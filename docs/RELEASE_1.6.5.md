# Release 1.6.5 preparation

Status: draft for maintainer review. No merge, tag or publication is authorized.

## Version and integration

The latest published GitHub release and highest release tag are `v1.6.4`.
Current main is `f3d48bd8325a2efaac6c398d5391f2934493d81a`, with version 1.6.4
in Core, all three TOCs and both changelogs. Its tree matches `v1.6.4`.
No newer published version or tag, open release PR or existing `release/1.6.5`
was present at preparation. The historical `release/1.7.0` head `05aca2d`
is already an ancestor of main: that OneForAll release was renumbered to 1.6.3
before publication. It does not reserve the next version. The verified next
version is **1.6.5**.

`release/1.6.5` starts at current main and merges only PR #75,
`skin/restedxp-forever` at `f71c8a8cf30c43aa984d69d43d58e7de46789aa5`,
retaining its 29 commits and the original draft PR. The merge is conflict-free;
main is the merge base. No PR was merged on GitHub. Release preparation changes
only Core's version, three TOC versions, both changelogs and this document.

## Selected scope and dependencies

- RestedXP V1 and V2 Forever designs, accepted visual refinements and compatibility.
- Theme switching, pooled/owned window restoration, native actions and semantic colours.
- Opacity preferences, explicit 0%/100%, reset and the 75% Forever default.
- V1/V2 performance and stability work, including the final combined audit.
- Required support from #75: opt-in legacy popup styling in `Menus.lua`, six
  runtime artwork assets, package asset validation, regressions, benchmark and
  diagnostic development tools and audit documentation.

The menu helper's look/shell/colour options are used by RestedXP; default callers
and modern menu ownership/restoration remain covered by the complete suite.
Reviewed popup callers include Atlas, KiwiFarm, Questie, Angrier World Quests,
LiteMount, HandyNotes, NovaInstanceTracker and shared scoped/menu routing.
No other open PR is required. No shared-file conflict was encountered.

Excluded open PRs:

| PR | Reason |
| --- | --- |
| #71 Auctionator Settings input / Extended Search | Separate unfinished addon work; only its already released hotfix remains inherited from main. |
| #69 AtlasLoot Forever | Separate work; native target bootstrap defect and live verification remain open. |
| #40 World Quest Tracker | Explicitly on hold; excluded. |
| #39 Waypoint UI | Explicitly on hold; excluded. |
| #73 Work browser release documentation | Independent documentation change, not a dependency. |

Other unmerged branches `planning/skin-queue` and
`skin/auctionator-selection-highlight` are excluded. The latter contains an
owner-requested revert; neither branch is release input. Other remote branch
heads were already ancestors of main. No branches or published tags are retired.

## Compatibility and validation

The existing interface matrix is retained: Forever/Camelot `16001`; Mainline
`120000, 120001, 120005, 120007, 120100, 120105`. Generic, Camelot and Mainline
TOCs retain identical runtime manifests, dependencies and project identifiers.
No claim is made that the Forever design ports upstream RestedXP to another
client. Source-based RestedXP checks use v4.11.34 at `b4a0f99a`.

The maintainer confirms that RestedXP V1/V2 designs, functionality, theme
switching and 75% default passed in-game testing. That acceptance supersedes
older visual-pending notes in PR #75's iterative history. Automated checks do
not independently establish live taint, frame timing or long-session memory.

Final validation results and the CI run for the exact release commit are
recorded in the release PR. The required command is `python3 scripts/package.py`:
runtime Lua syntax, all 44 registered suites, 43 deferred skin factories,
version/client manifests, required artwork, exact MIT license and ZIP integrity.
The local Windows run uses Python 3.12 and Lua 5.4.2 with an ignored local
library-name mapping; repository runners and assertions are unchanged.
GitHub's Ubuntu validation remains the authoritative native runner check.

Packaging uses the explicit runtime allowlist: one `EUIAddonSkins/` directory,
66 files, all three TOCs, 43 skins, required shared Lua/assets and MIT LICENSE.
Tests, scripts, diagnostics, benchmarks, docs, screenshots, reference sources,
README/changelog copies and local test dependencies are excluded.
`.pkgmeta` retains the folder promotion, exclusions, manual root changelog and
EllesmereUI dependency required by the existing CurseForge Auto-Packager.
Static packaging compatibility is checked without uploading or firing a tag
webhook. Remote package output and platform availability can only be verified
after separately authorized publication.

The performance audit remains applicable because all runtime Lua except Core's
version and all assets are identical to audited `f71c8a8`. Its measured reduction
in duplicate V2 theme work is retained; host measurements are not FPS claims.
See [the final audit](RESTEDXP_PERFORMANCE.md#final-combined-v1v2-audit).

Local final verification passed all 44 suites and the independent ZIP check:
66 unique entries, all 43 skin files and three TOCs, exact tracked runtime
allowlist, source-byte parity, MIT license parity and no development files.
The archive is 373,591 bytes. `.pkgmeta` and both workflows are unchanged.
Five fresh-process benchmark trials each for the release and audited adapter
match all warm operation counters: V1 step 1,646 total calls with zero hierarchy
reads; V2 row refresh 125 calls and resize 5,785 calls, both with zero hierarchy
reads; V2 theme refresh 9,925 calls. Every warm probe creates zero UI objects,
hooks or events. Closed idle has zero adapter calls, queued work and churn.
Warm allocation churn also matches. Cold first-open profiling has small
run-to-run differences despite identical adapter code; timing and post-GC
variation on this Windows host are not new performance claims.

## Known upstream issue

RestedXP's native `GetNpcName` reads tooltip text and matches it without guarding
secret strings. The audit's source-shaped probe failed identically with and
without AddonSkins, before the adapter's display post-hook, and its resolver
function identities were unchanged. This is an upstream RestedXP investigation,
not a confirmed EUI AddonSkins defect or a fix supplied by this release. Actual
client taint circumstances remain unestablished; no upstream parser changes are
included. See [the evidence and limits](RESTEDXP_PERFORMANCE.md#stability-and-secret-string-investigation).

## Draft GitHub release notes

### EUI AddonSkins 1.6.5 — RestedXP Forever V1/V2

- Added the approved Forever designs for RestedXP V1 and V2, with matching guide,
  Current Step, Active Targets/Items, menus and copper navigation artwork.
- Improved theme switching and native window/control restoration.
- Forever backgrounds default to 75% opacity. Existing saved overrides remain;
  Reset restores the current look's default. Standard keeps its existing look.
- Reduced repeated styling and duplicate V2 theme work while retaining native
  guide actions, quest colours, scrolling and combat deferral.

Requires EllesmereUI with Blizzard Skins+ enabled. Install RestedXP separately
using a version for your client. The maintainer has approved V1/V2 in-game
testing. Automated performance results are host-Lua measurements; live frame
timing, taint and long-session memory remain unmeasured.

Once published, download **EUIAddonSkins-1.6.5.zip**, extract its
**EUIAddonSkins** folder into **Interface/AddOns/**, replace the previous folder
and restart the game. Keep SavedVariables to retain settings. GitHub's source
archives are not installation packages.

Known upstream issue: RestedXP's `GetNpcName` can encounter restricted tooltip
text. The source-based audit reproduced the same failure with and without this
skin. This release does not modify RestedXP's parser or claim to fix that issue.

The existing addon collection and MIT license are retained. Unfinished
Auctionator, AtlasLoot Forever, Waypoint UI and World Quest Tracker work is not
included.

## Review and publication boundary

Require successful final release-branch and PR validation before approval.
Remaining release actions require explicit maintainer approval: merge the
validated PR, create/push a version tag, publish the GitHub Release and allow
CurseForge/Wago publication. No publication workflow is dispatched during
preparation. Secret/webhook settings and actual platform packages must be checked
as part of the authorized publication procedure in [RELEASING.md](RELEASING.md).
