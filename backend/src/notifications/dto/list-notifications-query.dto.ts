import { Transform } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { MAX_NOTIFICATION_LIMIT, MIN_NOTIFICATION_LIMIT } from '../notifications.constants';

/**
 * Only fields with real Notification schema backing are accepted: cursor,
 * limit, and read (mapping directly to Notification.isRead). There is no
 * category column on Notification, so no category filter is declared here
 * — the global ValidationPipe's forbidNonWhitelisted rejects one if sent.
 */
export class ListNotificationsQueryDto {
  @IsOptional()
  @IsString()
  cursor?: string;

  @IsOptional()
  @Transform(({ value }) => (value === undefined || value === '' ? undefined : Number(value)))
  @IsInt()
  @Min(MIN_NOTIFICATION_LIMIT)
  @Max(MAX_NOTIFICATION_LIMIT)
  limit?: number;

  @IsOptional()
  @IsIn(['true', 'false'])
  read?: string;
}
