# Addonskins EUI — experimental native Details skin

This community prototype is opt-in and is not affiliated with or endorsed by EllesmereUI. It does not replace the approved standalone integration. Main and PR #91 remain unchanged.

## Try or stop using it

Back up the current profile using Details' native profile interface before selecting a different native skin: Details resets non-exempt appearance settings when changing skins.

Open Details Options → Skins → Skin Selection and choose **Addonskins EUI** for the intended window. Native group editing can affect several selected windows. No installation/login/theme callback explicitly selects it.

Continue using native Details options for bars, fonts, toolbar geometry, titles, timer visibility and profiles. To leave, select another native skin. The existing EUI meter matching preference applies again to non-prototype windows; turn it off if you want the alternate skin without legacy meter matching. Before removing this experimental build, select an available native skin for every prototype window, save the profile and reload.

The definition uses no_cache=true: no new definition is persisted in Details' skin cache. Missing-provider fallback is owned by Details; the native waiting-skin mechanism can restore a previously selected skin when registration becomes available. We do not rewrite saved skin names or install a second restoration system. Removing the provider before switching away can therefore cause native fallback/reset behavior.

## Native configuration

DetailsNative.lua copies Minimalistic's compatible atlas/layout metadata without mutating it. instance_cprops starts from a deep copy of the active build's instance_defaults, not Minimalistic's custom profile. Values are initialized once through native selection:

- GetMeterStyle supplies the exact existing EUI source values: fallback body RGB 0/0/0 and alpha .75; header RGB 27/255 each and alpha 1; header height 22 and title font size 11; bars height 18, spacing 2, left/right sizes 11 unless current EUI meter preferences specify otherwise.
- SharedMedia registers the existing resolved font/bar paths and WHITE8X8 flat header/body resources.
- Native title enabled, native timer/content retained, initial accent text color.
- Native flat header, .5 subdued full border, no sidebars/status bar/rounded corners, hidden attribute icon.
- Native class/status color defaults are retained; native bar texture/font/height/spacing and ordinary total/DPS formatting are initial settings, not refresh-time writes.
- Menu size, position, visibility, scale, window position and other native ignored fields follow Details' own skin-switching rules.

The renderer continuously consults skin definitions for some horizontal row padding. That native exception is not bypassed. Color/font/theme changes are not automatically copied into the chosen profile after selection: native customization wins. Reselecting the same skin normally refreshes current values rather than resetting defaults; use native saved appearance/profile controls when intentionally restoring a saved configuration.

## Hybrid layer and coexistence

The only new setter hooks are Details SetBackgroundColor and SetBackgroundAlpha. The native bgdisplay duplicate backdrop fill is tinted transparent; baseframe retains the native chosen color/alpha. No backdrop reconstruction, geometry reads/arithmetic, replacement fill frame or tooltip hook is added.

Existing native toolbar state textures are reused for the approved dm_*.png artwork when EllesmereUIDamageMeters is loaded. No new artwork objects, button anchors, dimensions, scripts or hitboxes are created. Native hover/pushed/disabled textures retain native interaction. If those optional media are unavailable, native icons remain.

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
