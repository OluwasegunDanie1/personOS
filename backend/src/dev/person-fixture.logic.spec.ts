import { runPersonFixture } from './person-fixture.logic';

function createMockPrisma() {
  return {
    user: { findUnique: jest.fn() },
    organizationMembership: { findMany: jest.fn() },
    person: { findMany: jest.fn(), create: jest.fn() },
  };
}

function baseEnv(overrides: Partial<{
  nodeEnv: string | undefined;
  authFixtureEmail: string | undefined;
  authFixtureOrganizationName: string | undefined;
  personFixtureFirstName: string | undefined;
  personFixtureLastName: string | undefined;
}> = {}) {
  return {
    nodeEnv: 'development',
    authFixtureEmail: 'ada@example.com',
    authFixtureOrganizationName: 'Acme Church',
    personFixtureFirstName: 'John',
    personFixtureLastName: 'Doe',
    ...overrides,
  };
}

describe('runPersonFixture', () => {
  let prisma: ReturnType<typeof createMockPrisma>;

  beforeEach(() => {
    prisma = createMockPrisma();
  });

  it('refuses to run in production before any database access', async () => {
    await expect(runPersonFixture({ env: baseEnv({ nodeEnv: 'production' }), prisma })).rejects.toThrow(
      'NODE_ENV=production',
    );

    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('fails clearly when AUTH_FIXTURE_EMAIL is missing', async () => {
    await expect(
      runPersonFixture({ env: baseEnv({ authFixtureEmail: undefined }), prisma }),
    ).rejects.toThrow('AUTH_FIXTURE_EMAIL is required.');
  });

  it('fails clearly when AUTH_FIXTURE_ORGANIZATION_NAME is missing', async () => {
    await expect(
      runPersonFixture({ env: baseEnv({ authFixtureOrganizationName: undefined }), prisma }),
    ).rejects.toThrow('AUTH_FIXTURE_ORGANIZATION_NAME is required.');
  });

  it('fails clearly when PERSON_FIXTURE_FIRST_NAME is missing', async () => {
    await expect(
      runPersonFixture({ env: baseEnv({ personFixtureFirstName: undefined }), prisma }),
    ).rejects.toThrow('PERSON_FIXTURE_FIRST_NAME is required.');
  });

  it('fails clearly when PERSON_FIXTURE_FIRST_NAME trims to empty', async () => {
    await expect(
      runPersonFixture({ env: baseEnv({ personFixtureFirstName: '   ' }), prisma }),
    ).rejects.toThrow('PERSON_FIXTURE_FIRST_NAME is required.');
  });

  it('fails clearly when PERSON_FIXTURE_LAST_NAME is missing', async () => {
    await expect(
      runPersonFixture({ env: baseEnv({ personFixtureLastName: undefined }), prisma }),
    ).rejects.toThrow('PERSON_FIXTURE_LAST_NAME is required.');
  });

  it('does not depend on AUTH_FIXTURE_PASSWORD', () => {
    const env = baseEnv() as Record<string, unknown>;
    expect('authFixturePassword' in env).toBe(false);
  });

  it('fails clearly when the controlled fixture User does not exist', async () => {
    prisma.user.findUnique.mockResolvedValue(null);

    await expect(runPersonFixture({ env: baseEnv(), prisma })).rejects.toThrow(
      'controlled fixture User does not exist',
    );
    expect(prisma.organizationMembership.findMany).not.toHaveBeenCalled();
  });

  it('resolves the organization through the controlled User membership + organization name', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.person.findMany.mockResolvedValue([]);

    await runPersonFixture({ env: baseEnv(), prisma });

    expect(prisma.organizationMembership.findMany).toHaveBeenCalledWith({
      where: { userId: 'user-1', organization: { name: 'Acme Church' } },
      select: { organizationId: true },
    });
  });

  it('fails clearly when the fixture organization is absent', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([]);

    await expect(runPersonFixture({ env: baseEnv(), prisma })).rejects.toThrow(
      'could not be found for this User',
    );
  });

  it('fails clearly when multiple organizations match (ambiguous)', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([
      { organizationId: 'org-1' },
      { organizationId: 'org-2' },
    ]);

    await expect(runPersonFixture({ env: baseEnv(), prisma })).rejects.toThrow('ambiguous');
  });

  it('creates exactly one Person with the approved shape', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.person.findMany.mockResolvedValue([]);

    const result = await runPersonFixture({
      env: baseEnv({ personFixtureFirstName: '  John  ', personFixtureLastName: '  Doe  ' }),
      prisma,
    });

    expect(result).toBe('created');
    expect(prisma.person.create).toHaveBeenCalledWith({
      data: {
        organizationId: 'org-1',
        firstName: 'John',
        lastName: 'Doe',
        email: null,
        phone: null,
        status: 'ACTIVE',
        profilePhoto: null,
        deletedAt: null,
      },
      select: { id: true },
    });
  });

  it('is idempotent: a second execution reports already_exists without creating a duplicate', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.person.findMany.mockResolvedValueOnce([{ id: 'person-1', deletedAt: null }]);

    const result = await runPersonFixture({ env: baseEnv(), prisma });

    expect(result).toBe('already_exists');
    expect(prisma.person.create).not.toHaveBeenCalled();
  });

  it('fails clearly when a matching Person exists but is soft-deleted', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.person.findMany.mockResolvedValue([{ id: 'person-1', deletedAt: new Date() }]);

    await expect(runPersonFixture({ env: baseEnv(), prisma })).rejects.toThrow('soft-deleted');
    expect(prisma.person.create).not.toHaveBeenCalled();
  });

  it('fails clearly when multiple matching non-deleted Persons exist (ambiguous)', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.person.findMany.mockResolvedValue([
      { id: 'person-1', deletedAt: null },
      { id: 'person-2', deletedAt: null },
    ]);

    await expect(runPersonFixture({ env: baseEnv(), prisma })).rejects.toThrow('ambiguous');
  });

  it('never mutates an already-existing matching Person', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organizationMembership.findMany.mockResolvedValue([{ organizationId: 'org-1' }]);
    prisma.person.findMany.mockResolvedValue([{ id: 'person-1', deletedAt: null }]);

    await runPersonFixture({ env: baseEnv(), prisma });

    expect(prisma.person.create).not.toHaveBeenCalled();
  });
});
