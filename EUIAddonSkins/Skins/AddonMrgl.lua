local _, ns = ...

local function DefineSkin()
    ns.RegisterModule("AddonMrgl", "Addon Manargl", function()
        local root = _G.AddonMgrAddonList
        return root and type(root.normalInit) == "function" and type(root.categoryInit) == "function"
    end, function(S, module)
        local root = _G.AddonMgrAddonList
        local H = ns.CreateSkinHelper(S, module)
        local rows = setmetatable({}, {__mode = "k"})
        local fonts = setmetatable({}, {__mode = "k"})
        local checkboxOptions = {stockCheck = true, hover = 0.08}
        local mainReady, pending, looksPending

        local function Font(text)
            if H.Allowed(text) and S.Font then
                S.Font(text)
                fonts[text] = true
            end
        end

        local function Button(button, keep)
            if not H.Allowed(button) then return end
            if S.Button then S.Button(button, keep) end
            if button.GetFontString then Font(button:GetFontString()) end
        end

        local function SkinRow(row)
            if rows[row] or not H.Allowed(row) then return end
            if InCombatLockdown and InCombatLockdown() then pending = true; return end
            rows[row] = true
            Font(row.title)
            if row.toggleBtn then
                -- The custom category control switches between checked, mixed
                -- and empty. Keep its art and collapse icon on the native row.
                Button(row, {"icon", "highlight"})
            else
                Font(row.status)
                if H.Allowed(row.check) and S.Checkbox then S.Checkbox(row.check, checkboxOptions) end
                Button(row.loadButton)
            end
        end

        local function SkinVisibleRows()
            -- Only used on late activation and combat recovery. The native
            -- view supplies its active frames, so no retired pool is walked.
            if not root.view or not root.view.GetFrames then return end
            for _, row in ipairs(root.view:GetFrames()) do
                if row.check or row.toggleBtn then SkinRow(row) end
            end
        end

        local function ScaleControl()
            local slider = root.scaleSlider
            if H.Allowed(slider) and slider.GetThumbTexture and S.GetAccentColor then
                H.LegacySlider(slider)
            end
        end

        local function SkinWindow()
            if mainReady or not root.view or not H.Allowed(root) then return end
            if InCombatLockdown and InCombatLockdown() then pending = true; return end
            mainReady = true
            -- Register the original frame through the public facade. The
            -- engine owns its shell artwork and live theme updates.
            if S.Shell then S.Shell(root, {bottomBar = true}) end
            if H.Allowed(root.inset) and S.Inset then S.Inset(root.inset) end
            if root.NineSlice and S.FadeNineSlice then S.FadeNineSlice(root.NineSlice) end
            local title = root.TitleContainer
            if title then H.Fade(title.TitleBg) end
            Font(title and title.TitleText or root.TitleText or root.Title)
            if H.Allowed(root.closeButton) and S.CloseButton then S.CloseButton(root.closeButton) end
            local search = root.searchBox
            if H.Allowed(search) and S.EditBox then
                local icon = H.Texture(search.searchIcon or search.SearchIcon)
                local alpha = icon and icon:GetAlpha()
                S.EditBox(search, {padInput = false})
                if icon then icon:SetAlpha(alpha) end
            end
            if root.inset and H.Allowed(root.inset.scrollBar) and S.ScrollBar then
                S.ScrollBar(root.inset.scrollBar, true)
            end
            for _, key in ipairs({"enableAll", "disableAll", "okay", "cancel"}) do Button(root[key]) end
            -- Owned launchers only. LibSFDropDown menu levels and their rows
            -- are shared by every consumer and stay native.
            Button(root.filterBtn, {"Arrow"})
            Button(root.profileBtn, {"Arrow"})
            Button(root.settingsBtn, {"icon"})
            local selector = root.charSelect
            if H.Allowed(selector) then
                if root.isMainline then
                    Button(selector, {"Arrow", "Icon"})
                elseif H.Allowed(selector.Button) and S.Button then
                    -- The classic selector opens through its nested arrow button.
                    -- Keep that native arrow/hitbox and give the owner a flat plate.
                    S.Button(selector, {"Icon"})
                end
                Font(selector.Text)
            end
            for _, key in ipairs({"currentCPU", "averageCPU", "peakCPU", "encounterCPU"}) do
                local control = root[key]
                if H.Allowed(control) then
                    Font(control.topStr)
                    Font(control.bottomStr)
                end
            end
            ScaleControl()
        end

        local function ApplyLooks()
            if not mainReady then return end
            if InCombatLockdown and InCombatLockdown() then looksPending = true; return end
            looksPending = nil
            for text in pairs(fonts) do Font(text) end
            ScaleControl()
        end

        local function Refresh()
            if not ns.IsEnabled(module) or not root:IsShown() then return end
            if InCombatLockdown and InCombatLockdown() then pending = true; return end
            pending = nil
            SkinWindow()
            SkinVisibleRows()
            if looksPending then ApplyLooks() end
        end

        -- Parent rows call normalInit themselves. Both hooks observe completed
        -- native layout only and bail immediately for a previously seen slot.
        local function RowReady(_, row)
            if not rows[row] then SkinRow(row) end
        end
        H.Hook(root, "normalInit", RowReady)
        H.Hook(root, "categoryInit", RowReady)
        local function WindowReady()
            if not mainReady or pending or looksPending then Refresh() end
        end
        H.Script(root, "OnShow", WindowReady)
        -- Manargl replaces its startup OnShow with this method. Retain a
        -- completion signal even on clients that replace earlier script hooks.
        H.Hook(root, "onShow", WindowReady)
        if S.OnLooksChanged then
            S.OnLooksChanged(function()
                if not ns.IsEnabled(module) or not mainReady then return end
                if root:IsShown() then ApplyLooks() else looksPending = true end
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

ns.RegisterSkinDefinition("AddonMrgl", DefineSkin)
