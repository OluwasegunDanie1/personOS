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
    user: { findUnique: jest.fn(), update: jest.fn() },
    refreshToken: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
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
});
