import { getTrustProxySetting } from './trust-proxy.config';

describe('getTrustProxySetting', () => {
  const originalNodeEnv = process.env.NODE_ENV;
  const originalTrustProxy = process.env.TRUST_PROXY;

  afterEach(() => {
    if (originalNodeEnv === undefined) {
      delete process.env.NODE_ENV;
    } else {
      process.env.NODE_ENV = originalNodeEnv;
    }

    if (originalTrustProxy === undefined) {
      delete process.env.TRUST_PROXY;
    } else {
      process.env.TRUST_PROXY = originalTrustProxy;
    }
  });

  it('disables trust proxy in development without requiring TRUST_PROXY', () => {
    process.env.NODE_ENV = 'development';
    delete process.env.TRUST_PROXY;

    expect(getTrustProxySetting()).toBe(false);
  });

  it('disables trust proxy in test without requiring TRUST_PROXY', () => {
    process.env.NODE_ENV = 'test';
    delete process.env.TRUST_PROXY;

    expect(getTrustProxySetting()).toBe(false);
  });

  it('fails clearly when TRUST_PROXY is missing in production', () => {
    process.env.NODE_ENV = 'production';
    delete process.env.TRUST_PROXY;

    expect(() => getTrustProxySetting()).toThrow('TRUST_PROXY is required in production.');
  });

  it('fails clearly when TRUST_PROXY is empty in production', () => {
    process.env.NODE_ENV = 'production';
    process.env.TRUST_PROXY = '';

    expect(() => getTrustProxySetting()).toThrow('TRUST_PROXY is required in production.');
  });

  it('rejects 0 in production', () => {
    process.env.NODE_ENV = 'production';
    process.env.TRUST_PROXY = '0';

    expect(() => getTrustProxySetting()).toThrow('TRUST_PROXY must be a positive integer');
  });

  it('rejects a negative integer in production', () => {
    process.env.NODE_ENV = 'production';
    process.env.TRUST_PROXY = '-1';

    expect(() => getTrustProxySetting()).toThrow('TRUST_PROXY must be a positive integer');
  });

  it('rejects a decimal value in production', () => {
    process.env.NODE_ENV = 'production';
    process.env.TRUST_PROXY = '1.5';

    expect(() => getTrustProxySetting()).toThrow('TRUST_PROXY must be a positive integer');
  });

  it('rejects a non-numeric value in production', () => {
    process.env.NODE_ENV = 'production';
    process.env.TRUST_PROXY = 'true';

    expect(() => getTrustProxySetting()).toThrow('TRUST_PROXY must be a positive integer');
  });

  it('accepts a positive integer in production', () => {
    process.env.NODE_ENV = 'production';
    process.env.TRUST_PROXY = '2';

    expect(getTrustProxySetting()).toBe(2);
  });

  it('never returns boolean true', () => {
    process.env.NODE_ENV = 'production';
    process.env.TRUST_PROXY = '1';

    const result = getTrustProxySetting();

    expect(result).not.toBe(true);
    expect(typeof result).toBe('number');
  });
});
