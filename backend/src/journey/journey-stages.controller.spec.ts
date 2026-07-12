import { GUARDS_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { JourneyStagesController } from './journey-stages.controller';
import { JourneyStagesService } from './journey-stages.service';

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

describe('JourneyStagesController', () => {
  let service: {
    list: jest.Mock;
    create: jest.Mock;
    update: jest.Mock;
    reorder: jest.Mock;
    remove: jest.Mock;
  };
  let controller: JourneyStagesController;

  beforeEach(() => {
    service = {
      list: jest.fn().mockResolvedValue({ stages: [] }),
      create: jest.fn().mockResolvedValue({ stage: {} }),
      update: jest.fn().mockResolvedValue({ stage: {} }),
      reorder: jest.fn().mockResolvedValue({ stages: [] }),
      remove: jest.fn().mockResolvedValue({ success: true }),
    };
    controller = new JourneyStagesController(service as unknown as JourneyStagesService);
  });

  it('is registered under organizations/:organizationId/journey-stages', () => {
    expect(Reflect.getMetadata(PATH_METADATA, JourneyStagesController)).toBe(
      'organizations/:organizationId/journey-stages',
    );
  });

  it('applies OrganizationMembershipGuard at the controller level', () => {
    const guards = Reflect.getMetadata(GUARDS_METADATA, JourneyStagesController) as unknown[];

    expect(guards).toEqual([OrganizationMembershipGuard]);
  });

  it('list() uses request.organization.organizationId, never the raw path param', async () => {
    const request = buildRequest({ params: { organizationId: 'attacker-supplied-id' } });

    await controller.list(request);

    expect(service.list).toHaveBeenCalledWith(ORG_ID);
  });

  it('create() delegates using the validated organization context', async () => {
    const request = buildRequest();
    const dto = { name: 'Visitor' };

    await controller.create(request, dto as never);

    expect(service.create).toHaveBeenCalledWith(ORG_ID, dto);
  });

  it('reorder() delegates using the validated organization context', async () => {
    const request = buildRequest();
    const dto = { stageIds: ['a', 'b'] };

    await controller.reorder(request, dto as never);

    expect(service.reorder).toHaveBeenCalledWith(ORG_ID, dto);
  });

  it('update() delegates using the validated organization context and stageId param', async () => {
    const request = buildRequest();
    const dto = { name: 'New' };

    await controller.update(request, 'stage-1', dto as never);

    expect(service.update).toHaveBeenCalledWith(ORG_ID, 'stage-1', dto);
  });

  it('remove() delegates using the validated organization context', async () => {
    const request = buildRequest();

    await controller.remove(request, 'stage-1');

    expect(service.remove).toHaveBeenCalledWith(ORG_ID, 'stage-1');
  });
});
