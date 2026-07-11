import { getJwtAccessSecret } from './jwt.config';

describe('getJwtAccessSecret', () => {
  const originalSecret = process.env.JWT_ACCESS_SECRET;

  afterEach(() => {
    if (originalSecret === undefined) {
      delete process.env.JWT_ACCESS_SECRET;
    } else {
      process.env.JWT_ACCESS_SECRET = originalSecret;
    }
  });

  it('fails clearly when JWT_ACCESS_SECRET is missing', () => {
    delete process.env.JWT_ACCESS_SECRET;

    expect(() => getJwtAccessSecret()).toThrow('JWT_ACCESS_SECRET is required.');
  });

  it('fails clearly when JWT_ACCESS_SECRET is empty', () => {
    process.env.JWT_ACCESS_SECRET = '';

    expect(() => getJwtAccessSecret()).toThrow('JWT_ACCESS_SECRET is required.');
  });

  it('accepts a configured secret without altering it', () => {
    const testSecret = 'unit-test-secret-value';
    process.env.JWT_ACCESS_SECRET = testSecret;

    expect(getJwtAccessSecret()).toBe(testSecret);
  });
});
