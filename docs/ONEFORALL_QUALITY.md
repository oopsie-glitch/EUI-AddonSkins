# Gear Planner quality state: live evidence and targeted fix

PR #68 remains draft. No release metadata, shared helpers, layouts or border
textures/layers change in this iteration.

## Confirmed failure sequence

The user's `98f3dc3` trace identifies OneForAll `6.0.1-retail.1`, Retail
`12.1.5` build `70688`. Discovery found all 19 slots (53 candidate frames),
with a valid before/after comparison and 144 changed entries. Its event log
hit the 1,024-event cap and dropped 842 later events; full manual snapshots
remain available. The raw user log is not committed.

- Initial `GearPlanner.paintSlots` / `Refresh` snapshots already have quality
  2 on equipped armour/accessories and quality 6 on weapons. This is **not**
  a complete absence of initial item data.
- At 8258.619, the delayed native refresh through `Armory.lua:852` paints with
  `q=nil`. Event 688 shows slot 1's EUI border paint responding to missing
  quality; the following native paints use neutral/decorative colours.
  Phase events 888/889 identify the same delayed paint/Refresh callback.
- The manual `before` snapshot has nil quality on every slot, including
  previously identified equipment. Retained border textures are shown and
  visible, with alpha 1, parent alpha 1 and `OVERLAY,1`; the changed retained
  edges primarily need correct colour, not another visibility/layer repair.
- Mouse-down on slot 7 is recorded at 8265.504. Selection painting at
  8265.547 still sees nil quality (e.g. events 891/1022). The later `after`
  snapshot has quality populated again. The cap prevents attributing every
  recovery write to its final callback.

The supplied `UI/GearPlanner.lua` explains the state loss. `refreshSlots`
unconditionally assigns `b.q = GetInventoryItemQuality("player", b.slot)`
(line 616), then calls `f.paintSlots()` (634). A later nil result erases an
earlier valid quality. `paintSlots` chooses decorative selected gold, quality
colour or neutral chrome using that field (590–599). `Refresh` and OnShow
invoke `refreshSlots` (1103–1108). Armory's coalesced item-info/bag/equipment/
faction events call Refresh after their native delay (848–863).

The slot click handler (530–537) changes selection, clears search and repaints;
it **does not load quality metadata**. Therefore the log does not establish
that the click itself populated quality. It records a valid -> nil -> valid
sequence, with nil still present during the click. No gear-index/list-provider
write to slot quality exists in the supplied source; only refreshSlots assigns
it. The exact client-side reason the inventory-quality provider temporarily
returns nil is not established; that does not justify inventing another API
source or assuming all later nil results mean an item was removed.

## Fix

On completed `CreateGearPlanner`, bind the source's fixed character-panel
equipment buttons once, before Armory's first Show/Refresh. Retain the original
`paintSlots` function and its direct arguments/return path. Immediately before
each native paint:

1. Read the current equipped item ID for each bound slot.
2. If identity changed or became nil, invalidate the previous saved quality.
3. For an equipped item, remember a non-nil native quality (including Poor/0).
4. If native quality is temporarily nil, restore a saved quality **only for
   that same equipped item**, then let native paint run normally.

This captures the initial valid values seen in the live trace and prevents the
later nil refresh from discarding them. Replacing/removing/re-equipping an item
cannot reuse the previous item's cache. New valid native quality remains
authoritative, including a later change for the same item ID. No persistent
cache, item-data request, native Refresh invocation, artificial click, timer,
poll, repeated traversal, forced repaint or extra decorative layer is added.
Enabled/combat guards bypass the repair when the skin cannot act.

The existing EUI border-colour implementation remains unchanged. Native
selection, enchant selection, hover, tooltips, empty artwork, map/list data and
all visual improvements remain native or use their existing skin paths.

If quality has **never** been available for an item, or item identity itself is
unavailable, the adapter does not guess a rarity or borrow another item's
quality. Normal target refreshes may populate it later. This is distinct from
the supplied trace, which shows valid quality before the destructive refresh.

## Validation and limits

`tests/oneforall_spec.lua` now drives the supplied native data/paint lifecycle
with inventory provider results under test control. An unbound native planner
first receives valid quality, loses it on a later Refresh, remains nil through
selection, and recovers on the next Refresh when the provider becomes ready.
The bound planner retains correct metadata and all four existing quality edges
through the same delayed-nil refresh **before any click**. Tests cover all
quality levels, empty slots, identity replacement/removal/re-equipping, a newly
learned quality, selection/reopen, disabled/combat bypass and existing theme,
opacity and interaction checks.

Separate runs load actual supplied Widgets/MainFrame/Settings/QoL/GearPlanner
source (source ZIP hash and public EUI API revision in
[test notes](ONEFORALL_TEST.md)), under Retail and Forever mock identities.
No target code/assets are redistributed. The ordinary complete packaging suite
validates the production candidate and excludes all temporary diagnostic code.
Removing the completed-factory quality binding in a negative-control run of
the actual-source workload fails at "delayed refresh lost quality before
selection"; the fixed workload passes that same assertion.

Simulated 100 native paints add 1,900 item-ID reads (19 per paint), zero
hierarchy reads and zero UI objects/hooks. Existing warm-window/closed-update
checks still pass. These are operation counts, not in-game timing/FPS claims.

Temporary trace runtime, observer entry point, command wrapper, special builder,
instrumentation-only tests and capture instructions have been removed. Replace
the installed diagnostic folder with the new ordinary test ZIP, then /reload.
Verify first opening without clicking, waiting beyond the native delayed
refresh, switching selection, reopening and equipment changes. The live trace
confirms the failure path; actual rendering with this fix still needs in-game
acceptance. No claim of completed client verification is based on mocks.
