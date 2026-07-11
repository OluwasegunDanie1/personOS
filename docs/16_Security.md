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

Development Authentication Fixture Security

A development/test-support mechanism is approved for creating exactly one controlled local User for live local authentication lifecycle verification. Its scope and non-goals (not registration, not a seed framework, not production provisioning) are governed by Deployment.md.

The fixture must reuse the existing PasswordHashService/approved Argon2id primitive without duplicating or reimplementing password-hashing configuration.

The fixture must never log: the raw AUTH_FIXTURE_PASSWORD value, the resulting password hash, or the AUTH_FIXTURE_EMAIL value. No default or hardcoded fixture credentials are approved.

The fixture must refuse to run when NODE_ENV=production. It exists purely as local development/test tooling: it must never be exposed through a public API endpoint and must never be invoked automatically.

This fixture does not weaken any password-security requirement defined elsewhere in this document; the same Argon2id hashing and secret-handling rules apply to the credential it processes.

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

present
absent
excused
visitor

the backend must reject unsupported values.

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

For this boundary, client IP is the sole approved throttling key, resolved through standard NestJS/Express request IP handling. Do not manually parse X-Forwarded-For inside auth controllers. Do not combine the IP key with email, user ID, refresh-token hash, or device fingerprinting for this boundary.

Rate-limit rejection returns 429 Too Many Requests.

These thresholds and the package/keying decision apply specifically to the login/refresh/logout boundary. A generic requirement to rate limit elsewhere in this document does not by itself authorize thresholds, package selection, or keying strategy for other endpoints.

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

Rate limiting and brute-force protection remain required. Exact thresholds, package, keying strategy, and trust-proxy configuration for the login/refresh/logout boundary are resolved above. The forgot-password rate-limit threshold remains unresolved and must be decided before that endpoint is publicly exposed.

Security controls must avoid exposing whether a specific email account exists.

Authentication CORS Boundary

Native Flutter Android and iOS clients are not governed by browser CORS enforcement. Relvio v1 does not approve Flutter Web or other browser-client exposure. No CORS policy is introduced for the current native-mobile authentication API boundary. Browser exposure requires a future, separately approved CORS authority decision.

Idempotency Security

Sensitive write operations identified by the API Specification must support idempotency.

Examples:

Attendance check-in
Manual attendance submission
Invitation acceptance
Announcement sending
Campaign sending
Report export requests

Idempotency keys must be scoped appropriately.

A key used by one organization or operation must not incorrectly return data from another organization or operation.

Idempotency storage must not expose another user's response.

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