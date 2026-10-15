# Callback refresh audit

Version `1.4.0-alpha.6`, branch `acegui-audit-alpha`, based on accepted single-folder alpha.5 (`bfe608c`). Other skin branches remain separate. No release tag, GitHub Release, CurseForge or Wago publication is created.

## Findings and changes

AceGUI itself is not the underlying defect: expensive integration-wide work in repeated post-hooks turns normal construction/data refreshes into scan bursts. The PallyPower issue established that pattern; this audit reviews the 20 stable skins in the single-folder build, not the separate PallyPower branch.

| Integration | Finding | Severity | Change |
| --- | --- | --- | --- |
| Details | Designer RefreshDisabledOptions post-hook refreshed every options/meter root after a disabled-state-only update. Upstream DF runs this to re-evaluate option state. | Medium; redundant scans confirmed in mocks, in-game stalls unmeasured | Coalesce updates and scan only the editor. Recheck menu enablement when queued work executes. EditObject and completed section changes remain immediate. |
| ThreatClassic2 | AceConfigDialog FeedGroup post-hooks refreshed all options roots; window resize also refreshed those roots. | Medium | Coalesce FeedGroup by its owned container. Resize bursts repaint the meter once without scanning options. Open remains immediate; no native functions are replaced. |
| DBM | Each CreateNewPanel/CreateBossModPanel/CreateDropdown callback refreshed the whole GUI while panels were being constructed. | Medium | Coalesce construction callbacks. ShowTab/DisplayFrame/menu completion and final tab selection remain immediate. |
| Gargul | Navigation table Refresh/SetSelection/SetData scanned every discovered window and scope. | Medium | Immediately scan only the navigation subtree. Completed open/draw/section behavior remains synchronous. |

Scoped.lua now exposes guarded local control refreshes, with shared queued requests and no per-request callback allocation. These reuse the existing scanner, style guards and combat recovery. The code does not change target values, native callbacks, frame geometry or appearance settings.

## Measured mock comparison

The same source-shaped fixtures and 100-callback bursts ran against alpha.5's original four skins/Scoped.lua and the updated implementation. Counts measure H.Scan entry calls by root, not recursively visited frames, CPU time, memory or FPS.

| Burst, 100 callbacks | Before | After |
| --- | --- | --- |
| DBM panel constructors | 100 full GUI scans | 1 full GUI scan |
| Details disabled-option refreshes | 100 full options scans | 1 editor subtree scan |
| ThreatClassic2 Ace group feeds | 100 full options scans | 1 container subtree scan |
| ThreatClassic2 window resize | 100 options scans and 100 meter passes | 0 options scans and 1 meter pass |
| Gargul navigation refreshes | 100 full-window scans | 100 small navigation-only scans, retaining immediate feedback |

Raw results are in `acegui-callback-results.json`. Reproduce with:

```sh
python3 scripts/benchmark_callbacks.py --baseline /path/to/alpha.5/checkout
```

The benchmark uses the current regression fixtures for both runs and replaces only Scoped.lua and the four skin files for the baseline. Baseline mode skips only new performance-count assertions. All native-action, state, theme, dynamic-widget, combat and other regression assertions still run. The report does not establish that each integration caused visible stuttering in a live client, or guarantee a particular FPS gain.

## Review of remaining skins

| Skin | Callback assessment; no change made |
| --- | --- |
| Forever Companion | Bespoke refresh queue coalesces frame/constructor bursts; no polling loop. |
| Forever Dungeon Journal | Refresh hooks queue full work; tab/redraw primitives are local. The supplied questRefreshWorker OnUpdate is one-shot and hides itself after rendering. |
| RestedXP Guides | Layout/guide/theme/target updates use the existing module queue. |
| Auctionator | Constructor/discovery/tab/dialog updates queue refreshes; item border updates are local. |
| Spy | Ace FeedGroup remembers owned options and queues one module refresh. Combat defers full work. |
| What's Training? | Refresh callbacks queue work; protected/dynamic controls remain guarded. |
| ItemRack | Options/inventory/queue-control callbacks already coalesce; secure controls excluded. |
| KiwiFarm | Menu ownership and post-combat updates queue refreshes. |
| Myslot | No frequent target setter hooks; public window discovery and shared queued scans. |
| BugSack | Native tab/open/options callbacks queue work in this stable skin. The newer BugSack alpha stays separate. |
| Altoholic | Existing target callbacks queue refreshes; this build does not include the separate development branch's navigation fixes. |
| Attune | Node/tree construction callbacks queue work; graph canvas is excluded. |
| TwitchEmotes | Owner-scoped menu binding, no recursive window scanning on chat emotes. |
| Questie | FeedGroup queues refreshes; tracker row/header updates use local, coroutine-preserving styling. |
| AtlasLootClassic Continued | FeedGroup and bulk GUI updates queue; popup-local styling remains immediate to avoid menu flashes. |
| GTFO | Option rendering/refresh callbacks queue; alert gameplay paths are not scanned. |

Shared H.Queue combines requests, H.Scan guards styling/hook installation and scopes scroll refreshes, and shared Ace checkbox SetType/SetDisabled handlers queue work. Immediate completed user actions are intentional and are not blanket-deferred. Remaining nested draw/open callbacks are left intact where a safe simplification is not established. Continuous live event rates and actual in-game costs remain unmeasured.

## Verification and distribution

`python3 scripts/package.py` runs 15 suites and validates Lua syntax, client TOCs, version consistency and the single-folder install ZIP. New assertions cover scan counts, native returns/actions, newly added controls/labels, disabled menu settings, combat recovery, resize coalescing and unchanged immediate tab styling. All pass.

The archive contains one `EUIAddonSkins` folder, 34 runtime files and the MIT license; benchmark tools, tests and reports remain outside the player ZIP. No in-game verification is claimed and no manual profiling is required to use the automated findings.

Sources reviewed include the supplied AceConfigDialog FeedGroup implementation and Forever Dungeon Journal renderer, plus [Details Framework editor.lua](https://github.com/Tercioo/Details-Damage-Meter/blob/master/Libs/DF/editor.lua). Integration-specific findings otherwise describe our own hooks and fixtures.

## Combined 1.3.0 build

These audit changes are also included in the untagged 1.3.0 preparation branch alongside PallyPower, Altoholic and BugSack updates. The combined build runs 16 suites. For repeatable baseline comparisons, the benchmark retains the independent PallyPower borderless-button parameter in both runs; callback/scanning paths use the original baseline implementation. See [integration notes](RELEASE_1.3.0.md).
