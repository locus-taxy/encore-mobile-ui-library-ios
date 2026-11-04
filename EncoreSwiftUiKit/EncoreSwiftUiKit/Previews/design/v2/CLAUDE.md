# V2 Rider App prototype — in-app notifications (DP-2959 tiering, DP-2956 inbox)

Context for an engineer (or their Claude) picking up the in-app notification work.

**What this is:** a design prototype written in SwiftUI. It is the design source of truth for
behaviour, layout, copy and motion — not production code. It lives under `Previews/design/` in the UI
library, fakes the backend with a local engine, and is driven by demo states. Port the *rules* and
*shapes* into the rider app (`encore-dashboard-app-ios`); don't copy the files.

- DP-2959 — Notification priority tiering: how an arriving notification interrupts while the app is open.
- DP-2956 — In-app notification inbox: bell + unread count, list, read / unread, filters.
- Hand-off page with every state as a screenshot: https://claude.ai/artifact/7XMsFvX3kvB1TqVgsbzK3e

---

## Run it

```sh
cd EncoreSwiftUiKit
./xcodegen.sh                      # the .xcodeproj is generated and gitignored
xcodebuild -project EncoreSwiftUiKit.xcodeproj -scheme SnapshotTestHost \
  -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build/dd build
xcrun simctl install booted build/dd/Build/Products/Debug-iphonesimulator/SnapshotTestHost.app
SIMCTL_CHILD_POC_STATE=v2-inbox xcrun simctl launch --terminate-running-process booted sh.locus.encore.SnapshotTestHost
```

- `POC_STATE` must carry the `SIMCTL_CHILD_` prefix, or the app silently opens the default screen.
- No `POC_STATE` → full flow from splash.
- `SIMCTL_CHILD_POC_PUSH=critical,high,medium` fires pushes ~1.5 s after launch (0.4 s apart).
  Samples: `V2PushSample` in `V2Notify.swift`.
- In the simulator, **⌃⌘Z** (shake) opens the *Prototype* panel: jump to any demo state or fire any push.
  The state list is `V2PushPanel.states`; the state switch is in `V2Flow.swift` (search `case "notif-`).

Useful states: `home`, `inbox`, `inbox-unread`, `inbox-caughtup`, `inbox-filter`, `inbox-select`,
`inbox-swipe-read`, `inbox-offline`, `inbox-empty`, `badge-many`, `notif-pair`, `notif-trio`,
`notif-viewall`, `notif-banners`, `notif-inbox-medium`, `notif-viewtask`, `notif-cascade`, `notif-skip`,
`notif-open`, `notif-gone`, `notif-tray` (prefix each with `v2-`).

---

## Files

| File | What's in it |
|---|---|
| `V2Notify.swift` | DP-2959. Model (`V2Severity`, `V2NotificationKind`, `V2NotificationTarget`, `V2Notification`), `V2NotificationCenter` (the single source of what's on screen), `V2NotificationLayer` + `V2NotificationTakeover` (dialog / summary dialog), `V2BannerSlot` + `V2NotificationBanner` (medium banner / summary banner), `V2NetworkAlert` (offline strip), push samples and the Prototype panel. Header comment = the tiering rules. |
| `V2Inbox.swift` | DP-2956. `V2NotificationRowVars` / `V2NotificationRowCard` (the row = an SDUI card), `V2InboxPage` (native host: tabs, day sections, paging, swipe, select, states), `V2InboxFilter(Sheet)`, `V2Ago` (time grouping), `V2CountBadge`, `V2BellButton`, sample history (`V2NotificationCenter.history()`). |
| `V2Flow.swift` | Wiring: seeds the inbox, hosts the layer, routes a tapped notification to its target (`openNotification`), fires samples (`fire`), demo states. Holds banners while the camera is open; tells the center when the inbox is open. |
| `V2Engine.swift` | Fake backend: `cancelTask`, `skipStop` mutate the trip *before* the notification arrives; stop status derives from its tasks. |
| `V2Navbar.swift` | Every app bar hosts `V2BannerSlot()` under it. |
| `V2Scan.swift` | `V2Tab.count` → "Label (n)" (inbox tabs reuse the scan tabs). |
| `V2Nav.swift` | `V2Motion.reflow` (0.4 s, Material standard easing) for anything that grows / shrinks in a page. |
| `HFKit.swift`, `Assets` | Avatar badge variant, outlined bell / remove-circle icons, checkbox glyph fix. |

`V2NotificationCenter` decides; views only render what it publishes. Keep that split.

---

## Rules (agreed with design — the code follows these)

**Severity comes from the backend per notification.** The app never assigns or overrides it; missing or
unknown → LOW (`V2Severity(platform:)`). Whether a change touches the rider's *current* stop / trip is
the backend's call, reflected in the severity it sends.

| Severity | In-app treatment |
|---|---|
| CRITICAL, HIGH | **Takeover**: centred dialog over a scrim, one red treatment (tone + icon) for both. Buttons: target action ("View task" / "View stop" / … or "Got it" when there is no target) over "Dismiss". Buttons ignore taps for 0.6 s after appearing. Scrim tap does nothing. |
| — two or more at once | One **summary dialog**: "N urgent notifications" / "Open to see what needs your attention" / **Open notifications** (inbox on Unread, entries stay unread) / **Dismiss** (marks them read). A single dialog dissolves into the summary when another arrives. *(The brief queues them one after another — pending PM confirmation.)* |
| MEDIUM | **Banner** under the app bar; the page slides down with it (`reflow`). Stays until ✕ (marks read) or tapped through — no auto-dismiss. "View …" link on its own line under the message. Two or more → one **summary banner** "N new notifications" + "Open notifications". Not shown while a takeover is up, while the camera is open (waits, then slides in), or while the inbox is open (the row lands in the list instead). *(The brief says it goes on its own — pending PM.)* |
| LOW | Nothing on screen. Inbox entry + bell count only. |

- **Toast = feedback on the rider's own action.** Notifications never use the bottom toast.
- **Every alert is dismissed by the rider.** Exception: a time-bound banner (e.g. "Rest break due") goes when it's no longer true.
- **Tapping through or dismissing marks the entry read.** Opening the inbox does not.
- **The item carries its own state.** The platform changes the task / stop / trip first; the push only
  announces it. The target page shows the new status chip (Cancelled, Skipped) from the backend via
  the SDUI cards. No extra "context" box or reason line on the page (parked; no display text for reason
  codes yet, DP-2907).
- **Cascades:** one notification for the top-most entity that changed (a skipped stop, not the stop +
  each task). Needs backend support — see gaps below.
- **Nothing abandons a flow.** Opening a notification target leaves a scan / checklist; coming back
  resumes with its progress (cached). *The prototype still closes the scan here — not yet updated.*
- **Target gone** (reassigned / removed): stay put, toast "This trip is no longer available"; the row says so.
- Blocking states (break block, hours over limit, forced logout, mandatory update) and inline scan
  feedback are **not** notifications and don't go in the inbox.

**Inbox (DP-2956)**
- Bell (outlined = tappable) on Home and Delivery; badge = unread count, capped at **99+**, grows to the right.
- Tabs: **All** (no count) and **Unread (n)** — shows "(0)" when nothing is unread.
- Day sections (Today / Yesterday / This week / Older), collapsible; relative time only under Today.
- Paging 8 at a time; new rows land on top with `reflow`.
- Swipe toggles read ↔ unread; row ⋮ menu; Gmail-style select (tap the avatar or long-press) with one footer action.
- Filters: severity and type (Alerts / Notifications) live in the filter sheet, not on the row.
- States: empty ("No notifications yet"), caught up ("You're all caught up"), no results (Reset all), no connection.
- Alerts vs notifications are not styled differently in the list (decided).

**SDUI split:** the row content is the SDUI card `notification_list_card_v1` (`V2NotificationRowVars`
= its variables: subject, body, timeLabel, isUnread, goneLabel). Everything around it — tabs, sections,
filter, paging, checkbox, swipe, select, states, row tap → target — is native host chrome. The takeover,
banner, bell and network strip are native.

The entry mirrors the platform's `notificationInbox` (subject, body, createdAt, status/read, severity,
type, deepLinkTarget).

---

## Backend gaps (checked in code 2026-10-28: `encore` master 35b82ea10e incl. its `encore-bfa/` module, `encore-workflow-resources` 09d3aa7, rider apps `main`)

- No push emitters yet (`notification:push` worker is on a branch, DSCM-94/98); pushes carry no
  severity and don't write inbox entries (DP-7714).
- **Dispatcher skips a stop** → one `stop:skipped` `{stopId}`; its tasks are **not** cancelled (the
  per-task cascade action exists but nothing calls it). BFA sends one `stopSkipped`. The apps merge
  several skips into one local notification.
- **Tasks cancelled one by one → stop derived Skipped** → N `entitiesUpdated`, no `stop:skipped`:
  the rider is not told.
- **Trip cancelled** (only before dispatch) → one `entitiesUpdated`, not `tripUnassigned`.
- **Rider removed from a trip** → nothing; `tripUnassigned` is never produced.
- No correlation / cause id, collapse key, `thread-id` or `apns-collapse-id`; `task_cancelled` copy has no reason.

The prototype follows the product docs (skip cancels tasks; a derived skip notifies) as the intended behaviour.

## Open with product
- Several urgent at once → summary dialog (brief queues them).
- Medium banner stays until dismissed (brief: goes on its own).
- Should app-local timers (break due, shift ending, clock-out deadline) write inbox entries?
- Takeover as a centred card vs full screen.
