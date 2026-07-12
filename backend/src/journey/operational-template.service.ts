import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

export interface OperationalTemplateRef {
  id: string;
}

/**
 * Resolves the Organization's single v1 operational JourneyTemplate. This is
 * an internal application invariant, not a schema constraint: the schema
 * structurally permits multiple JourneyTemplate rows per organization, but
 * v1 application behavior never creates or exposes more than one. Zero or
 * multiple rows are invariant violations, not public API conditions — no
 * public Journey API error code is defined for them (per Task 009
 * authority), so these surface as plain internal errors normalized safely
 * by the existing GlobalExceptionFilter (never a stack trace or detail).
 */
@Injectable()
export class OperationalTemplateService {
  constructor(private readonly prisma: PrismaService) {}

  async resolve(organizationId: string): Promise<OperationalTemplateRef> {
    const templates = await this.prisma.journeyTemplate.findMany({
      where: { organizationId },
      select: { id: true },
    });

    if (templates.length === 0) {
      throw new Error('No operational JourneyTemplate exists for this organization.');
    }

    if (templates.length > 1) {
      throw new Error('Multiple JourneyTemplate rows exist for this organization; the operational template is ambiguous.');
    }

    return templates[0];
  }
}
