import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/**
 * Explicitly marks a route as bypassing the global AccessTokenGuard. Public
 * status must never be inferred from route or controller naming.
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
