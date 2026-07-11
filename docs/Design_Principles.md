---

Document: Design Principles
Version: 1.1
Status: Approved
Project: Relvio
Owner: Design & Product
-----------------------

# Design Principles

## Purpose

This document defines the product design principles that guide Relvio.

These principles help Design, Product, Engineering, and AI implementation assistants make consistent decisions when interpreting approved product requirements and implementing the approved Relvio UI.

Relvio v1 mobile UI is already approved and frozen.

This document must not be used to redesign approved screens.

It provides design judgment for:

* Implementing approved interfaces
* Handling implementation details not fully visible in static UI references
* Designing required interaction states
* Evaluating future product design work
* Preserving Relvio's product character as the system grows

---

# Product Design Context

Relvio is a:

> **People Operating System**

Relvio helps people-centered organizations understand, organize, and strengthen relationships with the people they serve.

Churches and similar organizations are a strong initial validation market.

The core product remains organization-neutral.

Relvio is not designed as a church-only interface.

The primary brand message is:

> **Build stronger relationships.**

Product design should reinforce this purpose.

---

# Design Philosophy

Relvio should feel:

* Clear
* Calm
* Focused
* Human
* Modern
* Trustworthy
* Intentional

Good product design is not decoration.

Good design helps users understand:

* Where they are
* What information matters
* What actions are available
* What happened after an action
* What they can do next

The interface should reduce unnecessary effort without hiding important meaning or control.

---

# Approved UI Authority

The approved Relvio v1 mobile UI is frozen before implementation.

Implementation must follow the approved UI.

Design principles do not authorize developers or AI coding assistants to:

* Rearrange screens
* Rename navigation
* Add features
* Remove approved interactions
* Introduce new visual styles
* Replace approved components
* Change information hierarchy
* Redesign flows based on personal preference

Where a static UI reference does not fully show an implementation state, these principles may guide the implementation of that state.

Examples include:

* Loading
* Empty
* Error
* Disabled
* Pressed
* Retry
* Network failure
* Validation feedback

Any such implementation must preserve the intent of the approved screen.

---

# Principle 1 — Clarity Before Cleverness

Relvio should prioritize clarity.

Users should be able to understand the purpose of a screen and its available actions without unnecessary interpretation.

Prefer:

* Clear labels
* Familiar interaction patterns
* Visible hierarchy
* Direct feedback
* Predictable actions

Avoid:

* Clever but unclear labels
* Hidden critical actions
* Decorative interaction patterns
* Ambiguous icons without sufficient context
* Unnecessary interface novelty

Do not simplify by removing information users genuinely need.

The goal is not minimum interface.

The goal is minimum unnecessary complexity.

---

# Principle 2 — People Before Records

Relvio manages information about real people and relationships.

The product must not feel like a cold database interface.

People-related experiences should preserve human context where approved by the product design.

Relevant context may include:

* Name
* Profile identity
* Relationship context
* Journey context
* Attendance history
* Relevant activity
* Follow-up context

The approved product requirements determine which information appears.

Do not add personal data merely to make a screen feel more human.

Data collection and display must remain purposeful.

Relvio should help organizations know their people, not simply accumulate records.

---

# Principle 3 — Relationships Over Administration

Relvio should reduce administrative friction so organizations can focus on people.

Product design should emphasize meaningful outcomes rather than internal system mechanics.

Where possible, user-facing experiences should communicate:

* People
* Relationships
* Progress
* Participation
* Follow-up
* Relevant action

rather than exposing technical implementation concepts.

Do not expose users to:

* Database terminology
* Internal identifiers
* API terminology
* Raw backend states
* Infrastructure concepts

unless a genuine product requirement requires technical information.

---

# Principle 4 — Reduce Unnecessary Cognitive Load

Users should not be required to remember information that the product can appropriately present.

Relvio should provide relevant context at the point where it is needed.

This may include:

* Clear labels
* Current selection
* Current state
* Relevant validation guidance
* Contextual actions
* Existing data required for a decision

Do not automatically implement:

* Recent searches
* Smart suggestions
* AI recommendations
* Predictive defaults
* Remembered user behavior

merely as cognitive-load improvements.

Such capabilities require approved product requirements.

Reducing cognitive load must not become permission to invent automation.

---

# Principle 5 — Consistency Builds Confidence

Similar approved interactions should behave consistently.

Consistency should be preserved across:

* Buttons
* Inputs
* Navigation
* Cards
* Lists
* Dialogs
* Bottom sheets
* Loading states
* Empty states
* Error states

Shared patterns should use approved reusable Flutter components where appropriate.

Component reuse is governed by:

* `Component Library.md`

Consistency does not mean every screen must use the same layout.

Feature-specific interfaces may differ when their responsibilities differ.

Reuse patterns.

Do not force unrelated features into one universal component.

---

# Principle 6 — Feedback Must Be Immediate and Truthful

When a user performs an action, Relvio should provide appropriate feedback.

The interface should communicate whether an action is:

* In progress
* Successful
* Unsuccessful
* Blocked
* Awaiting required input

Feedback should appear at the appropriate level of the interaction.

Do not show success before the product has sufficient reason to represent the action as successful.

UI speed must not create false state.

This is especially important for:

* Attendance
* Journey transitions
* Authentication
* Permission-sensitive actions
* Destructive actions
* Data mutations

The backend remains authoritative for protected business operations.

---

# Principle 7 — Perceived Speed Matters, Integrity Matters More

Relvio should feel responsive.

Appropriate implementation techniques may include:

* Immediate interaction feedback
* Loading indicators
* Skeletons
* Shimmer
* Local presentation state
* Efficient data reuse
* Avoiding unnecessary network requests

Optimistic updates may only be used where the feature's data integrity and failure behavior make them appropriate.

Do not use optimistic state merely to make the product appear faster.

Attendance requires backend integrity controls and idempotency.

Journey transitions preserve immutable journey history.

The UI must not fabricate authoritative attendance or journey state for visual speed.

When certainty is required, show a clear loading or pending interaction state.

---

# Principle 8 — Progressive Disclosure

Relvio should show users the information and controls relevant to their current task.

Secondary information or actions may be revealed through approved interaction patterns where appropriate.

Progressive disclosure may use:

* Expandable content
* Secondary screens
* Bottom sheets
* Dialogs
* Overflow actions
* Contextual sections

only when supported by the approved UI or product requirement.

Do not hide critical information merely to make a screen appear minimal.

Do not invent “advanced options” without an approved product requirement.

Progressive disclosure is an information hierarchy principle.

It is not a feature-generation rule.

---

# Principle 9 — Mobile First for Relvio v1

Relvio v1 is designed for:

```text
Android
iOS
```

The Flutter implementation must prioritize supported mobile experiences.

Design and implementation should account for:

* Mobile screen sizes
* Safe areas
* Touch interaction
* Mobile navigation
* Readable content
* Appropriate touch targets
* Mobile keyboard behavior
* Platform interaction expectations where relevant

Do not expand Relvio v1 design scope to:

* Web
* Windows
* macOS
* Linux
* Desktop-specific layouts

unless those platforms are explicitly approved in future product scope.

Tablet and desktop enhancement is not an automatic v1 requirement.

---

# Principle 10 — Accessibility Is Product Quality

Relvio should be usable by as many supported users as reasonably possible.

Mobile accessibility implementation should consider:

* Readable typography
* Sufficient contrast
* Meaningful semantics
* Screen reader labels where required
* Appropriate touch targets
* Clear interaction states
* Meaning that does not rely only on color

Accessibility must be considered during Flutter implementation and testing.

Do not silently redesign the frozen UI under the assumption that a change improves accessibility.

If an approved design creates a genuine accessibility issue:

1. Identify the affected screen or component.
2. Document the issue.
3. Return the issue to Design for intentional resolution.
4. Implement the approved correction.

Accessibility improvements should be deliberate and documented.

---

# Principle 11 — Help Users Recover

Users may make mistakes.

Networks may fail.

Requests may time out.

Sessions may expire.

Relvio should provide appropriate recovery where recovery is possible.

Recovery patterns may include:

* Clear validation
* Retry actions
* Confirmation for high-impact actions
* Returning to a safe screen
* Re-authentication
* Clear error explanation

Do not automatically add:

* Undo
* Autosave
* Drafts

to every feature.

These are product capabilities and require approved behavior.

A confirmation dialog should not be used for every action.

Use stronger confirmation for actions with meaningful destructive or irreversible impact.

---

# Principle 12 — Trust Through Predictability

Relvio handles organizational and people data.

The interface should build confidence through predictable behavior.

Users should not be surprised by:

* Hidden data mutations
* Unexpected navigation
* Silent failures
* Unclear destructive actions
* Permission behavior that appears random
* Data appearing to move between organizations

Where appropriate, users should understand:

* What happened
* Whether the action succeeded
* Why an action cannot continue
* What they can do next

Do not expose sensitive security or authorization details merely to provide an explanation.

User-facing clarity must remain compatible with secure error handling.

---

# Principle 13 — Organization Context Must Remain Clear

Relvio is a multi-tenant SaaS.

Organization isolation is a critical backend security boundary.

The backend enforces organization isolation.

Product design should avoid creating confusing experiences where users cannot understand the relevant organization context when that context matters.

The UI must not imply that:

* Data belongs to another organization
* A user can access an unauthorized organization
* Organization switching has completed before authoritative state is available

Visual organization context is not a security boundary.

The backend remains responsible for:

* Organization membership
* Organization access
* Roles
* Permissions
* Organization isolation

The UI must accurately represent backend-authorized state.

---

# Principle 14 — One Clear Hierarchy of Actions

Each screen should present a clear action hierarchy.

Actions may be:

* Primary
* Secondary
* Contextual
* Destructive

The approved UI determines the action hierarchy.

Do not enforce an arbitrary rule that every screen must contain exactly one primary action.

Some screens may:

* Primarily display information
* Contain no immediate primary action
* Require multiple related actions
* Use contextual actions

The important requirement is that competing actions do not create unnecessary confusion.

Visual emphasis should match product importance.

---

# Principle 15 — Critical Actions Deserve Deliberate Interaction

Actions affecting important data should be designed with their consequences in mind.

Examples include actions affecting:

* Attendance
* Journey transitions
* Organization membership
* Roles
* Permissions
* Destructive data operations

The interface should help prevent accidental repeated or destructive actions where appropriate.

Possible interaction safeguards may include:

* Loading states
* Disabled repeated submission
* Confirmation
* Clear action labels
* Explicit destructive treatment

UI safeguards do not replace backend integrity controls.

Attendance still requires backend idempotency.

Permissions still require backend authorization.

Organization isolation remains a backend security boundary.

---

# Principle 16 — Design States, Not Only Ideal Screens

A production interface must handle more than the successful loaded state.

Implementation should consider the states relevant to each approved screen.

Possible states include:

```text
Initial
Loading
Loaded
Empty
Error
Disabled
Submitting
Retry
```

Not every screen requires every state.

State requirements depend on the feature.

Animations, shimmer, skeletons, loading states, empty states, error states, and micro-interactions may be implemented during Flutter coding where appropriate.

These states must preserve the approved Relvio visual language.

Do not invent unrelated visual styles for implementation states.

---

# Principle 17 — Empty States Should Be Useful

An empty state should help users understand why content is absent.

Where appropriate, it may also explain the next relevant action.

An empty state may contain:

* Clear message
* Supporting context
* Relevant action

An illustration is not mandatory.

Do not create decorative illustrations merely because a screen is empty.

If an approved illustration is required, use the approved asset.

Missing approved brand assets must be reported.

---

# Principle 18 — Error Messages Should Be Human

User-facing errors should communicate useful information without exposing internal implementation details.

Avoid displaying:

* Raw exceptions
* Stack traces
* Database errors
* Internal service names
* Raw HTTP error text

Prefer clear explanations appropriate to the failure.

For example:

Instead of:

```text
Authentication failed.
```

a user-facing message may communicate:

```text
We couldn't sign you in. Check your details and try again.
```

The exact message should match the actual failure where the product can safely determine it.

Do not claim a specific cause when the application does not know the cause.

Error copy should be:

* Clear
* Calm
* Accurate
* Actionable where possible

---

# Principle 19 — Micro-Interactions Should Support Understanding

Small interaction details can improve product quality.

Appropriate micro-interactions may help communicate:

* Pressed state
* Selection
* Navigation transition
* Loading
* Completion
* State change

Animations should support comprehension and perceived quality.

Do not add animation merely to make the product feel impressive.

Avoid:

* Excessive motion
* Decorative delays
* Long transitions
* Repeated attention-seeking effects
* Animation that blocks user progress

Simple animation should be implemented directly in Flutter where appropriate.

Do not introduce Lottie or Rive by default.

Animation asset rules are governed by:

* `Asset_Structure.md`
* `Brand Assets.md`

---

# Principle 20 — Whitespace Creates Hierarchy

Whitespace is an intentional part of the Relvio visual system.

Spacing helps communicate:

* Grouping
* Separation
* Priority
* Reading order

Do not fill empty space merely because a screen appears visually sparse.

Do not compress approved layouts to display more information at once without a product requirement.

Spacing implementation must follow approved UI intent and centralized design values.

---

# Principle 21 — Reuse Without Premature Abstraction

Relvio should remain visually and technically consistent as features grow.

Repeated approved patterns should be reused.

However, future possibilities must not drive unnecessary v1 abstraction.

Do not build components or systems for hypothetical:

* Enterprise modules
* Desktop features
* Advanced integrations
* Automation
* White-label products
* Future navigation structures

before approved product requirements exist.

Component strategy is governed by:

* `Component Library.md`

Architecture remains feature-first with controlled data, domain, and presentation boundaries.

Build for current approved requirements while preserving maintainable boundaries.

---

# Principle 22 — Product Language Must Remain Consistent

Relvio terminology must remain consistent across screens.

Approved product terms must not be casually renamed during implementation.

The approved primary navigation label is:

```text
Workspace
```

Do not use:

```text
More
```

for the final primary navigation destination.

Use organization-neutral language for core Relvio concepts unless a feature or market-specific experience explicitly requires otherwise.

Do not silently replace product terminology with church-only language.

Churches are a strong initial validation market.

Relvio remains a People Operating System for people-centered organizations.

---

# Principle 23 — Data Integrity Is Part of User Experience

A visually polished interface that displays incorrect or inconsistent data is not a successful design.

Product quality includes confidence that user actions produce reliable results.

This is especially important for:

* Attendance
* Journey history
* Organization context
* Roles
* Permissions
* People records

The interface must represent authoritative application state accurately.

Do not prioritize animation, instant state changes, or visual smoothness over data correctness.

Trust is built through reliable behavior.

---

# Principle 24 — Design for the Approved Product, Not the Generic Category

Relvio may share concepts with:

* CRM products
* Attendance systems
* Church management systems
* Membership platforms
* Organization management tools

Relvio must not automatically inherit every pattern or feature from those categories.

Do not add:

* CRM complexity
* Church-only terminology
* Enterprise administration patterns
* Generic dashboard widgets
* Desktop data tables
* Kanban systems
* Automation builders

merely because comparable products use them.

Every Relvio design decision must come from approved product requirements and product intent.

---

# Future Design Work

When designing a future approved Relvio feature, use the following process:

```text
Approved Product Requirement
        ↓
Understand User Responsibility
        ↓
Understand Required Data and Actions
        ↓
Review Existing Relvio Patterns
        ↓
Design the Simplest Clear Flow
        ↓
Validate Critical States
        ↓
Check Product and Architecture Constraints
        ↓
Approve UI
        ↓
Freeze UI for Implementation
```

Do not begin with a generic component catalogue or competitor screen and force Relvio requirements into it.

---

# Design Review Questions

Before approving future product design, ask:

* Is the purpose of the screen clear?
* Does the design support the approved product requirement?
* Is the information hierarchy understandable?
* Are important actions clear?
* Are critical states considered?
* Does the design remain organization-neutral where required?
* Does it use established Relvio patterns appropriately?
* Does it avoid unnecessary complexity?
* Does it preserve accessibility intent?
* Does it represent data state truthfully?
* Does it protect trust around critical actions?
* Does it introduce an unapproved feature?
* Can the approved interaction be implemented within the Relvio architecture?

A negative answer does not automatically require more UI.

The correct response may be to simplify, clarify, remove, or return to the product requirement.

---

# AI Coding Assistant Rules

AI coding assistants must not use design principles as permission to redesign approved Relvio UI.

AI coding assistants must not:

* Add recent searches without approval.
* Add smart suggestions without approval.
* Add predictive behavior without approval.
* Add autosave without approval.
* Add drafts without approval.
* Add undo systems without approval.
* Add optimistic updates to critical flows without integrity review.
* Add desktop or tablet product scope.
* Force exactly one primary action onto every screen.
* Add decorative animations.
* Add illustrations to every empty state.
* Rename approved product terminology.
* Replace `Workspace` with `More`.
* Introduce church-only terminology into core product UI.
* Simplify away important product information.
* Redesign approved screens for generic accessibility assumptions.
* Build speculative systems for future features.

When a static approved UI does not define a required implementation state, the AI coding assistant must:

1. Identify the missing state.
2. Review existing approved Relvio patterns.
3. Apply the relevant principles in this document.
4. Preserve the approved screen's visual intent.
5. Avoid introducing new product capability.
6. Report genuine product or design ambiguity instead of inventing behavior.

---

# Source of Truth Priority

For product design decisions:

1. Approved Relvio product decisions define product scope and behavior.
2. Approved Relvio UI defines frozen v1 visual and interaction intent.
3. `Design Principles.md` defines product design judgment.
4. `19_Brand_Identity.md` defines brand identity and brand character.
5. `Component Library.md` defines component reuse and ownership.
6. `Color System.md` defines color governance.
7. `Brand Assets.md` defines brand asset governance.
8. `Asset_Structure.md` defines Flutter production asset organization.
9. Approved engineering and architecture documents define implementation boundaries.

Design principles must not override backend integrity or security requirements.

The backend REST API remains authoritative for:

* Authentication
* Organization membership
* Roles
* Permissions
* Business rules
* Validation
* Organization isolation
* Protected data mutations

If a genuine contradiction exists, the affected design or implementation decision must stop and be clarified.

---

# Success Criteria

The Relvio design principles are successful when:

* The approved v1 UI is implemented without redesign.
* Relvio feels clear, calm, human, and trustworthy.
* Product experiences focus on people and relationships.
* Users receive clear and truthful interaction feedback.
* Critical data state is represented accurately.
* Mobile experiences work correctly on Android and iOS.
* Repeated design patterns remain consistent.
* Loading, empty, and error states feel intentional.
* Accessibility is considered without undocumented redesign.
* Future features grow from approved product requirements.
* Organization-neutral product language is preserved.
* AI coding assistants can resolve implementation details without inventing product capabilities.
* Visual polish never takes priority over security or data integrity.

---

# Final Principle

Relvio should not feel powerful because it exposes complexity.

Relvio should feel powerful because it helps organizations understand their people and build stronger relationships with clarity and confidence.

---

# End of Document
