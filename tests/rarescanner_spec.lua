-- RareScanner secure-alert cosmetics, Explorer and reversible shared Ace options.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local menuBindings, dialogStyles=0,0
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'RareScanner'); factory = fn end
ns.RegisterModule = function(id, _, available, install) module = {id=id, available=available, install=install} end
ns.BindPopupList=function(_,_,owner,list) assert(owner==list.dropdown); menuBindings=menuBindings+1 end
ns.BindPopupOwner=function(_,_,owner) owner.popupOwner=true end
ns.RefreshPopupMenusNow=function() end
ns.StyleTextureDialog=function(_,_,popup,active) dialogStyles=dialogStyles+1; popup.styled=active end
MSA_ToggleDropDownMenu=function() return 'native-menu' end
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
    function f:SetParent(p) self.parent=p end
    function f:GetParent() parentReads=parentReads+1; return self.parent end
    function f:GetBackdrop() return self.backdrop end
    function f:GetBackdropColor() return table.unpack(self.bg or {0.2,0.2,0.2,1}) end
    function f:GetBackdropBorderColor() return table.unpack(self.edge or {0.5,0.1,0.8,1}) end
    function f:SetBackdropColor(...) self.bg={...} end
    function f:SetBackdropBorderColor(...) self.edge={...} end
    function f:GetVertexColor() return table.unpack(self.vertex or {1,1,1,1}) end
    function f:GetTexCoord() return table.unpack(self.coords or {0,1,0,1}) end
    function f:GetNumPoints() return self.point and 1 or 0 end
    function f:GetPoint() return table.unpack(self.point or {}) end
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
    function f:SetGradientAlpha(...) self.gradient={...} end
    function f:SetRotation(v) self.rotation=v end
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
    function f:Hide() self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
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
S.SquareIcon=function(t) t:SetTexCoord(0.08,0.92,0.08,0.92) end
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

assert(loadfile('EUIAddonSkins/Skins/RareScanner.lua'))('EUIAddonSkins',ns)
RARESCANNER_BUTTON,RSExplorerFrame=nil,nil
assert(factory and not module)
local before=allocated; factory(); assert(not module.available() and before==allocated)
UIParent=Object('Frame')
local function Button(parent)
    local f=Object('Button',parent); f.Text=Text(f); f.Text.color={0.9,0.9,0.9,1}
    f.scripts.OnClick=function() return 'native-action' end; return f
end
RARESCANNER_BUTTON=Object('Button',UIParent)
local scanner=RARESCANNER_BUTTON
scanner.protected=true; scanner.attributes={type1='macro',macrotext='/targetexact rare'}
function scanner:SetAttribute() error('skin touched secure attributes') end
function scanner:GetChildren() error('secure alert hierarchy traversed') end
scanner.backdrop={edgeFile='native'}; scanner.normal=scanner:CreateTexture(nil,'BACKGROUND'); scanner.normal:SetTexture('native-paper')
scanner.Title=Text(scanner); scanner.Title.text='Native rare title'
scanner.CloseButton=Button(scanner)
scanner.FilterEntityButton=Button(scanner); scanner.FilterEntityButton:SetNormalTexture('native-stop')
scanner.UnFilterEntityButton=Button(scanner); scanner.UnFilterEntityButton:SetNormalTexture('native-skull')
for _,k in ipairs({'PreviousButton','NextButton'}) do
    scanner[k]=Object('Frame',scanner); scanner[k].Texture=scanner[k]:CreateTexture(nil,'ARTWORK')
    scanner[k].scripts.OnMouseDown=function() return 'native-navigation' end
end
scanner.ModelView=Object('PlayerModel',scanner); scanner.ModelView.displayID=123
function scanner:ShowButton() self:Show(); return 'native-alert' end
local rootFrame=CreateFrame('Frame','RSExplorerFrame',UIParent)
local explorer=rootFrame
-- Retail DropdownButton mixins report Button, not DropdownButton. The named
-- XML controls include native red atlas resets and ChatConfig check buttons.
explorer.Filters=Object('Frame',explorer)
local filters=explorer.Filters
for _,key in ipairs({'FilterDropDown','ContinentDropDown'}) do
    local button=Button(filters);filters[key]=button
    button.SetupMenu=function() return 'native-menu-setup' end
    button.OnMenuOpened=function() return 'native-menu-opened' end
end
local rescan=Button(filters);filters.RestartScanningButton=rescan
rescan.normal=rescan:CreateTexture(nil,'ARTWORK');rescan.normal:SetTexture('128-RedButton')
rescan.scripts.OnShow=function() rescan.normal:SetAlpha(1) end
rescan.scripts.OnEnter=function() rescan.normal:SetAlpha(1) end
rescan.scripts.OnClick=function() return 'native-rescan',nil,42 end
local function NativeCheck(parent)
    local check=Object('CheckButton',parent);check:SetSize(32,32);check.Text=Text(check)
    check.checkedArt=check:CreateTexture(nil,'ARTWORK');check.checkedArt:SetTexture('native-tick')
    check.disabledArt=check:CreateTexture(nil,'ARTWORK');check:SetChecked(true)
    check.scripts.OnClick=function() check:SetChecked(not check:GetChecked());return 'native-check' end
    return check
end
filters.LockCurrentZoneCheckButton=NativeCheck(filters)
explorer.Control=Object('Frame',explorer)
explorer.Control.AutoFilterCheckButton=NativeCheck(explorer.Control)
explorer.Control.CreateProfilesBackupCheckButton=NativeCheck(explorer.Control)
explorer.Control.ApplyFiltersButton=Button(explorer.Control)
explorer.ScanRequired=Object('Frame',explorer)
explorer.ScanRequired.StartScanningButton=Button(explorer.ScanRequired)
function filters:Initialize() return 'native-filters-init' end
local explorerMenuManager={OpenMenu=function() return 'native-menu' end,GetOpenMenu=function(self) return self.list end}
Menu={GetManager=function() return explorerMenuManager end}
explorer.Border=Object('Frame',explorer); explorer.Border.art=explorer.Border:CreateTexture(nil,'OVERLAY')
explorer.RareInfo=Object('Frame',explorer); explorer.RareInfo.BaseFrameBackground=explorer.RareInfo:CreateTexture(nil,'BACKGROUND')
explorer.RareInfo.Name=Text(explorer.RareInfo); explorer.RareInfo.Name.color={0.2,1,0.2,1}
explorer.RareInfo.Map=Object('Frame',explorer.RareInfo)
function explorer.RareInfo.Map:GetChildren() error('map tiles scanned') end
explorer.RareInfo.Mounts=Object('Frame',explorer.RareInfo)
explorer.RareInfo.Mounts.Background1=explorer.RareInfo.Mounts:CreateTexture(nil,'BACKGROUND')
explorer.RareInfo.Mounts.Texture=explorer.RareInfo.Mounts:CreateTexture(nil,'BACKGROUND'); explorer.RareInfo.Mounts.Texture:SetTexture('native-mount-category')
explorer.RareNPCList=Object('Frame',explorer)
explorer.RareNPCList.scrollBox=Object('Frame',explorer.RareNPCList)
explorer.RareNPCList.scrollBar=Object('Frame',explorer.RareNPCList)
local listView={}
function listView:RegisterCallback(event,fn,owner) assert(event=='OnInitializedFrame' and not self.fn); self.fn,self.owner=fn,owner end
function explorer.RareNPCList.scrollBox:GetView() return self.view end
function explorer.RareNPCList:Initialize() self.scrollBox.view=listView; return 'native-list-init' end
local row=Object('Button',explorer.RareNPCList.scrollBox)
row.Name=Text(row); row.Name.color={1,0.1,0.1,1}
row.BG=row:CreateTexture(nil,'BACKGROUND'); row.Selected=row:CreateTexture(nil,'BACKGROUND'); row.Selected:Hide()
row.MountTexture=row:CreateTexture(nil,'BACKGROUND'); row.MountTexture:SetTexture('native-collectible')
function listView:ForEachFrame(fn) fn(row) end
local rowPasses=0
function explorer.RareNPCList.scrollBox:ForEachFrame(fn)
    rowPasses=rowPasses+1
    return self:GetView():ForEachFrame(fn)
end
explorer.CustomLoot=Object('Frame',explorer)
local custom=explorer.CustomLoot
custom.GroupList=Object('Frame',custom); custom.GroupList.ScrollBox=Object('Frame',custom.GroupList)
local groupView={}
local groupRow=Object('Button',custom.GroupList.ScrollBox); groupRow.Name=Text(groupRow)
function groupView:RegisterCallback(event,fn,owner) assert(event=='OnInitializedFrame' and not self.fn); self.fn,self.owner=fn,owner end
function groupView:ForEachFrame(fn) fn(groupRow) end
function custom.GroupList.ScrollBox:GetView() return self.view end
function custom.GroupList.ScrollBox:ForEachFrame(fn)
    rowPasses=rowPasses+1
    return self:GetView():ForEachFrame(fn)
end
function custom:Initialize() self.GroupList.ScrollBox.view=groupView; return 'native-group-init' end
function explorer.RareNPCList:OnElementInitialize(element) element.Name:SetText('Rare'); return 'native-row' end
function explorer:Initialize() return 'native-explorer' end
local loot=Object('Frame',explorer.RareInfo); loot.Icon=loot:CreateTexture(); loot.Icon:SetTexture('native-item')
loot.IconOverlay=loot:CreateTexture(); loot.IconOverlay.color={1,0.1,0.1,1}
explorer.lootItemsPool={EnumerateActive=function() return next,{[loot]=true},nil end}
local gui={Release=function(_,widget) if widget.OnRelease then widget:OnRelease() end; widget.frame:Hide(); widget.frame:SetParent(UIParent); return 'native-release' end}
local dialog={OpenFrames={},BlizOptions={['RareScanner General']={}}}
function dialog:FeedGroup(id,_,container) self.feeds=(self.feeds or 0)+1; return 'native-feed',container,id end
local targetApp={SetupOptions=function() return "native-setup" end}
local libDialog={}
function libDialog:Spawn(reference,data)
    self.last=Object('Frame',UIParent);self.last.Text=Text(self.last)
    self.last.buttons={Button(self.last),Button(self.last)}
    return self.last
end
function libDialog:ActiveDialog() return self.last end
LibStub=function(id,silent)
    assert(silent)
    if id=='AceConfigDialog-3.0' then return dialog elseif id=='AceGUI-3.0' then return gui elseif id=='LibDialog-1.0RS' then return libDialog elseif id=='AceAddon-3.0' then return {GetAddon=function(_,id,quiet) assert(id=='RareScanner' and quiet); return targetApp end} end
end
RSLootMixin={AddItem=function(self,id) self.itemID=id; return 'native-item' end}
assert(module.available()); module.install(S,module); Flush()
assert(#errors==0 and rowPasses==0, 'cold Explorer must not iterate ScrollBoxes without a view')
assert(not listView.fn and not groupView.fn, 'callbacks must wait for native views')
assert(explorer.RareNPCList:Initialize()=='native-list-init')
assert(listView.fn and row.Name.path=='EUI', 'late rare-list initialization must style existing rows')
assert(custom:Initialize()=='native-group-init')
assert(groupView.fn and groupRow.Name.path=='EUI', 'late custom-group initialization must style existing rows')
local lateGroupRow=Object('Button',custom.GroupList.ScrollBox); lateGroupRow.Name=Text(lateGroupRow)
groupView.fn(groupView.owner,lateGroupRow); assert(lateGroupRow.Name.path=='EUI')
-- A temporarily cleared native view must be safe on subsequent refreshes too.
explorer.RareNPCList.scrollBox.view=nil; custom.GroupList.ScrollBox.view=nil
local passes=rowPasses
for i=1,10 do explorer:Show() end
assert(rowPasses==passes and #errors==0, 'refresh iterated a temporarily uninitialized view')
assert(explorer.RareNPCList:Initialize()=='native-list-init')
assert(custom:Initialize()=='native-group-init')
assert(scanner.panel and scanner.backdrop==nil and scanner.attributes.macrotext=='/targetexact rare')
assert(scanner.ModelView.displayID==123 and scanner.CloseButton.scripts.OnClick()=='native-action')
assert(scanner.FilterEntityButton.normal.texture=='native-stop' and scanner.NextButton.scripts.OnMouseDown()=='native-navigation')
assert(explorer.Border.art.alpha==0 and explorer.RareInfo.Mounts.Texture.alpha==1)
assert(row.Name.color[1]==1 and row.Name.color[2]==0.1 and row.Selected.shown==false and row.MountTexture.texture=='native-collectible')
assert(listView.fn and explorer.RareNPCList.scrollBar.scroll and loot.Icon.coords[1]==0.08 and loot.IconOverlay.color[2]==0.1)
local c,r,o,h,w=childReads,regionReads,allocated,hookCount,fontWrites
for i=1,100 do assert(scanner:ShowButton()=='native-alert'); explorer:Show(); listView.fn(listView.owner,row) end
Flush()
assert(childReads==c and regionReads==r and allocated==o and hookCount==h and fontWrites==w,'warm open scanned or allocated')
local newRow=Object('Button',explorer.RareNPCList.scrollBox); newRow.Name=Text(newRow)
listView.fn(listView.owner,newRow); assert(newRow.Name.path=='EUI')
local popup=libDialog:Spawn('RARESCANNER_DELETE_GROUP_CONFIRMATION'); assert(popup.styled and popup.Text.path=='Native')
assert(popup.buttons[1].styled and popup.buttons[2].styled, 'LibDialog buttons[] were not styled')
assert(popup.buttons[1].Text.path=='Native' and popup.buttons[1].scripts.OnClick()=='native-action')
local foreign=libDialog:Spawn('FOREIGN_CONFIRM'); assert(not foreign.styled and not foreign.buttons[1].styled)
assert(filters.FilterDropDown.dropdown and filters.ContinentDropDown.dropdown and filters.FilterDropDown.popupOwner)
assert(filters:Initialize()=='native-filters-init')
assert(rescan.button and rescan.normal.alpha==0)
rescan:Show();rescan.scripts.OnEnter(rescan);assert(rescan.normal.alpha==0,'native atlas reset exposed red button')
local actionResult,actionNil,actionValue=rescan.scripts.OnClick(rescan)
assert(actionResult=='native-rescan' and actionNil==nil and actionValue==42)
local check=filters.LockCurrentZoneCheckButton
local checkHost
for _,child in ipairs(check.children) do if child.width==22 then checkHost=child end end
local checkMark
for _,texture in ipairs(checkHost.regions) do if texture.layer=='OVERLAY' then checkMark=texture end end
assert(check.width==32 and check.height==32 and check.checkedArt.alpha==0 and checkMark.width==8 and checkMark:IsShown())
check.scripts.OnClick(check);assert(not checkMark:IsShown())
check:SetChecked(true);assert(checkMark:IsShown())
local menuList=Object('Frame',UIParent);menuList.dropdown=filters.ContinentDropDown
menuList.GetOwnerRegion=function(self) return self.dropdown end
local desc={IsRadio=function() return true end,AddInitializer=function(self,fn) self.initializers=self.initializers or {};table.insert(self.initializers,fn) end}
local menuRow=Object('Button',menuList)
menuRow.GetFont=function() error('restricted menu text was accessed') end
menuRow.GetElementDescription=function() return desc end
menuRow.leftTexture1=menuRow:CreateTexture(nil,'ARTWORK');menuRow.leftTexture1:SetTexture('native-radio-circle')
menuRow.leftTexture2=menuRow:CreateTexture(nil,'ARTWORK');menuRow.leftTexture2:SetTexture('native-radio-mark')
menuRow.leftTexture2:SetSize(12,12);menuRow.leftTexture2:Hide()
menuRow.arrow=menuRow:CreateTexture(nil,'ARTWORK');menuRow.arrow:SetTexture('native-arrow')
menuList.EnumerateElementDescriptions=function(_,fn) fn(nil,desc) end
explorerMenuManager.list=menuList
assert(explorerMenuManager:OpenMenu()=='native-menu')
assert(menuRow.leftTexture2.width==7 and menuRow.leftTexture2.color[1]==accent and not menuRow.leftTexture2:IsShown())
assert(menuRow.arrow.texture:find('eui%-arrow%-right'))
-- A native response clears cosmetics and runs the appended initializer again.
menuRow.leftTexture1:SetTexture('native-radio-circle');menuRow.leftTexture2:SetTexture('native-radio-mark')
for _,fn in ipairs(desc.initializers) do fn(menuRow,desc,menuList) end
assert(menuRow.leftTexture2.width==7 and #desc.initializers==1)
menuList:Hide();assert(menuRow.leftTexture2.width==12 and menuRow.leftTexture1.texture=='native-radio-circle' and menuRow.arrow.texture=='native-arrow')
menuList:Show();explorerMenuManager:OpenMenu()
local submenu=Object('Frame',UIParent);submenu.dropdown=menuList;submenu.GetOwnerRegion=menuList.GetOwnerRegion
explorerMenuManager.list=submenu;explorerMenuManager:OpenMenu();assert(submenu.dropdown==menuList)
-- Shared menus may be transferred without hiding. Old initializers must not
-- repaint foreign controls, and original marker cosmetics must be restored.
menuList.dropdown=Object('Frame');explorerMenuManager.list=menuList
explorerMenuManager:OpenMenu()
assert(menuRow.leftTexture2.width==12 and menuRow.leftTexture2.texture=='native-radio-mark')
local menuReads,menuObjects,menuHooks=childReads,allocated,hookCount
for _=1,100 do rescan:Show();check:SetChecked(true) end
assert(childReads==menuReads and allocated==menuObjects and hookCount==menuHooks,'warm action/check changes traversed or allocated')
-- Theme updates and native reinitialization must recolour an already-open
-- owned submenu; combat and disable paths must not leak styling to reuse.
menuList.dropdown=filters.FilterDropDown;menuList:Show();explorerMenuManager.list=menuList
explorerMenuManager:OpenMenu()
local oldAccent=accent;accent=.67;module.refresh();Flush()
assert(menuRow.leftTexture2.color[1]==.67 and #desc.initializers==1)
combat=true
local oldColour=menuRow.leftTexture2.color[1]
for _,fn in ipairs(desc.initializers) do fn(menuRow,desc,menuList) end
assert(menuRow.leftTexture2.color[1]==oldColour)
combat=false;enabled=false;module.refresh()
assert(menuRow.leftTexture2.texture=='native-radio-mark' and menuRow.leftTexture2.width==12)
local oldBindings=menuBindings
for _,fn in ipairs(desc.initializers) do fn(menuRow,desc,menuList) end
explorerMenuManager:OpenMenu();assert(menuBindings==oldBindings)
enabled=true;accent=oldAccent;menuList:Hide();explorerMenuManager.list=nil;module.refresh();Flush()
local function Widget(kind,parent)
    local w={type=kind,frame=Object('Frame',parent),children={}}
    w.frame.obj=w; w.OnRelease=function(self) self.releases=(self.releases or 0)+1 end
    return w
end
local root=Widget('BlizOptionsGroup',UIParent)
dialog.BlizOptions['RareScanner General'].settings=root
local check=Widget('CheckBox',root.frame); root.children={check}
check.checkbg=check.frame:CreateTexture(nil,'BACKGROUND'); check.checkbg:SetTexture('native-check-bg'); check.checkbg:SetSize(24,24)
check.check=check.frame:CreateTexture(nil,'ARTWORK'); check.check:SetTexture('native-tick'); check.check:SetSize(24,24)
check.SetValue=function(self,value) self.checked=value; return 'native-value' end
check.SetDisabled=function(self,value) self.disabled=value; return 'native-disabled' end
check.frame:SetSize(200,24)
check.checkbg:SetPoint('TOPLEFT',check.frame,'TOPLEFT',0,0)
check.text=Text(check.frame); check.text:SetPoint('LEFT',check.checkbg,'RIGHT',0,0)
check.image=check.frame:CreateTexture(nil,'ARTWORK')
check.SetLabel=function(self,value) self.text:SetText(value); self.text:SetPoint('LEFT',self.checkbg,'RIGHT',0,0); return 'native-label' end
check.SetImage=function(self,value) self.image:SetTexture(value); self.text:SetPoint('LEFT',self.image,'RIGHT',1,0); return 'native-image' end
local nativePresses=0
check.frame.scripts.OnMouseDown=function() nativePresses=nativePresses+1; check.text:SetPoint('LEFT',check.checkbg,'RIGHT',1,-1) end
check.frame.scripts.OnMouseUp=function() check:SetValue(not check.checked) end
check.text.color={0.7,0.7,0.7,1}; check.checked=true
local action=Widget('Button',root.frame); action.frame.kind='Button'; action.frame.Text=Text(action.frame)
action.text=action.frame.Text; action.text.color={1,0.82,0,1}
action.SetDisabled=function(self,value) self.disabled=value; if value then self.frame:Disable() else self.frame:Enable() end; return 'native-button-state' end
action.Fire=function(self,event) if self.events and self.events[event] then return self.events[event]() end; return 'native-fire' end
table.insert(root.children,action)
action.frame.scripts.OnClick=function() return 'native-option' end
local dropdown=Widget('Dropdown',root.frame); table.insert(root.children,dropdown)
dropdown.dropdown=Object('Frame',dropdown.frame); dropdown.button=Object('Button',dropdown.dropdown)
dropdown.button.normal=dropdown.button:CreateTexture(nil,'ARTWORK'); dropdown.button.normal:SetTexture('native-arrow')
dropdown.button.scripts.OnClick=function() return 'native-dropdown' end
dropdown.button_cover=Object('Button',dropdown.frame)
dropdown.nativeArt=dropdown.dropdown:CreateTexture(nil,'ARTWORK'); dropdown.nativeArt:SetTexture('native-selector-border')
dropdown.text=Text(dropdown.dropdown); dropdown.text.color={0.1,0.7,1,1}
local popup={type='Dropdown-Pullout',frame=Object('Frame',UIParent),items={},userdata={obj=dropdown}}
popup.frame.obj=popup; popup.frame.backdrop={bgFile='native-popup',edgeFile='ornate'}
popup.Open=function(self) self.frame:Show(); return 'native-open',17 end
local popupItem={text=Text(popup.frame)}; popupItem.text.color={0.4,0.5,0.6,1}; popup.items={popupItem}
dropdown.pullout=popup
local inline=Widget('InlineGroup',root.frame); table.insert(root.children,inline)
local inlineBorder=Object('Frame',inline.frame); inlineBorder.backdrop={bgFile='native-inline',edgeFile='bevelled'}
inline.content=Object('Frame',inlineBorder); inline.titletext=Text(inline.frame)
local scroll=Widget('ScrollFrame',root.frame); table.insert(root.children,scroll)
scroll.scrollbar=CreateFrame('Slider','ActualAceScrollbar',scroll.frame); scroll.scrollbar.obj=scroll
scroll.scrollbar.thumb=scroll.scrollbar:CreateTexture(nil,'ARTWORK'); scroll.scrollbar.thumb:SetTexture('native-thumb'); scroll.scrollbar.thumb:SetSize(20,28)
local up=CreateFrame('Button','ActualAceScrollbarScrollUpButton',scroll.scrollbar); up:SetNormalTexture('native-up')
local down=CreateFrame('Button','ActualAceScrollbarScrollDownButton',scroll.scrollbar); down:SetNormalTexture('native-down')
down.scripts.OnClick=function() return 'native-step' end
local tabs=Widget('TabGroup',root.frame); table.insert(root.children,tabs)
tabs.tabs={Object('Button',tabs.frame),Object('Button',tabs.frame)}
for i,tab in ipairs(tabs.tabs) do tab.Text=Text(tab); tab.selected=i==1 end
local media=Widget('LSM30_Sound',root.frame); table.insert(root.children,media)
media.frame.label=Text(media.frame); media.frame.label.color={1,0.82,0,1}
media.frame.text=Text(media.frame); media.frame.text.text='Horn'
for _,k in ipairs({'DLeft','DMiddle','DRight'}) do media.frame[k]=media.frame:CreateTexture(nil,'ARTWORK'); media.frame[k]:SetTexture('native-lsm-border') end
media.frame.dropButton=Object('Button',media.frame); media.frame.dropButton:SetNormalTexture('native-down')
media.soundbutton=Object('Button',media.frame); media.soundbutton.obj=media
media.speaker=media.soundbutton:CreateTexture(nil,'BACKGROUND'); media.speaker:SetTexture('native-speaker')
media.soundbutton.scripts.OnClick=function() return 'native-sound-preview' end
local mediaPopup=Object('Frame',UIParent); mediaPopup.backdrop={bgFile='native-media',edgeFile='ornate'}
local mediaRow=Object('Button',mediaPopup); mediaRow.obj=media; mediaRow.text=Text(mediaRow)
mediaRow.text.color={1,1,1,1}; mediaRow.highlight=mediaRow:CreateTexture(nil,'HIGHLIGHT'); mediaRow.highlight:SetTexture('native-highlight')
mediaRow.scripts.OnClick=function() return 'native-sound-choice' end
mediaRow.check=mediaRow:CreateTexture(nil,'ARTWORK'); mediaRow.check:SetTexture('native-tick'); mediaRow.check:Show()
mediaPopup.contentRepo={mediaRow}
mediaPopup.slider=Object('Slider',mediaPopup); mediaPopup.slider.thumb=mediaPopup.slider:CreateTexture(); mediaPopup.slider.thumb:SetTexture('media-thumb'); mediaPopup.slider.thumb:SetSize(20,28)
mediaPopup:Hide()
local mediaToggles=0
media.frame.dropButton.scripts.OnClick=function()
    mediaToggles=mediaToggles+1
    if media.dropdown then mediaPopup:Hide(); media.dropdown=nil else media.dropdown=mediaPopup; mediaPopup:Show() end
    return 'native-media-toggle'
end
local binding=Widget('Keybinding',root.frame); table.insert(root.children,binding)
binding.button=Object('Button',binding.frame); binding.button.obj=binding; binding.button.Text=Text(binding.button)
binding.button:SetNormalTexture('native-red-button'); binding.key='CTRL-A'
binding.msgframe=Object('Frame',UIParent); binding.msgframe.Text=Text(binding.msgframe); binding.msgframe:Hide()
binding.button.scripts.OnClick=function() binding.waiting=true; binding.msgframe:Show(); return 'native-key-capture' end
binding.button.scripts.OnKeyDown=function(_,key) binding.key=key; binding.waiting=false; binding.msgframe:Hide(); return 'native-bind' end
root.closebutton=Object('Button',root.frame); root.closebutton:SetNormalTexture('native-close')
root.closebutton.scripts.OnClick=function() return 'native-close-action' end
-- Reproduce a real Blizzard canvas: its native OnShow builds its content.
-- The shared library then receives a newer FeedGroup method after skin setup.
root.frame:Hide()
root.frame.scripts.OnShow=function() dialog:FeedGroup('RareScanner General',{},root) end
assert(targetApp:SetupOptions()=='native-setup')
local replacedFeeds=0
dialog.FeedGroup=function(self,id,_,container) replacedFeeds=replacedFeeds+1; return 'native-feed',container,id end
root.frame:Show()
assert(replacedFeeds==1 and check.checkbg.width==14 and action.text.color[1]==0.92,'canvas fallback missed replaced library')
local sr,container,id=dialog:FeedGroup('RareScanner General',{},root)
assert(sr=='native-feed' and container==root and id=='RareScanner General')
assert(media.frame.DLeft.alpha==0 and media.speaker.alpha==1 and media.frame.label.color[1]==0.86)
assert(media.soundbutton.scripts.OnClick()=='native-sound-preview')
media.frame.dropButton.scripts.OnClick()
assert(mediaToggles==1 and mediaPopup.backdrop==nil and mediaRow.text.path=='EUI')
assert(mediaPopup.slider.thumb.width==20 and mediaPopup.slider.thumb.height==28 and mediaPopup.slider.thumb.alpha==0)
assert(mediaRow.scripts.OnClick()=='native-sound-choice' and mediaRow.check:IsShown())
media.frame.dropButton.scripts.OnClick(); assert(mediaToggles==2 and media.dropdown==nil)
assert(mediaPopup.backdrop.edgeFile=='ornate' and mediaRow.text.path=='Native' and mediaPopup.slider.thumb.alpha==1,'media popup cleanup leaked')
assert(binding.button.normal.alpha==0 and binding.button.Text.color[1]==0.92)
binding.button.scripts.OnClick(); assert(binding.waiting and binding.msgframe.styled)
assert(binding.button.scripts.OnKeyDown(binding.button,'SHIFT-B')=='native-bind' and binding.key=='SHIFT-B')
local stableReads,stableRegions,stableObjects,stableHooks,stableFonts=childReads,regionReads,allocated,hookCount,fontWrites
for i=1,100 do
    for _,event in ipairs(events) do if event.events and event.events.ADDON_LOADED then event.scripts.OnEvent(event,'ADDON_LOADED','UnrelatedAddon') end end
end
assert(childReads==stableReads and regionReads==stableRegions and allocated==stableObjects and hookCount==stableHooks and fontWrites==stableFonts,'unchanged libraries caused options work')
local popupObjects,popupHooks=allocated,hookCount
for i=1,20 do media.frame.dropButton.scripts.OnClick(); media.frame.dropButton.scripts.OnClick() end
assert(allocated==popupObjects and hookCount==popupHooks and mediaPopup.backdrop.edgeFile=='ornate','media popup reuse grew/leaked styling')
-- A normal native feed during OnShow must not cause a second full paint.
local cr,rr=childReads,regionReads
dialog:FeedGroup('RareScanner General',{},root)
local expectedChildren,expectedRegions=childReads-cr,regionReads-rr
cr,rr=childReads,regionReads; root.frame:Show()
assert(childReads-cr==expectedChildren and regionReads-rr==expectedRegions,'page OnShow duplicated its completed feed')
print('BENCH RareScanner unrelated_addon_loads=100 hierarchy_reads=0 font_writes=0; media_reopen=20 new_UI_objects=0 new_hooks=0')


assert(check.check.width==8 and check.checkbg.width==14 and check.checked and check.text.path=='EUI')
assert(check.checkbg.point[4]==5 and check.checkbg.point[5]==-5 and check.frame.width==200 and check.frame.height==24)
assert(check.text.point[2]==check.checkbg and check.text.point[4]==6)
assert(check:SetLabel('Only use in raids')=='native-label' and check.text.point[4]==6)
check.frame.scripts.OnMouseDown(check.frame)
assert(nativePresses==1 and check.text.point[4]==6 and check.text.point[5]==0, 'native pressed text must not overlap the flat square')
local checkedBefore=check.checked
check.frame.scripts.OnMouseUp(check.frame); assert(check.checked~=checkedBefore and check.text.point[4]==6)
assert(check:SetImage('native-class-icon')=='native-image' and check.text.point[2]==check.image and check.text.point[4]==6)
check:SetImage(nil); check:SetValue(true)
assert(action.frame.scripts.OnClick()=='native-option')
assert(action.text.color[1]==0.92 and action.text.color[4]==1, 'enabled action buttons must be readable')
assert(action:SetDisabled(true)=='native-button-state' and action.text.color[1]==0.5)
action:SetDisabled(false); action.text:SetTextColor(0.05,0.05,0.01,1)
assert(action.text.color[1]==0.92, 'native text resets must not leave enabled actions dark')
action.frame:SetFrameLevel(40); action.frame:SetParent(inline.content)
assert(#action.frame.children==0, 'action backgrounds must stay behind text without frame-level child overlays')
assert(inlineBorder.backdrop==nil and inline.titletext.color[1]==accent)
assert(dropdown.nativeArt.alpha==0 and dropdown.text.color[3]==1, 'selector art is removed while quality colours survive')
assert(up.normal.alpha==0 and down.normal.alpha==0 and down.scripts.OnClick()=='native-step')
assert(scroll.scrollbar.thumb.width==20 and scroll.scrollbar.thumb.height==28 and scroll.scrollbar.thumb.alpha==0, 'visual grip must preserve native drag dimensions')
local opened,openValue=popup:Open()
assert(opened=='native-open' and openValue==17 and popup.frame.backdrop==nil and popupItem.text.path=='EUI')
popup.frame:Hide()
assert(popup.frame.backdrop.edgeFile=='ornate' and popupItem.text.path=='Native' and popupItem.text.color[1]==0.4)
popup:Open(); popup.userdata.obj={}; popup:Open()
assert(popupItem.text.path=='Native' and popup.frame.backdrop.edgeFile=='ornate', 'foreign popup reuse restores native styling')
popup.userdata.obj=dropdown
dialog.popup=Object('Frame',UIParent); dialog.popup.text=Text(dialog.popup)
action.events={OnClick=function() dialog.popup:Show(); return 'native-confirm' end}
assert(action:Fire('OnClick')=='native-confirm' and dialog.popup.styled and dialog.popup.text.path=='Native')
check:OnRelease(); action:OnRelease(); dropdown:OnRelease(); tabs:OnRelease(); inline:OnRelease(); scroll:OnRelease(); media:OnRelease(); binding:OnRelease(); root:OnRelease()
assert(check.check.texture=='native-tick' and check.check.width==24 and check.checkbg.texture=='native-check-bg')
assert(check.text.point[4]==0 and check.checkbg.point[4]==0 and check.checkbg.point[5]==0,
    'pool release must restore native checkbox and label anchors')
assert(check.text.path=='Native' and action.frame.Text.path=='Native', 'pool release must restore native fonts')
assert(action.text.color[1]==1 and action.text.color[2]==0.82 and inlineBorder.backdrop.edgeFile=='bevelled')
assert(media.frame.DLeft.alpha==1 and media.frame.label.color[1]==1 and binding.button.normal.alpha==1,'new widget styles leaked on release')
assert(up.normal.alpha==1 and down.normal.alpha==1 and scroll.scrollbar.thumb.alpha==1)
local nativeWidgets=allocated
dialog:FeedGroup('AnotherAddon',{},root); check.frame:Show()
assert(check.text.path=='Native' and allocated==nativeWidgets, 'other addons must not trigger the skin')
dialog:FeedGroup('RareScanner General',{},root)
assert(check.check.width==8, 'owned pool reacquisition restores skin art')
local actionFill; for _,r in ipairs(action.frame.regions) do if r.layer=='BACKGROUND' then actionFill=r end end
assert(actionFill and actionFill.alpha==1 and actionFill.anchor==action.frame)
assert(dropdown.button.scripts.OnClick()=='native-dropdown' and dropdown.button.normal.alpha==0)
assert(root.closebutton.scripts.OnClick()=='native-close-action' and root.closebutton.normal.alpha==0)
local beforeStateWalks,beforeStateObjects=childReads,allocated
for i=1,100 do check:SetValue(i%2==0); check:SetDisabled(i%2==0) end
assert(childReads==beforeStateWalks and allocated==beforeStateObjects and check.check.width==8)
assert(check.check.color[1]==0.45 and check.checked==true)
local callbacks=hookCount
for i=1,40 do dialog:FeedGroup('RareScanner General',{},root) end
assert(hookCount==callbacks and allocated==nativeWidgets, 'repeated page feeds must reuse skin objects and hooks')
local beforeLabels,beforeLabelObjects=childReads,allocated
for i=1,100 do action:SetDisabled(i%2==0); action.text:SetTextColor(0.1,0.1,0.1,1) end
assert(action.text.color[1]==0.5 and childReads==beforeLabels and allocated==beforeLabelObjects, 'button state repairs must stay local')
action:SetDisabled(false)

check:SetDisabled(false)
accent=0.75; fontFace='EUI-new'; for _,fn in ipairs(looks) do fn() end; Flush()
assert(row.Name.path=='EUI-new' and row.Name.color[2]==0.1 and check.check.color[1]==0.75)
combat=true
local oldCalls=fontWrites; module.refresh(); scanner:ShowButton(); listView.fn(listView.owner,newRow); Flush()
assert(fontWrites==oldCalls,'combat styling occurred')
combat=false; for _,event in ipairs(events) do if event.events and event.events.PLAYER_REGEN_ENABLED then event.scripts.OnEvent(event) end end; Flush()
enabled=false
gui.Release=function(_,widget) widget.frame:Hide(); return 'native-release' end
for _,event in ipairs(events) do if event.events and event.events.ADDON_LOADED then event.scripts.OnEvent(event,'ADDON_LOADED','LibraryUpgrade') end end
check:OnRelease(); action.OnRelease=nil
assert(gui:Release(action)=='native-release' and check.text.path=='Native' and action.text.path=='Native')
action:SetDisabled(false); action.text:SetTextColor(0.2,0.3,0.4,1); assert(action.text.color[1]==0.2)
local objects=allocated; module.refresh(); scanner:ShowButton(); explorer:Show(); Flush(); assert(allocated==objects)
assert(#errors==0,table.concat(errors,'\n'))
RARESCANNER_BUTTON,RSExplorerFrame,RSLootMixin=nil,nil,nil
print('PASS: RareScanner secure alert/Explorer, page activation after Ace replacement, LSM sound menus/scrollbars, keybindings, native actions/pool restoration, themes/combat/disable')
