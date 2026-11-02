# AtlasLoot Continued / Forever shared skin

Branch: `skin/atlasloot-forever`, based on released main `1e45cec` (1.6.2).
OneForAll PR #68 and its approved runtime are not included or modified.

## Supplied sources

| Archive | SHA-256 | Core identity / metadata |
| --- | --- | --- |
| AtlasLootClassic-Continued_12902.zip | `99495f460e236f310ee494b7c1e287e010712be88a3c0a7004917bc24ff016a5` | `AtlasLootContinued`, version 12902 |
| AtlasLoot Classic Forever 1.2.7-211026-16001.zip | `f7846e00f4957f6ac534c50c301f850a3a4b0965f4d967b2e58f123cc33bd638` | `AtlasLootClassic`, TOC version **Forever 1.60.1** (different from archive name) |

The Forever ZIP uses backslashes in member names. Analysis normalizes separators
when extracting to the Linux workspace; original uploads remain unchanged.
Target code/assets are not redistributed in this MIT adapter or its packages.

## Architectural comparison

| Area | Continued 12902 | Supplied Forever | Consequence |
| --- | --- | --- | --- |
| Modules | Core plus BiS, Collections, Crafting, Data, DungeonsAndRaids, Factions, Favourites, Options, PvP | Core plus Collections, Crafting, Data, DungeonsAndRaids, Factions, Options, PvP and AtlasBIStooltips | Folder aliases must differ; do not force-load modules |
| TOCs | Camelot 16000/16001/120100; Vanilla 11509; TBC 20506; Wrath 30404 | Base and `_Forever` TOCs declare 16001 | Metadata is not real-client certification; no target TOC edits |
| Dependencies | Optional Ace3, shared media/widgets, LibDBIcon/Broker | Same, plus optional Atlas/DevTool; AtlasBIStooltips depends on core | No new skin/library dependency |
| Global / GUI | `_G.AtlasLoot`, `.GUI`, `AtlasLoot_GUI-Frame` | Same | One adapter and stable existing toggle |
| Saved variables | AtlasLootDB | AtlasLootClassicDB; BiS helper uses slcDB | Skin touches neither; do not enable both forks together |
| Bootstrap | Compat.lua before Init; numeric revision parsing | No Compat.lua; C_AddOns metadata, older version/project parsing | Native bootstrap differs, not skin-owned |
| Widget factories | CreateDropDown, CreateSelect, CreateCheckBox, CreateButton, CreateTextWithBg, CreateModel | Same implementations | Reuse existing treatment |
| Main / item display | GUI.lua and ItemFrame; named content, search, selectors, item buttons | Same structure; different version selection, map paths, auto-selection/data behavior | Preserve native data/version/map logic |
| Dropdowns/selectors | Custom AtlasLoot-DropDown and Select naming, pooled categories/rows | **Identical** source after newline/BOM normalization | Existing synchronous menu/selection code applies |
| Sound/model | SoundFrame, model canvases and UI textures | SoundFrame and model templates identical | Preserve models, sounds and artwork |
| Favourites | Separate load-on-demand module, Addons:GetAddon('Favourites') | Built into core Addons/Favourites*.lua; same Addons registry and GUI methods | Existing lookup and lazy hooks cover both |
| Settings | Load-on-demand AceConfig app `AtlasLoot` | Same app key, OpenFrames key and Show/ShowAddon | Existing owned settings root/FeedGroup filter applies |
| Extra Forever UI | Not applicable | BiS and fading PSA footers under main frame; PvP extensions under Blizzard PVPFrame; tooltip/BiS module | Main footers are discovered with the main subtree; only phase dropdown needs a small adapter |

Compared all core Lua paths (83 Continued / 82 Forever including bundled library
Lua). Both have ten GUI Lua files. Eight relevant files match exactly after text
normalization: Template_DropDown, Template_Select, Template_CheckBox,
Template_Button, Template_TextWithBg, Template_Model, SoundFrame and Addons.
GUI.lua has approximately 97.4% matching lines; ItemFrame 97.7%; Button 99.2%
(SequenceMatcher with autojunk disabled; descriptive similarity, not proof of
behavior). Tooltip/data/client APIs differ and remain entirely native.

Initialization uses native ADDON_LOADED callbacks and lazy GUI/module loading.
The skin waits for target enable/load, EUI facade and GUI readiness. Existing
Create/Toggle/style/font/item/favourites hooks plus Scoped's load/show/look and
combat recovery handling provide the shared lifecycle. No global frame factory,
AceGUI replacement, polling, native data refresh or extra gameplay event hook.

## Implementation

- Add `AtlasLootClassic` as the second target of the existing
  `AtlasLootContinued` catalog entry in Lua and Python. Shared Loader already
  supports target arrays (as used by DBM, ItemRack and Scrap); no shared logic or
  helper default changes. All client manifests already include this skin file.
- Preserve module ID and the **AtlasLootClassic Continued** EUI setting name,
  so existing saved per-skin preferences are retained. This one setting now
  controls either variant. README names both variants.
- Reuse all approved main window, favourites, item/rarity, search, checkbox,
  slider, custom dropdown, map/model and options styling.
- Style only the known owned `AtlasLoot_BiSPhaseDropdown` through public
  `S.Dropdown`. Scoped already binds its native `initialize` menu owner through
  the shared ownership helper. No second menu, click handler or label is added;
  phase colours and native callbacks remain intact.
- Native Create post-hooks queue/coalesce the completed main subtree, including
  later chained native footer constructors. PSA fade/timer behavior stays native.

Both forks publish the same `_G.AtlasLoot` singleton and named frames. **Test one
variant at a time.** Co-loading them is an upstream collision, not two separate
skin instances to support.

## Confirmed upstream blocker in supplied Forever build

Its Init.lua reads the TOC Version `Forever 1.60.1`, then matches
`v(%d+)%.(%d+)%.(%d+)`. That produces no components, `tonumber('')` yields nil,
and line 35 passes nil to `%d` in `string.format`. Executing the **unmodified
supplied Init.lua**, with C_AddOns.GetAddOnMetadata returning that exact TOC
value, reproduces:

```
AtlasLootClassic/Init.lua:35: bad argument #3 to 'format' (number expected, got nil)
```

This was reproduced in host Lua 5.4; there is no actual Forever run here. The
parser/value mismatch is source-confirmed and must be resolved by the addon
maintainer or a corrected target build before end-to-end initialization can be
accepted. The skin does not rewrite target metadata, repair native data modules
or conceal target errors. Do not treat passing widget fixtures as proof that
the supplied complete addon boots.

Its older project detection also maps a mainline identity to RETAIL_VERSION_NUM,
while its GUI separately forces Classic data selection. Continued has explicit
Forever handling. This is native game/data routing; the adapter deliberately
uses neither project's game-version constants. Actual Forever behavior still
needs client verification after the startup blocker is resolved.

## Scope limitations

Shared core/favourites/options and the main-window BiS/PSA footers are covered.
Forever's separate AtlasBIStooltips and additions attached to Blizzard's PvP
window are not claimed as newly skinned surfaces. The latter are created by
anonymous native OnUpdate loops, outside the owned AtlasLoot GUI tree, with
no exported completion callback. Supporting them reliably deserves a separate
explicit ownership/lifecycle adapter; this extension does not add polling or
replace Blizzard's PvP skin. Native tooltip augmentation and quality/status
colours remain unchanged.

Native Forever already has a PvP tracker OnUpdate loop, additional one-shot
OnUpdate injectors, currency updates and a PSA timer/fade. Their costs belong to
the target; this skin neither hooks those loops nor claims to eliminate them.

## Verification and performance

- 43 registered suites pass, with the previous Continued coverage retained and
  repeated for Forever's namespace/widget contract and real mainline identity.
  No invented Forever project constant is required.
- New loader regression runs both target folders independently with modern and
  legacy addon API fixtures: late target/EUI/GUI, disabled skin/character,
  combat deferral, native module readiness and exactly one definition/toggle.
- Both variant fixtures preserve item colour/count/phase/favourite art, maps,
  models, native selector actions, synchronous popup styling, dynamic controls,
  footer checkbox/phase input, theme colours and combat/disable handling.
- Optional source-backed run executes each supplied real
  GUI/Template_DropDown.lua: constructor, category/row pools, native click args,
  semantic colours, shrink/reopen and hook reuse. Other main-window and settings
  coverage is source-shaped plus source review, not a full native addon boot.
- Baseline main adapter and candidate use the same workload: a burst of 100 item
  refresh callbacks produces **one main-root scan**, **zero added regions** and
  stable hook identity in both variants. Existing full visible-root scans still
  occur; this task does not claim zero traversal or a performance optimization.
  No new persistent adapter cache, timer, per-frame handler or repeated hook.
  These are deterministic mock counts, not real CPU, memory, GC, FPS or latency.
- `python3 scripts/package.py` passes Lua/regressions/catalog/manifest/version/
  license checks: 59 files in one addon folder, 42 deferred skin factories.
  Test/docs/target sources are excluded; version remains 1.6.2.

Source-backed command, from repository root:

```sh
ATLASLOOT_CONTINUED_SOURCE=/path/to/AtlasLootContinued \
ATLASLOOT_FOREVER_SOURCE=/path/to/AtlasLootClassic \
python3 tests/run_lua.py
```

`tests/atlasloot_source_fixture.lua` uses mocked WoW/EUI APIs and does not ship.
No actual supported WoW client has been run in this environment. Upstream TOC
Classic support is not a claim that current EllesmereUI supports every Classic
client; the installed host EUI must itself support the selected client.

## Install and in-game review

Both test ZIP names contain the **same universal EUIAddonSkins payload**. Use
one ZIP, not both; neither includes AtlasLoot itself. Preserve saved variables.
Enable EUI, Blizzard Skins+ and **one** target fork, with the existing
AtlasLootClassic Continued third-party skin toggle enabled.

1. Forever: first obtain a maintainer-corrected build that passes native startup;
   record its exact version. `/reload`, verify /euiskins diagnostics shows target
   loaded, EUI callback and integration active. No need to enable the other fork.
2. Open main window, reopen, change category/instance/boss, difficulty and pages;
   exercise search, class filters, item links/modifier-clicks and tooltips. Check
   rarity/count/favourite/phase colours, map artwork and model controls.
3. Open favourites and options late, switch tabs, change settings, shrink/reopen
   dropdowns. Confirm native actions and first-render styling.
4. Forever: verify BiS checkbox/class filter/phase dropdown/currency/status text
   and PSA fade. PvP side extensions remain native as scoped above.
5. Change EUI accent/theme/font; verify visible and later-opened controls. Test
   combat open/changes/recovery, skin disable/reload, scaling and native opacity.
6. Repeat core/favourites/options checks with Continued only. Report client build,
   target version and errors/screenshots; no temporary diagnostic instrumentation.

Keep PR draft until actual client review and the supplied Forever startup
blocker are resolved. No merge, release metadata changes, tags or publication.
