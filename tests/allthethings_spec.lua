-- Source-shaped ATT window pools and Settings.RegisterObject lifecycle.
local enabled, combat, allocated, hookCount = true, false, 0, 0
local errors, timers, looks, events, handlers = {}, {}, {}, {}, {}
local module, factory, fontFace, accent = nil, nil, 'EUI', 0.25
local ns = {IsEnabled = function() return enabled end}
ns.RegisterSkinDefinition = function(id, fn) assert(id == 'AllTheThings'); factory = fn end
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
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:GetFont() return self.path,self.size,self.flags end
    function f:SetFont(path,size,flags) assert(not combat); self.path,self.size,self.flags=path,size,flags end
    function f:SetFontObject() self.path='Native'; self.size=15; self.flags='' end
    function f:SetTextColor(...) self.color={...} end
    function f:GetAlpha() return self.alpha end
    function f:SetAlpha(v) self.alpha=v end
    function f:SetColorTexture(...) self.color={...} end
    function f:SetVertexColor(...) self.vertex={...} end
    function f:SetTexture(v) self.texture=v end
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
S.Font=function(f) f:SetFont(fontFace, f.size, '') end
S.Panel=function(f) f.panel=true; f:CreateTexture(nil,'BACKGROUND') end
S.ScrollBar=function(f) f.scroll=true end
S.CloseButton=function(f) f.close=true end
S.Checkbox=function(f) f.check=true end
S.Button=function(f) f.button=true end
S.EditBox=function(f) f.input=true end
S.Dropdown=function(f) f.dropdown=true end
S.StateButtonLabel=function(f) f.stateLabel=true end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins',ns)
assert(loadfile('EUIAddonSkins/Skins/AllTheThings.lua'))('EUIAddonSkins',ns)
assert(not module and factory, 'skin should defer its implementation')
factory(); AllTheThings=nil; assert(not module.available())
local function Row(parent)
    local row=Object('Button',parent); row.Label=Text(row); row.Summary=Text(row)
    row.Texture=row:CreateTexture(nil,'ARTWORK'); row.Texture.texture='item'
    row.Indicator=row:CreateTexture(nil,'ARTWORK'); row.Background=row:CreateTexture(nil,'BACKGROUND')
    row.highlight=row:CreateTexture(nil,'HIGHLIGHT'); return row
end
local function Window()
    local w=Object('Frame'); w.backdrop={bgFile='native'}; w.Grip=w:CreateTexture(nil,'ARTWORK')
    w.native=w:CreateTexture(nil,'BACKGROUND'); w.CloseButton=Object('Button',w)
    w.ScrollBar=Object('Slider',w); w.ScrollBar.thumb=Object('Texture')
    w.Container=Object('Frame',w); w.Container.rows=setmetatable({Row(w.Container)}, {
        __index=function() error('skinning instantiated a lazy collection row') end})
    w.DefaultRedraw=function(self) self.Container.rows[1].Label:SetFontObject('GameFontNormal') end
    w.scripts.OnShow=function() w.nativeShow=true end
    return w
end
local settings=Object('Frame'); local page=Object('Frame'); settings:RegisterObject(page)
local check=Object('CheckButton',page); check.Text=Text(check); check.checked=true
check.checkedArt=Object('Texture'); check.disabledArt=Object('Texture'); page:RegisterObject(check)
local slider=Object('Slider',page); slider.orientation='HORIZONTAL'; slider.thumb=Object('Texture'); page:RegisterObject(slider)
local nativeCalls=0; settings.CreateOptionsPage=function(self)
    nativeCalls=nativeCalls+1; local p=Object('Frame'); self:RegisterObject(p); return p,'native-return'
end
local prime=Window(); AllTheThings={Windows={Prime=prime},Settings=settings,
    GetWindow=function() error('skin must not force ATT window creation') end,
    AddEventHandler=function(event,fn) assert(not handlers[event]); handlers[event]=fn end}
AllTheThings.ShowPopupDialogWithMultiLineEditBox=function()
    ATTEditBox=Object('Frame'); ATTEditBox.Label=Text(ATTEditBox)
    ATTEditBox.EditBox=Object('EditBox',ATTEditBox); ATTEditBox.EditBox.IsMultiLine=function() return true end
    ATTEditBox.EditBox.text='native export data'
    ATTEditBox.Button=Object('Button',ATTEditBox); ATTEditBox.Button.Text=Text(ATTEditBox.Button)
    return 'dialog-return'
end
assert(module.available()); module.install(S,module); Flush()
local row=prime.Container.rows[1]
assert(row.Label.path=='EUI' and row.Summary.path=='EUI' and row.Label.color[2]==0.8)
assert(row.Texture.texture=='item' and row.Background.alpha==1 and row.Indicator.alpha==1)
assert(prime.native.alpha==0 and prime.Grip.alpha==1 and prime.backdrop.bgFile=='native')
assert(prime.CloseButton.close and prime.ScrollBar.thumb.width==5)
assert(check.check and check.checked and check.checkedArt.color[1]==accent and slider.thumb.width==8)
check:Disable(); assert(check.Text.color[1]==0.48 and check.checked)
check:Enable(); assert(check.Text.color[1]==0.9)
local oldSize=row.Label.size; prime:DefaultRedraw(); assert(row.Label.path=='EUI' and row.Label.size==15)
local count,hooks=allocated,hookCount
for _=1,100 do prime:DefaultRedraw() end
assert(allocated==count and hookCount==hooks, 'warm redraw creates UI objects or duplicate hooks')
local other=Window(); AllTheThings.Windows.MiniList=other; handlers.OnWindowCreated(other,'MiniList')
assert(other.CloseButton.close and other.Container.rows[1].Label.path=='EUI')
local fresh,marker=settings:CreateOptionsPage('new'); assert(marker=='native-return' and nativeCalls==1)
local late=Object('CheckButton'); late.Text=Text(late); late.checkedArt=Object('Texture'); late.disabledArt=Object('Texture')
fresh:RegisterObject(late); Flush(); assert(late.check and late.Text.path=='EUI', 'late settings controls missed')
assert(AllTheThings.ShowPopupDialogWithMultiLineEditBox()=='dialog-return')
assert(ATTEditBox.Button.button and ATTEditBox.EditBox.path=='EUI' and not ATTEditBox.EditBox.input
    and ATTEditBox.EditBox.text=='native export data', 'multiline dialog lost native editor behaviour')
fontFace='EUI-new'; accent=0.7; looks[1](); Flush()
assert(row.Label.path==fontFace and late.checkedArt.color[1]==0.7, 'theme/accent refresh missed')
local saved=prime.backdrop; prime:SetBackdrop({bgFile='changed-by-ATT'}); assert(prime.backdrop.bgFile=='changed-by-ATT')
enabled=false; local before=allocated; local disabled=Window(); local nativeAllocated=allocated
AllTheThings.Windows.Disabled=disabled; handlers.OnWindowCreated(disabled); assert(allocated==nativeAllocated and not disabled.CloseButton.close)
row.Label.path='native'; prime:DefaultRedraw(); assert(row.Label.path=='Native', 'disabled skin still processes rows')
enabled=true; combat=true; handlers.OnWindowCreated(disabled); assert(not disabled.CloseButton.close)
combat=false; for _,f in ipairs(events) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent(f) end end
Flush(); assert(disabled.CloseButton.close, 'combat-deferred window never styled')
local protected=Window(); protected.protected=true; handlers.OnWindowCreated(protected); assert(not protected.CloseButton.close)
assert(#errors==0,table.concat(errors,'\n'))
AllTheThings=nil
ATTEditBox=nil
print('PASS: ATT lazy windows, row reuse, native colours/actions/profile backdrops, settings construction, theme updates, disable/combat gates and stable warm allocations')
