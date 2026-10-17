# DBM skin reference review

Reviewed on 2026-10-17 while HUD alpha.7 was being evaluated. No reference implementation or assets were copied into the addon.

## Pinned: review before release packaging

The user requested a reminder before this DBM alpha is prepared for release if useful follow-ups remain unfinished. Check implementation and tests, update this list, and bring up outstanding items before release packaging/publication. Iterative alpha test ZIPs do not consume this reminder.

- [ ] Theme current DBM range/radar windows through EllesmereUI, after verifying current frame/API behavior.
- [ ] Theme the current DBM information window, using targeted lifecycle hooks and reusable styling.
- [x] Separate ordinary GUI navigation/control refreshes from HUD repaints, retaining theme/accent updates, late loading, manual refreshes and enable transitions; covered by alpha.23 regressions.
- [x] Reuse timer skin objects and install per-object lifecycle hooks once.
- [x] Discover new timers directly instead of scanning the whole active pool on creation; protect with a creation-burst regression.
- [x] Keep countdowns free of added Update/OnUpdate hooks and polling; retain the simulated countdown regression.
- [x] Keep warning icon changes scoped to DBM-owned text and guard secret text.

Preserve these boundaries: use EllesmereUI APIs, keep native DBM positioning/row spacing/configured sizes under user control, and implement independently rather than copying protected reference code. The old boss-health implementation requires a current supported target before it can become an actionable item.

## Sources

- [Azilroka AddOnSkins DBM integration](https://github.com/Azilroka/AddOnSkins/blob/main/AddOnSkins/Skins/AddOns/DBM.lua), reviewed blob `148022bbe6d7baa2fac6574a6fb7092e998371db`.
- [Cataclysm 4.3.4 DBM integration](https://github.com/ElvUI-Cataclysm/ElvUI_AddOnSkins-4.3.4/blob/master/ElvUI_AddOnSkins/Skins/Addons/DBM.lua).
- Azilroka's core registration, skin helpers and license, plus the current DBM timer lifecycle already reviewed for the HUD implementation.

## Findings

| Pattern | References | EUI AddonSkins decision |
| --- | --- | --- |
| Per-object ApplyStyle hook | Both integrations follow DBT restyling and guard installation | Retain our existing once-per-object hooks and UI object caches |
| CreateBar pool traversal | Both enumerate all active bars to discover unhooked objects | Keep direct GetBar(id) lookup; no active-pool traversal on timer creation |
| Countdown Update hook | Azilroka adjusts its half-bar spark on each Update | Keep our countdown path untouched; the spark is suppressed and fill tint follows the native texture |
| DBT skin profiles | Azilroka registers/selects a DBT skin and supplies height, icon-lock and half-bar spacing options | Do not import profile selection or spacing overrides; DBM settings remain user-controlled |
| Icon backgrounds | Guarded reusable icon backdrops, explicit left/right visibility | Our cached borders and native icon shown states already provide this |
| Half-bar layout | Azilroka places text above the bar and enlarges spell icons | Confirms DBT permits alternate layouts; our concept panels are independently implemented and fit native row space |
| Additional HUD windows | Range/radar and information frames in Azilroka; boss-health frames in the old Cataclysm skin | Add range/radar and information windows to the interface review; verify current APIs before implementation. The current DBM source tree has range and information modules, but no matching legacy boss-health module |
| Warning icon text | Old Cataclysm skin replaces the global RaidNotice_AddMessage function | Keep our DBM-owned font-string hooks, exact plain-icon matching and secret-text guards |
| GUI load timing | Old skin has a separate DBM-GUI callback and hardcoded historical widget names | Retain lazy GUI discovery; do not transplant old frame names or owner.options access |

## Performance assessment

No runtime change was justified by copying these approaches. Our direct creation lookup avoids the references' repeated pool walks, and our existing countdown regression checks for no added skin allocations, font writes, hooks or hierarchy reads over 1,000 simulated ticks. The new creation-burst regression checks 25 new timers with zero active-pool enumerations and only the four expected font writes per new timer.

These are mocked operation counts, not live CPU/FPS measurements or timings. The references' per-creation traversal has cumulative growth as the active timer pool grows; no numerical speedup over either addon is claimed.

A separate candidate remains in our implementation: the scoped GUI hooks call the HUD refresh, so an options-page refresh can repaint existing timers and aura previews. Removing that coupling needs coverage for theme changes, late-loaded APIs, manual refreshes and enable transitions. It is recorded for the DBM performance pass; alpha.7's runtime is unchanged by this review.

Completed in alpha.23: navigation and control callbacks now repaint the selected page/sidebar without entering the full GUI/HUD refresh. Full/manual/theme/load refreshes still run HUD discovery; hidden pages style when shown. The new simulated navigation regression checks 100 callbacks with zero active timer-pool walks or font writes. See [DBM GUI performance](DBM_GUI_PERFORMANCE.md) for scope, baseline counts and limitations. Range/radar and information-window styling remain pending.

Azilroka's custom license restricts modifications and reserves other rights. The older repository does not establish permission to transplant its code merely by being public. This review retains implementation ideas and API observations only; project licensing is unchanged.
