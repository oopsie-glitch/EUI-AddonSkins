# EUI AddonSkins

EllesmereUI skins for World of Warcraft addons.

## Supported addons

- Forever Companion
- Forever Dungeon Journal
- RestedXP Guides (legacy and V2 windows)
- Auctionator
- Spy
- What’s Training?
- ItemRack
- KiwiFarm
- Myslot
- BugSack
- Altoholic
- Attune
- TwitchEmotes (popup menu)
- Questie (Journey, settings, tracker styling and popup menus)
- Deadly Boss Mods (options window and controls)
- AtlasLootClassic Continued
- GTFO (settings controls)
- Gargul (windows, dialogs and menus)
- Details! (meter windows, options, breakdown/report windows and menus)
- ThreatClassic2 (meter, context menu and options)

Each skin is optional and only activates when its addon is loaded.

## Installation

1. Install EllesmereUI and enable its Blizzard Skins+ module.
2. Copy the `EUIAddonSkins` folder to `Interface/AddOns/`.
3. Enable EUI AddonSkins and restart the game.

Install the addons you want to skin separately.

## Settings

Toggle individual skins in **Blizzard Skins+ > Window Skins > Third-Party Addons**.
Details appearance is opt-in. Hover its settings icon > **EUI AddonSkins** for independent Details meter, Tiny Threat and menus/options switches. The same controls are available through `/euidetails`.

Skins follow EUI's theme and accent settings. Run `/reload` after disabling a skin.

## Commands

- `/euiskins` — show version and skin status.
- `/euiskins on` or `/euiskins off` — enable or disable the collection; then `/reload`.
- `/euiskins refresh` — refresh loaded skins.

## Issues

Include the affected addon's version, any Lua error and a screenshot.

See [CHANGELOG.md](CHANGELOG.md) for changes.

ItemRack’s secure equipment buttons and Attune’s quest graph/map retain their artwork and status colors. Myslot’s private import-progress dialog and shared Blizzard tooltips keep their existing styling. Altoholic, KiwiFarm, RestedXP and TwitchEmotes popup menus use temporary EUI styling while open.

DBM combat alerts, timer bars and preview content retain DBM’s styling. Its newer Blizzard Menu popups are not included in this skin.

## License

EUI AddonSkins is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Disclaimer

EUI AddonSkins is an independent third-party addon and is not affiliated with, sponsored by, or officially endorsed by EllesmereUI or the developers of the supported addons.

All trademarks and addon names belong to their respective owners.

EUI AddonSkins integrates with EllesmereUI's public skinning API. EllesmereUI and the supported addons are developed and distributed separately and are not included in this project.

## Deferred activation alpha

This experimental branch installs as one `EUIAddonSkins` folder. Skin definitions load at startup; implementation factories wait for an enabled, loaded target and its EUI toggle. Missing/disabled targets have no toggle or active integration. Existing settings are preserved.

When upgrading from the earlier multi-folder alpha, remove its old `EUIAddonSkins_*` module folders, then overwrite `EUIAddonSkins` with this ZIP. Those obsolete folders are no longer used. See [loader documentation](https://github.com/oopsie-glitch/EUI-AddonSkins/blob/loader-alpha/docs/LOADER_ALPHA.md).

## Callback audit alpha

The `acegui-audit-alpha` branch builds on the single-folder loader alpha and reduces repeated refresh work in DBM, Details, Gargul and ThreatClassic2. See [audit and mock measurements](https://github.com/oopsie-glitch/EUI-AddonSkins/blob/acegui-audit-alpha/docs/ACEGUI_AUDIT.md). No platform release has been published.
