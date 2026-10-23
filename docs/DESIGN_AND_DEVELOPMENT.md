# EUI AddonSkins Design & Development Standard

This is the starting point for adding or changing a skin. The goal is a cohesive EllesmereUI appearance with the target addon's behaviour, content and layout ownership preserved. A skin that looks correct but breaks input, obscures content or repeatedly scans gameplay UI is incomplete.

## Read before working

Read [AGENTS.md](../AGENTS.md), this standard and the relevant sections of the guides below. Inspect the current target source and relevant implementation/tests before editing. A new session should not need the old conversation to establish these defaults.

| Subject | Authoritative document |
| --- | --- |
| Visual identity, reference choices and completion criteria | This standard |
| Ownership, callbacks, performance, AceGUI, fonts, secure UI and regression cases | [ENGINEERING.md](ENGINEERING.md) |
| Branches, shared-code changes and integration | [CONTRIBUTING.md](../CONTRIBUTING.md) |
| Tags, packaging, distribution and publication | [RELEASING.md](RELEASING.md) |
| Repeatable performance workloads and their limits | [benchmarks/README.md](../benchmarks/README.md) |
| Selected promotional images | [screenshots/README.md](../screenshots/README.md) |

Keep each rule in its owning document; link it instead of maintaining competing checklists. Update the engineering guide when a new failure class is learned. Historical reports record old evidence, not current pending work or authority to revive an experiment. Current task instructions can refine a skin's appearance or scope; record lasting accepted exceptions with that integration. Do not treat an old mockup as overriding newer accepted code or feedback.

## Visual identity

### Windows, backgrounds and borders

- Use cohesive dark matte surfaces, with readable separation between content and controls. For options/list windows, a subtly lighter centre fading toward darker corners can improve contrast. Avoid unreadable near-black blocks, shiny fills and stacks of unrelated black panels.
- Reuse EUI primitives and the existing soft treatment. Prefer filled controls and contrast over light-grey outlines around every element. Thin subdued borders are appropriate where the existing Settings treatment or an accepted skin requires them; there is no blanket borderless rule.
- Preserve intentional opacity controls. Change background opacity without fading labels, icons or data. Check both transparent and opaque extremes and avoid stacked fills. Existing per-addon defaults remain authoritative; do not impose one opacity everywhere.
- Do not add a main-window top accent stripe by default. Prefer restrained selected-tab emphasis, small active indicators and controlled header text. Preserve deliberate per-skin exceptions and existing switches.
- Place fills behind content on the correct owned frame. A background-layer texture on a raised sibling can still cover text, graphs or clicks. Do not turn data canvases, model frames or every anonymous border into filled panels.

### Typography, spacing and controls

- Resolve fonts through the current skin API/shared helpers. Preserve meaningful text colours and hierarchy. Borrowed Settings rows, restricted menus and shared inputs may require native fonts; follow the ownership rules in the engineering guide.
- Keep native positioning, window sizes, control spacing and customization unless the task specifically authorizes layout changes. Match local baselines, padding and icon/text alignment to the relevant accepted reference. There is no established universal pixel spacing or font-size scale; do not invent one or reuse screenshot dimensions as runtime requirements.
- Use compact square checkbox artwork with a small accent-filled indicator. Preserve checked/unchecked/disabled state, native hit areas and label spacing. Avoid oversized ticks, clipping and duplicate labels.
- Use slim scrollbar artwork with a proportionate visible grip. Keep a usable native drag/hit area even when the painted grip is narrower. Retain arrows and wheel behaviour where present.
- Buttons need readable enabled/disabled contrast and a restrained hover state. Verify state after clicks and page rebuilds; enabled buttons must not remain grey. Use existing labels rather than painting a second copy over native text or texture lettering.
- Align quantity, price and duration inputs with adjacent labels/currency art. Cosmetic writes must not retrigger validation, overwrite input or disturb cursor/selection.
- Keep icons square/cropped where appropriate while retaining rarity borders, cooldowns, counts, empty-slot art and gameplay overlays. Do not add decorative markers that resemble state indicators.
- Keep logos inside their header bounds. Removing a logo or centring a title is an integration-specific decision, not a global requirement.

### Accent and theme synchronization

Use the current EUI theme/font/accent sources rather than copying a fixed palette into a new adapter. [Accent.lua](../EUIAddonSkins/Accent.lua) resolves Window Skins' custom accent and accent-bar visibility where applicable. Respect those settings and existing per-skin controls; do not modify EUI's saved settings.

Refresh existing and lazily created owned controls when looks change. Invalidate visual caches as needed without recreating art or repeatedly writing unchanged geometry/fonts. A completed new page should appear styled on first display, without a delayed native-to-skinned flash.

Keep warning, danger, class, rarity, quest/status, disabled and raid-mechanic colours meaningful. Accent is decoration, not a replacement for semantic colour. Branding colours in the addon title/icon are not a universal widget palette.

## Architecture and consistency

| Responsibility | Reuse/inspect |
| --- | --- |
| Definition registration, target enable/load gating and diagnostics | [Loader.lua](../EUIAddonSkins/Loader.lua), [Core.lua](../EUIAddonSkins/Core.lua) |
| Guarded control styling, owned subtree scans, queues and softened primitives | [Widgets.lua](../EUIAddonSkins/Widgets.lua): `CreateSkinHelper`, `CreateSoftSkin` |
| Explicit owned roots and lifecycle/refresh routing | [Scoped.lua](../EUIAddonSkins/Scoped.lua): `RegisterScopedSkin`, `SkinRoots` |
| Accent settings and look changes | [Accent.lua](../EUIAddonSkins/Accent.lua) |
| Shared menus/dialogs and restoration | [Menus.lua](../EUIAddonSkins/Menus.lua) |
| Meters and Details-specific configuration/layout | [MeterStyle.lua](../EUIAddonSkins/MeterStyle.lua), [DetailsSettings.lua](../EUIAddonSkins/DetailsSettings.lua), [DetailsLayout.lua](../EUIAddonSkins/DetailsLayout.lua) |
| Target-specific ownership, exceptions and hooks | [Skins/](../EUIAddonSkins/Skins/) |

Retain the `RegisterSkinDefinition` factory and current loader conventions. Use scoped registration when it fits the actual lifecycle; a complex adapter may need explicit owned callbacks. Inspect helper signatures and callers rather than guessing from their names. Existing helpers are not permission to scan every target root after every interaction.

Use EUI's public skin API, guard optional exports and avoid duplicating an existing native EUI skin or shared function. Keep target-specific detection/layout in the adapter. Shared extensions should be small and opt-in where appropriate, preserving defaults for other integrations. Follow the caller-review and regression requirements in CONTRIBUTING.md and ENGINEERING.md.

Style relevant owned dropdowns, confirmations, tooltips and lazy popouts as well as the main window. Preserve native actions, settings, warnings, navigation, drag/resize behaviour, secure attributes and return values. Temporary styling must be ownership-aware and clean up on release/foreign reuse, including after disabling the skin. Never globally repaint shared tooltips or replace AceGUI factories to solve one integration's problem.

## Reference implementations

These are references for the named treatment, not universal templates or claims that every path is flawless. Read the associated tests and target-specific exceptions. Choose the closest lifecycle as well as the closest appearance.

| Treatment | Reference | Preserve/avoid |
| --- | --- | --- |
| Refined AH/profession controls, prices and settings | [Auctionator.lua](../EUIAddonSkins/Skins/Auctionator.lua) | Native commerce/input actions and numeric alignment |
| Options hierarchy, selected navigation and separate HUD presentation | [DBM.lua](../EUIAddonSkins/Skins/DBM.lua) | Native bar placement/size/spacing and encounter colours; GUI navigation must not repaint timers |
| Options surfaces and modular meter/menu choices | [Details.lua](../EUIAddonSkins/Skins/Details.lua), Details helpers above | Independent Tiny Threat choice, safe native layout restoration |
| Soft controls, calendar/header hierarchy and state-aware text | [Altoholic.lua](../EUIAddonSkins/Skins/Altoholic.lua) | Semantic calendar state; lazy pages and menu ownership |
| Settings controls, legacy scrollbars and square rarity icons | [ItemRack.lua](../EUIAddonSkins/Skins/ItemRack.lua) | Secure actions, set editing/save and unchanged-input write guards; no main top stripe |
| Borderless main controls, contextual Settings borders and modern menus | [Myslot.lua](../EUIAddonSkins/Skins/Myslot.lua) | Restricted menu fonts and private/shared dialogs stay within their supported styling paths |
| Collection windows, scrollbars and background opacity | [AllTheThings.lua](../EUIAddonSkins/Skins/AllTheThings.lua) | Collection colours and current rows; opacity changes must not scan all rows |
| Owned popup lifecycle and configurable appearance | [KiwiFarm.lua](../EUIAddonSkins/Skins/KiwiFarm.lua), [RXPGuides.lua](../EUIAddonSkins/Skins/RXPGuides.lua) | Reopen/reset/foreign reuse; RXP arrow is an accepted separate design, not a general icon template |

The [gallery](../screenshots/README.md) provides captured visual evidence. Theme, configuration and target version can differ; images alone do not prove behaviour or replace source inspection.

## Task workflow and verification

1. Establish the selected task, target version/client and actual source. Inspect existing EUI coverage, the closest reference and relevant fixtures. Identify windows, lazy/pool paths, semantic art and native actions that must survive.
2. Create a focused untagged branch from current main using CONTRIBUTING.md. Implement the bounded change, reuse helpers and review shared callers where needed. Do performance/error review as part of the task, without waiting for a separate request.
3. Apply ENGINEERING.md's relevant regressions: first show and late initialization, warm reopen/tab/scroll/redraw, pool release/foreign reuse, input/state preservation, theme/accent, toggles and combat recovery. Missing/disabled targets and optional APIs must remain safe.
4. Run `python3 scripts/package.py` on the final tree. It checks Lua, registered regressions, catalogs/manifests, versions, required assets/license and the installation ZIP. Keep the Lua loader catalog, Python skin catalog and all relevant client TOCs consistent when adding a skin. Follow RELEASING.md for exact archive requirements and exclusions.
5. Inspect the complete diff and built archive. Run relevant benchmark workloads when performance changes; report operation counts/host measurements as such. Mocks do not establish actual rendering, taint safety, FPS, crash freedom or client compatibility. Finish feasible checks independently and state remaining limitations.
6. Commit/push and prepare the focused PR; use a draft for unfinished or awaiting-feedback work. Require GitHub validation before integration. Supply an install-ready test ZIP when useful, labelled by branch and commit; it is not a tagged release. Record scope, source/client versions, evidence and unresolved concerns in the PR.

Retail and Forever support are target/version-specific. A TOC entry, Classic similarity or a user's Retail fork does not certify the original addon for another client. Do not turn missing upstream assets into an unrelated porting task. Check protected/forbidden/secret-value paths and combat deferral as described in ENGINEERING.md; do not force-load optional UI or use continuous polling.

## Working procedures and publication boundary

- Carry out routine authorized inspection, implementation, testing, commits, pushes and PR preparation without making the owner operate Git manually. An analyze-first request stays analysis-only; stop/hold instructions preserve unfinished work without resuming it later automatically.
- Visual acceptance of one build is not authority to merge unfinished runtime or publish it. Main retains the validated release runtime; selected runtime changes are combined and checked through the release procedure. Documentation maintenance can integrate independently through a validated PR.
- Respect protected-main PR/check requirements; do not bypass them, force-push main, discard unmerged work or alter published tags. No automatic AI/bot co-author trailers or invented contributors; retain legitimate attribution and required notices. Verify commit identity.
- Never create/push publication tags or upload releases to CurseForge/Wago without explicit owner instruction. “Make an alpha” or “looks good” does not alone authorize publication. No tag is needed for a local test ZIP. Check active task/release pins and paused work before release selection.
- Licensing changes require their own agreed terms/review; documentation consolidation does not authorize relicensing. Keep current license checks intact and revisit deferred licensing alongside substantive release work, not a license-only release.
- Gallery submissions belong under `screenshots/<addon>/` with descriptive names and an updated gallery index. Preserve original image bytes unless editing is requested. Distinguish promotional submissions from troubleshooting/reference screenshots; do not automatically publish every supplied image. Keep the whole folder excluded from packages. A stopped upload remains stopped until requested again.
- Keep public text and runtime labels in English, concise and factual. Avoid repetitive branding, conversational development narratives and gratuitous comparison-project mentions. Preserve meaningful technical comments and provenance. Brief progress/completion reports should distinguish local, pushed, merged, tagged and published states and clearly label test evidence.

## Completion criteria

A skin is ready for feedback when the requested surfaces follow this standard, native behaviour is preserved by source review and relevant regressions, feasible performance/error checks are complete, package validation passes, and its branch/PR/build identity and limitations are clear. Visual/in-game feedback can still be outstanding; say so. Readiness for feedback, readiness for integration and explicit publication approval are separate states, not interchangeable claims.
