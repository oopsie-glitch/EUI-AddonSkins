# Skin performance review — 21 October 2026

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Review the active unpublished skins before further visual work. Keep independent task branches; do not merge or tag them as part of this review.

## Scope and validation

- The 22 stable skins already have collection/callback audits in `PERFORMANCE_AUDIT.md` and `ACEGUI_AUDIT.md`, with subsequent integration-specific checks. Re-ran the complete stable package validation at `961ff417d1c1d86217bb8fc10faf83ba1e8618e5`; no stable runtime changes made.
- Reviewed the six latest alpha adapters without a separate dedicated follow-up: SimulationCraft, RCLootCouncil, HekiLight, Scrap, Quest Completist and World Quests List. Checked callback frequency, scans, lazy controls, pools, font/texture reuse, combat/toggle recovery and target gating.
- Re-ran `python3 scripts/package.py` on all 11 active alpha candidates as well as the stable baseline. Every checkout passed Lua syntax, its full regression suite, manifests, exact MIT license and one-folder ZIP checks. The alphas each contain 40 runtime files and 23 deferred factories; the stable baseline contains 39 files and 22 factories.
- Waypoint UI and World Quest Tracker are paused and excluded. World Quest Tab is skipped because it has native integration; the superseded Hekili adapter is excluded in favour of HekiLight. Reserved branches without implementations have no runtime to audit.

## Active alpha results

These are source-shaped mock workloads. Counts do not establish in-game FPS, CPU time, retained memory or taint safety.

| Skin / task branch | Result |
| --- | --- |
| AllTheThings — `skin/allthethings-initial` | Previous dedicated audit retained; full suite passes. Visible-row budget and local settings/auction-tab callbacks remain in place. |
| Guild Roster Manager — `skin/guild-roster-manager` | Previous dedicated audit retained; full suite passes. Warm tab/settings state repair avoids whole-window scanning. |
| Premade Groups Filter — `skin/premadegroupsfilter-initial` | Previous dedicated audit retained; full suite passes. Owned panels and recycled controls only; no search-result processing hook. |
| Pawn — `skin/pawn-initial` | Previous dedicated audit retained; full suite passes. Current native rows only, with historical hidden rows excluded. No scoring/bag/tooltip-parsing hooks. |
| RareScanner — `skin/rarescanner-initial` | Previous dedicated audit retained; full suite passes. Owned options/media pools restore on reuse; no scanning-engine or polling hooks. |
| SimulationCraft — `skin/simulationcraft-initial` | No new change justified. 1,000 mock warm export/show cycles create no UI objects/hooks and cause no font writes or checkbox repaint. The skin observes completed window construction, never profile/export generation. |
| RCLootCouncil — `skin/rclootcouncil-initial` | Fixed redundant entry/table traversal and late table-hook binding. See measurements below. Preserve native voting/response/timer actions and shared pool restoration. |
| HekiLight — `skin/hekilight-initial` | No new change justified. 1,000 native suggestion updates trigger no skin hierarchy reads or UI objects; 100 warm settings interactions add no hierarchy reads/hooks. Native suggestion polling is unchanged. |
| Scrap — `skin/scrap-initial` | No new change justified. Verified exact alpha.3 head `bfaabca0ef558588f7b6e70a8e577eeec60a86a7`. 1,000 bag/list updates add no hierarchy reads/font writes; options, tutorials and alternating pooled menu backgrounds retain bounded art/hooks and native restoration. |
| Quest Completist — `skin/questcompletist-initial` | No new change justified. 1,000 list/scroll/window/options cycles add no UI objects/hooks/font writes/hierarchy reads. Only 16 fixed display rows are inspected; no quest-database traversal. |
| World Quests List — `skin/world-quests-list-initial` | Limit popup repainting to the native current-row budget rather than its largest historical menu pool. Native table refreshes still inspect only newly appended rows; 300 warm updates add no hierarchy walks/UI objects/font writes. |

## Implemented fixes

### RCLootCouncil

Updated commit: `17bf210d27c266c726e1d9a306d01f7e26b877b1` (draft PR #30).

- Cached `EntryManager:GetEntry(item)` returned an existing native entry but forced a recursive skin pass. Use the existing node cache for unchanged items; recycled entries with a different item still force one completed repaint. Newly introduced controls remain supported.
- `UpdateSt` rebuilt the voting table but scanned the whole content tree. Style the current table, mark replaced tables as retired and omit those hidden trees during later discovery/theme passes.
- Native `UI:Embed` can run before the target assigns `UpdateSt`. Retry binding at completed window discovery; the shared hook guard prevents duplicate hooks.
- Snapshot new pooled widgets once instead of immediately taking the same snapshot twice. Later passes still capture new native regions and retain release restoration.

| Identical mock workload | Alpha.3 baseline | Updated |
| --- | ---: | ---: |
| 300 cached entry lookups: child-list reads | 600 | 0 |
| 20 voting-table rebuilds: reads of the immediately retired table | 19 | 0 |

Reproduce from the RCLootCouncil task branch using `python3 benchmarks/run_rc.py --baseline` and `python3 benchmarks/run_rc.py`. The baseline runner loads the exact alpha.3 adapter (`8df070b33ce0c0a93a37facf8a6f75cecccea952`) against the same fixture. It skips only the newly added performance expectations; existing functional tests still run.

Additional regression coverage checks recycled items, new controls, late method binding, preserved multi-value returns, retired-table theme exclusion and the existing combat/toggle/pool lifecycles. These fixes reduce unnecessary UI work; no numerical FPS or gameplay CPU improvement is claimed.

### World Quests List

Updated commit: `84da4123d8c753f60b41dc520c2613fda83d921a` (draft PR #41).

ELib stores every row up to the largest menu opened. Native code sets `LinesNow` before Show and uses it during Reload. Use that same budget for skinning. A new regression opens 12 rows, reopens at 2 without touching the other 10, then confirms they are styled when reacquired. No callbacks, menu data, actions or geometry change.

## Retained boundaries

- Fresh window/page construction, native pool reacquisition, language/theme changes and explicit refresh can legitimately require discovery or snapshots. No blanket child-count cache replaces those native lifecycle points.
- Spy, Attune, AtlasLoot and What's Training retain conservative scoped refreshes documented in the earlier audits. Spy's data updates can still queue recursive scans of unprotected UI. No new optimisation was justified here without a current source-shaped model of all of those dynamic paths. This is a retained concern, not a claim of zero cost or an unreported regression.
- WoW frames and native pools can grow as the target addon creates new UI. Skin caches reuse those objects; the mocks do not reproduce long gameplay sessions or establish retained-heap growth.
- No shared Lua helper, saved variable schema, addon behaviour, main branch, release tag or publishing workflow was changed. Both fixes stay on their respective task branches. No CurseForge or Wago publication occurred.
