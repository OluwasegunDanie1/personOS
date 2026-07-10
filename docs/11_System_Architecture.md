---
Document: System Architecture
Version: 0.1
Status: Draft
Project: Atlas (Codename)
Owner: Engineering Team
---

# System Architecture

## Purpose

This document describes the technical architecture of Atlas.

The goal is to build a scalable, secure, and maintainable platform that can support thousands of organizations.

---

# Architecture Overview

Atlas follows a modern client-server architecture.

```
Flutter App
        │
        ▼
 REST API / Backend
        │
        ▼
 Business Logic
        │
        ▼
 Database
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
 Web Dashboard          Mobile App
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
- Dio
- Freezed
- Drift / Isar (Offline Support)

---

## Backend

To be finalized.

Possible options:

- Laravel
- NestJS
- ASP.NET Core

The backend should expose REST APIs.

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

Atlas is a multi-tenant platform.

One application.

Many organizations.

```
Atlas

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
```

Use consistent naming throughout.

---

# Security

Every request should verify:

- Authentication
- Organization
- Permissions

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

---

# Performance Goals

- Fast page loads
- Efficient API responses
- Minimal loading screens
- Lazy loading where appropriate

---

# Scalability

The system should support:

- Thousands of organizations
- Millions of people
- Millions of attendance records
- Concurrent users

without major architectural changes.

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