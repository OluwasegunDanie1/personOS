import { ExecutionContext } from '@nestjs/common';
import { ApiException } from '../http/api-exception';
import { AuthenticatedRequest } from '../http/request-context';
import { OrganizationMembershipGuard } from './organization-membership.guard';

const VALID_ORG_ID = '11111111-1111-1111-1111-111111111111';

function buildRequest(overrides: Partial<AuthenticatedRequest> = {}): AuthenticatedRequest {
  return {
    headers: {},
    params: { organizationId: VALID_ORG_ID },
    auth: { userId: 'user-1' },
    ...overrides,
  };
}

function buildContext(request: AuthenticatedRequest): ExecutionContext {
  return {
    getHandler: () => ({}) as never,
    getClass: () => ({}) as never,
    switchToHttp: () => ({ getRequest: () => request }) as never,
  } as unknown as ExecutionContext;
}

describe('OrganizationMembershipGuard', () => {
  let prisma: {
    organizationMembership: { findUnique: jest.Mock };
    permission: { findMany: jest.Mock };
    rolePermission: { findMany: jest.Mock };
  };
  let guard: OrganizationMembershipGuard;

  beforeEach(() => {
    prisma = {
      organizationMembership: { findUnique: jest.fn() },
      permission: { findMany: jest.fn() },
      rolePermission: { findMany: jest.fn() },
    };
    guard = new OrganizationMembershipGuard(prisma as never);
  });

  async function expectDenied(request: AuthenticatedRequest): Promise<ApiException> {
    try {
      await guard.canActivate(buildContext(request));
      throw new Error('expected canActivate to throw');
    } catch (error) {
      return error as ApiException;
    }
  }

  it('denies when authenticated request identity is missing', async () => {
    const error = await expectDenied(buildRequest({ auth: undefined }));

    expect(error.code).toBe('ORGANIZATION_ACCESS_DENIED');
    expect(prisma.organizationMembership.findUnique).not.toHaveBeenCalled();
  });

  it('denies a malformed organizationId', async () => {
    const error = await expectDenied(buildRequest({ params: { organizationId: 'not-a-uuid' } }));

    expect(error.code).toBe('ORGANIZATION_ACCESS_DENIED');
    expect(prisma.organizationMembership.findUnique).not.toHaveBeenCalled();
  });

  it('denies a missing organizationId path parameter', async () => {
    const error = await expectDenied(buildRequest({ params: {} }));

    expect(error.code).toBe('ORGANIZATION_ACCESS_DENIED');
  });

  it('denies when no membership exists', async () => {
    prisma.organizationMembership.findUnique.mockResolvedValue(null);

    const error = await expectDenied(buildRequest());

    expect(error.code).toBe('ORGANIZATION_ACCESS_DENIED');
  });

  it('denies when the membership cannot resolve a roleId', async () => {
    prisma.organizationMembership.findUnique.mockResolvedValue({
      id: 'membership-1',
      organizationId: VALID_ORG_ID,
      roleId: null,
    });

    const error = await expectDenied(buildRequest());

    expect(error.code).toBe('ORGANIZATION_ACCESS_DENIED');
  });

  it('attaches exactly organizationId/membershipId/roleId for a valid membership', async () => {
    prisma.organizationMembership.findUnique.mockResolvedValue({
      id: 'membership-1',
      organizationId: VALID_ORG_ID,
      roleId: 'role-1',
    });
    const request = buildRequest();

    const result = await guard.canActivate(buildContext(request));

    expect(result).toBe(true);
    expect(request.organization).toEqual({
      organizationId: VALID_ORG_ID,
      membershipId: 'membership-1',
      roleId: 'role-1',
    });
    expect(Object.keys(request.organization as object).sort()).toEqual(
      ['membershipId', 'organizationId', 'roleId'].sort(),
    );
  });

  it('looks up membership using the unique organizationId + userId boundary', async () => {
    prisma.organizationMembership.findUnique.mockResolvedValue({
      id: 'membership-1',
      organizationId: VALID_ORG_ID,
      roleId: 'role-1',
    });

    await guard.canActivate(buildContext(buildRequest()));

    expect(prisma.organizationMembership.findUnique).toHaveBeenCalledWith({
      where: { organizationId_userId: { organizationId: VALID_ORG_ID, userId: 'user-1' } },
      select: { id: true, organizationId: true, roleId: true },
    });
  });

  it('does not perform JWT verification', async () => {
    prisma.organizationMembership.findUnique.mockResolvedValue({
      id: 'membership-1',
      organizationId: VALID_ORG_ID,
      roleId: 'role-1',
    });
    const request = buildRequest();

    await guard.canActivate(buildContext(request));

    // The guard has no JwtService/AccessTokenService dependency at all;
    // its only collaborator is PrismaService.
    expect(Object.keys(guard as unknown as Record<string, unknown>)).toEqual(['prisma']);
  });

  it('never queries Permission or RolePermission', async () => {
    prisma.organizationMembership.findUnique.mockResolvedValue({
      id: 'membership-1',
      organizationId: VALID_ORG_ID,
      roleId: 'role-1',
    });

    await guard.canActivate(buildContext(buildRequest()));

    expect(prisma.permission.findMany).not.toHaveBeenCalled();
    expect(prisma.rolePermission.findMany).not.toHaveBeenCalled();
  });
});
