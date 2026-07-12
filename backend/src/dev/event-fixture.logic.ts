export type EventFixtureResult = 'created' | 'already_exists';

interface MembershipRow {
  organizationId: string;
}

interface EventMatchRow {
  id: string;
  deletedAt: Date | null;
}

export interface EventFixturePrisma {
  user: {
    findUnique(args: { where: { email: string }; select: { id: true } }): Promise<{ id: string } | null>;
  };
  organizationMembership: {
    findMany(args: {
      where: { userId: string; organization: { name: string } };
      select: { organizationId: true };
    }): Promise<MembershipRow[]>;
  };
  event: {
    findMany(args: {
      where: { organizationId: string; title: string; startDate: Date };
      select: { id: true; deletedAt: true };
    }): Promise<EventMatchRow[]>;
    create(args: {
      data: {
        organizationId: string;
        title: string;
        description: null;
        category: null;
        venue: null;
        startDate: Date;
        endDate: null;
        createdBy: string;
      };
      select: { id: true };
    }): Promise<{ id: string }>;
  };
}

export interface EventFixtureEnv {
  nodeEnv: string | undefined;
  authFixtureEmail: string | undefined;
  authFixtureOrganizationName: string | undefined;
  eventFixtureTitle: string | undefined;
  eventFixtureStartDate: string | undefined;
}

export interface EventFixtureDeps {
  env: EventFixtureEnv;
  prisma: EventFixturePrisma;
}

/**
 * Creates (or confirms) exactly one controlled local Event inside the
 * existing controlled fixture Organization, per the authority defined in
 * Deployment.md and 16_Security.md. Idempotent on (organization, normalized
 * title, exact startDate); never repairs conflicting partial state
 * (soft-deleted or ambiguous matches fail clearly). Creates zero Attendance
 * rows.
 */
export async function runEventFixture(deps: EventFixtureDeps): Promise<EventFixtureResult> {
  if (deps.env.nodeEnv === 'production') {
    throw new Error('The controlled event fixture must not run when NODE_ENV=production.');
  }

  if (!deps.env.authFixtureEmail) {
    throw new Error('AUTH_FIXTURE_EMAIL is required.');
  }

  if (!deps.env.authFixtureOrganizationName) {
    throw new Error('AUTH_FIXTURE_ORGANIZATION_NAME is required.');
  }

  if (!deps.env.eventFixtureTitle) {
    throw new Error('EVENT_FIXTURE_TITLE is required.');
  }

  if (!deps.env.eventFixtureStartDate) {
    throw new Error('EVENT_FIXTURE_START_DATE is required.');
  }

  const normalizedEmail = deps.env.authFixtureEmail.trim().toLowerCase();

  if (!normalizedEmail) {
    throw new Error('AUTH_FIXTURE_EMAIL is required.');
  }

  const trimmedOrganizationName = deps.env.authFixtureOrganizationName.trim();

  if (!trimmedOrganizationName) {
    throw new Error('AUTH_FIXTURE_ORGANIZATION_NAME is required.');
  }

  const trimmedTitle = deps.env.eventFixtureTitle.trim();

  if (!trimmedTitle) {
    throw new Error('EVENT_FIXTURE_TITLE is required.');
  }

  const trimmedStartDate = deps.env.eventFixtureStartDate.trim();

  if (!trimmedStartDate) {
    throw new Error('EVENT_FIXTURE_START_DATE is required.');
  }

  const startDate = new Date(trimmedStartDate);

  if (Number.isNaN(startDate.getTime())) {
    throw new Error('EVENT_FIXTURE_START_DATE must be a valid date.');
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

  const matches = await deps.prisma.event.findMany({
    where: { organizationId, title: trimmedTitle, startDate },
    select: { id: true, deletedAt: true },
  });

  const nonDeletedMatches = matches.filter((match) => match.deletedAt === null);

  if (nonDeletedMatches.length > 1) {
    throw new Error('Multiple matching Events already exist; refusing to repair ambiguous fixture state.');
  }

  if (nonDeletedMatches.length === 1) {
    return 'already_exists';
  }

  const deletedMatches = matches.filter((match) => match.deletedAt !== null);

  if (deletedMatches.length > 0) {
    throw new Error('A matching Event already exists but is soft-deleted; refusing to repair partial fixture state.');
  }

  await deps.prisma.event.create({
    data: {
      organizationId,
      title: trimmedTitle,
      description: null,
      category: null,
      venue: null,
      startDate,
      endDate: null,
      createdBy: user.id,
    },
    select: { id: true },
  });

  return 'created';
}
