-- Source-shaped OneForAll 6.0.1 construction/state workload. An optional local
-- upstream Widgets.lua can exercise the real constructors without bundling it.
for _,client in ipairs({'Retail','Forever'}) do
WOW_PROJECT_MAINLINE, WOW_PROJECT_CAMELOT = 1, 99
WOW_PROJECT_ID = client=='Retail' and WOW_PROJECT_MAINLINE or WOW_PROJECT_CAMELOT
for _,suffix in ipairs({'Frame','ProfilePopup','Confirm','BugReport','Discord','CraftList','QuestChain','WeightEditor','TrainerSpells','TalentCode','Welcome','WhatsNew','PreviewFrame','QuestSharePopup'})do _G['OneForAll'..suffix]=nil end
local timers, modules, looks, events = {}, {}, {}, {}
local count = {objects=0,hooks=0,reads=0,geometry=0,fonts=0,scans=0,colours=0}
local enabled, combat, accent, face = true, false, {.1,.7,.9}, 'eui-font'
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
    function f:IsProtected()return self.protected end
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
    function f:GetTexture()return self.path end
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
    function f:SetJustifyH(v)self.justify=v end
    function f:SetJustifyV()end
    function f:SetShadowOffset()end
    function f:SetTextInsets(...)self.insets={...}end
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
    function f:GetOrientation()return self.orientation end
    function f:SetOrientation(v)self.orientation=v end
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
        for i=1,9 do local t=owner:CreateTexture(nil,layer);t:SetTexture(UI.ASSET_ROOT..(tex or 'rr_fill'));v.pieces[i]=t end
        function v:SetColor(...)for _,t in ipairs(self.pieces)do t:SetVertexColor(...)end end
        function v:SetShown(on)for _,t in ipairs(self.pieces)do t:SetShown(on)end end
        v:SetColor(r,g,b,a or 1);return v
    end
    function UI.Card(owner,anchor)
        local v={fill=UI.RoundRect(owner,anchor,'BACKGROUND',0,4,1,.06,.06,.07,1),
            border=UI.RoundRect(owner,anchor,'BORDER',0,4,0,.28,.25,.2,1,'rr_ring_w')}
        function v:SetFill(...)self.fill:SetColor(...)end
        function v:SetBorder(...)self.border:SetColor(...)end
        return v
    end
    function UI.CardRow(f)
        local c=UI.Card(f,f)
        function c:SetSelected(on)self:SetBorder(on and 1 or .28,.8,.34,1);self:SetFill(.22,.155,.055,.98)end
        return c
    end
    function UI.GlowLine(f)
        local t=f:CreateTexture(nil,'ARTWORK');t:SetTexture(UI.ASSET_ROOT..'glow_line');return t
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
    end
    return 'native-toggle',nil,42
end
local mainSource=os.getenv('ONEFORALL_MAINFRAME')
if mainSource then
    OneForAllDB={window={alpha=.95}};OneForAllCharDB={}
    A.Refresh=function()end
    assert(loadfile(mainSource))('OneForAll',A)
end
assert(loadfile('EUIAddonSkins/Skins/OneForAll.lua'))('EUIAddonSkins',ns)
local m=assert(modules.OneForAll);assert(m.available())
m.install(S,m);flush()
local r,n,last=A:ToggleUI();flush()
if not mainSource then assert(r=='native-toggle' and n==nil and last==42)end
local root=UI.mainWindow
if mainSource then
    for _,t in ipairs(root.regions)do
        if t.GetTexture and t:GetTexture()==UI.ASSET_ROOT..'header_banner' then UI.banner=t end
        if t.GetTexture and t:GetTexture()==UI.ASSET_ROOT..'rr_fill' then UI.normalBg=t end
    end
end
assert(UI.banner.alpha==1 and UI.brandLogo.alpha==1 and UI.normalBg.alpha==0,'shell art ownership/opacity')
for _,spec in ipairs(UI.panels)do local p=spec.create(root);flush()
    assert(p.button.euiButton and p.edit.euiEdit and p.check.w==42 and p.check.h==24)
    assert(p.art.alpha==1 and p.model.kind=='PlayerModel')
    local r,g,b=p.row.name:GetTextColor();assert(r==1 and g==.5 and b==0,'rarity text changed')
    p.check:SetChecked(true);assert(p.check:GetChecked())
    p.button:SetActive(true);assert(p.button.euiOfaSelection and p.button.euiOfaSelection:IsShown())
    assert(p.button._label:GetTextColor()==.91,'native active gold returned')
end
flush()
local p=pages.armory
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
p.row.card:SetFill(.035,.16,.055,.9)
local fill=p.row.card.fill.pieces[#p.row.card.fill.pieces]
local fr,fg,fb=fill:GetVertexColor();assert(fr==.035 and fg==.16 and fb==.055,'quest completion fill lost')
p.row.card:SetFill(.22,.17,.04,.92)
local fr,fg,fb=fill:GetVertexColor();assert(fr==.22 and fg==.17 and fb==.04,'quest in-log fill lost')
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
p.button:Enable();p.button:SetActive(true)
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
