local ADDON, ns = ...
local function DefineSkin()
ns.RegisterModule("AllTheThings", "AllTheThings", function()
    return type(_G.AllTheThings) == "table" and type(_G.AllTheThings.Windows) == "table"
end, function(S, module)
    local app = _G.AllTheThings
    local soft = ns.CreateSoftSkin(S, module)
    -- Legacy ATT steppers use the same public page-arrow primitive, with
    -- subdued borders, as the rest of the collection's soft controls.
    local H = ns.CreateSkinHelper(setmetatable({PageButton = soft.SoftPageButton}, {__index = S}), module)
    local windows, objects, surfaces, fonts = {}, {}, {}, {}
    local painted, states, highlights = {}, {}, {}
    local generation = 0
    local pending, painting, waiting = {}, false, false
    local PaintWindow, BindWindow, BindObject, PaintObject, Refresh
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")

    local function Run(fn, ...)
        if painting or not ns.IsEnabled(module) then return end
        if InCombatLockdown and InCombatLockdown() then waiting = true; return end
        painting = true
        H.Safe(fn, ...)
        painting = false
    end
    local function Font(text, control)
        if not H.Allowed(text) or not text.GetFont then return end
        local entry = fonts[text]
        if not entry then
            entry = {}; fonts[text] = entry
            H.Hook(text, "SetFontObject", function() Run(Font, text, entry.control) end)
        end
        if control then entry.control = control end
        local path, size, flags = text:GetFont()
        if not path then return end -- A registered label may not be initialized yet.
        local font, outline = S.GetFont()
        if path ~= font or flags ~= (outline or "") or entry.size ~= size or entry.generation ~= generation then
            S.Font(text) -- Preserve native point size, layout and collection colours.
            entry.size, entry.generation = size, generation
        end
        if control and text.SetTextColor then
            local shade = control.IsEnabled and not control:IsEnabled() and 0.48 or 0.9
            text:SetTextColor(shade, shade, shade, 1)
        end
    end
    local function State(f)
        local enabled = not f.IsEnabled or f:IsEnabled()
        if states[f] == enabled then return end
        states[f] = enabled
        Font(f.Text or (f.GetFontString and f:GetFontString()), f)
    end
    local function Gradient(t, first, last, r, g, b)
        t:SetColorTexture(1, 1, 1, 1)
        if t.SetGradient and CreateColor then
            t:SetGradient("HORIZONTAL", CreateColor(r, g, b, first), CreateColor(r, g, b, last))
        elseif t.SetGradientAlpha then t:SetGradientAlpha("HORIZONTAL", r, g, b, first, r, g, b, last)
        else t:SetColorTexture(r, g, b, math.max(first, last) * 0.5) end
    end
    local function Surface(owner)
        local d = surfaces[owner]
        if not d then
            -- ATT saves GetBackdrop/colours to its profiles. Skin a separate,
            -- mouse-transparent layer so those native settings stay untouched.
            local layer = CreateFrame("Frame", nil, owner)
            layer:SetAllPoints(owner); layer:EnableMouse(false)
            layer:SetFrameLevel(owner:GetFrameLevel())
            S.Panel(layer, {noBorder = true})
            d = {layer = layer}; surfaces[owner] = d
            d.left = layer:CreateTexture(nil, "BACKGROUND", nil, -3)
            d.left:SetPoint("TOPLEFT"); d.left:SetPoint("BOTTOMRIGHT", layer, "BOTTOM")
            d.right = layer:CreateTexture(nil, "BACKGROUND", nil, -3)
            d.right:SetPoint("TOPLEFT", layer, "TOP"); d.right:SetPoint("BOTTOMRIGHT")
        end
        local r, g, b = S.GetPanelColor()
        r, g, b = math.min(1, r + 0.15), math.min(1, g + 0.15), math.min(1, b + 0.15)
        Gradient(d.left, 0, 0.4, r, g, b); Gradient(d.right, 0.4, 0, r, g, b)
    end
    local function NativeBackground(window)
        -- Do not clear its backdrop or call colour setters: ATT records both.
        for _, region in ipairs(H.Regions(window)) do
            if H.Texture(region) and region ~= window.Grip then H.Fade(region) end
        end
    end
    local function Scroll(f)
        if not H.Allowed(f) then return end
        local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
        if thumb then
            -- S.ScrollBar handles modern Track.Thumb frames; ATT's collection
            -- windows use UIPanelScrollBarTemplate and a texture thumb instead.
            H.LegacySlider(f)
            thumb:SetVertexColor(1, 1, 1, 1)
            if thumb.SetTexCoord then thumb:SetTexCoord(0, 1, 0, 1) end
            thumb:SetWidth(5) -- Keep native height, range and slider hit area.
        else
            S.ScrollBar(f, true)
            if H.Allowed(f.Back) then soft.SoftPageButton(f.Back, "^") end
            if H.Allowed(f.Forward) then soft.SoftPageButton(f.Forward, "v") end
        end
    end
    local function Rows(window)
        if window.IsShown and not window:IsShown() then return end
        local rows = window.Container and window.Container.rows
        if type(rows) ~= "table" then return end
        -- rawget does not invoke ATT's lazy __index. Never create a row by
        -- indexing past the pool, or traverse its collection/database objects.
        for i = 1, math.min(window.rowCount or #rows, #rows) do
            local row = rawget(rows, i)
            if H.Allowed(row) and (not row.IsShown or row:IsShown()) then
                Font(row.Label); Font(row.Summary)
                local hover = row.GetHighlightTexture and H.Texture(row:GetHighlightTexture())
                if hover and not highlights[hover] then
                    highlights[hover] = true
                    hover:SetColorTexture(1, 1, 1, 0.10)
                end
                -- Background marks map selections; Texture/Indicator/Summary
                -- carry collection, rarity and completion state. Leave them native.
            end
        end
    end
    PaintWindow = function(window)
        if not H.Allowed(window) then return end
        NativeBackground(window)
        if not windows[window] then
            windows[window] = true
            Surface(window)
            if H.Allowed(window.CloseButton) then S.CloseButton(window.CloseButton) end
            H.Hook(window, "SetBackdrop", function() Run(NativeBackground, window) end)
            -- DefaultRedraw is the completed, non-yielding visual stage; never
            -- hook ATT's coroutine-driven data rebuilding or GetWindow factory.
            H.Hook(window, "DefaultRedraw", function() Run(Rows, window) end)
            H.Script(window, "OnShow", function() Run(PaintWindow, window) end)
        end
        Rows(window)
        if H.Texture(window.Grip) then H.Resize(window, true) end
        Scroll(window.ScrollBar)
    end
    BindWindow = function(window) Run(PaintWindow, window) end

    local function Check(f)
        S.Checkbox(f, {borderInset = 4, hover = 0.05})
        for i, getter in ipairs({"GetCheckedTexture", "GetDisabledCheckedTexture"}) do
            local mark = f[getter] and H.Texture(f[getter](f))
            if mark then
                mark:SetVertexColor(1, 1, 1, 1)
                if i == 1 then mark:SetColorTexture(S.GetAccentColor())
                else mark:SetColorTexture(0.4, 0.4, 0.4, 0.8) end
                mark:ClearAllPoints(); mark:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
                mark:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 6)
            end
        end
        Font(f.Text, f)
    end
    PaintObject = function(f, completed)
        if not H.Allowed(f) then return end
        if painted[f] == generation and not completed then State(f); return end
        painted[f] = generation
        local kind = f:GetObjectType()
        if kind == "CheckButton" then Check(f)
        elseif kind == "EditBox" then
            if not (f.IsMultiLine and f:IsMultiLine()) then S.EditBox(f) end
            Font(f)
        elseif kind == "Slider" then
            if f.GetOrientation and f:GetOrientation() == "HORIZONTAL" then
                H.LegacySlider(f)
                local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
                if thumb then thumb:SetSize(8, 14) end
            else Scroll(f) end
        elseif kind == "DropdownButton" then soft.Dropdown(f)
        elseif kind == "Button" and f.GetFontString and H.Allowed(f:GetFontString()) then
            S.Button(f, {"Text", "Icon", "icon"})
            if S.StateButtonLabel then S.StateButtonLabel(f) end
            Font(f:GetFontString(), f)
        elseif kind == "FontString" then Font(f)
        end
        if H.Allowed(f.ScrollBar) then Scroll(f.ScrollBar) end
        if H.Texture(f.separator) then f.separator:SetColorTexture(1, 1, 1, 0.10) end
        if kind ~= "FontString" then
            for _, region in ipairs(H.Regions(f)) do Font(region) end
        end
        states[f] = not f.IsEnabled or f:IsEnabled()
    end
    local function PaintPending()
        for object in pairs(pending) do
            pending[object] = nil
            PaintObject(object, true)
        end
    end
    local function FlushObjects() Run(PaintPending) end
    BindObject = function(f)
        if not H.Allowed(f) or objects[f] then return end
        objects[f] = true
        local kind = f:GetObjectType()
        if kind ~= "FontString" then
            -- RegisterObject runs before a control's constructor finishes.
            -- Bind now; paint completed controls together on the next frame.
            H.Script(f, "OnShow", function() Run(PaintObject, f) end)
            for _, method in ipairs({"Enable", "Disable", "SetEnabled"}) do
                H.Hook(f, method, function() Run(State, f) end)
            end
            H.Hook(f, "RegisterObject", function(_, object)
                if not H.Allowed(object) then return end
                BindObject(object); pending[object] = true; H.Queue(pending, FlushObjects)
            end)
            if type(f.Objects) == "table" then for _, object in ipairs(f.Objects) do BindObject(object) end end
            -- Scroll templates and label children are real UI frames only.
            for _, child in ipairs(H.Children(f)) do BindObject(child) end
        end
        pending[f] = true
    end
    local function Settings()
        BindObject(app.Settings)
        PaintPending()
    end
    local function EditDialog()
        local dialog = _G.ATTEditBox
        if not H.Allowed(dialog) then return end
        PaintWindow(dialog)
        if surfaces[dialog] then Surface(dialog) end
        BindObject(dialog)
        PaintPending()
    end
    Refresh = function()
        waiting = false
        generation = generation + 1
        for _, window in pairs(app.Windows) do
            PaintWindow(window); if surfaces[window] then Surface(window) end
        end
        Settings()
        EditDialog()
        for f in pairs(objects) do PaintObject(f) end
        soft.RefreshSoftBorders()
    end
    module.refresh = function() H.Queue(module, function() Run(Refresh) end) end
    events:SetScript("OnEvent", function() if waiting then Run(Refresh) end end)
    if type(app.AddEventHandler) == "function" then
        app.AddEventHandler("OnWindowCreated", BindWindow)
        app.AddEventHandler("OnStartupDone", module.refresh)
    end
    H.Hook(app.Settings, "CreateOptionsPage", function() Run(Settings) end)
    H.Hook(app, "ShowPopupDialogWithMultiLineEditBox", function() Run(EditDialog) end)
    if S.OnLooksChanged then S.OnLooksChanged(module.refresh) end
    Run(Refresh)
end)
end
if ns.RegisterSkinDefinition then ns.RegisterSkinDefinition("AllTheThings", DefineSkin)
else DefineSkin() end
