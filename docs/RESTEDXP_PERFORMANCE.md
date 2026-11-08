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

## Final combined V1/V2 audit

The comparison baseline is `91ccb72` from draft PR #75. The source review uses RestedXP v4.11.34 at `b4a0f99a2ceac856f75a11594bcaa19886236a01`. [V2 implementation and visual validation history](RESTEDXP_V2_FOREVER.md)

Forever now defaults to 75% using the same composition as an explicit 75% slider choice. With no custom preference, the resolver supplies 75% without populating saved variables. Explicit values including 0% and 100% remain valid in either look. Reset removes the custom settings and restores the selected look's default. Standard still uses the existing EUI panel alpha or saved override. The obsolete V1 automatic step-fill texture is removed because the shared surface now supplies the complete opacity budget. Existing colours, textures, mask material and header treatments are preserved.

### Workloads and measured changes

Run the existing host-Lua runner from the repository root with a checkout containing the baseline.

```sh
python3 benchmarks/run_rxp.py --native --output /tmp/rxp-native.json
python3 benchmarks/run_rxp.py --baseline 91ccb72 --output /tmp/rxp-before.json
python3 benchmarks/run_rxp.py --output /tmp/rxp-after.json
```

Each configuration used five fresh Lua processes and separate cold call probes. The audit rotated configuration order. The fixture adds a V2 slider and wheel/drag offset model, V2 reopen, guide changes, native-shaped theme dispatch and combat recovery. It models 36 guide rows, three Current Step cards and native asset groups. V2 resize alternates 242 and 342 units. Warm paths have 20 warmups and 120 operations, except theme and combat recovery (30) and mode transitions (40). The opacity workload changes the slider eight times before draining one queue. The native control executes the same modeled operations without installing the skin. Some native controls are simple stand-ins, notably menu display, options layout, native row/font rendering and combat. Persistence is a functional test using a reconstructed saved-variable table. It is separate from the timing suite and actual game disk persistence remains a live check.

Confirmed redundant work occurs on V2 theme application. Native legacy `UpdateVisuals` returns after dispatching the V2 theme refresh, which the adapter was invoking again directly. For that known native V2 path the adapter now makes one explicit theme call with its existing child-refresh payload. The opacity-only trial still recorded 14,975 calls for a V2 theme change. The final candidate recorded 9,925. The fallback and V1 continue to use their native redraw path. Guide changes and reopen still have measurable discovery costs. This pass keeps those ownership checks and leaves row measurement, scroll geometry and inline-icon invalidation intact.

All table cells show native / baseline / candidate. Timings are median host CPU totals and per-operation P95, in milliseconds. Calls, scans and queued flushes are one sampled operation. Heap churn is the GC-stopped batch delta in KiB.

### CPU and heap

| Workload | CPU ms | P95 ms | Max ms | Churn KiB | Forced GC ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Adapter installation | 0.004 / 0.383 / 0.411 | 0.001 / 0.382 / 0.411 | 0.001 / 0.382 / 0.411 | 0.0 / 121.6 / 125.2 | 0.071 / 0.138 / 0.139 |
| First V1 open | 0.779 / 3.372 / 2.740 | 0.778 / 3.371 / 2.738 | 0.778 / 3.371 / 2.738 | 497.5 / 955.1 / 959.2 | 0.174 / 0.496 / 0.407 |
| First V2 open after V1 | 2.159 / 4.775 / 4.253 | 2.158 / 4.773 / 4.250 | 2.158 / 4.773 / 4.250 | 1426.5 / 1805.2 / 1814.9 | 0.703 / 1.363 / 1.388 |
| V1 reopen | 0.084 / 10.737 / 10.458 | 0.001 / 0.146 / 0.147 | 0.001 / 0.398 / 0.431 | 0.0 / 940.0 / 940.0 | 0.570 / 1.590 / 1.317 |
| V1 guide switch | 2.875 / 57.628 / 58.037 | 0.027 / 0.681 / 0.658 | 0.108 / 1.116 / 1.369 | 1403.6 / 4116.1 / 4116.1 | 1.062 / 2.413 / 2.163 |
| V1 step | 0.418 / 13.262 / 12.654 | 0.004 / 0.173 / 0.169 | 0.050 / 0.273 / 0.311 | 28.6 / 570.1 / 570.1 | 0.508 / 1.251 / 1.066 |
| V1 scroll and row update | 0.102 / 4.957 / 5.264 | 0.001 / 0.071 / 0.065 | 0.004 / 0.116 / 0.155 | 10.1 / 425.5 / 425.5 | 0.533 / 1.110 / 1.112 |
| Auxiliary updates | 0.107 / 4.345 / 3.775 | 0.001 / 0.070 / 0.047 | 0.002 / 0.144 / 0.203 | 28.2 / 217.2 / 217.2 | 0.555 / 1.089 / 1.091 |
| Context and nested menu | 0.069 / 0.813 / 0.838 | 0.001 / 0.007 / 0.006 | 0.001 / 0.064 / 0.046 | 0.0 / 114.4 / 114.4 | 0.501 / 0.924 / 0.909 |
| Opacity burst | 0.107 / 6.688 / 5.656 | 0.001 / 0.103 / 0.071 | 0.001 / 0.216 / 0.178 | 0.0 / 354.1 / 354.1 | 0.615 / 1.036 / 1.151 |
| Theme switch with V1 active | 0.031 / 22.651 / 21.578 | 0.001 / 1.050 / 0.908 | 0.002 / 1.393 / 0.977 | 7.0 / 2264.7 / 2264.7 | 0.541 / 1.783 / 1.574 |
| V1 ↔ V2 | 0.227 / 15.193 / 13.464 | 0.007 / 0.546 / 0.459 | 0.014 / 0.787 / 0.623 | 12.4 / 589.4 / 589.4 | 0.587 / 1.278 / 1.174 |
| V2 row and wrapping update | 0.654 / 1.085 / 1.070 | 0.005 / 0.009 / 0.011 | 0.037 / 0.073 / 0.073 | 14.9 / 33.5 / 33.5 | 0.528 / 1.008 / 1.058 |
| V2 width change | 13.820 / 42.423 / 41.621 | 0.190 / 0.517 / 0.458 | 0.319 / 0.893 / 0.699 | 5062.6 / 6424.4 / 6424.4 | 1.856 / 2.826 / 2.739 |
| V2 reopen | 0.627 / 11.517 / 11.394 | 0.005 / 0.156 / 0.164 | 0.042 / 0.259 / 0.227 | 0.0 / 749.8 / 749.8 | 0.534 / 1.357 / 1.205 |
| V2 guide switch | 4.864 / 73.196 / 70.552 | 0.083 / 0.843 / 0.759 | 0.183 / 1.099 / 1.181 | 1798.5 / 5461.2 / 5461.2 | 0.906 / 2.731 / 2.445 |
| V2 scrollbar movement | 0.162 / 0.204 / 0.202 | 0.001 / 0.002 / 0.003 | 0.018 / 0.042 / 0.033 | 42.2 / 42.2 / 42.2 | 0.559 / 1.002 / 1.007 |
| V2 combat deferral and recovery | 2.858 / 48.394 / 34.636 | 0.157 / 2.226 / 1.427 | 0.181 / 2.540 / 1.558 | 1265.8 / 6736.7 / 5114.3 | 0.857 / 2.997 / 2.552 |
| V2 theme switch | 2.929 / 28.739 / 18.426 | 0.151 / 1.318 / 0.869 | 0.182 / 1.364 / 0.947 | 1274.5 / 3503.3 / 1923.2 | 0.917 / 2.863 / 2.037 |
| Three V2 Current Step cards | 0.282 / 2.081 / 1.722 | 0.002 / 0.023 / 0.014 | 0.036 / 0.169 / 0.054 | 36.2 / 162.9 / 162.8 | 0.557 / 1.075 / 1.156 |
| Closed idle | 0.059 / 0.060 / 0.061 | 0.001 / 0.001 / 0.001 | 0.001 / 0.001 / 0.001 | 0.0 / 0.0 / 0.0 | 0.679 / 1.088 / 0.998 |
| Closed auxiliary callback | 0.112 / 4.518 / 4.468 | 0.001 / 0.064 / 0.067 | 0.003 / 0.120 / 0.154 | 28.2 / 217.3 / 217.3 | 0.712 / 1.095 / 1.036 |
| Closed step callback | 0.388 / 13.139 / 13.429 | 0.003 / 0.166 / 0.181 | 0.009 / 0.442 / 0.229 | 28.6 / 570.3 / 570.3 | 0.651 / 1.482 / 1.211 |

### Call profile

| Workload | Total calls | Adapter calls | Scans | Queues | Selected writes |
| --- | ---: | ---: | ---: | ---: | ---: |
| Adapter installation | 4 / 1294 / 1266 | 0 / 217 / 189 | 0 / 4 / 4 | 0 / 1 / 1 | 0 / 80 / 93 |
| First V1 open | 639 / 13737 / 13652 | 0 / 1481 / 1442 | 0 / 218 / 218 | 0 / 1 / 1 | 99 / 874 / 886 |
| First V2 open after V1 | 2276 / 15338 / 15261 | 0 / 2343 / 2286 | 0 / 160 / 160 | 0 / 1 / 1 | 368 / 839 / 856 |
| V1 reopen | 7 / 1689 / 1689 | 0 / 127 / 127 | 0 / 57 / 57 | 0 / 1 / 1 | 2 / 50 / 50 |
| V1 guide switch | 206 / 6189 / 5998 | 0 / 1166 / 1079 | 0 / 57 / 57 | 0 / 1 / 1 | 38 / 136 / 136 |
| V1 step | 59 / 1718 / 1646 | 0 / 444 / 414 | 0 / 0 / 0 | 0 / 1 / 1 | 2 / 7 / 7 |
| V1 scroll and row update | 4 / 838 / 838 | 0 / 43 / 43 | 0 / 37 / 37 | 0 / 1 / 1 | 0 / 0 / 0 |
| Auxiliary updates | 8 / 567 / 471 | 0 / 204 / 156 | 0 / 0 / 0 | 0 / 1 / 1 | 2 / 7 / 7 |
| Context and nested menu | 5 / 89 / 89 | 0 / 18 / 18 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 |
| Opacity burst | 3 / 866 / 751 | 0 / 194 / 143 | 0 / 0 / 0 | 0 / 1 / 1 | 0 / 12 / 12 |
| Theme switch with V1 active | 7 / 10379 / 10292 | 0 / 2143 / 2103 | 0 / 57 / 57 | 0 / 1 / 1 | 2 / 804 / 804 |
| V1 ↔ V2 | 96 / 4567 / 4433 | 0 / 965 / 905 | 0 / 80 / 80 | 0 / 1 / 1 | 4 / 58 / 58 |
| V2 row and wrapping update | 81 / 125 / 125 | 0 / 15 / 15 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 |
| V2 width change | 1520 / 5785 / 5785 | 0 / 1229 / 1229 | 0 / 0 / 0 | 0 / 0 / 0 | 360 / 396 / 396 |
| V2 reopen | 84 / 1866 / 1866 | 0 / 103 / 103 | 0 / 80 / 80 | 0 / 1 / 1 | 2 / 2 / 2 |
| V2 guide switch | 444 / 7672 / 7539 | 0 / 1531 / 1472 | 0 / 80 / 80 | 0 / 1 / 1 | 36 / 76 / 76 |
| V2 scrollbar movement | 8 / 8 / 8 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 3 / 3 / 3 |
| V2 combat deferral and recovery | 1522 / 26013 / 19879 | 0 / 5484 / 4130 | 0 / 80 / 80 | 0 / 1 / 1 | 360 / 1603 / 1201 |
| V2 theme switch | 1525 / 15025 / 9925 | 0 / 3231 / 2074 | 0 / 80 / 80 | 0 / 1 / 1 | 362 / 1066 / 664 |
| Three V2 Current Step cards | 29 / 245 / 245 | 0 / 51 / 51 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 3 / 3 |
| Closed idle | 2 / 2 / 2 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 |
| Closed auxiliary callback | 8 / 587 / 487 | 0 / 202 / 156 | 0 / 0 / 0 | 0 / 1 / 1 | 2 / 7 / 7 |
| Closed step callback | 59 / 1701 / 1637 | 0 / 430 / 402 | 0 / 0 / 0 | 0 / 1 / 1 | 2 / 7 / 7 |

### Cold objects and retention

| Phase | Frames | Textures | Masks | FontStrings | Hooks | Events | Retained KiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Adapter installation | 0 / 9 / 9 | 0 / 12 / 13 | 0 / 3 / 3 | 0 / 0 / 0 | 0 / 42 / 43 | 0 / 1 / 1 | 0.0 / 108.1 / 115.7 |
| First V1 open | 57 / 69 / 69 | 12 / 118 / 118 | 0 / 2 / 2 | 102 / 102 / 102 | 0 / 269 / 269 | 0 / 0 / 0 | 483.6 / 883.9 / 887.8 |
| First V2 open after V1 | 262 / 272 / 272 | 362 / 418 / 420 | 0 / 3 / 3 | 36 / 36 / 36 | 0 / 401 / 402 | 0 / 0 / 0 | 1424.9 / 1768.5 / 1778.0 |

Host adapter-file load and compilation measured 3.572 / 3.693 / 3.764 ms, including the unused compilation in the native control. This is separate from installation and WoW login.

Default opacity now initializes the split composition on first use, which explains the additional cold textures and hooks. Warm probes created no UI objects and registered no hooks or events. Warm post-GC heap deltas were near zero, with the V1/V2 mode fixture retaining about 1.3 KiB in all three controls. These figures cannot establish native object reclamation, WoW memory leaks, actual allocation counts, frame times or FPS. Small timing differences on unchanged paths and individual maxima are inconclusive. Closed idle had zero adapter calls and zero queued work. Closed native callbacks still run the corresponding cosmetic paths. The closed-step probe is an explicit delivered callback and does not imply polling.

### Stability and secret-string investigation

The reported failure originates at RestedXP's `GetNpcName`. It reads `GameTooltipTextLeft1:GetText()` and immediately calls `name:match`. Native `UpdateActiveStepsFrame` calls `GetActiveStepText` while checking whether the active-step payload is ready. `ReplaceNpcIds` resolves the NPC token before the display-widget update and even before the native V2-mode check. The reported error therefore occurs before the adapter's post-hook on the active-step item. Blizzard documents restrictions on inspecting secret UI values. The adapter has no hook or direct call to these resolver and payload functions. Its theme path updates existing widget styles and reads cached guide-row descriptors. [Native resolver](https://github.com/RestedXP/RXPGuides/blob/b4a0f99a2ceac856f75a11594bcaa19886236a01/functions.lua#L890-L941) · [Native payload path](https://github.com/RestedXP/RXPGuides/blob/b4a0f99a2ceac856f75a11594bcaa19886236a01/GuideWindow.lua#L3469-L3515) · [Blizzard's secret-value overview](https://worldofwarcraft.blizzard.com/en-gb/news/24246290)

A scratch host probe ran the unmodified upstream event, payload, token and lookup functions with the adapter absent and installed. Each configuration read 60 tooltip values for 60 unique IDs, with 30 ordinary strings and 30 deliberately restricted stand-ins. Both produced 30 failures at the same access. All five function identities were unchanged by installation. Twenty modeled look refreshes caused zero additional tooltip reads in either configuration. The stand-in raises on indexing and does not model Blizzard's secret tags or execution taint. This supports reporting the unguarded tooltip access upstream. RestedXP should guard restricted tooltip values before matching or caching them and fall back to the name already present in the guide token when resolution is unavailable. This audit leaves the resolver untouched and cannot determine whether the skin changes the circumstances of real-client taint.

The adapter uses owned presentation objects, combat guards around eligible cosmetic work, protected/forbidden checks at discovery and a single recovery event. Pooled cards keep their native parents and callbacks. The V1/V2 hide paths and EUI texture-cleanup isolation continue to be exercised by the regression suite. No new runtime profiling or diagnostic code was shipped.

### Remaining client validation

The full package suite covers appearance inputs, native handlers, guide/step ownership, checkbox marks, wrapping, labels, opacity endpoints and reset, deserialized settings, theme and mode changes, and deferred combat recovery. Confirm in WoW that fresh and reset Forever profiles render at 75%, saved 0% and 100% persist through `/reload`, and the appearance remains approved in both modes. For the secret-string report, repeat the same affected guide and NPC under matching combat and instance conditions with AddonSkins disabled and enabled. Record the client build, RestedXP version, mode and stack trace if the error returns. Live long-session memory, native taint and actual frame times remain unmeasured.
