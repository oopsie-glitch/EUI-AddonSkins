local ADDON, ns = ...
-- Standalone skin addons receive their own namespace from WoW.
if ADDON ~= "EUIAddonSkins" then
    ns = EUIAddonSkins and EUIAddonSkins.GetSkinNamespace(ADDON)
    if not ns then return end
    ADDON = "EUIAddonSkins"
end

local function GUI() return _G.AtlasLoot and _G.AtlasLoot.GUI end
local function Favourites()
    local atlas = _G.AtlasLoot
    local addons = atlas and atlas.Addons
    if addons and type(addons.GetAddon) == "function" then return addons:GetAddon("Favourites") end
    return atlas and atlas.Favourites
end
local Visit
local function DropdownMenus(C, owner, refresh)
    if InCombatLockdown and InCombatLockdown() then refresh(); return end
    if not C.H.Allowed(owner) then return end
    -- Categories are pooled, but belong exclusively to AtlasLoot. Style them
    -- synchronously after its click handler, before their first rendered frame.
    for _, child in ipairs(C.H.Children(owner)) do
        local name = child.GetName and child:GetName() or ""
        if name:match("^AtlasLoot%-DropDown%-CatFrame") then
            C.Panel(child)
            C.H.Scan(child, refresh, function(f, kind) return Visit(C, f, kind, refresh) end)
        end
    end
end

Visit = function(C, f, kind, refresh)
    local H, S = C.H, C.S
    local name = f.GetName and f:GetName() or ""
    if GUI() and f == GUI().frame then
        -- The expansion logo is a foreground Texture on the main window itself.
        -- Retain that artwork while using EUI's fill, border and accent colours.
        H.ThinBackdrop(f)
        if f.SetBackdropBorderColor then f:SetBackdropBorderColor(0.055, 0.055, 0.055, 1) end
        C.borderLock = C.borderLock or {}
        H.Hook(f, "SetBackdropBorderColor", function(_, r, g, b)
            if C.borderLock[f] or r == 0.055 and g == 0.055 and b == 0.055 then return end
            if InCombatLockdown and InCombatLockdown() then refresh(); return end
            C.borderLock[f] = true
            f:SetBackdropBorderColor(0.055, 0.055, 0.055, 1)
            C.borderLock[f] = false
        end)
        if f.SetBackdropColor and S.GetPanelColor then f:SetBackdropColor(S.GetPanelColor()) end
        ns.AttachAccent(S, f)
        if H.Allowed(f.CloseButton) then S.CloseButton(f.CloseButton) end
        return true
    end
    if kind == "Slider" then
        H.LegacySlider(f)
        H.Script(f, "OnValueChanged", refresh)
        return true
    end
    if name:match("^AtlasLoot%-DropDown%-%d+$") then
        S.Dropdown(f)
        if H.Allowed(f.button) then
            S.SoftPageButton(f.button, "v")
        end
        if f.par then
            H.Hook(f.par, "SetSelected", refresh)
            H.Hook(f.par, "SetData", refresh)
            H.Hook(f.par, "Toggle", function() DropdownMenus(C, f, refresh); refresh() end)
        end
        local function Open() DropdownMenus(C, f, refresh); refresh() end
        H.Script(f, "OnClick", Open)
        H.Script(f.button, "OnClick", Open)
        DropdownMenus(C, f, refresh)
        H.Font(f.label); H.Font(f.title)
        return true
    end
    if name:match("^AtlasLoot%-DropDown%-CatFrame") then C.Panel(f) end
    if name:match("^AtlasLoot%-DropDown%-Button") then
        H.Action(f, {"icon", "check", "label"})
        if H.Texture(f.check) then f.check:SetVertexColor(S.GetAccentColor()) end
        H.Font(f.label)
        return true
    end
    if kind == "CheckButton" and f.obj and f.obj.frame == f:GetParent() and f.info and f.label then
        -- These are full-width selection rows, not small checkboxes.
        if not f.euiAtlasSelection then
            f.euiAtlasSelection = f:CreateTexture(nil, "BACKGROUND")
            f.euiAtlasSelection:SetAllPoints(f)
        end
        H.Action(f, {"icon", "coin", "label", "euiAtlasSelection"})
        if f.GetCheckedTexture then H.Fade(f:GetCheckedTexture()) end
        local r, g, b = S.GetAccentColor()
        f.euiAtlasSelection:SetColorTexture(r, g, b, f:GetChecked() and 0.2 or 0)
        H.Hook(f, "SetChecked", refresh)
        return true
    end
    if kind == "ScrollFrame" and f.obj and f.obj.frame == f then
        C.Panel(f)
        H.Hook(f.obj, "Update", refresh); H.Hook(f.obj, "SetSelected", refresh)
    end
    if kind == "Button" then
        if f.className then
            H.ThinBackdrop(f); H.Font(f.text)
            return true
        end
        if H.Icon(f) and f.overlay then
            -- Item-quality, completion, favourite and phase overlays carry data.
            -- Keep them, the item counts and AtlasLoot's item actions unchanged.
            for _, region in ipairs(H.Regions(f)) do H.Font(region) end
            return true
        end
        if name:match("%-nextPageButton$") then S.SoftPageButton(f, ">"); return true end
        if name:match("%-prevPageButton$") then S.SoftPageButton(f, "<"); return true end
        H.Resize(f)
    end
    local widget = f.obj
    if widget and widget.frame == f then
        if widget.closebtn and H.Allowed(widget.closebtn) then H.Action(widget.closebtn) end
        if widget.sizer_se then H.Resize(widget.sizer_se, true) end
        if widget.type == "TabGroup" then
            for _, tab in pairs(widget.tabs or {}) do
                if H.Allowed(tab) then H.Tab(tab, tab.selected and true or false) end
            end
            H.Hook(widget, "SelectTab", refresh)
        end
    end
end

ns.RegisterScopedSkin("AtlasLootContinued", "AtlasLootClassic Continued", {
    softBorders = true,
    available = function() return type(GUI()) == "table" end,
    preserveTextColors = true,
    roots = function(C)
        local roots = {}
        local function Add(frame, mode)
            if C.H.Allowed(frame) then roots[#roots + 1] = {frame = frame, mode = mode} end
        end
        Add(GUI() and GUI().frame, "controls")
        local favourites = Favourites()
        Add(favourites and favourites.GUI and favourites.GUI.frame)
        if LibStub then
            local dialog = LibStub("AceConfigDialog-3.0", true)
            local widget = dialog and dialog.OpenFrames and dialog.OpenFrames.AtlasLoot
            Add(widget and widget.frame)
        end
        return roots
    end,
    hooks = function(C, refresh)
        local H, gui = C.H, GUI()
        for _, name in ipairs({"Create", "Toggle", "RefreshStyle", "RefreshFonts", "ForceUpdate", "RefreshButtons"}) do
            H.Hook(gui, name, refresh)
        end
        H.Hook(gui and gui.ItemFrame, "Refresh", refresh)
        H.Hook(gui and gui.SoundFrame, "Show", refresh)
        local atlas = _G.AtlasLoot
        local favourites = Favourites()
        local favGUI = favourites and favourites.GUI
        for _, name in ipairs({"Create", "Toggle", "UpdateStyle", "UpdateDropDown", "ItemListUpdate", "SelectSlot"}) do
            H.Hook(favGUI, name, refresh)
        end
        H.Hook(atlas and atlas.Options, "Show", refresh)
        H.Hook(atlas and atlas.Options, "ShowAddon", refresh)
        if LibStub then
            local dialog = LibStub("AceConfigDialog-3.0", true)
            H.Hook(dialog, "FeedGroup", function(_, name) if name == "AtlasLoot" then refresh() end end)
        end
    end,
    visit = Visit,
})
