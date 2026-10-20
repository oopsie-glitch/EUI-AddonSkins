-- Quest Completist window/options lifecycle and bounded styling.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'QuestCompletist'); factory = fn end
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
    function f:GetText() return self.text end
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
    function f:Show() self.shown=true; if self.scripts.OnShow then self.scripts.OnShow(self) end; for _,fn in ipairs(self.postScripts and self.postScripts.OnShow or {}) do fn(self) end end
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
        self.postScripts=self.postScripts or {}; self.postScripts[k]=self.postScripts[k] or {}
        table.insert(self.postScripts[k],fn)
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
S.Panel=function(f) if not f.panel then for _,r in ipairs(f.regions)do if r.kind=='Texture'then r:SetAlpha(0)end end; f.panel=true; f:CreateTexture(nil,'BACKGROUND') end end
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

S.Shell=function(f,options)
    f.shell=options
    for _,region in ipairs(f.regions) do if region.kind=='Texture' then region:SetAlpha(0) end end
end
ns.BindPopupOwner=function(_,_,owner) owner.menuBound=true end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
assert(loadfile('EUIAddonSkins/Skins/QuestCompletist.lua'))('EUIAddonSkins',ns)
assert(factory and not module)
local before=allocated; factory(); assert(not module.available() and allocated==before)
UIParent=Object('Frame')
local clicks,updates=0,0
local function Build()
    local root=CreateFrame('Frame','qcQuestCompletistUI',UIParent)
    root.qcPortrait=root:CreateTexture(nil,'BACKGROUND'); root.qcPortrait:SetTexture('native-portrait')
    root.qcPortraitMask=root:CreateTexture(nil,'BACKGROUND')
    root.qcTitleText=Text(root); root.qcTitleText.text='Quest Completist v113.9'
    root.qcSelectedCategory=Text(root); root.qcSelectedCategory.text='Native category'
    root.qcCurrentCategoryQuestCount=Text(root)
    root.HiddenQuests=Text(root)
    for _,name in ipairs({'qcOptionsButton','qcCategoryDropdownButton','qcXButton'}) do
        local b=CreateFrame('Button',name,root); b.Text=Text(b)
        b.scripts.OnClick=function() clicks=clicks+1; return 'native-action' end
    end
    local box=CreateFrame('EditBox','qcSearchBox',root); box.text='native search'; box.color={.5,.5,.5,1}
    box.scripts.OnTextChanged=function(_,user) updates=updates+1; return user end
    local clear=CreateFrame('Button',nil,box); clear.scripts.OnClick=function() box.text='';return 'native-clear' end
    local slider=CreateFrame('Slider','qcMenuSlider',root); slider.thumb=slider:CreateTexture(nil,'ARTWORK')
    slider.value=13;slider.minimum=1;slider.maximum=100
    slider.scripts.OnValueChanged=function(_,v) slider.value=v; qcUpdateQuestList();return 'native-scroll' end
    for i=1,16 do
        local row=CreateFrame('Button','qcMenuButton'..i,root)
        row.QuestName=Text(row);row.QuestIcon=row:CreateTexture(nil,'ARTWORK');row.FactionIcon=row:CreateTexture(nil,'ARTWORK')
        row.QuestIcon:SetTexture('native-quest-atlas');row.FactionIcon:SetTexture('native-faction')
        row.highlight=row:CreateTexture(nil,'HIGHLIGHT');row.QuestID=123+i
        row.scripts.OnClick=function()return row.QuestID end
    end
    root.scripts.OnShow=function() qcUpdateQuestList() end
    return root
end
qcUpdateQuestList=function()
    updates=updates+1
    for i=1,16 do
        local row=_G['qcMenuButton'..i]
        row.QuestName:SetText('Quest '..updates);row.QuestName:SetTextColor(.1,.6,.9,1)
        row.QuestIcon:SetTexture('native-status-'..updates)
    end
end
qcCategoryDropdownButton_OnClick=function()
    qcCategoryDropDownMenu=qcCategoryDropDownMenu or CreateFrame('Frame','qcCategoryDropDownMenu',UIParent)
    return 'native-dropdown',42
end
qcInterfaceOptions_OnShow=function(self)
    if self.built then return end
    self.built=true
    Text(self).text='Quest Completist options'
    for i=1,4 do
        local check=CreateFrame('CheckButton','qcIO_TEST'..i,self);check.Text=Text(check)
        check.checkedArt=check:CreateTexture(nil,'ARTWORK');check.disabledArt=check:CreateTexture(nil,'ARTWORK')
        check.checked=i%2==0
        check.scripts.OnClick=function() check.checked=not check.checked;return 'native-check' end
    end
    self:SetScript('OnShow',function() updates=updates+1 end)
end
local root=Build()
qcInterfaceOptions=CreateFrame('Frame','qcInterfaceOptions',UIParent)
qcInterfaceOptions:SetScript('OnShow',qcInterfaceOptions_OnShow)
qcMapTooltip=CreateFrame('GameTooltip','qcMapTooltip',UIParent)
local icon=qcMapTooltip:CreateTexture(nil,'ARTWORK');icon:SetTexture('native-map-icon')
local tooltipText=Text(qcMapTooltip);tooltipText.text='|cff00ff00Completed|r';tooltipText.color={0,1,0,1}
local tooltipBar=CreateFrame('StatusBar',nil,qcMapTooltip);tooltipBar.value=.75
qcToast=CreateFrame('Frame','qcToast',UIParent);qcToast.qcToastText=Text(qcToast)
qcToastLogo=qcToast:CreateTexture(nil,'ARTWORK')
assert(module.available());module.install(S,module);Flush()
assert(root.shell.noAccent and root.shell.noTopBar and root.width==360 and root.height==450)
assert(root.qcPortrait.alpha==0 and root.qcPortraitMask.alpha==0 and root.qcTitleText.path=='EUI')
assert(qcOptionsButton.button and qcCategoryDropdownButton.button and qcXButton.close)
assert(qcSearchBox.input and qcSearchBox.text=='native search' and qcSearchBox.color[1]==.5)
assert(qcSearchBox.scripts.OnTextChanged(qcSearchBox,true)==true)
assert(qcMenuSlider.thumb.width==5 and qcMenuSlider.thumb.height==20 and qcMenuSlider.value==13)
assert(qcMenuSlider.minimum==1 and qcMenuSlider.maximum==100)
assert(qcOptionsButton.scripts.OnClick()=='native-action' and clicks==1)
local a,b=qcCategoryDropdownButton_OnClick();assert(a=='native-dropdown' and b==42 and qcCategoryDropDownMenu.menuBound)
assert(qcMapTooltip.panel and icon.alpha==1 and icon.texture=='native-map-icon')
assert(tooltipText.path=='Native' and tooltipText.color[2]==1 and tooltipBar.value==.75 and not tooltipBar.panel)
assert(qcToastLogo.alpha==0 and qcToast.panel)
qcInterfaceOptions:Show();Flush()
assert(qcIO_TEST1.check and qcIO_TEST2.checked and not qcIO_TEST1.checked)
assert(qcIO_TEST1.checkedArt.width==8 and qcIO_TEST1.checkedArt.color[1]==accent)
assert(qcIO_TEST1.scripts.OnClick()=='native-check' and qcIO_TEST1.checked)
qcIO_TEST1:Disable();assert(qcIO_TEST1.Text.color[1]==.5)
qcIO_TEST1:Enable();assert(qcIO_TEST1.Text.color[1]==.9)
assert(qcMenuButton1.scripts.OnClick()==124)
local objects,hooks,writes,children,regions=allocated,hookCount,fontWrites,childReads,regionReads
for i=1,1000 do qcUpdateQuestList();qcMenuSlider.scripts.OnValueChanged(qcMenuSlider,i);root:Show();qcInterfaceOptions:Show() end
assert(allocated==objects and hookCount==hooks and fontWrites==writes,'warm use created objects/hooks/fonts')
assert(childReads==children and regionReads==regions,'warm use walked frame hierarchies')
assert(qcMenuButton1.QuestName.color[1]==.1 and qcMenuButton1.QuestIcon.alpha==1 and not qcMenuButton1.button)
fontFace='EUI-next';accent=.75;looks[1]();Flush()
assert(qcMenuButton1.QuestName.path=='EUI-next' and qcMenuButton1.QuestName.color[1]==.1)
assert(qcIO_TEST1.checkedArt.color[1]==.75 and allocated==objects)
assert(tooltipText.path=='Native' and tooltipText.text=='|cff00ff00Completed|r')
combat=true;qcIO_TEST1:Disable();looks[1]();Flush();combat=false
for _,event in ipairs(events)do if event.events and event.events.PLAYER_REGEN_ENABLED then event.scripts.OnEvent(event,'PLAYER_REGEN_ENABLED')end end
assert(qcIO_TEST1.Text.color[1]==.5)
local function AddCheck(protected)
    local check=CreateFrame('CheckButton',nil,qcInterfaceOptions);check.checkedArt=check:CreateTexture(nil,'ARTWORK');check.Text=Text(check);check.protected=protected;return check
end
local new=AddCheck(false);local secure=AddCheck(true);qcInterfaceOptions:Show();assert(new.check and not secure.check)
enabled=false;new=AddCheck(false);qcInterfaceOptions:Show();module.refresh();assert(not new.check)
enabled=true;combat=true;module.refresh();assert(not new.check);combat=false
for _,event in ipairs(events)do if event.events and event.events.PLAYER_REGEN_ENABLED then event.scripts.OnEvent(event,'PLAYER_REGEN_ENABLED')end end
assert(new.check)
-- Missing optional panels/tooltips, protected roots and delayed construction are safe.
qcInterfaceOptions=nil;qcMapTooltip=nil;qcToast=nil;module.refresh();Flush()
local old=root;root=Build();root.protected=true;module.refresh();assert(not root.shell)
root.protected=false;module.refresh();assert(root.shell and old.shell)
assert(#errors==0,table.concat(errors,'\n'))
print('PASS: Quest Completist native search/filter/menu/scroll/click semantics, status colours/icons, lazy options, tooltip content, themes, missing/protected controls, combat/disable and bounded reuse')
print('BENCH Quest Completist mock: 1000 list/scroll/window/options cycles: 0 new skin objects/hooks/font writes or hierarchy reads')
