import {
  registerDecorator,
  ValidationOptions,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';

const CALENDAR_DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;

function parseCalendarDateParts(value: string): { year: number; month: number; day: number } | null {
  const match = CALENDAR_DATE_PATTERN.exec(value);
  if (!match) {
    return null;
  }

  return { year: Number(match[1]), month: Number(match[2]), day: Number(match[3]) };
}

function isRealCalendarDate(year: number, month: number, day: number): boolean {
  const asUtc = new Date(Date.UTC(year, month - 1, day));
  return asUtc.getUTCFullYear() === year && asUtc.getUTCMonth() === month - 1 && asUtc.getUTCDate() === day;
}

@ValidatorConstraint({ name: 'isCalendarDateOnly', async: false })
class IsCalendarDateOnlyConstraint implements ValidatorConstraintInterface {
  validate(value: unknown): boolean {
    if (typeof value !== 'string') {
      return false;
    }

    const parts = parseCalendarDateParts(value);
    if (!parts) {
      return false;
    }

    return isRealCalendarDate(parts.year, parts.month, parts.day);
  }

  defaultMessage(): string {
    return 'must be a real calendar date in YYYY-MM-DD format';
  }
}

/**
 * Accepts exactly YYYY-MM-DD and rejects anything JavaScript's Date would
 * otherwise silently roll over (e.g. 2025-02-30), per the approved
 * date-of-birth-is-a-calendar-date-not-an-instant contract
 * (13_API_Specification.md). This is the inverse of IsAbsoluteInstant
 * (events/absolute-instant.validator.ts), which requires a datetime with an
 * explicit offset and rejects date-only values; dateOfBirth must reject
 * datetime values and accept only the date-only form.
 */
export function IsCalendarDateOnly(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string): void {
    registerDecorator({
      name: 'isCalendarDateOnly',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: IsCalendarDateOnlyConstraint,
    });
  };
}

/**
 * Converts an already-validated YYYY-MM-DD string into a UTC midnight Date
 * for Prisma's @db.Date column, so the stored calendar day never shifts
 * regardless of server timezone.
 */
export function parseCalendarDateOnlyToUtcDate(value: string): Date {
  const parts = parseCalendarDateParts(value);
  if (!parts) {
    throw new Error(`Invalid calendar date passed to parseCalendarDateOnlyToUtcDate: ${value}`);
  }

  return new Date(Date.UTC(parts.year, parts.month - 1, parts.day));
}
