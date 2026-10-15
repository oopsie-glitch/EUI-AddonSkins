local ADDON, ns = ...
-- Standalone skin addons receive their own namespace from WoW.
if ADDON ~= "EUIAddonSkins" then
    ns = EUIAddonSkins and EUIAddonSkins.GetSkinNamespace(ADDON)
    if not ns then return end
    ADDON = "EUIAddonSkins"
end
local trackerFonts, wrapped = {}, {}
local function TrackerFont(C, text)
    local H, S = C.H, C.S
    if not H.Allowed(text) or text:GetObjectType() ~= "FontString" then return end
    local Paint = trackerFonts[text]
    if not Paint then
        local painting = false
        Paint = function()
            if painting then return end
            if InCombatLockdown and InCombatLockdown() then C.module.refresh(); return end
            local path, flags
            if S.GetFont then path, flags = S.GetFont() end
            local current, _, currentFlags = text:GetFont()
            if path and current == path and (currentFlags or "") == (flags or "") then return end
            painting = true
            H.Safe(function() H.Font(text) end)
            painting = false
        end
        trackerFonts[text] = Paint
        H.Hook(text, "SetFont", Paint)
        H.Hook(text, "SetFontObject", Paint)
    end
    Paint()
end

local function Module(name)
    local loader = _G.QuestieLoader
    -- ImportModule creates missing modules. Read the existing registry only.
    local modules = type(loader) == "table" and loader._modules
    return type(modules) == "table" and modules[name] or nil
end
local function Frame(widget)
    local kind = type(widget)
    if kind == "table" or kind == "userdata" then return widget.frame or widget end
end
local function Menus(C)
    for _, name in ipairs({"QuestieTrackerMenuFrame", "QuestieTownsfolkMenuFrame",
        "QuestieTownsfolkMenuFrameTownsfolk", "QuestieTownsfolkMenuFrameProfs", "QuestieTownsfolkMenuFrameVendors"}) do
        if C.H.Allowed(_G[name]) then C.MenuOwner(_G[name]) end
    end
    if ns.RefreshPopupMenusNow then ns.RefreshPopupMenusNow() end
end
local function QuestToggle(C, button)
    local H = C.H
    if not H.Allowed(button) then return end
    local function Paint()
        if InCombatLockdown and InCombatLockdown() then C.module.refresh(); return end
        H.Toggle(button, button.mode == 1)
        local art = H.Texture(button.texture)
        if art then H.Fade(art) end
    end
    Paint()
    H.Hook(button, "SetMode", Paint)
end
local function TreeToggle(C, button)
    local H = C.H
    if not H.Allowed(button) then return end
    local function Paint()
        if InCombatLockdown and InCombatLockdown() then C.module.refresh(); return end
        local art = button.GetNormalTexture and H.Texture(button:GetNormalTexture())
        local path = art and art:GetTexture()
        H.Toggle(button, path == 130821 or (type(path) == "string" and path:lower():find("minusbutton") ~= nil))
    end
    Paint()
    H.Hook(button, "SetNormalTexture", Paint)
end
local function Tracker(C)
    local H, S = C.H, C.S
    local base = _G.Questie_BaseFrame
    if not H.Allowed(base) then return end
    -- Keep Questie's background opacity, movement, resizing and fade behaviour.
    H.ThinBackdrop(base)
    ns.AttachAccent(S, base)
    if H.Allowed(base.sizer) then H.Resize(base.sizer, true) end
    local function walk(f, depth)
        if depth > 16 or not H.Allowed(f) or (f.IsShown and not f:IsShown()) then return end
        -- Zone toggles cover the whole heading; only quest toggles have icons.
        QuestToggle(C, f.expandQuest)
        for _, region in ipairs(H.Regions(f)) do TrackerFont(C, region) end
        for _, child in ipairs(H.Children(f)) do walk(child, depth + 1) end
    end
    walk(base, 0)
    local header = _G.Questie_HeaderFrame
    if H.Allowed(header) then
        local r, g, b = S.GetAccentColor()
        local label = header.trackedQuests and header.trackedQuests.label
        TrackerFont(C, label)
        if H.Allowed(label) then label:SetTextColor(r, g, b) end
        local button = header.questieIcon
        local icon = button and H.Texture(button.texture)
        if H.Allowed(button) and icon then S.SquareIcon(icon) end
    end
    -- SecureActionButtonTemplate quest-item buttons are UIParent-owned and are
    -- deliberately never discovered or modified by this skin.
end

ns.RegisterScopedSkin("Questie", "Questie", {
    softBorders = true,
    available = function() return _G.Questie ~= nil and Module("QuestieJourney") ~= nil end,
    preserveTextColors = true,
    roots = function(C)
        Tracker(C); Menus(C)
        local result = {}
        local function Add(widget)
            local f = Frame(widget)
            if C.H.Allowed(f) then result[#result + 1] = {frame = f, options = {bottomBar = 24, noTopBar = true}} end
        end
        Add(_G.QuestieJourneyFrame); Add(_G.QuestieConfigFrame)
        local journey = Module("QuestieJourney")
        Add(journey and journey.private and journey.private.notePopup)
        if LibStub then
            local dialog = LibStub("AceConfigDialog-3.0", true)
            Add(dialog and dialog.OpenFrames and dialog.OpenFrames.Questie)
        end
        return result
    end,
    hooks = function(C, refresh)
        local H = C.H
        -- GetNextLine returns before Questie chooses a row font and measures it.
        -- Lua wrappers preserve coroutine boundaries and all native return values.
        local pool = Module("TrackerLinePool")
        if pool and type(pool.GetNextLine) == "function" and not wrapped[pool] then
            wrapped[pool] = true
            local original = pool.GetNextLine
            local function After(...)
                local line = ...
                if ns.IsEnabled(C.module) and H.Allowed(line) then
                    H.Safe(function() TrackerFont(C, line.label); QuestToggle(C, line.expandQuest) end)
                end
                return ...
            end
            pool.GetNextLine = function(...) return After(original(...)) end
        end
        local headerModule = Module("TrackerHeaderFrame")
        if headerModule and type(headerModule.Update) == "function" and not wrapped[headerModule] then
            wrapped[headerModule] = true
            local original = headerModule.Update
            headerModule.Update = function(...)
                if ns.IsEnabled(C.module) then
                    local header = _G.Questie_HeaderFrame
                    H.Safe(function() TrackerFont(C, header and header.trackedQuests and header.trackedQuests.label) end)
                end
                return original(...)
            end
        end
        local journey, options = Module("QuestieJourney"), Module("QuestieOptions")
        for _, name in ipairs({"BuildMainFrame", "ToggleJourneyWindow"}) do H.Hook(journey, name, refresh) end
        H.Hook(journey and journey.private, "HandleTabChange", refresh)
        H.Hook(journey and journey.private, "ShowNotePopup", refresh)
        H.Hook(Module("QuestDetailsFrame"), "Draw", refresh)
        H.Hook(options, "ToggleConfigWindow", refresh)
        if LibStub then
            local dialog = LibStub("AceConfigDialog-3.0", true)
            H.Hook(dialog, "FeedGroup", function(_, name) if name == "Questie" then refresh() end end)
        end
        local function UpdateTracker()
            local base = _G.Questie_BaseFrame
            if H.Allowed(base) then
                H.Queue(base, function()
                    if InCombatLockdown and InCombatLockdown() then refresh() else Tracker(C) end
                end)
            else refresh() end
        end
        -- Questie's coroutine-based initialization must not cross the C boundary
        -- introduced by hooksecurefunc. Discover frames after initialization.
        for _, name in ipairs({"Update", "UpdateFormatting", "Show", "Expand", "Collapse"}) do
            H.Hook(Module("QuestieTracker"), name, UpdateTracker)
        end
        H.Hook(Module("TrackerHeaderFrame"), "Update", UpdateTracker)
        local menu = Module("QuestieMenu")
        for _, name in ipairs({"Show", "ShowTownsfolk", "ShowProfessions", "ShowVendors"}) do
            H.Hook(menu, name, function() Menus(C) end)
        end
    end,
    visit = function(C, f, kind, refresh)
        local H, S = C.H, C.S
        if kind == "Button" and f.treeline and H.Allowed(f.toggle) then
            TreeToggle(C, f.toggle)
            H.Font(f.text)
            return true
        end
        if kind == "Slider" then H.LegacySlider(f); return true end
        local widget = f.obj
        if widget and widget.frame == f then
            if widget.type == "Dropdown" and H.Allowed(widget.dropdown) then
                -- AceGUI offsets compensate for Blizzard's transparent borders.
                -- EUI fills the entire frame, so those offsets must be removed.
                local function Align()
                    if InCombatLockdown and InCombatLockdown() then refresh(); return end
                    local label = widget.label
                    local y = label and label.IsShown and label:IsShown() and -14 or 0
                    widget.dropdown:ClearAllPoints()
                    widget.dropdown:SetPoint("TOPLEFT", f, "TOPLEFT", 0, y)
                    widget.dropdown:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
                    if H.Allowed(widget.button) then
                        widget.button:ClearAllPoints()
                        widget.button:SetPoint("RIGHT", widget.dropdown, "RIGHT", -2, 0)
                        for _, art in ipairs(H.Regions(widget.button)) do if H.Texture(art) then H.Fade(art) end end
                    end
                    if widget.text then
                        widget.text:ClearAllPoints()
                        widget.text:SetPoint("LEFT", widget.dropdown, "LEFT", 8, 2)
                        widget.text:SetPoint("RIGHT", widget.dropdown, "RIGHT", -26, 2)
                    end
                end
                Align(); H.Hook(widget, "SetLabel", Align)
            end
            if widget.type == "TabGroup" then
                for _, tab in pairs(widget.tabs or {}) do
                    if H.Allowed(tab) then H.Tab(tab, tab.selected and true or false) end
                end
                H.Hook(widget, "SelectTab", refresh)
            end
            if widget.closebtn and H.Allowed(widget.closebtn) then
                S.Button(widget.closebtn); if S.StateButtonLabel then S.StateButtonLabel(widget.closebtn) end
            end
            if widget.sizer_se and H.Allowed(widget.sizer_se) then H.Resize(widget.sizer_se, true) end
        end
    end,
})
