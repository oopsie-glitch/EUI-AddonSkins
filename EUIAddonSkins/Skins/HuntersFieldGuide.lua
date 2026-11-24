local _, ns = ...

-- Hunter's Field Guide draws its journal as a spellbook. On the Forever book
-- the spellbook art (parchment page, header plate, entry frames, tab frames)
-- is faded, the book's own text styles get a light palette, icons and tabs
-- are squared, the portrait moves into the title bar and the page arrows use
-- EUI's. The Classic book keeps its 1.x spellbook art and ink text; only its
-- toolbar and Filter menu are styled. The target panel, the toast, the Filter
-- menu and the export window are styled on both books.

-- Atlases of the Forever spellbook that only draw the parchment look.
local SPELLBOOK_ART = {
    ["spellbook-Page-Right-C60"] = true,
    ["spellbook-list-backplate"] = true,
    ["spellbook-divider"] = true,
    ["spellbook-item-backplate"] = true,
    ["spellbook-item-iconframe"] = true,
    ["spellbook-item-iconframe-inactive"] = true,
    ["spellbook-item-iconframe-shadow"] = true,
    ["spellbook-item-iconframe-hover"] = true,
    ["spellbook-Tab-Frame-C60"] = true,
    ["spellbook-Tab-Frame-Glow-C60"] = true,
    ["spellbook-Tab-Frame-glow-gradient-C60"] = true,
}

-- Light text for the book's styles. Accent follows EUI's accent colour.
local LIGHT = {
    body = {0.86, 0.86, 0.86}, heading = {1, 1, 1}, header = {1, 1, 1},
    small = {0.78, 0.78, 0.78}, pager = {0.85, 0.85, 0.85}, label = {0.6, 0.6, 0.62},
    good = {0.45, 0.9, 0.45}, bad = {1, 0.45, 0.4},
}
local STYLE_ORDER = {"body", "small", "pager", "heading", "header", "label", "accent", "good", "bad"}
local RARE = {0.42, 0.72, 1}
-- Colour codes the book writes into its text for the parchment.
local HEX = {
    ["|cff0a570a"] = "|cff73e673", -- learnable / new / happy (dark green)
    ["|cff9a1008"] = "|cffff6a5a", -- unhappy
    ["|cff8a5a00"] = "|cffe6b84d", -- content
}
local INK = {0.24, 0.15, 0.06} -- target panel and toast text

local function DefineSkin()
    ns.RegisterModule("HuntersFieldGuide", "Hunter's Field Guide", function()
        local guide = _G.HuntersFieldGuide
        return type(guide) == "table" and type(guide.ShowExport) == "function"
            and type(guide.RefreshUI) == "function" and _G.FieldGuideFrame ~= nil
    end, function(S, module)
        local guide = _G.HuntersFieldGuide
        local root = _G.FieldGuideFrame
        local book = guide.skinName == "forever"
        local H = ns.CreateSkinHelper(S, module)
        local fonts = setmetatable({}, {__mode = "k"})
        local seen = setmetatable({}, {__mode = "k"})
        local underlines = {}
        local remap = {}
        local accentMap
        local accentText = setmetatable({}, {__mode = "k"})
        local done = {}
        local backing, topBar
        local pending, looksPending

        local function Locked() return InCombatLockdown and InCombatLockdown() end

        local function Font(text)
            if H.Allowed(text) and text:GetObjectType() == "FontString" and S.Font then
                S.Font(text)
                fonts[text] = true
            end
        end

        local function RegionFonts(f)
            for _, region in ipairs(H.Regions(f)) do
                if region.GetObjectType and region:GetObjectType() == "FontString" then Font(region) end
            end
        end

        -- Label colour is left alone: Filter turns green while a filter is on.
        local function Button(button)
            if not H.Allowed(button) or not S.Button then return end
            S.Button(button)
            if button.GetFontString then Font(button:GetFontString()) end
        end

        local function Check(check)
            if not H.Allowed(check) or not S.Checkbox then return end
            S.Checkbox(check)
            Font(check.Text or check.text)
        end

        local function EditBox(box)
            if not H.Allowed(box) or not S.EditBox then return end
            -- SearchBoxTemplate keeps its magnifier; native bounds stay put.
            local icon = H.Texture(box.searchIcon or box.SearchIcon)
            local alpha = icon and icon:GetAlpha()
            S.EditBox(box, {padInput = false})
            if icon then icon:SetAlpha(alpha) end
        end

        local function Fill(texture, r, g, b, a)
            if texture then texture:SetColorTexture(r, g, b, a) end
        end

        local function PaintOwned()
            if S.GetPanelColor then
                local r, g, b = S.GetPanelColor()
                Fill(backing, r, g, b, 1)
            end
            Fill(topBar, 0, 0, 0, 0.5)
            if S.GetAccentColor then
                local r, g, b = S.GetAccentColor()
                for _, line in ipairs(underlines) do Fill(line, r, g, b, 1) end
            end
        end

        local function RemoveMasks(texture)
            if not (texture and texture.GetNumMaskTextures and texture.RemoveMaskTexture) then return end
            for i = texture:GetNumMaskTextures(), 1, -1 do
                local mask = texture:GetMaskTexture(i)
                if mask then texture:RemoveMaskTexture(mask) end
            end
        end

        -- A square icon with EUI's 1px border on an owned holder the size of the icon.
        local function SquareIcon(icon, parent)
            if not (H.Texture(icon) and parent and parent.CreateTexture) then return end
            RemoveMasks(icon)
            if not S.SquareIcon then return end
            local holder = CreateFrame("Frame", nil, parent)
            holder:SetAllPoints(icon)
            holder:EnableMouse(false)
            S.SquareIcon(icon, holder)
        end

        -- Book text: the light palette replaces the parchment one.
        local function SetPalette()
            local styles = guide.Skins and guide.Skins.forever and guide.Skins.forever.styles
            if type(styles) ~= "table" then return end
            local accent = S.GetAccentColor and {S.GetAccentColor()} or {1, 0.82, 0}
            -- Several styles share one ink table; text coloured before this
            -- (at creation) maps to body, the first in this order.
            for _, kind in ipairs(STYLE_ORDER) do
                local st = styles[kind]
                local light = kind == "accent" and accent or LIGHT[kind]
                if type(st) == "table" and type(st.color) == "table" and light then
                    if not st.euiOriginal then st.euiOriginal = st.color end
                    local pair = {st.euiOriginal, light}
                    remap[#remap + 1] = pair
                    if kind == "accent" then accentMap = pair end
                    st.color = {light[1], light[2], light[3]}
                    st.shadow = nil
                end
            end
            local skin = guide.Skins.forever
            if type(skin.rare) == "table" then
                remap[#remap + 1] = {skin.rare, RARE}
                skin.rare = {RARE[1], RARE[2], RARE[3]}
            end
            local ink = _G.SPELLBOOK_FONT_COLOR
            if type(ink) == "table" and ink.GetRGB then remap[#remap + 1] = {{ink:GetRGB()}, LIGHT.body} end
        end

        local function Near(a, r, g, b)
            return math.abs(a[1] - r) < 0.01 and math.abs(a[2] - g) < 0.01 and math.abs(a[3] - b) < 0.01
        end

        local function LightText(fs)
            local r, g, b = fs:GetTextColor()
            if r then
                local prior = accentText[fs]
                if prior and accentMap and Near(prior, r, g, b) then
                    local c = accentMap[2]
                    if not Near(c, r, g, b) then fs:SetTextColor(c[1], c[2], c[3]) end
                    accentText[fs] = c
                else
                    for _, pair in ipairs(remap) do
                        if Near(pair[1], r, g, b) then
                            local c = pair[2]
                            fs:SetTextColor(c[1], c[2], c[3])
                            if pair == accentMap then accentText[fs] = c else accentText[fs] = nil end
                            break
                        end
                    end
                end
            end
            local text = fs:GetText()
            if type(text) == "string" and text:find("|c", 1, true) then
                local light = text:gsub("|c%x%x%x%x%x%x%x%x", HEX)
                if light ~= text then fs:SetText(light) end
            end
        end

        local function SkinEntry(e)
            -- The border gets its atlas in SetEntry, so an entry never filled
            -- before activation has no atlas to recognise it by yet.
            H.Fade(H.Texture(e.border))
            SquareIcon(e.icon, e.slot)
            if e.CreateTexture then
                local hover = e:CreateTexture(nil, "HIGHLIGHT")
                hover:SetAllPoints(e)
                hover:SetColorTexture(1, 1, 1, 0.06)
            end
        end

        local function SkinTab(t)
            local icon
            for _, region in ipairs(H.Regions(t)) do
                if region ~= t.frame and region ~= t.active and region ~= t.glow and H.Texture(region)
                    and region:GetDrawLayer() == "ARTWORK" then icon = region end
            end
            -- The tab's SquareMask is offset 2px and keeps the icon's bevel.
            if icon then SquareIcon(icon, t) end
            local line = t:CreateTexture(nil, "OVERLAY")
            line:SetHeight(2)
            line:SetPoint("BOTTOMLEFT", icon or t, "BOTTOMLEFT", 0, -3)
            line:SetPoint("BOTTOMRIGHT", icon or t, "BOTTOMRIGHT", 0, -3)
            underlines[#underlines + 1] = line
            PaintOwned()
            local function Selected(_, on) line:SetShown(on and true or false) end
            Selected(t, t.active and t.active:IsShown())
            H.Hook(t, "SetChecked", Selected)
        end

        -- First sight of an owned control: fade spellbook art, square icons and
        -- tabs, style template buttons. Every visit: light text.
        local function Visit(f, all)
            local first = not seen[f]
            seen[f] = true
            for _, region in ipairs(H.Regions(f)) do
                local kind = region.GetObjectType and region:GetObjectType()
                if kind == "FontString" then
                    LightText(region)
                elseif first and kind == "Texture" and region.GetAtlas and SPELLBOOK_ART[region:GetAtlas() or ""] then
                    H.Fade(region)
                end
            end
            for _, child in ipairs(H.Children(f)) do
                if H.Allowed(child) and (all or child:IsShown()) then
                    local kind = child:GetObjectType()
                    if kind ~= "PlayerModel" and kind ~= "ModelScene" and kind ~= "GameTooltip" then
                        if not seen[child] then
                            if child.SetEntry and child.slot and child.icon then SkinEntry(child)
                            elseif child.frame and child.active and child.glow and child.SetChecked then SkinTab(child)
                            elseif kind == "Button" and child.Left and child.Right and child.GetFontString then Button(child) end
                        end
                        Visit(child, all)
                    end
                end
            end
        end

        local function SkinPortrait()
            local pc = root.PortraitContainer
            local icon = H.Texture(root.portrait)
            if not (pc and icon) then return end
            for _, region in ipairs(H.Regions(pc)) do
                if region ~= icon and H.Texture(region) then H.Fade(region) end
            end
            RemoveMasks(icon)
            icon:ClearAllPoints()
            icon:SetSize(28, 28)
            icon:SetPoint("TOPLEFT", root, "TOPLEFT", 8, -6)
            if S.SquareIcon then
                local holder = CreateFrame("Frame", nil, root)
                holder:SetAllPoints(icon)
                holder:EnableMouse(false)
                S.SquareIcon(icon, holder)
            end
        end

        -- The Forever book is a PortraitFrameTemplate whose spellbook page is a
        -- texture on the window itself, so the window is not given S.Shell (it
        -- would fade every texture the book draws on it); the frame art is
        -- faded and owned fill, title strip and border take its place.
        local function SkinBook()
            if root.NineSlice and S.FadeNineSlice then S.FadeNineSlice(root.NineSlice) end
            H.Fade(H.Texture(root.Bg))
            H.Fade(H.Texture(root.TitleBg))
            H.Fade(H.Texture(root.TopTileStreaks))
            local title = root.TitleContainer
            if type(title) == "table" then H.Fade(H.Texture(title.TitleBg)) end
            backing = root:CreateTexture(nil, "BACKGROUND", nil, -8)
            backing:SetAllPoints(root)
            topBar = root:CreateTexture(nil, "BACKGROUND", nil, -5)
            topBar:SetPoint("TOPLEFT")
            topBar:SetPoint("TOPRIGHT")
            topBar:SetHeight(25)
            if S.Panel then
                local edge = CreateFrame("Frame", nil, root)
                edge:SetAllPoints(root)
                edge:EnableMouse(false)
                S.Panel(edge, {noBg = true})
            end
            if H.Allowed(root.CloseButton) and S.CloseButton then S.CloseButton(root.CloseButton) end
            Font(root.title)
            SkinPortrait()
            local header = root.header
            if H.Allowed(header) and header.CreateTexture then
                local rule = header:CreateTexture(nil, "ARTWORK")
                rule:SetHeight(1)
                rule:SetPoint("BOTTOMLEFT", -8, 0)
                rule:SetPoint("BOTTOMRIGHT", -60, 0)
                rule:SetColorTexture(1, 1, 1, 0.12)
                -- Styled once at creation and only re-texted afterwards.
                if H.Allowed(header.text) then header.text:SetTextColor(LIGHT.header[1], LIGHT.header[2], LIGHT.header[3]) end
            end
            local pager = guide.pager
            if type(pager) == "table" and S.PageButton then
                if H.Allowed(pager.prev) then S.PageButton(pager.prev, "<") end
                if H.Allowed(pager.next) then S.PageButton(pager.next, ">") end
            end
            SetPalette()
            PaintOwned()
            Visit(root, true)
        end

        local function SkinWindow()
            if done.main or not H.Allowed(root) then return end
            done.main = true
            if book then SkinBook() end
            for _, key in ipairs({"back", "map", "model", "filter"}) do Button(root[key]) end
            EditBox(root.search)
        end

        local function SkinFilter()
            local menu = root.filterMenu
            if done.filter or not H.Allowed(menu) then return end
            done.filter = true
            if menu.SetBackdrop then menu:SetBackdrop(nil) end
            if S.Panel then S.Panel(menu) end
            RegionFonts(menu)
            for _, key in ipairs({"level", "speed", "look"}) do Check(menu[key]) end
            if type(menu.only) == "table" then
                for _, check in pairs(menu.only) do Check(check) end
            end
            Button(menu.clear)
        end

        local function Popup(f)
            if not H.Allowed(f) then return end
            if f.SetBackdrop then f:SetBackdrop(nil) end
            if S.Panel then S.Panel(f) end
            for _, region in ipairs(H.Regions(f)) do
                if region.GetObjectType and region:GetObjectType() == "FontString" then
                    local r, g, b = region:GetTextColor()
                    if r and Near(INK, r, g, b) then region:SetTextColor(LIGHT.body[1], LIGHT.body[2], LIGHT.body[3]) end
                    Font(region)
                end
            end
            Button(f.done)
        end

        local function SkinPopups()
            if done.popups then return end
            local panel, toast = _G.FieldGuideTargetPanel, _G.FieldGuideToast
            if not (panel and toast) then return end
            done.popups = true
            Popup(panel)
            Popup(toast)
        end

        -- Built on the first export, then reused.
        local function SkinExport()
            local export = _G.FieldGuideExport
            if done.export or not H.Allowed(export) then return end
            done.export = true
            H.Shell(export, function() end)
            RegionFonts(export)
            for _, child in ipairs(H.Children(export)) do
                if H.Allowed(child) and child:GetObjectType() == "Button" and S.CloseButton then S.CloseButton(child) end
            end
            local scroll = _G.FieldGuideExportScroll
            local bar = scroll and (scroll.ScrollBar or _G.FieldGuideExportScrollScrollBar)
            if H.Allowed(bar) and S.ScrollBar then S.ScrollBar(bar) end
            EditBox(export.link)
        end

        local function ApplyLooks()
            if Locked() then looksPending = true; return end
            looksPending = nil
            if book then
                local styles = guide.Skins.forever.styles
                if S.GetAccentColor and styles and styles.accent then
                    local accent = {S.GetAccentColor()}
                    if accentMap then accentMap[2] = accent end
                    styles.accent.color = accent
                end
                PaintOwned()
            end
            for text in pairs(fonts) do Font(text) end
            if book and root:IsShown() then guide:RefreshUI() end
        end

        local function Refresh()
            if not ns.IsEnabled(module) then return end
            if Locked() then pending = true; return end
            pending = nil
            SkinWindow()
            SkinFilter()
            SkinPopups()
            SkinExport()
            if looksPending then ApplyLooks() end
        end

        -- Every page is drawn by RefreshUI (the pet tab also by PetTabRefresh):
        -- new pages are faded and recoloured as they finish, in the same frame.
        local function PageDrawn()
            if not (book and done.main and root:IsShown()) then return end
            Visit(root, false)
        end
        H.Hook(guide, "RefreshUI", PageDrawn)
        H.Hook(guide, "PetTabRefresh", PageDrawn)
        local function ToastShown()
            local toast = _G.FieldGuideToast
            if done.popups and toast and H.Allowed(toast.sub) then LightText(toast.sub) end
        end
        H.Hook(guide, "Toast", ToastShown)
        H.Hook(guide, "ToastNotice", ToastShown)
        H.Hook(guide, "ShowExport", function()
            if not done.export then Refresh() end
        end)
        H.Script(root, "OnShow", function()
            if pending or looksPending then Refresh() end
        end)
        if S.OnLooksChanged then
            S.OnLooksChanged(function()
                if ns.IsEnabled(module) and done.main then ApplyLooks() end
            end)
        end
        local recovery = CreateFrame("Frame")
        recovery:RegisterEvent("PLAYER_REGEN_ENABLED")
        recovery:SetScript("OnEvent", function()
            if pending or looksPending then Refresh() end
        end)
        module.refresh = Refresh
        Refresh()
    end)
end

ns.RegisterSkinDefinition("HuntersFieldGuide", DefineSkin)
