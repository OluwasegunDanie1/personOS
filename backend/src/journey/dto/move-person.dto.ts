import { Transform } from 'class-transformer';
import { IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';

function normalizeNullable({ value }: { value: unknown }): unknown {
  if (typeof value !== 'string') {
    return value;
  }
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

export class MovePersonDto {
  @IsUUID()
  @IsNotEmpty()
  stageId!: string;

  @IsOptional()
  @Transform(normalizeNullable)
  @IsString()
  note?: string | null;
}
