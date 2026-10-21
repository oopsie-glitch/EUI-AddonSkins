local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("WaypointUI", "Waypoint UI", function() return _G.WUISettingFrame ~= nil end, function(S, module)
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(S, module)
    local states, fonts, scanned, panels = {}, {}, {}, {}
    local epoch, applying, waiting = 1, false, false
    local Apply, Visit, Scan
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED"); events:RegisterEvent("ADDON_LOADED")
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return false end
        return true
    end
    local function Children(frame)
        if frame.GetFrameChildren then return frame:GetFrameChildren() or {} end
        return H.Children(frame)
    end
    local function FadeArt(frame)
        if not H.Allowed(frame) or not frame.GetTextureFrame then return end
        local art = frame:GetTextureFrame()
        -- UIKit wraps its texture inside a frame, sometimes inside a declared
        -- Background element. Never hide that element or its interactive children.
        for _ = 1, 4 do
            if not H.Allowed(art) then return end
            if art.GetTextureObject then
                H.Fade(art:GetTextureObject())
                local backdrop = art.GetBackdropObject and art:GetBackdropObject()
                if H.Allowed(backdrop) then backdrop:SetAlpha(0) end
                return
            end
            art = art.GetTextureFrame and art:GetTextureFrame()
        end
    end
    local function Font(frame, semantic)
        if not H.Allowed(frame) then return end
        local text = frame.__Text or (frame:GetObjectType() == "FontString" and frame)
        if not H.Allowed(text) or not text.GetFont then return end
        local path, size, flags = text:GetFont()
        local old = fonts[text]
        if not old or old.epoch ~= epoch or old.path ~= path or old.size ~= size or old.flags ~= flags then
            local r, g, b, a
            if semantic and text.GetTextColor then r, g, b, a = text:GetTextColor() end
            S.Font(text, r, g, b)
            if r then text:SetTextColor(r, g, b, a) end
            path, size, flags = text:GetFont()
            old = old or {}; old.epoch, old.path, old.size, old.flags = epoch, path, size, flags; fonts[text] = old
        end
        if not semantic and text.SetTextColor then
            local r, g, b = text:GetTextColor()
            if r ~= 0.9 or g ~= 0.9 or b ~= 0.9 then text:SetTextColor(0.9, 0.9, 0.9) end
        end
        if frame ~= text and not old.hooked then
            old.hooked = true
            H.Hook(frame, "UpdateFont", function() if Ready() then Font(frame, semantic) end end)
        end
    end
    local function Surface(frame, kind)
        if not H.Allowed(frame) then return end
        local state = states[frame]
        if not state then state = {}; states[frame] = state end
        if not state.surface then
            state.surface = kind
            if kind == "panel" then soft.Panel(frame, {inset = false})
            elseif kind == "check" then
                local children, regions = {}, {}
                for _, child in ipairs(H.Children(frame)) do children[child] = true end
                for _, region in ipairs(H.Regions(frame)) do regions[region] = true end
                S.Checkbox(frame, {borderInset = 4, hover = 0.08})
                -- Match the compact, complete outlines used in Quest Completist.
                -- Native UIKit children and the larger hit area stay untouched.
                for _, child in ipairs(H.Children(frame)) do
                    if not children[child] and H.Allowed(child) then child:SetAlpha(0); child:EnableMouse(false) end
                end
                for _, region in ipairs(H.Regions(frame)) do
                    if not regions[region] and H.Texture(region) then
                        region:ClearAllPoints(); region:SetPoint("CENTER", frame, "CENTER"); region:SetSize(14, 14)
                    end
                end
                for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                    local edge = frame:CreateTexture(nil, "OVERLAY")
                    edge:SetColorTexture(0.25, 0.25, 0.25, 1)
                    if side == "TOP" or side == "BOTTOM" then
                        local y = side == "TOP" and 7 or -7
                        edge:SetPoint("LEFT", frame, "CENTER", -7, y); edge:SetPoint("RIGHT", frame, "CENTER", 7, y); edge:SetHeight(1)
                    else
                        local x = side == "LEFT" and -7 or 7
                        edge:SetPoint("TOP", frame, "CENTER", x, 7); edge:SetPoint("BOTTOM", frame, "CENTER", x, -7); edge:SetWidth(1)
                    end
                end
            else soft.Button(frame) end
            FadeArt(frame)
            H.Hook(frame, "background", function() if Ready() then FadeArt(frame) end end)
        end
        return state
    end
    local function Button(frame, selected)
        local state = Surface(frame, "button")
        if not state then return end
        Font(frame.Text)
        if selected ~= nil then
            if not state.accent then
                state.accent = frame:CreateTexture(nil, "OVERLAY")
                state.accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
                state.accent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 5, 5); state.accent:SetWidth(2)
            end
            state.accent:SetColorTexture(S.GetAccentColor()); state.accent:SetAlpha(selected and 1 or 0)
        end
        local text = frame.Text and frame.Text.__Text
        if H.Allowed(text) and frame.IsEnabled then
            local shade = frame:IsEnabled() and 0.9 or 0.5
            local r, g, b = text:GetTextColor()
            if r ~= shade or g ~= shade or b ~= shade then text:SetTextColor(shade, shade, shade) end
        end
    end
    local function Check(frame)
        local state = Surface(frame, "check")
        if not state then return end
        if not state.mark then
            state.mark = frame:CreateTexture(nil, "OVERLAY")
            state.mark:SetPoint("CENTER", frame, "CENTER"); state.mark:SetSize(8, 8)
        end
        if frame.IsEnabled and not frame:IsEnabled() then state.mark:SetColorTexture(0.4, 0.4, 0.4, 0.8)
        else state.mark:SetColorTexture(S.GetAccentColor()) end
        state.mark:SetAlpha(frame:GetChecked() and 1 or 0)
    end
    local function Bar(thumb, track, horizontal)
        for i, frame in ipairs({thumb, track}) do
            if H.Allowed(frame) then
                local state = states[frame]
                if not state then state = {}; states[frame] = state end
                if not state.bar then
                    state.bar = frame:CreateTexture(nil, "OVERLAY")
                    if horizontal then
                        state.bar:SetPoint("LEFT", frame, "LEFT"); state.bar:SetPoint("RIGHT", frame, "RIGHT"); state.bar:SetHeight(i == 1 and 12 or 2)
                    else
                        state.bar:SetPoint("TOP", frame, "TOP"); state.bar:SetPoint("BOTTOM", frame, "BOTTOM"); state.bar:SetWidth(i == 1 and 5 or 2)
                    end
                    FadeArt(frame)
                    H.Hook(frame, "background", function() if Ready() then FadeArt(frame) end end)
                end
                if i == 1 then state.bar:SetColorTexture(S.GetAccentColor())
                else state.bar:SetColorTexture(0.18, 0.18, 0.18, 1) end
            end
        end
    end
    local function ControlState(frame)
        if not Ready() then return end
        if frame.GetChecked and frame.UpdateCheck then Check(frame)
        elseif frame.SetSelected then Button(frame, frame.isSelected)
        elseif frame.IsSelected then Button(frame, frame:IsSelected())
        else Button(frame) end
    end
    Visit = function(frame)
        if not H.Allowed(frame) then return end
        if frame.__Text then Font(frame, false) end
        if frame.__widgetType == 3 then Surface(frame.Background, "panel") end
        if frame.GetChecked and frame.UpdateCheck then
            Check(frame)
        elseif frame.SetSelected and frame.Text then Button(frame, frame.isSelected)
        elseif frame.Row_OnClick and frame.Text then Button(frame, frame:IsSelected())
        elseif frame.GetButtonState and frame.Text and not frame.__widgetType then Button(frame) end
        if (frame.GetChecked and frame.UpdateCheck) or (frame.GetButtonState and frame.Text and not frame.__widgetType) then
            H.Hook(frame, "UpdateAnimation", function() ControlState(frame) end)
            H.Hook(frame, "SetEnabled", function() ControlState(frame) end)
        end
        if frame.RangeThumb and frame.RangeTrack then
            Bar(frame.RangeThumb, frame.RangeTrack, true)
            Button(frame.ForwardButton); Button(frame.BackwardButton)
        elseif frame.Thumb and frame.Track and frame.HitRect then Bar(frame.Thumb, frame.Track, false) end
        if frame.Input and frame.HitRect and frame.Background then Surface(frame.Background, "panel") end
        -- Colour-input Fill/FillTexture, screenshots, binding capture, caret and
        -- placeholder objects remain native. They must not become button chrome.
        if frame.FillTexture and frame.Fill and frame.OnColorChange then Surface(frame, "button") end
        if frame.Picker then Button(frame.Picker) end
        if frame.Content and frame.Content.ButtonContainer then
            local list = frame.Content.ButtonContainer.List
            H.Hook(list, "RenderElements", function()
                if Ready() then Scan(list) end
            end)
        end
        if frame.HandleElementUpdate and frame.List then
            H.Hook(frame, "HandleElementUpdate", function(_, element)
                if Ready() then Scan(element) end
            end)
        end
    end
    Scan = function(frame, force, depth)
        if not Ready() or not H.Allowed(frame) or (depth or 0) > 24 then return end
        local count = frame.GetNumChildren and frame:GetNumChildren() or 0
        local old = scanned[frame]
        if not force and old and old.epoch == epoch and old.count == count then return end
        Visit(frame)
        for _, child in ipairs(Children(frame)) do Scan(child, true, (depth or 0) + 1) end
        scanned[frame] = {epoch = epoch, count = frame.GetNumChildren and frame:GetNumChildren() or 0}
        -- A completed tab render may expose its lazily constructed controls.
        if frame.Layout and frame.Content and frame.ScrollBar then
            H.Hook(frame, "_Render", function() Scan(frame) end)
        end
    end
    local function SettingsReady()
        if not Ready() then return end
        local root = _G.WUISettingFrame
        if not H.Allowed(root) then return end
        Scan(root)
        -- Native SetupSettingUI adds descendants after showing the root. Probe
        -- only its three build containers, never rewalk every tab on a click.
        if root.Content then Scan(root.Content.Container) end
        if root.Sidebar then Scan(root.Sidebar.Tab); Scan(root.Sidebar.Footer) end
    end
    local function HUD(frame, depth)
        if not H.Allowed(frame) or (depth or 0) > 8 then return end
        if frame.__Text then Font(frame, true) end
        for _, child in ipairs(Children(frame)) do HUD(child, (depth or 0) + 1) end
    end
    local function Paint()
        local root = _G.WUISettingFrame
        if H.Allowed(root) then
            H.Script(root, "OnShow", SettingsReady)
            H.Hook(root, "_Render", SettingsReady)
            SettingsReady()
        end
        for _, frame in pairs({menu = root and root.SelectionMenu, prompt = root and root.Prompt,
            shared = _G.WUISharedPrompt, input = _G.WUISharedInputPrompt}) do
            if H.Allowed(frame) then
                Surface(frame.Background or frame, "panel")
                Scan(frame)
                H.Hook(frame, "Open", function() if Ready() then Scan(frame) end end)
            end
        end
        local waypoint = _G.WUIWaypointFrame
        local footer = waypoint and waypoint.Footer
        if H.Allowed(footer) and panels[footer] ~= epoch then HUD(footer); panels[footer] = epoch end
        soft.RefreshSoftBorders()
    end
    Apply = function()
        if applying or not Ready() then return end
        applying = true; H.Safe(Paint); applying = false
    end
    module.refresh = function() epoch = epoch + 1; Apply() end
    events:SetScript("OnEvent", function(_, event, addon)
        if event == "PLAYER_REGEN_ENABLED" and waiting then waiting = false; module.refresh()
        elseif event == "ADDON_LOADED" and addon == "WaypointUI" then H.Queue(module, Apply) end
    end)
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    H.Queue(module, Apply)
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("WaypointUI", DefineSkin)
else DefineSkin() end
