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

Only the native StatusBar's visual rectangle is recessed two units horizontally
and one vertically. Native row targeting buttons, heights, spacing, positions, macro
attributes, sort/data/actions and pooled identity stay unchanged. Spy's chosen
status-bar texture, vertex/status RGB, region alpha and value are never read or
overwritten by the skin. Class/status colours stay meaningful; the subdued
bronze framing provides the refined contrast instead of replacing semantic RGB.

The latest material pass adds two reusable two-unit gradient strips per slot:
a warm upper bevel (maximum alpha 0.14) and a dark lower bevel (0.16). They sit
on the native StatusBar at ARTWORK sublevel 2, below its OVERLAY text, and do not
replace the fill, texture, colour, value or alpha. They have no mouse input or
full-row opaque plate. Existing four-edge chrome supplies the copper separation.
The inner viewport rails sit three units from the window edge, with four short
corner ticks; a one-unit warm ledge accompanies the header rule. No native row,
secure hitbox, text coordinate, pitch, clipping flag or window bounds moves.
The material strips are decorative chrome independent of Spy's fill alpha;
Spy's whole-window fading still applies to them.

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
Forever art host. EUI texture cleanup cannot strip/recreate these custom hosts. Material strips
on native bars are created once, hidden for Standard, and reparented to the
reusable cosmetic slot when the native bar is retired. Replacement bars acquire
the same two textures instead of accumulating new artwork.

Native child anchors are captured on acquisition and restored on Standard,
disable, stale-row retirement and slot transfer. New StatusBar/label objects
are detected at existing discovery boundaries. Retired row callbacks cannot
affect a host transferred to another row. No detached native geometry or
growing per-update artwork is retained.

Combat gates all cosmetic geometry/paint and defer eligible changes to recovery.
Mocks cannot establish live taint safety; secure/forbidden APIs are not bypassed.

## Native states

The pinned Spy.xml secure-row template has native OnEnter/OnLeave callbacks to
Spy:ShowTooltip and an additive BarFill highlight. One secure posthook on that
Spy-local method dispatches only currently owned rows; per-row hover hooks remain
only as a fallback when the shared method is absent. Native scripts retain their
click attributes, native hover artwork and tooltips. The four existing copper
edges brighten only during a real row hover; cached transitions avoid duplicate
paint. Hide, recycling, Standard and disable clear the cosmetic hover state.
Combat defers cosmetic writes until recovery. No per-player or target scan is
used to infer focus.

No dependable persistent selected/focused row state was found in this upstream
implementation; statistics tab selection is unrelated. No sticky selection is
invented. Nearby, Last Hour, Ignore and KOS classifications, unknown-player
metadata and alert severity remain entirely native. All share the same reusable
row material; none receives an invented warning or bronze status colour.

## Settings and unaffected UI

Automatic / EUI Standard / EUI Forever, `/euispy`, the native row-menu
EUI AddonSkins submenu, AceConfig dialog, saved `EUIAddonSkinsDB.spy` preferences
and reset behavior are unchanged. Reset is Automatic / 75% and affects this skin
only. Saved 0% and 100% values are preserved. Missing Forever engine APIs fall
back to Standard without loading an addon.

Only the existing main decorative plate/grain own background opacity: neutral
white plate source, warm gradient/vertex paint, explicit BLEND, composed alpha,
no allocated main-header band and excluded zero-opacity draws. New row/list edges
are border chrome, not additional opaque background surfaces. Spy retains native
whole-window/instance fading and all row textures/colours/alpha. The background
slider never fades the window or text.

Nearby, Last Hour, Ignore and KOS share the new list/header. Existing statistics,
alerts/Watch severity, scoped menus/reason dialogs and settings helpers remain.
Shared player-unit menus, GameTooltip, map/minimap/target markers remain native.

## Performance audit follow-up

The approved Concept A appearance is unchanged. The native tooltip dispatch
removes 79 hooks from a 40-slot pool, the always-hidden main band is omitted, and
unchanged opacity callbacks save explicit preferences without scheduling paint.
Hover uses the existing applied-row theme cache. Two independent material strips
per row remain necessary for the approved edges/gradients; no visual feature was
removed to reduce counts. Complete before/after lifecycle timing, call profiles,
heap limits and live-client requirements are in
[SPY_FOREVER_PERFORMANCE.md](SPY_FOREVER_PERFORMANCE.md).

## Validation and performance

The focused Spy suite covers single-line and narrow reflow headers; dynamic
titles/counters; native actions, hitboxes and state feedback; source-shaped
native helper child-border suppression/Standard restoration; recessed fill and
four-edge row chrome and two bevel bands; native tooltip/hover script retention,
non-sticky hover and stale callback isolation; unchanged row/text coordinates and truncation; selected
texture/alpha preservation; native widths and row pitch; acquire/recycle/remove;
Standard/disable restoration; theme/opacity/reset/combat and art cleanup.

Actions runs the full 45-suite package check and an actual-source mode executing
unmodified Colors/Widgets/MainWindow against mocked client APIs. It also boots
fresh Lua states with saved 0%, 75%, 100%. Sensitivity checks reintroduce a
separate header row, remove the fill inset or restore black helper borders and
must fail focused assertions. Hover-palette and bevel-height mutations must also fail their focused assertions.
Existing opacity/tint/gradient checks remain.

Warm workloads count UI objects/hooks, hierarchy reads and cosmetic writes:
1,000 native SetBar calls retain zero extra cosmetic work. A separate source-shaped 1,000
unchanged row synchronization workload checks that cached inset anchors/edges
do not add objects/hooks/scans/geometry/paint/alpha writes. Existing header/state/
opacity and repeated theme-cycle workloads remain. These are mock counts,
not live CPU/FPS, taint or retained-memory measurements. The additional five-trial
baseline comparison and explicit cold/hover costs are recorded in
[SPY_FOREVER_PERFORMANCE.md](SPY_FOREVER_PERFORMANCE.md).

The read-only branch workflow builds and re-downloads the installable artifact:
66 source-identical runtime files, 43 skin factories, three unchanged v1.6.5 TOCs,
one EUIAddonSkins folder and exact MIT license. No tests, docs, scripts,
benchmarks, diagnostics or upstream dependencies are bundled. The PR records
the final commit, CI, checksum and public sign-in-free nightly.link test ZIP.

## Concept A scope

Implemented: low-contrast bevel depth, warm upper highlights, fine copper row
separation, a slightly recessed viewport with restrained corner ticks, matched
header rule/ledge and genuine native hover emphasis. The approved outer rim,
single-row header geometry/buttons, materials and 75% background compositor
remain unchanged. The slightly wider visual fill inset reveals the viewport
rail without narrowing native text or hitboxes.

Intentionally omitted: mockup typography/column headings/class icons, extra row
height, thick independent borders, full-row opaque plates, heavy shadows/glow,
additional artwork files and synthetic selected/threat states. Existing Spy
textures remain user-controlled; the small reusable edge bands provide material
depth without a new texture selector or per-update texture replacement.

## Exact in-game review checklist

1. Install this PR's ZIP into Interface/AddOns, retaining SavedVariables. Confirm
   the filename commit; runtime version deliberately remains 1.6.5.
2. With Spy 1.3.8-forever5/current EUI, inspect Nearby, Last Hour, Ignore and KOS.
   Provide normal/wide screenshots of Nearby and Kill On Sight. Check unified
   title/control/counter line, title truncation at tighter widths, the minimum-
   width fallback, divider, bronze corners and absence of black control boxes.
3. Compare short/long names, metadata columns, native ordering and truncation.
   Check rows with full/partial/empty fills, all five requested class identities,
   custom class/status colours and native hover states. Confirm
   recessed bodies, bevel strips, copper separators and inner rails remain subtle
   and readable at normal UI scale. Hover/leave, hide/show and recycled slots must
   clear the brighter outline while keeping native tooltip/target interactions.
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
