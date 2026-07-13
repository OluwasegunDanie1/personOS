import { HttpStatus, Injectable } from '@nestjs/common';
import { Prisma } from '../../generated/prisma/client';
import { ApiException } from '../common/http/api-exception';
import { PrismaService } from '../database/prisma.service';
import { decodeCursor, encodeCursor } from './cursor.util';
import { formatUtcDateOnly, parseCalendarDateOnlyToUtcDate } from './date-of-birth.validator';
import { CreatePersonDto } from './dto/create-person.dto';
import { ListPeopleQueryDto } from './dto/list-people-query.dto';
import { UpdatePersonDto } from './dto/update-person.dto';
import { DEFAULT_PEOPLE_LIMIT, PEOPLE_ERROR_CODES, PeopleSort, PersonGenderValue } from './people.constants';

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

/**
 * List-only enrichment. Deliberately a separate type from PersonSummary so
 * Create/Update (which reuse toSummary() directly) never widen to include
 * these two fields — only PeopleService.list() ever constructs this shape.
 */
export interface PersonListSummary extends PersonSummary {
  currentJourneyStage: { id: string; name: string } | null;
  lastAttendance: { checkedInAt: string } | null;
}

export interface PeopleListResult {
  people: PersonListSummary[];
  nextCursor: string | null;
}

/**
 * Detail-only widening (Product Task 039): gender/dateOfBirth/address are
 * approved Create Person write authority that Detail can now read back.
 * Deliberately not added to PersonSummary itself so List/Create/Update -
 * which all reuse toSummary() directly - never widen.
 */
export interface PersonDetail extends PersonSummary {
  tags: Array<{ id: string; name: string }>;
  currentJourneyStage: { id: string; name: string } | null;
  gender: PersonGenderValue | null;
  dateOfBirth: string | null;
  address: string | null;
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

/**
 * Detail-only select. A separate constant (rather than widening the shared
 * PERSON_SELECT) so List/Create/Update's Prisma queries are never touched by
 * this correction - only detail() ever uses this.
 */
const PERSON_DETAIL_SELECT = {
  ...PERSON_SELECT,
  gender: true,
  dateOfBirth: true,
  address: true,
} as const;

interface PersonDetailRow extends PersonRow {
  gender: string | null;
  dateOfBirth: Date | null;
  address: string | null;
}

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

    if (pageRows.length === 0) {
      return { people: [], nextCursor };
    }

    // Exactly two bounded batch queries per non-empty page — never one per
    // person — regardless of how many rows the page contains.
    const personIds = pageRows.map((row) => row.id);
    const [journeyStageByPersonId, lastAttendanceByPersonId] = await Promise.all([
      this.resolveCurrentJourneyStages(organizationId, personIds),
      this.resolveLatestAttendance(organizationId, personIds),
    ]);

    return {
      people: pageRows.map((row) => ({
        ...this.toSummary(row),
        currentJourneyStage: journeyStageByPersonId.get(row.id) ?? null,
        lastAttendance: lastAttendanceByPersonId.get(row.id) ?? null,
      })),
      nextCursor,
    };
  }

  async detail(organizationId: string, personId: string): Promise<{ person: PersonDetail }> {
    const person = (await this.prisma.person.findFirst({
      where: { id: personId, organizationId, deletedAt: null },
      select: PERSON_DETAIL_SELECT,
    })) as PersonDetailRow | null;

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
        gender: (person.gender as PersonGenderValue | null) ?? null,
        dateOfBirth: person.dateOfBirth ? formatUtcDateOnly(person.dateOfBirth) : null,
        address: person.address ?? null,
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
        gender: dto.gender ?? null,
        dateOfBirth: dto.dateOfBirth ? parseCalendarDateOnlyToUtcDate(dto.dateOfBirth) : null,
        address: dto.address ?? null,
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
      dto.status !== undefined ||
      dto.gender !== undefined ||
      dto.dateOfBirth !== undefined ||
      dto.address !== undefined;

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
    if (dto.gender !== undefined) data.gender = dto.gender;
    if (dto.dateOfBirth !== undefined) {
      data.dateOfBirth = dto.dateOfBirth ? parseCalendarDateOnlyToUtcDate(dto.dateOfBirth) : null;
    }
    if (dto.address !== undefined) data.address = dto.address;

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

  /**
   * Batch-resolves each page person's current journey stage in exactly one
   * query (never one per person), using the same latest-row-per-person
   * DISTINCT ON pattern as resolveJourneyStageMatches above. Person A
   * Journey history has no organizationId column of its own, so isolation
   * is enforced by joining through organization-owned People — identical to
   * the existing precedent, not a new scoping mechanism.
   */
  private async resolveCurrentJourneyStages(
    organizationId: string,
    personIds: string[],
  ): Promise<Map<string, { id: string; name: string }>> {
    const idParams = Prisma.join(personIds.map((id) => Prisma.sql`${id}::uuid`));

    const latestRows = await this.prisma.$queryRaw<Array<{ person_id: string; to_stage_id: string }>>`
      SELECT DISTINCT ON (h.person_id) h.person_id, h.to_stage_id
      FROM person_journey_history h
      INNER JOIN people p ON p.id = h.person_id
      WHERE p.organization_id = ${organizationId}::uuid
        AND h.person_id IN (${idParams})
      ORDER BY h.person_id, h.moved_at DESC, h.id DESC
    `;

    if (latestRows.length === 0) {
      return new Map();
    }

    // Re-validated against this organization's own journey configuration —
    // never trusts to_stage_id alone as proof of organization ownership.
    const stageIds = [...new Set(latestRows.map((row) => row.to_stage_id))];
    const stages = await this.prisma.journeyStage.findMany({
      where: { id: { in: stageIds }, journeyTemplate: { organizationId } },
      select: { id: true, name: true },
    });
    const stageById = new Map(stages.map((stage) => [stage.id, stage]));

    const result = new Map<string, { id: string; name: string }>();
    for (const row of latestRows) {
      const stage = stageById.get(row.to_stage_id);
      if (stage) {
        result.set(row.person_id, stage);
      }
    }
    return result;
  }

  /**
   * Batch-resolves each page person's latest Attendance row in exactly one
   * query (never one per person). Attendance carries its own organizationId
   * column, so both that column and the pre-scoped personId list constrain
   * the query — defense in depth beyond the already-organization-scoped ids.
   */
  private async resolveLatestAttendance(
    organizationId: string,
    personIds: string[],
  ): Promise<Map<string, { checkedInAt: string }>> {
    const idParams = Prisma.join(personIds.map((id) => Prisma.sql`${id}::uuid`));

    const rows = await this.prisma.$queryRaw<Array<{ person_id: string; checked_in_at: Date }>>`
      SELECT DISTINCT ON (person_id) person_id, checked_in_at
      FROM attendance
      WHERE organization_id = ${organizationId}::uuid
        AND person_id IN (${idParams})
      ORDER BY person_id, checked_in_at DESC, id DESC
    `;

    const result = new Map<string, { checkedInAt: string }>();
    for (const row of rows) {
      result.set(row.person_id, { checkedInAt: row.checked_in_at.toISOString() });
    }
    return result;
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
