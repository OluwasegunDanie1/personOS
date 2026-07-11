import { UserStatus } from '../../generated/prisma/client';

/**
 * firstName/lastName have no database default and are NOT NULL on User, but
 * the approved fixture shape (Deployment.md) does not define them since they
 * carry no behavioral significance for the login/refresh/logout lifecycle
 * this fixture exists to support. These are mechanical placeholders only.
 */
const FIXTURE_FIRST_NAME = 'Auth';
const FIXTURE_LAST_NAME = 'Fixture';

export type AuthFixtureResult = 'created' | 'already_exists';

export interface AuthFixturePrisma {
  user: {
    findUnique(args: { where: { email: string } }): Promise<{ id: string } | null>;
    create(args: {
      data: {
        email: string;
        passwordHash: string;
        phone: null;
        status: UserStatus;
        lastLogin: null;
        deletedAt: null;
        firstName: string;
        lastName: string;
      };
    }): Promise<unknown>;
  };
}

export interface AuthFixturePasswordHashService {
  hash(password: string): Promise<string>;
}

export interface AuthFixtureEnv {
  nodeEnv: string | undefined;
  authFixtureEmail: string | undefined;
  authFixturePassword: string | undefined;
}

export interface AuthFixtureDeps {
  env: AuthFixtureEnv;
  prisma: AuthFixturePrisma;
  passwordHashService: AuthFixturePasswordHashService;
}

/**
 * Creates (or confirms) exactly one controlled local User for live local
 * authentication lifecycle verification, per the authority defined in
 * Deployment.md and 16_Security.md. Idempotent per normalized email; never
 * mutates an already-existing matching User.
 */
export async function runAuthFixture(deps: AuthFixtureDeps): Promise<AuthFixtureResult> {
  if (deps.env.nodeEnv === 'production') {
    throw new Error('The controlled auth fixture must not run when NODE_ENV=production.');
  }

  if (!deps.env.authFixtureEmail) {
    throw new Error('AUTH_FIXTURE_EMAIL is required.');
  }

  if (!deps.env.authFixturePassword) {
    throw new Error('AUTH_FIXTURE_PASSWORD is required.');
  }

  const normalizedEmail = deps.env.authFixtureEmail.trim().toLowerCase();

  const existing = await deps.prisma.user.findUnique({ where: { email: normalizedEmail } });

  if (existing) {
    return 'already_exists';
  }

  const passwordHash = await deps.passwordHashService.hash(deps.env.authFixturePassword);

  await deps.prisma.user.create({
    data: {
      email: normalizedEmail,
      passwordHash,
      phone: null,
      status: UserStatus.ACTIVE,
      lastLogin: null,
      deletedAt: null,
      firstName: FIXTURE_FIRST_NAME,
      lastName: FIXTURE_LAST_NAME,
    },
  });

  return 'created';
}
