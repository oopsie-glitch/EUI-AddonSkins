# Changelog

## 1.5.1 — RestedXP and Gargul Improvements

- Refined RestedXP guide headers, backgrounds and Active Targets/Items windows; fixed clipped titles and matched auxiliary-window opacity.
- Updated RestedXP options controls and fixed dark button labels after state changes and preview/page rebuilds.
- Added an accent-coloured navigation arrow with sharper artwork, a thin black outline and smoother edges when rotated.
- Reduced redundant RestedXP guide scans, options refreshes and font updates.
- Improved Gargul settings performance with page-local refreshes.
- Refined Gargul's roll organizer, MS/OS/PASS window and accepted-roll notification.
- Fixed Gargul dropdown arrow click areas, input alignment, overlapping controls and oversized slider grips.

## 1.5.0 — DBM Skin and Performance Improvements

- Redesigned DBM timer bars with separate Small and Big Bar styling, clearer progress, countdowns and mechanic icons.
- Added Skin Options for bar layouts, colours, borders, mechanic icons and background opacity.
- Refined the DBM interface, range/radar and info frames, including menus, accent headings and draggable backgrounds.
- Reduced unnecessary work when switching DBM options pages and updating timers.
- Preserved DBM positioning, movement locks, category colours and encounter warnings.

## 1.4.2 — Auctionator and Performance Improvements

- Themed Auctionator’s crafting and enchanting price controls, Search buttons and quantity-search popup.
- Reduced unnecessary skin refresh work for hidden addon windows.

## 1.4.1 — Auctionator and Performance Improvements

- Themed Auctionator’s crafting and enchanting price controls, Search buttons and quantity-search popup.
- Reduced unnecessary skin refresh work for hidden addon windows.

## 1.4.0 — BtWQuests, ItemRack and Other Skin Improvements

### BtWQuests — New Skin
- Added Retail support for BtWQuests, including category cards, quest trees, search, dropdowns and options menus.
- Styled navigation, scrollbars and controls to match EllesmereUI.
- Preserved quest status colours, completion indicators and expansion artwork.

### ItemRack
- Updated settings, saved-set menus, equipment selectors and quick-access menus with softer EUI styling.
- Added square item icons with rarity-coloured borders.
- Improved sliders, checkboxes, dropdowns and input alignment.
- Added accent colours to tab labels and quick-access menu controls.
- Removed repeated input refreshes that could disrupt set editing and reduce performance.

### Auctionator
- Improved integration with the EUI auction-house background, tabs and result tables.
- Updated scrollbars, search controls, shopping-list buttons and pooled item rows.
- Corrected quantity, price and duration alignment in the Selling tab while preserving currency icons.

### Altoholic
- Improved summary tables, category navigation, options controls and scrollbars.
- Corrected missing equipment artwork and added square borders that follow item quality.
- Restored bottom-tab backgrounds and improved accent styling.
- Updated the Agenda calendar with dark day cells, subtle dividers, EUI navigation arrows and an accent outline for today.
- Aligned calendar filters and reduced unnecessary processing of hidden tabs and panels.

## 1.3.0 — PallyPower and Skin Loader Optimization

- Added PallyPower styling for Blessing Assignments, options, menus and buff controls, with clearer columns and softer controls. Kept the original lock button.
- Fixed Altoholic scrollbar styling and thumb size, hidden unused realm-row cells, and preserved category styling after tab changes.
- Cleaned up BugSack's header, portrait, navigation and footer. Removed its top accent bar.
- Show EUI skin toggles only for installed, enabled targets. Defer skin activation until the target loads while keeping one addon folder and existing settings.
- Reduced repeated refresh work in DBM, Details, Gargul and ThreatClassic2. Kept PallyPower checkbox updates local to avoid full-window scans.
- Added `/euiskins diagnostics` for copyable loader status.

## 1.2.0 — Details! and ThreatClassic2

- Added Details! meter, options, breakdown/report window and pop-out menu skins.
- Added independent Details meter, Tiny Threat and menus/options controls, accessible from the meter settings pop-out or `/euidetails`.
- Added ThreatClassic2 meter, context menu and options skins while preserving native threat values, colours and layout.
- Fixed header anchor cycles, restoration for missing Details windows, and raid-plugin menu switching/refreshes.
- Fixed ThreatClassic2 menu reuse and font resets after Lock/Test Mode changes.

## 1.1.1 — Styling improvements

- Softer window, panel and control styling, with darker outlines and clearer background contrast.
- Updated RestedXP, Altoholic, AtlasLootClassic Continued, Attune, Auctionator, BugSack, DBM, Forever Companion, Forever Dungeon Journal, Gargul, GTFO, KiwiFarm, Myslot, Spy, Questie and What's Training?.
- Improved Questie tracker font timing and continuous Questie/Dungeon Journal headers.
- Aligned Forever Companion header controls and side-tab icons.
- Fixed oversized GTFO slider thumbs and removed native slider border artwork.
- Retained accents, scrollbar styling, selection feedback and meaningful status/item colours.

## 1.1.0

- Promoted 1.1.0-beta.4 to stable with the same skin implementations.
- Added Questie, Deadly Boss Mods options, AtlasLootClassic Continued, GTFO settings and Gargul skins.
- Includes Questie toggle/dropdown, DBM font/tab, RXP scrollbar and AtlasLoot border fixes from the beta series.
- CrossGambling and ThreatClassic2 are no longer included.

## 1.1.0-beta.4

- Removed the boxed Questie tracker icon and styled tracker/Journey expand and collapse controls.
- Aligned Questie Journey dropdowns with their containing panels.
- Slimmed the RXP scrollbar thumb while preserving its drag area.
- Styled DBM paragraph fonts and native font changes immediately, including lazy panels.
- Prevented native DBM tab artwork from returning.
- Removed CrossGambling and ThreatClassic2 skins.

## 1.1.0-beta.3

- Fixed Questie initialization failing when hooked coroutine functions yield.
- Applied Gargul settings sections and DBM tab changes synchronously to avoid delayed skinning.
- Improved Gargul text contrast and removed boxed navigation rows.
- Completed DBM Classic tab styling and separated the search box from the content frame.
- Fixed AtlasLoot Favourites discovery and the main window's white border.
- Contained RXP header icons and styled its legacy scrollbar and resize grip.

## 1.1.0-beta.2

- Added ThreatClassic2 monitor typography, window accents and settings controls while preserving threat values, class colours and warnings.
- Added Gargul window, dialog, input, icon and menu styling.
- Preserved Gargul countdown colours, loot actions and its custom font-size methods.

## 1.1.0-beta

- Added AtlasLootClassic Continued window, favourites, settings, dropdown and selection-control styling.
- Preserved AtlasLoot item-quality colours, item overlays, expansion logos, maps and models.
- Added GTFO settings skins for checkboxes, test/reset buttons and sliders.
- Includes the Questie and DBM skins from the alpha builds.

## 1.1.0-alpha.2

- Added optional Deadly Boss Mods options-window styling, including tabs, category toggles, sliders, buttons and dropdown controls.
- Preserved DBM colour swatches, preview content, combat alerts and timer bars.
- Includes the Questie skin from the previous alpha.

## 1.1.0-alpha

- Added an optional Questie skin for Journey, settings, note windows, tracker typography and popup menus.
- Preserved quest colours, tracker opacity, map markers and secure quest-item buttons.

## 1.0.6

- Replaced the AddOns list icon with the correct A.S. logo.

## 1.0.5

- Added the addon icon to the in-game AddOns list.

## 1.0.4

- Promoted the tested 1.0.4-beta build to stable; no skinning behaviour changed.
- Includes the frame-guard and Auctionator refresh-discovery fixes from the beta.

## 1.0.4-beta

- Fixed frame guards attempting to inspect functions or other non-UI values.
- Removed Auctionator's ambiguous Refresh field from button discovery.
- Updates are now published as beta while the skinning fixes are being validated.

## 1.0.3

- Kept Dungeon Journal mode tabs flat in every enabled and disabled state, preserving their icons.
- Completed Auctionator legacy scrollbar, item-border, duration-selector and secondary-control styling.
- Corrected Auctionator tab selection when hidden wrappers retain visible child pages.
- Aligned Shopping search controls and separated them from its list tabs.
- Applied consistent panel and text styling while preserving item counts, rarity colours and loading indicators.
- Moved Forever Companion's auction scan footer below the tabs so its status text has room.

## 1.0.2

- Fixed missing-font errors in tree toggles, resize grips and the Dungeon Journal language picker.
- Fixed numeric icon IDs being passed to EllesmereUI as Texture objects.

## 1.0.1

- Removed the deferred native-menu flash when opening supported popup menus and submenus.
- Added scoped Altoholic options-menu styling and completed its legacy controls and header portrait.
- Styled Attune quest cards, zoom controls, tree selection and header portrait while preserving graph/status information.
- Completed Dungeon Journal header buttons, language picker, dungeon-card borders and legacy scrollbars.
- Flattened native control borders and resize artwork; preserved actions, icons and status colours.

## 1.0.0

- First stable release with fourteen optional addon skins and independent EllesmereUI toggles.
- Includes the performance improvements from 0.7.2.

## 0.7.2

- Reduced repeated scrolling, texture writes and hook allocations.
- Limited Auctionator configuration discovery to load/initialization events.
- Deferred RestedXP skin work during combat and removed unnecessary combat-end theme refreshes.

## 0.7.1

- Added scoped popup-menu styling for KiwiFarm, RestedXP and TwitchEmotes, including submenus.
- Fixed ItemRack labels hidden by background fills and preserved the selected-set icon.

## 0.7.0

- Added MIT licensing and publication disclaimers.

- Added CrossGambling, What’s Training?, ItemRack, KiwiFarm, Myslot, BugSack, Altoholic and Attune skins.
- Added shared support for lazy windows, native panels, AceGUI controls and multiline output panes.

## 0.6.2

- Skinned Forever Companion’s BiS Talents button above the spellbook/talent window.

## 0.6.1

- Fixed release packaging to include and load the Auctionator and Spy skins.

## 0.6.0

- Added Auctionator and Spy skins with individual EUI toggles.

## 0.5.0

- Added EUI theme backgrounds for RestedXP guide and Active Targets windows.
- Added selected-tab styling for Companion and Dungeon Journal.
- Added input padding, icon borders, footer strips and support for existing status bars and sortable headers.

## 0.4.1

- Added accent bars that follow EUI visibility and color settings.
- Fixed RestedXP borders flashing white during redraws.

## 0.4.0

- Added individual skin toggles to EUI's Third-Party Addons settings.

## 0.3.2

- Removed the gap between RestedXP backgrounds and borders.

## 0.3.1

- Fixed RestedXP border colors and Active Targets styling.
- Replaced Dungeon Journal's close button with the EUI style.

## 0.3.0

- Added Forever Dungeon Journal and RestedXP skins.

## 0.2.0

- Renamed the project to EUI AddonSkins.
- Made skins optional and switched addon text to English.
