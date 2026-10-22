# Skin engineering checklist

Use this guide for every new integration and when revisiting an existing skin. Keep addon-specific behaviour in its adapter. Changes to shared helpers need caller review and regression coverage for affected and unaffected integrations.

## 1. Establish ownership and lifecycle

- Inspect the target's actual version, constructors, completed page/window builders, native refreshes, pools and release/reset paths. Record source versions in the task report. Screenshots show appearance, not the full lifecycle.
- Identify owned windows, controls and popup owners. Never scan UIParent, enumerate every global on interaction, or replace global CreateFrame/AceGUI factories.
- Use EllesmereUI's public skin API. Guard optional exports and client-specific APIs; keep an understandable fallback. Do not transplant another addon's code or assets without the required permission and attribution.
- Register the definition through the existing loader. Missing/disabled targets must not activate; support enabled load-on-demand targets without force-loading them. Check current-character enable state, late API/target arrival and load order.
- Keep all client TOCs, Loader.lua and scripts/skin_catalog.json consistent. Adding a TOC does not establish that the target itself supports that client.

## 2. Classify callbacks before adding hooks

| Callback | Preferred scope | Regression to add |
| --- | --- | --- |
| Completed window/page construction | Discover the owned completed subtree | Lazy children, same-count replacements and first-show styling |
| Repeated constructor/FeedGroup bursts | Coalesce discovery for the relevant owner/container | A burst performs bounded scans; no duplicate hooks |
| Click, check state, hover, disabled state | Repair that control's cosmetics | Native actions/state preserved; no whole-window refresh |
| Scroll/pool update | Current rows or the scrolling subtree | Recycled rows, smaller reopened menus and new rows |
| Tab selection | Completed selected page and navigation | No hidden-page scans, HUD refresh or delayed style flash |
| Theme/accent/manual refresh | Invalidate relevant visual state, then refresh eligible owned UI | Existing and lazy controls, disabled/combat transitions |
| Gameplay/data/countdown update | Avoid skin work unless native cosmetics actually change | Warm updates add no scans, objects, hooks or font writes |

Follow the full call path, not just hook names. A single tab action can nest ShowTab, DisplayFrame, UpdateMenuFrame and OnShow. Consume/coalesce redundant work without delaying the final completed-page styling. Blindly deferring everything can produce visible native-to-skinned flashes.

### H.Scan and hidden roots

- H.Scan discovers new controls; its style guards do not make recursive traversal free. Count root calls **and** children/regions visited.
- Shared queues should merge bursts; a pending full pass should supersede partial passes. Preserve excluded ancestors when scanning subtrees.
- Scan an unknown hidden root once to bind discovery/show handling; skip repeat warm walks while it remains hidden. Showing it must discover controls added while hidden. Preserve fallback behaviour when IsVisible is unavailable.
- This visible-root policy was contributed by [AngelosNaoumis in PR #2](https://github.com/oopsie-glitch/EUI-AddonSkins/pull/2), implemented in Scoped.lua and covered by tests/batch_spec.lua and benchmarks/scoped.lua. It applies to scoped callers, not automatically to every bespoke skin.
- Child counts alone cannot detect a replacement with the same number of children. Invalidate at completed construction/reacquisition points; use native current-row budgets and ownership, not historical maximum pools.
- Keep GUI navigation independent of timer/HUD repaint. DBM's direct new-timer lookup must not enumerate its active pool; countdowns must not gain styling Update/OnUpdate hooks.

## 3. AceGUI, shared widgets and menus

AceGUI is not inherently the performance problem. Recursive skin work inside each normal construction/state callback causes scan bursts, and pooled widgets can later belong to another addon.

- Filter AceConfig application IDs and owned containers. Bind completed Open/FeedGroup paths only for the target; unrelated feeds must do no traversal.
- Acquire once per ownership session. Reuse skin art and hooks; inspect actual native resets instead of assuming a previously skinned widget stays styled.
- Snapshot only cosmetics the adapter changes. Restore them and hide added art on release, reset, hide or owner transfer as appropriate. Cleanup must still run after the skin is disabled.
- Do not retain stale owners or keep restyling foreign widgets through old hooks. Recheck current ownership, settings and combat state when queued callbacks execute.
- Avoid native FontObject capture/reassignment on shared controls. CraftSim crash reports identified EditBox:SetFontObject as a native stack-overflow trigger; the fixtures now reject that restoration path. AWQ/LiteMount and DBM received related preventive hardening. This does not prove identical crashes occurred in those skins.
- Preserve native fonts for borrowed Settings rows, shared confirmation dialogs and pooled menu inputs where the integration requires texture-only styling. Owned labels can use guarded concrete font styling.
- Menus can rebuild while visible, change owner, shrink their active row count or reset their textures after Show. Cover those lifecycle points, not just first creation. Style current active rows and restore foreign reuse.
- Modern Blizzard compositor regions restrict operations. Never index/call forbidden SetFont methods or create raw regions on managed controls. Use supported attached-texture/initializer APIs; keep native fonts unless a verified supported path is needed. Older isolated menu implementations are not a template for new shared controls.

## 4. Fonts, callbacks and native input

| Past failure | Check and prevention |
| --- | --- |
| FontString:SetText(): Font not set | Establish a valid font before populating an owned new FontString; preserve native initialization order |
| `.icon` is a number, or a field is a function | Validate object type/method availability before indexing; asset IDs, callbacks and regions are different values |
| Attempt to yield across a C-call/metamethod boundary | Preserve coroutine-capable constructors and direct return paths; do not wrap a yielding target call in pcall/xpcall or an incompatible hook boundary |
| Recursive font hooks / native stack overflow | Use re-entry guards, compare actual fonts, avoid borrowed FontObject restoration and model reset/release paths |
| ItemRack set editing/save stops working | Font/layout writes can trigger OnTextChanged and native validation. Do not rewrite unchanged inputs or their internal text regions; test the editing flow, not just appearance |
| Details anchor dependency cycle | Clear the managed anchor graph before native restoration; anchor sibling controls independently to an owned host |
| Details baseframe is nil | Iterate only initialized native instances and guard optional/incomplete windows during restore |
| Grey enabled buttons or labels reverting | Follow native enabled/disabled state and later template/FontObject resets; repair only the current owned label |
| Double labels, clipped checks, dead dropdown arrows | Avoid painting duplicate native/skin labels. Contain artwork within the native slot and preserve hit/drag regions and callbacks |

Post-hooks must preserve native arguments, nil-containing multiple returns and receiver identity. Do not call target data/render actions from a cosmetic refresh. Do not hide errors with broad catches around unsupported operations; model the failing operation and prevent it.

## 5. Layering, appearance and secure UI

- New fills belong behind content on the correct owned frame. A high-level sibling can cover text, rows, graphs and click targets even if its draw layer is BACKGROUND. Do not classify every anonymous backdrop/border as a filled panel.
- CraftSim's queue/list overlays established this failure mode. Exclude graph/model/data canvases; retain grid/curve/axis/hover art, selection, validation and status textures. Test raised sibling layers, late wrapper assignment and multiple opacity/frame-level combinations.
- Keep added art non-interactive. Preserve native click targets, edit-box insets where needed, slider ranges/drag areas, secure attributes, scripts, visibility and state drivers.
- Respect forbidden/protected/secret-value guards and combat lockdown. Queue eligible work for combat recovery; do not force-load optional UI or add continuous polling.
- Preserve meaningful colours: warning/danger, class, rarity, status, selected/disabled states and raid-mechanic indicators. Use accents for controlled decoration rather than overwriting data semantics.
- Keep one cohesive background, readable text and bounded highlights. Opacity must work at 0/100%; avoid accidental stacked fills. Background contrast, clean checkbox art, contained icons and active-tab emphasis should match the host UI without changing layout ownership.
- Texture/geometry caches must survive native redraws and allow theme changes. Weak tables alone do not reclaim native WoW frames; distinguish native pool growth, temporary allocations and retained skin state.

## 6. Required automated verification

Run `python3 scripts/package.py` on the complete final tree. It compiles runtime Lua, executes the registered suite and validates manifests, versions, all skins/assets, the exact MIT licence and the single installation folder. Inspect the diff and the archive; a passing individual branch is not a passing combined release.

Choose source-shaped fixtures from tests/run_lua.py and extend the relevant integration suite. For shared changes, inspect every caller and test both the existing default and any new opt-in path.

- Cold initialization, absent/wrong target, missing API, late libraries and target/API load-order changes.
- Warm repeated show/hide, tab selection, scrolling, native redraw and same-count child replacement.
- Control acquisition, release, shrink/reopen and foreign reuse; cleanup after disabling.
- Native return values, actions, settings, text editing, validation, selected/disabled state, tooltips and arrow hit targets.
- Theme/accent changes, explicit refresh, combat deferral/recovery and disabled-to-enabled transitions.
- No duplicate hooks or unbounded visual objects. Measure root scans, node/region reads, font/geometry writes and UI object creation during representative repeated work.
- Regression sensitivity: where feasible, check that reverting the intended fix fails its assertion. Do not disable functional assertions to obtain better benchmark numbers.

Use [benchmark workloads](../benchmarks/README.md) for comparative measurements. Report source versions, workload, warmup, trial count and whether each number is a mock operation count, host timing, temporary allocation or actual client measurement. GC-stopped heap growth is allocation churn, not retained memory. Never convert a mock speedup into an FPS claim.

## 7. Record the result and prepare integration

For each task, record scope, source/client versions, changed callbacks, shared-code impact, tests, measured results and unresolved concerns in its PR or focused report. Link the relevant regression and update this guide when a new failure class is learned. Keep raw crash reports, tokens and personal/system data out of Git.

Keep reports concise: current behaviour, reason, evidence and limitations. Historical alpha narratives belong in history/development. Preserve genuine contributor attribution and required licence notices; omit unrelated comparison-skin names from implementation comments.

Do not use mocks to claim actual rendering, taint safety, native-crash prevention, FPS or long-session memory verification. Where the client is unavailable, finish feasible source/test/package checks and explicitly retain the limitation. Follow [the release procedure](RELEASING.md); ordinary maintenance pushes must never publish a version.
