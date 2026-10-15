local ADDON, ns = ...
local function DefineSkin()
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

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("KiwiFarm", DefineSkin)
else DefineSkin() end
