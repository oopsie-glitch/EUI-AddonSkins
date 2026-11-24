local _, ns = ...

local function DefineSkin()
    ns.RegisterModule("CheapUpgrades", "Cheap Upgrades", function()
        local cu = _G.CheapUpgrades
        return type(cu) == "table" and type(cu.CreateUI) == "function"
            and type(cu.AttachAHButton) == "function"
    end, function(S, module)
        local CU = _G.CheapUpgrades
        local H = ns.CreateSkinHelper(S, module)
        local soft = ns.CreateSoftSkin(S, module)
        local roots, painted, menus = {}, {}, {}
        local generation, pending = 1, false
        local PaintRoot, Discover
        local recovery = CreateFrame("Frame")
        recovery:RegisterEvent("PLAYER_REGEN_ENABLED")

        local function Ready()
            if not ns.IsEnabled(module) then return false end
            if InCombatLockdown and InCombatLockdown() then pending = true; return false end
            return true
        end
        local function Font(fs)
            if not H.Allowed(fs) or not fs.GetFont or not fs.SetFont then return end
            local face, height, flags = fs:GetFont()
            if issecretvalue and (issecretvalue(face) or issecretvalue(height) or issecretvalue(flags)) then return end
            if type(face) ~= "string" or type(height) ~= "number" or not (height > 0 and height < math.huge) then return end
            local target, targetFlags = S.GetFont()
            if face ~= target or (flags or "") ~= (targetFlags or "") then
                local r, g, b, a = fs:GetTextColor()
                S.Font(fs, r, g, b)
                fs:SetTextColor(r, g, b, a)
            end
        end
        local function OpenMenu(dropdown)
            local manager = Menu and Menu.GetManager and Menu.GetManager()
            local menu = manager and manager.GetOpenMenu and manager:GetOpenMenu()
            if Ready() and menu and menu.GetOwnerRegion and menu:GetOwnerRegion() == dropdown and ns.BindPopupList then
                ns.BindPopupList(S, module, dropdown, menu)
            end
        end
        local function Walk(f, force, depth)
            depth = depth or 0
            if depth > 16 or not H.Allowed(f) then return end
            local kind = f:GetObjectType()
            if kind == "GameTooltip" or kind == "PlayerModel" or kind == "ModelScene" then return end
            local first = painted[f] ~= generation
            if not first and not force then return end
            if first then
                painted[f] = generation
                -- Native item cells own rarity, selection, upgrade badges and data.
                local parent = f.GetParent and f:GetParent()
                local normal = f.GetNormalTexture and H.Texture(f:GetNormalTexture())
                local closeArt = normal and normal.GetTexture and normal:GetTexture()
                if parent and parent.CloseButton == f and S.CloseButton then
                    S.CloseButton(f)
                elseif type(closeArt) == "string" and closeArt:find("UI%-Panel%-MinimizeButton") and S.CloseButton then
                    S.CloseButton(f)
                elseif (f.group or f.isAlt) and H.Texture(f.icon) then
                    if S.SquareIcon then S.SquareIcon(f.icon) end
                elseif kind == "DropdownButton" then
                    soft.Dropdown(f)
                    if not menus[f] then
                        menus[f] = true
                        H.Script(f, "OnClick", OpenMenu)
                        H.Script(f, "OnMouseDown", OpenMenu)
                    end
                elseif kind == "EditBox" then
                    soft.EditBox(f, {padInput = false})
                    Font(f)
                elseif kind == "CheckButton" then
                    soft.Checkbox(f, {borderInset = 4, hover = 0.08})
                elseif kind == "Slider" then
                    H.LegacySlider(f)
                elseif kind == "Button" and f ~= _G.CheapUpgradesMinimapButton then
                    if f.pageKey then H.Tab(f)
                    else soft.Button(f, {"Icon", "icon", "badge", "price", "sel", "border"}) end
                end
                if H.Allowed(f.CloseButton) and S.CloseButton then S.CloseButton(f.CloseButton) end
                if H.Allowed(f.ScrollBar) and S.ScrollBar then S.ScrollBar(f.ScrollBar) end
                for _, region in ipairs(H.Regions(f)) do
                    if region:GetObjectType() == "FontString" then Font(region) end
                end
            end
            for _, child in ipairs(H.Children(f)) do Walk(child, force, depth + 1) end
        end
        local function BindRoot(f, mode)
            if not H.Allowed(f) then return end
            local state = roots[f]
            if not state then
                state = {mode = mode}; roots[f] = state
                H.Script(f, "OnShow", function() PaintRoot(f) end)
            end
            PaintRoot(f)
        end
        PaintRoot = function(f, force)
            if not Ready() or not H.Allowed(f) then return end
            local state = roots[f]
            if not state then return end
            if state.generation and f.IsVisible and not f:IsVisible() then return end
            if state.generation == generation and not force then return end
            if not state.skinned then
                if state.mode == "window" then
                    soft.Shell(f, {noAccent = true})
                    if f.SetBackdrop then f:SetBackdrop(nil) end
                    if f.NineSlice and S.FadeNineSlice then S.FadeNineSlice(f.NineSlice) end
                else
                    -- Already hosted by EUI's auction house or Settings canvas.
                    soft.Panel(f, {noBg = true})
                    if f.SetBackdrop then f:SetBackdrop(nil) end
                end
                state.skinned = true
            end
            Walk(f, force)
            state.generation = generation
        end
        local function PageFrame(page)
            if H.Allowed(page) then return page end
            return type(page) == "table" and H.Allowed(page.frame) and page.frame or nil
        end
        local function Tabs()
            local state = CU.ahTabs
            if type(state) == "table" then
                local lib = type(state.lib) == "table" and state.lib
                if not lib and LibStub then lib = LibStub("LibAHTab-1-0", true) end
                for _, key in ipairs({"upgrades", "alts"}) do
                    local tab = lib and lib.GetButton and lib:GetButton("CheapUpgrades_" .. key)
                        or _G["CheapUpgradesAHTab_" .. key]
                    if H.Allowed(tab) then H.Tab(tab) end
                end
            end
            local options = CU.Options
            if type(options) == "table" then
                for _, tab in ipairs(options.tabs or {}) do
                    local page = options.pages and PageFrame(options.pages[tab.pageKey])
                    if H.Allowed(tab) then H.Tab(tab, page and page:IsShown() or false) end
                end
            end
        end
        Discover = function()
            if not Ready() then return end
            BindRoot(_G.CheapUpgradesFrame, "window")
            BindRoot(_G.CheapUpgradesAHFrame, "panel")
            BindRoot(_G.CheapUpgradesOptionsWindow, "window")
            BindRoot(_G.CheapUpgradesSpecAsk, "window")
            local options = CU.Options
            if type(options) == "table" then
                for _, page in pairs(options.pages or {}) do BindRoot(PageFrame(page), "panel") end
                BindRoot(options.window, "window")
                BindRoot(options.specAsk, "window")
            end
            Tabs()
        end
        -- All item/alternative cells are constructed in CreateUI (0.18.9).
        -- Never hook RefreshUI, UpdateCell, scanning or scoring hot paths.
        for _, method in ipairs({"CreateUI", "AttachAHButton", "ShowUI"}) do H.Hook(CU, method, Discover) end
        local options = CU.Options
        if type(options) == "table" then
            for _, method in ipairs({"CreatePanel", "Open", "AskSpec"}) do H.Hook(options, method, Discover) end
            H.Hook(options, "ShowPage", Tabs)
            H.Hook(options, "BuildPage", function(_, page)
                if not Ready() then return end
                local frame = PageFrame(page)
                if frame then BindRoot(frame, "panel"); PaintRoot(frame, true) end
            end)
        end
        module.refresh = function()
            if not Ready() then return end
            generation = generation + 1
            Discover()
        end
        if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
        recovery:SetScript("OnEvent", function()
            if pending then pending = false; module.refresh() end
        end)
        Discover()
    end)
end
ns.RegisterSkinDefinition("CheapUpgrades", DefineSkin)
