import { HttpStatus, Injectable } from '@nestjs/common';
import { ApiException } from '../common/http/api-exception';
import { PrismaService } from '../database/prisma.service';
import { decodeCursor, encodeCursor } from './cursor.util';
import { CreatePersonDto } from './dto/create-person.dto';
import { ListPeopleQueryDto } from './dto/list-people-query.dto';
import { UpdatePersonDto } from './dto/update-person.dto';
import { DEFAULT_PEOPLE_LIMIT, PEOPLE_ERROR_CODES, PeopleSort } from './people.constants';

type PrismaOrderBy = Record<string, 'asc' | 'desc'>;

const SORT_ORDER_BY: Record<PeopleSort, PrismaOrderBy[]> = {
  name_asc: [{ firstName: 'asc' }, { lastName: 'asc' }, { id: 'asc' }],
  name_desc: [{ firstName: 'desc' }, { lastName: 'desc' }, { id: 'asc' }],
  newest: [{ createdAt: 'desc' }, { id: 'asc' }],
  oldest: [{ createdAt: 'asc' }, { id: 'asc' }],
};

interface PersonRow {
  id: string;
  firstName: string;
  lastName: string;
  email: string | null;
  phone: string | null;
  status: string;
  profilePhoto: string | null;
  createdAt: Date;
}

export interface PersonSummary {
  id: string;
  firstName: string;
  lastName: string;
  email: string | null;
  phone: string | null;
  status: string;
  avatarUrl: string | null;
  joinedAt: string;
}

export interface PeopleListResult {
  people: PersonSummary[];
  nextCursor: string | null;
}

export interface PersonDetail extends PersonSummary {
  tags: Array<{ id: string; name: string }>;
  currentJourneyStage: { id: string; name: string } | null;
}

const PERSON_SELECT = {
  id: true,
  firstName: true,
  lastName: true,
  email: true,
  phone: true,
  status: true,
  profilePhoto: true,
  createdAt: true,
} as const;

@Injectable()
export class PeopleService {
  constructor(private readonly prisma: PrismaService) {}

  async list(organizationId: string, query: ListPeopleQueryDto): Promise<PeopleListResult> {
    const sort: PeopleSort = query.sort ?? 'name_asc';
    const limit = query.limit ?? DEFAULT_PEOPLE_LIMIT;

    const where: Record<string, unknown> = {
      organizationId,
      deletedAt: null,
    };

    if (query.search) {
      const trimmed = query.search.trim();
      if (trimmed) {
        where.OR = [
          { firstName: { contains: trimmed, mode: 'insensitive' } },
          { lastName: { contains: trimmed, mode: 'insensitive' } },
          { email: { contains: trimmed, mode: 'insensitive' } },
          { phone: { contains: trimmed, mode: 'insensitive' } },
        ];
      }
    }

    if (query.status) {
      where.status = query.status;
    }

    if (query.journeyStageId) {
      where.id = { in: await this.resolveJourneyStageMatches(organizationId, query.journeyStageId) };
    }

    const cursorId = query.cursor ? decodeCursor(query.cursor, sort) : undefined;

    const rows = (await this.prisma.person.findMany({
      where,
      orderBy: SORT_ORDER_BY[sort],
      take: limit + 1,
      select: PERSON_SELECT,
      ...(cursorId ? { cursor: { id: cursorId }, skip: 1 } : {}),
    })) as PersonRow[];

    const hasMore = rows.length > limit;
    const pageRows = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor = hasMore ? encodeCursor({ id: pageRows[pageRows.length - 1].id, sort }) : null;

    return {
      people: pageRows.map((row) => this.toSummary(row)),
      nextCursor,
    };
  }

  async detail(organizationId: string, personId: string): Promise<{ person: PersonDetail }> {
    const person = (await this.prisma.person.findFirst({
      where: { id: personId, organizationId, deletedAt: null },
      select: PERSON_SELECT,
    })) as PersonRow | null;

    if (!person) {
      throw this.personNotFoundError();
    }

    const personTags = await this.prisma.personTag.findMany({
      where: { personId },
      select: { tag: { select: { id: true, name: true } } },
      orderBy: [{ tag: { name: 'asc' } }, { tag: { id: 'asc' } }],
    });

    const latestHistory = await this.prisma.personJourneyHistory.findFirst({
      where: { personId },
      orderBy: [{ movedAt: 'desc' }, { id: 'desc' }],
      select: { toStage: { select: { id: true, name: true } } },
    });

    return {
      person: {
        ...this.toSummary(person),
        tags: personTags.map((personTag) => personTag.tag),
        currentJourneyStage: latestHistory ? latestHistory.toStage : null,
      },
    };
  }

  async create(organizationId: string, dto: CreatePersonDto): Promise<{ person: PersonSummary }> {
    const created = (await this.prisma.person.create({
      data: {
        organizationId,
        firstName: dto.firstName,
        lastName: dto.lastName,
        email: dto.email ?? null,
        phone: dto.phone ?? null,
        status: dto.status ?? 'ACTIVE',
      },
      select: PERSON_SELECT,
    })) as PersonRow;

    return { person: this.toSummary(created) };
  }

  async update(organizationId: string, personId: string, dto: UpdatePersonDto): Promise<{ person: PersonSummary }> {
    const hasAnyField =
      dto.firstName !== undefined ||
      dto.lastName !== undefined ||
      dto.email !== undefined ||
      dto.phone !== undefined ||
      dto.status !== undefined;

    if (!hasAnyField) {
      throw new ApiException(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'VALIDATION_ERROR',
        'At least one field must be supplied.',
      );
    }

    const existing = await this.prisma.person.findFirst({
      where: { id: personId, organizationId, deletedAt: null },
      select: { id: true },
    });

    if (!existing) {
      throw this.personNotFoundError();
    }

    const data: Record<string, unknown> = {};
    if (dto.firstName !== undefined) data.firstName = dto.firstName;
    if (dto.lastName !== undefined) data.lastName = dto.lastName;
    if (dto.email !== undefined) data.email = dto.email;
    if (dto.phone !== undefined) data.phone = dto.phone;
    if (dto.status !== undefined) data.status = dto.status;

    const updated = (await this.prisma.person.update({
      where: { id: personId },
      data,
      select: PERSON_SELECT,
    })) as PersonRow;

    return { person: this.toSummary(updated) };
  }

  async remove(organizationId: string, personId: string): Promise<{ success: true }> {
    const existing = await this.prisma.person.findFirst({
      where: { id: personId, organizationId, deletedAt: null },
      select: { id: true },
    });

    if (!existing) {
      throw this.personNotFoundError();
    }

    await this.prisma.person.update({
      where: { id: personId },
      data: { deletedAt: new Date() },
    });

    return { success: true };
  }

  /**
   * "Current journey stage" is the latest PersonJourneyHistory row per
   * Person (movedAt desc, id desc). Prisma's query builder cannot express
   * "latest row per group" without a window function, so a parameterized
   * raw query computes it; Persons without history never match.
   */
  private async resolveJourneyStageMatches(organizationId: string, journeyStageId: string): Promise<string[]> {
    const stage = await this.prisma.journeyStage.findFirst({
      where: { id: journeyStageId, journeyTemplate: { organizationId } },
      select: { id: true },
    });

    if (!stage) {
      throw this.journeyStageNotFoundError();
    }

    const rows = await this.prisma.$queryRaw<Array<{ person_id: string }>>`
      SELECT person_id FROM (
        SELECT DISTINCT ON (h.person_id) h.person_id, h.to_stage_id
        FROM person_journey_history h
        INNER JOIN people p ON p.id = h.person_id
        WHERE p.organization_id = ${organizationId}::uuid
        ORDER BY h.person_id, h.moved_at DESC, h.id DESC
      ) latest
      WHERE latest.to_stage_id = ${journeyStageId}::uuid
    `;

    return rows.map((row) => row.person_id);
  }

  private toSummary(row: PersonRow): PersonSummary {
    return {
      id: row.id,
      firstName: row.firstName,
      lastName: row.lastName,
      email: row.email,
      phone: row.phone,
      status: row.status,
      avatarUrl: row.profilePhoto,
      joinedAt: row.createdAt.toISOString(),
    };
  }

  private personNotFoundError(): ApiException {
    return new ApiException(HttpStatus.NOT_FOUND, PEOPLE_ERROR_CODES.PERSON_NOT_FOUND, 'Person not found.');
  }

  private journeyStageNotFoundError(): ApiException {
    return new ApiException(
      HttpStatus.NOT_FOUND,
      PEOPLE_ERROR_CODES.JOURNEY_STAGE_NOT_FOUND,
      'Journey stage not found.',
    );
  }
}
