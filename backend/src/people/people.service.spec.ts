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
    journeyStage: { findFirst: jest.fn() },
    $queryRaw: jest.fn(),
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
          },
        ],
        nextCursor: null,
      });
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
      expect(result.person).not.toHaveProperty('followUps');
      expect(result.person).not.toHaveProperty('notes');
    });

    it('maps the exact approved detail shape', async () => {
      prisma.person.findFirst.mockResolvedValue(buildPersonRow());
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
        },
      });
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
      });
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
