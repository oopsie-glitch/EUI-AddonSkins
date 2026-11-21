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
function F:SetBackdrop(v) assert(native,"adapter rebuilt a native backdrop");self.backdrop=v end
function F:SetBackdropColor(...) self.bg={...} end
function F:GetBackdropColor() return table.unpack(self.bg or {0,0,0,.75}) end
function F:CreateTexture() return frame("Texture",self) end
function F:SetNormalTexture(v) self.normal:SetTexture(v) end
function F:SetHighlightTexture(v) self.highlight:SetTexture(v) end
function F:SetPushedTexture(v) self.pushed:SetTexture(v) end
function F:GetNormalTexture() return self.normal end
function F:GetHighlightTexture() return self.highlight end
function F:GetPushedTexture() return self.pushed end
local combat=false
InCombatLockdown=function() return combat end
issecretvalue=function(v) return type(v)=="table" and v.secret end
C_Timer={After=function() end} -- native AttributeMenu's deferred font/color only
C_AddOns={IsAddOnLoaded=function() return true end}
local registered={}
local media={Register=function(_,kind,name,path) registered[kind..":"..name]=path end,
    Fetch=function(_,kind,name) return registered[kind..":"..name] or name end}
LibStub=function() return media end
local D={skins={},instances={},loaded=true,CopyTable=copy,
    IsLoaded=function() return true end,GetAllInstances=function(self)return self.instances end,
    instance_skin_ignored_values={},StatusBar={Reset=function()end},ToolBar={Shown={}},
    SetFontFace=function(_,t,v)t.face=v end,SetFontSize=function(_,t,v)t.size=v end,
    SetFontColor=function(_,t,v)t.textColor=v end,SetFontOutline=function()end,
    Destroy=function(_,t)for k in pairs(t) do t[k]=nil end end,
    GetTitleBarFontString=function(self)return self.title end,
    IsLowerInstance=function()return false end,
}
_G.Details=D
local framework={IsAddonApocalypseWow=function()return false end,ParseColors=function(_,v)return table.unpack(v)end}
_G.DetailsFramework=framework
local rowtexts={Prepare=function()end,GetDefaultTexts=function()return {{font={}}}end}
-- Read the real native default table without running unrelated initializers.
local defaults=assert(read("include_instance.lua"):match("(_detalhes.instance_defaults = .*)"))
assert(load("local _detalhes,SharedMedia,Details222=...; "..defaults))(D,media,{RowTexts=rowtexts})
local function method(name,file)
    local body=assert((file or main):match("(function Details:"..name.."%s*%b().-)\nend"),name)
    local constants="local COORDS_LEFT_BALL_NO_ICON,COORDS_LEFT_CONNECTOR_NO_ICON,COORDS_LEFT_BALL,COORDS_LEFT_CONNECTOR,COORDS_RIGHT_BALL,COORDS_TOP_BACKGROUND,COORDS_BOTTOM_SIDE_BAR={0,1,0,1},{0,1,0,1},{0,1,0,1},{0,1,0,1},{0,1,0,1},{0,1,0,1},{0,1,0,1}\n"
    assert(load("local Details,gump,SharedMedia,Details222,detailsFramework,tbuttons=...; local unpack=unpack or table.unpack; "..constants..body.."\nend"))(D,{},media,{RowTexts=rowtexts,WindowSnap={RefreshGeometry=function()end}},framework,{})
end
for _,name in ipairs({"GetMenuAnchorPoint","ToolbarMenuButtonsSize","ToolbarMenuSetButtons","ToolbarMenuButtons","MenuAnchor","LeftMenuAnchorSide","RefreshAttributeTextSize","AttributeMenu","RefreshTitleBar","SetBackdropTexture"}) do method(name) end
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
local P=ns.CreateNativeDetailsPrototype({H=H,S={},module={}},function()end)
local look={texture="approved-bar",font="approved-font",bg={0,0,0,.75},
    header={r=27/255,g=27/255,b=27/255},headerAlpha=1,headerHeight=22,headerSize=11,
    titleColor={1,.7,.3,1},height=18,spacing=2,leftSize=11,rightSize=10}
P.Register(look)
local definition=assert(D.skins["Addonskins EUI"])
local base=D.skins.Minimalistic
assert(definition.icon_anchor_main[1]==base.icon_anchor_main[1] and definition.icon_anchor_plugins[2]==base.icon_anchor_plugins[2])
if not os.getenv("DETAILS_LAYOUT_REPRO") and not os.getenv("DETAILS_LAYOUT_BENCH") then
    assert(definition.instance_cprops.menu_anchor.side==base.instance_cprops.menu_anchor.side,"discarded coordinated native toolbar side")
    assert(definition.instance_cprops.attribute_text.anchor[1]==base.instance_cprops.attribute_text.anchor[1])
end
local function instance()
    local i=copy(definition.instance_cprops);setmetatable(i,{__index=D});i.skin="Addonskins EUI"
    i.baseframe=frame();i.baseframe.width=380;i.baseframe.height=180
    local f=i.baseframe;f.x=100;f.y=200;f.cabecalho={}
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
    return
end
if os.getenv("DETAILS_LAYOUT_REPRO") then
    -- Existing saved prototype profiles retain the old left-side setting.
    a.menu_anchor.side=1;layout(a);noOverlap(a);return
end
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
a.baseframe.width=90;a.menu_anchor.side=1;a.menu_icons_size=1.4
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
