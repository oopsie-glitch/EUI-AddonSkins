# Auctionator profession additions

Branch: `skin/auctionator-profession-panels`. Untagged; no platform publication.

- Apply EUI button styling to Auctionator's crafting, enchanting and tracked-recipe Search buttons.
- Use EUI fonts for cost/profit text while retaining its gold labels, inline warning colors and coin textures.
- Theme the Retail custom-quantity popup and its numeric input without changing values, anchors or search actions.
- Leave Blizzard's profession window, recipe list and reagent controls to EllesmereUI.

Named frame coverage follows the remaining profession additions in AngelosNaoumis's PR #1. Implementation uses targeted public API calls and initializer post-hooks, without scanning the native profession hierarchy or adding polling. Existing frames, late initializers and show callbacks are supported; combat defers updates until combat ends.

`python3 scripts/package.py` validates all 18 suites, Lua syntax, manifests and the install ZIP. Expanded Auctionator coverage checks native search returns/right clicks, colors/text/placement, pre-existing and late frames, quantity values, theme refresh, object/hook reuse, unchanged input fonts on warm refreshes, combat and disabled skins. The shared PR #2 optimization is kept on its separate branch.

Source reference: the supplied Auctionator 341 source snapshot, `Source_Classic/CraftingInfo`, `Source_Vanilla/EnchantInfo`, and `Source_Mainline/CraftingInfo`. Tests use mocks; no in-game rendering or taint verification was performed.
