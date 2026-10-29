local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("Atlas", "Atlas", function() return type(_G.Atlas) == "table" end, function(S, module)
    local A = _G.Atlas
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(S, module)
    local styled, fonts, surfaces, pooled, poolArt, groups = {}, {}, {}, {}, {}, {}
    local generation, waiting, applying = 1, false, false
    local Apply, Options, PaintWidget
    local menuOptions = {noAccent = true, chevrons = true, compactChecks = true, hoverAlpha = 0.08}
    local imagePath = "Interface\\AddOns\\Atlas\\Images\\"
    -- Anonymous CreateArt regions can report file IDs instead of paths. Match
    -- only the inspected root chrome's layer, dimensions and anchor as fallback.
    local chromeSlots = {
        AtlasFrame = {{512,128,0,0}, {512,512,0,-128}, {512,128,512,0}, {512,512,512,-128}},
        AtlasFrameSmall = {{512,128,0,0}, {512,512,0,-128}, {32,128,512,0}, {32,512,512,-128}},
        AtlasFrameLarge = {{512,512,0,0}, {512,512,512,0}, {512,256,0,-512}, {512,256,512,-512},
            {512,32,0,-768}, {512,32,512,-768}},
    }
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
    local function Chrome(f, region)
        if not H.Texture(region) then return end
        local path = region:GetTexture()
        if type(path) == "string" and path:lower():match("atlas[/\\]images[/\\]atlasframe") then return true end
        if region:GetName() == "AtlasEJLootFrame_Back" then return true end
        if type(path) ~= "number" or region:GetDrawLayer() ~= "ARTWORK" or not region.GetPoint then return end
        local w, h = region:GetSize()
        local point, relative, relativePoint, x, y = region:GetPoint(1)
        if point ~= "TOPLEFT" or relative ~= f or relativePoint ~= "TOPLEFT" then return end
        for _, slot in ipairs(chromeSlots[f:GetName()] or {}) do
            if w == slot[1] and h == slot[2] and x == slot[3] and y == slot[4] then return true end
        end
    end
    -- Same-frame fill sits below both copies of the large map tile grid.
    -- Never pass a map root through a blanket texture-strip/shell operation.
    local function Surface(f)
        if not H.Allowed(f) then return end
        local d = surfaces[f]
        if not d then
            d = {}; surfaces[f] = d
            d.fill = f:CreateTexture(nil, "BACKGROUND", nil, -8); d.fill:SetAllPoints(f)
            for _, region in ipairs(H.Regions(f)) do
                if Chrome(f, region) then H.Fade(region) end
            end
            if chromeSlots[f:GetName()] then
                d.header = f:CreateTexture(nil, "BACKGROUND", nil, -7)
                d.header:SetPoint("TOPLEFT", 1, -1); d.header:SetPoint("TOPRIGHT", -1, -1); d.header:SetHeight(80)
                d.toolbar = f:CreateTexture(nil, "BACKGROUND", nil, -7)
                d.toolbar:SetPoint("BOTTOMLEFT", 1, 1); d.toolbar:SetPoint("BOTTOMRIGHT", -1, 1); d.toolbar:SetHeight(32)
                if f:GetName() == "AtlasFrame" then
                    d.info = f:CreateTexture(nil, "BACKGROUND", nil, -7)
                    d.info:SetPoint("TOPLEFT", f, "TOPLEFT", 538, -82)
                    d.info:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -18, -197)
                    d.legend = f:CreateTexture(nil, "BACKGROUND", nil, -7)
                    d.legend:SetPoint("TOPLEFT", f, "TOPLEFT", 538, -201)
                    d.legend:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 36)
                end
                -- The original globe is baked into TopLeft, not a button.
                -- Reuse that asset's globe crop; never resize the root/hit area.
                d.globe = f:CreateTexture(nil, "ARTWORK")
                d.globe:SetTexture(imagePath .. f:GetName() .. "-TopLeft")
                local textureHeight = f:GetName() == "AtlasFrameLarge" and 512 or 128
                d.globe:SetTexCoord(4 / 512, 72 / 512, 0, 70 / textureHeight)
                d.globe:SetSize(32, 32); d.globe:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -9)
                if f.CreateMaskTexture and d.globe.AddMaskTexture then
                    d.globeMask = f:CreateMaskTexture(nil, "ARTWORK")
                    d.globeMask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                    d.globeMask:SetAllPoints(d.globe); d.globe:AddMaskTexture(d.globeMask)
                end
            end
        end
        if d.generation ~= generation then
            local r, g, b, a = Color()
            d.fill:SetColorTexture(r, g, b, a)
            if d.header then d.header:SetColorTexture(r * 0.8, g * 0.8, b * 0.8, a) end
            if d.toolbar then d.toolbar:SetColorTexture(r * 0.7, g * 0.7, b * 0.7, a) end
            if d.info then d.info:SetColorTexture(r * 1.12, g * 1.12, b * 1.12, a) end
            if d.legend then d.legend:SetColorTexture(r * 0.9, g * 0.9, b * 0.9, a) end
            d.generation = generation
        end
        Texts(f)
    end
    local function Button(f, glyph, size)
        if not H.Allowed(f) then return end
        local d = styled[f] or {}; styled[f] = d
        if not d.button then
            d.button = true
            if glyph then soft.SoftPageButton(f, glyph, size or 10)
            else soft.Button(f); if S.StateButtonLabel then S.StateButtonLabel(f) end end
        end
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
            soft.Button(f, keep)
        end
    end
    local function Dropdown(f)
        if not H.Allowed(f) then return end
        local d = styled[f] or {}; styled[f] = d
        if not d.dropdown then
            d.dropdown = true
            for _, key in ipairs({"Left", "Middle", "Right", "Background"}) do H.Fade(f[key]) end
            -- EUI Dropdown adds a decorative arrow on the root. LibDD already
            -- has its own clickable child: style that child instead of both.
            d.fill = f:CreateTexture(nil, "BACKGROUND", nil, -8); d.fill:SetAllPoints(f)
            Button(f.Button or _G[(f:GetName() or "") .. "Button"], "v", 10)
            if ns.BindPopupOwner then ns.BindPopupOwner(S, module, f, menuOptions) end
        end
        if d.generation ~= generation then d.fill:SetColorTexture(Color()); d.generation = generation end
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
    local roots = {"AtlasFrame", "AtlasFrameSmall", "AtlasFrameLarge"}
    local glyphs = {PrevMapButton = "<", NextMapButton = ">", SizeUpButton = "+", SizeDownButton = "-",
        CollapseButton = ">", ExpandButton = "<"}
    local icons = {"LFGButton", "AdventureJournalMapButton", "AdventureJournalButton", "AtlasLootButton"}
    local function Lock(f)
        if not H.Allowed(f) then return end
        IconButton(f)
        local d = styled[f]
        if d.lockTone then return end
        for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture"}) do
            local texture = f[getter] and f[getter](f)
            if H.Texture(texture) then
                -- Keep the native open/closed padlock silhouettes and state
                -- updates; desaturate the red/yellow decorative plate only.
                if texture.SetDesaturated then texture:SetDesaturated(true) end
                texture:SetVertexColor(0.78, 0.78, 0.8, 1)
            end
        end
        d.lockTone = true
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
            if H.Allowed(search) and not styled[search] then soft.EditBox(search); styled[search] = {} end
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
