The immediate priority is to finalize the engineering foundation and begin implementation of the approved Relvio v1 product.

Phase 0 — Product Foundation ✅
Goal

Define the product before implementation.

Deliverables
Product Charter
Product Blueprint
Product Strategy
Market Research
User Personas
Product Requirements
MVP Scope
Information Architecture
User Flows
Feature Backlog
Database Design
API Specification
Engineering Standards
Testing Strategy
Security Strategy
Status
Completed
Phase 1 — Brand and Product Design ✅
Goal

Create a complete and consistent Relvio product experience.

Deliverables
Brand Identity
Product Name
Logo
App Icon
Color System
Typography
Spacing System
Design System
Flutter Theme Direction
Component Direction
User Flows
Mobile UI
High-Fidelity Screens
Approved Product Areas
Splash
Welcome
Onboarding
Authentication
Organization Setup
Dashboard
People
Journey
Communities
Events
Attendance
Follow-Ups
Messages
Announcements
Email Campaigns
Notifications
Reports
Profile
Organization Settings
Roles and Permissions
Workspace
Status
Completed

The approved Relvio v1 UI is frozen.

The UI must not be redesigned during development unless a genuine usability or technical issue is identified.

Phase 2 — Engineering Foundation
Goal

Create the technical foundation required to build Relvio safely and consistently.

Deliverables
Final System Architecture
Final Database Design
Final API Specification
Final Engineering Standards
Final Testing Strategy
Final Security Strategy
Approved Folder Structure
Flutter Project Setup
Backend Project Setup
Environment Configuration
PostgreSQL Setup
API Foundation
Authentication Foundation
Logging Foundation
Error Handling Foundation
Continuous Integration Foundation
Success Criteria
Flutter project builds successfully.
Backend project runs successfully.
Development environment is documented.
PostgreSQL database is available.
API versioning is configured.
Authentication architecture is implemented.
Organization isolation foundation exists.
Engineering quality checks run successfully.
Status
Current Phase
Phase 3 — Identity and Organization Foundation
Goal

Allow users to securely access Relvio and create or join organizations.

Features
Registration
Login
Email Verification
Forgot Password
Password Reset
Session Refresh
Logout
Current User
Organization Creation
Organization Setup
Organization Invitations
Invitation Acceptance
Organization Membership
Active Organization Context
Organization Switching
Roles
Permissions
Success Criteria

A user can:

Create an account.
Authenticate securely.
Create an organization.
Complete organization setup.
Invite another user.
Join an organization.
Switch between organizations where applicable.

Organization data must remain fully isolated.

Phase 4 — People and Relationship Management
Goal

Build the core Relvio people operating system.

Features
People Directory
People Search
People Filters
Person Creation
Person Profile
Person Editing
Person Deletion Behaviour
Journey Stages
Journey Transitions
Journey History
Person Timeline
Communities
Community Membership
Follow-Ups
Follow-Up Assignment
Follow-Up Completion
Success Criteria

An organization can:

Add people.
Find people.
Understand a person's current journey stage.
View journey history.
Organize people into communities.
Assign follow-ups.
Track relationship activity.

Journey history must remain trustworthy and immutable according to the approved architecture.

Phase 5 — Events and Attendance
Goal

Allow organizations to create events and reliably record attendance.

Features
Event Directory
Event Creation
Event Editing
Event Cancellation
Event Categories
Event Templates
Attendance Dashboard
Live Check-In
Search Check-In
QR Check-In
Manual Check-In
Manual Attendance
Walk-In Visitors
Attendance History
Attendance Summary
Offline Attendance Queue
Attendance Synchronization
Success Criteria

An organization can:

Create an event.
Start attendance.
Find a person.
Check the person in.
Register a walk-in visitor.
Record manual attendance.
View attendance summaries.
Continue approved attendance workflows during temporary connectivity loss.

Duplicate attendance must be prevented.

Offline synchronization must not create duplicate attendance records.

Phase 6 — Communication
Goal

Help organizations communicate with their people and teams.

Features
Conversations
Messages
Conversation Read State
Announcements
Announcement Drafts
Announcement Audience Selection
Scheduled Announcements
Email Campaigns
Campaign Sending
Campaign Analytics
In-App Notifications
Push Notification Foundation
Success Criteria

Authorized users can:

View conversations.
Send supported messages.
Create announcements.
Save announcement drafts.
Send announcements.
Schedule supported announcements.
Create email campaigns.
View campaign analytics.
Receive application notifications.

Communication permissions must be enforced by the backend.

Duplicate send operations must be protected through approved idempotency behaviour.

Phase 7 — Dashboard, Reports, and Workspace
Goal

Complete the operational and administrative Relvio experience.

Features
Dashboard
Organization Overview
People Insights
Attendance Insights
Follow-Up Summary
Recent Activity
Upcoming Events
Reports
Attendance Reports
Growth Reports
Follow-Up Reports
Date Filtering
Report Export
PDF Export
XLSX Export
CSV Export
Workspace
Organization Settings
Branding Settings
Localization Settings
Attendance Settings
Communication Preferences
My Profile
Security
Appearance
Roles and Permissions
Activity
Audit Logs
Success Criteria

Organization leaders can understand current activity, review important metrics, export supported reports, and manage their workspace.

Reports must return organization-scoped data only.

Phase 8 — Internal Alpha
Goal

Test the complete Relvio v1 product internally before inviting external organizations.

Activities
Complete critical automated tests.
Run integration tests.
Test organization isolation.
Test roles and permissions.
Test attendance integrity.
Test offline attendance synchronization.
Perform regression testing.
Review crash reports.
Test on representative Android devices.
Test on representative iOS devices.
Fix P0 and P1 defects.
Success Criteria
No known P0 defects.
Critical workflows pass.
Organization isolation tests pass.
Permission tests pass.
Attendance integrity tests pass.
Application is stable enough for controlled external testing.
Phase 9 — Private Beta
Goal

Validate Relvio with a small number of real organizations.

Initial Beta Focus

Relvio should initially prioritize people-centered organizations with strong relationship and attendance workflows.

Potential early adopters include:

Churches
Ministries
NGOs
Communities
Associations

The product architecture must remain organization-neutral.

Relvio must not become technically dependent on church-specific terminology or business rules unless explicitly approved.

Activities
Select beta organizations.
Onboard organization owners.
Observe onboarding behaviour.
Measure feature usage.
Collect structured feedback.
Review support requests.
Review application crashes.
Identify confusing workflows.
Fix high-impact defects.
Core Beta Workflows
Create organization
Invite team member
Add person
Track journey
Create event
Record attendance
Assign follow-up
Send announcement
Review dashboard
View reports
Success Criteria
Organizations complete primary workflows.
No recurring critical data integrity issues.
Product terminology is understood.
Attendance workflows are reliable.
Journey functionality provides clear value.
Beta organizations return to the product.
Major usability blockers are identified.
Phase 10 — Launch Readiness
Goal

Prepare Relvio for public availability.

Activities
Resolve critical beta findings.
Finalize onboarding.
Finalize privacy documentation.
Finalize terms of service.
Finalize data retention decisions.
Complete production security review.
Complete production backup verification.
Configure production monitoring.
Configure crash reporting.
Configure analytics.
Prepare App Store assets.
Prepare Google Play assets.
Create product website or landing page.
Create support process.
Prepare release notes.
Success Criteria
Production infrastructure is approved.
No known P0 defects remain.
P1 defects are resolved or formally accepted.
Privacy and legal documents are available.
Monitoring is active.
Backup restoration has been tested.
Store submissions are ready.
Phase 11 — Public Launch
Goal

Release Relvio to the public.

Activities
Publish Android application.
Publish iOS application.
Launch Relvio website.
Begin product marketing.
Onboard new organizations.
Provide customer support.
Monitor production health.
Review product analytics.
Review activation and retention.
Success Criteria
Organizations successfully onboard.
Core workflows remain stable.
Production incidents are handled quickly.
Early users demonstrate repeat product usage.
Product feedback produces clear priorities.
Phase 12 — Product Growth
Goal

Improve Relvio based on real customer behaviour and validated needs.

Potential Features
Custom Fields
Journey Templates
Advanced Import
Advanced Export
Advanced Search
Saved Filters
Additional Attendance Workflows
Advanced Notification Preferences
Multiple Branches
Enhanced Organization Switching
Additional Communication Providers
Advanced Reporting

Features must be prioritized using evidence.

A feature must not enter development merely because it appears useful.

Phase 13 — Automation
Goal

Reduce repetitive administrative work.

Potential Features
Workflow Builder
Automatic Follow-Ups
Smart Reminders
Rules Engine
Automated Journey Actions
Scheduled Operational Tasks
Trigger-Based Communication

Example:

When a person enters "New Member"
↓
Create a follow-up
↓
Assign the follow-up to the responsible team
↓
Schedule a reminder

Automation must remain explainable and auditable.

Phase 14 — Integrations
Goal

Connect Relvio with external tools used by organizations.

Potential Integrations
Google Calendar
Microsoft Outlook
Zoom
Slack
Microsoft Teams
Zapier
Payment Providers
Email Providers
SMS Providers
WhatsApp Providers

Integrations must be prioritized based on customer demand and provider cost.

Relvio must not add paid third-party dependencies without understanding their operational cost.

Phase 15 — Enterprise
Goal

Support larger and more complex organizations.

Potential Features
Multiple Branches
Advanced Custom Roles
Enterprise Permissions
Advanced Audit Controls
Single Sign-On
Enterprise Identity Providers
Public API
Webhooks
IP Restrictions
Organization Security Policies
Advanced Data Retention
White Labeling
Enterprise Support

Enterprise functionality must not unnecessarily complicate the Relvio v1 architecture.

The v1 architecture should allow future growth without prematurely implementing enterprise complexity.

Long-Term Vision

Relvio should become the operating system for people-centered organizations.

The product should help organizations understand:

Who are our people?

Where are they in their journey?

How are they engaging?

Who needs attention?

What is happening in our organization?

What should we do next?

Relvio should not become only:

An attendance application
A church management application
An event application
A messaging application
A CRM clone

The long-term product value comes from connecting people, journeys, engagement, attendance, communication, and organizational action in one operating system.

Product Expansion Principle

Relvio may begin with organizations where the problem is easiest to validate.

However, the core product language and architecture should remain adaptable to:

Churches
NGOs
Communities
Associations
Schools
Ministries
Clubs
People-centered businesses

Industry-specific functionality should be introduced deliberately.

Do not hardcode one industry's assumptions into the core platform without approval.

Roadmap Prioritization

Before building a new feature, ask:

Does this solve a verified customer problem?
How many target organizations experience the problem?
How frequently does the problem occur?
Does the feature strengthen Relvio's core product vision?
Can the feature be maintained?
What is the engineering complexity?
What is the operational cost?
Does it introduce a paid external dependency?
Does it create security or privacy risk?
Is now the correct time to build it?

If the evidence is insufficient, the feature remains in the backlog.

Scope Protection

Roadmap ideas are not automatically approved features.

The following terms indicate potential future work:

Potential
Future
Possible
Planned for later
Under consideration

AI coding assistants must not implement roadmap features outside the current approved phase.

Claude or any other implementation assistant must follow the approved task scope.

Future roadmap items must not be silently added during feature development.

Current Build Order

The approved implementation order is:

Engineering Foundation
        ↓
Authentication
        ↓
Organizations
        ↓
Roles and Permissions
        ↓
People
        ↓
Journey
        ↓
Communities
        ↓
Follow-Ups
        ↓
Events
        ↓
Attendance
        ↓
Communication
        ↓
Notifications
        ↓
Dashboard
        ↓
Reports
        ↓
Workspace
        ↓
Internal Alpha
        ↓
Private Beta

This order may be adjusted when a technical dependency requires it.

Changes must be intentional.

Success Milestones
Milestone 1 — Product Foundation
Completed
Milestone 2 — Brand and UI
Completed
Milestone 3 — Engineering Foundation
Current
Milestone 4 — Core Platform

Authentication, organizations, roles, and permissions are operational.

Milestone 5 — People Operating System

People, Journey, Communities, and Follow-Ups are operational.

Milestone 6 — Events and Attendance

Event and attendance workflows are reliable.

Milestone 7 — Relvio v1 Feature Complete

Approved v1 modules are implemented.

Milestone 8 — Internal Alpha

Critical quality gates pass.

Milestone 9 — Private Beta

Real organizations use Relvio.

Milestone 10 — Public Launch

Relvio is publicly available.

Milestone 11 — Product Validation

Relvio demonstrates repeat usage and retention.

Milestone 12 — First 100 Paying Organizations

Relvio reaches its first major commercial milestone.

Milestone 13 — Market Expansion

Relvio validates use beyond its initial early-adopter segment.

Success Criteria

The roadmap is successful when:

Relvio reaches implementation without unnecessary scope expansion.
The approved v1 product is completed.
Critical product workflows are reliable.
Real organizations use Relvio repeatedly.
Product priorities are informed by evidence.
Technical architecture supports growth.
Future features do not distract from current product delivery.

The goal is not to build every possible feature.

The goal is to build the right Relvio, validate it, and grow deliberately.