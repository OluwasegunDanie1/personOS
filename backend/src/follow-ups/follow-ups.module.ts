import { Module } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { DatabaseModule } from '../database/database.module';
import { FollowUpsController } from './follow-ups.controller';
import { FollowUpsService } from './follow-ups.service';

@Module({
  imports: [DatabaseModule],
  controllers: [FollowUpsController],
  providers: [FollowUpsService, OrganizationMembershipGuard],
})
export class FollowUpsModule {}
