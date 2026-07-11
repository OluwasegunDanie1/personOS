---
Document: Figma Design System
Version: 1.1
Status: Approved
Project: Relvio
Owner: Design Team
---

# Figma Design System

## Purpose

This document defines how approved Relvio product design should be organized and maintained in Figma.

The goal is to provide a clear design source for:

- Approved Relvio mobile screens
- Verified design foundations
- Reusable approved components
- Repeated interaction patterns
- Prototype flows where useful
- Developer implementation reference

Relvio v1 mobile UI is already approved and frozen.

This document must not be used to redesign approved Relvio screens or create speculative product components.

The Figma design system should reflect the approved Relvio product.

It must not define product scope independently.

---

# Product Design Context

Relvio is a:

> **People Operating System**

Relvio helps people-centered organizations understand, organize, and strengthen relationships with the people they serve.

Churches and similar organizations are a strong initial validation market.

The core product remains organization-neutral.

The primary brand message is:

> **Build stronger relationships.**

Relvio v1 supports:

```text
Android
iOS



The approved frontend technology is:

Flutter

The approved primary brand color is:

#2563FF

The approved primary application background is:

#FCFCFD

The approved typeface is:

Inter

The approved v1 mobile UI is the visual product authority.

Figma Responsibility

Figma is responsible for representing approved visual and interaction intent.

Figma may define:

Screen layouts
Visual hierarchy
Typography usage
Color usage
Spacing
Component appearance
Component states
Interaction patterns
Prototype transitions
Relevant design annotations

Figma does not define:

Backend architecture
API endpoints
Database tables
Authentication rules
Authorization rules
Organization isolation
Attendance integrity
Journey history behavior
Business rules not approved by Product

Visual design must remain compatible with approved product and architecture documentation.

Approved UI Freeze

The approved Relvio v1 mobile UI is frozen before implementation.

The frozen UI must not be changed because:

A designer prefers another pattern
Flutter provides a different default
Material components look different
A generic design system recommends another layout
An AI coding assistant suggests an improvement
A competitor uses another pattern

Changes to frozen UI require an intentional design decision.

If implementation reveals a genuine design problem:

Identify the affected screen.
Identify the affected component or interaction.
Document the issue.
Return the issue for design review.
Approve the correction.
Update the relevant Figma design.
Update affected documentation where necessary.
Implement the approved correction.

Do not silently redesign during Flutter implementation.

Figma File Organization

The Relvio Figma file may use the following conceptual organization:

Relvio

├── Cover
├── Foundations
├── Components
├── Patterns
├── Screens
├── Prototype
└── Archive

A separate Tokens page may be used where it improves clarity.

A separate Templates page may be used when approved repeated screen templates genuinely exist.

Do not create empty pages solely to match this structure.

Figma organization should remain useful and simple.

Cover

The Cover page may contain:

Relvio logo
File purpose
Design version
Last meaningful update
Design ownership
Relevant documentation references

Use approved Relvio logo assets.

Do not recreate the Relvio logo in Figma from screenshots.

Logo usage is governed by:

19_Brand_Identity.md
20_Logo_Strategy.md
Brand Assets.md
Foundations

The Foundations area should contain verified Relvio visual foundations.

Relevant foundation categories may include:

Colors
Typography
Spacing
Radius
Borders
Shadows
Icons
Motion

Only create foundation sections required by approved Relvio design.

Do not automatically create:

Desktop Grid
Tablet Grid
Large Desktop Grid
Generic Illustration System
Generic Elevation Scale

unless approved product design requires them.

Design token governance is defined by:

Design Tokens.md

Color governance is defined by:

Color System.md
Color Variables and Styles

Figma should use centralized approved color variables or styles where appropriate.

Known approved Relvio values include:

Primary Brand Color: #2563FF
Primary Application Background: #FCFCFD

Additional color values must come from:

Approved Relvio UI
Color System.md
Approved brand documentation

Do not create a generic color system containing:

Primary 50–900
Secondary 50–900
Emerald 50–900
Amber 50–900
Gray 50–900

unless those exact scales are explicitly approved for Relvio.

Do not use the old Atlas color system as Relvio's Figma palette.

Prefer semantic color responsibilities where useful.

Possible examples include:

Brand / Primary
Background / Primary
Surface / Primary
Text / Primary
Text / Secondary
Border / Default
Action / Primary
State / Error

These examples do not approve missing color values.

Do not assign guessed colors to complete a variable collection.

Raw Color Values

Approved screens should use centralized Figma color variables or styles for repeated approved color responsibilities where practical.

Avoid scattering repeated raw HEX values across components.

However, do not replace an approved visual value merely because it does not fit an existing color variable.

If a repeated approved color value is missing:

Verify the value.
Determine its responsibility.
Add the appropriate variable or style.
Update affected approved components.

Do not normalize approved colors into visually similar existing tokens.

Typography

The approved Relvio typeface is:

Inter

Figma typography styles should reflect typography patterns that actually exist in the approved Relvio UI.

Possible semantic responsibilities may include:

Heading
Title
Body
Body Secondary
Label
Caption

The final typography structure must come from verified Relvio designs.

Do not automatically create the Atlas typography catalogue:

Display Large
Display Medium
Heading 1
Heading 2
Heading 3
Title
Body Large
Body Medium
Body Small
Caption
Label

unless those styles genuinely exist in approved Relvio UI.

Typography values should preserve approved:

Font family
Font size
Font weight
Line height
Letter spacing

where applicable.

Typography token implementation is governed by:

Design Tokens.md
Spacing

Repeated spacing values should be represented consistently in approved Figma components and screens.

Do not force all Relvio layouts onto a generic spacing scale.

The old Atlas spacing scale is not automatically approved.

If approved screens contain a verified repeated spacing value, it may become part of the Relvio design token system.

If an intentional screen-specific value exists, do not change it merely to fit a cleaner scale.

Spacing extraction and Flutter centralization are governed by:

Design Tokens.md
Radius

Repeated approved corner-radius treatments should be documented and reused.

Do not automatically create:

4
8
12
16
24
999

as the Relvio radius system.

Radius values must come from approved Relvio components and screens.

Where multiple components share the same approved treatment, reuse the same design variable or documented value where appropriate.

Borders and Shadows

Borders and shadows must reflect approved Relvio UI.

Do not create generic effects such as:

Shadow Small
Shadow Medium
Shadow Large
Blur
Overlay

unless those effects are genuinely used by approved Relvio designs.

For repeated approved shadow treatments, preserve relevant values such as:

Color
Opacity
Blur
Spread
Offset

where applicable.

Do not replace approved borders with shadows.

Do not add elevation because a surface is called a card.

The approved UI determines the visual treatment.

Mobile Layout

Relvio v1 is mobile-first for:

Android
iOS

Figma layouts should reflect supported mobile experiences.

Design should account for:

Mobile screen width
Mobile screen height
Safe areas
Touch interaction
System insets
Mobile keyboards
Scrollable content
Text scaling considerations
Supported mobile navigation

Do not create desktop or web layouts as v1 requirements.

Grid Systems

Relvio v1 does not require the old Atlas grid system:

Desktop = 12 Columns
Tablet = 8 Columns
Mobile = 4 Columns

Do not force approved Relvio mobile screens into a four-column grid.

If a layout grid is useful for a specific approved mobile design, configure the grid based on the actual screen and layout requirements.

A Figma layout grid is a design aid.

It is not automatically a Flutter architecture rule.

Responsive and Adaptive Design

Approved Relvio mobile screens should support implementation across relevant Android and iOS screen sizes.

Figma may include representative mobile frames where necessary to verify adaptation.

Do not automatically create:

Tablet variants
Desktop variants
Web variants
Large desktop variants

unless those product platforms are approved.

If an approved screen requires meaningful adaptation across mobile widths, document the intended behavior.

Do not assume one reference frame should be reproduced with absolute pixel positioning on every device.

Components

Figma components should represent reusable approved Relvio UI patterns.

A component should be created when reuse improves:

Visual consistency
Design maintenance
State consistency
Developer handoff

Not every visual element must become a global component.

Do not create components solely because a generic design system normally contains them.

The component library must grow from approved Relvio screens.

Component governance is defined by:

Component Library.md
Component Extraction

The preferred component process is:

Approved Screens
        ↓
Identify Repeated UI Pattern
        ↓
Verify Shared Responsibility
        ↓
Create or Refine Figma Component
        ↓
Replace Repeated Pattern with Component Instance
        ↓
Document Relevant States
        ↓
Mirror Approved Pattern in Flutter

Do not begin by creating a large generic component catalogue and forcing approved screens to use it.

Component Organization

The Figma component area may be grouped by actual approved component responsibilities.

Possible categories include:

Actions
Inputs
Navigation
People
Events
Attendance
Journey
Feedback
Layout

The final categories should reflect actual Relvio component usage.

Do not automatically create categories for:

Tables
Charts
Desktop Menus
Breadcrumbs
Pagination
Kanban

unless approved Relvio features require them.

Feature-specific components may remain grouped with their domain.

Not every component belongs in a global UI library.

Shared and Feature Components

Figma should distinguish conceptually between:

Shared Components
Feature Components

Shared components are reused across multiple Relvio features.

Examples may include approved patterns such as:

Common buttons
Common input treatments
Shared navigation
Shared feedback patterns

Feature components belong primarily to a product domain.

Examples may include approved:

People patterns
Attendance patterns
Journey patterns
Event patterns

Do not generalize a feature component into a global component merely because it appears more than once inside the same feature.

Flutter component boundaries should follow the same responsibility principle.

Component Naming

Component names should clearly describe responsibility.

Possible naming patterns include:

Button / Primary
Input / Search
Navigation / Bottom
Person / Avatar
Attendance / Status
Journey / Stage

Names should remain understandable outside the frame where the component was created.

Avoid names such as:

Component 1
Blue Button
Card New
Copy 4
Final Final

Do not rename approved product concepts casually.

The approved final primary navigation label is:

Workspace

Do not use:

More

for the final primary navigation destination.

Component Variants

Figma variants should represent real approved component differences.

Possible variant responsibilities may include:

State
Size
Selection
Icon Presence
Loading

Only create properties required by actual component behavior.

Do not require every component to support:

Default
Hover
Pressed
Focus
Disabled
Loading
Error
Selected

Component states depend on component responsibility.

Relvio v1 mobile components do not require universal hover states.

Do not create unused variants for hypothetical future needs.

Buttons

Button components should reflect approved Relvio button patterns.

Possible approved button responsibilities may include:

Primary action
Secondary action
Text action
Icon action
Destructive action

The actual button set must come from approved Relvio UI.

Do not automatically create:

Primary
Secondary
Outlined
Text
Danger
Icon
Floating Action Button

as mandatory component variants.

A Floating Action Button is not required merely because Relvio uses Flutter or Material.

Button states should match actual approved interaction behavior.

Relevant states may include:

Default
Pressed
Disabled
Loading

where required.

Inputs

Input components should reflect approved Relvio forms and interactions.

Possible input responsibilities may include:

Text input
Password input
Search
Selection
Date input
Multiline input

The approved UI determines which input patterns exist.

Do not automatically create:

Dropdown
Date Picker
Checkbox
Radio
Switch

unless those controls are required by approved screens.

Input states may include:

Default
Focused
Error
Disabled

where relevant.

Validation presentation must match approved product behavior.

Navigation

The approved Relvio v1 navigation is mobile navigation.

Figma navigation components should represent the approved Relvio mobile flows.

The final bottom navigation label is:

Workspace

not:

More

Do not create v1 navigation components for:

Desktop sidebar
Desktop top navigation
Breadcrumbs
Pagination

unless future product scope explicitly approves those experiences.

Navigation design must match the approved frozen UI.

Routing implementation is governed by approved GoRouter architecture.

Figma does not define route architecture.

Cards and Content Surfaces

Approved repeated content surfaces may become Figma components.

Possible feature responsibilities may include:

Person information
Event information
Attendance information
Journey information
Follow-up information

Do not create generic:

Statistic Card
Profile Card
Event Card
Attendance Card
Follow-up Card
Report Card

as mandatory design-system components.

A visual surface should become a reusable component when the approved UI demonstrates a repeated responsibility.

Do not add hover states to mobile cards by default.

Feedback Components

Figma should document approved repeated feedback patterns where they exist.

Relevant patterns may include:

Loading
Skeleton
Shimmer
Empty state
Error state
Snackbar or transient feedback
Validation feedback

Not every screen requires every feedback pattern.

Animations, shimmer, skeletons, loading states, empty states, error states, and micro-interactions may be implemented during Flutter coding where appropriate.

Figma may define or refine repeated visual patterns for these states.

Do not add product capability while designing a feedback state.

Loading States

Loading designs should communicate that content or an operation is in progress.

Possible patterns may include:

Progress indicator
Skeleton
Shimmer
Button loading state

The appropriate pattern depends on the interaction.

Do not create a skeleton version of every screen automatically.

Do not use loading animation to imply success.

Attendance and Journey authoritative state must remain truthful.

Empty States

Empty states should explain the absence of content where needed.

An empty state may contain:

Message
Supporting context
Relevant approved action

An illustration is not mandatory.

Do not invent illustration assets.

Missing approved assets must be reported according to:

Asset_Structure.md
Brand Assets.md
Error States

Error states should help users understand that an operation or content load did not complete successfully.

Where appropriate, an error state may provide:

Clear explanation
Retry action
Safe navigation action

Do not display raw:

Exceptions
Stack traces
Database errors
HTTP error payloads

Error copy should remain:

Clear
Calm
Accurate
Actionable where possible

Error behavior must remain compatible with approved security requirements.

Dialogs and Bottom Sheets

Dialogs and bottom sheets should be designed only where approved Relvio interactions require them.

Possible responsibilities may include:

Confirmation
Destructive action confirmation
Contextual actions
Filters
Short mobile workflows

Do not create a generic catalogue of:

Confirmation
Delete
Information
Warning
Success

dialogs unless distinct approved visual patterns exist.

A dialog type should not exist merely because its message has a different semantic meaning.

Reuse visual structure where responsibility is shared.

Tables

Desktop-style data tables are not an approved Relvio v1 mobile design-system requirement.

Do not create a generic Figma table system with:

Sorting
Filtering
Pagination
Bulk actions

unless an approved future feature requires it.

Mobile list and content patterns should follow approved Relvio UI.

Do not import desktop SaaS patterns into Relvio mobile v1.

Charts

Do not prepare generic chart templates merely because Relvio contains data.

Charts must come from approved product requirements and defined metrics.

Do not automatically create:

Bar Chart
Pie Chart
Area Chart
Line Chart
KPI Card

as design-system components.

Before designing a chart, the product requirement should define:

Metric
Data source
Calculation
Organization scope
Time range
Interpretation

Chart design should then reflect the approved product requirement.

Patterns

The Patterns area may document repeated combinations of approved components and interaction behavior.

A pattern may be appropriate for repeated responsibilities such as:

Form structure
Search result presentation
Empty-state treatment
Loading presentation
Destructive confirmation
Feature list presentation

Patterns should emerge from approved Relvio experiences.

Do not create generic SaaS patterns for hypothetical features.

A pattern is not a new product capability.

Templates

A template should exist only when multiple approved screens share a meaningful structural responsibility.

Possible examples may include:

Approved authentication structure
Approved standard mobile content structure

Do not automatically create:

Desktop Dashboard
Tablet Dashboard
Mobile Dashboard
Form Layout
Settings Layout
Profile Layout
Authentication Layout

as a mandatory template catalogue.

If only one approved screen uses a structure, it may remain a screen rather than becoming a template.

Screen Library

The Screens area should contain the approved Relvio v1 mobile screens.

Screens should be organized according to the approved product and design flow.

Screen organization may reflect approved areas such as:

Authentication
Onboarding
Home
People
Person details
Journey
Events
Attendance
Follow-ups
Workspace

The actual screen library must match the approved Relvio UI.

Do not add screens because they appear in the Feature Backlog.

Do not add speculative screens for:

Enterprise
AI
Marketplace
Developer platform
Billing
White-labeling
Advanced integrations
Desktop administration

unless those capabilities become approved product scope.

Screen Naming

Screen frames should use clear names.

Prefer names that describe:

Feature / Screen

Examples:

People / List
People / Details
Events / Details
Attendance / Record
Workspace / Main

The exact names should match approved product terminology.

Avoid:

Screen 1
Screen Copy
New Screen
Final Screen
Final Screen 2

Screen naming should help Design and Engineering refer to the same product surface.

Approved Screen Versions

When an approved screen changes intentionally, preserve clarity about which design is current.

The current approved version should be clearly identifiable.

Old designs should be moved to Archive where historical reference remains useful.

Do not leave multiple competing screen versions in the active Screens area without identifying the approved version.

Do not ask developers or AI coding assistants to infer which visual is final.

Archive

The Archive area may contain:

Superseded screens
Rejected design directions
Old component versions
Historical explorations

Archived design must be clearly separated from approved active design.

Do not use archived designs for implementation.

Do not copy components from Archive into production screens without design review.

Where an archived design represents a significant rejected product direction, the relevant decision may also belong in:

18_Decision_Log.md
Auto Layout

Figma Auto Layout should be used where it improves:

Component resizing
Content adaptation
Spacing consistency
Component maintenance
Developer understanding

Repeated component structures should generally use Auto Layout where appropriate.

Do not use Auto Layout as an absolute rule for every Figma layer.

Some approved visual structures may require other positioning behavior.

Avoid unnecessary manual positioning when Auto Layout clearly represents the intended layout.

Use the Figma layout mechanism that most accurately communicates approved design behavior.

Constraints and Resizing

Figma components and frames should define resizing behavior where that behavior matters to implementation.

Relevant behavior may include:

Fill available width
Hug content
Fixed approved dimension
Scrollable content area
Pinned mobile navigation
Safe-area relationship

Do not configure desktop, tablet, and mobile constraints for every component.

Relvio v1 requires supported mobile behavior.

Document meaningful adaptation rather than creating speculative cross-platform variants.

Absolute Positioning

Avoid using arbitrary absolute positioning for normal mobile content layout where responsive structure is intended.

Absolute positioning may be appropriate for approved visual elements that genuinely overlap or occupy fixed visual relationships.

Flutter implementation must not copy Figma X and Y coordinates directly as application layout architecture.

Figma measurements communicate design relationships.

Flutter should reproduce those relationships using appropriate widgets and layout constraints.

Component Properties

Use Figma component properties when they reduce unnecessary component duplication.

Properties may represent actual approved differences such as:

State
Size
Icon visibility
Selection
Loading

Do not add every possible property to every component.

A component with excessive speculative properties becomes harder to understand and maintain.

Component properties should represent real approved use cases.

Prototyping

Figma prototypes may be used to communicate approved user flows and important interaction intent.

Prototype only flows where interaction reference is useful.

Possible approved flows may include:

Authentication
Organization onboarding
Adding a person
Viewing person information
Event interaction
Attendance interaction
Journey interaction
Follow-up interaction
Workspace navigation

The actual prototype must match approved Relvio product behavior.

Do not prototype backlog features as if they are approved.

A Figma prototype is not an API or backend specification.

If prototype behavior conflicts with approved product or architecture documentation, the contradiction must be resolved before implementation.

Prototype Limitations

Prototype transitions may simulate behavior that requires backend authority in production.

For example, a prototype may visually move from:

Submit Attendance
        ↓
Attendance Recorded

The production implementation must still use the backend REST API and required integrity controls.

A Figma transition does not authorize:

Client-only business logic
Client-side authorization
Client-generated authoritative journey history
Direct PostgreSQL access
Bypassing backend validation

The approved architecture remains:

Flutter
    ↓
Backend REST API
    ↓
PostgreSQL

The API base remains:

/api/v1
Developer Handoff

Approved Figma design should provide enough information for accurate Flutter implementation.

Useful handoff information includes:

Approved screen
Component responsibility
Layout relationships
Exact verified colors
Typography
Spacing
Radius
Border treatment
Shadow treatment
Icon usage
Relevant component states
Relevant interaction behavior

Do not intentionally leave known design decisions ambiguous.

However, do not invent exact values merely to make handoff appear complete.

If a value cannot be verified, mark or report it as unresolved.

The implementation process for unresolved values is governed by:

Design Tokens.md
Flutter Handoff Principle

Flutter must implement approved UI as widgets.

Do not:

Export full UI screens as images
Crop buttons from screenshots
Crop cards from screenshots
Crop text from screenshots
Crop icons from screenshots
Rebuild the Relvio logo from a screenshot

UI screenshots are design references.

They are not production UI assets.

Asset implementation rules are governed by:

Asset_Structure.md

Approved brand assets must be used directly.

Figma and Flutter Components

A Figma component does not automatically require a one-to-one Flutter widget.

Likewise, a Flutter widget does not require a matching standalone Figma component.

Component boundaries should reflect responsibility.

For example:

Figma visual reuse

and:

Flutter code reuse

are related but not identical concerns.

Flutter component architecture is governed by:

Component Library.md
14_Engineering_Standards.md
Approved project structure documentation

Do not create unnecessary Flutter widgets solely to mirror every Figma component layer.

Figma Variables and Flutter Tokens

Figma variables or styles and Flutter design tokens should represent the same approved design responsibilities where practical.

Conceptually:

Approved Figma Value
        ↓
Verified Design Responsibility
        ↓
Flutter Token

Names do not need to be character-for-character identical when Figma and Dart naming conventions differ.

The responsibility and approved value should remain aligned.

Do not automatically generate Flutter tokens from every Figma variable.

Do not automatically create Figma variables from every Flutter constant.

Design token governance is defined by:

Design Tokens.md
Icons

Figma must use the approved Relvio icon approach.

Do not mix icon styles casually.

Icons should preserve approved visual consistency.

If the approved UI uses an icon available from the approved icon source, use the correct icon.

Do not recreate icons from screenshots when an approved source exists.

Do not export standard UI icons as raster images merely to match screenshots.

Flutter should implement approved icons using the approved icon source or approved vector asset strategy.

Missing approved icon decisions must be reported.

Illustrations

Illustrations are not a mandatory part of every Relvio state.

Only use approved illustration assets.

Do not create generic flat illustrations merely because the old Atlas design system specified an illustration style.

Do not invent onboarding graphics, empty-state graphics, or error illustrations.

Missing approved illustration assets must be reported.

Asset governance is defined by:

Brand Assets.md
Asset_Structure.md
Motion Documentation

Where an approved interaction requires motion, Figma may communicate:

Transition intent
State relationship
Motion direction
Relevant timing where verified

Figma prototype animation should not automatically become the exact Flutter animation specification.

Flutter motion must preserve the approved interaction intent.

Repeated motion values may become design tokens according to:

Design Tokens.md

Simple animations should be implemented directly in Flutter where appropriate.

Do not introduce Lottie or Rive by default.

Accessibility

Figma design should consider:

Readable typography
Sufficient contrast
Meaning beyond color
Appropriate mobile touch interaction
Clear state presentation

Figma alone cannot prove complete application accessibility.

Flutter implementation and testing remain necessary.

If a frozen approved design creates a genuine accessibility concern:

Identify the affected screen or component.
Document the concern.
Review the design intentionally.
Approve any correction.
Update Figma.
Update implementation.

Do not silently redesign approved UI.

Accessibility principles are governed by:

Design Principles.md
Color System.md
Component Library.md
Design Documentation

Important shared components should document behavior where visual appearance alone is insufficient.

Useful component documentation may include:

Purpose
Usage
Relevant variants
Relevant states
Important constraints
Accessibility notes
Misuse guidance

Not every simple visual component requires a full documentation page.

Documentation depth should match component complexity and implementation risk.

Do not create design-system bureaucracy that slows Relvio v1 without improving clarity.

Versioning

Meaningful Figma design changes should remain traceable.

Relevant changes may include:

Approved screen change
Shared component change
Design token change
Navigation change
Important interaction change

A lightweight design changelog may record:

Date
Area
Change
Reason
Owner

Do not create a new design-system version for every small layer rename or organizational cleanup.

Meaningful product and design decisions should remain understandable.

Significant approved decisions may also require an update to:

18_Decision_Log.md
Design Change Control

Before changing an approved shared component:

Identify all active screen usage.
Confirm the design change is approved.
Review affected component variants.
Update the shared component.
Review affected screens.
Confirm Flutter implementation impact.
Update relevant design documentation where required.

Do not change a shared component to solve one screen-specific problem if the shared component is correct elsewhere.

The screen may require a feature-specific treatment.

Duplicate Component Control

Before creating a new Figma component:

Search existing shared components.
Search relevant feature components.
Compare responsibility, not only appearance.
Reuse an existing component when responsibility matches.
Extend an existing component only when the new variant is genuinely part of the same component.
Create a new component when responsibility differs.

Do not merge unrelated components merely because they look similar.

Do not duplicate the same component under different names.

Quality Review

Before treating a Figma design update as implementation-ready, review the items relevant to the change:

Is the screen or component approved?
Does it use approved Relvio terminology?
Does it preserve Workspace as the final navigation label?
Does it preserve organization-neutral core language?
Are approved brand values used?
Is Inter used correctly?
Are repeated approved design values consistent?
Are shared components reused appropriately?
Are speculative components avoided?
Are important states represented where required?
Is mobile behavior understandable?
Are unresolved design values identified?
Are approved assets used directly?
Are archived designs clearly separated?
Does the design avoid introducing an unapproved feature?
Is the design compatible with approved product behavior?

Not every simple design change requires the same review depth.

Review effort should match design impact.

AI Coding Assistant Rules

AI coding assistants must treat approved active Figma screens as implementation references.

AI coding assistants must not:

Redesign approved Relvio screens.
Use archived Figma designs for implementation.
Choose between competing screen versions without an approved current version.
Create desktop layouts.
Create tablet product layouts.
Create web layouts.
Add sidebars.
Add breadcrumbs.
Add desktop pagination.
Add generic tables.
Add generic chart systems.
Add hover states as universal mobile requirements.
Build every generic design-system component.
Reuse the old Atlas design system.
Generate missing design values and present them as approved.
Normalize approved UI into a generic spacing or typography scale.
Replace approved colors with generated Material colors.
Use ColorScheme.fromSeed as the source of Relvio visual identity.
Replace Workspace with More.
Introduce church-only terminology into core Relvio UI.
Export Figma screens as production UI images.
Crop UI elements from screenshots.
Recreate the approved Relvio logo.
Add unapproved illustrations.
Add Lottie or Rive by default.
Implement backlog screens because they exist as product ideas.

When Figma does not clearly define a required implementation detail, the AI coding assistant must:

Check approved documentation.
Check approved active design patterns.
Apply Design Principles.md.
Apply Design Tokens.md.
Preserve the approved screen's intent.
Avoid introducing new product capability.
Report genuine unresolved design decisions.

The AI coding assistant is an implementation engineer.

It is not the product designer of record.

Source of Truth Priority

For Figma and visual implementation decisions:

Approved Relvio product decisions define product scope.
Approved active Relvio Figma screens define frozen v1 visual and interaction intent.
Design Principles.md defines product design judgment.
19_Brand_Identity.md defines Relvio brand character.
Color System.md defines color governance.
Design Tokens.md defines design-value centralization.
Component Library.md defines component responsibility and reuse.
Brand Assets.md defines approved brand asset governance.
Asset_Structure.md defines Flutter production asset organization.
Approved architecture and engineering documentation define implementation boundaries.

Figma must not override backend security or data integrity rules.

The backend REST API remains authoritative for:

Authentication
Organization membership
Roles
Permissions
Business rules
Validation
Organization isolation
Protected data mutations

Attendance requires backend integrity controls and idempotency.

Journey transitions preserve immutable journey history.

If a genuine contradiction exists between Figma and approved product or architecture documentation, implementation must stop at the affected behavior and request clarification.

Success Criteria

The Relvio Figma Design System is successful when:

Approved v1 mobile screens are clearly identifiable.
Android and iOS remain the supported v1 design targets.
Frozen Relvio UI is protected from accidental redesign.
Figma reflects approved Relvio product scope.
Shared components emerge from real approved UI patterns.
Feature-specific components remain appropriately scoped.
Verified design values align with Flutter design tokens.
#2563FF remains the approved primary brand color.
#FCFCFD remains the approved primary application background.
Inter remains the approved typeface.
Workspace remains the approved final primary navigation label.
Archived designs cannot be confused with active implementation references.
Developers and AI coding assistants can identify approved design intent.
Unresolved values are reported rather than invented.
Figma does not create desktop, web, enterprise, AI, or backlog scope.
Flutter implements the approved UI as widgets rather than screenshot assets.
Design consistency improves without forcing Relvio into a generic design system.
Final Principle

The Relvio Figma Design System exists to preserve and communicate the approved product design.

It must grow from Relvio.

Relvio must not be reshaped to fit a generic design system