local timers, errors, calls = {}, {}, {}
local combat = false
InCombatLockdown = function() return combat end
local function count(k) calls[k] = (calls[k] or 0) + 1 end
local function texture(kind)
    return { GetObjectType = function() return kind or "Texture" end,
        SetColorTexture = function(self, ...) self.color = {...} end,
        SetAlpha = function(self, a) self.alpha = a end,
        ClearAllPoints = function(self) self.points = {} end,
        SetPoint = function(self, ...) self.points = self.points or {}; self.points[#self.points + 1] = {...} end }
end
local function frame(kind, name, parent)
    local f = { kind = kind or "Frame", parent = parent, regions = {}, children = {}, scripts = {}, hooks = {} }
    function f:CreateTexture()
        local t = {SetPoint = function() end, SetHeight = function() end,
            SetColorTexture = function(self, ...) self.color = {...} end,
            SetAlpha = function(self, a) self.alpha = a end}
        return t
    end
    function f:GetObjectType() return self.kind end
    function f:GetParent() return self.parent end
    function f:GetPoint() if self.point then return table.unpack(self.point) end end
    function f:GetFrameLevel() return self.level or 1 end
    function f:SetFrameLevel(level) self.level = level end
    function f:GetWidth() return self.width or 24 end
    function f:GetHeight() return self.height or 24 end
    function f:IsForbidden() return self.forbidden end
    function f:IsProtected() return self.protected end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:GetChildren() return table.unpack(self.children) end
    function f:HookScript(event, fn)
        self.hooks[event] = self.hooks[event] or {}; table.insert(self.hooks[event], fn)
    end
    function f:SetScript(event, fn) self.scripts[event] = fn end
    function f:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
    function f:UnregisterEvent() end
    function f:SetPoint(...) self.point = {...} end
    function f:ClearAllPoints() self.point = nil end
    function f:SetSize(w, h) self.width, self.height = w, h end
    if parent then table.insert(parent.children, f) end
    if name then _G[name] = f end
    return f
end
local lastCreated
CreateFrame = function(kind, name, parent) lastCreated = frame(kind, name, parent); return lastCreated end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
geterrorhandler = function() return function(err) errors[#errors + 1] = err end end
C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
hooksecurefunc = function(object, name, callback)
    local original = object[name]
    object[name] = function(...)
        local out = table.pack(original(...)); callback(...); return table.unpack(out, 1, out.n)
    end
end
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 20, "timer loop")
    end
end
local enabled = true
local looks
local skin = {
    IsEnabled = function() return enabled end,
    GetAccentColor = function() return 0.047, 0.824, 0.616 end,
    OnLooksChanged = function(fn) looks = fn end,
}
for _, name in ipairs({ "Shell", "Panel", "Button", "EditBox", "Dropdown", "Inset", "FadeRegions",
    "FadeNineSlice", "Font", "CloseButton", "ScrollBar", "SquareIcon", "Checkbox", "StateButtonLabel" }) do
    skin[name] = function(f, options) assert(f, name .. " missing frame"); count(name); if name == "Button" then f.buttonSkinned = true end; if name == "Shell" or name == "EditBox" then f.softOptions = options end end
end
local callback
EllesmereUI = { RegisterSkin = function(name, fn) count("registration"); callback = fn end }
ForeverCompanionAPI = {
    COLORS = {},
    AttachToFrame = function(button, host) button.host = host; return "attach-result" end,
    CreateWindow = function(name) return frame("Frame", name), nil, "sentinel" end,
    CreateMenuButton = function(parent)
        local f = frame("Button", nil, parent); f.Text = texture("FontString"); return f
    end,
    CreateSearchBox = function(parent) return frame("EditBox", nil, parent) end,
    CreateDropdown = function(parent) return { frame = frame("DropdownButton", nil, parent) } end,
    CreateScrollFrame = function(parent) return frame("ScrollFrame", nil, parent), frame("EventFrame", nil, parent) end,
    AddInset = function() return texture(), frame() end,
    StripedBackground = function() return texture(), texture() end,
    CreateSideTab = function(parent)
        local f = frame("Button", nil, parent); f.icon = texture(); f.sel = texture(); return f
    end,
    CreateOptionsButton = function(parent) local f = frame("Button", nil, parent); f.icon = texture(); return f end,
    VirtualList = function() return { Layout = function() end, Refresh = function() end } end,
}
local chunk = assert(loadfile("EUIAddonSkins/Core.lua"))
local integration = assert(loadfile("EUIAddonSkins/Skins/ForeverCompanion.lua"))
local ns = {}
chunk("EUIAddonSkins", ns)
assert(loadfile("EUIAddonSkins/Accent.lua"))("EUIAddonSkins", ns)
assert(loadfile("EUIAddonSkins/Widgets.lua"))("EUIAddonSkins", ns)
integration("EUIAddonSkins", ns)
assert(calls.registration == 1 and not calls.Shell, "must wait for API dispatch")
local existingLauncher = frame("Button", "ForeverCompanionTalentBtn")
existingLauncher.Text = texture("FontString")
callback(skin)
flush()
assert(existingLauncher.buttonSkinned, "existing BiS Talents launcher not skinned")
local host = frame()
local blizzardButton = frame("Button", nil, host); blizzardButton.Text = texture("FontString")
local lateLauncher = frame("Button", "ForeverCompanionTalentBtn")
lateLauncher.Text = texture("FontString")
lateLauncher:SetScript("OnClick", function() return "original-talent-toggle" end)
assert(ForeverCompanionAPI.AttachToFrame(lateLauncher, host) == "attach-result")
flush()
assert(lateLauncher.buttonSkinned and not blizzardButton.buttonSkinned, "launcher skin scanned Blizzard host")
assert(lateLauncher.scripts.OnClick() == "original-talent-toggle" and lateLauncher.host == host)
combat = true
local combatLauncher = frame("Button", "ForeverCompanionTalentBtn")
combatLauncher.Text = texture("FontString")
ForeverCompanionAPI.AttachToFrame(combatLauncher, host); flush()
assert(not combatLauncher.buttonSkinned, "launcher changed in combat")
combat = false
lastCreated.scripts.OnEvent(lastCreated, "PLAYER_REGEN_ENABLED"); flush()
assert(combatLauncher.buttonSkinned, "launcher not applied after combat")
enabled = false
local disabledLauncher = frame("Button", "ForeverCompanionTalentBtn")
disabledLauncher.Text = texture("FontString")
ForeverCompanionAPI.AttachToFrame(disabledLauncher, host); flush()
assert(not disabledLauncher.buttonSkinned, "disabled Companion launcher was skinned")
enabled = true
ForeverCompanionAPI.AttachToFrame(disabledLauncher, host); flush()
assert(disabledLauncher.buttonSkinned)
-- The private FC scan footer moves below the auction tabs; unrelated children stay put.
AuctionFrame = frame('Frame')
local unrelated = frame('Frame', nil, AuctionFrame)
local footer = frame('Frame', nil, AuctionFrame)
footer.icon = texture(); footer.icon.GetTexture = function() return 'Interface/\\AddOns/ForeverCompanion/Media/LogoAddon.tga' end
footer.btn = frame('Button', nil, footer); footer.btn.scripts.OnClick = function() return 'full-scan-original' end
footer.status = texture('FontString'); footer.status.SetWidth = function(self, w) self.width = w end
local externalEvents = lastCreated
externalEvents.scripts.OnEvent(externalEvents, 'AUCTION_HOUSE_SHOW'); flush()
assert(footer.point[5] == -30 and footer.status.width == 200 and footer.btn.buttonSkinned)
assert(not unrelated.point and footer.btn.scripts.OnClick() == 'full-scan-original')
local panels = calls.Panel; externalEvents.scripts.OnEvent(externalEvents, 'AUCTION_HOUSE_SHOW'); flush()
assert(calls.Panel == panels, 'scan footer allocated twice')
AuctionFrame = nil
local api = ForeverCompanionAPI
local f, missing, sentinel = api.CreateWindow("ForeverCompanionFrame")
assert(f and missing == nil and sentinel == "sentinel", "factory return values changed")
f.CloseButton = frame('Button', nil, f); f.optionsBtn = api.CreateOptionsButton(f); f.helpBtn = frame('Button', nil, f)
local headerCheck = frame('CheckButton', nil, f); headerCheck:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -84, -4)
local originalHelp = function() return 'tour-native' end; f.helpBtn:SetScript('OnClick', originalHelp)
local b = api.CreateMenuButton(f)
local clicks = 0; b:SetScript("OnClick", function() clicks = clicks + 1 end)
local search = api.CreateSearchBox(f); api.CreateDropdown(f); api.CreateScrollFrame(f)
local sc = frame("Frame", nil, f)
local list = api.VirtualList(nil, sc)
local tab = api.CreateSideTab(f)
tab:SetPoint('TOPLEFT', f, 'TOPRIGHT', -2, -30)
assert(tab.point[4] == 6 and tab.point[5] == -30 and tab.level == f:GetFrameLevel() + 8)
assert(tab.icon.points[1][1] == 'TOPLEFT' and tab.icon.points[2][4] == -3)
local light, right = api.StripedBackground(f, "light")
local inset = api.AddInset(f)
local check = frame("CheckButton", nil, f)
local secret = frame("EditBox", nil, f); secret.forbidden = true
local protected = frame("EditBox", nil, f); protected.protected = true
local edits = calls.EditBox or 0
flush()
assert(headerCheck.point[1] == 'RIGHT' and headerCheck.point[2] == f.helpBtn and headerCheck.width == 20)
assert(f.CloseButton.point[4] == -8 and f.CloseButton.point[5] == -8 and f.CloseButton.width == 20)
assert(f.optionsBtn.point[2] == f.CloseButton and f.helpBtn.point[2] == f.optionsBtn and f.helpBtn.scripts.OnClick == originalHelp)
assert(f.softOptions.noBorder and search.softOptions.noBorder and api.COLORS.border[1] == 0.055, "Companion soft chrome missing")
assert(calls.EditBox == edits + 1, "must skin the ordinary input exactly once; skip restricted frames")
assert(light.color[4] == 0.045 and right.color[4] == 0.045)
assert(inset.color[1] == 0.025)
assert(tab.sel.color[2] == 0.824)
b.scripts.OnClick(); assert(clicks == 1, "lost click callback")
local shells = calls.Shell
list:Layout(); list:Layout(); assert(#timers == 1, "updates not coalesced"); flush()
assert(calls.Shell == shells, "rescan must not fade window content again")
local newCheck = frame("CheckButton", nil, sc)
local checks = calls.Checkbox; list:Layout(); flush()
assert(calls.Checkbox == checks + 1, "new pooled row control not discovered")
looks(); flush()
enabled = false
local before = calls.Shell; api.CreateWindow("AnotherWindow"); flush()
assert(calls.Shell == before, "EUI master/per-addon disable ignored")
enabled = true
SlashCmdList.EUIADDONSKINS("off")
api.CreateWindow("DisabledWindow"); assert(calls.Shell == before)
SlashCmdList.EUIADDONSKINS("on")
api.CreateWindow("EnabledWindow"); flush(); assert(calls.Shell == before + 1)
assert(#errors == 0, table.concat(errors, "\n"))
-- Missing API must leave FC unchanged and expose a usable status command.
EllesmereUI = nil
local original = api.CreateWindow
local missingNS = {}
chunk("EUIAddonSkins", missingNS)
integration("EUIAddonSkins", missingNS)
assert(api.CreateWindow == original)
SlashCmdList.EUIADDONSKINS("")
-- Missing target must be harmless and must not block other skin modules.
EUIAddonSkinsDB = {}
ForeverCompanionAPI = nil
EllesmereUI = { RegisterSkin = function(_, fn) callback = fn; fn(skin) end }
local collection = {}
chunk("EUIAddonSkins", collection)
assert(loadfile("EUIAddonSkins/Accent.lua"))("EUIAddonSkins", collection)
local coreEvents = lastCreated
assert(loadfile("EUIAddonSkins/Widgets.lua"))("EUIAddonSkins", collection)
integration("EUIAddonSkins", collection)
callback(skin)
assert(not collection.modules[1].attempted, "absent target must stay dormant")
local otherRuns = 0
collection.RegisterModule("OtherAddon", "Other Addon", function() return true end,
    function() otherRuns = otherRuns + 1 end)
assert(otherRuns == 1 and collection.modules[2].active, "unrelated skin blocked by missing FC")
-- Load-on-demand target activates once, including after PLAYER_LOGIN.
ForeverCompanionAPI = { COLORS = {} }
coreEvents.scripts.OnEvent(coreEvents, "ADDON_LOADED", "ForeverCompanion")
assert(collection.modules[1].active, "late target not activated")
local wrapped = ForeverCompanionAPI.CreateWindow
coreEvents.scripts.OnEvent(coreEvents, "PLAYER_LOGIN")
coreEvents.scripts.OnEvent(coreEvents, "ADDON_LOADED", "UnrelatedAddon")
assert(otherRuns == 1 and ForeverCompanionAPI.CreateWindow == wrapped, "module installed twice")
collection.RegisterModule("BrokenAddon", "Broken Addon", function() return true end,
    function() error("expected test failure") end)
assert(not collection.modules[3].active and #errors == 1, "installer failure not isolated")
local afterFailure = false
collection.RegisterModule("WorkingAddon", "Working Addon", function() return true end,
    function() afterFailure = true end)
assert(afterFailure, "broken integration blocked another skin")
print("PASS: syntax, preserved returns/clicks, dynamic controls, coalescing, restricted frames, theme/toggles, missing API/target, late activation, independent modules, error isolation")
