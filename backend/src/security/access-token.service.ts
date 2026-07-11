import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { JWT_ALGORITHM, JWT_AUDIENCE, JWT_ISSUER } from './jwt.config';

interface AccessTokenPayload {
  sub: string;
}

@Injectable()
export class AccessTokenService {
  constructor(private readonly jwtService: JwtService) {}

  sign(userId: string): string {
    const payload: AccessTokenPayload = { sub: userId };
    return this.jwtService.sign(payload);
  }

  /**
   * Verifies a token against the approved algorithm, issuer, and audience.
   * These are not automatically re-applied by JwtService.verifyAsync from
   * the sign-time configuration, so they must be passed explicitly here.
   */
  async verify(token: string): Promise<AccessTokenPayload> {
    return this.jwtService.verifyAsync<AccessTokenPayload>(token, {
      algorithms: [JWT_ALGORITHM],
      issuer: JWT_ISSUER,
      audience: JWT_AUDIENCE,
    });
  }
}
