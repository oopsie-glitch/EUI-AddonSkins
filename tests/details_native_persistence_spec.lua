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
    elseif type(v)=="number" then return string.format("%a",v)
    elseif type(v)=="boolean" then return tostring(v) end
    error("non-SavedVariables value: "..type(v))
end
-- Table order is irrelevant across reconstructed Lua states.
local function same(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~="table"then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local function mismatch(a,b,path)
    if same(a,b)then return "" end
    if type(a)~="table" or type(b)~="table" then return (path or "")..": actual="..tostring(a).." expected="..tostring(b) end
    for k,v in pairs(a)do if not same(v,b[k])then return mismatch(v,b[k],(path or "").."."..tostring(k))end end
    for k,v in pairs(b)do if a[k]==nil then return mismatch(nil,v,(path or "").."."..tostring(k))end end
end
local keys={"Details","DetailsFramework","_detalhes_database","_detalhes_global","InCombatLockdown","LibStub","UnitName","UnitClass","UnitFactionGroup","GetRealmName","GetBuildInfo","PLAYER_FACTION_GROUP","IsInGroup","IsInRaid","issecretvalue"}
local original={};for _,k in ipairs(keys)do original[k]=_G[k]end
local main,skins,include,classes,profiles,loader,parser,saver=read("window_main.lua"),read("skins.lua"),read("include_instance.lua"),read("class_instance.lua"),read("profiles.lua"),read("loaddata.lua"),read("parser.lua"),read("savedata.lua")
local adapter=assert(io.open("EUIAddonSkins/Skins/Details.lua"));local adapterSource=adapter:read("*a");adapter:close()
local function environment(saved)
    local counts={resets=0,changes=0,hooks=0,save=0,recovery=0}
    local D={skins={},instances={},tabela_instancias={},unused_instances={},instances_amount=2,loaded=false,installed_skins_cache={},
        preset_version=1,default_skin_to_use="Minimalistic",profile_save_pos=false,local_instances_config={},initializing=true,
        default_profile={instances={},profile_save_pos=false,capture_real={}},capture_real={},
        switch={},Buffs={},capture_real={},gump=true,always_use_profile=false,always_use_profile_exception={}}
    Details=D
    local data=saved and assert(load("return "..saved))() or {active="A",profiles={A={instances={},profile_save_pos=false,capture_real={}},B={instances={},profile_save_pos=false,capture_real={}}}}
    D.profiles=data.profiles
    _detalhes_database={active_profile=data.active,tabela_instancias={},last_version="fixture"}
    _detalhes_global={switchSaved={slots={},table={}},__profiles=D.profiles}
    local combat=false
    InCombatLockdown=function()return combat end
    issecretvalue=function()return false end
    UnitName=function()return "Fixture"end;UnitClass=function()return "Warrior","WARRIOR"end
    GetRealmName=function()return "FixtureRealm"end;GetBuildInfo=function()return "fixture","",0,16001 end
    UnitFactionGroup=function()return "Alliance"end;PLAYER_FACTION_GROUP={[0]="Horde",[1]="Alliance"}
    IsInGroup=function()return false end;IsInRaid=function()return false end
    local framework={IsAddonApocalypseWow=function()return false end,Mixin=function()end,table={copy=function(_,v)return copy(v)end}}
    framework.ParseColors=function(_,v)return table.unpack(v)end
    DetailsFramework=framework
    local media={Fetch=function(_,_,name)return name or "native" end,Register=function()end}
    LibStub=setmetatable({GetLibrary=function()return media end},{__call=function()return media end})
    local nop=function()end
    local function art()return {SetAlpha=nop,SetVertexColor=nop}end
    framework.CriaJanelaPrincipal=function()
        local f={EnableMouseWheel=nop,GetHeight=function()return 200 end,GetWidth=function()return 300 end,cabecalho={},UPFrame=art(),barra_esquerda=art(),barra_direita=art(),barra_fundo=art()}
        for _,k in ipairs({"ball_r","ball","atributo_icon","emenda","top_bg"})do f.cabecalho[k]=art()end
        return f,{}, {},{}
    end
    local N={RowTexts={Prepare=nop,GetDefaultTexts=function()return {{font={}}}end},
        WindowSnap={ReleaseAll=nop,ImportLayout=nop,Initialize=nop,MoveGroupWith=nop,RegisterInstance=nop},
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
    D.StatusBar={Reset=nop,UpdateChilds=nop,ApplyOptions=nop,SetPlugin=nop,
        CreateStatusBarChildForInstance=function(_,instance,name)return {real_name=name,options={}}end,
        SetLeftPlugin=function(_,i,p)i.StatusBar.left=p end,SetCenterPlugin=function(_,i,p)i.StatusBar.center=p end,SetRightPlugin=function(_,i,p)i.StatusBar.right=p end}
    D.ToolBar={ReorganizeIcons=nop};D.GetLowerInstanceNumber=function()return 1 end
    D.ResetTempSegment=nop;D.IsDetached=function()return false end
    D.GetApocalypseSourceType=function()return 0 end
    D.StatusBarColor=nop;D.EsconderScrollBar=nop
    N.Apocalypse={TypeDetails=1,TypeGame=2}
    for _,name in ipairs({"SetTooltipBackdrop","SelectNumericalSystem","RefreshUpdater","RefreshAnimationFunctions","LoadFramesForBroadcastTools","HandleRogueCombatSpecIconByGameVersion","SendEvent","NickTagSetCache","CountDataOnLoad","SetUseAnimations","ClearSpellCache","UpdateParserGears"})do D[name]=nop end
    D.Buffs.BuildTables=nop;D.Ambiguate=function(_,v)return v end
    local function method(file,name)
        local ending=name=="OptionPanelOnChangeSkin" and "\n            end" or "\nend"
        local body=assert(file:match("(function Details:"..name.."%s*%b().-)"..ending),name)
        local exportHelper=name=="ExportSkin" and assert(classes:match("(local createStatusbarOptions = function.-)\nend")).."\nend\n" or ""
        assert(load("local Details,Details222,DetailsFramework=...;local gump,detailsFramework=DetailsFramework,DetailsFramework;local instanceMixins={};local _math_floor=math.floor;local modo_grupo,modo_alone,modo_raid=2,1,3;local safe_load=function(fn,...)fn(...);return true end;"..exportHelper..body.."\nend"))(D,N,framework)
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
    method(main,"InstanceColor")
    method(classes,"GetId")
    method(classes,"RestauraJanela")
    local activate=assert(classes:match("(function Details:AtivarInstancia.-self:ChangeSkin%(%))"))
    assert(load("local Details,DetailsFramework,detailsFramework,Details222=...;local instanceMixins={};"..activate.."\nend"))(D,framework,framework,N)
    method(classes,"ExportSkin")
    method(classes,"ApplySavedSkin")
    local realRecovery=D.ApplySavedSkin
    D.ApplySavedSkin=function(...)counts.recovery=counts.recovery+1;return realRecovery(...)end
    method(profiles,"GetCurrentProfileName")
    method(profiles,"GetProfile")
    method(profiles,"ApplyProfile")
    method(profiles,"SaveProfile")
    assert(load("local _detalhes=...;"..assert(skins:match("(function _detalhes:InstallSkin.-)\n\tend")).."\nend"))(D)
    local first=assert(skins:find('_detalhes:InstallSkin ("Minimalistic",',1,true))
    local last=assert(skins:find('_detalhes:InstallSkin ("Minimalistic v2",',first+1,true))
    assert(load("local _detalhes,Loc=...;"..skins:sub(first,last-1)))(D,setmetatable({},{__index=function(_,k)return k end}))
    local function instance(id)
        local i=setmetatable({meu_id=id,bgframe={},baseframe={},skin="Minimalistic",StatusBar={options={},left={real_name="NONE",options={}},center={real_name="NONE",options={}},right={real_name="NONE",options={}}},snap={},mostrando="normal",posicao={normal={w=300,h=200}}},{__index=D})
        for _,name in ipairs({"LockInstance","LoadLocalInstanceConfig","RestoreMainWindowPosition","ReajustaGump"})do i[name]=nop end
        i.GetId=function()return id end;i.IsStarted=function(self)return self.iniciada end
        i.IsEnabled=function(self)return self.ativa end
        i.ShutDown=function(self)self.ativa=false end
        i.AtivarInstancia=D.AtivarInstancia
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
    -- Execute the integration's existing ChangeSkin observer, including its
    -- requested-skin argument. No extra runtime hook is introduced.
    local state={native=P,applying=false}
    local hook=assert(adapterSource:match('(H.Hook%(D, name, function%(instance.-)\n        end%)'))
    local H={Hook=function(o,name,callback)
        local original=o[name]
        o[name]=function(...)local result=table.pack(original(...));callback(...);return table.unpack(result,1,result.n)end
    end}
    assert(load("local H,D,state,refresh,name=...;"..hook.."\nend)"))(H,D,state,function()end,"ChangeSkin")
    method(read("window_options2_sections.lua"),"OptionPanelOnChangeSkin")
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
    for _,text in ipairs(i.row_info.texts or {})do if text.font then text.font.face="UserBarFont"..n;text.font.size=12+n end end
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
    if os.getenv("DETAILS_PRIOR_DEFAULTS") then
        -- Historical sensitivity/benchmark runs retain their verified defaults.
        assert(i.attribute_text.anchor[1]==1.4 and i.attribute_text.anchor[2]==4.5,"historical title baseline changed")
        assert(i.menu_icons_size==1 and i.menu_anchor[1]==13 and i.menu_anchor[2]==4 and i.menu_anchor.side==2,"historical toolbar baseline changed")
        assert(i.row_info.texture_background_class_color==true,"historical bar-background baseline changed")
    else
        assert(i.attribute_text.anchor[1]==-18 and i.attribute_text.anchor[2]==5,"new selection did not apply title defaults")
        assert(i.menu_icons_size==.86 and i.menu_anchor[1]==11 and i.menu_anchor[2]==4 and i.menu_anchor.side==2,"new selection did not apply toolbar defaults")
        assert(i.row_info.texture_background_class_color==false,"new selection did not disable Background by Class")
    end
    for _,key in ipairs({"texture_background","texture_background_file","fixed_texture_background_color"})do
        assert(same(i.row_info[key],initial.D.instance_defaults.row_info[key]),"bar background texture/color/opacity changed: "..key)
    end
    assert(i.menu_icons.space==initial.D.instance_defaults.menu_icons.space,"skin selection imposed unsupported spacing")
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
local pendingExpected=copy(expectedA[1]);pendingExpected.skin="Minimalistic"
assert(same(afterFallback,pendingExpected),"native window construction unexpectedly changed saved settings before late registration: "..mismatch(afterFallback,pendingExpected))
assert(reload.D.waitingForSkins[1]=="Addonskins EUI" and reload.D.waitingForSkins[2]=="Addonskins EUI")
assert(same(prefs(reload.D.profiles.A.instances[1]),expectedA[1]),"upstream fallback already destroyed the saved profile")
local profilesBefore=copy(reload.D.profiles)
reload.P.Register()
assert(same(reload.D.profiles,profilesBefore),"registration wrote a native profile")
for id,wanted in ipairs(expectedA)do
    assert(same(prefs(reload.D:GetInstance(id)),wanted),"REPRO: reload registration lost native customization for window "..id..": "..mismatch(prefs(reload.D:GetInstance(id)),wanted))
end
assert(next(reload.D.waitingForSkins)==nil,"prototype waiting entries were not consumed")
assert(reload.P.recoveredWindows==2 and reload.counts.recovery==0,"registration imported saved appearance instead of avoiding reset")
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
for id=1,2 do customize(reload.D:GetInstance(id),id+6);expectedA[id]=prefs(reload.D:GetInstance(id)) end
reload.P.Refresh()
for id,wanted in ipairs(expectedA)do assert(same(prefs(reload.D:GetInstance(id)),wanted),"later customization was reapplied")end
reload.D:SaveProfile()
local second=environment(reload.save())
second.boot();second.combat(true);second.P.Register()
assert(not second.D.skins["Addonskins EUI"],"registered/recovered during combat")
second.combat(false);second.P.Register()
for id,wanted in ipairs(expectedA)do assert(same(prefs(second.D:GetInstance(id)),wanted),"second reload lost customization")end
for id,wanted in ipairs(expectedB)do assert(same(prefs(second.D.profiles.B.instances[id]),wanted),"inactive profile preferences changed")end
print("PASS: actual native ExportSkin/SaveProfile -> serialized reload -> parser initializer/LoadConfig/ApplyProfile/WaitForSkin -> registration preserves two windows, profiles, timer/fonts/bars/background/title/toolbar")
-- Stale ownership must not select the prototype over a different current skin.
second.D.waitingForSkins={[1]="Addonskins EUI",[9]="Foreign"}
second.D.skins.Foreign=copy(second.D.skins.Minimalistic)
second.D:GetInstance(1):OptionPanelOnChangeSkin("Foreign")
local thirdNS={IsEnabled=function()return true end}
assert(loadfile("EUIAddonSkins/DetailsNative.lua"))("EUIAddonSkins",thirdNS)
second.D.skins["Addonskins EUI"]=nil
local third=thirdNS.CreateNativeDetailsPrototype({H={Allowed=function()return false end,Hook=function()end},S={GetAccentColor=function()return .2,.6,.4 end,GetFont=function()return "fixture-font"end},module={}},function()end)
third.Register()
assert(second.D:GetInstance(1).skin=="Foreign" and second.D.waitingForSkins[9]=="Foreign","stale wait selected prototype or changed a foreign wait")
assert(not second.D.waitingForSkins[1],"stale prototype wait retained")
print("PASS: stale waiting ownership cannot select prototype; foreign waiting entries are untouched")
local closedData=assert(load("return "..reload.save()))()
closedData.profiles.A.instances[2].__was_opened=false
local closed=environment(encode(closedData))
closed.boot();closed.P.Register()
for id,wanted in ipairs(expectedA)do assert(same(prefs(closed.D:GetInstance(id)),wanted),"closed-window startup lost settings")end
assert(closed.P.recoveredWindows==1 and closed.counts.recovery==0 and not closed.D:GetInstance(2):IsEnabled(),"closed window was unnecessarily recovered or opened")
local incomplete=environment(reload.save())
incomplete.boot()
local missing=copy(incomplete.D.profiles.A.instances[1])
incomplete.D.profiles.A.instances[1]=nil
incomplete.P.Register()
assert(incomplete.P.status=="profile" and not incomplete.D.skins["Addonskins EUI"],"missing saved window silently accepted")
assert(incomplete.D.waitingForSkins[1]=="Addonskins EUI","failed recovery consumed its wait")
incomplete.D.profiles.A.instances[1]=missing
local install=incomplete.D.InstallSkin
incomplete.D.InstallSkin=function()return false end
incomplete.P.Register()
assert(incomplete.P.status=="rejected" and incomplete.D.waitingForSkins[1]=="Addonskins EUI","rejected install lost pending ownership")
incomplete.D.InstallSkin=install
incomplete.P.Register()
for id,wanted in ipairs(expectedA)do assert(same(prefs(incomplete.D:GetInstance(id)),wanted),"safe retry lost settings")end
print("PASS: closed windows remain closed; missing native profile windows defer with diagnostic; rejected installation retains recoverable waits")
local chosen=environment(reload.save())
chosen.boot()
-- Choosing the displayed fallback is still an explicit native selection.
chosen.D:GetInstance(1):OptionPanelOnChangeSkin("Minimalistic")
assert(not chosen.D.waitingForSkins[1],"explicit native fallback selection did not cancel pending recovery")
chosen.P.Register()
assert(chosen.D:GetInstance(1).skin=="Minimalistic","late registration undid an explicit native skin selection")
assert(same(prefs(chosen.D:GetInstance(2)),expectedA[2]),"another pending window was lost after explicit selection")
local edited=environment(reload.save())
edited.boot()
customize(edited.D:GetInstance(1),5)
local live=prefs(edited.D:GetInstance(1));live.skin="Addonskins EUI"
local before=copy(edited.D.profiles)
edited.P.Register()
assert(same(prefs(edited.D:GetInstance(1)),live),"registration restored stale saved settings over live startup edits")
assert(same(edited.D.profiles,before),"startup recovery wrote saved profiles")
print("PASS: explicit native fallback selection cancels pending recovery; live startup edits win without profile writes")
local reselect=environment(reload.save())
reselect.boot();reselect.P.Register()
local first,other=reselect.D:GetInstance(1),prefs(reselect.D:GetInstance(2))
first.menu_icons.space=7
local sameSkin=prefs(first)
first:OptionPanelOnChangeSkin("Addonskins EUI")
assert(same(prefs(first),sameSkin),"same-skin selection reapplied recommended defaults")
first:OptionPanelOnChangeSkin("Minimalistic")
first:OptionPanelOnChangeSkin("Addonskins EUI")
assert(first.attribute_text.anchor[1]==-18 and first.attribute_text.anchor[2]==5)
assert(first.menu_icons_size==.86 and first.menu_anchor[1]==11 and first.menu_anchor[2]==4 and first.menu_anchor.side==2)
assert(first.row_info.texture_background_class_color==false and first.attribute_text.show_timer==false)
assert(first.menu_icons.space==7,"explicit reselection overrode native retained spacing")
assert(same(prefs(reselect.D:GetInstance(2)),other),"explicit reselection changed another window")
print("PASS: approved defaults apply on explicit different-skin selection/reselection only; native spacing, same-skin customization and other windows remain owned by Details")
for _,k in ipairs(keys)do _G[k]=original[k]end

