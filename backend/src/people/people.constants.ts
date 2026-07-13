export const PERSON_STATUS_VALUES = ['ACTIVE', 'INACTIVE'] as const;
export type PersonStatusValue = (typeof PERSON_STATUS_VALUES)[number];

export const PERSON_GENDER_VALUES = ['MALE', 'FEMALE'] as const;
export type PersonGenderValue = (typeof PERSON_GENDER_VALUES)[number];

export const PEOPLE_SORT_VALUES = ['name_asc', 'name_desc', 'newest', 'oldest'] as const;
export type PeopleSort = (typeof PEOPLE_SORT_VALUES)[number];

export const DEFAULT_PEOPLE_LIMIT = 20;
export const MIN_PEOPLE_LIMIT = 1;
export const MAX_PEOPLE_LIMIT = 100;

export const PEOPLE_ERROR_CODES = {
  PERSON_NOT_FOUND: 'PERSON_NOT_FOUND',
  JOURNEY_STAGE_NOT_FOUND: 'JOURNEY_STAGE_NOT_FOUND',
} as const;
