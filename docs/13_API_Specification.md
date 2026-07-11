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

Access tokens are signed JWTs with a 15-minute lifetime.

Refresh tokens are opaque, cryptographically secure random values with a 30-day lifetime. Refresh tokens rotate on every successful refresh. Reuse of an already rotated or revoked refresh token is treated as suspicious and revokes the entire refresh-token family.

Authentication failures must return:

401 Unauthorized

Permission failures must return:

403 Forbidden
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

Logout
POST /auth/logout

Revokes the active refresh-token session.

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

Example error codes:

AUTH_INVALID_CREDENTIALS
AUTH_SESSION_EXPIRED
ORGANIZATION_ACCESS_DENIED
PERMISSION_DENIED
PERSON_NOT_FOUND
PERSON_EMAIL_EXISTS
EVENT_NOT_FOUND
ATTENDANCE_ALREADY_RECORDED
INVITATION_INVALID
INVITATION_EXPIRED
VALIDATION_ERROR
INTERNAL_SERVER_ERROR
Organization Endpoints
List User Organizations
GET /organizations

Returns organizations the authenticated user belongs to.

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
List People
GET /organizations/{organizationId}/people

Supports:

Search
Journey stage filters
Community filters
Sorting
Pagination

Example:

GET /organizations/{organizationId}/people?search=john&journey_stage=visitor
Create Person
POST /organizations/{organizationId}/people
View Person
GET /organizations/{organizationId}/people/{personId}
Update Person
PATCH /organizations/{organizationId}/people/{personId}
Delete Person
DELETE /organizations/{organizationId}/people/{personId}

Deletion must follow the approved soft-delete strategy where applicable.

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