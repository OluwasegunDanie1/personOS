---
Document: Wireframes
Version: 1.0
Status: Draft
Project: Atlas (Codename)
Owner: Design Team
---

# Wireframes

## Purpose

This document outlines the structure and layout of every major screen in Atlas before visual design begins.

Wireframes focus on **layout, hierarchy, navigation, and usability**, not colors or visual styling.

---

# Design Philosophy

Every screen should answer three questions within five seconds:

- Where am I?
- What can I do here?
- What should I do next?

If users cannot answer these questions quickly, simplify the design.

---

# Layout Principles

Every screen should follow a consistent layout.

## Desktop

```
┌────────────────────────────────────────────┐
│ Header                                     │
├───────────────┬────────────────────────────┤
│ Sidebar       │ Main Content               │
│ Navigation    │                            │
│               │                            │
│               │                            │
│               │                            │
└───────────────┴────────────────────────────┘
```

---

## Mobile

```
┌──────────────────────┐
│ App Bar              │
├──────────────────────┤
│                      │
│ Main Content         │
│                      │
│                      │
├──────────────────────┤
│ Bottom Navigation    │
└──────────────────────┘
```

---

# Authentication

## Login

Elements

- Logo
- Welcome text
- Email
- Password
- Remember Me
- Login Button
- Forgot Password
- Create Account

Primary Action

Login

---

## Registration

Elements

- Organization Name
- Full Name
- Email
- Password
- Confirm Password
- Create Organization Button

---

# Dashboard

Widgets

- Welcome Card
- Statistics Cards
- Upcoming Events
- Recent Activity
- Pending Follow-ups
- Quick Actions

Primary Action

Create Event

---

# People

Layout

```
Header

Search

Filters

Table / Cards

Pagination
```

Actions

- Add Person
- Edit
- Delete
- View Profile

---

# Person Profile

Sections

- Basic Information
- Contact Details
- Journey
- Attendance
- Notes
- Follow-ups
- Timeline

Primary Action

Edit Profile

---

# Journey Board

Layout

Kanban-style columns.

Example

```
Visitor

↓

First Visit

↓

Follow-up

↓

Member

↓

Volunteer

↓

Leader
```

Users should be able to drag and drop people between stages.

---

# Events

Layout

- Calendar View
- Event List
- Search
- Filters

Primary Action

Create Event

---

# Event Details

Sections

- Event Information
- Attendance
- Assigned Staff
- Notes
- Reports

Primary Action

Record Attendance

---

# Attendance

Layout

Search

↓

People List

↓

Check-in Controls

↓

Attendance Summary

Primary Action

Mark Attendance

---

# Follow-ups

Layout

- Assigned Tasks
- Due Today
- Upcoming
- Completed

Actions

- Create
- Assign
- Complete

---

# Reports

Widgets

- Charts
- KPIs
- Attendance Trends
- Growth Trends
- Journey Metrics

Actions

- Export
- Filter
- Compare

---

# Notifications

Layout

Simple chronological list.

Each notification includes:

- Icon
- Title
- Description
- Time
- Read Status

---

# Settings

Sections

- Organization
- Users
- Permissions
- Appearance
- Notifications
- Security
- Billing (Future)

---

# Empty States

Every module should include a meaningful empty state.

Example

"No people have been added yet."

Primary Action

Add Person

---

# Loading States

Use skeleton loaders instead of spinners whenever possible.

Users should immediately understand where content will appear.

---

# Error States

Display:

- Friendly title
- Clear explanation
- Retry button

Avoid technical language.

---

# Navigation

Desktop

- Sidebar Navigation

Mobile

- Bottom Navigation
- Overflow Menu

Navigation should remain consistent across all modules.

---

# Responsive Behavior

Atlas should support:

- Mobile
- Tablet
- Laptop
- Desktop
- Large Displays

Layouts should adapt gracefully without changing user workflows.

---

# Wireframe Principles

Every screen should:

- Have one clear primary action.
- Minimize unnecessary clicks.
- Keep important information visible.
- Follow the design system.
- Feel familiar across the platform.

---

# Deliverables

Before UI design begins, wireframes should be created for:

- Login
- Registration
- Dashboard
- People
- Person Profile
- Journey Board
- Events
- Event Details
- Attendance
- Follow-ups
- Reports
- Notifications
- Settings

---

# Success Criteria

Wireframes are complete when:

- Every major screen is represented.
- User flows are validated.
- Navigation is consistent.
- Layouts support all target devices.

---

# End of Document