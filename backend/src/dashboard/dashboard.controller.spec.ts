import { GUARDS_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { DashboardController } from './dashboard.controller';
import { DashboardService } from './dashboard.service';

const ORG_ID = '11111111-1111-1111-1111-111111111111';

function buildRequest(overrides: Partial<AuthenticatedRequest> = {}): AuthenticatedRequest {
  return {
    headers: {},
    params: { organizationId: ORG_ID },
    organization: { organizationId: ORG_ID, membershipId: 'membership-1', roleId: 'role-1' },
    auth: { userId: 'user-1' },
    ...overrides,
  };
}

describe('DashboardController', () => {
  let service: { summary: jest.Mock };
  let controller: DashboardController;

  beforeEach(() => {
    service = {
      summary: jest.fn().mockResolvedValue({ totalPeople: 0, newPeople: 0, pendingFollowUps: 0, upcomingEvents: [] }),
    };
    controller = new DashboardController(service as unknown as DashboardService);
  });

  it('is registered under organizations/:organizationId/reports', () => {
    expect(Reflect.getMetadata(PATH_METADATA, DashboardController)).toBe('organizations/:organizationId/reports');
  });

  it('applies OrganizationMembershipGuard at the controller level', () => {
    const guards = Reflect.getMetadata(GUARDS_METADATA, DashboardController) as unknown[];
    expect(guards).toEqual([OrganizationMembershipGuard]);
  });

  it('exposes only the dashboard summary handler (no report/export methods)', () => {
    const prototype = Object.getPrototypeOf(controller) as Record<string, unknown>;
    const methodNames = Object.getOwnPropertyNames(prototype).filter((name) => name !== 'constructor');
    expect(methodNames).toEqual(['summary']);
  });

  it('summary() uses request.organization.organizationId, never the raw path param', async () => {
    const request = buildRequest({ params: { organizationId: 'attacker-supplied-id' } });

    await controller.summary(request);

    expect(service.summary).toHaveBeenCalledWith(ORG_ID);
  });
});
