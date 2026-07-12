import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, IsUUID, Max, Min } from 'class-validator';
import { MAX_PEOPLE_LIMIT, MIN_PEOPLE_LIMIT, PEOPLE_SORT_VALUES, PeopleSort, PERSON_STATUS_VALUES, PersonStatusValue } from '../people.constants';

export class ListPeopleQueryDto {
  @IsOptional()
  @IsString()
  cursor?: string;

  @IsOptional()
  @Transform(({ value }) => (value === undefined || value === '' ? undefined : Number(value)))
  @IsInt()
  @Min(MIN_PEOPLE_LIMIT)
  @Max(MAX_PEOPLE_LIMIT)
  limit?: number;

  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  search?: string;

  @IsOptional()
  @IsUUID()
  journeyStageId?: string;

  @IsOptional()
  @IsIn(PERSON_STATUS_VALUES)
  status?: PersonStatusValue;

  @IsOptional()
  @IsIn(PEOPLE_SORT_VALUES)
  sort?: PeopleSort;
}
