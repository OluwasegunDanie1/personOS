# Relvio

> Build stronger relationships.

Relvio is a People Operating System for people-centered organizations.

It helps organizations understand people, coordinate meaningful follow-up, manage core relationship workflows, and support organizational growth through a connected product experience.

---

## Product Context

Relvio is a multi-tenant SaaS product.

Churches and similar organizations are an important initial validation market.

The core product remains organization-neutral.

Relvio must not be hardcoded as a church-only product unless an explicitly approved product requirement requires market-specific behavior.

The public product name is:

**Relvio**

Atlas was an internal early codename.

Do not use Atlas in production UI, customer-facing copy, new implementation naming, or new documentation unless historical context explicitly requires it.

---

## Product Direction

Relvio exists to help people-centered organizations build stronger relationships.

The product focuses on approved people and relationship workflows represented by the frozen Relvio v1 mobile UI and approved product documentation.

Core v1 responsibility areas include:

- Secure product access
- Authorized organization access
- People workflows
- Journey workflows
- Event responsibilities
- Attendance
- Follow-ups
- Approved product insights
- Workspace responsibilities

These responsibility areas do not independently define screens, API endpoints, database tables, fields, routes, or Flutter folders.

The relevant approved documentation controls implementation details.

---

## Approved v1 Platforms

Relvio v1 product platforms are:

- Android
- iOS

The frontend is implemented with Flutter.

This project does not currently approve:

- Web application support
- Desktop application support
- Additional client platforms

Do not create infrastructure for unapproved platforms.

---

## Approved Technology Direction

### Frontend

- Flutter
- Riverpod
- GoRouter

### Backend

- Backend REST API

### Database

- PostgreSQL

API base:

`/api/v1`

Approved architecture:

```text
Flutter
↓
Backend REST API
↓
PostgreSQL