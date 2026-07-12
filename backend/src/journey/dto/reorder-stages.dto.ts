import { ArrayNotEmpty, IsArray, IsUUID } from 'class-validator';

export class ReorderStagesDto {
  @IsArray()
  @ArrayNotEmpty()
  @IsUUID('all', { each: true })
  stageIds!: string[];
}
