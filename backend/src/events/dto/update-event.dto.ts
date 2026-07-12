import { Transform } from 'class-transformer';
import { IsNotEmpty, IsOptional, IsString, ValidateIf } from 'class-validator';
import { IsAbsoluteInstant } from '../absolute-instant.validator';

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

export class UpdateEventDto {
  // Present-but-null must be rejected (title/startDate are never
  // clearable), while absent (undefined) must be allowed through untouched.
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
  @IsString()
  category?: string | null;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsString()
  venue?: string | null;

  @ValidateIf((_object: unknown, value: unknown) => value !== undefined)
  @IsAbsoluteInstant()
  startDate?: string;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsAbsoluteInstant()
  endDate?: string | null;
}
