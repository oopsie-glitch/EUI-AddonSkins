local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("Spy", "Spy", function()
    return _G.Spy and type(_G.Spy.CreateMainWindow) == "function"
end, function(S, module)
    S = ns.CreateSoftSkin(S, module)
    local spy = _G.Spy
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
    local function ForeverLook()
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
    local function Surface(host)
        local plate = host:CreateTexture(nil, "BACKGROUND", nil, 1)
        local grain = host:CreateTexture(nil, "BACKGROUND", nil, 2)
        plate:SetAllPoints(host); grain:SetAllPoints(host)
        -- Same material as RestedXP: EUI exports the rim, not its warm fill.
        plate:SetColorTexture(0.165, 0.115, 0.075, 1)
        if plate.SetGradient and CreateColor then
            plate:SetGradient("VERTICAL", CreateColor(0.120, 0.084, 0.055, 1),
                CreateColor(0.165, 0.115, 0.075, 1))
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
        return plate, grain
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
            layout = {regions = {}, titleWidth = f.Title:GetWidth(), titleHeight = f.Title:GetHeight(),
                wordWrap = f.Title.GetWordWrap and f.Title:GetWordWrap()}
            entry.headerLayout = layout
        end
        if layout.writing then return end
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
                if f.Title.SetWordWrap and layout.wordWrap ~= nil then f.Title:SetWordWrap(layout.wordWrap) end
                entry.host:ClearAllPoints(); entry.host:SetAllPoints(f)
                layout.active = false
            end
            layout.writing = false
            return
        end
        local width, title = f:GetWidth(), f.Title
        if not SafeValue(width) then layout.writing = false; return end
        local counterWidth = 0
        if counter and (not counter.IsVisible or counter:IsVisible()) then
            local alpha = counter.GetAlpha and counter:GetAlpha() or 1
            local size = counter:GetStringWidth()
            if SafeValue(alpha) and SafeValue(size) and alpha > 0 and size > 0 then
                counterWidth = size + 6
            end
        end
        local available = math.max(16, width - 16 - counterWidth)
        if title:GetWidth() ~= available then title:SetWidth(available) end
        if title.SetWordWrap and (not title.GetWordWrap or not title:GetWordWrap()) then title:SetWordWrap(true) end
        local measure = title.GetUnboundedStringWidth or title.GetStringWidth
        local length = measure and measure(title) or available
        if not SafeValue(length) then length = available end
        local line = math.max(12, layout.titleHeight)
        local lines = math.max(1, math.ceil(length / available))
        if title.GetStringHeight then
            local height = title:GetStringHeight()
            if SafeValue(height) then lines = math.max(lines, math.ceil(height / line)) end
        end
        local titleHeight = line * lines
        if title:GetHeight() ~= titleHeight then title:SetHeight(titleHeight) end
        -- Reuse the native 34-unit header and extend only its decorative top.
        -- This leaves every secure row, native resize bound and saved size alone.
        local top = titleHeight
        Anchor(title, "TOPLEFT", f, "TOPLEFT", 8, top - 4)
        if counter then Anchor(counter, "TOPRIGHT", f, "TOPRIGHT", -8, top - 4) end
        if f.CountButton then Anchor(f.CountButton, "TOPRIGHT", f, "TOPRIGHT", -6, top - 4) end
        local total, number = 0, 0
        for _, key in ipairs(controlOrder) do
            local button = f[key]
            if button and (not button.IsShown or button:IsShown()) then
                total, number = total + button:GetWidth(), number + 1
            end
        end
        local gap = number > 1 and math.min(2, math.max(0, (width - 6 - total) / (number - 1))) or 0
        local offset = 3
        for _, key in ipairs(controlOrder) do
            local button = f[key]
            if button and (not button.IsShown or button:IsShown()) then
                Anchor(button, "RIGHT", f, "TOPRIGHT", -offset, -21)
                offset = offset + button:GetWidth() + gap
            end
        end
        if layout.top ~= top or not layout.active then
            entry.host:ClearAllPoints()
            entry.host:SetPoint("TOPLEFT", f, "TOPLEFT", 0, top)
            entry.host:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
            layout.top = top
        end
        if entry.seam and not layout.seamAnchored then
            Anchor(entry.seam, "TOPLEFT", f, "TOPLEFT", 4, -8)
            entry.seam:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -8)
            layout.seamAnchored = true
        end
        layout.active, layout.writing = true, false
    end
    local function SyncWindow(f, alert, standardLayer, forever)
        local entry = foreverWindows[f]
        if not entry and forever and Owned(f) then
            local host = Host(f)
            local plate, grain = Surface(host)
            entry = {host = host, plate = plate, grain = grain, rim = Rim(host)}
            foreverWindows[f] = entry
            if f.Background and f.Background.GetAlpha then
                entry.nativeBackground = f.Background
                entry.backgroundAlpha = f.Background:GetAlpha()
            end
            if f.TitleBar and not alert then
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
        if not entry then return end
        entry.standardLayer = standardLayer or entry.standardLayer
        Alpha(entry.host, forever and 1 or 0)
        ShowRim(entry.rim, forever)
        if entry.standardLayer then Alpha(entry.standardLayer, forever and 0 or 1) end
        if entry.nativeBackground then Alpha(entry.nativeBackground, forever and 0 or entry.backgroundAlpha) end
        if forever then
            local alpha = f == spy.MainWindow and BackgroundOpacity() or PanelAlpha()
            local grainAlpha = alpha * 0.12
            Alpha(entry.grain, grainAlpha)
            Alpha(entry.plate, grainAlpha < 1 and (alpha - grainAlpha) / (1 - grainAlpha) or 0)
            -- The warm plate/grain already cover the header. No stacked fill.
            if entry.band then Alpha(entry.band, f == spy.MainWindow and 0 or alpha * 0.16); Alpha(entry.seam, 1) end
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
            rule:SetHeight(1); rule:SetColorTexture(0.49, 0.33, 0.18, 0.24)
            entry = {host = host}
            if row.id then rowSlots[row.id] = entry end
        end
        if not entry then return end
        if entry.row ~= row then
            if entry.row then
                rowArt[entry.row] = nil
            end
            entry.row = row
            local host = entry.host
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
                if not Locked() then Alpha(host, ns.IsEnabled(module) and ForeverLook() and 1 or 0)
                else waiting = true end
            end)
            row:HookScript("OnHide", function()
                if entry.row ~= row then return end
                if not Locked() then Alpha(host, 0) else waiting = true end
            end)
            end
        end
        Alpha(entry.host, forever and (not row.IsShown or row:IsShown()) and 1 or 0)
    end
    local function SyncRows(forever)
        local rows = spy.MainWindow and spy.MainWindow.Rows or {}
        for row, entry in pairs(rowArt) do
            if row.id and rows[row.id] ~= row then
                Alpha(entry.host, 0)
                rowArt[row] = nil
                entry.row = nil
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
                            SavePreference("opacity", math.max(0, math.min(100, value)) / 100)
                            H.Queue(opacityKey, ApplyOpacity)
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
