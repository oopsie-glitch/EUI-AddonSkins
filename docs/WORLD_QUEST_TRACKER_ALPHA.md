# World Quest Tracker alpha

Branch: `skin/world-quest-tracker-initial`, based on stable v1.5.2. Untagged; no CurseForge or Wago publication.

Reference: Tercioo/World-Quest-Tracker tree `4391a6a91ce959edcba80316e1a0a71dd2bfb94c` (Retail). No upstream Lua or assets are bundled.

## Coverage

- Options window: cohesive dark shell, subtle centre brightness, neutral labels and selected-tab accent.
- DetailsFramework checkboxes, dropdowns, sliders, inputs and action buttons, including hidden options pages.
- Owned Cooltip menus and pooled dropdown rows, plus finder, statistics, blacklist, share, news and flight windows.
- Matte tracker rows, square reward icons and EUI fonts. Reward/urgency colours, tracking overlays, quest actions, navigation and native sizing remain controlled by World Quest Tracker.
- World/zone quest icon crops; rarity, faction, tracking and objective indicators retain their meaning and native artwork.

## Validation

`python3 scripts/package.py` validates Lua, runs the full regression suite and verifies the one-folder ZIP and MIT license.

The focused test covers deferred options construction, hidden pages, preserved native returns/actions, checkbox state, disabled/enabled colours, pooled menus, new icons/rows, theme changes and combat/toggle deferral. It checks that 300 warm tab changes cause no hierarchy walks, font writes or UI-object allocation in the mock environment. Native tracking/update callbacks are not replaced or polled.

These are automated checks, not an in-game rendering, FPS or taint verification. This build is an alpha for Retail; the navigation arrow and default Blizzard map are not redesigned.
