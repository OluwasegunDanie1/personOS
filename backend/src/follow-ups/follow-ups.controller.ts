import { Body, Controller, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { CreateFollowUpDto } from './dto/create-follow-up.dto';
import { ListFollowUpsQueryDto } from './dto/list-follow-ups-query.dto';
import { UpdateFollowUpDto } from './dto/update-follow-up.dto';
import { FollowUpsService } from './follow-ups.service';

@Controller('organizations/:organizationId/follow-ups')
@UseGuards(OrganizationMembershipGuard)
export class FollowUpsController {
  constructor(private readonly followUpsService: FollowUpsService) {}

  @Get()
  list(@Req() request: AuthenticatedRequest, @Query() query: ListFollowUpsQueryDto) {
    // Uses the guard-validated organization context, never the raw path param.
    return this.followUpsService.list(request.organization!.organizationId, query);
  }

  @Post()
  create(@Req() request: AuthenticatedRequest, @Body() dto: CreateFollowUpDto) {
    return this.followUpsService.create(request.organization!.organizationId, dto);
  }

  @Get(':followUpId')
  detail(@Req() request: AuthenticatedRequest, @Param('followUpId') followUpId: string) {
    return this.followUpsService.detail(request.organization!.organizationId, followUpId);
  }

  @Patch(':followUpId')
  update(
    @Req() request: AuthenticatedRequest,
    @Param('followUpId') followUpId: string,
    @Body() dto: UpdateFollowUpDto,
  ) {
    return this.followUpsService.update(request.organization!.organizationId, followUpId, dto);
  }

  @Patch(':followUpId/complete')
  complete(@Req() request: AuthenticatedRequest, @Param('followUpId') followUpId: string) {
    return this.followUpsService.complete(request.organization!.organizationId, followUpId);
  }
}
