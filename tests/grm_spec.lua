-- Source-shaped GRM construction helpers, pooled menus and native action lifecycles.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'GuildRosterManager'); factory = fn end
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
    function f:GetChildren() self.walks=(self.walks or 0)+1; return table.unpack(self.children) end
    function f:GetNumChildren() return #self.children end
    function f:GetNumRegions() return #self.regions end
    function f:GetName() return self.name end
    function f:GetParent() return self.parent end
    function f:GetBackdrop() return self.backdrop end
    function f:LockHighlight() self.locked=true end
    function f:UnlockHighlight() self.locked=false end
    function f:IsHighlightLocked() return self.locked == true end
    function f:SetHighlightTexture(v)
        if type(v)=='table' then self.highlight=v
        elseif not self.highlight then self.highlight=self:CreateTexture(nil,'HIGHLIGHT') end
        self.highlight.texture=v
    end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:GetFont() return self.path,self.size,self.flags end
    function f:SetFont(path,size,flags) self.path,self.size,self.flags=path,size,flags end
    function f:SetFontObject() self.path='Native'; self.size=15; self.flags='' end
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
    function f:SetPoint(...) if not ATT_PERF_FIXTURE then self.point={...} end end
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
        local t=Object('FontString'); self.regions[#self.regions+1]=t; return t
    end
    function f:RegisterObject(o) self.Objects=self.Objects or {}; self.Objects[#self.Objects+1]=o end
    function f:SetBackdrop(v) self.backdrop=v end
    if parent then parent.children[#parent.children+1]=f end
    return f
end
CreateFrame = function(kind,_,parent) local f=Object(kind,parent); events[#events+1]=f; return f end
local function Text(parent)
    local f=Object('FontString'); parent.regions[#parent.regions+1]=f; return f
end
local S = {GetFont=function() return fontFace,'' end, GetAccentColor=function() return accent,0.6,0.8 end,
    GetPanelColor=function() return 0.06,0.06,0.07,0.95 end, OnLooksChanged=function(fn) looks[#looks+1]=fn end}
S.Font=function(f) assert(not combat); fontWrites=fontWrites+1; f:SetFont(fontFace, f.size, '') end
S.Panel=function(f) if not f.panel then f.panel=true; f:CreateTexture(nil,'BACKGROUND') end end
S.Inset=function(f) f.inset=true end
S.FadeNineSlice=function(f) f.faded=true end
S.Tab=function(f) f.tab=true end
S.SetTabSelection=function(f,v) f.selected=v end
S.ScrollBar=function(f) f.scroll=true end
S.CloseButton=function(f) f.close=true end
S.Checkbox=function(f) checkboxPaints=checkboxPaints+1; f.check=true end
S.Button=function(f) f.button=true end
S.EditBox=function(f) f.input=true end
S.Dropdown=function(f) f.dropdown=true end
S.StateButtonLabel=function(f) f.stateLabel=true end
S.PageButton=function(f,glyph) f.glyph=glyph end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
assert(loadfile('EUIAddonSkins/Skins/GuildRosterManager.lua'))('EUIAddonSkins',ns)
assert(not module and factory, 'implementation must be deferred')
GRM_UI, GRM = nil, nil; factory(); assert(not module.available())
UIParent=Object('Frame'); UIParent.name='UIParent'
GameTooltip=Object('GameTooltip',UIParent)
CommunitiesFrame=Object('Frame',UIParent)
local function Named(kind, name, parent)
    local f=Object(kind,parent); f.name=name
    if parent then parent[name]=f end
    return f
end
local function Button(name,parent,custom)
    local b=Named('Button',name,parent)
    local label=Text(b)
    if custom then b[name..'Text']=label else b.Text=label end
    b.highlight=b:CreateTexture(nil,'HIGHLIGHT')
    b.scripts.OnClick=function(_,key) b.clicks=(b.clicks or 0)+1; return key,'native-return' end
    return b,label
end
local function Slider(name,parent)
    local f=Named('Slider',name,parent); f.thumb=Object('Texture'); f.track=f:CreateTexture(nil,'BACKGROUND')
    f.ScrollUpButton=Button(name..'ScrollUpButton',f)
    f.ScrollDownButton=Button(name..'ScrollDownButton',f)
    f.scripts.OnValueChanged=function(_,value) f.value=value; return 'native-scroll' end
    return f
end
local root=Named('Frame','GRM_RosterChangeLogFrame',UIParent)
-- Modern TranslucentFrameTemplate can have no BackdropTemplate API/backdrop.
root.NineSlice=Named('Frame','NineSlice',root)
local check=Named('CheckButton','GRM_TestCheckButton',root)
check.checked=true; check.checkedArt=Object('Texture'); check.disabledArt=Object('Texture')
check.Text=Text(check)
check.scripts.OnClick=function(self) self.checked=not self.checked end
local action,actionLabel=Button('GRM_ActionButton',root,true)
local semantic=Text(root); semantic.color={0.3,0.7,0.1,1}
local scroll=Slider('GRM_LogScrollFrameSlider',root)
local first=Button('GRM_GeneralTab',root); first:LockHighlight()
local second=Button('GRM_ScanTab',root)
local editor=Named('EditBox','GRM_LogTextEditor',root)
editor.IsMultiLine=function() return true end; editor.text='unchanged guild export'
local swatch=Named('Frame','GRM_ColorPickerSwatch',root); swatch.backdrop={bgFile='class colour'}
local art=Named('Button','GRM_ClassIcon',root); art.Icon=art:CreateTexture(nil,'ARTWORK'); art.Icon.texture='class-icon'
local protected=Named('Frame','GRM_Protected',root); protected.protected=true
local protectedText=Text(protected)
local tooltip=Named('GameTooltip','GRM_Tooltip',root); tooltip.Text=Text(tooltip)
local launch=Button('GRM_LoadLogButton',CommunitiesFrame)
local phaseCalls=0
GRM_UI={GRM_RosterChangeLogFrame=root,GRM_LoadLogButton=launch,GRM_LoadLogButtonText=launch.Text}
-- Construction helpers return native results and preserve scripts. No guild data
-- operations are required for visual discovery.
GRM_UI.CreateButton=function(name,parent)
    if not parent[name] then Button(name,parent,true) end
    parent[name][name..'Text']:SetFont('Native',14,'')
    return 'factory-return',17
end
GRM_UI.CreateCoreFrame=function(name,parent)
    local f=Named('Frame',name,UIParent); parent[name]=f; f.backdrop={bgFile='native'}
end
GRM_UI.CreateString=function(name,parent)
    parent[name]=Text(parent); parent[name]:SetFont('Native',16,'')
end
GRM_UI.CreateRadialButtons=function(name,parent)
    for i=1,2 do
        local r=Named('CheckButton',name..'Radial'..i,parent); r.checkedArt=Object('Texture')
        r.scripts.OnClick=function(self)
            for j=1,2 do parent[name..'Radial'..j].checked=j==i end
        end
    end
end
GRM_UI.CreateHybridScrollFrame=function(name,parent) Slider(name..'Slider',parent) end
GRM_UI.CreateDropDownMenu=function(name,parent)
    local s=Named('Frame',name..'Selected',parent); s.backdrop={bgFile='native'}
    s.Text=Text(s); s.result=1
    s.scripts.OnMouseDown=function(self) self.opened=true; return 'native-dropdown' end
    local m=Named('Frame',name..'Menu',s); parent[name..'Menu']=m; m.backdrop={bgFile='native'}
    m.Buttons={}; GRM_UI.BuildDropDownOptions({'One','Two'},m,s)
end
GRM_UI.BuildDropDownOptions=function(list,menu,selector)
    for i,title in ipairs(list) do
        local row=menu.Buttons[i]
        if not row then
            local b=Named('Button','GRM_DropdownRow'..i,menu)
            row={b,Text(b)}; menu.Buttons[i]=row
        end
        row[2]:SetFont('Native',12,''); row[2]:SetText(title)
        row[1]:SetHighlightTexture('native highlight')
        row[1].scripts.OnClick=function() selector.result=i; return 'selected' end
    end
    return 'menu-return'
end
GRM_UI.ReloadAllFrames=function() phaseCalls=phaseCalls+1; return 'reload-result' end
GRM_R={BuildRosterFrames=function()
    GRM_UI.GRM_RosterFrame=Named('Frame','GRM_RosterFrame',UIParent)
    GRM_UI.GRM_RosterFrame.backdrop={bgFile='native'}
    Button('GRM_RosterAction',GRM_UI.GRM_RosterFrame,true)
    return 'roster-return'
end}
GRM={Export={LoadExportUI=function()
    GRM_UI.GRM_ExportLogBorderFrame=Named('Frame','GRM_ExportLogBorderFrame',UIParent)
    GRM_UI.GRM_ExportLogBorderFrame.NineSlice=Named('Frame','NineSlice',GRM_UI.GRM_ExportLogBorderFrame)
    return 'export-return'
end},OptionTabFrameControl=function(tab)
    for _,b in ipairs({first,second}) do if b~=tab then b:UnlockHighlight() end end
    return 'tab-return'
end, Kick=function() error('skinning must not invoke guild actions') end}
assert(module.available()); module.install(S,module); Flush()
assert(root.panel and root.NineSlice.faded and #root.children>0)
assert(CommunitiesFrame.panel==nil and UIParent.panel==nil and GameTooltip.panel==nil)
assert(launch.button and launch.Text.path=='EUI')
assert(action.button and actionLabel.path=='EUI')
assert(action.scripts.OnClick(action,'LeftButton')=='LeftButton' and action.clicks==1)
assert(semantic.path=='EUI' and semantic.color[2]==0.7, 'semantic guild colours changed')
assert(protectedText.path=='Native' and tooltip.Text.path=='Native')
assert(editor.text=='unchanged guild export' and not editor.input, 'native editor was restyled destructively')
assert(swatch.backdrop.bgFile=='class colour' and not swatch.panel and art.Icon.texture=='class-icon')
assert(check.check and check.checkedArt.color[1]==accent and check.checked)
check.scripts.OnClick(check); assert(not check.checked)
assert(scroll.thumb.width==5 and scroll.width==16 and scroll.thumb.height==20)
assert(scroll.ScrollUpButton.glyph=='^' and scroll.ScrollDownButton.glyph=='v')
assert(scroll.scripts.OnValueChanged(scroll,37)=='native-scroll' and scroll.value==37)
assert(scroll.ScrollUpButton.scripts.OnClick(scroll.ScrollUpButton,'LeftButton')=='LeftButton')
assert(first.selected and not second.selected)
second:LockHighlight(); assert(GRM.OptionTabFrameControl(second)=='tab-return')
assert(second.selected and not first.selected and second.locked and not first.locked)
-- Native font refreshes retain their new size and colour without deferred flashes.
actionLabel:SetFont('Native',19,'OUTLINE')
assert(actionLabel.path=='EUI' and actionLabel.size==19)
semantic:SetFontObject('GameFontNormal'); assert(semantic.path=='EUI' and semantic.size==15 and semantic.color[2]==0.7)
local a,b=GRM_UI.CreateButton('GRM_LazyButton',root); assert(a=='factory-return' and b==17)
assert(root.GRM_LazyButton.button and root.GRM_LazyButton.GRM_LazyButtonText.path=='EUI')
GRM_UI.CreateCoreFrame('GRM_Dialog',GRM_UI); Flush(); assert(GRM_UI.GRM_Dialog.panel)
GRM_UI.CreateString('GRM_NewLabel',root); assert(root.GRM_NewLabel.path=='EUI')
GRM_UI.CreateRadialButtons('GRM_Mode',root); GRM_UI.CreateHybridScrollFrame('GRM_LazyScroll',root); Flush()
assert(root.GRM_ModeRadial1.check and root.GRM_LazyScrollSlider.thumb.width==5)
root.GRM_ModeRadial2.scripts.OnClick(root.GRM_ModeRadial2)
assert(root.GRM_ModeRadial2.checked and not root.GRM_ModeRadial1.checked)
GRM_UI.CreateDropDownMenu('GRM_Filter',root); Flush()
local menu,selector=root.GRM_FilterMenu,root.GRM_FilterSelected
assert(menu.panel and selector.panel and menu.Buttons[1][2].path=='EUI')
assert(selector.scripts.OnMouseDown(selector)=='native-dropdown' and selector.opened)
assert(menu.Buttons[2][1].scripts.OnClick()=='selected' and selector.result==2)
local stableObjects,stableHooks=allocated,hookCount
for i=1,100 do
    assert(GRM_UI.BuildDropDownOptions({'One','Two'},menu,selector)=='menu-return')
    assert(menu.Buttons[1][2].path=='EUI' and menu.Buttons[1][1].highlight.color[4]==0.10)
end
assert(allocated==stableObjects and hookCount==stableHooks, 'pooled menu refresh created objects/hooks')
-- Settle the changed root child count after the factory construction burst.
root.scripts.OnShow(root)
stableObjects,stableHooks=allocated,hookCount
local walks=root.walks; local writes=fontWrites
for i=1,100 do root.scripts.OnShow(root) end
assert(root.walks==walks and fontWrites==writes and allocated==stableObjects, 'warm root re-scanned/repainted')
-- A newly built child is discovered without forcing a guild refresh.
local dynamic=Button('GRM_DynamicAction',root,true)
root.scripts.OnShow(root); assert(dynamic.button)
Flush(); assert(GRM.Export.LoadExportUI()=='export-return' and GRM_UI.GRM_ExportLogBorderFrame.panel)
assert(GRM_R.BuildRosterFrames()=='roster-return' and GRM_UI.GRM_RosterFrame.GRM_RosterAction.button)
assert(GRM_UI.ReloadAllFrames()=='reload-result' and phaseCalls==1)
Flush()
local objectsBefore=allocated
fontFace='OtherEUI'; accent=0.65; looks[1](); Flush()
assert(semantic.path=='OtherEUI' and check.checkedArt.color[1]==0.65 and allocated==objectsBefore)
enabled=false
local hidden=GRM_UI.CreateButton('GRM_DisabledAction',root)
assert(not root.GRM_DisabledAction.button)
local beforeWrites=fontWrites
root.scripts.OnShow(root); module.refresh(); Flush(); assert(fontWrites==beforeWrites)
enabled=true; combat=true
GRM_UI.CreateButton('GRM_CombatAction',root); module.refresh(); Flush()
assert(not root.GRM_CombatAction.button)
combat=false
for _,event in ipairs(events) do
    if event.events and event.events.PLAYER_REGEN_ENABLED then event.scripts.OnEvent(event,'PLAYER_REGEN_ENABLED') end
end
Flush(); assert(root.GRM_CombatAction.button and root.GRM_DisabledAction.button)
print('BENCH GRM simulation: 100 pooled menu rebuilds add 0 objects/hooks; 100 warm root shows add 0 child scans/font writes')
local before=checkboxPaints
for _,event in ipairs(events) do
    if event.events and event.events.ADDON_LOADED then event.scripts.OnEvent(event,'ADDON_LOADED','UnrelatedAddon') end
end
Flush(); assert(checkboxPaints==before)
assert(#errors==0,table.concat(errors,'\n'))
print('PASS: GRM factories, pooled menus, clean checks, tabs, lazy windows, font resets, native actions, cached warm shows, theme/disabled/combat gates')
