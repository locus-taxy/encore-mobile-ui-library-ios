# CLAUDE.md — encore-mobile-ui-library-ios

This file provides guidance to Claude Code when working in this repository. See also the root `CLAUDE.md` at `../CLAUDE.md` for cross-project context.

---

## Project Overview

Shared iOS UI component library for the Encore platform. Provides reusable SwiftUI components consumed by `encore-dashboard-app-ios`.

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Min iOS:** 15
- **Build:** Swift Package Manager (`Package.swift`)
- **Module name:** `EncoreSwiftUiKit`
- **Main source:** `EncoreSwiftUiKit/EncoreSwiftUiKit/`

---

## Consumer Projects

- **`encore-dashboard-app-ios`** — imports `EncoreSwiftUiKit`

**Breaking change rule:** Any change to a component's public API (struct/init signature, parameter names, types) requires a corresponding update in `encore-dashboard-app-ios`.

---

## Component Inventory

All components are in `EncoreSwiftUiKit/EncoreSwiftUiKit/`:

| Category | Directory | Key struct/view |
|----------|-----------|----------------|
| Checkbox | `Checkbox/` | `TriStateCheckbox`, `ChecklistToggleStyle` |
| Boolean toggle | `Boolean/BooleanView.swift` | `BooleanView` |
| Single choice | `SingleChoice/SingleChoiceView.swift` | `SingleChoiceView` |
| Multi choice | `MultiChoice/MultiChoiceView.swift` | `MultiChoiceView` |
| Rating | `Rating/RatingView.swift` | `RatingView` |
| Pin entry | `Pin/PinView.swift` | `PinView` |
| Signature | `Signature/SignatureCanvasView.swift` | `SignatureCanvasView` |
| Image | `Image/PlatformImageView.swift`, `EncoreIcon.swift` | `PlatformImageView` |
| Image picker | `ImagePicker/ImagePickerView.swift` | `ImagePickerView` |
| Date | `DateTime/EncoreDateView.swift` | `EncoreDateView` |
| Time | `DateTime/EncoreTimeView.swift` | `EncoreTimeView` |
| DateTime | `DateTime/EncoreDateTimeView.swift` | `EncoreDateTimeView` |
| URL | `Url/UrlView.swift` | `UrlView` |
| Text field | `TextField/TextFieldView.swift` | `TextFieldView` |
| Checklist | `Checklist/ChecklistView.swift` | `ChecklistView` |

### Checklist Item Types

`Checklist/Items/` contains:
`BooleanCheckListItem`, `TextFieldCheckListItem`, `DateCheckListItem`, `TimeCheckListItem`, `DateTimeCheckListItem`, `SingleChoiceCheckListItem`, `MultiChoiceCheckListItem`, `RatingCheckListItem`, `PinCheckListItem`, `ImageCheckListItem`, `SignatureCheckListItem`, `UrlCheckListItem`

### Checklist Supporting Files

- `ChecklistView.swift` — main container
- `ChecklistStateManager.swift` — state management
- `ChecklistValidator.swift` — validation logic
- `ChecklistItemCallbacks.swift` — callback protocols
- `Models/ChecklistItem.swift`, `ChecklistItemValue.swift`, `ChecklistItemFormat.swift`, `ChecklistPossibleValue.swift`
- `Utils/ChecklistHeader.swift`, `ChecklistItemConstants.swift`

---

## Android Counterpart

This library mirrors `encore-mobile-ui-library-android` (`AndroidUIKit`). When adding or changing a component here, check if the same change is needed in the Android library.

---

## Build Commands

```bash
# Open in Xcode
open EncoreSwiftUiKit.xcodeproj

# Format code
./format-code.sh

# Build via SPM (from package root)
swift build
swift test
```
