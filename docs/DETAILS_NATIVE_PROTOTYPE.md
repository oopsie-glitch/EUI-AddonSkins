# Addonskins EUI — experimental native Details skin

This community prototype is opt-in and is not affiliated with or endorsed by EllesmereUI. It does not replace the approved standalone integration. Main and PR #91 remain unchanged.

## Try or stop using it

Back up the current profile using Details' native profile interface before selecting a different native skin: Details resets non-exempt appearance settings when changing skins.

Open Details Options → Skins → Skin Selection and choose **Addonskins EUI** for the intended window. Native group editing can affect several selected windows. No installation/login/theme callback explicitly selects it.

Continue using native Details options for bars, fonts, toolbar geometry, titles, timer visibility and profiles. To leave, select another native skin. The existing EUI meter matching preference applies again to non-prototype windows; turn it off if you want the alternate skin without legacy meter matching. Before removing this experimental build, select an available native skin for every prototype window, save the profile and reload.

The definition uses no_cache=true: no new definition is persisted in Details' skin cache. Missing-provider fallback is owned by Details; the native waiting-skin mechanism can restore a previously selected skin when registration becomes available. We do not rewrite saved skin names or install a second restoration system. Removing the provider before switching away can therefore cause native fallback/reset behavior.

## Native configuration

DetailsNative.lua copies Minimalistic's compatible atlas/layout metadata without mutating it. instance_cprops starts from a deep copy of the active build's instance_defaults, not Minimalistic's custom profile. Values are initialized once through native selection:

- The approved fallback values are self-contained: body RGB 0/0/0 and alpha .75; header RGB 27/255 each and alpha 1; header height 22 and title font size 11; bars height 18, spacing 2 and left/right font sizes 11. The native definition does not import optional EUI Damage Meters preferences.
- SharedMedia registers the public Skin API font and client WHITE8X8 bar/header/body resources. No optional meter file path is imported.
- Native title enabled, encounter timer initially disabled; native timer/content retained. Its initial text color comes directly from the live public Skin API GetAccentColor, independently of EUI Damage Meters' separate custom-title preference.
- Native flat header, .5 subdued full border, no sidebars/status bar/rounded corners, hidden attribute icon.
- Native class/status color defaults are retained; native bar texture/font/height/spacing and ordinary total/DPS formatting are initial settings, not refresh-time writes.
- Menu size, position, visibility, scale, window position and other native ignored fields follow Details' own skin-switching rules.

The renderer continuously consults skin definitions for some horizontal row padding. That native exception is not bypassed. Color/font/theme changes are not automatically copied into the chosen profile after selection: native customization wins. Reselecting the same skin normally refreshes current values rather than resetting defaults; use native saved appearance/profile controls when intentionally restoring a saved configuration.

## Hybrid layer and coexistence

The only new setter hooks are Details SetBackgroundColor and SetBackgroundAlpha. The native bgdisplay duplicate backdrop fill is tinted transparent; baseframe retains the native chosen color/alpha. No backdrop reconstruction, geometry reads/arithmetic, replacement fill frame or tooltip hook is added.

Existing native toolbar state textures are reused for the bundled MIT-licensed Feather outline glyphs in Media/DetailsNative. No new artwork objects, button anchors, dimensions, scripts or hitboxes are created. Native hover/pushed/disabled textures retain native interaction. Neither optional-addon availability checks nor external meter assets are used.

Named header atlas decorations behind the native flat title band are suppressed only for selected prototype windows. Native skin switching restores cosmetics without replacing new native values.

The existing Details adapter yields row/settings/title/layout ownership for prototype windows. On handoff, old cosmetic art and stale native snapshots are released without restoring them over the newly selected settings. Its replacement title, row formatting and row-font processing remain intact for other windows. Original menu/options and Cooltip safety paths are preserved. Tiny Threat continues to use its own native row renderer and supported host settings; exact parity is not guaranteed.

## Source compatibility and validation limits

Reviewed official Details revisions:
- 2efa4b10628e0e4a91c346138cf8325e81d0a43c
- 4316feb434bcc9751455ae2c6435d93fc20f034f

Registration waits for IsLoaded, checks required exports/schema and declines foreign name collisions. It runs through the existing target/load/enable/combat lifecycle. InstallSkin can synchronously restore a waiting selection; registration is therefore deferred out of combat. No explicit ChangeSkin call is made by the prototype.

Source fixtures execute official InstallSkin and the reset/default portion of ChangeSkin. They do not emulate the complete WoW renderer or prove the installed Forever version. The existing regression suite exercises native sizing and Cooltip ownership. Hosted timings are CPU fixture results, not WoW FPS/frametime/GPU/taint measurements.

## In-game acceptance

1. Before selection, confirm all existing windows and settings look unchanged.
2. Back up the native profile, select Addonskins EUI for one window, leave another unchanged.
3. Compare header/body opacity, title accent, native title/timer and toolbar icons with the approved screenshot.
4. Change fonts/textures/colors/height/spacing/title/timer and toolbar size/side/visibility; reopen and reload.
5. Test separate settings per window, profile switching and Tiny Threat.
6. Check background alpha extremes, resizing/scaling, theme changes, combat recovery and tooltip fade/owner transfer with Lua errors and taint logging.
7. Switch away, confirm no duplicate header/icons or retained background suppression, then test removing the prototype after saving an alternate skin.

Visual parity, installed-client compatibility, native disk persistence and live taint safety require WoW testing. This draft must not replace production behavior before approval.

## Registration correction after first in-game test

The initial prototype incorrectly used Details:GetSkin(name) for named lookups. In both pinned official sources, functions/skins.lua first defines a named getter, but classes/class_instance.lua loads later and replaces it with GetSkin() returning Details.skins[self.skin]. The global Details object has no selected instance skin, so the Minimalistic lookup returned nil before InstallSkin was reached. The original source fixture executed InstallSkin without the later getter override and missed this failure.

The adapter now reads Details.skins by name for template, collision, registration and ownership checks, exactly as the native dropdown builder does. Native GetSkin is not modified. Verify by-name registration through Details.skins["Addonskins EUI"], or use GetSkin() on an instance already selecting that skin. Calling Details:GetSkin("Addonskins EUI") is not a supported by-name query after the native override and cannot be made one without altering the upstream global method.

The real TOC order, both GetSkin definitions, official Minimalistic definition, InstallSkin and native menu builder are now executed by source fixtures. Opening the native menu rebuilds its choices from the registry; no additional dropdown refresh hook is required. Existing DETAILS_STARTED and combat-recovery refreshes retry initialization without polling.

All registration early exits now retain a bounded status. /euidetailsnative reports status, install-attempt count, Details version, IsLoaded and combat state. Persistent incompatibility, schema, collision, media or rejection reasons report once per reason. Optional EUI meter artwork is not required to register.

This is a source-reproduced defect, not proof of the exact installed Forever version. The corrected entry still requires in-game confirmation.

## Native title and toolbar layout correction

The initial definition copied Minimalistic's atlas anchors but replaced its coordinated menu/title defaults with generic instance defaults. Those defaults assume the native title is disabled and put the toolbar on the left. Enabling the native title without preserving the working layout made the two overlap. icon_anchor_main and icon_anchor_plugins position the attribute/plugin icon, not the toolbar, and are preserved.

The definition now copies the native template's menu_anchor, menu_anchor_down, toolbar_side, plugins_grow_direction, toolbar_icon_file and title anchor/side as initial native defaults. No numeric replacement toolbar offsets are introduced. Native selection applies them once; saved/customized instances are not silently migrated or reselected.

The native RefreshAttributeTextSize subtracts a count-based button width but does not move a title past a left-side toolbar. A single prototype-scoped posthook fits the existing native FontString to the actual visible toolbar bounds, converting effective scales and keeping its native vertical placement. Buttons are only read. Font, size, text, timer, profile values and button geometry are not overwritten. Very narrow windows temporarily paint the title transparent when no space remains, restoring its previous alpha when space returns; native visibility and content remain intact. Long titles use the native bounded text region. Normal, bottom and hidden-button arrangements are respected. Native title anchors are released on switching away without overwriting newly applied native points.

The hook runs on native title-layout changes, not row updates or timer ticks. Repeated unchanged cosmetic refreshes do not reanchor or resize the title. Original production helpers and PR #91 are unchanged.

Material values remain derived from the unchanged historical GetMeterStyle sources: fallback body black at .75 alpha; header 27/255 RGB at alpha 1. Native SetBackgroundColor/SetBackgroundAlpha/SetBackdropTexture paths are exercised to verify one effective body fill, and native RefreshTitleBar applies the flat header. No extra material layer or new palette is added to guess at screenshot differences. Exact rendered parity still requires WoW screenshots.

The source fixture runs native MenuAnchor, ToolbarSide, ToolbarMenuSetButtons, AttributeMenu, RefreshAttributeTextSize and surface setters across 432 geometry configurations, including narrow widths, scales, toolbar sides, sizes and visibility. Hosted anchor resolution is a model of UI geometry, not WoW rasterization or taint validation.

## Native title accent default correction

The approved prototype at 01b74dc6c32e78032510c9fc6e47b05bf511f33c copied GetMeterStyle.titleColor into its native definition once during registration. That shared helper intentionally follows EUI Damage Meters' hdrTextUseAccent / hdrTextColor preferences. A custom yellow EDM title therefore produced a yellow native selection default even when the current EUI accent was different. Registration also left the definition unchanged after an accent change before selection.

The prototype alone now reads S.GetAccentColor(), the existing public EUI Skin API getter, for attribute_text.text_color in its own native definition. It updates that default through the existing safe appearance refresh, only when RGBA actually differs. It never recolors a FontString, changes an applied instance, installs another color hook, or writes saved preferences. All other rendering/default values and the legacy GetMeterStyle implementation are unchanged.

Details' native ChangeSkin reset/default path deep-copies the definition when selecting a different skin. AttributeMenu reads the instance attribute_text.text_color, and native SetFontColor plus DF ParseColors apply that RGBA immediately and again in Details' own delayed callback. The correction adds no timer or retry. Native same-skin refresh and restored profile values remain authoritative.

Accent/theme changes update **future selection defaults only**. Existing windows retain their current title color, whether originally chosen by the default or explicitly customized. This avoids guessing whether a saved yellow is intentional and introducing a second preference-tracking system. Previously saved yellow is not silently migrated; change it in Details' native title-color control if desired. Re-selecting the already selected skin does not reset its defaults. No automatic ChangeSkin or profile migration is performed.

The screenshot alone cannot establish whether the installed window obtained yellow from the EDM custom preference, a stale definition, a saved Details profile, or embedded color markup in native title content. Hosted tests reproduce the first two defects and verify the native color pipeline; they cannot inspect the user's installed profile. Native title strings are never rewritten.

Regression coverage uses the actual pinned official InstallSkin, ChangeSkin reset/default path, AttributeMenu, SetFontColor and DF ParseColors. It covers a conflicting EDM yellow preference, live accent default refresh, manual RGBA, the native delayed callback, independent windows, saved-profile reconstruction, combat deferral, and 1,000 unchanged refreshes without additional title writes, hooks or UI objects. The identical targeted test must fail against 01b74dc and pass after the correction. Existing geometry, toolbar and Cooltip tests remain in the full suite.

In WoW Forever, verify a fresh explicit selection uses the current EUI accent; customize its title color, reload and switch profiles; check another window independently; then change the EUI accent and confirm existing saved colors stay unchanged while a new selection uses the new accent. Confirm title text, timer, font, geometry, toolbar and meter surfaces are unchanged. Installed-client persistence, taint and rendering remain live-client checks.

## Optional meter independence

The prior native prototype referenced EllesmereUIDamageMeters/Media/dm_*.png and skipped toolbar repaint when that optional addon was not loaded. That directly explains the native atlas icons in one screenshot and thin outline icons in the other. Registration also imported GetMeterStyle's EDM profile, font and texture registry; initial header height/color/alpha, body and bar defaults could therefore differ with optional-addon availability. The shared helper and production legacy integration are intentionally unchanged; the native adapter no longer consumes those values.

The self-contained native defaults use the exact historical fallback values listed above and the public S.GetFont / S.GetAccentColor sources. Installed default media is client WHITE8X8 or this addon's toolbar files. Applied instance settings are not reset or migrated, including intentional custom colors, sizes, fonts and textures. Existing native profiles can still reference optional textures/fonts chosen previously; the skin cannot replace those arbitrary user choices without violating ownership. Use native Details options to choose an available asset when such a profile references an uninstalled provider. Selecting another native skin resets appearance preferences under Details' own rules; back up profiles first.

### Media ownership

EllesmereGaming/EllesmereUI at e95e531ad99ddb8ae3901c4fdc9fffd98e7f56bb has an all-rights-reserved license excluding unspecified third-party resources. No file-specific redistribution grant for its dm_*.png files was established. None are copied, converted or bundled.

The owner approved using licensed outline equivalents. This package instead rasterizes unchanged Feather v4.29.2 icons (settings, rotate-ccw, file-text, radio, refresh-cw, plus and x), pinned at 1b002399e8758fb2bccea4d07312dc9e0f43dcb8, under Cole Bemis' MIT license. They preserve the outline visual language, meaning, native slot size and .65/1/.25 state tinting; exact glyph shapes are not claimed identical to EUI's PNGs. The complete upstream notice ships in Media/DetailsNative/LICENSE.txt. Original SVGs, source pin and generator are development-only. No client-side rasterization or new runtime textures/frames are added. scripts/build_details_native_media.py reproducibly creates 32x32 uncompressed white-RGB alpha TGA assets in read-only GitHub Actions.

### Version footer

The pictured text matches native startup.lua: Details! followed by userversion and (core realversion). The pinned boot.lua uses build 15410 / core 172, matching the screenshot, but does not prove every installed file is identical. Native startup explicitly shows the lower window's version FontString, schedules FadeStartVersion after 12 seconds, then requests a two-second fade. In Details' fade engine, "in" means hiding. This is independent of the optional meter. Screenshots taken at different startup times can legitimately differ; their exact elapsed time is unknown.

The native adapter never changes _version text, alpha, visibility or its timer. Source fixtures execute the actual startup block and fade engine and verify that cosmetic refreshes neither suppress the visible footer nor revive it after the native fade. A footer persisting beyond that native lifecycle needs live investigation; no speculative hide or global fade hook is added.

### Verification

The enabled/disabled/missing matrix compares fresh native definitions and registered media, plus existing windows under availability/global changes. Native redraws restore bundled toolbar art without querying the optional addon. Manual RGBA, row/font/texture/geometry choices, accent-default behavior, combat recovery and multiple windows remain covered. Exact prior-head tests reproduce both the toolbar dependency and imported optional defaults, and pass after the correction. Existing official-source, layout, sizing and Cooltip tests remain.

In WoW, compare the same saved native profile in sessions with EUI Damage Meters enabled, disabled and absent. Verify header/body and all toolbar states, resize controls natively, test profiles/reload, two windows, combat and title-color customization. Compare the new licensed glyphs with the approved outline treatment. Observe the native version footer shortly after login and again after its fade. Hosted fixtures cannot establish rasterized parity, installed-client persistence or live taint safety.

## Toolbar polish, native body fallback and encounter-timer default

The follow-up baseline is 93074946e3ce9ee52baf35d5dc9c8b53219ebd92. The current change remains inside the experimental adapter, licensed toolbar assets and directly related tests/build documentation. No native toolbar dimensions/anchors, header height, bar settings, title content, legacy skin or Cooltip code changes.

### Toolbar evidence and changes

Pixel measurements of the tracked 32x32 TGA alpha bounds (threshold 16) showed every original glyph already vertically centered at y=16. The undo glyph was horizontally centered at x=15; the others at x=16. Therefore transparent vertical padding was not the cause of the whole toolbar sitting low within the header. Native MenuAnchor/GetMenuAnchorPoint anchor the buttons to native corner/menu points independently of the flat title band's height. The DF button constructor uses native button texture states and zero pushed-text offset; the prototype had no button/texture positioning writes.

The rebuild retains the original licensed Feather source SVGs and MIT notice, changes rendering stroke width from 2 to 2.5, gives round caps room with a -1/-1/26/26 view box, centers measured glyph bounds at 128px before downsampling, and keeps the same 32px file format/canvas. All final measured glyph centers are (16,16). Alpha coverage increases roughly 4–9%, depending on the glyph. Normal tint changes from .55 to .65; hover/pushed remain 1 and disabled .25. No native button or texture-region geometry, scaling, alpha/visibility state or callback is replaced.

This improves readability and consistent in-button artwork. It intentionally does not move the native toolbar upward relative to the header: doing that would violate native geometry ownership. A native toolbar placed low by its saved anchors can remain low relative to the band. Actual optical alignment, engine Texture region bounds and rasterized appearance still need WoW review; alpha-bound tests cannot prove header-relative pixel alignment.

### Body evidence and correction

Historical 3553aca8e386c77be2c1af20a719117c14199df2 renders one matte color-texture body from GetMeterStyle: fallback black at .75 alpha, with native baseframe/bgdisplay backdrops removed. The prototype default is also black at .75 and uses client WHITE8X8. Two .75 fills would composite to .9375 before parent fading, so duplicating layers is not a valid restoration.

The prior adapter unconditionally suppressed bgdisplay while assuming the baseframe had an equivalent painted backdrop. Native ChangeSkin can clear the base backdrop in its rounded-corner path, and other native redraw/profile states can leave it missing. Suppressing the remaining fill then removes the body, regardless of the configured .75 value. The source fixture reproduces native baseframe backdrop removal and fails against the prior adapter.

P.Background now checks both native backdrop definitions, file identity and guarded RGBA before suppressing a duplicate. If the base fill is absent/different, it keeps or restores the native bgdisplay surface using the current native bg_alpha, including explicit zero. Release also uses current native opacity rather than a stale suppression snapshot. No new fill, alpha compensation, backdrop rebuild, profile write, hook or geometry calculation is added.

The .75 initial default remains unchanged. Native parent/interaction/combat alpha still multiplies it (e.g. .75 * .7 = .525); the adapter must not cancel that user setting. Wallpaper, user colors and textures remain native-owned. The screenshot cannot establish the installed frame alpha, saved background opacity, wallpaper or rounded state, so the demonstrated source defect is not claimed to explain every captured pixel. A normal window already painting a single .75 fill should remain unchanged, and visual parity is still pending.

### Native timer default and customization

The definition initializes attribute_text.show_timer=false for a new native selection. No timer formatting, ticker, title text or FontString is replaced. Native CheckForTextTimeCounter uses that flag to decide whether to start encounter-time updates, and the Designer's applyTitleText passes it to AttributeMenu. The pinned source implements the same setting as the Forever build metadata reviewed earlier, but exact installed files cannot be inspected.

Existing Addonskins EUI windows retain their saved flag. To disable it without resetting any other setting, use Details! → Options → Designer → Title Text → Show Encounter Timer. Users can turn it on again; ordinary refreshes, same-skin updates, theme changes, profile restoration and reload do not force it off. Native skin switching itself can reset appearance preferences, so back up profiles before intentionally selecting a different skin.

Tests cover the actual native Designer setter and encounter-start scheduling, false initial defaults, later true preferences and saved-profile reconstruction. Existing source/layout/color/availability/sizing/Cooltip regressions and exact-package verification remain enabled. Hosted fixtures do not prove live WoW taint safety or pixel-perfect rendering.

## Initial native header alignment and legacy-setting wording

Reference: 234312c087803a83a8aa2e51cd474ae45ca5d447. The native definition inherited Minimalistic's title anchor (1.4,2) and right toolbar anchor (20,0), but uses a 22-unit flat band and an 11-unit native title font. Native RefreshAttributeTextSize uses text_size+2 for its title region. Native MenuAnchor/GetMenuAnchorPoint use 128-unit corner textures, a 16-unit top offset and 1x1 menu points.

For the normal initial native size (16 units), the inherited title center was 8.5 and toolbar center 7 units above the body, against a header center of 11. The rightmost 16-unit button could also extend 4 units outside the window. Glyph alpha bounds were already centered; no artwork or texture changes are needed.

The native definition now computes initial title/menu offsets from its own header/text/button dimensions and verified native corner coordinates. On the pinned source, title Y becomes 4.5; right-toolbar anchor becomes (13,4), giving centers of 11 and a 3-unit right margin. These are derived UI-unit coordinates, not an extra render-time pixel translation. Header height, font, button size and click targets are unchanged. There are no new hooks or instance/profile migrations. A same-skin refresh, reload or new definition registration does not overwrite existing native positions. Existing custom windows retain their values; new native selection follows Details' own skin-reset rules.

### Native customization and limits

All subsequent native layout changes win. Larger/smaller toolbar buttons, different title fonts/sizes or side changes may require native Position Y adjustment: continuously recentering them would override deliberate user positions. The existing horizontal title-fit helper is unchanged and does not enforce the new default Y.

Details deliberately lists menu_icons among instance_skin_ignored_values, so a native skin cannot safely replace retained menu_icons.space via its definition. Negative retained spacing (native default -2) explains crowded glyphs, independently of the band offsets. This change does not bypass that native protection, shrink artwork or force a new gap. Adjust Details! → Options → Designer → Title Bar → Buttons and Menu Settings → Button Spacing if desired; Position X/Y and Button Size remain there as well. Continuous centering or automatic spacing replacement is outside this non-invasive change. Native skin switching may reset non-exempt native appearance values, as before; back up profiles before switching.

### Legacy settings clarity

The quick submenu, central Details! provider and Legacy options page now say **Legacy Details! Styling**. Descriptions identify it as the older automatic method and direct users to Details! → Options → Skins → Skin Selection → Addonskins EUI for the native prototype. No new setting or alias exists: the saved meter key, getters, setters, callbacks, synchronization and restore semantics are unchanged.

Fresh installation defaults are legacy meter Off, Tiny Threat Off and menus/options On. Explicit saved false/true values take precedence. Historical saves with no tiny field still inherit meter as before; this presentation change does not migrate them. Native Addonskins EUI selection is independent of the legacy meter switch.

The regression fixtures now load the actual native ignored-values table and ResetInstanceConfigKeepingValues function, replacing the prior simplified reset stub. They verify retained spacing, same-skin custom anchors/sizes, initial source-native header centering at 12 scale/width combinations, three settings labels/descriptions, fresh defaults without binding writes, saved preferences, legacy/native isolation and existing 432 native geometry configurations. Reverting the initial-default correction must fail the centering assertion.

Actual glyph optical centering, engine pixel rounding, installed Forever profile persistence and live taint safety still need in-game review. The built-in native layout does not promise automatic centering after every user geometry change; no invasive enforcement is added to claim otherwise.

## Native reload/profile persistence correction

Reference: 309997d084cb4ce038174e2cea9b3510f77bab2b. This pass changes no visual defaults.

The native core/parser.lua ADDON_LOADED(Details) initializer runs LoadConfig → ApplyProfile while IsLoaded is still false. ApplyProfile copies each saved window and activates it. On first construction AtivarInstancia calls RestauraJanela, which calls InstanceColor. If the provider is absent, InstanceColor invokes instance:WaitForSkin. WaitForSkin records the selected name and temporarily replaces instance.skin with the built-in fallback. The customized native values are still intact at this point.

Our previous late InstallSkin processed that wait by calling instance:ChangeSkin(Addonskins EUI). Since the instance now had the fallback identity, ChangeSkin treated it as a different skin, called ResetInstanceConfigKeepingValues and applied the prototype instance_cprops. This registration-time reset lost customization. The previous reload fixture only reconstructed a same-skin in-memory window after registration, omitting RestauraJanela/InstanceColor, so it did not test this transition.

The correction verifies each Addonskins EUI pending entry against the active native profile. For windows still using the fallback or the originally selected prototype, it preserves that original selected skin identity immediately before native InstallSkin processes the entry. Native ChangeSkin then takes its normal same-skin refresh branch and skips both ResetInstanceConfigKeepingValues and instance_cprops application. No appearance property, profile export or SavedVariables table is replayed or written. Only the live selected-name metadata and this provider's native pending entries are adjusted.

The existing ChangeSkin observer now forwards explicit native selections to a cancellation helper. Choosing any other native skin, including the currently displayed fallback, cancels our pending recovery. No new hook is installed. Stale own entries cannot reselect the prototype over a different current skin/profile; foreign pending entries are untouched. Rejected installation restores prior identity/pending ownership. Missing active native profile data emits a bounded diagnostic and leaves registration pending rather than inventing defaults.

This happens only on successful late registration of an already selected, waiting native skin. Ordinary registration refreshes, accent changes, meter updates and profile switches do not replay any settings. There is no secondary preference store, extra native preset application, repeated restoration hook or poll. The provider remains no_cache: disabling/removing it leaves fallback handling to Details rather than retaining a cached external provider/media definition.

Native limitations remain: explicitly selecting a different skin can reset non-exempt appearance fields; native horizontal row padding is read from instance_cprops.row_info.space by ShowSideBars/HideSideBars. Preferences already saved over by an older failing session cannot be reconstructed; use a native profile backup where needed. Native button spacing is ignored by the reset in the pinned sources, so that field was not independently shown to reset through this path; it is still checked across both reload cycles.

The fixture executes pinned upstream InstallSkin, WaitForSkin, ChangeSkin's actual reset/configuration prefix, ResetInstanceConfigKeepingValues, LoadInstanceConfig, RestauraJanela, InstanceColor, the activation prefix, ExportSkin, SaveProfile, SaveLocalInstanceConfig, ApplyProfile, LoadConfig, OptionPanelOnChangeSkin and the actual parser initializer. It loads the native ApplySavedSkin importer to assert that our fix never calls it. Engine UI/data services are isolated stubs. Plain SavedVariables are serialized into fresh Details/provider environments twice, across two windows and profiles. Assertions cover toolbar size/spacing/XY, title XY/font/size/color/timer, old and structured bar fonts, bar height/spacing/texture/background-by-class, body opacity, newer live startup edits, profile saves/switches, accent refreshes, combat, closed windows, explicit native choices, foreign waiting ownership, absent profiles and rejected-install retries. Registration cannot mutate profile tables. CI must fail against the exact prior head at the reload assertion and pass after correction.

Hosted tests establish configuration flow and bounded callbacks/resources, not engine rendering, exact installed Forever files or live taint safety. In-game reload/profile acceptance remains required.
