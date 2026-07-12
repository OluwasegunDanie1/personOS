import { Module } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { DatabaseModule } from '../database/database.module';
import { PeopleController } from './people.controller';
import { PeopleService } from './people.service';

@Module({
  imports: [DatabaseModule],
  controllers: [PeopleController],
  providers: [PeopleService, OrganizationMembershipGuard],
})
export class PeopleModule {}
