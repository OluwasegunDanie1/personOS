import { GUARDS_METADATA } from '@nestjs/common/constants';
import { OrganizationMembershipGuard } from '../common/guards/organization-membership.guard';
import { AuthenticatedRequest } from '../common/http/request-context';
import { OrganizationsController } from './organizations.controller';
import { OrganizationsService } from './organizations.service';

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

describe('OrganizationsController', () => {
  it('delegates to OrganizationsService using request.auth.userId only', async () => {
    const service = { listForUser: jest.fn().mockResolvedValue({ organizations: [] }) };
    const controller = new OrganizationsController(service as never);
    const request = {
      headers: {},
      params: {},
      auth: { userId: 'user-1' },
    } as AuthenticatedRequest & { query?: unknown; body?: unknown };
    // Simulate a client attempting to smuggle a different userId via other
    // request channels; the controller must never read these.
    request.query = { userId: 'attacker-supplied-id' };
    request.body = { userId: 'attacker-supplied-id' };

    const result = await controller.list(request);

    expect(service.listForUser).toHaveBeenCalledWith('user-1');
    expect(service.listForUser).not.toHaveBeenCalledWith('attacker-supplied-id');
    expect(result).toEqual({ organizations: [] });
  });

  describe('create', () => {
    it('is not guarded by OrganizationMembershipGuard at the method level', () => {
      const controller = new OrganizationsController({} as never);
      const guards = Reflect.getMetadata(GUARDS_METADATA, controller.create) as unknown[] | undefined;

      expect(guards ?? []).not.toContain(OrganizationMembershipGuard);
    });

    it('derives the creator id from request.auth.userId, never the request body', async () => {
      const service = { create: jest.fn().mockResolvedValue({ organization: { id: 'org-1', name: 'Acme' } }) };
      const controller = new OrganizationsController(service as unknown as OrganizationsService);
      const request = buildRequest({ auth: { userId: 'authenticated-user-id' } });
      const dto = { name: 'Acme' };

      await controller.create(request, dto as never);

      expect(service.create).toHaveBeenCalledWith('authenticated-user-id', dto);
    });
  });

  describe('detail', () => {
    it('applies OrganizationMembershipGuard at the method level', () => {
      const controller = new OrganizationsController({} as never);
      const guards = Reflect.getMetadata(GUARDS_METADATA, controller.detail) as unknown[];

      expect(guards).toEqual([OrganizationMembershipGuard]);
    });

    it('uses request.organization.organizationId, never the raw path param', async () => {
      const service = { detail: jest.fn().mockResolvedValue({ organization: { id: ORG_ID, name: 'Acme' } }) };
      const controller = new OrganizationsController(service as unknown as OrganizationsService);
      const request = buildRequest({ params: { organizationId: 'attacker-supplied-id' } });

      await controller.detail(request);

      expect(service.detail).toHaveBeenCalledWith(ORG_ID);
    });
  });

  describe('update', () => {
    it('applies OrganizationMembershipGuard at the method level', () => {
      const controller = new OrganizationsController({} as never);
      const guards = Reflect.getMetadata(GUARDS_METADATA, controller.update) as unknown[];

      expect(guards).toEqual([OrganizationMembershipGuard]);
    });

    it('uses request.organization.organizationId, never the raw path param', async () => {
      const service = { update: jest.fn().mockResolvedValue({ organization: { id: ORG_ID, name: 'Updated' } }) };
      const controller = new OrganizationsController(service as unknown as OrganizationsService);
      const request = buildRequest({ params: { organizationId: 'attacker-supplied-id' } });
      const dto = { name: 'Updated' };

      await controller.update(request, dto as never);

      expect(service.update).toHaveBeenCalledWith(ORG_ID, dto);
    });
  });

  describe('listMembers (Product Task 050)', () => {
    it('applies OrganizationMembershipGuard at the method level', () => {
      const controller = new OrganizationsController({} as never);
      const guards = Reflect.getMetadata(GUARDS_METADATA, controller.listMembers) as unknown[];

      expect(guards).toEqual([OrganizationMembershipGuard]);
    });

    it('uses request.organization.organizationId, never the raw path param', async () => {
      const service = { listMembers: jest.fn().mockResolvedValue({ members: [] }) };
      const controller = new OrganizationsController(service as unknown as OrganizationsService);
      const request = buildRequest({ params: { organizationId: 'attacker-supplied-id' } });

      await controller.listMembers(request);

      expect(service.listMembers).toHaveBeenCalledWith(ORG_ID);
    });
  });

  describe('listRoles (Product Task 050)', () => {
    it('applies OrganizationMembershipGuard at the method level', () => {
      const controller = new OrganizationsController({} as never);
      const guards = Reflect.getMetadata(GUARDS_METADATA, controller.listRoles) as unknown[];

      expect(guards).toEqual([OrganizationMembershipGuard]);
    });

    it('uses request.organization.organizationId, never the raw path param', async () => {
      const service = { listRoles: jest.fn().mockResolvedValue({ roles: [] }) };
      const controller = new OrganizationsController(service as unknown as OrganizationsService);
      const request = buildRequest({ params: { organizationId: 'attacker-supplied-id' } });

      await controller.listRoles(request);

      expect(service.listRoles).toHaveBeenCalledWith(ORG_ID);
    });
  });

  describe('listPermissions (Product Task 050)', () => {
    it('applies OrganizationMembershipGuard at the method level', () => {
      const controller = new OrganizationsController({} as never);
      const guards = Reflect.getMetadata(GUARDS_METADATA, controller.listPermissions) as unknown[];

      expect(guards).toEqual([OrganizationMembershipGuard]);
    });

    it('uses request.organization.organizationId, never the raw path param', async () => {
      const service = { listPermissions: jest.fn().mockResolvedValue({ permissions: [] }) };
      const controller = new OrganizationsController(service as unknown as OrganizationsService);
      const request = buildRequest({ params: { organizationId: 'attacker-supplied-id' } });

      await controller.listPermissions(request);

      expect(service.listPermissions).toHaveBeenCalledWith(ORG_ID);
    });
  });
});
