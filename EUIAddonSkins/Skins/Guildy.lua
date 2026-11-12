local ADDON, ns = ...
local function DefineSkin()
local WHITE = "Interface\\Buttons\\WHITE8X8"
-- Guildy's own gold (UI/Widgets.lua W.GOLD[1]); a box border at or above 95% of it
-- marks a selected card/slot or a hovered control, anything dimmer is resting.
local GOLD_LIT = 0.79 * 0.95
local selected = setmetatable({}, {__mode = "k"})
local boxes = setmetatable({}, {__mode = "k"})
local groups = setmetatable({}, {__mode = "k"})

local function OwnedTab(tab)
    local name = tab and tab.GetName and tab:GetName()
    return name and (name:find("^GuildyFrameTab%d+$") or name:find("^GuildyOptionsTab%d+$")) and true or false
end
local function Tooltip(path)
    return type(path) == "string" and path:lower():find("ui%-tooltip%-border") ~= nil
end
-- Guildy's dark boxes (W.Box): keep the backdrop so its own border-colour
-- updates still show selection and hover, but redraw it as a flat EUI panel.
local function Box(C, f)
    local S = C.S
    local entry = boxes[f]
    if not entry then
        entry = {}; boxes[f] = entry
        entry.border = function(_, r, g, b)
            if entry.painting or not C.H.Allowed(f) then return end
            if r then entry.lit = r >= GOLD_LIT and (g or 0) >= GOLD_LIT * 0.8 and (b or 0) < r * 0.8 end
            entry.painting = true
            if entry.lit then local ar, ag, ab = S.GetAccentColor(); f:SetBackdropBorderColor(ar, ag, ab, 1)
            else f:SetBackdropBorderColor(0.055, 0.055, 0.055, 1) end
            entry.painting = false
        end
        C.H.Hook(f, "SetBackdropBorderColor", entry.border)
        C.H.Hook(f, "SetBackdrop", function(_, value)
            if value and value.edgeFile ~= WHITE and not entry.painting then C.H.Safe(Box, C, f) end
        end)
        local r, g, b = f:GetBackdropBorderColor()
        entry.lit = r ~= nil and r >= GOLD_LIT and (g or 0) >= GOLD_LIT * 0.8 and (b or 0) < r * 0.8
    end
    local backdrop = f:GetBackdrop()
    if backdrop and backdrop.edgeFile ~= WHITE then
        -- BackdropTemplateMixin:SetBackdrop resets the border to white through
        -- SetBackdropBorderColor; that reset is ours, not a Guildy highlight.
        entry.painting = true
        f:SetBackdrop({bgFile = WHITE, edgeFile = WHITE, edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}})
        entry.painting = false
    end
    local r, g, b = S.GetPanelColor()
    f:SetBackdropColor(math.min(r + 0.02, 1), math.min(g + 0.02, 1), math.min(b + 0.02, 1), 0.9)
    entry.border()
end
-- W.Segmented: the chosen option is its disabled button.
local function Segment(C, button)
    local H, S = C.H, C.S
    local on = button.IsEnabled and not button:IsEnabled()
    H.Selection(button, on)
    local label = button.GetFontString and button:GetFontString()
    if on then H.Font(label, 1, 1, 1) end
    if S.StateButtonLabel and not on then S.StateButtonLabel(button) end
end
-- The chat timeline rail (UI/ChatTimeline.lua): a 2px gold track plus a child
-- thumb button (black edge, gold fill, highlight). Returns its textures once found.
local rails = setmetatable({}, {__mode = "k"})
local function Rail(C, f)
    if rails[f] ~= nil then return rails[f] end
    local H, found = C.H, false
    local regions = H.Regions(f)
    local track = #regions == 1 and H.Texture(regions[1])
    if track and track:GetDrawLayer() == "BACKGROUND" and track:GetWidth() == 2 then
        for _, child in ipairs(H.Children(f)) do
            if H.Allowed(child) and child:GetObjectType() == "Button" then
                local layers = {}
                for _, region in ipairs(H.Regions(child)) do
                    if H.Texture(region) then layers[region:GetDrawLayer()] = region end
                end
                if layers.BACKGROUND and layers.ARTWORK and layers.HIGHLIGHT then
                    found = {track = track, fill = layers.ARTWORK, hover = layers.HIGHLIGHT, thumb = child}
                    break
                end
            end
        end
    end
    rails[f] = found
    return found
end
local function PaintRail(C, rail)
    local r, g, b = C.S.GetAccentColor()
    rail.track:SetColorTexture(r, g, b, 0.35)
    rail.fill:SetColorTexture(r, g, b, 1)
    rail.hover:SetColorTexture(1, 1, 1, 0.25)
end
local function SegmentGroup(button)
    local group = button.GetParent and button:GetParent()
    if type(group) == "table" and type(group.buttons) == "table" and type(group.SetValue) == "function" then
        for _, member in ipairs(group.buttons) do if member == button then return group end end
    end
end

ns.RegisterScopedSkin("Guildy", "Guildy", {
    softBorders = true, preserveTextColors = true, immediateShow = true,
    available = function() return SlashCmdList ~= nil and SlashCmdList.GUILDY ~= nil end,
    hooks = function(C, refresh)
        local H = C.H
        -- Guildy builds its window the first time Blizzard's guild window opens
        -- (Blizzard_Communities loads on demand) and lives inside it.
        H.Hook(_G, "ToggleGuildFrame", refresh)
        H.Hook(_G, "ToggleCommunitiesFrame", refresh)
        if _G.CommunitiesFrame then H.Script(_G.CommunitiesFrame, "OnShow", refresh) end
        H.Hook(_G, "PanelTemplates_SelectTab", function(tab)
            if OwnedTab(tab) then selected[tab] = true; H.Tab(tab, true) end
        end)
        H.Hook(_G, "PanelTemplates_DeselectTab", function(tab)
            if OwnedTab(tab) then selected[tab] = false; H.Tab(tab, false) end
        end)
    end,
    roots = function(C)
        local exclude = {}
        -- Blizzard's guild text editor is lent into Guildy's panels: never style it.
        local editor = _G.CommunitiesGuildTextEditFrame
        if editor and editor.Container then exclude[editor.Container] = true end
        local main = _G.GuildyFrame
        if main and main.Emblem then exclude[main.Emblem] = true end
        local result = {}
        for _, name in ipairs({"GuildyFrame", "GuildyOptions", "GuildyConfirm", "GuildyCopyBox"}) do
            local f = _G[name]
            if C.H.Allowed(f) then
                result[#result + 1] = {frame = f, exclude = exclude, options = {noAccent = true}}
            end
        end
        return result
    end,
    visit = function(C, f, kind, refresh)
        local H, S = C.H, C.S
        if f == _G.GuildyFrame or f == _G.GuildyOptions then
            -- Guildy draws the guild emblem over the portrait; drop only the ring art.
            local pc = f.PortraitContainer
            if pc and pc.GetRegions then
                local portrait = pc.portrait
                for _, region in ipairs(H.Regions(pc)) do
                    if region ~= portrait and H.Texture(region) then H.Fade(region) end
                end
            end
            return
        end
        if kind == "Button" and OwnedTab(f) then
            local value = selected[f]
            if value == nil then
                local owner = f.GetParent and f:GetParent()
                value = owner and owner.selectedTab ~= nil and f.GetID and owner.selectedTab == f:GetID() or false
            end
            return H.Tab(f, value)
        end
        if f.sideTab then return true end -- profession-style side tabs keep their native art
        if kind == "Frame" and f.GetBackdrop then
            local backdrop = f:GetBackdrop()
            if boxes[f] or backdrop and Tooltip(backdrop.edgeFile) then Box(C, f); return true end
        end
        if kind == "Button" then
            local main = _G.GuildyFrame
            if main and f == main.OptionsButton then
                S.Button(f, {"Icon"}); return true
            end
            local group = SegmentGroup(f)
            if group then
                if not groups[group] then
                    groups[group] = true
                    H.Hook(group, "SetValue", function()
                        for _, member in ipairs(group.buttons) do Segment(C, member) end
                    end)
                end
                Segment(C, f); return true
            end
            -- Only real template buttons are controls. Guildy's custom buttons are
            -- data: sort headers, overview cells, bar rows, cards and timeline marks.
            if not (f.GetFontString and f:GetFontString()) then
                local rail = Rail(C, f)
                if rail then PaintRail(C, rail); return true end
                -- The window's resize grip (W.ResizeGrip) is its only direct anonymous button.
                if main and f.GetParent and f:GetParent() == main then H.Resize(f) end
                return true
            end
        end
    end,
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("Guildy", DefineSkin)
else DefineSkin() end
