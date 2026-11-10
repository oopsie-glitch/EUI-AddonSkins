# Spy Forever — performance and stability audit

Approved visual baseline: `a8c0e848ad001e1eecf1db7d8246bcd0dff73e1b`,
draft PR #77. The window, header geometry/buttons, row materials, inner rails,
outer rim, native textures/colours and 75% opacity design are unchanged.

## Changes justified by the audit

1. **One Spy-local native hover posthook replaces 80 per-row posthooks.** The
   pinned secure-row XML calls `Spy:ShowTooltip(row, true/false)` from native
   OnEnter/OnLeave. Its audited implementation only displays/hides the tooltip.
   A secure posthook on that method dispatches through the current `rowArt[row]`
   ownership map. Native scripts, tooltip body, target macro and return values
   remain untouched. Foreign/statistics/retired row calls do no skin work.
   Forks without this method retain the original two scoped row hooks.
2. **Hover uses the row's applied theme state.** It checks the existing
   `entry.forever` cache and current skin enabled state instead of resolving
   the whole EUI theme on every pointer entry. Refresh/Standard/disable update
   that cache together with the artwork. This follows the currently applied
   appearance while a queued theme refresh is pending.
3. **Omit an unused main-header band.** The old main band was created, painted,
   then hidden unconditionally. It has no visible contribution. Auxiliary
   header bands remain. This removes one texture and its colour/paint setup;
   divider, ledge, surface composition and all visible materials remain.
4. **Unchanged opacity saves no longer queue a cosmetic pass.** Explicit values
   are still saved, including 0 and 100. A changed value queues the existing
   coalesced apply; repeated values skip it. A 0 -> 75 -> 75 burst uses the final
   saved preference. Reset and combat recovery follow the existing paths.

The two material textures per row are retained. They are independently anchored,
two-unit upper/lower strips above the native fill and below its text, with
different gradients/alpha. A single two-stop gradient cannot reproduce both
separated bands. Stretching a shared atlas over the row would change edge
thickness as users change native row height; more slice/mask regions would not
reduce resources. Reusing the native ADD hover texture would alter Spy's native
highlight and blend semantics. No such visual trade-off was made.

The four existing edge textures still make eight colour writes for a full
enter/leave pair. Unchanged states do not repaint. Replacing that palette change
with another highlight layer would increase textures. Shared list rails/corners
are already list-level objects. The pre-existing per-row OnShow/OnHide hooks
remain necessary: their sibling chrome does not inherit row visibility and must
clear on hide/reuse without polling.

## Reproduction

The package workflow downloads official **Spy 1.3.8-forever5**, CF file 9501070,
and checks SHA256
`f0373e3cb8a31864d41532e08fb5748f42f0a76f45b2c4c9b0bbd92efe14fbec`.
Actions records the XML scripts, ShowTooltip, row constructors, paints and
pool/resize functions before testing. Unmodified Colors/Widgets/MainWindow
(including the real tooltip function in source mode) execute against mocked
client APIs and minimal deterministic player/tooltip data.

`SPY_SOURCE=/tmp/spy-upstream python3 benchmarks/run_spy.py --baseline a8c0e848ad001e1eecf1db7d8246bcd0dff73e1b --trials 5 --iterations 1000 --rows 40`

Native-only, approved baseline and candidate use the same fixture with five
fresh VMs each, plus independent cold call-profile VMs. Reported timings are
five-trial medians. Warm jobs get 100 warm-up callbacks. Player/sync/hover/pool/
slot-transfer/unchanged-opacity/closed jobs use 1,000 callbacks; reopen/theme
pairs/four-value opacity cycles use 100. Cold is one adapter acquisition over
40 already constructed rows. The list dispatcher is shaped, not full detection.

Slot transfer alternates two pre-created native rows at index 2, warming both
identities before measuring; this tests bounded artwork reuse separately from
ordinary same-frame hide/show. It does not repeatedly allocate native frames
and misattribute their cost to the adapter. Closed idle is a no-event loop,
supported by source review showing no added OnUpdate/polling; it is not a WoW
idle profiler.

Total/direct-adapter/native/shared-helper/C calls are captured separately with
debug hooks (10 callbacks per warm job, one independent cold acquisition).
Timing runs never enable those hooks. The fixture chunk is named explicitly,
so source matching cannot accidentally classify its embedded code text as the
adapter or upstream. Total includes fixture dispatch and one hook-removal call;
direct adapter means Spy.lua only, shared helper means EUI Widgets.lua.
The raw JSON retains all trials, counters and call profiles.

## Comparable measurements

Runtime snapshot: `1fdc03aecc10be2b3dea1912612f36aa54219f7a`.
[Full cloud run and raw five-trial JSON](https://github.com/oopsie-glitch/EUI-AddonSkins/actions/runs/42852436288).
The previous material-pass comparison against pre-Concept-A code remains in
[its original report](https://github.com/oopsie-glitch/EUI-AddonSkins/blob/a8c0e848ad001e1eecf1db7d8246bcd0dff73e1b/docs/SPY_FOREVER_PERFORMANCE.md).
Historical timings from another host/run are not used as this audit's baseline.

| Workload | Iterations | Native ms | Approved baseline ms | Candidate ms |
| --- | ---: | ---: | ---: | ---: |
| Cold acquisition | 1 | 0.001 | 3.491 | 3.485 |
| Player updates | 1000 | 5.421 | 5.599 | 5.600 |
| Whole-pool sync | 1000 | 0.046 | 29.807 | 28.321 |
| Hover pairs | 1000 | 0.788 | 2.708 | 3.090 |
| Same-row hide/show | 1000 | 0.098 | 0.957 | 1.035 |
| Slot transfer (two reused native identities) | 1000 | 0.205 | 41.161 | 40.337 |
| Reopen | 100 | 0.017 | 14.328 | 14.415 |
| Standard/Forever pairs | 100 | 0.003 | 49.419 | 49.514 |
| 0/75/100/75 opacity cycles | 100 | 0.003 | 6.223 | 6.181 |
| Unchanged opacity | 1000 | 0.018 | 14.510 | 0.439 |
| Closed player updates | 1000 | 5.450 | 5.585 | 5.860 |
| Closed no-event idle | 1000 | 0.011 | 0.011 | 0.011 |

**Hover did not become faster in this host benchmark:** 2.708 -> 3.090 ms
(+14.1%, +0.382 ms per 1,000 pairs). Direct adapter calls decrease, but the mock
secure-hook return wrapper adds six calls per pair while the cached theme path
removes one; total rises by five. The fixed eight colour writes remain. The
justification for the shared hook is the verified 79-hook/closure reduction,
not an invented CPU/FPS gain. Actual native-hook timing requires WoW.

Unchanged opacity falls from 14.510 to 0.439 ms (about 97% here), because the
callback no longer runs SyncWindow, controls and header layout. It still saves
the explicit preference. Changed opacity cycles remain comparable. Whole-pool
sync/player code has unchanged operation counts; their small timing changes
are not attributed to an optimization. Closed native updates likewise have
identical call/operation counts despite host timing variation.

### Fixed resources and heap

| Cold adapter acquisition, 40 rows | Baseline | Candidate | Delta |
| --- | ---: | ---: | ---: |
| Frames | 65 | 65 | 0 |
| Textures | 308 | 307 | -1 |
| Hooks | 274 | 195 | -79 |
| Mock Lua retained KiB | 2978.921 | 2955.062 | -23.859 |
| Mock Lua churn KiB | 3186.244 | 3161.518 | -24.727 |

These are full adapter acquisition totals, not the Concept A incremental count.
Relative to the preceding pre-material skin, that incremental cost is now
**84 textures, one shared hover hook, zero frames** (previously 85/80/0).
Existing OnShow/OnHide and other adapter hooks are included in the totals.
Fallback builds without ShowTooltip retain the original per-row hover hooks.
All warmed lifecycle workloads create **zero new frames/textures/hooks**.

| Workload | Baseline churn KiB | Candidate churn KiB | Baseline retained KiB | Candidate retained KiB |
| --- | ---: | ---: | ---: | ---: |
| Player updates | 500.188 | 500.188 | 0.000 | 0.000 |
| Whole-pool sync | 125.500 | 125.500 | 0.000 | 0.000 |
| Hover pairs | 1875.352 | 2031.664 | 0.000 | 0.000 |
| Same-row hide/show | 0.344 | 0.344 | 0.000 | 0.000 |
| Slot transfer (two reused native identities) | 4024.031 | 4024.031 | 0.000 | 0.000 |
| Reopen | 4161.590 | 4161.590 | 0.156 | 0.156 |
| Standard/Forever pairs | 15421.777 | 15421.840 | 0.000 | 0.063 |
| 0/75/100/75 opacity cycles | 352.871 | 352.871 | 0.000 | 0.000 |
| Unchanged opacity | 234.902 | 0.250 | 0.000 | 0.063 |
| Closed player updates | 500.188 | 500.188 | 0.000 | 0.000 |
| Closed no-event idle | 0.000 | 0.000 | 0.000 | 0.000 |

Retained changes no larger than 0.156 KiB in these warmed jobs are small VM/
measurement residuals, not growing row artwork. Slot reuse makes 28,000 geometry
writes and 6,000 visibility writes per 1,000 transfers in both versions: native
child restoration/reacquisition and band reparenting are explicit lifecycle work.
Ordinary hide/show does not reanchor geometry. Hover churn increases 156.313 KiB
in the return-preserving Lua hook fixture; it retains zero after collection.
Unchanged opacity churn falls 234.902 -> 0.250 KiB. These are mock-host values,
not real native UI/GPU memory estimates.

### Separate call profiles

Warm profile rows below use **10 callbacks** each; cold uses one fresh acquisition.
Timing and heap measurements above never enable profiling hooks.

| Workload | Baseline total | Candidate total | Baseline Spy.lua | Candidate Spy.lua | Baseline helpers | Candidate helpers |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Cold acquisition | 14041 | 13946 | 1197 | 1197 | 593 | 593 |
| Player updates | 1601 | 1601 | 0 | 0 | 0 | 0 |
| Whole-pool sync | 7791 | 7791 | 3240 | 3240 | 20 | 20 |
| Hover pairs | 391 | 441 | 90 | 80 | 0 | 0 |
| Same-row hide/show | 351 | 351 | 120 | 120 | 0 | 0 |
| Slot transfer (two reused native identities) | 9611 | 9611 | 3540 | 3540 | 20 | 20 |
| Reopen | 29071 | 29061 | 4810 | 4810 | 3490 | 3490 |
| Standard/Forever pairs | 100611 | 100601 | 14560 | 14560 | 7300 | 7300 |
| 0/75/100/75 opacity cycles | 14911 | 15151 | 3640 | 3720 | 120 | 120 |
| Unchanged opacity | 3661 | 171 | 910 | 50 | 30 | 0 |
| Closed player updates | 1601 | 1601 | 0 | 0 | 0 | 0 |
| Closed no-event idle | 11 | 11 | 0 | 0 | 0 | 0 |

Player updates profile 40 actual-source function calls per 10 callbacks in both
versions, zero direct adapter/helper calls. Hover profiles 20 actual-source
ShowTooltip calls in both. Remaining native-source and C counts, native-only
controls and every raw trial are in the linked JSON logs. The total includes
fixture calls, secure-hook emulation, C calls and shared helpers; it is not the
number of WoW API calls.


## Interpretation and stability findings

- Warm native SetBar is not hooked. Its 1,000 geometry writes are native text
  truncation; the native-only control makes those same writes. Skin scans,
  cosmetics and UI-object creation stay zero even when the window is closed.
- The native secure hook is modeled by a Lua wrapper preserving arbitrary,
  nil-containing returns. That mock wrapper packs returns into a Lua table;
  WoW's secure hook implementation does not run this fixture. Its temporary
  churn and call overhead must not be described as a game allocation regression
  or speedup. Existing edge colour setter tables likewise dominate mock hover
  churn. All retained/churn measurements below are Lua-host fixture values.
- Cold heap includes fake UI objects with per-object Lua method tables. It does
  not estimate WoW C-side textures/frames or GPU storage. No actual CPU/FPS,
  real retained addon memory or native taint/crash guarantee is established.
  Changes within host timing variability are not evidence of a game improvement.
- Secure row positions, sizes, macro attributes, click scripts and native data
  remain unchanged. Only already-approved child cosmetics change, outside
  combat. Posthooks do not replace secure/native scripts or protected actions.
  The combat path records desired state and existing PLAYER_REGEN_ENABLED
  recovery applies it; no extra event registration or polling was added.
- Per-slot textures and edge host are reused. Retirement restores native child
  anchors, detaches material bands, removes the old ownership mapping and hides
  chrome. Native rows may remain resident in WoW; weak tables do not destroy
  frames. Row-slot storage follows the high-water native pool, not number of
  player updates. Growing the native pool legitimately adds fixed slot art.
- Reopening/theme changes still invoke the existing owned-window refresh and
  scan boundaries. Their costs are measured, not represented as zero. This
  audit does not add global discovery or scans to frequent player/hover events.
- EUI cleanup touches registered shell surfaces; Forever custom hosts stay
  outside that registry. Native StatusBar bands are retained, not repainted on
  every cleanup or SetBar. Standard/disable hide them and restore captured native
  anchors. Native texture, alpha, class/status RGB, sorting/detection, warning
  logic and targeting remain under Spy's control.
- No new fill, gradient, font, geometry, asset, user setting or native preference
  was introduced. Opacity remains confined to decorative background surfaces.
  Saved 0/75/100 boots, explicit values, queued reversions and Reset are covered.

## Regression and remaining live checks

Full package/regression validation plus actual-source mode and fallback boots
cover normal/fallback hover routing, original scripts and return preservation,
foreign/retired ownership, duplicate enters, hide/reuse, texture/class colours,
pool replacement, header geometry, inner frame and layer ordering, resize/list
changes, Standard/disable, opacity/reset, combat deferral and EUI cleanup.
Mutation checks must catch reintroduced per-row hooks, the unused main-header
fill, changed hover/bevel appearance and existing geometry/opacity failures.
The player ZIP contains only 66 runtime files in one addon folder.

Live checks remain: identical approved materials in Nearby/Last Hour/Ignore/KOS,
native hover/tooltip/target/modifier actions after hide/reopen and recycling,
resize and theme switching, saved opacity after reload/Reset, combat recovery
without taint, EUI cleanup and a long session with pool growth. Client rendering,
implicit parent show/hide propagation, secure hit-testing and third-party forks
cannot be certified by this host fixture. The fallback is checked when the
shared method is absent; a fork that defines it but bypasses it in custom row
scripts needs separate native-source review. No runtime script inspection or
polling was added to guess such behavior.

This is an untagged draft-review build. Main, version 1.6.5, release tags and
publication remain unchanged.
