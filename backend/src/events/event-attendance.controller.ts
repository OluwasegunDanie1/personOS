import { Body, Controller, Get, HttpStatus, Param, Post, Query, Req, Res, UseGuards } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { AttendanceService } from './attendance.service';
import { ListEventAttendanceQueryDto } from './dto/list-event-attendance-query.dto';
import { RecordAttendanceDto } from './dto/record-attendance.dto';

/**
 * Minimal response surface for setting a dynamic status code (201 on first
 * write, 200 on idempotent replay) before Nest's normal interceptor/envelope
 * pipeline serializes the returned body. Avoids an @types/express dependency,
 * mirroring common/http/global-exception.filter.ts's HttpResponseLike.
 */
interface MinimalResponse {
  status(code: number): MinimalResponse;
}

@Controller('organizations/:organizationId/events/:eventId/attendance')
@UseGuards(OrganizationMembershipGuard)
export class EventAttendanceController {
  constructor(private readonly attendanceService: AttendanceService) {}

  @Get()
  list(
    @Req() request: AuthenticatedRequest,
    @Param('eventId') eventId: string,
    @Query() query: ListEventAttendanceQueryDto,
  ) {
    return this.attendanceService.listForEvent(request.organization!.organizationId, eventId, query);
  }

  @Post()
  async record(
    @Req() request: AuthenticatedRequest,
    @Res({ passthrough: true }) response: MinimalResponse,
    @Param('eventId') eventId: string,
    @Body() dto: RecordAttendanceDto,
  ) {
    const result = await this.attendanceService.record(
      request.organization!.organizationId,
      eventId,
      request.auth!.userId,
      dto,
    );

    response.status(result.created ? HttpStatus.CREATED : HttpStatus.OK);

    return { attendance: result.attendance };
  }
}
