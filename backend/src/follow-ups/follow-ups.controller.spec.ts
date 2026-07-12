import { GUARDS_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { FollowUpsController } from './follow-ups.controller';
import { FollowUpsService } from './follow-ups.service';

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

describe('FollowUpsController', () => {
  let service: {
    list: jest.Mock;
    create: jest.Mock;
    detail: jest.Mock;
    update: jest.Mock;
    complete: jest.Mock;
  };
  let controller: FollowUpsController;

  beforeEach(() => {
    service = {
      list: jest.fn().mockResolvedValue({ followUps: [], nextCursor: null }),
      create: jest.fn().mockResolvedValue({ followUp: {} }),
      detail: jest.fn().mockResolvedValue({ followUp: {} }),
      update: jest.fn().mockResolvedValue({ followUp: {} }),
      complete: jest.fn().mockResolvedValue({ followUp: {} }),
    };
    controller = new FollowUpsController(service as unknown as FollowUpsService);
  });

  it('is registered under organizations/:organizationId/follow-ups', () => {
    expect(Reflect.getMetadata(PATH_METADATA, FollowUpsController)).toBe(
      'organizations/:organizationId/follow-ups',
    );
  });

  it('applies OrganizationMembershipGuard at the controller level', () => {
    const guards = Reflect.getMetadata(GUARDS_METADATA, FollowUpsController) as unknown[];
    expect(guards).toEqual([OrganizationMembershipGuard]);
  });

  it('has no remove()/delete method (no Delete Follow-Up route exists)', () => {
    expect((controller as unknown as Record<string, unknown>).remove).toBeUndefined();
    expect((controller as unknown as Record<string, unknown>).delete).toBeUndefined();
  });

  it('list() uses request.organization.organizationId, never the raw path param', async () => {
    const request = buildRequest({ params: { organizationId: 'attacker-supplied-id' } });

    await controller.list(request, {});

    expect(service.list).toHaveBeenCalledWith(ORG_ID, {});
  });

  it('create() delegates using the validated organization context', async () => {
    const request = buildRequest();
    const dto = { personId: 'person-1', title: 'Call Ada' };

    await controller.create(request, dto as never);

    expect(service.create).toHaveBeenCalledWith(ORG_ID, dto);
  });

  it('detail() delegates using the validated organization context', async () => {
    const request = buildRequest();

    await controller.detail(request, 'follow-up-1');

    expect(service.detail).toHaveBeenCalledWith(ORG_ID, 'follow-up-1');
  });

  it('update() delegates using the validated organization context and followUpId param', async () => {
    const request = buildRequest();
    const dto = { title: 'New' };

    await controller.update(request, 'follow-up-1', dto as never);

    expect(service.update).toHaveBeenCalledWith(ORG_ID, 'follow-up-1', dto);
  });

  it('complete() delegates using the validated organization context', async () => {
    const request = buildRequest();

    await controller.complete(request, 'follow-up-1');

    expect(service.complete).toHaveBeenCalledWith(ORG_ID, 'follow-up-1');
  });
});
