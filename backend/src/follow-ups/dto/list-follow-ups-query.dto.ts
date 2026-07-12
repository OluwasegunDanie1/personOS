import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, IsUUID, Max, Min } from 'class-validator';
import { IsAbsoluteInstant } from '../../events/absolute-instant.validator';
import {
  FOLLOW_UP_SORT_VALUES,
  FOLLOW_UP_STATUS_VALUES,
  FollowUpSort,
  FollowUpStatus,
  MAX_FOLLOW_UP_LIMIT,
  MIN_FOLLOW_UP_LIMIT,
} from '../follow-ups.constants';

export class ListFollowUpsQueryDto {
  @IsOptional()
  @IsString()
  cursor?: string;

  @IsOptional()
  @Transform(({ value }) => (value === undefined || value === '' ? undefined : Number(value)))
  @IsInt()
  @Min(MIN_FOLLOW_UP_LIMIT)
  @Max(MAX_FOLLOW_UP_LIMIT)
  limit?: number;

  @IsOptional()
  @IsIn(FOLLOW_UP_STATUS_VALUES)
  status?: FollowUpStatus;

  // Approved query parameter names are snake_case exactly as documented in
  // 13_API_Specification.md; they are not renamed to camelCase here.
  @IsOptional()
  @IsUUID()
  assigned_user_id?: string;

  @IsOptional()
  @IsUUID()
  person_id?: string;

  @IsOptional()
  @IsAbsoluteInstant()
  due_date?: string;

  @IsOptional()
  @IsIn(FOLLOW_UP_SORT_VALUES)
  sort?: FollowUpSort;
}
