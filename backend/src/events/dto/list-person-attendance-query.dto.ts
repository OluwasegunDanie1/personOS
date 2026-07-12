import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import {
  MAX_ATTENDANCE_LIMIT,
  MIN_ATTENDANCE_LIMIT,
  PERSON_ATTENDANCE_SORT_VALUES,
  PersonAttendanceSort,
} from '../attendance.constants';

export class ListPersonAttendanceQueryDto {
  @IsOptional()
  @IsString()
  cursor?: string;

  @IsOptional()
  @Transform(({ value }) => (value === undefined || value === '' ? undefined : Number(value)))
  @IsInt()
  @Min(MIN_ATTENDANCE_LIMIT)
  @Max(MAX_ATTENDANCE_LIMIT)
  limit?: number;

  @IsOptional()
  @IsIn(PERSON_ATTENDANCE_SORT_VALUES)
  sort?: PersonAttendanceSort;
}
