# Auctionator Retail rarity borders

Development branch: `skin/auctionator-quality-borders`, based on main `b9e0d71`.
Awaiting in-game approval; no release/version/changelog changes.

## Source and cause

Reviewed the current official [Auctionator 341 package](https://www.curseforge.com/wow/addons/auctionator/files/9162359) (Retail 12.1.5/12.1.0), downloaded for this task. ZIP SHA-256: `32c4a2a8d24d46f4fc2725e62c255171a62877854ce6fcbd3272735f6dd3e4e2`.

- `Source/Groups/ViewItem.lua` sets native `IconBorder` colour and selected/empty visibility in `SetItemInfo`; the selling selected-item subclass restores the border for a populated slot. Our Item adapter faded that texture and drew four replacement edges, suppressing grey/white edges on the modern auction house.
- `Source/Components/ResultsListing/Templates/ItemKeyCell.xml` supplies a small native border atlas. Our Row adapter faded it. The modern `ItemKeyCell:Populate` assigns item data, icon and availability alpha but does not colour the border. Shopping/search (including shopping-list searches) and cancelling share this cell. `ItemKeyLoading:ProcessItemKey` completes native metadata loading and dirties the provider, repopulating cells.
- `Source_ModernAH/Tabs/Buying/Templates/IconAndName.xml` and its mixin already supply and colour `QualityBorder` for item/commodity purchase headers and dialogs. Leave this path native. Price-only/history/search-term rows do not acquire decorative item borders.

## Implementation

Keep the selling button's native `IconBorder` in EUI Button's keep list, including theme reapplication. Retain native colour, selection, empty state, count and profession-quality overlay; keep the existing icon geometry/crop. Promote native borders above the EUI button surface, below the profession-quality overlay. Remove replacement border creation on the modern path.

Retain the result cell's existing atlas and geometry. At discovery and completed per-cell `Populate`, colour that texture using `ITEM_QUALITY_COLORS` and the current `C_AuctionHouse.GetItemKeyInfo` quality, with cached `C_Item.GetItemInfo(itemLink)` fallback. Hide it when quality is unavailable, rather than showing a recycled colour. Later native population retries with current data. No custom rarity palette, data mutation, extra border artwork, item-loading callback, polling or global hook is added. Existing ScrollBox updates only touch their current rows. Unchanged colour/visibility writes are skipped.

Changes are confined to Auctionator.lua and its regression fixture. Legacy AuctionFrame retains its accepted replacement-edge treatment. Shared helpers, other skins, layout, click targets, protected actions, release versions and MIT license are unchanged.

## Verification

`python3 scripts/package.py` passes: runtime Lua syntax, all 41 registered regression suites, manifest/catalog/version checks and the 58-file, single-folder installation ZIP with exact MIT license. `git diff --check` passes. The updated fixture rejects the pre-fix adapter.

The Auctionator fixture covers all eight rarity indices (Poor through Heirloom), native selling selection/empty/count/tier states, purchase headers, first-populated and newly pooled results, replacement/shrinking rows, late/missing metadata, item-link fallback, missing optional item-key API, native nil-containing returns, unchanged icon/row geometry, theme reapplication and disabled/stock/combat deferral/recovery.

A single 1,000-population mock workload cycles all qualities and verifies zero new UI objects, hooks, hierarchy reads, geometry writes or queued refreshes. These are mock operation counts, not client timings or FPS measurements.

In-game verification remains: border thickness/layering at the user's UI scale, shopping/search and shopping-list results, scrolling/sorting/filter changes, cancelling, selling bag/selected slots, item/commodity purchase headers/dialogs, theme/accent changes and selection/empty transitions. WoW rendering and taint safety are not established by mocks. No merge, tag or platform publication is authorized by this task.
