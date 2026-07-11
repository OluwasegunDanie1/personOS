---
Document: Release Checklist
Version: 1.1
Status: Approved
Project: Relvio
Owner: Engineering Team
---

# Release Checklist

## Purpose

This document defines the release verification checklist for Relvio.

The checklist protects product quality, security, data integrity, and approved product behavior before a release progresses to its intended environment or distribution stage.

Release verification must be appropriate to the actual release scope.

A release must not skip critical checks because the change appears small.

At the same time, checks that are unrelated to the release must not be marked as completed without verification merely to satisfy a generic checklist.

---

# Release Scope

Before release verification begins, identify the actual release scope.

Record:

- Release identifier
- Intended environment or distribution stage
- Included approved changes
- Affected Flutter responsibilities
- Affected backend responsibilities
- Affected API contracts
- Affected database responsibilities
- Affected security boundaries
- Affected product workflows
- Known release risks

The release scope determines which conditional checks apply.

This document does not define a semantic versioning policy.

Do not assume Major, Minor, or Patch release classification unless an approved versioning decision defines that policy.

---

# Documentation Authority

Release verification must use approved Relvio documentation.

Relevant authorities include:

- `MVP Scope.md`
- `13_API_Specification.md`
- Approved database documentation
- `16_Security.md`
- Approved architecture documentation
- `15_Testing_Strategy.md`
- `14_Engineering_Standards.md`
- `Coding Standards.md`
- `Deployment.md`
- `Folder Structure.md`
- `High-Fidelity Screens.md`
- `Design Tokens.md`
- `Color System.md`
- `Component Library.md`
- `Flutter Theme Implementation.md`
- `Asset_Structure.md`
- `Brand Assets.md`

A release checklist must not redefine responsibilities owned by these documents.

If approved documentation conflicts, the conflict must be resolved before release approval.

---

# Approved Platforms

Relvio v1 product platforms are:

- Android
- iOS

Required platform release verification applies to the supported Android and iOS targets relevant to the release.

This document does not require product testing for:

- Web
- Windows
- macOS
- Linux

These are not approved Relvio v1 product platforms.

Do not create release infrastructure for unapproved platforms.

---

# Pre-Release Scope Verification

Before final release verification:

- [ ] Included changes are part of approved product scope.
- [ ] The release does not introduce unapproved features.
- [ ] The release does not introduce unapproved platform support.
- [ ] Relevant requirements are sufficiently defined.
- [ ] Relevant frozen UI references have been identified.
- [ ] Relevant API contracts have been identified.
- [ ] Relevant database changes are documented where applicable.
- [ ] Relevant security responsibilities have been identified.
- [ ] Known documentation conflicts have been resolved.
- [ ] Known release risks are recorded.

Do not release functionality whose required product or implementation behavior was invented during coding.

---

# Development Completion

Verify for the included release scope:

- [ ] Approved functionality is implemented.
- [ ] Relevant code review requirements are satisfied.
- [ ] Required documentation changes are complete.
- [ ] Temporary debug behavior has been removed.
- [ ] Temporary development credentials have been removed.
- [ ] Temporary test endpoints or bypasses have been removed.
- [ ] Unresolved implementation placeholders do not affect production behavior.
- [ ] Feature flags are correctly configured where an approved feature flag responsibility exists.

A release does not require every comment or tracked technical note to disappear.

However, executable placeholders, unsafe bypasses, unfinished production paths, and unresolved release-critical TODOs must not remain.

---

# Code Quality

Verify according to approved engineering and coding standards:

- [ ] Flutter analyzer requirements pass.
- [ ] Required lint rules pass.
- [ ] Required formatting checks pass.
- [ ] Backend quality checks pass where backend code changed.
- [ ] No unresolved release-blocking analyzer errors remain.
- [ ] No unresolved release-blocking warnings remain.
- [ ] Known deprecations affecting the release have been reviewed.
- [ ] Dependency changes have been reviewed.
- [ ] Unused release-critical implementation paths have been reviewed.
- [ ] Debug logging does not expose sensitive information.

Do not ignore a warning merely because the application builds.

Do not block a release solely because a dependency exposes a harmless known deprecation when approved engineering review determines it does not create unacceptable release risk.

---

# Testing

Testing requirements are controlled by `15_Testing_Strategy.md`.

Run the tests required for the changed responsibilities and affected critical workflows.

## Automated Testing

Where required by the approved testing strategy:

- [ ] Required unit tests pass.
- [ ] Required widget tests pass.
- [ ] Required integration tests pass.
- [ ] Required backend tests pass.
- [ ] Required API tests pass.
- [ ] Required security tests pass.
- [ ] Required regression tests pass.

Do not mechanically create meaningless tests solely to mark a test category as complete.

A required failing test blocks release until the failure is resolved or explicitly reviewed under an approved release decision.

---

# Critical Workflow Verification

Verify the approved critical workflows affected by the release.

Potential critical workflow areas include:

- Authentication
- Authorized organization access
- People workflows
- Journey workflows
- Events
- Attendance
- Follow-ups
- Approved product insights
- Workspace responsibilities

Only approved workflows should be tested as product behavior.

Do not use an old Atlas module list as the release test inventory.

For each affected critical workflow:

- [ ] Primary approved path works.
- [ ] Relevant loading behavior works.
- [ ] Relevant empty behavior works.
- [ ] Relevant recoverable error behavior works.
- [ ] Protected actions use the backend API.
- [ ] Unauthorized actions are rejected where applicable.
- [ ] UI state remains consistent with confirmed backend results.

---

# Organization Isolation

Organization isolation is a critical release security boundary.

For backend, API, database, membership, role, or permission changes:

- [ ] Organization isolation tests pass.
- [ ] Cross-organization reads are rejected.
- [ ] Cross-organization mutations are rejected.
- [ ] Organization identifiers cannot be used to bypass membership checks.
- [ ] Client-side organization filtering is not treated as tenant security.
- [ ] Protected operations verify organization membership.
- [ ] Relevant roles and permissions are enforced by the backend.

A known organization-isolation failure is release-blocking.

Do not release with a known cross-tenant data exposure or mutation vulnerability.

---

# Authentication and Authorization

For affected authentication or protected workflows:

- [ ] Approved authentication behavior works.
- [ ] Invalid authentication state is handled correctly.
- [ ] Protected endpoints reject unauthenticated access.
- [ ] Protected operations enforce organization membership.
- [ ] Relevant role checks work.
- [ ] Relevant permission checks work.
- [ ] Flutter does not act as the authoritative authorization layer.
- [ ] Hidden UI controls are not relied upon as security enforcement.

Security behavior must follow `16_Security.md`.

---

# Journey Integrity

For any release affecting journey behavior:

- [ ] Approved journey transitions work.
- [ ] Invalid protected transitions are rejected where defined.
- [ ] Journey mutations are backend-controlled.
- [ ] Immutable journey history is preserved.
- [ ] Historical transition records are not rewritten to simulate current state.
- [ ] Current journey presentation remains consistent with confirmed backend data.
- [ ] Relevant concurrent or repeated actions have been reviewed.

A known journey-history integrity failure is release-blocking.

---

# Attendance Integrity

For any release affecting attendance:

- [ ] Approved attendance recording flow works.
- [ ] Backend attendance validation works.
- [ ] Approved idempotency behavior works.
- [ ] Repeated equivalent submissions do not create unintended duplicate attendance records.
- [ ] Flutter does not treat local state as proof of a committed attendance write.
- [ ] Failed attendance writes are represented correctly.
- [ ] Retried attendance writes behave according to the approved API contract.
- [ ] Organization isolation is preserved.
- [ ] Relevant attendance permissions are enforced.

A known attendance integrity or idempotency failure is release-blocking.

---

# API Verification

For releases affecting the backend REST API:

- [ ] Implemented endpoints match `13_API_Specification.md`.
- [ ] API base remains `/api/v1`.
- [ ] Request validation works.
- [ ] Approved response contracts are preserved.
- [ ] Approved error behavior is preserved.
- [ ] Authentication requirements are enforced.
- [ ] Organization membership requirements are enforced.
- [ ] Roles and permissions are enforced where required.
- [ ] Protected mutations enforce backend business rules.
- [ ] No undocumented endpoint was added.
- [ ] No undocumented field was added.
- [ ] API documentation is updated when an approved contract changed.

Do not release an API implementation that silently diverges from the approved specification.

---

# Database Verification

For releases affecting PostgreSQL structures or database behavior:

- [ ] Approved database changes are documented.
- [ ] Required migrations are reviewed.
- [ ] Migrations have been tested in an appropriate non-production environment.
- [ ] Organization isolation assumptions remain valid.
- [ ] Required constraints remain valid.
- [ ] Journey history integrity remains valid where affected.
- [ ] Attendance integrity remains valid where affected.
- [ ] Migration failure behavior has been reviewed.
- [ ] Deployment compatibility has been reviewed.
- [ ] Recovery requirements have been reviewed.

Do not assume every migration must have a destructive reverse migration.

Database rollback and recovery must follow the approved deployment and database strategy.

Do not delete or rewrite production history merely to make rollback technically symmetrical.

---

# UI Fidelity Review

For Flutter UI changes:

- [ ] Approved frozen Relvio UI references were used.
- [ ] Approved screen composition is preserved.
- [ ] Approved navigation is preserved.
- [ ] Approved typography responsibilities are preserved.
- [ ] Approved color responsibilities are preserved.
- [ ] Approved spacing relationships are preserved.
- [ ] Approved component responsibilities are preserved.
- [ ] Approved iconography is preserved.
- [ ] Approved brand assets are used directly.
- [ ] Screens are implemented with Flutter widgets.
- [ ] Screenshot fragments are not used as production UI.
- [ ] Material defaults do not silently redefine the approved Relvio UI.

The approved primary bottom navigation label is:

**Workspace**

Do not release the obsolete primary navigation label:

**More**

---

# Theme Verification

Relvio v1 uses the approved light theme.

Verify:

- [ ] Approved light-theme behavior is preserved.
- [ ] Primary brand color remains `#2563FF` where its approved responsibility applies.
- [ ] Primary application background remains `#FCFCFD` where its approved responsibility applies.
- [ ] Inter is used according to approved typography responsibilities.
- [ ] No unapproved theme toggle has been introduced.
- [ ] No Riverpod theme state has been introduced.
- [ ] No system theme switching has been introduced.
- [ ] No dark theme infrastructure has been introduced.
- [ ] No organization-controlled application theme has been introduced.

Dark mode testing is not a Relvio v1 release requirement because dark mode is not approved for v1.

---

# State Verification

For affected screens, verify relevant real application states.

Where applicable:

- [ ] Initial loading works.
- [ ] Refreshing works.
- [ ] Loaded content works.
- [ ] Empty content works.
- [ ] Recoverable errors work.
- [ ] Submission loading works.
- [ ] Submission failure works.
- [ ] Submission success works.
- [ ] Disabled actions behave correctly.

Skeletons and shimmer are not mandatory for every screen.

State presentation should follow approved high-fidelity and component guidance.

Do not add decorative state systems merely to satisfy this checklist.

---

# Mobile Layout Verification

For affected Flutter screens:

- [ ] Essential content does not overflow on supported test devices.
- [ ] Essential controls remain reachable.
- [ ] Text layout remains usable.
- [ ] System safe areas are handled correctly.
- [ ] Keyboard appearance does not permanently block required form actions.
- [ ] Scrolling behavior remains usable.
- [ ] Orientation behavior follows approved product expectations where relevant.

The goal is stable supported mobile behavior.

Do not create desktop or web layouts from this checklist.

---

# Accessibility Verification

For affected mobile UI responsibilities, verify where relevant:

- [ ] Interactive controls expose meaningful semantics.
- [ ] Icon-only actions have appropriate accessible meaning.
- [ ] Form fields communicate their purpose.
- [ ] Validation feedback is understandable.
- [ ] Important states are not communicated only through unclear decoration.
- [ ] Touch targets are practically usable.
- [ ] Screen-reader behavior has been reviewed for critical affected workflows.
- [ ] Focus behavior is reasonable for forms and relevant mobile interactions.

Desktop keyboard navigation is not a universal Relvio v1 release gate.

Accessibility testing should reflect the approved Android and iOS product experience.

---

# Performance Verification

Review performance for the affected release responsibilities.

Where relevant:

- [ ] Application startup remains acceptable.
- [ ] Affected screens remain responsive.
- [ ] Relevant search behavior remains responsive.
- [ ] Network loading behavior remains usable.
- [ ] Repeated requests are not created unintentionally.
- [ ] Large visible lists remain usable.
- [ ] No obvious release-critical memory issue is observed.
- [ ] No obvious release-critical rendering issue is observed.
- [ ] Backend performance impact has been reviewed where backend behavior changed.
- [ ] Database query impact has been reviewed where data access changed.

This document does not define invented numeric performance thresholds.

Approved performance requirements and measured evidence should control release decisions where exact thresholds are required.

---

# Secrets and Environment Verification

Before production release:

- [ ] Production secrets are not committed to the repository.
- [ ] Required environment configuration is present.
- [ ] Development credentials are not used in production.
- [ ] Sensitive values are not exposed through Flutter source or assets.
- [ ] Logging does not expose credentials or sensitive protected data.
- [ ] Backend secret configuration has been reviewed.
- [ ] Environment-specific API configuration is correct.

Flutter must not contain PostgreSQL credentials.

Flutter must never connect directly to PostgreSQL.

---

# Dependency Verification

For releases containing dependency changes:

- [ ] New dependencies have a verified implementation requirement.
- [ ] Dependencies comply with approved engineering standards.
- [ ] Unapproved platform infrastructure was not introduced.
- [ ] Duplicate libraries for the same responsibility have been reviewed.
- [ ] Icon dependencies remain controlled.
- [ ] Lottie or Rive was not added without an approved requirement.
- [ ] Billing or payment dependencies were not added without approved billing scope.
- [ ] Future-feature infrastructure was not added speculatively.

Do not install packages because an AI coding assistant considers them common.

---

# Asset Verification

For releases affecting production assets:

- [ ] Required approved assets exist.
- [ ] Asset paths follow `Asset_Structure.md`.
- [ ] Approved centralized `AppAssets` responsibilities are used where defined.
- [ ] Approved Relvio logo assets are used directly.
- [ ] The logo was not recreated from a screenshot.
- [ ] The logo was not recreated with Flutter drawing code.
- [ ] UI screenshot fragments are not used as production assets.
- [ ] Missing approved brand assets have been reported.
- [ ] Unapproved replacement brand assets were not invented.

---

# Android Verification

For an Android release:

- [ ] Required automated tests pass.
- [ ] Required manual critical-flow verification passes.
- [ ] Production build succeeds.
- [ ] Environment configuration is correct.
- [ ] Application identity and approved branding are correct.
- [ ] Required permissions have been reviewed.
- [ ] Release-critical startup behavior works.
- [ ] Release-critical network behavior works.
- [ ] Affected critical workflows work.
- [ ] Release artifact requirements are satisfied according to approved deployment documentation.

---

# iOS Verification

For an iOS release:

- [ ] Required automated tests pass.
- [ ] Required manual critical-flow verification passes.
- [ ] Production build succeeds.
- [ ] Environment configuration is correct.
- [ ] Application identity and approved branding are correct.
- [ ] Required permissions have been reviewed.
- [ ] Release-critical startup behavior works.
- [ ] Release-critical network behavior works.
- [ ] Affected critical workflows work.
- [ ] Release artifact requirements are satisfied according to approved deployment documentation.

---

# Backend Deployment Verification

For a release affecting backend behavior:

- [ ] Approved backend build or deployment checks pass.
- [ ] Required environment configuration is verified.
- [ ] Required migrations are ready.
- [ ] API compatibility has been reviewed.
- [ ] Organization isolation verification is complete.
- [ ] Authentication and authorization verification is complete.
- [ ] Relevant integrity requirements are verified.
- [ ] Deployment procedure follows `Deployment.md`.
- [ ] Recovery requirements have been reviewed.

Do not treat Flutter release verification as a substitute for backend deployment verification.

---

# Observability

Use only approved observability infrastructure.

Where monitoring, logging, crash reporting, or alerting has been approved and configured:

- [ ] Required monitoring is active.
- [ ] Required backend logs are available.
- [ ] Required error reporting is active.
- [ ] Required mobile crash reporting is active.
- [ ] Alerting configuration is correct where applicable.

This checklist does not independently approve a monitoring or crash-reporting provider.

Do not install observability services solely because they appear in this checklist.

---

# Documentation Verification

For the release scope:

- [ ] Relevant approved documentation remains aligned.
- [ ] README is updated if project orientation changed.
- [ ] API documentation is updated if an approved API contract changed.
- [ ] Database documentation is updated if approved data structure changed.
- [ ] Security documentation is updated if approved security behavior changed.
- [ ] Deployment documentation is updated if deployment behavior changed.
- [ ] User-facing documentation is updated where required.
- [ ] Release notes are prepared where required by the distribution stage.

Do not update unrelated documents merely to create release activity.

---

# Pre-Deployment Approval

Before production deployment or production distribution:

- [ ] Required tests are complete.
- [ ] Release-blocking defects are resolved.
- [ ] Known risks are reviewed.
- [ ] Security-critical checks are complete.
- [ ] Organization isolation is verified.
- [ ] Relevant data integrity checks are complete.
- [ ] Production configuration is verified.
- [ ] Deployment readiness is confirmed.
- [ ] Required release approval has been recorded.

The exact approver names or organizational roles are not defined by this document.

Do not invent Product Lead, Engineering Lead, QA, or Project Owner approval workflows unless project governance separately defines them.

---

# Post-Deployment Verification

After deployment or release distribution, verify the responsibilities relevant to the release.

Where applicable:

- [ ] Application starts successfully.
- [ ] Approved authentication flow works.
- [ ] Authorized organization access works.
- [ ] Affected critical workflows work.
- [ ] Backend API health is verified.
- [ ] Relevant database behavior is healthy.
- [ ] Relevant attendance behavior is healthy.
- [ ] Relevant journey behavior is healthy.
- [ ] Relevant error reporting is reviewed where configured.
- [ ] Relevant logs are reviewed.
- [ ] No known cross-organization access issue is present.
- [ ] No release-critical regression is identified.

Do not require notification verification when notification behavior is unrelated to the release or not part of approved scope.

---

# Recovery and Rollback Readiness

Before production deployment:

- [ ] The previous releasable application artifact or deployment reference is identifiable where applicable.
- [ ] Recovery responsibilities are understood.
- [ ] Backend rollback or forward-fix strategy has been reviewed where applicable.
- [ ] Database recovery implications have been reviewed where applicable.
- [ ] Migration compatibility has been reviewed.
- [ ] Data integrity risks have been reviewed.
- [ ] The release team knows the response path for a critical production failure.

Rollback must not destroy valid production data or rewrite immutable history merely to restore an earlier application version.

Database recovery must follow approved database and deployment responsibilities.

---

# Release-Blocking Conditions

A release must not proceed with a known unresolved critical issue involving:

- Cross-organization data exposure
- Cross-organization protected mutation
- Authentication bypass
- Authorization bypass
- Exposed production secrets
- Known critical data corruption
- Broken attendance integrity for affected workflows
- Broken attendance idempotency for affected workflows
- Journey history corruption
- Critical approved workflow failure
- Production build failure
- Known release-critical API contract divergence

Other defects should be evaluated according to the approved testing, engineering, product, and release decision process.

---

# Release Result

Record the final release result.

Possible result:

- Approved for intended release stage
- Blocked
- Returned for correction

Record:

- Release identifier
- Result
- Date
- Known accepted risks
- Required follow-up actions
- Approval reference where applicable

Do not mark a blocked release as approved merely because deployment is technically possible.

---

# Continuous Improvement

After meaningful releases, review the release process where useful.

Consider:

- What worked well?
- What caused avoidable risk?
- What failed?
- What was difficult to verify?
- Which documentation was unclear?
- Which checks were missing?
- Which checks were repeatedly irrelevant?
- What should be improved before the next comparable release?

Update this checklist when validated release experience reveals a better control.

Do not weaken critical security or data-integrity gates merely to make releases faster.

---

# AI Implementation and Release Rules

Claude or another AI coding assistant may assist with release preparation and verification.

AI must not:

- Mark unverified checks as passed
- Invent test results
- Invent security verification
- Invent organization-isolation verification
- Invent attendance idempotency results
- Invent journey integrity results
- Invent deployment success
- Invent monitoring status
- Invent release approval
- Add unapproved release platforms
- Add dark mode to satisfy a generic checklist
- Install infrastructure because the checklist mentions a conditional responsibility

AI should clearly distinguish:

- Verified
- Not verified
- Not applicable
- Blocked

When a critical requirement cannot be verified, report the gap.

Do not assume success.

---

# Documentation Responsibilities

This document owns:

- Relvio release verification gates
- Release checklist structure
- Critical release-blocking conditions
- Scope-aware release verification
- Post-release review expectations

This document does not own:

- Product scope
- API contracts
- Database schema
- Security architecture
- Testing strategy
- Deployment procedures
- Versioning policy
- Team governance
- Monitoring provider selection
- Crash-reporting provider selection

Those responsibilities remain with their approved Relvio documents or future explicitly approved governance documentation.

---

# Success Criteria

This checklist is successful when:

- Releases are verified against actual approved scope.
- Organization isolation remains a critical release gate.
- Attendance integrity and idempotency remain protected.
- Immutable journey history remains protected.
- Android and iOS are the only required v1 product platform checks.
- Dark mode is not introduced through release requirements.
- Generic Atlas module lists do not control testing.
- Conditional infrastructure is not installed merely because it appears in the checklist.
- Release results reflect real verification.
- AI coding assistants cannot claim unperformed checks as passed.
- Critical product, security, and data-integrity failures block release.

---

# End of Document