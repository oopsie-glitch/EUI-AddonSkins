local _, ns = ...

-- Providers are metadata plus existing preference handlers. Registration
-- does not load targets, initialize saved values, or create controls.
local providers = {}
local ui, category, requested
local Refresh
function ns.RegisterSettingsProvider(id, provider)
    assert(type(id) == "string" and not providers[id], "Duplicate settings provider: " .. tostring(id))
    assert(type(provider.label) == "string" and type(provider.options) == "table", "Invalid settings provider")
    providers[id] = provider
    if ui and ui.open then Refresh() end
end

local function Combat()
    return InCombatLockdown and InCombatLockdown()
end

local function TargetAvailable(entry)
    local info = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo
    local loaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    if not (entry and info and loaded) then return false end
    for _, target in ipairs(entry.targets) do
        if loaded(target) then
            local ok, name = pcall(info, target)
            if ok and name then return ns.TargetEnabled(entry) end
        end
    end
    return false
end

local function ActiveModule(id)
    local provider = providers[id]
    if not provider or #provider.options == 0 or not ns.IsEnabled() then return end
    local entry = ns.skinCatalogByID and ns.skinCatalogByID[id]
    if not entry or entry.failed or entry.skin and not ns.IsEnabled(entry) then return end
    for _, module in ipairs(ns.modules) do
        if module.id == id and module.active and ns.IsEnabled(module)
            and (not provider.ready or provider.ready(module)) and TargetAvailable(entry) then
            return module
        end
    end
end

-- Core calls this after successful activation, including deferred loads.
function ns.SettingsAvailabilityChanged(id)
    if ui and ui.open and (not id or providers[id]) then Refresh() end
end

local function Text(parent, template)
    local label = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlight")
    label:SetJustifyH("LEFT")
    return label
end

local function Fill(parent, r, g, b, a)
    local texture = parent:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(parent)
    texture:SetColorTexture(r, g, b, a)
    return texture
end

local function Button(parent)
    local button = CreateFrame("Button", nil, parent)
    button.fill = Fill(button, 0.10, 0.11, 0.12, 0.95)
    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(button); hover:SetColorTexture(1, 1, 1, 0.075)
    button:SetHighlightTexture(hover)
    button.label = Text(button)
    button.label:SetPoint("LEFT", button, "LEFT", 8, 0)
    button.label:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    button.label:SetWordWrap(false)
    return button
end

local function Scroll(parent, name)
    local scroll = CreateFrame("ScrollFrame", name, parent, "UIPanelScrollFrameTemplate")
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    return scroll, content
end

local function Place(frame, parent, x, y, width, height)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    frame:SetSize(width, height)
end

local function FindValue(option, value)
    for i, choice in ipairs(option.values or {}) do
        if choice.value == value then return choice.label, i end
    end
end

local function Enabled(row)
    if not ui.open or ui.updating or not row.option or row.id ~= ui.selected or Combat() then return false end
    if not ui.module or not ns.IsEnabled(ui.module) then return false end
    local entry = ns.skinCatalogByID and ns.skinCatalogByID[row.id]
    if entry and ns.TargetEnabled and not ns.TargetEnabled(entry) then return false end
    return not row.option.enabled or row.option.enabled()
end

local function SyncRow(row)
    local option = row.option
    if not option then return end
    local value = option.get and option.get()
    local control = row.control
    local enabled = not Combat() and (not option.enabled or option.enabled())
    if control.SetEnabled then control:SetEnabled(enabled)
    elseif enabled then control:Enable() else control:Disable() end
    if option.kind == "toggle" then control:SetChecked(value == true)
    elseif option.kind == "slider" then
        value = value or option.min
        if not control.GetValue or control:GetValue() ~= value then control:SetValue(value) end
        row.title:SetText(option.label .. ": " .. tostring(value) .. (option.unit or ""))
    elseif option.kind == "choice" then
        control.label:SetText(FindValue(option, value) or (value ~= nil and "Unavailable" or "Choose"))
    else control.label:SetText(option.buttonLabel or option.label) end
    if option.status then row.description:SetText(option.status()) end
end

local function Write(row, value)
    if not Enabled(row) then return end
    local option = row.option
    if option.get() == value then return end
    option.set(value) -- Provider notifies after committing the shared preference.
end

local function MakeRow(kind)
    local frame = CreateFrame("Frame", nil, ui.detailContent)
    Fill(frame, 0.09, 0.10, 0.11, 0.65)
    local row = {frame = frame, title = Text(frame), description = Text(frame, "GameFontHighlightSmall")}
    row.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -7)
    row.title:SetWordWrap(true)
    row.description:SetWordWrap(true)
    row.description:SetTextColor(0.72, 0.75, 0.78)
    local control
    if kind == "toggle" then
        control = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        control:SetScript("OnClick", function(self) Write(row, self:GetChecked() == true) end)
    elseif kind == "slider" then
        control = CreateFrame("Slider", nil, frame)
        control:SetOrientation("HORIZONTAL")
        control:EnableMouse(true)
        control:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        Fill(control, 0.19, 0.21, 0.23, 1)
        if control.SetObeyStepOnDrag then control:SetObeyStepOnDrag(true) end
        control:SetScript("OnValueChanged", function(_, value) Write(row, value) end)
    else
        control = Button(frame)
        control:SetScript("OnClick", function()
            if not Enabled(row) then return end
            local option = row.option
            if kind == "action" then option.run(); Refresh(); return end
            local values = option.values or {}
            if #values == 0 then return end
            local _, index = FindValue(option, option.get())
            for offset = 1, #values do
                local choice = values[((index or 0) + offset - 1) % #values + 1]
                if not choice.available or choice.available() then Write(row, choice.value); return end
            end
        end)
    end
    row.control = control
    return row
end

local function BindDetails()
    ui.updating = true
    for _, pool in pairs(ui.pools) do
        for _, row in ipairs(pool) do row.option, row.id = nil, nil; row.frame:Hide() end
    end
    local provider = providers[ui.selected]
    local title = provider and provider.label or "No active configurable addons"
    local notice = not provider and "Enable and load a supported addon with configurable settings, or open Legacy options."
        or (Combat() and "Settings are unavailable during combat.") or ""
    ui.heading:SetText(title)
    ui.notice:SetText(notice)
    local width = ui.detailWidth
    ui.heading:SetWidth(width - 16); ui.notice:SetWidth(width - 16)
    local y = math.max(20, ui.heading:GetStringHeight()) + 8
    if notice ~= "" then y = y + math.max(16, ui.notice:GetStringHeight()) + 8 end
    ui.notice:ClearAllPoints()
    ui.notice:SetPoint("TOPLEFT", ui.heading, "BOTTOMLEFT", 0, -5)
    if provider then
        local used = {}
        local count = #provider.options + (provider.reset and 1 or 0)
        for i = 1, count do
            local option = provider.options[i] or provider.reset
            local kind = option.kind
            local pool = ui.pools[kind]
            if pool and (not option.visible or option.visible()) then
                local slot = (used[kind] or 0) + 1
                used[kind] = slot
                local row = pool[slot]
                if not row then row = MakeRow(kind); pool[slot] = row end
                row.option, row.id = option, ui.selected
                row.title:SetText(option.label)
                row.description:SetText(option.status and option.status() or option.description or "")
                local controlWidth = kind == "toggle" and 24 or math.min(150, math.floor(width * 0.38))
                local stacked = width < 225 and kind ~= "toggle"
                row.title:SetWidth(math.max(40, width - (stacked and 16 or controlWidth + 24)))
                row.description:SetWidth(width - 16)
                local titleHeight = math.max(18, row.title:GetStringHeight())
                local descHeight = (option.status or option.description) and math.max(14, row.description:GetStringHeight()) + 5 or 0
                local lineHeight = stacked and titleHeight + 29 or math.max(24, titleHeight)
                Place(row.frame, ui.detailContent, 0, y, width, lineHeight + descHeight + 12)
                Place(row.control, row.frame, width - controlWidth - 8, stacked and titleHeight + 9 or 3,
                    controlWidth, kind == "slider" and 18 or 24)
                row.description:ClearAllPoints()
                row.description:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 8, -lineHeight - 6)
                if kind == "slider" then
                    row.control:SetMinMaxValues(option.min, option.max)
                    row.control:SetValueStep(option.step or 1)
                end
                SyncRow(row); row.frame:Show()
                y = y + lineHeight + descHeight + 16
            end
        end
    end
    ui.detailContent:SetHeight(math.max(1, y))
    ui.detailScroll:SetVerticalScroll(math.min(ui.detailScroll:GetVerticalScroll(), ui.detailScroll:GetVerticalScrollRange()))
    ui.updating = false
end

local Select
local function Sidebar()
    local query = (ui.search:GetText() or ""):lower()
    local shown = 0
    local r, g, b = 0.36, 0.70, 0.61
    local module = ui.module
    if module and module.skin and module.skin.GetAccentColor then r, g, b = module.skin.GetAccentColor() end
    ui.firstMatch = nil
    ui.clearSearch:SetShown(query ~= "")
    for _, entry in ipairs(ui.entries) do
        if query == "" or entry.label:lower():find(query, 1, true) then
            shown = shown + 1
            if not ui.firstMatch then ui.firstMatch = entry.id end
            local button = ui.buttons[shown]
            if not button then
                button = Button(ui.listContent)
                button:SetScript("OnClick", function(self) if ui.open and self.id then Select(self.id, true) end end)
                ui.buttons[shown] = button
            end
            button.id = entry.id
            button.label:SetText(entry.label)
            if entry.id == ui.selected then
                button.fill:SetColorTexture(r * 0.33, g * 0.33, b * 0.33, 1)
                button.label:SetTextColor(0.95, 0.98, 0.98)
            else
                button.fill:SetColorTexture(0.10, 0.11, 0.12, 0.95)
                button.label:SetTextColor(0.77, 0.81, 0.83)
            end
            Place(button, ui.listContent, 0, (shown - 1) * 25, ui.listWidth, 24)
            button:Show()
        end
    end
    for i = shown + 1, #ui.buttons do ui.buttons[i].id = nil; ui.buttons[i]:Hide() end
    ui.empty:SetText(#ui.entries == 0 and "No active addons" or "No matching addons")
    ui.empty:SetShown(shown == 0)
    ui.listContent:SetHeight(math.max(25, shown * 25))
    ui.listScroll:SetVerticalScroll(math.min(ui.listScroll:GetVerticalScroll(), ui.listScroll:GetVerticalScrollRange()))
end

Select = function(id, remember)
    local module = id and ui.activeModules[id]
    if not module then id = nil end
    local changed = ui.selected ~= id
    ui.selected, ui.module = id, module
    if remember and id then
        EUIAddonSkinsDB = EUIAddonSkinsDB or {}
        local db = EUIAddonSkinsDB
        if type(db.settingsUI) ~= "table" then db.settingsUI = {} end
        if db.settingsUI.lastAddonID ~= id then db.settingsUI.lastAddonID = id end
    end
    if changed then ui.detailScroll:SetVerticalScroll(0) end
    Sidebar()
    BindDetails()
end

Refresh = function()
    ui.entries = {}
    ui.activeModules = {}
    for id, provider in pairs(providers) do
        local module = ActiveModule(id)
        if module then
            ui.activeModules[id] = module
            ui.entries[#ui.entries+1] = {id = id, label = provider.label}
        end
    end
    table.sort(ui.entries, function(a, b) return a.label:lower() < b.label:lower()
        or a.label:lower() == b.label:lower() and a.id < b.id end)
    local db = EUIAddonSkinsDB and EUIAddonSkinsDB.settingsUI
    local saved = type(db) == "table" and db.lastAddonID
    local id = ui.activeModules[requested] and requested
        or ui.activeModules[ui.selected] and ui.selected
        or ui.activeModules[saved] and saved
        or ui.entries[1] and ui.entries[1].id
    requested = nil
    Select(id)
end

local function Layout()
    local root = ui.root
    local w, h = root:GetWidth(), root:GetHeight()
    if w <= 0 or h <= 0 then w, h = 600, 450 end
    if ui.width == w and ui.height == h then return end
    ui.width, ui.height = w, h
    local narrow = w < 480
    local left = narrow and w - 36 or 170
    local listHeight = narrow and 76 or math.max(25, h - 107)
    local detailX, detailY = narrow and 12 or left + 38, narrow and 164 or 38
    Place(ui.legacy, root, w - 137, narrow and math.max(30, h - 32) or 8, 125, 23)
    Place(ui.search, root, 14, 52, math.max(45, left - 32), 22)
    Place(ui.clearSearch, root, left - 12, 52, 22, 22)
    Place(ui.listScroll, root, 12, 80, math.max(70, left), listHeight)
    Place(ui.detailScroll, root, detailX, detailY, math.max(100, w - detailX - 33), math.max(30, h - detailY - (narrow and 40 or 18)))
    ui.listWidth = math.max(70, left - 5)
    ui.detailWidth = math.max(100, w - detailX - 38)
    ui.listContent:SetWidth(ui.listWidth)
    ui.detailContent:SetWidth(ui.detailWidth)
    ui.divider:ClearAllPoints()
    ui.divider:SetPoint("TOPLEFT", root, "TOPLEFT", left + 30, -38)
    ui.divider:SetSize(1, math.max(1, h - 56))
    ui.divider:SetShown(not narrow)
end

local function Build(root)
    Fill(root, 0.045, 0.052, 0.059, 0.97)
    local name = Text(root, "GameFontNormalLarge")
    name:SetPoint("TOPLEFT", root, "TOPLEFT", 12, -10); name:SetText("EUI AddonSkins")
    local legacy = Button(root)
    ui.legacy = legacy
    legacy.label:SetText("Legacy options")
    legacy:SetScript("OnClick", function() if not Combat() then ns.OpenLegacyAddonSettings() end end)
    ui.search = CreateFrame("EditBox", "EUIAddonSkinsSearch", root, "InputBoxTemplate")
    ui.search:SetAutoFocus(false)
    ui.clearSearch = Button(root)
    ui.clearSearch.label:SetText("×")
    ui.clearSearch:SetScript("OnClick", function() ui.search:SetText(""); ui.search:ClearFocus() end)
    local searchLabel = Text(root, "GameFontHighlightSmall")
    searchLabel:SetPoint("BOTTOMLEFT", ui.search, "TOPLEFT", 0, 3); searchLabel:SetText("Search addons")
    ui.search:SetScript("OnTextChanged", function() if ui.open and not ui.updating then Sidebar() end end)
    ui.search:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    ui.search:SetScript("OnEnterPressed", function(self)
        if ui.open and ui.firstMatch then Select(ui.firstMatch, true) end
        self:ClearFocus()
    end)
    ui.listScroll, ui.listContent = Scroll(root, "EUIAddonSkinsSidebarScroll")
    ui.detailScroll, ui.detailContent = Scroll(root, "EUIAddonSkinsOptionsScroll")
    ui.heading = Text(ui.detailContent, "GameFontNormalLarge")
    ui.heading:SetPoint("TOPLEFT", ui.detailContent, "TOPLEFT", 0, -2)
    ui.heading:SetWordWrap(true)
    ui.notice = Text(ui.detailContent, "GameFontHighlightSmall")
    ui.notice:SetWordWrap(true)
    ui.empty = Text(ui.listContent, "GameFontHighlightSmall")
    ui.empty:SetPoint("TOPLEFT", ui.listContent, "TOPLEFT", 5, -5)
    ui.divider = root:CreateTexture(nil, "ARTWORK")
    ui.divider:SetColorTexture(0.22, 0.25, 0.28, 0.7)
    ui.built = true
    root:SetScript("OnSizeChanged", function()
        if not ui.open then return end
        Layout(); Sidebar(); BindDetails()
    end)
end

function ns.SettingsPreferenceChanged(id, key)
    if not ui or not ui.open or ui.updating or ui.selected ~= id then return end
    ui.updating = true
    for _, pool in pairs(ui.pools) do
        for _, row in ipairs(pool) do
            if row.option and (not key or row.option.key == key or row.option.dependsOn == key) then SyncRow(row) end
        end
    end
    ui.updating = false
end

function ns.SupportsAddonSettingsCanvas()
    return Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory and Settings.OpenToCategory
end

local function RegisterCanvas()
    if category or not ns.SupportsAddonSettingsCanvas() then return end
    local root = CreateFrame("Frame", "EUIAddonSkinsSettingsCanvas", UIParent)
    root.name = "EUI AddonSkins"
    root:Hide()
    ui = {root=root, pools={toggle={},choice={},slider={},action={}}, entries={}, buttons={}}
    root:SetScript("OnShow", function()
        if ui.open then return end
        if not ui.built then Build(root) end
        Layout()
        ui.open = true
        root:RegisterEvent("PLAYER_REGEN_DISABLED")
        root:RegisterEvent("PLAYER_REGEN_ENABLED")
        root:RegisterEvent("UI_SCALE_CHANGED")
        Refresh()
    end)
    root:SetScript("OnHide", function()
        if not ui.open then return end
        ui.open = false
        root:UnregisterAllEvents()
        ui.search:ClearFocus(); ui.search:SetText("")
        for _, pool in pairs(ui.pools) do
            for _, row in ipairs(pool) do row.option, row.id = nil, nil end
        end
    end)
    root:SetScript("OnEvent", function(_, event)
        if not ui.open then return end
        if event == "UI_SCALE_CHANGED" then Layout() end
        Refresh()
    end)
    category = Settings.RegisterCanvasLayoutCategory(root, root.name)
    Settings.RegisterAddOnCategory(category)
end

function ns.OpenAddonSettings(id)
    if not ns.SupportsAddonSettingsCanvas() or id and not ActiveModule(id) then return false end
    RegisterCanvas()
    if not category then return false end
    requested = id
    if ui.open and id then Refresh() end
    Settings.OpenToCategory(category:GetID())
    return true
end

local function Toggle(key, label, description, get, set)
    return {kind="toggle", key=key, label=label, description=description,
        get=function() return get(key) end, set=function(value) set(key, value) end}
end
ns.RegisterSettingsProvider("Details", {label="Details!", options={
    Toggle("menus", "Skin menus and options", "Styles Details! dialogs and dropdowns. Reload after changing.", ns.ReadDetailsSetting, ns.SetDetailsSetting),
    Toggle("meter", "Match EUI meter appearance", "Matches fonts, bars and spacing. Turning it off restores the captured appearance.", ns.ReadDetailsSetting, ns.SetDetailsSetting),
    Toggle("tiny", "Style Tiny Threat", "Styles Tiny Threat independently of other Details! meters.", ns.ReadDetailsSetting, ns.SetDetailsSetting),
}})
ns.RegisterSettingsProvider("RXPGuides", {label="RestedXP", options={
    Toggle("arrow", "Skin navigation arrow", "Turn off to restore RestedXP's original arrow. Separate from guide style and opacity.", ns.ReadRXPSetting, ns.SetRXPSetting),
}})

-- Appearance providers delegate to the active adapter.
local function Handler()
    return ui.module and ui.module.settingsAppearance
end

local function Appearance(kind, key, label, description)
    local option = {kind=kind, key=key, label=label, description=description}
    option.enabled = function() return Handler() ~= nil end
    option.get = function()
        local handler = Handler()
        if handler then return handler.get(key) end
    end
    option.set = function(value) Handler().set(key, value) end
    if kind == "slider" then option.min, option.max, option.step, option.unit = 0, 100, 1, "%" end
    return option
end

local function Reset(description)
    local option = Appearance("action", "reset", "Reset Skin Settings", description)
    option.buttonLabel = "Reset"
    option.run = function() Handler().reset() end
    return option
end

local function ForeverAvailable()
    return _G.EllesmereUI and _G.EllesmereUI.IS_FOREVER == true
end

local function SkinStyle(available, unsupportedText)
    local option = Appearance("choice", "style", "Skin Style")
    option.values = {
        {value="auto", label="Automatic"},
        {value="standard", label="EUI Standard"},
        {value="forever", label="EUI Forever", available=available},
    }
    option.status = function()
        local handler = Handler()
        if not handler then return "The effective style is available when the skin is active." end
        local text = "Effective: " .. handler.effectiveStyle()
        local supported = handler.supportsForever or available
        if option.get() == "forever" and supported and not supported() then return text .. ". " .. unsupportedText end
        return text
    end
    return option
end
local style = SkinStyle(ForeverAvailable, "The saved EUI Forever choice requires the Forever client.")
local rxp = providers.RXPGuides
local rxpOpacity = Appearance("slider", "opacity", "Background Opacity", "Changes the guide background while leaving text and controls visible.")
rxpOpacity.dependsOn = "style"
table.insert(rxp.options, 1, rxpOpacity)
table.insert(rxp.options, 1, style)
rxp.reset = Reset("Resets guide style and opacity. Keeps the navigation arrow setting.")

ns.RegisterSettingsProvider("AllTheThings", {label="AllTheThings", options={
    Appearance("slider", "opacity", "Background Opacity", "Changes the window background without fading text or icons."),
}})
ns.RegisterSettingsProvider("RareScanner", {label="RareScanner", options={
    Appearance("slider", "opacity", "Background Opacity", "Changes the alert and navigation button backgrounds."),
}})

local kiwiSource = Appearance("choice", "opacitySource", "Background Opacity Source", "Follow KiwiFarm's opacity or set it here.")
kiwiSource.values = {{value="native", label="KiwiFarm"}, {value="custom", label="Custom"}}
kiwiSource.dependsOn = "backgroundOpacity"
local kiwiOpacity = Appearance("slider", "backgroundOpacity", "Background Opacity")
kiwiOpacity.enabled = function() return kiwiSource.get() == "custom" end
local kiwiTreatment = Appearance("choice", "backgroundStyle", "Background Style")
kiwiTreatment.values = {{value="soft", label="Soft highlight"}, {value="flat", label="Flat charcoal"}}
ns.RegisterSettingsProvider("KiwiFarm", {label="KiwiFarm",
    ready=function(module) return module.settingsAppearance ~= nil end, options={
    kiwiTreatment,
    Appearance("toggle", "useEUIFont", "Use EUI Font", "Applies to KiwiFarm statistics. Turn off to restore the original font and outline."),
    kiwiSource,
    kiwiOpacity,
    Appearance("slider", "menuOpacity", "Menu Background Opacity"),
    Appearance("toggle", "accent", "Show Accent Line"),
}, reset=Reset("Restores KiwiFarm's AddonSkins appearance defaults.")})

local spyReset = Reset("Restores Spy's AddonSkins style and opacity. Keeps native Spy settings.")
spyReset.label = "Reset Appearance"
ns.RegisterSettingsProvider("Spy", {label="Spy", options={
    SkinStyle(nil, "EUI Forever rendering is unavailable on this client or EUI version."),
    Appearance("slider", "opacity", "Background Opacity", "Changes only the Forever decorative background. Spy controls its own bar textures and window fading."),
}, reset=spyReset})

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    RegisterCanvas()
end)
