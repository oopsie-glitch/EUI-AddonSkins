-- Official Spy SharedMedia dropdown investigation. No EUI source is loaded.
-- Only the host UI API is modeled; AceGUI, the widget and option callbacks are
-- executed from the SHA256-pinned package extracted by GitHub Actions.
do
local root = os.getenv("SPY_SOURCE")
if not root then
    print("SKIP: official Spy SharedMedia investigation requires SPY_SOURCE")
else
    local function read(path)
        local file = assert(io.open(root .. "/" .. path, "rb"))
        local source = file:read("*a"); file:close()
        return source
    end
    local coreSource = read("Libs/AceGUI-3.0/AceGUI-3.0.lua")
    local prototypeSource = read("Libs/AceGUI-3.0-SharedMediaWidgets/prototypes.lua")
    local widgetSource = read("Libs/AceGUI-3.0-SharedMediaWidgets/StatusbarWidget.lua")
    local optionSource = assert(read("Spy.lua"):match("BarTexture%s*=%s*(%b{})"), "native texture option not found")
    local function wipe(t) for key in pairs(t) do t[key] = nil end; return t end
    local function host(capabilities, profile)
        local counts = {frames=0, textures=0, fonts=0, scripts=0}
        local errors, libraries, minors = {}, {}, {}
        local methods = {}
        function methods:SetPoint(...) self.points[#self.points+1] = {...} end
        function methods:ClearAllPoints() self.points = {} end
        function methods:SetAllPoints(other) self.allPoints = other end
        function methods:SetWidth(value) self.w = value end
        function methods:SetHeight(value) self.h = value end
        function methods:GetWidth() return self.w end
        function methods:GetHeight() return self.h end
        function methods:SetParent(parent) self.parent = parent end
        function methods:GetParent() return self.parent end
        function methods:SetFrameStrata(value) self.strata = value end
        function methods:GetFrameStrata() return self.strata or "MEDIUM" end
        function methods:SetFrameLevel(value) self.level = value end
        function methods:GetFrameLevel() return self.level or 1 end
        function methods:SetClampedToScreen(value) self.clamped = value end
        function methods:EnableMouseWheel(value) self.mouseWheel = value end
        function methods:SetScrollChild(child) self.scrollChild = child end
        function methods:SetVerticalScroll(value) self.scroll = value end
        function methods:SetOrientation(value) self.orientation = value end
        function methods:SetThumbTexture(value) self.thumb = value end
        function methods:SetMinMaxValues(low, high) self.low, self.high = low, high end
        function methods:GetValue() return self.value end
        function methods:SetValue(value)
            if self.value == value then return end
            self.value = value
            if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
        end
        function methods:SetScript(key, value)
            if self.scripts[key] ~= value then counts.scripts = counts.scripts+1 end
            self.scripts[key] = value
        end
        function methods:GetScript(key) return self.scripts[key] end
        function methods:Show()
            if self.shown then return end
            self.shown = true
            if self.scripts.OnShow then self.scripts.OnShow(self) end
        end
        function methods:Hide()
            if not self.shown then return end
            self.shown = false
            if self.scripts.OnHide then self.scripts.OnHide(self) end
        end
        function methods:IsShown() return self.shown end
        function methods:IsVisible() return self.shown end
        function methods:Enable() self.enabled = true end
        function methods:Disable() self.enabled = false end
        function methods:Click()
            if self.enabled ~= false and self.scripts.OnClick then self.scripts.OnClick(self, "LeftButton") end
        end
        function methods:SetText(value) self.textValue = value end
        function methods:GetText() return self.textValue end
        function methods:SetTextColor(...) self.textColor = {...} end
        function methods:SetFont(...) self.font = {...} end
        function methods:GetFont() return table.unpack(self.font or {"native-font", 12, ""}) end
        function methods:SetJustifyH(value) self.justify = value end
        function methods:SetTexture(value) self.texture = value end
        function methods:SetTexCoord(...) self.texCoord = {...} end
        function methods:SetAlpha(value) self.alpha = value end
        function methods:SetHighlightTexture(value) self.highlight = value end
        function methods:SetNormalTexture(value) self.normal = value end
        function methods:SetPushedTexture(value) self.pushed = value end
        function methods:SetDisabledTexture(value) self.disabledTexture = value end
        local function object(kind, parent)
            return setmetatable({kind=kind,parent=parent,points={},scripts={},shown=true,
                w=200,h=20,enabled=true}, {__index=methods})
        end
        function methods:CreateTexture()
            counts.textures = counts.textures+1
            return object("Texture", self)
        end
        function methods:CreateFontString()
            counts.fonts = counts.fonts+1
            return object("FontString", self)
        end
        local env = {
            assert=assert,error=error,ipairs=ipairs,pairs=pairs,next=next,type=type,
            tostring=tostring,select=select,setmetatable=setmetatable,rawget=rawget,
            unpack=table.unpack,xpcall=xpcall,math=math,string=string,wipe=wipe,
            table=setmetatable({wipe=wipe}, {__index=table}),
        }
        env._G = env
        env.UIParent = object("Frame"); env.UIParent.h = 900
        env.geterrorhandler = function() return function(err) errors[#errors+1] = err end end
        local created = {}
        env.CreateFrame = function(kind, name, parent, template)
            local frame = object(kind, parent)
            counts.frames = counts.frames+1
            frame.template = template
            local backdrop = capabilities == "legacy" or capabilities == "all-backdrops-control"
                or capabilities == "frame-only-control" and kind == "Frame"
                or template and template:find("BackdropTemplate", 1, true)
            if backdrop then
                function frame:SetBackdrop(value) self.backdrop = value end
                function frame:GetBackdrop() return self.backdrop end
                function frame:SetBackdropColor(...) self.fill = {...} end
                function frame:SetBackdropBorderColor(...) self.border = {...} end
            end
            created[#created+1] = frame
            return frame
        end
        local media = {textures={Flat="native-flat", Smooth="native-smooth"}}
        -- Enough native entries to exercise the popup's scroll branch.
        for i=1,30 do media.textures[("Texture %02d"):format(i)] = "native-" .. i end
        function media:HashTable() return self.textures end
        function media:Fetch(_, key) return self.textures[key] or "native-default" end
        libraries["LibSharedMedia-3.0"] = media
        env.LibStub = setmetatable({
            NewLibrary=function(_, name, version)
                if minors[name] and minors[name] >= version then return nil end
                local previous = minors[name]
                minors[name] = version; libraries[name] = libraries[name] or {}
                return libraries[name], previous
            end,
        }, {__call=function(_,name) return assert(libraries[name], name) end})
        env.SM = media
        env.L = setmetatable({}, {__index=function(_,key) return key end})
        env.Spy = {db={profile=profile}, textureUpdates=0}
        function env.Spy:UpdateBarTextures() self.textureUpdates = self.textureUpdates+1 end
        local function source(code, name) return assert(load(code, "@" .. name, "t", env))() end
        local function loadLibraries()
            source(coreSource, "Spy/Libs/AceGUI-3.0/AceGUI-3.0.lua")
            source(prototypeSource, "Spy/Libs/AceGUI-3.0-SharedMediaWidgets/prototypes.lua")
            source(widgetSource, "Spy/Libs/AceGUI-3.0-SharedMediaWidgets/StatusbarWidget.lua")
        end
        loadLibraries()
        local ace = libraries["AceGUI-3.0"]
        local option = source("return " .. optionSource, "Spy-native-BarTexture-option")
        local function acquire()
            local widget = assert(ace:Create(option.dialogControl))
            widget:SetList(option.values)
            widget:SetValue(option.get())
            widget:SetCallback("OnValueChanged", function(self, _, value)
                option.set(nil, value)
                self:SetValue(option.get())
            end)
            widget.frame:Show()
            return widget
        end
        return {env=env,ace=ace,counts=counts,errors=errors,created=created,
            acquire=acquire,reloadLibraries=loadLibraries,option=option}
    end
    -- Fresh environments: no EUI globals, skin factory, helpers or hooks exist.
    for _, mode in ipairs({"modern", "frame-only-control"}) do
        local h = host(mode, {BarTexture="Smooth"})
        assert(h.env.EllesmereUI == nil and h.env.EUIAddonSkins == nil)
        local widget = h.acquire()
        local ok, err = pcall(function() widget.frame.dropButton:Click() end)
        assert(not ok and tostring(err):find("SetBackdrop", 1, true), tostring(err))
        local last = h.created[#h.created]
        if mode == "modern" then
            assert(tostring(err):find("prototypes.lua:211:", 1, true), tostring(err))
            assert(last.kind == "Frame" and last.template == nil)
        else
            assert(last.kind == "Slider" and last.template == nil, "first-call-only repair masked Slider failure")
        end
        assert(h.env.Spy.textureUpdates == 0 and h.option.get() == "Smooth")
        print("REPRO WITHOUT EUI: " .. mode .. " fails on missing SetBackdrop in " .. last.kind)
    end
    -- Capability controls, not production patches. Official source stays intact.
    -- They prove that the native constructor, callbacks and pools work when
    -- the backdrop API assumed by that source is available.
    for _, mode in ipairs({"legacy", "all-backdrops-control"}) do
        local saved = {BarTexture="Smooth"}
        local h = host(mode, saved)
        local widget = h.acquire()
        local enter, leave = 0, 0
        widget:SetCallback("OnEnter", function() enter=enter+1 end)
        widget:SetCallback("OnLeave", function() leave=leave+1 end)
        widget.frame.dropButton:GetScript("OnEnter")(widget.frame.dropButton)
        widget.frame.dropButton:GetScript("OnLeave")(widget.frame.dropButton)
        assert(enter==1 and leave==1, "native tooltip events lost")
        widget:SetDisabled(true); widget.frame.dropButton:Click()
        assert(widget.dropdown == nil, "disabled button opened popup")
        widget:SetDisabled(false); widget.frame.dropButton:Click()
        local popup = assert(widget.dropdown)
        assert(#popup.contentRepo==32 and popup.slider:IsShown(), "native scroll path not exercised")
        local selected
        for _, row in ipairs(popup.contentRepo) do
            assert(row.bar.texture == h.option.values[row.text:GetText()], "native texture preview changed")
            if row.text:GetText()=="Flat" then selected=row end
        end
        assert(selected):Click()
        assert(saved.BarTexture=="Flat" and h.env.Spy.textureUpdates==1 and widget.dropdown==nil)
        widget.frame.dropButton:Click()
        assert(widget.dropdown==popup, "popup not reused")
        local checks=0
        for _, row in ipairs(popup.contentRepo) do
            if row.check:IsShown() then
                checks=checks+1;assert(row.text:GetText()=="Flat", "stale selected check")
            end
        end
        assert(checks==1)
        widget.frame:Hide()
        assert(widget.dropdown==nil and not popup:IsShown(), "OnHide did not return popup")
        h.ace:Release(widget)
        local frames, textures, fonts = h.counts.frames, h.counts.textures, h.counts.fonts
        for i=1,200 do
            local reused = h.acquire()
            assert(reused==widget and reused:GetValue()=="Flat", "native widget pool/preference lost")
            reused.frame.dropButton:Click()
            assert(reused.dropdown==popup)
            h.ace:Release(reused)
            assert(reused.dropdown==nil and not popup:IsShown())
        end
        assert(h.counts.frames==frames and h.counts.textures==textures and h.counts.fonts==fonts,
            "repeated settings reopen grew native objects")
        h.reloadLibraries()
        assert(h.counts.frames==frames and h.counts.textures==textures and h.counts.fonts==fonts,
            "same-version library initialization created duplicate objects")
        assert(#h.errors==0, table.concat(h.errors, "\n"))
        local afterReload = host(mode, saved)
        local restored = afterReload.acquire()
        assert(restored:GetValue()=="Flat" and afterReload.env.Spy.db.profile==saved,
            "fresh-library reload lost the native saved texture")
        restored.frame.dropButton:Click()
        afterReload.ace:Release(restored)
        assert(#afterReload.errors==0, table.concat(afterReload.errors, "\n"))
        print("PASS NATIVE CAPABILITY CONTROL: " .. mode ..
            "; real AceGUI/widget/option callbacks, selection, disabled/tooltip events, hide/release, 200 reopens, reload; bounded objects")
    end
end
end
