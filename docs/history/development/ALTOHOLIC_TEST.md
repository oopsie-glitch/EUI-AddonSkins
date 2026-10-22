# Altoholic refinement

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Branch: `skin/altoholic-refinement`, based on main. Untagged; no CurseForge or Wago upload. Auctionator and BtWQuests experiments remain on their own branches.

- Clear content insets and category backgrounds expose the EUI window texture. Results and column headings receive a subtle 2% wash instead of extra opaque panels.
- Summary values and sort headings have transparent fills and no cell borders. Actual action buttons retain their EUI control surfaces; category selection retains its accent tint.
- Sort-arrow direction/visibility, text colours, currency formatting, column widths, alignment, tooltips and click handlers remain native.
- Completed tab changes style the selected tab synchronously; completed options-panel changes style their current panel. Both broader and local scans skip explicitly registered hidden tabs/panels. Generic show/click bursts retain their coalesced refresh. Pooled data setters refresh only their cell; no new polling, global hooks or shared helper changes.
- Existing portrait, tabs, scrollbar, private-menu and unused realm-cell fixes remain in place. Shared runtime helpers, settings, addon version and release changelog are unchanged.

`python3 scripts/package.py` checks Lua syntax, all 16 suites, manifests, catalog and the installation archive. Regression fixtures cover transparent cells versus action buttons, preserved selection/sort/data/clicks/layout, lazy tabs, local setter refreshes, warm reuse, theme repaint, combat deferral and disabling.

The ZIP has one `EUIAddonSkins/` directory, all 21 main-branch skins and the MIT license. Development and reference files are excluded. It does not include the separate unmerged Auctionator or BtWQuests work.

Source shapes were checked against the author's AddonFactory and Altoholic templates, including the shared category, header and twelve-cell summary controllers. This follow-up also checks Thaoky/Altoholic_Forever directly (tree 873969817e8aa1a4f37cf1fe3d9e7f88218a9a2d), including the thirteen-column grid, equipment setup, dropdown and options templates. No WoW client rendering or taint verification was performed; automated mocks do not establish those results.

## Tab-refresh check

The inspected main/options tab controllers use AddonFactory, not the AceGUI tab-selection path involved in PallyPower. The previous alpha nevertheless synchronously rescanned the whole window after SwitchToTab, including hidden tabs; show/click callbacks could queue another pass.

A source-shaped mock with eight tabs and 30 cells in each inactive tab produced these counts for ten switches, including native show/click notifications:

| Work | Previous alpha a568622 | Revised |
| --- | ---: | ---: |
| Full-window scans | 20 | 10 |
| Hidden data-cell visits | 4,200 | 0 |

The revised path also performs the immediate selected-tab pass. Newly selected tabs/panels, combat deferral, disabled skin behavior and the older-layout fallback are covered. These are deterministic mocked operation counts; no client CPU time, memory or FPS improvement is claimed. The audit is limited to the inspected AddonFactory tab path and this adapter, not every historical version or embedded library.

## Forever grid and options follow-up

- Preserve equipment artwork stored in `GridsButton.Background` instead of treating it as a panel fill. Replace rounded/glowing borders with cached thin square edges that follow native border colour/visibility. Preserve item levels, empty-slot art, clicks and tooltips. Completed grid-row updates style only that row, including newly pooled cells.
- Preserve class-icon atlas coordinates; the module-local square-icon wrapper skips only registered class atlas textures. Native unassigned-column question marks remain placeholders. Ordinary item icons still use EUI cropping.
- Options sliders clear their separate backdrop child and use compact thumbs, thin tracks and separated captions/endpoints. Scrollbars use a thin neutral thumb. Checkbox labels use neutral/disabled colours with contained accent-tinted ticks. Dropdown fields, native arrow hit targets and their existing private menu binding retain selection behavior; paging uses EUI arrows.
- Remove full-window accent/header/footer bands, retain one continuous EUI shell, and tint the visible EUI tab labels without exposing their native mirrored labels. Keep native bottom-tab anchors and data-column geometry to avoid overlaps with Altoholic's footer and sortable data. The search input retains its native action/icon and gets the EUI font and charcoal fill.
- Use only the public skinning facade. Primitive-created regions are discovered once and cached; no internal EUI frame-data accessor is used. No shared runtime files, target data or saved variables are changed.

The source-shaped fixtures cover real grid Background/Name/IconBorder fields, item-to-empty reuse, new pooled cells, quality colour changes, class atlas updates, public primitive-created tab labels/arrows, native dropdown methods/actions, slider backdrop/geometry/value preservation, normal checkbox semantics, and combat/disabled guards. Fifty grid-row updates perform no full-window scans or repeated edge allocation. Existing hidden-tab benchmark and all 16 regression suites still pass. No in-game rendering or taint verification is claimed.

## Agenda calendar

- Restore the public EUI tab primitive's dark backgrounds on the external bottom tabs. Native tab anchors, labels and selection remain intact, including active accent underlines.
- Replace Agenda's gold calendar tiles and orange weekday strip with EUI button fills, subtle single grid dividers, muted neighbouring-month dates and a restrained hover. Today's date has an accent outline. Native event counts, colours, visibility, date values, tooltips and click actions remain authoritative.
- Use EUI month arrows and a neutral month/year heading aligned over the seven-column grid. Group the existing three filter icons above the event list at a uniform size and spacing, clear of the search field. The native filter hover menus and month actions remain in place.
- Style day updates directly after their native `Update` method. Event-list updates scan only their own subtree; month changes do not request a full-window scan. Dividers are created once on visual-only, mouse-disabled children. No polling or shared runtime changes.

Checked against `Thaoky/Altoholic_Forever` Agenda/calendar templates at `873969817e8aa1a4f37cf1fe3d9e7f88218a9a2d` and EUI's Blizzard calendar implementation. Altoholic's calendar contains event counts rather than Blizzard's holiday illustrations; no new event data or actions are introduced.

Automated fixtures cover late Agenda loading, all 42 days, public primitive-created tab backgrounds, current/adjacent month colours, today/accent changes, weekday art, heading/filter alignment, original day geometry and actions, event visibility/colours, navigation/return values, combat deferral and disabled skins. Twenty mocked month updates retain the same objects/hooks, execute exactly the native 42 day updates per month, and perform no main-window or Agenda-tab scans. All 16 suites and the 35-file MIT-licensed one-folder package checks pass. Actual client layout, hit-testing and taint remain unverified.


## Controls and Retail achievement follow-up

Untagged `skin/altoholic-controls`, based on v1.5.1. No version or release changelog change.

- Use DBM-style inset accent squares on native options checkboxes, retaining native checked/disabled visibility and actions. Checkbox clicks and state changes repaint only that control.
- Replace scroll-stepper text glyphs with image chevrons, preserving button geometry, scroll actions and disabled feedback.
- Use neutral sidebar labels and accent selected labels. Remove embedded decorative colour codes only within category labels; leave character, item, achievement and status data colours alone.
- Flatten Retail achievement-name rows with a 12% hover wash. Preserve native tooltip callbacks, account-wide cyan names, completion overlays and all item/class borders. Row updates repaint the name only.
- Soften Reset/Apply controls and options separators. Retain full shortcut-logo artwork with a small inset inside the original hit area. Dedicated mouse-disabled border children survive texture refreshes.

Sources inspected: Thaoky/Altoholic_Retail `Altoholic/Main.xml`, `Altoholic_Options/TabOptions.xml`, `Altoholic_Achievements/Templates/AchievementRow.lua` and `.xml`; Thaoky/AddonFactory `Templates/AuctionHouseUI/CategoriesList.lua` and `Templates/ScrollFrames.lua` / `.xml`. No upstream code or assets are bundled.

The tab definitions explicitly load each module on demand. First-open work includes native module/data initialization and initial skin setup; later openings reuse controls. The relative cost of those parts has not been measured in WoW. Hidden-tab exclusions and synchronous selected-tab styling remain intact; no eager loading or polling was added.

Validation: `python3 scripts/package.py` runs all regression suites and validates the 39-file single-folder ZIP. Added source-shaped cases cover accent/disabled checkmarks, category colour-code cleanup, chevron redraw/state reuse, Retail achievement rows, logo cropping, action boundaries, native returns, protected controls and unchanged settings/actions. One hundred achievement-row updates plus one hundred checkbox click/disable/enable cycles perform zero full-window scans and allocate no additional UI objects in the mock. Warm refreshes retain the same objects/hooks. These checks do not establish actual client rendering, FPS or taint behaviour.
