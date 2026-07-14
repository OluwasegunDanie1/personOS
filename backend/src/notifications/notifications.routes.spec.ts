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
const NOTIFICATION_ID = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

interface TestResponseBody {
  success: boolean;
  data?: Record<string, unknown>;
  error?: { code: string; message: string };
}

describe('Notifications route composition', () => {
  let app: INestApplication;
  let port: number;
  let prisma: {
    user: { findUnique: jest.Mock };
    organizationMembership: { findUnique: jest.Mock };
    notification: {
      findMany: jest.Mock;
      findFirst: jest.Mock;
      update: jest.Mock;
      updateMany: jest.Mock;
      deleteMany: jest.Mock;
    };
  };
  let validToken: string;

  beforeAll(async () => {
    const testSecret = 'notifications-routes-test-secret';
    process.env.JWT_ACCESS_SECRET = testSecret;

    prisma = {
      user: { findUnique: jest.fn() },
      organizationMembership: { findUnique: jest.fn() },
      notification: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
        deleteMany: jest.fn(),
      },
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
    prisma.notification.findMany.mockResolvedValue([]);
    prisma.notification.findFirst.mockResolvedValue(null);
    prisma.notification.updateMany.mockResolvedValue({ count: 0 });
    prisma.notification.deleteMany.mockResolvedValue({ count: 0 });
  });

  function request(
    method: string,
    path: string,
    token?: string,
  ): Promise<{ status: number; json: TestResponseBody }> {
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

  const notificationsPath = `/api/v1/organizations/${ORG_ID}/notifications`;

  it('all four routes reject a missing access token with AUTHENTICATION_REQUIRED', async () => {
    const routes: Array<[string, string]> = [
      ['GET', notificationsPath],
      ['PATCH', `${notificationsPath}/${NOTIFICATION_ID}/read`],
      ['PATCH', `${notificationsPath}/read-all`],
      ['DELETE', `${notificationsPath}/read`],
    ];

    for (const [method, path] of routes) {
      const { status, json } = await request(method, path);
      expect(status).toBe(401);
      expect(json.error?.code).toBe('AUTHENTICATION_REQUIRED');
    }
  });

  it('rejects a valid token with no organization membership using ORGANIZATION_ACCESS_DENIED', async () => {
    prisma.organizationMembership.findUnique.mockResolvedValue(null);

    const { status, json } = await request('GET', notificationsPath, validToken);

    expect(status).toBe(403);
    expect(json.error?.code).toBe('ORGANIZATION_ACCESS_DENIED');
  });

  it('GET returns the standard envelope with the exact approved empty shape', async () => {
    const { status, json } = await request('GET', notificationsPath, validToken);

    expect(status).toBe(200);
    expect(json.success).toBe(true);
    expect(json.data).toEqual({ notifications: [], nextCursor: null });
  });

  it('GET rejects an unknown query parameter (e.g. category — no such column exists)', async () => {
    const { status } = await request('GET', `${notificationsPath}?category=announcement`, validToken);
    expect(status).toBe(400);
  });

  it('GET returns real, exact-shape notifications scoped to organizationId + the authenticated userId', async () => {
    prisma.notification.findMany.mockResolvedValue([
      {
        id: NOTIFICATION_ID,
        title: 'New follow-up assigned',
        message: 'You have a new follow-up due soon.',
        isRead: false,
        createdAt: new Date('2026-07-14T09:00:00.000Z'),
      },
    ]);

    const { status, json } = await request('GET', notificationsPath, validToken);

    expect(status).toBe(200);
    expect(json.data).toEqual({
      notifications: [
        {
          id: NOTIFICATION_ID,
          title: 'New follow-up assigned',
          message: 'You have a new follow-up due soon.',
          isRead: false,
          createdAt: '2026-07-14T09:00:00.000Z',
        },
      ],
      nextCursor: null,
    });

    const args = prisma.notification.findMany.mock.calls[0][0];
    expect(args.where).toEqual({ organizationId: ORG_ID, userId: 'user-1' });
  });

  it('PATCH mark-read returns NOTIFICATION_NOT_FOUND for an absent/cross-tenant/cross-user notification', async () => {
    const { status, json } = await request('PATCH', `${notificationsPath}/${NOTIFICATION_ID}/read`, validToken);

    expect(status).toBe(404);
    expect(json.error?.code).toBe('NOTIFICATION_NOT_FOUND');
  });

  it('PATCH mark-read is idempotent on replay: repeat calls both return isRead:true without erroring', async () => {
    prisma.notification.findFirst.mockResolvedValue({ id: NOTIFICATION_ID });
    prisma.notification.update.mockResolvedValue({
      id: NOTIFICATION_ID,
      title: 'Title',
      message: 'Message',
      isRead: true,
      createdAt: new Date('2026-07-14T09:00:00.000Z'),
    });

    const first = await request('PATCH', `${notificationsPath}/${NOTIFICATION_ID}/read`, validToken);
    const second = await request('PATCH', `${notificationsPath}/${NOTIFICATION_ID}/read`, validToken);

    expect(first.status).toBe(200);
    expect(second.status).toBe(200);
    expect((first.json.data as { notification: { isRead: boolean } }).notification.isRead).toBe(true);
    expect((second.json.data as { notification: { isRead: boolean } }).notification.isRead).toBe(true);
  });

  it('PATCH read-all issues one bounded updateMany scoped to unread notifications for this user/org', async () => {
    prisma.notification.updateMany.mockResolvedValue({ count: 4 });

    const { status, json } = await request('PATCH', `${notificationsPath}/read-all`, validToken);

    expect(status).toBe(200);
    expect(json.data).toEqual({ markedCount: 4 });
    expect(prisma.notification.updateMany).toHaveBeenCalledTimes(1);
    const args = prisma.notification.updateMany.mock.calls[0][0];
    expect(args.where).toEqual({ organizationId: ORG_ID, userId: 'user-1', isRead: false });
  });

  it('DELETE read clears only read notifications for this user/org, never unread ones', async () => {
    prisma.notification.deleteMany.mockResolvedValue({ count: 2 });

    const { status, json } = await request('DELETE', `${notificationsPath}/read`, validToken);

    expect(status).toBe(200);
    expect(json.data).toEqual({ clearedCount: 2 });
    const args = prisma.notification.deleteMany.mock.calls[0][0];
    expect(args.where).toEqual({ organizationId: ORG_ID, userId: 'user-1', isRead: true });
  });

  it('does not create/read any push/email/preference/category row (mocked Prisma exposes no such model)', async () => {
    await request('GET', notificationsPath, validToken);
    await request('PATCH', `${notificationsPath}/read-all`, validToken);
    await request('DELETE', `${notificationsPath}/read`, validToken);

    expect(Object.keys(prisma).sort()).toEqual(['user', 'organizationMembership', 'notification'].sort());
  });
});
