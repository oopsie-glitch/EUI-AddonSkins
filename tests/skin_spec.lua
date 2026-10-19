local timers, errors, calls = {}, {}, {}
local combat = false
InCombatLockdown = function() return combat end
local function count(k) calls[k] = (calls[k] or 0) + 1 end
local function texture(kind)
    return { GetObjectType = function() return kind or "Texture" end,
        SetColorTexture = function(self, ...) self.color = {...}; self.colorWrites = (self.colorWrites or 0) + 1 end,
        SetAlpha = function(self, a) self.alpha = a end,
        SetGradientAlpha = function(self, ...) self.gradient = {...} end,
        GetAlpha = function(self) return self.alpha == nil and 1 or self.alpha end,
        SetTexture = function(self, path) self.path = path; self.atlas = nil end,
        GetAtlas = function(self) return self.atlas end,
        SetSize = function(self, w, h) self.width, self.height = w, h end,
        ClearAllPoints = function(self) self.points = {} end,
        SetPoint = function(self, ...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end }
end
local function frame(kind, name, parent)
    local f = { name = name, kind = kind or "Frame", parent = parent, regions = {}, children = {}, scripts = {}, hooks = {} }
    function f:CreateTexture()
        local t = texture()
        function t:SetHeight(h) self.height = h end
        function t:SetWidth(w) self.width = w end
        function t:SetAllPoints(target) self.allPoints = target end
        function t:SetGradientAlpha(...) self.gradient = {...} end
        self.regions[#self.regions + 1] = t
        return t
    end
    function f:SetAllPoints(target) self.allPoints = target end
    function f:EnableMouse(value) self.mouseEnabled = value end
    function f:GetName() return self.name end

    function f:GetObjectType() return self.kind end
    function f:GetParent() return self.parent end
    function f:GetPoint() if self.point then return table.unpack(self.point) end end
    function f:GetFrameLevel() return self.level or 1 end
    function f:SetFrameLevel(level) self.level = level end
    function f:GetWidth() return self.width or 24 end
    function f:GetHeight() return self.height or 24 end
    function f:IsForbidden() return self.forbidden end
    function f:IsProtected() return self.protected end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:GetChildren() self.childReads = (self.childReads or 0) + 1; return table.unpack(self.children) end
    function f:IsVisible() return self.visible ~= false end
    function f:HookScript(event, fn)
        self.hooks[event] = self.hooks[event] or {}; table.insert(self.hooks[event], fn)
    end
    function f:SetScript(event, fn) self.scripts[event] = fn end
    function f:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
    function f:UnregisterEvent() end
    function f:SetPoint(...) self.point = {...} end
    function f:ClearAllPoints() self.point = nil end
    function f:SetSize(w, h) self.width, self.height = w, h end
    if parent then table.insert(parent.children, f) end
    if name then _G[name] = f end
    return f
end
local lastCreated
CreateFrame = function(kind, name, parent) lastCreated = frame(kind, name, parent); return lastCreated end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
geterrorhandler = function() return function(err) errors[#errors + 1] = err end end
C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
hooksecurefunc = function(object, name, callback)
    local original = object[name]
    object[name] = function(...)
        local out = table.pack(original(...)); callback(...); return table.unpack(out, 1, out.n)
    end
end
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 20, "timer loop")
    end
end
local enabled = true
local looks
local skin = {
    IsEnabled = function() return enabled end,
    GetAccentColor = function() return 0.047, 0.824, 0.616 end,
    OnLooksChanged = function(fn) looks = fn end,
}
for _, name in ipairs({ "Shell", "Panel", "Button", "EditBox", "Dropdown", "Inset", "FadeRegions",
    "FadeNineSlice", "Font", "CloseButton", "ScrollBar", "SquareIcon", "Checkbox", "StateButtonLabel" }) do
    skin[name] = function(f, options) assert(f, name .. " missing frame"); count(name); if name == "Button" then f.buttonSkinned = true end; if name == "Shell" or name == "EditBox" then f.softOptions = options end end
end
skin.Dropdown = function(f)
    count('Dropdown')
    if f.skinFill then return end
    if f.Icon then f.Icon:SetAlpha(0) end
    f.skinFill = f:CreateTexture(); f.skinFill:SetAlpha(1)
    f.skinArrow = f:CreateTexture(); f.skinArrow.atlas = 'Azerite-PointingArrow'; f.skinArrow:SetAlpha(1)
end
local nativeOpen
ForeverCompanion = {OpenOptions = function() if nativeOpen then return nativeOpen() end end}
local popupOwners = {}
local legacyDropdownMode = false
local callback
EllesmereUI = { RegisterSkin = function(name, fn) count("registration"); callback = fn end }
ForeverCompanionAPI = {
    COLORS = {},
    AttachToFrame = function(button, host) button.host = host; return "attach-result" end,
    CreateWindow = function(name) return frame("Frame", name), nil, "sentinel" end,
    CreateMenuButton = function(parent)
        local f = frame("Button", nil, parent); f.Text = texture("FontString"); return f
    end,
    CreateSearchBox = function(parent) return frame("EditBox", nil, parent) end,
    CreateDropdown = function(parent)
        local f = frame(legacyDropdownMode and 'Frame' or 'DropdownButton', nil, parent)
        f.Icon = f:CreateTexture(); f.Icon:SetTexture('selected-class-icon'); f.Icon:SetAlpha(0.7)
        local button = legacyDropdownMode and frame('Button', nil, f) or f
        if legacyDropdownMode then f.Button = button end
        button.Arrow = texture()
        function button.Arrow:SetTexture(path) self.path = path end
        function button.Arrow:SetSize(w, h) self.width, self.height = w, h end
        button.normal = button:CreateTexture(); button.normal:SetTexture('native-boxed-border'); button.normal:SetAlpha(1)
        button.GetNormalTexture = function(self) return self.normal end
        button.SetNormalTexture = function(self, value) self.normal = value end
        f.GenerateMenu = function()
            button.Arrow:SetAlpha(1); button.normal:SetAlpha(1)
            return nil, 'menu-native'
        end
        f.OverrideText = function(self, value) self.selectedText = value; button.Arrow:SetAlpha(1) end
        button.scripts.OnClick = function() return 'dropdown-native' end
        return {frame = f}
    end,
    CreateScrollFrame = function(parent) return frame("ScrollFrame", nil, parent), frame("EventFrame", nil, parent) end,
    AddInset = function() return texture(), frame() end,
    StripedBackground = function() return texture(), texture() end,
    CreateSideTab = function(parent)
        local f = frame("Button", nil, parent); f.icon = texture(); f.sel = texture(); return f
    end,
    CreateOptionsButton = function(parent) local f = frame("Button", nil, parent); f.icon = texture(); return f end,
    VirtualList = function() return { Layout = function() end, Refresh = function() end } end,
}
local chunk = assert(loadfile("EUIAddonSkins/Core.lua"))
local integration = assert(loadfile("EUIAddonSkins/Skins/ForeverCompanion.lua"))
local ns = {}
chunk("EUIAddonSkins", ns)
assert(loadfile("EUIAddonSkins/Accent.lua"))("EUIAddonSkins", ns)
assert(loadfile("EUIAddonSkins/Widgets.lua"))("EUIAddonSkins", ns)
integration("EUIAddonSkins", ns)
ns.BindPopupOwner = function(S, module, owner) popupOwners[owner] = S end
assert(calls.registration == 1 and not calls.Shell, "must wait for API dispatch")
local existingLauncher = frame("Button", "ForeverCompanionTalentBtn")
existingLauncher.Text = texture("FontString")
callback(skin)
flush()
assert(existingLauncher.buttonSkinned, "existing BiS Talents launcher not skinned")
local host = frame()
local blizzardButton = frame("Button", nil, host); blizzardButton.Text = texture("FontString")
local lateLauncher = frame("Button", "ForeverCompanionTalentBtn")
lateLauncher.Text = texture("FontString")
lateLauncher:SetScript("OnClick", function() return "original-talent-toggle" end)
assert(ForeverCompanionAPI.AttachToFrame(lateLauncher, host) == "attach-result")
flush()
assert(lateLauncher.buttonSkinned and not blizzardButton.buttonSkinned, "launcher skin scanned Blizzard host")
assert(lateLauncher.scripts.OnClick() == "original-talent-toggle" and lateLauncher.host == host)
combat = true
local combatLauncher = frame("Button", "ForeverCompanionTalentBtn")
combatLauncher.Text = texture("FontString")
ForeverCompanionAPI.AttachToFrame(combatLauncher, host); flush()
assert(not combatLauncher.buttonSkinned, "launcher changed in combat")
combat = false
lastCreated.scripts.OnEvent(lastCreated, "PLAYER_REGEN_ENABLED"); flush()
assert(combatLauncher.buttonSkinned, "launcher not applied after combat")
enabled = false
local disabledLauncher = frame("Button", "ForeverCompanionTalentBtn")
disabledLauncher.Text = texture("FontString")
ForeverCompanionAPI.AttachToFrame(disabledLauncher, host); flush()
assert(not disabledLauncher.buttonSkinned, "disabled Companion launcher was skinned")
enabled = true
ForeverCompanionAPI.AttachToFrame(disabledLauncher, host); flush()
assert(disabledLauncher.buttonSkinned)
-- The private FC scan footer moves below the auction tabs; unrelated children stay put.
AuctionFrame = frame('Frame')
local unrelated = frame('Frame', nil, AuctionFrame)
local footer = frame('Frame', nil, AuctionFrame)
footer.icon = texture(); footer.icon.GetTexture = function() return 'Interface/\\AddOns/ForeverCompanion/Media/LogoAddon.tga' end
footer.btn = frame('Button', nil, footer); footer.btn.scripts.OnClick = function() return 'full-scan-original' end
footer.status = texture('FontString'); footer.status.SetWidth = function(self, w) self.width = w end
local externalEvents = lastCreated
externalEvents.scripts.OnEvent(externalEvents, 'AUCTION_HOUSE_SHOW'); flush()
assert(footer.point[5] == -30 and footer.status.width == 200 and footer.btn.buttonSkinned)
assert(not unrelated.point and footer.btn.scripts.OnClick() == 'full-scan-original')
local panels = calls.Panel; externalEvents.scripts.OnEvent(externalEvents, 'AUCTION_HOUSE_SHOW'); flush()
assert(calls.Panel == panels, 'scan footer allocated twice')
AuctionFrame = nil
local api = ForeverCompanionAPI
local f, missing, sentinel = api.CreateWindow("ForeverCompanionFrame")
assert(f and missing == nil and sentinel == "sentinel", "factory return values changed")
f.CloseButton = frame('Button', nil, f); f.optionsBtn = api.CreateOptionsButton(f); f.helpBtn = frame('Button', nil, f)
local headerCheck = frame('CheckButton', nil, f); headerCheck:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -84, -4)
local originalHelp = function() return 'tour-native' end; f.helpBtn:SetScript('OnClick', originalHelp)
local b = api.CreateMenuButton(f)
local clicks = 0; b:SetScript("OnClick", function() clicks = clicks + 1 end)
local search = api.CreateSearchBox(f); api.CreateDropdown(f); api.CreateScrollFrame(f)
local sc = frame("Frame", nil, f)
local list = api.VirtualList(nil, sc)
local tab = api.CreateSideTab(f)
tab:SetPoint('TOPLEFT', f, 'TOPRIGHT', -2, -30)
assert(tab.point[4] == 6 and tab.point[5] == -30 and tab.level == f:GetFrameLevel() + 8)
assert(tab.icon.points[1][1] == 'TOPLEFT' and tab.icon.points[2][4] == -3)
local light, right = api.StripedBackground(f, "light")
local inset = api.AddInset(f)
local check = frame("CheckButton", nil, f)
local secret = frame("EditBox", nil, f); secret.forbidden = true
local protected = frame("EditBox", nil, f); protected.protected = true
local edits = calls.EditBox or 0
flush()
assert(headerCheck.point[1] == 'RIGHT' and headerCheck.point[2] == f.helpBtn and headerCheck.width == 20)
assert(f.CloseButton.point[4] == -8 and f.CloseButton.point[5] == -8 and f.CloseButton.width == 20)
assert(f.optionsBtn.point[2] == f.CloseButton and f.helpBtn.point[2] == f.optionsBtn and f.helpBtn.scripts.OnClick == originalHelp)
assert(f.softOptions.noBorder and search.softOptions.noBorder and api.COLORS.border[1] == 0.055, "Companion soft chrome missing")
assert(calls.EditBox == edits + 1, "must skin the ordinary input exactly once; skip restricted frames")
assert(light.gradient[2] == 0.075 and light.gradient[6] == 0.13 and right.gradient[2] == 0.13 and right.gradient[6] == 0.075, 'row halves lost their centre gradient')
local darkL, darkR = api.StripedBackground(f, 'dark')
local headL, headR = api.StripedBackground(f, 'header')
assert(darkL.gradient[6] == 0.085 and darkR.gradient[2] == 0.085)
assert(headL.gradient[6] == 0.16 and headR.gradient[2] == 0.16)
assert(light.gradient[5] == 1 and darkR.gradient[9] == 1, 'rows retained transparent dark overlays')
assert(headL.gradient[6] > light.gradient[6] and light.gradient[6] > darkL.gradient[6])
looks(); flush()
assert(light.gradient[6] == 0.13 and right.gradient[6] == 0.075 and headR.gradient[6] == 0.09, 'theme refresh reversed or flattened a row')
assert(inset.color[1] == 0.055, "inset missed the charcoal palette")
assert(tab.sel.color[2] == 0.824)
b.scripts.OnClick(); assert(clicks == 1, "lost click callback")
local shells = calls.Shell
list:Layout(); list:Layout(); assert(#timers == 1, "updates not coalesced"); flush()
assert(calls.Shell == shells, "rescan must not fade window content again")
local newCheck = frame("CheckButton", nil, sc)
local checks = calls.Checkbox; list:Layout(); flush()
assert(calls.Checkbox == checks + 1, "new pooled row control not discovered")
-- The refresh keeps native semantics while styling private lazy-page controls.
do
    local function label(parent, r, g, b)
        local t = texture('FontString'); t.font, t.size, t.flags = 'native', 12, ''
        t.textColor = {r or 1, g or 0.82, b or 0}
        function t:GetFont() return self.font, self.size, self.flags end
        function t:SetFont(path, size, flags) self.font, self.size, self.flags = path, size, flags; self.writes = (self.writes or 0) + 1 end
        function t:SetFontObject() self:SetFont('native', 12, '') end
        function t:GetTextColor() return table.unpack(self.textColor) end
        function t:SetTextColor(...) self.textColor = {...} end
        parent.regions[#parent.regions + 1] = t
        return t
    end
    for _, legacy in ipairs({false, true}) do
        legacyDropdownMode = legacy
        local dropdown = api.CreateDropdown(f).frame
        local button = dropdown.Button or dropdown
        assert(dropdown.skinArrow.path:find('eui%-arrow%-down3') and dropdown.skinArrow.width == 10)
        assert(button.Arrow.alpha == 0 and button.normal.alpha == 0 and dropdown.skinFill.alpha == 1 and dropdown.Icon.alpha == 0.7)
        local regions, hooks = #dropdown.regions, #(dropdown.hooks.OnClick or {})
        for _ = 1, 100 do
            local empty, result = dropdown:GenerateMenu()
            dropdown:OverrideText('Warrior')
            for _, fn in ipairs(button.hooks.OnClick or {}) do fn(button) end
            assert(empty == nil and result == 'menu-native' and dropdown.selectedText == 'Warrior')
            assert(button.Arrow.alpha == 0 and button.normal.alpha == 0 and dropdown.skinFill.alpha == 1 and dropdown.skinArrow.alpha == 1, 'dropdown restored native artwork on interaction')
        end
        local replacement = button:CreateTexture(); replacement:SetAlpha(1)
        button:SetNormalTexture(replacement); replacement:SetAlpha(1)
        assert(replacement.alpha == 0, 'replacement state texture escaped the skin')
        assert(#dropdown.regions == regions + (legacy and 0 or 1) and #(dropdown.hooks.OnClick or {}) == hooks, 'dropdown interactions recreated art or hooks')
        local _, _, _, alpha = popupOwners[dropdown].GetPanelColor()
        assert(alpha == 0.98 and button.scripts.OnClick() == 'dropdown-native')
    end
    legacyDropdownMode = false
    local oldFont = skin.Font
    skin.Font = function(t) count('Font'); if t.SetFont then t:SetFont('eui', 12, '') end end
    local opt = api.CreateWindow('ForeverCompanionOptionsFrame')
    opt.headTitle = label(opt)
    opt.pages = {}; opt.current = 1
    local sf = api.CreateScrollFrame(opt)
    local content = frame('Frame', nil, sf)
    opt.pages[1] = {sf = sf, content = content}
    local heading = label(content)
    local item = frame('Button', nil, content); item.itemId = 123; item.name = label(item, 0, 0.44, 0.87)
    local difficulty = label(content, 0.2, 1, 0.2)
    local cb = frame('CheckButton', nil, content); cb.checked = true
    local mark = cb:CreateTexture(); mark.visible = true
    local disabledMark = cb:CreateTexture(); disabledMark.visible = false
    cb.GetCheckedTexture = function() return mark end
    cb.GetDisabledCheckedTexture = function() return disabledMark end
    cb.SetCheckedTexture = function(self, value) mark = value end
    cb.scripts.OnClick = function(self) self.checked = not self.checked end
    function opt:ShowPage(index)
        self.current = index
        local page = self.pages[index]
        if not page then
            local child = frame('Frame', nil, self)
            page = {sf = child}; self.pages[index] = page
            page.heading = label(child)
            page.nativeAction = function() return 'page-native' end
        end
        heading:SetTextColor(1, 0.82, 0)
        return 'page-result', nil, 3
    end
    nativeOpen = function() return opt:ShowPage(1) end
    flush()
    assert(opt.softOptions.noAccent and opt.softOptions.noBorder)
    local canvas
    for _, child in ipairs(opt.children) do if child.mouseEnabled == false and #child.regions == 3 then canvas = child end end
    assert(canvas and canvas.regions[1].color[1] == 0.055 and canvas.regions[2].gradient[9] == 0.48)
    assert(not canvas.childReads, 'decorative canvas was traversed')
    assert(heading.font == 'eui' and heading.textColor[1] == 0.91 and opt.headTitle.textColor[2] == 0.824)
    assert(item.name.textColor[3] == 0.87 and difficulty.textColor[2] == 1, 'semantic colours changed')
    assert(mark.color[2] == 0.824 and mark.points[1][4] == 7 and mark.visible and not disabledMark.visible)
    cb.scripts.OnClick(cb); assert(not cb.checked, 'native checkbox action replaced')
    local replacement = cb:CreateTexture(); replacement.visible = true
    cb:SetCheckedTexture(replacement); assert(replacement.color[2] == 0.824 and replacement.visible)
    local beforeWrites = heading.writes
    heading:SetFontObject('native'); assert(heading.font == 'eui' and heading.writes == beforeWrites + 2, 'font reset caused recursive public font writes')
    local result, gap, third = opt:ShowPage(2)
    assert(result == 'page-result' and gap == nil and third == 3)
    assert(opt.pages[2].heading.font == 'eui' and opt.pages[2].heading.textColor[1] == 0.91, 'new page waited for timer styling')
    assert(opt.pages[2].nativeAction() == 'page-native')
    local stale = frame('Frame', nil, opt); stale.visible = false
    -- Warm the stale page once, then it must be skipped by full refreshes.
    stale.visible = true; opt.pages[3] = {sf = stale}; opt:ShowPage(3); stale.visible = false
    local staleReads = stale.childReads
    -- A completed FC open also covers first-load pages, with native returns intact.
    local open, nilResult, last = ForeverCompanion:OpenOptions()
    assert(open == 'page-result' and nilResult == nil and last == 3)
    local writes, children, markerWrites = calls.Font, #opt.children, replacement.colorWrites
    for _ = 1, 100 do opt:ShowPage(1) end
    flush()
    assert(calls.Font == writes and #opt.children == children and replacement.colorWrites == markerWrites, 'warm navigation rewrote fonts/markers or created canvases')
    assert(stale.childReads == staleReads)
    -- Pooled layout only visits active rows, never their scroll-content owner.
    local pooled = api.VirtualList(nil, content); pooled.active = {[1] = frame('Frame', nil, content)}
    label(pooled.active[1]); flush()
    local ownerReads = content.childReads
    for _ = 1, 100 do pooled:Layout() end
    assert(content.childReads == ownerReads and pooled.active[1].regions[1].font == 'eui')
    -- The exact talent shape keeps artwork/desaturation/rank semantics.
    local talents = api.CreateWindow('ForeverCompanionTalentFrame')
    local talent = frame('Button', nil, talents)
    talent.tex, talent.outerTex, talent.rankBg = talent:CreateTexture(), talent:CreateTexture(), talent:CreateTexture()
    talent.rankFS = label(talent, 1, 0.84, 0)
    talent.outerTex.GetVertexColor = function(self) return table.unpack(self.vertex or {1, 0.84, 0}) end
    talent.outerTex.SetVertexColor = function(self, ...) self.vertex = {...} end
    talent.tex.art, talent.tex.desaturated = 'spell-texture', false
    flush()
    assert(#talents.children == 1, 'talent artwork covered by a canvas')
    assert(talent.outerTex.alpha == 0 and talent.fcSkinEdges[1].color[2] == 0.84 and talent.rankFS.textColor[2] == 0.84)
    talent.outerTex:SetVertexColor(0.5, 0.5, 0.5)
    assert(talent.fcSkinEdges[1].color[1] == 0.5 and talent.tex.art == 'spell-texture' and talent.tex.desaturated == false)
    local edgeCount = #talent.regions
    for _ = 1, 10 do talent.outerTex:SetVertexColor(1, 0.84, 0) end
    assert(#talent.regions == edgeCount)
    enabled = false; heading:SetTextColor(1, 0.82, 0); assert(heading.textColor[1] == 1)
    enabled = true; combat = true; heading:SetTextColor(1, 0.82, 0); assert(heading.textColor[1] == 1)
    combat = false; externalEvents.scripts.OnEvent(externalEvents, 'PLAYER_REGEN_ENABLED'); flush()
    assert(heading.textColor[1] == 0.91)
    local themeWrites = calls.Font; looks(); flush(); assert(calls.Font > themeWrites)
    -- Factory UI decoration waits until combat ends without changing returns.
    combat = true
    local late, gap, last = api.CreateWindow('CombatCompanionWindow')
    assert(late and gap == nil and last == 'sentinel' and not late.softOptions)
    combat = false; externalEvents.scripts.OnEvent(externalEvents, 'PLAYER_REGEN_ENABLED'); flush()
    assert(late.softOptions.noAccent)
    -- Overlapping construction requests are serviced once per subtree.
    local overlap = api.CreateWindow('OverlappingCompanionWindow')
    local scroll = api.CreateScrollFrame(overlap)
    api.CreateSearchBox(scroll)
    local fallback = api.VirtualList(nil, scroll)
    for _ = 1, 100 do fallback:Layout() end
    flush(); assert(scroll.childReads == 1, 'overlapping parent/child requests repeated the subtree scan')
    skin.Font = oldFont
    print('BENCH companion_navigation callbacks=100 font_writes=0 new_canvases=0; pooled_layouts=100 owner_scans=0')
end
looks(); flush()
enabled = false
local before = calls.Shell; api.CreateWindow("AnotherWindow"); flush()
assert(calls.Shell == before, "EUI master/per-addon disable ignored")
enabled = true
SlashCmdList.EUIADDONSKINS("off")
api.CreateWindow("DisabledWindow"); assert(calls.Shell == before)
SlashCmdList.EUIADDONSKINS("on")
api.CreateWindow("EnabledWindow"); flush(); assert(calls.Shell == before + 1)
assert(#errors == 0, table.concat(errors, "\n"))
-- Missing API must leave FC unchanged and expose a usable status command.
EllesmereUI = nil
local original = api.CreateWindow
local missingNS = {}
chunk("EUIAddonSkins", missingNS)
integration("EUIAddonSkins", missingNS)
assert(api.CreateWindow == original)
SlashCmdList.EUIADDONSKINS("")
-- Missing target must be harmless and must not block other skin modules.
EUIAddonSkinsDB = {}
ForeverCompanionAPI = nil
EllesmereUI = { RegisterSkin = function(_, fn) callback = fn; fn(skin) end }
local collection = {}
chunk("EUIAddonSkins", collection)
assert(loadfile("EUIAddonSkins/Accent.lua"))("EUIAddonSkins", collection)
local coreEvents = lastCreated
assert(loadfile("EUIAddonSkins/Widgets.lua"))("EUIAddonSkins", collection)
integration("EUIAddonSkins", collection)
callback(skin)
assert(not collection.modules[1].attempted, "absent target must stay dormant")
local otherRuns = 0
collection.RegisterModule("OtherAddon", "Other Addon", function() return true end,
    function() otherRuns = otherRuns + 1 end)
assert(otherRuns == 1 and collection.modules[2].active, "unrelated skin blocked by missing FC")
-- Load-on-demand target activates once, including after PLAYER_LOGIN.
ForeverCompanionAPI = { COLORS = {} }
coreEvents.scripts.OnEvent(coreEvents, "ADDON_LOADED", "ForeverCompanion")
assert(collection.modules[1].active, "late target not activated")
local wrapped = ForeverCompanionAPI.CreateWindow
coreEvents.scripts.OnEvent(coreEvents, "PLAYER_LOGIN")
coreEvents.scripts.OnEvent(coreEvents, "ADDON_LOADED", "UnrelatedAddon")
assert(otherRuns == 1 and ForeverCompanionAPI.CreateWindow == wrapped, "module installed twice")
collection.RegisterModule("BrokenAddon", "Broken Addon", function() return true end,
    function() error("expected test failure") end)
assert(not collection.modules[3].active and #errors == 1, "installer failure not isolated")
local afterFailure = false
collection.RegisterModule("WorkingAddon", "Working Addon", function() return true end,
    function() afterFailure = true end)
assert(afterFailure, "broken integration blocked another skin")
print("PASS: syntax, preserved returns/clicks, dynamic controls, coalescing, restricted frames, theme/toggles, missing API/target, late activation, independent modules, error isolation")
