import { Transform } from 'class-transformer';
import { IsEmail, IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';
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

export class CreatePersonDto {
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  firstName!: string;

  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  lastName!: string;

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

  @IsOptional()
  @IsIn(PERSON_GENDER_VALUES)
  gender?: PersonGenderValue;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsCalendarDateOnly()
  dateOfBirth?: string | null;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsString()
  address?: string | null;
}
