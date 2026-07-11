import { HttpException } from '@nestjs/common';

/**
 * Base exception for approved machine-readable API errors. Producing this
 * (rather than a plain HttpException) guarantees the response carries an
 * explicit code and, optionally, safely representable details.
 */
export class ApiException extends HttpException {
  public readonly code: string;
  public readonly details?: unknown;

  constructor(status: number, code: string, message: string, details?: unknown) {
    super({ code, message, details }, status);
    this.code = code;
    this.details = details;
  }
}
