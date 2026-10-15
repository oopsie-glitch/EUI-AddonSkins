# Load-on-demand alpha

Version `1.4.0-alpha.2`, untagged branch `loader-alpha`, based on stable `b8e0125`. This experiment does not merge PallyPower, BugSack or Altoholic development branches. No release tag or platform upload is created.

## Installation and behavior

Extract every `EUIAddonSkins*` folder from the single ZIP into `Interface/AddOns/`. There are 21 sibling addon folders: the core and 20 load-on-demand skin modules. Keep the child modules enabled in WoW's addon list; they do not load automatically. Existing skin Lua files left by an older install are no longer in the core TOC and do not execute. Saved variables and existing EUI registration names stay unchanged.

The small catalog checks target installation and character enable state. Missing/disabled targets get no toggle and execute no skin implementation. Enabled load-on-demand targets keep a toggle, but their skin code loads only once the target is loaded and EUI enables the skin. Loading is deferred during combat. The loader never loads the target addon itself and never changes addon enable state. Changing enabled addons normally takes effect after a reload.

The core's existing ADDON_LOADED / PLAYER_LOGIN listener also handles activation; PLAYER_REGEN_ENABLED handles combat recovery. There is no OnUpdate loop or recurring timer. Target metadata is cached per character. A failed child load is reported once and isolated, without repeated retries on unrelated events.

Each child TOC declares LoadOnDemand and a dependency on the core. The controlled GetSkinNamespace entry point returns the original shared namespace only during an authorized child load, preserving shared callbacks used by Details. Existing skin bodies are unchanged; the production namespace bootstrap is the only change to the moved implementation files. Shared helpers and existing Details settings/layout utilities remain in the core.

## Automated checks

Run `python3 scripts/package.py`. It validates every core/child TOC, version, runtime path, dependency, Lua file and ZIP entry, then runs 15 suites. New tests cover absent/disabled targets, late target loads, EUI toggle restoration, combat deferral, modern/legacy metadata signatures, failure isolation, single loading, and all 20 actual relocated skin files with separate WoW namespaces. Existing skin regression tests still run against the moved files.

With all targets absent, the actual core TOC test executes zero skin implementation files and registers zero irrelevant toggles. The core still loads shared utilities and a roughly 4 KB loader/catalog. This is not an in-game memory, CPU or FPS measurement. Actual WoW behavior, taint and perceived startup gains have not been measured.

The local archive contains 21 sibling directories and 54 runtime files; MIT LICENSE is in the core. Development files are excluded. `.pkgmeta` moves each existing module directory out of the checkout wrapper, following the official packager's move-folders behavior. Local validation checks the expected contents; an official CurseForge packaging job has not been triggered on this untagged branch.

## Upgrading an existing install

The core ships matching generic, Camelot and Mainline TOCs. The official packager generates client-specific manifests; WoW can prefer those over the generic TOC. The alpha.1 local ZIP omitted client-specific files, so extracting over a CurseForge install could leave an older manifest active. Alpha.2 overwrites both supported manifests with the loader file list. Tests execute all three core manifests with only BugSack installed and enabled and require exactly one EUI toggle. No EUI saved preferences are deleted.
