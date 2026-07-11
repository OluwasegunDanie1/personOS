---
Document: Product Requirements Document (PRD)
Version: 0.1
Status: Draft
Project: Atlas (Codename)
Owner: Product Team
---

# Product Requirements Document (PRD)

## Purpose

This document defines the functional requirements for the MVP.

It answers one question:

> **What exactly are we building?**

---

# Product Overview

Atlas is a multi-tenant SaaS platform that helps organizations manage:

- People
- Events
- Attendance
- Follow-ups
- Communication
- Reports

---

# MVP Scope

The first release will include:

- Authentication
- Organization Setup
- Dashboard
- People
- Journey Engine
- Events
- Attendance
- Follow-up
- Reports
- Roles & Permissions

---

# User Roles

Approved roles are governed by `16_Security.md`.

## Owner

Manages the organization workspace.

Can:

- Invite users
- Manage settings
- Create events
- Manage members
- View reports

---

## Administrator

Manages an organization.

Can:

- Invite users
- Manage settings
- Create events
- Manage members
- View reports

---

## Manager

Oversees assigned teams and operations.

Example:

- Record attendance
- Follow up visitors
- View assigned reports

---

## Team Lead

Can perform assigned tasks.

Example:

- Record attendance
- Follow up visitors
- View assigned reports

---

## Volunteer

Limited access.

Permissions depend on role.

---

## Member

Baseline organization member access.

Permissions depend on role.

---

# Epic 1 — Authentication

## Goal

Allow users to securely access Atlas.

### Features

- Register
- Login
- Forgot Password
- Reset Password
- Logout
- Email Verification

### Acceptance Criteria

- User can register.
- User receives verification email.
- User can login.
- Invalid credentials return errors.
- Password reset works.

---

# Epic 2 — Organization Setup

## Goal

Allow organizations to create their workspace.

### Features

- Organization Name
- Logo
- Address
- Industry
- Time Zone
- Country

### Acceptance Criteria

- Organization created successfully.
- The creating user becomes the organization Owner.

---

# Epic 3 — Dashboard

## Goal

Show important information immediately after login.

### Dashboard Cards

- Total People
- New People
- Events This Week
- Attendance Today
- Pending Follow-ups
- Recent Activities

---

# Epic 4 — People Management

## Features

- Add Person
- Edit Person
- Delete Person
- Search
- Filter
- Tags
- Notes
- Custom Fields

### Person Profile

Contains:

- Personal Details
- Contact Information
- Journey
- Attendance History
- Follow-up History
- Notes
- Assigned Worker

---

# Epic 5 — Journey Engine

Every person belongs to a journey.

Example:

Visitor

↓

First Visit

↓

Welcome Call

↓

Membership Class

↓

Member

↓

Volunteer

↓

Leader

### Features

- Create Journey
- Edit Journey
- Move Person
- View Progress

---

# Epic 6 — Events

### Features

- Create Event
- Edit Event
- Delete Event
- Event Categories
- Attendance Enabled

---

# Epic 7 — Attendance

### Methods

- Manual Check-in

### Features

- Mark Present
- Mark Absent
- Search Person
- Attendance History

---

# Epic 8 — Follow-up

### Features

- Assign Follow-up
- Due Date
- Reminder
- Status
- Notes

Statuses

- Pending
- In Progress
- Completed

---

# Epic 9 — Reports

Reports include:

- Attendance
- Growth
- Follow-up
- New People
- Journey Progress

Export:

- PDF
- Excel
- CSV

---

# Notifications

Users receive notifications for:

- Assigned Follow-up
- Upcoming Events
- Missed Tasks
- Organization Announcements

---

# Search

Global Search should find:

- People
- Events
- Tasks
- Notes

---

# Settings

Organization Settings

- Profile
- Branding
- Roles
- Permissions
- Billing
- Subscription

---

# Non-Functional Requirements

## Performance

- Dashboard loads under 2 seconds.
- Search results under 500ms.

---

## Security

- Encrypted passwords
- Secure authentication
- Role-based permissions
- Audit logs

---

## Scalability

Support:

- Multiple organizations
- Thousands of users
- Millions of records

---

## Accessibility

- Keyboard navigation
- Responsive UI
- High contrast support

---

# MVP Checklist

- [ ] Authentication
- [ ] Organization Setup
- [ ] Dashboard
- [ ] People
- [ ] Journey Engine
- [ ] Events
- [ ] Attendance
- [ ] Follow-up
- [ ] Reports
- [ ] Settings
- [ ] Roles & Permissions

---

# Success Criteria

The MVP is complete when a new organization can:

1. Create an account.
2. Create their organization.
3. Add people.
4. Create an event.
5. Record attendance.
6. Assign follow-ups.
7. View reports.
8. Invite team members.

without needing any external tool.

---

# End of Document