local ADDON, ns = ...
local function DefineSkin()
local function Public()
    return LibStub and LibStub("Myslot-5.0", true)
end
ns.RegisterScopedSkin("Myslot", "Myslot", {
    softBorders = true,
    available = function() local lib = Public(); return (lib and lib.MainFrame ~= nil) or (C_AddOns and C_AddOns.IsAddOnLoaded("Myslot")) end,
    roots = function()
        local lib = Public()
        return lib and lib.MainFrame and {{frame = lib.MainFrame, options = {bottomBar = 38}}} or {}
    end,
    -- The public library exposes the main import/export/profile window. Its
    -- private UIParent-owned import progress dialog has no stable public handle.
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Myslot", DefineSkin)
else DefineSkin() end
