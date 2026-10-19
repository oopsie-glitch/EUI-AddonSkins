local ADDON, ns = ...
local function DefineSkin()
local function Public()
    local ace = LibStub and LibStub("AceAddon-3.0", true)
    return ace and ace.GetAddon and ace:GetAddon("Simulationcraft", true)
end
ns.RegisterModule("Simulationcraft", "SimulationCraft", function()
    local app = Public()
    return app and type(app.GetMainFrame) == "function"
end, function(S, module)
    local app = Public()
    local soft = ns.CreateSoftSkin(S, module)
    local H = ns.CreateSkinHelper(setmetatable({PageButton = soft.SoftPageButton}, {__index = S}), module)
    local styled, checks = {}, {}
    local generation, applying, waiting = 1, false, false
    local Apply
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    local function Owned(f, root)
        if not H.Allowed(f) then return false end
        local parent = f
        for _ = 1, 8 do
            if parent == root then return true end
            parent = parent.GetParent and parent:GetParent()
            if not parent then break end
        end
        return false
    end
    local function Font(text, owner)
        if H.Allowed(text) and text.GetFont then
            local path = text:GetFont()
            if path then
                local shade = owner and owner.IsEnabled and not owner:IsEnabled() and 0.5 or 0.9
                S.Font(text, shade, shade, shade)
            end
        end
    end
    local function Check(f)
        local entry = checks[f]
        if not entry then
            local regions, children = {}, {}
            for _, r in ipairs(H.Regions(f)) do regions[r] = true end
            for _, c in ipairs(H.Children(f)) do children[c] = true end
            S.Checkbox(f, {borderInset = 4, hover = 0.05})
            entry = {}; checks[f] = entry
            for _, r in ipairs(H.Regions(f)) do
                if not regions[r] and H.Texture(r) then entry[#entry + 1] = r end
            end
            for _, c in ipairs(H.Children(f)) do
                if not children[c] and H.Allowed(c) and c:GetObjectType() == "Frame" then entry[#entry + 1] = c end
            end
        end
        local size = math.min(14, f:GetWidth(), f:GetHeight())
        for _, art in ipairs(entry) do
            art:ClearAllPoints(); art:SetPoint("CENTER", f, "CENTER"); art:SetSize(size, size)
        end
        for i, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = f[getter] and H.Texture(f[getter](f))
            if mark then
                mark:SetVertexColor(1, 1, 1, 1)
                if i == 1 then local r, g, b = S.GetAccentColor(); mark:SetColorTexture(r, g, b, 1)
                else mark:SetColorTexture(0.4, 0.4, 0.4, 0.8) end
                mark:ClearAllPoints(); mark:SetPoint("CENTER", f, "CENTER")
                mark:SetSize(math.max(2, size - 4), math.max(2, size - 4))
            end
        end
        Font(f.Text, f)
    end
    local function Scroll(f)
        local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
        if thumb then
            H.LegacySlider(f); thumb:SetVertexColor(1, 1, 1, 1); thumb:SetWidth(5)
        else
            S.ScrollBar(f, true)
            if H.Allowed(f.Back) then soft.SoftPageButton(f.Back, "^") end
            if H.Allowed(f.Forward) then soft.SoftPageButton(f.Forward, "v") end
        end
    end
    local function Paint()
        local frame = _G.SimcFrame
        if not H.Allowed(frame) then return end
        local state = styled[frame]
        if state and state.generation == generation then return end
        if not state then
            state = {}; styled[frame] = state
            S.Panel(frame, {noBorder = true})
            if frame.NineSlice then S.FadeNineSlice(frame.NineSlice) end
            if frame.SetBackdrop then frame:SetBackdrop(nil) end
            -- Quiet matte surface; accent is reserved for active controls.
            state.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            state.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -12)
            state.title:SetText("SimulationCraft")
            H.Script(frame, "OnShow", Apply)
        end
        Font(state.title)
        local button = _G.SimcFrameButton
        if Owned(button, frame) then
            soft.Button(button, {"Text"})
            if S.StateButtonLabel then S.StateButtonLabel(button) end
            Font(button.Text or button:GetFontString(), button)
        end
        -- Do not call SetText, HighlightText, SetFocus or change editor sizing:
        -- native export strings, clipboard handling and selection stay intact.
        if Owned(_G.SimcEditBox, frame) then Font(_G.SimcEditBox) end
        local scroll = _G.SimcScrollFrame
        local bar = scroll and scroll.ScrollBar or _G.SimcScrollFrameScrollBar
        if Owned(bar, frame) then Scroll(bar) end
        if Owned(_G.SimcResizeButton, frame) then H.Resize(_G.SimcResizeButton, true) end
        for _, name in ipairs({"AutomaticClose", "SimcOffspecLoadouts"}) do
            local check = _G[name]
            if Owned(check, frame) then Check(check) end
        end
        state.generation = generation
        soft.RefreshSoftBorders()
    end
    Apply = function()
        if applying or not ns.IsEnabled(module) then return end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return end
        applying = true; H.Safe(Paint); applying = false
    end
    module.refresh = function()
        generation = generation + 1
        Apply()
    end
    -- Observe only completed window construction. Do not touch profile generation,
    -- async spell loading, slash handlers or global/AceGUI factories.
    H.Hook(app, "GetMainFrame", Apply)
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    events:SetScript("OnEvent", function()
        if waiting then waiting = false; Apply() end
    end)
    Apply() -- Also support enabling the collection after the export window exists.
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Simulationcraft", DefineSkin)
else DefineSkin() end
