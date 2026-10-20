# Quest Completist alpha

Branch: `skin/questcompletist-initial`. Untagged; no CurseForge or Wago publication. Runtime remains at main's 1.5.2 until release integration.

## Coverage

- Attached Quest Completist 113.9, including its Retail and Camelot manifests.
- Native EUI shell without the portrait, top accent stripe or heavy outline; compact outer bounds around the existing controls. Readable theme fonts, flat category/filter buttons, search field, close controls, slim accent scrollbar and subtle quest-row hover.
- Options filters receive the clean checkbox treatment, preserving their native checked state, disabled state, scripts and hit areas. Options headings remain neutral.
- Owned category dropdown and submenus use the collection's existing owner-scoped menu adapter, including pooled restoration. The dropdown is discovered after native creation; the skin never opens it itself.
- Named quest/map/alert tooltips receive texture-only panel styling. Native fonts, inline icons, progress bars, quest/faction artwork and meaningful completion/status colours remain unchanged. Shared GameTooltip and map pins are not modified.

## Performance and verification

No skin OnUpdate, polling, database iteration, UIParent scan, global frame-creation replacement, forced addon load or full-window recursive scan. The target reuses 16 quest rows; the skin does not hook list/scroll/filter updates. Initial options construction is observed after the native handler. Further option discovery depends on changed child/region counts or a theme refresh.

`python3 scripts/package.py` checks Lua syntax, all 23 regression suites, catalogs/client manifests and the 40-file single-folder archive with the exact MIT license. The new fixture covers native search/clear/filter/menu/scroll/click behaviour, semantic colours/icons, lazy and new controls, missing/protected frames, theme updates, disabled skins and combat deferral. It models HookScript independently of SetScript, as the native options handler replaces its own OnShow callback after construction.

Mock benchmark: 1,000 repeated list/scroll/window/options cycles produce zero additional skin UI objects, hooks, font writes or hierarchy reads after setup. This is simulated, not an in-game CPU/FPS measurement. Actual WoW appearance and taint behaviour are not established by automated tests.

Reference sources were inspected for frame identities and lifecycle only. No target addon code, ElvUI integration code, external libraries or assets are bundled. Implementation uses EllesmereUI's public skin API and existing collection utilities.

Input archive SHA-256: `1c1c486c8fb4c5a143f7e2481cd6e541c8ba84cbe65c36d25764da7bfdbf2796`.
