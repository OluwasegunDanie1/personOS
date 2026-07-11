import { ArgumentsHost, BadRequestException, HttpStatus, NotFoundException } from '@nestjs/common';
import { ApiException } from './api-exception';
import { GlobalExceptionFilter } from './global-exception.filter';

function mockHost() {
  const json = jest.fn();
  const status = jest.fn().mockReturnValue({ json });
  const getResponse = jest.fn().mockReturnValue({ status });

  const host = {
    switchToHttp: () => ({ getResponse }),
  } as unknown as ArgumentsHost;

  return { host, status, json };
}

describe('GlobalExceptionFilter', () => {
  const filter = new GlobalExceptionFilter();

  it('preserves status/code/message/details for an approved ApiException', () => {
    const { host, status, json } = mockHost();
    const exception = new ApiException(HttpStatus.CONFLICT, 'PERSON_EMAIL_EXISTS', 'A person with this email already exists.', { field: 'email' });

    filter.catch(exception, host);

    expect(status).toHaveBeenCalledWith(HttpStatus.CONFLICT);
    expect(json).toHaveBeenCalledWith({
      success: false,
      error: {
        code: 'PERSON_EMAIL_EXISTS',
        message: 'A person with this email already exists.',
        details: { field: 'email' },
      },
    });
  });

  it('normalizes a standard 404 HttpException to NOT_FOUND', () => {
    const { host, status, json } = mockHost();

    filter.catch(new NotFoundException(), host);

    expect(status).toHaveBeenCalledWith(HttpStatus.NOT_FOUND);
    expect(json).toHaveBeenCalledWith({
      success: false,
      error: { code: 'NOT_FOUND', message: 'Not Found' },
    });
  });

  it('safely preserves validation-style 400 details', () => {
    const { host, status, json } = mockHost();

    filter.catch(new BadRequestException(['email must be valid', 'name should not be empty']), host);

    expect(status).toHaveBeenCalledWith(HttpStatus.BAD_REQUEST);
    expect(json).toHaveBeenCalledWith({
      success: false,
      error: {
        code: 'BAD_REQUEST',
        message: 'Bad Request Exception',
        details: ['email must be valid', 'name should not be empty'],
      },
    });
  });

  it('normalizes an unknown error to a safe INTERNAL_SERVER_ERROR', () => {
    const { host, status, json } = mockHost();

    filter.catch(new Error('secret database connection string leaked'), host);

    expect(status).toHaveBeenCalledWith(HttpStatus.INTERNAL_SERVER_ERROR);
    expect(json).toHaveBeenCalledWith({
      success: false,
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'An unexpected error occurred. Please try again.',
      },
    });
  });

  it('does not expose the original message of an unknown error', () => {
    const { host, json } = mockHost();

    filter.catch(new Error('secret database connection string leaked'), host);

    const body = json.mock.calls[0][0];
    expect(JSON.stringify(body)).not.toContain('secret database connection string leaked');
  });
});
