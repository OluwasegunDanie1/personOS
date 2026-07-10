---
Document: Spacing System
Version: 1.0
Status: Draft
Project: Atlas (Codename)
Owner: Design Team
---

# Spacing System

## Purpose

This document defines the spacing system used throughout Atlas.

Consistent spacing creates rhythm, improves readability, and makes the interface feel professional.

Every margin, padding, and gap should use this spacing scale.

---

# Philosophy

Whitespace is not empty space.

Whitespace improves:

- Readability
- Focus
- Organization
- User Experience

Never add spacing randomly.

Every space should have a purpose.

---

# Base Unit

Atlas uses an **8px Grid System**.

Every spacing value should be a multiple of 8 whenever possible.

Small adjustments may use 4px.

---

# Spacing Scale

| Token | Value |
|--------|------:|
| xs | 4px |
| sm | 8px |
| md | 16px |
| lg | 24px |
| xl | 32px |
| 2xl | 40px |
| 3xl | 48px |
| 4xl | 64px |
| 5xl | 80px |
| 6xl | 96px |

---

# Padding

## Cards

```
24px
```

---

## Dialogs

```
24px
```

---

## Forms

```
24px
```

---

## Side Panels

```
32px
```

---

## Mobile Screens

Horizontal

```
16px
```

Vertical

```
24px
```

---

# Margins

Between Sections

```
48px
```

---

Between Cards

```
24px
```

---

Between Inputs

```
16px
```

---

Between Labels and Inputs

```
8px
```

---

Between Buttons

```
16px
```

---

Between Icons and Text

```
8px
```

---

# Layout Spacing

## Desktop

Outer Margin

```
32px
```

Content Gap

```
32px
```

Sidebar Gap

```
24px
```

---

## Tablet

Outer Margin

```
24px
```

Content Gap

```
24px
```

---

## Mobile

Outer Margin

```
16px
```

Content Gap

```
16px
```

---

# Grid System

Desktop

```
12 Columns
```

---

Tablet

```
8 Columns
```

---

Mobile

```
4 Columns
```

---

# Component Spacing

## Button

Horizontal Padding

```
24px
```

Vertical Padding

```
12px
```

---

## Input Field

Horizontal

```
16px
```

Vertical

```
12px
```

---

## Card

Internal Padding

```
24px
```

Gap Between Elements

```
16px
```

---

## Table

Row Height

```
56px
```

Cell Padding

```
16px
```

---

# Avatar Spacing

Avatar to Text

```
12px
```

Avatar to Avatar

```
8px
```

---

# List Items

Vertical Padding

```
16px
```

Gap Between Items

```
8px
```

---

# Navigation

Sidebar Item Height

```
48px
```

Sidebar Padding

```
16px
```

Navigation Icon Gap

```
12px
```

---

# Dashboard

Gap Between Widgets

```
24px
```

Section Spacing

```
40px
```

---

# Forms

Form Header

↓

```
24px
```

Input

↓

```
16px
```

Section

↓

```
32px
```

Submit Button

---

# Dialog Layout

```
Title

↓

16px

↓

Content

↓

24px

↓

Buttons
```

---

# Empty States

Illustration

↓

```
24px
```

↓

Title

↓

```
12px
```

↓

Description

↓

```
24px
```

↓

Action Button

---

# Responsive Rules

Spacing should reduce naturally on smaller devices.

Desktop

More breathing room.

Tablet

Moderate spacing.

Mobile

Compact without feeling cramped.

---

# Spacing Principles

Always use the spacing scale.

Never use arbitrary values like:

```
13px

19px

27px

35px
```

Consistency is more important than precision.

---

# Design Tokens

Examples

```
spacing.xs

spacing.sm

spacing.md

spacing.lg

spacing.xl

spacing.2xl

spacing.3xl
```

Developers should reference tokens instead of raw pixel values.

---

# Accessibility

Maintain enough spacing to ensure:

- Easy touch interactions
- Readable layouts
- Clear grouping
- Comfortable scanning

Touch targets should never be smaller than **44 × 44px**.

---

# Success Criteria

The spacing system is successful when:

- Every screen feels balanced.
- Related elements are visually grouped.
- Users can scan information quickly.
- Designers and developers use the same spacing values.
- The interface remains consistent across all devices.

---

# End of Document