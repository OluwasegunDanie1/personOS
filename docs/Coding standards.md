---
Document: Coding Standards
Version: 1.0
Status: Draft
Project: Atlas (Codename)
Owner: Engineering Team
---

# Coding Standards

## Purpose

This document defines the coding conventions used throughout Atlas.

The goal is to keep the codebase clean, readable, predictable, and easy to maintain as the project grows.

---

# Core Principles

Every piece of code should be:

- Simple
- Readable
- Reusable
- Testable
- Maintainable

Code is read far more often than it is written.

Optimize for readability.

---

# General Rules

- Write self-explanatory code.
- Avoid unnecessary complexity.
- Prefer composition over inheritance.
- Keep methods small.
- Keep widgets focused.
- Remove dead code immediately.

---

# Naming Conventions

## Variables

Use **camelCase**.

```dart
final currentUser;
final selectedPerson;
final attendanceCount;
```

---

## Classes

Use **PascalCase**.

```dart
PeopleRepository

AttendanceService

DashboardController
```

---

## Files

Use **snake_case**.

```text
people_repository.dart

dashboard_screen.dart

attendance_service.dart
```

---

## Folders

Use **snake_case**.

```text
people/

attendance/

dashboard/
```

---

## Enums

Use **PascalCase**.

```dart
AttendanceStatus

UserRole
```

---

## Extensions

Suffix with **Extension**.

```dart
StringExtension

DateTimeExtension
```

---

# Widget Guidelines

Widgets should have a single responsibility.

Good

```text
AttendanceCard
```

Bad

```text
AttendanceCardWithButtonsAndCharts
```

If a widget exceeds roughly 200 lines, consider splitting it into smaller widgets.

---

# Screen Guidelines

Each screen should:

- Load data
- Display data
- Delegate business logic

Avoid placing business logic inside UI code.

---

# State Management

Atlas uses **Riverpod**.

Rules:

- One provider, one responsibility.
- Keep providers focused.
- Avoid global mutable state.
- Dispose temporary providers when appropriate.

---

# Business Logic

Business logic belongs in:

- Use Cases
- Services
- Repositories

Never inside widgets.

---

# Repository Pattern

All external data access should go through repositories.

Example

```text
UI

↓

Controller

↓

Repository

↓

API
```

Do not call APIs directly from the presentation layer.

---

# Models

Models should represent data only.

Avoid placing business logic inside models.

---

# Functions

Functions should:

- Do one thing
- Have descriptive names
- Return predictable results

Prefer early returns over deep nesting.

---

# Error Handling

Handle errors explicitly.

Instead of:

```dart
catch (e) {}
```

Use:

```dart
catch (e, stackTrace) {
  logger.error(e, stackTrace);
}
```

Never ignore exceptions.

---

# Logging

Log meaningful events.

Examples:

- Login
- Logout
- API failures
- Data synchronization
- Permission changes

Never log:

- Passwords
- Tokens
- Sensitive user data

---

# Comments

Only write comments that explain **why**, not **what**.

Good

```dart
// Retry because the API occasionally returns temporary failures.
```

Bad

```dart
// Increment counter.
counter++;
```

---

# Constants

Avoid magic numbers.

Bad

```dart
if (value > 5)
```

Good

```dart
const maxRetryAttempts = 5;
```

---

# Null Safety

Always embrace Dart's null safety.

Avoid unnecessary `!`.

Prefer:

- Nullable types
- Guards
- Default values

---

# Imports

Order imports consistently.

1. Dart SDK
2. Flutter
3. Third-party packages
4. Internal packages
5. Relative imports

Remove unused imports before committing.

---

# Async Code

Prefer:

```dart
async / await
```

Avoid deeply nested `.then()` chains.

---

# API Calls

Every API call should:

- Handle loading
- Handle success
- Handle failure
- Handle timeout

Never assume success.

---

# Performance

Avoid:

- Large rebuilds
- Heavy synchronous work on the UI thread
- Duplicate network requests
- Unnecessary object creation

Profile before optimizing.

---

# Security

Never:

- Hardcode secrets
- Commit `.env` files
- Store passwords locally
- Trust client-side validation

---

# Git Standards

Branch names

```text
feature/dashboard

feature/attendance

bugfix/login

refactor/navigation
```

---

Commit messages

```text
feat: add attendance history

fix: resolve login issue

refactor: simplify dashboard layout

docs: update architecture

test: add people repository tests
```

---

# Code Reviews

Every pull request should verify:

- Readability
- Simplicity
- Performance
- Security
- Test coverage
- Documentation

Reject code that does not meet the standards.

---

# Definition of Good Code

Good code should answer these questions without additional explanation:

- What does it do?
- Why does it exist?
- Where does it belong?
- Can it be reused?
- Can it be tested?

If the answer is "No", improve the implementation.

---

# Engineering Philosophy

Write code that your future self—and every future teammate—will enjoy maintaining.

Clean code is a competitive advantage.

---

# End of Document