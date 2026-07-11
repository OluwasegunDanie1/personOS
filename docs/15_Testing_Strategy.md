---
Document: Testing Strategy
Version: 0.2
Status: Approved
Project: Relvio
Owner: Engineering Team
---

# Testing Strategy

## Purpose

This document defines how Relvio is tested during development and before release.

The goal is to detect defects early, protect critical business workflows, prevent regressions, and ship reliable software.

Relvio is a multi-organization People Operating System.

Testing must give special attention to:

- Authentication
- Organization isolation
- Roles and permissions
- Journey history
- Attendance integrity
- Offline attendance synchronization
- Communication delivery actions
- Reports and calculations
- Session handling

Testing is part of feature development.

It is not a final activity performed only before release.

---

# Testing Scope

Relvio v1 is a Flutter mobile application.

Primary supported platforms:

- Android
- iOS

Testing must prioritize mobile behaviour.

Web and desktop testing are outside the Relvio v1 scope unless those platforms are officially added to the product roadmap.

Backend APIs and database behaviour must be tested independently of the Flutter UI.

---

# Testing Principles

Relvio follows these testing principles:

1. Test behaviour, not implementation details.
2. Critical business rules require automated tests.
3. Bugs should be reproduced before they are fixed where practical.
4. Every bug fix should consider a regression test.
5. Organization isolation is a critical security boundary.
6. Permission behaviour must be tested server-side.
7. Client-side validation does not replace backend validation.
8. Loading, empty, error, and success states are part of a feature.
9. Tests must be deterministic.
10. Tests must not depend on production data.
11. A screen rendering successfully does not prove the feature works.
12. AI-generated code must meet the same testing requirements as human-written code.

Quality takes priority over rushing incomplete features into release.

---

# Testing Pyramid

Relvio should prefer a balanced testing strategy.

```text
        End-to-End
           /\
          /  \
     Integration
        /      \
       /        \
  Unit / Widget Tests


  Most tests should be:

Unit tests
Domain tests
Repository tests
Focused widget tests

A smaller number should be:

Integration tests
End-to-end tests

Do not attempt to test every possible behaviour through full end-to-end tests.

Test Types
Unit Testing

Unit tests verify isolated business behaviour.

Examples:

Input validation
Journey transition rules
Attendance calculations
Report calculations
Permission evaluation
Pagination state
Error mapping
Date handling
Organization switching logic
Idempotency key generation
Offline sync state transitions

Unit tests should:

Run quickly
Be deterministic
Avoid real network requests
Avoid production services
Test observable behaviour
Domain Testing

Critical domain behaviour must be tested directly.

Examples:

A journey transition creates history.
Journey history is not overwritten.
Duplicate attendance is rejected.
Attendance status values are valid.
An event cancellation preserves the event.
Protected system roles cannot be deleted.
Organization-owned data remains organization scoped.

Domain tests are required for business rules that protect data integrity.

Repository Testing

Repositories must be tested where they contain:

API coordination
Data mapping
Pagination behaviour
Cache behaviour
Error mapping
Offline synchronization logic

Examples:

PeopleRepository
AttendanceRepository
EventsRepository
AuthenticationRepository

Repository tests should verify:

Successful responses
API errors
Validation errors
Session errors
Permission errors
Serialization failures
Empty responses
Pagination metadata

External services should normally be replaced with fakes or controlled test doubles.

Riverpod State Testing

Controllers and notifiers must be tested for important state transitions.

Examples:

Initial
↓
Loading
↓
Success
Initial
↓
Loading
↓
Error

Where relevant, test:

Initial state
Loading
Success
Empty
Error
Refreshing
Paginating
Submitting

Verify that duplicate submissions are prevented where required.

Verify that organization-scoped providers do not preserve data incorrectly after an organization switch.

Widget Testing

Widget tests verify important Flutter UI behaviour.

Examples:

Form validation messages
Button enabled and disabled states
Loading buttons
Empty states
Error states
Permission-controlled actions
Dialog behaviour
Bottom navigation
Search interactions
Filter selection
Journey stage display
Attendance status controls

Widget tests should focus on behaviour.

Avoid fragile tests that depend unnecessarily on exact widget tree structure.

Prefer stable keys or semantic identifiers where test targeting is required.

Golden Testing

Golden tests may be used selectively for high-value shared visual components.

Recommended candidates:

Primary buttons
Input fields
Cards
Empty states
Error states
Journey timeline components
Attendance status controls
Navigation components

Golden testing is not required for every screen.

The approved UI images remain visual references.

Golden tests should protect reusable visual systems rather than create a maintenance burden for every page.

Integration Testing

Integration tests verify multiple application layers working together.

Critical integration flows include:

Registration and authentication
Login and session restoration
Session expiration
Organization creation
Organization invitation acceptance
Organization switching
Person creation
Journey stage transition
Event creation
Live attendance check-in
Manual attendance submission
Follow-up completion
Announcement sending
Role permission updates

Integration tests should use controlled environments.

Never run integration tests against the production database.

Backend API Testing

Backend endpoints must be tested independently.

API tests must verify:

Authentication
Request validation
Standard response format
Machine-readable error codes
Organization membership
Permission enforcement
Organization scoping
HTTP status codes
Pagination
Filtering
Sorting
Idempotency
Rate limiting where applicable

Example:

POST /organizations/{organizationId}/people

must be tested for:

Valid authorized request
Missing authentication
Invalid organization
Non-member access
Missing permission
Invalid request data
Duplicate email behaviour
Successful creation

The Flutter client must not be required to compensate for missing backend tests.

Database Testing

Database-related tests must verify important constraints and relationships.

Critical areas include:

Organization foreign keys
Unique constraints
Attendance uniqueness
Journey history integrity
Soft deletion behaviour
Invitation uniqueness and expiration
Role relationships
Permission relationships
Cascade and restricted deletion behaviour

Migration tests should verify that schema changes can be applied safely.

Where practical, database tests should use a temporary PostgreSQL test database.

Never use the production database for automated tests.

Organization Isolation Testing

Organization isolation is a critical security requirement.

Every organization-owned resource must be tested for cross-organization access.

Example scenario:

Organization A
- User A
- Person A

Organization B
- User B
- Person B

Verify:

User A can access Person A when permitted.
User A cannot access Person B.
User B can access Person B when permitted.
User B cannot access Person A.

Test isolation for:

People
Journey stages
Journey history
Communities
Events
Attendance
Follow-ups
Conversations
Messages
Announcements
Campaigns
Roles
Reports
Activity
Audit logs
Organization settings

A cross-organization data leak is a Critical severity defect.

No release may proceed with a known organization isolation defect.

Roles and Permissions Testing

Permissions must be tested on the backend.

The Flutter UI hiding an action is not sufficient.

Test permissions such as:

people.view
people.create
people.update
people.delete

events.view
events.create
events.update
events.delete

attendance.view
attendance.record

communication.view
communication.send

reports.view
reports.export

organization.update
roles.manage
billing.manage
settings.manage

For protected actions, verify:

An authorized role succeeds.
An unauthorized role receives 403 Forbidden.
The operation does not modify data after permission failure.

System role protections must also be tested.

Authentication Testing

Verify:

Registration
Login
Invalid credentials
Logout
Forgot password
Password reset
Session restoration
Access token expiration
Session refresh
Refresh failure
Revoked session
Unauthorized API access
Secure logout behaviour

Forgot-password responses must not reveal whether an email exists.

Authentication tokens must never appear in test logs or screenshots.

Live Local Authentication Fixture

In addition to automated test fixtures (see Test Data), Relvio approves one separate, explicit, development-only command that creates exactly one controlled global User. Its sole purpose is manual, live local verification of the full authentication lifecycle against a real local backend and local database: login, refresh rotation, reuse of the revoked old refresh token and family revocation, a fresh login, logout, and reuse of the logged-out refresh token.

This fixture is test/infrastructure support only. It is not public registration, product onboarding, or a general-purpose database seed. Its exact scope, input, idempotency, and execution-environment authority are governed by Deployment.md and 16_Security.md.

The fixture must not run automatically as part of the automated test suite, build, or CI pipeline. It requires an explicit developer command and is separate from the standard `npm test` run.

Organization Testing

Verify:

Create organization
View organization
Update organization
Delete organization behaviour
Organization membership
Invitation creation
Invitation acceptance
Expired invitation
Invalid invitation
Revoked invitation
Member role update
Member removal
Organization switching

When switching organizations, verify that:

Previous organization data disappears immediately.
Scoped providers are invalidated.
Cached organization data is not mixed.
New organization data loads correctly.
People Module Testing

Verify:

List people
Cursor pagination
Search
Journey stage filter
Community filter
Sorting
Create person
View person
Update person
Delete person
Empty state
Loading state
Error state

Verify duplicate-person rules according to approved backend behaviour.

Test person profile sections with partial or missing optional data.

Journey Testing

Verify:

List journey stages
Create journey stage
Update journey stage
Reorder journey stages
Delete journey stage behaviour
Current person stage
Create journey transition
Journey history ordering
Journey transition timestamps
Journey transition metadata

Critical rule:

Changing a person's journey stage must create history.

Verify that previous journey history remains unchanged.

Journey history must never be silently overwritten.

Community Testing

Verify:

List communities
Create community
View community
Update community
Delete community
Add person to community
Remove person from community
Community member listing

Verify organization isolation for all community membership operations.

Event Testing

Verify:

List events
Search
Status filters
Category filters
Date filters
Create event
View event
Update event
Delete event
Cancel event
Event categories
Event templates

Date and time testing must include:

Start before end
Time zone handling
Date boundary behaviour
Invalid date ranges

Cancelling an event must preserve the event record.

Attendance Testing

Attendance is a critical Relvio workflow.

Verify:

Event attendance list
Search-based check-in
Manual check-in
QR check-in
Walk-in visitor
Manual attendance submission
Present status
Absent status
Excused status
Visitor status
Person attendance history
Attendance summary
Attendance calculations

Critical tests:

Duplicate attendance prevention
Database uniqueness enforcement
Idempotency retry
Concurrent duplicate requests
Incorrect organization
Incorrect event
Permission denial

Example:

Request 1:
Idempotency-Key: abc123

Request 2:
Idempotency-Key: abc123

The requests must not create two attendance records.

Offline Attendance Testing

Offline attendance synchronization requires dedicated tests.

Verify:

Check-in while offline
Multiple offline check-ins
Application restart before synchronization
Synchronization after reconnecting
Partial synchronization failure
Retry after failure
Duplicate retry
Organization switch with pending records
Event context preservation
Timestamp preservation
Idempotency key preservation

Critical rule:

Offline synchronization must never create duplicate attendance records.

Pending offline attendance must not be silently lost.

Follow-Up Testing

Verify:

List follow-ups
Filter follow-ups
Create follow-up
View follow-up
Update follow-up
Complete follow-up
Assigned user
Due date
Person relationship

Completing a follow-up should create the expected activity where required.

Test overdue date behaviour.

Communication Testing
Conversations and Messages

Verify:

List conversations
Create conversation
View conversation
List messages
Send message
Mark conversation read
Cursor pagination
Empty conversation state

Where delivery status exists, verify supported status transitions.

Announcements

Verify:

Create announcement
Save draft
Update draft
Send announcement
Schedule announcement
Audience selection
Delivery options

Critical tests:

Duplicate send retry
Idempotency
Permission enforcement
Invalid audience
Email Campaigns

Verify:

List campaigns
Create campaign
View campaign
Update campaign
Send campaign
Campaign analytics

Verify analytics mapping for:

Recipients
Delivered
Opened
Clicked
Failed

Campaign sending must test idempotent retries.

Notifications Testing

Verify:

List notifications
Category filters
Read filters
Cursor pagination
Mark notification read
Mark all read
Clear read notifications
Empty state

Notifications must remain scoped to the authenticated user.

A user must never access another user's notifications.

Reports Testing

Verify:

Dashboard summary
Attendance report
Growth report
Follow-up report
Date filtering
Event filtering
Community filtering where supported
Empty reports
Report calculations

Report values should be tested against known datasets.

Do not test report accuracy only by visually inspecting charts.

Report Export Testing

Verify:

PDF export request
XLSX export request
CSV export request
Invalid format
Permission denial
Large asynchronous export
Duplicate export retry

Generated exports must contain data only from the requested organization.

Cross-organization export leakage is a Critical severity defect.

Search Testing

Verify global search across supported resources.

Examples:

People
Events
Communities
Conversations
Notes

Test:

Exact match
Partial match
Case handling
Empty query
No results
Pagination where applicable
Permission filtering
Organization isolation

Search must never reveal inaccessible resource names or metadata.

Error State Testing

Verify user-facing behaviour for:

No internet
Request timeout
Server error
Session expired
Permission denied
Resource not found
Validation error
Rate limit
Serialization error

The application must use API error codes where available.

Technical backend errors must not be displayed directly to users.

Loading State Testing

Verify:

Initial screen loading
Skeleton or shimmer state
Button loading state
Refreshing
Pagination loading
Submission loading

Verify that users cannot accidentally submit sensitive actions multiple times while loading.

Examples:

Create person
Record attendance
Send announcement
Send campaign
Accept invitation
Empty State Testing

Verify intentional empty states for:

People
Events
Attendance
Conversations
Notifications
Reports
Communities
Follow-ups

Empty states must not appear as application errors.

Where appropriate, verify the primary empty-state action.

Network Condition Testing

Test under:

Normal connection
Slow connection
No connection
Connection loss during request
Connection restored after failure

Expected behaviour depends on the feature.

Do not assume every feature supports offline writes.

Only approved offline workflows should queue write operations.

Performance Testing

Performance testing should focus on realistic product behaviour.

Important areas:

Application startup
Dashboard loading
People directory
People search
Long people lists
Event lists
Live check-in
Manual attendance lists
Conversation message lists
Notification lists
Reports

Test with realistic large datasets.

Examples:

10,000 people
1,000 events
100,000 attendance records
Large conversation histories
Large notification histories

The application must use pagination and lazy rendering where required.

Performance expectations should be measured on representative mobile devices.

Responsive and Device Testing

Relvio v1 must be tested on representative mobile layouts.

Test:

Small Android phone
Standard Android phone
Large Android phone
Standard iPhone
Large iPhone

Verify:

Safe areas
Keyboard behaviour
Text scaling
Long names
Long organization names
Long event names
Large numbers
Empty content
Scrolling
Bottom navigation
Sticky actions

Tablet support may be tested for graceful behaviour but is not a Relvio v1 optimization target unless product scope changes.

Accessibility Testing

Verify:

Text scaling
Touch target sizes
Screen reader labels for important actions
Meaningful semantic labels
Sufficient visual distinction for states
Keyboard focus where applicable
Error messages associated with fields

Color must not be the only way critical state is communicated.

Examples:

Attendance status
Journey stage completion
Error state
Permission state
Manual Testing

Developers must manually verify the feature before marking implementation complete.

Manual testing should cover the primary happy path and important failure paths.

Examples:

Create a person.
Move the person to another journey stage.
Create an event.
Check the person into the event.
Complete a follow-up.
Switch organizations.
Verify the previous organization's data is no longer visible.

Manual testing does not replace automated tests for critical business rules.

User Acceptance Testing

Before public release, representative users should test important workflows.

Target users may include:

Organization owners
Administrators
Team leads
Volunteers

UAT should focus on whether users can complete tasks without developer guidance.

Important workflows:

Create an organization
Invite a team member
Add a person
Understand the person's journey
Create an event
Start check-in
Record attendance
Find people needing follow-up
Send an announcement
Understand attendance insights

UAT feedback should be categorized as:

Defect
Usability issue
Product request
Training or clarity issue

Product requests discovered during UAT must not automatically expand Relvio v1 scope.

Regression Testing

Regression testing is required before release.

Critical regression flows:

Application startup
Login
Session restoration
Organization switching
Dashboard
People directory
Person profile
Journey transitions
Event creation
Live check-in
Manual attendance
Attendance reports
Messages
Announcements
Notifications
Workspace
Roles and permissions

High-risk bug fixes should include focused regression tests.

Bug Severity
Critical — P0

The application or critical security boundary is compromised.

Examples:

Cross-organization data exposure
Data loss
Authentication bypass
Permission bypass
Duplicate attendance corruption at scale
Application cannot start for most users

Release is blocked.

High — P1

A major workflow is unavailable or seriously incorrect.

Examples:

Login fails for valid users
Cannot create people
Cannot create events
Attendance does not save
Journey history is overwritten
Organization switching displays stale data

Release is normally blocked.

Medium — P2

A feature works but has a meaningful defect.

Examples:

Incorrect validation
Filter failure
Incorrect non-critical report display
Broken empty-state action
Layout issue affecting usability

Release decision depends on impact and workaround.

Low — P3

Minor visual or usability issue.

Examples:

Small spacing inconsistency
Minor animation issue
Non-blocking text issue

Does not normally block release.

Bug Report Requirements

A useful bug report should contain:

Title
Environment
App version
User role
Organization context
Preconditions
Reproduction steps
Expected result
Actual result
Screenshots or video where useful
Relevant non-sensitive logs
Severity

Never include passwords, access tokens, refresh tokens, or other secrets in bug reports.

Test Data

Automated tests must use controlled test data.

Do not depend on production users or organizations.

Test factories or fixtures should create predictable data.

Organization isolation tests must clearly identify organization ownership.

Example:

org_a
user_a
person_a

org_b
user_b
person_b

Test data should be easy to understand while debugging failures.

Test Environments

Relvio should maintain separated environments.

Recommended:

Development
Testing / CI
Staging
Production

Tests must not write to production systems.

Integration and end-to-end tests should use Testing or Staging environments as appropriate.

Environment configuration must be explicit.

Continuous Integration Quality Gates

Where CI is configured, pull requests or protected branches should verify:

dart format
flutter analyze
flutter test

Backend quality gates should run the approved backend test and static analysis commands.

Critical test failures must block merging.

Do not disable failing tests merely to make CI pass.

Flaky tests must be investigated and fixed.

Release Testing

Before release:

Critical automated tests must pass.
High-risk integration flows must pass.
Regression testing must be completed.
Organization isolation tests must pass.
Permission tests must pass.
Attendance integrity tests must pass.
No known P0 defect may remain.
P1 defects must be resolved unless explicitly accepted through a documented release decision.
Release Checklist

Before deployment:

 Approved scope is complete
 Flutter project builds successfully
 No unresolved analyzer errors
 Automated tests pass
 Backend tests pass
 Critical integration flows pass
 Organization isolation verified
 Permissions verified
 Attendance duplicate prevention verified
 Offline attendance sync verified if included in the release
 Loading states verified
 Empty states verified
 Error states verified
 Accessibility basics verified
 Regression testing completed
 No P0 bugs remain
 P1 bugs resolved or explicitly accepted
 Documentation updated where necessary
 Version number updated
 Release notes prepared
 Staging build approved
Success Criteria

The Relvio testing strategy is successful when:

Critical business workflows are protected by automated tests.
Organization isolation is continuously verified.
Permission failures are detected before release.
Attendance duplication is prevented.
Journey history remains trustworthy.
Regressions are detected early.
Users can complete primary workflows reliably.
Releases do not depend only on manual confidence.
Test failures provide useful information to developers.

The goal is not to achieve an arbitrary test coverage percentage.

The goal is to protect the behaviour and data that matter most to Relvio.