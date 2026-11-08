# RestedXP performance and stability audit

This pass uses the approved Forever V1 visuals at `9a0e4bb` as the baseline for draft PR #75. It follows the [Atlas](ATLAS_PERFORMANCE.md) and [OneForAll](ONEFORALL_PERFORMANCE.md) audits by separating source review, host measurements and client validation.

## Source review and changes

Reviewed the adapter, shared scan and queue, popup ownership, EUI texture cleanup and the RestedXP v4.11.34 source at `b4a0f99a2ceac856f75a11594bcaa19886236a01`. The local EllesmereUI source reference was `5abb35ba`.

| Path | Finding and disposition |
| --- | --- |
| V1 step progression | `GuideWindow.lua` builds Current Step in `SetStep`. It changes guide-list row alpha and scrollbar position but builds the scroll-row pool in `LoadGuide`. Previously both paths queued a full guide refresh. A warm Forever V1 step now queues only the shown Current Step cards and checks the existing shared surface anchor after native layout. Native target and item callbacks still finish those panels. The check requires the same guide, root and row pool, a previously applied Forever composition and explicit V1 mode. First use, changed ownership, guide loads, theme refreshes, mode transitions and combat recovery still take the full path. |
| Backdrop borders | A scan rebuilt two callbacks per eligible frame, revisited hook registration and rewrote neutral borders even when already at the desired colour and alpha. The adapter now reuses one painter and its existing native hooks per frame and compares current RGBA before writing. Synchronous repair of native white resets, combat deferral, semantic colours and both theme outputs are preserved. |
| Opening, guide changes and scrolling | The normal guide build and reopen paths still discover native controls. Standalone scrolling still uses the existing coalesced scroll-subtree scan. This preserves discovery of changed rows and avoids assuming that all supported clients have identical pool behavior. |
| V2 ownership and EUI cleanup | V2 keeps its guide widget in `state.guideWindow` and acquires/releases active-step widgets through native AceGUI paths. The adapter uses existing owners, hides legacy art when V2 takes over, and retires prior V2 art when the owner changes. Decorative child hosts remain outside EUI's registered-panel texture cleanup. Known owners, hooks and pooled artwork remain resident for reuse. The audit found no accumulating objects in steady-state fixture cycles and cannot establish client-side object reclamation. |
| Inline icons, waypoint and checkboxes | Exact substitutions are scoped to owned labels. Each label caches its last source and rendered text and keeps semantic tags. The waypoint retains its native update path, and objective artwork repairs native texture writes. The adapter has no `OnUpdate` or repeating timer. Newly created Current Step cards and checkboxes still receive the immediate native-post-hook repair. |
| Menus and opacity | Owned menus copy the descriptors needed for padding and settings. Caching mutable descriptors by table identity would risk stale entries or callbacks. Opacity already coalesces into a separate, scan-free background repaint. Neither path changed. |
| Closed, disabled and combat paths | No work is scheduled in the absence of native events. If RestedXP emits updates while the guide is closed, work remains event-driven, and independently visible auxiliary panels can still update. The existing enable gates, protected-frame checks and `PLAYER_REGEN_ENABLED` recovery remain in place. |

References for the relevant native paths are [V1 SetStep](https://github.com/RestedXP/RXPGuides/blob/b4a0f99a2ceac856f75a11594bcaa19886236a01/GuideWindow.lua#L755-L1226), [V1 LoadGuide and row creation](https://github.com/RestedXP/RXPGuides/blob/b4a0f99a2ceac856f75a11594bcaa19886236a01/GuideWindow.lua#L1819-L2130), and [V2 guide ownership](https://github.com/RestedXP/RXPGuides/blob/b4a0f99a2ceac856f75a11594bcaa19886236a01/UI/V2/Core.lua#L1470-L1500).

## Reproducing the host benchmark

Run from the repository root with Python 3 and `liblua5.4.so.0`.

```sh
python3 benchmarks/run_rxp.py --native --output /tmp/rxp-native.json
python3 benchmarks/run_rxp.py --baseline 9a0e4bb --output /tmp/rxp-before.json
python3 benchmarks/run_rxp.py --output /tmp/rxp-after.json
```

Each configuration uses five fresh Lua processes plus a separate fresh process per trial for cold call profiling. The reported run rotated configuration order per trial on an AMD EPYC 7763 host. The border-only isolation loaded the baseline adapter with only its border-painter changes applied through `RXP_ADAPTER`. The workload models two guides with 36 V1 list rows, three active cards with four objectives each, both auxiliary windows and a 36-row V2 window. Each warm workload has 20 warmups and 120 measured iterations except theme switching (30) and mode switching (40). The opacity workload uses eight actual option-setter calls per flush. Each nested-menu iteration prepares root and submenu descriptors.

CPU is process CPU from `os.clock`. The timer excludes the debug call profiler and forced collection. Churn is Lua heap growth with GC paused. Forced GC and the resulting retained delta are measured separately. The un-timed profile counts Lua and C call events, adapter-source call events, selected property writes, child/region reads, queued timer flushes, hook calls and explicit mock UI-object factories. Warm counts describe one post-warmup probe, including the sampled direction for alternating workloads. Cold measurements are one install and one first open per process.

The native control executes the same fixture actions with the adapter uninstalled. It estimates the cost of the modeled operations only. It does not run the real RestedXP parser, native WoW UI API, renderer, secure environment, popup renderer or AceConfig layout/input engine. The opacity control writes a mock preference in the native-only control because native RestedXP has no equivalent slider. Timings include fixture overhead and do not establish WoW FPS, client frame time or live memory. Exact Lua allocation counts and total live C-side allocations are unavailable here. Churn and explicit mock UI creations are the observable substitutes.

## Median results

Entries show native / approved baseline / candidate. CPU and churn are totals for the measured workload. P95 and max are the medians of the per-trial operation P95 and maximum, in milliseconds.

| Workload | CPU ms | P95 ms | Max ms | Churn KiB | Forced GC ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Install | 0.002 / 0.405 / 0.362 | 0.001 / 0.403 / 0.360 | 0.001 / 0.403 / 0.360 | 0.0 / 112.5 / 113.0 | 0.072 / 0.145 / 0.143 |
| First open | 0.868 / 3.666 / 3.244 | 0.866 / 3.654 / 3.242 | 0.866 / 3.654 / 3.242 | 497.5 / 973.8 / 955.1 | 0.207 / 0.547 / 0.536 |
| V1 reopen | 0.076 / 18.165 / 14.464 | 0.001 / 0.262 / 0.219 | 0.002 / 0.470 / 0.397 | 0.0 / 2407.2 / 940.0 | 0.186 / 1.628 / 1.026 |
| V1 guide switch | 3.828 / 86.441 / 86.409 | 0.091 / 1.087 / 1.135 | 0.207 / 2.074 / 1.911 | 1403.6 / 6454.2 / 4102.0 | 0.554 / 2.783 / 3.595 |
| V1 step | 0.538 / 51.907 / 17.148 | 0.005 / 0.622 / 0.246 | 0.084 / 0.949 / 0.585 | 28.6 / 3934.9 / 570.2 | 0.205 / 2.438 / 0.943 |
| V1 scroll + row text | 0.094 / 7.911 / 6.103 | 0.001 / 0.107 / 0.105 | 0.002 / 0.179 / 0.367 | 10.1 / 1537.7 / 427.6 | 0.194 / 0.839 / 0.704 |
| Targets + items | 0.109 / 6.505 / 6.203 | 0.001 / 0.096 / 0.120 | 0.002 / 0.187 / 0.181 | 28.2 / 430.9 / 217.2 | 0.257 / 0.523 / 0.521 |
| Root + nested menu | 0.063 / 0.915 / 0.821 | 0.001 / 0.007 / 0.007 | 0.001 / 0.112 / 0.034 | 0.0 / 114.4 / 114.4 | 0.173 / 0.478 / 0.419 |
| Opacity burst | 0.145 / 7.687 / 7.632 | 0.001 / 0.106 / 0.089 | 0.031 / 0.195 / 0.178 | 0.0 / 354.0 / 354.0 | 0.191 / 0.541 / 0.565 |
| Standard ↔ Forever | 0.028 / 15.738 / 11.989 | 0.001 / 0.768 / 0.544 | 0.001 / 0.826 / 0.604 | 7.0 / 1322.5 / 686.1 | 0.178 / 1.102 / 0.959 |
| V1 ↔ V2 | 0.117 / 13.124 / 12.179 | 0.004 / 0.515 / 0.534 | 0.006 / 0.703 / 0.631 | 9.9 / 1439.1 / 548.3 | 0.235 / 1.452 / 1.056 |
| V2 row refresh | 0.070 / 23.136 / 19.176 | 0.001 / 0.327 / 0.284 | 0.001 / 0.519 / 0.634 | 0.0 / 2034.8 / 499.3 | 0.301 / 1.539 / 1.184 |
| Closed idle flush | 0.054 / 0.055 / 0.054 | 0.001 / 0.001 / 0.001 | 0.001 / 0.001 / 0.001 | 0.0 / 0.0 / 0.0 | 0.269 / 0.594 / 0.684 |
| Closed target/item callbacks | 0.100 / 4.349 / 3.923 | 0.001 / 0.054 / 0.068 | 0.001 / 0.146 / 0.173 | 28.2 / 428.9 / 217.2 | 0.230 / 0.643 / 0.785 |
| Closed step after mode cycling | 0.428 / 41.297 / 36.425 | 0.004 / 0.531 / 0.517 | 0.040 / 0.722 / 0.962 | 28.6 / 4001.3 / 1651.2 | 0.234 / 2.210 / 2.133 |

| Workload | Total calls | Adapter calls | Child/region reads | Selected writes | Queued flushes |
| --- | ---: | ---: | ---: | ---: | ---: |
| Install | 4 / 1253 / 1276 | 0 / 203 / 217 | 0 / 4 / 4 | 0 / 80 / 80 | 0 / 1 / 1 |
| First open | 639 / 14221 / 13736 | 0 / 1464 / 1480 | 0 / 218 / 218 | 99 / 896 / 874 | 0 / 1 / 1 |
| V1 reopen | 7 / 1983 / 1688 | 0 / 127 / 127 | 0 / 57 / 57 | 2 / 55 / 50 | 0 / 1 / 1 |
| V1 guide switch | 206 / 6606 / 6132 | 0 / 1150 / 1153 | 0 / 57 / 57 | 38 / 156 / 135 | 0 / 1 / 1 |
| V1 step | 59 / 5333 / 1718 | 0 / 945 / 444 | 0 / 57 / 0 | 2 / 120 / 7 | 0 / 1 / 1 |
| V1 scroll + row text | 4 / 1059 / 837 | 0 / 43 / 43 | 0 / 37 / 37 | 0 / 0 / 0 | 0 / 1 / 1 |
| Targets + items | 8 / 611 / 567 | 0 / 204 / 204 | 0 / 0 / 0 | 2 / 11 / 7 | 0 / 1 / 1 |
| Root + nested menu | 5 / 89 / 89 | 0 / 18 / 18 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 |
| Opacity burst | 3 / 845 / 845 | 0 / 185 / 185 | 0 / 0 / 0 | 0 / 12 / 12 | 0 / 1 / 1 |
| Standard ↔ Forever | 7 / 5092 / 4611 | 0 / 809 / 827 | 0 / 57 / 57 | 2 / 244 / 225 | 0 / 1 / 1 |
| V1 ↔ V2 | 20 / 2924 / 2616 | 0 / 580 / 582 | 0 / 41 / 41 | 4 / 20 / 12 | 0 / 1 / 1 |
| V2 row refresh | 5 / 2872 / 2564 | 0 / 571 / 573 | 0 / 41 / 41 | 0 / 11 / 3 | 0 / 1 / 1 |
| Closed idle flush | 2 / 2 / 2 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 |
| Closed target/item callbacks | 8 / 440 / 396 | 0 / 110 / 110 | 0 / 0 / 0 | 2 / 11 / 7 | 0 / 1 / 1 |
| Closed step after mode cycling | 59 / 4105 / 3631 | 0 / 616 / 619 | 0 / 57 / 57 | 2 / 132 / 111 | 0 / 1 / 1 |

Cold object counts are frames / textures / masks / FontStrings. All warm probes created zero objects in those categories and installed zero hooks. Across warm workloads, the median post-GC heap deltas ranged from −0.125 to +0.003 KiB in the native fixture, −0.312 to +0.156 KiB before, and −0.250 to +0.159 KiB after. These are short fixture deltas, with UI and hooks intentionally resident after warmup.

| Cold phase | Native objects | Before objects | After objects | Retained Lua heap KiB | Hook calls |
| --- | ---: | ---: | ---: | ---: | ---: |
| Install | 0 / 0 / 0 / 0 | 9 / 12 / 3 / 0 | 9 / 12 / 3 / 0 | 0.000 / 102.504 / 103.637 | 0 / 39 / 39 |
| First open | 57 / 12 / 0 / 102 | 69 / 118 / 2 / 102 | 69 / 118 / 2 / 102 | 483.631 / 880.667 / 883.854 | 0 / 269 / 269 |

The separate adapter definition compile/register measurement was 3.359 / 3.191 / 2.999 ms. The native fixture compiles the same definition for harness setup and leaves it uninstalled, so this measures file preparation rather than native addon startup.

### Isolating the optimizations

| Workload | Approved → border-only → candidate CPU ms | Approved → border-only → candidate churn KiB | Approved → border-only → candidate total calls |
| --- | ---: | ---: | ---: |
| V1 reopen | 18.165 → 15.883 → 14.464 | 2407.2 → 940.0 → 940.0 | 1983 → 1688 → 1688 |
| V1 guide switch | 86.441 → 72.531 → 86.409 | 6454.2 → 4102.0 → 4102.0 | 6606 → 6129 → 6132 |
| V1 step | 51.907 → 45.696 → 17.148 | 3934.9 → 1582.7 → 570.2 | 5333 → 4856 → 1718 |
| V1 scroll + row text | 7.911 → 6.247 → 6.103 | 1537.7 → 427.6 → 427.6 | 1059 → 837 → 837 |
| V2 row refresh | 23.136 → 18.291 → 19.176 | 2034.8 → 499.3 → 499.3 | 2872 → 2562 → 2564 |

Border reuse accounted for most of the churn reduction during full scans. Scoping ordinary V1 steps removed their 57 child/region reads per probe and accounted for most of that workload's CPU reduction. Guide switching still dominates the candidate's warm measurements. Its median total CPU was essentially flat in the rotated comparison despite lower churn. Several short or infrequent paths showed mixed tail times across runs, including first open, mode switching and closed step callbacks. A serial sensitivity run gave first-open medians of 2.866 ms before and 4.209 ms after, compared with 3.666 and 3.244 ms in the rotated run. These measurements do not establish a cold-open speedup or slowdown. The candidate retains roughly 4.3 KiB more fixture Lua heap across installation and first open, with the same UI object counts. Full scans, V2 row refreshes and event-driven closed callbacks still have measurable fixture overhead. Closed idle activity was zero in both adapter versions.

## Stability validation

The local full regression suite and package verification cover warm and cold Current Step, same-batch guide reload, post-layout anchor correction, synchronous white-border repair, semantic colours, settled border write suppression, pooled copper checks, alpha composition, chamfered bounds, auxiliary panels, arrow and inline artwork, native menu and control callbacks, settings, EUI cleanup, Standard restoration, V2 owner replacement and mode transitions, and combat deferral. The added benchmark and profiling code are development-only and excluded from the ZIP.

Live WoW Forever verification remains open. Use the same character, guide, addon set and EUI profile across native-only, approved and candidate runs. Capture at least five matched trials of login or `/reload`, first open, close and reopen, guide/step changes, scrolling, opacity drag, nested menus, and V1/V2 and theme switches. Compare client CPU and frame-time tails with the same profiler configuration and sample addon memory after repeated cycles and stabilization. Include closed idle and closed quest progress, and verify that combat interactions and recovery produce no blocked actions or taint. Check Current Step's border/checkboxes during fast step changes and the shared anchor when a step starts hidden or expands. Confirm V2 movement/recreation and EUI texture cleanup visually. The host suite provides no live frame-time, GC, secure-interaction or appearance certification.
