import { Transform } from 'class-transformer';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';
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

export class CreateEventDto {
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
  @IsString()
  category?: string | null;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsString()
  venue?: string | null;

  @IsAbsoluteInstant()
  startDate!: string;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsAbsoluteInstant()
  endDate?: string | null;
}
