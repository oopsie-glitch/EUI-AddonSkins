# Angrier World Quests alpha

Branch: `skin/angrier-world-quests-initial` (untagged; no platform upload).

Alpha 2 uses smaller settings-checkbox artwork without changing hit areas, and recognises modern dropdowns reported as Buttons. It also styles AWQ quest-row checkboxes with compact dark squares and an accent-coloured checked indicator. The original alpha 1 ZIP remains available for comparison. Styles the Retail quest-log trophy tab, the addon settings canvas and its AceDB Profiles controls. Reward/status colours, data providers, map pins and quest processing are untouched. Native action scripts, hit areas, layout and settings remain owned by Angrier World Quests.

Quest checkboxes are discovered only through the AWQ header’s active frame pool after completed list rebuilds. The tracking mark follows native Show/Hide state; tracking actions and hit areas are unchanged. Prepared rows reuse their artwork and hooks.

The tab is located by the QuestFrameModule display-mode identifier. Settings are styled after native construction; warm canvas refreshes skip already prepared controls. Profiles styling is scoped to `AWQ-Profiles`, with cosmetic restoration when pooled AceGUI widgets are released. Modern menu styling uses the existing texture-only helper and does not modify compositor fonts.

Validation: `python3 scripts/package.py` checks Lua syntax, all regression suites, client manifests, catalog entries and the one-folder ZIP with MIT license. The AWQ fixture covers late controls, native actions and return values, unchanged shared quest-log controls and native tracking state, repeated refreshes, Profiles pool restoration, menu ownership, theme updates, combat and disabled skins. A mock of 100 warm canvas refreshes adds no objects, font writes, hooks or quest-tree reads; repeated Profiles feeds also add no objects or font writes. These results are simulated, not in-game CPU/FPS measurements.

No WoW client is available here; visual appearance, live taint behaviour and real frame-time impact have not been verified in-game. No upstream code or artwork is bundled.
