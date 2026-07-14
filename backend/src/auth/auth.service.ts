import { HttpStatus, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { UserStatus } from '../../generated/prisma/client';
import { ApiException } from '../common/http/api-exception';
import { PrismaService } from '../database/prisma.service';
import { AccessTokenService } from '../security/access-token.service';
import { JWT_ACCESS_TOKEN_EXPIRY_SECONDS } from '../security/jwt.config';
import { OpaqueTokenService } from '../security/opaque-token.service';
import { PasswordHashService } from '../security/password-hash.service';
import {
  AUTH_ERROR_CODES,
  FORGOT_PASSWORD_MESSAGE,
  PASSWORD_RESET_TOKEN_LIFETIME_MS,
  REFRESH_TOKEN_LIFETIME_MS,
} from './auth.constants';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { LoginDto } from './dto/login.dto';
import { LogoutDto } from './dto/logout.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
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

interface RegisterResult {
  user: PublicUser;
}

interface ForgotPasswordResult {
  message: string;
  developmentResetToken?: string;
}

interface MeResult {
  user: PublicUser;
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

  /**
   * Creates exactly one ACTIVE User. Never auto-creates an Organization,
   * Role, or Membership — organization context selection remains its own
   * separate, explicit workflow (mirroring Login's own established
   * separation). Never auto-logs in: the client calls Login afterward to
   * obtain tokens, matching this endpoint's minimal approved scope.
   */
  async register(dto: RegisterDto): Promise<RegisterResult> {
    const normalizedEmail = dto.email.trim().toLowerCase();

    const existing = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });

    if (existing) {
      throw this.emailAlreadyRegisteredError();
    }

    const passwordHash = await this.passwordHashService.hash(dto.password);

    const created = await this.prisma.user.create({
      data: {
        firstName: dto.firstName,
        lastName: dto.lastName,
        email: normalizedEmail,
        passwordHash,
        status: UserStatus.ACTIVE,
      },
    });

    return { user: toPublicUser(created) };
  }

  /**
   * Always returns the same non-disclosing message regardless of whether
   * the email resolves to a real User — an unknown email creates no token
   * and produces an identical response. Outside production only, the raw
   * reset token is additionally returned as developmentResetToken so the
   * flow is truthfully testable without pretending an email was sent;
   * production never exposes it, matching this repository's existing
   * NODE_ENV-gated dev-only conventions (see security/trust-proxy.config.ts).
   */
  async forgotPassword(dto: ForgotPasswordDto): Promise<ForgotPasswordResult> {
    const normalizedEmail = dto.email.trim().toLowerCase();

    const user = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });

    if (!user) {
      return { message: FORGOT_PASSWORD_MESSAGE };
    }

    const rawToken = this.opaqueTokenService.generate();
    const tokenHash = this.opaqueTokenService.hash(rawToken);

    await this.prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        tokenHash,
        expiresAt: new Date(Date.now() + PASSWORD_RESET_TOKEN_LIFETIME_MS),
      },
    });

    if (process.env.NODE_ENV !== 'production') {
      return { message: FORGOT_PASSWORD_MESSAGE, developmentResetToken: rawToken };
    }

    return { message: FORGOT_PASSWORD_MESSAGE };
  }

  /**
   * Single-use, concurrency-safe: the conditional updateMany below only
   * ever matches a still-unused row, so two concurrent requests replaying
   * the same raw token can never both succeed — the loser's WHERE clause
   * matches zero rows once the winner's UPDATE commits, and it is rejected
   * exactly like an already-used token. On success, the password change
   * and revocation of every other active session are committed together.
   */
  async resetPassword(dto: ResetPasswordDto): Promise<{ success: true }> {
    const tokenHash = this.opaqueTokenService.hash(dto.token);

    const resetToken = await this.prisma.passwordResetToken.findUnique({ where: { tokenHash } });

    if (!resetToken || resetToken.usedAt || resetToken.expiresAt.getTime() < Date.now()) {
      throw this.invalidResetTokenError();
    }

    const newPasswordHash = await this.passwordHashService.hash(dto.newPassword);

    const claimed = await this.prisma.passwordResetToken.updateMany({
      where: { id: resetToken.id, usedAt: null },
      data: { usedAt: new Date() },
    });

    if (claimed.count !== 1) {
      throw this.invalidResetTokenError();
    }

    await this.prisma.$transaction([
      this.prisma.user.update({ where: { id: resetToken.userId }, data: { passwordHash: newPasswordHash } }),
      this.prisma.refreshToken.updateMany({
        where: { userId: resetToken.userId, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
    ]);

    return { success: true };
  }

  /**
   * AccessTokenGuard already guarantees the caller resolves to an existing,
   * non-deleted, non-DISABLED User by the time this runs, but only selected
   * a narrow field set for that check — the full row is re-fetched here for
   * the complete PublicUser shape. No organization-context field is
   * included: no server-side "active organization" is ever persisted
   * anywhere in this backend (it is a Flutter-local-only concept), so there
   * is no existing approved convention to reuse and none is invented here.
   */
  async me(userId: string): Promise<MeResult> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });

    if (!user) {
      throw this.invalidAccessTokenError();
    }

    return { user: toPublicUser(user) };
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

  private emailAlreadyRegisteredError(): ApiException {
    return new ApiException(
      HttpStatus.CONFLICT,
      AUTH_ERROR_CODES.EMAIL_ALREADY_REGISTERED,
      'An account with this email already exists.',
    );
  }

  private invalidResetTokenError(): ApiException {
    return new ApiException(
      HttpStatus.UNAUTHORIZED,
      AUTH_ERROR_CODES.INVALID_RESET_TOKEN,
      'Invalid or expired reset token.',
    );
  }

  private invalidAccessTokenError(): ApiException {
    return new ApiException(
      HttpStatus.UNAUTHORIZED,
      AUTH_ERROR_CODES.INVALID_ACCESS_TOKEN,
      'Invalid or expired access token.',
    );
  }
}
