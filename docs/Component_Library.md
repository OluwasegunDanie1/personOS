---
Document: Component Library
Version: 1.0
Status: Draft
Project: Atlas (Codename)
Owner: Design Team
---

# Component Library

## Purpose

This document defines every reusable UI component used throughout Atlas.

A component should be designed once and reused everywhere.

The goal is to ensure consistency, reduce development time, and simplify maintenance.

---

# Design Principles

Every component should be:

- Reusable
- Accessible
- Responsive
- Consistent
- Easy to maintain

A component should solve one problem well.

---

# Component Categories

Atlas components are grouped into:

- Foundations
- Inputs
- Navigation
- Data Display
- Feedback
- Overlays
- Layout
- Charts
- Utility Components

---

# Foundations

## Colors

Use only Design Tokens.

Never hardcode colors.

---

## Typography

Use predefined text styles.

Examples

- Display
- Heading
- Title
- Subtitle
- Body
- Caption
- Label

---

## Icons

Supported Sizes

```
16

20

24

32

40

48
```

Icons should come from a single icon library.

---

# Buttons

Types

## Primary Button

Used for the primary action on a page.

Example

```
Create Event
```

---

## Secondary Button

Used for supporting actions.

---

## Text Button

Used for low-emphasis actions.

---

## Icon Button

Button containing only an icon.

---

## Floating Action Button

Reserved for mobile.

One per screen.

---

## Button States

Every button supports:

- Default
- Hover
- Focus
- Pressed
- Disabled
- Loading

---

# Inputs

## Text Field

Supports

- Label
- Placeholder
- Helper Text
- Validation
- Prefix Icon
- Suffix Icon

---

## Search Field

Includes

- Search Icon
- Clear Button

---

## Password Field

Supports

- Show Password
- Hide Password

---

## Text Area

Used for:

- Notes
- Descriptions
- Comments

---

## Select Dropdown

Supports

- Search
- Single Select
- Multi Select

---

## Date Picker

Supports

- Single Date
- Date Range

---

## Time Picker

Used for scheduling events.

---

## Checkbox

Supports:

- Checked
- Unchecked
- Disabled

---

## Radio Button

Single selection.

---

## Switch

Binary settings.

Example

```
Enable Notifications
```

---

# Navigation

## Sidebar

Desktop navigation.

Supports

- Icons
- Labels
- Active state
- Collapse

---

## Bottom Navigation

Mobile navigation.

Maximum

Five items.

---

## Top App Bar

Contains

- Logo
- Search
- Notifications
- User Menu

---

## Breadcrumb

Shows navigation hierarchy.

Desktop only.

---

## Tabs

Used to switch between related content.

---

# Cards

## Statistic Card

Examples

- Total Members
- Attendance
- Events

---

## Person Card

Contains

- Avatar
- Name
- Tags
- Status

---

## Event Card

Contains

- Date
- Time
- Title
- Attendance

---

## Follow-up Card

Contains

- Person
- Due Date
- Assigned User
- Status

---

# Tables

Supports

- Sorting
- Pagination
- Search
- Filtering
- Bulk Selection

Responsive on all supported devices.

---

# Lists

Examples

- Notifications
- Activities
- Events
- People

---

# Timeline

Used in:

- Person Profile
- Activity History
- Journey History

---

# Kanban Board

Used for:

Journey Management

Supports

- Drag and Drop
- Reordering
- Stage Counts

---

# Feedback Components

## Snackbar

Temporary success or error messages.

---

## Alert

Types

- Success
- Warning
- Error
- Information

---

## Progress Indicator

Types

- Circular
- Linear
- Skeleton Loader

---

## Empty State

Contains

- Illustration
- Message
- Primary Action

---

## Error State

Contains

- Friendly explanation
- Retry button

---

# Dialogs

Standard dialogs

Examples

- Delete Confirmation
- Logout
- Archive
- Remove User

---

# Bottom Sheets

Used on mobile for:

- Filters
- Actions
- Quick Forms

---

# Menus

Supports

- Context Menu
- Overflow Menu
- Dropdown Menu

---

# Avatars

Sizes

```
32

40

48

64

80
```

Supports

- Initials
- Image
- Status Indicator

---

# Badges

Types

- Status
- Count
- Notification

---

# Chips

Used for

- Tags
- Filters
- Categories

Supports removable chips.

---

# Charts

Supported Charts

- Line Chart
- Bar Chart
- Pie Chart
- Area Chart
- KPI Cards

Charts should prioritize readability.

---

# Calendar

Supports

- Month View
- Week View
- Day View

Future

Agenda View

---

# Search

Global search component.

Supports

- Keyboard shortcut
- Recent searches
- Suggestions
- Results grouping

---

# Notifications

Notification item includes

- Icon
- Title
- Description
- Timestamp
- Read Indicator

---

# File Upload

Supports

- Drag & Drop
- Browse Files
- Image Preview
- Upload Progress

---

# Responsive Behavior

Every component must support:

- Mobile
- Tablet
- Desktop

Components should adapt without changing behavior.

---

# Accessibility

Every component must include:

- Keyboard navigation
- Focus state
- Screen reader labels
- Accessible color contrast

---

# Component Documentation

Each component should include:

- Purpose
- Usage Guidelines
- Properties
- States
- Variants
- Accessibility Notes
- Example

---

# Component Naming

Examples

```
AppButton

AppCard

AppInput

AppDialog

AppAvatar

AppTable

AppBadge

AppTimeline

AppSearchBar
```

Use a consistent naming convention across the project.

---

# Source of Truth

The Component Library in Figma is the single source of truth.

Flutter implementations should match the design specifications exactly.

---

# Success Criteria

The component library is successful when:

- Every screen is built using reusable components.
- Components are visually consistent.
- New features require minimal new UI elements.
- Designers and developers work from the same library.

---

# End of Document