---
Document: Database Design
Version: 0.1
Status: Approved
Project: Relvio
Owner: Engineering Team
---

# Database Design

## Purpose

This document defines the core database structure for Relvio.

The database should be simple, scalable, and support multiple organizations without mixing data.

---

# Database Engine

**PostgreSQL**

Reason:

- Reliable
- Fast
- Excellent relational support
- Scales well
- Open source

---

# Design Principles

- Normalize data where appropriate.
- Avoid duplicate information.
- Every organization-owned record belongs to an organization.
- Users are a global identity linked to organizations through Organization Memberships.
- Use UUIDs as primary keys.
- Never hard delete important records.
- Track creation and update dates.

---

# Core Tables

## Organizations

Stores organization information.

Fields:

- id
- name
- slug
- industry
- logo
- email
- phone
- address
- country
- timezone
- subscription_plan
- created_at
- updated_at

---

## Users

Stores global user identities who can access Relvio.

A user is not owned by a single organization. A user may belong to multiple organizations through Organization Memberships.

Fields:

- id
- first_name
- last_name
- email
- password_hash
- phone
- status
- last_login
- created_at
- updated_at

status is a closed v1 value set: ACTIVE, DISABLED. Disabled users cannot authenticate or refresh authentication.

---

## Refresh Tokens

Supports refresh-token-based session renewal.

Raw refresh tokens are never stored. Only the cryptographic hash of the token is stored.

Fields:

- id
- user_id
- token_hash
- family_id
- expires_at
- revoked_at
- created_at

family_id supports revoking an entire refresh-token family after confirmed token reuse. revoked_at represents refresh-token revocation, including rotation and reuse-triggered family revocation.

---

## Email Verification Tokens

Supports single-use email verification.

Raw verification tokens are never stored. Only the cryptographic hash of the token is stored.

Fields:

- id
- user_id
- token_hash
- expires_at
- used_at
- created_at

used_at represents single-use token consumption. Verification tokens expire 24 hours after creation.

---

## Password Reset Tokens

Supports single-use password reset.

Raw reset tokens are never stored. Only the cryptographic hash of the token is stored.

Fields:

- id
- user_id
- token_hash
- expires_at
- used_at
- created_at

used_at represents single-use token consumption. Password reset tokens expire 1 hour after creation.

---

## Roles

Defines user permissions.

Roles remain organization-owned.

Fields:

- id
- organization_id
- name
- description

Examples:

- Owner
- Administrator
- Manager
- Team Lead
- Volunteer
- Member

---

## Organization Memberships

Represents one User's membership in one Organization.

A User may belong to multiple Organizations through separate Organization Membership records. A User may have only one membership record per Organization.

Fields:

- id
- organization_id
- user_id
- role_id
- created_at

Unique constraint: (organization_id, user_id).

Role assignment is scoped to the membership, not to the User directly. A membership's role_id must reference a Role owned by the same organization_id as the membership. The database schema should structurally enforce this same-organization membership-to-role linkage where supported by the persistence/database constraint model.

---

## Role Permissions

Fields:

- role_id
- permission_id
---

## Permissions

Stores available system permissions.

Examples:

- View People
- Edit People
- Delete People
- Create Events
- Manage Reports

---

## People

The heart of Relvio.

Stores everyone managed by the organization.

Fields:

- id
- organization_id
- first_name
- last_name
- gender
- date_of_birth
- phone
- email
- address
- occupation
- profile_photo
- current_journey_stage_id
- assigned_user_id
- status
- created_at
- updated_at

status is stored as a plain string column. The closed v1 API allowlist for this value is ACTIVE or INACTIVE, defined by 13_API_Specification.md; this is an API-level constraint, not a Prisma enum change.

current_journey_stage_id is a dormant column for v1: it is not the source of truth for a Person's current journey stage, must not be required to stay synchronized, and must not be exposed in v1 API responses. The authoritative current stage is always derived from the latest Person Journey History row (see below). There is no journey_template_id column on People; a Person never belongs to a JourneyTemplate directly, only through PersonJourneyHistory.

---

## Tags

Examples:

- Visitor
- VIP
- Worker
- Student
- New Member

Fields:

- id
- organization_id
- name
- color

---

## Person Tags

Links people to tags.

Fields:

- person_id
- tag_id

(person_id, tag_id)

---

## Journey Templates

Stores journey definitions.

Example:

Visitor

↓

First Visit

↓

Member

↓

Volunteer

---

Fields:

- id
- organization_id
- name
- description

There is no is_default or similar flag column. For Relvio v1, application behavior treats exactly one JourneyTemplate row per organization_id as the single operational template; this is an application-level invariant, not a schema-enforced constraint. The schema permitting multiple rows per organization does not authorize v1 application behavior to create or expose more than one. JourneyTemplate is internal application infrastructure in v1: it is not exposed as a standalone user-facing API resource, and there is no v1 create/update/delete/list endpoint for it. Full v1 authority is defined in 13_API_Specification.md and 16_Security.md.

---

## Journey Stages

Stores stages inside a journey.

Fields:

- id
- journey_template_id
- name
- order

There is no description column. The API exposes the order field under the response key position; order and position refer to the same column. Any future description requirement is a schema decision outside existing authority.

---

## Person Journey History

Tracks every movement.

Fields:

- id
- person_id
- from_stage_id
- to_stage_id
- moved_by
- moved_at
- notes

The API exposes the notes field under the response key note; notes and note refer to the same column. moved_at (not changed_at) is the approved ordering field for determining a Person's current journey stage: the latest row by moved_at descending, then id descending.

---

## Events

Fields:

- id
- organization_id
- title
- description
- category
- venue
- start_date
- end_date
- created_by

---

## Attendance

Fields:

- id
- event_id
- person_id
- status
- checked_in_by
- checked_in_at
- organization_id
Status:

- Present
- Absent
- Late

Unique constraint: (organization_id, event_id, person_id).

This is the database-level attendance idempotency / duplicate-prevention boundary. A given person may have only one attendance record per event within an organization.

---

## Follow-ups

Fields:

- id
- organization_id
- person_id
- assigned_to
- title
- description
- due_date
- status
- completed_at

---

## Notes

Stores notes about people.

Fields:

- id
- person_id
- user_id
- note
- created_at
- organization_id

---

## Reports

Stores generated reports.

Fields:

- id
- organization_id
- report_name
- generated_by
- generated_at

---

## Notifications

Fields:

- id
- organization_id
- user_id
- title
- message
- is_read
- created_at

---

## Audit Logs

Stores important system activities.

Examples:

- User Login
- Attendance Recorded
- Person Updated
- Event Deleted

Fields:

- id
- organization_id
- user_id
- action
- entity
- entity_id
- created_at

---

# Relationships

```
Organization
│
├── Organization Memberships
├── Roles
├── People
├── Events
├── Follow-ups
├── Tags
├── Reports
└── Notifications

User
│
├── Organization Memberships
├── Refresh Tokens
├── Email Verification Tokens
└── Password Reset Tokens

Role
│
└── Organization Memberships

People
│
├── Attendance
├── Notes
├── Journey History
└── Follow-ups

Events
│
└── Attendance
```

---

# Naming Conventions

- Table names use plural nouns.
- Columns use snake_case.
- Primary key: id
- Foreign keys: table_name_id

Example:

organization_id

person_id

event_id

---

# Soft Deletes

Important tables should support soft deletes.

Examples:

- People
- Events
- Users
deleted_at TIMESTAMP NULL

This prevents accidental data loss.

---

# Indexes

Create indexes for:

- organization_id
- email
- phone
- event_id
- person_id
- created_at
- user_id and token_hash (Refresh Tokens, Email Verification Tokens, Password Reset Tokens)
(organization_id, user_id)

(organization_id, event_id, person_id)

(organization_id, person_id)

(organization_id, event_id)

(organization_id, created_at)

This improves query performance.


---

# Future Tables

These are not required for MVP.

- Automations
- Workflows
- Messages
- Forms
- Integrations
- API Keys
- Billing
- Payments
- Branches

---

# Success Criteria

The database should:

- Scale easily
- Prevent duplicate data
- Support multiple organizations
- Maintain data integrity
- Be easy to extend

---

# Constraints

- Email should be unique globally across Users.
- Slug should be globally unique.
- Foreign keys must enforce referential integrity.
- Required fields should use NOT NULL.
- Organization Membership must be unique per (organization_id, user_id).
- Attendance must be unique per (organization_id, event_id, person_id). This is the database-level attendance idempotency / duplicate-prevention boundary.
- token_hash must be unique within Refresh Tokens, within Email Verification Tokens, and within Password Reset Tokens.

UUID v4 should be used for all primary keys.
# End of Document