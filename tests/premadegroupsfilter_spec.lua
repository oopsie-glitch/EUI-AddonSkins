-- PGF native filters, recycled menus/settings rows, bounded warm refreshes.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'PremadeGroupsFilter'); factory = fn end
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
    function f:SetFontObject() self.path='Native'; self.size=15; self.flags='' end
    function f:GetTextColor() return table.unpack(self.color) end
    function f:SetTextColor(r,g,b,a) self.color[1],self.color[2],self.color[3],self.color[4]=r,g,b,a end
    function f:GetAlpha() return self.alpha end
    function f:SetAlpha(v) self.alpha=v end
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
assert(loadfile('EUIAddonSkins/Skins/PremadeGroupsFilter.lua'))('EUIAddonSkins',ns)
assert(factory and not module)
local before=allocated; factory(); assert(not module.available() and allocated==before)
UIParent=Object('Frame')
local function Button(parent)
    local f=Object('Button',parent); f.Text=Text(f); f.scripts.OnClick=function() f.clicks=(f.clicks or 0)+1; return 'native-click' end
    return f
end
local function Check(parent)
    local f=Object('CheckButton',parent); f.width,f.height=32,32
    f.checkedArt=Object('Texture'); f.disabledArt=Object('Texture'); f.checked=true
    f.scripts.OnClick=function() f.checked=not f.checked; return 'native-filter' end
    return f
end
local function Panel()
    local f=Object('Frame',PremadeGroupsFilterDialog)
    f.Act=Check(f); f.Title=Text(f)
    f.Min=Object('EditBox',f); f.Min.text='1200'; f.Min.scripts.OnTextChanged=function(self) return self.text end
    f.DropDown=Object('Frame',f)
    for _,k in ipairs({'Left','Middle','Right'}) do f.DropDown[k]=f.DropDown:CreateTexture() end
    f.DropDown.Text=Text(f.DropDown); f.DropDown.Button=Button(f.DropDown)
    f.DropDown.Button:SetNormalTexture('native-down')
    return f
end
PremadeGroupsFilter={Debug={PopupMenu_Initialize=function() return 'native-menu' end}}
PremadeGroupsFilterDialog=Object('Frame',UIParent)
local dialog=PremadeGroupsFilterDialog
function dialog:RegisterPanel(id,panel) self.panels[id]=panel; return 'registered' end
function dialog:SwitchToPanel() return 'native-switch' end
PremadeGroupsFilterDialog.panels={}
dialog.CloseButton=Button(dialog); dialog.RefreshButton=Button(dialog)
dialog.MaximizeMinimizeFrame=Object('Frame',dialog)
dialog.MaximizeMinimizeFrame.MaximizeButton=Button(dialog.MaximizeMinimizeFrame)
local panel=Panel(); dialog.panels.dungeon=panel; dialog.activePanel=panel
local delve=Panel(); delve.isAvailable=true; delve.Title.color={1,0.82,0,1}; dialog.panels.delve=delve
UsePGFButton=Check(UIParent)
local popup=Object('Frame',UIParent); popup.Buttons={Button(popup),Button(popup)}; popup.Shadow=popup:CreateTexture()
PremadeGroupsFilter.PopupMenuFrame=popup
PremadeGroupsFilterStaticPopup=Object('Frame',UIParent)
PremadeGroupsFilterStaticPopup.Border=Object('Frame',PremadeGroupsFilterStaticPopup)
PremadeGroupsFilterStaticPopup.Button1=Button(PremadeGroupsFilterStaticPopup)
PremadeGroupsFilterSettingsFrame=Object('Frame',UIParent)
local settings=PremadeGroupsFilterSettingsFrame
settings.ScrollBox=Object('Frame',settings); settings.ScrollBar=Object('Frame',settings)
local view={}
function view:RegisterCallback(event,fn,owner) assert(event=='OnInitializedFrame' and not self.fn); self.fn,self.owner=fn,owner end
function settings.ScrollBox:GetView() return view end
local rows={Object('Frame',settings.ScrollBox)}; rows[1].CheckBox=Check(rows[1])
function settings.ScrollBox:ForEachFrame(fn) for _,f in ipairs(rows) do fn(f) end end
S.Shell=function(f) f.shell=true end
S.FadeRegions=function(f) f.faded=true end
module.skin=S; module.install(S,module); Flush()
assert(dialog.shell and dialog.CloseButton.close and panel.Act.check)
assert(panel.Act.width==32 and panel.Act.checkFill.width==14 and panel.Act.checkedArt.width==10)
assert(delve.Title.color[1]==1 and delve.Title.color[2]==0.82,'bountiful Delve status lost')
assert(panel.Min.input and panel.Min.text=='1200' and panel.Min.scripts.OnTextChanged(panel.Min)=='1200')
assert(panel.DropDown.Text.path=='EUI' and panel.DropDown.Button.normal.alpha==0)
assert(panel.DropDown.Button.scripts.OnClick()=='native-click')
assert(panel.Act.scripts.OnClick()=='native-filter' and not panel.Act.checked)
assert(rows[1].CheckBox.check and settings.ScrollBar.scroll and view.fn)
assert(PremadeGroupsFilterStaticPopup.Border.faded and PremadeGroupsFilterStaticPopup.Button1.button)
local reads, regions, objects, hooks, fonts=childReads,regionReads,allocated,hookCount,fontWrites
for i=1,100 do dialog:Show(); dialog:SwitchToPanel() end
Flush()
assert(childReads==reads and regionReads==regions and allocated==objects and hookCount==hooks and fontWrites==fonts,'warm window traversal/allocation')
local dynamic=Panel(); assert(dialog:RegisterPanel('delve',dynamic)=='registered' and dynamic.Act.check)
local row=Object('Frame',settings.ScrollBox); row.CheckBox=Check(row); rows[#rows+1]=row
view.fn(view.owner,row); assert(row.CheckBox.check,'new settings row missing')
objects,hooks,reads=allocated,hookCount,childReads
for i=1,100 do view.fn(view.owner,row) end
assert(allocated==objects and hookCount==hooks and childReads==reads,'recycled settings row rescanned')
local extra=Button(popup); popup.Buttons[#popup.Buttons+1]=extra
extra.Text:SetFont('Native',12,''); assert(PremadeGroupsFilter.Debug.PopupMenu_Initialize()=='native-menu'); Flush()
assert(extra.button and extra.Text.path=='EUI')
extra.Text:SetFont('Native',12,''); popup:Show(); assert(extra.Text.path=='EUI','reopened dropdown reset its font')
local click=dialog.RefreshButton.scripts.OnClick; dialog.RefreshButton:Disable(); module.refresh(); Flush()
assert(dialog.RefreshButton.Text.color[1]==0.5 and dialog.RefreshButton.scripts.OnClick==click)
dialog.RefreshButton:Enable(); module.refresh(); assert(dialog.RefreshButton.Text.color[1]==0.92)
fontFace='NewTheme'; accent=0.8; for _,fn in ipairs(looks) do fn() end; Flush()
assert(panel.Title.path=='NewTheme' and panel.Act.checkedArt.color[1]==0.8)
local protected=Panel(); protected.protected=true; dialog:RegisterPanel('protected',protected)
assert(not protected.Act.check,'protected subtree styled')
combat=true
local late=Panel(); dialog:RegisterPanel('raid',late); view.fn(view.owner,row); assert(not late.Act.check)
for _,fn in ipairs(looks) do fn() end
combat=false; for _,f in ipairs(events) do if f.scripts.OnEvent then f.scripts.OnEvent(f,'PLAYER_REGEN_ENABLED') end end; Flush()
assert(late.Act.check,'combat deferred panel not recovered')
enabled=false
local absent=Panel(); dialog:RegisterPanel('arena',absent); objects=allocated
module.refresh(); popup:Show(); view.fn(view.owner,absent); Flush()
assert(not absent.Act.check and allocated==objects,'disabled skin did work')
assert(#errors==0,table.concat(errors,'\n'))
PremadeGroupsFilter,PremadeGroupsFilterDialog,PremadeGroupsFilterStaticPopup,PremadeGroupsFilterSettingsFrame,UsePGFButton=nil,nil,nil,nil,nil
print('PASS: PGF native actions/values, compact checks, dynamic panels/menus/settings, cached warm opens, theme, combat and disabled gating')
