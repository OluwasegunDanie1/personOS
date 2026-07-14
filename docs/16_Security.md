---
Document: Security
Version: 0.2
Status: Approved
Project: Relvio
Owner: Engineering Team
---

# Security

## Purpose

This document defines the security requirements for Relvio.

Relvio stores and processes organization, user, people, attendance, communication, and operational data.

The goal is to:

- Protect customer data
- Prevent unauthorized access
- Preserve organization isolation
- Protect authentication sessions
- Prevent data corruption
- Reduce abuse
- Detect suspicious activity
- Support secure recovery
- Build trust with organizations using Relvio

Security is a system-wide responsibility.

It must be enforced by the backend and database.

The Flutter application is not a security boundary.

---

# Security Principles

Relvio follows these principles:

1. Never trust client-side input.
2. Deny access by default.
3. Grant only the permissions required.
4. Verify organization access on every organization-scoped operation.
5. Validate all external input.
6. Protect secrets and authentication material.
7. Use secure defaults.
8. Minimize collected data.
9. Record sensitive administrative actions.
10. Avoid exposing internal system information.
11. Keep dependencies and infrastructure maintained.
12. Design for detection and recovery.
13. Security controls must not be disabled for development convenience.

Security must be considered during design, implementation, testing, and release.

---

# Security Boundaries

Relvio contains several security boundaries:

```text
Flutter Application
        ↓
Backend API
        ↓
Application Authorization
        ↓
PostgreSQL Database
        ↓
Infrastructure and Storage


The Flutter application may improve usability by hiding unavailable actions.

However:

Hidden UI ≠ Authorization

All protected actions must be authorized by the backend.

The backend must never assume a request is safe because it came from the official Relvio mobile application.

Authentication

Relvio v1 supports:

Email and password registration
Email and password login
Email verification
Password reset
Session refresh
Logout
Session expiration

User status is a closed v1 value set: ACTIVE, DISABLED. Disabled users cannot authenticate. Disabled users cannot refresh authentication.

Login failures caused by an invalid email or an invalid password must return the same public authentication failure. The response must not reveal which factor was incorrect.

Future authentication methods may include:

Google Sign-In
Apple Sign-In
Microsoft Sign-In
Multi-Factor Authentication
Single Sign-On

Future authentication methods must not be implemented until approved.

Password Security

Passwords must never be stored in plain text.

Passwords must be hashed using a modern password hashing algorithm.

The approved v1 algorithm is Argon2id, implemented using the argon2 Node package, using the secure defaults of the approved Argon2 implementation.

Hash configuration must be centralized. Algorithm parameters must not be scattered through authentication code.

SHA-256 must never be used for password storage.

Password hashes must never be returned by the API.

Password hashes must never appear in:

Logs
Analytics
Audit metadata
Error responses
Flutter storage

Password requirements must balance security and usability.

The backend must enforce the approved password policy.

Frontend password validation is for user experience only.

Password Reset Security

Password reset requests must not reveal whether an account exists.

Example response:

If an account exists for this email, password reset instructions will be sent.

Reset tokens are opaque, cryptographically secure random values. Only a cryptographic hash of the reset token may be stored; the raw token must never be stored.

Reset tokens must:

Be cryptographically secure
Expire 1 hour after creation
Be single-use
Be invalidated after successful reset
Never be logged

Password reset operations should be rate limited.

A successful password reset should consider invalidating existing sessions according to the approved session policy.

Email Verification

Email verification tokens are opaque, cryptographically secure random values. Only a cryptographic hash of the verification token may be stored; the raw token must never be stored.

Email verification tokens must:

Be securely generated
Expire 24 hours after creation
Be single-use
Be validated by the backend

The backend must determine whether an email is verified.

The Flutter client must not be allowed to mark an account as verified.

Opaque Authentication Token Generation and Hashing

Refresh tokens, email verification tokens, and password reset tokens are generated using Node's built-in crypto.randomBytes(32), encoded as base64url. Do not use UUIDs or Math.random for authentication token generation.

The raw token value is hashed using SHA-256 (Node built-in crypto) before storage. The stored representation is lowercase hexadecimal. Only the hash is stored; the raw token is never stored.

SHA-256 token hashing is approved only for these high-entropy opaque authentication tokens. It must never be used for password storage.

Session Security

Authentication state must have a single authoritative backend source.

Access tokens are signed JWTs with a 15-minute lifetime. Access JWTs must never be persisted in PostgreSQL.

Access tokens use symmetric HS256 signing via the approved @nestjs/jwt integration. The signing secret is provided through the JWT_ACCESS_SECRET environment variable, which must never be committed to source control, must never be exposed to the Flutter application, and must have no hardcoded fallback value. Backend authentication configuration must fail clearly when JWT_ACCESS_SECRET is absent.

Access-token claims are limited to: sub (global User ID), iat, exp, iss (relvio-api), aud (relvio-mobile). The login access token must not contain organization ID, active organization, role, or permission claims. Organization context selection is a separate explicit membership/context workflow.

Refresh tokens are used for session renewal (see Refresh Token Security).

Authentication material must never be stored in insecure plain-text application storage.

The Flutter application must use approved secure device storage for sensitive authentication material.

Tokens must never be written to:

Application logs
Crash reports
Analytics events
Screenshots generated for debugging
Error messages

The application must support:

Session creation
Session refresh
Session expiration
Logout
Revoked sessions

When authentication can no longer be refreshed safely, the application must return the user to the approved authentication flow.

Refresh Token Security

Refresh tokens are opaque, cryptographically secure random values with a 30-day lifetime. Only a cryptographic hash of the refresh token may be stored in PostgreSQL. The raw refresh token must never be stored.

Refresh tokens must:

Be securely generated
Be stored only as a hash
Support revocation
Have a defined 30-day expiration
Be validated server-side

Refresh tokens rotate on every successful refresh.

Reuse of an already rotated or revoked refresh token is treated as suspicious and revokes the entire refresh-token family.

Logout revokes the active refresh-token session.

Refresh tokens must never be exposed through application logs.

Authenticated Request Boundary

A single global NestJS access-token guard protects all routes except an explicit set of public endpoints, marked using an explicit public-route decorator/metadata mechanism. The current public endpoints are POST /auth/login, POST /auth/refresh, and POST /auth/logout.

The global guard must:

Extract Authorization: Bearer <token>.
Verify the signed JWT using the already-approved JWT configuration.
Require a valid sub claim.
Resolve the User by sub.
Reject a missing User, a deleted User, and a DISABLED User.
Attach a minimal authenticated identity to the request: { userId: string }. It must never attach the full Prisma User record, passwordHash, or organization/role/permission context.

Organization switching must never require issuing a replacement access token. The access token remains global-identity-only for its entire lifetime; this guard boundary does not change the approved access-token claim set defined above.

Access-Token Error Codes

AUTHENTICATION_REQUIRED: missing Authorization header, a non-Bearer scheme, or an empty Bearer token.
INVALID_ACCESS_TOKEN: malformed token, invalid signature, invalid issuer/audience, expired token, missing/invalid sub, or a sub whose User no longer exists or is deleted.
USER_DISABLED: the resolved User's status is DISABLED.

All three use the standard error envelope. The underlying JWT library's error details must never be exposed to the client.

Development Authentication Fixture Security

A development/test-support mechanism is approved for creating exactly one controlled local User for live local authentication lifecycle verification. Its scope and non-goals (not registration, not a seed framework, not production provisioning) are governed by Deployment.md.

The fixture must reuse the existing PasswordHashService/approved Argon2id primitive without duplicating or reimplementing password-hashing configuration.

The fixture must never log: the raw AUTH_FIXTURE_PASSWORD value, the resulting password hash, or the AUTH_FIXTURE_EMAIL value. No default or hardcoded fixture credentials are approved.

The fixture must refuse to run when NODE_ENV=production. It exists purely as local development/test tooling: it must never be exposed through a public API endpoint and must never be invoked automatically.

This fixture does not weaken any password-security requirement defined elsewhere in this document; the same Argon2id hashing and secret-handling rules apply to the credential it processes.

Development Organization Fixture Security

A second, separate development/test-support mechanism extends the controlled auth-fixture concept to enable live local verification of organization listing and membership enforcement. It may create exactly one Organization, one Role (named Owner) owned by that Organization, and one OrganizationMembership linking the existing controlled fixture User to that Role and Organization. It must create zero Permission, RolePermission, or any product-domain or auth-token record.

This fixture reuses AUTH_FIXTURE_EMAIL only to locate the already-existing controlled User; it must not read or require AUTH_FIXTURE_PASSWORD. It reads the required, non-default AUTH_FIXTURE_ORGANIZATION_NAME environment variable (trimmed, must be non-empty).

The fixture is idempotent; existing matching records must not be mutated (no upsert-that-updates). It must refuse to run when NODE_ENV=production, is invoked manually only, and must never auto-run during application bootstrap, npm install, Prisma generate, Prisma migrate, tests, or build.

This fixture is not product onboarding. It does not implement an organization-creation API and does not replace a future registration/onboarding contract.

Development Person Fixture Security

A third, separate development/test-support mechanism extends the same controlled-fixture concept to enable live local verification of the People list/detail endpoints. It may create exactly one Person inside the existing controlled fixture Organization, with email, phone, and avatarUrl null, status ACTIVE, and deletedAt null. It must create zero Tag, PersonTag, JourneyTemplate, JourneyStage, PersonJourneyHistory, Attendance, FollowUp, Note, Report, Notification, AuditLog, or auth-token record.

This fixture reuses AUTH_FIXTURE_EMAIL and AUTH_FIXTURE_ORGANIZATION_NAME only to locate the existing controlled User, membership, and Organization; it reads the required, non-default PERSON_FIXTURE_FIRST_NAME and PERSON_FIXTURE_LAST_NAME environment variables (trimmed, non-empty).

The fixture is idempotent on (controlled fixture Organization, normalized firstName, normalized lastName, null email, null phone); existing matching non-deleted records must not be mutated (no upsert-that-updates). A matching but soft-deleted Person, or multiple exact matches, fail clearly rather than being repaired or guessed. It must refuse to run when NODE_ENV=production, is invoked manually only, and must never auto-run during application bootstrap, npm install, Prisma generate, Prisma migrate, tests, or build. This fixture is not product onboarding and does not replace POST /people.

Person Tenant Isolation

For any personId route, service-level Person access must scope by both id = personId and organizationId = the validated organization context; a personId-only lookup is prohibited. Cross-tenant Person access and an absent or soft-deleted Person return the identical stable error, PERSON_NOT_FOUND, without disclosing whether a Person exists in another tenant's organization.

Development Journey Fixture Security

A fourth, separate development/test-support mechanism extends the same controlled-fixture concept to enable live local verification of the Journey Stage and Person Journey endpoints. It may create exactly one JourneyTemplate (description null) for the existing controlled fixture Organization and exactly two JourneyStages attached to it (positions 1 and 2). It must create zero PersonJourneyHistory and zero other records.

This fixture reuses AUTH_FIXTURE_EMAIL and AUTH_FIXTURE_ORGANIZATION_NAME only to locate the existing controlled User, membership, and Organization; it reads the required, non-default JOURNEY_FIXTURE_TEMPLATE_NAME, JOURNEY_FIXTURE_STAGE_ONE_NAME, and JOURNEY_FIXTURE_STAGE_TWO_NAME environment variables (trimmed, non-empty). It never reads AUTH_FIXTURE_PASSWORD.

The fixture is idempotent on an exact matching operational template plus exactly two matching stages at the expected positions; existing matching records must not be mutated (no upsert-that-updates). Any partial match (wrong stage count, wrong positions, or multiple candidate templates) fails clearly rather than being repaired or guessed. It must refuse to run when NODE_ENV=production, is invoked manually only, and must never auto-run during application bootstrap, npm install, Prisma generate, Prisma migrate, tests, or build. It is test/development support only and does not implement user-facing Journey Template management.

Journey Tenant Isolation

JourneyTemplate is scoped directly by organizationId = the validated organization context. JourneyStage ownership is indirect: a stageId is valid only when its journeyTemplateId resolves to a JourneyTemplate whose organizationId matches the validated organization context, and that template must be the Organization's single operational template; an absent or cross-tenant stage returns JOURNEY_STAGE_NOT_FOUND without disclosing foreign existence. PersonJourneyHistory ownership is doubly indirect (through personId and through fromStageId/toStageId); it must never be fetched by personId alone for organization-scoped API use — Person tenant ownership (id + organizationId + deletedAt null) must be validated first. For journey movement, Person tenant ownership and target Stage tenant ownership are each validated independently before any PersonJourneyHistory row is appended. Reorder validation (INVALID_STAGE_ORDER) never discloses whether a supplied foreign stage id exists.

Journey history remains immutable: movedBy exposes only id, firstName, lastName (never email, phone, status, passwordHash, or deletedAt), and historical attribution remains visible unchanged even if that User later becomes DISABLED or is soft-deleted.

Development Event Fixture Security

A fifth, separate development/test-support mechanism extends the same controlled-fixture concept to enable live local verification of the Event and Attendance endpoints. It may create exactly one Event inside the existing controlled fixture Organization, with description, category, venue, and endDate null, and createdBy set to the existing controlled fixture User. It must create zero Attendance, EventCategory-shaped, EventTemplate-shaped, or any other product-domain record.

This fixture reuses AUTH_FIXTURE_EMAIL and AUTH_FIXTURE_ORGANIZATION_NAME only to locate the existing controlled User, membership, and Organization; it reads the required, non-default EVENT_FIXTURE_TITLE and EVENT_FIXTURE_START_DATE environment variables (trimmed/parsed, non-empty). It never reads AUTH_FIXTURE_PASSWORD.

The fixture is idempotent on (controlled fixture Organization, normalized title, exact startDate); an existing exact, non-deleted match must not be mutated (no upsert-that-updates). A matching but soft-deleted Event, or multiple exact matches, fail clearly rather than being repaired or guessed. It must refuse to run when NODE_ENV=production, is invoked manually only, and must never auto-run during application bootstrap, npm install, Prisma generate, Prisma migrate, tests, or build. It is test/development support only and does not implement or replace POST /organizations/{organizationId}/events or the Record Attendance endpoint.

This fixture must never expand to a second Organization or a second controlled User. Live verification of cross-tenant Event/Attendance isolation is out of scope for this fixture and must remain a mocked/unit-level test concern (see 15_Testing_Strategy.md); the controlled fixture mechanism approved across all five fixtures exists for single-tenant, happy-path live verification only.

Like every prior fixture, this mechanism's CLI runner output must be neutral: it may report only a success/already-exists result, never the AUTH_FIXTURE_EMAIL value, never any Event field value, and never any other secret or personal data.

Event Tenant Isolation

For any eventId route, service-level Event access must scope by id = eventId, organizationId = the validated organization context, and deletedAt IS NULL; an eventId-only lookup is prohibited. Cross-tenant Event access and an absent or soft-deleted Event return the identical stable error, EVENT_NOT_FOUND, without disclosing whether an Event exists in another tenant's organization.

Attendance Tenant Isolation

Attendance is scoped directly by organizationId, since the schema gives Attendance its own organizationId column; this direct column must always be included in Attendance queries in addition to any Event or Person relation. Before any Attendance row is read or written, Event tenant ownership (id + organizationId + deletedAt null) and Person tenant ownership (id + organizationId + deletedAt null) must each be validated independently — an Attendance row must never be reached only through an eventId or personId path parameter without first confirming both parents belong to the validated organization context. A cross-tenant or absent Event returns EVENT_NOT_FOUND; a cross-tenant or absent Person returns PERSON_NOT_FOUND; neither discloses foreign existence.

Follow-Up Tenant Isolation

For any followUpId route, service-level FollowUp access must scope by id = followUpId and organizationId = the validated organization context; a followUpId-only lookup is prohibited. FollowUp has no deletedAt column, so this scoping is exactly (id, organizationId). Cross-tenant FollowUp access and an absent FollowUp return the identical stable error, FOLLOW_UP_NOT_FOUND, without disclosing whether a FollowUp exists in another tenant's organization. The personId relation must independently satisfy Person Tenant Isolation above (id + organizationId + deletedAt null), returning PERSON_NOT_FOUND otherwise.

Follow-Up Assignment Tenant Rule

assignedTo references a global User directly, exactly like Event.createdBy and Attendance.checkedInBy. Global User existence is never sufficient authorization: an assignedTo value must resolve to a User holding an active OrganizationMembership for the validated organization context (the same organizationId_userId membership lookup used by OrganizationMembershipGuard), else ASSIGNED_USER_NOT_FOUND. A User who is a member of a different organization, or of no organization, must be rejected identically to a nonexistent User, without disclosing which case applies.

Dashboard Summary Tenant Isolation

Dashboard Summary is a read-only aggregate over People, FollowUp, and Event, each already organization-owned. Every one of its source queries (the People count, the FollowUp count, and the Event query) must explicitly filter by the validated organizationId; none may run unscoped. An aggregate query that omits organizationId is a cross-tenant data leakage defect under the existing Cross-Organization Data Leakage severity classification above, identical in severity to leaking a single record. No Dashboard-specific role or permission restriction is approved beyond active organization membership; do not invent one.

Authorization

Relvio uses role and permission-based authorization.

Approved Relvio roles include:

Owner
Administrator
Manager
Team Lead
Volunteer
Member

Roles contain permissions.

Example permissions:

people.view
people.create
people.update
people.delete

events.view
events.create
events.update
events.delete

attendance.view
attendance.record

communication.view
communication.send

reports.view
reports.export

organization.update
roles.manage
billing.manage
settings.manage

Every protected backend action must define its required permission.

Authorization must be enforced by the backend.

The Flutter application may hide actions the user cannot perform, but hidden actions must still be rejected by the backend when called directly.

Permission failures must return:

403 Forbidden
Default Deny

Relvio follows a default-deny authorization model.

If a permission requirement cannot be determined safely, access must be denied.

Do not assume permission because:

The user is authenticated
The user knows a resource ID
The Flutter UI displayed a screen
The user previously had permission
The request contains an organization ID

Authorization must be evaluated using current backend state.

Multi-Organization Security

Relvio is a multi-organization platform.

Organization isolation is a critical security boundary.

A user may belong to:

One organization
Multiple organizations
Different roles in different organizations

Role and permission context must be evaluated per organization.

Membership is represented by an Organization Membership record linking a User, an Organization, and a Role. A user has at most one Organization Membership per organization. A membership's role must belong to the same organization as the membership.

Login does not automatically select an active Organization context. Organization context selection is a separate explicit membership/context workflow.

Example:

User A

Organization One
Role: Administrator

Organization Two
Role: Volunteer

Administrator permissions in Organization One must not apply to Organization Two.

Organization-Scoped Requests

For every organization-scoped request, the backend must:

Authenticate the user.
Resolve the requested organization.
Verify active organization membership.
Resolve the user's role in that organization.
Resolve current permissions.
Verify the required permission.
Scope the database operation to the organization.

Example:

GET /organizations/{organizationId}/people/{personId}

The backend must not query only by:

personId

The operation must verify that the person belongs to the requested organization.

Conceptually:

person.id = personId
AND
person.organization_id = organizationId

Knowing a resource identifier does not grant access to the resource.

Organization Creation Authority

POST /organizations requires only the global access-token guard. OrganizationMembershipGuard must never be applied to this route, since the target Organization does not exist until the request succeeds. The creator identity is always request.auth.userId; the request body never accepts a userId, ownerId, or role field.

Organization creation is one atomic transaction: exactly one Organization row, exactly one Role row named "Owner" scoped to that new Organization, and exactly one OrganizationMembership row linking the creator, the new Organization, and that new Role. This is not a global/dynamic role catalogue: Role remains organization-owned (per the approved Database Design), so "Owner" is freshly created per Organization, never looked up from a shared or global row, and the client never supplies or influences the role name. This extends, into the real creation path, the exact "Owner" naming convention already established by the approved Organization Fixture (see Development Organization Fixture Security below), which explicitly anticipated this: "This fixture is not product onboarding. It does not implement an organization-creation API and does not replace a future registration/onboarding contract." Zero Permission or RolePermission rows are created; permission enforcement remains deferred, consistent with every other implemented domain. If any part of the transaction fails, no Organization, Role, or OrganizationMembership row persists.

No Invitation model or workflow is introduced by Organization creation. The creator's membership is established directly and immediately; no second membership-creation endpoint and no invitation-acceptance step exists or is required for the creator.

Organization Context Mechanism

Relvio v1 does not maintain server-side active-organization session state, does not use an organization header, and does not issue organization-scoped JWTs. After login, the Flutter application calls GET /organizations, selects an organization locally, and supplies that organization ID through the approved {organizationId} path parameter on organization-scoped requests. Organization selection/switching is a Flutter application-context action, not a backend select/switch endpoint; there is no POST /organizations/select or POST /organizations/switch endpoint. Immediately after a successful Create Organization, the same mechanism applies unchanged: the client calls GET /organizations and finds the new Organization already present with role name "Owner."

Organization Detail and Update Tenant Isolation

GET /organizations/{organizationId} and PATCH /organizations/{organizationId} both require OrganizationMembershipGuard and are scoped by id = organizationId; Organization has no deletedAt column. An absent or non-member Organization returns ORGANIZATION_ACCESS_DENIED — the same code the membership guard already produces — without disclosing whether the Organization exists for other tenants. No role-specific (Owner-only or Administrator-only) restriction is approved for Update Organization in v1; this is an explicit, temporary, membership-only boundary pending a future approved permission-enforcement slice, and must not be tightened or invented ad hoc during implementation.

Organization-Membership Enforcement Boundary

A reusable organization-membership guard/boundary protects every route containing {organizationId}. The membership proof tuple is exactly (authenticated userId, path organizationId) — nothing else proves organization access.

This boundary must:

Require authenticated request identity (it consumes request.auth.userId; it must not independently re-verify the JWT).
Read organizationId from the route path parameter and validate it as a UUID-compatible identifier.
Query OrganizationMembership using the unique organizationId + userId boundary.
Reject missing membership by default.
Resolve the membership's Role, relying on the existing database composite foreign key for same-organization membership-to-role structural integrity.
Attach minimal organization request context: { organizationId: string, membershipId: string, roleId: string }. It must never attach full Prisma models or permission codes.

Guard order for organization-scoped routes: the global access-token guard runs first; organization-membership enforcement runs second; controller/service business logic runs only after both succeed.

The stable error code for this boundary is ORGANIZATION_ACCESS_DENIED, used for a malformed organizationId, a non-existent organization, a missing membership for the authenticated user, or a membership that cannot resolve its role consistently. This code must never reveal whether another tenant's organization exists.

Path organizationId is a requested tenant context, not proof of access — client-supplied organizationId is never trusted merely because it is present. Membership validation is mandatory before any organization-scoped business logic executes. Organization-scoped Prisma queries must include the validated organizationId where the model directly owns organizationId; indirect tenant-owned models must be reached through validated organization-owned relations rather than a bare foreign-key lookup.

Denied cross-tenant attempts should be auditable once the audit infrastructure for security events is implemented. This document does not define that audit event schema now.

Permission authorization is deferred until a product endpoint requires a specific permission; this boundary does not perform permission checks and no permission-enforcement guard exists yet.

PostgreSQL Organization Isolation

Organization-owned tables must follow the approved Database Design.

Database queries must preserve organization scope.

Developers must avoid unsafe patterns such as:

SELECT person WHERE id = personId

when organization context is required.

Preferred conceptual pattern:

SELECT person
WHERE id = personId
AND organization_id = organizationId

Repository and data-access patterns should make organization scoping difficult to forget.

Parameterized queries or approved ORM/query-builder mechanisms must be used.

Never construct SQL by directly concatenating untrusted input.

Cross-Organization Data Leakage

Cross-organization data leakage is a Critical P0 security defect.

Examples include:

Viewing another organization's person
Searching another organization's people
Exporting another organization's report
Viewing another organization's attendance
Accessing another organization's messages
Receiving another organization's activity
Reusing stale organization data after switching workspaces

No release may proceed with a known cross-organization data exposure defect.

Organization Switching

When the active organization changes, the Flutter application must:

Invalidate organization-scoped providers
Clear or separate organization-scoped caches
Cancel inappropriate pending requests where possible
Reload organization-specific permissions
Reload organization-specific data
Avoid displaying stale data from the previous organization

Pending offline attendance requires special handling according to the approved offline synchronization design.

The application must never silently sync Organization A data into Organization B.

Input Validation

All external input must be validated by the backend.

Validation may include:

Required fields
Data types
Length limits
Allowed values
Date ranges
Identifier formats
File types
File sizes
Pagination limits
Sorting fields
Filter fields

The backend must use allowlists where practical.

Example:

If supported attendance statuses are:

PRESENT
ABSENT
LATE

the backend must reject unsupported values. These are the public API values; the internal Prisma persistence enum (Present, Absent, Late) is never exposed to clients (see 13_API_Specification.md for the explicit mapping).

Frontend validation improves usability.

Backend validation protects the system.

DTO Validation

Request DTO validation uses class-validator and class-transformer.

A single global NestJS ValidationPipe must be registered with:

whitelist: true
forbidNonWhitelisted: true
transform: true

Validation failures surface as standard NestJS HttpException responses. The backend's global exception filter normalizes these into the approved public API error envelope without requiring structural changes.

API Security

Every protected API endpoint must:

Require authentication
Validate the active session
Validate request data
Verify organization membership where applicable
Verify required permissions
Scope data access correctly
Return approved HTTP status codes
Return approved machine-readable error codes

The API must not expose:

Stack traces
Raw SQL errors
Internal file paths
Secret values
Infrastructure details
Framework debug pages

Production debug mode must be disabled.

API Error Security

Public API errors should contain safe information.

Example:

{
  "success": false,
  "error": {
    "code": "PERMISSION_DENIED",
    "message": "You do not have permission to perform this action.",
    "details": {}
  }
}

Internal errors may be logged securely for investigation.

Internal exception messages must not automatically be returned to clients.

Rate Limiting

Sensitive or abuse-prone endpoints must be rate limited.

Examples:

Login
Registration
Forgot password
Password reset
Invitation acceptance
Global search
Message sending
Announcement sending
Campaign sending
Report export

Rate-limit responses should return:

429 Too Many Requests

Rate limits should consider the endpoint and threat model.

Possible rate-limit dimensions include:

IP address
User account
Organization
Session

Do not rely on IP-based rate limiting alone for authenticated abuse prevention.

Approved v1 Authentication Rate-Limit Configuration

The approved NestJS rate-limit package is @nestjs/throttler.

Approved v1 thresholds for the public authentication boundary:

POST /auth/login: maximum 5 requests per 60 seconds per client IP
POST /auth/refresh: maximum 10 requests per 60 seconds per client IP
POST /auth/logout: maximum 20 requests per 60 seconds per client IP
POST /auth/register: maximum 5 requests per 15 minutes per client IP (Product Task 072)
POST /auth/forgot-password: maximum 5 requests per 15 minutes per client IP (Product Task 072)

For this boundary, client IP is the sole approved throttling key, resolved through standard NestJS/Express request IP handling. Do not manually parse X-Forwarded-For inside auth controllers. Do not combine the IP key with email, user ID, refresh-token hash, or device fingerprinting for this boundary.

Rate-limit rejection returns 429 Too Many Requests.

These thresholds and the package/keying decision apply specifically to the login/refresh/logout/register/forgot-password boundary. A generic requirement to rate limit elsewhere in this document does not by itself authorize thresholds, package selection, or keying strategy for other endpoints. POST /auth/reset-password and GET /auth/me have no endpoint-specific threshold approved beyond the module's default throttler bucket; a distinct threshold for either was not requested and is not invented here.

Trust-Proxy Boundary

Correct client-IP resolution depends on the deployment network boundary.

Local development: the backend receives direct local connections. Express trust proxy remains disabled. Request IP is derived from the direct socket/client connection.

Non-production and production: the deployed API may run behind a reverse proxy or platform ingress. The approved backend environment variable TRUST_PROXY controls Express trust proxy configuration in these environments. TRUST_PROXY is required before public authentication exposure in non-production or production. It has no hardcoded fallback and must fail clearly if required and absent or empty. Its value is the explicitly configured trusted proxy hop count, expressed as a positive integer, and is used to configure Express trust proxy from that validated hop count. Do not configure trust proxy using a boolean true value. Do not trust arbitrary proxy addresses. Do not manually parse X-Forwarded-For.

NODE_ENV distinguishes development, test, and production for this authority. No additional environment-naming variable is introduced. A separately deployed non-production environment that publicly exposes authentication endpoints must configure TRUST_PROXY under the same rule before that exposure.

Brute-Force Protection

Authentication endpoints must be protected against repeated credential attempts.

Controls may include:

Rate limiting
Progressive delays
Temporary protection mechanisms
Suspicious login monitoring

Persistent account lockout is not part of Relvio v1. Do not add failed-attempt counters or locked-until fields.

Rate limiting and brute-force protection remain required. Exact thresholds, package, keying strategy, and trust-proxy configuration for the login/refresh/logout/register/forgot-password boundary are resolved above (Product Task 072 resolved the register and forgot-password thresholds; they are no longer unresolved).

Security controls must avoid exposing whether a specific email account exists.

Authentication CORS Boundary

Native Flutter Android and iOS clients are not governed by browser CORS enforcement. Relvio v1 does not approve Flutter Web or other browser-client exposure. No CORS policy is introduced for the current native-mobile authentication API boundary. Browser exposure requires a future, separately approved CORS authority decision.

Idempotency Security

Sensitive write operations identified by the API Specification must support idempotency.

Examples:

Attendance recording
Invitation acceptance
Announcement sending
Campaign sending
Report export requests

Idempotency keys must be scoped appropriately.

A key used by one organization or operation must not incorrectly return data from another organization or operation.

Idempotency storage must not expose another user's response.

Record Attendance does not use a client-supplied Idempotency-Key header. Its natural key — the database-level unique constraint on (organizationId, eventId, personId) — is sufficient and approved for this endpoint; see Attendance Integrity below and 13_API_Specification.md.

Attendance Integrity

Attendance is a critical Relvio data workflow.

The backend must protect against:

Duplicate attendance
Replayed check-ins
Cross-organization check-ins
Invalid event references
Invalid person references
Unauthorized attendance recording

Attendance integrity must use:

Authentication
Authorization
Organization validation
Request validation
Idempotency
Database constraints

Client-side duplicate prevention is not sufficient.

Approved v1 idempotency mechanism: on Record Attendance, the backend attempts to create the Attendance row directly. If the database unique-constraint on (organizationId, eventId, personId) rejects the write because a matching row already exists — including under a concurrent race between two simultaneous first-creation requests — the backend must catch that constraint violation, re-fetch the existing row, and return it with HTTP 200. It must never surface the raw database constraint error to the client, and it must never update the existing row's status to match a differing replay request.

Offline Attendance Security

Offline attendance records must preserve:

Organization ID
Event ID
Person identity
Timestamp
Check-in method
Idempotency key
Synchronization state

Offline records must not contain unnecessary sensitive data.

When synchronizing, the backend must revalidate:

Authentication
Organization membership
Permission
Event validity
Person ownership
Attendance uniqueness

An offline operation is not trusted merely because it was created earlier by the official Flutter application.

File Upload Security

Uploaded files are untrusted input.

The backend must validate:

File size
Allowed file type
Actual file content where practical
Upload authorization
Organization ownership

File extensions alone must not be trusted.

Example:

profile.jpg

does not prove that the file is a valid JPEG image.

Allowed upload types must be defined per feature.

Examples may include:

JPEG
PNG
PDF

Do not create one universal upload allowlist for every feature.

Executable file types must be rejected unless a future approved feature explicitly requires them.

File Naming and Storage

User-provided file names must not be trusted as storage paths.

Uploaded files should use server-generated identifiers.

Example:

generated-file-id.jpg

rather than directly trusting:

../../profile.jpg

Storage access must respect organization and user permissions.

Private files must not accidentally become publicly accessible.

Temporary upload links or signed access mechanisms should expire where used.

File Metadata

The application should avoid trusting user-controlled file metadata.

Where relevant, file processing should consider:

Content type
File size
Image dimensions
Malformed files

Sensitive metadata should be removed where required by product or privacy policy.

Data Protection

Relvio must protect data in transit and at rest.

Data in transit must use HTTPS/TLS.

Production HTTP traffic must not be accepted for authenticated API operations.

Data at rest should use encryption provided by approved infrastructure and storage systems.

Not all data requires custom application-level encryption.

Application-level encryption should only be introduced when justified by the data classification and threat model.

Passwords Are Hashed, Not Encrypted

Passwords must be hashed.

Passwords must not be reversibly encrypted.

This distinction is mandatory.

Approved password handling uses a password hashing algorithm such as:

Argon2id
bcrypt
Secrets

Secrets include:

Database credentials
Signing secrets
Private API keys
Service credentials
Encryption keys
Provider secrets

Secrets must not be:

Hardcoded in source code
Committed to Git
Included in Flutter assets
Embedded in the mobile application
Written to documentation examples as real values
Logged

Secrets must use approved environment or secret-management systems.

The Flutter mobile application must be treated as a public client.

A secret embedded in the Flutter application must be considered recoverable by an attacker.

Public Configuration

Not every configuration value is a secret.

Examples may include:

Public API base URL
Application environment name
Public service identifiers designed for client use

Public configuration should still be managed consistently.

Do not incorrectly treat public configuration as a secure secret.

Do not expose private server credentials simply because another client configuration value is public.

Personally Identifiable Information

Relvio may process personal information about people managed by organizations.

Access to personal data must follow permissions and organization boundaries.

Developers should minimize unnecessary exposure of personal data.

Avoid including full personal records in:

Logs
Analytics
Crash reports
Debug screenshots
Error metadata

Only collect fields required by approved product functionality.

Logging Security

Logs must never contain:

Passwords
Password hashes
Access tokens
Refresh tokens
Password reset tokens
Invitation secrets
Authorization headers
Database credentials
Private API keys

Sensitive personal data should not be logged unnecessarily.

Use structured logging.

Where request logging is enabled, sensitive headers and fields must be redacted.

Audit Logging

Audit logs are different from technical application logs.

Sensitive administrative actions should create audit records where required.

Examples:

Organization settings changed
Member removed
Role changed
Permissions changed
Invitation created or revoked
Sensitive record deleted
Report exported
Security-related account action

Audit records may contain:

actor
action
organization
resource_type
resource_id
timestamp
metadata

Audit metadata must not contain secrets.

Audit logs must be protected from ordinary user modification.

Authorized audit-log access must remain organization scoped.

Audit Log Integrity

Audit logs should be append-oriented.

Ordinary application users must not be able to edit audit history.

Deletion or retention of audit logs must follow an approved retention policy.

If audit log removal is required for legal or operational reasons, it must be handled through an approved administrative process.

Database Security

Production database access must be restricted.

The PostgreSQL database must not be publicly exposed unnecessarily.

Database credentials must use approved secret management.

Application database permissions should follow least privilege.

Where practical, separate responsibilities should use appropriately scoped database access.

Database backups must be protected.

Developers must not use production database credentials for local development.

SQL Injection Prevention

All database operations must use:

Parameterized queries
Prepared statements
Approved ORM or query-builder parameter binding

Never concatenate untrusted input directly into SQL.

Unsafe conceptual example:

"SELECT * FROM people WHERE name = '" + userInput + "'"

Sorting and filtering fields must use approved allowlists.

Parameterized values do not automatically make dynamic table names or column names safe.

Database Constraints

Security and data integrity must not depend entirely on application code.

Use approved database constraints where required.

Examples:

Foreign keys
Unique constraints
Non-null constraints
Valid relationships

Attendance duplicate prevention must include a database-level integrity control according to the approved Database Design.

Backup Security

Database backups must be:

Automated
Protected from unauthorized access
Encrypted where supported and required
Retained according to the approved backup policy
Periodically tested for restoration

A backup is not considered reliable merely because it exists.

Recovery procedures must be tested.

Backup credentials must be protected.

Data Recovery

Relvio must maintain a documented recovery process.

Recovery planning should consider:

Database failure
Accidental deletion
Corrupted deployment
Infrastructure failure
Security incident

Recovery tests should verify that protected data remains correctly organization scoped after restoration.

Dependency Security

Dependencies must be reviewed before adoption.

Consider:

Maintenance activity
Known vulnerabilities
Release history
Flutter or backend compatibility
Package ownership
Necessity

Unused dependencies should be removed.

Security advisories should be monitored.

Critical vulnerable dependencies must be assessed promptly.

Do not perform blind dependency upgrades without testing.

Mobile Application Security

The Relvio Flutter application must be treated as an untrusted client.

Do not embed server secrets in the application.

Sensitive authentication material must use approved secure storage.

The application must not rely on code obfuscation as a primary security control.

Obfuscation may increase reverse-engineering difficulty, but it does not make embedded secrets safe.

Debug-only functionality must not expose production secrets or bypass production authorization.

Local Storage

Store only data required for approved application behaviour.

Sensitive values must use secure storage where appropriate.

Organization-scoped cached data must be separated or invalidated correctly.

Do not permanently cache unnecessary personal data.

Offline attendance storage must follow the approved offline synchronization design.

Local storage should be cleared appropriately during logout where required by the approved session and caching strategy.

Analytics Security

Analytics must not receive:

Passwords
Authentication tokens
Reset tokens
Invitation secrets
Full personal records
Sensitive message contents

Analytics events should describe product behaviour without unnecessarily exposing personal information.

Example:

Preferred:

attendance_check_in_completed

Avoid:

john_doe_checked_into_sunday_service_with_phone_080...
Crash Reporting Security

Crash reporting tools must not intentionally receive secrets or unnecessary personal data.

Before attaching custom context to crash reports, verify that it does not contain:

Tokens
Passwords
Private message contents
Full personal profiles
Sensitive request payloads

Use technical identifiers only when necessary and approved.

Monitoring

Security monitoring should consider:

Repeated failed login attempts
Suspicious session behaviour
High authorization failure rates
Unusual API request volume
Repeated rate-limit violations
Unexpected report export activity
High-volume communication sending
Unusual administrative changes
Application error spikes

Monitoring should prioritize meaningful signals.

Do not collect excessive sensitive data merely for monitoring.

Security Alerts

Critical security signals should generate alerts where infrastructure supports them.

Examples:

Significant authentication abuse
Unexpected cross-organization access detection
Database availability failure
Large error-rate spike
Critical dependency vulnerability
Suspicious administrative activity

Alerting rules must be reviewed to reduce ignored alert noise.

Privacy

Relvio should collect only data required for approved product functionality.

Organizations and users should be informed through approved privacy documentation about:

What data is collected
Why it is collected
How it is used
How long it may be retained
Applicable user or organization rights

Privacy requirements may vary by jurisdiction.

Legal and compliance requirements must be reviewed before entering regulated markets or making compliance claims.

Data Retention

Data must not be retained indefinitely merely because storage is available.

Retention requirements should be defined for:

User accounts
Organization data
Deleted records
Audit logs
Application logs
Backups
Notifications
Communication data
Export files

Retention policy must align with product, legal, privacy, and operational requirements.

Relvio v1 must not claim a specific compliance certification unless formally achieved.

Account and Organization Deletion

Deletion must follow the approved Database Design and retention strategy.

The system must distinguish between:

Soft deletion
Scheduled deletion
Permanent deletion
Legally or operationally retained records

Organization deletion is a sensitive action.

It must require strong authorization.

Owner-level destructive actions may require additional confirmation.

The Flutter application must not directly determine which database records to delete.

Deletion business logic belongs on the backend.

Secure Development

Developers and AI coding assistants must:

Follow approved architecture
Avoid hardcoded secrets
Validate external input
Use parameterized database access
Follow authorization requirements
Preserve organization isolation
Review dependency changes
Avoid exposing internal errors
Write tests for critical security rules

Security findings must not be hidden with frontend workarounds.

If a backend security requirement is missing, the API or architecture documentation must be corrected.

Environment Separation

Relvio should maintain separated environments.

Recommended:

Development
Testing / CI
Staging
Production

Production secrets must not be reused casually in development.

Development and automated tests must not depend on production data.

Environment configuration must be explicit.

Production debug settings must be disabled.

Security Testing

Security testing requirements are defined further in the Testing Strategy.

At minimum, verify:

Authentication enforcement
Session expiration
Session revocation
Organization isolation
Role permissions
Backend validation
SQL injection resistance
Upload validation
Attendance duplicate prevention
Idempotency scoping
Secure error responses
Sensitive log redaction

Every organization-owned resource must be tested against cross-organization access.

Incident Response

When a suspected security incident occurs:

Identify the issue.
Preserve relevant evidence.
Assess severity and scope.
Contain the impact.
Revoke affected credentials or sessions where required.
Fix the vulnerability.
Verify the fix.
Restore affected systems safely.
Notify affected parties where legally or operationally required.
Document the incident.
Review the root cause.
Improve controls and testing.

Security incidents must not be treated only as ordinary application bugs.

Security Incident Severity
Critical

Examples:

Cross-organization data exposure
Authentication bypass
Permission bypass
Production secret exposure
Large-scale sensitive data exposure
Active database compromise

Immediate response is required.

High

Examples:

Session revocation failure
Sensitive upload exposure
Significant brute-force weakness
Audit access bypass
Serious data integrity vulnerability

Urgent investigation is required.

Medium

Examples:

Missing rate limit on a non-critical endpoint
Excessive technical information in an error
Weak security monitoring coverage

Must be prioritized according to impact.

Low

Examples:

Minor hardening opportunity
Non-sensitive information exposure with limited impact

Track and resolve appropriately.

Vulnerability Handling

Security vulnerabilities must be documented and prioritized.

Do not publish sensitive exploitation details unnecessarily before remediation.

A vulnerability fix should include:

Root cause analysis
Code or infrastructure fix
Security verification
Regression testing
Documentation updates where required

Critical security fixes may use the approved hotfix workflow.

Future Security Enhancements

Potential future improvements include:

Multi-Factor Authentication
Single Sign-On
Enterprise identity providers
Device management
IP restrictions
Security dashboard
Advanced anomaly detection
Organization security policies
Session risk scoring
Formal compliance programs

These are future capabilities.

They must not be represented as available in Relvio v1 unless implemented and approved.

Compliance Claims

Relvio must not claim certifications or compliance status that has not been formally achieved.

Examples include:

SOC 2
ISO 27001
HIPAA
PCI DSS

Using secure engineering practices does not automatically make Relvio certified.

Compliance requirements must be evaluated separately when required by customers or markets.

Security Release Gate

A release must be blocked for known Critical security defects.

Before production release, verify:

Authentication works correctly
Session handling works correctly
Organization isolation tests pass
Permission tests pass
Sensitive values are not logged
Production secrets are configured securely
Production debug mode is disabled
Database migrations are reviewed
Critical dependency vulnerabilities are assessed
Attendance integrity protections pass
Upload validation works for included upload features
No known authentication or authorization bypass exists

Security approval is based on verified behaviour, not assumptions.

Success Criteria

Relvio's security strategy is successful when:

Organizations remain isolated.
Authentication sessions are protected.
Permissions are enforced by the backend.
Sensitive values are protected.
Cross-organization access is prevented.
Attendance integrity is preserved.
External input is validated.
Security events can be investigated.
Backups can be restored.
Critical vulnerabilities block release.
Security controls remain understandable and testable.

Security is not a one-time feature.

It is an ongoing engineering responsibility throughout the life of Relvio.