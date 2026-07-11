---
Document: Feature Backlog
Version: 1.1
Status: Living Document
Project: Relvio
Owner: Product Team
---

# Feature Backlog

## Purpose

This document records potential Relvio product opportunities that are not part of the currently approved Relvio v1 implementation scope.

The backlog exists to preserve ideas without turning those ideas into approved features.

A feature appearing in this document is:

- Not approved for implementation
- Not part of the frozen Relvio v1 UI
- Not an approved API requirement
- Not an approved database requirement
- Not a roadmap commitment
- Not a release promise
- Not permission for an AI coding assistant to build the feature

Backlog items must move through product validation and explicit approval before they affect implementation documentation.

---

# Product Context

Relvio is a:

> **People Operating System**

Relvio helps people-centered organizations understand, organize, and strengthen relationships with the people they serve.

Churches and similar organizations are a strong initial validation market.

The core product remains organization-neutral.

The primary brand message is:

> **Build stronger relationships.**

Future feature evaluation must preserve this product direction.

Relvio must not become a collection of unrelated organization-management features.

---

# Current Product Priority

The current priority is:

```text
Validate the approved core Relvio v1 product.


Core v1 validation takes priority over:

Automation
Advanced integrations
Enterprise features
AI features
Marketplace systems
Developer platforms
White-label systems
Complex analytics
Speculative workflow engines

Future opportunities should be evaluated using evidence from real product use.

Do not use this backlog to expand Relvio v1 during Flutter or backend implementation.

Backlog Authority

This document is a product discovery record.

It is not an implementation authority.

The following documents take precedence over the backlog:

Approved product scope documentation
Approved roadmap
Approved decision log
Approved Relvio UI
Approved API specification
Approved database design
Approved architecture documentation
Approved feature-specific documentation

If a backlog item conflicts with approved documentation, the backlog item remains unapproved.

Do not modify approved implementation to accommodate a backlog idea.

Backlog States

Backlog opportunities should use evidence-based states rather than speculative implementation priorities.

Approved backlog states are:

State	Meaning
Captured	An opportunity or idea has been recorded
Research	The problem requires further investigation
Validating	Product evidence is actively being collected
Candidate	Evidence supports possible future prioritization
Approved	Product has explicitly approved the feature for planning
Rejected	The opportunity has been intentionally declined
Archived	The opportunity is no longer actively relevant

Approved does not automatically mean implementation may begin.

An approved backlog item must still be incorporated into the relevant product, architecture, API, database, design, and roadmap documentation before coding begins.

Priority Rule

Do not assign:

P0
P1
P2
P3
P4

to speculative opportunities without current product prioritization evidence.

Priority should be assigned during roadmap planning after considering:

Validated user problem
Product impact
Strategic alignment
Frequency of need
Severity of problem
Implementation complexity
Data integrity impact
Security impact
Operational cost
Maintenance cost
Dependency requirements
Current Relvio product maturity

A backlog position is not a priority decision.

Opportunity Records

Each actively evaluated backlog opportunity should eventually record:

Opportunity
Problem
Evidence
Affected Users
Product Value
Current State
Known Risks
Dependencies
Decision

Optional information may include:

Research Notes
Validation Market
Technical Questions
Security Questions
Data Questions
Design Questions

Do not create full technical specifications for Captured ideas.

Technical planning should become more detailed only after product evidence justifies it.

Customer Experience Opportunities

Potential opportunities include:

Guided organization onboarding
Product guidance
Welcome or setup checklist
Contextual product education
Recently accessed content
User-configurable shortcuts

These opportunities require validation.

Do not assume:

Interactive product tours
Sample organization data
Personalized dashboards
Favorites

are approved Relvio features.

Any onboarding change must preserve the approved Relvio v1 onboarding UI until a new design is explicitly approved.

People Opportunities

Potential people-management opportunities include:

Duplicate person detection
Duplicate record resolution
Bulk person import
Bulk person export
Extended relationship data
Custom profile data requirements
Additional contact context

These opportunities require product and data validation.

Duplicate resolution is especially sensitive because merging people may affect:

Attendance history
Journey history
Event relationships
Follow-up relationships
Organization ownership
Other historical records

Do not implement automatic person merging without an approved data-integrity strategy.

Relationship and Household Opportunities

Organizations may require additional relationship structures between people.

Potential needs may include:

Family relationships
Household relationships
Guardian relationships
Emergency contacts
Other organization-relevant relationships

These concepts must remain organization-neutral where they become part of core Relvio.

Do not model the core People system around church-specific household assumptions without broader validation.

Any future relationship model requires approved database and API design.

Journey Opportunities

Potential Journey opportunities include:

Journey templates
Journey analytics
Journey configuration improvements
Assisted stage recommendations
Automated journey actions
Conditional journey behavior
Multi-path journey structures
Branching journey logic

These are not approved Relvio v1 requirements.

Automation must not be added before core Journey behavior is validated.

Journey transitions preserve immutable journey history.

Any future automation or recommendation capability must preserve:

Historical transitions
Organization isolation
Permission enforcement
Authoritative backend transitions
Data integrity

AI or automation must not silently rewrite journey history.

Event Opportunities

Potential Event opportunities include:

Recurring events
Event reminders
RSVP tracking
Event capacity management
Event registration
Waiting lists
Additional event participation flows

Ticketing is not assumed to be a Relvio product direction.

A payment or commercial event capability requires separate product validation.

Recurring events require careful data design.

Do not implement recurring events as duplicated event records without an approved recurrence and exception model.

Attendance Opportunities

Potential Attendance opportunities include:

QR-assisted attendance
Self check-in
Attendance insights
Offline attendance
Additional attendance verification methods
Attendance trend visualization

Potential technologies requiring validation may include:

QR codes
NFC
Device location capabilities

These technologies are not approved merely because they appear in the backlog.

Attendance requires backend integrity controls and idempotency.

Future attendance methods must preserve:

Organization isolation
Person identity integrity
Event integrity
Duplicate prevention
Idempotent behavior
Permission rules
Auditability appropriate to the feature

Do not use device location, NFC, or similar capabilities without an approved product need and privacy review.

Follow-Up Opportunities

Potential follow-up opportunities include:

Follow-up reminders
Follow-up templates
Follow-up insights
Assignment assistance
Escalation behavior
Recurring follow-up workflows

Automation is not currently approved by this backlog.

Before automating follow-up behavior, Relvio must validate:

The core follow-up workflow
User responsibilities
Assignment behavior
Completion behavior
Real organizational needs

Do not introduce a generic workflow engine merely to support future follow-up ideas.

Communication Opportunities

Potential communication opportunities include:

Email communication
SMS communication
WhatsApp-related workflows
Broadcast communication
Scheduled communication
Message templates

No communication provider or integration is approved by this document.

Future communication features require evaluation of:

User need
Consent
Privacy
Delivery reliability
Provider availability
Provider cost
Regional availability
Organization isolation
Message permissions
Abuse prevention
Operational complexity

Do not add email, SMS, or WhatsApp infrastructure during core Relvio v1 implementation unless separately approved.

Reporting Opportunities

Potential reporting opportunities include:

Configurable reports
Saved report views
Scheduled report delivery
Organization insights
Trend visualization
Additional product metrics

Do not build a generic report builder before validated user need exists.

Reports must use clearly defined metrics.

A visually attractive chart is not useful if the metric definition is ambiguous.

Future reporting work must define:

Metric
Data Source
Calculation
Organization Scope
Time Range
Interpretation

before implementation.

Organization Structure Opportunities

Potential organization-structure opportunities include:

Branches
Departments
Teams
Regions
Parent-child organization relationships
Other internal organization units

These structures require broad validation.

Do not assume every Relvio organization uses:

Branch
Department
Region

terminology.

Any core organization hierarchy should remain adaptable to people-centered organizations without becoming church-specific or enterprise-specific by default.

Organization hierarchy changes require careful review of the multi-tenant security boundary.

A sub-organization structure must not weaken organization isolation.

Role and Permission Opportunities

Potential access-management opportunities include:

Custom roles
Permission groups
Additional session controls
Access history
Advanced administrative controls

The approved Relvio backend already enforces:

Authentication
Organization membership
Roles
Permissions
Organization isolation

Backlog opportunities may extend these capabilities.

They must not replace or postpone required v1 authorization controls.

Custom roles require an approved permission model.

Do not implement arbitrary permission builders without understanding the real administrative need.

Audit and Activity Opportunities

Potential opportunities include:

Administrative activity history
Security-relevant access history
Organization action logs
Additional operational audit views

The term audit log must not be used loosely.

Before implementing an audit capability, define:

Which actions are recorded
Why they are recorded
Who can view them
Organization scope
Retention behavior
Sensitive data handling
Integrity expectations

Application logs are not automatically product audit logs.

Integration Opportunities

Potential integrations may include:

Calendar services
Team collaboration tools
Automation platforms
Webhooks
Other organization tools

Possible products or categories may be investigated based on validated user demand.

No third-party integration is approved by this document.

Do not implement speculative integrations before core Relvio v1 validation.

Every integration requires review of:

Product value
Authentication model
Data access
Organization isolation
Security
Privacy
Failure behavior
Provider limits
Provider cost
Maintenance burden
Mobile Opportunities

Potential future mobile capabilities include:

Push notifications
Offline behavior
Biometric-assisted authentication
Platform widgets

These are not approved Relvio v1 requirements unless separately documented.

Offline behavior is especially sensitive for:

Attendance
Journey transitions
Organization context
Conflicting mutations

Do not add offline mutation queues without an approved synchronization and conflict strategy.

Biometric capability must not be treated as a replacement for backend authentication.

AI Opportunities

Potential AI-assisted opportunities include:

Assisted search
Summaries
Follow-up suggestions
Relationship insights
Natural-language interaction
Product assistance

AI features are not part of the approved Relvio v1 core implementation.

Do not add AI features because an AI coding assistant is being used to build Relvio.

Implementation tooling and product capability are separate concerns.

Future AI opportunities require validation of:

User value
Accuracy requirements
Data privacy
Organization isolation
Permission context
Cost
Latency
Failure behavior
Explainability where important

AI must not become authoritative for:

Organization access
Roles
Permissions
Attendance integrity
Journey history
Protected business rules

AI-generated suggestions must not silently mutate critical Relvio data.

Enterprise Opportunities

Potential advanced organization capabilities may include:

Single Sign-On
Advanced access controls
Organization hierarchy
Dedicated operational support
Advanced security controls
Custom organization experiences

These capabilities are not approved Relvio v1 requirements.

Do not create an Enterprise architecture layer before validated demand exists.

Core Relvio v1 must be validated before advanced enterprise features are prioritized.

Custom Branding Opportunities

Potential future branding capabilities may include:

Limited organization branding
Organization visual identity in selected surfaces
Advanced branded experiences

White-label capability is not approved.

Custom organization colors and themes are not part of the approved Relvio v1 color system.

Color governance is defined by:

Color System.md

Do not build theme override infrastructure for hypothetical enterprise customers.

Developer Platform Opportunities

Relvio already uses an internal backend REST API.

The approved API base is:

/api/v1

This internal application API must not be confused with a public developer platform.

Potential future developer-platform opportunities include:

Public API access
External API credentials
Webhooks
SDKs
External developer documentation

A public API is not approved by this backlog.

Do not expose internal application endpoints publicly merely because Relvio uses REST.

A future developer platform requires explicit decisions regarding:

Authentication
Authorization
Organization scope
Rate limits
API lifecycle
Versioning
Credential management
Developer documentation
Abuse prevention
Billing Opportunities

Potential commercial product capabilities include:

Subscription management
Plan management
Billing history
Invoicing
Promotional pricing
Usage-based product metrics

This document does not approve a billing provider or billing architecture.

Do not add billing infrastructure during core Relvio implementation unless product scope explicitly approves it.

Billing requirements should be designed from the approved Relvio business model.

Do not copy a generic SaaS billing model into Relvio.

Security Opportunities

Potential additional security capabilities include:

Multi-factor authentication
Device visibility
Login history
Advanced session controls
Network-based access restrictions

These are backlog opportunities.

They do not replace the mandatory security controls defined by:

16_Security.md

Core authentication, authorization, organization isolation, and secret protection are current requirements.

Future security features should be prioritized based on actual threat, customer need, and product maturity.

Accessibility Opportunities

Relvio accessibility is a current product quality responsibility.

Accessibility must not be postponed entirely into the backlog.

Current Flutter implementation should consider the accessibility principles defined by:

Design Principles.md
Color System.md
Component Library.md

Potential additional accessibility capabilities may include:

Dedicated high-contrast themes
Advanced accessibility preferences
Additional navigation accommodations

Font scaling and screen reader compatibility should be evaluated as part of supported mobile behavior where applicable.

Do not classify basic accessible implementation as a future optional feature.

Localization Opportunities

Potential localization opportunities include:

Multiple interface languages
Right-to-left layout support
User or organization timezone preferences
Regional date formatting
Regional time formatting
Regional number formatting

Localization is not automatically approved for Relvio v1.

However, implementation should avoid unnecessary hardcoded assumptions where simple engineering discipline can prevent future problems.

Do not build a full localization platform without approved product scope.

Analytics Opportunities

Potential product and organization insight opportunities include:

Organization growth trends
Participation trends
Relationship progression insights
Product engagement analytics
Conversion or journey metrics

Every analytics feature requires a defined metric.

Do not implement vague metrics such as:

Growth
Engagement
Retention
Conversion

without documenting exactly what the metric means in Relvio.

Analytics must preserve organization isolation.

Cross-organization analytics must not expose one organization's protected data to another organization.

Data Recovery Opportunities

Potential user-facing recovery capabilities may include:

Recycle bin
Archived record recovery
Controlled restoration
Additional historical views

These capabilities require domain-specific rules.

Do not implement a universal recycle bin for all Relvio data.

Some data may be:

Archived
Soft deleted
Permanently deleted
Immutable
Restorable under specific conditions

Journey history must not be treated as ordinary recoverable mutable data.

The relevant domain model determines recovery behavior.

Search Opportunities

Potential search improvements include:

Broader cross-feature search
Assisted search
Search suggestions
Search history
Command-style navigation

Do not assume a global search system exists.

Do not build a keyboard command palette for mobile v1.

Future search work must define:

Search scope
Organization scope
Permission behavior
Indexed data
Ranking behavior
Result grouping
Privacy expectations

Search must never bypass organization or permission boundaries.

Additional Captured Ideas

The following ideas remain captured for possible future research:

Voice notes
QR-based contact sharing
Badge printing
Smart tags
Calendar synchronization
Dark mode
Activity history filtering

These ideas have no implementation priority by appearing in this list.

They may be:

Researched
Validated
Rejected
Archived

based on future product evidence.

Backlog Feature Promotion

A backlog opportunity must not move directly from this document into coding.

The normal promotion path is:

Captured Opportunity
        ↓
Problem Research
        ↓
Validation Evidence
        ↓
Product Decision
        ↓
Roadmap Approval
        ↓
Architecture Impact Review
        ↓
Data and API Design
        ↓
UI/UX Design
        ↓
Documentation Approval
        ↓
Implementation

The depth of each stage should match the feature's complexity and risk.

A simple approved improvement may require a lightweight process.

A feature affecting:

Multi-tenancy
Authentication
Permissions
Attendance
Journey history
Database structure
External integrations

requires stronger review.

Feature Evaluation Questions

Before promoting a backlog opportunity, ask:

What real problem does this solve?
Who experiences the problem?
What evidence do we have?
How frequently does the problem occur?
How severe is the problem?
Does the opportunity align with Relvio as a People Operating System?
Does it help organizations build stronger relationships?
Is the capability organization-neutral where required?
Can the existing product solve the problem already?
What new complexity does the feature introduce?
What data does the feature require?
Does it affect organization isolation?
Does it affect roles or permissions?
Does it affect attendance integrity?
Does it affect immutable journey history?
Does it require an external provider?
What ongoing operational cost does it create?
What maintenance burden does it create?
Is now the correct time to build it?

A feature should not be promoted because it sounds modern or appears in competing products.

Validation Market Learning

Churches and similar organizations are a strong initial Relvio validation market.

Product learning from this market is valuable.

However, backlog evaluation must distinguish between:

A real people-centered organization problem

and:

A church-specific workflow

A church-specific need may still become a Relvio capability when:

The underlying problem exists across people-centered organizations
The core model can remain organization-neutral
Market-specific presentation can be separated appropriately

Do not force church terminology into the core Relvio product without an explicit product decision.

Backlog Maintenance

The Product Team should review this backlog when meaningful new evidence exists.

Useful review moments include:

Customer interviews
Product usage analysis
Usability testing
Validation experiments
Roadmap planning
Major product releases

The backlog does not require ceremonial review on a fixed schedule when no meaningful evidence has changed.

During review:

Add evidence to relevant opportunities.
Update opportunity states.
Merge duplicate opportunities.
Reject unsupported directions.
Archive obsolete ideas.
Promote validated candidates through the approved product process.
Remove false priority assumptions.
Duplicate Opportunity Control

Before adding a new backlog item:

Search existing backlog opportunities.
Check the approved roadmap.
Check the decision log.
Check existing feature documentation.
Determine whether the idea is genuinely new.

Do not create separate backlog entries for differently worded versions of the same product problem.

Examples:

Calendar Sync
Google Calendar Integration
External Calendar Integration

may represent one broader opportunity until product research identifies distinct requirements.

Rejected Ideas

Rejected opportunities should not be silently deleted when the decision provides useful product context.

Where appropriate, record:

Opportunity
Decision
Reason
Date

Significant product decisions should also be reflected in:

18_Decision_Log.md

A rejected idea may be reconsidered when meaningful new evidence appears.

Do not repeatedly reintroduce rejected ideas without new evidence.

AI Coding Assistant Rules

AI coding assistants must treat this document as non-implementation backlog context.

AI coding assistants must not:

Build a feature because it appears in this backlog.
Create API endpoints for backlog features.
Create database tables for backlog features.
Add navigation for backlog features.
Add hidden feature screens.
Add placeholder implementations for backlog features.
Add future-proof abstractions specifically for backlog ideas.
Add automation.
Add AI product features.
Add advanced integrations.
Add enterprise systems.
Add a marketplace.
Add a plugin architecture.
Add a public developer platform.
Add billing infrastructure.
Add white-label infrastructure.
Add dark mode.
Add organization theme overrides.
Add offline mutation queues.
Add QR, NFC, or GPS attendance methods.
Add WhatsApp, SMS, or email integrations.

unless the relevant feature has been explicitly approved and incorporated into implementation-authoritative documentation.

When a backlog feature is mentioned in an implementation task, the AI coding assistant must verify that the feature also exists in the approved implementation scope.

If it exists only in this backlog, implementation must stop for that feature and report:

This capability is currently a backlog opportunity and is not approved for implementation.

The assistant may continue unrelated approved implementation work.

Source of Truth Priority

For product scope and backlog decisions:

Approved product scope defines current product requirements.
17_Roadmap.md defines approved product sequencing.
18_Decision_Log.md records approved significant decisions.
Approved feature documentation defines approved feature behavior.
Approved Relvio UI defines approved v1 visual and interaction intent.
Feature Backlog.md records unapproved future opportunities.

The backlog must never override:

Architecture
API specification
Database design
Security requirements
Testing strategy
Approved UI
Approved roadmap

If a backlog opportunity conflicts with approved product direction, the opportunity must be reviewed rather than silently implemented.

Success Criteria

The Relvio feature backlog is successful when:

Product ideas are preserved without becoming accidental requirements.
Relvio v1 remains protected from scope expansion.
Backlog priorities are based on evidence rather than speculation.
Churches provide useful validation without making the core product church-only.
Automation is not introduced before core workflows are validated.
Advanced integrations are not built without demonstrated need.
Enterprise infrastructure is not created prematurely.
AI product features are evaluated as product capabilities, not implementation trends.
Critical attendance and journey integrity rules remain protected.
Public API concepts are not confused with the internal /api/v1 REST API.
AI coding assistants clearly understand that backlog items are not approved implementation work.
Future features move through an intentional approval and documentation process.
Final Principle

The backlog preserves possibilities.

It does not define the product Relvio is building today.

Relvio should earn its next features through validated user problems, product evidence, and deliberate decisions.