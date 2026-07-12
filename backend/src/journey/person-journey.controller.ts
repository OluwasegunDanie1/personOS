import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { MovePersonDto } from './dto/move-person.dto';
import { PersonJourneyService } from './person-journey.service';

@Controller('organizations/:organizationId/people/:personId/journey')
@UseGuards(OrganizationMembershipGuard)
export class PersonJourneyController {
  constructor(private readonly personJourneyService: PersonJourneyService) {}

  @Get()
  view(@Req() request: AuthenticatedRequest, @Param('personId') personId: string) {
    return this.personJourneyService.view(request.organization!.organizationId, personId);
  }

  @Post('transitions')
  move(
    @Req() request: AuthenticatedRequest,
    @Param('personId') personId: string,
    @Body() dto: MovePersonDto,
  ) {
    return this.personJourneyService.move(
      request.organization!.organizationId,
      personId,
      request.auth!.userId,
      dto,
    );
  }
}
