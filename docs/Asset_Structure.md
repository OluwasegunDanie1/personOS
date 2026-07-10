---
Document: Asset Structure
Version: 1.0
Status: Draft
Project: Relvio
Owner: Engineering & Design
---

# Asset Structure

## Purpose

This document defines how all design assets, icons, illustrations, fonts, and images are organized within the Relvio project.

A consistent asset structure improves maintainability, scalability, and collaboration between designers and developers.

---

# Principles

Assets should be:

- Organized
- Reusable
- Optimized
- Versioned
- Easy to locate

Avoid duplicate assets.

---

# Project Structure

```
assets/

├── branding/
│   ├── logos/
│   ├── app_icon/
│   ├── favicon/
│   └── splash/
│
├── icons/
│   ├── outline/
│   ├── filled/
│   └── custom/
│
├── illustrations/
│   ├── onboarding/
│   ├── empty_states/
│   ├── errors/
│   └── marketing/
│
├── images/
│   ├── avatars/
│   ├── placeholders/
│   ├── backgrounds/
│   ├── banners/
│   └── demo/
│
├── animations/
│   ├── lottie/
│   └── rive/
│
├── fonts/
│
├── mockups/
│
└── flags/
```

---

# Branding

Contains:

- Primary Logo
- Secondary Logo
- White Logo
- Black Logo
- SVG Files
- PNG Files

---

# App Icon

Contains:

- Android Icon
- iOS Icon
- Adaptive Icon
- Foreground
- Background
- Play Store Assets

---

# Icons

Official application icons.

Requirements:

- SVG format
- Consistent stroke width
- Optimized for Flutter

---

# Illustrations

Organized into:

## Onboarding

Welcome screens.

---

## Empty States

Examples

- No People
- No Events
- No Reports
- No Notifications

---

## Errors

Examples

- 404
- Offline
- Server Error

---

## Marketing

Used for:

- Landing Page
- Blog
- Social Media
- Documentation

---

# Images

Should include:

- Team Photos
- Demo Images
- Placeholder Images
- Organization Covers

Optimize before committing.

---

# Fonts

Store only licensed fonts.

Primary

Inter

Future fonts should include license documentation.

---

# Animations

Supported formats:

- Lottie
- Rive

Avoid GIF animations.

---

# File Naming

Good

```
logo_primary.svg

logo_white.svg

dashboard_empty.png

user_placeholder.png
```

Avoid

```
logo-new-final2.png

image1.png

test.png
```

---

# Image Formats

Use:

SVG

- Logos
- Icons
- Simple graphics

PNG

- Transparent assets

WebP

- Product images
- Marketing assets

JPEG

- Photography

---

# Optimization

Every image should be optimized before use.

Avoid unnecessarily large files.

---

# Asset Guidelines

Never:

- Duplicate assets
- Upload unoptimized images
- Mix naming styles
- Commit temporary exports

---

# Versioning

When replacing assets:

- Archive old versions
- Keep filenames consistent
- Update documentation if necessary

---

# Flutter Integration

Reference assets using centralized constants.

Example

```
AppAssets.logo

AppAssets.emptyPeople

AppAssets.iconAttendance
```

Avoid hardcoding file paths throughout the project.

---

# Git Rules

Commit only production-ready assets.

Exclude:

- Temporary exports
- Design experiments
- AI prompt files
- Scratch artwork

---

# Success Criteria

The asset structure is successful when:

- Every asset has a predictable location.
- Naming is consistent.
- Flutter developers can find assets easily.
- Designers can update assets without confusion.
- The project remains clean as it grows.

---

# End of Document