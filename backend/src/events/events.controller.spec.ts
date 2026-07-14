import { GUARDS_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { EventsController } from './events.controller';
import { EventsService } from './events.service';

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

describe('EventsController', () => {
  let service: {
    list: jest.Mock;
    create: jest.Mock;
    detail: jest.Mock;
    update: jest.Mock;
    remove: jest.Mock;
    cancel: jest.Mock;
  };
  let controller: EventsController;

  beforeEach(() => {
    service = {
      list: jest.fn().mockResolvedValue({ events: [], nextCursor: null }),
      create: jest.fn().mockResolvedValue({ event: {} }),
      detail: jest.fn().mockResolvedValue({ event: {} }),
      update: jest.fn().mockResolvedValue({ event: {} }),
      remove: jest.fn().mockResolvedValue({ success: true }),
      cancel: jest.fn().mockResolvedValue({ event: {} }),
    };
    controller = new EventsController(service as unknown as EventsService);
  });

  it('is registered under organizations/:organizationId/events', () => {
    expect(Reflect.getMetadata(PATH_METADATA, EventsController)).toBe('organizations/:organizationId/events');
  });

  it('applies OrganizationMembershipGuard at the controller level', () => {
    const guards = Reflect.getMetadata(GUARDS_METADATA, EventsController) as unknown[];
    expect(guards).toEqual([OrganizationMembershipGuard]);
  });

  it('list() uses request.organization.organizationId, never the raw path param', async () => {
    const request = buildRequest({ params: { organizationId: 'attacker-supplied-id' } });

    await controller.list(request, {});

    expect(service.list).toHaveBeenCalledWith(ORG_ID, {});
  });

  it('create() derives organizationId and createdBy from validated context, never client input', async () => {
    const request = buildRequest();
    const dto = { title: 'Sunday Service', startDate: '2026-08-02T09:00:00Z' };

    await controller.create(request, dto as never);

    expect(service.create).toHaveBeenCalledWith(ORG_ID, 'user-1', dto);
  });

  it('detail() delegates using the validated organization context', async () => {
    const request = buildRequest();

    await controller.detail(request, 'event-1');

    expect(service.detail).toHaveBeenCalledWith(ORG_ID, 'event-1');
  });

  it('update() delegates using the validated organization context and eventId param', async () => {
    const request = buildRequest();
    const dto = { title: 'New' };

    await controller.update(request, 'event-1', dto as never);

    expect(service.update).toHaveBeenCalledWith(ORG_ID, 'event-1', dto);
  });

  it('remove() delegates using the validated organization context', async () => {
    const request = buildRequest();

    await controller.remove(request, 'event-1');

    expect(service.remove).toHaveBeenCalledWith(ORG_ID, 'event-1');
  });

  it('cancel() delegates using the validated organization context', async () => {
    const request = buildRequest();

    await controller.cancel(request, 'event-1');

    expect(service.cancel).toHaveBeenCalledWith(ORG_ID, 'event-1');
  });
});
