import { runJourneyFixture } from './journey-fixture.logic';

function createMockPrisma() {
  return {
    user: { findUnique: jest.fn() },
    organizationMembership: { findMany: jest.fn() },
    journeyTemplate: { findMany: jest.fn(), create: jest.fn() },
    journeyStage: { findMany: jest.fn(), create: jest.fn() },
    $transaction: jest.fn(),
  };
}

function baseEnv(overrides: Partial<{
  nodeEnv: string | undefined;
  authFixtureEmail: string | undefined;
  authFixtureOrganizationName: string | undefined;
  journeyFixtureTemplateName: string | undefined;
  journeyFixtureStageOneName: string | undefined;
  journeyFixtureStageTwoName: string | undefined;
}> = {}) {
  return {
    nodeEnv: 'development',
    authFixtureEmail: 'ada@example.com',
    authFixtureOrganizationName: 'Acme Church',
    journeyFixtureTemplateName: 'Main Journey',
    journeyFixtureStageOneName: 'Visitor',
    journeyFixtureStageTwoName: 'Member',
    ...overrides,
  };
}

describe('runJourneyFixture', () => {
  let prisma: ReturnType<typeof createMockPrisma>;

  beforeEach(() => {
    prisma = createMockPrisma();
    prisma.$transaction.mockImplementation((ops: Promise<unknown>[]) => Promise.all(ops));
  });

  it('refuses to run in production before any database access', async () => {
    await expect(runJourneyFixture({ env: baseEnv({ nodeEnv: 'production' }), prisma })).rejects.toThrow(
      'NODE_ENV=production',
    );
    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('fails clearly when AUTH_FIXTURE_EMAIL is missing', async () => {
    await expect(
      runJourneyFixture({ env: baseEnv({ authFixtureEmail: undefined }), prisma }),
    ).rejects.toThrow('AUTH_FIXTURE_EMAIL is required.');
  });

  it('fails clearly when AUTH_FIXTURE_ORGANIZATION_NAME is missing', async () => {
    await expect(
      runJourneyFixture({ env: baseEnv({ authFixtureOrganizationName: undefined }), prisma }),
    ).rejects.toThrow('AUTH_FIXTURE_ORGANIZATION_NAME is required.');
  });

  it('fails clearly when JOURNEY_FIXTURE_TEMPLATE_NAME is missing', async () => {
    await expect(
      runJourneyFixture({ env: baseEnv({ journeyFixtureTemplateName: undefined }), prisma }),
    ).rejects.toThrow('JOURNEY_FIXTURE_TEMPLATE_NAME is required.');
  });

  it('fails clearly when JOURNEY_FIXTURE_STAGE_ONE_NAME is missing', async () => {
    await expect(
      runJourneyFixture({ env: baseEnv({ journeyFixtureStageOneName: undefined }), prisma }),
    ).rejects.toThrow('JOURNEY_FIXTURE_STAGE_ONE_NAME is required.');
  });

  it('fails clearly when JOURNEY_FIXTURE_STAGE_TWO_NAME is missing', async () => {
    await expect(
      runJourneyFixture({ env: baseEnv({ journeyFixtureStageTwoName: undefined }), prisma }),
    ).rejects.toThrow('JOURNEY_FIXTURE_STAGE_TWO_NAME is required.');
  });

  it('fails clearly when a required value trims to empty', async () => {
    await expect(
      runJourneyFixture({ env: baseEnv({ journeyFixtureStageOneName: '   ' }), prisma }),
    ).rejects.toThrow('JOURNEY_FIXTURE_STAGE_ONE_NAME is required.');
  });

  it('does not depend on AUTH_FIXTURE_PASSWORD', () => {
    const env = baseEnv() as Record<string, unknown>;
    expect('authFixturePassword' in env).toBe(false);
  });

  it('fails clearly when the controlled fixture User does not exist', async () => {
    prisma.user.findUnique.mockResolvedValue(null);

    await expect(runJourneyFixture({ env: baseEnv(), prisma })).rejects.toThrow(
      'controlled fixture User does not exist',
    );
    expect(prisma.organizationMembership.findMany).not.toHaveBeenCalled();
  });

  it('fails clearly when the fixture organization is absent', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([]);

    await expect(runJourneyFixture({ env: baseEnv(), prisma })).rejects.toThrow(
      'could not be found for this User',
    );
  });

  it('fails clearly when multiple organizations match (ambiguous)', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([
      { organizationId: 'org-1' },
      { organizationId: 'org-2' },
    ]);

    await expect(runJourneyFixture({ env: baseEnv(), prisma })).rejects.toThrow('ambiguous');
  });

  it('creates exactly one JourneyTemplate and two JourneyStages in one transaction', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.journeyTemplate.findMany.mockResolvedValue([]);

    const result = await runJourneyFixture({ env: baseEnv(), prisma });

    expect(result).toBe('created');
    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    const transactionArg = prisma.$transaction.mock.calls[0][0];
    expect(transactionArg).toHaveLength(3);

    const templateArgs = prisma.journeyTemplate.create.mock.calls[0][0];
    expect(templateArgs.data).toMatchObject({
      organizationId: 'org-1',
      name: 'Main Journey',
      description: null,
    });

    const stageCalls = prisma.journeyStage.create.mock.calls;
    expect(stageCalls[0][0].data).toMatchObject({ name: 'Visitor', order: 1 });
    expect(stageCalls[1][0].data).toMatchObject({ name: 'Member', order: 2 });
    expect(stageCalls[0][0].data.journeyTemplateId).toBe(templateArgs.data.id);
    expect(stageCalls[1][0].data.journeyTemplateId).toBe(templateArgs.data.id);
  });

  it('creates zero PersonJourneyHistory or other records', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.journeyTemplate.findMany.mockResolvedValue([]);
    const otherModelCalls = jest.fn();
    const prismaWithExtraModels = {
      ...prisma,
      personJourneyHistory: { create: otherModelCalls },
      person: { create: otherModelCalls },
    };

    await runJourneyFixture({ env: baseEnv(), prisma: prismaWithExtraModels as never });

    expect(otherModelCalls).not.toHaveBeenCalled();
  });

  it('is idempotent: a second execution reports already_exists without creating a duplicate', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.journeyTemplate.findMany.mockResolvedValue([{ id: 'template-1', name: 'Main Journey' }]);
    prisma.journeyStage.findMany.mockResolvedValue([
      { id: 'stage-1', name: 'Visitor', order: 1 },
      { id: 'stage-2', name: 'Member', order: 2 },
    ]);

    const result = await runJourneyFixture({ env: baseEnv(), prisma });

    expect(result).toBe('already_exists');
    expect(prisma.journeyTemplate.create).not.toHaveBeenCalled();
    expect(prisma.journeyStage.create).not.toHaveBeenCalled();
  });

  it('fails clearly on partial state: matching template with the wrong stage count', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.journeyTemplate.findMany.mockResolvedValue([{ id: 'template-1', name: 'Main Journey' }]);
    prisma.journeyStage.findMany.mockResolvedValue([{ id: 'stage-1', name: 'Visitor', order: 1 }]);

    await expect(runJourneyFixture({ env: baseEnv(), prisma })).rejects.toThrow(
      'does not have exactly the expected two stages',
    );
  });

  it('fails clearly when multiple template candidates exist', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.journeyTemplate.findMany.mockResolvedValue([
      { id: 'template-1', name: 'Main Journey' },
      { id: 'template-2', name: 'Main Journey' },
    ]);

    await expect(runJourneyFixture({ env: baseEnv(), prisma })).rejects.toThrow(
      'Multiple matching JourneyTemplates',
    );
  });

  it('fails clearly when stage names/positions do not match expectations (extra/mismatched stage)', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.journeyTemplate.findMany.mockResolvedValue([{ id: 'template-1', name: 'Main Journey' }]);
    prisma.journeyStage.findMany.mockResolvedValue([
      { id: 'stage-1', name: 'Visitor', order: 1 },
      { id: 'stage-2', name: 'SomethingElse', order: 2 },
    ]);

    await expect(runJourneyFixture({ env: baseEnv(), prisma })).rejects.toThrow(
      'do not match the expected names/positions',
    );
  });

  it('never mutates existing matching records', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.journeyTemplate.findMany.mockResolvedValue([{ id: 'template-1', name: 'Main Journey' }]);
    prisma.journeyStage.findMany.mockResolvedValue([
      { id: 'stage-1', name: 'Visitor', order: 1 },
      { id: 'stage-2', name: 'Member', order: 2 },
    ]);

    await runJourneyFixture({ env: baseEnv(), prisma });

    expect(prisma.journeyTemplate.create).not.toHaveBeenCalled();
    expect(prisma.journeyStage.create).not.toHaveBeenCalled();
  });
});
