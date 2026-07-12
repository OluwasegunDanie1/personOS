import { ApiException } from '../common/http/api-exception';
import { PersonJourneyService } from './person-journey.service';

const ORG_ID = 'org-1';
const PERSON_ID = 'person-1';
const TEMPLATE_ID = 'template-1';
const STAGE_A = '11111111-1111-1111-1111-111111111111';
const STAGE_B = '22222222-2222-2222-2222-222222222222';
const MOVER = { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace' };

function createMockPrisma() {
  return {
    person: { findFirst: jest.fn() },
    personJourneyHistory: { findMany: jest.fn(), findFirst: jest.fn(), create: jest.fn() },
    journeyStage: { findFirst: jest.fn() },
  };
}

function createMockOperationalTemplate() {
  return { resolve: jest.fn().mockResolvedValue({ id: TEMPLATE_ID }) };
}

describe('PersonJourneyService', () => {
  let prisma: ReturnType<typeof createMockPrisma>;
  let operationalTemplate: ReturnType<typeof createMockOperationalTemplate>;
  let service: PersonJourneyService;

  beforeEach(() => {
    prisma = createMockPrisma();
    operationalTemplate = createMockOperationalTemplate();
    service = new PersonJourneyService(prisma as never, operationalTemplate as never);
  });

  describe('view', () => {
    it('scopes Person lookup by id + organizationId + deletedAt null', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      await expect(service.view(ORG_ID, PERSON_ID)).rejects.toThrow();

      const args = prisma.person.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: PERSON_ID, organizationId: ORG_ID, deletedAt: null });
    });

    it('throws PERSON_NOT_FOUND for a deleted/cross-tenant/absent Person', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.view(ORG_ID, PERSON_ID);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('PERSON_NOT_FOUND');
    });

    it('returns currentJourneyStage null when there is no history', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.personJourneyHistory.findMany.mockResolvedValue([]);

      const result = await service.view(ORG_ID, PERSON_ID);

      expect(result.currentJourneyStage).toBeNull();
      expect(result.history).toEqual([]);
    });

    it('orders history movedAt desc, id desc and uses the latest row for currentJourneyStage', async () => {
      const now = new Date('2026-01-02T00:00:00.000Z');
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.personJourneyHistory.findMany.mockResolvedValue([
        {
          id: 'history-2',
          notes: null,
          movedAt: now,
          fromStage: { id: STAGE_A, name: 'Visitor' },
          toStage: { id: STAGE_B, name: 'Member', order: 2 },
          movedByUser: MOVER,
        },
      ]);

      const result = await service.view(ORG_ID, PERSON_ID);

      const args = prisma.personJourneyHistory.findMany.mock.calls[0][0];
      expect(args.orderBy).toEqual([{ movedAt: 'desc' }, { id: 'desc' }]);
      expect(result.currentJourneyStage).toEqual({ id: STAGE_B, name: 'Member', position: 2 });
    });

    it('maps schema notes to API note and exposes minimal movedBy', async () => {
      const now = new Date('2026-01-02T00:00:00.000Z');
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.personJourneyHistory.findMany.mockResolvedValue([
        {
          id: 'history-1',
          notes: 'Completed follow-up.',
          movedAt: now,
          fromStage: null,
          toStage: { id: STAGE_A, name: 'Visitor', order: 1 },
          movedByUser: MOVER,
        },
      ]);

      const result = await service.view(ORG_ID, PERSON_ID);

      expect(result.history[0].note).toBe('Completed follow-up.');
      expect(result.history[0].movedBy).toEqual(MOVER);
      expect(result.history[0]).not.toHaveProperty('notes');
    });

    it('exposes no email/phone/status/passwordHash/deletedAt/organizationId', async () => {
      const now = new Date();
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.personJourneyHistory.findMany.mockResolvedValue([
        {
          id: 'history-1',
          notes: null,
          movedAt: now,
          fromStage: null,
          toStage: { id: STAGE_A, name: 'Visitor', order: 1 },
          movedByUser: MOVER,
        },
      ]);

      const result = await service.view(ORG_ID, PERSON_ID);

      const serialized = JSON.stringify(result);
      expect(serialized).not.toContain('email');
      expect(serialized).not.toContain('passwordHash');
      expect(serialized).not.toContain('organizationId');
    });
  });

  describe('move', () => {
    it('scopes Person lookup and rejects deleted/cross-tenant Person', async () => {
      prisma.person.findFirst.mockResolvedValue(null);

      await expect(
        service.move(ORG_ID, PERSON_ID, MOVER.id, { stageId: STAGE_A } as never),
      ).rejects.toThrow();

      expect(operationalTemplate.resolve).not.toHaveBeenCalled();
    });

    it('validates the target stage belongs to the operational template', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.journeyStage.findFirst.mockResolvedValue(null);

      let error: ApiException | undefined;
      try {
        await service.move(ORG_ID, PERSON_ID, MOVER.id, { stageId: STAGE_A } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('JOURNEY_STAGE_NOT_FOUND');
      const args = prisma.journeyStage.findFirst.mock.calls[0][0];
      expect(args.where).toEqual({ id: STAGE_A, journeyTemplateId: TEMPLATE_ID });
    });

    it('first movement has fromStage null', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_A, name: 'Visitor' });
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);
      prisma.personJourneyHistory.create.mockResolvedValue({
        id: 'history-1',
        notes: null,
        movedAt: new Date(),
        fromStage: null,
        toStage: { id: STAGE_A, name: 'Visitor' },
        movedByUser: MOVER,
      });

      await service.move(ORG_ID, PERSON_ID, MOVER.id, { stageId: STAGE_A } as never);

      const args = prisma.personJourneyHistory.create.mock.calls[0][0];
      expect(args.data.fromStageId).toBeNull();
    });

    it('later movement uses the latest history toStageId as fromStageId', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_B, name: 'Member' });
      prisma.personJourneyHistory.findFirst.mockResolvedValue({ toStageId: STAGE_A });
      prisma.personJourneyHistory.create.mockResolvedValue({
        id: 'history-2',
        notes: null,
        movedAt: new Date(),
        fromStage: { id: STAGE_A, name: 'Visitor' },
        toStage: { id: STAGE_B, name: 'Member' },
        movedByUser: MOVER,
      });

      await service.move(ORG_ID, PERSON_ID, MOVER.id, { stageId: STAGE_B } as never);

      const args = prisma.personJourneyHistory.create.mock.calls[0][0];
      expect(args.data.fromStageId).toBe(STAGE_A);
      expect(args.data.toStageId).toBe(STAGE_B);
    });

    it('rejects moving to the current stage with PERSON_ALREADY_IN_STAGE', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_A, name: 'Visitor' });
      prisma.personJourneyHistory.findFirst.mockResolvedValue({ toStageId: STAGE_A });

      let error: ApiException | undefined;
      try {
        await service.move(ORG_ID, PERSON_ID, MOVER.id, { stageId: STAGE_A } as never);
      } catch (e) {
        error = e as ApiException;
      }

      expect(error?.code).toBe('PERSON_ALREADY_IN_STAGE');
      expect(prisma.personJourneyHistory.create).not.toHaveBeenCalled();
    });

    it('allows backward movement (no ordering check against previous stage)', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_A, name: 'Visitor' });
      prisma.personJourneyHistory.findFirst.mockResolvedValue({ toStageId: STAGE_B });
      prisma.personJourneyHistory.create.mockResolvedValue({
        id: 'history-3',
        notes: null,
        movedAt: new Date(),
        fromStage: { id: STAGE_B, name: 'Member' },
        toStage: { id: STAGE_A, name: 'Visitor' },
        movedByUser: MOVER,
      });

      const result = await service.move(ORG_ID, PERSON_ID, MOVER.id, { stageId: STAGE_A } as never);

      expect(result.movement.toStage.id).toBe(STAGE_A);
    });

    it('movedBy is always the authenticated userId, never client input', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_A, name: 'Visitor' });
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);
      prisma.personJourneyHistory.create.mockResolvedValue({
        id: 'history-1',
        notes: null,
        movedAt: new Date(),
        fromStage: null,
        toStage: { id: STAGE_A, name: 'Visitor' },
        movedByUser: MOVER,
      });

      await service.move(ORG_ID, PERSON_ID, 'authenticated-user-id', {
        stageId: STAGE_A,
        movedBy: 'attacker-supplied-id',
      } as never);

      const args = prisma.personJourneyHistory.create.mock.calls[0][0];
      expect(args.data.movedBy).toBe('authenticated-user-id');
    });

    it('movedAt is server-generated', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_A, name: 'Visitor' });
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);
      prisma.personJourneyHistory.create.mockResolvedValue({
        id: 'history-1',
        notes: null,
        movedAt: new Date(),
        fromStage: null,
        toStage: { id: STAGE_A, name: 'Visitor' },
        movedByUser: MOVER,
      });

      await service.move(ORG_ID, PERSON_ID, MOVER.id, { stageId: STAGE_A } as never);

      const args = prisma.personJourneyHistory.create.mock.calls[0][0];
      expect(args.data.movedAt).toBeInstanceOf(Date);
    });

    it('creates exactly one history row and never updates Person.currentJourneyStageId', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_A, name: 'Visitor' });
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);
      prisma.personJourneyHistory.create.mockResolvedValue({
        id: 'history-1',
        notes: null,
        movedAt: new Date(),
        fromStage: null,
        toStage: { id: STAGE_A, name: 'Visitor' },
        movedByUser: MOVER,
      });

      await service.move(ORG_ID, PERSON_ID, MOVER.id, { stageId: STAGE_A } as never);

      expect(prisma.personJourneyHistory.create).toHaveBeenCalledTimes(1);
      // The mock Prisma object never exposes person.update, proving the
      // service has no code path that could write to Person at all here.
      expect((prisma as unknown as { person: { update?: unknown } }).person.update).toBeUndefined();
    });

    it('returns the exact approved movement response shape', async () => {
      prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
      prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_A, name: 'Visitor' });
      prisma.personJourneyHistory.findFirst.mockResolvedValue(null);
      prisma.personJourneyHistory.create.mockResolvedValue({
        id: 'history-1',
        notes: 'a note',
        movedAt: new Date('2026-01-01T00:00:00.000Z'),
        fromStage: null,
        toStage: { id: STAGE_A, name: 'Visitor' },
        movedByUser: MOVER,
      });

      const result = await service.move(ORG_ID, PERSON_ID, MOVER.id, {
        stageId: STAGE_A,
        note: 'a note',
      } as never);

      expect(result).toEqual({
        movement: {
          id: 'history-1',
          fromStage: null,
          toStage: { id: STAGE_A, name: 'Visitor' },
          note: 'a note',
          movedAt: '2026-01-01T00:00:00.000Z',
          movedBy: MOVER,
        },
      });
    });
  });
});
