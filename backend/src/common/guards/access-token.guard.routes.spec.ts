import { Controller, Get, INestApplication, Req, UseGuards } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import * as http from 'http';
import { AccessTokenService } from '../../security/access-token.service';
import {
  JWT_ACCESS_TOKEN_EXPIRY_SECONDS,
  JWT_ALGORITHM,
  JWT_AUDIENCE,
  JWT_ISSUER,
} from '../../security/jwt.config';
import { PrismaService } from '../../database/prisma.service';
import { Public } from '../decorators/public.decorator';
import { GlobalExceptionFilter } from '../http/global-exception.filter';
import { ResponseInterceptor } from '../http/response.interceptor';
import { AuthenticatedRequest } from '../http/request-context';
import { AccessTokenGuard } from './access-token.guard';
import { OrganizationMembershipGuard } from './organization-membership.guard';

const VALID_ORG_ID = '22222222-2222-2222-2222-222222222222';

interface TestResponseBody {
  success: boolean;
  data?: Record<string, unknown>;
  error?: { code: string; message: string };
}

@Controller('test-routes')
class TestRoutesController {
  @Public()
  @Get('public')
  publicRoute() {
    return { ok: true };
  }

  @Get('protected')
  protectedRoute(@Req() req: AuthenticatedRequest) {
    return { userId: req.auth?.userId };
  }

  @UseGuards(OrganizationMembershipGuard)
  @Get(':organizationId/scoped')
  scopedRoute(@Req() req: AuthenticatedRequest) {
    return { auth: req.auth, organization: req.organization };
  }
}

/**
 * Isolated test app proving the global-guard/public-route/membership-guard
 * composition without adding a production route. Never registers AppModule.
 */
describe('Access-token and organization-membership guard composition', () => {
  let app: INestApplication;
  let port: number;
  let prisma: {
    user: { findUnique: jest.Mock };
    organizationMembership: { findUnique: jest.Mock };
  };
  let validToken: string;

  beforeAll(async () => {
    prisma = {
      user: { findUnique: jest.fn() },
      organizationMembership: { findUnique: jest.fn() },
    };

    const jwtService = new JwtService({
      secret: 'integration-test-secret',
      signOptions: {
        algorithm: JWT_ALGORITHM,
        expiresIn: JWT_ACCESS_TOKEN_EXPIRY_SECONDS,
        issuer: JWT_ISSUER,
        audience: JWT_AUDIENCE,
      },
    });
    const accessTokenService = new AccessTokenService(jwtService);
    validToken = jwtService.sign({ sub: 'user-1' });

    const moduleRef = await Test.createTestingModule({
      controllers: [TestRoutesController],
      providers: [
        { provide: APP_GUARD, useClass: AccessTokenGuard },
        { provide: AccessTokenService, useValue: accessTokenService },
        { provide: PrismaService, useValue: prisma },
        OrganizationMembershipGuard,
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalInterceptors(new ResponseInterceptor());
    app.useGlobalFilters(new GlobalExceptionFilter());

    await app.init();
    await app.listen(0);

    const address = app.getHttpServer().address();
    port = typeof address === 'object' && address ? address.port : 0;
  });

  afterAll(async () => {
    await app.close();
  });

  function get(path: string, token?: string): Promise<{ status: number; json: TestResponseBody }> {
    return new Promise((resolve, reject) => {
      const req = http.request(
        {
          host: '127.0.0.1',
          port,
          path,
          method: 'GET',
          headers: token ? { Authorization: `Bearer ${token}` } : {},
        },
        (res) => {
          let body = '';
          res.on('data', (chunk) => {
            body += chunk;
          });
          res.on('end', () => resolve({ status: res.statusCode ?? 0, json: body ? JSON.parse(body) : {} }));
        },
      );
      req.on('error', reject);
      req.end();
    });
  }

  it('allows a route marked @Public() without a token', async () => {
    const { status, json } = await get('/test-routes/public');

    expect(status).toBe(200);
    expect(json.success).toBe(true);
  });

  it('protects an unmarked route by default with a standard error envelope', async () => {
    const { status, json } = await get('/test-routes/protected');

    expect(status).toBe(401);
    expect(json.success).toBe(false);
    expect(json.error?.code).toBe('AUTHENTICATION_REQUIRED');
  });

  it('allows an unmarked route with a valid token', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: 'ACTIVE', deletedAt: null });

    const { status, json } = await get('/test-routes/protected', validToken);

    expect(status).toBe(200);
    expect(json.success).toBe(true);
    expect(json.data?.userId).toBe('user-1');
  });

  it('makes global auth identity available before the organization-membership guard executes', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: 'ACTIVE', deletedAt: null });
    prisma.organizationMembership.findUnique.mockResolvedValue({
      id: 'membership-1',
      organizationId: VALID_ORG_ID,
      roleId: 'role-1',
    });

    const { status, json } = await get(`/test-routes/${VALID_ORG_ID}/scoped`, validToken);

    expect(status).toBe(200);
    expect(json.data?.auth).toEqual({ userId: 'user-1' });
    expect(json.data?.organization).toEqual({
      organizationId: VALID_ORG_ID,
      membershipId: 'membership-1',
      roleId: 'role-1',
    });
    expect(prisma.organizationMembership.findUnique).toHaveBeenCalledWith({
      where: { organizationId_userId: { organizationId: VALID_ORG_ID, userId: 'user-1' } },
      select: { id: true, organizationId: true, roleId: true },
    });
  });

  it('denies the scoped route with the standard error envelope when membership is missing', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: 'ACTIVE', deletedAt: null });
    prisma.organizationMembership.findUnique.mockResolvedValue(null);

    const { status, json } = await get(`/test-routes/${VALID_ORG_ID}/scoped`, validToken);

    expect(status).toBe(403);
    expect(json.success).toBe(false);
    expect(json.error?.code).toBe('ORGANIZATION_ACCESS_DENIED');
  });
});
