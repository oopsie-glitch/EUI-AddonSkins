local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("Atlas", "Atlas", function() return type(_G.Atlas) == "table" end, function(S, module)
    local A = _G.Atlas
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(S, module)
    local styled, fonts, surfaces, pooled, poolArt, groups = {}, {}, {}, {}, {}, {}
    local generation, waiting, applying = 1, false, false
    local Apply, Options, PaintWidget
    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED"); events:RegisterEvent("PLAYER_REGEN_ENABLED")
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
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
        for _, region in ipairs(H.Regions(f)) do Font(region) end
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
                local path = region.GetTexture and region:GetTexture()
                local name = region.GetName and region:GetName()
                if type(path) == "string" and path:lower():match("atlas[/\\]images[/\\]atlasframe")
                    or name == "AtlasEJLootFrame_Back" then H.Fade(region) end
            end
        end
        if d.generation ~= generation then d.fill:SetColorTexture(Color()); d.generation = generation end
        Texts(f)
    end
    local function Button(f, glyph)
        if not H.Allowed(f) then return end
        local d = styled[f] or {}; styled[f] = d
        if not d.button then
            d.button = true
            if glyph then soft.SoftPageButton(f, glyph)
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
            d.dropdown = true; soft.Dropdown(f)
            if ns.BindPopupOwner then ns.BindPopupOwner(S, module, f) end
        end
        Font(f.Label); Texts(f)
    end
    local function Scroll(f)
        if not H.Allowed(f) then return end
        local d = styled[f] or {}; styled[f] = d
        if d.scroll == generation then return end
        H.LegacySlider(f); d.scroll = generation
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
    local icons = {"LockButton", "LFGButton", "AdventureJournalMapButton", "AdventureJournalButton", "AtlasLootButton"}
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
            if H.Allowed(owner) and ns.BindPopupOwner then ns.BindPopupOwner(S, module, owner) end
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
    local function Check(widget, record)
        local frame = widget.frame
        local bg, check = widget.checkbg, widget.check
        if not H.Texture(bg) or not H.Texture(check) then return end
        for _, region in ipairs({bg, check}) do
            if record.alpha[region] == nil then record.alpha[region] = region:GetAlpha() end
            if region:GetAlpha() ~= 0 then region:SetAlpha(0) end
        end
        local d = Art(frame)
        if not d.box then
            d.box = frame:CreateTexture(nil, "ARTWORK"); d.box:SetSize(14, 14); d.box:SetPoint("CENTER", bg, "CENTER")
            d.box:SetColorTexture(0.05, 0.05, 0.06, 1); poolArt[d.box] = true
            d.mark = frame:CreateTexture(nil, "OVERLAY"); d.mark:SetSize(8, 8); d.mark:SetPoint("CENTER", bg, "CENTER"); poolArt[d.mark] = true
        end
        if d.box:GetAlpha() ~= 1 then d.box:SetAlpha(1) end
        local checked = widget.checked
        if checked == nil then checked = check:IsShown() end
        if d.checkGeneration ~= generation or d.disabled ~= widget.disabled or d.record ~= record then
            local r, g, b = S.GetAccentColor()
            if widget.disabled then r, g, b = 0.4, 0.4, 0.4 end
            d.mark:SetColorTexture(r, g, b, 1)
            d.checkGeneration, d.disabled, d.record = generation, widget.disabled, record
        end
        local alpha = checked and 1 or 0
        if d.mark:GetAlpha() ~= alpha then d.mark:SetAlpha(alpha) end
        record.art[d.box], record.art[d.mark] = true, true
    end
    local function WidgetState(widget)
        local record = pooled[widget]
        if record and record.active and Ready() then Check(widget, record) end
    end
    PaintWidget = function(widget)
        if type(widget) ~= "table" or not H.Allowed(widget.frame) or not Ready() then return end
        local record = Record(widget)
        local frame, kind = widget.frame, widget.type or ""
        if widget.checkbg and widget.check then
            Check(widget, record)
            for _, method in ipairs({"SetValue", "SetDisabled", "SetType"}) do H.Hook(widget, method, function() WidgetState(widget) end) end
        elseif kind == "Button" or kind == "Execute" then
            local button = H.Allowed(widget.button) and widget.button or frame
            Fade(record, button, widget.image); Fill(record, button)
        elseif kind == "Dropdown" then
            local box = H.Allowed(widget.dropdown) and widget.dropdown or frame
            Fade(record, box); Fill(record, box)
            if H.Allowed(widget.button) then
                Fade(record, widget.button)
                local d = Art(widget.button)
                if not d.arrow then
                    d.arrow = CreateFrame("Frame", nil, widget.button); d.arrow:SetAllPoints(widget.button)
                    soft.SoftPageButton(d.arrow, "v"); d.arrow:EnableMouse(false)
                end
                if d.arrow:GetAlpha() ~= 1 then d.arrow:SetAlpha(1) end; record.art[d.arrow] = true
            end
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
            local slider = widget.slider
            local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
            Fade(record, slider); Fill(record, slider)
            if H.Texture(thumb) then
                local d = Art(slider)
                if not d.grip then
                    d.grip = slider:CreateTexture(nil, "OVERLAY"); d.grip:SetSize(6, 14)
                    d.grip:SetPoint("CENTER", thumb, "CENTER"); poolArt[d.grip] = true
                end
                if d.gripGeneration ~= generation then d.grip:SetColorTexture(S.GetAccentColor()); d.gripGeneration = generation end
                if d.grip:GetAlpha() ~= 1 then d.grip:SetAlpha(1) end; record.art[d.grip] = true
            end
            if H.Allowed(widget.editbox) then Fade(record, widget.editbox); Fill(record, widget.editbox) end
        elseif kind == "Frame" or kind == "BlizOptionsGroup" or kind == "InlineGroup" or kind == "TabGroup" then
            Fade(record, frame); Fill(record, frame)
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
            if ns.BindPopupOwner and _G.AtlasSwitchDD then ns.BindPopupOwner(S, module, _G.AtlasSwitchDD) end
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
