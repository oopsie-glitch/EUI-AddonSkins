# Spy Forever development build

Draft implementation on `skin/spy-forever`, based only on released v1.6.5.
No version bump, release tag, merge or publication is authorized. All development,
source inspection, tests and packaging use GitHub cloud APIs and Actions.

## Design and architecture

The released Standard window/control primitives remain the baseline. Automatic
uses EllesmereUI's active profile resolver; EUI Standard disables the added
Forever artwork; EUI Forever selects it explicitly on the Forever-capable EUI
engine. Missing engine APIs fall back to Standard without forcing an addon load.

Open **/euispy**, or choose **EUI AddonSkins…** in a Spy player-row context menu.
The existing AceConfig registry/dialog provides the three style choices. The
preference is stored separately as `EUIAddonSkinsDB.spy.style`; it does not change
Spy's profile or EllesmereUI's settings. Changes coalesce safely without a reload
outside combat; a change made in combat is applied on combat recovery.

The Forever treatment uses EUI's public textured bronze border and the existing
RestedXP chamfer mask, warm shaded fill and subtle tiled material. No new assets
or shared runtime helper changes are needed. Artwork lives on unregistered,
mouse-disabled children; it is not put in EUI's registered-panel texture keep
set and does not require recurring restrip repair.

Native title positions, button sizes/spacing, list density, row anchors, text
width calculations, resize bounds and drag/click scripts remain owned by Spy.
The header band follows the existing title bar rather than adding another bar.
Control rims reuse the existing icon slots and retain all native functions,
tooltips, visibility, alpha and state textures.

Ordinary class fills retain native RGB and alpha semantics, with their texture
coverage softened to 32% of its original region alpha over the warm surface.
Player text and other status fills are not faded. The adapter never reads or
rewrites player names, levels, targeting attributes or detection data.
Out-of-combat cosmetic texture writes are separate from secure row actions.
One separator host is reused per native row slot, with stale-row callbacks
gated against later ownership. Native status-bar texture replacement restores
the prior texture before adopting the new one.

There is no additional opacity slider: Spy already exposes main-window and
instance opacity. Those remain native, including whole-window fading.
EllesmereUI's panel alpha controls the skin material; plate/grain use a composed
alpha budget so grain does not make the background unexpectedly opaque. This
does not migrate Spy to RestedXP's 75% default or change its existing defaults.

## Inspected source

Official [Spy 1.3.8-forever5](https://www.curseforge.com/wow/addons/spy-forever/files/9501070),
interface 16001. Archive SHA256:

`f0373e3cb8a31864d41532e08fb5748f42f0a76f45b2c4c9b0bbd92efe14fbec`

Reviewed native `Widgets.lua`, `MainWindow.lua`, `List.lua`, `Colors.lua`, `SpyStats.lua` and `SpyStats.xml`
on a GitHub-hosted runner. Reviewed the UI wrappers in `Forever.lua` and the
shared alert/menu paths in `Watch.lua`: the port adds a native row PostClick and
combat show/hide recovery, while watch warnings reuse the same AlertWindow.
Those native callbacks remain in place. The adapter observes both ShowAlert and
AlertWatch to synchronize the existing rim without reading detection payloads. The native row constructor is `CreateRow` / `SetupBar`;
`SetBar` owns text, truncation, progress, class/status colours and opacity.
Four lists share that pool. `UpdateMainWindow` only sets native whole-window
alpha, so it no longer triggers a generic skin scan.

The optional source-backed test downloads the pinned archive on Actions and
executes its unmodified Colors, Widgets and MainWindow files for actual row
construction and paint. It still uses mocked client APIs; it does not run
Spy's complete detection/bootstrap or certify other forks. External Spy source
is neither committed nor included in the install artifact.

## UI coverage and intentional native surfaces

| Surface | Treatment |
| --- | --- |
| Nearby, Last Hour, Ignore, Kill On Sight | Same continuous Forever shell, native compact header, class fills and fine row separators. |
| Native close, previous/next, clear, statistics and count controls | Bronze trim; original scripts, modifiers, tooltips, visibility and sizes retained. |
| Statistics window | Matching outer shell/close trim; native sorting, filters, data colours, row layout and scrollbar behavior retained through existing helpers. |
| Alert window | Matching background with native severity-coloured rim; native icons, text colours, widths, location, timing/flashing and sounds remain. |
| Spy row context menu and nested reasons; statistics menu | Existing scoped shared-menu helper only while Forever is active. Standard menus retain native appearance plus the new settings command. |
| KOS “Other reason” shared confirmation | Existing texture-only dialog helper, scoped to Spy's popup identity; native fonts, input/actions and foreign reuse retained. |
| Spy AceConfig windows and skin-style dialog | Existing controls/helper treatment with matching outer shell; no replacement settings framework. |
| Shared GameTooltip, Blizzard player-unit menus, map/combat markers, minimap and target-frame KOS button | Remain native. Their semantic art, shared ownership and protected overlays require separate treatment; no global hooks are added. |

The source's main-window wheel handler is a placeholder. The skin does not add
scrolling or change Spy's native navigation. Existing settings and statistics
scrollbars keep their native ranges and hit areas. Inverted layout and unusual
profile/font/scale combinations require live verification.

## Automated verification and performance

The new `tests/spy_spec.lua` is registered in the full package suite.
It checks automatic/manual style changes, Standard restoration, five class
identities, native status fills, constructor/reuse/removal, long names/narrow
widths, header scripts, auxiliary frames, severity, opacity endpoints, source
immutability of actions, settings persistence, menu callback returns, foreign
popup ownership, combat deferral, disable cleanup and artwork/hook reuse.

A 1,000-update warm workload asserts zero added UI objects/hooks, hierarchy
reads/scans, cosmetic alpha writes or queued refreshes for unchanged class rows.
Both source-shaped and actual-source row modes run on Actions. These are
operation counts in mocked UI, not live CPU, FPS, taint or memory measurements.
Full discovery remains event-driven at construction, options/profile/style
boundaries; ordinary `SetBar` work is local and there is no new polling/OnUpdate.

The branch-specific Actions workflow builds the one-folder addon, verifies
source bytes/66 entries/43 skin files/three unchanged-version TOCs/MIT license,
and uploads an installable test artifact. It has read-only repository access
and no publishing steps. The PR records exact commit, CI and artifact links.

## In-game review checklist

1. Install the PR's test artifact, retaining existing SavedVariables. Its runtime
   version remains 1.6.5; identify the test by branch and commit in the filename.
2. With Spy 1.3.8-forever5 and current EUI, compare Automatic, Standard and Forever
   without reload, then reload to confirm the saved manual selection. Compare
   Standard against the released build at the same native profile/scale.
3. Check Nearby, Last Hour, Ignore and KOS at ordinary and minimum width: long
   names, right-hand level/class text, ordering, row fading, hover, target clicks,
   shift/ctrl actions, list changes, clears, player removal and new detections.
4. Compare druid, paladin, shaman, hunter and rogue fills. Check custom class
   colours, unknown/status rows, inactive/faded rows and all warning severities.
5. Exercise every title control, tooltips, clear modifiers, statistics toggle,
   native resize grips, drag/lock, resize/reopen and inverted profile layout.
6. Exercise statistics filtering/sorting/scrolling and player menus; reason
   submenus and the “Other” input; then open another addon's shared popup/menu.
7. Check AceConfig pages and /euispy. Change native opacity at low/high values
   against bright and dark scenery; also change EUI panel opacity and themes.
   Confirm only native Spy whole-window opacity fades text.
8. Detect/switch lists and change style around combat. Native targeting/actions
   must remain functional; cosmetic changes should recover after combat.
9. Trigger EUI appearance refresh/texture cleanup, reopen after several minutes,
   reload and cycle modes repeatedly. Record exact versions, screenshots and
   any errors. No in-game visual, taint or long-session approval is claimed.

The requested reference screenshots were not visible in this chat. This initial
variant follows the written brief and approved RestedXP implementation; its
appearance remains pending maintainer screenshots and feedback.
