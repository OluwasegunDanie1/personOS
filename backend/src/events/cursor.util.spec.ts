import { decodeCursor, encodeCursor } from './cursor.util';

const VALID_ID = '11111111-1111-1111-1111-111111111111';

describe('events/cursor.util', () => {
  it('round-trips id and sort through encode/decode', () => {
    const cursor = encodeCursor({ id: VALID_ID, sort: 'startDate_desc' });

    const decodedId = decodeCursor(cursor, 'startDate_desc');

    expect(decodedId).toBe(VALID_ID);
  });

  it('does not expose id/sort in plain text in the encoded string', () => {
    const cursor = encodeCursor({ id: VALID_ID, sort: 'startDate_desc' });

    expect(cursor).not.toContain(VALID_ID);
    expect(cursor).not.toContain('startDate_desc');
  });

  it('rejects a cursor generated for a different sort (cross-sort reuse)', () => {
    const cursor = encodeCursor({ id: VALID_ID, sort: 'startDate_desc' });

    expect(() => decodeCursor(cursor, 'title_asc')).toThrow();
  });

  it('rejects a malformed (non-base64/non-JSON) cursor without leaking internal detail', () => {
    let error: Error | undefined;
    try {
      decodeCursor('not-a-valid-cursor!!!', 'startDate_desc');
    } catch (e) {
      error = e as Error;
    }

    expect(error).toBeDefined();
    expect((error as { code?: string }).code).toBe('VALIDATION_ERROR');
  });

  it('rejects a decoded cursor whose id is not UUID-shaped', () => {
    const cursor = Buffer.from(JSON.stringify({ id: 'not-a-uuid', sort: 'startDate_desc' })).toString('base64url');

    expect(() => decodeCursor(cursor, 'startDate_desc')).toThrow();
  });

  it('rejects a decoded cursor missing required fields', () => {
    const cursor = Buffer.from(JSON.stringify({ id: VALID_ID })).toString('base64url');

    expect(() => decodeCursor(cursor, 'startDate_desc')).toThrow();
  });

  it('works generically across the Attendance sort allowlists too', () => {
    const cursor = encodeCursor({ id: VALID_ID, sort: 'personName_asc' });

    expect(decodeCursor(cursor, 'personName_asc')).toBe(VALID_ID);
    expect(() => decodeCursor(cursor, 'eventStartDate_desc')).toThrow();
  });
});
