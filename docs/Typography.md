---
Document: Typography System
Version: 1.0
Status: Draft
Project: Atlas (Codename)
Owner: Design Team
---

# Typography System

## Purpose

This document defines the typography system used throughout Atlas.

Typography is one of the strongest contributors to usability, readability, and brand identity.

Every screen in Atlas should use these typography styles consistently.

---

# Design Philosophy

Typography should feel:

- Modern
- Professional
- Calm
- Spacious
- Easy to read

Users should never struggle to read information.

---

# Primary Typeface

## Inter

Inter is the primary typeface used throughout Atlas.

Reasons:

- Excellent readability
- Optimized for digital interfaces
- Large weight selection
- Open-source
- Supported across platforms

---

# Fallback Fonts

```
Inter

↓

SF Pro Display (Apple)

↓

Roboto (Android)

↓

Segoe UI (Windows)

↓

sans-serif
```

---

# Font Weights

Light

```
300
```

Regular

```
400
```

Medium

```
500
```

SemiBold

```
600
```

Bold

```
700
```

ExtraBold

```
800
```

Avoid using Light except for very large headings.

---

# Typography Scale

## Display Large

```
48px

Weight: 700

Line Height: 56px
```

Usage

Landing Pages

Hero Sections

---

## Display Medium

```
40px

Weight: 700

Line Height: 48px
```

---

## Display Small

```
32px

Weight: 700

Line Height: 40px
```

---

## Heading 1

```
30px

Weight: 700

Line Height: 38px
```

Used for page titles.

---

## Heading 2

```
24px

Weight: 700

Line Height: 32px
```

---

## Heading 3

```
20px

Weight: 600

Line Height: 28px
```

---

## Heading 4

```
18px

Weight: 600

Line Height: 26px
```

---

## Title

```
16px

Weight: 600

Line Height: 24px
```

Used for cards and sections.

---

## Body Large

```
16px

Weight: 400

Line Height: 26px
```

Default paragraph style.

---

## Body Medium

```
15px

Weight: 400

Line Height: 24px
```

---

## Body Small

```
14px

Weight: 400

Line Height: 22px
```

---

## Caption

```
12px

Weight: 400

Line Height: 18px
```

Used for timestamps and helper text.

---

## Label

```
13px

Weight: 500

Line Height: 18px
```

Buttons

Inputs

Badges

---

## Overline

```
11px

Weight: 600

Letter Spacing: 1px

Uppercase
```

---

# Button Typography

Primary Buttons

```
16px

Weight: 600
```

Secondary Buttons

```
15px

Weight: 600
```

Small Buttons

```
14px

Weight: 600
```

---

# Input Typography

Input Text

```
16px

Weight: 400
```

Label

```
14px

Weight: 500
```

Helper Text

```
12px

Weight: 400
```

Error Text

```
12px

Weight: 500
```

---

# Table Typography

Header

```
14px

Weight: 600
```

Rows

```
14px

Weight: 400
```

---

# Card Typography

Title

```
18px

Weight: 600
```

Description

```
14px

Weight: 400
```

Statistics

```
30px

Weight: 700
```

---

# Navigation Typography

Sidebar

```
14px

Weight: 500
```

Top Navigation

```
14px

Weight: 500
```

Bottom Navigation

```
12px

Weight: 500
```

---

# Line Height Rules

Use:

120%

for headings

140%

for UI elements

160%

for body text

This improves readability across all screen sizes.

---

# Letter Spacing

Default

```
0px
```

Large Headings

```
-0.5px
```

Overline

```
1px
```

Avoid excessive letter spacing.

---

# Text Alignment

Default

Left aligned

Exceptions

- Numbers in statistics
- Empty states
- Hero sections

Avoid justified text.

---

# Text Color Usage

Primary Text

Gray 900

Secondary Text

Gray 600

Muted Text

Gray 500

Disabled

Gray 400

Inverse

White

---

# Responsive Typography

Typography should scale gracefully.

Mobile

Smaller headings

Desktop

Larger headings

Body text should remain readable on every device.

---

# Accessibility

Maintain:

- Minimum 16px body text
- Sufficient color contrast
- Clear hierarchy
- Readable spacing

Avoid:

- Thin fonts
- Low contrast
- Long paragraphs
- Tiny text

---

# Typography Tokens

Examples

```
text.display.large

text.heading.1

text.heading.2

text.body.large

text.body.medium

text.body.small

text.caption

text.label
```

Flutter should reference these tokens instead of raw font sizes.

---

# Typography Principles

Typography should:

- Guide attention
- Create hierarchy
- Improve readability
- Support accessibility
- Reflect the Atlas brand

Good typography should feel invisible—it helps users focus on their work, not on the interface.

---

# Success Criteria

The typography system is successful when:

- Every screen follows the same hierarchy.
- Reading feels effortless.
- Designers and developers use the same text styles.
- The interface looks consistent across all platforms.

---

# End of Document