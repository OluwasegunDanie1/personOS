import { Transform } from 'class-transformer';
import { IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';
import { IsAbsoluteInstant } from '../../events/absolute-instant.validator';

function trim({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

function normalizeNullable({ value }: { value: unknown }): unknown {
  if (typeof value !== 'string') {
    return value;
  }
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

export class CreateFollowUpDto {
  @IsUUID()
  personId!: string;

  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  title!: string;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsString()
  description?: string | null;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsAbsoluteInstant()
  dueDate?: string | null;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsUUID()
  assignedTo?: string | null;
}
