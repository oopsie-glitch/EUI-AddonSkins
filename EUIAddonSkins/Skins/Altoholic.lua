local ADDON, ns = ...
local function DefineSkin()
ns.RegisterScopedSkin("Altoholic", "Altoholic", {
    softBorders = true,
    panels = false,
    immediateShow = true,
    borderlessButtons = function(f)
        local parent = f.GetParent and f:GetParent()
        return type(f.SetCategory) == "function" or type(f.SetColumnData) == "function" or type(f.SetColumnTotal) == "function"
            or type(f.DrawArrow) == "function" or (parent and type(parent.DrawRealmLine) == "function")
    end,
    available = function() return _G.Altoholic ~= nil end,
    roots = function() return ns.SkinRoots({"AltoholicFrame", "AltoMessageBox"}, {bottomBar = 24}) end,
    hooks = function(C, refresh)
        if not C.StyleCategory then
            local H, S = C.H, C.S
            local surfaces, clear, zones = {}, {}, {}
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
        end
        for _, method in ipairs({"SwitchToTab", "SetTabs"}) do C.H.Hook(_G.AltoholicFrame, method, C.RefreshNow) end
        for _, method in ipairs({"ToggleUI", "SetPortraitToUnit"}) do C.H.Hook(_G.AltoholicFrame, method, refresh) end
    end,
    visit = function(C, f, kind, refresh)
        local H, S, main = C.H, C.S, _G.AltoholicFrame
        if f == main then H.Portrait(f, true); ns.AttachAccent(S, f) end
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
            H.LegacySlider(f)
            if f.GetOrientation and f:GetOrientation() == "VERTICAL" then
                local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
                if thumb then thumb:SetTexCoord(0, 1, 0, 1); thumb:SetSize(8, 18) end
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
                    return H.Tab(f, main.selectedTab == index)
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
        end
        if kind == "Button" then
            local icon = H.Icon(f)
            if icon then
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
            if label and not f.Icon and not f.icon then H.Action(f); return true end
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
