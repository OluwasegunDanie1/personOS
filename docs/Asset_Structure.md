---
Document: Asset Structure
Version: 1.1
Status: Approved
Project: Relvio
Owner: Engineering & Design
---

# Asset Structure

## Purpose

This document defines how visual assets, icons, illustrations, fonts, images, and animation assets are organized within the Relvio project.

The goal is to keep assets predictable, reusable, optimized, and easy for developers and AI coding assistants to locate.

This document is the source of truth for asset organization.

---

# Asset Principles

Relvio assets must be:

- Organized
- Reusable
- Optimized
- Predictably named
- Easy to locate
- Production-ready

Avoid duplicate assets.

Do not create multiple versions of the same asset without a documented reason.

---

# Flutter Asset Structure

The approved Flutter asset structure is:

```text
assets/
├── branding/
│   ├── logos/
│   │   ├── relvio_logo_primary.svg
│   │   ├── relvio_logo_horizontal.svg
│   │   ├── relvio_logo_stacked.svg
│   │   ├── relvio_symbol.svg
│   │   ├── relvio_logo_white.svg
│   │   └── relvio_logo_black.svg
│   │
│   ├── app_icon/
│   │   ├── relvio_app_icon.png
│   │   ├── relvio_app_icon_foreground.png
│   │   └── relvio_app_icon_background.png
│   │
│   ├── favicon/
│   │   └── relvio_favicon.svg
│   │
│   └── splash/
│       └── relvio_splash_logo.svg
│
├── icons/
│   └── custom/
│
├── illustrations/
│   ├── onboarding/
│   ├── empty_states/
│   ├── errors/
│   └── system/
│
├── images/
│   ├── avatars/
│   ├── placeholders/
│   ├── event_covers/
│   └── demo/
│
├── animations/
│
└── fonts/



Folders should only contain production assets used by the application.

Do not create empty asset categories simply because they may be useful in the future.

Branding Assets

The branding/ directory contains approved Relvio brand assets.

These assets are controlled brand files.

They must not be recreated from screenshots.

They must not be approximated using Flutter widgets, text, icons, or custom drawing code.

Logo Assets

Approved logo files belong in:

assets/branding/logos/

Expected assets include:

relvio_logo_primary.svg
relvio_logo_horizontal.svg
relvio_logo_stacked.svg
relvio_symbol.svg
relvio_logo_white.svg
relvio_logo_black.svg

Only include a logo variation when the approved asset actually exists.

Do not generate fake logo variations to satisfy this file list.

If an expected logo asset is unavailable, report the missing asset.

The approved logo rules are defined in:

20_Logo_Strategy.md
Logo Source Rule

The approved Relvio logo is a fixed brand asset.

Developers and AI coding assistants must:

Locate the approved logo asset.
Use the asset directly.
Preserve the aspect ratio.
Follow the documented logo usage rules.
Report missing assets.

Never:

Trace the logo from a UI screenshot
Recreate the logo with Flutter CustomPainter
Replace the symbol with a typed R
Approximate the logo with an icon
Redesign the logo
App Icon Assets

Application icon source assets belong in:

assets/branding/app_icon/

The app icon is based on the approved Relvio brand symbol.

Source files may include:

relvio_app_icon.png
relvio_app_icon_foreground.png
relvio_app_icon_background.png

Platform-generated launcher icons should remain in their respective Android and iOS platform directories.

Do not manually duplicate every generated launcher icon inside assets/.

The assets/branding/app_icon/ directory stores source assets only.

Favicon

The approved favicon source belongs in:

assets/branding/favicon/

Preferred file:

relvio_favicon.svg

Flutter Web generated or platform-specific favicon files may remain inside the web platform directory where required.

Splash Assets

Splash branding assets belong in:

assets/branding/splash/

The splash screen uses the approved Relvio identity.

The splash asset must not include the complete screen background as one large screenshot.

Flutter should implement:

Background
Positioning
Responsive layout
Animation

The asset should contain only the approved brand artwork required by the splash experience.

Icons

Relvio should prefer a consistent Flutter-compatible icon system for standard interface icons.

Standard icons should not be exported as individual image assets unless required by the design.

Examples include:

Search
Filter
Calendar
Person
Settings
Chevron
Close
Add
Edit

These should use the approved icon package or icon system selected during implementation.

Custom Relvio-specific icons belong in:

assets/icons/custom/

Use SVG for custom vector icons whenever practical.

Do not mix multiple icon styles without an approved design reason.

Custom Icon Requirements

Custom icons must:

Match the Relvio visual language
Use consistent stroke treatment
Scale cleanly
Remain recognizable at mobile sizes
Be optimized before inclusion

Custom icons should not be created when an approved standard icon already communicates the action clearly.

Illustrations

Illustration assets belong in:

assets/illustrations/

Approved categories are:

onboarding/
empty_states/
errors/
system/
Onboarding Illustrations

Onboarding assets belong in:

assets/illustrations/onboarding/

These may include connected orbital systems, product icons, nodes, and relationship paths.

The downloaded high-fidelity UI screens are visual references.

They are not production illustration assets.

Do not crop illustrations directly from UI screenshots for application use.

Production illustrations should be exported or recreated as dedicated approved assets.

Empty State Illustrations

Empty-state assets belong in:

assets/illustrations/empty_states/

Examples may include:

empty_people.svg
empty_events.svg
empty_messages.svg
empty_notifications.svg
empty_reports.svg

Only add assets for implemented product states.

Do not generate unused empty-state artwork in advance.

Error Illustrations

Error-state assets belong in:

assets/illustrations/errors/

Possible assets include:

offline.svg
server_error.svg
not_found.svg

Error-state behavior may be implemented during development.

Dedicated illustration assets are optional unless required by the approved design.

Do not block feature development because an optional error illustration is unavailable.

System Illustrations

System-level product illustrations belong in:

assets/illustrations/system/

Examples include:

Organization ready state
Setup completion state
Success illustrations
Relationship system graphics

These assets should follow the approved Relvio design language.

Images

Image assets belong in:

assets/images/

Approved categories are:

avatars/
placeholders/
event_covers/
demo/
Avatars

Demo or development avatar assets belong in:

assets/images/avatars/

These are intended for:

Local development
UI previews
Demo data
Testing

Production user profile photos should come from the configured storage system.

Do not bundle real customer profile images into the application.

Placeholders

Placeholder assets belong in:

assets/images/placeholders/

Examples include:

avatar_placeholder.svg
event_cover_placeholder.svg
organization_logo_placeholder.svg

Prefer lightweight vector placeholders where appropriate.

Event Covers

Bundled demonstration event covers belong in:

assets/images/event_covers/

Production event covers should be loaded from remote storage.

Bundled event covers should only support:

Demo mode
Development
Testing
Approved default templates
Demo Assets

Demo-specific assets belong in:

assets/images/demo/

Demo assets must not be confused with production customer data.

Do not place temporary screenshots or random development images in this directory.

Fonts

Font assets belong in:

assets/fonts/

The approved Relvio product typeface is:

Inter

Only required font weights should be bundled.

Do not include every available Inter font file automatically.

The implementation should include only the weights required by the approved typography system.

Font usage rules are defined in:

Typography.md

Only licensed fonts may be committed to the repository.

Animations

Animation assets belong in:

assets/animations/

Relvio animations should preferably be implemented directly in Flutter when the motion is simple.

Examples include:

Fade transitions
Scale transitions
Button feedback
Shimmer loading
Skeleton loading
Progress movement
Logo reveal
Node appearance

Do not create animation files for interactions that Flutter can implement cleanly.

External animation formats should only be introduced when a specific approved animation requires them.

Do not add Lottie or Rive as a dependency by default.

Adding an animation dependency requires an engineering decision.

UI Reference Screens

Downloaded high-fidelity Relvio UI screens are design references.

They should not be stored inside the Flutter production assets/ directory unless there is a documented development reason.

Recommended project documentation location:

docs/ui_reference/

or:

design/ui_reference/

These files may be used by developers and AI coding assistants to understand:

Layout
Spacing
Visual hierarchy
Component composition
Screen structure

They must not be displayed directly as application screens.

Do not implement Relvio by placing full-screen UI screenshots inside Flutter.

Asset File Naming

All asset filenames must use:

snake_case

Good examples:

relvio_symbol.svg
empty_people.svg
avatar_placeholder.svg
sunday_service_cover.webp
organization_ready.svg

Avoid:

logo-new-final2.png
RelvioLogo.svg
image1.png
test.png
new_logo_latest.svg
final-final-logo.png

Filenames should describe the asset clearly.

Image Formats

Use the following format guidance.

SVG

Preferred for:

Logos
Custom icons
Illustrations
Simple vector graphics
Placeholders
PNG

Use for:

Transparent raster assets
App icon source files
Assets requiring lossless raster output
WebP

Preferred for:

Event covers
Demo images
Product imagery
Optimized bundled raster images
JPEG

Use primarily for photography when WebP is not appropriate.

Screenshot Rule

Screenshots are documentation and reference assets.

Do not use screenshots as production UI assets.

Do not crop:

Buttons
Cards
Inputs
Navigation bars
Icons
Text
Forms

from screenshots and place them inside the Flutter application.

These elements must be implemented as Flutter widgets.

Asset Optimization

Every production asset must be optimized before inclusion.

Check:

File size
Image dimensions
Transparency
Compression
Visual quality

Avoid bundling unnecessarily large files.

Large source artwork should not automatically be included in the application package.

Duplicate Asset Rule

Before adding an asset:

Search the existing asset directories.
Check whether an equivalent asset already exists.
Reuse the existing asset when appropriate.
Add a new asset only when it has a distinct purpose.

Do not create duplicate files with different names.

Asset Versioning

Git provides version history for production assets.

Do not archive old asset versions inside the active Flutter asset directories.

Avoid:

relvio_logo_old.svg
relvio_logo_v2.svg
relvio_logo_final.svg
relvio_logo_final_new.svg

When an approved asset is replaced:

Replace the source asset.
Preserve the canonical filename when appropriate.
Commit the change.
Document major brand changes in the Decision Log.

Historical assets may be stored outside the active application asset structure when required.

Flutter Asset Registration

Asset directories must be registered correctly in:

pubspec.yaml

Do not register undocumented temporary folders.

Only production asset paths required by the application should be included.

Centralized Asset References

Flutter code must reference application assets through centralized constants.

Example:

abstract final class AppAssets {
  static const String relvioSymbol =
      'assets/branding/logos/relvio_symbol.svg';

  static const String emptyPeople =
      'assets/illustrations/empty_states/empty_people.svg';

  static const String avatarPlaceholder =
      'assets/images/placeholders/avatar_placeholder.svg';
}

Use:

AppAssets.relvioSymbol

Avoid:

'assets/branding/logos/relvio_symbol.svg'

throughout feature widgets.

Asset Constant Rules

Asset constants should:

Use camelCase
Describe the asset clearly
Point to one canonical asset path
Remain centralized

Do not create separate asset constant classes inside every feature unless there is a documented architectural reason.

Missing Asset Rule

If implementation requires an asset that does not exist:

Confirm the asset is required by the approved design.
Search the approved asset structure.
Check the brand asset documentation.
Report the missing asset.

Do not invent a replacement.

Do not download random artwork.

Do not recreate approved brand assets from screenshots.

Standard Flutter UI icons may use the approved icon system and are not considered missing brand assets.

AI Coding Assistant Guardrail

Before using an asset, AI coding assistants must:

Inspect the documented asset structure.
Locate the existing asset.
Confirm its intended purpose.
Use the centralized asset reference.
Preserve approved brand assets.

AI coding assistants must not:

Invent asset paths
Create duplicate assets
Recreate the Relvio logo
Crop UI screenshots into assets
Add random internet images
Add animation dependencies without approval
Generate unused placeholder assets
Rename approved assets without updating documentation and references

If a required approved asset is missing, report it before implementation.

Git Rules

Commit only production-ready application assets.

Do not commit to active asset directories:

Temporary exports
Design experiments
AI prompt files
Scratch artwork
Full UI reference screenshots
Duplicate files
Unoptimized source files

Use appropriate documentation or design directories for non-production references.

Related Documents

This document should be used together with:

19_Brand_Identity.md
20_Logo_Strategy.md
Brand Assets.md
Color_System.md
Typography.md
Iconography.md
Design_Tokens.md

These documents define the visual rules governing Relvio assets.

Success Criteria

The Relvio asset structure is successful when:

Every production asset has a predictable location.
Approved brand assets are protected.
Asset naming is consistent.
Duplicate assets are avoided.
Flutter code uses centralized asset references.
UI screenshots remain references rather than production assets.
Developers can locate assets quickly.
AI coding assistants do not invent or recreate approved assets.
The application package contains only necessary production assets.