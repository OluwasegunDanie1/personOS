---
Document: MVP Scope
Version: 1.1
Status: Approved
Project: Relvio
Owner: Product Team
---

# MVP Scope

## Purpose

This document defines the product scope boundary for the first public version of Relvio.

Relvio v1 should solve its approved core people and relationship management problems well without expanding into unrelated organizational software.

The first release exists to:

- Deliver a usable Relvio product
- Validate the product with real organizations
- Support early customer adoption
- Observe real organizational workflows
- Collect product feedback
- Establish a reliable foundation for deliberate future development

This document defines product scope boundaries.

It is not:

- An API specification
- A database design
- A screen specification
- A route inventory
- A Flutter folder inventory
- A complete field catalogue
- A roadmap for future releases

Implementation details remain controlled by their approved Relvio documents.

---

# Product Definition

Relvio is a People Operating System for people-centered organizations.

Relvio helps organizations understand people, strengthen relationships, coordinate meaningful follow-up, and support organizational growth.

Primary brand message:

> Build stronger relationships.

Churches and similar organizations are an important initial validation market.

The core Relvio product remains organization-neutral.

Product language, architecture, database structures, API contracts, and implementation must not hardcode Relvio as a church-only product unless an explicitly approved product requirement requires market-specific behavior.

---

# Approved v1 Platforms

Relvio v1 product platforms are:

- Android
- iOS

The frontend is implemented with Flutter.

The approved Relvio v1 mobile UI is complete, approved, and frozen.

This document does not approve:

- Web application support
- Desktop application support
- Additional client platforms

Do not create platform infrastructure for unapproved clients.

---

# v1 Product Goal

The first public version of Relvio should enable approved organization users to manage the core relationship workflow represented by the frozen Relvio UI and approved product documentation.

The core v1 product responsibilities are:

- Securely access Relvio
- Operate within an authorized organization
- Work with people records
- Understand relevant people information
- Manage approved journey workflows
- Manage approved event responsibilities
- Record attendance reliably
- Coordinate follow-ups
- View approved product insights
- Access approved workspace responsibilities

These responsibilities define product areas.

They do not independently define screens, API endpoints, fields, database tables, or navigation destinations.

The approved UI and implementation-controlling documentation define the exact implementation.

---

# Authentication and Access

Relvio v1 includes the approved authentication and access flows required by the frozen UI and backend API.

Authentication responsibilities may include approved flows for:

- Account access
- Account creation or onboarding
- Credential recovery
- Session termination

The exact authentication endpoints, request fields, response fields, and session behavior are controlled by `13_API_Specification.md` and `16_Security.md`.

Do not invent:

- Social authentication
- Enterprise authentication
- Two-factor authentication
- Biometric authentication
- Additional authentication providers

unless separately approved.

Flutter authentication state does not replace backend authorization.

---

# Organization Access

Relvio is a multi-tenant SaaS.

Every protected organization operation must respect:

- Authentication
- Organization membership
- Roles
- Permissions
- Organization isolation

Organization isolation is a critical backend security boundary.

Flutter must never be treated as the authoritative tenant-security layer.

Client organization filtering is not tenant security.

The backend REST API remains authoritative for organization access.

The exact organization creation, selection, onboarding, profile, or settings experiences are determined by approved UI and API documentation.

Do not invent organization fields or settings from this document.

---

# People

People management is a core Relvio v1 responsibility.

The exact approved people capabilities must follow:

- Frozen Relvio UI
- Approved API specification
- Approved database design
- Approved security rules

Potential visible operations must only be implemented when they are present in approved implementation-controlling documentation.

Do not infer that generic CRM capabilities are approved merely because Relvio manages people.

Do not automatically add:

- Arbitrary custom fields
- Import systems
- Export systems
- Duplicate detection
- AI suggestions
- Bulk actions
- Relationship mapping

unless separately approved.

Person data mutations must use the backend REST API.

Flutter must not directly mutate PostgreSQL.

Destructive or archival behavior must follow approved API and data rules.

Do not assume hard deletion when product history or related records may exist.

---

# Journey

Journey is a core Relvio v1 product responsibility.

Approved journey behavior must follow the frozen UI, API specification, and database design.

Journey transitions must preserve immutable journey history.

A current journey state must not be implemented by rewriting or destroying historical journey transition records.

Protected journey mutations must be validated by the backend.

Flutter must not become the authority for:

- Valid journey transitions
- Organization isolation
- Journey permissions
- Historical integrity

Do not invent:

- Journey stages
- Stage ordering
- Automatic transitions
- Drag-and-drop behavior
- AI recommendations
- Journey scoring

unless those responsibilities are explicitly approved.

Visual movement in Flutter must not imply that the client can bypass backend journey rules.

---

# Events

Events are part of the approved Relvio v1 people and attendance workflow.

The exact event capabilities, fields, states, and operations must follow approved UI and API documentation.

Do not infer generic event-management functionality from this scope document.

This document does not independently approve:

- Recurring events
- Ticketing
- Payments
- Public registration
- Event categories
- Calendar synchronization
- External conferencing
- Resource booking

unless separately approved elsewhere.

Event mutations must use protected backend API operations.

---

# Attendance

Attendance is a core Relvio v1 responsibility.

Attendance must be recorded reliably.

Attendance is an integrity-sensitive product area.

The backend must enforce approved attendance integrity controls.

Attendance write operations must support approved idempotency behavior.

Flutter must not rely on local UI state as proof that attendance was successfully recorded.

The exact attendance workflow must follow:

- Frozen Relvio UI
- Approved API specification
- Approved database design
- Approved security documentation

Do not add unapproved check-in methods such as:

- QR check-in
- NFC check-in
- Facial recognition
- Geofenced check-in
- Self check-in

Attendance reports or metrics must use explicitly defined backend data and approved product meaning.

Do not invent attendance formulas.

---

# Follow-Ups

Follow-ups are a core Relvio v1 relationship coordination responsibility.

The exact follow-up capabilities, states, assignment behavior, and visible actions must follow approved UI and API documentation.

Protected follow-up mutations must be validated by the backend.

Flutter must not independently determine authorization for follow-up actions.

Do not invent:

- Automated follow-up workflows
- AI-generated follow-up decisions
- Communication sending
- Escalation rules
- Follow-up scoring
- Additional status values

unless explicitly approved.

---

# Insights and Reporting

Relvio v1 may present approved product insights represented by the frozen UI and supported by approved backend behavior.

This document does not approve a generic reporting platform.

Do not invent report categories, formulas, scoring systems, or analytics because they are common in SaaS products.

Metrics must have explicit product meaning.

AI coding assistants must not invent definitions for:

- Growth
- Engagement
- Retention
- Conversion
- Activity scores
- Performance scores

If an approved UI displays a metric but its calculation is not defined by approved implementation documentation, report the missing definition.

Do not create a guessed formula.

Advanced analytics and predictive insights are not approved v1 scope.

---

# Primary Navigation

The final Relvio v1 primary bottom navigation contains exactly five ordered destinations:

1. **Home**
2. **People**
3. **Events**
4. **Messages**
5. **Workspace**

Exact ordered label sequence:

**Home → People → Events → Messages → Workspace**

This order is frozen for v1. Messages is the fourth primary navigation destination; Workspace is the fifth and final primary navigation destination.

Do not substitute:

- Dashboard for Home
- More for Workspace
- Settings for Workspace
- Attendance for Messages
- Follow-ups for Messages
- any other destination

Do not add a sixth primary navigation item.

Attendance and Follow-ups are approved product areas/screens, reached through their own approved flows and routes; they do not replace any of the five primary bottom-navigation destinations.

Backend implementation status does not authorize removing, replacing, reordering, renaming, or hiding a frozen primary navigation destination. Messages remains in navigation while its production backend is deferred, following the approved deferred-state behavior contract defined below ("Messages Navigation").

The "Relvio Product Specification" document's product responsibility-area sequence (Dashboard → People → Events → Attendance → Messages → Workspace) is a product responsibility-area illustration only. It must not be interpreted as bottom-navigation order; this Primary Navigation section is the controlling navigation authority.

---

# Workspace

The approved primary bottom navigation label is:

**Workspace**

Workspace replaces the obsolete primary navigation label:

**More**

The approved frozen UI determines the visible Workspace content and actions.

Do not use old Atlas documentation to populate Workspace with generic settings or SaaS modules.

Do not automatically add:

- Appearance
- Theme switching
- Billing
- Integrations
- API management
- Marketplace
- White-label controls

unless explicitly approved.

Workspace naming must remain consistent in:

- Visible labels
- Routes
- Screens
- Folder names
- Providers
- Tests

---

# Messages Navigation

Messages is the fourth of the five frozen Relvio v1 primary bottom-navigation destinations (see "Primary Navigation" above: Home → People → Events → Messages → Workspace), evidenced by 17_Roadmap.md's completed Phase 1 "Approved Product Areas" list and Asset_Structure.md's Messages empty-state illustration provisioning. Frozen UI presence and production messaging backend readiness are separate concerns and must not be confused with each other.

The production messaging backend (Conversation/Message persistence, participant identity, tenant/conversation-membership security, field-complete API contracts, pagination/sort, send/read semantics, notification side effects) remains explicitly deferred: 12_Database_Design.md lists Messages under "Future Tables — not required for MVP," and no approved documentation defines a field-complete, implementation-ready Messages/Conversations contract.

Do not remove, rename, replace, or hide the Messages navigation destination merely because its production backend is deferred. Do not implement a production messaging backend, invent participant identity, invent real-time delivery, or invent notification side effects to fill this gap. Do not populate the Messages destination with fake or local-only conversation data merely to make the screen appear functional.

The Messages route remains routable in Flutter v1 as a frozen-UI navigation destination that renders a neutral, explicit unavailable/not-yet-connected state until a future, separate authority decision promotes production messaging into approved MVP scope and resolves the gaps listed above. See 13_API_Specification.md and 15_Testing_Strategy.md for the corresponding pre-backend behavior contract.

---

# Team Access, Roles, and Permissions

Relvio v1 supports the approved team access responsibilities required by the product.

The exact user, membership, role, and permission behavior is controlled by approved API, database, and security documentation.

Roles and permissions are backend security responsibilities.

Flutter may present authorized controls and states.

Flutter must not become the authoritative permission enforcement layer.

Do not invent:

- Role names
- Permission names
- Permission matrices
- Enterprise identity models
- Custom permission builders

unless explicitly defined in approved documentation.

A hidden Flutter control is not a security boundary.

The backend must reject unauthorized protected operations.

---

# Notifications

Only notification behavior explicitly represented in approved product, UI, and API documentation belongs to v1.

This document does not independently approve a notification delivery architecture.

Do not assume approval for:

- SMS
- WhatsApp messaging
- Email campaigns
- Push notification infrastructure
- Automated communication
- Communication provider integrations

unless separately approved.

The absence of a communication capability from v1 does not automatically place it on a committed future roadmap.

Potential future opportunities remain governed by `Future Features.md` and approved product decisions.

---

# Settings and Product Configuration

Only settings represented by approved Relvio UI and supported by approved product behavior belong to v1.

Do not create generic SaaS settings sections.

Relvio v1 uses the approved light theme.

Dark mode is not approved for v1.

System theme switching is not approved.

Do not add:

- Theme toggle
- Appearance settings for theme switching
- Riverpod theme state
- Organization-controlled application themes
- White-label theme infrastructure

The exact approved settings experience must follow the frozen UI.

---

# Explicitly Outside v1 Scope

The following capability categories are not approved Relvio v1 implementation scope unless a later explicit decision updates the approved documentation:

- AI assistant
- AI recommendations
- Predictive insights
- Workflow builder
- Automation builder
- Marketplace
- Plugin architecture
- Public developer platform
- Public SDKs
- White-label mobile applications
- Organization-controlled application themes
- Accounting
- Payment processing
- Donation management
- Financial management
- Volunteer scheduling systems
- General learning management
- General document management
- Resource booking systems
- Facial recognition
- NFC check-in
- Geofenced check-in
- Web application
- Desktop application

This list is a v1 exclusion boundary.

It is not a future-release commitment.

An excluded capability must still pass the Relvio product approval process before becoming future implementation scope.

---

# Scope Interpretation

A capability belongs to Relvio v1 only when the relevant approved documentation supports it.

Depending on the responsibility, implementation should be supported by:

- Approved product scope
- Approved frozen UI
- Approved API specification
- Approved database design
- Approved security rules
- Approved architecture
- Approved design documentation

A mention in an old Atlas draft is not approval.

A mention in `Future Features.md` is not approval.

A backlog idea is not automatically implementation scope.

A visually similar feature in another SaaS product is not approval.

A Flutter package capability is not approval.

If required implementation responsibilities conflict or remain undefined, report the documentation gap.

Do not invent the missing product decision.

---

# Scope and Frozen UI

The approved frozen Relvio v1 mobile UI remains authoritative for visible product implementation.

This MVP scope document must not be used to add controls or screens that are absent from the approved UI.

Likewise, visual appearance alone must not be used to invent backend behavior.

For implementation:

- UI authority comes from approved high-fidelity references.
- Product scope comes from approved product documentation.
- API behavior comes from `13_API_Specification.md`.
- Data structure comes from approved database documentation.
- Security authority comes from `16_Security.md`.
- Architecture boundaries come from approved architecture documentation.

These responsibilities must remain aligned.

---

# AI Implementation Rules

Claude or another AI coding assistant acts as an implementation engineer.

AI must not use this document to invent:

- Screens
- API endpoints
- API fields
- Database tables
- Database columns
- Journey stages
- Role names
- Permission names
- Report formulas
- Notification providers
- Product settings
- Navigation destinations
- Future features
- Platform support

AI must not pre-create Flutter feature folders for excluded or speculative capabilities.

AI must implement only approved Relvio v1 responsibilities supported by the relevant implementation-controlling documentation.

When scope is unclear or contradictory, AI must report the conflict.

It must not resolve ambiguity by copying generic CRM, church management, or SaaS patterns.

---

# MVP Success Direction

Relvio v1 should validate whether approved users can use the product to strengthen core people and relationship workflows.

Important product outcomes include:

- Organizations can access and begin using the approved product successfully.
- People information can be managed through approved workflows.
- Attendance can be recorded reliably.
- Attendance integrity is protected.
- Follow-up work can be coordinated through approved workflows.
- Journey history remains accurate.
- Approved insights provide understandable product value.
- Organization data remains isolated.
- Authorized users can complete their relevant responsibilities.
- Users find enough recurring value to return to Relvio.

Exact analytics definitions and numeric success thresholds require separate approved measurement decisions.

Do not invent product success formulas during implementation.

---

# Release Readiness

Relvio v1 is ready for approved beta or release progression when the required release scope satisfies the relevant product and engineering checks.

These include:

- Approved v1 scope is implemented.
- Frozen approved UI is implemented with sufficient fidelity.
- Critical product flows work correctly.
- Critical defects are resolved.
- API behavior matches the approved specification.
- Organization isolation has been verified.
- Authentication and authorization controls have been verified.
- Attendance integrity and idempotency requirements have been tested.
- Journey history integrity has been tested.
- Required documentation is aligned.
- Required testing is complete.
- Security review requirements are satisfied.
- Supported Android and iOS builds meet approved release requirements.

Detailed testing responsibilities remain controlled by `15_Testing_Strategy.md`.

Deployment responsibilities remain controlled by `Deployment.md`.

Security responsibilities remain controlled by `16_Security.md`.

---

# Documentation Responsibilities

This document owns:

- Relvio v1 product scope boundary
- Core v1 product responsibility areas
- Explicit v1 exclusion categories
- MVP scope interpretation rules

This document does not own:

- Detailed feature backlog
- Delivery sequencing
- API contracts
- API fields
- Database schema
- Security implementation
- Flutter architecture
- Screen design
- Design tokens
- Component specifications
- Deployment procedures

Those responsibilities remain with their approved Relvio documents.

`Feature Backlog.md` controls recorded product backlog items.

`Roadmap.md` controls approved delivery sequencing.

`Future Features.md` controls speculative long-term opportunity boundaries.

---

# Guiding Principle

When evaluating v1 scope, ask:

> Does this strengthen the approved Relvio people and relationship workflow required for the first usable product?

If the answer is unclear, the feature must not be added automatically.

It should move through the appropriate product decision process.

Relvio v1 should remain focused.

---

# Success Criteria

This document is successful when:

- Relvio v1 has a clear product boundary.
- The core product remains organization-neutral.
- Churches remain a validation market rather than a hardcoded product identity.
- The frozen UI is protected from scope expansion.
- AI coding assistants cannot invent generic SaaS modules from the MVP definition.
- API and database structures are not inferred from product-area names.
- Attendance integrity requirements remain visible.
- Journey history requirements remain visible.
- Backend organization isolation remains authoritative.
- Excluded capabilities do not become accidental future commitments.
- Product scope remains aligned with approved Relvio documentation.

---

# End of Document