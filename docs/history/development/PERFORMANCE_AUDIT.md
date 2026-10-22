# Performance audit

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Audited all 19 runtime Lua files and all 14 integrations against the supplied addon sources and EllesmereUI API. Baseline: `a06eb20bd77e17136ea57e5fd10cc818a11bd44d` (0.7.1). Changes released in 0.7.2 and included in 1.0.0.

## Assessment

The addon is event-driven. Missing targets do not install skin hooks or create skin windows. There is no addon-owned continuous polling loop. The Dungeon Journal OnUpdate hook observes an existing worker that clears its script and hides itself after one update.

Idle overhead should be low; the relevant costs occur when windows load, render, scroll, or change theme. No numeric in-game CPU or FPS estimate is justified without the WoW client. Large window construction and whole-window native render callbacks still require traversal, and can produce bursts of work. These are coalesced into deferred passes; safe dynamic discovery takes precedence over skipping already-known branches.

Shells, accents, control styling and native hooks are created once per object. Weak caches are already used for Companion frames, accents, popup owners and RXP visual layers. Other caches retain discovered native frames for the session. WoW frames generally persist once created; changing those caches to weak tables alone would not reclaim native UI objects. No unbounded timer or duplicate-hook growth was found. Memory can grow with the number of distinct windows and controls actually created by supported addons; a long-running client session cannot be reproduced here.

Confidence is high for the tested callback/discovery behavior and moderate for client compatibility based on source review. Real client taint, secure execution, rendering, frame time and long-session heap behavior were not measured.

## Findings and changes

| Severity | Location | Cause and resolution |
| --- | --- | --- |
| Medium | Widgets.lua: H.Scan | Each scroll event scheduled a full integration refresh. Scrolls now coalesce a scan of their own subtree. Full refreshes supersede queued partial scans. Integrations with exclusion sets conservatively retain full refreshes, including ancestor exclusions. OnShow, OnClick and native renderer hooks retain broader discovery. |
| Medium | Auctionator.lua: Apply | Repaint searched all globals for configuration frames. Discovery now runs on installation, addon loading and the native configuration initializer; mixin hooks still remember newly constructed windows. |
| Medium | RXPGuides.lua: combat event | Every combat end rerendered native themes. Only deferred skin/theme work now resumes; skin traversal waits outside combat. Native redraw tint hooks remain synchronous to prevent border flashes. |
| Low | Widgets.lua: H.Fade | Warm visits rewrote alpha and allocated callbacks that duplicate-hook guards discarded. Existing zero alpha is left alone and the reset hook is created once. External redraws remain suppressed. |
| Low | Widgets.lua / ForeverCompanion.lua: traversal | Every leaf allocated a child list. Empty native child/region counts avoid enumeration tables; fallback APIs remain supported. Lists are not cached, so same-count child replacement remains discoverable. |
| Low | ForeverCompanion.lua: SkinNode | Repeated scans allocated refresh hook closures despite existing hooks. Closures are created only for available, unhooked methods; late methods remain supported. |
| Low | Menus.lua | Rebinding the same owner scheduled repaint; font and alpha writes repeated unchanged state. Stable bindings no longer schedule work, and setters check actual native state. Owner reuse/restoration and theme callbacks are preserved. |
| Low | RXPGuides.lua: theme wrapper | Return-packing helper was recreated on every call. It is now shared within the integration, preserving nil/multiple returns. |

No gameplay handlers, saved variables, dependencies, visual settings or supported skins were removed. Protected/forbidden frame guards, hook recursion guards, module toggles and EllesmereUI public styling calls remain in place.

## Integration review

| Integration | Review result |
| --- | --- |
| Forever Companion | Factory results/clicks preserved; warm hook allocations reduced. Selected tabs and BiS launcher retain native state. |
| Forever Dungeon Journal | Lazy windows and render hooks retained. Map/portrait exclusions preserved; one-shot quest worker checked. Shared fade/traversal improvements apply. |
| RestedXP Guides | Legacy/v2/Active Targets reviewed. Combat work deferred, unnecessary combat-end themes removed. Backdrop opacity/hidden states and profile/theme immutability retained. |
| Auctionator | Lazy auction/config/dialog discovery retained with bounded discovery triggers. Shared scroll scoping applies. |
| Spy | Protected target rows and attributes remain excluded; only visual layers and public options styled. Exclusion-aware scrolling retains full refreshes. |
| CrossGambling | Explicit owned windows and native render hooks retained; no gambling/chat handlers changed. |
| What's Training? | Spellbook child discovery and native refresh hooks retained; spell icons and semantic colors preserved. |
| ItemRack | Pooled controls, labels, set preview, selected icon and queue picker retained. Protected gear actions excluded. |
| KiwiFarm | Owned stats/menu controls only; no farming counters or tracking handlers changed. Stable menu binding avoids repeated popup scheduling. |
| Myslot | Public main frame only; multiline output retains native size and actions. |
| BugSack | Owned tabs/panel controls only; shared native tab hooks filter owned names. |
| Altoholic | Lazy panels, native tab selection and icon semantics retained. |
| Attune | Owned windows only; map/graph exclusions and progress semantics retained. |
| TwitchEmotes | Menu owner and renderer hooks only; no chat processing or emote artwork added. |

## Automated verification

All ten mock suites pass, with syntax compilation of every runtime Lua file. Coverage includes actual TOC loading of all fourteen modules, optional/missing addons and API, load order, toggles, live accents/themes, lazy/pooled controls, native actions, preserved returns, secure/protected exclusions, combat deferral, icons/maps, ItemRack labels, popup reuse/restoration and error isolation.

New tests verify scroll bursts coalesce, full refresh supersedes partial work, newly added and replaced children are styled, excluded ancestors are respected, disabled integrations do not traverse, fade hooks are not duplicated, native redraw suppression remains intact, late Auctionator config discovery works, and idle combat endings do not rerender RXP themes.

The package check verifies Core/TOC versions, required module paths, ZIP integrity, exact source bytes and canonical MIT LICENSE inclusion. Tests, benchmark fixtures and third-party reference sources are not packaged.

## Measured mock benchmark

`benchmarks/scan.lua` models 2,011 frames: a root plus ten groups of 200 children, one group being a scroll frame. After initialization it delivers 200 scroll events with timer flushing. Each visit fades a decorative texture. `scripts/benchmark.py` runs five isolated Lua 5.4 trials and reports medians. Garbage collection is stopped only during the measured loop to expose allocation churn; this is not retained heap or actual WoW memory consumption.

| Metric | 0.7.1 baseline | Optimized |
| --- | ---: | ---: |
| Host Lua CPU, seconds | 0.532969 | 0.023588 |
| Allocated heap with GC stopped, KiB | 78,651.383 | 747.852 |
| Frame visits | 402,200 | 40,200 |
| Child enumerations | 402,200 | 200 |
| Alpha writes after warmup | 402,200 | 0 |
| Full integration scans | 200 | 0 |
| Initial native hooks | 4,023 | 4,023 |
| Additional hooks during measured scrolling | 0 | 0 |

No new frames/textures are created in the measured warm loop. The benchmark deliberately concentrates repeated traversal and fading; its timing/allocation improvements cannot be extrapolated to overall addon CPU, FPS or every integration. Initial hook counts are unchanged. Exclusion-bearing integrations retain full scroll discovery and do not claim the same traversal reduction.

To reproduce, provide the addon directory from the baseline revision:

```sh
python3 tests/run_lua.py
python3 scripts/benchmark.py --baseline /path/to/baseline/EUIAddonSkins
python3 scripts/package.py
```

## Retained concerns

Full OnShow/click/native render refreshes are kept where sibling/lazy windows or changed selection may require discovery. Recursive traversal retains its existing depth limit. Incremental multi-frame painting and caching child lists would increase visible-update and compatibility risks.

Scoped font styling still calls the public EUI font helper when a native render may have reset style, shadow or color. A font-path-only cache would miss those changes. RXP still copies nested theme fields on native theme requests to preserve source/profile immutability and detect in-place native theme changes. Neither was replaced with an unsafe cache.

The actual WoW Forever client was unavailable. Visual identity, client-specific taint and real gameplay performance are supported by static/source review and mocks, not claimed as in-game verification.
