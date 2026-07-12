export const EVENT_SORT_VALUES = ['startDate_asc', 'startDate_desc', 'createdAt_desc', 'title_asc'] as const;
export type EventSort = (typeof EVENT_SORT_VALUES)[number];

export const DEFAULT_EVENT_SORT: EventSort = 'startDate_desc';

export const DEFAULT_EVENT_LIMIT = 20;
export const MIN_EVENT_LIMIT = 1;
export const MAX_EVENT_LIMIT = 100;

export const EVENT_ERROR_CODES = {
  EVENT_NOT_FOUND: 'EVENT_NOT_FOUND',
  INVALID_EVENT_DATE_RANGE: 'INVALID_EVENT_DATE_RANGE',
} as const;
