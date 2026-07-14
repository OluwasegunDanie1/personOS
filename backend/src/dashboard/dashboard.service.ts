import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

export interface UpcomingEventRef {
  id: string;
  title: string;
  startDate: string;
}

/**
 * Product Task 054: joinedAt reuses the same Person.createdAt mapping
 * PersonSummary already establishes elsewhere — no new field/meaning.
 */
export interface RecentMemberRef {
  id: string;
  firstName: string;
  lastName: string;
  joinedAt: string;
}

/**
 * Product Task 054: reuses exactly the existing FollowUp fields already
 * approved for List Follow-Ups/Create Follow-Up (id, title, description,
 * dueDate) — not a new Task domain, no invented priority/category/assignee
 * field.
 */
export interface PendingTaskRef {
  id: string;
  title: string;
  description: string | null;
  dueDate: string | null;
}

export interface DashboardSummary {
  totalPeople: number;
  newPeople: number;
  pendingFollowUps: number;
  upcomingEvents: UpcomingEventRef[];
  recentMembers: RecentMemberRef[];
  pendingTasks: PendingTaskRef[];
}

interface UpcomingEventRow {
  id: string;
  title: string;
  startDate: Date;
}

interface RecentMemberRow {
  id: string;
  firstName: string;
  lastName: string;
  createdAt: Date;
}

interface PendingTaskRow {
  id: string;
  title: string;
  description: string | null;
  dueDate: Date | null;
}

const UPCOMING_EVENTS_TAKE = 5;
const RECENT_MEMBERS_TAKE = 5;
const PENDING_TASKS_TAKE = 5;

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * A single, read-only aggregate over People/FollowUp/Event, each
   * independently organizationId-scoped (the guard is never trusted as a
   * substitute for query scoping). All six operations share one captured
   * server instant so the UTC-day boundary and the upcoming-events
   * comparison stay logically consistent within a single response.
   */
  async summary(organizationId: string): Promise<DashboardSummary> {
    const now = new Date();
    const utcDayBoundary = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

    const [totalPeople, newPeople, pendingFollowUps, upcomingEventRows, recentMemberRows, pendingTaskRows] =
      await Promise.all([
        this.prisma.person.count({
          where: { organizationId, deletedAt: null, status: 'ACTIVE' },
        }),
        this.prisma.person.count({
          where: { organizationId, deletedAt: null, status: 'ACTIVE', createdAt: { gte: utcDayBoundary } },
        }),
        this.prisma.followUp.count({
          where: { organizationId, status: { in: ['PENDING', 'IN_PROGRESS'] } },
        }),
        this.prisma.event.findMany({
          where: { organizationId, deletedAt: null, startDate: { gte: now } },
          orderBy: [{ startDate: 'asc' }, { id: 'asc' }],
          take: UPCOMING_EVENTS_TAKE,
          select: { id: true, title: true, startDate: true },
        }) as Promise<UpcomingEventRow[]>,
        this.prisma.person.findMany({
          where: { organizationId, deletedAt: null, status: 'ACTIVE' },
          orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
          take: RECENT_MEMBERS_TAKE,
          select: { id: true, firstName: true, lastName: true, createdAt: true },
        }) as Promise<RecentMemberRow[]>,
        this.prisma.followUp.findMany({
          where: { organizationId, status: { in: ['PENDING', 'IN_PROGRESS'] } },
          orderBy: [{ dueDate: { sort: 'asc', nulls: 'last' } }, { id: 'asc' }],
          take: PENDING_TASKS_TAKE,
          select: { id: true, title: true, description: true, dueDate: true },
        }) as Promise<PendingTaskRow[]>,
      ]);

    return {
      totalPeople,
      newPeople,
      pendingFollowUps,
      upcomingEvents: upcomingEventRows.map((row) => ({
        id: row.id,
        title: row.title,
        startDate: row.startDate.toISOString(),
      })),
      recentMembers: recentMemberRows.map((row) => ({
        id: row.id,
        firstName: row.firstName,
        lastName: row.lastName,
        joinedAt: row.createdAt.toISOString(),
      })),
      pendingTasks: pendingTaskRows.map((row) => ({
        id: row.id,
        title: row.title,
        description: row.description,
        dueDate: row.dueDate ? row.dueDate.toISOString() : null,
      })),
    };
  }
}
