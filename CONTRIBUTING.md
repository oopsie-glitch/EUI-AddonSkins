# Development

Start with [the Design & Development Standard](docs/DESIGN_AND_DEVELOPMENT.md) for visual identity, implementation references and the authoritative reading path.

## Branches

| Branch | Purpose |
| --- | --- |
| main | Latest validated release runtime, plus documentation/build maintenance |
| skin/<addon>-<change> | One addon addition or fix, such as skin/altoholic-scrollbar |
| fix/<change> | One shared-code fix, such as fix/acegui-refresh |
| chore/<change> | Tooling or documentation maintenance |
| release/<version> | Selected changes combined for the next release |

Create task branches from current main. Keep them untagged: ordinary pushes and pull requests run validation, not publication. There is no permanent alpha branch per addon and no standing development branch to keep synchronized. Open a pull request against main for review; work can stay open until selected for release.

Keep addon version and release changelog changes on the release branch. A test ZIP from an untagged branch is not a published release; identify it by branch and commit when sharing it. If a distinct in-game prerelease version is needed, update it on the integration branch before building. Do not create a tag just to build a local test ZIP.

## Shared code

Keep target-specific behavior in Skins/<Addon>.lua. Change shared helpers only when needed; prefer existing options or opt-in behavior that preserves other callers' defaults. Inspect callers before changing a helper and cover the affected behavior with regression tests. Put shared helper changes in a focused commit so their impact is reviewable.

| Area | Existing checks to review |
| --- | --- |
| Widgets, Scoped, menus and generic controls | skin, batch, legacy_controls, menus, performance, new_addons |
| Core, loader, registration and manifests | package, loader, loader_modules, collection, toggles |
| Theme and accents | accent, features and affected integration fixtures |
| Meter styling and Details settings/layout | details, threat |
| PallyPower, protected controls and Ace options | pallypower plus shared control/loader fixtures |

These are starting points, not a replacement for checking callers. The automated workflow runs the full suite for every branch push and pull request. It uses read-only permissions, no publishing credentials and no upload steps.

## Release integration

1. Create release/<version> from current main. List the selected task branches/commits.
2. Merge the selected work, retaining commit history. Review overlapping shared-file edits explicitly and keep every applicable regression test.
3. Set one consistent version and concise changelog. Run python3 scripts/package.py against the combined tree and inspect its ZIP. Automated checks cannot establish in-game appearance or taint safety.
4. Review the final diff and CI result, then promote that exact validated runtime to main. Publish only when requested, following docs/RELEASING.md.
5. Confirm the publication status independently on each platform. Retire task/release branches only after verifying their heads are included in main. Published tags preserve the release; do not move or delete them.

If more development lands during release preparation, update the release branch and rerun the checks. An individual branch passing does not establish that the combined release passes.

Read [the engineering checklist](docs/ENGINEERING.md) before adding a skin or changing shared callbacks. Historical reports remain in docs/history/development; retired branch heads are recorded in docs/history/BRANCHES.md for traceability.
