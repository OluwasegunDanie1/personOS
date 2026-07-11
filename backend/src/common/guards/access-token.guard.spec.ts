import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserStatus } from '../../../generated/prisma/client';
import { ApiException } from '../http/api-exception';
import { AuthenticatedRequest } from '../http/request-context';
import { AccessTokenGuard } from './access-token.guard';

function buildRequest(authorization?: string): AuthenticatedRequest {
  return { headers: { authorization }, params: {} };
}

function buildContext(request: AuthenticatedRequest): ExecutionContext {
  return {
    getHandler: () => ({}) as never,
    getClass: () => ({}) as never,
    switchToHttp: () => ({ getRequest: () => request }) as never,
  } as unknown as ExecutionContext;
}

describe('AccessTokenGuard', () => {
  let accessTokenService: { verify: jest.Mock };
  let prisma: { user: { findUnique: jest.Mock } };

  beforeEach(() => {
    accessTokenService = { verify: jest.fn() };
    prisma = { user: { findUnique: jest.fn() } };
  });

  function buildGuard(isPublic: boolean): AccessTokenGuard {
    const reflector = { getAllAndOverride: jest.fn().mockReturnValue(isPublic) } as unknown as Reflector;
    return new AccessTokenGuard(reflector, accessTokenService as never, prisma as never);
  }

  async function expectDenied(request: AuthenticatedRequest, isPublic = false): Promise<ApiException> {
    const guard = buildGuard(isPublic);
    try {
      await guard.canActivate(buildContext(request));
      throw new Error('expected canActivate to throw');
    } catch (error) {
      return error as ApiException;
    }
  }

  it('bypasses authentication when explicit public metadata is present', async () => {
    const guard = buildGuard(true);

    const result = await guard.canActivate(buildContext(buildRequest()));

    expect(result).toBe(true);
    expect(accessTokenService.verify).not.toHaveBeenCalled();
  });

  it('rejects a missing Authorization header with AUTHENTICATION_REQUIRED', async () => {
    const error = await expectDenied(buildRequest(undefined));

    expect(error.code).toBe('AUTHENTICATION_REQUIRED');
  });

  it('rejects a non-Bearer scheme with AUTHENTICATION_REQUIRED', async () => {
    const error = await expectDenied(buildRequest('Token some-value'));

    expect(error.code).toBe('AUTHENTICATION_REQUIRED');
  });

  it('rejects an empty Bearer token with AUTHENTICATION_REQUIRED', async () => {
    const error = await expectDenied(buildRequest('Bearer '));

    expect(error.code).toBe('AUTHENTICATION_REQUIRED');
  });

  it('rejects a verification failure with INVALID_ACCESS_TOKEN', async () => {
    accessTokenService.verify.mockRejectedValue(new Error('jwt malformed'));

    const error = await expectDenied(buildRequest('Bearer some-token'));

    expect(error.code).toBe('INVALID_ACCESS_TOKEN');
  });

  it('never exposes the underlying JWT library error message', async () => {
    accessTokenService.verify.mockRejectedValue(new Error('jwt expired at 2020-01-01'));

    const error = await expectDenied(buildRequest('Bearer some-token'));

    expect(error.message).not.toContain('2020-01-01');
  });

  it('rejects a missing sub claim with INVALID_ACCESS_TOKEN', async () => {
    accessTokenService.verify.mockResolvedValue({ sub: undefined });

    const error = await expectDenied(buildRequest('Bearer some-token'));

    expect(error.code).toBe('INVALID_ACCESS_TOKEN');
  });

  it('rejects an empty sub claim with INVALID_ACCESS_TOKEN', async () => {
    accessTokenService.verify.mockResolvedValue({ sub: '' });

    const error = await expectDenied(buildRequest('Bearer some-token'));

    expect(error.code).toBe('INVALID_ACCESS_TOKEN');
  });

  it('rejects when the User cannot be found with INVALID_ACCESS_TOKEN', async () => {
    accessTokenService.verify.mockResolvedValue({ sub: 'user-1' });
    prisma.user.findUnique.mockResolvedValue(null);

    const error = await expectDenied(buildRequest('Bearer some-token'));

    expect(error.code).toBe('INVALID_ACCESS_TOKEN');
  });

  it('rejects a deleted User with INVALID_ACCESS_TOKEN', async () => {
    accessTokenService.verify.mockResolvedValue({ sub: 'user-1' });
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: UserStatus.ACTIVE, deletedAt: new Date() });

    const error = await expectDenied(buildRequest('Bearer some-token'));

    expect(error.code).toBe('INVALID_ACCESS_TOKEN');
  });

  it('rejects a DISABLED User with USER_DISABLED', async () => {
    accessTokenService.verify.mockResolvedValue({ sub: 'user-1' });
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: UserStatus.DISABLED, deletedAt: null });

    const error = await expectDenied(buildRequest('Bearer some-token'));

    expect(error.code).toBe('USER_DISABLED');
  });

  it('attaches exactly {userId} for an ACTIVE User and returns true', async () => {
    accessTokenService.verify.mockResolvedValue({ sub: 'user-1' });
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: UserStatus.ACTIVE, deletedAt: null });
    const request = buildRequest('Bearer some-token');
    const guard = buildGuard(false);

    const result = await guard.canActivate(buildContext(request));

    expect(result).toBe(true);
    expect(request.auth).toEqual({ userId: 'user-1' });
    expect(Object.keys(request.auth as object)).toEqual(['userId']);
  });

  it('only ever selects id/status/deletedAt, never passwordHash or the full User model', async () => {
    accessTokenService.verify.mockResolvedValue({ sub: 'user-1' });
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: UserStatus.ACTIVE, deletedAt: null });
    const guard = buildGuard(false);

    await guard.canActivate(buildContext(buildRequest('Bearer some-token')));

    expect(prisma.user.findUnique).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      select: { id: true, status: true, deletedAt: true },
    });
  });

  it('verifies via AccessTokenService rather than performing its own JWT decoding', async () => {
    accessTokenService.verify.mockResolvedValue({ sub: 'user-1' });
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: UserStatus.ACTIVE, deletedAt: null });
    const guard = buildGuard(false);

    await guard.canActivate(buildContext(buildRequest('Bearer some-token')));

    expect(accessTokenService.verify).toHaveBeenCalledWith('some-token');
  });
});
