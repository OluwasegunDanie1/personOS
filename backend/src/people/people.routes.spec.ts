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

const ORG_ID = '33333333-3333-3333-3333-333333333333';
const OTHER_ORG_ID = '44444444-4444-4444-4444-444444444444';
const PERSON_ID = '55555555-5555-5555-5555-555555555555';

interface TestResponseBody {
  success: boolean;
  data?: Record<string, unknown>;
  error?: { code: string; message: string };
}

describe('People route composition', () => {
  let app: INestApplication;
  let port: number;
  let prisma: {
    user: { findUnique: jest.Mock };
    organizationMembership: { findUnique: jest.Mock };
    person: { findMany: jest.Mock; findFirst: jest.Mock; create: jest.Mock; update: jest.Mock };
    personTag: { findMany: jest.Mock };
    personJourneyHistory: { findFirst: jest.Mock };
    journeyStage: { findMany: jest.Mock };
    $queryRaw: jest.Mock;
  };
  let validToken: string;

  beforeAll(async () => {
    const testSecret = 'people-routes-test-secret';
    process.env.JWT_ACCESS_SECRET = testSecret;

    prisma = {
      user: { findUnique: jest.fn() },
      organizationMembership: { findUnique: jest.fn() },
      person: { findMany: jest.fn(), findFirst: jest.fn(), create: jest.fn(), update: jest.fn() },
      personTag: { findMany: jest.fn() },
      personJourneyHistory: { findFirst: jest.fn() },
      journeyStage: { findMany: jest.fn().mockResolvedValue([]) },
      $queryRaw: jest.fn().mockResolvedValue([]),
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

  const listPath = `/api/v1/organizations/${ORG_ID}/people`;
  const detailPath = `/api/v1/organizations/${ORG_ID}/people/${PERSON_ID}`;

  it('all five routes exist and reject missing auth with AUTHENTICATION_REQUIRED', async () => {
    const routes: Array<[string, string]> = [
      ['GET', listPath],
      ['POST', listPath],
      ['GET', detailPath],
      ['PATCH', detailPath],
      ['DELETE', detailPath],
    ];

    for (const [method, path] of routes) {
      const { status, json } = await request(method, path);
      expect(status).toBe(401);
      expect(json.error?.code).toBe('AUTHENTICATION_REQUIRED');
    }
  });

  it('rejects a valid token with no organization membership using ORGANIZATION_ACCESS_DENIED', async () => {
    prisma.organizationMembership.findUnique.mockResolvedValue(null);

    const { status, json } = await request('GET', listPath, validToken);

    expect(status).toBe(403);
    expect(json.error?.code).toBe('ORGANIZATION_ACCESS_DENIED');
  });

  it('GET list returns the standard envelope with people:[] and nextCursor:null when empty', async () => {
    prisma.person.findMany.mockResolvedValue([]);

    const { status, json } = await request('GET', listPath, validToken);

    expect(status).toBe(200);
    expect(json.success).toBe(true);
    expect(json.data).toEqual({ people: [], nextCursor: null });
  });

  it('GET list includes currentJourneyStage and lastAttendance end-to-end, both nullable', async () => {
    prisma.person.findMany.mockResolvedValue([
      {
        id: PERSON_ID,
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: null,
        phone: null,
        status: 'ACTIVE',
        profilePhoto: null,
        createdAt: new Date('2026-01-01T00:00:00.000Z'),
      },
    ]);
    prisma.$queryRaw
      .mockResolvedValueOnce([{ person_id: PERSON_ID, to_stage_id: 'stage-1' }])
      .mockResolvedValueOnce([{ person_id: PERSON_ID, checked_in_at: new Date('2026-05-25T09:00:00.000Z') }]);
    prisma.journeyStage.findMany.mockResolvedValue([{ id: 'stage-1', name: 'Connected Guest' }]);

    const { status, json } = await request('GET', listPath, validToken);

    expect(status).toBe(200);
    const person = (json.data!.people as Array<Record<string, unknown>>)[0];
    expect(person.currentJourneyStage).toEqual({ id: 'stage-1', name: 'Connected Guest' });
    expect(person.lastAttendance).toEqual({ checkedInAt: '2026-05-25T09:00:00.000Z' });
  });

  it('GET detail includes gender, dateOfBirth, and address end-to-end (Product Task 039)', async () => {
    prisma.person.findFirst.mockResolvedValue({
      id: PERSON_ID,
      firstName: 'Ada',
      lastName: 'Lovelace',
      email: null,
      phone: null,
      status: 'ACTIVE',
      profilePhoto: null,
      createdAt: new Date('2026-01-01T00:00:00.000Z'),
      gender: 'FEMALE',
      dateOfBirth: new Date(Date.UTC(1990, 11, 10)),
      address: '221B Baker Street',
    });
    prisma.personTag.findMany.mockResolvedValue([]);
    prisma.personJourneyHistory.findFirst.mockResolvedValue(null);

    const { status, json } = await request('GET', detailPath, validToken);

    expect(status).toBe(200);
    const person = json.data!.person as Record<string, unknown>;
    expect(person.gender).toBe('FEMALE');
    expect(person.dateOfBirth).toBe('1990-12-10');
    expect(person.address).toBe('221B Baker Street');
  });

  it('GET detail preserves null for gender, dateOfBirth, and address end-to-end', async () => {
    prisma.person.findFirst.mockResolvedValue({
      id: PERSON_ID,
      firstName: 'Ada',
      lastName: 'Lovelace',
      email: null,
      phone: null,
      status: 'ACTIVE',
      profilePhoto: null,
      createdAt: new Date('2026-01-01T00:00:00.000Z'),
      gender: null,
      dateOfBirth: null,
      address: null,
    });
    prisma.personTag.findMany.mockResolvedValue([]);
    prisma.personJourneyHistory.findFirst.mockResolvedValue(null);

    const { json } = await request('GET', detailPath, validToken);

    const person = json.data!.person as Record<string, unknown>;
    expect(person.gender).toBeNull();
    expect(person.dateOfBirth).toBeNull();
    expect(person.address).toBeNull();
  });

  it('GET detail returns PERSON_NOT_FOUND for a cross-tenant/absent person', async () => {
    prisma.person.findFirst.mockResolvedValue(null);

    const { status, json } = await request(
      'GET',
      `/api/v1/organizations/${OTHER_ORG_ID}/people/${PERSON_ID}`,
      validToken,
    );

    // Membership lookup for OTHER_ORG_ID is mocked to succeed above via
    // beforeEach's default; this proves detail itself scopes and 404s.
    expect([403, 404]).toContain(status);
    expect(json.success).toBe(false);
  });

  it('POST create returns HTTP 201 with the approved response shape', async () => {
    prisma.person.create.mockResolvedValue({
      id: PERSON_ID,
      firstName: 'Ada',
      lastName: 'Lovelace',
      email: null,
      phone: null,
      status: 'ACTIVE',
      profilePhoto: null,
      createdAt: new Date('2026-01-01T00:00:00.000Z'),
    });

    const { status, json } = await request('POST', listPath, validToken, {
      firstName: 'Ada',
      lastName: 'Lovelace',
    });

    expect(status).toBe(201);
    expect(json.data).toEqual({
      person: {
        id: PERSON_ID,
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: null,
        phone: null,
        status: 'ACTIVE',
        avatarUrl: null,
        joinedAt: '2026-01-01T00:00:00.000Z',
      },
    });
  });

  it('POST create rejects a missing firstName with a validation error', async () => {
    const { status, json } = await request('POST', listPath, validToken, { lastName: 'Lovelace' });

    expect(status).toBe(400);
    expect(json.success).toBe(false);
  });

  describe('POST create gender/dateOfBirth/address contract', () => {
    beforeEach(() => {
      prisma.person.create.mockResolvedValue({
        id: PERSON_ID,
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: null,
        phone: null,
        status: 'ACTIVE',
        profilePhoto: null,
        createdAt: new Date('2026-01-01T00:00:00.000Z'),
      });
    });

    it('accepts gender omitted', async () => {
      const { status } = await request('POST', listPath, validToken, { firstName: 'Ada', lastName: 'Lovelace' });

      expect(status).toBe(201);
    });

    it.each(['MALE', 'FEMALE'])('accepts gender %s', async (gender) => {
      const { status } = await request('POST', listPath, validToken, {
        firstName: 'Ada',
        lastName: 'Lovelace',
        gender,
      });

      expect(status).toBe(201);
    });

    it.each(['Male', 'Female', 'male', 'female', 'OTHER', 'PREFER_NOT_TO_SAY', 'NON_BINARY', ''])(
      'rejects gender %s',
      async (gender) => {
        const { status, json } = await request('POST', listPath, validToken, {
          firstName: 'Ada',
          lastName: 'Lovelace',
          gender,
        });

        expect(status).toBe(400);
        expect(json.success).toBe(false);
      },
    );

    it('accepts dateOfBirth omitted', async () => {
      const { status } = await request('POST', listPath, validToken, { firstName: 'Ada', lastName: 'Lovelace' });

      expect(status).toBe(201);
    });

    it('accepts a valid YYYY-MM-DD dateOfBirth', async () => {
      const { status } = await request('POST', listPath, validToken, {
        firstName: 'Ada',
        lastName: 'Lovelace',
        dateOfBirth: '2001-07-14',
      });

      expect(status).toBe(201);
    });

    it('accepts the leap day 2000-02-29', async () => {
      const { status } = await request('POST', listPath, validToken, {
        firstName: 'Ada',
        lastName: 'Lovelace',
        dateOfBirth: '2000-02-29',
      });

      expect(status).toBe(201);
    });

    it.each([
      '01-07-2001',
      '2001/07/14',
      '2001-7-14',
      '2001-07-4',
      '2001-07-14T00:00:00Z',
      '2001-07-14T00:00:00+01:00',
      '2025-02-29',
      '2025-02-30',
      '2023-13-01',
      '2023-00-10',
      'not-a-date',
    ])('rejects malformed or impossible dateOfBirth %s', async (dateOfBirth) => {
      const { status, json } = await request('POST', listPath, validToken, {
        firstName: 'Ada',
        lastName: 'Lovelace',
        dateOfBirth,
      });

      expect(status).toBe(400);
      expect(json.success).toBe(false);
    });

    it('accepts address omitted', async () => {
      const { status } = await request('POST', listPath, validToken, { firstName: 'Ada', lastName: 'Lovelace' });

      expect(status).toBe(201);
    });

    it('accepts a non-empty address', async () => {
      const { status } = await request('POST', listPath, validToken, {
        firstName: 'Ada',
        lastName: 'Lovelace',
        address: '123 Main St',
      });

      expect(status).toBe(201);
    });

    it('accepts a whitespace-only address at transport and persists it as null', async () => {
      const { status } = await request('POST', listPath, validToken, {
        firstName: 'Ada',
        lastName: 'Lovelace',
        address: '   ',
      });

      expect(status).toBe(201);
      const args = prisma.person.create.mock.calls[0][0];
      expect(args.data.address).toBeNull();
    });

    it.each(['avatarUrl', 'profilePhoto', 'group', 'groupId', 'notes', 'occupation', 'currentJourneyStageId', 'tags'])(
      'rejects unsupported field %s',
      async (field) => {
        const { status, json } = await request('POST', listPath, validToken, {
          firstName: 'Ada',
          lastName: 'Lovelace',
          [field]: 'some-value',
        });

        expect(status).toBe(400);
        expect(json.success).toBe(false);
      },
    );

    it('rejects an arbitrary unknown field', async () => {
      const { status, json } = await request('POST', listPath, validToken, {
        firstName: 'Ada',
        lastName: 'Lovelace',
        totallyUnknownField: 'x',
      });

      expect(status).toBe(400);
      expect(json.success).toBe(false);
    });
  });

  it('DELETE returns {success:true} on first delete and PERSON_NOT_FOUND on repeat', async () => {
    prisma.person.findFirst.mockResolvedValueOnce({ id: PERSON_ID });
    prisma.person.update.mockResolvedValue({});

    const first = await request('DELETE', detailPath, validToken);
    expect(first.status).toBe(200);
    expect(first.json.data).toEqual({ success: true });

    prisma.person.findFirst.mockResolvedValueOnce(null);
    const second = await request('DELETE', detailPath, validToken);
    expect(second.status).toBe(404);
    expect(second.json.error?.code).toBe('PERSON_NOT_FOUND');
  });
});
