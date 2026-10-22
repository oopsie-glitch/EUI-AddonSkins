# BugSack alpha

> Historical development snapshot. Versions, branch status and validation counts describe that snapshot; use [the engineering guide](../../ENGINEERING.md) and [release procedure](../../RELEASING.md) for current work.

Version: `1.2.1-alpha.2`, untagged `bugsack-alpha`, based on stable `b8e0125`. PallyPower development stays on its separate branch.

- Use the existing EUI skin, public portrait/button/tab primitives and soft styling.
- Replace the protruding native portrait with a contained square icon.
- Leave the session caption free of a button plate; retain its drag, tooltip and double-click search actions.
- Preserve translated Previous/Next labels and native navigation/shift-click actions; remove replacement glyphs and native button art.
- Compact navigation controls and move the four tabs inside the footer.
- Update enabled/disabled label contrast locally, without full scans per state change.

Validation: `python3 scripts/package.py` checks Lua syntax, runs the existing regression suite, and inspects the install archive. Expanded BugSack fixtures cover the contained portrait, header actions, footer geometry, tab selection, native artwork removal, disabled text, dynamic controls and reuse. No in-game verification is claimed. BugSack and its assets/source are not bundled. No release tag, GitHub Release or CurseForge/Wago publication is created.
