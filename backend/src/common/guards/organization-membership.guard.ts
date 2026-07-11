import { CanActivate, ExecutionContext, HttpStatus, Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { ApiException } from '../http/api-exception';
import { AuthenticatedRequest } from '../http/request-context';

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const ORGANIZATION_ACCESS_DENIED = 'ORGANIZATION_ACCESS_DENIED';

/**
 * Reusable, route-level guard for endpoints containing :organizationId.
 * Consumes request.auth.userId (already attached by the global
 * AccessTokenGuard) and never re-reads or re-verifies Authorization/JWT.
 */
@Injectable()
export class OrganizationMembershipGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const userId = request.auth?.userId;

    if (!userId) {
      throw this.accessDeniedError();
    }

    const organizationId = request.params.organizationId;

    if (!organizationId || !UUID_PATTERN.test(organizationId)) {
      throw this.accessDeniedError();
    }

    const membership = await this.prisma.organizationMembership.findUnique({
      where: { organizationId_userId: { organizationId, userId } },
      select: { id: true, organizationId: true, roleId: true },
    });

    if (!membership || !membership.roleId) {
      throw this.accessDeniedError();
    }

    request.organization = {
      organizationId: membership.organizationId,
      membershipId: membership.id,
      roleId: membership.roleId,
    };

    return true;
  }

  private accessDeniedError(): ApiException {
    return new ApiException(
      HttpStatus.FORBIDDEN,
      ORGANIZATION_ACCESS_DENIED,
      'You do not have access to this organization.',
    );
  }
}
