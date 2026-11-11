# Spy Forever — compact composition

Draft PR #77. The compact visual reference is `01c099e6cdfbdea5ea77c9f53e50e2f585c016e4`, the last passing
revision before `1a3924e6` introduced the Concept A list and frame. Its predecessor
`8b3c117e` restored the compact control grouping; the intervening commits only
updated validation. The Concept A references and prior performance reports are
historical, not the visual target.

## Appearance and ownership

- Use the original slim textured chamfered rim and the warm plate/grain over
  the native window, with one header rule. No Heavy Bronze rim, inner panel,
  side bezel, header fill, bottom extension, or shadow ledge.
- Spy owns window size, resize bounds, row heights/spacing, statusbar and label
  anchors, text truncation, textures, values, alpha, and class/status colours.
  The compact button art, sizes, spacing, input and tooltips remain. Keep
  title, controls and count together at ordinary widths; retain the small
  safety reflow when a saved narrow window cannot fit the native hitboxes.
  The restored surface has no added bottom padding or enlarged title font.
- Each occupied row slot has the historical one-unit copper rule on an
  unregistered, mouse-inert sibling below the native content. No textures
  attach to the statusbar. No per-row geometry snapshots, bevel gradients,
  underlays, or decorative side rails.

## Compact header and native Inverted layout

At ordinary widths the title, five native controls, and counter share one
horizontal row. The height fits measured text and visible bronze seats with
two units of visual padding, and native hitboxes with at least one unit of
clearance at either edge. Round up at the effective scale. With the native
20-unit Close hitbox, this is 22 units at scale 1, versus 28 previously.
The native hitbox determines the minimum; the existing 14-unit bronze seat
has four units of visible clearance in that case. Very narrow windows keep
the existing title/counter and control bands so hitboxes do not overlap.

Normal layout keeps the divider and first row together, with the native
row origin restored in Standard. If text needs more than Spy's 34-unit
reservation, the decorative top can extend without reducing capacity.

Spy 1.3.8-forever5 keeps rows top-left anchored at -34 in either mode.
Inverted changes the resize/save pivot to the native bottom and puts the
native title and controls below it. Forever follows that constructed title
anchor: its same rim covers the body from just above the first row down
through the footer, and the divider sits at the native bottom. Inverted
rows retain native anchors and ordering. The skin does not move or resize
the native window, edit saved positions, or change Spy's row budget.

The pinned option setter only saves the preference and provides a Reload
button; the skin does not preempt native reconstruction. If a supported
fork reanchors the native title live, the existing header anchor observer
reuses the same artwork and switches edge without a reload. Standard
restores the captured native anchors on either edge.

Height measurements remain cached by font, scale and relevant title layout.
Identical text and same-width counter changes skip layout. Pending metrics
use a safe fallback until a native show, font, or scale boundary. No polling
or extra layout timers.

## Functional safeguards kept

Automatic, Standard and Forever, the EUI AddonSkins menu, /euispy, Reset,
explicit saved opacity values and the default 75% remain. The warm plate and
grain share the original opacity budget; native content and border opacity
are independent. Unchanged slider input does not schedule paint. Standard
restores native header anchors and current framework typography.

The existing CreateRow posthook prepares the rule after native construction,
while the slot is hidden, before normal native visibility management. The
first resting paint and hover exit use the same solid copper colour; the
old white-gradient/vertex-tint combination is absent. Hover uses the
existing shared Spy:ShowTooltip posthook (with the scoped old-fork fallback)
to brighten only the separator. Native highlights, tooltips, and actions
are preserved. Show/hide and row replacement reuse the slot art, and old
callbacks cannot repaint the new owner. Combat defers skin work to the
existing recovery event. No polling, timers for first visibility, or SetBar
hook are introduced.

Spy's upstream SharedMediaWidgets dropdown issue is separate. Neither its
libraries nor its native texture preference path are modified.

## Validation and live review

CI uses official Spy sources for native row creation and SetBar, checks
first visibility before hover/queued work, and verifies a white-paint
mutation fails. The three-way hosted Lua benchmark compares the restored
skin, the preceding PR runtime and the historical compact runtime with
the same workload. Results and the install ZIP are linked in PR #77.

In WoW, reload with the pointer away, open Nearby and Kill On Sight, and
verify the first visible rows before moving the pointer. Then hover/leave,
recycle rows, close/reopen, resize, and switch Standard/Forever. Confirm
native textures, 0/75/100% opacity, and combat recovery. Automated tests do
not establish actual compositor output or client taint behavior.
