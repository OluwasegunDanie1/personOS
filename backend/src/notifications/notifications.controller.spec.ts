import { GUARDS_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';

const ORG_ID = '11111111-1111-1111-1111-111111111111';
const USER_ID = '22222222-2222-2222-2222-222222222222';

function buildRequest(overrides: Partial<AuthenticatedRequest> = {}): AuthenticatedRequest {
  return {
    headers: {},
    params: { organizationId: ORG_ID },
    organization: { organizationId: ORG_ID, membershipId: 'membership-1', roleId: 'role-1' },
    auth: { userId: USER_ID },
    ...overrides,
  };
}

describe('NotificationsController', () => {
  let service: {
    list: jest.Mock;
    markRead: jest.Mock;
    markAllRead: jest.Mock;
    clearRead: jest.Mock;
  };
  let controller: NotificationsController;

  beforeEach(() => {
    service = {
      list: jest.fn().mockResolvedValue({ notifications: [], nextCursor: null }),
      markRead: jest.fn().mockResolvedValue({ notification: {} }),
      markAllRead: jest.fn().mockResolvedValue({ markedCount: 0 }),
      clearRead: jest.fn().mockResolvedValue({ clearedCount: 0 }),
    };
    controller = new NotificationsController(service as unknown as NotificationsService);
  });

  it('is registered under organizations/:organizationId/notifications', () => {
    expect(Reflect.getMetadata(PATH_METADATA, NotificationsController)).toBe(
      'organizations/:organizationId/notifications',
    );
  });

  it('applies OrganizationMembershipGuard at the controller level', () => {
    const guards = Reflect.getMetadata(GUARDS_METADATA, NotificationsController) as unknown[];
    expect(guards).toEqual([OrganizationMembershipGuard]);
  });

  it('list() uses request.organization.organizationId and request.auth.userId, never the raw path param', async () => {
    const request = buildRequest({ params: { organizationId: 'attacker-supplied-id' } });

    await controller.list(request, {});

    expect(service.list).toHaveBeenCalledWith(ORG_ID, USER_ID, {});
  });

  it('markRead() delegates using the validated organization context, authenticated userId, and notificationId param', async () => {
    const request = buildRequest();

    await controller.markRead(request, 'notif-1');

    expect(service.markRead).toHaveBeenCalledWith(ORG_ID, USER_ID, 'notif-1');
  });

  it('markAllRead() delegates using the validated organization context and authenticated userId', async () => {
    const request = buildRequest();

    await controller.markAllRead(request);

    expect(service.markAllRead).toHaveBeenCalledWith(ORG_ID, USER_ID);
  });

  it('clearRead() delegates using the validated organization context and authenticated userId', async () => {
    const request = buildRequest();

    await controller.clearRead(request);

    expect(service.clearRead).toHaveBeenCalledWith(ORG_ID, USER_ID);
  });
});
