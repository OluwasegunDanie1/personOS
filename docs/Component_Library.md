---
Document: Component Library
Version: 1.1
Status: Approved
Project: Relvio
Owner: Design & Engineering
---

# Component Library

## Purpose

This document defines the rules for identifying, implementing, and maintaining reusable Flutter UI components in Relvio.

The Relvio v1 mobile UI is already approved and frozen.

This document does not design new components.

It exists to help implementation engineers and AI coding assistants:

- Reuse repeated UI patterns
- Preserve visual consistency
- Avoid duplicated widget implementations
- Keep feature code maintainable
- Respect the approved Relvio UI
- Avoid creating speculative design-system abstractions

Relvio v1 targets:

- Android
- iOS

The approved frontend technology is:

- Flutter

---

# Core Principle

A component should be extracted because an approved UI pattern is repeated or clearly shared.

Do not create a component merely because a generic design system normally contains one.

The implementation direction is:

```text
Approved Relvio UI
        ↓
Identify Repeated Visual Patterns
        ↓
Define Shared or Feature Component
        ↓
Implement Reusable Flutter Widget
        ↓
Reuse Across Approved Screens



Do not reverse this process by creating a large generic component library and forcing approved Relvio screens to use speculative components.

Source of Truth

The approved Relvio UI is the source of truth for:

Component appearance
Visual hierarchy
Layout intent
Component states visible in the design
Navigation presentation
Spacing intent
Typography intent
Color intent
Icon intent

Flutter components must match the approved UI.

If approved design source files or component specifications exist, they may provide exact implementation values.

A Figma component library must not be assumed to exist unless it is explicitly available and approved.

UI screenshots are design references.

They are not production assets.

Do not crop UI components from screenshots.

Flutter must implement interface components as widgets.

Component Design Principles

Relvio components should be:

Consistent
Focused
Reusable where appropriate
Maintainable
Accessible for supported mobile use
Easy to understand
Aligned with the approved UI

A component should solve a clear interface responsibility.

Avoid:

Premature abstraction
Highly configurable universal widgets
Feature logic inside shared visual components
Duplicated shared UI patterns
Generic design-system components with no approved Relvio use
Component Ownership

Relvio components are divided into two primary ownership levels:

Shared Components
Feature Components

The correct ownership level should be selected based on actual reuse and domain responsibility.

Shared Components

Shared components are reusable across multiple Relvio features.

They belong in the approved shared or core presentation structure defined by the project architecture.

Examples may include approved implementations of:

Primary buttons
Secondary buttons
Text fields
Search fields
App bars
Avatars
Status indicators
Empty-state containers
Error-state containers
Loading indicators
Confirmation dialogs
Shared bottom sheets
Shared cards
Navigation components

This list defines possible shared responsibilities.

It does not require every listed component to exist.

A shared component should only be created when supported by the approved UI or repeated implementation needs.

Feature Components

Feature components belong to a specific Relvio feature.

Examples may include UI patterns specific to:

Dashboard
People
Attendance
Events
Journeys
Workspace

A feature component should remain inside its feature when:

It represents feature-specific data
It contains feature-specific presentation logic
It is not reused outside the feature
Moving it to shared code would create unnecessary abstraction

Do not move a widget into the shared component library simply because it is visually a card, row, or tile.

Domain-specific UI should remain feature-owned unless genuine reuse exists.

Shared Component Promotion Rule

A feature component may be promoted to the shared component library when:

The same visual responsibility is used across multiple features.
The component can remain domain-neutral.
The public API can remain focused.
Promotion reduces duplication.
Promotion does not introduce feature-specific conditions into shared code.

Do not create shared widgets containing logic such as:

if attendance
if journey
if event
if person

to support unrelated feature variants.

Prefer feature composition over a universal component with excessive conditional configuration.

Foundations

Shared components must consume approved Relvio design foundations.

These include:

Color tokens
Typography styles
Spacing tokens
Radius values
Approved icon usage
Approved asset references

Feature widgets must not independently recreate design foundations.

Relevant design documentation includes:

19_Brand_Identity.md
Color System.md
Brand Assets.md
Asset_Structure.md
Approved Relvio UI
Colors

Components must use centralized approved color tokens.

Do not hardcode raw color values throughout component implementations.

The approved primary brand color is:

#2563FF

The approved primary application background is:

#FCFCFD

All additional component colors must come from the approved design token system.

Color governance is defined by:

Color System.md
Typography

Components must use centralized approved typography styles.

The approved Relvio typeface is:

Inter

Do not define unrelated text style systems independently inside features.

Typography style names should describe approved semantic responsibilities.

Possible responsibilities may include:

display
heading
title
body
label
caption

The final typography token structure must follow the approved typography documentation and UI.

Do not assume every possible typography category must exist.

Spacing and Radius

Components must use approved centralized spacing and radius values where defined.

Do not scatter arbitrary repeated values throughout shared widgets.

Do not replace exact approved layout requirements with generic spacing merely to fit a token scale.

Where an approved UI value is intentionally unique, preserve the approved design.

Icons

Icons must match the approved Relvio UI.

Do not assume a universal icon size scale such as:

16
20
24
32
40
48

unless those values are confirmed during approved UI implementation.

Icon sizes should use centralized values where repeated.

The implementation team may select an appropriate Flutter icon source or library based on the approved UI.

Do not introduce multiple unrelated icon libraries without a clear implementation requirement.

Do not recreate the Relvio logo using an icon system.

Logo usage is governed by:

20_Logo_Strategy.md
Brand Assets.md
Buttons

Implement only button variants required by the approved Relvio UI.

Possible shared button responsibilities may include:

Primary action
Secondary action
Text action
Icon action

Do not automatically create:

Floating action buttons
Tertiary buttons
Gradient buttons
Split buttons
Desktop hover button systems

unless required by approved UI.

Button appearance must follow the approved Relvio design.

Button States

Buttons should support the interaction states required by their approved use.

For Relvio mobile v1, relevant states may include:

Default
Pressed
Disabled
Loading

Additional states such as focus may be supported where required by Flutter accessibility or platform interaction behavior.

Do not design desktop hover behavior as a Relvio v1 requirement.

Loading states must prevent accidental duplicate submissions where appropriate.

A disabled visual state does not replace backend authorization or business-rule enforcement.

Primary Actions

Primary actions use the approved Relvio primary action treatment.

The primary brand color is:

#2563FF

Do not assume every screen must contain exactly one primary action.

The approved UI determines action hierarchy.

Button labels must match approved product terminology and UI copy.

Do not rename actions during implementation.

Inputs

Implement input components required by approved Relvio screens.

Possible shared input responsibilities may include:

Text field
Search field
Password field
Multiline text field
Selection field
Date input
Time input
Checkbox
Radio selection
Switch

This list is not a mandatory component backlog.

Only implement components required by approved product flows.

Input Validation

Input components display validation feedback.

They do not define authoritative business rules.

Validation responsibilities are separated as follows:

Flutter UI
- Immediate input feedback
- Required-field presentation
- Format guidance
- User-friendly validation messages

Backend API
- Authoritative validation
- Business rules
- Permission checks
- Organization isolation
- Data integrity

Client validation must never be treated as a security boundary.

Search Fields

Search components must follow the approved Relvio UI.

A search field may support:

Search input
Approved search icon
Clear action
Loading state
Empty result state
Error state

depending on the feature requirement.

Do not automatically implement:

Global search
Recent searches
Search suggestions
Keyboard shortcuts
Result grouping

unless approved product requirements explicitly define them.

Navigation Components

Relvio v1 mobile navigation must follow the approved UI.

The approved primary bottom navigation uses:

Workspace

not:

More

Do not rename the approved navigation labels.

Do not introduce:

Desktop sidebars
Breadcrumbs
Desktop navigation rails
Collapsible navigation systems

as Relvio v1 requirements.

Routing is implemented using:

GoRouter

Navigation components present approved navigation UI.

They must not independently invent routing architecture.

Bottom Navigation

The bottom navigation must match the approved Relvio mobile UI.

Navigation items, labels, icons, active states, and layout must follow the approved design.

The final navigation label is:

Workspace

Do not use:

More

in the primary navigation.

Do not apply a generic rule such as “maximum five items” as an architectural requirement.

The approved Relvio UI determines the navigation structure.

App Bars

App bar and header components must follow approved screen designs.

Do not assume every app bar contains:

Logo
Search
Notifications
User menu

The approved screen determines:

Title
Leading action
Trailing actions
Search behavior
Navigation behavior

Avoid creating one universal app bar with excessive conditional properties.

Use shared app bar patterns only where genuine visual reuse exists.

Cards

Cards should be implemented from approved repeated UI patterns.

Possible Relvio card patterns may represent:

People
Events
Attendance information
Journey information
Dashboard information
Workspace actions

Do not create generic domain cards before reviewing approved screens.

A PersonCard should not become a universal card for events, attendance, and journeys.

Prefer focused feature components composed from shared foundations.

Lists

List presentation should follow approved feature UI.

Repeated list-row patterns may become reusable components when they share the same visual responsibility.

Lists must handle appropriate states such as:

Loading
Loaded
Empty
Error

where the feature requires them.

Pagination or incremental loading must follow API and feature requirements.

Do not assume every list requires client-side pagination controls.

Timeline Components

Timeline UI may be implemented where required by approved Relvio screens.

Potential uses include:

Person activity
Journey history
Other approved historical views

Timeline components are presentation components.

Journey history data remains governed by backend integrity rules.

A timeline must not mutate or reconstruct immutable journey transition history.

The backend data is authoritative.

Journey Components

Journey UI must reflect approved Relvio journey designs.

Do not assume a Kanban board is required.

Do not implement drag-and-drop journey transitions unless explicitly defined by the approved product flow and backend API.

Journey transitions must use approved backend operations.

The UI must not directly reorder or rewrite journey history.

Journey history remains immutable.

Attendance Components

Attendance components must reflect approved Relvio attendance UI.

Attendance interactions must respect backend integrity and idempotency requirements.

A loading or disabled UI state should help prevent repeated user actions.

It does not replace backend idempotency.

Attendance components must not fabricate successful attendance state before authoritative API behavior is handled according to the approved feature implementation.

Feedback Components

Shared feedback patterns may include:

Snackbar
Inline message
Error container
Progress indicator
Loading state
Empty state

Only approved visual patterns should be implemented.

Feedback components should use clear, human language.

Avoid exposing raw:

HTTP status text
Stack traces
Internal exception names
Database errors

to users.

Loading Components

Relvio may use:

Progress indicators
Skeletons
Shimmer
Inline loading states

where appropriate during Flutter implementation.

Loading patterns should match the approved UI and interaction context.

Do not introduce Lottie or Rive by default.

Simple loading animations should be implemented directly in Flutter where appropriate.

Loading colors must use approved centralized color tokens.

Empty States

Empty states should clearly explain the current state and, where appropriate, provide a relevant next action.

An empty state may contain:

Message
Supporting text
Action

An illustration is not mandatory.

If the approved UI requires an illustration, use the approved asset.

Missing approved assets must be reported.

Do not invent or generate a replacement illustration during coding.

Error States

Error states should provide:

A clear user-facing explanation
A recovery action where appropriate

Examples of recovery actions may include:

Retry
Return
Refresh
Sign in again

The correct action depends on the failure.

Do not expose internal implementation details.

Error presentation does not replace structured application error handling.

Dialogs

Dialogs should be used where required by approved Relvio interactions.

Possible uses include:

Destructive confirmation
Logout confirmation
Removal confirmation
Other high-impact actions

Do not create a dialog for every confirmation.

The approved interaction flow determines whether a dialog, bottom sheet, inline confirmation, or direct action is appropriate.

Bottom Sheets

Bottom sheets may be used for approved mobile interactions such as:

Actions
Filters
Selection
Compact forms

Do not automatically move every secondary interaction into a bottom sheet.

Bottom sheet use must follow approved Relvio UI patterns.

Menus

Overflow and action menus may be implemented where required by approved screens.

Menu items must respect:

User permissions
Organization membership
Backend business rules

Hiding an action in the UI is not authorization.

The backend must enforce protected operations.

Avatars

Avatar components should follow approved Relvio UI.

They may display:

Approved profile image
Initials fallback
Approved placeholder state

Status indicators should only appear where defined by the approved UI.

Do not assume a fixed avatar size scale.

Centralize repeated avatar sizes when implementation confirms shared values.

Badges and Status Indicators

Badges and status indicators must represent approved UI and domain states.

Do not create a universal status-to-color mapping based only on status names.

Status color governance is defined by:

Color System.md

Critical meaning should not rely only on color.

Use approved labels, icons, or supporting presentation where appropriate.

Chips and Filters

Chip and filter components should only be implemented where required by approved screens.

Possible uses include:

Filters
Tags
Approved categories

Do not assume all chips are removable.

Do not create a universal chip component with every possible behavior unless genuine reuse requires it.

Charts and Metrics

Do not create a generic chart library as part of Relvio v1 implementation.

Charts should only be implemented when an approved Relvio screen requires a specific visualization.

Do not automatically support:

Line charts
Bar charts
Pie charts
Area charts

because they appeared in the Atlas draft.

For every approved chart:

Confirm the screen requirement.
Confirm the data source.
Confirm the metric definition.
Confirm the visual design.
Select an implementation approach appropriate to that chart.

KPI or metric cards should be treated as approved UI components, not automatically classified as charts.

Calendar Components

Do not build a general calendar system unless required by approved Relvio v1 screens.

Do not automatically support:

Month view
Week view
Day view
Agenda view

The approved event flows and UI determine date-related component requirements.

Date and time pickers are input components and are separate from a full calendar feature.

Notifications

Notification UI should only be implemented according to approved Relvio product scope and screens.

Do not assume a global notification center exists merely because a notification component appeared in the Atlas draft.

If notification items are required, their visual structure must follow the approved UI.

Notification delivery architecture is outside the responsibility of a visual component.

File Upload

File upload UI should only be implemented where an approved Relvio flow requires file or image selection.

Relvio v1 mobile must not automatically implement desktop interaction patterns such as:

Drag and Drop

Mobile file or image selection should use the approved product flow and appropriate platform capabilities.

Upload progress should be displayed where the approved interaction requires it.

File validation and authorization must remain enforced by the backend where applicable.

Responsive Behavior

Relvio v1 targets:

Android
iOS

Components must behave correctly across supported mobile screen sizes.

Layouts should avoid:

Overflow
Clipped content
Unreadable text
Broken safe-area behavior
Unusable touch targets

Do not treat desktop and tablet design systems as approved Relvio v1 requirements.

Flutter widgets may remain technically adaptable, but implementation must prioritize the approved mobile experience.

Accessibility

Components should support appropriate accessibility for Relvio mobile v1.

Implementation should consider:

Readable text
Sufficient contrast
Meaningful semantics
Screen reader labels where required
Appropriate touch targets
Clear interaction states
Meaning that does not rely only on color

Keyboard navigation is not a universal mobile component requirement.

Where Flutter or a supported device interaction requires focus behavior, implement it appropriately.

Accessibility improvements must preserve approved UI intent.

Document genuine design conflicts instead of silently redesigning the product.

Component States

Components should explicitly handle states required by their responsibility.

Possible states include:

Default
Pressed
Focused
Disabled
Loading
Empty
Error
Selected

Not every component supports every state.

Do not implement meaningless states simply to satisfy a generic component checklist.

Component states must reflect real product behavior.

Async UI States

Components that present asynchronous feature data should support the states required by the feature.

Common presentation states may include:

Initial
Loading
Loaded
Empty
Error

Riverpod is the approved state management solution.

Shared visual components should not own feature data fetching merely because they render async states.

Feature presentation logic coordinates state.

Shared components render the provided visual state.

Component APIs

Component constructors and public APIs should remain focused.

Avoid components with excessive optional parameters such as:

showBorder
showShadow
showIcon
showSubtitle
showBadge
isCompact
isDense
isJourney
isAttendance
isEvent
isPerson

when these options represent unrelated visual or domain responsibilities.

Prefer:

Composition
Focused variants
Feature-owned components
Small shared primitives

A reusable component should be easier to understand than duplicated implementation.

Component Naming

Component names should describe their responsibility clearly.

Shared component names may use the approved project naming convention.

Examples:

AppButton
AppAvatar
AppSearchField
AppErrorState
AppEmptyState

Feature components should use domain-specific names where appropriate.

Examples:

PersonListItem
AttendanceSummaryCard
JourneyHistoryItem
EventDetailsHeader

Do not prefix every widget with App merely because it is a Flutter widget.

Use App for genuinely shared application-level components where the naming remains useful.

Naming must follow:

14_Engineering_Standards.md
Component File Placement

Shared components belong in the approved shared presentation structure.

Feature-specific components belong inside their feature.

Conceptually:

shared/
└── presentation/
    └── widgets/

features/
└── people/
    └── presentation/
        └── widgets/

The exact directory structure must follow the approved project structure documentation.

Do not create duplicate component-library directories outside the approved architecture.

Component Documentation

Shared components should be understandable from:

Clear naming
Focused public APIs
Typed parameters
Appropriate code documentation where needed
Relevant tests for critical behavior

Do not require a large standalone design-system document for every simple widget.

Document complex shared components when their behavior, states, or usage constraints are not obvious from the implementation.

Comments and documentation should explain intent and constraints rather than restating code.

Component Testing

Testing should prioritize critical component behavior.

Examples include:

Primary action loading behavior
Disabled action behavior
Validation presentation
Error recovery actions
Navigation interaction
Permission-sensitive action visibility
Attendance interaction safeguards

Do not chase arbitrary widget test coverage percentages.

Testing strategy is governed by:

15_Testing_Strategy.md

Critical behavior and data integrity matter more than raw coverage numbers.

AI Coding Assistant Rules

AI coding assistants must not:

Recreate the Relvio UI as a generic Material design system.
Build every component listed in the old Atlas draft.
Introduce desktop sidebars.
Introduce breadcrumbs.
Build generic tables without an approved screen requirement.
Build a Kanban board without an approved journey requirement.
Add drag-and-drop journey transitions.
Build a generic chart library.
Build a general calendar system.
Add global keyboard search.
Add desktop drag-and-drop file upload.
Assume every component supports hover.
Require illustrations in every empty state.
Invent component variants.
Invent component colors.
Invent component spacing.
Rename approved UI labels.
Use More instead of Workspace.
Crop components from UI screenshots.
Introduce Lottie or Rive by default.
Create universal components with unrelated feature conditionals.

When implementing a screen, an AI coding assistant must:

Review the approved screen.
Identify existing shared components.
Identify repeated approved patterns.
Reuse appropriate shared components.
Keep domain-specific UI inside the feature.
Add a new shared component only when genuine reuse exists.
Preserve approved visual and interaction intent.
Report missing design information rather than inventing it.
Component Review Checklist

Before adding a shared component, verify:

Does the approved UI require this pattern?
Is the pattern genuinely reused?
Is the component domain-neutral?
Does an existing component already solve the responsibility?
Is the public API focused?
Are design tokens used?
Are feature business rules kept outside the shared widget?
Are required interaction states handled?
Does the implementation preserve the approved UI?
Is this abstraction simpler than duplication?

If the answer to the first question is no, do not create the component.

Source of Truth Priority

For component implementation, use the following authority boundaries:

Approved Relvio UI defines visual and interaction intent.
Approved product documentation defines feature behavior.
Component Library.md defines component reuse and ownership rules.
Color System.md defines color governance.
Approved typography and spacing documentation define visual foundations.
Asset_Structure.md defines production asset organization.
14_Engineering_Standards.md defines implementation standards.
Approved project structure documentation defines code placement.

GoRouter remains the approved routing solution.

Riverpod remains the approved state management solution.

The backend REST API remains authoritative for:

Authentication
Organization membership
Roles
Permissions
Business rules
Validation
Organization isolation
Protected data mutations

A visual component must never become a security or data-integrity boundary.

If a genuine documentation contradiction exists, implementation must stop at the conflicting decision and request clarification.

Success Criteria

The Relvio component library is successful when:

Approved screens are implemented consistently.
Repeated UI patterns are reused appropriately.
Feature-specific widgets remain feature-owned.
Shared components remain domain-neutral and focused.
Flutter widgets use approved design foundations.
The frozen Relvio UI is not redesigned during implementation.
Unapproved desktop and speculative components are not built.
Components handle real product states intentionally.
Critical interaction behavior is testable.
AI coding assistants can identify when to reuse, create, or avoid a shared component.
The component system grows from actual Relvio product needs rather than generic design-system assumptions.