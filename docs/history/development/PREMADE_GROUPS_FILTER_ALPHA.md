# Premade Groups Filter alpha

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Branch: `skin/premadegroupsfilter-initial`. Untagged test build based on v1.5.2.

## Coverage

- Matte main filter window without a top accent stripe, themed close/minimize controls and readable labels.
- Compact accent checks, min/max inputs, legacy difficulty selectors and modern scrollbars.
- Dungeon, raid, arena, rated battleground, role, minimized-expression and Delve panels discovered through the addon's panel registry.
- Advanced-expression and sorting inputs retain native focus, text, limits and callbacks.
- Shared custom dropdown menu, reset/confirmation window and virtualized Settings rows.
- Bountiful Delve colours, availability, warning icons, filter logic and native positioning remain controlled by the target addon.

Toggle in EllesmereUI's Blizzard Skins+ third-party skin list. Install Premade Groups Filter separately.

## Implementation and validation

Reviewed current upstream tree `fe2885d99c5808d73d5fcb9f1cbcaa8a33435620` from https://github.com/0xbs/premade-groups-filter. Original adapter; no target code, external skin code or assets bundled.

Styles static owned trees once per theme generation. Completed panel registration/category changes handle new panels. PGF's completed popup initializer repairs its native per-open font reset. The settings list's `OnInitializedFrame` callback styles new recycled controls after their native initializer. No search-result hooks, polling, global factories or recursive scroll callbacks.

`python3 scripts/package.py` validates syntax, all 23 test suites, manifests, version consistency and the one-folder install archive. Targeted mocks cover native actions/returns/values, compact checkbox geometry, dynamic panels/menu entries/settings rows, theme updates, disabled/protected gating and combat deferral. In 100 warm opens/category switches, extra hierarchy reads, font writes, objects and hooks are all zero. These are simulated operation counts, not in-game CPU/FPS measurements.

No WoW client is available here. Automated checks do not establish in-game appearance or taint safety. Runtime version stays 1.5.2 until release integration; the ZIP filename identifies this alpha.

This build contains only this branch's changes. Other unmerged alpha skins are excluded. No tag, GitHub Release, CurseForge or Wago publication is created.
