import { randomUUID } from 'crypto';
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { CreateOrganizationDto } from './dto/create-organization.dto';
import { UpdateOrganizationDto } from './dto/update-organization.dto';

const OWNER_ROLE_NAME = 'Owner';

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

export interface OrganizationDetail {
  id: string;
  name: string;
}

/**
 * Extends the existing organization-fixture slugify() convention
 * (src/dev/organization-fixture.logic.ts) with an appended uniqueness
 * guarantee. Organization.slug is a required, unique, non-null persistence
 * column with no application-level meaning: it is never accepted from or
 * returned to the client (13_API_Specification.md). Reusing slugify(name)
 * alone would collide whenever two Organizations share a name, which v1
 * explicitly permits — so the newly generated Organization id (already
 * globally unique) is appended to guarantee collision-free uniqueness
 * without introducing a retry loop, counter suffix, or any user-facing slug
 * feature.
 */
function slugify(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
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

  /**
   * Not organization-scoped: the target Organization does not exist yet.
   * Atomically creates the Organization, a freshly named "Owner" Role scoped
   * to it, and the creator's OrganizationMembership linking both — so the
   * creator is immediately an active member usable by every existing
   * OrganizationMembershipGuard-protected endpoint, with zero Permission or
   * RolePermission rows created.
   */
  async create(userId: string, dto: CreateOrganizationDto): Promise<{ organization: OrganizationDetail }> {
    const organizationId = randomUUID();
    const roleId = randomUUID();
    const slug = `${slugify(dto.name)}-${organizationId}`;

    const [organization] = await this.prisma.$transaction([
      this.prisma.organization.create({
        data: { id: organizationId, name: dto.name, slug },
        select: { id: true, name: true },
      }),
      this.prisma.role.create({
        data: { id: roleId, organizationId, name: OWNER_ROLE_NAME },
        select: { id: true },
      }),
      this.prisma.organizationMembership.create({
        data: { organizationId, userId, roleId },
        select: { id: true },
      }),
    ]);

    return { organization };
  }

  /**
   * OrganizationMembershipGuard has already validated an active membership
   * for (organizationId, userId) before this runs; OrganizationMembership's
   * foreign key guarantees the referenced Organization row exists (there is
   * no Delete Organization path in v1), so a missing row here is an
   * unreachable internal invariant violation, not a public NOT_FOUND
   * condition — it is deliberately a plain Error, normalized to a generic
   * 500 by the existing GlobalExceptionFilter, mirroring
   * OperationalTemplateService's precedent for its own unreachable case.
   */
  async detail(organizationId: string): Promise<{ organization: OrganizationDetail }> {
    const organization = await this.prisma.organization.findFirst({
      where: { id: organizationId },
      select: { id: true, name: true },
    });

    if (!organization) {
      throw new Error('Organization not found for a validated membership context.');
    }

    return { organization };
  }

  async update(organizationId: string, dto: UpdateOrganizationDto): Promise<{ organization: OrganizationDetail }> {
    const organization = await this.prisma.organization.update({
      where: { id: organizationId },
      data: { name: dto.name },
      select: { id: true, name: true },
    });

    return { organization };
  }
}
