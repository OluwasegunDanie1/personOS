import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

export interface OrganizationSummary {
  id: string;
  name: string;
  logoUrl: string | null;
  role: {
    id: string;
    name: string;
  };
}

export interface OrganizationListResult {
  organizations: OrganizationSummary[];
}

@Injectable()
export class OrganizationsService {
  constructor(private readonly prisma: PrismaService) {}

  async listForUser(userId: string): Promise<OrganizationListResult> {
    const memberships = await this.prisma.organizationMembership.findMany({
      where: { userId },
      select: {
        organization: { select: { id: true, name: true, logo: true } },
        role: { select: { id: true, name: true } },
      },
      orderBy: [{ organization: { name: 'asc' } }, { organization: { id: 'asc' } }],
    });

    return {
      organizations: memberships.map((membership) => ({
        id: membership.organization.id,
        name: membership.organization.name,
        logoUrl: membership.organization.logo,
        role: {
          id: membership.role.id,
          name: membership.role.name,
        },
      })),
    };
  }
}
