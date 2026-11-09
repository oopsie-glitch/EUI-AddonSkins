# Spy Forever development build

Draft PR #77 on `skin/spy-forever`, based on released v1.6.5.
All source inspection, edits, testing and packaging use GitHub APIs and Actions.
No merge, version bump, tag or platform publication is authorized.

## Accepted visuals and ownership

The chamfered bronze rim, warm window material, compact native rows, class/status
colours and inset control artwork have passed maintainer in-game review. This
iteration changes only header layout and skin settings/background opacity.
The Rim and Surface primitives and button artwork are unchanged.

Spy exclusively owns bar texture paths, region alpha, native colours, text,
sorting, warnings, targeting and other gameplay actions. The adapter never
hooks SetBar, SetBarTextures or UpdateBarTextures, or reads/writes native
StatusBar textures. It adds separate fine row separators, reused per row slot;
retired row callbacks cannot control artwork reassigned to a new row.

## Two-row Forever header

The native title remains the actual dynamic FontString. It occupies a full-width
title area with a reserved right-side native counter. Existing close, next,
previous, clear and statistics buttons use a separate aligned row below it.
Hidden controls release their space. Their original sizes, hitboxes, state
artwork, scripts and tooltips are retained; painted insets provide separation
even where minimum width requires adjacent hitboxes. The native count hitbox
follows the counter.

A thin bronze separator divides the rows. The existing 34-unit native header
area accommodates controls; the decorative top extends upward by the title's
line height (normally 12 units). Long/localized titles wrap within the title
area at narrow widths and extend that top only as necessary. There is no width
increase, parent-frame resizing, row relocation, new input overlay or change to
Spy's saved position/size or resize bounds. This avoids moving secure targeting
rows or stealing list space. The native title drag/wheel frame continues to
follow the title. The Forever header is at the top even for inverted profiles;
switching to Standard restores the original inverted native anchors.

Title text changes, counter text/visibility changes and completed native
resize/setup/profile operations synchronize the existing header only. Native
header anchor changes are observed locally and saved for restoration; adapter
writes are guarded against re-entry. Standard/disable restore saved native
anchors, title width/height/wrapping and helper art. Artwork is mouse/motion
disabled, unregistered with EUI's texture cleanup, and reused.

## One settings model

Open **/euispy**, or use the **EUI AddonSkins** submenu in Spy's native player-row
right-click menu. The submenu mirrors the RestedXP pattern:

- Style: Automatic, EUI Standard, EUI Forever.
- Background Opacity…: existing AceConfig dialog, 0–100%.
- Reset Skin Settings.

Both entry points share `EUIAddonSkinsDB.spy.style` and `.opacity`. Automatic
follows the active EUI theme; missing Forever APIs fall back to Standard.
Unset Forever opacity resolves to **75%**. Explicit 0% and 100% survive settings
re-reading, theme changes and reload; defaults are not written over saved values.
Reset clears only this skin's preference table, restoring Automatic/75%, and
notifies the same AceConfig registry. It does not alter Spy profiles or other
skin settings. There is no separate configuration framework.

Spy assigns and opens its legacy initializer inside BarDropDownOpen. A scoped
wrapper prepares that Spy-owned initializer before the first opening, appends
one settings submenu and intercepts only its own submenu token. Native menu
actions, nested reasons and nil-containing callback returns remain intact.
No Blizzard/global menu API is replaced. Shared player-unit menus remain native.

## Background opacity

Only the Forever main-window material uses the skin opacity preference. The
same warm gradient/grain spans header and body with a composed alpha budget;
the old overlapping header fill is disabled. Borders, separator, labels and
buttons remain fully visible at 0%. The slider does not set alpha on the window,
text or interactive controls. It coalesces bursts and updates existing artwork
without hierarchy discovery.

Spy's native overall window/instance fading remains its independent native
feature. It can fade the entire addon, including its decorative material;
the skin slider does not compete for those properties. Spy still controls all
row textures, class/status colours and their appearance. Standard, alerts,
statistics and menus retain their existing opacity behavior; this iteration
does not redesign those surfaces.

## Source and supported surfaces

Inspected official [Spy 1.3.8-forever5](https://www.curseforge.com/wow/addons/spy-forever/files/9501070),
interface 16001, archive SHA256
`f0373e3cb8a31864d41532e08fb5748f42f0a76f45b2c4c9b0bbd92efe14fbec`.
Reviewed Widgets, MainWindow, List, Colors, statistics Lua/XML, Forever and Watch
UI wrappers. The Actions compatibility mode executes unmodified official Colors,
Widgets and MainWindow code for row construction, native paint, texture/profile
updates and resizing against mocked client APIs. It does not execute the full
detection/bootstrap or prove another fork/client compatible.

| Surface | Treatment |
| --- | --- |
| Nearby, Last Hour, Ignore, KOS | Approved shell/rows, new two-row header, native bar textures and colours. |
| Native controls/counter | Existing approved trim, native states/functions, title/control separation. |
| Statistics | Existing matching shell/close trim, native data/sorting/scrolling. |
| Alerts and Watch alerts | Existing severity-coloured rim, native content/timing/sounds. |
| Row/reason and statistics menus | Existing scoped menu styling; settings submenu in the native row menu. |
| KOS Other-reason confirmation | Existing texture-only helper, scoped to Spy popup identity and restoring foreign reuse. |
| Spy options and skin dialog | Existing AceConfig infrastructure/control helpers. |
| Shared tooltip/player-unit menus, markers, minimap, target-frame KOS button | Native and intentionally outside this change. |

## Verification and limits

The full package suite includes the focused Spy regression with source-shaped
and actual-source modes. Header checks cover 90/130/200/300-unit native widths,
full/wrapped dynamic titles, live counters, aligned native hitboxes, visibility,
clicks/tooltips/state feedback, Standard restoration, style switching and combat
deferral. Settings checks cover 75% default, 0/100 endpoints, composed header/body
alpha, saved settings re-reading, reset isolation, first-open submenu injection
and native return preservation. Existing bar-texture/profile/alpha tests remain.

Warm workloads assert no new UI objects/hooks, hierarchy reads, cosmetic alpha
or geometry writes or queued refreshes for 1,000 unchanged title/counter pairs.
Existing 1,000 native SetBar and control-state workloads and repeated theme
cycles check bounded artwork/hooks. These are mock operation counts, not live
CPU/FPS, retained-memory or taint measurements.

The branch's read-only Actions workflow runs the complete regression/package
checks, verifies 66 runtime files under one EUIAddonSkins folder, three unchanged
v1.6.5 TOCs, exact MIT license and source-byte parity, uploads a test artifact,
then downloads it again on the cloud runner and verifies ZIP integrity and all
runtime bytes. Development/upstream/reference files are excluded. The PR records
the final commit, CI and temporary sign-in-free nightly.link download.

## In-game verification checklist

1. Install the test ZIP into Interface/AddOns, keeping SavedVariables. It remains
   runtime version 1.6.5; use the commit in its filename to identify this test.
2. Check full dynamic titles and counters in Nearby/Last Hour/Ignore/KOS, at
   default/minimum width, multiple fonts/scales, normal/inverted layout, and near
   screen edges. Verify wrapped titles, top extension, drag/wheel, resize/reopen,
   control alignment and every original button/tooltip/modifier/state.
3. Use the row-menu EUI AddonSkins submenu on its first opening and /euispy.
   Switch Automatic/Standard/Forever; compare Standard to released appearance,
   anchors and size. Verify native nested reasons/actions still work.
4. Verify 75% default and 0/100% background settings against bright/dark scenery;
   borders/text/icons must remain visible. Save each endpoint and reload, switch
   theme and reopen. Reset must restore Automatic/75% without altering Spy.
5. Change Spy bar texture/colours and native window/instance fading. Verify native
   row appearance immediately and after updates, resize, mode/theme changes and
   reload. The skin slider must affect only decorative background material.
6. Check alerts/statistics, combat transitions/recovery, EUI cleanup, repeat
   reopening/theme cycles and errors. Rendering, real hit-testing/taint, native
   secure behavior and long-session stability still require WoW verification.
