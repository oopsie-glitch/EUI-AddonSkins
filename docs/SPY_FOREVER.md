# Spy Forever — Concept A list build

Draft PR #77, branch `skin/spy-forever`, based on released v1.6.5. This build uses
the maintainer's written Concept A direction: a unified header and contained,
recessed list items. Visual design remains awaiting in-game screenshots.
All inspection, edits, testing and packaging use GitHub APIs and Actions.
No merge, version bump, tag or publication is authorized.

## Visual structure

The approved chamfered bronze outer rim, warm matte gradient/grain and composed
75% Forever background default remain. No new assets or shared runtime helpers
are introduced.

### Integrated header

At normal widths title, right-side controls and counter share one header line.
The title is the native dynamic FontString at the left; controls keep their
bronze artwork, native sizes/order/actions/tooltips/states; the count indicator
and its original hitbox remain at the right. One bronze rule separates header
and content. The separate toolbar divider/band is gone.

The compact controls use existing modest gaps (maximum two units). Space for the
counter includes its invisible native hitbox, avoiding overlap with close or the
title. The title truncates natively when its available single-line width is
insufficient; widen the Spy window for longer/localized titles.

A native 90-unit window cannot simultaneously fit five unchanged hitboxes
(normally 84 units), counter and title on one line. If the title would get less
than 24 units, the same unified header reflows compactly, preserving all native
controls/counter and readable wrapped title instead of losing functions.
This minimum-width safety fallback has no separate toolbar background.
Normal 200+ widths use one line; the exact threshold follows visible controls
and native counter dimensions. Native window width/height/resize bounds are
never forced or saved differently. The decorative top fits the content.

The shared soft-control helper previously added child black borders around
page buttons, outside the direct native texture slots. Its existing borderless
predicate now suppresses only Spy's main-header helper borders in Forever.
Standard and disable restore them. Native X/arrow/icon replacement artwork
remains saved/restored as in the approved build; no global stripping/scans.

### Contained list rows

A hollow inset list surround and stronger header/content rule define the list
surface. Each native row gains four one-unit matte bronze edges: a restrained
upper highlight, warm lower edge and subtle side rails. This creates stable
rectangular items and consistent row rhythm even when the native progress fill
is partial or empty. There are no stacked opaque row plates.

Only the native StatusBar's visual rectangle is recessed by one unit on each
edge. Native row targeting buttons, heights, spacing, positions, macro
attributes, sort/data/actions and pooled identity stay unchanged. Spy's chosen
status-bar texture, vertex/status RGB, region alpha and value are never read or
overwritten by the skin. Class/status colours stay meaningful; the subdued
bronze framing provides the refined contrast instead of replacing semantic RGB.

Native names remain primary on the left, metadata on the right. Their anchors
are pinned to the same original row coordinates (two-unit text margins), not
moved with the inset bar. This preserves Spy's exact native truncation formula:
row width minus right-text string width minus four. No per-player paint hook,
custom text pipeline or texture selector is needed.

## Native source and safety

Pinned official [Spy 1.3.8-forever5](https://www.curseforge.com/wow/addons/spy-forever/files/9501070),
interface 16001, SHA256
`f0373e3cb8a31864d41532e08fb5748f42f0a76f45b2c4c9b0bbd92efe14fbec`.
Actions records unmodified CreateRow, SetupBar, SetBar, ResizeMainWindow and
ManageBarsDisplayed before implementation; Widgets/Colors and Forever/Watch
UI paths are also reviewed.

CreateRow makes a secure targeting button at x=2, y=-34 minus native row pitch.
SetupBar anchors the StatusBar over that button and labels to the bar.
SetBar updates native text, value, colours/opacity and truncation width.
ResizeMainWindow changes row width; it does not reset those child anchors.
The skin changes only child cosmetic geometry outside combat and reanchors
text to retain its original coordinates. No secure action, detection data or
player-name parsing is added.

Row chrome uses one reusable mouse/motion-disabled sibling host per native slot,
below the StatusBar/text frame level. It contains edge textures only, never a
raised fill over data. The list surround lives under the existing unregistered
Forever art host. EUI texture cleanup cannot strip/recreate these custom hosts.

Native child anchors are captured on acquisition and restored on Standard,
disable, stale-row retirement and slot transfer. New StatusBar/label objects
are detected at existing discovery boundaries. Retired row callbacks cannot
affect a host transferred to another row. No detached native geometry or
growing per-update artwork is retained.

Combat gates all cosmetic geometry/paint and defer eligible changes to recovery.
Mocks cannot establish live taint safety; secure/forbidden APIs are not bypassed.

## Settings and unaffected UI

Automatic / EUI Standard / EUI Forever, `/euispy`, the native row-menu
EUI AddonSkins submenu, AceConfig dialog, saved `EUIAddonSkinsDB.spy` preferences
and reset behavior are unchanged. Reset is Automatic / 75% and affects this skin
only. Saved 0% and 100% values are preserved. Missing Forever engine APIs fall
back to Standard without loading an addon.

Only the existing main decorative plate/grain own background opacity: neutral
white plate source, warm gradient/vertex paint, explicit BLEND, composed alpha,
hidden unused header band and excluded zero-opacity draws. New row/list edges
are border chrome, not additional opaque background surfaces. Spy retains native
whole-window/instance fading and all row textures/colours/alpha. The background
slider never fades the window or text.

Nearby, Last Hour, Ignore and KOS share the new list/header. Existing statistics,
alerts/Watch severity, scoped menus/reason dialogs and settings helpers remain.
Shared player-unit menus, GameTooltip, map/minimap/target markers remain native.

## Validation and performance

The focused Spy suite covers single-line and narrow reflow headers; dynamic
titles/counters; native actions, hitboxes and state feedback; source-shaped
native helper child-border suppression/Standard restoration; recessed fill and
four-edge row chrome; unchanged row/text coordinates and truncation; selected
texture/alpha preservation; native widths and row pitch; acquire/recycle/remove;
Standard/disable restoration; theme/opacity/reset/combat and art cleanup.

Actions runs the full 45-suite package check and an actual-source mode executing
unmodified Colors/Widgets/MainWindow against mocked client APIs. It also boots
fresh Lua states with saved 0%, 75%, 100%. Sensitivity checks reintroduce a
separate header row, remove the fill inset or restore black helper borders and
must fail focused assertions. Existing opacity/tint/gradient checks remain.

Warm workloads count UI objects/hooks, hierarchy reads and cosmetic writes:
1,000 native SetBar calls retain zero extra cosmetic work. A separate 1,000
unchanged row synchronization workload checks that cached inset anchors/edges
do not add objects/hooks/scans/geometry/paint/alpha writes. Existing header/state/
opacity and repeated theme-cycle workloads remain. These are mock counts,
not live CPU/FPS, taint or retained-memory measurements.

The read-only branch workflow builds and re-downloads the installable artifact:
66 source-identical runtime files, 43 skin factories, three unchanged v1.6.5 TOCs,
one EUIAddonSkins folder and exact MIT license. No tests, docs, scripts,
benchmarks, diagnostics or upstream dependencies are bundled. The PR records
the final commit, CI, checksum and public sign-in-free nightly.link test ZIP.

## Exact in-game review checklist

1. Install this PR's ZIP into Interface/AddOns, retaining SavedVariables. Confirm
   the filename commit; runtime version deliberately remains 1.6.5.
2. With Spy 1.3.8-forever5/current EUI, inspect Nearby, Last Hour, Ignore and KOS.
   Provide normal/wide screenshots of Nearby and Kill On Sight. Check unified
   title/control/counter line, title truncation at tighter widths, the minimum-
   width fallback, divider, bronze corners and absence of black control boxes.
3. Compare short/long names, metadata columns, native ordering and truncation.
   Check rows with full/partial/empty fills, all five requested class identities,
   custom class/status colours and native faded/selected/hover states. Confirm
   recessed bodies and row rails remain subtle and readable at normal UI scale.
4. Change Spy's bar texture and native opacity; verify immediate application and
   after row updates, new detections, list changes, clear/remove/reuse, resize
   and reopen. Check every target/modifier click, tooltip and header action.
5. Cycle Automatic/Standard/Forever; compare Standard against released native
   EUI appearance, full bar anchors and text positions. Reload saved selections.
   At minimum/maximum width and inverted profiles, verify geometry and dragging.
6. Test decorative 0%, 75%, 100% over bright/dark scenery; save and reload each,
   then reset. Text, icons, edges and native semantic fills must stay readable.
   Native whole-window fading remains independent.
7. Enter/leave combat while updates occur, reopen/switch lists and request theme
   changes. Verify native actions and post-combat restoration without errors.
   Exercise EUI appearance refresh/texture cleanup and repeated mode cycles.
8. Check unchanged statistics, alerts/Watch warnings, row/reason submenus,
   Other-reason input and foreign shared popup/menu reuse.

Actual rendering, secure hit-testing/taint, screen-edge positioning, other Spy
forks/clients and long-session stability remain live checks. Automated tests
do not approve this visual design.
