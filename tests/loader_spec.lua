local ns, entries, handlers, installed, loaded, disabled = {}, {}, {}, {}, {}, {}
local combat, attempts, executed, errors = false, {}, {}, {}
EUIAddonSkinsDB = {}; SlashCmdList = {}; DEFAULT_CHAT_FRAME = {AddMessage = function() end}
UnitName = function() return 'Tester' end
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
CreateFrame = function()
    local f = {RegisterEvent = function() end}; function f:SetScript(_, fn) handlers[#handlers + 1] = fn end; return f
end
local function event(e, addon) for _, fn in ipairs(handlers) do fn(nil, e, addon) end end
C_AddOns = {
    GetAddOnInfo = function(name) if installed[name] then return name end end,
    GetAddOnEnableState = function(name, character) assert(character == 'Tester'); return disabled[name] and 0 or 2 end,
    IsAddOnLoaded = function(name) return loaded[name] end,
    LoadAddOn = function(name)
        assert(not combat); attempts[name] = (attempts[name] or 0) + 1
        local context = EUIAddonSkins.GetSkinNamespace(name); assert(context == ns)
        local id = name:match('EUIAddonSkins_(.+)')
        if id == 'GTFO' then return nil, 'DISABLED' end
        executed[id] = true
        context.RegisterModule(id, context.skinCatalogByID[id].label, function() return true end, function() end)
        loaded[name] = true; event('ADDON_LOADED', name)
        return true
    end,
}
loaded.EUIAddonSkins = true
installed.BugSack, loaded.BugSack = true, true
installed.Questie = true -- Enabled but not loaded yet.
installed.Spy, disabled.Spy = true, true
installed.GTFO, loaded.GTFO = true, true -- Broken/missing child module must be isolated.
installed.Details, loaded.Details = true, true -- EUI skin toggle is disabled.
local euiAPI = {RegisterSkin = function(name, fn)
    assert(not entries[name], 'duplicate toggle'); entries[name] = fn
    fn({IsEnabled = function() return name ~= 'EUI AddonSkins - Details!' end})
end}
EllesmereUI = nil
assert(loadfile('EUIAddonSkins/Core.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/Loader.lua'))('EUIAddonSkins', ns)
assert(next(attempts) == nil and #ns.modules == 0, 'skin loaded before the EUI API became available')
loaded.EUIAddonSkins = false; EllesmereUI = euiAPI; event('PLAYER_LOGIN')
assert(next(attempts) == nil, 'child loaded before its core dependency completed')
loaded.EUIAddonSkins = true; event('ADDON_LOADED', 'EUIAddonSkins')
assert(executed.BugSack and not executed.Questie and not executed.Spy and not executed.Details)
assert(entries['EUI AddonSkins - Questie'] and not entries['EUI AddonSkins - Spy'] and not entries['EUI AddonSkins - Auctionator'])
assert(attempts.EUIAddonSkins_GTFO == 1 and #errors == 1)
assert(not EUIAddonSkins.GetSkinNamespace('EUIAddonSkins_BugSack') and not EUIAddonSkins.GetSkinNamespace('unrelated'))
combat = true; loaded.Questie = true; event('ADDON_LOADED', 'Questie'); assert(not executed.Questie)
combat = false; event('PLAYER_REGEN_ENABLED'); assert(executed.Questie)
for _ = 1, 25 do event('ADDON_LOADED', 'Unrelated') end
assert(attempts.EUIAddonSkins_BugSack == 1 and attempts.EUIAddonSkins_Questie == 1 and attempts.EUIAddonSkins_GTFO == 1)
-- Re-enabling a saved EUI toggle loads the skin once.
entries['EUI AddonSkins - Details!']({IsEnabled = function() return true end}); assert(executed.Details)
local report = ns.LoaderDiagnostics()
assert(report:find('BugSack: true', 1, true) and report:find('Spy: nil', 1, true))
assert(report:find('modern(current)', 1, true) and report:find(ns.VERSION, 1, true))
-- Legacy API signatures: character precedes addon name.
local modern = C_AddOns
C_AddOns = nil
GetAddOnInfo = modern.GetAddOnInfo
GetAddOnEnableState = function(character, name) assert(character == 'Tester'); return disabled[name] and 0 or 2 end
IsAddOnLoaded, LoadAddOn = modern.IsAddOnLoaded, modern.LoadAddOn
UnitName = function() return 'TesterLegacy' end
GetAddOnEnableState = function(character, name) assert(character == 'TesterLegacy'); return disabled[name] and 0 or 2 end
assert(ns.TargetEnabled(ns.skinCatalogByID.BugSack) and not ns.TargetEnabled(ns.skinCatalogByID.Spy))
C_AddOns = modern; GetAddOnInfo, GetAddOnEnableState, IsAddOnLoaded, LoadAddOn = nil, nil, nil, nil
UnitName = nil
print('PASS: loader missing/disabled/late targets, saved EUI toggles, combat deferral, modern/legacy API signatures, failure isolation and one load per skin')
