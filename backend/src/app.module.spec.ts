import { Test, TestingModule } from '@nestjs/testing';
import { AppModule } from './app.module';

describe('AppModule', () => {
  let moduleRef: TestingModule;

  beforeAll(async () => {
    // Prisma 7 requires a driver adapter to be constructed with a connection
    // string, even though no query is executed in this test. This placeholder
    // is never used to open a real connection; only module compilation and
    // dependency wiring are verified here.
    process.env.DATABASE_URL ??=
      'postgresql://test:test@localhost:5432/relvio_test';

    // SecurityModule's JwtModule factory requires JWT_ACCESS_SECRET to be
    // present at module construction. This placeholder is never used to sign
    // a real token; only module compilation and dependency wiring are
    // verified here.
    process.env.JWT_ACCESS_SECRET ??= 'test-only-placeholder-secret';

    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
  });

  afterAll(async () => {
    await moduleRef.close();
  });

  it('compiles the root module', () => {
    expect(moduleRef).toBeDefined();
  });
});
