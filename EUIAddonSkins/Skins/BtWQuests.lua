local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("BtWQuests", "BtWQuests", function()
    return _G.BtWQuests ~= nil and _G.BtWQuestsFrame ~= nil
end, function(S, module)
    local H = ns.CreateSkinHelper(S, module)
    local soft = ns.CreateSoftSkin(S, module)
    local root = _G.BtWQuestsFrame
    local styled, menus, panels, scrolls = {}, {}, {}, {}
    local painting, waiting = false, false
    local Paint, Walk, Menu, BindMenu
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")

    local function Run(fn, ...)
        if painting or not ns.IsEnabled(module) then return end
        if InCombatLockdown() then waiting = true; return end
        painting = true
        H.Safe(fn, ...)
        painting = false
    end
    local function Fonts(f, white)
        for _, region in ipairs(H.Regions(f)) do
            if white then H.Font(region, 0.92, 0.92, 0.94) else H.Font(region) end
        end
    end
    local function Strip(f)
        if not H.Allowed(f) then return end
        if S.Inset then S.Inset(f) end
        if f.SetBackdrop then f:SetBackdrop(nil) end
        if f.NineSlice then S.FadeNineSlice(f.NineSlice) end
    end
    local function Scroll(f)
        if not H.Allowed(f) then return end
        if not scrolls[f] then
            if f.GetThumbTexture then
                local thumb = f:GetThumbTexture()
                if not thumb then return end -- Retry after a lazy template initializes.
                for _, region in ipairs(H.Regions(f)) do
                    if region ~= thumb and H.Texture(region) then H.Fade(region) end
                end
                if thumb then
                    thumb:SetColorTexture(1, 1, 1, 0.3)
                    thumb:SetWidth(4) -- Keep native height, drag range and hit area.
                end
                for _, key in ipairs({"ScrollUpButton", "ScrollDownButton"}) do
                    local button = f[key]
                    if H.Allowed(button) then for _, region in ipairs(H.Regions(button)) do if H.Texture(region) then H.Fade(region) end end end
                end
            else S.ScrollBar(f) end
            scrolls[f] = true
        end
    end
    local function Button(f, keep)
        if not H.Allowed(f) then return end
        S.Button(f, keep)
        Fonts(f)
        if S.StateButtonLabel then S.StateButtonLabel(f) end
    end
    local NODE_KEEP = {"Tick", "TagTexture", "HeroicTexture", "MythicTexture", "ActiveTexture", "IsNext"}
    local CARD_KEEP = {"Tick", "Major", "Acive"} -- Acive is the target addon's field spelling.
    local function Row(f)
        if not H.Allowed(f) then return end
        if f.Cover and f.Name then
            soft.Button(f, NODE_KEEP)
            H.Fade(f.Icon); H.Fade(f.Cover)
            Fonts(f) -- Preserve status colours, spoiler visibility and fade animations.
        elseif f.Name and f.Tick then
            soft.Button(f, CARD_KEEP)
            H.Fade(f.Background)
            H.Font(f.Name, 0.92, 0.92, 0.94)
            H.Font(f.Subtext, 0.7, 0.7, 0.72)
        elseif f.Name then
            local r, g, b = S.GetAccentColor()
            H.Font(f.Name, r, g, b)
            for _, child in ipairs(H.Children(f)) do H.Fade(child.Background) end
        end
        if not styled[f] then
            styled[f] = true
            for _, method in ipairs({"Set", "Update"}) do
                H.Hook(f, method, function() Run(Row, f) end)
            end
        end
    end
    local function Graph()
        local chain = root.Chain and root.Chain.Scroll
        local child = chain and chain.Child
        if not H.Allowed(child) then return end
        Scroll(chain.ScrollBar)
        -- Lines live on sibling frames, sometimes with frame-pool children.
        -- Never recurse into them or change graph geometry, zoom or connectors.
        for _, node in ipairs(H.Children(child)) do
            if H.Allowed(node) and node:GetObjectType() == "Button" and node.Cover then Row(node) end
        end
    end
    Menu = function(list)
        if not H.Allowed(list) then return end
        if not panels[list] then
            panels[list] = true
            S.Panel(list, {noBorder = true})
            Strip(list.Backdrop); Strip(list.MenuBackdrop)
        end
        for _, row in ipairs(H.Children(list)) do
            if H.Allowed(row) and row:GetObjectType() == "Button" then
                -- Keep check/radio visibility, class-coloured names, delete and
                -- swatch controls. Native hover scripts still own Highlight.
                H.Font(row.NormalText)
                if H.Texture(row.Highlight) then row.Highlight:SetColorTexture(1, 1, 1, 0.08) end
                if H.Texture(row.Check) then
                    local r, g, b = S.GetAccentColor()
                    row.Check:SetVertexColor(r, g, b)
                end
                if H.Texture(row.UnCheck) then row.UnCheck:SetVertexColor(0.4, 0.4, 0.4) end
            end
        end
    end
    BindMenu = function(f)
        if not H.Allowed(f) or type(f.GetListFrame) ~= "function" then return end
        if not menus[f] then
            menus[f] = true
            -- GetListFrame is lazy. Observe it; never call it or force creation.
            H.Hook(f, "GetListFrame", function() Run(Menu, f.list) end)
            H.Hook(f, "Open", function() Run(Menu, f.list) end)
        end
        if f.list then Menu(f.list) end
        if f.displayMode ~= "MENU" then
            local icon = H.Texture(f.Icon)
            local alpha = icon and icon:GetAlpha()
            S.Dropdown(f)
            if icon then icon:SetAlpha(alpha) end
            H.Font(f.Text)
            -- The custom arrow button is separate from the dropdown's regions.
            if H.Allowed(f.Button) then
                for _, region in ipairs(H.Regions(f.Button)) do if H.Texture(region) then H.Fade(region) end end
            end
        end
    end
    Walk = function(f, depth)
        if depth > 12 or not H.Allowed(f) then return end
        local kind = f:GetObjectType()
        if kind == "GameTooltip" or kind == "PlayerModel" or kind == "ModelScene" then return end
        local canvas = root.Chain and root.Chain.Scroll and root.Chain.Scroll.Child
        if f == canvas then Graph(); return end
        if f.Cover and f.Name or f.Name and f.Tick then Row(f)
        elseif kind == "Button" and f.Name and not f.Icon then
            -- Category headers and search results have Name, not ButtonText.
            if f.link or f.resultType then soft.Button(f); Fonts(f, true)
            else Row(f) end
        elseif type(f.GetListFrame) == "function" then BindMenu(f)
        elseif kind == "EditBox" then S.EditBox(f); if S.Font then S.Font(f) end
        elseif kind == "CheckButton" then S.Checkbox(f)
        elseif kind == "StatusBar" and S.ApplyBarFill then S.ApplyBarFill(f)
        elseif kind == "Slider" then Scroll(f)
        elseif kind == "Button" and f.MenuArrowButton then
            Button(f, {"selected"})
            if H.Texture(f.selected) then
                local r, g, b = S.GetAccentColor()
                f.selected:SetColorTexture(r, g, b, 0.12)
            end
            if H.Allowed(f.MenuArrowButton) then S.PageButton(f.MenuArrowButton, "v") end
        elseif kind == "Button" and f.Active and f.Subtext then
            Button(f, {"Active"})
            if H.Texture(f.Active) then
                if not styled[f] then f.Active:SetAllPoints(f); styled[f] = true end
                local r, g, b = S.GetAccentColor()
                f.Active:SetColorTexture(r, g, b, 0.12)
            end
        elseif kind == "Button" and f.GetFontString and f:GetFontString() then Button(f) end
        Fonts(f)
        if f.ScrollBar then Scroll(f.ScrollBar) end
        if f.scrollBar then Scroll(f.scrollBar) end
        if f.CloseButton and H.Allowed(f.CloseButton) then S.CloseButton(f.CloseButton) end
        if f.Background and f.Base and f.AutoLoad then
            -- Expansion artwork identifies the expansion; remove its frame,
            -- leaving the image and auto-load behaviour in their native layout.
            H.Fade(f.Base)
            H.Font(f.Name, 0.92, 0.92, 0.94)
        end
        for _, child in ipairs(H.Children(f)) do Walk(child, depth + 1) end
    end
    local function Surface(f)
        if not H.Allowed(f) then return end
        if not panels[f] then
            panels[f] = true
            -- Separate search overlays need a fill; content inside the main
            -- journal inherits its existing textured/Modern shell instead.
            S.Panel(f, {noBorder = true})
        end
        Walk(f, 0)
    end
    local function Setup()
        if styled[root] then return end
        styled[root] = true
        S.Shell(root, {noBorder = true})
        if root.NineSlice then S.FadeNineSlice(root.NineSlice) end
        Strip(root.Inset)
        local portrait = root.PortraitContainer
        if H.Allowed(portrait) then
            for _, region in ipairs(H.Regions(portrait)) do if H.Texture(region) then H.Fade(region) end end
        end
        H.Fade(root.portrait)
        if root.CloseButton then S.CloseButton(root.CloseButton) end
        local previous
        for _, entry in ipairs({{"NavBack", "<"}, {"NavForward", ">"}, {"NavHere", "^"}}) do
            local button = root[entry[1]]
            if H.Allowed(button) then
                S.PageButton(button, entry[2])
                button:SetSize(22, 22); button:ClearAllPoints()
                if previous then button:SetPoint("LEFT", previous, "RIGHT", 3, 0)
                else button:SetPoint("TOPLEFT", root, "TOPLEFT", 8, -2) end
                previous = button
            end
        end
        if H.Allowed(root.OptionsButton) then
            local button = root.OptionsButton
            local icon = button.GetNormalTexture and H.Texture(button:GetNormalTexture())
            if icon then button.euiOptionsIcon = icon; Button(button, {"euiOptionsIcon"}); icon:SetAlpha(1); S.SquareIcon(icon) end
            button:SetSize(22, 22); button:ClearAllPoints()
            button:SetPoint("TOPRIGHT", root, "TOPRIGHT", -30, -2)
        end
        if H.Allowed(root.CharacterDropDown) and H.Allowed(root.OptionsButton) then
            root.CharacterDropDown:SetHeight(22)
            root.CharacterDropDown:ClearAllPoints()
            root.CharacterDropDown:SetPoint("RIGHT", root.OptionsButton, "LEFT", -6, 0)
        end
        if H.Allowed(root.navBar) then
            Strip(root.navBar)
            H.Hook(root.navBar, "AddButtons", function() Run(Walk, root.navBar, 0) end)
        end
        if root.ExpansionList then
            for _, entry in ipairs({{"Left", "<"}, {"Right", ">"}}) do
                local button = root.ExpansionList[entry[1]]
                if H.Allowed(button) then button:SetSize(22, 22); S.PageButton(button, entry[2]) end
            end
        end
        for _, method in ipairs({"DisplayExpansionList", "DisplayItemList", "DisplayCurrentChain"}) do
            H.Hook(root, method, function() Run(Paint) end)
        end
        H.Hook(root, "UpdateCurrentChain", function() Run(Graph) end)
        local chain = root.Chain and root.Chain.Scroll
        if chain then
            H.Hook(chain, "SetChain", function() Run(Graph) end)
            H.Hook(chain, "Update", function() Run(Graph) end)
        end
        for _, key in ipairs({"SearchPreview", "SearchResults"}) do
            local f = root[key]
            if H.Allowed(f) then
                for _, method in ipairs({"UpdateResults", "UpdateSearch"}) do
                    H.Hook(f, method, function() Run(Surface, f) end)
                end
            end
        end
        H.Script(root, "OnShow", function() Run(Paint) end)
    end
    Paint = function()
        waiting = false
        Setup()
        Walk(root, 0)
        for _, key in ipairs({"SearchPreview", "SearchResults"}) do Surface(root[key]) end
        BindMenu(_G.BtWQuestsOptionsMenu)
        soft.RefreshSoftBorders()
    end
    module.refresh = function() H.Queue(module, function() Run(Paint) end) end
    events:SetScript("OnEvent", function() if waiting then Run(Paint) end end)
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    Run(Paint)
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("BtWQuests", DefineSkin)
else DefineSkin() end
