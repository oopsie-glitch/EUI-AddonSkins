local ADDON, ns = ...
local unpack = unpack or table.unpack
local MEDIA = "Interface\\AddOns\\EllesmereUIDamageMeters\\Media\\"

-- Use Details' controls and calculation/formatting APIs. This layer only owns
-- presentation; no actor values, click handlers or combat parser are replaced.
function ns.CreateDetailsLayout(H, active, defer, fade)
    local L, windows, originals = {}, {}, {}
    local function Plain(value) return not (issecretvalue and issecretvalue(value)) end
    local function Capture(f)
        if originals[f] then return originals[f] end
        local old = {points = {}, width = f.GetWidth and f:GetWidth(), height = f.GetHeight and f:GetHeight(), level = f.GetFrameLevel and f:GetFrameLevel()}
        for i = 1, f.GetNumPoints and f:GetNumPoints() or 0 do old.points[i] = {f:GetPoint(i)} end
        originals[f] = old
        return old
    end
    local function CanLayout(instance)
        if not active(instance) then return false end
        if InCombatLockdown and InCombatLockdown() then defer(); return false end
        return true
    end
    function L.Title(instance)
        local entry = windows[instance]
        if not entry or not active(instance) then return end
        local name = instance.GetInstanceAttributeText and instance:GetInstanceAttributeText()
        if not Plain(name) or type(name) ~= "string" then return end
        if entry.lastName ~= name then entry.name:SetText(name); entry.lastName = name end
        local combat = instance.GetShowingCombat and instance:GetShowingCombat()
            or instance.GetCombat and instance:GetCombat()
        local seconds = combat and combat.GetCombatTime and combat:GetCombatTime()
        local timer = ""
        if Plain(seconds) and type(seconds) == "number" and seconds >= 0 then
            seconds = math.floor(seconds)
            timer = string.format(" (%d:%02d)", math.floor(seconds / 60), seconds % 60)
        end
        if entry.lastTimer ~= timer then entry.timer:SetText(timer); entry.lastTimer = timer end
        if entry.name.GetStringWidth then
            local width = math.min(entry.available or 10000, entry.name:GetStringWidth())
            local x = (entry.titleLeft or 6) + width
            if entry.timerLeft ~= x then
                entry.timer:ClearAllPoints(); entry.timer:SetPoint("LEFT", entry.frame, "LEFT", x, 0)
                entry.timerLeft = x
            end
        end
    end
    local buttons = {
        {"modo_selecao", "dm_settings.png"}, {"segmento", "dm_undo.png"},
        {"atributo", "dm_sheet.png"}, {"report", "dm_report.png"},
        {"reset", "dm_reset.png"}, {"novo", "dm_open.png"}, {"fechar", "dm_close.png"},
    }
    local nativeTextures = {"GetNormalTexture", "GetHighlightTexture", "GetPushedTexture", "GetDisabledTexture"}
    local nativeRegions = {"texture", "icon", "leftTexture", "rightTexture", "centerTexture"}

    function L.Toolbar(instance)
        local entry = windows[instance]
        if not entry or not CanLayout(instance) or not H.Allowed(instance.baseframe) then return end
        local f = instance.baseframe
        local header = f.cabecalho or {}
        local toolbarOnTop = instance.toolbar_side ~= 2
        local toolbarOnRight = instance.menu_anchor and instance.menu_anchor.side == 2
        local windowLeft = f.GetLeft and f:GetLeft()
        local windowScale = f.GetEffectiveScale and f:GetEffectiveScale() or 1
        local titleLeft, titleRight = 6, f:GetWidth()
        local hasMedia = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("EllesmereUIDamageMeters")
        for _, spec in ipairs(buttons) do
            local value = header[spec[1]]
            local button = value and (value.widget or value)
            if H.Allowed(button) and (not button.IsShown or button:IsShown()) then
                if toolbarOnTop and windowLeft and button.GetLeft and button.GetRight then
                    local edge = toolbarOnRight and button:GetLeft() or button:GetRight()
                    if edge then
                        local scale = button.GetEffectiveScale and button:GetEffectiveScale() or windowScale
                        local x = edge * scale / windowScale - windowLeft
                        if toolbarOnRight then titleRight = math.min(titleRight, x)
                        else titleLeft = math.max(titleLeft, x + 6) end
                    end
                end

                if hasMedia then
                    local control = entry.controls[button]
                    if not control then
                        control = entry.frame:CreateTexture(nil, "OVERLAY")
                        entry.controls[button] = control
                        -- Native toolbar buttons are square and own their scale and anchors.
                        -- Keep the art separate so Details' frame fades do not erase the EUI icon.
                        control:SetAllPoints(button)
                        control:SetTexture(MEDIA .. spec[2])
                        control:SetVertexColor(0.55, 0.55, 0.55, 1)
                        H.Script(button, "OnEnter", function() if active(instance) then control:SetVertexColor(1, 1, 1, 1) end end)
                        H.Script(button, "OnLeave", function() if active(instance) then control:SetVertexColor(0.55, 0.55, 0.55, 1) end end)
                        H.Script(button, "OnHide", function()
                            control:SetAlpha(0)
                            if active(instance) then defer() end
                        end)
                        H.Script(button, "OnShow", function()
                            if CanLayout(instance) then
                                control:SetAlpha(1)
                                defer()
                            end
                        end)
                    end
                    if control:GetAlpha() ~= 1 then control:SetAlpha(1) end
                    for _, getter in ipairs(nativeTextures) do
                        if button[getter] then fade(button[getter](button), instance) end
                    end
                    -- DF buttons draw the foreground image in their own texture.
                    for _, key in ipairs(nativeRegions) do fade(button[key], instance) end
                end
            end
        end
        -- Only the EUI title adapts to the occupied native toolbar space.
        if entry.titleLeft ~= titleLeft then
            entry.name:ClearAllPoints(); entry.name:SetPoint("LEFT", entry.frame, "LEFT", titleLeft, 0)
            entry.titleLeft = titleLeft
        end
        local width = math.max(0, titleRight - titleLeft - 59)
        if entry.available ~= width then
            entry.available = width
            entry.name:SetWidth(width)
            entry.name:SetAlpha(width > 0 and 1 or 0); entry.timer:SetAlpha(width > 0 and 1 or 0)
        end
        L.Title(instance)
    end

    function L.Window(instance, look)
        if not CanLayout(instance) or not H.Allowed(instance.baseframe) then return end
        local f = instance.baseframe
        local entry = windows[instance]
        if not entry then
            entry = {controls = {}}; windows[instance] = entry
            entry.frame = CreateFrame("Frame", nil, f)
            entry.frame:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 0)
            entry.frame:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 0)
            entry.frame:SetFrameLevel(f:GetFrameLevel() + 3); entry.frame:EnableMouse(false)
            -- The fill must sit below native buttons when replacement media is unavailable.
            entry.bg = f:CreateTexture(nil, "BACKGROUND"); entry.bg:SetAllPoints(entry.frame)
            entry.name = entry.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            if entry.name.SetWordWrap then entry.name:SetWordWrap(false) end
            if entry.name.SetJustifyH then entry.name:SetJustifyH("LEFT") end
            entry.timer = entry.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        end
        entry.frame:Show(); entry.frame:SetHeight(look.headerHeight)
        local c = look.header; entry.bg:SetColorTexture(c.r or 0, c.g or 0, c.b or 0, look.headerAlpha)
        entry.bg:SetAlpha(1)
        entry.name:SetFont(look.font, look.headerSize, look.flags)
        entry.timer:SetFont(look.font, look.headerSize, look.flags)
        entry.name:SetTextColor(unpack(look.titleColor)); entry.timer:SetTextColor(0.75, 0.75, 0.75, 1)
        -- The font may have changed since the last width measurement.
        entry.timerLeft = nil
        local nativeTitle = instance.GetTitleBarFontString and instance:GetTitleBarFontString()
        if nativeTitle then fade(nativeTitle.widget or nativeTitle) end
        local header = f.cabecalho or {}
        fade(header.atributo_icon)
        for _, side in ipairs({"resize_direita", "resize_esquerda"}) do
            local grip = f[side]; if grip then fade(grip.texture) end
        end
        if f.lock_button then fade(f.lock_button.label) end
        L.Toolbar(instance)
    end
    function L.Row(row)
        if not CanLayout() then return end
        for _, key in ipairs({"lineText4", "lineText14"}) do
            local text = row[key]
            if H.Allowed(text) and H.Allowed(row.statusbar) then
                Capture(text); text:ClearAllPoints(); text:SetPoint("RIGHT", row.statusbar, "RIGHT", -4, 0)
            end
        end
    end
    function L.Restore()
        for _, entry in pairs(windows) do
            entry.frame:Hide()
            entry.bg:SetAlpha(0)
            for _, control in pairs(entry.controls) do control:SetAlpha(0) end
        end
        for f in pairs(originals) do f:ClearAllPoints() end
        for f, old in pairs(originals) do
            for _, point in ipairs(old.points) do f:SetPoint(unpack(point)) end
            if old.width and old.height and f.SetSize then f:SetSize(old.width, old.height) end
            if old.level and f.SetFrameLevel then f:SetFrameLevel(old.level) end
        end
        originals = {}
    end
    return L
end
