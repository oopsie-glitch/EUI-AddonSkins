# Nova Instance Tracker alpha

Branch: `skin/novainstancetracker-initial`, based on stable 1.5.2. Untagged; not published to CurseForge or Wago.

## Scope

Independently written runtime cosmetics for the supplied Nova Instance Tracker 2.31. Covers instance history, characters/rested XP, trade log/export, copy/delete dialogs, raid lockouts, post-instance sharing, level log, loot-reminder lists and the options canvas/standalone AceConfig window. Soft charcoal surfaces have a restrained centre lift. Native red action buttons, close buttons, dropdowns, scrollbars, horizontal sliders and checkbox artwork receive the existing theme treatment. No top accent stripe. Native checkbox hit areas and log geometry remain intact; selected checks/grips follow the EllesmereUI accent. Options labels are neutral.

Status legends, coloured log text, realm/class/status information, item/coin icons, hyperlinks, reminder animation, sharing/copy/whisper actions, deletion, history, filters, settings and saved layout remain controlled by Nova. Background fills are BACKGROUND textures on the owning frame; no raised opaque overlay is placed over data. Models, tooltips owned by Blizzard and protected frames are excluded. Main runtime version remains 1.5.2 until release integration; the test ZIP name identifies the alpha.

## Lifecycle and safety

Native completed open/create callbacks bind current windows. Instance/character row constructors style only the returned named row; Level Log's frame-local constructor handles its own new row. Stable descendants cache child/region counts and theme generation. Nova resets some log/title fonts on reopen; those owned texts get a synchronous local font repair, without a page refresh. There are no skin OnUpdate hooks, tick/recalc/data hooks, UIParent traversal, global frame factories or AceGUI constructor/AddChild replacements.

AceConfig completion is limited to NovaInstanceTracker application IDs. Each shared widget acquisition snapshots native texture/backdrop/colour/anchor state and restores it on release, even when disabled. Shared options/menu fonts are left native; no FontObject is captured or assigned. Pullouts restore on hide and foreign reuse. Warm widget feeds skip existing artwork; check state callbacks skip unchanged cosmetic geometry/colours, while label/image changes retain local anchor repair. Target/toggle/combat guards and late library binding remain in place.

## Verification

`python3 scripts/package.py` validates Lua syntax, all 23 regression suites, all client manifests/catalogs and the 40-file, single-folder ZIP with the exact MIT license. Targeted tests cover missing targets, native return values/actions/data/links/status art, late rows/windows, local title-font repair, compact checks, options/menu reuse/restoration, neutral labels, independent foreign widgets, protected/model exclusions, live themes and combat/disabled handling.

Mock workloads: 1,000 native timer updates add zero skin hierarchy reads, objects, hooks or font writes; 1,000 warm options-feed/window-show cycles add no skin objects/hooks/font writes; 100 newly created log rows cause no whole-log traversal; 500 pullout opens, 250 widget release/reacquire cycles and 25 theme refreshes add no new skin objects/hooks after warm-up. A further 1,000 stable checkbox setter cycles add no cosmetic geometry/colour writes. First-time native controls still require initial styling. These counts are simulated; no in-game FPS/CPU, long-session memory, appearance, taint or native crash result is claimed.

## Source and package boundaries

Input archive SHA-256: `02f91b73ef281c8e084bfb9353c799695217c4bc56d9d920ba7aa3a192d31998`. No Nova code, XML, bundled libraries, assets, records or other target files are shipped. Install Nova Instance Tracker and EllesmereUI separately. Reference and test/development files remain outside the player ZIP.
