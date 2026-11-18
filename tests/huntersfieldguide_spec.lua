-- Hunter's Field Guide 1.1.1: window chrome, toolbar, Filter menu and the lazy
-- export window. The spellbook pages, entries, tabs and popups stay native.
do
local globals = {"HuntersFieldGuide", "FieldGuideFrame", "FieldGuideExport", "FieldGuideExportScroll",
    "CreateFrame", "hooksecurefunc", "InCombatLockdown", "geterrorhandler"}
local saved = {}
for _, key in ipairs(globals) do saved[key] = _G[key] end

local function Run(look)
    local calls, frames, textures, hooks = 0, 0, 0, 0
    local locked, enabled = false, true
    local events, looks = {}, {}
    local function region(kind)
        local f = {kind = kind, alpha = 1, scripts = {}, regions = {}, children = {}, shown = true}
        function f:GetObjectType() return self.kind end
        function f:GetParent() return self.parent end
        function f:SetAlpha(value) self.alpha = value end
        function f:GetAlpha() return self.alpha end
        function f:SetAllPoints(target) self.allPoints = target end
        function f:SetPoint(...) self.point = {...} end
        function f:EnableMouse(value) self.mouse = value end
        function f:SetColorTexture(...) self.fill = {...}; self.fills = (self.fills or 0) + 1 end
        function f:SetTextColor(...) self.color = {...} end
        function f:GetFontString() return self.label end
        function f:GetRegions() return table.unpack(self.regions) end
        function f:GetChildren() return table.unpack(self.children) end
        function f:IsShown() return self.shown end
        function f:SetBackdrop(value) self.backdrop = value end
        function f:CreateTexture(_, layer, _, sublevel)
            textures = textures + 1
            local t = region("Texture")
            t.layer, t.sublevel = layer, sublevel
            self.regions[#self.regions + 1] = t
            return t
        end
        function f:HookScript(name, fn)
            hooks = hooks + 1
            local old = self.scripts[name]
            self.scripts[name] = function(...) if old then old(...) end; fn(...) end
        end
        function f:SetScript(name, fn) self.scripts[name] = fn end
        function f:RegisterEvent(event) events[event] = self end
        return f
    end
    local function button(text)
        local b = region("Button")
        b.label = region("FontString")
        b.label:SetTextColor(1, 0.82, 0)
        b.text = text
        b.scripts.OnClick = function() return "native-" .. text end
        return b
    end
    local function check()
        local c = region("CheckButton")
        c.Text = region("FontString")
        return c
    end

    CreateFrame = function(_, _, parent)
        frames = frames + 1
        local f = region("Frame")
        f.parent = parent
        return f
    end
    hooksecurefunc = function(owner, key, fn)
        hooks = hooks + 1
        local native = owner[key]
        owner[key] = function(...)
            local result = table.pack(native(...))
            fn(...)
            return table.unpack(result, 1, result.n)
        end
    end
    InCombatLockdown = function() return locked end
    geterrorhandler = function() return function(message) error(message) end end

    -- The journal as UI.lua builds it for the chosen look.
    local root = region("Frame")
    local page = root:CreateTexture(nil, "BACKGROUND", nil, 2) -- the spellbook page
    root.NineSlice = region("Frame")
    if look == "forever" then
        root.Bg = root:CreateTexture(nil, "BACKGROUND")
        root.TitleContainer = {TitleText = region("FontString")}
        root.CloseButton = button("close")
        root.title = root.TitleContainer.TitleText
    end
    for _, key in ipairs({"back", "map", "model", "filter"}) do root[key] = button(key) end
    root.search = region("EditBox")
    root.search.searchIcon = region("Texture")
    root.search.scripts.OnTextChanged = function() return "native-search" end
    root.gear = region("Button")
    root.home = region("Button")
    local menu = region("Frame")
    menu.backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"}
    menu.regions[#menu.regions + 1] = region("FontString")
    menu.level, menu.speed, menu.look = check(), check(), check()
    menu.only = {fast = check(), elite = check()}
    menu.clear = button("clear")
    root.filterMenu = menu
    root.filter.label:SetTextColor(0.3, 1, 0.3) -- a filter is on
    local textures0 = textures

    local guide = {skinName = look, exports = 0}
    function guide:ShowExport()
        self.exports = self.exports + 1
        if not FieldGuideExport then
            local export = region("Frame")
            export.title, export.hint = region("FontString"), region("FontString")
            export.regions = {export.title, export.hint, region("Texture")}
            local close = button("export-close")
            local scroll = region("ScrollFrame")
            scroll.ScrollBar = region("Slider")
            export.link = region("EditBox")
            export.box = region("EditBox")
            export.children = {close, scroll, export.link}
            export.close, export.scroll = close, scroll
            FieldGuideExport, FieldGuideExportScroll = export, scroll
        end
        return "native-export"
    end
    HuntersFieldGuide, FieldGuideFrame, FieldGuideExport, FieldGuideExportScroll = guide, root, nil, nil

    local S = {}
    for _, name in ipairs({"Shell", "Panel", "CloseButton", "EditBox", "ScrollBar", "Button", "Checkbox", "Font", "FadeNineSlice"}) do
        S[name] = function(f, options)
            assert(not locked, "cosmetic write in combat: " .. name)
            calls = calls + 1
            f.skin, f.opts = name, options
            if name == "EditBox" and f.searchIcon then f.searchIcon:SetAlpha(0) end
            if name == "Font" then f.font = (f.font or 0) + 1 end
            if name == "FadeNineSlice" then f:SetAlpha(0) end
        end
    end
    local panel = {0.1, 0.1, 0.12}
    S.GetPanelColor = function() return panel[1], panel[2], panel[3], 1 end
    S.GetAccentColor = function() return 0.2, 0.7, 0.6 end
    S.OnLooksChanged = function(fn) looks[#looks + 1] = fn end

    local ns = {IsEnabled = function() return enabled end, AttachAccent = function(_, f) f.accent = true end}
    local module = {}
    ns.RegisterModule = function(id, label, available, install)
        assert(id == "HuntersFieldGuide" and label == "Hunter's Field Guide" and available())
        install(S, module)
    end
    assert(loadfile("EUIAddonSkins/Widgets.lua"))("EUIAddonSkins", ns)
    local definitions = 0
    ns.RegisterSkinDefinition = function(id, fn)
        definitions = definitions + 1
        assert(id == "HuntersFieldGuide")
        fn()
    end

    -- Activation during combat waits for its end.
    locked = true
    assert(loadfile("EUIAddonSkins/Skins/HuntersFieldGuide.lua"))("EUIAddonSkins", ns)
    assert(definitions == 1 and calls == 0 and textures == textures0)
    locked = false
    local recovery = assert(events.PLAYER_REGEN_ENABLED)
    recovery.scripts.OnEvent(recovery)
    assert(calls > 0)

    -- The book page and native controls keep their art, actions and colours.
    assert(page.alpha == 1 and page.fill == nil)
    for _, key in ipairs({"back", "map", "model", "filter"}) do
        assert(root[key].skin == "Button" and root[key].label.font == 1)
        assert(root[key].scripts.OnClick() == "native-" .. key)
    end
    assert(root.filter.label.color[1] == 0.3 and root.filter.label.color[2] == 1)
    assert(root.search.skin == "EditBox" and root.search.opts.padInput == false)
    assert(root.search.searchIcon:GetAlpha() == 1 and root.search.scripts.OnTextChanged() == "native-search")
    assert(not root.gear.skin and not root.home.skin)
    assert(menu.skin == "Panel" and menu.backdrop == nil and menu.regions[1].font == 1)
    for _, c in ipairs({menu.level, menu.speed, menu.look, menu.only.fast, menu.only.elite}) do
        assert(c.skin == "Checkbox" and c.Text.font == 1)
    end
    assert(menu.clear.skin == "Button" and menu.clear.scripts.OnClick() == "native-clear")

    local backing
    if look == "forever" then
        assert(root.NineSlice.skin == "FadeNineSlice" and root.Bg.alpha == 0)
        assert(root.CloseButton.skin == "CloseButton" and root.title.font == 1)
        backing = root.regions[#root.regions]
        assert(backing ~= page and backing.layer == "BACKGROUND" and backing.sublevel == -8)
        assert(backing.allPoints == root and backing.fill[1] == panel[1])
        assert(textures == textures0 + 1)
        assert(frames == 2) -- the border frame and the combat recovery frame
        root.Bg:SetAlpha(1)
        assert(root.Bg.alpha == 0, "template background came back")
    else
        -- The Classic book keeps its spellbook frame art.
        assert(not root.NineSlice.skin and textures == textures0 and frames == 1)
    end

    -- The export window is built on demand and styled once, on its first show.
    assert(FieldGuideExport == nil)
    assert(guide:ShowExport() == "native-export")
    local export = FieldGuideExport
    assert(export.skin == "Shell" and export.accent and export.backdrop == nil)
    assert(export.title.font == 1 and export.hint.font == 1)
    assert(export.close.skin == "CloseButton" and export.close.scripts.OnClick() == "native-export-close")
    assert(export.scroll.ScrollBar.skin == "ScrollBar" and export.link.skin == "EditBox" and not export.box.skin)
    local warm = {calls, frames, textures, hooks}
    for _ = 1, 50 do assert(guide:ShowExport() == "native-export") end
    root.scripts.OnShow(root)
    assert(guide.exports == 51)
    assert(calls == warm[1] and frames == warm[2] and textures == warm[3] and hooks == warm[4])

    -- Theme changes repaint owned art and fonts without new objects or hooks.
    panel[1] = 0.3
    looks[1]()
    if backing then assert(backing.fill[1] == 0.3) end
    assert(root.back.label.font == 2 and menu.level.Text.font == 2 and export.title.font == 2)
    assert(frames == warm[2] and textures == warm[3] and hooks == warm[4])
    locked = true; panel[1] = 0.5; looks[1](); locked = false
    if backing then assert(backing.fill[1] == 0.3) end
    recovery.scripts.OnEvent(recovery)
    if backing then assert(backing.fill[1] == 0.5) end

    -- A disabled skin does no further work.
    enabled = false
    local before = calls
    looks[1](); module.refresh(); root.scripts.OnShow(root); guide:ShowExport()
    assert(calls == before)
    return calls
end

local forever = Run("forever")
local classic = Run("classic")
print(("PASS: Hunter's Field Guide Forever (%d calls) and Classic (%d calls) chrome, toolbar, Filter menu and lazy export window; native pages, actions, filter colour, combat deferral, theme refresh and disabled skin")
    :format(forever, classic))
for _, key in ipairs(globals) do _G[key] = saved[key] end
end
