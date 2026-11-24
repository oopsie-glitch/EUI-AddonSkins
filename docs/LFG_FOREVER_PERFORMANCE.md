# LFG Forever performance and stability audit

Approved visual baseline: `ec84dc8c75bd9fa7a794557d9d51241a079c8fbd`, draft PR #96. Audit runtime reference: `c779bc7b52c96b29bb1b241b825e127d35825855`.

The approved EUI surfaces, artwork, colors, geometry, input ownership and native addon settings are preserved. This is an isolated development candidate, not a release or an authorization to include it in v1.6.8.

## Findings

No Critical security issue was identified in the adapter. No native data/communication/profile hooks or SavedVariables writes were introduced.

| Severity | Finding | Evidence / correction |
| --- | --- | --- |
| Medium, performance | Page OnShow walked initialized row pools; the SetTab post-hook walked pages again. IsShown does not establish visibility through a hidden ancestor. | Model baseline: 125,000 getter traversal reads for 1,000 Whispers reopens; 335,916 for 1,000 rotating tab selections. Remove the redundant SetTab hook. Page show still discovers late static controls, but existing virtual rows are owned by completed view callbacks. |
| Medium, stability | The manually added side indicator was absent from the public Button keep list. | The actual pinned EUI Restrip function removes it in the starting runtime. Create the same indicator before Button registration and include its field in the supported keep list. The regression fails on the approved starting runtime and passes after correction. This demonstrates the operation, not a claim that the user observed this defect. |
| Low, performance | Every descendant repeated full root ancestry checks. | Check ancestry at entry, then validate each direct child-parent edge. Retain per-frame protected/forbidden guards and reject stale reparented snapshots/foreign row callbacks. No cached ownership assumption is introduced. |
| Low, performance | Hidden refreshes and hidden view callbacks could perform cosmetic traversal. | Reuse the existing generation and pending-refresh state. Hidden work is applied synchronously on the next safe root show; no hidden row references, extra queue, timer or polling is added. |
| Low, redundant writes | Theme updates reanchored unchanged checkbox art; side selection rewrote unchanged RGB/visibility. | Cache cosmetic size and marker identity in the existing checkbox entry; cache indicator RGB/visibility in its existing entry. Replaced mark textures are still positioned correctly. |

The source still has no OnUpdate handler, recurring timer, chat listener or player-rating/search-data hook. The two pre-existing public menu-manager instance post-hooks remain ownership/visibility gated; no global hook is added. The listing listener unregisters once the root is bound. Skin disable retains the established reload semantics.

## Measurement environment and scope

Reference data: [GitHub Actions run 45422857792](https://github.com/oopsie-glitch/EUI-AddonSkins/actions/runs/45422857792).

Ubuntu 24.04 hosted runner, system Lua 5.4 library; five fresh Lua states per treatment, medians. The same source-shaped UI has 20 populated rows per view, three views, ancestor show/hide propagation and native-style tab selection. Read/write/object counters instrument the same fixture in all treatments.

Treatments:
- **Unskinned control:** the fixture's native UI with no adapter installation.
- **Before:** exact approved PR runtime from immutable commit ec84dc8.
- **After:** the audit runtime above.

These are **not measurements of LFG Forever's real WoW execution**. The fixture models its inspected UI ownership/lifecycle, uses minimal public-EUI primitive stubs, and does not execute server queries, native chat parsing, persistent ratings storage, C rendering or native GPU work. Native whisper processing is unchanged; only its completed display-row path and a forced hidden-notification boundary are measured. Actual /reload duration is unavailable: fresh-state initialization models its skin lifecycle.

The source archive remains pinned to LFG Forever 2.6.0, interface 16001, SHA256 `68529acce2de99476226522242daacd9d277ffecd5b1a8b2d9c12c99febe6a6e`. Actual source contracts are checked without printing or redistributing original source. EUI engine reference: EllesmereGaming/EllesmereUI `d84a1e19d0b63a9a944dd8023e436290a1b7a173`; its Restrip is executed separately in the stability test, not used as a runtime internal API.

## CPU: median milliseconds for each complete workload

| Workload | Iterations | Unskinned control | Before | After |
| --- | ---: | ---: | ---: | ---: |
| Adapter definition / factory load | 1 | 0.000 | 0.264 | 0.274 |
| Skin activation | 1 | 0.001 | 0.029 | 0.029 |
| First populated window open | 1 | 0.667 | 1.384 | 1.301 |
| Warm reopen: Filters | 1000 | 15.388 | 19.164 | 18.258 |
| Warm reopen: Whispers | 1000 | 28.202 | 133.599 | 32.473 |
| Rotate Filters / Whispers / Ratings | 1000 | 8.539 | 287.768 | 10.190 |
| Search-result row initialization | 1000 | 0.082 | 4.627 | 3.778 |
| Player-list row initialization | 1000 | 0.080 | 4.606 | 3.798 |
| Whisper row display | 1000 | 0.080 | 5.002 | 3.859 |
| Rating row display | 1000 | 0.080 | 4.953 | 3.871 |
| Theme/accent: window open | 100 | 0.012 | 38.608 | 32.369 |
| Theme/accent: window closed | 100 | 0.011 | 39.352 | 0.210 |
| Idle control ticks (no callbacks scheduled) | 10000 | 0.132 | 0.133 | 0.142 |
| Foreign menu opens: window closed | 1000 | 0.084 | 1.552 | 1.564 |
| Addon-load notifications: window closed | 1000 | 0.059 | 3.022 | 1.833 |
| Forced hidden-view notifications (stress) | 1000 | 0.081 | 4.926 | 0.210 |
| Side-tab checked state | 1000 | 0.069 | 0.935 | 0.878 |
| Theme request in combat + recovery | 100 | 0.011 | 38.581 | 32.528 |
| Disabled-skin native row updates | 1000 | 0.082 | 0.145 | 0.143 |

Subtract the control only to assess incremental cost inside this model. Tiny timing differences are host noise, not a demonstrated gameplay change. The idle tick workload has no scheduled skin callback; its loop timing is a control measurement, not proof of zero real-world cost. Menu opens and addon-load notifications still execute inexpensive guards while closed.

The most dependable evidence is the operation-count reduction:
- Whispers reopen traversal reads: **125,000 → 5,000**; remaining reads discover only the small static page.
- Rotating tab traversal reads: **335,916 → 3,996**.
- Search/player row ancestry reads per 1,000: **19,000 → 6,000**; whisper/rating rows: **27,000 → 8,000**.
- Closed-theme and forced hidden-view notification workloads: **zero candidate traversal/font/geometry writes**.
- 100 open theme changes: checkbox geometry writes **900 → 0**.
- 1,000 side selections: indicator RGB writes **1,000 → 0** when RGB is unchanged.
- Warm row updates retain **zero additional SetFont calls**, while still detecting native font resets and new children.

## Allocation and retention

GC is stopped to measure temporary allocation churn, restarted, then collected for retained-heap deltas. These are distinct measurements.

| Workload | Before allocated KiB | After allocated KiB |
| --- | ---: | ---: |
| Warm reopen: Whispers | 9253.188 | 503.188 |
| Rotate Filters / Whispers / Ratings | 24783.703 | 398.703 |
| Theme/accent: window closed | 4052.719 | 18.750 |
| Forced hidden-view notifications (stress) | 437.938 | 0.250 |
| Side-tab checked state | 195.313 | 78.125 |

Open-theme allocation is slightly higher in this instrumented fixture (4052.781 → 4119.313 KiB / 100 changes); actual color synchronization remains intentional. This is not presented as a universal allocation reduction.

The fixture's hooksecurefunc shim uses table.pack to preserve native return tuples. This accounts for approximately 128 bytes per hooked call in the model; real WoW's C post-hook implementation is not measured by that Lua shim. Mock native Frames also contain Lua method closures, so their cold memory sizes are not native WoW frame memory estimates.

Repeated warm updates/open/close/tab/theme/recovery workloads add no Frames, Textures, FontStrings, hooks or event listeners. Retained-heap medians are bounded around the measurement floor (typically within 1 KiB). The foreign-menu workload's approximately 3 KiB retained model allocation is its first native pooled popup, not accumulating skin state.

| Final mixed fixture inventory | Unskinned | Before | After |
| --- | ---: | ---: | ---: |
| Frames | 214 | 215 | 215 |
| Textures | 68 | 144 | 144 |
| FontStrings | 252 | 252 | 252 |
| Adapter hooks | 0 | 13 | 12 |
| Active adapter event listeners | 0 | 2 | 2 |
| Completed-view callbacks | 0 | 3 | 3 |

The adapter directly creates one event frame and the existing cached side indicator; public EUI primitives create their own cached art. The table uses minimal primitive stubs and **does not enumerate all real EUI backend Frames/FontStrings/hooks**.

State is bounded by the singleton window and physical native widget pools, not player names, whisper history or rating records. Known frames/check art/view callbacks are retained for their native UI lifetime; weak tables alone would not destroy WoW frames. Existing generation invalidation, actual native font checks and late/static/same-count child discovery remain in place.

## Regression and stability coverage

- Complete package suite plus pinned native source contracts.
- All three pages, native input/click/return behavior, class/role/rating semantics.
- Completed rows, same-count replacements, foreign callbacks and stale reparented child snapshots.
- Warm page shows without revisiting row pools; late static controls are still discovered.
- Hidden theme changes and new hidden rows: no styling until first safe visibility, then correct appearance before any hover.
- Unchanged checkbox geometry and replacement checkmark identity.
- Actual EUI restrip preserves the existing side indicator; the original runtime fails this assertion.
- Theme/accent properties, native geometry and approved visual-property snapshots match before/after.
- Combat deferral/recovery, disabled skins, absent/late targets and generic/Mainline/Camelot loader/package gates.
- Exact install ZIP filenames, CRC and every runtime byte verified against the tested checkout.

Profiling code and reports are development-only and excluded from the install ZIP. No permanent diagnostics are added to gameplay.

## Remaining client verification

The audit supports testing the candidate; it cannot certify actual FPS, native RAM/VRAM, secret-value taint safety or pixel-perfect rendering. The real target is WoW Forever; Mainline fixture success is not a Retail support claim.

In the live client, verify first/repeated opening through all launchers, all three populated tabs, a new whisper/rating/result after closing, theme/accent changes while closed then reopen, combat recovery, resizing/scales, /reload and native menus/tooltips. The approved visual design is unchanged; smoke-test the optimized first-show paths and check Lua/taint logs. Existing deliberately native shared dialogs and unowned submenus remain unchanged.
