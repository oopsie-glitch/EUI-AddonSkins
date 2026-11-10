# Spy Forever — Concept A composition redesign

Baseline: b4f2e7b6e4ac86b2b2a1ec9352c93422bdc3abe2, draft PR #77.
The previous appearance is not visually approved. This document records the
reference comparison before runtime edits. Concept A is the visual target;
in-game screenshots, not automated checks, decide acceptance.

## Visual gap and implementation direction

| Element | Current in-game image | Concept A target | WoW implementation / compromise |
| --- | --- | --- | --- |
| Proportions and weight | Narrow flat strips inside a thin rim; little content margin | Substantial perimeter and framed inset content | Keep saved native width/height; expand only the cosmetic bezel/foot clearance and inset visual content. Wider native window recommended for full title. |
| Outer corners | Existing chamfered EUI bronze is recognizable but visually isolated | Chamfers connect to broader illuminated bronze construction | Reuse EUI Forever rim artwork with warm, shaded bezel surfaces inside it; no invented asset ownership. |
| Header | Similar tone to body, little depth | Dark-bronze integrated band with metallic ledge | Dedicated header surface, restrained top highlight and broader lower ledge. One horizontal title/control/count line. |
| List well | Rows nearly touch outer rim | Separately recessed, shadowed inner panel | Inset the visual viewport; use the shared chamfered rim, clipped warm-dark material and inner shading. Native secure row buttons and row budget remain untouched. |
| Row materials | Two short edge bands leave a flat coloured centre | Broad matte upper light/lower shade and fine copper joints | Reuse the existing two row textures as broad surface gradients above native fills and below text. Native paths/RGBA/value stay untouched; no generic bronze replacement or new per-row grain texture. |
| Typography | Small addon text, little internal breathing room | Larger deliberate title, padded columns | Modest title emphasis; inset native labels and constrain name width through anchors. Preserve Spy's own row-height/font settings; no oversized mockup type or column-heading row. |
| Grain and lighting | Fine flat texture, little directional light | Warm grain and controlled metallic falloff | Reuse RestedXP mask/grain patterns, distinct header/list gradients and bezel lighting. No noisy new bitmaps or external assets. |
| Transparency | Existing 75% compositor | Warm materials readable against the world | Separate header/list background regions with the same 75% target, no stacked opaque plates. Decorative borders/text are not faded. |

## Compatibility decisions

Native detection, sorting, warnings, status/class colours, texture selection,
targeting and tooltip logic remain Spy-owned. No class icons, fake selection,
decorative controls or full native frame replacement are introduced. The single
native ShowTooltip posthook and per-slot pooling remain. No new polling or
steady-state discovery is permitted.

The secure row's visual fill can move inward independently of its hitbox.
Native labels use constrained anchors so normal FontString truncation works
without adding a SetBar hook or editing names. Original anchors restore in
Standard/disable. This intentionally changes Forever content padding, not the
saved row height or whole-window geometry.

The target's large typography/column headings and exact screenshot dimensions
are not copied. Users can widen/resize Spy and adjust native row height/font to
get more breathing room. Existing custom dimensions must not be overwritten.
Extremely narrow legacy windows cannot physically fit five unchanged hitboxes,
title and counter in one line; supported sizing and any safe native resize-bound
policy must be validated before delivery.

The body and header materials must be visibly different from the old flat
construction. Merely darkening bars or adding thin rules is not completion.
The first ZIP is a review build, not proof of visual acceptance.
