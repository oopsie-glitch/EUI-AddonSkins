-- The real core TOC must not execute any implementation for absent targets.
local ns, entries, events = {}, {}, {}
EUIAddonSkinsDB = nil
C_AddOns = {GetAddOnInfo = function() return nil end, IsAddOnLoaded = function() return false end}
UnitName = function() return 'Test' end
SlashCmdList = {}; DEFAULT_CHAT_FRAME = {AddMessage = function() end}
CreateFrame = function()
    local f = {RegisterEvent = function() end}; function f:SetScript(_, fn) events[#events + 1] = fn end; return f
end
EllesmereUI = {RegisterSkin = function(name) assert(not entries[name]); entries[name] = true end}
for line in io.lines('EUIAddonSkins/EUIAddonSkins.toc') do
    if line:match('%.lua$') then assert(not line:match('Skin.lua$')); assert(loadfile('EUIAddonSkins/' .. line))('EUIAddonSkins', ns) end
end
assert(#ns.modules == 0 and next(entries) == nil and #ns.skinCatalog == 20)
print('PASS: actual core TOC executes zero skins and registers zero irrelevant toggles with all targets absent')
