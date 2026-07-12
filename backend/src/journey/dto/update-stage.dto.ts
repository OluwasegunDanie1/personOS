import { Transform } from 'class-transformer';
import { IsNotEmpty, IsString, ValidateIf } from 'class-validator';

function trim({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class UpdateStageDto {
  // Absent (undefined) is allowed through untouched; present-but-null/empty
  // is rejected by IsString/IsNotEmpty. The service additionally requires
  // this single field to be present at all (at least one field supplied).
  @ValidateIf((_object: unknown, value: unknown) => value !== undefined)
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  name?: string;
}
