---
Document: Figma Design System
Version: 1.0
Status: Draft
Project: Atlas (Codename)
Owner: Design Team
---

# Figma Design System

## Purpose

This document defines how the Atlas Design System is organized inside Figma.

The goal is to ensure every designer and developer works from a single source of truth.

The design system should be scalable, reusable, and easy to maintain.

---

# Design Philosophy

Every UI element should come from reusable components.

Never redesign the same element twice.

Design once.

Reuse everywhere.

---

# Figma File Structure

```
📁 Atlas Design System

├── Cover
├── Foundations
├── Tokens
├── Components
├── Patterns
├── Templates
├── Screens
├── Prototype
└── Archive
```

---

# Cover Page

Contains

- Logo
- Version
- Last Updated
- Design Team
- Links to Documentation

---

# Foundations

Contains the visual foundations.

Pages

```
Colors

Typography

Spacing

Elevation

Border Radius

Grid

Icons

Illustrations

Motion
```

---

# Color Styles

Create color styles for:

```
Primary

Secondary

Success

Warning

Danger

Info

Gray

Background

Surface

Border
```

Never use raw HEX values inside screens.

---

# Typography Styles

Create reusable text styles.

```
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
```

---

# Effects

Create reusable effects.

Examples

```
Shadow Small

Shadow Medium

Shadow Large

Blur

Overlay
```

---

# Grid Styles

Desktop

```
12 Columns
```

Tablet

```
8 Columns
```

Mobile

```
4 Columns
```

---

# Component Organization

```
Components

├── Buttons
├── Inputs
├── Navigation
├── Cards
├── Tables
├── Dialogs
├── Menus
├── Chips
├── Badges
├── Avatars
├── Lists
├── Empty States
├── Loading
├── Charts
└── Misc
```

---

# Button Variants

Primary

Secondary

Outlined

Text

Danger

Icon

Floating Action Button

Each button should include:

- Default
- Hover
- Pressed
- Focus
- Disabled
- Loading

---

# Input Components

Create variants for:

```
Text Field

Password

Search

Dropdown

Date Picker

Text Area

Checkbox

Radio

Switch
```

States

- Default
- Focus
- Error
- Disabled

---

# Navigation Components

Sidebar

Top Navigation

Bottom Navigation

Tabs

Breadcrumb

Pagination

---

# Card Components

Statistic Card

Profile Card

Event Card

Attendance Card

Follow-up Card

Report Card

Cards should support:

- Default
- Hover
- Selected

---

# Feedback Components

Snackbar

Toast

Alert

Progress

Skeleton Loader

Error State

Empty State

---

# Dialog Components

Confirmation

Delete

Information

Warning

Success

Bottom Sheet

---

# Tables

Create reusable tables with:

Sorting

Filtering

Pagination

Bulk Actions

Empty State

Loading State

---

# Charts

Prepare reusable chart templates.

Examples

Bar Chart

Pie Chart

Area Chart

Line Chart

KPI Card

---

# Layout Templates

Desktop Dashboard

Tablet Dashboard

Mobile Dashboard

Form Layout

Settings Layout

Profile Layout

Authentication Layout

---

# Screen Library

Create high-fidelity screens for:

Authentication

Dashboard

People

Person Profile

Journey

Events

Attendance

Follow-ups

Reports

Notifications

Settings

Organization

---

# Auto Layout Rules

Every component should use Auto Layout.

Benefits

- Easier resizing
- Responsive behavior
- Faster updates
- Cleaner developer handoff

Avoid manual positioning whenever possible.

---

# Constraints

Configure proper constraints for:

Desktop

Tablet

Mobile

Components should resize predictably.

---

# Naming Convention

Use consistent names.

Examples

```
Button / Primary

Button / Secondary

Input / Search

Card / Person

Dialog / Delete

Avatar / Medium
```

Avoid generic names.

---

# Component Properties

Use properties for:

Size

State

Icon

Loading

Disabled

Selected

This minimizes duplicate components.

---

# Prototyping

Prototype the following flows:

- Login
- Create Organization
- Dashboard
- Add Person
- Create Event
- Record Attendance
- Create Follow-up
- Reports
- Settings

The prototype should simulate the real product.

---

# Developer Handoff

Every screen should include:

- Measurements
- Spacing
- Typography
- Color Styles
- Component Names

Developers should never guess values.

---

# Versioning

Update the design system whenever:

- A new component is added.
- A component changes.
- Tokens are updated.
- A design decision changes.

Maintain a simple changelog.

---

# Documentation

Each component should document:

- Purpose
- Usage
- Variants
- Properties
- Accessibility
- Do's
- Don'ts

---

# Quality Checklist

Before publishing updates:

- Components use Auto Layout.
- Tokens are applied correctly.
- Naming is consistent.
- No duplicate components.
- Accessibility is considered.
- Responsive behavior is verified.

---

# Success Criteria

The Figma Design System is successful when:

- Every screen is built using reusable components.
- Designers work faster with fewer inconsistencies.
- Developers can implement designs without ambiguity.
- New features can be designed without recreating existing elements.
- Atlas maintains a consistent visual identity across every platform.

---

# End of Document