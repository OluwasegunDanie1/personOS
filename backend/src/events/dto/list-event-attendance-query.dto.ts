import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import {
  EVENT_ATTENDANCE_SORT_VALUES,
  EventAttendanceSort,
  MAX_ATTENDANCE_LIMIT,
  MIN_ATTENDANCE_LIMIT,
  PUBLIC_ATTENDANCE_STATUS_VALUES,
  PublicAttendanceStatus,
} from '../attendance.constants';

export class ListEventAttendanceQueryDto {
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
  @IsIn(PUBLIC_ATTENDANCE_STATUS_VALUES)
  status?: PublicAttendanceStatus;

  @IsOptional()
  @IsIn(EVENT_ATTENDANCE_SORT_VALUES)
  sort?: EventAttendanceSort;
}
