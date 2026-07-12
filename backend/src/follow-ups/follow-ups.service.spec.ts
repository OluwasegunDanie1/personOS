import { ApiException } from '../common/http/api-exception';
import { decodeCursor, encodeCursor } from './cursor.util';
import { FollowUpsService } from './follow-ups.service';

const ORG_ID = '11111111-1111-1111-1111-111111111111';
const PERSON_ID = '22222222-2222-2222-2222-222222222222';
const USER_ID = '33333333-3333-3333-3333-333333333333';

function buildFollowUpRow(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'follow-up-1',
    title: 'Call Ada',
    description: null,
    dueDate: new Date('2026-08-02T09:00:00.000Z'),
    status: 'PENDING',
    completedAt: null,
    person: { id: PERSON_ID, firstName: 'Ada', lastName: 'Lovelace' },
    assignedToUser: null,
    ...overrides,
  };
}

function createMockPrisma() {
  return {
    followUp: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    person: { findFirst: jest.fn() },
    organizationMembership: { findUnique: jest.fn() },
  };
}

describe('FollowUpsService', () => {
  let prisma: ReturnType<typeof createMockPrisma>;
  let service: FollowUpsService;

  beforeEach(() => {
    prisma = createMockPrisma();
    service = new FollowUpsService(prisma as never);
  });

  describe('list', () => {
    it('scopes by organizationId', async () => {
      prisma.followUp.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, {});

      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.where.organizationId).toBe(ORG_ID);
    });

    it('applies the status filter exactly', async () => {
      prisma.followUp.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { status: 'IN_PROGRESS' } as never);

      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.where.status).toBe('IN_PROGRESS');
    });

    it('validates assigned_user_id tenant membership before filtering', async () => {
      prisma.organizationMembership.findUnique.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.list(ORG_ID, { assigned_user_id: USER_ID } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('ASSIGNED_USER_NOT_FOUND');
      expect(prisma.followUp.findMany).not.toHaveBeenCalled();
    });

    it('applies the assigned_user_id filter when membership is valid', async () => {
      prisma.organizationMembership.findUnique.mockResolvedValue({ id: 'membership-1' });
      prisma.followUp.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { assigned_user_id: USER_ID } as never);

      const membershipArgs = prisma.organizationMembership.findUnique.mock.calls[0][0];
      expect(membershipArgs.where).toEqual({ organizationId_userId: { organizationId: ORG_ID, userId: USER_ID } });
      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.where.assignedTo).toBe(USER_ID);
    });

    it('validates person_id tenant ownership before filtering', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.list(ORG_ID, { person_id: PERSON_ID } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('PERSON_NOT_FOUND');
      expect(prisma.followUp.findMany).not.toHaveBeenCalled();
    });

    it('applies the person_id filter when the Person is tenant-valid', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.followUp.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { person_id: PERSON_ID } as never);

      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.where.personId).toBe(PERSON_ID);
    });

    it('applies due_date as an exact equality match', async () => {
      prisma.followUp.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { due_date: '2026-08-02T09:00:00Z' } as never);

      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.where.dueDate).toEqual(new Date('2026-08-02T09:00:00Z'));
    });

    it('a null dueDate never matches a supplied due_date filter (equality semantics only)', async () => {
      prisma.followUp.findMany.mockResolvedValue([buildFollowUpRow({ dueDate: null })]);

      const result = await service.list(ORG_ID, { due_date: '2026-08-02T09:00:00Z' } as never);

      // The where clause is an exact equality match; Prisma's equality
      // filter structurally never matches a NULL column value.
      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.where.dueDate).toEqual(new Date('2026-08-02T09:00:00Z'));
      expect(result.followUps).toHaveLength(1); // mock returns unconditionally; real DB enforces the semantics
    });

    it.each([
      ['dueDate_asc', [{ dueDate: { sort: 'asc', nulls: 'last' } }, { id: 'asc' }]],
      ['dueDate_desc', [{ dueDate: { sort: 'desc', nulls: 'last' } }, { id: 'asc' }]],
      ['title_asc', [{ title: 'asc' }, { id: 'asc' }]],
    ])('implements %s ordering exactly', async (sort, expectedOrderBy) => {
      prisma.followUp.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { sort } as never);

      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual(expectedOrderBy);
    });

    it('defaults to dueDate_asc when no sort is supplied', async () => {
      prisma.followUp.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, {});

      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual([{ dueDate: { sort: 'asc', nulls: 'last' } }, { id: 'asc' }]);
    });

    it('defaults limit to 20 and requests limit+1 rows', async () => {
      prisma.followUp.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, {});

      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.take).toBe(21);
    });

    const CURSOR_ID_1 = '66666666-6666-6666-6666-666666666666';
    const CURSOR_ID_2 = '77777777-7777-7777-7777-777777777777';

    it('paginates continuity: opaque cursor round-trips to the last row id per sort', async () => {
      prisma.followUp.findMany.mockResolvedValue([
        buildFollowUpRow({ id: CURSOR_ID_1 }),
        buildFollowUpRow({ id: CURSOR_ID_2 }),
      ]);

      const result = await service.list(ORG_ID, { limit: 1, sort: 'title_asc' } as never);

      expect(result.followUps).toHaveLength(1);
      expect(decodeCursor(result.nextCursor as string, 'title_asc')).toBe(CURSOR_ID_1);
    });

    it('passes a decoded cursor id to Prisma native cursor+skip', async () => {
      prisma.followUp.findMany.mockResolvedValue([]);
      const cursor = encodeCursor({ id: CURSOR_ID_1, sort: 'title_asc' });

      await service.list(ORG_ID, { cursor, sort: 'title_asc' } as never);

      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.cursor).toEqual({ id: CURSOR_ID_1 });
      expect(args.skip).toBe(1);
    });

    it('rejects a cursor generated for a different sort (cross-sort reuse)', async () => {
      const cursor = encodeCursor({ id: CURSOR_ID_1, sort: 'dueDate_desc' });

      await expect(service.list(ORG_ID, { cursor, sort: 'title_asc' } as never)).rejects.toThrow();
      expect(prisma.followUp.findMany).not.toHaveBeenCalled();
    });

    it('rejects a malformed cursor', async () => {
      await expect(service.list(ORG_ID, { cursor: 'garbage' } as never)).rejects.toThrow();
    });

    it('returns the exact approved empty list shape', async () => {
      prisma.followUp.findMany.mockResolvedValue([]);

      const result = await service.list(ORG_ID, {});

      expect(result).toEqual({ followUps: [], nextCursor: null });
    });

    it('maps the exact approved list-item shape', async () => {
      prisma.followUp.findMany.mockResolvedValue([buildFollowUpRow()]);

      const result = await service.list(ORG_ID, {});

      expect(result.followUps[0]).toEqual({
        id: 'follow-up-1',
        title: 'Call Ada',
        description: null,
        dueDate: '2026-08-02T09:00:00.000Z',
        status: 'PENDING',
        completedAt: null,
        person: { id: PERSON_ID, firstName: 'Ada', lastName: 'Lovelace' },
        assignedTo: null,
      });
    });
  });

  describe('detail', () => {
    it('scopes by id + organizationId', async () => {
      prisma.followUp.findFirst.mockResolvedValue(null);

      await expect(service.detail(ORG_ID, 'follow-up-1')).rejects.toThrow();

      const args = prisma.followUp.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'follow-up-1', organizationId: ORG_ID });
    });

    it('throws FOLLOW_UP_NOT_FOUND for a cross-tenant/absent FollowUp', async () => {
      prisma.followUp.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.detail(ORG_ID, 'follow-up-1');
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('FOLLOW_UP_NOT_FOUND');
    });
  });

  describe('create', () => {
    it('validates the Person belongs to the organization', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.create(ORG_ID, { personId: PERSON_ID, title: 'Call Ada' } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('PERSON_NOT_FOUND');
      expect(prisma.followUp.create).not.toHaveBeenCalled();
    });

    it('rejects a cross-tenant/non-member assignedTo', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.organizationMembership.findUnique.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.create(ORG_ID, { personId: PERSON_ID, title: 'Call Ada', assignedTo: USER_ID } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('ASSIGNED_USER_NOT_FOUND');
      expect(prisma.followUp.create).not.toHaveBeenCalled();
    });

    it('derives status PENDING and completedAt null, ignoring any client-side attempt', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.followUp.create.mockResolvedValue(buildFollowUpRow());

      await service.create(ORG_ID, { personId: PERSON_ID, title: 'Call Ada' } as never);

      const args = prisma.followUp.create.mock.calls[0][0];
      expect(args.data.status).toBe('PENDING');
      expect(args.data.completedAt).toBeNull();
      expect(args.data.organizationId).toBe(ORG_ID);
    });

    it('normalizes optional fields to null when absent', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.followUp.create.mockResolvedValue(buildFollowUpRow());

      await service.create(ORG_ID, { personId: PERSON_ID, title: 'Call Ada' } as never);

      const args = prisma.followUp.create.mock.calls[0][0];
      expect(args.data.description).toBeNull();
      expect(args.data.dueDate).toBeNull();
      expect(args.data.assignedTo).toBeNull();
    });

    it('returns the exact approved create response shape', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.followUp.create.mockResolvedValue(buildFollowUpRow());

      const result = await service.create(ORG_ID, { personId: PERSON_ID, title: 'Call Ada' } as never);

      expect(result).toEqual({
        followUp: {
          id: 'follow-up-1',
          title: 'Call Ada',
          description: null,
          dueDate: '2026-08-02T09:00:00.000Z',
          status: 'PENDING',
          completedAt: null,
          person: { id: PERSON_ID, firstName: 'Ada', lastName: 'Lovelace' },
          assignedTo: null,
        },
      });
    });
  });

  describe('update', () => {
    it('rejects an update with no fields supplied', async () => {
      await expect(service.update(ORG_ID, 'follow-up-1', {} as never)).rejects.toThrow(
        'At least one field must be supplied.',
      );
      expect(prisma.followUp.findFirst).not.toHaveBeenCalled();
    });

    it('scopes the update target by id + organizationId', async () => {
      prisma.followUp.findFirst.mockResolvedValue(null);

      await expect(service.update(ORG_ID, 'follow-up-1', { title: 'New' } as never)).rejects.toThrow();

      const args = prisma.followUp.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'follow-up-1', organizationId: ORG_ID });
    });

    it('throws FOLLOW_UP_NOT_FOUND for a cross-tenant/absent target', async () => {
      prisma.followUp.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.update(ORG_ID, 'follow-up-1', { title: 'New' } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('FOLLOW_UP_NOT_FOUND');
    });

    it('accepts PENDING and IN_PROGRESS status writes on a non-completed FollowUp', async () => {
      prisma.followUp.findFirst.mockResolvedValue({ id: 'follow-up-1', status: 'PENDING' });
      prisma.followUp.update.mockResolvedValue(buildFollowUpRow({ status: 'IN_PROGRESS' }));

      await service.update(ORG_ID, 'follow-up-1', { status: 'IN_PROGRESS' } as never);

      const args = prisma.followUp.update.mock.calls[0][0];
      expect(args.data.status).toBe('IN_PROGRESS');
    });

    it('the DTO layer is the sole gate against COMPLETED; the service also never special-cases it as acceptable', async () => {
      prisma.followUp.findFirst.mockResolvedValue({ id: 'follow-up-1', status: 'PENDING' });
      prisma.followUp.update.mockResolvedValue(buildFollowUpRow());

      // Simulates a value that bypassed the DTO allowlist (defense in depth
      // is the DTO's @IsIn; this proves the service does not itself special
      // case COMPLETED as a valid write target when status !== COMPLETED already).
      await service.update(ORG_ID, 'follow-up-1', { status: 'IN_PROGRESS' } as never);

      expect(prisma.followUp.update).toHaveBeenCalledTimes(1);
    });

    it('never accepts completedAt (not part of the data payload even if present on the dto object)', async () => {
      prisma.followUp.findFirst.mockResolvedValue({ id: 'follow-up-1', status: 'PENDING' });
      prisma.followUp.update.mockResolvedValue(buildFollowUpRow());

      await service.update(ORG_ID, 'follow-up-1', {
        title: 'New',
        completedAt: '2020-01-01T00:00:00Z',
      } as never);

      const args = prisma.followUp.update.mock.calls[0][0];
      expect(args.data).not.toHaveProperty('completedAt');
    });

    it('rejects any status write on an already-COMPLETED FollowUp with FOLLOW_UP_ALREADY_COMPLETED', async () => {
      prisma.followUp.findFirst.mockResolvedValue({ id: 'follow-up-1', status: 'COMPLETED' });

      let error: ApiException | undefined;
      try {
        await service.update(ORG_ID, 'follow-up-1', { status: 'PENDING' } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('FOLLOW_UP_ALREADY_COMPLETED');
      expect(prisma.followUp.update).not.toHaveBeenCalled();
    });

    it('allows non-status fields to remain editable on an already-COMPLETED FollowUp', async () => {
      prisma.followUp.findFirst.mockResolvedValue({ id: 'follow-up-1', status: 'COMPLETED' });
      prisma.followUp.update.mockResolvedValue(buildFollowUpRow({ status: 'COMPLETED', title: 'Updated title' }));

      const result = await service.update(ORG_ID, 'follow-up-1', { title: 'Updated title' } as never);

      const args = prisma.followUp.update.mock.calls[0][0];
      expect(args.data).toEqual({ title: 'Updated title' });
      expect(result.followUp.status).toBe('COMPLETED');
    });

    it('rejects a cross-tenant/non-member assignedTo on update', async () => {
      prisma.followUp.findFirst.mockResolvedValue({ id: 'follow-up-1', status: 'PENDING' });
      prisma.organizationMembership.findUnique.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.update(ORG_ID, 'follow-up-1', { assignedTo: USER_ID } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('ASSIGNED_USER_NOT_FOUND');
      expect(prisma.followUp.update).not.toHaveBeenCalled();
    });

    it('allows unassigning by explicit null without a membership check', async () => {
      prisma.followUp.findFirst.mockResolvedValue({ id: 'follow-up-1', status: 'PENDING' });
      prisma.followUp.update.mockResolvedValue(buildFollowUpRow({ assignedToUser: null }));

      await service.update(ORG_ID, 'follow-up-1', { assignedTo: null } as never);

      expect(prisma.organizationMembership.findUnique).not.toHaveBeenCalled();
      const args = prisma.followUp.update.mock.calls[0][0];
      expect(args.data.assignedTo).toBeNull();
    });

    it('only writes fields explicitly present in the dto', async () => {
      prisma.followUp.findFirst.mockResolvedValue({ id: 'follow-up-1', status: 'PENDING' });
      prisma.followUp.update.mockResolvedValue(buildFollowUpRow());

      await service.update(ORG_ID, 'follow-up-1', { title: 'Updated' } as never);

      const args = prisma.followUp.update.mock.calls[0][0];
      expect(args.data).toEqual({ title: 'Updated' });
    });
  });

  describe('complete', () => {
    it('scopes by id + organizationId', async () => {
      prisma.followUp.findFirst.mockResolvedValue(null);

      await expect(service.complete(ORG_ID, 'follow-up-1')).rejects.toThrow();

      const args = prisma.followUp.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'follow-up-1', organizationId: ORG_ID });
    });

    it('throws FOLLOW_UP_NOT_FOUND for a cross-tenant/absent FollowUp', async () => {
      prisma.followUp.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.complete(ORG_ID, 'follow-up-1');
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('FOLLOW_UP_NOT_FOUND');
    });

    it('writes status COMPLETED and a server-derived completedAt for a non-completed FollowUp', async () => {
      prisma.followUp.findFirst.mockResolvedValue(buildFollowUpRow({ status: 'PENDING', completedAt: null }));
      prisma.followUp.update.mockResolvedValue(
        buildFollowUpRow({ status: 'COMPLETED', completedAt: new Date('2026-08-05T00:00:00.000Z') }),
      );
      const before = Date.now();

      await service.complete(ORG_ID, 'follow-up-1');

      const args = prisma.followUp.update.mock.calls[0][0];
      expect(args.data.status).toBe('COMPLETED');
      expect(args.data.completedAt).toBeInstanceOf(Date);
      expect((args.data.completedAt as Date).getTime()).toBeGreaterThanOrEqual(before);
    });

    it('is idempotent: repeating Complete on an already-COMPLETED FollowUp does not call update and preserves completedAt', async () => {
      const completedAt = new Date('2026-08-01T00:00:00.000Z');
      prisma.followUp.findFirst.mockResolvedValue(
        buildFollowUpRow({ status: 'COMPLETED', completedAt }),
      );

      const result = await service.complete(ORG_ID, 'follow-up-1');

      expect(prisma.followUp.update).not.toHaveBeenCalled();
      expect(result.followUp.completedAt).toBe(completedAt.toISOString());
      expect(result.followUp.status).toBe('COMPLETED');
    });

    it('creates no unapproved side-effect records (mock exposes only followUp/person/organizationMembership)', async () => {
      prisma.followUp.findFirst.mockResolvedValue(buildFollowUpRow({ status: 'PENDING', completedAt: null }));
      prisma.followUp.update.mockResolvedValue(buildFollowUpRow({ status: 'COMPLETED' }));

      await service.complete(ORG_ID, 'follow-up-1');

      expect(Object.keys(prisma).sort()).toEqual(['followUp', 'organizationMembership', 'person'].sort());
    });
  });
});
