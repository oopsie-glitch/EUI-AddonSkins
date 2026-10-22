-- Pawn native scale/score colours, current-row discovery, tabs and lazy launchers.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local fontWrites, checkboxPaints, colourWrites = 0, 0, 0
local childReads, regionReads, parentReads = 0, 0, 0
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'Pawn'); factory = fn end
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
    function f:GetRegions() regionReads=regionReads+1; self.regionReads=(self.regionReads or 0)+1; return table.unpack(self.regions) end
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

S.Shell=function(f) f.shell=true end
S.SquareIcon=function(icon,parent) icon.square=true; icon.borderParent=parent end
local nativeFont=S.Font
S.Font=function(f,r,g,b)
    nativeFont(f,r,g,b)
    if not r then f:SetTextColor(1,1,1,1) end -- Shadow FontObjects may reset inherited colours.
end
assert(loadfile('EUIAddonSkins/Skins/Pawn.lua'))('EUIAddonSkins',ns)
assert(factory and not module)
local before=allocated; factory(); assert(not module.available() and allocated==before)
UIParent=Object('Frame')
local function Named(kind,name,parent)
    local f=Object(kind,parent); f.name=name; _G[name]=f; return f
end
local function Label(parent,name)
    local f=Text(parent); f.name=name; if name then _G[name]=f end; return f
end
local function Button(name,parent)
    local f=Named('Button',name,parent); f.Text=Label(f)
    f.scripts.OnClick=function() f.clicks=(f.clicks or 0)+1; return 'native-click' end
    return f
end
PawnUIFrame=Named('Frame','PawnUIFrame',UIParent); PawnUIFrame.backdrop={bgFile='native'}
PawnUIFrame_TinyCloseButton=Button('PawnUIFrame_TinyCloseButton',PawnUIFrame)
PawnUIScaleSelector=Named('Frame','PawnUIScaleSelector',PawnUIFrame)
PawnUIScaleSelectorScrollContent=Named('Frame','PawnUIScaleSelectorScrollContent',PawnUIScaleSelector)
PawnUICompareScrollContent=Named('Frame','PawnUICompareScrollContent',PawnUIFrame)
PawnUIGemScrollContent=Named('Frame','PawnUIGemScrollContent',PawnUIFrame)
local body=Named('Frame','PawnUIOptionsTabPage',PawnUIFrame)
local check=Named('CheckButton','PawnUIFrame_EnchantedValuesCheck',body); check.width,check.height=25,25
check.checkedArt=Object('Texture'); check.disabledArt=Object('Texture'); check.checked=true
check.scripts.OnClick=function() check.checked=not check.checked; return 'native-check' end
local edit=Named('EditBox','PawnUIFrame_StatValueBox',body); edit.text='1.25'
edit.scripts.OnTextChanged=function() return edit.text end
local action=Button('PawnUIFrame_ResetUpgradesButton',body)
action:Disable()
local auto=Button('PawnUIFrame_AutoSelectScalesOnButton',body); auto.SelectedTexture=auto:CreateTexture(); auto.SelectedTexture:Hide()
local swatch=Named('Button','PawnUIFrame_ScaleColorSwatch',body)
local color=swatch:CreateTexture(); color.color={0.3,0.4,0.8,1}
local icon=Named('Button','PawnUICompareItemIcon1',body); icon:SetNormalTexture('item-image')
icon.scripts.OnReceiveDrag=function() return 'native-drag' end
local score=Label(body,'PawnUICompareItemScore1'); score.color={0.1,1,0.2,1}
local arrow=body:CreateTexture(); arrow:SetTexture('Interface\\AddOns\\Pawn\\Textures\\UpgradeArrowBig')
local banner=body:CreateTexture(); banner:SetTexture('Interface\\AddOns\\Pawn\\Textures\\CompareBanner')
PawnUI_InventoryPawnButton=Button('PawnUI_InventoryPawnButton',UIParent)
PawnInterfaceOptionsFrame=Named('Frame','PawnInterfaceOptionsFrame',UIParent)
Button('PawnInterfaceOptionsLaunch',PawnInterfaceOptionsFrame)
for _,name in ipairs({'PawnUIStringDialogSingleLine','PawnUIStringDialogMultiLine'}) do
    local f=Named('Frame',name,UIParent); f.TextBox=Named('EditBox',name..'_TextBox',f)
    f.TextBox.text='native-export'; f.TextBox.scripts.OnEscapePressed=function() return 'native-cancel' end
    if name:find('MultiLine') then function f.TextBox:IsMultiLine() return true end end
    f.OKButton=Button(name..'OK',f); f.CancelButton=Button(name..'Cancel',f)
end
PawnUITabList={body,Named('Frame','PawnUIScalesTabPage',PawnUIFrame)}
PawnUICurrentTabNumber=1
function PawnUICreateTabs()
    for i=1,#PawnUITabList do Button('PawnUIFrameTab'..i,PawnUIFrame) end
    return 'native-tabs'
end
PawnUICreateTabs()
function PawnUISwitchToTab(page)
    for i,p in ipairs(PawnUITabList) do if p==page then PawnUICurrentTabNumber=i end end
    return 'native-tab-switch'
end
PawnUITotalScaleLines,PawnUITotalComparisonLines,PawnUITotalGemLines=0,0,0
local function Row(prefix,counter,parent,kind)
    _G[counter]=_G[counter]+1
    local name=prefix.._G[counter]; local f=Named(kind or 'Frame',name,parent)
    local label=Label(f,name..'Name'); label.color={0.1,0.8,0.3,1}
    if kind=='Button' then f.Text=label; f.highlight=f:CreateTexture(nil,'HIGHLIGHT') end
    return f
end
local function Scale()
    return Row('PawnUIScaleLine','PawnUITotalScaleLines',PawnUIScaleSelectorScrollContent,'Button')
end
function PawnUIFrame_ScaleSelector_AddHeaderLine() local f=Scale(); f:Disable(); return 'native-header' end
function PawnUIFrame_ScaleSelector_AddScaleLine() local f=Scale(); f.Text:SetFontObject('Silver'); return 'native-scale' end
function PawnUI_AddComparisonStatLineStrings() Row('PawnUICompareStatLine','PawnUITotalComparisonLines',PawnUICompareScrollContent); return 'native-comparison' end
function PawnUI_AddComparisonHeaderLine() Row('PawnUICompareStatLine','PawnUITotalComparisonLines',PawnUICompareScrollContent) end
function PawnUI_AddGemLine()
    local f=Row('PawnUIGemLine','PawnUITotalGemLines',PawnUIGemScrollContent,'Button')
    local tex=f:CreateTexture(); _G[f.name..'Icon']=tex; tex:SetTexture('gem'); return 'native-gem'
end
function PawnUI_AddGemHeaderLine() Row('PawnUIGemLine','PawnUITotalGemLines',PawnUIGemScrollContent,'Button') end
local stat=Button('PawnUIFrame_StatsList_Item1',body)
function PawnUIFrame_StatsList_UpdateStatItem(i)
    local f=_G['PawnUIFrame_StatsList_Item'..i]; f.Text:SetFontObject('Silver'); f.Text:SetTextColor(0.5,0.5,0.5,1); return 'native-stats'
end
function PawnUI_InspectPawnButton_Attach() PawnUI_InspectPawnButton=Button('PawnUI_InspectPawnButton',UIParent); return 'native-inspect' end
function PawnUI_SocketingPawnButton_Attach() PawnUI_SocketingPawnButton=Button('PawnUI_SocketingPawnButton',UIParent); return 'native-socket' end
module.skin=S; module.install(S,module); Flush()
assert(PawnUIFrame.shell and PawnUIFrame.backdrop==nil and PawnUIFrame_TinyCloseButton.close)
assert(check.check and check.width==25 and check.checkFill.width==14 and check.checked)
assert(check.scripts.OnClick()=='native-check' and not check.checked)
assert(edit.input and edit.text=='1.25' and edit.scripts.OnTextChanged()=='1.25')
assert(action.button and action.scripts.OnClick()=='native-click' and action.Text.color[1]==0.5,'disabled label lost')
assert(auto.SelectedTexture.color[1]==accent and not auto.SelectedTexture.shown,'native auto-selection changed')
assert(color.color[1]==0.3 and icon.normal.texture=='item-image' and icon.normal.square and icon.normal.borderParent==icon)
assert(icon.scripts.OnReceiveDrag()=='native-drag')
assert(score.color[2]==1 and arrow.alpha==1 and banner.alpha==0,'semantic/decorative art confused')
assert(PawnUIFrameTab1.selected and not PawnUIFrameTab2.selected)
assert(PawnUIStringDialogMultiLine.TextBox.text=='native-export' and PawnUIStringDialogMultiLine.TextBox.scripts.OnEscapePressed()=='native-cancel')
local c,r,o,h,w=childReads,regionReads,allocated,hookCount,fontWrites
for i=1,1000 do PawnUIFrame:Show(); assert(PawnUISwitchToTab(body)=='native-tab-switch') end
Flush()
assert(childReads==c and regionReads==r and allocated==o and hookCount==h and fontWrites==w,'warm window churn')
PawnUISwitchToTab(PawnUITabList[2]); assert(not PawnUIFrameTab1.selected and PawnUIFrameTab2.selected)
assert(PawnUIFrame_ScaleSelector_AddScaleLine()=='native-scale')
assert(PawnUIScaleLine1.Text.path=='EUI' and PawnUIScaleLine1.Text.color[2]==0.8)
assert(PawnUI_AddComparisonStatLineStrings()=='native-comparison')
assert(PawnUICompareStatLine1Name.color[2]==0.8 and PawnUICompareStatLine1Name.path=='EUI')
assert(PawnUI_AddGemLine()=='native-gem' and PawnUIGemLine1Icon.square)
assert(PawnUIFrame_StatsList_UpdateStatItem(1)=='native-stats' and stat.Text.path=='EUI' and stat.Text.color[1]==0.5)
local baselineObjects,baselineHooks=allocated,hookCount
for i=1,100 do PawnUIFrame_ScaleSelector_AddScaleLine(); PawnUI_AddComparisonStatLineStrings(); PawnUI_AddGemLine() end
assert(allocated-baselineObjects==900 and hookCount==baselineHooks,'skin allocated objects/hooks on dynamic native rows')
print('BENCH Pawn rows=300 native_mock_objects=900 skin_objects=0 new_hooks=0; warm_open_switch=1000 hierarchy_reads=0 font_writes=0')
local oldScale,oldCompare,oldGem=PawnUIScaleLine1,PawnUICompareStatLine1,PawnUIGemLine1
local oldWrites=oldScale.regionReads
PawnUITotalScaleLines,PawnUITotalComparisonLines,PawnUITotalGemLines=0,0,0
PawnUIFrame_ScaleSelector_AddScaleLine(); PawnUI_AddComparisonStatLineStrings(); PawnUI_AddGemLine()
local current=PawnUIScaleLine1
module.refresh(); Flush()
assert(oldScale.regionReads==oldWrites,'historical rows traversed')
assert(not oldScale.button and not oldCompare.button and not oldGem.button,'dynamic row gained canvases')
assert(PawnUI_InspectPawnButton_Attach()=='native-inspect' and PawnUI_InspectPawnButton.button)
assert(PawnUI_SocketingPawnButton_Attach()=='native-socket' and PawnUI_SocketingPawnButton.button)
local late=PawnUI_InspectPawnButton; assert(late.width==16 and late.height==20,'native launcher size changed')
local objects,hooks=allocated,hookCount
for i=1,50 do module.refresh() end; Flush()
assert(allocated==objects and hookCount==hooks,'theme refresh grew objects/hooks')
fontFace='NewTheme'; accent=0.8; for _,fn in ipairs(looks) do fn() end; Flush()
assert(current.Text.path=='NewTheme' and check.checkedArt.color[1]==accent and score.color[2]==1)
combat=true; PawnUI_AddGemLine(); local pending=PawnUIGemLine2
assert(not pending.Text.path:find('NewTheme'))
combat=false; for _,f in ipairs(events) do if f.scripts.OnEvent then f.scripts.OnEvent(f,'PLAYER_REGEN_ENABLED') end end; Flush()
assert(pending.Text.path=='NewTheme')
enabled=false
PawnUIFrame_ScaleSelector_AddScaleLine(); local unstyled=PawnUIScaleLine2
local unchanged=allocated; module.refresh(); PawnUIFrame:Show(); Flush()
assert(unstyled.Text.path=='Native' and allocated==unchanged)
assert(#errors==0,table.concat(errors,'\n'))
PawnUIFrame,PawnUITabList,PawnInterfaceOptionsFrame,PawnUIStringDialogSingleLine,PawnUIStringDialogMultiLine=nil,nil,nil,nil,nil
print('PASS: Pawn native actions/scales/colours/drag/editor/radios, dynamic rows, cached warm tabs, historical-row exclusion, lazy launchers, themes/combat/disable')
