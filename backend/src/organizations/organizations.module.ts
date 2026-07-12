import { Module } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { DatabaseModule } from '../database/database.module';
import { OrganizationsController } from './organizations.controller';
import { OrganizationsService } from './organizations.service';

@Module({
  imports: [DatabaseModule],
  controllers: [OrganizationsController],
  providers: [OrganizationsService, OrganizationMembershipGuard],
})
export class OrganizationsModule {}
