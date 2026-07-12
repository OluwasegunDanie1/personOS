import { HttpStatus, Injectable } from '@nestjs/common';
import { ApiException } from '../common/http/api-exception';
import { PrismaService } from '../database/prisma.service';
import { CreateStageDto } from './dto/create-stage.dto';
import { ReorderStagesDto } from './dto/reorder-stages.dto';
import { UpdateStageDto } from './dto/update-stage.dto';
import { JOURNEY_ERROR_CODES } from './journey.constants';
import { OperationalTemplateService } from './operational-template.service';

export interface StageSummary {
  id: string;
  name: string;
  position: number;
}

interface StageRow {
  id: string;
  name: string;
  order: number;
}

@Injectable()
export class JourneyStagesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly operationalTemplate: OperationalTemplateService,
  ) {}

  async list(organizationId: string): Promise<{ stages: StageSummary[] }> {
    const template = await this.operationalTemplate.resolve(organizationId);

    const stages = (await this.prisma.journeyStage.findMany({
      where: { journeyTemplateId: template.id },
      orderBy: [{ order: 'asc' }, { id: 'asc' }],
      select: { id: true, name: true, order: true },
    })) as StageRow[];

    return { stages: stages.map((row) => this.toSummary(row)) };
  }

  async create(organizationId: string, dto: CreateStageDto): Promise<{ stage: StageSummary }> {
    const template = await this.operationalTemplate.resolve(organizationId);

    const aggregate = await this.prisma.journeyStage.aggregate({
      where: { journeyTemplateId: template.id },
      _max: { order: true },
    });

    const nextOrder = (aggregate._max.order ?? 0) + 1;

    const created = (await this.prisma.journeyStage.create({
      data: { journeyTemplateId: template.id, name: dto.name, order: nextOrder },
      select: { id: true, name: true, order: true },
    })) as StageRow;

    return { stage: this.toSummary(created) };
  }

  async update(organizationId: string, stageId: string, dto: UpdateStageDto): Promise<{ stage: StageSummary }> {
    if (dto.name === undefined) {
      throw new ApiException(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'VALIDATION_ERROR',
        'At least one field must be supplied.',
      );
    }

    const template = await this.operationalTemplate.resolve(organizationId);

    const existing = await this.prisma.journeyStage.findFirst({
      where: { id: stageId, journeyTemplateId: template.id },
      select: { id: true },
    });

    if (!existing) {
      throw this.stageNotFoundError();
    }

    const updated = (await this.prisma.journeyStage.update({
      where: { id: stageId },
      data: { name: dto.name },
      select: { id: true, name: true, order: true },
    })) as StageRow;

    return { stage: this.toSummary(updated) };
  }

  async reorder(organizationId: string, dto: ReorderStagesDto): Promise<{ stages: StageSummary[] }> {
    const template = await this.operationalTemplate.resolve(organizationId);

    const currentStages = await this.prisma.journeyStage.findMany({
      where: { journeyTemplateId: template.id },
      select: { id: true },
    });

    const currentIds = new Set(currentStages.map((stage) => stage.id));
    const suppliedIds = dto.stageIds;
    const suppliedIdSet = new Set(suppliedIds);

    const isExactSet =
      suppliedIds.length === currentStages.length &&
      suppliedIdSet.size === suppliedIds.length &&
      suppliedIds.every((id) => currentIds.has(id));

    if (!isExactSet) {
      throw this.invalidStageOrderError();
    }

    await this.prisma.$transaction(
      suppliedIds.map((id, index) =>
        this.prisma.journeyStage.update({
          where: { id },
          data: { order: index + 1 },
        }),
      ),
    );

    const stages = (await this.prisma.journeyStage.findMany({
      where: { journeyTemplateId: template.id },
      orderBy: [{ order: 'asc' }, { id: 'asc' }],
      select: { id: true, name: true, order: true },
    })) as StageRow[];

    return { stages: stages.map((row) => this.toSummary(row)) };
  }

  async remove(organizationId: string, stageId: string): Promise<{ success: true }> {
    const template = await this.operationalTemplate.resolve(organizationId);

    const existing = await this.prisma.journeyStage.findFirst({
      where: { id: stageId, journeyTemplateId: template.id },
      select: { id: true },
    });

    if (!existing) {
      throw this.stageNotFoundError();
    }

    const referenceCount = await this.prisma.personJourneyHistory.count({
      where: { OR: [{ fromStageId: stageId }, { toStageId: stageId }] },
    });

    if (referenceCount > 0) {
      throw this.stageInUseError();
    }

    await this.prisma.journeyStage.delete({ where: { id: stageId } });

    return { success: true };
  }

  private toSummary(row: StageRow): StageSummary {
    return { id: row.id, name: row.name, position: row.order };
  }

  private stageNotFoundError(): ApiException {
    return new ApiException(
      HttpStatus.NOT_FOUND,
      JOURNEY_ERROR_CODES.JOURNEY_STAGE_NOT_FOUND,
      'Journey stage not found.',
    );
  }

  private invalidStageOrderError(): ApiException {
    return new ApiException(
      HttpStatus.UNPROCESSABLE_ENTITY,
      JOURNEY_ERROR_CODES.INVALID_STAGE_ORDER,
      'The supplied stage order is invalid.',
    );
  }

  private stageInUseError(): ApiException {
    return new ApiException(
      HttpStatus.CONFLICT,
      JOURNEY_ERROR_CODES.JOURNEY_STAGE_IN_USE,
      'This journey stage is still in use.',
    );
  }
}
