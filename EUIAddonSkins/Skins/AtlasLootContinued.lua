local ADDON, ns = ...
local function DefineSkin()

local function GUI() return _G.AtlasLoot and _G.AtlasLoot.GUI end
local function Classic()
    local gui = GUI()
    -- 13014 builds the Classic controls first, then applies either navigation
    -- look. GetStyle/GetLook are saved choices, not the UI currently displayed.
    return type(gui) == "table" and gui.frame ~= nil and not (gui.Nav and gui.Nav.active)
end
local function Favourites()
    local atlas = _G.AtlasLoot
    local addons = atlas and atlas.Addons
    if addons and type(addons.GetAddon) == "function" then return addons:GetAddon("Favourites") end
    return atlas and atlas.Favourites
end

-- Repaint only 13014's owned cosmetic layers; maps/models/item art never pass
-- through these helpers. Native alpha choices remain read-only.
local function Alpha(group, fallback)
    return group and group.bgColor and group.bgColor.a or fallback
end
local function Backdrop(C, f, alpha)
    local H, S = C.H, C.S
    if not H.Allowed(f) or not f.GetBackdrop or not f:GetBackdrop() or not S.GetPanelColor then return end
    H.ThinBackdrop(f)
    local backdrop = f:GetBackdrop()
    if backdrop.bgFile ~= "Interface/Buttons/WHITE8X8" then
        -- Keep the native bounds. Remove only the old tooltip/stone fill.
        backdrop.bgFile = "Interface/Buttons/WHITE8X8"
        f:SetBackdrop(backdrop)
    end
    local r,g,b,a = S.GetPanelColor()
    a = alpha or a
    local cr,cg,cb,ca = f:GetBackdropColor()
    if cr ~= r or cg ~= g or cb ~= b or ca ~= a then f:SetBackdropColor(r,g,b,a) end
    local br,bg,bb,ba = f:GetBackdropBorderColor()
    if br ~= .055 or bg ~= .055 or bb ~= .055 or ba ~= 1 then
        f:SetBackdropBorderColor(.055,.055,.055,1)
    end
end
local function Solid(C, texture, alpha, dirty)
    if not C.H.Texture(texture) or not C.S.GetPanelColor then return end
    local r,g,b,a = C.S.GetPanelColor()
    a = alpha or a
    if dirty or texture.euiAtlasR ~= r or texture.euiAtlasG ~= g
        or texture.euiAtlasB ~= b or texture.euiAtlasA ~= a then
        texture:SetColorTexture(r,g,b,a)
        texture.euiAtlasR,texture.euiAtlasG,texture.euiAtlasB,texture.euiAtlasA = r,g,b,a
    end
end
local function Surfaces(C)
    local gui = GUI()
    local frame = gui and gui.frame
    if not frame then return end
    local db = _G.AtlasLoot.db and _G.AtlasLoot.db.GUI or {}
    Backdrop(C, frame, Alpha(db.mainFrame))
    Backdrop(C, frame.titleFrame, Alpha(db.mainFrame and db.mainFrame.title))
    local content = frame.contentFrame
    if content then
        Solid(C, content.topBG, Alpha(db.contentTopBar), C.surfaceDirty)
        Solid(C, content.downBG, Alpha(db.contentBottomBar), C.surfaceDirty)
        -- Background images are optional native content, not obsolete decoration.
        if not (db.content and db.content.showBgImage and gui.curBgInfo and gui.curBgInfo[2]) then
            Solid(C, content.itemBG, Alpha(db.content), C.surfaceDirty)
        end
    end
    C.surfaceDirty = nil
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
            Backdrop(C, child)
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
        Surfaces(C)
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
        -- One native arrow button: avoid a second arrow on the field itself.
        S.Button(f, {"label", "title"})
        if f.GetBackdrop and f:GetBackdrop() then f:SetBackdrop(nil) end
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
    if name:match("^AtlasLoot%-DropDown%-CatFrame") then Backdrop(C, f) end
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
        local a = f:GetChecked() and 0.12 or 0
        if f.euiAtlasSelectedR ~= r or f.euiAtlasSelectedG ~= g or f.euiAtlasSelectedB ~= b or f.euiAtlasSelectedA ~= a then
            f.euiAtlasSelection:SetColorTexture(r,g,b,a)
            f.euiAtlasSelectedR,f.euiAtlasSelectedG,f.euiAtlasSelectedB,f.euiAtlasSelectedA = r,g,b,a
        end
        H.Hook(f, "SetChecked", refresh)
        return true
    end
    if kind == "ScrollFrame" and f.obj and f.obj.frame == f then
        Backdrop(C, f)
        H.Hook(f.obj, "Update", refresh); H.Hook(f.obj, "SetSelected", refresh)
    end
    if kind == "Button" then
        if f.className then
            S.Button(f, {"text"}); H.Font(f.text)
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
    active = Classic,
    setup = function(C, refresh)
        local gui = GUI()
        C.H.Hook(gui, "Create", refresh)
        C.H.Hook(gui and gui.Nav, "Revert", refresh)
    end,
    available = function() return type(GUI()) == "table" end,
    preserveTextColors = true,
    roots = function(C)
        local roots = {}
        local function Add(frame, mode)
            if C.H.Allowed(frame) then roots[#roots + 1] = {frame = frame, mode = mode} end
        end
        Add(GUI() and GUI().frame, "controls")
        local favourites = Favourites()
        local favGUI = favourites and favourites.GUI
        -- A late-created Favourites window can use the pending navigation
        -- choice even while the main window still displays Classic.
        if not (favGUI and favGUI.NavStyle and favGUI.NavStyle.applied) then
            Add(favGUI and favGUI.frame)
        end
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
        H.Hook(gui, "RefreshContentBackGround", function()
            C.surfaceDirty = true
            refresh()
        end)
        H.Hook(gui, "RefreshMainFrame", refresh)
        H.Hook(gui and gui.ItemFrame, "Refresh", refresh)
        H.Hook(gui and gui.SoundFrame, "Show", refresh)
        local atlas = _G.AtlasLoot
        local favourites = Favourites()
        local favGUI = favourites and favourites.GUI
        local function ClassicFavourites()
            return favGUI and not (favGUI.NavStyle and favGUI.NavStyle.applied)
        end
        H.Hook(favGUI, "Create", function() if ClassicFavourites() then refresh() end end)
        if favGUI and favGUI.frame and ClassicFavourites() then
            for _, name in ipairs({"Toggle", "UpdateStyle", "UpdateDropDown", "ItemListUpdate", "SelectSlot"}) do
                H.Hook(favGUI, name, function() if ClassicFavourites() then refresh() end end)
            end
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

end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("AtlasLootContinued", DefineSkin)
else DefineSkin() end
