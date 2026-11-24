-- Hunter's Field Guide 1.1.1: the Forever book in EUI (spellbook art faded,
-- light text palette, square icons/tabs, portrait in the title bar, EUI page
-- arrows), the Classic book's toolbar, the Filter menu, the popups and the lazy
-- export window.
do
local globals = {"HuntersFieldGuide", "FieldGuideFrame", "FieldGuideExport", "FieldGuideExportScroll",
    "FieldGuideTargetPanel", "FieldGuideToast", "SPELLBOOK_FONT_COLOR",
    "CreateFrame", "hooksecurefunc", "InCombatLockdown", "geterrorhandler"}
local saved = {}
for _, key in ipairs(globals) do saved[key] = _G[key] end

local INK = {0.24, 0.15, 0.06}
local BOOK_INK = {0.2, 0.12, 0.05}
local function Near(c, r, g, b) return math.abs(c[1] - r) < 0.001 and math.abs(c[2] - g) < 0.001 and math.abs(c[3] - b) < 0.001 end

local function Run(look)
    local calls, frames, textures, hooks, walks = 0, 0, 0, 0, 0
    local locked, enabled = false, true
    local events, looks = {}, {}
    local function region(kind, parent)
        local f = {kind = kind, alpha = 1, scripts = {}, regions = {}, children = {}, shown = true, masks = {}, parent = parent}
        if parent and kind ~= "Texture" and kind ~= "FontString" and kind ~= "MaskTexture" then
            parent.children[#parent.children + 1] = f
        end
        function f:GetObjectType() return self.kind end
        function f:GetParent() return self.parent end
        function f:SetAlpha(value) self.alpha = value end
        function f:GetAlpha() return self.alpha end
        function f:SetAllPoints(target) self.allPoints = target end
        function f:SetPoint(...) self.point = {...} end
        function f:ClearAllPoints() self.point = nil end
        function f:SetSize(w, h) self.width, self.height = w, h end
        function f:SetHeight(h) self.height = h end
        function f:EnableMouse(value) self.mouse = value end
        function f:SetColorTexture(...) self.fill = {...} end
        function f:SetAtlas(atlas) self.atlas = atlas end
        function f:GetAtlas() return self.atlas end
        function f:GetDrawLayer() return self.layer, self.sublevel end
        function f:SetTextColor(r, g, b) self.color = {r, g, b} end
        function f:GetTextColor() if self.color then return self.color[1], self.color[2], self.color[3] end end
        function f:SetText(text) self.text = text; self.textWrites = (self.textWrites or 0) + 1 end
        function f:GetText() return self.text end
        function f:GetFontString() return self.label end
        function f:GetNumMaskTextures() return #self.masks end
        function f:GetMaskTexture(i) return self.masks[i] end
        function f:RemoveMaskTexture(mask)
            for i, m in ipairs(self.masks) do if m == mask then table.remove(self.masks, i) end end
        end
        function f:GetRegions() walks = walks + 1; return table.unpack(self.regions) end
        function f:GetChildren() walks = walks + 1; return table.unpack(self.children) end
        function f:IsShown() return self.shown end
        function f:Show() self.shown = true end
        function f:Hide() self.shown = false end
        function f:SetShown(on) self.shown = on end
        function f:SetBackdrop(value) self.backdrop = value end
        function f:CreateTexture(_, layer, _, sublevel)
            textures = textures + 1
            local t = region("Texture")
            t.layer, t.sublevel = layer, sublevel
            self.regions[#self.regions + 1] = t
            return t
        end
        function f:CreateFontString()
            local t = region("FontString")
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
    local function text(parent, color, value)
        local fs = parent:CreateFontString()
        fs:SetTextColor(color[1], color[2], color[3])
        fs.text = value or "text"
        return fs
    end
    local function button(parent, name)
        local b = region("Button", parent)
        b.label = region("FontString")
        b.label:SetTextColor(1, 0.82, 0)
        b.scripts.OnClick = function() return "native-" .. name end
        return b
    end
    local function check(parent)
        local c = region("CheckButton", parent)
        c.Text = region("FontString")
        return c
    end

    CreateFrame = function(_, _, parent)
        frames = frames + 1
        return region("Frame", parent)
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
    SPELLBOOK_FONT_COLOR = {GetRGB = function() return BOOK_INK[1], BOOK_INK[2], BOOK_INK[3] end}

    -- The journal as UI.lua builds it for the chosen look.
    local styles = {
        body = {color = BOOK_INK}, heading = {color = BOOK_INK}, small = {color = BOOK_INK},
        accent = {color = {0.45, 0.12, 0.02}}, label = {color = {0.42, 0.3, 0.16}},
        good = {color = {0.04, 0.34, 0.04}}, bad = {color = {0.55, 0.05, 0.02}},
        pager = {color = BOOK_INK}, header = {color = BOOK_INK},
    }
    local guide = {skinName = look, exports = 0, refreshes = 0, Skins = {forever = {styles = styles, rare = {0, 0.35, 0.8}}}}
    local root = region("Frame")
    local page = root:CreateTexture(nil, "BACKGROUND", nil, 2)
    page:SetAtlas(look == "forever" and "spellbook-Page-Right-C60" or nil)
    root.NineSlice = region("Frame")
    local ring
    if look == "forever" then
        root.Bg = root:CreateTexture(nil, "BACKGROUND")
        root.TitleContainer = {TitleText = region("FontString")}
        root.title = root.TitleContainer.TitleText
        root.CloseButton = button(root, "close")
        root.PortraitContainer = region("Frame", root)
        ring = root.PortraitContainer:CreateTexture(nil, "OVERLAY")
        root.portrait = root.PortraitContainer:CreateTexture(nil, "OVERLAY", nil, 2)
        root.portrait.masks[1] = region("MaskTexture")
        root.header = region("Frame", root)
        root.header.plate = root.header:CreateTexture(nil, "BACKGROUND")
        root.header.plate:SetAtlas("spellbook-list-backplate")
        root.header.text = text(root.header, BOOK_INK, "Families")
    end
    for _, key in ipairs({"back", "map", "model", "filter"}) do root[key] = button(root, key) end
    root.search = region("EditBox", root)
    root.search.searchIcon = region("Texture")
    root.search.scripts.OnTextChanged = function() return "native-search" end
    root.gear = region("Button", root)
    root.home = region("Button", root)
    -- a tab and a grid entry, as SKINS.forever.Tab and ForeverEntry make them
    local tab = region("Button", root)
    local tabIcon = tab:CreateTexture(nil, "ARTWORK")
    tabIcon.layer, tabIcon.sublevel = "ARTWORK", 0
    tabIcon.masks[1] = region("MaskTexture") -- SquareMask
    tab.frame = tab:CreateTexture(nil, "ARTWORK", nil, 1); tab.frame:SetAtlas("spellbook-Tab-Frame-C60")
    tab.active = tab:CreateTexture(nil, "ARTWORK", nil, 1); tab.active:SetAtlas("spellbook-Tab-Frame-Glow-C60")
    tab.glow = tab:CreateTexture(nil, "ARTWORK", nil, 1); tab.glow:SetAtlas("spellbook-Tab-Frame-glow-gradient-C60")
    function tab:SetChecked(on) self.frame:SetShown(not on); self.active:SetShown(on); self.glow:SetShown(on) end
    tab:SetChecked(true)
    local entry = region("Button", root)
    entry.backplate = entry:CreateTexture(nil, "BACKGROUND"); entry.backplate:SetAtlas("spellbook-item-backplate")
    entry.slot = region("Frame", entry)
    entry.icon = entry.slot:CreateTexture(nil, "ARTWORK", nil, -1)
    entry.icon.masks[1] = region("MaskTexture")
    entry.border = entry.slot:CreateTexture(nil, "OVERLAY", nil, 1)
    entry.name = text(entry, BOOK_INK, "Bat")
    entry.sub = text(entry, BOOK_INK, "0 / 22")
    function entry:SetEntry(_, name, sub, inactive)
        self.border:SetAtlas(inactive and "spellbook-item-iconframe-inactive" or "spellbook-item-iconframe")
        self.name:SetText(name); self.sub:SetText(sub)
        self.name:SetTextColor(BOOK_INK[1], BOOK_INK[2], BOOK_INK[3])
    end
    -- (grid entries are not filled before the journal first opens: the border has no atlas yet)
    local pager = {prev = button(root, "prev"), next = button(root, "next"), text = text(root, BOOK_INK, "Page 1/1")}
    local templateButton = button(root, "settings")
    templateButton.Left, templateButton.Right = region("Texture"), region("Texture")
    local hidden = region("Frame", root)
    hidden.shown = false
    local hiddenLabel = text(hidden, {0.42, 0.3, 0.16}, "DAMAGE")
    local menu = region("Frame", root)
    menu.backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"}
    text(menu, {1, 0.82, 0}, "Sort beasts by")
    menu.level, menu.speed, menu.look = check(menu), check(menu), check(menu)
    menu.only = {fast = check(menu), elite = check(menu)}
    menu.clear = button(menu, "clear")
    root.filterMenu = menu
    root.filter.label:SetTextColor(0.3, 1, 0.3) -- a filter is on
    guide.pager = pager

    -- The page drawn by RefreshUI: book text in the current style colours.
    local dynamic = text(root, BOOK_INK, "")
    function guide:RefreshUI()
        self.refreshes = self.refreshes + 1
        entry:SetEntry(nil, "Boar", "2 / 35 |cff0a570anew|r", true)
        local st = self.Skins.forever.styles
        dynamic:SetTextColor(st.body.color[1], st.body.color[2], st.body.color[3])
        dynamic:SetText("Studied with Beast Lore |cff0a570aLearnable|r")
    end
    function guide:PetTabRefresh() end

    -- The popups (UI.lua CreateTargetPanel, CreateToast).
    local panel = region("Frame")
    panel.backdrop = {}
    panel.title = text(panel, {1, 0.82, 0}, "Found in")
    panel.zones = text(panel, INK, "Elwynn Forest (5)")
    panel.done = button(panel, "done")
    local toast = region("Frame")
    toast.backdrop = {}
    toast.head = text(toast, INK, "NEW BEAST RECORDED")
    toast.sub = text(toast, INK, "")
    toast.done = button(toast, "toast-done")
    function guide:Toast(_, _) toast.sub:SetText("Bite 1 |cff0a570a(new)|r") end
    function guide:ToastNotice() toast.sub:SetText("Learn it") end

    function guide:ShowExport()
        self.exports = self.exports + 1
        if not FieldGuideExport then
            local export = region("Frame")
            export.title = text(export, {1, 0.82, 0}, "Field Guide discoveries (3)")
            export.hint = text(export, {1, 1, 1}, "Press Ctrl+C")
            local close = button(export, "export-close")
            local scroll = region("ScrollFrame", export)
            scroll.ScrollBar = region("Slider", scroll)
            export.link = region("EditBox", export)
            export.close, export.scroll = close, scroll
            FieldGuideExport, FieldGuideExportScroll = export, scroll
        end
        return "native-export"
    end
    HuntersFieldGuide, FieldGuideFrame, FieldGuideExport, FieldGuideExportScroll = guide, root, nil, nil
    FieldGuideTargetPanel, FieldGuideToast = panel, toast

    local S = {}
    for _, name in ipairs({"Shell", "Panel", "CloseButton", "EditBox", "ScrollBar", "Button", "Checkbox", "Font",
        "FadeNineSlice", "SquareIcon", "PageButton"}) do
        S[name] = function(f, options, extra)
            assert(not locked, "cosmetic write in combat: " .. name)
            calls = calls + 1
            f.skin, f.opts = name, options
            if name == "EditBox" and f.searchIcon then f.searchIcon:SetAlpha(0) end
            if name == "Font" then f.font = (f.font or 0) + 1 end
            if name == "FadeNineSlice" then f:SetAlpha(0) end
            if name == "SquareIcon" then f.border = options end
        end
    end
    local panelColor, accent = {0.1, 0.1, 0.12}, {0.2, 0.7, 0.6}
    S.GetPanelColor = function() return panelColor[1], panelColor[2], panelColor[3], 1 end
    S.GetAccentColor = function() return accent[1], accent[2], accent[3] end
    S.OnLooksChanged = function(fn) looks[#looks + 1] = fn end

    local ns = {IsEnabled = function() return enabled end, AttachAccent = function(_, f) f.accent = true end}
    local module = {}
    ns.RegisterModule = function(id, label, available, install)
        assert(id == "HuntersFieldGuide" and label == "Hunter's Field Guide" and available())
        install(S, module)
    end
    assert(loadfile("EUIAddonSkins/Widgets.lua"))("EUIAddonSkins", ns)
    ns.RegisterSkinDefinition = function(id, fn) assert(id == "HuntersFieldGuide"); fn() end

    -- Activation during combat waits for its end.
    locked = true
    local textures0 = textures
    assert(loadfile("EUIAddonSkins/Skins/HuntersFieldGuide.lua"))("EUIAddonSkins", ns)
    assert(calls == 0 and textures == textures0)
    locked = false
    local recovery = assert(events.PLAYER_REGEN_ENABLED)
    recovery.scripts.OnEvent(recovery)
    assert(calls > 0)

    -- Toolbar, Filter menu, popups: both books.
    for _, key in ipairs({"back", "map", "model", "filter"}) do
        assert(root[key].skin == "Button" and root[key].scripts.OnClick() == "native-" .. key)
    end
    assert(root.filter.label.color[1] == 0.3 and root.filter.label.color[2] == 1)
    assert(root.search.skin == "EditBox" and root.search.opts.padInput == false)
    assert(root.search.searchIcon:GetAlpha() == 1 and root.search.scripts.OnTextChanged() == "native-search")
    assert(not root.gear.skin and not root.home.skin)
    assert(menu.skin == "Panel" and menu.backdrop == nil and menu.regions[1].font == 1)
    for _, c in ipairs({menu.level, menu.speed, menu.look, menu.only.fast, menu.only.elite}) do assert(c.skin == "Checkbox") end
    assert(menu.clear.skin == "Button" and menu.clear.scripts.OnClick() == "native-clear")
    for _, p in ipairs({panel, toast}) do assert(p.skin == "Panel" and p.backdrop == nil and p.done.skin == "Button") end
    assert(Near({0.86, 0.86, 0.86}, panel.zones:GetTextColor()) and Near({1, 0.82, 0}, panel.title:GetTextColor()))
    assert(Near({0.86, 0.86, 0.86}, toast.head:GetTextColor()))
    guide:Toast("Boar", "studied")
    assert(toast.sub.text == "Bite 1 |cff73e673(new)|r")

    if look == "forever" then
        -- Window: frame art faded, owned fill and title strip, border frame.
        assert(root.NineSlice.skin == "FadeNineSlice" and root.Bg.alpha == 0 and page.alpha == 0)
        page:SetAlpha(1); assert(page.alpha == 0, "parchment came back")
        assert(root.CloseButton.skin == "CloseButton" and root.title.font == 1)
        local backing, bar
        for _, r in ipairs(root.regions) do
            if r.sublevel == -8 then backing = r elseif r.sublevel == -5 then bar = r end
        end
        assert(backing and backing.fill[1] == panelColor[1] and bar and bar.height == 25)
        -- Portrait: ring faded, square icon in the title bar, mask removed.
        assert(ring.alpha == 0 and root.portrait.alpha == 1 and #root.portrait.masks == 0)
        assert(root.portrait.width == 28 and root.portrait.point[2] == root and root.portrait.border)
        -- Header, entries, tabs, page arrows.
        assert(root.header.plate.alpha == 0 and Near({1, 1, 1}, root.header.text:GetTextColor()))
        assert(entry.border.atlas == nil and entry.border.alpha == 0)
        assert(entry.backplate.alpha == 0 and #entry.icon.masks == 0 and entry.icon.border)
        assert(tab.frame.alpha == 0 and tab.active.alpha == 0 and tab.glow.alpha == 0 and tabIcon.border and #tabIcon.masks == 0)
        assert(pager.prev.skin == "PageButton" and pager.prev.opts == "<" and pager.next.opts == ">")
        assert(templateButton.skin == "Button" and templateButton.scripts.OnClick() == "native-settings")
        -- Text: light palette, including labels on pages not shown yet.
        assert(Near({0.86, 0.86, 0.86}, entry.name:GetTextColor()) and Near({0.86, 0.86, 0.86}, pager.text:GetTextColor()))
        assert(Near({0.6, 0.6, 0.62}, hiddenLabel:GetTextColor()))
        assert(guide.Skins.forever.rare[3] == 1 and styles.accent.color[2] == accent[2])
        -- The underline follows the tab's own selection.
        local line = tab.regions[#tab.regions]
        assert(line.shown and line.fill[2] == accent[2])
        tab:SetChecked(false); assert(not line.shown)
        tab:SetChecked(true); assert(line.shown)
        -- A drawn page: the dark-green parchment code becomes a light one.
        root.shown = true
        guide:RefreshUI()
        assert(dynamic.text == "Studied with Beast Lore |cff73e673Learnable|r")
        assert(entry.sub.text == "2 / 35 |cff73e673new|r" and Near({0.86, 0.86, 0.86}, entry.name:GetTextColor()))
        assert(entry.border.atlas == "spellbook-item-iconframe-inactive" and entry.border.alpha == 0)
        -- Warm redraws: no new objects or hooks, no text rewritten twice.
        local warm = {calls, frames, textures, hooks}
        local writes = dynamic.textWrites
        for _ = 1, 50 do guide:RefreshUI() end
        assert(calls == warm[1] and frames == warm[2] and textures == warm[3] and hooks == warm[4])
        assert(dynamic.textWrites == writes + 100) -- native write + one recolour per draw
        -- Hidden pages are not walked on a redraw.
        hiddenLabel:SetTextColor(BOOK_INK[1], BOOK_INK[2], BOOK_INK[3])
        guide:RefreshUI()
        assert(Near(BOOK_INK, hiddenLabel:GetTextColor()))
        hidden.shown = true; guide:RefreshUI()
        assert(Near({0.86, 0.86, 0.86}, hiddenLabel:GetTextColor()))
        -- Accent change: owned art and accent text follow, the open page is redrawn.
        accent = {0.9, 0.3, 0.1}
        local drawn = guide.refreshes
        looks[1]()
        assert(line.fill[1] == 0.9 and styles.accent.color[1] == 0.9 and guide.refreshes == drawn + 1)
        root.shown = false
    else
        -- The Classic book keeps its art and ink.
        assert(not root.NineSlice.skin and page.alpha == 1)
        assert(Near(BOOK_INK, entry.name:GetTextColor()) and not entry.icon.border and tab.frame.alpha == 1)
        assert(styles.body.color == BOOK_INK and not pager.prev.skin)
        guide:RefreshUI()
        assert(dynamic.text == "Studied with Beast Lore |cff0a570aLearnable|r")
    end

    -- The export window is built on demand and styled once.
    assert(FieldGuideExport == nil)
    assert(guide:ShowExport() == "native-export")
    local export = FieldGuideExport
    assert(export.skin == "Shell" and export.accent and export.title.font == 1)
    assert(export.close.skin == "CloseButton" and export.close.scripts.OnClick() == "native-export-close")
    assert(export.scroll.ScrollBar.skin == "ScrollBar" and export.link.skin == "EditBox")
    local warm = {calls, frames, textures, hooks}
    for _ = 1, 20 do assert(guide:ShowExport() == "native-export") end
    assert(calls == warm[1] and frames == warm[2] and textures == warm[3] and hooks == warm[4])

    -- A theme change during combat waits for its end.
    locked = true; looks[1](); locked = false
    local before = calls
    recovery.scripts.OnEvent(recovery)
    assert(calls > before)

    -- A disabled skin does no further work.
    enabled = false
    before = calls
    looks[1](); module.refresh(); guide:RefreshUI(); guide:ShowExport(); guide:Toast("Boar", "seen")
    assert(calls == before)
    return calls
end

local forever = Run("forever")
local classic = Run("classic")
print(("PASS: Hunter's Field Guide Forever book in EUI (%d calls: faded spellbook art, light palette and colour codes, square icons/tabs, title-bar portrait, page arrows) and Classic toolbar (%d calls); Filter menu, popups, lazy export, hidden pages, combat, theme and disabled skin")
    :format(forever, classic))
for _, key in ipairs(globals) do _G[key] = saved[key] end
end
