---

Document: Color System
Version: 1.1
Status: Approved
Project: Relvio
Owner: Design & Engineering
---------------------------

# Color System

## Purpose

This document defines the approved color system and color implementation rules for Relvio.

The color system provides a controlled visual language for:

* The Relvio mobile product
* Shared Flutter components
* Product states
* Brand-aligned digital surfaces

The approved Relvio UI is already complete and frozen.

This document does not redesign the approved UI.

It exists to prevent developers and AI coding assistants from inventing colors, replacing approved colors, or introducing unrelated color systems during implementation.

Brand identity decisions are governed by:

* `19_Brand_Identity.md`

Brand asset rules are governed by:

* `Brand Assets.md`

Flutter implementation must follow:

* The approved Relvio UI
* The approved design token structure
* This document

---

# Core Color Principle

Relvio should feel:

* Calm
* Clear
* Modern
* Focused
* Trustworthy
* Human

Color should support hierarchy and meaning.

Color must not create unnecessary visual noise.

The approved UI is the visual source of truth for where colors appear.

Developers and AI coding assistants must not reinterpret the Relvio interface by applying colors based on personal preference or generic design-system conventions.

---

# Primary Brand Color

The approved Relvio primary brand color is:

```text
#2563FF
```

Name:

```text
Relvio Blue
```

Relvio Blue is the primary brand and interaction color.

It may be used where defined by the approved UI for elements such as:

* Primary actions
* Active navigation states
* Selected states
* Interactive emphasis
* Brand highlights
* Approved links
* Approved focus or active indicators

The exact use of Relvio Blue must follow the approved UI.

Do not replace Relvio Blue with:

```text
#2563EB
```

or another visually similar blue.

The approved value is:

```text
#2563FF
```

---

# Primary Application Background

The approved primary Relvio application background is:

```text
#FCFCFD
```

This is the default primary background for the approved Relvio mobile interface where shown in the approved UI.

Do not globally replace it with:

```text
#FFFFFF
```

White may still be used for surfaces or components where required by the approved UI.

The primary application background remains:

```text
#FCFCFD
```

---

# Color Source of Truth

The approved Relvio UI is the visual source of truth for product color usage.

The implementation color system must translate approved UI colors into centralized Flutter design tokens.

Do not create a generic palette first and then recolor the approved UI to fit that palette.

The correct implementation direction is:

```text
Approved Relvio UI
        ↓
Verified Color Values
        ↓
Centralized Design Tokens
        ↓
Flutter Components
        ↓
Feature UI
```

If an exact color value cannot be verified from approved design documentation or approved design source files, the implementation assistant must report the unresolved color.

Do not guess a visually similar hex value.

---

# Color Token Categories

The Flutter design system should organize approved colors by purpose.

Recommended token categories include:

```text
Brand
Background
Surface
Text
Border
Icon
Action
State
Overlay
```

These categories define token responsibilities.

They do not authorize the invention of new colors.

Only verified approved color values should be assigned to production tokens.

---

# Brand Tokens

The required primary brand token is:

```text
brandPrimary = #2563FF
```

The approved primary application background token is:

```text
backgroundPrimary = #FCFCFD
```

Additional brand tokens may only be added when an approved Relvio brand or UI requirement provides the required value.

Do not automatically create:

```text
brandSecondary
brandAccent
brandEmerald
brandAmber
```

unless those colors are formally approved.

Relvio does not currently define Emerald or Amber as official secondary brand colors.

---

# Primary Color Shades

Do not automatically generate a `50` to `900` color scale for Relvio Blue.

A generated Tailwind-style color scale is not part of the approved Relvio color system.

If the approved UI requires:

* A lighter blue background
* A pressed blue state
* A disabled blue state
* A blue border
* A blue tint
* A hover or focus variation on a supported platform

the exact approved color value should be represented as a semantic design token.

Example token intent:

```text
actionPrimary
actionPrimaryPressed
selectionBackground
brandTint
```

The final token names must follow the approved Flutter design token conventions.

Do not derive arbitrary shades mathematically during feature implementation.

---

# Background Colors

The approved primary application background is:

```text
#FCFCFD
```

Additional background colors must come from the approved Relvio UI.

Possible semantic responsibilities include:

```text
backgroundPrimary
backgroundSecondary
```

A background token should only be created when a distinct approved background value exists.

Do not assume:

```text
#FFFFFF
#F9FAFB
```

as global background colors merely because they are common in generic design systems.

---

# Surface Colors

Surface colors are used for approved UI elements such as:

* Cards
* Sheets
* Dialog surfaces
* Input surfaces
* Navigation surfaces
* Approved containers

Surface values must match the approved Relvio UI.

White may be used where the approved UI uses white.

Do not globally force all cards and surfaces to:

```text
#FFFFFF
```

unless that matches the approved component specification.

Use semantic surface tokens rather than raw color values inside feature widgets.

---

# Text Colors

Text colors must follow the approved Relvio UI and typography hierarchy.

Semantic text token responsibilities may include:

```text
textPrimary
textSecondary
textMuted
textDisabled
textInverse
textAction
```

The exact color values must be verified from the approved design source.

Do not automatically adopt a generic gray scale.

Feature code must not invent text colors.

Typography hierarchy and color hierarchy must work together.

---

# Border and Divider Colors

Border and divider colors must follow the approved Relvio UI.

Semantic responsibilities may include:

```text
borderDefault
borderSubtle
borderFocused
divider
```

Only create separate tokens when the approved UI contains visually or semantically distinct values.

Do not introduce arbitrary:

```text
Light
Default
Strong
```

border scales without an approved design requirement.

---

# Icon Colors

Icon colors must follow the visual hierarchy of the approved Relvio UI.

Semantic icon token responsibilities may include:

```text
iconPrimary
iconSecondary
iconMuted
iconAction
iconInverse
```

Icons must not use arbitrary colors directly inside feature widgets.

Decorative icon recoloring must not be introduced during implementation.

---

# Action Colors

Primary action color is based on approved Relvio Blue:

```text
#2563FF
```

Primary buttons and other primary actions must match the approved UI.

Secondary, destructive, disabled, pressed, and other action states must use approved design values.

Do not derive action-state colors by guessing.

Do not introduce gradients to primary actions unless an approved Relvio UI explicitly contains a gradient.

---

# Semantic State Colors

Relvio may require semantic colors for states such as:

* Success
* Warning
* Error
* Information

These are semantic interface colors.

They are not secondary Relvio brand colors.

Semantic color values must be verified against the approved UI or approved component specification before implementation.

Do not automatically assign:

```text
Success = #10B981
Warning = #F59E0B
Error = #EF4444
Information = #3B82F6
```

unless those exact values are confirmed by the approved design source.

Semantic colors should be centralized as design tokens.

Example responsibilities:

```text
stateSuccess
stateWarning
stateError
stateInfo
```

Where required, semantic state systems may also include approved:

```text
Background
Border
Text
Icon
```

variations.

Do not generate these variations automatically.

---

# Domain Status Colors

Business and domain statuses must not receive global colors based only on their names.

Examples include:

* Draft
* Pending
* Active
* Completed
* Archived
* Present
* Absent
* Follow-up states
* Journey stages

The domain meaning and approved UI determine the visual treatment.

Do not assume:

```text
Pending = Amber
Active = Blue
Completed = Green
Archived = Gray
```

for every Relvio feature.

A status color must be defined within the approved design system or relevant component specification before use.

This prevents unrelated domain states from being forced into a generic global status palette.

---

# Attendance Color Rules

Attendance is a data-integrity-sensitive Relvio feature.

Attendance state colors are presentation concerns only.

Color must not determine attendance state.

Attendance state must come from validated backend data.

The UI may visually represent attendance states using approved colors, labels, and icons.

Do not infer:

```text
Present
Absent
Late
```

from color values.

The data state determines the visual state.

The visual state never determines the data state.

---

# Journey Color Rules

Journey stages and journey transitions must not be represented as mutable state based on UI color.

Journey history is preserved as immutable transition history according to the approved architecture and data rules.

Colors may visually distinguish approved journey states or stages.

Color has no authority over journey data or transition history.

The backend remains authoritative for journey state and transition integrity.

---

# Color and Meaning

Color must not be the only method used to communicate critical meaning.

Where appropriate, combine color with:

* Text
* Labels
* Icons
* Status indicators
* Component state
* Accessible semantics

This is especially important for:

* Errors
* Warnings
* Attendance states
* Permission-related feedback
* Destructive actions
* Journey states

Users should be able to understand critical state without relying only on color recognition.

---

# Accessibility

Color implementation should preserve sufficient visual contrast for supported mobile experiences.

Text, controls, and meaningful interface states should remain readable and distinguishable.

Accessibility validation should be performed against the implemented Flutter UI.

Where the approved UI creates a verified accessibility issue, the issue must be documented and returned to Design for resolution.

An AI coding assistant must not independently redesign the color system under the assumption that it is improving accessibility.

Accessibility issues should be fixed intentionally without creating undocumented visual divergence.

---

# Gradients

Do not introduce gradients into the Relvio product UI unless a gradient exists in the approved UI.

AI coding assistants must not add gradients to:

* Buttons
* Cards
* Navigation
* Backgrounds
* Empty states
* Splash screens
* Brand surfaces

for decorative improvement.

The approved UI must be implemented as designed.

---

# Opacity

Opacity values should be centralized or derived from approved component requirements where practical.

Do not scatter arbitrary opacity values throughout feature widgets.

Examples of values that require design intent include:

```text
0.05
0.08
0.10
0.12
0.50
0.60
```

The existence of common opacity values in other design systems does not make them approved Relvio values.

Use approved component and design token values.

---

# Overlays

Overlay colors may be required for:

* Dialog barriers
* Bottom sheets
* Modal states
* Image overlays

Overlay values must follow the approved UI or shared component implementation.

Do not create feature-specific overlay colors without a documented visual requirement.

---

# Disabled States

Disabled colors must communicate reduced availability while preserving readability.

Disabled state values must match approved component behavior.

Do not implement disabled states by applying arbitrary opacity to an entire widget unless the approved component implementation requires that behavior.

Disabled visual state does not replace permission or business-rule enforcement.

The backend remains authoritative for protected operations.

---

# Loading States

Loading states may use:

* Skeletons
* Shimmer
* Progress indicators
* Inline loading states

where appropriate during Flutter implementation.

Loading-state colors must use centralized approved design tokens.

Do not introduce unrelated shimmer palettes or decorative loading colors.

Loading behavior must remain visually consistent with the approved Relvio UI.

---

# Empty and Error States

Empty and error states must use approved color tokens and approved UI intent.

Do not automatically use large green, amber, or red surfaces because a state is categorized as success, warning, or error.

The approved component design determines:

* Color intensity
* Icon treatment
* Text hierarchy
* Background treatment
* Action treatment

Missing approved visual assets must be reported according to `Brand Assets.md` and `Asset_Structure.md`.

---

# Light Theme

Relvio v1 implementation follows the approved light mobile UI.

The primary application background is:

```text
#FCFCFD
```

The light theme should be implemented from approved Relvio design tokens.

Do not substitute a generic Flutter or Material light theme as the final product appearance.

---

# Dark Mode

Dark mode is not defined by this document as a Relvio v1 requirement.

Do not invent a dark color palette during v1 implementation.

Do not automatically generate dark theme colors from light theme values.

If dark mode is approved in the future, it requires:

1. Approved product scope.
2. Approved dark UI designs.
3. Verified dark theme color tokens.
4. Accessibility validation.
5. Implementation documentation updates.

Until then, the Atlas draft dark palette is not approved for Relvio.

---

# High Contrast Themes

A separate high contrast theme is not currently defined as a Relvio v1 product requirement.

Accessibility remains important, but AI coding assistants must not invent an additional visual theme without approved product and design requirements.

---

# Organization Branding

Custom organization branding is not part of the approved Relvio v1 color system.

Organizations must not be allowed to override core Relvio interface colors unless this capability is explicitly approved in future product scope.

Do not implement:

* Organization primary colors
* Custom navigation colors
* Custom button colors
* Organization-specific themes
* White-label color systems

as part of Relvio v1.

Core Relvio v1 must be validated before advanced enterprise branding capabilities are introduced.

---

# Flutter Implementation

All production colors must be centralized in the approved Flutter design system.

Feature widgets must not scatter raw hex values.

Avoid implementation such as:

```dart
const Color(0xFF2563FF)
```

directly throughout feature widgets.

Instead, feature UI should consume centralized color tokens.

Conceptually:

```dart
AppColors.brandPrimary
AppColors.backgroundPrimary
AppColors.textPrimary
AppColors.borderDefault
```

The final token structure must align with the approved project structure and engineering standards.

Do not create duplicate color classes inside individual features.

---

# Material Theme Integration

Flutter theme configuration should use approved Relvio tokens.

Material defaults must not silently replace approved Relvio colors.

When configuring:

* `ColorScheme`
* `ThemeData`
* Component themes
* Navigation themes
* Input themes
* Button themes

map approved Relvio colors intentionally.

Do not rely on generated Material color schemes as the final Relvio visual system unless explicitly approved.

Do not use automatic seed-color generation to invent the Relvio palette.

---

# AI Coding Assistant Rules

AI coding assistants must not:

* Replace `#2563FF` with a similar blue.
* Replace `#FCFCFD` with pure white globally.
* Reuse the Atlas color palette.
* Invent secondary brand colors.
* Introduce Emerald as a Relvio brand color.
* Introduce Amber as a Relvio brand color.
* Generate a `50` to `900` palette automatically.
* Add dark mode without approval.
* Add organization branding without approval.
* Generate a Material color scheme from a seed and treat it as approved.
* Add gradients for visual improvement.
* Scatter raw color values across feature widgets.
* Infer business state from UI color.
* Redesign approved UI colors.

When an exact required color cannot be verified, the implementation assistant must:

1. Identify the affected component or state.
2. Report the unresolved color requirement.
3. Avoid inventing a substitute.
4. Continue with unrelated implementation work where possible.

---

# Color Usage Rules

## Do

* Use approved Relvio colors.
* Use `#2563FF` as the approved primary brand color.
* Use `#FCFCFD` as the approved primary application background.
* Centralize production color values.
* Use semantic design tokens.
* Follow the approved Relvio UI.
* Preserve meaningful visual hierarchy.
* Support meaning with labels, icons, or text where appropriate.
* Report unresolved color values.

## Do Not

* Reuse the Atlas palette.
* Invent new brand colors.
* Generate arbitrary color scales.
* Add decorative gradients.
* Introduce unapproved themes.
* Hardcode raw colors throughout feature widgets.
* Use color as the only critical state indicator.
* Infer backend state from color.
* Recolor the frozen Relvio UI.

---

# Source of Truth Priority

For color decisions, use the following authority boundaries:

1. Approved Relvio UI defines product visual intent.
2. `19_Brand_Identity.md` defines approved brand identity and primary brand direction.
3. `Color System.md` defines color governance and implementation rules.
4. Shared Flutter design tokens define centralized production color values.
5. Feature UI consumes approved shared color tokens.

`Brand Assets.md` governs approved brand asset usage.

`Asset_Structure.md` governs production asset organization.

An implementation assistant must not use generic Flutter, Material, Tailwind, or third-party design-system defaults to override approved Relvio color decisions.

If a genuine contradiction remains, implementation must stop at the conflicting color decision and request clarification.

---

# Success Criteria

The Relvio color system is successful when:

* The approved Relvio UI is implemented without unintended recoloring.
* `#2563FF` remains the consistent primary brand color.
* `#FCFCFD` remains the approved primary application background.
* Product colors are centralized in Flutter.
* Feature code does not invent colors.
* Semantic colors communicate meaning consistently.
* Critical states do not rely only on color.
* Unapproved dark mode and organization themes are not introduced.
* AI coding assistants can implement the color system without guessing.
* Color documentation does not conflict with the approved brand or UI.

---

# End of Document
