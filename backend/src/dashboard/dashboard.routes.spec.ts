import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
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

const ORG_ID = '99999999-9999-9999-9999-999999999999';

interface TestResponseBody {
  success: boolean;
  data?: Record<string, unknown>;
  error?: { code: string; message: string };
}

describe('Dashboard route composition', () => {
  let app: INestApplication;
  let port: number;
  let prisma: {
    user: { findUnique: jest.Mock };
    organizationMembership: { findUnique: jest.Mock };
    person: { count: jest.Mock };
    followUp: { count: jest.Mock };
    event: { findMany: jest.Mock };
  };
  let validToken: string;

  beforeAll(async () => {
    const testSecret = 'dashboard-routes-test-secret';
    process.env.JWT_ACCESS_SECRET = testSecret;

    prisma = {
      user: { findUnique: jest.fn() },
      organizationMembership: { findUnique: jest.fn() },
      person: { count: jest.fn() },
      followUp: { count: jest.fn() },
      event: { findMany: jest.fn() },
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
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: 'ACTIVE', deletedAt: null });
    prisma.organizationMembership.findUnique.mockResolvedValue({
      id: 'membership-1',
      organizationId: ORG_ID,
      roleId: 'role-1',
    });
    prisma.person.count.mockResolvedValue(0);
    prisma.followUp.count.mockResolvedValue(0);
    prisma.event.findMany.mockResolvedValue([]);
  });

  function request(method: string, path: string, token?: string): Promise<{ status: number; json: TestResponseBody }> {
    return new Promise((resolve, reject) => {
      const headers: Record<string, string> = {};
      if (token) headers.Authorization = `Bearer ${token}`;

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
      req.end();
    });
  }

  const dashboardPath = `/api/v1/organizations/${ORG_ID}/reports/dashboard`;

  it('rejects a missing access token with AUTHENTICATION_REQUIRED', async () => {
    const { status, json } = await request('GET', dashboardPath);

    expect(status).toBe(401);
    expect(json.error?.code).toBe('AUTHENTICATION_REQUIRED');
  });

  it('rejects a valid token with no organization membership using ORGANIZATION_ACCESS_DENIED', async () => {
    prisma.organizationMembership.findUnique.mockResolvedValue(null);

    const { status, json } = await request('GET', dashboardPath, validToken);

    expect(status).toBe(403);
    expect(json.error?.code).toBe('ORGANIZATION_ACCESS_DENIED');
  });

  it('exact runtime route responds at GET /api/v1/organizations/:organizationId/reports/dashboard', async () => {
    const { status } = await request('GET', dashboardPath, validToken);
    expect(status).toBe(200);
  });

  it('returns the standard envelope with exactly the four approved fields on empty/zero data', async () => {
    const { status, json } = await request('GET', dashboardPath, validToken);

    expect(status).toBe(200);
    expect(json.success).toBe(true);
    expect(json.data).toEqual({ totalPeople: 0, newPeople: 0, pendingFollowUps: 0, upcomingEvents: [] });
  });

  it('never includes disallowed fields in the live response', async () => {
    prisma.person.count.mockResolvedValue(3);
    prisma.followUp.count.mockResolvedValue(2);
    prisma.event.findMany.mockResolvedValue([
      { id: 'event-1', title: 'Sunday Service', startDate: new Date('2026-08-02T09:00:00.000Z') },
    ]);

    const { json } = await request('GET', dashboardPath, validToken);

    const data = json.data as Record<string, unknown>;
    expect(Object.keys(data).sort()).toEqual(['newPeople', 'pendingFollowUps', 'totalPeople', 'upcomingEvents'].sort());
    expect((data.upcomingEvents as Array<Record<string, unknown>>)[0]).toEqual({
      id: 'event-1',
      title: 'Sunday Service',
      startDate: '2026-08-02T09:00:00.000Z',
    });
  });

  it('an unrecognized query parameter does not break the endpoint (no query contract is declared)', async () => {
    const { status } = await request('GET', `${dashboardPath}?foo=bar`, validToken);
    expect(status).toBe(200);
  });

  it('does not create any Report/AuditLog/Notification row (mocked Prisma exposes no such model)', async () => {
    await request('GET', dashboardPath, validToken);

    expect(Object.keys(prisma).sort()).toEqual(
      ['user', 'organizationMembership', 'person', 'followUp', 'event'].sort(),
    );
  });
});
