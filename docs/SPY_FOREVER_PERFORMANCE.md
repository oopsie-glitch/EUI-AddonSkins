# Spy Forever — material/depth refinement performance

Baseline: optimized PR #77 `e7631a3e9fada47474a9bda356f0ce7a0fef1c2c`.
This pass preserves its window/header/row geometry and changes lighting/materials.
[Exact layers and limits](SPY_FOREVER.md#rows-and-native-texture-ownership).

Measured runtime snapshot: `45189b1c5b2603f2e43659176b566d5329537f53`.
[Cloud comparison and raw five-trial JSON](https://github.com/oopsie-glitch/EUI-AddonSkins/actions/runs/42896769375).
The final documentation-only commit has the same runtime.
[Earlier composition comparison](https://github.com/oopsie-glitch/EUI-AddonSkins/blob/e7631a3e9fada47474a9bda356f0ce7a0fef1c2c/docs/SPY_FOREVER_PERFORMANCE.md)
remains evidence for that snapshot, not this pass's baseline timing.

## Method

`SPY_SOURCE=/tmp/spy-upstream python3 benchmarks/run_spy.py --baseline e7631a3e9fada47474a9bda356f0ce7a0fef1c2c --trials 5 --iterations 1000 --rows 40`

Five fresh VMs per native-only/baseline/candidate plus independent cold profiling
VMs, 40 shown slots, 100 warm-ups. Player/sync/hover/hide-show/transfer/unchanged-
opacity/closed jobs use 1,000 callbacks; reopen/theme/four-value opacity cycles
use 100. Cold is one adapter acquisition over existing rows. Slot replacement
alternates two pre-created identities, warming both, distinct from ordinary
same-row hide/show.

Official Spy 1.3.8-forever5 (CF9501070), SHA256
`f0373e3cb8a31864d41532e08fb5748f42f0a76f45b2c4c9b0bbd92efe14fbec`,
runs unmodified Colors/Widgets/MainWindow/ShowTooltip on mocked client APIs.
The list dispatcher/pointer events are shaped. Full detection/bootstrap is not
run. CPU uses os.clock; churn stops GC, retention collects before/after. Call
profiles run separately (ten warm callbacks, one cold acquisition) and never
contaminate timed passes. Closed idle is a no-event loop, not a game profiler.

## Five-trial median host timings

| Workload | Iterations | Native-only ms | Baseline ms | Refinement ms |
| --- | ---: | ---: | ---: | ---: |
| Cold acquisition | 1 | 0.001 | 2.170 | 2.243 |
| Native player updates | 1000 | 3.696 | 3.783 | 3.790 |
| Whole-pool sync | 1000 | 0.026 | 19.380 | 20.131 |
| Hover pairs | 1000 | 0.553 | 1.878 | 1.971 |
| Same-row hide/show | 1000 | 0.058 | 0.673 | 0.653 |
| Reused-slot transfer | 1000 | 0.144 | 26.078 | 28.710 |
| Window reopen | 100 | 0.011 | 9.516 | 9.643 |
| Standard/Forever pairs | 100 | 0.002 | 37.355 | 38.124 |
| 0/75/100/75 opacity cycles | 100 | 0.002 | 4.918 | 4.873 |
| Unchanged opacity | 1000 | 0.011 | 0.324 | 0.317 |
| Closed native updates | 1000 | 3.683 | 3.849 | 3.852 |
| Closed no-event idle | 1000 | 0.009 | 0.009 | 0.010 |

No added calls/scans/artwork/geometry/paint/alpha/visibility work on native
player updates or unchanged whole-pool sync. The 1,000 width writes in SetBar
are native truncation; the native-only control makes them too.
Hover still makes eight writes per enter/leave pair, now tinting the two reused
bevel gradients with vertex colour rather than replacing their source colour.
Its timing is slightly higher here; no CPU/FPS improvement is claimed.
The same-row hide/show, reopen and opacity operation counts remain unchanged.

**Replacement/theme overhead is real and bounded.** Slot transfer rises
26.078 -> 28.710 ms (+10.1%, about 2.63 microseconds per transfer) per 1,000
alternating replacements. It makes 12,000 more geometry writes and 4,000 more
visibility calls because the two old line textures are now attached to/hid with
the native bar. This work is not performed on normal per-player paints.

One hundred Standard/Forever pairs make 16,000 additional visibility calls
(hiding/showing the reused bevels), measuring 37.355 -> 38.124 ms (+2.1%).
Cold acquisition adds 320 geometry and 162 paint operations over 40 slots for
the attachment and one-time gradient setup. No repeated gradient construction
occurs on warm events. These costs are reported for draft visual review, not
concealed as free cosmetics or treated as release approval.

## Resources and heap

| Complete cold mock adapter acquisition, 40 slots | Baseline | Refinement | Delta |
| --- | ---: | ---: | ---: |
| Frame objects | 65 | 65 | 0 |
| Texture objects | 270 | 270 | 0 |
| Posthooks | 195 | 195 | 0 |
| Lua retained KiB | 2707.030 | 2752.522 | 45.492 |
| Lua churn KiB | 2908.111 | 2992.314 | 84.203 |

**Zero new frames, textures, masks or hooks in this pass**, per-row or shared.
The same EUI rim primitives and surface masks are called as in the baseline;
only four additional shadow attachments reuse the existing well mask where
supported. Seven new shared Colour objects support the row bevel ramps and
header ledge (three module-wide, four per main window). Pool entries add two
references to already existing textures; no native row object is duplicated.

The rim fixture abstracts EUI's internal pieces/layout frames/masks, so these
totals are not the real client's complete counts. Unlike the preceding redesign,
this pass adds no EUI primitive call, hence the source-based native frame/texture/
mask delta is also zero. GPU/native gradient state and allocations are not
measured as bytes.

| Workload | Baseline churn KiB | Refinement churn KiB | Baseline retained KiB | Refinement retained KiB |
| --- | ---: | ---: | ---: | ---: |
| Native player updates | 500.188 | 500.188 | 0.000 | 0.000 |
| Whole-pool sync | 125.500 | 125.500 | 0.000 | 0.000 |
| Hover pairs | 2031.664 | 2031.664 | 0.000 | 0.000 |
| Same-row hide/show | 0.344 | 0.344 | 0.000 | 0.000 |
| Reused-slot transfer | 3766.219 | 4578.719 | 0.000 | 0.000 |
| Window reopen | 4181.996 | 4181.996 | 0.156 | 0.156 |
| Standard/Forever pairs | 16059.277 | 16059.277 | 0.000 | 0.000 |
| 0/75/100/75 opacity cycles | 880.996 | 880.996 | 0.000 | 0.000 |
| Unchanged opacity | 0.250 | 0.250 | 0.063 | 0.063 |
| Closed native updates | 500.188 | 500.188 | 0.000 | 0.000 |
| Closed no-event idle | 0.000 | 0.000 | 0.000 | 0.000 |

The cold +45.492 KiB retained result is **mock Lua memory**, much of it fake
gradient/anchor/colour tables; not a WoW C/GPU estimate. Transfer churn rises
812.500 KiB per 1,000 replacements from extra anchor tables but retains zero
after collection. Warm retained deltas up to 0.156 KiB are small VM residuals,
not accumulating art. Theme/player/hover/opacity churn is unchanged.

The fixture represents UI objects/methods and setter arguments as Lua tables;
native secure-hook emulation also packs returns. Neither models WoW's actual
C-side storage or CPU implementation. Do not claim real retained memory/FPS
from these numbers.

## Separate call profiles

Ten callbacks per warm row, one acquisition for cold. Total includes fixture,
shared and C calls; Spy.lua is the direct adapter subset.

| Workload | Baseline total | Refinement total | Baseline Spy.lua | Refinement Spy.lua | Baseline helpers | Refinement helpers |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Cold acquisition | 13074 | 14250 | 1164 | 1164 | 593 | 593 |
| Native player updates | 1601 | 1601 | 0 | 0 | 0 | 0 |
| Whole-pool sync | 7791 | 7791 | 3240 | 3240 | 20 | 20 |
| Hover pairs | 441 | 441 | 80 | 80 | 0 | 0 |
| Same-row hide/show | 351 | 351 | 120 | 120 | 0 | 0 |
| Reused-slot transfer | 9411 | 9811 | 3530 | 3530 | 20 | 20 |
| Window reopen | 29151 | 29151 | 4830 | 4830 | 3490 | 3490 |
| Standard/Forever pairs | 98381 | 103181 | 14180 | 14180 | 7300 | 7300 |
| 0/75/100/75 opacity cycles | 15951 | 15951 | 3800 | 3800 | 120 | 120 |
| Unchanged opacity | 171 | 171 | 50 | 50 | 0 | 0 |
| Closed native updates | 1601 | 1601 | 0 | 0 | 0 | 0 |
| Closed no-event idle | 11 | 11 | 0 | 0 | 0 | 0 |

Native/C breakdown and every raw trial are in the linked JSON. Direct native
SetBar uses zero adapter calls. The single scoped native tooltip posthook and
its fallback are retained; this pass does not return to 274 hooks.

## Rendering trade-offs and actual limits

The prior panel shadows occupied the three-unit rim band, where the art could
obscure them. Moving the same strips three units inward and making them five
units deep exposes the lip, while the existing shared mask clips chamfers.
Native opaque bars still hide material underneath; no raised full-area sibling
is added over row text/data to fake a shadow.

The full-row material is now behind the native fill. Two former sibling lines
become soft two-unit ARTWORK bevels on that fill, below OVERLAY text, with white
gradient sources and vertex-tint hover feedback. Normal side rails drop to
alpha 0.18, avoiding heavy individual boxes. Native colour/path/opacity/value
and name/metadata geometry remain unchanged. Fully opaque native textures keep
their native centre appearance; forced Concept A grain there would require
replacing or overpainting the user's texture choice. This limitation is explicit.

GPU work is not free: the top/bottom lines become two units high rather than one,
and four shared panel shadow strips grow from three to five units. At a native
16-unit row height, decorative row region area rises roughly 12.5% before
horizontal inset differences (broad underlay plus edges, excluding side rails).
Masking four lip strips adds mask sampling with an existing mask. Real blending/
occlusion/batching, GPU cost and FPS are unmeasured. No new noisy artwork, baked
class texture, reflection shader or continuous effect was added.

Header/list coverage budgets are unchanged at 75% by default and preserve
saved 0/100. Their RGB/material lighting changes; backgrounds are not stacked.
At 0 their full-area surfaces hide, while native bars and decorative row/border
chrome remain. Fixed lip shadows/dividers are narrow perimeter lighting, not an
additional opaque full-window plate.

## Validation and live acceptance

Full regressions/package, actual-source/native constructors/paints, masked and
unmasked surface modes, Heavy/slim rim modes, hover fallback, saved 0/75/100 boots,
Reset, pooled retirement/reuse, Standard/disable, native texture/class opacity,
counter/title/resize, combat deferral and EUI cleanup are exercised.
Specific assertions cover reused bevel ownership/gradient falloff/BLEND/sublevel,
native fill above underlay and text above bevels, inherited row visibility,
retired-bar cleanup, panel lip placement, shared corner mask and header ledge.
Mutation checks must detect missing bevels/lip, broken tint/opacity/ownership
and the existing geometry/settings regressions.

Source comparison confirms SyncHeader, SyncControl and RowGeometry are identical
to the baseline. Only cosmetic edge sizes/anchors used for material rendering
change; no native window/row/header/control layout is redesigned. Main, version
and packaged 66-file installation layout are unchanged.

Actual screenshot quality, texture contrast at UI scale, opaque/transparent
native bars, corner lighting, targeting/tooltip/hover, parent visibility,
combat taint and long-session native/GPU behavior remain live checks. The
material pass is a draft for screenshots, not declared visually complete.
