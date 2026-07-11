import { HttpStatus, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { UserStatus } from '../../generated/prisma/client';
import { ApiException } from '../common/http/api-exception';
import { PrismaService } from '../database/prisma.service';
import { AccessTokenService } from '../security/access-token.service';
import { JWT_ACCESS_TOKEN_EXPIRY_SECONDS } from '../security/jwt.config';
import { OpaqueTokenService } from '../security/opaque-token.service';
import { PasswordHashService } from '../security/password-hash.service';
import { AUTH_ERROR_CODES, REFRESH_TOKEN_LIFETIME_MS } from './auth.constants';
import { LoginDto } from './dto/login.dto';
import { LogoutDto } from './dto/logout.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { PublicUser, toPublicUser } from './public-user';

interface LoginResult {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: PublicUser;
}

interface RefreshResult {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly accessTokenService: AccessTokenService,
    private readonly passwordHashService: PasswordHashService,
    private readonly opaqueTokenService: OpaqueTokenService,
  ) {}

  async login(dto: LoginDto): Promise<LoginResult> {
    const normalizedEmail = dto.email.trim().toLowerCase();

    const user = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });

    if (!user) {
      throw this.invalidCredentialsError();
    }

    const passwordValid = await this.passwordHashService.verify(user.passwordHash, dto.password);

    if (!passwordValid) {
      throw this.invalidCredentialsError();
    }

    if (user.status === UserStatus.DISABLED) {
      throw this.userDisabledError();
    }

    const rawRefreshToken = this.opaqueTokenService.generate();
    const refreshTokenHash = this.opaqueTokenService.hash(rawRefreshToken);
    // Internal refresh-family identifier, not an authentication token: must
    // be UUID-compatible for the RefreshToken.familyId @db.Uuid column.
    const familyId = randomUUID();

    const [updatedUser] = await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: user.id },
        data: { lastLogin: new Date() },
      }),
      this.prisma.refreshToken.create({
        data: {
          userId: user.id,
          tokenHash: refreshTokenHash,
          familyId,
          expiresAt: new Date(Date.now() + REFRESH_TOKEN_LIFETIME_MS),
        },
      }),
    ]);

    const accessToken = this.accessTokenService.sign(user.id);

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      expiresIn: JWT_ACCESS_TOKEN_EXPIRY_SECONDS,
      user: toPublicUser(updatedUser),
    };
  }

  async refresh(dto: RefreshTokenDto): Promise<RefreshResult> {
    const tokenHash = this.opaqueTokenService.hash(dto.refreshToken);

    const existingToken = await this.prisma.refreshToken.findUnique({ where: { tokenHash } });

    if (!existingToken) {
      throw this.invalidRefreshTokenError();
    }

    if (existingToken.expiresAt.getTime() < Date.now()) {
      throw this.invalidRefreshTokenError();
    }

    const user = await this.prisma.user.findUnique({ where: { id: existingToken.userId } });

    if (!user || user.status === UserStatus.DISABLED) {
      throw this.userDisabledError();
    }

    if (existingToken.revokedAt) {
      await this.prisma.refreshToken.updateMany({
        where: { familyId: existingToken.familyId, revokedAt: null },
        data: { revokedAt: new Date() },
      });

      throw this.invalidRefreshTokenError();
    }

    const newRawRefreshToken = this.opaqueTokenService.generate();
    const newTokenHash = this.opaqueTokenService.hash(newRawRefreshToken);

    await this.prisma.$transaction([
      this.prisma.refreshToken.update({
        where: { id: existingToken.id },
        data: { revokedAt: new Date() },
      }),
      this.prisma.refreshToken.create({
        data: {
          userId: existingToken.userId,
          tokenHash: newTokenHash,
          familyId: existingToken.familyId,
          expiresAt: new Date(Date.now() + REFRESH_TOKEN_LIFETIME_MS),
        },
      }),
    ]);

    const accessToken = this.accessTokenService.sign(user.id);

    return {
      accessToken,
      refreshToken: newRawRefreshToken,
      expiresIn: JWT_ACCESS_TOKEN_EXPIRY_SECONDS,
    };
  }

  async logout(dto: LogoutDto): Promise<void> {
    const tokenHash = this.opaqueTokenService.hash(dto.refreshToken);

    const existingToken = await this.prisma.refreshToken.findUnique({ where: { tokenHash } });

    if (!existingToken || existingToken.revokedAt) {
      return;
    }

    await this.prisma.refreshToken.update({
      where: { id: existingToken.id },
      data: { revokedAt: new Date() },
    });
  }

  private invalidCredentialsError(): ApiException {
    return new ApiException(
      HttpStatus.UNAUTHORIZED,
      AUTH_ERROR_CODES.INVALID_CREDENTIALS,
      'Invalid email or password.',
    );
  }

  private invalidRefreshTokenError(): ApiException {
    return new ApiException(
      HttpStatus.UNAUTHORIZED,
      AUTH_ERROR_CODES.INVALID_REFRESH_TOKEN,
      'Invalid or expired refresh token.',
    );
  }

  private userDisabledError(): ApiException {
    return new ApiException(HttpStatus.FORBIDDEN, AUTH_ERROR_CODES.USER_DISABLED, 'This account is disabled.');
  }
}
