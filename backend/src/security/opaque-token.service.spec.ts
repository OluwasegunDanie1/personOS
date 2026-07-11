import { OpaqueTokenService } from './opaque-token.service';

describe('OpaqueTokenService', () => {
  const service = new OpaqueTokenService();

  it('generates a non-empty token', () => {
    expect(service.generate().length).toBeGreaterThan(0);
  });

  it('generates different tokens on each call', () => {
    expect(service.generate()).not.toBe(service.generate());
  });

  it('generates a valid base64url token', () => {
    expect(service.generate()).toMatch(/^[A-Za-z0-9_-]+$/);
  });

  it('hashes deterministically', () => {
    const token = service.generate();

    expect(service.hash(token)).toBe(service.hash(token));
  });

  it('produces a lowercase hexadecimal SHA-256 hash', () => {
    const hash = service.hash(service.generate());

    expect(hash).toMatch(/^[0-9a-f]{64}$/);
  });

  it('produces different hashes for different tokens', () => {
    const hashA = service.hash(service.generate());
    const hashB = service.hash(service.generate());

    expect(hashA).not.toBe(hashB);
  });
});
