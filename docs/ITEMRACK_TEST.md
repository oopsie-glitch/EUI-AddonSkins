# ItemRack refinement

Branch: `skin/itemrack-refinement`, based on main. Untagged; no CurseForge or Wago upload. Other addon experiments remain separate.

- Options panels expose the EUI shell instead of stacked grey gradients and opaque nested panels. Independent hover/queue panels retain a matching surface.
- Classic sliders use flat tracks, usable horizontal thumbs and thin vertical scroll strips. Native ranges, values and actions remain unchanged.
- Checkbox borders follow their inset boxes; helm/cloak tristate check colours remain native. Equipment selectors remain equipment controls, not checkboxes.
- Set selectors and queue movement buttons use flat navigation controls. Native control positions and tooltip/click handlers are preserved.
- Options and hover-menu icons use consistent cropping with the baked action-slot bevel removed. Semantic borders, cooldowns, counts and checked states remain native. Protected controls are skipped.
- Queue/event/set row highlights use a subdued accent wash. Item-quality text colours and native highlight visibility are retained.
- Completed tab/menu changes style controls synchronously. Row updates repaint their list, individual highlight changes repaint their row; neither triggers a full options scan. No polling or global widget replacements are added.

Source shapes were checked against Rottenbeer/ItemRack's options and menu templates/controllers. Other forks may expose different layouts. No WoW client rendering or taint verification was performed.

`python3 scripts/package.py` checks all 16 suites, Lua syntax, catalogs/manifests and the 35-file one-folder archive with the MIT license. Regression fixtures cover native actions/returns, equipment versus checkbox treatment, gradients versus foreground art, slider geometry/ranges/reuse, dynamic menu items, local row callbacks, item colours/highlights, protected controls, combat deferral and disabled behavior.

Versions and changelogs remain at main's release version until release preparation. Test ZIPs are identified by commit. Shared runtime helpers, saved variables and external addon sources are unchanged; reference sources and development files are not bundled.
