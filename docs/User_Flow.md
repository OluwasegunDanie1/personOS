---
Document: User Flow
Version: 1.1
Status: Approved
Project: Relvio
Owner: Design Team
---

# User Flow

## Purpose

This document defines how approved Relvio user flows should be interpreted and protected during implementation.

A user flow describes the relationship between approved user intent, visible product states, navigation, and confirmed system outcomes.

User flows should support:

- Clarity
- Predictability
- Efficiency
- Error recovery
- Data integrity
- Security
- Frozen UI fidelity

The approved Relvio v1 mobile UI and specialized approved product documentation remain authoritative.

This document does not independently define:

- Product scope
- Screens
- Routes
- Navigation destinations
- API endpoints
- API fields
- Database structures
- Journey stages
- Roles
- Permissions
- Report types
- Notification delivery
- Business rules

Do not use a flow diagram as authority to invent missing implementation behavior.

---

# Product and Platform Context

The public product name is:

**Relvio**

Atlas was an internal early codename.

Relvio v1 product platforms are:

- Android
- iOS

This document defines mobile application flow guidance.

It does not define:

- Landing-page flows
- Web application flows
- Desktop sidebar flows
- Windows flows
- macOS flows
- Linux flows

Do not create unapproved platform navigation from this document.

---

# Flow Authority

Approved Relvio user flows must be interpreted using the relevant documentation.

Important authorities include:

- `MVP Scope.md`
- `High-Fidelity Screens.md`
- `13_API_Specification.md`
- Approved database documentation
- `16_Security.md`
- Approved architecture documentation
- `Folder Structure.md`
- `Component Library.md`
- `Flutter Theme Implementation.md`

The frozen Relvio v1 mobile UI controls visible screen and interaction interpretation.

The API specification controls approved client-server contracts.

The backend controls protected business operations.

The database documentation controls approved persistence structures.

Security documentation controls authentication, membership, role, permission, and organization-isolation responsibilities.

If an apparent user flow requires behavior not defined by the relevant approved documentation, report the gap.

Do not invent the missing behavior.

---

# Flow Principles

Approved Relvio flows should:

- Make the user's current context understandable.
- Make approved primary actions clear.
- Preserve approved navigation behavior.
- Provide appropriate feedback for asynchronous operations.
- Represent loading where the user is waiting.
- Represent recoverable failure where recovery is possible.
- Prevent duplicate protected actions where relevant.
- Preserve backend authority.
- Protect organization isolation.
- Preserve data integrity.
- Avoid unnecessary interaction steps.

Efficiency must not override:

- Security
- Validation
- Permission enforcement
- Attendance idempotency
- Journey history integrity
- Required confirmation
- Required backend processing

The goal is not mechanically to minimize taps.

The goal is to make the approved workflow clear and efficient without weakening product integrity.

---

# Flow Representation

Flow diagrams in this document are conceptual.

A conceptual flow such as:

```text
User Action
↓
Processing
↓
Confirmed Result


does not imply:

A screen named Processing
A route named /processing
An API endpoint
A database table
A Flutter feature folder

Flow labels describe responsibilities.

Exact implementation names must come from approved implementation documentation.

Application Entry Flow

The approved frozen Relvio UI controls the visible application entry experience.

Conceptually:

Application Opened
↓
Approved Entry State
↓
Authentication or Authorized Product Access

Implementation must determine the appropriate state using approved authentication and application-start behavior.

Do not invent a landing page.

Do not automatically force every application open through login if an approved authenticated state remains valid.

Do not bypass authentication merely because local Flutter state indicates a previous session.

Protected backend operations remain subject to backend authentication and authorization.

Welcome and Authentication Flow

Visible welcome and authentication behavior must match the approved frozen Relvio UI.

Conceptually:

Approved Welcome or Authentication Entry
↓
User Provides Approved Credentials or Authentication Input
↓
Authentication Request
↓
Backend Result

Successful authentication:

Authentication Confirmed
↓
Authorized Application State

Failed authentication:

Authentication Rejected or Fails
↓
Approved Error State
↓
User Corrects Input or Retries Where Appropriate

Flutter must not treat local navigation as proof of authentication.

The backend remains authoritative for protected access.

Do not invent:

Authentication providers
Social login
Biometric login
Two-factor authentication
Firebase Authentication

unless explicitly approved.

Password Recovery Flow

Password recovery behavior must follow approved authentication and API documentation.

Conceptually:

Approved Password Recovery Entry
↓
User Provides Required Input
↓
Recovery Request
↓
Backend Result
↓
Approved User Feedback

Do not assume the exact recovery mechanism from this document.

This document does not independently approve:

Verification emails
One-time codes
Deep links
In-app password reset
External reset pages

The approved API and authentication documentation control the mechanism.

If the implementation mechanism is not defined, report the gap.

Organization Access and Setup Flow

Relvio is a multi-tenant SaaS.

Organization access is a security boundary.

Conceptually:

Authenticated User
↓
Backend Determines Approved Organization Access State
↓
Authorized Organization Context or Approved Setup State

Where approved organization setup is required:

Approved Organization Setup UI
↓
User Provides Approved Information
↓
Backend Validation and Mutation
↓
Confirmed Organization State
↓
Approved Next Product State

Do not infer required setup fields from this document.

Do not invent:

Organization type fields
Country fields
Time-zone fields
Logo requirements
Team invitation steps
Role assignment steps

unless those responsibilities are defined in approved product, UI, API, and database documentation.

Client organization selection or filtering is not tenant security.

The backend must enforce organization membership and organization isolation.

People Flow

People workflows must follow the approved frozen UI and product scope.

Conceptually:

Approved People Entry
↓
Approved People State
↓
User Selects an Approved People Action
↓
Relevant UI Flow

For a protected people mutation:

User Submits Approved People Action
↓
Submission State
↓
Backend Validation and Authorization
↓
Confirmed Result or Recoverable Failure

On success:

Confirmed Backend Result
↓
Approved Updated People State

On failure:

Backend or Network Failure
↓
Approved Error State
↓
Correction or Retry Where Appropriate

Do not invent:

Person fields
Person statuses
Person types
Member-only terminology
Visitor-only modules
Groups
Duplicate detection

from this document.

The API and database documentation control approved data structures.

Journey Flow

Journey is an approved Relvio product responsibility.

The exact journey UI must follow the frozen Relvio interface.

Conceptually:

Approved Journey Context
↓
User Initiates an Approved Transition
↓
Submission State
↓
Backend Authorization and Business Rule Validation
↓
Confirmed Transition or Rejected Transition

Successful transition:

Backend Confirms Transition
↓
Current Journey State Updates
↓
Immutable Journey History Remains Preserved

Rejected or failed transition:

Backend Rejects or Request Fails
↓
Current Confirmed Journey State Remains Authoritative
↓
Approved Error or Recovery State

Do not implement journey movement as a local-only Flutter state change.

Do not rewrite historical transition records to represent current journey state.

Do not invent a stage sequence such as:

Visitor
↓
First Visit
↓
Follow-up
↓
Member
↓
Volunteer
↓
Leader

unless those exact stages and relationships are defined by approved implementation-controlling documentation.

Do not invent:

Stage names
Stage order
Automatic transitions
Drag-and-drop behavior
Transition permissions
Transition confirmation requirements

The backend remains authoritative for protected journey transitions.

Event Flow

Event workflows must follow the approved frozen UI, product scope, API specification, and database documentation.

Conceptually:

Approved Event Context
↓
User Initiates an Approved Event Action
↓
Relevant Event UI
↓
Submission State Where Applicable
↓
Backend Result
↓
Approved Updated Event State or Error State

Do not infer event lifecycle behavior from generic event-management products.

This document does not independently approve:

Draft events
Published events
Event templates
Event categories
Recurring events
Announcements
Event staff assignment

Do not use the word Publish as an implementation action unless approved event behavior defines a publish responsibility.

Attendance Flow

Attendance is an approved Relvio product responsibility.

Attendance requires backend integrity controls and idempotency.

Conceptually:

Approved Attendance Context
↓
User Initiates an Approved Attendance Action
↓
Submission State
↓
Backend Validation, Authorization, and Idempotency Handling
↓
Confirmed Attendance Result or Failure

Successful attendance write:

Backend Confirms Attendance Result
↓
Flutter Presents Confirmed Attendance State

Failed attendance write:

Request Fails or Backend Rejects Action
↓
Flutter Does Not Treat Local State as Committed Attendance
↓
Approved Error or Recovery State

Repeated equivalent attendance submissions must behave according to the approved API idempotency contract.

Flutter must not create duplicate attendance behavior through uncontrolled repeated submissions.

This document does not approve:

QR check-in
NFC check-in
Facial recognition
Geofenced check-in
Self check-in

Do not create future attendance flows inside the v1 implementation.

Follow-up Flow

Follow-up workflows must follow approved frozen UI and implementation-controlling documentation.

Conceptually:

Approved Follow-up Context
↓
User Initiates an Approved Follow-up Action
↓
Relevant Follow-up UI
↓
Submission State
↓
Backend Validation and Authorization
↓
Confirmed Result or Failure

For an approved completion action:

User Initiates Completion
↓
Backend Processes Protected Mutation
↓
Confirmed Follow-up State Updates

Do not assume that creating a follow-up automatically sends a notification.

Do not assume that completing a follow-up automatically creates a person timeline event unless approved API and database behavior defines that responsibility.

Do not invent:

Follow-up statuses
Assignment rules
Due-date requirements
Completion-history structures
Notification triggers

from this document.

Approved Product Insights Flow

Where the frozen Relvio UI contains approved product insights or reporting responsibilities:

Approved Insights Entry
↓
Backend-Supported Data Request
↓
Loading State
↓
Approved Insight State or Error State

Where approved filtering exists:

User Changes Approved Filter
↓
Relevant State Updates
↓
Approved Data Request or Local Presentation Behavior
↓
Updated Insight State

This document does not independently approve:

Report types
Custom reports
Export
PDF generation
Excel generation
CSV generation
Advanced analytics
Report builders

Do not create a generic:

Choose Report
↓
Apply Filters
↓
View Results
↓
Export

workflow unless the approved UI and implementation documentation define it.

Primary Navigation Order

The final Relvio v1 primary bottom navigation contains exactly five ordered destinations:

Home → People → Events → Messages → Workspace

This order is frozen for v1. Messages is the fourth destination; Workspace is the fifth and final destination. Do not substitute Dashboard for Home, More or Settings for Workspace, or Attendance/Follow-ups for Messages, and do not add a sixth destination. Attendance and Follow-ups are approved product areas reached through their own approved flows/routes, not primary-navigation substitutes.

The "Relvio Product Specification" document's responsibility-area sequence (Dashboard → People → Events → Attendance → Messages → Workspace) is a product responsibility-area illustration, not navigation order; this section is the controlling navigation authority.

Workspace Flow

The approved primary bottom navigation label is:

Workspace

Do not use:

More

as the primary navigation destination name.

Workspace behavior must follow the approved frozen Relvio UI.

Conceptually:

Primary Navigation
↓
Workspace
↓
Approved Workspace Responsibilities

Do not treat Workspace as a generic dumping ground for unrelated product features.

Do not add:

Billing
Integrations
Appearance settings
API settings
White-label settings
Future-feature links

unless explicitly approved.

The visible Workspace content must match the frozen UI and approved product scope.

Messages Navigation Flow

Messages remains the fourth of the five frozen Relvio v1 primary bottom-navigation destinations (see "Primary Navigation Order" above). Frozen UI presence does not by itself authorize a production messaging backend; production messaging persistence remains deferred (see Mvp_scope.md, 12_Database_Design.md).

Conceptually, while production messaging backend authority remains deferred:

Primary Navigation
↓
Messages
↓
Frozen Messages Screen Shell (header/navigation chrome only)
↓
Neutral Unavailable/Not-Yet-Connected Content State

Do not render invented conversation rows, unread counts, groups, or announcements in this state. Do not perform any Messages/Conversations API call while this state is in effect. Do not create local fake conversations or messages. Compose/new-message controls must be disabled or non-functional while backend authority is deferred; they must not silently no-op or appear to succeed.

Do not remove Messages from primary navigation to work around the deferred backend. Do not replace it with another destination. Do not invent an interim messaging backend, participant model, or real-time delivery mechanism to make this screen appear functional.

Real Messages/Conversations integration may begin only after a separate, explicit authority decision promotes production messaging into approved MVP scope and resolves persistence, participant identity, tenant/conversation-membership security, field-complete API contracts, pagination/sort, send/read semantics, and the notification-side-effect boundary.

Notification Flow Boundary

A visible notification responsibility does not automatically approve remote push infrastructure.

Where an approved notification UI exists:

Approved Notification Entry
↓
Approved Notification State
↓
User Selects an Approved Notification
↓
Approved Destination or Action Where Defined

Do not assume every notification has a deep link.

Do not assume every notification has an action.

Do not assume notification creation or delivery behavior from this document.

This document does not approve:

Firebase Cloud Messaging
SMS notifications
WhatsApp notifications
Email notifications
Push infrastructure

Notification delivery and backend behavior require approved product and technical documentation.

Search Flow Boundary

This document does not approve a global search system.

Do not implement:

Global Search
↓
People
Events
Follow-ups
Users

from the old Atlas flow.

Where an approved Relvio screen contains search:

Approved Search Context
↓
User Provides Search Input
↓
Approved Search Behavior
↓
Results, Empty State, or Error State

Search scope, query behavior, backend support, and result types must follow the approved UI and API documentation.

Do not expand screen-specific search into a global product feature.

Settings and Configuration Flow Boundary

Configuration responsibilities must follow the approved Workspace UI and product documentation.

Conceptually:

Approved Configuration Entry
↓
Approved Configuration Responsibility
↓
User Changes Approved Value
↓
Backend Mutation Where Required
↓
Confirmed State or Error State

Do not create a generic Settings architecture from this document.

Do not invent categories such as:

Appearance
Billing
Integrations
API
Language
White Label

Relvio v1 does not approve dark mode or a theme toggle.

The frozen UI controls visible configuration responsibilities.

Permission Flow

Permission enforcement is a backend responsibility.

Conceptually:

User Initiates Protected Action
↓
Backend Verifies Authentication
↓
Backend Verifies Organization Membership
↓
Backend Verifies Relevant Role or Permission
↓
Action Allowed or Rejected

Allowed:

Backend Confirms Protected Operation
↓
Flutter Presents Confirmed Result

Rejected:

Backend Rejects Operation
↓
Flutter Presents Approved Restricted or Error State

Flutter may hide or disable actions based on known authorized state for user experience.

That UI behavior is not the authoritative permission boundary.

Do not implement:

Restricted Action
↓
Flutter Permission Check
↓
Access Denied

as the complete security model.

Hiding a control is not permission enforcement.

Client-side permission checks do not replace backend authorization.

Loading Flow

Asynchronous operations should represent meaningful waiting states where appropriate.

Conceptually:

User Enters or Initiates Async Responsibility
↓
Loading or Submission State
↓
Confirmed Content or Failure State

The approved UI and component documentation control presentation.

A loading state may use:

Approved progress presentation
Approved skeleton behavior
Approved shimmer behavior
Approved button submission state

Do not add skeletons or shimmer to every screen automatically.

Do not introduce Lottie or Rive by default.

Simple approved animations should be implemented directly in Flutter where appropriate.

Error Recovery Flow

Recoverable failures should provide an appropriate recovery path.

Conceptually:

Approved Action
↓
Failure
↓
Understandable Error State
↓
Correction, Retry, or Safe Return Where Appropriate

Not every error supports retry.

Examples of conditions that may require different handling include:

Validation rejection
Authentication failure
Authorization rejection
Organization-access rejection
Network failure
Backend failure
Conflict
Idempotent repeated request result

Do not reduce all errors to:

Error
↓
Retry

The approved API error contract and product UI control the correct behavior.

Users should not be trapped in an avoidable dead end.

Security rejection must not be converted into an unauthorized retry loop.

Empty-State Flow

Where an approved screen has no content:

Approved Empty State
↓
Approved Explanation
↓
Approved Action Where One Exists

An empty state does not always require a primary action.

Do not automatically add:

Create First Record

to every empty state.

Do not invent creation permissions or product actions from an empty state.

The frozen UI controls:

Empty-state content
Icon or illustration use
Action presence
Action destination

Do not invent illustration assets.

Success Feedback

Completed actions should provide feedback appropriate to the approved interaction.

Feedback may be represented through:

Updated visible state
Approved inline confirmation
Approved transient feedback
Navigation to a confirmed state
Updated content

This document does not require a snackbar or toast after every successful action.

Do not automatically make every success message disappear after a fixed duration.

The feedback mechanism should match the approved UI and interaction responsibility.

For protected mutations, success feedback must follow confirmed backend success.

Do not show success because a local Flutter state update occurred before the backend result.

Failure Feedback

Failure feedback should help the user understand what can happen next.

Where appropriate, communicate:

What failed
Whether input should be corrected
Whether retry is available
Whether access is restricted
Whether the previous confirmed state remains unchanged

Do not expose:

Stack traces
Database errors
Sensitive backend details
Authorization implementation details
Secrets

Error presentation must follow approved security and API behavior.

Mobile Navigation Flow

Relvio v1 navigation is mobile-first for Android and iOS.

Visible navigation must follow the approved frozen UI.

Conceptually:

Approved Navigation Entry
↓
Approved Destination
↓
Approved Child Responsibility Where Applicable
↓
Approved Back or Return Behavior

Do not create a generic rule that every product area must use:

Module
↓
Screen
↓
Details
↓
Back

The approved screen hierarchy controls navigation.

Do not invent routes to make navigation architecture symmetrical.

GoRouter implementation must represent approved navigation behavior.

The approved primary bottom navigation label is:

Workspace

Back Navigation

Back behavior should preserve user context where appropriate and follow approved mobile navigation expectations.

Implementation should review:

Nested navigation
Form state
Unsaved approved input behavior
Modal or sheet dismissal
Authentication boundaries
Organization-access boundaries

Do not add confirmation dialogs to every back action.

Do not silently discard important user input where the approved workflow requires protection.

If unsaved-change behavior is not defined for a critical flow, report the gap.

Do not invent a universal confirmation rule.

Repeated Submission Protection

Protected mutation flows should prevent unintended repeated submissions where appropriate.

Flutter may use interaction controls such as:

Submission loading state
Temporary action disabling
Request-state coordination

These client controls improve user experience.

They are not substitutes for backend integrity.

Attendance idempotency remains a backend requirement.

Protected backend operations must preserve their approved integrity rules even if the client submits a request more than once.

Organization Context

Relvio is multi-tenant.

Every protected organization-scoped flow must preserve the authorized organization context.

Conceptually:

Authenticated User
↓
Authorized Organization Context
↓
Organization-Scoped Product Flow
↓
Backend Organization Isolation

Flutter must not treat an organization identifier selected or stored locally as proof of authorized organization access.

The backend must enforce:

Authentication
Organization membership
Relevant authorization
Organization isolation

A cross-organization access failure is a security issue.

Do not design client flows that bypass the backend security boundary.

Flow and API Relationship

A visible user flow may require one or more API operations.

Do not infer API endpoints from screen names.

For example, a conceptual flow label such as:

Complete Follow-up

does not authorize an endpoint such as:

POST /api/v1/followups/{id}/complete

unless 13_API_Specification.md defines that contract.

Similarly, do not infer:

Request fields
Response fields
Status codes
Query parameters
Mutation behavior

from a user-flow diagram.

The API specification remains authoritative.

Flow and Database Relationship

A user-flow step does not define a database table or column.

Do not create database structures from labels such as:

Timeline
Notification
Stage
Status
Team
Report

unless approved database documentation defines the required persistence responsibility.

A visible UI concept and a database entity are not automatically one-to-one.

Approved database documentation remains authoritative.

Flow and Flutter Structure

A user-flow step does not automatically require:

A feature folder
A screen class
A controller
A provider
A repository
A use case
A route

Implementation structure follows real responsibility.

Folder Structure.md remains authoritative.

Do not convert every box in a flow diagram into an architecture layer or file.

Frozen UI Protection

The Relvio v1 mobile UI is complete, approved, and frozen.

This document must not be used to redesign approved flows visually.

Do not:

Add steps because a generic SaaS flow usually contains them
Remove approved steps to minimize taps
Add confirmation dialogs automatically
Add progress steppers automatically
Add onboarding screens automatically
Add success screens automatically
Add desktop flows
Add global search
Add future attendance methods

Where this document is less visually specific than the frozen UI, the frozen UI remains authoritative.

AI Implementation Rules

Claude or another AI coding assistant acts as an implementation engineer.

AI must not:

Treat conceptual flow labels as screen names
Treat conceptual flow labels as route names
Infer API endpoints from flows
Infer API fields from flows
Infer database structures from flows
Invent journey stages
Invent role names
Invent permission names
Invent event publication behavior
Invent notification triggers
Invent global search
Invent report exports
Add QR check-in
Add desktop navigation
Add a landing page
Minimize steps by removing required integrity behavior
Show mutation success before confirmed backend success

AI should:

Use the frozen Relvio UI as visual flow authority
Use approved product scope
Use the approved API specification
Preserve backend authority
Preserve organization isolation
Preserve immutable journey history
Preserve attendance idempotency
Represent meaningful loading and recovery states
Report missing flow decisions

When a flow cannot be implemented from approved documentation, report the gap.

Do not invent the missing behavior.

Documentation Responsibilities

This document owns:

User-flow implementation principles
Flow interpretation boundaries
Mobile flow guidance
Backend-authority flow expectations
Error-recovery flow guidance
Loading and submission flow guidance
Repeated-submission guidance
Organization-context flow protection

This document does not own:

Product scope
Screen inventory
Screen design
Route definitions
API contracts
Database schema
Journey stage definitions
Role definitions
Permission definitions
Notification infrastructure
Report definitions
Platform expansion

Those responsibilities remain with their approved Relvio documents.

Success Criteria

Relvio user flows are successful when:

Approved user intent remains clear.
Frozen UI behavior is preserved.
Users receive appropriate asynchronous feedback.
Recoverable failures provide appropriate recovery.
Protected mutations remain backend-authoritative.
Organization isolation remains protected.
Journey transitions preserve immutable history.
Attendance writes preserve approved idempotency behavior.
Conceptual flow labels do not create invented screens or routes.
User flows do not invent API contracts or database structures.
Android and iOS remain the approved v1 platform context.
AI coding assistants report missing flow decisions instead of guessing.
Flow efficiency does not weaken security or data integrity.