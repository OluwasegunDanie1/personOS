export type PersonFixtureResult = 'created' | 'already_exists';

interface MembershipRow {
  organizationId: string;
}

interface PersonMatchRow {
  id: string;
  deletedAt: Date | null;
}

export interface PersonFixturePrisma {
  user: {
    findUnique(args: { where: { email: string }; select: { id: true } }): Promise<{ id: string } | null>;
  };
  organizationMembership: {
    findMany(args: {
      where: { userId: string; organization: { name: string } };
      select: { organizationId: true };
    }): Promise<MembershipRow[]>;
  };
  person: {
    findMany(args: {
      where: { organizationId: string; firstName: string; lastName: string; email: null; phone: null };
      select: { id: true; deletedAt: true };
    }): Promise<PersonMatchRow[]>;
    create(args: {
      data: {
        organizationId: string;
        firstName: string;
        lastName: string;
        email: null;
        phone: null;
        status: string;
        profilePhoto: null;
        deletedAt: null;
      };
      select: { id: true };
    }): Promise<{ id: string }>;
  };
}

export interface PersonFixtureEnv {
  nodeEnv: string | undefined;
  authFixtureEmail: string | undefined;
  authFixtureOrganizationName: string | undefined;
  personFixtureFirstName: string | undefined;
  personFixtureLastName: string | undefined;
}

export interface PersonFixtureDeps {
  env: PersonFixtureEnv;
  prisma: PersonFixturePrisma;
}

/**
 * Creates (or confirms) exactly one controlled local Person inside the
 * existing controlled fixture Organization, per the authority defined in
 * Deployment.md and 16_Security.md. Idempotent on (organization, normalized
 * firstName, normalized lastName, null email, null phone); never repairs
 * conflicting partial state (soft-deleted or ambiguous matches fail clearly).
 */
export async function runPersonFixture(deps: PersonFixtureDeps): Promise<PersonFixtureResult> {
  if (deps.env.nodeEnv === 'production') {
    throw new Error('The controlled person fixture must not run when NODE_ENV=production.');
  }

  if (!deps.env.authFixtureEmail) {
    throw new Error('AUTH_FIXTURE_EMAIL is required.');
  }

  if (!deps.env.authFixtureOrganizationName) {
    throw new Error('AUTH_FIXTURE_ORGANIZATION_NAME is required.');
  }

  if (!deps.env.personFixtureFirstName) {
    throw new Error('PERSON_FIXTURE_FIRST_NAME is required.');
  }

  if (!deps.env.personFixtureLastName) {
    throw new Error('PERSON_FIXTURE_LAST_NAME is required.');
  }

  const normalizedEmail = deps.env.authFixtureEmail.trim().toLowerCase();

  if (!normalizedEmail) {
    throw new Error('AUTH_FIXTURE_EMAIL is required.');
  }

  const trimmedOrganizationName = deps.env.authFixtureOrganizationName.trim();

  if (!trimmedOrganizationName) {
    throw new Error('AUTH_FIXTURE_ORGANIZATION_NAME is required.');
  }

  const trimmedFirstName = deps.env.personFixtureFirstName.trim();

  if (!trimmedFirstName) {
    throw new Error('PERSON_FIXTURE_FIRST_NAME is required.');
  }

  const trimmedLastName = deps.env.personFixtureLastName.trim();

  if (!trimmedLastName) {
    throw new Error('PERSON_FIXTURE_LAST_NAME is required.');
  }

  const user = await deps.prisma.user.findUnique({ where: { email: normalizedEmail }, select: { id: true } });

  if (!user) {
    throw new Error('The controlled fixture User does not exist. Run the auth fixture first.');
  }

  const memberships = await deps.prisma.organizationMembership.findMany({
    where: { userId: user.id, organization: { name: trimmedOrganizationName } },
    select: { organizationId: true },
  });

  if (memberships.length === 0) {
    throw new Error(
      'The controlled fixture Organization could not be found for this User. Run the organization fixture first.',
    );
  }

  if (memberships.length > 1) {
    throw new Error('Multiple organizations match the controlled fixture target; ambiguous.');
  }

  const organizationId = memberships[0].organizationId;

  const matches = await deps.prisma.person.findMany({
    where: {
      organizationId,
      firstName: trimmedFirstName,
      lastName: trimmedLastName,
      email: null,
      phone: null,
    },
    select: { id: true, deletedAt: true },
  });

  const nonDeletedMatches = matches.filter((match) => match.deletedAt === null);

  if (nonDeletedMatches.length > 1) {
    throw new Error('Multiple matching Persons already exist; refusing to repair ambiguous fixture state.');
  }

  if (nonDeletedMatches.length === 1) {
    return 'already_exists';
  }

  const deletedMatches = matches.filter((match) => match.deletedAt !== null);

  if (deletedMatches.length > 0) {
    throw new Error(
      'A matching Person already exists but is soft-deleted; refusing to repair partial fixture state.',
    );
  }

  await deps.prisma.person.create({
    data: {
      organizationId,
      firstName: trimmedFirstName,
      lastName: trimmedLastName,
      email: null,
      phone: null,
      status: 'ACTIVE',
      profilePhoto: null,
      deletedAt: null,
    },
    select: { id: true },
  });

  return 'created';
}
