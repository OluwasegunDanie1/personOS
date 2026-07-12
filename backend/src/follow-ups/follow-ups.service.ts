import { HttpStatus, Injectable } from '@nestjs/common';
import { ApiException } from '../common/http/api-exception';
import { PrismaService } from '../database/prisma.service';
import { PEOPLE_ERROR_CODES } from '../people/people.constants';
import { decodeCursor, encodeCursor } from './cursor.util';
import { CreateFollowUpDto } from './dto/create-follow-up.dto';
import { ListFollowUpsQueryDto } from './dto/list-follow-ups-query.dto';
import { UpdateFollowUpDto } from './dto/update-follow-up.dto';
import {
  COMPLETED_FOLLOW_UP_STATUS,
  DEFAULT_FOLLOW_UP_LIMIT,
  DEFAULT_FOLLOW_UP_SORT,
  DEFAULT_FOLLOW_UP_STATUS,
  FOLLOW_UP_ERROR_CODES,
  FollowUpSort,
} from './follow-ups.constants';

type PrismaOrderByValue = 'asc' | 'desc' | { sort: 'asc' | 'desc'; nulls: 'last' };
type PrismaOrderBy = Record<string, PrismaOrderByValue>;

const SORT_ORDER_BY: Record<FollowUpSort, PrismaOrderBy[]> = {
  dueDate_asc: [{ dueDate: { sort: 'asc', nulls: 'last' } }, { id: 'asc' }],
  dueDate_desc: [{ dueDate: { sort: 'desc', nulls: 'last' } }, { id: 'asc' }],
  title_asc: [{ title: 'asc' }, { id: 'asc' }],
};

export interface PersonRef {
  id: string;
  firstName: string;
  lastName: string;
}

export interface FollowUpSummary {
  id: string;
  title: string;
  description: string | null;
  dueDate: string | null;
  status: string;
  completedAt: string | null;
  person: PersonRef;
  assignedTo: PersonRef | null;
}

export interface FollowUpListResult {
  followUps: FollowUpSummary[];
  nextCursor: string | null;
}

interface FollowUpRow {
  id: string;
  title: string;
  description: string | null;
  dueDate: Date | null;
  status: string;
  completedAt: Date | null;
  person: PersonRef;
  assignedToUser: PersonRef | null;
}

const FOLLOW_UP_SELECT = {
  id: true,
  title: true,
  description: true,
  dueDate: true,
  status: true,
  completedAt: true,
  person: { select: { id: true, firstName: true, lastName: true } },
  assignedToUser: { select: { id: true, firstName: true, lastName: true } },
} as const;

@Injectable()
export class FollowUpsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(organizationId: string, query: ListFollowUpsQueryDto): Promise<FollowUpListResult> {
    const sort: FollowUpSort = query.sort ?? DEFAULT_FOLLOW_UP_SORT;
    const limit = query.limit ?? DEFAULT_FOLLOW_UP_LIMIT;

    const where: Record<string, unknown> = { organizationId };

    if (query.status) {
      where.status = query.status;
    }

    if (query.assigned_user_id) {
      await this.assertActiveMember(organizationId, query.assigned_user_id);
      where.assignedTo = query.assigned_user_id;
    }

    if (query.person_id) {
      await this.assertActivePerson(organizationId, query.person_id);
      where.personId = query.person_id;
    }

    if (query.due_date) {
      // Exact equality match only; no range/overdue/before/after semantics.
      where.dueDate = new Date(query.due_date);
    }

    const cursorId = query.cursor ? decodeCursor(query.cursor, sort) : undefined;

    const rows = (await this.prisma.followUp.findMany({
      where,
      orderBy: SORT_ORDER_BY[sort],
      take: limit + 1,
      select: FOLLOW_UP_SELECT,
      ...(cursorId ? { cursor: { id: cursorId }, skip: 1 } : {}),
    })) as FollowUpRow[];

    const hasMore = rows.length > limit;
    const pageRows = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor = hasMore ? encodeCursor({ id: pageRows[pageRows.length - 1].id, sort }) : null;

    return { followUps: pageRows.map((row) => this.toSummary(row)), nextCursor };
  }

  async detail(organizationId: string, followUpId: string): Promise<{ followUp: FollowUpSummary }> {
    const row = (await this.prisma.followUp.findFirst({
      where: { id: followUpId, organizationId },
      select: FOLLOW_UP_SELECT,
    })) as FollowUpRow | null;

    if (!row) {
      throw this.followUpNotFoundError();
    }

    return { followUp: this.toSummary(row) };
  }

  async create(organizationId: string, dto: CreateFollowUpDto): Promise<{ followUp: FollowUpSummary }> {
    await this.assertActivePerson(organizationId, dto.personId);

    if (dto.assignedTo) {
      await this.assertActiveMember(organizationId, dto.assignedTo);
    }

    const created = (await this.prisma.followUp.create({
      data: {
        organizationId,
        personId: dto.personId,
        title: dto.title,
        description: dto.description ?? null,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        assignedTo: dto.assignedTo ?? null,
        status: DEFAULT_FOLLOW_UP_STATUS,
        completedAt: null,
      },
      select: FOLLOW_UP_SELECT,
    })) as FollowUpRow;

    return { followUp: this.toSummary(created) };
  }

  async update(
    organizationId: string,
    followUpId: string,
    dto: UpdateFollowUpDto,
  ): Promise<{ followUp: FollowUpSummary }> {
    const hasAnyField =
      dto.title !== undefined ||
      dto.description !== undefined ||
      dto.dueDate !== undefined ||
      dto.assignedTo !== undefined ||
      dto.status !== undefined;

    if (!hasAnyField) {
      throw new ApiException(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'VALIDATION_ERROR',
        'At least one field must be supplied.',
      );
    }

    const existing = await this.prisma.followUp.findFirst({
      where: { id: followUpId, organizationId },
      select: { id: true, status: true },
    });

    if (!existing) {
      throw this.followUpNotFoundError();
    }

    // A completed Follow-up can never be reopened or have its status
    // otherwise mutated through Update; only Complete governs COMPLETED.
    if (dto.status !== undefined && existing.status === COMPLETED_FOLLOW_UP_STATUS) {
      throw this.alreadyCompletedError();
    }

    if (dto.assignedTo) {
      await this.assertActiveMember(organizationId, dto.assignedTo);
    }

    const data: Record<string, unknown> = {};
    if (dto.title !== undefined) data.title = dto.title;
    if (dto.description !== undefined) data.description = dto.description;
    if (dto.dueDate !== undefined) data.dueDate = dto.dueDate ? new Date(dto.dueDate) : null;
    if (dto.assignedTo !== undefined) data.assignedTo = dto.assignedTo;
    if (dto.status !== undefined) data.status = dto.status;

    const updated = (await this.prisma.followUp.update({
      where: { id: followUpId },
      data,
      select: FOLLOW_UP_SELECT,
    })) as FollowUpRow;

    return { followUp: this.toSummary(updated) };
  }

  async complete(organizationId: string, followUpId: string): Promise<{ followUp: FollowUpSummary }> {
    const existing = (await this.prisma.followUp.findFirst({
      where: { id: followUpId, organizationId },
      select: FOLLOW_UP_SELECT,
    })) as FollowUpRow | null;

    if (!existing) {
      throw this.followUpNotFoundError();
    }

    if (existing.status === COMPLETED_FOLLOW_UP_STATUS) {
      // Idempotent: return the row unchanged, never overwriting completedAt.
      return { followUp: this.toSummary(existing) };
    }

    const updated = (await this.prisma.followUp.update({
      where: { id: followUpId },
      data: { status: COMPLETED_FOLLOW_UP_STATUS, completedAt: new Date() },
      select: FOLLOW_UP_SELECT,
    })) as FollowUpRow;

    return { followUp: this.toSummary(updated) };
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

  /** Global User existence alone is never sufficient; membership in the active organization is required. */
  private async assertActiveMember(organizationId: string, userId: string): Promise<void> {
    const membership = await this.prisma.organizationMembership.findUnique({
      where: { organizationId_userId: { organizationId, userId } },
      select: { id: true },
    });

    if (!membership) {
      throw this.assignedUserNotFoundError();
    }
  }

  private toSummary(row: FollowUpRow): FollowUpSummary {
    return {
      id: row.id,
      title: row.title,
      description: row.description,
      dueDate: row.dueDate ? row.dueDate.toISOString() : null,
      status: row.status,
      completedAt: row.completedAt ? row.completedAt.toISOString() : null,
      person: row.person,
      assignedTo: row.assignedToUser,
    };
  }

  private followUpNotFoundError(): ApiException {
    return new ApiException(
      HttpStatus.NOT_FOUND,
      FOLLOW_UP_ERROR_CODES.FOLLOW_UP_NOT_FOUND,
      'Follow-up not found.',
    );
  }

  private assignedUserNotFoundError(): ApiException {
    return new ApiException(
      HttpStatus.NOT_FOUND,
      FOLLOW_UP_ERROR_CODES.ASSIGNED_USER_NOT_FOUND,
      'Assigned user not found.',
    );
  }

  private alreadyCompletedError(): ApiException {
    return new ApiException(
      HttpStatus.CONFLICT,
      FOLLOW_UP_ERROR_CODES.FOLLOW_UP_ALREADY_COMPLETED,
      'This follow-up is already completed.',
    );
  }
}
