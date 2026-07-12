export const FOLLOW_UP_STATUS_VALUES = ['PENDING', 'IN_PROGRESS', 'COMPLETED'] as const;
export type FollowUpStatus = (typeof FOLLOW_UP_STATUS_VALUES)[number];

// Update Follow-Up may only ever write these two values; COMPLETED is
// reachable exclusively through the dedicated Complete Follow-Up endpoint.
export const FOLLOW_UP_UPDATABLE_STATUS_VALUES = ['PENDING', 'IN_PROGRESS'] as const;
export type FollowUpUpdatableStatus = (typeof FOLLOW_UP_UPDATABLE_STATUS_VALUES)[number];

export const DEFAULT_FOLLOW_UP_STATUS: FollowUpStatus = 'PENDING';
export const COMPLETED_FOLLOW_UP_STATUS: FollowUpStatus = 'COMPLETED';

export const FOLLOW_UP_SORT_VALUES = ['dueDate_asc', 'dueDate_desc', 'title_asc'] as const;
export type FollowUpSort = (typeof FOLLOW_UP_SORT_VALUES)[number];

export const DEFAULT_FOLLOW_UP_SORT: FollowUpSort = 'dueDate_asc';

export const DEFAULT_FOLLOW_UP_LIMIT = 20;
export const MIN_FOLLOW_UP_LIMIT = 1;
export const MAX_FOLLOW_UP_LIMIT = 100;

export const FOLLOW_UP_ERROR_CODES = {
  FOLLOW_UP_NOT_FOUND: 'FOLLOW_UP_NOT_FOUND',
  ASSIGNED_USER_NOT_FOUND: 'ASSIGNED_USER_NOT_FOUND',
  FOLLOW_UP_ALREADY_COMPLETED: 'FOLLOW_UP_ALREADY_COMPLETED',
} as const;
