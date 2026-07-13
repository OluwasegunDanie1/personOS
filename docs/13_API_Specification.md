---
Document: API Specification
Version: 0.2
Status: Approved
Project: Relvio
Owner: Engineering Team
---

# API Specification

## Purpose

This document defines the communication contract between the Relvio Flutter application and the backend platform.

The API must be:

- Simple
- Predictable
- Secure
- Organization-aware
- Easy to maintain
- Easy to test
- Backward compatible

The API must support Relvio as a multi-organization People Operating System.

---

# API Architecture

Relvio uses REST APIs.

Standards:

- RESTful resource design
- JSON requests and responses
- HTTPS only
- Versioned endpoints
- Consistent naming
- Predictable response structures
- Server-side authorization
- Organization-level data isolation

Base URL:

```text
/api/v1

Example:

/api/v1/organizations/{organizationId}/people

API resource names must use lowercase plural nouns.

Examples:

/people
/events
/attendance
/follow-ups
/notifications
Multi-Organization Scoping

Relvio is a multi-organization platform.

Organization-owned resources must be scoped to an organization.

Example:

/api/v1/organizations/{organizationId}/people
/api/v1/organizations/{organizationId}/events
/api/v1/organizations/{organizationId}/attendance
/api/v1/organizations/{organizationId}/follow-ups

The backend must never trust organizationId alone.

For every organization-scoped request, the backend must:

Verify the authenticated user.
Verify organization membership.
Verify the user's role.
Verify the required permission.
Scope every database query to the organization.

A user must never access another organization's data without valid membership and permission.

Authentication

Protected endpoints require a valid access token.

Example:

Authorization: Bearer <access_token>

Access tokens are signed JWTs with a 15-minute lifetime, signed using HS256 with a symmetric secret.

Access-token claims:

sub (global User ID)
iat
exp
iss (relvio-api)
aud (relvio-mobile)

The login access token does not contain organization ID, active organization, role, or permission claims.

Refresh tokens are opaque, cryptographically secure random values with a 30-day lifetime. Refresh tokens rotate on every successful refresh. Reuse of an already rotated or revoked refresh token is treated as suspicious and revokes the entire refresh-token family.

Authentication failures must return:

401 Unauthorized

Permission failures must return:

403 Forbidden

Authenticated Request Boundary

A single global NestJS access-token guard protects all routes except the explicitly public endpoints below. Public routes are marked using an explicit public-route decorator/metadata mechanism; they are not merely "unguarded" by omission.

Public endpoints for the current implemented boundary:

POST /auth/login
POST /auth/refresh
POST /auth/logout

The global guard:

Extracts Authorization: Bearer <token>.
Verifies the signed JWT using the already-approved JWT configuration.
Requires a valid sub claim.
Resolves the User by sub.
Rejects a missing User, a deleted User, and a DISABLED User.
Attaches a minimal authenticated identity to the request: { userId: string }. It never attaches the full Prisma User record, passwordHash, or organization/role/permission context.

Organization switching never requires issuing a replacement access token; the access token remains global-identity-only for its entire lifetime.

Access-Token Error Codes

AUTHENTICATION_REQUIRED: missing Authorization header, non-Bearer scheme, or empty Bearer token.
INVALID_ACCESS_TOKEN: malformed token, invalid signature, invalid issuer/audience, expired token, missing/invalid sub, or a sub whose User no longer exists or is deleted.
USER_DISABLED: the resolved User's status is DISABLED.

All three use the standard error envelope. JWT library error details must never be exposed to the client.
Authentication Endpoints
Register
POST /auth/register

Creates a user account.

Login
POST /auth/login

Authenticates a user using email and password.

Request fields:

email
password

Success response data:

accessToken
refreshToken
expiresIn
user

expiresIn is the access-token lifetime in seconds.

Login returns the global User identity. Login does not automatically select an active Organization context. Organization context selection is a separate explicit membership/context workflow.

Refresh Session
POST /auth/refresh

Returns a new access token and a new rotated refresh token using a valid, unrevoked refresh token.

Request body:

{
  "refreshToken": "string"
}

Success response data:

{
  "accessToken": "string",
  "refreshToken": "string",
  "expiresIn": 900
}

expiresIn is the access-token lifetime in seconds.

Logout
POST /auth/logout

Revokes the active refresh-token session.

Request body:

{
  "refreshToken": "string"
}

Logout is idempotent. It must not reveal whether the supplied refresh token existed or was already revoked.

Success response data:

{
  "success": true
}

This object is business data. It is still wrapped by the approved global success envelope, producing:

{
  "success": true,
  "data": {
    "success": true
  }
}

Logout does not use a special envelope exception.

Forgot Password
POST /auth/forgot-password

Requests a password reset.

The response must not reveal whether an email address exists.

Reset Password
POST /auth/reset-password

Resets a password using a valid reset token.

Current User
GET /auth/me

Returns the authenticated user and the active organization context where one has been separately established.

Standard Response Format
Success Response
{
  "success": true,
  "message": "Person created successfully.",
  "data": {}
}

For collection responses:

{
  "success": true,
  "data": [],
  "meta": {}
}
Standard Error Format

Errors must contain machine-readable error codes.

Example:

{
  "success": false,
  "error": {
    "code": "PERSON_EMAIL_EXISTS",
    "message": "A person with this email already exists.",
    "details": {}
  }
}

The Flutter application must use the code property for predictable application behaviour.

The application must never depend on parsing human-readable error messages.

Stable v1 codes for the login/refresh/logout boundary:

INVALID_CREDENTIALS
INVALID_REFRESH_TOKEN
USER_DISABLED

These codes are authoritative for POST /auth/login, POST /auth/refresh, and POST /auth/logout and must not be paired with a conflicting AUTH_-prefixed equivalent for the same condition.

Stable v1 codes for the authenticated-request boundary (all protected routes):

AUTHENTICATION_REQUIRED
INVALID_ACCESS_TOKEN
USER_DISABLED

USER_DISABLED is the same stable code used at login; it applies wherever a DISABLED User is resolved, whether during login or during access-token identity resolution.

Stable v1 code for the organization-membership boundary:

ORGANIZATION_ACCESS_DENIED

Used for a malformed organizationId, a non-existent organization, a missing membership for the authenticated user, or a membership that cannot resolve its role consistently. This code must never reveal whether another tenant's organization exists.

Stable v1 codes for the People domain:

PERSON_NOT_FOUND
JOURNEY_STAGE_NOT_FOUND

PERSON_NOT_FOUND is used for an absent, deleted, or cross-tenant Person on any personId route, without disclosing cross-tenant existence. JOURNEY_STAGE_NOT_FOUND is used when a supplied journeyStageId does not belong to the validated organization, or (for Journey Stage routes) for an absent, already-deleted, or cross-tenant stageId. Relvio v1 does not define PERSON_DUPLICATE, EMAIL_ALREADY_EXISTS, PHONE_ALREADY_EXISTS, or PERSON_ALREADY_DELETED; Person.email and Person.phone are not unique and duplicates are allowed.

Stable v1 codes for the Journey Stage and Person Journey domain:

INVALID_STAGE_ORDER
JOURNEY_STAGE_IN_USE
PERSON_ALREADY_IN_STAGE

INVALID_STAGE_ORDER is used for any Reorder Journey Stages request that is malformed, incomplete, contains a foreign stage, or contains a duplicate, without disclosing whether a foreign stage id exists. JOURNEY_STAGE_IN_USE is used when Delete Journey Stage targets a stage still referenced by PersonJourneyHistory as fromStageId or toStageId. PERSON_ALREADY_IN_STAGE is used when a journey movement request targets the Person's current stage.

Example error codes for other areas:

AUTH_SESSION_EXPIRED
PERMISSION_DENIED
EVENT_NOT_FOUND
ATTENDANCE_ALREADY_RECORDED
INVITATION_INVALID
INVITATION_EXPIRED
VALIDATION_ERROR
INTERNAL_SERVER_ERROR
Organization Endpoints
List User Organizations
GET /organizations

Authenticated (subject to the global access-token guard). Returns only organizations for which the authenticated User has an OrganizationMembership.

Success response data:

{
  "organizations": [
    {
      "id": "string",
      "name": "string",
      "logoUrl": "string | null",
      "role": {
        "id": "string",
        "name": "string"
      }
    }
  ]
}

Permission codes are not included in this response.

Ordering: organization name ascending, with deterministic secondary ordering by organization id ascending.

Empty state: HTTP 200 with the standard success envelope and:

{
  "organizations": []
}

Organization Context Mechanism

Relvio v1 does not maintain server-side active-organization session state, does not use an organization header, and does not issue organization-scoped JWTs. After login, the Flutter application calls GET /organizations, lets the user choose an organization locally, stores the selected organization ID as application context, and supplies that ID through the {organizationId} path parameter already used by every organization-scoped endpoint below. Organization selection/switching is therefore a Flutter application-context action, not a backend select/switch endpoint. There is no POST /organizations/select or POST /organizations/switch endpoint.

Every organization-scoped request below independently validates membership for the authenticated user and the path organizationId using a reusable organization-membership boundary. This boundary runs after the global access-token guard and consumes its resolved userId rather than re-verifying the JWT. It attaches minimal organization request context: { organizationId: string, membershipId: string, roleId: string }. It never attaches full Prisma models or permission codes. Permission authorization itself is deferred until a specific endpoint requires a permission check.

Create Organization
POST /organizations

Requires the global access-token guard only; it is never organization-scoped (the Organization does not yet exist) and OrganizationMembershipGuard must not be applied to this route. The creator identity is always request.auth.userId from the validated access token; the request body never accepts a userId or creator field.

Request fields (no others accepted):

{ "name": "string" }

name is required, trimmed, and must remain non-empty after trim. There is no maximum length beyond what the existing validation conventions already impose, no slug field, and no uniqueness constraint on name — two Organizations may share the same name. The request never accepts industry, logoUrl, country, timezone, role, ownerId, setupComplete, status, or any billing/plan field; all are rejected as unknown fields by the existing global ValidationPipe.

Creation is one atomic operation (a single Prisma transaction) creating exactly three rows: the Organization; exactly one Role named "Owner" scoped to that new Organization (organizationId = the new Organization's id); and exactly one OrganizationMembership linking the authenticated creator User, the new Organization, and that new Role. This mirrors the naming convention already established by the approved Organization Fixture (16_Security.md, Deployment.md), extended here into the real, non-fixture creation path. Zero Permission or RolePermission rows are created; permission enforcement remains deferred as it is everywhere else in v1. If any part of this transaction fails, no Organization, Role, or OrganizationMembership row is left behind (no orphan Organization).

The database's required, unique slug column is set internally to the new Organization's own generated id. This is a mechanical detail to satisfy a non-null unique database constraint; it is never accepted from or returned to the client, and no human-readable slug scheme is implemented.

Success response data (HTTP 201, standard success envelope):

{
  "organization": {
    "id": "string",
    "name": "string"
  }
}

Immediately after creation, the creator is an active member of the new Organization: GET /organizations returns the new Organization in the caller's list (with role name "Owner"), and every existing OrganizationMembershipGuard-protected endpoint (People, Journey, Events, Attendance, Follow-Ups, Dashboard Summary) works against the new organizationId without any fixture or manual provisioning step.

Get Organization
GET /organizations/{organizationId}

Requires the global access-token guard, OrganizationMembershipGuard, and a validated request.organization context, identically to every other organization-scoped endpoint. Service-level access is scoped by id = organizationId (no separate deletedAt column exists on Organization). An absent or non-member-accessible Organization returns ORGANIZATION_ACCESS_DENIED — the existing membership-boundary code — never a distinct not-found code, since OrganizationMembershipGuard already rejects before the handler runs.

Success response data:

{
  "organization": {
    "id": "string",
    "name": "string"
  }
}

industry, logoUrl, country, timezone, email, phone, address, and subscriptionPlan are not included; this document does not approve exposing them.

Update Organization
PATCH /organizations/{organizationId}

Requires the global access-token guard, OrganizationMembershipGuard, and a validated request.organization context. No role-specific restriction is approved for this endpoint in v1: any active member may update name; there is no Owner-only or Administrator-only enforcement, because v1 has no approved permission-enforcement mechanism. This membership-only boundary is explicit and temporary pending a future approved role/permission slice.

Mutable fields (no others accepted): { "name": "string" }. name is the only approved mutable field; at least one accepted field (i.e. name) must be supplied, trimmed, and non-empty. industry, logoUrl, country, timezone, role, ownerId, and any setup-state or billing/plan field are rejected as unknown fields.

Success response data matches Get Organization's shape. An absent or non-member-accessible Organization returns ORGANIZATION_ACCESS_DENIED.

Delete Organization
DELETE /organizations/{organizationId}

Deferred and unresolved. This path is named only as a placeholder; hard delete, soft delete, archive, cascade, and ownership-transfer semantics are not defined and must not be implemented from this bare path.

Organization Setup

Organization Setup is not a separate persisted lifecycle or state in v1. There is no setupComplete, onboardingComplete, setupCompletedAt, onboardingStep, or any setup-status/progress field, and no separate setup-completion endpoint. Successful Create Organization (which atomically establishes the creator's membership) is, by itself, a usable organization context: the Flutter Organization Setup screen may collect and display only the name field actually supported by this contract; any other visually present field must not be wired to a backend capability until separately approved.

Server-Side Active-Organization Selection

Unchanged from the existing Organization Context Mechanism above: there is no server-side active-organization session, no organization-switch endpoint, and no organization header. GET /organizations (unchanged, see List User Organizations above) remains the sole mechanism for the client to discover organization membership/context after Create Organization succeeds.

Organization-Domain Error Codes

ORGANIZATION_ACCESS_DENIED: reused unchanged from the existing organization-membership boundary; used for View/Update when the organizationId is absent or the authenticated user is not an active member, without disclosing which case applies.

There is no dedicated public error code for a Create Organization transaction failure (for example, the "Owner" Role or OrganizationMembership insert failing within the same atomic transaction as the Organization insert). Since the "Owner" Role is always freshly created within the same transaction rather than looked up, this is not a distinct business condition; a failure here is a plain, internal, unexpected error. It surfaces as a generic 500 through the existing GlobalExceptionFilter, exactly as JourneyModule's OperationalTemplateService already does for its own internal template-invariant failure (see Journey Stage Endpoints above) — no new client-facing error code is invented, and the client must never be told it supplied invalid data for this failure.

Neither this document nor any Organization endpoint defines a dynamic/global Role catalogue, an Invitation model or workflow, a userId/role field on Create Organization, or an Owner-only/Administrator-only update restriction; none of these are approved v1 behavior.

Organization Invitations
Create Invitation
POST /organizations/{organizationId}/invitations

Creates an invitation.

The invitation may contain:

email
role_id
expires_at
List Invitations
GET /organizations/{organizationId}/invitations
Accept Invitation
POST /invitations/{code}/accept

Adds the authenticated user to the organization.

Revoke Invitation
DELETE /organizations/{organizationId}/invitations/{invitationId}
Organization Members

These endpoints operate on a user's Organization Membership within the given organization. A user is a global identity and may hold a separate membership, with its own role, in each organization they belong to.

List Members
GET /organizations/{organizationId}/members
View Member
GET /organizations/{organizationId}/members/{userId}
Update Member Role
PATCH /organizations/{organizationId}/members/{userId}/role

Updates the role on the user's membership for this organization only.

Remove Member
DELETE /organizations/{organizationId}/members/{userId}
People Endpoints

People are organization-owned resources. All five People endpoints below require the global access-token guard, OrganizationMembershipGuard membership validation, and a validated request.organization context. There is no Community filter in Relvio v1; the previously undefined "Community filters" wording is removed.

For any route containing personId, service-level Person access must scope by both id = personId and organizationId = validated organizationId. A personId-only lookup is prohibited. Cross-tenant Person access and an absent/non-visible Person both return the same stable error, PERSON_NOT_FOUND, without disclosing cross-tenant existence.

Person Status

The closed v1 accepted API values for Person.status are exactly:

ACTIVE
INACTIVE

The underlying database column remains a plain string; this is an API-level allowlist, not a schema enum. Default status on creation is ACTIVE.

List People
GET /organizations/{organizationId}/people

Approved query parameters: cursor, limit, search, journeyStageId, status, sort.

limit: default 20, minimum 1, maximum 100.

sort: one of name_asc (default), name_desc, newest, oldest.

name_asc: firstName ascending, lastName ascending, id ascending.
name_desc: firstName descending, lastName descending, id ascending.
newest: createdAt descending, id ascending.
oldest: createdAt ascending, id ascending.

Cursor pagination is opaque to the client; its internal encoding is an implementation detail, not part of this API contract.

Only non-deleted Persons are returned (deletedAt IS NULL).

search: trimmed; an empty trimmed value behaves as no search; case-insensitive; matches firstName, lastName, email, or phone (OR semantics).

journeyStageId: returns Persons whose current journey stage matches. For v1, current journey stage is the most recent PersonJourneyHistory record by movedAt descending, then id descending (movedAt is the approved PersonJourneyHistory timestamp field); a Person with no journey history does not match any journeyStageId. The supplied journeyStageId must belong to the validated organization; if it does not exist there, return JOURNEY_STAGE_NOT_FOUND.

status: ACTIVE or INACTIVE only.

Invalid status, sort, limit, or other query values use the existing standard validation error handling.

Success response data:

{
  "people": [
    {
      "id": "string",
      "firstName": "string",
      "lastName": "string",
      "email": "string | null",
      "phone": "string | null",
      "status": "ACTIVE | INACTIVE",
      "avatarUrl": "string | null",
      "joinedAt": "string",
      "currentJourneyStage": { "id": "string", "name": "string" } | null,
      "lastAttendance": { "checkedInAt": "string" } | null
    }
  ],
  "nextCursor": "string | null"
}

joinedAt maps to Person.createdAt.

currentJourneyStage is resolved from the latest PersonJourneyHistory row per Person, ordered movedAt descending then id descending (the same deterministic ordering rule used by the journeyStageId filter above); a Person with no journey history returns null. Journey stage names are organization-configured through the existing Journey Stage endpoints and are not a fixed set of system enums — no reference label (e.g. Visitor, Member, Volunteer, Leader) is hardcoded by this contract. Only id and name are included; position, color, description, and any journey-template identifiers are not part of this shape.

lastAttendance is resolved from the latest Attendance row per Person, ordered checkedInAt descending then id descending; a Person with no Attendance record returns null. checkedInAt is Attendance's authoritative timestamp and is returned as an ISO-8601 absolute instant. Only checkedInAt is included — event detail (id, title, start time), attendance status, and the Attendance record's own id are not part of this shape.

Both fields are resolved per page in bounded, organization-scoped batch operations, not per-Person queries.

The list response still does not include tags, follow-up summary, notes, membership information, Person.address, Person.gender, Person.dateOfBirth, or Group data. Create Person's response and Person Detail's response are unchanged by this contract; currentJourneyStage and lastAttendance in this exact List shape are List-only.

Empty state (HTTP 200, standard success envelope):

{
  "people": [],
  "nextCursor": null
}

Create Person
POST /organizations/{organizationId}/people

Request fields (no others accepted):

{
  "firstName": "string",
  "lastName": "string",
  "email": "string | null (optional)",
  "phone": "string | null (optional)",
  "status": "ACTIVE | INACTIVE (optional)",
  "gender": "MALE | FEMALE (optional)",
  "dateOfBirth": "string | null (optional)",
  "address": "string | null (optional)"
}

Required: firstName, lastName.

Normalization: firstName and lastName are trimmed; email is trimmed and lowercased; phone is trimmed; dateOfBirth and address are trimmed; an empty normalized optional email, phone, dateOfBirth, or address becomes null.

Validation: firstName and lastName must remain non-empty after trim; email, when non-null, must be syntactically valid; status, when supplied, must be ACTIVE or INACTIVE. Default status is ACTIVE. gender, when supplied, must be exactly MALE or FEMALE (case-sensitive); no other value, including lowercase or mixed-case variants, is accepted. dateOfBirth, when non-null, must be a date-only string in exact YYYY-MM-DD form representing a real calendar date; an ISO 8601 datetime (with a time component, an offset, or a Z suffix) is rejected, as is a calendar-invalid date such as 2025-02-30 or 2023-13-01. address, when non-null, is free text with no structural decomposition (no street/city/state/postal/country subfields).

Relvio v1 imposes no database uniqueness on Person.email or Person.phone. Creation is never rejected merely because another Person in the organization shares the same email or phone. No duplicate detection or merge behavior is implemented.

Creation does not assign tags, assign a journey stage, or create journey history, attendance, a follow-up, or a note. gender, dateOfBirth, and address are persisted on the Person row but are not included in the create success response or in any List/Detail response; they remain write-only through this endpoint in v1.

Success response data (HTTP 201, standard success envelope):

{
  "person": {
    "id": "string",
    "firstName": "string",
    "lastName": "string",
    "email": "string | null",
    "phone": "string | null",
    "status": "ACTIVE | INACTIVE",
    "avatarUrl": "string | null",
    "joinedAt": "string"
  }
}

View Person
GET /organizations/{organizationId}/people/{personId}

Success response data:

{
  "person": {
    "id": "string",
    "firstName": "string",
    "lastName": "string",
    "email": "string | null",
    "phone": "string | null",
    "status": "ACTIVE | INACTIVE",
    "avatarUrl": "string | null",
    "joinedAt": "string",
    "tags": [
      { "id": "string", "name": "string" }
    ],
    "currentJourneyStage": { "id": "string", "name": "string" } | null,
    "gender": "MALE | FEMALE | null",
    "dateOfBirth": "YYYY-MM-DD | null",
    "address": "string | null"
  }
}

Tags must belong to the same organization through the Person's PersonTag relations, ordered name ascending then id ascending. currentJourneyStage uses the same latest-history rule as the journeyStageId filter above. Journey history, attendance history/summary, follow-ups, and notes are not embedded here; those remain separate product concerns/endpoints (see Person Timeline, Person Journey, and Person Attendance Summary below). A deleted Person behaves as PERSON_NOT_FOUND.

gender, dateOfBirth, and address are read back exactly as persisted by Create Person (see Create Person below); this is Detail-only read authority. They are not added to the List response's Person shape, Create Person's own response, or Update Person's own response — only this View Person endpoint exposes them. dateOfBirth is serialized as an exact date-only YYYY-MM-DD string derived from the stored calendar date's UTC components; it is never rendered as a full timestamp and never shifted by a server timezone conversion.

Update Person
PATCH /organizations/{organizationId}/people/{personId}

Mutable fields (no others accepted):

{
  "firstName": "string (optional)",
  "lastName": "string (optional)",
  "email": "string | null (optional)",
  "phone": "string | null (optional)",
  "status": "ACTIVE | INACTIVE (optional)",
  "gender": "MALE | FEMALE | null (optional)",
  "dateOfBirth": "string | null (optional)",
  "address": "string | null (optional)"
}

Immutable through this endpoint: id, organizationId, avatarUrl, createdAt, updatedAt, deletedAt, tags, journey state/history, attendance, follow-ups, notes.

Partial-update semantics: at least one approved mutable field must be supplied. Normalization and validation match Create Person. An explicit null for email, phone, gender, dateOfBirth, or address clears it; an empty normalized value also becomes null for email, phone, dateOfBirth, and address. firstName and lastName cannot be null or empty after trim. Duplicate email/phone remain allowed. gender, when non-null, must be exactly MALE or FEMALE (case-sensitive); no other value is accepted. dateOfBirth, when non-null, must be a date-only string in exact YYYY-MM-DD form representing a real calendar date; an ISO 8601 datetime (with a time component, an offset, or a Z suffix) is rejected, as is a calendar-invalid date. address, when non-null, is free text with no structural decomposition.

Success response data matches Create Person's shape (Product Task 045: gender, dateOfBirth, and address become write-only mutable fields on this endpoint — the same write-only boundary Create Person already established — but, like Create Person's own response, Update Person's response never includes them; View Person remains the sole read authority for these three fields). A deleted or cross-tenant Person returns PERSON_NOT_FOUND.

Delete Person
DELETE /organizations/{organizationId}/people/{personId}

Person deletion is a soft deletion: deletedAt is set when the visible, organization-scoped Person exists. The Person row is never hard-deleted. PersonJourneyHistory, Attendance, FollowUp, Note, and PersonTag are never deleted or rewritten by this operation; historical/dependent records remain preserved.

First successful deletion returns (standard success envelope):

{
  "success": true
}

A repeated delete sees the Person as non-visible and returns PERSON_NOT_FOUND, as does a cross-tenant Person. No restore behavior is defined.

Tag and Journey Boundary for People CRUD

Tags are read-only through Person detail for this People CRUD slice; Tag CRUD endpoints are not defined here, and Create/Update Person never assign or mutate tags. People list may filter by current journey stage and Person detail may expose currentJourneyStage, but Create/Update Person never change journey stage; journey-stage movement remains governed by the separate Person Journey endpoint below, not by PATCH Person.

Person-Domain Error Codes

PERSON_NOT_FOUND: an absent, deleted, or cross-tenant Person for any personId route.
JOURNEY_STAGE_NOT_FOUND: a journeyStageId query value that does not belong to the validated organization.

Neither this document nor any Person endpoint defines PERSON_DUPLICATE, EMAIL_ALREADY_EXISTS, PHONE_ALREADY_EXISTS, or PERSON_ALREADY_DELETED; these are not approved v1 codes. All other validation failures continue through the existing global validation/error foundation.

Person Timeline
View Timeline
GET /organizations/{organizationId}/people/{personId}/timeline

Timeline events may include:

Journey transitions
Attendance
Follow-ups
Notes
Group changes
Communication activity
Profile activity

Timeline entries should be returned newest first.

V1 Operational Journey Template

Each Organization has exactly one operational JourneyTemplate in v1 application behavior. It is internal structural infrastructure required by the approved schema, not a user-facing resource: there is no v1 JourneyTemplate list, create, update, or delete endpoint, no template selector anywhere in the product, and no template switching. The Prisma schema's permissiveness (multiple JourneyTemplate rows are structurally possible per organization) does not authorize application behavior to create or expose more than one. User-facing Journey Template management/customization (naming, multiple templates, a workflow builder) remains deferred and requires separate future authority; see Feature_Backlog.md.

Journey Stage Endpoints

All five endpoints below require the global access-token guard, OrganizationMembershipGuard, and a validated organization context; none is public. Every stage always belongs to the Organization's single operational JourneyTemplate. journeyTemplateId is never exposed in API responses.

List Journey Stages
GET /organizations/{organizationId}/journey-stages

Success response data:

{
  "stages": [
    { "id": "string", "name": "string", "position": 1 }
  ]
}

Ordered by position ascending, then id ascending. Empty state: { "stages": [] }, HTTP 200.

The approved schema has no description column for Journey Stages; the position field is the schema's order column exposed under this response key. A description field is not part of this v1 contract; adding one is a future schema decision outside current authority.

Create Journey Stage
POST /organizations/{organizationId}/journey-stages

Request fields (no others accepted):

{ "name": "string" }

name is required, trimmed, and must remain non-empty after trim. The new stage always attaches to the Organization's single operational JourneyTemplate. position is assigned as the current maximum position in that template plus 1, or 1 if no stages exist. Duplicate stage names are allowed; the schema does not constrain name uniqueness. Creation never moves any Person.

Success response data (HTTP 201):

{ "stage": { "id": "string", "name": "string", "position": 1 } }

Update Journey Stage
PATCH /organizations/{organizationId}/journey-stages/{stageId}

Mutable fields (no others accepted): { "name": "string (optional)" }. At least one field must be supplied; today that is only name, which must be trimmed and non-empty (never null). position cannot be changed through this endpoint (see Reorder), and a stage can never move between templates. Success response data matches Create Journey Stage's shape.

Reorder Journey Stages
POST /organizations/{organizationId}/journey-stages/reorder

Request:

{ "stageIds": ["string"] }

stageIds is required and non-empty; each value must be UUID-compatible with no duplicates; the list must contain every current stage of the Organization's operational template exactly once (no foreign stage, no missing current stage, no extra stage). Request order becomes positions 1..N, applied atomically. Reorder never mutates PersonJourneyHistory and never changes any Person's current stage.

Success response data: { "stages": [ { "id": "string", "name": "string", "position": 1 } ] }, ordered by the new position then id.

Stable error: INVALID_STAGE_ORDER, used for any violation above (missing/extra/foreign/duplicate stage, malformed input). It never discloses whether a foreign stage id actually exists.

Delete Journey Stage
DELETE /organizations/{organizationId}/journey-stages/{stageId}

JourneyStage has no soft-delete column. Deletion is a hard delete, allowed only when the stage has zero PersonJourneyHistory references as either fromStageId or toStageId; a referenced stage is rejected with JOURNEY_STAGE_IN_USE. Deletion never rewrites history, never moves a Person automatically, and never renumbers remaining stage positions (gaps are allowed; a future Reorder call may normalize them).

Success response data: { "success": true }. An absent, already-deleted, or cross-tenant stage returns JOURNEY_STAGE_NOT_FOUND.

Person Journey
View Person Journey
GET /organizations/{organizationId}/people/{personId}/journey

Person is scoped by id + validated organizationId + deletedAt null; an absent, deleted, or cross-tenant Person returns PERSON_NOT_FOUND.

Success response data:

{
  "currentJourneyStage": { "id": "string", "name": "string", "position": 1 } | null,
  "history": [
    {
      "id": "string",
      "fromStage": { "id": "string", "name": "string" } | null,
      "toStage": { "id": "string", "name": "string" },
      "note": "string | null",
      "movedAt": "string",
      "movedBy": { "id": "string", "firstName": "string", "lastName": "string" }
    }
  ]
}

currentJourneyStage is derived from the latest PersonJourneyHistory row (movedAt descending, then id descending); null when no history exists. history is ordered movedAt descending, then id descending, with no pagination in v1. note is the schema's notes column exposed under this response key. movedBy exposes only id, firstName, lastName — never email, phone, status, passwordHash, or deletedAt. If that User later becomes DISABLED or is soft-deleted, historical movedBy attribution remains visible unchanged; history is immutable.

Create Journey Movement
POST /organizations/{organizationId}/people/{personId}/journey/transitions

Request fields (no others accepted):

{ "stageId": "string", "note": "string | null (optional)" }

stageId is required and UUID-compatible. note is optional, trimmed, and an empty normalized value becomes null. The request must never accept movedBy, movedAt, fromStageId, personId, organizationId, or templateId; all are server-derived or path-derived.

Person is scoped by id + validated organizationId + deletedAt null (PERSON_NOT_FOUND otherwise). The target stageId must belong (indirectly, through the operational JourneyTemplate) to the validated organization; an absent or cross-tenant target returns JOURNEY_STAGE_NOT_FOUND without disclosing foreign existence. Current stage is the latest PersonJourneyHistory row (movedAt desc, id desc); the first movement for a Person has fromStageId null, later movements use the current stage id. movedBy is always request.auth.userId; movedAt is always server-generated. Movement always appends exactly one new, immutable PersonJourneyHistory row; an existing row is never updated or deleted, and Person.currentJourneyStageId is never written.

Moving to the Person's current stage is rejected with PERSON_ALREADY_IN_STAGE. Backward movement and skipping stages are both allowed; v1 defines no transition graph or rule engine. No authorization beyond validated organization membership is required in v1. The append is a single atomic operation.

Success response data (HTTP 201):

{
  "movement": {
    "id": "string",
    "fromStage": { "id": "string", "name": "string" } | null,
    "toStage": { "id": "string", "name": "string" },
    "note": "string | null",
    "movedAt": "string",
    "movedBy": { "id": "string", "firstName": "string", "lastName": "string" }
  }
}

Follow-Up Endpoints

Follow-ups are organization-owned resources. All five Follow-Up endpoints below require the global access-token guard, OrganizationMembershipGuard membership validation, and a validated request.organization context. There is no Delete Follow-Up endpoint; FollowUp has no deletedAt column, and this is an intentional, controlled decision, not an oversight.

The approved FollowUp schema has no createdAt, updatedAt, or deletedAt column, and no relationship to JourneyTemplate/JourneyStage. Nothing in this contract may assume a persisted Timeline/Activity record, an automatic notification, or a Journey coupling.

For any route containing followUpId, service-level FollowUp access must scope by both id = followUpId and organizationId = validated organizationId. A followUpId-only lookup is prohibited. An absent or cross-tenant FollowUp returns the stable error FOLLOW_UP_NOT_FOUND, without disclosing cross-tenant existence.

Follow-Up Status

The closed v1 accepted API values for FollowUp.status are exactly:

PENDING
IN_PROGRESS
COMPLETED

The underlying database column remains a plain string; this is an API-level allowlist, not a schema enum. Default status on creation is PENDING. No other status value (CANCELLED, OVERDUE, SNOOZED, BLOCKED, ESCALATED, or any other) is approved. Overdue is a due-date-derived condition computed by comparing dueDate to the current time; it is never a persisted or accepted status value.

List Follow-Ups
GET /organizations/{organizationId}/follow-ups

Approved query parameters (exactly these): cursor, limit, status, assigned_user_id, person_id, due_date, sort.

limit: default 20, minimum 1, maximum 100.

sort: exactly one of dueDate_asc (default), dueDate_desc, title_asc. FollowUp has no createdAt/updatedAt column, so no sort based on creation or update time is defined.

dueDate_asc: dueDate ascending with nulls last, id ascending.
dueDate_desc: dueDate descending with nulls last, id ascending.
title_asc: title ascending, id ascending.

Every sort ends with id ascending as the deterministic tie-break. Cursor pagination is opaque to the client and bound to the active sort, following the same convention already approved for People and Events; its internal encoding is an implementation detail, not part of this API contract.

status: optional filter, one of PENDING, IN_PROGRESS, COMPLETED.

assigned_user_id: optional filter. The supplied value must resolve to a User holding an active OrganizationMembership in the validated organization; if it does not, return ASSIGNED_USER_NOT_FOUND without disclosing whether the User exists globally or in another organization. A FollowUp with assignedTo null never matches a supplied assigned_user_id filter.

person_id: optional filter. The supplied value must belong to the validated organization (id + organizationId + deletedAt null); if it does not, return PERSON_NOT_FOUND (the existing People-domain error code), matching the journeyStageId precedent in the People list contract.

due_date: optional filter. Must be an ISO 8601 datetime string representing an absolute instant (same rule as Create/Update below). Used as an exact equality match against the stored dueDate value; there is no date-range, due_before/due_after, overdue=true, calendar-window, or reminder-window filter. A FollowUp with dueDate null never matches a supplied due_date filter.

Invalid sort, limit, status, or other query values use the existing standard validation error handling.

Success response data:

{
  "followUps": [
    {
      "id": "string",
      "title": "string",
      "description": "string | null",
      "dueDate": "string | null",
      "status": "PENDING | IN_PROGRESS | COMPLETED",
      "completedAt": "string | null",
      "person": { "id": "string", "firstName": "string", "lastName": "string" },
      "assignedTo": { "id": "string", "firstName": "string", "lastName": "string" } | null
    }
  ],
  "nextCursor": "string | null"
}

Empty state (HTTP 200, standard success envelope): { "followUps": [], "nextCursor": null }.

Create Follow-Up
POST /organizations/{organizationId}/follow-ups

Request fields (no others accepted):

{
  "personId": "string",
  "title": "string",
  "description": "string | null (optional)",
  "dueDate": "string | null (optional)",
  "assignedTo": "string | null (optional)"
}

Required: personId, title.

Normalization: title and description are trimmed; an empty normalized optional value becomes null.

Validation: title must remain non-empty after trim; personId must belong to the validated organization (id + organizationId + deletedAt null), else PERSON_NOT_FOUND; dueDate, when supplied and non-null, must be an ISO 8601 datetime string representing an absolute instant (an explicit UTC offset or Z suffix is required); assignedTo, when supplied and non-null, must resolve to a User holding an active OrganizationMembership in the validated organization, else ASSIGNED_USER_NOT_FOUND.

status and completedAt are never accepted through this endpoint; they are always server-derived (status is always PENDING, completedAt is always null on creation). organizationId is always path-derived. Creation never creates a Timeline/Activity record, a Notification, or any Journey record.

Success response data (HTTP 201, standard success envelope):

{
  "followUp": {
    "id": "string",
    "title": "string",
    "description": "string | null",
    "dueDate": "string | null",
    "status": "PENDING",
    "completedAt": null,
    "person": { "id": "string", "firstName": "string", "lastName": "string" },
    "assignedTo": { "id": "string", "firstName": "string", "lastName": "string" } | null
  }
}

View Follow-Up
GET /organizations/{organizationId}/follow-ups/{followUpId}

Success response data matches Create Follow-Up's shape (with whatever status/completedAt/assignedTo the FollowUp currently holds). An absent or cross-tenant FollowUp returns FOLLOW_UP_NOT_FOUND.

Update Follow-Up
PATCH /organizations/{organizationId}/follow-ups/{followUpId}

Mutable fields (no others accepted): title, description, dueDate, assignedTo, status — all optional. completedAt is never accepted through this endpoint under any circumstance.

Partial-update semantics: at least one approved mutable field must be supplied. title cannot be null or empty after trim. description, dueDate, and assignedTo may each be explicitly nulled (an empty normalized string also becomes null); assignedTo null means unassigned. dueDate and assignedTo follow the same validation as Create Follow-Up.

status, when supplied, must be one of PENDING or IN_PROGRESS only; COMPLETED is never an accepted value through this endpoint (see Complete Follow-Up below). If the FollowUp's current stored status is already COMPLETED, supplying status in the same request is rejected with FOLLOW_UP_ALREADY_COMPLETED, regardless of the supplied value; a completed FollowUp can never be returned to an incomplete state through Update. All other approved fields (title, description, dueDate, assignedTo) remain updatable on an already-completed FollowUp.

Success response data matches Create Follow-Up's shape. An absent or cross-tenant FollowUp returns FOLLOW_UP_NOT_FOUND.

Complete Follow-Up
PATCH /organizations/{organizationId}/follow-ups/{followUpId}/complete

Request: no fields accepted; the request body must be empty.

This is the sole approved path to the COMPLETED status. On a FollowUp whose current status is not COMPLETED, this sets status to COMPLETED and completedAt to the server clock at write time. On a FollowUp whose current status is already COMPLETED, this endpoint is idempotent: it returns the FollowUp unchanged, including its original completedAt value, which is never overwritten by a repeat call. This endpoint never reverses completion; there is no path back to PENDING or IN_PROGRESS once COMPLETED. Completing a Follow-Up never creates a Timeline/Activity record, a Notification, or any Journey record; no such persisted model exists.

Success response data (HTTP 200, standard success envelope) matches Create Follow-Up's shape.

Follow-Up-Domain Error Codes

FOLLOW_UP_NOT_FOUND: an absent or cross-tenant FollowUp for any followUpId route.
PERSON_NOT_FOUND: an absent or cross-tenant personId (Create Follow-Up) or person_id filter value (List Follow-Ups); reuses the existing People-domain code.
ASSIGNED_USER_NOT_FOUND: an assignedTo value (Create/Update) or assigned_user_id filter value (List) that does not resolve to an active OrganizationMembership in the validated organization.
FOLLOW_UP_ALREADY_COMPLETED: an Update Follow-Up request that supplies status on a FollowUp whose current status is already COMPLETED.

Neither this document nor any Follow-Up endpoint defines a Delete Follow-Up operation, a CANCELLED/OVERDUE/SNOOZED/BLOCKED/ESCALATED status, or a completion-history/reversal code; none of these are approved v1 codes or endpoints.

Event Endpoints

Events are organization-owned resources. All five Event endpoints below require the global access-token guard, OrganizationMembershipGuard membership validation, and a validated request.organization context.

The approved Event schema has no status, cancelledAt, or lifecycle-state column, no EventCategory model, and no EventTemplate model. category is a single plain nullable string column directly on Event, not a separate manageable resource. Event Categories and Event Templates as listable/creatable/updatable/deletable resources are not approved v1 endpoints; they referenced schema models that do not exist and have been removed from this contract. There is no Cancel Event endpoint and no event status filter: Delete Event (below) is the sole approved v1 lifecycle-ending action, and it already preserves the event record through soft deletion.

For any route containing eventId, service-level Event access must scope by both id = eventId and organizationId = validated organizationId, with deletedAt IS NULL. An absent, deleted, or cross-tenant Event returns the stable error EVENT_NOT_FOUND, without disclosing cross-tenant existence.

List Events
GET /organizations/{organizationId}/events

Approved query parameters (exactly these, no others): cursor, limit, search, category, sort. There is no date-range query filter in v1.

limit: default 20, minimum 1, maximum 100.

sort: exactly one of startDate_desc (default), startDate_asc, createdAt_desc, title_asc.

startDate_desc: startDate descending, id ascending.
startDate_asc: startDate ascending, id ascending.
createdAt_desc: createdAt descending, id ascending.
title_asc: title ascending, id ascending.

Every sort ends with id ascending as the deterministic tie-break. Cursor pagination is opaque to the client and is bound to the active sort; its internal encoding is an implementation detail, not part of this API contract.

Only non-deleted Events are returned (deletedAt IS NULL).

search: trimmed; an empty trimmed value behaves as no search (absent); case-insensitive contains (substring) match; matches title, description, or venue (OR semantics).

category: trimmed, case-insensitive exact match against Event.category; an Event with category null never matches a supplied category filter.

Invalid sort, limit, or other query values use the existing standard validation error handling.

Success response data:

{
  "events": [
    {
      "id": "string",
      "title": "string",
      "description": "string | null",
      "category": "string | null",
      "venue": "string | null",
      "startDate": "string",
      "endDate": "string | null",
      "createdAt": "string"
    }
  ],
  "nextCursor": "string | null"
}

Empty state (HTTP 200, standard success envelope): { "events": [], "nextCursor": null }.

Create Event
POST /organizations/{organizationId}/events

Request fields (no others accepted):

{
  "title": "string",
  "description": "string | null (optional)",
  "category": "string | null (optional)",
  "venue": "string | null (optional)",
  "startDate": "string",
  "endDate": "string | null (optional)"
}

Required: title, startDate.

Normalization: title, description, category, and venue are trimmed; an empty normalized optional value becomes null.

Validation: title must remain non-empty after trim; startDate must be an ISO 8601 datetime string representing an absolute instant (an explicit UTC offset or Z suffix is required; a date-only value or an offset-less local datetime is rejected as a standard validation error); endDate, when supplied and non-null, follows the same absolute-instant rule and must not be earlier than startDate, else INVALID_EVENT_DATE_RANGE.

createdBy is always request.auth.userId; it is never client-supplied. organizationId is always path-derived. Creation never creates an Attendance record.

Success response data (HTTP 201, standard success envelope):

{
  "event": {
    "id": "string",
    "title": "string",
    "description": "string | null",
    "category": "string | null",
    "venue": "string | null",
    "startDate": "string",
    "endDate": "string | null",
    "createdAt": "string",
    "createdBy": { "id": "string", "firstName": "string", "lastName": "string" }
  }
}

View Event
GET /organizations/{organizationId}/events/{eventId}

Success response data matches Create Event's shape. createdBy exposes only id, firstName, lastName — never email, phone, status, passwordHash, or deletedAt; historical attribution remains visible unchanged even if that User later becomes DISABLED or is soft-deleted. A deleted or cross-tenant Event returns EVENT_NOT_FOUND.

Update Event
PATCH /organizations/{organizationId}/events/{eventId}

Mutable fields (no others accepted): title, description, category, venue, startDate, endDate — all optional, same normalization and validation as Create Event. Partial-update semantics: at least one approved mutable field must be supplied. An explicit null for description, category, venue, or endDate clears it; an empty normalized value also becomes null. title and startDate cannot be null or empty after trim. Date-range validation always uses the final combined values that would actually be persisted — the supplied field's new value merged with the other field's existing stored value when only one of startDate/endDate is supplied in the request — and rejects with INVALID_EVENT_DATE_RANGE when the resulting effective endDate would be earlier than the resulting effective startDate.

Immutable through this endpoint: id, organizationId, createdBy, createdAt, updatedAt, deletedAt.

Success response data matches Create Event's shape. A deleted or cross-tenant Event returns EVENT_NOT_FOUND.

Delete Event
DELETE /organizations/{organizationId}/events/{eventId}

Event deletion is a soft deletion: deletedAt is set when the visible, organization-scoped Event exists. The Event row is never hard-deleted. Attendance records referencing this eventId are never deleted or rewritten by this operation; historical attendance remains preserved. This is the approved v1 equivalent of "cancelling" an event; there is no separate cancel action or status transition.

First successful deletion returns (standard success envelope): { "success": true }.

A repeated delete sees the Event as non-visible and returns EVENT_NOT_FOUND, as does a cross-tenant Event.

Event-Domain Error Codes

EVENT_NOT_FOUND: an absent, deleted, or cross-tenant Event for any eventId route.
INVALID_EVENT_DATE_RANGE: a supplied endDate earlier than the applicable startDate.

Neither this document nor any Event endpoint defines EVENT_CATEGORY_NOT_FOUND, EVENT_TEMPLATE_NOT_FOUND, or an event status/cancellation code; these are not approved v1 codes.

Attendance Endpoints

Attendance write behavior in Relvio v1 is narrowed to exactly three endpoints. There is no check-in-method endpoint variant (manual/search/walk-in/offline_sync), no walk-in-visitor endpoint that creates or links a Person, no batch/multi-entry manual attendance endpoint, and no attendance summary endpoint; none of these had schema or product backing beyond illustrative wording, and they are removed from this contract.

Attendance Status

The Prisma persistence enum (AttendanceStatus) remains exactly Present, Absent, Late — unchanged, schema-frozen. The public v1 API status values are a separate, distinct closed set, exactly:

PRESENT
ABSENT
LATE

The API must never expose internal Prisma enum casing. Every request and response boundary translates explicitly between the two using this exact mapping:

PRESENT -> Present
ABSENT -> Absent
LATE -> Late

and the corresponding reverse mapping (Present -> PRESENT, Absent -> ABSENT, Late -> LATE) when reading a stored row back out. excused and visitor remain unapproved in either casing and are rejected as validation errors.

For any route containing eventId or personId, service-level access must independently scope Event by id + organizationId + deletedAt null (EVENT_NOT_FOUND otherwise) and Person by id + organizationId + deletedAt null (PERSON_NOT_FOUND otherwise), mirroring the Journey movement dual-validation pattern. Attendance itself is scoped directly by organizationId, since the schema gives Attendance a direct organizationId column. Event.startDate may be in the past or the future; attendance may be recorded for either without restriction.

Event Attendance
GET /organizations/{organizationId}/events/{eventId}/attendance

Approved query parameters (exactly these): cursor, limit, status, sort.

limit: default 50, minimum 1, maximum 100. status: optional filter, one of the public values PRESENT, ABSENT, LATE.

sort: exactly one of checkedInAt_desc (default), checkedInAt_asc, personName_asc.

checkedInAt_desc: checkedInAt descending, id ascending.
checkedInAt_asc: checkedInAt ascending, id ascending.
personName_asc: person firstName ascending, person lastName ascending, id ascending.

Success response data:

{
  "attendance": [
    {
      "id": "string",
      "person": { "id": "string", "firstName": "string", "lastName": "string" },
      "status": "PRESENT | ABSENT | LATE",
      "checkedInBy": { "id": "string", "firstName": "string", "lastName": "string" } | null,
      "checkedInAt": "string"
    }
  ],
  "nextCursor": "string | null"
}

Empty state (HTTP 200): { "attendance": [], "nextCursor": null }.

A row remains visible in this list even after its referenced Person is later soft-deleted; Person.deletedAt never hides or removes historical Attendance, and the person sub-object continues to render from the Person's stored name fields.

Record Attendance
POST /organizations/{organizationId}/events/{eventId}/attendance

Request fields (no others accepted):

{ "personId": "string", "status": "PRESENT | ABSENT | LATE (optional, default PRESENT)" }

personId is required. status is optional and defaults to PRESENT when omitted; only the public values PRESENT, ABSENT, LATE are accepted (standard validation error otherwise). checkedInBy is always request.auth.userId; checkedInAt is always the server clock at write time; neither is client-supplied. eventId and organizationId are always path-derived.

Event is validated (id + organizationId + deletedAt null, else EVENT_NOT_FOUND) and Person is validated (id + organizationId + deletedAt null, else PERSON_NOT_FOUND) before any write. Event.startDate being in the past or the future does not affect whether attendance can be recorded.

Idempotency: the database-level unique constraint on (organizationId, eventId, personId) is the sole idempotency key; no Idempotency-Key header is required or read. If no Attendance row exists yet for this (organizationId, eventId, personId), one is created and returned with HTTP 201. If a matching row already exists, it is returned unchanged with HTTP 200: the request is not rejected, no duplicate is created, and the duplicate request's submitted status (including any explicit non-default value) is entirely ignored — it never updates the existing row's status, checkedInBy, or checkedInAt. No upsert-that-updates is approved; a duplicate request must never issue a write capable of modifying an existing row, and it produces no other side effects. Under a concurrent race (two requests attempting first-creation simultaneously), the backend must catch the resulting database unique-constraint violation and re-fetch and return the now-existing row with HTTP 200 rather than surfacing a 409 or 500.

Success response data (HTTP 201 on first creation, HTTP 200 on idempotent replay):

{
  "attendance": {
    "id": "string",
    "person": { "id": "string", "firstName": "string", "lastName": "string" },
    "status": "PRESENT | ABSENT | LATE",
    "checkedInBy": { "id": "string", "firstName": "string", "lastName": "string" } | null,
    "checkedInAt": "string"
  }
}

Person Attendance
GET /organizations/{organizationId}/people/{personId}/attendance

Approved query parameters (exactly these, no status filter): cursor, limit, sort.

limit: default 50, minimum 1, maximum 100.

sort: exactly one of checkedInAt_desc (default), checkedInAt_asc, eventStartDate_desc.

checkedInAt_desc: checkedInAt descending, id ascending.
checkedInAt_asc: checkedInAt ascending, id ascending.
eventStartDate_desc: event startDate descending, id ascending.

Success response data:

{
  "attendance": [
    {
      "id": "string",
      "event": { "id": "string", "title": "string", "startDate": "string" },
      "status": "PRESENT | ABSENT | LATE",
      "checkedInAt": "string"
    }
  ],
  "nextCursor": "string | null"
}

Empty state (HTTP 200): { "attendance": [], "nextCursor": null }.

A row remains visible in this history even after its referenced Event is later soft-deleted; Event.deletedAt never hides or removes historical Attendance for a Person.

Person Attendance Summary
GET /organizations/{organizationId}/people/{personId}/attendance/summary

Person is validated using the same active, organization-scoped authority as Person Attendance above (id + organizationId + deletedAt null, else PERSON_NOT_FOUND).

Success response data:

{
  "attendanceSummary": {
    "totalCount": 0,
    "currentMonthCount": 0
  }
}

totalCount is the count of immutable Attendance records for the Person within the validated organization (organizationId + personId), with no date bound. currentMonthCount is the same scope additionally bounded to the current calendar month by Attendance.checkedInAt: current month start (inclusive) through next month start (exclusive), evaluated against the backend server's UTC clock at request time. This is a fixed calendar-month window, never a rolling 30-day window, and is never derived from Event.startDate. Both counts are computed as bounded database aggregate counts; no Attendance rows are loaded into application memory to compute them. This endpoint returns only these two counts — no latestAttendance, no attendance history, no event summaries, no percentage, no streak, and no monthly trend array are part of this contract.

Attendance Lifecycle and Immutability

Attendance records are immutable once created: there is no Update Attendance, Delete Attendance, or any reversal/correction endpoint in v1. A recorded status can only be established at creation time; correcting a mistaken check-in requires a separately approved future capability, not a v1 endpoint. This mirrors the append-only immutability already approved for PersonJourneyHistory.

Editing an Event's startDate or endDate through Update Event never rewrites, recalculates, or otherwise touches any existing Attendance.checkedInAt value. Soft-deleting an Event or a Person never deletes, hard-removes, or rewrites existing Attendance rows; the historical-visibility rules above govern how those rows continue to display.

Attendance-Domain Error Codes

Attendance endpoints reuse EVENT_NOT_FOUND and PERSON_NOT_FOUND (defined above); no new Attendance-specific error code is introduced. Idempotent replay is a success response, not an error, and must never use a 409 or 422 status.

The backend must enforce attendance uniqueness using the database-level constraint on (organization_id, event_id, person_id), matching the approved Database Design; this constraint is what makes the idempotency behavior above correct even under concurrent requests. This constraint governs the internal Present/Absent/Late enum column; it is unaffected by the public PRESENT/ABSENT/LATE API mapping defined above.

Communities
List Communities
GET /organizations/{organizationId}/communities
Create Community
POST /organizations/{organizationId}/communities
View Community
GET /organizations/{organizationId}/communities/{communityId}
Update Community
PATCH /organizations/{organizationId}/communities/{communityId}
Delete Community
DELETE /organizations/{organizationId}/communities/{communityId}
Add Person To Community
POST /organizations/{organizationId}/communities/{communityId}/members
Remove Person From Community
DELETE /organizations/{organizationId}/communities/{communityId}/members/{personId}
Conversations

Messages is a frozen v1 UI navigation destination whose production backend remains explicitly deferred (12_Database_Design.md lists Messages under "Future Tables — not required for MVP"; no Conversation/Message Prisma model exists). The bare paths below are not field-complete and are not implementation-ready: they carry no approved request fields, response shapes, participant-identity model, pagination/sort contract, or error codes. Do not implement a production messaging backend from these paths. Do not build a fake/local-only conversation store to back the frozen Messages screen. The approved pre-backend v1 behavior for the Messages destination is defined in Mvp_scope.md ("Messages Navigation") and User_Flow.md ("Messages Navigation Flow"): the frozen screen shell remains routable and renders a neutral unavailable/not-yet-connected content state, with zero calls to any path below and non-functional compose/send controls.

List Conversations
GET /organizations/{organizationId}/conversations
Create Conversation
POST /organizations/{organizationId}/conversations
View Conversation
GET /organizations/{organizationId}/conversations/{conversationId}
Messages
List Messages
GET /organizations/{organizationId}/conversations/{conversationId}/messages
Send Message
POST /organizations/{organizationId}/conversations/{conversationId}/messages
Mark Conversation Read
PATCH /organizations/{organizationId}/conversations/{conversationId}/read
Announcements
List Announcements
GET /organizations/{organizationId}/announcements
Create Announcement
POST /organizations/{organizationId}/announcements
View Announcement
GET /organizations/{organizationId}/announcements/{announcementId}
Update Draft
PATCH /organizations/{organizationId}/announcements/{announcementId}
Send Announcement
POST /organizations/{organizationId}/announcements/{announcementId}/send
Schedule Announcement
POST /organizations/{organizationId}/announcements/{announcementId}/schedule
Email Campaigns
List Campaigns
GET /organizations/{organizationId}/campaigns
Create Campaign
POST /organizations/{organizationId}/campaigns
View Campaign
GET /organizations/{organizationId}/campaigns/{campaignId}
Update Campaign
PATCH /organizations/{organizationId}/campaigns/{campaignId}
Send Campaign
POST /organizations/{organizationId}/campaigns/{campaignId}/send
Campaign Analytics
GET /organizations/{organizationId}/campaigns/{campaignId}/analytics

Returns metrics such as:

recipients
delivered
opened
clicked
failed
Notifications
List Notifications
GET /notifications

Notifications are scoped to the authenticated user.

Supports:

category
read
cursor
limit
Mark Notification Read
PATCH /notifications/{notificationId}/read
Mark All Notifications Read
PATCH /notifications/read-all
Clear Read Notifications
DELETE /notifications/read
Roles
List Roles
GET /organizations/{organizationId}/roles
Create Role
POST /organizations/{organizationId}/roles
View Role
GET /organizations/{organizationId}/roles/{roleId}
Update Role
PATCH /organizations/{organizationId}/roles/{roleId}
Delete Role
DELETE /organizations/{organizationId}/roles/{roleId}

Protected system roles may not be deleted.

Permissions
List Permissions
GET /permissions

Returns supported platform permissions.

Examples:

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
View Role Permissions
GET /organizations/{organizationId}/roles/{roleId}/permissions
Update Role Permissions
PATCH /organizations/{organizationId}/roles/{roleId}/permissions
Reports

Dashboard Summary is resolved below. Attendance Report, Growth Report, Follow-Up Report, and Export Report remain unresolved and deferred; no field contract, formula, or export mechanism is approved for them. Do not implement them from the bare paths below.

Dashboard Summary
GET /organizations/{organizationId}/reports/dashboard

Dashboard Summary is a single, read-only, organization-scoped aggregate endpoint. It requires the global access-token guard, OrganizationMembershipGuard membership validation, and a validated request.organization context, identically to every other organization-scoped endpoint. It accepts no query parameters; any supplied query parameter is rejected by the existing global validation behavior. There is no Dashboard-specific error code: authentication, membership, and validation failures use the existing established codes (AUTHENTICATION_REQUIRED, INVALID_ACCESS_TOKEN, ORGANIZATION_ACCESS_DENIED). Dashboard Summary is exactly one endpoint; it is never split into multiple endpoints, and no generic analytics or metrics endpoint is approved.

Success response data:

{
  "totalPeople": 0,
  "newPeople": 0,
  "pendingFollowUps": 0,
  "upcomingEvents": [
    { "id": "string", "title": "string", "startDate": "string" }
  ]
}

totalPeople: count of People in the validated organization where deletedAt IS NULL and status = ACTIVE. INACTIVE and soft-deleted People are excluded. This is a current operational count, not a historical total.

newPeople: count of People in the validated organization matching the same totalPeople filter (deletedAt IS NULL, status = ACTIVE), additionally restricted to createdAt >= the start of the current UTC calendar day (00:00:00.000Z). There is no query parameter for a custom date window, no previous-period comparison, and no growth percentage; this document does not approve any of those.

pendingFollowUps: count of FollowUps in the validated organization whose status is PENDING or IN_PROGRESS. COMPLETED FollowUps are excluded. There is no overdue count and no reminder-state derivation.

upcomingEvents: the next 5 non-deleted Events in the validated organization (deletedAt IS NULL) whose startDate is greater than or equal to the current server UTC instant, ordered by startDate ascending then id ascending (deterministic tie-break). There is no fixed future cutoff window beyond "the next 5"; there is no status/cancelled filtering, since Event has no such column. Each entry reuses the same minimal Event reference shape already approved for the Person Attendance history endpoint (id, title, startDate) — no new Event persistence field or Dashboard-specific Event shape is introduced.

Not approved for v1 Dashboard Summary, and therefore never present in the response: attendanceRate, attendancePercentage (no approved denominator exists — Attendance has no expected-attendee, roster, RSVP, or capacity concept), todayAttendance (no Approved-status document establishes this requirement; it appears only in Draft/Atlas-era material, which is not authority), recentActivity (no persisted Timeline/Activity model exists), journeyStageDistribution (Journey history is immutable and per-transition; it is never aggregated as a current-stage snapshot), growth, trend, comparison percentages, overdueFollowUps, or any report metadata.

All Dashboard Summary time semantics use UTC exclusively. There is no organization timezone setting, no client/device timezone inference, and no timezone query parameter.

Attendance Report
GET /organizations/{organizationId}/reports/attendance
Growth Report
GET /organizations/{organizationId}/reports/growth
Follow-Up Report
GET /organizations/{organizationId}/reports/follow-ups
Export Report
POST /organizations/{organizationId}/reports/export

Example:

{
  "report": "attendance",
  "format": "pdf",
  "filters": {}
}

Supported formats:

pdf
xlsx
csv

Large report exports may be processed asynchronously.

Activity and Audit Logs
Organization Activity
GET /organizations/{organizationId}/activity

Returns user-facing activity.

Examples:

Person created
Journey stage changed
Event created
Attendance recorded
Follow-up completed
Audit Logs
GET /organizations/{organizationId}/audit-logs

Audit logs are restricted to authorized roles.

Audit logs may contain:

actor
action
resource_type
resource_id
timestamp
metadata
Organization Settings
View Settings
GET /organizations/{organizationId}/settings
Update Settings
PATCH /organizations/{organizationId}/settings

Settings may include:

Branding
Localization
Journey configuration
Attendance configuration
Communication preferences
User Profile
View Profile
GET /users/me
Update Profile
PATCH /users/me
Change Password
POST /users/me/change-password
List Sessions
GET /users/me/sessions
Revoke Session
DELETE /users/me/sessions/{sessionId}
Global Search
GET /organizations/{organizationId}/search

Example:

GET /organizations/{organizationId}/search?q=john

Search may include:

People
Events
Communities
Conversations
Notes

Search results must respect user permissions.

The API must never return resources the authenticated user cannot access.

Pagination

Relvio supports cursor pagination and page pagination.

Cursor Pagination

Use for high-volume or continuously changing resources:

People
Messages
Notifications
Activity
Audit logs

Example:

GET /organizations/{organizationId}/people?limit=20&cursor=cursor_value

Response:

{
  "success": true,
  "data": [],
  "meta": {
    "next_cursor": "cursor_value",
    "has_more": true
  }
}
Page Pagination

Use for stable reports and administrative datasets.

Example:

GET /organizations/{organizationId}/reports/attendance?page=1&limit=20

Response:

{
  "success": true,
  "data": [],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 120,
    "last_page": 6
  }
}
Filtering

Examples:

GET /organizations/{organizationId}/people?journey_stage=visitor
GET /organizations/{organizationId}/events?category=conference
GET /organizations/{organizationId}/follow-ups?status=PENDING

Filters must use documented field names.

Sorting

Ascending:

GET /organizations/{organizationId}/people?sort=first_name

Descending:

GET /organizations/{organizationId}/people?sort=-created_at

The - prefix means descending order.

Unsupported sorting fields must return a validation error.

Validation

All request data must be validated on the server.

Validation errors return:

422 Unprocessable Entity

Example:

{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The submitted data is invalid.",
    "details": {
      "email": [
        "Enter a valid email address."
      ]
    }
  }
}

The backend must never rely only on Flutter validation.

Authorization

Every protected endpoint must define its required permission.

Examples:

Action	Permission
View people	people.view
Create person	people.create
Update person	people.update
Delete person	people.delete
View events	events.view
Create event	events.create
Record attendance	attendance.record
Send communication	communication.send
View reports	reports.view
Export reports	reports.export
Update organization	organization.update
Manage roles	roles.manage
Manage billing	billing.manage
Manage settings	settings.manage

Authorization must be enforced by the backend.

The Flutter application may hide unavailable actions for usability, but client-side visibility is not security.

Idempotency

Sensitive write operations must support idempotency where duplicate requests could create incorrect data.

Required for:

Invitation acceptance
Announcement sending
Campaign sending
Report export requests

Header:

Idempotency-Key: <unique-key>

The backend must return the original result when the same key is safely retried.

Record Attendance is idempotent but does not use this header; its idempotency key is the database-level unique constraint on (organizationId, eventId, personId). See Attendance Endpoints above.

Rate Limiting

Rate limiting should be applied to sensitive endpoints.

Examples:

Login
Forgot password
Invitation acceptance
Global search
Message sending
Announcement sending
Campaign sending
Report exports

Rate-limit responses should return:

429 Too Many Requests

Approved v1 Authentication Rate Limits

The approved v1 rate-limit package is @nestjs/throttler.

Endpoint-specific limits for the current public authentication boundary:

POST /auth/login: maximum 5 requests per 60 seconds per client IP
POST /auth/refresh: maximum 10 requests per 60 seconds per client IP
POST /auth/logout: maximum 20 requests per 60 seconds per client IP

The throttling key is client IP only, derived through standard NestJS/Express request IP handling. Do not combine the key with email, user ID, refresh-token hash, or device identity. Do not manually parse X-Forwarded-For inside auth controllers.

Rejected requests return 429 Too Many Requests. Persistent account lockout remains out of scope for v1.
HTTP Status Codes
Code	Meaning
200	Success
201	Created
202	Accepted
204	No Content
400	Bad Request
401	Unauthorized
403	Forbidden
404	Not Found
409	Conflict
422	Validation Error
429	Too Many Requests
500	Internal Server Error
Security

Every protected endpoint must:

Verify authentication
Verify organization membership
Verify permissions
Validate request data
Scope database queries to the organization
Prevent cross-organization access
Use parameterized database queries
Avoid exposing internal errors
Record sensitive administrative actions where required

Never trust client-side data.

Never trust a client-provided organization identifier without validating membership.

Sensitive information must never be written to application logs.

API Versioning

Current version:

v1

Breaking API changes must create a new version.

Example:

/api/v2

Existing supported mobile clients must not be broken by undocumented API changes.

Non-breaking fields may be added to existing responses.

Existing response fields must not be renamed or removed without a version change.

API Documentation

The backend should maintain an OpenAPI specification.

Recommended format:

OpenAPI 3.1

The OpenAPI specification should document:

Endpoints
Request schemas
Response schemas
Authentication
Permissions
Error codes
Pagination
Filters

The API documentation should be updated when endpoints change.

Future APIs

Planned for later releases:

Public API
Webhooks
Bulk Import API
Bulk Export API
Integration API
Mobile SDK
Automation API

These APIs are outside the Relvio v1 scope.

Success Criteria

The Relvio API should be:

Easy to understand
Predictable
Secure
Organization-aware
Permission-aware
Consistent
Fast
Testable
Backward compatible
Easy for the Flutter application to consume

The API must support the approved Relvio product flows without requiring the Flutter client to bypass backend rules or implement business logic that belongs on the server.