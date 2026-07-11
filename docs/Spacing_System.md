---
Document: Spacing System
Version: 1.1
Status: Approved
Project: Relvio
Owner: Design Team
---

# Spacing System

## Purpose

This document defines how spacing responsibilities are interpreted, centralized, and implemented throughout Relvio.

Spacing supports:

- Visual hierarchy
- Content grouping
- Readability
- Interaction clarity
- Layout rhythm
- Visual consistency

The approved frozen Relvio v1 mobile UI is the visual authority for spacing.

This document does not define a generic spacing scale.

This document does not authorize implementation teams or AI coding assistants to replace approved spacing relationships with a conventional grid system.

---

# Spacing Philosophy

Whitespace is an intentional part of the Relvio interface.

Spacing should help users understand:

- Which elements belong together
- Which sections are separate
- Which content has greater emphasis
- Where an interaction begins or ends
- How information should be scanned

Spacing should reflect approved visual relationships.

The goal is controlled consistency.

The goal is not zero numeric literals.

---

# Frozen UI Authority

The approved Relvio v1 mobile UI controls visible spacing decisions.

Approved visual references determine spacing relationships such as:

- Screen edge to content
- Section to section
- Heading to supporting content
- Label to field
- Field to field
- Icon to text
- Avatar to content
- Card internal spacing
- Card to card
- List item spacing
- Button content spacing
- Navigation spacing
- Empty-state spacing
- Loading-state spacing

Implementation should reproduce these approved relationships faithfully.

Do not replace an approved spacing relationship merely because another value fits a conventional spacing scale.

---

# No Generic Grid Assumption

Relvio does not approve a universal `8px` grid system through this document.

Do not assume that every spacing value must be:

- A multiple of `8`
- A multiple of `4`
- Derived from an `8px` base unit

A repeated approved spacing value may happen to align with a common grid.

That does not make the grid itself the design authority.

The frozen Relvio UI remains authoritative.

---

# No Generated Spacing Scale

This document does not approve a generic scale such as:

| Token | Value |
|---|---:|
| xs | 4 |
| sm | 8 |
| md | 16 |
| lg | 24 |
| xl | 32 |
| 2xl | 40 |
| 3xl | 48 |
| 4xl | 64 |
| 5xl | 80 |
| 6xl | 96 |

Do not create this scale automatically.

Do not create spacing tokens because a value appears conventional.

Do not invent missing intermediate spacing values to complete a scale.

Spacing tokens must represent verified repeated Relvio design responsibilities.

`Design Tokens.md` remains authoritative for approved token definitions.

---

# Repeated Spacing Responsibilities

A spacing value may be centralized when it represents a genuinely repeated approved Relvio responsibility.

Examples of responsibilities that may justify centralized spacing include repeated approved relationships such as:

- Standard mobile screen horizontal content inset
- Repeated section separation
- Repeated form field separation
- Repeated icon and label relationship
- Repeated card internal spacing
- Repeated list content relationship

These examples do not approve specific numeric values.

Before centralizing a spacing responsibility:

1. Verify the value against approved Relvio UI references.
2. Confirm that the same visual responsibility genuinely repeats.
3. Confirm that centralization improves consistency.
4. Use a responsibility-based name.
5. Avoid creating a generic scale merely for symmetry.

---

# Responsibility-Based Naming

Where approved spacing is centralized, naming should describe the responsibility where practical.

Prefer names that communicate intended use.

Conceptual examples:

```text
screenHorizontalPadding
sectionSpacing
formFieldSpacing
iconLabelSpacing
cardContentPadding



These names are illustrative.

They do not approve the tokens or numeric values.

Avoid generic token names such as:

xs
sm
md
lg
xl
2xl
3xl

when the token's actual product responsibility is known.

Generic names can encourage unrelated UI relationships to share a value merely because the number is equal.

Two spacing responsibilities may currently use the same numeric value without being the same design responsibility.

Unique Intentional Values

A unique intentional approved spacing value may remain local.

Do not create a global token for a value used once solely to eliminate a numeric literal.

Do not modify a unique approved value merely because it does not fit a spacing scale.

Values such as:

13
19
27
35

are not automatically invalid.

The relevant question is whether the value is:

Intentional
Supported by the approved UI
Appropriate to the local layout responsibility

If a visually significant value cannot be confidently determined from the approved design reference, report the uncertainty.

Do not guess merely to fit a generic scale.

Flutter Units

Flutter layout dimensions use logical pixels.

Spacing values implemented through Flutter properties such as:

EdgeInsets
SizedBox
Padding
Gap responsibilities where an approved dependency exists
Layout constraints

must represent the approved visual spacing responsibility.

Do not describe Flutter spacing implementation as CSS px behavior.

The design reference may communicate numeric visual dimensions, but Flutter implementation uses logical layout dimensions.

Implementation should verify visual fidelity on supported mobile targets.

Screen Spacing

Screen-level spacing must follow the approved frozen mobile UI.

This includes:

Horizontal content inset
Top content positioning
Bottom content spacing
Safe-area relationships
Section spacing
Scroll content padding

This document does not approve universal values such as:

16 horizontal padding
24 vertical padding

unless those values are verified from the approved Relvio UI and centralized through the appropriate approved design responsibility.

Do not apply one screen padding value mechanically to every screen.

A repeated approved screen responsibility may be centralized.

A unique approved screen layout may retain intentional local spacing.

Safe Areas

System safe areas are not design spacing tokens.

Flutter implementation must account for relevant Android and iOS system areas.

Safe-area behavior may affect:

Top content positioning
Bottom navigation
Bottom actions
Scrollable content
Keyboard interaction

Do not hardcode spacing intended to imitate a system safe area.

Use appropriate Flutter platform and layout behavior.

Preserve the approved visual relationship after system insets are applied.

Component Spacing

Component-specific spacing responsibilities are controlled by approved component definitions and the frozen UI.

Examples include:

Button internal padding
Input internal padding
Card internal padding
Navigation item spacing
Avatar and text spacing
List item spacing

This document does not independently define numeric component spacing.

Component Library.md controls approved shared component responsibilities.

Do not use this document to override an approved component.

Do not create one universal component padding value for visually different approved components.

Button Spacing

Button spacing must follow approved Relvio button responsibilities.

Do not automatically apply:

24 horizontal
12 vertical

to every button.

Different approved button responsibilities may have different:

Height
Horizontal content spacing
Icon relationship
Label relationship

Shared approved button behavior should be centralized through the appropriate component responsibility.

Unique approved button presentation should not be forced into a generic spacing rule.

Input Spacing

Input spacing must follow approved Relvio field presentation.

Do not automatically apply:

16 horizontal
12 vertical

to every input.

Input spacing may be influenced by:

Field height
Label behavior
Prefix icon
Suffix icon
Validation content
Multiline behavior
Approved field type

Repeated approved input responsibilities should be implemented through approved shared field components where appropriate.

Card Spacing

Card spacing must follow the approved Relvio card presentation.

Do not assume every card uses:

24 internal padding
16 element gap

Cards may represent different approved visual responsibilities.

Repeated card patterns should use the relevant approved shared component responsibility.

Do not create a universal card spacing rule that damages frozen UI fidelity.

Form Spacing

Form spacing should preserve approved grouping and hierarchy.

Implementation should distinguish relationships such as:

Section heading to supporting content
Label to field
Field to validation feedback
Field to field
Form section to form section
Form content to primary action

Do not define a generic form sequence from this document.

The approved screen and component responsibilities control the actual spacing.

Do not add spacing mechanically after every widget.

Spacing should communicate form structure.

List Spacing

List spacing must follow the approved list responsibility.

Different lists may represent different content densities and interaction patterns.

Do not assume every list item requires:

16 vertical padding
8 item gap

Repeated approved list patterns may be centralized.

List spacing should preserve:

Readability
Touch usability
Content hierarchy
Visual density shown in the approved UI
Icon Spacing

Icon spacing is governed by approved visual relationships and Iconography.md.

Do not assume every icon-to-text relationship is 8.

Do not assume every icon-to-icon relationship is 16.

Repeated verified icon spacing may be centralized where appropriate.

Unique approved icon relationships may remain local.

Do not create a separate spacing system inside iconography.

Navigation Spacing

Navigation spacing must follow the approved frozen Relvio mobile UI.

The approved primary bottom navigation label is:

Workspace

Do not use:

More

as the primary navigation destination name.

This document does not approve:

Sidebar spacing
Sidebar item height
Sidebar padding
Desktop navigation gaps

Relvio v1 is approved for Android and iOS.

Navigation spacing must preserve the approved mobile navigation design.

Dashboard and Product-Area Spacing

This document does not define independent spacing systems for:

Dashboard
People
Journey
Events
Attendance
Follow-ups
Workspace

Product-area layouts must follow their approved frozen UI references.

Do not assign generic widget gaps or section spacing based on old Atlas documentation.

If multiple product areas genuinely share an approved spacing responsibility, centralization may be appropriate.

Do not force visual sameness where the frozen UI intentionally differs.

Empty-State Spacing

Empty states must follow approved Relvio visual language.

An empty state may contain:

Approved text
An approved icon
An approved illustration asset
An approved action

This document does not define a mandatory spacing sequence between these elements.

Do not automatically implement:

Illustration
24
Title
12
Description
24
Action

unless that relationship is verified from the approved UI.

Illustrations are not mandatory.

Do not invent illustration assets.

Dialog and Overlay Spacing

Dialog, modal, sheet, and overlay spacing must follow approved Relvio UI responsibilities.

Do not assume every overlay uses:

24 padding
16 title gap
24 action gap

Different overlay responsibilities may require different approved layouts.

Use shared components where a genuinely repeated approved pattern exists.

Do not create desktop dialog assumptions for the mobile application.

Mobile Platform Boundary

Relvio v1 product platforms are:

Android
iOS

This document does not define spacing systems for:

Desktop
Web
Windows
macOS
Linux

Do not create:

Desktop outer margins
Desktop content gaps
Desktop sidebar gaps
Tablet grid systems
Desktop grid systems

from this document.

Supported mobile layouts must remain stable across relevant Android and iOS screen sizes.

Responsive behavior should preserve the approved mobile UI rather than create new product layouts.

Grid Boundary

Relvio does not approve a universal column grid through this document.

Do not create:

12-column desktop grid
8-column tablet grid
4-column mobile grid

unless a separately approved design responsibility explicitly requires such a system.

Flutter layout should implement the approved mobile interface using appropriate layout widgets and constraints.

Do not force approved screens into a generic column grid.

Responsive Spacing

Spacing must remain usable across supported mobile screen sizes.

Implementation should protect against:

Content overflow
Clipped essential content
Unreachable actions
Broken text layout
Unsafe system-area placement

Do not apply a generic rule that spacing must always reduce on smaller devices.

Do not create automatic spacing interpolation without an approved requirement.

Where layout adaptation is technically necessary, preserve the approved hierarchy and visual intent.

A significant responsive design decision that is absent from approved UI references should be reported.

Do not redesign the screen.

Accessibility and Touch Usability

Spacing should support practical mobile interaction.

Implementation should consider:

Touch target usability
Separation between adjacent actions
Readable content grouping
Form usability
Screen-reader navigation relationships
Error-message clarity

A commonly recognized mobile touch-target guideline must not automatically redefine the visible dimensions of every approved Relvio component.

Where a visible approved control requires accessibility support, Flutter may use appropriate semantic or hit-target implementation techniques when they preserve the approved UI.

If a serious accessibility conflict exists, report it for review rather than silently redesigning the component.

Design Token Boundary

Design Tokens.md owns approved token definitions.

This document provides spacing-governance rules.

It does not independently approve token names or values.

Do not create:

spacing.xs
spacing.sm
spacing.md
spacing.lg
spacing.xl
spacing.2xl
spacing.3xl

from this document.

When a verified repeated spacing responsibility deserves centralization, update or follow the appropriate approved token documentation.

Do not maintain conflicting spacing definitions across multiple files.

Theme Boundary

Flutter Theme Implementation.md controls Flutter theme boundaries.

ThemeData is not the entire Relvio design system.

Spacing responsibilities do not need to be forced into ThemeData.

Repeated approved spacing responsibilities may use an appropriate centralized Flutter structure consistent with approved architecture and design documentation.

Do not generate a generic spacing scale merely because Flutter implementation is beginning.

Implementation Review

During Flutter implementation, spacing should be reviewed against approved Relvio UI references.

Review should consider:

Screen edge relationships
Section hierarchy
Content grouping
Component internal spacing
Repeated visual relationships
Navigation balance
Form rhythm
List density
Touch usability
Layout stability

Visual comparison should identify meaningful inconsistencies.

Do not normalize every numeric difference automatically.

Determine whether the difference represents:

An implementation error
A repeated design responsibility
An intentional local value
An unresolved design measurement
AI Implementation Rules

Claude or another AI coding assistant acts as an implementation engineer.

AI must not:

Create an 8px grid because it is common
Generate a generic spacing scale
Force every value to a multiple of 4
Force every value to a multiple of 8
Replace approved local spacing with the nearest token
Create xs, sm, md, lg, and xl tokens automatically
Invent desktop spacing
Invent tablet spacing
Create a column grid
Apply one padding value to every card
Apply one spacing sequence to every form
Apply one spacing value to every screen
Redesign responsive spacing

AI should:

Use the approved frozen UI as visual authority
Identify genuinely repeated spacing responsibilities
Use approved tokens where they exist
Preserve intentional local values
Report unresolved significant spacing decisions

The goal is faithful Relvio implementation.

The goal is not architecture symmetry or token completeness.

Documentation Responsibilities

This document owns:

Spacing implementation philosophy
Spacing centralization rules
Repeated-spacing responsibility guidance
Local spacing guidance
Mobile spacing boundaries
Spacing review expectations

This document does not own:

Numeric design token definitions
Component specifications
Iconography specifications
Flutter theme architecture
Screen design
Product navigation
Responsive platform expansion

Those responsibilities remain with their approved Relvio documents.

Success Criteria

The Relvio spacing system is successful when:

Approved frozen UI spacing is reproduced faithfully.
Repeated spacing responsibilities remain consistent.
Generic spacing scales are not invented.
Unique intentional values are preserved where appropriate.
Component spacing remains controlled by approved component responsibilities.
Android and iOS layouts remain stable.
Desktop and web spacing infrastructure is not introduced.
Spacing tokens represent verified Relvio responsibilities.
AI coding assistants do not normalize the UI into a generic 8px system.
The interface maintains clear hierarchy, grouping, readability, and visual rhythm.