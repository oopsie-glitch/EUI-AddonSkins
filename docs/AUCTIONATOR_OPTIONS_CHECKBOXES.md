# Auctionator options checkboxes

Branch: `skin/auctionator-options-checkboxes`, based on stable 1.5.2. Untagged alpha; no publication or merge into main.

The supplied Options > AddOns > Auctionator > Tooltips screenshot shows oversized dark checkbox plates retaining Blizzard yellow ticks. Apply the compact treatment only to native CheckButtons under named AuctionatorConfig*Frame settings ancestors. Existing option discovery and OnLoad hooks supply those owned roots; no additional global scan is introduced. This is a narrow checkbox correction, not an assertion that every settings control has been audited against current upstream source, which was unavailable during this pass.

A mouse-disabled 22-unit host uses EllesmereUI's public Checkbox primitive with a 4-unit border inset (14-unit visible square), an 8-unit accent marker and a 14-unit hover. Fade only the original checkbox textures. Preserve the original control dimensions, label anchors, click hit area, checked state, callbacks and values. Auction-house duration radios and other checkboxes retain existing styling; foreign/protected controls are excluded.

State callbacks repaint only their own mark visibility/colour. Show/enable/disable/click handlers are bound locally before the generic scanner, preventing those control events from scheduling a whole integration refresh. Stable values skip colour writes. Combat defers cosmetic repair through the existing regeneration refresh; disabled integrations perform no new paint. No new polling, OnUpdate, data hooks, shared-helper changes, dependencies or source/assets are introduced.

`python3 scripts/package.py` passes Lua syntax, all 22 existing regression suites and a 39-file single-folder install package with the exact MIT LICENSE. Expanded Auctionator coverage checks native actions/returns, hit/label preservation, square geometry, checked/disabled states, theme changes, combat/disabled behavior and foreign/protected exclusions. In a mock, 1,000 warm checked/enable/show cycles add zero UI objects/hooks, hierarchy reads, geometry/colour writes or queued full refreshes. Existing auction-house and profession tests also pass. In-game appearance, FPS, native client errors and taint cannot be established here.

Retain the broader Auctionator settings coverage reminder until remaining pages/controls are confirmed; this branch addresses the reported checkbox issue specifically.
