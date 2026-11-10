# Spy Forever — Concept A redesign performance comparison

The comparison baseline is the optimized, functionally tested PR #77 build
`b4f2e7b6e4ac86b2b2a1ec9352c93422bdc3abe2`. Its visual design is not approved.
The new composition and acceptance criteria are in [SPY_FOREVER.md](SPY_FOREVER.md).

Measured runtime: `3fd024ca30105adea100aa61f00c61b81d683e53`.
[Raw five-trial JSON and checks](https://github.com/oopsie-glitch/EUI-AddonSkins/actions/runs/42882717569).
The final documentation-only commit has the same runtime.
[Previous optimization audit](https://github.com/oopsie-glitch/EUI-AddonSkins/blob/b4f2e7b6e4ac86b2b2a1ec9352c93422bdc3abe2/docs/SPY_FOREVER_PERFORMANCE.md)
remains evidence for that snapshot; historical timings from different runners
are not used as this comparison's baseline.

## Method

`SPY_SOURCE=/tmp/spy-upstream python3 benchmarks/run_spy.py --baseline b4f2e7b6e4ac86b2b2a1ec9352c93422bdc3abe2 --trials 5 --iterations 1000 --rows 40`

GitHub Actions downloads pinned official Spy **1.3.8-forever5**, CF9501070,
SHA256 `f0373e3cb8a31864d41532e08fb5748f42f0a76f45b2c4c9b0bbd92efe14fbec`.
Its unmodified Colors/Widgets/MainWindow constructors, SetBar and ShowTooltip run
against deterministic mocked client/player/tooltip APIs. Native list dispatch
and pointer events are shaped; full detection/bootstrap is not run.

Five fresh timed VMs per native-only/baseline/candidate, with independent fresh
cold call-profile VMs. Warm jobs get 100 warm-ups. Most jobs use 1,000 callbacks;
reopen/theme pairs/four-value opacity cycles use 100. Cold is one adapter
acquisition over 40 existing rows. Reuse alternates two pre-created native
identities in slot 2, warmed before measuring, separate from same-row hide/show.
Closed idle is a no-event loop plus source review for no added polling; it is
not a game-wide idle profiler.

CPU uses os.clock. GC is stopped during churn measurement, then collected for
retained deltas. Total/direct Spy.lua/shared Widgets.lua/native/C calls are
profiled separately (10 warm callbacks, one cold acquisition), never during
timing. Fixture source has its own chunk name, avoiding false source matches.
Every trial is retained in the linked logs.

## Five-trial median host timings

| Workload | Iterations | Native-only ms | Baseline ms | Redesign ms |
| --- | ---: | ---: | ---: | ---: |
| Cold acquisition | 1 | 0.001 | 4.858 | 4.454 |
| Native player updates | 1000 | 7.466 | 7.400 | 7.445 |
| Whole-pool sync | 1000 | 0.051 | 35.932 | 33.736 |
| Hover enter/leave pairs | 1000 | 1.014 | 3.723 | 3.813 |
| Same-row hide/show | 1000 | 0.128 | 1.268 | 1.234 |
| Reused-slot transfer | 1000 | 0.234 | 54.653 | 50.063 |
| Window reopen | 100 | 0.019 | 19.706 | 19.945 |
| Standard/Forever pairs | 100 | 0.003 | 73.111 | 70.840 |
| 0/75/100/75 opacity cycles | 100 | 0.004 | 9.137 | 10.295 |
| Unchanged opacity | 1000 | 0.018 | 0.596 | 0.574 |
| Closed native updates | 1000 | 7.518 | 7.568 | 7.598 |
| Closed no-event idle | 1000 | 0.015 | 0.015 | 0.014 |

Player/sync/hover have identical warm operation/call counts; their small timing
differences are host variability, not a demonstrated CPU/FPS improvement.
No new art/hooks/scans/geometry/paint/alpha writes are added to native SetBar.
Its 1,000 width writes belong to native truncation, as the native-only control
confirms. Whole-pool warm sync also adds zero cosmetic writes or discovery.

Changed opacity is **12.7% slower here**, +1.158 ms per 100 four-value cycles:
it now paints separate header/list backgrounds and three bezel segments. Paint
writes rise 800 -> 2,800 (two -> seven per changed value), visibility writes
400 -> 800. Unchanged opacity retains the optimized no-work path.
Theme pairs make 4,200 more geometry writes per 100 pairs for revised anchors/
title height and restoring native resize bounds. These are explicit lifecycle
costs, not hidden warm-player work.

## Resources: fixture counts versus real EUI primitives

| Cold adapter acquisition, 40 rows (mock UI) | Baseline | Redesign | Delta |
| --- | ---: | ---: | ---: |
| Frames | 65 | 65 | 0 |
| Texture objects | 307 | 270 | -37 |
| Posthooks | 195 | 195 | 0 |
| Lua retained KiB | 2989.937 | 2707.030 | -282.906 |
| Lua churn KiB | 3196.424 | 2908.049 | -288.375 |

One full-row material texture replaces two short textures per slot: **40 fewer
per-row textures** at this pool size, with no new per-row frame/hook. Shared
header/bezel/inner-panel art adds resources. The single native tooltip posthook
is retained; missing-ShowTooltip forks keep their existing fallback.

**The fixture models each EUI rim as one texture and no internal frame/masks.**
Do not present its +0 frames/-37 textures as the actual game's complete count.
The pinned public
[EUI border implementation](https://github.com/EllesmereGaming/EllesmereUI/blob/d83ffb7db2dc0104d328d4c99cc700c2ea052948/EllesmereUI_RetailAtlas.lua)
creates one layout frame, eight textures and four corner masks for a normal
textured rim; Heavy Bronze creates one layout frame/eight textures without
those masks. Each uses its own OnSizeChanged layout script, not polling.

Static native-primitive accounting for this redesign:
- Main rim changes textured -> Heavy where supported: same frame/texture count,
  four fewer corner masks.
- New inner textured rim: +1 internal layout frame, +8 textures, +4 corner masks.
- Shared header/bezel/shadows add nine ordinary textures and replace seven old
  well-edge/tick textures: +2 textures.
- Replacing two row bands with one material over 40 slots: -40 textures.
- Header Surface may add one mask when the existing slice-mask API is available.

Thus, for the pinned Heavy-capable API and 40 slots, the expected delta is
**-30 ordinary textures, +1 EUI-internal layout frame, +1 optional surface mask,
zero new posthooks**. The new inner layout frame has one owned size script.
With the textured outer fallback, the expected mask delta is +5 instead of +1.
These are source-based creation counts, not live client/GPU memory observations;
future/older EUI implementations can differ. No additional native row objects
or interactive frame is created by the adapter.

### GPU fill trade-off

The material now shades the row's full height. At a native 16-unit row height,
one 14-unit-high surface covers roughly 3.5 times the area of two previous
two-unit bands before horizontal insets, despite using fewer textures. It adds
bounded fragment coverage; it is not free GPU work. This is the main visual
benefit (broad surface depth), and actual GPU/FPS cost is unmeasured. One gradient
was chosen instead of overlapping two full-row glazes to limit overdraw.

## Heap and lifecycle comparison

| Workload | Baseline churn KiB | Redesign churn KiB | Baseline retained KiB | Redesign retained KiB |
| --- | ---: | ---: | ---: | ---: |
| Native player updates | 500.188 | 500.188 | 0.000 | 0.000 |
| Whole-pool sync | 125.500 | 125.500 | 0.000 | 0.000 |
| Hover enter/leave pairs | 2031.664 | 2031.664 | 0.000 | 0.000 |
| Same-row hide/show | 0.344 | 0.344 | 0.000 | 0.000 |
| Reused-slot transfer | 4024.031 | 3766.219 | 0.000 | 0.000 |
| Window reopen | 4161.621 | 4181.934 | 0.156 | 0.156 |
| Standard/Forever pairs | 15421.777 | 16059.277 | 0.000 | 0.000 |
| 0/75/100/75 opacity cycles | 352.871 | 880.996 | 0.000 | 0.000 |
| Unchanged opacity | 0.250 | 0.250 | 0.063 | 0.063 |
| Closed native updates | 500.188 | 500.188 | 0.000 | 0.000 |
| Closed no-event idle | 0.000 | 0.000 | 0.000 | 0.000 |

Churn is temporary, not retained memory. The fixture implements each UI object
and its methods as Lua tables and colour setters as argument tables. Secure-hook
emulation packs returns; WoW's native secure hook does not run that wrapper.
These heap values do not estimate WoW C-side frames/textures, GPU memory or
actual retained addon memory. Small post-GC values up to 0.156 KiB are VM/
measurement residuals; no accumulating art was observed.

Slot transfer reduces geometry writes 28,000 -> 23,000 and visibility writes
6,000 -> 4,000 per 1,000 swaps with one material instead of two. Its churn also
falls. Native row identities are reused; native allocation is not disguised as
skin cost. Theme/reopen and changed-opacity churn increases are explicit above.
Ordinary steady updates/hover add no UI objects or hooks.

## Separate call profiles

Ten callbacks per warm workload, one cold acquisition. Total includes fixture,
C and shared calls; Spy.lua is the direct adapter subset.

| Workload | Baseline total | Redesign total | Baseline Spy.lua | Redesign Spy.lua | Baseline helpers | Redesign helpers |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Cold acquisition | 13951 | 13074 | 1197 | 1164 | 593 | 593 |
| Native player updates | 1601 | 1601 | 0 | 0 | 0 | 0 |
| Whole-pool sync | 7791 | 7791 | 3240 | 3240 | 20 | 20 |
| Hover enter/leave pairs | 441 | 441 | 80 | 80 | 0 | 0 |
| Same-row hide/show | 351 | 351 | 120 | 120 | 0 | 0 |
| Reused-slot transfer | 9611 | 9411 | 3540 | 3530 | 20 | 20 |
| Window reopen | 29081 | 29151 | 4810 | 4830 | 3490 | 3490 |
| Standard/Forever pairs | 100641 | 98381 | 14560 | 14180 | 7300 | 7300 |
| 0/75/100/75 opacity cycles | 15151 | 15951 | 3720 | 3800 | 120 | 120 |
| Unchanged opacity | 171 | 171 | 50 | 50 | 0 | 0 |
| Closed native updates | 1601 | 1601 | 0 | 0 | 0 | 0 |
| Closed no-event idle | 11 | 11 | 0 | 0 | 0 | 0 |

Raw profiles include native/C counts and native-only controls. Hover/player/sync
counts are unchanged. The count reduction in slot transfer is a lifecycle
improvement; no warm FPS claim follows from it.

## Stability and validation limits

The full suite and actual-source mode preserve native texture paths/RGBA/value,
secure row anchors/actions, nil-containing callback returns, dynamic metadata
and normal FontString truncation. The new dual-anchor name constraint adds no
per-player hook. Current EUI typography and original anchors/bounds restore on
Standard/disable; no native saved dimensions or row-height settings are written.
The 180-unit resize floor is guarded and never forced above current width;
legacy tiny saved windows retain the documented safety reflow.

Normal/fallback hover and Heavy/slim rim API modes, pool retirement/reuse,
native resize/mode changes, combat deferral, EUI cleanup, opacity 0/75/100 boots,
Reset, queued reversions and theme cycling are tested. Mutation checks detect
reverting the Heavy rim, full-surface material, inset, native-hover route, opacity
budget and unchanged-value queue suppression. Packaging checks one addon folder,
66 source-identical runtime files, exact MIT license and unchanged 1.6.5 metadata.

Mocks do not certify rendered chamfers/lighting, parent visibility propagation,
native secure hit-testing, taint/crash freedom, actual native resource memory,
GPU/FPS, every fork or long-session behavior. These require WoW screenshots and
the [live checklist](SPY_FOREVER.md#deliberate-compromises-and-screenshot-checklist).
The draft remains unmerged/untagged/unpublished.
