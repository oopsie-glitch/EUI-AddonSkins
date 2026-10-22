# DBM font restoration hardening

Branch: `skin/dbm-font-restoration`, based on stable 1.5.2. Untagged; no publication.

The CraftSim crash reports exposed a native stack-overflow trigger when restoring a borrowed FontObject. No equivalent DBM crash is established, but the DBM skin used related capture/restore operations for timer labels and range/radar/info text.

DBM no longer captures or reassigns FontObjects. Timer restoration uses the existing concrete font path, size, flags, text colour, shadow colour/offset and layout snapshots. Auxiliary text now also snapshots/restores shadow properties. Native font-change notifications remain supported; styling never writes a captured inheritance object back to a region. Auxiliary font callbacks stop repainting once their style is deactivated, so they cannot overwrite restored native metrics. Profile values, timer data, positions, actions and geometry remain native.

Regression fixtures reject GetFontObject capture and direct font-object assignments from the DBM adapter. Existing native font-change tests still run. New checks preserve current object identity while restoring the original visible font, verify native auxiliary shadows and exercise 50 complete disable/re-enable cycles with no extra UI objects/hooks. The full syntax/regression suite and one-folder 39-file ZIP validation pass. Actual client crashes and prevention are not reproduced or verified outside WoW.

This is an integration-local preventive fix. No shared helper or release metadata changed.
