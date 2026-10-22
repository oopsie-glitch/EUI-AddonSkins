# Guild Roster Manager alpha

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Branch: `skin/guild-roster-manager`, based on stable 1.5.2. Untagged; no CurseForge or Wago publication. The ZIP filename identifies this alpha; runtime version and release changelog stay at the stable base until release preparation.

## Scope

- Log, options, member details, roster, dialogs, export and macro-tool windows discovered through GRM's UI registry and construction helpers.
- Soft panels with a lighter centre on top-level windows, native-size themed fonts, accent-selected tabs and flat checkboxes.
- Legacy scrollbars, slider thumbs, navigation arrows, inputs, buttons and pooled dropdown menus.
- Native guild actions, drag/resize behaviour, checkbox and radio values, scroll ranges, export data and semantic text colours remain controlled by GRM.

## Lifecycle and performance

The adapter activates only when Guild_Roster_Manager is loaded and its skin is enabled. It observes GRM-owned construction helpers and completed UI phases, including lazy roster/export loading. Hooks run after native functions and preserve their results. No global frame factory replacement, guild-data scan, polling, OnUpdate or scroll-triggered full-window scan is added.

Warm OnShow discovery uses cached child counts. Factory bursts coalesce a completed-component pass; dropdown rebuilds style their own menu. Font resets are repaired locally. Combat defers styling until PLAYER_REGEN_ENABLED; protected frames and tooltips are excluded.

The mocked regression exercises native button/radio/dropdown actions, legacy scroll behaviour, lazy windows, initial tab selection, font resets, theme/accent changes, disabled skins and combat deferral. In this fixture, 100 pooled menu rebuilds add no UI objects or hooks, and 100 warm root shows cause no child traversal or font rewrites. These are simulation results, not in-game CPU or FPS measurements.

## Source review and limitations

Integration points were inspected in TheGeneticsGuy/Guild-Roster-Manager, Retail commit `79be399c35424a48456361c374bc591b68c88dd2` (GRM 1.99423). GRM and EllesmereUI are installed separately.

The full project syntax/regression/package checks pass. No WoW client is available here: appearance, live guild permissions, client-specific templates and taint behaviour have not been verified in-game. Older GRM versions use feature detection; their visual coverage is not established by the Retail source review.

## Visual refinement (alpha.2)

The centre highlight is subdued for a matte appearance. Template artwork inside main-tab child frames, unnamed BasicFrame close buttons and the Display Changes side-panel border are stripped before applying the public skin primitives. Native controls retain their geometry and callbacks. Main-tab selection follows GRM's page Show calls, without hooking its repeating fade timers.

Checkboxes have a consistent 14-unit visual box while their native hit rectangles stay intact; tiny native radio controls remain smaller. MinimalSliderWithSteppers wrappers receive left/right arrows around the actual slider, with native click handlers preserved. Stock gold/yellow labels become soft white and GRM's dark-red missing-data colour becomes a brighter red. Class colours, disabled greys and the log's coloured event legend remain native. Changes to text colours are repaired locally without scanning the interface.

Additional mocked fixtures cover nested template artwork, anonymous close buttons, side panels without a backdrop API, wrapped slider arrows, main-page selection, checkbox resizing, live status-colour resets and preserved class/legend colours. Full package/regression checks pass; no in-game visual verification is claimed.

## Performance review (alpha.3)

Two avoidable paths were reduced without changing appearance:

- Removed the full-window callback on `BuildLogFrames`. In GRM 1.99423 this refreshes settings, permissions and existing text/control values. Local setters and construction hooks already maintain those visuals, including newly created controls. Genuine construction, language and theme refreshes retain their completed discovery passes.
- Text colours that do not need remapping now return before inspecting parents. Class colours, good/unknown states and disabled greys keep their native values. The legend exclusion still applies when a colour actually needs examination.

Reproduce the source-shaped benchmark with `python3 benchmarks/run_grm.py --baseline` and `python3 benchmarks/run_grm.py`. The baseline is alpha.2 commit `8973f28e39cde681cf9ccce438a314096673c2bc`. Each workload uses seven trials; these are median host-Lua times, not WoW timings.

| Simulated workload | Alpha.2 | Alpha.3 |
| --- | ---: | ---: |
| 100 settings refreshes, with 500 extra audit labels present | 104.590 ms | 0.411 ms |
| 100 batches updating 500 class/good-state colours | 69.077 ms | 43.776 ms |
| 2,000 warm main-tab switches | 4.684 ms | 5.139 ms |

The small tab-time difference is host timing variation; that runtime path is unchanged. Warm window shows and tab switches perform zero child/region traversals, font rewrites or new UI object/hook creation. The 100 simulated settings refreshes previously read 1,900 child lists and 14,600 region lists; they now read zero. Fifty thousand unmodified colour updates previously inspected 250,000 parents; they now inspect zero. Native font resets are still repaired, and a real pooled dropdown font reset still causes the required local font write.

The settings-refresh trial's GC-stopped temporary Lua growth fell from 3,533.410 KiB to 48.625 KiB. These figures include mock hook argument/return tables and other simplified test APIs; they do not measure retained addon memory or WoW allocations. All warm workloads create zero new UI objects or hooks. Tests also cover dynamically constructed controls during a native settings refresh, class/legend/status colours, themes, disabled skins and combat deferral.

Static review found no added polling, OnUpdate, per-frame scan, scroll-triggered full refresh or guild-data traversal. Caches and hook guards reuse existing UI objects. Full discovery remains intentional during initial construction and explicit theme/language rebuilds. Real-client first-open latency, FPS and protected-action behaviour cannot be measured here.
