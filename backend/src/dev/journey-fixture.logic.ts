import { randomUUID } from 'crypto';

export type JourneyFixtureResult = 'created' | 'already_exists';

interface MembershipRow {
  organizationId: string;
}

interface TemplateRow {
  id: string;
  name: string;
}

interface StageRow {
  id: string;
  name: string;
  order: number;
}

export interface JourneyFixturePrisma {
  user: {
    findUnique(args: { where: { email: string }; select: { id: true } }): Promise<{ id: string } | null>;
  };
  organizationMembership: {
    findMany(args: {
      where: { userId: string; organization: { name: string } };
      select: { organizationId: true };
    }): Promise<MembershipRow[]>;
  };
  journeyTemplate: {
    findMany(args: {
      where: { organizationId: string; name: string };
      select: { id: true; name: true };
    }): Promise<TemplateRow[]>;
    create(args: {
      data: { id: string; organizationId: string; name: string; description: null };
      select: { id: true; name: true };
    }): Promise<TemplateRow>;
  };
  journeyStage: {
    findMany(args: {
      where: { journeyTemplateId: string };
      select: { id: true; name: true; order: true };
    }): Promise<StageRow[]>;
    create(args: {
      data: { id: string; journeyTemplateId: string; name: string; order: number };
      select: { id: true; name: true; order: true };
    }): Promise<StageRow>;
  };
  $transaction<T extends unknown[]>(ops: readonly [...{ [K in keyof T]: Promise<T[K]> }]): Promise<T>;
}

export interface JourneyFixtureEnv {
  nodeEnv: string | undefined;
  authFixtureEmail: string | undefined;
  authFixtureOrganizationName: string | undefined;
  journeyFixtureTemplateName: string | undefined;
  journeyFixtureStageOneName: string | undefined;
  journeyFixtureStageTwoName: string | undefined;
}

export interface JourneyFixtureDeps {
  env: JourneyFixtureEnv;
  prisma: JourneyFixturePrisma;
}

function requireTrimmed(value: string | undefined, label: string): string {
  if (!value) {
    throw new Error(`${label} is required.`);
  }
  const trimmed = value.trim();
  if (!trimmed) {
    throw new Error(`${label} is required.`);
  }
  return trimmed;
}

/**
 * Creates (or confirms) exactly one controlled local JourneyTemplate plus
 * exactly two JourneyStages for the existing controlled fixture
 * Organization, per the authority defined in Deployment.md and
 * 16_Security.md. Idempotent on an exact matching operational template plus
 * exactly two matching stages at the expected positions; never repairs
 * conflicting partial state (fails clearly instead).
 */
export async function runJourneyFixture(deps: JourneyFixtureDeps): Promise<JourneyFixtureResult> {
  if (deps.env.nodeEnv === 'production') {
    throw new Error('The controlled journey fixture must not run when NODE_ENV=production.');
  }

  if (!deps.env.authFixtureEmail) {
    throw new Error('AUTH_FIXTURE_EMAIL is required.');
  }

  if (!deps.env.authFixtureOrganizationName) {
    throw new Error('AUTH_FIXTURE_ORGANIZATION_NAME is required.');
  }

  if (!deps.env.journeyFixtureTemplateName) {
    throw new Error('JOURNEY_FIXTURE_TEMPLATE_NAME is required.');
  }

  if (!deps.env.journeyFixtureStageOneName) {
    throw new Error('JOURNEY_FIXTURE_STAGE_ONE_NAME is required.');
  }

  if (!deps.env.journeyFixtureStageTwoName) {
    throw new Error('JOURNEY_FIXTURE_STAGE_TWO_NAME is required.');
  }

  const normalizedEmail = deps.env.authFixtureEmail.trim().toLowerCase();
  if (!normalizedEmail) {
    throw new Error('AUTH_FIXTURE_EMAIL is required.');
  }

  const trimmedOrganizationName = requireTrimmed(
    deps.env.authFixtureOrganizationName,
    'AUTH_FIXTURE_ORGANIZATION_NAME',
  );
  const trimmedTemplateName = requireTrimmed(
    deps.env.journeyFixtureTemplateName,
    'JOURNEY_FIXTURE_TEMPLATE_NAME',
  );
  const trimmedStageOneName = requireTrimmed(
    deps.env.journeyFixtureStageOneName,
    'JOURNEY_FIXTURE_STAGE_ONE_NAME',
  );
  const trimmedStageTwoName = requireTrimmed(
    deps.env.journeyFixtureStageTwoName,
    'JOURNEY_FIXTURE_STAGE_TWO_NAME',
  );

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

  const matchingTemplates = await deps.prisma.journeyTemplate.findMany({
    where: { organizationId, name: trimmedTemplateName },
    select: { id: true, name: true },
  });

  if (matchingTemplates.length > 1) {
    throw new Error('Multiple matching JourneyTemplates already exist; refusing to repair ambiguous fixture state.');
  }

  if (matchingTemplates.length === 1) {
    const template = matchingTemplates[0];

    const stages = await deps.prisma.journeyStage.findMany({
      where: { journeyTemplateId: template.id },
      select: { id: true, name: true, order: true },
    });

    if (stages.length !== 2) {
      throw new Error(
        'A matching JourneyTemplate exists but does not have exactly the expected two stages; refusing to repair partial fixture state.',
      );
    }

    const stageOne = stages.find((stage) => stage.order === 1);
    const stageTwo = stages.find((stage) => stage.order === 2);

    if (
      !stageOne ||
      !stageTwo ||
      stageOne.name !== trimmedStageOneName ||
      stageTwo.name !== trimmedStageTwoName
    ) {
      throw new Error(
        'A matching JourneyTemplate exists but its stages do not match the expected names/positions; refusing to repair partial fixture state.',
      );
    }

    return 'already_exists';
  }

  const templateId = randomUUID();
  const stageOneId = randomUUID();
  const stageTwoId = randomUUID();

  await deps.prisma.$transaction([
    deps.prisma.journeyTemplate.create({
      data: { id: templateId, organizationId, name: trimmedTemplateName, description: null },
      select: { id: true, name: true },
    }),
    deps.prisma.journeyStage.create({
      data: { id: stageOneId, journeyTemplateId: templateId, name: trimmedStageOneName, order: 1 },
      select: { id: true, name: true, order: true },
    }),
    deps.prisma.journeyStage.create({
      data: { id: stageTwoId, journeyTemplateId: templateId, name: trimmedStageTwoName, order: 2 },
      select: { id: true, name: true, order: true },
    }),
  ]);

  return 'created';
}
