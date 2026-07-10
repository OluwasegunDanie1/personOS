---
Document: Information Architecture
Version: 0.1
Status: Draft
Project: Atlas (Codename)
Owner: Product Team
---

# Information Architecture

## Purpose

This document defines how information is organized throughout Atlas.

The goal is to make navigation simple, predictable, and scalable.

---

# Navigation Structure

```
Dashboard
│
├── People
│   ├── All People
│   ├── Journey
│   ├── Tags
│   └── Import
│
├── Events
│   ├── All Events
│   ├── Calendar
│   └── Attendance
│
├── Follow-ups
│   ├── Pending
│   ├── In Progress
│   ├── Completed
│   └── Templates
│
├── Reports
│   ├── Attendance
│   ├── People
│   ├── Growth
│   ├── Follow-ups
│   └── Events
│
├── Team
│   ├── Users
│   ├── Roles
│   └── Permissions
│
├── Settings
│   ├── Organization
│   ├── Branding
│   ├── Billing
│   └── Preferences
│
└── Help
```

---

# Main Navigation

The sidebar should contain only the most important sections.

- Dashboard
- People
- Events
- Follow-ups
- Reports
- Team
- Settings

Keep the navigation short and easy to scan.

---

# Dashboard

The dashboard is the home screen after login.

It should answer three questions immediately:

- What happened today?
- What needs attention?
- What's coming next?

Widgets may include:

- Total People
- Today's Attendance
- Pending Follow-ups
- Upcoming Events
- Recent Activity

---

# People

The People module is the heart of Atlas.

Every person has a profile containing:

- Basic Information
- Contact Details
- Journey
- Attendance History
- Follow-up History
- Notes
- Tags

---

# Events

Each event contains:

- Event Details
- Date & Time
- Location
- Attendance
- Notes
- Reports

---

# Follow-ups

Each follow-up contains:

- Assigned Person
- Assigned Staff
- Due Date
- Status
- Notes
- Activity History

---

# Reports

Reports should be grouped by category instead of displaying one long list.

Examples:

- Attendance Reports
- Event Reports
- Growth Reports
- Follow-up Reports

---

# Search

Global Search should always be visible.

Users should be able to search for:

- People
- Events
- Teams
- Notes

Results should appear instantly.

---

# Notifications

Notifications should be accessible from every page.

Types include:

- New assignments
- Upcoming events
- Follow-up reminders
- System updates

---

# Profile Menu

The profile menu should contain:

- My Profile
- Notifications
- Preferences
- Help
- Logout

---

# Breadcrumbs

Every page after the dashboard should display a breadcrumb.

Example:

Dashboard

↓

People

↓

John Doe

This helps users know where they are.

---

# Mobile Navigation

On mobile, use a bottom navigation bar.

Recommended tabs:

- Home
- People
- Events
- Tasks
- Menu

Everything else can be accessed through the Menu tab.

---

# Design Rules

Navigation should:

- Be consistent
- Require minimal clicks
- Avoid deep nesting
- Keep labels simple
- Highlight the current page

---

# Future Expansion

The architecture should allow new modules to be added without redesigning the navigation.

Examples:

- Automations
- Integrations
- API
- Marketplace
- AI Assistant

---

# End of Document