---
name: ios-snapshot-test
description: Use when verifying that a SwiftUI component's visual output matches a Figma reference screenshot. Runs SnapshotPreviews tests against existing #Preview / PreviewProvider and reports match/mismatch with pixel diff analysis. Required inputs: component_name, reference_png, preview_name, preview_description.
---

# ios-snapshot-test

Verify a SwiftUI UI component in `encore-mobile-ui-library-ios` matches a Figma-exported reference PNG using SnapshotPreviews snapshot testing.

## Required Inputs

Collect all four before proceeding. Do not start Phase 1 if any are missing — ask the caller for them.

| Input | Type | Example |
|---|---|---|
| `component_name` | String | `BooleanView` |
| `reference_png` | File path | `/Users/kanj/designs/boolean-design.png` |
| `preview_name` | String | `BooleanViewPreview` — exact name of `#Preview("name")` or `PreviewProvider` type |
| `preview_description` | String | `"2-column grid: On / Off / Indeterminate states"` |

## Context

Working directory: root of `encore-mobile-ui-library-ios/` (the directory containing `EncoreSwiftUiKit/` and `Package.swift`).

Key paths:
- `EncoreSwiftUiKit/project.yml` — XcodeGen config (source of truth for test dependencies)
- `EncoreSwiftUiKit/EncoreSwiftUiKit/` — component source files and previews
- `EncoreSwiftUiKit/EncoreSwiftUiKitTests/` — test target source

Do NOT edit `Package.swift` for test dependencies — it is the SPM manifest for external consumers only.

---

## Phase 1 — Setup

### 1a. Check ImageMagick

Run: `magick -version`

If this fails, continue without diff images — Phase 4 uses vision-only comparison. Note this limitation in the final output.

### 1b. Check SnapshotPreviews

Read `EncoreSwiftUiKit/project.yml`. Search for `SnapshotPreviews` in the `packages:` section.

**If already present:** skip to 1c.

**If missing**, apply two edits to `EncoreSwiftUiKit/project.yml`:

Under the `packages:` key, add:
```
SnapshotPreviews:
  url: https://github.com/EmergeTools/SnapshotPreviews.git
  version: <latest-stable>  # check https://github.com/EmergeTools/SnapshotPreviews/releases
```

Under `targets.EncoreSwiftUiKitTests.dependencies`, add:
```
- package: SnapshotPreviews
  product: SnapshottingTests
```

Then regenerate the Xcode project:
```
cd EncoreSwiftUiKit && ./xcodegen.sh
```

### 1c. Ensure .gitignore entries

Read the repo root `.gitignore`. Add if missing:
```
EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/
```

---

## Phase 2 — Preview Source Validation

This phase catches a wrong `preview_name` or structurally mismatched preview before the expensive `xcodebuild` run.

### 2a. Find the preview source file

Search `EncoreSwiftUiKit/EncoreSwiftUiKit/` for a file containing `preview_name`. It will appear as either:
- `#Preview("PREVIEW_NAME") { ... }` — inline in a component file
- `struct PREVIEW_NAME: PreviewProvider { ... }` — in a dedicated `*Preview.swift` file

### 2b. Vision validation

Read the preview source file and `reference_png` together with vision. Compare the layout structure described in `preview_description` against what the preview code will produce. Evaluate:
- Does the preview show the same variants and states as the reference?
- Is the grid/layout structure compatible?

**If structurally viable:** proceed to Phase 3.

**If fundamentally mismatched** (wrong variants, wrong layout, preview doesn't contain the reference content): exit immediately with this error:

```
⛔ PREVIEW MISMATCH
The preview "PREVIEW_NAME" does not match the reference layout described in preview_description.
Expected: PREVIEW_DESCRIPTION
Found in preview source: [describe what the preview actually shows]
Update the preview or provide a different preview_name before retrying.
```

---

## Phase 3 — Test Generation

### 3a. Write or reuse test file

Check whether `EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/COMPONENT_NAMESnapshotTest.swift` already exists (path relative to repo root).

- **If it exists:** reuse it — skip to Phase 4.
- **If not:** create it using the template below. Replace `COMPONENT_NAME` and `PREVIEW_NAME` with actual values.

```
import SnapshottingTests

class COMPONENT_NAMESnapshotTest: SnapshotTest {
    override class func snapshotPreviews() -> [String]? {
        return ["PREVIEW_NAME"]
    }
}
```

---

## Phase 4 — Run & Compare Loop (max 3 iterations)

Track the current iteration number starting at 1.

### Each iteration:

**Step 1 — Run xcodebuild**

```
cd EncoreSwiftUiKit && xcodebuild test \
  -scheme EncoreSwiftUiKit \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:EncoreSwiftUiKitTests/COMPONENT_NAMESnapshotTest \
  TEST_RUNNER_SNAPSHOTS_EXPORT_DIR=$(pwd)/EncoreSwiftUiKitTests/snapshot/exports
```

Exported PNG(s) land in `EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/exports/`. Find the file whose name contains `PREVIEW_NAME`.

**Step 2 — Generate pixel diff (skip if ImageMagick unavailable)**

Get the snapshot's pixel dimensions:
```
magick identify SNAPSHOT_PATH
```

Create the deltas directory, resize the reference, then diff:
```
mkdir -p EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/deltas
magick REFERENCE_PNG -resize WxH! /tmp/reference_resized.png
magick compare /tmp/reference_resized.png SNAPSHOT_PATH \
  EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/deltas/COMPONENT_NAME_diff.png || true
```

`magick compare` exits with code 1 when images differ — expected, not an error.

**Step 3 — Vision comparison**

Read `reference_png`, the exported snapshot, and the diff image (if available) with vision. Evaluate match across:
- Layout structure (variants present, grid arrangement)
- Colors (backgrounds, foregrounds, tints)
- Typography (font weight, size, spacing)
- Spacing and padding
- Component states

**Step 4 — Decide**

| Situation | Action |
|---|---|
| Match | Go to Phase 5 — success output |
| **Structural mismatch**: preview doesn't contain the variants shown in the reference | Exit immediately with structural error — do not retry |
| **Rendering mismatch** (correct structure, wrong colors/font/spacing) and iterations < 3 | Fix component implementation; increment count; repeat loop |
| **Rendering mismatch** after 3 iterations | Exit with rendering exhaustion error |

**Structural error:**
```
⛔ ERROR: Unable to produce a snapshot matching the reference after N attempt(s).
The preview "PREVIEW_NAME" cannot reproduce the layout shown in the reference PNG.
The preview source may need to be updated to include the required variants
before snapshot testing can proceed.
```

**Rendering exhaustion error:**
```
⛔ ERROR: Component rendering did not match the reference after 3 iteration(s).
The preview layout is structurally correct, but colors, typography, or spacing differ.
Review the component implementation for styling discrepancies before retrying.
Last diff image: EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/deltas/COMPONENT_NAME_diff.png
Test file retained at: EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/COMPONENT_NAMESnapshotTest.swift
```

---

## Phase 5 — Output

**On success:**
```
✅ SNAPSHOT MATCH
Component: COMPONENT_NAME
Preview: PREVIEW_NAME
Snapshot: EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/exports/SNAPSHOT_FILENAME
Test file retained at: EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/COMPONENT_NAMESnapshotTest.swift
```

**On rendering mismatch (calling agent should continue iterating):**
```
❌ SNAPSHOT MISMATCH
Divergences detected:
  - AREA: DESCRIPTION OF DIVERGENCE
  - AREA: DESCRIPTION OF DIVERGENCE
Diff image: EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/deltas/COMPONENT_NAME_diff.png
Test file retained at: EncoreSwiftUiKit/EncoreSwiftUiKitTests/snapshot/COMPONENT_NAMESnapshotTest.swift
```
