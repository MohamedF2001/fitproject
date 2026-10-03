---
name: Kinetic Volt
colors:
  surface: '#111316'
  surface-dim: '#111316'
  surface-bright: '#37393d'
  surface-container-lowest: '#0c0e11'
  surface-container-low: '#1a1c1f'
  surface-container: '#1e2023'
  surface-container-high: '#282a2d'
  surface-container-highest: '#333538'
  on-surface: '#e2e2e6'
  on-surface-variant: '#c4c9ac'
  inverse-surface: '#e2e2e6'
  inverse-on-surface: '#2f3034'
  outline: '#8e9379'
  outline-variant: '#444933'
  surface-tint: '#abd600'
  primary: '#ffffff'
  on-primary: '#283500'
  primary-container: '#c3f400'
  on-primary-container: '#556d00'
  inverse-primary: '#506600'
  secondary: '#7bd0ff'
  on-secondary: '#00354a'
  secondary-container: '#00a6e0'
  on-secondary-container: '#00374d'
  tertiary: '#ffffff'
  on-tertiary: '#233143'
  tertiary-container: '#d4e4fa'
  on-tertiary-container: '#576679'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#c3f400'
  primary-fixed-dim: '#abd600'
  on-primary-fixed: '#161e00'
  on-primary-fixed-variant: '#3c4d00'
  secondary-fixed: '#c4e7ff'
  secondary-fixed-dim: '#7bd0ff'
  on-secondary-fixed: '#001e2c'
  on-secondary-fixed-variant: '#004c69'
  tertiary-fixed: '#d4e4fa'
  tertiary-fixed-dim: '#b9c8de'
  on-tertiary-fixed: '#0d1c2d'
  on-tertiary-fixed-variant: '#39485a'
  background: '#111316'
  on-background: '#e2e2e6'
  surface-variant: '#333538'
typography:
  metric-display:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 52px
    letterSpacing: -0.03em
  metric-display-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 44px
    letterSpacing: -0.03em
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 30px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: 0em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.04em
  label-mono-stat:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.08em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system expresses high-performance discipline, athletic technicality, and focused utility tailored for West African fitness enthusiasts navigating both local gym cultures and global fitness standards. The visual language rejects motivational clichés and stock photography in favor of structural clarity, precise anatomical feedback, and high-legibility telemetry. 

The aesthetic is high-contrast, technical minimalism built for dark gym environments: deep anthracite backdrops eliminate eye strain under fluorescent or low gym lighting, punctuated by razor-sharp electric lime signals that demand immediate action. The interface feels like a finely tuned instrument—weight plates, split times, heart rates, and sets are front-and-center with authoritative geometric typography and robust line art.

## Colors

The palette establishes an aggressive functional hierarchy optimized strictly for dark-mode environments:

- **Primary (`#CCFF00` - Electric Volt):** Reserved strictly for primary action states, current active sets, progress ring completions, and active tab anchors. It must never coat expansive surfaces or body backgrounds.
- **Secondary (`#38BDF8` - Cyan Ice):** Deployed for biometric data, secondary telemetry (e.g., cadence, target pace, personal records), and cooling rest timers.
- **Tertiary (`#94A3B8` - Muted Slate):** Utilized for metadata, inactive states, secondary labels, and structural delimiters.
- **Neutral Canvas (`#121417` Base Anthracite):** Deep charcoal foundation preventing pure-black OLED smearing while maintaining ocular comfort.
- **Elevated Surfaces:** Surface tier 1 resides at `#181B20`, stepping up to `#22272E` for interactive cards and `#2B313A` for active input modules and overlays.
- **Typography Tokens:** Primary content and metrics use Off-White (`#F8FAFC`); supporting metrics use Slate (`#8E9AA8`).

## Typography

Typography prioritizes rapid glanceability during active sets. Plus Jakarta Sans provides clean geometric proportions with distinct tabular numeric clarity.

- **Numeric Telemetry (`metric-display`):** Heavy, condensed numbers (`font-weight: 800`) feature negative tracking for compact presentation of weights, rest counts, and reps.
- **Labels & Tags:** Uppercase `label-mono-stat` styling ensures muscle groups, status badges, and units (`KG`, `LBS`, `SEC`, `RPE`) read clearly at a split-second glance.
- **Optical Adjustments:** Maintain standard tracking on body sizes, while applying tight tracking (`-0.02em` to `-0.03em`) on sizes above 20px to sustain structural density.

## Layout & Spacing

The layout is built on a 4-column fluid mobile grid anchored by an 8pt structural rhythm, with a persistent bottom safe-area offset to clear the global tab bar.

- **Margins & Gutters:** Base screen edge margins are fixed at `1.25rem` (20px), while inner item gutters maintain `1rem` (16px).
- **Gym-Safe Touch Zones:** Interactive targets (e.g., set incrementors, rep toggles, timer controls) enforce a minimum tap clearance of 48×48px with `space-md` separation to prevent mistaps during physical exertion.
- **Adapting Breakpoints:**
  - **Compact Mobile (<390px):** Metric displays step down to `metric-display-mobile`, inner card padding condenses to `space-md` (16px), margins drop to `1rem`.
  - **Standard Mobile (390px - 480px):** Native 4-column layout, `space-lg` card padding.
  - **Tablet Form (>480px):** Layout locks to a max-width of 540px centered frame, retaining an app-shell ergonomic profile.

## Elevation & Depth

Depth is established via tonal stacking and crisp, low-contrast ghost borders rather than heavy drop shadows:

- **Base Layer:** `#121417` handles full canvas backgrounds.
- **Container Level 1:** `#181B20` handles secondary groups and recessed wells.
- **Container Level 2 (Cards):** `#22272E` paired with a delicate top/outer rim: `1px solid rgba(255, 255, 255, 0.08)`.
- **Container Level 3 (Modals, Overlays):** `#2B313A` framed with `1px solid rgba(255, 255, 255, 0.12)`.
- **Glow & Energy Highlights:** Active states, active workout badges, and the primary center action button cast a tight, colored ambient bleed: `0px 8px 24px rgba(204, 255, 0, 0.22)`. Ambient shadows on standard surfaces remain neutral: `0px 10px 30px rgba(0, 0, 0, 0.45)`.

## Shapes

The interface embraces a rounded, architectural silhouette that feels solid and ergonomic in hand:

- **Standard Cards and Modules:** Bound by a continuous `18px` to `20px` radius, giving dense metric components a smooth, modern profile.
- **Action Buttons & Badges:** Primary and secondary CTA buttons take full-capsule (pill) geometry (`9999px`) to immediately distinguish triggers from informational surfaces.
- **Metric Chips & Controls:** Enclosed in `10px` to `12px` rounded envelopes, providing consistent corner radii across nested modules.

## Components

### Buttons
- **Primary CTA:** Background `#CCFF00`, text `#121417` (`font-weight: 700`), 52px height, pill-shaped (`border-radius: 9999px`). Glowing hover/pressed reaction with subtle scale down (`0.98`).
- **Secondary CTA:** Surface `#22272E` with `1px solid rgba(255, 255, 255, 0.15)`, text `#F8FAFC`.
- **Ghost Action:** Transparent fill, text `#94A3B8`, active state `#F8FAFC`.

### Cards & Exercise Containers
- Built on `#22272E` with an `18px` border radius and `1px solid rgba(255, 255, 255, 0.08)`.
- Card headers house clean, single-weight line-art anatomical icons detailing activated muscle zones in `#94A3B8` (unactivated) and `#CCFF00` (targeted).

### Input Fields & Steppers
- Numeric input fields utilize `#181B20` recessed wells with `12px` radius and centered `24px` bold off-white numbers.
- Stepper buttons (`+` / `-`) utilize minimum 44px surface bounds with high-contrast slate icon strokes.

### Checkboxes & Set Completion Toggles
- Custom circular action discs (32px diameter). Incomplete: `2px solid #8E9AA8` circle. Complete: Filled `#CCFF00` with dark `#121417` checkmark.

### Chips & Status Tags
- Height: 28px, radius: 8px. Background: `rgba(255, 255, 255, 0.05)`, border: `1px solid rgba(255, 255, 255, 0.08)`, text: uppercase `label-mono-stat`.

### Fixed Mobile Navigation Bar
- Frosted dark container (`background: rgba(18, 20, 23, 0.88)` with `backdrop-filter: blur(16px)`), bordered on top by `1px solid rgba(255, 255, 255, 0.06)`.
- Features 5 tabs: **Accueil**, **Programmes**, **Séance**, **Objectifs**, and **Profil**.
- Standard tabs feature 2px stroke line-art vector icons (`#8E9AA8`, active: `#CCFF00`).
- **Séance (Center Action FAB):** Elevated circular button (56px) floating slightly above the bar baseline, coated in solid `#CCFF00` with `#121417` iconography and an electric volt ambient shadow (`0px 6px 20px rgba(204, 255, 0, 0.35)`).