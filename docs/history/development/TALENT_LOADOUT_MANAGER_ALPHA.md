# Talent Loadout Manager alpha

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Branch: `skin/talentloadoutmanager-initial`, based on stable 1.5.2. Untagged; no CurseForge/Wago publication.

Retail integration for the Blizzard talent sidebar and Talent Tree Viewer sidebar, import dialog, AceConfig Settings canvas and standalone options window. Flat buttons, compact accent check markers, neutral labels, themed scrollbars and a textured standalone options/import background. No main-window accent stripe. Native sidebar background/selection colour and opacity controls remain authoritative; no opaque shell is placed beneath its configurable background.

Native loadout creation, import/export, save, rename, locking, deletion, character visibility, validation, side positioning/collapse and talent application remain untouched. Context menus bind only to TLM rows. Shared confirmation and AceGUI controls retain native fonts, get no FontObject access or reassignment, and restore borrowed texture/backdrop/label colours on release. No shared helper changes or bundled third-party code/assets.

The implementation uses TLM's SideBarLoaded callback, completed SetupHook/row initializers and app-scoped AceConfig FeedGroup. It does not hook talent calculation, data providers, OnUpdate, global frame creation or AceGUI constructors. Row updates style only their row; no full talent/options hierarchy scan. Theme changes and deferred combat recovery repaint owned controls.

Validation: Lua syntax, all 23 regression suites and the 40-file, single-folder install package pass. Targeted mocks cover missing/late targets, lazy sidebars and import dialogs, native clicks/returns/disabled state, custom colours/opacity, modern scrollbar, row/menu ownership, pooled font safety and release while disabled, theme changes and combat recovery. A thousand warm row initializations add zero UI objects/hooks or child/region reads; 100 AceGUI release/reacquire cycles add zero objects/hooks/font writes. These are simulated counters, not in-game FPS/CPU or taint measurements. Actual rendering and protected-client behaviour remain unverified outside WoW.

Source reviewed: NumyAddon/TalentLoadoutManager tree `5cf71b5776a7b73df7baf6053fcd7b1e40488c98`, including Config, SideBarMixin, DefaultUISidebar and TalentTreeViewerSidebar, plus the public AceGUI checkbox lifecycle. Target addons and EllesmereUI are installed separately. Install ZIP keeps version 1.5.2; its alpha filename identifies this untagged build.

## Alpha.2 options refresh performance

Repeated AceConfig FeedGroup/Open/OnShow callbacks previously enumerated native button artwork and reapplied layer frame levels, visibility and backdrops even when the widget was unchanged. State setters also ran the general widget painter. A small mock of 100 warm feed/state cycles recorded 100 region enumerations before the change.

Each borrowed widget acquisition now records its styling generation. Subsequent feeds retain new-child discovery but skip unchanged artwork/layer operations. SetDisabled/SetValue/SetType/SetTriState callbacks update only the affected widget's label/check state. Unchanged labels and check colours avoid redundant writes. Release clears the record, so a widget reacquired for a new tab still gets its first complete styling pass; no native actions or layout methods are replaced.

A thousand warm feed/state cycles now perform zero hierarchy/artwork reads, new UI objects, hooks, font writes or texture colour writes in the mock. Replacement children at the same child count and widget release/reacquisition remain covered. Full 23-suite, Lua syntax and one-folder package checks pass. This demonstrates reduced repeated work, not a measured in-game FPS gain or conclusive diagnosis of the reported lag.
