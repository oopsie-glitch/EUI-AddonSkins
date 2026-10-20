local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("Scrap", "Scrap", function() return type(_G.Scrap) == "table" end, function(S, module)
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(soft, module)
    local unpack = unpack or table.unpack
    local app = _G.Scrap
    local records, groups, rows, merchantPaints, visualizers = {}, {}, {}, {}, {}
    local generation, waiting, applying = 1, false, false
    local Refresh, PaintGroup, PaintControl
    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED"); events:RegisterEvent("PLAYER_REGEN_ENABLED")
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
        return true
    end
    local function Font(text, shade, heading)
        if not H.Allowed(text) or not text.GetFont then return end
        local kind = text:GetObjectType()
        if kind ~= "FontString" and kind ~= "EditBox" then return end
        local face, size, flags = text:GetFont()
        if not face then return end
        local target, targetFlags = S.GetFont()
        if face ~= target or (flags or "") ~= (targetFlags or "") then
            local r, g, b, a = text:GetTextColor()
            S.Font(text); text:SetTextColor(r, g, b, a)
        end
        if heading then text:SetTextColor(S.GetAccentColor())
        elseif shade then text:SetTextColor(shade, shade, shade, 1) end
    end
    -- Snapshot only this acquired widget and its explicitly owned decoration.
    -- No recursive scans of pooled frame hierarchies or global Sushi factories.
    local function RegionState(region)
        local state = {alpha = region:GetAlpha()}
        if region.GetFont and region:GetFont() then
            state.font, state.color = {region:GetFont()}, {region:GetTextColor()}
            state.fontObject = region.GetFontObject and region:GetFontObject()
        end
        if H.Texture(region) then
            state.texture = region:GetTexture()
            state.atlas = region.GetAtlas and region:GetAtlas()
            state.vertex = region.GetVertexColor and {region:GetVertexColor()}
            state.coords = region.GetTexCoord and {region:GetTexCoord()}
            state.size = {region:GetWidth(), region:GetHeight()}
        end
        if region.GetNumPoints then
            state.points = {}; for i = 1, region:GetNumPoints() do state.points[i] = {region:GetPoint(i)} end
        end
        return state
    end
    local function RestoreRegion(region, state)
        region:SetAlpha(state.alpha)
        if state.font then
            if state.fontObject and region.SetFontObject then region:SetFontObject(state.fontObject) end
            region:SetFont(unpack(state.font)); region:SetTextColor(unpack(state.color))
        end
        if H.Texture(region) then
            if state.atlas and region.SetAtlas then region:SetAtlas(state.atlas) else region:SetTexture(state.texture) end
            if state.vertex then region:SetVertexColor(unpack(state.vertex)) end
            if state.coords then region:SetTexCoord(unpack(state.coords)) end
            region:SetSize(unpack(state.size))
        end
        if state.points then
            region:ClearAllPoints(); for _, point in ipairs(state.points) do region:SetPoint(unpack(point)) end
        end
    end
    local function Capture(record, frame)
        if not H.Allowed(frame) or record.saved[frame] then return end
        local saved = {regions = {}}; record.saved[frame] = saved
        if not frame.Children and frame.GetBackdrop then
            saved.backdrop, saved.hasBackdrop = frame:GetBackdrop(), true
            if frame.GetBackdropColor then saved.bg = {frame:GetBackdropColor()} end
            if frame.GetBackdropBorderColor then saved.edge = {frame:GetBackdropBorderColor()} end
        end
        if frame:GetObjectType() == "EditBox" then saved.font = RegionState(frame) end
        for _, region in ipairs(H.Regions(frame)) do
            if not record.art[region] then saved.regions[region] = RegionState(region) end
        end
    end
    local function Restore(record)
        if not record.active then return end
        record.active = false -- Setter callbacks must not repaint during cleanup.
        local decoration = record.decoration
        if decoration and decoration.label:GetText() == decoration.cleaned then
            decoration.label:SetText(decoration.original)
        end
        record.decoration = nil
        for frame, saved in pairs(record.saved) do
            if saved.hasBackdrop then
                frame:SetBackdrop(saved.backdrop)
                if saved.bg then frame:SetBackdropColor(unpack(saved.bg)) end
                if saved.edge then frame:SetBackdropBorderColor(unpack(saved.edge)) end
            end
            if saved.font then RestoreRegion(frame, saved.font) end
            for region, state in pairs(saved.regions) do RestoreRegion(region, state) end
        end
        for art in pairs(record.art) do art:SetAlpha(0) end
        record.saved = {}
    end
    local function Record(frame)
        local record = records[frame]
        if not record then record = {saved = {}, art = {}, frame = frame}; records[frame] = record end
        -- Sushi clears its callback table on acquisition. Bind once to each new
        -- table so cleanup runs at OnReset, before native defaults are applied.
        if frame.SetCall and record.calls ~= frame.calls then
            record.calls = frame.calls
            frame:SetCall("OnReset", function() Restore(record) end)
        end
        if not record.active then record.active, record.saved = true, {} end
        return record
    end
    local function Art(record, key, host, layer)
        local texture = record[key]
        if not texture then
            texture = host:CreateTexture(nil, layer or "BACKGROUND", nil, -6)
            record[key], record.art[texture] = texture, true
        end
        -- A Sushi popup can acquire a different background from its frame pool.
        -- Keep our cached art on the current host, including after reuse.
        if texture.GetParent and texture.SetParent and texture:GetParent() ~= host then texture:SetParent(host) end
        texture:SetAlpha(1)
        return texture
    end
    local function Decoration(frame, record, depth)
        if not H.Allowed(frame) or (depth or 0) > 3 then return end
        Capture(record, frame)
        for _, region in ipairs(H.Regions(frame)) do
            if H.Texture(region) and not record.art[region] then region:SetAlpha(0) end
        end
        -- TooltipBackdropTemplate can draw its border inside a NineSlice child.
        -- Snapshot these native pieces; permanent fade hooks would leak into
        -- another addon's next acquisition of this background.
        for _, child in ipairs(H.Children(frame)) do Decoration(child, record, (depth or 0) + 1) end
    end
    local function Panel(frame, record)
        Capture(record, frame)
        local fill = Art(record, "fill", frame)
        fill:SetAllPoints(frame)
        if frame.SetBackdrop then frame:SetBackdrop(nil) end
        for _, region in ipairs(H.Regions(frame)) do
            if H.Texture(region) and not record.art[region] then region:SetAlpha(0) end
        end
        local r, g, b = S.GetPanelColor(); fill:SetColorTexture(r, g, b, 0.98)
    end
    local function Label(frame, record)
        if not record.active or not Ready() or record.labelBusy then return end
        record.labelBusy = true
        local shade = frame.isTitle and 0.92 or (frame.IsEnabled and not frame:IsEnabled() and 0.5 or 0.92)
        local label = frame.Label or frame.GetFontString and frame:GetFontString()
        Font(label, shade)
        if frame.Arrow and H.Allowed(label) and label.GetText then
            local original = label:GetText()
            if type(original) == "string" then
                -- Scrap adds tiny decorative symbols to these two menu entries.
                -- Change only the displayed label; keep native menu data/actions.
                local cleaned = original:gsub("%s*|A:worldquest%-icon%-engineering:.-|a", "")
                    :gsub("%s*|T516770:.-|t", "")
                if cleaned ~= original then
                    record.decoration = {label = label, original = original, cleaned = cleaned}
                    label:SetText(cleaned)
                end
            end
        end
        record.labelBusy = false
    end
    local function Check(frame)
        local normal = frame.GetNormalTexture and H.Texture(frame:GetNormalTexture())
        if not normal then return end
        normal:SetVertexColor(1, 1, 1, 1); normal:SetColorTexture(0.17, 0.17, 0.18, 1)
        normal:ClearAllPoints(); normal:SetPoint("LEFT", frame, "LEFT", 6, 0); normal:SetSize(14, 14)
        for i, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture", "GetPushedTexture", "GetHighlightTexture"}) do
            local texture = frame[getter] and H.Texture(frame[getter](frame))
            if texture then
                texture:SetVertexColor(1, 1, 1, 1)
                local r, g, b = S.GetAccentColor()
                if i == 1 then texture:SetColorTexture(r, g, b, 1)
                elseif i == 2 then texture:SetColorTexture(0.4, 0.4, 0.4, 0.8)
                else texture:SetColorTexture(1, 1, 1, 0.08) end
                texture:ClearAllPoints(); texture:SetPoint("CENTER", normal, "CENTER")
                texture:SetSize(i <= 2 and 8 or 14, i <= 2 and 8 or 14)
            end
        end
    end
    PaintControl = function(frame)
        if not Ready() or not H.Allowed(frame) then return end
        local record = Record(frame)
        if record.generation == generation and record.active and next(record.saved) then return end
        Capture(record, frame)
        local kind = frame:GetObjectType()
        if kind == "CheckButton" and not frame.Arrow then Check(frame)
        elseif kind == "Slider" then
            local thumb = frame.GetThumbTexture and H.Texture(frame:GetThumbTexture())
            if thumb then
                for _, region in ipairs(H.Regions(frame)) do if H.Texture(region) and region ~= thumb and not record.art[region] then region:SetAlpha(0) end end
                if frame.SetBackdrop then frame:SetBackdrop(nil) end
                thumb:SetVertexColor(1, 1, 1, 1); thumb:SetColorTexture(S.GetAccentColor()); thumb:SetSize(8, 14)
                local track = Art(record, "track", frame)
                track:SetPoint("LEFT", frame, "LEFT"); track:SetPoint("RIGHT", frame, "RIGHT"); track:SetHeight(2)
                track:SetColorTexture(0.2, 0.2, 0.22, 1)
            end
            if H.Allowed(frame.Edit) then PaintControl(frame.Edit) end
        elseif kind == "EditBox" then
            -- Sushi owns numeric suffixes and its hover-only background.
            Font(frame)
            if H.Allowed(frame.Bg) then
                Capture(record, frame.Bg)
                if frame.Bg.SetBackdrop then frame.Bg:SetBackdrop(nil) end
                local fill = Art(record, "editFill", frame.Bg)
                fill:SetAllPoints(frame.Bg); fill:SetColorTexture(0.10, 0.10, 0.11, 0.95)
            end
        elseif kind == "Button" and not frame.Line then
            Panel(frame, record)
            local hover = Art(record, "hover", frame, "HIGHLIGHT")
            hover:SetAllPoints(frame); hover:SetColorTexture(1, 1, 1, 0.08)
            if H.Texture(frame.Right) and frame.GetChecked then
                local glyph = Art(record, "expand", frame, "OVERLAY")
                glyph:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
                glyph:SetPoint("CENTER", frame.Right, "CENTER"); glyph:SetSize(12, 12)
                local function Expand()
                    if not record.active or not Ready() then return end
                    glyph:SetRotation(frame:GetChecked() and 0 or math.pi / 2)
                    glyph:SetVertexColor(S.GetAccentColor())
                end
                H.Hook(frame, "SetChecked", Expand); Expand()
            end
        elseif H.Texture(frame.Line) then frame.Line:SetAlpha(0) end
        -- Menu rows retain native check/radio/arrow/icon textures and actions.
        if frame.Arrow and H.Texture(frame.Highlight) then frame.Highlight:SetColorTexture(1, 1, 1, 0.10) end
        for _, text in ipairs(H.Regions(frame)) do Font(text) end
        Label(frame, record)
        for _, name in ipairs({"UpdateFont", "SetEnabled", "SetSmall"}) do
            H.Hook(frame, name, function() Label(frame, record) end)
        end
        local label = frame.Label or frame.GetFontString and frame:GetFontString()
        if H.Allowed(label) then
            H.Hook(label, "SetFontObject", function() Label(frame, record) end)
            if frame.Arrow then H.Hook(label, "SetText", function() Label(frame, record) end) end
        end
        record.generation = generation
    end
    local function BindGroup(group, menu)
        if not H.Allowed(group) then return end
        if not groups[group] then
            groups[group] = {menu = menu}
            local function Completed() PaintGroup(group) end
            for _, name in ipairs({"UpdateChildren", "Update", "SetChildren"}) do H.Hook(group, name, Completed) end
            H.Script(group, "OnShow", Completed)
        end
    end
    PaintGroup = function(group)
        if not Ready() or not H.Allowed(group) then return end
        local context = groups[group]
        if not context then return end
        if context.menu and group:GetParent() ~= app.Merchant then
            local record = records[group]; if record then Restore(record) end
            return
        end
        local record = Record(group)
        Capture(record, group)
        if context.menu and H.Allowed(group.bg) then
            Decoration(group.bg, record)
            Panel(group.bg, record)
        end
        for _, text in ipairs(H.Regions(group)) do Font(text) end
        for _, child in ipairs(group.Children or {}) do
            if H.Allowed(child) then
                if type(child.Children) == "table" then BindGroup(child); PaintGroup(child)
                else PaintControl(child) end
            end
        end
    end
    local function Menu()
        if not Ready() then return end
        local sushi = LibStub and LibStub("Sushi-3.2", true)
        local drop = sushi and sushi.Dropdown and sushi.Dropdown.Current
        if H.Allowed(drop) and drop:GetParent() == app.Merchant then BindGroup(drop, true); PaintGroup(drop) end
    end
    local function Merchant()
        if not Ready() then return end
        local frame = app.Merchant
        if not H.Allowed(frame) or not H.Texture(frame.icon) then return end
        -- OnLoad installs native scripts; attach only after that construction.
        H.Script(frame, "OnShow", Merchant); H.Script(frame, "OnClick", Menu)
        if merchantPaints[frame] == generation then return end
        soft.Button(frame, {"icon"})
        if H.Texture(frame.border) then H.Fade(frame.border) end
        -- The bag is a logo, not a square spell/item tile: cropping clips it.
        local size = math.max(1, math.min(frame:GetWidth(), frame:GetHeight()) - 6)
        frame.icon:SetTexCoord(0, 1, 0, 1)
        frame.icon:ClearAllPoints(); frame.icon:SetPoint("CENTER", frame, "CENTER"); frame.icon:SetSize(size, size)
        merchantPaints[frame] = generation
    end
    local function Rows()
        if not Ready() then return end
        local root = app.Visualizer or _G.ScrapVisualizer
        for _, row in ipairs(root and root.Scroll and root.Scroll.buttons or {}) do
            if H.Allowed(row) and rows[row] ~= generation then
                Font(row.Text) -- Preserve native item-quality RGB and selection.
                if H.Texture(row.Icon) then S.SquareIcon(row.Icon) end
                if H.Texture(row.Stripe) then row.Stripe:SetColorTexture(1, 1, 1, 0.035) end
                local hover = row.GetHighlightTexture and H.Texture(row:GetHighlightTexture())
                if hover then hover:SetColorTexture(1, 1, 1, 0.09) end
                rows[row] = generation
            end
        end
    end
    local function Tabs()
        if not Ready() then return end
        local root = app.Visualizer or _G.ScrapVisualizer
        if not H.Allowed(root) then return end
        H.Tab(root.Tab1 or _G.ScrapVisualizerTab1, root.selectedTab == 1)
        H.Tab(root.Tab2 or _G.ScrapVisualizerTab2, root.selectedTab == 2)
        H.Tab(root.ParentTab or root.tab, root:IsShown())
    end
    local function Visualizer()
        if not Ready() then return end
        local root = app.Visualizer or _G.ScrapVisualizer
        if not H.Allowed(root) or not root.numTabs then return end
        if visualizers[root] ~= generation then
            H.Shell(root, function() Tabs(); Rows() end, {noAccent = true, noTopBar = true})
            local inset = root.Inset or _G.ScrapVisualizerInset
            if H.Allowed(inset) then S.Inset(inset) end
            local close = root.CloseButton or _G.ScrapVisualizerCloseButton
            if H.Allowed(close) then S.CloseButton(close) end
            for _, button in pairs({root.ToggleButton, root.ForgetButton}) do
                if H.Allowed(button) then soft.Button(button); if S.StateButtonLabel then S.StateButtonLabel(button) end end
            end
            local scroll = root.Scroll or _G.ScrapVisualizerScroll
            local bar = scroll and scroll.scrollBar or _G.ScrapVisualizerScrollBar
            if H.Allowed(bar) then H.LegacySlider(bar); if bar.GetThumbTexture and H.Texture(bar:GetThumbTexture()) then bar:GetThumbTexture():SetWidth(5) end end
            local title = root.TitleText or root.TitleContainer and root.TitleContainer.TitleText
            Font(title, nil, true)
            visualizers[root] = generation
        end
        Tabs(); Rows()
    end
    local tutorialPaints = {}
    local function Tutorial()
        if not Ready() then return end
        local library = LibStub and LibStub("CustomTutorials-2.1", true)
        local frame = library and library.frames and library.frames[app.Tutorials]
        if not H.Allowed(frame) or tutorialPaints[frame] == generation then return end
        local images = {}
        for _, texture in pairs(frame.images or {}) do
            if H.Texture(texture) then images[texture] = texture:GetAlpha() end
        end
        H.Shell(frame, Tutorial, {noAccent = true, noTopBar = true})
        if S.RemovePortrait then S.RemovePortrait(frame) end
        if H.Allowed(frame.Inset) then S.Inset(frame.Inset) end
        if H.Allowed(frame.NineSlice) then S.FadeNineSlice(frame.NineSlice) end
        if H.Allowed(frame.CloseButton) then S.CloseButton(frame.CloseButton) end
        Font(frame.TitleText or frame.TitleContainer and frame.TitleContainer.TitleText, 0.92)
        Font(frame.text, 0.92)
        for i, button in ipairs({frame.prev, frame.next}) do
            if H.Allowed(button) then
                soft.SoftPageButton(button, i == 1 and "<" or ">")
                for _, text in ipairs(H.Regions(button)) do Font(text) end
            end
        end
        -- Shell stripping must never hide the tutorial's illustrations. Leave
        -- page visibility, sizing/anchors, callout shine and animation native.
        for texture, alpha in pairs(images) do texture:SetAlpha(alpha) end
        tutorialPaints[frame] = generation
    end
    local function Discover()
        local merchant, visualizer, options = app.Merchant, app.Visualizer or _G.ScrapVisualizer, app.Options
        H.Hook(merchant, "OnLoad", Refresh)
        H.Hook(visualizer, "OnLoad", Refresh); H.Hook(visualizer, "SetTab", Tabs)
        H.Hook(visualizer and visualizer.Scroll, "update", Rows)
        H.Hook(options, "OnLoad", Refresh)
        for _, method in ipairs({"OnLoad", "Register", "Start", "Restart", "RegisterTutorials", "TriggerTutorial"}) do
            H.Hook(app.Tutorials, method, Tutorial)
        end
        if type(options) == "table" then
            for _, name in ipairs({"Main", "Filters", "Help", "Credits"}) do
                local group = options[name]
                if H.Allowed(group) then
                    BindGroup(group)
                    if group.IsVisible and group:IsVisible() or not group.IsVisible and group:IsShown() then PaintGroup(group) end
                end
            end
        end
        Merchant(); Visualizer(); Menu(); Tutorial(); soft.RefreshSoftBorders()
    end
    Refresh = function()
        if applying or not Ready() then return end
        applying = true; H.Safe(Discover); applying = false
    end
    module.refresh = function() generation = generation + 1; Refresh() end
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    events:SetScript("OnEvent", function(_, event, addon)
        if event == "ADDON_LOADED" then
            if addon == "Scrap" or addon == "Scrap_Merchant" or addon == "Scrap_Config" then Refresh() end
        elseif waiting then waiting = false; generation = generation + 1; Refresh() end
    end)
    Refresh()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Scrap", DefineSkin)
else DefineSkin() end
