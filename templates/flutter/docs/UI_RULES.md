# UI Rules (Flutter)

Visual and widget rules for **{{PROJECT_NAME}}**. The goal: one consistent, accessible, responsive design system built from theme tokens and shared widgets. Starter values are neutral; brand values are recorded in `docs/DECISIONS.md` (ADR-006).

---

## 1. Design Tokens (single source of truth)

All visual values live in `lib/core/theme/`. Widgets read them from `Theme.of(context)` or the token extensions. **No hardcoded colors, text styles, radii, spacing or durations in widgets.**

| Token group | File | Rule |
|---|---|---|
| Colors | `color_tokens.dart` | Define a `ColorScheme` (light and dark) plus a `ThemeExtension<AppColors>` for semantic colors (`success`, `warning`, `info`, `*Soft` tints). Use `Theme.of(context).colorScheme.*` first. |
| Typography | `text_styles.dart` | One `TextTheme`. Use `textTheme.titleLarge`, `bodyMedium`, etc. Never `TextStyle(fontSize: 14)` inline. |
| Spacing | `spacing.dart` | 4 dp scale: `xs 4, sm 8, md 12, lg 16, xl 24, xxl 32`. Use `AppSpacing.md`, never magic numbers. |
| Radius | `app_theme.dart` | `AppRadius.sm 8, md 12, lg 16, pill 999`. |
| Elevation / shadow | `app_theme.dart` | Prefer surface tint and borders; shadows via tokens only. |
| Motion | `app_theme.dart` | `AppDurations.fast 150ms, normal 250ms`; standard `Curves.easeOut`. |

Search check before every PR: no `Color(0x...)`, `Colors.red`, `fontSize:` or `EdgeInsets.all(<number>)` outside `lib/core/theme/` (use a token). Exception: `0` and `Colors.transparent`.

---

## 2. Theme

- Material 3 (`useMaterial3: true`) with a seed or explicit `ColorScheme`; component themes (`FilledButtonTheme`, `InputDecorationTheme`, `CardTheme`, `AppBarTheme`) set once in `app_theme.dart`.
- Light and dark themes are both required and tested. `ThemeMode.system` by default.
- Fonts bundled or via `google_fonts` with caching disabled risk reviewed; declare fonts in `pubspec.yaml`.
- Icons from one set (Material Symbols or the set chosen in ADR-006). No mixing icon packs.

---

## 3. Shared Widgets (reuse before creating)

| Need | Use |
|---|---|
| Buttons (primary, secondary, ghost, icon, loading) | `AppButton` |
| Text input with label, helper, error | `AppTextField` |
| Card / surface | `AppCard` |
| Loading / empty / error / content | `StateBuilder` with `LoadingView`, `EmptyView`, `ErrorView` |
| Page scaffold with safe area, padding, app bar | `AppScaffold` |
| Dialogs and confirmations | `showAppDialog`, `ConfirmDialog` |
| Snackbars and toasts | `AppSnackbar` |
| Lists with pull-to-refresh and pagination | `PaginatedListView` |

Rules:

- A new screen should be mostly composition of shared widgets and feature widgets.
- Extract a shared widget on the **second** use. Shared widgets live in `lib/shared/widgets/`, are `const`-friendly, take only data and callbacks, and have a widget test and a golden test.
- Use widget classes, not `Widget _buildX()` helper methods.

---

## 4. Responsive and Adaptive Layout

- Design for **360 dp** minimum width up to tablets and foldables. No fixed widths for content; use `Expanded`, `Flexible`, `LayoutBuilder`, `ConstrainedBox`.
- Breakpoints in `lib/shared/layout/breakpoints.dart`: compact < 600, medium 600 to 840, expanded > 840. Switch layouts at breakpoints (navigation bar -> rail -> drawer), not per device model.
- No overflow errors in any supported width, orientation or text scale. Wrap scrollable content; never put unbounded children in a `Column` without scrolling.
- Respect safe areas, notches, keyboard insets (`resizeToAvoidBottomInset`, scroll to focused field).
- Touch targets at least 48 x 48 dp with 8 dp spacing.
- Use `MediaQuery.sizeOf(context)` (not `MediaQuery.of`) to avoid unnecessary rebuilds.

---

## 5. Accessibility

- Text scales to at least 200% without clipping; never fix text container heights.
- Contrast at least 4.5:1 for body text and 3:1 for large text and icons, in light and dark themes.
- Every interactive widget has a semantic label (`Semantics`, `tooltip`, `semanticLabel`); decorative images are excluded from semantics.
- Logical focus order; all actions reachable by keyboard/switch control on tablets and desktop.
- Do not convey meaning by color alone; pair with icon or text.
- Respect reduced motion (`MediaQuery.disableAnimations`).

---

## 6. States and Feedback

Every screen that loads data handles all of: **loading** (skeleton or progress), **empty** (message plus primary action), **error** (message plus retry) and **offline**. Forms show inline validation and disable the submit button while submitting. Destructive actions confirm first. Success feedback is a snackbar, not a blocking dialog.

---

## 7. Forms

- Validators are pure functions in `core/utils/validators.dart`, shared between forms; messages come from localization.
- `TextInputType`, `textInputAction`, `autofillHints` and capitalization are set on every field.
- Validate on blur or submit, not on every keystroke (except password strength meters).
- Dispose all controllers and focus nodes.

---

## 8. Navigation

- `go_router` with route constants in `core/router/routes.dart`; no string literals in widgets.
- Auth redirects live in the router `redirect`, not scattered in pages.
- Support the Android back button and iOS swipe back; confirm before discarding unsaved changes.
- Deep links map to routes and validate their parameters.

---

## 9. Localization and Copy (Centralized Dictionary)

- **Single source of truth:** All words, button labels, navigation items, dialog titles, validation messages, and error messages live in `lib/l10n/app_en.arb` (and `app_es.arb` for translations), accessed via `AppLocalizations.of(context)`.
- **Zero hardcoded strings:** Never write raw strings or error messages in widgets, BLoCs, or mappers.
- **Single place to update text:** Developers can update any word, error message, or label across the entire app by editing `lib/l10n/app_en.arb`.
- **Language switching:** To switch languages, update the app locale via `Locale('es')` in `MaterialApp.router`.
- Use ICU plurals and placeholders; never concatenate translated fragments.
- Format dates, numbers and currency with `intl` using the active locale.
- No emojis in UI text, comments or commit messages.

---

## 10. Images, Assets and Icons

- Declare assets in `pubspec.yaml`; reference through generated constants (`flutter_gen` or a const class), never raw string paths.
- Provide `1x/2x/3x` bitmaps or prefer SVG for icons and illustrations.
- Network images use a caching widget with placeholder and error builders and explicit size.
- Launcher icon and splash generated from one source asset.

---

## 11. Review Checklist (UI)

- [ ] Only theme tokens and shared widgets used; token search check passes
- [ ] Light and dark verified
- [ ] 360 dp phone, tablet and landscape verified; no overflow; large text scale (200%) verified
- [ ] Loading, empty, error and offline states present
- [ ] Semantics labels, contrast and 48 dp targets verified
- [ ] Strings localized; no hardcoded text
- [ ] Widget (and golden, if shared) tests added
