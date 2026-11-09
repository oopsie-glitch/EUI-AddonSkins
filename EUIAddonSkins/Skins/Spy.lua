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
    local foreverWindows, rowArt, rowSlots, controlArt, rowKinds = {}, {}, {}, {}, setmetatable({}, {__mode = "k"})
    local menuOwners = setmetatable({}, {__mode = "k"})
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
    local function PanelAlpha()
        local _, _, _, alpha = S.GetPanelColor()
        if type(alpha) ~= "number" or not SafeValue(alpha) or alpha ~= alpha then return 0.92 end
        return math.max(0, math.min(1, alpha))
    end
    local function SyncControl(button, forever)
        local entry = controlArt[button]
        if not entry and forever and H.Allowed(button) then
            local host = Host(button)
            entry = {host = host, rim = Rim(host), colors = {}}
            controlArt[button] = entry
            for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture"}) do
                local texture = button[getter] and button[getter](button)
                if texture and texture.GetVertexColor then
                    entry.colors[texture] = {texture:GetVertexColor()}
                end
            end
        end
        if not entry then return end
        Alpha(entry.host, forever and 1 or 0)
        ShowRim(entry.rim, forever)
        if entry.active == forever then return end
        entry.active = forever
        for texture, saved in pairs(entry.colors) do
            if forever then texture:SetVertexColor(0.91, 0.71, 0.43, saved[4])
            else texture:SetVertexColor(unpack(saved)) end
        end
    end
    local controls = {"CloseButton", "LeftButton", "RightButton", "ClearButton", "StatsButton", "CountButton"}
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
            local alpha = PanelAlpha()
            local grainAlpha = alpha * 0.12
            Alpha(entry.grain, grainAlpha)
            Alpha(entry.plate, grainAlpha < 1 and (alpha - grainAlpha) / (1 - grainAlpha) or 0)
            if entry.band then Alpha(entry.band, alpha * 0.16); Alpha(entry.seam, alpha) end
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
            if f[key] then SyncControl(f[key], forever) end
        end
    end
    local function SyncRow(row, classTint, forever)
        if not Owned(row) or not Owned(row.StatusBar) then return end
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
                if entry.texture and entry.nativeAlpha then Alpha(entry.texture, entry.nativeAlpha) end
            end
            entry.row, entry.texture, entry.nativeAlpha, entry.classTint = row, nil, nil, nil
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
        if classTint ~= nil then entry.classTint = classTint end
        local texture = row.StatusBar.GetStatusBarTexture and row.StatusBar:GetStatusBarTexture()
        if texture ~= entry.texture then
            if entry.texture and entry.nativeAlpha then Alpha(entry.texture, entry.nativeAlpha) end
            entry.texture = texture
            entry.nativeAlpha = texture and texture.GetAlpha and texture:GetAlpha()
        end
        if entry.texture and entry.nativeAlpha then
            -- Retain native RGB, values, text alpha, flags and status colours.
            Alpha(entry.texture, forever and entry.classTint and entry.nativeAlpha * 0.32 or entry.nativeAlpha)
        end
        Alpha(entry.host, forever and (not row.IsShown or row:IsShown()) and 1 or 0)
    end
    local function InitialClassFill(row)
        local bar = row.StatusBar
        if not (bar and bar.GetStatusBarColor) then return false end
        local r, g, b = bar:GetStatusBarColor()
        if not (SafeValue(r) and SafeValue(g) and SafeValue(b)) then return false end
        local profile = spy.db and spy.db.profile
        local colors = profile and profile.Colors and profile.Colors.Class or _G.RAID_CLASS_COLORS
        for _, color in pairs(colors or {}) do
            if type(color) == "table" and color.r and color.g and color.b
                and math.abs(r - color.r) < 0.004 and math.abs(g - color.g) < 0.004
                and math.abs(b - color.b) < 0.004 then return true end
        end
        return false
    end
    local function SyncRows(forever)
        local rows = spy.MainWindow and spy.MainWindow.Rows or {}
        for row, entry in pairs(rowArt) do
            if row.id and rows[row.id] ~= row then
                if entry.texture and entry.nativeAlpha then Alpha(entry.texture, entry.nativeAlpha) end
                Alpha(entry.host, 0)
                rowArt[row] = nil
                entry.row, entry.texture, entry.nativeAlpha = nil, nil, nil
            end
        end
        for _, row in pairs(rows) do
            local classTint = rowKinds[row]
            if classTint == nil and forever then classTint = InitialClassFill(row) end
            SyncRow(row, classTint, forever)
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
        for row in pairs(rowArt) do SyncRow(row, nil, false) end
        for popup in pairs(reasonDialogs) do
            if ns.StyleTextureDialog then ns.StyleTextureDialog(S, module, popup, false) end
        end
        if ns.RefreshPopupMenusNow then ns.RefreshPopupMenusNow() end
    end
    local function OpenSettings()
        if Locked() then waiting = true; return end
        local registry = LibStub and LibStub("AceConfigRegistry-3.0", true)
        local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
        if not (registry and registry.RegisterOptionsTable and dialog and dialog.Open) then return end
        if not settingsRegistered then
            registry:RegisterOptionsTable(APP, {
                type = "group", name = "Spy — EUI AddonSkins", args = {
                    style = {type = "select", name = "Style", order = 1, width = "full",
                        values = {auto = "Automatic", standard = "EUI Standard", forever = "EUI Forever"},
                        get = function() return EUIAddonSkinsDB and EUIAddonSkinsDB.spy and EUIAddonSkinsDB.spy.style or "auto" end,
                        set = function(_, value)
                            if value ~= "auto" and value ~= "standard" and value ~= "forever" then return end
                            EUIAddonSkinsDB = EUIAddonSkinsDB or {}
                            EUIAddonSkinsDB.spy = EUIAddonSkinsDB.spy or {}
                            EUIAddonSkinsDB.spy.style = value
                            refresh()
                        end,
                    },
                    opacity = {type = "description", name = "Opacity uses Spy's existing window controls and the EllesmereUI panel appearance.", order = 2},
                },
            })
            if dialog.SetDefaultSize then dialog:SetDefaultSize(APP, 360, 180) end
            settingsRegistered = true
        end
        dialog:Open(APP)
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
        if addSettings and type(menu.initialize) == "function" and not menuOwners[menu] then
            local original = menu.initialize
            menuOwners[menu] = original
            menu.initialize = function(self, level, ...)
                local result = pack(original(self, level, ...))
                if ns.IsEnabled(module) and (level or 1) == 1 and UIDropDownMenu_AddButton then
                    UIDropDownMenu_AddButton({text = "EUI AddonSkins…", notCheckable = true, func = OpenSettings}, level or 1)
                end
                return unpack(result, 1, result.n)
            end
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
        if H.Allowed(_G.SpyStatsFrameTopCloseButton) then SyncControl(_G.SpyStatsFrameTopCloseButton, ForeverLook()) end
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
    H.Hook(spy, "SetBar", function(_, num, _, _, _, group)
        if not SafeValue(num) or type(num) ~= "number" or not SafeValue(group) then return end
        local row = spy.MainWindow and spy.MainWindow.Rows and spy.MainWindow.Rows[num]
        if row then rowKinds[row] = group == "Class" end
        if Locked() then waiting = true; return end
        SyncRow(row, group == "Class", ForeverLook())
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
