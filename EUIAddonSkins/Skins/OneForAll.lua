local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("OneForAll", "OneForAll", function()
    return _G.OneForAll and _G.OneForAll.UI
end, function(S, module)
    local A, UI = _G.OneForAll, _G.OneForAll.UI
    local H = ns.CreateSkinHelper(S, module)
    local soft = ns.CreateSoftSkin(S, module)
    local unpack = unpack or table.unpack
    local nodes, fonts, colours, kept, flattened, windows = {}, {}, {}, {}, {}, {}
    local pending, deferred, busy, depth = {}, {}, false, 0
    local windowNames, trusted = {}, {}
    local excludedNames = {OneForAllMinimapCollectorBar=true, OneForAllMinimapCollector=true,
        OneForAllBuffReminder=true, OneForAllLootFeed=true, OneForAllChatHideButton=true,
        OneForAllDungeonMapKey=true}
    for _, suffix in ipairs({"Frame", "Confirm", "BugReport", "Discord", "CraftList", "ProfilePopup", "QuestChain", "WeightEditor", "TrainerSpells", "TalentCode", "Welcome", "WhatsNew", "PreviewFrame", "QuestSharePopup", "CopyChat", "BagsFull", "NearbyAlert"}) do
        windowNames["OneForAll"..suffix] = true
    end
    local Walk, Flush, Queue, Window
    local layoutFont, layoutFlags
    local function Ready()
        if not ns.IsEnabled(module) then return false end
        if InCombatLockdown and InCombatLockdown() then busy = true; return false end
        return true
    end
    local function Owned(f)
        local p = f
        for _ = 1, 40 do
            if not H.Allowed(p) or p == UIParent then return false end
            local name = p.GetName and p:GetName()
            if excludedNames[name] then return false end
            if p == UI.mainWindow or windows[p] or trusted[p] or windowNames[name] then return true end
            p = p.GetParent and p:GetParent()
        end
        return false
    end
    local function Asset(t)
        local path = t.GetTexture and t:GetTexture()
        return type(path) == "string" and path:lower():gsub("/", "\\"):match("\\oneforall\\assets\\([^\\]+)")
    end
    local function State(f)
        if not nodes[f] then nodes[f] = {} end
        return nodes[f]
    end
    local function Semantic(t)
        local f = t.GetParent and t:GetParent()
        return f and (t == f.rank or t == f.skill or t == f.tag or t == f.level or t == f.count
            or t == f.status or t == f.name)
    end
    local function Quality(r, g, b)
        for _, c in pairs(ITEM_QUALITY_COLORS or {}) do
            if c.r and math.abs(c.r-r) < .00001 and math.abs(c.g-g) < .00001 and math.abs(c.b-b) < .00001 then return true end
        end
        for _, c in pairs(RAID_CLASS_COLORS or {}) do
            if c.r and math.abs(c.r-r) < .00001 and math.abs(c.g-g) < .00001 and math.abs(c.b-b) < .00001 then return true end
        end
    end
    local function Font(t, neutral)
        if not H.Allowed(t) or t:GetObjectType() ~= "FontString" then return end
        local d = fonts[t]
        if not d then
            d = {}; fonts[t] = d
            d.paint = function()
                if d.painting or not Ready() then return end
                d.painting = true
                local face, _, flags = t:GetFont()
                local path, style = S.GetFont()
                if face ~= path or (flags or "") ~= (style or "") then S.Font(t) end
                -- Only decorative text loses the warm palette. Inline item,
                -- class and status colour escapes and semantic fields stay native.
                if d.control and d.control.IsEnabled and not d.control:IsEnabled() then
                    t:SetTextColor(.45, .45, .47)
                elseif d.neutral and not Semantic(t) then
                    local r, g, b, a = t:GetTextColor()
                    if not Quality(r, g, b) and r > .7 and g > .35 and b < g * .95 then t:SetTextColor(.91, .91, .93, a) end
                end
                d.painting = nil
            end
            H.Hook(t, "SetFont", d.paint); H.Hook(t, "SetTextColor", d.paint)
        end
        if neutral then d.neutral = true end
        d.paint()
    end
    local function Keep(t)
        if not H.Texture(t) or kept[t] then return end
        local alpha = t:GetAlpha(); kept[t] = alpha
        local painting
        H.Hook(t, "SetAlpha", function(_, a)
            if painting or not Ready() then return end
            if a > 0 then alpha = a; kept[t] = a; return end
            if a == alpha then return end
            painting = true; t:SetAlpha(alpha); painting = nil
        end)
        t:SetAlpha(alpha)
    end
    -- Reuse native colourable decoration, preserving its alpha/visibility and
    -- semantic state colours. Never change SkinC or the gameplay colour tables.
    local function Colour(t, role, r, g, b, a)
        if not H.Texture(t) then return end
        local d = colours[t]
        if not d then
            d = {role = role}; colours[t] = d
            d.paint = function()
                if d.painting or not Ready() then return end
                d.painting = true
                local cr, cg, cb, ca = d.r or 1, d.g or 1, d.b or 1, d.a or 1
                if d.role == "accent" then cr, cg, cb = S.GetAccentColor()
                elseif d.role == "selection" then cr, cg, cb = S.GetAccentColor(); ca = ca * .18
                elseif d.role == "surface" then
                    -- Quest-chain done/in-log fills and learned pet ranks are
                    -- data, even when the in-log colour is itself gold.
                    local status = (cr == .035 and cg == .16 and cb == .055)
                        or (cr == .22 and cg == .17 and cb == .04)
                        or (cr == .05 and cg == .15 and cb == .07)
                    if not status then cr, cg, cb = S.GetPanelColor() end
                elseif d.role == "line" then cr, cg, cb = .22, .22, .24
                elseif d.role == "white" then cr, cg, cb = .8, .8, .82
                elseif d.role == "border" then
                    -- Normal card chrome is neutral; a native quality/class/
                    -- quest-state colour supplied later remains authoritative.
                    local warm = not Quality(cr, cg, cb) and cr > cg and cg > cb and cb < .4
                    if warm and cr > .7 then cr, cg, cb = S.GetAccentColor()
                    elseif warm then cr, cg, cb = .2, .2, .22 end
                end
                local vr, vg, vb, va = t:GetVertexColor()
                if vr ~= cr or vg ~= cg or vb ~= cb or va ~= ca then t:SetVertexColor(cr, cg, cb, ca) end
                d.painting = nil
            end
            H.Hook(t, "SetVertexColor", function(_, nr, ng, nb, na)
                if d.painting then return end
                d.r, d.g, d.b, d.a = nr, ng, nb, na or 1
                d.paint()
            end)
        end
        d.role = role
        d.r, d.g, d.b, d.a = r or 1, g or 1, b or 1, a or 1
        d.paint()
    end
    local function Pieces(rr, anchor, role)
        if type(rr) ~= "table" or type(rr.pieces) ~= "table" or flattened[rr] then return end
        flattened[rr] = true
        local p = rr.pieces
        if role == "border" then
            -- Reuse four of the native nine-slice regions as thin straight edges.
            for i, t in ipairs(p) do
                if i <= 4 then
                    t:SetTexture("Interface\\Buttons\\WHITE8X8"); t:SetTexCoord(0, 1, 0, 1); t:ClearAllPoints()
                    local side = ({"TOP", "BOTTOM", "LEFT", "RIGHT"})[i]
                    if i <= 2 then t:SetPoint(side.."LEFT", anchor, side.."LEFT"); t:SetPoint(side.."RIGHT", anchor, side.."RIGHT"); t:SetHeight(1)
                    else t:SetPoint("TOP"..side, anchor, "TOP"..side); t:SetPoint("BOTTOM"..side, anchor, "BOTTOM"..side); t:SetWidth(1) end
                    Colour(t, role, t:GetVertexColor())
                else H.Fade(t) end
            end
        else
            local t = p[#p]
            t:SetTexture("Interface\\Buttons\\WHITE8X8"); t:SetTexCoord(0, 1, 0, 1)
            t:ClearAllPoints(); t:SetAllPoints(anchor)
            Colour(t, role, t:GetVertexColor())
            for _, other in ipairs(p) do if other ~= t then H.Fade(other) end end
        end
    end
    local function Card(card, anchor)
        if not card then return end
        Pieces(card.fill, anchor, "surface"); Pieces(card.border, anchor, "border")
        H.Hook(card, "SetSelected", function(_, selected)
            if not Ready() then return end
            if card.fill and card.fill.pieces then
                for _, t in ipairs(card.fill.pieces) do
                    local d = colours[t]
                    if d then d.role = selected and "selection" or "surface"; d.paint() end
                end
            end
        end)
    end
    local function Decorative(t)
        if not H.Texture(t) then return end
        local name = Asset(t)
        if not name then return end
        name = name:gsub("%.tga$", "")
        if name == "glow_line" then
            -- The native visibility remains the selected-state indicator.
            t:SetColorTexture(1, 1, 1, 1)
            Colour(t, "accent")
            local f = t:GetParent()
            t:ClearAllPoints(); t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 0)
            t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 0); t:SetHeight(1)
        elseif name == "divider_plain" or name == "divider_ornate" then
            t:SetDesaturated(true); Colour(t, "line")
        elseif name == "talent_frame" then
            t:SetTexture("Interface\\Common\\WhiteIconFrame")
            Colour(t, "border", t:GetVertexColor())
        elseif name == "talent_glow" then Colour(t, "accent", t:GetVertexColor())
        elseif name == "tab_icons" or name == "grip_resize" or name == "grip_height"
            or name == "icon_close" or name == "icon_bug" or name == "icon_chat"
            or name == "chevron" or name == "icon_arrow_down" or name == "icon_back" then
            -- Monochrome control glyphs, not map/faction/status illustrations.
            Keep(t); t:SetDesaturated(true); Colour(t, "white")
        elseif name == "ring_gold" or name == "ring_silver" or name == "ring_plain"
            or name == "frame_boss2" or name == "frame_badge" or name == "gem_rim" then
            t:SetDesaturated(true); Colour(t, "white")
        elseif name == "window_ring" or name == "modern_frame" or name == "window_frame"
            or name == "corner_glow" or name == "edge_fade" or name == "line_cap" then H.Fade(t) end
    end
    local function Button(f)
        if not H.Allowed(f) then return end
        local d = State(f)
        if not d.button then
            d.button = true
            -- The public Tab primitive mirrors labels at a fixed size/centre;
            -- retain this addon's icon/label layout and reuse its active plate
            -- as the one-pixel indicator instead.
            for _, t in ipairs(H.Regions(f)) do
                if Asset(t) == "btn_m_active" and t:GetDrawLayer() ~= "HIGHLIGHT" and not f.euiOfaSelection then
                    f.euiOfaSelection = t
                    t:SetColorTexture(1, 1, 1, 1); t:ClearAllPoints()
                    t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 0); t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 0)
                    t:SetHeight(1); t:SetDrawLayer("OVERLAY", 6); Colour(t, "accent")
                end
            end
            local keys = {"icon", "Icon", "glyph", "check", "del", "euiOfaSelection", "euiOfaChevron"}
            -- Retain native state regions; all redundant plates/glows are faded.
            for _, t in ipairs(H.Regions(f)) do
                if colours[t] and (colours[t].role == "accent" or colours[t].role == "selection") then
                    local key = "euiOfaKeep"..#keys; f[key] = t; keys[#keys+1] = key
                end
            end
            soft.Button(f, keys)
            local label = f._label or f.text or (f.GetFontString and f:GetFontString())
            Font(label, true)
            if fonts[label] then
                fonts[label].control = f
                for _, method in ipairs({"SetEnabled", "Enable", "Disable"}) do H.Hook(f, method, fonts[label].paint) end
            end
        end
    end
    local function Check(f)
        local d = State(f)
        if d.check then return end
        d.check = true
        -- OneForAll's 42px switch hit box is kept. Only its visible art is
        -- replaced with the accepted compact square, centred in the same space.
        for _, t in ipairs(H.Regions(f)) do if H.Texture(t) then H.Fade(t) end end
        local host = CreateFrame("Frame", nil, f); host:SetSize(22, 22); host:SetPoint("CENTER"); host:EnableMouse(false)
        soft.Checkbox(host, {borderInset = 4, hover = .06})
        local mark = host:CreateTexture(nil, "OVERLAY"); mark:SetSize(8, 8); mark:SetPoint("CENTER")
        d.mark = mark
        d.paintCheck = function()
            if not Ready() then return end
            local r, g, b = S.GetAccentColor()
            if d.r ~= r or d.g ~= g or d.b ~= b then mark:SetColorTexture(r, g, b, 1); d.r, d.g, d.b = r, g, b end
            local checked = f:GetChecked() and true or false
            if mark:IsShown() ~= checked then mark:SetShown(checked) end
        end
        for _, name in ipairs({"SetChecked", "SetEnabled", "Enable", "Disable", "Paint"}) do H.Hook(f, name, d.paintCheck) end
        H.Script(f, "PostClick", d.paintCheck)
        d.paintCheck()
    end
    local function WindowArt(f, t)
        if not H.Texture(t) then return end
        local path = Asset(t)
        local native = t:GetTexture()
        if (path and (path:find("banner", 1, true) or path:find("logo", 1, true)
                or path:find("preview_", 1, true) or path == "minimap_icon"
                or (f == UI.mainWindow and path == "shade_lr")))
            or t == UI.brandLogo or t == f.pic or t == f.icon or t == f.arrow
            or (type(native) == "string" and (native:find("Interface\\Icons\\", 1, true)
                or native:find("UI-Dialog-Icon-Alert", 1, true))) then
            Keep(t)
        end
    end
    local function SkinNode(f)
        if not H.Allowed(f) then return end
        local d = State(f)
        if d.seen then return end
        d.seen = true
        local kind = f:GetObjectType()
        if f == UI.mainWindow then
            for _, t in ipairs(H.Regions(f)) do
                if H.Texture(t) and not Asset(t) and t:GetHeight() == 1 and t:GetDrawLayer() ~= "BACKGROUND" then
                    t:SetColorTexture(1, 1, 1, 1); Colour(t, "line")
                end
            end
        end
        if kind == "PlayerModel" or kind == "ModelScene" or kind == "GameTooltip" then return end
        if kind == "CheckButton" then Check(f)
        elseif kind == "EditBox" then
            -- No padding/position writes: native numeric validation and layout
            -- belong to OneForAll. EUI supplies the input surface and border.
            S.EditBox(f)
        elseif kind == "Slider" then
            if f.GetOrientation and f:GetOrientation() == "VERTICAL" then S.ScrollBar(f)
            elseif not d.grip then H.LegacySlider(f) end
        elseif kind == "Button" and (f._label or (f.check and f.del)) and not (f.slot or f.itemID or f.itemId) then
            if f.check and f.del then f.check:SetColorTexture(1, 1, 1, 1); Colour(f.check, "accent") end
            Button(f)
        end
        if f.ScrollBar and H.Allowed(f.ScrollBar) then S.ScrollBar(f.ScrollBar) end
        for _, t in ipairs(H.Regions(f)) do
            if t:GetObjectType() == "FontString" then Font(t, true) else Decorative(t) end
        end
        -- Discovery happens only on new art/control construction. Warm shows,
        -- scrolls and gameplay refreshes never traverse the known subtree.
        H.Hook(f, "CreateTexture", function() Queue(f) end)
        H.Hook(f, "CreateFontString", function() Queue(f) end)
        -- Only flush newly constructed work after native interaction callbacks;
        -- a warm click/show/scroll with no new objects does no tree walk.
        for _, script in ipairs({"OnClick", "OnShow", "OnVerticalScroll"}) do
            H.Script(f, script, function() if next(pending) then Flush() end end)
        end
    end
    Walk = function(f, level)
        if not H.Allowed(f) or (level or 0) > 24 then return end
        local kind = f:GetObjectType()
        if kind == "GameTooltip" or kind == "PlayerModel" or kind == "ModelScene" then return end
        SkinNode(f)
        for _, t in ipairs(H.Regions(f)) do
            if t:GetObjectType() == "FontString" then Font(t, true)
            else
                if windows[f] then WindowArt(f, t) end
                Decorative(t)
            end
        end
        for _, child in ipairs(H.Children(f)) do Walk(child, (level or 0)+1) end
    end
    Queue = function(f)
        if not H.Allowed(f) or not Owned(f) then return end
        local kind = f:GetObjectType()
        if kind == "FontString" then Font(f, true); return end
        if kind == "Texture" then Decorative(f); return end
        if not f.GetChildren or not f.GetRegions then return end
        pending[f] = true
        if depth > 0 then return end
        H.Queue(module, function() Flush() end)
    end
    local function Layout()
        if not UI.mainWindow or not UI.LayoutTabs then return end
        local path, flags = S.GetFont()
        if path ~= layoutFont or flags ~= layoutFlags then
            layoutFont, layoutFlags = path, flags
            UI.LayoutTabs() -- native ContentWidth spacing follows the new font
        end
    end
    Flush = function()
        if not Ready() then return end
        local work = pending; pending = {}
        -- A completed ancestor covers child construction in the same burst.
        for f in pairs(work) do
            local p, covered = f.GetParent and f:GetParent(), false
            for _ = 1, 40 do
                if not p then break end
                if work[p] then covered = true; break end
                p = p.GetParent and p:GetParent()
            end
            if not covered then
                if f.GetName and windowNames[f:GetName()] then Window(f) end
                Walk(f)
            end
        end
        Layout()
    end
    Window = function(f)
        if not H.Allowed(f) or not Owned(f) or windows[f] then return end
        windows[f] = true
        local keep, before = {}, {}
        for _, t in ipairs(H.Regions(f)) do
            before[t] = true
            WindowArt(f, t)
            if kept[t] then keep[t] = kept[t] end
        end
        S.Shell(f, {noTopBar = true})
        if f.SetBackdrop then f:SetBackdrop(nil) end
        if f.NineSlice then S.FadeNineSlice(f.NineSlice) end
        if f.Inset then S.Inset(f.Inset) end
        if f ~= UI.mainWindow and H.Allowed(f.CloseButton) and f.CloseButton:IsShown() and S.CloseButton then S.CloseButton(f.CloseButton) end
        for t, alpha in pairs(keep) do t:SetAlpha(alpha) end
        -- Native opacity only affects shell textures, never labels or artwork.
        local alpha = UI.GetWindowAlpha and UI.GetWindowAlpha() or 1
        if f == UI.mainWindow then
            local shell = {}
            for _, t in ipairs(H.Regions(f)) do if H.Texture(t) and not before[t] and t:GetDrawLayer() == "BACKGROUND" then shell[#shell+1] = t end end
            local function Opacity()
                if not Ready() then return end
                alpha = UI.GetWindowAlpha and UI.GetWindowAlpha() or 1
                for _, t in ipairs(shell) do if t:GetAlpha() ~= alpha then t:SetAlpha(alpha) end end
            end
            for _, t in ipairs(shell) do
                local painting
                H.Hook(t, "SetAlpha", function(_, value)
                    if painting or not Ready() or value == alpha then return end
                    painting = true; t:SetAlpha(alpha); painting = nil
                end)
            end
            State(f).opacity = Opacity
            H.Hook(UI, "ApplyWindowAlpha", Opacity); Opacity()
        end
        Queue(f)
    end
    -- Return-preserving wrappers are scoped to OneForAll's own constructors.
    -- Native functions run directly (never under pcall or secure post-hooks):
    -- ShowNews/ShowWelcome are also passed to C_Timer and are left untouched.
    local function Wrap(object, name, after, delayed)
        local original = object[name]
        if type(original) ~= "function" then return end
        object[name] = function(...)
            local first = ...
            -- Private anonymous dropdown/popup roots opt in at their own panel
            -- constructor. Other helper calls still need a known owned ancestor.
            if name == "FramedPanel" and H.Allowed(first) and first:GetParent() == UIParent
                and not first:GetName() then trusted[first] = true end
            if H.Allowed(first) and not Owned(first) then return original(...) end
            if not Ready() then
                local f = ...
                if busy and H.Allowed(f) and f ~= UIParent then deferred[f] = true end
                return original(...)
            end
            depth = depth + 1
            local function Pack(...) return {n = select("#", ...), ...} end
            local result = Pack(original(...))
            H.Safe(after, result, ...)
            depth = depth - 1
            if depth == 0 then
                if delayed then
                    if next(pending) then H.Queue(module, function() Flush() end) end
                else Flush() end
            end
            return unpack(result, 1, result.n)
        end
    end
    Wrap(A, "NewFS", function(v, owner) if v[1] then Queue(owner) end end, true)
    Wrap(A, "SkinBlizz", function(v) if H.Allowed(v[1]) and not nodes[v[1]] then Queue(v[1]) end end, true)
    for _, name in ipairs({"GoldButton", "makeButton", "NavButton", "CloseButton", "SkinBlizzButton"}) do
        Wrap(UI, name, function(v) if H.Allowed(v[1]) then Queue(v[1]) end end)
    end
    Wrap(UI, "GlowLine", function(v) Decorative(v[1]) end)
    Wrap(UI, "Column", function(v) if H.Texture(v[1]) then v[1]:SetColorTexture(1, 1, 1, .55); Colour(v[1], "line") end end)
    Wrap(UI, "Card", function(v, owner, anchor) Card(v[1], anchor or owner); Queue(owner) end)
    Wrap(UI, "CardRow", function(v, owner) Card(v[1], owner); Queue(owner) end)
    Wrap(UI, "RoundRect", function(v, owner, anchor, layer, sub, c, inset, r, g, b, a, tex)
        if layer == "HIGHLIGHT" then Pieces(v[1], anchor or owner, "selection")
        elseif not tex and r and r > .15 and r > g and g > b then Pieces(v[1], anchor or owner, "selection") end
        Queue(owner)
    end)
    Wrap(UI, "FramedPanel", function(_, f)
        -- These panels can be talent canvases. Reuse only their decorative fill
        -- instead of registering the canvas (which would fade later tree art).
        local rr = {}
        for _, t in ipairs(H.Regions(f)) do
            if Asset(t) == "rr_fill" then rr[#rr+1] = t else Decorative(t) end
        end
        if #rr > 0 then Pieces({pieces = rr}, f, "surface") end
        if f.GetParent and f:GetParent() == UIParent then Window(f) end
        Queue(f)
    end)
    Wrap(UI, "Slider", function(v)
        local f = v[1]
        if not H.Allowed(f) then return end
        local d = State(f)
        local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
        if thumb and not d.grip then
            d.grip = f:CreateTexture(nil, "OVERLAY")
            d.grip:SetSize(8, 12); d.grip:SetPoint("CENTER", thumb, "CENTER")
            d.grip:SetColorTexture(1, 1, 1, 1); Colour(d.grip, "accent")
            H.Fade(thumb) -- retain the original 24px thumb drag rectangle
        end
        for _, child in ipairs(H.Children(f)) do
            local fills = {}
            for _, t in ipairs(H.Regions(child)) do
                if Asset(t) == "rr_fill" then fills[#fills+1] = t
                elseif H.Texture(t) and t:GetDrawLayer() == "ARTWORK" then
                    t:SetColorTexture(1, 1, 1, .75); Colour(t, "accent")
                else Decorative(t) end
            end
            if #fills > 0 then Pieces({pieces=fills}, child, "surface") end
        end
        Queue(f)
    end)
    Wrap(UI, "QuietHead", function(v, owner)
        owner.euiOfaChevron = v[1]
        Decorative(v[1]); Button(owner); Queue(owner)
    end)
    Wrap(UI, "ColumnHeader", function(v)
        local f = v[1]
        if not H.Allowed(f) then return end
        for _, t in ipairs(H.Regions(f)) do
            if H.Texture(t) then t:SetColorTexture(1, 1, 1, .35); Colour(t, "line") end
        end
        Queue(f)
    end)
    Wrap(UI, "QuietRow", function(v)
        local t = v[1] and v[1].line
        if H.Texture(t) then t:SetColorTexture(1, 1, 1, .35); Colour(t, "line") end
    end)
    Wrap(UI, "WindowFrame", function(_, deco) for _, t in ipairs(H.Regions(deco)) do if H.Texture(t) then H.Fade(t) end end end)
    for _, name in ipairs({"NavHeader", "SectionTitle", "SmallCaps", "PageHeader", "CreateRecipeBrowser", "CreateGearPlanner"}) do
        Wrap(UI, name, function(v, owner)
            if H.Allowed(v[1]) then Queue(v[1]) end
            Queue(owner)
        end)
    end
    -- Panels are lazy; observe their completed factories, including ones
    -- registered after installation. No UIParent/global scan is required.
    local specs = {}
    local function Panel(spec)
        if type(spec) ~= "table" or specs[spec] or type(spec.create) ~= "function" then return end
        specs[spec] = true
        Wrap(spec, "create", function(v) Queue(v[1]) end)
    end
    for _, spec in ipairs(UI.panels or {}) do Panel(spec) end
    H.Hook(UI, "RegisterPanel", function(spec) Panel(spec) end)
    for _, name in ipairs({"ToggleUI", "OpenPanel", "SetWindowScale"}) do
        Wrap(A, name, function() Window(UI.mainWindow); Flush() end)
    end
    for _, name in ipairs({"EnsurePanel", "OpenDropDown"}) do
        Wrap(UI, name, function(v) if H.Allowed(v[1]) then Queue(v[1]) end end)
    end
    -- Known lazy secondary windows; inspect once on construction via FramedPanel
    -- and once here for controls that existed before this skin was enabled.
    for name in pairs(windowNames) do
        local f = _G[name]
        if H.Allowed(f) then Window(f) end
    end
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", function()
        if not busy then return end
        busy = false
        if Ready() then
            local work = deferred; deferred = {}
            for f in pairs(work) do
                if H.Allowed(f) then
                    if f:GetObjectType() == "Frame" and f:GetParent() == UIParent then Window(f) else Queue(f) end
                end
            end
            module.refresh(); Flush()
        end
    end)
    if S.OnLooksChanged then S.OnLooksChanged(function()
        if not Ready() then return end
        soft.RefreshSoftBorders()
        for _, d in pairs(fonts) do d.paint() end
        for _, d in pairs(colours) do d.paint() end
        for _, d in pairs(nodes) do
            if d.paintCheck then d.paintCheck() end
            if d.opacity then d.opacity() end
        end
        Layout()
    end) end
    module.refresh = function()
        if not Ready() then return end
        Window(UI.mainWindow)
        for name in pairs(windowNames) do if H.Allowed(_G[name]) then Window(_G[name]) end end
        for f in pairs(windows) do Walk(f); if State(f).opacity then State(f).opacity() end end
        for t, alpha in pairs(kept) do if t:GetAlpha() ~= alpha then t:SetAlpha(alpha) end end
        for _, d in pairs(colours) do d.paint() end
        for _, d in pairs(nodes) do if d.paintCheck then d.paintCheck() end end
        Flush()
    end
    Flush()
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("OneForAll", DefineSkin) else DefineSkin() end
