const POSITIVE_INTEGER_PATTERN = /^[1-9]\d*$/;

/**
 * Resolves the validated Express trust-proxy hop count for the current
 * environment. Returns `false` when trust proxy must remain disabled
 * (development and test), or a positive integer hop count in production.
 *
 * There is no fallback: production configuration must fail clearly rather
 * than silently trusting an unconfigured or malformed proxy boundary.
 */
export function getTrustProxySetting(): number | false {
  const nodeEnv = process.env.NODE_ENV;

  if (nodeEnv !== 'production') {
    return false;
  }

  const trustProxy = process.env.TRUST_PROXY;

  if (!trustProxy) {
    throw new Error(
      'TRUST_PROXY is required in production. Set it to the trusted proxy hop count before starting the backend.',
    );
  }

  if (!POSITIVE_INTEGER_PATTERN.test(trustProxy)) {
    throw new Error('TRUST_PROXY must be a positive integer trusted proxy hop count.');
  }

  return Number(trustProxy);
}
