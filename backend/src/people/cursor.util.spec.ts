import { decodeCursor, encodeCursor } from './cursor.util';

const VALID_ID = '11111111-1111-1111-1111-111111111111';

describe('cursor.util', () => {
  it('round-trips id and sort through encode/decode', () => {
    const cursor = encodeCursor({ id: VALID_ID, sort: 'name_asc' });

    const decodedId = decodeCursor(cursor, 'name_asc');

    expect(decodedId).toBe(VALID_ID);
  });

  it('does not expose id/sort in plain text in the encoded string', () => {
    const cursor = encodeCursor({ id: VALID_ID, sort: 'name_asc' });

    expect(cursor).not.toContain(VALID_ID);
    expect(cursor).not.toContain('name_asc');
  });

  it('rejects a cursor generated for a different sort', () => {
    const cursor = encodeCursor({ id: VALID_ID, sort: 'name_asc' });

    expect(() => decodeCursor(cursor, 'newest')).toThrow();
  });

  it('rejects a malformed (non-base64/non-JSON) cursor without leaking internal detail', () => {
    let error: Error | undefined;
    try {
      decodeCursor('not-a-valid-cursor!!!', 'name_asc');
    } catch (e) {
      error = e as Error;
    }

    expect(error).toBeDefined();
    expect((error as { code?: string }).code).toBe('VALIDATION_ERROR');
  });

  it('rejects a decoded cursor whose id is not UUID-shaped', () => {
    const cursor = Buffer.from(JSON.stringify({ id: 'not-a-uuid', sort: 'name_asc' })).toString('base64url');

    expect(() => decodeCursor(cursor, 'name_asc')).toThrow();
  });

  it('rejects a decoded cursor missing required fields', () => {
    const cursor = Buffer.from(JSON.stringify({ id: VALID_ID })).toString('base64url');

    expect(() => decodeCursor(cursor, 'name_asc')).toThrow();
  });
});
