-- Scroll scoping must preserve discovery, exclusions, toggles and native redraws.
local timers, enabled, visits, hooks, painted = {}, true, {}, 0, 0
local ns = {IsEnabled = function() return enabled end}
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
geterrorhandler = function() return function(e) error(e) end end
hooksecurefunc = function(o, key, fn)
    hooks = hooks + 1
    local original = o[key]
    o[key] = function(...) original(...); fn(...) end
end
local function flush()
    while #timers > 0 do
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
    end
end
local function frame(kind)
    local f = {children = {}, scripts = {}, kind = kind or 'Frame'}
    function f:GetObjectType() return self.kind end
    function f:GetNumChildren() return #self.children end
    function f:GetNumRegions() return 0 end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetRegions() end
    function f:IsProtected() return self.protected end
    function f:HookScript(key, fn) self.scripts[key] = fn; hooks = hooks + 1 end
    return f
end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
local S = {Font = function() end, EditBox = function(f) f.skinned = true; painted = painted + 1 end}
local module, exclude = {}, nil
local H = ns.CreateSkinHelper(S, module)
-- UI fields can be functions or asset IDs, not just frames.
for _, value in ipairs({function() end, 12345, 'Refresh', true, false, {}, {GetObjectType = true}}) do
    assert(not H.Allowed(value), 'non-UI value accepted as a frame')
    H.Scan(value, function() error('invalid scan callback') end)
    H.Script(value, 'OnShow', function() error('invalid hook') end)
    H.Font(value); H.Fade(value); H.Hook(value, 'Refresh', function() error('invalid method hook') end)
end
assert(not H.Allowed(nil))
local root, scroll, sibling = frame(), frame('ScrollFrame'), frame()
root.children = {scroll, sibling}
local function visit(f) visits[f] = (visits[f] or 0) + 1 end
local refresh
local function apply() H.Scan(root, refresh, visit, exclude) end
refresh = function() H.Queue(module, apply) end
apply()
local initialHooks = hooks
for _ = 1, 100 do scroll.scripts.OnVerticalScroll() end
assert(#timers == 1); flush()
assert(visits[scroll] == 2 and visits[sibling] == 1 and hooks == initialHooks)
local late = frame('EditBox'); scroll.children = {late}
scroll.scripts.OnVerticalScroll(); flush()
assert(late.skinned and painted == 1, 'new scroll child missed')
local replacement = frame('EditBox'); scroll.children = {replacement}
scroll.scripts.OnVerticalScroll(); flush()
assert(replacement.skinned and painted == 2, 'same-count child replacement missed')
local before = visits[scroll]
scroll.scripts.OnVerticalScroll(); refresh(); flush()
assert(visits[scroll] == before + 1, 'partial and full scans were duplicated')
exclude = {[scroll] = true}; refresh(); flush()
before = visits[scroll]
scroll.scripts.OnVerticalScroll(); flush()
assert(visits[scroll] == before, 'excluded scroll ancestor bypassed')
exclude = nil; refresh(); flush()
replacement.protected = true
local previous = visits[replacement]
scroll.scripts.OnVerticalScroll(); flush()
assert(visits[replacement] == previous, 'protected child visited')
enabled = false; before = visits[scroll]
scroll.scripts.OnVerticalScroll(); refresh(); flush()
assert(visits[scroll] == before, 'disabled integration traversed')
enabled = true
local writes = 0
local texture = {alpha = 1, GetAlpha = function(self) return self.alpha end,
    SetAlpha = function(self, value) self.alpha = value; writes = writes + 1 end}
H.Fade(texture)
local fadeHooks = hooks
for _ = 1, 100 do H.Fade(texture) end
assert(writes == 1 and hooks == fadeHooks, 'warm fade rewrote texture or duplicated hook')
texture:SetAlpha(0.8)
assert(texture.alpha == 0 and writes == 3, 'native redraw suppression lost')
print('PASS: scoped/coalesced scrolling, dynamic replacement, exclusions/protected/toggles, idempotent fade and native redraw')

-- Scoped adapters can explicitly route control callbacks to their own roots.
-- The default path remains a coalesced full refresh for every existing caller.
do
    local previousCreate, previousCombat = CreateFrame, InCombatLockdown
    local createdFrames, registrations, inCombat = {}, {}, false
    CreateFrame = function(kind)
        local f = frame(kind)
        function f:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
        function f:SetScript(key, fn) self.scripts[key] = fn end
        createdFrames[#createdFrames + 1] = f; return f
    end
    InCombatLockdown = function() return inCombat end
    ns.RegisterModule = function(id, _, _, install) registrations[id] = {install = install} end
    assert(loadfile('EUIAddonSkins/Scoped.lua'))('EUIAddonSkins', ns)
    local root, button = frame(), frame('Button'); root.children = {button}
    local context, full, routed, visited = nil, 0, 0, {}
    ns.RegisterScopedSkin('Routed', 'Routed', {
        roots = function() return {{frame = root, mode = 'controls'}} end,
        hooks = function(C) context = C; full = full + 1 end,
        visit = function(_, f) visited[f] = (visited[f] or 0) + 1 end,
        controlRefresh = function(_, owner, source)
            assert(owner == root and source == button); routed = routed + 1
        end,
    })
    registrations.Routed.install(S, registrations.Routed); flush()
    assert(full == 1)
    local installedHooks = hooks
    for _ = 1,100 do button.scripts.OnClick(button) end
    flush(); assert(routed == 100 and full == 1 and hooks == installedHooks)
    local previousVisits = visited[button]
    context.RefreshControlsNow(root, {[button] = true})
    assert(visited[button] == previousVisits, 'targeted exclusion was ignored')
    context.RefreshControlsNow(root); assert(visited[button] == previousVisits + 1)
    inCombat = true; previousVisits = visited[button]
    context.RefreshControlsNow(root); assert(visited[button] == previousVisits)
    inCombat = false
    for _, eventFrame in ipairs(createdFrames) do
        if eventFrame.events and eventFrame.events.PLAYER_REGEN_ENABLED then eventFrame.scripts.OnEvent(eventFrame, 'PLAYER_REGEN_ENABLED') end
    end
    flush(); assert(visited[button] == previousVisits + 1, 'targeted combat deferral lost')
    enabled = false; button.scripts.OnClick(button); flush(); assert(routed == 100)
    enabled = true
    local normalRoot, normalButton, normalFull = frame(), frame('Button'), 0
    normalRoot.children = {normalButton}
    ns.RegisterScopedSkin('Default', 'Default', {
        roots = function() return {{frame = normalRoot, mode = 'controls'}} end,
        hooks = function() normalFull = normalFull + 1 end,
    })
    registrations.Default.install(S, registrations.Default); flush(); assert(normalFull == 1)
    for _ = 1,100 do normalButton.scripts.OnClick(normalButton) end
    flush(); assert(normalFull == 2, 'default control refresh no longer coalesces')
    CreateFrame, InCombatLockdown = previousCreate, previousCombat
end
print('PASS: opt-in scoped control routing/exclusions, default coalescing, combat deferral and disabled gating')
