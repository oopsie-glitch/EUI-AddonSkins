local ADDON, ns = ...
local function DefineSkin()
ns.RegisterScopedSkin("WhatsTraining", "What's Training?", {
    softBorders = true,
    available = function() return _G.WhatsTrainingFrame ~= nil or (C_AddOns and C_AddOns.IsAddOnLoaded("WhatsTraining")) end,
    roots = function()
        local roots = ns.SkinRoots({"WhatsTrainingFrame"}, {noTopBar = true})
        if _G.WhatsTrainingSkillsButton then roots[#roots + 1] = {frame = _G.WhatsTrainingSkillsButton, mode = "controls"} end
        return roots
    end,
    hooks = function(C, refresh) C.H.Hook(_G.WhatsTrainingFrame, "Refresh", refresh) end,
    visit = function(C, f)
        local spellIcon = f.spell and C.H.Texture(f.spell.icon)
        if spellIcon then C.S.SquareIcon(spellIcon) end
        if f.groupingPopup then C.Panel(f.groupingPopup) end
        if f.scrollBar and f.scrollBar.ScrollBar then C.S.ScrollBar(f.scrollBar.ScrollBar) end
        -- Spell/city indicators keep their colors and artwork. Only UI icons crop.
        local icon = C.H.Icon(f)
        if icon then C.S.SquareIcon(icon) end
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("WhatsTraining", DefineSkin)
else DefineSkin() end
