import { UserStatus } from '../../generated/prisma/client';
import { runAuthFixture } from './auth-fixture.logic';

function createMockPrisma() {
  return {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
  };
}

function createMockPasswordHashService() {
  return {
    hash: jest.fn().mockResolvedValue('hashed-value'),
  };
}

describe('runAuthFixture', () => {
  it('refuses to run in production before any database access', async () => {
    const prisma = createMockPrisma();
    const passwordHashService = createMockPasswordHashService();

    await expect(
      runAuthFixture({
        env: { nodeEnv: 'production', authFixtureEmail: 'x@example.com', authFixturePassword: 'x' },
        prisma,
        passwordHashService,
      }),
    ).rejects.toThrow('NODE_ENV=production');

    expect(prisma.user.findUnique).not.toHaveBeenCalled();
    expect(prisma.user.create).not.toHaveBeenCalled();
    expect(passwordHashService.hash).not.toHaveBeenCalled();
  });

  it('fails clearly when AUTH_FIXTURE_EMAIL is missing', async () => {
    const prisma = createMockPrisma();
    const passwordHashService = createMockPasswordHashService();

    await expect(
      runAuthFixture({
        env: { nodeEnv: 'development', authFixtureEmail: undefined, authFixturePassword: 'x' },
        prisma,
        passwordHashService,
      }),
    ).rejects.toThrow('AUTH_FIXTURE_EMAIL is required.');
  });

  it('fails clearly when AUTH_FIXTURE_EMAIL is empty', async () => {
    const prisma = createMockPrisma();
    const passwordHashService = createMockPasswordHashService();

    await expect(
      runAuthFixture({
        env: { nodeEnv: 'development', authFixtureEmail: '', authFixturePassword: 'x' },
        prisma,
        passwordHashService,
      }),
    ).rejects.toThrow('AUTH_FIXTURE_EMAIL is required.');
  });

  it('fails clearly when AUTH_FIXTURE_PASSWORD is missing', async () => {
    const prisma = createMockPrisma();
    const passwordHashService = createMockPasswordHashService();

    await expect(
      runAuthFixture({
        env: { nodeEnv: 'development', authFixtureEmail: 'x@example.com', authFixturePassword: undefined },
        prisma,
        passwordHashService,
      }),
    ).rejects.toThrow('AUTH_FIXTURE_PASSWORD is required.');
  });

  it('fails clearly when AUTH_FIXTURE_PASSWORD is empty', async () => {
    const prisma = createMockPrisma();
    const passwordHashService = createMockPasswordHashService();

    await expect(
      runAuthFixture({
        env: { nodeEnv: 'development', authFixtureEmail: 'x@example.com', authFixturePassword: '' },
        prisma,
        passwordHashService,
      }),
    ).rejects.toThrow('AUTH_FIXTURE_PASSWORD is required.');
  });

  it('normalizes email using trim and lowercase before lookup and creation', async () => {
    const prisma = createMockPrisma();
    prisma.user.findUnique.mockResolvedValue(null);
    const passwordHashService = createMockPasswordHashService();

    await runAuthFixture({
      env: { nodeEnv: 'development', authFixtureEmail: '  Ada@Example.com  ', authFixturePassword: 'correct-password' },
      prisma,
      passwordHashService,
    });

    expect(prisma.user.findUnique).toHaveBeenCalledWith({ where: { email: 'ada@example.com' } });
    expect(prisma.user.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ email: 'ada@example.com' }) }),
    );
  });

  it('hashes the password through PasswordHashService when creating', async () => {
    const prisma = createMockPrisma();
    prisma.user.findUnique.mockResolvedValue(null);
    const passwordHashService = createMockPasswordHashService();

    await runAuthFixture({
      env: { nodeEnv: 'development', authFixtureEmail: 'ada@example.com', authFixturePassword: 'correct-password' },
      prisma,
      passwordHashService,
    });

    expect(passwordHashService.hash).toHaveBeenCalledWith('correct-password');
  });

  it('never persists the raw password', async () => {
    const prisma = createMockPrisma();
    prisma.user.findUnique.mockResolvedValue(null);
    const passwordHashService = createMockPasswordHashService();

    await runAuthFixture({
      env: { nodeEnv: 'development', authFixtureEmail: 'ada@example.com', authFixturePassword: 'correct-password' },
      prisma,
      passwordHashService,
    });

    const createArgs = prisma.user.create.mock.calls[0][0];
    expect(createArgs.data.passwordHash).toBe('hashed-value');
    expect(createArgs.data.passwordHash).not.toBe('correct-password');
    expect(JSON.stringify(createArgs)).not.toContain('correct-password');
  });

  it('creates exactly the approved new-user shape', async () => {
    const prisma = createMockPrisma();
    prisma.user.findUnique.mockResolvedValue(null);
    const passwordHashService = createMockPasswordHashService();

    const result = await runAuthFixture({
      env: { nodeEnv: 'development', authFixtureEmail: 'ada@example.com', authFixturePassword: 'correct-password' },
      prisma,
      passwordHashService,
    });

    expect(result).toBe('created');
    const createArgs = prisma.user.create.mock.calls[0][0];
    expect(createArgs.data).toEqual({
      email: 'ada@example.com',
      passwordHash: 'hashed-value',
      phone: null,
      status: UserStatus.ACTIVE,
      lastLogin: null,
      deletedAt: null,
      firstName: expect.any(String),
      lastName: expect.any(String),
    });
  });

  it('does not mutate or duplicate an already-existing matching user', async () => {
    const prisma = createMockPrisma();
    prisma.user.findUnique.mockResolvedValue({ id: 'existing-user-id' });
    const passwordHashService = createMockPasswordHashService();

    const result = await runAuthFixture({
      env: { nodeEnv: 'development', authFixtureEmail: 'ada@example.com', authFixturePassword: 'correct-password' },
      prisma,
      passwordHashService,
    });

    expect(result).toBe('already_exists');
    expect(prisma.user.create).not.toHaveBeenCalled();
  });

  it('does not hash the password when a matching user already exists', async () => {
    const prisma = createMockPrisma();
    prisma.user.findUnique.mockResolvedValue({ id: 'existing-user-id' });
    const passwordHashService = createMockPasswordHashService();

    await runAuthFixture({
      env: { nodeEnv: 'development', authFixtureEmail: 'ada@example.com', authFixturePassword: 'correct-password' },
      prisma,
      passwordHashService,
    });

    expect(passwordHashService.hash).not.toHaveBeenCalled();
  });

  it('distinguishes created vs already_exists in its neutral result', async () => {
    const prisma = createMockPrisma();
    const passwordHashService = createMockPasswordHashService();

    prisma.user.findUnique.mockResolvedValueOnce(null);
    const first = await runAuthFixture({
      env: { nodeEnv: 'development', authFixtureEmail: 'ada@example.com', authFixturePassword: 'x' },
      prisma,
      passwordHashService,
    });

    prisma.user.findUnique.mockResolvedValueOnce({ id: 'existing-user-id' });
    const second = await runAuthFixture({
      env: { nodeEnv: 'development', authFixtureEmail: 'ada@example.com', authFixturePassword: 'x' },
      prisma,
      passwordHashService,
    });

    expect(first).toBe('created');
    expect(second).toBe('already_exists');
  });

  it('touches no product-domain or token model', async () => {
    const otherModelCalls = jest.fn();
    const prisma = {
      user: { findUnique: jest.fn().mockResolvedValue(null), create: jest.fn() },
      organization: { create: otherModelCalls },
      organizationMembership: { create: otherModelCalls },
      role: { create: otherModelCalls },
      permission: { create: otherModelCalls },
      person: { create: otherModelCalls },
      event: { create: otherModelCalls },
      attendance: { create: otherModelCalls },
      refreshToken: { create: otherModelCalls },
      emailVerificationToken: { create: otherModelCalls },
      passwordResetToken: { create: otherModelCalls },
    };
    const passwordHashService = createMockPasswordHashService();

    await runAuthFixture({
      env: { nodeEnv: 'development', authFixtureEmail: 'ada@example.com', authFixturePassword: 'x' },
      prisma: prisma as never,
      passwordHashService,
    });

    expect(otherModelCalls).not.toHaveBeenCalled();
  });
});
