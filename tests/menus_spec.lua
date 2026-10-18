local timers, errors, looks = {}, {}, {}
local combat, accent = false, 0.4
local ns = {IsEnabled = function(module) return module and module.enabled end,
    AttachAccent = function(_, f) f.accent = true end}
C_Timer.After = function(_, fn) timers[#timers + 1] = fn end
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
hooksecurefunc = function(obj, name, callback)
    local original = obj[name]
    obj[name] = function(...)
        local values = table.pack(original(...)); callback(...); return table.unpack(values, 1, values.n)
    end
end
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 15, 'menu refresh loop')
    end
end
local function region(kind)
    local r = {kind = kind or 'Texture', alpha = 0.8, color = {1, 0.82, 0, 1}, font = {'native-font', 13, 'OUTLINE'}, text = '|Temote-art:0|t xqcA'}
    function r:GetObjectType() return self.kind end
    function r:IsShown() return self.shown ~= false end
    function r:SetSize() end
    function r:SetHeight() end
    function r:SetAllPoints() end
    function r:SetDrawLayer(value) self.layer = value end
    function r:SetPoint() end
    function r:SetColorTexture(...) self.color = {...} end
    function r:GetAlpha() return self.alpha end
    function r:SetAlpha(a) self.alpha = a end
    function r:GetDrawLayer() return self.layer or 'BACKGROUND' end
    function r:GetVertexColor() return table.unpack(self.color) end
    function r:SetVertexColor(...) self.color = {...} end
    function r:GetFont() return table.unpack(self.font) end
    function r:SetFont(...) self.font = {...} end
    return r
end
local function frame(kind, name, parent)
    local f = {kind = kind or 'Frame', name = name, shown = false, alpha = 1, children = {}, regions = {}, hooks = {}, scripts = {}}
    function f:GetObjectType() return self.kind end
    function f:CreateTexture() local r = region(); self.regions[#self.regions + 1] = r; return r end
    function f:GetName() return self.name end
    function f:IsProtected() return self.protected end
    function f:IsForbidden() return self.forbidden end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetAlpha() return self.alpha end
    function f:SetAlpha(a) self.alpha = a end
    function f:GetFrameLevel() return 5 end
    function f:SetFrameLevel(v) self.level = v end
    function f:SetAllPoints() end
    function f:EnableMouse(v) self.mouse = v end
    function f:IsShown() return self.shown end
    function f:HookScript(event, callback) self.hooks[event] = callback end
    function f:RegisterEvent() end
    function f:SetScript(event, callback) self.scripts[event] = callback end
    function f:Hide() self.shown = false; if self.hooks.OnHide then self.hooks.OnHide() end end
    if parent then parent.children[#parent.children + 1] = f end
    if name then _G[name] = f end
    return f
end
local events
CreateFrame = function(kind, _, parent)
    local f = frame(kind, nil, parent)
    if not parent then events = f end
    return f
end
local lib = {ToggleDropDownMenu = function() return 'lib-original' end, UIDropDownMenu_AddButton = function() end}
local questLib = {ToggleDropDownMenu = function() return 'quest-menu-native' end, UIDropDownMenu_AddButton = function() end}
LibStub = function(name) if name == 'LibUIDropDownMenu-4.0' then return lib elseif name == 'LibUIDropDownMenuQuestie-4.0' then return questLib end end
ToggleDropDownMenu = function() return 'native-original', nil, 9 end
UIDropDownMenu_AddButton = function() end
local S = {GetFont = function() return 'eui-font', '' end, GetAccentColor = function() return accent, 0.5, 0.6 end,
    GetPanelColor = function() return 0.03, 0.03, 0.03, 0.95 end,
    OnLooksChanged = function(fn) looks[#looks + 1] = fn end}
function S.Shell(f, options) f.shell = true; assert(options.noTopBar) end
local module = {enabled = true}
assert(loadfile('EUIAddonSkins/Menus.lua'))('EUIAddonSkins', ns)
local owner, unrelated = frame(), frame()
DropDownList1 = frame('Frame', 'DropDownList1')
DropDownList1.MenuBackdrop = frame('Frame', nil, DropDownList1)
local button = frame('Button', 'DropDownList1Button1', DropDownList1)
local text, highlight, arrow = region('FontString'), region(), region()
button.regions = {text}
button.GetFontString = function() return text end
button.GetHighlightTexture = function() return highlight end
button.ExpandArrow = arrow
button.callback = function() return 'emote-insert-original' end
button.disabled = true
DropDownList1.dropdown, DropDownList1.shown = owner, true
ns.BindPopupOwner(S, module, owner); flush()
assert(DropDownList1.MenuBackdrop.alpha == 0 and text.font[1] == 'eui-font')
assert(text.color[2] == 0.82 and text.text == '|Temote-art:0|t xqcA' and button.callback() == 'emote-insert-original' and button.disabled)
assert(arrow.color[1] == accent and highlight.color[4] == 0.1)
local layer = DropDownList1.children[#DropDownList1.children]
assert(layer.shell and layer.accent and layer.mouse == false and layer.level < DropDownList1:GetFrameLevel())
-- Submenus inherit root ownership, retaining independent content/actions.
DropDownList2 = frame('Frame', 'DropDownList2'); DropDownList2.shown = true; DropDownList2.dropdown = button
DropDownList2.Backdrop = frame('Frame', nil, DropDownList2)
local sub = frame('Button', nil, DropDownList2); sub.regions = {region('FontString')}
local a, b, c = ToggleDropDownMenu(); assert(a == 'native-original' and b == nil and c == 9)
assert(DropDownList2.Backdrop.alpha == 0 and sub.regions[1].font[1] == 'eui-font', 'submenu exposed native style until timer')
flush()
assert(DropDownList2.Backdrop.alpha == 0 and sub.regions[1].font[1] == 'eui-font')
accent = 0.9; for _, fn in ipairs(looks) do fn() end; flush(); assert(arrow.color[1] == 0.9)
DropDownList1:Hide(); DropDownList2:Hide()
assert(layer.alpha == 0 and DropDownList1.MenuBackdrop.alpha == 1 and text.font[1] == 'native-font')
assert(arrow.color[2] == 0.82 and highlight.color[4] == 1)
-- Reuse for an unrelated addon must not inherit our overlay or font.
DropDownList1.dropdown, DropDownList1.shown = unrelated, true
ToggleDropDownMenu(); flush()
assert(layer.alpha == 0 and text.font[1] == 'native-font' and DropDownList1.MenuBackdrop.alpha == 1)
-- Native changes during owner replacement win over old snapshot values.
DropDownList1.dropdown = owner; ToggleDropDownMenu(); flush()
DropDownList1.dropdown = unrelated; text:SetFont('other-native-font', 17, 'THICKOUTLINE')
ToggleDropDownMenu(); flush(); assert(text.font[1] == 'other-native-font' and text.font[2] == 17)
-- Library menus, independent module toggles and combat deferral.
local emoteOwner = frame()
local emoteModule = {enabled = true}
L_DropDownList1 = frame('Frame', 'L_DropDownList1'); L_DropDownList1.dropdown, L_DropDownList1.shown = emoteOwner, true
L_DropDownList1.Backdrop = frame('Frame', nil, L_DropDownList1)
ns.BindPopupOwner(S, emoteModule, emoteOwner); assert(lib:ToggleDropDownMenu() == 'lib-original'); flush()
assert(L_DropDownList1.Backdrop.alpha == 0)
emoteModule.enabled = false; for _, fn in ipairs(looks) do fn() end; flush()
assert(L_DropDownList1.Backdrop.alpha == 1)
emoteModule.enabled = true; combat = true; ns.RefreshPopupMenus(); flush(); assert(L_DropDownList1.Backdrop.alpha == 1)
combat = false; events.scripts.OnEvent(events, 'PLAYER_REGEN_ENABLED'); flush(); assert(L_DropDownList1.Backdrop.alpha == 0)
L_DropDownList1:Hide()
-- Questie's private menu namespace paints immediately and restores on native reuse.
local questOwner = frame(); local questModule = {enabled = true}
L_DropDownListQuestie1 = frame('Frame', 'L_DropDownListQuestie1')
L_DropDownListQuestie1.dropdown, L_DropDownListQuestie1.shown = questOwner, true
L_DropDownListQuestie1.Backdrop = frame('Frame', nil, L_DropDownListQuestie1)
ns.BindPopupOwner(S, questModule, questOwner)
assert(questLib:ToggleDropDownMenu() == 'quest-menu-native')
assert(L_DropDownListQuestie1.Backdrop.alpha == 0, 'Questie menu deferred past first draw')
L_DropDownListQuestie1.dropdown = unrelated; questLib:UIDropDownMenu_AddButton()
assert(L_DropDownListQuestie1.Backdrop.alpha == 1, 'Questie menu reuse lost native style')
L_DropDownListQuestie1:Hide()
-- AddonFactory's unnamed pool is registered explicitly and restores on reuse.
local custom = frame('Button'); custom.Backdrop = frame('Frame', nil, custom)
local customRow = frame('Button', nil, custom); local customText = region('FontString')
customRow.regions = {customText}; customRow.GetFontString = function() return customText end
customRow.callback = function() return 'original-options-action' end
customRow.Check, customRow.UnCheck = region(), region()
customRow.UnCheck.shown = false
function custom:Toggle(dropdown) self.dropdown = dropdown; self.shown = true; return nil, 31 end
ns.BindPopupList(S, emoteModule, emoteOwner, custom)
local missing, extra = custom:Toggle(emoteOwner)
assert(missing == nil and extra == 31 and custom.Backdrop.alpha == 0, 'custom menu first-frame paint/returns lost')
assert(customText.font[1] == 'eui-font' and customRow.callback() == 'original-options-action')
assert(customRow.Check.alpha == 0 and customRow.regions[2].alpha == 1 and customRow.regions[3].alpha == 0)
customRow.Check.shown, customRow.UnCheck.shown = false, true
customRow.hooks.OnClick()
assert(customRow.regions[2].alpha == 0 and customRow.regions[3].alpha == 1, 'live menu marker state lost')
local customLayer = custom.children[#custom.children]
custom:Hide(); assert(custom.Backdrop.alpha == 1 and customLayer.alpha == 0)
assert(customRow.Check.alpha == 0.8 and customRow.regions[2].alpha == 0 and customRow.regions[3].alpha == 0, 'native marker restoration lost')
custom:Toggle(unrelated)
assert(customText.font[1] == 'native-font' and custom.Backdrop.alpha == 1 and customLayer.alpha == 0, 'unrelated pool owner inherited skin')
custom:Toggle(emoteOwner); assert(custom.Backdrop.alpha == 0)
-- Modern Menu.GetManager() proxies expose their current owner publicly.
local modern = frame('Frame'); modern.NineSlice = frame('Frame', nil, modern)
modern.shown, modern.owner = true, emoteOwner
function modern:GetOwnerRegion() return self.owner end
local attached, allocatedFonts = 0, 0
local textures = {}
function modern:AttachTexture()
    attached = attached + 1
    -- Reuse the same native pool across menu acquisitions.
    local tex = textures[attached] or region(); textures[attached] = tex
    self.regions[attached] = tex
    return tex
end
function modern:CreateTexture() error('compositor CreateTexture forbidden') end
CreateFont = function()
    allocatedFonts = allocatedFonts + 1
    return {SetFont = function(self, ...) self.font = {...} end}
end
local modernRow = frame('Button', nil, modern)
local nativeFont = {font = {'native-font', 13, 'OUTLINE'}}
local modernText = region('FontString'); modernText.SetFont = nil; modernText.fontObject = nativeFont
setmetatable(modernText, {__index = function(_, key) if key == 'SetFont' then error('compositor SetFont forbidden, including lookup') end end})
function modernText:GetFont() return table.unpack(self.fontObject.font) end
function modernText:GetFontObject() return self.fontObject end
modernText.textColor = {0.5, 0.5, 0.5, 0.8}
function modernText:GetTextColor() return table.unpack(self.textColor) end
function modernText:SetTextColor(...) self.textColor = {...} end
function modernText:SetFontObject(value) self.fontObject = value; self.textColor = {1, 1, 1, 1} end
modernRow.regions = {modernText}
modernRow.GetFontString = function() return modernText end
modernRow.callback = function() return 'modern-native-action' end
local description = {initializers = {}}
function description:AddInitializer(callback) self.initializers[#self.initializers + 1] = callback end
function modern:EnumerateElementDescriptions(callback) callback(1, description) end
local function toggleModern()
    -- MenuResponse.Refresh clears pooled row state and runs native initializers
    -- before addon initializers, without closing or reopening the menu.
    modernText.fontObject = nativeFont
    for _, initialize in ipairs(description.initializers) do initialize(modernRow, description, modern) end
    return 'toggle-native'
end
ns.BindPopupList(S, emoteModule, emoteOwner, modern)
assert(modern.NineSlice.alpha == 0, 'modern menu native border was left visible')
assert(modernText:GetFont() == 'eui-font' and modernRow.callback() == 'modern-native-action', 'modern menu font/action lost')
assert(modernText.textColor[1] == 0.5 and modernText.textColor[4] == 0.8, 'modern disabled/text colours were changed')
assert(#modern.children == 2 and attached == 2, 'modern menu created an unmanaged overlay frame')
ns.RefreshPopupMenusNow(); assert(attached == 2, 'warm modern menu refresh allocated duplicate regions')
for _ = 1, 20 do
    assert(toggleModern() == 'toggle-native' and modernText:GetFont() == 'eui-font', 'checkbox refresh reset the modern menu font')
    ns.RefreshPopupMenusNow()
end
assert(#description.initializers == 1 and attached == 2, 'checkbox refresh duplicated initializers or menu regions')
emoteModule.enabled = false; toggleModern()
assert(modernText:GetFontObject() == nativeFont, 'disabled skin initializer still changed menu fonts')
emoteModule.enabled = true; toggleModern()
assert(modernText:GetFont() == 'eui-font')
modern.owner = unrelated; ns.RefreshPopupMenusNow()
assert(modern.NineSlice.alpha == 1, 'modern pooled menu retained another owner skin')
toggleModern(); assert(modernText:GetFontObject() == nativeFont, 'old initializer styled another owner menu')
modern.owner = emoteOwner; ns.RefreshPopupMenusNow()
assert(modern.NineSlice.alpha == 0, 'modern menu failed to restyle for its owner')
modern:Hide(); assert(modern.NineSlice.alpha == 1)
assert(modernText:GetFontObject() == nativeFont, 'modern font-object restoration failed')
for _ = 1, 50 do
    -- Blizzard discards compositor-assigned fields and returns its textures to
    -- the pool. A new acquisition can have a different level and new rows.
    modern.euiAddonSkinsMenuFill, modern.euiAddonSkinsMenuAccent = nil, nil
    modern.owner, modern.shown, attached = emoteOwner, true, 0
    modernText.fontObject = nativeFont
    ns.BindPopupList(S, emoteModule, emoteOwner, modern)
    assert(modern.euiAddonSkinsMenuFill.alpha == 1 and modernText:GetFont() == 'eui-font', 'reopened menu lost its background or text')
    assert(attached == 2 and #modern.children == 2 and modernRow.callback() == 'modern-native-action')
    modern:Hide()
end
assert(allocatedFonts == 1 and #textures == 2, 'modern menu font/texture pool grew on every open')
modern.owner, modern.shown = emoteOwner, true
ns.RefreshPopupMenusNow()
-- A renderer reset may precede our hide callback. Stale snapshot restoration
-- must not modify regions that now belong to an unrelated pooled menu.
modern.euiAddonSkinsMenuFill, modern.euiAddonSkinsMenuAccent = nil, nil
modern.owner = unrelated; modern.NineSlice.alpha = 1; modernText.fontObject = nativeFont
ns.RefreshPopupMenusNow()
assert(modernText:GetFontObject() == nativeFont and modern.NineSlice.alpha == 1, 'stale acquisition restored into a reused menu')
flush()
assert(#errors == 0, table.concat(errors, '\n'))
print('PASS: scoped legacy/library popup/submenu styling, native reuse/restoration, preserved emotes/actions/colors, live accents, independent toggles and combat deferral')

-- Shared confirmation dialogs: texture-only, no font or action setters.
local popup = frame('Frame')
function popup:Show() self.shown = true end
popup.accept = frame('Button', nil, popup)
popup.cancel = frame('Button', nil, popup)
local border = frame('Frame', nil, popup)
local edge, red = region(), region()
border.regions = {edge}; popup.accept.regions = {red}
local text = region('FontString'); popup.regions = {text}
function text:SetFont() error('confirmation font must remain native') end
function text:SetTextColor() error('confirmation colour must remain native') end
local action = function() return 'accepted', nil, 7 end
popup.accept.scripts.OnClick = action
local panels = 0
local dialogLooks = {}
local dialogSkin = {
    Panel = function(layer) panels = panels + 1 end,
    OnLooksChanged = function(fn) dialogLooks[#dialogLooks+1] = fn end,
}
module.enabled = true; combat = false; popup.shown = true
ns.StyleTextureDialog(dialogSkin, module, popup, true)
assert(edge.alpha == 0 and red.alpha == 0 and text.alpha == 0.8)
assert(panels == 3 and popup.accept.scripts.OnClick == action)
local a,b,c = popup.accept.scripts.OnClick(); assert(a=='accepted' and b==nil and c==7)
for _=1,30 do
    ns.StyleTextureDialog(dialogSkin, module, popup, true)
    popup:Hide()
    assert(edge.alpha==0.8 and red.alpha==0.8)
    popup:Show()
    ns.StyleTextureDialog(dialogSkin, module, popup, true)
end
assert(panels==3 and #dialogLooks==1, 'popup reopening allocated layers/hooks')
popup:Show()
assert(edge.alpha==0.8 and red.alpha==0.8, 'visible popup replacement retained previous owner skin')
ns.StyleTextureDialog(dialogSkin, module, popup, true)
ns.StyleTextureDialog(dialogSkin, module, popup, false)
assert(edge.alpha==0.8 and red.alpha==0.8, 'foreign owner retained dialog skin')
combat=true;ns.StyleTextureDialog(dialogSkin,module,popup,true)
assert(edge.alpha==0.8 and panels==3, 'combat created or styled popup')
combat=false;ns.StyleTextureDialog(dialogSkin,module,popup,true)
module.enabled=false;dialogLooks[1]()
assert(edge.alpha==0.8, 'disabled popup skin not restored')
module.enabled=true;popup.protected=true
ns.StyleTextureDialog(dialogSkin,module,popup,true)
assert(edge.alpha==0.8, 'protected popup styled')
print('PASS: texture-only dialogs preserve fonts/actions; restore ownership/toggle/hide; reuse layers and skip combat/protected frames')
