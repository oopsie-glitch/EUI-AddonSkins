# Deferred activation alpha

Version `1.4.0-alpha.5`, untagged `loader-alpha`, based on stable skins. Other skin-development branches remain separate. No release tag or CurseForge/Wago publication is created.

## Installation

Extract the single `EUIAddonSkins` folder into `Interface/AddOns/`. If upgrading from alpha.1–alpha.4, remove the old sibling `EUIAddonSkins_*` module folders. They are not used by alpha.5, but WoW will still list them if left installed. Keep your saved variables. Generic, Camelot and Mainline TOCs have identical runtime lists, preventing older client-specific manifests from selecting the previous setup.

## Activation

Every skin Lua file loads at startup and registers a small factory. The factory body does not run until its target is installed, enabled for the current character, loaded, and permitted by EUI. Missing/disabled targets have no EUI toggle. Enabled load-on-demand targets keep their toggle and activate when loaded; the collection never force-loads a target. Activation waits out combat. Failed factories are isolated and not repeatedly retried. Successful factories are released after use.

Modern enable-state checks use UnitGUID, matching Blizzard's addon-list implementation; legacy checks use UnitName. Metadata is cached per character. Existing EUI registration names, saved preferences, shared namespaces and skin bodies are preserved. There is no extra per-frame polling and no child-addon loading API. The core's event listener handles late targets and combat recovery.

This uses the single-addon deferred-function pattern also seen in AddOnSkins, implemented independently with EllesmereUI's API. No AddOnSkins code/assets are bundled. It is deferred activation, not deferred loading of Lua files. Unused definitions still cost parsing and retained code memory. Startup, memory and FPS gains have not been measured in WoW.

## Checks

`python3 scripts/package.py` validates versions, every TOC/runtime path, all 20 skin definitions and the single-root ZIP with MIT LICENSE. It runs 15 suites covering the actual TOCs, only-BugSack filtering, the reported GUID/name/account mismatch, deferred factories, late EUI/targets, disabled toggles, combat, failure isolation, reuse, shared callbacks and all existing skin regressions. No in-game verification of this version is claimed.

The ZIP contains 34 runtime files under one addon folder. Development tools and documentation remain in GitHub and outside the player ZIP. `.pkgmeta` again promotes only the core addon directory.

`/euiskins diagnostics` opens a copyable report on request. Its final column now says "skin activated": all definitions are read at startup, so it no longer claims that inactive skin files were left unloaded.
