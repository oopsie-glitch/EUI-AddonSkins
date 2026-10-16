local ADDON, ns = ...
local function DefineSkin()
ns.RegisterScopedSkin("Altoholic", "Altoholic", {
    softBorders = true,
    panels = false,
    preserveTextColors = true,
    immediateShow = true,
    borderlessButtons = function(f)
        local parent = f.GetParent and f:GetParent()
        return type(f.SetCategory) == "function" or type(f.SetColumnData) == "function" or type(f.SetColumnTotal) == "function"
            or type(f.DrawArrow) == "function" or (parent and type(parent.DrawRealmLine) == "function")
    end,
    available = function() return _G.Altoholic ~= nil end,
    roots = function() return ns.SkinRoots({"AltoholicFrame", "AltoMessageBox"}, {noTopBar = true, noAccent = true}) end,
    hooks = function(C, refresh)
        if not C.StyleCategory then
            local H, S = C.H, C.S
            local surfaces, clear, zones = {}, {}, {}
            local primitives, edges, tabLabels, dropdowns, tabPaints = {}, {}, {}, {}, {}
            local calendarDays, calendarBorders, calendarLayouts = {}, {}, {}
            local atlasIcons, square = {}, S.SquareIcon
            S.SquareIcon = function(icon, parent)
                if not atlasIcons[icon] then return square(icon, parent) end
            end
            C.Primitive = function(f, key, method, ...)
                local entry = primitives[f]
                if not entry then entry = {}; primitives[f] = entry end
                if not entry[key] then
                    local before = {}; for _, region in ipairs(H.Regions(f)) do before[region] = true end
                    method(f, ...)
                    local added = {}
                    for _, region in ipairs(H.Regions(f)) do if not before[region] then added[#added + 1] = region end end
                    entry[key] = added
                else method(f, ...) end
                return entry[key]
            end
            C.Font = function(text, size, r, g, b)
                H.Font(text, r, g, b)
                if H.Allowed(text) and text.GetFont and size then
                    local path, _, flags = text:GetFont()
                    if path then text:SetFont(path, size, flags or "") end
                end
            end
            C.Tab = function(f, selected)
                if not H.Allowed(f) then return end
                local added = C.Primitive(f, "tab", H.Tab, selected)
                local native = (f.GetFontString and f:GetFontString()) or f.Text
                local label = tabLabels[f]
                if not label then
                    for _, region in ipairs(added) do
                        if region:GetObjectType() == "FontString" then label = region end
                    end
                    label = label or native; tabLabels[f] = label
                end
                if label and native and label ~= native then H.Fade(native) end
                if label then
                    local entry = tabPaints[f]
                    if not entry then
                        entry = {}; tabPaints[f] = entry
                        local painting = false
                        entry.paint = function()
                            if painting then return end
                            if InCombatLockdown and InCombatLockdown() then refresh(); return end
                            local r, g, b = S.GetAccentColor(); local shade = entry.selected and 1 or 0.65
                            painting = true; label:SetTextColor(r * shade, g * shade, b * shade, 1); painting = false
                        end
                        H.Hook(label, "SetTextColor", entry.paint)
                    end
                    entry.selected = selected; entry.paint(); H.Font(label)
                end
            end
            C.Item = function(f, icon, atlas)
                if not H.Allowed(f) or not H.Texture(icon) then return end
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                if atlas then atlasIcons[icon] = true else S.SquareIcon(icon) end
                if f.SetBackdrop then f:SetBackdrop(nil) end
                H.Fade(f.NormalTexture)
                local border = H.Texture(f.IconBorder)
                if not border then return end
                H.Fade(border)
                local strips = edges[f]
                if not strips then
                    strips = {}; edges[f] = strips
                    for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                        local strip = f:CreateTexture(nil, "OVERLAY", nil, 5)
                        if side == "TOP" or side == "BOTTOM" then
                            strip:SetPoint(side .. "LEFT", icon, side .. "LEFT"); strip:SetPoint(side .. "RIGHT", icon, side .. "RIGHT"); strip:SetHeight(1)
                        else
                            strip:SetPoint("TOP" .. side, icon, "TOP" .. side); strip:SetPoint("BOTTOM" .. side, icon, "BOTTOM" .. side); strip:SetWidth(1)
                        end
                        strips[#strips + 1] = strip
                    end
                end
                local r, g, b = 0.15, 0.15, 0.15
                if border.IsShown and border:IsShown() then r, g, b = border:GetVertexColor() end
                for _, strip in ipairs(strips) do strip:SetColorTexture(r, g, b, 1) end
                H.Font(f.Name); H.Font(f.Count)
            end
            C.GridRow = function(row)
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                if row.Name then C.FlatAction(row.Name) end
                for index = 1, 13 do
                    local cell = row["Item" .. index]
                    if cell then C.Item(cell, cell.Background) end
                end
            end
            C.Local = function(f) C.RefreshControlsNow(f) end
            C.CalendarDay = function(day)
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                local normal = day.GetNormalTexture and H.Texture(day:GetNormalTexture())
                local shade = normal and normal.GetVertexColor and normal:GetVertexColor() or 1
                local dark = shade < 0.9
                local br, bg, bb, ba = 0.08, 0.08, 0.08, 0.92
                if S.GetPanelColor then br, bg, bb, ba = S.GetPanelColor() end
                local dim = dark and 0.4 or 1
                local fill = C.Primitive(day, "calendarDay", S.Button, {"Date", "Count"})
                H.Fade(normal)
                for _, region in ipairs(fill) do
                    if H.Texture(region) and region:GetDrawLayer() == "BACKGROUND" then
                        region:SetColorTexture(br * dim, bg * dim, bb * dim, ba)
                    elseif H.Texture(region) and region:GetDrawLayer() == "HIGHLIGHT" then
                        region:SetColorTexture(1, 1, 1, 0.05)
                    end
                end
                local border = calendarBorders[day]
                if not border then
                    -- Keep these visual-only dividers outside EUI's direct
                    -- texture re-strip registry. The child never takes input.
                    local layer = CreateFrame("Frame", nil, day)
                    layer:SetAllPoints(day)
                    if layer.EnableMouse then layer:EnableMouse(false) end
                    if day.GetFrameLevel and layer.SetFrameLevel then layer:SetFrameLevel(day:GetFrameLevel()) end
                    border = {}; calendarBorders[day] = border
                    for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
                        local edge = layer:CreateTexture(nil, "OVERLAY", nil, 7)
                        if side == "TOP" or side == "BOTTOM" then
                            edge:SetPoint(side .. "LEFT", day, side .. "LEFT"); edge:SetPoint(side .. "RIGHT", day, side .. "RIGHT"); edge:SetHeight(1)
                        else
                            edge:SetPoint("TOP" .. side, day, "TOP" .. side); edge:SetPoint("BOTTOM" .. side, day, "BOTTOM" .. side); edge:SetWidth(1)
                        end
                        border[side] = edge
                    end
                end
                local now = C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime and C_DateAndTime.GetCurrentCalendarTime()
                local today = now and day.day == now.monthDay and day.month == now.month and day.year == now.year
                local r, g, b = 0.18, 0.18, 0.18
                if today then r, g, b = S.GetAccentColor() end
                local index = calendarDays[day]
                for side, edge in pairs(border) do
                    local outer = side == "TOP" or side == "LEFT" or side == "RIGHT" and index % 7 == 0 or side == "BOTTOM" and index > 35
                    edge:SetColorTexture(r, g, b, (today or outer) and 1 or 0)
                end
                local color = dark and 0.38 or 0.95
                H.Font(day.Date, color, color, color)
                H.Font(day.Count) -- Native event count/visibility remains authoritative.
            end
            C.IsCalendarDay = function(day) return calendarDays[day] ~= nil end
            C.Calendar = function(calendar)
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                for index = 1, 42 do
                    local day = calendar["Day" .. index]
                    if H.Allowed(day) and not calendarDays[day] then
                        calendarDays[day] = index
                        H.Hook(day, "Update", C.CalendarDay)
                    end
                end
                for index = 1, 7 do
                    H.Fade(calendar["Weekday" .. index .. "Background"])
                    H.Font(calendar["Weekday" .. index .. "Name"], 1, 1, 0.604)
                end
                C.Font(calendar.MonthYear, 16, 0.95, 0.95, 0.95)
                S.SoftPageButton(calendar.PrevMonth, "<", 16)
                S.SoftPageButton(calendar.NextMonth, ">", 16)
                if not calendarLayouts[calendar] then
                    calendarLayouts[calendar] = true
                    local first, last = calendar.Day1, calendar.Day7
                    calendar.PrevMonth:ClearAllPoints(); calendar.PrevMonth:SetPoint("TOPLEFT", first, "TOPLEFT", 0, 62)
                    calendar.NextMonth:ClearAllPoints(); calendar.NextMonth:SetPoint("TOPRIGHT", last, "TOPRIGHT", 0, 62)
                    calendar.MonthYear:ClearAllPoints()
                    calendar.MonthYear:SetPoint("LEFT", calendar.PrevMonth, "RIGHT", 8, 0)
                    calendar.MonthYear:SetPoint("RIGHT", calendar.NextMonth, "LEFT", -8, 0)
                    local agenda = _G.AltoholicFrame and AltoholicFrame.TabAgenda
                    local previous
                    for _, key in ipairs({"CharacterFilterIcon", "DateFilterIcon", "EventFilterIcon"}) do
                        local button = agenda and agenda[key]
                        if H.Allowed(button) and calendar.EventList then
                            button:SetSize(32, 32); button:ClearAllPoints()
                            if previous then button:SetPoint("LEFT", previous, "RIGHT", 8, 0)
                            else button:SetPoint("TOPLEFT", calendar.EventList, "TOPLEFT", 32, 59) end
                            previous = button
                        end
                    end
                end
                H.Hook(calendar, "Update", C.Calendar)
                if H.Allowed(calendar.EventList) then H.Hook(calendar.EventList, "Update", C.Local) end
            end
            C.Dropdown = function(f)
                dropdowns[f] = true
                local icon = H.Texture(f.Icon); local alpha = icon and icon:GetAlpha()
                local added = C.Primitive(f, "dropdown", S.Dropdown)
                if icon then icon:SetAlpha(alpha) end
                for _, key in ipairs({"Left", "Middle", "Right"}) do H.Fade(f[key]) end
                for _, region in ipairs(H.Regions(f.Button)) do if H.Texture(region) then H.Fade(region) end end
                f.Button:ClearAllPoints(); f.Button:SetPoint("RIGHT", f, "RIGHT", -3, 0); f.Button:SetSize(20, 20)
                f:SetSize(f:GetWidth(), 24)
                local showIcon = icon and (not icon.IsShown or icon:IsShown()) and alpha > 0
                f.Text:ClearAllPoints(); f.Text:SetPoint("LEFT", f, "LEFT", showIcon and 26 or 6, 0)
                f.Text:SetPoint("RIGHT", f, "RIGHT", -26, 0)
                H.Font(f.Text, f.isDisabled and 0.5 or 0.9, f.isDisabled and 0.5 or 0.9, f.isDisabled and 0.5 or 0.92)
                for _, arrow in ipairs(added) do
                    if H.Texture(arrow) and arrow:GetDrawLayer() == "OVERLAY" then
                        arrow:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-left.png"); arrow:SetTexCoord(0, 1, 0, 1)
                        if arrow.SetRotation then arrow:SetRotation(math.pi / 2) end
                        arrow:SetSize(9, 9); arrow:SetVertexColor(0.75, 0.75, 0.77, 1)
                    end
                end
                for _, method in ipairs({"SetMenuWidth", "SetText", "JustifyText", "EnableDropDown", "DisableDropDown"}) do H.Hook(f, method, C.Local) end
            end
            C.DropChild = function(f) return dropdowns[f:GetParent()] end
            -- This helper instance belongs only to Altoholic. Both full and
            -- local/scroll scans exclude its explicitly registered hidden
            -- tabs/panels; arbitrary hidden children can still initialize.
            local scan = H.Scan
            H.Scan = function(root, onRefresh, visit)
                local exclude = {}
                local main = _G.AltoholicFrame
                for _, tab in pairs(main and main.TabFrames or {}) do
                    if tab.IsShown and not tab:IsShown() then exclude[tab] = true end
                    for _, panel in pairs(tab.Panels or {}) do
                        if panel.IsShown and not panel:IsShown() then exclude[panel] = true end
                    end
                end
                return scan(root, onRefresh, visit, exclude)
            end
            C.ClearInset = function(f)
                if not H.Allowed(f) then return end
                if not clear[f] then
                    clear[f] = true
                    if S.Inset then S.Inset(f) end
                    H.Fade(f.bg); H.Fade(f.Bg)
                    if f.NineSlice then S.FadeNineSlice(f.NineSlice) end
                end
                if f.SetBackdrop then f:SetBackdrop(nil) end
            end
            C.Zone = function(f, wash)
                if not H.Allowed(f) then return end
                C.ClearInset(f)
                if wash and not zones[f] then
                    zones[f] = true
                    -- A separate layer survives EUI's own inset refreshes.
                    local layer = CreateFrame("Frame", nil, f)
                    layer:SetAllPoints(f)
                    if f.GetFrameLevel and layer.SetFrameLevel then layer:SetFrameLevel(f:GetFrameLevel()) end
                    local fill = layer:CreateTexture(nil, "BACKGROUND")
                    fill:SetAllPoints(layer); fill:SetColorTexture(1, 1, 1, 0.02)
                end
            end
            C.StyleCell = function(button) C.FlatAction(button) end
            C.StyleHeader = function(button) C.FlatAction(button, {"Arrow"}) end
            C.FlatAction = function(button, keep, selected)
                if not H.Allowed(button) then return end
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                local surface, before = surfaces[button]
                if not surface then
                    before = {}
                    for _, region in ipairs(H.Regions(button)) do before[region] = true end
                end
                if selected ~= nil then H.Selection(button, selected)
                else H.Action(button, keep) end
                if before then
                    surface = {}; surfaces[button] = surface
                    for _, region in ipairs(H.Regions(button)) do
                        if not before[region] and region ~= button.euiSelection and H.Texture(region) then
                            local layer = region:GetDrawLayer()
                            if layer == "BACKGROUND" or layer == "HIGHLIGHT" then
                                surface[#surface + 1] = {region, layer}
                            end
                        end
                    end
                end
                for _, entry in ipairs(surface) do
                    if entry[2] == "BACKGROUND" then entry[1]:SetColorTexture(0, 0, 0, 0)
                    else entry[1]:SetColorTexture(1, 1, 1, 0.06) end
                end
            end
            local function Paint(button)
                if not H.Allowed(button) then return end
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                C.FlatAction(button, nil, button.data and button.data.isSelected == true or false)
                for _, key in ipairs({"NormalTexture", "SelectedTexture", "HighlightTexture", "Lines"}) do H.Fade(button[key]) end
            end
            C.StyleCategory = function(button)
                if not H.Allowed(button) or type(button.SetCategory) ~= "function" or type(button.SetSelected) ~= "function" then return end
                for _, method in ipairs({"SetCategory", "SetSubCategory", "SetSubSubCategory", "SetSelected"}) do H.Hook(button, method, Paint) end
                Paint(button)
            end
            C.StyleCategories = function(list)
                for _, button in pairs(list.Buttons or {}) do C.StyleCategory(button) end
            end
            C.StyleSelectedTab = function(main)
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                for _, tab in pairs(main.TabFrames or {}) do
                    if H.Allowed(tab) and tab.GetID and tab:GetID() == main.selectedTab then
                        C.RefreshControlsNow(tab)
                        for index, button in ipairs(main.Tabs or {}) do C.Tab(button, main.selectedTab == index) end
                        return
                    end
                end
                -- Older layouts may not expose AddonFactory's tab registry.
                C.RefreshNow()
            end
            C.StyleCurrentPanel = function(tab)
                if type(tab.GetCurrentPanel) ~= "function" then return end
                local panel = tab:GetCurrentPanel()
                C.RefreshControlsNow(panel)
            end
        end
        C.H.Hook(_G.AltoholicFrame, "SwitchToTab", C.StyleSelectedTab)
        C.H.Hook(_G.AltoholicFrame, "SetTabs", C.RefreshNow)
        for _, method in ipairs({"ToggleUI", "SetPortraitToUnit"}) do C.H.Hook(_G.AltoholicFrame, method, refresh) end
    end,
    visit = function(C, f, kind, refresh)
        local H, S, main = C.H, C.S, _G.AltoholicFrame
        if f == main then H.Portrait(f, true, true) end
        if kind == "Frame" and f.Day1 and f.Day7 and f.MonthYear and H.Allowed(f.PrevMonth) and H.Allowed(f.NextMonth) then
            C.Calendar(f)
        end
        if kind == "Button" and C.IsCalendarDay(f) then C.CalendarDay(f); return true end
        if kind == "Button" and H.Texture(f.Background) and H.Texture(f.IconBorder) and f.Name then
            C.Item(f, f.Background); return true
        end
        if kind == "Button" and f.Item1 and H.Texture(f.Item1.Background) and H.Texture(f.Item1.IconBorder) then
            H.Hook(f, "Update", C.GridRow); C.GridRow(f)
        end
        if type(f.ShowPanel) == "function" and type(f.GetCurrentPanel) == "function" then
            H.Hook(f, "ShowPanel", C.StyleCurrentPanel)
        end
        if f.CategoriesList and f.Background then
            C.Zone(f.CategoriesList, false)
            C.Zone(f.Background, true)
            C.Zone(f.HeaderContainer, true)
        end
        if type(f.UpdateCategories) == "function" and type(f.Buttons) == "table" then
            H.Hook(f, "UpdateCategories", C.StyleCategories)
            C.StyleCategories(f)
        end
        if type(f.SetCategory) == "function" and type(f.SetSelected) == "function" then
            C.StyleCategory(f)
            return true
        end
        if kind == "ScrollFrame" then
            -- AddonFactory keeps the Blizzard scrollbar border on its parent,
            -- outside the slider's own regions.
            for _, key in ipairs({"scrollBorderTop", "scrollBorderMiddle", "scrollBorderBottom", "scrollFrameScrollBarBackground"}) do
                H.Fade(f[key])
            end
        end
        if kind == "Slider" then
            if H.Allowed(f.Backdrop) then C.ClearInset(f.Backdrop) end
            H.LegacySlider(f)
            if f.GetOrientation and f:GetOrientation() == "VERTICAL" then
                local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
                if thumb then thumb:SetTexCoord(0, 1, 0, 1); thumb:SetSize(4, 18); thumb:SetColorTexture(1, 1, 1, 0.3) end
            elseif f.GetOrientation and f:GetOrientation() == "HORIZONTAL" then
                local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
                if thumb then thumb:SetTexCoord(0, 1, 0, 1); thumb:SetSize(8, 12) end
                C.Font(f.Text, 10, 0.88, 0.88, 0.9); C.Font(f.Low, 9, 0.6, 0.6, 0.62); C.Font(f.High, 9, 0.6, 0.6, 0.62)
                if H.Allowed(f.Text) then f.Text:ClearAllPoints(); f.Text:SetPoint("BOTTOM", f, "TOP", 0, 5) end
                if H.Allowed(f.Low) then f.Low:ClearAllPoints(); f.Low:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -4) end
                if H.Allowed(f.High) then f.High:ClearAllPoints(); f.High:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -4) end
            end
            return true
        end
        if type(f.DrawRealmLine) == "function" and f.Collapse and f.Item1 then
            local function HideUnusedRealmCells(row)
                -- Summary rows define twelve cells, but DrawRealmLine only
                -- hides 2..10. The remaining empty buttons extend off-window.
                for index = 11, 12 do
                    local cell = row["Item" .. index]
                    if H.Allowed(cell) and cell.Hide then cell:Hide() end
                end
            end
            H.Hook(f, "DrawRealmLine", HideUnusedRealmCells)
            if H.Allowed(f.Collapse) and f.Collapse.IsShown and f.Collapse:IsShown() and not f.character then
                HideUnusedRealmCells(f)
            end
        end
        if kind == "Button" then
            local parent = f.GetParent and f:GetParent()
            if type(f.SetColumnData) == "function" or type(f.SetColumnTotal) == "function"
                or (parent and type(parent.DrawRealmLine) == "function" and f ~= parent.Collapse) then
                H.Hook(f, "SetColumnData", C.StyleCell); H.Hook(f, "SetColumnTotal", C.StyleCell)
                C.FlatAction(f)
                return true
            end
            if type(f.DrawArrow) == "function" and f.Arrow then
                H.Hook(f, "DrawArrow", C.StyleHeader)
                C.StyleHeader(f)
                return true
            end
        end
        if kind == "Button" and main then
            for index, tab in ipairs(main.Tabs or {}) do
                if f == tab then
                    -- Keep native external bottom-tab anchors; moving them would overlap data.
                    C.Tab(f, main.selectedTab == index); return true
                end
            end
        end
        if H.Texture(f.Background) then H.Fade(f.Background) end
        if H.Texture(f.Bg) then H.Fade(f.Bg) end
        local resize = false
        if kind == "Button" and f.GetPoint and f.GetParent and f:GetParent() == main
            and f.GetWidth and f:GetWidth() <= 25 then
            local point = f:GetPoint(1)
            resize = point == "BOTTOMRIGHT"
        end
        H.Resize(f, resize)
        if kind == "CheckButton" and (f.locLabel or f.module and f.option) then
            S.Checkbox(f, {borderInset = 4, hover = 0.06})
            local check = f.GetCheckedTexture and H.Texture(f:GetCheckedTexture())
            if check then
                if check.SetDesaturated then check:SetDesaturated(true) end
                check:ClearAllPoints(); check:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4); check:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
                local r, g, b = S.GetAccentColor(); check:SetVertexColor(r, g, b, 1)
            end
            local shade = f.IsEnabled and not f:IsEnabled() and 0.5 or 0.88
            H.Font(f.Text, shade, shade, shade); return true
        end
        if kind == "EditBox" and main and f == main.SearchBox then
            local icon = H.Texture(f.searchIcon) or H.Texture(f.SearchIcon)
            local alpha = icon and icon:GetAlpha()
            for _, region in ipairs(C.Primitive(f, "input", S.EditBox)) do
                if H.Texture(region) and region:GetDrawLayer() == "BACKGROUND" then region:SetColorTexture(0.055, 0.055, 0.055, 0.9) end
            end
            if icon then icon:SetAlpha(alpha) end
            if f.SetFont and S.GetFont then
                local path, flags = S.GetFont(); local _, size = f:GetFont()
                if path then f:SetFont(path, size or 11, flags or "") end
            end
            return true
        end
        if kind == "Frame" and f.Initialize and (type(f.initialize) == "function" or f.AddButtonInfo) then
            C.MenuOwner(f)
            local function BindLists()
                -- AddonFactory exposes its otherwise private pool through this controller method.
                if not C.menuPool and LibStub then
                    local mvc = LibStub("LibMVC-1.0", true)
                    if mvc and mvc.BindViewToController then
                        local proxy = CreateFrame("Frame")
                        mvc:BindViewToController(proxy, "AddonFactory.DropDownList")
                        C.menuPool = proxy
                    end
                end
                local proxy = C.menuPool
                if proxy and proxy.GetListFromPool and ns.BindPopupList then
                    for level = 1, 8 do
                        local list = proxy:GetListFromPool(level)
                        if list then ns.BindPopupList(S, C.module, f, list) end
                    end
                end
            end
            H.Hook(f, "Initialize", BindLists)
            H.Hook(f, "Toggle", BindLists)
            BindLists()
            if H.Allowed(f.Button) and H.Allowed(f.Text) and f.Left and f.Middle and f.Right then C.Dropdown(f); return true end
        end
        if kind == "Button" then
            if C.DropChild(f) then return true end
            local parent = f:GetParent()
            if parent and (parent.PrevMonth == f or parent.NextMonth == f) then
                S.SoftPageButton(f, parent.NextMonth == f and ">" or "<", 16); return true
            end
            if parent and (parent.NextPage == f or parent.PrevPage == f) then
                S.SoftPageButton(f, parent.NextPage == f and ">" or "<", 12); return true
            end
            if parent and parent.Item1 and H.Texture(parent.Item1.Background) and parent.Name == f then C.FlatAction(f); return true end
            local icon = H.Icon(f)
            if icon then
                if H.Texture(f.IconBorder) then
                    C.Item(f, icon, type(f.SetClass) == "function")
                    for _, method in ipairs({"SetItem", "SetRarity", "SetClass"}) do H.Hook(f, method, C.Local) end
                    return true
                end
                if f.GetWidth and f.GetHeight and f:GetWidth() == f:GetHeight() then
                    H.Action(f, {"Icon", "icon"}); S.SquareIcon(icon, f)
                    return true
                end
            end
            local normal = f.GetNormalTexture and f:GetNormalTexture()
            local path = normal and normal.GetTexture and normal:GetTexture()
            if path == 130821 or path == 130838 or type(path) == "string" and (path:find("MinusButton") or path:find("PlusButton")) then
                H.Toggle(f, path == 130821 or type(path) == "string" and path:find("MinusButton"))
                H.Hook(f, "SetNormalTexture", refresh)
                return true
            end
            if normal and f.GetWidth and f.GetHeight and f:GetWidth() == f:GetHeight()
                and f:GetWidth() >= 28 and (type(path) == "number" or type(path) == "string" and path:lower():find("interface[/\\]icons")) then
                f.euiToolbarIcon = normal
                H.Action(f, {"euiToolbarIcon"}); S.SquareIcon(normal, f)
                return true
            end
            local label = (f.GetFontString and f:GetFontString()) or f.Text or f.text
            if label and not f.Icon and not f.icon then
                H.Action(f)
                local shade = f.IsEnabled and not f:IsEnabled() and 0.5 or 0.9
                H.Font(label, shade, shade, shade); return true
            end
        end
        if H.Allowed(f.Inset) then
            C.ClearInset(f.Inset)
            if f.CloseButton and H.Allowed(f.CloseButton) then S.CloseButton(f.CloseButton) end
            for _, region in ipairs(H.Regions(f)) do H.Font(region) end
            return true -- Prevent the generic adapter adding an opaque inset panel.
        end
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Altoholic", DefineSkin)
else DefineSkin() end
