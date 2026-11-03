-- Real Camelot manifest/Core/Loader/adapter activation with both addon API shapes.
-- This models API availability, not the Forever executable or its secure runtime.
for _, legacy in ipairs({false, true}) do
    local ns, callbacks, frames, errors = {}, {}, {}, {}
    local loaded, disabled, combat, skinEnabled = {}, false, false, true
    EUIAddonSkinsDB = {}; SlashCmdList = {}; OneForAll = nil
    EllesmereUI = nil; GetFileIDFromPath = nil; C_Item = nil
    for _,suffix in ipairs({'Frame','Confirm','BugReport','Discord','CraftList','ProfilePopup','QuestChain','WeightEditor','TrainerSpells','TalentCode','Welcome','WhatsNew','PreviewFrame','QuestSharePopup','CopyChat','BagsFull','NearbyAlert'}) do _G['OneForAll'..suffix]=nil end
    UIParent = {}; DEFAULT_CHAT_FRAME = {AddMessage=function() end}
    UnitName=function() return 'ForeverTester' end
    UnitGUID=function() return 'Player-ForeverTester' end
    InCombatLockdown=function() return combat end
    geterrorhandler=function() return function(e) errors[#errors+1]=e end end
    C_Timer={After=function() error('empty activation must not queue work') end}
    CreateFrame=function()
        local f={RegisterEvent=function() end}
        function f:SetScript(k, fn) self[k]=fn end
        frames[#frames+1]=f; return f
    end
    local function info(name) if name=='OneForAll' then return name end end
    local function isLoaded(name) return loaded[name] end
    local function modernState(name, guid)
        assert(name=='OneForAll' and guid=='Player-ForeverTester')
        return disabled and 0 or 2
    end
    local function noLoad() error('must not force-load target') end
    C_AddOns={GetAddOnInfo=info,GetAddOnEnableState=modernState,IsAddOnLoaded=isLoaded,LoadAddOn=noLoad}
    GetAddOnInfo,GetAddOnEnableState,IsAddOnLoaded,LoadAddOn=nil,nil,nil,nil
    if legacy then
        C_AddOns=nil; GetAddOnInfo=info; IsAddOnLoaded=isLoaded; LoadAddOn=noLoad
        GetAddOnEnableState=function(character,name)
            assert(character=='ForeverTester' and name=='OneForAll'); return disabled and 0 or 2
        end
    end
    local function event(name)
        local budget=#frames
        for i=1,budget do if frames[i].OnEvent then frames[i].OnEvent(frames[i],name) end end
    end
    local chain={'Core.lua','Widgets.lua','Loader.lua','Skins\\OneForAll.lua'}
    local cursor=1
    for line in io.lines('EUIAddonSkins/EUIAddonSkins_Camelot.toc') do
        if line==chain[cursor] then
            assert(loadfile('EUIAddonSkins/'..line:gsub('\\','/')))('EUIAddonSkins',ns)
            cursor=cursor+1
        end
    end
    assert(cursor==5,'Camelot manifest lost the skin or its required load order')
    local entry=assert(ns.skinCatalogByID.OneForAll)
    assert(entry.defined and not entry.loaded and #ns.modules==0)
    EllesmereUI={RegisterSkin=function(name,fn)
        assert(name=='EUI AddonSkins - OneForAll' and not callbacks[name])
        callbacks[name]=fn
        fn({IsEnabled=function() return skinEnabled end})
    end}
    skinEnabled=false; loaded.EUIAddonSkins=true; event('PLAYER_LOGIN')
    loaded.OneForAll=true; event('ADDON_LOADED'); assert(not entry.loaded)
    skinEnabled=true; combat=true; event('ADDON_LOADED'); assert(not entry.loaded)
    combat=false; event('PLAYER_REGEN_ENABLED')
    assert(entry.loaded and #ns.modules==1 and not ns.modules[1].active,'namespace readiness must gate install')
    -- OptionalDeps/load ordering can leave the target namespace arriving later.
    OneForAll={UI={panels={},ASSET_ROOT='Interface\\AddOns\\OneForAll\\Assets\\'}}
    event('ADDON_LOADED')
    assert(ns.modules[1].active and #errors==0,table.concat(errors,'; '))
    local count=#frames
    for i=1,50 do event('PLAYER_REGEN_ENABLED') end
    assert(#frames==count and #ns.modules==1,'warm recovery duplicated activation')
    -- Character disable is evaluated with the correct modern/legacy argument order.
    disabled=true
    UnitGUID=function() return 'Player-DisabledForever' end
    if legacy then
        UnitName=function() return 'DisabledForever' end
        GetAddOnEnableState=function(character,name)
            assert(character=='DisabledForever' and name=='OneForAll'); return 0
        end
    else
        C_AddOns.GetAddOnEnableState=function(name,guid)
            assert(name=='OneForAll' and guid=='Player-DisabledForever'); return 0
        end
    end
    assert(not ns.TargetEnabled(entry))
end
C_AddOns,GetAddOnInfo,GetAddOnEnableState,IsAddOnLoaded,LoadAddOn=nil,nil,nil,nil,nil
OneForAll=nil
print('PASS: OneForAll actual Camelot TOC, modern/legacy APIs, late EUI/namespace, disabled toggle/character, combat deferral, one activation, no force loading or idle allocations')
