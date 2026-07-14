import { Controller, Delete, Get, Param, Patch, Query, Req, UseGuards } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { ListNotificationsQueryDto } from './dto/list-notifications-query.dto';
import { NotificationsService } from './notifications.service';

@Controller('organizations/:organizationId/notifications')
@UseGuards(OrganizationMembershipGuard)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  list(@Req() request: AuthenticatedRequest, @Query() query: ListNotificationsQueryDto) {
    // Uses the guard-validated organization context and the authenticated
    // caller's own userId, never the raw path param nor another user's id.
    return this.notificationsService.list(request.organization!.organizationId, request.auth!.userId, query);
  }

  // Declared before ':notificationId/read' below only for readability —
  // segment counts differ (one segment vs two), so there is no routing
  // ambiguity between them regardless of declaration order.
  @Patch('read-all')
  markAllRead(@Req() request: AuthenticatedRequest) {
    return this.notificationsService.markAllRead(request.organization!.organizationId, request.auth!.userId);
  }

  @Patch(':notificationId/read')
  markRead(@Req() request: AuthenticatedRequest, @Param('notificationId') notificationId: string) {
    return this.notificationsService.markRead(
      request.organization!.organizationId,
      request.auth!.userId,
      notificationId,
    );
  }

  @Delete('read')
  clearRead(@Req() request: AuthenticatedRequest) {
    return this.notificationsService.clearRead(request.organization!.organizationId, request.auth!.userId);
  }
}
