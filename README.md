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
- BtWQuests (Retail journal, category/chain views, search and menus)
- BugSack
- Altoholic
- Attune
- TwitchEmotes (popup menu)
- Questie (Journey, settings, tracker styling and popup menus)
- Deadly Boss Mods (timer bars, options, range/radar and info frames)
- AtlasLootClassic Continued
- GTFO (settings controls)
- Gargul (windows, dialogs and menus)
- Details! (meter windows, options, breakdown/report windows and menus)
- ThreatClassic2 (meter, context menu and options)
- PallyPower (Blessing Assignments, options, menus and buff controls)
- World Quest Tracker (Retail options, tracker rows, quest icons and menus)

Each skin is optional. Only installed, enabled targets appear in EUI settings; their skins activate when the target loads. Everything installs in one addon folder.

## Installation

1. Install EllesmereUI and enable its Blizzard Skins+ module.
2. Copy the `EUIAddonSkins` folder to `Interface/AddOns/`.
3. Enable EUI AddonSkins and restart the game.

Install the addons you want to skin separately.

## Settings

Toggle individual skins in **Blizzard Skins+ > Window Skins > Third-Party Addons**.
Details appearance is opt-in. Hover its settings icon > **EUI AddonSkins** for independent Details meter, Tiny Threat and menus/options switches. The same controls are available through `/euidetails`.

RestedXP's navigation-arrow skin can be toggled in **Options > AddOns > EUI AddonSkins**.
KiwiFarm skin options are under **Appearance > AddonSkins** in its right-click menu, including separate stats/menu opacity and background style.

Skins follow EUI's theme and accent settings. Run `/reload` after disabling a skin.

## Commands

- `/euiskins` — show version and skin status.
- `/euiskins on` or `/euiskins off` — enable or disable the collection; then `/reload`.
- `/euiskins refresh` — refresh loaded skins.
- `/euiskins diagnostics` — show copyable target and activation status.

## Issues

Include the affected addon's version, any Lua error and a screenshot.

See [CHANGELOG.md](CHANGELOG.md) for changes.

ItemRack’s secure equipment buttons and Attune’s quest graph/map retain their artwork and status colors. Myslot’s private import-progress dialog and shared Blizzard tooltips keep their existing styling. Altoholic, KiwiFarm, RestedXP and TwitchEmotes popup menus use temporary EUI styling while open.

PallyPower support targets the Forever beta layout. Its original lock button, secure actions, status colours and native layout are preserved.

DBM timer and range/radar/info appearance can be adjusted through **Skin Options** beside its options window. DBM controls positioning, size and spacing; encounter warning colours and behaviour remain native.

## License

EUI AddonSkins is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Disclaimer

EUI AddonSkins is an independent third-party addon and is not affiliated with, sponsored by, or officially endorsed by EllesmereUI or the developers of the supported addons.

All trademarks and addon names belong to their respective owners.

EUI AddonSkins integrates with EllesmereUI's public skinning API. EllesmereUI and the supported addons are developed and distributed separately and are not included in this project.
