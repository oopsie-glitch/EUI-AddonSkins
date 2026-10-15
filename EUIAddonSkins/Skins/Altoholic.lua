local ADDON, ns = ...
local function DefineSkin()
ns.RegisterScopedSkin("Altoholic", "Altoholic", {
    softBorders = true,
    available = function() return _G.Altoholic ~= nil end,
    roots = function() return ns.SkinRoots({"AltoholicFrame", "AltoMessageBox"}, {bottomBar = 24}) end,
    hooks = function(C, refresh)
        for _, method in ipairs({"SwitchToTab", "SetTabs", "ToggleUI", "SetPortraitToUnit"}) do C.H.Hook(_G.AltoholicFrame, method, refresh) end
    end,
    visit = function(C, f, kind, refresh)
        local H, S, main = C.H, C.S, _G.AltoholicFrame
        if f == main then H.Portrait(f, true); ns.AttachAccent(S, f) end
        if kind == "Slider" then H.LegacySlider(f); return true end
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
