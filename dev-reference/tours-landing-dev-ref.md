# Tours Landing — Developer Reference

**Source:** Figma "Landing Page" · Outbound · Mobile · v2 (node `1-2320`)
**iOS preview:** `EncoreSwiftUiKit/EncoreSwiftUiKit/Previews/design/tours_landing/ToursLandingView.swift`
**This file:** `dev-reference/tours-landing-dev-ref.md`
**Last updated:** 2026-06-22

The preview is a static visual mock. This document is the bridge to a real implementation.

---

## Screen: ToursLanding

### Dynamic Data

All placeholder values in the preview are hardcoded stubs. Bind these in production:

| Preview stub | Real data source | Notes |
|--------------|------------------|-------|
| `"Arnold Schwarzenegger"` (greeting) | `UserSession.displayName` | Prefix with "Hi ", single line, scales down before truncating |
| `"AS"` (avatar initials) | derived from `UserSession.displayName` | Fallback when no avatar image; replace with photo when available |
| `"Atlanta Team"` | `UserSession.teamName` | Single line |
| `"Atlanta Homebase"` | `UserSession.homebaseName` | Single line; chevron implies a switcher |
| online dot | `UserSession.isOnline` | Show green dot only when online |
| `"07:00"` + status icons | system status bar | Replace mock bar with the real device status bar in-app |
| Outbound / Inbound tiles | `ToursService.availableFlows` | Each: action label, name, accent, destination |

### User Interactions

| Element | Action | What should happen | Notes |
|---------|--------|-------------------|-------|
| "Start Outbound" tile | Tap | Navigate into the Outbound tour flow (`onSelectFlow("Outbound")`) | Decision/navigation → tap, not swipe |
| "Start Inbound" tile | Tap | Navigate into the Inbound tour flow (`onSelectFlow("Inbound")`) | Same |
| Homebase row (chevron) | Tap | Open team/homebase switcher | Not wired in preview |
| Avatar | Tap | Open profile / account | Not wired in preview |

### Navigation Flow

```
ToursLanding
   ├─ [Tap "Start Outbound"] ─► Outbound tour flow (first step)
   ├─ [Tap "Start Inbound"]  ─► Inbound tour flow (first step)
   ├─ [Tap homebase chevron] ─► Homebase/team switcher
   └─ [Tap avatar]           ─► Profile / account
```

### State Transitions

| Trigger | From | To |
|---------|------|----|
| Screen appears, data loading | — | Loading (redacted skeleton) |
| Tours loaded | Loading | Loaded (default) |
| No tours assigned | Loading | Empty |
| Pull to refresh (empty) | Empty | Loading |

### Conditional Visibility

| Element | Shown when | Hidden when |
|---------|-----------|------------|
| Online dot on avatar | `isOnline == true` | offline |
| Tours tiles | `availableFlows` non-empty | empty → EmptyStateView |

### Accessibility Notes

| Element | VoiceOver label | Notes |
|---------|-----------------|-------|
| Outbound tile | "Start Outbound tour, button" | Combine the "Start" + "Outbound" texts into one label |
| Inbound tile | "Start Inbound tour, button" | Same |
| Avatar | "Arnold Schwarzenegger, online" | Announce presence |

### Developer TODOs (from preview)

- [ ] Replace SF Symbol glyphs (`arrow.up.right`, `arrow.down.right`, `house.fill`,
      `person.2.fill`, status icons) with library `EncoreIcon` assets when available.
- [ ] Replace mock status bar with the real device status bar.
- [ ] Map header background to an exact token if `#22262F` is added to the palette
      (currently nearest token `Grey/900`).
- [ ] Wire `onSelectFlow`, avatar, and homebase switcher to real navigation.
- [ ] Swap avatar initials for the user's photo when present.
