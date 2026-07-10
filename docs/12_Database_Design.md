---
Document: Database Design
Version: 0.1
Status: Draft
Project: Atlas (Codename)
Owner: Engineering Team
---

# Database Design

## Purpose

This document defines the core database structure for Atlas.

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
- Every record belongs to an organization.
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

Stores users who can access Atlas.

Fields:

- id
- organization_id
- first_name
- last_name
- email
- password
- phone
- role_id
- status
- last_login
- created_at
- updated_at

---

## Roles

Defines user permissions.

Fields:

- id
- organization_id
- name
- description

Examples:

- Admin
- Staff
- Volunteer
- Viewer

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

The heart of Atlas.

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

---

## Journey Stages

Stores stages inside a journey.

Fields:

- id
- journey_template_id
- name
- order

---

## Person Journey History

Tracks every movement.

Fields:

- id
- person_id
- from_stage
- to_stage
- moved_by
- moved_at
- notes

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

Status:

- Present
- Absent
- Late

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
├── Users
├── Roles
├── People
├── Events
├── Follow-ups
├── Tags
├── Reports
└── Notifications

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

# End of Document