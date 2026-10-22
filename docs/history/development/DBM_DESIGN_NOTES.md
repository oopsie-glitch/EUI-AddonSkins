# DBM design and lifecycle checks

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Completed implementation review, included in the stable DBM skin. This is a historical record, not a pending-release checklist.

- Reuse each timer's visual objects and install lifecycle hooks once.
- Discover a new timer directly; creation must not enumerate the active pool.
- Add no countdown Update/OnUpdate hooks or polling. The mock regression exercises 1,000 ticks without added objects, hooks, font writes or hierarchy reads.
- Keep GUI page/control navigation separate from timer, warning and auxiliary-frame refreshes. Full theme/manual/load/enable refreshes still discover active HUD elements.
- Style only DBM-owned warning text, with secret-text guards and exact icon matching.
- Preserve DBM's configured positions, sizes, row spacing, category colours and encounter behaviour.
- Bind the current lazy GUI, range/radar and information-frame lifecycles. Do not rely on obsolete widget names.
- Preserve native radar markers, warning colours, row data, drag targets and menu ownership. Background-opacity changes do not traverse the timer pool.

Mock coverage includes 25 new timers with zero active-pool enumerations; 100 GUI navigation callbacks with no timer-pool walks or font writes; and 2,000 warm auxiliary-row setters with no added objects, hooks, font writes or region enumeration. These are operation counts, not measured client CPU or FPS.

See [GUI performance](DBM_GUI_PERFORMANCE.md) and the current [engineering guide](../../ENGINEERING.md) for the reusable checks. Legacy boss-health styling is outside the supported target reviewed here.
