# 1.6.0 integration

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Selected 19 new skins and the DBM font-safety and Auctionator settings-checkbox fixes from the exact heads recorded in RELEASE_1.6.0_SOURCES.json. The performance review document is retained. The integration commit preserves those branch heads as parents.

Every selected input file was checked against its GitHub blob SHA. Runtime adapters and integration-specific tests retain the selected branches' exact contents. Shared loader/catalog/TOC/test-list additions were combined explicitly: 41 unique factories, 41 suites, one addon folder. No shared styling helper was replaced.

Excluded: Waypoint UI, World Quest Tracker, the superseded Hekili adapter, World Quest Tab and KeystoneLoot (native EUI support), and unimplemented queue entries. Development tools, tests, benchmarks and documentation remain in GitHub, outside the player ZIP. The DBM reference implementation checklist is complete. Decor Vendor is included at the owner's explicit request; its adapter includes no target source/assets/data, and the author's opt-out contact text is recorded in README/CURSEFORGE.md.

Auctionator's reported settings-checkbox issue is fixed and covered by automated regressions; this does not establish that every unrelated options control has complete styling. Remaining client combinations without current target evidence are not advertised as verified compatibility.
