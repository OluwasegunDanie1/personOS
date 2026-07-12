import {
  registerDecorator,
  ValidationOptions,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';

const ABSOLUTE_INSTANT_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,3})?(Z|[+-]\d{2}:\d{2})$/;

@ValidatorConstraint({ name: 'isAbsoluteInstant', async: false })
class IsAbsoluteInstantConstraint implements ValidatorConstraintInterface {
  validate(value: unknown): boolean {
    if (typeof value !== 'string' || !ABSOLUTE_INSTANT_PATTERN.test(value)) {
      return false;
    }

    return !Number.isNaN(new Date(value).getTime());
  }

  defaultMessage(): string {
    return 'must be an ISO 8601 datetime with an explicit UTC offset or Z suffix';
  }
}

/**
 * Rejects date-only and offset-less local datetime strings, per the approved
 * "ISO 8601 absolute instant" Event date contract (13_API_Specification.md);
 * a plain @IsISO8601 alone does not enforce the offset requirement.
 */
export function IsAbsoluteInstant(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string): void {
    registerDecorator({
      name: 'isAbsoluteInstant',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: IsAbsoluteInstantConstraint,
    });
  };
}
