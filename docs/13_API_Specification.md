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

PERSON_NOT_FOUND is used for an absent, deleted, or cross-tenant Person on any personId route, without disclosing cross-tenant existence. JOURNEY_STAGE_NOT_FOUND is used when a supplied journeyStageId does not belong to the validated organization. Relvio v1 does not define PERSON_DUPLICATE, EMAIL_ALREADY_EXISTS, PHONE_ALREADY_EXISTS, or PERSON_ALREADY_DELETED; Person.email and Person.phone are not unique and duplicates are allowed.

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

Creates a new organization.

The authenticated user becomes the organization owner.

Get Organization
GET /organizations/{organizationId}
Update Organization
PATCH /organizations/{organizationId}
Delete Organization
DELETE /organizations/{organizationId}

Restricted to authorized organization owners.

Organization deletion should use the approved deletion and retention strategy.

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

journeyStageId: returns Persons whose current journey stage matches. For v1, current journey stage is the most recent PersonJourneyHistory record by changedAt descending, then id descending; a Person with no journey history does not match any journeyStageId. The supplied journeyStageId must belong to the validated organization; if it does not exist there, return JOURNEY_STAGE_NOT_FOUND.

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
      "joinedAt": "string"
    }
  ],
  "nextCursor": "string | null"
}

joinedAt maps to Person.createdAt. The list response does not include tags, current journey stage, attendance summary, follow-up summary, notes, or membership information.

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
  "status": "ACTIVE | INACTIVE (optional)"
}

Required: firstName, lastName.

Normalization: firstName and lastName are trimmed; email is trimmed and lowercased; phone is trimmed; an empty normalized optional email or phone becomes null.

Validation: firstName and lastName must remain non-empty after trim; email, when non-null, must be syntactically valid; status, when supplied, must be ACTIVE or INACTIVE. Default status is ACTIVE.

Relvio v1 imposes no database uniqueness on Person.email or Person.phone. Creation is never rejected merely because another Person in the organization shares the same email or phone. No duplicate detection or merge behavior is implemented.

Creation does not assign tags, assign a journey stage, or create journey history, attendance, a follow-up, or a note.

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
    "currentJourneyStage": { "id": "string", "name": "string" } | null
  }
}

Tags must belong to the same organization through the Person's PersonTag relations, ordered name ascending then id ascending. currentJourneyStage uses the same latest-history rule as the journeyStageId filter above. Journey history, attendance history/summary, follow-ups, and notes are not embedded here; those remain separate product concerns/endpoints (see Person Timeline and Person Journey below). A deleted Person behaves as PERSON_NOT_FOUND.

Update Person
PATCH /organizations/{organizationId}/people/{personId}

Mutable fields (no others accepted):

{
  "firstName": "string (optional)",
  "lastName": "string (optional)",
  "email": "string | null (optional)",
  "phone": "string | null (optional)",
  "status": "ACTIVE | INACTIVE (optional)"
}

Immutable through this endpoint: id, organizationId, avatarUrl, createdAt, updatedAt, deletedAt, tags, journey state/history, attendance, follow-ups, notes.

Partial-update semantics: at least one approved mutable field must be supplied. Normalization and validation match Create Person. An explicit null for email or phone clears it; an empty normalized value also becomes null. firstName and lastName cannot be null or empty after trim. Duplicate email/phone remain allowed.

Success response data matches Create Person's shape. A deleted or cross-tenant Person returns PERSON_NOT_FOUND.

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

Journey Stage Endpoints
List Journey Stages
GET /organizations/{organizationId}/journey-stages
Create Journey Stage
POST /organizations/{organizationId}/journey-stages
Update Journey Stage
PATCH /organizations/{organizationId}/journey-stages/{stageId}
Reorder Journey Stages
PATCH /organizations/{organizationId}/journey-stages/reorder
Delete Journey Stage
DELETE /organizations/{organizationId}/journey-stages/{stageId}

Deletion must be rejected or safely handled when people currently reference the stage.

Person Journey
View Person Journey
GET /organizations/{organizationId}/people/{personId}/journey

Returns:

Current journey stage
Journey stage history
Transition dates
Transition metadata
Create Journey Transition
POST /organizations/{organizationId}/people/{personId}/journey/transitions

Example request:

{
  "stage_id": "stage_id",
  "note": "Completed follow-up.",
  "occurred_at": "2026-07-10T10:00:00Z"
}

Journey transitions must create immutable journey history records.

Historical journey records must not be overwritten when a person's current stage changes.

Follow-Up Endpoints
List Follow-Ups
GET /organizations/{organizationId}/follow-ups

Supports filters:

status
assigned_user_id
person_id
due_date
Create Follow-Up
POST /organizations/{organizationId}/follow-ups
View Follow-Up
GET /organizations/{organizationId}/follow-ups/{followUpId}
Update Follow-Up
PATCH /organizations/{organizationId}/follow-ups/{followUpId}
Complete Follow-Up
PATCH /organizations/{organizationId}/follow-ups/{followUpId}/complete

Completing a follow-up may create a timeline activity.

Event Endpoints
List Events
GET /organizations/{organizationId}/events

Supports:

Search
Status
Category
Date range
Sorting
Pagination
Create Event
POST /organizations/{organizationId}/events
View Event
GET /organizations/{organizationId}/events/{eventId}
Update Event
PATCH /organizations/{organizationId}/events/{eventId}
Delete Event
DELETE /organizations/{organizationId}/events/{eventId}
Cancel Event
PATCH /organizations/{organizationId}/events/{eventId}/cancel

Cancellation must preserve the event record.

Event Categories
List Categories
GET /organizations/{organizationId}/event-categories
Create Category
POST /organizations/{organizationId}/event-categories
Update Category
PATCH /organizations/{organizationId}/event-categories/{categoryId}
Delete Category
DELETE /organizations/{organizationId}/event-categories/{categoryId}
Event Templates
List Templates
GET /organizations/{organizationId}/event-templates
Create Template
POST /organizations/{organizationId}/event-templates
Update Template
PATCH /organizations/{organizationId}/event-templates/{templateId}
Delete Template
DELETE /organizations/{organizationId}/event-templates/{templateId}
Attendance Endpoints
Event Attendance
GET /organizations/{organizationId}/events/{eventId}/attendance
Record Check-In
POST /organizations/{organizationId}/events/{eventId}/attendance/check-in

Example:

{
  "person_id": "person_id",
  "check_in_method": "manual",
  "checked_in_at": "2026-07-10T09:30:00Z"
}

Supported check-in methods may include:

manual
search
walk_in
offline_sync
Record Walk-In Visitor
POST /organizations/{organizationId}/events/{eventId}/attendance/walk-ins

Creates or links a person and records attendance.

Manual Attendance
POST /organizations/{organizationId}/events/{eventId}/attendance/manual

Supports recording multiple attendance entries.

Example:

{
  "entries": [
    {
      "person_id": "person_id",
      "status": "present"
    },
    {
      "person_id": "person_id",
      "status": "absent"
    }
  ]
}

Attendance statuses:

present
absent
excused
visitor
Person Attendance
GET /organizations/{organizationId}/people/{personId}/attendance
Attendance Summary
GET /organizations/{organizationId}/events/{eventId}/attendance/summary

Returns:

Expected attendance
Checked in
Remaining
Visitors
Attendance rate
Attendance Idempotency

Attendance write endpoints must support idempotency.

Example header:

Idempotency-Key: <unique-key>

Repeated requests using the same idempotency key must not create duplicate attendance records.

The backend must also enforce attendance uniqueness using a database-level constraint on (organization_id, event_id, person_id), matching the approved Database Design.

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
Dashboard Summary
GET /organizations/{organizationId}/reports/dashboard
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
GET /organizations/{organizationId}/events?status=upcoming
GET /organizations/{organizationId}/follow-ups?status=pending

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

Attendance check-in
Manual attendance submission
Invitation acceptance
Announcement sending
Campaign sending
Report export requests

Header:

Idempotency-Key: <unique-key>

The backend must return the original result when the same key is safely retried.

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