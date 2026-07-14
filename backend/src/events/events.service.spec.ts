import { ApiException } from '../common/http/api-exception';
import { decodeCursor, encodeCursor } from './cursor.util';
import { EventsService } from './events.service';

const ORG_ID = '11111111-1111-1111-1111-111111111111';

function buildEventRow(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'event-1',
    title: 'Sunday Service',
    description: null,
    category: null,
    venue: null,
    startDate: new Date('2026-08-02T09:00:00.000Z'),
    endDate: null,
    cancelledAt: null,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    createdByUser: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace' },
    ...overrides,
  };
}

function createMockPrisma() {
  return {
    event: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
  };
}

describe('EventsService', () => {
  let prisma: ReturnType<typeof createMockPrisma>;
  let service: EventsService;

  beforeEach(() => {
    prisma = createMockPrisma();
    service = new EventsService(prisma as never);
  });

  describe('list', () => {
    it('scopes by organizationId and requires deletedAt null, with no date-range param', async () => {
      prisma.event.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, {});

      const args = prisma.event.findMany.mock.calls[0][0];
      expect(args.where.organizationId).toBe(ORG_ID);
      expect(args.where.deletedAt).toBeNull();
      expect(args.where.startDate).toBeUndefined();
    });

    it('ORs search across title/description/venue case-insensitively', async () => {
      prisma.event.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { search: 'sunday' } as never);

      const args = prisma.event.findMany.mock.calls[0][0];
      expect(args.where.OR).toEqual([
        { title: { contains: 'sunday', mode: 'insensitive' } },
        { description: { contains: 'sunday', mode: 'insensitive' } },
        { venue: { contains: 'sunday', mode: 'insensitive' } },
      ]);
    });

    it('treats an empty trimmed search as absent', async () => {
      prisma.event.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { search: '   ' } as never);

      const args = prisma.event.findMany.mock.calls[0][0];
      expect(args.where.OR).toBeUndefined();
    });

    it('applies a case-insensitive exact-match category filter', async () => {
      prisma.event.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { category: 'Conference' } as never);

      const args = prisma.event.findMany.mock.calls[0][0];
      expect(args.where.category).toEqual({ equals: 'Conference', mode: 'insensitive' });
    });

    it.each([
      ['startDate_desc', [{ startDate: 'desc' }, { id: 'asc' }]],
      ['startDate_asc', [{ startDate: 'asc' }, { id: 'asc' }]],
      ['createdAt_desc', [{ createdAt: 'desc' }, { id: 'asc' }]],
      ['title_asc', [{ title: 'asc' }, { id: 'asc' }]],
    ])('implements %s ordering exactly', async (sort, expectedOrderBy) => {
      prisma.event.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, { sort } as never);

      const args = prisma.event.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual(expectedOrderBy);
    });

    it('defaults to startDate_desc when no sort is supplied', async () => {
      prisma.event.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, {});

      const args = prisma.event.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual([{ startDate: 'desc' }, { id: 'asc' }]);
    });

    it('defaults limit to 20 and requests limit+1 rows', async () => {
      prisma.event.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, {});

      const args = prisma.event.findMany.mock.calls[0][0];
      expect(args.take).toBe(21);
    });

    it('returns nextCursor null when there is no extra row', async () => {
      prisma.event.findMany.mockResolvedValue([buildEventRow()]);

      const result = await service.list(ORG_ID, { limit: 1 } as never);

      expect(result.nextCursor).toBeNull();
      expect(result.events).toHaveLength(1);
    });

    const CURSOR_ID_1 = '66666666-6666-6666-6666-666666666666';
    const CURSOR_ID_2 = '77777777-7777-7777-7777-777777777777';

    it('returns a usable opaque nextCursor when an extra row exists, trimming to the requested limit', async () => {
      prisma.event.findMany.mockResolvedValue([
        buildEventRow({ id: CURSOR_ID_1 }),
        buildEventRow({ id: CURSOR_ID_2 }),
      ]);

      const result = await service.list(ORG_ID, { limit: 1, sort: 'title_asc' } as never);

      expect(result.events).toHaveLength(1);
      expect(decodeCursor(result.nextCursor as string, 'title_asc')).toBe(CURSOR_ID_1);
    });

    it('passes a decoded cursor id to Prisma native cursor+skip', async () => {
      prisma.event.findMany.mockResolvedValue([]);
      const cursor = encodeCursor({ id: CURSOR_ID_1, sort: 'title_asc' });

      await service.list(ORG_ID, { cursor, sort: 'title_asc' } as never);

      const args = prisma.event.findMany.mock.calls[0][0];
      expect(args.cursor).toEqual({ id: CURSOR_ID_1 });
      expect(args.skip).toBe(1);
    });

    it('rejects a cursor generated for a different sort (cross-sort reuse)', async () => {
      const cursor = encodeCursor({ id: CURSOR_ID_1, sort: 'createdAt_desc' });

      await expect(service.list(ORG_ID, { cursor, sort: 'title_asc' } as never)).rejects.toThrow();
      expect(prisma.event.findMany).not.toHaveBeenCalled();
    });

    it('rejects a malformed cursor', async () => {
      await expect(service.list(ORG_ID, { cursor: 'garbage' } as never)).rejects.toThrow();
    });

    it('returns the exact approved empty list shape', async () => {
      prisma.event.findMany.mockResolvedValue([]);

      const result = await service.list(ORG_ID, {});

      expect(result).toEqual({ events: [], nextCursor: null });
    });

    it('a cancelled (but not soft-deleted) Event remains readable in the list, with cancelledAt exposed', async () => {
      prisma.event.findMany.mockResolvedValue([
        buildEventRow({ cancelledAt: new Date('2026-07-14T10:00:00.000Z') }),
      ]);

      const result = await service.list(ORG_ID, {});

      const args = prisma.event.findMany.mock.calls[0][0];
      expect(args.where.deletedAt).toBeNull();
      expect(args.where.cancelledAt).toBeUndefined();
      expect(result.events[0].cancelledAt).toBe('2026-07-14T10:00:00.000Z');
    });

    it('maps the exact approved list shape without organizationId/createdBy/deletedAt', async () => {
      prisma.event.findMany.mockResolvedValue([buildEventRow()]);

      const result = await service.list(ORG_ID, { limit: 5 } as never);

      expect(result.events[0]).toEqual({
        id: 'event-1',
        title: 'Sunday Service',
        description: null,
        category: null,
        venue: null,
        startDate: '2026-08-02T09:00:00.000Z',
        endDate: null,
        cancelledAt: null,
        createdAt: '2026-01-01T00:00:00.000Z',
      });
      expect(result.events[0]).not.toHaveProperty('organizationId');
      expect(result.events[0]).not.toHaveProperty('createdBy');
      expect(result.events[0]).not.toHaveProperty('deletedAt');
    });
  });

  describe('detail', () => {
    it('scopes by id + organizationId + deletedAt null', async () => {
      prisma.event.findFirst.mockResolvedValue(null);

      await expect(service.detail(ORG_ID, 'event-1')).rejects.toThrow();

      const args = prisma.event.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'event-1', organizationId: ORG_ID, deletedAt: null });
    });

    it('throws EVENT_NOT_FOUND for a cross-tenant, absent, or soft-deleted Event', async () => {
      prisma.event.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.detail(ORG_ID, 'event-1');
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('EVENT_NOT_FOUND');
    });

    it('a cancelled (but not soft-deleted) Event remains readable via detail, with cancelledAt exposed', async () => {
      prisma.event.findFirst.mockResolvedValue(buildEventRow({ cancelledAt: new Date('2026-07-14T10:00:00.000Z') }));

      const result = await service.detail(ORG_ID, 'event-1');

      const args = prisma.event.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'event-1', organizationId: ORG_ID, deletedAt: null });
      expect(result.event.cancelledAt).toBe('2026-07-14T10:00:00.000Z');
    });

    it('maps the exact approved detail shape including createdBy', async () => {
      prisma.event.findFirst.mockResolvedValue(buildEventRow());

      const result = await service.detail(ORG_ID, 'event-1');

      expect(result).toEqual({
        event: {
          id: 'event-1',
          title: 'Sunday Service',
          description: null,
          category: null,
          venue: null,
          startDate: '2026-08-02T09:00:00.000Z',
          endDate: null,
          cancelledAt: null,
          createdAt: '2026-01-01T00:00:00.000Z',
          createdBy: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace' },
        },
      });
    });
  });

  describe('create', () => {
    it('derives organizationId and createdBy on the server', async () => {
      prisma.event.create.mockResolvedValue(buildEventRow());

      await service.create(
        ORG_ID,
        'user-1',
        { title: 'Sunday Service', startDate: '2026-08-02T09:00:00Z' } as never,
      );

      const args = prisma.event.create.mock.calls[0][0];
      expect(args.data.organizationId).toBe(ORG_ID);
      expect(args.data.createdBy).toBe('user-1');
    });

    it('normalizes optional nullable fields to null when absent', async () => {
      prisma.event.create.mockResolvedValue(buildEventRow());

      await service.create(
        ORG_ID,
        'user-1',
        { title: 'Sunday Service', startDate: '2026-08-02T09:00:00Z' } as never,
      );

      const args = prisma.event.create.mock.calls[0][0];
      expect(args.data.description).toBeNull();
      expect(args.data.category).toBeNull();
      expect(args.data.venue).toBeNull();
      expect(args.data.endDate).toBeNull();
    });

    it('rejects endDate earlier than startDate with INVALID_EVENT_DATE_RANGE', async () => {
      let error: ApiException | undefined;
      try {
        await service.create(
          ORG_ID,
          'user-1',
          {
            title: 'Sunday Service',
            startDate: '2026-08-02T09:00:00Z',
            endDate: '2026-08-01T09:00:00Z',
          } as never,
        );
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('INVALID_EVENT_DATE_RANGE');
      expect(prisma.event.create).not.toHaveBeenCalled();
    });

    it('accepts endDate equal to startDate', async () => {
      prisma.event.create.mockResolvedValue(buildEventRow());

      await expect(
        service.create(
          ORG_ID,
          'user-1',
          {
            title: 'Sunday Service',
            startDate: '2026-08-02T09:00:00Z',
            endDate: '2026-08-02T09:00:00Z',
          } as never,
        ),
      ).resolves.toBeDefined();
    });

    it('creates no Attendance or other side-effect record (only event.create is called)', async () => {
      prisma.event.create.mockResolvedValue(buildEventRow());

      await service.create(
        ORG_ID,
        'user-1',
        { title: 'Sunday Service', startDate: '2026-08-02T09:00:00Z' } as never,
      );

      expect(Object.keys(prisma)).toEqual(['event']);
    });

    it('returns HTTP-201-appropriate exact approved response shape', async () => {
      prisma.event.create.mockResolvedValue(buildEventRow());

      const result = await service.create(
        ORG_ID,
        'user-1',
        { title: 'Sunday Service', startDate: '2026-08-02T09:00:00Z' } as never,
      );

      expect(result).toEqual({
        event: {
          id: 'event-1',
          title: 'Sunday Service',
          description: null,
          category: null,
          venue: null,
          startDate: '2026-08-02T09:00:00.000Z',
          endDate: null,
          cancelledAt: null,
          createdAt: '2026-01-01T00:00:00.000Z',
          createdBy: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace' },
        },
      });
    });
  });

  describe('update', () => {
    it('rejects an update with no fields supplied', async () => {
      await expect(service.update(ORG_ID, 'event-1', {} as never)).rejects.toThrow(
        'At least one field must be supplied.',
      );
      expect(prisma.event.findFirst).not.toHaveBeenCalled();
    });

    it('scopes the update target by id + organizationId + deletedAt null', async () => {
      prisma.event.findFirst.mockResolvedValue(null);

      await expect(service.update(ORG_ID, 'event-1', { title: 'New' } as never)).rejects.toThrow();

      const args = prisma.event.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'event-1', organizationId: ORG_ID, deletedAt: null });
    });

    it('throws EVENT_NOT_FOUND for a cross-tenant/deleted target', async () => {
      prisma.event.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.update(ORG_ID, 'event-1', { title: 'New' } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('EVENT_NOT_FOUND');
    });

    it('only writes fields explicitly present in the dto', async () => {
      prisma.event.findFirst.mockResolvedValue({
        id: 'event-1',
        startDate: new Date('2026-08-02T09:00:00.000Z'),
        endDate: null,
      });
      prisma.event.update.mockResolvedValue(buildEventRow());

      await service.update(ORG_ID, 'event-1', { title: 'Updated' } as never);

      const args = prisma.event.update.mock.calls[0][0];
      expect(args.data).toEqual({ title: 'Updated' });
    });

    it('null-clears description/category/venue/endDate when explicitly supplied', async () => {
      prisma.event.findFirst.mockResolvedValue({
        id: 'event-1',
        startDate: new Date('2026-08-02T09:00:00.000Z'),
        endDate: new Date('2026-08-03T09:00:00.000Z'),
      });
      prisma.event.update.mockResolvedValue(buildEventRow());

      await service.update(ORG_ID, 'event-1', {
        description: null,
        category: null,
        venue: null,
        endDate: null,
      } as never);

      const args = prisma.event.update.mock.calls[0][0];
      expect(args.data).toEqual({ description: null, category: null, venue: null, endDate: null });
    });

    it('validates the final combined (post-merge) date state, not just the raw payload', async () => {
      // Existing endDate is one day after the existing startDate. Supplying
      // only a new, later startDate must be validated against the EXISTING
      // stored endDate, not silently accepted.
      prisma.event.findFirst.mockResolvedValue({
        id: 'event-1',
        startDate: new Date('2026-08-02T09:00:00.000Z'),
        endDate: new Date('2026-08-03T09:00:00.000Z'),
      });

      let error: ApiException | undefined;
      try {
        await service.update(ORG_ID, 'event-1', { startDate: '2026-08-04T09:00:00Z' } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('INVALID_EVENT_DATE_RANGE');
      expect(prisma.event.update).not.toHaveBeenCalled();
    });

    it('validates final combined state when only endDate is supplied against the existing startDate', async () => {
      prisma.event.findFirst.mockResolvedValue({
        id: 'event-1',
        startDate: new Date('2026-08-02T09:00:00.000Z'),
        endDate: null,
      });

      let error: ApiException | undefined;
      try {
        await service.update(ORG_ID, 'event-1', { endDate: '2026-08-01T09:00:00Z' } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('INVALID_EVENT_DATE_RANGE');
    });

    it('does not mutate immutable fields (id/organizationId/createdBy/createdAt/updatedAt/deletedAt)', async () => {
      prisma.event.findFirst.mockResolvedValue({
        id: 'event-1',
        startDate: new Date('2026-08-02T09:00:00.000Z'),
        endDate: null,
      });
      prisma.event.update.mockResolvedValue(buildEventRow());

      await service.update(ORG_ID, 'event-1', { title: 'Updated' } as never);

      const args = prisma.event.update.mock.calls[0][0];
      expect(args.data).not.toHaveProperty('organizationId');
      expect(args.data).not.toHaveProperty('createdBy');
      expect(args.data).not.toHaveProperty('createdAt');
      expect(args.data).not.toHaveProperty('deletedAt');
      expect(args.data).not.toHaveProperty('cancelledAt');
    });

    it('returns the exact approved Event response shape', async () => {
      prisma.event.findFirst.mockResolvedValue({
        id: 'event-1',
        startDate: new Date('2026-08-02T09:00:00.000Z'),
        endDate: null,
      });
      prisma.event.update.mockResolvedValue(buildEventRow({ title: 'Updated' }));

      const result = await service.update(ORG_ID, 'event-1', { title: 'Updated' } as never);

      expect(result.event.title).toBe('Updated');
      expect(result.event).toHaveProperty('createdBy');
    });
  });

  describe('remove', () => {
    it('scopes the visible target by id + organizationId + deletedAt null', async () => {
      prisma.event.findFirst.mockResolvedValue(null);

      await expect(service.remove(ORG_ID, 'event-1')).rejects.toThrow();

      const args = prisma.event.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'event-1', organizationId: ORG_ID, deletedAt: null });
    });

    it('throws EVENT_NOT_FOUND when absent, cross-tenant, or already deleted', async () => {
      prisma.event.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.remove(ORG_ID, 'event-1');
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('EVENT_NOT_FOUND');
    });

    it('soft-deletes by setting deletedAt, never hard-deleting', async () => {
      prisma.event.findFirst.mockResolvedValue({ id: 'event-1' });
      prisma.event.update.mockResolvedValue({});

      await service.remove(ORG_ID, 'event-1');

      const args = prisma.event.update.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'event-1' });
      expect(args.data.deletedAt).toBeInstanceOf(Date);
    });

    it('returns exactly {success: true}', async () => {
      prisma.event.findFirst.mockResolvedValue({ id: 'event-1' });
      prisma.event.update.mockResolvedValue({});

      const result = await service.remove(ORG_ID, 'event-1');

      expect(result).toEqual({ success: true });
    });
  });

  describe('cancel', () => {
    it('scopes the target by id + organizationId + deletedAt null', async () => {
      prisma.event.findFirst.mockResolvedValue(null);

      await expect(service.cancel(ORG_ID, 'event-1')).rejects.toThrow();

      const args = prisma.event.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'event-1', organizationId: ORG_ID, deletedAt: null });
    });

    it('throws EVENT_NOT_FOUND when absent, cross-tenant, or soft-deleted', async () => {
      prisma.event.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.cancel(ORG_ID, 'event-1');
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('EVENT_NOT_FOUND');
      expect(prisma.event.update).not.toHaveBeenCalled();
    });

    it('sets cancelledAt (never deletedAt) on first cancel', async () => {
      prisma.event.findFirst.mockResolvedValue(buildEventRow({ cancelledAt: null }));
      prisma.event.update.mockResolvedValue(buildEventRow({ cancelledAt: new Date('2026-07-14T10:00:00.000Z') }));

      const result = await service.cancel(ORG_ID, 'event-1');

      const args = prisma.event.update.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'event-1' });
      expect(args.data).toEqual({ cancelledAt: expect.any(Date) });
      expect(result.event.cancelledAt).toBe('2026-07-14T10:00:00.000Z');
    });

    it('is idempotent: a repeat cancel performs no write and returns the original cancelledAt unchanged', async () => {
      const alreadyCancelledAt = new Date('2026-07-10T08:00:00.000Z');
      prisma.event.findFirst.mockResolvedValue(buildEventRow({ cancelledAt: alreadyCancelledAt }));

      const result = await service.cancel(ORG_ID, 'event-1');

      expect(prisma.event.update).not.toHaveBeenCalled();
      expect(result.event.cancelledAt).toBe('2026-07-10T08:00:00.000Z');
    });

    it('returns the exact approved Event response shape including cancelledAt', async () => {
      prisma.event.findFirst.mockResolvedValue(buildEventRow({ cancelledAt: null }));
      prisma.event.update.mockResolvedValue(buildEventRow({ cancelledAt: new Date('2026-07-14T10:00:00.000Z') }));

      const result = await service.cancel(ORG_ID, 'event-1');

      expect(result).toEqual({
        event: {
          id: 'event-1',
          title: 'Sunday Service',
          description: null,
          category: null,
          venue: null,
          startDate: '2026-08-02T09:00:00.000Z',
          endDate: null,
          cancelledAt: '2026-07-14T10:00:00.000Z',
          createdAt: '2026-01-01T00:00:00.000Z',
          createdBy: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace' },
        },
      });
    });

    it('creates no Attendance or other side-effect record (only event.findFirst/event.update are touched)', async () => {
      prisma.event.findFirst.mockResolvedValue(buildEventRow({ cancelledAt: null }));
      prisma.event.update.mockResolvedValue(buildEventRow({ cancelledAt: new Date() }));

      await service.cancel(ORG_ID, 'event-1');

      expect(Object.keys(prisma)).toEqual(['event']);
    });
  });

  describe('assertActiveEvent', () => {
    it('resolves silently when the Event is active and tenant-owned', async () => {
      prisma.event.findFirst.mockResolvedValue({ id: 'event-1' });

      await expect(service.assertActiveEvent(ORG_ID, 'event-1')).resolves.toBeUndefined();
    });

    it('throws EVENT_NOT_FOUND for an absent, cross-tenant, or soft-deleted Event', async () => {
      prisma.event.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.assertActiveEvent(ORG_ID, 'event-1');
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('EVENT_NOT_FOUND');
    });
  });
});
