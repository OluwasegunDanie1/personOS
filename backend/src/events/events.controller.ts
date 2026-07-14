import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { CreateEventDto } from './dto/create-event.dto';
import { ListEventsQueryDto } from './dto/list-events-query.dto';
import { UpdateEventDto } from './dto/update-event.dto';
import { EventsService } from './events.service';

@Controller('organizations/:organizationId/events')
@UseGuards(OrganizationMembershipGuard)
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  @Get()
  list(@Req() request: AuthenticatedRequest, @Query() query: ListEventsQueryDto) {
    // Uses the guard-validated organization context, never the raw path param.
    return this.eventsService.list(request.organization!.organizationId, query);
  }

  @Post()
  create(@Req() request: AuthenticatedRequest, @Body() dto: CreateEventDto) {
    return this.eventsService.create(request.organization!.organizationId, request.auth!.userId, dto);
  }

  @Get(':eventId')
  detail(@Req() request: AuthenticatedRequest, @Param('eventId') eventId: string) {
    return this.eventsService.detail(request.organization!.organizationId, eventId);
  }

  @Patch(':eventId')
  update(@Req() request: AuthenticatedRequest, @Param('eventId') eventId: string, @Body() dto: UpdateEventDto) {
    return this.eventsService.update(request.organization!.organizationId, eventId, dto);
  }

  @Delete(':eventId')
  remove(@Req() request: AuthenticatedRequest, @Param('eventId') eventId: string) {
    return this.eventsService.remove(request.organization!.organizationId, eventId);
  }

  @Post(':eventId/cancel')
  @HttpCode(HttpStatus.OK)
  cancel(@Req() request: AuthenticatedRequest, @Param('eventId') eventId: string) {
    return this.eventsService.cancel(request.organization!.organizationId, eventId);
  }
}
