-- LevelGuide: lógica de la ruta.
-- Igual que las guías de leveo más usadas (RestedXP, Zygor, Guidelime):
-- una ruta fija de pasos (viajar, aceptar, hacer, entregar). El paso activo
-- es el primero de esa ruta que aún no has hecho. No elige según la zona
-- en la que estés ni según las demás misiones del diario.
-- Sin clases, talentos ni rotaciones.

local _, NS = ...

NS.recent = {} -- misiones entregadas en esta sesión (más reciente primero)

NS.ICON = {
    turnin  = "Interface\\Icons\\INV_Misc_Coin_01",
    quest   = "Interface\\Icons\\INV_Misc_Note_01",
    avail   = "Interface\\Icons\\INV_Letter_15",
    map     = "Interface\\Icons\\INV_Misc_Map_01",
    dungeon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
    book    = "Interface\\Icons\\INV_Misc_Book_09",
    note    = "Interface\\Icons\\INV_Misc_Note_01",
    warn    = "Interface\\DialogFrame\\DialogAlertIcon",
    ok      = "Interface\\RaidFrame\\ReadyCheck-Ready",
    wait    = "Interface\\RaidFrame\\ReadyCheck-Waiting",
    info    = "Interface\\FriendsFrame\\InformationIcon",
}
local ICON = NS.ICON

------------------------------------------------------------------------
-- Utilidades
------------------------------------------------------------------------
function NS.factionCode()
    return UnitFactionGroup("player") == "Horde" and "H" or "A"
end

local function startKey(key)
    if key == "START" then
        return NS.StartZone[select(2, UnitRace("player"))] or key
    end
    return key
end
NS.startKey = startKey

local function sameZone(a, b)
    return a and b and a ~= "" and b ~= "" and a:lower() == b:lower()
end
NS.sameZone = sameZone

local function currentMapID()
    local ok, id = pcall(function()
        if C_Map and C_Map.GetBestMapForUnit then return C_Map.GetBestMapForUnit("player") end
    end)
    return ok and id or nil
end

-- ¿Es "current" (nombre de zona) la zona `key`? También compara por ID de mapa.
local function zoneMatches(key, current)
    local zn = NS.Zones[startKey(key)]
    if not zn then return false end
    if sameZone(zn.en, current) or sameZone(zn.es, current) then return true end
    local id = currentMapID()
    return (id and zn.map and id == zn.map) and true or false
end
NS.zoneMatches = zoneMatches

-- Clave de zona a partir del nombre mostrado por el cliente
function NS.zoneKeyByName(name)
    for key, zn in pairs(NS.Zones) do
        if sameZone(zn.en, name) or sameZone(zn.es, name) then return key end
    end
    local id = currentMapID()
    if id then
        for key, zn in pairs(NS.Zones) do
            if zn.map and zn.map == id then return key end
        end
    end
end

function NS.zoneLabel(key)
    key = startKey(key)
    local zn = NS.Zones[key]
    if not zn then return NS.L("task.startZone") end
    if NS.Lang() == "es" and zn.es and zn.es ~= zn.en then
        return zn.es .. " (" .. zn.en .. ")"
    end
    return zn.en
end

function NS.zoneLevels(key)
    if key == "START" then return "1-10" end
    local zn = NS.Zones[key]
    if not zn then return "?" end
    if zn.min == zn.max then return tostring(zn.min) end
    return zn.min .. "-" .. zn.max
end

function NS.currentLevel()
    return NS.forcedLevel or UnitLevel("player")
end

-- Pueblos adecuados para un nivel dentro de una zona (el más avanzado primero)
function NS.HubsFor(key, level, fc)
    key = startKey(key)
    local list = NS.Hubs[key]
    if not list then return {} end
    local out = {}
    for _, hub in ipairs(list) do
        if (not hub.faction or hub.faction == fc) and level <= hub.hi and level >= hub.lo - 2 then
            out[#out + 1] = hub
        end
    end
    if #out == 0 then
        for _, hub in ipairs(list) do
            if (not hub.faction or hub.faction == fc) and level <= hub.hi then out[#out + 1] = hub end
        end
    end
    if #out == 0 then
        for _, hub in ipairs(list) do
            if not hub.faction or hub.faction == fc then out[#out + 1] = hub end
        end
    end
    table.sort(out, function(a, b) return a.lo > b.lo end)
    return out
end

function NS.HubText(key, level, fc)
    local list = NS.HubsFor(key, level, fc)
    if #list == 0 then return nil end
    local names = {}
    for i, hub in ipairs(list) do
        names[#names + 1] = hub.name
        if i >= 2 then break end
    end
    return table.concat(names, " / ")
end

-- Mazmorras para tu nivel: las que ya puedes hacer y aún te sirven, la más avanzada primero
function NS.DungeonsFor(level, fc)
    local out = {}
    for _, dg in ipairs(NS.Dungeons) do
        local fOk = (not dg.faction) or dg.faction == fc
        local inRange = level >= dg.lo and level <= dg.hi and (level < dg.hi or dg.hi >= NS.MAX_LEVEL)
        if fOk and inRange then out[#out + 1] = dg end
    end
    table.sort(out, function(a, b)
        local aq, bq = (a.quests or 0) > 0, (b.quests or 0) > 0
        if aq ~= bq then return aq end
        return a.lo > b.lo
    end)
    return out
end

-- Estado de una mazmorra respecto a tu nivel: "now", "soon", "past" o "locked"
function NS.DungeonState(dg, level, fc)
    if dg.faction and dg.faction ~= fc then return "locked" end
    if level > dg.hi or (level == dg.hi and dg.hi < NS.MAX_LEVEL) then return "past" end
    if level >= dg.lo then return "now" end
    if level >= dg.lo - 3 then return "soon" end
    return "later"
end

-- Abre el mapa del mundo en una zona (si conocemos su ID de mapa)
function NS.OpenMap(key)
    key = startKey(key)
    local zn = NS.Zones[key]
    if zn then
        NS.msg(NS.Lf("msg.go", NS.zoneLabel(key), NS.zoneLevels(key)))
    end
    if zn and zn.map then
        pcall(function()
            if OpenWorldMap then
                OpenWorldMap(zn.map)
            elseif WorldMapFrame then
                ShowUIPanel(WorldMapFrame)
                WorldMapFrame:SetMapID(zn.map)
            end
        end)
    elseif zn then
        NS.msg(NS.L("msg.noMap"))
    end
end

-- Marca una misión: la sigue en el objetivo y la señala en el mapa
function NS.TrackQuest(qid, title)
    if not qid then return end
    pcall(function() if C_QuestLog.AddQuestWatch then C_QuestLog.AddQuestWatch(qid) end end)
    pcall(function()
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
            C_SuperTrack.SetSuperTrackedQuestID(qid)
        end
    end)
    local extra = title and NS.Lf("msg.trackedTitle", title) or ""
    NS.msg(NS.Lf("msg.tracked", extra))
end

------------------------------------------------------------------------
-- Diario de misiones
------------------------------------------------------------------------
local function greenRange()
    local ok, r = pcall(function() return GetQuestGreenRange and GetQuestGreenRange("player") end)
    return (ok and tonumber(r)) or 8
end

local function dungeonLabel(title)
    if not title or title == "" then return nil end
    local name = title:gsub("^Mazmorra:%s*", ""):gsub("^Dungeon:%s*", "")
    return NS.DungeonName(name)
end

function NS.ScanQuests()
    local list, header = {}, nil
    local QL = C_QuestLog
    local n = 0
    if QL and QL.GetNumQuestLogEntries then
        n = QL.GetNumQuestLogEntries() or 0
    elseif GetNumQuestLogEntries then
        n = GetNumQuestLogEntries() or 0
    end
    local plevel = NS.currentLevel()
    local gr = greenRange()
    for i = 1, n do
        local title, qid, isHeader, level, complete
        if QL and QL.GetInfo then
            local info = QL.GetInfo(i)
            if info and not info.isHidden then
                title, qid, isHeader, level = info.title, info.questID, info.isHeader, info.level
                if not isHeader and qid and QL.IsComplete then complete = QL.IsComplete(qid) end
            end
        elseif GetQuestLogTitle then
            local t, lv, _, hdr, _, comp, _, id = GetQuestLogTitle(i)
            title, level, isHeader, qid = t, lv, hdr, id
            complete = (comp == 1)
        end
        if title then
            if isHeader then
                header = title
            else
                local f, r = 0, 0
                if QL and QL.GetQuestObjectives and qid then
                    for _, o in ipairs(QL.GetQuestObjectives(qid) or {}) do
                        if o.numRequired and o.numRequired > 0 then
                            f = f + (o.numFulfilled or 0)
                            r = r + o.numRequired
                        end
                    end
                end
                level = level or 0
                list[#list + 1] = {
                    id = qid, title = title, level = level, zone = header or "",
                    complete = complete and true or false, f = f, r = r,
                    -- gris = da muy poca XP (se compara como hace el juego)
                    grey = level > 0 and (plevel - level) > gr or false,
                }
            end
        end
    end
    return list
end

-- Total de misiones completadas según el servidor (si el cliente lo permite)
function NS.TotalCompleted()
    local ok, n = pcall(function()
        if C_QuestLog and C_QuestLog.GetAllCompletedQuestIDs then
            return #C_QuestLog.GetAllCompletedQuestIDs()
        end
    end)
    if ok and n then return n end
    return NS.cfg and NS.cfg.turnedIn or 0
end

NS.On("QUEST_TURNED_IN", function(questID)
    local cfg = NS.cfg
    if not cfg then return end
    local title
    pcall(function() title = C_QuestLog.GetTitleForQuestID(questID) end)
    table.insert(NS.recent, 1, { id = questID, title = title or NS.Lf("task.questFallback", questID or "?"), zone = GetRealZoneText() or "" })
    while #NS.recent > 8 do table.remove(NS.recent) end
    cfg.turnedIn = (cfg.turnedIn or 0) + 1
    cfg.doneQuests = cfg.doneQuests or {}
    cfg.doneQuests[questID] = true
    if NS.NoteQuestDone then NS.NoteQuestDone(questID) end
    local zone = GetRealZoneText() or ""
    if zone ~= "" then cfg.zoneDone[zone] = (cfg.zoneDone[zone] or 0) + 1 end
    NS.RequestRefresh()
end)

------------------------------------------------------------------------
-- Ruta fija. El paso en curso es el primero que la guía aún no da por hecho.
------------------------------------------------------------------------
local doneMemo = {}

local function cacheCompleted()
    if NS._doneLoaded then return end
    local ids
    local ok = pcall(function()
        if C_QuestLog and C_QuestLog.GetAllCompletedQuestIDs then
            ids = C_QuestLog.GetAllCompletedQuestIDs()
        end
    end)
    if not (ok and type(ids) == "table") then return end
    NS._doneLoaded = true
    for _, id in ipairs(ids) do doneMemo[id] = true end
    local saved = NS.cfg and NS.cfg.doneQuests
    if saved then
        for id, v in pairs(saved) do
            if v then doneMemo[tonumber(id) or id] = true end
        end
    end
end

local function isTurnedIn(id)
    local v = doneMemo[id]
    if v ~= nil then return v end
    if NS._doneLoaded then
        doneMemo[id] = false
        return false
    end
    local flag = false
    pcall(function()
        if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
            flag = C_QuestLog.IsQuestFlaggedCompleted(id) and true or false
        elseif IsQuestFlaggedCompleted then
            flag = IsQuestFlaggedCompleted(id) and true or false
        end
    end)
    doneMemo[id] = flag
    return flag
end

function NS.NoteQuestDone(id)
    if id then doneMemo[id] = true end
end

function NS.SetWaypoint(map, x, y)
    if not map or map == 0 or not x or not y or (x == 0 and y == 0) then return end
    pcall(function()
        if not (C_Map and C_Map.SetUserWaypoint and CreateVector2D) then return end
        C_Map.SetUserWaypoint({ uiMapID = map, position = CreateVector2D(x / 100, y / 100) })
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
    end)
end

local function showWorldMap(map)
    if not map or map == 0 then return end
    local function focus()
        if not WorldMapFrame then return end
        if WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(map) end
        if NS.RefreshPickupPins then NS.RefreshPickupPins() end
    end
    if OpenWorldMap then
        OpenWorldMap(map)
    elseif C_Map and C_Map.OpenWorldMap then
        C_Map.OpenWorldMap(map)
    elseif WorldMapFrame then
        ShowUIPanel(WorldMapFrame)
    end
    focus()
    if C_Timer and C_Timer.After then C_Timer.After(0.15, focus) end
end

-- Abre el mapa en el sitio exacto. Si aún no la tienes, manda al NPC que la da,
-- no al mapa de la zona en la que estás.
function NS.OpenQuestMap(questID, map, x, y)
    local inLog = false
    pcall(function()
        if questID and C_QuestLog and C_QuestLog.IsOnQuest then inLog = C_QuestLog.IsOnQuest(questID) and true or false end
    end)
    local wpMap, wpX, wpY = map, x, y
    if inLog then
        pcall(function()
            if questID and C_QuestLog and C_QuestLog.GetNextWaypoint then
                local m, px, py = C_QuestLog.GetNextWaypoint(questID)
                if m and px and py and not (px == 0 and py == 0) then
                    wpMap, wpX, wpY = m, px * 100, py * 100
                end
            end
        end)
        pcall(function()
            if C_QuestLog and C_QuestLog.AddQuestWatch then C_QuestLog.AddQuestWatch(questID) end
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
                C_SuperTrack.SetSuperTrackedQuestID(questID)
            end
        end)
    end
    NS.SetWaypoint(wpMap, wpX, wpY)
    if not inLog and wpMap and wpMap ~= 0 then
        showWorldMap(wpMap)
        return
    end
    local opened = false
    pcall(function()
        if questID and QuestMapFrame_OpenToQuestDetails then
            QuestMapFrame_OpenToQuestDetails(questID)
            opened = true
        end
    end)
    if not opened then showWorldMap(wpMap) end
    if NS.RefreshPickupPins then NS.RefreshPickupPins() end
end

------------------------------------------------------------------------
-- Iconos en el mapa del mundo: dónde se coge cada misión que toca aceptar
------------------------------------------------------------------------
local mapPins, pickupPins = {}, {}

local function pinSpot(shownMap, map, x, y)
    if map == shownMap then return x / 100, y / 100 end
    if not (C_Map and C_Map.GetWorldPosFromMapPos and C_Map.GetMapPosFromWorldPos and CreateVector2D) then return nil end
    local ok, continent, world = pcall(C_Map.GetWorldPosFromMapPos, map, CreateVector2D(x / 100, y / 100))
    if not (ok and continent and world) then return nil end
    local okPos, _, pos = pcall(C_Map.GetMapPosFromWorldPos, continent, world, shownMap)
    if not (okPos and pos) then return nil end
    local px, py = pos:GetXY()
    if not px or px < 0 or px > 1 or py < 0 or py > 1 then return nil end
    return px, py
end

local function makeMapPin(canvas)
    local pin = CreateFrame("Button", nil, canvas)
    pin:SetSize(28, 28)
    pin.glow = pin:CreateTexture(nil, "BACKGROUND")
    pin.glow:SetTexture("Interface\\Cooldown\\star4")
    pin.glow:SetBlendMode("ADD")
    pin.glow:SetVertexColor(1, 0.85, 0.2, 0.85)
    pin.glow:SetPoint("CENTER")
    pin.glow:SetSize(46, 46)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetPoint("CENTER")
    pin.icon:SetSize(22, 22)
    pin.icon:SetTexture("Interface\\Icons\\INV_Letter_15")
    pin.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    pin.count = pin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pin.count:SetPoint("BOTTOMRIGHT", 2, -2)
    pin.count:SetTextColor(1, 0.9, 0.4)
    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(NS.L("msg.pinTitle"), 1, 0.82, 0)
        for _, q in ipairs(self.quests) do
            GameTooltip:AddLine("«" .. q.name .. "»", 1, 1, 1)
        end
        if self.who and self.who ~= "" then GameTooltip:AddLine(self.who, 0.8, 0.8, 0.8) end
        GameTooltip:AddLine(NS.L("msg.pinClick"), 0.6, 0.85, 0.6)
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pin:SetScript("OnClick", function(self)
        NS.SetWaypoint(self.map, self.x, self.y)
        local q = self.quests[1]
        NS.msg(NS.Lf("msg.arrowTo", (self.who ~= "" and self.who or (q and q.name or NS.L("msg.arrowQuest")))))
    end)
    return pin
end

function NS.RefreshPickupPins()
    for _, pin in ipairs(mapPins) do pin:Hide() end
    if not (WorldMapFrame and WorldMapFrame:IsShown() and WorldMapFrame.GetCanvas) then return end
    local canvas = WorldMapFrame:GetCanvas()
    local shown = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    if not (canvas and shown) then return end
    local scale = 1 / ((WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale()) or 1)
    local width, height = canvas:GetWidth(), canvas:GetHeight()
    local n = 0
    for _, spot in ipairs(pickupPins) do
        local x, y = pinSpot(shown, spot.map, spot.x, spot.y)
        if x then
            n = n + 1
            local pin = mapPins[n] or makeMapPin(canvas)
            mapPins[n] = pin
            pin.quests, pin.map, pin.x, pin.y, pin.who = spot.quests, spot.map, spot.x, spot.y, spot.who
            pin.count:SetText(#spot.quests > 1 and tostring(#spot.quests) or "")
            pin:SetParent(canvas)
            pin:SetScale(scale)
            pin:SetFrameStrata("HIGH")
            pin:SetFrameLevel(9000)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", canvas, "TOPLEFT", x * width, -y * height)
            pin:Show()
        end
    end
end

local pinsHooked
local function hookMapPins()
    if pinsHooked or not WorldMapFrame then return end
    pinsHooked = true
    WorldMapFrame:HookScript("OnShow", function()
        if C_Timer and C_Timer.After then C_Timer.After(0, NS.RefreshPickupPins) else NS.RefreshPickupPins() end
    end)
    if hooksecurefunc then
        if WorldMapFrame.OnMapChanged then hooksecurefunc(WorldMapFrame, "OnMapChanged", NS.RefreshPickupPins) end
        if WorldMapFrame.OnCanvasScaleChanged then hooksecurefunc(WorldMapFrame, "OnCanvasScaleChanged", NS.RefreshPickupPins) end
        if WorldMapFrame.OnCanvasSizeChanged then hooksecurefunc(WorldMapFrame, "OnCanvasSizeChanged", NS.RefreshPickupPins) end
    end
end

function NS.SetPickupPins(list, aimArrow)
    local grouped, order = {}, {}
    for _, p in ipairs(list or {}) do
        if p.map and p.map ~= 0 then
            local key = p.map .. ":" .. math.floor((p.x or 0) * 10) .. ":" .. math.floor((p.y or 0) * 10)
            local spot = grouped[key]
            if not spot then
                spot = { map = p.map, x = p.x, y = p.y, who = p.who or "", quests = {} }
                grouped[key] = spot
                order[#order + 1] = spot
            end
            spot.quests[#spot.quests + 1] = { name = p.name, id = p.id }
            if (not spot.who or spot.who == "") and p.who then spot.who = p.who end
        end
    end
    pickupPins = order
    hookMapPins()
    NS.RefreshPickupPins()
    local first = order[1]
    if aimArrow and first and NS.cfg and NS.cfg.arrow ~= false then
        NS.SetWaypoint(first.map, first.x, first.y)
    end
end

-- Objetivo en el idioma del cliente. La base de la ruta está en inglés.
local function clientObjective(id)
    local lines = {}
    local function add(text)
        if type(text) ~= "string" or text == "" then return end
        text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        text = text:gsub("[\r\n]+", " "):gsub("%s+", " ")
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        if text ~= "" then lines[#lines + 1] = text end
    end
    pcall(function()
        if not (C_QuestLog and C_QuestLog.GetQuestObjectives) then return end
        for _, o in ipairs(C_QuestLog.GetQuestObjectives(id) or {}) do
            add(o.text)
        end
    end)
    if #lines > 0 then return table.concat(lines, " ") end
    pcall(function()
        local idx
        if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
            idx = C_QuestLog.GetLogIndexForQuestID(id)
        elseif GetQuestLogIndexByID then
            idx = GetQuestLogIndexByID(id)
        end
        if idx and idx > 0 and GetQuestLogQuestText then
            local _, objectives = GetQuestLogQuestText(idx)
            add(objectives)
        end
    end)
    if #lines > 0 then return table.concat(lines, " ") end
end

local function guideSteps()
    if not NS.Steps then return nil end
    local race = select(2, UnitRace("player"))
    return NS.Steps[race] or (NS.factionCode() == "H" and NS.Steps.Orc or NS.Steps.Human)
end

local function questName(id, fallback)
    local name = fallback or NS.Lf("task.questFallback", id)
    pcall(function()
        if C_QuestLog and C_QuestLog.GetTitleForQuestID then
            local t = C_QuestLog.GetTitleForQuestID(id)
            if type(t) == "string" and t ~= "" then name = t end
        end
    end)
    return name
end

local function place(map, x, y, who)
    local bits = {}
    if who and who ~= "" then bits[#bits + 1] = who end
    if map and map ~= 0 and x and y and not (x == 0 and y == 0) then
        bits[#bits + 1] = string.format("%.1f, %.1f", x, y)
    end
    if #bits == 0 then return nil end
    return table.concat(bits, " · ")
end

function NS.BuildTasks()
    local cfg = NS.cfg
    local steps = guideSteps()
    local quests = NS.ScanQuests()
    NS.quests = quests
    if not steps then
        return {{
            kind = "info", icon = ICON.info, noDismiss = true, key = "noguide", prio = 1,
            title = NS.L("task.noGuide"),
            sub = NS.L("task.noGuideSub"),
        }}
    end

    cacheCompleted()
    local level = NS.currentLevel()
    local log = {}
    for _, q in ipairs(quests) do log[q.id] = q end

    local dungeonAt = {}
    local curDg
    for i, s in ipairs(steps) do
        if s[1] == "G" then
            curDg = (s[4] == 1) and dungeonLabel(s[3]) or nil
        else
            dungeonAt[i] = curDg
        end
    end

    -- Capital enemiga: esa misión no se puede coger con esta facción.
    local enemyCity = NS.factionCode() == "H"
        and { [1453] = true, [1455] = true, [1457] = true }
        or { [1454] = true, [1456] = true, [1458] = true }
    local function wrongFaction(id)
        local info = NS.Qinfo and NS.Qinfo[id]
        if not info then return false end
        local where = info[5]
        if not where or where == 0 then where = info[9] end
        return enemyCity[where] and not log[id]
    end

    local function skippedQuest(id) return cfg.dismissed["q" .. id] end

    -- Una mazmorra renta si lo mejor que queda está a 6 niveles o menos: una sola ida con todas
    -- las misiones. Más baja que eso (Cuevas a nivel 30) se salta. Si renta, entran todas,
    -- también las cortas: ya estás dentro y suman.
    local questDg, dgTop = {}, {}
    for i, s in ipairs(steps) do
        local dg = dungeonAt[i]
        if dg and s[1] ~= "G" then
            local id = s[2]
            questDg[id] = dg
            if not isTurnedIn(id) and not skippedQuest(id) and not wrongFaction(id) then
                local info = NS.Qinfo and NS.Qinfo[id]
                local qlevel = info and info[2] or 0
                if not dgTop[dg] or qlevel > dgTop[dg] then dgTop[dg] = qlevel end
            end
        end
    end
    local liveDg = {}
    for name, top in pairs(dgTop) do
        if top > 0 and (level - top) <= 6 then liveDg[name] = true end
    end

    local keep = {}
    for i = #steps, 1, -1 do
        local s = steps[i]
        if s[1] ~= "G" then
            local id = s[2]
            local dg = dungeonAt[i]
            if not isTurnedIn(id) and not skippedQuest(id) and not wrongFaction(id) and (not dg or liveDg[dg]) then
                local info = NS.Qinfo and NS.Qinfo[id]
                local qlevel = info and info[2] or 0
                local grey = (not dg) and qlevel > 0 and (level - qlevel) > 3
                if keep[id] or not grey then
                    keep[id] = true
                    local ps = NS.Qpre and NS.Qpre[id]
                    if ps then
                        for _, p in ipairs(ps) do
                            local pd = questDg[p]
                            local pull = not pd or pd == dg or liveDg[pd]
                            if pull and not isTurnedIn(p) and not skippedQuest(p) and not wrongFaction(p) then
                                keep[p] = true
                            end
                        end
                    end
                end
            end
        end
    end

    local function stepDone(s)
        local id = s[2]
        local q = log[id]
        if s[1] == "A" then return isTurnedIn(id) or q ~= nil end
        if s[1] == "C" then return isTurnedIn(id) or (q and q.complete) end
        return isTurnedIn(id)
    end

    local function inZone(map, title)
        if map and map ~= 0 and currentMapID() == map then return true end
        local zone = (GetRealZoneText and GetRealZoneText()) or ""
        return zone ~= "" and title and zone:lower() == title:lower()
    end

    local function chapterStarted(i)
        for j = i + 1, math.min(i + 8, #steps) do
            local s = steps[j]
            if s[1] == "G" then break end
            if stepDone(s) then return true end
        end
    end

    -- El "ve a esta zona" solo sale si en ese tramo queda alguna misión que a tu nivel aún da XP.
    local function chapterHasWork(i)
        for j = i + 1, #steps do
            local n = steps[j]
            if n[1] == "G" then return false end
            if keep[n[2]] and not stepDone(n) then return true end
        end
        return false
    end

    local show, skipDungeon = {}, false
    local hideDungeons = cfg.dungeons == false
    local i = 1
    while i <= #steps do
        local s = steps[i]
        if s[1] == "G" and s[4] == 1 then
            skipDungeon = hideDungeons
            local name = dungeonLabel(s[3])
            local gone = cfg.dismissed["g" .. (s[2] or 0) .. (s[3] or "")]
            local j = i + 1
            while j <= #steps and steps[j][1] ~= "G" do j = j + 1 end
            if not skipDungeon and not gone and liveDg[name] and chapterHasWork(i) then
                local ids, seen = {}, {}
                local stepOf = {}
                for k = i + 1, j - 1 do
                    local id = steps[k][2]
                    stepOf[steps[k][1] .. id] = stepOf[steps[k][1] .. id] or k
                    if not seen[id] and keep[id] and not isTurnedIn(id) then
                        seen[id] = true
                        ids[#ids + 1] = id
                    end
                end
                local accepts, dos, turns = {}, {}, {}
                for _, id in ipairs(ids) do
                    local q = log[id]
                    if not q then accepts[#accepts + 1] = id
                    elseif q.complete then turns[#turns + 1] = id
                    else dos[#dos + 1] = id end
                end
                local function push(kind, id)
                    local k = stepOf[kind .. id]
                    if k then show[#show + 1] = k end
                end
                if #accepts > 0 then show[#show + 1] = i end
                for _, id in ipairs(accepts) do push("A", id) end
                for _, id in ipairs(dos) do push("C", id) end
                for _, id in ipairs(turns) do push("T", id) end
            end
            i = j
            if #show >= 8 then break end
        else
            if s[1] == "G" then
                skipDungeon = false
                local gone = cfg.dismissed["g" .. (s[2] or 0) .. (s[3] or "")]
                if not gone and chapterHasWork(i) and not inZone(s[2], s[3]) and not chapterStarted(i) then
                    show[#show + 1] = i
                end
            elseif not skipDungeon then
                local id = s[2]
                if keep[id] and not stepDone(s) then show[#show + 1] = i end
            end
            i = i + 1
            if #show >= 8 then break end
        end
    end

    local function pointAt(s)
        local info = NS.Qinfo and NS.Qinfo[s[2]]
        if not info then return end
        if s[1] == "T" then
            NS.SetWaypoint(info[9], info[10], info[11])
        elseif s[1] == "C" and log[s[2]] then
            NS.TrackQuest(s[2], questName(s[2], info[1]))
        else
            NS.SetWaypoint(info[5], info[6], info[7])
        end
    end

    local tasks = {}
    for n, i in ipairs(show) do
        local s = steps[i]
        local t = { key = "s" .. i, step = i, prio = n, noDismiss = false }
        if s[1] == "G" then
            local map, title = s[2], s[3]
            local dgName = (s[4] == 1) and dungeonLabel(title) or nil
            t.dungeon = dgName
            t.kind, t.icon = "zone", dgName and ICON.dungeon or ICON.map
            t.badge = dgName and NS.L("task.badge.dungeonEnter") or NS.L("task.badge.travel")
            t.title = dgName and NS.Lf("task.enter", dgName) or NS.Lf("task.go", title)
            t.sub = dgName and NS.Lf("task.enterSub", dgName)
                or NS.L("task.goSub")
            t.label = (map and map ~= 0) and NS.L("task.openMap") or nil
            t.onLeft = (map and map ~= 0) and function()
                pcall(function() if OpenWorldMap then OpenWorldMap(map) end end)
            end or nil
            t.onRight = function()
                cfg.dismissed["g" .. (map or 0) .. (title or "")] = true
                NS.RequestRefresh()
            end
        else
            local id = s[2]
            local info = (NS.Qinfo and NS.Qinfo[id]) or { NS.Lf("task.questFallback", id), 0, 0, "", 0, 0, 0, "", 0, 0, 0, "" }
            local name = questName(id, info[1])
            t.qname = name
            t.stepKind = s[1]
            t.giverName = info[12]
            if s[1] == "A" and info[5] and info[5] ~= 0 and not ((info[6] or 0) == 0 and (info[7] or 0) == 0) then
                t.pin = { id = id, map = info[5], x = info[6], y = info[7], who = info[8] or "", name = name }
            end
            t.dungeon = dungeonAt[i]
            if t.dungeon then t.icon = ICON.dungeon end
            t.onRight = function()
                cfg.dismissed["q" .. id] = true
                NS.RequestRefresh()
            end
            t.onLeft = function()
                local map, px, py
                if s[1] == "T" then map, px, py = info[9], info[10], info[11]
                else map, px, py = info[5], info[6], info[7] end
                NS.OpenQuestMap(id, map, px, py)
            end
            t.label = NS.L("task.arrow")
            t.tag = info[2] > 0 and NS.Lf("ui.dg.levelOnly", info[2]) or nil
            if s[1] == "A" then
                t.kind, t.badge = "zone", t.dungeon and NS.L("task.badge.dungeonGet") or NS.L("task.badge.accept")
                if not t.dungeon then t.icon = ICON.avail end
                t.title = NS.Lf("task.accept", name)
                local where = place(info[5], info[6], info[7], info[8])
                local give = where and NS.Lf("task.give", where) or ""
                if t.dungeon then
                    t.sub = give .. NS.Lf("task.acceptDg", t.dungeon)
                else
                    t.sub = give .. NS.L("task.acceptRoute")
                end
            elseif s[1] == "C" then
                t.kind, t.badge = "quest", t.dungeon and NS.L("task.badge.dungeonIn") or NS.L("task.badge.do")
                if not t.dungeon then t.icon = ICON.quest end
                t.title = NS.Lf("task.do", name)
                local obj = clientObjective(id)
                if not obj or obj == "" then obj = info[4] end
                if not obj or obj == "" then obj = NS.L("task.doFallback") end
                t.sub = obj
                local q = log[id]
                if q and q.r and q.r > 0 then t.progress = q.f / q.r end
            else
                t.kind, t.badge = "turnin", t.dungeon and NS.L("task.badge.dungeonTurn") or NS.L("task.badge.turn")
                if not t.dungeon then t.icon = ICON.turnin end
                t.title = NS.Lf("task.turn", name)
                local where = place(info[9], info[10], info[11], info[12])
                local to = where and NS.Lf("task.to", where) or ""
                if t.dungeon then
                    t.sub = to .. NS.Lf("task.turnDg", t.dungeon)
                else
                    t.sub = to .. NS.L("task.turnRoute")
                end
            end
        end
        tasks[#tasks + 1] = t
    end

    local firstDg = tasks[1] and tasks[1].dungeon
    if firstDg then
        local grab, inside = {}, {}
        for _, t in ipairs(tasks) do
            if t.dungeon ~= firstDg then break end
            if t.stepKind == "A" and t.qname then grab[#grab + 1] = NS.Lf("task.quote", t.qname)
            elseif t.stepKind == "C" and t.qname then inside[#inside + 1] = NS.Lf("task.quote", t.qname) end
        end
        local first = tasks[1]
        if not first.stepKind and #grab > 0 then
            first.title = NS.Lf("task.grabN", #grab, firstDg)
            first.badge = NS.L("task.badge.dungeonGet")
            first.sub = NS.Lf("task.grabSub", table.concat(grab, ", "))
            for _, t in ipairs(tasks) do
                if t.pin and t.onLeft then
                    first.onLeft = t.onLeft
                    first.label = NS.L("task.map")
                    break
                end
            end
        elseif first.stepKind == "A" and #grab > 1 then
            first.title = NS.Lf("task.grab", firstDg)
            first.badge = NS.L("task.badge.dungeonGet")
            first.sub = NS.Lf("task.grabSub2", table.concat(grab, ", "))
        elseif first.stepKind == "C" and #inside > 1 then
            first.sub = (first.sub or "") .. NS.Lf("task.sameRun", table.concat(inside, ", "))
        end
    end

    local here = show[1]
    local zoneName, dungeonName
    if here then
        for j = here, 1, -1 do
            local g = steps[j]
            if g[1] == "G" and g[4] ~= 1 then zoneName = g[3] break end
        end
        for j = here, #steps do
            local g = steps[j]
            if g[1] == "G" and g[4] == 1 and chapterHasWork(j) then
                dungeonName = dungeonLabel(g[3])
                break
            end
        end
    end
    NS.guideHint = { zone = zoneName, dungeon = dungeonName }

    if #tasks == 0 then
        tasks[1] = {
            kind = "info", icon = ICON.ok, noDismiss = true, key = "routedone", prio = 1,
            badge = NS.L("task.badge.route"),
            title = NS.L("task.done"),
            sub = NS.L("task.doneSub"),
        }
    else
        local s = steps[show[1]]
        local wp = s[1] .. ":" .. tostring(s[2]) .. ":" .. tostring(s[3])
        if cfg.arrow ~= false and NS._wp ~= wp then
            NS._wp = wp
            if s[1] == "G" then
                -- el mapa se abre solo con el botón; viajar no mueve la flecha de una misión
            else
                pointAt(s)
            end
        end
    end
    -- Dónde se cogen las misiones de este tramo. Dónde se hacen lo marca el juego.
    local pins, seen, byWho = {}, {}, {}
    local chapter = show[1]
    if chapter then
    for j = chapter, 1, -1 do
        if steps[j][1] == "G" then chapter = j break end
    end
    local j = chapter
    while j <= #steps do
        local s = steps[j]
        if j ~= chapter and s[1] == "G" then break end
        if s[1] == "A" then
            local id = s[2]
            if keep[id] and not isTurnedIn(id) and not log[id] and not seen[id] then
                local info = NS.Qinfo and NS.Qinfo[id]
                local name = questName(id, info and info[1])
                if info and info[5] and info[5] ~= 0 and not ((info[6] or 0) == 0 and (info[7] or 0) == 0) then
                    seen[id] = { id = id, map = info[5], x = info[6], y = info[7], who = info[8] or "", name = name }
                    pins[#pins + 1] = seen[id]
                    if seen[id].who ~= "" then byWho[seen[id].who] = seen[id] end
                else
                    seen[id] = false
                end
            end
        end
        j = j + 1
    end
    j = chapter
    while j <= #steps do
        local s = steps[j]
        if j ~= chapter and s[1] == "G" then break end
        if s[1] == "A" and seen[s[2]] == false then
            local info = NS.Qinfo and NS.Qinfo[s[2]]
            local who = info and info[12]
            local d = who and byWho[who]
            if d then
                pins[#pins + 1] = { id = s[2], map = d.map, x = d.x, y = d.y, who = d.who, name = questName(s[2], info[1]) }
            end
        end
        j = j + 1
    end
    end
    local firstKind = tasks[1] and tasks[1].stepKind
    local pickingUp = firstKind == "A" or (firstKind == nil and tasks[1] and tasks[1].dungeon and #pins > 0)
    if NS.SetPickupPins then NS.SetPickupPins(pins, pickingUp) end
    return tasks
end

-- Imprime los pasos en el chat (útil con lectores de pantalla)
function NS.PrintTasks()
    local tasks = NS.BuildTasks()
    NS.msg(NS.Lf("msg.levelNow", NS.currentLevel()))
    for i, t in ipairs(tasks) do
        if i > 8 then break end
        print(string.format("  %d. %s  (%s)", i, t.title, t.sub or ""))
    end
end

------------------------------------------------------------------------
-- Eventos
------------------------------------------------------------------------
NS.On("PLAYER_LEVEL_UP", function(level)
    level = tonumber(level) or UnitLevel("player")
    NS.forcedLevel = level -- UnitLevel puede tardar en actualizarse
    C_Timer.After(5, function() NS.forcedLevel = nil; NS.RequestRefresh() end)
    NS.alert("levelup" .. level, 1, NS.Lf("msg.levelUp", level))
    NS.RequestRefresh()
end)

for _, ev in ipairs({
    "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
    "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "UNIT_QUEST_LOG_CHANGED",
}) do
    NS.On(ev, function() NS.RequestRefresh() end)
end
