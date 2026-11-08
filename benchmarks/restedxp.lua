-- Source-shaped RestedXP v4.11.34 adapter workload. Runs only under host Lua.
C_Timer = {}
local fixture = assert(loadfile("tests/collection_spec.lua"))("rxp-benchmark", os.getenv("RXP_ADAPTER"))
local addon, module, S = fixture.addon, fixture.module, fixture.api
local frame, guide, flush = fixture.frame, fixture.guide, fixture.flush
local native = os.getenv("RXP_NATIVE") == "1"
local look, v2Mode = "forever", false
local checked = false
local marker = "|TInterface/GossipFrame/AvailableQuestIcon:0|t"
local guides = {{}, {}}
Enum = {UITextureSliceMode = {Stretched = 0}}
C_Texture = {GetAtlasInfo = function() return {file = 12345, leftTexCoord = 0, rightTexCoord = 1, topTexCoord = 0, bottomTexCoord = 1} end}
EllesmereUI = {
    IS_FOREVER = true, GetActiveProfileData = function() return look end,
    ProfileWindowSkinLook = function(profile) return profile end,
    ForeverBorder = function(host)
        local border = host:CreateTexture()
        border:SetTexture(1234); border:SetTexCoord(0, 1, 0, 1); border:SetHeight(6)
        return {on = true, [5] = border}
    end,
    ForeverBorderSeat = function() end, ForeverBorderShown = function(ring, shown) ring.on = shown end,
}
local function Label(text)
    local label = frame("FontString")
    label.text, label.font = text, "native"
    function label:GetFont() return self.font, self.size or 12, self.flags or "" end
    function label:SetFont(font, size, flags) self.font, self.size, self.flags = font, size, flags end
    function label:GetTextColor() return 1, 1, 1, 1 end
    function label:SetTextColor(...) self.color = {...} end
    function label:GetText() return self.text end
    function label:SetText(value) self.text = value end
    function label:SetJustifyH() end
    function label:GetStringWidth() return 85 end
    return label
end
function S.Font(text, r, g, b)
    local _, size = text:GetFont()
    text:SetFont("EUI-font", size, "OUTLINE")
    if r then text:SetTextColor(r, g, b, 1) end
end
function guide.GuideName:CreateFontString() return Label("") end
local function Backdrop(panel, kind)
    panel:SetBackdrop(guide.backdrop[kind or "edge"])
    function panel:GetBackdropColor() return table.unpack(self.fill or {0.03, 0.03, 0.04, 0.95}) end
    function panel:SetBackdropColor(...) self.fill = {...} end
    return panel
end
local function MakeRows()
    local scroll = frame("ScrollFrame")
    local pool = {}
    for i = 1, 36 do
        local row = Backdrop(frame(), "bottom")
        row.text = Label(marker .. " Accept a quest")
        row.number = {text = Label(tostring(i))}
        pool[i], scroll.children[i] = row, row
    end
    guide.ScrollFrame, guide.ScrollChild = scroll, {framePool = pool}
    guide.GuideName.text = Label("Hillsbrad Foothills\nDungeon Guide")
    guide.children = {scroll, guide.BottomFrame, guide.GuideName, guide.Footer, guide.CurrentStepFrame}
end
local function Checkbox()
    local button = frame("CheckButton")
    button.theme = {}
    local tick = button:CreateTexture()
    tick.GetObjectType = function() return "Texture" end
    tick:SetTexture("Interface/AddOns/RXPGuides/Textures/rxp-checked-32")
    function button:GetCheckedTexture() return tick end
    return button
end
local function MakeSteps()
    for i = 1, 3 do
        local card = Backdrop(i == 1 and fixture.step or frame())
        card.number = Backdrop(card.number or frame())
        card.number.text = Label("Step " .. i)
        card.elements = {}
        for j = 1, 4 do
            local button = Checkbox()
            card.elements[j] = {button = button, icon = Label(marker), text = Label("A quest objective")}
            card.children[j] = button
        end
        guide.CurrentStepFrame.framePool[i] = card
        guide.CurrentStepFrame.children[i] = card
    end
end
local function MakeAux()
    local panel = Backdrop(frame())
    panel.title = Backdrop(frame())
    panel.title.text = Label("Active Targets")
    panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", 5, 8)
    function panel:UpdateVisuals()
        self:SetBackdrop(guide.backdrop.edge)
        self.title:SetBackdrop(guide.backdrop.edge)
    end
    return panel
end
local function MakeV2()
    local window = {frame = frame(), upperFrame = Backdrop(frame()), guideNameFrame = Backdrop(frame()),
        guideStepsFrame = Backdrop(frame()), footer = Backdrop(frame())}
    window.frame.children = {window.upperFrame, window.guideNameFrame, window.guideStepsFrame, window.footer}
    local rows = {}
    for i = 1, 36 do
        rows[i] = {frame = frame(), text = Label(marker .. " Accept a quest")}
        window.guideStepsFrame.children[i] = rows[i].frame
    end
    window.guideSteps = {items = rows, SetRows = function(self, items) self.items = items end}
    window.UpdateTheme = function(self) self.guideSteps:SetRows(rows) end
    return window
end
addon.v2.IsGuideWindowEnabled = function() return v2Mode end
function addon.targeting:RenderTargetFrameBackground()
    local panel = self.activeTargetFrame
    panel:SetBackdropColor(0.03, 0.03, 0.04, 0.95)
end
function addon.targeting:UpdateTargetFrame()
    self:RenderTargetFrameBackground()
end
function addon.UpdateItemFrame()
    addon.activeItemFrame:SetBackdropColor(0.03, 0.03, 0.04, 0.95)
end
function addon.SetStep(i)
    if v2Mode then
        local steps = addon.v2.state.guideWindow.guideSteps
        steps:SetRows(steps.items)
        return
    end
    for j, card in ipairs(guide.CurrentStepFrame.framePool) do
        card.number.text:SetText("Step " .. (i + j))
        for _, element in ipairs(card.elements) do
            element.icon:SetText(marker)
            element.text:SetText(checked and "Done" or "A quest objective")
        end
    end
    addon.targeting:UpdateTargetFrame()
    addon.UpdateItemFrame()
    local scroll = guide.ScrollFrame.hooks.OnVerticalScroll
    if scroll then scroll(guide.ScrollFrame) end
end
function addon.LoadGuide(_, i)
    addon.currentGuide = guides[i % 2 + 1]
    for _, row in ipairs(guide.ScrollChild.framePool) do
        row.text:SetText(marker .. " Accept quest " .. i)
        row:SetBackdropColor(table.unpack(addon.colors.bottomFrameBG or {0.03, 0.03, 0.04, 0.95}))
    end
    addon.SetStep(i)
end
function guide:UpdateVisuals()
    self.BottomFrame:SetBackdrop(self.backdrop.edge)
    self.GuideName:SetBackdrop(self.backdrop.guideName)
end
local options
local registry = {RegisterOptionsTable = function(_, _, value) options = value end}
local dialog = {SetDefaultSize = function() end, Open = function() end}
LibStub = function(name)
    if name == "AceConfigRegistry-3.0" then return registry end
    if name == "AceConfigDialog-3.0" then return dialog end
end
GAMEOPTIONS_MENU = "Options"
local nested = {{text = "Chapter", hasArrow = true, menuList = {{text = "Route"}}}}
local menu = {{text = "Choose guide", hasArrow = true, menuList = nested}, {text = "Options..."}}
local function install()
    if native then addon.colors = addon:LoadActiveTheme() else module.install(S, module) end
    flush()
end
local function open()
    MakeRows(); MakeSteps()
    addon.targeting.activeTargetFrame, addon.activeItemFrame = MakeAux(), MakeAux()
    addon.LoadGuide(addon, 1)
    guide:SetShown(true)
    flush()
end
guide:SetShown(false)

local coldProfile = os.getenv("RXP_COLD_PROFILE") == "1"
local counted = {frame = "frames", CreateTexture = "textures", CreateMaskTexture = "masks", Label = "fonts",
    GetChildren = "scans", GetRegions = "scans", After = "queues", hooksecurefunc = "hooks", HookScript = "hooks",
    SetBackdrop = "writes", SetBackdropBorderColor = "writes", SetBackdropColor = "writes", SetColorTexture = "writes",
    SetVertexColor = "writes", SetTexture = "writes", SetShown = "writes", SetPoint = "writes",
    ClearAllPoints = "writes", SetSize = "writes", SetAlpha = "writes", SetTextColor = "writes", SetFont = "writes"}
local function Measure(name, action, iterations, warm)
    if coldProfile and warm > 0 then return end
    local counters = {calls = 0, skin = 0, frames = 0, textures = 0, masks = 0, fonts = 0,
        scans = 0, writes = 0, queues = 0, hooks = 0}
    local function Count()
        local info = debug.getinfo(2, "Sn")
        counters.calls = counters.calls + 1
        if info.source:find("RXPGuides.lua", 1, true) then counters.skin = counters.skin + 1 end
        local key = counted[info.name]
        if key and (key ~= "frames" or select(2, debug.getlocal(2, 1)) ~= "FontString") then
            counters[key] = counters[key] + 1
        end
    end
    if coldProfile then
        debug.sethook(Count, "c")
        action(1)
        debug.sethook()
    else
        for i = 1, warm do action(i) end
        local samples = {}
        for i = 1, iterations do samples[i] = 0 end
        collectgarbage("collect")
        local heap = collectgarbage("count")
        collectgarbage("stop")
        local begin = os.clock()
        for i = 1, iterations do
            local tick = os.clock()
            action(i)
            samples[i] = os.clock() - tick
        end
        local time = (os.clock() - begin) * 1000
        local churn = collectgarbage("count") - heap
        collectgarbage("restart")
        local gc = os.clock()
        collectgarbage("collect")
        local gcMS, retained = (os.clock() - gc) * 1000, collectgarbage("count") - heap

        if warm > 0 then
            debug.sethook(Count, "c")
            action(iterations + 1)
            debug.sethook()
        end
        assert(#fixture.errors == 0, table.concat(fixture.errors, "\n"))
        table.sort(samples)
        io.write(("RXP %s ms=%.6f p95_ms=%.6f max_ms=%.6f churn_kib=%.6f gc_ms=%.6f retained_kib=%.6f"):format(
            name, time, samples[math.ceil(iterations * 0.95)] * 1000, samples[iterations] * 1000, churn, gcMS, retained))
    end
    if coldProfile then io.write("RXP ", name) end
    if warm > 0 or coldProfile then
        for key, value in pairs(counters) do io.write(" ", key, "=", value) end
    end
    print()
end
if not coldProfile then print(("RXP setup definition_ms=%.6f"):format(fixture.definitionMS)) end
Measure("install", install, 1, 0)
Measure("first_open", open, 1, 0)
if coldProfile then return end
local n, warm = 120, 20
Measure("reopen", function() guide:SetShown(false); guide:SetShown(true); flush() end, n, warm)
Measure("guide_switch", function(i) addon:LoadGuide(i % 2); flush() end, n, warm)
Measure("step", function(i) checked = not checked; addon.SetStep(i % 15); flush() end, n, warm)
Measure("scroll", function(i)
    local row = guide.ScrollChild.framePool[i % 36 + 1]
    row.text:SetText(marker .. " Accept quest " .. i % 5)
    local callback = guide.ScrollFrame.hooks.OnVerticalScroll
    if callback then callback(guide.ScrollFrame) end
    flush()
end, n, warm)
Measure("aux_updates", function() addon.targeting:UpdateTargetFrame(); addon.UpdateItemFrame(); flush() end, n, warm)
addon:ShowMenu(menu, guide)
local displayed = fixture.menu()
if displayed and displayed[2] and displayed[2].menuList then
    local choices = displayed[2].menuList
    if choices[5] then choices[5].func() end
end
assert(native or options, "opacity fixture did not bind the real setting")
Measure("nested_menu", function() addon:ShowMenu(menu, guide); addon:ShowMenu(nested, guide); flush() end, n, warm)
Measure("opacity_burst", function(i)
    for j = 1, 8 do
        local value = (i + j) % 70 + 20
        if options then options.args.opacity.set(nil, value)
        else EUIAddonSkinsDB = EUIAddonSkinsDB or {restedXP = {}}; EUIAddonSkinsDB.restedXP.opacity = value / 100 end
    end
    flush()
end, n, warm)
Measure("theme_switch", function()
    look = look == "forever" and "eui" or "forever"
    if native then addon:LoadActiveTheme(); guide:UpdateVisuals() else module.refresh() end
    flush()
end, 30, warm)
addon.v2.state.guideWindow = MakeV2()
Measure("mode_switch", function(i)
    v2Mode = not v2Mode
    if v2Mode then addon.v2:DisableLegacyGuideWindow()
    else for _, panel in ipairs({guide.BottomFrame, guide.GuideName, guide.Footer, guide.CurrentStepFrame}) do panel:SetShown(true) end end
    addon.SetStep(i % 15); flush()
end, 40, warm)
v2Mode = true; addon.SetStep(1); flush()
Measure("v2_rows", function(i) addon.SetStep(i % 15); flush() end, n, warm)
v2Mode = false; guide:SetShown(false)
Measure("closed_idle", flush, n, warm)
Measure("closed_aux", function() addon.targeting:UpdateTargetFrame(); addon.UpdateItemFrame(); flush() end, n, warm)
Measure("closed_step", function(i) addon.SetStep(i % 15); flush() end, n, warm)
