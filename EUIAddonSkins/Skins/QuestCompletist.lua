local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("QuestCompletist", "Quest Completist", function()
    return _G.qcQuestCompletistUI ~= nil
end, function(S, module)
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(S, module)
    local painted, fonts, checks = {}, {}, {}
    local generation, applying, waiting = 1, false, false
    local Apply
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    local function Font(text, semantic)
        if not H.Allowed(text) or text:GetObjectType() ~= "FontString" or fonts[text] == generation then return end
        if semantic and text.GetTextColor then
            local r, g, b, a = text:GetTextColor()
            H.Font(text, r, g, b); text:SetTextColor(r, g, b, a)
        else H.Font(text, 0.9, 0.9, 0.92) end
        fonts[text] = generation
    end
    local function Label(frame)
        local name = frame.GetName and frame:GetName()
        return frame.Text or frame.text or (frame.GetFontString and frame:GetFontString()) or name and _G[name .. "Text"]
    end
    local function Owned(frame, root)
        if not H.Allowed(frame) or not H.Allowed(root) then return false end
        local parent = frame
        for _ = 1, 8 do
            if parent == root then return true end
            parent = parent.GetParent and parent:GetParent()
            if not parent then return false end
        end
        return false
    end
    local function Button(frame)
        if not H.Allowed(frame) then return end
        if not painted[frame] then
            soft.Button(frame)
            if S.StateButtonLabel then S.StateButtonLabel(frame) end
            painted[frame] = true
        end
        Font(Label(frame))
    end
    local function Check(frame)
        if not checks[frame] then
            soft.Checkbox(frame, {borderInset = 4, hover = 0.08})
            local function State()
                if InCombatLockdown and InCombatLockdown() then waiting = true; return end
                local text = Label(frame)
                if H.Allowed(text) and text.SetTextColor then
                    local shade = frame.IsEnabled and not frame:IsEnabled() and 0.5 or 0.9
                    text:SetTextColor(shade, shade, shade, 1)
                end
            end
            checks[frame] = State
            for _, method in ipairs({"Enable", "Disable", "SetEnabled"}) do H.Hook(frame, method, State) end
        end
        Font(Label(frame))
        local r, g, b = S.GetAccentColor()
        for i, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = frame[getter] and H.Texture(frame[getter](frame))
            if mark then
                mark:SetVertexColor(1, 1, 1, 1)
                if i == 1 then mark:SetColorTexture(r, g, b, 1)
                else mark:SetColorTexture(0.4, 0.4, 0.4, 0.8) end
                mark:ClearAllPoints(); mark:SetPoint("CENTER", frame, "CENTER"); mark:SetSize(8, 8)
            end
        end
        checks[frame]()
    end
    local function Menu()
        if ns.BindPopupOwner and H.Allowed(_G.qcCategoryDropDownMenu) then
            ns.BindPopupOwner(S, module, qcCategoryDropDownMenu)
        end
    end
    local optionChildren, optionRegions, optionGeneration, optionFrame
    local function Options()
        local frame = _G.qcInterfaceOptions
        if not H.Allowed(frame) then return end
        -- OnShow builds the native filters before our post-script runs. Once
        -- constructed, changing values requires no traversal or font writes.
        local children, regions = frame:GetNumChildren(), frame:GetNumRegions()
        if optionFrame == frame and optionChildren == children and optionRegions == regions and optionGeneration == generation then return end
        for _, child in ipairs(H.Children(frame)) do
            if H.Allowed(child) then
                if child:GetObjectType() == "CheckButton" then Check(child)
                elseif child:GetObjectType() == "Button" then Button(child) end
            end
        end
        for _, text in ipairs(H.Regions(frame)) do Font(text) end
        -- Skin primitives can add their own children/regions: cache final counts.
        optionFrame, optionChildren, optionRegions, optionGeneration = frame, frame:GetNumChildren(), frame:GetNumRegions(), generation
    end
    local tooltipNames = {"qcMapTooltip", "qcQuestInformationTooltip", "qcToastTooltip", "qcQuestReputationTooltip",
        "qcNewDataAlertTooltip", "qcMutuallyExclusiveAlertTooltip"}
    local function Tooltip(frame)
        if not H.Allowed(frame) or painted[frame] then return end
        painted[frame] = true
        -- Texture-only styling preserves quest status colours, inline icons,
        -- native tooltip fonts, dynamically added lines and completion bars.
        local icons = {}
        for _, region in ipairs(H.Regions(frame)) do
            if H.Texture(region) and region.GetDrawLayer then
                local layer = region:GetDrawLayer()
                if layer ~= "BACKGROUND" and layer ~= "BORDER" then icons[region] = region:GetAlpha() end
            end
        end
        S.Panel(frame, {noBorder = true, inset = false})
        for region, alpha in pairs(icons) do region:SetAlpha(alpha) end
        if frame.SetBackdrop then frame:SetBackdrop(nil) end
        if H.Allowed(frame.NineSlice) then S.FadeNineSlice(frame.NineSlice) end
    end
    local function Paint()
        local root = _G.qcQuestCompletistUI
        if not H.Allowed(root) then return end
        if not painted[root] then
            H.Shell(root, Apply, {noAccent = true, noTopBar = true, noBorder = true})
            -- The native artwork includes transparent margins below the content.
            -- All native rows/control anchors fit in this compact outer shell.
            root:SetSize(360, 450)
            H.Fade(root.qcPortrait); H.Fade(root.qcPortraitMask)
            painted[root] = true
        end
        for _, key in ipairs({"qcTitleText", "qcSelectedCategory", "qcCurrentCategoryQuestCount"}) do Font(root[key]) end
        Font(_G.qcQuestCompletistUIHiddenQuests)
        if Owned(_G.qcXButton, root) and not painted[qcXButton] then
            S.CloseButton(qcXButton); qcXButton:ClearAllPoints(); qcXButton:SetPoint("TOPRIGHT", root, "TOPRIGHT", -5, -5)
            painted[qcXButton] = true
        end
        for _, name in ipairs({"qcOptionsButton", "qcCategoryDropdownButton"}) do
            if Owned(_G[name], root) then Button(_G[name]) end
        end
        local search = _G.qcSearchBox
        if Owned(search, root) and not painted[search] then
            soft.EditBox(search, {padInput = true}); painted[search] = true
            -- The search's native placeholder, focus, clear-button and text
            -- callbacks must retain control of content, colour and visibility.
            for _, child in ipairs(H.Children(search)) do
                if H.Allowed(child) and child:GetObjectType() == "Button" then S.CloseButton(child) end
            end
        end
        local slider = _G.qcMenuSlider
        if Owned(slider, root) and painted[slider] ~= generation then
            H.LegacySlider(slider)
            local thumb = slider.GetThumbTexture and H.Texture(slider:GetThumbTexture())
            if thumb then thumb:SetVertexColor(1, 1, 1, 1); thumb:SetSize(5, 20) end
            painted[slider] = generation
        end
        for i = 1, 16 do
            local row = _G["qcMenuButton" .. i]
            if Owned(row, root) then
                Font(row.QuestName, true)
                if not painted[row] then
                    -- Keep quest/faction atlases, hit areas and semantic colours.
                    -- A plain highlight avoids a second button shell per row.
                    local highlight = row.GetHighlightTexture and H.Texture(row:GetHighlightTexture())
                    if highlight then highlight:SetColorTexture(1, 1, 1, 0.12) end
                    painted[row] = true
                end
            end
        end
        local options = _G.qcInterfaceOptions
        if H.Allowed(options) then H.Script(options, "OnShow", Apply); Options() end
        -- Named tooltips are accessible even when the target keeps its own
        -- references local. No map providers, pin creation or data are changed.
        for _, name in ipairs(tooltipNames) do Tooltip(_G[name]) end
        local toast = _G.qcToast
        if H.Allowed(toast) and not painted[toast] then
            soft.Panel(toast, {inset = false}); H.Fade(_G.qcToastLogo); painted[toast] = true
        end
        if H.Allowed(toast) then Font(toast.qcToastText, true) end
        Menu()
        soft.RefreshSoftBorders()
    end
    Apply = function()
        if applying or not ns.IsEnabled(module) then return end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return end
        applying = true; H.Safe(Paint); applying = false
    end
    module.refresh = function() generation = generation + 1; Apply() end
    -- Only completed constructors need discovery. Scrolling/filtering merely
    -- changes the existing 16 rows; no skin callbacks are attached to that path.
    for _, method in ipairs({"qcQuestCompletistUI_OnLoad", "qcInterfaceOptions_OnShow", "qcCategoryDropdownButton_OnClick",
        "qcMapTooltipSetup", "qcQuestInformationTooltipSetup", "qcToastTooltipSetup",
        "qcNewDataAlertTooltipSetup", "qcMutuallyExclusiveAlertTooltipSetup"}) do H.Hook(_G, method, Apply) end
    events:SetScript("OnEvent", function()
        if waiting then waiting = false; module.refresh() end
    end)
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    Apply()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("QuestCompletist", DefineSkin)
else DefineSkin() end
