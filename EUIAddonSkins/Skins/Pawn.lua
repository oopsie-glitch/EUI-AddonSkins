local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("Pawn", "Pawn", function() return _G.PawnUIFrame ~= nil end, function(S, module)
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(setmetatable({PageButton = soft.SoftPageButton}, {__index = S}), module)
    local painted, checks, tabs, tabStates = {}, {}, {}, {}
    local rowPainted = setmetatable({}, {__mode = "k"})
    local generation, applying, waiting = 1, false, false
    local Apply, Walk, lastPaint
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
        return true
    end
    local function Name(f) return f.GetName and f:GetName() or "" end
    local function Font(text, preserveColor, owner)
        if H.Allowed(text) and text.GetFont and text:GetFont() then
            if preserveColor then
                local r, g, b, a = text:GetTextColor()
                S.Font(text); text:SetTextColor(r, g, b, a)
            else
                local disabled = owner and owner.IsEnabled and not owner:IsEnabled()
                S.Font(text, disabled and 0.5 or 0.92, disabled and 0.5 or 0.92, disabled and 0.5 or 0.94)
            end
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
    local function Row(f)
        if not Ready() or not H.Allowed(f) or rowPainted[f] == generation then return end
        rowPainted[f] = generation
        -- Pawn creates new native rows on rebuilds. Reuse their existing art;
        -- never add canvases, textures or permanent setter hooks to these rows.
        for _, r in ipairs(H.Regions(f)) do
            if r:GetObjectType() == "FontString" then Font(r, true) end
        end
        local highlight = f.GetHighlightTexture and H.Texture(f:GetHighlightTexture())
        if highlight then highlight:SetColorTexture(1, 1, 1, 0.09) end
        local icon = _G[Name(f) .. "Icon"]
        if H.Texture(icon) and S.SquareIcon then S.SquareIcon(icon) end
    end
    local rowGroups = {
        {"PawnUIScaleLine", "PawnUITotalScaleLines"},
        {"PawnUICompareStatLine", "PawnUITotalComparisonLines"},
        {"PawnUIGemLine", "PawnUITotalGemLines"},
    }
    local function CurrentRows()
        for _, group in ipairs(rowGroups) do
            for i = 1, tonumber(_G[group[2]]) or 0 do Row(_G[group[1] .. i]) end
        end
    end
    local function Tabs()
        if not Ready() then return end
        local previous
        for i = 1, #(_G.PawnUITabList or {}) do
            local tab = _G["PawnUIFrameTab" .. i]
            if H.Allowed(tab) then
                if not tabs[tab] then
                    S.Tab(tab); tabs[tab] = true
                    if previous then
                        tab:ClearAllPoints(); tab:SetPoint("LEFT", previous, "RIGHT", 2, 0)
                    end
                end
                local selected = i == _G.PawnUICurrentTabNumber
                local state = tabStates[tab]
                if not state or state.generation ~= generation or state.selected ~= selected then
                    if S.SetTabSelection then S.SetTabSelection(tab, selected) end
                    tabStates[tab] = {generation = generation, selected = selected}
                end
                previous = tab
            end
        end
    end
    local function Semantic(name)
        return name:find("^PawnUICompareItem") or name:find("^PawnUICompareStat")
            or name == "PawnUIFrame_ScaleNameLabel" or name == "PawnUIFrame_ScaleSelector_SpecLabel"
    end
    local function ItemButton(f)
        local icon = f.GetNormalTexture and H.Texture(f:GetNormalTexture())
        if icon and S.SquareIcon then S.SquareIcon(icon, f) end
        -- These normal textures ARE the item images. Generic Button stripping
        -- would erase them. Preserve their native drag, tooltip and click paths.
        local highlight = f.GetHighlightTexture and H.Texture(f:GetHighlightTexture())
        if highlight then highlight:SetColorTexture(1, 1, 1, 0.09) end
    end
    local function Launcher(f)
        if not Ready() or not H.Allowed(f) or painted[f] == generation then return end
        painted[f] = generation
        soft.Button(f)
        if not f:GetFontString() then f:SetText("Pawn") end
        if S.StateButtonLabel then S.StateButtonLabel(f) end
        Font(f:GetFontString(), false, f)
    end
    Walk = function(f)
        if not Ready() or not H.Allowed(f) or painted[f] == generation then return end
        local name = Name(f)
        if name == "PawnUIScaleSelectorScrollContent" or name == "PawnUICompareScrollContent"
            or name == "PawnUIGemScrollContent" or name:match("^PawnUIFrameTab%d+$") then return end
        painted[f] = generation
        -- Snapshot children before the API adds its own border hosts.
        local children, regions = H.Children(f), H.Regions(f)
        local kind = f:GetObjectType()
        if name:find("^PawnUIFrame_StatsList_Item%d+$") then Row(f); return end
        if kind == "CheckButton" then Check(f)
        elseif kind == "EditBox" then
            if not f.IsMultiLine or not f:IsMultiLine() then soft.EditBox(f) end
            Font(f)
        elseif kind == "Button" then
            if f == _G.PawnUIFrame_TinyCloseButton then S.CloseButton(f)
            elseif name:find("^PawnUICompareItemIcon%d+$") or name:find("^PawnUICompareItemShortcut%d+$") then
                ItemButton(f)
            elseif f == _G.PawnUIFrame_ScaleColorSwatch then
                -- Keep the colour picker and its exact scale colour.
                for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture"}) do
                    if f[getter] then H.Fade(f[getter](f)) end
                end
            else
                soft.Button(f, {"Text", "SelectedTexture", "Icon"})
                if S.StateButtonLabel then S.StateButtonLabel(f) end
                if H.Texture(f.SelectedTexture) then
                    local r, g, b = S.GetAccentColor(); f.SelectedTexture:SetColorTexture(r, g, b, 0.14)
                end
            end
        elseif f.GetBackdrop and f:GetBackdrop() and f ~= _G.PawnUIFrame then
            soft.Panel(f); f:SetBackdrop(nil)
        end
        local bar = f.ScrollBar or (name ~= "" and _G[name .. "ScrollBar"])
        if bar then Scroll(bar) end
        for _, r in ipairs(regions) do
            if r:GetObjectType() == "FontString" then Font(r, Semantic(Name(r)), (kind == "Button" or kind == "CheckButton") and f or nil)
            elseif H.Texture(r) then
                local path = r.GetTexture and r:GetTexture()
                if type(path) == "string" then
                    local leaf = path:match("([^\\/]+)$")
                    if leaf == "HorizontalBar" or leaf == "CompareBanner" or leaf == "CompareBar" then H.Fade(r) end
                end
            end
        end
        for _, child in ipairs(children) do if child ~= bar then Walk(child) end end
    end
    local function Paint()
        if lastPaint == generation then return end
        H.Shell(_G.PawnUIFrame, Apply, {noAccent = true})
        Walk(_G.PawnUIFrame)
        Walk(_G.PawnInterfaceOptionsFrame)
        for _, name in ipairs({"PawnUIStringDialogSingleLine", "PawnUIStringDialogMultiLine"}) do
            local frame = _G[name]
            if H.Allowed(frame) then
                H.Shell(frame, Apply, {noAccent = true, noTopBar = true})
                Walk(frame)
            end
        end
        for _, name in ipairs({"PawnUI_InventoryPawnButton", "PawnUI_InspectPawnButton", "PawnUI_SocketingPawnButton"}) do Launcher(_G[name]) end
        for _, name in ipairs({"PawnUIScaleSelector", "PawnUIScaleSelectorAuto"}) do
            if H.Allowed(_G[name]) then soft.Panel(_G[name]) end
        end
        CurrentRows(); Tabs(); soft.RefreshSoftBorders()
        lastPaint = generation
    end
    Apply = function()
        if applying or not Ready() then return end
        applying = true; H.Safe(Paint); applying = false
    end
    -- Completed local UI operations only. No item scoring, tooltip parsing,
    -- bag/equipment events, global factories or per-frame polling are hooked.
    H.Hook(_G, "PawnUICreateTabs", Tabs)
    H.Hook(_G, "PawnUISwitchToTab", Tabs)
    for _, entry in ipairs({
        {"PawnUIFrame_ScaleSelector_AddHeaderLine", 1}, {"PawnUIFrame_ScaleSelector_AddScaleLine", 1},
        {"PawnUI_AddComparisonStatLineStrings", 2}, {"PawnUI_AddComparisonHeaderLine", 2},
        {"PawnUI_AddGemLine", 3}, {"PawnUI_AddGemHeaderLine", 3},
    }) do
        local group = rowGroups[entry[2]]
        H.Hook(_G, entry[1], function() Row(_G[group[1] .. tostring(_G[group[2]])]) end)
    end
    H.Hook(_G, "PawnUIFrame_StatsList_UpdateStatItem", function(i)
        local f = _G["PawnUIFrame_StatsList_Item" .. tostring(i)]
        if Ready() and H.Allowed(f) then
            -- Native SetNormalFontObject deliberately changes semantic greys.
            -- Apply the face locally after that operation, retaining its colour.
            rowPainted[f] = nil; Row(f)
        end
    end)
    for _, name in ipairs({"PawnUI_InspectPawnButton_Attach", "PawnUI_SocketingPawnButton_Attach"}) do
        H.Hook(_G, name, function()
            Launcher(_G.PawnUI_InspectPawnButton); Launcher(_G.PawnUI_SocketingPawnButton)
        end)
    end
    module.refresh = function() generation = generation + 1; Apply() end
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    events:SetScript("OnEvent", function() if waiting then waiting = false; generation = generation + 1; Apply() end end)
    Apply()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Pawn", DefineSkin)
else DefineSkin() end
