---
Document: User Flow
Version: 1.0
Status: Draft
Project: Atlas (Codename)
Owner: Design Team
---

# User Flow

## Purpose

This document defines how users move through Atlas to accomplish their tasks.

Every flow should be:

- Simple
- Predictable
- Efficient
- Consistent

The goal is to reduce friction and help users complete tasks with minimal effort.

---

# Design Principles

Every user flow should:

- Minimize clicks
- Reduce decision fatigue
- Provide clear feedback
- Prevent mistakes
- Support recovery from errors

---

# Primary User Journey

```text
Landing Page

↓

Sign Up

↓

Create Organization

↓

Email Verification

↓

Complete Setup

↓

Dashboard
```

---

# Authentication Flow

```text
Open App

↓

Login

↓

Authentication

↓

Dashboard
```

If authentication fails:

```text
Login

↓

Error Message

↓

Retry
```

---

# Forgot Password Flow

```text
Forgot Password

↓

Enter Email

↓

Verification Email

↓

Reset Password

↓

Login
```

---

# Organization Setup Flow

```text
Create Organization

↓

Organization Details

↓

Upload Logo

↓

Invite Team Members

↓

Complete Setup

↓

Dashboard
```

Users may skip inviting team members and complete it later.

---

# Invite Team Member Flow

```text
Dashboard

↓

Team Members

↓

Invite User

↓

Enter Details

↓

Assign Role

↓

Send Invitation
```

---

# Add Person Flow

```text
Dashboard

↓

People

↓

Add Person

↓

Fill Form

↓

Save

↓

Person Profile
```

---

# Edit Person Flow

```text
People

↓

Open Profile

↓

Edit

↓

Save

↓

Updated Profile
```

---

# Journey Flow

```text
Person Profile

↓

Journey

↓

Move Stage

↓

Confirmation

↓

Timeline Updated
```

Example:

```text
Visitor

↓

First Visit

↓

Follow-up

↓

Member

↓

Volunteer

↓

Leader
```

---

# Event Creation Flow

```text
Dashboard

↓

Events

↓

Create Event

↓

Fill Details

↓

Publish

↓

Event Details
```

---

# Attendance Flow

```text
Open Event

↓

Attendance

↓

Search Person

↓

Mark Present

↓

Confirmation

↓

Attendance Updated
```

Future:

```text
Scan QR Code

↓

Automatic Check-in

↓

Success
```

---

# Follow-up Flow

```text
Person Profile

↓

Create Follow-up

↓

Assign Staff

↓

Choose Due Date

↓

Save

↓

Notification Sent
```

---

# Complete Follow-up Flow

```text
Pending Task

↓

Open Follow-up

↓

Complete

↓

Timeline Updated
```

---

# Report Flow

```text
Dashboard

↓

Reports

↓

Choose Report

↓

Apply Filters

↓

View Results

↓

Export
```

---

# Notification Flow

```text
Notification

↓

Open

↓

View Details

↓

Take Action
```

---

# Settings Flow

```text
Settings

↓

Choose Category

↓

Update

↓

Save

↓

Confirmation
```

---

# Search Flow

Global Search

↓

Results

↓

Select Record

↓

Open Details

Search should support:

- People
- Events
- Follow-ups
- Users

---

# Error Recovery Flow

```text
Action

↓

Error

↓

Helpful Message

↓

Retry
```

Users should never reach a dead end.

---

# Empty State Flow

If a module contains no data:

```text
Empty State

↓

Explanation

↓

Primary Action

↓

Create First Record
```

Example:

"No events yet."

↓

Create Event

---

# Permission Flow

If a user lacks permission:

```text
Restricted Action

↓

Permission Check

↓

Access Denied

↓

Return
```

Explain why access is restricted.

---

# Mobile Navigation Flow

```text
Bottom Navigation

↓

Module

↓

Screen

↓

Details

↓

Back
```

Navigation depth should remain shallow.

---

# Desktop Navigation Flow

```text
Sidebar

↓

Module

↓

List

↓

Details
```

The sidebar should remain visible whenever possible.

---

# Success Feedback

Every completed action should provide feedback.

Examples:

- Person created
- Event updated
- Attendance recorded
- Follow-up completed

Feedback should disappear automatically after a short time.

---

# Flow Principles

Every flow should:

- Require the fewest steps possible.
- Keep users informed.
- Avoid unnecessary confirmations.
- Prevent accidental data loss.
- Feel fast and intuitive.

---

# Deliverables

Before UI design begins, complete user flows for:

- Authentication
- Organization Setup
- Dashboard
- People
- Journey Management
- Events
- Attendance
- Follow-ups
- Reports
- Notifications
- Settings

---

# Success Criteria

User flows are successful when:

- Users can complete tasks without guidance.
- Navigation feels natural.
- Errors are recoverable.
- Workflows are consistent across the platform.

---

# End of Document