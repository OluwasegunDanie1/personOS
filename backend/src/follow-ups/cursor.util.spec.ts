import { decodeCursor, encodeCursor } from './cursor.util';

const VALID_ID = '11111111-1111-1111-1111-111111111111';

describe('follow-ups/cursor.util', () => {
  it('round-trips id and sort through encode/decode', () => {
    const cursor = encodeCursor({ id: VALID_ID, sort: 'dueDate_asc' });

    expect(decodeCursor(cursor, 'dueDate_asc')).toBe(VALID_ID);
  });

  it('does not expose id/sort in plain text in the encoded string', () => {
    const cursor = encodeCursor({ id: VALID_ID, sort: 'dueDate_asc' });

    expect(cursor).not.toContain(VALID_ID);
    expect(cursor).not.toContain('dueDate_asc');
  });

  it('rejects a cursor generated for a different sort (cross-sort reuse)', () => {
    const cursor = encodeCursor({ id: VALID_ID, sort: 'dueDate_asc' });

    expect(() => decodeCursor(cursor, 'title_asc')).toThrow();
  });

  it('rejects a malformed cursor without leaking internal detail', () => {
    let error: Error | undefined;
    try {
      decodeCursor('not-a-valid-cursor!!!', 'dueDate_asc');
    } catch (e) {
      error = e as Error;
    }

    expect(error).toBeDefined();
    expect((error as { code?: string }).code).toBe('VALIDATION_ERROR');
  });

  it('rejects a decoded cursor whose id is not UUID-shaped', () => {
    const cursor = Buffer.from(JSON.stringify({ id: 'not-a-uuid', sort: 'dueDate_asc' })).toString('base64url');

    expect(() => decodeCursor(cursor, 'dueDate_asc')).toThrow();
  });

  it('rejects a decoded cursor missing required fields', () => {
    const cursor = Buffer.from(JSON.stringify({ id: VALID_ID })).toString('base64url');

    expect(() => decodeCursor(cursor, 'dueDate_asc')).toThrow();
  });
});
