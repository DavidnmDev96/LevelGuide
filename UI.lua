-- LevelGuide: interfaz estilo Diario de misiones (marco de madera + pergamino),
-- botón de minimapa, opciones, mini tracker de XP y comandos.

local _, NS = ...
local ICON = NS.ICON

local WIN_SCALES   = { 0.85, 1.0, 1.2, 1.4 }
local TRACK_SCALES = { 1, 1.15, 1.4, 1.8 }
local function sizeName(n)
    return NS.L("ui.size." .. tostring(n or 2))
end

local W, H = 780, 600
local ROWS_LIST, ROWS_HERO, GRID_PER_PAGE = 9, 6, 18

------------------------------------------------------------------------
-- Paletas (normal y alto contraste)
------------------------------------------------------------------------
local PAL = {
    norm = {
        parch = { 0.80, 0.66, 0.43 }, parchIn = { 0.87, 0.74, 0.51 }, edge = { 0.36, 0.23, 0.09 },
        ink = { 0.20, 0.11, 0.04 }, ink2 = { 0.38, 0.25, 0.12 }, gold = { 0.52, 0.31, 0.02 },
        green = { 0.05, 0.40, 0.10 }, gray = { 0.50, 0.42, 0.30 }, red = { 0.62, 0.10, 0.05 },
        ring = { 0.86, 0.68, 0.24 }, ringOff = { 0.42, 0.30, 0.10 },
    },
    hi = {
        parch = { 0.97, 0.94, 0.82 }, parchIn = { 1, 0.98, 0.90 }, edge = { 0.2, 0.12, 0.04 },
        ink = { 0, 0, 0 }, ink2 = { 0.12, 0.08, 0.04 }, gold = { 0.42, 0.22, 0 },
        green = { 0, 0.30, 0.05 }, gray = { 0.30, 0.27, 0.22 }, red = { 0.55, 0, 0 },
        ring = { 1, 0.85, 0.2 }, ringOff = { 0.5, 0.38, 0.1 },
    },
}
local function pal() return (NS.cfg and NS.cfg.contrast) and PAL.hi or PAL.norm end
local function unpackc(c, a) return c[1], c[2], c[3], a end

------------------------------------------------------------------------
-- Utilidades gráficas
------------------------------------------------------------------------
local function colorTex(tex, r, g, b, a)
    if tex.SetColorTexture then tex:SetColorTexture(r, g, b, a or 1) else tex:SetTexture(r, g, b, a or 1) end
end

local function setFont(fs, size, outline)
    fs:SetFont(STANDARD_TEXT_FONT, size, outline and "OUTLINE" or "")
end

local function addBorder(f, t)
    local e = {}
    for i = 1, 4 do e[i] = f:CreateTexture(nil, "OVERLAY") end
    e[1]:SetPoint("TOPLEFT");    e[1]:SetPoint("TOPRIGHT");    e[1]:SetHeight(t)
    e[2]:SetPoint("BOTTOMLEFT"); e[2]:SetPoint("BOTTOMRIGHT"); e[2]:SetHeight(t)
    e[3]:SetPoint("TOPLEFT");    e[3]:SetPoint("BOTTOMLEFT");  e[3]:SetWidth(t)
    e[4]:SetPoint("TOPRIGHT");   e[4]:SetPoint("BOTTOMRIGHT"); e[4]:SetWidth(t)
    f.edges = e
    return e
end

local function setBorder(f, c, a)
    if not f.edges then return end
    for _, tex in ipairs(f.edges) do colorTex(tex, c[1], c[2], c[3], a or 1) end
end

-- Caja con icono y anillo dorado (como los iconos del Diario)
local function iconBox(parent, size)
    local b = CreateFrame("Frame", nil, parent)
    b:SetSize(size, size)
    b.back = b:CreateTexture(nil, "BACKGROUND")
    b.back:SetAllPoints()
    colorTex(b.back, 0.05, 0.03, 0.01, 1)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetPoint("TOPLEFT", 2, -2)
    b.tex:SetPoint("BOTTOMRIGHT", -2, 2)
    addBorder(b, 2)
    return b
end

local function setIcon(box, path, ringColor)
    box.tex:SetTexture(path or ICON.info)
    box.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if ringColor then setBorder(box, ringColor) end
end

local function savePos(f)
    if not (NS.cfg and f.posKey) then return end
    local p, _, rp, x, y = f:GetPoint()
    NS.cfg["pos_" .. f.posKey] = { p, rp, x, y }
end

local function restorePos(f)
    local s = NS.cfg and f.posKey and NS.cfg["pos_" .. f.posKey]
    if s then
        f:ClearAllPoints()
        f:SetPoint(s[1], UIParent, s[2], s[3], s[4])
    end
end

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

local SMALL_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local framesToStyle = {}

-- Ventana con marco de madera oscura, cabecera dorada y pergamino
local function makeFrame(name, w, h, title, pageTop)
    local f = CreateFrame("Frame", name, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f.posKey = name
    f:SetSize(w, h)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    if f.SetBackdrop then
        f:SetBackdrop(BACKDROP)
        f:SetBackdropColor(0.13, 0.08, 0.04, 0.98)
    end
    f:SetScript("OnDragStart", function(self)
        if not (NS.cfg and NS.cfg.lock) then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePos(self)
    end)

    local hdr = f:CreateTexture(nil, "OVERLAY")
    hdr:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    hdr:SetSize(300, 64)
    hdr:SetPoint("TOP", 0, 12)
    local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("TOP", hdr, "TOP", 0, -14)
    t:SetText(title)
    f.title = t

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    -- pergamino
    local page = CreateFrame("Frame", nil, f)
    page:SetPoint("TOPLEFT", 18, -pageTop)
    page:SetPoint("BOTTOMRIGHT", -18, 18)
    page.base = page:CreateTexture(nil, "BACKGROUND")
    page.base:SetAllPoints()
    page.inner = page:CreateTexture(nil, "BACKGROUND", nil, 1)
    page.inner:SetPoint("TOPLEFT", 8, -8)
    page.inner:SetPoint("BOTTOMRIGHT", -8, 8)
    addBorder(page, 3)
    f.page = page

    framesToStyle[#framesToStyle + 1] = f
    if UISpecialFrames then tinsert(UISpecialFrames, name) end
    f:Hide()
    return f, page
end

local setOption -- se define más abajo

------------------------------------------------------------------------
-- Ventana principal
------------------------------------------------------------------------
local win, page = makeFrame("LevelGuideWindow", W, H, "LevelGuide", 100)
local currentTab, pageNum = "now", 1

-- Pestañas con iconos redondos arriba a la izquierda
local TABS = {
    { id = "now",      label = "ui.tab.now",      title = "ui.tab.now.tip" },
    { id = "route",    label = "ui.tab.route",    title = "ui.tab.route.tip" },
    { id = "dungeons", label = "ui.tab.dungeons", title = "ui.tab.dungeons.tip" },
    { id = "log",      label = "ui.tab.log",      title = "ui.tab.log.tip" },
    { id = "settings", label = "ui.tab.settings", title = "ui.tab.settings.tip" },
}
local tabs = {}
for i, t in ipairs(TABS) do
    local b = CreateFrame("Button", nil, win)
    b:SetSize(104, 26)
    b:SetPoint("TOPLEFT", 18 + (i - 1) * 108, -50)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    colorTex(b.bg, 0.22, 0.14, 0.06, 1)
    addBorder(b, 1)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.label:SetPoint("CENTER", 0, 0)
    b.label:SetText(NS.L(t.label))
    b.textKey = t.label
    b.tipKey = t.title
    b:SetScript("OnClick", function()
        currentTab, pageNum = t.id, 1
        NS.Refresh()
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(NS.L(t.title))
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    tabs[t.id] = b
end

-- Nivel, zona y barra de XP arriba a la derecha
local levelText = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
levelText:SetPoint("TOPRIGHT", -28, -28)
levelText:SetJustifyH("RIGHT")
local xpBar = CreateFrame("StatusBar", nil, win)
xpBar:SetSize(180, 14)
xpBar:SetPoint("TOPRIGHT", -28, -76)
xpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
xpBar:SetStatusBarColor(0.58, 0, 0.55)
xpBar:SetMinMaxValues(0, 1)
local xpBack = xpBar:CreateTexture(nil, "BACKGROUND")
xpBack:SetAllPoints()
colorTex(xpBack, 0, 0, 0, 0.7)
addBorder(xpBar, 1)
setBorder(xpBar, { 0.8, 0.62, 0.2 })
local xpText = xpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
xpText:SetPoint("CENTER")

-- Título de la página, contador y adorno
local pageTitle = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
pageTitle:SetPoint("TOPLEFT", 26, -20)
pageTitle:SetJustifyH("LEFT")
local counter = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
counter:SetPoint("TOPRIGHT", -26, -28)
counter:SetJustifyH("RIGHT")
local orn1 = page:CreateTexture(nil, "ARTWORK")
orn1:SetPoint("TOPLEFT", 22, -56)
orn1:SetPoint("TOPRIGHT", -22, -56)
orn1:SetHeight(2)
local orn2 = page:CreateTexture(nil, "ARTWORK")
orn2:SetPoint("TOP", orn1, "BOTTOM", 0, -3)
orn2:SetSize(260, 1)
local orn3 = page:CreateTexture(nil, "ARTWORK")
orn3:SetPoint("CENTER", orn1, "CENTER", 0, 0)
orn3:SetSize(10, 10)

-- Tarjeta "SIGUIENTE PASO" (solo en la pestaña Ahora)
local hero = CreateFrame("Frame", nil, page)
hero:SetPoint("TOPLEFT", 20, -74)
hero:SetPoint("TOPRIGHT", -20, -74)
hero:SetHeight(112)
hero.back = hero:CreateTexture(nil, "BACKGROUND")
hero.back:SetAllPoints()
addBorder(hero, 2)
hero.box = iconBox(hero, 60)
hero.box:SetPoint("LEFT", 14, 0)
hero.btn = CreateFrame("Button", nil, hero, "UIPanelButtonTemplate")
hero.btn:SetSize(110, 30)
hero.btn:SetPoint("RIGHT", -16, 0)
hero.tag = hero:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hero.tag:SetPoint("TOPLEFT", 88, -10)
hero.tag:SetText(NS.L("ui.hero.badge"))
hero.title = hero:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hero.title:SetPoint("TOPLEFT", 88, -26)
hero.title:SetPoint("RIGHT", hero.btn, "LEFT", -12, 0)
hero.title:SetJustifyH("LEFT")
hero.title:SetWordWrap(false)
hero.sub = hero:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hero.sub:SetPoint("TOPLEFT", 88, -48)
hero.sub:SetPoint("RIGHT", hero.btn, "LEFT", -12, 0)
hero.sub:SetHeight(56)
hero.sub:SetWordWrap(true)
hero.sub:SetJustifyH("LEFT")
hero.sub:SetJustifyV("TOP")
hero:Hide()

-- Filas de lista
local rows = {}
for i = 1, ROWS_LIST do
    local r = CreateFrame("Button", nil, page)
    r:SetSize(700, 38)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r.hl = r:CreateTexture(nil, "HIGHLIGHT")
    r.hl:SetAllPoints()
    colorTex(r.hl, 0.25, 0.12, 0, 0.14)
    r.sep = r:CreateTexture(nil, "BACKGROUND")
    r.sep:SetPoint("BOTTOMLEFT", 0, 0)
    r.sep:SetPoint("BOTTOMRIGHT", 0, 0)
    r.sep:SetHeight(1)
    r.box = iconBox(r, 30)
    r.box:SetPoint("LEFT", 6, 0)
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.text:SetJustifyH("LEFT")
    r.text:SetWordWrap(false)
    r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.sub:SetJustifyH("LEFT")
    r.sub:SetWordWrap(false)
    r.tag = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.tag:SetPoint("RIGHT", -10, 0)
    r.tag:SetJustifyH("RIGHT")
    r.tag:SetWidth(110)
    r.bar = CreateFrame("StatusBar", nil, r)
    r.bar:SetSize(80, 8)
    r.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    r.bar:SetMinMaxValues(0, 1)
    r.barBack = r.bar:CreateTexture(nil, "BACKGROUND")
    r.barBack:SetAllPoints()
    colorTex(r.barBack, 0.1, 0.05, 0, 0.45)
    r:SetScript("OnClick", function(self, button)
        local d = self.data
        if not d then return end
        if button == "RightButton" then
            if d.onRight then d.onRight() end
        elseif d.onLeft then
            d.onLeft()
        end
    end)
    r:Hide()
    rows[i] = r
end

-- Celdas de cuadrícula (mazmorras)
local cells = {}
for i = 1, GRID_PER_PAGE do
    local c = CreateFrame("Button", nil, page)
    c:SetSize(232, 54)
    c:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
    c:SetPoint("TOPLEFT", 22 + col * 240, -76 - row * 62)
    c.hl = c:CreateTexture(nil, "HIGHLIGHT")
    c.hl:SetAllPoints()
    colorTex(c.hl, 0.25, 0.12, 0, 0.14)
    c.box = iconBox(c, 42)
    c.box:SetPoint("LEFT", 4, 0)
    c.text = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    c.text:SetPoint("TOPLEFT", 54, -8)
    c.text:SetWidth(176)
    c.text:SetJustifyH("LEFT")
    c.text:SetWordWrap(false)
    c.sub = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    c.sub:SetPoint("TOPLEFT", 54, -26)
    c.sub:SetWidth(176)
    c.sub:SetJustifyH("LEFT")
    c.sub:SetWordWrap(false)
    c.tag = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    c.tag:SetPoint("TOPRIGHT", -4, -8)
    c.tag:SetJustifyH("RIGHT")
    c:SetScript("OnClick", function(self)
        local d = self.data
        if d and d.onLeft then d.onLeft() end
    end)
    c:SetScript("OnEnter", function(self)
        local d = self.data
        if not (d and d.tip) then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        for n, line in ipairs(d.tip) do
            if n == 1 then GameTooltip:AddLine(line, 1, 0.82, 0) else GameTooltip:AddLine(line, 0.9, 0.9, 0.9, true) end
        end
        GameTooltip:Show()
    end)
    c:SetScript("OnLeave", function() GameTooltip:Hide() end)
    c:Hide()
    cells[i] = c
end

-- Pie y paginación
local footer = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
footer:SetPoint("BOTTOMLEFT", 26, 14)
footer:SetWidth(520)
footer:SetJustifyH("LEFT")

local function navButton(prefix, point, x)
    local b = CreateFrame("Button", nil, page)
    b:SetSize(28, 28)
    b:SetPoint("BOTTOMRIGHT", x, 10)
    b:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prefix .. "Page-Up")
    b:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prefix .. "Page-Down")
    b:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prefix .. "Page-Disabled")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    return b
end
local nextBtn = navButton("Next", "BOTTOMRIGHT", -24)
local prevBtn = navButton("Prev", "BOTTOMRIGHT", -56)
local pageText = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
pageText:SetPoint("RIGHT", prevBtn, "LEFT", -8, 0)
pageText:SetJustifyH("RIGHT")

nextBtn:SetScript("OnClick", function() pageNum = pageNum + 1; NS.Refresh() end)
prevBtn:SetScript("OnClick", function() pageNum = math.max(1, pageNum - 1); NS.Refresh() end)

------------------------------------------------------------------------
-- Pintar filas, celdas y tarjeta
------------------------------------------------------------------------
local function outlineOn() return NS.cfg and NS.cfg.contrast end

local function colorFor(it, P)
    if it.color == "green" then return P.green end
    if it.color == "gray" then return P.gray end
    if it.color == "red" then return P.red end
    if it.color == "gold" then return P.gold end
    return P.ink
end

local function fillRow(r, it, mode)
    local P = pal()
    r.data = it
    local o = outlineOn()
    setFont(r.text, 14, o)
    setFont(r.sub, 11, o)
    setFont(r.tag, 11, o)
    r.text:ClearAllPoints()
    r.sub:ClearAllPoints()
    r.bar:ClearAllPoints()
    colorTex(r.sep, P.edge[1], P.edge[2], P.edge[3], 0.35)
    if it.header then
        r.box:Hide(); r.bar:Hide(); r.tag:SetText("")
        r.text:SetPoint("TOPLEFT", 10, -14)
        r.text:SetWidth(660)
        setFont(r.text, 15, o)
        r.text:SetTextColor(unpackc(P.gold))
        r.sub:SetText("")
        colorTex(r.sep, P.gold[1], P.gold[2], P.gold[3], 0.7)
    else
        r.box:Show()
        setIcon(r.box, it.icon, it.color == "gray" and P.ringOff or P.ring)
        r.box.tex:SetDesaturated(it.color == "gray")
        local tagW = it.tag and 118 or 12
        local barW = it.progress and 92 or 0
        local w = 700 - 48 - tagW - barW
        r.text:SetPoint("TOPLEFT", 48, -4)
        r.text:SetWidth(w)
        r.text:SetTextColor(unpackc(colorFor(it, P)))
        r.sub:SetPoint("TOPLEFT", 48, -21)
        r.sub:SetWidth(w)
        r.sub:SetTextColor(unpackc(P.ink2))
        r.sub:SetText(it.sub or "")
        r.tag:SetText(it.tag or "")
        local tc = it.tagColor == "green" and P.green or it.tagColor == "red" and P.red or P.gold
        r.tag:SetTextColor(unpackc(tc))
        if it.progress then
            r.bar:SetPoint("RIGHT", r.tag, "LEFT", it.tag and -6 or 100, 0)
            r.bar:SetStatusBarColor(0.2, 0.6, 0.2)
            r.bar:SetValue(math.min(1, math.max(0, it.progress)))
            r.bar:Show()
        else
            r.bar:Hide()
        end
    end
    r.text:SetText(it.title or "")
    r:Show()
end

local function fillCell(c, it)
    local P = pal()
    c.data = it
    local o = outlineOn()
    setFont(c.text, 14, o)
    setFont(c.sub, 11, o)
    setFont(c.tag, 11, o)
    setIcon(c.box, it.icon, it.color == "gray" and P.ringOff or P.ring)
    c.box.tex:SetDesaturated(it.color == "gray")
    c.text:SetText(it.title or "")
    c.text:SetTextColor(unpackc(colorFor(it, P)))
    c.sub:SetText(it.sub or "")
    c.sub:SetTextColor(unpackc(P.ink2))
    c.tag:SetText(it.tag or "")
    local tc = it.tagColor == "green" and P.green or it.tagColor == "red" and P.red or P.gold
    c.tag:SetTextColor(unpackc(tc))
    c:Show()
end

local function fillHero(task)
    local P = pal()
    local o = outlineOn()
    colorTex(hero.back, P.parchIn[1] * 0.93, P.parchIn[2] * 0.93, P.parchIn[3] * 0.93, 1)
    setBorder(hero, P.edge, 0.9)
    setFont(hero.tag, 11, o)
    setFont(hero.title, 19, o)
    setFont(hero.sub, 13, o)
    hero.tag:SetTextColor(unpackc(P.gold))
    hero.title:SetTextColor(unpackc(P.ink))
    hero.sub:SetTextColor(unpackc(P.ink2))
    if not task then
        setIcon(hero.box, ICON.ok, P.ring)
        hero.tag:SetText(NS.L("ui.hero.badge"))
        hero.title:SetText(NS.L("ui.hero.ok"))
        hero.sub:SetText(NS.L("ui.hero.okSub"))
        hero.btn:Hide()
        return
    end
    hero.tag:SetText(task.badge or NS.L("ui.hero.badge"))
    setIcon(hero.box, task.icon, P.ring)
    hero.title:SetText(task.title)
    hero.sub:SetText(task.sub or "")
    if task.onLeft then
        hero.btn:SetText(task.label or NS.L("ui.hero.view"))
        hero.btn:SetScript("OnClick", task.onLeft)
        hero.btn:Show()
    else
        hero.btn:Hide()
    end
end

-- Muestra una lista de elementos con paginación. mode: "list", "hero" o "grid".
local function setItems(items, mode)
    local perPage = (mode == "grid") and GRID_PER_PAGE or (mode == "hero" and ROWS_HERO or ROWS_LIST)
    local pages = math.max(1, math.ceil(#items / perPage))
    if pageNum > pages then pageNum = pages end
    if pageNum < 1 then pageNum = 1 end
    local base = (pageNum - 1) * perPage
    local y0 = (mode == "hero") and -196 or -72

    for i = 1, ROWS_LIST do
        local r = rows[i]
        local it = (mode ~= "grid" and i <= perPage) and items[base + i] or nil
        if it then
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", 22, y0 - (i - 1) * 40)
            fillRow(r, it, mode)
        else
            r.data = nil
            r:Hide()
        end
    end
    for i = 1, GRID_PER_PAGE do
        local c = cells[i]
        local it = (mode == "grid") and items[base + i] or nil
        if it then fillCell(c, it) else c.data = nil; c:Hide() end
    end

    local P = pal()
    setFont(pageText, 12, outlineOn())
    pageText:SetTextColor(unpackc(P.ink2))
    if pages > 1 then
        pageText:SetText(NS.Lf("ui.page", pageNum, pages))
        pageText:Show()
        prevBtn:Show(); nextBtn:Show()
        prevBtn:SetEnabled(pageNum > 1)
        nextBtn:SetEnabled(pageNum < pages)
    else
        pageText:SetText("")
        prevBtn:Hide(); nextBtn:Hide()
    end
end

------------------------------------------------------------------------
-- Contenido de cada pestaña
------------------------------------------------------------------------
local function levelTag(from, to)
    if to == from then return NS.Lf("ui.levelTag", from) end
    return NS.Lf("ui.levelRange", from, to)
end

local function nowItems(tasks)
    local items = {}
    if #tasks > 1 then
        items[#items + 1] = { header = true, title = (tasks[2] and tasks[2].dungeon)
            and NS.Lf("ui.now.headerDungeon", tasks[2].dungeon)
            or NS.L("ui.now.header") }
        for i = 2, #tasks do
            local t = tasks[i]
            items[#items + 1] = {
                icon = t.icon, title = t.title, sub = t.sub, tag = t.tag, progress = t.progress,
                onLeft = t.onLeft, onRight = t.onRight,
                color = t.kind == "turnin" and "green" or (t.kind == "warn" and "red" or nil),
            }
        end
    end
    return items
end

local function routeItems()
    local items = {}
    local level = NS.currentLevel()
    local faction = UnitFactionGroup("player")
    local fc = NS.factionCode()
    local route = NS.Route[faction] or NS.Route.Alliance
    for _, b in ipairs(route) do
        local from, to = b[1], b[2]
        local key, alts = NS.Recommend(from, faction)
        local names = {}
        for _, a in ipairs(alts) do names[#names + 1] = NS.zoneLabel(a) end
        local hub = NS.HubText(key, from, fc)
        local sub = {}
        if hub then sub[#sub + 1] = NS.Lf("ui.route.start", hub) end
        if #names > 0 then sub[#sub + 1] = NS.Lf("ui.route.also", table.concat(names, ", ")) end
        local state = level > to and "done" or (level >= from and "here" or "later")
        items[#items + 1] = {
            icon = state == "done" and ICON.ok or (state == "here" and ICON.map or ICON.wait),
            color = state == "done" and "gray" or (state == "here" and "green" or nil),
            title = NS.zoneLabel(key),
            sub = table.concat(sub, " - "),
            tag = levelTag(from, to),
            tagColor = state == "here" and "green" or nil,
            onLeft = function() NS.OpenMap(key) end,
        }
    end
    return items
end

local openDungeon
local bossPick = 1
local sheet

-- Mazmorras de la propia ruta. Forever no tiene diario de encuentros y no se lee ningún otro addon.
local function dgName(en)
    return NS.DungeonName(en) or en
end

local function questTitle(id, fallback)
    local name
    pcall(function()
        if C_QuestLog and C_QuestLog.GetTitleForQuestID then name = C_QuestLog.GetTitleForQuestID(id) end
    end)
    if type(name) == "string" and name ~= "" then return name end
    return fallback
end

local function playerSteps()
    local race = select(2, UnitRace("player"))
    return NS.Steps and NS.Steps[race]
end

local function sameDungeon(title, en)
    local name = (title or ""):gsub("^Mazmorra:%s*", "")
    if name == en or name:find(en, 1, true) or en:find(name, 1, true) then return true end
    return false
end

local function questsFor(en)
    local steps = playerSteps()
    local out, seen, on = {}, {}, false
    if not steps then return out end
    for _, s in ipairs(steps) do
        if s[1] == "G" then
            on = s[4] == 1 and sameDungeon(s[3], en)
        elseif on and s[1] == "A" and not seen[s[2]] then
            seen[s[2]] = true
            local info = NS.Qinfo and NS.Qinfo[s[2]]
            local name, level, map, x, y, npc = NS.Lf("task.questFallback", s[2]), 0, 0, 0, 0, ""
            if info then
                name = info[1] or name
                level = info[2] or 0
                map, x, y, npc = info[5] or 0, info[6] or 0, info[7] or 0, info[8] or ""
            end
            out[#out + 1] = { s[2], level, "B", map, x, y, npc, name }
        end
    end
    return out
end

local function bossesOf(dg)
    return (NS.Bosses and NS.Bosses[dg.en]) or {}
end

local function showBoss(dg)
    local bosses = bossesOf(dg)
    local b = bosses[bossPick] or bosses[1]
    for _, btn in ipairs(sheet.loots or {}) do btn:Hide() end
    if not b then
        if sheet.model then sheet.model:Hide() end
        for _, btn in ipairs(sheet.bossBtns or {}) do btn:Hide() end
        sheet.bossName:SetText(NS.L("ui.dg.noBosses"))
        sheet.bossName:SetTextColor(1, 0.86, 0.45)
        sheet.bossSub:SetText(NS.L("ui.dg.noBossesSub"))
        sheet.bossSub:SetTextColor(0.85, 0.72, 0.48)
        return
    end
    if bossPick > #bosses then bossPick = 1 end
    b = bosses[bossPick]
    sheet.model:Show()
    pcall(function() sheet.model:ClearModel() end)
    local shown = false
    if b[3] and b[3] > 0 then
        pcall(function()
            sheet.model:SetDisplayInfo(b[3])
            shown = true
        end)
    end
    if not shown then
        pcall(function() sheet.model:SetCreature(b[1]) end)
    end
    pcall(function()
        sheet.model:SetCamDistanceScale(1.15)
        sheet.model:SetFacing(0.4)
    end)
    sheet.bossName:SetText(b[2])
    sheet.bossName:SetTextColor(1, 0.86, 0.45)
    sheet.bossSub:SetText(NS.L("ui.dg.loot"))
    sheet.bossSub:SetTextColor(0.85, 0.72, 0.48)
    for i, btn in ipairs(sheet.bossBtns) do
        local boss = bosses[i]
        if boss then
            btn.label:SetText(boss[2])
            btn.boss = i
            local on = i == bossPick
            colorTex(btn.bg, on and 0.45 or 0.16, on and 0.28 or 0.10, on and 0.08 or 0.04, 1)
            btn:Show()
        else
            btn:Hide()
        end
    end
    for i, btn in ipairs(sheet.loots) do
        local id = b[4] and b[4][i]
        if id then
            btn.itemID = id
            local link, quality, icon
            pcall(function()
                if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
                local _, l, q, _, _, _, _, _, _, ic = GetItemInfo(id)
                link, quality, icon = l, q, ic
            end)
            btn.link = link
            btn.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            local qc = ITEM_QUALITY_COLORS and quality and ITEM_QUALITY_COLORS[quality]
            if qc then setBorder(btn, { qc.r, qc.g, qc.b }) else setBorder(btn, pal().ring) end
            btn:Show()
        else
            btn.itemID = nil
            btn.link = nil
        end
    end
end

local function paintDungeonList()
    sheet.list:Show()
    sheet.detail:Hide()
    local fc = NS.factionCode()
    local book = {}
    for _, dg in ipairs(NS.Dungeons or {}) do
        if not dg.faction or dg.faction == fc then book[#book + 1] = dg end
    end
    local child = sheet.list.child
    if sheet.empty then sheet.empty:Hide() end
    local n = #book
    local rowsN = math.ceil(n / 2)
    child:SetSize(700, math.max(360, rowsN * 64 + 16))
    for i, card in ipairs(sheet.cards) do
        local dg = book[i]
        if not dg then
            card:Hide()
        else
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", 6 + col * 352, -8 - row * 64)
            card.dg = dg
            setIcon(card.box, ICON.dungeon, pal().ring)
            card.title:SetText(dgName(dg.en))
            card.title:SetTextColor(1, 0.86, 0.55)
            card.sub:SetTextColor(0.86, 0.74, 0.52)
            card.tag:SetTextColor(1, 0.78, 0.28)
            local nq = #questsFor(dg.en)
            local nb = #bossesOf(dg)
            card.sub:SetText((nq == 1 and NS.Lf("ui.dg.oneQuest", nq) or NS.Lf("ui.dg.manyQuests", nq))
                .. "  ·  " .. (nb == 1 and NS.Lf("ui.dg.oneBoss", nb) or NS.Lf("ui.dg.manyBosses", nb)))
            card.tag:SetText(NS.Lf("ui.levelRange", dg.lo, dg.hi))
            card:Show()
        end
    end
end

local function paintDungeonDetail(dg)
    if sheet.backLabel then sheet.backLabel:SetText(NS.L("ui.dg.back")) end
    sheet.list:Hide()
    sheet.detail:Show()
    sheet.head:SetText(dgName(dg.en))
    sheet.head:SetTextColor(1, 0.86, 0.45)
    sheet.kind:SetTextColor(0.85, 0.72, 0.48)
    sheet.kind:SetText(NS.Lf("ui.dg.kind", dg.lo, dg.hi, dg.where and ("  ·  " .. dg.where) or ""))
    local quests = questsFor(dg.en)
    local child = sheet.qscroll.child
    child:SetSize(380, math.max(300, #quests * 46 + 8))
    if #quests == 0 then
        sheet.qempty:SetText(NS.L("ui.dg.noQuests"))
        sheet.qempty:SetTextColor(0.9, 0.78, 0.55)
        sheet.qempty:Show()
    else
        sheet.qempty:Hide()
    end
    for i, row in ipairs(sheet.qrows) do
        local q = quests[i]
        if not q then
            row:Hide()
        else
            row:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 46)
            row.q = q
            row.title:SetText(questTitle(q[1], q[8]))
            row.title:SetTextColor(1, 0.9, 0.7)
            row.sub:SetTextColor(0.82, 0.7, 0.48)
            local who = (q[7] ~= "" and q[7] or NS.L("ui.dg.pickNpc"))
            local place = (q[4] ~= 0 and q[5] > 0) and NS.Lf("ui.dg.pick", who) or NS.L("msg.noOutside")
            row.sub:SetText(NS.Lf("ui.dg.place", q[2], place))
            row:Show()
        end
    end
    if bossPick > #bossesOf(dg) then bossPick = 1 end
    showBoss(dg)
end

local function buildDungeonSheet()
    sheet = CreateFrame("Frame", nil, page)
    sheet:SetPoint("TOPLEFT", 14, -46)
    sheet:SetPoint("BOTTOMRIGHT", -14, 34)
    sheet:Hide()

    local list = CreateFrame("ScrollFrame", nil, sheet)
    list:SetAllPoints()
    list:EnableMouseWheel(true)
    local child = CreateFrame("Frame", nil, list)
    child:SetSize(700, 400)
    list:SetScrollChild(child)
    list.child = child
    list:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 48)))
    end)
    sheet.list = list
    sheet.empty = child:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sheet.empty:SetPoint("TOPLEFT", 16, -24)
    sheet.empty:SetWidth(660)
    sheet.empty:SetJustifyH("LEFT")
    setFont(sheet.empty, 15, true)
    sheet.empty:SetTextColor(1, 0.86, 0.55)
    sheet.empty:Hide()
    sheet.cards = {}
    for i = 1, 64 do
        local card = CreateFrame("Button", nil, child)
        card:SetSize(342, 58)
        card.bg = card:CreateTexture(nil, "BACKGROUND")
        card.bg:SetAllPoints()
        colorTex(card.bg, 0.22, 0.14, 0.06, 0.92)
        addBorder(card, 2)
        setBorder(card, pal().edge, 0.8)
        card.box = iconBox(card, 40)
        card.box:SetPoint("LEFT", 8, 0)
        card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        card.title:SetPoint("TOPLEFT", 56, -8)
        card.title:SetWidth(210)
        card.title:SetJustifyH("LEFT")
        setFont(card.title, 14, true)
        card.sub = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        card.sub:SetPoint("BOTTOMLEFT", 56, 8)
        card.sub:SetWidth(210)
        card.sub:SetJustifyH("LEFT")
        setFont(card.sub, 11)
        card.tag = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        card.tag:SetPoint("RIGHT", -8, 0)
        card.tag:SetJustifyH("RIGHT")
        setFont(card.tag, 12, true)
        card:SetScript("OnClick", function(self)
            openDungeon = self.dg
            bossPick = 1
            paintDungeonDetail(self.dg)
        end)
        card:SetScript("OnEnter", function(self)
            colorTex(self.bg, 0.34, 0.22, 0.08, 1)
        end)
        card:SetScript("OnLeave", function(self)
            colorTex(self.bg, 0.22, 0.14, 0.06, 0.92)
        end)
        card:EnableMouseWheel(true)
        card:SetScript("OnMouseWheel", function(_, delta)
            local cur = list:GetVerticalScroll()
            list:SetVerticalScroll(math.max(0, math.min(list:GetVerticalScrollRange(), cur - delta * 48)))
        end)
        card:Hide()
        sheet.cards[i] = card
    end

    local detail = CreateFrame("Frame", nil, sheet)
    detail:SetAllPoints()
    detail:Hide()
    sheet.detail = detail
    local back = CreateFrame("Button", nil, detail)
    back:SetSize(110, 24)
    back:SetPoint("TOPLEFT", 0, 0)
    back.bg = back:CreateTexture(nil, "BACKGROUND")
    back.bg:SetAllPoints()
    colorTex(back.bg, 0.28, 0.16, 0.05, 1)
    addBorder(back, 2)
    setBorder(back, pal().ring)
    local bl = back:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bl:SetPoint("CENTER")
    bl:SetText(NS.L("ui.dg.back"))
    setFont(bl, 13, true)
    sheet.backLabel = bl
    back:SetScript("OnClick", function()
        openDungeon = nil
        paintDungeonList()
    end)
    sheet.head = detail:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sheet.head:SetPoint("LEFT", back, "RIGHT", 12, 6)
    sheet.head:SetJustifyH("LEFT")
    setFont(sheet.head, 18, true)
    sheet.kind = detail:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sheet.kind:SetPoint("TOPLEFT", back, "BOTTOMRIGHT", 12, 2)
    sheet.kind:SetJustifyH("LEFT")
    setFont(sheet.kind, 12)

    local qscroll = CreateFrame("ScrollFrame", nil, detail)
    qscroll:SetPoint("TOPLEFT", 0, -32)
    qscroll:SetPoint("BOTTOMLEFT", 0, 0)
    qscroll:SetWidth(400)
    qscroll:EnableMouseWheel(true)
    local qchild = CreateFrame("Frame", nil, qscroll)
    qchild:SetSize(380, 400)
    qscroll:SetScrollChild(qchild)
    qscroll.child = qchild
    qscroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), cur - delta * 46)))
    end)
    sheet.qscroll = qscroll
    sheet.qempty = qchild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sheet.qempty:SetPoint("TOPLEFT", 8, -8)
    sheet.qempty:SetWidth(360)
    sheet.qempty:SetJustifyH("LEFT")
    setFont(sheet.qempty, 13)
    sheet.qrows = {}
    for i = 1, 48 do
        local row = CreateFrame("Button", nil, qchild)
        row:SetSize(372, 42)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        colorTex(row.bg, 0.20, 0.13, 0.05, 0.9)
        addBorder(row, 1)
        row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.title:SetPoint("TOPLEFT", 8, -4)
        row.title:SetWidth(350)
        row.title:SetJustifyH("LEFT")
        setFont(row.title, 13, true)
        row.sub = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.sub:SetPoint("BOTTOMLEFT", 8, 4)
        row.sub:SetWidth(350)
        row.sub:SetJustifyH("LEFT")
        setFont(row.sub, 11)
        row:SetScript("OnClick", function(self)
            local q = self.q
            if not q then return end
            if q[4] ~= 0 and q[5] > 0 then
                NS.OpenQuestMap(q[1], q[4], q[5], q[6])
            else
                NS.msg(NS.L("msg.noOutside"))
            end
        end)
        row:SetScript("OnEnter", function(self)
            local q = self.q
            if not q then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(questTitle(q[1], q[8]), 1, 0.82, 0)
            GameTooltip:AddLine(q[4] ~= 0 and "Clic: abrir el mapa donde se coge." or "Sin punto de recogida en el exterior.", 0.9, 0.9, 0.9, true)
            GameTooltip:Show()
            colorTex(self.bg, 0.32, 0.20, 0.08, 1)
        end)
        row:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            colorTex(self.bg, 0.20, 0.13, 0.05, 0.9)
        end)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta)
            local cur = qscroll:GetVerticalScroll()
            qscroll:SetVerticalScroll(math.max(0, math.min(qscroll:GetVerticalScrollRange(), cur - delta * 46)))
        end)
        row:Hide()
        sheet.qrows[i] = row
    end

    local stage = CreateFrame("Frame", nil, detail)
    stage:SetPoint("TOPLEFT", qscroll, "TOPRIGHT", 10, 0)
    stage:SetPoint("BOTTOMRIGHT", 0, 0)
    stage.bg = stage:CreateTexture(nil, "BACKGROUND")
    stage.bg:SetAllPoints()
    colorTex(stage.bg, 0.08, 0.05, 0.02, 0.95)
    addBorder(stage, 2)
    setBorder(stage, pal().ring, 0.9)

    local model = CreateFrame("PlayerModel", nil, stage)
    model:SetPoint("TOPLEFT", 8, -8)
    model:SetSize(168, 200)
    model:SetFrameLevel(stage:GetFrameLevel() + 2)
    model.dragX = nil
    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self)
        self.dragX = select(1, GetCursorPosition())
    end)
    model:SetScript("OnMouseUp", function(self) self.dragX = nil end)
    model:SetScript("OnUpdate", function(self)
        if not self.dragX then return end
        local x = select(1, GetCursorPosition())
        local facing = 0
        pcall(function() facing = self:GetFacing() or 0 end)
        pcall(function() self:SetFacing(facing + (x - self.dragX) * 0.01) end)
        self.dragX = x
    end)
    sheet.model = model

    sheet.bossName = stage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sheet.bossName:SetPoint("TOPLEFT", model, "TOPRIGHT", 8, -2)
    sheet.bossName:SetPoint("RIGHT", -6, 0)
    sheet.bossName:SetJustifyH("LEFT")
    setFont(sheet.bossName, 13, true)
    sheet.bossSub = stage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sheet.bossSub:SetPoint("TOPLEFT", sheet.bossName, "BOTTOMLEFT", 0, -2)
    sheet.bossSub:SetJustifyH("LEFT")
    setFont(sheet.bossSub, 11)

    local bscroll = CreateFrame("ScrollFrame", nil, stage)
    bscroll:SetPoint("TOPLEFT", model, "TOPRIGHT", 6, -36)
    bscroll:SetSize(140, 156)
    bscroll:EnableMouseWheel(true)
    local bchild = CreateFrame("Frame", nil, bscroll)
    bchild:SetSize(140, 18 * 18)
    bscroll:SetScrollChild(bchild)
    bscroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), cur - delta * 18)))
    end)
    sheet.bossBtns = {}
    for i = 1, 18 do
        local btn = CreateFrame("Button", nil, bchild)
        btn:SetSize(132, 16)
        btn:SetPoint("TOPLEFT", 0, -(i - 1) * 18)
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        colorTex(btn.bg, 0.16, 0.10, 0.04, 1)
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("LEFT", 4, 0)
        fs:SetPoint("RIGHT", -2, 0)
        fs:SetJustifyH("LEFT")
        setFont(fs, 10)
        fs:SetTextColor(1, 0.86, 0.62)
        btn.label = fs
        btn:SetScript("OnClick", function(self)
            bossPick = self.boss
            if openDungeon then showBoss(openDungeon) end
        end)
        btn:Hide()
        sheet.bossBtns[i] = btn
    end

    sheet.loots = {}
    for i = 1, 16 do
        local col = (i - 1) % 8
        local row = math.floor((i - 1) / 8)
        local btn = CreateFrame("Button", nil, stage)
        btn:SetSize(32, 32)
        btn:SetPoint("BOTTOMLEFT", 8 + col * 36, 8 + (1 - row) * 36)
        btn.back = btn:CreateTexture(nil, "BACKGROUND")
        btn.back:SetAllPoints()
        colorTex(btn.back, 0, 0, 0, 1)
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetPoint("TOPLEFT", 2, -2)
        btn.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        addBorder(btn, 2)
        btn:SetScript("OnEnter", function(self)
            if not self.itemID then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local ok = false
            pcall(function()
                if self.link then ok = GameTooltip:SetHyperlink(self.link) end
                if not ok and GameTooltip.SetItemByID then GameTooltip:SetItemByID(self.itemID) end
            end)
            GameTooltip:AddLine("Mayús+clic: enlace al chat", 0.6, 0.8, 0.6)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function(self)
            if not self.link then return end
            if IsModifiedClick and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then
                ChatEdit_InsertLink(self.link)
            elseif DressUpItemLink then
                DressUpItemLink(self.link)
            end
        end)
        btn:Hide()
        sheet.loots[i] = btn
    end

    sheet:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    sheet:SetScript("OnEvent", function()
        if sheet:IsShown() and openDungeon then showBoss(openDungeon) end
    end)
end

local function logItems()
    local items = {}
    local quests = NS.quests or {}
    if #quests == 0 then
        items[1] = { icon = ICON.avail, title = "No tienes misiones en el diario",
            sub = "Habla con los NPC que tengan un ! amarillo." }
    else
        local ready = {}
        for _, q in ipairs(quests) do if q.complete then ready[#ready + 1] = q end end
        if #ready > 0 then
            local here = (GetRealZoneText and GetRealZoneText()) or ""
            table.sort(ready, function(a, b)
                local az, bz = NS.sameZone(a.zone, here), NS.sameZone(b.zone, here)
                if az ~= bz then return az end
                if a.grey ~= b.grey then return not a.grey end
                return (a.level or 99) < (b.level or 99)
            end)
            items[#items + 1] = { header = true, title = NS.Lf("ui.log.ready", #ready) }
            for _, q in ipairs(ready) do
                items[#items + 1] = { icon = ICON.turnin, title = q.title, sub = q.zone, color = "green",
                    tag = q.level > 0 and NS.Lf("ui.dg.levelOnly", q.level) or nil,
                    onLeft = function() NS.TrackQuest(q.id, q.title) end }
            end
        end
        local pending = {}
        for _, q in ipairs(quests) do
            if not q.complete then pending[#pending + 1] = q end
        end
        table.sort(pending, function(a, b)
            if a.grey ~= b.grey then return not a.grey end
            if (a.zone or "") ~= (b.zone or "") then return (a.zone or "") < (b.zone or "") end
            local ad, bd = a.dist or 9, b.dist or 9
            if ad ~= bd then return ad < bd end
            return (a.level or 0) > (b.level or 0)
        end)
        local lastZone
        for _, q in ipairs(pending) do
            if not q.complete then
                if q.zone ~= lastZone then
                    items[#items + 1] = { header = true, title = q.zone ~= "" and q.zone or NS.L("ui.log.other") }
                    lastZone = q.zone
                end
                items[#items + 1] = { icon = ICON.quest, title = q.title,
                    sub = q.grey and NS.L("ui.log.grey") or ((q.r > 0) and (q.f .. "/" .. q.r) or NS.L("ui.log.active")),
                    color = q.grey and "gray" or nil,
                    tag = q.level > 0 and NS.Lf("ui.dg.levelOnly", q.level) or nil,
                    progress = q.r > 0 and (q.f / q.r) or nil,
                    onLeft = function() NS.TrackQuest(q.id, q.title) end }
            end
        end
    end
    if #NS.recent > 0 then
        items[#items + 1] = { header = true, title = NS.Lf("ui.log.turned", #NS.recent) }
        for i, q in ipairs(NS.recent) do
            if i > 4 then break end
            items[#items + 1] = { icon = ICON.ok, title = q.title, sub = q.zone, color = "green" }
        end
    end
    return items
end

------------------------------------------------------------------------
-- Refresco general
------------------------------------------------------------------------
local function short(n)
    if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
    if n >= 1e3 then return string.format("%.1fk", n / 1e3) end
    return string.format("%d", math.floor(n))
end

local function updateHeader()
    local level = NS.currentLevel()
    local token = UnitFactionGroup("player") == "Horde" and "Horde" or "Alliance"
    levelText:SetText(NS.Lf("ui.level", level, NS.L("faction." .. token)))
    levelText:SetTextColor(0.98, 0.86, 0.55)
    if level >= NS.MAX_LEVEL then
        xpBar:SetValue(1)
        xpText:SetText(NS.L("ui.levelMax"))
    else
        local cur, max = UnitXP("player"), UnitXPMax("player")
        xpBar:SetValue(max > 0 and cur / max or 0)
        local text = NS.Lf("ui.xp", short(cur), short(max), max > 0 and math.floor(cur / max * 100) or 0)
        local rested
        pcall(function() rested = GetXPExhaustion() end)
        if rested and rested > 0 then text = text .. NS.Lf("ui.rested", short(rested)) end
        xpText:SetText(text)
    end
end

local function stylePage()
    local P = pal()
    local o = outlineOn()
    for _, f in ipairs(framesToStyle) do
        colorTex(f.page.base, unpackc(P.parch, 1))
        colorTex(f.page.inner, unpackc(P.parchIn, 0.55))
        setBorder(f.page, P.edge, 0.9)
        if f.SetBackdropColor then f:SetBackdropColor(0.13, 0.08, 0.04, 0.98) end
    end
    colorTex(orn1, P.gold[1], P.gold[2], P.gold[3], 0.75)
    colorTex(orn2, P.gold[1], P.gold[2], P.gold[3], 0.45)
    colorTex(orn3, P.gold[1], P.gold[2], P.gold[3], 0.9)
    if orn3.SetRotation then orn3:SetRotation(math.rad(45)) end
    setFont(pageTitle, 26, o)
    setFont(counter, 13, o)
    setFont(footer, 11, o)
    setFont(levelText, 13, true)
    pageTitle:SetTextColor(unpackc(P.ink))
    counter:SetTextColor(unpackc(P.ink2))
    footer:SetTextColor(unpackc(P.ink2))
end

-- Botón del minimapa. Padre UIParent: el minimapa recorta a sus hijos
-- y el botón del borde desaparece.
local mm = CreateFrame("Button", "LevelGuideMinimapButton", UIParent)
mm:SetSize(31, 31)
mm:SetFrameStrata("HIGH")
mm:SetFrameLevel(8)
if mm.SetFixedFrameStrata then mm:SetFixedFrameStrata(true) end
if mm.SetFixedFrameLevel then mm:SetFixedFrameLevel(true) end
mm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mm:RegisterForDrag("LeftButton")
mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local mmBack = mm:CreateTexture(nil, "BACKGROUND")
mmBack:SetSize(20, 20)
mmBack:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
mmBack:SetPoint("TOPLEFT", 7, -5)
local mmIcon = mm:CreateTexture(nil, "ARTWORK")
mmIcon:SetSize(18, 18)
mmIcon:SetPoint("TOPLEFT", 7, -6)
mmIcon:SetTexture(ICON.book)
mmIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
local mmBorder = mm:CreateTexture(nil, "OVERLAY")
mmBorder:SetSize(53, 53)
mmBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mmBorder:SetPoint("TOPLEFT")
local mmBadge = mm:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
mmBadge:SetPoint("TOPRIGHT", 6, 6)
mmBadge:SetTextColor(1, 0.82, 0)
mmBadge:Hide()

local function placeMinimapButton()
    local angle = math.rad(NS.cfg and NS.cfg.mmAngle or 215)
    local radius = (Minimap:GetWidth() / 2) + 5
    mm:ClearAllPoints()
    mm:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
    mm:Show()
end

local atan2 = math.atan2 or math.atan
mm:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local s = Minimap:GetEffectiveScale()
        px, py = px / s, py / s
        NS.cfg.mmAngle = math.deg(atan2(py - my, px - mx)) % 360
        placeMinimapButton()
    end)
end)
mm:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
end)

local toggleOptions
local function toggleWindow()
    if win:IsShown() then win:Hide() else win:Show() end
end

mm:SetScript("OnClick", function(_, button)
    if button == "RightButton" then toggleOptions() else toggleWindow() end
end)
mm:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("LevelGuide", 1, 0.82, 0)
    local t = NS.tasks and NS.tasks[1]
    if t then
        GameTooltip:AddLine(t.title, 1, 1, 1, true)
        if t.sub then GameTooltip:AddLine(t.sub, 0.8, 0.8, 0.8, true) end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(NS.L("ui.mm.left"), 0.6, 0.9, 0.6)
    GameTooltip:AddLine(NS.L("ui.mm.right"), 0.6, 0.9, 0.6)
    GameTooltip:AddLine(NS.L("ui.mm.drag"), 0.6, 0.9, 0.6)
    GameTooltip:Show()
end)
mm:SetScript("OnLeave", function() GameTooltip:Hide() end)
placeMinimapButton()

local settings
local buildOptions
local refreshOptions
local lastNextKey
local ANNOUNCE = { turnin = true, zone = true }

local TAB_INFO = {
    now      = "ui.tab.now.tip",
    route    = "ui.tab.route.tip",
    dungeons = "ui.tab.dungeons",
    log      = "ui.tab.log.tip",
    settings = "ui.settings.title",
}

function NS.Refresh()
    local cfg = NS.cfg
    if not cfg then return end
    local tasks = NS.BuildTasks()
    NS.tasks = tasks
    local first = tasks[1]

    -- aviso del botón del minimapa
    if first and first.kind == "turnin" then
        mmBadge:SetText("?"); mmBadge:Show()
    elseif first and first.kind == "zone" then
        mmBadge:SetText("!"); mmBadge:Show()
    else
        mmBadge:Hide()
    end

    -- anuncio cuando cambia el siguiente paso
    if first and first.key ~= lastNextKey then
        if lastNextKey and ANNOUNCE[first.kind] then
            NS.alert("next" .. first.key, 15, NS.Lf("msg.next", first.title))
        end
        lastNextKey = first.key
    end

    if win:IsShown() then
        local P = pal()
        updateHeader()
        stylePage()
        for id, b in pairs(tabs) do
            local on = id == currentTab
            colorTex(b.bg, on and 0.62 or 0.20, on and 0.40 or 0.13, on and 0.10 or 0.05, 1)
            setBorder(b, on and P.ring or P.ringOff)
            b.label:SetText(NS.L(b.textKey or ""))
            b.label:SetTextColor(on and 1 or 0.78, on and 0.92 or 0.70, on and 0.62 or 0.48)
        end
        pageTitle:SetText(NS.L(TAB_INFO[currentTab]))

        local level = NS.currentLevel()
        local fc = NS.factionCode()
        if currentTab == "now" then
            if sheet then sheet:Hide() end
            counter:SetText(first and first.step and NS.Lf("ui.now.counter", first.step) or NS.L("ui.now.counterEmpty"))
            footer:SetText(NS.L("ui.now.footer"))
            if settings then settings:Hide() end
            hero:Show()
            fillHero(first)
            setItems(nowItems(tasks), "hero")
        else
            hero:Hide()
            if settings then settings:Hide() end
            if sheet and currentTab ~= "dungeons" then sheet:Hide() end
            if currentTab == "route" then
                counter:SetText(NS.Lf("ui.route.counter", level))
                footer:SetText(NS.L("ui.route.footer"))
                setItems(routeItems(), "list")
            elseif currentTab == "dungeons" then
                if not sheet then buildDungeonSheet() end
                sheet:Show()
                setItems({}, "list")
                if openDungeon then
                    counter:SetText(dgName(openDungeon.en))
                    footer:SetText(NS.L("ui.dg.detailFooter"))
                    paintDungeonDetail(openDungeon)
                else
                    counter:SetText(NS.L("ui.dg.counter"))
                    footer:SetText(NS.L("ui.dg.footer"))
                    paintDungeonList()
                end
            elseif currentTab == "settings" then
                if not settings then buildOptions() end
                counter:SetText(NS.L("ui.settings.counter"))
                footer:SetText(NS.L("ui.settings.footer"))
                pageTitle:SetText(NS.L("ui.settings.title"))
                setItems({}, "list")
                settings:Show()
                refreshOptions()
            else
                counter:SetText(NS.Lf("ui.log.counter", #(NS.quests or {})))
                footer:SetText(NS.L("ui.log.footer"))
                setItems(logItems(), "list")
            end
        end
    end
    NS.UpdateTracker()
end

win:SetScript("OnShow", function() NS.Refresh() end)

------------------------------------------------------------------------
-- Mini tracker de XP (flotante)
------------------------------------------------------------------------
local startTime, sessionXP, lastXP, lastMax, lastGain = GetTime(), 0, 0, 0, 0
local tracker = CreateFrame("Frame", "LevelGuideTracker", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
tracker.posKey = "LevelGuideTracker"
tracker:SetSize(320, 74)
tracker:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then toggleWindow() end
end)
tracker:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 220)
tracker:Hide()
tracker:SetClampedToScreen(true)
tracker:SetMovable(true)
tracker:EnableMouse(true)
tracker:RegisterForDrag("LeftButton")
if tracker.SetBackdrop then tracker:SetBackdrop(SMALL_BACKDROP) end
tracker:SetScript("OnDragStart", function(self)
    if NS.cfg and not NS.cfg.lock then self:StartMoving() end
end)
tracker:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    savePos(self)
end)
local tline1 = tracker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
tline1:SetPoint("TOPLEFT", 8, -6)
tline1:SetPoint("RIGHT", -8, 0)
tline1:SetJustifyH("LEFT")
tline1:SetWordWrap(false)
local tline2 = tracker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
tline2:SetPoint("TOPLEFT", 8, -22)
tline2:SetPoint("RIGHT", -8, 0)
tline2:SetJustifyH("LEFT")
tline2:SetWordWrap(false)
local tline3 = tracker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
tline3:SetPoint("TOPLEFT", 8, -38)
tline3:SetPoint("RIGHT", -8, 0)
tline3:SetJustifyH("LEFT")
tline3:SetWordWrap(false)
local tline4 = tracker:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
tline4:SetPoint("TOPLEFT", 8, -54)
tline4:SetPoint("RIGHT", -8, 0)
tline4:SetJustifyH("LEFT")
tline4:SetWordWrap(false)

local function fmtTime(sec)
    sec = math.max(0, math.floor(sec))
    if sec >= 3600 then return string.format("%dh%02dm", math.floor(sec / 3600), math.floor((sec % 3600) / 60)) end
    return string.format("%dm%02ds", math.floor(sec / 60), sec % 60)
end

function NS.UpdateTracker()
    local cfg = NS.cfg
    if not cfg or not cfg.xp or UnitLevel("player") >= NS.MAX_LEVEL then
        tracker:Hide()
        return
    end
    tracker:Show()
    local hint = NS.guideHint or {}
    local step = NS.tasks and NS.tasks[1]
    local nxt = NS.tasks and NS.tasks[2]
    tline1:SetText(hint.zone and NS.Lf("track.zone", hint.zone) or NS.L("track.zoneWait"))
    tline2:SetText(step and NS.Lf("track.step", step.title) or NS.L("track.stepWait"))
    local nextBit = nxt and NS.Lf("track.next", nxt.title) or NS.L("track.nextNone")
    if hint.dungeon then nextBit = nextBit .. "   ·   " .. hint.dungeon end
    tline3:SetText(nextBit)
    local elapsed = GetTime() - startTime
    local rate = (elapsed > 30) and (sessionXP / elapsed * 3600) or 0
    local remaining = UnitXPMax("player") - UnitXP("player")
    local eta = NS.L("track.etaNone")
    if rate > 0 then eta = NS.Lf("track.eta", fmtTime(remaining / (rate / 3600))) end
    tline4:SetText(NS.Lf("track.xph", short(rate), eta))
end

local function initXP() lastXP, lastMax = UnitXP("player"), UnitXPMax("player") end

NS.On("PLAYER_XP_UPDATE", function()
    local cur, max = UnitXP("player"), UnitXPMax("player")
    local gained = (max ~= lastMax) and ((lastMax - lastXP) + cur) or (cur - lastXP)
    if gained > 0 then
        sessionXP = sessionXP + gained
        lastGain = gained
    end
    lastXP, lastMax = cur, max
    NS.RequestRefresh()
end)

local function resetXP()
    startTime, sessionXP, lastGain = GetTime(), 0, 0
    initXP()
    NS.UpdateTracker()
end

C_Timer.NewTicker(1, function() if NS.cfg then NS.UpdateTracker() end end)

------------------------------------------------------------------------
-- Ventana de opciones
------------------------------------------------------------------------
local ORDER = { "quest", "sell", "repair", "autoloot", "dungeons", "arrow", "xp", "minimap", "contrast", "voice", "lock" }
local LEFT = { "dungeons", "arrow", "quest", "xp", "minimap" }
local RIGHT = { "sell", "repair", "autoloot", "contrast", "voice", "lock" }

local function optTitle(key) return NS.L("ui.opt." .. key) end
local function optHint(key) return NS.L("ui.opt." .. key .. ".hint") end

refreshOptions = function()
    if not settings then return end
    local P = pal()
    for key, row in pairs(settings.rows) do
        local on = NS.cfg[key] and true or false
        colorTex(row.bg, on and 0.16 or 0.28, on and 0.32 or 0.14, on and 0.14 or 0.08, 0.95)
        row.state:SetText(on and NS.L("ui.settings.yes") or NS.L("ui.settings.no"))
        row.state:SetTextColor(on and 0.55 or 0.65, on and 0.9 or 0.35, on and 0.45 or 0.28)
        row.title:SetText(optTitle(key))
        row.hint:SetText(optHint(key))
        row.title:SetTextColor(unpackc(P.ink))
        row.hint:SetTextColor(unpackc(P.ink2))
    end
    settings.sizeText:SetText(NS.Lf("ui.settings.size", sizeName(NS.cfg.size)))
    settings.sizeText:SetTextColor(unpackc(P.ink))
    settings.langLabel:SetText(NS.L("ui.settings.lang"))
    settings.langHint:SetText(NS.L("ui.settings.langHint"))
    settings.langLabel:SetTextColor(unpackc(P.ink))
    settings.langHint:SetTextColor(unpackc(P.ink2))
    settings.restore:SetText(NS.L("ui.settings.restore"))
    if settings.colRoute then settings.colRoute:SetText(NS.L("ui.settings.route")) end
    if settings.colPlay then settings.colPlay:SetText(NS.L("ui.settings.play")) end
    local current = NS.Lang()
    for code, btn in pairs(settings.langButtons) do
        local on = code == current
        colorTex(btn.bg, on and 0.16 or 0.28, on and 0.32 or 0.14, on and 0.14 or 0.08, 0.95)
        btn.label:SetTextColor(unpackc(on and P.green or P.ink))
    end
end

buildOptions = function()
    settings = CreateFrame("Frame", nil, page)
    settings:SetPoint("TOPLEFT", 16, -68)
    settings:SetPoint("BOTTOMRIGHT", -16, 28)
    settings:Hide()
    settings.rows = {}
    settings.langButtons = {}

    local function column(titleKey, keys, x, headKey)
        local head = settings:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        head:SetPoint("TOPLEFT", x, 0)
        head:SetText(NS.L(titleKey))
        settings[headKey] = head
        for i, key in ipairs(keys) do
            local row = CreateFrame("Button", nil, settings)
            row:SetSize(348, 40)
            row:SetPoint("TOPLEFT", x, -18 - (i - 1) * 42)
            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            addBorder(row, 1)
            row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.title:SetPoint("TOPLEFT", 12, -6)
            row.title:SetText(optTitle(key))
            row.hint = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.hint:SetPoint("BOTTOMLEFT", 12, 6)
            row.hint:SetText(optHint(key))
            row.state = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            row.state:SetPoint("RIGHT", -16, 0)
            row:SetScript("OnClick", function()
                setOption(key, not NS.cfg[key])
            end)
            settings.rows[key] = row
        end
    end

    column("ui.settings.route", LEFT, 8, "colRoute")
    column("ui.settings.play", RIGHT, 368, "colPlay")

    settings.langLabel = settings:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settings.langLabel:SetPoint("BOTTOMLEFT", 12, 78)
    settings.langHint = settings:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    settings.langHint:SetPoint("BOTTOMLEFT", 12, 60)
    local x = 220
    for _, code in ipairs(NS.localeOrder or {}) do
        local info = NS.locales[code]
        local btn = CreateFrame("Button", nil, settings)
        btn:SetSize(110, 26)
        btn:SetPoint("BOTTOMLEFT", x, 70)
        x = x + 116
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        addBorder(btn, 1)
        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btn.label:SetPoint("CENTER")
        btn.label:SetText(info.name)
        btn:SetScript("OnClick", function() setOption("lang", code) end)
        settings.langButtons[code] = btn
    end

    settings.sizeText = settings:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settings.sizeText:SetPoint("BOTTOMLEFT", 12, 8)
    local minus = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
    minus:SetSize(36, 26)
    minus:SetPoint("BOTTOMLEFT", 200, 4)
    minus:SetText("-")
    minus:SetScript("OnClick", function() setOption("size", math.max(1, NS.cfg.size - 1)) end)
    local plus = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
    plus:SetSize(36, 26)
    plus:SetPoint("LEFT", minus, "RIGHT", 6, 0)
    plus:SetText("+")
    plus:SetScript("OnClick", function() setOption("size", math.min(#WIN_SCALES, NS.cfg.size + 1)) end)
    local restore = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
    restore:SetSize(180, 26)
    restore:SetPoint("BOTTOMRIGHT", -8, 4)
    restore:SetText(NS.L("ui.settings.restore"))
    restore:SetScript("OnClick", function()
        NS.cfg.dismissed = {}
        NS.msg(NS.L("msg.skipped"))
        NS.RequestRefresh()
    end)
    settings.restore = restore
end

toggleOptions = function()
    currentTab, pageNum = "settings", 1
    if win:IsShown() then NS.Refresh() else win:Show() end
end

------------------------------------------------------------------------
-- Apariencia y accesibilidad
------------------------------------------------------------------------
function NS.ApplyLook()
    local cfg = NS.cfg
    if not cfg then return end
    win:SetScale(WIN_SCALES[cfg.size] or 1)
    tracker:SetScale(TRACK_SCALES[cfg.size] or 1)
    if tracker.SetBackdropColor then
        if cfg.contrast then
            tracker:SetBackdropColor(0, 0, 0, 1)
            tracker:SetBackdropBorderColor(1, 1, 1, 1)
        else
            tracker:SetBackdropColor(0, 0, 0, 0.7)
            tracker:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
        end
    end
    local flags = cfg.contrast and "OUTLINE" or ""
    tline1:SetFont(STANDARD_TEXT_FONT, 11, flags)
    tline2:SetFont(STANDARD_TEXT_FONT, 11, flags)
    tline3:SetFont(STANDARD_TEXT_FONT, 11, flags)
    tline4:SetFont(STANDARD_TEXT_FONT, 10, flags)
    xpText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    stylePage()
    if cfg.minimap then mm:Show() else mm:Hide() end
end

setOption = function(key, value)
    local cfg = NS.cfg
    if not cfg then return end
    cfg[key] = value
    if key == "autoloot" then
        local set = (C_CVar and C_CVar.SetCVar) or SetCVar
        set("autoLootDefault", value and "1" or "0")
    end
    NS.ApplyLook()
    refreshOptions()
    NS.RequestRefresh()
end

------------------------------------------------------------------------
-- Inicio
------------------------------------------------------------------------
NS.On("PLAYER_LOGIN", function()
    local cfg = NS.cfg
    restorePos(win)
    restorePos(tracker)
    initXP()
    placeMinimapButton()
    NS.ApplyLook()
    NS.Refresh()
    NS.msg(NS.L("msg.loaded"))
    if not cfg.seen then
        cfg.seen = true
        win:Show()
    end
end)

------------------------------------------------------------------------
-- Comandos
------------------------------------------------------------------------
local ALIASES = {
    opciones = "options", options = "options", config = "options",
    ruta = "route", route = "route", pasos = "route",
    leer = "read", read = "read",
    tamano = "size", ["tamaño"] = "size", size = "size",
    contraste = "contrast", contrast = "contrast",
    voz = "voice", voice = "voice",
    vender = "sell", sell = "sell",
    reparar = "repair", repair = "repair",
    misiones = "quest", quest = "quest",
    mazmorras = "dungeons", dungeons = "dungeons",
    xp = "xp", minimapa = "minimap", minimap = "minimap",
    loot = "autoloot", autoloot = "autoloot",
    bloquear = "lock", lock = "lock",
    reset = "reset", reiniciar = "reset",
    restaurar = "restore", restore = "restore",
    idioma = "lang", language = "lang", lang = "lang",
    ayuda = "help", help = "help",
}

local function status()
    NS.msg(NS.L("msg.helpTitle"))
    print(NS.L("msg.help1"))
    print(NS.L("msg.help2"))
    print(NS.Lf("msg.help3", sizeName(NS.cfg.size)))
    print(NS.L("msg.help4"))
    print(NS.L("msg.help5"))
    for _, k in ipairs(ORDER) do
        print(NS.Lf("msg.helpOpt", k, NS.onoff(NS.cfg[k]), optTitle(k)))
    end
end

SLASH_LEVELGUIDE1 = "/lg"
SLASH_LEVELGUIDE2 = "/levelguide"
SlashCmdList["LEVELGUIDE"] = function(input)
    local cfg = NS.cfg
    if not cfg then return end
    local word, arg = (input or ""):match("^(%S*)%s*(.-)$")
    local cmd = ALIASES[word:lower()] or word:lower()

    if cmd == "" then
        toggleWindow()
    elseif cmd == "help" then
        status()
    elseif cmd == "options" then
        toggleOptions()
    elseif cmd == "route" then
        NS.PrintTasks()
    elseif cmd == "read" then
        local t = (NS.tasks or NS.BuildTasks())[1]
        NS.speak(t and (t.title .. ". " .. (t.sub or "")) or NS.L("msg.allOk"), true)
    elseif cmd == "lang" then
        local code = (arg or ""):lower()
        if NS.locales[code] then
            setOption("lang", code)
            NS.msg(NS.Lf("msg.lang", NS.locales[code].name))
        else
            NS.msg(NS.L("msg.langUsage"))
        end
    elseif cmd == "reset" then
        resetXP()
        NS.msg(NS.L("msg.xpReset"))
    elseif cmd == "restore" then
        cfg.dismissed = {}
        NS.msg(NS.L("msg.restored"))
        NS.RequestRefresh()
    elseif cmd == "size" then
        local n = tonumber(arg)
        if n and n >= 1 and n <= #WIN_SCALES then
            setOption("size", math.floor(n))
            NS.msg(NS.Lf("msg.size", sizeName(cfg.size)))
        else
            NS.msg(NS.L("msg.sizeUsage"))
        end
    elseif optTitle(cmd) ~= ("ui.opt." .. cmd) then
        setOption(cmd, not cfg[cmd])
        NS.msg(NS.Lf("msg.opt", optTitle(cmd), NS.onoff(cfg[cmd])))
    else
        status()
    end
end
