import { Transform } from 'class-transformer';
import { IsIn, IsNotEmpty, IsOptional, IsString, IsUUID, ValidateIf } from 'class-validator';
import { IsAbsoluteInstant } from '../../events/absolute-instant.validator';
import { FOLLOW_UP_UPDATABLE_STATUS_VALUES, FollowUpUpdatableStatus } from '../follow-ups.constants';

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

export class UpdateFollowUpDto {
  // Present-but-null must be rejected (title is never clearable), while
  // absent (undefined) must be allowed through untouched.
  @ValidateIf((_object: unknown, value: unknown) => value !== undefined)
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  title?: string;

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

  // COMPLETED is never an accepted value here; the dedicated Complete
  // Follow-Up endpoint is the sole path to that status.
  @IsOptional()
  @IsIn(FOLLOW_UP_UPDATABLE_STATUS_VALUES)
  status?: FollowUpUpdatableStatus;
}
