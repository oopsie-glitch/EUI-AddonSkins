-- Spy Forever: native-shaped UI plus optional unmodified official constructors.
do
local timers, errors, looks, events = {}, {}, {}, {}
local priorEnum=Enum
local maskedSurfaces=os.getenv("SPY_MASKED_SURFACES")
if maskedSurfaces then Enum={UITextureSliceMode={Stretched="stretched"}} end
local combat, enabled, look, panelAlpha = false, true, "blizzard", 0.8
local rings, shells = {}, {}
tinsert=table.insert
tDeleteItem=function(t,item) for i=#t,1,-1 do if t[i]==item then table.remove(t,i) end end end
local counts = {objects=0, hooks=0, reads=0, alphaWrites=0, scans=0, geometry=0, paint=0, visibility=0}
local function pack(...) return {n=select("#",...), ...} end
local unpack=table.unpack or unpack
C_Timer={After=function(_,fn) timers[#timers+1]=fn end}
InCombatLockdown=function() return combat end
geterrorhandler=function() return function(err) errors[#errors+1]=err end end
issecretvalue=function(v) return type(v)=="table" and v.secret==true end
local function hook(obj,key,fn)
    local original=obj[key]
    obj[key]=function(...)
        local r=pack(original(...)); fn(...); return unpack(r,1,r.n)
    end
    counts.hooks=counts.hooks+1
end
hooksecurefunc=hook
local function flush()
    local round=0
    while #timers>0 do
        local batch=timers; timers={}
        for _,fn in ipairs(batch) do fn() end
        round=round+1; assert(round<30,"Spy refresh loop")
    end
end
CreateColor=function(r,g,b,a)
    local c={}
    function c:SetRGBA(r,g,b,a) self.r,self.g,self.b,self.a=r,g,b,a end
    c:SetRGBA(r,g,b,a);return c
end
local function frame(kind,parent)
    counts.objects=counts.objects+1
    local f={kind=kind or "Frame",parent=parent,children={},regions={},scripts={},hooks={},
        shown=true,alpha=1,level=parent and parent.level+1 or 3,width=200,height=16,
        color={1,1,1,1},text="",font={"native",11,""},points={}}
    if parent then parent.children[#parent.children+1]=f end
    function f:GetObjectType() return self.kind end
    function f:IsForbidden() return self.forbidden end
    function f:IsProtected() return self.protected or self.secure end
    function f:GetParent() return self.parent end
    function f:SetParent(parent)
        if self.parent==parent then return end
        if self.parent then
            local list=(self.kind=="Texture" or self.kind=="FontString" or self.kind=="MaskTexture") and self.parent.regions or self.parent.children
            for i=#list,1,-1 do if list[i]==self then table.remove(list,i) end end
        end
        self.parent=parent
        local list=(self.kind=="Texture" or self.kind=="FontString" or self.kind=="MaskTexture") and parent.regions or parent.children
        list[#list+1]=self
        counts.geometry=counts.geometry+1
    end
    function f:GetResizeBounds() return unpack(self.resizeBounds or {90,34,1200,1200}) end
    function f:SetResizeBounds(a,b,c,d) assert(not combat);self.resizeBounds={a,b,c,d};counts.geometry=counts.geometry+1 end
    function f:GetFrameLevel() return self.level end
    function f:SetFrameLevel(v) assert(not combat); self.level=v end
    function f:SetFrameStrata(v) self.strata=v end
    function f:GetFrameStrata() return self.strata or "MEDIUM" end
    function f:GetChildren() counts.reads=counts.reads+1; return unpack(self.children) end
    function f:GetRegions() counts.reads=counts.reads+1; return unpack(self.regions) end
    function f:GetNumChildren() return #self.children end
    function f:GetNumRegions() return #self.regions end
    function f:EnableMouse(v) self.mouse=v end
    function f:SetMouseMotionEnabled(v) self.motion=v end
    function f:SetAllPoints(v)
        self.allPoints=v
        self.points={{"TOPLEFT",v,"TOPLEFT",0,0},{"BOTTOMRIGHT",v,"BOTTOMRIGHT",0,0}}
        counts.geometry=counts.geometry+1
    end
    function f:SetPoint(...)
        local point={...}
        for i,old in ipairs(self.points) do
            if old[1]==point[1] then self.points[i]=point;counts.geometry=counts.geometry+1;return end
        end
        self.points[#self.points+1]=point;counts.geometry=counts.geometry+1
    end
    function f:ClearAllPoints() self.points={};self.allPoints=nil;counts.geometry=counts.geometry+1 end
    function f:SetHeight(v) self.height=v;counts.geometry=counts.geometry+1 end
    function f:SetWidth(v) self.width=v;self.autoWidth=false;counts.geometry=counts.geometry+1 end
    function f:SetSize(w,h) self.width,self.height=w,h;counts.geometry=counts.geometry+1 end
    function f:GetWidth()
        local a,b=self.points[1],self.points[2]
        if a and b and a[1]=="LEFT" and b[1]=="RIGHT" then
            return b[2]:GetLeft()+(b[4] or 0)-(a[2]:GetLeft()+(a[4] or 0))
        end
        if a and b and a[1]=="TOPLEFT" and b[1]=="BOTTOMRIGHT" and a[2]==b[2] then
            return a[2]:GetWidth()+(b[4] or 0)-(a[4] or 0)
        end
        return self.width
    end
    function f:GetHeight()
        local a,b=self.points[1],self.points[2]
        if a and b and a[1]=="TOPLEFT" and b[1]=="BOTTOMRIGHT" and a[2]==b[2] then
            return a[2]:GetHeight()+(a[5] or 0)-(b[5] or 0)
        end
        if a and b and a[1]=="TOPLEFT" and b[1]=="BOTTOMRIGHT" then
            local bottom=b[2]:GetTop()
            if b[3]:find("BOTTOM") then bottom=bottom-b[2]:GetHeight()
            elseif not b[3]:find("TOP") then bottom=bottom-b[2]:GetHeight()/2 end
            return self:GetTop()-bottom-(b[5] or 0)
        end
        return self.height
    end
    function f:SetMovable() end
    function f:SetScale(v) self.scale=v end
    function f:GetEffectiveScale() return self.effectiveScale or self.scale or 1 end
    function f:GetLeft()
        local p=self.points[1]
        if not p or type(p[2])~="table" then return self.left or 0 end
        local x=p[2]:GetLeft()
        if p[3]:find("RIGHT") then x=x+p[2]:GetWidth()
        elseif not p[3]:find("LEFT") then x=x+p[2]:GetWidth()/2 end
        x=x+(p[4] or 0)
        if p[1]:find("RIGHT") then x=x-self.width
        elseif not p[1]:find("LEFT") then x=x-self.width/2 end
        return x
    end
    function f:GetTop()
        local p=self.points[1]
        if not p or type(p[2])~="table" then return self.top or 100 end
        local y=p[2]:GetTop()
        if p[3]:find("BOTTOM") then y=y-p[2]:GetHeight()
        elseif not p[3]:find("TOP") then y=y-p[2]:GetHeight()/2 end
        y=y+(p[5] or 0)
        if p[1]:find("BOTTOM") then y=y+self.height
        elseif not p[1]:find("TOP") then y=y+self.height/2 end
        return y
    end
    function f:GetBottom() return self:GetTop()-self:GetHeight() end
    function f:GetRight() return self:GetLeft()+self:GetWidth() end
    function f:GetNumPoints() return #self.points end
    function f:GetPoint(i) return unpack(self.points[i] or {}) end
    function f:IsEnabled() return self.enabled~=false end
    function f:GetButtonState() return self.state or "NORMAL" end
    function f:SetButtonState(v) self.state=v end
    function f:FireScript(key,...)
        if key=="OnEnter" then self.mouseOver=true elseif key=="OnLeave" then self.mouseOver=false end
        if self.scripts[key] then self.scripts[key](self,...) end
        if self.hooks[key] then self.hooks[key](self,...) end
    end
    function f:GetAlpha() return self.alpha end
    function f:SetAlpha(v)
        assert(not combat,"cosmetic alpha write in combat")
        self.alpha=v; counts.alphaWrites=counts.alphaWrites+1
    end
    function f:Show() counts.visibility=counts.visibility+1; self.shown=true; if self.hooks.OnShow then self.hooks.OnShow(self) end end
    function f:Hide() counts.visibility=counts.visibility+1; self.shown=false; if self.hooks.OnHide then self.hooks.OnHide(self) end end
    function f:SetShown(shown) if shown then self:Show() else self:Hide() end end
    function f:IsShown() return self.shown end
    function f:IsVisible()
        local region=self
        while region do if not region.shown then return false end;region=region.parent end
        return true
    end
    function f:HookScript(key,fn)
        counts.hooks=counts.hooks+1
        local old=self.hooks[key]
        self.hooks[key]=function(...) if old then old(...) end; fn(...) end
    end
    function f:SetScript(key,fn) self.scripts[key]=fn end
    function f:HasScript() return true end
    function f:RegisterEvent(e) self.events=self.events or {};self.events[e]=true end
    function f:SetBackdrop(v) assert(not combat); self.backdrop=v end
    function f:GetBackdrop() return self.backdrop end
    function f:SetBackdropColor(...) self.fill={...} end
    function f:GetBackdropColor() return unpack(self.fill or {0,0,0,1}) end
    function f:SetBackdropBorderColor(...) self.border={...} end
    function f:GetBackdropBorderColor() return unpack(self.border or {1,0,0,1}) end
    function f:SetTexture(v) self.path=v end
    function f:SetAtlas(v) self.atlas=v end
    for setter,slot in pairs({SetNormalTexture="normal",SetPushedTexture="pushed",SetDisabledTexture="disabledTexture",SetHighlightTexture="highlight"}) do
        f[setter]=function(self,path)
            local texture=self[slot]
            if not texture then texture=frame("Texture");self[slot]=texture;self.regions[#self.regions+1]=texture end
            texture:SetTexture(path)
        end
    end
    function f:GetTexture() return self.path end
    function f:GetDrawLayer() return self.drawLayer or "ARTWORK" end
    function f:SetColorTexture(...) self.color={...};self.baseColor={...};counts.paint=counts.paint+1 end
    function f:SetVertexColor(...) self.color={...};self.vertexColor={...};counts.paint=counts.paint+1 end
    function f:SetBlendMode(mode) self.blend=mode end
    function f:SetGradient(direction,low,high)
        self.gradient={direction=direction,low={low.r,low.g,low.b,low.a},high={high.r,high.g,high.b,high.a}}
        counts.paint=counts.paint+1
    end
    function f:GetVertexColor() return unpack(self.color) end
    function f:SetHorizTile() end
    function f:SetVertTile() end
    function f:SetText(v) self.text=v; if self.autoWidth then self.width=self:GetStringWidth() end end
    function f:GetText() return self.text end
    function f:SetTextColor(...) self.textColor={...} end
    function f:GetTextColor() return unpack(self.textColor or {1,1,1,1}) end
    function f:SetFont(...) self.font={...} end
    function f:GetFont() return unpack(self.font) end
    function f:SetJustifyH(v) self.justify=v end
    function f:GetStringWidth() return #self.text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")*6 end
    function f:GetUnboundedStringWidth() return self:GetStringWidth() end
    function f:SetWordWrap(v) self.wordWrap=v end
    function f:GetWordWrap() return self.wordWrap or false end
    function f:SetNonSpaceWrap(v) self.nonSpaceWrap=v end
    function f:GetNonSpaceWrap() return self.nonSpaceWrap or false end
    function f:GetStringHeight()
        counts.metrics=(counts.metrics or 0)+1
        if self.pendingMetrics then return 0 end
        if self.metricHeight then return self.metricHeight end
        local line=self.font[2] or 12
        return line * (self.wordWrap and math.max(1,math.ceil(self:GetStringWidth()/self.width)) or 1)
    end
    function f:SetStatusBarTexture(v)
        if not self.texture then self.texture=frame("Texture"); self.texture.alpha=1 end
        self.texture.path=v
    end
    function f:GetStatusBarTexture() return self.texture end
    function f:SetStatusBarColor(...) self.statusColor={...} end
    function f:GetStatusBarColor() return unpack(self.statusColor or {0.5,0.5,0.5,1}) end
    function f:SetMinMaxValues(a,b) self.min,self.max=a,b end
    function f:SetValue(v) self.value=v end
    function f:CreateTexture(_,layer,_,sublevel)
        local t=frame("Texture");t.parent=self;t.drawLayer=layer;t.sublevel=sublevel; self.regions[#self.regions+1]=t; return t
    end
    if maskedSurfaces then
        function f:CreateMaskTexture()
            local mask=frame("MaskTexture");mask.parent=self;self.regions[#self.regions+1]=mask;return mask
        end
        function f:AddMaskTexture(mask) self.masks=self.masks or {};self.masks[mask]=true end
        function f:SetTextureSliceMargins(...) self.sliceMargins={...} end
        function f:SetTextureSliceMode(mode) self.sliceMode=mode end
    end
    function f:CreateFontString(_,layer)
        local t=frame("FontString");t.parent=self;t.autoWidth=true;t.drawLayer=layer or "OVERLAY";self.regions[#self.regions+1]=t;return t
    end
    function f:GetFontString() return self.label end
    function f:GetNormalTexture() return self.normal end
    function f:GetPushedTexture() return self.pushed end
    function f:GetDisabledTexture() return self.disabledTexture end
    function f:GetHighlightTexture() return self.highlight end
    if f.kind=="StatusBar" then f.SetVertexColor=nil;f.GetVertexColor=nil end
    return f
end
local function Coverage(texture)
    local alpha=texture.alpha*(texture.baseColor and texture.baseColor[4] or 1)
    if texture.gradient then alpha=alpha*texture.gradient.low[4]
    else alpha=alpha*(texture.vertexColor and texture.vertexColor[4] or 1) end
    local region=texture
    while region do
        if region.shown==false then return 0 end
        if region~=texture then alpha=alpha*(region.alpha or 1) end
        region=region.parent
    end
    return alpha
end
local function Composite(plate,grain)
    local a,b=Coverage(plate),Coverage(grain)
    return a+b*(1-a)
end
MouseIsOver=function(row) return row.mouseOver==true end
local function NativeRowScripts(row)
    row.unit={name="Fixture-Enemy"}
    row.scripts.OnEnter=function(self) self.nativeTooltip=true;self.nativeEnterCalls=(self.nativeEnterCalls or 0)+1;if Spy.ShowTooltip then Spy:ShowTooltip(self,true) end end
    row.scripts.OnLeave=function(self) self.nativeTooltip=false;self.nativeLeaveCalls=(self.nativeLeaveCalls or 0)+1;if Spy.ShowTooltip then Spy:ShowTooltip(self,false) end end
end
CreateFrame=function(kind,name,parent,template)
    local f=frame(kind,parent);f.name=name;f.secure=template=="SpySecureActionButtonTemplate"
    if f.secure then NativeRowScripts(f) end
    if name then _G[name]=f end
    if not parent then events[#events+1]=f end
    return f
end
UIParent=frame()
TargetFrame={Update=function() end}
local dialog={OpenFrames={},FeedGroup=function() end,SetDefaultSize=function() end}
local registry={tables={},RegisterOptionsTable=function(self,id,t) self.tables[id]=t end}
function dialog:Open(id) self.lastOpen=id end
local locale=setmetatable({},{__index=function(_,k)return k end})
local media={MediaType={STATUSBAR="statusbar"},Fetch=function(_,_,v) return v or "flat" end}
LibStub=setmetatable({GetLibrary=function() return media end},{__call=function(_,name)
    if name=="AceConfigDialog-3.0" then return dialog end
    if name=="AceConfigRegistry-3.0" then return registry end
    if name=="AceLocale-3.0" then return {GetLocale=function() return locale end} end
    return {}
end})
local ns={IsEnabled=function(module)
    if module and module.skin and module.skin.IsEnabled then return module.skin.IsEnabled() end
    return enabled
end,AttachAccent=function(_,f) f.accent=true end}
local module
ns.RegisterModule=function(_,_,_,install) module={install=install} end
local menuBinding
ns.BindPopupOwner=function(S,m,owner,options) menuBinding={module=m,owner=owner,options=options} end
ns.RefreshPopupMenusNow=function() end
ns.StyleTextureDialog=function(_,_,popup,active) popup.skinActive=active end
local S={OnLooksChanged=function(fn) looks[#looks+1]=fn end,
    GetPanelColor=function() return 0.04,0.04,0.04,panelAlpha end}
function S.Shell(f,opts)
    f.standardShell=true;f.shellOptions=opts;shells[f]=true
    -- Native-shaped EUI shell textures: inherited frame alpha must exclude all.
    f.shellAtlas=f:CreateTexture();f.shellAtlas:SetTexture("modern_blizz.png")
    f.shellOverlay=f:CreateTexture();f.shellOverlay:SetColorTexture(0,0,0,0.62)
    f.shellFlat=f:CreateTexture();f.shellFlat:SetColorTexture(0.04,0.04,0.04,0.92)
end
function S.CloseButton(f)
    if f.close then return end
    f.close=true
    for _,setter in ipairs({"SetNormalTexture","SetPushedTexture","SetDisabledTexture","SetHighlightTexture"}) do f[setter](f,"") end
    local x=f:CreateTexture();x:SetAtlas("uitools-icon-close");x:SetSize(14,14);x:SetPoint("CENTER",-2,0)
    f.standardGlyph=x
end
function S.PageButton(f,glyph)
    if f.glyph then return end
    f.glyph=glyph
    for _,texture in ipairs({f.normal,f.pushed,f.highlight}) do texture.alpha=0 end
    f.standardFill=f:CreateTexture();f.standardFill:SetColorTexture(0.04,0.04,0.04,0.8)
    f.standardGlyph=f:CreateTexture();f.standardGlyph:SetTexture(glyph=="<" and "left" or "right")
    f.standardGlyph:SetSize(14,14)
    f.standardBorder=frame("Frame",f)
    for i=1,4 do
        local edge=f.standardBorder:CreateTexture(nil,"BORDER")
        edge:SetSize(1,16);edge:SetColorTexture(0.055,0.055,0.055,1)
    end
end
local euiFont={"EUI",11,""}
function S.Font(f,r,g,b) f.font={table.unpack(euiFont)};f:SetTextColor(r or 1,g or 1,b or 1,1) end
function S.Button(f) f.button=true end
function S.EditBox() end
function S.Checkbox() end
function S.ScrollBar() end
function S.Dropdown() end
function S.FadeNineSlice() end
function S.StateButtonLabel() end
function S.ApplyBarFill() error("secure row discovered by generic scan") end
EllesmereUI={IS_FOREVER=true,GetActiveProfileData=function() return look end,
    ProfileWindowSkinLook=function(p) return p end,
    ForeverBorder=function(host)
        local edge=host:CreateTexture();local r={on=true,host=host,edge=edge};rings[host]=r;return r
    end,
    ForeverBorderSeat=function() end,
    ForeverBorderShown=function(r,v) r.on=v end,
    ForeverBorderPaint=function(r,...) r.color={...} end}
-- Public Heavy Bronze API; the host fixture models one rim object, not its
-- real eight pieces/masks/internal layout frame (source costs documented).
if not os.getenv("SPY_SLIM_BORDER") then
    EllesmereUI.ForeverHeavyOK=function() return true end
    EllesmereUI.ForeverHeavy=function(host,layer,sub)
        local rim=EllesmereUI.ForeverBorder(host,layer,sub)
        rim.heavy=true;return rim
    end
    EllesmereUI.ForeverHeavySeat=EllesmereUI.ForeverBorderSeat
    EllesmereUI.ForeverHeavyShown=EllesmereUI.ForeverBorderShown
end
local bootOpacity=tonumber(os.getenv("SPY_BOOT_OPACITY"))
EUIAddonSkinsDB={spy={style="auto",opacity=bootOpacity},other={preserved=true}}
SlashCmdList={}
local colors={
    Class={DRUID={r=1,g=0.49,b=0.04,a=1},PALADIN={r=0.96,g=0.55,b=0.73,a=1},
        SHAMAN={r=0,g=0.44,b=0.87,a=1},HUNTER={r=0.67,g=0.83,b=0.45,a=1},ROGUE={r=1,g=0.96,b=0.41,a=1}},
    Window={Title={r=1,g=1,b=1,a=1},Background={r=0,g=0,b=0,a=1},["Title Text"]={r=1,g=1,b=1,a=1}},
    Bar={["Bar Text"]={r=1,g=1,b=1,a=1}},
    Alert={["KOS Border"]={r=0.9,g=0.1,b=0.05,a=1},Background={r=0,g=0,b=0,a=1},Icon={r=1,g=1,b=1,a=1},["KOS Text"]={r=1,g=0.1,b=0.1,a=1},["Name Text"]={r=1,g=1,b=1,a=1}},
}
Spy={db={profile={MainWindow={RowHeight=16,RowSpacing=1,TextHeight=12,Alpha=1,AlphaBG=1},Colors=colors}},
    Colors={},CreateMainWindow=function() end,CreateFrame=function(_,name)
        local f=frame(); _G[name]=f;return f,nil,"native-tail" end,
    SetFontSize=function(_,f,size) f.font[2]=size end,AddFontString=function() end,
    SetCurrentList=function(_,list) return list,nil,"list-tail" end,
    AlertWatch=function(self) self.AlertWindow:SetBackdropBorderColor(0.6,0.2,0.8,1);return "native-watch" end,
    SetKOSReason=function() StaticPopup1.which="Spy_SetKOSReasonOther";StaticPopup1.shown=true;return "native-reason" end,
    ShowAlert=function(self) self.AlertWindow:SetBackdropBorderColor(0.9,0.1,0.05,1);self.AlertWindow.Title:SetTextColor(1,0.1,0.1,1);return "native-alert" end,BarDropDownOpen=function() end}
local function makeRow(index)
    local row=frame("Button",Spy.MainWindow);row.secure=true;row.id=index;NativeRowScripts(row)
    row:SetPoint("TOPLEFT",Spy.MainWindow,"TOPLEFT",2,-34-17*(index-1))
    row:SetSize(Spy.MainWindow:GetWidth()-4,16)
    row.StatusBar=frame("StatusBar",row);row.StatusBar:SetAllPoints(row);row.StatusBar:SetStatusBarTexture("native")
    row.LeftText=row.StatusBar:CreateFontString();row.RightText=row.StatusBar:CreateFontString()
    row.LeftText:SetPoint("LEFT",row.StatusBar,"LEFT",2,0);row.RightText:SetPoint("RIGHT",row.StatusBar,"RIGHT",-2,0)
    row.attributes={type1="macro",macrotext="/target Enemy"};row.scripts.OnClick=function()return "target" end
    Spy.MainWindow.Rows[index]=row;return row
end
function Spy:CreateRow(i) if not self.MainWindow.Rows[i] then return makeRow(i) end end
function Spy:SetBar(i,name,desc,value,group,class,_,opacity)
    local row=self.MainWindow.Rows[i]; if not row then return end
    row.LeftText:SetText(name);row.RightText:SetText(desc)
    row.LeftText:SetWidth(row:GetWidth()-row.RightText:GetStringWidth()-4)
    row.StatusBar:SetValue(value)
    local c=group=="Class" and colors.Class[class] or {r=1,g=0,b=0}
    row.StatusBar:SetStatusBarColor(c.r,c.g,c.b,opacity)
    return "native-setbar",nil,i
end
-- Optional exact upstream source, downloaded only on the cloud runner.
local source=os.getenv("SPY_SOURCE")
Spy.ShowTooltip=function(_,row,show) return "native-tooltip",nil,show end
Spy.ButtonName={}
SpyPerCharDB={PlayerData={},KOSData={}}
colors.Tooltip={["Title Text"]={r=1,g=1,b=1,a=1}}
GameTooltip={SetOwner=function(self,owner) self.owner=owner end,
    SetPoint=function() end,ClearLines=function() end,AddLine=function() end,
    Show=function(self) self.shown=true end,Hide=function(self) self.shown=false end}
if source then
    assert(loadfile(source.."/Colors.lua"))()
    assert(loadfile(source.."/Widgets.lua"))()
    assert(loadfile(source.."/MainWindow.lua"))()
    -- The exact-source mode exercises row construction/paint; menu dispatch
    -- remains source-shaped to avoid opening Blizzard UI in the host fixture.
    Spy.BarDropDownOpen=function() end
end
if os.getenv("SPY_HOVER_FALLBACK") then Spy.ShowTooltip=nil end
Spy.MainWindow=frame();Spy.MainWindow.Rows={};Spy.MainWindow.protected=true
_G.Spy_MainWindow=Spy.MainWindow
Spy.MainWindow.Background=Spy.MainWindow:CreateTexture()
Spy.MainWindow.TitleBar=frame("Frame",Spy.MainWindow)
Spy.MainWindow.TitleBar:SetBackdrop({bgFile="native-opaque-title"})
Spy.MainWindow.TitleBar:SetBackdropColor(0,0,0,1)
Spy.MainWindow.Title=Spy.MainWindow:CreateFontString()
Spy.MainWindow.Title:SetText("Kill On Sight")
Spy.MainWindow.Title.left=8;Spy.MainWindow.Title.width=121
Spy.MainWindow.Title:SetPoint("TOPLEFT",Spy.MainWindow,"TOPLEFT",8,-16)
Spy.MainWindow.TitleClick=frame("Frame",Spy.MainWindow)
Spy.MainWindow.TitleClick:SetAllPoints(Spy.MainWindow.Title)
Spy.MainWindow.TitleClick.width=121
for _,key in ipairs({"CloseButton","LeftButton","RightButton","ClearButton","StatsButton","CountButton"}) do
    local b=frame("Button",Spy.MainWindow)
    b.normal=frame("Texture");b.pushed=frame("Texture");b.highlight=frame("Texture")
    b.width=key=="CloseButton" and 20 or 16
    b.height=(key=="StatsButton" or key=="CountButton") and 12 or b.width
    b.regions={b.normal,b.pushed,b.highlight}
    b.normal.path="native-"..key;b.pushed.path="pressed-"..key
    b.scripts.OnEnter=function(self) self.tooltipCalls=(self.tooltipCalls or 0)+1 end
    b.scripts.OnClick=function() return key end
    Spy.MainWindow[key]=b
end
Spy.AlertWindow=frame();Spy.AlertWindow.Icon=frame("Frame",Spy.AlertWindow)
Spy.AlertWindow.Title=Spy.AlertWindow:CreateFontString();Spy.AlertWindow.Name=Spy.AlertWindow:CreateFontString()
Spy.AlertWindow.Location=Spy.AlertWindow:CreateFontString()
SpyStatsFrame=frame();SpyStatsFrameTopCloseButton=frame("Button",SpyStatsFrame)
Spy.optionsFrames={}
Spy.db.profile.ResizeSpyLimit=40;Spy.ListAmountDisplayed=2;Spy.MainWindow.height=90
Spy.MainWindow.CountFrame=frame("Frame",Spy.MainWindow)
Spy.MainWindow.CountFrame.Text=Spy.MainWindow.CountFrame:CreateFontString()
Spy.MainWindow.CountFrame.Text.autoWidth=true
Spy.MainWindow.CountFrame.Text:SetText("|cFF0070DE0|r")
Spy.MainWindow.CountFrame.Text:SetPoint("RIGHT",Spy.MainWindow.StatsButton,"LEFT",-4,0)
Spy.MainWindow.CountButton.alpha=0
local function NativeHeaderLayout(w)
    Spy.MainWindow.width=w
    local f=Spy.MainWindow
    f.CloseButton.left=w-4-f.CloseButton.width
    f.RightButton.left=w-23-f.RightButton.width
    f.LeftButton.left=f.RightButton.left-f.LeftButton.width
    f.ClearButton.left=f.LeftButton.left-f.ClearButton.width
    f.StatsButton.left=f.ClearButton.left-4-f.StatsButton.width
    f.CountButton.left=f.StatsButton.left-4-f.CountButton.width
end
NativeHeaderLayout(200)
Spy.MainWindow.CloseButton:SetPoint("TOPRIGHT",Spy.MainWindow,"TOPRIGHT",-4,-12)
Spy.MainWindow.RightButton:SetPoint("TOPRIGHT",Spy.MainWindow,"TOPRIGHT",-23,-14.5)
Spy.MainWindow.LeftButton:SetPoint("RIGHT",Spy.MainWindow.RightButton,"LEFT",0,0)
Spy.MainWindow.ClearButton:SetPoint("RIGHT",Spy.MainWindow.LeftButton,"LEFT",0,0)
Spy.MainWindow.StatsButton:SetPoint("RIGHT",Spy.MainWindow.ClearButton,"LEFT",-4,0)
Spy.MainWindow.CountButton:SetPoint("RIGHT",Spy.MainWindow.StatsButton,"LEFT",-4,0)
Spy.ResizeMainWindow=Spy.ResizeMainWindow or function()
    Spy.MainWindow.Title:SetWidth(Spy.MainWindow.width-79)
    return "native-resize",nil,5
end
Spy.SetBarTextures=Spy.SetBarTextures or function(self,path)
    self.db.profile.BarTexture=path
    for _,row in pairs(self.MainWindow.Rows) do row.StatusBar:SetStatusBarTexture(path) end
end
Spy.UpdateBarTextures=Spy.UpdateBarTextures or function(self) self:SetBarTextures(self.db.profile.BarTexture) end
local firstOpeningEntries={}
UIDropDownMenu_AddButton=function(info) firstOpeningEntries[#firstOpeningEntries+1]=info end
Spy_CreateBarDropdown=function() return "native-first-menu",nil,7 end
Spy.BarDropDownOpen=function(self)
    if self.testFirstMenu then
        Spy_BarDropDownMenu={initialize=Spy_CreateBarDropdown}
        return Spy_BarDropDownMenu.initialize({},1)
    end
end
StaticPopup1=frame();StaticPopup1.shown=false
Spy:CreateRow(1)
local row=Spy.MainWindow.Rows[1]
row.attributes={type1="macro",macrotext="/target Enemy"}
row.scripts.OnClick=function()return "target" end
local nativePostClick=function()return "native-port-postclick" end
row.scripts.PostClick=nativePostClick
local originalEnter,originalLeave=row.scripts.OnEnter,row.scripts.OnLeave
local nativeTooltipFunction=Spy.ShowTooltip
local tooltipReturns=nativeTooltipFunction and pack(Spy:ShowTooltip(row,false))
local rawSetBar=Spy.SetBar
Spy:SetBar(1,"A very long player name","60 Druid",100,"Class","DRUID",nil,1)
local textWidth=row.LeftText.width
local nativeLeft,nativeRight=row.LeftText:GetLeft(),row.RightText:GetRight()
local nativeRowPoint={row:GetPoint(1)}
local oldSetBarResult=pack(Spy:SetBar(1,"Player","60 Druid",100,"Class","DRUID",nil,1))
assert(loadfile("EUIAddonSkins/Widgets.lua"))("EUIAddonSkins",ns)
local realScan=ns.CreateSkinHelper
ns.CreateSkinHelper=function(...)
    local h=realScan(...)
    local scan=h.Scan;h.Scan=function(...)counts.scans=counts.scans+1;return scan(...)end
    return h
end
assert(loadfile("EUIAddonSkins/Skins/Spy.lua"))("EUIAddonSkins",ns)
module.install(S,module);flush()
Spy.testFirstMenu=true
local firstA,firstB,firstC=Spy:BarDropDownOpen()
assert(firstA=="native-first-menu" and firstB==nil and firstC==7 and #firstOpeningEntries==1,"first menu opening lost submenu/returns")
Spy.testFirstMenu=false
local initialObjects=counts.objects
assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==1,"Standard fill changed")
assert(Spy.MainWindow.LeftButton.glyph=="<" and Spy.MainWindow.CloseButton.close)
assert(SLASH_EUISPYSKIN1=="/euispy")
SlashCmdList.EUISPYSKIN()
local settings=registry.tables.EUIAddonSkinsSpy
assert(settings and dialog.lastOpen=="EUIAddonSkinsSpy")
local style=settings.args.style
assert(settings.args.opacity.get()==math.floor((bootOpacity or 0.75)*100+0.5),"saved/default opacity was overwritten")
local statsColour=frame("Frame",SpyStatsFrame)
local classLabel=statsColour:CreateFontString()
classLabel:SetTextColor(0.2,0.4,0.9,0.6)
style.set(nil,"forever");flush()
assert(classLabel:GetTextColor()==0.2 and classLabel.textColor[4]==0.6,"statistics semantic label colour lost")
assert(style.get()=="forever" and EUIAddonSkinsDB.other.preserved)
assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==1,"skin changed native class fill alpha")
assert(Spy.MainWindow.Background:GetAlpha()==0,"native background stacks under transparency")
assert(row.StatusBar.statusColor[1]==1 and row.StatusBar.statusColor[2]==0.49,"class identity changed")
assert(row.LeftText:GetText()=="Player" and row.RightText:GetText()=="60 Druid")
assert(row.attributes.macrotext=="/target Enemy" and row.scripts.OnClick()=="target")
assert(row.scripts.PostClick==nativePostClick and row.scripts.PostClick()=="native-port-postclick")
assert(Spy.MainWindow.StatsButton.scripts.OnClick()=="StatsButton")
assert(Spy.MainWindow.StatsButton.width==16 and Spy.MainWindow.StatsButton.height==12,"native header hitbox changed")
local function RowChrome(row)
    for _,host in ipairs(Spy.MainWindow.children) do
        if host.points[1] and host.points[1][2]==row and (#host.regions==1) and host.mouse==false then return host end
    end
end
local chrome=assert(RowChrome(row),"contained row frame missing")
assert(chrome:GetFrameLevel()<row.StatusBar:GetFrameLevel(),"row frame can cover player text")
assert(row.StatusBar.allPoints==row and row.StatusBar:GetWidth()==row:GetWidth()
    and row.StatusBar:GetHeight()==row:GetHeight(),"Forever changed native list geometry")
assert(row.LeftText:GetLeft()==nativeLeft and row.RightText:GetRight()==nativeRight,"Forever moved native row columns")
assert(row.points[1][2]==nativeRowPoint[2] and row.points[1][4]==nativeRowPoint[4]
    and row.points[1][5]==-30,"first row did not follow the compact header")
assert(row.LeftText.points[1][2]==row.StatusBar and #row.LeftText.points==1,"native name anchors changed")
for _,button in ipairs({Spy.MainWindow.LeftButton,Spy.MainWindow.RightButton}) do
    for _,edge in ipairs(button.standardBorder.regions) do assert(edge.baseColor[4]==0,"native helper border leaked into Forever") end
end
local function AssertRestingRule(nativeRow)
    local owner=assert(RowChrome(nativeRow),"compact separator missing")
    local rule=owner.regions[1]
    local c=rule.baseColor
    assert(c and c[1]==0.49 and c[2]==0.33 and c[3]==0.18 and c[4]==0.24
        and not rule.gradient and not rule.vertexColor,"first-visible row lacks resting bronze paint")
    assert(owner.allPoints==nativeRow and rule.height==1 and #nativeRow.StatusBar.regions==2,
        "compact separator changed native bar geometry or attached decoration")
    return rule
end
assert(row.scripts.OnEnter==originalEnter and row.scripts.OnLeave==originalLeave,"native hover handlers replaced")
row:Show()
local rule=AssertRestingRule(row)
assert(not row.nativeEnterCalls and not row.nativeTooltip,"first visibility fixture already hovered")
assert(Coverage(rule)>0,"initial resting bevel is not visible")
local nativeColor={table.unpack(row.StatusBar.statusColor)}
row:FireScript("OnEnter")
assert(row.nativeTooltip and rule.baseColor[1]==0.73,"native hover did not highlight bronze frame")
if nativeTooltipFunction then
    assert(not row.hooks.OnEnter and not row.hooks.OnLeave,"shared native hover still adds per-row hooks")
    local foreign={id=99,unit={name="Foreign"}}
    local foreignPaint=counts.paint
    Spy:ShowTooltip(foreign,false)
    assert(counts.paint==foreignPaint,"foreign tooltip repainted Spy rows")
    local result=pack(Spy:ShowTooltip(row,false))
    assert(result.n==tooltipReturns.n,"tooltip return count changed")
    for i=1,result.n do assert(result[i]==tooltipReturns[i],"tooltip returns changed") end
    row:FireScript("OnEnter")
else
    assert(row.hooks.OnEnter and row.hooks.OnLeave,"missing shared-method fallback")
end
local hoverPaint=counts.paint
row:FireScript("OnEnter")
assert(counts.paint==hoverPaint,"duplicate hover repainted")
row:FireScript("OnLeave")
assert(not row.nativeTooltip and rule.baseColor[1]==0.49,"native leave did not restore row bevel")
for i=1,4 do assert(row.StatusBar.statusColor[i]==nativeColor[i],"hover changed meaningful class/status colour") end
row:Hide();assert(chrome.alpha==0 and Coverage(rule)==0,"hidden row retained rendered bevel")
row:Show()
Spy.MainWindow:Hide()
assert(Coverage(rule)==0,"closed window left row bevels visible")
Spy.MainWindow:Show()
assert(Coverage(AssertRestingRule(row))>0,"reopen required hover to restore resting bevel")
flush()
local stableHoverObjects,stableHoverHooks=counts.objects,counts.hooks
for i=1,1000 do row:FireScript("OnEnter");row:FireScript("OnLeave") end
assert(counts.objects==stableHoverObjects and counts.hooks==stableHoverHooks,"hover accumulated artwork/hooks")
rawSetBar(Spy,1,"Unknown","?? Unknown",0,nil,nil,nil,0.6)
local unknownColor={table.unpack(row.StatusBar.statusColor)}
row:FireScript("OnEnter");row:FireScript("OnLeave")
assert(row.RightText:GetText()=="?? Unknown" and row.StatusBar.value==0,"unknown player state changed")
for i=1,4 do assert(row.StatusBar.statusColor[i]==unknownColor[i],"unknown/status colour was invented") end
Spy:SetBar(1,"Player","60 Druid",100,"Class","DRUID",nil,1)
local function Control(button)
    for host,rim in pairs(rings) do
        if host.parent and host.parent.parent==button then return {host=host,seat=host.parent,rim=rim,icon=host.regions[1],fill=host.regions[2]} end
    end
end
local close=assert(Control(Spy.MainWindow.CloseButton))
assert(close.host.scale==0.5 and close.icon.color[1]==0.91)
assert(Spy.MainWindow.CloseButton.standardGlyph.alpha==0,"EUI X stacked beneath Forever icon")
assert(Spy.MainWindow.LeftButton.standardFill.alpha==0 and Spy.MainWindow.LeftButton.standardGlyph.alpha==0,"EUI page block/glyph not suppressed")
assert(Spy.SetBar==rawSetBar,"skin still hooks native per-player bar paint")
if bootOpacity then
    local backgrounds=0
    for host in pairs(rings) do
        if host.parent==Spy.MainWindow then
        for _,region in ipairs(host.regions) do
            if region.drawLayer=="BACKGROUND" and region.sublevel==1 and region.gradient then
                local grain
                for _,candidate in ipairs(host.regions) do
                    if candidate.drawLayer=="BACKGROUND" and candidate.sublevel==2 then grain=candidate end
                end
                if grain then
                    assert(math.abs(Composite(region,grain)-bootOpacity)<0.0001,"fresh bootstrap lost saved opacity")
                    backgrounds=backgrounds+1
                end
            end
        end
    end
    end
    assert(backgrounds==1,"fresh list background missing")
    assert(EUIAddonSkinsDB.spy.opacity==bootOpacity,"bootstrap overwrote saved endpoint")
    EUIAddonSkinsDB.spy.opacity=nil
    module.refresh();flush()
end
local nextResult=pack(Spy:SetBar(1,"A very long player name","60 Druid",100,"Class","DRUID",nil,1))
assert(nextResult.n==oldSetBarResult.n)
for i=1,nextResult.n do assert(nextResult[i]==oldSetBarResult[i]) end
assert(row.LeftText.width==textWidth,"native truncation changed")
row.width=90
Spy:SetBar(1,"A very long player name","60 Druid",100,"Class","DRUID",nil,1)
assert(row.LeftText.width==90-row.RightText:GetStringWidth()-4)

-- The native selected bar texture, including its region alpha, stays authoritative.
Spy:SetBarTextures("player-selected-grain")
local barTexture=row.StatusBar:GetStatusBarTexture()
barTexture:SetAlpha(0.73)
local textureAlphaWrites=counts.alphaWrites
for i=1,50 do Spy:SetBar(1,"Player","60 Druid",100,"Class","DRUID",nil,0.6) end
module.refresh();flush()
assert(barTexture:GetTexture()=="player-selected-grain" and barTexture:GetAlpha()==0.73,"native texture appearance overridden")
Spy:SetBarTextures("player-selected-flat")
assert(row.StatusBar:GetStatusBarTexture():GetTexture()=="player-selected-flat" and #timers==0,"native texture selector delayed by skin")
local profile=Spy.db.profile
Spy.db.profile.BarTexture="saved-profile-texture";Spy:UpdateBarTextures()
assert(row.StatusBar:GetStatusBarTexture():GetTexture()=="saved-profile-texture")
style.set(nil,"standard");flush();style.set(nil,"forever");flush()
assert(row.StatusBar:GetStatusBarTexture():GetTexture()=="saved-profile-texture" and barTexture:GetAlpha()==0.73,"theme switch rewrote selected texture")
Spy.MainWindow:Hide();Spy.MainWindow:Show();flush()
assert(barTexture:GetTexture()=="saved-profile-texture" and barTexture:GetAlpha()==0.73)
barTexture:SetAlpha(1)
-- One integrated header at normal widths; responsive safety wrap at minimum.
for _,width in ipairs({90,130,160,200,240,300}) do
    NativeHeaderLayout(width)
    Spy:ResizeMainWindow();flush()
    for _,label in ipairs({"Nearby","Last Hour","Kill On Sight"}) do
    for _,value in ipairs({0,7,123}) do
        local f=Spy.MainWindow
        f.CountFrame.Text:SetText("|cFF0070DE"..value.."|r")
        f.Title:SetText(label)
        local title,counter=f.Title,f.CountFrame.Text
        local unified=title.points[1][5]==f.CloseButton.points[1][5]
        if width>=200 then assert(unified,"header did not integrate at normal width") end
        if width<=130 then assert(not unified,"narrow header lost safety wrap") end
        assert(title:GetText()==label and title:GetWidth()>0,"native title changed/vanished")
        assert(f:GetWidth()==width and f:GetHeight()==90,"skin resized native window")
        if unified then
            assert(not title:GetWordWrap(),"single-line header wrapped title")
            assert(math.abs(title:GetTop()-title:GetHeight()/2-(f:GetTop()-14))<0.001,"title not centered in unified header")
            assert(title:GetRight()+6<=f.StatsButton:GetLeft(),"title/control overlap")
            assert(f.CloseButton:GetRight()+6<=f.CountButton:GetLeft(),"control/counter hitboxes overlap")
        else
            assert(title:GetBottom()>f.CloseButton:GetTop(),"wrapped header overlaps controls")
            assert(title:GetRight()+6<=counter:GetLeft(),"wrapped title/counter overlap")
        end
        local prior,gap
        for _,key in ipairs({"StatsButton","ClearButton","LeftButton","RightButton","CloseButton"}) do
            local button=f[key]
            assert(button:GetLeft()>=3 and button:GetRight()<=width-3,"header outside native width")
            if prior then
                local nextGap=button:GetLeft()-prior:GetRight()
                assert(nextGap>=0 and nextGap<=2,"control spacing is not compact")
                if gap then assert(math.abs(nextGap-gap)<0.001,"inconsistent control gaps") end
                gap=nextGap
            end
            assert(button.scripts.OnClick()==key,"native click changed")
            assert(button:GetHeight()==(key=="StatsButton" and 12 or key=="CloseButton" and 20 or 16),"header hitbox changed")
            prior=button
        end
        assert(row.StatusBar:GetWidth()==row:GetWidth() and select(1,f:GetResizeBounds())==90,"Forever changed native row width or resize limits")
    end
    end
end
NativeHeaderLayout(200);Spy:ResizeMainWindow();flush()
local title=Spy.MainWindow.Title
local counter=Spy.MainWindow.CountFrame.Text
for _,label in ipairs({"Nearby","Last Hour","Ignore","Kill On Sight","A localized title requiring more space"}) do
    title:SetText(label)
    assert(title.points[1][5]==-14 and not title:GetWordWrap(),"dynamic title rebuilt separate toolbar")
end
title:SetText("Kill On Sight")
counter:SetText("|cFF0070DE123|r")
assert(title:GetRight()+6<=Spy.MainWindow.StatsButton:GetLeft(),"dynamic title overlaps controls")
counter:Hide();counter:Show()
assert(Spy.MainWindow.CloseButton:GetRight()+6<=Spy.MainWindow.CountButton:GetLeft(),"counter toggle overlaps hitbox")
local g,o,h,r,w,p,v=counts.geometry,counts.objects,counts.hooks,counts.reads,counts.alphaWrites,counts.paint,counts.visibility
for i=1,1000 do title:SetText("Kill On Sight");counter:SetText("|cFF0070DE123|r") end
assert(counts.geometry==g and counts.objects==o and counts.hooks==h and counts.reads==r and counts.alphaWrites==w and counts.paint==p and counts.visibility==v and #timers==0,"warm header state repainted/rediscovered")
print("BENCH Spy header: 1000 unchanged title/counter pairs: geometry/alpha/paint/visibility writes, new UI objects/hooks, hierarchy reads and queued refreshes=0")
counter:SetText("|cFF0070DE0|r")
local main=Spy.MainWindow
local rowHeight=row:GetHeight()
local function ScaleEvent()
    for _,f in ipairs(events) do
        if f.events and f.events.UI_SCALE_CHANGED then f.scripts.OnEvent(f,"UI_SCALE_CHANGED") end
    end
end
assert(title.points[1][5]==-14 and row.points[1][5]==-30,"20-unit control plus 4-unit padding did not produce 28-unit header")
main.effectiveScale=0.73;ScaleEvent()
local snapped=math.ceil(28*0.73)/0.73
assert(math.abs(title.points[1][5]+snapped/2)<0.0001 and math.abs(row.points[1][5]+snapped+2)<0.0001,
    "fractional-scale header was not rounded up with list attached")
main.effectiveScale=nil;ScaleEvent()
local font,size,flags=title:GetFont()
title:SetFont(font,22,flags)
assert(title.points[1][5]==-15 and row.points[1][5]==-32,"larger title did not grow header")
counter:SetFont(font,23,flags)
assert(title.points[1][5]==-15.5 and row.points[1][5]==-33,"counter did not grow header")
title:SetFont(font,30,flags)
assert(row.points[1][5]==-34 and main:GetHeight()==90 and row:GetHeight()==rowHeight,
    "large header changed native dimensions or capacity")
counter:SetFont(font,12,flags)
title.pendingMetrics=true
title:SetFont(font,21,flags)
assert(row.points[1][5]==-31,"unavailable metric lacked safe font fallback")
title.pendingMetrics=false;title.metricHeight=24
main:Hide();main:Show();flush()
assert(row.points[1][5]==-34,"first show failed to recover pending metrics")
title.metricHeight=nil
title:SetFont(font,size,flags)
assert(row.points[1][5]==-30,"return to compact metrics did not lift list")
local metricReads=counts.metrics
for i=1,1000 do counter:SetText(tostring(i));title:SetText("Kill On Sight") end
assert(counts.metrics==metricReads,"warm counter values repeated font-height measurement")
counter:SetText("|cFF0070DE0|r")
local b=Spy.MainWindow.ClearButton
local art=Control(b)
local callback=b.scripts.OnClick
b:FireScript("OnEnter");assert(b.tooltipCalls==1 and art.fill.color[1]==0.12)
b:FireScript("OnMouseDown");assert(art.fill.color[1]==0.035 and art.icon.points[1][5]==-2)
b:FireScript("OnMouseUp");assert(art.fill.color[1]==0.12)
b:FireScript("OnLeave");assert(art.fill.color[1]==0.065)
b.enabled=false;b:FireScript("OnDisable");assert(art.icon.color[4]==0.55)
b.enabled=true;b:FireScript("OnEnable");assert(art.icon.color[4]==1)
b:SetNormalTexture("native-active-on")
assert(art.icon.path=="native-active-on" and b.normal.alpha==0,"native active icon not reflected")
assert(b.scripts.OnClick==callback and callback()=="ClearButton","click replaced")
local stableObjects,stableHooks,stableReads,stableWrites=counts.objects,counts.hooks,counts.reads,counts.alphaWrites
for i=1,1000 do b:FireScript("OnEnable");b:SetNormalTexture("native-active-on") end
assert(counts.objects==stableObjects and counts.hooks==stableHooks and counts.reads==stableReads and counts.alphaWrites==stableWrites,"stable control repainted/rediscovered")
style.set(nil,"standard");flush()
assert(Spy.MainWindow.CloseButton.standardGlyph.alpha==1 and Spy.MainWindow.LeftButton.standardGlyph.alpha==1,"Standard helper glyph lost")
assert(row.points[1][5]==nativeRowPoint[5],"Standard did not restore native row origin")
assert(row.StatusBar.points[1][4]==0 and row.StatusBar.points[2][4]==0 and row.LeftText.points[1][2]==row.StatusBar and row.RightText.points[1][2]==row.StatusBar,"Standard row geometry not restored")
assert(Coverage(rule)==0,"Standard retained row material")
for _,edge in ipairs(Spy.MainWindow.LeftButton.standardBorder.regions) do assert(edge.baseColor[4]==1,"Standard helper border not restored") end
assert(select(1,Spy.MainWindow:GetResizeBounds())==90,"Standard resize bounds not restored")
assert(Spy.MainWindow.Title.width==121 and Spy.MainWindow.Title.height==16 and not Spy.MainWindow.Title:GetWordWrap() and not Spy.MainWindow.Title:GetNonSpaceWrap(),"Standard title geometry not restored")
assert(Spy.MainWindow.Title.points[1][5]==-16 and Spy.MainWindow.CloseButton.points[1][1]=="TOPRIGHT" and Spy.MainWindow.CloseButton.points[1][4]==-4 and Spy.MainWindow.CloseButton.points[1][5]==-12,"Standard native anchors not restored")
assert(Spy.MainWindow.LeftButton.points[1][2]==Spy.MainWindow.RightButton and Spy.MainWindow.StatsButton.points[1][2]==Spy.MainWindow.ClearButton,"Standard native anchor chain not restored")
style.set(nil,"forever");flush()

for _,class in ipairs({"DRUID","PALADIN","SHAMAN","HUNTER","ROGUE"}) do
    Spy:SetBar(1,"Player","60 "..class,75,"Class",class,nil,0.7)
    assert(row.StatusBar.statusColor[1]==colors.Class[class].r and row.StatusBar.statusColor[2]==colors.Class[class].g)
    assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==1 and row.StatusBar.value==75)
end
Spy:SetBar(1,"Player","KOS",100,"Bar","Bar Text",nil,1)
assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==1,"non-class/status fill dimmed")
Spy:SetBar(1,"Player","60 Druid",100,"Class","DRUID",nil,1)
local before={objects=counts.objects,hooks=counts.hooks,reads=counts.reads,writes=counts.alphaWrites,scans=counts.scans}
for i=1,1000 do Spy:SetBar(1,"Player","60 Druid",100,"Class","DRUID",nil,1) end
assert(counts.objects==before.objects and counts.hooks==before.hooks,"warm row objects/hooks grew")
assert(counts.reads==before.reads and counts.scans==before.scans,"warm row traversed hierarchy")
assert(counts.alphaWrites==before.writes and #timers==0,"settled rows wrote alpha or queued full work")
print("BENCH Spy "..(source and "actual-source" or "source-shaped")..": 1000 warm SetBar updates: new UI objects/hooks, hierarchy scans/reads, cosmetic alpha writes and queued refreshes=0")
-- The full native list dispatcher requires Spy bootstrap/game state; this
-- additional synchronization workload uses the source-shaped dispatcher only.
if not source then
local steady={objects=counts.objects,hooks=counts.hooks,reads=counts.reads,geometry=counts.geometry,paint=counts.paint,alpha=counts.alphaWrites}
for i=1,1000 do Spy:SetCurrentList(1) end
assert(counts.objects==steady.objects and counts.hooks==steady.hooks and counts.reads==steady.reads and counts.geometry==steady.geometry and counts.paint==steady.paint and counts.alphaWrites==steady.alpha,"warm row synchronization churned cosmetics")
print("BENCH Spy Concept A: 1000 unchanged row-sync callbacks: objects/hooks/hierarchy reads/geometry/paint/alpha writes=0")
end
-- Native whole-window opacity updates do not schedule a skin repaint.
Spy.UpdateMainWindow=Spy.UpdateMainWindow or function() Spy.MainWindow.alpha=0.45 end
local q=#timers;Spy:UpdateMainWindow();assert(#timers==q)
-- New row pools, shrink/removal and same-slot replacement retain native actions.
local pendingBeforeRow=#timers
Spy:CreateRow(2)
local firstSlot=Spy.MainWindow.Rows[2]
firstSlot:Show()
assert(#timers==pendingBeforeRow,"new row queued a cosmetic refresh")
assert(firstSlot.points[1][5]==row.points[1][5]-17,"new slot did not follow dynamic list origin")
if source and Spy.BarsChanged then
    local cfg=Spy.db.profile.MainWindow
    local height=cfg.RowHeight
    cfg.RowHeight=height-4
    Spy:BarsChanged();flush()
    assert(firstSlot.points[1][5]==row.points[1][5]-13 and firstSlot:GetHeight()==height-4,
        "native row reflow lost the header offset")
    cfg.RowHeight=height
    Spy:BarsChanged();flush()
    assert(firstSlot.points[1][5]==row.points[1][5]-17,"native row stride was not restored")
end
assert(not firstSlot.nativeEnterCalls and Coverage(AssertRestingRule(firstSlot))>0,
    "new row was not painted before its first show")
Spy:SetBar(2,"Second","60 Rogue",100,"Class","ROGUE",nil,1)
local second=Spy.MainWindow.Rows[2];second:Hide();second:Show()
assert(second.StatusBar:GetStatusBarTexture():GetAlpha()==1)
local retired=Spy.MainWindow.Rows[2];retired:Hide();Spy.MainWindow.Rows[2]=nil
Spy:CreateRow(2);flush()
Spy:SetBar(2,"Recycled","60 Hunter",100,"Class","HUNTER",nil,1)
assert(Spy.MainWindow.Rows[2]~=retired)
assert(retired.points[1][5]==-51,"retired slot retained header offset")
assert(not RowChrome(retired) and #retired.StatusBar.regions==2,"row trim retained on retired native bars")
Spy.MainWindow.Rows[2]:Show()
AssertRestingRule(Spy.MainWindow.Rows[2])
assert(retired.StatusBar.points[1][4]==0 and retired.LeftText.points[1][2]==retired.StatusBar,"retired row retained Forever anchors")
assert(RowChrome(Spy.MainWindow.Rows[2]) and Spy.MainWindow.Rows[2].StatusBar.allPoints==Spy.MainWindow.Rows[2],"recycled slot lost compact geometry")
local settledObjects,settledHooks=counts.objects,counts.hooks
Spy.MainWindow.Rows[2]:Hide();Spy.MainWindow.Rows[2]:Show()
retired:Hide();retired:Show()
assert(counts.objects==settledObjects and counts.hooks==settledHooks,"retired row callbacks allocated artwork")
local currentChrome=RowChrome(Spy.MainWindow.Rows[2]);local beforeRetired=counts.paint
retired:FireScript("OnEnter");retired:FireScript("OnLeave")
assert(counts.paint==beforeRetired and AssertRestingRule(Spy.MainWindow.Rows[2]),"retired hover restyled current owner")
-- Native warning severity, stats frame and unregistered art ownership.
Spy:ShowAlert("kos","Enemy","Source","Location");flush()
local rootRim,alertRim,statsRim
for host,rim in pairs(rings) do
    assert(not shells[host] and host.mouse==false,"Forever host entered EUI registry or intercepts input")
    if host.parent==Spy.MainWindow then rootRim=rim end
    if host.parent==Spy.AlertWindow then alertRim=rim end
    if host.parent==SpyStatsFrame then statsRim=rim end
end
assert(rootRim and rootRim.on and alertRim and statsRim,"auxiliary Forever frame missing")
assert(not rootRim.heavy and not alertRim.heavy and not statsRim.heavy,"Heavy Bronze retained")
assert(#rootRim.host.children==0,"extra Forever surface hosts retained")
assert(rootRim.host:GetBottom()==Spy.MainWindow:GetBottom(),"Forever extended the native window")
assert(alertRim.color[1]==0.9 and Spy.AlertWindow.Title.textColor[1]==1,"alert severity changed")
assert(Spy:AlertWatch()=="native-watch" and alertRim.color[1]==0.6 and alertRim.color[3]==0.8,"watch alert severity failed to refresh")
-- Simulate EUI's registered-host texture cleanup; custom art remains outside it.
for host in pairs(shells) do for _,region in ipairs(host.regions) do region.alpha=0 end end
assert(rootRim.edge.alpha==1,"EUI cleanup stripped Forever rim")
assert(Coverage(AssertRestingRule(row))>0,"EUI cleanup changed resting row bevels")
local plate,grain
for _,region in ipairs(rootRim.host.regions) do
    if region.drawLayer=="BACKGROUND" and region.sublevel==1 then plate=region end
    if region.drawLayer=="BACKGROUND" and region.sublevel==2 then grain=region end
end
assert(plate and grain and plate.parent==rootRim.host,"compact background ownership missing")
local seam,mask
for _,region in ipairs(rootRim.host.regions) do
    if region.kind=="Texture" and region.height==1 then seam=region end
    if region.kind=="MaskTexture" then mask=region end
end
assert(seam and seam.points[1][5]==row.points[1][5]+2,"separator did not move with the list")
if maskedSurfaces then assert(mask and plate.masks[mask] and grain.masks[mask],"compact mask lost surface coverage") end
local opacity=settings.args.opacity
Spy.MainWindow:SetAlpha(1)
assert(plate.gradient and plate.blend=="BLEND" and grain.blend=="BLEND","managed gradient/blend path not exercised")
local low,high={0.120,0.084,0.055},{0.165,0.115,0.075}
for i=1,3 do
    assert(plate.baseColor[i]==1,"main plate source repeats the warm tint")
    assert(math.abs(plate.baseColor[i]*plate.gradient.low[i]-low[i])<0.0001 and math.abs(plate.baseColor[i]*plate.gradient.high[i]-high[i])<0.0001,"rendered material RGB is double-tinted")
end
assert(opacity.get()==75,"Forever background default is not 75%")
for _,a in ipairs({0,35,100,75}) do
    local parentAlpha=Spy.MainWindow.alpha
    opacity.set(nil,a);flush()
    local grainAlpha=a/100*0.12
    local plateAlpha=(a/100-grainAlpha)/(1-grainAlpha)
    assert(math.abs(plate.gradient.low[4]-plateAlpha)<0.0001 and math.abs(plate.gradient.high[4]-plateAlpha)<0.0001,"gradient stops retain opaque paint")
    assert(math.abs(grain.color[4]-grainAlpha)<0.0001,"grain retained opaque paint")
    assert((a>0)==plate:IsShown() and (a>0)==grain:IsShown(),"zero-opacity surfaces still render")
    assert(math.abs((Composite(plate,grain))-a/100)<0.0001,"stacked opacity budget")
    assert(Spy.MainWindow.alpha==parentAlpha and rootRim.edge.alpha==1,"background slider faded parent/border")
    assert(Spy.MainWindow.Title.alpha==1 and Spy.MainWindow.CloseButton.alpha==1,"slider faded content")
    -- SavedVariables reconstruction: explicit endpoints must survive re-reading.
    EUIAddonSkinsDB={spy={style="forever",opacity=a/100},other={preserved=true}}
    module.refresh();flush()
    assert(opacity.get()==a and math.abs(Composite(plate,grain)-a/100)<0.0001,"saved opacity lost")
end
-- Repeat an unchanged slider value: no material/geometry/visibility work.
local pc,gc,vc,rc=counts.paint,counts.geometry,counts.visibility,counts.reads
local queuedBefore=#timers
for i=1,1000 do opacity.set(nil,75) end
assert(#timers==queuedBefore,"unchanged opacity scheduled cosmetic work")
flush()
assert(counts.paint==pc and counts.geometry==gc and counts.visibility==vc and counts.reads==rc,"unchanged opacity repainted or scanned")
assert(Spy.MainWindow.Background.alpha==0 and Spy.MainWindow:GetBackdrop()==nil and Spy.MainWindow.TitleBar:GetBackdrop()==nil,"native backdrop stacks with Forever")
for host in pairs(shells) do
    if host.parent==Spy.MainWindow then
        assert(Coverage(host.shellAtlas)==0 and Coverage(host.shellOverlay)==0 and Coverage(host.shellFlat)==0,"EUI Standard shell stacks with Forever")
    end
end
-- A queued change followed by the original value must still use latest prefs.
opacity.set(nil,0);opacity.set(nil,75);opacity.set(nil,75);flush()
assert(opacity.get()==75 and math.abs(Composite(plate,grain)-0.75)<0.0001,"coalesced opacity reverted saved preference")
-- Native whole-window fading is independent; the skin never changes its alpha.
Spy.MainWindow:SetAlpha(0.5)
local faded=Composite(plate,grain)
assert(faded>0 and faded<0.75,"native parent fade unexpectedly increases coverage")
opacity.set(nil,75);flush()
assert(Spy.MainWindow.alpha==0.5,"skin changed native parent fade")
Spy.MainWindow:SetAlpha(1)
local nativeProfile=Spy.db.profile
settings.args.reset.func();flush()
assert(style.get()=="auto" and opacity.get()==75 and Spy.db.profile==nativeProfile and EUIAddonSkinsDB.other.preserved,"reset changed unrelated settings")
style.set(nil,"forever");flush()
local savedRows=Spy.MainWindow.Rows
Spy.MainWindow:Hide();Spy.MainWindow:Show();flush()
assert(Spy.MainWindow.Rows==savedRows and row.scripts.OnClick()=="target")
style.set(nil,"standard");flush()
assert(not rootRim.on and not alertRim.on and not statsRim.on,"Standard retained Forever rims")
local standardPaint=counts.paint
row:FireScript("OnEnter");row:FireScript("OnLeave")
assert(counts.paint==standardPaint and chrome.alpha==0,"Standard hover retained Forever paint")
assert(not row.scripts.OnUpdate and not Spy.MainWindow.scripts.OnUpdate,"skin added polling")
assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==1 and Spy.MainWindow.Background:GetAlpha()==1)
assert(Spy.MainWindow.CloseButton.normal.color[1]==1,"Standard icon tint not restored")
-- Automatic follows the current EUI profile; saved overrides survive reconstruction.
style.set(nil,"auto");look="forever";for _,fn in ipairs(looks)do fn()end;flush()
assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==1)
EUIAddonSkinsDB={spy={style="standard"},other={preserved=true}}
for _,fn in ipairs(looks)do fn()end;flush()
assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==1)
style.set(nil,"forever");flush()
local objects,hooks=counts.objects,counts.hooks
for i=1,40 do
    style.set(nil,i%2==0 and "forever" or "standard");flush()
end
assert(counts.objects==objects and counts.hooks==hooks,"theme cycling accumulated artwork/hooks")
-- Spy owns only its reason dialog; foreign StaticPopup reuse stays native.
assert(Spy:SetKOSReason()=="native-reason" and StaticPopup1.skinActive)
StaticPopup1.which="OtherAddon";module.refresh();flush()
assert(not StaticPopup1.skinActive,"reason-dialog style leaked into a foreign popup")
-- Borrowed menu retains callback returns and has one skin settings command.
Spy_BarDropDownMenu={initialize=function()return "native-menu",nil,3 end}
local menuEntries={}
UIDropDownMenu_AddButton=function(info)menuEntries[#menuEntries+1]=info end
Spy:BarDropDownOpen()
local a,b,c=Spy_BarDropDownMenu.initialize({},1)
assert(a=="native-menu" and b==nil and c==3 and #menuEntries==1)
Spy:BarDropDownOpen();menuEntries={};Spy_BarDropDownMenu.initialize({},1)
assert(#menuEntries==1,"duplicate menu injection")
assert(menuEntries[1].text=="EUI AddonSkins" and menuEntries[1].hasArrow and #menuEntries[1].menuList==6,"settings submenu missing")
UIDROPDOWNMENU_MENU_VALUE=menuEntries[1].value
menuEntries={};Spy_BarDropDownMenu.initialize({},2)
assert(#menuEntries==6 and menuEntries[1].text=="Style","submenu delegated into native player actions")
menuEntries[5].func();assert(dialog.lastOpen=="EUIAddonSkinsSpy")
menuEntries[3].func();flush();assert(style.get()=="standard" and menuEntries[3].checked())
menuEntries[4].func();flush();assert(style.get()=="forever")
menuEntries[6].func();flush();assert(style.get()=="auto" and opacity.get()==75)
style.set(nil,"forever");flush()
UIDROPDOWNMENU_MENU_VALUE=nil
assert(menuBinding.owner==Spy_BarDropDownMenu and menuBinding.module.skin.IsEnabled())
style.set(nil,"standard");flush();assert(not menuBinding.module.skin.IsEnabled(),"Standard menus no longer native")
-- EUI font changes must restore the current Standard font, not an old snapshot.
euiFont={"EUI New",13,"OUTLINE"}
style.set(nil,"forever");module.refresh();flush()
assert(Spy.MainWindow.Title.font[1]=="EUI New" and Spy.MainWindow.Title.font[2]==13,"Forever changed current EUI font size")
style.set(nil,"standard");flush()
assert(Spy.MainWindow.Title.font[1]=="EUI New" and Spy.MainWindow.Title.font[2]==13,"Standard restored stale EUI typography")
-- Combat defers even inherited-protected cosmetics and catches disable cleanup.
style.set(nil,"forever");flush()
combat=true
local alphaBefore,geometryBefore,paintBefore,visibilityBefore=counts.alphaWrites,counts.geometry,counts.paint,counts.visibility
Spy.MainWindow.Title:SetText("Nearby")
row:FireScript("OnEnter");row:FireScript("OnLeave")
settings.args.opacity.set(nil,0)
style.set(nil,"standard");flush()
assert(counts.geometry==geometryBefore and counts.paint==paintBefore and counts.visibility==visibilityBefore,"header artwork wrote in combat")
assert(counts.alphaWrites==alphaBefore,"theme wrote in combat")
combat=false
for _,f in ipairs(events)do if f.events and f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent()end end
flush();assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==1)
style.set(nil,"forever");flush()
enabled=false
for _,fn in ipairs(looks)do fn()end;flush()
assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==1 and Spy.MainWindow.Background:GetAlpha()==1,"disable did not clean Forever art")
assert(row.StatusBar.points[1][4]==0 and row.LeftText.points[1][2]==row.StatusBar and chrome.alpha==0,"disable retained custom row geometry")
assert(Coverage(rule)==0,"disable retained row bevels")
assert(Spy.MainWindow.Title.font[1]=="EUI New" and Spy.MainWindow.Title.font[2]==13,"disable retained title emphasis")
for _,edge in ipairs(Spy.MainWindow.LeftButton.standardBorder.regions) do assert(edge.baseColor[4]==1,"disable retained hidden Standard border") end
assert(#errors==0,table.concat(errors,"\n"))

-- Investigation fixture: run the unmodified bundled widget against a modern
-- frame capability model. An expected failure here documents the reproduction;
-- it is not evidence that the live regression has been repaired.
local upstreamRoot = os.getenv("SPY_SOURCE")
if upstreamRoot then
    local savedFactory, savedLibStub, savedLists = CreateFrame, LibStub, AceGUIWidgetLSMlists
    local function ReproduceTexturePopup(active, selectedStyle)
        enabled = active
        style.set(nil, selectedStyle); flush()
        local factoryBefore = CreateFrame
        module.refresh(); flush()
        assert(CreateFrame == factoryBefore, "Spy adapter replaced the global frame factory")
        local created = {}
        -- Only this test's new frames lose legacy backdrop capabilities. The
        -- production adapter and the official library files are unmodified.
        CreateFrame = function(kind, name, parent, template)
            local f = savedFactory(kind, name, parent, template)
            local createTexture = f.CreateTexture
            f.CreateTexture = function(self, ...)
                local texture = createTexture(self, ...)
                texture.SetTexCoord = function() end
                return texture
            end
            f.SetClampedToScreen = function() end
            f.EnableMouseWheel = function() end
            if not (template and template:find("BackdropTemplate", 1, true)) then
                f.SetBackdrop, f.GetBackdrop = nil, nil
                f.SetBackdropColor, f.SetBackdropBorderColor = nil, nil
            end
            created[#created+1] = {frame=f, template=template, kind=kind}
            return f
        end
        local ace = {constructors={}}
        function ace:RegisterWidgetType(name, constructor) self.constructors[name] = constructor end
        function ace:RegisterAsWidget(widget)
            function widget:SetWidth(value) self.frame:SetWidth(value) end
            function widget:SetHeight(value) self.frame:SetHeight(value) end
            function widget:Fire() end
        end
        function ace:SetFocus(widget) self.focus = widget end
        function ace:ClearFocus() self.focus = nil end
        local sharedMedia = {}
        function sharedMedia:HashTable() return {Flat="native-flat", Smooth="native-smooth"} end
        function sharedMedia:Fetch(_, key) return key end
        local libraries = {["AceGUI-3.0"]=ace, ["LibSharedMedia-3.0"]=sharedMedia}
        LibStub = setmetatable({
            NewLibrary=function(_,name) local lib={};libraries[name]=lib;return lib end,
        }, {__call=function(_,name) return assert(libraries[name], name) end})
        assert(loadfile(upstreamRoot .. "/Libs/AceGUI-3.0-SharedMediaWidgets/prototypes.lua"))()
        assert(loadfile(upstreamRoot .. "/Libs/AceGUI-3.0-SharedMediaWidgets/StatusbarWidget.lua"))()
        local widget = ace.constructors.LSM30_Statusbar()
        widget:OnAcquire()
        widget:SetList(sharedMedia:HashTable("statusbar"))
        widget:SetValue("Smooth")
        local ok, err = pcall(function() widget.frame.dropButton:FireScript("OnClick", "LeftButton") end)
        assert(not ok and tostring(err):find("prototypes.lua:211:", 1, true)
            and tostring(err):find("SetBackdrop", 1, true), "unexpected texture-dropdown failure: " .. tostring(err))
        local popup = created[#created]
        assert(popup.kind == "Frame" and popup.template == nil and popup.frame.SetBackdrop == nil,
            "official popup did not use the untemplated construction path")
        CreateFrame, LibStub = savedFactory, savedLibStub
        print("REPRO ONLY: official Spy texture popup lacks SetBackdrop; skin=" .. tostring(active) ..
            ", style=" .. selectedStyle .. "; EUI-only trigger remains unverified")
    end
    ReproduceTexturePopup(false, "standard")
    ReproduceTexturePopup(true, "standard")
    ReproduceTexturePopup(true, "forever")
    ReproduceTexturePopup(true, "auto")
    enabled = false
    module.refresh(); flush()
    CreateFrame, LibStub, AceGUIWidgetLSMlists = savedFactory, savedLibStub, savedLists
end

Enum=priorEnum
print("PASS: Spy Standard/Forever/Automatic restoration, native class/status colours, secure rows, callbacks/truncation, controls, pooling, settings/menu ownership, combat and bounded warm work")
end
