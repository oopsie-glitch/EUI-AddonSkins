local ADDON, ns = ...
local function DefineSkin()

local function Label(f)
    local name = f.GetName and f:GetName()
    return f.Text or (f.GetFontString and f:GetFontString()) or name and _G[name .. "Text"]
end
local function Tone(C, text, owner, heading)
    if not C.H.Allowed(text) or not text.SetTextColor then return end
    C.H.Font(text)
    if owner and owner.IsEnabled and not owner:IsEnabled() then text:SetTextColor(0.5, 0.5, 0.5, 1)
    elseif heading then text:SetTextColor(C.S.GetAccentColor())
    else text:SetTextColor(0.88, 0.88, 0.88, 1) end
end
local function Paint(C, f, kind)
    local H, S = C.H, C.S
    if kind == "CheckButton" then
        S.Checkbox(f, {borderInset = 4, hover = 0.05})
        local r, g, b = S.GetAccentColor()
        for i, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = f[getter] and H.Texture(f[getter](f))
            if mark then
                -- As in DBM: native visibility still owns checked/disabled state.
                mark:SetVertexColor(1, 1, 1, 1)
                if i == 1 then mark:SetColorTexture(r, g, b, 1)
                else mark:SetColorTexture(0.4, 0.4, 0.4, 0.8) end
                mark:ClearAllPoints()
                mark:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
                mark:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 6)
            end
        end
        Tone(C, Label(f), f)
    elseif kind == "Slider" then
        H.LegacySlider(f)
        if H.Allowed(f.NineSlice) then
            for _, art in ipairs(H.Regions(f.NineSlice)) do if H.Texture(art) then H.Fade(art) end end
        end
        local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
        if thumb and f.GetOrientation and f:GetOrientation() == "HORIZONTAL" then
            thumb:SetSize(8, 14)
            if f.IsEnabled and not f:IsEnabled() then thumb:SetColorTexture(0.4, 0.4, 0.4, 0.55) end
        end
        local name = f.GetName and f:GetName()
        if name then
            for _, suffix in ipairs({"Text", "Low", "High"}) do Tone(C, _G[name .. suffix], f) end
        end
    elseif kind == "Button" then Tone(C, Label(f), f) end
end

ns.RegisterScopedSkin("GTFO", "GTFO", {
    softBorders = true,
    immediateShow = true,
    available = function() return type(_G.GTFO) == "table" end,
    preserveTextColors = true,
    roots = function(C)
        local roots = {}
        for _, name in ipairs({"GTFO_MainFrame", "GTFO_IgnoreOptionsFrame"}) do
            local frame = _G[name]
            if C.H.Allowed(frame) then
                -- Canvas categories already live inside Blizzard's settings shell.
                for _, text in ipairs(C.H.Regions(frame)) do
                    if text.GetObjectType and text:GetObjectType() == "FontString" then
                        local title = text.GetText and text:GetText()
                        Tone(C, text, nil, type(title) == "string" and title:sub(1, 5) == "GTFO ")
                    end
                end
                roots[#roots + 1] = {frame = frame, mode = "controls"}
            end
        end
        return roots
    end,
    hooks = function(C, refresh)
        C.H.Hook(_G, "GTFO_RenderOptions", C.RefreshNow)
        C.H.Hook(_G, "GTFO_RefreshOptions", refresh)
    end,
    controlRefresh = function(C, _, source)
        -- Checkbox actions and enable/disable changes repaint one control only.
        if C.gtfoPaint and C.gtfoPaint[source] then C.gtfoPaint[source]() end
    end,
    visit = function(C, f, kind)
        local H, S = C.H, C.S
        if f == _G.GTFO_BrokenExplanationBox then
            C.Panel(f)
            for _, text in ipairs(H.Regions(f)) do
                if text.GetObjectType and text:GetObjectType() == "FontString" then
                    local heading = _G.GTFOLocal and text.GetText and text:GetText() == GTFOLocal.UI_BrokenExplanation_Header
                    Tone(C, text, nil, heading)
                    if heading then
                        text:ClearAllPoints(); text:SetPoint("TOPLEFT", f, "TOPLEFT", 32, -10)
                    end
                end
            end
            return true
        end
        if kind ~= "CheckButton" and kind ~= "Slider" and kind ~= "Button" then return end
        C.gtfoPaint = C.gtfoPaint or setmetatable({}, {__mode = "k"})
        if not C.gtfoPaint[f] then
            if kind == "Button" then
                S.Button(f)
                local hover = f:CreateTexture(nil, "HIGHLIGHT")
                hover:SetAllPoints(f); hover:SetColorTexture(1, 1, 1, 0.08)
                -- Subtle action boundaries, with native hit areas and scripts intact.
                for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                    local edge = f:CreateTexture(nil, "OVERLAY")
                    edge:SetColorTexture(0.25, 0.25, 0.25, 0.65)
                    if side == "TOP" or side == "BOTTOM" then
                        edge:SetPoint(side .. "LEFT", f, side .. "LEFT"); edge:SetPoint(side .. "RIGHT", f, side .. "RIGHT"); edge:SetHeight(1)
                    else
                        edge:SetPoint("TOP" .. side, f, "TOP" .. side); edge:SetPoint("BOTTOM" .. side, f, "BOTTOM" .. side); edge:SetWidth(1)
                    end
                end
            end
            local function Repaint()
                if InCombatLockdown and InCombatLockdown() then C.module.refresh(); return end
                Paint(C, f, kind)
            end
            C.gtfoPaint[f] = Repaint
            H.Script(f, "OnEnable", Repaint); H.Script(f, "OnDisable", Repaint)
            H.Hook(f, "Enable", Repaint); H.Hook(f, "Disable", Repaint); H.Hook(f, "SetEnabled", Repaint)
        end
        Paint(C, f, kind)
        return true
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("GTFO", DefineSkin)
else DefineSkin() end
