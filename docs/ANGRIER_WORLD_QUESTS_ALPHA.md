# Angrier World Quests alpha

Branch: `skin/angrier-world-quests-initial` (untagged; no platform upload).

Alpha 2 uses smaller settings-checkbox artwork without changing hit areas, and recognises modern dropdowns reported as Buttons. It also styles AWQ quest-row checkboxes with compact dark squares and an accent-coloured checked indicator. The original alpha 1 ZIP remains available for comparison. Styles the Retail quest-log trophy tab, the addon settings canvas and its AceDB Profiles controls. Reward/status colours, data providers, map pins and quest processing are untouched. Native action scripts, hit areas, layout and settings remain owned by Angrier World Quests.

Quest checkboxes are discovered only through the AWQ header’s active frame pool after completed list rebuilds. The tracking mark follows native Show/Hide state; tracking actions and hit areas are unchanged. Prepared rows reuse their artwork and hooks.

The tab is located by the QuestFrameModule display-mode identifier. Settings are styled after native construction; warm canvas refreshes skip already prepared controls. Profiles styling is scoped to `AWQ-Profiles`, with cosmetic restoration when pooled AceGUI widgets are released. Modern menu styling uses the existing texture-only helper and does not modify compositor fonts.

Validation: `python3 scripts/package.py` checks Lua syntax, all regression suites, client manifests, catalog entries and the one-folder ZIP with MIT license. The AWQ fixture covers late controls, native actions and return values, unchanged shared quest-log controls and native tracking state, repeated refreshes, Profiles pool restoration, menu ownership, theme updates, combat and disabled skins. A mock of 100 warm canvas refreshes adds no objects, font writes, hooks or quest-tree reads; repeated Profiles feeds also add no objects or font writes. These results are simulated, not in-game CPU/FPS measurements.

No WoW client is available here; visual appearance, live taint behaviour and real frame-time impact have not been verified in-game. No upstream code or artwork is bundled.

## Alpha 3: checkbox outline and performance review

Checkboxes now draw a continuous outer rectangle with an inset fill above the base API surface. The outline stays inside the visible square and uses a minimum of one physical pixel, recalculated on theme/UI-scale refreshes. Native control size, click areas and checked state remain unchanged. The geometry fixture covers effective scales 0.533333, 0.64, 0.711111, 0.9, 1 and 1.25. This validates geometry, not the actual WoW renderer.

The scoped audit found no OnUpdate, scrolling scans, global frame discovery or quest-data hooks. Quest refresh completion visits only AWQ’s active pool; prepared rows reuse their marks and hooks. Settings refreshes use the existing child-count/generation guard. Load-event bursts coalesce into one refresh. Profiles release restores cosmetic state even when the skin has been disabled.

Profiles feeds were rebuilding callback closures and temporary region lists. The adapter now binds callbacks once per reused widget/pullout, shares its font helper and traverses region varargs without allocating a list. The same mock benchmark with garbage collection paused measured temporary Lua heap for 1,000 Profiles feeds dropping from 2,844.44 KiB to 789.75 KiB. This includes harness overhead and is not retained memory or a WoW memory measurement.

Final mock sample (1,000 callbacks each): settings refreshes 0.760 ms / 125.06 KiB temporary heap; quest rebuild completions 3.981 ms / 211.31 KiB; Profiles feeds 13.249 ms / 789.75 KiB. All three create zero UI objects, write zero fonts and add zero hooks after warm-up. Timings vary by host. Another test confirms 1,000 load events coalesce once, and 100 Profiles release/reuse cycles add no objects or hooks. No claim of in-game FPS, CPU usage or visual verification is made.

`python3 scripts/package.py` passes the complete regression suite and installation archive checks. No shared runtime helpers or unrelated skins changed.

## Alpha 4: dropdown refresh and selection markers

AWQ's dropdown generators capture a configuration value in each radio selection predicate. The adapter now enables Blizzard's supported regenerate-on-response behavior for these four controls, so the chosen label and selected marker use current configuration immediately. It does not call configuration setters, regenerate menus from a skin callback or duplicate the native selection action.

Completed native label/selection updates repair only the dropdown's original texture regions and labels. Radio textures receive the compact square/accent treatment through per-description initializers before display; open-menu reconstruction is repaired synchronously too. The adapter does not access compositor SetFont or replace menu responders. Bindings are reused and invalidated on hide; initializer ownership guards leave another addon's menu native.

Late Settings construction now binds display hooks synchronously during ADDON_LOADED, before callers can open the first category. Queued load discovery no longer advances the theme generation and needlessly reapplies every prepared font. Theme, scale and combat recovery still refresh their relevant styling.

New source-shaped tests reproduce native menu reconstruction, captured selection predicates, response regeneration, label/art resets, restricted font access and reuse by a foreign owner. A 1,000-selection stress test adds no skin UI objects, hooks, duplicate setting actions or queued repaints; generated descriptions are collectable. Another test verifies a late Settings category is styled before its display method returns, and queued discovery causes no additional font writes. Existing performance, pool-reuse, combat and disabled-skin checks still pass. Actual visual smoothness and native AWQ world-quest data processing delays remain unmeasured outside WoW.
