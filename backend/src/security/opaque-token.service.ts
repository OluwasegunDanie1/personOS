import { Injectable } from '@nestjs/common';
import { createHash, randomBytes } from 'crypto';

/**
 * Shared cryptography for refresh, email-verification, and password-reset
 * tokens. All three use the same opaque generation and hashing primitive;
 * only their persistence and lifecycle rules differ, which belong to a
 * later task.
 */
@Injectable()
export class OpaqueTokenService {
  generate(): string {
    return randomBytes(32).toString('base64url');
  }

  hash(rawToken: string): string {
    return createHash('sha256').update(rawToken).digest('hex');
  }
}
