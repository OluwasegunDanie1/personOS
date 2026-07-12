import { OrganizationsService } from './organizations.service';

function createMockPrisma() {
  return { organizationMembership: { findMany: jest.fn() } };
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
});
