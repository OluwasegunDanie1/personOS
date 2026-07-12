import { Controller, Get, Req } from '@nestjs/common';
import { AuthenticatedRequest } from '../common/http/request-context';
import { OrganizationListResult, OrganizationsService } from './organizations.service';

@Controller('organizations')
export class OrganizationsController {
  constructor(private readonly organizationsService: OrganizationsService) {}

  @Get()
  list(@Req() request: AuthenticatedRequest): Promise<OrganizationListResult> {
    // Not marked @Public(): the global AccessTokenGuard guarantees request.auth
    // is populated before this handler runs.
    return this.organizationsService.listForUser(request.auth!.userId);
  }
}
