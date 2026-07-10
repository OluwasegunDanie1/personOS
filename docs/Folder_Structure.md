---
Document: Folder Structure
Version: 1.0
Status: Draft
Project: Atlas (Codename)
Owner: Engineering Team
---

# Folder Structure

## Purpose

This document defines the folder structure for the Atlas Flutter application.

The goal is to create a project that is scalable, maintainable, and easy for any developer to understand.

---

# Architecture

Atlas follows a **Feature-First Clean Architecture**.

Each feature owns its:

- UI
- State
- Models
- Repository
- Services
- Routes

This keeps modules independent and easier to maintain.

---

# Root Structure

```text
atlas/

├── android/
├── ios/
├── linux/
├── macos/
├── windows/
├── web/
│
├── assets/
│
├── docs/
│
├── scripts/
│
├── test/
│
├── lib/
│
├── .env
├── pubspec.yaml
└── README.md
```

---

# Assets

```text
assets/

├── fonts/
├── icons/
├── images/
├── logos/
├── illustrations/
├── animations/
├── lottie/
└── translations/
```

---

# lib/

```text
lib/

├── app/
├── bootstrap/
├── core/
├── shared/
├── features/
└── main.dart
```

---

# app/

Contains application configuration.

```text
app/

├── app.dart
├── router.dart
├── theme.dart
├── constants.dart
└── providers.dart
```

---

# bootstrap/

Responsible for initializing the application.

```text
bootstrap/

├── bootstrap.dart
├── env.dart
└── initialization.dart
```

---

# core/

Contains reusable application-wide functionality.

```text
core/

├── api/
├── auth/
├── config/
├── database/
├── errors/
├── exceptions/
├── extensions/
├── localization/
├── logger/
├── network/
├── routing/
├── security/
├── services/
├── storage/
├── theme/
├── utils/
└── validators/
```

Nothing inside **core** should depend on a feature.

---

# shared/

Reusable UI components.

```text
shared/

├── widgets/
├── dialogs/
├── bottom_sheets/
├── cards/
├── forms/
├── buttons/
├── tables/
├── layouts/
├── navigation/
└── animations/
```

---

# features/

Every feature lives here.

```text
features/

├── auth/
├── dashboard/
├── organizations/
├── people/
├── journeys/
├── events/
├── attendance/
├── followups/
├── reports/
├── notifications/
├── settings/
└── profile/
```

Each feature should be independent.

---

# Example Feature

```text
people/

├── data/
│
├── domain/
│
├── presentation/
│
├── providers/
│
├── routes/
│
└── people_module.dart
```

---

# Data Layer

```text
data/

├── datasource/
├── dto/
├── models/
├── repository/
└── services/
```

Responsible for talking to APIs and local storage.

---

# Domain Layer

```text
domain/

├── entities/
├── repositories/
├── usecases/
└── value_objects/
```

Contains business rules.

---

# Presentation Layer

```text
presentation/

├── screens/
├── widgets/
├── controllers/
├── states/
└── viewmodels/
```

Contains everything related to UI.

---

# Providers

```text
providers/

people_provider.dart

selected_person_provider.dart

people_filter_provider.dart
```

Riverpod providers belong here.

---

# Routes

```text
routes/

people_routes.dart
```

Each feature manages its own routes.

---

# Tests

```text
test/

├── unit/
├── widget/
├── integration/
└── mocks/
```

Tests should mirror the application structure.

---

# Naming Rules

Folders:

snake_case

Files:

snake_case

Classes:

PascalCase

Variables:

camelCase

Constants:

camelCase

Enums:

PascalCase

Extensions:

SomethingExtension

---

# Feature Independence

A feature should never directly access another feature's internals.

Instead, communicate through:

- Shared services
- Interfaces
- Repositories

Avoid tight coupling.

---

# Dependency Direction

The dependency flow should always be:

```text
Presentation

↓

Domain

↓

Data

↓

API / Database
```

Never reverse this flow.

---

# Adding a New Feature

Every new feature should follow the same structure.

Example:

```text
donations/

├── data/
├── domain/
├── presentation/
├── providers/
├── routes/
└── donations_module.dart
```

Consistency is more important than creativity.

---

# Project Rules

- Keep files focused.
- Keep widgets small.
- Avoid large utility files.
- Prefer composition over inheritance.
- Remove unused code.
- Keep imports organized.

---

# Definition of a Good Folder Structure

A new developer should be able to:

- Find any file within seconds.
- Understand where new code belongs.
- Add new features without restructuring the project.

If the structure becomes confusing, simplify it.

---

# End of Document