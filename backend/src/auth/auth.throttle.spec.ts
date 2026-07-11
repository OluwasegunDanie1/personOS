import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import * as http from 'http';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

/**
 * Confirms the ThrottlerGuard's default tracker resolves from NestJS/Express
 * request IP handling (req.ip) rather than any application-supplied field
 * such as email, user id, token, or device identity.
 */
describe('AuthController throttling', () => {
  it('tracks requests using req.ip, not an application-supplied field', async () => {
    const guard = new ThrottlerGuard(
      [{ name: 'default', ttl: 60_000, limit: 5 }],
      { increment: jest.fn() } as never,
      { getAllAndOverride: jest.fn().mockReturnValue(undefined) } as never,
    );

    const tracker = await (guard as unknown as { getTracker(req: Record<string, unknown>): Promise<string> }).getTracker(
      { ip: '203.0.113.7', body: { email: 'ada@example.com' } },
    );

    expect(tracker).toBe('203.0.113.7');
  });

  it('rejects the 6th request within the window with HTTP 429 (login limit is 5/60s)', async () => {
    const authService = {
      login: jest.fn().mockResolvedValue({ accessToken: 'a', refreshToken: 'r', expiresIn: 900, user: {} }),
      refresh: jest.fn(),
      logout: jest.fn(),
    };

    const moduleRef = await Test.createTestingModule({
      imports: [ThrottlerModule.forRoot([{ name: 'default', ttl: 60_000, limit: 5 }])],
      controllers: [AuthController],
      providers: [{ provide: AuthService, useValue: authService }, ThrottlerGuard],
    }).compile();

    const app: INestApplication = moduleRef.createNestApplication();
    await app.init();
    await app.listen(0);

    const address = app.getHttpServer().address();
    const port = typeof address === 'object' && address ? address.port : 0;

    const postLogin = (): Promise<number> =>
      new Promise((resolve, reject) => {
        const payload = JSON.stringify({ email: 'ada@example.com', password: 'correct-password' });
        const req = http.request(
          {
            host: '127.0.0.1',
            port,
            path: '/auth/login',
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

    const statuses: number[] = [];
    for (let i = 0; i < 6; i += 1) {
      statuses.push(await postLogin());
    }

    expect(statuses.slice(0, 5)).toEqual([200, 200, 200, 200, 200]);
    expect(statuses[5]).toBe(429);

    await app.close();
  });
});
