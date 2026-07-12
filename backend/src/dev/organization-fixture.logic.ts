import { randomUUID } from 'crypto';

const OWNER_ROLE_NAME = 'Owner';

export type OrganizationFixtureResult = 'created' | 'already_exists';

interface OrganizationRow {
  id: string;
  name: string;
}

interface RoleRow {
  id: string;
  name: string;
  organizationId: string;
}

interface MembershipRow {
  id: string;
  roleId: string;
}

export interface OrganizationFixturePrisma {
  user: {
    findUnique(args: { where: { email: string }; select: { id: true } }): Promise<{ id: string } | null>;
  };
  organization: {
    findMany(args: { where: { name: string }; select: { id: true; name: true } }): Promise<OrganizationRow[]>;
    create(args: {
      data: { id: string; name: string; slug: string };
      select: { id: true; name: true };
    }): Promise<OrganizationRow>;
  };
  role: {
    findUnique(args: {
      where: { id: string };
      select: { id: true; name: true; organizationId: true };
    }): Promise<RoleRow | null>;
    create(args: {
      data: { id: string; organizationId: string; name: string };
      select: { id: true; name: true; organizationId: true };
    }): Promise<RoleRow>;
  };
  organizationMembership: {
    findUnique(args: {
      where: { organizationId_userId: { organizationId: string; userId: string } };
      select: { id: true; roleId: true };
    }): Promise<MembershipRow | null>;
    create(args: {
      data: { organizationId: string; userId: string; roleId: string };
      select: { id: true; roleId: true };
    }): Promise<MembershipRow>;
  };
  $transaction<T extends unknown[]>(ops: readonly [...{ [K in keyof T]: Promise<T[K]> }]): Promise<T>;
}

export interface OrganizationFixtureEnv {
  nodeEnv: string | undefined;
  authFixtureEmail: string | undefined;
  authFixtureOrganizationName: string | undefined;
}

export interface OrganizationFixtureDeps {
  env: OrganizationFixtureEnv;
  prisma: OrganizationFixturePrisma;
}

function slugify(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

/**
 * Creates (or confirms) exactly one controlled local Organization + Owner
 * Role + OrganizationMembership for the existing controlled auth-fixture
 * User, per the authority defined in Deployment.md and 16_Security.md.
 * Idempotent per (fixture organization name, controlled User membership).
 * Never repairs conflicting partial fixture state; fails clearly instead.
 */
export async function runOrganizationFixture(deps: OrganizationFixtureDeps): Promise<OrganizationFixtureResult> {
  if (deps.env.nodeEnv === 'production') {
    throw new Error('The controlled organization fixture must not run when NODE_ENV=production.');
  }

  if (!deps.env.authFixtureEmail) {
    throw new Error('AUTH_FIXTURE_EMAIL is required.');
  }

  if (!deps.env.authFixtureOrganizationName) {
    throw new Error('AUTH_FIXTURE_ORGANIZATION_NAME is required.');
  }

  const normalizedEmail = deps.env.authFixtureEmail.trim().toLowerCase();

  if (!normalizedEmail) {
    throw new Error('AUTH_FIXTURE_EMAIL is required.');
  }

  const trimmedOrganizationName = deps.env.authFixtureOrganizationName.trim();

  if (!trimmedOrganizationName) {
    throw new Error('AUTH_FIXTURE_ORGANIZATION_NAME is required.');
  }

  const user = await deps.prisma.user.findUnique({ where: { email: normalizedEmail }, select: { id: true } });

  if (!user) {
    throw new Error('The controlled fixture User does not exist. Run the auth fixture first.');
  }

  const matchingOrganizations = await deps.prisma.organization.findMany({
    where: { name: trimmedOrganizationName },
    select: { id: true, name: true },
  });

  if (matchingOrganizations.length > 1) {
    throw new Error(
      'Multiple organizations match AUTH_FIXTURE_ORGANIZATION_NAME; the fixture target is ambiguous.',
    );
  }

  if (matchingOrganizations.length === 1) {
    const organization = matchingOrganizations[0];

    const membership = await deps.prisma.organizationMembership.findUnique({
      where: { organizationId_userId: { organizationId: organization.id, userId: user.id } },
      select: { id: true, roleId: true },
    });

    if (!membership) {
      throw new Error(
        'A matching organization exists but the controlled User has no membership; refusing to repair partial fixture state.',
      );
    }

    const role = await deps.prisma.role.findUnique({
      where: { id: membership.roleId },
      select: { id: true, name: true, organizationId: true },
    });

    if (!role || role.organizationId !== organization.id) {
      throw new Error(
        'The membership role could not be resolved consistently; refusing to repair partial fixture state.',
      );
    }

    if (role.name !== OWNER_ROLE_NAME) {
      throw new Error(
        'The existing membership role is not Owner; refusing to repair partial fixture state.',
      );
    }

    return 'already_exists';
  }

  const organizationId = randomUUID();
  const roleId = randomUUID();

  await deps.prisma.$transaction([
    deps.prisma.organization.create({
      data: { id: organizationId, name: trimmedOrganizationName, slug: slugify(trimmedOrganizationName) },
      select: { id: true, name: true },
    }),
    deps.prisma.role.create({
      data: { id: roleId, organizationId, name: OWNER_ROLE_NAME },
      select: { id: true, name: true, organizationId: true },
    }),
    deps.prisma.organizationMembership.create({
      data: { organizationId, userId: user.id, roleId },
      select: { id: true, roleId: true },
    }),
  ]);

  return 'created';
}
