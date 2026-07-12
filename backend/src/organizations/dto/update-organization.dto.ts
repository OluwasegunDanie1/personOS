import { Transform } from 'class-transformer';
import { IsNotEmpty, IsString } from 'class-validator';

function trim({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

// name is the only approved mutable field, and it is required (not
// optional): with a single-field contract, "at least one field supplied"
// reduces to "name must be present," so an empty body is rejected by this
// DTO's own required validation rather than a separate service-level check.
export class UpdateOrganizationDto {
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  name!: string;
}
