import { CanActivate, ExecutionContext, HttpStatus, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserStatus } from '../../../generated/prisma/client';
import { AUTH_ERROR_CODES } from '../../auth/auth.constants';
import { PrismaService } from '../../database/prisma.service';
import { AccessTokenService } from '../../security/access-token.service';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { ApiException } from '../http/api-exception';
import { AuthenticatedRequest } from '../http/request-context';

const BEARER_PREFIX = 'Bearer ';

/**
 * Single global guard. Bypassed only for routes carrying the explicit
 * @Public() metadata (currently POST /auth/login, /auth/refresh, /auth/logout).
 */
@Injectable()
export class AccessTokenGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly accessTokenService: AccessTokenService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const rawHeader = request.headers['authorization'];
    const authorizationHeader = Array.isArray(rawHeader) ? rawHeader[0] : rawHeader;

    if (!authorizationHeader || !authorizationHeader.startsWith(BEARER_PREFIX)) {
      throw this.authenticationRequiredError();
    }

    const token = authorizationHeader.slice(BEARER_PREFIX.length);

    if (!token) {
      throw this.authenticationRequiredError();
    }

    let sub: string;
    try {
      const payload = await this.accessTokenService.verify(token);
      if (typeof payload.sub !== 'string' || payload.sub.length === 0) {
        throw new Error('missing sub');
      }
      sub = payload.sub;
    } catch {
      throw this.invalidAccessTokenError();
    }

    const user = await this.prisma.user.findUnique({
      where: { id: sub },
      select: { id: true, status: true, deletedAt: true },
    });

    if (!user || user.deletedAt) {
      throw this.invalidAccessTokenError();
    }

    if (user.status === UserStatus.DISABLED) {
      throw this.userDisabledError();
    }

    request.auth = { userId: user.id };

    return true;
  }

  private authenticationRequiredError(): ApiException {
    return new ApiException(
      HttpStatus.UNAUTHORIZED,
      AUTH_ERROR_CODES.AUTHENTICATION_REQUIRED,
      'Authentication is required.',
    );
  }

  private invalidAccessTokenError(): ApiException {
    return new ApiException(
      HttpStatus.UNAUTHORIZED,
      AUTH_ERROR_CODES.INVALID_ACCESS_TOKEN,
      'Invalid or expired access token.',
    );
  }

  private userDisabledError(): ApiException {
    return new ApiException(HttpStatus.FORBIDDEN, AUTH_ERROR_CODES.USER_DISABLED, 'This account is disabled.');
  }
}
