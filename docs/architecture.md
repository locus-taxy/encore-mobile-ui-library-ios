# iOS UI Library — Architecture

Project: `encore-mobile-ui-library-ios` (`ui-library-ios`)

---

## Module Structure

**Build system:** Swift Package Manager
**Package name:** `EncoreSwiftUiKit`
**Min iOS:** 15

All source lives under:
`EncoreSwiftUiKit/EncoreSwiftUiKit/`

Components are organized by feature (one directory per component type):

```
EncoreSwiftUiKit/
├── Boolean/        # BooleanView.swift
├── Checkbox/       # TriStateCheckbox, ChecklistToggleStyle
├── Checklist/      # Complex multi-field form (largest module)
│   ├── Models/     # ChecklistItem, ChecklistItemValue, ChecklistItemFormat, etc.
│   ├── Items/      # 11 specialized item-type views
│   ├── Utils/      # ChecklistHeader, ChecklistItemConstants
│   ├── ChecklistView.swift
│   ├── ChecklistStateManager.swift
│   ├── ChecklistValidator.swift
│   └── ChecklistItemCallbacks.swift
├── Common/         # Typography.swift, Spacing.swift, BundleToken.swift
├── DateTime/       # EncoreDateView, EncoreTimeView, EncoreDateTimeView
├── Image/          # PlatformImageView, EncoreIcon, Image+Extensions
├── ImagePicker/    # ImagePickerView, ImageSourceType
├── MultiChoice/    # MultiChoiceView
├── Pin/            # PinView
├── Rating/         # RatingView
├── Signature/      # SignatureCanvasView
├── SingleChoice/   # SingleChoiceView
├── TextField/      # TextFieldView
├── Url/            # UrlView
├── Assets/         # Design system asset catalog
└── Fonts/          # Inter variant .ttf files
```

---

## Architecture Pattern

**SwiftUI component library** — no MVVM or app architecture layers.

- All components are SwiftUI `View` structs
- No UIViewController bridges
- Parent-driven data flow: components receive values and emit changes via closure callbacks
- Complex form state centralized in `ChecklistStateManager` (`ObservableObject`)
- `ChecklistItemRenderer` dispatches to specialized item views via a switch/case (Strategy pattern)

---

## Preview Components

Two patterns coexist in the library:

**Simple components** — `#Preview` macro placed inline at the bottom of the component file:
```swift
#Preview {
    EncoreIcon(iconName: "Schedule", size: 26)
}
```

**Complex components** — `PreviewProvider` struct in a dedicated `*Preview.swift` file alongside the component (e.g. `Checklist/ChecklistViewPreview.swift`):
```swift
struct ChecklistViewPreview: PreviewProvider {
    static var previews: some View {
        ChecklistView(header: "Complete Your Information", items: [...], ...)
    }
}
```

Use `#Preview` for simple single-call previews. Use `PreviewProvider` when the preview requires substantial mock data setup (e.g. building a full `ChecklistItem` list).

---

## State Management

**SwiftUI property wrappers + ObservableObject** (no third-party library).

Simple components use closure-based callbacks with no internal state:
```swift
struct BooleanView: View {
    let value: Bool
    let onCheckedChange: (Bool) -> Void
}
```

The `ChecklistView` uses a dedicated state manager:
```swift
// ChecklistView.swift
@StateObject private var stateManager: ChecklistStateManager

// ChecklistStateManager.swift
class ChecklistStateManager: ObservableObject {
    @Published private var stateMap: [String: Any] = [:]
    @Published private var validationMap: [String: Bool] = [:]

    func updateValue(key: String, value: Any?)
    func getValue(key: String) -> Any?
    func validateItem(_ item: ChecklistItem)
    func areAllRequiredItemsValid() -> Bool
    func buildSubmissionMap() -> [String: ChecklistItemValue]
}
```

Data flow is unidirectional:
```
ChecklistView → ChecklistStateManager → individual item views (via @ObservedObject)
Item change → callback closure → stateManager.updateValue() → @Published triggers re-render
```

---

## Dependency Injection

**No DI framework.** All dependencies are passed as parameters or closure callbacks:

```swift
struct SignatureCanvasView: View {
    @Binding var signatureImage: UIImage?
    let onSignatureCaptured: (UIImage?) -> Void
}
```

The library exposes a clean public API — no global singletons or service locators.

---

## Design Tokens

`Typography` and `Spacing` are value-type structs (not classes) defined in `Common/`:

```swift
struct Typography {
    static let h1 = Font.custom("Inter-Medium", size: 42)
    struct Button { static let large = Font.custom("Inter-SemiBold", size: 16) }
}
struct Spacing {
    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
}
```

---

## Unit Test Patterns

**Framework:** XCTest

Tests are minimal — focused on design token property verification:
```swift
class TypographyTests: XCTestCase {
    func testH1FontSize() {
        XCTAssertEqual(Typography.h1.size, 42, accuracy: 0.001)
    }
}
```

No mocking — tests assert on static design token values.

---

## Key Build Config

| Item | Value |
|------|-------|
| Build system | Swift Package Manager |
| Min iOS | 15 |
| Swift | 5.9+ |
| Package name | `EncoreSwiftUiKit` |
