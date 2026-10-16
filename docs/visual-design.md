# Devventory Mobile — soft minimalism

The mobile companion keeps the desktop brand's navy and sky-blue accent, with a
softer, tactile presentation. This is a presentation-only interlude after Phase 2;
it does not add project browsing, metadata caching, notifications, or new auth APIs.

## Visual system

- Navy canvas `#0C121B`, raised surface `#162230`, inset field `#101A26`.
- Primary sky blue `#7DD3FC`, secondary cyan `#67E8F9`, solid button base `#3583AA`.
- Inter 4.1 is bundled in regular, medium, semibold, bold, and extra bold. No font
  is fetched at runtime. Original fonts and their SIL Open Font License come from
  the [official Inter release](https://github.com/rsms/inter/releases/tag/v4.1).
- Cards use 28dp corners and a restrained 32dp diffused shadow. Dialogs use 32dp;
  primary/secondary controls use 20dp; input fields use 18dp. This radius hierarchy
  keeps fields and actions distinct from larger surfaces.
- Page content is scrollable, safe-area aware, and capped at 480dp. Headings and
  the mascot adapt to available width and text scaling rather than shrinking text.

`lib/app/app_theme.dart` owns the Material theme. Shared visual tokens, `SoftCard`,
`CompanionHero`, `VentyMascot`, and `ActionButton` live in
`lib/shared/presentation`. Feature-specific content and recovery remain inside
the auth and workspace features.

## Tactile primary action

Use `ActionButton` for the main action in a flow. Secondary actions remain quiet
text or outlined buttons; not every control should compete for attention.

- The face rests above a solid 6dp base and travels down 6dp when pressed. The
  base shrinks to zero at full depression. Press/release use 90ms/160ms ease-out.
- The reserved base space and stationary hit target prevent layout jumps.
- Pointer-down starts visual feedback immediately, including inside a scrolling
  gesture arena. Flutter's real `FilledButton` still owns action activation,
  gesture cancellation, focus, keyboard behavior, and button semantics.
- Loading blocks duplicate activation, retains the label, and announces progress.
  Disabled actions are visually distinct. Focus has an explicit visible border.
- Reduced-motion preference removes translation and animating progress, retaining
  immediate color/depth feedback and a static progress symbol.
- Labels can wrap at large text sizes; controls have at least 48dp touch targets.

Framework references: [button background layers](https://api.flutter.dev/flutter/material/ButtonStyle/backgroundBuilder.html),
[widget states](https://api.flutter.dev/flutter/widgets/WidgetStatesController-class.html),
[pointer events](https://api.flutter.dev/flutter/widgets/Listener-class.html),
[reduced motion](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html),
and [bundled font weights](https://docs.flutter.dev/cookbook/design/fonts#declare-styles-and-weights).

## Venty

Venty is a pocket inventory robot: an icy-blue matte shell, navy visor, simple blue
eyes, rounded limbs, and a single drawer-shaped chest panel. The compact silhouette
connects the mascot to Devventory's inventory identity without implying an AI chat
feature. It is static, decorative, and excluded from screen-reader announcements;
adjacent text and icons convey the actual state.

The transparent illustration is bundled at `assets/mascot/venty-welcome.png` and
decoded at display resolution. The [asset provenance and complete generation
prompt](../assets/mascot/README.md) are preserved with it. One consistent welcoming
pose is used for now; expression variants and animation are not required for this
slice.

## UX decisions and boundaries

The user-named frontend/UI-UX skills guided persistent labels, visible focus,
generous targets, motion restraint, and grouping one primary action with its
feedback. Design Motion's Form Field States, Behind the Button, Empty States,
Animation Timing, and Easing Curves references informed state completeness and
quick feedback; the exact palette, dimensions, timing, and mascot are project
design choices, not claims imposed by those references.

Sign-in, verification, reset, startup/session waiting, and workspace connection
share the visual system. Existing validation, SDK authentication, token handling,
verification/reset outcomes, sign-out, discovery, retry rules, account isolation,
and lifecycle behavior remain intact. Empty/unpublished workspace, offline,
rate-limit, and expired-session states keep distinct explanations and recovery.
A linked desktop still does not claim that metadata is uploaded or cached.

## Verification

Results for this redesign are recorded in `phase-2-verification.md`. Widget tests
exercise 320dp with 2× text, 768dp, 1024dp, and 1440dp layouts; long account names;
keyboard-open password reset; target labels/sizes; and the tactile interaction.
The native Firebase journey uses only the local demo Auth emulator, never a
production account. iOS/device release acceptance remains a later phase.
