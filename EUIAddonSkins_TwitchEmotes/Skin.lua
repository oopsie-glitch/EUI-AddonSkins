local ADDON, ns = ...
-- Standalone skin addons receive their own namespace from WoW.
if ADDON ~= "EUIAddonSkins" then
    ns = EUIAddonSkins and EUIAddonSkins.GetSkinNamespace(ADDON)
    if not ns then return end
    ADDON = "EUIAddonSkins"
end
ns.RegisterModule("TwitchEmotes", "TwitchEmotes", function()
    return _G.EmoticonMiniMapDropDown ~= nil
end, function(S, module)
    local function refresh()
        ns.BindPopupOwner(S, module, _G.EmoticonMiniMapDropDown)
    end
    refresh()
    module.refresh = refresh
    if S.OnLooksChanged then S.OnLooksChanged(refresh) end
end)
