---
Document: Design Tokens
Version: 1.0
Status: Draft
Project: Atlas (Codename)
Owner: Design Team
---

# Design Tokens

## Purpose

This document defines the foundational design values used throughout Atlas.

Design tokens ensure consistency between design (Figma) and development (Flutter).

Every color, spacing value, typography style, radius, and shadow should come from this document.

---

# Philosophy

Atlas should feel:

- Modern
- Premium
- Calm
- Professional
- Spacious

The interface should never feel crowded.

---

# Color Palette

## Primary

```text
Primary 50
Primary 100
Primary 200
Primary 300
Primary 400
Primary 500
Primary 600
Primary 700
Primary 800
Primary 900
```

Usage

- Primary Buttons
- Active Navigation
- Links
- Highlights

---

## Secondary

Emerald Scale

```text
Secondary 50

↓

Secondary 900
```

Usage

- Success
- Growth
- Positive Indicators

---

## Accent

Amber Scale

Usage

- Warnings
- Pending Status
- Notifications

---

## Semantic Colors

### Success

```text
Success 500
```

---

### Warning

```text
Warning 500
```

---

### Error

```text
Error 500
```

---

### Info

```text
Info 500
```

---

# Neutral Colors

```text
Gray 50

↓

Gray 900
```

Usage

- Backgrounds
- Borders
- Cards
- Text
- Dividers

---

# Typography

Primary Font

Inter

Fallback

System Font

---

## Font Sizes

```text
12

14

16

18

20

24

30

36

48
```

---

## Font Weights

```text
400

500

600

700
```

---

## Line Heights

Use approximately:

120%

140%

160%

depending on content type.

---

# Spacing Scale

Base Unit

```
4px
```

Spacing Tokens

```
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
```

All spacing should use these values.

---

# Border Radius

```text
4

8

12

16

24

999 (Pill)
```

Usage

Cards

Buttons

Inputs

Dialogs

---

# Elevation

Atlas uses subtle elevation.

Levels

```
None

Low

Medium

High
```

Avoid heavy shadows.

---

# Border Width

```text
1px

2px
```

---

# Opacity

```text
5%

10%

20%

40%

60%

80%

100%
```

---

# Icon Sizes

```text
16

20

24

28

32

40

48
```

---

# Avatar Sizes

```text
32

40

48

64

80

96
```

---

# Button Heights

Small

```
36
```

Medium

```
44
```

Large

```
52
```

---

# Input Heights

Default

```
48
```

Large

```
56
```

---

# Card Sizes

Cards should use:

- Consistent padding
- Rounded corners
- Minimal shadows

---

# Grid

Desktop

12 Columns

Tablet

8 Columns

Mobile

4 Columns

---

# Breakpoints

Mobile

```
0–599
```

Tablet

```
600–1023
```

Desktop

```
1024–1439
```

Large Desktop

```
1440+
```

---

# Animation

Standard Duration

```
150ms
```

Normal

```
250ms
```

Slow

```
400ms
```

Animations should feel subtle and responsive.

---

# Motion Principles

Animations should:

- Guide attention
- Confirm actions
- Improve understanding

Never distract users.

---

# Component States

Every interactive component supports:

- Default
- Hover
- Pressed
- Focused
- Disabled
- Loading
- Error

---

# Accessibility

Maintain:

- Accessible color contrast
- Readable typography
- Visible focus indicators
- Touch targets of at least 44×44px

---

# Dark Mode

Every token must support:

- Light Theme
- Dark Theme

Never hardcode colors in components.

Always reference design tokens.

---

# Token Naming

Examples

```text
color.primary.500

color.success.500

spacing.16

radius.12

font.size.18

font.weight.600

shadow.medium
```

Developers should reference token names instead of raw values.

---

# Source of Truth

Figma is the design source of truth.

Flutter should mirror the same tokens through a centralized theme system.

---

# Success Criteria

The design token system is successful when:

- Every UI element uses defined tokens.
- Designers and developers use the same values.
- New themes can be added without redesigning components.
- Visual consistency is maintained across the product.

---

# End of Document