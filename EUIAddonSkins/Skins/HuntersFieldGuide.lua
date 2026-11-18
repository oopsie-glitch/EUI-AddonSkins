local _, ns = ...

-- Hunter's Field Guide draws its journal as a spellbook: parchment pages, ink
-- text, spellbook entries, tabs and page arrows. Those pages stay native (dark
-- ink would be unreadable on an EUI surface). The skin styles the window
-- chrome around the Forever book, the toolbar, the Filter menu and the export
-- window. The Classic book keeps its spellbook frame art; only its toolbar and
-- Filter menu are styled. The target panel and the toast are parchment popups
-- with ink text and stay native as well.
local function DefineSkin()
    ns.RegisterModule("HuntersFieldGuide", "Hunter's Field Guide", function()
        local guide = _G.HuntersFieldGuide
        return type(guide) == "table" and type(guide.ShowExport) == "function" and _G.FieldGuideFrame ~= nil
    end, function(S, module)
        local guide = _G.HuntersFieldGuide
        local root = _G.FieldGuideFrame
        local H = ns.CreateSkinHelper(S, module)
        local fonts = setmetatable({}, {__mode = "k"})
        local done = {}
        local backing
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

        -- Font and colour of the label are left alone: the Filter button turns
        -- its label green while a filter is on.
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

        local function PaintBacking()
            if not backing or not S.GetPanelColor then return end
            local r, g, b = S.GetPanelColor()
            backing:SetColorTexture(r, g, b, 1)
        end

        -- The Forever book is a PortraitFrameTemplate with the spellbook page
        -- as a BACKGROUND texture on the window itself. S.Shell would fade that
        -- page with the rest of the window's regions, so only the template's
        -- frame art is faded here; an owned fill sits under the page and an
        -- owned, mouse-transparent border frame goes around it.
        local function SkinChrome()
            if root.NineSlice and S.FadeNineSlice then S.FadeNineSlice(root.NineSlice) end
            H.Fade(H.Texture(root.Bg))
            H.Fade(H.Texture(root.TitleBg))
            H.Fade(H.Texture(root.TopTileStreaks))
            local title = root.TitleContainer
            if type(title) == "table" then H.Fade(H.Texture(title.TitleBg)) end
            if root.CreateTexture then
                backing = root:CreateTexture(nil, "BACKGROUND", nil, -8)
                backing:SetAllPoints(root)
                PaintBacking()
            end
            if S.Panel then
                local edge = CreateFrame("Frame", nil, root)
                edge:SetAllPoints(root)
                edge:EnableMouse(false)
                S.Panel(edge, {noBg = true})
            end
            if H.Allowed(root.CloseButton) and S.CloseButton then S.CloseButton(root.CloseButton) end
            Font(root.title)
        end

        local function SkinWindow()
            if done.main or not H.Allowed(root) then return end
            done.main = true
            if guide.skinName == "forever" then SkinChrome() end
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
            PaintBacking()
            for text in pairs(fonts) do Font(text) end
        end

        local function Refresh()
            if not ns.IsEnabled(module) then return end
            if Locked() then pending = true; return end
            pending = nil
            SkinWindow()
            SkinFilter()
            SkinExport()
            if looksPending then ApplyLooks() end
        end

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
