-- Real loader/Core and definition, independent target folders, shared singleton.
for _, variant in ipairs({'AtlasLootContinued','AtlasLootClassic'}) do
    for _, legacy in ipairs({false,true}) do
        local ns, callbacks, handlers, scopes, errors = {}, {}, {}, {}, {}
        local loaded, combat, disabled, toggle = {}, false, false, true
        AtlasLoot=nil; EllesmereUI=nil; EUIAddonSkinsDB={}; SlashCmdList={}
        DEFAULT_CHAT_FRAME={AddMessage=function()end}
        C_Timer={After=function()error('loader must not poll')end}
        UnitName=function()return 'VariantTester'end; UnitGUID=function()return 'Player-Variant'end
        InCombatLockdown=function()return combat end
        geterrorhandler=function()return function(e)errors[#errors+1]=e end end
        CreateFrame=function()return {RegisterEvent=function()end,SetScript=function(_,_,fn)handlers[#handlers+1]=fn end}end
        local function info(name)if name==variant then return name end end
        local function state(name,guid)assert(name==variant and guid=='Player-Variant');return disabled and 0 or 2 end
        local function isLoaded(name)return loaded[name]end
        C_AddOns={GetAddOnInfo=info,GetAddOnEnableState=state,IsAddOnLoaded=isLoaded,
            LoadAddOn=function()error('force loading')end}
        GetAddOnInfo,GetAddOnEnableState,IsAddOnLoaded=nil,nil,nil
        if legacy then
            C_AddOns=nil; GetAddOnInfo=info; IsAddOnLoaded=isLoaded
            GetAddOnEnableState=function(character,name)assert(character=='VariantTester' and name==variant);return disabled and 0 or 2 end
        end
        local function event(e)for _,fn in ipairs(handlers)do fn(nil,e)end end
        assert(loadfile('EUIAddonSkins/Core.lua'))('EUIAddonSkins',ns)
        assert(loadfile('EUIAddonSkins/Loader.lua'))('EUIAddonSkins',ns)
        -- Capture configuration only: full cosmetics/native actions run in legacy_controls_spec.
        ns.RegisterScopedSkin=function(id,label,config)
            scopes[#scopes+1]=config
            ns.RegisterModule(id,label,config.available,function()end)
        end
        assert(loadfile('EUIAddonSkins/Skins/AtlasLootContinued.lua'))('EUIAddonSkins',ns)
        local entry=ns.skinCatalogByID.AtlasLootContinued
        assert(not entry.loaded and #ns.modules==0)
        EllesmereUI={RegisterSkin=function(name,fn)
            assert(name=='EUI AddonSkins - AtlasLootClassic Continued' and not callbacks[name])
            callbacks[name]=fn;fn({IsEnabled=function()return toggle end})
        end}
        loaded.EUIAddonSkins=true; toggle=false; event('PLAYER_LOGIN')
        loaded[variant]=true;event('ADDON_LOADED');assert(not entry.loaded)
        toggle=true;combat=true;event('ADDON_LOADED');assert(not entry.loaded)
        combat=false;event('PLAYER_REGEN_ENABLED')
        assert(entry.loaded and #scopes==1 and not ns.modules[1].active)
        AtlasLoot={GUI={}};event('ADDON_LOADED')
        assert(ns.modules[1].active and #errors==0,table.concat(errors,';'))
        for i=1,30 do event('ADDON_LOADED')end
        assert(#scopes==1 and #ns.modules==1,'duplicate variant registration')
        -- A fresh character invalidates cached enable state and must remain disabled.
        disabled=true;UnitGUID=function()return 'Player-Other'end;UnitName=function()return 'Other'end
        if legacy then GetAddOnEnableState=function(character,name)assert(character=='Other' and name==variant);return 0 end
        else C_AddOns.GetAddOnEnableState=function(name,guid)assert(name==variant and guid=='Player-Other');return 0 end end
        assert(not ns.TargetEnabled(entry))
    end
end
C_AddOns,GetAddOnInfo,GetAddOnEnableState,IsAddOnLoaded=nil,nil,nil,nil
AtlasLoot=nil
print('PASS: both AtlasLoot folder identities; stable single toggle/factory, late API/namespace, modern/legacy enable state, disabled/combat gating, no force load')
