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

const ORG_ID = '66666666-6666-6666-6666-666666666666';
const PERSON_ID = '77777777-7777-7777-7777-777777777777';
const STAGE_ID = '88888888-8888-8888-8888-888888888888';
const TEMPLATE_ID = '99999999-9999-9999-9999-999999999999';

interface TestResponseBody {
  success: boolean;
  data?: Record<string, unknown>;
  error?: { code: string; message: string };
}

describe('Journey route composition', () => {
  let app: INestApplication;
  let port: number;
  let prisma: {
    user: { findUnique: jest.Mock };
    organizationMembership: { findUnique: jest.Mock };
    journeyTemplate: { findMany: jest.Mock };
    journeyStage: {
      findMany: jest.Mock;
      findFirst: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
      delete: jest.Mock;
      aggregate: jest.Mock;
    };
    person: { findFirst: jest.Mock };
    personJourneyHistory: { findMany: jest.Mock; findFirst: jest.Mock; create: jest.Mock; count: jest.Mock };
    $transaction: jest.Mock;
  };
  let validToken: string;

  beforeAll(async () => {
    const testSecret = 'journey-routes-test-secret';
    process.env.JWT_ACCESS_SECRET = testSecret;

    prisma = {
      user: { findUnique: jest.fn() },
      organizationMembership: { findUnique: jest.fn() },
      journeyTemplate: { findMany: jest.fn() },
      journeyStage: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
        aggregate: jest.fn(),
      },
      person: { findFirst: jest.fn() },
      personJourneyHistory: { findMany: jest.fn(), findFirst: jest.fn(), create: jest.fn(), count: jest.fn() },
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
    prisma.user.findUnique.mockResolvedValue({ id: 'user-1', status: 'ACTIVE', deletedAt: null });
    prisma.organizationMembership.findUnique.mockResolvedValue({
      id: 'membership-1',
      organizationId: ORG_ID,
      roleId: 'role-1',
    });
    prisma.journeyTemplate.findMany.mockResolvedValue([{ id: TEMPLATE_ID }]);
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

  const stagesPath = `/api/v1/organizations/${ORG_ID}/journey-stages`;
  const stagePath = `${stagesPath}/${STAGE_ID}`;
  const reorderPath = `${stagesPath}/reorder`;
  const journeyPath = `/api/v1/organizations/${ORG_ID}/people/${PERSON_ID}/journey`;
  const movePath = `${journeyPath}/transitions`;

  it('all Journey routes reject a missing access token with AUTHENTICATION_REQUIRED', async () => {
    const routes: Array<[string, string]> = [
      ['GET', stagesPath],
      ['POST', stagesPath],
      ['PATCH', stagePath],
      ['POST', reorderPath],
      ['DELETE', stagePath],
      ['GET', journeyPath],
      ['POST', movePath],
    ];

    for (const [method, path] of routes) {
      const { status, json } = await request(method, path);
      expect(status).toBe(401);
      expect(json.error?.code).toBe('AUTHENTICATION_REQUIRED');
    }
  });

  it('rejects a valid token with no organization membership using ORGANIZATION_ACCESS_DENIED', async () => {
    prisma.organizationMembership.findUnique.mockResolvedValue(null);

    const { status, json } = await request('GET', stagesPath, validToken);

    expect(status).toBe(403);
    expect(json.error?.code).toBe('ORGANIZATION_ACCESS_DENIED');
  });

  it('GET journey-stages returns the standard envelope with the exact list shape', async () => {
    prisma.journeyStage.findMany.mockResolvedValue([{ id: STAGE_ID, name: 'Visitor', order: 1 }]);

    const { status, json } = await request('GET', stagesPath, validToken);

    expect(status).toBe(200);
    expect(json.success).toBe(true);
    expect(json.data).toEqual({ stages: [{ id: STAGE_ID, name: 'Visitor', position: 1 }] });
  });

  it('POST journey-stages returns HTTP 201 with the exact create shape', async () => {
    prisma.journeyStage.aggregate.mockResolvedValue({ _max: { order: null } });
    prisma.journeyStage.create.mockResolvedValue({ id: STAGE_ID, name: 'Visitor', order: 1 });

    const { status, json } = await request('POST', stagesPath, validToken, { name: 'Visitor' });

    expect(status).toBe(201);
    expect(json.data).toEqual({ stage: { id: STAGE_ID, name: 'Visitor', position: 1 } });
  });

  it('POST journey-stages rejects a missing name with a validation error', async () => {
    const { status, json } = await request('POST', stagesPath, validToken, {});

    expect(status).toBe(400);
    expect(json.success).toBe(false);
  });

  it('POST reorder rejects an invalid order with INVALID_STAGE_ORDER', async () => {
    prisma.journeyStage.findMany.mockResolvedValueOnce([{ id: STAGE_ID }]);

    const { status, json } = await request('POST', reorderPath, validToken, {
      stageIds: ['11111111-1111-4111-8111-111111111111'],
    });

    expect(status).toBe(422);
    expect(json.error?.code).toBe('INVALID_STAGE_ORDER');
  });

  it('POST reorder returns HTTP 200 on success (a mutation, not a resource creation)', async () => {
    prisma.journeyStage.findMany
      .mockResolvedValueOnce([{ id: STAGE_ID }])
      .mockResolvedValueOnce([{ id: STAGE_ID, name: 'Visitor', order: 1 }]);

    const { status, json } = await request('POST', reorderPath, validToken, {
      stageIds: [STAGE_ID],
    });

    expect(status).toBe(200);
    expect(json.success).toBe(true);
  });

  it('DELETE journey-stages returns JOURNEY_STAGE_IN_USE when referenced', async () => {
    prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_ID });
    prisma.personJourneyHistory.count.mockResolvedValue(1);

    const { status, json } = await request('DELETE', stagePath, validToken);

    expect(status).toBe(409);
    expect(json.error?.code).toBe('JOURNEY_STAGE_IN_USE');
  });

  it('GET person journey returns PERSON_NOT_FOUND for a cross-tenant/absent Person', async () => {
    prisma.person.findFirst.mockResolvedValue(null);

    const { status, json } = await request('GET', journeyPath, validToken);

    expect(status).toBe(404);
    expect(json.error?.code).toBe('PERSON_NOT_FOUND');
  });

  it('GET person journey returns the standard envelope with null current stage when there is no history', async () => {
    prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
    prisma.personJourneyHistory.findMany.mockResolvedValue([]);

    const { status, json } = await request('GET', journeyPath, validToken);

    expect(status).toBe(200);
    expect(json.data).toEqual({ currentJourneyStage: null, history: [] });
  });

  it('POST movement returns HTTP 201 with the exact movement shape', async () => {
    prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
    prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_ID, name: 'Visitor' });
    prisma.personJourneyHistory.findFirst.mockResolvedValue(null);
    prisma.personJourneyHistory.create.mockResolvedValue({
      id: 'history-1',
      notes: null,
      movedAt: new Date('2026-01-01T00:00:00.000Z'),
      fromStage: null,
      toStage: { id: STAGE_ID, name: 'Visitor' },
      movedByUser: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace' },
    });

    const { status, json } = await request('POST', movePath, validToken, { stageId: STAGE_ID });

    expect(status).toBe(201);
    expect(json.data).toEqual({
      movement: {
        id: 'history-1',
        fromStage: null,
        toStage: { id: STAGE_ID, name: 'Visitor' },
        note: null,
        movedAt: '2026-01-01T00:00:00.000Z',
        movedBy: { id: 'user-1', firstName: 'Ada', lastName: 'Lovelace' },
      },
    });
  });

  it('POST movement rejects the client submitting movedBy/movedAt/fromStageId/organizationId/templateId', async () => {
    const { status, json } = await request('POST', movePath, validToken, {
      stageId: STAGE_ID,
      movedBy: 'attacker',
      movedAt: '2000-01-01T00:00:00.000Z',
      fromStageId: 'x',
      organizationId: 'x',
      templateId: 'x',
    });

    expect(status).toBe(400);
    expect(json.success).toBe(false);
  });

  it('POST movement rejects same-stage movement with PERSON_ALREADY_IN_STAGE', async () => {
    prisma.person.findFirst.mockResolvedValue({ id: PERSON_ID });
    prisma.journeyStage.findFirst.mockResolvedValue({ id: STAGE_ID, name: 'Visitor' });
    prisma.personJourneyHistory.findFirst.mockResolvedValue({ toStageId: STAGE_ID });

    const { status, json } = await request('POST', movePath, validToken, { stageId: STAGE_ID });

    expect(status).toBe(409);
    expect(json.error?.code).toBe('PERSON_ALREADY_IN_STAGE');
  });
});
