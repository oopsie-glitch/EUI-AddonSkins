local _, ns = ...

local function DefineSkin()
    ns.RegisterModule("LFGForever", "LFG Forever", function()
        return type(_G.LFGForever_ToggleWindow) == "function"
    end, function(S, module)
        local soft = ns.CreateSoftSkin(S, module)
        local H = ns.CreateSkinHelper(S, module)
        local painted, lists, checks, navigation = {}, {}, {}, {}
        local generation, pending, applying, softGeneration = 1, false, false, 0
        local root, content, filter
        local Apply, Discover
        local events = CreateFrame("Frame")
        events:RegisterEvent("ADDON_LOADED")
        events:RegisterEvent("PLAYER_REGEN_ENABLED")
        -- The addon can open its private lazy window after posting a listing.
        -- Stop listening once that window has been discovered.
        events:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")

        local function Ready()
            if not ns.IsEnabled(module) then return false end
            if InCombatLockdown and InCombatLockdown() then pending = true; return false end
            return true
        end
        local function Owned(f)
            if not root then return false end
            for _ = 1, 20 do
                if f == root then return true end
                if not f or not f.GetParent then return false end
                f = f:GetParent()
            end
            return false
        end
        local function Font(text, accent)
            if not H.Allowed(text) or not text.GetFont or not text.SetFont then return end
            local face, size, flags = text:GetFont()
            if issecretvalue and (issecretvalue(face) or issecretvalue(size) or issecretvalue(flags)) then return end
            if type(size) ~= "number" or not (size > 0 and size < math.huge) or not face then return end
            local target, targetFlags = S.GetFont()
            if face ~= target or (flags or "") ~= (targetFlags or "") then
                local r, g, b, a = text:GetTextColor()
                S.Font(text, r, g, b); text:SetTextColor(r, g, b, a)
            end
            if accent then
                local r, g, b = S.GetAccentColor()
                local cr, cg, cb = text:GetTextColor()
                if not (issecretvalue and (issecretvalue(cr) or issecretvalue(cg) or issecretvalue(cb)))
                    and (r ~= cr or g ~= cg or b ~= cb) then text:SetTextColor(r, g, b) end
            end
        end
        local function Fade(texture)
            if H.Texture(texture) and texture:GetAlpha() ~= 0 then texture:SetAlpha(0) end
        end
        local function Button(f)
            local icon = H.Texture(f.Icon or f.icon)
            local alpha = icon and icon:GetAlpha()
            soft.Button(f, {"Icon", "icon", "IconMask", "Check", "SelectedTexture", "HighlightTexture"})
            if icon then icon:SetAlpha(alpha) end
            if S.StateButtonLabel then S.StateButtonLabel(f) end
        end
        local function Check(f)
            local art = checks[f]
            local icon, alpha = H.Texture(f.Icon)
            if icon then alpha = icon:GetAlpha() end
            if not art then
                local before = {}
                for _, r in ipairs(H.Regions(f)) do before[r] = true end
                for _, child in ipairs(H.Children(f)) do before[child] = true end
                soft.Checkbox(f, {borderInset = 4, hover = 0.08})
                art = {}; checks[f] = art
                for _, r in ipairs(H.Regions(f)) do if not before[r] and H.Texture(r) then art[#art + 1] = r end end
                for _, child in ipairs(H.Children(f)) do
                    if not before[child] and H.Allowed(child) and child:GetObjectType() == "Frame" then art[#art + 1] = child end
                end
            end
            -- Only the newly added cosmetic box changes size, never the button.
            local size = math.min(14, f:GetWidth(), f:GetHeight())
            for _, r in ipairs(art) do r:ClearAllPoints(); r:SetPoint("CENTER", f, "CENTER"); r:SetSize(size, size) end
            for _, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
                local mark = f[getter] and H.Texture(f[getter](f))
                if mark then
                    if getter == "GetCheckedTexture" then
                        mark:SetVertexColor(1, 1, 1, 1); mark:SetColorTexture(S.GetAccentColor())
                    end
                    mark:ClearAllPoints(); mark:SetPoint("CENTER", f, "CENTER"); mark:SetSize(size - 4, size - 4)
                end
            end
            if icon then icon:SetAlpha(alpha) end
        end

        local Walk
        local function Row(f)
            if Ready() and Owned(f) then Walk(f, true) end
        end
        local function List(box)
            if not H.Allowed(box) or not box.GetView then return end
            local view = box:GetView()
            if view and view.RegisterCallback and not lists[view] then
                lists[view] = box
                -- Native initializers have completed before this supported event.
                view:RegisterCallback("OnInitializedFrame", function(_, row) Row(row) end, module)
            end
            if box.ForEachFrame then box:ForEachFrame(Row) end
        end
        Walk = function(f, dynamic, depth)
            depth = depth or 0
            if depth > 18 or not H.Allowed(f) or not Owned(f) then return end
            local kind = f:GetObjectType()
            if kind == "GameTooltip" or kind == "ModelScene" or kind == "PlayerModel" then return end
            -- Stars own their earned/unearned art, hover preview and rating input.
            if f.Unearned and f.Earned or f == root.ResizeButton or f == root.DragBar then return end
            local first = painted[f] ~= generation
            if not first and not dynamic then return end
            local virtual = f.GetView and f.ForEachFrame
            local children = virtual and {} or H.Children(f) -- Never walk a retired row pool.
            if first then
                painted[f] = generation
                if f.NineSlice and S.FadeNineSlice then S.FadeNineSlice(f.NineSlice) end
                if f == content then
                    soft.Shell(f, {noAccent = true})
                    if f.PortraitContainer and f.PortraitContainer.SetAlpha then f.PortraitContainer:SetAlpha(0) end
                    Fade(f.portrait); Fade(f.TitleBg)
                elseif f == content.ListPanel or f == filter then
                    soft.Panel(f)
                    if f.SetBackdrop then f:SetBackdrop(nil) end
                elseif f == root.CloseButton then
                    S.CloseButton(f)
                elseif filter and f:GetParent() == filter.TabSystem then
                    if S.Tab then S.Tab(f) end
                    Fade(f.LFGFGlow)
                elseif kind == "DropdownButton" then
                    soft.Dropdown(f) -- Retains the native whole-field click handler.
                    Fade(f.Arrow) -- My Filters' additional stock caret.
                elseif kind == "CheckButton" then
                    Check(f)
                elseif kind == "EditBox" then
                    soft.EditBox(f, {padInput = false}); Font(f)
                elseif kind == "Slider" then
                    H.LegacySlider(f)
                elseif kind == "Button" then
                    local label = f.GetFontString and f:GetFontString()
                    -- Rows, links, stars and class/status art are not ordinary buttons.
                    if label then Button(f)
                    elseif f == root.CompactToggle then -- Keep its native direction/state artwork.
                    elseif f == content.ReportBug or filter and f == filter.SettingsGear then Button(f)
                    elseif f:GetParent() == root and f.Icon then Button(f) end
                end
                if f.ScrollBar and S.ScrollBar then S.ScrollBar(f.ScrollBar) end
                if f.Header and f.Content and f.Title then Font(f.Title, true) end
                for _, r in ipairs(H.Regions(f)) do
                    if r:GetObjectType() == "FontString" then Font(r) end
                end
                -- Theme callbacks repaint only known native objects, not API art.
                for _, child in ipairs(children) do Walk(child, dynamic, depth + 1) end
            elseif dynamic then
                for _, r in ipairs(H.Regions(f)) do
                    if r:GetObjectType() == "FontString" then Font(r) end
                end
                for _, child in ipairs(children) do Walk(child, true, depth + 1) end
            end
            if virtual then List(f) end
        end

        local function MenuOpened(manager)
            if not root or not root:IsShown() or not manager.GetOpenMenu then return end
            local menu = manager:GetOpenMenu()
            local owner = menu and menu.GetOwnerRegion and menu:GetOwnerRegion()
            if not Owned(owner) or not Ready() then return end
            -- Reuse the collection's reversible compositor/owner handling.
            -- Shared menus, FontObjects and descriptions remain library-owned.
            if ns.BindPopupList then ns.BindPopupList(S, module, owner, menu) end
        end
        local function BindLaunchers()
            H.Hook(_G, "LFGForever_ToggleWindow", Discover)
            H.Hook(_G, "LFGForever_OnAddonCompartmentClick", Discover)
            if SlashCmdList then H.Hook(SlashCmdList, "LFGFOREVER", Discover) end
            for _, name in ipairs({"LFGForeverMinimapButton", "LFGForeverSearchKeyButton"}) do
                H.Script(_G[name], "OnClick", Discover)
            end
            H.Script(_G.LFGForeverBlizzardTab, "OnMouseUp", Discover)
            local manager = Menu and Menu.GetManager and Menu.GetManager()
            if manager then
                H.Hook(manager, "OpenMenu", MenuOpened)
                H.Hook(manager, "OpenContextMenu", MenuOpened)
            end
        end
        local function Paint()
                content = root.Content
                if not H.Allowed(content) then return end
                filter = content.FilterPanel
                Walk(root)
                Font(content.TitleContainer and content.TitleContainer.TitleText or content.TitleText, true)
                if filter and not navigation[filter] then
                    navigation[filter] = true
                    H.Hook(filter, "SetTab", function()
                        if not Ready() then return end
                        for _, key in ipairs({"WhisperLog", "PlayerRatings"}) do
                            local panel = filter[key]
                            if panel and panel:IsShown() then Walk(panel, true) end
                        end
                    end)
                    for _, key in ipairs({"WhisperLog", "PlayerRatings"}) do
                        local panel = filter[key]
                        if panel then
                            H.Script(panel, "OnShow", function() if Ready() then Walk(panel, true) end end)
                        end
                    end
                end
                if softGeneration ~= generation then
                    soft.RefreshSoftBorders(); softGeneration = generation
                end
        end
        Apply = function()
            if applying or not Ready() or not H.Allowed(root) then return end
            applying = true; H.Safe(Paint); applying = false
        end
        Discover = function()
            if not Ready() then return end
            local current = _G.LFGForeverFrame
            if H.Allowed(current) and current.Content then
                if root ~= current then root = current end
                events:UnregisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
                H.Script(root, "OnShow", Apply)
                Apply()
            end
        end
        module.refresh = function()
            if not Ready() then return end
            generation = generation + 1
            BindLaunchers()
            Discover()
            local manager = Menu and Menu.GetManager and Menu.GetManager()
            if manager then MenuOpened(manager) end
        end
        if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
        events:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_REGEN_ENABLED" then
                if pending then pending = false; module.refresh() end
            elseif Ready() then BindLaunchers(); Discover() end
        end)
        BindLaunchers()
        Discover()
    end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("LFGForever", DefineSkin)
else DefineSkin() end
