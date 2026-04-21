# Design Tokens — EncoreSwiftUiKit (iOS)

Source files:
- **Typography:** `EncoreSwiftUiKit/EncoreSwiftUiKit/Common/Typography.swift`
- **Spacing:** `EncoreSwiftUiKit/EncoreSwiftUiKit/Common/Spacing.swift`
- **Colours:** `EncoreSwiftUiKit/EncoreSwiftUiKit/Assets/Assets.xcassets/Color/`

---

## Colours

Colours are defined as named color assets in `Assets.xcassets/Color/`. Each asset supports **light and dark appearance** variants.

### Brand

| Token | Light |
|-------|-------|
| `brand_purple` | `#B066FF` |
| `brand_green` | `#00D273` |
| `brand_blue` | `#14B4EF` |
| `brand_red` | `#FF6429` |

### Greyscale

| Token | Hex |
|-------|-----|
| `white` | `#FFFFFF` |
| `black` | `#000000` |
| `grey/50` | `#F5F5F5` |
| `grey/100` | `#E0E0E0` |
| `grey/200` | `#C2C2C2` |
| `grey/300` | `#A3A3A3` |
| `grey/400` | `#8F8F8F` |
| `grey/500` | `#757575` |
| `grey/600` | `#666666` |
| `grey/700` | `#525252` |
| `grey/800` | `#323232` |
| `grey/900` | `#141414` |

### Colour Palette

Each hue has steps 50–900 plus accent variants A100/A200/A400/A700/A900 and B100/B200/B400/B700/B900. The table below lists the main 50–900 scale for each hue.

#### Purple

| Step | Hex |
|------|-----|
| 50 | `#F7F3FF` |
| 100 | `#E2D3FF` |
| 200 | `#CEB2FF` |
| 300 | `#BC90FF` |
| 400 | `#AB69FF` |
| 500 | `#944DE7` |
| 600 | `#8122D9` |
| 700 | `#6100A9` |
| 800 | `#3F0070` |
| 900 | `#220042` |

#### Blue

| Step | Hex |
|------|-----|
| 50 | `#F0F5FF` |
| 100 | `#C8DCFF` |
| 200 | `#9FC2FF` |
| 300 | `#76A7FF` |
| 400 | `#4B8BFF` |
| 500 | `#266EF1` |
| 600 | `#0054DD` |
| 700 | `#003DA5` |
| 800 | `#00266E` |
| 900 | `#001341` |

#### Light Blue

| Step | Hex |
|------|-----|
| 50 | `#ECF7FF` |
| 100 | `#BDE2FF` |
| 200 | `#8ACDFF` |
| 300 | `#51B7FC` |
| 400 | `#359FE3` |
| 500 | `#0188CC` |
| 600 | `#0070A9` |
| 700 | `#00517C` |
| 800 | `#003351` |
| 900 | `#001A2D` |

#### Green

| Step | Hex |
|------|-----|
| 50 | `#DEFFED` |
| 100 | `#A9EFCA` |
| 200 | `#82D9AA` |
| 300 | `#61BD8C` |
| 400 | `#3B9D69` |
| 500 | `#0E8345` |
| 600 | `#006E33` |
| 700 | `#005226` |
| 800 | `#003619` |
| 900 | `#001F0E` |

#### Yellow

| Step | Hex |
|------|-----|
| 50 | `#FFF4DE` |
| 100 | `#FFE9BE` |
| 200 | `#FFDE9B` |
| 300 | `#FFD275` |
| 400 | `#FFC643` |
| 500 | `#F6BC2E` |
| 600 | `#C99600` |
| 700 | `#8C6700` |
| 800 | `#513A00` |
| 900 | `#221600` |

#### Orange

| Step | Hex |
|------|-----|
| 50 | `#FFF2ED` |
| 100 | `#FFD4C5` |
| 200 | `#FFB599` |
| 300 | `#FF926A` |
| 400 | `#FC6B2F` |
| 500 | `#E65301` |
| 600 | `#BE4300` |
| 700 | `#8A2F00` |
| 800 | `#581B00` |
| 900 | `#2F0A00` |

#### Red

| Step | Hex |
|------|-----|
| 50 | `#FFE0DB` |
| 100 | `#FFB6AB` |
| 200 | `#FF8776` |
| 300 | `#FF4637` |
| 400 | `#E30000` |
| 500 | `#B50000` |
| 600 | `#8A0000` |
| 700 | `#610000` |
| 800 | `#3A0000` |
| 900 | `#180000` |

### Semantic Colours

Semantic colours map the palette to roles. They are applied directly in components.

#### Text

| Token | Hex |
|-------|-----|
| `text/primary` | `#141414` |
| `text/secondary` | `#666666` |
| `text/disabled` | `#C2C2C2` |

#### Action

| Token | Hex |
|-------|-----|
| `action/active` | `#666666` |
| `action/hover` | `#F5F5F5` |
| `action/selected` | `#E0E0E0` |
| `action/focus` | `#757575` |
| `action/disabled` | `#C2C2C2` |
| `action/disabled_background` | `#E0E0E0` |

#### Primary (Blue)

| Token | Hex |
|-------|-----|
| `primary/main` | `#266EF1` |
| `primary/dark` | `#0054DD` |
| `primary/light` | `#9FC2FF` |
| `primary/contrast_text` | `#FFFFFF` |
| `primary/focus_visible` | `#C8DCFF` |
| `primary/outlined_border` | `#266EF1` |

#### Secondary (Purple)

| Token | Hex |
|-------|-----|
| `secondary/main` | `#944DE7` |
| `secondary/dark` | `#8122D9` |
| `secondary/light` | `#CEB2FF` |
| `secondary/contrast_text` | `#FFFFFF` |
| `secondary/focus_visible` | `#E2D3FF` |
| `secondary/outlined_border` | `#944DE7` |

#### Semantic States

| Role | main | dark | light | focus_visible |
|------|------|------|-------|---------------|
| Error | `#B50000` | `#8A0000` | `#FF8776` | `#FFB6AB` |
| Warning | `#E65301` | `#BE4300` | `#FFB599` | `#FFD4C5` |
| Highlight | `#F6BC2E` | `#C99600` | `#FFDE9B` | `#FFE9BE` |
| Info | `#0188CC` | `#0070A9` | `#8ACDFF` | `#BDE2FF` |
| Success | `#0E8345` | `#006E33` | `#82D9AA` | `#A9EFCA` |

All semantic states have `contrast_text: #FFFFFF`.

#### Background

| Token | Hex |
|-------|-----|
| `background/default` | `#FFFFFF` |
| `background/column_heading` | `#F5F5F5` |

#### Component Colours

| Token | Hex | Usage |
|-------|-----|-------|
| `divider` | `#C2C2C2` | Divider lines |
| `elevation/outlined` | `#C2C2C2` | Outlined elevation |
| `avatar/fill` | `#A3A3A3` | Avatar background |
| `snackbar/fill` | `#323232` | Snackbar background |
| `tooltip/fill` | `#323232` | Tooltip background |
| `backdrop/fill` | `#000000` | Backdrop overlay |
| `app_bar/default_fill` | `#E0E0E0` | App bar |
| `rating/enabled_border` | `#8F8F8F` | Star border |
| `rating/active_fill` | `#F6BC2E` | Active star fill |
| `switch/knob_fill_enabled` | `#F5F5F5` | Switch knob |
| `switch/slide_fill` | `#000000` | Switch track |

#### Input

| Token | Hex |
|-------|-----|
| `input/standard_enabled_border` | `#757575` |
| `input/standard_hover_border` | `#000000` |
| `input/filled_enabled_fill` | `#E0E0E0` |
| `input/filled_hover_fill` | `#C2C2C2` |
| `input/outlined_enabled_border` | `#8F8F8F` |
| `input/outlined_hover_border` | `#141414` |
| `input/outlined_read_only_fill` | `#F5F5F5` |

#### Chip

| Token | Hex |
|-------|-----|
| `chip/default_close_fill` | `#000000` |
| `chip/default_hover_fill` | `#C2C2C2` |
| `chip/default_enabled_border` | `#A3A3A3` |
| `chip/default_focus_fill` | `#C2C2C2` |

#### Alert Colours

| Variant | Color | Background |
|---------|-------|------------|
| Error | `#180000` | `#B50000` |
| Warning | `#2F0A00` | `#E65301` |
| Info | `#001A2D` | `#0188CC` |
| Success | `#001F0E` | `#0E8345` |

#### Status Chip Colours

| Variant | Background | Bold/Text |
|---------|------------|-----------|
| Grey | `#E0E0E0` | `#757575` |
| Purple | `#E2D3FF` | `#944DE7` |
| Blue | `#C8DCFF` | `#266EF1` |
| Light Blue | `#BDE2FF` | `#0188CC` |
| Green | `#A9EFCA` | `#0E8345` |
| Yellow | `#FFE9BE` | `#F6BC2E` |
| Orange | `#FFD4C5` | `#E65301` |
| Red | `#FFB6AB` | `#B50000` |

---

## Typography

**Font family:** Inter (Regular, Medium, MediumItalic, SemiBold)  
**PostScript name prefix:** `Inter18pt-` (e.g. `Inter18pt-Medium`)  
**Usage:** `Text("…").typography(Typography.h1)`

> `link*` styles require `.underline()` modifier. `overline*` styles require `.textCase(.uppercase)`. `Status.label` requires `.textCase(.uppercase)`.

### Base Type Scale

| Token | Weight | Size | Tracking |
|-------|--------|------|----------|
| `h1` | Medium | 42pt | — |
| `h2` | Medium | 36pt | — |
| `h3` | Medium | 32pt | — |
| `h4` | Medium | 24pt | — |
| `h5` | SemiBold | 20pt | — |
| `h6` | SemiBold | 16pt | — |
| `label0` | Medium | 16pt | — |
| `label1` | Medium | 14pt | — |
| `label2` | Medium | 12pt | — |
| `label3` | Medium | 10pt | 0.46 |
| `body0` | Regular | 16pt | — |
| `body1` | Regular | 14pt | — |
| `body2` | Regular | 12pt | — |
| `body3` | Regular | 10pt | 0.46 |
| `italics0` | MediumItalic | 16pt | — |
| `italics1` | MediumItalic | 14pt | — |
| `italics2` | MediumItalic | 12pt | — |
| `italics3` | MediumItalic | 10pt | 0.46 |
| `link0` | Medium | 16pt | — |
| `link1` | Medium | 14pt | — |
| `link2` | Medium | 12pt | — |
| `subtitle1` | Regular | 14pt | 0.15 |
| `subtitle2` | Medium | 12pt | 0.17 |
| `overline0` | SemiBold | 16pt | — |
| `overline1` | SemiBold | 14pt | — |
| `overline2` | SemiBold | 12pt | — |
| `overline3` | SemiBold | 10pt | 0.46 |
| `caption` | Regular | 10pt | 0.4 |

### Component Styles

| Token | Weight | Size | Tracking |
|-------|--------|------|----------|
| `Alert.title` | Medium | 16pt | 0.15 |
| `Alert.description` | Regular | 14pt | 0.15 |
| `Avatar.initialsXLg` | SemiBold | 24pt | 0.14 |
| `Avatar.initialsLg` | SemiBold | 16pt | 0.14 |
| `Avatar.initialsMd` | SemiBold | 12pt | — |
| `Avatar.initialsSm` | SemiBold | 10pt | — |
| `Badge.label` | Medium | 12pt | 0.14 |
| `BottomNavigation.activeLabel` | Regular | 14pt | 0.4 |
| `Button.large` | SemiBold | 16pt | — |
| `Button.medium` | SemiBold | 14pt | — |
| `Button.small` | SemiBold | 12pt | — |
| `Chip.labelSmall` | Medium | 13pt | 0.16 |
| `Chip.label` | Medium | 14pt | 0.16 |
| `Chip.labelLg` | Medium | 16pt | 0.16 |
| `Chip.labelXLg` | Medium | 18pt | 0.16 |
| `Status.label` | Medium | 12pt | 0.4 |
| `DatePicker.currentMonth` | Medium | 16pt | 0.15 |
| `Input.label` | Regular | 12pt | 0.15 |
| `Input.value` | Regular | 16pt | 0.15 |
| `Input.helper` | Regular | 12pt | 0.4 |
| `List.subheader` | Medium | 12pt | 0.1 |
| `Menu.itemLarge` | Regular | 16pt | 0.15 |
| `Menu.itemDefault` | Regular | 14pt | 0.15 |
| `Menu.itemDense` | Regular | 12pt | 0.17 |
| `Table.header` | Medium | 12pt | 0.17 |
| `Tooltip.label` | Medium | 10pt | — |
| `DataGrid.aggregationColumnHeaderLabel` | Medium | 12pt | 0.15 |
| `Nav.sidebarCompact` | Medium | 9pt | 0.04 |
| `Nav.sidebarWide` | Medium | 12pt | 0.05 |

---

## Spacing

**Source:** `Spacing` enum (internal) — values are `CGFloat` in points.

| Token | Value |
|-------|-------|
| `Spacing.spacing2` | 2 |
| `Spacing.spacing4` | 4 |
| `Spacing.spacing6` | 6 |
| `Spacing.spacing8` | 8 |
| `Spacing.spacing12` | 12 |
| `Spacing.spacing16` | 16 |
| `Spacing.spacing20` | 20 |
| `Spacing.spacing24` | 24 |
| `Spacing.spacing32` | 32 |
| `Spacing.spacing40` | 40 |
| `Spacing.spacing48` | 48 |
| `Spacing.spacing56` | 56 |
| `Spacing.spacing60` | 60 |
| `Spacing.spacing64` | 64 |
| `Spacing.spacing72` | 72 |
| `Spacing.spacing80` | 80 |
| `Spacing.spacing88` | 88 |
| `Spacing.spacing96` | 96 |

> `Spacing` is declared `internal` — components use it directly; consumers should not reference it. Use the values above as a reference for understanding component layout.
