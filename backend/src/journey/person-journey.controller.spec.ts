import { GUARDS_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { PersonJourneyController } from './person-journey.controller';
import { PersonJourneyService } from './person-journey.service';

const ORG_ID = '11111111-1111-1111-1111-111111111111';

function buildRequest(overrides: Partial<AuthenticatedRequest> = {}): AuthenticatedRequest {
  return {
    headers: {},
    params: { organizationId: ORG_ID, personId: 'person-1' },
    organization: { organizationId: ORG_ID, membershipId: 'membership-1', roleId: 'role-1' },
    auth: { userId: 'authenticated-user-id' },
    ...overrides,
  };
}

describe('PersonJourneyController', () => {
  let service: { view: jest.Mock; move: jest.Mock };
  let controller: PersonJourneyController;

  beforeEach(() => {
    service = {
      view: jest.fn().mockResolvedValue({ currentJourneyStage: null, history: [] }),
      move: jest.fn().mockResolvedValue({ movement: {} }),
    };
    controller = new PersonJourneyController(service as unknown as PersonJourneyService);
  });

  it('is registered under organizations/:organizationId/people/:personId/journey', () => {
    expect(Reflect.getMetadata(PATH_METADATA, PersonJourneyController)).toBe(
      'organizations/:organizationId/people/:personId/journey',
    );
  });

  it('applies OrganizationMembershipGuard at the controller level', () => {
    const guards = Reflect.getMetadata(GUARDS_METADATA, PersonJourneyController) as unknown[];

    expect(guards).toEqual([OrganizationMembershipGuard]);
  });

  it('view() uses request.organization.organizationId, never the raw path param', async () => {
    const request = buildRequest({ params: { organizationId: 'attacker-supplied-id', personId: 'person-1' } });

    await controller.view(request, 'person-1');

    expect(service.view).toHaveBeenCalledWith(ORG_ID, 'person-1');
  });

  it('move() uses request.auth.userId for attribution, never client-supplied movedBy', async () => {
    const request = buildRequest();
    const dto = { stageId: 'stage-1', movedBy: 'attacker-supplied-id' };

    await controller.move(request, 'person-1', dto as never);

    expect(service.move).toHaveBeenCalledWith(ORG_ID, 'person-1', 'authenticated-user-id', dto);
  });
});
