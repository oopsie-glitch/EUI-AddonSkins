-- Execute native layout functions against a scale-aware frame/anchor model.
-- No mocked toolbar placement: the native code chooses every button point/size.
local source=os.getenv("DETAILS_NATIVE_SOURCE")
if not source then print("SKIP: Details native geometry source fixture (run by pinned-source CI)"); return end
local function read(name) local f=assert(io.open(source.."/"..name));local s=f:read("*a");f:close();return (s:gsub("\r","")) end
local main,skins=read("window_main.lua"),read("skins.lua")
local native=false
local geometryEpoch=0
local writes, objects, hooks = {title=0,button=0}, 0, 0
local function copy(v) if type(v)~="table" then return v end local t={};for k,x in pairs(v) do t[k]=copy(x) end;return t end
local frac={BOTTOMLEFT={0,0},BOTTOMRIGHT={1,0},TOPLEFT={0,1},TOPRIGHT={1,1},LEFT={0,.5},RIGHT={1,.5},CENTER={.5,.5},TOP={.5,1},BOTTOM={.5,0}}
local F={}; F.__index=F
local function frame(kind,parent)
    objects=objects+1
    return setmetatable({kind=kind or "Frame",parent=parent,points={},width=128,height=128,color={1,1,1,1},alpha=1},F)
end
function F:GetObjectType() return self.kind end
function F:IsShown() return not self.hidden end
function F:Show() self.hidden=false end
function F:Hide() self.hidden=true end
function F:SetScript(name,fn) self.scripts=self.scripts or {};self.scripts[name]=fn end
function F:SetShown(v) self.hidden=not v end
function F:SetParent(p) self.parent=p;geometryEpoch=geometryEpoch+1 end
function F:GetParent() return self.parent end
function F:GetEffectiveScale() return self.scale or self.parent and self.parent:GetEffectiveScale() or 1 end
function F:GetFrameLevel() return 2 end
function F:SetFrameLevel() end
function F:GetWidth() return self.stretch and self.parent:GetWidth() or self.width end
function F:GetHeight() return self.height end
function F:GetNumPoints() return #self.points end
function F:GetPoint(i) return table.unpack(self.points[i or 1],1,5) end
local function mutate(f)
    geometryEpoch=geometryEpoch+1
    if f.kind=="Button" then assert(native,"adapter changed native button geometry"); writes.button=writes.button+1
    elseif f.kind=="FontString" then writes.title=writes.title+1 end
end
function F:ClearAllPoints() mutate(self); self.points={} end
function F:SetPoint(p,r,rp,x,y)
    mutate(self); self.points[#self.points+1]={p:upper(),r,rp:upper(),x or 0,y or 0}
end
function F:SetSize(w,h) mutate(self); self.width,self.height=w,h end
function F:SetWidth(w) mutate(self); self.width=w end
function F:SetHeight(h) mutate(self); self.height=h end
local function rect(f)
    if f.rectEpoch==geometryEpoch then return table.unpack(f.cachedRect) end
    local scale=f:GetEffectiveScale()
    local w,h=f:GetWidth()*scale,f:GetHeight()*scale
    local p=f.points[1]
    if not p then
        f.cachedRect={(f.x or 0)*scale,(f.y or 0)*scale,w,h};f.rectEpoch=geometryEpoch
        return table.unpack(f.cachedRect)
    end
    local rx,ry,rw,rh=rect(p[2])
    local a,b=frac[p[1]],frac[p[3]]
    f.cachedRect={rx+rw*b[1]+p[4]*scale-w*a[1],ry+rh*b[2]+p[5]*scale-h*a[2],w,h};f.rectEpoch=geometryEpoch
    return table.unpack(f.cachedRect)
end
function F:GetLeft() return select(1,rect(self))/self:GetEffectiveScale() end
function F:GetBottom() return select(2,rect(self))/self:GetEffectiveScale() end
function F:GetRight() local x,y,w=rect(self);return (x+w)/self:GetEffectiveScale() end
function F:GetTop() local x,y,w,h=rect(self);return (y+h)/self:GetEffectiveScale() end
function F:SetTexture(v) self.path=v end
function F:GetTexture() return self.path end
function F:SetTexCoord(...) self.coords={...} end
function F:GetTexCoord() return table.unpack(self.coords or {0,1,0,1}) end
function F:SetVertexColor(...) self.color={...} end
function F:GetVertexColor() return table.unpack(self.color) end
function F:SetAlpha(v) self.alpha=v end
function F:GetAlpha() return self.alpha end
function F:SetText(v) self.text=v end
function F:GetText() return self.text end
function F:SetBackdrop(v) assert(native,"adapter rebuilt a native backdrop");self.backdrop=v end
function F:SetBackdropColor(...) self.bg={...} end
function F:GetBackdrop() return self.backdrop end
function F:GetBackdropColor() return table.unpack(self.bg or {0,0,0,.75}) end
function F:CreateTexture() return frame("Texture",self) end
function F:SetNormalTexture(v) self.normal:SetTexture(v) end
function F:SetHighlightTexture(v) self.highlight:SetTexture(v) end
function F:SetPushedTexture(v) self.pushed:SetTexture(v) end
function F:GetNormalTexture() return self.normal end
function F:GetHighlightTexture() return self.highlight end
function F:GetPushedTexture() return self.pushed end
function F:SetTextColor(...)
    assert(native,"adapter directly recolored native title")
    self.textColor={...};self.colorWrites=(self.colorWrites or 0)+1
end
local combat=false
InCombatLockdown=function() return combat end
issecretvalue=function(v) return type(v)=="table" and v.secret end
local timers
C_Timer={After=function(_,fn) if timers then timers[#timers+1]=fn end end}
local function flushTimers()
    local pending=timers;timers=nil
    for _,fn in ipairs(pending or {}) do
        local old=native;native=true;fn();native=old
    end
end
C_AddOns={IsAddOnLoaded=function(name)
    return name~="EllesmereUIDamageMeters" or (os.getenv("DETAILS_EDM_STATE") or "enabled")=="enabled"
end}
local registered={}
local media={Register=function(_,kind,name,path) registered[kind..":"..name]=path end,
    Fetch=function(_,kind,name) return registered[kind..":"..name] or name end}
LibStub=function() return media end
local D={skins={},instances={},loaded=true,CopyTable=copy,
    IsLoaded=function() return true end,GetAllInstances=function(self)return self.instances end,
    instance_skin_ignored_values={},StatusBar={Reset=function()end},ToolBar={Shown={}},
    SetFontFace=function(_,t,v)t.face=v end,SetFontSize=function(_,t,v)t.size=v end,
    SetFontOutline=function()end,
    Destroy=function(_,t)for k in pairs(t) do t[k]=nil end end,
    GetTitleBarFontString=function(self)return self.title end,
    IsLowerInstance=function()return false end,
}
_G.Details=D
local framework={IsAddonApocalypseWow=function()return false end}
-- Execute the real Details -> DF parser -> FontString color path, including
-- AttributeMenu's native delayed color callback; no successful-color stub.
local parse=assert(read("fw.lua"):match("(function DF:ParseColors.-)\n\tend"))
assert(load("local DF=...; local unpack=unpack or table.unpack; local Saturate=function(v)return math.max(0,math.min(1,v))end; "..parse.."\nend"))(framework)
local fontColor=assert(read("util.lua"):match("(function Details:SetFontColor.-)\n\tend"))
assert(load("local Details,gump=...; "..fontColor.."\nend"))(D,framework)
_G.DetailsFramework=framework
local rowtexts={Prepare=function()end,GetDefaultTexts=function()return {{font={}}}end}
-- Read the real native default table without running unrelated initializers.
local defaults=assert(read("include_instance.lua"):match("(_detalhes.instance_defaults = .*)"))
assert(load("local _detalhes,SharedMedia,Details222=...; "..defaults))(D,media,{RowTexts=rowtexts})
local include=read("include_instance.lua")
assert(load("local _detalhes=...; "..assert(include:match("(_detalhes.instance_skin_ignored_values = %b{})"))))(D)
local reset=assert(include:match("(function _detalhes:ResetInstanceConfigKeepingValues.-)\nend"))
assert(load("local _detalhes,Details,Details222=...; "..reset.."\nend"))(D,D,{RowTexts=rowtexts})
local changePrefix=assert(main:match("(function Details:ChangeSkin.-)\n\tlocal skin_file"))
assert(load("local Details,Details222=...; "..changePrefix.."\nend"))(D,{RowTexts=rowtexts})
local function method(name,file)
    local body=assert((file or main):match("(function Details:"..name.."%s*%b().-)\nend"),name)
    local constants="local COORDS_LEFT_BALL_NO_ICON,COORDS_LEFT_CONNECTOR_NO_ICON,COORDS_LEFT_BALL,COORDS_LEFT_CONNECTOR,COORDS_RIGHT_BALL,COORDS_TOP_BACKGROUND,COORDS_BOTTOM_SIDE_BAR={0,1,0,1},{0,1,0,1},{0,1,0,1},{0,1,0,1},{0,1,0,1},{0,1,0,1},{0,1,0,1}\n"
    assert(load("local Details,gump,SharedMedia,Details222,detailsFramework,tbuttons=...; local unpack=unpack or table.unpack; "..constants..body.."\nend"))(D,framework,media,{RowTexts=rowtexts,WindowSnap={RefreshGeometry=function()end}},framework,{})
end
for _,name in ipairs({"GetMenuAnchorPoint","ToolbarMenuButtonsSize","ToolbarMenuSetButtons","ToolbarMenuSetButtonsOptions","ToolbarMenuButtons","MenuAnchor","LeftMenuAnchorSide","RefreshAttributeTextSize","AttributeMenu","RefreshTitleBar","SetBackdropTexture"}) do method(name) end
method("SetBackgroundColor",read("class_instance.lua"));method("SetBackgroundAlpha",read("class_instance.lua"))
-- Safe stubs for non-layout native services.
D.RefreshTitleBarText=function()end
D.StretchButtonAnchor=function()end
D.HideMainIcon=function()end
D.SetBarGrowDirection=function()end
D.ShowSideBars=function()end
method("ToolbarSide")
local function Native(fn,...) local old=native;native=true;local out=table.pack(fn(...));native=old;return table.unpack(out,1,out.n)end
local registry=assert(skins:match("function _detalhes:InstallSkin.-\n\tend"))
assert(load("local _detalhes=...; "..registry))(D)
local first=assert(skins:find('_detalhes:InstallSkin ("Minimalistic",',1,true))
local last=assert(skins:find('_detalhes:InstallSkin ("Minimalistic v2",',first+1,true))
assert(load("local _detalhes,Loc=...;"..skins:sub(first,last-1)))(D,setmetatable({},{__index=function(_,k)return k end}))
local ns={IsEnabled=function()return true end}
local H={Allowed=function(f)return type(f)=="table" and f.GetObjectType end}
function H.Hook(o,name,fn)
    if not o[name] then return end
    hooks=hooks+1;local original=o[name]
    o[name]=function(...)
        local old=native; native=true;local out=table.pack(original(...));native=false;fn(...);native=old
        return table.unpack(out,1,out.n)
    end
end
assert(loadfile("EUIAddonSkins/DetailsNative.lua"))("EUIAddonSkins",ns)
local accent={.13,.62,.47}
local P=ns.CreateNativeDetailsPrototype({H=H,S={GetAccentColor=function()return table.unpack(accent)end,GetFont=function()return "approved-font","" end},module={}},function()end)
local look={texture="approved-bar",font="approved-font",bg={0,0,0,.75},
    header={r=27/255,g=27/255,b=27/255},headerAlpha=1,headerHeight=22,headerSize=11,
    titleColor={1,.7,.3,1},height=18,spacing=2,leftSize=11,rightSize=10}
P.Register(look)
local definition=assert(D.skins["Addonskins EUI"])
local base=D.skins.Minimalistic
assert(definition.icon_anchor_main[1]==base.icon_anchor_main[1] and definition.icon_anchor_plugins[2]==base.icon_anchor_plugins[2])
if not os.getenv("DETAILS_LAYOUT_REPRO") and not os.getenv("DETAILS_LAYOUT_BENCH") then
    assert(definition.instance_cprops.menu_anchor.side==base.instance_cprops.menu_anchor.side,"discarded coordinated native toolbar side")
    assert(definition.instance_cprops.attribute_text.anchor~=base.instance_cprops.attribute_text.anchor,"native title defaults alias the base skin")
end
local function instance()
    local i=copy(definition.instance_cprops);setmetatable(i,{__index=D});i.skin="Addonskins EUI"
    i.baseframe=frame();i.baseframe.width=380;i.baseframe.height=180
    local f=i.baseframe;f.x=100;f.y=200;f.cabecalho={}
    i.bgframe=frame(nil,f)
    local h=f.cabecalho
    for _,key in ipairs({"ball","ball_r","ball_point","emenda","top_bg"})do h[key]=frame("Texture",f) end
    f.UPFrame=frame(nil,f);f.UPFrameConnect=frame(nil,f);f.UPFrameLeftPart=frame(nil,f)
    f.titleBar=frame(nil,f);f.titleBar.stretch=true;f.titleBar.texture=frame("Texture",f.titleBar)
    Native(f.titleBar.SetPoint,f.titleBar,"BOTTOMLEFT",f,"TOPLEFT",0,0)
    i.bgdisplay=frame(nil,f);i.menu_points={frame(nil,f),frame(nil,f)}
    for _,point in ipairs(i.menu_points) do point.width,point.height=1,1 end -- native constructor uses 1x1 anchors
    i.title=frame("FontString",f.titleBar);i.title.height=13;i.title.text="Damage Done"
    for _,key in ipairs({"modo_selecao","segmento","atributo","report","reset","fechar"})do
        local button=frame("Button",f);button.normal=frame("Texture",button);button.highlight=frame("Texture",button);button.pushed=frame("Texture",button)
        h[key]=button
    end
    function i:GetSize()return self.baseframe:GetWidth(),self.baseframe:GetHeight()end
    -- Scene setup only; all tested placement then comes from native functions.
    i.menu_icons={true,true,true,true,true,true,space=-2,shadow=false}
    return i
end
local function layout(i)
    Native(i.ToolbarSide,i);Native(i.AttributeMenu,i);Native(i.RefreshTitleBar,i)
    Native(i.SetBackgroundColor,i);Native(i.SetBackdropTexture,i)
    P.Apply(i)
end
local function noOverlap(i)
    local t=i.title;if not t:IsShown() or t:GetAlpha()==0 then return end
    local tl,tr,tt,tb=t:GetLeft(),t:GetRight(),t:GetTop(),t:GetBottom()
    assert(t:GetWidth()>=0)
    for _,key in ipairs({"modo_selecao","segmento","atributo","report","reset","fechar"})do
        local b=i.baseframe.cabecalho[key]
        if b:IsShown() and b:GetTop()>tb and b:GetBottom()<tt then
            assert(tr<=b:GetLeft()+.00001 or tl>=b:GetRight()-.00001,"REPRO: title and native toolbar overlap")
        end
    end
end
local a,b=instance(),instance();D.instances={a,b}
for _,i in ipairs({a,b})do P.Apply(i) end
if os.getenv("DETAILS_LAYOUT_BENCH") then
    a.menu_anchor.side=1;layout(a)
    local samples={}
    local objectCount,hookCount,titleWrites=objects,hooks,writes.title
    for trial=1,5 do
        collectgarbage("collect")
        local start=os.clock();for _=1,1000 do P.Apply(a)end;samples[trial]=(os.clock()-start)*1000
    end
    table.sort(samples)
    collectgarbage("collect");local heap=collectgarbage("count")
    for _=1,1000 do P.Apply(a)end
    collectgarbage("collect")
    print(("LAYOUT_BENCH warm_refreshes=1000 median_ms=%.3f frame_growth=%d hook_growth=%d title_writes=%d retained_delta_KiB=%.3f"):format(
        samples[3],objects-objectCount,hooks-hookCount,writes.title-titleWrites,collectgarbage("count")-heap))
    local refresh={}
    for trial=1,5 do
        local start=os.clock();for _=1,1000 do P.Register(look) end;refresh[trial]=(os.clock()-start)*1000
    end
    table.sort(refresh)
    print(("ACCENT_DEFAULT_BENCH refreshes=1000 median_ms=%.3f added_ui_objects=%d added_hooks=%d"):format(refresh[3],objects-objectCount,hooks-hookCount))
    return
end
if os.getenv("DETAILS_LAYOUT_REPRO") then
    -- Existing saved prototype profiles retain the old left-side setting.
    a.menu_anchor.side=1;layout(a);noOverlap(a);return
end
-- User-approved native defaults replace the earlier calculated centering.
-- Verify native fields and containment, not a new automatic centering policy.
local function checkInitialHeader(i)
    assert(i.attribute_text.anchor[1]==-18 and i.attribute_text.anchor[2]==5,
        "REPRO: initial native title defaults differ from approved values")
    assert(i.menu_icons_size==.86 and i.menu_anchor[1]==11 and i.menu_anchor[2]==4 and i.menu_anchor.side==2,
        "REPRO: initial native toolbar defaults differ from approved values")
    assert(i.row_info.texture_background_class_color==false,"initial Background by Class is not off")
    layout(i)
    local top=i.baseframe:GetTop()
    assert(math.abs(i.title:GetBottom()-top-5)<1e-7,"native title did not use the approved Y offset")
    assert(i.title:GetBottom()>=i.baseframe.titleBar:GetBottom()-1e-7 and i.title:GetTop()<=i.baseframe.titleBar:GetTop()+1e-7,"initial native title is outside the header")
    for _,key in ipairs({"modo_selecao","segmento","atributo","report","reset","fechar"}) do
        local button=i.baseframe.cabecalho[key]
        if button:IsShown() then
            assert(math.abs(button:GetHeight()-16*.86)<1e-7,"native button did not apply initial size multiplier")
            assert(button:GetBottom()>=i.baseframe.titleBar:GetBottom()-1e-7 and button:GetTop()<=i.baseframe.titleBar:GetTop()+1e-7,"native initial toolbar is outside the header")
            assert(button:GetRight()<=i.baseframe:GetRight()+1e-7,"initial toolbar exceeds header right edge")
        end
    end
end
if os.getenv("DETAILS_HEADER_REPRO") then
    checkInitialHeader(instance());return
end
if not os.getenv("DETAILS_BODY_REPRO") then
for _,scale in ipairs({.75,1,1.375}) do
    for _,width in ipairs({90,180,380,600}) do
        local initial=instance()
        initial.baseframe.scale=scale;initial.baseframe.width=width
        checkInitialHeader(initial)
    end
end
end
-- Native selection must preserve its own ignored fields, including spacing.
local retained=instance();retained.skin="Minimalistic";retained.menu_icons.space=4
Native(retained.ChangeSkin,retained,"Addonskins EUI")
assert(retained.menu_icons.space==4,"skin registration bypassed native retained spacing")
retained.menu_icons_size=1.3
retained.menu_anchor={7,9,side=1};retained.attribute_text.anchor={3,10}
retained.menu_icons.space=5
Native(retained.ChangeSkin,retained,"Addonskins EUI") -- same-skin refresh
layout(retained);P.Apply(retained)
assert(retained.menu_icons_size==1.3 and retained.menu_anchor[1]==7 and retained.menu_anchor[2]==9)
assert(retained.attribute_text.anchor[2]==10 and retained.menu_icons.space==5,"adapter enforced header defaults over native customization")
-- Position and spacing use the existing native setters with no adapter hook.
Native(retained.MenuAnchor,retained,11,12)
Native(retained.ToolbarMenuSetButtonsOptions,retained,3)
assert(retained.menu_anchor[1]==11 and retained.menu_anchor[2]==12 and retained.menu_icons.space==3)
print("PASS: approved native defaults/containment at 12 scale/width combinations; native retained spacing, custom size/anchors and same-skin refresh preserved")

-- A native skin selection initializes the instance once. Re-rendering uses
-- the instance's own RGBA, including the native one-second callback.
local function colorEqual(a,b)
    for n=1,4 do assert(a[n]==b[n],"native rendered title color mismatch") end
end
local selected=instance()
timers={};layout(selected);flushTimers()
colorEqual(selected.title.textColor,{accent[1],accent[2],accent[3],1})
selected.attribute_text.text_color={.8,.21,.34,.53}
timers={};Native(selected.AttributeMenu,selected);flushTimers()
colorEqual(selected.title.textColor,selected.attribute_text.text_color)
D.instances[#D.instances+1]=selected
local beforeColor, beforeHooks, beforeObjects=selected.title.colorWrites,hooks,objects
accent={.68,.37,.15}
for _=1,1000 do P.Refresh(look) end
colorEqual(selected.attribute_text.text_color,{.8,.21,.34,.53})
colorEqual(selected.title.textColor,{.8,.21,.34,.53})
assert(selected.title.colorWrites==beforeColor and hooks==beforeHooks and objects==beforeObjects,"accent refresh touched native title or grew resources")
colorEqual(definition.instance_cprops.attribute_text.text_color,{accent[1],accent[2],accent[3],1})
-- A different/fresh window gets the new default; saved profile values win
-- when reconstructed for reload or profile switching.
local fresh=instance();timers={};layout(fresh);flushTimers()
colorEqual(fresh.title.textColor,{accent[1],accent[2],accent[3],1})
local profile=copy(selected.attribute_text)
local restoredColor=instance();restoredColor.attribute_text=copy(profile)
timers={};layout(restoredColor);flushTimers()
colorEqual(restoredColor.title.textColor,profile.text_color)
assert(restoredColor.attribute_text.text_color~=definition.instance_cprops.attribute_text.text_color)
timers={};Native(restoredColor.AttributeMenu,restoredColor);accent={.28,.51,.78};P.Refresh(look);flushTimers()
colorEqual(restoredColor.title.textColor,profile.text_color)
combat=true;accent={.34,.67,.29};local previousDefault=copy(definition.instance_cprops.attribute_text.text_color)
P.Refresh(look);colorEqual(definition.instance_cprops.attribute_text.text_color,previousDefault)
combat=false;P.Refresh(look)
colorEqual(definition.instance_cprops.attribute_text.text_color,{accent[1],accent[2],accent[3],1})
print("PASS: actual native AttributeMenu / SetFontColor / DF ParseColors: live accent default, manual RGBA, deferred color, independent windows, profile reconstruction, combat and zero adapter color writes")

-- Test the native removal path that the former duplicate-fill assumption
-- missed. Do not rebuild a backdrop or increase the saved opacity to hide it.
local body=instance();Native(body.SetBackdropTexture,body);P.Apply(body)
assert(body.baseframe.bg[4]==.75 and body.bgdisplay.bg[4]==0)
local clearBase=assert(main:match("(baseFrame:SetBackdropColor%(0, 0, 0, 0%).-baseFrame:SetBackdrop%(nil%))"))
body.baseframe.SetBackdropBorderColor=function()end
Native(assert(load("local baseFrame=...; "..clearBase)),body.baseframe)
P.Background(body)
assert(body.bgdisplay.bg[4]==.75,"REPRO: prototype removed sole native body fill")
assert(body.bg_alpha==.75 and body.baseframe:GetBackdrop()==nil)
Native(body.SetBackgroundAlpha,body,.38);P.Background(body)
assert(body.bgdisplay.bg[4]==.38 and body.bg_alpha==.38)
Native(body.SetBackgroundAlpha,body,0);P.Background(body)
assert(body.bgdisplay.bg[4]==0,"zero native opacity lost during fallback")
Native(body.SetBackdropTexture,body);Native(body.SetBackgroundAlpha,body,.75);P.Background(body)
assert(body.baseframe.bg[4]==.75 and body.bgdisplay.bg[4]==0)
-- Effective opacity includes inherited frame alpha; skin must not cancel
-- native interaction/combat fading or silently change bg_alpha.
for _,parentAlpha in ipairs({1,.7,.35}) do
    body.baseframe:SetAlpha(parentAlpha)
    local effective=body.baseframe.bg[4]*body.baseframe:GetAlpha()
    assert(math.abs(effective-.75*parentAlpha)<1e-10 and body.bg_alpha==.75)
end
print("PASS: actual native base-backdrop removal, surviving fill, single .75 body, zero/custom opacity and inherited-alpha ownership")
if os.getenv("DETAILS_BODY_REPRO") then return end

-- The Designer checkbox uses the native positional setter. New defaults
-- disable encounter timers; user enabling is retained by adapter refreshes.
local nativeDesigner=read("designer_objects.lua")
local applyText=assert(nativeDesigner:match("(local applyTitleText = function%(instanceObject%).-)\nend"))
local designerApply=assert(load(applyText.."\nend\nreturn applyTitleText"))()
assert(selected.attribute_text.show_timer==false,"fresh native default kept encounter timer")
Native(designerApply,selected)
assert(selected.attribute_text.show_timer==false)
selected.attribute_text.show_timer=true
Native(designerApply,selected)
for _=1,20 do P.Refresh(look);P.Apply(selected) end
assert(selected.attribute_text.show_timer==true,"skin forced enabled timer off")
local savedTimer=copy(selected.attribute_text)
local reloaded=instance();reloaded.attribute_text=copy(savedTimer)
Native(designerApply,reloaded);P.Apply(reloaded)
assert(reloaded.attribute_text.show_timer==true,"profile reconstruction lost enabled timer")
-- Execute native encounter start scheduling, not a mocked successful switch.
method("CheckForTextTimeCounter")
method("SetTitleBarText");method("GetTitleBarText")
D.instance_title_text_timer={}
local tickStart=assert(main:find("local formatTime = function(t)",1,true))
local tickEnd=assert(main:find("function Details:RefreshTitleBarText()",tickStart,true))
assert(load("local Details,detailsFramework,Details222=...; local floor=math.floor; local IsEncounterInProgress=function()return true end; "..main:sub(tickStart,tickEnd-1)))(D,framework,{})
D.GetZoneType=function()return "party" end
local combatTime={GetCombatTime=function()return 91 end}
D.GetCurrentCombat=function()return combatTime end
function selected:GetShowingCombat()return combatTime end
selected.title.text="Damage Done";selected.title.originalText="Damage Done"
local scheduled,nativeTick=0,nil
D.GetLowerInstanceNumber=function()return 1 end
D.GetInstance=function()return selected end
function selected:GetId()return 1 end
function selected:IsEnabled()return true end
D.Schedules={Cancel=function()end,NewTicker=function(_,fn,owner,inst)
    scheduled=scheduled+1;assert(type(fn)=="function" and owner==D and inst==selected)
    nativeTick=function()Native(fn,owner,inst)end;return {}
end}
selected.attribute_text.show_timer=false
Native(D.CheckForTextTimeCounter,D,true);assert(scheduled==0 and selected.title.text=="Damage Done")
selected.attribute_text.show_timer=true
Native(D.CheckForTextTimeCounter,D,true);assert(scheduled==1)
nativeTick();assert(selected.title.text=="[01:31] Damage Done","native opt-in timer renderer was altered")
assert(selected.attribute_text.show_timer==true and definition.instance_cprops.attribute_text.show_timer==false)
print("PASS: native Designer timer setter, off selection default, user opt-in, native encounter scheduling and saved-profile reconstruction")

-- Native startup owns the footer. Execute its actual show/schedule block
-- and the native fade engine; the adapter must not hide it or cancel its fade.
local util=read("util.lua")
local fadeStart=assert(util:find("Details.FadeHandler = {",1,true))
local fadeEnd=assert(util:find("--details api functions",fadeStart,true))
assert(load("local Details,CreateFrame,upper,Lerp=...; "..util:sub(fadeStart,fadeEnd-1)))(
    D,function()return frame()end,function(v)return type(v)=="string" and v:upper() or v end,
    function(a,b,t)return a+(b-a)*t end)
local startup=read("startup.lua")
local startupBlock=assert(startup:match("(%-%-version\n.-Details.Schedules.NewTimer%(12, Details.FadeStartVersion, Details%))"))
D.userversion,D.realversion="1.60.1 15410",172
local pendingVersion
D.Schedules={NewTimer=function(delay,fn,owner) assert(delay==12);pendingVersion=function()fn(owner)end end}
a._version=frame("FontString",a.baseframe);a._version:Hide()
local devIcon,devText=frame("Texture"),frame("FontString")
Native(assert(load("local Details,instance,devIcon,devText=...; "..startupBlock)),D,a,devIcon,devText)
assert(a._version:IsShown() and a._version:GetAlpha()==1)
assert(a._version.text=="Details! 1.60.1 15410 (core 172)")
for _,availability in ipairs({true,false}) do
    C_AddOns.IsAddOnLoaded=function()return availability end
    P.Refresh(look)
    assert(a._version:IsShown() and a._version:GetAlpha()==1,"skin changed native startup footer")
end
Native(pendingVersion)
Native(D.FadeHandler.OnUpdateFrame.scripts.OnUpdate,D.FadeHandler.OnUpdateFrame,2)
assert(not a._version:IsShown() and a._version:GetAlpha()==0,"skin blocked native footer fade")
P.Refresh(look)
assert(not a._version:IsShown() and a._version:GetAlpha()==0,"skin revived native hidden footer")
C_AddOns.IsAddOnLoaded=function()return true end
print("PASS: actual Details startup footer, 12-second schedule and native two-second fade remain owned by Details")

for _,scale in ipairs({.75,1,1.375})do
 for _,width in ipairs({90,180,380,600})do
  for _,side in ipairs({1,2})do
   for _,vertical in ipairs({1,2})do
    for _,size in ipairs({.6,1,1.4})do
     for _,visible in ipairs({0,2,6})do
      a.baseframe.scale=scale;a.baseframe.width=width
      a.menu_anchor.side=side;a.toolbar_side=vertical;a.menu_icons_size=size
      for n=1,6 do a.menu_icons[n]=n<=visible end
      a.title.text=visible==2 and "A much longer native title and encounter timer" or "Damage"
      layout(a);noOverlap(a)
      for n,key in ipairs({"modo_selecao","segmento","atributo","report","reset","fechar"})do
        local button=a.baseframe.cabecalho[key]
        assert(button:IsShown()==(n<=visible))
        if button:IsShown() then assert(button:GetWidth()==16*size,"lost native sizing") end
      end
      assert(a.baseframe.bg[4]==.75 and a.bgdisplay.bg[4]==0,"wrong effective background layering")
      assert(a.baseframe.titleBar.texture.color[1]==27/255 and a.baseframe.titleBar.texture.color[4]==1)
     end
    end
   end
  end
 end
end
-- Reconstruct native saved values in a fresh window, as a reload/profile does.
local restored=instance()
for _,key in ipairs({"menu_anchor","menu_anchor_down","menu_icons","menu_icons_size","toolbar_side","attribute_text"}) do restored[key]=copy(a[key]) end
restored.baseframe.scale=a.baseframe.scale;restored.baseframe.width=a.baseframe.width
layout(restored);noOverlap(restored)
assert(restored.menu_icons_size==a.menu_icons_size and restored.menu_anchor.side==a.menu_anchor.side,"profile reconstruction lost native geometry")
-- Native fade changes made while clipped become the latest restore value.
a.baseframe.width=90;a.menu_anchor.side=1;a.toolbar_side=1;a.menu_icons_size=1.4
for index=1,6 do a.menu_icons[index]=true end
layout(a);assert(a.title:GetAlpha()==0,"no-room title was auto-sized over controls")
a.title:SetAlpha(.6);P.Apply(a);assert(a.title:GetAlpha()==0)
a.baseframe.width=380;layout(a);assert(a.title:GetAlpha()==.6,"lost native alpha change while clipped")
a.title:SetAlpha(1)
layout(b);local bpoint={b.title:GetPoint(1)}
a.title.text="user text";a.attribute_text.text_face="user-font";a.attribute_text.text_size=17
layout(a);assert(a.title.text=="user text" and a.title.face=="user-font" and a.title.size==17)
assert(({b.title:GetPoint(1)})[2]==bpoint[2],"cross-window title ownership")
a.menu_anchor.side=1;a.toolbar_side=1;a.baseframe.width=380;layout(a)
local beforeObjects,beforeHooks,beforeWrites=objects,hooks,writes.title
for _=1,1000 do P.Apply(a) end
assert(objects==beforeObjects and hooks==beforeHooks and writes.title==beforeWrites,"warm refresh churn")
combat=true;Native(a.ToolbarMenuButtonsSize,a,.9);local savedWrites=writes.title;P.Apply(a)
assert(writes.title==savedWrites,"adapter changed combat layout")
combat=false;P.Apply(a);noOverlap(a)
a.skin="Minimalistic";Native(a.AttributeMenu,a);local point={a.title:GetPoint(1)};P.Apply(a)
assert(({a.title:GetPoint(1)})[2]==point[2],"switching away overwrote native title anchors")
print("PASS: native title/toolbar geometry across 432 configurations, native size/anchors, material RGBA, combat, independent windows and warm reuse")
local samples={}
a.skin="Addonskins EUI";layout(a)
local measuredObjects,measuredWrites=objects,writes.title
for trial=1,5 do local start=os.clock();for _=1,1000 do P.Apply(a)end;samples[trial]=(os.clock()-start)*1000 end
table.sort(samples)
print(("BENCH native source layout 1000 warm cosmetics median_ms=%.3f extra_hooks=%d frame_growth=%d title_geometry_writes=%d"):format(samples[3],hooks,objects-measuredObjects,writes.title-measuredWrites))
