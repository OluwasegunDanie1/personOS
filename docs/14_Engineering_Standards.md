---
Document: Engineering Standards
Version: 0.1
Status: Draft
Project: Atlas (Codename)
Owner: Engineering Team
---

# Engineering Standards

## Purpose

This document defines how Atlas should be built.

The goal is to keep the codebase clean, maintainable, and easy for any developer to understand.

---

# Core Principles

- Keep it simple.
- Write readable code.
- Prefer clarity over cleverness.
- Build reusable components.
- Fix the root cause, not the symptom.

---

# Project Structure

Every feature should have its own folder.

Example:

```
features/

├── authentication/
├── dashboard/
├── people/
├── events/
├── attendance/
├── followups/
├── reports/
└── settings/
```

Avoid placing unrelated files together.

---

# Naming Conventions

## Files

Use snake_case.

Examples:

```
people_service.dart

event_repository.dart

attendance_screen.dart
```

---

## Classes

Use PascalCase.

Examples:

```
PeopleRepository

AttendanceService

DashboardController
```

---

## Variables

Use camelCase.

Examples:

```
currentUser

selectedEvent

attendanceList
```

---

## Constants

Use camelCase.

Examples:

```
defaultPageSize

maxUploadSize
```

---

# Folder Rules

Each feature should contain only what it needs.

Example:

```
people/

├── data/
├── models/
├── repository/
├── services/
├── controllers/
├── views/
├── widgets/
└── providers/
```

---

# State Management

Use Riverpod.

Rules:

- Keep providers focused.
- Avoid unnecessary global state.
- Dispose temporary state when appropriate.
- Keep business logic out of widgets.

---

# UI Guidelines

Widgets should:

- Do one thing.
- Be reusable.
- Stay small.

If a widget grows too large, split it.

---

# Business Logic

Never place business logic inside UI widgets.

Instead:

```
UI

↓

Controller / Provider

↓

Repository

↓

API
```

---

# API Layer

All API calls should go through repositories.

Do not call APIs directly from screens.

---

# Error Handling

Handle errors gracefully.

Show users clear messages.

Example:

❌ Something went wrong.

✅ Unable to save this event. Please try again.

---

# Logging

Log important actions.

Examples:

- Login
- Attendance recorded
- Event created
- User invited

Avoid logging sensitive information.

---

# Comments

Write comments only when necessary.

Good code should explain itself.

Avoid comments like:

```dart
// Increment counter
counter++;
```

Instead, use comments to explain decisions.

---

# Code Formatting

Use the project's formatter.

Never commit unformatted code.

---

# Git Workflow

Branch naming:

```
feature/people

feature/events

bugfix/login

hotfix/api-error
```

---

# Commit Messages

Examples:

```
feat: add people management

fix: resolve attendance sync issue

refactor: simplify authentication flow

docs: update PRD

chore: upgrade dependencies
```

---

# Pull Requests

Every pull request should include:

- Summary
- Screenshots (if UI changes)
- Testing notes
- Related issue

---

# Testing

Before merging:

- Code compiles
- No analyzer errors
- Manual testing completed
- Existing features still work

---

# Performance

Avoid:

- Unnecessary rebuilds
- Large widgets
- Duplicate API calls
- Blocking the UI thread

---

# Security

Never:

- Store passwords in plain text
- Hardcode API keys
- Trust client-side validation
- Expose sensitive information in logs

---

# Dependencies

Before adding a package, ask:

- Do we really need it?
- Is it actively maintained?
- Does Flutter already provide this?
- Will it increase app size significantly?

---

# Documentation

Every major feature should include:

- Purpose
- How it works
- Known limitations

---

# Definition of Done

A feature is complete when:

- It works as expected.
- It has been tested.
- It follows the design system.
- It follows coding standards.
- It has no known critical bugs.
- It is documented.

---

# Engineering Values

As a team, we value:

- Simplicity
- Quality
- Consistency
- Reliability
- Continuous improvement

---

# End of Document