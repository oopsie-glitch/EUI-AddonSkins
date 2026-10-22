# Performance workloads

Keep these fixtures for repeatable regressions and before/after comparisons. They are development tools, excluded from player ZIPs; they do not run in WoW or at addon startup. Age alone is not a reason to remove a workload.

Run commands from the repository root. Python runners use Python 3 and the installed `liblua5.4.so.0`; direct Lua commands require Lua 5.4. No game client or publishing credentials are needed.

| Workload | Command | What it measures |
| --- | --- | --- |
| AllTheThings | `python3 benchmarks/run_att.py` | Warm native row/window interactions and skin object/hook/traversal counts |
| Guild Roster Manager | `python3 benchmarks/run_grm.py` | Warm settings/tab interactions against a large owned tree |
| RCLootCouncil | `python3 benchmarks/run_rc.py` | Cached entry lookups and retired voting-table traversal |
| Scoped hidden roots | `lua5.4 -e 'BENCH_ROOT="EUIAddonSkins"; dofile("benchmarks/scoped.lua")'` | Six option roots, one visible; shared Scoped.lua warm refresh cost |
| Scanner comparison | `python3 scripts/benchmark.py --baseline /path/to/old/EUIAddonSkins` | Identical 200-scroll-event workloads, median of five host trials |
| Historical callback comparison | `scripts/benchmark_callbacks.py` | DBM/Details/Threat/Gargul callback bursts from the original five-counter fixture |

The ATT/GRM/RC runners accept `--baseline` to load their pinned historical adapter from Git. Use a full checkout containing those commits; shallow clones may lack them. Their fixtures are tied to the named historical changes. An old baseline failing a newer functional assertion is a fixture-compatibility problem to investigate, not permission to drop that assertion.

The callback comparison runner predates the expanded regression suite and expects exactly five counter records. Keep it for reproducing its historical audit with matching fixtures; it is not a current-suite pass/fail command. Current callback regressions run through tests/run_lua.py. Do not weaken those checks to make a historical comparison run.

`scan.lua` and `scoped.lua` accept BENCH_ROOT pointing to the addon directory under test. Scan comparison's default historical path may not exist; pass an explicit baseline. The callback runner writes `docs/acegui-callback-results.json`; inspect that diff and do not overwrite historical evidence casually. Earlier recorded results also remain in `docs/benchmark-results.json` and [archived audits](../docs/history/development/).

These are mocks and host Lua measurements, not WoW CPU/FPS or retained-memory measurements. Most integration regression suites also contain warm-path operation counters; `python3 scripts/package.py` runs those as part of normal validation. See [the engineering guide](../docs/ENGINEERING.md) for interpretation and required functional checks.
