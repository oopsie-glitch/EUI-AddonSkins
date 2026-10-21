local ADDON, ns = ...
-- One-folder activation catalog. Skin files define factories at startup;
-- their implementation bodies run only for eligible, loaded targets.
ns.skinCatalog = {
    {id = "Altoholic", label = "Altoholic", targets = {"Altoholic"}},
    {id = "AtlasLootContinued", label = "AtlasLootClassic Continued", targets = {"AtlasLootContinued"}},
    {id = "Attune", label = "Attune", targets = {"Attune"}},
    {id = "Auctionator", label = "Auctionator", targets = {"Auctionator"}},
    {id = "BtWQuests", label = "BtWQuests", targets = {"BtWQuests"}},
    {id = "BugSack", label = "BugSack", targets = {"BugSack"}},
    {id = "DBM", label = "Deadly Boss Mods", targets = {"DBM-Core", "DBM-GUI"}},
    {id = "Details", label = "Details!", targets = {"Details"}},
    {id = "ForeverCompanion", label = "Forever Companion", targets = {"ForeverCompanion"}},
    {id = "ForeverDungeonJournal", label = "Forever Dungeon Journal", targets = {"ForeverDungeonJournal"}},
    {id = "GTFO", label = "GTFO", targets = {"GTFO"}},
    {id = "Gargul", label = "Gargul", targets = {"Gargul"}},
    {id = "ItemRack", label = "ItemRack", targets = {"ItemRack", "ItemRackOptions"}},
    {id = "KiwiFarm", label = "KiwiFarm", targets = {"KiwiFarm"}},
    {id = "Myslot", label = "Myslot", targets = {"Myslot"}},
    {id = "PallyPower", label = "PallyPower", targets = {"PallyPower"}},
    {id = "Questie", label = "Questie", targets = {"Questie"}},
    {id = "RXPGuides", label = "RestedXP Guides", targets = {"RXPGuides"}},
    {id = "Spy", label = "Spy", targets = {"Spy"}},
    {id = "ThreatClassic2", label = "ThreatClassic2", targets = {"ThreatClassic2"}},
    {id = "TwitchEmotes", label = "TwitchEmotes", targets = {"TwitchEmotes"}},
    {id = "WorldQuestTracker", label = "World Quest Tracker", targets = {"WorldQuestTracker"}},
    {id = "WhatsTraining", label = "What's Training?", targets = {"WhatsTraining"}},
}
ns.skinCatalogByID = {}
for _, entry in ipairs(ns.skinCatalog) do
    ns.skinCatalogByID[entry.id] = entry
end

local enabledCache, cacheCharacter = {}, nil
function ns.TargetEnabled(entry)
    local modern = C_AddOns and C_AddOns.GetAddOnEnableState
    -- Modern AddOnList uses a player GUID, not the display name. A name can
    -- resolve to default state 2 even for addons disabled on this character.
    local character
    if modern then character = UnitGUID and UnitGUID("player")
    else character = UnitName and UnitName("player") end
    if not character then return false end -- Resolve character overrides at login.
    if character ~= cacheCharacter then enabledCache, cacheCharacter = {}, character end
    for _, target in ipairs(entry.targets) do
        if enabledCache[target] == nil then
            local info = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo
            local ok, name = pcall(info or function() end, target)
            local state = 0
            if ok and name then
                if C_AddOns and C_AddOns.GetAddOnEnableState then state = C_AddOns.GetAddOnEnableState(target, character)
                elseif GetAddOnEnableState then state = GetAddOnEnableState(character, target) end
            end
            enabledCache[target] = (state or 0) > 0
        end
        if enabledCache[target] then return true end
    end
    return false
end
local function TargetLoaded(entry)
    local loaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    if not loaded then return false end
    for _, target in ipairs(entry.targets) do if loaded(target) then return true end end
    return false
end
function ns.LoadSkin(entry)
    local loaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    if not loaded or not loaded(ADDON) then return end
    if entry.loading or entry.loaded or entry.failed or not entry.factory or not entry.skin or not ns.IsEnabled()
        or entry.skin.IsEnabled and not entry.skin.IsEnabled() or not ns.TargetEnabled(entry)
        or not TargetLoaded(entry) then return end
    if InCombatLockdown and InCombatLockdown() then return end
    entry.loading = true
    local ok, reason = pcall(entry.factory)
    entry.loading = false
    entry.loaded = ok
    if ok then entry.factory = nil
    else
        entry.failed = true
        geterrorhandler()(ADDON .. " / " .. entry.label .. ": " .. tostring(reason))
    end
end
function ns.RegisterSkinDefinition(id, factory)
    local entry = ns.skinCatalogByID[id]
    if not entry or entry.defined then error("Unknown or duplicate skin definition: " .. tostring(id)) end
    entry.defined, entry.factory = true, factory
    ns.LoadSkin(entry)
end
-- On-demand diagnostics only: no extra polling or startup UI allocations.
local function Result(fn, ...)
    if type(fn) ~= "function" then return "unavailable" end
    local ok, value = pcall(fn, ...)
    return ok and tostring(value) or "error"
end
function ns.LoaderDiagnostics()
    local api, character = C_AddOns or {}, UnitName and UnitName("player")
    local isLoaded = api.IsAddOnLoaded or IsAddOnLoaded
    local metadata = api.GetAddOnMetadata or GetAddOnMetadata
    local function Interface() return GetBuildInfo and select(4, GetBuildInfo()) or "unavailable" end
    local integrations = {}
    for _, module in ipairs(ns.modules or {}) do integrations[module.id] = module end
    local lines = {"EUI AddonSkins loader diagnostics", "Code: " .. ns.VERSION .. " | TOC: " .. Result(metadata, ADDON, "Version"),
        "Client interface: " .. Result(Interface) .. " | EllesmereUI: " .. Result(metadata, "EllesmereUI", "Version"),
        "Skin API registration: " .. tostring(_G.EllesmereUI and type(_G.EllesmereUI.RegisterSkin) == "function" or false)
            .. " | EUI client blocked: " .. tostring(_G.EUI_CLIENT_BLOCKED == true),
        "Core loaded: " .. Result(isLoaded, ADDON), "Packaging: single addon folder; definitions loaded at startup, activation deferred",
        "Columns: target loaded / modern(account) / modern(name) / modern(GUID) / legacy(name) / toggle registered / skin activated / EUI callback received / integration active"}
    for _, entry in ipairs(ns.skinCatalog) do
        for _, target in ipairs(entry.targets) do
            lines[#lines + 1] = target .. ": " .. Result(isLoaded, target) .. " / "
                .. Result(api.GetAddOnEnableState, target) .. " / " .. Result(api.GetAddOnEnableState, target, character)
                .. " / " .. Result(api.GetAddOnEnableState, target, UnitGUID and UnitGUID("player"))
                .. " / " .. Result(GetAddOnEnableState, character, target) .. " / " .. tostring(entry.registered == true)
                .. " / " .. tostring(entry.loaded == true)
                .. " / " .. tostring(entry.skin ~= nil)
                .. " / " .. tostring(integrations[entry.id] and integrations[entry.id].active == true or false)
        end
    end
    return table.concat(lines, "\n")
end
local diagnosticWindow, diagnosticText
function ns.ShowLoaderDiagnostics()
    if InCombatLockdown and InCombatLockdown() then return end
    if not diagnosticWindow then
        diagnosticWindow = CreateFrame("Frame", "EUIAddonSkinsLoaderDiagnostics", UIParent, "BasicFrameTemplateWithInset")
        diagnosticWindow:SetSize(760, 500); diagnosticWindow:SetPoint("CENTER"); diagnosticWindow:SetFrameStrata("DIALOG")
        diagnosticWindow.TitleText:SetText("EUI AddonSkins — Loader diagnostics")
        local scroll = CreateFrame("ScrollFrame", nil, diagnosticWindow, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 12, -34); scroll:SetPoint("BOTTOMRIGHT", -32, 12)
        diagnosticText = CreateFrame("EditBox", nil, scroll)
        diagnosticText:SetMultiLine(true); diagnosticText:SetAutoFocus(false); diagnosticText:SetFontObject("ChatFontNormal")
        diagnosticText:SetWidth(700); diagnosticText:SetMaxLetters(0)
        diagnosticText:SetScript("OnEscapePressed", function() diagnosticWindow:Hide() end)
        scroll:SetScrollChild(diagnosticText)
    end
    diagnosticWindow:Show(); diagnosticText:SetText(ns.LoaderDiagnostics()); diagnosticText:HighlightText(); diagnosticText:SetFocus()
end
ns.RefreshRegistrations()
