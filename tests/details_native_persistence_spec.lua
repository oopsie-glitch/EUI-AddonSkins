-- Run real native save, startup, profile and late-provider recovery code.
-- Only engine UI/services are stubs; configuration copying/resetting is upstream.
local source=os.getenv("DETAILS_NATIVE_SOURCE")
if not source then print("SKIP: native persistence source fixture (pinned-source CI)"); return end
local function read(name)
    local f=assert(io.open(source.."/"..name));local s=f:read("*a");f:close();return (s:gsub("\r",""))
end
local function copy(v) if type(v)~="table" then return v end local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
local function encode(v)
    if type(v)=="table" then local t={"{"};for k,x in pairs(v)do t[#t+1]="["..encode(k).."]="..encode(x).."," end;t[#t+1]="}";return table.concat(t)
    elseif type(v)=="string" then return string.format("%q",v)
    elseif type(v)=="number" or type(v)=="boolean" then return tostring(v) end
    error("non-SavedVariables value: "..type(v))
end
local function equal(a,b) return encode(a)==encode(b) end
-- Table order is irrelevant across reconstructed Lua states.
local function same(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~="table"then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local keys={"Details","DetailsFramework","_detalhes_database","_detalhes_global","InCombatLockdown","LibStub","UnitName","UnitClass","UnitFactionGroup","GetRealmName","GetBuildInfo","PLAYER_FACTION_GROUP","IsInGroup","IsInRaid","issecretvalue"}
local original={};for _,k in ipairs(keys)do original[k]=_G[k]end
local main,skins,include,classes,profiles,loader,parser,saver=read("window_main.lua"),read("skins.lua"),read("include_instance.lua"),read("class_instance.lua"),read("profiles.lua"),read("loaddata.lua"),read("parser.lua"),read("savedata.lua")
local counts
local function environment(saved)
    counts={resets=0,changes=0,hooks=0,save=0,recovery=0}
    local D={skins={},tabela_instancias={},unused_instances={},instances_amount=2,loaded=false,installed_skins_cache={},
        preset_version=1,default_skin_to_use="Minimalistic",profile_save_pos=false,local_instances_config={},initializing=true,
        default_profile={instances={},profile_save_pos=false,capture_real={}},capture_real={},
        switch={},Buffs={},capture_real={},gump=true,always_use_profile=false,always_use_profile_exception={}}
    Details=D
    local data=saved and assert(load("return "..saved))() or {active="A",profiles={A={instances={},profile_save_pos=false,capture_real={}},B={instances={},profile_save_pos=false,capture_real={}}}}
    D.profiles=data.profiles
    _detalhes_database={active_profile=data.active,tabela_instancias={},last_version="fixture"}
    _detalhes_global={switchSaved={slots={},table={}}}
    local combat=false
    InCombatLockdown=function()return combat end
    issecretvalue=function()return false end
    UnitName=function()return "Fixture"end;UnitClass=function()return "Warrior","WARRIOR"end
    GetRealmName=function()return "FixtureRealm"end;GetBuildInfo=function()return "fixture","",0,16001 end
    UnitFactionGroup=function()return "Alliance"end;PLAYER_FACTION_GROUP={[0]="Horde",[1]="Alliance"}
    IsInGroup=function()return false end;IsInRaid=function()return false end
    local framework={IsAddonApocalypseWow=function()return false end,table={copy=function(_,v)return copy(v)end}}
    DetailsFramework=framework
    local media={Fetch=function(_,_,name)return name or "native" end,Register=function()end}
    LibStub=setmetatable({GetLibrary=function()return media end},{__call=function()return media end})
    local nop=function()end
    local N={RowTexts={Prepare=nop,GetDefaultTexts=function()return {{font={}}}end},
        WindowSnap={ReleaseAll=nop,ImportLayout=nop,Initialize=nop,MoveGroupWith=nop},
        SaveVariables={},LoadSavedVariables={},AutoRunCode={StartAutoRun=nop},BParser={}}
    D.CopyTable=copy;D.IsLoaded=function()return D.isLoaded end
    D.GetAllInstances=function()return D.tabela_instancias end
    D.GetInstance=function(_,id)return D.tabela_instancias[id]end
    D.ListInstances=function()return ipairs(D.tabela_instancias)end
    D.GetCurrentProfileName=function()return _detalhes_database.active_profile end
    D.GetProfile=function(_,name)return D.profiles[name or _detalhes_database.active_profile]end
    D.Msg=function(_,m)error(m)end
    D.Destroy=function(_,t)for k in pairs(t)do t[k]=nil end end
    D.table={deploy=function(dst,src)for k,v in pairs(src)do if dst[k]==nil then dst[k]=copy(v)end end end}
    D.StatusBar={Reset=nop,UpdateChilds=nop,ApplyOptions=nop,SetPlugin=nop}
    for _,name in ipairs({"SetTooltipBackdrop","SelectNumericalSystem","RefreshUpdater","RefreshAnimationFunctions","LoadFramesForBroadcastTools","HandleRogueCombatSpecIconByGameVersion","NickTagSetCache","CountDataOnLoad","SetUseAnimations","ClearSpellCache","UpdateParserGears"})do D[name]=nop end
    D.Buffs.BuildTables=nop;D.Ambiguate=function(_,v)return v end
    local function method(file,name)
        local body=assert(file:match("(function Details:"..name.."%s*%b().-)\nend"),name)
        local exportHelper=name=="ExportSkin" and assert(classes:match("(local createStatusbarOptions = function.-)\nend")).."\nend\n" or ""
        assert(load("local Details,Details222,DetailsFramework=...;local safe_load=function(fn,...)fn(...);return true end;"..exportHelper..body.."\nend"))(D,N,framework)
    end
    assert(load("local _detalhes,SharedMedia,Details222=...;"..assert(include:match("(_detalhes.instance_defaults = .*)"))))(D,media,N)
    assert(load("local _detalhes=...;"..assert(include:match("(_detalhes.instance_skin_ignored_values = %b{})"))))(D)
    for _,name in ipairs({"ResetInstanceConfigKeepingValues","LoadInstanceConfig"})do
        local body=assert(include:match("(function _detalhes:"..name..".-)\nend"))
        assert(load("local _detalhes,Details,Details222=...;"..body.."\nend"))(D,D,N)
    end
    local realReset=D.ResetInstanceConfigKeepingValues
    D.ResetInstanceConfigKeepingValues=function(...)counts.resets=counts.resets+1;return realReset(...)end
    assert(load("local Details,Details222=...;"..assert(main:match("(function Details:ChangeSkin.-)\n\tlocal skin_file")).."\nend"))(D,N)
    local realChange=D.ChangeSkin
    D.ChangeSkin=function(...)counts.changes=counts.changes+1;return realChange(...)end
    method(main,"WaitForSkin")
    method(classes,"ExportSkin")
    method(classes,"ApplySavedSkin")
    local realRecovery=D.ApplySavedSkin
    D.ApplySavedSkin=function(...)counts.recovery=counts.recovery+1;return realRecovery(...)end
    method(profiles,"ApplyProfile")
    method(profiles,"SaveProfile")
    assert(load("local _detalhes=...;"..assert(skins:match("(function _detalhes:InstallSkin.-)\n\tend")).."\nend"))(D)
    local first=assert(skins:find('_detalhes:InstallSkin ("Minimalistic",',1,true))
    local last=assert(skins:find('_detalhes:InstallSkin ("Minimalistic v2",',first+1,true))
    assert(load("local _detalhes,Loc=...;"..skins:sub(first,last-1)))(D,setmetatable({},{__index=function(_,k)return k end}))
    local function instance(id)
        local i=setmetatable({meu_id=id,bgframe={},baseframe={},skin="Minimalistic",StatusBar={options={},left={real_name="NONE",options={}},center={real_name="NONE",options={}},right={real_name="NONE",options={}}},snap={},posicao={normal={w=300,h=200}}},{__index=D})
        for _,name in ipairs({"LockInstance","LoadLocalInstanceConfig","RestoreMainWindowPosition","ReajustaGump"})do i[name]=nop end
        i.GetId=function()return id end;i.IsStarted=function(self)return self.iniciada end
        i.IsEnabled=function(self)return self.ativa end
        i.ShutDown=function(self)self.ativa=false end
        i.AtivarInstancia=function(self)self.iniciada=true;self.ativa=true;self:ChangeSkin()end
        i.GetPosition=function(self)return self.posicao end
        i.GetDisplay=function()return 1,1 end;i.GetMode=function()return 2 end;i.GetSegment=function()return 0 end
        return i
    end
    D.CreateDisabledInstance=function(_,id)local i=instance(id);D.tabela_instancias[id]=i;return i end
    -- Actual native per-character save called by SaveProfile and ApplyProfile.
    assert(load("local Details,Details222=...;"..assert(saver:match("(function Details222.SaveVariables.SaveLocalInstanceConfig.-)\nend")).."\nend"))(D,N)
    local saveLocal=N.SaveVariables.SaveLocalInstanceConfig
    N.SaveVariables.SaveLocalInstanceConfig=function()counts.save=counts.save+1;return saveLocal()end
    assert(load("local Details,Details222,UnitName=...;"..assert(loader:match("(function Details222.LoadSavedVariables.LoadConfig.-)\nend")).."\nend"))(D,N,UnitName)
    assert(load("local Details,Details222=...;"..assert(loader:match("(function Details222.LoadSavedVariables.DefaultProfile.-)\nend")).."\nend"))(D,N)
    N.LoadSavedVariables.CharacterData=nop;N.LoadSavedVariables.SharedData=nop;N.LoadSavedVariables.CombatSegments=nop
    -- Execute the actual initializer called on ADDON_LOADED(Details), not a
    -- successful-API stub. Parser/data/engine services unrelated to prefs are noops.
    local turn=assert(parser:match("(local TurnTheSpeakersOn = function%(%).-)\n\tend"))
    local boot=assert(load("local Details,Details222,detailsFramework=...;"..turn.."\nend;return TurnTheSpeakersOn"))(D,N,framework)
    local context={IsEnabled=function()return true end}
    assert(loadfile("EUIAddonSkins/DetailsNative.lua"))("EUIAddonSkins",context)
    local accent={.2,.6,.4}
    local P=context.CreateNativeDetailsPrototype({H={Allowed=function()return false end,Hook=function()counts.hooks=counts.hooks+1 end},S={GetAccentColor=function()return table.unpack(accent)end,GetFont=function()return "fixture-font"end},module={}},nop)
    local function savedState()
        return encode({active=D:GetCurrentProfileName(),profiles=D.profiles})
    end
    return {D=D,P=P,boot=boot,instance=instance,save=savedState,context=context,N=N,counts=counts,combat=function(v)combat=v end,accent=accent}
end
local function customize(i,n)
    i.menu_icons_size=.6+n/10;i.menu_icons.space=3+n;i.menu_anchor={8+n,13+n,side=n%2+1}
    i.attribute_text.anchor={4+n,9+n};i.attribute_text.text_face="UserFont"..n;i.attribute_text.text_size=15+n
    i.attribute_text.show_timer=n%2==1;i.attribute_text.text_color={.1*n,.2,.8,1}
    i.row_info.height=24+n;i.row_info.space.between=5+n;i.row_info.texture="UserTexture"..n
    i.row_info.font_face="UserBarFont"..n;i.row_info.font_size=12+n
    i.row_info.texture_background_class_color=n%2==1;i.bg_alpha=.2+n/10;i.bg_r=.12;i.bg_g=.13;i.bg_b=.14
end
local fields={"menu_icons_size","menu_icons","menu_anchor","attribute_text","row_info","bg_alpha","bg_r","bg_g","bg_b","skin"}
local function prefs(i)local t={};for _,k in ipairs(fields)do t[k]=copy(i[k])end;return t end
local initial=environment()
initial.D.isLoaded=true;initial.P.Register()
assert(initial.D.skins["Addonskins EUI"],"definition missing")
for id=1,2 do
    local i=initial.instance(id);initial.D.tabela_instancias[id]=i
    -- Native defaults enter only on this explicit first selection.
    i:LoadInstanceConfig();i:ChangeSkin("Addonskins EUI")
    assert(i.attribute_text.show_timer==false and i.row_info.height==18)
    i.ativa=true;customize(i,id)
end
initial.D:SaveProfile("A")
-- A second independent native profile, with independently customized windows.
initial.D.profiles.B=copy(initial.D.profiles.A)
for id,s in ipairs(initial.D.profiles.B.instances)do customize(s,id+2)end
local saved=initial.save()
local expectedA,expectedB={},{}
for id,s in ipairs(initial.D.profiles.A.instances)do expectedA[id]=prefs(s)end
for id,s in ipairs(initial.D.profiles.B.instances)do expectedB[id]=prefs(s)end
if os.getenv("DETAILS_PERSIST_BENCH") then
    local bootTimes,registerTimes,warmTimes={}, {}, {}
    local lost,resets,recoveries,delta
    for trial=1,5 do
        local e=environment(saved)
        local start=os.clock();e.boot();bootTimes[trial]=(os.clock()-start)*1000
        local before=e.counts.resets
        start=os.clock();e.P.Register();registerTimes[trial]=(os.clock()-start)*1000
        resets=e.counts.resets-before;recoveries=e.counts.recovery
        lost=not same(prefs(e.D:GetInstance(1)),expectedA[1])
        collectgarbage("collect");local heap=collectgarbage("count")
        local changes,hooks=e.counts.changes,e.counts.hooks
        start=os.clock();for _=1,1000 do e.P.Register()end;warmTimes[trial]=(os.clock()-start)*1000
        collectgarbage("collect");delta=collectgarbage("count")-heap
        assert(e.counts.changes==changes and e.counts.hooks==hooks,"warm registration performed native skin resets or added hooks")
    end
    table.sort(bootTimes);table.sort(registerTimes);table.sort(warmTimes)
    print(("PERSIST_BENCH trials=5 windows=2 native_cold_load_ms=%.3f provider_registration_ms=%.3f warm_1000_ms=%.3f native_recovery_calls=%d registration_resets=%d lost_preferences=%s warm_retained_KiB=%.3f extra_hooks=0"):format(bootTimes[3],registerTimes[3],warmTimes[3],recoveries,resets,tostring(lost),delta))
    for _,k in ipairs(keys)do _G[k]=original[k]end
    return
end
local reload=environment(saved)
reload.boot()
assert(reload.D.IsLoaded(),"actual native initializer did not complete")
local afterFallback=prefs(reload.D:GetInstance(1))
assert(not same(afterFallback,expectedA[1]),"fixture did not execute the unavailable-provider default reset")
assert(reload.D.waitingForSkins[1]=="Addonskins EUI" and reload.D.waitingForSkins[2]=="Addonskins EUI")
assert(same(prefs(reload.D.profiles.A.instances[1]),expectedA[1]),"upstream fallback already destroyed the saved profile")
reload.P.Register()
for id,wanted in ipairs(expectedA)do
    assert(same(prefs(reload.D:GetInstance(id)),wanted),"REPRO: reload registration lost native customization for window "..id)
end
assert(next(reload.D.waitingForSkins)==nil,"prototype waiting entries were not consumed")
local recovery=reload.counts.recovery
local resets=reload.counts.resets
for _=1,1000 do reload.P.Register() end
assert(reload.counts.recovery==recovery and reload.counts.resets==resets,"warm registration reapplied saved or default prefs")
-- Real profile switching saves the outgoing customization and loads the target.
reload.D:ApplyProfile("B")
for id,wanted in ipairs(expectedB)do assert(same(prefs(reload.D:GetInstance(id)),wanted),"native B profile overwritten")end
reload.D:ApplyProfile("A")
for id,wanted in ipairs(expectedA)do assert(same(prefs(reload.D:GetInstance(id)),wanted),"native A profile overwritten")end
reload.accent[1]=.9;reload.P.Refresh()
for id,wanted in ipairs(expectedA)do assert(same(prefs(reload.D:GetInstance(id)),wanted),"accent/refresh rewrote native preferences")end
-- Save again, reconstruct plain SavedVariables, and initialize a completely new
-- addon/Details environment. This is not an in-memory same-skin refresh.
reload.D:SaveProfile()
local second=environment(reload.save())
second.boot();second.combat(true);second.P.Register()
assert(not second.D.skins["Addonskins EUI"],"registered/recovered during combat")
second.combat(false);second.P.Register()
for id,wanted in ipairs(expectedA)do assert(same(prefs(second.D:GetInstance(id)),wanted),"second reload lost customization")end
assert(same(second.D.profiles.B,initial.D.profiles.B),"inactive profile was changed")
print("PASS: actual native ExportSkin/SaveProfile -> serialized reload -> parser initializer/LoadConfig/ApplyProfile/WaitForSkin -> registration preserves two windows, profiles, timer/fonts/bars/background/title/toolbar")
-- Stale ownership must not select the prototype over a different current skin.
second.D.waitingForSkins={[1]="Addonskins EUI",[9]="Foreign"}
second.D:GetInstance(1):ChangeSkin("Minimalistic")
local thirdNS={IsEnabled=function()return true end}
assert(loadfile("EUIAddonSkins/DetailsNative.lua"))("EUIAddonSkins",thirdNS)
second.D.skins["Addonskins EUI"]=nil
local third=thirdNS.CreateNativeDetailsPrototype({H={Allowed=function()return false end,Hook=function()end},S={GetAccentColor=function()return .2,.6,.4 end,GetFont=function()return "fixture-font"end},module={}},function()end)
third.Register()
assert(second.D:GetInstance(1).skin=="Minimalistic" and second.D.waitingForSkins[9]=="Foreign","stale wait selected prototype or changed a foreign wait")
assert(not second.D.waitingForSkins[1],"stale prototype wait retained")
print("PASS: stale waiting ownership cannot select prototype; foreign waiting entries are untouched")
for _,k in ipairs(keys)do _G[k]=original[k]end
