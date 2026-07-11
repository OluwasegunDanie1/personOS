import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as http from 'http';
import { AppModule } from '../app.module';
import { GlobalExceptionFilter } from '../common/http/global-exception.filter';
import { ResponseInterceptor } from '../common/http/response.interceptor';
import { PrismaService } from '../database/prisma.service';

/**
 * Confirms the three auth endpoints resolve under the global /api/v1 prefix,
 * mirroring main.ts's bootstrap composition. PrismaService is overridden so
 * this never requires a live PostgreSQL connection; requests below are
 * deliberately invalid so they are rejected by the global ValidationPipe
 * before reaching AuthService.
 */
describe('Auth route composition', () => {
  let app: INestApplication;
  let port: number;

  beforeAll(async () => {
    process.env.JWT_ACCESS_SECRET ??= 'test-only-placeholder-secret';

    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PrismaService)
      .useValue({})
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
  });

  afterAll(async () => {
    await app.close();
  });

  function post(path: string, body: unknown): Promise<number> {
    return new Promise((resolve, reject) => {
      const payload = JSON.stringify(body);
      const req = http.request(
        {
          host: '127.0.0.1',
          port,
          path,
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) },
        },
        (res) => {
          res.on('data', () => undefined);
          res.on('end', () => resolve(res.statusCode ?? 0));
        },
      );
      req.on('error', reject);
      req.write(payload);
      req.end();
    });
  }

  it('resolves POST /api/v1/auth/login and remains public (no access token supplied)', async () => {
    const status = await post('/api/v1/auth/login', { email: 'not-an-email', password: '' });

    expect(status).not.toBe(404);
    expect(status).not.toBe(401);
  });

  it('resolves POST /api/v1/auth/refresh and remains public (no access token supplied)', async () => {
    const status = await post('/api/v1/auth/refresh', { refreshToken: '' });

    expect(status).not.toBe(404);
    expect(status).not.toBe(401);
  });

  it('resolves POST /api/v1/auth/logout and remains public (no access token supplied)', async () => {
    const status = await post('/api/v1/auth/logout', { refreshToken: '' });

    expect(status).not.toBe(404);
    expect(status).not.toBe(401);
  });

  it('does not register auth routes outside the /api/v1 prefix', async () => {
    const status = await post('/auth/login', { email: 'not-an-email', password: '' });

    expect(status).toBe(404);
  });
});
