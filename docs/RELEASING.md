# Releases

GitHub is the source of truth. Stable version tags publish to CurseForge through its existing official Auto-Packager webhook and to Wago through `.github/workflows/wago-release.yml`. Ordinary branch pushes publish to neither platform.

## One-time setup

- **CurseForge:** retain the GitHub push webhook and **Package tagged commits only**. Keep the token-bearing endpoint secret. Do not add CurseForge upload credentials to the Wago workflow; `-p 0` explicitly disables its CurseForge target.
- **Wago:** project ID `aN0a2M6j` is recorded as `X-Wago-ID` in the TOC. Create an API key at https://addons.wago.io/account/apikeys and save it directly in GitHub **Settings > Secrets and variables > Actions > New repository secret**, named `WAGO_API_TOKEN`. Never commit or paste the key into chat.
- Allow GitHub Actions to run the pinned checkout and BigWigs Packager actions. The workflow requires only read access to repository contents; it does not create GitHub Releases or upload to other addon platforms.

The v1.6.0 Wago workflow completed an upload successfully. Repository preparation or webhook delivery alone does not prove public availability on either platform; check publication separately for each release.

## Versions and channels

Update `EUIAddonSkins/EUIAddonSkins.toc` and its `_Camelot.toc` / `_Mainline.toc` copies (`## Version`), `EUIAddonSkins/Core.lua` (`ns.VERSION`) and both changelog copies together. Addon versions omit the tag's leading `v`.

| Tag or push | CurseForge | Wago |
| --- | --- | --- |
| Stable tag, e.g. `v1.2.0` | Release | Stable |
| Beta tag, e.g. `v1.2.0-beta.1` | Beta | Skipped |
| Alpha tag, e.g. `v1.2.0-alpha.1` | Alpha | Skipped |
| Untagged development branch | No package | No package |

The Wago job skips prerelease tags and validates exact `vMAJOR.MINOR.PATCH` syntax, matching TOC/Core versions, the release changelog and project ID before uploading. Keep task branches untagged. Combine selected changes on `release/<version>`, run the full checks, then promote the validated build to `main`. See [CONTRIBUTING.md](../CONTRIBUTING.md) for branch and shared-code rules. A public alpha/beta release requires an explicit tag and currently publishes only to CurseForge.

## Release procedure

1. Prepare the intended stable code, version and concise changelog on `release/<version>` from current `main`. Review overlapping shared-file changes and the complete diff. After the combined checks pass, promote the validated build to `main`; do not include unselected experiments.
2. Run `python3 scripts/package.py` and require a successful **Validate addon** CI run on the final integration. This validates Lua syntax, runs the regression suites, checks TOC paths/version consistency and builds an install-ready local ZIP without uploading.
3. Confirm the CurseForge webhook remains enabled in tag-only mode and the Wago secret is configured. Do not tag while preparation or authorization is incomplete.
4. Record the exact validated commit SHA after the merge and confirm **Validate addon** passed for that commit on `main`. Check whether the version tag, draft, or published release already exists before opening a new release form.

### Publish in the authenticated Work browser

Use the GitHub integration for pull requests and checks, and the authenticated Work browser for the release form. No local Git or PowerShell is required. An annotated tag points to a separate tag object with a tagger and message. A lightweight tag points directly to the commit. GitHub's release form creates a lightweight tag, as used for v1.6.3 and v1.6.4. An annotated tag is acceptable when supported by authenticated tooling, and a lightweight tag is supported for the browser workflow.

1. Open the repository's **Releases → Draft a new release**. If the tag already exists and resolves to the validated SHA, select it. Otherwise choose **Select tag**, enter the exact version (for example `v1.6.4`), click **Create new tag**, then click **Create** in the second dialog. Confirm the version appears on the form. The tag is created when the release is published.
2. For a new tag, verify that **Target** resolves to the validated SHA. Use `main` only if its current tip is that SHA. If the browser cannot select a ref at the exact commit, stop before publishing.
3. Enter the title and release notes, including any limits on in-game verification. Attach the validated install ZIP through **Attach binaries** using the browser-accessible copy. Select the appropriate release channel. Recheck the target immediately before clicking **Publish release**.
4. Verify the published release page and the tag's resolved commit SHA through GitHub. Confirm the release is public, the version and channel are correct, and the intended ZIP is listed and downloadable under **Assets**. Compare its digest with the validated ZIP when available. GitHub's automatic source archives are separate from the install package. If the browser times out, inspect the actual release and tag state before retrying.

### Verify distribution separately

| Service | Evidence to check |
| --- | --- |
| GitHub Actions | **Validate addon** passed on the released commit. Check the stable Wago workflow run for the version tag separately. |
| CurseForge | Check the tag push webhook delivery and Auto-Packager status where accessible. Confirm the exact version appears on the public project files page with the expected channel and game versions. A successful webhook delivery alone proves only that the event was received. |
| Wago | Check **Publish stable release to Wago** for the exact tag and inspect its upload result. Confirm the version appears on the public project listing. A green workflow alone does not establish public availability. |

Inspect downloaded packages using the layout below when accessible. Report each service independently with links and verified status. If a dashboard, packaging log, public listing or download is inaccessible, say exactly what remains unverified. Record any remaining action and the blocker. An attempted browser action is never proof of success.

### Recover a partial release

- **Tag exists, release missing or draft:** verify the tag resolves to the validated SHA, then complete the existing draft or publish a release using the existing tag.
- **Release published, ZIP missing:** edit the existing release and attach the validated ZIP. Verify the asset after saving.
- **Tag points to a different commit:** stop and report the mismatch. Published tags are immutable. Do not move or recreate them. Code or package fixes require a new version.
- **Distribution pending or failed:** check the platform and existing run before retrying. For Wago, see [Wago recovery](WAGO_RECOVERY.md) and rerun only a confirmed failed upload after fixing its cause. For CurseForge, check delivery and packaging history before using its supported recovery options. Never push a tag again or retry a successful upload to recover the other platform.

## Packaging

`.pkgmeta` sets `package-as: EUIAddonSkins` and moves `EUIAddonSkins/EUIAddonSkins` into `EUIAddonSkins`. Ignore paths apply before the move. Both services use this configuration. `.github` and development files remain in GitHub but are excluded from downloads.

The addon LICENSE is tracked and matches the root MIT LICENSE. README/changelog copies stay out of the player ZIP; the root changelog supplies package release notes. No external addons are bundled. Required and optional dependencies remain in the TOC; check platform dependency listings after upload.

The actions are pinned to reviewed commits. Review upstream changes, including game-version handling, when updating those pins. Local mocked tests and packaging checks do not establish in-game compatibility or prove platform publication.

## References

- https://support.curseforge.com/support/solutions/articles/9000197281 — official Auto-Packager
- https://support.curseforge.com/support/solutions/articles/9000197952-preparing-the-packagemeta-file — package layout
- https://docs.wago.io/ — Wago project IDs and API authentication
- https://github.com/BigWigsMods/packager — supported packaging directives and upload targets
