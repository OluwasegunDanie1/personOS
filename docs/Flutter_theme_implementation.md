---
Document: Flutter Theme Implementation
Version: 1.0
Status: Draft
Project: Atlas (Codename)
Owner: Engineering Team
---

# Flutter Theme Implementation

## Purpose

This document defines how the Atlas Design System will be implemented in Flutter.

The goal is to ensure that the Flutter application perfectly matches the Figma design system while remaining scalable and easy to maintain.

---

# Design Philosophy

The UI should never contain hardcoded:

- Colors
- Font Sizes
- Font Weights
- Border Radius
- Shadows
- Spacing

Everything should come from the theme.

---

# Architecture

The theme system should be centralized.

```
lib/

core/

theme/

├── app_theme.dart
├── app_colors.dart
├── app_text_theme.dart
├── app_spacing.dart
├── app_radius.dart
├── app_shadows.dart
├── app_icons.dart
├── app_extensions.dart
└── theme_extensions.dart
```

---

# Theme Entry Point

```
AppTheme.light()

AppTheme.dark()
```

No screen should create colors manually.

---

# Color System

Create strongly typed colors.

Example

```
AppColors.primary

AppColors.success

AppColors.warning

AppColors.error

AppColors.surface

AppColors.background

AppColors.border
```

Use semantic naming.

Never:

```
blueColor

greenColor

myColor
```

---

# Material ColorScheme

Atlas should use Flutter's ColorScheme.

Example

```
primary

secondary

surface

error

outline

onPrimary

onSurface
```

This improves compatibility with Material widgets.

---

# Typography

Create one centralized text theme.

```
AppTextTheme.light

AppTextTheme.dark
```

All text widgets should use:

```
Theme.of(context).textTheme
```

Avoid custom TextStyles inside screens.

---

# Spacing

Centralize spacing values.

```
AppSpacing.xs

AppSpacing.sm

AppSpacing.md

AppSpacing.lg

AppSpacing.xl

AppSpacing.xxl
```

Instead of

```
SizedBox(height: 17)
```

Use

```
SizedBox(height: AppSpacing.lg)
```

---

# Border Radius

```
AppRadius.small

AppRadius.medium

AppRadius.large

AppRadius.pill
```

Never hardcode

```
BorderRadius.circular(12)
```

---

# Shadows

Centralize shadows.

```
AppShadows.small

AppShadows.medium

AppShadows.large
```

---

# Icons

Create one wrapper.

```
AppIcons.add

AppIcons.edit

AppIcons.delete

AppIcons.search
```

This allows changing icon libraries later without touching the UI.

---

# Theme Extensions

Use ThemeExtension for custom values.

Examples

```
Status Colors

Chart Colors

Journey Colors

Avatar Colors
```

Avoid scattering custom colors across widgets.

---

# Component Styling

Buttons

↓

Theme

Cards

↓

Theme

Inputs

↓

Theme

Dialogs

↓

Theme

Bottom Sheets

↓

Theme

Navigation

↓

Theme

Widgets should inherit styling automatically.

---

# Light Theme

Optimized for:

- Daylight
- Offices
- General usage

Primary Background

White

Cards

White

Text

Dark Gray

---

# Dark Theme

Optimized for:

- Low-light environments
- Reduced eye strain

Background

Dark Slate

Surface

Dark Gray

Text

Light Gray

---

# Responsive Helpers

Create helpers for breakpoints.

```
Mobile

Tablet

Desktop

Large Desktop
```

UI should adapt using centralized utilities.

---

# Animation Constants

```
Fast

150ms

Medium

250ms

Slow

400ms
```

Reuse durations across the app.

---

# Input Decoration Theme

Centralize:

- Borders
- Radius
- Padding
- Error Style
- Hint Style
- Label Style

Every input should look identical.

---

# Button Theme

Create:

Primary Button

Secondary Button

Outlined Button

Text Button

Danger Button

Loading Button

Avoid styling buttons individually.

---

# Card Theme

Default card should include:

- Radius
- Background
- Elevation
- Padding

Cards should not define these repeatedly.

---

# Dialog Theme

Configure:

- Shape
- Padding
- Background
- Title Style
- Actions

---

# Navigation Theme

Configure:

Sidebar

Navigation Rail

Bottom Navigation

Top App Bar

Drawer

Navigation should remain visually consistent.

---

# Theme Switching

Support:

- Light Theme
- Dark Theme
- System Theme

Theme switching should happen instantly without restarting the app.

---

# Accessibility

Respect:

- System font scaling
- High contrast settings
- Reduced motion (future)
- Screen reader compatibility

---

# Theme Rules

Developers should never write:

```
Color(0xFF2563EB)

TextStyle(...)

EdgeInsets.all(16)

BorderRadius.circular(8)
```

Instead, always reference:

```
AppColors

AppSpacing

AppRadius

AppTextTheme

AppShadows
```

---

# Testing

Verify:

- Light Theme
- Dark Theme
- Theme Switching
- Responsive Layout
- Text Scaling
- Accessibility

---

# Future Expansion

The theme system should support:

- Organization Branding
- White Label Themes
- Seasonal Themes
- Enterprise Customization

Without modifying component code.

---

# Success Criteria

The Flutter theme implementation is successful when:

- Every UI element derives its styling from the centralized theme.
- No design values are hardcoded.
- Light and Dark themes remain visually consistent.
- Designers and developers share the same design language.
- Future branding changes require minimal code updates.

---

# Final Principle

The theme is the foundation of Atlas.

Build components once.

Style them through the theme.

Never through individual widgets.

---

# End of Document