# EUI AddonSkins

EllesmereUI skins for World of Warcraft addons.

## Supported addons

- AllTheThings
- Altoholic
- Angrier World Quests
- Atlas
- AtlasLootClassic Continued
- Attune
- Auctionator
- BtWQuests
- BugSack
- CraftSim
- Deadly Boss Mods
- Decor Vendor
- Details!
- Forever Companion
- Forever Dungeon Journal
- Gargul
- GTFO
- Guild Roster Manager
- HandyNotes
- HekiLight
- Home Bound
- ItemRack
- KiwiFarm
- LiteMount
- Myslot
- Nova Instance Tracker
- OneForAll (Forever; supplied Retail-loadable builds require in-game verification)
- PallyPower
- Pawn
- Premade Groups Filter
- Quest Completist
- Questie
- RareScanner
- RCLootCouncil
- RestedXP Guides
- Scrap
- SimulationCraft
- Spy
- Talent Loadout Manager
- ThreatClassic2
- TwitchEmotes
- What's Training?
- World Quests List

Each skin is optional. Only installed, enabled targets appear in EUI settings; their skins activate when the target loads. Everything installs in one addon folder.

## Installation

1. Install EllesmereUI and enable its Blizzard Skins+ module.
2. Copy the `EUIAddonSkins` folder to `Interface/AddOns/`.
3. Enable EUI AddonSkins and restart the game.

Install the addons you want to skin separately. Client support varies by target addon and version; a skin does not make a Retail-only addon work on Forever, or the reverse.

## Settings

Toggle individual skins in **Blizzard Skins+ > Window Skins > Third-Party Addons**.

Open **Options > AddOns > EUI AddonSkins** for a searchable list of active configurable addons. The panel shows only the controls each integration supports. **Legacy options** remains available for the original shared page.

- Details! keeps its independent meter, Tiny Threat and menus/options switches. Use the meter settings icon or `/euidetails` for quick access.
- Spy offers Automatic, EUI Standard and EUI Forever, decorative background opacity and Reset Appearance. Use its right-click **EUI AddonSkins** menu or `/euispy` for quick access. The Forever look requires the supported Forever client and EUI appearance API.
- RestedXP offers style, opacity and its separate navigation-arrow toggle. Appearance Reset preserves the arrow preference.
- AllTheThings, RareScanner and KiwiFarm expose their existing appearance controls. KiwiFarm can also restore its native statistics font. Nova Instance Tracker windows retain their 80% background opacity.

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

## Development

See [the documentation index](../docs/README.md) for contribution rules, engineering checks, benchmarks and releases.

## License

EUI AddonSkins is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Disclaimer

EUI AddonSkins is an independent third-party addon and is not affiliated with, sponsored by, or officially endorsed by EllesmereUI or the developers of the supported addons.

All trademarks and addon names belong to their respective owners.

EUI AddonSkins integrates with EllesmereUI's public skinning API. EllesmereUI and the supported addons are developed and distributed separately and are not included in this project.

## Addon authors

If you prefer that your addon is not supported by this skin collection, please [open an issue](https://github.com/oopsie-glitch/EUI-AddonSkins/issues). The skin will be removed on request.
