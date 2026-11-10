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

A thin bronze separator divides the rows. This polish pass removes the previous
fixed -21 control baseline, seven-unit title/control gap and padded native title
box. It measures actual wrapped glyph height instead of reserving the old
FontString box. Existing native button heights determine the row's vertical
center. The group is horizontally centered, with one consistent gap (up to two
units, reduced evenly only at native minimum width); no hitbox is resized.

Exact normal 12-unit text / 20-unit tallest-button geometry, relative to the
native window's top:

- Controls center: -23; top -13; bottom -33 (one unit before native rows at -34).
- Title bottom: -11; divider: -12; title-to-controls clearance: two units.
- Title top: +1; decorative top: +3 (two units above actual text).
- Header height: 37 units, down from 46 (about 20%); wrapped titles add only
  their measured extra glyph height. With a formerly padded 16-unit title box,
  the previous 50-unit reservation also collapses to 37 for 12-unit glyphs.
- Counter and its original hitbox align to the first title line's center.

Only the decorative top moves; outer rim artwork/thickness/colour and all native
window dimensions, row anchors, sizes, saved position/size and resize bounds
remain unchanged. This avoids moving secure targeting rows or stealing list
space. Native title drag/wheel handling follows the title. Inverted profiles use
the top Forever header and restore their original native anchors in Standard.
Long/localized titles wrap as needed; screen-edge behavior remains a live check.

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

The opacity audit found a paint-contract defect and a regression blind spot:
the previous main plate and unused header band were initialized with fully
opaque gradient stops, while subsequent updates changed only texture-level
alpha. The previous fixture had no SetGradient/CreateColor implementation, so it
could approve a 75% GetAlpha budget without ever exercising those paint paths.
The unused band also remained submitted for drawing at a zero texture alpha.

The main material now follows RestedXP's SetPaintAlpha/SurfaceAlpha pattern:
explicit BLEND, cached gradient-stop RGBA for the plate, vertex RGBA for grain,
and explicit visibility exclusion at zero. The unused header band is hidden
entirely. The warm RGB/gradient values are unchanged. For a target A, grain paint
uses 0.12A and plate paint uses (A - 0.12A)/(1 - 0.12A), giving exactly A combined
coverage over the game world in the unmasked interior at native parent alpha 1.
No paint alpha is applied a second time via SetAlpha. Tests check actual paint
values and visibility, not only GetAlpha; zero, 75% and 100% are covered.

The full hierarchy was reviewed: official Spy Widgets creates a body texture and
an opaque black TitleBar backdrop; the skin suppresses the body texture and
removes native window/TitleBar backdrops. Its registered EUI Standard shell has
atlas/black-overlay/flat alternatives, but their host has alpha zero in Forever.
The extra decorative header band is now excluded from rendering. One warm
plate/grain pair covers both header and body; the mask only lowers edge coverage.
No other owned filled header background remains. EUI's engine source has no
ignore-parent-alpha exception in its shell; its texture cleanup does not register
the custom Forever hosts.

Spy's native overall window/instance fading remains an independent feature.
The skin never changes parent alpha or fades interactive controls: native fading
can still lower the entire addon's final screen opacity, never make this
background more opaque. Borders, separator, labels and buttons are excluded from
the background slider. Saved preferences, reset behavior and all bar textures,
class/status colours and native row appearance remain unchanged. Standard,
alerts, statistics and menus retain their prior appearance.

These are verified source defects and modeled composition checks, not a captured
GPU trace from the maintainer's client. Confirm the resulting transparency in WoW;
the screenshot pixels/another addon modifying these frames cannot be audited
through GitHub APIs alone.

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
