import { HttpStatus, Injectable } from '@nestjs/common';
import { ApiException } from '../common/http/api-exception';
import { PrismaService } from '../database/prisma.service';
import { decodeCursor, encodeCursor } from './cursor.util';
import { ListNotificationsQueryDto } from './dto/list-notifications-query.dto';
import { DEFAULT_NOTIFICATION_LIMIT, NOTIFICATION_ERROR_CODES, NOTIFICATION_SORT } from './notifications.constants';

export interface NotificationSummary {
  id: string;
  title: string;
  message: string;
  isRead: boolean;
  createdAt: string;
}

export interface NotificationListResult {
  notifications: NotificationSummary[];
  nextCursor: string | null;
}

interface NotificationRow {
  id: string;
  title: string;
  message: string;
  isRead: boolean;
  createdAt: Date;
}

const NOTIFICATION_SELECT = {
  id: true,
  title: true,
  message: true,
  isRead: true,
  createdAt: true,
} as const;

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Personal, per-user notifications within one organization: scoped by
   * organizationId (guard-derived) AND userId (the authenticated caller) —
   * a Notification belongs to exactly one user, never a shared org-wide
   * feed. Deterministic newest-first (createdAt desc, id asc tie-break);
   * no client-selectable sort exists. Only real Notification.isRead backs
   * the optional read/unread filter — there is no category column.
   */
  async list(
    organizationId: string,
    userId: string,
    query: ListNotificationsQueryDto,
  ): Promise<NotificationListResult> {
    const limit = query.limit ?? DEFAULT_NOTIFICATION_LIMIT;

    const where: Record<string, unknown> = { organizationId, userId };
    if (query.read !== undefined) {
      where.isRead = query.read === 'true';
    }

    const cursorId = query.cursor ? decodeCursor(query.cursor, NOTIFICATION_SORT) : undefined;

    const rows = (await this.prisma.notification.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
      take: limit + 1,
      select: NOTIFICATION_SELECT,
      ...(cursorId ? { cursor: { id: cursorId }, skip: 1 } : {}),
    })) as NotificationRow[];

    const hasMore = rows.length > limit;
    const pageRows = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor = hasMore
      ? encodeCursor({ id: pageRows[pageRows.length - 1].id, sort: NOTIFICATION_SORT })
      : null;

    return { notifications: pageRows.map((row) => this.toSummary(row)), nextCursor };
  }

  /**
   * Idempotent: setting isRead to true is applied unconditionally once
   * tenant/ownership is verified, so a repeat call on an already-read
   * notification is a harmless no-op re-write, never an error.
   */
  async markRead(organizationId: string, userId: string, notificationId: string): Promise<{ notification: NotificationSummary }> {
    const existing = await this.prisma.notification.findFirst({
      where: { id: notificationId, organizationId, userId },
      select: { id: true },
    });

    if (!existing) {
      throw this.notFoundError();
    }

    const updated = (await this.prisma.notification.update({
      where: { id: notificationId },
      data: { isRead: true },
      select: NOTIFICATION_SELECT,
    })) as NotificationRow;

    return { notification: this.toSummary(updated) };
  }

  /**
   * Single bounded UPDATE over every unread notification for this
   * (organizationId, userId) — never a per-record loop. Returns the real
   * affected-row count from Prisma's updateMany, never a fabricated value.
   */
  async markAllRead(organizationId: string, userId: string): Promise<{ markedCount: number }> {
    const result = await this.prisma.notification.updateMany({
      where: { organizationId, userId, isRead: false },
      data: { isRead: true },
    });

    return { markedCount: result.count };
  }

  /**
   * Notification has no soft-delete column (no deletedAt), so "Clear Read"
   * is a real, permanent hard delete of every isRead:true row for this
   * (organizationId, userId) — a single bounded DELETE, never a per-record
   * loop. isRead:false is never included in the where clause's match, so
   * unread notifications can never be cleared by this action.
   */
  async clearRead(organizationId: string, userId: string): Promise<{ clearedCount: number }> {
    const result = await this.prisma.notification.deleteMany({
      where: { organizationId, userId, isRead: true },
    });

    return { clearedCount: result.count };
  }

  private toSummary(row: NotificationRow): NotificationSummary {
    return {
      id: row.id,
      title: row.title,
      message: row.message,
      isRead: row.isRead,
      createdAt: row.createdAt.toISOString(),
    };
  }

  private notFoundError(): ApiException {
    return new ApiException(
      HttpStatus.NOT_FOUND,
      NOTIFICATION_ERROR_CODES.NOTIFICATION_NOT_FOUND,
      'Notification not found.',
    );
  }
}
