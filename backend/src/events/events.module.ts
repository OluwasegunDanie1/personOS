import { Module } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { DatabaseModule } from '../database/database.module';
import { AttendanceService } from './attendance.service';
import { EventAttendanceController } from './event-attendance.controller';
import { EventsController } from './events.controller';
import { EventsService } from './events.service';
import { PersonAttendanceController } from './person-attendance.controller';

@Module({
  imports: [DatabaseModule],
  controllers: [EventsController, EventAttendanceController, PersonAttendanceController],
  providers: [EventsService, AttendanceService, OrganizationMembershipGuard],
})
export class EventsModule {}
