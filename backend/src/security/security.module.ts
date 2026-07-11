import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { AccessTokenService } from './access-token.service';
import {
  JWT_ALGORITHM,
  JWT_ACCESS_TOKEN_EXPIRY_SECONDS,
  JWT_AUDIENCE,
  JWT_ISSUER,
  getJwtAccessSecret,
} from './jwt.config';
import { OpaqueTokenService } from './opaque-token.service';
import { PasswordHashService } from './password-hash.service';

@Module({
  imports: [
    JwtModule.registerAsync({
      useFactory: () => ({
        secret: getJwtAccessSecret(),
        signOptions: {
          algorithm: JWT_ALGORITHM,
          expiresIn: JWT_ACCESS_TOKEN_EXPIRY_SECONDS,
          issuer: JWT_ISSUER,
          audience: JWT_AUDIENCE,
        },
      }),
    }),
  ],
  providers: [AccessTokenService, PasswordHashService, OpaqueTokenService],
  exports: [AccessTokenService, PasswordHashService, OpaqueTokenService],
})
export class SecurityModule {}
