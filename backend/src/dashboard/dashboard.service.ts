import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

export interface UpcomingEventRef {
  id: string;
  title: string;
  startDate: string;
}

export interface DashboardSummary {
  totalPeople: number;
  newPeople: number;
  pendingFollowUps: number;
  upcomingEvents: UpcomingEventRef[];
}

interface UpcomingEventRow {
  id: string;
  title: string;
  startDate: Date;
}

const UPCOMING_EVENTS_TAKE = 5;

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * A single, read-only aggregate over People/FollowUp/Event, each
   * independently organizationId-scoped (the guard is never trusted as a
   * substitute for query scoping). All four operations share one captured
   * server instant so the UTC-day boundary and the upcoming-events
   * comparison stay logically consistent within a single response.
   */
  async summary(organizationId: string): Promise<DashboardSummary> {
    const now = new Date();
    const utcDayBoundary = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

    const [totalPeople, newPeople, pendingFollowUps, upcomingEventRows] = await Promise.all([
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
    };
  }
}
