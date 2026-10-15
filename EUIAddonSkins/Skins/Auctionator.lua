local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("Auctionator", "Auctionator", function()
    return _G.Auctionator and _G.Auctionator.Tabs and _G.Auctionator.Tabs.State
end, function(S, module)
    S = ns.CreateSoftSkin(S, module)
    local A = _G.Auctionator
    local H = ns.CreateSkinHelper(S, module)
    local roots, shells, panels = {}, {}, {}
    local scrollChrome, itemBorders, radioMarks, layouts = {}, {}, {}, {}
    local refresh, waiting
    local discoveryDirty = true
    local events = CreateFrame("Frame")
    events:RegisterEvent("AUCTION_HOUSE_SHOW")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")

    local function Remember(f, shell)
        if not f or not f.GetObjectType then return end
        roots[f] = shell or roots[f] or "controls"
        refresh()
    end
    local function Panel(f)
        if H.Allowed(f) and not panels[f] then
            local artwork = {}
            for _, region in ipairs(H.Regions(f)) do
                if region.GetTexture and region.GetDrawLayer then
                    local layer = region:GetDrawLayer()
                    if layer == "ARTWORK" or layer == "OVERLAY" then artwork[region] = region:GetAlpha() end
                end
            end
            S.Panel(f)
            panels[f] = artwork
            if f.SetBackdrop then f:SetBackdrop(nil) end
        end
        if type(panels[f]) == "table" then
            for region, alpha in pairs(panels[f]) do region:SetAlpha(alpha) end
        end
    end
    local function Scroll(bar)
        if not H.Allowed(bar) then return end
        if bar.GetThumbTexture then H.LegacySlider(bar); return end
        -- WowTrimScrollBar's end caps live directly on the bar, outside Track.
        if not scrollChrome[bar] then
            scrollChrome[bar] = true
            for _, region in ipairs(H.Regions(bar)) do if region.GetTexture then H.Fade(region) end end
        end
        S.ScrollBar(bar)
    end
    local function Radio(button)
        if not H.Allowed(button) then return end
        S.Checkbox(button)
        if not button.CreateTexture or not button.GetChecked then return end
        if not radioMarks[button] then
            local mark = button:CreateTexture(nil, "OVERLAY", nil, 7)
            mark:SetSize(6, 6); mark:SetPoint("CENTER"); radioMarks[button] = mark
            if button.GetCheckedTexture then H.Fade(button:GetCheckedTexture()) end
            if button.GetDisabledCheckedTexture then H.Fade(button:GetDisabledCheckedTexture()) end
            H.Hook(button, "SetChecked", function() Radio(button) end)
            H.Script(button, "OnClick", function() Radio(button) end)
        end
        local r, g, b = S.GetAccentColor()
        radioMarks[button]:SetColorTexture(r, g, b, 1)
        radioMarks[button]:SetShown(button:GetChecked() and true or false)
    end
    local function Item(f, icon)
        local border = H.Texture(f.IconBorder)
        if border and not itemBorders[f] and f.CreateTexture then
            local lines = {}
            for _, side in ipairs({"Top", "Bottom", "Left", "Right"}) do
                local line = f:CreateTexture(nil, "OVERLAY", nil, 6)
                f["euiQuality" .. side] = line; lines[#lines + 1] = line
                if side == "Top" or side == "Bottom" then
                    local edge = side:upper(); line:SetPoint(edge .. "LEFT"); line:SetPoint(edge .. "RIGHT"); line:SetHeight(1)
                else
                    local edge = side:upper(); line:SetPoint("TOP" .. edge); line:SetPoint("BOTTOM" .. edge); line:SetWidth(1)
                end
            end
            itemBorders[f] = lines
            H.Hook(border, "SetVertexColor", function() Item(f, icon) end)
        end
        -- Register keep regions after creation so EUI's theme restrip retains them.
        H.Action(f, {"Icon", "icon", "IconSelectedHighlight", "Highlight",
            "euiQualityTop", "euiQualityBottom", "euiQualityLeft", "euiQualityRight"})
        icon:SetAlpha(1); S.SquareIcon(icon, f)
        if H.Texture(f.EmptySlot) then H.Fade(f.EmptySlot) end
        H.Fade(border)
        if itemBorders[f] and border.GetVertexColor then
            local r, g, b, a = border:GetVertexColor()
            for _, line in ipairs(itemBorders[f]) do line:SetColorTexture(r, g, b, a or 1); line:SetAlpha(1) end
        end
    end
    local function SearchLayout(f)
        local options = f.SearchOptions
        if layouts[f] or not _G.AuctionFrame or not options or not options.SearchLabel
            or not options.SearchString or not options.SearchButton or not options.SearchLabel.ClearAllPoints then return end
        layouts[f] = true
        options.SearchLabel:ClearAllPoints(); options.SearchLabel:SetPoint("TOPLEFT", options, "TOPLEFT", 12, -10)
        options.SearchString:ClearAllPoints(); options.SearchString:SetPoint("LEFT", options.SearchLabel, "RIGHT", 12, 0)
        local previous = options.SearchString
        for _, key in ipairs({"ResetSearchStringButton", "SearchButton", "MoreButton", "AddToListButton", "FullScanButton"}) do
            local button = options[key]
            if H.Allowed(button) and button.ClearAllPoints then
                button:ClearAllPoints(); button:SetPoint("LEFT", previous, "RIGHT", 6, 0); previous = button
            end
        end
        for _, key in ipairs({"ListsContainer", "RecentsContainer"}) do
            local list = f[key]
            if H.Allowed(list) and list.ClearAllPoints then
                list:ClearAllPoints(); list:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -84)
                list:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, key == "ListsContainer" and 35 or 10)
            end
        end
        if H.Allowed(f.ContainerTabs) and f.ListsContainer then
            f.ContainerTabs:ClearAllPoints(); f.ContainerTabs:SetPoint("BOTTOMLEFT", f.ListsContainer, "TOPLEFT", 0, 4)
        end
    end
    local function Visit(f, kind)
        if kind == "Slider" then Scroll(f); return true end
        if f.isAuctionatorRadio and H.Allowed(f.RadioButton) then Radio(f.RadioButton) end
        if kind == "CheckButton" and f.GetParent then
            local parent = f:GetParent()
            if parent and parent.isAuctionatorRadio then Radio(f); return true end
        end
        if kind == "Button" then
            local icon = H.Icon(f)
            if icon and (f.IconBorder or f.EmptySlot or f.IconSelectedHighlight) then Item(f, icon); return true end
        end
        if f.ListsTab and f.RecentsTab then
            for _, tab in ipairs({f.ListsTab, f.RecentsTab}) do
                local selected = f.selectedTab and tab.GetID and f.selectedTab == tab:GetID()
                H.Tab(tab, selected or false)
                if tab.ActiveMarker then H.Fade(tab.ActiveMarker) end
            end
            H.Hook(f, "SetView", refresh)
        end
        for _, key in ipairs({"HistoryButton", "CurrentPricesButton", "YourHistoryButton"}) do
            local button = f[key]
            if H.Allowed(button) then
                local view = key == "HistoryButton" and f.HistoryPrices or key == "CurrentPricesButton" and f.CurrentPrices or f.YourHistory
                H.Tab(button, view and view.IsShown and view:IsShown() or false)
                if view then H.Script(view, "OnShow", refresh); H.Script(view, "OnHide", refresh) end
            end
        end
        for _, key in ipairs({"RefreshButton", "ResetSearchStringButton"}) do
            local button = f[key]
            if H.Allowed(button) and button:GetObjectType() == "Button" then
                local icon = H.Texture(button.GetNormalTexture and button:GetNormalTexture())
                if icon then
                    button.euiRefreshIcon = icon
                    H.Action(button, {"euiRefreshIcon"}); icon:SetAlpha(1); S.SquareIcon(icon)
                    local r, g, b = S.GetAccentColor(); if icon.SetVertexColor then icon:SetVertexColor(r, g, b) end
                end
            end
        end
        SearchLayout(f)
        for _, key in ipairs({"ShoppingResultsInset", "BagInset", "HistoricalPriceInset", "ListsContainer", "RecentsContainer", "ScrollArea"}) do Panel(f[key]) end
        for _, key in ipairs({"Title", "SearchLabel", "Deposit", "Total", "NoResultsText", "ResultsText"}) do H.Font(f[key], 0.9, 0.9, 0.92) end
        if H.Allowed(f.NineSlice) then S.FadeNineSlice(f.NineSlice) end
        -- Auctionator's simple panels expose their decorative rock background.
        if f.Bg then H.Fade(f.Bg) end
        if H.Allowed(f.Border) then
            S.FadeNineSlice(f.Border)
            for _, region in ipairs({f.Border:GetRegions()}) do
                if region.GetTexture then H.Fade(region) end
            end
        end
        if f.Inset and H.Allowed(f.Inset) and not panels[f.Inset] then
            panels[f.Inset] = true
            S.Panel(f.Inset)
            if f.Inset.SetBackdrop then f.Inset:SetBackdrop(nil) end
        end
        if H.Allowed(f.CloseButton) then S.CloseButton(f.CloseButton) end
        -- WowTrimScrollBar is an EventFrame rather than a Slider.
        if H.Allowed(f.ScrollBar) then Scroll(f.ScrollBar) end
    end
    local function Apply()
        if InCombatLockdown() then waiting = true; return end
        waiting = false
        local active = false
        for _, details in ipairs(A.Tabs.State.knownTabs or {}) do
            local f = _G[details.tabFrameName]
            if f then roots[f] = "content" end
            local tab = _G["AuctionatorTabs_" .. details.name]
            if H.Allowed(tab) then
                local visible = f and f.IsShown and f:IsShown()
                    and (not tab.wrapperFrame or not tab.wrapperFrame.IsShown or tab.wrapperFrame:IsShown()) or false
                active = active or visible
                H.Tab(tab, visible)
                for _, method in ipairs({"Selected", "DeselectTab"}) do H.Hook(tab, method, refresh) end
                H.Script(tab, "OnClick", refresh)
                if tab.wrapperFrame then roots[tab.wrapperFrame] = "content" end
                if f then H.Script(f, "OnHide", refresh); H.Script(f, "OnShow", refresh) end
            end
        end
        -- Visual overrides only: Auctionator's wrapper does not always update
        -- the Blizzard host's selectedTab value when it opens an extension tab.
        if _G.AuctionFrame then
            for index = 1, 3 do
                local tab = _G["AuctionFrameTab" .. index]
                if H.Allowed(tab) and S.SetTabSelection then
                    if active then S.SetTabSelection(tab, false) else S.SetTabSelection(tab, nil) end
                end
            end
        end
        -- Only addon-owned globals, never a scan of the Blizzard auction house.
        if discoveryDirty then
            discoveryDirty = false
            for name, f in pairs(_G) do
                if type(name) == "string" and name:match("^AuctionatorConfig.*Frame$") and (type(f) == "table" or type(f) == "userdata") then
                    if f.GetObjectType then roots[f] = roots[f] or "controls" end
                end
            end
        end
        for _, name in ipairs({"AuctionatorShoppingTabItemFrame", "AuctionatorExportListFrame",
            "AuctionatorImportListFrame", "AuctionatorItemHistoryFrame"}) do
            if _G[name] then roots[_G[name]] = "dialog" end
        end
        for f, mode in pairs(roots) do
            if H.Allowed(f) then
                if mode ~= "controls" and not shells[f] then
                    shells[f] = true
                    H.Shell(f, refresh, {noTopBar = mode == "content", bottomBar = mode == "dialog" and 32 or nil})
                end
                H.Scan(f, refresh, Visit)
            end
        end
        -- Standard confirmation dialogs are private, but have numbered owned globals.
        local index = 1
        while _G["AuctionatorDialog" .. index] do
            local f = _G["AuctionatorDialog" .. index]
            if H.Allowed(f) then H.Shell(f, refresh); H.Scan(f, refresh, Visit) end
            index = index + 1
        end
        S.RefreshSoftBorders()
    end
    refresh = function() H.Queue(module, Apply) end
    -- Post-hooks see complete controls without replacing constructors or callbacks.
    for _, entry in ipairs({
        {"AuctionatorTabContainerMixin", "OnLoad", "controls"},
        {"AuctionatorConfigFrameMixin", "OnLoad", "controls"},
        {"AuctionatorShoppingTabFrameMixin", "OnLoad", "content"},
        {"AuctionatorListExportFrameMixin", "OnLoad", "dialog"},
        {"AuctionatorListImportFrameMixin", "OnLoad", "dialog"},
        {"AuctionatorExportTextFrameMixin", "OnLoad", "dialog"},
    }) do
        H.Hook(_G[entry[1]], entry[2], function(f) Remember(f, entry[3]) end)
    end
    if A.Dialogs then
        for _, method in ipairs({"ShowEditBox", "ShowConfirm", "ShowConfirmAlt", "ShowMoney"}) do
            H.Hook(A.Dialogs, method, refresh)
        end
    end
    local function Discover() discoveryDirty = true; refresh() end
    H.Hook(A.Config, "InternalInitializeFrames", Discover)
    -- OnLoad already ran for frames created before this skin was enabled.
    local shopping = _G.AuctionatorShoppingFrame
    if shopping then
        for _, key in ipairs({"exportCSVDialog", "exportDialog", "importDialog", "itemDialog", "itemHistoryDialog"}) do
            if shopping[key] then roots[shopping[key]] = "dialog" end
        end
        if shopping.exportDialog and shopping.exportDialog.copyTextDialog then roots[shopping.exportDialog.copyTextDialog] = "dialog" end
    end
    events:SetScript("OnEvent", function(_, event)
        if event == "ADDON_LOADED" then discoveryDirty = true end
        if ns.IsEnabled(module) and (event ~= "PLAYER_REGEN_ENABLED" or waiting) then refresh() end
    end)
    module.refresh = refresh
    if S.OnLooksChanged then S.OnLooksChanged(refresh) end
    refresh()
end)

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Auctionator", DefineSkin)
else DefineSkin() end
