export const JWT_ALGORITHM = 'HS256';
export const JWT_ACCESS_TOKEN_EXPIRY_SECONDS = 15 * 60;
export const JWT_ISSUER = 'relvio-api';
export const JWT_AUDIENCE = 'relvio-mobile';

/**
 * Reads the required JWT signing secret from the environment. There is no
 * fallback: backend authentication configuration must fail clearly rather
 * than silently sign tokens with a guessable or empty secret.
 */
export function getJwtAccessSecret(): string {
  const secret = process.env.JWT_ACCESS_SECRET;

  if (!secret) {
    throw new Error(
      'JWT_ACCESS_SECRET is required. Set it in the environment before starting the backend.',
    );
  }

  return secret;
}
