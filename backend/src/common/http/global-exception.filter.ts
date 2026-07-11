import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from '@nestjs/common';
import { ApiException } from './api-exception';

interface HttpResponseLike {
  status(code: number): { json(body: unknown): void };
}

interface ErrorEnvelope {
  success: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
}

interface NormalizedError {
  status: number;
  code: string;
  message: string;
  details?: unknown;
}

const GENERIC_HTTP_STATUS_CODES: Record<number, string> = {
  400: 'BAD_REQUEST',
  401: 'UNAUTHORIZED',
  403: 'FORBIDDEN',
  404: 'NOT_FOUND',
  409: 'CONFLICT',
  422: 'UNPROCESSABLE_ENTITY',
  429: 'TOO_MANY_REQUESTS',
};

const GENERIC_ERROR_MESSAGE = 'An unexpected error occurred. Please try again.';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<HttpResponseLike>();
    const normalized = this.normalize(exception);

    const body: ErrorEnvelope = {
      success: false,
      error: {
        code: normalized.code,
        message: normalized.message,
        ...(normalized.details !== undefined ? { details: normalized.details } : {}),
      },
    };

    response.status(normalized.status).json(body);
  }

  private normalize(exception: unknown): NormalizedError {
    if (exception instanceof ApiException) {
      return {
        status: exception.getStatus(),
        code: exception.code,
        message: exception.message,
        details: exception.details,
      };
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const responseBody = exception.getResponse();

      return {
        status,
        code: this.codeForStatus(status),
        message: this.extractMessage(responseBody, exception.message),
        details: this.extractDetails(responseBody),
      };
    }

    return {
      status: HttpStatus.INTERNAL_SERVER_ERROR,
      code: 'INTERNAL_SERVER_ERROR',
      message: GENERIC_ERROR_MESSAGE,
    };
  }

  private codeForStatus(status: number): string {
    if (GENERIC_HTTP_STATUS_CODES[status]) {
      return GENERIC_HTTP_STATUS_CODES[status];
    }

    if (status >= 500) {
      return 'INTERNAL_SERVER_ERROR';
    }

    return `HTTP_${status}`;
  }

  private extractMessage(responseBody: unknown, fallback: string): string {
    if (typeof responseBody === 'object' && responseBody !== null && 'message' in responseBody) {
      const message = (responseBody as Record<string, unknown>).message;

      if (typeof message === 'string') {
        return message;
      }
    }

    return fallback;
  }

  private extractDetails(responseBody: unknown): unknown {
    if (typeof responseBody === 'object' && responseBody !== null && 'message' in responseBody) {
      const message = (responseBody as Record<string, unknown>).message;

      if (Array.isArray(message) || (typeof message === 'object' && message !== null)) {
        return message;
      }
    }

    return undefined;
  }
}
