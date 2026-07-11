---
Document: Iconography
Version: 1.1
Status: Approved
Project: Relvio
Owner: Design Team
---

# Iconography

## Purpose

This document defines how iconography is interpreted and implemented throughout Relvio.

Icons support recognition, navigation, actions, status communication, and interface scanning.

Icons should support product meaning.

They must not become decorative noise or replace necessary text without a clear interaction reason.

The approved frozen Relvio v1 mobile UI remains the visual authority for icon selection, placement, scale, and presentation.

---

# Iconography Authority

The approved Relvio high-fidelity UI controls visible icon decisions.

Approved visual references determine:

- Which icon is shown
- Where the icon appears
- Relative icon size
- Visual weight
- Color responsibility
- Relationship to labels
- Relationship to containers
- Selected and unselected presentation
- Action meaning

This document does not authorize implementation teams or AI coding assistants to reinterpret approved icons using generic SaaS conventions.

If an icon shown in the approved UI cannot be confidently identified or reproduced with an approved implementation source:

1. Do not guess.
2. Do not replace it with a visually unrelated icon.
3. Do not create a custom icon automatically.
4. Report the unresolved icon requirement.
5. Wait for clarification or approval where the difference is visually or semantically significant.

---

# Design Philosophy

Relvio iconography should preserve the visual character of the approved UI.

Icons should feel:

- Clean
- Minimal
- Modern
- Calm
- Consistent
- Professional
- Easy to understand

Icons should communicate a recognizable interface responsibility.

Avoid decorative icon usage that adds no product meaning.

---

# Icon Source

The icon source used during Flutter implementation must be selected from the icon requirements visible in the approved Relvio UI.

This document does not independently approve:

- HugeIcons
- Lucide
- Phosphor
- Material Symbols
- A custom icon package

Do not install an icon dependency merely because it was recommended in an old Atlas draft.

Before selecting a primary Flutter icon library, implementation should verify that the library can reproduce the dominant approved Relvio icon language with sufficient visual fidelity.

The selected implementation source should minimize unnecessary icon-style mixing.

If one approved icon cannot be represented by the primary icon source, a controlled exception may be used when necessary.

The goal is visual consistency.

The goal is not an absolute technical rule that every icon must originate from one package regardless of fidelity.

Dependency selection must follow approved engineering and dependency rules.

---

# Approved Brand Assets Are Not Interface Icons

The Relvio logo and approved brand marks are brand assets.

They are not generic interface icons.

Approved Relvio logo assets must be used directly.

Do not:

- Recreate the Relvio logo with Flutter icon data
- Approximate the logo using generic icons
- Draw the logo with Flutter painting code
- Convert screenshots into replacement logo assets
- Treat the Relvio mark as part of a third-party icon library

Brand asset handling is controlled by:

- `Brand Assets.md`
- `Asset_Structure.md`
- `Logo_Strategy.md`

If a required approved brand asset is missing, report it.

Do not invent a replacement.

---

# Icon Style

The approved frozen UI determines the required icon style.

The dominant Relvio icon language should remain visually consistent.

Where reflected by the approved UI, prefer icon forms that feel:

- Minimal
- Visually balanced
- Clean
- Appropriately rounded
- Consistent in apparent weight

Do not mechanically mix substantially different visual styles.

Avoid uncontrolled combinations of:

- Heavy filled icons
- Thin outline icons
- Cartoon-style icons
- Skeuomorphic icons
- Decorative symbols
- Visually aggressive icon forms

Filled and outline states may coexist when the approved UI intentionally uses them to communicate state, selection, or hierarchy.

Do not remove an intentional approved filled or outline state merely to enforce a generic icon rule.

---

# Stroke and Visual Weight

Relvio does not define a universal `2px` icon stroke requirement.

Different icon implementations may use different vector construction and stroke behavior.

The implementation goal is consistent apparent visual weight relative to the approved UI.

Do not:

- Modify every icon to force a technical stroke width
- Rebuild third-party icons solely to normalize stroke values
- Assume equal numeric stroke width guarantees equal visual weight

Evaluate icon weight visually against the approved Relvio references.

If a selected icon source consistently conflicts with the approved visual language, the source should be reconsidered rather than individually redrawing large numbers of icons.

---

# Icon Size

Icon dimensions must follow verified approved UI requirements.

This document does not define a generic global icon scale.

Do not automatically create or enforce a scale such as:

- 16
- 20
- 24
- 32
- 48

unless those values are verified from approved Relvio design responsibilities and are genuinely repeated.

Repeated verified icon dimensions may be centralized where appropriate.

Unique intentional icon dimensions may remain local.

The goal is controlled consistency, not zero numeric literals.

`Design Tokens.md` and the approved frozen UI remain authoritative for verified design values.

---

# Icon Color

Icon color must follow the semantic and visual responsibility shown in the approved Relvio UI.

Approved color responsibilities are controlled by `Color System.md`.

Primary Relvio brand color:

`#2563FF`

Do not invent independent icon color values.

Icons may use approved responsibilities such as:

- Primary emphasis
- Primary text relationship
- Secondary or muted content
- Success feedback
- Warning feedback
- Error or destructive feedback
- Disabled presentation

The exact color must come from approved Relvio color responsibilities.

Avoid assigning arbitrary colors to icons for decoration.

Do not create a separate icon-only color system.

---

# Navigation Icons

Primary navigation icons must match the approved frozen Relvio mobile UI.

The approved primary bottom navigation label is:

**Workspace**

Do not use:

**More**

as the name of the primary navigation destination.

An overflow or ellipsis icon may still represent a contextual overflow action when the approved UI requires one.

The existence of an overflow action does not restore `More` as a primary navigation label.

Do not invent navigation icons or destinations from old Atlas documentation.

Navigation icon selection and selected-state behavior must follow the approved visual references.

---

# Action Icons

Action icons should communicate the approved action clearly.

Examples of general interface responsibilities may include:

- Add
- Edit
- Delete
- Search
- Filter
- Refresh
- Close
- Back
- Forward
- Expand
- Collapse
- Overflow

This list is illustrative.

It does not approve product actions.

An action icon must only be implemented when the underlying action is part of approved product behavior.

Do not add:

- Export
- Import
- Print
- Share
- Archive
- Restore
- Duplicate
- Download
- Upload

merely because an icon exists for the action.

Product documentation and approved UI determine whether an action exists.

---

# Status Icons

Status icons may support approved state communication.

Potential semantic responsibilities include:

- Success
- Warning
- Error
- Information
- Pending
- Completed

The presence of a status icon must reflect real product state.

Do not invent:

- Status models
- Workflow states
- Journey states
- Attendance states
- Follow-up states

from this document.

Product and backend documentation control state meaning.

Iconography only controls visual communication of approved states.

---

# Feature Icons

Feature-specific icons must be derived from approved Relvio UI and approved product scope.

Do not build a generic catalogue of icons for hypothetical modules.

This document does not approve icons or modules for:

- Billing
- API management
- Integrations
- Departments
- Branches
- Advanced analytics
- Custom reports
- Theme settings
- Appearance settings
- Relationship mapping

If a future feature is approved, its iconography should be reviewed as part of that feature's approved design responsibility.

---

# Empty-State Iconography

Empty states must follow the approved Relvio visual language.

An empty state may use:

- An approved icon
- An approved illustration asset
- Text without an illustration

Illustrations are not mandatory.

Do not invent illustration assets.

Do not generate new branded illustrations automatically.

Do not use an error icon to represent normal absence of content unless the approved design intentionally communicates an error.

Empty-state behavior is further governed by approved high-fidelity screen documentation and product behavior.

---

# Icon and Text Relationships

Icons should be paired with text where the icon alone may be ambiguous.

Icon-only controls are appropriate when:

- The action is conventionally recognizable
- The approved UI intentionally uses an icon-only control
- Accessibility meaning is provided
- The control remains understandable in context

Do not remove approved labels merely because an icon appears recognizable.

Do not add redundant labels that alter the frozen UI.

The approved high-fidelity screen remains the visual authority.

---

# Icon Spacing

Icon spacing must follow the approved Relvio UI and verified design responsibilities.

This document does not define universal spacing rules such as:

- Icon to text equals `8px`
- Icon to icon equals `16px`
- Icon to button edge equals `12px`

Repeated verified spacing responsibilities may be centralized where appropriate.

Unique intentional values may remain local.

Do not generate a generic spacing system from this document.

`Design Tokens.md`, `Component Library.md`, and approved visual references control spacing decisions.

---

# Interactive Icons

Interactive icon controls must reflect their actual state.

Relevant states may include:

- Default
- Pressed
- Focused
- Disabled
- Loading
- Selected

Only states required by the implemented interaction should be created.

Do not create decorative state variants without a product or accessibility purpose.

Interactive icon behavior must remain consistent with approved shared component responsibilities where applicable.

---

# Animation

Interactive icons may use subtle Flutter animation where it supports understanding.

Potential examples include:

- Chevron state transition
- Loading rotation
- Expand or collapse transition
- Selection transition

These examples do not approve new product interactions.

Simple icon animations should be implemented directly in Flutter where practical.

Do not add Lottie or Rive by default.

Icon animation should:

- Support state understanding
- Remain subtle
- Feel responsive
- Avoid unnecessary delay
- Avoid visual distraction

Do not animate icons solely to make the interface feel more active.

---

# Accessibility

Interactive icons must expose meaningful accessibility information.

The semantic meaning should describe the action or responsibility.

For example, an interactive destructive control should communicate the approved action it performs rather than exposing a generic description such as:

`Icon Button`

Accessibility meaning should be contextual.

Examples of semantic responsibilities may include:

- Go back
- Search people
- Close dialog
- Open notifications

These examples are illustrative and do not approve product actions or screens.

Decorative icons that provide no independent meaning should not create unnecessary screen-reader noise.

Accessibility implementation must follow Flutter accessibility practices and approved product meaning.

---

# Custom Icons

Custom interface icons should be minimized.

A custom icon may only be introduced when:

- The approved UI requires a visually specific icon
- Existing approved implementation sources cannot reproduce it with sufficient fidelity
- The icon represents an approved Relvio product responsibility
- The custom asset has been reviewed and approved

Do not create custom icons because an AI coding assistant prefers a different visual style.

Do not create a custom Relvio icon family during v1 implementation without explicit design approval.

Custom icon assets must follow approved asset documentation.

---

# Future Iconography

This document does not approve a future branded icon family.

Potential future product features must not cause icons to be pre-designed, pre-generated, or pre-added to Flutter.

Do not create speculative icons for:

- Journey expansion
- Follow-up expansion
- Organization features
- Growth features
- Community features
- Relationship mapping

Future approved features should define icon requirements through their approved product and design process.

---

# Flutter Implementation Rules

During Flutter implementation:

- Use the approved UI as the visual reference.
- Use approved centralized icon responsibilities where they genuinely exist.
- Keep icon source usage controlled.
- Preserve approved icon meaning.
- Preserve approved selected and unselected states.
- Use approved color responsibilities.
- Provide accessibility meaning for interactive icons.
- Report visually significant unresolved icons.

Do not:

- Install multiple icon packages without a verified requirement
- Select an icon library from the old Atlas draft automatically
- Replace approved icons with arbitrary Material icons
- Invent feature icons
- Invent icon token scales
- Invent icon spacing scales
- Recreate brand assets as icons
- Add speculative icons for future features

---

# AI Implementation Rules

Claude or another AI coding assistant acts as an implementation engineer.

AI must not independently:

- Choose a new icon design language
- Redesign approved icons
- Install HugeIcons because it appears in an old draft
- Install multiple icon packages for convenience
- Invent icon dimensions
- Invent icon spacing values
- Invent feature icons
- Create a branded icon family
- Recreate the Relvio logo
- Add product actions because matching icons are available

AI should compare the implementation against the approved Relvio UI.

If an approved icon requirement cannot be resolved confidently, AI must report the issue rather than inventing a replacement.

---

# Documentation Responsibilities

This document owns:

- Iconography implementation boundaries
- Icon consistency rules
- Icon source selection boundaries
- Icon accessibility expectations
- Custom icon governance

This document does not own:

- Product feature scope
- Product actions
- Navigation architecture
- Design token definitions
- Color definitions
- Shared component specifications
- Brand asset definitions
- Logo implementation
- Asset folder structure

Those responsibilities remain with their approved Relvio documents.

---

# Success Criteria

The Relvio icon system is successful when:

- Approved icons are reproduced faithfully
- Icon meaning remains clear
- Visual weight feels consistent
- Icon source usage remains controlled
- Approved product actions are not expanded through icon availability
- Brand assets are not recreated as interface icons
- Interactive icons are accessible
- Speculative feature icons are not introduced
- AI coding assistants report unresolved icon requirements instead of guessing
- Iconography remains consistent with the frozen Relvio v1 mobile UI

---

# End of Document