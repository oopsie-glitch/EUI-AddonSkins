# Spy Forever material pass — performance comparison

This comparison covers the Concept A row-material/inner-viewport refinement in
draft PR #77. Baseline: `43beb7c48a1a569964f39e3d4ca2b50e8629a83b`.
This is a development measurement, excluded from player ZIPs.

## Reproduction and controls

Run on GitHub Actions with Python 3 and liblua5.4:
`SPY_SOURCE=/tmp/spy-upstream python3 benchmarks/run_spy.py --baseline 43beb7c48a1a569964f39e3d4ca2b50e8629a83b --trials 5 --iterations 1000 --rows 40`.

The package workflow downloads official Spy 1.3.8-forever5 (CF file 9501070),
verifies SHA256
`f0373e3cb8a31864d41532e08fb5748f42f0a76f45b2c4c9b0bbd92efe14fbec`,
then runs its unmodified row constructors, SetupBar and SetBar against mocked
client APIs. The list dispatcher is shaped: full detection/bootstrap requires
the game. Hover events and mouse position are simulated, retaining native-shaped
tooltip scripts. Regression tests separately exercise real native row constructors
and the native secure template's source is recorded in the audit logs.

The runner reuses only fixture setup, never removes regression assertions.
Native-only, baseline and candidate each get five fresh Lua states. The pool has
40 shown rows. Each warm workload has 100 warm-up iterations before measuring
1,000 updates, whole-pool sync callbacks or enter/leave pairs. Cold acquisition
includes Standard install then first Forever application. Timing is os.clock;
allocation churn stops GC during the workload, retention collects before/after.
The logs contain all trials and their medians, operation counts and deltas.

## Interpretation limits

Mock UI objects implement their methods as Lua tables/functions; setters may
allocate arrays. These measurements include those fixture costs. Heap numbers
are mock-host Lua values, not WoW C-side frame/texture storage, GPU memory,
actual addon retained memory or FPS. In particular hover colour setter churn
does not demonstrate corresponding runtime Lua allocations in WoW.
Small retained deltas around +/-0.125 KiB reflect measurement/VM noise.

Existing native text-width changes count as geometry operations in SetBar:
the native-only control makes the same 1,000 writes. They are not skin work.
Cold discovery counts existing shared-helper setup; warm comparisons are the
important constraint on frequent player events. Native detection CPU, actual
tooltip complexity, combat taint, secure hit-testing and long-session resource
behavior require the live client.

## Fixed and event costs

Added artwork: two two-unit material textures per acquired row slot and five
shared textures (four corner ticks and a header ledge). A 40-slot pool adds
**85 textures, zero frames, and 80 event posthooks**. The four existing edge
textures per row are reused for native hover emphasis. Four shared gradient
colour objects are created once. Repeated recycling reuses the texture pairs;
no per-player bar-paint hook, polling or new warm hierarchy traversal is added.

Each genuine enter/leave pair changes four existing edge colours twice:
**eight paint writes**, zero alpha/geometry writes and no new UI objects/hooks.
Repeated identical enter events do not repaint. Hidden/retired/Standard rows
clear the emphasis; combat defers paint. Native persistent selection is not
exposed reliably, so none is synthesized.

## Measured results

Runtime snapshot: `2ce4475d431b26a70ba21ae618693c337489f567`.
[Cloud comparison and raw five-trial logs](https://github.com/oopsie-glitch/EUI-AddonSkins/actions/runs/42833436621).

| Workload | Native control ms | Baseline ms | Candidate ms | Candidate minus baseline ms |
| --- | ---: | ---: | ---: | ---: |
| Cold acquisition (40 rows) | 0.001 | 3.677 | 4.698 | 1.021 |
| 1,000 native player updates | 7.404 | 7.348 | 7.326 | -0.022 |
| 1,000 whole-pool sync callbacks | 0.051 | 31.214 | 33.863 | 2.649 |
| 1,000 enter/leave pairs | 0.291 | 0.296 | 2.698 | 2.402 |

Warm player updates and whole-pool sync create zero objects/hooks, add zero
hierarchy reads/scans, cosmetic paint/alpha/visibility writes or geometry work.
Player-update churn remains 500.063 KiB/1,000 and row-sync churn 125.625 KiB/1,000,
identical to baseline. Post-GC deltas remain -0.125 / +0.125 KiB respectively.
The row-sync median is **8.5% higher** here (+2.649 ms per 1,000 forty-row calls,
about 2.65 microseconds per whole-pool callback). Cached tone-parent/visibility
and hover-state guards avoid redundant warm ownership/paint function calls.
Timing noise and fixture costs preclude a real-game regression percentage.

The cold candidate adds **725.766 KiB mock Lua churn and 698.281 KiB mock retained
heap**, alongside the 85 textures and 80 hooks. These are synthetic object-table
costs, not a WoW memory estimate. Hover pairs add 1,875.250 KiB mock setter churn,
0.063 KiB retained delta and 8,000 colour writes over baseline; no additional
objects/hooks/geometry/alpha work. This is an explicit event cost, not free
cosmetics. The workload has no unbounded retained growth. A constant four-edge
palette change was preferred to new hover frames, glows or state polling.


## Required live checks

Check material strength at normal UI scale over every class and unknown/status
fill, native user-selected textures and opacity, actual native highlight/tooltip,
recycled rows, mode/window changes, Standard restoration and combat recovery.
The automated comparison establishes bounded event/artwork cost, not visual
approval or live-client CPU/FPS/memory.
