import { Controller, Get, Param, Query, Req, UseGuards } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { AttendanceService } from './attendance.service';
import { ListPersonAttendanceQueryDto } from './dto/list-person-attendance-query.dto';

@Controller('organizations/:organizationId/people/:personId/attendance')
@UseGuards(OrganizationMembershipGuard)
export class PersonAttendanceController {
  constructor(private readonly attendanceService: AttendanceService) {}

  @Get()
  list(
    @Req() request: AuthenticatedRequest,
    @Param('personId') personId: string,
    @Query() query: ListPersonAttendanceQueryDto,
  ) {
    return this.attendanceService.listForPerson(request.organization!.organizationId, personId, query);
  }
}
