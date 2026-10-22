# EUI AddonSkins 1.6.0 — Expanded Addon Support

Adds 19 new skins, bringing the collection to 41 supported addons.

### New skins

- AllTheThings
- Angrier World Quests
- CraftSim
- Decor Vendor
- Guild Roster Manager
- HandyNotes
- HekiLight
- Home Bound (including Blueprints)
- LiteMount
- Nova Instance Tracker
- Pawn
- Premade Groups Filter
- Quest Completist
- RareScanner
- RCLootCouncil
- Scrap
- SimulationCraft
- Talent Loadout Manager
- World Quests List

### Improvements and fixes

- Auctionator: replaced oversized settings checkboxes and yellow ticks with compact accent-coloured square indicators, preserving click areas and settings.
- DBM: safer restoration of shared options fonts.
- Added scoped refreshes and control reuse for the new integrations to reduce repeated styling work.
- AllTheThings: adjustable window opacity and support for its auction-house panel.
- Nova Instance Tracker: flat backgrounds at 80% opacity, compact controls and local styling for newly created log rows.

## Requirements and installation

Requires EllesmereUI with Blizzard Skins+ enabled. Install the supported addons separately, using versions for your client. Client coverage varies by addon; this collection does not port addons between Retail and Forever.

Download **EUIAddonSkins-1.6.0.zip**, extract its **EUIAddonSkins** folder into **Interface/AddOns/** and replace the previous folder. Keep SavedVariables to retain settings, then restart the game.

Toggle skins in **Blizzard Skins+ > Window Skins > Third-Party Addons**. Only installed, enabled targets appear; each skin activates when its target loads.

The combined build passes Lua syntax, all 41 automated suites and package validation. Automated checks do not establish every client/addon combination's in-game appearance, taint safety or FPS.
