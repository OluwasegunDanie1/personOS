import { HttpStatus } from '@nestjs/common';
import { ApiException } from '../common/http/api-exception';
import { NotificationSort } from './notifications.constants';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface CursorPayload {
  id: string;
  sort: NotificationSort;
}

/**
 * Opaque, sort-bound cursor mirroring events/cursor.util.ts and
 * people/cursor.util.ts exactly (each domain module owns its own copy per
 * repository convention). Only id (Prisma's native cursor+skip:1
 * mechanism) plus a sort discriminator are encoded; internal encoding is
 * not part of the public API contract.
 */
export function encodeCursor(payload: CursorPayload): string {
  return Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
}

export function decodeCursor(cursor: string, expectedSort: NotificationSort): string {
  let parsed: unknown;

  try {
    parsed = JSON.parse(Buffer.from(cursor, 'base64url').toString('utf8'));
  } catch {
    throw invalidCursorError();
  }

  if (
    typeof parsed !== 'object' ||
    parsed === null ||
    typeof (parsed as Record<string, unknown>).id !== 'string' ||
    typeof (parsed as Record<string, unknown>).sort !== 'string'
  ) {
    throw invalidCursorError();
  }

  const payload = parsed as CursorPayload;

  if (!UUID_PATTERN.test(payload.id)) {
    throw invalidCursorError();
  }

  if (payload.sort !== expectedSort) {
    throw invalidCursorError();
  }

  return payload.id;
}

function invalidCursorError(): ApiException {
  return new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, 'VALIDATION_ERROR', 'The supplied cursor is invalid.');
}
