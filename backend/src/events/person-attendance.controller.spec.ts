import { GUARDS_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { PersonAttendanceController } from './person-attendance.controller';
import { AttendanceService } from './attendance.service';

const ORG_ID = '11111111-1111-1111-1111-111111111111';

function buildRequest(overrides: Partial<AuthenticatedRequest> = {}): AuthenticatedRequest {
  return {
    headers: {},
    params: { organizationId: ORG_ID, personId: 'person-1' },
    organization: { organizationId: ORG_ID, membershipId: 'membership-1', roleId: 'role-1' },
    auth: { userId: 'user-1' },
    ...overrides,
  };
}

describe('PersonAttendanceController', () => {
  let service: { listForPerson: jest.Mock };
  let controller: PersonAttendanceController;

  beforeEach(() => {
    service = { listForPerson: jest.fn().mockResolvedValue({ attendance: [], nextCursor: null }) };
    controller = new PersonAttendanceController(service as unknown as AttendanceService);
  });

  it('is registered under organizations/:organizationId/people/:personId/attendance', () => {
    expect(Reflect.getMetadata(PATH_METADATA, PersonAttendanceController)).toBe(
      'organizations/:organizationId/people/:personId/attendance',
    );
  });

  it('applies OrganizationMembershipGuard at the controller level', () => {
    const guards = Reflect.getMetadata(GUARDS_METADATA, PersonAttendanceController) as unknown[];
    expect(guards).toEqual([OrganizationMembershipGuard]);
  });

  it('list() uses request.organization.organizationId, never the raw path param', async () => {
    const request = buildRequest({ params: { organizationId: 'attacker-supplied-id', personId: 'person-1' } });

    await controller.list(request, 'person-1', {});

    expect(service.listForPerson).toHaveBeenCalledWith(ORG_ID, 'person-1', {});
  });
});
