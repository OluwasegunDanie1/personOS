import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import * as http from 'http';
import { AppModule } from '../app.module';
import { GlobalExceptionFilter } from '../common/http/global-exception.filter';
import { ResponseInterceptor } from '../common/http/response.interceptor';
import { PrismaService } from '../database/prisma.service';
import {
  JWT_ACCESS_TOKEN_EXPIRY_SECONDS,
  JWT_ALGORITHM,
  JWT_AUDIENCE,
  JWT_ISSUER,
} from '../security/jwt.config';

interface TestResponseBody {
  success: boolean;
  data?: { organizations: Array<Record<string, unknown>> };
  error?: { code: string; message: string };
}

/**
 * Confirms GET /api/v1/organizations resolves under the global prefix, is
 * protected by the global AccessTokenGuard (not public), and produces the
 * approved response shape/envelope. PrismaService is overridden so this
 * never requires a live PostgreSQL connection.
 */
describe('Organizations route composition', () => {
  let app: INestApplication;
  let port: number;
  let prisma: {
    user: { findUnique: jest.Mock };
    organizationMembership: { findMany: jest.Mock };
  };
  let validToken: string;

  beforeAll(async () => {
    const testSecret = 'organizations-routes-test-secret';
    process.env.JWT_ACCESS_SECRET = testSecret;

    prisma = {
      user: { findUnique: jest.fn() },
      organizationMembership: { findMany: jest.fn() },
    };

    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PrismaService)
      .useValue(prisma)
      .compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalInterceptors(new ResponseInterceptor());
    app.useGlobalFilters(new GlobalExceptionFilter());

    await app.init();
    await app.listen(0);

    const address = app.getHttpServer().address();
    port = typeof address === 'object' && address ? address.port : 0;

    const jwtService = new JwtService({
      secret: testSecret,
      signOptions: {
        algorithm: JWT_ALGORITHM,
        expiresIn: JWT_ACCESS_TOKEN_EXPIRY_SECONDS,
        issuer: JWT_ISSUER,
        audience: JWT_AUDIENCE,
      },
    });
    validToken = jwtService.sign({ sub: 'user-1' });
  });

  afterAll(async () => {
    await app.close();
  });

  function get(token?: string): Promise<{ status: number; json: TestResponseBody }> {
    return new Promise((resolve, reject) => {
      const req = http.request(
        {
          host: '127.0.0.1',
          port,
          path: '/api/v1/organizations',
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

  it('is not public: rejects a request without an access token', async () => {
    const { status, json } = await get();

    expect(status).toBe(401);
    expect(json.success).toBe(false);
    expect(json.error?.code).toBe('AUTHENTICATION_REQUIRED');
  });

  it('resolves GET /api/v1/organizations and returns the standard success envelope with one membership', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: 'ACTIVE', deletedAt: null });
    prisma.organizationMembership.findMany.mockResolvedValue([
      { organization: { id: 'org-1', name: 'Acme', logo: null }, role: { id: 'role-1', name: 'Owner' } },
    ]);

    const { status, json } = await get(validToken);

    expect(status).toBe(200);
    expect(json.success).toBe(true);
    expect(json.data?.organizations).toEqual([
      { id: 'org-1', name: 'Acme', logoUrl: null, role: { id: 'role-1', name: 'Owner' } },
    ]);
  });

  it('excludes permission codes and membershipId from every returned organization', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: 'ACTIVE', deletedAt: null });
    prisma.organizationMembership.findMany.mockResolvedValue([
      { organization: { id: 'org-1', name: 'Acme', logo: null }, role: { id: 'role-1', name: 'Owner' } },
    ]);

    const { json } = await get(validToken);
    const organization = json.data?.organizations[0] as Record<string, unknown>;

    expect(organization).not.toHaveProperty('permissions');
    expect(organization).not.toHaveProperty('membershipId');
  });

  it('returns organizations: [] with HTTP 200 when there are no memberships', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: 'ACTIVE', deletedAt: null });
    prisma.organizationMembership.findMany.mockResolvedValue([]);

    const { status, json } = await get(validToken);

    expect(status).toBe(200);
    expect(json.success).toBe(true);
    expect(json.data).toEqual({ organizations: [] });
  });
});
