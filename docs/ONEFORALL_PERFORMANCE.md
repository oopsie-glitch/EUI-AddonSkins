# OneForAll performance audit

Approved baseline: `7676fdb` (owner confirmed the rarity fix and accepted the
visual skin in game). PR #68 remains draft; no release metadata changes.

## Result and scope

The audit found redundant **cosmetic callbacks**, not repeated warm subtree
scans. Targeted changes reduce row-selection work, colour classification,
data-icon ancestry checks and empty-queue allocations. Gear Planner's accepted
same-item quality cache is unchanged. Native data refreshes, APIs, event
semantics, appearance, semantic colours and layout remain intact.

Measured Retail skin calls per warm action fall from 2,342 to 1,400 for 40-row
refresh, 820 to 752 for Gear Planner refresh, 37 to 33 for a reopen pair and
9 to 2 for a data-icon update. Forty-row refresh readbacks halve. Reopen
allocation churn falls 55.5%. These are headless operation/host measurements,
**not WoW CPU, native C-call, frame-time or FPS measurements**.

## Methodology and reproduction

- Five fresh-process trials per configuration, run **serially** for final
  before/native/after results. Reported values are medians. Each process tests
  Retail and Forever identity/protection conventions separately.
- Source: supplied OneForAll 6.0.1, ZIP SHA256
  `7dbde14d2edeffd837285f70c409b05629018ba243096f4354805639efeec48c`.
  Actual external Widgets, MainFrame, Settings, QoL and GearPlanner files run
  under the existing fixture. They are not redistributed. Other section pages
  use eight lightweight source-shaped fixtures. Native item/list providers for
  the UI workload are deterministic, with an empty GearIndex; the real data
  index is measured separately below.
- WoW frames/API methods and public EUI styling primitives are mocked. The
  native-only control runs the **same** target workload without installing the
  adapter. Its definition is parsed by the fixture but not activated; definition
  load time is recorded separately. This separates native UI work from adapter
  overhead within this model, not from the complete client/EUI engine cost.
- Warm workloads use 20 warmups and 200 iterations. Stable look notifications
  use 20 iterations; initial construction and an actual accent/font change run
  once per trial. Each warm workload also gets 100 separately timed CPU samples
  for p95/max and one untimed debug call-profile sample. Cold function calls are
  not profiled (`-1` in JSON); cold time and operation counts are collected.
- Time uses Lua 5.4 `os.clock` (process CPU). The profiler distinguishes Lua
  functions, host C-library calls and adapter-source calls. The API methods are
  Lua mocks: host C-call counts **must not** be described as WoW API C calls.
  Getter/write counters give separate API-shaped operation counts.
- Allocation churn is heap growth with GC stopped during the batch. GC is
  restarted and a forced full collection is separately timed; post-collection
  retained growth is recorded. Mock frames have many Lua closures, and mock
  secure hooks allocate return tables. These strongly inflate heap/GC costs
  relative to real native frames/hooks. Neither churn nor forced host GC pauses
  are player memory/FPS measurements.

```sh
python3 benchmarks/run_oneforall.py --baseline 7676fdb --source /path/to/OneForAll --output before.json
python3 benchmarks/run_oneforall.py --native --source /path/to/OneForAll --output native.json
python3 benchmarks/run_oneforall.py --source /path/to/OneForAll --output after.json
python3 benchmarks/run_oneforall.py --index-only --source /path/to/OneForAll --output native-index.json
```

Without `--source`, the UI runner is portable using the source-shaped fixture.
The native-index mode requires supplied sources/data. The runtime adapter hash
is retained in the recorded final UI results.

## Before/native/after CPU results

All numbers below are **host CPU milliseconds per entire workload**, including
native work. A reopen iteration calls ToggleUI twice; page switch selects one
of eight sections; Settings updates 40 checks; list refresh updates 40 existing
rows from a 256-row pool. UI construction excludes game asset loading/rendering.

| Workload | Iterations | Retail native | Retail before | Retail after | Forever before | Forever after |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Install | 1 | 0.001 | 0.454 | 0.446 | 2.102 | 2.099 |
| First window | 1 | 22.434 | 42.160 | 42.478 | 40.458 | 40.072 |
| First lazy pages, Settings/QoL | 1 | 65.091 | 124.541 | 129.374 | 121.354 | 124.537 |
| First Gear Planner | 1 | 17.081 | 60.552 | 55.981 | 60.446 | 56.125 |
| Construct 256 list rows | 1 | 108.150 | 178.022 | 184.268 | 184.368 | 168.365 |
| Reopen pair | 200 | 0.060 | 1.328 | 0.877 | 1.318 | 0.939 |
| Page switch | 200 | 14.237 | 28.223 | 28.087 | 27.313 | 25.501 |
| Gear refresh | 200 | 30.869 | 108.367 | 100.467 | 110.463 | 97.016 |
| Gear selection | 200 | 20.142 | 103.472 | 92.002 | 97.087 | 88.137 |
| Settings check states | 200 | 45.103 | 71.234 | 72.996 | 70.611 | 70.742 |
| QoL category navigation | 200 | 7.906 | 22.419 | 20.753 | 22.476 | 20.938 |
| Refresh 40 list rows | 200 | 71.748 | 241.872 | 181.565 | 257.828 | 180.365 |
| Same-look notifications | 20 | 0.006 | 83.583 | 69.101 | 76.029 | 69.216 |
| Actual accent/font change | 1 | 0.005 | 14.430 | 12.572 | 14.195 | 14.215 |
| Closed-window data icon | 200 | 0.112 | 0.689 | 0.416 | 0.668 | 0.406 |
| Closed regen notifications | 200 | 0.017 | 0.030 | 0.030 | 0.031 | 0.030 |
| Closed idle/no event | 200 | 0.005 | 0.005 | 0.004 | 0.005 | 0.004 |

There is **no consistent startup speedup**: some cold cases and unchanged
Settings timings vary upward. Do not advertise every row as faster. The strong
deterministic result is reduced redundant warm work, especially list selection;
the table retains the non-improvements. Native UI/data costs are left intact.

Per-action Retail host p95 for 40-row refresh falls from 2.112 to 1.439 ms;
median trial maximum falls from 3.346 to 2.371 ms. Gear selection's trial maximum
is effectively unchanged (5.499 -> 5.519 ms). These are CPU samples in the mock,
not rendered frames; no conclusion about actual game frame-time spikes follows.

## Confirmed bottlenecks and isolated steps

| Change | Evidence and final invariant |
| --- | --- |
| Classify colour only when required | Quality/class palette scans previously ran even for non-warm colours and equipment whose authoritative quality was known. Cheap eligibility checks now precede palette lookup. Gear refresh Quality calls drop 146 -> 78; skin calls 820 -> 752. Semantic colour checks remain when eligible. |
| Prepare selection role before native paint | Native CardRow:SetSelected paints border/fill, then the old skin post-hook painted them again. Updating only cosmetic role/state first lets existing setter hooks produce the final state in one pass. For 40 rows: paint calls 400 -> 200; skin calls 2,342 -> 1,400; batch colour readbacks 80,000 -> 40,000. Native arguments, receiver, nil-containing returns and optional status fill are preserved. |
| Reject data icons before ancestry work | Existing addon-local SetTex hook walked owners before recognizing data art. Non-decorative paths now invalidate old asset metadata and return before Object/Owned traversal; faded native decorations retain their earlier suppression fast path. Data-update skin calls 9 -> 2 and batch parent reads 1,000 -> 0. Native texture updates still happen. |
| Skip empty discovery batches; share Pack closure | Empty Flush calls allocated a pending table and checked cached layout repeatedly. Empty queues now return; manual refresh explicitly retains Layout and the existing look-change path still updates it. Return packing still preserves nils but no longer creates its helper closure each call. Reopen batch churn 106.930 -> 47.555 KiB; native actions remain unchanged. |

[Intermediate step counters](performance/oneforall/stages.json) record cumulative
colour, row, icon and allocation changes. Their exploratory timings are omitted;
the serial final measurements above are authoritative. No new cross-addon
cache/global hook, polling, timer or shared-helper change was introduced.

## Allocation, retention and lifetime

Retail churn per 200 reopen pairs falls 55.5%; 200 list refreshes fall from
45,938.930 to 44,420.117 KiB. Much of the latter comes from native/mock setters,
not the adapter. Native-only list churn is 33,482.367 KiB. Gear refresh churn is
unchanged at 19,426.220 KiB, including native UI updates and mock hook trampolines.
The rarity cache still performs 19 item-ID reads per native paint; it is not
weakened to improve the benchmark.

All repeated warm workloads retain at most about 0.5 KiB over a batch after full
collection (the measurement/counter tables create a small floor). There is no
observed warm growth in frames, hooks, discovery/font/skin geometry writes or
queued timers. The 256-row cold stress creates 7,424 **native mock objects** in
both native and skinned modes. Skin hooks fall 8,704 -> 8,448, retained host heap
86,658.262 -> 86,588.262 KiB; most of that heap is mock native object closures.
This does not imply 85 MiB of player memory usage.

Inspected nodes/fonts/colours/kept/flattened/windows/assets tables retain references
to owned native controls so themes and reopen can reuse them. OneForAll keeps
its main/lazy panels and row pools; WoW frames are not reclaimed like ordinary
Lua tables. Skin records scale with actual constructed controls, not reopen
count. The test does not establish long-session native pool/memory behaviour.
No speculative weak-table conversion or GC mode change is justified. Forced
full GC on the large host list heap costs about 128 ms before and after; this
is outside the timed operation and is **not** a measured WoW GC/frame pause.

## Discovery, events and background work

The adapter does not call H.Scan. Initial construction uses its existing bounded
owned walk and coalesced owner queue; nested constructors merge into completed
subtrees. Getter counts, child/region visits and hooks are retained in the JSON.
Warm reopen, navigation, Gear Planner, Settings/QoL and list-state workloads add
zero child/region reads, zero frames/hooks, zero font writes and zero timers.
Geometry writes match the native-only control: for example, 200 Gear refreshes
write 800 native anchors/sizes and 200 Settings batches write 16,000 native
switch-knob positions; the skin adds none. Real theme/font changes intentionally
update fonts/layout (612 font
writes and 30 geometry writes in this fixture); suppressing them would be a
regression. No callback is removed merely because it is rare or costly.

No adapter OnUpdate or recurring timer exists. Only PLAYER_REGEN_ENABLED is
registered directly, to recover deferred work; a no-pending notification returns
immediately. Construction may schedule one coalesced zero-delay helper batch.
Native Armory's delayed refresh remains native; the benchmark measures its Gear
Refresh body rather than pretending to simulate server/event timing. Closed
idle adds no skin callbacks. Closed icon **events** still pass through the one
existing addon-local SetTex hook, now without parent traversal. This is not an
assertion that all of OneForAll's optional gameplay features are idle.

## Native data costs kept separate

The separate index run loads actual external dungeon files/DungeonData, Armory,
ClassQuests and QuestRewards plus GearPlanner. It does not load the skin. Mock
item APIs deliberately classify every candidate as head armour, so the 3,191
entries measure realistic source-data volume, **not actual client filtering**.
Profession recipe sources/game caches are outside this separate subset.

Retail median: data/source load 14.220 ms; cold native index 9.938 ms,
6,221.452 KiB churn / 2,513.117 KiB retained; 10,000 cached lookups 0.615 ms with
no allocation churn. The index already has native first-use caching; the skin
does not rebuild it, and this audit adds no redundant cache or upstream change.
These costs are not included in the UI runner's empty-index timings.

## Validation and remaining limits

- Complete regression/package validation, plus separate runs against the supplied
  native UI sources with numeric textures and both client identities.
- New operation guards: a selected row reads its four retained edges/fill once,
  data icons do not walk ancestry, manual font/layout refresh works with an empty
  discovery queue, and native selection arguments/returns remain intact.
- Existing accepted rarity regression still covers initial valid -> delayed nil,
  all qualities/empty slots, item identity invalidation, selection/reopen,
  disabled/combat paths, plus semantic/status colours, native interactions,
  dynamic controls, theme/opacity and private menu ownership.
- The ordinary 60-file installation package contains no rarity diagnostics,
  profiling runtime, development TOC markers, special commands or benchmark data.
  Tests/scripts/benchmarks/docs stay outside the installed addon.

Actual in-game CPU, API C-call counts, rendering/texture loading, taint, frame
spikes, long-session native memory and real EUI primitive costs remain unmeasured.
Retail/Forever identities in mocks do not certify both actual clients. The
owner approved the pre-optimization visuals; these equivalent control-state
changes pass automated checks but still need a brief client review. Test first
open after /reload, wait for delayed rarity refresh, switch pages/selection,
Settings/QoL states, long lists, accents/fonts/opacity, reopening and closed idle.
No client performance improvement is claimed solely from this harness.

Evidence: [before](performance/oneforall/before.json),
[native-only](performance/oneforall/native.json),
[after](performance/oneforall/after.json),
[native index](performance/oneforall/native-index.json).
