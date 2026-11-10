# Spy Forever development build

Draft PR #77 on `skin/spy-forever`, based on released v1.6.5.
All source inspection, edits, testing and packaging use GitHub APIs and Actions.
No merge, version bump, tag or platform publication is authorized.

## Accepted visuals and ownership

The chamfered bronze rim, warm window material, compact native rows, class/status
colours and inset control artwork have passed maintainer in-game review. This
iteration restores compact right-aligned toolbar placement, using 42ab68d as the
baseline. Current materials/opacity/settings, rim and button artwork are unchanged.

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
center. All five controls form one compact group aligned to the right. The
full-width distribution and single-control centering formulas are removed.
The existing compact gap calculation is reused: at most two units between
unchanged native hitboxes, reduced only when the native minimum width requires
it. The normal right inset is eight units, reducing to three at width 90.
Hidden native controls close their slot; a lone control stays right-aligned.
No new layout system, control, artwork, stretched icon or hitbox is introduced.

The pinned Spy geometry remains close 20x20; previous/next/clear 16x16;
statistics starts 12x12 and native active-button setup sets width to 16, leaving
height 12. The usual five active hitboxes total 84 horizontal units. At widths
130, 200 and 300, the group remains 92 units wide (84 plus four 2-unit gaps),
ending eight units from the right edge. At native width 90, gaps are zero with
three units on either side. Runtime uses actual visible control dimensions.
The title left inset, right-aligned counter and all vertical geometry remain
unchanged. The remaining space is deliberately left of the cohesive group.

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

The audit found a concrete double-tint defect as well as a paint-contract/test
blind spot. The main plate used a brown solid source (0.165, 0.115, 0.075) and
then applied another brown gradient over it. Multiplicative texture colour
modulation produces near-black RGB: high red becomes 0.165 * 0.165 = 0.027225,
and low red 0.165 * 0.120 = 0.0198. The screenshot's near-black surface therefore
did not establish that the saved 75% slider value was wrong.

The previous plate and unused band also kept gradient stops at alpha 1 while
updates changed texture-level alpha. The old fixture had no SetGradient/
CreateColor implementation, and merged solid-source and vertex colours, so it
could approve GetAlpha without checking either the actual paint or multiplied
RGB. The unused band remained submitted for drawing at zero texture alpha.

The main plate now uses a white source and applies the same warm gradient once.
This corrects the colour multiplication rather than raising RGB or arbitrarily
lowering opacity. Auxiliary materials are unchanged.

The main material now follows RestedXP's SetPaintAlpha/SurfaceAlpha pattern:
explicit BLEND, cached gradient-stop RGBA for the plate, vertex RGBA for grain,
and explicit visibility exclusion at zero. The unused header band is hidden
entirely. The intended gradient RGB values are unchanged; the duplicate base tint is removed. For a target A, grain paint
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

## Compact right-aligned toolbar review

This focused correction restores compact geometry after the alignment/
distribution experiments. The existing right-to-left anchor loop and compact
gap calculation seat the original controls at the right inset. Full-width
spacing and centering calculations are removed. Header height, materials,
opacity/settings, controls, native rows and Standard restoration are unchanged.

Regressions cover Nearby, Last Hour and Kill On Sight at widths 90, 95, 103, 130,
200 and 300 with counters 0, 7 and 123. They require compact right alignment,
equal modest gaps, fixed native hitboxes/art sizes, original click behavior,
title/counter separation, resizing/reopening and hidden/single-control handling.
Standard restores the original native anchor chain. Existing combat, opacity,
row and warm operation-count checks remain. Sensitivity mutations restoring
full-width distribution or centering must fail their geometry assertions.

For live review, compare narrow/wide Nearby and Kill On Sight screenshots.
Confirm the compact group sits on the right, all controls/tooltips/states work,
the full title and counter stay clear and the two-row height/materials are
unchanged. Actual rendering, hit-testing and combat taint remain WoW checks.
