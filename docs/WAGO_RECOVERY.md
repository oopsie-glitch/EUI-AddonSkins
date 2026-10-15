# Wago packaging recovery

The v1.3.0 workflow passed metadata checks and all 16 suites, then failed before upload because BigWigs Packager requires client-suffixed TOCs to contain only interface values for that client. The new loader manifests carried a combined list to replace stale client manifests.

The Wago workflow now filters only the Interface header of Mainline/Camelot manifests in its temporary checkout, after the source tests pass. Runtime files, load order and version remain unchanged. The generic TOC keeps all supported clients. This build step uses the pinned official BigWigs Packager and existing .pkgmeta.

For an existing stable tag whose Wago upload has not succeeded, use Actions > Publish stable release to Wago > Run workflow on main, entering the exact release_tag. The workflow checks out that tag and validates stable version metadata before uploading. Confirm the version is absent on Wago before retrying. This recovery does not move tags, create another release or invoke CurseForge packaging.

Ordinary branch pushes still publish nothing. Tagged stable pushes keep using the same workflow. Do not rerun an upload that already succeeded.
