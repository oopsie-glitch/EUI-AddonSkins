-- LFG Forever 2.6.0 source-shaped UI; no target business logic is replaced.
do
local keys={"CreateFrame","InCombatLockdown","hooksecurefunc","geterrorhandler","LFGForeverFrame","LFGForever_ToggleWindow","LFGForever_OnAddonCompartmentClick","LFGForeverMinimapButton","LFGForeverSearchKeyButton","LFGForeverBlizzardTab","SlashCmdList","Menu"}
local saved={};for _,k in ipairs(keys)do saved[k]=_G[k]end
local combat,enabled=false,true
local stats={frames=0,textures=0,hooks=0,fonts=0,colors=0,reads=0,popup=0}
local errors,looks,events={},{},{}
local function texture()
    stats.textures=stats.textures+1
    local t={alpha=1,width=14,height=14}
    function t:GetObjectType()return "Texture"end
    function t:IsProtected()return false end
    function t:IsForbidden()return false end
    function t:GetAlpha()return self.alpha end
    function t:SetAlpha(v)self.alpha=v end
    function t:GetDrawLayer()return "ARTWORK"end
    function t:GetWidth()return self.width end
    function t:GetHeight()return self.height end
    function t:SetColorTexture(...)self.color={...}end
    function t:SetVertexColor(...)self.color={...}end
    function t:ClearAllPoints()end
    function t:SetPoint(...)self.point={...}end
    function t:SetSize(w,h)self.width,self.height=w,h end
    function t:SetHeight(h)self.height=h end
    function t:SetShown(value)self.shown=value end
    function t:SetAllPoints()end
    return t
end
local function font()
    local t={path="native",size=12,flags="",color={.1,.7,.3,.8}}
    function t:GetObjectType()return "FontString"end
    function t:IsProtected()return false end
    function t:IsForbidden()return false end
    function t:GetFont()return self.path,self.size,self.flags end
    function t:GetTextColor()return table.unpack(self.color)end
    function t:SetTextColor(...)stats.colors=stats.colors+1;self.color={...}end
    function t:SetFont(p,size,flags)assert(size>0);stats.fonts=stats.fonts+1;self.path,self.size,self.flags=p,size,flags end
    return t
end
local function frame(kind,parent)
    stats.frames=stats.frames+1
    local f={kind=kind or "Frame",parent=parent,children={},regions={},scripts={},callbacks={},shown=true,width=30,height=30}
    if parent then parent.children[#parent.children+1]=f end
    function f:GetObjectType()return self.kind end
    function f:IsProtected()return self.protected end
    function f:IsForbidden()return false end
    function f:GetParent()stats.parents=(stats.parents or 0)+1;return self.parent end
    function f:GetChildren()stats.reads=stats.reads+1;return table.unpack(self.children)end
    function f:GetRegions()stats.reads=stats.reads+1;return table.unpack(self.regions)end
    function f:GetFrameLevel()return 1 end
    function f:GetWidth()return self.width end
    function f:GetHeight()return self.height end
    function f:GetFontString()return self.Text end
    function f:RegisterEvent(e)self.callbacks[e]=true end
    function f:UnregisterEvent(e)self.callbacks[e]=nil end
    function f:SetScript(k,fn)self.scripts[k]=fn end
    function f:HasScript()return true end
    function f:HookScript(k,fn)
        stats.hooks=stats.hooks+1;local old=self.scripts[k]
        self.scripts[k]=function(...)if old then old(...)end;fn(...)end
    end
    function f:IsShown()return self.shown end
    function f:Show()self.shown=true;if self.scripts.OnShow then self.scripts.OnShow(self)end end
    function f:Hide()self.shown=false;if self.scripts.OnHide then self.scripts.OnHide(self)end end
    function f:SetBackdrop(v)assert(not combat);self.backdrop=v end
    function f:CreateTexture()local t=texture();self.regions[#self.regions+1]=t;return t end
    function f:GetCheckedTexture()return self.Checked end
    function f:GetDisabledCheckedTexture()return self.DisabledChecked end
    return f
end
local function label(parent)
    local t=font();parent.regions[#parent.regions+1]=t;return t
end
local function button(parent)
    local b=frame("Button",parent);b.Text=label(b);b.clicks=0
    b.scripts.OnClick=function(self)self.clicks=self.clicks+1;return "native-click"end
    return b
end
local function list(parent)
    local box=frame("Frame",parent);local view={callbacks={}};box.rows={}
    function view:RegisterCallback(k,fn,owner)
        assert(k=="OnInitializedFrame");assert(not self.callbacks[k],"duplicate view callback")
        self.callbacks[k]={fn,owner}
    end
    function box:GetView()return view end
    function box:ForEachFrame(fn)for _,r in ipairs(self.rows)do fn(r)end end
    function box:Initialize(r)
        r.Text=r.Text or label(r) -- Native constructor completed before event.
        local c=view.callbacks.OnInitializedFrame
        if c then c[1](c[2],r)end
    end
    parent.ScrollBox=box;parent.ScrollBar=frame("Frame",parent)
    return box,view
end
CreateFrame=function(kind)
    local f=frame(kind);events[#events+1]=f;return f
end
InCombatLockdown=function()return combat end
geterrorhandler=function()return function(e)errors[#errors+1]=e end end
hooksecurefunc=function(o,k,fn)
    stats.hooks=stats.hooks+1;local old=o[k]
    o[k]=function(...)local r=table.pack(old(...));fn(...);return table.unpack(r,1,r.n)end
end
local ns={IsEnabled=function()return enabled end,AttachAccent=function()end}
local installed,module,definition
ns.RegisterSkinDefinition=function(id,fn)assert(id=="LFGForever");definition=fn end
ns.RegisterModule=function(id,_,available,install)
    assert(id=="LFGForever");module={};installed={available=available,install=install}
end
local accent={.9,.5,.2}
local S={}
function S.GetFont()return "eui",""end
function S.GetAccentColor()return table.unpack(accent)end
function S.Font(t,r,g,b)local _,size=t:GetFont();t:SetFont("eui",size,"");if r then t:SetTextColor(r,g,b)end end
function S.OnLooksChanged(fn)looks[#looks+1]=fn end
local function art(f,field)assert(not combat);if not f[field]then f[field]=f:CreateTexture()end end
function S.Shell(f,opts)assert(opts.noAccent);art(f,"shell")end
function S.Panel(f)art(f,"panel")end
function S.FadeNineSlice(f)f.faded=true end
function S.Button(f,keep)
    art(f,"button")
    if not f.registeredKeep then
        f.registeredKeep={}
        for _,key in ipairs(keep or {})do if f[key]then f.registeredKeep[f[key]]=true end end
    end
end
function S.Checkbox(f)art(f,"checkArt");if f.Icon then f.Icon:SetAlpha(0)end end
function S.Dropdown(f)art(f,"dropdown")end
function S.EditBox(f)art(f,"editArt")end
function S.ScrollBar(f)art(f,"scrollArt")end
function S.CloseButton(f)art(f,"closeArt")end
function S.Tab(f)art(f,"tabArt")end
function S.StateButtonLabel()end
ns.BindPopupList=function(_,m,owner,popup)
    assert(m==module and owner);stats.popup=stats.popup+1
    popup.owner=owner;popup.eui=true
end
ns.RefreshPopupMenusNow=function()
    local popup=Menu.GetManager():GetOpenMenu()
    if popup and popup.owner~=popup:GetOwnerRegion()then popup.eui=false end
end
local manager={}
function manager:GetOpenMenu()self.reads=(self.reads or 0)+1;return self.current end
function manager:OpenMenu(owner)
    local popup=frame("Frame");popup.openOwner=owner
    function popup:GetOwnerRegion()return self.openOwner end
    self.current=popup;return "native-menu"
end
manager.OpenContextMenu=manager.OpenMenu
Menu={GetManager=function()return manager end}
SlashCmdList={}
_G.LFGForever_ToggleWindow=nil;_G.LFGForeverFrame=nil
assert(loadfile("EUIAddonSkins/Widgets.lua"))("EUIAddonSkins",ns)
assert(loadfile("EUIAddonSkins/Skins/LFGForever.lua"))("EUIAddonSkins",ns)
assert(definition and not installed,"absent target activated implementation")
definition();assert(not installed.available(),"missing target reported available")
local function build()
    if _G.LFGForeverFrame then return _G.LFGForeverFrame end
    local root=frame();root.width=1600;root.height=900
    root.Content=frame("Frame",root);local c=root.Content
    root.CloseButton=button(root);root.ResizeButton=button(root);root.DragBar=button(root)
    c.TitleText=label(c);c.PortraitContainer=texture();c.ReportBug=button(c)
    c.FilterPanel=frame("Frame",c);c.ListPanel=frame("Frame",c)
    local p=c.FilterPanel
    root.side=frame("Frame",root);root.side.Icon=texture();root.side.chrome=root.side:CreateTexture()
    function root.side:SetChecked(value)self.checked=value;self.chrome:SetAlpha(1)end
    function root.side:GetChecked()return self.checked end
    root.side:SetChecked(true)
    p.TabSystem=frame("Frame",p)
    for _=1,3 do button(p.TabSystem)end
    p.SettingsGear=button(p);p.dropdown=frame("DropdownButton",p)
    p.dropdown.scripts.OnMouseDown=function(self)self.opened=true end
    p.check=frame("CheckButton",p);p.check.Checked=texture();p.check.DisabledChecked=texture()
    p.check.Icon=texture();p.check.checked=true;p.check.scripts.OnClick=function(self)self.checked=not self.checked end
    p.WhisperLog=frame("Frame",p);p.PlayerRatings=frame("Frame",p)
    p.WhisperLog.shown=false;p.PlayerRatings.shown=false
    function p:SetTab(which)self.selected=which end
    list(c.ListPanel);list(p.WhisperLog);list(p.PlayerRatings)
    local stars=frame("Frame",p.PlayerRatings)
    p.star=frame("Button",stars);p.star.Unearned=texture();p.star.Earned=texture()
    p.star.scripts.OnClick=function(self)self.rating=3 end
    _G.LFGForeverFrame=root
    return root
end
LFGForever_ToggleWindow=function()build():Show();return "native",nil,7 end
LFGForever_OnAddonCompartmentClick=function()build():Show()end
LFGForeverMinimapButton=button();LFGForeverMinimapButton.scripts.OnClick=function()build():Show()end
LFGForeverSearchKeyButton=button();LFGForeverSearchKeyButton.scripts.OnClick=function()build():Show()end
LFGForeverBlizzardTab=frame();LFGForeverBlizzardTab.scripts.OnMouseUp=function()build():Show()end
SlashCmdList.LFGFOREVER=function()build():Show()end
assert(installed.available());installed.install(S,module)
assert(not _G.LFGForeverFrame,"skin forced lazy target construction")
local a,b,c=LFGForever_ToggleWindow();assert(a=="native"and b==nil and c==7)
local r=LFGForeverFrame;local p=r.Content.FilterPanel
assert(r.Content.shell and p.panel and r.Content.ListPanel.panel and r.CloseButton.closeArt)
assert(p.dropdown.dropdown and p.check.checkArt and p.check.Icon.alpha==1)
assert(r.side.button and r.side.Icon.alpha==1 and r.side.chrome.alpha==0,"frame-based side tab not skinned")
r.side:SetChecked(false);assert(r.side.chrome.alpha==0 and r.side.Icon.alpha==1)
r.side:SetChecked(true);assert(r.side.chrome.alpha==0)
assert(p.check.Checked.width==10 and p.check.width==30 and p.check.checked)
assert(r.width==1600 and r.height==900 and r.ResizeButton.button==nil and r.DragBar.button==nil)
assert(r.Content.TitleText.color[1]==accent[1]and p.check.Icon.alpha==1)
assert(p.star.button==nil and p.star.Unearned.alpha==1)
-- Real public engine's Restrip must preserve the existing owned accent.
local sideArt=r.side.euiLFGSideAccent or r.side.regions[#r.side.regions]
local function fadeRegions(f,keep)
    for _,texture in ipairs(f.regions)do if not keep[texture]then texture:SetAlpha(0)end end
end
local registry={[r.side]=r.side.registeredKeep or {}}
local function restrip()
    local keep=registry[r.side];keep[r.side.button]=true;fadeRegions(r.side,keep)
end
local engineSource=os.getenv("LFG_EUI_ENGINE_SOURCE")
if engineSource then
    local file=assert(io.open(engineSource));local code=file:read("*a");file:close()
    code=code:gsub("\r","")
    local first=assert(code:find("local function Restrip(winKey)",1,true))
    local last=assert(code:find("\nend",first,true))
    restrip=assert(load("local _windowRestrips,_restrip,FFD,PROTECT_KEYS,FadeRegions=...;"..code:sub(first,last+3).."\nreturn Restrip"))(
        {},registry,{[r.side]={bg=r.side.button}},{"bg"},fadeRegions)
end
restrip()
assert(sideArt.alpha==1,"custom side accent was stripped by supported EUI refresh")
p.star.scripts.OnClick(p.star);assert(p.star.rating==3)
p.dropdown.scripts.OnMouseDown(p.dropdown);assert(p.dropdown.opened)
p.check.scripts.OnClick(p.check);assert(not p.check.checked)
p:SetTab("Whispers");assert(p.selected=="Whispers")
local boxes={r.Content.ListPanel.ScrollBox,p.WhisperLog.ScrollBox,p.PlayerRatings.ScrollBox}
for _,box in ipairs(boxes)do
    local row=frame("Button",box);row.Icon=texture()
    row.scripts.OnClick=function(self)self.selected=true end
    box.rows={row};box:Initialize(row)
    assert(row.Text.path=="eui"and row.Text.color[2]==.7,"new row not styled before visibility")
    row.scripts.OnClick(row);assert(row.selected and row.Icon.alpha==1 and not row.button,"data row was treated as an ordinary action button")
    local nested=button(row);box:Initialize(row);assert(nested.button,"late row child not styled")
    local replacement=button(row);row.children[#row.children-1]=replacement;box:Initialize(row)
    assert(replacement.button,"same-count replacement missed")
end
local callbacks=0;for _,box in ipairs(boxes)do for _ in pairs(box:GetView().callbacks)do callbacks=callbacks+1 end end
assert(callbacks==3)
-- Audit regressions: inactive pages must not become traversal triggers.
local pageReads=stats.reads
p.WhisperLog.scripts.OnShow(p.WhisperLog)
p.PlayerRatings.scripts.OnShow(p.PlayerRatings)
assert(stats.reads-pageReads<=14,"warm page show rescanned initialized rows")
local lateStatic=button(p.WhisperLog)
p.WhisperLog.scripts.OnShow(p.WhisperLog)
assert(lateStatic.button and lateStatic.Text.path=="eui","late static page control missed first show")
r:Hide()
local hiddenReads,hiddenFonts=stats.reads,stats.fonts
module.refresh()
assert(stats.reads==hiddenReads and stats.fonts==hiddenFonts,"hidden theme refresh traversed window")
local hidden=frame("Button",boxes[1]);hidden.Text=label(hidden);boxes[1].rows[#boxes[1].rows+1]=hidden
boxes[1]:Initialize(hidden)
assert(hidden.Text.path=="native" and stats.reads==hiddenReads,"hidden view notification performed cosmetic traversal")
r:Show()
assert(hidden.Text.path=="eui","deferred hidden row missed first show")
local ancestry=stats.parents
for _=1,100 do boxes[1]:Initialize(boxes[1].rows[1])end
assert(stats.parents-ancestry<=800,"descendant ancestry was rechecked at every node")
local foreignRow=frame("Button",frame());foreignRow.Text=label(foreignRow)
boxes[1]:Initialize(foreignRow);assert(foreignRow.Text.path=="native","foreign callback bypassed ownership boundary")
-- A stale GetChildren snapshot must not authorize a reparented child.
local reparented=button(frame());reparented.Text.path="native"
local ownedRow=boxes[1].rows[1]
ownedRow.children[#ownedRow.children+1]=reparented
boxes[1]:Initialize(ownedRow)
assert(reparented.Text.path=="native","reparented snapshot child escaped direct-edge ownership check")
ownedRow.children[#ownedRow.children]=nil
local sideBar=r.side.euiLFGSideAccent or r.side.regions[#r.side.regions]
local sideColor=sideBar.color;r.side:SetChecked(true)
assert(sideBar.color==sideColor,"unchanged side state rewrote accent color")
local markPoint=p.check.Checked.point
local platePoint=p.check.checkArt.point
for _,fn in ipairs(looks)do fn()end
assert(p.check.Checked.point==markPoint and p.check.checkArt.point==platePoint,"theme reanchored unchanged checkbox artwork")
local replacementMark=texture();p.check.Checked=replacementMark;module.refresh()
assert(replacementMark.width==10 and replacementMark.point[1]=="CENTER","replacement native checkmark missed cached geometry")
local fcount,tcount,hcount,wcount,ccount=stats.frames,stats.textures,stats.hooks,stats.fonts,stats.colors
collectgarbage("collect");collectgarbage("stop");local warmHeap=collectgarbage("count")
local warmStart=os.clock()
for _=1,100 do r:Hide();r:Show()end
local warmMS=(os.clock()-warmStart)*1000
local warmAllocated=collectgarbage("count")-warmHeap;collectgarbage("restart")
print(("LFG_WARM reopens=100 elapsed_ms=%.3f allocation_KiB=%.3f"):format(warmMS,warmAllocated))
assert(stats.frames==fcount and stats.textures==tcount and stats.hooks==hcount and stats.fonts==wcount and stats.colors==ccount,"warm reopen allocated or repainted")
r:Hide();local menuReads=manager.reads or 0;manager:OpenMenu(frame())
assert((manager.reads or 0)==menuReads,"closed window inspected foreign popup")
r:Show()
manager:OpenMenu(p.dropdown);assert(manager.current.eui)
local foreign=frame();manager:OpenMenu(foreign);assert(not manager.current.eui)
manager:OpenContextMenu(p.SettingsGear);assert(manager.current.eui)
local oldFont=stats.fonts
local samples={}
collectgarbage("collect");local heap=collectgarbage("count")
for trial=1,5 do local t=os.clock();for _=1,1000 do boxes[1]:Initialize(boxes[1].rows[1])end;samples[trial]=(os.clock()-t)*1000 end
table.sort(samples);collectgarbage("collect")
assert(stats.fonts==oldFont and stats.hooks==hcount and #errors==0,"warm row refresh wrote fonts or grew hooks")
print(("LFG_BENCH trials=5 row_initializations=1000 median_ms=%.3f retained_KiB=%.3f extra_font_writes=%d"):format(samples[3],collectgarbage("count")-heap,stats.fonts-oldFont))
combat=true
local pendingRow=frame("Button",boxes[1]);boxes[1].rows[#boxes[1].rows+1]=pendingRow
boxes[1]:Initialize(pendingRow);assert(pendingRow.Text.path=="native")
module.refresh();assert(pendingRow.Text.path=="native")
combat=false
for _,e in ipairs(events)do if e.callbacks.PLAYER_REGEN_ENABLED and e.scripts.OnEvent then e.scripts.OnEvent(e,"PLAYER_REGEN_ENABLED")end end
assert(pendingRow.Text.path=="eui","combat recovery missed active row")
accent={.2,.6,.9};for _,fn in ipairs(looks)do fn()end
assert(r.Content.TitleText.color[3]==.9 and p.check.Checked.color[3]==.9)
enabled=false;local current=stats.fonts;LFGForever_ToggleWindow();for _,fn in ipairs(looks)do fn()end
assert(stats.fonts==current)
enabled=true;module.refresh()
assert(#errors==0,table.concat(errors,"\n"))
for _,e in ipairs(events)do assert(not e.callbacks.LFG_LIST_ACTIVE_ENTRY_UPDATE,"idle listing listener was retained")end
print(("LFG_RESOURCES native_and_skin_frames=%d textures=%d hooks=%d view_callbacks=%d; 100 warm reopens: zero UI allocations/font/color writes; no polling"):format(stats.frames,stats.textures,stats.hooks,callbacks))
print("PASS: LFG Forever optional lazy activation, three tabs, native actions/returns, semantic stars/icons/colors, virtual rows/replacements, warm reuse, menu ownership, theme, disabled/combat recovery")
for _,k in ipairs(keys)do _G[k]=saved[k]end
end
