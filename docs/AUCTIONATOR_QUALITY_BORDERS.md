# Auctionator Retail rarity borders

Development branch: `skin/auctionator-quality-borders`, based on main `b9e0d71`.
Awaiting in-game approval; no release/version/changelog changes.

## Source and cause

Reviewed the current official [Auctionator 341 package](https://www.curseforge.com/wow/addons/auctionator/files/9162359) (Retail 12.1.5/12.1.0), downloaded for this task. ZIP SHA-256: `32c4a2a8d24d46f4fc2725e62c255171a62877854ce6fcbd3272735f6dd3e4e2`.

- `Source/Groups/ViewItem.lua` sets native `IconBorder` colour and selected/empty visibility in `SetItemInfo`; the selling selected-item subclass restores the border for a populated slot. Our Item adapter faded that texture and drew four replacement edges, suppressing grey/white edges on the modern auction house.
- `Source/Components/ResultsListing/Templates/ItemKeyCell.xml` supplies a small native border atlas. Our Row adapter faded it. The modern `ItemKeyCell:Populate` assigns item data, icon and availability alpha but does not colour the border. Shopping/search (including shopping-list searches) and cancelling share this cell. `ItemKeyLoading:ProcessItemKey` completes native metadata loading and dirties the provider, repopulating cells.
- `Source_ModernAH/Tabs/Buying/Templates/IconAndName.xml` and its mixin already supply and colour `QualityBorder` for item/commodity purchase headers and dialogs. Leave this path native. Price-only/history/search-term rows do not acquire decorative item borders.

## Implementation

The selling refinement follows EllesmereUI 9.7, commit `5abb35ba158463ca25acc89cadcc56fbb7be6037`, inspected from the current upstream repository. Its `Skin_AuctionHouse` / `ItemDisplay` in [WindowPacks](https://github.com/EllesmereGaming/EllesmereUI/blob/5abb35ba158463ca25acc89cadcc56fbb7be6037/EllesmereUIBlizzardSkin/EllesmereUIBlizzardSkin_WindowPacks.lua) removes the display panel chrome but deliberately retains the item button. The public SkinAPI exports Button and SquareIcon; neither recreates that retained item-button treatment. No private EUI function or state is used.

Blizzard's `AuctionHouseSellFrameTemplate` uses `AuctionHouseInteractableItemDisplayTemplate`, whose `GiantItemButtonTemplate` supplies the `auctionhouse-itemicon-empty` socket, a 2-unit inset icon and `common-iconmask`. `SetItemButtonQuality` sets its native `IconBorder` to `Interface/Common/WhiteIconFrame`. References: [Auction House templates](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseSharedTemplates.xml), [item templates](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ItemButton/Mainline/ItemButtonTemplate.xml), [native quality setter](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ItemButton/Mainline/ItemButtonTemplate.lua).

For selling-owned slots only, reuse Auctionator's EmptySlot region with the same client socket atlas, anchor its existing rarity ring to the inset icon, and retain one native corner mask per slot. Reuse the existing selection texture as a restrained outer WhiteIconFrame ring, retaining Auctionator's selection colour/visibility. Keep native rarity visibility, count, profession-quality overlay and interaction. The large selected-sale subclass still keeps its populated rarity ring visible. Preserve the accepted 2-unit icon inset/crop and all button sizes, positions and click areas.

Do not register selling slots as EUI text Buttons; this removes their unrelated rectangular plate. An Auctionator-local SquareIcon facade suppresses only the shared scanner's redundant BorderRegion request for those known slots. Other SquareIcon callers, generic helpers, results, purchase headers and legacy AuctionFrame remain unchanged. Native icon setter hooks repair only that slot, with unchanged anchors skipped. Combat recovery and re-enabling inspect current anchors. Missing socket atlas keeps the previous usable native-border path; missing mask API omits only the mask. No private implementation or external artwork is bundled.

Retain the result cell's existing atlas and geometry. At discovery and completed per-cell `Populate`, colour that texture using `ITEM_QUALITY_COLORS` and the current `C_AuctionHouse.GetItemKeyInfo` quality, with cached `C_Item.GetItemInfo(itemLink)` fallback. Hide it when quality is unavailable, rather than showing a recycled colour. Later native population retries with current data. No custom rarity palette, data mutation, duplicate rarity border, item-loading callback, polling or global hook is added. Existing ScrollBox updates only touch their current rows. Unchanged colour/visibility writes are skipped.

Changes are confined to Auctionator.lua and its regression fixture. Legacy AuctionFrame retains its accepted replacement-edge treatment. Shared helpers, other skins, layout, click targets, protected actions, release versions and MIT license are unchanged.

## Verification

`python3 scripts/package.py` passes: runtime Lua syntax, all 41 registered regression suites, manifest/catalog/version checks and the 58-file, single-folder installation ZIP with exact MIT license. `git diff --check` passes. The updated fixture rejects both the pre-fix adapter and the preceding PR #64 test build.

The Auctionator fixture covers all eight rarity indices (Poor through Heirloom), native selling selection/empty/count/tier states, purchase headers, first-populated and newly pooled results, replacement/shrinking rows, late/missing metadata, item-link fallback, missing optional item-key API, native nil-containing returns, unchanged icon/row geometry, theme reapplication and disabled/stock/combat deferral/recovery.

A single 1,000-population mock workload cycles all qualities and verifies zero new UI objects, hooks, hierarchy reads, geometry writes or queued refreshes. An additional 1,000 large-slot plus 1,000 inventory-slot update workload verifies zero new UI objects/hooks, hierarchy reads, geometry writes or queued refreshes. Selling coverage includes the retained socket, inset rarity ring, single mask, no EUI plate/extra border, native count/selection/tier/actions, late slots, foreign controls, geometry reset, combat/disable recovery, theme and missing atlas/mask APIs. These are mock operation counts, not client timings or FPS measurements.

In-game verification remains: side-by-side selling socket/ring/mask rendering against the supplied EUI-skinned AH screenshot, border thickness/layering at the user's UI scale, shopping/search and shopping-list results, scrolling/sorting/filter changes, cancelling, selling bag/selected slots, item/commodity purchase headers/dialogs, theme/accent changes and selection/empty transitions. WoW rendering and taint safety are not established by mocks. No merge, tag or platform publication is authorized by this task.

The same client assets are used, but exact pixel equivalence is not claimed: inventory slots retain Auctionator's smaller size and accepted crop, selection remains an explicit native state, and an older client without the atlas or mask API retains the documented fallback. The installed EUI version and actual WoW rendering remain unverified.

## Empty-preview crop correction

The reported empty-slot cut-off is an inherited texture-coordinate mismatch in `AuctionatorSellingFrame.SaleItemFrame.Icon.EmptySlot`. Auctionator's `Source/Groups/ViewItem.xml` defines that reused region with `(0, 0.640625, 0, 0.640625)` for the old UI-Slot-Background sprite. The selling adapter assigned `auctionhouse-itemicon-empty` without resetting the inherited crop. This samples only part of the replacement art, consistent with the complete top/left and abruptly missing lower/right socket in both attached Auctionator states. Parent clipping, strata, levels and overlapping fills do not need to be changed to correct this source-level mismatch.

For this exact preview owner only, reset the existing socket's normalized texture coordinates to `(0, 1, 0, 1)` immediately after SetAtlas. This uses the complete client atlas region as the GiantItemButton empty background retained by EUI does. No region, overlay, hook, polling, layout change or refresh callback is added. Inventory texture coordinates, icon dimensions, rarity ring, mask, counts, price controls and selection actions are unchanged. The socket remains the backdrop beneath the item in populated states and fully visible when native code hides the item on clearing.

The fixture now starts with the actual inherited XML crop, models the native item show/hide transitions, and checks full-region sampling on first empty display, selection, clearing and theme refresh. It asserts one setup correction and no repeated socket UV writes across 1,000 large-slot updates, with inventory/foreign coordinates unchanged. The preceding `8bc7e39` runtime fails the focused crop assertion. Full package validation passes. In-game verification remains necessary for actual rendering at the user's UI scale; no live WoW frame dump or client rendering is available here.
