# DBM Range Check secret-number investigation

## Verdict

The second reported error is an upstream DBM-Core comparison, independent of
PR #103's aura-visibility correction. No additional EUI AddonSkins runtime fix
is justified. Do not patch DBM-Core, replace global APIs, or intercept its
range calculations from a cosmetic adapter.

Reviewed 2026-11-28:
- EUI AddonSkins v1.6.8 main: `0e388c8fc9fd635d5ec50d2a78d83a843005b7fd`.
- PR #103 runtime: `8830be491cf077639286609fe1f11e97899ee85d`.
- DBM stable 12.1.26: `b12b88d06e7812a9f2f26658400443ba48cbd57d`.
- DBM development: `fc433f76eba067f6704aa81340f40aeb61a6c58b`.
- Blizzard API documentation mirror: `ab5cb850a3f65e742959e379c4689353a2f4549f`.

The stable and development RangeCheck files are identical. No fix for this
comparison was found in the latest published release or current master.
Recent file history and targeted upstream issue/PR searches did not identify a
specific fix. That does not rule out an unpublished fix or a different installed
Forever distribution; the reporter's exact DBM and client builds are unknown.

## Source evidence and ownership

[Core_GUI.lua:46-50](https://github.com/DeadlyBossMods/DeadlyBossMods/blob/fc433f76eba067f6704aa81340f40aeb61a6c58b/DBM-GUI/modules/options/general/Core_GUI.lua#L46)
calls native `DBM.RangeCheck:Show(nil, nil, true)`.

[RangeCheck.lua:973-1020](https://github.com/DeadlyBossMods/DeadlyBossMods/blob/fc433f76eba067f6704aa81340f40aeb61a6c58b/DBM-Core/DBM-RangeCheck.lua#L973)
checks map restrictions/combat, builds or shows the native frames, and calls
`updateIcon()` when registering its controller's first events.
This icon update runs even in text-only mode and without a radar frame.

[RangeCheck.lua:759-761](https://github.com/DeadlyBossMods/DeadlyBossMods/blob/fc433f76eba067f6704aa81340f40aeb61a6c58b/DBM-Core/DBM-RangeCheck.lua#L759)
assigns `icon = GetRaidTargetIndex(unitList[i])`, then evaluates
`icon and icon < 9 and icon or nil`. The reported failing operation is
`icon < 9`. Testing truthiness with `icon and` does not establish public data.

[Blizzard's GetRaidTargetIndex declaration](https://github.com/Gethe/wow-ui-source/blob/ab5cb850a3f65e742959e379c4689353a2f4549f/Interface/AddOns/Blizzard_APIDocumentationGenerated/RaidMarkersDocumentation.lua#L36)
explicitly declares `SecretReturns = true`. Restriction is a property of the
native result; the error's DBM-Core taint label does not itself identify another
addon as its origin. The exact live condition making the value secret cannot
be recovered from this stack alone.

Our adapter does not read/replace GetRaidTargetIndex, change unitIcons or
unitList, or call RangeCheck:Show from refresh/theme code. It installs a scoped
post-hook on RangeCheck.Show to repaint existing owned surfaces.
That post-hook is not reached if native Show throws. Existing frame OnShow
cosmetics may run earlier when native Show displays a frame, but they do not
modify the raid-target API, its returned number, or the comparison.

PR #103 guards aura texture IsShown booleans, not raid-target numbers. Its
existing fix remains relevant to the first report only.

## Reproducible cloud tests

Run `python3 scripts/check_dbm_range.py` in GitHub Actions with system
`liblua5.4-0`. It retrieves the pinned official source and compiles the exact
updateIcon, Show and GUI OnClick bodies in a controlled fixture. The upstream
files are neither modified nor bundled. Only source identities/hashes and test
outcomes are logged.

The opaque test object raises from __lt at the same comparison. This is an
operation-level reproduction, not a WoW secret number or a live taint test.
Other native APIs and frame construction/rendering are mocked.

Cases cover:
- No EUI AddonSkins code loaded.
- Actual DBM skin adapter installed, then disabled.
- Actual DBM skin adapter enabled.
- Public nil/1/8/9 icon returns.
- Restricted-value comparison for party and raid tokens.
- The native restricted-combat early return.

The source-based fixture checks that a failed native Show never reaches its
post-observer, while public successful calls do. It is not a complete emulation
of Blizzard's secure hook implementation or C-side OnShow/render timing.
The full existing suite separately covers range/radar/info styling, native
interactions, deferred combat refreshes and the first secret-boolean fix.

No new runtime code, hooks, frames, events or recurring processing are added
by this investigation. Tests, source downloads, diagnostics and this report
remain excluded from the installable addon.

## Upstream bug report draft (not submitted)

**Title:** RangeCheck updateIcon compares a secret GetRaidTargetIndex result on Forever

**Observed:** Opening Range Check from DBM's General options produces:
`DBM-Core/DBM-RangeCheck.lua:761: attempt to compare local 'icon'
(a secret number value, while execution tainted by 'DBM-Core')`.

**Reported environment:** WoW Forever; exact installed client/DBM build not
provided. Source review confirms the unguarded comparison in stable 12.1.26
and master at the pins above. Do not describe 12.1.26 as the reporter's installed
version without checking it.

**Path:** Core_GUI OnClick -> RangeCheck:Show -> updateIcon ->
GetRaidTargetIndex(party/raid unit) -> icon < 9.

**Expected:** Restricted raid-target values should never be inspected with
Lua truth tests, ordering, string construction or table-index operations.

**Evidence:** The exact source-extracted native path fails with an opaque
comparison sentinel even when no EUI AddonSkins code is loaded. With the
adapter enabled/disabled it fails at the same native operation before the
Show post-hook. This does not establish a real DBM-only client reproduction.

**Suggested maintainer investigation:** Establish whether raid-target metadata
is needed in restricted/text-only modes. Guard the API return with a supported
secret-value check before any inspection, and use native class-dot/no-marker
behavior when the value is inaccessible. Review other consumers of unitIcons,
raid-target rendering and roster/raid-marker refreshes. This is a proposal for
DBM maintainers, not an EUI runtime workaround.

**Live confirmation still needed:** Record actual client and DBM build, group/
instance and combat state. Reproduce General -> Range Check with DBM alone,
then with EUI AddonSkins loaded/DBM skin disabled and enabled. Verify raid-marker
rendering, first open, repeated open/close and combat recovery. Do not claim a
DBM-only in-game reproduction or a fixed official version from hosted tests.
