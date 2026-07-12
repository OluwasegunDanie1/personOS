import { Module } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { DatabaseModule } from '../database/database.module';
import { JourneyStagesController } from './journey-stages.controller';
import { JourneyStagesService } from './journey-stages.service';
import { OperationalTemplateService } from './operational-template.service';
import { PersonJourneyController } from './person-journey.controller';
import { PersonJourneyService } from './person-journey.service';

@Module({
  imports: [DatabaseModule],
  controllers: [JourneyStagesController, PersonJourneyController],
  providers: [
    JourneyStagesService,
    PersonJourneyService,
    OperationalTemplateService,
    OrganizationMembershipGuard,
  ],
})
export class JourneyModule {}
