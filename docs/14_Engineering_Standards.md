---
Document: Engineering Standards
Version: 0.2
Status: Approved
Project: Relvio
Owner: Engineering Team
---

# Engineering Standards

## Purpose

This document defines the engineering rules for building Relvio.

These standards apply to:

- Human developers
- AI coding assistants
- Code reviews
- Refactoring
- Testing
- Flutter development
- Backend development

The goal is to keep the Relvio codebase:

- Simple
- Predictable
- Maintainable
- Secure
- Testable
- Scalable

These standards must be followed together with the approved:

- Product documentation
- System Architecture
- Database Design
- API Specification
- Design System
- Folder Structure

If documents conflict, the conflict must be identified and resolved before implementation.

Do not silently invent a new architectural rule.

---

# Core Engineering Principles

Relvio follows these principles:

1. Prefer clarity over cleverness.
2. Keep solutions as simple as the requirement allows.
3. Follow the approved architecture.
4. Keep business logic outside UI widgets.
5. Reuse established components and patterns.
6. Avoid premature abstraction.
7. Avoid premature optimization.
8. Fix root causes instead of hiding symptoms.
9. Make invalid states difficult to represent.
10. Never weaken security for development convenience.
11. Preserve organization data isolation.
12. Write code that another developer can understand.

Code should be boring, predictable, and easy to maintain.

---

# AI-Assisted Development

Relvio may use AI coding assistants such as Claude for implementation.

AI-generated code is not automatically approved.

Before writing code, the AI assistant must inspect the relevant approved project documentation.

At minimum, implementation work must consider:

- System Architecture
- Database Design
- API Specification
- Engineering Standards
- Folder Structure
- Design System or Flutter Theme documentation

The AI assistant must:

- Follow the existing architecture.
- Inspect existing code before creating new patterns.
- Reuse existing widgets and utilities where appropriate.
- Avoid creating duplicate abstractions.
- Avoid changing unrelated files.
- Avoid renaming public APIs without approval.
- Avoid modifying database structure without approval.
- Avoid inventing API endpoints.
- Avoid inventing design tokens.
- Avoid replacing approved dependencies without approval.
- State assumptions when requirements are genuinely unclear.

The AI assistant must not perform large architectural rewrites merely because another approach is preferred.

Approved architecture takes priority over AI preference.

---

# Change Scope

Every implementation task should have a clear scope.

A feature task must not silently include unrelated:

- Refactors
- Dependency upgrades
- Architecture changes
- Database changes
- UI redesigns
- Naming changes

If unrelated technical debt is discovered, document it separately.

Do not expand the task without approval.

---

# Project Structure

Relvio uses a feature-first Flutter structure.

Features are grouped by product responsibility.

Example:

```text
features/
├── authentication/
├── onboarding/
├── dashboard/
├── organizations/
├── people/
├── journeys/
├── communities/
├── events/
├── attendance/
├── follow_ups/
├── communication/
├── notifications/
├── reports/
└── workspace/


Shared application infrastructure must not be duplicated inside individual features.

Shared concerns belong in the approved core or shared directories defined by the Folder Structure document.

Do not create new top-level folders without architectural justification.

Feature Structure

A feature should contain only the layers it actually needs.

Example:

people/
├── data/
├── domain/
└── presentation/

Possible internal structure:

people/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── use_cases/
│
└── presentation/
    ├── controllers/
    ├── providers/
    ├── screens/
    └── widgets/

Do not create empty architectural folders.

Do not create a service, repository, controller, provider, or use case unless it has a clear responsibility.

Avoid architecture ceremony.

The approved System Architecture and Folder Structure documents remain the source of truth.

Dependency Direction

Dependencies must flow toward business rules.

Expected direction:

Presentation
    ↓
Domain
    ↓
Data abstractions

Infrastructure implements abstractions required by the application.

UI code must not directly depend on HTTP implementation details.

Widgets must not call API clients directly.

Expected application flow:

Screen / Widget
      ↓
Controller / Notifier
      ↓
Use Case or Repository
      ↓
Data Source / API Client
      ↓
Backend API

A use case should only be introduced when it represents meaningful application behaviour.

Simple repository operations do not require artificial use-case wrappers unless required by the approved architecture.

Naming Conventions
Dart Files

Use snake_case.

Examples:

people_repository.dart
person_profile_screen.dart
attendance_controller.dart
event_card.dart
Classes and Types

Use PascalCase.

Examples:

PeopleRepository
AttendanceController
PersonProfileScreen
EventSummary
Variables and Functions

Use camelCase.

Examples:

currentUser
selectedEvent
attendanceEntries
loadPeople()
recordAttendance()
Constants

Use lowerCamelCase.

Examples:

const defaultPageSize = 20;
const maxUploadSize = 10 * 1024 * 1024;

Use names that communicate meaning.

Avoid unclear names such as:

data
temp
obj
item2
value1
manager
helper

unless the context makes the meaning immediately obvious.

Boolean Naming

Boolean values should read naturally.

Preferred:

isLoading
isAuthenticated
hasMore
canEdit
shouldRefresh

Avoid:

loading
auth
more
editFlag
Function Standards

Functions should have one clear responsibility.

Prefer small, focused functions.

Avoid functions with excessive parameters.

If several parameters represent one concept, consider a typed object.

Prefer:

Future<void> createPerson(CreatePersonInput input)

instead of:

Future<void> createPerson(
  String firstName,
  String lastName,
  String email,
  String phone,
  String address,
  String stageId,
  String communityId,
)

Avoid deeply nested control flow.

Use early returns where they improve readability.

Dart and Flutter Standards

Use Dart null safety correctly.

Do not use the null assertion operator ! merely to silence analyzer errors.

Avoid dynamic unless interacting with genuinely dynamic external data.

Prefer typed models and typed collections.

Prefer immutable state.

Use const constructors where appropriate.

Do not use BuildContext after an asynchronous gap without verifying that the widget remains mounted.

Do not perform expensive synchronous work on the UI thread.

Do not place network calls inside build().

Do not create controllers repeatedly inside build().

Dispose resources when ownership requires disposal.

Follow the project's supported Flutter and Dart versions.

State Management

Relvio uses Riverpod.

Riverpod is the approved application state management solution.

Rules:

Keep providers focused.
Prefer feature-local providers.
Avoid unnecessary global state.
Keep business logic outside widgets.
Use immutable state.
Represent loading, success, and error states explicitly.
Dispose temporary state when appropriate.
Preserve state only when there is a product reason.
Avoid provider dependencies that create circular behaviour.
Avoid using providers as generic global variable containers.

Controllers or notifiers coordinate presentation state and application actions.

Repositories handle data access.

Widgets render state and send user intent to controllers or notifiers.

Riverpod Provider Naming

Provider names should communicate their responsibility.

Examples:

peopleRepositoryProvider
peopleListControllerProvider
personProfileProvider
activeOrganizationProvider

Avoid vague names:

dataProvider
managerProvider
mainProvider
stateProvider1
UI Standards

The approved Relvio UI is frozen for v1 unless a genuine usability or technical issue is identified.

Do not redesign approved screens during implementation.

All Flutter UI must follow the approved:

Color system
Typography
Spacing system
Border radius
Shadows
Buttons
Inputs
Card system
Iconography
Navigation
Visual hierarchy

Do not invent colors.

Do not hardcode repeated spacing values.

Do not create one-off button styles when an approved component exists.

Reusable visual rules must come from the theme or design token system.

Widget Standards

Widgets should:

Have one clear responsibility.
Remain readable.
Be reusable when reuse is genuine.
Avoid business logic.
Avoid direct API access.

Large screens should be decomposed into meaningful sections.

Example:

PersonProfileScreen
├── PersonProfileHeader
├── JourneyStageCard
├── AttendanceSummaryCard
├── CommunitiesSection
├── FollowUpsSection
└── RecentActivitySection

Do not split every small widget into a separate file merely to reduce line count.

Split widgets when doing so improves:

Readability
Reuse
Testing
Responsibility boundaries
Responsive Layout

The application must not assume one fixed device size.

UI must handle:

Small phones
Standard phones
Large phones
Text scaling
Safe areas
Keyboard visibility

Avoid using fixed dimensions copied directly from design images when they break responsive behaviour.

The approved UI images are visual references, not pixel-coordinate specifications.

Use Flutter layout systems appropriately.

Examples:

Expanded
Flexible
LayoutBuilder
MediaQuery
SafeArea
Scrollable layouts

Avoid unnecessary device-specific conditions.

Loading States

Loading behaviour is implemented during development.

Use the appropriate loading pattern for the context.

Examples:

Skeleton or shimmer for content-heavy screens
Inline progress for local actions
Button loading state for submissions
Pull-to-refresh indicators
Full-screen loading only when the entire application state genuinely requires it

Do not block the entire screen for a small background action.

Prevent duplicate submissions while an action is processing.

Empty States

Features must handle empty data intentionally.

Examples:

No people
No events
No conversations
No notifications
No attendance records
No reports

Empty states should:

Explain the current state.
Provide an action when appropriate.
Follow the Relvio design language.

Do not display a blank screen for an empty collection.

Error Handling

Errors must be handled intentionally.

The Flutter application must use machine-readable API error codes where available.

Example:

PERSON_EMAIL_EXISTS
AUTH_SESSION_EXPIRED
PERMISSION_DENIED
ATTENDANCE_ALREADY_RECORDED

Do not parse human-readable API error messages to determine application behaviour.

User messages should be clear and contextual.

Avoid:

Something went wrong.

Prefer:

Unable to save this event. Please try again.

Technical details must not be exposed to users.

Expected application states should distinguish:

Initial
Loading
Success
Empty
Error

Where relevant, also support:

Refreshing
Paginating
Submitting
API Standards

The approved API Specification is the source of truth for frontend-backend communication.

Flutter must not invent endpoints.

All API calls must go through the approved data layer.

Screens and widgets must not call HTTP clients directly.

The API layer must:

Attach authentication credentials.
Use the approved base URL.
Handle API versioning.
Decode standard response structures.
Map standard API errors.
Support request cancellation where appropriate.
Handle session expiration.
Support idempotency keys for required operations.

Organization-scoped requests must use the active organization context.

Never use a cached organization identifier without validating the current application context.

Models and Serialization

API models must be strongly typed.

Serialization should follow the approved project tooling.

Generated serialization code must not be manually edited.

API response models and domain entities should remain separate when their responsibilities differ.

Do not expose raw JSON maps throughout the application.

Avoid:

Map<String, dynamic> person

Prefer:

Person person

External API fields should be mapped deliberately.

Do not allow backend naming conventions to leak unpredictably across the UI layer.

Organization Isolation

Relvio is a multi-organization application.

Organization isolation is a critical engineering requirement.

Every organization-owned operation must use the active organization context.

Frontend filtering is not a security boundary.

The backend remains responsible for enforcing organization access.

The Flutter application must never merge cached organization-owned data between organizations.

When switching organizations:

Organization-scoped state must be invalidated.
Organization-scoped providers must refresh.
Organization-scoped caches must be separated or cleared.
The UI must not temporarily display data from the previous organization.

Cross-organization data leakage is a critical severity defect.

Authentication and Sessions

Authentication state must have a single authoritative source.

The application must handle:

Authenticated sessions
Unauthenticated sessions
Session refresh
Session expiration
Logout
Revoked sessions

Do not store passwords.

Sensitive authentication material must use approved secure storage.

Do not log access tokens or refresh tokens.

When a session expires, the application should follow the approved authentication flow.

Logging

Application logs are for technical diagnostics.

Use structured and intentional logging.

Appropriate examples:

Authentication flow failed
API request failed
Offline synchronization failed
Unexpected state transition
Serialization failure

Business activity such as:

Person created
Attendance recorded
Journey stage changed
User invited

belongs primarily in backend activity or audit systems where required.

Do not confuse application logs with audit logs.

Never log:

Passwords
Access tokens
Refresh tokens
Password reset tokens
Invitation secrets
Sensitive request headers
Full sensitive user records

Debug logging must not expose sensitive data.

Comments

Write comments to explain decisions, constraints, or non-obvious behaviour.

Avoid comments that simply repeat the code.

Bad:

// Increment counter
counter++;

Useful:

// Preserve the previous organization ID so scoped providers
// can be invalidated before loading the next workspace.

Prefer expressive code over excessive comments.

Documentation

Major architectural or behavioural decisions should be documented.

Do not create a new Markdown document for every implementation detail.

Update an existing approved document when the information belongs there.

Use the Decision Log for significant architectural decisions.

Feature code should only require additional documentation when the behaviour is genuinely complex or non-obvious.

Avoid documentation duplication.

Generated Code

Generated files must be treated according to their generating tool.

Do not manually edit generated files.

Examples may include:

*.g.dart
*.freezed.dart

Generated code should be recreated using the approved generation command.

Generated code must remain reproducible.

If generated output is incorrect, fix the source declaration or configuration.

Code Formatting

Use the official Dart formatter.

Before code is considered complete:

dart format

must pass for relevant code.

Do not manually align code against formatter behaviour.

Never commit intentionally unformatted Dart code.

Static Analysis

The Flutter analyzer must pass.

Before a feature is complete:

flutter analyze

must report no unresolved analyzer errors.

Warnings should be reviewed.

Do not suppress analyzer rules merely to make checks pass without understanding the issue.

Any lint suppression must have a clear reason.

Dependencies

Before adding a package, determine:

Is the package necessary?
Does Flutter or Dart already provide the capability?
Is the package actively maintained?
Does it support the project's Flutter version?
Does it have known security concerns?
Does it significantly increase application size?
Is there already an approved package solving the same problem?

Avoid duplicate packages with overlapping responsibilities.

AI coding assistants must not add dependencies silently.

Dependency changes must be visible in the implementation summary.

Do not upgrade unrelated dependencies during feature work.

Performance

Avoid:

Unnecessary widget rebuilds
Duplicate API requests
Large synchronous operations on the UI thread
Loading entire datasets when pagination is available
Repeated expensive calculations during build()
Unbounded lists
Unnecessary image memory usage

Use pagination for large datasets.

Use lazy list rendering.

Optimize only after understanding the problem.

Do not add complex caching or optimization systems without evidence or an approved requirement.

Offline Behaviour

Offline behaviour must be intentional.

Do not assume that every failed request means the user is offline.

Features approved for offline support must follow their specific synchronization strategy.

Attendance offline synchronization is a sensitive workflow.

Offline attendance operations must preserve:

Organization context
Event context
Person identity
Timestamp
Idempotency key
Sync state

Retries must not create duplicate attendance records.

Do not invent offline support for unrelated modules without approval.

Security

Never:

Store passwords.
Hardcode production secrets.
Commit secret keys.
Trust client-side validation.
Treat hidden UI as authorization.
Log authentication tokens.
Expose internal server errors.
Bypass permission checks.
Mix organization-owned data.
Disable security controls to make development easier.

Public configuration values and secret credentials must be treated differently.

Secrets belong in approved secret-management systems.

Server-side authorization is mandatory.

Database Changes

The approved Database Design is the source of truth.

Do not modify database structure as part of unrelated feature work.

Database changes must be intentional.

Schema changes must consider:

Existing data
Organization isolation
Constraints
Indexes
Migration safety
Rollback or recovery strategy
API compatibility

Do not allow Flutter implementation needs to silently redefine database architecture.

API Changes

The approved API Specification is the source of truth.

Do not rename, remove, or invent endpoints during frontend implementation.

If an API contract is insufficient:

Identify the missing requirement.
Document the conflict.
Update the API specification.
Implement the approved change.

Do not create frontend workarounds for missing backend business rules.

Git Workflow

Use short-lived branches.

Recommended branch names:

feature/people-directory
feature/live-check-in
feature/event-creation
bugfix/login-session
bugfix/attendance-duplicate
hotfix/critical-auth-error
refactor/people-state
docs/api-specification

Branch names should describe the work clearly.

Avoid long-lived feature branches where possible.

Commit Messages

Use Conventional Commit style.

Examples:

feat: add people directory

fix: prevent duplicate attendance check-in

refactor: simplify authentication state

test: add attendance repository tests

docs: update api specification

chore: update flutter configuration

Commits should represent logical units of work.

Avoid meaningless messages such as:

update

changes

fix stuff

final

working
Pull Requests

Where pull requests are used, include:

Summary
Scope
Screenshots for UI changes
Testing performed
Known limitations
Related issue or task

The pull request should not contain unrelated changes.

Testing Standards

Testing requirements are defined in detail by the approved Testing Strategy.

At minimum, before feature completion:

The project compiles.
Relevant tests pass.
Flutter analyzer passes.
Critical flows are manually verified.
Existing affected flows are regression tested.
Loading states are verified.
Empty states are verified.
Error states are verified.
Permission behaviour is verified where applicable.

Critical business logic should not rely only on manual testing.

Definition of Done

A feature is complete when:

It satisfies the approved product requirement.
It follows the approved UI.
It follows the System Architecture.
It follows the Folder Structure.
It follows the API Specification.
It follows the Database Design where applicable.
It follows these Engineering Standards.
Relevant tests pass.
Static analysis passes.
Loading behaviour is implemented.
Empty states are handled.
Error states are handled.
Permission behaviour is correct.
Organization isolation is preserved.
No known critical defect remains.
Documentation is updated when necessary.
The implementation has been reviewed.

A screen merely rendering successfully does not mean the feature is complete.

Code Review Checklist

Before approving implementation, verify:

Does the code solve the requested requirement?
Does it follow the approved architecture?
Does it reuse existing components appropriately?
Is business logic outside widgets?
Are API calls outside screens?
Is state ownership clear?
Are errors handled?
Are loading states handled?
Are empty states handled?
Are permissions respected?
Is organization context handled safely?
Are sensitive values protected?
Are tests sufficient for critical logic?
Were unnecessary dependencies added?
Were unrelated files changed?
Did the implementation silently alter architecture?

Any cross-organization data exposure must block approval.

Engineering Values

The Relvio engineering team values:

Simplicity
Clarity
Quality
Consistency
Security
Reliability
Maintainability
Thoughtful iteration

The goal is not to produce the most code.

The goal is to build Relvio correctly and keep it understandable as the product grows.