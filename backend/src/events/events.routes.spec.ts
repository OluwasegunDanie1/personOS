import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import * as http from 'http';
import { AppModule } from '../app.module';
import { GlobalExceptionFilter } from '../common/http/global-exception.filter';
import { ResponseInterceptor } from '../common/http/response.interceptor';
import { PrismaService } from '../database/prisma.service';
import { AttendanceStatus, Prisma } from '../../generated/prisma/client';
import {
  JWT_ACCESS_TOKEN_EXPIRY_SECONDS,
  JWT_ALGORITHM,
  JWT_AUDIENCE,
  JWT_ISSUER,
} from '../security/jwt.config';

const ORG_ID = '88888888-8888-8888-8888-888888888888';
const EVENT_ID = '99999999-9999-9999-9999-999999999999';
const PERSON_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

interface TestResponseBody {
  success: boolean;
  data?: Record<string, unknown>;
  error?: { code: string; message: string };
}

describe('Events/Attendance route composition', () => {
  let app: INestApplication;
  let port: number;
  let prisma: {
    user: { findUnique: jest.Mock };
    organizationMembership: { findUnique: jest.Mock };
    event: { findMany: jest.Mock; findFirst: jest.Mock; create: jest.Mock; update: jest.Mock };
    attendance: { findMany: jest.Mock; create: jest.Mock; findUnique: jest.Mock };
    person: { findFirst: jest.Mock };
  };
  let validToken: string;

  beforeAll(async () => {
    const testSecret = 'events-routes-test-secret';
    process.env.JWT_ACCESS_SECRET = testSecret;

    prisma = {
      user: { findUnique: jest.fn() },
      organizationMembership: { findUnique: jest.fn() },
      event: { findMany: jest.fn(), findFirst: jest.fn(), create: jest.fn(), update: jest.fn() },
      attendance: { findMany: jest.fn(), create: jest.fn(), findUnique: jest.fn() },
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

  const eventsPath = `/api/v1/organizations/${ORG_ID}/events`;
  const eventPath = `${eventsPath}/${EVENT_ID}`;
  const eventAttendancePath = `${eventPath}/attendance`;
  const personAttendancePath = `/api/v1/organizations/${ORG_ID}/people/${PERSON_ID}/attendance`;

  function eventRow(overrides: Partial<Record<string, unknown>> = {}) {
    return {
      id: EVENT_ID,
      title: 'Sunday Service',
      description: null,
      category: null,
      venue: null,
      startDate: new Date('2026-08-02T09:00:00.000Z'),
      endDate: null,
      createdAt: new Date('2026-01-01T00:00:00.000Z'),
      createdByUser: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace' },
      ...overrides,
    };
  }

  it('all eight routes reject a missing access token with AUTHENTICATION_REQUIRED', async () => {
    const routes: Array<[string, string]> = [
      ['GET', eventsPath],
      ['POST', eventsPath],
      ['GET', eventPath],
      ['PATCH', eventPath],
      ['DELETE', eventPath],
      ['GET', eventAttendancePath],
      ['POST', eventAttendancePath],
      ['GET', personAttendancePath],
    ];

    for (const [method, path] of routes) {
      const { status, json } = await request(method, path);
      expect(status).toBe(401);
      expect(json.error?.code).toBe('AUTHENTICATION_REQUIRED');
    }
  });

  it('rejects a valid token with no organization membership using ORGANIZATION_ACCESS_DENIED', async () => {
    prisma.organizationMembership.findUnique.mockResolvedValue(null);

    const { status, json } = await request('GET', eventsPath, validToken);

    expect(status).toBe(403);
    expect(json.error?.code).toBe('ORGANIZATION_ACCESS_DENIED');
  });

  it('GET events returns the standard envelope with events:[] and nextCursor:null when empty', async () => {
    prisma.event.findMany.mockResolvedValue([]);

    const { status, json } = await request('GET', eventsPath, validToken);

    expect(status).toBe(200);
    expect(json.success).toBe(true);
    expect(json.data).toEqual({ events: [], nextCursor: null });
  });

  it('GET events rejects an unknown query parameter (e.g. startDateFrom)', async () => {
    const { status, json } = await request('GET', `${eventsPath}?startDateFrom=2026-01-01`, validToken);

    expect(status).toBe(400);
    expect(json.success).toBe(false);
  });

  it('POST create returns HTTP 201 with the approved response shape', async () => {
    prisma.event.create.mockResolvedValue(eventRow());

    const { status, json } = await request('POST', eventsPath, validToken, {
      title: 'Sunday Service',
      startDate: '2026-08-02T09:00:00Z',
    });

    expect(status).toBe(201);
    expect(json.data).toEqual({
      event: {
        id: EVENT_ID,
        title: 'Sunday Service',
        description: null,
        category: null,
        venue: null,
        startDate: '2026-08-02T09:00:00.000Z',
        endDate: null,
        createdAt: '2026-01-01T00:00:00.000Z',
        createdBy: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace' },
      },
    });
  });

  it('POST create rejects an offset-less local datetime for startDate', async () => {
    const { status, json } = await request('POST', eventsPath, validToken, {
      title: 'Sunday Service',
      startDate: '2026-08-02T09:00:00',
    });

    expect(status).toBe(400);
    expect(json.success).toBe(false);
  });

  it('POST create rejects endDate before startDate with INVALID_EVENT_DATE_RANGE', async () => {
    const { status, json } = await request('POST', eventsPath, validToken, {
      title: 'Sunday Service',
      startDate: '2026-08-02T09:00:00Z',
      endDate: '2026-08-01T09:00:00Z',
    });

    expect(status).toBe(422);
    expect(json.error?.code).toBe('INVALID_EVENT_DATE_RANGE');
  });

  it('POST create rejects a client-supplied createdBy/organizationId as unknown fields', async () => {
    const { status } = await request('POST', eventsPath, validToken, {
      title: 'Sunday Service',
      startDate: '2026-08-02T09:00:00Z',
      createdBy: 'attacker',
      organizationId: 'attacker',
    });

    expect(status).toBe(400);
  });

  it('GET detail returns EVENT_NOT_FOUND for a cross-tenant/absent Event', async () => {
    prisma.event.findFirst.mockResolvedValue(null);

    const { status, json } = await request('GET', eventPath, validToken);

    expect(status).toBe(404);
    expect(json.error?.code).toBe('EVENT_NOT_FOUND');
  });

  it('PATCH update returns the approved response shape', async () => {
    prisma.event.findFirst.mockResolvedValue({
      id: EVENT_ID,
      startDate: new Date('2026-08-02T09:00:00.000Z'),
      endDate: null,
    });
    prisma.event.update.mockResolvedValue(eventRow({ title: 'Updated Title' }));

    const { status, json } = await request('PATCH', eventPath, validToken, { title: 'Updated Title' });

    expect(status).toBe(200);
    expect((json.data as { event: { title: string } }).event.title).toBe('Updated Title');
  });

  it('DELETE returns {success:true} on first delete and EVENT_NOT_FOUND on repeat', async () => {
    prisma.event.findFirst.mockResolvedValueOnce({ id: EVENT_ID });
    prisma.event.update.mockResolvedValue({});

    const first = await request('DELETE', eventPath, validToken);
    expect(first.status).toBe(200);
    expect(first.json.data).toEqual({ success: true });

    prisma.event.findFirst.mockResolvedValueOnce(null);
    const second = await request('DELETE', eventPath, validToken);
    expect(second.status).toBe(404);
    expect(second.json.error?.code).toBe('EVENT_NOT_FOUND');
  });

  it('GET event attendance list returns the empty shape and rejects an unknown query param', async () => {
    prisma.event.findFirst.mockResolvedValue({ id: EVENT_ID });
    prisma.attendance.findMany.mockResolvedValue([]);

    const empty = await request('GET', eventAttendancePath, validToken);
    expect(empty.status).toBe(200);
    expect(empty.json.data).toEqual({ attendance: [], nextCursor: null });

    const badParam = await request('GET', `${eventAttendancePath}?foo=bar`, validToken);
    expect(badParam.status).toBe(400);
  });

  it('POST record attendance returns 201 on first write, then 200 unchanged on a duplicate with a different status', async () => {
    prisma.event.findFirst.mockResolvedValue({ id: EVENT_ID });
    prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });

    prisma.attendance.create.mockResolvedValueOnce({
      id: 'attendance-1',
      status: AttendanceStatus.Present,
      checkedInAt: new Date('2026-08-02T09:05:00.000Z'),
      person: { id: PERSON_ID, firstName: 'Ada', lastName: 'Lovelace' },
      checkedInByUser: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace' },
    });

    const first = await request('POST', eventAttendancePath, validToken, { personId: PERSON_ID });
    expect(first.status).toBe(201);
    expect((first.json.data as { attendance: { status: string } }).attendance.status).toBe('PRESENT');

    const conflict = new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
      code: 'P2002',
      clientVersion: '7.8.0',
    });
    prisma.attendance.create.mockRejectedValueOnce(conflict);
    prisma.attendance.findUnique.mockResolvedValueOnce({
      id: 'attendance-1',
      status: AttendanceStatus.Present,
      checkedInAt: new Date('2026-08-02T09:05:00.000Z'),
      person: { id: PERSON_ID, firstName: 'Ada', lastName: 'Lovelace' },
      checkedInByUser: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace' },
    });

    const second = await request('POST', eventAttendancePath, validToken, {
      personId: PERSON_ID,
      status: 'LATE',
    });

    expect(second.status).toBe(200);
    expect((second.json.data as { attendance: { id: string; status: string } }).attendance).toEqual({
      id: 'attendance-1',
      person: { id: PERSON_ID, firstName: 'Ada', lastName: 'Lovelace' },
      status: 'PRESENT',
      checkedInBy: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace' },
      checkedInAt: '2026-08-02T09:05:00.000Z',
    });
  });

  it('POST record attendance rejects an unapproved status value', async () => {
    const { status, json } = await request('POST', eventAttendancePath, validToken, {
      personId: PERSON_ID,
      status: 'excused',
    });

    expect(status).toBe(400);
    expect(json.success).toBe(false);
  });

  it('GET person attendance history returns the empty shape and has no status query param', async () => {
    prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
    prisma.attendance.findMany.mockResolvedValue([]);

    const empty = await request('GET', personAttendancePath, validToken);
    expect(empty.status).toBe(200);
    expect(empty.json.data).toEqual({ attendance: [], nextCursor: null });

    const rejectedStatus = await request('GET', `${personAttendancePath}?status=PRESENT`, validToken);
    expect(rejectedStatus.status).toBe(400);
  });
});
