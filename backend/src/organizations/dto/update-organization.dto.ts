import { Transform } from 'class-transformer';
import { IsNotEmpty, IsOptional, IsString, ValidateIf } from 'class-validator';

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

// Product Task 092: name, industry, country, and timezone are all now real,
// independently optional, partially-updatable fields — a genuine partial
// update accepts any non-empty subset of them. name is never nullable (an
// Organization always has a name), so it uses the same "present-but-null
// rejected, absent allowed" @ValidateIf pattern already established for
// Person's never-clearable fields; industry/country/timezone may be
// explicitly cleared to null, matching Person's optional-field convention.
export class UpdateOrganizationDto {
  @ValidateIf((_object: unknown, value: unknown) => value !== undefined)
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  name?: string;

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
