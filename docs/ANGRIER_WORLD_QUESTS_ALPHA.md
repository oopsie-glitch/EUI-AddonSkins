# Angrier World Quests alpha

Branch: `skin/angrier-world-quests-initial` (untagged; no platform upload).

Styles the Retail quest-log trophy tab, the addon settings canvas and its AceDB Profiles controls. Quest-list checkboxes, reward/status colours, data providers, map pins and quest processing are untouched. Native action scripts, hit areas, layout and settings remain owned by Angrier World Quests.

The tab is located by the QuestFrameModule display-mode identifier. Settings are styled after native construction; warm canvas refreshes skip already prepared controls. Profiles styling is scoped to `AWQ-Profiles`, with cosmetic restoration when pooled AceGUI widgets are released. Modern menu styling uses the existing texture-only helper and does not modify compositor fonts.

Validation: `python3 scripts/package.py` checks Lua syntax, all regression suites, client manifests, catalog entries and the one-folder ZIP with MIT license. The AWQ fixture covers late controls, native actions and return values, unchanged quest checkboxes, repeated refreshes, Profiles pool restoration, menu ownership, theme updates, combat and disabled skins. A mock of 100 warm canvas refreshes adds no objects, font writes, hooks or quest-tree reads; repeated Profiles feeds also add no objects or font writes. These results are simulated, not in-game CPU/FPS measurements.

No WoW client is available here; visual appearance, live taint behaviour and real frame-time impact have not been verified in-game. No upstream code or artwork is bundled.
