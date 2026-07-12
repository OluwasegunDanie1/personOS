import { config as loadEnvironment } from 'dotenv';

loadEnvironment({ quiet: true });

import { PrismaService } from '../database/prisma.service';
import { runJourneyFixture } from './journey-fixture.logic';

/**
 * Explicit, manual, development/test-support entrypoint only. Never invoked
 * by application bootstrap, npm install, Prisma generate/migrate, tests, or
 * build. See Deployment.md and 16_Security.md for the approved fixture
 * authority boundary. Reuses AUTH_FIXTURE_EMAIL/AUTH_FIXTURE_ORGANIZATION_NAME
 * only to locate the existing controlled User/Organization.
 */
async function main(): Promise<void> {
  const prisma = new PrismaService();

  await prisma.$connect();

  try {
    const result = await runJourneyFixture({
      env: {
        nodeEnv: process.env.NODE_ENV,
        authFixtureEmail: process.env.AUTH_FIXTURE_EMAIL,
        authFixtureOrganizationName: process.env.AUTH_FIXTURE_ORGANIZATION_NAME,
        journeyFixtureTemplateName: process.env.JOURNEY_FIXTURE_TEMPLATE_NAME,
        journeyFixtureStageOneName: process.env.JOURNEY_FIXTURE_STAGE_ONE_NAME,
        journeyFixtureStageTwoName: process.env.JOURNEY_FIXTURE_STAGE_TWO_NAME,
      },
      prisma,
    });

    if (result === 'created') {
      console.log('controlled journey fixture created');
    } else {
      console.log('controlled journey fixture already exists');
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
