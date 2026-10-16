# ItemRack refinement

Branch: `skin/itemrack-refinement`, based on main. Untagged; no CurseForge or Wago upload. Other addon experiments remain separate.

- Options panels expose the EUI shell instead of stacked grey gradients and opaque nested panels. Independent hover/queue panels retain a matching surface.
- Classic sliders use flat tracks, usable horizontal thumbs and thin vertical scroll strips. Native ranges, values and actions remain unchanged.
- Checkbox borders follow their inset boxes; helm/cloak tristate check colours remain native. Equipment selectors remain equipment controls, not checkboxes.
- Set selectors and queue movement buttons use flat navigation controls. Native control positions and tooltip/click handlers are preserved.
- Options, hover-menu and detached equipment icons use consistent square cropping and thin rarity-coloured edges. Empty slots retain Blizzard artwork with neutral edges. Existing missing-item warning borders, cooldowns, counts and checked states remain native. Set-editing selection has a separate accent marker.
- Detached quick-access buttons use a separate cosmetic-only path outside combat, restricted to exact ItemRack-owned button names. Lock/settings artwork references the installed EllesmereUI icons; queue and remove controls retain their native actions and tooltips. No secure attributes, native scripts, visibility, frame positions or state drivers are changed. General recursive scanning still skips protected frames.
- Queue/event/set row highlights use a subdued accent wash. Item-quality text colours and native highlight visibility are retained.
- Completed tab/menu changes style controls synchronously. Row updates repaint their list, individual highlight changes repaint their row; neither triggers a full options scan. No polling or global widget replacements are added.

Source shapes were checked against Rottenbeer/ItemRack and Bl4ut0/ItemRack-Universal. Universal detached buttons use `ItemRackButtonNItemRackIcon` (also exposed as `button.icon`/`button.Icon`); older `ItemRackButtonNIcon` names remain supported. Rarity colours use the global or modern `C_Item` API, then `ITEM_QUALITY_COLORS`; inventory IDs provide a quality fallback on clients without `GetInventoryItemQuality`. Completed custom-icon refreshes restyle only the owned equipment controls. No WoW client rendering or taint verification was performed.

`python3 scripts/package.py` checks all 16 suites, Lua syntax, catalogs/manifests and the 35-file one-folder archive with the MIT license. Regression fixtures cover native actions/returns, equipment versus checkbox treatment, gradients versus foreground art, slider geometry/ranges/reuse, dynamic menu items, local row callbacks, item colours/highlights, protected controls, combat deferral and disabled behavior. Detached-button fixtures additionally cover quality changes, neutral empty slots, separate editing selection, native secure actions/attributes, protected-parent hover menus, lock state, warm texture/hook reuse and zero full options scans during repeated equipment refreshes. Universal fixtures cover its icon names/fields, modern-only colour APIs, quality-table fallback, poor-quality versus empty slots, inventory-ID fallback, custom-icon refresh reuse and combat/disabled guards.

Versions and changelogs remain at main's release version until release preparation. Test ZIPs are identified by commit. Shared runtime helpers, saved variables and external addon sources are unchanged; reference sources and development files are not bundled.
