# Cheap Upgrades (WoW Forever)

Development integration: PR #100. Visual and live-client acceptance are pending.

## Sources and scope

- Authoritative supplied CheapUpgrades-0.18.9.zip: https://github.com/user-attachments/files/35381363/CheapUpgrades-0.18.9.zip
- Archive SHA256: 79bdfc5e451360a2f19310e5aae575daae4456428474471e7ae9b4086aad2b47; TOC version 0.18.9, Interface 16001, 39 files.
- Native shared tab implementation: fiote/AuctionatorForever at d38a2cabd892571aae129dce5da801080de077b3, Libs_ModernAH/LibAHTab/LibAHTab.lua and Source_ModernAH/Tabs/Mixins/TabContainer.lua.
- Naowh comparison: naowh-gaming/NaowhForever at 2cdc6717b980b8f076290955f4df943f8cf5010a, NaowhForever_Market/UI/HouseTabs.lua and UI/Dock.lua.
- Public EUI primitives checked against window engine revision d84a1e19d0b63a9a944dd8023e436290a1b7a173.
- Modern owned dropdown completion follows Blizzard DropdownButtonMixin:OnMenuOpened(menu); the existing popup helper owns styling/restoration.

These are source references, not proof of the reporter's installed Auctionator/Naowh revisions. Only the supplied Cheap Upgrades version is verified exactly. No upstream addon source or media is bundled. Cheap Upgrades declares All Rights Reserved.

## Confirmed overlap and correction

Auctionator's skin previously rebuilt AuctionatorAHTabsContainer.Tabs directly after the last Blizzard tab, shortened each button by 2 and replaced native hit insets. This list excludes other LibAHTab consumers. Cheap Upgrades inserts Upgrades/Alts into the complete shared row; our rechain skipped those tabs and placed Shopping/Selling over them.

The correction removes that subset layout operation, including the height and hitbox overrides. LibAHTab retains complete-row order, geometry and native selection. No replacement layout, tab-count assumption or additional layout hook is introduced. This correction belongs to Auctionator and applies whether Cheap Upgrades is absent, enabled or its EUI skin is disabled.

Naowh's reviewed dock reads the complete library list when finding its last tab. Its positioning and callbacks are left intact. Cheap Upgrades' own fallback tabs/offset are also left intact.

## Skin coverage and ownership

The independent Cheap Upgrades toggle uses the existing loader/catalog; no new appearance preferences or SavedVariables are added.

- Standalone window, auction-house content host, options window/pages and specialization prompt.
- Upgrades/Alts tabs using GetButton with CheapUpgrades_upgrades / CheapUpgrades_alts; native fallback owned tab globals.
- Buttons, checkboxes, edit boxes/money fields, dropdown fields, scrollbars and owned inset chrome.
- Fixed item and alternative-cell pools: icon treatment and fonts only. Native rarity borders, selection, badges, prices, class/spec information and semantic colors remain native.
- Options pages: types, weights, reasons, auction house and display, including their constructed controls and scrolling content.
- Owned modern dropdowns are bound at their instance's completed-menu callback. Shared popup appearance/restoration is delegated to the existing owner-aware popup helper. There is no library/prototype replacement or competing menu.

Shared GameTooltip, StaticPopup confirmations/profile-name/import/export dialogs, bag/quest reward overlays and minimap art remain native. They are not privately owned windows and are deliberately excluded. Modern menu states and nested submenu interaction still require client verification.

## Lifecycle and resources

The module installs completed-builder hooks on CreateUI, AttachAHButton, ShowUI and Options CreatePanel/Open/AskSpec/BuildPage, plus ShowPage for option-tab selection. Each root has one OnShow observer; each owned dropdown has at most one OnMenuOpened post-hook. One combat-recovery event and one appearance callback are used. No hook is installed on RefreshUI, UpdateCell, scanning, scoring, item/price updates or native OnUpdate handlers.

Root generation caching avoids warm subtree scans. Appearance refresh invalidates fonts; already painted hidden roots wait until shown. Public EUI primitives own their theme resources. Native option-tab selection is only written when its state changes. There is no scheduled timer, recurring discovery, global frame scan or geometry write in the Cheap Upgrades module.

## Validation and acceptance

GitHub Actions runs the complete package/regression suite, checksum-pinned source contracts, actual pinned LibAHTab execution in both insertion orders and an independent later consumer. The overlap test is also run against the exact main baseline and must fail there.

Seven fresh Lua states compare unskinned and skinned source-shaped fixtures for activation, first opening, 1,000 reopens, 1,000 native updates and 1,000 closed-window updates. Results are hosted Lua measurements, not actual WoW CPU/FPS/GPU/taint results. Public EUI helper allocations in the real client can differ from the mock inventory.

Test in WoW Forever:

1. Auctionator alone, then Cheap Upgrades with each skin on/off. Compare complete tab order/click targets and selection.
2. Add Naowh; open/reopen the auction house and change all tabs. Repeat after /reload and with alternate load orders.
3. Open Cheap Upgrades standalone and inside the auction house; exercise Upgrades, Alts, class/spec/character menus, item alternatives, budget and scan controls.
4. Exercise all five options pages, profile actions, specialization prompt and tooltips; verify native actions and meaningful colors.
5. Test dropdown selection, nested menus, Escape/outside click and reuse by another addon.
6. Change EUI theme/accent; resize/scale and repeat in/out of combat. Check Lua errors/taint and warm reopening.
7. Confirm disabled/absent Cheap Upgrades creates no skin work. Retail remains catalog-safe; Cheap Upgrades' functionality is verified only for its Forever source.

No merge, version bump or publication is part of this integration.
