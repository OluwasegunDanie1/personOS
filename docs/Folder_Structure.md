---
Document: Folder Structure
Version: 1.1
Status: Approved
Project: Relvio
Owner: Engineering Team
---

# Folder Structure

## Purpose

This document defines the approved folder organization for the Relvio Flutter application.

The goal is to keep the codebase:

- Easy to navigate
- Predictable
- Maintainable
- Testable
- Compatible with AI-assisted implementation
- Scalable without premature abstraction

Relvio uses a feature-first architecture with controlled:

- Data
- Domain
- Presentation

boundaries.

This document defines Flutter client organization.

It does not define backend folder structure.

---

# Relvio v1 Context

Relvio v1 supports:

```text
Android
iOS


The approved frontend technology is:

Flutter

The approved state management technology is:

Riverpod

The approved routing technology is:

GoRouter

The approved client architecture communicates through:

Flutter
    ↓
Backend REST API
    ↓
PostgreSQL

The API base is:

/api/v1

Flutter must never connect directly to PostgreSQL.

The backend remains authoritative for:

Authentication
Organization membership
Roles
Permissions
Business rules
Validation
Organization isolation
Protected data mutations

Attendance requires backend integrity controls and idempotency.

Journey transitions preserve immutable journey history.

The Flutter folder structure must preserve these architecture boundaries.

Architecture Style

Relvio uses:

Feature-first architecture with controlled data, domain, and presentation boundaries.

Conceptually:

Feature
│
├── data
├── domain
└── presentation

Not every feature must contain every possible folder.

Create architectural layers only when the feature requires them.

Do not create empty folders to satisfy a template.

Architecture Principle

The preferred organization is:

Application Infrastructure
        +
Shared Presentation Foundations
        +
Feature-Owned Product Code

Conceptually:

lib/
│
├── app/
├── core/
├── shared/
├── features/
└── main.dart

Each area has a distinct responsibility.

Do not place feature business logic in core.

Do not place application-wide infrastructure inside an arbitrary feature.

Do not turn shared into a dumping ground.

Root Structure

The Relvio Flutter repository should conceptually contain:

relvio/
│
├── android/
├── ios/
│
├── assets/
├── docs/
├── test/
├── lib/
│
├── pubspec.yaml
├── README.md
└── ...

Additional project configuration files may exist as required by:

Flutter
Dart
Android
iOS
CI/CD
Approved tooling

Do not treat every generated Flutter platform directory as an approved Relvio product target.

Relvio v1 product targets are:

Android
iOS

Do not build Relvio v1 product support for:

Web
Windows
macOS
Linux

unless future product scope explicitly approves those platforms.

If Flutter tooling generates unused platform directories, their existence does not authorize platform-specific implementation.

Environment Files

Sensitive environment configuration must not be committed to source control.

Do not treat:

.env

as a normal committed root file.

Environment configuration must follow approved security and deployment documentation.

Relevant documents include:

16_Security.md
Deployment.md

Do not hardcode:

API secrets
Database credentials
Private keys
Authentication secrets

inside Flutter source code.

Flutter must not receive PostgreSQL credentials.

Asset Structure

Production Flutter assets must follow:

Asset_Structure.md

The approved asset structure must not be redefined in this document.

Conceptually, production assets live under:

assets/

Use the exact approved categories and rules defined by Asset_Structure.md.

Do not automatically create:

animations/
lottie/
translations/
illustrations/

unless approved assets or implementation requirements justify those directories.

Do not add Lottie or Rive by default.

Simple animation should be implemented directly in Flutter where appropriate.

Approved brand assets must be used directly.

Missing approved assets must be reported.

Do not recreate the Relvio logo.

lib Structure

The approved conceptual lib structure is:

lib/
│
├── app/
├── core/
├── shared/
├── features/
└── main.dart

These top-level areas should remain limited and understandable.

Do not add new top-level architecture folders without a clear approved responsibility.

main.dart

main.dart is the Flutter application entry point.

Its responsibility should remain minimal.

Conceptually:

main.dart
    ↓
Application Initialization
    ↓
ProviderScope
    ↓
Relvio Application

main.dart should not contain:

Feature business logic
API implementation
Route definitions for every feature
Theme token definitions
Large initialization workflows
Screen widgets

Delegate responsibilities to the appropriate application or infrastructure code.

app

The app area contains application composition and top-level Flutter configuration.

Conceptually:

app/
│
├── app.dart
├── routing/
└── theme/

Additional application-level files may be introduced only when a real responsibility exists.

The exact internal structure may evolve according to approved implementation needs.

Do not create generic files such as:

constants.dart
providers.dart

as global dumping grounds.

app.dart

app.dart contains the top-level Relvio application widget.

Its responsibilities may include:

Application theme integration
GoRouter integration
Top-level Flutter application configuration

Conceptually:

MaterialApp.router(...)

or the approved Flutter equivalent.

app.dart must not contain feature business logic.

Application Routing

Application-level routing composition belongs under an approved routing responsibility.

Conceptually:

app/
└── routing/
    ├── app_router.dart
    └── ...

GoRouter is the approved routing technology.

The application router may compose route definitions owned or declared by features where useful.

Do not require every feature to create a separate routes/ directory.

Do not require:

people_routes.dart
events_routes.dart
attendance_routes.dart

merely because a feature exists.

Route organization should reflect actual routing complexity.

Routing architecture is defined by approved routing documentation where applicable.

Application Theme

Flutter theme implementation belongs under the approved application or shared presentation foundation according to final project organization.

Conceptually:

app/
└── theme/
    ├── app_theme.dart
    └── ...

or another approved placement consistent with the project structure.

Theme implementation must follow:

Flutter Theme Implementation.md
Design Tokens.md
Color System.md

Do not duplicate theme responsibilities between:

app/theme/

and:

core/theme/

There should be one clear theme ownership location.

bootstrap

A dedicated top-level:

bootstrap/

directory is not mandatory.

Application initialization should be introduced only when initialization complexity requires separation.

A small application may use an application initialization file under an appropriate approved infrastructure location.

If initialization becomes substantial, a focused structure may be introduced.

Possible responsibilities include:

Flutter binding initialization
Approved environment configuration
Approved service initialization
Error boundary setup
Logging initialization

Do not create:

bootstrap.dart
env.dart
initialization.dart

as empty architecture placeholders.

Create files when real implementation responsibilities exist.

core

The core area contains application-wide technical infrastructure and foundational code.

Nothing inside core should depend on feature implementation details.

Possible responsibilities include:

core/
│
├── api/
├── config/
├── errors/
├── logging/
├── network/
├── security/
├── storage/
└── utils/

Only create directories that are actually required.

The final core structure should remain small.

Core Rules

core may contain:

REST API client infrastructure
Network configuration
Shared API transport behavior
Application configuration
Technical error foundations
Logging infrastructure
Secure local storage abstraction
Application-wide technical utilities

core must not contain:

People business logic
Attendance business logic
Journey business logic
Event business logic
Follow-up business logic
Organization-specific product rules

Feature product behavior belongs with the relevant feature.

No Flutter Database Layer

Do not create:

core/database/

for PostgreSQL access.

The approved architecture is:

Flutter
    ↓
Backend REST API
    ↓
PostgreSQL

Flutter must never:

Open PostgreSQL connections
Contain PostgreSQL credentials
Execute SQL against the production database
Bypass the backend REST API

If approved local device persistence is required, it belongs under an explicitly defined local storage or cache responsibility.

Local storage must not be confused with the primary PostgreSQL database.

API Infrastructure

Shared REST API infrastructure may live conceptually under:

core/
└── api/

Possible responsibilities include:

Base API client
/api/v1 base configuration
Request transport
Response transport
Approved authentication header attachment
Timeout handling
Shared API error mapping

Do not place feature endpoint methods for every product domain into one giant API client.

Feature-specific remote data access belongs with the relevant feature data layer.

Conceptually:

core/api/
    ↓
Shared HTTP Infrastructure

features/people/data/
    ↓
People API Data Access
Authentication Infrastructure

Do not automatically create:

core/auth/

and place the complete authentication feature there.

Authentication is a product feature and may live under:

features/auth/

Application-wide authentication infrastructure may exist in core only where the responsibility is genuinely technical and shared.

Examples may include:

Secure token storage abstraction
Shared authenticated request handling

Do not duplicate authentication responsibility between core/auth and features/auth.

Routing Infrastructure

Do not automatically create both:

app/routing/

and:

core/routing/

for the same responsibility.

Application route composition should have one clear ownership location.

GoRouter configuration should remain understandable.

Avoid multiple router registries, route service layers, and navigation abstractions unless actual implementation complexity requires them.

Localization

Localization infrastructure is not an approved Relvio v1 requirement.

Do not automatically create:

core/localization/

or:

assets/translations/

Do not add localization packages or translation architecture for hypothetical future support.

If localization becomes approved product scope, update relevant:

Product documentation
Asset structure
Project structure
Flutter configuration
Testing strategy

before implementation.

shared

The shared area contains reusable presentation code that is used across multiple features.

Conceptually:

shared/
│
├── widgets/
└── ...

Additional grouping may be introduced when the number of shared components justifies it.

Do not create every possible component category in advance.

Shared Presentation Rules

A component belongs in shared when:

It is used across multiple features.
Its responsibility is not owned by one product domain.
Reuse improves consistency.
Its behavior remains generic to Relvio presentation.

Examples may include approved shared:

Buttons
Inputs
Feedback patterns
Navigation elements
Common layout helpers

The actual shared component set must emerge from approved Relvio UI.

Component governance is defined by:

Component Library.md
Shared Is Not a Dumping Ground

Do not move a widget to shared merely because it is reused twice inside one feature.

For example:

features/attendance/presentation/widgets/

may contain a widget used by several Attendance screens.

That does not automatically make it application-wide.

Promote a component to shared only when responsibility genuinely crosses feature boundaries.

Shared Folder Growth

Start with the smallest useful shared structure.

For example:

shared/
└── widgets/

As approved components grow, organization may evolve into focused groups.

Possible examples include:

shared/
├── actions/
├── inputs/
├── feedback/
└── navigation/

only when actual component volume justifies those categories.

Do not pre-create:

dialogs/
bottom_sheets/
cards/
forms/
buttons/
tables/
layouts/
navigation/
animations/

as empty folders.

Do not create a shared table system for Relvio v1 unless approved UI requires one.

features

Product features live under:

features/

Each feature owns its product-specific implementation.

Approved or implementation-required v1 feature areas may include:

features/
│
├── auth/
├── onboarding/
├── home/
├── people/
├── journeys/
├── events/
├── attendance/
├── follow_ups/
└── workspace/

The exact active feature directories must match approved Relvio v1 product scope and frozen UI.

Do not create feature folders merely because an idea appears in:

Feature Backlog.md
Future roadmap sections
Old Atlas documentation

Do not pre-create:

reports/
notifications/
settings/
profile/
organizations/

unless approved Relvio v1 screens or implementation responsibilities require those feature boundaries.

Some responsibilities may exist inside another approved feature rather than as standalone features.

Use approved product responsibility, not generic SaaS naming.

Workspace Naming

The approved final primary navigation label is:

Workspace

Use:

workspace/

for the corresponding feature responsibility where a dedicated feature folder is appropriate.

Do not use:

more/

for the final primary navigation destination.

Do not preserve the old More terminology in:

Folder names
Route names
Screen names
Widget names
Providers
Tests

unless referring to historical design documentation.

Feature Structure

A feature may use:

feature_name/
│
├── data/
├── domain/
└── presentation/

Example:

people/
│
├── data/
├── domain/
└── presentation/

This is the approved conceptual feature boundary.

Not every feature must contain all three layers.

Do not create empty architectural layers.

Feature Layer Rule

Use the smallest architecture that preserves responsibility.

For a simple presentation-only feature, this may be sufficient:

feature_name/
└── presentation/

If the feature consumes backend data:

feature_name/
├── data/
├── domain/
└── presentation/

may be appropriate.

If a domain abstraction provides no real value for a simple feature, do not create placeholder:

entities/
repositories/
usecases/
value_objects/

solely to imitate Clean Architecture.

Relvio uses controlled architecture.

It does not use architecture ceremony for its own sake.

Data Layer

The feature data layer handles technical data access and data representation for that feature.

A feature data layer may conceptually contain:

data/
│
├── datasources/
├── dtos/
├── repositories/
└── mappers/

Create only the folders required by the feature.

Possible responsibilities include:

Feature REST API calls
Request DTOs
Response DTOs
Data mapping
Repository implementation
Approved local cache access

The data layer does not define protected business authority.

The backend remains authoritative.

Data Sources

Feature remote data access may live under:

data/
└── datasources/

For example:

people_remote_data_source.dart

where such an abstraction improves clarity.

Do not require a data source interface for every API call.

Do not create:

remote/
local/
cache/

subdirectories unless the feature actually has those data sources.

Avoid abstraction layers with only one method and no meaningful architectural responsibility.

DTOs

Transport-specific API data structures may live under:

data/
└── dtos/

DTOs may represent:

API requests
API responses

DTOs should reflect the approved API contract.

Do not invent fields missing from:

13_API_Specification.md
Approved backend contracts

Do not use Flutter UI models as API DTOs merely to reduce file count.

Do not expose backend transport details unnecessarily to presentation code.

Mappers

Mapping code may be introduced where data and domain representations differ.

Conceptually:

API DTO
    ↓
Mapper
    ↓
Domain Entity

Do not create mapper classes when no meaningful transformation exists.

Simple conversion may remain close to the responsible data type where engineering standards permit.

Do not create architecture ceremony around one-to-one field copies without benefit.

Data Models

Do not create both:

models/

and:

dto/

inside every feature without a defined difference.

Use clear terminology.

Recommended conceptual distinction:

DTO
    ↓
Transport representation

Entity
    ↓
Domain representation

View State
    ↓
Presentation representation

If a feature does not require separate representations, use the simplest approved structure.

Avoid duplicate classes containing identical fields solely to satisfy layer names.

Repository Implementation

Repository implementations belong in the feature data layer.

Conceptually:

data/
└── repositories/
    └── people_repository_impl.dart

where a repository abstraction is justified.

Repository implementations may coordinate:

Remote data access
Approved local cache access
Data mapping

Repositories must not bypass the backend for protected mutations.

Do not implement client-side organization isolation as the security boundary.

The backend enforces organization isolation.

Domain Layer

The domain layer contains feature concepts and client-side application rules that should remain independent from Flutter presentation and transport details.

A domain layer may conceptually contain:

domain/
│
├── entities/
├── repositories/
└── use_cases/

Additional domain structures should be introduced only when justified.

Do not create:

value_objects/

for every primitive field.

Use value objects only when they protect meaningful domain rules or concepts.

Domain Independence

Domain code should not depend on:

Flutter widgets
BuildContext
Material UI
GoRouter
HTTP response objects
JSON maps
PostgreSQL
Feature presentation controllers

Domain abstractions should remain focused on product responsibility.

Domain Entities

Domain entities represent meaningful feature concepts where separation from API transport improves clarity.

Examples may conceptually include:

Person
Event
Journey
AttendanceRecord

Actual fields and behavior must follow approved product and API documentation.

Do not invent domain properties.

Do not move backend authority into Flutter domain entities.

For example, a Flutter entity must not become the authoritative source for:

Organization membership
Permissions
Journey history
Attendance integrity

The backend remains authoritative.

Domain Repository Contracts

Repository abstractions may live under:

domain/
└── repositories/

when abstraction improves:

Testability
Dependency direction
Data source independence
Feature clarity

Do not create a repository interface automatically for every data class.

A repository contract should represent a meaningful feature data responsibility.

Example conceptually:

PeopleRepository

not:

GetPersonNameRepository
PersonAvatarRepository
PersonCountRepository

Avoid unnecessary fragmentation.

Use Cases

Use cases may be introduced for meaningful client application operations.

Conceptually:

domain/
└── use_cases/

A use case is useful when it:

Coordinates meaningful client-side application behavior.
Is reused.
Protects a clear feature operation.
Improves testability.

Do not create one use-case class for every repository method.

Do not create:

GetPeopleUseCase
GetPersonUseCase
CreatePersonUseCase
UpdatePersonUseCase
DeletePersonUseCase

automatically merely because CRUD methods exist.

Simple feature flows may call a repository abstraction from the presentation controller when approved architecture remains clear.

Critical backend business rules remain backend responsibilities.

Presentation Layer

The feature presentation layer contains Flutter UI and Riverpod-managed presentation state.

Conceptually:

presentation/
│
├── screens/
├── widgets/
├── controllers/
└── providers/

Create only the directories required by the feature.

The presentation layer may contain:

Screens
Feature-specific widgets
Riverpod providers
Controllers or notifiers
Presentation state

Do not create both controllers and view models for the same responsibility.

Screens

Feature screens belong under:

presentation/
└── screens/

Screens should:

Compose approved UI.
Observe presentation state.
Trigger approved user actions.
Delegate data operations and business coordination.

Screens must not:

Call PostgreSQL
Execute SQL
Build raw HTTP requests
Enforce organization isolation
Define protected authorization rules
Generate authoritative journey history
Treat local attendance state as authoritative

Do not place feature repository implementation inside a screen.

Feature Widgets

Feature-specific widgets belong under:

presentation/
└── widgets/

A widget should remain feature-owned when its responsibility belongs primarily to that feature.

For example:

attendance_status_row.dart
journey_stage_item.dart
person_summary_section.dart

may remain feature-specific.

Do not move widgets into shared merely to shorten import paths.

Riverpod Providers

Riverpod providers belong near the state or dependency responsibility they expose.

For feature presentation state, providers should normally live under:

presentation/
└── providers/

or alongside the responsible controller/notifier when a smaller feature structure is clearer.

Do not create a separate top-level feature folder:

feature_name/providers/

while also maintaining presentation controllers and state elsewhere.

There should be one clear presentation state ownership model.

Controllers and Notifiers

Riverpod state coordination may use approved Riverpod patterns such as:

Notifier
AsyncNotifier
Provider
FutureProvider
StreamProvider

where appropriate.

A conceptual controller or notifier file may live under:

presentation/
└── controllers/

or another clearly defined presentation state location.

Do not create all of the following for the same feature operation:

Controller
ViewModel
Notifier
Provider
Service

unless each has a genuinely different responsibility.

Prefer the smallest clear state structure.

Presentation State

Complex presentation state may use explicit state classes.

These may live:

Near the responsible controller or notifier
In a focused states/ directory when feature complexity justifies it

Do not create a states/ directory for one trivial state class.

Do not place backend DTOs in presentation state.

Presentation state should represent what the UI needs to render and interact with.

View Models

A universal viewmodels/ directory is not approved.

Do not create both:

controllers/

and:

viewmodels/

for equivalent presentation responsibilities.

If a specific read model or view-specific transformation is genuinely required, name it according to its responsibility.

Do not introduce an additional MVVM architecture on top of approved Riverpod presentation architecture.

Feature Routes

A universal:

routes/

directory inside every feature is not required.

Route declarations may remain close to feature navigation responsibility and be composed by the application router.

For a simple feature, the application router may define the relevant routes directly.

For a larger feature, a focused feature route file may be appropriate.

Do not create:

people_routes.dart
journey_routes.dart
event_routes.dart

as empty or trivial wrappers.

GoRouter remains the approved routing technology.

Feature Module Files

A universal file such as:

people_module.dart

is not required.

Relvio does not use a mandatory feature module registry architecture.

Do not create:

auth_module.dart
people_module.dart
events_module.dart
attendance_module.dart

solely to imitate modular frameworks.

Create a feature composition file only when it has a real approved responsibility.

Feature Independence

A feature should not directly depend on another feature's private implementation details.

Avoid imports into another feature's:

data/
presentation/controllers/
presentation/providers/

unless an approved architecture decision explicitly requires the relationship.

Prefer communication through:

Shared domain contracts where genuinely shared
Application composition
Shared infrastructure
Approved feature-facing interfaces

Do not create a generic event bus to avoid all feature dependencies.

Do not move product logic into core merely because two features need related data.

Cross-feature relationships should reflect actual Relvio product concepts.

Cross-Feature Imports

Before importing code from one feature into another, ask:

Is this concept genuinely owned by the source feature?
Is the target feature allowed to know about it?
Is the imported type a stable feature-facing concept?
Are we importing private implementation detail?
Would application composition be clearer?

Do not ban all cross-feature imports mechanically.

Control them intentionally.

Architecture rules should preserve responsibility, not create artificial indirection.

Dependency Direction

The old dependency diagram:

Presentation
    ↓
Domain
    ↓
Data
    ↓
API / Database

is not the approved dependency model.

The conceptual feature dependency direction is:

Presentation
    ↓
Domain Abstractions
    ↑
Data Implementations

More explicitly:

Presentation
    ↓
Domain

Data
    ↓
Domain

Data
    ↓
Core API Infrastructure

The domain layer should not depend on the data layer.

Conceptually:

Domain Repository Contract
            ↑
            │ implements
            │
Data Repository Implementation

The Flutter client communicates with the backend REST API.

There is no Flutter PostgreSQL dependency.

Dependency Composition

Riverpod may compose dependencies.

Conceptually:

Core API Client
        ↓
Feature Remote Data Source
        ↓
Feature Repository Implementation
        ↓
Repository Provider
        ↓
Presentation Controller / Notifier
        ↓
Screen

This is a conceptual dependency chain.

Do not create every layer when the feature does not require it.

The approved architecture permits simplification where responsibilities remain clear.

Backend Boundary

The Flutter folder structure must never imply that client architecture replaces backend architecture.

Flutter may contain:

API request models
API response models
Client presentation state
Client-side input validation
Client navigation logic
Client interaction state

Flutter must not become authoritative for:

Organization isolation
Role enforcement
Permission enforcement
Protected business rules
Attendance integrity
Journey transition history

The backend REST API enforces those responsibilities.

Organization Context

Relvio is multi-tenant.

The client may need presentation or request context related to the active organization.

Do not create a client-side organization filter and treat it as the security boundary.

For example:

people.where(
  (person) => person.organizationId == activeOrganizationId,
)

does not enforce tenant isolation.

The backend must return organization-authorized data.

Client organization context supports UX and request context only.

Security requirements are governed by:

16_Security.md
Naming Rules

Use approved Dart and Flutter naming conventions.

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

Extensions should use descriptive PascalCase names.

Where an extension name requires explicit distinction, an Extension suffix may be used.

Examples:

StringExtension
DateTimeFormattingExtension

Naming should prioritize clarity.

File Naming

File names should describe responsibility.

Prefer:

people_repository.dart
people_repository_impl.dart
people_remote_data_source.dart
people_controller.dart
people_screen.dart
person_details_screen.dart

Avoid:

helper.dart
utils.dart
common.dart
manager.dart
service.dart
stuff.dart
misc.dart

unless the file has a clearly defined responsibility matching the name.

Do not create giant generic utility files.

Barrel Files

Barrel export files are optional.

Do not create:

people.dart
attendance.dart
journey.dart

solely to export every file in a feature.

Use barrel files only when they create a clear stable import boundary.

Avoid barrel files that:

Hide dependency direction
Create circular imports
Export private feature implementation
Make code navigation harder

Direct imports are acceptable.

Generated Code

Generated Dart files should remain close to the source that generates them according to the relevant package convention.

Examples may include generated files for:

Serialization
Riverpod code generation

Do not manually edit generated files.

Do not move generated files into a global:

generated/

directory unless the approved tool requires that structure.

Generated code must follow approved engineering and tooling decisions.

Tests

Tests should mirror application responsibility where practical.

Conceptually:

test/
│
├── core/
├── shared/
├── features/
└── app/

Example:

test/
└── features/
    └── people/
        ├── data/
        ├── domain/
        └── presentation/

Create test directories only when relevant tests exist.

Do not require top-level:

unit/
widget/
integration/
mocks/

as the primary organizational structure.

Organizing tests by application responsibility usually makes corresponding production code easier to locate.

Testing strategy is governed by:

15_Testing_Strategy.md
Integration Tests

Flutter integration tests should use the structure required by approved Flutter tooling and project configuration.

Where Flutter requires:

integration_test/

use that location.

Do not force integration tests into:

test/integration/

when the approved tooling expects a different structure.

The testing tool and test responsibility determine placement.

Test Doubles

Do not create one global:

test/mocks/

directory by default.

Feature-specific test doubles should remain near the relevant feature tests where practical.

Shared test helpers may live under a focused test support location when genuinely reused.

Do not create large global mock registries.

Test code should remain understandable.

Documentation

Project documentation may live under:

docs/

according to the approved documentation organization.

The approved MD documentation defines implementation guidance.

AI coding assistants must review relevant approved documentation before implementing affected architecture.

Do not duplicate the same architecture rule across multiple new documentation files without need.

If two documents conflict, resolve the contradiction before implementation.

Scripts

A root:

scripts/

directory may be introduced when approved project automation scripts exist.

Do not create an empty scripts directory.

Possible responsibilities may include:

Approved development automation
Approved CI support
Approved asset validation

Scripts must not contain committed secrets.

Do not use scripts to bypass approved build, security, or deployment controls.

Adding a New Feature

Do not copy a fixed generic feature template blindly.

Before adding a feature:

Confirm the feature is approved product scope.
Identify the feature responsibility.
Review approved API contracts.
Determine whether the feature needs backend data.
Determine whether a domain layer adds meaningful value.
Determine required presentation state.
Create the smallest justified feature structure.
Add tests according to behavioral risk.

A simple feature may begin as:

feature_name/
└── presentation/

A data-backed feature may use:

feature_name/
├── data/
├── domain/
└── presentation/

Do not create:

providers/
routes/
services/
models/
value_objects/
feature_module.dart

automatically.

Structure follows responsibility.

Example People Feature

A possible People feature structure is:

features/
└── people/
    │
    ├── data/
    │   ├── datasources/
    │   ├── dtos/
    │   ├── mappers/
    │   └── repositories/
    │
    ├── domain/
    │   ├── entities/
    │   └── repositories/
    │
    └── presentation/
        ├── screens/
        ├── widgets/
        ├── controllers/
        └── providers/

This is illustrative.

Do not create every listed directory until the People implementation requires it.

For example, if no mapper abstraction is required:

mappers/

should not exist.

If providers remain beside their responsible controllers and that structure is clearer:

providers/

may not be required.

The approved architecture defines boundaries.

It does not require empty folders.

Example Simple Feature

A simple approved presentation feature may use:

features/
└── workspace/
    └── presentation/
        ├── screens/
        └── widgets/

If Workspace later requires API-backed state, its structure may evolve intentionally.

Do not build data and domain infrastructure before the feature needs it.

Folder Creation Rule

Create a folder when:

A real implementation responsibility exists.
Multiple related files benefit from grouping.
The grouping improves navigation.
The folder name communicates responsibility.

Do not create a folder because:

Clean Architecture examples contain it.
A previous Atlas document listed it.
A generic SaaS template uses it.
An AI coding assistant prefers symmetry.
The folder may become useful someday.

Empty architecture is not scalability.

File Creation Rule

Create a file when it owns a clear responsibility.

Do not create files solely to keep every file extremely short.

Do not create one-class-per-file mechanically when tightly related private implementation can remain clear together.

Likewise, do not create giant files containing unrelated responsibilities.

Follow:

14_Engineering_Standards.md
Coding Standards.md

where applicable.

Responsibility and readability determine file boundaries.

Refactoring Structure

Folder structure may evolve when actual implementation reveals a better responsibility boundary.

Refactoring is allowed when:

Existing placement is genuinely confusing.
A feature has grown.
Shared responsibility has become clear.
A dependency boundary is being violated.

Do not restructure the entire project because:

A new coding trend appears.
An AI assistant recommends another architecture.
A generic Flutter article uses another structure.

Meaningful structural changes should be reviewed intentionally.

If a change affects approved architecture, update relevant documentation.

AI Coding Assistant Rules

AI coding assistants must not:

Rename Relvio to Atlas.
Create Atlas root directories or namespaces.
Create Flutter PostgreSQL access.
Create core/database/ for PostgreSQL.
Create desktop product architecture.
Create web product architecture.
Create Linux product architecture.
Create Windows product architecture.
Create macOS product architecture.
Create localization infrastructure without approval.
Create translation asset folders without approval.
Create Lottie folders by default.
Create generic animation asset folders by default.
Create every core directory from a template.
Create every shared component category in advance.
Create feature folders from the Feature Backlog.
Create more/ instead of workspace/.
Create separate top-level feature providers/ while presentation state is owned elsewhere.
Create both controllers and view models for the same responsibility.
Create a routes/ directory inside every feature.
Create a feature_module.dart file inside every feature.
Create repository interfaces mechanically.
Create use-case classes for every CRUD method.
Create value objects for every primitive.
Create DTOs and models with identical fields solely for architecture symmetry.
Place feature business logic in core.
Move feature widgets into shared without cross-feature responsibility.
Treat client organization filtering as tenant security.
Implement protected business rules only in Flutter.
Invent API endpoints.
Invent API fields.
Invent database structures.
Create empty architecture folders for future use.

When implementation requires a new folder or architecture boundary, the AI coding assistant must:

Identify the responsibility.
Check approved project documentation.
Place the code in the smallest appropriate existing boundary.
Create a new folder only when grouping improves clarity.
Avoid duplicate ownership.
Report genuine architecture conflicts.

The AI coding assistant is an implementation engineer.

Approved Relvio documentation defines architecture.

Source of Truth Priority

For Flutter folder organization:

Approved Relvio product decisions define product scope.
Approved architecture documentation defines system boundaries.
Folder Structure.md defines Flutter code organization.
Approved project structure documentation defines broader repository organization where applicable.
14_Engineering_Standards.md defines engineering rules.
Coding Standards.md defines code conventions where not superseded.
13_API_Specification.md defines API contracts.
16_Security.md defines security boundaries.
15_Testing_Strategy.md defines testing priorities.
Component Library.md defines shared and feature component responsibility.
Flutter Theme Implementation.md defines theme implementation.
Asset_Structure.md defines production asset organization.

If a genuine contradiction exists between approved documents, implementation must stop at the affected architecture decision and request clarification.

Do not silently choose one conflicting architecture.

Success Criteria

The Relvio Flutter folder structure is successful when:

Relvio remains the public product name.
Android and iOS remain the approved v1 platforms.
Flutter communicates only through the approved backend REST API for protected product data.
PostgreSQL remains inaccessible directly from Flutter.
Product features own feature-specific code.
Data, domain, and presentation responsibilities remain understandable.
The domain layer does not depend on the data layer.
Riverpod presentation state has clear ownership.
GoRouter configuration has clear ownership.
Shared code contains genuinely cross-feature responsibilities.
Core contains technical infrastructure rather than product business logic.
Empty architecture folders are avoided.
Backlog features are not pre-created.
Workspace replaces More.
Asset organization remains governed by Asset_Structure.md.
New engineers and AI coding assistants can locate code quickly.
The project can grow without requiring architecture ceremony for every simple feature.
Backend security and data integrity boundaries remain protected.
Final Principle

Relvio uses structure to clarify responsibility.

Not to display architectural complexity.

Create the smallest folder structure that preserves approved boundaries, keeps product code easy to find, and prevents implementation responsibilities from becoming mixed.