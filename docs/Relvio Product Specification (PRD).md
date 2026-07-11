---
Document: Project Implementation Brief
Version: 1.1
Status: Approved
Project: Relvio
Owner: Product & Engineering
---

# Project Implementation Brief

## Purpose

This document provides a concise implementation orientation for Relvio.

It helps engineers and AI coding assistants understand the approved product and technical direction before implementation.

This document is a project summary.

It is not:

- A complete product requirements document
- A feature backlog
- An API specification
- A database design
- A screen inventory
- A navigation specification
- A role and permission matrix
- A design token specification
- A dependency manifest
- A deployment specification

Detailed implementation responsibilities remain controlled by the relevant approved Relvio documentation.

If this summary appears to conflict with a specialized approved document, the specialized document controlling that responsibility remains authoritative and the conflict must be reported.

---

# Product Overview

## Product Name

**Relvio**

Atlas was an internal early codename.

Do not use Atlas in production UI, customer-facing product copy, new implementation naming, or new documentation unless historical context explicitly requires it.

---

## Primary Brand Message

> Build stronger relationships.

---

## Product Definition

Relvio is a People Operating System for people-centered organizations.

Relvio helps organizations understand people, strengthen relationships, coordinate meaningful follow-up, and support organizational growth through connected people workflows.

Relvio should not be expanded into a generic organization-management suite merely because an adjacent capability is common in SaaS products.

---

# Vision

Relvio aims to become the operating system for people-centered organizations.

Product expansion must remain deliberate and evidence-driven.

The vision does not automatically approve future features, modules, integrations, infrastructure, or platforms.

`Future Features.md` controls speculative long-term opportunity boundaries.

`Roadmap.md` controls approved delivery sequencing.

`Feature Backlog.md` controls recorded backlog items.

---

# Initial Validation Market

Churches and similar organizations are an important initial validation market for Relvio.

The core product remains organization-neutral.

Relvio architecture, API contracts, database structures, Flutter implementation, and general product language must not hardcode the product as church-only unless an explicitly approved requirement requires market-specific behavior.

Potential use by other people-centered organizations does not mean every organization category is a separately approved target market.

Do not create market-specific modules for:

- Schools
- NGOs
- Businesses
- Associations
- Ministries
- Clubs
- Communities

from this document.

Future market expansion requires product validation and approval.

---

# Approved v1 Product Responsibility Areas

Relvio v1 focuses on the approved people and relationship workflows represented by the frozen mobile UI and approved product documentation.

Core responsibility areas include:

- Secure product access
- Authorized organization access
- People workflows
- Journey workflows
- Event responsibilities
- Attendance
- Follow-ups
- Approved product insights
- Workspace responsibilities

These are product responsibility areas.

They do not independently define:

- Screens
- Routes
- Bottom navigation destinations
- API endpoints
- API fields
- Database tables
- Database columns
- Flutter feature folders

Exact implementation must follow the relevant approved documentation.

`MVP Scope.md` controls the v1 product scope boundary.

---

# Product Scope Protection

Do not infer generic SaaS features from the product definition.

This document does not independently approve:

- Groups
- Event templates
- Announcements
- QR check-in
- Self check-in
- Visitor-specific modules
- Email campaigns
- SMS
- Messaging providers
- Communication campaigns
- Billing
- Integrations
- Public API access
- Export systems
- Custom reporting
- Advanced analytics
- Workflow automation
- AI assistance

A capability must be supported by approved implementation-controlling documentation before it is implemented.

The existence of a capability in an old Relvio or Atlas draft is not approval.

---

# Journey

Journey is an approved Relvio product responsibility.

The exact journey behavior must follow:

- Approved frozen UI
- Approved API specification
- Approved database documentation
- Approved security documentation

Journey transitions must preserve immutable journey history.

Do not implement journey transitions by rewriting or destroying historical transition records.

Do not invent:

- Journey stages
- Stage order
- Automatic transitions
- Drag-and-drop transitions
- Journey scoring
- AI journey recommendations

The backend remains authoritative for protected journey mutations and approved business rules.

---

# Attendance

Attendance is an approved Relvio product responsibility.

Attendance requires backend integrity controls.

Approved attendance write behavior must support idempotency.

Flutter local state must not be treated as proof that an attendance write was committed successfully.

Do not add unapproved attendance methods such as:

- QR check-in
- NFC check-in
- Facial recognition
- Geofenced check-in
- Self check-in

unless separately approved.

Attendance implementation must follow approved API, database, security, and testing documentation.

---

# Roles and Permissions

This document does not define Relvio role names.

Do not invent or automatically implement roles such as:

- Owner
- Administrator
- Manager
- Team Lead
- Volunteer
- Member

unless those exact roles are defined in approved implementation-controlling documentation.

Roles and permissions are backend authorization responsibilities.

The backend REST API must enforce approved authorization rules.

Flutter may present authorized UI.

Flutter is not the authoritative permission layer.

Hiding a Flutter control is not permission enforcement.

Do not confuse a person relationship status with an authenticated organization-user role.

---

# Approved v1 Platforms

Relvio v1 product platforms are:

- Android
- iOS

The frontend is implemented with Flutter.

This document does not approve:

- Web application support
- Desktop application support
- Additional client platforms

Do not create infrastructure for unapproved platforms.

---

# Approved Technical Architecture

The approved Relvio architecture is:

```text
Flutter
↓
Backend REST API
↓
PostgreSQL


API base:

/api/v1

Flutter must never connect directly to PostgreSQL.

The backend REST API is authoritative for protected product operations.

The backend enforces approved responsibilities including:

Authentication
Organization membership
Roles
Permissions
Business rules
Validation
Organization isolation
Protected data mutations

Organization isolation is a critical backend security boundary.

Client-side organization filtering is not tenant security.

Frontend Technology Direction

Approved frontend technologies include:

Flutter
Riverpod
GoRouter

Feature-first architecture is used with controlled data, domain, and presentation boundaries.

Approved conceptual structure:

lib/
├── app/
├── core/
├── shared/
├── features/
└── main.dart

Approved conceptual dependency direction:

Presentation
↓
Domain

Data
↓
Domain

Data
↓
Core API Infrastructure

The domain layer must not depend on the data layer.

Not every feature requires every layer.

Do not create empty architecture folders.

Do not pre-create feature folders from backlog or future-feature documents.

Folder Structure.md controls Flutter project organization.

Firebase Boundary

Firebase is not the approved Relvio backend architecture.

Do not use this document or an old project brief to introduce:

Cloud Firestore
Firebase Authentication
Firebase Storage
Firebase Cloud Messaging
Firebase Crashlytics
Firebase Analytics

These services are not approved merely because they appeared in an earlier draft.

Do not:

Initialize Firebase
Add Firebase configuration files
Create Firestore collections
Connect Flutter to Firestore
Replace backend authentication with Firebase Auth
Add Firebase Storage
Add Firebase Cloud Messaging
Add Firebase Crashlytics
Add Firebase Analytics

without an explicit approved architecture or infrastructure decision.

The current approved architecture remains:

Flutter
↓
Backend REST API
↓
PostgreSQL

A future service integration must preserve the approved architecture and security boundaries unless the architecture is explicitly changed through the approved decision process.

API Client Dependencies

This document does not independently approve a specific Flutter HTTP client package.

Do not install Dio or another networking dependency solely because it appeared in an old project summary.

API infrastructure must follow approved engineering, architecture, and dependency decisions.

The selected client implementation must communicate with the approved backend REST API.

Flutter must not bypass the backend.

Storage

This document does not approve a specific cloud storage provider.

Do not interpret the phrase Cloud Storage as approval for Firebase Storage or another provider.

If implementation requires file or media storage, the approved architecture and infrastructure documentation must define the responsibility.

Do not select a provider automatically.

Push Notifications

Push notification infrastructure is not approved by this document.

Do not install or configure:

Firebase Cloud Messaging
Another push provider
Notification backend infrastructure

unless approved product and technical documentation requires push notifications.

The presence of a notification UI concept does not automatically approve remote push delivery infrastructure.

Crash Reporting and Analytics

No crash-reporting or product-analytics provider is approved by this document.

Do not install:

Firebase Crashlytics
Firebase Analytics
Another crash-reporting SDK
Another analytics SDK

solely because production applications commonly use them.

Provider selection requires an approved implementation requirement.

Conditional observability responsibilities remain governed by approved engineering, deployment, and release documentation.

Design Direction

The Relvio v1 mobile UI is complete, approved, and frozen.

Do not redesign approved screens.

Approved high-fidelity UI references are the visual authority.

Primary brand color:

#2563FF

Primary application background:

#FCFCFD

Typeface:

Inter

Primary brand message:

Build stronger relationships.

The approved UI may have been informed by high-quality modern product design principles.

References to companies or products used during early inspiration do not authorize implementation teams to copy, combine, or redesign Relvio using another product's current UI.

The approved Relvio UI is the implementation target.

Navigation

The approved frozen Relvio UI controls visible navigation.

The final approved primary bottom navigation label is:

Workspace

Do not use:

More

as the primary navigation destination name.

This document does not define a linear application navigation flow.

Do not interpret product responsibility areas as:

Dashboard
↓
People
↓
Events
↓
Attendance
↓
Messages
↓
Workspace

or any other mandatory sequential navigation architecture.

Routes and navigation behavior must follow approved UI and routing documentation.

Do not invent navigation destinations.

Theme Direction

Relvio v1 uses the approved light theme.

Dark mode is not approved for v1.

System theme switching is not approved.

Do not add:

Theme toggle
Appearance-based theme switching
Riverpod theme state
Dark theme infrastructure
Organization-controlled application themes
White-label theme infrastructure

Flutter Theme Implementation.md controls Flutter theme implementation boundaries.

Brand Assets

The Relvio brand identity and logo are approved.

The approved logo is the custom Relvio R inside a connected orbital system with relationship nodes and intentional orbital breaks.

Approved logo assets must be used directly.

Do not:

Redesign the logo
Recreate the logo from screenshots
Approximate the logo with generic icons
Recreate the logo using Flutter drawing code
Generate replacement logo assets

Missing approved brand assets must be reported.

Do not invent replacements.

Implementation Goal

Build the approved Relvio v1 Android and iOS application as a secure, reliable, maintainable, and visually faithful product.

Implementation should protect:

Approved product scope
Organization isolation
Backend authority
Data integrity
Attendance idempotency
Immutable journey history
Maintainability
Reliability
Performance
Frozen UI fidelity
Controlled consistency

The phrase enterprise-grade must not be used as justification for speculative abstraction or unrelated infrastructure.

Architecture should follow real responsibility.

Do not create complexity for hypothetical future requirements.

AI Implementation Rules

Claude or another AI coding assistant acts as an implementation engineer.

AI must not use old project summaries to invent or restore:

Firebase architecture
Firestore
Firebase Authentication
Firebase Storage
Firebase Cloud Messaging
Firebase Crashlytics
Firebase Analytics
Messages modules
QR check-in
Email campaigns
Billing
Integrations
Role names
Journey stages
Reports
API endpoints
API fields
Database structures
Navigation destinations
Flutter feature folders

AI must not select infrastructure because it is common in Flutter applications.

AI must follow approved Relvio documentation.

When required implementation information is missing or contradictory, AI must report the gap.

Do not invent the missing decision.

Documentation Authority

This document provides project orientation only.

Important implementation authorities include:

MVP Scope.md for the Relvio v1 product scope boundary
13_API_Specification.md for REST API contracts
Approved database documentation for PostgreSQL structures
16_Security.md for security responsibilities
Approved architecture documentation for technical boundaries
Folder Structure.md for Flutter project organization
High-Fidelity Screens.md for frozen UI interpretation
Design Tokens.md for approved design token definitions
Color System.md for approved color responsibilities
Component Library.md for shared component responsibilities
Flutter Theme Implementation.md for Flutter theme boundaries
Asset_Structure.md for production asset organization
Brand Assets.md for approved brand assets
Feature Backlog.md for recorded backlog items
Roadmap.md for approved delivery sequencing
Future Features.md for speculative future opportunity boundaries

A summary document must not override a specialized approved document.

If a conflict is discovered, report it before implementation.

Current Project Stage

Relvio is completing the existing MD documentation audit before Flutter coding begins.

The following directions are already established:

Relvio product direction
Approved architecture
Multi-tenant backend security boundary
PostgreSQL database direction
REST API direction
Android and iOS v1 platform scope
Brand identity
Approved logo
Frozen Relvio v1 mobile UI

Do not restart the project.

Do not redesign Relvio.

Do not create a new architecture.

Do not begin speculative future infrastructure.

The current responsibility is documentation alignment.

Success Criteria

This implementation brief is successful when:

Relvio is clearly identified as the public product.
The core product remains organization-neutral.
Churches and similar organizations remain an initial validation market.
The approved REST API and PostgreSQL architecture remain protected.
Firebase cannot be reintroduced from old documentation.
Product modules are not invented from an old feature list.
Role names are not invented.
QR check-in is not accidentally added to v1.
The frozen Relvio UI remains authoritative.
Android and iOS remain the approved v1 platforms.
AI coding assistants use specialized approved documents for implementation details.
Missing or contradictory decisions are reported instead of guessed.