import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { DashboardService } from './dashboard.service';

@Controller('organizations/:organizationId/reports')
@UseGuards(OrganizationMembershipGuard)
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('dashboard')
  summary(@Req() request: AuthenticatedRequest) {
    // Uses the guard-validated organization context, never the raw path param.
    return this.dashboardService.summary(request.organization!.organizationId);
  }
}
