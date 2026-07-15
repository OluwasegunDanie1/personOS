import { Transform } from 'class-transformer';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

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

// industry/country/timezone are real, existing Organization columns
// (Product Task 092) — previously dormant schema the API rejected as
// unknown fields. All three are optional free-form strings: no approved
// enum/finite list exists for organization type or country, and no
// timezone database is part of this app's authority, so none is invented
// here (Product Task 090B/092 rulings).
export class CreateOrganizationDto {
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  name!: string;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsString()
  industry?: string | null;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsString()
  country?: string | null;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsString()
  timezone?: string | null;
}
