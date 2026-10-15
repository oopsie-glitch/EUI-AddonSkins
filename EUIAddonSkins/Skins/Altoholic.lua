local ADDON, ns = ...
local function DefineSkin()
ns.RegisterScopedSkin("Altoholic", "Altoholic", {
    softBorders = true,
    available = function() return _G.Altoholic ~= nil end,
    roots = function() return ns.SkinRoots({"AltoholicFrame", "AltoMessageBox"}, {bottomBar = 24}) end,
    hooks = function(C, refresh)
        if not C.StyleCategory then
            local H = C.H
            local function Paint(button)
                if not H.Allowed(button) then return end
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                H.Selection(button, button.data and button.data.isSelected == true)
                for _, key in ipairs({"NormalTexture", "SelectedTexture", "HighlightTexture"}) do H.Fade(button[key]) end
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
        for _, method in ipairs({"SwitchToTab", "SetTabs", "ToggleUI", "SetPortraitToUnit"}) do C.H.Hook(_G.AltoholicFrame, method, refresh) end
    end,
    visit = function(C, f, kind, refresh)
        local H, S, main = C.H, C.S, _G.AltoholicFrame
        if f == main then H.Portrait(f, true); ns.AttachAccent(S, f) end
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
        if kind == "Button" and main then
            for index, tab in ipairs(main.Tabs or {}) do
                if f == tab then
                    -- Keep native external bottom-tab anchors; moving them would overlap data.
                    return H.Tab(f, main.selectedTab == index)
                end
            end
        end
        if f.Background then H.Fade(f.Background) end
        if f.Bg then H.Fade(f.Bg) end
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
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Altoholic", DefineSkin)
else DefineSkin() end
