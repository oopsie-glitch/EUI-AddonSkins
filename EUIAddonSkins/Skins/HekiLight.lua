local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("HekiLight", "HekiLight", function()
    return type(_G.HekiLightST) == "table"
end, function(S, module)
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(S, module)
    local painted, containers, checkArt, headings, hudFonts = {}, {}, {}, {}, {}
    local generation, waiting, applying = 1, false, false
    local Walk, Refresh
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
        return true
    end
    local function Font(text, heading, hud)
        if not H.Allowed(text) or not text.GetFont then return end
        local kind = text:GetObjectType()
        if kind ~= "FontString" and kind ~= "EditBox" then return end
        local face, size, flags = text:GetFont()
        if not face then return end
        local target, targetFlags = S.GetFont()
        if face ~= target or not hud and (flags or "") ~= (targetFlags or "") then
            local r, g, b, a = text:GetTextColor()
            -- HUD size, outline and colour are explicitly configurable in
            -- HekiLight; only the typeface follows the skin there.
            if hud then text:SetFont(target, size, flags or "") else S.Font(text) end
            text:SetTextColor(r, g, b, a)
        end
        if not hud then
            if heading then text:SetTextColor(S.GetAccentColor())
            else text:SetTextColor(0.88, 0.88, 0.90, 1) end
        end
    end
    local function HudFont(text)
        if not H.Allowed(text) then return end
        local state = hudFonts[text]
        if not state then
            state = {}; hudFonts[text] = state
            H.Hook(text, "SetFont", function()
                if state.busy or not Ready() then return end
                state.busy = true; Font(text, false, true); state.busy = false
            end)
        end
        if not state.busy then state.busy = true; Font(text, false, true); state.busy = false end
    end
    local function Slot(frame, icon, keybind, editLabel)
        if not H.Allowed(frame) then return end
        if frame.SetBackdrop then frame:SetBackdrop(nil) end
        if H.Texture(icon) and S.BorderRegion then S.BorderRegion(frame, icon) end
        HudFont(keybind); HudFont(editLabel)
    end
    local function Displays()
        local state = _G.HekiLightST or {}
        for _, slot in ipairs(state.slots or {}) do
            Slot(slot.frame, slot.iconTexture, slot.keybindText, slot.editLabel)
        end
        local proc = state.procAlertFrame
        if H.Allowed(proc) then
            Slot(proc, proc.iconTexture, proc.keybindText, proc.editLabel)
            HudFont(proc.lockLabel)
        end
        if H.Allowed(state.display) then HudFont(state.display.editBanner) end
        -- No hook on Refresh, icon textures, suggestion polling or proc glows.
    end
    local function Check(frame)
        local art = checkArt[frame]
        if not art then
            local before = {}
            for _, r in ipairs(H.Regions(frame)) do before[r] = true end
            for _, c in ipairs(H.Children(frame)) do before[c] = true end
            soft.Checkbox(frame, {borderInset = 4, hover = 0.08})
            art = {}; checkArt[frame] = art
            for _, r in ipairs(H.Regions(frame)) do if not before[r] then art[#art + 1] = r end end
            for _, c in ipairs(H.Children(frame)) do if not before[c] then art[#art + 1] = c end end
        end
        for _, part in ipairs(art) do
            part:ClearAllPoints(); part:SetPoint("CENTER", frame, "CENTER"); part:SetSize(14, 14)
        end
        for i, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = frame[getter] and H.Texture(frame[getter](frame))
            if mark then
                mark:SetVertexColor(1, 1, 1, 1)
                if i == 1 then local r, g, b = S.GetAccentColor(); mark:SetColorTexture(r, g, b, 1)
                else mark:SetColorTexture(0.4, 0.4, 0.4, 0.8) end
                mark:ClearAllPoints(); mark:SetPoint("CENTER", frame, "CENTER"); mark:SetSize(8, 8)
            end
        end
        -- Preserve the native hit rectangle and checked/radio visibility.
        Font(frame.text or frame.Text)
    end
    local function Slider(frame)
        if frame.GetThumbTexture and H.Texture(frame:GetThumbTexture()) then
            H.LegacySlider(frame)
            local thumb = frame:GetThumbTexture()
            if frame.GetOrientation and frame:GetOrientation() == "HORIZONTAL" then thumb:SetSize(8, 14)
            else thumb:SetWidth(5) end
        else S.ScrollBar(frame, true) end
    end
    local function Heading(text)
        if not H.Allowed(text) then return end
        local value = text.GetText and text:GetText()
        -- HekiLight embeds a fixed gold code in section labels; remove only
        -- that decoration. Spell names/status text elsewhere remain unchanged.
        if type(value) == "string" then
            local cleaned = value:gsub("|cffffcc00", ""):gsub("|r", "")
            if cleaned ~= value then text:SetText(cleaned) end
        end
        Font(text, true)
    end
    local function Button(frame)
        local label = frame.GetFontString and frame:GetFontString()
        if H.Allowed(label) then
            soft.Button(frame)
            if frame.SetBackdrop then frame:SetBackdrop(nil) end
            if S.StateButtonLabel then S.StateButtonLabel(frame) end
            Font(label)
            H.Script(frame, "OnClick", function()
                if Ready() then
                    local parent = frame:GetParent()
                    H.Queue(parent, function() if Ready() then Walk(parent) end end)
                end
            end)
        else
            local texts = {}
            for _, r in ipairs(H.Regions(frame)) do
                if r:GetObjectType() == "FontString" then texts[#texts + 1] = r end
            end
            -- Section headers have text plus a +/- label. A textless button
            -- is the keybinding colour swatch; keep its preview RGB and action.
            if #texts == 2 then
                soft.Button(frame)
                if frame.SetBackdrop then frame:SetBackdrop(nil) end
                headings[frame] = texts
                for _, text in ipairs(texts) do Heading(text) end
            end
        end
    end
    Walk = function(frame)
        if not Ready() or not H.Allowed(frame) then return end
        local kind = frame:GetObjectType()
        if kind == "GameTooltip" or kind == "Cooldown" or kind == "PlayerModel" then return end
        local count = frame.GetNumChildren and frame:GetNumChildren()
        local regions = frame.GetNumRegions and frame:GetNumRegions()
        local state = painted[frame]
        if state and state.generation == generation and state.children == count and state.regions == regions then return end
        if not state then
            state = {}; painted[frame] = state
            if kind == "Frame" or kind == "ScrollFrame" then containers[#containers + 1] = frame end
            H.Script(frame, "OnShow", function() if Ready() then Walk(frame) end end)
        end
        if kind == "CheckButton" then Check(frame)
        elseif kind == "Slider" then Slider(frame)
        elseif kind == "Button" then Button(frame)
        elseif kind == "EditBox" then soft.EditBox(frame, {padInput = false}); Font(frame)
        elseif type(frame.initialize) == "function" then
            soft.Dropdown(frame)
            if ns.BindPopupOwner then ns.BindPopupOwner(S, module, frame) end
        end
        if H.Allowed(frame.ScrollBar) then Slider(frame.ScrollBar) end
        local children = H.Children(frame)
        for _, text in ipairs(H.Regions(frame)) do
            if headings[frame] then Heading(text) else Font(text) end
        end
        -- Do not walk the generated scrollbar art twice or any skin-added
        -- checkbox/border children created while styling this control.
        if kind == "Frame" or kind == "ScrollFrame" then
            for _, child in ipairs(children) do if child ~= frame.ScrollBar then Walk(child) end end
        end
        state.children = frame.GetNumChildren and frame:GetNumChildren()
        state.regions = frame.GetNumRegions and frame:GetNumRegions()
        state.generation = generation
    end
    local panel
    local function Options()
        local scroll = _G.HekiLightScrollFrame
        if not H.Allowed(scroll) then return end
        local root = scroll:GetParent()
        if not H.Allowed(root) or root.name ~= "HekiLight" then return end
        if panel ~= root then
            panel = root
            H.Script(panel, "OnShow", function()
                if not Ready() then return end
                -- Native OnShow may add ignored-spell/keybinding rows. Check
                -- owned container counts, without scanning unchanged pages.
                for i = 1, #containers do Walk(containers[i]) end
            end)
        end
        Walk(panel)
    end
    Refresh = function()
        if applying or not Ready() then return end
        applying = true
        H.Safe(function() Displays(); Options(); soft.RefreshSoftBorders() end)
        applying = false
    end
    -- In either load order, capture completion of the target's native builder.
    -- It initializes the public state/anonymous slots before registering Settings.
    H.Hook(_G, "BuildSettingsPanel", Refresh)
    module.refresh = function() generation = generation + 1; Refresh() end
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    events:SetScript("OnEvent", function()
        if waiting then waiting = false; generation = generation + 1; Refresh() end
    end)
    Refresh()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("HekiLight", DefineSkin)
else DefineSkin() end
