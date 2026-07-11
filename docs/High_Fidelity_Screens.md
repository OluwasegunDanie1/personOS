---
Document: High-Fidelity Screens
Version: 1.1
Status: Approved
Project: Relvio
Owner: Design Team
---

# High-Fidelity Screens

## Purpose

This document defines how approved Relvio high-fidelity screen designs are interpreted during implementation.

The Relvio v1 mobile UI is already complete, approved, and frozen.

This document does not define a new screen inventory.

This document does not redesign approved screens.

This document does not authorize implementation teams or AI coding assistants to invent missing screens, controls, fields, navigation destinations, or responsive platform layouts.

Approved high-fidelity UI references are the visual blueprint for Flutter implementation.

---

# Approved Product Platforms

Relvio v1 product platforms are:

- Android
- iOS

The approved v1 high-fidelity UI is mobile-focused.

This document does not approve:

- Web application UI
- Desktop application UI
- Tablet-specific product layouts
- Desktop navigation systems
- Desktop tables
- Desktop dashboard layouts
- Fixed desktop breakpoint designs

Flutter must not create web or desktop UI infrastructure from this document.

Tablet behavior may use reasonable Flutter layout adaptation where required by the mobile application runtime, but tablet-specific product redesign is not approved unless separately documented.

---

# High-Fidelity UI Authority

The approved frozen Relvio UI is the visual authority for v1 implementation.

Approved screen references control visible decisions such as:

- Screen composition
- Visual hierarchy
- Navigation presentation
- Content placement
- Component appearance
- Typography usage
- Color usage
- Spacing relationships
- Radius usage
- Icon placement
- Button presentation
- Card presentation
- Input presentation
- Empty visual space
- Approved visible states

Implementation must reproduce the approved design faithfully.

Textual documentation must not silently override an approved visual decision.

If a textual document and an approved high-fidelity screen appear to conflict, the conflict must be reported and resolved through documentation review.

Claude or another AI coding assistant must not choose a new design direction.

---

# Frozen UI Rule

The approved Relvio v1 mobile UI is frozen.

Do not:

- Redesign approved screens
- Rearrange approved screen hierarchy
- Add visible product features because they appear common in similar applications
- Replace approved components with generic Material defaults
- Add unapproved tabs
- Add unapproved navigation destinations
- Add unapproved dashboard widgets
- Add unapproved profile sections
- Add unapproved settings sections
- Add unapproved filters
- Add unapproved fields
- Add unapproved action buttons
- Add desktop-style controls
- Add speculative responsive layouts

A screen may only change when an approved product or design decision explicitly changes it.

---

# Product Naming

The public product name is:

**Relvio**

The internal early codename Atlas must not appear in production UI.

Approved Relvio logo assets must be used directly.

Do not recreate the Relvio logo:

- From screenshots
- With Flutter drawing code
- With generic icons
- With text approximations
- With generated replacement artwork

If an approved required logo asset is missing, report the missing asset.

Do not invent a replacement.

---

# Brand Alignment

Approved Relvio brand decisions remain authoritative.

Primary brand color:

`#2563FF`

Primary application background:

`#FCFCFD`

Typeface:

`Inter`

Primary brand message:

> Build stronger relationships.

High-fidelity implementation must remain consistent with approved brand documentation.

This document does not redefine the brand identity.

---

# Navigation

The approved frozen navigation design must be implemented as shown in the approved UI references.

The final approved primary bottom navigation label is:

**Workspace**

Do not use:

**More**

Workspace must replace obsolete More naming in:

- Visible navigation labels
- Screen names
- Route naming
- Folder naming
- Provider naming
- Test naming

Do not add navigation destinations that are not present in approved product and UI documentation.

---

# Screen Inventory

The approved high-fidelity screen inventory is determined by the frozen Relvio v1 UI references and approved product documentation.

This document intentionally does not reproduce a speculative screen-by-screen feature list.

A textual screen inventory must not become a second visual specification.

Implementation teams must use the approved UI references for the actual visible screen structure.

If an implementation-required screen cannot be identified in the approved references or approved product documentation:

1. Do not invent the screen.
2. Do not copy a generic SaaS pattern.
3. Do not derive the screen from the old Atlas drafts.
4. Report the missing design or documentation decision.
5. Wait for clarification or approval.

---

# Screen Implementation

Approved screens must be implemented as Flutter widgets.

UI screenshots are design references.

They are not production UI assets.

Do not:

- Place complete screenshots inside Flutter screens
- Crop buttons from screenshots
- Crop cards from screenshots
- Crop text from screenshots
- Crop standard icons from screenshots
- Use screenshots to simulate interactive UI

Flutter must implement the visible interface using real widgets.

Approved production image and brand assets must follow `Asset_Structure.md` and `Brand Assets.md`.

---

# Visual Fidelity

Implementation should preserve the approved visual relationships shown in the high-fidelity UI.

Important areas include:

- Content hierarchy
- Alignment
- Relative spacing
- Component dimensions
- Typography hierarchy
- Icon sizing and placement
- Border treatment
- Radius treatment
- Surface treatment
- Background treatment
- Visual emphasis
- Navigation balance

The goal is faithful implementation of the approved Relvio UI.

The goal is not to reinterpret the UI using a generic Flutter or Material design style.

---

# Design Tokens

Approved design tokens must be used where a verified centralized token exists.

`Design Tokens.md` controls approved token definitions.

`Color System.md` controls approved color responsibilities.

`Flutter Theme Implementation.md` controls Flutter theme implementation boundaries.

`Component Library.md` controls approved shared component responsibilities.

Do not create generic token scales to fill perceived gaps.

Do not invent:

- Spacing scales
- Radius scales
- Shadow scales
- Motion scales
- Breakpoint scales

Unique intentional approved values may remain local where appropriate.

The goal is controlled consistency, not zero numeric literals.

---

# Components

Repeated approved visual responsibilities should use approved centralized components where appropriate.

A shared component should reflect a genuinely repeated Relvio UI responsibility.

Do not create generic component abstractions solely because multiple Flutter widgets look technically similar.

Do not force unique approved screens into shared components when doing so damages visual fidelity or creates unnecessary configuration complexity.

Material defaults must not silently redefine approved Relvio components.

---

# Screen States

Relvio screens must handle real application states required by their implemented behavior.

Relevant states may include:

- Initial loading
- Refreshing
- Loaded content
- Empty content
- Recoverable error
- Unavailable action
- Submission in progress
- Submission failure
- Submission success

The exact states for a screen depend on its approved behavior and data requirements.

Do not create decorative state variants that have no product or technical purpose.

Do not add visible state designs that conflict with the frozen UI.

Where an implementation-required state is not visually specified, use the approved Relvio design system and existing approved visual language without redesigning the screen.

If the missing state requires a significant product or visual decision, report it.

---

# Loading Behavior

Loading behavior should match the real asynchronous responsibility of the screen.

Appropriate techniques may include:

- Progress indicators
- Skeleton content
- Shimmer
- Local button loading states
- Inline loading states
- Refresh indicators

No single loading technique is mandatory for every screen.

Skeletons and shimmer must not be added mechanically.

Loading UI should:

- Preserve layout stability where practical
- Avoid misleading fake content
- Communicate active work
- Avoid duplicate submissions
- Remain visually consistent with Relvio

Implementation details may be completed during Flutter coding where appropriate.

---

# Empty States

Empty states should communicate the actual absence of relevant content.

Where appropriate, an empty state may include:

- Clear empty-state messaging
- Supporting context
- An approved relevant action

Illustrations are not mandatory.

Do not invent illustration assets.

Do not add actions that are not approved product actions.

Empty states must remain consistent with the frozen Relvio UI and approved product behavior.

---

# Error States

Errors should be handled according to actual application and API behavior.

Potential categories include:

- Recoverable loading failure
- Validation failure
- Authentication failure
- Authorization failure
- Network unavailability
- Resource unavailability
- Server failure

This document does not require dedicated visual pages for every HTTP status code.

Backend HTTP behavior is controlled by approved API and security documentation.

Flutter should present user-appropriate feedback without exposing internal implementation details.

Do not invent new product navigation to handle technical errors.

---

# Interaction States

Flutter implementation must support interaction states that are relevant to mobile use.

These may include:

- Default
- Pressed
- Focused
- Disabled
- Loading
- Validation error

Desktop hover behavior is not a v1 mobile design requirement.

Interaction states should use approved Relvio visual responsibilities.

Do not introduce a generic interaction-state system that changes the frozen visual language.

---

# Motion and Micro-Interactions

Animations, transitions, shimmer, skeletons, loading states, and micro-interactions may be implemented during Flutter coding where appropriate.

Simple animations should be implemented directly in Flutter where practical.

Do not add Lottie or Rive by default.

Motion should:

- Support understanding
- Reinforce state changes
- Feel responsive
- Remain subtle
- Avoid delaying primary actions
- Avoid unnecessary visual noise

This document does not approve new animated product experiences.

---

# Accessibility

Approved high-fidelity screens must be implemented with practical mobile accessibility considerations.

Implementation should consider:

- Semantic meaning
- Readable text
- Appropriate touch targets
- Screen reader support
- Logical focus behavior
- Form labels
- Error communication
- Sufficient visual distinction for important states

Accessibility implementation must preserve the approved Relvio product hierarchy and visual identity where possible.

If an approved visual decision creates a serious accessibility conflict, report the conflict for review rather than silently redesigning the screen.

---

# Theme Boundary

Relvio v1 uses the approved light theme.

Dark mode is not approved for v1.

System theme switching is not approved.

Do not add:

- A theme toggle
- An Appearance settings section for theme switching
- Riverpod theme state
- Dark theme infrastructure
- Organization-controlled application themes
- White-label theme infrastructure

`Flutter Theme Implementation.md` remains authoritative for Flutter theme rules.

---

# Responsive Boundary

Relvio v1 is a mobile application for Android and iOS.

Implementation must handle supported mobile screen sizes without breaking the approved UI.

Layouts should avoid:

- Unintentional overflow
- Clipped essential content
- Unreachable controls
- Broken text layout
- Unsafe system-area placement

Responsive implementation should preserve the approved mobile design rather than create new desktop or tablet product layouts.

Do not derive desktop breakpoints or desktop screens from the mobile UI.

---

# Prototype Status

The approved high-fidelity UI and approved design references represent the design direction for v1 implementation.

This document does not require a new prototype phase before Flutter coding.

Do not recreate approved flows merely to satisfy an outdated Atlas prototype checklist.

If interaction behavior is unclear during implementation, compare:

1. Approved UI references
2. Approved product documentation
3. Approved API documentation
4. Approved architecture documentation

If the behavior remains undefined, report the missing decision.

Do not invent the interaction.

---

# AI Implementation Rules

Claude or another AI coding assistant acts as an implementation engineer.

When implementing approved high-fidelity screens, AI must not invent:

- Screens
- Product features
- Navigation destinations
- Fields
- Filters
- Dashboard widgets
- Journey stages
- Reports
- Settings sections
- Organization branding controls
- Theme controls
- Desktop layouts
- Tablet product layouts
- API endpoints
- API fields
- Database structures

AI should implement the approved Relvio UI using approved documentation as architectural and product guidance.

When information is missing or contradictory, AI must report the issue.

It must not resolve product ambiguity by inventing a common SaaS pattern.

---

# Documentation Responsibilities

This document owns:

- High-fidelity UI implementation authority
- Frozen screen governance
- Visual reference interpretation
- Screen implementation boundaries
- Missing-design handling rules

This document does not own:

- Product feature scope
- API contracts
- Database structures
- Security rules
- Architecture
- Design token definitions
- Color definitions
- Shared component specifications
- Flutter theme architecture
- Asset organization

Those responsibilities remain with their approved Relvio documents.

---

# Implementation Readiness

The high-fidelity UI is considered ready for implementation because the Relvio v1 mobile design has been approved and frozen.

Flutter implementation may rely on the approved UI references when:

- The screen is part of approved product scope
- The required visual reference exists
- Required approved assets exist
- Required product behavior is documented
- Required API behavior is documented where applicable

If one of these requirements is missing, the implementation gap must be reported.

Do not redesign or invent the missing responsibility.

---

# Success Criteria

High-fidelity screen implementation is successful when:

- Approved Relvio screens are reproduced faithfully
- The frozen UI is not redesigned
- Flutter uses real widgets rather than screenshot fragments
- Approved assets are used directly
- Product behavior is not invented from visual assumptions
- Mobile layouts remain stable across supported Android and iOS screen sizes
- Loading, empty, error, and interaction states support real application behavior
- AI coding assistants can distinguish visual authority from product and architecture authority
- Missing design decisions are reported instead of invented

---

# End of Document