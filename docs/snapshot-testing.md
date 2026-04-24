# Snapshot Testing

AI agents developing UI components can use the `ios-snapshot-test` skill to verify that a component's visual output matches a Figma reference screenshot.

## How It Works

The skill:
1. Validates that the named preview structurally matches the reference before running any builds
2. Configures SnapshotPreviews automatically in `project.yml` if not already set up
3. Writes a minimal `SnapshotTest` subclass that filters to the named preview
4. Runs `xcodebuild test` and exports snapshot PNGs via `TEST_RUNNER_SNAPSHOTS_EXPORT_DIR`
5. Uses vision to compare the snapshot against the reference and report the result

Test files and snapshot images are **git-ignored** and **retained between runs** — subsequent invocations reuse the existing test file for faster re-evaluation.

## Prerequisites

- XcodeGen: `brew install xcodegen`. Used to regenerate the Xcode project after editing `project.yml`.
- Xcode with the **iPhone 16 simulator** available.

## Invoking the Skill

```
/ios-snapshot-test
  component_name: "BooleanView"
  reference_png: "/path/to/boolean-design.png"
  preview_name: "BooleanViewPreview"
  preview_description: "2-column grid: On / Off / Indeterminate states"
```

All four inputs are mandatory.

## Inputs

| Input | Description |
|---|---|
| `component_name` | Exact Swift type name of the component, e.g. `BooleanView` |
| `reference_png` | Absolute path to the Figma-exported reference PNG |
| `preview_name` | Exact name of the `#Preview("name")` string or `PreviewProvider` type name |
| `preview_description` | Plain-language description of the reference layout, used for vision analysis |

## How to Find the preview_name

For `#Preview` macros — the name is the string argument:
```swift
#Preview("BooleanViewPreview") {
    BooleanView(...)
}
```
→ `preview_name: "BooleanViewPreview"`

For `PreviewProvider` structs — the name is the type name:
```swift
struct ChecklistViewPreview: PreviewProvider {
    static var previews: some View { ... }
}
```
→ `preview_name: "ChecklistViewPreview"`

## Output

**Success:**
```
✅ SNAPSHOT MATCH
Component: BooleanView
Preview: BooleanViewPreview
Snapshot: EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/exports/...png
Test file retained at: EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/BooleanViewSnapshotTest.swift
```

**Mismatch** — the skill describes exactly where the output diverges:
```
❌ SNAPSHOT MISMATCH
Divergences detected:
  - Background: incorrect dark tint applied
  - Row 2 (Off state): checkmark visible when it should not be
Test file retained at: EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/BooleanViewSnapshotTest.swift
```

**Preview mismatch** (Phase 2 exit — caught before the build):
```
⛔ PREVIEW MISMATCH
The preview "BooleanViewPreview" does not match the reference layout described in preview_description.
Expected: 2-column grid: On / Off / Indeterminate states
Found in preview source: single BooleanView instance with On state only
Update the preview or provide a different preview_name before retrying.
```

**Structural error** — preview can't reproduce the reference layout:
```
⛔ ERROR: Unable to produce a snapshot matching the reference after N attempt(s).
The preview "BooleanViewPreview" cannot reproduce the layout shown in the reference PNG.
The preview source may need to be updated to include the required variants
before snapshot testing can proceed.
```

**Rendering exhaustion error** — structure matches but styling didn't converge:
```
⛔ ERROR: Component rendering did not match the reference after 3 iteration(s).
The preview layout is structurally correct, but colors, typography, or spacing differ.
Review the component implementation for styling discrepancies before retrying.
Test file retained at: EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/BooleanViewSnapshotTest.swift
```

## Generated File Locations

All paths below are git-ignored:

| Artifact | Path |
|---|---|
| Test file | `EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/<Name>SnapshotTest.swift` |
| Exported snapshots | `EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/exports/` |
