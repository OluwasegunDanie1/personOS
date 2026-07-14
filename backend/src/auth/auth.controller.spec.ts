import { GUARDS_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { ThrottlerGuard } from '@nestjs/throttler';
import { IS_PUBLIC_KEY } from '../common/decorators/public.decorator';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

const THROTTLER_LIMIT = 'THROTTLER:LIMIT';
const THROTTLER_TTL = 'THROTTLER:TTL';

function createMockAuthService() {
  return {
    login: jest.fn(),
    refresh: jest.fn(),
    logout: jest.fn(),
    register: jest.fn(),
    forgotPassword: jest.fn(),
    resetPassword: jest.fn(),
    me: jest.fn(),
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

  describe('register', () => {
    it('delegates the exact DTO to AuthService.register', async () => {
      const dto = { firstName: 'Grace', lastName: 'Hopper', email: 'grace@example.com', password: 'secret123' };
      const expected = { user: {} };
      authService.register.mockResolvedValue(expected);

      const result = await controller.register(dto as never);

      expect(authService.register).toHaveBeenCalledWith(dto);
      expect(result).toBe(expected);
    });

    it('is throttled at 5 requests per 15 minutes', () => {
      expect(Reflect.getMetadata(THROTTLER_LIMIT + 'default', AuthController.prototype.register)).toBe(5);
      expect(Reflect.getMetadata(THROTTLER_TTL + 'default', AuthController.prototype.register)).toBe(900_000);
    });
  });

  describe('forgotPassword', () => {
    it('delegates the exact DTO to AuthService.forgotPassword', async () => {
      const dto = { email: 'ada@example.com' };
      const expected = { message: 'If an account exists for this email, password reset instructions will be sent.' };
      authService.forgotPassword.mockResolvedValue(expected);

      const result = await controller.forgotPassword(dto as never);

      expect(authService.forgotPassword).toHaveBeenCalledWith(dto);
      expect(result).toBe(expected);
    });

    it('is throttled at 5 requests per 15 minutes', () => {
      expect(Reflect.getMetadata(THROTTLER_LIMIT + 'default', AuthController.prototype.forgotPassword)).toBe(5);
      expect(Reflect.getMetadata(THROTTLER_TTL + 'default', AuthController.prototype.forgotPassword)).toBe(900_000);
    });
  });

  describe('resetPassword', () => {
    it('delegates the exact DTO to AuthService.resetPassword', async () => {
      const dto = { token: 'raw-token', newPassword: 'brand-new-password' };
      const expected = { success: true };
      authService.resetPassword.mockResolvedValue(expected);

      const result = await controller.resetPassword(dto as never);

      expect(authService.resetPassword).toHaveBeenCalledWith(dto);
      expect(result).toBe(expected);
    });
  });

  describe('me', () => {
    it('delegates the authenticated request.auth.userId to AuthService.me, never a client-supplied id', async () => {
      const expected = { user: {} };
      authService.me.mockResolvedValue(expected);
      const request = { headers: {}, params: {}, auth: { userId: 'user-1' } };

      const result = await controller.me(request as never);

      expect(authService.me).toHaveBeenCalledWith('user-1');
      expect(result).toBe(expected);
    });

    it('is not marked @Public — it requires the global AccessTokenGuard', () => {
      const isPublic = Reflect.getMetadata(IS_PUBLIC_KEY, AuthController.prototype.me);
      expect(isPublic).toBeUndefined();
    });
  });

  it('login/refresh/logout/register/forgotPassword/resetPassword are all marked @Public, unlike me', () => {
    for (const handler of [
      AuthController.prototype.login,
      AuthController.prototype.refresh,
      AuthController.prototype.logout,
      AuthController.prototype.register,
      AuthController.prototype.forgotPassword,
      AuthController.prototype.resetPassword,
    ]) {
      expect(Reflect.getMetadata(IS_PUBLIC_KEY, handler)).toBe(true);
    }
  });
});
