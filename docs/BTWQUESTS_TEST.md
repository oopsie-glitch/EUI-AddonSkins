# BtWQuests test build

Branch: `skin/btwquests`, based on current main. Untagged; no CurseForge or Wago upload. Auctionator's ongoing changes remain on their separate branch.

Targets the supplied Retail BtWQuests v2.65.0 UI. BtWQuests and its expansion databases must be installed separately; none of their code, data or assets are bundled.

Client manifests include Retail interface 120105 alongside existing client entries. `/euiskins diagnostics` reports the client/EUI version, API registration availability, EUI's client-block flag, receipt of the skin callback and actual integration activation. An older EUI installation without the public API, or a client blocked by EUI itself, cannot activate this skin; this addon does not bypass that restriction.

## Appearance and scope

- One EUI journal shell, following the user's textured or Modern theme. The content inset blends into that shell without an additional black panel or accent bar.
- Contained navigation controls, a close button, character/expansion dropdowns, search fields, thin scrollbar thumbs, expansion buttons and auto-load checkboxes.
- Flat category cards, readable headings and a consistent quest-node surface. Completion, active/next, difficulty and quest-tag indicators keep their native visibility and behavior.
- Search previews/results and the addon's private options, character and breadcrumb popup lists use matching surfaces and controls.
- Expansion identity artwork remains visible. Quest dependency lines, graph positioning/zoom/drag, spoiler rules, completion animations, quest actions and data are untouched.
- Existing EUI per-addon toggle and deferred target loading. No target is loaded by the skin.

Dynamic category/search/graph UI is styled synchronously after its own completed navigation/update methods. Individual pooled quest nodes reapply their local styling after Set/Update. No global frame walks, polling or new OnUpdate handlers are added. Graph connector hierarchies are excluded entirely. Styling is deferred during combat and stops while disabled.

## Verification

Run `python3 scripts/package.py`. It validates Lua, all 17 suites, the Lua/Python skin catalogs, three client manifests and the one-folder archive. New fixtures cover deferred definition/activation, missing targets, native returns/actions, semantic indicators and connector exclusions, pooled categories/nodes, private lazy menus, search results, native colour retention, accent refresh, protected controls, combat deferral, disable and warm object/hook reuse. Manifest fixtures include a BtWQuests-only enabled configuration.

The ZIP contains 36 files under one `EUIAddonSkins/` folder, including all 22 skin definitions and the MIT LICENSE. Tests, docs and the original addon/database files remain excluded. Versions and release changelog remain unchanged until release preparation; identify this build by its branch and commit.

Automated fixtures do not establish in-game rendering, input geometry, taint safety or compatibility with other BtWQuests versions. Shared Blizzard tooltips and the minimap button are left native. No actual WoW client verification was performed.
