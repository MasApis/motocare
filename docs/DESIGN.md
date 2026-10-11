---
name: MotoSense Design System
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#3f4850'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#707881'
  outline-variant: '#bfc7d2'
  surface-tint: '#006398'
  primary: '#006194'
  on-primary: '#ffffff'
  primary-container: '#007bb9'
  on-primary-container: '#fdfcff'
  inverse-primary: '#93ccff'
  secondary: '#006591'
  on-secondary: '#ffffff'
  secondary-container: '#39b8fd'
  on-secondary-container: '#004666'
  tertiary: '#006947'
  on-tertiary: '#ffffff'
  tertiary-container: '#00855b'
  on-tertiary-container: '#f5fff6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#cce5ff'
  primary-fixed-dim: '#93ccff'
  on-primary-fixed: '#001d31'
  on-primary-fixed-variant: '#004b73'
  secondary-fixed: '#c9e6ff'
  secondary-fixed-dim: '#89ceff'
  on-secondary-fixed: '#001e2f'
  on-secondary-fixed-variant: '#004c6e'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 52px
    letterSpacing: -0.03em
  display-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 42px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: 0em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  metric-val:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 36px
    letterSpacing: -0.02em
  label-caps:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.06em
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.01em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-desktop: 1.5rem
  margin: 1rem
  margin-desktop: 2.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
---

## Brand & Style

The design system is engineered specifically for connected motorcycle diagnostics, real-time telemetry, and scheduled fleet maintenance. The aesthetic balances precision engineering with immediate, glanceable utility under intense ambient sunlight. The design language marries clean automotive instrumentation with high-legibility digital product design. 

Key principles:
- **Glanceability Under Vibration:** Critical metrics, tire pressure, and error diagnostics must be immediately decipherable within a 200ms glance at arm’s length.
- **Precision Diagnostics:** Visuals avoid ornamental clutter in favor of crisp boundaries, distinct visual weights, and definitive color-coded states.
- **Ergonomic Tactility:** Generous tap targets, clear physical boundaries, and exaggerated pill-shaped interactive surfaces support gloved or single-thumb operation while stationary.

## Colors

The palette is tuned for high optical contrast in outdoor daylight. The canvas relies on pure whites and tinted slate tones, punctuated by an electric diagnostic cyan and a standardized automotive status trio.

- **Primary Canvas & Surfaces:** Background is anchored on `#F8FAFC` (Canvas Slate 50), with surface cards resting on `#FFFFFF` (Surface White) to achieve punchy contrast without glare.
- **Typography & Structure:** Primary text and icons use `#0F172A` (Deep Slate 900), yielding an optical contrast ratio exceeding 13:1 against white backgrounds. Muted text rests at `#475569` (Slate 600) and borders sit at `#E2E8F0` (Slate 200).
- **Brand & Telemetry Accents:** `#0284C7` (Electric Cyan) serves as the primary action and focused telemetry color, with `#0EA5E9` (Sky Blue) utilized for interactive highlights, active states, and gauge fills.
- **Status & Diagnostic System:**
  - **Optimal / Nominal:** `#10B981` (Emerald Green) paired with a 10% tinted container (`#ECFDF5`) for battery health, stable tire pressures, and green DTC passes.
  - **Advisory / Maintenance:** `#F59E0B` (Amber Warning) with container `#FFFBEB` for wear limits, impending service windows, or non-critical sensor drifts.
  - **Critical / Fault:** `#EF4444` (Diagnostic Red) with container `#FEF2F2` for active DTC engine faults, low oil pressure, or critical brake degradation.

## Typography

The type scale combines the modern geometric energy of **Plus Jakarta Sans** for headlines and telemetry metrics with the utilitarian legibility of **Inter** for descriptions, status logs, and interface controls.

- **Plus Jakarta Sans** is used strictly for headings, major diagnostic summaries, and numeric metric readings. Its generous counters and open apertures prevent characters from blurring together when mounted to handlebars.
- **Inter** handles all long-form body text, diagnostic DTC sub-labels, and tabular data. Metric units (e.g., `PSI`, `V`, `°C`) must sit immediately adjacent to metric numerals using `label-caps` with uppercase tracking.
- All numbers representing speed, voltage, pressure, and temperature must utilize tabular figure styling (`tnum`) to eliminate visual jitter during real-time updates.

## Layout & Spacing

The layout is built on a responsive 4-column mobile grid expanding to an 8-column tablet grid and a 12-column desktop dashboard. Because the primary usage scenario is mobile (often cockpit-mounted), spacing must balance dense diagnostic feedback with thumb accessibility.

- **Layout Hierarchy:** Mobile viewports use `margin: 1rem` to maximize screen real estate, while maintaining a strict `gutter: 1rem` to enforce visual separation between parallel metrics (e.g., Front Tire vs. Rear Tire PSI).
- **Rhythm Rules:** Telemetry groups sit in dense clusters using `space-xs` (4px) and `space-sm` (8px) for related labels and values. Card internals follow `space-md` (16px) or `space-lg` (24px) padding to create an airy, uncrowded feel despite data density.
- **Touch Clearance:** All touch targets must adhere to a minimum interactive footprint of 48px by 48px.

## Elevation & Depth

To guarantee legibility in changing daylight and prevent muddy visual artifacts on high-brightness mobile panels, depth relies on clean tonal separation and low-opacity, crisp ambient shadows.

- **Surface Levels:**
  - **Canvas (Level 0):** Flat `#F8FAFC`.
  - **Cards & Modules (Level 1):** Solid `#FFFFFF` background bordered with 1px solid `#E2E8F0`. Shadow: `0 1px 3px rgba(15, 23, 42, 0.04), 0 4px 6px -1px rgba(15, 23, 42, 0.03)`.
  - **Interactive Elevate / Floating Controls (Level 2):** `#FFFFFF` with primary border tinted `#0284C7` at 20% opacity. Shadow: `0 8px 16px -4px rgba(2, 132, 199, 0.12), 0 4px 8px -2px rgba(15, 23, 42, 0.04)`.
  - **Overlays, Diagnostics Trays & Modals (Level 3):** `#FFFFFF` with backdrop overlay of `#0F172A` at 40% blur. Shadow: `0 20px 25px -5px rgba(15, 23, 42, 0.12), 0 10px 10px -5px rgba(15, 23, 42, 0.04)`.
- **Diagnostic Glowing Accents:** Critical warnings never use heavy blurred glow effects; they are rendered as crisp 1px perimeter rings and 100% opaque, high-contrast indicator dots.

## Shapes

The design system adopts a pill-shaped, ergonomic profile (`roundedness: 3`). Telemetry badges, interactive CTAs, filter chips, and progress bars utilize full pill geometries (`border-radius: 9999px`). 

Diagnostic cards and telemetry containers employ standard `rounded-2xl` corners (equivalent to 1rem to 1.5rem), yielding friendly, modern silhouettes that echo the smoothed mechanical lines of modern sport and adventure motorcycles. Internal progress tracks and inner gauges always match the curvature of their outer container.

## Components

### Buttons & Interactive Targets
- **Primary Action:** Pill-shaped (`rounded-full`), solid `#0284C7` background with bold white `#FFFFFF` text. Height of 52px for primary actions to facilitate gloves. Subtle transition to `#0369A1` on active press.
- **Secondary Action:** Pill-shaped, transparent background with 1.5px border `#E2E8F0`, dark slate text `#0F172A`. Active state transitions to `#F1F5F9`.
- **Icon Actions:** Minimum 48px square bounding box, rendered as circular pills (`rounded-full`) with a neutral `#FFFFFF` fill and a 1px `#E2E8F0` edge.

### Diagnostic Badges & Status Chips
- Fully rounded pill tags (`rounded-full`) using semantic color pairings:
  - **Healthy:** `#ECFDF5` background, `#065F46` label, with a 6px pulsing dot in `#10B981`.
  - **Warning:** `#FFFBEB` background, `#92400E` label, with a solid 6px dot in `#F59E0B`.
  - **Critical:** `#FEF2F2` background, `#991B1B` label, with an alert icon in `#EF4444`.
- Padding is strictly `space-xs` vertical by `space-sm` horizontal; text uses `label-caps`.

### Cards & Metric Modules
- Encased in `#FFFFFF` with 16px (`rounded-2xl`) radius and 1px `#E2E8F0` border.
- Divided internally by subtle borders (`#F1F5F9`) rather than heavy backgrounds.
- Header row hosts the metric identifier (e.g., "COOLANT TEMP") in `label-caps` (`#475569`) alongside the current status badge. The module body houses the `metric-val` in `Plus Jakarta Sans` 32px bold paired with a secondary baseline unit label.

### Form Inputs & Adjustments
- Pill-shaped or `rounded-xl` text fields with a 1.5px border `#CBD5E1`, inset padding of 16px horizontal, and a fixed height of 48px.
- Focus state applies a 2px `#0284C7` border and an ambient `0 0 0 4px rgba(2, 132, 199, 0.15)` ring.

### Telemetry Gauges & Battery/Tire Monitors
- Arc and bar indicators feature an underlay track of `#E2E8F0` with a dynamic fill in `#0284C7` (or corresponding status color). Tracks end in rounded caps (`stroke-linecap: round`).
- Center-stage telemetry components provide an immediate visual representation of the bike silhouette with front and rear status anchors displaying live tire pressures in PSI or Bar.