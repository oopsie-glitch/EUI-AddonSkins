local ADDON, ns = ...
local owners = setmetatable({}, {__mode = "k"})
local records = setmetatable({}, {__mode = "k"})
local hooks, lookHooks, queued = {}, {}, false
local unpack = unpack or table.unpack
local extraLists = setmetatable({}, {__mode = "k"})
local applying = false
local menuFonts, fontSerial = {}, 0
local modernInitializers = setmetatable({}, {__mode = "k"})

local function Allowed(f)
    return f and f.GetObjectType and not (f.IsForbidden and f:IsForbidden())
        and not (f.IsProtected and f:IsProtected())
end
local function Enabled(binding)
    return binding and ns.IsEnabled(binding.module)
end
local function SetMenuFontObject(text, font)
    if text.GetTextColor and text.SetTextColor then
        local red, green, blue, alpha = text:GetTextColor()
        text:SetFontObject(font)
        text:SetTextColor(red, green, blue, alpha)
    else text:SetFontObject(font) end
end
local function Restore(f)
    local r = records[f]
    if not r or not r.active then return end
    -- A released modern menu may already have recycled its regions. Never
    -- restore an old acquisition's references into the next menu's controls.
    if r.modern and f.euiAddonSkinsMenuFill ~= r.fill then
        r.active = false; r.alpha, r.fonts, r.colors, r.objectFonts = {}, {}, {}, {}
        return
    end
    for text, data in pairs(r.objectFonts or {}) do
        if data.original and text:GetFontObject() == data.applied then SetMenuFontObject(text, data.original) end
    end
    for object, value in pairs(r.alpha) do
        if object:GetAlpha() == 0 then object:SetAlpha(value) end
    end
    for text, value in pairs(r.fonts) do
        local font, size, flags = text:GetFont()
        local applied = r.appliedFonts[text]
        if applied and font == applied[1] and size == applied[2] and (flags or "") == applied[3] then
            text:SetFont(unpack(value))
        end
    end
    for texture, value in pairs(r.colors) do
        local current = {texture:GetVertexColor()}
        local applied = r.appliedColors[texture]
        local same = applied ~= nil
        for i = 1, 4 do if current[i] ~= applied[i] then same = false end end
        if same then texture:SetVertexColor(unpack(value)) end
    end
    for text, value in pairs(r.textColors or {}) do
        local current, applied = {text:GetTextColor()}, r.appliedTextColors[text]
        if applied and current[1] == applied[1] and current[2] == applied[2]
            and current[3] == applied[3] and current[4] == applied[4] then text:SetTextColor(unpack(value)) end
    end
    if r.layer then r.layer:SetAlpha(0) end
    if r.fill then r.fill:SetAlpha(0) end
    if r.accent then r.accent:SetAlpha(0) end
    for _, marker in pairs(r.markers or {}) do marker:SetAlpha(0) end
    for _, arrow in pairs(r.arrows or {}) do arrow:SetAlpha(0) end
    r.active = false
end
local function Hook(object, method, callback)
    if not object or type(object[method]) ~= "function" then return end
    local entry = hooks[object]
    if not entry then entry = {}; hooks[object] = entry end
    if entry[method] == object[method] then return end
    hooksecurefunc(object, method, callback)
    entry[method] = object[method]
end
local function Font(r, text, S)
    if not text or not text.GetFont or not text.SetFont then return end
    if not r.fonts[text] then r.fonts[text] = {text:GetFont()} end
    local current, size, currentFlags = text:GetFont()
    local path, flags = S.GetFont()
    flags = flags or ""
    if current ~= path or (currentFlags or "") ~= flags then text:SetFont(path, size or 12, flags) end
    r.appliedFonts[text] = {path, size or 12, flags}
end
local function Fade(r, object)
    if not object or not object.GetAlpha or not object.SetAlpha then return end
    if r.alpha[object] == nil then r.alpha[object] = object:GetAlpha() end
    if object:GetAlpha() ~= 0 then object:SetAlpha(0) end
end
local function Tint(r, texture, red, green, blue, alpha)
    if not texture or not texture.GetVertexColor or not texture.SetVertexColor then return end
    if not r.colors[texture] then r.colors[texture] = {texture:GetVertexColor()} end
    texture:SetVertexColor(red, green, blue, alpha)
    r.appliedColors[texture] = {red, green, blue, alpha}
end
local function Marker(r, button, native, checked, S)
    if not native or not native.IsShown or not button.CreateTexture then return end
    r.markers = r.markers or {}
    local marker = r.markers[native]
    if not marker then
        marker = button:CreateTexture(nil, "OVERLAY")
        marker:SetSize(8, 8); marker:SetPoint("CENTER", native, "CENTER")
        r.markers[native] = marker
    end
    local red, green, blue = S.GetAccentColor()
    marker:SetColorTexture(checked and red or 0.3, checked and green or 0.3, checked and blue or 0.3, 1)
    marker:SetAlpha(native:IsShown() and 1 or 0)
    Fade(r, native)
end
local function HeadingColor(r, text, heading, S)
    if not text or not text.GetTextColor or not text.SetTextColor then return end
    r.textColors, r.appliedTextColors = r.textColors or {}, r.appliedTextColors or {}
    if heading then
        if not r.textColors[text] then r.textColors[text] = {text:GetTextColor()} end
        local red, green, blue = S.GetAccentColor()
        text:SetTextColor(red, green, blue, 1)
        r.appliedTextColors[text] = {red, green, blue, 1}
    elseif r.textColors[text] then
        local a, b, c, d = text:GetTextColor()
        local applied = r.appliedTextColors[text]
        if applied and a == applied[1] and b == applied[2] and c == applied[3] and d == applied[4] then
            text:SetTextColor(unpack(r.textColors[text]))
        end
        r.textColors[text], r.appliedTextColors[text] = nil, nil
    end
end
local function Chevron(r, button, native)
    if not native or not native.IsShown or not button.CreateTexture then return end
    r.arrows = r.arrows or {}
    local arrow = r.arrows[native]
    if not arrow then
        arrow = button:CreateTexture(nil, 'OVERLAY')
        arrow:SetTexture('Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-arrow-right.png')
        arrow:SetSize(10, 10); arrow:SetPoint('CENTER', native, 'CENTER')
        arrow:SetVertexColor(0.75, 0.75, 0.78, 1)
        r.arrows[native] = arrow
    end
    arrow:SetAlpha(native:IsShown() and 1 or 0); Fade(r, native)
end
local function ModernFont(r, text, S)
    -- Compositor FontStrings forbid even indexing SetFont. Apply a standalone
    -- FontObject through the supported API instead, retaining the native size.
    if not text or not text.GetFont or not text.GetFontObject or not text.SetFontObject or not CreateFont then return end
    local _, size = text:GetFont()
    local path, flags = S.GetFont(); size, flags = size or 12, flags or ""
    if issecretvalue and issecretvalue(size) then return end
    local key = path .. "\031" .. tostring(size) .. "\031" .. flags
    local font = menuFonts[key]
    if not font then
        fontSerial = fontSerial + 1
        font = CreateFont("EUIAddonSkinsPopupFont" .. fontSerial)
        font:SetFont(path, size, flags); menuFonts[key] = font
    end
    local old = r.objectFonts[text]
    local currentFont = text:GetFontObject()
    if not old then old = {}; r.objectFonts[text] = old end
    if currentFont ~= old.applied then old.original = currentFont end
    old.applied = font
    if currentFont ~= font then SetMenuFontObject(text, font) end
end
local function ModernRow(r, button, S)
    if not Allowed(button) or button:GetObjectType() ~= "Button" then return end
    ModernFont(r, button.GetFontString and button:GetFontString(), S)
    for _, region in ipairs({button:GetRegions()}) do
        if region.GetObjectType and region:GetObjectType() == "FontString" then ModernFont(r, region, S) end
    end
end
local function ModernStyle(f, binding, owner)
    if not f.AttachTexture then Restore(f); return end
    local fill = f.euiAddonSkinsMenuFill
    local r = records[f]
    if r and r.active and (r.binding ~= binding or r.owner ~= owner) then Restore(f) end
    if not fill then
        -- These regions belong to Blizzard's compositor and are recycled with
        -- the menu. An unmanaged child frame can cover reused menu entries.
        fill = f:AttachTexture(); fill:SetDrawLayer("BACKGROUND", -8); fill:SetAllPoints()
        f.euiAddonSkinsMenuFill = fill
        local accent = f:AttachTexture(); accent:SetDrawLayer("OVERLAY", 7)
        accent:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1); accent:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1); accent:SetHeight(2)
        f.euiAddonSkinsMenuAccent = accent
        f:HookScript("OnHide", function() Restore(f) end)
    end
    if not r or not r.active or r.fill ~= fill then
        r = {modern = true, active = true, binding = binding, owner = owner, fill = fill,
            accent = f.euiAddonSkinsMenuAccent, alpha = {}, fonts = {}, colors = {},
            objectFonts = {}, appliedFonts = {}, appliedColors = {}}
        records[f] = r
    end
    local S = binding.S
    fill:SetColorTexture(S.GetPanelColor()); fill:SetAlpha(1)
    local red, green, blue
    if ns.AccentBarColor then red, green, blue = ns.AccentBarColor(S) else red, green, blue = S.GetAccentColor() end
    r.accent:SetColorTexture(red, green, blue, 1)
    r.accent:SetAlpha(not (binding.options and binding.options.noAccent)
        and (not ns.AccentBarShown or ns.AccentBarShown()) and 1 or 0)
    Fade(r, f.Backdrop); Fade(r, f.MenuBackdrop); Fade(r, f.NineSlice)
    for _, region in ipairs({f:GetRegions()}) do
        if region ~= fill and region ~= r.accent and region.GetDrawLayer then
            local layer = region:GetDrawLayer()
            if layer == "BACKGROUND" or layer == "BORDER" then Fade(r, region) end
        end
    end
    for _, button in ipairs({f:GetChildren()}) do
        ModernRow(r, button, S)
    end
    if f.EnumerateElementDescriptions then
        f:EnumerateElementDescriptions(function(_, description)
            if not description.AddInitializer then return end
            local context = modernInitializers[description]
            if not context then
                context = {}; modernInitializers[description] = context
                -- Checkbox responses clear and reinitialize compositor rows.
                -- Append after the native initializer; do not hook pooled row
                -- scripts or setters that the compositor discards on refresh.
                description:AddInitializer(function(button, _, menu)
                    local list = context.list
                    if menu and menu ~= list then return end
                    local current = list and records[list]
                    if not current or not current.modern or not current.active or not Enabled(current.binding)
                        or list:GetOwnerRegion() ~= current.owner
                        or list.euiAddonSkinsMenuFill ~= current.fill
                        or (InCombatLockdown and InCombatLockdown()) then return end
                    ModernRow(current, button, current.binding.S)
                end)
            end
            context.list = f
        end)
    end
end
local function Style(f, binding, owner)
    if not Allowed(f) or not Enabled(binding) then Restore(f); return end
    if InCombatLockdown and InCombatLockdown() then return end
    if f.GetOwnerRegion then return ModernStyle(f, binding, owner or f:GetOwnerRegion()) end
    local r = records[f]
    if not r then
        r = {layers = {}, rowHooks = {}}; records[f] = r
        f:HookScript("OnHide", function() Restore(f); ns.RefreshPopupMenus() end)
        f:HookScript("OnShow", function() ns.RefreshPopupMenusNow() end)
    end
    owner = owner or f.dropdown
    if r.active and (r.binding ~= binding or r.owner ~= owner) then Restore(f) end
    if not r.active then
        r.alpha, r.fonts, r.colors = {}, {}, {}
        r.appliedFonts, r.appliedColors = {}, {}
        r.textColors, r.appliedTextColors = {}, {}
        r.binding, r.owner, r.active = binding, owner, true
    end
    local S = binding.S
    local layer = r.layers[binding.module]
    if not layer then
        -- Style only our visual child. Never register the pooled native menu or
        -- its rows with EUI's persistent skin registry.
        layer = CreateFrame("Frame", nil, f)
        layer:SetAllPoints(f)
        layer:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
        layer:EnableMouse(false)
        S.Shell(layer, {noTopBar = true})
        if not (binding.options and binding.options.noAccent) then ns.AttachAccent(S, layer) end
        layer:SetAlpha(0)
        r.layers[binding.module] = layer
    end
    r.layer = layer
    layer:SetAlpha(1)
    local name = f.GetName and f:GetName() or ""
    Fade(r, f.Backdrop or _G[name .. "Backdrop"])
    Fade(r, f.MenuBackdrop or _G[name .. "MenuBackdrop"])
    if f.GetOwnerRegion then Fade(r, f.NineSlice) end
    -- Older dropdown implementations draw their border directly on the list.
    for _, region in ipairs({f:GetRegions()}) do
        if region.GetObjectType and region:GetObjectType() == "Texture" and region.GetDrawLayer then
            local drawLayer = region:GetDrawLayer()
            if drawLayer == "BACKGROUND" or drawLayer == "BORDER" then Fade(r, region) end
        end
    end
    for _, button in ipairs({f:GetChildren()}) do
        if Allowed(button) and button:GetObjectType() == "Button" then
            local text = button.GetFontString and button:GetFontString()
            Font(r, text, S)
            if binding.options and binding.options.isHeading then
                HeadingColor(r, text, binding.options.isHeading(button, text), S)
            end
            for _, region in ipairs({button:GetRegions()}) do
                if region.GetObjectType and region:GetObjectType() == "FontString" then Font(r, region, S) end
            end
            local arrow = button.ExpandArrow or _G[(button.GetName and button:GetName() or "") .. "ExpandArrow"]
            if arrow and arrow.GetNormalTexture then arrow = arrow:GetNormalTexture() end
            local red, green, blue = S.GetAccentColor()
            if binding.options and binding.options.chevrons then Chevron(r, button, arrow)
            else Tint(r, arrow, red, green, blue, 1) end
            local highlight = button.Highlight or (button.GetHighlightTexture and button:GetHighlightTexture())
            Tint(r, highlight, 1, 1, 1, 0.1)
            local check, uncheck = button.Check, button.UnCheck
            if binding.options and binding.options.chevrons then
                local buttonName = button.GetName and button:GetName()
                check = check or buttonName and _G[buttonName .. 'Check']
                uncheck = uncheck or buttonName and _G[buttonName .. 'UnCheck']
            end
            Marker(r, button, check, true, S)
            Marker(r, button, uncheck, false, S)
            if not r.rowHooks[button] and button.HookScript then
                r.rowHooks[button] = true
                button:HookScript("OnClick", ns.RefreshPopupMenusNow)
            end
            -- Checkmarks, disabled/title colors, embedded emotes and row actions
            -- retain their native state. No labels, anchors or handlers change.
        end
    end
end
local function Apply()
    if InCombatLockdown and InCombatLockdown() then return end
    for f, expected in pairs(extraLists) do
        local owner = f.GetOwnerRegion and f:GetOwnerRegion() or f.dropdown
        if f.IsShown and f:IsShown() and owner == expected then Style(f, owners[owner], owner) else Restore(f) end
    end
    for _, prefix in ipairs({"DropDownList", "L_DropDownList", "L_DropDownListQuestie"}) do
        local root = _G[prefix .. "1"]
        local owner = root and root.dropdown
        local binding = owner and root.IsShown and root:IsShown() and owners[owner]
        -- The root menu owns the entire submenu chain, even when submenu
        -- dropdown fields refer to a row instead of the original launcher.
        for level = 1, 8 do
            local f = _G[prefix .. level]
            if f then
                if f.IsShown and f:IsShown() and Enabled(binding) then Style(f, binding)
                else Restore(f) end
            end
        end
    end
end
-- Render-completion hooks must paint in this frame, before the next screen draw.
function ns.RefreshPopupMenusNow()
    if applying then return end
    applying = true
    local ok, err = pcall(Apply)
    applying = false
    if not ok then geterrorhandler()(ADDON .. " / popup menus: " .. tostring(err)) end
end
function ns.BindPopupList(S, module, owner, list)
    if not Allowed(list) then return end
    ns.BindPopupOwner(S, module, owner)
    extraLists[list] = owner
    Hook(list, "Toggle", ns.RefreshPopupMenusNow)
    ns.RefreshPopupMenusNow()
end
function ns.RefreshPopupMenus()
    if queued then return end
    queued = true
    C_Timer.After(0, function()
        queued = false
        local ok, err = pcall(Apply)
        if not ok then geterrorhandler()(ADDON .. " / popup menus: " .. tostring(err)) end
    end)
end
function ns.BindPopupOwner(S, module, owner, options)
    if not owner then return end
    local binding = owners[owner]
    local changed = not binding or binding.module ~= module or binding.S ~= S or binding.options ~= options
    if changed then
        binding = {S = S, module = module, options = options}; owners[owner] = binding
    end
    if not lookHooks[module] and S.OnLooksChanged then
        lookHooks[module] = true
        S.OnLooksChanged(ns.RefreshPopupMenus)
    end
    if changed then ns.RefreshPopupMenusNow() end
end
-- Observe shared renderer completion, with all mutation gated by known owner.
local function InstallHooks()
    Hook(_G, "ToggleDropDownMenu", ns.RefreshPopupMenusNow)
    Hook(_G, "UIDropDownMenu_AddButton", ns.RefreshPopupMenusNow)
    if LibStub then
        for _, name in ipairs({"LibUIDropDownMenu-4.0", "LibUIDropDownMenuQuestie-4.0"}) do
            local lib = LibStub(name, true)
            if lib then
                Hook(lib, "ToggleDropDownMenu", ns.RefreshPopupMenusNow)
                Hook(lib, "UIDropDownMenu_AddButton", ns.RefreshPopupMenusNow)
            end
        end
    end
end
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function() InstallHooks(); ns.RefreshPopupMenus() end)
InstallHooks()
