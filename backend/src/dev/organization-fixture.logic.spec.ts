import { runOrganizationFixture } from './organization-fixture.logic';

function createMockPrisma() {
  return {
    user: { findUnique: jest.fn() },
    organization: { findMany: jest.fn(), create: jest.fn() },
    role: { findUnique: jest.fn(), create: jest.fn() },
    organizationMembership: { findUnique: jest.fn(), create: jest.fn() },
    $transaction: jest.fn(),
  };
}

function baseEnv(overrides: Partial<{
  nodeEnv: string | undefined;
  authFixtureEmail: string | undefined;
  authFixtureOrganizationName: string | undefined;
}> = {}) {
  return {
    nodeEnv: 'development',
    authFixtureEmail: 'ada@example.com',
    authFixtureOrganizationName: 'Acme Church',
    ...overrides,
  };
}

describe('runOrganizationFixture', () => {
  let prisma: ReturnType<typeof createMockPrisma>;

  beforeEach(() => {
    prisma = createMockPrisma();
    prisma.$transaction.mockImplementation((ops: Promise<unknown>[]) => Promise.all(ops));
  });

  it('refuses to run in production before any database access', async () => {
    await expect(
      runOrganizationFixture({ env: baseEnv({ nodeEnv: 'production' }), prisma }),
    ).rejects.toThrow('NODE_ENV=production');

    expect(prisma.user.findUnique).not.toHaveBeenCalled();
    expect(prisma.organization.findMany).not.toHaveBeenCalled();
  });

  it('fails clearly when AUTH_FIXTURE_EMAIL is missing', async () => {
    await expect(
      runOrganizationFixture({ env: baseEnv({ authFixtureEmail: undefined }), prisma }),
    ).rejects.toThrow('AUTH_FIXTURE_EMAIL is required.');
  });

  it('fails clearly when AUTH_FIXTURE_EMAIL normalizes to empty', async () => {
    await expect(
      runOrganizationFixture({ env: baseEnv({ authFixtureEmail: '   ' }), prisma }),
    ).rejects.toThrow('AUTH_FIXTURE_EMAIL is required.');
  });

  it('fails clearly when AUTH_FIXTURE_ORGANIZATION_NAME is missing', async () => {
    await expect(
      runOrganizationFixture({ env: baseEnv({ authFixtureOrganizationName: undefined }), prisma }),
    ).rejects.toThrow('AUTH_FIXTURE_ORGANIZATION_NAME is required.');
  });

  it('fails clearly when AUTH_FIXTURE_ORGANIZATION_NAME trims to empty', async () => {
    await expect(
      runOrganizationFixture({ env: baseEnv({ authFixtureOrganizationName: '   ' }), prisma }),
    ).rejects.toThrow('AUTH_FIXTURE_ORGANIZATION_NAME is required.');
  });

  it('fails clearly when the controlled fixture User does not exist', async () => {
    prisma.user.findUnique.mockResolvedValue(null);

    await expect(runOrganizationFixture({ env: baseEnv(), prisma })).rejects.toThrow(
      'controlled fixture User does not exist',
    );

    expect(prisma.organization.findMany).not.toHaveBeenCalled();
  });

  it('normalizes email with trim + lowercase before the User lookup', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organization.findMany.mockResolvedValue([]);

    await runOrganizationFixture({ env: baseEnv({ authFixtureEmail: '  Ada@Example.com  ' }), prisma });

    expect(prisma.user.findUnique).toHaveBeenCalledWith({
      where: { email: 'ada@example.com' },
      select: { id: true },
    });
  });

  it('trims the organization name before lookup and creation', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organization.findMany.mockResolvedValue([]);

    await runOrganizationFixture({ env: baseEnv({ authFixtureOrganizationName: '  Acme Church  ' }), prisma });

    expect(prisma.organization.findMany).toHaveBeenCalledWith({
      where: { name: 'Acme Church' },
      select: { id: true, name: true },
    });
    const orgCreateArgs = prisma.organization.create.mock.calls[0][0];
    expect(orgCreateArgs.data.name).toBe('Acme Church');
  });

  it('creates the Organization, Owner Role, and Membership through one transaction', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organization.findMany.mockResolvedValue([]);

    const result = await runOrganizationFixture({ env: baseEnv(), prisma });

    expect(result).toBe('created');
    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    const transactionArg = prisma.$transaction.mock.calls[0][0];
    expect(Array.isArray(transactionArg)).toBe(true);
    expect(transactionArg).toHaveLength(3);

    expect(prisma.organization.create).toHaveBeenCalledTimes(1);
    expect(prisma.role.create).toHaveBeenCalledTimes(1);
    expect(prisma.organizationMembership.create).toHaveBeenCalledTimes(1);

    const roleArgs = prisma.role.create.mock.calls[0][0];
    expect(roleArgs.data.name).toBe('Owner');

    const membershipArgs = prisma.organizationMembership.create.mock.calls[0][0];
    expect(membershipArgs.data.userId).toBe('user-1');
    expect(membershipArgs.data.organizationId).toBe(roleArgs.data.organizationId);
    expect(membershipArgs.data.roleId).toBe(roleArgs.data.id);
  });

  it('creates no Permission, RolePermission, product-domain, or auth-token record', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organization.findMany.mockResolvedValue([]);
    const otherModelCalls = jest.fn();
    const prismaWithExtraModels = {
      ...prisma,
      permission: { create: otherModelCalls },
      rolePermission: { create: otherModelCalls },
      person: { create: otherModelCalls },
      event: { create: otherModelCalls },
      attendance: { create: otherModelCalls },
      refreshToken: { create: otherModelCalls },
      emailVerificationToken: { create: otherModelCalls },
      passwordResetToken: { create: otherModelCalls },
    };

    await runOrganizationFixture({ env: baseEnv(), prisma: prismaWithExtraModels as never });

    expect(otherModelCalls).not.toHaveBeenCalled();
  });

  it('is idempotent: a second execution reports already_exists without creating a duplicate', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organization.findMany.mockResolvedValueOnce([]);
    const first = await runOrganizationFixture({ env: baseEnv(), prisma });
    expect(first).toBe('created');

    const createdOrgArgs = prisma.organization.create.mock.calls[0][0];
    const createdRoleArgs = prisma.role.create.mock.calls[0][0];
    const createdMembershipArgs = prisma.organizationMembership.create.mock.calls[0][0];

    prisma.organization.findMany.mockResolvedValueOnce([
      { id: createdOrgArgs.data.id, name: createdOrgArgs.data.name },
    ]);
    prisma.organizationMembership.findUnique.mockResolvedValueOnce({
      id: 'membership-1',
      roleId: createdMembershipArgs.data.roleId,
    });
    prisma.role.findUnique.mockResolvedValueOnce({
      id: createdRoleArgs.data.id,
      name: 'Owner',
      organizationId: createdOrgArgs.data.id,
    });

    const second = await runOrganizationFixture({ env: baseEnv(), prisma });

    expect(second).toBe('already_exists');
    expect(prisma.organization.create).toHaveBeenCalledTimes(1);
    expect(prisma.role.create).toHaveBeenCalledTimes(1);
    expect(prisma.organizationMembership.create).toHaveBeenCalledTimes(1);
  });

  it('fails when a matching organization exists but the controlled User has no membership', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organization.findMany.mockResolvedValue([{ id: 'org-1', name: 'Acme Church' }]);
    prisma.organizationMembership.findUnique.mockResolvedValue(null);

    await expect(runOrganizationFixture({ env: baseEnv(), prisma })).rejects.toThrow('no membership');
    expect(prisma.organization.create).not.toHaveBeenCalled();
  });

  it('fails when the membership role cannot be resolved (missing role)', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organization.findMany.mockResolvedValue([{ id: 'org-1', name: 'Acme Church' }]);
    prisma.organizationMembership.findUnique.mockResolvedValue({ id: 'membership-1', roleId: 'role-1' });
    prisma.role.findUnique.mockResolvedValue(null);

    await expect(runOrganizationFixture({ env: baseEnv(), prisma })).rejects.toThrow(
      'could not be resolved consistently',
    );
  });

  it('fails when the existing membership role is not Owner', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organization.findMany.mockResolvedValue([{ id: 'org-1', name: 'Acme Church' }]);
    prisma.organizationMembership.findUnique.mockResolvedValue({ id: 'membership-1', roleId: 'role-1' });
    prisma.role.findUnique.mockResolvedValue({ id: 'role-1', name: 'Volunteer', organizationId: 'org-1' });

    await expect(runOrganizationFixture({ env: baseEnv(), prisma })).rejects.toThrow('is not Owner');
  });

  it('fails when multiple organizations match the fixture organization name', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organization.findMany.mockResolvedValue([
      { id: 'org-1', name: 'Acme Church' },
      { id: 'org-2', name: 'Acme Church' },
    ]);

    await expect(runOrganizationFixture({ env: baseEnv(), prisma })).rejects.toThrow('ambiguous');
    expect(prisma.organizationMembership.findUnique).not.toHaveBeenCalled();
  });

  it('does not depend on AUTH_FIXTURE_PASSWORD', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.organization.findMany.mockResolvedValue([]);

    const env = baseEnv() as Record<string, unknown>;
    expect('authFixturePassword' in env).toBe(false);

    const result = await runOrganizationFixture({ env: baseEnv(), prisma });

    expect(result).toBe('created');
  });
});
