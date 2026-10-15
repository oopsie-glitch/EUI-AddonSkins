-- Exercise each client-selected TOC, including manifests left by CurseForge.
for _, manifest in ipairs({'EUIAddonSkins.toc', 'EUIAddonSkins_Camelot.toc', 'EUIAddonSkins_Mainline.toc'}) do
    local interfaces = {}
    for line in io.lines('EUIAddonSkins/' .. manifest) do
        if line:match('^## Interface:') then for value in line:gmatch('%d+') do interfaces[tonumber(value)] = true end end
    end
    assert(interfaces[120100] and interfaces[120105] and interfaces[16001], 'Retail/Forever interface coverage regressed: ' .. manifest)
    for _, onlyTarget in ipairs({false, 'BugSack', 'PallyPower', 'BtWQuests'}) do
        local ns, entries = {}, {}
        EUIAddonSkinsDB = nil
        C_AddOns = {
            GetAddOnInfo = function(name) if onlyTarget then return name end end,
            GetAddOnEnableState = function(name, character)
                assert(character == 'Player-Test')
                return name == onlyTarget and 2 or 0
            end,
            IsAddOnLoaded = function() return false end,
            LoadAddOn = function() error('unloaded target caused skin code to load') end,
        }
        UnitName = function() return 'Test' end
        UnitGUID = function() return 'Player-Test' end
        SlashCmdList = {}; DEFAULT_CHAT_FRAME = {AddMessage = function() end}
        CreateFrame = function() return {RegisterEvent = function() end, SetScript = function() end} end
        EllesmereUI = {RegisterSkin = function(name) assert(not entries[name]); entries[name] = true end}
        for line in io.lines('EUIAddonSkins/' .. manifest) do
            if line:match('%.lua$') then
                assert(not line:match('Skin.lua$'))
                assert(loadfile('EUIAddonSkins/' .. line:gsub('\\','/')))('EUIAddonSkins', ns)
            end
        end
        assert(#ns.modules == 0 and #ns.skinCatalog == 22)
        for _, entry in ipairs(ns.skinCatalog) do assert(entry.defined and not entry.loaded) end
        local count = 0; for _ in pairs(entries) do count = count + 1 end
        assert(count == (onlyTarget and 1 or 0), manifest .. ': unexpected toggles')
        if onlyTarget then assert(entries['EUI AddonSkins - ' .. onlyTarget]) end
    end
end
print('PASS: generic, Forever/Camelot and Mainline manifests register only the enabled BugSack or PallyPower target; absent skin factories never activate')
