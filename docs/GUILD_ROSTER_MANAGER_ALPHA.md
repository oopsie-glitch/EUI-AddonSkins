# Guild Roster Manager alpha

Branch: `skin/guild-roster-manager`, based on stable 1.5.2. Untagged; no CurseForge or Wago publication. The ZIP filename identifies this alpha; runtime version and release changelog stay at the stable base until release preparation.

## Scope

- Log, options, member details, roster, dialogs, export and macro-tool windows discovered through GRM's UI registry and construction helpers.
- Soft panels with a lighter centre on top-level windows, native-size themed fonts, accent-selected tabs and flat checkboxes.
- Legacy scrollbars, slider thumbs, navigation arrows, inputs, buttons and pooled dropdown menus.
- Native guild actions, drag/resize behaviour, checkbox and radio values, scroll ranges, export data and semantic text colours remain controlled by GRM.

## Lifecycle and performance

The adapter activates only when Guild_Roster_Manager is loaded and its skin is enabled. It observes GRM-owned construction helpers and completed UI phases, including lazy roster/export loading. Hooks run after native functions and preserve their results. No global frame factory replacement, guild-data scan, polling, OnUpdate or scroll-triggered full-window scan is added.

Warm OnShow discovery uses cached child counts. Factory bursts coalesce a completed-component pass; dropdown rebuilds style their own menu. Font resets are repaired locally. Combat defers styling until PLAYER_REGEN_ENABLED; protected frames and tooltips are excluded.

The mocked regression exercises native button/radio/dropdown actions, legacy scroll behaviour, lazy windows, initial tab selection, font resets, theme/accent changes, disabled skins and combat deferral. In this fixture, 100 pooled menu rebuilds add no UI objects or hooks, and 100 warm root shows cause no child traversal or font rewrites. These are simulation results, not in-game CPU or FPS measurements.

## Source review and limitations

Integration points were inspected in TheGeneticsGuy/Guild-Roster-Manager, Retail commit `79be399c35424a48456361c374bc591b68c88dd2` (GRM 1.99423). The AddOnSkins GRM adapter was reviewed for coverage only. This adapter is original external styling code; no upstream code, textures, fonts or other assets are bundled or copied.

The full project syntax/regression/package checks pass. No WoW client is available here: appearance, live guild permissions, client-specific templates and taint behaviour have not been verified in-game. Older GRM versions use feature detection; their visual coverage is not established by the Retail source review.
