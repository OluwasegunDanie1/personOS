import { GUARDS_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { HttpStatus } from '@nestjs/common';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { EventAttendanceController } from './event-attendance.controller';
import { AttendanceService } from './attendance.service';

const ORG_ID = '11111111-1111-1111-1111-111111111111';

function buildRequest(overrides: Partial<AuthenticatedRequest> = {}): AuthenticatedRequest {
  return {
    headers: {},
    params: { organizationId: ORG_ID, eventId: 'event-1' },
    organization: { organizationId: ORG_ID, membershipId: 'membership-1', roleId: 'role-1' },
    auth: { userId: 'user-1' },
    ...overrides,
  };
}

function buildResponse() {
  const response = { status: jest.fn() };
  response.status.mockReturnValue(response);
  return response;
}

describe('EventAttendanceController', () => {
  let service: { listForEvent: jest.Mock; record: jest.Mock };
  let controller: EventAttendanceController;

  beforeEach(() => {
    service = {
      listForEvent: jest.fn().mockResolvedValue({ attendance: [], nextCursor: null }),
      record: jest.fn().mockResolvedValue({ attendance: { id: 'attendance-1' }, created: true }),
    };
    controller = new EventAttendanceController(service as unknown as AttendanceService);
  });

  it('is registered under organizations/:organizationId/events/:eventId/attendance', () => {
    expect(Reflect.getMetadata(PATH_METADATA, EventAttendanceController)).toBe(
      'organizations/:organizationId/events/:eventId/attendance',
    );
  });

  it('applies OrganizationMembershipGuard at the controller level', () => {
    const guards = Reflect.getMetadata(GUARDS_METADATA, EventAttendanceController) as unknown[];
    expect(guards).toEqual([OrganizationMembershipGuard]);
  });

  it('list() uses request.organization.organizationId, never the raw path param', async () => {
    const request = buildRequest({ params: { organizationId: 'attacker-supplied-id', eventId: 'event-1' } });

    await controller.list(request, 'event-1', {});

    expect(service.listForEvent).toHaveBeenCalledWith(ORG_ID, 'event-1', {});
  });

  it('record() derives organizationId/eventId/checkedInBy from validated context, never client input', async () => {
    const request = buildRequest();
    const response = buildResponse();
    const dto = { personId: 'person-1' };

    await controller.record(request, response as never, 'event-1', dto as never);

    expect(service.record).toHaveBeenCalledWith(ORG_ID, 'event-1', 'user-1', dto);
  });

  it('sets HTTP 201 when a new Attendance row is created', async () => {
    service.record.mockResolvedValue({ attendance: { id: 'attendance-1' }, created: true });
    const response = buildResponse();

    const result = await controller.record(buildRequest(), response as never, 'event-1', {
      personId: 'person-1',
    } as never);

    expect(response.status).toHaveBeenCalledWith(HttpStatus.CREATED);
    expect(result).toEqual({ attendance: { id: 'attendance-1' } });
  });

  it('sets HTTP 200 when an existing Attendance row is returned (idempotent replay)', async () => {
    service.record.mockResolvedValue({ attendance: { id: 'attendance-1' }, created: false });
    const response = buildResponse();

    const result = await controller.record(buildRequest(), response as never, 'event-1', {
      personId: 'person-1',
    } as never);

    expect(response.status).toHaveBeenCalledWith(HttpStatus.OK);
    expect(result).toEqual({ attendance: { id: 'attendance-1' } });
  });
});
