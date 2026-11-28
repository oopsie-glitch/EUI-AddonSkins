# AtlasLoot Classic-only styling investigation

Status: blocked pending the source of the installed three-mode AtlasLoot build.
No runtime correction has been implemented or claimed.

## Baseline and confirmed adapter behavior

Published v1.6.8 and current main both point to
`0e388c8fc9fd635d5ec50d2a78d83a843005b7fd`.

`Skins/AtlasLootContinued.lua` accepts any AtlasLoot.GUI table. It does not
inspect the target's selected native UI skin. Its roots include the main GUI,
Favourites and the AtlasLoot AceConfig window. It hooks GUI Create, Toggle,
RefreshStyle, RefreshFonts, ForceUpdate and RefreshButtons plus item, sound,
Favourites and owned options lifecycles.

The main-root visitor replaces backdrop details and font/control discovery
also runs for the owned subtrees. This is consistent with the reported
Forever background interference and Atlas Nav font conflict; the precise
native interleaving cannot be established without the matching implementation.

## Why availability-only gating is insufficient

Core checks a module's available callback before its one-time install.
Scoped's later refreshes do not re-check that callback. Hooks created through
Widgets check the addon skin's enabled toggle, not AtlasLoot's native UI mode.
Some dropdown callbacks style menus synchronously before queueing refreshes.
Therefore changing only available() would not protect a session that changes
from Classic to another mode.

The public EllesmereUI skin API reviewed at
`EllesmereGaming/EllesmereUI@d84a1e19d0b63a9a944dd8023e436290a1b7a173`
documents disabling installed skins as reload-bound, and does not export a
general restoration/unregister operation. Shell and primitive artwork may
also receive engine-owned look updates. A namespace/mode guard alone is not
proof that previous font/backdrop changes or those callbacks have been retired.

The native mode-switch lifecycle must be inspected before deciding whether
AtlasLoot recreates separate windows, resets existing cosmetics, or requires
reload. Do not invent skin fields, guess numeric mode IDs, replace shared
factories, or introduce broad restoration snapshots without ownership evidence.

## Source investigation and exact limitation

The public Continued source located at
[danielandersson/AtlasLootClassic-Continued](https://github.com/danielandersson/AtlasLootClassic-Continued/tree/f8f716082e009b6842aaad2299480ff9e6082daf)
exports GUI.RefreshStyle but contains no Classic/Forever/Atlas Nav selection
system in its GUI or a skin-registry module. It is not a verified substitute
for the user's installed build.

Public GitHub repository/code searches also located separate AtlasLoot forks
and ForeverLoot, but none was verified as the reported three-mode version.
The old experimental AtlasLoot Forever PR #69 uses a different supplied
archive and is not imported or modified.

A read-only GitHub Actions request to the publicly documented Continued
project metadata endpoint (project 1270310) returned HTTP 403. It supplied no
matching archive or selection API. No protection bypass, credentials or local
filesystem operation was attempted.

A GitHub-hosted ZIP or repository link for the installed version is required.
The chat has requested that source. It will be inspected in cloud tooling;
upstream code/assets will not be redistributed in the player package.

## Work remaining once source is available

1. Verify TOC/build identity and the native selected-mode getter/registry.
2. Trace initial selection, profile/reload restoration and every transition.
3. Gate all classic styling, menu callbacks, font/backdrop enforcement and
   engine-owned theme handling at the correct ownership boundary.
4. Retire or restore only our Classic cosmetics before another native mode
   takes ownership; reapply the unchanged Classic rendering on return.
5. Reproduce the released regression and cover Classic -> Forever -> Atlas Nav
   -> Classic, login/reload in each mode, menus/options, themes and combat.
6. Run complete regressions, source-backed lifecycle checks, packaging and
   resource benchmarks; then provide an actual fix ZIP for in-game review.

No new support for Forever or Atlas Nav is proposed. Their native UI must be
untouched. Keep the investigation draft and do not merge/tag/publish it.
