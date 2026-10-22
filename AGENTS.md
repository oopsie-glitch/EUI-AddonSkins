# Working on EUI AddonSkins

Read CONTRIBUTING.md and docs/RELEASING.md before changing code or preparing a release.

## Engineering checks

Read docs/ENGINEERING.md before adding a skin, changing shared utilities or reviewing performance. Use benchmarks/README.md to choose repeatable workloads. Historical reports in docs/history/development are evidence for earlier snapshots, not pending work. Carry forward unresolved concerns in the relevant task or release notes.

## Branches and scope

- Start each task from current main: skin/<addon>-<change> for an integration, fix/<shared-change> for shared code, chore/<maintenance> for tooling/docs.
- Keep branches focused and untagged. Do not combine unrelated addon changes until preparing release/<version>.
- Keep main's runtime at the latest validated release. Documentation and build-system maintenance may follow without a new addon version. Update Core, client TOCs and changelog versions together at release preparation, not independently in each task branch.
- Before retiring any branch, verify its head is an ancestor of main. Preserve unmerged work, contributor pull requests and published tags. Record retired branch heads in docs/history/BRANCHES.md or a merged pull request.

## Shared Lua changes

- Put addon-specific behavior in its skin module. Do not change every integration's defaults to fix one addon.
- Before editing Widgets.lua, Scoped.lua, Core.lua, Loader.lua, Accent.lua, Menus.lua, MeterStyle.lua, DetailsSettings.lua or DetailsLayout.lua, inspect their callers across all skins and relevant tests.
- Prefer existing options or a small opt-in extension with backward-compatible defaults. Keep target-specific detection and layout values in the skin module.
- Review shared changes in a focused commit. Identify affected integrations and explain intended effects on both opted-in and unaffected callers.
- Preserve native actions/returns, secure-frame handling, coroutine behavior, target/toggle gating, load order, dynamic controls and theme/accent refreshes.
- Coalesce construction/setter bursts or repaint only owned controls. Preserve synchronous completed-window/tab styling where it prevents native UI flashes. Do not add global AceGUI replacements or polling to solve an integration-local problem.
- Add meaningful regression coverage for the reported failure and affected existing callers. For callback changes, include dynamic controls, repeated calls/hook reuse, disabled skins and combat deferral where applicable. Do not weaken existing assertions to make a merge pass.

## Integration and validation

- Retain each skin's RegisterSkinDefinition factory, the single-folder packaging layout, Lua catalog, Python packaging catalog and all client TOC entries. New integrations must appear in all relevant catalogs/manifests.
- Merge complete, selected work into one release branch. Resolve shared-file conflicts by preserving both intended behaviors; never choose one entire file blindly.
- Run python3 scripts/package.py on the combined final tree. It validates Lua, the regression suite, manifests, version and installation ZIP. Rerun after runtime or packaging changes.
- Review the complete diff, excluded development files, exact MIT license and all required runtime files before publication. CI is validation only; it must not upload on branch pushes or pull requests.
- Actual WoW behavior is not established by mocks. Report limitations honestly and leave changes whose safety cannot be justified untouched; do not require the user to profile or debug the addon to complete feasible checks.
- Published tags are immutable. Publishing requires explicit user instruction. Use the existing release workflow and exact validated commit; no duplicate tags or unnecessary platform uploads.
