local ADDON, ns = ...
-- Standalone skin addons receive their own namespace from WoW.
if ADDON ~= "EUIAddonSkins" then
    ns = EUIAddonSkins and EUIAddonSkins.GetSkinNamespace(ADDON)
    if not ns then return end
    ADDON = "EUIAddonSkins"
end
ns.RegisterScopedSkin("KiwiFarm", "KiwiFarm", {
    softBorders = true,
    available = function() return _G.KiwiFarm ~= nil end,
    panels = false,
    roots = function() return ns.SkinRoots({"KiwiFarm"}, {noTopBar = true}) end,
    hooks = function(C, refresh)
        C.MenuOwner(_G.KiwiFarmPopupMenu)
        C.H.Hook(_G.KiwiFarm, "ShowMenu", function()
            C.MenuOwner(_G.KiwiFarmPopupMenu); refresh()
        end)
        C.H.Hook(_G.KiwiFarm, "PLAYER_REGEN_ENABLED", refresh)
    end,
    -- KiwiFarm's native whole-frame alpha/visibility still controls its shell.
    -- Shared Blizzard StaticPopup frames retain their existing styling.
})
