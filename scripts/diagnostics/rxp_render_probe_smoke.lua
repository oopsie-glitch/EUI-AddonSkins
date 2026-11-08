-- Injected into collection_spec for the diagnostic package check only.
assert(SlashCmdList.EUIRXPRENDER)
assert(not EUIAddonSkinsDB or not EUIAddonSkinsDB.rxpRenderDiagnostic)
SlashCmdList.EUIRXPRENDER("start mock")
local trace = EUIAddonSkinsDB.rxpRenderDiagnostic[1]
assert(trace[1]:find("PR75%-render%-trace%-1"))
assert(table.concat(trace, "\n"):find("V1.root.EUIAS.composition", 1, true))
local before = #trace
legacyArt:SetAlpha(0.45)
assert(#trace == before + 1 and trace[#trace]:find("WRITE", 1, true))
modules.RXPGuides.refresh(); flush()
local output = table.concat(trace, "\n")
assert(output:find("EUIAS.Apply.before", 1, true) and output:find("EUIAS.Apply.after", 1, true))
SlashCmdList.EUIRXPRENDER("stop")
before = #trace
legacyArt:SetAlpha(1)
assert(#trace == before and trace == EUIAddonSkinsDB.rxpRenderDiagnostic[1])
SlashCmdList.EUIRXPRENDER("clear")
assert(not EUIAddonSkinsDB.rxpRenderDiagnostic)
print("PASS: RestedXP diagnostic is opt-in, records scoped writes and refreshes, and stops and clears")
