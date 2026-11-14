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
        local menuStyleRegistered
        local menuStyle = "EUIAddonSkins_AddonMrgl"

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
            if not H.Allowed(slider) or not slider.GetThumbTexture then return end
            local thumb = H.Texture(slider:GetThumbTexture())
            local left, middle, right = H.Texture(slider.Left), H.Texture(slider.Middle), H.Texture(slider.Right)
            if not (thumb and left and middle and right and slider.CreateTexture) then return end
            H.Fade(left)
            H.Fade(middle)
            H.Fade(right)
            local track = slider:CreateTexture(nil, "BACKGROUND")
            track:SetPoint("LEFT")
            track:SetPoint("RIGHT")
            track:SetHeight(2)
            track:SetColorTexture(0.2, 0.2, 0.22, 1)

            -- Like HomeBound's scale grip, follow the native thumb without
            -- changing the slider's travel, input scripts, or hit area.
            local edge = slider:CreateTexture(nil, "OVERLAY")
            edge:SetSize(8, 14)
            edge:SetPoint("CENTER", thumb, "CENTER")
            edge:SetColorTexture(0.31, 0.28, 0.23, 1)
            local grip = slider:CreateTexture(nil, "OVERLAY", nil, 1)
            grip:SetPoint("TOPLEFT", edge, "TOPLEFT", 1, -1)
            grip:SetPoint("BOTTOMRIGHT", edge, "BOTTOMRIGHT", -1, 1)
            grip:SetColorTexture(0.11, 0.105, 0.10, 1)
            H.Fade(thumb)
        end

        local function SkinMenus()
            if not S.Panel or not LibStub then return end
            local library = LibStub("LibSFDropDown-1.5", true)
            if not library or not library.CreateMenuStyle then return end
            if not menuStyleRegistered then
                -- The library owns popup reuse and switches style children
                -- from the opening launcher's display mode at every depth.
                menuStyleRegistered = library:CreateMenuStyle(menuStyle, function(menu)
                    local surface = CreateFrame("Frame", nil, menu)
                    surface:EnableMouse(false)
                    S.Panel(surface, {inset = true})
                    return surface
                end)
                if not menuStyleRegistered then return end
            end
            for _, key in ipairs({"filterBtn", "profileBtn", "charSelect"}) do
                local launcher = root[key]
                if H.Allowed(launcher) and launcher:GetParent() == root and launcher.ddSetDisplayMode then
                    launcher:ddSetDisplayMode(menuStyle)
                end
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
            -- Shared menu rows retain their native interaction and state art.
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
            SkinMenus()
        end

        local function ApplyLooks()
            if not mainReady then return end
            if InCombatLockdown and InCombatLockdown() then looksPending = true; return end
            looksPending = nil
            for text in pairs(fonts) do Font(text) end
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
