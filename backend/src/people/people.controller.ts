import { Body, Controller, Delete, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { CreatePersonDto } from './dto/create-person.dto';
import { ListPeopleQueryDto } from './dto/list-people-query.dto';
import { UpdatePersonDto } from './dto/update-person.dto';
import { PeopleService } from './people.service';

@Controller('organizations/:organizationId/people')
@UseGuards(OrganizationMembershipGuard)
export class PeopleController {
  constructor(private readonly peopleService: PeopleService) {}

  @Get()
  list(@Req() request: AuthenticatedRequest, @Query() query: ListPeopleQueryDto) {
    // Uses the guard-validated organization context, never the raw path param.
    return this.peopleService.list(request.organization!.organizationId, query);
  }

  @Post()
  create(@Req() request: AuthenticatedRequest, @Body() dto: CreatePersonDto) {
    return this.peopleService.create(request.organization!.organizationId, dto);
  }

  @Get(':personId')
  detail(@Req() request: AuthenticatedRequest, @Param('personId') personId: string) {
    return this.peopleService.detail(request.organization!.organizationId, personId);
  }

  @Patch(':personId')
  update(
    @Req() request: AuthenticatedRequest,
    @Param('personId') personId: string,
    @Body() dto: UpdatePersonDto,
  ) {
    return this.peopleService.update(request.organization!.organizationId, personId, dto);
  }

  @Delete(':personId')
  remove(@Req() request: AuthenticatedRequest, @Param('personId') personId: string) {
    return this.peopleService.remove(request.organization!.organizationId, personId);
  }
}
