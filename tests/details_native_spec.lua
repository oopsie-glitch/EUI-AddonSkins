-- Native skin boundary tests. No installed addon or client is required.
local ns, hooks, combat, enabled, allocations, writes = {}, {}, false, true, 0, 0
local function copy(t)
    if type(t) ~= "table" then return t end
    local r = {}; for k,v in pairs(t) do r[k] = copy(v) end; return r
end
local function art()
    allocations = allocations + 1
    local a = {path = "native", coords = {0.2,0.2,0.2,0.4,0.4,0.2,0.4,0.4}, color = {1,1,1,1}, alpha = 1}
    function a:GetObjectType() return "Texture" end
    function a:GetTexture() return self.path end
    function a:SetTexture(p) self.path = p; writes = writes + 1 end
    function a:GetTexCoord() return table.unpack(self.coords) end
    function a:SetTexCoord(...)
        local v={...}
        self.coords = #v==4 and {v[1],v[3],v[1],v[4],v[2],v[3],v[2],v[4]} or v
        writes = writes + 1
    end
    function a:GetVertexColor() return table.unpack(self.color) end
    function a:SetVertexColor(...) self.color = {...}; writes = writes + 1 end
    function a:GetAlpha() return self.alpha end
    function a:SetAlpha(v) self.alpha = v; writes = writes + 1 end
    return a
end
local function frame()
    allocations = allocations + 1
    local f = {color = {0,0,0,0.75}}
    function f:GetObjectType() return "Frame" end
    function f:GetBackdropColor() return table.unpack(self.color) end
    function f:SetBackdropColor(...) self.color = {...}; writes = writes + 1 end
    function f:SetBackdrop() error("prototype must never rebuild a backdrop") end
    function f:SetSize() error("prototype must never size a native widget") end
    function f:SetPoint() error("prototype must never anchor a native widget") end
    return f
end
_G.Details = {
    loaded = false, skins = {}, instances = {}, installed_skins_cache = {},
    IsLoaded = function() return Details.loaded end,
    CopyTable = copy,
    instance_defaults = {
        row_info = {height = 14, space = {left=3,right=-5,between=1}, texts = {{font={size=10}}}},
        attribute_text = {enabled=false, show_timer=true, text_face="native"},
        menu_icons_size=1, show_statusbar=true, use_multi_fontstrings=true,
    },
    GetAllInstances = function() return Details.instances end,
    GetInstance = function(_, id) return Details.instances[id] end,
    GetSkin = function(self) return Details.skins[self.skin] end,
    SetBackgroundColor = function(self,r,g,b)
        self.baseframe:SetBackdropColor(r,g,b,self.bg_alpha or 0.75)
        self.bgdisplay:SetBackdropColor(r,g,b,self.bg_alpha or 0.75)
    end,
    SetBackgroundAlpha = function(self,a)
        self.bg_alpha = a
        self.baseframe:SetBackdropColor(0,0,0,a); self.bgdisplay:SetBackdropColor(0,0,0,a)
    end,
}
local function install(self,name,def)
    if not name or not def.file or self.skins[name] and def.is_cached_skin then return false end
    self.skins[name] = def
    for id, waiting in pairs(self.waitingForSkins or {}) do
        if waiting == name then self:GetInstance(id):ChangeSkin(name) end
    end
    return true
end
Details.InstallSkin = install
local function change(self,name)
    if name ~= self.skin then
        local props = copy(Details.skins[name].instance_cprops)
        for k,v in pairs(props or {}) do self[k] = v end
    end
    self.skin = name
end
Details.ChangeSkin = change
local buildMenu, installBuiltin
local source = os.getenv("DETAILS_NATIVE_SOURCE")
if source then
    local function read(p) local f=assert(io.open(source.."/"..p)); local s=f:read("*a"); f:close(); return (s:gsub("\r","")) end
    local skins = read("skins.lua")
    local registry = assert(skins:match("function _detalhes:InstallSkin.-\n\tend"))
    assert(load("local _detalhes=...; "..registry))(Details)
    -- Reproduce the TOC order, not just the early skins.lua implementation.
    local namedGetter=assert(skins:match("function _detalhes:GetSkin.-\n\tend"))
    assert(load("local _detalhes=...; "..namedGetter))(Details)
    local class=read("class_instance.lua")
    local instanceGetter=assert(class:match("function Details:GetSkin%(%)%s+.-\nend"))
    assert(load("local Details=...; "..instanceGetter))(Details)
    local toc=read("Details_Camelot.toc")
    assert(toc:find("functions\\skins.lua",1,true)<toc:find("classes\\class_instance.lua",1,true))
    local first=assert(skins:find('_detalhes:InstallSkin ("Minimalistic",',1,true))
    local last=assert(skins:find('_detalhes:InstallSkin ("Minimalistic v2",',first+1,true))
    local builtIn=skins:sub(first,last-1)
    installBuiltin=function()
        assert(load("local _detalhes,Loc=...; "..builtIn))(Details,setmetatable({},{__index=function(_,k)return k end}))
    end

    -- Execute the official reset/default-application portion without pretending
    -- that a hosted fixture implements the remaining WoW renderer.
    local main = read("window_main.lua")
    local prefix = assert(main:match("(function Details:ChangeSkin.-)\n\tlocal skin_file"))
    local rowTexts = {Prepare=function() end}
    Details.StatusBar = {Reset=function() end, ApplyOptions=function() end, SetPlugin=function() end}
    Details.ResetInstanceConfigKeepingValues = function(self)
        for k,v in pairs(Details.instance_defaults) do self[k]=copy(v) end
    end
    Details.instance_skin_ignored_values = {}
    assert(load("local Details, Details222=...; "..prefix.."\nreturn self.skin\nend"))(Details,{RowTexts=rowTexts})
    local menu = read("window_options2_sections.lua")
    assert(menu:find("pairs(Details.skins)",1,true), "native selector no longer reads the skin registry")
    local builder=assert(menu:match("(local buildSkinMenu = function%(%).-)\n            end"))
    buildMenu=assert(load("local Details,onSelectSkin=...; "..builder.."\nend\nreturn buildSkinMenu"))(Details,function() end)
    assert(menu:find("return buildSkinMenu()",1,true),"native option no longer rebuilds its choices")
    -- Execute the real dropdown opening path through native choice generation.
    -- Its existing interception callback stops before WoW frame painting.
    local dropdown=read("dropdown.lua")
    local mouseDown=assert(dropdown:match("(function DetailsFrameworkDropDownOnMouseDown.-)\nend"))
    local open=assert(load("local DF=...; "..mouseDown.."\nend\nreturn DetailsFrameworkDropDownOnMouseDown"))({
        Dispatch=function(_,fn,...) return fn(...) end,
    })
    local generator=buildMenu
    buildMenu=function()
        local choices
        local object={func=generator,realsizeW=120,OnMouseDownHook=function(_,_,options)
            choices=options; return true
        end}
        local button={MyObject=object,GetName=function() return "NativeSkinChoiceFixture" end,
            text={GetText=function() return "" end}}
        open(button,"LeftButton")
        return assert(choices,"native dropdown did not invoke its menu generator")
    end


    assert(main:find("this_skin.instance_cprops.row_info.space.left",1,true), "re-review native padding exception")
    print("SOURCE: actual TOC-ordered GetSkin override, InstallSkin, Minimalistic definition, native dropdown builder and ChangeSkin prefix")
end
local function instance(id)
    local f = frame()
    f.cabecalho = {ball=art(),ball_r=art(),emenda=art(),top_bg=art()}
    for _,key in ipairs({"modo_selecao","segmento","atributo","report","reset","fechar"}) do
        local b=frame(); b.normal=art(); b.highlight=art()
        function b:GetNormalTexture() return self.normal end
        function b:GetHighlightTexture() return self.highlight end
        f.cabecalho[key]=b
    end
    return setmetatable({meu_id=id,skin="Original",baseframe=f,bgframe={},bgdisplay=frame(),
        row_info=copy(Details.instance_defaults.row_info), bg_alpha=0.75}, {__index=Details})
end
Details.skins.Minimalistic={author="Details!",version="fixture",site="",desc="",file="native-atlas",icon_anchor_main={1,2},icon_anchor_plugins={3,4}, instance_cprops={row_info={height=99}}}
if installBuiltin then installBuiltin() end
Details.skins.Original=copy(Details.skins.Minimalistic)
assert(Details:GetSkin("Minimalistic")==nil, "fixture missed the real late instance-only GetSkin override")
assert(Details.GetSkin({skin="Minimalistic"})==Details.skins.Minimalistic)
Details.instances={instance(1),instance(2)}
InCombatLockdown=function() return combat end
C_AddOns={IsAddOnLoaded=function() return true end}
issecretvalue=function(v) return type(v)=="table" and v.secret end
local media={}
LibStub=function() return {Register=function(_,kind,name,path) media[kind..":"..name]=path end} end
ns.IsEnabled=function() return enabled end
local H={Allowed=function(f) return type(f)=="table" and f.GetObjectType end}
H.Hook=function(object,name,fn)
    if type(object[name])~="function" then return end
    hooks[#hooks+1]={name=name,fn=fn}
    local old=object[name]
    object[name]=function(...) local r=table.pack(old(...)); fn(...); return table.unpack(r,1,r.n) end
end
assert(loadfile("EUIAddonSkins/DetailsNative.lua"))("EUIAddonSkins",ns)
local accent={.12,.63,.46}
local skinAPI={GetAccentColor=function() return table.unpack(accent) end,
    GetFont=function() return "approved-font","" end}
local released=0
local P=ns.CreateNativeDetailsPrototype({H=H,S=skinAPI,module={}},function() released=released+1 end)
local look={texture="approved-bar",font="approved-font",flags="",bg={0,0,0,0.75},
    header={r=27/255,g=27/255,b=27/255},headerAlpha=1,headerHeight=22,headerSize=11,
    titleColor={1,0.7,0.3,1},height=18,spacing=2,leftSize=11,rightSize=10}
-- The legacy shared helper deliberately supports a separate EDM title color.
-- Native skin defaults must use the live EUI accent rather than that preference.
local savedEDM, savedEUI, savedTextures = _EDM_DB, EllesmereUI, _EDM_BarTextures
_EDM_DB={profile={dm={hdrTextUseAccent=false,hdrTextColor={r=1,g=.82,b=0},
    hdrBgColor={r=.41,g=.26,b=.13},hdrBgAlpha=.36,hdrHeight=37,hdrFontSize=19,
    bgR=.2,bgG=.3,bgB=.4,bgAlpha=.28,barHeight=29,barSpacing=6,
    leftFontSize=17,rightFontSize=18,barTexture="optional"}}}
_EDM_BarTextures={optional="Interface\\AddOns\\EllesmereUIDamageMeters\\Media\\bar.tga"}
EllesmereUI={}
assert(loadfile("EUIAddonSkins/MeterStyle.lua"))("EUIAddonSkins",ns)
local legacyLook=ns.GetMeterStyle(skinAPI)
assert(legacyLook.titleColor[1]==1 and legacyLook.titleColor[2]==.82 and legacyLook.titleColor[3]==0)
look=legacyLook
_EDM_DB,EllesmereUI,_EDM_BarTextures=savedEDM,savedEUI,savedTextures
local original=copy(Details.skins.Minimalistic)
P.Refresh(look)
assert(not Details.skins["Addonskins EUI"] and released==0, "registered before Details ready")
Details.loaded=true; combat=true; P.Refresh(look)
assert(not Details.skins["Addonskins EUI"],"registered in combat")
combat=false
local profileBefore=copy(Details.instances[1].row_info)
if os.getenv("DETAILS_REGISTRATION_REPRO") then
    P.Refresh(look)
    assert(Details.skins["Addonskins EUI"], "REPRO: late instance GetSkin prevents prototype registration")
    return
end
local savedLibStub=LibStub
local messages={}
DEFAULT_CHAT_FRAME={AddMessage=function(_,message) messages[#messages+1]=message end}
LibStub=function() return nil end
for _=1,10 do P.Refresh(look) end
assert(P.status=="media" and #messages==1 and not P.installAttempts,"missing SharedMedia was silent or retried InstallSkin")
LibStub=savedLibStub
-- Optional artwork provider is not required for registration.
C_AddOns.IsAddOnLoaded=function() return false end
if buildMenu then
    for _,option in ipairs(buildMenu()) do assert(option.value~="Addonskins EUI") end
end
P.Refresh(look)
local def=assert(Details.skins["Addonskins EUI"])
if os.getenv("DETAILS_MEDIA_REPRO") then
    C_AddOns.IsAddOnLoaded=function() return false end
    local first=Details.instances[1];first:ChangeSkin("Addonskins EUI");P.Apply(first)
    assert(first.baseframe.cabecalho.modo_selecao.normal.path=="Interface\\AddOns\\EUIAddonSkins\\Media\\DetailsNative\\settings.tga",
        "REPRO: native toolbar depends on optional EUI meter")
    return
end
if os.getenv("DETAILS_DEFAULTS_REPRO") then
    assert(def.instance_cprops.titlebar_height==22 and def.instance_cprops.titlebar_texture_color[1]==27/255
        and def.instance_cprops.bg_alpha==.75 and def.instance_cprops.row_info.height==18,
        "REPRO: native definition imports optional meter configuration")
    return
end
assert(Details.GetSkin({skin="Addonskins EUI"})==def, "native instance getter does not resolve the registered skin")
if buildMenu then
    local found=0
    for _,option in ipairs(buildMenu()) do
        if option.value=="Addonskins EUI" then assert(option.label=="Addonskins EUI"); found=found+1 end
    end
    assert(found==1,"native dropdown failed to discover the newly registered skin")
end
local function equalColor(a,b) for i=1,4 do assert(a[i]==b[i],"REPRO: native title default did not use the live EUI accent") end end
equalColor(def.instance_cprops.attribute_text.text_color,{accent[1],accent[2],accent[3],1})
accent={.71,.32,.19}
P.Refresh(look)
equalColor(def.instance_cprops.attribute_text.text_color,{accent[1],accent[2],accent[3],1})
if os.getenv("DETAILS_ACCENT_REPRO") then
    print("PASS: native title ignores EDM custom yellow and refreshes its selection default with the live accent")
    return
end
assert(P.status=="registered" and P.installAttempts==1)
assert(ns.NativeDetailsRegistrationStatus():find("registered in Details.skins",1,true))
C_AddOns.IsAddOnLoaded=function() return true end
assert(def.file==original.file and def.no_cache and not def.is_cached_skin)
assert(Details.skins.Minimalistic.instance_cprops.row_info.height==original.instance_cprops.row_info.height,"mutated source definition")
assert(Details.instances[1].skin=="Original" and Details.instances[1].row_info.height==profileBefore.height and released==0,"installation selected a skin or changed a profile")
assert(def.instance_cprops.bg_alpha==0.75 and def.instance_cprops.titlebar_texture_color[1]==27/255)
assert(def.instance_cprops.row_info.height==18 and def.instance_cprops.row_info.space.between==2)
assert(def.instance_cprops.attribute_text.show_timer==true)
assert(def.instance_cprops.titlebar_height==22 and def.instance_cprops.attribute_text.text_size==11)
assert(media["statusbar:Addonskins EUI Bar"]=="Interface\\Buttons\\WHITE8X8")
assert(media["font:Addonskins EUI Font"]=="approved-font")
assert(def.instance_cprops.row_info.texture_file=="Interface\\Buttons\\WHITE8X8")
-- Shared look retains the unrelated optional preferences; native ignores them.
assert(look.headerHeight==37 and look.bg[4]==.28 and look.height==29)
assert(def.instance_cprops.row_info.texts[1].font.face=="approved-font", "modern row text needs a concrete font file")
for _=1,20 do P.Refresh(look) end
assert(Details.skins["Addonskins EUI"]==def and #hooks==2,"duplicate registration/hooks")
-- A real native selection (only explicit test action), then normal customization.
local a,b=Details.instances[1],Details.instances[2]
a:ChangeSkin("Addonskins EUI")
local optionalQueries=0
C_AddOns.IsAddOnLoaded=function(name)
    if name=="EllesmereUIDamageMeters" then optionalQueries=optionalQueries+1;return false end
    return true
end
P.Apply(a)
assert(optionalQueries==0,"native cosmetics still query optional meter availability")
equalColor(a.attribute_text.text_color,{accent[1],accent[2],accent[3],1})
assert(a.attribute_text.text_color~=def.instance_cprops.attribute_text.text_color,"native selection aliases the definition")
a.attribute_text.text_color={.22,.34,.81,.6}
local manualTitleColor=copy(a.attribute_text.text_color)
accent={.18,.49,.77}
P.Refresh(look)
equalColor(a.attribute_text.text_color,manualTitleColor)
equalColor(def.instance_cprops.attribute_text.text_color,{accent[1],accent[2],accent[3],1})
assert(ns.IsNativeDetailsInstance(a) and not ns.IsNativeDetailsInstance(b))
assert(a.bgdisplay.color[4]==0 and a.baseframe.color[4]==0.75,"duplicated background opacity")
assert(a.baseframe.cabecalho.modo_selecao.normal.path:find("settings.tga",1,true))
a.row_info.height=31; a.row_info.space.between=5; a.row_info.texture="user-texture"
a.row_info.font_face="user-font"; a.attribute_text.show_timer=false
a.menu_icons_size=0.61; a.titlebar_height=29
local count=allocations
local stableWrites=writes
for _=1,1000 do P.Apply(a) end
assert(allocations==count and writes==stableWrites,"warm repaint allocates artwork or rewrites unchanged output")
a:ChangeSkin("Addonskins EUI"); P.Apply(a)
assert(a.row_info.height==31 and a.row_info.texture=="user-texture" and a.row_info.font_face=="user-font")
equalColor(a.attribute_text.text_color,manualTitleColor)
assert(not a.attribute_text.show_timer and a.menu_icons_size==0.61 and a.titlebar_height==29,"refresh overwrote native customization")
assert(b.skin=="Original" and b.row_info.height==14,"affected another instance")
a:SetBackgroundAlpha(0); assert(a.bgdisplay.color[4]==0 and a.baseframe.color[4]==0)
a:SetBackgroundAlpha(1); assert(a.bgdisplay.color[4]==0 and a.baseframe.color[4]==1)
-- Secret input never reaches arithmetic/comparison in the adapter.
a.bgdisplay.color={0,0,0,{secret=true}}; P.Background(a)
a.bgdisplay.color={0,0,0,0}
combat=true; local before=writes; P.Apply(a); P.Toolbar(a); P.Background(a)
assert(writes==before,"mutated UI in combat")
combat=false; P.Apply(a)
-- Session availability, globals and native redraws must not affect cosmetics.
local mediaRoot="Interface\\AddOns\\EUIAddonSkins\\Media\\DetailsNative\\"
for _,state in ipairs({"enabled","disabled","missing"}) do
    C_AddOns.IsAddOnLoaded=function(name)
        if name=="EllesmereUIDamageMeters" then optionalQueries=optionalQueries+1;return state=="enabled" end
        return true
    end
    _EDM_DB=state~="missing" and {profile={dm={hdrHeight=81,bgAlpha=.1}}} or nil
    _EDM_BarTextures=state=="enabled" and {atrocity="optional-media"} or nil
    for key,file in pairs({modo_selecao="settings",segmento="undo",atributo="sheet",report="report",reset="reset",fechar="close"}) do
        local button=a.baseframe.cabecalho[key]
        button.normal:SetTexture("native-redraw")
        P.Toolbar(a)
        assert(button.normal.path==mediaRoot..file..".tga","availability changed toolbar artwork: "..state)
    end
    P.Refresh(look)
    assert(a.menu_icons_size==.61 and a.titlebar_height==29,"availability changed native dimensions")
    assert(a.row_info.texture=="user-texture" and a.row_info.font_face=="user-font")
    equalColor(a.attribute_text.text_color,manualTitleColor)
end
assert(optionalQueries==0,"native prototype queried optional addon")
_EDM_DB,EllesmereUI,_EDM_BarTextures=savedEDM,savedEUI,savedTextures
C_AddOns.IsAddOnLoaded=function() return true end
print("PASS: enabled/disabled/missing optional meter, native redraw, stable defaults, assets, custom settings and zero availability queries")

-- Native renderer replaces art on switching; restoration must not overwrite it.
a:ChangeSkin("Original")
local icon=a.baseframe.cabecalho.modo_selecao.normal
icon:SetTexture("new-native-skin")
P.Apply(a)
assert(icon.path=="new-native-skin" and not P.entries[a],"stale artwork on switch away")
-- Missing-provider fallback is native-owned; a previous explicit selection may
-- be restored synchronously by InstallSkin. Registration itself never chooses.
assert(next(Details.installed_skins_cache)==nil,"cached prototype unexpectedly")
local foreign={file="foreign",instance_cprops={}}
Details.skins["Addonskins EUI"]=foreign
assert(not ns.IsNativeDetailsInstance(b),"foreign collision was claimed")
assert(#hooks==2)
print("PASS: native prototype registration, explicit selection, defaults, independent windows, customization, background alpha, toolbar geometry, secrets, combat and cleanup")
-- Reproducible host-only timing. Native render and WoW GPU costs are absent.
a.skin="Addonskins EUI"; Details.skins["Addonskins EUI"]=def; P.Apply(a)
local samples={}
for trial=1,5 do local start=os.clock(); for _=1,1000 do P.Apply(a) end; samples[trial]=(os.clock()-start)*1000 end
table.sort(samples)
collectgarbage("collect"); local heap=collectgarbage("count")
for _=1,1000 do P.Apply(a) end
collectgarbage("collect")
print(("BENCH native 1000 cosmetic refreshes median_ms=%.3f retained_delta_KiB=%.3f hooks=%d added_frames=0 added_textures=0 added_fontstrings=0"):format(samples[3],collectgarbage("count")-heap,#hooks))

local otherNS={IsEnabled=ns.IsEnabled}
assert(loadfile("EUIAddonSkins/DetailsNative.lua"))("EUIAddonSkins",otherNS)
local P2=otherNS.CreateNativeDetailsPrototype({H=H,S=skinAPI,module={}},function() end)
Details.skins["Addonskins EUI"]={file="foreign"}
P2.Register(look)
assert(P2.collision and Details.skins["Addonskins EUI"].file=="foreign","overwrote a foreign name")
Details.skins["Addonskins EUI"]=nil
Details.waitingForSkins={[2]="Addonskins EUI"}
b.skin="Original"
P2.Register(look)
assert(b.skin=="Addonskins EUI","did not account for native waiting-skin restoration")
assert(not next(Details.installed_skins_cache),"waiting recovery cached prototype")
print("PASS: foreign collision and prior-selection waiting restoration through native registration")

-- Isolate registration and first cosmetic activation from warm-refresh timing.
local savedInstances, savedWaiting, savedDefinition = Details.instances, Details.waitingForSkins, Details.skins["Addonskins EUI"]
local registration, activation, registryHeap = {}, {}, {}
for trial=1,5 do
    local context={IsEnabled=function() return true end}
    assert(loadfile("EUIAddonSkins/DetailsNative.lua"))("EUIAddonSkins",context)
    local coldH={Allowed=H.Allowed,Hook=function() end}
    local p=context.CreateNativeDetailsPrototype({H=coldH,S=skinAPI,module={}},function() end)
    Details.skins["Addonskins EUI"]=nil
    Details.instances={}; Details.waitingForSkins=nil
    collectgarbage('collect'); local heap=collectgarbage('count')
    local start=os.clock(); p.Register(look); registration[trial]=(os.clock()-start)*1000
    collectgarbage('collect'); registryHeap[trial]=collectgarbage('count')-heap
    local inst=instance(1); inst.skin="Addonskins EUI"
    local before=allocations
    start=os.clock(); p.Apply(inst); activation[trial]=(os.clock()-start)*1000
    assert(allocations==before,"cold cosmetics create UI objects")
end
table.sort(registration); table.sort(activation); table.sort(registryHeap)
Details.instances, Details.waitingForSkins, Details.skins["Addonskins EUI"] = savedInstances, savedWaiting, savedDefinition
print(("BENCH native registration median_ms=%.3f retained_KiB=%.3f first_cosmetic_activation_ms=%.3f trials=5"):format(registration[3],registryHeap[3],activation[3]))

-- Secret UV/color inputs are neither changed nor retained for later restoration.
Details.waitingForSkins=nil
local secretNS={IsEnabled=ns.IsEnabled}
assert(loadfile("EUIAddonSkins/DetailsNative.lua"))("EUIAddonSkins",secretNS)
local secureP=secretNS.CreateNativeDetailsPrototype({H={Allowed=H.Allowed,Hook=function() end},S=skinAPI,module={}},function() end)
Details.skins["Addonskins EUI"]=nil; secureP.Register(look)
local secretInstance=instance(9); secretInstance.skin="Addonskins EUI"
local secretArt=secretInstance.baseframe.cabecalho.modo_selecao.normal
secretArt.coords={{secret=true},0,0,1,1,0,1,1}
secureP.Apply(secretInstance)
assert(secretArt.path=="native" and not secureP.entries[secretInstance].art[secretArt],"retained or restyled secret texture coordinates")
secretInstance.skin="Original"; secureP.Apply(secretInstance)
print("PASS: secret texture coordinates are not cached or restored")

-- Reconstruct cold registration under all optional-addon session states.
-- Use the actual shared helper to supply deliberately different legacy looks.
local savedInstancesForMatrix=Details.instances
local savedDefinitionForMatrix=Details.skins["Addonskins EUI"]
local matrixDefinition
local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for k,v in pairs(a) do if not same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
for _,availability in ipairs({"enabled","disabled","missing"}) do
    Details.instances={};Details.waitingForSkins=nil;Details.skins["Addonskins EUI"]=nil
    C_AddOns.IsAddOnLoaded=function()return availability=="enabled" end
    _EDM_DB=availability=="enabled" and {profile={dm={
        hdrHeight=41,hdrBgAlpha=.23,hdrBgColor={r=.2,g=.3,b=.4},
        bgR=.3,bgG=.2,bgB=.1,bgAlpha=.26,barHeight=33,barSpacing=7,barTexture="optional"
    }}} or nil
    _EDM_BarTextures=availability=="enabled" and {optional="optional-meter-texture"} or nil
    EllesmereUI={GetFontPath=function()if availability=="enabled" then return "optional-meter-font" end end}
    local context={IsEnabled=ns.IsEnabled}
    assert(loadfile("EUIAddonSkins/DetailsNative.lua"))("EUIAddonSkins",context)
    local isolated=context.CreateNativeDetailsPrototype({H={Allowed=H.Allowed,Hook=function()end},S=skinAPI,module={}},function()error("registration selected a window")end)
    local legacy=ns.GetMeterStyle(skinAPI)
    isolated.Register(legacy)
    local current=assert(Details.skins["Addonskins EUI"])
    if matrixDefinition then assert(same(current,matrixDefinition),"optional meter changed fresh native definition") end
    matrixDefinition=copy(current)
    assert(media["statusbar:Addonskins EUI Bar"]=="Interface\\Buttons\\WHITE8X8")
    assert(media["font:Addonskins EUI Font"]=="approved-font")
end
Details.instances,Details.skins["Addonskins EUI"]=savedInstancesForMatrix,savedDefinitionForMatrix
_EDM_DB,EllesmereUI,_EDM_BarTextures=savedEDM,savedEUI,savedTextures
print("PASS: fresh native definitions and registered media identical with optional meter enabled, disabled and absent")
