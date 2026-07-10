---
Document: API Specification
Version: 0.1
Status: Draft
Project: Atlas (Codename)
Owner: Engineering Team
---

# API Specification

## Purpose

This document defines how the frontend and backend communicate.

The API should be simple, predictable, secure, and easy to maintain.

---

# API Standards

- Use REST APIs
- Use JSON for requests and responses
- HTTPS only
- Version every API
- Keep endpoints consistent

Base URL

```
/api/v1
```

Example

```
/api/v1/people
```

---

# Authentication

Protected endpoints require an access token.

Example Header

```http
Authorization: Bearer <token>
```

---

# Standard Response

## Success

```json
{
  "success": true,
  "message": "Person created successfully.",
  "data": {}
}
```

---

## Error

```json
{
  "success": false,
  "message": "Email already exists.",
  "errors": {}
}
```

---

# Authentication Endpoints

## Register

```
POST /auth/register
```

---

## Login

```
POST /auth/login
```

---

## Logout

```
POST /auth/logout
```

---

## Forgot Password

```
POST /auth/forgot-password
```

---

## Reset Password

```
POST /auth/reset-password
```

---

## Current User

```
GET /auth/me
```

---

# Organization Endpoints

## Create Organization

```
POST /organizations
```

---

## Get Organization

```
GET /organizations/{id}
```

---

## Update Organization

```
PUT /organizations/{id}
```

---

## Delete Organization

```
DELETE /organizations/{id}
```

---

# People Endpoints

## List People

```
GET /people
```

Supports:

- Search
- Filters
- Pagination

---

## Create Person

```
POST /people
```

---

## View Person

```
GET /people/{id}
```

---

## Update Person

```
PUT /people/{id}
```

---

## Delete Person

```
DELETE /people/{id}
```

---

## Person Timeline

```
GET /people/{id}/timeline
```

---

## Person Journey

```
GET /people/{id}/journey
```

---

# Journey Endpoints

## List Journeys

```
GET /journeys
```

---

## Create Journey

```
POST /journeys
```

---

## Update Journey

```
PUT /journeys/{id}
```

---

## Move Person To Stage

```
POST /journeys/{journeyId}/move
```

---

# Event Endpoints

## List Events

```
GET /events
```

---

## Create Event

```
POST /events
```

---

## View Event

```
GET /events/{id}
```

---

## Update Event

```
PUT /events/{id}
```

---

## Delete Event

```
DELETE /events/{id}
```

---

# Attendance Endpoints

## Record Attendance

```
POST /attendance
```

---

## Event Attendance

```
GET /events/{id}/attendance
```

---

## Person Attendance

```
GET /people/{id}/attendance
```

---

# Follow-up Endpoints

## List Follow-ups

```
GET /follow-ups
```

---

## Create Follow-up

```
POST /follow-ups
```

---

## Update Follow-up

```
PUT /follow-ups/{id}
```

---

## Complete Follow-up

```
PATCH /follow-ups/{id}/complete
```

---

# Report Endpoints

## Dashboard Report

```
GET /reports/dashboard
```

---

## Attendance Report

```
GET /reports/attendance
```

---

## Growth Report

```
GET /reports/growth
```

---

## Follow-up Report

```
GET /reports/followups
```

---

# User Endpoints

## List Users

```
GET /users
```

---

## Invite User

```
POST /users/invite
```

---

## Update User

```
PUT /users/{id}
```

---

## Delete User

```
DELETE /users/{id}
```

---

# Role Endpoints

```
GET /roles
POST /roles
PUT /roles/{id}
DELETE /roles/{id}
```

---

# Notification Endpoints

```
GET /notifications
PATCH /notifications/{id}/read
PATCH /notifications/read-all
```

---

# Search Endpoint

Global search across the application.

```
GET /search?q=john
```

Searches:

- People
- Events
- Users
- Notes

---

# Pagination

Example

```
GET /people?page=1&limit=20
```

Response

```json
{
  "data": [],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 120,
    "last_page": 6
  }
}
```

---

# Filtering

Example

```
GET /people?status=active
```

```
GET /events?category=conference
```

```
GET /attendance?date=2026-07-10
```

---

# Sorting

```
GET /people?sort=first_name
```

```
GET /people?sort=-created_at
```

(-) means descending.

---

# Error Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 204 | Deleted |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 409 | Conflict |
| 422 | Validation Error |
| 500 | Server Error |

---

# Security

Every protected endpoint should:

- Verify authentication
- Verify organization ownership
- Verify user permissions
- Validate request data

Never trust client-side data.

---

# Versioning

Current version:

```
v1
```

Future updates should create:

```
/api/v2
```

instead of breaking existing clients.

---

# Future APIs

Planned for later releases:

- Public API
- Webhooks
- Bulk Import API
- Bulk Export API
- Integration API
- Mobile SDK

---

# Success Criteria

The API should be:

- Easy to understand
- Easy to document
- Consistent
- Secure
- Fast
- Backward compatible

---

# End of Document