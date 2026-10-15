-- Exercise each client-selected TOC, including manifests left by CurseForge.
for _, manifest in ipairs({'EUIAddonSkins.toc', 'EUIAddonSkins_Camelot.toc', 'EUIAddonSkins_Mainline.toc'}) do
    for _, onlyBugSack in ipairs({false, true}) do
        local ns, entries = {}, {}
        EUIAddonSkinsDB = nil
        C_AddOns = {
            GetAddOnInfo = function(name) if onlyBugSack then return name end end,
            GetAddOnEnableState = function(name, character)
                assert(character == 'Test')
                return name == 'BugSack' and 2 or 0
            end,
            IsAddOnLoaded = function() return false end,
            LoadAddOn = function() error('unloaded target caused skin code to load') end,
        }
        UnitName = function() return 'Test' end
        SlashCmdList = {}; DEFAULT_CHAT_FRAME = {AddMessage = function() end}
        CreateFrame = function() return {RegisterEvent = function() end, SetScript = function() end} end
        EllesmereUI = {RegisterSkin = function(name) assert(not entries[name]); entries[name] = true end}
        for line in io.lines('EUIAddonSkins/' .. manifest) do
            if line:match('%.lua$') then
                assert(not line:match('Skin.lua$'))
                assert(loadfile('EUIAddonSkins/' .. line))('EUIAddonSkins', ns)
            end
        end
        assert(#ns.modules == 0 and #ns.skinCatalog == 20)
        local count = 0; for _ in pairs(entries) do count = count + 1 end
        assert(count == (onlyBugSack and 1 or 0), manifest .. ': unexpected toggles')
        if onlyBugSack then assert(entries['EUI AddonSkins - BugSack']) end
    end
end
print('PASS: generic, Forever/Camelot and Mainline manifests register only BugSack when all other installed targets are disabled; absent skins execute zero code')
