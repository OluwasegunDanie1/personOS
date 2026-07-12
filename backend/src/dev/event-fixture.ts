import { config as loadEnvironment } from 'dotenv';

loadEnvironment({ quiet: true });

import { PrismaService } from '../database/prisma.service';
import { runEventFixture } from './event-fixture.logic';

/**
 * Explicit, manual, development/test-support entrypoint only. Never invoked
 * by application bootstrap, npm install, Prisma generate/migrate, tests, or
 * build. See Deployment.md and 16_Security.md for the approved fixture
 * authority boundary. Reuses AUTH_FIXTURE_EMAIL/AUTH_FIXTURE_ORGANIZATION_NAME
 * only to locate the existing controlled User/Organization. Output is
 * neutral: never prints the fixture email, organization name, Event title,
 * Event date, IDs, or any other secret/personal value.
 */
async function main(): Promise<void> {
  const prisma = new PrismaService();

  await prisma.$connect();

  try {
    const result = await runEventFixture({
      env: {
        nodeEnv: process.env.NODE_ENV,
        authFixtureEmail: process.env.AUTH_FIXTURE_EMAIL,
        authFixtureOrganizationName: process.env.AUTH_FIXTURE_ORGANIZATION_NAME,
        eventFixtureTitle: process.env.EVENT_FIXTURE_TITLE,
        eventFixtureStartDate: process.env.EVENT_FIXTURE_START_DATE,
      },
      prisma,
    });

    if (result === 'created') {
      console.log('controlled event fixture created');
    } else {
      console.log('controlled event fixture already exists');
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
