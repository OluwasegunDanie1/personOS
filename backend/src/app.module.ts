import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { AuthModule } from './auth/auth.module';
import { AccessTokenGuard } from './common/guards/access-token.guard';
import { DatabaseModule } from './database/database.module';
import { SecurityModule } from './security/security.module';

@Module({
  imports: [DatabaseModule, SecurityModule, AuthModule],
  providers: [{ provide: APP_GUARD, useClass: AccessTokenGuard }],
})
export class AppModule {}
