import { Module } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { DatabaseModule } from '../database/database.module';
import { DashboardController } from './dashboard.controller';
import { DashboardService } from './dashboard.service';

@Module({
  imports: [DatabaseModule],
  controllers: [DashboardController],
  providers: [DashboardService, OrganizationMembershipGuard],
})
export class DashboardModule {}
