# Releases

GitHub is the source of truth. Stable version tags publish to CurseForge through its existing official Auto-Packager webhook and to Wago through `.github/workflows/wago-release.yml`. Ordinary branch pushes publish to neither platform.

## One-time setup

- **CurseForge:** retain the GitHub push webhook and **Package tagged commits only**. Keep the token-bearing endpoint secret. Do not add CurseForge upload credentials to the Wago workflow; `-p 0` explicitly disables its CurseForge target.
- **Wago:** project ID `aN0a2M6j` is recorded as `X-Wago-ID` in the TOC. Create an API key at https://addons.wago.io/account/apikeys and save it directly in GitHub **Settings > Secrets and variables > Actions > New repository secret**, named `WAGO_API_TOKEN`. Never commit or paste the key into chat.
- Allow GitHub Actions to run the pinned checkout and BigWigs Packager actions. The workflow requires only read access to repository contents; it does not create GitHub Releases or upload to other addon platforms.

The Wago secret and a successful real upload have not been verified by repository preparation alone. A webhook success also does not prove that CurseForge published a file. Check both platforms after the first intended release.

## Versions and channels

Update `EUIAddonSkins/EUIAddonSkins.toc` and its `_Camelot.toc` / `_Mainline.toc` copies (`## Version`), `EUIAddonSkins/Core.lua` (`ns.VERSION`) and both changelog copies together. Addon versions omit the tag's leading `v`.

| Tag or push | CurseForge | Wago |
| --- | --- | --- |
| Stable tag, e.g. `v1.2.0` | Release | Stable |
| Beta tag, e.g. `v1.2.0-beta.1` | Beta | Skipped |
| Alpha tag, e.g. `v1.2.0-alpha.1` | Alpha | Skipped |
| Untagged development branch | No package | No package |

The Wago job skips prerelease tags and validates exact `vMAJOR.MINOR.PATCH` syntax, matching TOC/Core versions, the release changelog and project ID before uploading. Testing in the public `development` branch stays untagged. Keep `main` for stable releases; commit each validated change to development and merge it into main when preparing a release. A public alpha/beta release requires an explicit tag and currently publishes only to CurseForge.

## Release procedure

1. Prepare the intended stable code, version and concise changelog on `main`. Review the diff; do not promote experimental integrations accidentally.
2. Run `python3 scripts/package.py`. This validates Lua syntax, runs the regression suites, checks TOC paths/version consistency and builds an install-ready local ZIP without uploading.
3. Confirm the CurseForge webhook remains enabled in tag-only mode and the Wago secret is configured. Do not tag while preparation or authorization is incomplete.
4. Create an annotated tag on the validated commit and push it. For example, after preparing version `1.2.0`:

   ```sh
   git tag -a v1.2.0 -m "EUI AddonSkins 1.2.0"
   git push origin v1.2.0
   ```

5. The CurseForge webhook queues its package. GitHub's **Publish stable release to Wago** workflow checks metadata, credentials and tests, then runs BigWigs Packager with the existing `.pkgmeta`, Wago project ID and all other upload targets disabled.
6. Verify the Actions result and each platform's packaging logs, release type, game versions and publication/approval status. Upload completion is not proof of public availability. The two services run independently; they need not finish at the same time.
7. Inspect the downloaded packages: exactly one `EUIAddonSkins/` folder, its TOC, every referenced runtime file, all supported skins/assets and the exact MIT LICENSE. Exclude tests, scripts, benchmarks, docs, `.github`, reference sources and nested installation folders.
8. Publish the corresponding GitHub Release from the existing tag with concise release notes and a validated install ZIP. Automatic GitHub source archives include development files and are not installation packages.

Published tags are immutable. Do not recreate a tag or rerun a successful Wago upload blindly: inspect the existing platform version before retrying. A failed Wago run can be rerun through Actions after fixing credentials, without pushing the tag again or retriggering CurseForge. Code or package fixes need a new version.

## Packaging

`.pkgmeta` sets `package-as: EUIAddonSkins` and moves `EUIAddonSkins/EUIAddonSkins` into `EUIAddonSkins`. Ignore paths apply before the move. Both services use this configuration. `.github` and development files remain in GitHub but are excluded from downloads.

The addon LICENSE is tracked and matches the root MIT LICENSE. README/changelog copies stay out of the player ZIP; the root changelog supplies package release notes. No external addons are bundled. Required and optional dependencies remain in the TOC; check platform dependency listings after upload.

The actions are pinned to reviewed commits. Review upstream changes, including game-version handling, when updating those pins. Local mocked tests and packaging checks do not establish in-game compatibility or prove platform publication.

## References

- https://support.curseforge.com/support/solutions/articles/9000197281 — official Auto-Packager
- https://support.curseforge.com/support/solutions/articles/9000197952-preparing-the-packagemeta-file — package layout
- https://docs.wago.io/ — Wago project IDs and API authentication
- https://github.com/BigWigsMods/packager — supported packaging directives and upload targets
