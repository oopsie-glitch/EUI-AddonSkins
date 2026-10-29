# Atlas development verification

This is an untagged integration awaiting in-game approval. It is independent of
the unfinished Auctionator and other task branches. No release metadata changes.

## Sources and ownership

- Atlas: arithmandar/Atlas commit `c84758095a216d6508de051471099ebd48ba99e4`.
  The latest changelog heading is v1.54.05; the source TOC version remains the
  upstream `@project-version@` packaging token.
- EllesmereUI reference: commit `5abb35ba158463ca25acc89cadcc56fbb7be6037`
  (Blizzard skin 9.7). No native Atlas integration was found. The adapter uses
  its public skin API through existing EUI AddonSkins soft/control helpers.
- Reference integrations: Attune for custom native windows; HandyNotes for
  owner-scoped AceConfig controls and cleanup. AtlasLootClassic Continued was
  inspected for registration separation and remains unchanged.

Atlas constructs three eager windows, fixed-budget reusable legend entries,
LibUIDropDownMenu controls and borrowed AceConfig widgets. It is not AtlasLoot.
In particular, the large window also owns twelve map tiles directly on its
root: blanket texture stripping would remove meaningful content.

## Coverage

The adapter styles the normal, small and large window chrome, headers, close,
options, lock, size/navigation/legend controls, dropdowns, search and legend
scrollbar. It replaces only the identified Atlas frame decoration and places
one background fill below the native map textures on the same frame. Map
artwork, proportions, pin sprites, labels, legend colours, tooltip handlers,
window geometry and input callbacks stay native.

General, Options and Profiles AceConfig categories receive scoped backgrounds,
buttons, dropdowns, compact checks and sliders. Pooled input fonts remain
native; changed cosmetics are restored on release or foreign reuse, including
dropdown items. Late controls are handled after owned FeedGroup completion.
The Atlas world-map launcher alone is styled; the world map is not traversed.

On supported clients the optional Atlas Encounter Journal loot window receives
its own chrome, filters, scrollbar and row backgrounds. Loot icons, quality
borders, meaningful overlays and callbacks remain native. The AtlasLoot launch
button is styled without touching AtlasLoot's windows or integration.

Shared GameTooltip and StaticPopup warnings retain the existing EUI treatment.
Optional modules' map data and markers are intentionally untouched. Plugin
options registered through Atlas use the owned options path; independently
owned plugin windows are outside this adapter's scope. No upstream code,
libraries or assets are bundled.

## Client findings

Atlas explicitly supports Retail and Forever in its TOC (interfaces 120105 and
16001) and detects `WOW_PROJECT_MAINLINE` / `WOW_PROJECT_CAMELOT` separately in
Data/Constants.lua. Both use its mainline API path and common UI construction;
Forever includes its own Classic area data. Atlas enables Encounter Journal
features for Retail, not Forever. The adapter guards absent optional frames and
does not enable that feature on Forever. This establishes source compatibility,
not successful execution inside either client.

## Automated evidence

`python3 scripts/package.py` compiles Lua, runs the complete regression suite
and verifies catalogs, all three client manifests, unchanged version metadata,
license and the install archive (59 files, one addon folder, 42 factories).
`tests/atlas_spec.lua` independently exercises Retail and Forever fixtures:
root map preservation, native geometry/actions/returns, dropdown ownership,
same-count legend replacement, optional EJ, options pooling/foreign reuse,
release while disabled, theme changes and combat recovery.

Per client, 1,000 warm legend updates create zero UI objects/hooks and perform
zero hierarchy reads/font writes. 1,000 stable checkbox value/disabled updates
likewise add no objects/hooks/scans/fonts, with at most one initial disabled
state colour normalization. These are mock operation counts, not client CPU,
FPS, taint or retained-memory measurements.

## In-game verification still required

On each client with current Atlas and suitable separately installed map modules:

1. Open/reopen all three sizes; lock, drag, scale, resize and collapse/expand.
   Confirm complete maps/tiles, original proportions, readable headers and
   legend data at opaque and transparent Atlas settings.
2. Change map type/map, navigate back/forward, search/clear, scroll the legend
   and hover/click native pins and entries. Check dropdown/submenu reuse.
3. Open General, Options and Profiles; change checkboxes, scales and dropdowns.
   Reopen, switch to another addon's settings, and change EUI font/accent/theme.
4. On Retail, inspect the optional EJ loot view, filters, scrolling and item
   tooltips/quality. On Forever, confirm its absence causes no errors.
5. Verify the optional world-map launcher and AtlasLoot launcher when present,
   and operation without those integrations. Check combat deferral/recovery.

Actual client rendering, protected-state behaviour and long-session behaviour
remain unverified until this test build is exercised in WoW.
