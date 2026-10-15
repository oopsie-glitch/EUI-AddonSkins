local ADDON, ns = ...
ns.VERSION = "1.4.0-alpha.3"
ns.modules = {}

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff0cd29fEUI AddonSkins:|r " .. message)
end

function ns.IsEnabled(module)
    if EUIAddonSkinsDB and EUIAddonSkinsDB.disabled then return false end
    if not module then return true end
    local S = module.skin
    return S and (not S.IsEnabled or S.IsEnabled()) or false
end

local function TryModules()
    for _, module in ipairs(ns.modules) do
        if not module.attempted and ns.IsEnabled(module) and module.available() then
            module.attempted = true
            local ok, err = pcall(module.install, module.skin, module)
            module.active = ok
            if not ok then geterrorhandler()(ADDON .. " / " .. module.label .. ": " .. tostring(err)) end
        end
    end
end

local function Register()
    local EUI = _G.EllesmereUI
    if not (EUI and EUI.RegisterSkin) then return end
    if ns.skinCatalog then
        for _, entry in ipairs(ns.skinCatalog) do
            if not entry.registered and ns.TargetEnabled(entry) then
                entry.registered = true
                EUI.RegisterSkin("EUI AddonSkins - " .. entry.label, function(S)
                    entry.skin = S
                    for _, module in ipairs(ns.modules) do if module.id == entry.id then module.skin = S end end
                    ns.LoadSkin(entry)
                    TryModules()
                end)
            end
        end
        return
    end
    for _, module in ipairs(ns.modules) do
        if not module.registered then
            module.registered = true
            -- Unique collection-prefixed names avoid target addons' own registrations.
            EUI.RegisterSkin("EUI AddonSkins - " .. module.label, function(S)
                module.skin = S
                TryModules()
            end)
        end
    end
end

-- Runtime modules inherit the already registered catalog toggle when loaded.
function ns.RegisterModule(id, label, available, install)
    for _, module in ipairs(ns.modules) do
        if module.id == id then error("Duplicate skin module: " .. id) end
    end
    local entry = ns.skinCatalogByID and ns.skinCatalogByID[id]
    table.insert(ns.modules, { id = id, label = label, available = available, install = install,
        registered = entry and entry.registered, skin = entry and entry.skin })
    Register()
    TryModules()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
    EUIAddonSkinsDB = EUIAddonSkinsDB or {}
    Register()
    if ns.skinCatalog then
        for _, entry in ipairs(ns.skinCatalog) do ns.LoadSkin(entry) end
    end
    TryModules()
    if event == "PLAYER_LOGIN" and not (_G.EllesmereUI and _G.EllesmereUI.RegisterSkin) then
        Print("Skin API unavailable. Update EllesmereUI and enable Blizzard Skins+.")
    end
end)
ns.RefreshRegistrations = Register
Register()

SLASH_EUIADDONSKINS1 = "/euiskins"
SLASH_EUIADDONSKINS2 = "/fcskin" -- Compatibility alias for the first release.
SlashCmdList.EUIADDONSKINS = function(message)
    local command = (message or ""):lower():match("^%s*(%S*)")
    EUIAddonSkinsDB = EUIAddonSkinsDB or {}
    if command == "off" or command == "on" then
        EUIAddonSkinsDB.disabled = command == "off"
        Print((command == "off" and "Disabled." or "Enabled.") .. " Run /reload to apply.")
    elseif command == "diagnostics" and ns.ShowLoaderDiagnostics then
        ns.ShowLoaderDiagnostics()
    elseif command == "refresh" then
        if ns.IsEnabled() then
            TryModules()
            for _, module in ipairs(ns.modules) do
                if module.active and ns.IsEnabled(module) and module.refresh then module.refresh() end
            end
            Print("Refresh requested.")
        else Print("Skins are inactive. Enable skinning and run /reload.") end
    else
        Print("v" .. ns.VERSION .. " | /euiskins on, off, refresh, list")
        if not ns.IsEnabled() then Print("Skinning disabled. Enable it and run /reload.") end
        for _, module in ipairs(ns.modules) do
            local status = "not installed or not loaded"
            if module.attempted and not module.active then status = "integration error"
            elseif module.active and ns.IsEnabled(module) then status = "active"
            elseif module.available() then status = "inactive" end
            Print(module.label .. ": " .. status)
        end
    end
end
