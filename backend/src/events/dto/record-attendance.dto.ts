import { IsIn, IsOptional, IsUUID } from 'class-validator';
import { PUBLIC_ATTENDANCE_STATUS_VALUES, PublicAttendanceStatus } from '../attendance.constants';

export class RecordAttendanceDto {
  @IsUUID()
  personId!: string;

  @IsOptional()
  @IsIn(PUBLIC_ATTENDANCE_STATUS_VALUES)
  status?: PublicAttendanceStatus;
}
