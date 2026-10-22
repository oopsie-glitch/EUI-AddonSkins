-- SimulationCraft export-window lifecycle, editor actions and native saved settings.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'TalentLoadoutManager'); factory = fn end
ns.RegisterModule = function(id, _, available, install) module = {id=id, available=available, install=install} end
geterrorhandler = function() return function(e) errors[#errors+1] = e end end
InCombatLockdown = function() return combat end
C_Timer = {After = function(_, fn) timers[#timers+1] = fn end}
hooksecurefunc = function(owner, key, callback)
    hookCount = hookCount + 1
    local original = owner[key]
    owner[key] = function(...)
        local values = table.pack(original(...)); callback(...); return table.unpack(values,1,values.n)
    end
end
local function Flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 10, 'refresh loop')
    end
    assert(#errors == 0, table.concat(errors, '\n'))
end
local function Object(kind, parent)
    allocated = allocated + 1
    local f = {kind=kind or 'Frame', parent=parent, regions={}, children={}, scripts={}, shown=true, alpha=1,
        path='Native', size=13, flags='', color={0.2,0.8,0.1,1}, width=16, height=20}
    function f:GetObjectType() return self.kind end
    function f:IsForbidden() return false end
    function f:IsProtected() return self.protected end
    function f:GetChildren() childReads=childReads+1; self.walks=(self.walks or 0)+1; return table.unpack(self.children) end
    function f:GetNumChildren() return #self.children end
    function f:GetNumRegions() return #self.regions end
    function f:GetName() return self.name end
    function f:GetNormalTexture() return self.normal end
    function f:GetPushedTexture() return self.pushed end
    function f:GetDisabledTexture() return self.disabled end
    function f:SetNormalTexture(value) self.normal=self.normal or self:CreateTexture(nil,'ARTWORK'); self.normal:SetTexture(value) end
    function f:SetPushedTexture(value) self.pushed=self.pushed or self:CreateTexture(nil,'ARTWORK'); self.pushed:SetTexture(value) end
    function f:SetChecked(value) self.checked=value end
    function f:GetChecked() return self.checked end
    function f:HighlightText() self.selections=(self.selections or 0)+1 end
    function f:GetParent() parentReads=parentReads+1; return self.parent end
    function f:GetBackdrop() return self.backdrop end
    function f:LockHighlight() self.locked=true end
    function f:UnlockHighlight() self.locked=false end
    function f:IsHighlightLocked() return self.locked == true end
    function f:SetHighlightTexture(v)
        if type(v)=='table' then self.highlight=v
        elseif not self.highlight then self.highlight=self:CreateTexture(nil,'HIGHLIGHT') end
        self.highlight.texture=v
    end
    function f:GetRegions() regionReads=regionReads+1; return table.unpack(self.regions) end
    function f:GetFont() return self.path,self.size,self.flags end
    function f:SetFont(path,size,flags) self.path,self.size,self.flags=path,size,flags end
    function f:SetFontObject() error('unsafe FontObject assignment') end
    function f:GetFontObject() error('unsafe FontObject capture') end
    function f:GetTextColor() return table.unpack(self.color) end
    function f:SetTextColor(r,g,b,a) self.color[1],self.color[2],self.color[3],self.color[4]=r,g,b,a end
    function f:GetAlpha() return self.alpha end
    function f:SetAlpha(v) self.alpha=v end
    function f:SetShown(v) if v then self:Show() else self:Hide() end end
    function f:SetRotation(v) self.rotation=v end
    function f:SetColorTexture(r,g,b,a)
        colourWrites=colourWrites+1; self.color[1],self.color[2],self.color[3],self.color[4]=r,g,b,a
    end
    function f:SetVertexColor(r,g,b,a)
        self.vertex=self.vertex or {}; self.vertex[1],self.vertex[2],self.vertex[3],self.vertex[4]=r,g,b,a
    end
    function f:SetTexture(v) self.texture=v end
    if kind=='Texture' then function f:GetTexture() return self.texture end end
    function f:SetTexCoord(...) self.coords={...} end
    function f:SetText(v) self.text=v end
    function f:SetPoint(...) self.point={...} end
    function f:ClearAllPoints() self.point=nil end
    function f:SetAllPoints(p) self.anchor=p end
    function f:SetFrameLevel(v) self.level=v end
    function f:GetFrameLevel() return self.level or 4 end
    function f:EnableMouse(v) self.mouse=v end
    function f:SetWidth(v) self.width=v end
    function f:SetHeight(v) self.height=v end
    function f:GetWidth() return self.width end
    function f:GetHeight() return self.height end
    function f:SetSize(w,h) self.width,self.height=w,h end
    function f:GetDrawLayer() return self.layer end
    function f:IsShown() return self.shown end
    function f:Show() self.shown=true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
    function f:Hide() self.shown=false end
    function f:IsEnabled() return self.enabled ~= false end
    function f:GetFontString() return self.Text end
    function f:GetHighlightTexture() return self.highlight end
    function f:GetThumbTexture() return self.thumb end
    function f:GetOrientation() return self.orientation or 'VERTICAL' end
    function f:GetCheckedTexture() return self.checkedArt end
    function f:GetDisabledCheckedTexture() return self.disabledArt end
    function f:Enable() self.enabled=true end
    function f:Disable() self.enabled=false end
    function f:RegisterEvent(e) self.events=self.events or {}; self.events[e]=true end
    function f:SetScript(k, fn) self.scripts[k]=fn end
    function f:HookScript(k, fn)
        local old=self.scripts[k]; self.scripts[k]=function(...) if old then old(...) end; fn(...) end
    end
    function f:CreateTexture(_,layer)
        local t=Object('Texture'); t.layer=layer; self.regions[#self.regions+1]=t; return t
    end
    function f:CreateFontString()
        local t=Object('FontString'); t.parent=self; self.regions[#self.regions+1]=t; return t
    end
    function f:RegisterObject(o) self.Objects=self.Objects or {}; self.Objects[#self.Objects+1]=o end
    function f:SetBackdrop(v) self.backdrop=v end
    if parent then parent.children[#parent.children+1]=f end
    return f
end
CreateFrame = function(kind,name,parent) local f=Object(kind,parent); f.name=name; if name then _G[name]=f end; events[#events+1]=f; return f end
local function Text(parent)
    local f=Object('FontString'); f.parent=parent; parent.regions[#parent.regions+1]=f; return f
end
local S = {GetFont=function() return fontFace,'' end, GetAccentColor=function() return accent,0.6,0.8 end,
    GetPanelColor=function() return 0.06,0.06,0.07,0.95 end, OnLooksChanged=function(fn) looks[#looks+1]=fn end}
S.Font=function(f,r,g,b) assert(not combat); fontWrites=fontWrites+1; f:SetFont(fontFace, f.size, ''); if r then f:SetTextColor(r,g,b,1) end end
S.Panel=function(f) if not f.panel then f.panel=true; f:CreateTexture(nil,'BACKGROUND') end end
S.Shell=S.Panel
S.Inset=function(f) f.inset=true end
S.FadeNineSlice=function(f) f.faded=true end
S.Tab=function(f)
    f.tab=true
    if not f.tabFill then
        f.tabFill=f:CreateTexture(nil,'BACKGROUND')
        f.tabText=f:CreateFontString(); f.tabText:SetTextColor(1,1,0,1)
    end
end
S.SetTabSelection=function(f,v) f.selected=v end
S.ScrollBar=function(f) f.scroll=true end
S.CloseButton=function(f)
    f.close=true
    if not f.closeGlyph then f.closeGlyph=f:CreateTexture(nil,'OVERLAY') end
end
S.Checkbox=function(f)
    checkboxPaints=checkboxPaints+1
    if f.check then return end
    f.check=true; f.checkFill=f:CreateTexture(nil,'BACKGROUND'); f.checkHover=f:CreateTexture(nil,'HIGHLIGHT')
    f.checkBorder=Object('Frame',f)
end
S.Button=function(f)
    f.button=true
    if not f.buttonBorder then
        f.buttonBorder=Object('Frame',f)
        for i=1,4 do local edge=f.buttonBorder:CreateTexture(nil,'BORDER'); edge.width=1; edge.height=20 end
    end
end
S.EditBox=function(f) f.input=true end
S.Dropdown=function(f) f.dropdown=true end
S.StateButtonLabel=function(f) f.stateLabel=true end
S.PageButton=function(f,glyph) f.glyph=glyph end

assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
local popupBinds=0
ns.BindPopupOwner=function() end
ns.BindPopupList=function() popupBinds=popupBinds+1 end
assert(loadfile('EUIAddonSkins/Skins/TalentLoadoutManager.lua'))('EUIAddonSkins',ns)
assert(not module and factory)
factory();assert(not module.available())
local function Button(parent)
    local f=Object('Button',parent);f.Text=Text(f);return f
end
local function Check(parent)
    local f=Object('CheckButton',parent);f.text=Text(f)
    f.checkedArt=f:CreateTexture(nil,'ARTWORK');f.disabledArt=f:CreateTexture(nil,'ARTWORK')
    return f
end
local rows={}
local app={sideBars={},Event={SideBarLoaded='SideBarLoaded'}}
function app:RegisterCallback(event,cb) self.callback=cb end
TalentLoadoutManager=app
assert(module.available())
UIParent=Object('Frame')
local native=Object('Frame',UIParent);native.protected=true
local side={}
function side:SetupHook() return 'native-setup' end
function side:OnListElementInitialized(row,data)
    row.Text:SetText(data);row.Text:SetTextColor(.1,.8,.3,1)
    row.scripts.OnClick=function() return 'native-row' end
    return 'native-initializer'
end
function side:Make()
    self.SideBar=Object('Frame',native)
    local f=self.SideBar;f.Title=Text(f);f.Background=f:CreateTexture(nil,'BACKGROUND');f.Background:SetColorTexture(.1,.2,.3,.4)
    for _,key in ipairs({'CreateButton','ImportButton','SaveButton','ConfigButton','ToggleSideBarButton'}) do
        f[key]=Button(f);f[key].scripts.OnClick=function() return key end
    end
    f.SaveButton:Disable()
    f.ScrollBoxContainer={ScrollBar=Object('Frame',f),ScrollBox={EnumerateFrames=function() return ipairs(rows) end}}
    f.ScrollBoxContainer.ScrollBox.EnumerateFrames=function() local i=0;return function() i=i+1;return rows[i] end end
    local bar=f.ScrollBoxContainer.ScrollBar;bar.Track={Thumb=Object('Frame',bar)};bar.Back=Button(bar);bar.Forward=Button(bar)
    self.importDialog=Object('Frame',UIParent)
    local d=self.importDialog;d.Title=Text(d);d.AcceptButton=Button(d);d.CancelButton=Button(d)
    d.AutoApplyCheckbox=Check(d);d.ImportIntoCurrentLoadoutCheckbox=Check(d)
    d.ImportControl={Label=Text(d),InputContainer=Object('ScrollFrame',d)}
    d.NameControl={Label=Text(d),EditBox=Object('EditBox',d)}
    d.NameControl.EditBox:SetText('saved-name')
    self.createDialogName='Default_CreateLoadout'
end
local gui={Release=function() return 'released' end}
local dialog={BlizOptions={},OpenFrames={},FeedGroup=function() return 'native-feed' end,Open=function() return 'native-open' end}
LibStub=function(name) if name=='AceGUI-3.0' then return gui elseif name=='AceConfigDialog-3.0' then return dialog end end
local menu={OpenMenu=function() end,GetOpenMenu=function(self) return self.list end}
Menu={GetManager=function() return menu end}
StaticPopup_Show=function() return 'native-popup' end
module.install(S,module)
assert(app.callback and #errors==0)
app.sideBars.Default=side
side:Make();app.callback()
local f,d=side.SideBar,side.importDialog
assert(f.CreateButton.button and f.SaveButton.enabled==false and f.ScrollBoxContainer.ScrollBar.scroll)
assert(f.Background.color[4]==.4 and not f.panel,'sidebar opacity setting replaced by opaque shell')
assert(d.panel and d.NameControl.EditBox.input and d.AutoApplyCheckbox.check)
assert(d.NameControl.EditBox.text=='saved-name' and not native.panel)
local row=Button(f);rows[1]=row
assert(side:OnListElementInitialized(row,'loadout-name')=='native-initializer')
assert(row.Text.path=='EUI' and row.Text.color[2]==.8 and row.scripts.OnClick()=='native-row')
menu.list=Object('Frame');menu.list.GetOwnerRegion=function() return row end
menu:OpenMenu();assert(popupBinds==1)
menu.list.GetOwnerRegion=function() return native end
menu:OpenMenu();assert(popupBinds==1,'foreign popup adopted')
local canvas=Object('Frame')
local w={type='BlizOptionsGroup',frame=canvas,children={}}
local b={type='Button',frame=Button(canvas),disabled=false};b.text=b.frame.Text
local check={type='CheckBox',frame=Object('Frame',canvas),children={}}
check.text=Text(check.frame);check.checkbg=check.frame:CreateTexture(nil,'BACKGROUND');check.check=check.frame:CreateTexture(nil,'ARTWORK')
check.SetValue=function(self,value) self.check:SetShown(value);return value end
check.SetDisabled=function(self,value) self.disabled=value end
w.children={b,check}
dialog.BlizOptions.TalentLoadoutManager={w}
assert(dialog:FeedGroup('Foreign',{},w)=='native-feed' and not b.frame.buttonBorder)
local original=b.text.path;local color={b.text:GetTextColor()}
assert(dialog:FeedGroup('TalentLoadoutManager',{},w)=='native-feed')
assert(b.text.path==original and b.text.color[1]==.9 and check.checkbg.alpha==0)
check:SetValue(true);check:SetDisabled(true)
assert(check.check.alpha==0 and check.text.color[1]==.5)
-- No FontObject or font-face operations for pooled controls; release is not
-- gated by the skin toggle, and native values/action callbacks remain intact.
local alloc,hooks,fonts=allocated,hookCount,fontWrites
for _=1,100 do
    gui:Release(b);gui:Release(check)
    dialog:FeedGroup('TalentLoadoutManager',{},w)
end
assert(allocated==alloc and hookCount==hooks and fontWrites==fonts,'pooled reuse grew objects/hooks/fonts')
enabled=false;gui:Release(b);gui:Release(check)
assert(b.text.path==original and b.text.color[1]==color[1] and check.checkbg.alpha==1 and check.check.alpha==1)
local before=allocated;dialog:FeedGroup('TalentLoadoutManager',{},w);assert(allocated==before)
enabled=true
-- Shared confirmation dialog keeps text/fonts and restores its art on hide.
StaticPopup1=Object('Frame',UIParent);StaticPopup1.which=side.createDialogName
StaticPopup1.art=StaticPopup1:CreateTexture(nil,'BACKGROUND');StaticPopup1.button1=Button(StaticPopup1)
StaticPopup_Show();assert(StaticPopup1.art.alpha==0)
StaticPopup1:Hide();if StaticPopup1.scripts.OnHide then StaticPopup1.scripts.OnHide(StaticPopup1) end
assert(StaticPopup1.art.alpha==1)
StaticPopup1:Show();StaticPopup1.which='FOREIGN';StaticPopup_Show();assert(StaticPopup1.art.alpha==1)
-- Warm row initializers are local; they never traverse the options/talent tree.
local a,h,c,r=allocated,hookCount,childReads,regionReads
for i=1,1000 do side:OnListElementInitialized(row,'dynamic-'..i) end
assert(allocated==a and hookCount==h and childReads==c and regionReads==r)
combat=true;local writes=fontWrites;fontFace="DeferredTheme";module.refresh();assert(fontWrites==writes)
combat=false
for _,event in ipairs(events) do if event.scripts.OnEvent then event.scripts.OnEvent(event,'PLAYER_REGEN_ENABLED') end end
assert(fontWrites>writes)
fontFace='NewTheme';accent=.7;for _,fn in ipairs(looks) do fn() end
assert(f.Title.path=='NewTheme' and f.Title.color[1]==.7 and d.AutoApplyCheckbox.checkedArt.color[1]==.7)
assert(#errors==0,table.concat(errors,'\n'))
print('PASS: Talent Loadout Manager: late sidebars/imports, native actions/colours/opacity, Ace reuse/font safety, popup ownership, combat/theme and 1000 local row updates')
