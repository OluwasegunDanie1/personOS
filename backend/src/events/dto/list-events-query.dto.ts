import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { EVENT_SORT_VALUES, EventSort, MAX_EVENT_LIMIT, MIN_EVENT_LIMIT } from '../events.constants';

export class ListEventsQueryDto {
  @IsOptional()
  @IsString()
  cursor?: string;

  @IsOptional()
  @Transform(({ value }) => (value === undefined || value === '' ? undefined : Number(value)))
  @IsInt()
  @Min(MIN_EVENT_LIMIT)
  @Max(MAX_EVENT_LIMIT)
  limit?: number;

  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  search?: string;

  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  category?: string;

  @IsOptional()
  @IsIn(EVENT_SORT_VALUES)
  sort?: EventSort;
}
