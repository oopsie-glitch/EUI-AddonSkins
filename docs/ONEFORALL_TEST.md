# OneForAll skin

Development branch: `skin/oneforall-eui`, based on released main `1e45cec`.
Awaiting in-game review. No release metadata or shared helper defaults change.

## Sources and identity

- Supplied `OneForAll-6.0.1.zip`, SHA-256
  `7dbde14d2edeffd837285f70c409b05629018ba243096f4354805639efeec48c`.
  Inspected Widgets, MainFrame, all eight panel implementations and their lazy
  dialogs, plus TalentPlanner and the QoL/proximity window constructors.
- Official [EllesmereUI skinning API](https://github.com/EllesmereGaming/EllesmereUI/blob/fc8d3c839af0950f8d6cd5195460ad58cdd760bd/SKINNING_API.md),
  public API v3 at `fc8d3c839af0950f8d6cd5195460ad58cdd760bd`.
- Reference integrations: ForeverCompanion's owned constructors, HomeBound's
  data/art exclusions, Auctionator's compact checkbox visual hosts and Atlas's
  native label/geometry preservation.

OneForAll exposes `OneForAll.UI` and shared constructors. Its Widgets.lua states
that the earlier selectable themes were removed in 5.7.3; only its gold theme
remains. No EUI registration or native EUI theme exists in the supplied source.
The older `ForeverCompanionAPI` belongs to the separate existing integration.
Keep that integration and its target unchanged; OneForAll has its own loader
entry, definition, setting and all-client TOC registration. No upstream source,
GPL code or artwork is redistributed with this standalone adapter.

## Coverage and visual decisions

| Surface | Treatment |
| --- | --- |
| Main window | Public Shell, native banner/logo preserved, native window opacity respected |
| Armory, Dungeons & Raids, Professions, QoL, Talent Trees, Books, Pets, Settings | Completed lazy factories, shared navigation, cards, controls and fonts |
| Navigation and mode buttons | Public filled Button; native bottom glow reused for selected main tabs, thin accent indicator for mode buttons |
| Cards and custom panels | Reuse native nine-slice regions as flat surfaces/thin edges; suppress redundant pieces, glows and gold window decoration |
| Inputs and scrollbars | Public EditBox and ScrollBar; native text, caret, validation, scrolling and click areas |
| Switches/checkboxes | Existing hit rectangle with a centred compact EUI square; checked, disabled and native callbacks retained |
| Horizontal sliders | Original thumb drag rectangle retained; one small noninteractive grip, neutral track and accent fill |
| Private dropdown | Native full-field opener, selection, delete indicator, owner/position and pooled menu callbacks retained; EUI rows and current-accent check |
| Secondary windows | Crafting list, trainer spells, profiles/import, talent codes, quest chain, weights, confirmations, setup/news, bug/Discord copy dialogs, QoL previews, copy-chat/bags-full dialogs and nearby-book popup |

The public Tab primitive mirrors text into a fixed-size centred label. It would
conflict with OneForAll's composite icon/label positioning and ContentWidth
layout. Use the public Button primitive with the original label and reuse the
native bottom glow as the underline. Dropdown selectors likewise keep their
native GoldButton click handlers rather than acquiring a second menu/opener.
These are OneForAll-specific adaptations, not shared styling changes.

Preserve map/dressing-room/talent illustrations, portraits, section emblems,
status gems, inline colours, item-quality and class colours, talent ranks,
quest completion/in-log fills, cooldowns and all meaningful markers. Only known
decorative assets and colour roles are changed. No model/data canvas is skinned
as a filled panel. Warning/delete markers keep their semantics. Private
GameTooltip/scanner frames, protected action buttons, minimap/world-map tools,
HUD gameplay elements and Blizzard windows modified by QoL stay with their
native/Blizzard skin owners.

## Lifecycle and performance

Wrappers are limited to OneForAll's own UI factories and NewFS, plus its main
window entry points. Native calls run directly and preserve arguments, receiver
and nil-containing multiple returns. ShowNews and ShowWelcome are also handed
to C_Timer by the addon; those functions are deliberately not hooked/replaced.
No global frame factory, AceGUI factory, SkinC, saved preference, data action,
combat attribute, gameplay callback or theme palette is replaced.

Completed panel construction styles synchronously. Construction bursts queue
only owned new subtrees and coalesce children under a pending ancestor. Known
frames observe new texture/font creation; interaction hooks only flush pending
construction, never rediscover an unchanged window. Same-count replacements
are caught at construction rather than through child-count assumptions.
There is no H.Scan, global UI scan, polling, skin OnUpdate or repeating timer.
Manual refresh and combat recovery are explicit discovery points. Theme/accent
refresh repaints retained roles and fonts; native LayoutTabs recalculates text
widths only when the font changes; no new art is created. Disabled and
explicitly protected controls remain gated. Native background-opacity registration remains
in place, with separate tracking for the public shell's new textures; late
banner/logo/preview art survives engine restripping and combat recovery.

`tests/oneforall_spec.lua` runs Retail and Forever client identities with a
source-shaped fixture. It covers eight lazy factories, native returns/actions,
all eight quality colours, status fills, art/model isolation, selection and
clearing, same-count replacement, popup construction, disabled states, theme,
opacity, combat recovery and warm work. An optional local-source run also uses
the supplied actual Widgets.lua, MainFrame.lua and Settings.lua; those files are not stored
in the repository or player ZIP:

```sh
ONEFORALL_WIDGETS=/path/to/OneForAll/UI/Widgets.lua \
ONEFORALL_MAINFRAME=/path/to/OneForAll/UI/MainFrame.lua \
ONEFORALL_SETTINGS=/path/to/OneForAll/UI/Settings.lua \
ONEFORALL_NUMERIC_TEXTURES=1 \
python3 tests/run_lua.py
python3 scripts/package.py
```

For each client identity, 1,000 warm reopen/selection/check cycles add zero UI
objects/hooks, child/region discovery reads or font writes, and zero skin geometry writes.
The actual widget run retains 2,000 native knob anchor writes from its original
switch animation. Another 1,000 closed texture updates queue no skin work.
These are deterministic mock operation counts, not client latency/FPS, memory
retention or rendering measurements. Ownership is checked even when OneForAll calls a helper on an external frame;
its minimap collector and gameplay HUD ancestors are explicitly excluded.
The real panel data providers, server
queries, graphics engine and secure execution are not simulated.

Mutating either the rarity-colour guard or artwork protection fails its focused
assertion. The final package validates 60 installation files in one EUIAddonSkins folder,
43 deferred factories, consistent manifests/version and the exact MIT license.
Development documents, tests, sources and screenshots are excluded.

## Visual refinement: confirmed causes and fixes

- **Unskinned late pages:** ProfessionRecipes constructs RecipeBar's explicit
  SecureActionButtonTemplate Craft action. Its ancestors become implicitly
  protected. The earlier ownership walk rejected that whole ancestry and the
  soft-control proxy rejected implicitly protected controls. The addon-local
  guard now separates ownership from permission, permits implicit containers
  outside combat and excludes explicit secure controls (or an ambiguous older
  protected result). Public Button/Checkbox primitives are called directly.
  No secure attributes, actions or shared-helper defaults change. Cosmetic
  alpha guards also defer during combat and recover on regen.
- **Nested tab selection:** MainFrame.openBottom reanchors the RoundRect centre
  after its constructor returns. Retaining that flattened active fill produced
  an inset selected box. Discard the fill and suppress its native alpha resets;
  reuse the original desaturated additive glow_line texture as a 4px bottom
  strip tinted by the live accent. Native SetActive controls its visibility.
- **Mixed switch layers:** toggleSkin owns its pill slices and knob on the
  CheckButton, while its pill child is only an anchor. Suppress those exact
  owned slices at construction and all native switch regions at completion.
  Keep one compact EUI square, the original 42px click area, checked state,
  callbacks and native disabled dimming. Re-enabling buttons restores readable
  labels without requiring a subsequent selection change.
- **Texture recognition:** GetTexture can expose a numeric FileID. Decorative
  identification now accepts file paths/IDs, resolves the finite known asset
  set once and records names through OneForAll's own SetTex with ID validation.
  New data-icon updates do not queue discovery. This is a compatibility repair,
  not evidence that every screenshot came from numeric texture IDs.
- **Dungeons/raids typography:** SmallCaps assembles separately measured letter
  runs. Changing their face without rebuilding those measurements leaves stale
  positions. Reuse the first native FontString for one normal EUI caption and
  fade its remaining runs. Bound column captions and 8px sort glyphs inside
  existing cells; retain left/centred alignment, native widths, hover tooltips,
  click handlers and ascending/descending/default atlas coordinates. Narrow
  captions may truncate at some font/scale combinations; review in game.
- **Settings/Professions:** Correct late-page discovery applies the existing
  surfaces, inputs, buttons, fonts, private menus and slider treatment. Settings
  reorder arrows use public PageButton. Real Settings factory coverage includes
  12 buttons, 14 switches, one slider, 16 reorder arrows and a native profile
  action. Profile import/export popups remain covered by owned construction.
  Professions detail/reagent panel structure, backgrounds and all data/art
  exclusions are unchanged.

Regressions include implicitly protected roots, explicit secure exclusions,
native switch alpha resurrection, selected-tab fill removal and glow visibility,
bounded captions, sort actions/UVs, enabled-label recovery and numeric textures.
The source-shaped warm workload retains the same zero skin object/hook/read/
font/geometry counts as iteration 1. The actual Settings run uses supplied
upstream code with mocked APIs/providers, not a WoW client. Cold discovery and
look changes remain explicit work; no new polling, H.Scan or warm traversal.
Individually reverting implicit-ancestry handling, selection-fill suppression,
native-knob suppression or caption repair fails its corresponding regression.

## Client limits and in-game review

The supplied TOC declares interface 16001 (Forever). Its Retail-loadable
adaptations do not certify Retail gameplay features: talent planning, dungeon,
item and profession data remain Forever-specific. The skin uses public UI APIs
and guards optional exports/protected objects; it does not port the addon or
change its TOC. Both mocked client identities pass, but separate client testing
is still required.

Review every section and its subpages, first-open/reopen and scrolling, class
and rarity colours, talent availability/ranks/connections, dropdown selection
and deletion, search/caret/focus, disabled controls, banner/logo/preview art,
all secondary dialogs, scaling/height, opacity extremes and live accent/font
changes. In-game visual acceptance, input/taint safety and long-session client
performance remain unverified. Install this pack alongside OneForAll and EUI;
the target addon itself is not included in the test ZIP.
