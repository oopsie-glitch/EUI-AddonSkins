local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("PremadeGroupsFilter", "Premade Groups Filter", function()
    return _G.PremadeGroupsFilter ~= nil and _G.PremadeGroupsFilterDialog ~= nil
end, function(S, module)
    local app = _G.PremadeGroupsFilter
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(setmetatable({PageButton = soft.SoftPageButton}, {__index = S}), module)
    local painted, checks, selectors, views = {}, {}, {}, {}
    local generation, applying, waiting = 1, false, false
    local Apply, Walk, lastPaint
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
        return true
    end
    local function Font(text, owner, preserveColor)
        if H.Allowed(text) and text.GetFont and text:GetFont() then
            local shade = owner and owner.IsEnabled and not owner:IsEnabled() and 0.5 or 0.92
            if preserveColor then S.Font(text) else S.Font(text, shade, shade, shade) end
        end
    end
    local function Check(f)
        local art = checks[f]
        if not art then
            local before = {}
            for _, r in ipairs(H.Regions(f)) do before[r] = true end
            for _, c in ipairs(H.Children(f)) do before[c] = true end
            soft.Checkbox(f, {borderInset = 4, hover = 0.08})
            art = {}; checks[f] = art
            for _, r in ipairs(H.Regions(f)) do
                if not before[r] and H.Texture(r) then art[#art + 1] = r end
            end
            for _, c in ipairs(H.Children(f)) do
                if not before[c] and H.Allowed(c) and c:GetObjectType() == "Frame" then art[#art + 1] = c end
            end
        end
        -- Compact visible box, unchanged native click area and checked state.
        local size = math.min(14, f:GetWidth(), f:GetHeight())
        for _, r in ipairs(art) do
            r:ClearAllPoints(); r:SetPoint("CENTER", f, "CENTER"); r:SetSize(size, size)
        end
        for i, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = f[getter] and H.Texture(f[getter](f))
            if mark then
                mark:SetVertexColor(1, 1, 1, 1)
                if i == 1 then local r, g, b = S.GetAccentColor(); mark:SetColorTexture(r, g, b, 1)
                else mark:SetColorTexture(0.4, 0.4, 0.4, 0.8) end
                mark:ClearAllPoints(); mark:SetPoint("CENTER", f, "CENTER"); mark:SetSize(size - 4, size - 4)
            end
        end
    end
    local function Scroll(f)
        if not H.Allowed(f) then return end
        if f.GetThumbTexture and H.Texture(f:GetThumbTexture()) then
            H.LegacySlider(f); f:GetThumbTexture():SetWidth(5)
        else
            S.ScrollBar(f, true)
            if H.Allowed(f.Back) then soft.SoftPageButton(f.Back, "^") end
            if H.Allowed(f.Forward) then soft.SoftPageButton(f.Forward, "v") end
        end
    end
    local function Selector(f)
        local surface = selectors[f]
        if not surface then
            -- PGF's legacy selector includes decorative padding. Keep its
            -- native arrow button/label geometry and put the fill behind them.
            for _, key in ipairs({"Left", "Middle", "Right"}) do H.Fade(f[key]) end
            for _, r in ipairs(H.Regions(f.Button)) do if H.Texture(r) then H.Fade(r) end end
            surface = CreateFrame("Frame", nil, f)
            surface:EnableMouse(false)
            surface:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
            surface:SetPoint("LEFT", f, "LEFT", 20, 2)
            surface:SetPoint("RIGHT", f.Button, "RIGHT")
            surface:SetHeight(20)
            selectors[f] = surface
        end
        soft.Dropdown(surface)
        Font(f.Text)
    end
    Walk = function(f)
        if not Ready() or not H.Allowed(f) or painted[f] == generation then return end
        painted[f] = generation
        if selectors[f] then Selector(f); return end
        local kind = f:GetObjectType()
        if kind == "CheckButton" then Check(f)
        elseif kind == "EditBox" then
            if not f.IsMultiLine or not f:IsMultiLine() then soft.EditBox(f) end
            Font(f)
        elseif f.Button and f.Left and f.Middle and f.Right and H.Allowed(f.Button) then
            Selector(f); return
        elseif kind == "Button" then
            if f == _G.PremadeGroupsFilterDialog.CloseButton then S.CloseButton(f)
            elseif f.I and f.H then
                H.Fade(f.I); H.Fade(f.H); soft.SoftPageButton(f, "i", 13)
            elseif f:GetParent() == _G.PremadeGroupsFilterDialog.MaximizeMinimizeFrame then
                local holder = f:GetParent()
                soft.SoftPageButton(f, f == holder.MaximizeButton and "+" or "-", 14)
            else
                soft.Button(f, {"Text", "Label", "Icon", "icon", "Warning", "Image"})
                if S.StateButtonLabel then S.StateButtonLabel(f) end
            end
            local label = f.Text or f.Label or (f.GetFontString and f:GetFontString())
            Font(label, f)
            if f.Label then
                H.Script(f, "OnLeave", function() if Ready() then Font(f.Label, f) end end)
            end
        end
        if kind == "ScrollFrame" and f.EditBox then soft.Panel(f) end
        if f.NineSlice then S.FadeNineSlice(f.NineSlice) end
        if f.ScrollBar then Scroll(f.ScrollBar) end
        -- Do not traverse into modern virtualized lists or generated skin art.
        local children = H.Children(f)
        for _, r in ipairs(H.Regions(f)) do
            if r:GetObjectType() == "FontString" then Font(r, kind == "Button" and f or nil, r == f.Title and f.isAvailable ~= nil) end
        end
        for _, child in ipairs(children) do
            if child ~= f.ScrollBar and child ~= f.ScrollBox and child ~= f.InputBlocker then Walk(child) end
        end
    end
    local function Popup()
        if not Ready() then return end
        local popup = app.PopupMenuFrame
        if not H.Allowed(popup) then return end
        if painted[popup] ~= generation then
            soft.Panel(popup); if popup.SetBackdrop then popup:SetBackdrop(nil) end
            H.Fade(popup.Shadow); painted[popup] = generation
        end
        for _, button in ipairs(popup.Buttons or {}) do
            Walk(button)
            -- PGF rewrites the font every time this shared menu is initialized.
            Font(button.Text, button)
        end
        soft.RefreshSoftBorders()
    end
    local function Settings()
        local frame = _G.PremadeGroupsFilterSettingsFrame
        if not H.Allowed(frame) then return end
        Walk(frame)
        local box = frame.ScrollBox
        local view = box and box.GetView and box:GetView()
        if view and view.RegisterCallback and not views[view] then
            views[view] = true
            view:RegisterCallback("OnInitializedFrame", function(_, item)
                if Ready() then H.Safe(Walk, item) end
            end, module)
        end
        if box and box.ForEachFrame then box:ForEachFrame(function(item) Walk(item) end) end
    end
    local function Paint()
        if lastPaint == generation then return end
        local dialog = _G.PremadeGroupsFilterDialog
        H.Shell(dialog, Apply, {noAccent = true})
        Walk(dialog)
        for _, panel in pairs(dialog.panels or {}) do Walk(panel) end
        Walk(_G.UsePGFButton)
        Settings()
        local popup = _G.PremadeGroupsFilterStaticPopup
        if H.Allowed(popup) then
            if painted[popup] ~= generation then
                soft.Panel(popup)
                if popup.Border then S.FadeRegions(popup.Border) end
            end
            Walk(popup)
        end
        Popup()
        soft.RefreshSoftBorders()
        lastPaint = generation
    end
    Apply = function()
        if applying or not Ready() then return end
        applying = true; H.Safe(Paint); applying = false
    end
    local dialog = _G.PremadeGroupsFilterDialog
    H.Hook(dialog, "RegisterPanel", function(_, id, panel) if Ready() then Walk(panel) end end)
    H.Hook(dialog, "SwitchToPanel", function() if Ready() then Walk(dialog.activePanel) end end)
    H.Script(app.PopupMenuFrame, "OnShow", Popup)
    H.Hook(app.Debug, "PopupMenu_Initialize", Popup)
    H.Script(_G.PremadeGroupsFilterSettingsFrame, "OnShow", function() if Ready() then Settings() end end)
    H.Script(_G.PremadeGroupsFilterStaticPopup, "OnShow", Apply)
    module.refresh = function() generation = generation + 1; Apply() end
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    events:SetScript("OnEvent", function() if waiting then waiting = false; generation = generation + 1; Apply() end end)
    Apply()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("PremadeGroupsFilter", DefineSkin)
else DefineSkin() end
