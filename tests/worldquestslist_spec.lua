-- World Quests List 127 source-shaped table, private ELib menus and lazy dialogs.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'WorldQuestsList'); factory = fn end
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
    function f:SetAtlas(v)self.atlas=v end
    function f:SetRotation(v) self.rotation=v end
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
    function f:SetShown(v)self.shown=v end
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
S.SquareIcon=function(t) t.square=true; t:SetTexCoord(.08,.92,.08,.92) end

S.Shell=function(f,options)
    f.shell=options
    for _,region in ipairs(f.regions) do if region.kind=='Texture' then region:SetAlpha(0) end end
end

assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
assert(loadfile('EUIAddonSkins/Skins/WorldQuestsList.lua'))('EUIAddonSkins',ns)
assert(factory and not module);local before=allocated;factory();assert(not module.available()and allocated==before)
UIParent=Object('Frame')
local W=CreateFrame('Frame','WorldQuestsListFrame',UIParent);WorldQuestList=W
W.b=W:CreateTexture(nil,'BACKGROUND');W.b.A=.97
W.backdrop=Object('Frame',W);W.backdrop.BorderTop=W.backdrop:CreateTexture()
W.shadow=Object('Frame',W.backdrop)
W.C=Object('Frame',W);W.l={}
local actions,sorts,filterChanges=0,0,0
local function Button(parent)
 local f=Object('Button',parent);f.Text=Text(f)
 f.scripts.OnClick=function()actions=actions+1;return'click-native',nil,8 end
 return f
end
local function Row()
 local f=Object('Button',W.C)
 for _,k in ipairs({'name','reward','faction','timeleft','zone'})do f[k]=Text(f)end
 f.name.color={.2,.5,1,1};f.hl=f:CreateTexture();f.hl:Hide();f.nqhl=f:CreateTexture();f.nqhl:Hide()
 f.nameicon=f:CreateTexture();f.nameicon:SetAtlas('worldquest-icon-pvp-ffa')
 f.scripts.OnClick=function()actions=actions+1;return'quest-native'end
 return f
end
function W.UpdateList(count)
 for i=#W.l+1,count or #W.l do W.l[i]=Row()end
 W.C:SetHeight(math.max(1,#W.l*16))
 return'list-native',nil,9
end
local privateUpdate=W.UpdateList
W.UpdateList(3)
W.header=Object('Button',W);W.header.b=W.header:CreateTexture()
W.header.name=Text(W.header);W.header.name.f=Object('Button',W.header)
W.header.name.f.scripts.OnClick=function()sorts=sorts+1 end
W.footer=Object('Button',W);W.footer.gold=Text(W.footer)
W.Close=Object('Button',W);W.Close.X=Text(W.Close)
W.Close.scripts.OnClick=function()W:Hide();return'close-native'end
local function Drop()
 local f=Object('Frame',W);f.b=f:CreateTexture();f.l=f:CreateTexture();f.t=Text(f)
 f.Button=Object('Button',f);f.Button.i=f.Button:CreateTexture();f.Button.hl=f.Button:CreateTexture();f.Button.hl:Hide()
 f.Button.scripts.OnClick=function()actions=actions+1 end
 return f
end
W.sortDropDown=Drop();W.filterDropDown=Drop();W.optionsDropDown=Drop();W.moveHeader=Drop()
W.modeSwitcherCheck=Object('Frame',W);W.modeSwitcherCheck.b=W.modeSwitcherCheck:CreateTexture()
W.modeSwitcherCheck.s=Object('Slider',W.modeSwitcherCheck);W.modeSwitcherCheck.s.orientation='HORIZONTAL';W.modeSwitcherCheck.s.thumb=W.modeSwitcherCheck.s:CreateTexture()
W.modeSwitcherCheck.s.scripts.OnValueChanged=function()filterChanges=filterChanges+1 end
local function Check(parent)
 local f=Object('CheckButton',parent);f.width=12;f.height=12;f.checkedArt=f:CreateTexture();f.disabledArt=f:CreateTexture();f.checkedArt:Hide();f.disabledArt:Hide()
 f.scripts.OnClick=function()f.checked=not f.checked;f.checkedArt:SetShown(f.checked);filterChanges=filterChanges+1 end
 return f
end
W.WorldMapHideWQLCheck=Check(UIParent);W.WorldMapHideWQLCheck.width=26
local nativeArrow=Object('Texture');nativeArrow:SetTexture('navigation-arrow');W.Arrow={texture=nativeArrow}
W.BlackListWindow=Object('Frame',UIParent);W.BlackListWindow:Hide()
W.BlackListWindow.scripts.OnShow=function(self)
 if not self.created then
  self.created=true;self.close=Button(self);self.C=Object('Frame',self)
  self.bar=Object('Slider',self);self.bar.thumb=self.bar:CreateTexture();self.bar.orientation='VERTICAL';self.L={}
 end
 for i=#self.L+1,4 do local r=Object('Frame',self.C);r.n=Text(r);r.action=Button(r);self.L[i]=r end
end
W.SortPriorWindow=Object('Frame',UIParent);W.SortPriorWindow:Hide();W.SortPriorWindow.lines={}
W.SortPriorWindow.Close=Object('Button',W.SortPriorWindow);W.SortPriorWindow.Close.X=Text(W.SortPriorWindow.Close)
W.SortPriorWindow.Reset=Button(W.SortPriorWindow)
function W.SortPriorWindow:Update()
 for i=#self.lines+1,3 do local r=Object('Button',self);r.text=Text(r);self.lines[i]=r end
 return'sort-native',nil,4
end
W.SortPriorWindow.scripts.OnShow=function(self)self:Update()end
local function MenuRow(menu)
 local f=Object('Button',menu);f.NormalText=Text(f);f.Icon=f:CreateTexture();f.Icon:SetTexture('reward-icon')
 f.Arrow=f:CreateTexture();f.Arrow:Hide();f.Highlight=f:CreateTexture();f.Highlight:Hide()
 f.checkButton=Check(f);f.radioButton=Check(f)
 f.slider=Object('Slider',f);f.slider.orientation='HORIZONTAL';f.slider.thumb=f.slider:CreateTexture();f.slider.text=Text(f.slider)
 f.slider.scripts.OnValueChanged=function()filterChanges=filterChanges+1 end
 function f:SetNormalFontObject()self.NormalText:SetFont('Native',12,'')end
 function f:SetHighlightFontObject()self.NormalText:SetFont('Native',12,'')end
 f.scripts.OnClick=function()actions=actions+1;return'menu-action'end
 return f
end
for i=1,3 do
 local m=CreateFrame('Button','WQL_ExRTDropDownListModern'..i,UIParent);m.Buttons={};m.Background=m:CreateTexture();m:Hide()
end
local function OpenMenu(menu,count)
 for i=#menu.Buttons+1,count do menu.Buttons[i]=MenuRow(menu)end
 menu:Show() -- native ToggleDropDownMenu shows first, Reload follows
 for i,f in ipairs(menu.Buttons)do
  f:SetNormalFontObject();f:SetHighlightFontObject();f.NormalText:SetText('setting '..i)
  f.checkButton:SetChecked(i%2==0);f.checkButton.checkedArt:SetShown(i%2==0);f:Show()
 end
 return'menu-native'
end
assert(module.available());module.install(S,module);Flush()
assert(W.backdrop.BorderTop.alpha==0 and W.shadow.alpha==0 and W.Close.close)
assert(W.l[1].name.path=='EUI' and W.l[1].name.color[1]==.2 and W.l[1].nameicon.atlas=='worldquest-icon-pvp-ffa')
assert(not W.l[1].hl.shown and not W.l[1].nqhl.shown,'skinning forced row highlight visibility')
assert(W.modeSwitcherCheck.s.thumb.width==8 and W.modeSwitcherCheck.s.thumb.height==14)
assert(W.optionsDropDown.Button.i.texture:find('eui%-arrow%-down3'))
assert(not W.BlackListWindow.created,'skin forced lazy blacklist construction')
assert(W.Arrow.texture.texture=='navigation-arrow')
local a,b,c=privateUpdate(5);assert(a=='list-native'and b==nil and c==9 and W.l[5].name.path=='EUI','private updater rows missed')
local reads,objects,hooks,writes=childReads,allocated,hookCount,fontWrites
for i=1,300 do privateUpdate(5)end
Flush();assert(childReads==reads and allocated==objects and hookCount==hooks and fontWrites==writes,'warm quest updates scan, allocate or rewrite fonts')
W.header.name.f.scripts.OnClick();assert(sorts==1)
assert(W.l[1].scripts.OnClick()=='quest-native')
local menu=WQL_ExRTDropDownListModern1
OpenMenu(menu,10)
assert(menu.panel and menu.Background.alpha==0)
assert(menu.Buttons[1].NormalText.path=='EUI','Reload reset menu font after Show')
assert(menu.Buttons[1].Icon.texture=='reward-icon'and not menu.Buttons[1].Arrow.shown)
assert(menu.Buttons[1].checkButton.checkedArt.color[1]==accent and menu.Buttons[1].checkButton.checkedArt.point[4]==-3)
assert(not menu.Buttons[1].checkButton.checkedArt.shown and menu.Buttons[2].checkButton.checkedArt.shown)
local objects,hooks=allocated,hookCount
for i=1,50 do menu:Hide();OpenMenu(menu,10)end
assert(allocated==objects and hookCount==hooks,'menu hooks/objects duplicated')
OpenMenu(menu,12);assert(menu.Buttons[12].NormalText.path=='EUI')
assert(menu.Buttons[1].scripts.OnClick()=='menu-action')
W.BlackListWindow:Show();assert(W.BlackListWindow.shell.noAccent and W.BlackListWindow.L[4].n.path=='EUI')
assert(W.BlackListWindow.bar.thumb.width==6)
W.SortPriorWindow:Show();assert(W.SortPriorWindow.lines[3].text.path=='EUI'and W.SortPriorWindow.Close.close)
local objects,hooks,writes=allocated,hookCount,fontWrites
for i=1,50 do W.SortPriorWindow:Update()end
assert(allocated==objects and hookCount==hooks and fontWrites==writes,'warm sorting dialog creates objects/hooks/fonts')
W.b:SetAlpha(0)
local glow;for _,f in ipairs(W.children)do if f.parts then glow=f end end
assert(glow and glow.alpha==0,'native transparent/no-background mode lost')
W.b:SetAlpha(.4);assert(glow.alpha==.4)
combat=true;privateUpdate(7);assert(W.l[7].name.path~='EUI')
combat=false
for _,f in ipairs(events)do if f.events and f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent(f,'PLAYER_REGEN_ENABLED')end end
Flush();assert(W.l[7].name.path=='EUI')
accent=.8;fontFace='Changed';for _,fn in ipairs(looks)do fn()end;Flush()
assert(W.l[1].name.path=='Changed' and menu.Buttons[1].checkButton.checkedArt.color[1]==.8)
enabled=false;privateUpdate(8);assert(W.l[8].name.path~='Changed')
enabled=true;module.refresh();Flush();assert(W.l[8].name.path=='Changed')
assert(filterChanges==0,'skinning changed a setting')
assert(#errors==0,table.concat(errors,'\n'))
print('BENCH WorldQuestsList warm_updates=300 hierarchy_walks=0 new_objects=0 font_writes=0 (mock)')
print('PASS: World Quests List private updater rows, native actions/colours/opacity, pooled post-Show menus, clean checks/sliders, lazy dialogs, theme/toggle/combat and warm reuse')
