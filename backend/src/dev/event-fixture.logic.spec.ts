import { runEventFixture } from './event-fixture.logic';

function createMockPrisma() {
  return {
    user: { findUnique: jest.fn() },
    organizationMembership: { findMany: jest.fn() },
    event: { findMany: jest.fn(), create: jest.fn() },
  };
}

function baseEnv(overrides: Partial<{
  nodeEnv: string | undefined;
  authFixtureEmail: string | undefined;
  authFixtureOrganizationName: string | undefined;
  eventFixtureTitle: string | undefined;
  eventFixtureStartDate: string | undefined;
}> = {}) {
  return {
    nodeEnv: 'development',
    authFixtureEmail: 'ada@example.com',
    authFixtureOrganizationName: 'Acme Church',
    eventFixtureTitle: 'Sunday Service',
    eventFixtureStartDate: '2026-08-02T09:00:00Z',
    ...overrides,
  };
}

describe('runEventFixture', () => {
  let prisma: ReturnType<typeof createMockPrisma>;

  beforeEach(() => {
    prisma = createMockPrisma();
  });

  it('refuses to run in production before any database access', async () => {
    await expect(runEventFixture({ env: baseEnv({ nodeEnv: 'production' }), prisma })).rejects.toThrow(
      'NODE_ENV=production',
    );
    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('fails clearly when AUTH_FIXTURE_EMAIL is missing', async () => {
    await expect(
      runEventFixture({ env: baseEnv({ authFixtureEmail: undefined }), prisma }),
    ).rejects.toThrow('AUTH_FIXTURE_EMAIL is required.');
  });

  it('fails clearly when AUTH_FIXTURE_ORGANIZATION_NAME is missing', async () => {
    await expect(
      runEventFixture({ env: baseEnv({ authFixtureOrganizationName: undefined }), prisma }),
    ).rejects.toThrow('AUTH_FIXTURE_ORGANIZATION_NAME is required.');
  });

  it('fails clearly when EVENT_FIXTURE_TITLE is missing', async () => {
    await expect(runEventFixture({ env: baseEnv({ eventFixtureTitle: undefined }), prisma })).rejects.toThrow(
      'EVENT_FIXTURE_TITLE is required.',
    );
  });

  it('fails clearly when EVENT_FIXTURE_START_DATE is missing', async () => {
    await expect(runEventFixture({ env: baseEnv({ eventFixtureStartDate: undefined }), prisma })).rejects.toThrow(
      'EVENT_FIXTURE_START_DATE is required.',
    );
  });

  it('fails clearly when EVENT_FIXTURE_START_DATE is not a valid date', async () => {
    await expect(
      runEventFixture({ env: baseEnv({ eventFixtureStartDate: 'not-a-date' }), prisma }),
    ).rejects.toThrow('EVENT_FIXTURE_START_DATE must be a valid date.');
  });

  it('does not depend on AUTH_FIXTURE_PASSWORD', () => {
    const env = baseEnv() as Record<string, unknown>;
    expect('authFixturePassword' in env).toBe(false);
  });

  it('fails clearly when the controlled fixture User does not exist', async () => {
    prisma.user.findUnique.mockResolvedValue(null);

    await expect(runEventFixture({ env: baseEnv(), prisma })).rejects.toThrow(
      'controlled fixture User does not exist',
    );
    expect(prisma.organizationMembership.findMany).not.toHaveBeenCalled();
  });

  it('fails clearly when the fixture organization is absent', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([]);

    await expect(runEventFixture({ env: baseEnv(), prisma })).rejects.toThrow('could not be found for this User');
  });

  it('fails clearly when multiple organizations match (ambiguous)', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([
      { organizationId: 'org-1' },
      { organizationId: 'org-2' },
    ]);

    await expect(runEventFixture({ env: baseEnv(), prisma })).rejects.toThrow('ambiguous');
  });

  it('creates exactly one Event with the approved fixture shape', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.event.findMany.mockResolvedValue([]);

    const result = await runEventFixture({ env: baseEnv(), prisma });

    expect(result).toBe('created');
    expect(prisma.event.create).toHaveBeenCalledTimes(1);
    const args = prisma.event.create.mock.calls[0][0];
    expect(args.data).toEqual({
      organizationId: 'org-1',
      title: 'Sunday Service',
      description: null,
      category: null,
      venue: null,
      startDate: new Date('2026-08-02T09:00:00Z'),
      endDate: null,
      createdBy: 'user-1',
    });
  });

  it('is idempotent: a second execution reports already_exists without creating a duplicate', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.event.findMany.mockResolvedValue([{ id: 'event-1', deletedAt: null }]);

    const result = await runEventFixture({ env: baseEnv(), prisma });

    expect(result).toBe('already_exists');
    expect(prisma.event.create).not.toHaveBeenCalled();
  });

  it('fails clearly when the matching Event is soft-deleted', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.event.findMany.mockResolvedValue([{ id: 'event-1', deletedAt: new Date() }]);

    await expect(runEventFixture({ env: baseEnv(), prisma })).rejects.toThrow(
      'already exists but is soft-deleted',
    );
    expect(prisma.event.create).not.toHaveBeenCalled();
  });

  it('fails clearly when multiple active matches exist', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.event.findMany.mockResolvedValue([
      { id: 'event-1', deletedAt: null },
      { id: 'event-2', deletedAt: null },
    ]);

    await expect(runEventFixture({ env: baseEnv(), prisma })).rejects.toThrow('ambiguous fixture state');
    expect(prisma.event.create).not.toHaveBeenCalled();
  });
});
