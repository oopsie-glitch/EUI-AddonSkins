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
    events:RegisterEvent("UI_SCALE_CHANGED")
    events:RegisterEvent("DISPLAY_SIZE_CHANGED")


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
    local function SupportsForever()
        local EUI = _G.EllesmereUI
        return not not (S.GetPanelColor and EUI and EUI.IS_FOREVER and EUI.ForeverBorder
            and EUI.ForeverBorderSeat and EUI.ForeverBorderShown)
    end
    ForeverLook = function()
        if not SupportsForever() then return false end
        local EUI = _G.EllesmereUI
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
    local function Surface(host, managed)
        local plate = host:CreateTexture(nil, "BACKGROUND", nil, 1)
        local grain = host:CreateTexture(nil, "BACKGROUND", nil, 2)
        plate:SetAllPoints(host); grain:SetAllPoints(host)
        -- Same material as RestedXP: EUI exports the rim, not its warm fill.
        -- A coloured source multiplied by the same gradient squares the tint.
        -- Use one warm paint pass on a neutral source for the main material.
        if managed then plate:SetColorTexture(1, 1, 1, 1)
        else plate:SetColorTexture(0.165, 0.115, 0.075, 1) end
        local paint = managed and {} or nil
        if plate.SetGradient and CreateColor then
            local low, high = CreateColor(0.120, 0.084, 0.055, 1), CreateColor(0.165, 0.115, 0.075, 1)
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
        local mode = Enum and Enum.UITextureSliceMode and Enum.UITextureSliceMode.Stretched
        if mode and host.CreateMaskTexture and plate.AddMaskTexture then
            local mask = host:CreateMaskTexture()
            mask:SetTexture("Interface\\AddOns\\EUIAddonSkins\\Media\\RestedXPFill.tga",
                "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetTextureSliceMargins(8, 8, 8, 8); mask:SetTextureSliceMode(mode)
            mask:SetAllPoints(host); plate:AddMaskTexture(mask); grain:AddMaskTexture(mask)
        end
        return plate, grain, paint
    end
    local function PaintBackground(entry, target)
        local paint = entry.paint
        if paint.alpha ~= target then
            paint.alpha = target
            local grainAlpha = target * 0.12
            local plateAlpha = (target - grainAlpha) / (1 - grainAlpha)
            if paint.low then
                paint.low:SetRGBA(0.120, 0.084, 0.055, plateAlpha)
                paint.high:SetRGBA(0.165, 0.115, 0.075, plateAlpha)
                entry.plate:SetGradient("VERTICAL", paint.low, paint.high)
            else
                entry.plate:SetVertexColor(0.165, 0.115, 0.075, plateAlpha)
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
    local CONTROL_SCALE, CONTROL_SEAT_LIMIT = 0.5, 14
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
        local width, height = math.min(CONTROL_SEAT_LIMIT, w - 2), math.min(CONTROL_SEAT_LIMIT, h - 2)
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
    local headerLayouts = setmetatable({}, {__mode = "k"})
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
            if p == point and r == relative and rp == relativePoint and SafeValue(px) and SafeValue(py)
                and type(px) == "number" and type(py) == "number"
                and math.abs(px - x) < 0.001 and math.abs(py - y) < 0.001 then return end
        end
        region:ClearAllPoints(); region:SetPoint(point, relative, relativePoint, x, y)
    end
    -- Spy uses 34 units both for its native row origin and its visible-row
    -- budget. Move only supported native TOPLEFT row anchors, never the budget.
    local NATIVE_LIST_TOP, VISUAL_PADDING, HITBOX_CLEARANCE, LIST_GAP = 34, 2, 1, 2
    local function HeaderBand(textHeight, hitboxHeight)
        local seat = math.min(CONTROL_SEAT_LIMIT, math.max(0, hitboxHeight - 2))
        return math.max(math.max(textHeight, seat) + 2 * VISUAL_PADDING,
            hitboxHeight + 2 * HITBOX_CLEARANCE)
    end
    local function OffsetRow(f, layout, row, shift, nativeStride)
        local p, parent, rp, x, y = row:GetPoint(1)
        if row:GetNumPoints() ~= 1 or p ~= "TOPLEFT" or parent ~= f or rp ~= "TOPLEFT"
            or not SafeValue(x) or not SafeValue(y) or type(x) ~= "number" or type(y) ~= "number" then
            layout.rowY[row] = nil
            return
        end
        local saved = layout.rowY[row]
        if nativeStride and type(row.id) == "number" and math.abs(y + NATIVE_LIST_TOP + nativeStride * (row.id - 1)) < 0.001 then
            -- BarsChanged just rewrote the native anchor; it can numerically
            -- coincide with the previous shifted anchor at a different stride.
            saved, layout.rowY[row] = nil, nil
        end
        -- Client anchor readback can round fractional offsets.
        local nativeY = saved and math.abs(y - saved.applied) < 0.001 and saved.native or y
        local target = nativeY + shift
        if math.abs(target - y) >= 0.001 then row:SetPoint(p, parent, rp, x, target) end
        if shift ~= 0 then
            if not saved then saved = {}; layout.rowY[row] = saved end
            saved.native, saved.applied = nativeY, target
        else layout.rowY[row] = nil end
    end
    local function ShiftList(f, layout, shift, force, nativeStride)
        if layout.shift == shift and not force then return end
        layout.shift = shift
        for _, row in pairs(f.Rows or {}) do
            if Owned(row) and row.GetNumPoints then OffsetRow(f, layout, row, shift, nativeStride) end
        end
    end
    local function Positive(value, fallback)
        if SafeValue(value) and type(value) == "number" and value > 0 and value < math.huge then return value end
        return fallback
    end
    local function MeasureHeight(region, cache, scale, width, wrapped, retry)
        local font, size, flags = region:GetFont()
        local value = width and region:GetText() -- counter digits share a single-line font metric
        if not SafeValue(value) then value = nil end
        if cache.height and cache.font == font and cache.size == size and cache.flags == flags
            and cache.scale == scale and cache.width == width and cache.wrapped == wrapped
            and cache.text == value and not (retry and cache.pending) then return cache.height end
        local actual = region.GetStringHeight and Positive(region:GetStringHeight())
        local height = actual or Positive(size, Positive(region:GetHeight(), 1))
        cache.font, cache.size, cache.flags = font, size, flags
        cache.scale, cache.width, cache.wrapped, cache.text = scale, width, wrapped, value
        cache.height, cache.pending = height, not actual
        return height
    end
    local function TrackHeaderRegion(f, layout, region)
            if not region or layout.regions[region] then return end
            layout.regions[region] = SavePoints(region)
            local isCounter = region == (f.CountFrame and f.CountFrame.Text)
            if region == f.Title or isCounter then
                layout.lastText[region] = region:GetText()
                H.Hook(region, "SetText", function()
                    if layout.writing then return end
                    local value, previous = region:GetText(), layout.lastText[region]
                    if SafeValue(value) and SafeValue(previous) and value == previous then return end
                    layout.lastText[region] = SafeValue(value) and value or nil
                    if isCounter and layout.active and layout.counterTextWidth then
                        local width = region:GetStringWidth()
                        if SafeValue(width) and width == layout.counterTextWidth then return end
                    end
                    SyncHeader(f, ns.IsEnabled(module) and ForeverLook())
                end)
                H.Hook(region, "SetFont", function()
                    if not layout.writing then SyncHeader(f, ns.IsEnabled(module) and ForeverLook(), false, true) end
                end)
            end
            if isCounter then
                local function CounterChanged() SyncHeader(f, ns.IsEnabled(module) and ForeverLook()) end
                H.Hook(region, "SetAlpha", CounterChanged)
                H.Hook(region, "Show", CounterChanged)
                H.Hook(region, "Hide", CounterChanged)
            end
            if region ~= f.Title and not isCounter and region.HookScript then
                local function ControlChanged()
                    if not layout.writing then SyncHeader(f, ns.IsEnabled(module) and ForeverLook()) end
                end
                region:HookScript("OnShow", ControlChanged)
                region:HookScript("OnHide", ControlChanged)
                region:HookScript("OnSizeChanged", ControlChanged)
            end
            -- Observe only owned native header anchors and ignore our writes.
            H.Hook(region, "SetPoint", function()
                if layout.writing then return end
                layout.regions[region] = SavePoints(region)
                SyncHeader(f, ns.IsEnabled(module) and ForeverLook())
            end)
    end
    SyncHeader = function(f, forever, capture, retry)
        if not f or f ~= spy.MainWindow or not f.Title then return end
        if Locked() then waiting = true; return end
        local entry = foreverWindows[f]
        local active = forever or ns.IsEnabled(module)
        local host = forever and entry and entry.host or (not forever and layers[f])
        if not host then return end
        local layout = headerLayouts[f]
        if not layout then
            if not active then return end
            layout = {regions = {}, lastText = {}, titleMetric = {}, counterMetric = {},
                rowY = setmetatable({}, {__mode = "k"}), titleWidth = f.Title:GetWidth(), titleHeight = f.Title:GetHeight(),
                wordWrap = f.Title.GetWordWrap and f.Title:GetWordWrap(),
                nonSpaceWrap = f.Title.GetNonSpaceWrap and f.Title:GetNonSpaceWrap()}
            headerLayouts[f] = layout
            H.Hook(f, "SetScale", function()
                SyncHeader(f, ns.IsEnabled(module) and ForeverLook(), false, true)
            end)
        end
        if layout.writing then return end
        TrackHeaderRegion(f, layout, f.Title)
        for _, key in ipairs(controls) do TrackHeaderRegion(f, layout, f[key]) end
        local counter = f.CountFrame and f.CountFrame.Text
        TrackHeaderRegion(f, layout, counter)
        if capture then layout.titleWidth = f.Title:GetWidth() end
        layout.writing = true
        if not active then
            if layout.active then
                for region, points in pairs(layout.regions) do RestorePoints(region, points) end
                f.Title:SetWidth(layout.titleWidth); f.Title:SetHeight(layout.titleHeight)
                if f.Title.SetWordWrap and layout.wordWrap ~= nil then f.Title:SetWordWrap(layout.wordWrap) end
                if f.Title.SetNonSpaceWrap and layout.nonSpaceWrap ~= nil then f.Title:SetNonSpaceWrap(layout.nonSpaceWrap) end
                ShiftList(f, layout, 0, true)
                if layout.host then layout.host:ClearAllPoints(); layout.host:SetAllPoints(f) end
                layout.active, layout.host = false, nil
            end
            layout.writing = false
            return
        end
        local width, title = f:GetWidth(), f.Title
        if not SafeValue(width) then layout.writing = false; return end
        local scale = f.GetEffectiveScale and Positive(f:GetEffectiveScale(), 1) or 1
        local counterWidth, counterHeight = 0, 0
        layout.counterTextWidth = nil
        if counter and (not counter.IsShown or counter:IsShown()) then
            local alpha = counter.GetAlpha and counter:GetAlpha() or 1
            local size = counter:GetStringWidth()
            if SafeValue(alpha) and SafeValue(size) and alpha > 0 and size > 0 then
                layout.counterTextWidth = size
                counterWidth = size + 6
                counterHeight = MeasureHeight(counter, layout.counterMetric, scale, nil, false, retry)
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
        if wrapped then available = math.max(1, width - 24 - counterWidth) end
        available = math.max(1, available)
        if title:GetWidth() ~= available then title:SetWidth(available) end
        if title.SetWordWrap and (not title.GetWordWrap or title:GetWordWrap() ~= wrapped) then title:SetWordWrap(wrapped) end
        if title.SetNonSpaceWrap and (not title.GetNonSpaceWrap or title:GetNonSpaceWrap() ~= wrapped) then title:SetNonSpaceWrap(wrapped) end
        local titleHeight = MeasureHeight(title, layout.titleMetric, scale, wrapped and available or 0, wrapped, retry)
        if title:GetHeight() ~= titleHeight then title:SetHeight(titleHeight) end
        local countHeight = countButton and countButton:IsShown() and countButton:GetHeight() or 0
        -- The native title anchors identify the constructed layout. The pinned
        -- Spy option only saves a preference; do not flip the skin ahead of
        -- native reconstruction, or override a fork's live reanchoring.
        local titlePoints = layout.regions[title]
        local nativeTitle = titlePoints and titlePoints[1]
        local inverted = nativeTitle and nativeTitle[2] == f and nativeTitle[3] == "BOTTOMLEFT"
        local leftEdge, rightEdge = "TOPLEFT", "TOPRIGHT"
        if inverted then leftEdge, rightEdge = "BOTTOMLEFT", "BOTTOMRIGHT" end

        local textHeight = math.max(titleHeight, counterHeight)
        local textBand = HeaderBand(textHeight, countHeight)
        local controlBand = HeaderBand(0, tallest)
        local required = wrapped and textBand + LIST_GAP + controlBand
            or HeaderBand(textHeight, math.max(tallest, countHeight))
        -- Round up to a whole physical pixel, never into the hitboxes.
        local headerHeight = math.ceil(required * scale) / scale
        -- Standard has one uninterrupted shell, so the list can meet the
        -- measured header directly. Keep Forever's existing divider gap.
        local listGap = forever and LIST_GAP or 0
        local listDepth = headerHeight + listGap
        local start = inverted and 0 or math.max(0, listDepth - NATIVE_LIST_TOP)
        local listTop = listDepth - start
        local titleY = start - headerHeight / 2
        local controlY = titleY
        if wrapped then
            local upper = start - (headerHeight - required) / 2
            titleY = upper - textBand / 2
            controlY = upper - textBand - LIST_GAP - controlBand / 2
        end
        Anchor(title, "LEFT", f, leftEdge, 12, titleY)
        if counter then Anchor(counter, "RIGHT", f, rightEdge, -12, titleY) end
        if countButton then Anchor(countButton, "RIGHT", f, rightEdge, -rightInset, titleY) end
        local offset = rightInset + (wrapped and 0 or counterSpace)
        for _, key in ipairs(controlOrder) do
            local button = f[key]
            if button and (not button.IsShown or button:IsShown()) then
                Anchor(button, "RIGHT", f, rightEdge, -offset, controlY)
                offset = offset + button:GetWidth() + gap
            end
        end
        -- Inverted Spy still orders its rows from the native top-left -34
        -- reservation, and places the controls below the native bottom.
        -- Fit the existing bronze host around that body and footer. Keep
        -- the native root, resize grips, row anchors and capacity untouched.
        local frameTop = inverted and LIST_GAP - NATIVE_LIST_TOP or start
        local frameBottom = inverted and -headerHeight or 0
        if layout.host ~= host or layout.frameTop ~= frameTop or layout.frameBottom ~= frameBottom then
            host:ClearAllPoints()
            host:SetPoint("TOPLEFT", f, "TOPLEFT", 0, frameTop)
            host:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, frameBottom)
            layout.host, layout.frameTop, layout.frameBottom = host, frameTop, frameBottom
        end
        local dividerY = inverted and 0 or LIST_GAP - listTop
        if forever and entry.seam and (layout.dividerY ~= dividerY or layout.dividerEdge ~= leftEdge) then
            Anchor(entry.seam, "TOPLEFT", f, leftEdge, 5, dividerY)
            entry.seam:SetPoint("TOPRIGHT", f, rightEdge, -5, dividerY)
            layout.dividerY, layout.dividerEdge = dividerY, leftEdge
        end
        ShiftList(f, layout, inverted and 0 or NATIVE_LIST_TOP - listTop)
        layout.active, layout.writing = true, false
    end
    local function PaintRowHover(entry, hovered)
        if entry.paintedHover == hovered then return end
        -- One compact copper separator. First acquisition and hover exit use
        -- the same solid paint; there are no neutral gradients or bar overlays.
        if hovered then entry.rule:SetColorTexture(0.73, 0.49, 0.26, 0.55)
        else entry.rule:SetColorTexture(0.49, 0.33, 0.18, 0.24) end
        entry.paintedHover = hovered
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
    local function SyncWindow(f, alert, standardLayer, forever)
        local entry = foreverWindows[f]
        if not entry and forever and Owned(f) then
            local host = Host(f)
            local plate, grain, paint = Surface(host, f == spy.MainWindow)
            entry = {host = host, plate = plate, grain = grain, paint = paint, rim = Rim(host)}
            foreverWindows[f] = entry
            if f.Background and f.Background.GetAlpha then
                entry.nativeBackground = f.Background
                entry.backgroundAlpha = f.Background:GetAlpha()
            end
            if f == spy.MainWindow then
                local seam = host:CreateTexture(nil, "ARTWORK")
                seam:SetHeight(1); seam:SetColorTexture(0.49, 0.33, 0.18, 0.65)
                entry.seam = seam
            elseif f.TitleBar and not alert then
                local header = Host(host)
                header:ClearAllPoints(); header:SetAllPoints(f.TitleBar)
                local band = header:CreateTexture(nil, "BACKGROUND", nil, 3)
                band:SetAllPoints(header); band:SetColorTexture(0.185, 0.126, 0.080, 1)
                if band.SetGradient and CreateColor then
                    band:SetGradient("VERTICAL", CreateColor(0.095, 0.064, 0.040, 1),
                        CreateColor(0.185, 0.126, 0.080, 1))
                end
                local seam = header:CreateTexture(nil, "ARTWORK")
                seam:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 1, 0)
                seam:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -1, 0)
                seam:SetHeight(1); seam:SetColorTexture(0.49, 0.33, 0.18, 0.65)
                entry.band, entry.seam = band, seam
            end
        end
        if not entry then
            if not forever then SyncHeader(f, false) end
            return
        end
        entry.standardLayer = standardLayer or entry.standardLayer
        Alpha(entry.host, forever and 1 or 0)
        ShowRim(entry.rim, forever)
        if entry.standardLayer then Alpha(entry.standardLayer, forever and 0 or 1) end
        if entry.nativeBackground then Alpha(entry.nativeBackground, forever and 0 or entry.backgroundAlpha) end
        if forever then
            local alpha = f == spy.MainWindow and BackgroundOpacity() or PanelAlpha()
            if entry.paint then PaintBackground(entry, alpha)
            else
                local grainAlpha = alpha * 0.12
                Alpha(entry.grain, grainAlpha)
                Alpha(entry.plate, grainAlpha < 1 and (alpha - grainAlpha) / (1 - grainAlpha) or 0)
            end
            -- The warm plate/grain already cover the header. No stacked fill.
            if entry.band then
                Alpha(entry.band, alpha * 0.16)
                Alpha(entry.seam, 1)
            end
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
    local function RestoreRetiredRow(row)
        local f = spy.MainWindow
        local layout = f and headerLayouts[f]
        if layout and layout.rowY[row] and Owned(row) then OffsetRow(f, layout, row, 0) end
    end
    local function SyncRow(row, forever)
        if not Owned(row) then return end
        local entry = rowArt[row] or row.id and rowSlots[row.id]
        if not entry and forever then
            local root = spy.MainWindow
            if not root then return end
            -- One reusable sibling per native row slot, below its secure text.
            local host = Host(root, math.max(root:GetFrameLevel(), row:GetFrameLevel() - 1))
            local rule = host:CreateTexture(nil, "ARTWORK")
            rule:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", 0, 0)
            rule:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", 0, 0)
            rule:SetHeight(1)
            entry = {host = host, rule = rule}
            PaintRowHover(entry, false)
            if row.id then rowSlots[row.id] = entry end
        end
        if not entry then return end
        if entry.row ~= row then
            if entry.row then
                RestoreRetiredRow(entry.row)
                PaintRowHover(entry, false)
                rowArt[entry.row] = nil
            end
            entry.row = row
            local root = spy.MainWindow
            local layout = headerLayouts[root]
            if forever and layout and layout.active and row.GetNumPoints then OffsetRow(root, layout, row, layout.shift or 0) end
            entry.forever, entry.wantHover = nil, false
            local host = entry.host
            local level = math.max(spy.MainWindow:GetFrameLevel(), row:GetFrameLevel() - 1)
            if host:GetFrameLevel() ~= level then host:SetFrameLevel(level) end
            if host.GetParent and host:GetParent() ~= spy.MainWindow then host:SetParent(spy.MainWindow) end
            host:ClearAllPoints(); host:SetAllPoints(row)
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
        if not forever then entry.wantHover = false end
        local hovered = forever and entry.wantHover or false
        if entry.paintedHover ~= hovered then PaintRowHover(entry, hovered) end
        Alpha(entry.host, forever and (not row.IsShown or row:IsShown()) and 1 or 0)
    end
    local function SyncRows(forever)
        local rows = spy.MainWindow and spy.MainWindow.Rows or {}
        for row, entry in pairs(rowArt) do
            if row.id and rows[row.id] ~= row then
                RestoreRetiredRow(row)
                PaintRowHover(entry, false)
                Alpha(entry.host, 0)
                rowArt[row] = nil
                entry.row = nil
            end
        end
        local f = spy.MainWindow
        local layout = not forever and f and headerLayouts[f]
        local shift = layout and layout.active and layout.shift
        if shift and shift ~= 0 then
            for row in pairs(layout.rowY) do
                if row.id and rows[row.id] ~= row then RestoreRetiredRow(row) end
            end
        end
        for _, row in pairs(rows) do
            if shift and shift ~= 0 and not layout.rowY[row] and Owned(row) and row.GetNumPoints then
                OffsetRow(f, layout, row, shift)
            end
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
        SyncHeader(spy.MainWindow, false)
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
    local function GetStyle()
        local preferences = EUIAddonSkinsDB and EUIAddonSkinsDB.spy
        return preferences and preferences.style or "auto"
    end
    local function NotifyCanvas(key)
        if ns.SettingsPreferenceChanged then ns.SettingsPreferenceChanged("Spy", key) end
    end
    local function SetStyle(value)
        if value ~= "auto" and value ~= "standard" and value ~= "forever" then return end
        SavePreference("style", value); refresh(); NotifySettings(); NotifyCanvas("style")
    end
    local function ResetSkinSettings()
        if EUIAddonSkinsDB then EUIAddonSkinsDB.spy = nil end
        refresh(); NotifySettings(); NotifyCanvas()
    end
    local function ApplyOpacity()
        if Locked() then waiting = true; return end
        if not ns.IsEnabled(module) then return end
        local f = spy.MainWindow
        local entry = f and foreverWindows[f]
        if entry then SyncWindow(f, false, entry.standardLayer, ForeverLook()) end
    end
    local function GetOpacity()
        return math.floor(BackgroundOpacity() * 100 + 0.5)
    end
    local function SetOpacity(value)
        if type(value) ~= "number" or not SafeValue(value) or value ~= value then return end
        local target = math.max(0, math.min(100, value)) / 100
        local current = BackgroundOpacity()
        SavePreference("opacity", target)
        if target ~= current then
            H.Queue(opacityKey, ApplyOpacity)
            NotifyCanvas("opacity")
        end
    end
    module.settingsAppearance = {
        get = function(key) if key == "style" then return GetStyle() end; return GetOpacity() end,
        set = function(key, value)
            if key == "style" then SetStyle(value)
            else SetOpacity(value); NotifySettings() end
        end,
        reset = ResetSkinSettings,
        effectiveStyle = function() return ForeverLook() and "EUI Forever" or "EUI Standard" end,
        supportsForever = SupportsForever,
    }
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
                        get = GetStyle,
                        set = function(_, value) SetStyle(value) end,
                    },
                    opacity = {type = "range", name = "Background Opacity", order = 2,
                        desc = "Forever decorative background only. Spy retains its own bar textures and window fading.",
                        width = "full", min = 0, max = 100, step = 1, bigStep = 5,
                        get = GetOpacity,
                        set = function(_, value) SetOpacity(value) end,
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
        return {text = label, isNotRadio = false, checked = function() return GetStyle() == value end,
            func = function() SetStyle(value) end}
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
                f:HookScript("OnShow", function()
                    if ns.IsEnabled(module) then
                        SyncHeader(f, ForeverLook(), false, true)
                        refresh()
                    end
                end)
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
    H.Hook(spy, "CreateRow", function(_, index)
        if not ns.IsEnabled(module) then return end
        if Locked() then waiting = true; return end
        local main = spy.MainWindow
        local row = main and main.Rows and main.Rows[index]
        -- Native CreateRow returns with the slot hidden. Prepare the owned
        -- trim here, before ManageBarsDisplayed can first show the slot.
        if not row then return end
        if ForeverLook() then
            if not rowArt[row] then SyncRow(row, true) end
        else
            local layout = headerLayouts[main]
            if layout and layout.active and layout.shift ~= 0 and not layout.rowY[row]
                and Owned(row) and row.GetNumPoints then OffsetRow(main, layout, row, layout.shift) end
        end
    end)
    H.Hook(spy, "ResizeMainWindow", function()
        if Locked() then waiting = true; return end
        SyncHeader(spy.MainWindow, ns.IsEnabled(module) and ForeverLook(), true)
    end)
    H.Hook(spy, "BarsChanged", function()
        if not ns.IsEnabled(module) then return end
        if Locked() then waiting = true; return end
        local f = spy.MainWindow
        local layout = f and headerLayouts[f]
        if layout and layout.active then
            local profile = spy.db and spy.db.profile and spy.db.profile.MainWindow
            local height = profile and Positive(profile.RowHeight)
            local spacing = profile and profile.RowSpacing
            local stride = height and SafeValue(spacing) and type(spacing) == "number" and height + spacing or nil
            ShiftList(f, layout, layout.shift or 0, true, stride)
        end
    end)
    H.Hook(spy, "SetCurrentList", function()
        if not ns.IsEnabled(module) then return end
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
    events:SetScript("OnEvent", function(_, event)
        if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
            if ns.IsEnabled(module) then SyncHeader(spy.MainWindow, ForeverLook(), false, true) end
        elseif waiting then
            local f = spy.MainWindow
            local layout = f and headerLayouts[f]
            if not Locked() and layout and layout.active and ns.IsEnabled(module) then
                ShiftList(f, layout, layout.shift or 0, true)
            end
            refresh()
        end
    end)
    module.refresh = refresh
    if S.OnLooksChanged then
        S.OnLooksChanged(function() refresh(); NotifyCanvas("style") end)
    end
    refresh()
end)

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Spy", DefineSkin)
else DefineSkin() end
