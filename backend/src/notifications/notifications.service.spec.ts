import { ApiException } from '../common/http/api-exception';
import { decodeCursor, encodeCursor } from './cursor.util';
import { NotificationsService } from './notifications.service';

const ORG_ID = '11111111-1111-1111-1111-111111111111';
const USER_ID = '22222222-2222-2222-2222-222222222222';

function buildNotificationRow(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'notif-1',
    title: 'New follow-up assigned',
    message: 'You have a new follow-up due soon.',
    isRead: false,
    createdAt: new Date('2026-07-14T09:00:00.000Z'),
    ...overrides,
  };
}

function createMockPrisma() {
  return {
    notification: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      deleteMany: jest.fn(),
    },
  };
}

describe('NotificationsService', () => {
  let prisma: ReturnType<typeof createMockPrisma>;
  let service: NotificationsService;

  beforeEach(() => {
    prisma = createMockPrisma();
    service = new NotificationsService(prisma as never);
  });

  describe('list', () => {
    it('scopes by organizationId and userId (the authenticated caller only)', async () => {
      prisma.notification.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, USER_ID, {});

      const args = prisma.notification.findMany.mock.calls[0][0];
      expect(args.where).toEqual({ organizationId: ORG_ID, userId: USER_ID });
    });

    it('orders createdAt descending with id ascending as the deterministic tie-break', async () => {
      prisma.notification.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, USER_ID, {});

      const args = prisma.notification.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual([{ createdAt: 'desc' }, { id: 'asc' }]);
    });

    it('defaults limit to 20 and requests limit+1 rows', async () => {
      prisma.notification.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, USER_ID, {});

      const args = prisma.notification.findMany.mock.calls[0][0];
      expect(args.take).toBe(21);
    });

    it('applies the read/unread filter only when explicitly supplied', async () => {
      prisma.notification.findMany.mockResolvedValue([]);

      await service.list(ORG_ID, USER_ID, { read: 'true' } as never);
      expect(prisma.notification.findMany.mock.calls[0][0].where.isRead).toBe(true);

      await service.list(ORG_ID, USER_ID, { read: 'false' } as never);
      expect(prisma.notification.findMany.mock.calls[1][0].where.isRead).toBe(false);

      await service.list(ORG_ID, USER_ID, {});
      expect(prisma.notification.findMany.mock.calls[2][0].where).not.toHaveProperty('isRead');
    });

    it('returns the exact approved empty list shape', async () => {
      prisma.notification.findMany.mockResolvedValue([]);

      const result = await service.list(ORG_ID, USER_ID, {});

      expect(result).toEqual({ notifications: [], nextCursor: null });
    });

    it('maps the exact approved fields: id, title, message, isRead, createdAt', async () => {
      prisma.notification.findMany.mockResolvedValue([buildNotificationRow()]);

      const result = await service.list(ORG_ID, USER_ID, { limit: 5 } as never);

      expect(result.notifications[0]).toEqual({
        id: 'notif-1',
        title: 'New follow-up assigned',
        message: 'You have a new follow-up due soon.',
        isRead: false,
        createdAt: '2026-07-14T09:00:00.000Z',
      });
      expect(result.notifications[0]).not.toHaveProperty('organizationId');
      expect(result.notifications[0]).not.toHaveProperty('userId');
    });

    it('returns nextCursor null when there is no extra row', async () => {
      prisma.notification.findMany.mockResolvedValue([buildNotificationRow()]);

      const result = await service.list(ORG_ID, USER_ID, { limit: 1 } as never);

      expect(result.nextCursor).toBeNull();
      expect(result.notifications).toHaveLength(1);
    });

    const CURSOR_ID_1 = '66666666-6666-6666-6666-666666666666';
    const CURSOR_ID_2 = '77777777-7777-7777-7777-777777777777';

    it('returns a usable opaque nextCursor when an extra row exists, trimming to the requested limit', async () => {
      prisma.notification.findMany.mockResolvedValue([
        buildNotificationRow({ id: CURSOR_ID_1 }),
        buildNotificationRow({ id: CURSOR_ID_2 }),
      ]);

      const result = await service.list(ORG_ID, USER_ID, { limit: 1 } as never);

      expect(result.notifications).toHaveLength(1);
      expect(decodeCursor(result.nextCursor as string, 'createdAt_desc')).toBe(CURSOR_ID_1);
    });

    it('passes a decoded cursor id to Prisma native cursor+skip', async () => {
      prisma.notification.findMany.mockResolvedValue([]);
      const cursor = encodeCursor({ id: CURSOR_ID_1, sort: 'createdAt_desc' });

      await service.list(ORG_ID, USER_ID, { cursor } as never);

      const args = prisma.notification.findMany.mock.calls[0][0];
      expect(args.cursor).toEqual({ id: CURSOR_ID_1 });
      expect(args.skip).toBe(1);
    });

    it('rejects a malformed cursor', async () => {
      await expect(service.list(ORG_ID, USER_ID, { cursor: 'garbage' } as never)).rejects.toThrow();
    });
  });

  describe('markRead', () => {
    it('scopes the target by id + organizationId + userId', async () => {
      prisma.notification.findFirst.mockResolvedValue(null);

      await expect(service.markRead(ORG_ID, USER_ID, 'notif-1')).rejects.toThrow();

      const args = prisma.notification.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'notif-1', organizationId: ORG_ID, userId: USER_ID });
    });

    it('throws NOTIFICATION_NOT_FOUND for an absent, cross-tenant, or cross-user notification', async () => {
      prisma.notification.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.markRead(ORG_ID, USER_ID, 'notif-1');
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('NOTIFICATION_NOT_FOUND');
    });

    it('sets isRead to true', async () => {
      prisma.notification.findFirst.mockResolvedValue({ id: 'notif-1' });
      prisma.notification.update.mockResolvedValue(buildNotificationRow({ isRead: true }));

      const result = await service.markRead(ORG_ID, USER_ID, 'notif-1');

      const args = prisma.notification.update.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'notif-1' });
      expect(args.data).toEqual({ isRead: true });
      expect(result.notification.isRead).toBe(true);
    });

    it('is idempotent: marking an already-read notification read again succeeds unchanged', async () => {
      prisma.notification.findFirst.mockResolvedValue({ id: 'notif-1' });
      prisma.notification.update.mockResolvedValue(buildNotificationRow({ isRead: true }));

      const first = await service.markRead(ORG_ID, USER_ID, 'notif-1');
      const second = await service.markRead(ORG_ID, USER_ID, 'notif-1');

      expect(first.notification.isRead).toBe(true);
      expect(second.notification.isRead).toBe(true);
    });
  });

  describe('markAllRead', () => {
    it('issues a single bounded updateMany scoped by organizationId + userId + isRead:false', async () => {
      prisma.notification.updateMany.mockResolvedValue({ count: 3 });

      const result = await service.markAllRead(ORG_ID, USER_ID);

      expect(prisma.notification.updateMany).toHaveBeenCalledTimes(1);
      const args = prisma.notification.updateMany.mock.calls[0][0];
      expect(args.where).toEqual({ organizationId: ORG_ID, userId: USER_ID, isRead: false });
      expect(args.data).toEqual({ isRead: true });
      expect(result).toEqual({ markedCount: 3 });
    });

    it('never touches another user or organization (scoping proven via where clause)', async () => {
      prisma.notification.updateMany.mockResolvedValue({ count: 0 });

      await service.markAllRead(ORG_ID, USER_ID);

      const args = prisma.notification.updateMany.mock.calls[0][0];
      expect(args.where.organizationId).toBe(ORG_ID);
      expect(args.where.userId).toBe(USER_ID);
    });
  });

  describe('clearRead', () => {
    it('issues a single bounded deleteMany scoped by organizationId + userId + isRead:true', async () => {
      prisma.notification.deleteMany.mockResolvedValue({ count: 5 });

      const result = await service.clearRead(ORG_ID, USER_ID);

      expect(prisma.notification.deleteMany).toHaveBeenCalledTimes(1);
      const args = prisma.notification.deleteMany.mock.calls[0][0];
      expect(args.where).toEqual({ organizationId: ORG_ID, userId: USER_ID, isRead: true });
      expect(result).toEqual({ clearedCount: 5 });
    });

    it('never includes isRead:false in its where clause (unread notifications can never be cleared)', async () => {
      prisma.notification.deleteMany.mockResolvedValue({ count: 0 });

      await service.clearRead(ORG_ID, USER_ID);

      const args = prisma.notification.deleteMany.mock.calls[0][0];
      expect(args.where.isRead).toBe(true);
    });
  });
});
