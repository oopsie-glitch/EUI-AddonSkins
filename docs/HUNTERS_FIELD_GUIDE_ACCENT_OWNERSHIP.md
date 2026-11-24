# Hunter's Field Guide accent ownership review

PR #97 remains blocked. No new runtime correction is claimed.

## Revisions and source

- Current main: 82eb4fd5dc22a4bc973b9c47739d40a912f57c26, original HFG runtime bb24ae8.
- Previous PR #97 runtime: 2be3e53333114c75a76222fba8f259c11e13222e.
- Public current upstream: Hunter's Field Guide 1.3.0, CurseForge file 9780878.
- Archive SHA256: caa507c63478c10140478e231694e9d79883213010dfdd5007dc59244cceb941.
- The reviewed 1.1.1 archive was not available through the inspected metadata. Do not claim that 1.3.0 verifies every 1.1.1 constructor.
- Upstream source is read only in Actions, never logged, executed as an addon, committed or packaged.

## Confirmed root cause and ownership limit

UI.lua's local Style(fs, kind) reads skin.styles[kind], applies its font object and explicit RGB, and returns the FontString. It leaves no role marker on that object and is not exported through the addon namespace. Body, accent, good and bad styles share the body font object.

The earlier optimization records only text remapped from the original parchment accent or an already tracked label. A later FontString initialized with the current EUI accent matches neither path and is missed.

Adding every current RGB match is unsafe: an untracked accent label and an intentionally semantic label can have identical observable RGB and font identity. The original growing-history implementation changes both; #97 changes neither. Looking at their text content, stack traces or private Lua upvalues is not a supported ownership mechanism.

## Independently reproducible matrix

scripts/check_hfg_accent_ownership.py verifies the pinned upstream contracts, then extends the original source-shaped fixture with late accent and equal-RGB semantic controls. It evaluates the original runtime, previous #97 and current #97. The original passes the late accent behavior but fails preservation of the semantic control; #97 preserves that semantic control but fails the late accent behavior. Existing tracked hidden-label/native-recolor tests still pass.

A successful diagnostic workflow means those known failures were reproduced; it is NOT an acceptance pass or a corrected implementation. No additional hooks, FontObjects, per-label observers, private function replacements or RGB guessing were introduced.

## Remaining work

A complete correction requires a verified source-owned role marker or a supported style-application callback carrying both the FontString and role. That could permit weak-key role tracking and revoke ownership on explicit native recoloring without retaining historical colors. The current inspected source exposes neither. Do not patch the upstream addon or globally intercept font operations to manufacture that signal.

The existing test now stresses 2,000 alternating theme changes. Hosted five-trial benchmarks retain the original/previous/current distinction; current runtime equals the previous optimization. There is no corrected column to report. Tests cannot establish actual client rendering, taint safety or FPS.

Keep #97 draft. Do not merge or issue this build as a fixed test ZIP. Revisit the boundary with the reviewed source or an explicitly agreed scoped integration point.

## Authoritative reviewed-version lookup and measurements

The paginated official history URLs returned HTTP 403 from Actions. The accessible official frontend API and CFWidget numeric-project metadata did not identify a 1.1.1 file. This is a retrieval limitation, not evidence that the old archive no longer exists. There is no verified 1.1.1 TOC/source to substitute. The separate 1.3.0 archive's TOCs are checked explicitly and are not treated as a silent replacement.

Reference run: https://github.com/oopsie-glitch/EUI-AddonSkins/actions/runs/45439449480 (five fresh Lua 5.4 states per treatment on Ubuntu 24.04; all timings are fixture CPU, not WoW).

| Forever workload | Original main runtime | Previous #97 | Current #97 (runtime unchanged) |
| --- | ---: | ---: | ---: |
| 1,000 ordinary reopens | 23.718 ms | 22.959 ms | 22.490 ms |
| 1,000 closed-window theme changes | 6.730 ms | 6.685 ms | 6.653 ms |
| Retained after those changes | 203.688 KiB | 0.438 KiB | 0.438 KiB |
| Another 1,000 changes: additional retained | 203.938 KiB | 0.438 KiB | 0.438 KiB |
| 1,000 redraws after 2,000 changes | 539.651 ms | 22.959 ms | 22.614 ms |

No additional UI object, hook or event counts are introduced. Existing prototype inventory remains five frame creations, 17 textures including native fixture textures, 17 hooks and one listener in the Forever scenario; Classic has its separate native-art path. Warm loops allocate no UI objects/hooks. These are modeled counts, not real WoW backend resources. Explicit theme events still repaint owned artwork and fonts; no idle polling was added.

Current PR packaging/regressions and an isolated overlay onto exact main 82eb4fd pass, including ItemTree and all 47 catalog entries. The diagnostic's ownership matrix deliberately records the unresolved failure. A green workflow does not turn that failure into a runtime pass. No install ZIP is offered as a corrected build.
