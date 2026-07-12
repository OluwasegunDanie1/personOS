import { Transform } from 'class-transformer';
import { IsNotEmpty, IsString } from 'class-validator';

function trim({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class CreateOrganizationDto {
  @Transform(trim)
  @IsString()
  @IsNotEmpty()
  name!: string;
}
