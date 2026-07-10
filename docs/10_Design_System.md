---
Document: Design System
Version: 0.1
Status: Draft
Project: Atlas (Codename)
Owner: Product Team
---

# Design System

## Purpose

This document defines the visual language of Atlas.

The goal is to build a clean, modern, and consistent interface that feels familiar from the first click.

---

# Design Principles

Every screen should be:

- Simple
- Clean
- Fast
- Consistent
- Accessible

If something can be made simpler, simplify it.

---

# Design Style

Atlas should have a modern SaaS look.

Inspired by products like:

- Linear
- Notion
- Stripe Dashboard
- Vercel
- Slack

Avoid clutter.

Whitespace is part of the design.

---

# Brand Personality

Atlas should feel:

- Professional
- Friendly
- Trustworthy
- Calm
- Modern

Never overwhelming.

---

# Color Palette

## Primary

Used for buttons, links and active states.

```
Primary Blue

#2563EB
```

---

## Success

```
#22C55E
```

---

## Warning

```
#F59E0B
```

---

## Error

```
#EF4444
```

---

## Background

```
#FFFFFF
```

Dark Mode

```
#0F172A
```

---

## Neutral Colors

```
Gray 50
Gray 100
Gray 200
Gray 300
Gray 400
Gray 500
Gray 600
Gray 700
Gray 800
Gray 900
```

---

# Typography

Use one font across the application.

Recommended:

- Inter

Fallbacks:

- System UI
- Roboto
- Segoe UI

---

# Font Sizes

| Element | Size |
|----------|------|
| Page Title | 32px |
| Section Title | 24px |
| Card Title | 20px |
| Body | 16px |
| Small Text | 14px |
| Caption | 12px |

---

# Border Radius

Small

```
8px
```

Medium

```
12px
```

Large

```
16px
```

Cards should have soft rounded corners.

---

# Spacing

Use an 8-point spacing system.

Examples:

```
4px

8px

16px

24px

32px

48px

64px
```

Avoid random spacing values.

---

# Shadows

Use subtle shadows only.

Cards should appear elevated without looking heavy.

Avoid large dark shadows.

---

# Buttons

## Primary Button

Used for the main action.

Examples:

- Save
- Create
- Continue

---

## Secondary Button

Used for less important actions.

Examples:

- Cancel
- Back
- Close

---

## Danger Button

Used carefully.

Examples:

- Delete
- Remove
- Archive

---

# Form Inputs

Every input should include:

- Label
- Placeholder
- Validation message
- Helper text (optional)

Example

```
Full Name

[________________]

Enter the person's full name.
```

---

# Icons

Use one icon library across the project.

Recommended:

Lucide Icons

Icons should always support text.

Avoid icon-only navigation where possible.

---

# Cards

Cards should contain:

- Title
- Content
- Optional actions

Example:

```
Attendance Today

245 Present

View Details →
```

---

# Tables

Tables should support:

- Search
- Sort
- Filter
- Pagination
- Bulk Actions

---

# Empty States

Every empty page should explain:

- Why nothing is shown
- What the user should do next

Example

```
No Events Yet

Create your first event to start tracking attendance.

[ Create Event ]
```

---

# Loading States

Use skeleton loaders instead of spinning loaders whenever possible.

Users should know where content will appear.

---

# Error States

Errors should explain:

- What happened
- Why
- What the user can do next

Avoid technical error messages.

---

# Notifications

Use toast notifications for:

- Success
- Warning
- Error
- Information

Keep messages short.

Example:

✓ Person added successfully.

---

# Modals

Use modals only when necessary.

Good examples:

- Delete confirmation
- Edit details
- Invite team member

Avoid putting long forms inside modals.

---

# Accessibility

Atlas should support:

- Keyboard navigation
- Screen readers
- High contrast
- Clear focus indicators
- Readable font sizes

Accessibility is required, not optional.

---

# Responsive Design

Atlas should work well on:

- Mobile
- Tablet
- Laptop
- Desktop

Design mobile-first whenever possible.

---

# Dark Mode

Support both:

- Light Mode
- Dark Mode

The experience should feel identical in both.

---

# Component Library

Reusable components include:

- Button
- Input
- Textarea
- Select
- Checkbox
- Radio Button
- Badge
- Avatar
- Card
- Modal
- Table
- Tabs
- Sidebar
- Navbar
- Breadcrumb
- Toast
- Empty State
- Skeleton Loader

No duplicate components should exist.

---

# Design Rules

Before shipping any screen, ask:

- Is it easy to understand?
- Can a first-time user use it?
- Is it visually consistent?
- Does it match the design system?
- Can it be reused?

If the answer is "No", redesign it.

---

# End of Document