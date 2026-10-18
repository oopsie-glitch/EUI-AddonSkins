local ADDON, ns = ...
local function DefineSkin()
local context, looksBound
local fonts = setmetatable({}, {__mode = 'k'})
local menuOptions = {noAccent = true, chevrons = true, hoverAlpha = 0.25}
local headingKeys = {'Kiwi Farm [/kfarm]', 'Statistics', 'Settings'}
local headingLabels = {}
local function StatsFont(S, text)
    if not text or not text.GetFont or not text.SetFont then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local path, size, flags = text:GetFont()
    if not path then return end
    local target = S.GetFont()
    local state = fonts[text]
    if not state then state = {}; fonts[text] = state end
    if path ~= target or (flags or '') ~= '' then state.native = {path, size, flags} end
    if context and not ns.IsEnabled(context.module) then
        if state.native then
            state.busy = true; text:SetFont((unpack or table.unpack)(state.native)); state.busy = false
        end
        return
    end
    if path ~= target or (flags or '') ~= '' then
        state.busy = true; text:SetFont(target, size, ''); state.busy = false
    end
end
menuOptions.isHeading = function(button, text)
    if button.isTitle then return true end
    if not text or not text.GetText then return false end
    return headingLabels[text:GetText()] == true
end
ns.RegisterScopedSkin("KiwiFarm", "KiwiFarm", {
    softBorders = true,
    available = function() return _G.KiwiFarm ~= nil end,
    panels = false,
    roots = function() return ns.SkinRoots({"KiwiFarm"}, {noTopBar = true, noAccent = true}) end,
    font = StatsFont,
    hooks = function(C)
        context = C
        local locale = LibStub and LibStub('AceLocale-3.0', true)
        local labels = locale and locale.GetLocale and locale:GetLocale('KiwiFarm', true)
        for _, key in ipairs(headingKeys) do headingLabels[labels and labels[key] or key] = true end
        local function Bind(owner)
            if ns.BindPopupOwner then ns.BindPopupOwner(C.S, C.module, owner, menuOptions)
            else C.MenuOwner(owner) end
        end
        local function MenuReady()
            Bind(_G.KiwiFarmPopupMenu)
            -- KiwiFarm can create a launcher on each open. Prefer the actual
            -- renderer owner if its named global still refers to another one.
            local list = _G.DropDownList1
            local owner = list and list.dropdown
            if list and list.IsShown and list:IsShown() and C.H.Allowed(owner)
                and owner.GetName and owner:GetName() == "KiwiFarmPopupMenu" then
                Bind(owner)
            end
            -- Registration only repaints changed bindings. Reopening an
            -- unchanged owner still needs a completed native-render pass.
            if ns.RefreshPopupMenusNow then ns.RefreshPopupMenusNow() end
        end
        Bind(_G.KiwiFarmPopupMenu)
        C.H.Hook(_G.KiwiFarm, "ShowMenu", MenuReady)
        -- Native LayoutFrame reapplies its outlined fonts. Repair only these
        -- two labels after SetFont; never scan on SetText or the stats timer.
        for _, text in ipairs({_G.KiwiFarm:GetRegions()}) do
            if text.GetObjectType and text:GetObjectType() == 'FontString' then
                StatsFont(C.S, text)
                C.H.Hook(text, 'SetFont', function()
                    local state = fonts[text]
                    if not state or not state.busy then StatsFont(C.S, text) end
                end)
            end
        end
        if not looksBound and C.S.OnLooksChanged then
            looksBound = true
            C.S.OnLooksChanged(function() for text in pairs(fonts) do StatsFont(C.S, text) end end)
        end
        -- Shared popup combat recovery handles the menu itself. No guide/main
        -- frame discovery is needed for menu opens or combat-end callbacks.
    end,
    -- KiwiFarm's native whole-frame alpha/visibility still controls its shell.
    -- Shared Blizzard StaticPopup frames retain their existing styling.
})

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("KiwiFarm", DefineSkin)
else DefineSkin() end
