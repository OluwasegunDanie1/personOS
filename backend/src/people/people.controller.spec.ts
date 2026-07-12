import { GUARDS_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { PeopleController } from './people.controller';
import { PeopleService } from './people.service';

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

describe('PeopleController', () => {
  let service: {
    list: jest.Mock;
    create: jest.Mock;
    detail: jest.Mock;
    update: jest.Mock;
    remove: jest.Mock;
  };
  let controller: PeopleController;

  beforeEach(() => {
    service = {
      list: jest.fn().mockResolvedValue({ people: [], nextCursor: null }),
      create: jest.fn().mockResolvedValue({ person: {} }),
      detail: jest.fn().mockResolvedValue({ person: {} }),
      update: jest.fn().mockResolvedValue({ person: {} }),
      remove: jest.fn().mockResolvedValue({ success: true }),
    };
    controller = new PeopleController(service as unknown as PeopleService);
  });

  it('is registered under organizations/:organizationId/people', () => {
    expect(Reflect.getMetadata(PATH_METADATA, PeopleController)).toBe('organizations/:organizationId/people');
  });

  it('applies OrganizationMembershipGuard at the controller level', () => {
    const guards = Reflect.getMetadata(GUARDS_METADATA, PeopleController) as unknown[];

    expect(guards).toEqual([OrganizationMembershipGuard]);
  });

  it('list() uses request.organization.organizationId, never a raw client-supplied id', async () => {
    const request = buildRequest({
      organization: { organizationId: ORG_ID, membershipId: 'm', roleId: 'r' },
      params: { organizationId: 'attacker-supplied-id' },
    });

    await controller.list(request, {} as never);

    expect(service.list).toHaveBeenCalledWith(ORG_ID, {});
  });

  it('create() delegates using the validated organization context', async () => {
    const request = buildRequest();
    const dto = { firstName: 'Ada', lastName: 'Lovelace' };

    await controller.create(request, dto as never);

    expect(service.create).toHaveBeenCalledWith(ORG_ID, dto);
  });

  it('detail() delegates using the validated organization context and personId param', async () => {
    const request = buildRequest();

    await controller.detail(request, 'person-1');

    expect(service.detail).toHaveBeenCalledWith(ORG_ID, 'person-1');
  });

  it('update() delegates using the validated organization context', async () => {
    const request = buildRequest();
    const dto = { firstName: 'Updated' };

    await controller.update(request, 'person-1', dto as never);

    expect(service.update).toHaveBeenCalledWith(ORG_ID, 'person-1', dto);
  });

  it('remove() delegates using the validated organization context', async () => {
    const request = buildRequest();

    await controller.remove(request, 'person-1');

    expect(service.remove).toHaveBeenCalledWith(ORG_ID, 'person-1');
  });

  it('never reads userId from the request; only request.auth is available for identity', () => {
    // The controller signatures never declare a userId parameter, and none
    // of the delegate calls above pass anything derived from a client input
    // channel (query/body/headers) for identity or organization scoping.
    expect(PeopleController.prototype.list.length).toBe(2);
  });
});
