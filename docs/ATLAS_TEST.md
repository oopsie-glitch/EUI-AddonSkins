# Atlas development verification

Atlas was developed on `skin/atlas-initial` and selected for release 1.6.2.
The owner accepted its current appearance. The client/performance limitations
below remain; paused and unrelated work is excluded.

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
scrollbar. It suppresses only identified Atlas decoration. The current
background uses two adjoining opaque, theme-derived horizontal gradients at
BACKGROUND -8: slightly lighter in the centre and darker at the outer edges.
Header and 35-pixel footer surfaces at BACKGROUND -7 establish restrained
contrast and integrate the native search field/buttons without moving them.
The main information section has a one-pixel horizontal separator at y=-195
and a one-pixel map/information divider at x=534, both BACKGROUND -6. No filled
information or legend rectangle, raised sibling or clipping change is used.
Map artwork, proportions, pins, labels, semantic colours and callbacks remain
native. Atlas's explicit whole-window opacity settings remain authoritative;
the skin's surface alpha is always 1, independent of EUI panel transparency.

Iteration 3 removed the unwanted `d.info` rectangle and redundant composites.
Those fixes remain: no large opaque information-panel overlay is reintroduced.

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
button. Its ORIGINAL globe-and-rim crop again uses the previous round design:
32-by-32 at (16, -9), with the existing Blizzard portrait mask. The obsolete
square slot is removed. Native decorative rim and root interactions remain;
no duplicate globe texture or redistributed image is used.

## Owned control refinement

Atlas's lock button is 36×36 and originally stretches low-resolution 32×32
art containing a red plate and a yellow padlock. The prior adapter preserved
that entire normal/pushed artwork plus its native highlight. It now reuses
those same normal/pushed Texture objects with the existing required EUI core
`media/icons/eui-lock-locked.png` / `eui-lock-unlocked.png` assets, displayed
at 12×16 with full UVs and a one-pixel pressed offset. The decorative native
highlight is suppressed by the public Button primitive. A local UpdateLock
post-hook follows native lock state without replacing its callbacks/returns.
No icon asset is bundled and no optional EUI module is required.

Owned action/arrow/icon controls reuse the public API's fill and hover textures.
Their fill is opaque, slightly lighter than the current theme panel; disabled
states dim and suppress hover. Painting is inset inside the native frame and
redundant pixel borders are disabled through the existing soft-helper opt-in.
No second button surface is created. The same primitive's later fill/anchor
resets repair locally. Options and Lock deliberately overlap by six pixels in
Atlas's constructor; positive hit insets and matching painted bounds separate
Options, Lock and Close without changing their native positions or sizes.
Adjacent Search/Clear buttons have contained inset fills with a small gap.
Borrowed Settings controls keep their separate existing restoration path.

The native 150×32 search EditBox retains its text, font, caret, scripts, text
insets and hit area. Its reused fill is contained to the centred 24-pixel bar.
An empty/unfocused Search hint and one contained input edge identify the field;
the edge follows the current EUI accent while focused. No hint is written into
the actual input. Text/focus events touch only this field's own cosmetics.

LibDD opens selectors from its arrow's OnMouseDown, not the parent Frame. The
adapter enables mouse input on the existing selector Frame and forwards left
clicks from its text field to the original arrow handler with the original
receiver. Native arrow scripts, menu anchoring, selection and submenus remain
unchanged. The clickable field excludes LibDD's decorative left/top/bottom
padding and does not cover the label or neighboring selector. Child actions
remain independent. Disabled/hidden arrows, disabled skin and combat gate the
added field-click path. A small local hover wash is reused on reopening. Each selector also has one
contained one-pixel bottom accent bar at alpha 0.65, synchronized with the EUI
accent on look changes (grey while disabled). This is an Atlas-specific choice;
no menu top stripe or shared-helper default was changed.


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
The same warm open/map/options/tree workload also performs zero geometry or
icon-texture writes. One thousand native search text/focus cycles create no
objects/hooks or hierarchy/font work; these remain mock operation counts.

Regression coverage checks the adjoining opaque surface, no new globe art,
reuse of the original globe/rim, unchanged levels/strata/text, late texture
assignment with an unchanged region count, numeric IDs, normalized basenames,
subpixel anchors and hidden native submenu buttons. The previous implementations
fail the new regression assertions.

## Reopening performance

See [the audit](ATLAS_PERFORMANCE.md) for repeatable before/after timings,
call counts, allocation churn, source review and limits. Completed eager roots
skip warm control passes, nested map/legend styling runs once, unrelated addon
loads do not repaint closed Atlas, and hidden legend cosmetics wait for show.
Pending/changed chrome, look changes, explicit refresh and row/text replacement
remain covered. No actual in-game latency or FPS improvement is claimed.

## In-game verification still required

On each client with current Atlas and suitable separately installed map modules:

1. Open/reopen all three sizes; lock, drag, scale, resize and collapse/expand.
   Confirm complete maps/tiles, original proportions, readable headers and
   legend data at opaque and transparent Atlas settings.
   Check the round globe/rim crop/placement, centre-to-edge shading, header
   and search/footer contrast, and subtle upper/lower information separation.
   Test both lock states/pressed/hover feedback, Options/Lock/Close separation,
   Search/Clear input, accent focus/hint, and Category/Map text/arrow clicks.
   Check neighboring hit areas and disabled/reopened menus at multiple scales.
   Atlas's own opacity slider still fades the entire native window.
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
