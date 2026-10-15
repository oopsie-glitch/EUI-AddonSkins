local ADDON, ns = ...
-- Standalone skin addons receive their own namespace from WoW.
if ADDON ~= "EUIAddonSkins" then
    ns = EUIAddonSkins and EUIAddonSkins.GetSkinNamespace(ADDON)
    if not ns then return end
    ADDON = "EUIAddonSkins"
end
local unpack = unpack or table.unpack
local WHITE = "Interface\\Buttons\\WHITE8X8"
local function Window() return _G.ThreatClassic2BarFrame end
local function Setup(C, refresh)
    if C.threat then return C.threat end
    local H, S = C.H, C.S
    local state = {painters = {}}
    C.threat = state
    local function Bind(object, methods, paint)
        if not H.Allowed(object) then return end
        if state.painters[object] then state.painters[object](); return end
        local painting = false
        local function Paint()
            if painting or not ns.IsEnabled(C.module) then return end
            if InCombatLockdown and InCombatLockdown() then
                if not state.pending then state.pending = true; refresh() end
                return
            end
            painting = true; H.Safe(paint); painting = false
        end
        state.painters[object] = Paint
        for _, method in ipairs(methods) do H.Hook(object, method, Paint) end
        Paint()
    end
    local function Font(text, title, right)
        local methods = {"SetFont", "SetFontObject"}
        if title then methods[#methods + 1] = "SetTextColor" end
        Bind(text, methods, function()
            local look = state.look
            local path, size, flags = text:GetFont()
            local wanted = title and look.headerSize or right and look.rightSize or look.leftSize
            if issecretvalue and (issecretvalue(path) or issecretvalue(size) or issecretvalue(flags)) then return end
            if path ~= look.font or size ~= wanted or (flags or "") ~= look.flags then text:SetFont(look.font, wanted, look.flags) end
            if title then
                text:SetTextColor(unpack(look.titleColor))
                text:ClearAllPoints(); text:SetPoint("LEFT", Window().header, "LEFT", 6, 0)
                text:SetPoint("RIGHT", Window().header, "RIGHT", -look.iconSize - 12, 0)
            end
        end)
    end
    local function Strip(frame)
        Bind(frame, {"SetBackdrop"}, function() if frame.SetBackdrop then frame:SetBackdrop(nil) end end)
    end
    local function Menu()
        local menu = _G.Menu
        local manager = menu and menu.GetManager and menu.GetManager()
        local list = manager and manager.GetOpenMenu and manager:GetOpenMenu()
        local f = Window()
        if H.Allowed(list) and list.GetOwnerRegion and list:GetOwnerRegion() == f.header and ns.BindPopupList then
            ns.BindPopupList(S, C.module, f.header, list)
        end
        if ns.RefreshPopupMenusNow then ns.RefreshPopupMenusNow() end
    end
    state.Meter = function()
        state.pending = false; state.look = ns.GetMeterStyle(S)
        local f, look = Window(), state.look
        if not H.Allowed(f) or not H.Allowed(f.header) then return end
        Bind(f.bg, {"SetVertexColor", "SetColorTexture"}, function()
            f.bg:SetColorTexture(1, 1, 1, 1); f.bg:SetVertexColor(unpack(state.look.bg))
        end)
        local header = f.header
        if not state.headerBG then
            state.headerBG = header:CreateTexture(nil, "BACKGROUND", nil, -8)
            state.headerBG:SetAllPoints(header)
        end
        Bind(header, {"SetBackdrop", "SetStatusBarTexture", "SetStatusBarColor", "SetSize", "SetHeight"}, function()
            local style = state.look; local color = style.header
            state.headerBG:SetColorTexture(color.r or 0, color.g or 0, color.b or 0, style.headerAlpha)
            H.Fade(header.GetStatusBarTexture and header:GetStatusBarTexture())
            if header.SetBackdrop then header:SetBackdrop(nil) end
            if header:GetHeight() ~= style.headerHeight then header:SetHeight(style.headerHeight) end
        end)
        Strip(header.edgeBackdrop)
        Font(header.text, true)
        H.Fade(f.resizeTexture)
        C.MenuOwner(header)
        H.Script(header, "OnMouseUp", Menu)
        H.Script(header, "OnShow", C.RefreshNow)
        if not state.button then
            local button = CreateFrame("Button", nil, header)
            button:SetPoint("RIGHT", header, "RIGHT", -4, 0)
            button:SetFrameLevel(header:GetFrameLevel() + 3)
            if button.RegisterForClicks then button:RegisterForClicks("LeftButtonUp", "RightButtonUp") end
            button.icon = button:CreateTexture(nil, "OVERLAY"); button.icon:SetAllPoints(button)
            button:SetScript("OnClick", function()
                if not ns.IsEnabled(C.module) then return end
                local action = header.GetScript and header:GetScript("OnMouseUp")
                if action then action(header, "RightButton"); Menu() end
            end)
            H.Script(button, "OnEnter", function() button.icon:SetVertexColor(1, 1, 1, 1) end)
            H.Script(button, "OnLeave", function() button.icon:SetVertexColor(0.55, 0.55, 0.55, 1) end)
            state.button = button
        end
        state.button:SetSize(look.iconSize, look.iconSize)
        local media = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("EllesmereUIDamageMeters")
        state.button.icon:SetTexture(media and "Interface\\AddOns\\EllesmereUIDamageMeters\\Media\\dm_settings.png" or "Interface\\Buttons\\UI-OptionsButton")
        state.button.icon:SetVertexColor(0.55, 0.55, 0.55, 1)
        for _, bar in ipairs(H.Children(f)) do
            if H.Allowed(bar) and bar ~= header and bar:GetObjectType() == "StatusBar" then
                -- Colours, values, percentages, TPS, ignite and column anchors
                -- remain native. There are no threat-update or OnUpdate hooks.
                Bind(bar, {"SetStatusBarTexture", "SetBackdrop"}, function()
                    bar:SetStatusBarTexture(state.look.texture)
                    if bar.SetBackdrop then bar:SetBackdrop(nil) end
                end)
                Strip(bar.edgeBackdrop)
                Font(bar.name); Font(bar.val, false, true); Font(bar.perc, false, true); Font(bar.tps, false, true)
            end
        end
    end
    return state
end

ns.RegisterScopedSkin("ThreatClassic2", "ThreatClassic2", {
    available = function() local f = Window(); return f and f.header and f.bg end,
    softBorders = true, preserveTextColors = true, immediateShow = true,
    hooks = function(C, refresh)
        Setup(C, refresh)
        local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
        C.H.Hook(dialog, "Open", function(_, name) if name == "ThreatClassic2" then C.RefreshNow() end end)
        C.H.Hook(dialog, "FeedGroup", function(_, name) if name == "ThreatClassic2" then C.RefreshNow() end end)
        C.H.Script(Window(), "OnShow", C.RefreshNow)
        C.H.Script(Window(), "OnSizeChanged", C.RefreshNow)
    end,
    roots = function(C)
        C.threat.Meter()
        local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
        local result, seen = {}, {}
        local function Add(value, mode)
            local f = value and (value.frame or value)
            if C.H.Allowed(f) and not seen[f] then
                seen[f] = true; result[#result + 1] = {frame = f, mode = mode}
            end
        end
        Add(dialog and dialog.OpenFrames and dialog.OpenFrames.ThreatClassic2)
        for _, group in pairs(dialog and dialog.BlizOptions and dialog.BlizOptions.ThreatClassic2 or {}) do Add(group, "controls") end
        return result
    end,
})
