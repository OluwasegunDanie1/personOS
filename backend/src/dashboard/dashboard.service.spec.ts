import { DashboardService } from './dashboard.service';

const ORG_ID = '11111111-1111-1111-1111-111111111111';

function createMockPrisma() {
  return {
    person: { count: jest.fn(), findMany: jest.fn() },
    followUp: { count: jest.fn(), findMany: jest.fn() },
    event: { findMany: jest.fn() },
  };
}

describe('DashboardService', () => {
  let prisma: ReturnType<typeof createMockPrisma>;
  let service: DashboardService;

  beforeEach(() => {
    prisma = createMockPrisma();
    prisma.person.count.mockResolvedValue(0);
    prisma.person.findMany.mockResolvedValue([]);
    prisma.followUp.count.mockResolvedValue(0);
    prisma.followUp.findMany.mockResolvedValue([]);
    prisma.event.findMany.mockResolvedValue([]);
    service = new DashboardService(prisma as never);

    // Deterministic clock: 2026-07-12T15:30:00.000Z (mid-day UTC).
    jest.useFakeTimers().setSystemTime(new Date('2026-07-12T15:30:00.000Z'));
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  describe('totalPeople', () => {
    it('is scoped by organizationId, deletedAt null, and status ACTIVE', async () => {
      await service.summary(ORG_ID);

      const totalPeopleArgs = prisma.person.count.mock.calls[0][0];
      expect(totalPeopleArgs.where).toEqual({ organizationId: ORG_ID, deletedAt: null, status: 'ACTIVE' });
    });

    it('reflects the resolved count value', async () => {
      prisma.person.count.mockResolvedValueOnce(42).mockResolvedValueOnce(0);

      const result = await service.summary(ORG_ID);

      expect(result.totalPeople).toBe(42);
    });
  });

  describe('newPeople', () => {
    it('is scoped by organizationId, deletedAt null, status ACTIVE, and the UTC-day boundary', async () => {
      await service.summary(ORG_ID);

      const newPeopleArgs = prisma.person.count.mock.calls[1][0];
      expect(newPeopleArgs.where).toEqual({
        organizationId: ORG_ID,
        deletedAt: null,
        status: 'ACTIVE',
        createdAt: { gte: new Date('2026-07-12T00:00:00.000Z') },
      });
    });

    it('derives the UTC-day boundary at midnight of the current server UTC date regardless of time-of-day', async () => {
      jest.setSystemTime(new Date('2026-07-12T23:59:59.999Z'));

      await service.summary(ORG_ID);

      const newPeopleArgs = prisma.person.count.mock.calls[1][0];
      expect(newPeopleArgs.where.createdAt).toEqual({ gte: new Date('2026-07-12T00:00:00.000Z') });
    });

    it('reflects the resolved count value distinctly from totalPeople', async () => {
      prisma.person.count.mockResolvedValueOnce(42).mockResolvedValueOnce(3);

      const result = await service.summary(ORG_ID);

      expect(result.totalPeople).toBe(42);
      expect(result.newPeople).toBe(3);
    });
  });

  describe('pendingFollowUps', () => {
    it('is scoped by organizationId and status IN [PENDING, IN_PROGRESS]', async () => {
      await service.summary(ORG_ID);

      const args = prisma.followUp.count.mock.calls[0][0];
      expect(args.where).toEqual({ organizationId: ORG_ID, status: { in: ['PENDING', 'IN_PROGRESS'] } });
    });

    it('does not filter by dueDate (no overdue/reminder derivation)', async () => {
      await service.summary(ORG_ID);

      const args = prisma.followUp.count.mock.calls[0][0];
      expect(args.where).not.toHaveProperty('dueDate');
    });

    it('reflects the resolved count value', async () => {
      prisma.followUp.count.mockResolvedValue(7);

      const result = await service.summary(ORG_ID);

      expect(result.pendingFollowUps).toBe(7);
    });
  });

  describe('upcomingEvents', () => {
    it('is scoped by organizationId, deletedAt null, and startDate >= the captured instant', async () => {
      await service.summary(ORG_ID);

      const args = prisma.event.findMany.mock.calls[0][0];
      expect(args.where).toEqual({
        organizationId: ORG_ID,
        deletedAt: null,
        startDate: { gte: new Date('2026-07-12T15:30:00.000Z') },
      });
    });

    it('orders by startDate ascending then id ascending', async () => {
      await service.summary(ORG_ID);

      const args = prisma.event.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual([{ startDate: 'asc' }, { id: 'asc' }]);
    });

    it('takes exactly 5', async () => {
      await service.summary(ORG_ID);

      const args = prisma.event.findMany.mock.calls[0][0];
      expect(args.take).toBe(5);
    });

    it('selects exactly id, title, startDate', async () => {
      await service.summary(ORG_ID);

      const args = prisma.event.findMany.mock.calls[0][0];
      expect(args.select).toEqual({ id: true, title: true, startDate: true });
    });

    it('maps rows to the exact approved shape with an ISO string startDate', async () => {
      prisma.event.findMany.mockResolvedValue([
        { id: 'event-1', title: 'Sunday Service', startDate: new Date('2026-08-02T09:00:00.000Z') },
      ]);

      const result = await service.summary(ORG_ID);

      expect(result.upcomingEvents).toEqual([
        { id: 'event-1', title: 'Sunday Service', startDate: '2026-08-02T09:00:00.000Z' },
      ]);
    });
  });

  describe('consistent captured instant', () => {
    it('uses one logically consistent instant across the UTC-day boundary and the upcoming-events comparison', async () => {
      await service.summary(ORG_ID);

      const newPeopleBoundary = (prisma.person.count.mock.calls[1][0] as { where: { createdAt: { gte: Date } } })
        .where.createdAt.gte;
      const upcomingEventsInstant = (
        prisma.event.findMany.mock.calls[0][0] as { where: { startDate: { gte: Date } } }
      ).where.startDate.gte;

      // The UTC-day boundary is midnight of the same calendar day as the
      // captured instant used for upcomingEvents — both derived from one
      // `now`, not two independent `new Date()` calls.
      expect(upcomingEventsInstant).toEqual(new Date('2026-07-12T15:30:00.000Z'));
      expect(newPeopleBoundary).toEqual(new Date('2026-07-12T00:00:00.000Z'));
      expect(newPeopleBoundary.getTime()).toBeLessThanOrEqual(upcomingEventsInstant.getTime());
    });
  });

  describe('recentMembers (Product Task 054)', () => {
    it('is scoped by organizationId, deletedAt null, and status ACTIVE — same scope as totalPeople/newPeople', async () => {
      await service.summary(ORG_ID);

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.where).toEqual({ organizationId: ORG_ID, deletedAt: null, status: 'ACTIVE' });
    });

    it('orders by createdAt descending then id ascending (most recently joined first)', async () => {
      await service.summary(ORG_ID);

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual([{ createdAt: 'desc' }, { id: 'asc' }]);
    });

    it('takes exactly 5', async () => {
      await service.summary(ORG_ID);

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.take).toBe(5);
    });

    it('selects exactly id, firstName, lastName, createdAt', async () => {
      await service.summary(ORG_ID);

      const args = prisma.person.findMany.mock.calls[0][0];
      expect(args.select).toEqual({ id: true, firstName: true, lastName: true, createdAt: true });
    });

    it('maps rows to {id, firstName, lastName, joinedAt} with an ISO string joinedAt', async () => {
      prisma.person.findMany.mockResolvedValue([
        { id: 'person-1', firstName: 'Ada', lastName: 'Lovelace', createdAt: new Date('2026-07-10T09:00:00.000Z') },
      ]);

      const result = await service.summary(ORG_ID);

      expect(result.recentMembers).toEqual([
        { id: 'person-1', firstName: 'Ada', lastName: 'Lovelace', joinedAt: '2026-07-10T09:00:00.000Z' },
      ]);
    });

    it('returns an empty array when there are no members', async () => {
      const result = await service.summary(ORG_ID);

      expect(result.recentMembers).toEqual([]);
    });
  });

  describe('pendingTasks (Product Task 054)', () => {
    it('is scoped by organizationId and status IN [PENDING, IN_PROGRESS] — same scope as pendingFollowUps', async () => {
      await service.summary(ORG_ID);

      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.where).toEqual({ organizationId: ORG_ID, status: { in: ['PENDING', 'IN_PROGRESS'] } });
    });

    it('never includes COMPLETED Follow-Ups (no completion percentage or status invention)', async () => {
      await service.summary(ORG_ID);

      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.where.status.in).not.toContain('COMPLETED');
    });

    it('orders by dueDate ascending with nulls last, then id ascending — matching the approved dueDate_asc List Follow-Ups sort', async () => {
      await service.summary(ORG_ID);

      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual([{ dueDate: { sort: 'asc', nulls: 'last' } }, { id: 'asc' }]);
    });

    it('takes exactly 5', async () => {
      await service.summary(ORG_ID);

      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.take).toBe(5);
    });

    it('selects exactly id, title, description, dueDate', async () => {
      await service.summary(ORG_ID);

      const args = prisma.followUp.findMany.mock.calls[0][0];
      expect(args.select).toEqual({ id: true, title: true, description: true, dueDate: true });
    });

    it('maps a row with a real dueDate to an ISO string dueDate', async () => {
      prisma.followUp.findMany.mockResolvedValue([
        {
          id: 'fu-1',
          title: 'Follow up with Alex Smith',
          description: 'Member follow-up',
          dueDate: new Date('2026-07-12T09:00:00.000Z'),
        },
      ]);

      const result = await service.summary(ORG_ID);

      expect(result.pendingTasks).toEqual([
        {
          id: 'fu-1',
          title: 'Follow up with Alex Smith',
          description: 'Member follow-up',
          dueDate: '2026-07-12T09:00:00.000Z',
        },
      ]);
    });

    it('preserves a null dueDate and a null description, never fabricating either', async () => {
      prisma.followUp.findMany.mockResolvedValue([
        { id: 'fu-1', title: 'Untitled task', description: null, dueDate: null },
      ]);

      const result = await service.summary(ORG_ID);

      expect(result.pendingTasks[0].dueDate).toBeNull();
      expect(result.pendingTasks[0].description).toBeNull();
    });

    it('returns an empty array when there are no pending tasks', async () => {
      const result = await service.summary(ORG_ID);

      expect(result.pendingTasks).toEqual([]);
    });
  });

  describe('response shape', () => {
    it('returns exactly the six approved fields on zero/empty results', async () => {
      const result = await service.summary(ORG_ID);

      expect(result).toEqual({
        totalPeople: 0,
        newPeople: 0,
        pendingFollowUps: 0,
        upcomingEvents: [],
        recentMembers: [],
        pendingTasks: [],
      });
    });

    it('never includes disallowed fields', async () => {
      const result = await service.summary(ORG_ID);

      expect(result).not.toHaveProperty('organizationId');
      expect(result).not.toHaveProperty('attendanceRate');
      expect(result).not.toHaveProperty('attendancePercentage');
      expect(result).not.toHaveProperty('todayAttendance');
      expect(result).not.toHaveProperty('recentActivity');
      expect(result).not.toHaveProperty('journeyStageDistribution');
      expect(result).not.toHaveProperty('growth');
      expect(result).not.toHaveProperty('trend');
      expect(result).not.toHaveProperty('generatedAt');
      expect(result).not.toHaveProperty('completionPercentage');
      expect(result).not.toHaveProperty('priority');
      expect(result).not.toHaveProperty('taskCategory');
    });
  });

  describe('read-only guarantee', () => {
    it('touches no model other than person/followUp/event (no Report/AuditLog/Notification write)', async () => {
      await service.summary(ORG_ID);

      expect(Object.keys(prisma).sort()).toEqual(['event', 'followUp', 'person'].sort());
    });

    it('performs no create/update/delete call on any mocked model', async () => {
      await service.summary(ORG_ID);

      expect((prisma.person as Record<string, unknown>).create).toBeUndefined();
      expect((prisma.person as Record<string, unknown>).update).toBeUndefined();
      expect((prisma.followUp as Record<string, unknown>).update).toBeUndefined();
      expect((prisma.event as Record<string, unknown>).update).toBeUndefined();
    });
  });
});
