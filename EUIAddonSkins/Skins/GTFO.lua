local ADDON, ns = ...
local function DefineSkin()

ns.RegisterScopedSkin("GTFO", "GTFO", {
    softBorders = true,
    available = function() return type(_G.GTFO) == "table" end,
    preserveTextColors = true,
    roots = function(C)
        local roots = {}
        for _, name in ipairs({"GTFO_MainFrame", "GTFO_IgnoreOptionsFrame"}) do
            local frame = _G[name]
            if C.H.Allowed(frame) then
                -- These are canvas categories inside Blizzard's settings window.
                -- Keep the host's geometry instead of adding another window shell.
                ns.AttachAccent(C.S, frame)
                roots[#roots + 1] = {frame = frame, mode = "controls"}
            end
        end
        return roots
    end,
    hooks = function(C, refresh)
        C.H.Hook(_G, "GTFO_RenderOptions", refresh)
        C.H.Hook(_G, "GTFO_RefreshOptions", refresh)
    end,
    visit = function(C, f, kind)
        if kind == "Slider" then
            C.H.LegacySlider(f)
            -- OptionsSliderTemplate keeps chrome in a separate NineSlice frame
            -- and its oversized atlas thumb must be sized after recolouring.
            if C.H.Allowed(f.NineSlice) then
                for _, art in ipairs(C.H.Regions(f.NineSlice)) do
                    if C.H.Texture(art) then C.H.Fade(art) end
                end
            end
            local thumb = f.GetThumbTexture and C.H.Texture(f:GetThumbTexture())
            if thumb and thumb.SetSize and f.GetOrientation and f:GetOrientation() == "HORIZONTAL" then
                thumb:SetSize(8, 14)
            end
            return true
        end
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("GTFO", DefineSkin)
else DefineSkin() end
