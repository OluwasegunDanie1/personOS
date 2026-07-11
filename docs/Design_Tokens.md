---
Document: Design Tokens
Version: 1.1
Status: Approved
Project: Relvio
Owner: Design & Engineering
---

# Design Tokens

## Purpose

This document defines how approved Relvio design values are translated into centralized Flutter design tokens.

Design tokens provide a controlled implementation layer between:

- The approved Relvio UI
- Approved brand and design documentation
- Shared Flutter components
- Feature UI

The Relvio v1 mobile UI is already approved and frozen.

This document does not invent a new visual system.

It exists to ensure that repeated approved design values are:

- Centralized
- Named consistently
- Reused intentionally
- Easy to maintain
- Protected from arbitrary implementation changes

---

# Core Principle

Design tokens must be extracted from approved Relvio design decisions.

Do not create a generic token system first and force the approved UI to fit it.

The correct implementation direction is:

```text
Approved Relvio UI
        ↓
Identify Verified Repeated Design Values
        ↓
Assign Semantic or Foundation Responsibility
        ↓
Create Centralized Flutter Tokens
        ↓
Build Shared Components
        ↓
Implement Feature UI




Relvio must follow the first approach.

Relvio v1 Design Context

Relvio v1 targets:

Android
iOS

The approved frontend technology is:

Flutter

The approved typeface is:

Inter

The approved primary brand color is:

#2563FF

The approved primary application background is:

#FCFCFD

The approved Relvio UI is the visual implementation authority.

Do not introduce desktop or web token systems as Relvio v1 requirements.

Token Responsibilities

Relvio design tokens may represent approved repeated values for:

Colors
Typography
Spacing
Radius
Borders
Shadows and elevation
Icon sizing
Avatar sizing
Component dimensions
Opacity
Motion

A token category should only contain values required by approved Relvio UI or repeated implementation patterns.

The existence of a category does not require a complete generic scale.

Token Types

Relvio may use two conceptual token levels:

Foundation Tokens
Semantic Tokens

These responsibilities should remain clear.

Foundation Tokens

Foundation tokens represent verified reusable design values.

Examples may include:

space4
space8
radius12
fontSize16
durationFast

Foundation tokens describe reusable values.

They do not automatically communicate product meaning.

Only repeated approved values should become foundation tokens.

Do not create large speculative scales for future use.

Semantic Tokens

Semantic tokens describe design responsibility or meaning.

Examples may include:

brandPrimary
backgroundPrimary
textPrimary
textSecondary
borderDefault
actionPrimary
stateError

Semantic tokens should be preferred where the meaning of a value matters.

For example:

AppColors.brandPrimary

is clearer than:

AppColors.blue500

when the value represents the Relvio primary brand color.

Semantic naming helps prevent implementation code from depending on arbitrary palette positions.

Token Extraction Rule

Before creating a token:

Confirm the value exists in the approved Relvio UI or approved design documentation.
Confirm the value is exact.
Identify whether the value is repeated or semantically important.
Determine the correct token category.
Use a clear implementation name.
Reuse the token where the same design responsibility applies.

Do not estimate values from memory.

Do not replace approved values with visually similar values.

If an exact required value cannot be verified, report the unresolved design value.

Color Tokens

Color decisions and color meaning are governed by:

Color System.md

The design token system implements approved color values in Flutter.

The required approved color values include:

brandPrimary = #2563FF
backgroundPrimary = #FCFCFD

Additional color tokens must be created from verified approved UI values.

Possible semantic responsibilities may include:

brandPrimary
backgroundPrimary
backgroundSecondary
surfacePrimary
textPrimary
textSecondary
textMuted
textDisabled
textInverse
borderDefault
borderSubtle
iconPrimary
iconSecondary
actionPrimary
stateSuccess
stateWarning
stateError
stateInfo
overlay

This list defines possible responsibilities.

It does not approve values for every token.

Do not create a token with a guessed value merely because the token name appears in this document.

Color Scale Rule

Relvio does not require a generic:

50
100
200
300
400
500
600
700
800
900

color scale.

Do not generate a Tailwind-style Relvio Blue scale.

Do not automatically create:

Primary 50–900
Secondary 50–900
Emerald 50–900
Amber 50–900
Gray 50–900

The old Atlas token scales are not approved Relvio design tokens.

Where approved UI requires multiple related color values, create tokens based on their design responsibility.

For example:

brandPrimary
brandTint
actionPrimaryPressed
selectionBackground

The exact values must be verified.

Typography Tokens

The approved Relvio typeface is:

Inter

Typography tokens must be extracted from the approved Relvio UI and approved typography documentation.

Typography tokens may define:

Font family
Font size
Font weight
Line height
Letter spacing

where required.

Do not automatically use the Atlas font-size scale:

12
14
16
18
20
24
30
36
48

unless those values are confirmed by the approved Relvio UI.

Do not automatically use:

400
500
600
700

as the complete approved font-weight system merely because Inter supports those weights.

Only configure typography values required by the approved design.

Semantic Typography Styles

Typography should be centralized through approved semantic text styles.

Possible responsibilities may include:

display
heading
title
body
bodySecondary
label
caption

The final style names and values must reflect actual Relvio UI patterns.

Do not create every possible text style before implementation confirms its use.

A semantic typography style should preserve the complete approved typography treatment where appropriate, including:

Font family
Font size
Font weight
Line height
Letter spacing
Approved default text color responsibility where the theme structure requires it

Avoid rebuilding the same typography combination manually across feature widgets.

Typography Implementation

Flutter typography should be centralized.

Conceptually:

AppTypography.heading
AppTypography.title
AppTypography.body
AppTypography.label

The final implementation naming must follow:

14_Engineering_Standards.md
Approved project structure documentation

Do not scatter repeated TextStyle definitions throughout feature widgets.

Do not use Flutter or Material default typography as the final Relvio typography system when it conflicts with the approved UI.

Line Height

Do not use approximate global rules such as:

120%
140%
160%

based only on content category.

Line height must match approved typography intent.

Repeated approved line-height values may be centralized.

Where Flutter implementation requires conversion between design line height and TextStyle.height, calculate the value accurately from the approved font size and line-height specification.

Do not guess.

Spacing Tokens

Spacing tokens should centralize repeated approved spacing values.

Do not assume that every Relvio spacing value must use a universal 4-pixel scale.

The old Atlas spacing scale:

4
8
12
16
20
24
32
40
48
64
80
96

is not automatically approved.

During Flutter implementation:

Review approved screen spacing.
Identify repeated values.
Confirm exact values.
Centralize genuinely repeated values.
Preserve intentional unique layout values where required.

Possible implementation names may include:

space4
space8
space12
space16
space24

only when those values are confirmed and used.

Spacing Usage

Use spacing tokens when the same approved spacing responsibility or value is repeated.

Do not force an approved value such as:

18

to become:

16

or:

20

merely to fit a spacing scale.

Design tokens exist to preserve approved design consistency.

They do not authorize visual normalization.

Avoid arbitrary raw spacing values when an approved shared token already exists.

Radius Tokens

Border radius values must be extracted from approved Relvio components.

Do not automatically create the Atlas radius scale:

4
8
12
16
24
999

Possible token responsibilities may include:

radiusSmall
radiusMedium
radiusLarge
radiusPill

or value-based names where approved engineering conventions prefer them.

The final token strategy should remain clear and consistent.

A pill radius may use an implementation approach appropriate to Flutter.

Do not assume 999 is the required Relvio implementation value.

Border Tokens

Repeated approved border values may be centralized.

Border tokens may represent:

Width
Color responsibility
Radius where composition requires it

Possible responsibilities include:

borderWidthDefault
borderWidthFocused

Only create multiple border-width tokens when the approved UI requires distinct repeated values.

Do not automatically define:

1px
2px

as a complete border system.

Flutter implementation values should use logical pixels.

Shadow and Elevation Tokens

Relvio uses the visual treatment shown in the approved UI.

Do not invent generic:

None
Low
Medium
High

shadow levels unless repeated approved elevation patterns justify those tokens.

For each approved repeated shadow, verify:

Color
Opacity
Blur
Spread
Offset

where applicable.

Shared shadow treatments may be centralized.

Do not replace approved subtle borders with Material elevation merely because a component is a card.

Do not add shadows to create a more “premium” appearance.

The approved UI determines surface treatment.

Opacity Tokens

Do not create a generic opacity scale such as:

5%
10%
20%
40%
60%
80%
100%

without approved usage.

Repeated opacity values may be centralized where they represent a shared design treatment.

Possible uses may include:

Disabled presentation
Overlays
Muted visual treatment
Pressed state treatment

Opacity should not be used to invent unapproved color variations.

Do not apply opacity to entire widgets automatically for disabled states.

Component behavior and readability must remain intentional.

Icon Size Tokens

Icon sizes must match the approved Relvio UI.

Do not automatically use the Atlas scale:

16
20
24
28
32
40
48

During implementation:

Review approved icon usage.
Confirm repeated icon sizes.
Centralize repeated values.
Preserve approved component-specific values where necessary.

Possible implementation names may include:

iconSmall
iconMedium
iconLarge

or value-based names where appropriate.

Do not create unused icon sizes for future features.

Avatar Size Tokens

Avatar sizes must match approved Relvio screens.

Do not automatically use:

32
40
48
64
80
96

as an approved avatar scale.

Repeated approved avatar sizes may be centralized.

Possible semantic responsibilities may include:

avatarSmall
avatarMedium
avatarLarge

Feature-specific avatar presentation may remain within the relevant component when it is not a shared pattern.

Avatar behavior is governed by:

Component Library.md
Component Dimension Tokens

Repeated approved component dimensions may be centralized.

These may include:

Button height
Input height
Navigation height
App bar height
Avatar size
Shared icon size
Repeated container dimensions

Do not automatically implement Atlas button heights:

36
44
52

Do not automatically implement Atlas input heights:

48
56

The approved Relvio UI determines actual dimensions.

A component dimension should become a token when centralization improves consistency and maintainability.

Card Tokens

Do not create universal card tokens based only on the concept of a card.

Approved Relvio card patterns may differ by responsibility.

Shared repeated card treatments may centralize values such as:

Surface color
Border treatment
Radius
Shadow
Internal padding

Only when the same approved visual pattern is genuinely reused.

Feature-specific cards may compose shared foundation tokens without becoming one universal AppCard.

Component ownership is governed by:

Component Library.md
Layout Tokens

Relvio v1 is mobile-first for:

Android
iOS

Layout tokens may centralize repeated approved values such as:

Screen horizontal padding
Section spacing
Content gaps
Safe-area-aware layout treatment

Do not automatically introduce a generic grid system.

The Atlas grid:

Desktop = 12 columns
Tablet = 8 columns
Mobile = 4 columns

is not an approved Relvio v1 requirement.

Do not force approved mobile screens into a four-column grid.

Flutter layout should reproduce approved Relvio mobile designs.

Breakpoints

Relvio v1 does not define the Atlas breakpoint system:

Mobile: 0–599
Tablet: 600–1023
Desktop: 1024–1439
Large Desktop: 1440+

Do not add desktop or web breakpoint infrastructure as a v1 requirement.

Flutter implementation must behave correctly across supported Android and iOS screen sizes.

Where an approved mobile layout requires adaptive behavior, define the smallest implementation rule required by that layout.

Do not create a full responsive framework for hypothetical future platforms.

Screen Size Adaptation

Approved Relvio mobile UI should remain usable across supported mobile screen dimensions.

Implementation should account for:

Safe areas
Available width
Available height
Text scaling behavior
Keyboard visibility
Scrollable content
Device-specific system insets

Do not use one fixed reference device size as an absolute runtime layout.

Do not redesign screen hierarchy for unapproved tablet or desktop layouts.

Motion Tokens

Motion tokens may centralize repeated approved animation values.

Possible responsibilities may include:

durationFast
durationStandard
durationSlow

These names do not approve specific values.

Do not automatically use the Atlas durations:

150ms
250ms
400ms

unless those values match approved implementation requirements.

Animation values should be selected from:

Approved UI behavior
Existing Relvio motion patterns
Appropriate Flutter interaction behavior

Repeated values should then be centralized.

Motion Curves

Repeated animation curves may be centralized when Relvio uses consistent motion behavior.

Do not invent a large motion system.

Use Flutter curves intentionally.

Motion should support:

State understanding
Selection feedback
Navigation continuity
Loading presentation
Completion feedback

Do not add decorative motion merely because a motion token exists.

Motion Principles

Relvio motion should be:

Subtle
Responsive
Purposeful
Non-blocking

Motion may help:

Confirm interaction
Communicate state change
Guide attention
Improve continuity

Motion must not:

Delay required actions unnecessarily
Distract users
Create false success state
Hide backend failure
Replace loading state
Imply authoritative data mutation before confirmation

Simple animation should be implemented directly in Flutter where appropriate.

Do not introduce Lottie or Rive by default.

Animation asset rules are governed by:

Asset_Structure.md
Brand Assets.md
Component State Tokens

Not every interactive component supports every possible state.

Do not enforce the Atlas rule that every component supports:

Default
Hover
Pressed
Focused
Disabled
Loading
Error

Component states must come from actual component behavior.

Possible states include:

Default
Pressed
Focused
Selected
Disabled
Loading
Error

The relevant states depend on the component.

Relvio v1 does not require desktop hover states as a universal token responsibility.

Where repeated state treatments exist, they may use semantic tokens.

Touch Targets

Relvio mobile controls should provide appropriate usable touch targets.

A visible icon or control does not need to visually occupy the entire interaction target.

Flutter implementation may provide appropriate hit areas around smaller visual elements.

Do not arbitrarily resize approved visual icons solely to increase touch target size.

Where accessibility requirements and approved UI appear to conflict, document the issue for intentional resolution.

Do not silently redesign the component.

Accessibility and Tokens

Design tokens should support consistent accessibility implementation.

Relevant token responsibilities may affect:

Text readability
Color contrast
Touch target layout
Focus treatment where applicable
State distinction

Accessibility is not achieved by token existence alone.

Implemented components and screens must still be evaluated.

Color must not be the only critical state indicator.

Accessibility principles are further defined in:

Design Principles.md
Color System.md
Component Library.md
Light Theme

Relvio v1 follows the approved light mobile UI.

The approved primary application background is:

#FCFCFD

Light theme configuration must use verified Relvio design tokens.

Do not use generic Material light theme defaults as the final Relvio visual system where they conflict with the approved UI.

Dark Mode

Dark mode is not an approved Relvio v1 requirement.

Design tokens are not required to provide dark equivalents for every value.

Do not:

Generate dark colors automatically
Create a dark token map
Create dark component variants
Add a theme switcher
Configure an unapproved dark theme

If dark mode is approved in the future, it requires:

Approved product scope.
Approved dark UI designs.
Verified dark theme tokens.
Component review.
Accessibility validation.
Documentation updates.

The old Atlas dark-mode requirement is not approved for Relvio.

Theme Architecture

Flutter should use a centralized Relvio theme and design token system.

The implementation may use structures such as:

AppColors
AppTypography
AppSpacing
AppRadius
AppShadows
AppMotion

only where those structures match the approved project structure and actual token requirements.

This document does not require one Dart class per token category.

The final code organization should remain simple and maintainable.

Do not create empty token classes for hypothetical future values.

Material Theme Integration

Approved Relvio tokens should be mapped intentionally into Flutter theme configuration.

Relevant Flutter structures may include:

ThemeData
ColorScheme
TextTheme
Component themes

Use only where appropriate to the implementation.

Do not generate the Relvio color system from:

ColorScheme.fromSeed

and treat the generated values as approved.

Do not allow Material defaults to silently redefine:

Relvio Blue
Background colors
Typography
Button appearance
Input appearance
Navigation appearance

Shared Relvio components may still provide explicit approved styling where Flutter theme configuration alone is insufficient.

Token Naming

Flutter token names should be:

Clear
Consistent
Valid Dart identifiers
Appropriate to their responsibility

Prefer semantic names where meaning matters.

Examples:

brandPrimary
backgroundPrimary
textPrimary
actionPrimary
stateError

Foundation values may use clear value or scale names where appropriate.

Examples:

space8
space16
radius12

only when those values are approved and the naming strategy is useful.

Do not use Figma-style dotted token names directly as Dart identifiers.

For example:

color.primary.500
spacing.16
font.size.18

may be useful conceptually in design tooling but should not be copied blindly into Flutter code.

Flutter naming must follow approved engineering conventions.

Raw Values

Feature widgets should not scatter repeated raw design values.

Avoid repeated implementation such as:

const Color(0xFF2563FF)

throughout feature code.

Prefer centralized approved tokens such as:

AppColors.brandPrimary

Likewise, repeated approved spacing, radius, typography, and motion values should use centralized tokens.

A unique layout value is not automatically forbidden.

Do not create a meaningless global token for every one-off number merely to eliminate all numeric literals.

Tokenization should improve consistency and understanding.

Token Duplication

Do not create duplicate tokens for the same responsibility.

Avoid structures such as:

primaryBlue
brandBlue
relvioBlue
mainBlue
buttonBlue

when all values represent the same approved brand responsibility.

Different semantic tokens may intentionally reference the same foundation value when their responsibilities are distinct.

For example:

brandPrimary
actionPrimary

may currently resolve to the same approved value.

Their semantic responsibilities remain different.

Do not merge semantically distinct responsibilities solely because their current values match.

Token Change Rules

Changing a shared token may affect multiple screens and components.

Before changing an approved token:

Identify its responsibility.
Identify affected components.
Confirm the design change is approved.
Verify that the new value is correct.
Review affected screens.
Update relevant documentation where the design system decision changed.

Do not change a shared token to fix one feature if the token is correct elsewhere.

A feature-specific visual requirement may need a different approved token or component treatment.

Token Extraction During Flutter Implementation

Because the approved Relvio UI is frozen, token extraction may occur during Flutter foundation implementation.

The implementation process should:

Review approved Relvio screens.
Record repeated verified design values.
Compare repeated values across screens.
Identify semantic responsibilities.
Create the smallest useful token set.
Implement shared foundations.
Build approved components.
Validate screens against the approved UI.
Add tokens only when an approved repeated need appears.

Do not create the complete hypothetical Relvio design system before implementation begins.

The token system should grow from the approved product.

Design Source Limitations

If the implementation team only has static UI references and an exact value cannot be reliably determined:

Identify the affected design property.
Check approved design documentation.
Check available approved source assets or design specifications.
Report the unresolved value if it remains uncertain.

Do not use screenshot pixel sampling as unquestionable design authority where scaling, compression, color profiles, or export conditions may alter the result.

Do not claim an estimated value is approved.

Approved exact values such as:

#2563FF
#FCFCFD
Inter

must be used directly.

AI Coding Assistant Rules

AI coding assistants must not:

Reuse the Atlas token system.
Generate a Tailwind-style color scale.
Introduce Emerald as a secondary Relvio brand scale.
Introduce Amber as a Relvio accent scale.
Generate a generic gray scale.
Assume a 4-pixel spacing system.
Force all spacing onto the Atlas spacing scale.
Use the Atlas typography scale without verification.
Use approximate line-height percentages without verification.
Use the Atlas radius scale automatically.
Use the Atlas opacity scale automatically.
Use the Atlas icon-size scale automatically.
Use the Atlas avatar-size scale automatically.
Use the Atlas button heights automatically.
Use the Atlas input heights automatically.
Build desktop, tablet, or large-desktop grid systems.
Add Atlas breakpoints.
Use 150ms, 250ms, and 400ms as approved motion values without verification.
Require hover states for all components.
Add dark mode.
Create dark equivalents for every token.
Generate a Material color scheme from a seed.
Replace approved UI values to fit a cleaner token scale.
Create tokens for hypothetical future features.
Scatter repeated raw design values across feature widgets.

When a required design value is unresolved, the AI coding assistant must:

Identify the screen and component.
Identify the unresolved property.
Check approved documentation and design sources.
Avoid presenting an estimate as approved.
Report the unresolved design value.
Continue unrelated implementation work where possible.
Token Review Checklist

Before adding a design token, verify:

Does the approved Relvio UI require this value?
Is the value exact and verified?
Is the value repeated or semantically important?
Does an existing token already represent the responsibility?
Is the token a foundation value or semantic responsibility?
Is the name clear?
Will centralization improve consistency?
Does the token preserve the approved UI?
Is the token being added for a real v1 requirement?
Is this token avoiding unnecessary future abstraction?

If the value is speculative, do not add the token.

Source of Truth Priority

For design token decisions:

Approved Relvio UI defines visual product intent.
Approved exact brand values define known immutable brand values.
Color System.md defines color governance and color meaning.
Design Tokens.md defines token extraction and centralized implementation rules.
Approved typography documentation defines typography requirements.
Component Library.md defines component reuse and ownership.
Design Principles.md defines product design judgment.
Asset_Structure.md and Brand Assets.md define asset responsibilities.
14_Engineering_Standards.md defines Flutter implementation standards.
Approved project structure documentation defines code placement.

The design token system must not override approved UI.

The design token system must not redefine product behavior.

If a genuine contradiction exists, implementation must stop at the affected design value and request clarification.

Success Criteria

The Relvio design token system is successful when:

Approved Relvio design values are centralized intentionally.
#2563FF remains the approved primary brand color.
#FCFCFD remains the approved primary application background.
Inter remains the approved Relvio typeface.
Shared components consume approved design foundations.
Feature widgets avoid duplicated raw design values.
The approved UI is not normalized into a generic token scale.
Unapproved Atlas color and spacing systems are not reused.
Desktop and web token infrastructure is not built for Relvio v1.
Dark mode is not invented.
Tokens grow from actual approved product needs.
Token names communicate clear responsibility.
AI coding assistants can implement design foundations without guessing or redesigning Relvio.