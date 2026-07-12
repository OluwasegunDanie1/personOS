import { Body, Controller, Get, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { CreateOrganizationDto } from './dto/create-organization.dto';
import { UpdateOrganizationDto } from './dto/update-organization.dto';
import { OrganizationDetail, OrganizationListResult, OrganizationsService } from './organizations.service';

@Controller('organizations')
export class OrganizationsController {
  constructor(private readonly organizationsService: OrganizationsService) {}

  @Get()
  list(@Req() request: AuthenticatedRequest): Promise<OrganizationListResult> {
    // Not marked @Public(): the global AccessTokenGuard guarantees request.auth
    // is populated before this handler runs.
    return this.organizationsService.listForUser(request.auth!.userId);
  }

  @Post()
  create(
    @Req() request: AuthenticatedRequest,
    @Body() dto: CreateOrganizationDto,
  ): Promise<{ organization: OrganizationDetail }> {
    // No OrganizationMembershipGuard: the target Organization does not exist
    // yet. Only the global AccessTokenGuard applies. The creator identity is
    // always request.auth.userId, never client-supplied.
    return this.organizationsService.create(request.auth!.userId, dto);
  }

  @Get(':organizationId')
  @UseGuards(OrganizationMembershipGuard)
  detail(@Req() request: AuthenticatedRequest): Promise<{ organization: OrganizationDetail }> {
    return this.organizationsService.detail(request.organization!.organizationId);
  }

  @Patch(':organizationId')
  @UseGuards(OrganizationMembershipGuard)
  update(
    @Req() request: AuthenticatedRequest,
    @Body() dto: UpdateOrganizationDto,
  ): Promise<{ organization: OrganizationDetail }> {
    return this.organizationsService.update(request.organization!.organizationId, dto);
  }
}
