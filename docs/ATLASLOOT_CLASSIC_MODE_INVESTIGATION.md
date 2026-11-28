# AtlasLootContinued: Classic-only EUI styling

## Source and scope

Target: AtlasLootClassic Continued (All Forever Loot), version **13014**.
[Supplied archive](https://github.com/user-attachments/files/35548736/AtlasLootContinued-Forever_13014.zip):
`AtlasLootContinued-Forever_13014.zip`.

SHA-256: `f3a7ffc65480a92c7b18961409087d9b2f83b1bf9d942fcd230b3cc28d479a1d`.

GitHub Actions verifies this checksum, ZIP integrity and the core Camelot TOC's
13014 version before testing. Target source and assets are downloaded only into
the hosted test process; none is bundled with EUI AddonSkins.

Baseline: published v1.6.8 / main
`0e388c8fc9fd635d5ec50d2a78d83a843005b7fd`.
Only the existing AtlasLootContinued target is supported. AtlasLootClassic /
the separate AtlasLoot Forever variant is not added. PR #69 remains excluded
and unchanged.

## Confirmed cause and actual mode lifecycle

The released adapter styles any AtlasLoot.GUI table. Continued 13014 builds
the Classic controls for every look, then adds navigation presentation over
those same controls. Unconditional font/backdrop scans therefore interfere
with Forever Bronze and Atlas Nav.

Relevant archive paths:
- GUI/GUI.lua:1314-1666 constructs the Classic controls, then applies Nav.
- GUI/Nav.lua: Swap marks Nav.active true; Revert:2311-2402 sets it false and
  restores Classic. Native GUI refreshes also use GUI.Nav.active to select
  their rendering path.
- GUI/Nav.lua:2407-2458 GetStyle/GetLook read the saved choice. SetStyle/SetLook
  save immediately and prompt for reload; they do not change the drawn UI.
- The reload dialogs at Nav.lua:2531-2580 call ReloadUI on acceptance. Cancel
  only dismisses the prompt, retaining the pending preference and current UI.
- Favourites_Nav.lua exposes GUI.NavStyle.applied for the separate Favourites
  window. Its first construction can follow a pending choice independently.
- Options/Nav settings have their own frame. Only an actual AceConfig Classic
  frame is a candidate owned root; navigation settings are not scanned.

The correction uses a constructed GUI.frame and the runtime GUI.Nav.active
flag, never GetStyle/GetLook or saved GUI.style. A constructed non-navigation
window is Classic, including native fallback after Nav fails. Older
Classic-only builds without Nav retain their original treatment.

## Implementation and ownership

AtlasLoot's Classic visitor and its approved colors, opacity, borders, fonts,
artwork and geometry are unchanged.

Scoped.lua gains opt-in active and setup callbacks:
- active provides a helper-local module/facade gate, leaving the registered
  module, its saved toggle and every other integration unchanged.
- The gate is checked both when queueing and when executing deferred jobs,
  hooks, scripts, scans and accent callbacks.
- setup binds only completed GUI.Create and Nav.Revert observers while the
  render mode is not yet eligible. Other GUI/font/item hooks install only
  once actual Classic UI is available.
- The registered module retains its normal refresh callback.
- Navigation-styled Favourites roots and callbacks are also excluded.

All 49 skin adapters were inspected; none already uses these option names.
Other Scoped callers follow the existing path without a predicate/proxy.
Full regression coverage includes existing shared helper/menu users.

There is no polling, recurring timer, OnUpdate hook, global factory replacement,
settings migration or native render/action call. One existing constructor hook
is reused and one scoped fallback observer is added. Nav-mode refresh methods
remain unhooked. EUI theme events and explicit refresh requests are inert
while navigation is displayed.

A real Classic-to-navigation selection takes effect only on reload, which
destroys the previous Lua/UI objects. Consequently no cross-mode restoration
ledger or rewriting of native artwork is needed. Cancelling a reload while
Classic remains displayed deliberately retains Classic EUI styling. A pending
Classic preference while navigation remains displayed cannot activate EUI.
The supported in-session transition is navigation failure back to Classic;
the completed native Revert is observed before applying EUI.

## Automated evidence

The released adapter fails the new regression at
“AtlasLoot navigation mode was styled”; the candidate passes.

Coverage includes fresh sessions for all three looks, pending/cancelled
selections, reload-session reconstruction, nil-containing native return
values, delayed main construction, native fallback, separate navigation
Favourites, stale queues and installed hooks, theme callbacks, combat recovery,
and 1,000 navigation refresh cycles without GUI scans, new queues or growing
hooks/events. Existing Classic appearance/action assertions remain intact.

The cloud source runner compiles the exact 13014 GetStyle, SetStyle, GetLook,
SetLook, Revert and reload-dialog definitions into an isolated fixture.
Construction/layout and other WoW services are mocked; this is not a full
client boot or a pixel/taint proof.

The complete registered 59-suite Lua regression/package validation checks all
runtime files, catalogs, TOCs, unchanged version, license and installation
layout. The transferred test artifact is independently compared byte-for-byte
against its exact checkout (82 runtime files; no upstream/development files).

## Hosted performance

Five fresh-state trials per version, Ubuntu 24.04 Actions runner, system Lua
5.4, identical source-shaped Classic window, one warmup, GC before/after the
measured batch. Medians from the first validated corrective build:

| 1,000 warm Classic reopen/refresh cycles | v1.6.8 | Candidate |
| --- | ---: | ---: |
| Host elapsed time | 39.308 ms | 41.886 ms |
| Main-root scans | 1,000 | 1,000 |
| Tracked item-label font writes | 1,000 | 1,000 |
| Added root regions | 0 | 0 |
| Positive retained heap growth after GC | 0 KiB | 0 KiB |

The ownership check has a small hosted cost; it does not optimize or redesign
the existing Classic refresh. Negative raw GC deltas are collection noise,
not claimed savings. Navigation workloads add no cosmetic queue/scans after
initial observer installation. No live WoW FPS, frametime, long-session memory
or native hook-overhead claim follows from these fixtures.

## In-game acceptance

1. Start in Classic: verify the previously approved main/favourites/options,
   dropdowns, item colors, fonts, backgrounds and accent.
2. Choose Forever Bronze, cancel reload: the displayed Classic UI stays styled.
   Accept reload later: Bronze remains fully native.
3. While Bronze is displayed, choose Classic and cancel: navigation stays native.
4. Reload into Atlas Nav; navigate, open menus/favourites/settings and change
   EUI theme/accent. Check for native background and steady fonts.
5. Reload back into Classic and verify EUI reapplies without duplicate art.
6. Check combat/recovery, ordinary open/close and existing SavedVariables.
   If native navigation fallback occurs, its Classic result should receive EUI.

Live visual, native rendering and taint acceptance remain pending. Keep PR #104
draft; do not merge, tag, version-bump or publish.
