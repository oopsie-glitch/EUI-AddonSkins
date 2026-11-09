-- Spy Forever: native-shaped UI plus optional unmodified official constructors.
do
local timers, errors, looks, events = {}, {}, {}, {}
local combat, enabled, look, panelAlpha = false, true, "blizzard", 0.8
local rings, shells = {}, {}
tinsert=table.insert
tDeleteItem=function(t,item) for i=#t,1,-1 do if t[i]==item then table.remove(t,i) end end end
local counts = {objects=0, hooks=0, reads=0, alphaWrites=0, scans=0}
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
    function f:SetAllPoints(v) self.allPoints=v end
    function f:SetPoint(...) self.points[#self.points+1]={...} end
    function f:ClearAllPoints() self.points={} end
    function f:SetHeight(v) self.height=v end
    function f:SetWidth(v) self.width=v end
    function f:SetSize(w,h) self.width,self.height=w,h end
    function f:GetWidth() return self.width end
    function f:GetHeight() return self.height end
    function f:SetMovable() end
    function f:GetAlpha() return self.alpha end
    function f:SetAlpha(v)
        assert(not combat,"cosmetic alpha write in combat")
        self.alpha=v; counts.alphaWrites=counts.alphaWrites+1
    end
    function f:Show() self.shown=true; if self.hooks.OnShow then self.hooks.OnShow(self) end end
    function f:Hide() self.shown=false; if self.hooks.OnHide then self.hooks.OnHide(self) end end
    function f:IsShown() return self.shown end
    function f:IsVisible() return self.shown end
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
    function f:GetTexture() return self.path end
    function f:SetColorTexture(...) self.color={...} end
    function f:SetVertexColor(...) self.color={...} end
    function f:GetVertexColor() return unpack(self.color) end
    function f:SetHorizTile() end
    function f:SetVertTile() end
    function f:SetText(v) self.text=v end
    function f:GetText() return self.text end
    function f:SetTextColor(...) self.textColor={...} end
    function f:GetTextColor() return unpack(self.textColor or {1,1,1,1}) end
    function f:SetFont(...) self.font={...} end
    function f:GetFont() return unpack(self.font) end
    function f:SetJustifyH(v) self.justify=v end
    function f:GetStringWidth() return #self.text*6 end
    function f:SetStatusBarTexture(v)
        if not self.texture then self.texture=frame("Texture"); self.texture.alpha=1 end
        self.texture.path=v
    end
    function f:GetStatusBarTexture() return self.texture end
    function f:SetStatusBarColor(...) self.statusColor={...} end
    function f:GetStatusBarColor() return unpack(self.statusColor or {0.5,0.5,0.5,1}) end
    function f:SetMinMaxValues(a,b) self.min,self.max=a,b end
    function f:SetValue(v) self.value=v end
    function f:CreateTexture()
        local t=frame("Texture"); self.regions[#self.regions+1]=t; return t
    end
    function f:CreateFontString()
        local t=frame("FontString");self.regions[#self.regions+1]=t;return t
    end
    function f:GetFontString() return self.label end
    function f:GetNormalTexture() return self.normal end
    function f:GetPushedTexture() return self.pushed end
    function f:GetDisabledTexture() return self.disabledTexture end
    function f:GetHighlightTexture() return self.highlight end
    if f.kind=="StatusBar" then f.SetVertexColor=nil;f.GetVertexColor=nil end
    return f
end
CreateFrame=function(kind,name,parent,template)
    local f=frame(kind,parent);f.name=name;f.secure=template=="SpySecureActionButtonTemplate"
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
function S.Shell(f,opts) f.standardShell=true;f.shellOptions=opts;shells[f]=true end
function S.CloseButton(f) f.close=true end
function S.PageButton(f,glyph) f.glyph=glyph end
function S.Font(f,r,g,b) f.font={"EUI",11,""};f:SetTextColor(r or 1,g or 1,b or 1,1) end
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
EUIAddonSkinsDB={spy={style="auto"},other={preserved=true}}
SlashCmdList={}
local colors={
    Class={DRUID={r=1,g=0.49,b=0.04,a=1},PALADIN={r=0.96,g=0.55,b=0.73,a=1},
        SHAMAN={r=0,g=0.44,b=0.87,a=1},HUNTER={r=0.67,g=0.83,b=0.45,a=1},ROGUE={r=1,g=0.96,b=0.41,a=1}},
    Window={Title={r=1,g=1,b=1,a=1},Background={r=0,g=0,b=0,a=1},["Title Text"]={r=1,g=1,b=1,a=1}},
    Bar={["Bar Text"]={r=1,g=1,b=1,a=1}},
    Alert={["KOS Border"]={r=0.9,g=0.1,b=0.05,a=1},Background={r=0,g=0,b=0,a=1},Icon={r=1,g=1,b=1,a=1},["KOS Text"]={r=1,g=0.1,b=0.1,a=1},["Name Text"]={r=1,g=1,b=1,a=1}},
}
Spy={db={profile={MainWindow={RowHeight=16,RowSpacing=1,TextHeight=12},Colors=colors}},
    Colors={},CreateMainWindow=function() end,CreateFrame=function(_,name)
        local f=frame(); _G[name]=f;return f,nil,"native-tail" end,
    SetFontSize=function(_,f,size) f.font[2]=size end,AddFontString=function() end,
    SetCurrentList=function(_,list) return list,nil,"list-tail" end,
    AlertWatch=function(self) self.AlertWindow:SetBackdropBorderColor(0.6,0.2,0.8,1);return "native-watch" end,
    SetKOSReason=function() StaticPopup1.which="Spy_SetKOSReasonOther";StaticPopup1.shown=true;return "native-reason" end,
    ShowAlert=function(self) self.AlertWindow:SetBackdropBorderColor(0.9,0.1,0.05,1);self.AlertWindow.Title:SetTextColor(1,0.1,0.1,1);return "native-alert" end,BarDropDownOpen=function() end}
local function makeRow(index)
    local row=frame("Button",Spy.MainWindow);row.secure=true;row.id=index
    row.StatusBar=frame("StatusBar",row);row.StatusBar:SetStatusBarTexture("native")
    row.LeftText=row.StatusBar:CreateFontString();row.RightText=row.StatusBar:CreateFontString()
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
if source then
    assert(loadfile(source.."/Colors.lua"))()
    assert(loadfile(source.."/Widgets.lua"))()
    assert(loadfile(source.."/MainWindow.lua"))()
    -- The exact-source mode exercises row construction/paint; menu dispatch
    -- remains source-shaped to avoid opening Blizzard UI in the host fixture.
    Spy.BarDropDownOpen=function() end
end
Spy.MainWindow=frame();Spy.MainWindow.Rows={};Spy.MainWindow.protected=true
_G.Spy_MainWindow=Spy.MainWindow
Spy.MainWindow.Background=Spy.MainWindow:CreateTexture()
Spy.MainWindow.TitleBar=frame("Frame",Spy.MainWindow)
Spy.MainWindow.Title=Spy.MainWindow:CreateFontString()
Spy.MainWindow.Title:SetText("Kill On Sight")
for _,key in ipairs({"CloseButton","LeftButton","RightButton","ClearButton","StatsButton","CountButton"}) do
    local b=frame("Button",Spy.MainWindow)
    b.normal=frame("Texture");b.pushed=frame("Texture");b.highlight=frame("Texture")
    b.width=key=="StatsButton" and 12 or 16
    b.scripts.OnClick=function() return key end
    Spy.MainWindow[key]=b
end
Spy.AlertWindow=frame();Spy.AlertWindow.Icon=frame("Frame",Spy.AlertWindow)
Spy.AlertWindow.Title=Spy.AlertWindow:CreateFontString();Spy.AlertWindow.Name=Spy.AlertWindow:CreateFontString()
Spy.AlertWindow.Location=Spy.AlertWindow:CreateFontString()
SpyStatsFrame=frame();SpyStatsFrameTopCloseButton=frame("Button",SpyStatsFrame)
Spy.optionsFrames={}
StaticPopup1=frame();StaticPopup1.shown=false
Spy:CreateRow(1)
local row=Spy.MainWindow.Rows[1]
row.attributes={type1="macro",macrotext="/target Enemy"}
row.scripts.OnClick=function()return "target" end
local nativePostClick=function()return "native-port-postclick" end
row.scripts.PostClick=nativePostClick
local rawSetBar=Spy.SetBar
Spy:SetBar(1,"A very long player name","60 Druid",100,"Class","DRUID",nil,1)
local textWidth=row.LeftText.width
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
local initialObjects=counts.objects
assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==1,"Standard fill changed")
assert(Spy.MainWindow.LeftButton.glyph=="<" and Spy.MainWindow.CloseButton.close)
assert(SLASH_EUISPYSKIN1=="/euispy")
SlashCmdList.EUISPYSKIN()
local settings=registry.tables.EUIAddonSkinsSpy
assert(settings and dialog.lastOpen=="EUIAddonSkinsSpy")
local style=settings.args.style
local statsColour=frame("Frame",SpyStatsFrame)
local classLabel=statsColour:CreateFontString()
classLabel:SetTextColor(0.2,0.4,0.9,0.6)
style.set(nil,"forever");flush()
assert(classLabel:GetTextColor()==0.2 and classLabel.textColor[4]==0.6,"statistics semantic label colour lost")
assert(style.get()=="forever" and EUIAddonSkinsDB.other.preserved)
assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==0.32,"class fill not softened")
assert(Spy.MainWindow.Background:GetAlpha()==0,"native background stacks under transparency")
assert(row.StatusBar.statusColor[1]==1 and row.StatusBar.statusColor[2]==0.49,"class identity changed")
assert(row.LeftText:GetText()=="Player" and row.RightText:GetText()=="60 Druid")
assert(row.attributes.macrotext=="/target Enemy" and row.scripts.OnClick()=="target")
assert(row.scripts.PostClick==nativePostClick and row.scripts.PostClick()=="native-port-postclick")
assert(Spy.MainWindow.StatsButton.scripts.OnClick()=="StatsButton")
assert(Spy.MainWindow.StatsButton.width==12,"header geometry changed")
local tint=Spy.MainWindow.CloseButton.normal.color
assert(tint[1]==0.91 and tint[2]==0.71)
local nextResult=pack(Spy:SetBar(1,"A very long player name","60 Druid",100,"Class","DRUID",nil,1))
assert(nextResult.n==oldSetBarResult.n)
for i=1,nextResult.n do assert(nextResult[i]==oldSetBarResult[i]) end
assert(row.LeftText.width==textWidth,"native truncation changed")
row.width=90
Spy:SetBar(1,"A very long player name","60 Druid",100,"Class","DRUID",nil,1)
assert(row.LeftText.width==90-row.RightText:GetStringWidth()-4)
for _,class in ipairs({"DRUID","PALADIN","SHAMAN","HUNTER","ROGUE"}) do
    Spy:SetBar(1,"Player","60 "..class,75,"Class",class,nil,0.7)
    assert(row.StatusBar.statusColor[1]==colors.Class[class].r and row.StatusBar.statusColor[2]==colors.Class[class].g)
    assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==0.32 and row.StatusBar.value==75)
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
-- Native whole-window opacity updates do not schedule a skin repaint.
Spy.UpdateMainWindow=Spy.UpdateMainWindow or function() Spy.MainWindow.alpha=0.45 end
local q=#timers;Spy:UpdateMainWindow();assert(#timers==q)
-- New row pools, shrink/removal and same-slot replacement retain native actions.
Spy:CreateRow(2);flush()
Spy:SetBar(2,"Second","60 Rogue",100,"Class","ROGUE",nil,1)
local second=Spy.MainWindow.Rows[2];second:Hide();second:Show()
assert(second.StatusBar:GetStatusBarTexture():GetAlpha()==0.32)
local retired=Spy.MainWindow.Rows[2];retired:Hide();Spy.MainWindow.Rows[2]=nil
Spy:CreateRow(2);flush()
Spy:SetBar(2,"Recycled","60 Hunter",100,"Class","HUNTER",nil,1)
assert(Spy.MainWindow.Rows[2]~=retired)
local settledObjects,settledHooks=counts.objects,counts.hooks
Spy.MainWindow.Rows[2]:Hide();Spy.MainWindow.Rows[2]:Show()
retired:Hide();retired:Show()
assert(counts.objects==settledObjects and counts.hooks==settledHooks,"retired row callbacks allocated artwork")
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
assert(alertRim.color[1]==0.9 and Spy.AlertWindow.Title.textColor[1]==1,"alert severity changed")
assert(Spy:AlertWatch()=="native-watch" and alertRim.color[1]==0.6 and alertRim.color[3]==0.8,"watch alert severity failed to refresh")
-- Simulate EUI's registered-host texture cleanup; custom art remains outside it.
for host in pairs(shells) do for _,region in ipairs(host.regions) do region.alpha=0 end end
assert(rootRim.edge.alpha==1,"EUI cleanup stripped Forever rim")
local plate,grain=rootRim.host.regions[1],rootRim.host.regions[2]
for _,a in ipairs({0,0.35,1,0.8}) do
    panelAlpha=a;module.refresh();flush()
    assert(math.abs((plate.alpha+grain.alpha*(1-plate.alpha))-a)<0.0001,"stacked opacity budget")
end
local savedRows=Spy.MainWindow.Rows
Spy.MainWindow:Hide();Spy.MainWindow:Show();flush()
assert(Spy.MainWindow.Rows==savedRows and row.scripts.OnClick()=="target")
style.set(nil,"standard");flush()
assert(not rootRim.on and not alertRim.on and not statsRim.on,"Standard retained Forever rims")
assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==1 and Spy.MainWindow.Background:GetAlpha()==1)
assert(Spy.MainWindow.CloseButton.normal.color[1]==1,"Standard icon tint not restored")
-- Automatic follows the current EUI profile; saved overrides survive reconstruction.
style.set(nil,"auto");look="forever";for _,fn in ipairs(looks)do fn()end;flush()
assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==0.32)
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
menuEntries[1].func();assert(dialog.lastOpen=="EUIAddonSkinsSpy")
assert(menuBinding.owner==Spy_BarDropDownMenu and menuBinding.module.skin.IsEnabled())
style.set(nil,"standard");flush();assert(not menuBinding.module.skin.IsEnabled(),"Standard menus no longer native")
-- Combat defers even inherited-protected cosmetics and catches disable cleanup.
style.set(nil,"forever");flush()
combat=true
local alphaBefore=counts.alphaWrites
style.set(nil,"standard");flush()
assert(counts.alphaWrites==alphaBefore,"theme wrote in combat")
combat=false
for _,f in ipairs(events)do if f.events and f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent()end end
flush();assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==1)
style.set(nil,"forever");flush()
enabled=false
for _,fn in ipairs(looks)do fn()end;flush()
assert(row.StatusBar:GetStatusBarTexture():GetAlpha()==1 and Spy.MainWindow.Background:GetAlpha()==1,"disable did not clean Forever art")
assert(#errors==0,table.concat(errors,"\n"))
print("PASS: Spy Standard/Forever/Automatic restoration, native class/status colours, secure rows, callbacks/truncation, controls, pooling, settings/menu ownership, combat and bounded warm work")
end
