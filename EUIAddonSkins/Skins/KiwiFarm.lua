local ADDON, ns = ...
local function DefineSkin()
ns.RegisterScopedSkin("KiwiFarm", "KiwiFarm", {
    softBorders = true,
    available = function() return _G.KiwiFarm ~= nil end,
    panels = false,
    roots = function() return ns.SkinRoots({"KiwiFarm"}, {noTopBar = true}) end,
    hooks = function(C)
        local function MenuReady()
            C.MenuOwner(_G.KiwiFarmPopupMenu)
            -- KiwiFarm can create a launcher on each open. Prefer the actual
            -- renderer owner if its named global still refers to another one.
            local list = _G.DropDownList1
            local owner = list and list.dropdown
            if list and list.IsShown and list:IsShown() and C.H.Allowed(owner)
                and owner.GetName and owner:GetName() == "KiwiFarmPopupMenu" then
                C.MenuOwner(owner)
            end
            -- Registration only repaints changed bindings. Reopening an
            -- unchanged owner still needs a completed native-render pass.
            if ns.RefreshPopupMenusNow then ns.RefreshPopupMenusNow() end
        end
        C.MenuOwner(_G.KiwiFarmPopupMenu)
        C.H.Hook(_G.KiwiFarm, "ShowMenu", MenuReady)
        -- Shared popup combat recovery handles the menu itself. No guide/main
        -- frame discovery is needed for menu opens or combat-end callbacks.
    end,
    -- KiwiFarm's native whole-frame alpha/visibility still controls its shell.
    -- Shared Blizzard StaticPopup frames retain their existing styling.
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("KiwiFarm", DefineSkin)
else DefineSkin() end
