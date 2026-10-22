# 1.3.0 integration preparation

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

This untagged preparation branch combines:

| Source | Commit | Work |
| --- | --- | --- |
| acegui-audit-alpha | 1c565f8d627b219549c118e2413f52c213800eaf | Single-folder loader and callback audit; includes loader-alpha |
| pallypower-alpha | 139ad407297bd2ca326a514daa9d46b3c78696a2 | PallyPower and Altoholic; includes development |
| bugsack-alpha | 4f6479a0b6c0395e39fbec304e38826a1e1d983a | BugSack cleanup |

## Merge decisions

- Retain target-aware factories and the new local/queued control refresh APIs in Scoped.lua. Add PallyPower's borderless-button option without replacing the audit improvements.
- Combine BugSack's opt-out of shell/portrait accents with PallyPower's borderless assignment controls in Widgets.lua.
- Preserve Altoholic and BugSack factory wrappers; wrap PallyPower in the same deferred factory and add it to the Lua/packaging catalogs and every client TOC.
- Keep all existing regression fixtures and add PallyPower's suite. Client-manifest tests cover no eligible targets, BugSack only and PallyPower only. Loader tests include PallyPower's late/combat-deferred activation and single activation.
- Consolidate unreleased changelog entries into 1.3.0 and retain prior stable history. Historical alpha reports remain in docs; they describe their original branches.
- Keep the independent PallyPower borderless-button parameter in both sides of the callback benchmark, so the baseline run changes only the audit callback/scanning paths under investigation.

## Validation

`python3 scripts/package.py` checks Lua syntax, executes 16 suites, validates all three identical client manifests, the version, every runtime path and the complete 21-skin catalog. It builds `EUIAddonSkins-1.3.0.zip`: 35 files inside one EUIAddonSkins folder, including the original MIT license and icon. Development files and third-party addon sources are excluded.

`python3 scripts/benchmark_callbacks.py --baseline /path/to/loader-alpha.5` reruns the source-shaped callback comparison. Results remain in acegui-callback-results.json. These are mock scan counts, not CPU/FPS measurements. No actual WoW client verification is claimed.

## Preparation status (before publication)

This section records the original preparation checkpoint. Version metadata and release notes were prepared for 1.3.0. No tag or platform release is created by this preparation commit. The existing alpha branches and main remain unchanged. The release notes are in releases/v1.3.0.md; follow RELEASING.md for final publication. Ordinary branch pushes do not run the stable Wago uploader, and CurseForge is configured for tagged commits only.
