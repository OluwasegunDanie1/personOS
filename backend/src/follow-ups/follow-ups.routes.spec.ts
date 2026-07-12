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

const ORG_ID = '55555555-5555-5555-5555-555555555555';
const FOLLOW_UP_ID = '66666666-6666-6666-6666-666666666666';
const PERSON_ID = '77777777-7777-4777-8777-777777777777';
const USER_ID = '88888888-8888-4888-8888-888888888888';

interface TestResponseBody {
  success: boolean;
  data?: Record<string, unknown>;
  error?: { code: string; message: string };
}

describe('Follow-Up route composition', () => {
  let app: INestApplication;
  let port: number;
  let prisma: {
    user: { findUnique: jest.Mock };
    organizationMembership: { findUnique: jest.Mock };
    followUp: { findMany: jest.Mock; findFirst: jest.Mock; create: jest.Mock; update: jest.Mock };
    person: { findFirst: jest.Mock };
  };
  let validToken: string;

  beforeAll(async () => {
    const testSecret = 'follow-ups-routes-test-secret';
    process.env.JWT_ACCESS_SECRET = testSecret;

    prisma = {
      user: { findUnique: jest.fn() },
      organizationMembership: { findUnique: jest.fn() },
      followUp: { findMany: jest.fn(), findFirst: jest.fn(), create: jest.fn(), update: jest.fn() },
      person: { findFirst: jest.fn() },
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
  });

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

  const listPath = `/api/v1/organizations/${ORG_ID}/follow-ups`;
  const detailPath = `${listPath}/${FOLLOW_UP_ID}`;
  const completePath = `${detailPath}/complete`;

  function followUpRow(overrides: Partial<Record<string, unknown>> = {}) {
    return {
      id: FOLLOW_UP_ID,
      title: 'Call Ada',
      description: null,
      dueDate: null,
      status: 'PENDING',
      completedAt: null,
      person: { id: PERSON_ID, firstName: 'Ada', lastName: 'Lovelace' },
      assignedToUser: null,
      ...overrides,
    };
  }

  it('all five routes reject a missing access token with AUTHENTICATION_REQUIRED', async () => {
    const routes: Array<[string, string]> = [
      ['GET', listPath],
      ['POST', listPath],
      ['GET', detailPath],
      ['PATCH', detailPath],
      ['PATCH', completePath],
    ];

    for (const [method, path] of routes) {
      const { status, json } = await request(method, path);
      expect(status).toBe(401);
      expect(json.error?.code).toBe('AUTHENTICATION_REQUIRED');
    }
  });

  it('there is no DELETE Follow-Up route', async () => {
    const { status } = await request('DELETE', detailPath, validToken);
    expect(status).toBe(404);
  });

  it('rejects a valid token with no organization membership using ORGANIZATION_ACCESS_DENIED', async () => {
    prisma.organizationMembership.findUnique.mockResolvedValue(null);

    const { status, json } = await request('GET', listPath, validToken);

    expect(status).toBe(403);
    expect(json.error?.code).toBe('ORGANIZATION_ACCESS_DENIED');
  });

  it('GET list returns the standard envelope with followUps:[] and nextCursor:null when empty', async () => {
    prisma.followUp.findMany.mockResolvedValue([]);

    const { status, json } = await request('GET', listPath, validToken);

    expect(status).toBe(200);
    expect(json.success).toBe(true);
    expect(json.data).toEqual({ followUps: [], nextCursor: null });
  });

  it('GET list rejects an invalid status value', async () => {
    const { status } = await request('GET', `${listPath}?status=CANCELLED`, validToken);
    expect(status).toBe(400);
  });

  it('GET list rejects an invalid sort value', async () => {
    const { status } = await request('GET', `${listPath}?sort=createdAt_desc`, validToken);
    expect(status).toBe(400);
  });

  it('GET list rejects a limit outside the approved bounds', async () => {
    const tooLow = await request('GET', `${listPath}?limit=0`, validToken);
    expect(tooLow.status).toBe(400);

    const tooHigh = await request('GET', `${listPath}?limit=101`, validToken);
    expect(tooHigh.status).toBe(400);
  });

  it('POST create returns HTTP 201 with the approved response shape (status PENDING, completedAt null)', async () => {
    prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
    prisma.followUp.create.mockResolvedValue(followUpRow());

    const { status, json } = await request('POST', listPath, validToken, {
      personId: PERSON_ID,
      title: 'Call Ada',
    });

    expect(status).toBe(201);
    expect(json.data).toEqual({
      followUp: {
        id: FOLLOW_UP_ID,
        title: 'Call Ada',
        description: null,
        dueDate: null,
        status: 'PENDING',
        completedAt: null,
        person: { id: PERSON_ID, firstName: 'Ada', lastName: 'Lovelace' },
        assignedTo: null,
      },
    });
  });

  it('POST create rejects a client-supplied status/completedAt as unknown fields', async () => {
    const { status } = await request('POST', listPath, validToken, {
      personId: PERSON_ID,
      title: 'Call Ada',
      status: 'COMPLETED',
      completedAt: '2020-01-01T00:00:00Z',
    });

    expect(status).toBe(400);
  });

  it('POST create rejects a cross-tenant/absent person with PERSON_NOT_FOUND', async () => {
    prisma.person.findFirst.mockResolvedValue(null);

    const { status, json } = await request('POST', listPath, validToken, {
      personId: PERSON_ID,
      title: 'Call Ada',
    });

    expect(status).toBe(404);
    expect(json.error?.code).toBe('PERSON_NOT_FOUND');
  });

  it('POST create rejects a non-member assignedTo with ASSIGNED_USER_NOT_FOUND', async () => {
    prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
    prisma.organizationMembership.findUnique
      .mockResolvedValueOnce({ id: 'membership-1', organizationId: ORG_ID, roleId: 'role-1' }) // guard
      .mockResolvedValueOnce(null); // assignedTo lookup

    const { status, json } = await request('POST', listPath, validToken, {
      personId: PERSON_ID,
      title: 'Call Ada',
      assignedTo: USER_ID,
    });

    expect(status).toBe(404);
    expect(json.error?.code).toBe('ASSIGNED_USER_NOT_FOUND');
  });

  it('GET detail returns FOLLOW_UP_NOT_FOUND for a cross-tenant/absent FollowUp', async () => {
    prisma.followUp.findFirst.mockResolvedValue(null);

    const { status, json } = await request('GET', detailPath, validToken);

    expect(status).toBe(404);
    expect(json.error?.code).toBe('FOLLOW_UP_NOT_FOUND');
  });

  it('PATCH update to IN_PROGRESS succeeds', async () => {
    prisma.followUp.findFirst.mockResolvedValue({ id: FOLLOW_UP_ID, status: 'PENDING' });
    prisma.followUp.update.mockResolvedValue(followUpRow({ status: 'IN_PROGRESS' }));

    const { status, json } = await request('PATCH', detailPath, validToken, { status: 'IN_PROGRESS' });

    expect(status).toBe(200);
    expect((json.data as { followUp: { status: string } }).followUp.status).toBe('IN_PROGRESS');
  });

  it('PATCH update rejects a direct COMPLETED status write as a validation error', async () => {
    const { status, json } = await request('PATCH', detailPath, validToken, { status: 'COMPLETED' });

    expect(status).toBe(400);
    expect(json.success).toBe(false);
  });

  it('PATCH update rejects any status write on an already-COMPLETED FollowUp with FOLLOW_UP_ALREADY_COMPLETED', async () => {
    prisma.followUp.findFirst.mockResolvedValue({ id: FOLLOW_UP_ID, status: 'COMPLETED' });

    const { status, json } = await request('PATCH', detailPath, validToken, { status: 'PENDING' });

    expect(status).toBe(409);
    expect(json.error?.code).toBe('FOLLOW_UP_ALREADY_COMPLETED');
  });

  it('PATCH complete transitions to COMPLETED with a server-derived completedAt', async () => {
    prisma.followUp.findFirst.mockResolvedValue(followUpRow({ status: 'PENDING', completedAt: null }));
    prisma.followUp.update.mockResolvedValue(
      followUpRow({ status: 'COMPLETED', completedAt: new Date('2026-08-05T00:00:00.000Z') }),
    );

    const { status, json } = await request('PATCH', completePath, validToken);

    expect(status).toBe(200);
    const body = json.data as { followUp: { status: string; completedAt: string } };
    expect(body.followUp.status).toBe('COMPLETED');
    expect(body.followUp.completedAt).toBe('2026-08-05T00:00:00.000Z');
  });

  it('repeated PATCH complete is idempotent and preserves the original completedAt', async () => {
    const originalCompletedAt = new Date('2026-08-01T00:00:00.000Z');
    prisma.followUp.findFirst.mockResolvedValue(
      followUpRow({ status: 'COMPLETED', completedAt: originalCompletedAt }),
    );

    const { status, json } = await request('PATCH', completePath, validToken);

    expect(status).toBe(200);
    expect((json.data as { followUp: { completedAt: string } }).followUp.completedAt).toBe(
      '2026-08-01T00:00:00.000Z',
    );
    expect(prisma.followUp.update).not.toHaveBeenCalled();
  });
});
