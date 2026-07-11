---
Document: Typography System
Version: 1.1
Status: Approved
Project: Relvio
Owner: Design Team
---

# Typography System

## Purpose

This document defines how typography responsibilities are interpreted, centralized, and implemented throughout Relvio.

Typography supports:

- Visual hierarchy
- Readability
- Content scanning
- Product clarity
- Interaction understanding
- Brand consistency

The approved frozen Relvio v1 mobile UI is the visual authority for typography.

This document does not define a generic typography scale.

This document does not authorize implementation teams or AI coding assistants to replace approved text styles with a conventional Material, web, or SaaS typography system.

---

# Typography Philosophy

Relvio typography should feel:

- Modern
- Professional
- Calm
- Clear
- Readable
- Balanced

Typography should help users understand the product without drawing unnecessary attention to itself.

Text hierarchy should communicate:

- Primary screen context
- Section importance
- Content relationships
- Supporting information
- Interactive labels
- Status and feedback

The goal is controlled consistency.

The goal is not to force every text value into a generic scale.

---

# Primary Typeface

The approved Relvio typeface is:

**Inter**

Inter is the primary typeface for the Relvio v1 mobile application.

Flutter implementation must use the approved Inter font assets and approved typography responsibilities.

Font assets must follow:

- `Asset_Structure.md`
- `Brand Assets.md`
- Approved Flutter asset configuration

If required approved Inter font files are missing, report the missing assets.

Do not silently replace the approved typeface.

---

# Font Asset Authority

Production typography must use approved font assets.

Do not:

- Download an arbitrary Inter package during implementation without checking approved assets
- Replace Inter with another font because it is available by default
- Recreate font files
- Rename font families inconsistently
- Configure multiple unrelated font families for convenience

The Flutter `fontFamily` configuration must match the approved font asset registration.

If the approved font asset structure and Flutter configuration conflict, report the issue.

Do not guess.

---

# Platform Font Boundary

Relvio does not intentionally switch its primary visual typeface by operating system.

Do not define the Relvio typography hierarchy as:

```text id="7p9czo"
Inter
↓
SF Pro Display
↓
Roboto
↓
Segoe UI
↓
sans-serif


for normal approved application typography.

Relvio uses Inter as its approved product typeface.

Android and iOS should preserve the approved Relvio visual identity.

A system fallback may occur at the rendering level for unsupported glyphs or technical font behavior, but it must not become a deliberate platform-specific redesign of the Relvio typography system.

This document does not define Windows typography because Windows is not an approved Relvio v1 product platform.

Frozen UI Authority

The approved Relvio v1 mobile UI controls visible typography decisions.

Approved visual references determine responsibilities such as:

Screen titles
Section headings
Card titles
Primary content
Secondary content
Supporting text
Form labels
Input text
Button labels
Navigation labels
Status text
Timestamps
Empty-state text
Validation feedback

Implementation should reproduce the approved hierarchy faithfully.

Do not replace an approved text style merely because another style fits a conventional typography scale.

No Generated Typography Scale

This document does not approve a generic typography scale such as:

Display Large
Display Medium
Display Small
Heading 1
Heading 2
Heading 3
Heading 4
Title
Body Large
Body Medium
Body Small
Caption
Label
Overline

Do not create these styles automatically.

Do not generate typography levels to complete a hierarchy.

A text style should be centralized because it represents a verified repeated Relvio typography responsibility.

It should not exist merely because a generic design system usually contains that level.

Design Tokens.md remains authoritative for approved token definitions.

Repeated Typography Responsibilities

A typography style may be centralized when it represents a genuinely repeated approved Relvio responsibility.

Potential responsibility categories may include repeated approved uses such as:

Primary screen title
Section title
Primary body content
Secondary supporting content
Button label
Form label
Input content
Navigation label
Small metadata
Validation feedback

These examples do not approve style names or numeric values.

Before centralizing a typography responsibility:

Verify the style against approved Relvio UI references.
Confirm that the same visual responsibility genuinely repeats.
Confirm the relevant font size.
Confirm the relevant font weight.
Confirm the relevant line-height behavior.
Confirm letter spacing where visibly intentional.
Use a responsibility-based name.
Avoid generating adjacent styles for symmetry.
Responsibility-Based Naming

Where typography is centralized, naming should describe the visual or product responsibility where practical.

Conceptual examples:

screenTitle
sectionTitle
primaryBody
secondaryBody
buttonLabel
fieldLabel
navigationLabel
metadataText

These names are illustrative.

They do not approve the tokens or style values.

Avoid generic naming such as:

displayLarge
displayMedium
heading1
heading2
bodyLarge
bodyMedium
bodySmall

when the actual Relvio responsibility is known.

Two typography responsibilities may currently use the same numeric font size without representing the same design responsibility.

Do not merge styles solely because their current values are equal.

Font Weights

Typography weight must follow the approved Relvio UI and available approved Inter font assets.

This document does not require every Inter weight to be bundled or used.

Do not automatically configure:

300
400
500
600
700
800

merely because Inter supports those weights.

Only required approved font weights should be configured.

If the approved UI requires a weight whose font asset is missing, report the missing asset or configuration requirement.

Do not simulate missing approved font weights through arbitrary substitutions when the visual difference is significant.

Font Size

Font sizes must follow verified approved Relvio UI requirements.

This document does not approve a global font-size scale.

Do not automatically create values such as:

11
12
13
14
15
16
18
20
24
30
32
40
48

as a typography system.

A repeated verified font size may appear in multiple typography responsibilities.

That does not automatically make the font size itself a generic reusable token.

Typography should be centralized by approved responsibility where appropriate.

Unique intentional approved text values may remain local.

The goal is controlled consistency, not zero numeric literals.

Line Height

Line-height behavior must follow the approved visual typography responsibility.

Relvio does not approve universal rules such as:

120% for headings
140% for UI elements
160% for body text

through this document.

Do not apply one percentage rule to all text in a category.

In Flutter, TextStyle.height is a multiplier relative to font size and must be handled carefully.

Do not copy CSS line-height assumptions directly into Flutter.

When an approved line-height relationship is verified and repeated, it may be centralized as part of the relevant typography responsibility.

Unique intentional line-height behavior may remain local.

Letter Spacing

Letter spacing must follow the approved Relvio visual reference.

This document does not approve universal values such as:

0
-0.5
1

for broad typography categories.

Do not add negative letter spacing to large text merely because it is common in modern SaaS interfaces.

Do not uppercase and letter-space text to create an Overline style unless the approved Relvio UI requires that responsibility.

Repeated verified letter-spacing behavior may be centralized with the relevant typography responsibility.

Text Color

Typography color responsibilities are controlled by Color System.md.

This document does not independently define:

Gray 900
Gray 600
Gray 500
Gray 400
White

as typography colors.

Text should use approved Relvio color responsibilities such as the relevant:

Primary content responsibility
Secondary content responsibility
Muted content responsibility
Disabled responsibility
Inverse content responsibility
Error responsibility

The exact approved color value and token ownership remain controlled by Color System.md and Design Tokens.md.

Do not create a separate typography color palette.

Text Alignment

Text alignment should follow the approved frozen UI and actual content responsibility.

Do not create a universal rule that all text must be left aligned with fixed exceptions.

Approved screens may intentionally use:

Leading alignment
Center alignment
Numeric alignment appropriate to the content

Do not center text merely because a screen is an empty state.

Do not change approved alignment to enforce a generic typography rule.

Avoid justified body text unless an explicitly approved design requires it.

Screen Titles

Screen-title typography must follow the approved frozen Relvio UI.

Do not automatically map screen titles to a generic Heading 1.

A screen title responsibility may be centralized when its approved style genuinely repeats.

The relevant:

Font size
Weight
Line height
Color
Spacing relationship

must come from approved Relvio design responsibilities.

Section Typography

Section headings and section-supporting text must preserve the approved hierarchy.

Do not assume all section headings share one universal style.

Where the approved UI repeats a section-title responsibility, centralization is appropriate.

Do not force visually different approved section responsibilities into one typography token merely because both are headings.

Body Typography

Body and supporting text must follow approved Relvio UI responsibilities.

This document does not require a universal minimum visible body size of 16.

The approved UI may use different text sizes for different responsibilities.

Implementation should preserve readability and accessibility while maintaining frozen UI fidelity.

Do not increase all 14 or 15 logical-pixel text to 16 merely to satisfy a generic rule.

If an approved text responsibility creates a serious readability or accessibility conflict, report it for review.

Do not silently redesign the typography hierarchy.

Button Typography

Button typography is controlled by approved button component responsibilities.

Do not automatically define:

Primary Button: 16 / 600
Secondary Button: 15 / 600
Small Button: 14 / 600

from this document.

Button labels must follow the approved Relvio UI and Component Library.md.

Different approved button responsibilities may use different typography.

Do not create button sizes or button variants because a typography style exists.

Typography must follow the approved component.

Input Typography

Input typography must follow approved Relvio field responsibilities.

Relevant typography may include:

Field label
Input content
Placeholder content
Supporting text
Validation feedback

Do not automatically define:

Input: 16 / 400
Label: 14 / 500
Helper: 12 / 400
Error: 12 / 500

unless those values are verified from the approved Relvio UI.

Repeated approved input typography should be centralized through the appropriate field component and typography responsibilities.

Card Typography

Card typography must follow approved Relvio card responsibilities.

Do not assume every card uses:

Title: 18 / 600
Description: 14 / 400
Statistics: 30 / 700

Cards may represent different product and visual responsibilities.

The approved frozen UI determines the hierarchy.

Repeated card typography responsibilities may be centralized.

Do not invent a statistics style merely because dashboard cards commonly use one.

Navigation Typography

Navigation typography must match the approved frozen Relvio mobile UI.

The approved primary bottom navigation label is:

Workspace

Do not use:

More

as the primary navigation destination name.

This document does not define typography for:

Desktop sidebars
Desktop top navigation
Web navigation

Relvio v1 is approved for Android and iOS.

Bottom navigation typography must follow the approved visual reference.

Do not automatically apply 12 / 500 unless verified from the approved UI.

Table Typography Boundary

This document does not define a generic table typography system.

Desktop data tables are not an approved Relvio v1 platform requirement.

If an approved mobile screen contains tabular or structured data presentation, its typography must follow the approved screen and component responsibilities.

Do not create table header and row typography from the old Atlas draft.

Responsive Typography

Relvio v1 product platforms are:

Android
iOS

Typography must remain usable across supported mobile screen sizes.

Do not create a rule that:

Mobile uses smaller headings
Desktop uses larger headings

Desktop is not an approved v1 product platform.

Do not create responsive typography interpolation or breakpoint-based type scales without an approved requirement.

Where mobile layout constraints require adaptation, preserve the approved hierarchy and product meaning.

A significant typography change absent from approved UI references should be reported.

Do not redesign the screen.

Text Scaling

Flutter implementation must consider operating-system text scaling and accessibility behavior.

Text scaling should be reviewed for critical screens and workflows.

Implementation should protect against:

Clipped essential text
Unreachable actions
Hidden validation feedback
Broken navigation labels
Severe layout overflow

Do not disable text scaling globally merely to preserve screenshot fidelity.

Do not redesign the entire typography hierarchy automatically in response to scaling.

Use appropriate Flutter layout behavior and report serious unresolved conflicts.

Accessibility

Typography should support practical mobile readability.

Implementation should consider:

Readable content hierarchy
Sufficient approved color contrast
Clear validation feedback
Appropriate text scaling behavior
Screen-reader semantics
Avoidance of unnecessarily thin text
Avoidance of visually hidden essential information

This document does not define a universal 16 logical-pixel minimum for every body responsibility.

Accessibility should be evaluated against the actual approved Relvio interface.

If a serious accessibility conflict exists, report it for review rather than silently replacing approved typography values.

Flutter TextTheme Boundary

Flutter TextTheme may centralize appropriate repeated approved typography responsibilities where it improves consistency.

However, Flutter's default Material typography scale is not the Relvio visual authority.

Do not treat Material styles such as:

displayLarge
displayMedium
headlineLarge
headlineMedium
titleLarge
bodyLarge
bodyMedium
labelLarge

as approved Relvio styles merely because Flutter provides them.

Approved Relvio responsibilities may be mapped deliberately where appropriate.

Do not force every Relvio typography responsibility into TextTheme.

A separate approved typography structure may be used for repeated responsibilities that do not map cleanly to Material semantics.

Flutter Theme Implementation.md remains authoritative for Flutter theme boundaries.

Typography Token Boundary

Design Tokens.md owns approved token definitions.

This document provides typography-governance rules.

It does not independently approve token names such as:

text.display.large
text.heading.1
text.heading.2
text.body.large
text.body.medium
text.body.small
text.caption
text.label

Do not create these tokens from this document.

When a verified repeated typography responsibility deserves centralization, follow the approved design-token and Flutter-theme documentation.

Do not maintain conflicting typography definitions across multiple files.

Local Typography Values

A unique intentional approved typography value may remain local.

Do not create a global text style for a value used once solely to eliminate a TextStyle literal.

Do not replace a unique approved value with the nearest shared style merely to reduce code.

A local typography value is acceptable when it is:

Intentional
Supported by the approved UI
Unique to the visual responsibility
Clear in implementation context

If the same responsibility begins repeating, review whether centralization is appropriate.

Implementation Review

During Flutter implementation, typography should be compared against approved Relvio UI references.

Review should consider:

Font family
Font size
Font weight
Line-height behavior
Letter spacing
Text color responsibility
Alignment
Truncation
Wrapping
Text scaling
Hierarchy between adjacent text

Visual differences should be evaluated by responsibility.

Do not normalize every text value automatically.

Determine whether the difference represents:

An implementation error
A repeated typography responsibility
An intentional local style
An unresolved design measurement
AI Implementation Rules

Claude or another AI coding assistant acts as an implementation engineer.

AI must not:

Generate a generic typography scale
Create Display, H1, H2, H3, Body, Caption, and Overline styles automatically
Copy Material typography defaults as Relvio authority
Create responsive desktop typography
Replace Inter with platform fonts
Bundle every Inter font weight automatically
Invent font sizes
Invent line-height percentages
Invent letter spacing
Create typography colors
Increase all body text to 16
Replace unique approved typography with the nearest generic token
Create typography tokens for scale completeness

AI should:

Use Inter
Use approved font assets
Use the frozen Relvio UI as visual authority
Identify genuinely repeated typography responsibilities
Use approved centralized styles where they exist
Preserve intentional local values
Review text scaling behavior
Report unresolved significant typography decisions

The goal is faithful Relvio implementation.

The goal is not generic design-system completeness.

Documentation Responsibilities

This document owns:

Typography implementation philosophy
Typeface usage rules
Typography centralization rules
Font weight and asset boundaries
Line-height and letter-spacing guidance
Mobile typography boundaries
Text scaling expectations
Typography review expectations

This document does not own:

Numeric design token definitions
Color definitions
Component specifications
Flutter theme architecture
Screen design
Product navigation
Platform expansion

Those responsibilities remain with their approved Relvio documents.

Success Criteria

The Relvio typography system is successful when:

Inter remains the approved product typeface.
Approved frozen UI typography is reproduced faithfully.
Repeated typography responsibilities remain consistent.
Generic typography scales are not invented.
Material typography defaults do not redefine Relvio.
Platform fonts do not replace the Relvio visual identity.
Unique intentional typography values are preserved where appropriate.
Text remains usable across supported Android and iOS screen sizes.
Text scaling is reviewed for critical workflows.
Typography tokens represent verified Relvio responsibilities.
AI coding assistants report unresolved typography requirements instead of guessing.
The interface maintains clear, calm, readable visual hierarchy.