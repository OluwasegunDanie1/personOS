---
Document: Decision Log
Version: 1.1
Status: Active
Project: Atlas (Codename) / Relvio
Owner: Product Team
---

# Decision Log

## Purpose

This document records significant product, design, engineering, architecture, and business decisions made during the development of Relvio.

The goal is to document why a decision was made, not only what was decided.

This helps future contributors and AI coding assistants understand the reasoning behind the product and prevents previously resolved decisions from being repeatedly reopened without new evidence.

The Decision Log is historical.

Approved decisions must not be silently deleted or rewritten when direction changes.

---

# Decision Status

Every decision must use one of the following statuses:

```text
Approved
Deferred
Rejected
Replaced


Approved

The decision is currently active.

Deferred

The decision may be reconsidered later.

Rejected

The decision was considered and intentionally not selected.

Replaced

A newer decision supersedes the decision.

When a decision is replaced, the original entry must remain in this document.

Decision Template

Use this format for every significant new decision.

Decision XXX

Date

YYYY-MM-DD

Category

Product / Design / Engineering / Architecture / Database / API / Security / Business

Decision

Describe the decision.

Reason

Explain why the decision was made.

Alternatives Considered

Option A
Option B
Option C

Related Decisions

Decision XXX

Status

Approved | Deferred | Rejected | Replaced

Decision 001

Date

2026-07-10

Category

Product

Decision

Atlas will be built as a multi-tenant SaaS platform.

Reason

A single platform serving multiple organizations is easier to maintain, operate, and scale than separate deployments for every organization.

The platform must preserve strict organization data isolation.

Alternatives Considered

Separate application for every organization
Self-hosted installations

Related Decisions

Decision 003
Decision 006

Status

Approved

Decision 002

Date

2026-07-10

Category

Product

Decision

Churches will be treated as a strong initial validation market.

Reason

Churches have clear people-management, attendance, follow-up, and engagement problems that align strongly with the product's core capabilities.

They provide a practical early market for validating Relvio.

This decision does not make Relvio a church-only product.

Alternatives Considered

Schools
NGOs
Businesses
Broad multi-industry launch from day one

Related Decisions

Decision 003
Decision 004

Status

Approved

Decision 003

Date

2026-07-10

Category

Product

Decision

The platform will be designed as an organization-neutral People Operating System.

Reason

The core problem of managing people, journeys, engagement, attendance, and organizational action exists across multiple organization types.

The core architecture and product language should remain adaptable to:

Churches
Ministries
NGOs
Communities
Associations
Schools
Clubs
People-centered businesses

Industry-specific assumptions must not be hardcoded into the core platform without an approved product decision.

Alternatives Considered

Church-only platform
Separate product for every industry

Related Decisions

Decision 001
Decision 002
Decision 004

Status

Approved

Decision 004

Date

2026-07-10

Category

Product

Decision

The Journey Engine will be a core product capability.

Reason

People move through meaningful stages in their relationship with an organization.

Relvio should help organizations understand:

Where a person currently is
Where the person has been
How the person's journey has changed
What action may be required next

Journey history must be preserved rather than represented only by a static status.

Alternatives Considered

Static member statuses
Fixed workflows
Tags only

Related Decisions

Decision 003
Decision 014

Status

Approved

Decision 005

Date

2026-07-10

Category

Engineering

Decision

Flutter will be used for Relvio client development.

Reason

Flutter provides a strong development environment for building high-quality mobile applications from one shared codebase.

Relvio v1 will prioritize:

Android
iOS

Flutter's broader platform support may be considered later.

The existence of Flutter web and desktop support does not place web or desktop applications inside Relvio v1 scope.

Alternatives Considered

Native Android and iOS applications
React Native
Web-first application

Related Decisions

Decision 011

Status

Approved

Decision 006

Date

2026-07-10

Category

Database

Decision

PostgreSQL will be the primary relational database.

Reason

Relvio contains strongly relational data including:

Organizations
Memberships
People
Journey stages
Journey history
Communities
Events
Attendance
Follow-ups
Roles
Permissions

PostgreSQL provides reliable relational integrity, transactions, constraints, and mature indexing capabilities.

Alternatives Considered

MySQL
MongoDB
Cloud Firestore

Related Decisions

Decision 001
Decision 007
Decision 013

Status

Approved

Decision 007

Date

2026-07-10

Category

API

Decision

The backend will expose versioned REST APIs.

Reason

REST is predictable, widely supported, straightforward for the Flutter application to consume, and sufficient for Relvio v1.

The approved API base version is:

/api/v1

Breaking API changes require an appropriate versioning decision.

Alternatives Considered

GraphQL
gRPC

Related Decisions

Decision 006
Decision 013

Status

Approved

Decision 008

Date

2026-07-10

Category

Business

Decision

Relvio will use a subscription-based business model.

Reason

Recurring revenue better supports continuous product development, infrastructure, customer support, and long-term product maintenance.

Pricing details may evolve based on product validation and market evidence.

Alternatives Considered

One-time purchase
Lifetime license
Advertising-supported model

Related Decisions

None

Status

Approved

Decision 009

Date

2026-07-10

Category

Product

Decision

Relvio will prioritize approved core operational workflows before advanced roadmap features.

Reason

Building the validated core product is more valuable than expanding into automation, enterprise capabilities, and integrations before real organizations use the platform.

Roadmap ideas are not automatically approved implementation scope.

Alternatives Considered

Large feature-rich first release
Building enterprise capabilities before validation
Building integrations before core workflows

Related Decisions

Decision 016

Status

Approved

Decision 010

Date

2026-07-10

Category

Design

Decision

Relvio will prioritize simplicity, clarity, and calm visual hierarchy over feature density.

Reason

People-centered organizations may include users with different levels of technical experience.

The product should require minimal training for primary workflows.

The approved design direction draws inspiration from the product quality and simplicity associated with modern premium software while maintaining Relvio's own brand identity.

Alternatives Considered

Feature-heavy dashboards
Dense enterprise navigation
Highly decorative interfaces

Related Decisions

Decision 012

Status

Approved

Decision 011

Date

2026-07-10

Category

Product

Decision

Relvio v1 will be a mobile-first product for Android and iOS.

Reason

The approved Relvio product workflows are strongly suited to mobile use.

Examples include:

People management
Follow-ups
Event operations
Live attendance
QR check-in
Walk-in registration
Communication
Notifications

The complete approved v1 UI has been designed as a mobile application.

Alternatives Considered

Building mobile and web simultaneously
Web-first development
Desktop-first development

Related Decisions

Decision 005

Status

Approved

Decision 012

Date

2026-07-10

Category

Design

Decision

The approved Relvio v1 mobile UI will be frozen before implementation.

Reason

The complete Relvio mobile experience has been designed and approved.

Freezing the UI prevents continuous redesign during engineering and allows implementation to focus on translating the approved product into Flutter.

Changes are allowed only when:

A genuine usability issue is discovered
A technical constraint requires adjustment
User testing identifies a meaningful problem

Loading states, skeletons, shimmer, error states, empty states, micro-interactions, and appropriate animations may be implemented during Flutter development according to the approved design language.

Alternatives Considered

Redesigning screens during implementation
Designing every technical state as a separate high-fidelity screen before coding

Related Decisions

Decision 010
Decision 011

Status

Approved

Decision 013

Date

2026-07-11

Category

Architecture

Decision

The Flutter application and PostgreSQL database will communicate through a dedicated backend API.

Reason

The backend must enforce:

Authentication
Organization membership
Roles and permissions
Business rules
Validation
Organization isolation
Attendance integrity
Journey history integrity

The Flutter application must not connect directly to PostgreSQL.

Alternatives Considered

Direct database access from Flutter
Client-controlled business rules
Firebase-first database architecture

Related Decisions

Decision 001
Decision 006
Decision 007

Status

Approved

Decision 014

Date

2026-07-11

Category

Database

Decision

Journey transitions will create immutable journey history records.

Reason

A person's journey is historical product data.

Changing a person's current journey stage must not overwrite previous stage movement.

Journey history is required for:

Person timeline
Relationship context
Reporting
Future automation
Organizational insight

Alternatives Considered

Store only the current stage
Overwrite the previous journey state
Store journey changes only in generic application logs

Related Decisions

Decision 004
Decision 006

Status

Approved

Decision 015

Date

2026-07-11

Category

Architecture

Decision

Relvio will use Riverpod for Flutter state management and GoRouter for application routing.

Reason

Riverpod provides explicit, testable state management and dependency access suitable for the approved feature-first architecture.

GoRouter provides declarative routing suitable for:

Authentication redirects
Onboarding flows
Organization setup
Protected application routes

Alternatives Considered

Provider
Bloc
GetX
Navigator-only routing

Related Decisions

Decision 005
Decision 011

Status

Approved

Decision 016

Date

2026-07-11

Category

Engineering

Decision

Relvio will use a feature-first architecture with controlled data, domain, and presentation boundaries.

Reason

Relvio contains distinct product modules including:

Authentication
Organizations
People
Journey
Communities
Events
Attendance
Follow-Ups
Communication
Notifications
Reports
Workspace

Feature-first organization improves discoverability and supports incremental implementation.

Architectural layers must only be introduced when they have a clear responsibility.

Empty folders and unnecessary architecture ceremony are discouraged.

Alternatives Considered

Global screens/models/services folders
Strict layer-first project structure
Unstructured feature development

Related Decisions

Decision 005
Decision 015

Status

Approved

Decision 017

Date

2026-07-11

Category

Security

Decision

Organization isolation is a critical security boundary and must be enforced by the backend.

Reason

Relvio serves multiple organizations from one platform.

Frontend filtering cannot guarantee data isolation.

Every organization-scoped backend operation must verify:

Authentication
Organization membership
Organization-specific role
Required permission
Organization-scoped resource ownership

A cross-organization data leak is classified as a Critical P0 defect.

Alternatives Considered

Client-side organization filtering
Trusting client-provided organization IDs
Separate application deployment per organization

Related Decisions

Decision 001
Decision 003
Decision 013

Status

Approved

Decision 018

Date

2026-07-11

Category

Engineering

Decision

Attendance write operations will use backend integrity controls and idempotency.

Reason

Attendance may be recorded through:

Search check-in
Manual check-in
QR check-in
Walk-in registration
Manual attendance
Offline synchronization

Mobile network retries and offline synchronization may repeat requests.

Relvio must prevent duplicate attendance records.

Protection should include:

Backend validation
Database constraints
Idempotency keys for required operations

Alternatives Considered

Flutter-only duplicate prevention
Retry without idempotency
Manual duplicate cleanup

Related Decisions

Decision 006
Decision 013
Decision 017

Status

Approved

Decision 019

Date

2026-07-11

Category

Engineering

Decision

Claude or another AI coding assistant may be used as an implementation engineer, but approved project documentation defines the architecture.

Reason

AI-assisted development can accelerate implementation, refactoring, and repetitive engineering work.

However, allowing an AI coding assistant to independently redefine architecture across tasks may create inconsistent patterns.

The implementation assistant must inspect relevant approved documentation before coding.

The assistant must not silently:

Change architecture
Invent API endpoints
Modify database design
Invent design tokens
Add unrelated features
Replace approved dependencies

Architectural decisions remain governed by approved project documentation and the Decision Log.

Alternatives Considered

Allow the coding assistant to design architecture per feature
Develop without architectural documentation
Avoid AI-assisted development

Related Decisions

Decision 015
Decision 016

Status

Approved

Decision 020

Date

2026-07-11

Category

Product

Decision

The final primary navigation item will use the label Workspace instead of More.

Reason

Workspace better communicates the operational and administrative area of Relvio.

The section contains organization, profile, roles, permissions, settings, and related workspace controls.

The label better supports Relvio's positioning as a People Operating System.

Alternatives Considered

More
Admin
Menu

Related Decisions

Decision 010
Decision 012

Status

Approved

Decision 021

Date

2026-07-11

Category

Engineering

Decision

Loading states, skeletons, shimmer, error states, empty states, and micro-interactions will be implemented during Flutter development.

Reason

These behaviours are application states and interaction details that are best implemented with the real Flutter state and component system.

They do not require separate high-fidelity UI screens for every variation before implementation.

All states must remain visually consistent with the approved Relvio design system.

Alternatives Considered

Design every state as a separate high-fidelity screen
Ignore technical states until after MVP

Related Decisions

Decision 012

Status

Approved

Decision 022

Date

2026-07-11

Category

Testing

Decision

Relvio testing will prioritize critical behaviour and data integrity instead of targeting an arbitrary code coverage percentage.

Reason

The most important product risks include:

Organization isolation
Permission enforcement
Attendance duplication
Journey history corruption
Authentication and session failures
Offline attendance synchronization

A high coverage percentage does not guarantee these workflows are protected.

Testing must focus on meaningful product behaviour.

Alternatives Considered

Mandatory universal coverage percentage
Manual testing only

Related Decisions

Decision 014
Decision 017
Decision 018

Status

Approved

Decision 023

Date

2026-07-11

Category

Product

Decision

Relvio will build and validate the approved core product before implementing automation, advanced integrations, or enterprise features.

Reason

The product must first prove that organizations repeatedly use the core system for:

People
Journey
Follow-Ups
Events
Attendance
Communication
Reports

Future roadmap ideas must not distract from completing and validating Relvio v1.

Alternatives Considered

Build automation before beta
Build broad integrations before beta
Build enterprise functionality before product validation

Related Decisions

Decision 009

Status

Approved

Updating Decisions

If an approved decision changes:

Do not delete the original decision.
Create a new decision.
Reference the previous decision.
Explain why the direction changed.
Mark the previous decision as Replaced.

Example:

Decision 015
Status: Replaced

Replaced by:
Decision 030

This preserves project history.

What Belongs in the Decision Log

Record decisions that significantly affect:

Product direction
Product scope
Architecture
Database design
API strategy
Security
Major dependencies
Platform support
Business model
Core design direction

Do not create a decision entry for every small implementation choice.

Examples that normally do not require a Decision Log entry:

Rename a private variable
Split a widget
Fix a padding issue
Add a unit test
Refactor a local function

Use engineering judgment.

AI Coding Assistant Rule

AI coding assistants must treat Approved decisions as active project constraints.

An AI coding assistant must not replace an Approved decision because it prefers another technology or pattern.

If implementation conflicts with an Approved decision:

Stop the conflicting implementation.
Identify the conflict.
Explain the impact.
Request or document an architectural decision.
Update the Decision Log if the approved direction changes.

The Decision Log is part of Relvio's architectural memory.