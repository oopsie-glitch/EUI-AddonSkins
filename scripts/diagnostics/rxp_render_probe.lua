-- Injected only into the explicit RestedXP diagnostic ZIP. This file lives
-- inside the skin factory after its private render state is declared.
local function InstallRenderProbe()
    if not SlashCmdList then return function() end end
    local active, deadline, lines, previous
    local ids = setmetatable({}, {__mode = "k"})
    local watched = setmetatable({}, {__mode = "k"})
    local nextID, watchedCount, callbackCount = 0, 0, 0
    local function read(object, method, ...)
        if object and type(object[method]) == "function" then return object[method](object, ...) end
    end
    local function scalar(value)
        if issecretvalue and issecretvalue(value) then return "<secret>" end
        local kind = type(value)
        if kind == "number" then return ("%.3f"):format(value) end
        if kind == "string" then return value:gsub("[%c]", " "):sub(1, 240) end
        if kind == "boolean" then return tostring(value) end
        return "-"
    end
    local function values(...)
        local result = {}
        for i = 1, select("#", ...) do result[i] = scalar(select(i, ...)) end
        return table.concat(result, ",")
    end
    local function usable(object)
        return object and not read(object, "IsForbidden")
    end
    local function id(object)
        if not usable(object) then return "-" end
        if not ids[object] then nextID = nextID + 1; ids[object] = nextID end
        return "#" .. ids[object] .. ":" .. scalar(read(object, "GetName"))
    end
    local function running()
        if active and (GetTime() > deadline or #lines >= 800) then active = false end
        return active and not CombatLocked()
    end
    local function log(message)
        if #lines >= 800 then return end
        lines[#lines + 1] = ("%.3f %s"):format(GetTime(), message)
    end
    local function state(object)
        local layer, sub = read(object, "GetDrawLayer")
        local parent = read(object, "GetParent")
        local backdrop = read(object, "GetBackdrop")
        local point, relative, relativePoint, x, y = read(object, "GetPoint", 1)
        return " parent=" .. id(parent)
            .. " strata/level=" .. values(read(object, "GetFrameStrata") or read(parent, "GetFrameStrata"),
                read(object, "GetFrameLevel") or read(parent, "GetFrameLevel"))
            .. " layer/sub=" .. values(layer, sub)
            .. " shown/visible/alpha/effective=" .. values(read(object, "IsShown"), read(object, "IsVisible"),
                read(object, "GetAlpha"), read(object, "GetEffectiveAlpha") or read(parent, "GetEffectiveAlpha"))
            .. " scale=" .. values(read(object, "GetEffectiveScale") or read(parent, "GetEffectiveScale"))
            .. " rect=" .. values(read(object, "GetRect"))
            .. " anchor=" .. values(point, relativePoint, x, y) .. "@" .. id(relative)
            .. " atlas=" .. values(read(object, "GetAtlas"))
            .. " texture=" .. values(read(object, "GetTexture"))
            .. " vertex=" .. values(read(object, "GetVertexColor"))
            .. " blend=" .. values(read(object, "GetBlendMode"))
            .. " backdrop=" .. values(backdrop and backdrop.bgFile, backdrop and backdrop.edgeFile)
            .. " fill=" .. values(read(object, "GetBackdropColor"))
            .. " edge=" .. values(read(object, "GetBackdropBorderColor"))
    end
    local textureMethods = {"SetTexture", "SetAtlas", "SetColorTexture", "SetAlpha", "SetVertexColor",
        "SetDrawLayer", "SetShown", "Hide", "Show", "SetParent", "SetGradient"}
    local frameMethods = {"SetAlpha", "SetShown", "Hide", "Show", "SetFrameLevel", "SetFrameStrata",
        "SetParent", "SetScale", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor"}
    local function watch(object, label, texture)
        if watched[object] or watchedCount >= 96 or read(object, "IsProtected") then return end
        watchedCount = watchedCount + 1
        local info = {label = label, last = state(object), arguments = {}}
        watched[object] = info
        for _, method in ipairs(texture and textureMethods or frameMethods) do
            if type(object[method]) == "function" then
                hooksecurefunc(object, method, function(_, ...)
                    if not running() or not usable(object) then return end
                    local value = state(object)
                    local arguments
                    if method == "SetColorTexture" or method == "SetGradient" or method == "SetTexture" or method == "SetAtlas" then
                        arguments = values(...)
                        if info.last == value and info.arguments[method] == arguments then return end
                        info.arguments[method] = arguments
                    elseif info.last == value then return end
                    info.last = value
                    local stack = debugstack and debugstack(2, 7, 0) or ""
                    log("WRITE " .. id(object) .. " " .. info.label .. "." .. method .. value
                        .. (arguments and " args=" .. arguments or "") .. " stack=" .. stack:gsub("[%c]", " "):sub(1, 740))
                end)
            end
        end
    end
    local function snapshot(label)
        if not running() then return end
        local eui = _G.EllesmereUI
        local profile = eui and eui.GetActiveProfileData and eui.GetActiveProfileData()
        local look = eui and eui.ProfileWindowSkinLook
            and eui.ProfileWindowSkinLook(profile, EllesmereUIDB and EllesmereUIDB.fonts)
        local legacy = addon.RXPFrame or _G.RXPFrame
        local v2 = addon.v2 and addon.v2.state
        local window = v2 and v2.guideWindow or _G.RXPV2GuideWindow
        local mode = addon.v2 and addon.v2.IsGuideWindowEnabled and addon.v2:IsGuideWindowEnabled()
        local loaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
        log("SNAP " .. label .. " v2Enabled=" .. values(mode) .. " rawLook=" .. values(profile and profile.windowSkinLook)
            .. " resolvedLook=" .. values(look) .. " foreverGate=" .. values(ForeverLook()) .. " foreverClient=" .. values(eui and eui.IS_FOREVER)
            .. " nativeTheme=" .. values(addon.settings and addon.settings.profile and addon.settings.profile.activeTheme)
            .. " naowhLoaded=" .. values(loaded and loaded("NaowhForever")))
        local current, visited = {}, {}
        local function record(object, path, trace)
            if not usable(object) or visited[object] then return end
            visited[object] = true
            local key = id(object)
            local texture = read(object, "GetObjectType") == "Texture"
            local observed = state(object)
            local line = path .. " " .. key .. observed
            current[key] = line
            if previous[key] ~= line then log("STATE " .. line) end
            if watched[object] then watched[object].last = observed
            elseif trace then watch(object, path, texture) end
        end
        local function regions(frame, path, trace, limit)
            if not usable(frame) or not frame.GetRegions then return end
            local count = 0
            for _, region in ipairs({frame:GetRegions()}) do
                if usable(region) and read(region, "GetObjectType") == "Texture" then
                    count = count + 1
                    record(region, path .. ".texture" .. count, trace)
                    if count >= (limit or 12) then break end
                end
            end
        end
        local function surface(frame, path)
            if not usable(frame) then return end
            local entry = themed[frame]
            local owned = compositions[frame]
            if owned then
                record(owned, path .. ".EUIAS.composition", true)
                regions(owned, path .. ".EUIAS.composition", true)
            end
            if entry then
                path = path .. (entry.joinedBody and "[joined]" or "")
                record(entry.layer, path .. ".EUIAS.panelHost", true)
                record(entry.art, path .. ".EUIAS.artHost", true)
                regions(entry.art, path .. ".EUIAS.art", true)
                regions(entry.layer, path .. ".EUI.panel", true)
            end
            record(frame, path, true)
            record(frame.rxpBackground, path .. ".RXP.backgroundGroup", true)
            regions(frame.rxpBackground, path .. ".RXP.backgroundGroup", true, 4)
            record(frame.rxpBorder, path .. ".RXP.borderGroup", true)
            regions(frame.rxpBorder, path .. ".RXP.borderGroup", false, 8)
            record(frame.rxpShadow, path .. ".RXP.shadowGroup")
            regions(frame.rxpShadow, path .. ".RXP.shadowGroup", false, 4)
            regions(frame, path .. ".direct", true, 8)
        end
        local function scrollbar(bar, path)
            if not usable(bar) then return end
            surface(bar, path)
            record(read(bar, "GetThumbTexture"), path .. ".nativeThumb", true)
            record(slimThumbs[bar] and slimThumbs[bar].fill, path .. ".EUIAS.thumb", true)
            record(bar.ScrollUpButton, path .. ".up")
            record(bar.ScrollDownButton, path .. ".down")
        end
        -- Inspect the active renderer first, so the writer budget is spent there.
        local function inspectV1()
            if not legacy then return end
            surface(legacy, "V1.root")
            surface(legacy.CurrentStepFrame, "V1.current")
            local pool = legacy.CurrentStepFrame and legacy.CurrentStepFrame.framePool
            for i = 1, math.min(#(pool or {}), 3) do
                surface(pool[i], "V1.current." .. i)
                surface(pool[i].number, "V1.current.badge." .. i)
            end
            record(legacy.GuideName and legacy.GuideName.bg, "V1.header.nativeBanner", true)
            surface(legacy.GuideName, "V1.header")
            surface(legacy.BottomFrame, "V1.list")
            surface(legacy.ScrollChild, "V1.list.content")
            local rows = legacy.ScrollChild and legacy.ScrollChild.framePool
            for i = 1, math.min(#(rows or {}), 2) do
                record(rowDividers[rows[i]], "V1.list.EUIAS.divider." .. i, true)
                regions(rows[i], "V1.list.row." .. i, false, 4)
            end
            scrollbar(legacy.ScrollFrame and legacy.ScrollFrame.ScrollBar, "V1.scrollbar")
            record(legacy.Footer and legacy.Footer.bg, "V1.footer.nativeBanner", true)
            surface(legacy.Footer, "V1.footer")
            surface(legacy.Footer and legacy.Footer.cog, "V1.footer.settings")
        end
        local function inspectV2()
            if not window then return end
            surface(window.frame, "V2.root")
            surface(window.upperFrame, "V2.upper")
            surface(window.header, "V2.headerParent")
            record(window.banner, "V2.header.nativeBanner", true)
            surface(window.guideNameFrame, "V2.header")
            surface(window.guideStepsFrame, "V2.list")
            record(window.footerBackground, "V2.footer.nativeFill", true)
            surface(window.footer, "V2.footer")
            local scroll = window.guideSteps and window.guideSteps.scroll
            scrollbar(scroll and scroll.scrollbar, "V2.scrollbar")
            local rows = window.guideSteps and window.guideSteps.items
            local sampled = 0
            for _, item in pairs(rows or {}) do
                if usable(item.frame) and read(item.frame, "IsShown") then
                    sampled = sampled + 1
                    record(rowDividers[item.frame], "V2.list.EUIAS.divider." .. sampled, true)
                    regions(item.frame, "V2.list.row." .. sampled, false, 4)
                    if sampled == 2 then break end
                end
            end
            local players = 0
            for _, player in pairs(v2 and v2.player or {}) do
                local steps = player.activeStepFrame
                if steps then
                    players = players + 1
                    surface(steps.frame, "V2.current." .. players)
                    local count = 0
                    for _, child in pairs(steps.children or {}) do
                        count = count + 1
                        surface(child.card or child.frame, "V2.current.card." .. players .. "." .. count)
                        surface(child.title, "V2.current.badge." .. players .. "." .. count)
                        if count == 2 then break end
                    end
                    if players == 2 then break end
                end
            end
        end
        if mode then inspectV2(); record(legacy, "V1.root") else inspectV1(); record(window and window.frame, "V2.root") end
        surface(_G.NaowhRXPWindow, "Naowh.replacement")
        for key in pairs(previous) do
            if not current[key] then log("UNTRACKED " .. key) end
        end
        previous = current
    end
    local callbacks = setmetatable({}, {__mode = "k"})
    local function observe(object, method, label)
        if not object or type(object[method]) ~= "function" or callbackCount >= 24 then return end
        callbacks[object] = callbacks[object] or {}
        if callbacks[object][method] then return end
        callbacks[object][method] = true
        callbackCount = callbackCount + 1
        hooksecurefunc(object, method, function()
            if running() then log("RETURN " .. label .. "." .. method) end
        end)
    end
    local function checkpoint(label)
        if not running() then return end
        snapshot(label)
        local legacy = addon.RXPFrame or _G.RXPFrame
        observe(legacy, "UpdateVisuals", "RXP.V1")
        observe(legacy, "UpdateScrollBar", "RXP.V1")
        local window = addon.v2 and addon.v2.state and addon.v2.state.guideWindow or _G.RXPV2GuideWindow
        observe(window, "UpdateTheme", "RXP.V2")
        observe(window, "UpdateSubTheme", "RXP.V2")
        observe(window, "UpdateFrameLayout", "RXP.V2")
        observe(window, "SetSnapshot", "RXP.V2")
    end
    SLASH_EUIRXPRENDER1 = "/rxprender"
    SlashCmdList.EUIRXPRENDER = function(message)
        local command, label = message:match("^(%S+)%s*(.-)%s*$")
        if command == "clear" then
            active = false
            if EUIAddonSkinsDB then EUIAddonSkinsDB.rxpRenderDiagnostic = nil end
            print("RestedXP render traces cleared.")
        elseif command == "start" and not CombatLocked() then
            EUIAddonSkinsDB = EUIAddonSkinsDB or {}
            local sessions = EUIAddonSkinsDB.rxpRenderDiagnostic or {}
            EUIAddonSkinsDB.rxpRenderDiagnostic = sessions
            while #sessions >= 4 do table.remove(sessions, 1) end
            lines, previous = {}, {}
            sessions[#sessions + 1] = lines
            deadline, active = GetTime() + 180, true
            local metadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
            log("BUILD " .. RXPRENDER_BUILD_ID .. " run=" .. scalar(label)
                .. " versions(RXP/EUI/Naowh)=" .. values(metadata and metadata("RXPGuides", "Version"),
                    metadata and metadata("EllesmereUI", "Version"), metadata and metadata("NaowhForever", "Version")))
            checkpoint("start")
            print("RestedXP capture started (180 seconds or 800 lines).")
        elseif command == "snap" and running() then
            checkpoint(label ~= "" and scalar(label) or "manual")
            print("RestedXP snapshot saved (" .. #lines .. " lines).")
        elseif command == "stop" then
            active = false
            print("RestedXP capture stopped. /reload writes EUIAddonSkins.lua under account SavedVariables.")
        else
            print("/rxprender start LABEL | snap LABEL | stop | clear (outside combat)")
        end
    end
    return checkpoint
end
local renderProbe = InstallRenderProbe()
