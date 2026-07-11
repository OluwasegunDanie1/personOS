/** Minimal identity attached by AccessTokenGuard. Never a Prisma User model. */
export interface AuthenticatedIdentity {
  userId: string;
}

/** Minimal organization context attached by OrganizationMembershipGuard. */
export interface OrganizationRequestContext {
  organizationId: string;
  membershipId: string;
  roleId: string;
}

/**
 * Local request shape covering only what the guards read/write. Avoids a
 * dependency on @types/express, which is not an approved dependency; see
 * common/http/global-exception.filter.ts for the same convention.
 */
export interface AuthenticatedRequest {
  headers: Record<string, string | string[] | undefined>;
  params: Record<string, string>;
  auth?: AuthenticatedIdentity;
  organization?: OrganizationRequestContext;
}
