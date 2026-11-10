# Spy texture-settings regression investigation

Status: **open; no runtime fix has been applied**. This is a release blocker for
the Spy integration. The maintainer observed the failure in WoW Forever with EUI AddonSkins enabled.
They have clarified that an isolated comparison with only EUI AddonSkins disabled
has not been performed. Skin causation is therefore a hypothesis, not a confirmed
reproduction result. The installed Spy version is likely 1.3.8-forever5 but is
not verified: cloud repository/package evidence cannot inspect the installed client.

## Verified source and failing operation

GitHub Actions downloads the official Spy 1.3.8-forever5 archive:
https://edge.forgecdn.net/files/9501/070/Spy-1.3.8-forever5.zip

Archive SHA256:
`f0373e3cb8a31864d41532e08fb5748f42f0a76f45b2c4c9b0bbd92efe14fbec`.

The statusbar widget (version 12) calls
`AGSMW:GetDropDownFrame()` at StatusbarWidget.lua:143. The shared prototype
(library revision 9003) constructs an anonymous Frame without a template at
prototypes.lua:208 and calls `frame:SetBackdrop(frameBackdrop)` at line 211.
**SetBackdrop is the nil operation in the supplied stack trace**, for this
source version. No texture selection callback has run when it fails.
The later Slider constructor also lacks a backdrop template and calls
SetBackdrop; fixing only the first call would not validate the entire popup.

Exact source SHA256:

- prototypes.lua: `b91f176401c605a0a9aa20acba5d7c68be4a92478ee3086a206633d2cfdad327`
- StatusbarWidget.lua: `4874591d8c0809f4811d058b9f46088f101a75510e55a743594408f3613a3ae4`

Spy's BarTexture option selects `LSM30_Statusbar`. Its native setter saves
`Spy.db.profile.BarTexture` and invokes `Spy:UpdateBarTextures()`.
The adapter does not replace that option, setter or library widget.

## Scope of the audit

Reviewed the current Spy adapter, its settings FeedGroup/OnShow scans, window
backdrop clearing, Standard/Forever restoration, shared Widgets/Scoped helpers,
and official EUI SkinAPI, WindowEngine and frame-pool sources. The inspected
code clears backdrop data conditionally; it does not delete the SetBackdrop
method or replace the global CreateFrame factory. Clearing a backdrop and
removing its API are distinct operations.

The archive-wide Spy source audit found no compatibility replacement of this
popup constructor. Spy's own main/title windows and its bundled ordinary
AceGUI dropdown explicitly inherit BackdropTemplate; the SharedMedia popup
and its Slider do not. This establishes a concrete capability mismatch,
**not whether enabling EUI AddonSkins changes the live outcome**.

Potential load-order/library-winner differences and the exact live client
capabilities remain unverified. The pinned package and inspected EUI commit
are source evidence, not proof that every installed library byte is identical.
Do not label the reported regression an upstream-only defect.

## Automated reproduction and limits

The optional SPY_SOURCE path in tests/spy_spec.lua now executes the unmodified
official prototypes.lua and StatusbarWidget.lua. The fixture models a modern
plain Frame without backdrop methods, constructs the real LSM30_Statusbar
widget, sets its native list/value, and invokes the native drop-button script.

The expected failure must identify prototypes.lua:211 and SetBackdrop, and the
popup must have been constructed without a template. This is repeated with
the adapter disabled after installation and with Standard, Forever and
Automatic selected. The test also checks that refreshing the adapter did not
replace the global frame factory.

This is an **expected-error investigation test**, not a passing functional
dropdown regression. An adapter-disabled fixture is not a fresh WoW session
with the addon absent. It cannot establish the reported enable/disable
difference or prove a repair in WoW.

The existing broad Spy suite still covers the established design, native row
textures/colours, menu/settings persistence, geometry, combat deferral,
restoration and bounded warm work. It previously gave all mock frames
SetBackdrop, so it could not expose this capability mismatch.

## Decision and remaining work

No BackdropTemplate workaround, global AceGUI/SharedMedia patch, frame-factory
hook, replacement widget or silent error suppression has been added.
Runtime files and visuals remain byte-identical to investigation baseline
`74c63cefc0ecc475a8b369bf16bd7ced6e92898e`.

Before selecting the smallest source fix, establish the exact installed Spy
version and client/build, and the outcome of the same interaction after
disabling only EUI AddonSkins and reloading with all other addons unchanged.
The missing evidence is whether there is a live EUI-specific interaction, not
permission for local access. All further work remains cloud-only.

After a justified fix, functional acceptance must cover Interface settings
open/create, popup open, different texture selections, native saved preference
and row updates, settings reopen, reload, all three styles and restoration,
combat recovery, and bounded widgets/hooks/artwork. Those checks are still
pending for this regression. In-game dropdown repair is not claimed.

## Follow-up: isolated native-library controls

The maintainer clarified that the error occurred in WoW Forever with the skin
enabled, and no isolated disabled-skin comparison has been confirmed. This
supersedes the earlier description of a confirmed EUI-only regression.

tests/spy_sharedmedia_spec.lua adds a fresh, restricted Lua environment with
no EUI code loaded. It executes the actual bundled AceGUI-3.0 core (minor 41),
SharedMedia prototypes (revision 9003), Statusbar widget (version 12) and the
BarTexture option table extracted from Spy.lua. The native UI API and
LibSharedMedia data source are modeled; this is not the WoW client.

| Host capability model, with no EUI loaded | Observed result |
| --- | --- |
| Plain frames lack backdrop methods | Exact prototypes.lua:211 failure before native option setter |
| Frame methods available, Slider methods absent (test control) | Reaches the later untemplated Slider and fails on its SetBackdrop |
| Legacy backdrop methods available | Native popup construction/selection succeeds |
| Backdrop methods available on all frames (test control) | Native popup construction/selection succeeds |

The controls do not patch the official source and are not production fixes.
They isolate the capability assumption and show that EUI is not required
to reproduce this source failure under that host model. They do not establish
whether WoW Forever has a compatibility provider, which runtime library wins
in the user's session, or whether enabling the skin changes either.

Positive controls exercise the actual widget and AceGUI pool, native texture
preview values, real BarTexture getter/setter, saved key, selected check mark,
scrollable lists, disabled click behavior, native enter/leave event forwarding,
hide/release, 200 reacquisitions, same-version library initialization and a
fresh environment with the saved profile. Frame/texture/font counts stay
constant through the repeated reopen workload. The native UpdateBarTextures
callback is counted, not a client render; existing Spy native-source tests
cover separate row update/texture-preservation behavior.

The isolated test does not open Blizzard's actual Interface settings or test
client taint/combat restrictions. Existing adapter tests remain responsible
for Standard/Forever/Automatic, restoration and combat deferral. There is no
new runtime artwork, hook, widget type, library patch or polling. No EUI-specific
source repair is justified yet by these results. Keep the live reported error
open without claiming either confirmed skin causation or a confirmed in-game fix.
