-- Guildy fixtures: lazy window inside Blizzard's guild window, borrowed Blizzard
-- editor, selection borders, data buttons, segmented options, tabs and combat.
local enabled, combat, accent, timers, events = true, false, 0.4, {}, {}
local hookCount, frameCount, textureCount, fontCount = 0, 0, 0, 0
local visits, scans, layouts, callbacks, styles = 0, 0, 0, 0, 0
local function CountLayout() layouts = layouts + 1 end
local ns = {IsEnabled = function() return enabled end, AttachAccent = function(_, f) f.accent = true end}
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) error(e) end end
hooksecurefunc = function(object, name, callback)
    hookCount = hookCount + 1
    local original = object[name]
    object[name] = function(...)
        local values = table.pack(original(...)); callbacks=callbacks+1; callback(...); return table.unpack(values, 1, values.n)
    end
end
local function texture(kind, parent)
    local t = {kind = kind or 'Texture', alpha = 1, path = 'native', parent = parent, points = {}}
    function t:GetObjectType() return self.kind end
    function t:Show() self.hidden = false end
    function t:Hide() self.hidden = true end
    function t:GetName() return self.name end
    function t:GetWidth() return self.width or 0 end
    function t:GetHeight() return self.height or 0 end
    function t:GetTexture() return self.path end
    function t:SetTexture(v) self.path = v; self.atlas = nil end
    function t:SetAtlas(v) self.atlas = v; self.path = nil end
    function t:GetAlpha() return self.alpha end
    function t:SetAlpha(v) self.alpha = v end
    function t:GetDrawLayer() return self.layer or 'ARTWORK' end
    function t:SetColorTexture(...) self.color = {...}; self.path = 'solid' end
    function t:SetVertexColor(...) self.color = {...} end
    function t:SetPoint(...) CountLayout(); self.points[#self.points + 1] = {...} end
    function t:SetAllPoints() end
    function t:ClearAllPoints() self.points = {} end
    function t:SetShown(v) self.shown = v end
    function t:IsShown() return self.shown ~= false end
    function t:SetSize(w, h) CountLayout(); self.width, self.height = w, h end
    function t:SetHeight(h) self.height = h end
    function t:SetWidth(w) CountLayout(); self.width = w end
    function t:SetTexCoord(...) self.crop = {...} end
    function t:GetNumMaskTextures() return 0 end
    function t:SetText(s) self.text = s end
    function t:GetText() return self.text end
    function t:GetStringWidth() return self.stringWidth or 0 end
    function t:SetWordWrap(v) self.wrap = v end
    function t:GetFont() return self.font, 12, '' end
    function t:SetFont(v) self.font = v; self.fontWrites = (self.fontWrites or 0) + 1 end
    function t:SetTextColor(...) self.textColor = {...} end
    function t:GetTextColor() return table.unpack(self.textColor or {1, 1, 1, 1}) end
    function t:GetParent() return self.parent end
    return t
end
local function frame(kind, name, parent)
    local f = {kind = kind or 'Frame', name = name, parent = parent, regions = {}, children = {}, hooks = {}}
    function f:GetObjectType() return self.kind end
    function f:SetPoint(...) CountLayout(); self.points = self.points or {}; self.points[#self.points + 1] = {...} end
    function f:GetPoint() return 'CENTER', nil, 'CENTER', 0, 0 end
    function f:ClearAllPoints() self.points = {} end
    function f:SetSize(w, h) CountLayout(); self.width, self.height = w, h end
    function f:GetWidth() return self.width or 24 end
    function f:GetHeight() return self.height or 24 end
    function f:SetID(v) self.id = v end
    function f:GetID() return self.id end
    function f:IsShown() return not self.hidden end
    function f:IsVisible() return not self.hidden and (not self.parent or self.parent:IsVisible()) end
    function f:Show() self.hidden = false; if self.hooks.OnShow then self.hooks.OnShow(self) end end
    function f:Hide() self.hidden = true end
    function f:IsEnabled() return not self.disabled end
    function f:SetEnabled(v) self.disabled = not v; local h = self.hooks[v and 'OnEnable' or 'OnDisable']; if h then h(self) end end
    function f:GetName() return self.name end
    function f:SetAlpha(v) self.alpha = v end
    function f:SetFrameLevel(v) self.level = v end
    function f:GetFrameLevel() return self.level or 1 end
    function f:EnableMouse(v) self.mouse = v end
    function f:GetAlpha() return self.alpha or 1 end
    function f:GetParent() return self.parent end
    function f:IsForbidden() return false end
    function f:IsProtected() return self.protected end
    function f:GetChildren() visits=visits+1; return table.unpack(self.children) end
    function f:GetNumChildren() return #self.children end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:HasScript() return true end
    function f:HookScript(event, fn) hookCount=hookCount+1; local old = self.hooks[event]; self.hooks[event] = function(...) if old then old(...) end; callbacks=callbacks+1; fn(...) end end
    function f:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
    function f:SetScript(e, fn) self.hooks[e] = fn end
    function f:GetBackdrop() return self.backdrop end
    -- BackdropTemplateMixin:SetBackdrop reapplies a white border through SetBackdropBorderColor.
    function f:SetBackdrop(b) CountLayout(); assert(not combat, 'styled during combat'); self.backdrop = b; if b then self:SetBackdropBorderColor(1, 1, 1, 1) end end
    function f:GetBackdropColor() return table.unpack(self.color or {0, 0, 0, 1}) end
    function f:GetBackdropBorderColor() return table.unpack(self.border or {0, 0, 0, 1}) end
    function f:SetBackdropColor(...) self.color = {...} end
    function f:SetBackdropBorderColor(...) self.border = {...} end
    function f:CreateTexture() textureCount=textureCount+1; local t = texture(nil, self); self.regions[#self.regions + 1] = t; return t end
    function f:CreateFontString() fontCount=fontCount+1; local t = texture('FontString', self); t.font = 'native'; self.regions[#self.regions + 1] = t; return t end
    function f:GetFontString() return self.label end
    function f:GetNormalTexture() return self.normal end
    if parent then parent.children[#parent.children + 1] = f end
    if name then _G[name] = f end
    return f
end
CreateFrame = function(kind, name, parent) frameCount=frameCount+1; local f = frame(kind, name, parent); events[#events + 1] = f; return f end
local S = {GetAccentColor = function() return accent, 0.6, 0.7 end}
function S.Font(t, r, g, b) t:SetFont('eui'); if r then t:SetTextColor(r, g, b) end end
function S.Button(f, keys)
    local keep = {}; for _, key in ipairs(keys or {}) do keep[f[key] or false] = true end
    for _, t in ipairs(f.regions) do if t.kind == 'Texture' and not keep[t] then t:SetAlpha(0) end end
    f.button = true
end
function S.SquareIcon(t) t:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
function S.PageButton(f, label) f.glyph = label end
function S.ScrollBar(f) f.scroll = true end
function S.Panel(f) f.panel = true end
function S.Shell(f, options) f.shell = true; f.shellOptions = options end
function S.Tab(f)
    if f.tab then return end
    f.tab = true
    -- EUI's own label, measured before the game font loaded: narrower than its text.
    f.euiLabel = f:CreateFontString(); f.euiLabel:SetText(f.label and f.label.text or '')
    f.euiLabel.font = 'eui'; f.euiLabel.width = 23.33; f.euiLabel.stringWidth = 24.17
end
function S.SetTabSelection(f, selected) f.selected = selected end
function S.CloseButton(f) f.close = true end
function S.Checkbox(f) f.checkbox = true end
function S.EditBox(f) f.input = true end
function S.Dropdown(f) f.dropdown = true end
function S.FadeNineSlice(f) f.faded = true end
function S.GetPanelColor() return 0.03, 0.03, 0.04, 0.95 end
for _, name in ipairs({"Font","Button","Tab","SetTabSelection","Panel","Shell","CloseButton","Checkbox","EditBox","ScrollBar"}) do
    local apply = S[name]
    S[name] = function(...) styles=styles+1; return apply(...) end
end
local looks = {}
S.OnLooksChanged = function(fn) looks[#looks + 1] = fn end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
local modules = {}
function ns.RegisterModule(id, _, available, install) modules[id] = {available = available, install = install} end
assert(loadfile('EUIAddonSkins/Scoped.lua'))('EUIAddonSkins', ns)
local baseline = os.getenv("GUILDY_AUDIT_BASELINE")
local opening = os.getenv("GUILDY_OPEN_AUDIT")

assert(loadfile(baseline or 'EUIAddonSkins/Skins/Guildy.lua'))('EUIAddonSkins', ns)
local helper = ns.CreateSkinHelper
ns.CreateSkinHelper = function(...)
    local H = helper(...)
    local scan = H.Scan
    H.Scan = function(...) scans=scans+1; return scan(...) end
    return H
end
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 12, 'Guildy refresh loop')
    end
end
local function label(parent, text)
    local t = parent:CreateFontString(); t:SetText(text); t:SetTextColor(1, 0.82, 0, 1); return t
end
local function Button(parent, text, name)
    local b = frame('Button', name, parent)
    b.label = label(b, text); b.art = b:CreateTexture()
    return b
end
local GOLD = {0.79, 0.64, 0.29}
local function Box(parent, border)
    local box = frame('Frame', nil, parent)
    box:SetBackdrop({bgFile = 'Interface\\Buttons\\WHITE8x8', edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border', edgeSize = 12})
    box:SetBackdropColor(0.08, 0.068, 0.048, 0.95)
    box:SetBackdropBorderColor(GOLD[1] * border, GOLD[2] * border, GOLD[3] * border)
    return box
end

-- Optional target: no Guildy, no activation.
SlashCmdList = nil
assert(not modules.Guildy.available(), 'Guildy should remain optional')
SlashCmdList = {GUILDY = function() end}
assert(modules.Guildy.available())

-- Blizzard globals Guildy relies on.
local toggles = 0
local inGuild = true
-- Tabard colours (C_GuildInfo.GetGuildTabardInfo); nil until the guild designs one.
local tabardInfo, emblemID, bannerPaints = nil, 123, 0
function GetGuildLogoInfo() return 0, 0, 0, 0, 0, 0, 0, 0, 0, emblemID end
C_GuildInfo = {GetGuildTabardInfo = function(unit) assert(unit == 'player'); return tabardInfo end}
local function Color(r, g, b) return {GetRGB = function() return r, g, b end} end
function IsInGuild() return inGuild end
-- The client has the guild finder card's banner art.
C_Texture = {GetAtlasInfo = function(name) if name:find('^guildfinder%-card%-guildbanner%-') then return {} end end}
function SetLargeGuildTabardTextures(unit, emblem, background, border)
    assert(not combat and unit == 'player'); if not inGuild then error('no tabard') end
    bannerPaints=bannerPaints+1
    emblem:SetTexture('guild-emblem'); background:SetVertexColor(0.2, 0.3, 0.9)
    border:SetTexture('guild-border'); border:SetVertexColor(0.9, 0.8, 0.1); border:Show()
end
function ToggleGuildFrame() toggles = toggles + 1; return 'native-toggle' end
-- Blizzard's select/deselect resets the label's font object: its text colour comes back opaque.
function PanelTemplates_SelectTab(tab) tab.nativeSelected = true; tab.label:SetTextColor(1, 1, 1, 1) end
function PanelTemplates_DeselectTab(tab) tab.nativeSelected = false; tab.label:SetTextColor(1, 0.82, 0, 1) end
CommunitiesGuildTextEditFrame = frame('Frame', 'CommunitiesGuildTextEditFrame')
local container = frame('Frame', nil, CommunitiesGuildTextEditFrame)
CommunitiesGuildTextEditFrame.Container = container
local blizzardEdit = frame('EditBox', nil, container)
local blizzardAccept = Button(container, 'Accept')

-- Installed before Guildy built its window (it builds on the first guild-window open).
if opening == "disabled" then enabled = false end
if opening ~= "native" then modules.Guildy.install(S, modules.Guildy); flush() end
local nativeToggle = ToggleGuildFrame

local coldStart = os.clock()
local coldCallbacks, coldVisits, coldScans, coldLayouts, coldStyles = callbacks, visits, scans, layouts, styles
local coldFrames, coldTextures, coldFonts = frameCount, textureCount, fontCount
-- Guildy builds GuildyFrame as ButtonFrameTemplate inside Blizzard's window.
local main = frame('Frame', 'GuildyFrame')
main.PortraitContainer = frame('Frame', nil, main)
local ring = main.PortraitContainer:CreateTexture()
main.PortraitContainer.portrait = main.PortraitContainer:CreateTexture()
main.PortraitContainer.portrait.path = 'Interface/Icons/INV_Shirt_GuildTabard_01'
main.CloseButton = Button(main, '', 'GuildyFrameCloseButton')
main.Emblem = frame('Frame', nil, main)
function main.Emblem:Update() self.updates = (self.updates or 0) + 1 end
main.Version = frame('Frame', nil, main); main.Version:EnableMouse(true)
main.Version.Text = label(main.Version, 'Guildy v1.5.0')
main.TitleContainer = frame('Frame', nil, main)
main.TitleContainer.TitleText = label(main.TitleContainer, 'Two Trolls One Orc \194\183 Guildy')
local emblemArt = main.Emblem:CreateTexture(); local emblemText = main.Emblem:CreateFontString()
main.OptionsButton = Button(main, '')
main.OptionsButton.Icon = main.OptionsButton:CreateTexture()
main.OptionsButton:SetScript('OnClick', function() main.optionsClicked = true end)
local side = frame('Frame', nil, main); side.sideTab = true; local sideArt = side:CreateTexture()
local tab1, tab2 = Button(main, 'Chat', 'GuildyFrameTab1'), Button(main, 'Members', 'GuildyFrameTab2')
tab1:SetID(1); tab2:SetID(2); main.selectedTab = 1
local grip = frame('Button', nil, main); grip.normal = grip:CreateTexture()
grip.normal.path = 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up'
local content = frame('Frame', nil, main); main.Content = content
local panel = frame('Frame', nil, content)
local box = Box(panel, 0.7)
local search = frame('EditBox', nil, panel)
local check = frame('CheckButton', nil, panel)
local reset = Button(panel, 'Reset')
-- data buttons: a heat-map cell and a sort header keep their own art
local cell = frame('Button', nil, panel); cell.Text = label(cell, '12')
local heat = cell:CreateTexture(); heat:SetColorTexture(0.2, 0.8, 0.1, 0.6)
local header = frame('Button', nil, panel); header.Text = label(header, 'Name')
header:SetScript('OnClick', function() header.sorted = true end)
-- the chat timeline rail: 2px gold track and a gold thumb button
local rail = frame('Button', nil, box)
local railTrack = rail:CreateTexture(); railTrack.layer = 'BACKGROUND'; railTrack:SetWidth(2); railTrack:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.35)
local thumb = frame('Button', nil, rail)
local thumbEdge = thumb:CreateTexture(); thumbEdge.layer = 'BACKGROUND'; thumbEdge:SetColorTexture(0, 0, 0, 1)
local thumbFill = thumb:CreateTexture(); thumbFill:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
local thumbHi = thumb:CreateTexture(); thumbHi.layer = 'HIGHLIGHT'; thumbHi:SetColorTexture(1, 0.82, 0, 0.35)
rail:SetScript('OnClick', function() rail.jumped = true end)
-- the Blizzard editor is lent into this panel
container.parent = panel; panel.children[#panel.children + 1] = container

if opening then
    -- Simulate Guildy's post-host sequence: show root, show the active page, then
    -- finish Blizzard's toggle. Populate hidden panels to reveal wasted walks.
    local nativeOpen = ToggleGuildFrame
    local alternate = frame("Frame", nil, content)
    for _=1,80 do Button(alternate, "Dormant row") end
    alternate:Hide()
    local activePage = frame("Frame", nil, content)
    for _=1,40 do Button(activePage, "Visible row") end
    activePage:Hide()
    local function Open()
        main:Show()
        activePage:Show()
        PanelTemplates_SelectTab(tab1)
        nativeOpen()
        flush()
    end
    Open()
    if enabled and opening ~= "native" then
        assert(activePage.children[1].button, "cold opening failed to skin active page")
    end
    print(("GUILDY OPEN %s cold %.4f ms callbacks=%d visits=%d scans=%d layout=%d styles=%d objects=%d/%d/%d"):format(
        opening,(os.clock()-coldStart)*1000,callbacks-coldCallbacks,visits-coldVisits,scans-coldScans,
        layouts-coldLayouts,styles-coldStyles,frameCount-coldFrames,textureCount-coldTextures,fontCount-coldFonts))
    local samples = {}
    collectgarbage("collect")
    local heap = collectgarbage("count")
    local c,v,sc,l,st = callbacks,visits,scans,layouts,styles
    local f,t,fs = frameCount,textureCount,fontCount
    for trial=1,5 do
        local start=os.clock()
        for _=1,1000 do main:Hide(); activePage:Hide(); Open() end
        samples[trial]=(os.clock()-start)*1000
    end
    table.sort(samples)
    collectgarbage("collect")
    assert(frameCount==f and textureCount==t and fontCount==fs)
    print(("GUILDY OPEN %s warm %.4f ms per 1000 callbacks=%d visits=%d scans=%d layout=%d styles=%d heap=%.3f KiB"):format(
        opening,samples[3],(callbacks-c)/5,(visits-v)/5,(scans-sc)/5,(layouts-l)/5,(styles-st)/5,collectgarbage("count")-heap))
    if opening == "candidate" then
        assert(not alternate.children[1].button, "warm opens styled hidden page")
        assert(scans-sc <= 5000, "warm open performed duplicate scans")
        activePage:Hide(); alternate:Show()
        assert(alternate.children[1].button, "lazy page not styled before returning to native code")
        flush()
    end
    local start = os.clock()
    local switchSamples = {}
    for trial=1,5 do
        start = os.clock()
        for _=1,500 do
            activePage:Hide(); alternate:Show(); PanelTemplates_SelectTab(tab2); flush()
            alternate:Hide(); activePage:Show(); PanelTemplates_SelectTab(tab1); flush()
        end
        switchSamples[trial] = (os.clock()-start)*1000
    end
    table.sort(switchSamples)
    print(("GUILDY OPEN %s switch %.4f ms per 1000"):format(opening,switchSamples[3]))
    return
end
if not baseline then
    for _, f in ipairs(events) do
        if f.events and f.events.GUILDBANKFRAME_OPENED then f.hooks.OnEvent(f, 'GUILDBANKFRAME_OPENED') end
    end
    flush()
    assert(main.shell, 'standalone bank first open not discovered')
end
assert(ToggleGuildFrame() == 'native-toggle' and toggles == 1); flush()
assert(main.shell and main.shellOptions.noAccent, 'Guildy window not shelled on first open')
assert(ring.alpha == 0 and main.PortraitContainer.portrait.alpha == 0, 'round portrait art remained')
local holder = main.euiGuildyTabard and main.euiGuildyTabard.Frame
assert(holder and holder.parent == main and holder.width == 70 and holder.height == 60, 'corner banner not at Guildy size')
assert(holder.points[1][1] == 'TOPLEFT' and holder.points[1][4] == 4 and holder.points[1][5] == -4, 'corner banner not inside the window frame')
assert(holder.level == main:GetFrameLevel() + 300, 'corner emblem below the window chrome')
if os.getenv("GUILDY_AUDIT") then
    local tabard = main.euiGuildyTabard
    GetGuildTabardFiles = function() return 180151, 180150, 184061, 184060, 180227, 180226 end
    tabardInfo = {backgroundColor = Color(.1,.05,.2), borderColor = Color(.6,.5,.1), emblemColor = Color(.8,.2,.9)}
    main.Emblem:Update(); flush()
    PanelTemplates_SelectTab(tab1)
    local function counts()
        return ("%d/%d/%d/%d"):format(frameCount,textureCount,fontCount,hookCount)
    end
    local function Bench(label, fn)
        collectgarbage("collect")
        local resources, heap, paints = counts(), collectgarbage("count"), bannerPaints
        local samples={}
        for trial=1,5 do
            local start=os.clock()
            for _=1,1000 do fn() end
            samples[trial]=(os.clock()-start)*1000
        end
        table.sort(samples)
        collectgarbage("collect")
        assert(counts()==resources, label.." accumulated resources")
        print(("GUILDY AUDIT %s %s %.3f ms; %d banner paints; %.3f KiB heap delta"):format(
            baseline and "baseline" or "candidate",label,samples[3],bannerPaints-paints,collectgarbage("count")-heap))
    end
    local scroll = frame("ScrollFrame", nil, panel)
    modules.Guildy.refresh(); flush()
    Bench("visible-emblem", function() main.Emblem:Update() end)
    main:Hide()
    Bench("closed-emblem", function() main.Emblem:Update() end)
    main:Show(); panel:Show(); flush()
    Bench("tab-switch", function() PanelTemplates_DeselectTab(tab1); PanelTemplates_SelectTab(tab1) end)
    Bench("reopen", function() main:Hide(); main:Show(); flush() end)
    Bench("scroll", function() scroll.hooks.OnVerticalScroll(scroll); flush() end)
    Bench("theme-refresh", function() looks[1](); flush() end)
    print(("GUILDY AUDIT %s inventory %s frames/textures/fontstrings/hooks; %d holder and %d outer textures"):
        format(baseline and "baseline" or "candidate",counts(),#holder.regions,#main.euiGuildyEdges))
    return
end
local titleIcon = main.euiGuildyTabard.Logo
assert(titleIcon.path == 'Interface/Icons/INV_Shirt_GuildTabard_01' and titleIcon.alpha == 1 and titleIcon.crop, 'square logo missing')
assert(main.Emblem.alpha == 0, 'round guild emblem still drawn in the corner')
local tabard = main.euiGuildyTabard
assert(tabard and tabard.ok and tabard.Emblem.path == 'guild-emblem' and tabard.Emblem:IsShown(), 'guild tabard not drawn in the title icon')
assert(tabard.banner and tabard.Emblem.width == 46 and tabard.Background.parent == holder, 'emblem not fitted to the banner')
assert(tabard.Background.atlas == 'guildfinder-card-guildbanner-background' and tabard.Background.color[3] == 0.9 and tabard.Background:IsShown(), 'banner not in the tabard background colour')
assert(tabard.Border.atlas == 'guildfinder-card-guildbanner-border' and tabard.Border.shown == true, 'banner border replaced by the round tabard ring')
assert(not tabard.Edges, 'square edges drawn around the banner')
assert(titleIcon == tabard.Logo and tabard.Logo.shown == false, 'Guildy logo still shown under the tabard')
assert(main.Version:GetAlpha() == 1 and main.Version.mouse, 'version tooltip suppressed')
assert(main.TitleContainer.TitleText.text == 'Two Trolls One Orc', 'Guildy suffix not removed from the title')
main.TitleContainer.TitleText:SetText('Other Guild - Guildy'); assert(main.TitleContainer.TitleText.text == 'Other Guild', 'retitle kept the suffix')
main.TitleContainer.TitleText:SetText('Guildy'); assert(main.TitleContainer.TitleText.text == 'Guildy', 'bare title emptied')
inGuild = false; main.Emblem:Update(); assert(not tabard.ok and not tabard.Emblem:IsShown() and tabard.Logo.shown == true, 'tabard kept, or logo not restored, after leaving the guild')
inGuild = true; main.Emblem:Update(); assert(tabard.ok and tabard.Emblem:IsShown() and tabard.Logo.shown == false, 'tabard not restored, or logo left showing, after joining')
main.Emblem:SetAlpha(1); main.Emblem:Update(); assert(main.Emblem.alpha == 0, 'native emblem visible after update')
assert(main.CloseButton.close)
assert(emblemArt.alpha == 1 and emblemText.font == 'native', 'guild emblem internals were styled')
assert(main.OptionsButton.button and main.OptionsButton.Icon.alpha == 1, 'options cog lost its icon')
assert(not side.button and sideArt.alpha == 1, 'side tab art changed')
assert(tab1.tab and tab1.selected == true and tab2.tab and tab2.selected == false, 'bottom tabs not styled with selection')
assert(tab1.label.alpha == 0 and tab2.label.alpha == 0, 'Blizzard tab labels still drawn under the EUI labels')
assert(tab1.euiLabel.wrap == false and tab1.euiLabel.width >= tab1.euiLabel.stringWidth, 'EUI tab label can still wrap its last letter')
tab1.euiLabel.stringWidth = 40; tab1.euiLabel:SetText('Chat (3)')
assert(tab1.euiLabel.width >= 40, 'EUI tab label not refitted after a text change')
assert(grip.normal.alpha == 0, 'resize grip art remained')
assert(search.input and check.checkbox and reset.button and reset.label.font == 'eui')
assert(reset.label.textColor[2] == 0.82, 'button label colour not preserved')
assert(not cell.button and heat.alpha == 1 and heat.color[2] == 0.8, 'data cell lost its colour art')
assert(cell.Text.font == 'eui' and not header.button, 'custom data buttons were boxed')
header.hooks.OnClick(header); assert(header.sorted, 'sort header action lost')
assert(not blizzardEdit.input and not blizzardAccept.button and blizzardAccept.label.font == 'native',
    'borrowed Blizzard editor was styled')

-- Boxes keep a backdrop so Guildy's own border colours still mean something.
assert(box.backdrop.edgeFile == 'Interface\\Buttons\\WHITE8X8' and box.backdrop.edgeSize == 1, 'box not flattened')
assert(box.border[1] == 0.055 and box.color[1] > 0.03 and box.color[4] == 0.9, 'resting box lit by the backdrop reset or wrong colours')
assert(railTrack.color[1] == accent and railTrack.color[4] == 0.35 and thumbFill.color[1] == accent, 'timeline rail kept gold')
assert(thumbEdge.color[1] == 0 and thumbEdge.alpha == 1 and not rail.button and not thumb.button, 'timeline rail art replaced')
rail.hooks.OnClick(rail); assert(rail.jumped, 'timeline rail action lost')
box:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3])
assert(box.border[1] == accent and box.border[4] == 1, 'selected card border did not use the accent')
box:SetBackdropBorderColor(GOLD[1] * 0.5, GOLD[2] * 0.5, GOLD[3] * 0.5)
assert(box.border[1] == 0.055, 'deselected card border stayed lit')
box:SetBackdropBorderColor(1, 0.82, 0)
assert(box.border[1] == accent, 'hover border did not use the accent')

-- Tab selection follows PanelTemplates; foreign tabs are untouched.
local foreign = Button(frame('Frame'), 'Other', 'GuildyFrameTab99')
PanelTemplates_SelectTab(tab2); PanelTemplates_DeselectTab(tab1); PanelTemplates_SelectTab(foreign)
assert(tab2.selected == true and tab1.selected == false and tab2.nativeSelected, 'tab selection not followed')
assert(not foreign.tab, 'foreign tab styled')

-- A tab panel built later is styled when it shows.
local lazy = frame('Frame', nil, content); lazy:Hide()
modules.Guildy.refresh(); flush()
local later = Button(lazy, 'Invite'); local laterBox = Box(lazy, 0.7)
local list = frame('ScrollFrame', nil, lazy)
local scrollChild = frame('Frame', nil, list)
list.rows = {}
function list:GetScrollChild() return scrollChild end
function list:SetItems(items)
    for i = 1, items do
        if not self.rows[i] then self.rows[i] = Button(scrollChild, 'Row') end
    end
end
for _, look in ipairs(looks) do look() end; flush()
assert(not later.button, 'theme refresh eagerly styled a hidden page')
lazy:Show()
assert(later.button and laterBox.backdrop.edgeSize == 1, 'lazy tab left native art after OnShow returned')
list:SetItems(2)
assert(list.rows[1].button and list.rows[2].button, 'post-OnShow list rows left unstyled')
local stableScans = scans
list:SetItems(2)
assert(scans == stableScans, 'same-sized list scanned again')
lazy:Hide(); lazy:Show()
assert(later.button and list.rows[1].button)
lazy:Hide()
local lockedPage = frame('Frame', nil, content); lockedPage:Hide()
modules.Guildy.refresh(); flush()
local lockedButton = Button(lockedPage, 'Combat tab')
combat = true
lockedPage:Show()
assert(not lockedButton.button, 'first show styled during combat')
combat = false
for _, f in ipairs(events) do
    if f.events and f.events.PLAYER_REGEN_ENABLED then f.hooks.OnEvent(f, 'PLAYER_REGEN_ENABLED') end
end
flush()
assert(lockedButton.button, 'first show did not recover after combat')

-- Segmented options: the chosen option is the disabled button.
local options = frame('Frame', 'GuildyOptions')
options.PortraitContainer = frame('Frame', nil, options)
local group = frame('Frame', nil, options); group.buttons = {}
for i, value in ipairs({'a', 'b'}) do
    local b = Button(group, value); b.value = value; group.buttons[i] = b
end
function group:SetValue(value)
    for _, b in ipairs(self.buttons) do b:SetEnabled(b.value ~= value) end
end
group:SetValue('a')
main.OptionsButton.hooks.OnClick(main.OptionsButton); flush()
assert(main.optionsClicked and options.shell, 'options window not styled after the cog click')
local a, b = group.buttons[1], group.buttons[2]
assert(a.euiSelection.color[4] == 0.2 and b.euiSelection.color[4] == 0, 'segmented selection not shown')
assert(a.label.textColor[1] == 1 and a.label.textColor[3] == 1, 'chosen segment label not white')
group:SetValue('b')
assert(b.euiSelection.color[4] == 0.2 and a.euiSelection.color[4] == 0, 'segmented selection did not follow SetValue')

-- Owned popups.
local confirm = Box(nil, 0.9); confirm.name = 'GuildyConfirm'; GuildyConfirm = confirm
local ok = Button(confirm, 'Yes')
modules.Guildy.refresh(); flush()
assert(not confirm.shell and not ok.button, 'standalone confirmation dialog must stay native')
local copy = frame('Frame', 'GuildyCopyBox')
local copyInput = frame('EditBox', nil, copy)
copy:Show(); flush()
assert(not copy.shell and not copyInput.input, 'standalone copy dialog must stay native')

-- Repeated refreshes add no hooks or objects.
local hooked, regions = ToggleGuildFrame, #box.regions
local mainRegions, mainHooks = #main.regions, main.Emblem.Update
for _ = 1, 10 do modules.Guildy.refresh(); flush() end
assert(#main.regions == mainRegions and main.Emblem.Update == mainHooks, 'title icon or tabard recreated on refresh')
PanelTemplates_SelectTab(tab1); PanelTemplates_DeselectTab(tab2)
assert(tab1.label.alpha == 0 and tab2.label.alpha == 0, 'a tab font reset brought the wrapping Blizzard label back')
tab1.label:SetAlpha(1); PanelTemplates_SelectTab(tab1)
assert(tab1.label.alpha == 0, 'Blizzard tab label came back after selection')
assert(ToggleGuildFrame == hooked and #box.regions == regions, 'duplicate hooks or objects')
assert(nativeToggle == ToggleGuildFrame)

-- Combat defers styling; leaving combat applies it.
local waiting = Button(panel, 'Promote')
combat = true
local paints = bannerPaints
local width = tab1.euiLabel.width
PanelTemplates_SelectTab(tab2); PanelTemplates_DeselectTab(tab1)
group:SetValue('a')
tab1.euiLabel.stringWidth = width + 20; tab1.euiLabel:SetText('New title')
main.TitleContainer.TitleText:SetText('Combat Guild - Guildy')
box:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3])
emblemID = 456; main.Emblem:Update()
assert(tab1.selected and not tab2.selected and b.euiSelection.color[4] == 0.2)
assert(tab1.euiLabel.width == width and main.TitleContainer.TitleText.text == 'Combat Guild - Guildy')
assert(box.border[1] == GOLD[1] and bannerPaints == paints)
modules.Guildy.refresh(); flush()
assert(not waiting.button, 'styled during combat')
combat = false
for _, f in ipairs(events) do if f.events and f.events.PLAYER_REGEN_ENABLED then f.hooks.OnEvent(f, 'PLAYER_REGEN_ENABLED') end end
flush(); assert(waiting.button, 'combat recovery missed')
assert(not tab1.selected and tab2.selected and a.euiSelection.color[4] == 0.2)
assert(tab1.euiLabel.width >= width + 20 and main.TitleContainer.TitleText.text == 'Combat Guild')
assert(box.border[1] == accent and bannerPaints == paints + 1)

-- Accent changes repaint lit borders.
box:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3])
accent = 0.9; for _, look in ipairs(looks) do look() end; flush()
assert(box.border[1] == 0.9, 'accent change not applied to a lit border')
assert(railTrack.color[1] == 0.9 and thumbFill.color[1] == 0.9, 'accent change not applied to the timeline rail')

-- No tabard design: the EUI look, no guild edges or underlines.
for _, e in ipairs(main.euiGuildyEdges) do assert(e.shown == false, 'window edge drawn without tabard colours') end
assert(not tab1.euiGuildyLine, 'guild underline without tabard colours')

-- Tabard colours drive Guildy's accent, tabs, title icon and window edge.
tabardInfo = {backgroundColor = Color(0.1, 0.05, 0.2), borderColor = Color(0.6, 0.5, 0.1), emblemColor = Color(0.8, 0.2, 0.9)}
main.Emblem:Update(); flush()
local function near(x, y) return math.abs(x - y) < 1e-6 end
assert(near(tabard.Border.color[1], 0.8) and near(tabard.Border.color[3], 0.1 * 0.8 / 0.6), 'banner border not lifted to full strength in the border colour')
-- A teal border the game reports near black (15, 20, 21) comes out teal; black stays black.
tabardInfo.borderColor = Color(15 / 255, 20 / 255, 21 / 255); main.Emblem:Update(); flush()
assert(near(tabard.Border.color[3], 0.8) and near(tabard.Border.color[1], 0.8 * 15 / 21), 'near-black teal border not lifted')
tabardInfo.borderColor = Color(0.05, 0.05, 0.05); main.Emblem:Update(); flush()
assert(near(tabard.Border.color[1], 0.05), 'black border lifted to grey')
tabardInfo.borderColor = Color(0.6, 0.5, 0.1); main.Emblem:Update(); flush()
assert(not tabard.Braid and tabard.Border.shown == true, 'client banner border must remain visible')
local previousPaints = bannerPaints
main.Emblem:Update()
assert(bannerPaints == previousPaints, 'repainted unchanged guild design')
emblemID = 789; main.Emblem:Update()
assert(bannerPaints == previousPaints + 1, 'same-colour design change missed')
for _, e in ipairs(main.euiGuildyEdges) do assert(e.shown == true and e.color[1] == 0.6, 'window edge not in the tabard border colour') end
box:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3])
assert(box.border[1] == 0.8 and box.border[3] == 0.9, 'lit border not in the guild accent')
assert(railTrack.color[1] == 0.8 and thumbFill.color[3] == 0.9, 'timeline rail not in the guild accent')
PanelTemplates_SelectTab(tab1); PanelTemplates_DeselectTab(tab2)
assert(tab1.selected == true and tab2.selected == false, 'EUI tab selection lost with guild colours')
assert(not tab1.euiGuildyLine and not tab2.euiGuildyLine, 'duplicate selection underline')
assert(tab1.label.alpha == 0 and tab2.label.alpha == 0, 'guild colours made the Blizzard tab labels visible')
-- A dark emblem is unreadable: the border colour becomes the accent.
tabardInfo.emblemColor = Color(0.05, 0.05, 0.05); main.Emblem:Update(); flush()
box:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3])
assert(box.border[1] == 0.6, 'dark emblem colour used as the accent')
-- Unchanged colours add no refresh work.
local queued = #timers; main.Emblem:Update(); assert(#timers == queued, 'unchanged tabard queued a refresh')
-- The design removed again: back to the EUI accent.
tabardInfo = nil; emblemID = nil; main.Emblem:Update(); flush()
for _, e in ipairs(main.euiGuildyEdges) do assert(e.shown == false, 'window edge kept after the tabard design went away') end
assert(railTrack.color[1] == accent and tab1.selected == true and not tab1.euiGuildyLine, 'EUI accent not restored')

-- Stable design: no paint work on repeated native roster-driven emblem updates.
collectgarbage("collect")
local usage = collectgarbage("count")
local samples = {}
local beforePaints = bannerPaints
for trial = 1, 5 do
    local start = os.clock()
    for _ = 1, 1000 do main.Emblem:Update() end
    samples[trial] = (os.clock() - start) * 1000
end
table.sort(samples)
collectgarbage("collect")
assert(bannerPaints == beforePaints and #timers == 0)
print(("BENCH Guildy: 1000 unchanged emblem updates %.3f ms median; %d holder and %d outer textures; heap delta %.3f KiB")
    :format(samples[3], #holder.regions, #main.euiGuildyEdges, collectgarbage("count") - usage))

-- Disabled skin stops processing.
enabled = false
box:SetBackdropBorderColor(GOLD[1] * 0.5, GOLD[2] * 0.5, GOLD[3] * 0.5)
assert(box.border[1] == GOLD[1] * 0.5, 'disabled skin still repainted borders')
local after = Button(panel, 'Late'); modules.Guildy.refresh(); flush()
assert(not after.button, 'disabled skin styled new controls')
print('PASS: Guildy lazy window, corner guild banner, guild colour accent/tabs/edges, hidden native tab labels, title trim and version tooltip, backdrop border reset, timeline rail, borrowed Blizzard editor, selection borders, data buttons, segmented options, tabs, popups, combat and disable')
