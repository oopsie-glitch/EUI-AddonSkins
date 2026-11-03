# OneForAll Forever compatibility audit

Audit date: 2 November 2026. PR #68; runtime candidate `282e162` unchanged.
**Source-level checks pass. Actual Forever-client verification remains a release blocker.**
No Forever executable, logged-in session or live Forever trace was available in
this environment. Neither the earlier screenshots/approval nor a mocked client
identity establishes that client verification.

## Source provenance and comparison

- Development input: supplied OneForAll 6.0.1 ZIP, SHA-256
  `7dbde14d2edeffd837285f70c409b05629018ba243096f4354805639efeec48c`.
- Official [6.0.1 source](https://github.com/smoergi/OneForAll_Forever/tree/8fd3fa38168066ed49c726921bab223befbf64b0/OneForAll):
  all **357 tracked files are byte-identical** to the supplied extracted tree,
  including its TOC. No Retail adaptation exists in those supplied files.
  This does not establish how the owner's Retail installation was made loadable.
- Current official [6.0.2 source](https://github.com/smoergi/OneForAll_Forever/tree/5f124be93ba377b3315a9f8bedf1186c62a3cf31/OneForAll),
  fetched at `5f124be`; merged 1 November 2026. Compared every Lua file against
  6.0.1. Relevant changes include multi-select Gear Planner source filtering,
  crafted-recipe navigation, tighter/new QoL rows, dungeon sharing controls,
  quest-sharing and welcome/news changes. Widgets' only change is accepting
  explicit `checked` dropdown options. MainFrame, Armory, Settings, Professions,
  HunterPets and the Gear Planner slot paint/quality-refresh contract are unchanged.
- Official EUI API/source snapshot `fc8d3c8` remains the reviewed dependency.
  Its ClientGate explicitly accepts interfaces 16000–19999 and sets
  `EUI_CLIENT_FOREVER`; the 12.1 Retail minimum does not reject 16001.
  An installed older/incompatible EUI build must still be checked in game.

## Manifest, dependency and activation review

Both OneForAll versions declare interface **16001**; target folder/global remains
`OneForAll`. Baganator is optional, not a skin dependency. OneForAll's namespace
and UI constructors are populated by its own TOC, with Widgets preceding page
factories, GearPlanner preceding Armory, and MainFrame after registered panels.
No skin code or upstream TOC needs modifying.

EUI AddonSkins includes OneForAll in Loader, Python catalog and all three TOCs.
The `_Camelot.toc` declares 16001 and requires EllesmereUI and
EllesmereUIBlizzardSkin. It loads the shared helpers/Loader before the skin
factory. No hard OneForAll dependency or force-loading is necessary: Core waits
for enabled/loaded target, EUI facade and `OneForAll.UI`, then installs once.
ADDON_LOADED/PLAYER_LOGIN and combat recovery retry pending activation.
Modern enable checks use GUID; legacy checks use character name and legacy
argument order. Missing/disabled targets or disabled skin remain inert.

There is no Retail-only project gate or Retail-only namespaced API in the
adapter. Mainline manifest registration is intentional; it does not make
OneForAll's gameplay data Retail-compatible. This audit neither ports the addon
nor restricts the approved adapter to a client guessed from a project constant.

## UI, item lifecycle and safety review

- The official 6.0.2 Gear Planner still owns nineteen slot buttons under its
  character panel. `Refresh` and OnShow call refreshSlots, which may assign nil
  quality; selection calls paintSlots using stored quality. The accepted
  same-item-ID quality cache runs immediately before native paint, preserving
  previously known quality and invalidating on item replacement/removal.
  It uses guarded GetInventoryItemID, not a Retail C_Item requirement.
- No new quality fix: the official source has the same lifecycle that the live
  98f3dc3 trace and accepted 7676fdb fix established. Cold-ever-unknown item data
  is not invented. Real Forever item-cache behavior remains a client check.
- Actual 6.0.2 Widgets, MainFrame, Settings, QoL and GearPlanner run in the source
  harness: 19-slot initial Show/Refresh/delayed-nil sequence, all eight modeled
  qualities, empty slots, item identity changes, selection/reopen, all ten QoL
  categories, settings/profile actions and multi-select dropdown recycling.
  Armory's delayed timer is modeled, not executed by a complete live addon.
  Other sections use source-shaped fixtures plus source comparison, not full
  end-to-end execution of their native data providers/game APIs.
- Native actions, scripts, arguments/returns, empty art and class/status colours
  remain owned by OneForAll. Texture/file-ID paths and inherited protection
  are tested. EUI primitives are API-shaped test doubles, not a renderer.
- Ready defers cosmetics in combat; explicitly secure/forbidden controls are
  excluded. The local inherited-protection exception handles the Craft button's
  ancestry; PLAYER_REGEN_ENABLED recovers deferred work. No global hook,
  secure attribute change or action replacement was introduced. Actual taint,
  secret-value handling and client protection behavior cannot be certified here.
- Constructor-local discovery and setter hooks remain bounded. No H.Scan,
  polling/OnUpdate, periodic timer, forced click or refresh loop. Closed idle
  performs no skin callbacks. No temporary rarity diagnostics are present.

## Regression and performance evidence

New `tests/oneforall_forever_spec.lua` loads the actual Camelot manifest's
Core/Widgets/Loader/OneForAll chain, using minimal modern and legacy API fixtures.
It covers late EUI/target namespace, skin/character disable, combat activation
recovery, one installation, no forced load and 50 empty recovery events without
new frames. Other shared files/skins are covered by the existing all-manifest
and integration suites, rather than misrepresented as part of this minimal test.
`tests/oneforall_spec.lua` adds optional 6.0.2 multi-select checked/unchecked,
click and shrink/reuse assertions against the real Widgets implementation.
The ordinary package runner now executes **44 suites** (43 skin factories).

Reproduce the source-backed run with ONEFORALL_WIDGETS, ONEFORALL_MAINFRAME,
ONEFORALL_SETTINGS, ONEFORALL_QOL and ONEFORALL_GEARPLANNER pointing at the
corresponding official 6.0.2 UI files, plus ONEFORALL_NUMERIC_TEXTURES=1 and
ONEFORALL_MULTISELECT=1, then `python3 tests/run_lua.py`.
Without the source variables, the standard source-shaped suite remains runnable
in CI; upstream GPL source/assets are never copied into this repository/package.

Five fresh-process trials used the existing `benchmarks/run_oneforall.py`
workloads with official 6.0.2 sources; 20 warmup actions, 200 measured iterations,
100 latency samples. [Raw results](performance/oneforall/forever-602-audit.json).
These are host Lua 5.4 CPU/allocation counts under mocked APIs/EUI, not in-game
Forever timing, native memory, frametime, FPS or GC measurements. Mock hook
trampolines themselves allocate return tables. No before/after optimization
claim is made because runtime is unchanged.

| Forever-identity workload | Skin calls/action | New objects/hooks/hierarchy reads/fonts/timers during warm work |
| --- | ---: | --- |
| Reopen pair | 33 | 0 / 0 / 0 / 0 / 0 |
| Gear refresh | 752 | 0 / 0 / 0 / 0 / 0 |
| Forty-row refresh | 1400 | 0 / 0 / 0 / 0 / 0 |
| Closed idle | 0 | 0 / 0 / 0 / 0 / 0 |

These operation counts match the approved 6.0.1 performance candidate. The
ordinary regression/manifest/Lua/license/package validation passes. The rebuilt
60-file ZIP has **identical entry names and bytes** to the previously supplied
`EUIAddonSkins-OneForAll-282e162-test.zip`; tests/docs are excluded. No replacement
test ZIP is needed. Branch CI status is recorded in PR #68.

## Required Forever release gate

Use the existing 282e162 test ZIP with official OneForAll 6.0.2 and compatible
Forever EUI/Blizzard Skins+. Record actual client build/interface and addon
versions, then verify:

1. `/reload`, open Armory > Gear Planner before clicking: all known equipped
   qualities immediately correct, including the later Armory refresh. Check
   empty slots, selection, actual equipment changes and reopening.
2. All navigation/subpages; 6.0.2 multi-source filter and crafted-recipe action;
   professions, Hunter Pets, talents and dynamically created secondary windows.
3. Settings/profile controls and every QoL category: inputs, dropdowns, toggles,
   disabled states, scrolling and native actions.
4. Accent/font/theme/opacity changes, lazy pages after a change, reopen, and
   combat entry/recovery including the secure Craft action. Check for blocked
   actions/errors/taint without treating absence in mocks as proof.

Existing `/euiskins diagnostics` can confirm interface, target enabled/loaded,
EUI callback, skin activation and integration status; no temporary tracer is
needed. **Until these actual Forever checks are recorded, full compatibility
must not be claimed and Forever release verification remains outstanding.**
