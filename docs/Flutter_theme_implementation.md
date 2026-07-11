---
Document: Flutter Theme Implementation
Version: 1.1
Status: Approved
Project: Relvio
Owner: Engineering & Design
---

# Flutter Theme Implementation

## Purpose

This document defines how approved Relvio visual foundations are implemented and centralized in Flutter.

The theme implementation exists to connect:

- Approved Relvio UI
- Approved design values
- Flutter theme configuration
- Shared Flutter components
- Feature presentation code

Relvio v1 mobile UI is already approved and frozen.

This document does not define a new visual system.

It does not authorize Flutter defaults, Material-generated values, or AI coding assistants to redesign approved Relvio UI.

The Flutter theme implementation must preserve approved Relvio design intent while keeping repeated design responsibilities centralized and maintainable.

---

# Relvio v1 Context

Relvio v1 supports:

```text
Android
iOS


The approved frontend technology is:

Flutter

The approved state management technology is:

Riverpod

The approved routing technology is:

GoRouter

The approved primary brand color is:

#2563FF

The approved primary application background is:

#FCFCFD

The approved typeface is:

Inter

The approved Relvio v1 mobile UI is the visual implementation authority.

Theme Responsibility

The Flutter theme system should centralize approved repeated visual responsibilities.

These may include:

Colors
Typography
Shared component styling
Repeated surface treatment
Repeated input treatment
Repeated action treatment
Repeated navigation treatment

Additional design foundations such as:

Spacing
Radius
Shadows
Icon sizes
Motion

may use centralized Flutter constants or foundation structures where approved repeated values exist.

Not every design value must live directly inside ThemeData.

The theme system and design token system work together.

Design token governance is defined by:

Design Tokens.md
Core Implementation Principle

The implementation direction is:

Approved Relvio UI
        ↓
Verified Design Values
        ↓
Design Tokens
        ↓
Flutter Theme and Foundations
        ↓
Shared Components
        ↓
Feature UI

Do not use:

Generic Flutter Theme
        ↓
Generated Material Defaults
        ↓
Generic Components
        ↓
Force Relvio UI to Fit

Relvio design must drive theme implementation.

Flutter theme defaults must not redefine Relvio.

Theme and Token Boundary

The Flutter theme and design tokens have related but different responsibilities.

Conceptually:

Design Tokens
    ↓
Approved reusable design values

Flutter Theme
    ↓
Context-aware application styling and Material integration

Shared Components
    ↓
Approved reusable UI behavior and visual composition

Feature UI
    ↓
Approved product screens

A value does not need to be forced into ThemeData merely because it is centralized.

For example, repeated approved spacing may be represented through:

AppSpacing

while approved text styles may be integrated with:

TextTheme

The final implementation should use the simplest structure that preserves approved design responsibilities.

Code Placement

Theme implementation must follow the approved Relvio project structure.

Conceptually, shared visual foundations may live under an approved shared or core presentation location.

Possible files may include:

app_theme.dart
app_colors.dart
app_typography.dart
app_spacing.dart
app_radius.dart
app_shadows.dart
app_motion.dart

only where the approved project structure and actual token requirements justify them.

This document does not independently approve the exact directory:

lib/core/theme/

The final file placement must follow approved project structure documentation.

Do not create:

Empty token files
Empty theme classes
Placeholder design systems
Future theme infrastructure

merely to match this conceptual list.

Theme Entry Point

Relvio should have one clear approved application theme entry point for v1.

Conceptually:

AppTheme.light()

or an equivalent approved naming structure.

The exact Dart API should follow approved engineering conventions.

Relvio v1 does not require:

AppTheme.dark()

Dark mode is not an approved Relvio v1 requirement.

Do not create a dark theme implementation for future use.

Light Theme

Relvio v1 follows the approved light mobile UI.

Known approved values include:

Primary Brand Color: #2563FF
Primary Application Background: #FCFCFD
Typeface: Inter

The light theme must be built from verified Relvio design values.

Do not describe the Relvio background as generic:

White

when the approved primary application background is:

#FCFCFD

Approved surfaces, text colors, borders, and component treatments must come from verified Relvio UI and approved design documentation.

Do not use generic Material light theme values as final Relvio values where they conflict with the approved UI.

Dark Mode

Dark mode is not approved for Relvio v1.

Do not implement:

Dark Theme
System Theme Switching
Dark Theme Tokens
Dark Component Variants
Theme Preference Storage
Theme Toggle UI

Do not automatically map Relvio colors into dark equivalents.

If dark mode is approved in the future, it requires:

Product approval.
Approved dark UI designs.
Verified dark design tokens.
Theme implementation updates.
Component review.
Accessibility validation.
Relevant documentation updates.

The existence of Flutter theme support does not make dark mode part of Relvio.

Theme Mode

Relvio v1 should use the approved light theme.

Do not implement runtime switching between:

Light
Dark
System

unless theme switching becomes approved product scope.

Do not add Riverpod state for theme switching.

Do not add local persistence for theme preference.

Do not add a theme setting to Workspace or any other screen.

The approved frozen UI determines visible settings.

Color Implementation

Approved colors should be centralized.

Known approved values include:

brandPrimary = #2563FF
backgroundPrimary = #FCFCFD

Conceptually:

abstract final class AppColors {
  static const brandPrimary = Color(0xFF2563FF);
  static const backgroundPrimary = Color(0xFFFCFCFD);
}

This code is illustrative.

Final implementation must follow approved engineering conventions.

Additional color tokens must use verified approved values.

Possible semantic responsibilities may include:

brandPrimary
backgroundPrimary
surfacePrimary
textPrimary
textSecondary
textMuted
borderDefault
actionPrimary
stateSuccess
stateWarning
stateError
stateInfo

The existence of a semantic name does not approve a value.

Do not assign guessed values to complete AppColors.

Semantic Color Naming

Prefer names that communicate design responsibility.

Prefer:

brandPrimary
backgroundPrimary
textPrimary
borderDefault
stateError

Avoid:

blueColor
greenColor
gray1
myColor
mainBlue
niceBlue

Value-based or foundation names may still be appropriate for verified foundation tokens.

Semantic naming should not become artificial.

Do not create multiple names for the same responsibility without reason.

Color governance is defined by:

Color System.md
Design Tokens.md
Raw Colors

Repeated approved color values should not be scattered through feature widgets.

Avoid repeated code such as:

const Color(0xFF2563FF)

across multiple features.

Prefer:

AppColors.brandPrimary

where that token represents the approved responsibility.

A raw Color value is not universally forbidden in every implementation context.

If a verified design value is genuinely unique and does not justify a shared token, implementation may use the value locally where appropriate.

Do not create meaningless global tokens solely to eliminate every raw color literal.

Do not present an estimated local color as an approved Relvio value.

Flutter ColorScheme

Relvio may use Flutter's:

ColorScheme

to integrate approved Relvio colors with Material components.

Relevant roles may include:

primary
surface
error
outline
onPrimary
onSurface

only where those roles correctly represent approved Relvio design responsibilities.

Do not assume every ColorScheme role requires a unique Relvio token.

Do not use:

ColorScheme.fromSeed(...)

as the source of Relvio's final visual identity.

Generated Material colors are not approved Relvio colors.

The implementation must map verified Relvio colors intentionally.

Material Defaults

Flutter and Material defaults may provide behavior or base widget functionality.

They must not silently redefine approved Relvio appearance.

Review Material defaults that affect:

Color
Typography
Button shape
Button padding
Input borders
Input padding
Card treatment
Dialog shape
Bottom sheet shape
App bar appearance
Navigation appearance
Splash and interaction effects

Where a Material default conflicts with approved Relvio UI, configure or override it intentionally.

Do not replace approved UI with Material defaults for implementation convenience.

Typography Implementation

Relvio uses:

Inter

Typography should be centralized using verified approved text styles.

Flutter theme integration may use:

TextTheme

where appropriate.

Conceptually:

Theme.of(context).textTheme

may be used for approved semantic text roles.

A separate centralized typography structure may also be used where required by the approved design token architecture.

Possible semantic responsibilities may include:

heading
title
body
bodySecondary
label
caption

The final styles and names must come from verified Relvio UI patterns.

Do not recreate the old Atlas typography scale.

TextStyle Rules

Repeated approved typography combinations should not be rebuilt manually throughout feature screens.

Avoid repeated code such as:

TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
)

when an approved shared typography style already represents that responsibility.

Prefer the approved centralized style.

However:

TextStyle(...)

is not universally forbidden.

Flutter may require local composition or controlled modification of an approved style.

For example, implementation may derive from an approved style where a verified screen-specific requirement exists.

Do not create a global typography token for every one-off text treatment.

Do not use arbitrary local text styling to bypass the approved typography system.

Inter Font Assets

The Flutter project must use the approved Inter font assets or approved font delivery strategy defined by project asset and implementation decisions.

Font assets must follow:

Asset_Structure.md
Brand Assets.md

Do not silently substitute another typeface.

Do not add another font because a screen appears difficult to match.

Do not depend on an external font-loading service unless explicitly approved.

If required Inter font files are missing, report the missing approved asset.

Do not invent or substitute font assets.

Spacing Implementation

Repeated approved spacing values should be centralized according to:

Design Tokens.md

A possible Flutter structure is:

AppSpacing

The final token set must be extracted from approved Relvio UI.

Do not automatically create:

xs
sm
md
lg
xl
xxl

without mapping those names to verified approved values and responsibilities.

Do not reuse the old Atlas spacing scale automatically.

Raw Spacing Values

The following rule is not approved:

Every EdgeInsets or SizedBox value must use a global token.

Instead:

Reuse approved spacing tokens for repeated design values.
Preserve intentional unique layout values.
Avoid arbitrary repeated raw values.
Do not normalize approved spacing to fit a generic scale.

For example, if an approved layout genuinely requires:

const SizedBox(height: 18)

do not change it to 16 or 20 merely because those values exist in a spacing scale.

If 18 becomes a repeated approved foundation value, it may be centralized.

Tokenization should improve consistency without changing approved UI.

Radius Implementation

Repeated approved radius values should be centralized where useful.

A possible structure is:

AppRadius

Do not automatically create:

small
medium
large
pill

as the Relvio radius system.

The approved Relvio UI determines actual radius values and repeated responsibilities.

Do not forbid:

BorderRadius.circular(...)

universally.

Avoid repeating approved shared radius values manually when a centralized token exists.

A unique approved radius may remain component-specific.

Shadow Implementation

Shared approved shadow treatments may be centralized.

A possible structure is:

AppShadows

Do not automatically create:

small
medium
large

shadow levels.

Do not add shadows because a widget is a:

Card
Dialog
Bottom Sheet

The approved UI determines:

Whether a shadow exists
Shadow color
Opacity
Blur
Spread
Offset

Do not replace approved borders with Material elevation.

Do not add elevation to make Relvio appear more premium.

Icon Implementation

Icons must follow the approved Relvio icon approach.

A centralized icon reference structure may be used where it improves consistency.

Conceptually:

AppIcons.search
AppIcons.add
AppIcons.edit

This approach is optional.

Do not create a wrapper for every icon merely to prepare for a hypothetical future icon-library replacement.

A centralized icon reference is most useful when:

The same product action must use a consistent icon.
An approved custom icon asset exists.
Icon mapping communicates product responsibility.

Do not invent icon aliases for unused future actions.

Icon asset rules are governed by:

Asset_Structure.md
Figma Design System.md
Component Library.md
Icon Source

Use the approved icon source or approved vector asset strategy.

Do not:

Mix unrelated icon styles
Recreate icons from screenshots
Export standard interface icons as raster images without need
Replace approved icons with visually similar icons silently

If the approved icon source has not been documented and exact icon selection cannot be verified, report the missing design decision.

Do not claim an estimated icon is approved.

ThemeExtension

Flutter:

ThemeExtension

may be used when Relvio has custom theme values that are genuinely:

Context-dependent
Repeated
Theme-related
Not represented appropriately by standard ThemeData

Do not create ThemeExtensions simply because Flutter supports them.

Do not automatically create extensions for:

Status Colors
Chart Colors
Journey Colors
Avatar Colors

The old Atlas extension examples are not approved Relvio requirements.

Create a ThemeExtension only when actual approved Relvio implementation requires it.

Status Colors

Status presentation must follow approved product and color meaning.

Do not create a generic status-color extension without reviewing actual approved statuses.

Status color is not a substitute for domain state.

The backend remains authoritative for protected domain state.

The UI may represent an approved state visually.

It must not derive or invent authoritative domain state from color.

Color must not be the only critical status indicator.

Component Theme Strategy

Flutter component themes may be used for repeated approved visual treatment.

Relevant Material theme configuration may include:

ElevatedButtonThemeData
TextButtonThemeData
OutlinedButtonThemeData
InputDecorationTheme
CardTheme
DialogThemeData
BottomSheetThemeData
AppBarTheme
NavigationBarThemeData

only where the approved Relvio UI uses the corresponding widget responsibility and theme-level configuration improves consistency.

Do not configure every available Flutter component theme in advance.

The component theme system should grow from approved Relvio components.

Shared Component Strategy

Not every approved visual requirement can or should be represented only through ThemeData.

Relvio may use shared Flutter components for approved repeated UI patterns.

Conceptually:

Theme and Tokens
        ↓
Shared Component
        ↓
Feature UI

For example, an approved Relvio button may require:

Specific loading behavior
Approved content layout
Icon handling
Disabled behavior

that is better represented by a shared component using approved theme values.

Component responsibility is governed by:

Component Library.md

Do not force all component behavior into theme configuration.

Buttons

Approved Relvio button patterns should use centralized styling and shared components where appropriate.

The actual button set must come from approved Relvio UI.

Do not automatically create:

Primary Button
Secondary Button
Outlined Button
Text Button
Danger Button
Loading Button

as mandatory global component types.

Where an approved shared button responsibility exists, centralize:

Typography
Color responsibility
Shape
Padding
Height where verified
State treatment

Loading behavior belongs to the component when the component requires it.

A loading button is not necessarily a separate visual button type.

Button States

Button states should reflect actual approved interaction behavior.

Relevant states may include:

Default
Pressed
Disabled
Loading

where required.

Do not add hover as a universal mobile button state.

Do not show success state before an authoritative operation has succeeded.

For critical mutations, button loading behavior should help prevent accidental repeated submission while the request is in progress.

UI safeguards do not replace backend integrity controls.

Attendance still requires backend idempotency.

Input Decoration

Approved repeated input appearance may be centralized using:

InputDecorationTheme

and shared input components where appropriate.

Relevant approved values may include:

Border treatment
Focused border treatment
Error treatment
Radius
Content padding
Hint typography
Label typography

The exact values must come from approved Relvio UI.

Do not assume every input should look identical.

Different input responsibilities may require different approved patterns.

Reuse shared treatment where responsibility matches.

Input Validation State

Input error styling must represent actual validation behavior.

The Flutter client may provide user-friendly validation feedback.

The backend remains authoritative for protected business validation.

Do not assume client validation replaces backend validation.

Do not expose raw backend or database errors directly in input UI.

Security and validation requirements are governed by:

13_API_Specification.md
16_Security.md
Cards and Surfaces

Do not define one universal card appearance unless the approved Relvio UI demonstrates a genuinely shared card responsibility.

A global CardTheme may be used where appropriate.

Feature surfaces may also use approved shared foundation tokens directly.

Do not assume every card has:

Background
Radius
Elevation
Padding

from one universal theme.

Padding is often layout responsibility rather than Material CardTheme responsibility.

Do not add elevation automatically.

Approved Relvio surfaces may use:

Background difference
Border
Radius
Shadow
Spacing

in different combinations.

The approved UI determines the treatment.

Dialog Theme

Approved repeated dialog appearance may use Flutter dialog theme configuration.

Relevant responsibilities may include:

Background
Shape
Surface treatment

Dialog content structure and action hierarchy may remain in approved shared components.

Do not create separate theme systems for:

Delete Dialog
Warning Dialog
Success Dialog
Information Dialog

unless the approved UI defines genuinely different visual structures.

Semantic meaning alone does not require a separate dialog theme.

Bottom Sheet Theme

Approved repeated bottom-sheet appearance may use:

BottomSheetThemeData

where appropriate.

Theme configuration may centralize verified visual treatment.

Bottom-sheet content and behavior remain component or feature responsibilities.

Do not create bottom sheets for unapproved interactions.

Theme availability does not create product capability.

Navigation Theme

Relvio v1 uses the approved mobile navigation design.

The final primary bottom navigation label is:

Workspace

not:

More

Theme implementation should support the approved mobile navigation appearance.

Relevant Flutter theme configuration may include:

NavigationBarThemeData

or another implementation approach that accurately reproduces the approved UI.

Do not create v1 theme systems for:

Sidebar
Navigation Rail
Drawer
Desktop Top Navigation
Breadcrumbs

unless future product scope explicitly approves those experiences.

GoRouter governs routing.

Theme configuration does not define navigation architecture.

App Bar Theme

Shared app bar styling may be centralized where approved Relvio screens use a repeated app bar treatment.

Do not force every screen to use one universal app bar.

Some approved screens may require:

No app bar
Feature-specific header
Custom navigation treatment

The approved UI determines screen structure.

Use theme-level configuration where it improves consistency without changing approved layouts.

Responsive Helpers

Do not create the old Atlas breakpoint helpers:

Mobile
Tablet
Desktop
Large Desktop

Relvio v1 supports Android and iOS mobile experiences.

Flutter implementation should adapt appropriately to supported mobile screen dimensions.

Relevant implementation concerns include:

Available width
Available height
Safe areas
System insets
Keyboard visibility
Scrollable content
Text scaling

Do not build desktop or web responsive infrastructure for Relvio v1.

Where an approved mobile screen requires a specific adaptation rule, implement the smallest required helper or layout behavior.

Screen Size Rules

Do not use one fixed Figma frame size as the runtime application size.

Avoid implementing screens through absolute X and Y coordinates copied from design references.

Flutter layout should preserve approved visual relationships using appropriate widgets and constraints.

Possible Flutter layout tools may include:

SafeArea
LayoutBuilder
MediaQuery
Expanded
Flexible
ConstrainedBox
SingleChildScrollView

only where appropriate.

This list is not a mandatory widget architecture.

Use the simplest layout that accurately reproduces approved mobile behavior.

Motion Implementation

Animations, shimmer, skeletons, loading states, empty states, error states, and micro-interactions may be implemented during Flutter coding where appropriate.

Motion should follow:

Design Principles.md
Design Tokens.md

Repeated approved motion values may be centralized.

A possible structure is:

AppMotion

Do not automatically define:

Fast = 150ms
Medium = 250ms
Slow = 400ms

The old Atlas durations are not approved Relvio motion values.

Verify motion requirements before centralizing values.

Animation Rules

Relvio motion should be:

Subtle
Responsive
Purposeful
Non-blocking

Animation may support:

Pressed feedback
Selection
State transition
Navigation continuity
Loading presentation
Completion feedback

Animation must not:

Delay user progress unnecessarily
Hide request failure
Imply false success
Fabricate authoritative data state
Distract from core work

Simple animations should be implemented directly in Flutter where appropriate.

Do not add Lottie or Rive by default.

Reduced Motion

Dedicated reduced-motion product behavior is not currently defined as a Relvio v1 feature.

Do not create a speculative reduced-motion settings system.

When implementing motion:

Avoid excessive motion.
Avoid unnecessarily long animations.
Avoid motion required to understand critical state.
Prefer simple transitions.

If explicit reduced-motion support becomes an approved requirement, update:

Product requirements
Design behavior
Motion tokens
Flutter implementation
Testing documentation

Do not claim complete reduced-motion support without approved behavior and verification.

Accessibility

Theme implementation should support accessible Flutter UI.

Relevant responsibilities include:

Readable typography
Sufficient contrast
Meaning beyond color
Appropriate touch interaction
Clear component states
Meaningful semantics where required

The theme alone does not provide complete accessibility.

Shared components and feature screens remain responsible for correct semantics and interaction behavior.

Accessibility principles are governed by:

Design Principles.md
Color System.md
Component Library.md
Text Scaling

Flutter implementation should be evaluated with supported text scaling behavior.

Do not globally disable text scaling merely to preserve screenshot-perfect layout.

Do not silently redesign the approved UI when scaling reveals a genuine layout problem.

If a critical approved screen fails under reasonable supported text scaling:

Identify the affected screen.
Identify the failing component.
Determine whether the issue is implementation or design.
Correct implementation issues.
Return genuine design conflicts for intentional review.

Avoid clipping important text.

Avoid hiding critical actions solely to preserve fixed visual height.

High Contrast

A dedicated high-contrast theme is not an approved Relvio v1 requirement.

Do not create:

High Contrast Theme
High Contrast Toggle
High Contrast Token Map

without product and design approval.

The approved light theme must still follow approved contrast requirements.

Color governance is defined by:

Color System.md
Screen Reader Compatibility

Screen reader compatibility is not implemented by theme values alone.

Shared components and feature UI should provide meaningful Flutter semantics where required.

Do not assume visible text automatically provides complete semantics for:

Icon-only actions
Custom controls
Status indicators
Complex interactive components

Theme implementation should not remove or interfere with semantic behavior.

Accessibility testing is governed by:

15_Testing_Strategy.md
Hardcoded Value Rules

The following absolute rule is not approved:

No design value may ever appear directly inside a widget.

Instead, use these rules:

Repeated approved design values should use centralized tokens or theme responsibilities.
Shared component styling should be centralized.
Feature widgets should not duplicate known shared design values.
Unique approved layout values may remain local where appropriate.
Do not create meaningless tokens for every numeric literal.
Do not replace approved values merely to fit an existing token scale.
Do not present guessed values as approved.

The goal is controlled consistency.

The goal is not zero numeric literals.

Theme Access

Flutter code should access approved theme values through the simplest clear mechanism.

Possible approaches include:

Theme.of(context)

centralized token classes, or approved convenience extensions.

Do not create extension methods solely to reduce a small number of characters.

A convenience extension may be useful when it:

Is repeated frequently
Improves readability
Preserves clear type responsibility

Do not create a large BuildContext extension API that hides where values come from.

Theme access should remain understandable to future engineers and AI coding assistants.

Theme Extensions File

Do not automatically create both:

app_extensions.dart
theme_extensions.dart

The old Atlas folder structure risks duplicate responsibility.

Create extension files only when actual approved implementation requires them.

Avoid multiple extension layers that expose the same theme values through different APIs.

There should be one clear way to access each design responsibility where practical.

Theme Testing

Theme implementation should be tested according to actual risk and approved behavior.

Relevant verification may include:

Approved light theme application
Primary brand color
Primary background
Inter typography
Shared component appearance
Navigation appearance
Input appearance
Text scaling behavior
Important accessibility behavior

Do not create dark-theme or theme-switching tests when those features are not approved.

Visual verification against approved UI is important.

Testing priorities are governed by:

15_Testing_Strategy.md
Visual Verification

Flutter implementation should be compared against approved Relvio UI.

Review relevant visual properties such as:

Layout
Spacing
Typography
Color
Radius
Border treatment
Shadow treatment
Icon treatment
Component states

Do not use screenshot similarity as the only correctness measure.

A screen may appear visually similar while having incorrect:

Loading behavior
Navigation behavior
Permission behavior
Data state
Accessibility behavior

Visual fidelity and functional correctness are both required.

Screenshot References

Approved UI screenshots are design references.

They are not production UI assets.

Do not:

Place full screenshots inside Flutter screens
Crop buttons from screenshots
Crop cards from screenshots
Crop text from screenshots
Crop standard icons from screenshots
Recreate the Relvio logo from screenshot pixels

Flutter must implement UI as widgets.

Approved brand assets must be used directly.

Asset rules are governed by:

Asset_Structure.md
Brand Assets.md
Theme Changes

Changing a shared theme value may affect multiple components and screens.

Before changing an approved theme value:

Identify the design responsibility.
Confirm the current value.
Confirm the design change is approved.
Identify affected shared components.
Identify affected screens.
Update the centralized value.
Verify affected UI.

Do not change a global theme value to fix one screen when the shared value is correct elsewhere.

The affected screen may require an approved feature-specific treatment.

Component Overrides

A component may require an approved visual treatment different from the shared default.

Local or component-specific overrides are allowed when:

The approved UI requires the difference.
The responsibility is genuinely different.
The override does not duplicate an existing approved shared variant.

Do not treat every override as a design-system failure.

Do not use overrides casually to bypass approved shared styling.

If the same override repeats across multiple responsibilities, review whether a shared token, theme value, or component variant is missing.

Theme Growth

The Relvio theme system should grow from approved product needs.

Do not prebuild support for:

Organization branding
White-label themes
Seasonal themes
Enterprise customization
Dark mode
Desktop themes
Web themes

These are not approved Relvio v1 theme requirements.

Future approved design capabilities may extend the theme system intentionally.

Do not build speculative theme architecture merely to make future changes theoretically easier.

Organization Branding

Custom organization branding is not approved for Relvio v1.

Do not allow organizations to override:

Relvio primary color
Application background
Typography
Navigation styling
Shared component styling

unless future product scope explicitly approves organization branding.

Organization data must not control arbitrary Flutter theme values.

This avoids unapproved visual behavior and future security or validation complexity.

White-Label Themes

White-label capability is not approved.

Do not create:

WhiteLabelTheme
OrganizationTheme
TenantTheme
DynamicBrandTheme

for Relvio v1.

Relvio is the public product brand.

Approved Relvio brand assets and design values must be used.

Future white-label capability requires explicit product, brand, architecture, and design decisions.

AI Coding Assistant Rules

AI coding assistants must not:

Reuse the Atlas theme system.
Create a dark theme.
Create system theme switching.
Add a theme toggle.
Add Riverpod theme state.
Add theme preference persistence.
Generate colors from ColorScheme.fromSeed.
Replace #2563FF.
Replace #FCFCFD.
Replace Inter.
Create a generic Tailwind-style color scale.
Create generic xs, sm, md, lg, xl, and xxl spacing without verified values.
Force every spacing value into a global token.
Create generic small, medium, and large radius scales without verification.
Create generic small, medium, and large shadow scales.
Add status, chart, journey, or avatar ThemeExtensions without approved need.
Add desktop breakpoints.
Add tablet product layouts.
Add web responsive helpers.
Add sidebar themes.
Add navigation rail themes.
Add drawer themes for hypothetical navigation.
Use 150ms, 250ms, and 400ms as approved motion values without verification.
Add organization branding infrastructure.
Add white-label theme infrastructure.
Add seasonal themes.
Add enterprise theme customization.
Export approved screens as production UI images.
Recreate the Relvio logo.
Change Workspace to More.
Use theme architecture to redesign frozen UI.

When a required theme value is unresolved, the AI coding assistant must:

Identify the affected screen.
Identify the affected component.
Identify the unresolved design property.
Check approved UI and documentation.
Check existing approved Relvio tokens and patterns.
Avoid presenting an estimate as approved.
Report the unresolved value.
Continue unrelated implementation work where possible.

The AI coding assistant is an implementation engineer.

Approved Relvio design defines the visual system.

Theme Implementation Sequence

When Flutter foundation implementation begins, the recommended sequence is:

Review Approved Relvio UI
        ↓
Verify Known Brand Values
        ↓
Extract Repeated Design Values
        ↓
Create Minimal Design Tokens
        ↓
Configure Approved Light Theme
        ↓
Integrate Inter
        ↓
Map Approved Material Theme Roles
        ↓
Build Required Shared Components
        ↓
Implement Approved Screens
        ↓
Verify Visual and Interaction Fidelity
        ↓
Add Missing Tokens Only When Approved Need Appears

Do not begin by generating every possible theme class.

Do not begin by building dark mode.

Do not begin by creating a generic design system.

Theme Review Checklist

Before approving Flutter theme implementation, verify:

Is the implementation based on approved Relvio UI?
Is #2563FF preserved as the approved primary brand color?
Is #FCFCFD preserved as the approved primary application background?
Is Inter configured correctly?
Is only the approved light theme implemented?
Are repeated approved colors centralized?
Are repeated approved typography styles centralized?
Are repeated approved design values tokenized intentionally?
Are Material defaults reviewed?
Is ColorScheme.fromSeed avoided as visual authority?
Are speculative token scales avoided?
Are desktop and web theme systems absent?
Is dark mode absent?
Is theme switching absent?
Is organization branding infrastructure absent?
Is white-label infrastructure absent?
Do shared components use approved theme responsibilities?
Are unique approved values preserved where appropriate?
Are unresolved design values reported rather than invented?
Does mobile layout remain compatible with supported Android and iOS screens?
Does Workspace remain the approved navigation label?
Source of Truth Priority

For Flutter theme implementation:

Approved Relvio product decisions define product scope.
Approved active Relvio UI defines frozen visual and interaction intent.
Color System.md defines color governance.
Design Tokens.md defines token extraction and centralization.
Flutter Theme Implementation.md defines Flutter theme implementation rules.
Figma Design System.md defines approved design organization and handoff.
Component Library.md defines component responsibility and reuse.
Design Principles.md defines product design judgment.
19_Brand_Identity.md defines Relvio brand character.
Brand Assets.md defines approved brand asset governance.
Asset_Structure.md defines production Flutter asset organization.
14_Engineering_Standards.md defines engineering implementation standards.
Approved project structure documentation defines final code placement.

Flutter theme implementation must not override:

Product scope
Backend architecture
API contracts
Security requirements
Organization isolation
Attendance integrity
Journey history rules

If a genuine contradiction exists, implementation must stop at the affected decision and request clarification.

Success Criteria

The Relvio Flutter theme implementation is successful when:

The approved frozen Relvio UI drives theme implementation.
Android and iOS remain the supported v1 UI targets.
#2563FF remains the approved primary brand color.
#FCFCFD remains the approved primary application background.
Inter remains the approved typeface.
Approved repeated design values are centralized intentionally.
Flutter Material integration uses verified Relvio values.
Material defaults do not silently redefine Relvio.
Shared components use consistent approved visual foundations.
Feature widgets do not duplicate known shared design responsibilities unnecessarily.
Unique approved values are not changed merely to fit a generic scale.
Dark mode is not invented.
Theme switching is not invented.
Desktop and web theme infrastructure is not built.
Organization branding and white-label infrastructure are not built prematurely.
The theme system grows from actual approved Relvio UI.
AI coding assistants can implement the theme without inventing design values or redesigning Relvio.
Final Principle

The Flutter theme is an implementation of approved Relvio design.

It is not a design generator.

Build the smallest centralized theme system required to reproduce Relvio accurately, consistently, and maintainably.