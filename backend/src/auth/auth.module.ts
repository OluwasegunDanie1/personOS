import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import { SecurityModule } from '../security/security.module';
import { AuthService } from './auth.service';

@Module({
  imports: [DatabaseModule, SecurityModule],
  providers: [AuthService],
  exports: [AuthService],
})
export class AuthModule {}
