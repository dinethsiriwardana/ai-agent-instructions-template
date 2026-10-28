# UI_RULES.md - Visual and Component Rules

> Read together with `AGENTS.md`. This file defines **how things look**; `AGENTS.md` defines **how code is structured**.
> Stack: Next.js + Tailwind CSS 4 + **owned components** (no runtime UI kit such as MUI, Chakra or Ant).
> Never hardcode colors, radii, shadows or font sizes. Use the tokens below only.
> Reuse existing shared components before creating new ones.
> **Mobile compatibility is mandatory**: every screen, modal, table, form and component must work on mobile viewports (320px and up) as well as desktop. Desktop-only views are prohibited.

---

## 1. Visual Character

- **Soft, airy, modern.** White rounded cards floating on a very light tinted page background.
- Hairline borders, very soft shadows, generous whitespace. No heavy borders, no hard shadows.
- One **primary** color for actions and active states, **semantic colors** for meaning, neutrals for everything else.
- Every colored element uses a **tint** (role color at low opacity) as background and the full color for icon and text. Never a saturated fill on large areas.
- Data is the hero: big bold numbers, small muted labels.

### 1.1 Professional tone

- **No emojis anywhere**: UI text, buttons, toasts, empty states, placeholders, alt text, code comments, commit messages. Use icons from the project icon set.
- No decorative unicode symbols as icons (stars, arrows, checkmarks in text). Use real icons.
- Copy is clear, neutral and business-like. No slang, no exclamation marks except in a greeting, no marketing hype.
- Sentence case for labels, buttons and headings (not ALL CAPS, except short table headers or badges).
- Error messages say what happened and what to do next, without blaming the user.
- Keep motion and illustration restrained: no bouncing, confetti or novelty effects.
- Use the formal register of the project locale for customer-facing text (set in `docs/PROJECT_PLAN.md`, section "Localization").

---

## 2. Design Tokens

Tokens live in `src/app/globals.css` (`:root` variables, exposed to Tailwind via `@theme inline`). Components reference **role names only**. Changing `--primary` re-themes the whole UI.

### 2.1 Color roles

| Token | Purpose | Starter value |
|---|---|---|
| `background` | Page canvas (very light) | `#f8fafc` |
| `surface` | Cards, sidebar, inputs | `#ffffff` |
| `surface-muted` | Table header, progress track, row hover | `#f1f5f9` |
| `border` | Hairline dividers, card outlines | `#e2e8f0` |
| `foreground` | Headings, key numbers | `#0f172a` |
| `muted-foreground` | Labels, captions, placeholders, inactive nav | `#64748b` |
| `primary` / `primary-soft` | Active nav, primary buttons, links, main chart line | **Set per project** (starter: `#00965f`) |
| `success` / `success-soft` | Completed, positive, paid | emerald family |
| `warning` / `warning-soft` | Pending, caution | amber family |
| `danger` / `danger-soft` | Errors, overdue, negative | rose/crimson family |
| `info` / `info-soft` | Neutral highlights | sky/blue family |
| `accent-1..5` | Extra chart categories | distinct hues, defined once |

Notes:

- Starter values are a neutral slate base plus an emerald primary. Replace `primary` with the project brand color on day one and record it in `docs/DECISIONS.md`.
- `danger` must stay visually distinct from `primary`. If the brand primary is in the red family, shift `danger` to a deeper crimson and always pair it with an icon or text. Never rely on color alone to signal an error.
- **Soft tint rule:** `*-soft` = role color at about 10 to 14% over `surface`, via `color-mix(in srgb, var(--x) 12%, var(--surface))`. Never a separate hand-picked hex.
- **Stat card background:** faint gradient from `surface` (top-left) to the tone's `*-soft` (bottom-right).
- **Chart series order:** `primary`, `success`, `warning`, `danger`, `accent-1..5`. Never invent colors.

### 2.2 Radius

| Token | Value | Use |
|---|---|---|
| `radius-xs` | 3px | Inner elements, small tags, sub-indicators |
| `radius-sm` | 4px | Badges, chips, inner input elements |
| `radius-md` | 6px | Buttons, inputs, nav items, list rows |
| `radius-lg` | 8px | Dropdowns, tooltips, nested cards |
| `radius-xl` | 10px | Standard cards, sections |
| `radius-2xl` | 12px | Prominent cards, feature blocks |
| `radius-3xl` | 16px | Page containers, sidebar, modals |
| `radius-full` | 9999px | Avatars, icon chips, progress bars, pills |

### 2.3 Shadow

`shadow-card` (default card, about 4 to 6% opacity, large blur), `shadow-pop` (dropdowns, tooltips, popovers), none inside tables, rows and nested elements.

### 2.4 Spacing (4px base)

- Page padding 24px desktop, 16px mobile. Gap between cards 20 to 24px. Card padding 20px.
- Inside a card: header to content 16px, between rows 12 to 16px.
- Scale: 4, 8, 12, 16, 20, 24, 32. No arbitrary values.

### 2.5 Typography

One family, loaded via `next/font` (starter: `Inter Tight`; change once per project). Tabular numbers (`tabular-nums`) for all figures.

| Role | Size / Weight | Color |
|---|---|---|
| Page title / greeting | 24 / 600 | `foreground` |
| Subtext | 14 / 400 | `muted-foreground` |
| Card title | 16 / 600 | `foreground` |
| **Stat value** | 28 / 700 | `foreground` |
| Label | 14 / 500 | `muted-foreground` |
| Body / list primary | 14 / 500 | `foreground` |
| Caption | 12 / 400 | `muted-foreground` |
| Badge | 12 / 500 | role color |
| Table header | 12 / 500 | `muted-foreground` |
| Link | 13 / 500 | `primary` |

All formatting (currency, number, percent, date, duration, relative time) goes through `src/shared/lib/format.ts`. Never inline. Locale and currency come from config.

### 2.6 Icons

One icon set for the whole project (pick one, add the dependency once), 1.5 to 2px stroke. Nav 20px, inline 16px, chip glyph 20 to 24px.
**Icon chip:** 40 to 44px circle, `*-soft` background, glyph in the full role color.

---

## 3. App Shell

- `DashboardLayout` lives in `src/shared/components/templates/`. Pages supply content only; never rebuild the shell.
- **Sidebar:** fixed about 220px, `surface`, `radius-xl`, `shadow-card`, floating with margin. Logo on top, nav below.
- **Nav item:** 44px, `radius-md`. Active: `primary-soft` background, `primary` icon and label, weight 600. Hover: `surface-muted`.
- **Top bar:** search input, notification button (small `danger` dot), avatar menu.
- **Grid:** 12 columns. Stat row = 4 equal columns; below, main (8) and side (4).
- **Breakpoints:** `lg+` full layout; `md` icon sidebar or drawer, stats 2x2, columns stack; `sm` drawer, single column, tables scroll or become card lists.
- **Mobile shell:** below `md` the sidebar collapses into a slide-over drawer or sheet. Top bar search and actions wrap or collapse into overflow menus; never clip or cause page-level horizontal overflow.

---

## 4. Components

Shared components live in `src/shared/components/` (`ui/` primitives, `common/` composites, `forms/`, `templates/`). Use these names, extend via props, never copy. If a component is missing, create it with tokens and **add its spec here**.

| Component | Spec |
|---|---|
| `Card` / `CardHeader` | `surface`, `radius-xl`, `shadow-card`, faint 1px `border`, padding 20. Header = title left, action slot right. |
| `StatCard` | Icon chip + chevron, label, big value, trend. Props: `label`, `value`, `icon`, `tone`, `trend`, `href?`. Gradient background. Clickable if `href`. Hover: deeper shadow, no movement. |
| `TrendBadge` | `radius-sm` pill, `*-soft` background, arrow + percent + muted comparison text. Explicit `sentiment` prop (up is not always good). |
| `Badge` / `StatusBadge` | `radius-full`, 12/500, padding 4x10, `*-soft` background. Map via one shared `statusToTone` / `categoryToTone`. |
| `Button` | Primary: `primary` fill, white text, `radius-md`, 40px, hover darker, focus ring `primary` 40%. Secondary: `surface` + `border`. Ghost. Icon button: 40px. Disabled 50%. Loading: inline spinner, keep width. |
| `Input` / `Select` / `Textarea` / `Checkbox` / `DatePicker` | `surface`, 1px `border`, `radius-lg`, 40 to 44px, leading icon allowed. Compact selects 36 to 40px, `radius-md`. Focus ring `primary`. |
| `ChartCard` | Title, subtitle, period select, loading and empty states. Responsive container always. |
| `ProgressItem` | Icon chip, title, `value / target`, percent, 8px bar on `surface-muted`. Fill by threshold (shared helper): high `success`, mid `warning`, low `danger`. |
| `ActivityItem` | Icon chip, title 14/500 + caption, value right, sign colored. Header has a "View all" link. |
| `DataTable` | No outer border. Header `surface-muted`, `radius-md`. Rows 56px, faint divider, hover `surface-muted`. Badges for status. Right-aligned numbers. Skeleton, empty state, pagination and horizontal scroll built in (`overflow-x-auto` wrapper with scroll indicator, or responsive card stack on mobile). |
| `Modal` | Backdrop dim + blur, `radius-3xl`, `shadow-pop`, focus trap, Esc closes. Mobile: `w-[calc(100vw-32px)]` or full-width bottom sheet, scrollable body (`max-h-[85vh] overflow-y-auto`), sticky action footer. |
| `ConfirmDialog` | Modal variant for destructive actions: title, consequence text, secondary cancel, `danger` confirm. |
| `InsightBanner` | `primary-soft`, `radius-xl`, icon left, headline, primary button right; stacks on mobile. |
| `EmptyState` / `StateBoundary` | See section 5. |
| `Toast` | `surface`, `radius-lg`, `shadow-pop`, icon + message, auto-dismiss 5s, `aria-live="polite"`. |

**Charts:** pick one chart library when first needed and wrap it in `ChartCard`. Line/area: `primary` 2px line, vertical gradient fill (about 15% to transparent), hidden dots except latest or hovered. Bar: rounded tops (4px), narrow bars. Donut: gapped ring with total in the center and a legend below. No axis lines, hairline `border` horizontal grid, 12px muted ticks, abbreviated y-values, tooltip `surface` + `radius-lg` + `shadow-pop`.

---

## 5. States and Interaction

| State | Rule |
|---|---|
| Loading | Skeletons matching the final layout (same radius and heights), shimmer on `surface-muted`. No full-page spinners. |
| Empty | `EmptyState`: centered icon chip, title, muted description, optional primary action. |
| Error | `StateBoundary`: inline in the card, danger icon chip, message, "Retry" ghost button. |
| Hover | Cards deeper shadow, rows `surface-muted`, buttons darker. 150ms ease. |
| Focus | Visible 2px `primary` ring (40%) on every interactive element. Never remove outlines. |
| Selected | `primary-soft` background + `primary` text. |
| Disabled | 50% opacity, `cursor-not-allowed`. |

Motion is subtle (150 to 250ms) and respects `prefers-reduced-motion`.

---

## 6. Content and Accessibility

- Signed values (money, deltas) always show `+` or `-` in lists.
- Long text truncates with ellipsis in lists. Tables never wrap category or status text.
- Meaningful icons have an accessible label; decorative icons are `aria-hidden`.
- Color is never the only indicator: pair with icon, sign or text.
- Body text contrast at least 4.5:1 on `surface`.
- Every form control has a visible label or an `aria-label`; errors are linked via `aria-describedby`.
- Keyboard: all interactive elements reachable and operable; modals trap focus and restore it on close.
- If i18n is enabled in `docs/PROJECT_PLAN.md`, all user-visible text goes through the project dictionary (one translation helper, one dictionary file per locale). No hardcoded strings.

---

## 7. Checklist for a New Page

1. Wrap in `DashboardLayout` (or the matching template).
2. Greeting header (shared `getGreeting()`), then 4-up `StatCard` row, then main (8) and side (4), where the page type fits.
3. Choose components only from section 4; otherwise create and document one.
4. Search for raw hex, `rgb()` and arbitrary Tailwind colors or values before finishing. There must be none in new code.
5. Provide loading, empty and error states for every data-driven card.
6. Verify at mobile (375px), tablet (`md`) and desktop (`lg+`), plus 320px as the minimum. Ensure zero horizontal page overflow, comfortable tap targets and functional dialogs and forms.
7. Respect file size limits from `AGENTS.md`; compose from small components in `features/<name>/components/`.

---

## 8. Do / Do Not

**Do:** soft tints, rounded cards, generous spacing, one primary, big bold figures, muted secondary text, consistent icon chips, mobile-first layouts, minimum 44px tap targets, mobile-adapted modals and tables.

**Do not:** hardcode colors, use pure black or heavy borders, stack many saturated colors in one card, mix radius values, use hard shadows, invent chart colors, use a second font family, build a new card, table or badge when a shared one exists, assume desktop-only layouts, allow horizontal page overflow on mobile, make tap targets smaller than 40px, or add more global CSS classes (new components use Tailwind utilities mapped to tokens).

---

## 9. Theming

Tokens are semantic: a dark theme needs only a second value set under `.dark` or `[data-theme="dark"]`. No dark-specific styles inside components.

---

## 10. Mobile Responsiveness and Touch Rules

Every view and component must work on mobile viewports (320px to 430px) as well as tablets and desktop.

### 10.1 Layout and viewport safety

- **Zero horizontal scroll on body.** No page or container may introduce horizontal scrolling to the viewport. Never use fixed widths (for example `w-[600px]`); use max-widths (`max-w-xl w-full`).
- **Responsive padding:** 16px (`p-4`) on mobile, stepping up to 20 to 24px (`sm:p-5`, `md:p-6`).
- **Flexible header actions:** title plus button bars stack on mobile (`flex-col gap-3 sm:flex-row sm:items-center sm:justify-between`). Primary CTAs may stretch full width on mobile for thumb reach.
- **Grid stacking:** multi-column grids collapse to a single column on small screens (`grid-cols-1 md:grid-cols-2 lg:grid-cols-4`).

### 10.2 Touch targets and ergonomics

- Minimum touch target 44x44px (or 40px with a generous hit area) for buttons, icon triggers, tabs, pagination items and checkboxes.
- Keep at least 8px between adjacent interactive elements.
- Inputs and selects are 40 to 44px tall with `text-sm` or `text-base` (at least 16px on iOS inputs to avoid auto-zoom).

### 10.3 Tables and data display

- Tables with more than 2 to 3 columns must either:
  1. wrap in an `overflow-x-auto` container with a visible scroll indicator, or
  2. switch to a stacked card list on mobile (`block md:table`).
- **Stat cards** stack into 1 or 2 columns (`grid-cols-1 sm:grid-cols-2 lg:grid-cols-4`). Use responsive font sizes (`text-2xl sm:text-3xl`) so large numbers do not clip.

### 10.4 Modals, drawers and dialogs

- Modals fit the viewport (`w-[calc(100vw-32px)]` or full-width sheet) with `max-h-[85vh]` and `overflow-y-auto` on the body.
- Action buttons (Submit, Cancel, Save) stay visible in a sticky footer, not pushed below the fold or hidden behind the on-screen keyboard.
