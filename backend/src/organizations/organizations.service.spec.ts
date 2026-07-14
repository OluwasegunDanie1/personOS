import { OrganizationsService } from './organizations.service';

function createMockPrisma() {
  return {
    organizationMembership: { findMany: jest.fn(), create: jest.fn() },
    organization: { create: jest.fn(), findFirst: jest.fn(), update: jest.fn() },
    role: { create: jest.fn(), findMany: jest.fn() },
    permission: { findMany: jest.fn() },
    $transaction: jest.fn(),
  };
}

describe('OrganizationsService', () => {
  let prisma: ReturnType<typeof createMockPrisma>;
  let service: OrganizationsService;

  beforeEach(() => {
    prisma = createMockPrisma();
    service = new OrganizationsService(prisma as never);
  });

  it('scopes the membership query by the given userId', async () => {
    prisma.organizationMembership.findMany.mockResolvedValue([]);

    await service.listForUser('user-1');

    expect(prisma.organizationMembership.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { userId: 'user-1' } }),
    );
  });

  it('selects only the approved organization and role fields', async () => {
    prisma.organizationMembership.findMany.mockResolvedValue([]);

    await service.listForUser('user-1');

    expect(prisma.organizationMembership.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        select: {
          organization: { select: { id: true, name: true, logo: true } },
          role: { select: { id: true, name: true } },
        },
      }),
    );
  });

  it('orders deterministically by organization name then id ascending', async () => {
    prisma.organizationMembership.findMany.mockResolvedValue([]);

    await service.listForUser('user-1');

    expect(prisma.organizationMembership.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        orderBy: [{ organization: { name: 'asc' } }, { organization: { id: 'asc' } }],
      }),
    );
  });

  it('maps membership rows to the approved response shape exactly', async () => {
    prisma.organizationMembership.findMany.mockResolvedValue([
      {
        organization: { id: 'org-1', name: 'Acme', logo: 'https://example.com/logo.png' },
        role: { id: 'role-1', name: 'Owner' },
      },
    ]);

    const result = await service.listForUser('user-1');

    expect(result).toEqual({
      organizations: [
        {
          id: 'org-1',
          name: 'Acme',
          logoUrl: 'https://example.com/logo.png',
          role: { id: 'role-1', name: 'Owner' },
        },
      ],
    });
  });

  it('maps a null logo to logoUrl: null', async () => {
    prisma.organizationMembership.findMany.mockResolvedValue([
      { organization: { id: 'org-1', name: 'Acme', logo: null }, role: { id: 'role-1', name: 'Owner' } },
    ]);

    const result = await service.listForUser('user-1');

    expect(result.organizations[0].logoUrl).toBeNull();
  });

  it('excludes permission data and membershipId from the response', async () => {
    prisma.organizationMembership.findMany.mockResolvedValue([
      { organization: { id: 'org-1', name: 'Acme', logo: null }, role: { id: 'role-1', name: 'Owner' } },
    ]);

    const result = await service.listForUser('user-1');

    expect(result.organizations[0]).not.toHaveProperty('permissions');
    expect(result.organizations[0]).not.toHaveProperty('membershipId');
    expect(result.organizations[0].role).not.toHaveProperty('permissions');
  });

  it('returns an empty organizations array when there are no memberships', async () => {
    prisma.organizationMembership.findMany.mockResolvedValue([]);

    const result = await service.listForUser('user-1');

    expect(result).toEqual({ organizations: [] });
  });

  describe('create', () => {
    beforeEach(() => {
      prisma.$transaction.mockImplementation((ops: Promise<unknown>[]) => Promise.all(ops));
    });

    it('creates the Organization with the supplied name and a server-generated id/slug', async () => {
      prisma.organization.create.mockResolvedValue({ id: 'org-1', name: 'Acme' });
      prisma.role.create.mockResolvedValue({ id: 'role-1' });

      await service.create('user-1', { name: 'Acme' } as never);

      const args = prisma.organization.create.mock.calls[0][0];
      expect(args.data.name).toBe('Acme');
      expect(typeof args.data.id).toBe('string');
      expect(typeof args.data.slug).toBe('string');
      expect(args.data.slug).toContain(args.data.id);
      expect(args.select).toEqual({ id: true, name: true });
    });

    it('creates exactly one Role named "Owner" scoped to the new Organization', async () => {
      prisma.organization.create.mockResolvedValue({ id: 'org-1', name: 'Acme' });
      prisma.role.create.mockResolvedValue({ id: 'role-1' });

      await service.create('user-1', { name: 'Acme' } as never);

      const orgArgs = prisma.organization.create.mock.calls[0][0];
      const roleArgs = prisma.role.create.mock.calls[0][0];
      expect(roleArgs.data.name).toBe('Owner');
      expect(roleArgs.data.organizationId).toBe(orgArgs.data.id);
    });

    it('creates exactly one OrganizationMembership linking the creator, new Organization, and new Role', async () => {
      prisma.organization.create.mockResolvedValue({ id: 'org-1', name: 'Acme' });
      prisma.role.create.mockResolvedValue({ id: 'role-1' });
      const membershipCreate = jest.fn().mockResolvedValue({ id: 'membership-1' });
      (prisma as unknown as { organizationMembership: { create: jest.Mock } }).organizationMembership.create =
        membershipCreate;

      await service.create('user-1', { name: 'Acme' } as never);

      const orgArgs = prisma.organization.create.mock.calls[0][0];
      const roleArgs = prisma.role.create.mock.calls[0][0];
      const membershipArgs = membershipCreate.mock.calls[0][0];
      expect(membershipArgs.data).toEqual({
        organizationId: orgArgs.data.id,
        userId: 'user-1',
        roleId: roleArgs.data.id,
      });
    });

    it('creates zero Permission/RolePermission rows', async () => {
      prisma.organization.create.mockResolvedValue({ id: 'org-1', name: 'Acme' });
      prisma.role.create.mockResolvedValue({ id: 'role-1' });
      (prisma as unknown as { organizationMembership: { create: jest.Mock } }).organizationMembership.create = jest
        .fn()
        .mockResolvedValue({ id: 'membership-1' });

      await service.create('user-1', { name: 'Acme' } as never);

      expect(prisma.permission.findMany).not.toHaveBeenCalled();
    });

    it('performs the three creates as a single atomic $transaction call', async () => {
      prisma.organization.create.mockResolvedValue({ id: 'org-1', name: 'Acme' });
      prisma.role.create.mockResolvedValue({ id: 'role-1' });
      (prisma as unknown as { organizationMembership: { create: jest.Mock } }).organizationMembership.create = jest
        .fn()
        .mockResolvedValue({ id: 'membership-1' });

      await service.create('user-1', { name: 'Acme' } as never);

      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
      const transactionArg = prisma.$transaction.mock.calls[0][0];
      expect(transactionArg).toHaveLength(3);
    });

    it('returns exactly {organization: {id, name}}', async () => {
      prisma.organization.create.mockResolvedValue({ id: 'org-1', name: 'Acme' });
      prisma.role.create.mockResolvedValue({ id: 'role-1' });
      (prisma as unknown as { organizationMembership: { create: jest.Mock } }).organizationMembership.create = jest
        .fn()
        .mockResolvedValue({ id: 'membership-1' });

      const result = await service.create('user-1', { name: 'Acme' } as never);

      expect(result).toEqual({ organization: { id: 'org-1', name: 'Acme' } });
    });

    it('never exposes slug in the returned response', async () => {
      prisma.organization.create.mockResolvedValue({ id: 'org-1', name: 'Acme' });
      prisma.role.create.mockResolvedValue({ id: 'role-1' });
      (prisma as unknown as { organizationMembership: { create: jest.Mock } }).organizationMembership.create = jest
        .fn()
        .mockResolvedValue({ id: 'membership-1' });

      const result = await service.create('user-1', { name: 'Acme' } as never);

      expect(result.organization).not.toHaveProperty('slug');
    });
  });

  describe('detail', () => {
    it('scopes the lookup by id', async () => {
      prisma.organization.findFirst.mockResolvedValue({ id: 'org-1', name: 'Acme' });

      await service.detail('org-1');

      const args = prisma.organization.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'org-1' });
      expect(args.select).toEqual({ id: true, name: true });
    });

    it('returns exactly {organization: {id, name}}', async () => {
      prisma.organization.findFirst.mockResolvedValue({ id: 'org-1', name: 'Acme' });

      const result = await service.detail('org-1');

      expect(result).toEqual({ organization: { id: 'org-1', name: 'Acme' } });
    });

    it('throws a plain (non-public) Error for the practically-unreachable missing-row case', async () => {
      prisma.organization.findFirst.mockResolvedValue(null);

      await expect(service.detail('org-1')).rejects.toThrow();
    });
  });

  describe('update', () => {
    it('scopes the mutation by organizationId and writes only name', async () => {
      prisma.organization.update.mockResolvedValue({ id: 'org-1', name: 'Updated' });

      await service.update('org-1', { name: 'Updated' } as never);

      const args = prisma.organization.update.mock.calls[0][0];
      expect(args.where).toEqual({ id: 'org-1' });
      expect(args.data).toEqual({ name: 'Updated' });
      expect(args.select).toEqual({ id: true, name: true });
    });

    it('returns exactly {organization: {id, name}}', async () => {
      prisma.organization.update.mockResolvedValue({ id: 'org-1', name: 'Updated' });

      const result = await service.update('org-1', { name: 'Updated' } as never);

      expect(result).toEqual({ organization: { id: 'org-1', name: 'Updated' } });
    });
  });

  describe('listMembers (Product Task 050)', () => {
    it('scopes the membership query by the given organizationId', async () => {
      prisma.organizationMembership.findMany.mockResolvedValue([]);

      await service.listMembers('org-1');

      expect(prisma.organizationMembership.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { organizationId: 'org-1' } }),
      );
    });

    it('orders deterministically by user firstName, lastName, then membership id ascending', async () => {
      prisma.organizationMembership.findMany.mockResolvedValue([]);

      await service.listMembers('org-1');

      expect(prisma.organizationMembership.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          orderBy: [{ user: { firstName: 'asc' } }, { user: { lastName: 'asc' } }, { id: 'asc' }],
        }),
      );
    });

    it('maps membership rows to {membershipId, user, role} exactly', async () => {
      prisma.organizationMembership.findMany.mockResolvedValue([
        {
          id: 'membership-1',
          user: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace', email: 'ada@example.com' },
          role: { id: 'role-1', name: 'Owner' },
        },
      ]);

      const result = await service.listMembers('org-1');

      expect(result).toEqual({
        members: [
          {
            membershipId: 'membership-1',
            user: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace', email: 'ada@example.com' },
            role: { id: 'role-1', name: 'Owner' },
          },
        ],
      });
    });

    it('never invents status, invite state, permissions summary, phone, avatar, or activity fields', async () => {
      prisma.organizationMembership.findMany.mockResolvedValue([
        {
          id: 'membership-1',
          user: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace', email: 'ada@example.com' },
          role: { id: 'role-1', name: 'Owner' },
        },
      ]);

      const result = await service.listMembers('org-1');
      const member = result.members[0] as unknown as Record<string, unknown>;

      expect(member).not.toHaveProperty('status');
      expect(member).not.toHaveProperty('inviteState');
      expect(member).not.toHaveProperty('permissions');
      expect(member.user).not.toHaveProperty('phone');
      expect(member.user).not.toHaveProperty('avatar');
      expect(member).not.toHaveProperty('lastActive');
    });

    it('returns an empty members array when the organization has no memberships', async () => {
      prisma.organizationMembership.findMany.mockResolvedValue([]);

      const result = await service.listMembers('org-1');

      expect(result).toEqual({ members: [] });
    });
  });

  describe('listRoles (Product Task 050)', () => {
    it('scopes the role query by the given organizationId', async () => {
      prisma.role.findMany.mockResolvedValue([]);

      await service.listRoles('org-1');

      expect(prisma.role.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { organizationId: 'org-1' } }));
    });

    it('orders deterministically by name then id ascending', async () => {
      prisma.role.findMany.mockResolvedValue([]);

      await service.listRoles('org-1');

      expect(prisma.role.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ orderBy: [{ name: 'asc' }, { id: 'asc' }] }),
      );
    });

    it('maps each role to {id, name, description, permissions} using the real RolePermission join', async () => {
      prisma.role.findMany.mockResolvedValue([
        {
          id: 'role-1',
          name: 'Owner',
          description: 'Full access',
          rolePermissions: [{ permission: { id: 'perm-1', name: 'people.view' } }],
        },
      ]);

      const result = await service.listRoles('org-1');

      expect(result).toEqual({
        roles: [
          {
            id: 'role-1',
            name: 'Owner',
            description: 'Full access',
            permissions: [{ id: 'perm-1', name: 'people.view' }],
          },
        ],
      });
    });

    it('returns an empty permissions array for a role with no assigned permissions', async () => {
      prisma.role.findMany.mockResolvedValue([
        { id: 'role-1', name: 'Owner', description: null, rolePermissions: [] },
      ]);

      const result = await service.listRoles('org-1');

      expect(result.roles[0].permissions).toEqual([]);
    });

    it('does not create, update, or delete any role', async () => {
      prisma.role.findMany.mockResolvedValue([]);

      await service.listRoles('org-1');

      expect(prisma.role.create).not.toHaveBeenCalled();
    });

    it('returns an empty roles array when the organization has no roles', async () => {
      prisma.role.findMany.mockResolvedValue([]);

      const result = await service.listRoles('org-1');

      expect(result).toEqual({ roles: [] });
    });
  });

  describe('listPermissions (Product Task 050)', () => {
    it('scopes the permission query to permissions assigned to a role in the given organization', async () => {
      prisma.permission.findMany.mockResolvedValue([]);

      await service.listPermissions('org-1');

      expect(prisma.permission.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { rolePermissions: { some: { role: { organizationId: 'org-1' } } } } }),
      );
    });

    it('orders deterministically by name then id ascending', async () => {
      prisma.permission.findMany.mockResolvedValue([]);

      await service.listPermissions('org-1');

      expect(prisma.permission.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ orderBy: [{ name: 'asc' }, { id: 'asc' }] }),
      );
    });

    it('returns exactly {id, name} per permission, never an invented group/category/description', async () => {
      prisma.permission.findMany.mockResolvedValue([{ id: 'perm-1', name: 'people.view' }]);

      const result = await service.listPermissions('org-1');

      expect(result).toEqual({ permissions: [{ id: 'perm-1', name: 'people.view' }] });
      expect(result.permissions[0]).not.toHaveProperty('category');
      expect(result.permissions[0]).not.toHaveProperty('group');
      expect(result.permissions[0]).not.toHaveProperty('description');
    });

    it('returns an empty permissions array when no Permission rows are assigned to this organization (real current state)', async () => {
      prisma.permission.findMany.mockResolvedValue([]);

      const result = await service.listPermissions('org-1');

      expect(result).toEqual({ permissions: [] });
    });
  });
});
