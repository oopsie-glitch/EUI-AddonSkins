local ADDON, ns = ...

function ns.DetailsSettings()
    EUIAddonSkinsDB = EUIAddonSkinsDB or {}
    local db = EUIAddonSkinsDB
    db.details = db.details or {menus = true, meter = true, toolbar = true, tiny = false}
    if db.details.tiny == nil then db.details.tiny = db.details.meter == true end
    if db.details.toolbar == nil then db.details.toolbar = db.details.meter == true or db.details.tiny == true end
    return db.details
end

-- UI reads must not materialize defaults merely by opening the canvas.
function ns.ReadDetailsSetting(key)
    local db = EUIAddonSkinsDB and EUIAddonSkinsDB.details
    if key == "menus" then return not db or db.menus == true end
    if key == "meter" then return not db or db.meter == true end
    if key == "toolbar" then
        if db and db.toolbar ~= nil then return db.toolbar == true end
        return not db or db.meter == true or db.tiny == true
    end
    if key == "tiny" then
        if db and db[key] ~= nil then return db[key] == true end
        return db and db.meter == true or false
    end
end

local legacyControls = {}
local function PreferenceChanged(id, key, value)
    local control = legacyControls[key]
    if control and control.IsVisible and control:IsVisible() then control:SetChecked(value) end
    if ns.SettingsPreferenceChanged then ns.SettingsPreferenceChanged(id, key) end
end

function ns.SetDetailsSetting(key, value)
    if key ~= "menus" and key ~= "meter" and key ~= "tiny" and key ~= "toolbar" then return end
    ns.DetailsSettings()[key] = value == true
    if ns.DetailsSettingsChanged then ns.DetailsSettingsChanged(key) end
    PreferenceChanged("Details", key, value == true)
end

-- Shared addon settings live here; retain the Details entry points for its menu.
function ns.RXPSettings()
    EUIAddonSkinsDB = EUIAddonSkinsDB or {}
    local db = EUIAddonSkinsDB
    db.rxp = db.rxp or {}
    if db.rxp.arrow == nil then db.rxp.arrow = true end
    return db.rxp
end

function ns.ReadRXPSetting(key)
    if key ~= "arrow" then return end
    local db = EUIAddonSkinsDB and EUIAddonSkinsDB.rxp
    return not db or db.arrow == nil or db.arrow == true
end

function ns.SetRXPSetting(key, value)
    if key ~= "arrow" then return end
    value = value == true
    local db = ns.RXPSettings()
    if db[key] == value then return end
    db[key] = value
    if ns.RXPSettingsChanged then ns.RXPSettingsChanged() end
    PreferenceChanged("RXPGuides", key, value)
end

-- Explicit, per-window setup. Native setters own the changes and normal
-- Details profile saving persists them. No cosmetic callback invokes this.
local PRESET_DIALOG = "EUI_ADDONSKINS_DETAILS_RECOMMENDED"
local PRESET_FONT = "EUI AddonSkins Recommended"
local PRESET_TEXTURE = "EUI AddonSkins Meter"
local function PresetMedia()
    local media = LibStub and LibStub("LibSharedMedia-3.0", true)
    if media and type(media.Register) == "function" and type(media.Fetch) == "function" then return media end
end
function ns.RegisterDetailsPresetMedia()
    local db = EUIAddonSkinsDB and EUIAddonSkinsDB.details
    local saved = db and db.presetMedia
    if not saved then return true end
    local media = PresetMedia()
    if not media then return false end
    for _, kind in ipairs({"font", "statusbar"}) do
        for name, path in pairs(saved[kind] or {}) do
            if type(name) == "string" and type(path) == "string" then media:Register(kind, name, path) end
        end
    end
    return true
end
local function PresetMessage(text)
    if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(text, 1, 0.6, 0.2) end
end
local function PresetWindow(id)
    local details = _G.Details
    if not details or type(details.GetAllInstances) ~= "function" then return end
    for _, instance in pairs(details:GetAllInstances() or {}) do
        if instance.meu_id == id and instance.baseframe then return instance end
    end
end
local function PresetReady(instance)
    if InCombatLockdown and InCombatLockdown() then return false end
    if not instance or not instance.baseframe then return false end
    local frame = instance.baseframe
    if frame.IsForbidden and frame:IsForbidden() or frame.IsProtected and frame:IsProtected() then return false end
    for _, name in ipairs({"SetBarSettings", "SetBarTextSettings", "SetBarRightTextSettings"}) do
        if type(instance[name]) ~= "function" then return false end
    end
    return type(ns.DetailsPresetStyle) == "function"
end
function ns.CanOpenDetailsRecommendedPreset()
    if not StaticPopupDialogs or type(StaticPopup_Show) ~= "function" then return false end
    local details = _G.Details
    if not details or type(details.GetCurrentProfileName) ~= "function" or type(details.GetAllInstances) ~= "function" then return false end
    for _, instance in pairs(details:GetAllInstances() or {}) do
        if PresetReady(instance) then return true end
    end
    return false
end
function ns.ApplyDetailsRecommendedPreset(id, request)
    if not request or not _G.Details or Details:GetCurrentProfileName() ~= request.profile then
        PresetMessage("The Details profile changed. Open the preset confirmation again.")
        return false
    end
    local instance = PresetWindow(id)
    if not PresetReady(instance) or not ns.DetailsPresetStyle() then
        PresetMessage("The selected Details window is unavailable or cannot be changed in combat.")
        return false
    end
    local media = PresetMedia()
    if not media then
        PresetMessage("Details SharedMedia is unavailable.")
        return false
    end
    local look = request.look
    if type(look.font) ~= "string" or type(look.texture) ~= "string" then return false end
    local fontName, textureName = PRESET_FONT .. ": " .. look.font, PRESET_TEXTURE .. ": " .. look.texture
    media:Register("font", fontName, look.font)
    media:Register("statusbar", textureName, look.texture)
    if media:Fetch("font", fontName, true) ~= look.font or media:Fetch("statusbar", textureName, true) ~= look.texture then
        PresetMessage("The recommended media names are already registered to different assets.")
        return false
    end
    local saved = ns.DetailsSettings()
    saved.presetMedia = saved.presetMedia or {font = {}, statusbar = {}}
    saved.presetMedia.font[fontName], saved.presetMedia.statusbar[textureName] = look.font, look.texture
    -- The documented native setters change only the disclosed bar preferences.
    -- Per-column font overrides, class/status colors, title/timer and geometry
    -- remain native. Selecting a profile or toggling cosmetics never calls here.
    instance:SetBarSettings(look.height, textureName, nil, nil, nil, nil, nil, nil, nil, nil, look.spacing)
    instance:SetBarTextSettings(look.leftSize, fontName, nil, nil, nil, nil, nil, false)
    instance:SetBarRightTextSettings(true, true, false, "(", "NONE")
    if type(instance.SetSimpleFormattingSettings) == "function" then instance:SetSimpleFormattingSettings(false) end
    return true
end
function ns.OpenDetailsRecommendedPreset(preferred)
    if not ns.CanOpenDetailsRecommendedPreset() then return end
    local look = ns.DetailsPresetStyle()
    if not look then return end
    local details = _G.Details
    local ids, first = {}, nil
    for _, instance in pairs(details:GetAllInstances() or {}) do
        if PresetReady(instance) then
            ids[#ids + 1] = instance.meu_id
            if not first or instance.meu_id < first then first = instance.meu_id end
        end
    end
    table.sort(ids)
    local textIds = {}
    for i, id in ipairs(ids) do textIds[i] = tostring(id) end
    if not StaticPopupDialogs[PRESET_DIALOG] then
        StaticPopupDialogs[PRESET_DIALOG] = {
            text = "%s", button1 = "Apply to Window", button2 = CANCEL or "Cancel",
            hasEditBox = true, editBoxWidth = 64, timeout = 0, whileDead = true,
            hideOnEscape = true, preferredIndex = 3,
            OnShow = function(self, data)
                local edit = self.GetEditBox and self:GetEditBox() or self.editBox
                if edit then edit:SetText(tostring(data.id)); if edit.HighlightText then edit:HighlightText() end end
            end,
            OnAccept = function(self, data)
                local edit = self.GetEditBox and self:GetEditBox() or self.editBox
                local text = edit and edit:GetText()
                if issecretvalue and issecretvalue(text) then return end
                local id = tonumber(text)
                if not id or not PresetWindow(id) then PresetMessage("Enter one of the listed Details window numbers."); return end
                ns.ApplyDetailsRecommendedPreset(id, data)
            end,
        }
    end
    local request = {profile = details:GetCurrentProfileName(), look = look,
        id = preferred and PresetReady(preferred) and preferred.meu_id or first}
    local disclosure = string.format(
        "EUI Recommended Preset\n\nProfile: %s\nAvailable window numbers: %s\n\n"
        .. "Changes only the selected window's bars:\nEUI texture, common EUI font (%g), height %g, spacing %g, "
        .. "native total/per-second values, no percentage, parentheses and no separator, custom right text off.\n\n"
        .. "Keeps per-column font overrides, class/status colors, title/timer, toolbar and window layout. "
        .. "This replaces these bar preferences in the active profile once. You can customize them afterward.\n\n"
        .. "Enter the target window number:",
        request.profile, table.concat(textIds, ", "), look.leftSize, look.height, look.spacing)
    return StaticPopup_Show(PRESET_DIALOG, disclosure, nil, request)
end

local panel, category
function ns.CreateDetailsSettingsPanel()
    if panel then return panel end
    panel = CreateFrame("Frame", "EUIAddonSkinsDetailsSettings", UIParent)
    panel.name = ns.SupportsAddonSettingsCanvas and ns.SupportsAddonSettingsCanvas()
        and "EUI AddonSkins (Legacy)" or "EUI AddonSkins"
    local function Text(value, template, y)
        local text = panel:CreateFontString(nil, "ARTWORK", template)
        text:SetPoint("TOPLEFT", 16, y); text:SetText(value)
        return text
    end
    Text(panel.name, "GameFontNormalLarge", -16)
    Text("Appearance options for supported addons.", "GameFontHighlight", -46)
    local function Check(key, label, description, y, get, set)
        get, set = get or ns.ReadDetailsSetting, set or ns.SetDetailsSetting
        local button = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
        button:SetPoint("TOPLEFT", 16, y)
        local text = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("LEFT", button, "RIGHT", 4, 0); text:SetText(label)
        button:SetScript("OnClick", function(self) set(key, self:GetChecked() == true) end)
        button:HookScript("OnShow", function(self) self:SetChecked(get(key) == true) end)
        legacyControls[key] = button
        Text(description, "GameFontHighlightSmall", y - 34)
        return button
    end
    Text("RestedXP", "GameFontNormal", -82)
    panel.rxpArrow = Check("arrow", "Skin navigation arrow", "Use the themed arrow. Turn off to restore RestedXP's original arrow appearance.", -104, ns.ReadRXPSetting, ns.SetRXPSetting)
    Text("Details!", "GameFontNormal", -190)
    panel.menus = Check("menus", "Skin menus and options", "Styles Details dialogs, dropdowns and options. Reload after changing this setting.", -216)
    panel.meter = Check("meter", "Style meter surfaces", "Styles window surfaces and the title accent. Details controls text, fonts, bars and layout.", -294)
    panel.toolbar = Check("toolbar", "Style toolbar artwork", "Uses EUI icons within native button bounds. Details controls size, visibility and placement.", -372)
    panel.tiny = Check("tiny", "Style Tiny Threat", "Independent styling for Tiny Threat rows and their Details window.", -450)
    panel.preset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.preset:SetPoint("TOPLEFT", 16, -530); panel.preset:SetSize(220, 22)
    panel.preset:SetText("EUI Recommended Preset...")
    panel.preset:SetScript("OnClick", function() ns.OpenDetailsRecommendedPreset() end)
    Text("Optional setup for one window. Review the changed settings before applying.", "GameFontHighlightSmall", -560)
    Text("Window positions, sizes, groups, statistics and interactions remain controlled by Details.", "GameFontHighlightSmall", -584)
    Text("Quick access: hover the meter settings icon > EUI AddonSkins.", "GameFontHighlightSmall", -608)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(panel) end
    return panel
end

SLASH_EUIDETAILS1 = "/euidetails"
function ns.OpenLegacyAddonSettings()
    ns.CreateDetailsSettingsPanel()
    if Settings and Settings.OpenToCategory and category then Settings.OpenToCategory(category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then InterfaceOptionsFrame_OpenToCategory(panel) end
end
function ns.OpenDetailsSettings()
    if ns.OpenAddonSettings and ns.OpenAddonSettings("Details") then return end
    ns.OpenLegacyAddonSettings()
end
SlashCmdList.EUIDETAILS = ns.OpenDetailsSettings

-- Register the shared controls even when Details is absent or its skin is off.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
if not ns.RegisterDetailsPresetMedia() then events:RegisterEvent("ADDON_LOADED") end
events:SetScript("OnEvent", function(self, event)
    if ns.RegisterDetailsPresetMedia() and self.UnregisterEvent then self:UnregisterEvent("ADDON_LOADED") end
    if event == "ADDON_LOADED" then return end
    if self.UnregisterEvent then self:UnregisterEvent("PLAYER_LOGIN") end
    if not (ns.SupportsAddonSettingsCanvas and ns.SupportsAddonSettingsCanvas()) then
        ns.CreateDetailsSettingsPanel()
    end
end)
