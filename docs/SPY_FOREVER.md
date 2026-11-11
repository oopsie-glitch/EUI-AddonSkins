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
