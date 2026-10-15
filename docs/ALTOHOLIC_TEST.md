# Altoholic refinement

Branch: `skin/altoholic-refinement`, based on main. Untagged; no CurseForge or Wago upload. Auctionator and BtWQuests experiments remain on their own branches.

- Clear content insets and category backgrounds expose the EUI window texture. Results and column headings receive a subtle 2% wash instead of extra opaque panels.
- Summary values and sort headings have transparent fills and no cell borders. Actual action buttons retain their EUI control surfaces; category selection retains its accent tint.
- Sort-arrow direction/visibility, text colours, currency formatting, column widths, alignment, tooltips and click handlers remain native.
- Completed tab changes style newly created controls synchronously. Pooled data setters refresh only their cell; no new polling or global hooks.
- Existing portrait, tabs, scrollbar, private-menu and unused realm-cell fixes remain in place. Shared runtime helpers, settings, addon version and release changelog are unchanged.

`python3 scripts/package.py` checks Lua syntax, all 16 suites, manifests, catalog and the installation archive. Regression fixtures cover transparent cells versus action buttons, preserved selection/sort/data/clicks/layout, lazy tabs, local setter refreshes, warm reuse, theme repaint, combat deferral and disabling.

The ZIP has one `EUIAddonSkins/` directory, all 21 main-branch skins and the MIT license. Development and reference files are excluded. It does not include the separate unmerged Auctionator or BtWQuests work.

Source shapes were checked against the author's AddonFactory and Altoholic Retail templates, including the shared category, header and twelve-cell summary controllers. The attempted Forever archive download was unavailable. No WoW client rendering or taint verification was performed; automated mocks do not establish those results.
