# Tours Landing — Design Preview (iOS)

**Source:** Figma "Landing Page" · Outbound · Mobile · v2 (node `1-2320`)
**File:** `ToursLandingView.swift`
**Generated:** 2026-06-22

## Screens covered
- **Default** — greeting header + "Tours" section with Outbound / Inbound tiles
- **Loading** — same layout, redacted skeleton
- **Empty** — no tours assigned (library `EmptyStateView`)

## How to preview (Xcode)
1. From the iOS repo run `./xcodegen.sh` (regenerates the project and includes this file).
2. Open `EncoreSwiftUiKit.xcodeproj`, open `ToursLandingView.swift`.
3. Press ⌘⌥↩ to open the canvas — the three `#Preview` states render.

Or use the workflow shortcut: `/mobile-preview tours-landing ios`.

## Notes
- Static visual preview only — no ViewModel, navigation, or networking.
- All colour / spacing / typography come from EncoreSwiftUiKit design tokens.
- Icons are SF Symbol placeholders — see `dev-reference/tours-landing-dev-ref.md` for the swap list.

## Iteration
Describe any change in plain English in the Claude session — no code knowledge needed.
