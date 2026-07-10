---
Document: Decision Log
Version: 1.0
Status: Active
Project: Atlas (Codename)
Owner: Product Team
---

# Decision Log

## Purpose

This document records important product and engineering decisions made during the development of Atlas.

The goal is to document **why** a decision was made, not just **what** was decided.

This helps future contributors understand the reasoning behind the product and prevents revisiting the same discussions repeatedly.

---

# Decision Template

Use this format for every new decision.

---

## Decision #

**Date**

YYYY-MM-DD

**Category**

Product / Design / Engineering / Business

**Decision**

...

**Reason**

...

**Alternatives Considered**

- Option A
- Option B
- Option C

**Status**

Approved | Deferred | Rejected | Replaced

---

# Decision 001

**Date**

2026-07-10

**Category**

Product

**Decision**

Atlas will be built as a multi-tenant SaaS platform.

**Reason**

A single platform serving multiple organizations is easier to maintain and scale.

**Alternatives Considered**

- Separate application for every organization
- Self-hosted installations

**Status**

Approved

---

# Decision 002

**Date**

2026-07-10

**Category**

Product

**Decision**

The first target market will be churches.

**Reason**

Churches have a clear need for attendance tracking, follow-ups, and member management, making them an ideal market for validating the product.

**Alternatives Considered**

- Schools
- NGOs
- Businesses

**Status**

Approved

---

# Decision 003

**Date**

2026-07-10

**Category**

Product

**Decision**

Atlas will be designed to support multiple industries from the beginning.

**Reason**

The core problem of managing people and engagement exists across many organizations.

**Alternatives Considered**

- Church-only platform

**Status**

Approved

---

# Decision 004

**Date**

2026-07-10

**Category**

Product

**Decision**

The Journey Engine will be a core feature of the platform.

**Reason**

People move through stages. Atlas should help organizations understand where someone is and what should happen next.

**Alternatives Considered**

- Static member statuses
- Fixed workflows

**Status**

Approved

---

# Decision 005

**Date**

2026-07-10

**Category**

Engineering

**Decision**

Flutter will be used for frontend development.

**Reason**

One codebase for Web, Android, iOS, Windows, macOS, and Linux.

**Alternatives Considered**

- React
- React Native

**Status**

Approved

---

# Decision 006

**Date**

2026-07-10

**Category**

Database

**Decision**

PostgreSQL will be the primary database.

**Reason**

Reliable, scalable, and well suited for relational data.

**Alternatives Considered**

- MySQL
- MongoDB

**Status**

Approved

---

# Decision 007

**Date**

2026-07-10

**Category**

API

**Decision**

The backend will expose REST APIs.

**Reason**

REST is simple, widely supported, and sufficient for the MVP.

**Alternatives Considered**

- GraphQL
- gRPC

**Status**

Approved

---

# Decision 008

**Date**

2026-07-10

**Category**

Business

**Decision**

Atlas will use a subscription-based pricing model.

**Reason**

Recurring revenue supports continuous development and customer support.

**Alternatives Considered**

- One-time purchase
- Lifetime license

**Status**

Approved

---

# Decision 009

**Date**

2026-07-10

**Category**

Product

**Decision**

The MVP will focus on solving core operational problems before adding advanced features.

**Reason**

Shipping early and gathering customer feedback is more valuable than building a large feature set before validation.

**Alternatives Considered**

- Large feature-rich first release

**Status**

Approved

---

# Decision 010

**Date**

2026-07-10

**Category**

Design

**Decision**

Atlas will prioritize simplicity over feature density.

**Reason**

Users should be able to learn the platform quickly with minimal training.

**Alternatives Considered**

- Feature-heavy dashboards
- Complex navigation

**Status**

Approved

---

# Updating Decisions

If a decision changes:

- Do not delete the original entry.
- Create a new decision referencing the previous one.
- Mark the previous decision as "Replaced".

This preserves the history of the project.

---

# End of Document