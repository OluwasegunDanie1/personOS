import { Transform } from 'class-transformer';
import { IsEmail, IsIn, IsNotEmpty, IsOptional, IsString, ValidateIf } from 'class-validator';
import { PERSON_STATUS_VALUES, PersonStatusValue } from '../people.constants';

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

export class UpdatePersonDto {
  // Present-but-null must be rejected (firstName/lastName are never
  // clearable), while absent (undefined) must be allowed through untouched.
  @ValidateIf((_object: unknown, value: unknown) => value !== undefined)
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  firstName?: string;

  @ValidateIf((_object: unknown, value: unknown) => value !== undefined)
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  lastName?: string;

  @IsOptional()
  @Transform(({ value }) => {
    const normalized = normalizeNullable({ value });
    return typeof normalized === 'string' ? normalized.toLowerCase() : normalized;
  })
  @IsEmail()
  email?: string | null;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsString()
  phone?: string | null;

  @IsOptional()
  @IsIn(PERSON_STATUS_VALUES)
  status?: PersonStatusValue;
}
