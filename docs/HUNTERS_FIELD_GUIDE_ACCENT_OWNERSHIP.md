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

A complete correction requires verified role ownership across both fixed fields and recycled text. Fixed source-owned fields do exist (see the follow-up below), but the inspected source exposes neither a current-role marker for its pooled text nor a supported style-application callback carrying both the FontString and role. Weak-key tracking alone cannot reconstruct that missing role. Do not patch the upstream addon or globally intercept font operations to manufacture that signal.

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


## Follow-up: source structures instead of RGB admission

The follow-up rechecked main at `82eb4fd5dc22a4bc973b9c47739d40a912f57c26` and PR #97 at `abd47d80b4f7201cb299fe0bf84afd9848406607`. Production Lua is unchanged in this follow-up. This is not a new corrected runtime or a release recommendation.

### What the actual 1.3.0 source establishes

| Source boundary | Verified ownership information | Limit |
| --- | --- | --- |
| UI.lua CreateAbilityInfo, lines 2017–2039 | `FieldGuideFrame.abInfo.desc` is constructed with the accent role (line 2030). | A fixed slot, not a certificate for arbitrary similarly colored text. |
| UI.lua CreatePetView, lines 3115–3347 | `FieldGuideFrame.petView.tamed.text` uses the accent role (line 3173). | Other pet/status fields have different roles and semantic colors. |
| UI.lua CreateModeChoice, lines 4312–4548 | Choice-row names use accent (lines 4363 and 4452); named Immersive/Reveal rows are retained. | Do not classify every child named `name` as accent. |
| UI.lua WriteLines, line 974; WriteSide, line 1036 | The current input record supplies `l.style` to the private Style function. A pooled FontString can change role between draws. | The role is not retained on the FontString; neither private writer is exported as a role-bearing callback. |
| UI.lua Style, lines 64–71; SKINS.forever.Styles | Native Style sets the chosen FontObject and explicit RGB. Body/accent/good/bad share the body FontObject. | Color and ordinary FontObject identity alone cannot distinguish the role after a private write. |
| Existing RefreshUI / PetTabRefresh post-hooks | Completed page redraw is observable. | Those callbacks do not supply the private line list or each FontString's current style role. |

These findings correct the earlier overly broad implication that no useful source-owned structures exist. Some are usable; coverage of the whole text lifecycle remains unproven. A full initial-field catalog for reviewed 1.1.1 is also unavailable: that exact authoritative archive is still not retrievable, and 1.3.0 is not silently substituted for it.

### Independent alternative tests

`scripts/check_hfg_source_roles.py` checks the pinned 1.3.0 constructors and extracts/executes the exact native Style function in an isolated Lua state. It does not execute the addon, patch its upvalues or modify upstream files.

The source-field experiment certifies only the two exact static slots above. It passes 2,000 alternating theme updates, late replacement of a certified slot, an identical-RGB body/semantic control, explicit native recoloring, combat deferral and weak-reference collection. It also deliberately demonstrates why this is not a complete fix: a late pooled accent line has no certificate, and assigning accent ownership to every pool position would recolor native good/body text.

A second experiment supplies a separate accent FontObject through the native style table. The actual native Style function then gives future text a distinguishable identity without RGB-based admission. Existing text remains bound to the old shared FontObject. This is a viable direction to investigate, not proof of a complete integration: initial text, all supported constructor versions, role reuse, explicit semantic recoloring, original font inheritance and live client behavior still need validation. No role-font wrapper, FontObject or per-FontString observer was added to production code.

The diagnostic's PASS means that these limited successes and expected blockers were reproduced. The existing ownership matrix still fails for the production runtime.

### Safest next steps

1. Keep #97 draft and do not ship its bounded implementation as an ownership-safe correction.
2. Prefer a supported upstream current-role registry/enumeration plus style-change notification, covering existing text and pool reuse. This would permit bounded weak-key ownership without guessing colors. No such API is currently verified; this is a proposed upstream contract, not an API callers can use today.
3. An addon-local role-FontObject adapter may be possible after exact supported-version source and first-construction/load-order coverage are established. It must not manufacture retroactive ownership or globally intercept font operations. Do not implement it speculatively.
4. If a temporary loss of live book-text accent synchronization is acceptable, a separately approved fixed text accent could avoid historical accent mappings while preserving semantic colors from theme-driven recoloring. That changes approved theme behavior and is not implemented or assumed authorized here.

### Validation limits and additional combat finding

The complete regression/package suite, existing Forever/Classic fixtures, 2,000-change retention test, original/previous/current ownership diagnostic and five-trial benchmark are rerun. An isolated overlay on current main also validates coexistence with ItemTree. These are hosted Lua/source checks, not in-game rendering, memory, FPS or taint validation.

The unchanged production `PageDrawn` callback does not check `Locked()` before `Visit`; `ToastShown` similarly calls `LightText` directly. The existing benchmark measures 8 writes during a combat redraw versus 5 in the native fixture (3 additional skin writes). This is evidence of an existing cosmetic-deferral gap, not proof of a blocked action or live taint. It must be covered by direct callback tests and corrected before a future runtime solution is accepted. No speculative runtime change is mixed into this ownership investigation.
