# Auctionator styling test

Branch: `skin/auctionator-fixes`. Untagged; no CurseForge or Wago publication.

The modern auction-house changes build on [AngelosNaoumis's contribution, PR #1](https://github.com/oopsie-glitch/EUI-AddonSkins/pull/1), adapted to the current deferred skin loader. The contributor PR remains open; its changes have not been merged into main.

## Changes

- Use the existing auction-house backdrop instead of nested content shells and opaque inset panels.
- Flatten table headings and use subtle result-area washes and separators.
- Strip WowTrimScrollBar background-child art as well as its end caps; retain EUI's scrollbar primitive.
- Align Auctionator tabs with the host tabs and synchronize visual selection without changing native tab state.
- Keep the search reset icon visible without its empty button block. Use the client's white refresh atlas when available; retain native refresh art otherwise.
- Keep pooled bag icons square, preserve quality colors and native row actions, and restyle newly pooled result rows.
- Preserve money-input coins, improve quantity/price spacing, and align shopping-list buttons and inner tabs.
- Center numeric input text vertically, use EUI's font, right-align prices with room for coin icons, and center duration labels beside their radio buttons.
- Resolve Auctionator 341's `Quantity.InputBox` wrapper and align independently anchored numeric FontStrings; preserve field labels, currency-symbol labels and direct EditBox layouts.
- Reuse frames and hooks; rescan hidden roots when shown rather than on every refresh.

Legacy AuctionFrame styling retains its existing behavior. Shared Lua files, saved variables, version metadata and published tags are unchanged.

## Validation and limits

`python3 scripts/package.py` runs all 17 regression suites, Lua syntax checks, manifest/version validation and ZIP inspection. The modern Auctionator fixture covers tab selection/layout, headers, pooled rows/icons, coin preservation, reset and refresh controls, scrollbar background redraws, theme foreground preservation, combat deferral, disabled/stock styles, and warm object/hook reuse. Existing fixtures cover legacy controls, missing targets and deferred loading.

The package contains 35 files under one `EUIAddonSkins/` installation directory, including all 21 skins and the MIT license. Development files remain excluded.

EUI's native auction-house seam host has no public skinning API. The inherited compatibility adapter recognizes its unnamed two-line/two-child structure, checks region layers and safe frame access, and lowers only its alpha while Auctionator is active. It restores the original alpha on native views. If the structure changes, the adapter leaves it untouched; native divider lines may remain. No private EUI state tables or native show/hide methods are changed.

Tests use mocked UI objects. No WoW rendering, taint or in-game appearance verification was performed. Translator font glyphs and intentionally clipped selectable URLs were not changed. The Info-page link controls retain their native structure.
