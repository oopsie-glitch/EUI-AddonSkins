# OneForAll live border trace (temporary development build)

PR #68 remains unresolved: the user reproduced disappearing first-open borders
at `76a3297`. This build adds instrumentation, **not another styling fix**.
The exact in-game overwriting callback is not yet confirmed.

## Install and reproduce

1. Exit WoW. Replace the existing `Interface/AddOns/EUIAddonSkins` folder with
   the `EUIAddonSkins` folder from the **diagnostic ZIP**. Keep OneForAll and EUI
   installed and enabled. This build intentionally retains release version
   1.6.2; the exported trace identifies its development commit separately.
2. Log in, then `/reload`. Before opening OneForAll, enter
   `/euiskins ofatrace start`. Start outside combat. This resets any previous
   capture and arms observation before the lazy Gear Planner factory runs.
3. Open OneForAll > Armory > Gear Planner normally. Do not click equipment.
   Wait until the borders disappear/stabilize (about a second lets the existing
   native 0.4-second delayed redraw run). Enter `/euiskins ofatrace before`.
   It should report **19 slots**. Take a screenshot if helpful.
4. Click one equipment item once. Enter `/euiskins ofatrace after`. This saves
   the corrected state, without refreshing or repainting it. Optionally take
   the matching screenshot.
5. Close and reopen OneForAll normally. Enter `/euiskins ofatrace snapshot`
   to include reopening in the same capture. Avoid unrelated page browsing or
   theme changes during this first capture.
6. Enter `/euiskins ofatrace export` (or `compare`). Recording stops and a
   copyable window opens. Click inside its text, press **Ctrl+A**, **Ctrl+C**,
   paste into a plain-text file named `OneForAll-border-trace.txt`, and attach
   that file to the conversation. The export includes both full snapshots and
   an automatic `COMPARE before -> after` section. **Escape** closes the window.
   Do not `/reload` before copying: logs are intentionally not saved to WTF.

If it reports zero slots, do not force a refresh or click to initialize them.
Export that capture and report whether OneForAll was already open before
`start`, whether its EUI skin is enabled, and the installed OneForAll version.

For a second capture of equipment changes, export the first log first, then
`start` again while the planner exists, change equipment normally, use `before`
and `after` around the change, and export separately. Starting again clears the
old log. `stop` freezes a log without opening its export. `status` prints the
capture status, slot count, event count and dropped-event count.

## What is observed

- Native Card creation and completed Gear Planner construction, before Armory's
  initial `gear:Show()` / `gear:Refresh()` calls.
- `paintSlots`, `Refresh`, ancestor OnShow/OnHide, physical slot mouse-down and
  post-click phases. Existing delayed native redraws call `Refresh`; their
  actual caller stacks are captured without replacing the native timer or
  adding a diagnostic timer.
- All nine existing border pieces, retained native fill and item icon, plus
  the finite slot ancestry. No UIParent or repeated subtree scan is performed.
- Changed setter arguments and readback: shown/visible flags, local alpha,
  product of parent alphas, effective alpha when exported by the client,
  draw layer/sublayer, texture/file path, vertex RGBA, quality/expected RGB,
  size/anchors/UVs, blend/desaturation, parent levels/strata and caller stacks.
  Parent draw-layer enable/disable calls are also recorded.
- Changed solid-colour setter arguments are retained even if public texture
  readback stays identical. The client does not consistently expose a getter
  for the base colour of a solid-colour texture; snapshots cannot reconstruct
  writes made before capture started. A stack identifies a setter caller,
  not necessarily the root cause by itself. Capturing before first opening
  and comparing with the later slot repaint supplies the missing context.

Events are capped at **1,024**, stacks at 1,100 characters each, manual/phase
snapshots at **12**. Repeated automatic phases reserve room for manual
before/after snapshots. An overflow increments `dropped`; final manual snapshots
still work. If overflow occurs, send that log first rather than changing the
reproduction. There is no polling, OnUpdate, full scan, forced input, quality
lookup/request, visual repair, native callback replacement or SavedVariables
logging. Recording uses memory and getter/post-hook work while explicitly
enabled, so this build is not a performance benchmark.

Only known constructor references are retained while disabled; no setter
observers, UI objects, timers or hierarchy walks are installed then. Observer
hooks installed by `start` remain until `/reload` but return immediately when
stopped, without reading states. The export window is created only on request,
outside combat. Logs omit character names, item links/IDs, chat and inventory
data; stacks can include other addon names and source paths. Review before
sharing publicly. `/reload` disables capture again.

## Development/package isolation

`diagnostics/OneForAllTrace.lua` is excluded by `.pkgmeta` and is absent from
all tracked runtime manifests and ordinary installation ZIPs. The adapter has
two optional observer entry points; without the diagnostic namespace they
perform no action. `scripts/package_oneforall_trace.py` derives a separate ZIP
from the already validated ordinary package, inserts the trace after Core in
each client TOC and marks those TOCs `X-EUI-Development`. It does not edit tracked
TOCs, versions or styling. Remove both observer entry points and this temporary
diagnostic code when the targeted fix is ready.

Build from a clean development commit:

```sh
python3 scripts/package.py
python3 scripts/package_oneforall_trace.py --output /absolute/path/EUIAddonSkins-OneForAll-diagnostic.zip
```

## Source evidence and verification limits

Inspected supplied OneForAll 6.0.1 (source/hash in [test notes](ONEFORALL_TEST.md)):
slot selection only invokes `paintSlots()` and `refreshList()` using existing
slot quality. Native `refreshSlots()` loads inventory quality and then paints.
Armory shows/refreshes the planner and coalesces item-info, bag, equipment and
faction events into a native delayed redraw. The original standalone fixture
did not model that owning Armory lifecycle or client rendering accurately.
These are confirmed source paths, **not a confirmed cause of the live failure**.

`tests/oneforall_trace_spec.lua` injects texture, solid-colour, layer, alpha and
visibility changes; verifies incoming arguments/stacks, before/after export,
caps, native writes/returns, duplicate-hook prevention, stopped getter silence
and absence of timers. Optional source runs of `tests/oneforall_spec.lua` with
`ONEFORALL_TRACE=diagnostics/OneForAllTrace.lua` additionally bind all 19 slots
through the real supplied Gear Planner constructors under Retail/Forever mock
identities. These validate instrumentation only. Live captures are pending;
neither mocks nor the diagnostic ZIP establish a rarity-border fix.
