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
  owner-scoped AceConfig controls and cleanup; DBM for restrained navigation
  highlights and slider proportions; Altoholic for state-local navigation;
  Auctionator for search/control and native-colour preservation. Their
  different GUI architectures are not copied into Atlas. AtlasLootClassic Continued was
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

Iteration 3 removes the extra header, toolbar, info and legend fills added in
iteration 2. The unwanted upper-right rectangle corresponds to `d.info`, an
anonymous texture owned by `AtlasFrame`, at BACKGROUND sublevel -7 and the root's
unchanged frame level/strata, anchored from (538, -82) to TOPRIGHT (-18, -197).
It was not an independently raised window. Only the original full-window fill
at BACKGROUND sublevel -8 remains; native text-frame placement separates the
information sections without stacked opaque panels or clipping changes.

The anonymous `AtlasFrame-*`, `AtlasFrameSmall-*` and `AtlasFrameLarge-*`
composites contain the stone, metallic edges and globe. Discovery now matches
exact normalized asset basenames and resolved file IDs; opaque-ID fallback is
limited to inspected ARTWORK/BORDER root slots, accepting subpixel rounding and
native named/implicit parent references. Known map paths are excluded even if
their dimensions match. Incomplete construction is retried at owned show/refresh
points instead of permanently caching an early empty pass. Completed roots
perform no region walk on warm show callbacks.

The screenshots confirm that the original composite survived the previous
pass. Source-shaped tests reproduce failures from the earlier path/geometry
assumptions and early caching; the specific texture getter/anchor values on the
user's live client cannot be measured from a screenshot and remain unverified.

The globe is baked into the TopLeft texture rather than being an independent
button. Its ORIGINAL texture is now cropped (including its rim), masked and
resized to 32-by-32 at header offset (16, -9). No second globe texture is created,
even if the original is not identified until a later show. The same Blizzard
portrait mask Atlas uses for pins is reused. No image is redistributed. Native
root drag/click/tooltip handling stays unchanged. Native open/closed lock
textures retain their state changes, desaturation and subdued tint.

LibDD's existing clickable child arrow is styled directly with a 10-pixel EUI
chevron; the adapter does not also request EUI's root-level decorative arrow.
Other child actions/icons are not removed or merged. Atlas-owned menus opt out
of the accent stripe and use subdued submenu chevrons plus compact checks.
`Menus.lua` adds only an opt-in `compactChecks` treatment because its owned marker
art is private to the shared renderer. Existing callers retain their defaults;
foreign/default reuse hides the new artwork and restores native cosmetics.
Iteration 3 also fixes the opt-in chevron's visibility: LibDD hides the actual
ExpandArrow button while its normal texture's own shown flag remains true.
The replacement now follows both, so leaf rows cannot acquire false submenu
arrows. Native expansion button anchors, callbacks and hit areas do not change.
The other chevron caller (KiwiFarm) and default menu paths retain regression
coverage; no unrelated addon adapter changes.

General, Options and Profiles AceConfig categories receive scoped backgrounds,
buttons, dropdowns, compact checks and sliders. Pooled input fonts remain
native; changed cosmetics are restored on release or foreign reuse, including
dropdown items. Late controls are handled after owned FeedGroup completion.
The Atlas world-map launcher alone is styled; the world map is not traversed.

Owned AceGUI InlineGroup content-parent backdrops and TreeGroup tree/content
backdrops are explicitly cleared/restored, rather than scanning anonymous UI.
Tree rows use restrained accent selection/hover fills and keep native text and
icons. Atlas's optional standalone AceGUI frame also styles its owned close and
status controls. Blizzard Settings' shared shell/navigation remain owned by
EUI's existing skin. Compact checks use a contained 14-pixel hover and 8-pixel
indicator. Horizontal sliders use a two-pixel track and 10-by-14 visible grip;
vertical grips are 5-by-22. Native thumbs, drag/hit areas and ranges retain their
geometry; only their artwork alpha is replaced. Dropdown items are styled at
pullout Open and repaired after native SetValue/click/disabled changes.

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

Iteration 2 adds path/file-ID composite chrome fixtures, one contained globe per
size, semantic art exclusions, child-arrow/favourite-action isolation, both lock
states, child-backdrop restoration, tree selection, native-style Ace dropdown
items, disabled sliders and the public PageButton's Button-state API contract.
`tests/menus_spec.lua` covers compact versus default owners, marker-state updates,
disabled/foreign cleanup and 1,000 stable menu refreshes without new marker art
or check-marker colour writes.

Per client, 1,000 warm legend updates create zero UI objects/hooks and perform
zero hierarchy reads/font writes. 1,000 stable checkbox value/disabled updates
likewise add no objects/hooks/scans/fonts, with at most one initial disabled
state colour normalization. These are mock operation counts, not client CPU,
FPS, taint or retained-memory measurements.

An additional 1,000 warm open/map/options/tree callback cycles per client also
add no UI objects/hooks, hierarchy reads or font writes. Styling is cached per
theme generation and ownership acquisition; no polling or timers are added.

Iteration 3 adds assertions for exactly one full-window fill, no new globe art,
reuse of the original globe/rim, unchanged levels/strata/text, late texture
assignment with an unchanged region count, numeric IDs, normalized basenames,
subpixel anchors and hidden native submenu buttons. The previous implementations
fail the new regression assertions.

## In-game verification still required

On each client with current Atlas and suitable separately installed map modules:

1. Open/reopen all three sizes; lock, drag, scale, resize and collapse/expand.
   Confirm complete maps/tiles, original proportions, readable headers and
   legend data at opaque and transparent Atlas settings.
   Check the smaller globe's crop/placement and the remaining separation of
   native upper/lower information sections over the single matte background.
2. Change map type/map, navigate back/forward, search/clear, scroll the legend
   and hover/click native pins and entries. Check dropdown/submenu reuse.
3. Open General, Options and Profiles; change checkboxes, scales and dropdowns.
   Reopen, switch to another addon's settings, and change EUI font/accent/theme.
   Verify both Settings-hosted and standalone Atlas options where available,
   including selected navigation, menu markers and disabled controls.
4. On Retail, inspect the optional EJ loot view, filters, scrolling and item
   tooltips/quality. On Forever, confirm its absence causes no errors.
5. Verify the optional world-map launcher and AtlasLoot launcher when present,
   and operation without those integrations. Check combat deferral/recovery.

Actual client rendering, protected-state behaviour and long-session behaviour
remain unverified until this test build is exercised in WoW.
