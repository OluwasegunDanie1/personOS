export const DEFAULT_NOTIFICATION_LIMIT = 20;
export const MIN_NOTIFICATION_LIMIT = 1;
export const MAX_NOTIFICATION_LIMIT = 100;

/**
 * There is exactly one deterministic list order (createdAt desc, id asc
 * tie-break) — no client-selectable sort exists, unlike Events/Follow-ups.
 * This discriminator only guards the opaque cursor against reuse if a
 * second sort is ever introduced later.
 */
export const NOTIFICATION_SORT = 'createdAt_desc' as const;
export type NotificationSort = typeof NOTIFICATION_SORT;

export const NOTIFICATION_ERROR_CODES = {
  NOTIFICATION_NOT_FOUND: 'NOTIFICATION_NOT_FOUND',
} as const;
