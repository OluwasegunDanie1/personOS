import { Controller, Get, Param, Query, Req, UseGuards } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { AttendanceService } from './attendance.service';
import { ListPersonAttendanceQueryDto } from './dto/list-person-attendance-query.dto';

@Controller('organizations/:organizationId/people/:personId/attendance')
@UseGuards(OrganizationMembershipGuard)
export class PersonAttendanceController {
  constructor(private readonly attendanceService: AttendanceService) {}

  // Registered before the base list() route: a static literal segment
  // ('summary') is matched independently of the parameterless base path,
  // but declaring the more specific route first follows the project's
  // static-before-dynamic routing convention.
  @Get('summary')
  summary(@Req() request: AuthenticatedRequest, @Param('personId') personId: string) {
    return this.attendanceService.summaryForPerson(request.organization!.organizationId, personId);
  }

  @Get()
  list(
    @Req() request: AuthenticatedRequest,
    @Param('personId') personId: string,
    @Query() query: ListPersonAttendanceQueryDto,
  ) {
    return this.attendanceService.listForPerson(request.organization!.organizationId, personId, query);
  }
}
