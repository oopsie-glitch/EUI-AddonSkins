local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("WorldQuestTab", "World Quest Tab", function() return _G.WQT_ListContainer ~= nil end, function(S, module)
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(S, module)
    local styled, fontCache, rows, settings, bound = {}, {}, {}, {}, {}
    local backgrounds = {}
    local generation, applying, waiting = 1, false, false
    local Apply, QuestRow, SettingRow
    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED"); events:RegisterEvent("PLAYER_REGEN_ENABLED")
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
        return true
    end
    local function Font(text, semantic, disabled)
        if not H.Allowed(text) or not text.GetFont then return end
        local path, size, flags = text:GetFont()
        local old = fontCache[text]
        if not old or old.epoch ~= generation or old.path ~= path or old.size ~= size or old.flags ~= flags then
            local r, g, b, a
            if semantic and text.GetTextColor then r, g, b, a = text:GetTextColor() end
            S.Font(text, r, g, b)
            if r then text:SetTextColor(r, g, b, a) end
            path, size, flags = text:GetFont()
            old = old or {}; old.epoch, old.path, old.size, old.flags = generation, path, size, flags
            fontCache[text] = old
        end
        if not semantic and text.SetTextColor then
            local shade = disabled and 0.5 or 0.9
            local r, g, b = text:GetTextColor()
            if r ~= shade or g ~= shade or b ~= shade then text:SetTextColor(shade, shade, shade) end
        end
    end
    local function Action(frame, keep)
        if not H.Allowed(frame) then return end
        if not styled[frame] then
            soft.Button(frame, keep)
            if S.StateButtonLabel and frame.GetFontString and frame:GetFontString() then S.StateButtonLabel(frame) end
            styled[frame] = true
        end
        Font(frame.Label or frame.Text or (frame.GetFontString and frame:GetFontString()), false, frame.IsEnabled and not frame:IsEnabled())
    end
    local function Dropdown(frame)
        if not H.Allowed(frame) then return end
        if not styled[frame] then soft.Dropdown(frame); styled[frame] = true end
        if ns.BindPopupOwner then ns.BindPopupOwner(S, module, frame) end
        Font(frame.Text)
    end
    local function Edit(frame)
        if not H.Allowed(frame) then return end
        -- Keep native input bounds, padding, instructions and focus callbacks.
        if not styled[frame] then soft.EditBox(frame); styled[frame] = true end
        local old = fontCache[frame]
        if (not old or old.epoch ~= generation) and frame.SetFont and frame.GetFont and S.GetFont then
            local _, size = frame:GetFont(); local path, flags = S.GetFont()
            frame:SetFont(path, size or 12, flags or "")
            old = old or {}; old.epoch = generation; fontCache[frame] = old
        end
    end
    local function Scroll(frame)
        if not H.Allowed(frame) or styled[frame] then return end
        S.ScrollBar(frame)
        if H.Allowed(frame.Back) then soft.SoftPageButton(frame.Back, "^") end
        if H.Allowed(frame.Forward) then soft.SoftPageButton(frame.Forward, "v") end
        styled[frame] = true
    end
    local function Background(frame)
        if not H.Allowed(frame) then return end
        local state = backgrounds[frame]
        if not state then
            local layer = CreateFrame("Frame", nil, frame)
            layer:SetAllPoints(frame); layer:EnableMouse(false); layer:SetFrameLevel(frame:GetFrameLevel())
            state = {layer = layer}; backgrounds[frame] = state
            state.base = layer:CreateTexture(nil, "BACKGROUND", nil, -5); state.base:SetAllPoints(layer)
            state.left = layer:CreateTexture(nil, "BACKGROUND", nil, -4)
            state.left:SetPoint("TOPLEFT", layer, "TOPLEFT"); state.left:SetPoint("BOTTOMRIGHT", layer, "BOTTOM")
            state.right = layer:CreateTexture(nil, "BACKGROUND", nil, -4)
            state.right:SetPoint("TOPLEFT", layer, "TOP"); state.right:SetPoint("BOTTOMRIGHT", layer, "BOTTOMRIGHT")
            H.Fade(frame.Background)
            if H.Allowed(frame.BorderFrame) then frame.BorderFrame:SetAlpha(0) end
        end
        if state.epoch == generation then return end
        local r, g, b = S.GetPanelColor()
        r, g, b = math.max(0.055, r), math.max(0.055, g), math.max(0.055, b)
        state.base:SetColorTexture(r, g, b, 0.94)
        for i, texture in ipairs({state.left, state.right}) do
            texture:SetColorTexture(1, 1, 1, 1)
            local first, last = i == 1 and 0 or 0.35, i == 1 and 0.35 or 0
            if texture.SetGradient and CreateColor then
                texture:SetGradient("HORIZONTAL", CreateColor(r + 0.1, g + 0.1, b + 0.1, first), CreateColor(r + 0.1, g + 0.1, b + 0.1, last))
            elseif texture.SetGradientAlpha then
                texture:SetGradientAlpha("HORIZONTAL", r + 0.1, g + 0.1, b + 0.1, first, r + 0.1, g + 0.1, b + 0.1, last)
            else texture:SetColorTexture(r + 0.03, g + 0.03, b + 0.03, 0.2) end
        end
        state.epoch = generation
    end
    local function Highlight(frame, r, g, b, alpha)
        if not H.Allowed(frame) then return end
        for _, key in ipairs({"Left", "Center", "Right"}) do
            local texture = H.Texture(frame[key])
            if texture then texture:SetColorTexture(r, g, b, 1) end
        end
        frame:SetAlpha(alpha)
    end
    QuestRow = function(frame)
        if not Ready() or not H.Allowed(frame) then return end
        local old = rows[frame]
        if old == generation then return end
        rows[frame] = generation
        local center = frame.CenterContent
        local bottom = center and center.BottomRow
        Font(center and center.Title, true)
        if bottom then Font(bottom.Time, true); Font(bottom.Extra, true); Font(bottom.ZoneSeparator, true) end
        Highlight(frame.Highlight, 1, 1, 1, 0.12)
        local r, g, b = S.GetAccentColor()
        -- Only change tracked-row colour: native alpha/visibility distinguishes
        -- tracked vs supertracked. Quest time, rarity and rewards remain native.
        if H.Allowed(frame.TrackedBorder) then
            for _, key in ipairs({"Left", "Center", "Right"}) do
                local texture = H.Texture(frame.TrackedBorder[key])
                if texture then texture:SetColorTexture(r, g, b, 1) end
            end
        end
        if ns.BindPopupOwner then ns.BindPopupOwner(S, module, frame) end
    end
    local function Check(frame)
        if not H.Allowed(frame) then return end
        if not styled[frame] then soft.Checkbox(frame, {borderInset = 4, hover = 0.08}); styled[frame] = true end
        local r, g, b = S.GetAccentColor()
        for i, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = frame[getter] and H.Texture(frame[getter](frame))
            if mark then
                mark:SetVertexColor(1, 1, 1, 1)
                if i == 1 then mark:SetColorTexture(r, g, b, 1) else mark:SetColorTexture(0.4, 0.4, 0.4, 0.8) end
                mark:ClearAllPoints(); mark:SetPoint("CENTER", frame, "CENTER"); mark:SetSize(8, 8)
            end
        end
    end
    local function Category(frame, record)
        if not record.category then
            record.category = true
            for _, key in ipairs({"BGLeft", "BGMiddle", "BGRight", "HighlightLeft", "HighlightMiddle", "HighlightRight", "Background", "Highlight", "ExpandIcon", "collapseTex"}) do H.Fade(frame[key]) end
            record.fill = frame:CreateTexture(nil, "BACKGROUND")
            record.fill:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -2); record.fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 2)
            record.hover = frame:CreateTexture(nil, "HIGHLIGHT"); record.hover:SetAllPoints(record.fill); record.hover:SetColorTexture(1, 1, 1, 0.1)
            record.arrow = frame:CreateTexture(nil, "OVERLAY")
            record.arrow:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
            record.arrow:SetSize(10, 7); record.arrow:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
        end
        local shade = frame.isExpanded and 0.12 or 0.09
        record.fill:SetColorTexture(shade, shade, shade, 0.95)
        record.arrow:SetRotation(frame.isExpanded and 0 or math.pi / 2)
        record.arrow:SetVertexColor(0.8, 0.8, 0.8, 1)
    end
    SettingRow = function(frame, data)
        if not Ready() or not H.Allowed(frame) then return end
        local record = settings[frame]
        if not record then
            record = {template = data and data.template}; settings[frame] = record
            -- Instance hooks run after native font/disabled-state resets. Never
            -- hook all AceGUI factories or scan the settings tree on a click.
            H.Hook(frame, "UpdateState", function() SettingRow(frame) end)
        end
        if data and data.template then record.template = data.template end
        local disabled = frame.IsDisabled and frame:IsDisabled()
        local template = record.template or ""
        Font(frame.Label, frame.staticLabelFont and template == "WQT_SettingTextTemplate", disabled)
        if record.epoch ~= generation then
            if H.Texture(frame.BgHighlight) then frame.BgHighlight:SetColorTexture(1, 1, 1, 0.1) end
            Dropdown(frame.Dropdown)
            for _, key in ipairs({"Button", "ButtonConfirm", "ButtonDecline"}) do Action(frame[key], {"Label", "Text"}) end
            Action(frame.Picker, {"Color"}); Action(frame.ResetButton, {"Icon"})
            Edit(frame.TextBox)
            local slider = frame.SliderWithSteppers
            if H.Allowed(slider) then
                local control = slider.Slider
                if H.Allowed(control) then
                    H.LegacySlider(control)
                    local thumb = control.GetThumbTexture and H.Texture(control:GetThumbTexture())
                    if thumb then thumb:SetVertexColor(1, 1, 1, 1); thumb:SetSize(8, 14) end
                end
                if H.Allowed(slider.Back) then soft.SoftPageButton(slider.Back, "<") end
                if H.Allowed(slider.Forward) then soft.SoftPageButton(slider.Forward, ">") end
            end
            if template == "WQT_SettingsQuestListPreviewTemplate" then H.Fade(frame.Background); QuestRow(frame.Preview) end
            Check(frame.CheckBox)
            record.epoch = generation
        end
        if template == "WQT_SettingCategoryTemplate" or template == "WQT_SettingSubCategoryTemplate" then Category(frame, record) end
        for _, key in ipairs({"Button", "ButtonConfirm", "ButtonDecline"}) do
            local button = frame[key]
            if H.Allowed(button) then Font(button.Label or button.Text, false, disabled) end
        end
    end
    local function BindScroll(box, callback)
        if not H.Allowed(box) or not box.RegisterCallback or bound[box] then return end
        bound[box] = callback
        local event = ScrollBoxListMixin and ScrollBoxListMixin.Event and ScrollBoxListMixin.Event.OnInitializedFrame
        if event then
            box:RegisterCallback(event, function(_, frame, data)
                if Ready() then H.Safe(callback, frame, data) end
            end, module)
        end
        if box.EnumerateFrames then for _, frame in box:EnumerateFrames() do callback(frame, frame.GetElementData and frame:GetElementData()) end end
    end
    local function Paint()
        local list = _G.WQT_ListContainer
        if not H.Allowed(list) then return end
        Background(list)
        local top = list.TopBar
        if H.Allowed(top) then
            Dropdown(top.SortDropdown); Dropdown(top.FilterDropdown); Edit(top.SearchBox)
            Action(top.SearchToggle, {"Icon", "Highlight"})
            Font(top.Label)
        end
        Action(list.SettingsButton, {"Icon"})
        Scroll(list.ScrollBar)
        local border = list.BorderContainer
        local box = border and border.QuestScrollBox
        BindScroll(box, QuestRow)
        if H.Allowed(border) then
            local filter = border.FilterBar
            if H.Allowed(filter) then Font(filter.Text); if H.Allowed(filter.ClearButton) then S.CloseButton(filter.ClearButton) end end
        end
        local options = _G.WQT_SettingsFrame
        if H.Allowed(options) then
            Background(options); Font(options.TitleText); Scroll(options.ScrollBar)
            if H.Allowed(options.CloseButton) and not styled[options.CloseButton] then S.CloseButton(options.CloseButton); styled[options.CloseButton] = true end
            BindScroll(options.ScrollBox, SettingRow)
        end
        local tab = _G.WQT_QuestMapTab
        if H.Allowed(tab) and not styled[tab] then
            soft.Button(tab, {"Icon", "IconOverlay"})
            if H.Texture(tab.Icon) and S.SquareIcon then S.SquareIcon(tab.Icon) end
            styled[tab] = true -- Never shrink/reanchor the native tab a second time.
        end
        for _, name in ipairs({"WQT_WorldMapContainer", "WQT_FlightMapContainer", "WQT_OldTaxiMapContainer"}) do
            local frame = _G[name]
            if H.Allowed(frame) and not styled[frame] then soft.Panel(frame, {inset = false}); styled[frame] = true end
        end
        for _, name in ipairs({"WQT_FlightMapContainerButton", "WQT_OldTaxiMapContainerButton"}) do Action(_G[name], {"Icon", "Arrow", "ActiveTexture"}) end
        -- These are addon-owned tooltips; shared GameTooltip/comparison windows
        -- keep native text and semantic colours. No tooltip line font rewrites.
        for _, name in ipairs({"WQT_GameTooltip", "WQT_ShoppingTooltip1", "WQT_ShoppingTooltip2"}) do
            local tooltip = _G[name]
            if H.Allowed(tooltip) and not styled[tooltip] then
                local keep = {}
                for _, region in ipairs(H.Regions(tooltip)) do
                    if H.Texture(region) and region.GetDrawLayer then
                        local layer = region:GetDrawLayer()
                        if layer ~= "BACKGROUND" and layer ~= "BORDER" then keep[region] = region:GetAlpha() end
                    end
                end
                soft.Panel(tooltip, {inset = false})
                for region, alpha in pairs(keep) do region:SetAlpha(alpha) end
                if H.Allowed(tooltip.NineSlice) then S.FadeNineSlice(tooltip.NineSlice) end
                styled[tooltip] = true
            end
        end
        soft.RefreshSoftBorders()
    end
    Apply = function()
        if applying or not Ready() then return end
        applying = true; H.Safe(Paint); applying = false
    end
    module.refresh = function()
        generation = generation + 1
        Apply()
        if not Ready() then return end
        -- Only theme/combat recovery enumerates active viewport frames. This
        -- also catches controls acquired while mutation was blocked in combat.
        for box, callback in pairs(bound) do
            if box.EnumerateFrames then
                for _, frame in box:EnumerateFrames() do callback(frame, frame.GetElementData and frame:GetElementData()) end
            end
        end
    end
    events:SetScript("OnEvent", function(_, event, addon)
        if event == "PLAYER_REGEN_ENABLED" and waiting then waiting = false; module.refresh()
        elseif event == "ADDON_LOADED" and (addon == "WorldQuestTab" or addon == "Blizzard_FlightMap") then H.Queue(module, Apply) end
    end)
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    -- Initial styling follows the target's OnEnable and built-in EUI callback.
    -- Public primitives are idempotent; native settings/registry entries remain
    -- untouched and the target's existing callbacks run before our refinements.
    H.Queue(module, Apply)
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("WorldQuestTab", DefineSkin)
else DefineSkin() end
