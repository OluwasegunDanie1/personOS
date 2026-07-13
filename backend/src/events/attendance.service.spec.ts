import { AttendanceStatus, Prisma } from '../../generated/prisma/client';
import { ApiException } from '../common/http/api-exception';
import { AttendanceService } from './attendance.service';
import { decodeCursor, encodeCursor } from './cursor.util';
import { EventsService } from './events.service';

const ORG_ID = '11111111-1111-1111-1111-111111111111';
const EVENT_ID = '22222222-2222-2222-2222-222222222222';
const PERSON_ID = '33333333-3333-3333-3333-333333333333';

function buildAttendanceRow(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'attendance-1',
    status: AttendanceStatus.Present,
    checkedInAt: new Date('2026-08-02T09:05:00.000Z'),
    person: { id: PERSON_ID, firstName: 'Ada', lastName: 'Lovelace' },
    checkedInByUser: { id: 'user-1', firstName: 'Grace', lastName: 'Hopper' },
    ...overrides,
  };
}

function createMockPrisma() {
  return {
    attendance: {
      findMany: jest.fn(),
      create: jest.fn(),
      findUnique: jest.fn(),
      count: jest.fn(),
    },
    person: { findFirst: jest.fn() },
  };
}

function createMockEventsService() {
  return { assertActiveEvent: jest.fn().mockResolvedValue(undefined) };
}

describe('AttendanceService', () => {
  let prisma: ReturnType<typeof createMockPrisma>;
  let eventsService: ReturnType<typeof createMockEventsService>;
  let service: AttendanceService;

  beforeEach(() => {
    prisma = createMockPrisma();
    eventsService = createMockEventsService();
    service = new AttendanceService(prisma as never, eventsService as unknown as EventsService);
  });

  describe('status mapping', () => {
    it.each([
      ['PRESENT', AttendanceStatus.Present],
      ['ABSENT', AttendanceStatus.Absent],
      ['LATE', AttendanceStatus.Late],
    ])('maps public %s to Prisma %s when recording', async (publicStatus, prismaStatus) => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.create.mockResolvedValue(buildAttendanceRow({ status: prismaStatus }));

      await service.record(ORG_ID, EVENT_ID, 'user-1', { personId: PERSON_ID, status: publicStatus } as never);

      const args = prisma.attendance.create.mock.calls[0][0];
      expect(args.data.status).toBe(prismaStatus);
    });

    it.each([
      [AttendanceStatus.Present, 'PRESENT'],
      [AttendanceStatus.Absent, 'ABSENT'],
      [AttendanceStatus.Late, 'LATE'],
    ])('maps Prisma %s back to public %s in responses', async (prismaStatus, publicStatus) => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.create.mockResolvedValue(buildAttendanceRow({ status: prismaStatus }));

      const result = await service.record(ORG_ID, EVENT_ID, 'user-1', { personId: PERSON_ID } as never);

      expect(result.attendance.status).toBe(publicStatus);
    });

    it('never returns internal Prisma casing (lowercase-first) to the client', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.create.mockResolvedValue(buildAttendanceRow({ status: AttendanceStatus.Present }));

      const result = await service.record(ORG_ID, EVENT_ID, 'user-1', { personId: PERSON_ID } as never);

      expect(result.attendance.status).not.toBe('Present');
      expect(result.attendance.status).toBe('PRESENT');
    });
  });

  describe('listForEvent', () => {
    it('validates the Event tenant ownership before reading Attendance', async () => {
      eventsService.assertActiveEvent.mockRejectedValue(
        new ApiException(404, 'EVENT_NOT_FOUND', 'Event not found.'),
      );

      await expect(service.listForEvent(ORG_ID, EVENT_ID, {})).rejects.toThrow();
      expect(prisma.attendance.findMany).not.toHaveBeenCalled();
    });

    it('scopes the query by organizationId and eventId', async () => {
      prisma.attendance.findMany.mockResolvedValue([]);

      await service.listForEvent(ORG_ID, EVENT_ID, {});

      const args = prisma.attendance.findMany.mock.calls[0][0];
      expect(args.where).toEqual({ organizationId: ORG_ID, eventId: EVENT_ID });
    });

    it('never filters by Person.deletedAt (historical visibility after Person soft-deletion)', async () => {
      prisma.attendance.findMany.mockResolvedValue([]);

      await service.listForEvent(ORG_ID, EVENT_ID, {});

      const args = prisma.attendance.findMany.mock.calls[0][0];
      expect(JSON.stringify(args.where)).not.toContain('deletedAt');
    });

    it('maps the public status filter to the Prisma enum', async () => {
      prisma.attendance.findMany.mockResolvedValue([]);

      await service.listForEvent(ORG_ID, EVENT_ID, { status: 'LATE' } as never);

      const args = prisma.attendance.findMany.mock.calls[0][0];
      expect(args.where.status).toBe(AttendanceStatus.Late);
    });

    it.each([
      ['checkedInAt_desc', [{ checkedInAt: 'desc' }, { id: 'asc' }]],
      ['checkedInAt_asc', [{ checkedInAt: 'asc' }, { id: 'asc' }]],
      ['personName_asc', [{ person: { firstName: 'asc' } }, { person: { lastName: 'asc' } }, { id: 'asc' }]],
    ])('implements %s ordering exactly', async (sort, expectedOrderBy) => {
      prisma.attendance.findMany.mockResolvedValue([]);

      await service.listForEvent(ORG_ID, EVENT_ID, { sort } as never);

      const args = prisma.attendance.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual(expectedOrderBy);
    });

    it('defaults to checkedInAt_desc and limit 50', async () => {
      prisma.attendance.findMany.mockResolvedValue([]);

      await service.listForEvent(ORG_ID, EVENT_ID, {});

      const args = prisma.attendance.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual([{ checkedInAt: 'desc' }, { id: 'asc' }]);
      expect(args.take).toBe(51);
    });

    const CURSOR_ID_1 = '66666666-6666-6666-6666-666666666666';
    const CURSOR_ID_2 = '77777777-7777-7777-7777-777777777777';

    it('paginates with an opaque sort-bound cursor', async () => {
      prisma.attendance.findMany.mockResolvedValue([
        buildAttendanceRow({ id: CURSOR_ID_1 }),
        buildAttendanceRow({ id: CURSOR_ID_2 }),
      ]);

      const result = await service.listForEvent(ORG_ID, EVENT_ID, { limit: 1, sort: 'checkedInAt_asc' } as never);

      expect(result.attendance).toHaveLength(1);
      expect(decodeCursor(result.nextCursor as string, 'checkedInAt_asc')).toBe(CURSOR_ID_1);
    });

    it('rejects a malformed cursor', async () => {
      await expect(service.listForEvent(ORG_ID, EVENT_ID, { cursor: 'garbage' } as never)).rejects.toThrow();
    });

    it('rejects cross-sort cursor reuse', async () => {
      const cursor = encodeCursor({ id: CURSOR_ID_1, sort: 'checkedInAt_asc' });

      await expect(
        service.listForEvent(ORG_ID, EVENT_ID, { cursor, sort: 'checkedInAt_desc' } as never),
      ).rejects.toThrow();
      expect(prisma.attendance.findMany).not.toHaveBeenCalled();
    });

    it('returns the exact approved response shape', async () => {
      prisma.attendance.findMany.mockResolvedValue([buildAttendanceRow()]);

      const result = await service.listForEvent(ORG_ID, EVENT_ID, {});

      expect(result).toEqual({
        attendance: [
          {
            id: 'attendance-1',
            person: { id: PERSON_ID, firstName: 'Ada', lastName: 'Lovelace' },
            status: 'PRESENT',
            checkedInBy: { id: 'user-1', firstName: 'Grace', lastName: 'Hopper' },
            checkedInAt: '2026-08-02T09:05:00.000Z',
          },
        ],
        nextCursor: null,
      });
    });
  });

  describe('record', () => {
    it('independently validates the Event and the Person before any write', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.create.mockResolvedValue(buildAttendanceRow());

      await service.record(ORG_ID, EVENT_ID, 'user-1', { personId: PERSON_ID } as never);

      expect(eventsService.assertActiveEvent).toHaveBeenCalledWith(ORG_ID, EVENT_ID);
      const personArgs = prisma.person.findFirst.mock.calls[0][0];
      expect(personArgs.where).toEqual({ id: PERSON_ID, organizationId: ORG_ID, deletedAt: null });
    });

    it('throws PERSON_NOT_FOUND for an absent/cross-tenant/soft-deleted Person', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.record(ORG_ID, EVENT_ID, 'user-1', { personId: PERSON_ID } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('PERSON_NOT_FOUND');
      expect(prisma.attendance.create).not.toHaveBeenCalled();
    });

    it('defaults status to PRESENT when omitted', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.create.mockResolvedValue(buildAttendanceRow());

      await service.record(ORG_ID, EVENT_ID, 'user-1', { personId: PERSON_ID } as never);

      const args = prisma.attendance.create.mock.calls[0][0];
      expect(args.data.status).toBe(AttendanceStatus.Present);
    });

    it('derives organizationId, eventId, checkedInBy, and checkedInAt on the server', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.create.mockResolvedValue(buildAttendanceRow());
      const before = Date.now();

      await service.record(ORG_ID, EVENT_ID, 'user-1', { personId: PERSON_ID } as never);

      const args = prisma.attendance.create.mock.calls[0][0];
      expect(args.data.organizationId).toBe(ORG_ID);
      expect(args.data.eventId).toBe(EVENT_ID);
      expect(args.data.checkedInBy).toBe('user-1');
      expect(args.data.checkedInAt).toBeInstanceOf(Date);
      expect((args.data.checkedInAt as Date).getTime()).toBeGreaterThanOrEqual(before);
    });

    it('allows recording attendance for a past-dated or future-dated Event (no restriction here)', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.create.mockResolvedValue(buildAttendanceRow());

      await expect(
        service.record(ORG_ID, EVENT_ID, 'user-1', { personId: PERSON_ID } as never),
      ).resolves.toBeDefined();
      // The service performs no date comparison against Event.startDate at all.
      expect(eventsService.assertActiveEvent).toHaveBeenCalledTimes(1);
    });

    it('first write creates exactly one row and returns created:true', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.create.mockResolvedValue(buildAttendanceRow());

      const result = await service.record(ORG_ID, EVENT_ID, 'user-1', { personId: PERSON_ID } as never);

      expect(prisma.attendance.create).toHaveBeenCalledTimes(1);
      expect(result.created).toBe(true);
    });

    it('duplicate request returns the existing row unchanged with created:false, ignoring the submitted status', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      const conflict = new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
        code: 'P2002',
        clientVersion: '7.8.0',
      });
      prisma.attendance.create.mockRejectedValue(conflict);
      prisma.attendance.findUnique.mockResolvedValue(buildAttendanceRow({ status: AttendanceStatus.Present }));

      const result = await service.record(ORG_ID, EVENT_ID, 'user-1', {
        personId: PERSON_ID,
        status: 'LATE',
      } as never);

      expect(result.created).toBe(false);
      expect(result.attendance.status).toBe('PRESENT');
      const findUniqueArgs = prisma.attendance.findUnique.mock.calls[0][0];
      expect(findUniqueArgs.where).toEqual({
        organizationId_eventId_personId: { organizationId: ORG_ID, eventId: EVENT_ID, personId: PERSON_ID },
      });
    });

    it('does not use an upsert (no update call exists on the attendance mock at all)', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.create.mockResolvedValue(buildAttendanceRow());

      await service.record(ORG_ID, EVENT_ID, 'user-1', { personId: PERSON_ID } as never);

      expect((prisma.attendance as Record<string, unknown>).update).toBeUndefined();
      expect((prisma.attendance as Record<string, unknown>).upsert).toBeUndefined();
    });

    it('re-throws an unrelated Prisma error unchanged instead of treating it as a duplicate', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      const unrelated = new Prisma.PrismaClientKnownRequestError('Foreign key constraint failed', {
        code: 'P2003',
        clientVersion: '7.8.0',
      });
      prisma.attendance.create.mockRejectedValue(unrelated);

      await expect(
        service.record(ORG_ID, EVENT_ID, 'user-1', { personId: PERSON_ID } as never),
      ).rejects.toBe(unrelated);
      expect(prisma.attendance.findUnique).not.toHaveBeenCalled();
    });

    it('re-throws a non-Prisma error unchanged', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      const genericError = new Error('boom');
      prisma.attendance.create.mockRejectedValue(genericError);

      await expect(
        service.record(ORG_ID, EVENT_ID, 'user-1', { personId: PERSON_ID } as never),
      ).rejects.toBe(genericError);
      expect(prisma.attendance.findUnique).not.toHaveBeenCalled();
    });

    it('produces no Journey/Person/Event/FollowUp/Note/Notification/AuditLog side effects', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.create.mockResolvedValue(buildAttendanceRow());

      await service.record(ORG_ID, EVENT_ID, 'user-1', { personId: PERSON_ID } as never);

      // The mock Prisma object exposes only `attendance` and `person`
      // models; if the service touched any other model, accessing it would
      // throw (undefined has no such method) rather than silently succeed.
      expect(Object.keys(prisma)).toEqual(['attendance', 'person']);
    });
  });

  describe('listForPerson', () => {
    it('validates the Person tenant ownership before reading Attendance', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      await expect(service.listForPerson(ORG_ID, PERSON_ID, {})).rejects.toThrow();
      expect(prisma.attendance.findMany).not.toHaveBeenCalled();
    });

    it('scopes the query by organizationId and personId', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.findMany.mockResolvedValue([]);

      await service.listForPerson(ORG_ID, PERSON_ID, {});

      const args = prisma.attendance.findMany.mock.calls[0][0];
      expect(args.where).toEqual({ organizationId: ORG_ID, personId: PERSON_ID });
    });

    it('never filters by Event.deletedAt (historical visibility after Event soft-deletion)', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.findMany.mockResolvedValue([]);

      await service.listForPerson(ORG_ID, PERSON_ID, {});

      const args = prisma.attendance.findMany.mock.calls[0][0];
      expect(JSON.stringify(args.where)).not.toContain('deletedAt');
    });

    it.each([
      ['checkedInAt_desc', [{ checkedInAt: 'desc' }, { id: 'asc' }]],
      ['checkedInAt_asc', [{ checkedInAt: 'asc' }, { id: 'asc' }]],
      ['eventStartDate_desc', [{ event: { startDate: 'desc' } }, { id: 'asc' }]],
    ])('implements %s ordering exactly', async (sort, expectedOrderBy) => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.findMany.mockResolvedValue([]);

      await service.listForPerson(ORG_ID, PERSON_ID, { sort } as never);

      const args = prisma.attendance.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual(expectedOrderBy);
    });

    it('defaults to checkedInAt_desc and limit 50', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.findMany.mockResolvedValue([]);

      await service.listForPerson(ORG_ID, PERSON_ID, {});

      const args = prisma.attendance.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual([{ checkedInAt: 'desc' }, { id: 'asc' }]);
      expect(args.take).toBe(51);
    });

    const CURSOR_ID_1 = '66666666-6666-6666-6666-666666666666';
    const CURSOR_ID_2 = '77777777-7777-7777-7777-777777777777';

    it('paginates with an opaque sort-bound cursor', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.findMany.mockResolvedValue([
        buildAttendanceRow({ id: CURSOR_ID_1, event: { id: 'event-1', title: 'A', startDate: new Date() } }),
        buildAttendanceRow({ id: CURSOR_ID_2, event: { id: 'event-1', title: 'A', startDate: new Date() } }),
      ]);

      const result = await service.listForPerson(ORG_ID, PERSON_ID, {
        limit: 1,
        sort: 'eventStartDate_desc',
      } as never);

      expect(result.attendance).toHaveLength(1);
      expect(decodeCursor(result.nextCursor as string, 'eventStartDate_desc')).toBe(CURSOR_ID_1);
    });

    it('rejects a malformed cursor', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });

      await expect(service.listForPerson(ORG_ID, PERSON_ID, { cursor: 'garbage' } as never)).rejects.toThrow();
    });

    it('rejects cross-sort cursor reuse', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      const cursor = encodeCursor({ id: CURSOR_ID_1, sort: 'checkedInAt_asc' });

      await expect(
        service.listForPerson(ORG_ID, PERSON_ID, { cursor, sort: 'checkedInAt_desc' } as never),
      ).rejects.toThrow();
      expect(prisma.attendance.findMany).not.toHaveBeenCalled();
    });

    it('returns the exact approved response shape', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.findMany.mockResolvedValue([
        {
          id: 'attendance-1',
          status: AttendanceStatus.Late,
          checkedInAt: new Date('2026-08-02T09:05:00.000Z'),
          event: { id: EVENT_ID, title: 'Sunday Service', startDate: new Date('2026-08-02T09:00:00.000Z') },
        },
      ]);

      const result = await service.listForPerson(ORG_ID, PERSON_ID, {});

      expect(result).toEqual({
        attendance: [
          {
            id: 'attendance-1',
            event: { id: EVENT_ID, title: 'Sunday Service', startDate: '2026-08-02T09:00:00.000Z' },
            status: 'LATE',
            checkedInAt: '2026-08-02T09:05:00.000Z',
          },
        ],
        nextCursor: null,
      });
    });
  });

  it('has no production code path that updates, deletes, or reverses Attendance', () => {
    const source = AttendanceService.toString();
    expect(source).not.toMatch(/attendance\.update\(/);
    expect(source).not.toMatch(/attendance\.delete\(/);
    expect(source).not.toMatch(/attendance\.upsert\(/);
  });

  describe('summaryForPerson', () => {
    beforeEach(() => {
      // Deterministic clock: 2026-07-12T15:30:00.000Z (mid-month, mid-day UTC).
      jest.useFakeTimers().setSystemTime(new Date('2026-07-12T15:30:00.000Z'));
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('validates the Person tenant ownership before counting Attendance', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      await expect(service.summaryForPerson(ORG_ID, PERSON_ID)).rejects.toThrow();
      expect(prisma.attendance.count).not.toHaveBeenCalled();
    });

    it('preserves PERSON_NOT_FOUND for an absent/cross-tenant/soft-deleted Person', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.summaryForPerson(ORG_ID, PERSON_ID);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error).toBeInstanceOf(ApiException);
      expect(error?.code).toBe('PERSON_NOT_FOUND');
    });

    it('totalCount is scoped by organizationId and personId only, with no date bound', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.count.mockResolvedValue(0);

      await service.summaryForPerson(ORG_ID, PERSON_ID);

      const totalArgs = prisma.attendance.count.mock.calls[0][0];
      expect(totalArgs.where).toEqual({ organizationId: ORG_ID, personId: PERSON_ID });
    });

    it('currentMonthCount is scoped by organizationId, personId, and the current UTC calendar-month window on checkedInAt', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.count.mockResolvedValue(0);

      await service.summaryForPerson(ORG_ID, PERSON_ID);

      const monthArgs = prisma.attendance.count.mock.calls[1][0];
      expect(monthArgs.where).toEqual({
        organizationId: ORG_ID,
        personId: PERSON_ID,
        checkedInAt: { gte: new Date('2026-07-01T00:00:00.000Z'), lt: new Date('2026-08-01T00:00:00.000Z') },
      });
    });

    it('behaviorally excludes previous-month, next-month-boundary, another Person, and another Organization Attendance from currentMonthCount', async () => {
      jest.setSystemTime(new Date('2026-07-15T12:00:00.000Z'));
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });

      const OTHER_PERSON_ID = '99999999-9999-9999-9999-999999999999';
      const OTHER_ORG_ID = '88888888-8888-8888-8888-888888888888';

      // A fixture-backed count simulation (not the real Postgres query
      // planner) that filters exactly the fields the service's `where`
      // clause supplies, so the test proves actual inclusion/exclusion
      // behavior rather than only the shape of the constructed filter.
      const rows = [
        { organizationId: ORG_ID, personId: PERSON_ID, checkedInAt: new Date('2026-06-30T23:59:59.999Z') },
        { organizationId: ORG_ID, personId: PERSON_ID, checkedInAt: new Date('2026-08-01T00:00:00.000Z') },
        { organizationId: ORG_ID, personId: OTHER_PERSON_ID, checkedInAt: new Date('2026-07-10T00:00:00.000Z') },
        { organizationId: OTHER_ORG_ID, personId: PERSON_ID, checkedInAt: new Date('2026-07-10T00:00:00.000Z') },
        { organizationId: ORG_ID, personId: PERSON_ID, checkedInAt: new Date('2026-07-01T00:00:00.000Z') },
        { organizationId: ORG_ID, personId: PERSON_ID, checkedInAt: new Date('2026-07-31T23:59:59.999Z') },
      ];

      prisma.attendance.count.mockImplementation(async (args: Record<string, unknown>) => {
        const where = args.where as {
          organizationId: string;
          personId: string;
          checkedInAt?: { gte: Date; lt: Date };
        };
        return rows.filter((row) => {
          if (row.organizationId !== where.organizationId) return false;
          if (row.personId !== where.personId) return false;
          if (where.checkedInAt) {
            if (row.checkedInAt < where.checkedInAt.gte) return false;
            if (row.checkedInAt >= where.checkedInAt.lt) return false;
          }
          return true;
        }).length;
      });

      const result = await service.summaryForPerson(ORG_ID, PERSON_ID);

      // totalCount: all 4 rows scoped to ORG_ID + PERSON_ID (June 30, Aug 1,
      // July 1, July 31), regardless of date; the other-Person/other-Org
      // rows are excluded by scope alone.
      expect(result.attendanceSummary.totalCount).toBe(4);
      // currentMonthCount: only the 2 July rows for ORG_ID + PERSON_ID;
      // previous-month, next-month-boundary, another Person, and another
      // Organization are each excluded.
      expect(result.attendanceSummary.currentMonthCount).toBe(2);
    });

    it('derives the same month window regardless of time-of-day or day-of-month', async () => {
      jest.setSystemTime(new Date('2026-07-31T23:59:59.999Z'));
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.count.mockResolvedValue(0);

      await service.summaryForPerson(ORG_ID, PERSON_ID);

      const monthArgs = prisma.attendance.count.mock.calls[1][0];
      expect(monthArgs.where.checkedInAt).toEqual({
        gte: new Date('2026-07-01T00:00:00.000Z'),
        lt: new Date('2026-08-01T00:00:00.000Z'),
      });
    });

    it('rolls the next-month boundary into the following calendar year across a December window', async () => {
      jest.setSystemTime(new Date('2026-12-15T12:00:00.000Z'));
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.count.mockResolvedValue(0);

      await service.summaryForPerson(ORG_ID, PERSON_ID);

      const monthArgs = prisma.attendance.count.mock.calls[1][0];
      expect(monthArgs.where.checkedInAt).toEqual({
        gte: new Date('2026-12-01T00:00:00.000Z'),
        lt: new Date('2027-01-01T00:00:00.000Z'),
      });
    });

    it('returns the exact approved response shape with the resolved counts', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.count.mockResolvedValueOnce(24).mockResolvedValueOnce(6);

      const result = await service.summaryForPerson(ORG_ID, PERSON_ID);

      expect(result).toEqual({ attendanceSummary: { totalCount: 24, currentMonthCount: 6 } });
    });

    it('never calls attendance.findMany (bounded COUNT only, never a per-record loop)', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.attendance.count.mockResolvedValue(0);

      await service.summaryForPerson(ORG_ID, PERSON_ID);

      expect(prisma.attendance.findMany).not.toHaveBeenCalled();
    });
  });
});
