local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("Spy", "Spy", function()
    return _G.Spy and type(_G.Spy.CreateMainWindow) == "function"
end, function(S, module)
    local spy = _G.Spy
    local ForeverLook
    S = ns.CreateSoftSkin(S, module, function(button)
        local f = spy.MainWindow
        return ns.IsEnabled(module) and ForeverLook and ForeverLook() and f and
            (button == f.CloseButton or button == f.LeftButton or button == f.RightButton
            or button == f.ClearButton or button == f.StatsButton or button == f.CountButton)
    end)
    local H = ns.CreateSkinHelper(S, module)
    local windows, styled, layers, options = {}, {}, {}, {}
    local config = LibStub and LibStub("AceConfigDialog-3.0", true)
    local refresh, waiting
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")


    -- Keep the released Standard primitives intact; Forever art lives on
    -- unregistered, mouse-inert hosts, never on secure targeting buttons.
    local APP = "EUIAddonSkinsSpy"
    local foreverWindows, rowArt, rowSlots, controlArt = {}, {}, {}, {}
    local settingsRegistered
    local reasonDialogs = {}
    local unpack = unpack or table.unpack
    local pack = table.pack or function(...) return {n = select("#", ...), ...} end
    local function Locked() return InCombatLockdown and InCombatLockdown() end
    local function SafeValue(value) return not (issecretvalue and issecretvalue(value)) end
    local function Owned(f)
        return f and f.GetObjectType and not (f.IsForbidden and f:IsForbidden())
    end
    ForeverLook = function()
        local EUI = _G.EllesmereUI
        if not (S.GetPanelColor and EUI and EUI.IS_FOREVER and EUI.ForeverBorder
            and EUI.ForeverBorderSeat and EUI.ForeverBorderShown) then return false end
        local pref = EUIAddonSkinsDB and EUIAddonSkinsDB.spy
        if pref and pref.style == "standard" then return false end
        if pref and pref.style == "forever" then return true end
        if not (EUI.ProfileWindowSkinLook and EUI.GetActiveProfileData) then return false end
        local db = _G.EllesmereUIDB
        return EUI.ProfileWindowSkinLook(EUI.GetActiveProfileData(), db and db.fonts) == "forever"
    end
    local nativeFont = S.Font
    S.Font = function(text, r, g, b)
        if not ForeverLook() or r ~= nil or not text.GetTextColor then return nativeFont(text, r, g, b) end
        local cr, cg, cb, ca = text:GetTextColor()
        if not (SafeValue(cr) and SafeValue(cg) and SafeValue(cb) and SafeValue(ca)) then return end
        nativeFont(text, cr, cg, cb)
        text:SetTextColor(cr, cg, cb, ca)
    end
    local function Alpha(texture, alpha)
        if not (texture and texture.SetAlpha and texture.GetAlpha)
            or texture.IsForbidden and texture:IsForbidden() then return end
        local current = texture:GetAlpha()
        if SafeValue(current) and current ~= alpha then texture:SetAlpha(alpha) end
    end
    local function Host(parent, level)
        local host = CreateFrame("Frame", nil, parent)
        host:SetAllPoints(parent)
        host:SetFrameLevel(level or parent:GetFrameLevel())
        host:EnableMouse(false)
        if host.SetMouseMotionEnabled then host:SetMouseMotionEnabled(false) end
        return host
    end
    local function Rim(host)
        local EUI = _G.EllesmereUI
        local rim = EUI.ForeverBorder(host, "ARTWORK", 1, nil, "textured")
        if rim then EUI.ForeverBorderSeat(rim, host, "TOPLEFT", 0, 0, 0, 0) end
        return rim
    end
    local function ShowRim(rim, shown)
        if rim and rim.on ~= shown then _G.EllesmereUI.ForeverBorderShown(rim, shown) end
    end
    local function Surface(host, managed, header)
        local plate = host:CreateTexture(nil, "BACKGROUND", nil, 1)
        local grain = host:CreateTexture(nil, "BACKGROUND", nil, 2)
        plate:SetAllPoints(host); grain:SetAllPoints(host)
        -- Same material as RestedXP: EUI exports the rim, not its warm fill.
        -- A coloured source multiplied by the same gradient squares the tint.
        -- Use one warm paint pass on a neutral source for the main material.
        if managed then plate:SetColorTexture(1, 1, 1, 1)
        else plate:SetColorTexture(0.165, 0.115, 0.075, 1) end
        local paint = managed and {header = header} or nil
        if plate.SetGradient and CreateColor then
            local low, high
            if managed then
                low = header and CreateColor(0.135, 0.085, 0.042, 1) or CreateColor(0.100, 0.065, 0.040, 1)
                high = header and CreateColor(0.250, 0.165, 0.080, 1) or CreateColor(0.175, 0.115, 0.065, 1)
            else
                low, high = CreateColor(0.120, 0.084, 0.055, 1), CreateColor(0.165, 0.115, 0.075, 1)
            end
            if paint then paint.low, paint.high = low, high
            else plate:SetGradient("VERTICAL", low, high) end
        end
        if paint then
            -- Match RestedXP: coverage belongs in gradient/vertex paint, with
            -- explicit alpha blending, rather than opaque stops plus SetAlpha.
            plate:SetBlendMode("BLEND"); grain:SetBlendMode("BLEND")
        end
        grain:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background", "REPEAT", "REPEAT")
        grain:SetHorizTile(true); grain:SetVertTile(true)
        grain:SetVertexColor(0.56, 0.44, 0.32, 1)
        local mask
        local mode = Enum and Enum.UITextureSliceMode and Enum.UITextureSliceMode.Stretched
        if mode and host.CreateMaskTexture and plate.AddMaskTexture then
            mask = host:CreateMaskTexture()
            mask:SetTexture("Interface\\AddOns\\EUIAddonSkins\\Media\\RestedXPFill.tga",
                "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetTextureSliceMargins(8, 8, 8, 8); mask:SetTextureSliceMode(mode)
            mask:SetAllPoints(host); plate:AddMaskTexture(mask); grain:AddMaskTexture(mask)
        end
        return plate, grain, paint, mask
    end
    local function PaintBackground(entry, target)
        local paint = entry.paint
        if paint.alpha ~= target then
            paint.alpha = target
            local grainAlpha = target * 0.12
            local plateAlpha = (target - grainAlpha) / (1 - grainAlpha)
            if paint.low then
                if paint.header then
                    paint.low:SetRGBA(0.135, 0.085, 0.042, plateAlpha)
                    paint.high:SetRGBA(0.250, 0.165, 0.080, plateAlpha)
                else
                    paint.low:SetRGBA(0.100, 0.065, 0.040, plateAlpha)
                    paint.high:SetRGBA(0.175, 0.115, 0.065, plateAlpha)
                end
                entry.plate:SetGradient("VERTICAL", paint.low, paint.high)
            else
                entry.plate:SetVertexColor(paint.header and 0.250 or 0.175, paint.header and 0.165 or 0.115, paint.header and 0.080 or 0.065, plateAlpha)
            end
            entry.grain:SetVertexColor(0.56, 0.44, 0.32, grainAlpha)
        end
        local shown = target > 0
        if paint.shown ~= shown then
            entry.plate:SetShown(shown); entry.grain:SetShown(shown)
            paint.shown = shown
        end
    end
    local function BackgroundOpacity()
        local preferences = EUIAddonSkinsDB and EUIAddonSkinsDB.spy
        local value = preferences and preferences.opacity
        if type(value) == "number" and SafeValue(value) and value == value then
            return math.max(0, math.min(1, value))
        end
        return 0.75
    end
    local function PanelAlpha()
        local _, _, _, alpha = S.GetPanelColor()
        if type(alpha) ~= "number" or not SafeValue(alpha) or alpha ~= alpha then return 0.92 end
        return math.max(0, math.min(1, alpha))
    end
    local CONTROL_SCALE = 0.5
    local fixedIcons = {
        CloseButton = {"atlas", "uitools-icon-close"},
        LeftButton = {"file", "Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-left.png"},
        RightButton = {"file", "Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-right.png"},
    }
    local function SnapshotControl(entry)
        -- Includes EUI's replacement X/arrow and flat block, not just the
        -- now-empty normal texture slots. This is one discovery per control.
        for _, region in ipairs({entry.button:GetRegions()}) do
            if region.GetAlpha and not entry.native[region] then
                entry.native[region] = {alpha = region:GetAlpha()}
            end
        end
    end
    local function ReflectControl(entry)
        if Locked() then waiting = true; return end
        local button = entry.button
        local active = ns.IsEnabled(module) and ForeverLook()
        if not active then
            if entry.active == false then return end
            for region, saved in pairs(entry.native) do Alpha(region, saved.alpha) end
            Alpha(entry.seat, 0); ShowRim(entry.rim, false)
            entry.active = false
            return
        end
        local w, h = button:GetWidth(), button:GetHeight()
        if not (SafeValue(w) and SafeValue(h)) then return end
        local width, height = math.min(14, w - 2), math.min(14, h - 2)
        if width <= 0 or height <= 0 then Alpha(entry.seat, 0); return end
        local geometry = entry.w ~= w or entry.h ~= h
        if geometry then
            entry.w, entry.h = w, h
            entry.seat:SetSize(width, height)
            local size = math.max(1, math.min(9, math.min(width, height) - 3)) / CONTROL_SCALE
            entry.icon:SetSize(size, size)
        end
        local enabled = not button.IsEnabled or button:IsEnabled()
        local pressed = enabled and (entry.pressed or button.GetButtonState and button:GetButtonState() == "PUSHED") or false
        local hover = enabled and entry.hover or false
        local fixed = fixedIcons[entry.role]
        local texture
        if not fixed then
            if not enabled and button.GetDisabledTexture then texture = button:GetDisabledTexture() end
            if not texture and pressed and button.GetPushedTexture then texture = button:GetPushedTexture() end
            texture = texture or button.GetNormalTexture and button:GetNormalTexture()
        end
        local path = fixed and fixed[2] or texture and texture.GetTexture and texture:GetTexture()
        if not SafeValue(path) then return end
        -- Empty disabled/pushed slots use the current normal icon.
        if not fixed and (not path or path == "") and button.GetNormalTexture then
            texture = button:GetNormalTexture()
            path = texture and texture.GetTexture and texture:GetTexture()
        end
        if not SafeValue(path) then return end
        if entry.active and not geometry and entry.enabled == enabled and entry.down == pressed
            and entry.over == hover and entry.path == path then return end
        entry.enabled, entry.down, entry.over, entry.path, entry.active = enabled, pressed, hover, path, true
        for region in pairs(entry.native) do Alpha(region, 0) end
        Alpha(entry.seat, 1); ShowRim(entry.rim, true)
        if fixed and fixed[1] == "atlas" and entry.icon.SetAtlas then entry.icon:SetAtlas(path)
        elseif path and path ~= "" then entry.icon:SetTexture(path) end
        entry.icon:ClearAllPoints()
        entry.icon:SetPoint("CENTER", entry.host, "CENTER", 0, pressed and -1 / CONTROL_SCALE or 0)
        -- Keep colour baked into native state icons (for example on/off).
        if fixed then entry.icon:SetVertexColor(0.91, 0.71, 0.43, enabled and 1 or 0.55)
        else entry.icon:SetVertexColor(1, 1, 1, enabled and 1 or 0.55) end
        local shade = pressed and 0.035 or hover and 0.12 or 0.065
        entry.fill:SetColorTexture(shade, shade * 0.72, shade * 0.48, 0.9)
        local EUI = _G.EllesmereUI
        if entry.rim and EUI.ForeverBorderPaint then
            EUI.ForeverBorderPaint(entry.rim, 1, 1, 1, not enabled and 0.55 or hover and 1 or 0.85)
        end
    end
    local function SyncControl(button, forever, role)
        local entry = controlArt[button]
        if not entry and forever and H.Allowed(button) then
            local seat = Host(button)
            seat:ClearAllPoints(); seat:SetPoint("CENTER", button, "CENTER", 0, 0)
            local host = Host(seat)
            host:SetScale(CONTROL_SCALE)
            local icon = host:CreateTexture(nil, "OVERLAY", nil, 5)
            local fill = host:CreateTexture(nil, "BACKGROUND")
            fill:SetPoint("TOPLEFT", host, "TOPLEFT", 4, -4)
            fill:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -4, 4)
            entry = {button = button, seat = seat, host = host, icon = icon, fill = fill,
                rim = Rim(host), role = role, native = {}}
            controlArt[button] = entry
            SnapshotControl(entry)
            local function Reflect() ReflectControl(entry) end
            button:HookScript("OnEnter", function() entry.hover = true; Reflect() end)
            button:HookScript("OnLeave", function() entry.hover, entry.pressed = false, false; Reflect() end)
            button:HookScript("OnMouseDown", function() entry.pressed = true; Reflect() end)
            button:HookScript("OnMouseUp", function() entry.pressed = false; Reflect() end)
            button:HookScript("OnEnable", Reflect)
            button:HookScript("OnDisable", Reflect)
            for setter, getter in pairs({SetNormalTexture = "GetNormalTexture", SetPushedTexture = "GetPushedTexture",
                SetDisabledTexture = "GetDisabledTexture", SetButtonState = false}) do
                H.Hook(button, setter, function()
                    if Locked() then waiting = true; return end
                    -- A native setter can replace a slot's Texture object.
                    local texture = getter and button[getter] and button[getter](button)
                    if texture and texture.GetAlpha then
                        if not entry.native[texture] then entry.native[texture] = {alpha = texture:GetAlpha()} end
                        if texture:GetAlpha() ~= 0 then entry.active = nil end
                    end
                    Reflect()
                end)
            end
        end
        if not entry then return end
        if forever then ReflectControl(entry)
        else
            if entry.active ~= false then
                for region, saved in pairs(entry.native) do Alpha(region, saved.alpha) end
                Alpha(entry.seat, 0); ShowRim(entry.rim, false); entry.active = false
            end
        end
    end
    local controls = {"CloseButton", "LeftButton", "RightButton", "ClearButton", "StatsButton", "CountButton"}
    local controlOrder = {"CloseButton", "RightButton", "LeftButton", "ClearButton", "StatsButton"}
    local SyncHeader
    local function SavePoints(region)
        local points = {}
        if region.GetNumPoints then
            for i = 1, region:GetNumPoints() do points[i] = {region:GetPoint(i)} end
        end
        return points
    end
    local function RestorePoints(region, points)
        region:ClearAllPoints()
        for _, point in ipairs(points) do region:SetPoint(unpack(point)) end
    end
    local function Anchor(region, point, relative, relativePoint, x, y)
        if region.GetNumPoints and region:GetNumPoints() == 1 then
            local p, r, rp, px, py = region:GetPoint(1)
            if p == point and r == relative and rp == relativePoint and px == x and py == y then return end
        end
        region:ClearAllPoints(); region:SetPoint(point, relative, relativePoint, x, y)
    end
    local function TrackHeaderRegion(f, layout, region)
            if not region or layout.regions[region] then return end
            layout.regions[region] = SavePoints(region)
            if region == f.Title or region == (f.CountFrame and f.CountFrame.Text) then
                H.Hook(region, "SetText", function()
                    SyncHeader(f, ns.IsEnabled(module) and ForeverLook())
                end)
            end
            if region == (f.CountFrame and f.CountFrame.Text) then
                local function CounterChanged() SyncHeader(f, ns.IsEnabled(module) and ForeverLook()) end
                H.Hook(region, "SetAlpha", CounterChanged)
                H.Hook(region, "Show", CounterChanged)
                H.Hook(region, "Hide", CounterChanged)
            end
            -- Only observe owned native anchors. Never touch row anchors or a
            -- global frame/menu factory. Ignore the adapter's own writes.
            H.Hook(region, "SetPoint", function()
                if layout.writing then return end
                layout.regions[region] = SavePoints(region)
                SyncHeader(f, ns.IsEnabled(module) and ForeverLook())
            end)
    end
    SyncHeader = function(f, forever, capture)
        if f ~= spy.MainWindow or not f.Title then return end
        if Locked() then waiting = true; return end
        local entry = foreverWindows[f]
        if not entry then return end
        local layout = entry.headerLayout
        if not layout then
            if not forever then return end
            local font, size, flags = f.Title:GetFont()
            layout = {regions = {}, titleFont = {font, size, flags}, titleWidth = f.Title:GetWidth(), titleHeight = f.Title:GetHeight(),
                wordWrap = f.Title.GetWordWrap and f.Title:GetWordWrap(),
                nonSpaceWrap = f.Title.GetNonSpaceWrap and f.Title:GetNonSpaceWrap()}
            if f.GetResizeBounds and f.SetResizeBounds then
                local minW, minH, maxW, maxH = f:GetResizeBounds()
                if SafeValue(minW) and SafeValue(minH) and SafeValue(maxW) and SafeValue(maxH) then
                    layout.bounds = {minW, minH, maxW, maxH}
                end
            end
            entry.headerLayout = layout
        end
        if layout.writing then return end
        if entry.well then Alpha(entry.well, f:GetHeight() > 34 and 1 or 0) end
        TrackHeaderRegion(f, layout, f.Title)
        for _, key in ipairs(controls) do TrackHeaderRegion(f, layout, f[key]) end
        local counter = f.CountFrame and f.CountFrame.Text
        TrackHeaderRegion(f, layout, counter)
        if capture then layout.titleWidth = f.Title:GetWidth() end
        layout.writing = true
        if not forever then
            if layout.active then
                for region, points in pairs(layout.regions) do RestorePoints(region, points) end
                f.Title:SetWidth(layout.titleWidth); f.Title:SetHeight(layout.titleHeight)
                f.Title:SetFont(unpack(layout.titleFont))
                if layout.boundMin then f:SetResizeBounds(unpack(layout.bounds)); layout.boundMin = nil end
                if f.Title.SetWordWrap and layout.wordWrap ~= nil then f.Title:SetWordWrap(layout.wordWrap) end
                if f.Title.SetNonSpaceWrap and layout.nonSpaceWrap ~= nil then f.Title:SetNonSpaceWrap(layout.nonSpaceWrap) end
                entry.host:ClearAllPoints(); entry.host:SetAllPoints(f)
                layout.active = false
            end
            layout.writing = false
            return
        end
        local width, title = f:GetWidth(), f.Title
        local font, size, flags = title:GetFont()
        if type(size) == "number" and SafeValue(size) and size < 14 then title:SetFont(font, 14, flags) end
        if not SafeValue(width) then layout.writing = false; return end
        if layout.bounds and (capture or not layout.active) then
            -- Do not clamp an existing custom narrow size; widen the resize
            -- floor only once the native window already accommodates it.
            local minimum = math.max(layout.bounds[1], math.min(180, width))
            if layout.boundMin ~= minimum then
                f:SetResizeBounds(minimum, layout.bounds[2], layout.bounds[3], layout.bounds[4])
                layout.boundMin = minimum
            end
        end
        local counterWidth = 0
        if counter and (not counter.IsVisible or counter:IsVisible()) then
            local alpha = counter.GetAlpha and counter:GetAlpha() or 1
            local size = counter:GetStringWidth()
            if SafeValue(alpha) and SafeValue(size) and alpha > 0 and size > 0 then
                counterWidth = size + 6
            end
        end
        local total, number, tallest = 0, 0, 0
        for _, key in ipairs(controlOrder) do
            local button = f[key]
            if button and (not button.IsShown or button:IsShown()) then
                total, number = total + button:GetWidth(), number + 1
                tallest = math.max(tallest, button:GetHeight())
            end
        end
        local gap = number > 1 and math.min(2, math.max(0, (width - 11 - total) / (number - 1))) or 0
        local rightInset = math.min(12, math.max(3, width - 3 - total - gap * math.max(0, number - 1)))
        local countButton = f.CountButton
        local countWidth = math.max(counterWidth > 0 and counterWidth - 6 or 0,
            countButton and countButton:IsShown() and countButton:GetWidth() or 0)
        local counterSpace = countWidth > 0 and countWidth + 6 or 0
        local groupWidth = total + gap * math.max(0, number - 1)
        local available = width - 12 - rightInset - counterSpace - groupWidth - 8
        -- Prefer one integrated header. A narrow native window cannot fit all
        -- hitboxes plus title/counter; wrap inside the same header as a fallback.
        local wrapped = available < 24
        local _, fontSize = title:GetFont()
        local line = type(fontSize) == "number" and math.max(1, fontSize) or layout.titleHeight
        local top, controlY, titleY
        if wrapped then
            available = math.max(1, width - 24 - counterWidth)
        end
        available = math.max(1, available)
        if title:GetWidth() ~= available then title:SetWidth(available) end
        if title.SetWordWrap and (not title.GetWordWrap or title:GetWordWrap() ~= wrapped) then title:SetWordWrap(wrapped) end
        if title.SetNonSpaceWrap and (not title.GetNonSpaceWrap or title:GetNonSpaceWrap() ~= wrapped) then title:SetNonSpaceWrap(wrapped) end
        local titleHeight = line
        if title.GetStringHeight then
            local measured = title:GetStringHeight()
            if SafeValue(measured) and measured and measured > 0 then titleHeight = math.max(line, measured) end
        end
        if title:GetHeight() ~= titleHeight then title:SetHeight(titleHeight) end
        if wrapped then
            controlY = -33 + tallest / 2
            titleY = controlY + tallest / 2 + 2 + titleHeight / 2
            top = titleY + titleHeight / 2 + 2
        else
            controlY, titleY = -18, -18
            top = 0
        end
        Anchor(title, "LEFT", f, "TOPLEFT", 12, titleY)
        local firstLine = math.max(line, math.min(titleHeight, counter and counter.GetStringHeight and counter:GetStringHeight() or line))
        local counterY = wrapped and titleY + titleHeight / 2 - firstLine / 2 or titleY
        if counter then Anchor(counter, "RIGHT", f, "TOPRIGHT", -12, counterY) end
        if countButton then Anchor(countButton, "RIGHT", f, "TOPRIGHT", -rightInset, counterY) end
        local offset = rightInset + (wrapped and 0 or counterSpace)
        for _, key in ipairs(controlOrder) do
            local button = f[key]
            if button and (not button.IsShown or button:IsShown()) then
                Anchor(button, "RIGHT", f, "TOPRIGHT", -offset, controlY)
                offset = offset + button:GetWidth() + gap
            end
        end
        if layout.top ~= top or not layout.active then
            entry.host:ClearAllPoints()
            entry.host:SetPoint("TOPLEFT", f, "TOPLEFT", 0, top)
            entry.host:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, -9)
            layout.top = top
        end
        -- One content rule below the integrated header, never a toolbar band.
        if entry.seam and layout.dividerY ~= -33 then
            Anchor(entry.seam, "TOPLEFT", f, "TOPLEFT", 5, -32)
            entry.seam:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -32)
            layout.dividerY = -33
        end
        layout.active, layout.writing = true, false
    end
    local function RowEdges(host, omitTop)
        local top
        if not omitTop then
            top = host:CreateTexture(nil, "ARTWORK")
            top:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
            top:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, 0)
            top:SetHeight(1); top:SetColorTexture(0.62, 0.43, 0.23, 0.60)
        end
        local bottom = host:CreateTexture(nil, "ARTWORK")
        bottom:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 0, 0)
        bottom:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
        bottom:SetHeight(1); bottom:SetColorTexture(0.20, 0.12, 0.055, 0.75)
        local left = host:CreateTexture(nil, "ARTWORK")
        left:SetPoint("TOPLEFT", host, "TOPLEFT", 0, -1)
        left:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 0, 1)
        left:SetWidth(1); left:SetColorTexture(0.38, 0.25, 0.13, 0.50)
        local right = host:CreateTexture(nil, "ARTWORK")
        right:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, -1)
        right:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 1)
        right:SetWidth(1); right:SetColorTexture(0.25, 0.15, 0.07, 0.55)
        return {top = top, bottom = bottom, left = left, right = right}
    end
    local function PaintRowHover(entry, hovered)
        if entry.paintedHover == hovered then return end
        entry.paintedHover = hovered
        local e = entry.edges
        if hovered then
            e.top:SetColorTexture(0.92, 0.70, 0.38, 0.95)
            e.bottom:SetColorTexture(0.66, 0.42, 0.19, 0.75)
            e.left:SetColorTexture(0.78, 0.52, 0.25, 0.90)
            e.right:SetColorTexture(0.78, 0.52, 0.25, 0.90)
        else
            e.top:SetColorTexture(0.62, 0.43, 0.23, 0.60)
            e.bottom:SetColorTexture(0.20, 0.12, 0.055, 0.75)
            e.left:SetColorTexture(0.38, 0.25, 0.13, 0.50)
            e.right:SetColorTexture(0.25, 0.15, 0.07, 0.55)
        end
    end
    local function RowHover(entry, row, entered)
        if entry.row ~= row then return end
        entry.wantHover = entered and entry.forever and ns.IsEnabled(module)
            and (not row.IsVisible or row:IsVisible()) or false
        if Locked() then waiting = true; return end
        PaintRowHover(entry, entry.wantHover)
    end
    -- The native secure-row scripts already route both pointer transitions
    -- through this Spy-local method. One secure posthook covers the whole pool.
    local nativeHover = type(spy.ShowTooltip) == "function"
    if nativeHover then
        hooksecurefunc(spy, "ShowTooltip", function(_, row, entered)
            local entry = rowArt[row]
            if entry then RowHover(entry, row, entered) end
        end)
    end
    local toneColors
    local function RowTones(entry, bar, shown)
        shown = shown and Owned(bar) and true or false
        if not entry.tones and shown then
            entry.tones = {bar:CreateTexture(nil, "ARTWORK", nil, 2),
                bar:CreateTexture(nil, "ARTWORK", nil, 2)}
            if CreateColor and entry.tones[1].SetGradient then
                toneColors = toneColors or {CreateColor(0.90, 0.73, 0.48, 0),
                    CreateColor(0.90, 0.73, 0.48, 0.16),
                    CreateColor(0.04, 0.025, 0.01, 0.28), CreateColor(0.04, 0.025, 0.01, 0)}
            end
            for i, texture in ipairs(entry.tones) do
                texture:SetColorTexture(1, 1, 1, 1)
                texture:SetBlendMode("BLEND")
                if toneColors then
                    texture:SetGradient("VERTICAL", toneColors[i == 1 and 1 or 3], toneColors[i == 1 and 2 or 4])
                else texture:SetVertexColor(i == 1 and 0.90 or 0.04, i == 1 and 0.73 or 0.025,
                    i == 1 and 0.48 or 0.01, 0.07) end
            end
        end
        if not entry.tones then return end
        if shown and entry.toneParent ~= bar then
            local upper, lower = entry.tones[1], entry.tones[2]
            upper:SetParent(bar); lower:SetParent(bar)
            upper:ClearAllPoints(); lower:ClearAllPoints()
            upper:SetAllPoints(bar); lower:SetAllPoints(bar)
            entry.toneParent = bar
        end
        if entry.tonesShown ~= shown then
            for _, texture in ipairs(entry.tones) do texture:SetShown(shown) end
            entry.tonesShown = shown
        end
    end
    local function ReleaseTones(entry)
        RowTones(entry, nil, false)
        if entry.toneParent then
            for _, texture in ipairs(entry.tones) do
                texture:SetParent(entry.host); texture:ClearAllPoints()
            end
            entry.toneParent = nil
        end
        entry.wantHover = false
        PaintRowHover(entry, false)
    end
    local function SyncWindow(f, alert, standardLayer, forever)
        local entry = foreverWindows[f]
        if not entry and forever and Owned(f) then
            local host = Host(f)
            local plate, grain, paint, mask = Surface(host, f == spy.MainWindow)
            entry = {host = host, plate = plate, grain = grain, paint = paint, mask = mask, rim = Rim(host)}
            foreverWindows[f] = entry
            if f == spy.MainWindow then
                local well = Host(host)
                well:ClearAllPoints()
                well:SetPoint("TOPLEFT", f, "TOPLEFT", 7, -32)
                well:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -7, -3)
                entry.innerRim = Rim(well)
                if entry.innerRim and _G.EllesmereUI.ForeverBorderPaint then
                    _G.EllesmereUI.ForeverBorderPaint(entry.innerRim, 0.86, 0.70, 0.48, 1)
                end
                -- Recessed lighting belongs to one shared viewport, not each row.
                for _, edge in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                    local shadow = well:CreateTexture(nil, "BACKGROUND", nil, 4)
                    if edge == "TOP" or edge == "BOTTOM" then
                        shadow:SetPoint(edge .. "LEFT", well, edge .. "LEFT", 2, 0)
                        shadow:SetPoint(edge .. "RIGHT", well, edge .. "RIGHT", -2, 0)
                        shadow:SetHeight(3)
                    else
                        shadow:SetPoint("TOP" .. edge, well, "TOP" .. edge, 0, -2)
                        shadow:SetPoint("BOTTOM" .. edge, well, "BOTTOM" .. edge, 0, 2)
                        shadow:SetWidth(3)
                    end
                    shadow:SetColorTexture(1, 1, 1, 1)
                    if shadow.SetGradient and CreateColor then
                        local dark, clear = CreateColor(0.025, 0.012, 0.006, 0.32), CreateColor(0.025, 0.012, 0.006, 0)
                        local reverse = edge == "TOP" or edge == "RIGHT"
                        shadow:SetGradient((edge == "TOP" or edge == "BOTTOM") and "VERTICAL" or "HORIZONTAL",
                            reverse and clear or dark, reverse and dark or clear)
                    else shadow:SetVertexColor(0.025, 0.012, 0.006, 0.20) end
                end
                -- Partition the backgrounds: header and list never overlap.
                plate:SetParent(well); plate:ClearAllPoints(); plate:SetAllPoints(well)
                grain:SetParent(well); grain:ClearAllPoints(); grain:SetAllPoints(well)
                if mask then mask:SetParent(well); mask:ClearAllPoints(); mask:SetAllPoints(well) end
                entry.bezel = {}
                for _, edge in ipairs({"LEFT", "RIGHT", "BOTTOM"}) do
                    local metal = host:CreateTexture(nil, "BACKGROUND", nil, 3)
                    if edge == "BOTTOM" then
                        metal:SetPoint("TOPLEFT", well, "BOTTOMLEFT", 0, 0)
                        metal:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -7, 0)
                    else
                        metal:SetPoint("TOP" .. edge, f, "TOP" .. edge, 0, -32)
                        metal:SetPoint("BOTTOM" .. edge, host, "BOTTOM" .. edge, 0, 0)
                        metal:SetWidth(7)
                    end
                    metal:SetColorTexture(0.24, 0.145, 0.065, 1)
                    metal:SetBlendMode("BLEND")
                    if metal.SetGradient and CreateColor then
                        local light, dark = CreateColor(0.34, 0.22, 0.10, 1), CreateColor(0.075, 0.040, 0.018, 1)
                        metal:SetColorTexture(1, 1, 1, 1)
                        metal:SetGradient(edge == "BOTTOM" and "VERTICAL" or "HORIZONTAL",
                            edge == "RIGHT" and dark or light, edge == "RIGHT" and light or dark)
                    end
                    entry.bezel[#entry.bezel + 1] = metal
                end
                entry.well = well
            end
            if f.Background and f.Background.GetAlpha then
                entry.nativeBackground = f.Background
                entry.backgroundAlpha = f.Background:GetAlpha()
            end
            if f.TitleBar and not alert then
                local header = Host(host)
                header:ClearAllPoints(); header:SetAllPoints(f.TitleBar)
                if f == spy.MainWindow then
                    header:ClearAllPoints()
                    header:SetPoint("TOPLEFT", host, "TOPLEFT", 2, -2)
                    header:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -2, -32)
                    local hp, hg, paint = Surface(header, true, true)
                    entry.headerSurface = {plate = hp, grain = hg, paint = paint}
                    entry.headerHost = header
                end
                local band
                if f ~= spy.MainWindow then
                    band = header:CreateTexture(nil, "BACKGROUND", nil, 3)
                    band:SetAllPoints(header); band:SetColorTexture(0.185, 0.126, 0.080, 1)
                    if band.SetGradient and CreateColor then
                        band:SetGradient("VERTICAL", CreateColor(0.095, 0.064, 0.040, 1),
                            CreateColor(0.185, 0.126, 0.080, 1))
                    end
                end
                local seam = header:CreateTexture(nil, "ARTWORK")
                seam:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 1, 0)
                seam:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -1, 0)
                seam:SetHeight(f == spy.MainWindow and 2 or 1); seam:SetColorTexture(0.49, 0.33, 0.18, 0.65)
                if f == spy.MainWindow then
                    local shade = header:CreateTexture(nil, "ARTWORK")
                    shade:SetPoint("BOTTOMLEFT", seam, "TOPLEFT", 0, 0)
                    shade:SetPoint("BOTTOMRIGHT", seam, "TOPRIGHT", 0, 0)
                    shade:SetHeight(2); shade:SetColorTexture(0.055, 0.032, 0.014, 0.50)
                    entry.seamShade = shade
                    seam:SetColorTexture(0.58, 0.38, 0.19, 0.75)
                end
                entry.band, entry.seam = band, seam
            end
        end
        if not entry then return end
        entry.standardLayer = standardLayer or entry.standardLayer
        Alpha(entry.host, forever and 1 or 0)
        ShowRim(entry.rim, forever)
        if entry.standardLayer then Alpha(entry.standardLayer, forever and 0 or 1) end
        if entry.nativeBackground then Alpha(entry.nativeBackground, forever and 0 or entry.backgroundAlpha) end
        if forever then
            local alpha = f == spy.MainWindow and BackgroundOpacity() or PanelAlpha()
            if entry.headerSurface then
                PaintBackground(entry.headerSurface, alpha)
                if entry.bezelAlpha ~= alpha then
                    for _, metal in ipairs(entry.bezel) do metal:SetVertexColor(1, 1, 1, alpha) end
                    entry.bezelAlpha = alpha
                end
            end
            if entry.paint then PaintBackground(entry, alpha)
            else
                local grainAlpha = alpha * 0.12
                Alpha(entry.grain, grainAlpha)
                Alpha(entry.plate, grainAlpha < 1 and (alpha - grainAlpha) / (1 - grainAlpha) or 0)
            end
            -- The warm plate/grain already cover the header. No stacked fill.
            if entry.band then Alpha(entry.band, alpha * 0.16) end
            if entry.seam then Alpha(entry.seam, 1) end
            -- Alert borders are severity indicators, not neutral bronze trim.
            if alert and entry.rim and f.GetBackdropBorderColor and _G.EllesmereUI.ForeverBorderPaint then
                local r, g, b, a = f:GetBackdropBorderColor()
                if SafeValue(r) and SafeValue(g) and SafeValue(b) and SafeValue(a)
                    and (entry.r ~= r or entry.g ~= g or entry.b ~= b or entry.a ~= a) then
                    _G.EllesmereUI.ForeverBorderPaint(entry.rim, r, g, b, a)
                    entry.r, entry.g, entry.b, entry.a = r, g, b, a
                end
            end
        end
        for _, key in ipairs(controls) do
            if f[key] then SyncControl(f[key], forever, key) end
        end
        SyncHeader(f, forever)
    end
    local function RestoreRowGeometry(entry)
        if not entry.inset then return end
        for _, saved in ipairs(entry.geometry) do RestorePoints(saved.region, saved.points) end
        entry.inset = false
    end
    local function RowGeometry(entry, row, forever)
        if not (Owned(row.StatusBar) and Owned(row.LeftText) and Owned(row.RightText)) then return end
        if entry.bar ~= row.StatusBar or entry.left ~= row.LeftText or entry.right ~= row.RightText then
            RestoreRowGeometry(entry)
            entry.bar, entry.left, entry.right = row.StatusBar, row.LeftText, row.RightText
            entry.geometry = {
                {region = entry.bar, points = SavePoints(entry.bar)},
                {region = entry.left, points = SavePoints(entry.left)},
                {region = entry.right, points = SavePoints(entry.right)},
            }
        end
        if not forever then RestoreRowGeometry(entry); return end
        if entry.inset then return end
        entry.bar:ClearAllPoints()
        entry.bar:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -1)
        entry.bar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -10, 1)
        -- Constrain the native FontString between inset columns. Native SetBar
        -- still owns its text/width writes; dual anchors provide clipping
        -- without a per-player skin hook or custom name parsing.
        Anchor(entry.right, "RIGHT", entry.bar, "RIGHT", -4, 0)
        entry.left:ClearAllPoints()
        entry.left:SetPoint("LEFT", entry.bar, "LEFT", 4, 0)
        entry.left:SetPoint("RIGHT", entry.right, "LEFT", -6, 0)
        entry.inset = true
    end
    local function SyncRow(row, forever)
        if not Owned(row) then return end
        local entry = rowArt[row] or row.id and rowSlots[row.id]
        if not entry and forever then
            local root = spy.MainWindow
            if not root then return end
            -- One reusable sibling per native row slot, below its secure text.
            local host = Host(root, math.max(root:GetFrameLevel(), row:GetFrameLevel() - 1))
            local edges = RowEdges(host)
            entry = {host = host, edges = edges, paintedHover = false}
            if row.id then rowSlots[row.id] = entry end
        end
        if not entry then return end
        if entry.row ~= row then
            if entry.row then
                RestoreRowGeometry(entry)
                ReleaseTones(entry)
                rowArt[entry.row] = nil
            end
            entry.row = row
            entry.forever, entry.wantHover = nil, false
            local host = entry.host
            local level = math.max(spy.MainWindow:GetFrameLevel(), row:GetFrameLevel() - 1)
            if host:GetFrameLevel() ~= level then host:SetFrameLevel(level) end
            if host.GetParent and host:GetParent() ~= spy.MainWindow then host:SetParent(spy.MainWindow) end
            host:ClearAllPoints()
            host:SetPoint("TOPLEFT", row, "TOPLEFT", 9, 0)
            host:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -9, 0)
            rowArt[row] = entry
            entry.hookedRows = entry.hookedRows or setmetatable({}, {__mode = "k"})
            if not entry.hookedRows[row] then
                entry.hookedRows[row] = true
            -- Old native rows may remain resident; their callbacks must not
            -- control artwork reassigned to another row in the same slot.
            row:HookScript("OnShow", function()
                if entry.row ~= row then return end
                if not Locked() then
                    if MouseIsOver then
                        local hovered = MouseIsOver(row)
                        if SafeValue(hovered) then entry.wantHover = hovered and true or false end
                    end
                    PaintRowHover(entry, entry.wantHover and ns.IsEnabled(module) and ForeverLook() or false)
                    Alpha(host, ns.IsEnabled(module) and ForeverLook() and 1 or 0)
                else waiting = true end
            end)
            row:HookScript("OnHide", function()
                if entry.row ~= row then return end
                entry.wantHover = false
                if not Locked() then PaintRowHover(entry, false); Alpha(host, 0) else waiting = true end
            end)
            -- Older forks without the shared method keep the scoped fallback.
            if not nativeHover then
                row:HookScript("OnEnter", function() RowHover(entry, row, true) end)
                row:HookScript("OnLeave", function() RowHover(entry, row, false) end)
            end
            end
        end
        if entry.forever ~= forever then
            entry.forever, entry.wantHover = forever, false
            if forever and MouseIsOver then
                local hovered = MouseIsOver(row)
                if SafeValue(hovered) then entry.wantHover = hovered and true or false end
            end
        end
        RowGeometry(entry, row, forever)
        local tonesShown = forever and entry.inset or false
        if entry.tonesShown ~= tonesShown or tonesShown and entry.toneParent ~= row.StatusBar then
            RowTones(entry, row.StatusBar, tonesShown)
        end
        if not forever then entry.wantHover = false end
        local hovered = forever and entry.wantHover or false
        if entry.paintedHover ~= hovered then PaintRowHover(entry, hovered) end
        Alpha(entry.host, forever and (not row.IsShown or row:IsShown()) and 1 or 0)
    end
    local function SyncRows(forever)
        local rows = spy.MainWindow and spy.MainWindow.Rows or {}
        for row, entry in pairs(rowArt) do
            if row.id and rows[row.id] ~= row then
                RestoreRowGeometry(entry)
                ReleaseTones(entry)
                Alpha(entry.host, 0)
                rowArt[row] = nil
                entry.row = nil
                entry.bar, entry.left, entry.right, entry.geometry = nil, nil, nil, nil
            end
        end
        for _, row in pairs(rows) do
            SyncRow(row, forever)
        end
    end
    local function ReasonDialogs(discover)
        if not ns.StyleTextureDialog then return end
        if discover then
            for i = 1, 4 do
                local popup = _G["StaticPopup" .. i]
                if popup and popup.which == "Spy_SetKOSReasonOther" then reasonDialogs[popup] = true end
            end
        end
        for popup in pairs(reasonDialogs) do
            ns.StyleTextureDialog(S, module, popup, ns.IsEnabled(module) and ForeverLook()
                and popup.which == "Spy_SetKOSReasonOther" and popup:IsShown())
        end
    end
    local function RestoreForever()
        if Locked() then waiting = true; return end
        for f, entry in pairs(foreverWindows) do SyncWindow(f, f == spy.AlertWindow, entry.standardLayer, false) end
        for button in pairs(controlArt) do SyncControl(button, false) end
        for row in pairs(rowArt) do SyncRow(row, false) end
        for popup in pairs(reasonDialogs) do
            if ns.StyleTextureDialog then ns.StyleTextureDialog(S, module, popup, false) end
        end
        S.RefreshSoftBorders()
        if ns.RefreshPopupMenusNow then ns.RefreshPopupMenusNow() end
    end
    local opacityKey = {}
    local function SavePreference(key, value)
        EUIAddonSkinsDB = EUIAddonSkinsDB or {}
        EUIAddonSkinsDB.spy = EUIAddonSkinsDB.spy or {}
        EUIAddonSkinsDB.spy[key] = value
    end
    local function NotifySettings()
        local registry = LibStub and LibStub("AceConfigRegistry-3.0", true)
        if settingsRegistered and registry and registry.NotifyChange then registry:NotifyChange(APP) end
    end
    local function SetStyle(value)
        if value ~= "auto" and value ~= "standard" and value ~= "forever" then return end
        SavePreference("style", value); refresh(); NotifySettings()
    end
    local function ResetSkinSettings()
        if EUIAddonSkinsDB then EUIAddonSkinsDB.spy = nil end
        refresh(); NotifySettings()
    end
    local function ApplyOpacity()
        if Locked() then waiting = true; return end
        if not ns.IsEnabled(module) then return end
        local f = spy.MainWindow
        local entry = f and foreverWindows[f]
        if entry then SyncWindow(f, false, entry.standardLayer, ForeverLook()) end
    end
    local function OpenSettings()
        if Locked() then return end
        local registry = LibStub and LibStub("AceConfigRegistry-3.0", true)
        local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
        if not (registry and registry.RegisterOptionsTable and dialog and dialog.Open) then return end
        if not settingsRegistered then
            registry:RegisterOptionsTable(APP, {
                type = "group", name = "Spy — EUI AddonSkins", args = {
                    style = {type = "select", name = "Style", order = 1, width = "full",
                        values = {auto = "Automatic", standard = "EUI Standard", forever = "EUI Forever"},
                        get = function() return EUIAddonSkinsDB and EUIAddonSkinsDB.spy and EUIAddonSkinsDB.spy.style or "auto" end,
                        set = function(_, value) SetStyle(value) end,
                    },
                    opacity = {type = "range", name = "Background Opacity", order = 2,
                        desc = "Forever decorative background only. Spy retains its own bar textures and window fading.",
                        width = "full", min = 0, max = 100, step = 1, bigStep = 5,
                        get = function() return math.floor(BackgroundOpacity() * 100 + 0.5) end,
                        set = function(_, value)
                            if type(value) ~= "number" or not SafeValue(value) or value ~= value then return end
                            local target = math.max(0, math.min(100, value)) / 100
                            local current = BackgroundOpacity()
                            SavePreference("opacity", target)
                            if target ~= current then H.Queue(opacityKey, ApplyOpacity) end
                        end,
                    },
                    reset = {type = "execute", name = "Reset Skin Settings", order = 3, func = ResetSkinSettings},
                },
            })
            if dialog.SetDefaultSize then dialog:SetDefaultSize(APP, 360, 240) end
            settingsRegistered = true
        end
        dialog:Open(APP)
    end
    local function StyleChoice(label, value)
        return {text = label, isNotRadio = false, checked = function()
            local preferences = EUIAddonSkinsDB and EUIAddonSkinsDB.spy
            return (preferences and preferences.style or "auto") == value
        end, func = function() SetStyle(value) end}
    end
    local menuToken = {}
    local settingsItems = {
        {text = "Style", isTitle = true, notCheckable = true},
        StyleChoice("Automatic", "auto"),
        StyleChoice("EUI Standard", "standard"),
        StyleChoice("EUI Forever", "forever"),
        {text = "Background Opacity…", notCheckable = true, func = OpenSettings},
        {text = "Reset Skin Settings", notCheckable = true, func = ResetSkinSettings},
    }
    local settingsMenu = {text = "EUI AddonSkins", notCheckable = true, hasArrow = true,
        value = menuToken, menuList = settingsItems, padding = 28}
    local initializerWrappers = setmetatable({}, {__mode = "k"})
    local wrappedInitializers = setmetatable({}, {__mode = "k"})
    local function WrapInitializer(original)
        if wrappedInitializers[original] then return original end
        if initializerWrappers[original] then return initializerWrappers[original] end
        local wrapper = function(self, level, ...)
            local active = ns.IsEnabled(module)
            if active and (level or 1) == 2 and
                (UIDROPDOWNMENU_MENU_VALUE == menuToken or UIDROPDOWNMENU_MENU_VALUE == settingsItems) then
                for _, item in ipairs(settingsItems) do UIDropDownMenu_AddButton(item, level) end
                return
            end
            local result = pack(original(self, level, ...))
            if active and (level or 1) == 1 and UIDropDownMenu_AddButton then
                UIDropDownMenu_AddButton(settingsMenu, level or 1)
            end
            return unpack(result, 1, result.n)
        end
        initializerWrappers[original], wrappedInitializers[wrapper] = wrapper, true
        return wrapper
    end
    -- Spy assigns and opens this initializer inside BarDropDownOpen. Wrap it
    -- before that call so the first opening already has the submenu.
    if type(spy.BarDropDownOpen) == "function" then
        local open = spy.BarDropDownOpen
        spy.BarDropDownOpen = function(...)
            if type(_G.Spy_CreateBarDropdown) == "function" then
                _G.Spy_CreateBarDropdown = WrapInitializer(_G.Spy_CreateBarDropdown)
            end
            return open(...)
        end
    end
    if type(SlashCmdList) == "table" then
        SLASH_EUISPYSKIN1 = "/euispy"
        SlashCmdList.EUISPYSKIN = OpenSettings
    end
    -- The existing shared menu helper handles nested owners and foreign reuse.
    -- Its separate gate leaves released Standard menus visually unchanged.
    local menuModule = {skin = {IsEnabled = function() return ns.IsEnabled(module) and ForeverLook() end}}
    local menuLook = {noAccent = true, chevrons = true,
        hoverColor = {0.8, 0.56, 0.32}, hoverAlpha = 0.25,
        legacyShell = function(host)
            local plate, grain = Surface(host)
            local a = PanelAlpha(); Alpha(plate, a); Alpha(grain, 0)
            Rim(host)
        end}
    local menuOptions = {legacyLook = function() return menuLook end}
    local function BindMenu(menu, addSettings)
        if not menu then return end
        if addSettings and type(menu.initialize) == "function" then
            menu.initialize = WrapInitializer(menu.initialize)
        end
        if ns.BindPopupOwner then ns.BindPopupOwner(S, menuModule, menu, menuOptions) end
    end

    local function Window(f, alert)
        if not f or not f.GetObjectType or (f.IsForbidden and f:IsForbidden()) then return end
        -- Secure targeting rows can make the parent protected. Create only a
        -- noninteractive visual child, outside combat, without changing actions.
        if not layers[f] then
            local bg = CreateFrame("Frame", nil, f)
            bg:SetAllPoints(f)
            bg:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
            bg:EnableMouse(false)
            S.Shell(bg, {noTopBar = alert or f == spy.MainWindow})
            ns.AttachAccent(S, bg)
            layers[f] = bg
            if f.HookScript then
                f:HookScript("OnShow", function() if ns.IsEnabled(module) then refresh() end end)
            end
        end
        if f.SetBackdrop then f:SetBackdrop(nil) end
        if f.TitleBar and f.TitleBar.SetBackdrop and not (f.TitleBar.IsForbidden and f.TitleBar:IsForbidden()) then
            f.TitleBar:SetBackdrop(nil)
        end
        if not styled[f] then
            styled[f] = true
            -- Remove only window decoration, not alert icons or player rows.
            for _, region in ipairs({f:GetRegions()}) do
                local path = region.GetTexture and region:GetTexture()
                if type(path) == "string" and (path:find("UI%-DialogBox") or path:find("UI%-Tooltip")) then H.Fade(region) end
            end
            if H.Allowed(f.CloseButton) then S.CloseButton(f.CloseButton) end
            if H.Allowed(f.LeftButton) and S.SoftPageButton then S.SoftPageButton(f.LeftButton, "<") end
            if H.Allowed(f.RightButton) and S.SoftPageButton then S.SoftPageButton(f.RightButton, ">") end
        end
        if alert and ForeverLook() and f.Title and f.Title.GetTextColor then
            local r, g, b, a = f.Title:GetTextColor()
            H.Font(f.Title, r, g, b)
            if f.Title.SetTextColor then f.Title:SetTextColor(r, g, b, a) end
        else H.Font(f.Title) end
        -- Scan individual unprotected children; secure rows and their bars keep
        -- Spy's class/KOS colors, macro attributes and click handlers intact.
        local exclude = {}
        if f.Icon then exclude[f.Icon] = true end
        for _, key in ipairs(controls) do if f[key] then exclude[f[key]] = true end end
        for _, row in pairs(f.Rows or {}) do exclude[row] = true end
        exclude[layers[f]] = true
        local art = foreverWindows[f]
        if art then exclude[art.host] = true end
        for _, entry in pairs(rowArt) do exclude[entry.host] = true end
        for _, child in ipairs({f:GetChildren()}) do H.Scan(child, refresh, nil, exclude) end
        SyncWindow(f, alert, layers[f], ForeverLook())
    end
    local function Apply()
        if InCombatLockdown() then waiting = true; return end
        waiting = false
        for _, name in ipairs({"Spy_MainWindow", "SpyStatsFrame"}) do
            if _G[name] then windows[_G[name]] = true end
        end
        if spy.MainWindow then windows[spy.MainWindow] = true end
        for f in pairs(windows) do Window(f) end
        Window(spy.AlertWindow, true)
        if H.Allowed(_G.SpyStatsFrameTopCloseButton) then S.CloseButton(_G.SpyStatsFrameTopCloseButton) end
        H.Fade(_G.SpyStatsFrame_Header)
        if config and config.OpenFrames and config.OpenFrames.Spy then
            Window(config.OpenFrames.Spy.frame)
        end
        for _, f in pairs(spy.optionsFrames or {}) do
            if H.Allowed(f) then H.Script(f, "OnShow", refresh); H.Scan(f, refresh) end
        end
        for f in pairs(options) do H.Scan(f, refresh) end
        S.RefreshSoftBorders()
        if H.Allowed(_G.SpyStatsFrameTopCloseButton) then SyncControl(_G.SpyStatsFrameTopCloseButton, ForeverLook(), "CloseButton") end
        if config and config.OpenFrames and config.OpenFrames[APP] then Window(config.OpenFrames[APP].frame) end
        ReasonDialogs(false)
        SyncRows(ForeverLook())
        if ns.RefreshPopupMenusNow then ns.RefreshPopupMenusNow() end
    end
    refresh = function()
        if not ns.IsEnabled(module) then RestoreForever(); return end
        H.Queue(module, Apply)
    end
    H.Hook(config, "FeedGroup", function(_, appName, _, root)
        if appName == "Spy" or appName == APP then
            if root and root.frame then options[root.frame] = true end
            refresh()
        end
    end)
    H.Hook(spy, "CreateFrame", function(_, name)
        if type(name) == "string" and _G[name] then windows[_G[name]] = true end
        refresh()
    end)
    for _, method in ipairs({"CreateMainWindow", "UpdateAlertWindow", "HandleProfileChanges",
        "SetupMainWindowButtons", "SetFont", "ShowConfig", "SetupOptions"}) do H.Hook(spy, method, refresh) end
    H.Hook(spy, "CreateRow", function() refresh() end)
    H.Hook(spy, "ResizeMainWindow", function()
        if Locked() then waiting = true; return end
        SyncHeader(spy.MainWindow, ns.IsEnabled(module) and ForeverLook(), true)
    end)
    H.Hook(spy, "SetCurrentList", function()
        if Locked() then waiting = true; return end
        SyncRows(ForeverLook())
    end)
    for _, method in ipairs({"ShowAlert", "AlertWatch"}) do
        H.Hook(spy, method, function()
            if Locked() then waiting = true; return end
            SyncWindow(spy.AlertWindow, true, layers[spy.AlertWindow], ForeverLook())
        end)
    end
    H.Hook(spy, "SetKOSReason", function()
        if Locked() then waiting = true; return end
        ReasonDialogs(true)
    end)
    H.Hook(spy, "BarDropDownOpen", function() BindMenu(_G.Spy_BarDropDownMenu, true) end)
    H.Hook(spy, "ShowStatsDropDown", function() BindMenu(_G.StatsDropDownMenu, false) end)
    H.Hook(spy.Colors, "UpdateColor", refresh)
    if _G.SpyStats then H.Hook(_G.SpyStats, "Show", refresh) end
    events:SetScript("OnEvent", function() if waiting then refresh() end end)
    module.refresh = refresh
    if S.OnLooksChanged then S.OnLooksChanged(refresh) end
    refresh()
end)

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Spy", DefineSkin)
else DefineSkin() end
