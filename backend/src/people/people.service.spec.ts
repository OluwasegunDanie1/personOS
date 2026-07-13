import { ApiException } from '../common/http/api-exception';
import { decodeCursor, encodeCursor } from './cursor.util';
import { PeopleService } from './people.service';

const ORG_ID = '11111111-1111-1111-1111-111111111111';
const STAGE_ID = '22222222-2222-2222-2222-222222222222';

function buildPersonRow(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'person-1',
    firstName: 'Ada',
    lastName: 'Lovelace',
    email: null,
    phone: null,
    status: 'ACTIVE',
    profilePhoto: null,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    ...overrides,
  };
}

function createMockPrisma() {
  return {
    person: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    personTag: { findMany: jest.fn() },
    personJourneyHistory: { findFirst: jest.fn() },
    journeyStage: { findFirst: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
    // Default: no journey/attendance enrichment data. Individual tests
    // override with mockResolvedValueOnce for the specific batch call(s)
    // they care about (journey batch is always called before attendance
    // batch within a single list() invocation — see Promise.all ordering).
    $queryRaw: jest.fn().mockResolvedValue([]),
  };
}

describe('PeopleService', () => {
  let prisma: ReturnType<typeof createMockPrisma>;
  let service: PeopleService;

  beforeEach(() => {
    prisma = createMockPrisma();
    service = new PeopleService(prisma as never);
  });

  describe('list', () => {
    it('scopes by organizationId and requires deletedAt null', async () => {
      prisma.person.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, {});

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.where.organizationId).toBe(ORG_ID);
      expect(args.where.deletedAt).toBeNull();
    });

    it('ORs search across firstName/lastName/email/phone case-insensitively', async () => {
      prisma.person.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { search: 'john' } as never);

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.where.OR).toEqual([
        { firstName: { contains: 'john', mode: 'insensitive' } },
        { lastName: { contains: 'john', mode: 'insensitive' } },
        { email: { contains: 'john', mode: 'insensitive' } },
        { phone: { contains: 'john', mode: 'insensitive' } },
      ]);
    });

    it('treats an empty trimmed search as absent', async () => {
      prisma.person.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { search: '   ' } as never);

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.where.OR).toBeUndefined();
    });

    it('applies the status filter exactly', async () => {
      prisma.person.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { status: 'INACTIVE' } as never);

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.where.status).toBe('INACTIVE');
    });

    it('verifies the journey stage belongs to the organization before filtering', async () => {
      prisma.journeyStage.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.list(ORG_ID, { journeyStageId: STAGE_ID } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('JOURNEY_STAGE_NOT_FOUND');
      expect(prisma.$queryRaw).not.toHaveBeenCalled();
    });

    it('filters by the latest-history match when the journey stage is valid', async () => {
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_ID });
      prisma.$queryRaw.mockResolvedValue([{ person_id: 'person-1' }, { person_id: 'person-2' }]);
      prisma.person.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { journeyStageId: STAGE_ID } as never);

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.where.id).toEqual({ in: ['person-1', 'person-2'] });
    });

    it('excludes Persons with no journey history from a journeyStageId match', async () => {
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_ID });
      prisma.$queryRaw.mockResolvedValue([]);
      prisma.person.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { journeyStageId: STAGE_ID } as never);

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.where.id).toEqual({ in: [] });
    });

    it.each([
      ['name_asc', [{ firstName: 'asc' }, { lastName: 'asc' }, { id: 'asc' }]],
      ['name_desc', [{ firstName: 'desc' }, { lastName: 'desc' }, { id: 'asc' }]],
      ['newest', [{ createdAt: 'desc' }, { id: 'asc' }]],
      ['oldest', [{ createdAt: 'asc' }, { id: 'asc' }]],
    ])('implements %s ordering exactly', async (sort, expectedOrderBy) => {
      prisma.person.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { sort } as never);

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual(expectedOrderBy);
    });

    it('defaults to name_asc when no sort is supplied', async () => {
      prisma.person.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, {});

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual([{ firstName: 'asc' }, { lastName: 'asc' }, { id: 'asc' }]);
    });

    it('defaults limit to 20 and requests limit+1 rows', async () => {
      prisma.person.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, {});

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.take).toBe(21);
    });

    it('respects a supplied limit for the limit+1 retrieval', async () => {
      prisma.person.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { limit: 5 } as never);

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.take).toBe(6);
    });

    it('returns nextCursor null when there is no extra row', async () => {
      prisma.person.findMany.mockResolvedValue([buildPersonRow()]);

      const result = await service.list(ORG_ID, { limit: 1 } as never);

      expect(result.nextCursor).toBeNull();
      expect(result.people).toHaveLength(1);
    });

    const CURSOR_ID_1 = '66666666-6666-6666-6666-666666666666';
    const CURSOR_ID_2 = '77777777-7777-7777-7777-777777777777';

    it('returns a usable opaque nextCursor when an extra row exists, trimming to the requested limit', async () => {
      prisma.person.findMany.mockResolvedValue([
        buildPersonRow({ id: CURSOR_ID_1 }),
        buildPersonRow({ id: CURSOR_ID_2 }),
      ]);

      const result = await service.list(ORG_ID, { limit: 1, sort: 'name_asc' } as never);

      expect(result.people).toHaveLength(1);
      expect(result.nextCursor).not.toBeNull();
      expect(decodeCursor(result.nextCursor as string, 'name_asc')).toBe(CURSOR_ID_1);
    });

    it('passes a decoded cursor id to Prisma native cursor+skip', async () => {
      prisma.person.findMany.mockResolvedValue([]);
      const cursor = encodeCursor({ id: CURSOR_ID_1, sort: 'name_asc' });

      await service.list(ORG_ID, { cursor, sort: 'name_asc' } as never);

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.cursor).toEqual({ id: CURSOR_ID_1 });
      expect(args.skip).toBe(1);
    });

    it('rejects a cursor generated for a different sort', async () => {
      const cursor = encodeCursor({ id: CURSOR_ID_1, sort: 'newest' });

      await expect(service.list(ORG_ID, { cursor, sort: 'name_asc' } as never)).rejects.toThrow();
      expect(prisma.person.findMany).not.toHaveBeenCalled();
    });

    it('maps the exact approved list response shape', async () => {
      prisma.person.findMany.mockResolvedValue([
        buildPersonRow({ id: 'person-1', email: 'ada@example.com', phone: '+1', profilePhoto: 'https://x/y.png' }),
      ]);

      const result = await service.list(ORG_ID, { limit: 5 } as never);

      expect(result).toEqual({
        people: [
          {
            id: 'person-1',
            firstName: 'Ada',
            lastName: 'Lovelace',
            email: 'ada@example.com',
            phone: '+1',
            status: 'ACTIVE',
            avatarUrl: 'https://x/y.png',
            joinedAt: '2026-01-01T00:00:00.000Z',
            currentJourneyStage: null,
            lastAttendance: null,
          },
        ],
        nextCursor: null,
      });
    });

    describe('current journey stage enrichment', () => {
      it('is null when the person has no journey history', async () => {
        prisma.person.findMany.mockResolvedValue([buildPersonRow({ id: 'person-1' })]);

        const result = await service.list(ORG_ID, {} as never);

        expect(result.people[0].currentJourneyStage).toBeNull();
      });

      it('returns exactly {id, name} when history exists', async () => {
        prisma.person.findMany.mockResolvedValue([buildPersonRow({ id: 'person-1' })]);
        prisma.$queryRaw
          .mockResolvedValueOnce([{ person_id: 'person-1', to_stage_id: STAGE_ID }])
          .mockResolvedValueOnce([]);
        prisma.journeyStage.findMany.mockResolvedValue([{ id: STAGE_ID, name: 'Connected Guest' }]);

        const result = await service.list(ORG_ID, {} as never);

        expect(result.people[0].currentJourneyStage).toEqual({ id: STAGE_ID, name: 'Connected Guest' });
        expect(Object.keys(result.people[0].currentJourneyStage as object).sort()).toEqual(['id', 'name']);
      });

      it('an organization-customized stage name is returned unchanged, with no hardcoded stage names in the mapping', async () => {
        prisma.person.findMany.mockResolvedValue([buildPersonRow({ id: 'person-1' })]);
        prisma.$queryRaw
          .mockResolvedValueOnce([{ person_id: 'person-1', to_stage_id: STAGE_ID }])
          .mockResolvedValueOnce([]);
        prisma.journeyStage.findMany.mockResolvedValue([{ id: STAGE_ID, name: 'Somos Familia — Etapa 3' }]);

        const result = await service.list(ORG_ID, {} as never);

        expect(result.people[0].currentJourneyStage?.name).toBe('Somos Familia — Etapa 3');
      });

      it('constructs the batch query with DISTINCT ON and movedAt DESC, id DESC ordering (latest-wins / tie-break structure)', async () => {
        prisma.person.findMany.mockResolvedValue([buildPersonRow({ id: 'person-1' })]);

        await service.list(ORG_ID, {} as never);

        const journeySql = (prisma.$queryRaw.mock.calls[0][0] as string[]).join('');
        expect(journeySql).toContain('DISTINCT ON (h.person_id)');
        expect(journeySql).toMatch(/ORDER BY h\.person_id, h\.moved_at DESC, h\.id DESC/);
      });

      it('scopes the batch query to the current organization and only the current-page person IDs', async () => {
        prisma.person.findMany.mockResolvedValue([
          buildPersonRow({ id: 'person-1' }),
          buildPersonRow({ id: 'person-2' }),
        ]);

        await service.list(ORG_ID, { limit: 2 } as never);

        const journeyCallArgs = prisma.$queryRaw.mock.calls[0];
        expect(journeyCallArgs[1]).toBe(ORG_ID);
        expect((journeyCallArgs[2] as { values: string[] }).values).toEqual(['person-1', 'person-2']);
      });

      it('a stage that does not belong to this organization cannot leak into the response', async () => {
        prisma.person.findMany.mockResolvedValue([buildPersonRow({ id: 'person-1' })]);
        prisma.$queryRaw
          .mockResolvedValueOnce([{ person_id: 'person-1', to_stage_id: STAGE_ID }])
          .mockResolvedValueOnce([]);
        // Simulates the stage not resolving under this organization's own
        // journeyTemplate — the re-validation step must then omit it.
        prisma.journeyStage.findMany.mockResolvedValue([]);

        const result = await service.list(ORG_ID, {} as never);

        expect(result.people[0].currentJourneyStage).toBeNull();
        const findManyArgs = prisma.journeyStage.findMany.mock.calls[0][0];
        expect(findManyArgs.where.journeyTemplate).toEqual({ organizationId: ORG_ID });
      });
    });

    describe('latest attendance enrichment', () => {
      it('is null when no attendance exists', async () => {
        prisma.person.findMany.mockResolvedValue([buildPersonRow({ id: 'person-1' })]);

        const result = await service.list(ORG_ID, {} as never);

        expect(result.people[0].lastAttendance).toBeNull();
      });

      it('returns exactly {checkedInAt} when attendance exists', async () => {
        prisma.person.findMany.mockResolvedValue([buildPersonRow({ id: 'person-1' })]);
        prisma.$queryRaw
          .mockResolvedValueOnce([]) // journey batch
          .mockResolvedValueOnce([{ person_id: 'person-1', checked_in_at: new Date('2026-05-25T09:00:00.000Z') }]);

        const result = await service.list(ORG_ID, {} as never);

        expect(result.people[0].lastAttendance).toEqual({ checkedInAt: '2026-05-25T09:00:00.000Z' });
        expect(Object.keys(result.people[0].lastAttendance as object)).toEqual(['checkedInAt']);
      });

      it('constructs the batch query with DISTINCT ON and checkedInAt DESC, id DESC ordering (latest-wins / tie-break structure)', async () => {
        prisma.person.findMany.mockResolvedValue([buildPersonRow({ id: 'person-1' })]);

        await service.list(ORG_ID, {} as never);

        const attendanceSql = (prisma.$queryRaw.mock.calls[1][0] as string[]).join('');
        expect(attendanceSql).toContain('DISTINCT ON (person_id)');
        expect(attendanceSql).toMatch(/ORDER BY person_id, checked_in_at DESC, id DESC/);
      });

      it('scopes the batch query to the current organization and only the current-page person IDs', async () => {
        prisma.person.findMany.mockResolvedValue([
          buildPersonRow({ id: 'person-1' }),
          buildPersonRow({ id: 'person-2' }),
        ]);

        await service.list(ORG_ID, { limit: 2 } as never);

        const attendanceCallArgs = prisma.$queryRaw.mock.calls[1];
        expect(attendanceCallArgs[1]).toBe(ORG_ID);
        expect((attendanceCallArgs[2] as { values: string[] }).values).toEqual(['person-1', 'person-2']);
      });

      it('never includes event detail, status, or the attendance id', async () => {
        prisma.person.findMany.mockResolvedValue([buildPersonRow({ id: 'person-1' })]);
        prisma.$queryRaw
          .mockResolvedValueOnce([])
          .mockResolvedValueOnce([{ person_id: 'person-1', checked_in_at: new Date('2026-05-25T09:00:00.000Z') }]);

        const result = await service.list(ORG_ID, {} as never);

        expect(result.people[0].lastAttendance).not.toHaveProperty('event');
        expect(result.people[0].lastAttendance).not.toHaveProperty('status');
        expect(result.people[0].lastAttendance).not.toHaveProperty('id');
      });
    });

    it('does not run journey or attendance enrichment queries for an empty page', async () => {
      prisma.person.findMany.mockResolvedValue([]);

      const result = await service.list(ORG_ID, {} as never);

      expect(result.people).toEqual([]);
      expect(prisma.$queryRaw).not.toHaveBeenCalled();
      expect(prisma.journeyStage.findMany).not.toHaveBeenCalled();
    });

    it('runs exactly one journey batch query and one attendance batch query regardless of page size (no per-person query loop)', async () => {
      prisma.person.findMany.mockResolvedValue([
        buildPersonRow({ id: 'person-1' }),
        buildPersonRow({ id: 'person-2' }),
        buildPersonRow({ id: 'person-3' }),
        buildPersonRow({ id: 'person-4' }),
        buildPersonRow({ id: 'person-5' }),
      ]);

      await service.list(ORG_ID, { limit: 5 } as never);

      // Exactly two $queryRaw calls total for a 5-person page: one journey
      // batch, one attendance batch — never one call per person (5 people
      // would otherwise mean 5+ calls under an N+1 pattern).
      expect(prisma.$queryRaw).toHaveBeenCalledTimes(2);
    });

    it('does not leak another organization journey stage even when to_stage_id is present, by re-validating against journeyTemplate.organizationId', async () => {
      prisma.person.findMany.mockResolvedValue([buildPersonRow({ id: 'person-1' })]);
      const OTHER_STAGE_ID = '33333333-3333-3333-3333-333333333333';
      prisma.$queryRaw
        .mockResolvedValueOnce([{ person_id: 'person-1', to_stage_id: OTHER_STAGE_ID }])
        .mockResolvedValueOnce([]);
      prisma.journeyStage.findMany.mockResolvedValue([]);

      const result = await service.list(ORG_ID, {} as never);

      expect(result.people[0].currentJourneyStage).toBeNull();
    });

    it('does not add address, gender, dateOfBirth, or tags to the List response', async () => {
      prisma.person.findMany.mockResolvedValue([buildPersonRow({ id: 'person-1' })]);

      const result = await service.list(ORG_ID, {} as never);

      expect(result.people[0]).not.toHaveProperty('address');
      expect(result.people[0]).not.toHaveProperty('gender');
      expect(result.people[0]).not.toHaveProperty('dateOfBirth');
      expect(result.people[0]).not.toHaveProperty('tags');
    });
  });

  describe('detail', () => {
    it('scopes by id + organizationId + deletedAt null', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      await expect(service.detail(ORG_ID, 'person-1')).rejects.toThrow();

      const args = prisma.person.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'person-1', organizationId: ORG_ID, deletedAt: null });
    });

    it('throws PERSON_NOT_FOUND for a cross-tenant or deleted person', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.detail(ORG_ID, 'person-1');
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('PERSON_NOT_FOUND');
    });

    it('orders tags by name asc then id asc', async () => {
      prisma.person.findFirst.mockResolvedValue(buildPersonRow());
      prisma.personTag.findMany.mockResolvedValue([]);
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);

      await service.detail(ORG_ID, 'person-1');

      const args = prisma.personTag.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual([{ tag: { name: 'asc' } }, { tag: { id: 'asc' } }]);
    });

    it('uses the latest PersonJourneyHistory (movedAt desc, id desc) for currentJourneyStage', async () => {
      prisma.person.findFirst.mockResolvedValue(buildPersonRow());
      prisma.personTag.findMany.mockResolvedValue([]);
      prisma.personJourneyHistory.findFirst.mockResolvedValue({
        toStage: { id: STAGE_ID, name: 'Visitor' },
      });

      const result = await service.detail(ORG_ID, 'person-1');

      const args = prisma.personJourneyHistory.findFirst.mock.calls[0][0];
      expect(args.orderBy).toEqual([{ movedAt: 'desc' }, { id: 'desc' }]);
      expect(result.person.currentJourneyStage).toEqual({ id: STAGE_ID, name: 'Visitor' });
    });

    it('returns currentJourneyStage null when there is no history', async () => {
      prisma.person.findFirst.mockResolvedValue(buildPersonRow());
      prisma.personTag.findMany.mockResolvedValue([]);
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);

      const result = await service.detail(ORG_ID, 'person-1');

      expect(result.person.currentJourneyStage).toBeNull();
    });

    it('excludes journey history, attendance, follow-ups, and notes from the response', async () => {
      prisma.person.findFirst.mockResolvedValue(buildPersonRow());
      prisma.personTag.findMany.mockResolvedValue([]);
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);

      const result = await service.detail(ORG_ID, 'person-1');

      expect(result.person).not.toHaveProperty('journeyHistory');
      expect(result.person).not.toHaveProperty('attendance');
      expect(result.person).not.toHaveProperty('lastAttendance');
      expect(result.person).not.toHaveProperty('followUps');
      expect(result.person).not.toHaveProperty('notes');
    });

    it('maps the exact approved detail shape (Product Task 039: gender/dateOfBirth/address widened onto Detail only)', async () => {
      prisma.person.findFirst.mockResolvedValue(
        buildPersonRow({ gender: 'FEMALE', dateOfBirth: new Date(Date.UTC(1990, 11, 10)), address: '221B Baker Street' }),
      );
      prisma.personTag.findMany.mockResolvedValue([{ tag: { id: 'tag-1', name: 'VIP' } }]);
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);

      const result = await service.detail(ORG_ID, 'person-1');

      expect(result).toEqual({
        person: {
          id: 'person-1',
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: null,
          phone: null,
          status: 'ACTIVE',
          avatarUrl: null,
          joinedAt: '2026-01-01T00:00:00.000Z',
          tags: [{ id: 'tag-1', name: 'VIP' }],
          currentJourneyStage: null,
          gender: 'FEMALE',
          dateOfBirth: '1990-12-10',
          address: '221B Baker Street',
        },
      });
    });

    it('maps gender through unchanged', async () => {
      prisma.person.findFirst.mockResolvedValue(buildPersonRow({ gender: 'MALE' }));
      prisma.personTag.findMany.mockResolvedValue([]);
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);

      const result = await service.detail(ORG_ID, 'person-1');

      expect(result.person.gender).toBe('MALE');
    });

    it('formats dateOfBirth as exact YYYY-MM-DD using UTC calendar components, never a local-time conversion', async () => {
      prisma.person.findFirst.mockResolvedValue(buildPersonRow({ dateOfBirth: new Date(Date.UTC(2001, 0, 5)) }));
      prisma.personTag.findMany.mockResolvedValue([]);
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);

      const result = await service.detail(ORG_ID, 'person-1');

      expect(result.person.dateOfBirth).toBe('2001-01-05');
    });

    it('maps address through unchanged', async () => {
      prisma.person.findFirst.mockResolvedValue(buildPersonRow({ address: '10 Downing Street' }));
      prisma.personTag.findMany.mockResolvedValue([]);
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);

      const result = await service.detail(ORG_ID, 'person-1');

      expect(result.person.address).toBe('10 Downing Street');
    });

    it('preserves null for gender, dateOfBirth, and address when unset', async () => {
      prisma.person.findFirst.mockResolvedValue(buildPersonRow({ gender: null, dateOfBirth: null, address: null }));
      prisma.personTag.findMany.mockResolvedValue([]);
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);

      const result = await service.detail(ORG_ID, 'person-1');

      expect(result.person.gender).toBeNull();
      expect(result.person.dateOfBirth).toBeNull();
      expect(result.person.address).toBeNull();
    });

    it('requests gender, dateOfBirth, and address in the Prisma select (Detail-only, never the shared list/create/update select)', async () => {
      prisma.person.findFirst.mockResolvedValue(buildPersonRow());
      prisma.personTag.findMany.mockResolvedValue([]);
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);

      await service.detail(ORG_ID, 'person-1');

      const args = prisma.person.findFirst.mock.calls[0][0];
      expect(args.select).toMatchObject({ gender: true, dateOfBirth: true, address: true });
    });
  });

  describe('create', () => {
    it('defaults status to ACTIVE and passes normalized dto values through', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow({ id: 'person-new' }));

      await service.create(ORG_ID, { firstName: 'Ada', lastName: 'Lovelace' } as never);

      const args = prisma.person.create.mock.calls[0][0];
      expect(args.data).toEqual({
        organizationId: ORG_ID,
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: null,
        phone: null,
        status: 'ACTIVE',
        gender: null,
        dateOfBirth: null,
        address: null,
      });
    });

    it('persists MALE exactly as MALE', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow());

      await service.create(ORG_ID, { firstName: 'Ada', lastName: 'Lovelace', gender: 'MALE' } as never);

      const args = prisma.person.create.mock.calls[0][0];
      expect(args.data.gender).toBe('MALE');
    });

    it('persists FEMALE exactly as FEMALE', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow());

      await service.create(ORG_ID, { firstName: 'Ada', lastName: 'Lovelace', gender: 'FEMALE' } as never);

      const args = prisma.person.create.mock.calls[0][0];
      expect(args.data.gender).toBe('FEMALE');
    });

    it('persists an omitted gender as null', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow());

      await service.create(ORG_ID, { firstName: 'Ada', lastName: 'Lovelace' } as never);

      const args = prisma.person.create.mock.calls[0][0];
      expect(args.data.gender).toBeNull();
    });

    it('persists a valid dateOfBirth without shifting the calendar day', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow());

      await service.create(ORG_ID, { firstName: 'Ada', lastName: 'Lovelace', dateOfBirth: '2001-07-14' } as never);

      const args = prisma.person.create.mock.calls[0][0];
      const persisted = args.data.dateOfBirth as Date;
      expect(persisted.getUTCFullYear()).toBe(2001);
      expect(persisted.getUTCMonth()).toBe(6);
      expect(persisted.getUTCDate()).toBe(14);
    });

    it('persists a leap-day dateOfBirth correctly', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow());

      await service.create(ORG_ID, { firstName: 'Ada', lastName: 'Lovelace', dateOfBirth: '2000-02-29' } as never);

      const args = prisma.person.create.mock.calls[0][0];
      const persisted = args.data.dateOfBirth as Date;
      expect(persisted.getUTCFullYear()).toBe(2000);
      expect(persisted.getUTCMonth()).toBe(1);
      expect(persisted.getUTCDate()).toBe(29);
    });

    it('persists an omitted dateOfBirth as null', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow());

      await service.create(ORG_ID, { firstName: 'Ada', lastName: 'Lovelace' } as never);

      const args = prisma.person.create.mock.calls[0][0];
      expect(args.data.dateOfBirth).toBeNull();
    });

    it('persists an already-normalized address value', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow());

      await service.create(ORG_ID, { firstName: 'Ada', lastName: 'Lovelace', address: '123 Main St' } as never);

      const args = prisma.person.create.mock.calls[0][0];
      expect(args.data.address).toBe('123 Main St');
    });

    it('persists an omitted address as null', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow());

      await service.create(ORG_ID, { firstName: 'Ada', lastName: 'Lovelace' } as never);

      const args = prisma.person.create.mock.calls[0][0];
      expect(args.data.address).toBeNull();
    });

    it('still constructs create data explicitly, never spreading the dto', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow());

      await service.create(ORG_ID, {
        firstName: 'Ada',
        lastName: 'Lovelace',
        gender: 'FEMALE',
        dateOfBirth: '2001-07-14',
        address: '123 Main St',
      } as never);

      const args = prisma.person.create.mock.calls[0][0];
      expect(Object.keys(args.data).sort()).toEqual(
        [
          'organizationId',
          'firstName',
          'lastName',
          'email',
          'phone',
          'status',
          'gender',
          'dateOfBirth',
          'address',
        ].sort(),
      );
    });

    it('does not perform any duplicate email/phone check', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow());

      await service.create(ORG_ID, { firstName: 'Ada', lastName: 'Lovelace', email: 'x@example.com' } as never);

      expect(prisma.person.findFirst).not.toHaveBeenCalled();
      expect(prisma.person.findMany).not.toHaveBeenCalled();
    });

    it('creates no related records (only the person.create call touches the database)', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow());

      await service.create(ORG_ID, { firstName: 'Ada', lastName: 'Lovelace' } as never);

      expect(prisma.personTag.findMany).not.toHaveBeenCalled();
      expect(prisma.personJourneyHistory.findFirst).not.toHaveBeenCalled();
    });

    it('returns the exact approved create response shape', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow({ id: 'person-new' }));

      const result = await service.create(ORG_ID, { firstName: 'Ada', lastName: 'Lovelace' } as never);

      expect(result).toEqual({
        person: {
          id: 'person-new',
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: null,
          phone: null,
          status: 'ACTIVE',
          avatarUrl: null,
          joinedAt: '2026-01-01T00:00:00.000Z',
        },
      });
    });

    it('never echoes gender, dateOfBirth, or address in the create response, even when supplied', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow({ id: 'person-new' }));

      const result = await service.create(ORG_ID, {
        firstName: 'Ada',
        lastName: 'Lovelace',
        gender: 'FEMALE',
        dateOfBirth: '2001-07-14',
        address: '123 Main St',
      } as never);

      expect(result.person).not.toHaveProperty('gender');
      expect(result.person).not.toHaveProperty('dateOfBirth');
      expect(result.person).not.toHaveProperty('address');
    });

    it('does not include currentJourneyStage or lastAttendance — those are List-only enrichment', async () => {
      prisma.person.create.mockResolvedValue(buildPersonRow({ id: 'person-new' }));

      const result = await service.create(ORG_ID, { firstName: 'Ada', lastName: 'Lovelace' } as never);

      expect(result.person).not.toHaveProperty('currentJourneyStage');
      expect(result.person).not.toHaveProperty('lastAttendance');
      expect(prisma.$queryRaw).not.toHaveBeenCalled();
    });
  });

  describe('update', () => {
    it('rejects an update with no fields supplied', async () => {
      await expect(service.update(ORG_ID, 'person-1', {} as never)).rejects.toThrow(
        'At least one field must be supplied.',
      );
      expect(prisma.person.findFirst).not.toHaveBeenCalled();
    });

    it('scopes the update target by organizationId + personId + deletedAt null', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      await expect(service.update(ORG_ID, 'person-1', { firstName: 'New' } as never)).rejects.toThrow();

      const args = prisma.person.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'person-1', organizationId: ORG_ID, deletedAt: null });
    });

    it('throws PERSON_NOT_FOUND for cross-tenant/deleted target', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.update(ORG_ID, 'person-1', { firstName: 'New' } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('PERSON_NOT_FOUND');
    });

    it('null-clears email and phone when explicitly supplied', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: 'person-1' });
      prisma.person.update.mockResolvedValue(buildPersonRow());

      await service.update(ORG_ID, 'person-1', { email: null, phone: null } as never);

      const args = prisma.person.update.mock.calls[0][0];
      expect(args.data).toEqual({ email: null, phone: null });
    });

    it('only writes fields explicitly present in the dto', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: 'person-1' });
      prisma.person.update.mockResolvedValue(buildPersonRow());

      await service.update(ORG_ID, 'person-1', { status: 'INACTIVE' } as never);

      const args = prisma.person.update.mock.calls[0][0];
      expect(args.data).toEqual({ status: 'INACTIVE' });
    });

    it('never mutates tags or journey state', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: 'person-1' });
      prisma.person.update.mockResolvedValue(buildPersonRow());

      await service.update(ORG_ID, 'person-1', { firstName: 'New' } as never);

      expect(prisma.personTag.findMany).not.toHaveBeenCalled();
      expect(prisma.personJourneyHistory.findFirst).not.toHaveBeenCalled();
    });

    it('returns the approved Person summary shape', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: 'person-1' });
      prisma.person.update.mockResolvedValue(buildPersonRow({ firstName: 'Updated' }));

      const result = await service.update(ORG_ID, 'person-1', { firstName: 'Updated' } as never);

      expect(result.person.firstName).toBe('Updated');
      expect(result.person).not.toHaveProperty('tags');
    });

    it('never widens to the Detail-only gender/dateOfBirth/address/currentJourneyStage fields (Product Task 039 boundary)', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: 'person-1' });
      prisma.person.update.mockResolvedValue(buildPersonRow({ firstName: 'Updated' }));

      const result = await service.update(ORG_ID, 'person-1', { firstName: 'Updated' } as never);

      expect(result.person).not.toHaveProperty('gender');
      expect(result.person).not.toHaveProperty('dateOfBirth');
      expect(result.person).not.toHaveProperty('address');
      expect(result.person).not.toHaveProperty('currentJourneyStage');
    });
  });

  describe('remove', () => {
    it('scopes the visible target by id + organizationId + deletedAt null', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      await expect(service.remove(ORG_ID, 'person-1')).rejects.toThrow();

      const args = prisma.person.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'person-1', organizationId: ORG_ID, deletedAt: null });
    });

    it('throws PERSON_NOT_FOUND when absent, cross-tenant, or already deleted', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.remove(ORG_ID, 'person-1');
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('PERSON_NOT_FOUND');
    });

    it('soft-deletes by setting deletedAt, never hard-deleting', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: 'person-1' });
      prisma.person.update.mockResolvedValue({});

      await service.remove(ORG_ID, 'person-1');

      const args = prisma.person.update.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'person-1' });
      expect(args.data.deletedAt).toBeInstanceOf(Date);
    });

    it('returns exactly {success: true}', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: 'person-1' });
      prisma.person.update.mockResolvedValue({});

      const result = await service.remove(ORG_ID, 'person-1');

      expect(result).toEqual({ success: true });
    });

    it('does not delete or rewrite dependent records', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: 'person-1' });
      prisma.person.update.mockResolvedValue({});

      await service.remove(ORG_ID, 'person-1');

      expect(prisma.personTag.findMany).not.toHaveBeenCalled();
      expect(prisma.personJourneyHistory.findFirst).not.toHaveBeenCalled();
    });
  });
});
