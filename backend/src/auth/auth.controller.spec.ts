import { GUARDS_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { ThrottlerGuard } from '@nestjs/throttler';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

const THROTTLER_LIMIT = 'THROTTLER:LIMIT';
const THROTTLER_TTL = 'THROTTLER:TTL';

function createMockAuthService() {
  return {
    login: jest.fn(),
    refresh: jest.fn(),
    logout: jest.fn(),
  };
}

describe('AuthController', () => {
  let authService: ReturnType<typeof createMockAuthService>;
  let controller: AuthController;

  beforeEach(() => {
    authService = createMockAuthService();
    controller = new AuthController(authService as unknown as AuthService);
  });

  it('is registered under the "auth" controller prefix', () => {
    expect(Reflect.getMetadata(PATH_METADATA, AuthController)).toBe('auth');
  });

  it('applies only ThrottlerGuard, never an access-token authentication guard', () => {
    const guards = Reflect.getMetadata(GUARDS_METADATA, AuthController) as unknown[];

    expect(guards).toEqual([ThrottlerGuard]);
  });

  describe('login', () => {
    it('delegates the exact DTO to AuthService.login', async () => {
      const dto = { email: 'ada@example.com', password: 'correct-password' };
      const expected = { accessToken: 'a', refreshToken: 'r', expiresIn: 900, user: {} };
      authService.login.mockResolvedValue(expected);

      const result = await controller.login(dto as never);

      expect(authService.login).toHaveBeenCalledWith(dto);
      expect(result).toBe(expected);
    });

    it('is throttled at 5 requests per 60 seconds', () => {
      expect(Reflect.getMetadata(THROTTLER_LIMIT + 'default', AuthController.prototype.login)).toBe(5);
      expect(Reflect.getMetadata(THROTTLER_TTL + 'default', AuthController.prototype.login)).toBe(60_000);
    });
  });

  describe('refresh', () => {
    it('delegates the refreshToken field to AuthService.refresh', async () => {
      const dto = { refreshToken: 'raw-refresh-token' };
      const expected = { accessToken: 'a', refreshToken: 'r2', expiresIn: 900 };
      authService.refresh.mockResolvedValue(expected);

      const result = await controller.refresh(dto as never);

      expect(authService.refresh).toHaveBeenCalledWith(dto);
      expect(result).toBe(expected);
    });

    it('is throttled at 10 requests per 60 seconds', () => {
      expect(Reflect.getMetadata(THROTTLER_LIMIT + 'default', AuthController.prototype.refresh)).toBe(10);
      expect(Reflect.getMetadata(THROTTLER_TTL + 'default', AuthController.prototype.refresh)).toBe(60_000);
    });
  });

  describe('logout', () => {
    it('delegates the refreshToken field to AuthService.logout', async () => {
      const dto = { refreshToken: 'raw-refresh-token' };
      authService.logout.mockResolvedValue(undefined);

      await controller.logout(dto as never);

      expect(authService.logout).toHaveBeenCalledWith(dto);
    });

    it('returns exactly {success:true} rather than the AuthService void result', async () => {
      const dto = { refreshToken: 'raw-refresh-token' };
      authService.logout.mockResolvedValue(undefined);

      const result = await controller.logout(dto as never);

      expect(result).toEqual({ success: true });
    });

    it('is throttled at 20 requests per 60 seconds', () => {
      expect(Reflect.getMetadata(THROTTLER_LIMIT + 'default', AuthController.prototype.logout)).toBe(20);
      expect(Reflect.getMetadata(THROTTLER_TTL + 'default', AuthController.prototype.logout)).toBe(60_000);
    });
  });
});
