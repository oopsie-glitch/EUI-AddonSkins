-- Source-shaped OneForAll 6.0.1 construction/state workload. An optional local
-- upstream Widgets.lua can exercise the real constructors without bundling it.
for _,client in ipairs({'Retail','Forever'}) do
WOW_PROJECT_MAINLINE, WOW_PROJECT_CAMELOT = 1, 99
WOW_PROJECT_ID = client=='Retail' and WOW_PROJECT_MAINLINE or WOW_PROJECT_CAMELOT
for _,suffix in ipairs({'Frame','ProfilePopup','Confirm','BugReport','Discord','CraftList','QuestChain','WeightEditor','TrainerSpells','TalentCode','Welcome','WhatsNew','PreviewFrame','QuestSharePopup'})do _G['OneForAll'..suffix]=nil end
local timers, modules, looks, events = {}, {}, {}, {}
local count = {objects=0,hooks=0,reads=0,geometry=0,fonts=0,scans=0,colours=0}
local enabled, combat, accent, face = true, false, {.1,.7,.9}, 'eui-font'
local numeric = os.getenv('ONEFORALL_NUMERIC_TEXTURES')
local textureIDs, nextTextureID = {}, 1000
GetFileIDFromPath=function(path)
    if not textureIDs[path] then nextTextureID=nextTextureID+1;textureIDs[path]=nextTextureID end
    return textureIDs[path]
end
local unpack = table.unpack
local ns={IsEnabled=function()return enabled end}
function ns.RegisterModule(id,_,available,install) modules[id]={available=available,install=install} end
function ns.RegisterSkinDefinition(_,fn) fn() end
InCombatLockdown=function()return combat end
C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
geterrorhandler=function()return function(err)error(err)end end
ITEM_QUALITY_COLORS={ [0]={r=.62,g=.62,b=.62}, {r=1,g=1,b=1}, {r=.12,g=1,b=0},
    {r=0,g=.44,b=.87}, {r=.64,g=.21,b=.93}, {r=1,g=.5,b=0}, {r=.9,g=.8,b=.5}, {r=0,g=.8,b=1} }
RAID_CLASS_COLORS={MAGE={r=.25,g=.78,b=.92}}
local function returns(...)return table.pack(...)end
hooksecurefunc=function(obj,name,fn)
    local original=obj[name];assert(type(original)=='function',name)
    count.hooks=count.hooks+1
    obj[name]=function(...)local v=returns(original(...));fn(...);return unpack(v,1,v.n)end
end
local function object(kind,parent,name)
    count.objects=count.objects+1
    local f={kind=kind,parent=parent,name=name,children={},regions={},scripts={},alpha=1,shown=true,
        w=30,h=24,points={},vertex={1,1,1,1},textColor={1,1,1,1},enabled=true,font='native-font',fontSize=12}
    function f:GetObjectType()return self.kind end
    function f:IsObjectType(k)return self.kind==k end
    function f:IsForbidden()return self.forbidden end
    function f:IsProtected()
        if self.protected then return true,true end
        local p=self
        while p do
            if p.implicit then
                if client=='Retail' then return true,false else return true,nil end
            end
            p=p.parent
        end
        return false,nil
    end
    function f:GetName()return self.name end
    function f:GetParent()return self.parent end
    function f:GetChildren()assert(self~=UIParent,'global traversal');count.reads=count.reads+1;return unpack(self.children)end
    function f:GetRegions()count.reads=count.reads+1;return unpack(self.regions)end
    function f:GetNumChildren()return #self.children end
    function f:GetNumRegions()return #self.regions end
    function f:SetSize(w,h)count.geometry=count.geometry+1;self.w,self.h=w,h end
    function f:GetSize()return self.w,self.h end
    function f:GetWidth()return self.w end
    function f:GetHeight()return self.h end
    function f:SetWidth(w)count.geometry=count.geometry+1;self.w=w end
    function f:SetHeight(h)count.geometry=count.geometry+1;self.h=h end
    function f:SetPoint(...)count.geometry=count.geometry+1;self.points[#self.points+1]={...}end
    function f:GetPoint(i)return unpack(self.points[i or 1] or {})end
    function f:GetNumPoints()return #self.points end
    function f:ClearAllPoints()count.geometry=count.geometry+1;self.points={};self.all=nil end
    function f:SetAllPoints(to)count.geometry=count.geometry+1;self.all=to or self.parent end
    function f:SetTexture(path)self.path=path;self.base=nil end
    function f:GetTexture()return numeric and self.path and GetFileIDFromPath(self.path) or self.path end
    function f:SetColorTexture(...)count.colours=count.colours+1;self.path=nil;self.base={...}end
    function f:SetVertexColor(r,g,b,a)count.colours=count.colours+1;self.vertex={r,g,b,a or 1}end
    function f:GetVertexColor()return unpack(self.vertex)end
    function f:SetAlpha(a)self.alpha=a end
    function f:GetAlpha()return self.alpha end
    function f:SetShown(v)self.shown=v and true or false end
    function f:IsShown()return self.shown end
    function f:IsVisible()return self.shown and (not self.parent or self.parent:IsVisible())end
    function f:Show()self.shown=true;if self.scripts.OnShow then self.scripts.OnShow(self)end end
    function f:Hide()self.shown=false end
    function f:SetTexCoord(...)self.uv={...}end
    function f:GetTexCoord()return unpack(self.uv or {0,1,0,1})end
    function f:SetDrawLayer(l,s)self.layer,self.sub=l,s end
    function f:GetDrawLayer()return self.layer,self.sub end
    function f:SetBlendMode(v)self.blend=v end
    function f:SetDesaturated(v)self.desat=v end
    function f:SetScript(k,fn)self.scripts[k]=fn end
    function f:GetScript(k)return self.scripts[k]end
    function f:HasScript()return self.kind~='Texture' and self.kind~='FontString'end
    function f:HookScript(k,fn)
        count.hooks=count.hooks+1;local old=self.scripts[k]
        self.scripts[k]=function(...)local v=old and returns(old(...));fn(...);if v then return unpack(v,1,v.n)end end
    end
    function f:RegisterEvent(e)self.events=self.events or {};self.events[e]=true end
    function f:EnableMouse(v)self.mouse=v end
    function f:EnableMouseWheel(v)self.wheel=v end
    function f:RegisterForClicks(...)self.clicks={...}end
    function f:SetFrameLevel(v)self.frameLevel=v end
    function f:GetFrameLevel()return self.frameLevel or 1 end
    function f:SetFrameStrata(v)self.strata=v end
    function f:SetMovable()end
    function f:SetToplevel()end
    function f:RegisterForDrag()end
    function f:SetClampedToScreen()end
    function f:SetScale(v)self.scale=v end
    function f:GetScale()return self.scale or 1 end
    function f:GetEffectiveScale()return self.scale or 1 end
    function f:GetLeft()return nil end
    function f:GetTop()return nil end
    function f:StartMoving()end
    function f:StopMovingOrSizing()end
    function f:SetNormalTexture(path)self.normal=self.normal or self:CreateTexture(nil,'ARTWORK');self.normal:SetTexture(path)end
    function f:SetPushedTexture(path)self.pushed=self.pushed or self:CreateTexture(nil,'ARTWORK');self.pushed:SetTexture(path)end
    function f:SetBackdrop(v)self.backdrop=v end
    function f:GetBackdrop()return self.backdrop end
    function f:SetFont(path,size,flags)count.fonts=count.fonts+1;self.font,self.fontSize,self.flags=path,size,flags or ''end
    function f:GetFont()return self.font,self.fontSize,self.flags or ''end
    function f:SetFontObject()end
    function f:SetText(t)self.textValue=t end
    function f:GetText()return self.textValue or ''end
    function f:SetTextColor(...)self.textColor={...}end
    function f:GetTextColor()return unpack(self.textColor)end
    function f:SetFontString(v)self.label=v end
    function f:GetFontString()return self.label end
    function f:GetStringWidth()return #self:GetText()*6 end
    function f:GetStringHeight()return 14 end
    function f:SetJustifyH(v)self.justify=v end
    function f:SetWordWrap(v)self.wordWrap=v end
    function f:SetJustifyV()end
    function f:SetShadowOffset()end
    function f:SetTextInsets(...)self.insets={...}end
    function f:SetAutoFocus()end
    function f:SetMaxLetters()end
    function f:SetNumeric()end
    function f:HasFocus()return false end
    function f:ClearFocus()end
    function f:GetTextInsets()return 0,0,0,0 end
    function f:GetNormalTexture()return self.normal end
    function f:GetPushedTexture()return self.pushed end
    function f:GetHighlightTexture()return self.highlight end
    function f:GetDisabledTexture()return self.disabled end
    function f:GetCheckedTexture()return self.checkedTex end
    function f:GetDisabledCheckedTexture()return self.disabledCheckedTex end
    function f:SetHighlightTexture(v)self.highlight=v end
    function f:SetChecked(v)self.checked=v end
    function f:GetChecked()return self.checked end
    function f:SetEnabled(v)self.enabled=v end
    function f:IsEnabled()return self.enabled end
    function f:Enable()self:SetEnabled(true)end
    function f:Disable()self:SetEnabled(false)end
    function f:Click()
        if not self.enabled then return end
        if self.kind=='CheckButton' then self:SetChecked(not self:GetChecked())end
        if self.scripts.OnClick then self.scripts.OnClick(self)end
        if self.scripts.PostClick then self.scripts.PostClick(self)end
    end
    function f:GetOrientation()return self.orientation end
    function f:SetOrientation(v)self.orientation=v end
    function f:SetScrollChild(v)self.scrollChild=v end
    function f:GetVerticalScrollRange()return 0 end
    function f:SetDisabledTexture(path)self.disabled=self.disabled or self:CreateTexture(nil,'ARTWORK');self.disabled:SetTexture(path)end
    function f:GetThumbTexture()return self.thumb end
    function f:SetThumbTexture(v)self.thumb=v end
    function f:SetMinMaxValues(lo,hi)self.lo,self.hi=lo,hi end
    function f:GetMinMaxValues()return self.lo or 0,self.hi or 1 end
    function f:SetValueStep(v)self.step=v end
    function f:SetObeyStepOnDrag()end
    function f:SetValue(v)self.value=v;if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v)end end
    function f:GetValue()return self.value end
    function f:CreateTexture(_,layer,_,sub)
        local t=object('Texture',self);t.layer,t.sub=layer,sub;self.regions[#self.regions+1]=t;return t
    end
    function f:CreateFontString(_,layer,template)
        local t=object('FontString',self);t.layer,t.template=layer,template;self.regions[#self.regions+1]=t;return t
    end
    if kind == 'Texture' or kind == 'FontString' then
        f.GetChildren, f.GetRegions, f.GetNumChildren, f.GetNumRegions = nil, nil, nil, nil
    end
    if parent and kind~='Texture' and kind~='FontString' then parent.children[#parent.children+1]=f end
    if name then _G[name]=f end
    return f
end
UIParent=object('Frame')
CreateFrame=function(kind,name,parent,template)
    local f=object(kind,parent,name)
    if template=='UICheckButtonTemplate' then f.checkedTex=f:CreateTexture(nil,'OVERLAY') end
    if template=='UIPanelScrollFrameTemplate' then f.ScrollBar=object('Slider',f);f.ScrollBar.orientation='VERTICAL' end
    if template=='BasicFrameTemplateWithInset' then
        f.TitleText=f:CreateFontString(nil,'OVERLAY','GameFontNormal')
        f.CloseButton=CreateFrame('Button',nil,f)
        f.Inset=CreateFrame('Frame',nil,f);f.Inset.Bg=f.Inset:CreateTexture(nil,'BACKGROUND')
    end
    if not parent then events[#events+1]=f end
    return f
end
local S={}
local primitiveButtons={}
local shells={}
function S.GetFont()return face,''end
function S.GetAccentColor()return unpack(accent)end
function S.GetPanelColor()return .08,.08,.09,1 end
function S.Font(t)t:SetFont(face,t.fontSize,'')end
function S.OnLooksChanged(fn)looks[#looks+1]=fn end
local function strip(f,keep)
    for _,t in ipairs({f:GetRegions()})do if t.kind=='Texture' and not (keep and keep[t])then t:SetAlpha(0)end end
end
function S.Button(f,keys)
    if f.euiButton then return end
    local d={};f.euiButton=d;primitiveButtons[f]=keys
    local keep={};for _,k in ipairs(keys or {})do if f[k]then keep[f[k]]=true end end
    strip(f,keep)
    d.fill=f:CreateTexture(nil,'BACKGROUND');d.fill:SetAllPoints(f);d.fill:SetColorTexture(.08,.08,.09,1)
    d.hover=f:CreateTexture(nil,'HIGHLIGHT');d.hover:SetAllPoints(f);d.hover:SetColorTexture(1,1,1,.1)
end
function S.Shell(f)
    assert(f.kind=='Frame');strip(f)
    if shells[f]then return end
    shells[f]={f:CreateTexture(nil,'BACKGROUND'),f:CreateTexture(nil,'BACKGROUND')}
    for _,t in ipairs(shells[f])do t:SetAllPoints(f);t:SetColorTexture(.08,.08,.09,1)end
end
function S.Panel(f)S.Button(f)end
function S.Inset(f)strip(f)end
function S.FadeNineSlice()end
function S.EditBox(f)if not f.euiEdit then f.euiEdit=true;S.Button(f)end end
function S.Checkbox(f)if not f.euiCheck then f.euiCheck=true;S.Button(f)end end
function S.PageButton(f,direction)S.Button(f);f.euiPageDirection=direction end
function S.ScrollBar(f)f.euiScroll=true end
function S.SquareIcon()end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
local A={}
local source=os.getenv('ONEFORALL_WIDGETS')
if source then
    assert(loadfile(source))('OneForAll',A)
else
    A.UI={panels={},ASSET_ROOT='Interface\\AddOns\\OneForAll\\Assets\\'}
    local UI=A.UI
    function A.SetTex(t,path)t:SetTexture(path)end
    function A.NewFS(owner,...)return owner:CreateFontString(...)end
    function A.SkinBlizz(f)return f end
    function UI.RegisterPanel(spec)UI.panels[#UI.panels+1]=spec end
    function UI.RoundRect(owner,anchor,layer,sub,c,inset,r,g,b,a,tex)
        local v={pieces={}}
        for i=1,(tex=='rr_ring_w' and 8 or 9) do
            local t=owner:CreateTexture(nil,layer);t:SetDrawLayer(layer,sub)
            t:SetTexture(UI.ASSET_ROOT..(tex or 'rr_fill'));v.pieces[i]=t
        end
        function v:SetColor(...)for _,t in ipairs(self.pieces)do t:SetVertexColor(...)end end
        function v:SetShown(on)for _,t in ipairs(self.pieces)do t:SetShown(on)end end
        v:SetColor(r,g,b,a or 1);return v
    end
    function UI.Card(owner,anchor,c,border,fill,layer,sub)
        local r,g,b,a=table.unpack(border or {.28,.25,.2,1})
        local v={fill=UI.RoundRect(owner,anchor,layer or 'BACKGROUND',(sub or 0)+1,4,1,table.unpack(fill or {.06,.06,.07,1})),
            border=UI.RoundRect(owner,anchor,layer or 'BACKGROUND',sub or 0,4,0,r,g,b,a,'rr_ring_w')}
        function v:SetFill(...)self.fill:SetColor(...)end
        function v:SetBorder(...)self.border:SetColor(...)end
        return v
    end
    function UI.CardRow(f)
        local c=UI.Card(f,f)
        local hi=f:CreateTexture(nil,'HIGHLIGHT');hi:SetColorTexture(.90,.66,.22,.07)
        for i=1,9 do local t=f:CreateTexture(nil,'HIGHLIGHT');t:SetTexture(UI.ASSET_ROOT..'rr_ring')end
        function c:SetSelected(on,nfill)
            if on then self:SetBorder(1,.8,.34,1);self:SetFill(.22,.155,.055,.98)
            else self:SetBorder(.28,.25,.2,.9);self:SetFill(table.unpack(nfill or {.06,.062,.074,.97}))end
        end
        return c
    end
    function UI.GlowLine(f)
        local t=f:CreateTexture(nil,'ARTWORK');t:SetTexture(UI.ASSET_ROOT..'glow_line');return t
    end
    function UI.SmallCaps(parent,text,big,small,color)
        local holder=CreateFrame('Frame',nil,parent)
        for part in text:gmatch('%a+')do
            for _,str in ipairs({part:sub(1,1),part:sub(2):upper()})do
                local t=A.NewFS(holder,nil,'OVERLAY','GameFontNormal');t:SetText(str)
                t:SetTextColor(table.unpack(color));t:SetFont('native-font',small,'')
            end
        end
        holder:SetSize(#text*6,big+2);return holder
    end
    function UI.GoldButton(parent,text,w,h,icon)
        local b=CreateFrame('Button',nil,parent);b:SetSize(w,h)
        local active=b:CreateTexture(nil,'BACKGROUND');active:SetTexture(UI.ASSET_ROOT..'btn_m_active');active:Hide()
        b._label=A.NewFS(b,nil,'OVERLAY','GameFontNormal');b._label:SetText(text);b._label:SetTextColor(.95,.82,.5)
        if icon then b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetTexture(icon)end
        function b:SetActive(on)active:SetShown(on);self._label:SetTextColor(1,.93,.66)end
        return b
    end
    UI.NavButton=UI.GoldButton
    function UI.FramedPanel(f)UI.RoundRect(f,f,'BACKGROUND',0,7,1,.045,.045,.055,.96)end
    function UI.Slider(parent,w,lo,hi,step,fn)
        local f=CreateFrame('Slider',nil,parent);f:SetOrientation('HORIZONTAL');f:SetSize(w,18)
        f.thumb=f:CreateTexture(nil,'OVERLAY');f:SetMinMaxValues(lo,hi);f:SetValueStep(step)
        f:SetScript('OnValueChanged',function(_,v)fn(v)end);return f
    end
end
OneForAll=A
local UI=A.UI
UI.GetWindowAlpha=function()return UI.alpha or .95 end
UI.ApplyWindowAlpha=function()return 'native-alpha'end
local function flush()local n=0;while #timers>0 do local t=timers;timers={};for _,fn in ipairs(t)do fn()end;n=n+1;assert(n<30,'unbounded cosmetic queue')end end
local pages={}
local function page(parent,key)
    local p=CreateFrame('Frame',nil,parent);p.key=key
    p.art=p:CreateTexture(nil,'BACKGROUND');p.art:SetTexture('Interface\\AddOns\\OneForAll\\Assets\\talent_tree_illustration')
    p.model=CreateFrame('PlayerModel',nil,p)
    p.button=UI.GoldButton(p,'Do something',110,24)
    p.button:SetScript('OnClick',function()p.clicked=(p.clicked or 0)+1;return 'native-click',nil,7 end)
    p.button:SetScript('OnEnter',function()return 'native-tooltip'end)
    p.edit=A.SkinBlizz(CreateFrame('EditBox',nil,p));p.edit:SetSize(120,20);p.edit:SetText('search')
    p.check=A.SkinBlizz(CreateFrame('CheckButton',nil,p,'UICheckButtonTemplate'));p.check:SetSize(42,24)
    p.row=CreateFrame('Button',nil,p);p.row.card=UI.CardRow(p.row)
    p.row.name=A.NewFS(p.row,nil,'OVERLAY','GameFontNormal');p.row.id=13
    p.row.name:SetTextColor(1,.5,0)
    p.status=UI.Gem and UI.Gem(p,10,.45,.85,.45) or nil
    pages[key]=p;return p
end
for _,key in ipairs({'armory','dungeons','professions','qol','talents','books','pets','settings'})do
    UI.RegisterPanel({key=key,label=key,order=key=='settings' and 0 or 1,create=function(parent)return page(parent,key)end})
end
A.ToggleUI=function()
    if not UI.mainWindow then
        local f=CreateFrame('Frame','OneForAllFrame',UIParent);UI.mainWindow=f;f:SetSize(1040,690)
        local art=f:CreateTexture(nil,'BORDER');art:SetTexture(UI.ASSET_ROOT..'header_banner');UI.banner=art
        local logo=f:CreateTexture(nil,'ARTWORK');logo:SetTexture(UI.ASSET_ROOT..'minimap_icon');UI.brandLogo=logo
        UI.normalBg=f:CreateTexture(nil,'BACKGROUND');UI.normalBg:SetTexture(UI.ASSET_ROOT..'rr_fill')
        local b=CreateFrame('Button',nil,f);b:SetSize(130,32)
        local plate=UI.RoundRect(b,b,'BACKGROUND',0,8,0,.21,.15,.08,1)
        -- MainFrame.openBottom changes the centre after RoundRect returns.
        plate.pieces[9]:ClearAllPoints();plate.pieces[9]:SetPoint('TOPLEFT',b,'TOPLEFT',8,-8)
        local glow=UI.GlowLine(b)
        b._label=A.NewFS(b,nil,'OVERLAY','GameFontNormal');b._label:SetText('Armory')
        function b:ContentWidth()return 130 end
        function b:SetActive(on)plate:SetShown(on);glow:SetShown(on)end
        UI.testMainTab=b
    end
    return 'native-toggle',nil,42
end
local mainSource=os.getenv('ONEFORALL_MAINFRAME')
if mainSource then
    OneForAllDB={window={alpha=.95}};OneForAllCharDB={}
    A.Refresh=function()end
    assert(loadfile(mainSource))('OneForAll',A)
end
local settingsSource=os.getenv('ONEFORALL_SETTINGS')
local actualSettings
if settingsSource then
    assert(source,'actual Settings requires actual Widgets')
    -- Register the real completed factory, retaining the eight lightweight
    -- pages for repeated-work counters. No target sources enter the package.
    local before={};for _,spec in ipairs(UI.panels)do before[spec]=true end
    assert(loadfile(settingsSource))('OneForAll',A)
    for _,spec in ipairs(UI.panels)do if not before[spec] then actualSettings=spec end end
    actualSettings.key='sourceSettings'
end
local qolSource=os.getenv('ONEFORALL_QOL')
local actualQoL
if qolSource then
    assert(source,'actual QoL requires actual Widgets')
    local before={};for _,spec in ipairs(UI.panels)do before[spec]=true end
    assert(loadfile(qolSource))('OneForAll',A)
    for _,spec in ipairs(UI.panels)do if not before[spec] then actualQoL=spec end end
    actualQoL.key='sourceQoL'
end
-- A window may already exist when EUI/the target integration becomes ready.
local prebuilt=CreateFrame('Frame','OneForAllWeightEditor',UIParent)
local preSlot=CreateFrame('Button',nil,prebuilt);preSlot.slot=2;preSlot.q=2
preSlot.card=UI.Card(preSlot,preSlot,4,{.12,1,0,1},{.05,.05,.06,.95},'BACKGROUND',0)
local preRow=CreateFrame('Button',nil,prebuilt);preRow.card=UI.CardRow(preRow);preRow.card:SetSelected(true)
preRow.card:SetBorder(1,.8000000119,.3400000036,1) -- native float readback
assert(loadfile('EUIAddonSkins/Skins/OneForAll.lua'))('EUIAddonSkins',ns)
local m=assert(modules.OneForAll);assert(m.available())
m.install(S,m);flush()
local r,n,last=A:ToggleUI();flush()
if not mainSource then assert(r=='native-toggle' and n==nil and last==42)end
local root=UI.mainWindow
if mainSource then
    for _,t in ipairs(root.regions)do
        if t.path==UI.ASSET_ROOT..'header_banner' then UI.banner=t end
        if t.path==UI.ASSET_ROOT..'rr_fill' then UI.normalBg=t end
    end
end
assert(UI.banner.alpha==1 and UI.brandLogo.alpha==1 and UI.normalBg.alpha==0,'shell art ownership/opacity')
for _,spec in ipairs(UI.panels)do
    if spec~=actualSettings and spec~=actualQoL then
    -- RecipeBar's secure Craft action implicitly protects the window before
    -- later Professions/Settings controls are created. It must not stop them.
    if spec.key=='professions' then root.implicit=true end
    local p=spec.create(root);flush()
    assert(p.button.euiButton and p.edit.euiEdit and p.check.w==42 and p.check.h==24)
    assert(p.art.alpha==1 and p.model.kind=='PlayerModel')
    local r,g,b=p.row.name:GetTextColor();assert(r==1 and g==.5 and b==0,'rarity text changed')
    p.check:SetChecked(true);assert(p.check:GetChecked())
    for _,t in ipairs(p.check.regions)do if t.kind=='Texture' then assert(t.alpha==0,'native switch art overlaps EUI square') end end
    p.check:Disable();assert(not p.check:IsEnabled())
    p.check:SetChecked(false);p.check:Enable();p.check:SetChecked(true)
    for _,t in ipairs(p.check.regions)do if t.kind=='Texture' then t:SetAlpha(1);assert(t.alpha==0,'switch art resurrected') end end
    p.button:SetActive(true);assert(p.button.euiOfaSelection and p.button.euiOfaSelection:IsShown())
    assert(p.button._label:GetTextColor()==.91,'native active gold returned')
    end
end
flush()
if actualSettings then
    local active='Default';local actions=0
    local noop=function()actions=actions+1 end
    A.Profiles={Active=function()return active end,Names=function()return {'Default','Test'} end,
        Switch=function(name)active=name end,New=noop,Copy=noop,Rename=noop,Delete=noop,Export=noop,Import=noop,
        SendDialog=noop,SetReceive=noop,ReceiveEnabled=function()return true end}
    local settings=actualSettings.create(root);flush();settings:Show();flush()
    local buttons,checks,sliders,arrows,labels=0,0,0,0,0
    local function verify(f)
        if f.kind=='Button' and f._label then
            assert(f.euiButton,'real Settings button missed');buttons=buttons+1
            if f._label:GetText()=='New' then f.scripts.OnClick(f);assert(actions==1,'profile action lost')end
        elseif f.kind=='CheckButton' then
            checks=checks+1
            for _,t in ipairs(f.regions)do if t.kind=='Texture' then assert(t.alpha==0,'Settings native switch visible')end end
        elseif f.kind=='Slider' and f.orientation=='HORIZONTAL' then
            sliders=sliders+1;assert(f.thumb.alpha==0,'Settings slider missed')
        end
        if f.euiPageDirection then arrows=arrows+1 end
        for _,t in ipairs(f.regions)do if t.kind=='FontString' then assert(t.font==face,'real Settings font missed');labels=labels+1 end end
        for _,child in ipairs(f.children)do verify(child)end
    end
    verify(settings)
    assert(buttons>=10 and checks>=10 and sliders==1 and arrows>=2 and labels>30,'incomplete Settings fixture')
    print('PASS: real Settings factory: '..buttons..' buttons, '..checks..' switches, '..sliders..' slider, '..arrows..' reorder arrows; profile action retained')
end
if actualQoL then
    local options={{key='off',label='Off'}}
    local values={}
    local function no()return false end
    local function empty()return {} end
    local Q={Get=function(k)return values[k]end,Set=function(k,v)values[k]=v end,
        LOGO_COLORS={},MM_DIR_OPTIONS=options,CHAT_HIDE_OPTIONS=options,QUALITY_OPTIONS=options,
        WHO_OPTIONS=options,DUEL_OPTIONS=options,GetJunkItems=empty,GetNeverItems=empty,GetBuffReminders=empty,
        GetCVarSwitch=no,GetCompareShift=no,IsLootFeedUnlocked=no}
    A.QoL=Q
    local qos=actualQoL.create(root);flush();qos:Show();flush()
    local checks,navs={},{}
    local function verify(f)
        if f.kind=='CheckButton' then
            checks[#checks+1]=f
            for _,t in ipairs(f.regions)do if t.kind=='Texture' then assert(t.alpha==0,'real QoL switch art remains')end end
        elseif f.kind=='Button' and f.key and f.count then navs[#navs+1]=f end
        for _,child in ipairs(f.children)do verify(child)end
    end
    verify(qos)
    for _,b in ipairs(navs)do b:Click();flush()end
    assert(#navs==10 and #checks>40,'not all QoL categories exercised')
    for _,cb in ipairs(checks)do
        if cb.parent.name=='Farther camera zoom' then cb:Click();assert(values.cameraZoom==true,'native QoL setting action lost')end
    end
    for _,cb in ipairs(checks)do
        cb:SetChecked(true);cb:Disable();cb:SetChecked(false);cb:Enable()
        for _,t in ipairs(cb.regions)do if t.kind=='Texture' then assert(t.alpha==0,'QoL native switch reappeared after state change')end end
    end
    print('PASS: real QoL factory: '..#navs..' categories, '..#checks..' switches; native on/off/disabled artwork suppression')
end
local secure=CreateFrame('Button',nil,root);secure.protected=true
secure._label=A.NewFS(secure,nil,'OVERLAY','GameFontNormal');secure._label:SetText('Secure Craft')
m.refresh();flush();assert(not secure.euiButton and secure._label.font=='native-font','explicit secure action styled')
for _,direction in ipairs({'<','>'})do
    local b=CreateFrame('Button',nil,root);b:SetSize(20,20)
    b:SetNormalTexture('Interface\\Buttons\\UI-SpellbookIcon-'..(direction=='<' and 'PrevPage' or 'NextPage')..'-Up')
    A.SkinBlizz(b);flush();assert(b.euiPageDirection==direction and b.w==20 and b.h==20,'settings reorder arrow missed')
end
if UI.SmallCaps then
    local b,label,sorts
    local spec={key='headerTest',create=function(parent)
        local header=CreateFrame('Frame',nil,parent);header:SetSize(812,24)
        b=CreateFrame('Button',nil,header);b:SetSize(50,22)
        label=UI.SmallCaps(b,'Territory',12,9,{1,.82,.2})
        label:SetPoint('LEFT',b,'CENTER',-30,0)
        b.arrow=b:CreateTexture(nil,'OVERLAY');A.SetTex(b.arrow,UI.ASSET_ROOT..'sort_arrows');b.arrow:SetTexCoord(.25,.5,0,1)
        sorts=0;b:SetScript('OnClick',function()sorts=sorts+1;b.arrow:SetTexCoord(.5,.75,0,1)end)
        return header
    end}
    UI.RegisterPanel(spec);spec.create(root)
    flush();assert(label.w<=34 and label.regions[1]:GetText()=='Territory','sort caption not bounded')
    assert(label.regions[1].justify=='CENTER','native column alignment lost')
    assert(b.arrow.w==8 and b.arrow.uv[1]==.25,'sort geometry or native state lost')
    for i,t in ipairs(label.regions)do if i>1 then assert(t.alpha==0,'old small-caps segments remain')end end
    b.scripts.OnClick(b);assert(sorts==1 and b.arrow.uv[1]==.5,'native sort action changed')
end
if mainSource or UI.testMainTab then
    local tested=0
    for _,b in ipairs(root.children)do
        if b.ContentWidth and b.SetActive then
            b:SetActive(true)
            local glow
            for _,t in ipairs(b.regions)do
                if t.path==UI.ASSET_ROOT..'glow_line' then glow=t end
                if t.kind=='Texture' and (t.base or t.path=='Interface\\Buttons\\WHITE8X8') and t.layer=='BACKGROUND' and not (b.euiButton and t==b.euiButton.fill) then
                    assert(t.alpha==0,'nested tab selection plate remains')
                end
            end
            assert(glow and glow.h==4 and glow.alpha>0 and glow:IsShown(),'native tab glow missing')
            b:SetActive(false);assert(not glow:IsShown(),'inactive tab glow visible');tested=tested+1
        end
    end
    assert(tested>0,'main tabs not exercised')
end
local p=pages.armory
if source then
    local lateKnob=p.check:CreateTexture(nil,'OVERLAY');A.SetTex(lateKnob,UI.ASSET_ROOT..'knob');flush()
    assert(lateKnob.alpha==0,'late native switch knob escaped suppression')
end
-- Card fills have a higher sublayer than their edges. They must remain inset
-- at full opacity; checking RGB alone misses a correctly tinted hidden border.
local function visibleCard(card)
    local fill=card.fill.pieces[#card.fill.pieces]
    local edge=card.border.pieces[1]
    assert(fill.layer==edge.layer and fill.sub>edge.sub,'fixture no longer models native card layering')
    assert(not fill.all and #fill.points==2 and fill.points[1][4]==1 and fill.points[1][5]==-1
        and fill.points[2][4]==-1 and fill.points[2][5]==1,'card fill covers rarity border')
    for i=1,4 do assert(card.border.pieces[i].alpha>0,'quality edge faded')end
end
visibleCard(preSlot.card)
visibleCard(preRow.card)
local r,g,b=preRow.card.border.pieces[2]:GetVertexColor()
assert(r==accent[1] and g==accent[2] and b==accent[3],'pre-existing row lost selected state')
local slot=CreateFrame('Button',nil,root);slot:SetSize(38,38)
slot.card=UI.Card(slot,slot,4,{.28,.25,.2,.9},{.05,.05,.06,.95},'BACKGROUND',0)
slot.icon=slot:CreateTexture(nil,'ARTWORK');slot.icon:SetTexture('equipment-art');slot.icon:SetTexCoord(.07,.93,.07,.93)
local hover=slot:CreateTexture(nil,'HIGHLIGHT');hover:SetTexture('Interface\\Buttons\\ButtonHilight-Square')
slot.slot=1;local clicks=0;slot:SetScript('OnClick',function()clicks=clicks+1 end)
flush();visibleCard(slot.card);assert(not slot.euiButton and hover.alpha==1,'item hover/control replaced')
for q=0,7 do
    slot.q=q
    local c=ITEM_QUALITY_COLORS[q]
    slot.card:SetBorder(c.r,c.g,c.b,1)
    -- Native paintSlots uses decorative gold on selection. The item quality
    -- remains authoritative, including Poor, and no second border is created.
    slot.card:SetBorder(1,.82,.25,1)
    for i=1,4 do
        local r,g,b=slot.card.border.pieces[i]:GetVertexColor()
        assert(r==c.r and g==c.g and b==c.b,'equipped quality lost on selection '..q)
    end
end
slot.q=nil;slot.card:SetBorder(.28,.25,.20,.90)
local r,g,b=slot.card.border.pieces[1]:GetVertexColor();assert(r==.2 and g==.2 and b==.22,'cleared slot kept stale quality')
assert(slot.icon.path=='equipment-art' and slot.icon.uv[1]==.07 and slot.w==38 and slot.h==38,'equipment art/geometry changed')
slot.scripts.OnClick(slot);assert(clicks==1,'equipment selection action lost')
visibleCard(p.row.card)
for _,t in ipairs(p.row.regions)do
    if t.kind=='Texture' and t.layer=='HIGHLIGHT' then
        if t.path==UI.ASSET_ROOT..'rr_ring' then assert(t.alpha==0,'native gold hover ring remains')
        elseif t.base then assert(t.base[1]==1 and t.base[2]==1 and t.base[3]==1 and t.base[4]==.06,'native gold hover wash remains')end
    end
end
p.row.card:SetSelected(true)
local selectedFill=p.row.card.fill.pieces[#p.row.card.fill.pieces]
local r,g,b,a=selectedFill:GetVertexColor()
assert(math.abs(r-(.08*.9+accent[1]*.1))<.00001 and a>.5,'selected row is not one cohesive surface')
for i=1,4 do
    local r,g,b=p.row.card.border.pieces[i]:GetVertexColor()
    if i==2 then assert(r==accent[1] and g==accent[2] and b==accent[3],'selected accent edge missing')
    else assert(r==.2 and g==.2 and b==.22,'selected row has multiple accent borders')end
end
p.row.card:SetSelected(false)
local r,g,b=p.row.card.border.pieces[2]:GetVertexColor();assert(r==.2 and g==.2 and b==.22,'recycled row retained accent')
local foreign=CreateFrame('Frame','UnrelatedBlizzardWindow',UIParent)
local foreignText=A.NewFS(foreign,nil,'OVERLAY','GameFontNormal');foreignText:SetTextColor(1,.82,.2)
local foreignButton=UI.GoldButton(foreign,'Foreign',80,24)
local hud=CreateFrame('Frame','OneForAllMinimapCollectorBar',UIParent)
UI.FramedPanel(hud)
local hudButton=UI.GoldButton(hud,'HUD',80,24)
flush();assert(not foreignButton.euiButton and foreignText.font=='native-font' and not hudButton.euiButton and not shells[hud],
    'helpers styled a foreign window or excluded gameplay HUD')
local a,b,c=p.button.scripts.OnClick(p.button);assert(a=='native-click' and b==nil and c==7 and p.clicked==1)
assert(p.button.scripts.OnEnter(p.button)=='native-tooltip')
for q=0,7 do
    local colour=ITEM_QUALITY_COLORS[q]
    p.row.card:SetBorder(colour.r,colour.g,colour.b,1)
    local t=p.row.card.border.pieces[1];local r,g,b=t:GetVertexColor()
    assert(r==colour.r and g==colour.g and b==colour.b,'native rarity ring '..q)
end
p.row.card:SetSelected(true);p.row.card:SetFill(.035,.16,.055,.9)
local fill=p.row.card.fill.pieces[#p.row.card.fill.pieces]
local fr,fg,fb=fill:GetVertexColor();assert(fr==.035 and fg==.16 and fb==.055,'quest completion fill lost')
p.row.card:SetFill(.22,.17,.04,.92)
local fr,fg,fb=fill:GetVertexColor();assert(fr==.22 and fg==.17 and fb==.04,'quest in-log fill lost')
p.row.card:SetSelected(false)
-- Owned popup discovery, dropdown recycling and independent removal state.
local popup=CreateFrame('Frame','OneForAllProfilePopup',UIParent)
UI.FramedPanel(popup)
popup.edit=A.SkinBlizz(CreateFrame('EditBox',nil,popup));popup.edit:SetText('keep this input')
popup.action=UI.GoldButton(popup,'Import',90,24)
popup.pic=popup:CreateTexture(nil,'ARTWORK');popup.pic:SetTexture(UI.ASSET_ROOT..'preview_example')
flush();S.Shell(popup);assert(popup.pic.alpha==1,'late preview art lost on theme strip')
assert(shells[popup] and popup.edit.euiEdit and popup.action.euiButton and popup.edit:GetText()=='keep this input')
if UI.OpenDropDown then
    local picked
    UI.OpenDropDown(p.button,{{key='first',label='First'},{key='second',label='Second',remove=true}},'second',function(k)picked=k end)
    flush()
    local menu
    for _,f in ipairs(UIParent.children)do if f.rows and f.owner==p.button then menu=f end end
    assert(menu and shells[menu] and menu.rows[2].del:IsShown() and menu.rows[2].check:IsShown())
    menu.rows[1].scripts.OnClick(menu.rows[1]);assert(picked=='first')
    UI.OpenDropDown(p.button,{{key='first',label='First'}},'first',function(k)picked=k end)
    flush();assert(menu.rows[1]:IsShown() and not menu.rows[2]:IsShown())
    assert(menu.rows[1].check:IsShown() and not menu.rows[1].del:IsShown())
end
if UI.QuietHead then
    local header=CreateFrame('Button',nil,root)
    local arrow,title=UI.QuietHead(header,'Group')
    flush();assert(header.euiButton and arrow.alpha==1 and title.font==face)
    arrow:SetTexCoord(.5,1,0,1);assert(arrow.uv[1]==.5, 'collapse indicator changed')
end
local value
local slider=UI.Slider(root,150,0,1,.1,function(v)value=v end)
slider:SetValue(.4);flush();assert(value==.4 and slider:GetValue()==.4 and slider:GetThumbTexture().alpha==0)
assert(slider:GetThumbTexture():GetWidth()==(source and 24 or 30),'native drag geometry changed')
p.button:Disable();assert(p.button._label:GetTextColor()==.45)
p.button:Enable();assert(p.button._label:GetTextColor()==.91,'enabled label stayed disabled grey');p.button:SetActive(true)
-- Same-count replacements are observed through their constructor, not counts.
local retired=UI.GoldButton(root,'retired',90,24);flush()
local before=#root.children
for i,f in ipairs(root.children)do if f==retired then table.remove(root.children,i);break end end
retired:Hide()
local replacement=UI.GoldButton(root,'replacement',90,24);flush();assert(replacement.euiButton)
assert(#root.children==before, 'fixture did not replace a control at the same child count')
local o,h,reads,geo,fw=count.objects,count.hooks,count.reads,count.geometry,count.fonts
for i=1,1000 do
    A.ToggleUI();p.button:SetActive(i%2==0);p.row.card:SetSelected(i%2==0)
    p.check:SetChecked(i%2==0)
end
flush()
assert(count.fonts==fw and count.objects==o and count.hooks==h and count.reads==reads and count.geometry-geo==(source and 2000 or 0),
    'warm interaction counts: '..table.concat({count.objects-o,count.hooks-h,count.reads-reads,count.geometry-geo},','))
accent={.9,.2,.3};face='changed-font';for _,fn in ipairs(looks)do fn()end;flush()
local r,g,b=p.button.euiOfaSelection:GetVertexColor();assert(r==.9 and g==.2 and b==.3)
local r,g,b=p.row.card.border.pieces[2]:GetVertexColor();assert(r==.9 and g==.2 and b==.3,'row indicator did not follow accent')
assert(p.button._label.font==face)
if mainSource then UI.SetWindowAlpha(.7)else UI.alpha=.7;UI.ApplyWindowAlpha()end;for _,t in ipairs(shells[root])do assert(t.alpha==.7)end
UI.banner:SetAlpha(0);UI.brandLogo:SetAlpha(0);assert(UI.banner.alpha==1 and UI.brandLogo.alpha==1)
-- Closed, unrelated data updates and scrolling do not schedule discovery.
root:Hide();local reads=count.reads
for i=1,1000 do A.SetTex(p.art,'map-art-'..i)end
assert(count.reads==reads and #timers==0)
-- A new late control while disabled stays native, then explicit refresh finds it.
enabled=false;local late=UI.GoldButton(root,'late',90,24);assert(not late.euiButton)
enabled=true;m.refresh();flush();assert(late.euiButton)
combat=true;local locked=UI.GoldButton(root,'combat',90,24);assert(not locked.euiButton)
UI.banner:SetAlpha(0);for _,t in ipairs(shells[root])do t:SetAlpha(1)end
combat=false;for _,f in ipairs(events)do if f.events and f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent(f,'PLAYER_REGEN_ENABLED')end end
m.refresh();flush();assert(locked.euiButton and UI.banner.alpha==1)
for _,t in ipairs(shells[root])do assert(t.alpha==.7)end
-- Optional target absent and the pre-existing Forever Companion namespace stay independent.
OneForAll=nil;assert(not m.available());OneForAll=A
print('PASS: OneForAll '..client..' '..(source and 'upstream Widgets.lua' or 'source-shaped')..': eight lazy sections, native actions/returns, rarity/art/model ownership, pooled state, theme/opacity/toggle/combat')
print('BENCH OneForAll mock: 1000 warm reopen/selection/check cycles: new objects/hooks and child/region discovery reads=0; skin geometry writes=0 (upstream knob moves excluded); 1000 closed texture updates: queued work=0')
end
