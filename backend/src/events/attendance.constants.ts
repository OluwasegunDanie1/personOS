import { AttendanceStatus } from '../../generated/prisma/client';

export const PUBLIC_ATTENDANCE_STATUS_VALUES = ['PRESENT', 'ABSENT', 'LATE'] as const;
export type PublicAttendanceStatus = (typeof PUBLIC_ATTENDANCE_STATUS_VALUES)[number];

export const DEFAULT_PUBLIC_ATTENDANCE_STATUS: PublicAttendanceStatus = 'PRESENT';

export const EVENT_ATTENDANCE_SORT_VALUES = ['checkedInAt_desc', 'checkedInAt_asc', 'personName_asc'] as const;
export type EventAttendanceSort = (typeof EVENT_ATTENDANCE_SORT_VALUES)[number];

export const PERSON_ATTENDANCE_SORT_VALUES = ['checkedInAt_desc', 'checkedInAt_asc', 'eventStartDate_desc'] as const;
export type PersonAttendanceSort = (typeof PERSON_ATTENDANCE_SORT_VALUES)[number];

export const DEFAULT_EVENT_ATTENDANCE_SORT: EventAttendanceSort = 'checkedInAt_desc';
export const DEFAULT_PERSON_ATTENDANCE_SORT: PersonAttendanceSort = 'checkedInAt_desc';

export const DEFAULT_ATTENDANCE_LIMIT = 50;
export const MIN_ATTENDANCE_LIMIT = 1;
export const MAX_ATTENDANCE_LIMIT = 100;

/**
 * The public v1 API surfaces uppercase status values; the Prisma persistence
 * enum (Present/Absent/Late) is never exposed to clients. Both directions of
 * this mapping are exhaustive over the closed value sets, per Product Task
 * 012's corrected authority.
 */
export const PUBLIC_TO_PRISMA_STATUS: Record<PublicAttendanceStatus, AttendanceStatus> = {
  PRESENT: AttendanceStatus.Present,
  ABSENT: AttendanceStatus.Absent,
  LATE: AttendanceStatus.Late,
};

export const PRISMA_TO_PUBLIC_STATUS: Record<AttendanceStatus, PublicAttendanceStatus> = {
  [AttendanceStatus.Present]: 'PRESENT',
  [AttendanceStatus.Absent]: 'ABSENT',
  [AttendanceStatus.Late]: 'LATE',
};
