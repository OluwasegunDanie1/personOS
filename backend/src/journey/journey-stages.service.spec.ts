import { ApiException } from '../common/http/api-exception';
import { JourneyStagesService } from './journey-stages.service';
import { OperationalTemplateService } from './operational-template.service';

const TEMPLATE_ID = 'template-1';
const ORG_ID = 'org-1';
const STAGE_A = '11111111-1111-1111-1111-111111111111';
const STAGE_B = '22222222-2222-2222-2222-222222222222';
const STAGE_C = '33333333-3333-3333-3333-333333333333';

function createMockPrisma() {
  return {
    journeyStage: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      aggregate: jest.fn(),
    },
    personJourneyHistory: { count: jest.fn() },
    $transaction: jest.fn(),
  };
}

function createMockOperationalTemplate() {
  return { resolve: jest.fn().mockResolvedValue({ id: TEMPLATE_ID }) };
}

describe('JourneyStagesService', () => {
  let prisma: ReturnType<typeof createMockPrisma>;
  let operationalTemplate: ReturnType<typeof createMockOperationalTemplate>;
  let service: JourneyStagesService;

  beforeEach(() => {
    prisma = createMockPrisma();
    operationalTemplate = createMockOperationalTemplate();
    prisma.$transaction.mockImplementation((ops: Promise<unknown>[]) => Promise.all(ops));
    service = new JourneyStagesService(prisma as never, operationalTemplate as never);
  });

  describe('list', () => {
    it('resolves the operational template and scopes by it', async () => {
      prisma.journeyStage.findMany.mockResolvedValue([]);

      await service.list(ORG_ID);

      expect(operationalTemplate.resolve).toHaveBeenCalledWith(ORG_ID);
      const args = prisma.journeyStage.findMany.mock.calls[0][0];
      expect(args.where).toEqual({ journeyTemplateId: TEMPLATE_ID });
    });

    it('orders by order asc, id asc and maps order -> position', async () => {
      prisma.journeyStage.findMany.mockResolvedValue([{ id: STAGE_A, name: 'Visitor', order: 1 }]);

      const result = await service.list(ORG_ID);

      const args = prisma.journeyStage.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual([{ order: 'asc' }, { id: 'asc' }]);
      expect(result).toEqual({ stages: [{ id: STAGE_A, name: 'Visitor', position: 1 }] });
    });

    it('returns an empty array when there are no stages', async () => {
      prisma.journeyStage.findMany.mockResolvedValue([]);

      const result = await service.list(ORG_ID);

      expect(result).toEqual({ stages: [] });
    });
  });

  describe('create', () => {
    it('attaches to the resolved operational template', async () => {
      prisma.journeyStage.aggregate.mockResolvedValue({ _max: { order: null } });
      prisma.journeyStage.create.mockResolvedValue({ id: STAGE_A, name: 'Visitor', order: 1 });

      await service.create(ORG_ID, { name: 'Visitor' } as never);

      const args = prisma.journeyStage.create.mock.calls[0][0];
      expect(args.data.journeyTemplateId).toBe(TEMPLATE_ID);
    });

    it('assigns position 1 when no stages exist', async () => {
      prisma.journeyStage.aggregate.mockResolvedValue({ _max: { order: null } });
      prisma.journeyStage.create.mockResolvedValue({ id: STAGE_A, name: 'Visitor', order: 1 });

      await service.create(ORG_ID, { name: 'Visitor' } as never);

      const args = prisma.journeyStage.create.mock.calls[0][0];
      expect(args.data.order).toBe(1);
    });

    it('assigns max+1 when stages already exist', async () => {
      prisma.journeyStage.aggregate.mockResolvedValue({ _max: { order: 4 } });
      prisma.journeyStage.create.mockResolvedValue({ id: STAGE_A, name: 'New', order: 5 });

      await service.create(ORG_ID, { name: 'New' } as never);

      const args = prisma.journeyStage.create.mock.calls[0][0];
      expect(args.data.order).toBe(5);
    });

    it('allows duplicate stage names', async () => {
      prisma.journeyStage.aggregate.mockResolvedValue({ _max: { order: 1 } });
      prisma.journeyStage.create.mockResolvedValue({ id: STAGE_A, name: 'Visitor', order: 2 });

      const result = await service.create(ORG_ID, { name: 'Visitor' } as never);

      expect(result.stage.name).toBe('Visitor');
    });

    it('has no PersonJourneyHistory side effect', async () => {
      prisma.journeyStage.aggregate.mockResolvedValue({ _max: { order: null } });
      prisma.journeyStage.create.mockResolvedValue({ id: STAGE_A, name: 'Visitor', order: 1 });

      await service.create(ORG_ID, { name: 'Visitor' } as never);

      expect(prisma.personJourneyHistory.count).not.toHaveBeenCalled();
    });

    it('returns the exact create response shape', async () => {
      prisma.journeyStage.aggregate.mockResolvedValue({ _max: { order: null } });
      prisma.journeyStage.create.mockResolvedValue({ id: STAGE_A, name: 'Visitor', order: 1 });

      const result = await service.create(ORG_ID, { name: 'Visitor' } as never);

      expect(result).toEqual({ stage: { id: STAGE_A, name: 'Visitor', position: 1 } });
    });
  });

  describe('update', () => {
    it('rejects an update with no fields supplied', async () => {
      await expect(service.update(ORG_ID, STAGE_A, {} as never)).rejects.toThrow(
        'At least one field must be supplied.',
      );
      expect(operationalTemplate.resolve).not.toHaveBeenCalled();
    });

    it('scopes lookup by stage id + operational template', async () => {
      prisma.journeyStage.findFirst.mockResolvedValue(null);

      await expect(service.update(ORG_ID, STAGE_A, { name: 'New' } as never)).rejects.toThrow();

      const args = prisma.journeyStage.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: STAGE_A, journeyTemplateId: TEMPLATE_ID });
    });

    it('throws JOURNEY_STAGE_NOT_FOUND for cross-tenant/non-operational-template stage', async () => {
      prisma.journeyStage.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.update(ORG_ID, STAGE_A, { name: 'New' } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('JOURNEY_STAGE_NOT_FOUND');
    });

    it('never mutates position/order through update', async () => {
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_A });
      prisma.journeyStage.update.mockResolvedValue({ id: STAGE_A, name: 'New', order: 1 });

      await service.update(ORG_ID, STAGE_A, { name: 'New' } as never);

      const args = prisma.journeyStage.update.mock.calls[0][0];
      expect(args.data).toEqual({ name: 'New' });
    });

    it('returns the same shape as create', async () => {
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_A });
      prisma.journeyStage.update.mockResolvedValue({ id: STAGE_A, name: 'New', order: 1 });

      const result = await service.update(ORG_ID, STAGE_A, { name: 'New' } as never);

      expect(result).toEqual({ stage: { id: STAGE_A, name: 'New', position: 1 } });
    });
  });

  describe('reorder', () => {
    it('accepts an exact full set and reassigns order 1..N atomically', async () => {
      prisma.journeyStage.findMany
        .mockResolvedValueOnce([{ id: STAGE_A }, { id: STAGE_B }, { id: STAGE_C }])
        .mockResolvedValueOnce([
          { id: STAGE_C, name: 'C', order: 1 },
          { id: STAGE_B, name: 'B', order: 2 },
          { id: STAGE_A, name: 'A', order: 3 },
        ]);

      const result = await service.reorder(ORG_ID, { stageIds: [STAGE_C, STAGE_B, STAGE_A] } as never);

      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
      const ops = prisma.journeyStage.update.mock.calls;
      expect(ops).toEqual([
        [{ where: { id: STAGE_C }, data: { order: 1 } }],
        [{ where: { id: STAGE_B }, data: { order: 2 } }],
        [{ where: { id: STAGE_A }, data: { order: 3 } }],
      ]);
      expect(result.stages.map((s) => s.position)).toEqual([1, 2, 3]);
    });

    it('rejects a missing current stage', async () => {
      prisma.journeyStage.findMany.mockResolvedValueOnce([{ id: STAGE_A }, { id: STAGE_B }]);

      await expect(service.reorder(ORG_ID, { stageIds: [STAGE_A] } as never)).rejects.toThrow();
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('rejects an extra stage not in the current set', async () => {
      prisma.journeyStage.findMany.mockResolvedValueOnce([{ id: STAGE_A }]);

      await expect(
        service.reorder(ORG_ID, { stageIds: [STAGE_A, STAGE_B] } as never),
      ).rejects.toThrow();
    });

    it('rejects a foreign stage without disclosing its existence', async () => {
      prisma.journeyStage.findMany.mockResolvedValueOnce([{ id: STAGE_A }]);

      let error: ApiException | undefined;
      try {
        await service.reorder(ORG_ID, { stageIds: [STAGE_B] } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('INVALID_STAGE_ORDER');
      expect(error?.message).not.toContain(STAGE_B);
    });

    it('rejects duplicate IDs in the supplied order', async () => {
      prisma.journeyStage.findMany.mockResolvedValueOnce([{ id: STAGE_A }, { id: STAGE_B }]);

      await expect(
        service.reorder(ORG_ID, { stageIds: [STAGE_A, STAGE_A] } as never),
      ).rejects.toThrow();
    });

    it('never touches PersonJourneyHistory', async () => {
      prisma.journeyStage.findMany
        .mockResolvedValueOnce([{ id: STAGE_A }])
        .mockResolvedValueOnce([{ id: STAGE_A, name: 'A', order: 1 }]);

      await service.reorder(ORG_ID, { stageIds: [STAGE_A] } as never);

      expect(prisma.personJourneyHistory.count).not.toHaveBeenCalled();
    });
  });

  describe('remove', () => {
    it('scopes lookup by stage id + operational template', async () => {
      prisma.journeyStage.findFirst.mockResolvedValue(null);

      await expect(service.remove(ORG_ID, STAGE_A)).rejects.toThrow();

      const args = prisma.journeyStage.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: STAGE_A, journeyTemplateId: TEMPLATE_ID });
    });

    it('throws JOURNEY_STAGE_NOT_FOUND when absent/cross-tenant', async () => {
      prisma.journeyStage.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.remove(ORG_ID, STAGE_A);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('JOURNEY_STAGE_NOT_FOUND');
    });

    it('throws JOURNEY_STAGE_IN_USE when referenced as fromStageId or toStageId', async () => {
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_A });
      prisma.personJourneyHistory.count.mockResolvedValue(1);

      let error: ApiException | undefined;
      try {
        await service.remove(ORG_ID, STAGE_A);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('JOURNEY_STAGE_IN_USE');
      expect(prisma.journeyStage.delete).not.toHaveBeenCalled();
    });

    it('checks references using OR across fromStageId/toStageId', async () => {
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_A });
      prisma.personJourneyHistory.count.mockResolvedValue(0);
      prisma.journeyStage.delete.mockResolvedValue({});

      await service.remove(ORG_ID, STAGE_A);

      expect(prisma.personJourneyHistory.count).toHaveBeenCalledWith({
        where: { OR: [{ fromStageId: STAGE_A }, { toStageId: STAGE_A }] },
      });
    });

    it('hard-deletes an unreferenced stage and returns {success:true}', async () => {
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_A });
      prisma.personJourneyHistory.count.mockResolvedValue(0);
      prisma.journeyStage.delete.mockResolvedValue({});

      const result = await service.remove(ORG_ID, STAGE_A);

      expect(prisma.journeyStage.delete).toHaveBeenCalledWith({ where: { id: STAGE_A } });
      expect(result).toEqual({ success: true });
    });
  });
});
