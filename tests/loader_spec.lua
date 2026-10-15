local ns, entries, handlers, installed, loaded, disabled = {}, {}, {}, {}, {}, {}
local combat, attempts, errors = false, {}, {}
EUIAddonSkinsDB = {}; SlashCmdList = {}; DEFAULT_CHAT_FRAME = {AddMessage = function() end}
UnitName = function() return 'Tester' end
UnitGUID = function() return 'Player-Tester' end
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
CreateFrame = function()
    local f = {RegisterEvent = function() end}; function f:SetScript(_, fn) handlers[#handlers + 1] = fn end; return f
end
local function event(e, addon) for _, fn in ipairs(handlers) do fn(nil, e, addon) end end
C_AddOns = {
    GetAddOnInfo = function(name) if installed[name] then return name end end,
    GetAddOnEnableState = function(name, character)
        if character == 'Tester' then return 2 end
        assert(character == 'Player-Tester'); return disabled[name] and 0 or 2
    end,
    IsAddOnLoaded = function(name) return loaded[name] end,
    LoadAddOn = function() error('single-folder loader must never request an addon load') end,
}
installed.BugSack, loaded.BugSack = true, true
installed.Questie = true
installed.Spy, disabled.Spy = true, true
installed.GTFO, loaded.GTFO = true, true
installed.Details, loaded.Details = true, true
local euiAPI = {RegisterSkin = function(name, fn)
    assert(not entries[name]); entries[name] = fn
    fn({IsEnabled = function() return name ~= 'EUI AddonSkins - Details!' end})
end}
EllesmereUI = nil
assert(loadfile('EUIAddonSkins/Core.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/Loader.lua'))('EUIAddonSkins', ns)
for _, entry in ipairs(ns.skinCatalog) do
    ns.RegisterSkinDefinition(entry.id, function()
        attempts[entry.id] = (attempts[entry.id] or 0) + 1
        if entry.id == 'GTFO' then error('fixture activation failure') end
        ns.RegisterModule(entry.id, entry.label, function() return true end, function() end)
    end)
end
assert(next(attempts) == nil)
EllesmereUI = euiAPI; event('PLAYER_LOGIN'); assert(next(attempts) == nil, 'activated before core finished loading')
loaded.EUIAddonSkins = true; event('ADDON_LOADED','EUIAddonSkins')
assert(attempts.BugSack == 1 and not attempts.Questie and not attempts.Spy and not attempts.Details)
assert(entries['EUI AddonSkins - Questie'] and not entries['EUI AddonSkins - Spy'] and not entries['EUI AddonSkins - Auctionator'])
assert(attempts.GTFO == 1 and #errors == 1)
combat = true; loaded.Questie = true; event('ADDON_LOADED','Questie'); assert(not attempts.Questie)
combat = false; EUIAddonSkinsDB.disabled = true; event('PLAYER_REGEN_ENABLED'); assert(not attempts.Questie)
EUIAddonSkinsDB.disabled = nil; event('PLAYER_REGEN_ENABLED'); assert(attempts.Questie == 1)
for _ = 1,25 do event('ADDON_LOADED','Unrelated') end
assert(attempts.BugSack == 1 and attempts.Questie == 1 and attempts.GTFO == 1)
entries['EUI AddonSkins - Details!']({IsEnabled = function() return true end}); assert(attempts.Details == 1)
assert(not ns.skinCatalogByID.BugSack.factory and ns.skinCatalogByID.Spy.factory, 'factory lifecycle incorrect')
local report=ns.LoaderDiagnostics(); assert(report:find('single addon folder',1,true) and report:find('skin activated',1,true))
-- Replay the reported account/name mismatch and respect the player GUID.
local account={Altoholic=1,KiwiFarm=1,Myslot=1,Questie=1,RXPGuides=1,Spy=1,ThreatClassic2=1}
local modern=C_AddOns; local state=modern.GetAddOnEnableState
UnitGUID=function() return 'Player-Reported' end
modern.GetAddOnInfo=function(name) return name end
modern.GetAddOnEnableState=function(name,character)
    if character==nil then return account[name] or 0 end
    if character=='Tester' then return 2 end
    assert(character=='Player-Reported')
    return (name=='BugSack' or name=='Details' or name=='ForeverDungeonJournal') and 2 or 0
end
for _,entry in ipairs(ns.skinCatalog) do
    assert(ns.TargetEnabled(entry)==(entry.id=='BugSack' or entry.id=='Details' or entry.id=='ForeverDungeonJournal'))
end
modern.GetAddOnEnableState=state
C_AddOns=nil; GetAddOnInfo=modern.GetAddOnInfo
GetAddOnEnableState=function(character,name) assert(character=='TesterLegacy'); return disabled[name] and 0 or 2 end
UnitName=function() return 'TesterLegacy' end
assert(ns.TargetEnabled(ns.skinCatalogByID.BugSack) and not ns.TargetEnabled(ns.skinCatalogByID.Spy))
C_AddOns=modern; GetAddOnInfo,GetAddOnEnableState=nil,nil; UnitName,UnitGUID=nil,nil
print('PASS: single-folder factories, GUID filtering, deferred/disabled targets, late EUI, combat, preserved toggles, failure isolation, reuse and no addon-loading calls')
