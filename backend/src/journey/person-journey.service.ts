import { HttpStatus, Injectable } from '@nestjs/common';
import { ApiException } from '../common/http/api-exception';
import { PrismaService } from '../database/prisma.service';
import { PEOPLE_ERROR_CODES } from '../people/people.constants';
import { MovePersonDto } from './dto/move-person.dto';
import { JOURNEY_ERROR_CODES } from './journey.constants';
import { OperationalTemplateService } from './operational-template.service';

export interface StageRef {
  id: string;
  name: string;
}

export interface MoverRef {
  id: string;
  firstName: string;
  lastName: string;
}

export interface JourneyHistoryEntry {
  id: string;
  fromStage: StageRef | null;
  toStage: StageRef;
  note: string | null;
  movedAt: string;
  movedBy: MoverRef;
}

export interface PersonJourneyView {
  currentJourneyStage: (StageRef & { position: number }) | null;
  history: JourneyHistoryEntry[];
}

export interface MovementResult {
  movement: JourneyHistoryEntry;
}

interface HistoryRow {
  id: string;
  notes: string | null;
  movedAt: Date;
  fromStage: StageRef | null;
  toStage: StageRef;
  movedByUser: MoverRef | null;
}

@Injectable()
export class PersonJourneyService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly operationalTemplate: OperationalTemplateService,
  ) {}

  async view(organizationId: string, personId: string): Promise<PersonJourneyView> {
    const person = await this.prisma.person.findFirst({
      where: { id: personId, organizationId, deletedAt: null },
      select: { id: true },
    });

    if (!person) {
      throw this.personNotFoundError();
    }

    const historyRows = (await this.prisma.personJourneyHistory.findMany({
      where: { personId },
      orderBy: [{ movedAt: 'desc' }, { id: 'desc' }],
      select: {
        id: true,
        notes: true,
        movedAt: true,
        fromStage: { select: { id: true, name: true } },
        toStage: { select: { id: true, name: true, order: true } },
        movedByUser: { select: { id: true, firstName: true, lastName: true } },
      },
    })) as Array<HistoryRow & { toStage: StageRef & { order: number } }>;

    const history = historyRows.map((row) => this.toHistoryEntry(row));

    const latest = historyRows[0];
    const currentJourneyStage = latest
      ? { id: latest.toStage.id, name: latest.toStage.name, position: latest.toStage.order }
      : null;

    return { currentJourneyStage, history };
  }

  async move(
    organizationId: string,
    personId: string,
    userId: string,
    dto: MovePersonDto,
  ): Promise<MovementResult> {
    const person = await this.prisma.person.findFirst({
      where: { id: personId, organizationId, deletedAt: null },
      select: { id: true },
    });

    if (!person) {
      throw this.personNotFoundError();
    }

    const template = await this.operationalTemplate.resolve(organizationId);

    const targetStage = await this.prisma.journeyStage.findFirst({
      where: { id: dto.stageId, journeyTemplateId: template.id },
      select: { id: true, name: true },
    });

    if (!targetStage) {
      throw this.stageNotFoundError();
    }

    const latest = await this.prisma.personJourneyHistory.findFirst({
      where: { personId },
      orderBy: [{ movedAt: 'desc' }, { id: 'desc' }],
      select: { toStageId: true },
    });

    if (latest && latest.toStageId === dto.stageId) {
      throw this.alreadyInStageError();
    }

    const created = (await this.prisma.personJourneyHistory.create({
      data: {
        personId,
        fromStageId: latest ? latest.toStageId : null,
        toStageId: dto.stageId,
        movedBy: userId,
        movedAt: new Date(),
        notes: dto.note ?? null,
      },
      select: {
        id: true,
        notes: true,
        movedAt: true,
        fromStage: { select: { id: true, name: true } },
        toStage: { select: { id: true, name: true } },
        movedByUser: { select: { id: true, firstName: true, lastName: true } },
      },
    })) as HistoryRow;

    return { movement: this.toHistoryEntry(created) };
  }

  private toHistoryEntry(row: HistoryRow): JourneyHistoryEntry {
    return {
      id: row.id,
      fromStage: row.fromStage,
      toStage: row.toStage,
      note: row.notes,
      movedAt: row.movedAt.toISOString(),
      movedBy: row.movedByUser as MoverRef,
    };
  }

  private personNotFoundError(): ApiException {
    return new ApiException(HttpStatus.NOT_FOUND, PEOPLE_ERROR_CODES.PERSON_NOT_FOUND, 'Person not found.');
  }

  private stageNotFoundError(): ApiException {
    return new ApiException(
      HttpStatus.NOT_FOUND,
      JOURNEY_ERROR_CODES.JOURNEY_STAGE_NOT_FOUND,
      'Journey stage not found.',
    );
  }

  private alreadyInStageError(): ApiException {
    return new ApiException(
      HttpStatus.CONFLICT,
      JOURNEY_ERROR_CODES.PERSON_ALREADY_IN_STAGE,
      'This Person is already in the requested stage.',
    );
  }
}
