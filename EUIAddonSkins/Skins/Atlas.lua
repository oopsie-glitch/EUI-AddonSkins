local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("Atlas", "Atlas", function() return type(_G.Atlas) == "table" end, function(S, module)
    local A = _G.Atlas
    local flatControls = {}
    local soft = ns.CreateSoftSkin(S, module, function(f) return flatControls[f] end)
    local H = ns.CreateSkinHelper(S, module)
    local styled, fonts, surfaces, pooled, poolArt, groups = {}, {}, {}, {}, {}, {}
    local generation, waiting, applying = 1, false, false
    local Apply, Options, PaintWidget
    local menuOptions = {noAccent = true, chevrons = true, compactChecks = true, hoverAlpha = 0.08}
    local imagePath = "Interface\\AddOns\\Atlas\\Images\\"
    -- Exact upstream composite assets; geometry is only a fallback for opaque
    -- IDs. Never classify a known map path by its dimensions alone.
    local chromeSlots = {
        AtlasFrame = {{"TopLeft",512,128,0,0}, {"BottomLeft",512,512,0,-128},
            {"TopRight",512,128,512,0}, {"BottomRight",512,512,512,-128}},
        AtlasFrameSmall = {{"TopLeft",512,128,0,0}, {"BottomLeft",512,512,0,-128},
            {"TopRight",32,128,512,0}, {"BottomRight",32,512,512,-128}},
        AtlasFrameLarge = {{"TopLeft",512,512,0,0}, {"TopRight",512,512,512,0},
            {"MidLeft",512,256,0,-512}, {"MidRight",512,256,512,-512},
            {"BottomLeft",512,32,0,-768}, {"BottomRight",512,32,512,-768}},
    }
    local chromeAssets = {}
    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED"); events:RegisterEvent("PLAYER_REGEN_ENABLED")
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
        waiting = false
        return true
    end
    local function Library(name) return LibStub and LibStub(name, true) end
    local function Color()
        if S.GetPanelColor then return S.GetPanelColor() end
        return 0.04, 0.04, 0.05, 0.95
    end
    local function Font(text)
        if not H.Allowed(text) or text:GetObjectType() ~= "FontString" or fonts[text] == generation then return end
        if text.GetFont and not text:GetFont() then return end
        local r, g, b, a = text:GetTextColor()
        S.Font(text, r, g, b); text:SetTextColor(r, g, b, a)
        fonts[text] = generation
    end
    local function Texts(f)
        if fonts[f] == generation then return end
        for _, region in ipairs(H.Regions(f)) do Font(region) end
        fonts[f] = generation
    end
    local function AssetKey(path)
        if type(path) == "string" then
            local key = path:lower():gsub("\\", "/"):match("([^/]+)$")
            return key and key:gsub("%.blp$", ""):gsub("%.tga$", "")
        end
    end
    local function Assets(f)
        local assets = chromeAssets[f]
        if assets then return assets end
        assets = {}; chromeAssets[f] = assets
        for _, slot in ipairs(chromeSlots[f:GetName()] or {}) do
            local path = imagePath .. f:GetName() .. "-" .. slot[1]
            assets[AssetKey(path)] = slot[1]
            if type(GetFileIDFromPath) == "function" then
                for _, file in ipairs({path, path .. ".blp"}) do
                    local id = GetFileIDFromPath(file)
                    if type(id) == "number" and id > 0 then assets[id] = slot[1] end
                end
            end
        end
        return assets
    end
    local function Near(a, b) return type(a) == "number" and math.abs(a - b) < 0.25 end
    local function Chrome(f, region)
        if not H.Texture(region) then return end
        if region:GetName() == "AtlasEJLootFrame_Back" then return "Backdrop" end
        local slots = chromeSlots[f:GetName()]
        if not slots then return end
        local path = region:GetTexture()
        local filePath = region.GetTextureFilePath and region:GetTextureFilePath()
        local assets = Assets(f)
        local key = AssetKey(filePath) or AssetKey(path)
        if key then return assets[key] end
        local id = region.GetTextureFileID and region:GetTextureFileID() or path
        if type(id) ~= "number" then return end
        if assets[id] then return assets[id] end
        local layer = region:GetDrawLayer()
        if (layer ~= "ARTWORK" and layer ~= "BORDER") or not region.GetPoint then return end
        local w, h = region:GetSize()
        local point, relative, relativePoint, x, y = region:GetPoint(1)
        if point ~= "TOPLEFT" or relativePoint ~= "TOPLEFT"
            or relative and relative ~= f and relative ~= f:GetName() then return end
        for _, slot in ipairs(slots) do
            if Near(w, slot[2]) and Near(h, slot[3]) and Near(x, slot[4]) and Near(y, slot[5]) then return slot[1] end
        end
    end
    local function Globe(f, d, texture)
        -- Resize the ORIGINAL composite's complete globe/rim crop. Creating a
        -- second globe before suppressing the original caused the duplication.
        d.globe = texture
        local height = f:GetName() == "AtlasFrameLarge" and 512 or 128
        texture:SetTexCoord(2 / 512, 74 / 512, 0, 72 / height)
        texture:ClearAllPoints(); texture:SetSize(35, 35)
        texture:SetPoint("TOPLEFT", f, "TOPLEFT", 7, -6)
        -- Keep the original round globe/rim recognizable inside a square slot.
        -- Do not add a circular mask: the slot follows the reference icon shape.
        d.logoSlot = f:CreateTexture(nil, "BACKGROUND", nil, -6)
        d.logoSlot:SetAllPoints(texture)
        local r, g, b = Color()
        d.logoSlot:SetColorTexture(r * 0.6, g * 0.6, b * 0.6, 1)
    end
    local function DiscoverChrome(f, d)
        local count = f.GetNumRegions and f:GetNumRegions()
        if count and count == d.regionCount and not d.pendingChrome then return end
        for _, region in ipairs(H.Regions(f)) do
            if region ~= d.fill and not d.chrome[region] then
                local part = Chrome(f, region)
                if part then
                    d.chrome[region], d.parts[part] = true, true
                    if part == "TopLeft" and not d.globe then Globe(f, d, region)
                    else H.Fade(region) end
                end
            end
        end
        local found = 0; for _ in pairs(d.parts) do found = found + 1 end
        local slots = chromeSlots[f:GetName()]
        d.pendingChrome = slots and found < #slots or false
        d.regionCount = f.GetNumRegions and f:GetNumRegions()
    end
    local function Gradient(texture, r1, g1, b1, r2, g2, b2)
        texture:SetColorTexture(1, 1, 1, 1)
        if texture.SetGradient and CreateColor then
            texture:SetGradient("HORIZONTAL", CreateColor(r1, g1, b1, 1), CreateColor(r2, g2, b2, 1))
        elseif texture.SetGradientAlpha then
            texture:SetGradientAlpha("HORIZONTAL", r1, g1, b1, 1, r2, g2, b2, 1)
        else texture:SetColorTexture(r1, g1, b1, 1) end
    end
    -- Two adjoining opaque halves form one cohesive surface. All art stays on
    -- the native root below map tiles/text; no raised information-panel fills.
    local function Surface(f)
        if not H.Allowed(f) then return end
        local d = surfaces[f]
        if not d then
            d = {chrome = {}, parts = {}}; surfaces[f] = d
            d.fill = f:CreateTexture(nil, "BACKGROUND", nil, -8)
            d.right = f:CreateTexture(nil, "BACKGROUND", nil, -8)
            d.fill:SetPoint("TOPLEFT", f, "TOPLEFT")
            d.fill:SetPoint("BOTTOMRIGHT", f, "BOTTOM")
            d.right:SetPoint("TOPLEFT", f, "TOP")
            d.right:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")
            if chromeSlots[f:GetName()] then
                d.header = f:CreateTexture(nil, "BACKGROUND", nil, -7)
                d.header:SetPoint("TOPLEFT", f, "TOPLEFT")
                d.header:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, -80)
                d.footer = f:CreateTexture(nil, "BACKGROUND", nil, -7)
                d.footer:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, 35)
                d.footer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")
                if f:GetName() == "AtlasFrame" then
                    d.separator = f:CreateTexture(nil, "BACKGROUND", nil, -6)
                    d.separator:SetPoint("TOPLEFT", f, "TOPLEFT", 540, -195)
                    d.separator:SetPoint("TOPRIGHT", f, "TOPRIGHT", -18, -195)
                    d.separator:SetHeight(1)
                    d.divider = f:CreateTexture(nil, "BACKGROUND", nil, -6)
                    d.divider:SetPoint("TOPLEFT", f, "TOPLEFT", 534, -84)
                    d.divider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 534, 35)
                    d.divider:SetWidth(1)
                end
            end
        end
        DiscoverChrome(f, d)
        if d.generation ~= generation then
            local r, g, b = Color()
            local cr, cg, cb = math.min(1, r + 0.045), math.min(1, g + 0.045), math.min(1, b + 0.04)
            Gradient(d.fill, r, g, b, cr, cg, cb)
            Gradient(d.right, cr, cg, cb, r, g, b)
            if d.header then
                d.header:SetColorTexture(r * 0.8, g * 0.8, b * 0.8, 1)
                d.footer:SetColorTexture(r * 0.8, g * 0.8, b * 0.8, 1)
            end
            if d.separator then
                d.separator:SetColorTexture(1, 1, 1, 0.10)
                d.divider:SetColorTexture(1, 1, 1, 0.08)
            end
            if d.logoSlot then d.logoSlot:SetColorTexture(r * 0.6, g * 0.6, b * 0.6, 1) end
            d.generation = generation
        end
        Texts(f)
    end
    local function InsetArt(texture, f, pads)
        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", f, "TOPLEFT", pads[1], -pads[3])
        texture:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -pads[2], pads[4])
    end
    -- Reuse the public primitive's fill/hover; do not stack another button.
    -- Atlas deliberately overlaps template bounds, so contain the paint and
    -- remove decorative borders on owned buttons only (borrowed widgets keep theirs).
    local function OwnedControl(f, apply, pads)
        local d = styled[f] or {}; styled[f] = d
        if d.control then return d.control end
        local before = {}; for _, r in ipairs(H.Regions(f)) do before[r] = true end
        flatControls[f] = true
        apply()
        local c = {fills = {}, hover = {}, pads = pads or {1, 1, 1, 1}}; d.control = c
        local painting = false
        local function Paint(force)
            if painting or not Ready() then return end
            local enabled = not f.IsEnabled or f:IsEnabled()
            if not force and c.generation == generation and c.enabled == enabled then return end
            painting = true
            local r, g, b = Color()
            local factor = enabled and 1 or 0.65
            for _, t in ipairs(c.fills) do
                t:SetColorTexture(math.min(1, r + 0.045) * factor,
                    math.min(1, g + 0.045) * factor, math.min(1, b + 0.045) * factor, 1)
            end
            for _, t in ipairs(c.hover) do t:SetAlpha(enabled and 1 or 0) end
            c.generation, c.enabled = generation, enabled
            if c.onState then c.onState(enabled) end
            painting = false
        end
        for _, t in ipairs(H.Regions(f)) do
            if not before[t] and H.Texture(t) then
                local layer = t:GetDrawLayer()
                if layer == "BACKGROUND" or layer == "HIGHLIGHT" then
                    local list = layer == "BACKGROUND" and c.fills or c.hover
                    list[#list + 1] = t; InsetArt(t, f, c.pads)
                    H.Hook(t, "SetAllPoints", function() if Ready() then InsetArt(t, f, c.pads) end end)
                    if layer == "BACKGROUND" then H.Hook(t, "SetColorTexture", function() Paint(true) end) end
                end
            end
        end
        c.Paint = Paint
        H.Script(f, "OnEnable", function() Paint() end)
        H.Script(f, "OnDisable", function() Paint() end)
        Paint()
        return c
    end
    local function Button(f, glyph, size)
        if not H.Allowed(f) then return end
        local d = styled[f] or {}; styled[f] = d
        if not d.button then
            d.button = true
            local options = (f:GetName() or ""):match("OptionsButton$")
            OwnedControl(f, function()
                if glyph then soft.SoftPageButton(f, glyph, size or 10)
                else soft.Button(f); if S.StateButtonLabel then S.StateButtonLabel(f) end end
            end, options and {1, 7, 1, 1} or nil)
            -- Native Options overlaps Lock by six pixels; keep both hit areas distinct.
            if options and f.SetHitRectInsets then f:SetHitRectInsets(0, 6, 0, 0) end
        end
        if d.control then d.control.Paint() end
        Texts(f)
    end
    local function IconButton(f)
        if not H.Allowed(f) then return end
        local d = styled[f] or {}; styled[f] = d
        if not d.button then
            d.button = true
            local keep = {}
            for index, region in ipairs(H.Regions(f)) do
                if H.Texture(region) then local key = "euiAtlasArt" .. index; f[key] = region; keep[#keep + 1] = key end
            end
            for index, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetHighlightTexture"}) do
                local region = f[getter] and f[getter](f)
                if region then local key = "euiAtlasState" .. index; f[key] = region; keep[#keep + 1] = key end
            end
            -- These are navigation/lock/role glyphs, not square item artwork.
            OwnedControl(f, function() soft.Button(f, keep) end)
        end
        if d.control then d.control.Paint() end
    end
    local function Dropdown(f)
        if not H.Allowed(f) then return end
        local d = styled[f] or {}; styled[f] = d
        local arrow = f.Button or _G[(f:GetName() or "") .. "Button"]
        if not H.Allowed(arrow) then return end
        if not d.dropdown then
            d.dropdown = true
            for _, key in ipairs({"Left", "Middle", "Right", "Background"}) do H.Fade(f[key]) end
            d.fill = f:CreateTexture(nil, "BACKGROUND", nil, -8)
            -- LibDD includes invisible label-frame padding; exclude it from the
            -- field hit area. Keep native arrow, text and optional child actions.
            InsetArt(d.fill, f, {16, 0, 1, 7})
            d.hover = f:CreateTexture(nil, "BACKGROUND", nil, -7); d.hover:SetAllPoints(d.fill)
            d.hover:SetColorTexture(1, 1, 1, 0.08); d.hover:SetAlpha(0)
            Button(arrow, "v", 10)
            d.Tone = function(enabled)
                local r, g, b = Color(); local factor = enabled and 1 or 0.65
                d.fill:SetColorTexture(math.min(1, r + 0.035) * factor,
                    math.min(1, g + 0.035) * factor, math.min(1, b + 0.035) * factor, 1)
                if not enabled then d.hover:SetAlpha(0) end
            end
            styled[arrow].control.onState = d.Tone
            f:EnableMouse(true)
            if f.SetHitRectInsets then f:SetHitRectInsets(16, 0, 1, 7) end
            H.Script(f, "OnMouseDown", function(_, mouse)
                if mouse ~= "LeftButton" or not Ready() or not H.Allowed(arrow)
                    or not arrow:IsEnabled() or not arrow:IsShown() then return end
                local handler = arrow.GetScript and arrow:GetScript("OnMouseDown")
                if handler then handler(arrow, mouse) end
            end)
            H.Script(f, "OnEnter", function()
                if Ready() and H.Allowed(arrow) and arrow:IsEnabled() then d.hover:SetAlpha(1) end
            end)
            H.Script(f, "OnLeave", function() d.hover:SetAlpha(0) end)
            H.Script(f, "OnHide", function() d.hover:SetAlpha(0) end)
            if ns.BindPopupOwner then ns.BindPopupOwner(S, module, f, menuOptions) end
        end
        if d.generation ~= generation then
            d.Tone(arrow:IsEnabled()); d.generation = generation
        end
        Button(arrow, "v", 10)
        Font(f.Label); Texts(f)
    end
    local function Scroll(f)
        if not H.Allowed(f) then return end
        local d = styled[f] or {}; styled[f] = d
        if d.scroll == generation then return end
        local thumb = f.GetThumbTexture and f:GetThumbTexture()
        if H.Texture(thumb) then
            if not d.scrollGrip then
                d.scrollGrip = f:CreateTexture(nil, "OVERLAY"); d.scrollGrip:SetSize(5, 22)
                d.scrollGrip:SetPoint("CENTER", thumb, "CENTER")
            end
            H.Fade(thumb); d.scrollGrip:SetColorTexture(S.GetAccentColor())
        end
        local name = f:GetName()
        Button(f.ScrollUpButton or name and _G[name .. "ScrollUpButton"], "^", 10)
        Button(f.ScrollDownButton or name and _G[name .. "ScrollDownButton"], "v", 10)
        H.LegacySlider(f, d.scrollGrip); d.scroll = generation
    end
    local function Entry(f)
        if not H.Allowed(f) then return end
        Font(f.Text or f.text)
        local d = styled[f] or {}; styled[f] = d
        if not d.entry then
            d.entry = true
            if H.Texture(f.Highlight) then f.Highlight:SetColorTexture(1, 1, 1, 0.08) end
        end
    end
    local function Entries()
        if not Ready() then return end
        -- Atlas reuses a fixed visible legend budget, not its full data list.
        for i = 1, (_G.ATLAS_NUM_LINES or 26) do Entry(_G["AtlasEntry" .. i]) end
    end
    local function Search(f)
        if not H.Allowed(f) then return end
        local d = styled[f] or {}; styled[f] = d
        if not d.search then
            d.search = true
            OwnedControl(f, function() soft.EditBox(f) end, {1, 1, 4, 4})
            -- A contained input edge provides focus feedback without an outer
            -- border crossing the immediately adjacent Search button.
            local edge = f:CreateTexture(nil, "BORDER"); edge:SetHeight(1)
            edge:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, 4)
            edge:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 4)
            d.edges = {edge}
            d.hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            S.Font(d.hint, 0.6, 0.6, 0.62)
            d.hint:SetPoint("LEFT", f, "LEFT", 7, 0)
            d.hint:SetText(_G.SEARCH or _G.ATLAS_STRING_SEARCH or "Search")
            local function Hint()
                if not Ready() then return end
                local show = (not f.GetText or f:GetText() == "") and not (f.HasFocus and f:HasFocus())
                if d.hint:IsShown() ~= show then
                    if show then d.hint:Show() else d.hint:Hide() end
                end
            end
            local function Focus()
                if not Ready() then return end
                local r, g, b = 0.25, 0.25, 0.27
                if f.HasFocus and f:HasFocus() then r, g, b = S.GetAccentColor() end
                for _, edge in ipairs(d.edges) do edge:SetColorTexture(r, g, b, 1) end
                Hint()
            end
            d.Focus = Focus
            H.Script(f, "OnEditFocusGained", Focus); H.Script(f, "OnEditFocusLost", Focus)
            H.Script(f, "OnTextChanged", Hint)
        end
        if d.searchGeneration ~= generation then
            S.Font(d.hint, 0.6, 0.6, 0.62)
            if f.SetTextColor then f:SetTextColor(0.92, 0.92, 0.94, 1) end
            d.control.Paint(); d.Focus(); d.searchGeneration = generation
        end
    end
    local roots = {"AtlasFrame", "AtlasFrameSmall", "AtlasFrameLarge"}
    local glyphs = {PrevMapButton = "<", NextMapButton = ">", SizeUpButton = "+", SizeDownButton = "-",
        CollapseButton = ">", ExpandButton = "<"}
    local icons = {"LFGButton", "AdventureJournalMapButton", "AdventureJournalButton", "AtlasLootButton"}
    local function Lock(f, redraw)
        if not H.Allowed(f) then return end
        local d = styled[f] or {}; styled[f] = d
        if not d.lock then
            d.lock = true
            f.euiAtlasNormal = f:GetNormalTexture(); f.euiAtlasPushed = f:GetPushedTexture()
            OwnedControl(f, function() soft.Button(f, {"euiAtlasNormal", "euiAtlasPushed"}) end, {6, 6, 8, 8})
            if f.SetHitRectInsets then f:SetHitRectInsets(6, 6, 0, 0) end
            for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture"}) do
                local t = f[getter](f)
                if H.Texture(t) then
                    t:ClearAllPoints(); t:SetSize(12, 16)
                    t:SetPoint("CENTER", f, "CENTER", getter == "GetPushedTexture" and 1 or 0, getter == "GetPushedTexture" and -1 or 0)
                    t:SetTexCoord(0, 1, 0, 1); t:SetVertexColor(0.9, 0.9, 0.9, 1)
                end
            end
        end
        local frames = A.db and A.db.profile and A.db.profile.options and A.db.profile.options.frames
        local locked = frames and frames.lock
        -- Atlas replaces these textures in UpdateLock; use those same state slots.
        if not d.iconDone or d.locked ~= locked or redraw then
            local path = "Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-lock-" .. (locked and "locked.png" or "unlocked.png")
            for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture"}) do
                local t = f[getter](f)
                if H.Texture(t) then t:SetTexture(path) end
            end
            d.iconDone, d.locked = true, locked
        end
        d.control.Paint()
    end
    local function Window(f)
        if not H.Allowed(f) then return end
        Surface(f)
        local name = f:GetName()
        local d = styled[f] or {}; styled[f] = d
        if not d.window then
            d.window = true
            H.Script(f, "OnShow", function() if Ready() then Window(f); Entries() end end)
        end
        local close = _G[name .. "CloseButton"]
        if H.Allowed(close) and not styled[close] then S.CloseButton(close); styled[close] = {} end
        Button(_G[name .. "OptionsButton"])
        Lock(_G[name .. "LockButton"])
        for suffix, glyph in pairs(glyphs) do Button(_G[name .. suffix], glyph) end
        for _, suffix in ipairs(icons) do IconButton(_G[name .. suffix]) end
        Dropdown(_G[name .. "DropDownType"]); Dropdown(_G[name .. "DropDown"])
        Font(f.ZoneName and f.ZoneName.Text)
    end
    local function LootRow(item)
        if not Ready() or not H.Allowed(item) then return end
        local d = styled[item] or {}; styled[item] = d
        if not d.loot then
            d.loot = true
            H.Fade(item.bossTexture); H.Fade(item.bosslessTexture)
        end
        -- Native quality, quest overlays, icon art and all loot actions survive.
        for _, key in ipairs({"name", "slot", "armorType", "boss"}) do Font(item[key]) end
    end
    local function Loot()
        local f = _G.AtlasEJLootFrame
        if not H.Allowed(f) or _G.ATLAS_HAS_EJ == false then return end
        Surface(f)
        local close = _G.AtlasEJLootFrameCloseButton
        if H.Allowed(close) and not styled[close] then S.CloseButton(close); styled[close] = {} end
        local scroll = f.lootScroll
        if not H.Allowed(scroll) then return end
        for _, key in ipairs({"filter", "slotFilter", "difficulty"}) do
            local button = scroll[key]
            if H.Allowed(button) then
                for _, side in ipairs({"UpLeft", "UpRight", "DownLeft", "DownRight", "HighLeft", "HighRight"}) do H.Fade(button[side]) end
                Button(button)
            end
        end
        for _, key in ipairs({"lootFilter", "lootSlotFilter", "difficultyDD"}) do
            local owner = scroll[key]
            if H.Allowed(owner) and ns.BindPopupOwner then ns.BindPopupOwner(S, module, owner, menuOptions) end
        end
        Scroll(scroll.scrollBar)
        for _, row in ipairs(scroll.buttons or {}) do LootRow(row) end
        local clear = scroll.classClearFilter
        if H.Allowed(clear) then Font(clear.text); Button(_G[clear:GetName() .. "ExitButton"], "x") end
    end
    -- AceConfig controls are borrowed. Add reusable, mouse-transparent art;
    -- restore only changed cosmetics on release and never touch FontObjects.
    local function Restore(record)
        if not record or not record.active then return end
        record.active = false
        for region, alpha in pairs(record.alpha) do if region:GetAlpha() == 0 then region:SetAlpha(alpha) end end
        for art in pairs(record.art) do art:SetAlpha(0) end
        for frame, backdrop in pairs(record.backdrops) do
            frame:SetBackdrop(backdrop.value)
            if backdrop.bg and frame.SetBackdropColor then frame:SetBackdropColor((unpack or table.unpack)(backdrop.bg)) end
            if backdrop.edge and frame.SetBackdropBorderColor then frame:SetBackdropBorderColor((unpack or table.unpack)(backdrop.edge)) end
        end
        record.alpha, record.backdrops, record.art = {}, {}, {}
    end
    local function RestoreWidget(widget)
        Restore(pooled[widget])
        for _, child in ipairs(widget.children or {}) do RestoreWidget(child) end
        for _, item in ipairs(widget.pullout and widget.pullout.items or {}) do RestoreWidget(item) end
    end
    local function Record(widget)
        local r = pooled[widget]
        if not r or not r.active then r = {active = true, alpha = {}, art = {}, backdrops = {}}; pooled[widget] = r end
        return r
    end
    local function Art(frame)
        local d = poolArt[frame]
        if not d then d = {}; poolArt[frame] = d end
        return d
    end
    local function Fade(record, frame, keep)
        local highlight = frame.GetHighlightTexture and frame:GetHighlightTexture()
        for _, region in ipairs(H.Regions(frame)) do
            if H.Texture(region) and not poolArt[region] and region ~= keep and region ~= highlight then
                if record.alpha[region] == nil then record.alpha[region] = region:GetAlpha() end
                if region:GetAlpha() ~= 0 then region:SetAlpha(0) end
            end
        end
        if frame.GetBackdrop and frame.SetBackdrop and not record.backdrops[frame] then
            local value = frame:GetBackdrop()
            if value then
                record.backdrops[frame] = {value = value,
                    bg = frame.GetBackdropColor and {frame:GetBackdropColor()},
                    edge = frame.GetBackdropBorderColor and {frame:GetBackdropBorderColor()}}
                frame:SetBackdrop(nil)
            end
        end
    end
    local function Fill(record, frame)
        local d = Art(frame)
        if not d.fill then
            d.fill = frame:CreateTexture(nil, "BACKGROUND", nil, -8); d.fill:SetAllPoints(frame); poolArt[d.fill] = true
        end
        if d.generation ~= generation then d.fill:SetColorTexture(Color()); d.generation = generation end
        if d.fill:GetAlpha() ~= 1 then d.fill:SetAlpha(1) end; record.art[d.fill] = true
    end
    local function BorrowedButton(record, frame, keep)
        Fade(record, frame, keep); Fill(record, frame)
        local highlight = frame.GetHighlightTexture and frame:GetHighlightTexture()
        if H.Texture(highlight) then
            if record.alpha[highlight] == nil then record.alpha[highlight] = highlight:GetAlpha() end
            if highlight:GetAlpha() ~= 0 then highlight:SetAlpha(0) end
        end
        local d = Art(frame)
        if not d.buttonHover then
            d.buttonHover = frame:CreateTexture(nil, "HIGHLIGHT"); d.buttonHover:SetAllPoints(frame)
            d.buttonHover:SetColorTexture(1, 1, 1, 0.08); poolArt[d.buttonHover] = true
        end
        if d.buttonHover:GetAlpha() ~= 1 then d.buttonHover:SetAlpha(1) end; record.art[d.buttonHover] = true
    end
    local function BorrowedArrow(widget, record, button, glyph)
        if not H.Allowed(button) then return end
        Fade(record, button)
        local d = Art(button)
        local function State()
            local active = pooled[widget]
            if not active or not active.active or not Ready() then return end
            local alpha = button:IsEnabled() and 1 or 0.5
            if d.arrow:GetAlpha() ~= alpha then d.arrow:SetAlpha(alpha) end
        end
        if not d.arrow then
            d.arrow = CreateFrame("Button", nil, button); d.arrow:SetAllPoints(button)
            soft.SoftPageButton(d.arrow, glyph, 10); d.arrow:EnableMouse(false)
            H.Script(button, "OnEnable", State); H.Script(button, "OnDisable", State)
        end
        State(); record.art[d.arrow] = true
    end
    local function SliderTone(widget, slider, record)
        local d = Art(slider)
        if not d.grip then return end
        if d.gripGeneration ~= generation or d.disabled ~= widget.disabled or d.record ~= record then
            local r, g, b = S.GetAccentColor()
            if widget.disabled then r, g, b = 0.4, 0.4, 0.4 end
            d.grip:SetColorTexture(r, g, b, 0.8)
            d.gripGeneration, d.disabled, d.record = generation, widget.disabled, record
        end
    end
    local function Slider(widget, record, slider)
        if not H.Allowed(slider) then return end
        local d = Art(slider)
        local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
        if not H.Texture(thumb) then return end
        if d.sliderRecord ~= record or d.sliderGeneration ~= generation then
            Fade(record, slider)
            if not d.track then
                d.track = slider:CreateTexture(nil, "BACKGROUND", nil, -7); poolArt[d.track] = true
                d.grip = slider:CreateTexture(nil, "OVERLAY"); poolArt[d.grip] = true
                local vertical = slider.GetOrientation and slider:GetOrientation() == "VERTICAL"
                if vertical then
                    d.track:SetPoint("TOP"); d.track:SetPoint("BOTTOM"); d.track:SetWidth(2)
                else
                    d.track:SetPoint("LEFT"); d.track:SetPoint("RIGHT"); d.track:SetHeight(2)
                end
                d.track:SetColorTexture(0.2, 0.2, 0.22, 1)
                d.grip:SetSize(vertical and 5 or 10, vertical and 22 or 14)
                d.grip:SetPoint("CENTER", thumb, "CENTER")
            end
            d.sliderRecord, d.sliderGeneration = record, generation
        end
        for _, art in ipairs({d.track, d.grip}) do
            if art:GetAlpha() ~= 1 then art:SetAlpha(1) end; record.art[art] = true
        end
        if d.arrowRecord ~= record then
            local name = slider:GetName()
            BorrowedArrow(widget, record, slider.ScrollUpButton or name and _G[name .. "ScrollUpButton"], "^")
            BorrowedArrow(widget, record, slider.ScrollDownButton or name and _G[name .. "ScrollDownButton"], "v")
            d.arrowRecord = record
        end
        SliderTone(widget, slider, record)
    end
    local function TreeRows(widget, record)
        for _, button in ipairs(widget.buttons or {}) do
            if H.Allowed(button) and button:IsShown() then
                local d = Art(button)
                if not d.selected then
                    d.selected = button:CreateTexture(nil, "BACKGROUND"); d.selected:SetAllPoints(button)
                    d.hover = button:CreateTexture(nil, "HIGHLIGHT"); d.hover:SetAllPoints(button)
                    poolArt[d.selected], poolArt[d.hover] = true, true
                end
                local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
                if H.Texture(highlight) then
                    if record.alpha[highlight] == nil then record.alpha[highlight] = highlight:GetAlpha() end
                    if highlight:GetAlpha() ~= 0 then highlight:SetAlpha(0) end
                end
                if d.treeGeneration ~= generation then
                    local r, g, b = S.GetAccentColor()
                    d.selected:SetColorTexture(r, g, b, 0.12); d.hover:SetColorTexture(r, g, b, 0.08)
                    d.treeGeneration = generation
                end
                local selectedAlpha = button.selected and 1 or 0
                if d.selected:GetAlpha() ~= selectedAlpha then d.selected:SetAlpha(selectedAlpha) end
                if d.hover:GetAlpha() ~= 1 then d.hover:SetAlpha(1) end
                record.art[d.selected], record.art[d.hover] = true, true
            end
        end
    end
    local function Check(widget, record)
        local frame = widget.frame
        local bg, check = widget.checkbg or widget.check, widget.check
        if not H.Texture(bg) or not H.Texture(check) then return end
        for _, region in ipairs({bg, check, widget.highlight}) do
            if record.alpha[region] == nil then record.alpha[region] = region:GetAlpha() end
            if region:GetAlpha() ~= 0 then region:SetAlpha(0) end
        end
        local d = Art(frame)
        if not d.box then
            d.box = frame:CreateTexture(nil, "ARTWORK"); d.box:SetSize(14, 14); d.box:SetPoint("CENTER", bg, "CENTER")
            d.box:SetColorTexture(0.05, 0.05, 0.06, 1); poolArt[d.box] = true
            d.mark = frame:CreateTexture(nil, "OVERLAY"); d.mark:SetSize(8, 8); d.mark:SetPoint("CENTER", bg, "CENTER"); poolArt[d.mark] = true
            d.checkHover = frame:CreateTexture(nil, "HIGHLIGHT"); d.checkHover:SetSize(14, 14)
            d.checkHover:SetPoint("CENTER", bg, "CENTER"); d.checkHover:SetColorTexture(1, 1, 1, 0.08); poolArt[d.checkHover] = true
        end
        if d.box:GetAlpha() ~= 1 then d.box:SetAlpha(1) end
        local hoverAlpha = widget.disabled and 0 or 1
        if d.checkHover:GetAlpha() ~= hoverAlpha then d.checkHover:SetAlpha(hoverAlpha) end
        local checked = widget.checked
        if widget.type == "Dropdown-Item-Toggle" then checked = widget.value end
        if checked == nil then checked = check:IsShown() end
        if d.checkGeneration ~= generation or d.disabled ~= widget.disabled or d.record ~= record then
            local r, g, b = S.GetAccentColor()
            if widget.disabled then r, g, b = 0.4, 0.4, 0.4 end
            d.mark:SetColorTexture(r, g, b, 1)
            d.checkGeneration, d.disabled, d.record = generation, widget.disabled, record
        end
        local alpha = checked and 1 or 0
        if d.mark:GetAlpha() ~= alpha then d.mark:SetAlpha(alpha) end
        record.art[d.box], record.art[d.mark], record.art[d.checkHover] = true, true, true
    end
    local function MenuItem(widget, record)
        local highlight = widget.highlight
        if H.Texture(highlight) then
            if record.alpha[highlight] == nil then record.alpha[highlight] = highlight:GetAlpha() end
            if highlight:GetAlpha() ~= 0 then highlight:SetAlpha(0) end
        end
        local d = Art(widget.frame)
        if not d.menuHover then
            d.menuHover = widget.frame:CreateTexture(nil, "HIGHLIGHT"); d.menuHover:SetAllPoints(widget.frame)
            d.menuHover:SetColorTexture(1, 1, 1, 0.08); poolArt[d.menuHover] = true
        end
        local alpha = (widget.disabled or widget.useHighlight == false) and 0 or 1
        if d.menuHover:GetAlpha() ~= alpha then d.menuHover:SetAlpha(alpha) end; record.art[d.menuHover] = true
        if widget.type == "Dropdown-Item-Toggle" then Check(widget, record) end
    end
    local function WidgetState(widget)
        local record = pooled[widget]
        if record and record.active and Ready() then
            if (widget.type or ""):match("^Dropdown%-Item%-") then MenuItem(widget, record)
            elseif widget.checkbg and widget.check then Check(widget, record)
            elseif H.Allowed(widget.slider) then SliderTone(widget, widget.slider, record) end
        end
    end
    PaintWidget = function(widget)
        if type(widget) ~= "table" or not H.Allowed(widget.frame) or not Ready() then return end
        local record = Record(widget)
        local frame, kind = widget.frame, widget.type or ""
        if record.generation == generation then
            WidgetState(widget)
            if kind == "TreeGroup" then TreeRows(widget, record) end
            for _, child in ipairs(widget.children or {}) do PaintWidget(child) end
            return
        end
        record.generation = generation
        if kind:match("^Dropdown%-Item%-") then
            MenuItem(widget, record)
            for _, method in ipairs({"SetValue", "SetDisabled"}) do H.Hook(widget, method, function() WidgetState(widget) end) end
            H.Script(frame, "OnClick", function() WidgetState(widget) end)
        elseif widget.checkbg and widget.check then
            Check(widget, record)
            for _, method in ipairs({"SetValue", "SetDisabled", "SetType"}) do H.Hook(widget, method, function() WidgetState(widget) end) end
        elseif kind == "Button" or kind == "Execute" then
            local button = H.Allowed(widget.button) and widget.button or frame
            BorrowedButton(record, button, widget.image)
        elseif kind == "Dropdown" then
            local box = H.Allowed(widget.dropdown) and widget.dropdown or frame
            Fade(record, box); Fill(record, box)
            BorrowedArrow(widget, record, widget.button, "v")
            local pullout = widget.pullout
            if pullout and H.Allowed(pullout.frame) then
                H.Hook(pullout, "Open", function()
                    local active = pooled[widget]
                    if not active or not active.active or not Ready() then return end
                    Fade(active, pullout.frame); Fill(active, pullout.frame)
                    for _, item in ipairs(pullout.items or {}) do PaintWidget(item) end
                end)
            end
        elseif kind == "EditBox" or kind == "MultiLineEditBox" then
            local edit = widget.editbox
            if H.Allowed(edit) then Fade(record, edit); Fill(record, edit) end
        elseif kind == "Slider" and H.Allowed(widget.slider) then
            Slider(widget, record, widget.slider)
            H.Hook(widget, "SetDisabled", function() WidgetState(widget) end)
            if H.Allowed(widget.editbox) then Fade(record, widget.editbox); Fill(record, widget.editbox) end
        elseif kind == "Frame" or kind == "BlizOptionsGroup" or kind == "InlineGroup" or kind == "TabGroup" or kind == "TreeGroup" then
            Fade(record, frame); Fill(record, frame)
            -- AceGUI's visible outlines are owned child backdrops, not regions
            -- of the wrapper. Touch only these documented container fields.
            for _, key in ipairs({"border", "treeframe"}) do
                if H.Allowed(widget[key]) then Fade(record, widget[key]); Fill(record, widget[key]) end
            end
            if (kind == "InlineGroup" or kind == "TabGroup") and H.Allowed(widget.content) then
                local border = widget.content:GetParent()
                if H.Allowed(border) and border ~= frame then Fade(record, border); Fill(record, border) end
            end
            if kind == "Frame" then
                for _, child in ipairs(H.Children(frame)) do
                    if H.Allowed(child) and child.obj == widget then
                        if child:GetObjectType() == "Button" then BorrowedButton(record, child)
                        elseif child:GetObjectType() == "Frame" and child.GetBackdrop and child:GetBackdrop() then
                            Fade(record, child); Fill(record, child)
                        end
                    end
                end
            end
            if kind == "TreeGroup" then
                Slider(widget, record, widget.scrollbar); TreeRows(widget, record)
                H.Hook(widget, "RefreshTree", function()
                    local active = pooled[widget]
                    if active and active.active and Ready() then TreeRows(widget, active) end
                end)
            end
        end
        -- Native fonts/colours on pooled Settings inputs and labels are kept.
        for _, child in ipairs(widget.children or {}) do PaintWidget(child) end
    end
    local libraryHooks = {}
    local function HookLibrary(object, key, callback)
        if type(object) ~= "table" or type(object[key]) ~= "function" then return end
        local h = libraryHooks[object] or {}; libraryHooks[object] = h
        if h[key] == object[key] then return end
        hooksecurefunc(object, key, callback); h[key] = object[key]
    end
    local function OptionID(id) return id == (A.LocName or "Atlas") end
    Options = function()
        local dialog, gui = Library("AceConfigDialog-3.0"), Library("AceGUI-3.0")
        HookLibrary(gui, "Release", function(_, widget)
            if type(widget) == "table" then RestoreWidget(widget); groups[widget] = nil end
        end)
        HookLibrary(dialog, "FeedGroup", function(_, id, _, container)
            if OptionID(id) then if Ready() then PaintWidget(container) end
            elseif groups[container] then RestoreWidget(container); groups[container] = nil end
            if OptionID(id) then groups[container] = true end
        end)
        for _, widget in pairs(A.optionsFrames or {}) do
            local frame = widget.frame
            if H.Allowed(frame) then
                groups[widget] = true
                H.Script(frame, "OnShow", function() if groups[widget] and Ready() then PaintWidget(widget) end end)
                if frame:IsShown() then PaintWidget(widget); groups[widget] = true end
            end
        end
        if dialog then
            local open = dialog.OpenFrames and dialog.OpenFrames[A.LocName or "Atlas"]
            if open and Ready() then PaintWidget(open); groups[open] = true end
        end
    end
    local function Bind()
        H.Hook(A, "UpdateLock", function() if Ready() then for _, name in ipairs(roots) do Lock(_G[name .. "LockButton"], true) end end end)
        H.Hook(A, "ScrollBar_Update", Entries)
        H.Hook(A, "RefreshMap", function() if Ready() then Entries(); Loot() end end)
        H.Hook(A, "ToggleWindowSize", function() if Ready() then for _, name in ipairs(roots) do Window(_G[name]) end end end)
        H.Hook(A, "ToggleLegendPanel", function() if Ready() then for _, name in ipairs(roots) do Window(_G[name]) end end end)
        H.Hook(A, "OpenOptions", function() if Ready() then Options() end end)
        H.Hook(A, "SetupOptions", function() if Ready() then Options() end end)
        H.Hook(A, "RegisterModuleOptions", function() if Ready() then Options() end end)
        H.Hook(_G, "Atlas_EncounterJournal_SetLootButton", LootRow)
        H.Hook(_G, "Atlas_EncounterJournal_DisplayLoot", function() if Ready() then Loot() end end)
    end
    Apply = function()
        if not ns.IsEnabled(module) then for _, record in pairs(pooled) do Restore(record) end; return end
        if not Ready() or applying then return end
        applying = true
        Bind()
        for _, name in ipairs(roots) do Window(_G[name]) end
        local main = _G.AtlasFrame
        if main then
            for _, suffix in ipairs({"ZoneName", "Location", "LevelRange", "RecommendedRange", "MinLevel", "PlayerLimit", "MinGearLevel"}) do
                local f = _G["AtlasText_" .. suffix]; if H.Allowed(f) then Texts(f) end
            end
            local search = _G.AtlasSearchEditBox
            Search(search)
            for _, name in ipairs({"AtlasSearchButton", "AtlasSearchClearButton", "AtlasSwitchButton"}) do Button(_G[name]) end
            Scroll(_G.AtlasScrollBarScrollBar)
            if ns.BindPopupOwner and _G.AtlasSwitchDD then ns.BindPopupOwner(S, module, _G.AtlasSwitchDD, menuOptions) end
        end
        Entries(); Loot(); Options()
        local world = A.WorldMap and A.WorldMap.Button
        if H.Allowed(world) then H.Fade(world.Background); H.Fade(world.Border); IconButton(world) end
        soft.RefreshSoftBorders()
        applying = false
    end
    events:SetScript("OnEvent", function(_, event)
        if event ~= "PLAYER_REGEN_ENABLED" or waiting then H.Safe(Apply) end
    end)
    if S.OnLooksChanged then S.OnLooksChanged(function() generation = generation + 1; H.Safe(Apply) end) end
    module.refresh = function() H.Safe(Apply) end
    H.Safe(Apply)
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Atlas", DefineSkin) else DefineSkin() end
