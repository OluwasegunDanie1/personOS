---
Document: System Architecture
Version: 0.1
Status: Approved
Project: Relvio
Owner: Engineering Team
---

# System Architecture

## Purpose

This document describes the technical architecture of Relvio.

The goal is to build a scalable, secure, and maintainable platform that can support thousands of organizations.

---

# Architecture Overview

Relvio follows a modern client-server architecture.

```
Flutter Mobile App
        │
        ▼
 REST API
        │
        ▼
 Application Layer
        │
        ▼
 Domain Layer
        │
        ▼
 Infrastructure Layer
        │
        ▼
 PostgreSQL + Object Storage
```

Every layer has a single responsibility.

---

# Architecture Principles

- Keep it simple
- Build for scale
- Write reusable code
- Separate concerns
- Secure by default
- Optimize for maintainability

---

# High-Level Architecture

```
                Users
                  │
     ┌────────────┴────────────┐
     │                         │
 Future Web Dashboard          Mobile App
     │                         │
     └────────────┬────────────┘
                  │
             Backend API
                  │
      ┌───────────┼───────────┐
      │           │           │
 Authentication Business   Notifications
      │           │           │
      └───────────┼───────────┘
                  │
              PostgreSQL
```

---

# Technology Stack

## Frontend

- Flutter
- Riverpod
- GoRouter
- Dio (approved Flutter HTTP client)
- Freezed
- Isar (Offline Database)
- SharedPreferences / Secure Storage

---

## Backend

Backend architecture follows REST principles and a layered architecture (Presentation, Application, Domain, Infrastructure).

The approved backend implementation technology is:

- NestJS

The backend should expose REST APIs.

### Approved Backend Authentication Packages

- @nestjs/jwt for access-token signing and verification
- argon2 for password hashing
- class-validator and class-transformer for request DTO validation

Token hashing and opaque token generation use Node's built-in `crypto` module only; no additional package is approved for that responsibility.

---

## Mobile Client Configuration

The approved Flutter API base-URL configuration strategy is compile-time environment configuration using `--dart-define`.

Configuration key:

```
API_BASE_URL
```

Production API URLs must not be hardcoded in Dart source.

### HTTP Timeout Policy

- Connection timeout: 30 seconds
- Receive timeout: 30 seconds

### HTTP Retry Policy

- No automatic retries for mutation requests (POST, PUT, PATCH, DELETE).
- Safe/idempotent GET requests may retry a maximum of 2 times.
- Retry only transient network failures.
- Do not retry authentication failures.
- Do not retry validation failures.
- Do not retry permission failures.
- Do not retry deterministic 4xx responses.

---

## Database

PostgreSQL

Reason:

- Reliable
- Fast
- Scalable
- Excellent relational support

---

## Storage

Cloud Storage

Used for:

- Logos
- Images
- Documents
- Attachments

---

## Authentication

Support:

- Email & Password
- Google Login (Future)
- Microsoft Login (Future)

---

# Multi-Tenant Architecture


Relvio is a multi-tenant platform.

One application.

Many organizations.
Every record must include an organization identifier (organization_id).

All database queries must be scoped to the authenticated organization.

```
Relvio

├── Church A
├── School B
├── NGO C
├── Company D
└── Community E
```

Each organization only accesses its own data.

---

# Core Modules

- Authentication
- Organizations
- People
- Journey Engine
- Events
- Attendance
- Follow-ups
- Reports
- Notifications
- Billing

Each module should remain independent.

---

# API Structure

```
/auth

/organizations

/people

/events

/attendance

/follow-ups

/reports

/settings

/users

/api/v1/auth
/api/v1/people
/api/v1/events
...
```

Use consistent naming throughout.

---

# Security

Every request should verify:

- Authentication
- Organization
- Permissions
- Authorization must use Role-Based Access Control (RBAC).

Users must never access another organization's data.

---

# Caching

Cache frequently accessed data.

Examples:

- User profile
- Organization settings
- Permissions

Reduce unnecessary API calls.

---

# Offline Support

The mobile app should continue working with limited internet access.

Examples:

- View people
- Record attendance
- Save notes

Changes should sync automatically when the connection returns.

Offline changes shall be stored locally and synchronized using a background sync queue when connectivity is restored.

---

# Notifications

Support:

- In-app notifications
- Push notifications
- Email (Future)
- WhatsApp (Future)

---

# Error Handling

Every API should return consistent responses.

Example:

```json
{
  "success": false,
  "message": "Email already exists."
}
```

Avoid exposing technical errors to users.

---

# Logging

Log important activities.

Examples:

- Login
- User creation
- Attendance updates
- Deleted records
- Permission changes
- Logs should include timestamps and user identifiers where applicable.

---

# Performance Goals

- Fast page loads
- Efficient API responses
- Minimal loading screens
- Lazy loading where appropriate
- - Pagination for large datasets
- Server-side filtering and search

---

# Scalability

The system should support:

- Thousands of organizations
- Millions of people
- Millions of attendance records
- Concurrent users

without major architectural changes.
The architecture should allow horizontal backend scaling without requiring client-side changes.

---

# Future Considerations

- Microservices (if needed)
- GraphQL API
- Public API
- Webhooks
- Third-party integrations
- AI services

These are not part of the MVP.

---

# Success Criteria

A successful architecture should be:

- Easy to understand
- Easy to maintain
- Secure
- Fast
- Scalable

---

# End of Document