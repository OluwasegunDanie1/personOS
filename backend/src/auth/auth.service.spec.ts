import { JwtService } from '@nestjs/jwt';
import { ApiException } from '../common/http/api-exception';
import { PrismaService } from '../database/prisma.service';
import { AccessTokenService } from '../security/access-token.service';
import { OpaqueTokenService } from '../security/opaque-token.service';
import { PasswordHashService } from '../security/password-hash.service';
import { AUTH_ERROR_CODES } from './auth.constants';
import { AuthService } from './auth.service';

function createMockPrisma() {
  return {
    user: { findUnique: jest.fn(), update: jest.fn(), create: jest.fn() },
    refreshToken: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
    passwordResetToken: {
      findUnique: jest.fn(),
      create: jest.fn(),
      updateMany: jest.fn(),
    },
    $transaction: jest.fn(),
  };
}

describe('AuthService', () => {
  const now = new Date();
  let correctPasswordHash: string;
  let prisma: ReturnType<typeof createMockPrisma>;
  let passwordHashService: PasswordHashService;
  let opaqueTokenService: OpaqueTokenService;
  let accessTokenService: AccessTokenService;
  let authService: AuthService;

  function buildUser(overrides: Record<string, unknown> = {}) {
    return {
      id: 'user-1',
      firstName: 'Ada',
      lastName: 'Lovelace',
      email: 'ada@example.com',
      passwordHash: correctPasswordHash,
      phone: null,
      status: 'ACTIVE',
      lastLogin: null,
      deletedAt: null,
      createdAt: now,
      updatedAt: now,
      ...overrides,
    };
  }

  function buildRefreshToken(overrides: Record<string, unknown> = {}) {
    return {
      id: 'token-1',
      userId: 'user-1',
      tokenHash: 'irrelevant-in-mock',
      familyId: 'family-1',
      expiresAt: new Date(Date.now() + 1000 * 60 * 60),
      revokedAt: null,
      createdAt: now,
      ...overrides,
    };
  }

  beforeAll(async () => {
    passwordHashService = new PasswordHashService();
    correctPasswordHash = await passwordHashService.hash('correct-password');
  });

  beforeEach(() => {
    prisma = createMockPrisma();
    prisma.$transaction.mockImplementation((ops: unknown[]) => Promise.all(ops));
    opaqueTokenService = new OpaqueTokenService();
    accessTokenService = new AccessTokenService(
      new JwtService({
        secret: 'unit-test-secret',
        signOptions: {
          algorithm: 'HS256',
          expiresIn: 900,
          issuer: 'relvio-api',
          audience: 'relvio-mobile',
        },
      }),
    );

    authService = new AuthService(
      prisma as unknown as PrismaService,
      accessTokenService,
      passwordHashService,
      opaqueTokenService,
    );
  });

  describe('login', () => {
    it('normalizes email before lookup', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(
        authService.login({ email: '  Ada@Example.com  ', password: 'x' }),
      ).rejects.toThrow();

      expect(prisma.user.findUnique).toHaveBeenCalledWith({ where: { email: 'ada@example.com' } });
    });

    it('uses the same INVALID_CREDENTIALS code for unknown email and wrong password', async () => {
      prisma.user.findUnique.mockResolvedValueOnce(null);
      let unknownEmailError: ApiException | undefined;
      try {
        await authService.login({ email: 'nobody@example.com', password: 'whatever' });
      } catch (error) {
        unknownEmailError = error as ApiException;
      }

      prisma.user.findUnique.mockResolvedValueOnce(buildUser());
      let wrongPasswordError: ApiException | undefined;
      try {
        await authService.login({ email: 'ada@example.com', password: 'incorrect-password' });
      } catch (error) {
        wrongPasswordError = error as ApiException;
      }

      expect(unknownEmailError?.code).toBe(AUTH_ERROR_CODES.INVALID_CREDENTIALS);
      expect(wrongPasswordError?.code).toBe(AUTH_ERROR_CODES.INVALID_CREDENTIALS);
    });

    it('rejects a disabled user and issues no tokens', async () => {
      prisma.user.findUnique.mockResolvedValue(buildUser({ status: 'DISABLED' }));

      let error: ApiException | undefined;
      try {
        await authService.login({ email: 'ada@example.com', password: 'correct-password' });
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe(AUTH_ERROR_CODES.USER_DISABLED);
      expect(prisma.refreshToken.create).not.toHaveBeenCalled();
    });

    it('updates lastLogin only after successful authentication', async () => {
      const user = buildUser();
      prisma.user.findUnique.mockResolvedValue(user);
      prisma.user.update.mockResolvedValue({ ...user, lastLogin: now });
      prisma.refreshToken.create.mockResolvedValue({});

      await authService.login({ email: 'ada@example.com', password: 'correct-password' });

      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { lastLogin: expect.any(Date) },
      });
    });

    it('persists only the refresh token hash, never the raw refresh token', async () => {
      const user = buildUser();
      prisma.user.findUnique.mockResolvedValue(user);
      prisma.user.update.mockResolvedValue(user);
      prisma.refreshToken.create.mockResolvedValue({});

      const result = await authService.login({ email: 'ada@example.com', password: 'correct-password' });

      const createArgs = prisma.refreshToken.create.mock.calls[0][0];
      expect(createArgs.data.tokenHash).toBe(opaqueTokenService.hash(result.refreshToken));
      expect(createArgs.data.tokenHash).not.toBe(result.refreshToken);
      expect(JSON.stringify(createArgs)).not.toContain(result.refreshToken);
    });

    it('returns expiresIn 900', async () => {
      const user = buildUser();
      prisma.user.findUnique.mockResolvedValue(user);
      prisma.user.update.mockResolvedValue(user);
      prisma.refreshToken.create.mockResolvedValue({});

      const result = await authService.login({ email: 'ada@example.com', password: 'correct-password' });

      expect(result.expiresIn).toBe(900);
    });

    it('returns a public user excluding passwordHash and deletedAt', async () => {
      const user = buildUser();
      prisma.user.findUnique.mockResolvedValue(user);
      prisma.user.update.mockResolvedValue(user);
      prisma.refreshToken.create.mockResolvedValue({});

      const result = await authService.login({ email: 'ada@example.com', password: 'correct-password' });

      expect(result.user).not.toHaveProperty('passwordHash');
      expect(result.user).not.toHaveProperty('deletedAt');
    });

    it('does not return organization, role, or permissions', async () => {
      const user = buildUser();
      prisma.user.findUnique.mockResolvedValue(user);
      prisma.user.update.mockResolvedValue(user);
      prisma.refreshToken.create.mockResolvedValue({});

      const result = await authService.login({ email: 'ada@example.com', password: 'correct-password' });

      expect(result).not.toHaveProperty('organization');
      expect(result).not.toHaveProperty('role');
      expect(result).not.toHaveProperty('permissions');
      expect(result.user).not.toHaveProperty('role');
      expect(result.user).not.toHaveProperty('permissions');
    });

    const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

    it('generates a UUID-compatible familyId, not an opaque token', async () => {
      const user = buildUser();
      prisma.user.findUnique.mockResolvedValue(user);
      prisma.user.update.mockResolvedValue(user);
      prisma.refreshToken.create.mockResolvedValue({});

      await authService.login({ email: 'ada@example.com', password: 'correct-password' });

      const createArgs = prisma.refreshToken.create.mock.calls[0][0];
      expect(createArgs.data.familyId).toMatch(UUID_PATTERN);
    });

    it('calls OpaqueTokenService.generate exactly once, only for the refresh token', async () => {
      const user = buildUser();
      prisma.user.findUnique.mockResolvedValue(user);
      prisma.user.update.mockResolvedValue(user);
      prisma.refreshToken.create.mockResolvedValue({});
      const generateSpy = jest.spyOn(opaqueTokenService, 'generate');

      await authService.login({ email: 'ada@example.com', password: 'correct-password' });

      expect(generateSpy).toHaveBeenCalledTimes(1);
    });

    it('submits the lastLogin update and refresh-token creation through one Prisma transaction', async () => {
      const user = buildUser();
      prisma.user.findUnique.mockResolvedValue(user);
      prisma.user.update.mockResolvedValue(user);
      prisma.refreshToken.create.mockResolvedValue({});

      await authService.login({ email: 'ada@example.com', password: 'correct-password' });

      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
      const transactionArg = prisma.$transaction.mock.calls[0][0];
      expect(Array.isArray(transactionArg)).toBe(true);
      expect(transactionArg).toHaveLength(2);
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { lastLogin: expect.any(Date) },
      });
      expect(prisma.refreshToken.create).toHaveBeenCalled();
    });

    it('does not produce a successful login result when the transaction fails', async () => {
      const user = buildUser();
      prisma.user.findUnique.mockResolvedValue(user);
      prisma.user.update.mockResolvedValue(user);
      prisma.refreshToken.create.mockResolvedValue({});
      prisma.$transaction.mockRejectedValueOnce(new Error('transaction failed'));

      await expect(
        authService.login({ email: 'ada@example.com', password: 'correct-password' }),
      ).rejects.toThrow('transaction failed');
    });
  });

  describe('refresh', () => {
    it('rejects an unknown refresh token generically', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await authService.refresh({ refreshToken: 'bogus' });
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe(AUTH_ERROR_CODES.INVALID_REFRESH_TOKEN);
    });

    it('rejects an expired refresh token', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue(
        buildRefreshToken({ expiresAt: new Date(Date.now() - 1000) }),
      );

      let error: ApiException | undefined;
      try {
        await authService.refresh({ refreshToken: 'expired' });
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe(AUTH_ERROR_CODES.INVALID_REFRESH_TOKEN);
    });

    it('rejects a disabled user', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue(buildRefreshToken());
      prisma.user.findUnique.mockResolvedValue(buildUser({ status: 'DISABLED' }));

      let error: ApiException | undefined;
      try {
        await authService.refresh({ refreshToken: 'some-token' });
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe(AUTH_ERROR_CODES.USER_DISABLED);
    });

    it('revokes all remaining family tokens on reuse of a revoked token', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue(buildRefreshToken({ revokedAt: new Date() }));
      prisma.user.findUnique.mockResolvedValue(buildUser());

      await expect(authService.refresh({ refreshToken: 'reused' })).rejects.toThrow();

      expect(prisma.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { familyId: 'family-1', revokedAt: null },
        data: { revokedAt: expect.any(Date) },
      });
    });

    it('revokes the old token and creates a replacement in the same family atomically', async () => {
      const token = buildRefreshToken();
      prisma.refreshToken.findUnique.mockResolvedValue(token);
      prisma.user.findUnique.mockResolvedValue(buildUser());

      const result = await authService.refresh({ refreshToken: 'valid-token' });

      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
      const transactionArg = prisma.$transaction.mock.calls[0][0];
      expect(Array.isArray(transactionArg)).toBe(true);
      expect(transactionArg).toHaveLength(2);

      expect(prisma.refreshToken.update).toHaveBeenCalledWith({
        where: { id: 'token-1' },
        data: { revokedAt: expect.any(Date) },
      });
      expect(prisma.refreshToken.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ familyId: 'family-1' }),
      });
      expect(result.expiresIn).toBe(900);
    });

    it('preserves the existing familyId and never generates a new one during rotation', async () => {
      const token = buildRefreshToken({ familyId: 'family-1' });
      prisma.refreshToken.findUnique.mockResolvedValue(token);
      prisma.user.findUnique.mockResolvedValue(buildUser());
      const generateSpy = jest.spyOn(opaqueTokenService, 'generate');

      await authService.refresh({ refreshToken: 'valid-token' });

      // Called once, only for the new raw refresh token, never for familyId.
      expect(generateSpy).toHaveBeenCalledTimes(1);
      const createArgs = prisma.refreshToken.create.mock.calls[0][0];
      expect(createArgs.data.familyId).toBe('family-1');
    });

    it('never persists the raw replacement refresh token', async () => {
      const token = buildRefreshToken();
      prisma.refreshToken.findUnique.mockResolvedValue(token);
      prisma.user.findUnique.mockResolvedValue(buildUser());

      const result = await authService.refresh({ refreshToken: 'valid-token' });

      const createArgs = prisma.refreshToken.create.mock.calls[0][0];
      expect(createArgs.data.tokenHash).toBe(opaqueTokenService.hash(result.refreshToken));
      expect(createArgs.data.tokenHash).not.toBe(result.refreshToken);
    });
  });

  describe('logout', () => {
    it('completes without revealing whether an unknown token exists', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue(null);

      await expect(authService.logout({ refreshToken: 'unknown' })).resolves.toBeUndefined();
      expect(prisma.refreshToken.update).not.toHaveBeenCalled();
    });

    it('revokes an active token', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue({
        id: 'token-1',
        familyId: 'family-1',
        revokedAt: null,
      });

      await authService.logout({ refreshToken: 'active-token' });

      expect(prisma.refreshToken.update).toHaveBeenCalledWith({
        where: { id: 'token-1' },
        data: { revokedAt: expect.any(Date) },
      });
    });

    it('completes idempotently for an already-revoked token', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue({
        id: 'token-1',
        familyId: 'family-1',
        revokedAt: new Date(),
      });

      await authService.logout({ refreshToken: 'already-revoked' });

      expect(prisma.refreshToken.update).not.toHaveBeenCalled();
    });

    it('does not revoke the whole family during normal logout', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue({
        id: 'token-1',
        familyId: 'family-1',
        revokedAt: null,
      });

      await authService.logout({ refreshToken: 'active-token' });

      expect(prisma.refreshToken.updateMany).not.toHaveBeenCalled();
    });
  });

  describe('register', () => {
    const dto = { firstName: '  Grace  ', lastName: '  Hopper  ', email: '  Grace@Example.com  ', password: 'correct-password' };

    it('normalizes email before the duplicate lookup and on the created row', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue(buildUser({ email: 'grace@example.com' }));

      await authService.register(dto as never);

      expect(prisma.user.findUnique).toHaveBeenCalledWith({ where: { email: 'grace@example.com' } });
      const createArgs = prisma.user.create.mock.calls[0][0];
      expect(createArgs.data.email).toBe('grace@example.com');
    });

    it('hashes the password with PasswordHashService, never storing it in plain text', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue(buildUser());

      await authService.register(dto as never);

      const createArgs = prisma.user.create.mock.calls[0][0];
      expect(createArgs.data.passwordHash).not.toBe('correct-password');
      expect(await passwordHashService.verify(createArgs.data.passwordHash, 'correct-password')).toBe(true);
    });

    it('creates the User with status ACTIVE', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue(buildUser());

      await authService.register(dto as never);

      const createArgs = prisma.user.create.mock.calls[0][0];
      expect(createArgs.data.status).toBe('ACTIVE');
    });

    it('rejects a duplicate email with EMAIL_ALREADY_REGISTERED and never creates a second User', async () => {
      prisma.user.findUnique.mockResolvedValue(buildUser({ email: 'grace@example.com' }));

      let error: ApiException | undefined;
      try {
        await authService.register(dto as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe(AUTH_ERROR_CODES.EMAIL_ALREADY_REGISTERED);
      expect(prisma.user.create).not.toHaveBeenCalled();
    });

    it('never fabricates an Organization, Role, or Membership row (mocked Prisma exposes no such model)', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue(buildUser());

      await authService.register(dto as never);

      expect(Object.keys(prisma).sort()).toEqual(
        ['user', 'refreshToken', 'passwordResetToken', '$transaction'].sort(),
      );
    });

    it('returns a public user excluding passwordHash', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue(buildUser());

      const result = await authService.register(dto as never);

      expect(result.user).not.toHaveProperty('passwordHash');
    });
  });

  describe('forgotPassword', () => {
    const originalNodeEnv = process.env.NODE_ENV;

    afterEach(() => {
      process.env.NODE_ENV = originalNodeEnv;
    });

    it('returns the exact non-disclosing message for an unknown email and creates no token', async () => {
      process.env.NODE_ENV = 'production';
      prisma.user.findUnique.mockResolvedValue(null);

      const result = await authService.forgotPassword({ email: 'nobody@example.com' } as never);

      expect(result).toEqual({
        message: 'If an account exists for this email, password reset instructions will be sent.',
      });
      expect(prisma.passwordResetToken.create).not.toHaveBeenCalled();
    });

    it('returns the exact same message for a known email (no disclosure difference)', async () => {
      process.env.NODE_ENV = 'production';
      prisma.user.findUnique.mockResolvedValue(buildUser());
      prisma.passwordResetToken.create.mockResolvedValue({});

      const result = await authService.forgotPassword({ email: 'ada@example.com' } as never);

      expect(result.message).toBe(
        'If an account exists for this email, password reset instructions will be sent.',
      );
    });

    it('persists only the token hash, never the raw token, with a 1-hour expiry and null usedAt', async () => {
      process.env.NODE_ENV = 'test';
      const user = buildUser();
      prisma.user.findUnique.mockResolvedValue(user);
      prisma.passwordResetToken.create.mockResolvedValue({});

      const before = Date.now();
      const result = await authService.forgotPassword({ email: 'ada@example.com' } as never);
      const after = Date.now();

      const createArgs = prisma.passwordResetToken.create.mock.calls[0][0];
      expect(createArgs.data.userId).toBe('user-1');
      expect(createArgs.data.tokenHash).toBe(opaqueTokenService.hash(result.developmentResetToken!));
      expect(createArgs.data.tokenHash).not.toBe(result.developmentResetToken);
      expect(createArgs.data).not.toHaveProperty('usedAt');
      const expiresAtMs = createArgs.data.expiresAt.getTime();
      expect(expiresAtMs).toBeGreaterThanOrEqual(before + 60 * 60 * 1000 - 1000);
      expect(expiresAtMs).toBeLessThanOrEqual(after + 60 * 60 * 1000 + 1000);
    });

    it('exposes developmentResetToken outside production', async () => {
      process.env.NODE_ENV = 'development';
      prisma.user.findUnique.mockResolvedValue(buildUser());
      prisma.passwordResetToken.create.mockResolvedValue({});

      const result = await authService.forgotPassword({ email: 'ada@example.com' } as never);

      expect(result.developmentResetToken).toBeDefined();
      expect(typeof result.developmentResetToken).toBe('string');
    });

    it('never exposes developmentResetToken in production', async () => {
      process.env.NODE_ENV = 'production';
      prisma.user.findUnique.mockResolvedValue(buildUser());
      prisma.passwordResetToken.create.mockResolvedValue({});

      const result = await authService.forgotPassword({ email: 'ada@example.com' } as never);

      expect(result).not.toHaveProperty('developmentResetToken');
    });
  });

  describe('resetPassword', () => {
    function buildResetToken(overrides: Record<string, unknown> = {}) {
      return {
        id: 'reset-1',
        userId: 'user-1',
        tokenHash: 'irrelevant-in-mock',
        expiresAt: new Date(Date.now() + 60 * 60 * 1000),
        usedAt: null,
        createdAt: now,
        ...overrides,
      };
    }

    it('rejects an unknown token', async () => {
      prisma.passwordResetToken.findUnique.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await authService.resetPassword({ token: 'bogus', newPassword: 'new-password-1' } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe(AUTH_ERROR_CODES.INVALID_RESET_TOKEN);
    });

    it('rejects an expired token', async () => {
      prisma.passwordResetToken.findUnique.mockResolvedValue(
        buildResetToken({ expiresAt: new Date(Date.now() - 1000) }),
      );

      let error: ApiException | undefined;
      try {
        await authService.resetPassword({ token: 'expired', newPassword: 'new-password-1' } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe(AUTH_ERROR_CODES.INVALID_RESET_TOKEN);
      expect(prisma.passwordResetToken.updateMany).not.toHaveBeenCalled();
    });

    it('rejects an already-used token', async () => {
      prisma.passwordResetToken.findUnique.mockResolvedValue(buildResetToken({ usedAt: new Date() }));

      let error: ApiException | undefined;
      try {
        await authService.resetPassword({ token: 'used', newPassword: 'new-password-1' } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe(AUTH_ERROR_CODES.INVALID_RESET_TOKEN);
    });

    it('rejects a concurrent replay that loses the atomic single-use claim (updateMany count 0)', async () => {
      prisma.passwordResetToken.findUnique.mockResolvedValue(buildResetToken());
      prisma.passwordResetToken.updateMany.mockResolvedValue({ count: 0 });

      let error: ApiException | undefined;
      try {
        await authService.resetPassword({ token: 'raced', newPassword: 'new-password-1' } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe(AUTH_ERROR_CODES.INVALID_RESET_TOKEN);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('claims the token atomically by id + usedAt:null before mutating anything', async () => {
      prisma.passwordResetToken.findUnique.mockResolvedValue(buildResetToken());
      prisma.passwordResetToken.updateMany.mockResolvedValue({ count: 1 });
      prisma.user.update.mockResolvedValue(buildUser());
      prisma.refreshToken.updateMany.mockResolvedValue({ count: 0 });

      await authService.resetPassword({ token: 'valid', newPassword: 'new-password-1' } as never);

      const claimArgs = prisma.passwordResetToken.updateMany.mock.calls[0][0];
      expect(claimArgs.where).toEqual({ id: 'reset-1', usedAt: null });
      expect(claimArgs.data).toEqual({ usedAt: expect.any(Date) });
    });

    it('updates User.passwordHash with a real Argon2id hash of the new password', async () => {
      prisma.passwordResetToken.findUnique.mockResolvedValue(buildResetToken());
      prisma.passwordResetToken.updateMany.mockResolvedValue({ count: 1 });
      prisma.user.update.mockResolvedValue(buildUser());
      prisma.refreshToken.updateMany.mockResolvedValue({ count: 0 });

      await authService.resetPassword({ token: 'valid', newPassword: 'brand-new-password' } as never);

      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
      const transactionArg = prisma.$transaction.mock.calls[0][0];
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { passwordHash: expect.any(String) },
      });
      const updateArgs = prisma.user.update.mock.calls[0][0];
      expect(await passwordHashService.verify(updateArgs.data.passwordHash, 'brand-new-password')).toBe(true);
      expect(Array.isArray(transactionArg)).toBe(true);
    });

    it('revokes every other active refresh token for that user in the same transaction', async () => {
      prisma.passwordResetToken.findUnique.mockResolvedValue(buildResetToken());
      prisma.passwordResetToken.updateMany.mockResolvedValue({ count: 1 });
      prisma.user.update.mockResolvedValue(buildUser());
      prisma.refreshToken.updateMany.mockResolvedValue({ count: 0 });

      await authService.resetPassword({ token: 'valid', newPassword: 'new-password-1' } as never);

      expect(prisma.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-1', revokedAt: null },
        data: { revokedAt: expect.any(Date) },
      });
    });

    it('returns exactly {success: true}', async () => {
      prisma.passwordResetToken.findUnique.mockResolvedValue(buildResetToken());
      prisma.passwordResetToken.updateMany.mockResolvedValue({ count: 1 });
      prisma.user.update.mockResolvedValue(buildUser());
      prisma.refreshToken.updateMany.mockResolvedValue({ count: 0 });

      const result = await authService.resetPassword({ token: 'valid', newPassword: 'new-password-1' } as never);

      expect(result).toEqual({ success: true });
    });
  });

  describe('me', () => {
    it('returns the exact public user shape for the authenticated userId', async () => {
      prisma.user.findUnique.mockResolvedValue(buildUser());

      const result = await authService.me('user-1');

      expect(prisma.user.findUnique).toHaveBeenCalledWith({ where: { id: 'user-1' } });
      expect(result.user).not.toHaveProperty('passwordHash');
      expect(result.user).not.toHaveProperty('deletedAt');
      expect(result.user.id).toBe('user-1');
    });

    it('does not include an organization-context field (no server-side authority exists)', async () => {
      prisma.user.findUnique.mockResolvedValue(buildUser());

      const result = await authService.me('user-1');

      expect(result).not.toHaveProperty('organization');
      expect(result.user).not.toHaveProperty('organization');
    });

    it('throws INVALID_ACCESS_TOKEN if the user cannot be found (defensive path)', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await authService.me('missing-user');
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe(AUTH_ERROR_CODES.INVALID_ACCESS_TOKEN);
    });
  });
});
