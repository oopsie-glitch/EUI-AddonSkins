local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("ForeverDungeonJournal", "Forever Dungeon Journal", function()
    local journal = _G.ForeverDungeonJournal_NS
    return journal and type(journal.ToggleJournal) == "function"
end, function(S, module)
    S = ns.CreateSoftSkin(S, module)
    local journal = _G.ForeverDungeonJournal_NS
    local H = ns.CreateSkinHelper(S, module)
    local refresh
    local fullQueued, fullSerial = false, 0
    local fontGeneration, fontCache = 0, setmetatable({}, {__mode = "k"})
    local applyFont = S.Font
    S.Font = function(text, r, g, b)
        if not H.Allowed(text) or not text.GetFont then return applyFont(text, r, g, b) end
        local path, size, flags = text:GetFont()
        if issecretvalue and (issecretvalue(path) or issecretvalue(size) or issecretvalue(flags)) then return applyFont(text, r, g, b) end
        local old = fontCache[text]
        if not old or old.generation ~= fontGeneration or old.path ~= path or old.size ~= size or old.flags ~= flags then
            applyFont(text, r, g, b)
            path, size, flags = text:GetFont()
            if issecretvalue and (issecretvalue(path) or issecretvalue(size) or issecretvalue(flags)) then return end
            fontCache[text] = {path = path, size = size, flags = flags, generation = fontGeneration}
        elseif r then text:SetTextColor(r, g, b or r) end
    end
    local panels, watched, watchPass = {}, {}, {}
    local borderLocks = {}
    local canvases, checks, arrows, grips = {}, {}, {}, {}
    local visuals = setmetatable({}, {__mode = "k"})
    local scan = H.Scan
    H.Scan = function(root, callback, visit, excluded)
        local exclude = setmetatable({}, {__index = visuals})
        for f, value in pairs(excluded or {}) do exclude[f] = value end
        return scan(root, callback, visit, exclude)
    end
    local function Busy()
        return InCombatLockdown and InCombatLockdown()
    end
    local function Gradient(t, first, last)
        t:SetColorTexture(1, 1, 1, 1)
        if t.SetGradient and CreateColor then
            t:SetGradient("HORIZONTAL", CreateColor(0.19, 0.19, 0.20, first), CreateColor(0.19, 0.19, 0.20, last))
        elseif t.SetGradientAlpha then t:SetGradientAlpha("HORIZONTAL", 0.19, 0.19, 0.20, first, 0.19, 0.19, 0.20, last)
        else t:SetColorTexture(0.12, 0.12, 0.13, 0.3) end
    end
    local function Canvas(f)
        if not H.Allowed(f) or not f.CreateTexture or canvases[f] then return end
        local layer = CreateFrame("Frame", nil, f); visuals[layer] = true
        layer:SetAllPoints(f); layer:EnableMouse(false)
        if layer.SetFrameLevel and f.GetFrameLevel then layer:SetFrameLevel(f:GetFrameLevel()) end
        local base = layer:CreateTexture(nil, "BACKGROUND", nil, 1); base:SetAllPoints(layer)
        base:SetColorTexture(0.055, 0.055, 0.06, 0.96)
        local left = layer:CreateTexture(nil, "BACKGROUND", nil, 2)
        left:SetPoint("TOPLEFT", f, "TOPLEFT"); left:SetPoint("BOTTOMRIGHT", f, "BOTTOM")
        Gradient(left, 0, 0.48)
        local right = layer:CreateTexture(nil, "BACKGROUND", nil, 2)
        right:SetPoint("TOPLEFT", f, "TOP"); right:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")
        Gradient(right, 0.48, 0)
        canvases[f] = {base, left, right}
    end
    local function Arrow(button, direction)
        if not H.Allowed(button) or not button.CreateTexture then return end
        local icon = arrows[button]
        if not icon then
            icon = button:CreateTexture(nil, "OVERLAY")
            icon:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
            icon:SetSize(10, 7); icon:SetPoint("CENTER")
            if icon.SetRotation then icon:SetRotation(direction == "up" and math.pi or 0) end
            arrows[button] = icon
        end
        button.fdjSkinArrow = icon
        H.Action(button, {"fdjSkinArrow"})
        for _, text in ipairs(H.Regions(button)) do
            if text.GetObjectType and text:GetObjectType() == "FontString" then H.Fade(text) end
        end
        icon:SetAlpha(1); icon:SetVertexColor(0.8, 0.8, 0.82, 1)
    end
    local function Check(f)
        if not H.Allowed(f) then return end
        if not checks[f] then
            checks[f] = true
            S.Checkbox(f, {borderInset = 4, hover = 0.08})
            local function Paint() if Busy() then module.combatPending = true else Check(f) end end
            for _, name in ipairs({"SetCheckedTexture", "SetDisabledCheckedTexture", "Enable", "Disable"}) do H.Hook(f, name, Paint) end
            H.Script(f, "OnEnable", Paint); H.Script(f, "OnDisable", Paint)
        end
        for _, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = f[getter] and H.Texture(f[getter](f))
            if mark then
                mark:SetVertexColor(1, 1, 1, 1)
                if f.IsEnabled and not f:IsEnabled() then mark:SetColorTexture(0.45, 0.45, 0.45, 0.8)
                else mark:SetColorTexture(S.GetAccentColor()) end
                mark:ClearAllPoints(); mark:SetPoint("TOPLEFT", f, "TOPLEFT", 7, -7)
                mark:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -7, 7)
            end
        end
        H.Font(f.fdjLabel)
    end
    local function Language(button)
        if not H.Allowed(button) then return end
        if not button.euiCaret and button.CreateTexture then
            local caret = button:CreateTexture(nil, "OVERLAY")
            caret:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
            caret:SetSize(10, 7); caret:SetPoint("RIGHT", button, "RIGHT", -8, 0)
            button.euiCaret = caret
        end
        H.Action(button, {"euiCaret"})
        if button.euiCaret then button.euiCaret:SetAlpha(1); button.euiCaret:SetVertexColor(0.8, 0.8, 0.82, 1) end
    end
    local inputEdges, favouriteIcons = {}, {}
    local function FilterOwner(f)
        local root = _G.ForeverDungeonJournalFrame
        local filter = root and root.lootFilterWindow or _G.ForeverDungeonJournalLootFilter
        for _ = 1, 20 do
            if not H.Allowed(f) then return false end
            if f == filter then return true end
            f = f.GetParent and f:GetParent()
        end
        return false
    end
    local function InputEdge(f)
        if inputEdges[f] or not f.CreateTexture then return end
        local layer = CreateFrame("Frame", nil, f); visuals[layer] = true
        layer:SetAllPoints(f); layer:EnableMouse(false)
        for _, side in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
            local t = layer:CreateTexture(nil, "BORDER"); t:SetColorTexture(0.28, 0.28, 0.30, 0.45)
            if side == "TOP" or side == "BOTTOM" then
                t:SetPoint(side .. "LEFT", layer, side .. "LEFT"); t:SetPoint(side .. "RIGHT", layer, side .. "RIGHT"); t:SetHeight(1)
            else
                t:SetPoint("TOP" .. side, layer, "TOP" .. side); t:SetPoint("BOTTOM" .. side, layer, "BOTTOM" .. side); t:SetWidth(1)
            end
        end
        inputEdges[f] = layer
    end
    local function FilterButton(f)
        local nativeArrow = H.Texture(f.arrow) or H.Texture(f.Arrow) or H.Texture(f.arrowTexture)
        if nativeArrow then
            H.Fade(nativeArrow)
            if not f.fdjSkinArrow and f.CreateTexture then
                local t = f:CreateTexture(nil, "OVERLAY")
                t:SetTexture("Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-down3.png")
                t:SetPoint("RIGHT", f, "RIGHT", -7, 0); t:SetSize(10, 7)
                f.fdjSkinArrow = t
            end
        end
        H.Action(f, {"icon", "Icon", "fdjSkinArrow"})
        for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture"}) do
            if f[getter] then H.Fade(f[getter](f)) end
        end
        if f.fdjSkinArrow then f.fdjSkinArrow:SetAlpha(1); f.fdjSkinArrow:SetVertexColor(0.8, 0.8, 0.82, 1) end
        H.Font((f.GetFontString and f:GetFontString()) or f.text or f.Text, 0.9, 0.9, 0.92)
    end
    local function Popup(f)
        local root = _G.ForeverDungeonJournalFrame
        local filter = root and root.lootFilterWindow or _G.ForeverDungeonJournalLootFilter
        local favourites = root and root.favouritesWindow or _G.ForeverDungeonJournalFavourites
        local r, g, b = S.GetAccentColor()
        if f == filter then
            if ns.BindPopupOwner then ns.BindPopupOwner(S, module, f) end
            H.Font(f.title, r, g, b); H.Font(f.statsHeader, r, g, b)
            H.Font(f.statsHint, 0.68, 0.68, 0.71)
            if H.Allowed(f.minBox) then S.EditBox(f.minBox, {padInput = false}); InputEdge(f.minBox) end
            for _, key in ipairs({"show", "ok", "clear"}) do
                local button = f[key]
                if H.Allowed(button) then FilterButton(button); if button.SetHeight then button:SetHeight(24) end end
            end
            local button = f.show
            local icon = button and H.Texture(button.icon)
            local label = button and button.GetFontString and button:GetFontString()
            if icon and label and label.ClearAllPoints then
                icon:SetSize(16, 16)
                label:ClearAllPoints(); label:SetPoint("CENTER", button, "CENTER", 9, 0)
                icon:ClearAllPoints(); icon:SetPoint("RIGHT", label, "LEFT", -2, 0)
            end
        elseif f == favourites then
            local inset = f.Inset
            if H.Allowed(inset) then
                if S.Inset then S.Inset(inset) end
                H.Fade(inset.Bg); H.Fade(inset.Background)
                if inset.SetBackdrop then inset:SetBackdrop(nil) end
                if not inset.fdjSkinInset and inset.ClearAllPoints then
                    inset:ClearAllPoints(); inset:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -38)
                    inset:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 12); inset.fdjSkinInset = true
                end
                if inset.NineSlice then S.FadeNineSlice(inset.NineSlice) end
            end
            H.Fade(f.Bg); H.Fade(f.Background); H.Fade(f.fdjStarBackground)
            if H.Allowed(f.PortraitContainer) then
                for _, t in ipairs(H.Regions(f.PortraitContainer)) do if H.Texture(t) then H.Fade(t) end end
            end
            Canvas(f)
            H.Font(f.fdjTitle, r, g, b); H.Font(f.fdjEmpty, 0.72, 0.72, 0.75)
            if f.fdjTitle and f.fdjTitle.ClearAllPoints and not f.fdjSkinTitle then
                f.fdjTitle:ClearAllPoints(); f.fdjTitle:SetPoint("TOP", f, "TOP", 0, -12); f.fdjSkinTitle = true
            end
            for _, divider in pairs(f.fdjDividers or {}) do H.Font(divider.title, r, g, b) end
            local portrait = H.Texture(f.portrait) or f.PortraitContainer and H.Texture(f.PortraitContainer.portrait)
            -- The non-portrait template keeps its star beside a local holder.
            if not portrait and f.fdjStarBackground and f.fdjStarBackground.GetParent then
                local holder = f.fdjStarBackground:GetParent()
                if holder ~= f and H.Allowed(holder) then
                    for _, t in ipairs(H.Regions(holder)) do
                        local path = t.GetTexture and t:GetTexture()
                        if type(path) == "string" and path:find("FavouriteStar", 1, true) then portrait = t; break end
                    end
                end
            end
            if portrait then
                if not favouriteIcons[f] then
                    local layer = CreateFrame("Frame", nil, f); visuals[layer] = true
                    layer:SetSize(22, 22); layer:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -9); layer:EnableMouse(false)
                    local t = layer:CreateTexture(nil, "OVERLAY"); t:SetAllPoints(layer)
                    t:SetTexture(portrait:GetTexture()); t:SetTexCoord(0, 1, 0, 1)
                    favouriteIcons[f] = t
                end
                H.Fade(portrait)
            end
        end
    end
    local function Grip(f)
        if not H.Allowed(f) or not f.CreateTexture then return end
        for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetHighlightTexture"}) do
            if f[getter] then H.Fade(f[getter](f)) end
        end
        if grips[f] then return end
        local lines = {}
        for i = 1, 2 do
            local t = f:CreateTexture(nil, "OVERLAY"); t:SetColorTexture(0.65, 0.65, 0.68, 0.65)
            t:SetSize(7 - (i-1)*3, 1); t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3 + (i-1)*3)
            if t.SetRotation then t:SetRotation(math.pi / 4) end
            lines[i] = t
        end
        grips[f] = lines
    end
    local unpack = unpack or table.unpack

    local function Palette()
        fontGeneration = fontGeneration + 1
        local r, g, b = S.GetAccentColor()
        -- Journal.lua caches this table; recolor in place without changing saved settings.
        for _, theme in pairs(journal.THEMES or {}) do
            theme.frame = {0.025, 0.025, 0.03, 0.98}
            theme.content = {0.035, 0.035, 0.04, 0.96}
            theme.header = {0.055, 0.055, 0.065, 0.96}
            theme.left = {0.025, 0.025, 0.03, 0.96}
            theme.right = {0.035, 0.035, 0.04, 0.96}
            theme.row = {0.06, 0.06, 0.07, 0.92}
            theme.lootRow = {0.06, 0.06, 0.07, 0.92}
            theme.rowSelected = {r * 0.25, g * 0.25, b * 0.25, 0.95}
            theme.border = {0.055, 0.055, 0.055, 1}
            theme.title = {r, g, b}
            theme.text = {0.9, 0.9, 0.92}
            theme.muted = {0.65, 0.65, 0.68}
        end
    end

    local function Panel(f)
        if not H.Allowed(f) or panels[f] then return end
        panels[f] = true
        -- Preserve foreground portrait/artwork regions while replacing the background.
        local artwork = {}
        for _, region in ipairs({f:GetRegions()}) do
            if region.GetTexture and region.GetDrawLayer then
                local layer = region:GetDrawLayer()
                if layer == "ARTWORK" or layer == "OVERLAY" then artwork[region] = region:GetAlpha() end
            end
        end
        S.Panel(f)
        for region, alpha in pairs(artwork) do region:SetAlpha(alpha) end
        if f.SetBackdrop then f:SetBackdrop(nil) end
    end

    local readable = setmetatable({}, {__mode = "k"})
    local queueQuest, ModeTab
    local function Readable(text, role, owner)
        if not H.Allowed(text) or text:GetObjectType() ~= "FontString" then return end
        local d = readable[text]
        if not d then
            d = {}; readable[text] = d
            d.paint = function()
                if d.painting or not ns.IsEnabled(module) or not H.Allowed(text) then return end
                if Busy() then module.combatPending = true; return end
                d.painting = true
                local r, g, b = 0.86, 0.86, 0.89
                if d.role == "accent" then r, g, b = S.GetAccentColor()
                elseif d.role == "muted" then r, g, b = 0.68, 0.68, 0.71
                elseif d.role == "heading" then r, g, b = 0.94, 0.94, 0.96
                elseif d.role == "action" and d.owner and d.owner.IsEnabled and not d.owner:IsEnabled() then r, g, b = 0.5, 0.5, 0.5 end
                H.Font(text)
                local cr, cg, cb, ca = text:GetTextColor()
                if cr ~= r or cg ~= g or cb ~= b or ca ~= 1 then text:SetTextColor(r, g, b, 1) end
                d.painting = false
            end
            -- Local/private renderers bypass exported namespace hooks. Guard
            -- only known prose/headings, never item or quest-status colours.
            for _, method in ipairs({"SetTextColor", "SetFontObject", "SetFont"}) do H.Hook(text, method, d.paint) end
        end
        d.role, d.owner = role, owner
        d.paint()
    end
    local function QuestReadability(f)
        if not H.Allowed(f) or Busy() then return end
        for _, key in ipairs({"questDetailText", "questTurninText", "questRewardSummary", "questStartsText", "questNotesText"}) do Readable(f[key], "body") end
        for _, key in ipairs({"selectedQuestMeta", "noQuestMessage"}) do Readable(f[key], "muted") end
        for _, key in ipairs({"questObjectiveHeader", "questRequiredItemsHeader", "questStartsHeader", "questTurninHeader", "questNotesHeader", "questRewardHeader", "questAlsoReceiveHeader", "questListTitle"}) do Readable(f[key], "heading") end
        Readable(f.selectedQuestName, "accent")
        Canvas(f.questLeftPanel); Canvas(f.questTextInset)
    end
    local function QuestDone()
        if Busy() then module.combatPending = true; return end
        local f = _G.ForeverDungeonJournalFrame
        QuestReadability(f)
        if H.Allowed(f) then
            for _, key in ipairs({"bossesTab", "questsTab", "mapTab", "dungeonRouteButton", "dungeonPrepButton"}) do ModeTab(f[key]) end
        end
        if queueQuest then queueQuest() end
    end
    local nativeChrome = {"Left", "Middle", "Right", "LeftDisabled", "MiddleDisabled", "RightDisabled", "LeftSeparator", "RightSeparator"}
    local function StripButton(f)
        if f.SetBackdrop then f:SetBackdrop(nil) end
        for _, key in ipairs(nativeChrome) do H.Fade(f[key]) end
        if f.NineSlice and S.FadeNineSlice then S.FadeNineSlice(f.NineSlice) end
        for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture"}) do
            if f[getter] then H.Fade(f[getter](f)) end
        end
    end
    local function QuestAction(button)
        if not H.Allowed(button) then return end
        H.Action(button, {"icon", "Icon"}); StripButton(button)
        Readable((button.GetFontString and button:GetFontString()) or button.text or button.Text, "action", button)
        local function Paint()
            if Busy() then module.combatPending = true; return end
            StripButton(button)
            Readable((button.GetFontString and button:GetFontString()) or button.text or button.Text, "action", button)
        end
        for _, name in ipairs({"SetNormalTexture", "SetPushedTexture", "SetDisabledTexture", "SetHighlightTexture", "Enable", "Disable"}) do H.Hook(button, name, Paint) end
        H.Script(button, "OnClick", QuestDone)
    end
    ModeTab = function(tab)
        if not H.Allowed(tab) then return end
        -- Keep the journal's foreground icon; the API only preserves .Icon.
        if H.Texture(tab.fdjIcon) then tab.Icon = tab.fdjIcon end
        H.Tab(tab, tab.IsEnabled and not tab:IsEnabled() or false)
        StripButton(tab)
        H.Hook(tab, "SetBackdrop", function(_, value) if value and not Busy() then tab:SetBackdrop(nil) end end)
        H.Script(tab, "OnClick", QuestDone)
        -- UIPanelButtonTemplate can restore its state textures after Enable().
        -- Suppress only native chrome, never the EUI tab's own regions.
        for _, getter in ipairs({"GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture"}) do
            if tab[getter] then H.Fade(tab[getter](tab)) end
        end
        local native = tab.text or (tab.GetFontString and tab:GetFontString())
        local replacement
        for _, text in ipairs(H.Regions(tab)) do
            if text ~= native and text.GetObjectType and text:GetObjectType() == "FontString" then replacement = true; break end
        end
        if replacement then H.Fade(native) else Readable(native, "heading") end
        for _, method in ipairs({"SetNormalTexture", "SetPushedTexture", "SetDisabledTexture", "SetHighlightTexture", "Enable", "Disable"}) do
            H.Hook(tab, method, function() ModeTab(tab) end)
        end
    end

    local function Visit(f, kind)
        local root = _G.ForeverDungeonJournalFrame
        if root and f == root.languageSelectorButton then Language(f); return true end
        if root and (f == root.bossesTab or f == root.questsTab or f == root.mapTab or f == root.dungeonRouteButton or f == root.dungeonPrepButton) then
            -- FDJ disables the active mode button. Mirror that visual state,
            -- including programmatic switches, without enabling/disabling it.
            ModeTab(f); return true
        end
        if root then
            for _, key in ipairs({"questMapButton", "questChainButton", "questStartLinkButton", "questLeadsToButton", "questShareButton"}) do
                if f == root[key] then QuestAction(f); return true end
            end
        end
        if kind == "Button" and f.questIndex and f.name and f.meta then
            H.Script(f, "OnClick", QuestDone)
            H.Script(f, "OnShow", function() if queueQuest then queueQuest() end end)
            H.Font(f.name); H.Font(f.meta)
            return true
        end
        -- UIPanelCloseButton textures can be numeric file IDs on this client.
        -- Identify the unnamed journal close control by its exact owned anchor.
        if kind == "Button" and f.GetParent and f.GetPoint then
            local parent = f:GetParent()
            if parent == _G.ForeverDungeonJournalFrame or parent == _G.ForeverDungeonJournalSettings
                or parent == _G.ForeverDungeonJournalLootFilter then
                local point, relative, relativePoint, x, y = f:GetPoint(1)
                if point == "TOPRIGHT" and relative == parent and relativePoint == "TOPRIGHT"
                    and ((x == -3 and y == -3) or (x == -2 and y == -2)) then S.CloseButton(f) end
            end
        end
        if kind == "CheckButton" then Check(f); return true end
        if FilterOwner(f) then
            if kind == "Frame" and H.Allowed(f.Button) and H.Allowed(f.Text) then
                local icon = H.Texture(f.icon) or H.Texture(f.Icon)
                local alpha = icon and icon:GetAlpha()
                S.Dropdown(f); Arrow(f.Button, "down"); H.Font(f.Text, 0.9, 0.9, 0.92)
                if icon then icon:SetAlpha(alpha) end
                return true
            end
            if kind == "EditBox" then S.EditBox(f, {padInput = false}); InputEdge(f); return true end
            if kind == "Button" and not f.itemID and not f.itemId then
                local label = (f.GetFontString and f:GetFontString()) or f.text or f.Text
                if label then FilterButton(f); return true end
            end
        end
        if kind == "Slider" then
            H.LegacySlider(f)
            local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
            if thumb and f.GetOrientation and f:GetOrientation() == "VERTICAL" then
                thumb:SetWidth(8)
                local name = f.GetName and f:GetName()
                Arrow(f.ScrollUpButton or name and _G[name .. "ScrollUpButton"], "up")
                Arrow(f.ScrollDownButton or name and _G[name .. "ScrollDownButton"], "down")
            end
            return true
        end
        if root and f == root.resizeGrip then Grip(f); return true end
        H.Resize(f)
        if kind == "Button" and f.art and f.dungeonName then
            -- Keep every artwork/status region and its native opacity, not just the image.
            H.ThinBackdrop(f)
            local function Border(_, r, g, b)
                if borderLocks[f] then return end
                if InCombatLockdown and InCombatLockdown() then refresh(); return end
                if r == nil and f.GetBackdropBorderColor then r, g, b = f:GetBackdropBorderColor() end
                local hover = r and g and b and r > 0.8 and g > 0.45 and b < 0.4
                if not hover and r and g and b and (math.abs(r - g) > 0.04 or math.abs(r - b) > 0.04) then return end
                if f.SetBackdropBorderColor then
                    borderLocks[f] = true
                    if hover then local cr, cg, cb = S.GetAccentColor(); f:SetBackdropBorderColor(cr, cg, cb, 1)
                    else f:SetBackdropBorderColor(0.055, 0.055, 0.055, 1) end
                    borderLocks[f] = false
                end
            end
            Border(); H.Hook(f, "SetBackdropBorderColor", Border)
            local r, g, b = S.GetAccentColor()
            H.Font(f.title, 0.93, 0.93, 0.95)
            if f.topShade then f.topShade:SetColorTexture(0, 0, 0, 0.26) end
            if f.innerGlow then f.innerGlow:SetColorTexture(0.2, 0.2, 0.22, 0.35) end
            for _, text in ipairs(H.Regions(f)) do H.Font(text) end
            return true
        end
        if kind == "Button" and f.SetBackdrop and not f.icon and not f.Icon and not f.itemID and not f.itemId then
            local label = (f.GetFontString and f:GetFontString()) or f.text or f.Text
            local parent = f.GetParent and f:GetParent()
            if label or (root and (f == root.languageSelectorButton or f == root.hideDungeonsButton
                or f == root.bugReportButton or f == root.favouritesButton or f == root.lootFilterButton
                or parent == root.homePanel or parent == root.languageMenu)) then
                local keep = {}
                for i, region in ipairs(H.Regions(f)) do
                    if region.GetTexture and region.GetDrawLayer and region:GetDrawLayer() == "ARTWORK" then
                        local key = "euiHeaderArtwork" .. i; f[key] = region; keep[#keep + 1] = key
                    end
                end
                H.Action(f, keep)
                for _, r in ipairs(H.Regions(f)) do H.Font(r, 1, 1, 1) end
                return true
            end
        end
        -- Brown text from the original parchment becomes unreadable on a dark panel.
        -- Keep item names/rarity, quest status indicators and portrait artwork intact.
        for _, key in ipairs({"slot", "meta"}) do H.Font(f[key], 0.65, 0.65, 0.68) end
    end

    local questQueue = {}
    queueQuest = function()
        if fullQueued or not ns.IsEnabled(module) then return end
        local serial = fullSerial
        H.Queue(questQueue, function()
            if serial ~= fullSerial then return end
            if Busy() then module.combatPending = true; return end
            local f = _G.ForeverDungeonJournalFrame
            if not H.Allowed(f) then return end
            QuestReadability(f)
            for _, key in ipairs({"questLeftPanel", "questTextInset"}) do
                if H.Allowed(f[key]) and (not f[key].IsVisible or f[key]:IsVisible()) then H.Scan(f[key], queueQuest, Visit) end
            end
        end)
    end
    local function Exclude(f)
        local out = {}
        if f.dungeonMapArtHolder then out[f.dungeonMapArtHolder] = true end
        if f == _G.ForeverDungeonJournalFrame then
            for _, key in ipairs({"lootFilterWindow", "favouritesWindow", "bugReportWindow"}) do
                if H.Allowed(f[key]) then out[f[key]] = true end
            end
        end
        return out
    end
    local function Watch(f)
        if not H.Allowed(f) or watchPass[f] then return end
        watchPass[f] = true
        local main = f == _G.ForeverDungeonJournalFrame
        H.Shell(f, refresh, {noTopBar = true, noAccent = main})
        if not main then ns.AttachAccent(S, f) end
        Popup(f)
        for _, key in ipairs({"fdjCloseButton", "CloseButton", "closeButton"}) do
            if H.Allowed(f[key]) then S.CloseButton(f[key]) end
        end
        local first = not watched[f]
        if first then
            watched[f] = true
            -- Private page renderers change panel colors; schedule after the whole render.
            H.Hook(f, "SetBackdropColor", refresh)
            H.Hook(f, "SetBackdropBorderColor", refresh)
        end
        local function Controls(source)
            if fullQueued then return end
            if main and H.Allowed(source) then
                local parent = source
                for _ = 1, 20 do
                    if parent == f or not H.Allowed(parent) then break end
                    if parent == f.questLeftPanel or parent == f.questRightPanel or parent == f.questTextInset then queueQuest(); return end
                    parent = parent.GetParent and parent:GetParent()
                end
            end
            local serial = fullSerial
            H.Queue(f, function()
                if serial ~= fullSerial then return end
                if Busy() then module.combatPending = true; return end
                H.Scan(f, Controls, Visit, Exclude(f))
            end)
        end
        if first or not f.IsVisible or f:IsVisible() then
            H.Scan(f, Controls, Visit, Exclude(f))
        end
    end

    local function Apply()
        if not ns.IsEnabled(module) then fullQueued = false; return end
        if Busy() then module.combatPending = true; fullQueued = false; return end
        module.combatPending = false
        watchPass = {}
        local f = _G.ForeverDungeonJournalFrame
        if f then
            Watch(f)
            for _, key in ipairs({"mapTab", "bossesTab", "questsTab", "dungeonRouteButton", "dungeonPrepButton"}) do ModeTab(f[key]) end
            for _, key in ipairs({"contentPanel", "headerPanel", "homePanel", "leftPanel", "rightPanel",
                "questLeftPanel", "questRightPanel", "questTextInset", "routePanel"}) do Panel(f[key]) end
            Canvas(f.homePanel)
            Canvas(f.leftPanel); Canvas(f.rightPanel)
            QuestReadability(f)
            for _, key in ipairs({"homeParchment", "contentParchment", "headerParchment", "leftParchment",
                "rightParchment", "questLeftParchment", "questRightParchment", "questParchment", "atmosphere"}) do H.Fade(f[key]) end
            for _, edge in ipairs(f.questInsetEdges or {}) do
                edge:SetColorTexture(0.055, 0.055, 0.055, 1)
            end
            for _, key in ipairs({"questDetailText", "questTurninText", "questRewardSummary", "selectedQuestMeta",
                "questStartsText", "questNotesText", "noQuestMessage", "selectedBossQuestion",
                "selectedBossDescription", "lootTitle"}) do
                H.Font(f[key], 0.85, 0.85, 0.88)
            end
            local r, g, b = S.GetAccentColor()
            H.Font(f.mainTitle, 1, 1, 1)
            H.Font(f.selectedQuestName, r, g, b)
            H.Font(f.homeTitle, r, g, b)
            H.Font(f.homeSubtitle, 0.65, 0.65, 0.68)
            H.Font(f.dungeonTitle, r, g, b)
            if f.homePanel then
                for _, t in ipairs(H.Regions(f.homePanel)) do
                    if t.GetHeight and t:GetHeight() == 1 and t.SetColorTexture then t:SetColorTexture(0.2, 0.2, 0.22, 0.35) end
                end
            end
            if f.languageMenu then Panel(f.languageMenu); H.Scan(f.languageMenu, refresh, Visit) end
            if f.languageSelectorButton then Language(f.languageSelectorButton); H.Font(f.languageSelectorText, 1, 1, 1) end
            for _, key in ipairs({"searchEditBox", "languageSelectorButton", "bugReportButton"}) do
                local control = f[key]
                if H.Allowed(control) and control.SetHeight and (not control.GetHeight or control:GetHeight() ~= 24) then control:SetHeight(24) end
            end
            if H.Allowed(f.searchEditBox) and f.searchEditBox.ClearAllPoints and not f.searchEditBox.fdjSkinAligned then
                f.searchEditBox:ClearAllPoints(); f.searchEditBox:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -15)
                f.searchEditBox.fdjSkinAligned = true
            end
            H.Font(f.searchPlaceholder, 0.65, 0.65, 0.68)
            local reportIcon = f.bugReportButton and H.Texture(f.bugReportButton.icon)
            if reportIcon then reportIcon:SetSize(18, 18) end
            H.Font(f.selectedBossName, r, g, b)
            for _, key in ipairs({"backButton"}) do
                if H.Allowed(f[key]) then S.Button(f[key]) end
            end
            if H.Allowed(f.questPrevStepButton) and S.SoftPageButton then S.SoftPageButton(f.questPrevStepButton, "<") end
            if H.Allowed(f.questNextStepButton) and S.SoftPageButton then S.SoftPageButton(f.questNextStepButton, ">") end
            for _, key in ipairs({"bugReportWindow", "lootFilterWindow", "favouritesWindow"}) do
                if f[key] then Watch(f[key]) end
            end
        end
        for _, name in ipairs({"ForeverDungeonJournalSettings", "ForeverDungeonJournalNotice",
            "ForeverDungeonJournalOptionsPanel", "ForeverDungeonJournalLootFilter",
            "ForeverDungeonJournalLootFilterResults", "ForeverDungeonJournalFavourites",
            "ForeverDungeonJournalFavouriteContextMenu"}) do
            local window = _G[name]
            -- The Blizzard Settings category is embedded, so only style its controls.
            if window then
                if name == "ForeverDungeonJournalOptionsPanel" then H.Scan(window, refresh)
                else Watch(window) end
            end
        end
        for _, name in ipairs({"OpenBossPage", "OpenQuestPage", "RefreshLootNow", "OpenSearchResult"}) do
            H.Hook(journal, name, refresh) -- Some exports appear only after first opening.
        end
        S.RefreshSoftBorders()
        fullQueued = false
    end
    refresh = function() fullQueued = true; fullSerial = fullSerial + 1; H.Queue(module, Apply) end
    for _, name in ipairs({"ToggleJournal", "ShowUpdateNotice", "ToggleSettingsPanel", "ToggleLootFilterWindow",
        "ToggleFavouritesWindow", "ToggleBugReportWindow", "RefreshHomeCards", "GoBackPage",
        "RefreshLootFilterResults", "RebuildLootFilterPage", "RefreshFavouritesWindow",
        "ShowItemFavouriteMenu", "ShowLootFilterResults", "RelocalizeLootFilter", "RefreshHomeDungeonCards",
        "ApplyTheme", "ApplyLocale", "ApplyLocalization", "ApplySelectedLanguage"}) do H.Hook(journal, name, refresh) end
    for _, name in ipairs({"RefreshQuestList", "RefreshQuestDetail", "SelectQuest", "SelectQuestByID", "SetQuestFaction", "SelectPrerequisiteStepByOffset", "SetMode", "ShowDungeonPage", "RefreshAll"}) do H.Hook(journal, name, QuestDone) end
    -- Current workers finish through exported renderers. Keep the legacy
    -- one-shot worker fallback only when those exports are unavailable.
    if journal.questRefreshWorker and not (type(journal.RefreshQuestList) == "function" and type(journal.RefreshQuestDetail) == "function") then
        H.Script(journal.questRefreshWorker, "OnUpdate", refresh)
    end
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", function() if module.combatPending then refresh() end end)
    Palette()
    refresh()
    module.refresh = refresh
    if S.OnLooksChanged then S.OnLooksChanged(function()
        if ns.IsEnabled(module) then Palette(); refresh() end
    end) end
end)

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("ForeverDungeonJournal", DefineSkin)
else DefineSkin() end
