import { OperationalTemplateService } from './operational-template.service';

function createMockPrisma() {
  return { journeyTemplate: { findMany: jest.fn() } };
}

describe('OperationalTemplateService', () => {
  let prisma: ReturnType<typeof createMockPrisma>;
  let service: OperationalTemplateService;

  beforeEach(() => {
    prisma = createMockPrisma();
    service = new OperationalTemplateService(prisma as never);
  });

  it('fails when zero templates exist for the organization', async () => {
    prisma.journeyTemplate.findMany.mockResolvedValue([]);

    await expect(service.resolve('org-1')).rejects.toThrow('No operational JourneyTemplate');
  });

  it('resolves the single template when exactly one exists', async () => {
    prisma.journeyTemplate.findMany.mockResolvedValue([{ id: 'template-1' }]);

    const result = await service.resolve('org-1');

    expect(result).toEqual({ id: 'template-1' });
  });

  it('fails when multiple templates exist for the organization', async () => {
    prisma.journeyTemplate.findMany.mockResolvedValue([{ id: 'template-1' }, { id: 'template-2' }]);

    await expect(service.resolve('org-1')).rejects.toThrow('Multiple JourneyTemplate rows');
  });

  it('scopes the lookup by organizationId', async () => {
    prisma.journeyTemplate.findMany.mockResolvedValue([{ id: 'template-1' }]);

    await service.resolve('org-1');

    expect(prisma.journeyTemplate.findMany).toHaveBeenCalledWith({
      where: { organizationId: 'org-1' },
      select: { id: true },
    });
  });

  it('does not throw an ApiException (kept as a plain internal invariant failure)', async () => {
    prisma.journeyTemplate.findMany.mockResolvedValue([]);

    try {
      await service.resolve('org-1');
      throw new Error('expected resolve to throw');
    } catch (error) {
      expect(error).toBeInstanceOf(Error);
      expect((error as { code?: string }).code).toBeUndefined();
    }
  });
});
