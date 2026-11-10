-- LevelGuide: núcleo (configuración, eventos, automatización de misiones y vendedor)

local ADDON, NS = ...

------------------------------------------------------------------------
-- Eventos: NS.On(evento, función) permite varios manejadores por evento
------------------------------------------------------------------------
NS.handlers = {}
local eventFrame = CreateFrame("Frame")

function NS.On(event, fn)
    local list = NS.handlers[event]
    if not list then
        list = {}
        NS.handlers[event] = list
        pcall(eventFrame.RegisterEvent, eventFrame, event) -- si no existe en el cliente, se ignora
    end
    list[#list + 1] = fn
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local list = NS.handlers[event]
    if not list then return end
    for _, fn in ipairs(list) do
        local ok, err = pcall(fn, ...)
        if not ok then geterrorhandler()(err) end
    end
end)

------------------------------------------------------------------------
-- Configuración
------------------------------------------------------------------------
NS.DEFAULTS = {
    sell     = true,  -- vender grises al abrir un vendedor
    repair   = true,  -- reparar al abrir un vendedor
    quest    = true,  -- aceptar/entregar misiones automáticamente (Shift = pausa)
    autoloot = true,  -- autolooteo
    dungeons = true,  -- incluir mazmorras en la ruta
    arrow    = true,  -- flecha al paso actual de la ruta
    xp       = false, -- cartel de leveo; apagado para no tapar el centro
    minimap  = true,  -- botón del minimapa
    lock     = false, -- bloquear la posición de las ventanas
    contrast = false, -- alto contraste
    voice    = false, -- leer avisos en voz alta
    lang     = "es",  -- idioma del addon (clave dada de alta en Locale/alta.lua)
    size     = 2,     -- 1 pequeño, 2 normal, 3 grande, 4 muy grande
    mmAngle  = 215,   -- posición del botón en el minimapa
    turnedIn = 0,     -- misiones entregadas con el addon
}

local function copy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = copy(x) end
    return t
end

NS.On("ADDON_LOADED", function(name)
    if name ~= ADDON then return end
    LevelGuideDB = LevelGuideDB or {}
    NS.cfg = LevelGuideDB
    for k, v in pairs(NS.DEFAULTS) do
        if NS.cfg[k] == nil then NS.cfg[k] = copy(v) end
    end
    NS.cfg.dismissed = NS.cfg.dismissed or {} -- tareas ocultas por el jugador
    NS.cfg.zoneDone  = NS.cfg.zoneDone or {}  -- misiones entregadas por zona
    -- El cartel salía en el centro. Se apaga una vez; en opciones se puede volver a poner.
    if not NS.cfg.trackerChoice then
        NS.cfg.xp = false
        NS.cfg.pos_LevelGuideTracker = nil
        NS.cfg.trackerChoice = true
    end
end)

------------------------------------------------------------------------
-- Mensajes, avisos y voz
------------------------------------------------------------------------
local PREFIX = "|cff67d45eLevelGuide|r: "
function NS.msg(text) print(PREFIX .. text) end

function NS.onoff(v)
    if v then return "|cff00ff00" .. NS.L("msg.on") .. "|r" end
    return "|cffff0000" .. NS.L("msg.off") .. "|r"
end

-- Lectura en voz alta (opcional; depende de la síntesis de voz del cliente)
function NS.speak(text, force)
    if not (force or (NS.cfg and NS.cfg.voice)) then return end
    pcall(function()
        local voice = 0
        if C_TTSSettings and C_TTSSettings.GetVoiceOptionID and Enum and Enum.TtsVoiceType then
            voice = C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType.Standard)
        end
        C_VoiceChat.SpeakText(voice, text, Enum.VoiceTtsDestination.LocalPlayback, 0, 100)
    end)
end

local lastAlert = {}
function NS.alert(key, secs, text)
    local now = GetTime()
    if lastAlert[key] and now - lastAlert[key] < secs then return end
    lastAlert[key] = now
    if UIErrorsFrame then UIErrorsFrame:AddMessage(text, 1, 0.8, 0.1, 1) end
    NS.msg(text)
    NS.speak(text)
end

-- Refresco con retardo para agrupar muchos eventos seguidos
local refreshPending
function NS.RequestRefresh()
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(0.3, function()
        refreshPending = false
        if NS.Refresh then
            local ok, err = pcall(NS.Refresh)
            if not ok then geterrorhandler()(err) end
        end
    end)
end

------------------------------------------------------------------------
-- Utilidades de API (Forever usa el motor moderno; dejamos fallbacks)
------------------------------------------------------------------------
local function itemSellPrice(link)
    if not link then return 0 end
    local fn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    return select(11, fn(link)) or 0
end

local function slotInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local i = C_Container.GetContainerItemInfo(bag, slot)
        if i then return i.hyperlink, i.quality, i.stackCount or 1 end
    elseif GetContainerItemInfo then
        local _, count, _, quality, _, _, link = GetContainerItemInfo(bag, slot)
        return link, quality, count or 1
    end
end

local function numSlots(bag)
    local fn = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    return fn and fn(bag) or 0
end

local function useSlot(bag, slot)
    local fn = (C_Container and C_Container.UseContainerItem) or UseContainerItem
    if fn then fn(bag, slot) end
end

local function coins(c)
    return GetCoinTextureString and GetCoinTextureString(c) or (c .. "c")
end

------------------------------------------------------------------------
-- Vendedor: vender grises y reparar
------------------------------------------------------------------------
NS.On("MERCHANT_SHOW", function()
    local cfg = NS.cfg
    if not cfg then return end
    if cfg.sell then
        local total, count = 0, 0
        for bag = 0, (NUM_BAG_SLOTS or 4) do
            for slot = 1, numSlots(bag) do
                local link, quality, stack = slotInfo(bag, slot)
                if link and quality == 0 then
                    local price = itemSellPrice(link)
                    if price > 0 then
                        useSlot(bag, slot)
                        total = total + price * stack
                        count = count + 1
                    end
                end
            end
        end
        if count > 0 then NS.msg(NS.Lf("msg.sold", count, coins(total))) end
    end
    if cfg.repair and CanMerchantRepair and CanMerchantRepair() then
        local cost, canRepair = GetRepairAllCost()
        if canRepair and cost and cost > 0 then
            if GetMoney() >= cost then
                RepairAllItems()
                NS.msg(NS.Lf("msg.repaired", coins(cost)))
            else
                NS.msg(NS.Lf("msg.repairNoGold", coins(cost)))
            end
        end
    end
end)

------------------------------------------------------------------------
-- Misiones automáticas (mantener Shift pulsado para pausar)
------------------------------------------------------------------------
local function questAuto()
    return NS.cfg and NS.cfg.quest and not IsShiftKeyDown()
end

local function bestRewardIndex()
    local n = GetNumQuestChoices()
    if n <= 1 then return 1 end
    local best, bestPrice = 1, -1
    for i = 1, n do
        local price = itemSellPrice(GetQuestItemLink("choice", i))
        if price > bestPrice then best, bestPrice = i, price end
    end
    return best
end

NS.On("QUEST_DETAIL",         function() if questAuto() then AcceptQuest() end end)
NS.On("QUEST_ACCEPT_CONFIRM", function() if questAuto() then ConfirmAcceptQuest() end end)
NS.On("QUEST_PROGRESS",       function() if questAuto() and IsQuestCompletable() then CompleteQuest() end end)
NS.On("QUEST_COMPLETE",       function() if questAuto() then GetQuestReward(bestRewardIndex()) end end)

NS.On("QUEST_GREETING", function()
    if not questAuto() then return end
    for i = 1, GetNumActiveQuests() do
        local _, isComplete = GetActiveTitle(i)
        if isComplete then SelectActiveQuest(i) return end
    end
    for i = 1, GetNumAvailableQuests() do
        SelectAvailableQuest(i)
        return
    end
end)

NS.On("GOSSIP_SHOW", function()
    if not questAuto() or not (C_GossipInfo and C_GossipInfo.GetActiveQuests) then return end
    for _, q in ipairs(C_GossipInfo.GetActiveQuests() or {}) do
        if q.isComplete then C_GossipInfo.SelectActiveQuest(q.questID) return end
    end
    for _, q in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
        if not q.isTrivial then C_GossipInfo.SelectAvailableQuest(q.questID) return end
    end
end)

NS.On("PLAYER_LOGIN", function()
    if NS.cfg.autoloot then
        local set = (C_CVar and C_CVar.SetCVar) or SetCVar
        set("autoLootDefault", "1")
    end
end)
