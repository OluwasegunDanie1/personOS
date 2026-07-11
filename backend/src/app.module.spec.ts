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
