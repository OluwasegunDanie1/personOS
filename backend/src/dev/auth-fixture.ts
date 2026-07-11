import { config as loadEnvironment } from 'dotenv';

loadEnvironment({ quiet: true });

import { PrismaService } from '../database/prisma.service';
import { PasswordHashService } from '../security/password-hash.service';
import { runAuthFixture } from './auth-fixture.logic';

/**
 * Explicit, manual, development/test-support entrypoint only. Never invoked
 * by application bootstrap, npm install, Prisma generate/migrate, tests, or
 * build. See Deployment.md and 16_Security.md for the approved fixture
 * authority boundary.
 */
async function main(): Promise<void> {
  const prisma = new PrismaService();
  const passwordHashService = new PasswordHashService();

  await prisma.$connect();

  try {
    const result = await runAuthFixture({
      env: {
        nodeEnv: process.env.NODE_ENV,
        authFixtureEmail: process.env.AUTH_FIXTURE_EMAIL,
        authFixturePassword: process.env.AUTH_FIXTURE_PASSWORD,
      },
      prisma,
      passwordHashService,
    });

    if (result === 'created') {
      console.log('controlled auth fixture created');
    } else {
      console.log('controlled auth fixture already exists');
    }
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : 'Unknown error';
  console.error(message);
  process.exitCode = 1;
});
