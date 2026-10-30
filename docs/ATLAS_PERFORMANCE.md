# Atlas adapter performance audit

Baseline: `3b1a636782c36fbab16d5c2f10c283ad87ae2439`. Atlas source:
`c84758095a216d6508de051471099ebd48ba99e4`; EllesmereUI reference:
`5abb35ba158463ca25acc89cadcc56fbb7be6037`. Measured on 2026-10-30.

## Method and limits

Run `python3 benchmarks/run_atlas.py --baseline 3b1a636` and
`python3 benchmarks/run_atlas.py`. Optional `--output PATH` saves JSON.
The runner uses five fresh Lua 5.4 states/processes, 100 warmup operations and
1,000 timed operations per workload; tables below show medians. Timing uses
`os.clock` without tracing. A separate single operation uses `debug.sethook`
for total Lua/C call counts, including fixture/helper calls. No profiler is
included in the addon or test ZIP. The normal regression path still executes
all functional assertions; the benchmark path uses only its setup harness.

The fixture has 26 legend rows and models the inspected callback nesting:
normal OnShow accounts for six native selector initializers; native RefreshMap
calls ScrollBar_Update. Initialization is a counter stand-in: actual LibDD row
construction, map searches, game APIs, texture IO, GPU rendering, AceGUI and
shared menu renderer costs are NOT timed. EUI control APIs are source-shaped
stand-ins. These results isolate adapter overhead, not total Atlas latency.

GC-stopped KiB is temporary allocation churn including fixture hook return
packing, not retained native UI memory. Post-collection deltas were at harness
noise levels (roughly 0.05–0.24 KiB); this is not a long-session leak test.

## Measured results

Warm timings and churn are per 1,000 operations; calls are per one operation.

| Client / workload | Before ms | After ms | Calls before → after | Churn KiB before → after |
| --- | ---: | ---: | ---: | ---: |
| Retail / reopen | 24.507 | 11.863 | 572 → 184 | 79.356 → 79.231 |
| Retail / map | 34.127 | 10.270 | 853 → 172 | 1016.794 → 126.106 |
| Retail / legend | 13.935 | 11.687 | 326 → 171 | 126.044 → 126.044 |
| Retail / closed_load | 194.682 | 0.143 | 4057 → 6 | 41431.188 → 0.242 |
| Forever / reopen | 25.008 | 10.575 | 572 → 184 | 79.294 → 79.169 |
| Forever / map | 27.288 | 11.117 | 657 → 172 | 251.169 → 126.106 |
| Forever / legend | 14.957 | 12.663 | 326 → 171 | 126.044 → 126.044 |
| Forever / closed_load | 158.367 | 0.172 | 3705 → 6 | 38321.812 → 0.242 |

| Client | Cold skin setup ms before → after | First show after setup ms before → after |
| --- | ---: | ---: |
| Retail | 4.692 → 7.255 | 0.032 → 0.015 |
| Forever | 3.298 → 3.959 | 0.047 → 0.016 |

No cold-start improvement is claimed. One-time setup now adds six reusable
selector accent textures; round masks replace the three square-slot textures.
The cold timing includes mock EUI/helper initialization and host noise.

Both versions created zero new UI objects/hooks, hierarchy enumerations, font,
geometry or icon-texture writes in warm reopen/map/legend batches. The baseline
closed-load stress caused 204,000 Retail / 192,000 Forever border colour writes
per 1,000 unrelated loads; the new event filter causes zero. Those large counts
are a stress workload, not a claim that real users load 1,000 addons.

## Confirmed adapter redundancy and fixes

1. Warm OnShow re-entered Window, Button, IconButton, Lock and Dropdown even
   when generation/chrome/controls were complete. Cache completed eager roots
   by look generation and region count. Pending chrome, changed regions, theme
   changes and explicit refresh still discover/style synchronously. Native
   Atlas controls are eager, not arbitrary pooled descendant trees.
2. RefreshMap already finishes ScrollBar_Update, whose post-hook styles the
   legend. Its second post-hook repeated all 26 rows and visited EJ, although
   native RefreshMap hides EJ. Remove the duplicate hook. Keep source-owned EJ
   display/row hooks. Cache row text identity per generation; replacement rows
   and replacement text regions still receive fonts. Preserve guard checks.
3. Every ADDON_LOADED triggered a full Apply, including while closed. Filter
   to Atlas and Blizzard_EncounterJournal; module option registration and
   OpenOptions still bind current Ace libraries, theme/manual/combat refreshes
   remain. Closed legend updates skip cosmetic row work until normal OnShow.

No H.Scan exists in this adapter. Completed roots had no repeated region/child
enumeration or object/font/geometry creation before this task; those were not
the measured bottlenecks. No polling, OnUpdate hook or timer was introduced.
All changes stay in the Atlas adapter; shared helpers are unchanged.

## Source review of work deliberately preserved

Atlas Core/UI.lua OnShow calls both selector refresh functions. In
Core/AtlasFrame.lua each refresh initializes all three window-size selectors;
LibDD InitializeHelper clears/hides its native menu pool, then the category or
map initializer rebuilds rows. Auto_Select can also refresh map data.
Core/Atlas.lua RefreshMap updates map content, searches/reset input, creates
needed entries, then scrolls the legend. These native data operations and
callbacks remain intact. We cannot attribute the visible reopening stall to
any one of them without a client trace. Skipping native initialization would
be a speculative behavioural change.

Menus.lua uses ownership-gated renderer completion hooks. Actual shared menu
rebuild cost is outside this adapter fixture; no shared/menu rewrite was made
without a representative profile. Options uses scoped FeedGroup/release paths
and its existing warm regression counters still pass. No global UI scan or
new scheduler runs while Atlas is closed.

## Regression and remaining verification

Tests reject reintroducing warm control revisits, duplicate legend completion
or unrelated-load cosmetic refreshes. Each mutation was independently checked
against the fixture. Late chrome assignment, changed root regions, explicit
control replacement, recycled row/text identity, theme/accent, disabled/combat,
menus, native input/returns and Retail/Forever optional EJ coverage remain.
`python3 scripts/package.py` passes all compilation, regressions, manifests,
versions, license and installation-archive checks.

The reported visible stall has NOT been reproduced or proven fixed. In-game
reopening, cold texture load, menu population, real client CPU/GC, native
crashes/taint and long-session behaviour remain unmeasured. Visual review is
still needed for the restored round globe/rim and subtle selector accent bars.
See [raw results](atlas-performance-results.json) and [test guide](ATLAS_TEST.md).
