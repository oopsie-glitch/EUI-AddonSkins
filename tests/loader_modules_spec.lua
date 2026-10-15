-- Execute the real module files using WoW's separate addon namespaces.
local ns, entries, reads, errors = {}, {}, {}, {}
EUIAddonSkinsDB = {}; SlashCmdList = {}; DEFAULT_CHAT_FRAME = {AddMessage = function() end}
UnitName = function() return 'ModuleFixture' end
UnitGUID = function() return 'Player-ModuleFixture' end
C_Timer = {After = function() end}
InCombatLockdown = function() return false end
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
CreateFrame = function() return {RegisterEvent = function() end, SetScript = function() end} end
C_AddOns = {
    GetAddOnInfo = function(name) return name end,
    GetAddOnEnableState = function() return 2 end,
    IsAddOnLoaded = function() return true end,
    LoadAddOn = function(name)
        reads[name] = (reads[name] or 0) + 1
        assert(loadfile(name .. '/Skin.lua'))(name, {})
        return true
    end,
}
EllesmereUI = {RegisterSkin = function(name, fn)
    assert(not entries[name]); entries[name] = true
    fn({IsEnabled = function() return true end})
end}
for line in io.lines('EUIAddonSkins/EUIAddonSkins.toc') do
    if line:match('%.lua$') then assert(loadfile('EUIAddonSkins/' .. line))('EUIAddonSkins', ns) end
end
assert(#ns.modules == 20 and #errors == 0, tostring(#ns.modules) .. " modules: " .. table.concat(errors, "; "))
for _, entry in ipairs(ns.skinCatalog) do
    assert(reads[entry.addon] == 1 and entries['EUI AddonSkins - ' .. entry.label])
    local found
    for _, module in ipairs(ns.modules) do if module.id == entry.id then found = module end end
    assert(found and found.skin == entry.skin and found.registered)
end
UnitName = nil
print('PASS: all twenty actual skin files load once through separate addon namespaces and inherit the existing EUI toggle facade')
