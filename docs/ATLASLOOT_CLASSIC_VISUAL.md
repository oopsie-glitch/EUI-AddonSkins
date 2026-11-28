# AtlasLoot Classic visual pass

Draft PR #105 is stacked on PR #104 at `95c2d6b3b2a512aef03d8242d07f1418e3eb3b27`. PR #69 is excluded.

## Source and ownership

The reference is AtlasLootContinued Forever 13014:
https://github.com/user-attachments/files/35548736/AtlasLootContinued-Forever_13014.zip

SHA-256: `f3a7ffc65480a92c7b18961409087d9b2f83b1bf9d942fcd230b3cc28d479a1d`.

The source and its media are not bundled. GitHub Actions retrieves and verifies the exact archive for source/lifecycle checks. No upstream files are modified.

The displayed mode is still determined by `GUI.Nav.active`, not pending `db.GUI.style` or `GetLook()` selections. The independent Favourites `NavStyle.applied` exclusion remains. Source-specific tests cover cancelled reload prompts, navigation initialization/fallback, pending callbacks and combat recovery.

## Visual changes

- Reuse `contentFrame.topBG`, `itemBG` and `downBG` for cohesive EUI matte RGB from the public `GetPanelColor()` source.
- Preserve native `mainFrame.bgColor.a`, title alpha and the three separate content alpha settings, including zero. Never write SavedVariables.
- Retain optional native content background images, map/model artwork, expansion logo and item overlays.
- Replace only decorative backdrop fills with WHITE8X8 and existing thin, subdued EUI borders.
- Keep title and popup surfaces out of the generic panel painter so a second fill cannot obscure the native opacity.
- Use the public Button helper on each dropdown field and the existing SoftPageButton helper on its native arrow button. There is one arrow; native click targets/actions stay in place.
- Soften boss/difficulty/extra selection wash from 20% to 12% accent. Keep native semantic text, selection coins, row dimensions and order.
- Use the existing Button helper for AtlasLoot's text controls; keep footer/search/page anchors and native actions unchanged.

No new runtime frames or textures are explicitly allocated by this pass. EUI primitives may retain their normal cosmetic resources; warm object/hook growth is checked. No global fonts, shared helper changes, polling or OnUpdate handlers were added.

## Refresh and validation

Two additional owned native completion paths are observed: RefreshContentBackGround invalidates only the three existing surface colors, and RefreshMainFrame requests the existing coalesced refresh. Both inherit the Classic/enabled gate. Background writes are cached until a native repaint, opacity change or EUI panel-color change. Native artwork selection remains authoritative.

`tests/atlasloot_visual_cases.lua` asserts EUI color sources, independent opacity, background-image preservation, native footer geometry, semantic colors, no warm surface writes, no hook/region growth, theme refresh, combat deferral and navigation isolation. The source runner injects the real 13014 background repaint and mode-selection/revert functions into the fixture.

The hosted comparison runs five fresh Lua 5.4 states per variant with the same native control tree, against the verified PR #104 baseline. It measures 1,000 warm opens, font writes, root scans, retained Lua memory, added root regions/hooks/listeners. This is synthetic host evidence, not WoW FPS, GPU cost, screenshot parity or proof of live taint safety.

## In-game acceptance

1. Open Classic: inspect header/body/footer consistency, dropdown arrows and popup lists.
2. Navigate loot and boss lists; check hover, selected rows, rarity/boss/difficulty colors, scrollbars and native actions.
3. Test search, page navigation, models/maps and optional background images.
4. Change opacity, theme/accent, UI scale and window size; confirm readability and no clipping.
5. Switch through Classic, Forever Bronze, Atlas Nav and back, including cancelled reload prompts and actual reloads. Both navigation looks must remain fully native.
6. Reopen repeatedly and test combat entry/recovery with Lua errors enabled.

Visual acceptance remains pending actual WoW testing. Nothing is merged, tagged or published.
