local ADDON, ns = ...
local function DefineSkin()
local context, looksBound
local fonts = setmetatable({}, {__mode = 'k'})
local menuOptions = {noAccent = true, chevrons = true, hoverAlpha = 0.25}
local headingKeys = {'Kiwi Farm [/kfarm]', 'Statistics', 'Settings'}
local headingLabels = {}
local function StatsFont(S, text)
    if not text or not text.GetFont or not text.SetFont then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local path, size, flags = text:GetFont()
    if not path then return end
    local target = S.GetFont()
    local state = fonts[text]
    if not state then state = {}; fonts[text] = state end
    if path ~= target or (flags or '') ~= '' then state.native = {path, size, flags} end
    if context and not ns.IsEnabled(context.module) then
        if state.native then
            state.busy = true; text:SetFont((unpack or table.unpack)(state.native)); state.busy = false
        end
        return
    end
    if path ~= target or (flags or '') ~= '' then
        state.busy = true; text:SetFont(target, size, ''); state.busy = false
    end
end
menuOptions.isHeading = function(button, text)
    if button.isTitle then return true end
    if not text or not text.GetText then return false end
    return headingLabels[text:GetText()] == true
end
local defaults = {backgroundOpacity = 0.9, menuOpacity = 0.95, backgroundStyle = 'soft', accent = false}
local layer, base, left, right, accentLine, menuSkin
local visualExclude = setmetatable({}, {__index = function(_, frame) return frame == layer end})
local nativeOpacity, painting, pending, nativeCaptured = 1, false, false, false
local menuFills = setmetatable({}, {__mode = "k"})
local function Value(key)
    local saved = EUIAddonSkinsDB and EUIAddonSkinsDB.kiwiFarm
    local value
    if type(saved) == 'table' then value = saved[key] end
    if value == nil then return defaults[key] end
    if key == 'backgroundOpacity' and value == 'native' then return value end
    if key == 'backgroundOpacity' or key == 'menuOpacity' then
        if type(value) ~= 'number' or value ~= value then return defaults[key] end
        return math.max(0, math.min(1, value))
    end
    if key == 'backgroundStyle' then return value == 'flat' and 'flat' or 'soft' end
    return value == true
end
local function Gradient(texture, first, last)
    texture:SetColorTexture(1, 1, 1, 1)
    if texture.SetGradient and CreateColor then
        texture:SetGradient('HORIZONTAL', CreateColor(0.19, 0.19, 0.20, first), CreateColor(0.19, 0.19, 0.20, last))
    elseif texture.SetGradientAlpha then texture:SetGradientAlpha('HORIZONTAL', 0.19, 0.19, 0.20, first, 0.19, 0.19, 0.20, last)
    else texture:SetColorTexture(0.12, 0.12, 0.13, (first + last) / 2) end
end
local function PaintBackground()
    if not context or not layer or painting then return end
    if InCombatLockdown and InCombatLockdown() then pending = true; return end
    pending = false
    if not ns.IsEnabled(context.module) then layer:SetAlpha(0); accentLine:SetAlpha(0); return end
    painting = true
    local opacity = Value('backgroundOpacity')
    if opacity == 'native' then opacity = nativeOpacity end
    layer:SetAlpha(opacity)
    base:SetColorTexture(0.055, 0.055, 0.06, 1)
    local wash = Value('backgroundStyle') == 'soft' and 0.48 or 0
    Gradient(left, 0, wash); Gradient(right, wash, 0)
    local r, g, b
    if ns.AccentBarColor then r, g, b = ns.AccentBarColor(context.S) else r, g, b = context.S.GetAccentColor() end
    accentLine:SetColorTexture(r, g, b, 1)
    accentLine:SetAlpha(Value('accent') and (not ns.AccentBarShown or ns.AccentBarShown()) and 1 or 0)
    painting = false
end
local function RefreshOpenMenu()
    local owner = UIDROPDOWNMENU_OPEN_MENU
    local level = UIDROPDOWNMENU_MENU_LEVEL
    if not context or not context.H.Allowed(owner) or not owner.GetName or owner:GetName() ~= 'KiwiFarmPopupMenu'
        or type(level) ~= 'number' or type(ToggleDropDownMenu) ~= 'function' then return end
    local list = _G['DropDownList' .. level]
    if not list or not list.IsShown or not list:IsShown() or not list.GetPoint then return end
    local _, anchor = list:GetPoint(1)
    if anchor and type(anchor.menuList) == 'table' then
        if CloseDropDownMenus then CloseDropDownMenus(level + 1) end
        ToggleDropDownMenu(level, owner.menuValues and owner.menuValues[level], nil, nil, nil, nil, anchor.menuList, anchor)
    end
end
local function ApplySettings(refreshMenu)
    if InCombatLockdown and InCombatLockdown() then pending = true; return end
    PaintBackground()
    if context and ns.IsEnabled(context.module) then
        for _, fill in pairs(menuFills) do fill:SetColorTexture(0.065, 0.065, 0.07, Value('menuOpacity')) end
    end
    if refreshMenu and not (InCombatLockdown and InCombatLockdown()) then RefreshOpenMenu() end
    if ns.RefreshPopupMenusNow then ns.RefreshPopupMenusNow() end
end
local function Set(key, value)
    if not context or not ns.IsEnabled(context.module) then return end
    EUIAddonSkinsDB = EUIAddonSkinsDB or {}
    if type(EUIAddonSkinsDB.kiwiFarm) ~= 'table' then EUIAddonSkinsDB.kiwiFarm = {} end
    EUIAddonSkinsDB.kiwiFarm[key] = value
    ApplySettings(true)
end
local function Background(C)
    local f = _G.KiwiFarm
    if not C.H.Allowed(f) or InCombatLockdown and InCombatLockdown() then pending = true; return end
    if not layer then
        layer = CreateFrame('Frame', nil, f)
        layer:SetAllPoints(f); layer:EnableMouse(false)
        layer:SetFrameLevel(f:GetFrameLevel())
        base = layer:CreateTexture(nil, 'BACKGROUND', nil, 1); base:SetAllPoints(layer)
        left = layer:CreateTexture(nil, 'BACKGROUND', nil, 2)
        left:SetPoint('TOPLEFT', layer, 'TOPLEFT'); left:SetPoint('BOTTOMRIGHT', layer, 'BOTTOM')
        right = layer:CreateTexture(nil, 'BACKGROUND', nil, 2)
        right:SetPoint('TOPLEFT', layer, 'TOP'); right:SetPoint('BOTTOMRIGHT', layer, 'BOTTOMRIGHT')
        accentLine = f:CreateTexture(nil, 'OVERLAY', nil, 7)
        accentLine:SetPoint('TOPLEFT', f, 'TOPLEFT', 1, -1); accentLine:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -1, -1); accentLine:SetHeight(2)
        C.H.Hook(f, 'SetBackdropColor', function(_, _, _, _, alpha)
            if type(alpha) == 'number' then nativeOpacity = math.max(0, math.min(1, alpha)) end
            PaintBackground()
        end)
        local events = CreateFrame('Frame')
        events:RegisterEvent('PLAYER_REGEN_ENABLED')
        events:SetScript('OnEvent', function() if pending then ApplySettings() end end)
    end
    -- Shell backgrounds are owned root textures; keep them transparent so the
    -- independent background opacity never dims text or exposes a second fill.
    for _, texture in ipairs({f:GetRegions()}) do
        if C.H.Texture(texture) and texture.GetDrawLayer then
            local draw = texture:GetDrawLayer()
            if draw == 'BACKGROUND' or draw == 'BORDER' then C.H.Fade(texture) end
        end
    end
    PaintBackground()
end
local settingsEntry
local function InjectMenu(owner, _, _, _, menu)
    if not context or not ns.IsEnabled(context.module) or not context.H.Allowed(owner)
        or not owner.GetName or owner:GetName() ~= 'KiwiFarmPopupMenu' or type(menu) ~= 'table' then return end
    local locale = LibStub and LibStub('AceLocale-3.0', true)
    local labels = locale and locale.GetLocale and locale:GetLocale('KiwiFarm', true)
    local appearance = labels and labels.Appearance or 'Appearance'
    for _, entry in ipairs(menu) do
        if entry.text == appearance and type(entry.menuList) == 'table' then
            for _, item in ipairs(entry.menuList) do if item == settingsEntry then return end end
            if not settingsEntry then
                local function Disabled() return not ns.IsEnabled(context.module) end
                local function Choice(text, key, value)
                    return {text = text, checked = function() return Value(key) == value end,
                        keepShownOnClick = true, disabled = Disabled, func = function() Set(key, value) end}
                end
                local function Opacity(text, key)
                    local choices = {}
                    if key == 'backgroundOpacity' then choices[#choices + 1] = Choice('Use KiwiFarm opacity', key, 'native') end
                    for percent = 0, 100, 10 do choices[#choices + 1] = Choice(percent .. '%', key, percent / 100) end
                    if key == 'menuOpacity' then choices[#choices + 1] = Choice('95% (default)', key, 0.95) end
                    return {text = text, notCheckable = true, hasArrow = true, menuList = choices, disabled = Disabled}
                end
                settingsEntry = {text = 'AddonSkins', notCheckable = true, hasArrow = true, hidden = Disabled, menuList = {
                    Opacity('Background opacity', 'backgroundOpacity'), Opacity('Menu background opacity', 'menuOpacity'),
                    {text = 'Background style', notCheckable = true, hasArrow = true, menuList = {
                        Choice('Flat charcoal', 'backgroundStyle', 'flat'), Choice('Soft centre highlight', 'backgroundStyle', 'soft')}},
                    {text = 'Show accent line', isNotRadio = true, keepShownOnClick = true, checked = function() return Value('accent') end,
                        disabled = Disabled, func = function() Set('accent', not Value('accent')) end},
                    {text = 'Reset skin settings', notCheckable = true, disabled = Disabled, func = function()
                        if Disabled() then return end
                        if EUIAddonSkinsDB then EUIAddonSkinsDB.kiwiFarm = nil end
                        ApplySettings(true)
                    end},
                }}
            end
            entry.menuList[#entry.menuList + 1] = settingsEntry
            return
        end
    end
end
ns.RegisterScopedSkin("KiwiFarm", "KiwiFarm", {
    softBorders = true,
    available = function() return _G.KiwiFarm ~= nil end,
    panels = false,
    roots = function()
        local roots = ns.SkinRoots({"KiwiFarm"}, {noTopBar = true, noAccent = true})
        for _, root in ipairs(roots) do root.exclude = visualExclude end
        return roots
    end,
    visit = function(C, f) if f == _G.KiwiFarm then Background(C) end end,
    font = StatsFont,
    hooks = function(C)
        context = C
        if not nativeCaptured and _G.KiwiFarm.GetBackdropColor then
            local _, _, _, alpha = _G.KiwiFarm:GetBackdropColor()
            if type(alpha) == 'number' then nativeOpacity = math.max(0, math.min(1, alpha)); nativeCaptured = true end
        end
        if not menuSkin then
            menuSkin = setmetatable({GetPanelColor = function() return 0.065, 0.065, 0.07, Value('menuOpacity') end}, {__index = C.S})
            menuSkin.Shell = function(frame, options)
                C.S.Shell(frame, options)
                -- Legacy menus use Shell rather than GetPanelColor. Replace
                -- only this owned layer's backdrop, never native menu rows.
                for _, texture in ipairs({frame:GetRegions()}) do
                    if C.H.Texture(texture) and texture.GetDrawLayer then
                        local draw = texture:GetDrawLayer()
                        if draw == 'BACKGROUND' or draw == 'BORDER' then C.H.Fade(texture) end
                    end
                end
                local fill = frame:CreateTexture(nil, 'BACKGROUND', nil, -6)
                fill:SetAllPoints(frame); fill:SetColorTexture(0.065, 0.065, 0.07, Value('menuOpacity'))
                menuFills[frame] = fill
            end
        end
        C.H.Hook(_G, 'UIDropDownMenu_Initialize', InjectMenu)
        local locale = LibStub and LibStub('AceLocale-3.0', true)
        local labels = locale and locale.GetLocale and locale:GetLocale('KiwiFarm', true)
        for _, key in ipairs(headingKeys) do headingLabels[labels and labels[key] or key] = true end
        local function Bind(owner)
            if ns.BindPopupOwner then ns.BindPopupOwner(menuSkin, C.module, owner, menuOptions)
            else C.MenuOwner(owner) end
        end
        local function MenuReady()
            Bind(_G.KiwiFarmPopupMenu)
            -- KiwiFarm can create a launcher on each open. Prefer the actual
            -- renderer owner if its named global still refers to another one.
            local list = _G.DropDownList1
            local owner = list and list.dropdown
            if list and list.IsShown and list:IsShown() and C.H.Allowed(owner)
                and owner.GetName and owner:GetName() == "KiwiFarmPopupMenu" then
                Bind(owner)
            end
            -- Registration only repaints changed bindings. Reopening an
            -- unchanged owner still needs a completed native-render pass.
            if ns.RefreshPopupMenusNow then ns.RefreshPopupMenusNow() end
        end
        Bind(_G.KiwiFarmPopupMenu)
        C.H.Hook(_G.KiwiFarm, "ShowMenu", MenuReady)
        -- Native LayoutFrame reapplies its outlined fonts. Repair only these
        -- two labels after SetFont; never scan on SetText or the stats timer.
        for _, text in ipairs({_G.KiwiFarm:GetRegions()}) do
            if text.GetObjectType and text:GetObjectType() == 'FontString' then
                StatsFont(C.S, text)
                C.H.Hook(text, 'SetFont', function()
                    local state = fonts[text]
                    if not state or not state.busy then StatsFont(C.S, text) end
                end)
            end
        end
        if not looksBound and C.S.OnLooksChanged then
            looksBound = true
            C.S.OnLooksChanged(function() for text in pairs(fonts) do StatsFont(C.S, text) end; ApplySettings() end)
        end
        -- Shared popup combat recovery handles the menu itself. No guide/main
        -- frame discovery is needed for menu opens or combat-end callbacks.
    end,
    -- KiwiFarm's native whole-frame alpha/visibility still controls the frame.
    -- Shared Blizzard StaticPopup frames retain their existing styling.
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("KiwiFarm", DefineSkin)
else DefineSkin() end
