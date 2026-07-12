---
Document: Deployment
Version: 1.1
Status: Approved
Project: Relvio
Owner: Engineering Team
---

# Deployment

## Purpose

This document defines the deployment and release principles for Relvio.

It covers the controlled delivery of:

- Flutter mobile applications
- Backend REST API services
- PostgreSQL database migrations
- Environment-specific configuration

The goal is to make Relvio releases:

- Predictable
- Repeatable
- Secure
- Observable
- Recoverable where technically possible

This document does not select a cloud provider, CI/CD vendor, mobile distribution service, monitoring vendor, or infrastructure platform unless separately approved.

AI coding assistants must not invent deployment infrastructure.

---

# Relvio Deployment Scope

Relvio v1 supports:

```text
Android
iOS





The approved client technology is:

Flutter

The approved application architecture is:

Flutter
    ↓
Backend REST API
    ↓
PostgreSQL

The API base is:

/api/v1

Flutter must never connect directly to PostgreSQL.

Deployment processes must preserve this architecture.

Deployment Boundaries

Relvio contains independently deployable technical boundaries.

These include:

Flutter Mobile Client
Backend REST API
PostgreSQL Database Migrations

These boundaries must not be treated as one identical deployment target.

Each has different:

Build requirements
Release behavior
Rollback capabilities
Distribution constraints
Validation requirements

A backend deployment is not equivalent to an Android or iOS release.

A database migration is not equivalent to an application deployment.

Deployment automation must respect these differences.

Deployment Principles

Relvio deployment should be:

Repeatable
Controlled
Verifiable
Secure
Observable
Appropriate to the deployment target

Automation should be introduced where it reduces human error and improves release reliability.

Manual release steps may remain where:

A platform requires them
App store workflows require review or approval
Infrastructure has not yet justified additional automation
A controlled manual approval is intentionally required

Do not build complex deployment infrastructure before Relvio v1 needs it.

Core product validation takes priority over premature deployment complexity.

Environment Strategy

Relvio requires clear environment separation.

The minimum conceptual environments are:

Local
Non-Production
Production

A separate staging environment may be introduced when required for production-like validation.

A separate shared development environment may also be introduced when team workflow requires it.

The existence of these conceptual environments does not require four independently hosted environments from the beginning.

Environment infrastructure should grow with actual engineering and validation needs.

Local Environment

The local environment is used for:

Feature development
Debugging
Local automated testing
Local API development
Migration development
Controlled implementation verification

Local configuration must not use production secrets.

Local development must not require direct Flutter access to PostgreSQL.

The Flutter client should communicate with the configured backend API.

Non-Production Environment

A non-production environment may be used for:

Backend integration testing
Mobile integration testing
API verification
Database migration verification
Team testing
QA
Approved release validation

Non-production data and credentials must remain separate from production.

Production secrets must not be copied into non-production environments.

Where realistic test data is required, do not use sensitive production data without an explicitly approved secure process.

Staging Environment

A dedicated staging environment may be introduced when Relvio requires production-like release validation.

Staging should approximate relevant production behavior closely enough to validate:

API deployment
Authentication flows
Organization membership behavior
Roles and permissions
Organization isolation
Database migrations
Critical feature flows
Mobile API integration

Staging does not need to be physically or operationally identical to production.

Differences between staging and production that affect release confidence must be understood and documented.

Do not claim that staging behaves exactly like production.

Production Environment

Production serves live Relvio organizations and users.

Production deployment must protect:

User access
Organization isolation
Authentication
Authorization
Data integrity
Journey history
Attendance integrity
Service availability

Production changes require appropriate validation for their risk.

High-risk changes require stronger release controls than low-risk changes.

Release Flow

The normal engineering flow is conceptually:

Implementation
    ↓
Local Validation
    ↓
Code Review
    ↓
Automated Verification
    ↓
Non-Production Validation
    ↓
Release Approval
    ↓
Target-Specific Production Release
    ↓
Post-Release Verification

The exact workflow may evolve with the engineering team and approved CI/CD configuration.

Do not create workflow stages merely to satisfy this diagram.

The important requirement is that critical production changes receive appropriate verification before release.

Risk-Based Release Validation

Not every change has the same deployment risk.

Release validation should consider whether a change affects:

Authentication
Organization membership
Roles
Permissions
Organization isolation
Attendance
Journey transitions
Database schema
Data migration
API contracts
Destructive operations
Mobile authentication state
Critical navigation
Production configuration

Changes affecting these areas require stronger validation.

Critical behavior and data integrity matter more than arbitrary checklist completion.

Testing requirements are governed by:

15_Testing_Strategy.md

Security requirements are governed by:

16_Security.md
Flutter Mobile Release

Relvio v1 Flutter releases target:

Android
iOS

Do not configure production release pipelines for:

Web
Windows
macOS
Linux

unless those platforms are explicitly approved in future product scope.

The existence of Flutter platform support does not make a platform part of the Relvio product.

Flutter Build Validation

Before creating a release build, verify as appropriate:

Dependencies resolve successfully
Required code generation completes
Static analysis passes
Critical automated tests pass
Approved environment configuration is selected
API configuration points to the intended environment
Approved assets are available
Android build configuration is valid
iOS build configuration is valid
Release version information is updated
No secrets are unintentionally bundled

The exact automated pipeline may depend on the approved CI/CD platform.

Flutter Environment Configuration

The Flutter application may require environment-specific non-secret configuration such as:

API base URL
Build environment identifier
Approved feature configuration

Flutter configuration must not contain backend secrets.

Do not place the following in the mobile application:

DATABASE_URL
Database credentials
JWT signing secrets
Backend private keys
SMTP passwords
Private storage credentials

A mobile application is a distributed client.

Values bundled with the application must not be treated as secret merely because they are stored in an environment file.

Security rules are governed by:

16_Security.md
API Base Configuration

The Flutter client must communicate with the Relvio backend REST API.

The approved API base path is:

/api/v1

Environment-specific host configuration may differ.

Conceptually:

Local API Host + /api/v1
Non-Production API Host + /api/v1
Production API Host + /api/v1

Do not hardcode production API hosts throughout feature code.

API configuration should be centralized according to approved engineering and project structure standards.

Backend Deployment

The backend REST API is deployed independently from the Flutter mobile application.

Backend deployment should verify as appropriate:

Dependencies install successfully.
Build or compilation steps complete.
Static analysis or linting passes where configured.
Critical automated tests pass.
Required configuration is available.
Database migration requirements are known.
The application starts successfully.
Health or readiness verification succeeds where implemented.
Critical API behavior is verified after deployment.

The exact backend commands depend on the approved backend technology and deployment platform.

This document must not invent them.

Backend Configuration

Backend secrets and sensitive configuration must be stored using the approved deployment environment or secret management mechanism.

Possible configuration responsibilities include:

Database connection configuration
Authentication signing configuration
External service credentials
Storage credentials
Email service credentials
Environment identifiers

These are responsibility examples.

They are not approved environment variable names or approved service integrations.

Do not create integrations because they appear in this document.

Actual configuration names must come from the approved backend implementation.

Authentication Secret Configuration

JWT_ACCESS_SECRET is a required backend secret used to sign access tokens.

JWT_ACCESS_SECRET must:

Never be committed to source control.
Never be exposed to the Flutter application.
Have no hardcoded fallback value.

Backend authentication configuration must fail clearly when JWT_ACCESS_SECRET is absent.

For the minimal login, refresh, and logout implementation phase, JWT_ACCESS_SECRET is the only newly required authentication secret. Refresh, email-verification, and password-reset tokens are opaque random values that are hashed for storage and do not require a separate signing secret.

Local Backend Runtime Environment Loading

The local NestJS backend runtime must load backend/.env before any module or configuration primitive reads process.env, including during application bootstrap. The already-approved dotenv package is approved for this purpose. Do not approve a second configuration or environment-loading package merely for this responsibility.

The standard local development start command must load backend/.env automatically. A developer must not be required to manually prepend a one-off Node preload flag to start the backend locally.

Requirements:

backend/.env remains Git-ignored.
No environment value may be logged.
No hardcoded DATABASE_URL fallback.
No hardcoded JWT_ACCESS_SECRET fallback.
Production must continue receiving secrets from the deployment environment and must not depend on a committed .env file.
Environment loading must occur before modules or configuration primitives read process.env.

This document defines this authority boundary only. Implementing the loading mechanism is authorized as a separate implementation task.

Trust-Proxy Environment Configuration

TRUST_PROXY is the approved backend environment variable controlling Express trust proxy configuration for the public authentication rate-limit boundary. Its value is the explicitly configured trusted proxy hop count, expressed as a positive integer. It has no hardcoded fallback.

Local development: Express trust proxy remains disabled; TRUST_PROXY is not required.

Non-production and production: TRUST_PROXY is required before publicly exposing the authentication endpoints. Backend configuration must fail clearly when TRUST_PROXY is required and absent or empty.

NODE_ENV distinguishes development, test, and production for this authority. No additional environment-naming variable is introduced. A separately deployed non-production environment must configure TRUST_PROXY under this same rule before publicly exposing authentication endpoints.

Full behavioral detail is governed by 16_Security.md.

Authentication Public-Exposure Readiness

Resolved for the login/refresh/logout boundary:

Rate-limit package: @nestjs/throttler
Login threshold: 5 requests per 60 seconds per client IP
Refresh threshold: 10 requests per 60 seconds per client IP
Logout threshold: 20 requests per 60 seconds per client IP
Rate-limit key: client IP only, via standard NestJS/Express request IP handling
Trust-proxy configuration: TRUST_PROXY (see above and 16_Security.md)
CORS: not applicable to the native-mobile boundary; no policy introduced; browser exposure remains unapproved

The following remain intentionally unresolved and must be decided before the affected endpoints are exposed to public production traffic:

Exact forgot-password rate-limit threshold/window
Email verification delivery provider/mechanism
Password-reset delivery provider/mechanism

Do not implement email verification or password-reset delivery until delivery infrastructure is approved.

Local Authentication Fixture (Development/Test Support)

Relvio approves exactly one development/test-support mechanism for creating a controlled local authentication fixture. Its sole purpose is to enable manual, live local verification of the following authentication lifecycle against a real local backend and local database: login, refresh rotation, reuse of the revoked old refresh token and family revocation, a fresh login, logout, and reuse of the logged-out refresh token. The fixture itself must not perform this lifecycle; it only creates the controlled User needed to exercise it manually.

This fixture is not: public registration, signup, production user provisioning, initial Owner creation, organization creation, product onboarding, or a general-purpose database seed. It does not implement, replace, or weaken the future POST /auth/register product registration workflow, which remains a separately governed contract under 13_API_Specification.md.

Scope: the fixture may create exactly one global User record. It must not create an Organization, OrganizationMembership, Role, Permission, Person, Event, Attendance, any other product-domain record, a refresh token, an email-verification token, or a password-reset token.

Input: the fixture reads exactly two local environment variables, AUTH_FIXTURE_EMAIL and AUTH_FIXTURE_PASSWORD. Both are required; an absent or empty value must fail clearly. No default or hardcoded fixture credentials are approved.

User shape: email is normalized using trim and lowercase; passwordHash is produced using the existing PasswordHashService/approved Argon2id primitive, with no duplicated Argon2 configuration; phone is null; status is ACTIVE; lastLogin is null; deletedAt is null. Database-default fields apply normally. No email-verification state is invented, since the approved User schema has no such field.

Idempotency: the fixture is idempotent for the normalized fixture email. If no matching User exists, it creates the controlled User. If a matching User already exists, the fixture must not create a duplicate and must not overwrite passwordHash, status, phone, lastLogin, or deletedAt; it completes successfully without modification. A Prisma upsert that would update an existing User is not approved for this purpose.

Execution boundary: the fixture must refuse to run when NODE_ENV=production. It is approved for explicit, manual developer invocation under NODE_ENV=development, and for explicit test invocation under NODE_ENV=test. It must never run automatically during application bootstrap, npm install, Prisma generate, Prisma migrate, automated test runs, or build. No Prisma seed hook and no general-purpose seed framework are approved for this mechanism.

Credential-handling and security requirements for this fixture are governed by 16_Security.md.

This document defines this fixture's authority boundary only. Implementing the fixture command is authorized as a separate implementation task.

Local Organization Fixture (Development/Test Support)

Relvio approves one additional, separate development/test-support mechanism extending the controlled auth-fixture concept, used solely to enable live local verification of organization listing and organization-membership enforcement.

This fixture is not public registration, signup, production provisioning, initial Owner onboarding as a product workflow, general organization creation, product onboarding, or a general-purpose database seed. It does not implement an organization-creation API and does not replace a future registration/onboarding contract.

Scope: the fixture may create exactly one Organization, one Role (named Owner) owned by that Organization, and one OrganizationMembership linking the existing controlled fixture User to that Role and Organization. It must create zero Permission records, zero RolePermission records, and zero records of any other product-domain or auth-token model.

Input: the fixture reads the required AUTH_FIXTURE_ORGANIZATION_NAME environment variable (trimmed, must be non-empty, no default). It reuses the existing AUTH_FIXTURE_EMAIL only to locate the already-existing controlled fixture User; it must not read or require AUTH_FIXTURE_PASSWORD.

Idempotency: the fixture is idempotent. Existing matching records must not be mutated; no upsert-that-updates is approved.

Execution boundary: the fixture must refuse to run when NODE_ENV=production. It is manual invocation only and must never auto-run during application bootstrap, npm install, Prisma generate, Prisma migrate, tests, or build.

Credential-handling and security requirements for this fixture are governed by 16_Security.md.

This document defines this fixture's authority boundary only. Implementing the fixture command is authorized as a separate implementation task.

Local Person Fixture (Development/Test Support)

Relvio approves one additional, separate development/test-support mechanism extending the controlled-fixture concept, used solely to enable live local verification of the People list/detail endpoints.

This fixture is not product onboarding and does not implement or replace POST /organizations/{organizationId}/people.

Scope: the fixture may create exactly one Person inside the existing controlled fixture Organization, with email null, phone null, avatarUrl null, status ACTIVE, and deletedAt null. It must create zero Tag, PersonTag, JourneyTemplate, JourneyStage, PersonJourneyHistory, Attendance, FollowUp, Note, Report, Notification, AuditLog, or auth-token record.

Input: the fixture reads the required PERSON_FIXTURE_FIRST_NAME and PERSON_FIXTURE_LAST_NAME environment variables (trimmed, must be non-empty, no default). It reuses the existing AUTH_FIXTURE_EMAIL and AUTH_FIXTURE_ORGANIZATION_NAME only to locate the already-existing controlled fixture User, membership, and Organization.

Idempotency: the fixture is idempotent on (controlled fixture Organization, normalized firstName, normalized lastName, null email, null phone). An existing exact, non-deleted match must not be mutated; no upsert-that-updates is approved. A matching but soft-deleted Person, or multiple exact matches, fail clearly rather than being repaired or guessed.

Execution boundary: the fixture must refuse to run when NODE_ENV=production. It is manual invocation only and must never auto-run during application bootstrap, npm install, Prisma generate, Prisma migrate, tests, or build. No Prisma seed hook is approved for this mechanism.

Credential-handling and security requirements for this fixture are governed by 16_Security.md.

This document defines this fixture's authority boundary only. Implementing the fixture command is authorized as a separate implementation task.

Database Deployment

PostgreSQL is the approved primary relational database.

Database schema changes must be managed through versioned migrations.

Migration rules:

Create migrations intentionally.
Review schema changes.
Do not manually change production schema as the normal deployment process.
Do not silently edit a migration that has already been applied to shared or production environments.
Create a new corrective migration when an applied schema change requires modification.
Test high-risk migrations before production.
Understand data impact before deployment.

Migration tooling must follow the approved backend technology once selected or documented.

Do not invent a migration framework independently.

Multi-Tenant Migration Safety

Relvio is a multi-tenant SaaS.

Organization isolation is a critical backend security boundary.

Database migrations must be reviewed for impact on:

Organization-scoped tables
Organization ownership relationships
Membership data
Role and permission data
Queries used for organization isolation
Unique constraints
Foreign keys
Indexes
Data backfills

A migration must not weaken organization isolation.

Data backfills involving organization-scoped records must preserve correct organization ownership.

Do not deploy a migration that creates ambiguous tenant ownership for protected records.

Attendance Migration Safety

Attendance requires backend integrity controls and idempotency.

Database changes affecting attendance must be reviewed for:

Existing attendance records
Uniqueness requirements
Idempotency behavior
Duplicate prevention
Event relationships
Person relationships
Organization ownership

A migration must not silently invalidate attendance integrity guarantees.

Critical attendance migration behavior should be tested according to:

15_Testing_Strategy.md
Journey Migration Safety

Journey transitions preserve immutable journey history.

Database changes affecting journey data must protect:

Existing transition history
Transition ordering where relevant
Organization ownership
Person relationships
Stage relationships
Historical timestamps
Historical transition records

Do not rewrite or collapse immutable journey history merely to simplify a schema migration.

Any migration that intentionally transforms historical journey data requires explicit review.

Migration Compatibility

Backend and database changes should consider deployment ordering.

Where practical, schema changes should be compatible with the currently deployed backend during the release transition.

For higher-risk changes, prefer staged migration patterns such as:

Add compatible schema
    ↓
Deploy compatible backend
    ↓
Migrate or backfill data
    ↓
Verify
    ↓
Remove deprecated schema in a later controlled change

This pattern is guidance, not a mandatory process for every migration.

Simple low-risk migrations do not require unnecessary multi-release complexity.

Database Backup and Recovery

Production database backup and recovery capability must exist.

Backup strategy should be appropriate to the approved database hosting environment.

Before a high-risk migration or destructive production data operation, verify appropriate recovery capability.

Do not assume that manually creating a new full backup before every code deployment is always required.

Deployment risk determines the required recovery verification.

The team must understand:

How production backups are created
How long backups are retained
How restoration works
Who can initiate recovery
What recovery limitations exist

Backup existence alone is insufficient if restoration has never been understood or validated.

Mobile Versioning

Android and iOS releases require platform-compatible application versioning and build identifiers.

Relvio may use product release versions in the form:

MAJOR.MINOR.PATCH

Example:

1.0.0
1.1.0
1.1.1

Semantic versioning may be used as a release communication convention.

However, mobile platform build numbers and store requirements must also be respected.

The implementation must maintain valid:

User-facing version
Platform build identifier

Do not assume backend deployment versions and mobile store versions must always move together.

API Versioning

The approved API base is:

/api/v1

API versioning is independent from mobile application semantic versioning.

A mobile release such as:

1.4.0

does not imply:

/api/v1.4

The API remains under its approved version boundary until an intentional API versioning decision is made.

API contracts are governed by:

13_API_Specification.md
Backward Compatibility

Mobile clients may remain installed after a newer backend version is deployed.

Backend releases must consider supported mobile client compatibility.

Do not assume every user immediately updates the Relvio application.

Changes to API contracts should be reviewed for:

Existing mobile clients
Required fields
Removed fields
Changed response structures
Changed validation behavior
Changed authentication behavior

Breaking active mobile clients must not occur accidentally.

Where an API change is intentionally incompatible, it requires an approved compatibility and release strategy.

Android Release

Android production releases must use the approved Android application identity and signing configuration.

Release credentials must be protected.

Do not commit signing secrets or private signing material to the repository.

Android release builds must use approved:

Application identifier
Version information
Signing configuration
Production API configuration
App icon assets
Required store metadata

The exact distribution workflow depends on the approved Android distribution platform.

iOS Release

iOS production releases must use the approved iOS application identity and signing configuration.

Certificates, signing credentials, and related private material must be protected.

iOS release builds must use approved:

Bundle identifier
Version information
Build identifier
Signing configuration
Production API configuration
App icon assets
Required store metadata

The exact distribution workflow depends on the approved iOS distribution platform.

Mobile Release Reality

Android and iOS releases are distributed applications.

A released mobile build cannot be treated like a backend process that can always be instantly replaced for every user.

Users may:

Receive store updates at different times
Delay application updates
Continue using an older supported version
Temporarily use a previously installed build

Deployment and API decisions must account for this reality.

Rollback Strategy

Rollback strategy depends on the deployment target.

There is no single universal rollback process for Relvio.

Backend Rollback

If a backend release causes a critical production issue, the team should determine the safest response.

Possible responses include:

Roll back to a previous compatible backend release
Disable the affected behavior where an approved control exists
Deploy a corrective release
Restrict a failing operation temporarily

The response depends on:

Database compatibility
Migration state
Data changes
Security impact
User impact

Do not automatically roll back backend code when the previous version is incompatible with an already-applied database migration.

Database Rollback

Database migrations must not assume automatic reversal is always safe.

A reverse migration may:

Lose data
Recreate invalid state
Break a newer backend
Violate integrity constraints

For production migration failures, choose a recovery approach based on the actual migration.

Possible approaches include:

Forward corrective migration
Controlled rollback migration
Data restoration
Backend compatibility adjustment

High-risk migration recovery should be understood before production deployment.

Mobile Release Recovery

A mobile release cannot be universally rolled back like a backend deployment.

If a released Android or iOS build contains a critical issue, possible responses may include:

Prepare and distribute a corrective build
Halt or pause further release rollout where the distribution platform supports it
Protect affected backend operations
Use an already approved remote control or feature mechanism if one exists

Do not invent a feature flag system solely because rollback is difficult.

Mobile recovery must account for app store review, rollout, and user update behavior.

Post-Deployment Verification

After a production deployment, verify behavior appropriate to the released change.

Critical verification may include:

Service availability
Authentication
Organization membership access
Organization isolation
Permission-sensitive operations
Critical API endpoints
Attendance behavior
Journey transitions
Mobile API connectivity
Database migration completion

Do not execute destructive production tests merely to satisfy a deployment checklist.

Use safe verification methods.

Monitoring and Observability

Production systems should provide enough visibility to detect and investigate important failures.

Relevant signals may include:

Backend errors
API latency
Failed authentication patterns
Database health
Application crashes
Failed critical operations
Migration failures

Monitoring scope should grow with actual product and operational needs.

This document does not approve a specific monitoring or crash-reporting vendor.

Do not add external monitoring SDKs without approval and security review.

Logging

Deployment and release records should preserve useful operational information.

Relevant release metadata may include:

Release version
Build identifier
Deployment date
Target environment
Source revision or commit
Deployment result

Backend logging must follow approved security rules.

Never log:

Passwords
Authentication tokens
Signing secrets
Database credentials
Sensitive data without an approved operational need

Security requirements are governed by:

16_Security.md
Release Notes

User-facing release notes should describe relevant changes clearly.

Release notes may include:

New approved features
Meaningful improvements
Important fixes

Internal release records may additionally include:

Technical changes
Migration requirements
Known issues
Operational notes
Compatibility concerns

Do not expose internal security details or sensitive infrastructure information in public release notes.

CI Principles

Continuous Integration should help verify changes before release.

Appropriate automated checks may include:

Dependency resolution
Code generation
Static analysis
Critical automated tests
Build verification

The exact CI pipeline must match the actual Relvio repository and approved technologies.

Do not add speculative CI steps for tools or platforms that Relvio does not use.

CD Principles

Deployment automation may be introduced for approved deployment targets.

Backend non-production deployment may be automated.

Backend production deployment should retain appropriate release control.

Mobile build and distribution automation may be introduced when it improves release reliability.

Do not assume fully automatic production deployment is required for Relvio v1.

A successful merge must not automatically imply an uncontrolled production release.

Production Release Approval

Production release approval should consider:

Change risk
Test results
Migration impact
Security impact
API compatibility
Mobile compatibility
Known issues

The approval process may remain lightweight for low-risk changes.

High-risk changes require explicit engineering attention.

Do not create unnecessary enterprise release bureaucracy for Relvio v1.

Secrets

Secrets must not be committed to source control.

Secrets must not be placed in:

Flutter source code
Flutter assets
Public configuration files
Documentation examples containing real credentials
Repository history

If a secret is exposed, removing it from the latest file is not sufficient.

The credential must be treated as compromised and rotated according to the affected service.

Dependency Review

Dependency updates should be reviewed according to risk.

Before important production releases, verify that:

Required dependencies resolve
Known critical issues affecting Relvio are understood
Major dependency changes have been tested
Unnecessary dependencies have not been introduced

Do not blindly update every dependency immediately before a production release.

Do not ignore known critical dependency risks.

Engineering standards are governed by:

14_Engineering_Standards.md
Deployment Failure Handling

When a production deployment fails:

Identify the affected deployment boundary.
Assess user, data, and security impact.
Stop further rollout where technically possible and appropriate.
Determine compatibility with the previous release.
Select the safest recovery action.
Verify the recovery.
Document significant incidents and required follow-up.

Do not use a universal:

Restore previous release

response without checking database and API compatibility.

AI Coding Assistant Rules

AI coding assistants must not:

Deploy Relvio independently without an explicit deployment task.
Invent a cloud provider.
Invent a CI/CD provider.
Invent a backend hosting platform.
Invent a database hosting platform.
Add Web, Windows, macOS, or Linux release pipelines.
Connect Flutter directly to PostgreSQL.
Place backend secrets in Flutter configuration.
Invent environment variable names and treat them as approved contracts.
Assume four hosted environments are mandatory.
Assume every merge deploys automatically to production.
Assume every deployment can be instantly rolled back.
Edit already-applied migrations silently.
Reuse production secrets in non-production.
Add monitoring SDKs without approval.
Add feature flags solely as speculative deployment infrastructure.
Introduce blue-green or canary infrastructure without an approved need.
Break /api/v1 contracts without an approved compatibility decision.

When deployment configuration is missing, an AI coding assistant must:

Identify the missing deployment decision.
Report the affected deployment target.
Avoid inventing infrastructure.
Continue only with unrelated implementation work where possible.
Deployment Review Checklist

Before a production release, review the items relevant to the change:

Does the intended target build successfully?
Do critical tests pass?
Are analyzer or configured static checks acceptable?
Is the correct environment configuration selected?
Are secrets protected?
Does the change affect /api/v1 compatibility?
Does the change affect organization isolation?
Does the change affect roles or permissions?
Does the change affect attendance integrity?
Does the change affect journey history?
Is a database migration required?
Has migration risk been reviewed?
Is recovery capability appropriate to the risk?
Are supported mobile clients compatible?
Is post-release verification defined?

Not every low-risk release requires every item to receive the same depth of review.

Review effort should match release risk.

Source of Truth Priority

For deployment and release decisions:

Approved Relvio architecture defines system boundaries.
13_API_Specification.md defines API contracts and /api/v1.
14_Engineering_Standards.md defines engineering implementation standards.
15_Testing_Strategy.md defines test priorities.
16_Security.md defines security requirements.
Deployment.md defines deployment and release governance.
Approved infrastructure configuration defines provider-specific deployment commands.

This document must not be used to invent missing infrastructure decisions.

If a genuine contradiction exists, deployment must stop at the affected decision and request clarification.

Deployment Success Criteria

Relvio deployment is successful when:

The intended deployment target is released correctly.
Android and iOS remain the supported Relvio v1 client platforms.
Flutter continues to communicate through the backend REST API.
Production secrets remain protected.
Organization isolation remains intact.
Critical attendance integrity remains intact.
Immutable journey history remains protected.
Database migrations preserve required data guarantees.
API compatibility is handled intentionally.
Production behavior is verified after release.
Recovery decisions account for the actual deployment boundary.
Deployment infrastructure grows from real Relvio needs rather than speculation.
AI coding assistants can support deployment without inventing architecture or infrastructure.