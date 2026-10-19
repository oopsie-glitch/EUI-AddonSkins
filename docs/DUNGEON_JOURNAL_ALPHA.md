# Dungeon Journal alpha

Branch: `skin/dungeon-journal-refresh`, based on v1.5.1. Untagged; no platform publication.

## Changes

- Add a charcoal browsing canvas with a soft centre highlight. Its mouse-disabled visual layer shares the panel frame level and is excluded from scans. Preserve dungeon artwork, quest/faction indicators, completion states and card actions.
- Use near-white card titles, softer title bands and neutral idle borders. Native gold hover borders follow the selected accent; other semantic border colours remain native.
- Refine vertical scrollbar thumbs and chevrons, the language caret and resize grip. Keep native scrolling, resize gestures and hit areas. Align existing search/report/language control heights without changing native widths.
- Apply flat inset accent markers to Loot Filter checkboxes, including disabled markers. Keep values, checked visibility, label colours, click callbacks and filter logic native.

## Refresh handling

Control events queue their owned subtree. A pending full render refresh supersedes those scans. Skip warmed hidden roots, retain map-art exclusions, reuse visual objects and avoid unchanged public font applications. Current quest workers are covered by completed exported render callbacks; older versions without the quest exports retain their original one-shot worker fallback. Defer styling during combat and resume on PLAYER_REGEN_ENABLED. No shared runtime files or saved-variable schemas change.

## Verification

`python3 scripts/package.py` validates Lua, all regression suites, manifests, MIT license and the 39-file single-folder ZIP. Fixtures cover checkbox actions/visibility, disabled and theme states, protected controls, combat deferral, map exclusions, card artwork/status preservation, scrollbar and resize actions, and visual reuse. A simulated burst of 100 home refresh callbacks coalesces to one root scan with no new canvas or title-font writes. Actual WoW rendering, frame time and taint behaviour cannot be verified here.

Sources reviewed: marcusowensofficial-design/ForeverDungeonJournal `UI/HomeTab.lua`, `UI/MainFrame.lua`, `UI/SearchWishlist.lua`, `Systems/LootFilter.lua`, `Systems/OptionsPanel.lua`, `Systems/Resize.lua`, `Core/Journal.lua` and the public EllesmereUI widget helpers. No source or assets from those addons are bundled.

## Popup follow-up

Remove the main journal's top accent line while keeping popup accents and active-tab feedback. Use accent headings and neutral descriptive text in Loot Filter. Style icon-bearing action buttons and both custom and legacy dropdown shapes, preserving selected artwork and native click targets. Keep the existing footer widths, align the Show results icon/label and give the numeric input a subtle outline without adding input padding. Register the filter as a scoped popup-menu owner where the shared menu helper is available.

Favourites gets a charcoal centre-highlight canvas, a clean inset, a brighter empty-state message and accent headings. Replace the oversized circular header decoration with the addon's existing star artwork in a contained 22-unit mouse-disabled layer. Item-row icons, quality colours and favourite actions are preserved. Soften the browsing divider to neutral grey.

Popup roots are excluded from their parent's scan and deduplicated across local/global aliases. Regression fixtures cover red native texture removal, both dropdown shapes, icon alpha, native footer/input/dropdown actions, no main accent, hidden portrait/stone textures, contained star geometry, heading colours and stable visual allocations. All package checks pass. The Retail fork's exact source was not supplied; supported control shapes are verified in mocks, with actual rendering still unverified.
