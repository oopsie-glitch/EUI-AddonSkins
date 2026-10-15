local ADDON, ns = ...
local unpack = unpack or table.unpack
local WHITE = "Interface\\Buttons\\WHITE8X8"

local function Frame(value)
    local kind = type(value)
    if kind == "table" or kind == "userdata" then return value.frame or value.widget or value end
end
local function Regions(C, frame)
    for _, region in ipairs(C.H.Regions(frame)) do
        local kind = region.GetObjectType and region:GetObjectType()
        if kind == "FontString" then
            local r, g, b, a = region:GetTextColor()
            C.S.Font(region, r, g, b)
            region:SetTextColor(r, g, b, a)
        elseif kind == "Texture" then
            local name = region.GetName and region:GetName() or ""
            -- Spell/class icons only: keep range, death and severity indicators native.
            if name:find("Icon") and C.H.Texture(region) then C.S.SquareIcon(region) end
        end
    end
end
local function MediaWidget(widget)
    return widget and (widget.type == "LSM30_Background" or widget.type == "LSM30_Border")
end
local function BuffButton(C, button)
    if not button or type(button.GetObjectType) ~= "function" or button:IsForbidden()
        or InCombatLockdown and InCombatLockdown() then return end
    -- This path deliberately does not scan or install script/method hooks on
    -- protected controls. Only cosmetic regions and existing backdrops change.
    Regions(C, button)
    local backdrop = button.GetBackdrop and button:GetBackdrop()
    if backdrop and button.SetBackdrop and (backdrop.bgFile ~= WHITE or backdrop.edgeFile ~= WHITE or backdrop.edgeSize ~= 1) then
        local color = button.GetBackdropColor and {button:GetBackdropColor()}
        button:SetBackdrop({bgFile = WHITE, edgeFile = WHITE, edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}})
        if color and button.SetBackdropColor then button:SetBackdropColor(unpack(color)) end
        if button.SetBackdropBorderColor then button:SetBackdropBorderColor(0.055, 0.055, 0.055, 1) end
    end
end

ns.RegisterScopedSkin("PallyPower", "PallyPower", {
    softBorders = true, preserveTextColors = true, immediateShow = true,
    borderlessButtons = function(frame)
        local name = frame.GetName and frame:GetName() or ""
        return name:find("^PallyPowerBlessingsFrame") ~= nil
    end,
    available = function() return type(_G.PallyPower) == "table" end,
    hooks = function(C, refresh)
        local P = _G.PallyPower
        for _, method in ipairs({"OnInitialize", "CreateLayout", "UpdateLayout", "ApplySkin", "OnProfileChanged", "OpenConfigWindow"}) do
            C.H.Hook(P, method, C.RefreshNow)
        end
        for _, name in ipairs({"PallyPowerBlessings_Toggle", "PallyPowerBlessings_Refresh"}) do C.H.Hook(_G, name, C.RefreshNow) end
        local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
        C.H.Hook(dialog, "Open", function(_, app) if app == "PallyPower" then C.RefreshNow() end end)
        if ns.BindPopupOwner then ns.BindPopupOwner(C.S, C.module, P.menuFrame or _G.PallyPowerMenuFrame) end
    end,
    roots = function(C)
        local P, roots, seen = _G.PallyPower, {}, {}
        local function Add(value, mode, options)
            local frame = Frame(value)
            if C.H.Allowed(frame) and not seen[frame] then
                seen[frame] = true; roots[#roots + 1] = {frame = frame, mode = mode, options = options}
            end
        end
        Add(_G.PallyPowerBlessingsFrame, nil, {noTopBar = true, noAccent = true})
        Add(_G.PallyPowerConfigFrame, nil, {noTopBar = true, noAccent = true})
        Add(P.configFrame, nil, {noTopBar = true, noAccent = true})
        Add(P.optionsFrame, "controls")
        local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
        Add(dialog and dialog.OpenFrames and dialog.OpenFrames.PallyPower, nil, {noTopBar = true, noAccent = true})
        C.titleBar = P.titleBar or _G.PallyPowerTitleBar
        if C.H.Allowed(C.titleBar) then Add(C.titleBar, "controls") end
        -- Never shell/scan the secure buff hierarchy or its Forever flyout covers.
        BuffButton(C, P.autoButton or _G.PallyPowerAuto)
        BuffButton(C, P.rfButton or _G.PallyPowerRF)
        BuffButton(C, P.auraButton or _G.PallyPowerAura)
        for _, button in pairs(P.classButtons or {}) do BuffButton(C, button) end
        for _, players in pairs(P.playerButtons or {}) do
            for _, button in pairs(players) do BuffButton(C, button) end
        end
        if C.titleBar and not C.H.Allowed(C.titleBar) then BuffButton(C, C.titleBar) end
        return roots
    end,
    visit = function(C, frame, kind, refresh)
        local H, S = C.H, C.S
        if frame == C.titleBar then
            C.Panel(frame); ns.AttachAccent(S, frame)
            if frame.text then local r, g, b = S.GetAccentColor(); H.Font(frame.text, r, g, b) end
            return true
        end
        local name = frame.GetName and frame:GetName() or ""
        if name:find("^PallyPowerBlessingsFrame") then
            -- Native class/aura divider textures are artwork, not shell borders.
            for _, region in ipairs(H.Regions(frame)) do
                local regionName = region.GetName and region:GetName() or ""
                if H.Texture(region) and regionName:find("Line%d*$") then H.Fade(region) end
            end
            if kind == "Button" and frame.SetBackdrop then frame:SetBackdrop(nil) end
        end
        if name == "PallyPowerBlessingsFrameTitle" then
            Regions(C, frame); return true -- Keep drag, credits tooltip and native grid update.
        end
        local column = name:match("^PallyPowerBlessingsFrameClassGroup(%d+)$")
            or name:match("^PallyPowerBlessingsFrameAuraGroup(%d+)$")
        if column then
            C.columns = C.columns or setmetatable({}, {__mode = "k"})
            local fill = C.columns[frame]
            if not fill then
                local line = _G[name .. "Line"]
                if line then
                    fill = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
                    fill:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, 0)
                    fill:SetPoint("BOTTOMRIGHT", line, "BOTTOMLEFT", 82, 0)
                    C.columns[frame] = fill
                    local header = _G[name .. "ClassButton"] or _G[name .. "AuraHeader"]
                    if H.Allowed(header) then
                        header.euiPallyHeader = header:CreateTexture(nil, "BACKGROUND", nil, 2)
                        header.euiPallyHeader:SetAllPoints(header)
                    end
                end
            end
            if fill then
                local r, g, b = S.GetPanelColor()
                local lift = tonumber(column) % 2 == 0 and 0.045 or 0.015
                fill:SetColorTexture(math.min(r + lift, 1), math.min(g + lift, 1), math.min(b + lift, 1), 0.65)
                local header = _G[name .. "ClassButton"] or _G[name .. "AuraHeader"]
                if header and header.euiPallyHeader then
                    header.euiPallyHeader:SetColorTexture(math.min(r + 0.09, 1), math.min(g + 0.09, 1), math.min(b + 0.09, 1), 0.4)
                end
            end
        end
        if C.mediaPreviews and C.mediaPreviews[frame] then return true end
        if C.optionTabs and C.optionTabs[frame] then return true end
        local widget = frame.obj
        if widget then
            if widget.frame == frame then
                if MediaWidget(widget) then
                    C.mediaPreviews = C.mediaPreviews or setmetatable({}, {__mode = "k"})
                    if H.Allowed(frame.displayButton) then
                        C.mediaPreviews[frame.displayButton] = true
                        local backdrop = frame.displayButton.GetBackdrop and frame.displayButton:GetBackdrop()
                        if backdrop and backdrop.edgeFile then
                            local copy = {}; for key, value in pairs(backdrop) do copy[key] = value end
                            copy.edgeFile = nil; frame.displayButton:SetBackdrop(copy)
                        end
                    end
                    for _, key in ipairs({"DLeft", "DRight", "DMiddle"}) do H.Fade(frame[key]) end
                    C.Panel(frame); H.Font(frame.text); H.Font(frame.label)
                    if H.Allowed(frame.dropButton) then S.Dropdown(frame.dropButton) end
                    local function Popup()
                        if InCombatLockdown and InCombatLockdown() then C.RefreshNow(); return end
                        local popup = widget.dropdown
                        if not H.Allowed(popup) then return end
                        C.Panel(popup)
                        H.Scan(popup, C.RefreshNow, function(row, rowKind)
                            if rowKind == "Slider" then
                                H.LegacySlider(row)
                                local thumb = row.GetThumbTexture and row:GetThumbTexture()
                                if thumb then thumb:SetSize(8, 18) end
                                return true
                            end
                            if rowKind == "Button" and row.obj == widget and row.text then
                                H.Action(row, {"text", "check"}); H.Font(row.text)
                                if row.check then local r, g, b = S.GetAccentColor(); row.check:SetVertexColor(r, g, b, 1) end
                                return true
                            end
                        end)
                    end
                    H.Hook(widget, "ToggleDrop", Popup)
                    H.Script(frame.dropButton, "OnClick", Popup)
                    Popup()
                    return true
                end
                if widget.type == "CheckBox" and widget.checkbg and widget.check then
                    C.checkPainters = C.checkPainters or setmetatable({}, {__mode = "k"})
                    local Paint = C.checkPainters[widget]
                    if not Paint then
                        Paint = function()
                            if InCombatLockdown and InCombatLockdown() then refresh(); return end
                            local r, g, b = S.GetAccentColor()
                            widget.checkbg:SetColorTexture(0.08, 0.08, 0.09, 1)
                            widget.checkbg:SetTexCoord(0, 1, 0, 1); widget.checkbg:SetSize(14, 14)
                            widget.check:ClearAllPoints(); widget.check:SetPoint("CENTER", widget.checkbg, "CENTER")
                            widget.check:SetSize(8, 8); widget.check:SetTexCoord(0, 1, 0, 1)
                            widget.check:SetVertexColor(1, 1, 1, 1)
                            if widget.check.SetBlendMode then widget.check:SetBlendMode("BLEND") end
                            widget.check:SetColorTexture(widget.disabled and 0.5 or r, widget.disabled and 0.5 or g, widget.disabled and 0.5 or b, 1)
                            if widget.highlight then widget.highlight:SetColorTexture(r, g, b, 0.12); widget.highlight:SetTexCoord(0, 1, 0, 1) end
                            H.Font(widget.text)
                        end
                        C.checkPainters[widget] = Paint
                        H.Hook(widget, "SetType", Paint); H.Hook(widget, "SetDisabled", Paint)
                    end
                    Paint()
                    return true
                end
                if widget.type == "Heading" then
                    for _, region in ipairs(H.Regions(frame)) do
                        if H.Texture(region) then H.Fade(region) else H.Font(region) end
                    end
                    return true
                end
                if widget.type == "Frame" then
                    for _, region in ipairs(H.Regions(frame)) do
                        local path = region.GetTexture and region:GetTexture()
                        if path == 131080 or type(path) == "string" and path:find("UI%-DialogBox%-Header") then H.Fade(region) end
                    end
                    if widget.sizer_se then H.Resize(widget.sizer_se, true) end
                    H.Font(widget.titletext)
                end
                if widget.type == "TabGroup" then
                    C.optionTabs = C.optionTabs or setmetatable({}, {__mode = "k"})
                    for _, tab in pairs(widget.tabs or {}) do
                        if H.Allowed(tab) then
                            if not C.optionTabs[tab] then
                                for _, region in ipairs(H.Regions(tab)) do
                                    if H.Texture(region) then H.Fade(region) end
                                end
                                C.optionTabs[tab] = true
                            end
                            H.Tab(tab, tab.selected and true or false)
                        end
                    end
                    H.Hook(widget, "SelectTab", C.RefreshNow)
                    H.Hook(widget, "SetTabs", refresh)
                end
            elseif widget.type == "Frame" and widget.statustext
                and widget.statustext.GetParent and widget.statustext:GetParent() == frame then
                C.Panel(frame); H.Font(widget.statustext); return true
            end
        end
        if kind == "Slider" then
            H.LegacySlider(frame)
            local thumb = frame.GetThumbTexture and frame:GetThumbTexture()
            if thumb then thumb:SetSize(frame.GetOrientation and frame:GetOrientation() == "HORIZONTAL" and 10 or 8,
                frame.GetOrientation and frame:GetOrientation() == "HORIZONTAL" and 16 or 18) end
            return true
        end
        if kind == "Button" and name:find("CloseButton$") then S.CloseButton(frame); return true end
        if kind == "Button" and name:find("Resize$") then H.Resize(frame, true); return true end
        if kind == "Button" then
            local keep = {"Text", "text", "euiPallyHeader"}
            local count = 0
            for _, region in ipairs(H.Regions(frame)) do
                local regionName = region.GetName and region:GetName() or ""
                if H.Texture(region) and regionName:find("Icon") then
                    count = count + 1
                    local key = "euiPallyIcon" .. count
                    frame[key] = region; keep[#keep + 1] = key
                    S.SquareIcon(region)
                end
            end
            if count > 0 then H.Action(frame, keep); return true end
        end
    end,
})
