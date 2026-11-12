# Settings canvas, Phase 1

The Blizzard AddOns category is registered at login. The canvas builds its
navigation and controls on first show. It uses built-in WoW templates for
search, scrolling and checkboxes, and small owned controls for choices,
sliders and actions. It does not load the EllesmereUI Options addon or use
a global AceGUI factory. Legacy options remain reachable from the canvas
and serve as the original category when the modern canvas API is absent.

Register a provider with `ns.RegisterSettingsProvider(catalogID, descriptor)`.
It declares a label and ordered options with stable keys and kinds
(`toggle`, `choice`, `slider`, `action`). Provide side-effect-free `get`
and validated `set` for values, or a `run` action; choices declare an
ordered list of label/value pairs and sliders declare min/max/step.
An optional provider-owned reset is an action. Existing setters call
`ns.SettingsPreferenceChanged(id, key)` after an actual committed value,
so either entry point can update an open page without another save.
Details! and RestedXP use their existing preference setters. No providers
are added for Spy or the other Phase 2 integrations.

The renderer hides absent targets, keeps installed inactive entries with
a reason, and defers to the existing loader without loading targets. A
page closed or in combat cannot invoke a bound setting. Registration and
binding do not initialize defaults. Only explicit sidebar selections save
`settingsUI.lastAddonID`; all existing appearance values stay in place.
The three Details! controls and arrow toggle gain no new reset behavior;
RestedXP's separate appearance reset still does not reset its arrow.

Native client review (Retail and Forever):

1. Open AddOns > EUI AddonSkins. With Details! and RestedXP installed,
   check alphabetical sidebar, restrained accent, compact rows and no
   clipping. Use a narrow settings panel and a larger UI scale; search
   and the options list must scroll without overlapping.
2. Filter with mixed case, no matches and clear. Use Enter to select the
   first match. Close/reopen and reload to check the remembered selection.
3. Change a Details! control from its quick menu and the canvas; both
   must show the same state. Verify /euidetails opens Details! and the
   Legacy options button still opens the old settings.
4. Toggle the RestedXP arrow with existing style/opacity values, including
   zero, and confirm they are untouched. Test installed inactive,
   absent targets and a session with no configurable addons.
5. Enter and leave combat with the page open. Verify disabled changes,
   working keyboard focus/scrolling, and unchanged check states on
   recovery. Close the canvas and resume normal gameplay.
6. Keep the old page through live parity review. Phase 1 uses a cycling
   choice control and a native slider foundation; no migrated option
   needs them yet. Production parity on both clients is the next gate.
