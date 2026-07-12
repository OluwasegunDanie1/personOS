import { HttpStatus, Injectable } from '@nestjs/common';
import { AttendanceStatus, Prisma } from '../../generated/prisma/client';
import { ApiException } from '../common/http/api-exception';
import { PrismaService } from '../database/prisma.service';
import { PEOPLE_ERROR_CODES } from '../people/people.constants';
import {
  DEFAULT_ATTENDANCE_LIMIT,
  DEFAULT_EVENT_ATTENDANCE_SORT,
  DEFAULT_PERSON_ATTENDANCE_SORT,
  DEFAULT_PUBLIC_ATTENDANCE_STATUS,
  EventAttendanceSort,
  PersonAttendanceSort,
  PRISMA_TO_PUBLIC_STATUS,
  PUBLIC_TO_PRISMA_STATUS,
  PublicAttendanceStatus,
} from './attendance.constants';
import { decodeCursor, encodeCursor } from './cursor.util';
import { ListEventAttendanceQueryDto } from './dto/list-event-attendance-query.dto';
import { ListPersonAttendanceQueryDto } from './dto/list-person-attendance-query.dto';
import { RecordAttendanceDto } from './dto/record-attendance.dto';
import { EventsService } from './events.service';

type PrismaOrderBy = Record<string, unknown>;

const EVENT_ATTENDANCE_ORDER_BY: Record<EventAttendanceSort, PrismaOrderBy[]> = {
  checkedInAt_desc: [{ checkedInAt: 'desc' }, { id: 'asc' }],
  checkedInAt_asc: [{ checkedInAt: 'asc' }, { id: 'asc' }],
  personName_asc: [{ person: { firstName: 'asc' } }, { person: { lastName: 'asc' } }, { id: 'asc' }],
};

const PERSON_ATTENDANCE_ORDER_BY: Record<PersonAttendanceSort, PrismaOrderBy[]> = {
  checkedInAt_desc: [{ checkedInAt: 'desc' }, { id: 'asc' }],
  checkedInAt_asc: [{ checkedInAt: 'asc' }, { id: 'asc' }],
  eventStartDate_desc: [{ event: { startDate: 'desc' } }, { id: 'asc' }],
};

export interface PersonRef {
  id: string;
  firstName: string;
  lastName: string;
}

export interface EventRef {
  id: string;
  title: string;
  startDate: string;
}

export interface EventAttendanceEntry {
  id: string;
  person: PersonRef;
  status: PublicAttendanceStatus;
  checkedInBy: PersonRef | null;
  checkedInAt: string;
}

export interface PersonAttendanceEntry {
  id: string;
  event: EventRef;
  status: PublicAttendanceStatus;
  checkedInAt: string;
}

export interface RecordAttendanceResult {
  attendance: EventAttendanceEntry;
  created: boolean;
}

interface EventAttendanceRow {
  id: string;
  status: AttendanceStatus;
  checkedInAt: Date;
  person: PersonRef;
  checkedInByUser: PersonRef | null;
}

interface PersonAttendanceRow {
  id: string;
  status: AttendanceStatus;
  checkedInAt: Date;
  event: { id: string; title: string; startDate: Date };
}

const EVENT_ATTENDANCE_SELECT = {
  id: true,
  status: true,
  checkedInAt: true,
  person: { select: { id: true, firstName: true, lastName: true } },
  checkedInByUser: { select: { id: true, firstName: true, lastName: true } },
} as const;

const PERSON_ATTENDANCE_SELECT = {
  id: true,
  status: true,
  checkedInAt: true,
  event: { select: { id: true, title: true, startDate: true } },
} as const;

const UNIQUE_CONSTRAINT_VIOLATION_CODE = 'P2002';

@Injectable()
export class AttendanceService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventsService: EventsService,
  ) {}

  async listForEvent(
    organizationId: string,
    eventId: string,
    query: ListEventAttendanceQueryDto,
  ): Promise<{ attendance: EventAttendanceEntry[]; nextCursor: string | null }> {
    // Event tenant ownership is validated independently before any
    // Attendance read; never an eventId-only lookup.
    await this.eventsService.assertActiveEvent(organizationId, eventId);

    const sort: EventAttendanceSort = query.sort ?? DEFAULT_EVENT_ATTENDANCE_SORT;
    const limit = query.limit ?? DEFAULT_ATTENDANCE_LIMIT;

    const where: Record<string, unknown> = { organizationId, eventId };
    if (query.status) {
      where.status = PUBLIC_TO_PRISMA_STATUS[query.status];
    }

    const cursorId = query.cursor ? decodeCursor(query.cursor, sort) : undefined;

    // Deliberately does not filter by person.deletedAt: historical
    // Attendance must remain visible after the referenced Person is later
    // soft-deleted.
    const rows = (await this.prisma.attendance.findMany({
      where,
      orderBy: EVENT_ATTENDANCE_ORDER_BY[sort],
      take: limit + 1,
      select: EVENT_ATTENDANCE_SELECT,
      ...(cursorId ? { cursor: { id: cursorId }, skip: 1 } : {}),
    })) as EventAttendanceRow[];

    const hasMore = rows.length > limit;
    const pageRows = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor = hasMore ? encodeCursor({ id: pageRows[pageRows.length - 1].id, sort }) : null;

    return { attendance: pageRows.map((row) => this.toEventAttendanceEntry(row)), nextCursor };
  }

  async record(
    organizationId: string,
    eventId: string,
    userId: string,
    dto: RecordAttendanceDto,
  ): Promise<RecordAttendanceResult> {
    // Event and Person tenant ownership are each validated independently;
    // never an eventId-only or personId-only lookup.
    await this.eventsService.assertActiveEvent(organizationId, eventId);
    await this.assertActivePerson(organizationId, dto.personId);

    const publicStatus: PublicAttendanceStatus = dto.status ?? DEFAULT_PUBLIC_ATTENDANCE_STATUS;
    const prismaStatus = PUBLIC_TO_PRISMA_STATUS[publicStatus];

    try {
      const created = (await this.prisma.attendance.create({
        data: {
          organizationId,
          eventId,
          personId: dto.personId,
          status: prismaStatus,
          checkedInBy: userId,
          checkedInAt: new Date(),
        },
        select: EVENT_ATTENDANCE_SELECT,
      })) as EventAttendanceRow;

      return { attendance: this.toEventAttendanceEntry(created), created: true };
    } catch (error) {
      // Only the (organizationId, eventId, personId) unique-constraint
      // conflict is treated as an idempotent replay; any other Prisma error
      // must propagate unchanged.
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === UNIQUE_CONSTRAINT_VIOLATION_CODE) {
        const existing = (await this.prisma.attendance.findUnique({
          where: { organizationId_eventId_personId: { organizationId, eventId, personId: dto.personId } },
          select: EVENT_ATTENDANCE_SELECT,
        })) as EventAttendanceRow | null;

        if (existing) {
          // The duplicate request's submitted status is entirely ignored;
          // the existing row is returned unchanged (no upsert-that-updates).
          return { attendance: this.toEventAttendanceEntry(existing), created: false };
        }
      }

      throw error;
    }
  }

  async listForPerson(
    organizationId: string,
    personId: string,
    query: ListPersonAttendanceQueryDto,
  ): Promise<{ attendance: PersonAttendanceEntry[]; nextCursor: string | null }> {
    // Person tenant ownership is validated independently before any
    // Attendance read; never a personId-only lookup.
    await this.assertActivePerson(organizationId, personId);

    const sort: PersonAttendanceSort = query.sort ?? DEFAULT_PERSON_ATTENDANCE_SORT;
    const limit = query.limit ?? DEFAULT_ATTENDANCE_LIMIT;

    const cursorId = query.cursor ? decodeCursor(query.cursor, sort) : undefined;

    // Deliberately does not filter by event.deletedAt: historical
    // Attendance must remain visible after the referenced Event is later
    // soft-deleted.
    const rows = (await this.prisma.attendance.findMany({
      where: { organizationId, personId },
      orderBy: PERSON_ATTENDANCE_ORDER_BY[sort],
      take: limit + 1,
      select: PERSON_ATTENDANCE_SELECT,
      ...(cursorId ? { cursor: { id: cursorId }, skip: 1 } : {}),
    })) as PersonAttendanceRow[];

    const hasMore = rows.length > limit;
    const pageRows = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor = hasMore ? encodeCursor({ id: pageRows[pageRows.length - 1].id, sort }) : null;

    return { attendance: pageRows.map((row) => this.toPersonAttendanceEntry(row)), nextCursor };
  }

  private async assertActivePerson(organizationId: string, personId: string): Promise<void> {
    const existing = await this.prisma.person.findFirst({
      where: { id: personId, organizationId, deletedAt: null },
      select: { id: true },
    });

    if (!existing) {
      throw new ApiException(HttpStatus.NOT_FOUND, PEOPLE_ERROR_CODES.PERSON_NOT_FOUND, 'Person not found.');
    }
  }

  private toEventAttendanceEntry(row: EventAttendanceRow): EventAttendanceEntry {
    return {
      id: row.id,
      person: row.person,
      status: PRISMA_TO_PUBLIC_STATUS[row.status],
      checkedInBy: row.checkedInByUser,
      checkedInAt: row.checkedInAt.toISOString(),
    };
  }

  private toPersonAttendanceEntry(row: PersonAttendanceRow): PersonAttendanceEntry {
    return {
      id: row.id,
      event: { id: row.event.id, title: row.event.title, startDate: row.event.startDate.toISOString() },
      status: PRISMA_TO_PUBLIC_STATUS[row.status],
      checkedInAt: row.checkedInAt.toISOString(),
    };
  }
}
