import { Transform } from 'class-transformer';
import { IsEmail, IsIn, IsNotEmpty, IsOptional, IsString, ValidateIf } from 'class-validator';
import { IsCalendarDateOnly } from '../date-of-birth.validator';
import { PERSON_GENDER_VALUES, PERSON_STATUS_VALUES, PersonGenderValue, PersonStatusValue } from '../people.constants';

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

  // Same @IsOptional() + @IsIn() pattern as Create Person's gender field.
  // @IsOptional() treats an explicit null as "skip further validation," so a
  // client-supplied null passes through untouched (never rejected by IsIn,
  // never coerced to undefined) — this is what lets the service below
  // distinguish "omitted" (property absent) from "explicitly cleared"
  // (property present with value null), the same distinction email/phone
  // already rely on.
  @IsOptional()
  @IsIn(PERSON_GENDER_VALUES)
  gender?: PersonGenderValue | null;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsCalendarDateOnly()
  dateOfBirth?: string | null;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsString()
  address?: string | null;
}
