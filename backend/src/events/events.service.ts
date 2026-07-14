import { HttpStatus, Injectable } from '@nestjs/common';
import { ApiException } from '../common/http/api-exception';
import { PrismaService } from '../database/prisma.service';
import { decodeCursor, encodeCursor } from './cursor.util';
import { CreateEventDto } from './dto/create-event.dto';
import { ListEventsQueryDto } from './dto/list-events-query.dto';
import { UpdateEventDto } from './dto/update-event.dto';
import { DEFAULT_EVENT_LIMIT, DEFAULT_EVENT_SORT, EVENT_ERROR_CODES, EventSort } from './events.constants';

type PrismaOrderBy = Record<string, 'asc' | 'desc'>;

const SORT_ORDER_BY: Record<EventSort, PrismaOrderBy[]> = {
  startDate_desc: [{ startDate: 'desc' }, { id: 'asc' }],
  startDate_asc: [{ startDate: 'asc' }, { id: 'asc' }],
  createdAt_desc: [{ createdAt: 'desc' }, { id: 'asc' }],
  title_asc: [{ title: 'asc' }, { id: 'asc' }],
};

export interface EventSummary {
  id: string;
  title: string;
  description: string | null;
  category: string | null;
  venue: string | null;
  startDate: string;
  endDate: string | null;
  cancelledAt: string | null;
  createdAt: string;
}

export interface EventCreatorRef {
  id: string;
  firstName: string;
  lastName: string;
}

export interface EventDetail extends EventSummary {
  createdBy: EventCreatorRef;
}

export interface EventListResult {
  events: EventSummary[];
  nextCursor: string | null;
}

interface EventRow {
  id: string;
  title: string;
  description: string | null;
  category: string | null;
  venue: string | null;
  startDate: Date;
  endDate: Date | null;
  cancelledAt: Date | null;
  createdAt: Date;
}

interface EventDetailRow extends EventRow {
  createdByUser: EventCreatorRef;
}

const EVENT_SELECT = {
  id: true,
  title: true,
  description: true,
  category: true,
  venue: true,
  startDate: true,
  endDate: true,
  cancelledAt: true,
  createdAt: true,
} as const;

const EVENT_DETAIL_SELECT = {
  ...EVENT_SELECT,
  createdByUser: { select: { id: true, firstName: true, lastName: true } },
} as const;

@Injectable()
export class EventsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(organizationId: string, query: ListEventsQueryDto): Promise<EventListResult> {
    const sort: EventSort = query.sort ?? DEFAULT_EVENT_SORT;
    const limit = query.limit ?? DEFAULT_EVENT_LIMIT;

    const where: Record<string, unknown> = { organizationId, deletedAt: null };

    if (query.search) {
      const trimmed = query.search.trim();
      if (trimmed) {
        where.OR = [
          { title: { contains: trimmed, mode: 'insensitive' } },
          { description: { contains: trimmed, mode: 'insensitive' } },
          { venue: { contains: trimmed, mode: 'insensitive' } },
        ];
      }
    }

    if (query.category) {
      const trimmed = query.category.trim();
      if (trimmed) {
        where.category = { equals: trimmed, mode: 'insensitive' };
      }
    }

    const cursorId = query.cursor ? decodeCursor(query.cursor, sort) : undefined;

    const rows = (await this.prisma.event.findMany({
      where,
      orderBy: SORT_ORDER_BY[sort],
      take: limit + 1,
      select: EVENT_SELECT,
      ...(cursorId ? { cursor: { id: cursorId }, skip: 1 } : {}),
    })) as EventRow[];

    const hasMore = rows.length > limit;
    const pageRows = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor = hasMore ? encodeCursor({ id: pageRows[pageRows.length - 1].id, sort }) : null;

    return { events: pageRows.map((row) => this.toSummary(row)), nextCursor };
  }

  async detail(organizationId: string, eventId: string): Promise<{ event: EventDetail }> {
    const event = (await this.prisma.event.findFirst({
      where: { id: eventId, organizationId, deletedAt: null },
      select: EVENT_DETAIL_SELECT,
    })) as EventDetailRow | null;

    if (!event) {
      throw this.eventNotFoundError();
    }

    return { event: this.toDetail(event) };
  }

  async create(organizationId: string, userId: string, dto: CreateEventDto): Promise<{ event: EventDetail }> {
    const startDate = new Date(dto.startDate);
    const endDate = dto.endDate ? new Date(dto.endDate) : null;

    if (endDate && endDate < startDate) {
      throw this.invalidDateRangeError();
    }

    const created = (await this.prisma.event.create({
      data: {
        organizationId,
        title: dto.title,
        description: dto.description ?? null,
        category: dto.category ?? null,
        venue: dto.venue ?? null,
        startDate,
        endDate,
        createdBy: userId,
      },
      select: EVENT_DETAIL_SELECT,
    })) as EventDetailRow;

    return { event: this.toDetail(created) };
  }

  async update(organizationId: string, eventId: string, dto: UpdateEventDto): Promise<{ event: EventDetail }> {
    const hasAnyField =
      dto.title !== undefined ||
      dto.description !== undefined ||
      dto.category !== undefined ||
      dto.venue !== undefined ||
      dto.startDate !== undefined ||
      dto.endDate !== undefined;

    if (!hasAnyField) {
      throw new ApiException(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'VALIDATION_ERROR',
        'At least one field must be supplied.',
      );
    }

    const existing = await this.prisma.event.findFirst({
      where: { id: eventId, organizationId, deletedAt: null },
      select: { id: true, startDate: true, endDate: true },
    });

    if (!existing) {
      throw this.eventNotFoundError();
    }

    const data: Record<string, unknown> = {};
    if (dto.title !== undefined) data.title = dto.title;
    if (dto.description !== undefined) data.description = dto.description;
    if (dto.category !== undefined) data.category = dto.category;
    if (dto.venue !== undefined) data.venue = dto.venue;
    if (dto.startDate !== undefined) data.startDate = new Date(dto.startDate);
    if (dto.endDate !== undefined) data.endDate = dto.endDate ? new Date(dto.endDate) : null;

    // Date-range validation always runs against the final combined
    // (post-merge) values that would actually be persisted, not just the
    // raw request payload, per the approved Update Event authority.
    const effectiveStartDate = dto.startDate !== undefined ? new Date(dto.startDate) : existing.startDate;
    const effectiveEndDate =
      dto.endDate !== undefined ? (dto.endDate ? new Date(dto.endDate) : null) : existing.endDate;

    if (effectiveEndDate && effectiveEndDate < effectiveStartDate) {
      throw this.invalidDateRangeError();
    }

    const updated = (await this.prisma.event.update({
      where: { id: eventId },
      data,
      select: EVENT_DETAIL_SELECT,
    })) as EventDetailRow;

    return { event: this.toDetail(updated) };
  }

  async remove(organizationId: string, eventId: string): Promise<{ success: true }> {
    const existing = await this.prisma.event.findFirst({
      where: { id: eventId, organizationId, deletedAt: null },
      select: { id: true },
    });

    if (!existing) {
      throw this.eventNotFoundError();
    }

    await this.prisma.event.update({
      where: { id: eventId },
      data: { deletedAt: new Date() },
    });

    return { success: true };
  }

  /**
   * Reused by AttendanceService: validates Event tenant ownership (id +
   * organizationId + deletedAt null) before any Attendance read/write. Never
   * an eventId-only lookup.
   */
  async assertActiveEvent(organizationId: string, eventId: string): Promise<void> {
    const existing = await this.prisma.event.findFirst({
      where: { id: eventId, organizationId, deletedAt: null },
      select: { id: true },
    });

    if (!existing) {
      throw this.eventNotFoundError();
    }
  }

  /**
   * Idempotent: cancellation authority (cancelledAt) is set exactly once. A
   * repeat call on an already-cancelled Event performs no write and returns
   * the original cancelledAt unchanged, mirroring the Attendance idempotent-
   * replay convention. Never soft-deletes (deletedAt is untouched), never
   * touches Attendance/Journey, and there is no restore/uncancel path.
   */
  async cancel(organizationId: string, eventId: string): Promise<{ event: EventDetail }> {
    const existing = (await this.prisma.event.findFirst({
      where: { id: eventId, organizationId, deletedAt: null },
      select: EVENT_DETAIL_SELECT,
    })) as EventDetailRow | null;

    if (!existing) {
      throw this.eventNotFoundError();
    }

    if (existing.cancelledAt) {
      return { event: this.toDetail(existing) };
    }

    const updated = (await this.prisma.event.update({
      where: { id: eventId },
      data: { cancelledAt: new Date() },
      select: EVENT_DETAIL_SELECT,
    })) as EventDetailRow;

    return { event: this.toDetail(updated) };
  }

  private toSummary(row: EventRow): EventSummary {
    return {
      id: row.id,
      title: row.title,
      description: row.description,
      category: row.category,
      venue: row.venue,
      startDate: row.startDate.toISOString(),
      endDate: row.endDate ? row.endDate.toISOString() : null,
      cancelledAt: row.cancelledAt ? row.cancelledAt.toISOString() : null,
      createdAt: row.createdAt.toISOString(),
    };
  }

  private toDetail(row: EventDetailRow): EventDetail {
    return { ...this.toSummary(row), createdBy: row.createdByUser };
  }

  private eventNotFoundError(): ApiException {
    return new ApiException(HttpStatus.NOT_FOUND, EVENT_ERROR_CODES.EVENT_NOT_FOUND, 'Event not found.');
  }

  private invalidDateRangeError(): ApiException {
    return new ApiException(
      HttpStatus.UNPROCESSABLE_ENTITY,
      EVENT_ERROR_CODES.INVALID_EVENT_DATE_RANGE,
      'endDate cannot be earlier than startDate.',
    );
  }
}
