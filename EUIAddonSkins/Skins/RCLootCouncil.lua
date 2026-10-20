local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("RCLootCouncil", "RCLootCouncil", function()
    local ui = type(_G.RCLootCouncil) == "table" and _G.RCLootCouncil.UI
    return type(ui) == "table" and type(ui.GetCreatedFramesOfType) == "function"
end, function(S, module)
    local app = _G.RCLootCouncil
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(setmetatable({PageButton = soft.SoftPageButton}, {__index = S}), module)
    local unpack = unpack or table.unpack
    local windows, icons, layers, nodes, pooled, owners = {}, {}, {}, {}, {}, {}
    local pooledButtons, dropdownArrows, closeGlyphs, nativeChecks, pooledThumbs = {}, {}, {}, {}, {}
    local windowDirty = {}
    local generation, waiting, applying = 1, false, false
    local Walk, PaintWidget, Refresh
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
        return true
    end
    local function Font(text, heading)
        if not H.Allowed(text) or not text.GetFont then return end
        local face, size, flags = text:GetFont()
        if not face then return end -- Partially constructed controls have no font yet.
        local target, targetFlags = S.GetFont()
        if face ~= target or (flags or "") ~= (targetFlags or "") then
            S.Font(text) -- Preserve native size, class, response and status colours.
        end
        if heading then text:SetTextColor(S.GetAccentColor()) end
    end
    local function Panel(f)
        if not H.Allowed(f) then return end
        if not layers[f] then
            -- A separate non-interactive child never intercepts loot or drag clicks.
            local layer = CreateFrame("Frame", nil, f)
            layers[f], layers[layer] = layer, true
            layer:SetAllPoints(f); layer:EnableMouse(false)
            layer:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
            S.Panel(layer, {noBorder = true})
        end
        if f.SetBackdrop then f:SetBackdrop(nil) end
        for _, r in ipairs(H.Regions(f)) do
            local layer = r.GetDrawLayer and r:GetDrawLayer()
            if H.Texture(r) and (layer == "BACKGROUND" or layer == "BORDER") then r:SetAlpha(0) end
        end
    end
    local function PoolButton(f)
        Panel(f)
        local hover = pooledButtons[f]
        if not hover then
            hover = f:CreateTexture(nil, "HIGHLIGHT")
            hover:SetAllPoints(f); hover:SetColorTexture(1, 1, 1, 0.08)
            pooledButtons[f] = hover
        end
        for _, r in ipairs(H.Regions(f)) do if H.Texture(r) and r ~= hover then r:SetAlpha(0) end end
    end
    local function PooledClose(f)
        if not H.Allowed(f) then return end
        if not closeGlyphs[f] then
            local layer = CreateFrame("Frame", nil, f)
            closeGlyphs[f], layers[layer] = layer, true
            layer:SetAllPoints(f); layer:EnableMouse(false)
            S.CloseButton(layer)
        end
        for _, r in ipairs(H.Regions(f)) do if H.Texture(r) then r:SetAlpha(0) end end
    end
    local function Icon(f)
        if not H.Allowed(f) then return end
        icons[f] = true
        local texture = f.GetNormalTexture and H.Texture(f:GetNormalTexture())
        if texture then S.SquareIcon(texture) end
        -- Native SetBorderColor also conveys selection/awarded/corruption state.
        -- Retain its colour, desaturation, texture and visibility logic.
        if f.GetBackdrop and f:GetBackdrop() then H.ThinBackdrop(f) end
    end
    local function Scroll(f, temporary)
        if f.GetThumbTexture and f:GetThumbTexture() then
            local thumb = f:GetThumbTexture()
            if temporary then
                -- No alpha-lock hooks on shared widgets: native art is restored
                -- when AceGUI releases this acquisition.
                for _, r in ipairs(H.Regions(f)) do if r ~= thumb and H.Texture(r) then r:SetAlpha(0) end end
                if f.SetBackdrop then f:SetBackdrop(nil) end
                local r, g, b = S.GetAccentColor(); thumb:SetColorTexture(r, g, b, 0.8)
                for _, pair in ipairs({{f.ScrollUpButton, "^"}, {f.ScrollDownButton, "v"}}) do
                    -- Keep native arrow art and its hit target on pooled sliders.
                    -- The track/thumb are themed without persistent API hooks.
                    if H.Allowed(pair[1]) then Font(pair[1].Text) end
                end
            else H.LegacySlider(f) end
            if f.GetOrientation and f:GetOrientation() == "HORIZONTAL" then thumb:SetSize(8, 14)
            else thumb:SetWidth(5) end
        elseif temporary then
            local thumb = f.Track and f.Track.Thumb or f.GetThumb and f:GetThumb()
            if H.Allowed(thumb) then
                local fill = pooledThumbs[thumb]
                if not fill then
                    fill = thumb:CreateTexture(nil, "ARTWORK"); pooledThumbs[thumb] = fill
                    fill:SetPoint("TOP", thumb, "TOP"); fill:SetPoint("BOTTOM", thumb, "BOTTOM"); fill:SetWidth(5)
                end
                for _, r in ipairs(H.Regions(thumb)) do if H.Texture(r) and r ~= fill then r:SetAlpha(0) end end
                local r, g, b = S.GetAccentColor(); fill:SetColorTexture(r, g, b, 0.8)
            end
        else
            S.ScrollBar(f, true)
            if H.Allowed(f.Back) then soft.SoftPageButton(f.Back, "^") end
            if H.Allowed(f.Forward) then soft.SoftPageButton(f.Forward, "v") end
        end
    end
    local function Check(f)
        local art = nativeChecks[f]
        if not art then
            local before = {}
            for _, r in ipairs(H.Regions(f)) do before[r] = true end
            for _, child in ipairs(H.Children(f)) do before[child] = true end
            soft.Checkbox(f, {borderInset = 4, hover = 0.06})
            art = {}; nativeChecks[f] = art
            for _, r in ipairs(H.Regions(f)) do if not before[r] then art[#art + 1] = r end end
            for _, child in ipairs(H.Children(f)) do if not before[child] then art[#art + 1] = child end end
        end
        for _, part in ipairs(art) do
            part:ClearAllPoints(); part:SetPoint("CENTER", f, "CENTER"); part:SetSize(14, 14)
        end
        for i, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = f[getter] and H.Texture(f[getter](f))
            if mark then
                mark:SetVertexColor(1, 1, 1, 1)
                if i == 1 then local r, g, b = S.GetAccentColor(); mark:SetColorTexture(r, g, b, 1)
                else mark:SetColorTexture(0.4, 0.4, 0.4, 0.8) end
                mark:ClearAllPoints(); mark:SetPoint("CENTER", f, "CENTER"); mark:SetSize(10, 10)
            end
        end
    end
    local function Control(f)
        local kind, widget = f:GetObjectType(), f.obj
        if icons[f] or type(f.SetBorderColor) == "function" then Icon(f); return end
        if kind == "CheckButton" then Check(f)
        elseif kind == "Slider" then Scroll(f, owners[f])
        elseif kind == "EditBox" then
            Font(f)
            if not (f.IsMultiLine and f:IsMultiLine()) then
                if owners[f] then Panel(f) else soft.EditBox(f, {padInput = false}) end
            end
        elseif kind == "Button" then
            local label = f.GetFontString and f:GetFontString()
            -- Texture-only dice/pass/note/class controls retain recognisable artwork.
            if H.Allowed(label) then
                if owners[f] then PoolButton(f)
                else
                    soft.Button(f)
                    if S.StateButtonLabel then S.StateButtonLabel(f) end
                end
            end
        end
        if kind == "StatusBar" then return end -- Native timeout value, alpha and colour.
        if H.Allowed(f.NineSlice) then
            if owners[f] then
                for _, r in ipairs(H.Regions(f.NineSlice)) do if H.Texture(r) then r:SetAlpha(0) end end
            else S.FadeNineSlice(f.NineSlice) end
        end
        if H.Allowed(f.CloseButton) then
            if owners[f] then PooledClose(f.CloseButton) else S.CloseButton(f.CloseButton) end
        end
        for _, key in ipairs({"ScrollBar", "scrollbar"}) do if H.Allowed(f[key]) then Scroll(f[key], owners[f]) end end
        if not owners[f] and type(f.initialize) == "function" and ns.BindPopupOwner then
            ns.BindPopupOwner(S, module, f); soft.Dropdown(f)
        end
        -- Ace widgets are handled after their complete page is built, never by a
        -- global AceGUI Create/AddChild callback.
        if widget and widget.frame == f then
            PooledClose(widget.closebutton); PooledClose(widget.closebtn)
        end
    end
    Walk = function(f, force, owner, depth)
        if not H.Allowed(f) or layers[f] == true or (depth or 0) > 24 then return end
        local kind = f:GetObjectType()
        if kind == "GameTooltip" or kind == "Texture" or kind == "FontString" then return end
        local state = nodes[f]
        local nc = f.GetNumChildren and f:GetNumChildren()
        local nr = f.GetNumRegions and f:GetNumRegions()
        if not force and state and state.generation == generation and nc ~= nil and nr ~= nil
            and state.children == nc and state.regions == nr then return end
        if not state then
            state = {}; nodes[f] = state
            H.Script(f, "OnShow", function() if (not owner or owner.active) and Ready() then Walk(f, false, owner) end end)
        end
        if owner then owner.nodes[f] = true; owners[f] = owner end
        Control(f)
        for _, text in ipairs(H.Regions(f)) do Font(text) end
        local children = H.Children(f)
        for _, child in ipairs(children) do
            if not owner or not child.obj or child.obj == owner.widget then
                Walk(child, force, owner, (depth or 0) + 1)
            end
        end
        state.children = f.GetNumChildren and f:GetNumChildren()
        state.regions = f.GetNumRegions and f:GetNumRegions()
        state.generation = generation
    end
    local function Window(f, force)
        if not H.Allowed(f) then return end
        if windowDirty[f] then force = true; windowDirty[f] = nil end
        if not windows[f] then
            windows[f] = true
            H.Script(f, "OnShow", function() if Ready() then Window(f, false) end end)
            H.Hook(f, "Update", function() if Ready() then Panel(f.content); Panel(f.title); Font(f.title and f.title.text, true) end end)
            H.Hook(f, "UpdateSt", function() if Ready() then Walk(f.content, true) end end)
        end
        -- RCFrame minimises content only. Never put a full-size fill on its parent.
        Panel(f.content); Panel(f.title); Font(f.title and f.title.text, true)
        Walk(f, force)
        for _, key in ipairs({"st", "date", "name"}) do
            local st = f[key]
            if type(st) == "table" and H.Allowed(st.frame) then
                Panel(st.frame)
                H.Hook(st, "Refresh", function()
                    if Ready() then Walk(st.frame, false) end
                end)
            end
        end
        if H.Allowed(f.moreInfoBtn) then
            H.ThinBackdrop(f.moreInfoBtn) -- Keep native expand/collapse direction.
        end
    end
    local function Queue(f)
        if not H.Allowed(f) then return end
        H.Queue(f, function() if Ready() then
            if windows[f] then Window(f, false) else Walk(f, true) end
        end end)
    end
    -- Pooled Ace widgets are shared with other addons. Snapshot only native
    -- cosmetics and restore them, then hide our added art, on each release.
    local function RegionState(r)
        local d = {alpha = r:GetAlpha()}
        if r.GetFont and r:GetFont() then d.font = {r:GetFont()}; d.color = {r:GetTextColor()} end
        if H.Texture(r) then
            d.texture = r:GetTexture()
            if r.GetAtlas then d.atlas = r:GetAtlas() end
            if r.GetVertexColor then d.vertex = {r:GetVertexColor()} end
            if r.GetTexCoord then d.coords = {r:GetTexCoord()} end
            d.width, d.height = r:GetWidth(), r:GetHeight()
            if r.GetNumPoints then
                d.points = {}; for i = 1, r:GetNumPoints() do d.points[i] = {r:GetPoint(i)} end
            end
        end
        return d
    end
    local function RestoreRegion(r, d)
        r:SetAlpha(d.alpha)
        if d.font then r:SetFont(unpack(d.font)); r:SetTextColor(unpack(d.color)) end
        if H.Texture(r) then
            if d.atlas and r.SetAtlas then r:SetAtlas(d.atlas) else r:SetTexture(d.texture) end
            if d.vertex then r:SetVertexColor(unpack(d.vertex)) end
            if d.coords then r:SetTexCoord(unpack(d.coords)) end
            r:SetSize(d.width, d.height)
            if d.points then r:ClearAllPoints(); for _, point in ipairs(d.points) do r:SetPoint(unpack(point)) end end
        end
    end
    local function Snapshot(f, record, depth)
        if not H.Allowed(f) or layers[f] == true or (depth or 0) > 24 then return end
        if f:GetObjectType() == "GameTooltip" then return end
        local d = record.saved[f]
        local fresh = not d
        if fresh then d = {regions = {}, children = {}}; record.saved[f] = d end
        if fresh and f.GetBackdrop then
            d.backdrop = f:GetBackdrop()
            if f.GetBackdropColor then d.bg = {f:GetBackdropColor()} end
            if f.GetBackdropBorderColor then d.edge = {f:GetBackdropBorderColor()} end
        end
        if fresh and f.GetFont and f:GetFont() then d.font = {f:GetFont()}; d.color = {f:GetTextColor()} end
        for _, r in ipairs(H.Regions(f)) do
            if not d.regions[r] and not (record.art and record.art[r]) then d.regions[r] = RegionState(r) end
        end
        for _, child in ipairs(H.Children(f)) do
            d.children[child] = true
            if not (record.art and record.art[child]) and (not child.obj or child.obj == record.widget) then
                Snapshot(child, record, (depth or 0) + 1)
            end
        end
    end
    local function Restore(record)
        if not record.active then return end
        record.active = false
        for f, d in pairs(record.saved) do
            nodes[f], owners[f] = nil, nil
            if f.SetBackdrop then
                f:SetBackdrop(d.backdrop)
                if d.bg then f:SetBackdropColor(unpack(d.bg)) end
                if d.edge then f:SetBackdropBorderColor(unpack(d.edge)) end
            end
            if d.font then f:SetFont(unpack(d.font)); f:SetTextColor(unpack(d.color)) end
            for r, saved in pairs(d.regions) do RestoreRegion(r, saved) end
        end
        for art in pairs(record.art or {}) do art:SetAlpha(0) end
        record.saved = {}
    end
    local function PaintCheck(widget, record)
        if not record.active or not Ready() or not widget.checkbg or not widget.check then return end
        widget.checkbg:SetColorTexture(0.1, 0.1, 0.11, 1); widget.checkbg:SetSize(14, 14)
        widget.checkbg:SetTexCoord(0, 1, 0, 1)
        local r, g, b = S.GetAccentColor()
        widget.check:SetVertexColor(1, 1, 1, 1)
        widget.check:SetColorTexture(widget.disabled and 0.45 or r, widget.disabled and 0.45 or g, widget.disabled and 0.45 or b, 1)
        widget.check:SetTexCoord(0, 1, 0, 1)
        widget.check:ClearAllPoints(); widget.check:SetPoint("CENTER", widget.checkbg, "CENTER"); widget.check:SetSize(8, 8)
    end
    PaintWidget = function(widget)
        if type(widget) ~= "table" or not H.Allowed(widget.frame) then return end
        local f = widget.frame
        local record = pooled[widget]
        if not record then
            record = {widget = widget, nodes = {}, saved = {}}; pooled[widget] = record
            -- Cleanup is intentionally ungated: disabling a skin cannot leak its
            -- appearance into an unrelated addon's next pool acquisition.
            if type(widget.OnRelease) == "function" then hooksecurefunc(widget, "OnRelease", function() Restore(record) end) end
        end
        if not record.active then
            record.active, record.saved = true, {}
            Snapshot(f, record)
            for art, alpha in pairs(record.art or {}) do art:SetAlpha(alpha) end
        end
        -- Snapshot newly introduced native subframes before this pass; a
        -- layout rebuild can add children without releasing the outer group.
        Snapshot(f, record)
        local before = {}
        for node in pairs(record.saved) do
            for _, r in ipairs(H.Regions(node)) do before[r] = true end
            for _, child in ipairs(H.Children(node)) do before[child] = true end
        end
        for node in pairs(record.saved) do owners[node] = record end
        if widget.type == "Window" or widget.type == "Frame" then Panel(f) end
        if widget.type == "CheckBox" and widget.checkbg and widget.check then
            PaintCheck(widget, record)
            for _, method in ipairs({"SetValue", "SetType", "SetDisabled"}) do
                H.Hook(widget, method, function() PaintCheck(widget, record) end)
            end
        elseif widget.type == "Dropdown" and H.Allowed(widget.dropdown) then
            local host = H.Allowed(widget.button_cover) and widget.button_cover or widget.dropdown
            PoolButton(host)
            if not dropdownArrows[host] then
                local arrow = host:CreateTexture(nil, "OVERLAY")
                arrow:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
                arrow:SetSize(12, 12); arrow:SetPoint("RIGHT", host, "RIGHT", -5, 0)
                dropdownArrows[host] = arrow
            end
            dropdownArrows[host]:SetAlpha(0.8)
            if H.Allowed(widget.button) then
                for _, r in ipairs(H.Regions(widget.button)) do if H.Texture(r) then r:SetAlpha(0) end end
            end
        elseif widget.type == "TabGroup" then
            for _, tab in pairs(widget.tabs or {}) do
                if H.Allowed(tab) then
                    PoolButton(tab)
                    local text = tab.text or tab.Text or tab.GetFontString and tab:GetFontString()
                    if H.Allowed(text) then
                        Font(text)
                        if tab.selected then text:SetTextColor(S.GetAccentColor()) else text:SetTextColor(0.9, 0.9, 0.9, 1) end
                    end
                end
            end
        end
        for _, key in ipairs({"border", "treeframe"}) do if H.Allowed(widget[key]) then Panel(widget[key]) end end
        Walk(f, true, record)
        record.art = record.art or {}
        for node in pairs(record.saved) do
            for _, r in ipairs(H.Regions(node)) do if not before[r] then record.art[r] = r:GetAlpha() end end
            for _, child in ipairs(H.Children(node)) do if not before[child] then record.art[child] = child:GetAlpha() end end
        end
        for _, child in ipairs(widget.children or {}) do PaintWidget(child) end
    end
    local function Options()
        local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
        if not dialog then return end
        H.Hook(dialog, "FeedGroup", function(_, id, _, container)
            if id == "RCLootCouncil" and Ready() then PaintWidget(container) end
        end)
        local open = dialog.OpenFrames and dialog.OpenFrames.RCLootCouncil
        if open then PaintWidget(open) end
        for _, widget in pairs(dialog.BlizOptions and dialog.BlizOptions.RCLootCouncil or {}) do
            if widget.frame and widget.frame:IsShown() then PaintWidget(widget) end
        end
    end
    local function Menus()
        if not ns.BindPopupList then return end
        local root = _G.MSA_DROPDOWNMENU_OPEN_MENU
        local name = H.Allowed(root) and root:GetName()
        if type(name) ~= "string" or not name:match("^RCLootCouncil") then
            if ns.RefreshPopupMenusNow then ns.RefreshPopupMenusNow() end
            return
        end
        for level = 1, 8 do
            local list = _G["MSA_DropDownList" .. level]
            if H.Allowed(list) and list.dropdown then ns.BindPopupList(S, module, list.dropdown, list) end
        end
    end
    local function Discover()
        local ui = app.UI
        for _, kind in ipairs({"Icon", "IconBordered"}) do
            for _, f in pairs(ui:GetCreatedFramesOfType(kind)) do Icon(f) end
        end
        for _, f in pairs(ui:GetCreatedFramesOfType("RCFrame")) do Window(f, false) end
        for _, kind in ipairs({"RCExportFrame", "RCImportFrame", "RCHugeExportFrame"}) do
            for _, widget in pairs(ui:GetCreatedFramesOfType(kind)) do PaintWidget(widget) end
        end
        Options(); Menus()
    end
    Refresh = function()
        if applying or not Ready() then return end
        applying = true; H.Safe(Discover); applying = false
    end
    module.refresh = function() generation = generation + 1; Refresh() end
    -- Embed receives the actual newly constructed result; observing it leaves
    -- constructors, native return values and asynchronous work untouched.
    H.Hook(app.UI.private, "Embed", function(_, object)
        if not Ready() then return end
        if H.Allowed(object) then
            if object.content and object.title then Window(object, false); windowDirty[object] = true; Queue(object)
            elseif object.GetNormalTexture and object:GetNormalTexture() and not (object.GetFontString and object:GetFontString()) then Icon(object)
            else Walk(object, false) end
        elseif type(object) == "table" and object.frame then PaintWidget(object) end
    end)
    -- Completion hooks for controls created directly rather than by UI:New.
    if type(app.IterateModules) == "function" then
        for _, target in app:IterateModules() do
            H.Hook(target, "GetFrame", function()
                if Ready() then
                    if H.Allowed(target.frame) then Window(target.frame, false) end
                end
            end)
            for _, method in ipairs({"SetCellVote", "SetCellGear", "SetCellNote", "SetCellDeleteBtn", "SetCellDelete", "SetCellItemIcon", "SetCellSessionResponses"}) do
                H.Hook(target, method, function(_, cell)
                    if Ready() and H.Allowed(cell) then
                        if method == "SetCellGear" or method == "SetCellItemIcon" then Icon(cell) end
                        Walk(cell, false)
                    end
                end)
            end
            local manager = target.EntryManager
            H.Hook(manager, "GetEntry", function(_, item)
                local entry = manager.entries and manager.entries[item]
                if Ready() and entry then Walk(entry.frame, true) end
            end)
        end
    end
    H.Hook(_G, "MSA_ToggleDropDownMenu", Menus)
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    events:SetScript("OnEvent", function() if waiting then waiting = false; generation = generation + 1; Refresh() end end)
    Refresh()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("RCLootCouncil", DefineSkin)
else DefineSkin() end
