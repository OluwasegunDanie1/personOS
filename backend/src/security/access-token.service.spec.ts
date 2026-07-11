import { JwtService } from '@nestjs/jwt';
import { AccessTokenService } from './access-token.service';
import {
  JWT_ACCESS_TOKEN_EXPIRY_SECONDS,
  JWT_ALGORITHM,
  JWT_AUDIENCE,
  JWT_ISSUER,
} from './jwt.config';

function decodeHeader(token: string): { alg: string } {
  const [headerSegment] = token.split('.');
  return JSON.parse(Buffer.from(headerSegment, 'base64url').toString('utf8'));
}

describe('AccessTokenService', () => {
  const testSecret = 'unit-test-secret-value';
  let jwtService: JwtService;
  let accessTokenService: AccessTokenService;

  beforeEach(() => {
    jwtService = new JwtService({
      secret: testSecret,
      signOptions: {
        algorithm: JWT_ALGORITHM,
        expiresIn: JWT_ACCESS_TOKEN_EXPIRY_SECONDS,
        issuer: JWT_ISSUER,
        audience: JWT_AUDIENCE,
      },
    });
    accessTokenService = new AccessTokenService(jwtService);
  });

  it('signs a token using HS256', () => {
    const token = accessTokenService.sign('user-123');

    expect(decodeHeader(token).alg).toBe('HS256');
  });

  it('contains only the approved sub, timing, issuer, and audience claims', () => {
    const token = accessTokenService.sign('user-123');
    const decoded = jwtService.verify(token, { secret: testSecret });

    expect(decoded.sub).toBe('user-123');
    expect(decoded.iss).toBe(JWT_ISSUER);
    expect(decoded.aud).toBe(JWT_AUDIENCE);
    expect(typeof decoded.iat).toBe('number');
    expect(typeof decoded.exp).toBe('number');
    expect(decoded.exp - decoded.iat).toBe(JWT_ACCESS_TOKEN_EXPIRY_SECONDS);
    expect(decoded).not.toHaveProperty('organizationId');
    expect(decoded).not.toHaveProperty('role');
    expect(decoded).not.toHaveProperty('permissions');
  });
});
