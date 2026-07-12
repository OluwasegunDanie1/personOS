import { INestApplication, ValidationPipe } from '@nestjs/common';
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
  data?: { organizations?: Array<Record<string, unknown>>; organization?: Record<string, unknown> };
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
    organizationMembership: { findMany: jest.Mock; findUnique: jest.Mock; create: jest.Mock };
    organization: { create: jest.Mock; findFirst: jest.Mock; update: jest.Mock };
    role: { create: jest.Mock };
    $transaction: jest.Mock;
  };
  let validToken: string;

  beforeAll(async () => {
    const testSecret = 'organizations-routes-test-secret';
    process.env.JWT_ACCESS_SECRET = testSecret;

    prisma = {
      user: { findUnique: jest.fn() },
      organizationMembership: { findMany: jest.fn(), findUnique: jest.fn(), create: jest.fn() },
      organization: { create: jest.fn(), findFirst: jest.fn(), update: jest.fn() },
      role: { create: jest.fn() },
      $transaction: jest.fn((ops: Promise<unknown>[]) => Promise.all(ops)),
    };

    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PrismaService)
      .useValue(prisma)
      .compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalInterceptors(new ResponseInterceptor());
    app.useGlobalFilters(new GlobalExceptionFilter());
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));

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

  beforeEach(() => {
    jest.clearAllMocks();
  });

  function get(token?: string): Promise<{ status: number; json: TestResponseBody }> {
    return request('GET', '/api/v1/organizations', token);
  }

  function request(
    method: string,
    path: string,
    token?: string,
    body?: unknown,
  ): Promise<{ status: number; json: TestResponseBody }> {
    return new Promise((resolve, reject) => {
      const payload = body !== undefined ? JSON.stringify(body) : undefined;
      const headers: Record<string, string> = {};
      if (token) headers.Authorization = `Bearer ${token}`;
      if (payload) {
        headers['Content-Type'] = 'application/json';
        headers['Content-Length'] = String(Buffer.byteLength(payload));
      }

      const req = http.request({ host: '127.0.0.1', port, path, method, headers }, (res) => {
        let responseBody = '';
        res.on('data', (chunk) => {
          responseBody += chunk;
        });
        res.on('end', () =>
          resolve({ status: res.statusCode ?? 0, json: responseBody ? JSON.parse(responseBody) : {} }),
        );
      });
      req.on('error', reject);
      if (payload) req.write(payload);
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
    const organization = json.data?.organizations?.[0] as Record<string, unknown>;

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

  const ORG_ID = '22222222-2222-2222-2222-222222222222';

  describe('POST /organizations', () => {
    beforeEach(() => {
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: 'ACTIVE', deletedAt: null });
    });

    it('rejects a missing access token with AUTHENTICATION_REQUIRED', async () => {
      const { status, json } = await request('POST', '/api/v1/organizations', undefined, { name: 'Acme' });

      expect(status).toBe(401);
      expect(json.error?.code).toBe('AUTHENTICATION_REQUIRED');
    });

    it('does not require organization membership (creates without any existing membership)', async () => {
      prisma.organization.create.mockResolvedValue({ id: ORG_ID, name: 'Acme' });
      prisma.role.create.mockResolvedValue({ id: 'role-1' });
      prisma.organizationMembership.create.mockResolvedValue({ id: 'membership-1' });

      const { status } = await request('POST', '/api/v1/organizations', validToken, { name: 'Acme' });

      expect(status).toBe(201);
      // The membership guard's own lookup (findUnique) must never be
      // consulted for Create: no OrganizationMembershipGuard applies here.
      expect(prisma.organizationMembership.findUnique).not.toHaveBeenCalled();
    });

    it('returns HTTP 201 with exactly {organization: {id, name}}', async () => {
      prisma.organization.create.mockResolvedValue({ id: ORG_ID, name: 'Acme' });
      prisma.role.create.mockResolvedValue({ id: 'role-1' });
      prisma.organizationMembership.create.mockResolvedValue({ id: 'membership-1' });

      const { status, json } = await request('POST', '/api/v1/organizations', validToken, { name: 'Acme' });

      expect(status).toBe(201);
      expect(json.data).toEqual({ organization: { id: ORG_ID, name: 'Acme' } });
    });

    it('rejects a missing name with a validation error', async () => {
      const { status, json } = await request('POST', '/api/v1/organizations', validToken, {});

      expect(status).toBe(400);
      expect(json.success).toBe(false);
    });

    it('rejects an empty/whitespace-only name', async () => {
      const { status } = await request('POST', '/api/v1/organizations', validToken, { name: '   ' });

      expect(status).toBe(400);
    });

    it('rejects unknown fields (industry, logoUrl, ownerId, role, setupComplete)', async () => {
      const { status } = await request('POST', '/api/v1/organizations', validToken, {
        name: 'Acme',
        industry: 'Nonprofit',
        logoUrl: 'https://example.com/logo.png',
        ownerId: 'attacker-supplied-id',
        role: 'Owner',
        setupComplete: true,
      });

      expect(status).toBe(400);
    });

    it('never exposes slug in the response', async () => {
      prisma.organization.create.mockResolvedValue({ id: ORG_ID, name: 'Acme' });
      prisma.role.create.mockResolvedValue({ id: 'role-1' });
      prisma.organizationMembership.create.mockResolvedValue({ id: 'membership-1' });

      const { json } = await request('POST', '/api/v1/organizations', validToken, { name: 'Acme' });

      expect(json.data?.organization).not.toHaveProperty('slug');
    });
  });

  describe('GET /organizations/:organizationId', () => {
    it('rejects a missing access token with AUTHENTICATION_REQUIRED', async () => {
      const { status, json } = await request('GET', `/api/v1/organizations/${ORG_ID}`);

      expect(status).toBe(401);
      expect(json.error?.code).toBe('AUTHENTICATION_REQUIRED');
    });

    it('rejects a non-member with ORGANIZATION_ACCESS_DENIED', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: 'ACTIVE', deletedAt: null });
      prisma.organizationMembership.findUnique.mockResolvedValue(null);

      const { status, json } = await request('GET', `/api/v1/organizations/${ORG_ID}`, validToken);

      expect(status).toBe(403);
      expect(json.error?.code).toBe('ORGANIZATION_ACCESS_DENIED');
    });

    it('returns exactly {organization: {id, name}} for an active member', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: 'ACTIVE', deletedAt: null });
      prisma.organizationMembership.findUnique.mockResolvedValue({
        id: 'membership-1',
        organizationId: ORG_ID,
        roleId: 'role-1',
      });
      prisma.organization.findFirst.mockResolvedValue({ id: ORG_ID, name: 'Acme' });

      const { status, json } = await request('GET', `/api/v1/organizations/${ORG_ID}`, validToken);

      expect(status).toBe(200);
      expect(json.data).toEqual({ organization: { id: ORG_ID, name: 'Acme' } });
    });
  });

  describe('PATCH /organizations/:organizationId', () => {
    beforeEach(() => {
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: 'ACTIVE', deletedAt: null });
      prisma.organizationMembership.findUnique.mockResolvedValue({
        id: 'membership-1',
        organizationId: ORG_ID,
        roleId: 'role-1',
      });
    });

    it('rejects a missing access token with AUTHENTICATION_REQUIRED', async () => {
      const { status, json } = await request('PATCH', `/api/v1/organizations/${ORG_ID}`, undefined, {
        name: 'Updated',
      });

      expect(status).toBe(401);
      expect(json.error?.code).toBe('AUTHENTICATION_REQUIRED');
    });

    it('rejects a non-member with ORGANIZATION_ACCESS_DENIED', async () => {
      prisma.organizationMembership.findUnique.mockResolvedValue(null);

      const { status, json } = await request('PATCH', `/api/v1/organizations/${ORG_ID}`, validToken, {
        name: 'Updated',
      });

      expect(status).toBe(403);
      expect(json.error?.code).toBe('ORGANIZATION_ACCESS_DENIED');
    });

    it('rejects an empty body', async () => {
      const { status } = await request('PATCH', `/api/v1/organizations/${ORG_ID}`, validToken, {});

      expect(status).toBe(400);
    });

    it('rejects unknown fields', async () => {
      const { status } = await request('PATCH', `/api/v1/organizations/${ORG_ID}`, validToken, {
        name: 'Updated',
        industry: 'Nonprofit',
      });

      expect(status).toBe(400);
    });

    it('returns exactly {organization: {id, name}} on success', async () => {
      prisma.organization.update.mockResolvedValue({ id: ORG_ID, name: 'Updated Name' });

      const { status, json } = await request('PATCH', `/api/v1/organizations/${ORG_ID}`, validToken, {
        name: 'Updated Name',
      });

      expect(status).toBe(200);
      expect(json.data).toEqual({ organization: { id: ORG_ID, name: 'Updated Name' } });
    });
  });

  it('there is no DELETE Organization route', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: 'ACTIVE', deletedAt: null });
    prisma.organizationMembership.findUnique.mockResolvedValue({
      id: 'membership-1',
      organizationId: ORG_ID,
      roleId: 'role-1',
    });

    const { status } = await request('DELETE', `/api/v1/organizations/${ORG_ID}`, validToken);

    expect(status).toBe(404);
  });
});
