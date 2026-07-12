import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { CreateStageDto } from './dto/create-stage.dto';
import { ReorderStagesDto } from './dto/reorder-stages.dto';
import { UpdateStageDto } from './dto/update-stage.dto';
import { JourneyStagesService } from './journey-stages.service';

@Controller('organizations/:organizationId/journey-stages')
@UseGuards(OrganizationMembershipGuard)
export class JourneyStagesController {
  constructor(private readonly journeyStagesService: JourneyStagesService) {}

  @Get()
  list(@Req() request: AuthenticatedRequest) {
    return this.journeyStagesService.list(request.organization!.organizationId);
  }

  @Post()
  create(@Req() request: AuthenticatedRequest, @Body() dto: CreateStageDto) {
    return this.journeyStagesService.create(request.organization!.organizationId, dto);
  }

  @Post('reorder')
  @HttpCode(HttpStatus.OK)
  reorder(@Req() request: AuthenticatedRequest, @Body() dto: ReorderStagesDto) {
    return this.journeyStagesService.reorder(request.organization!.organizationId, dto);
  }

  @Patch(':stageId')
  update(
    @Req() request: AuthenticatedRequest,
    @Param('stageId') stageId: string,
    @Body() dto: UpdateStageDto,
  ) {
    return this.journeyStagesService.update(request.organization!.organizationId, stageId, dto);
  }

  @Delete(':stageId')
  remove(@Req() request: AuthenticatedRequest, @Param('stageId') stageId: string) {
    return this.journeyStagesService.remove(request.organization!.organizationId, stageId);
  }
}
