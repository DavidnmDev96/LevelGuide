-- LevelGuide: datos de la guia de leveo (editables)
--
-- ZONAS: rangos de nivel de guias de la comunidad de WoW Forever (no hay tabla oficial de
--   Blizzard; los rangos marcados como Classic son aproximados).
-- PUEBLOS (hubs): donde recoger misiones en cada zona. Basados en Classic: Forever anade
--   mas de 1000 misiones, asi que pueden variar. Si uno no te cuadra, edita este archivo.
-- MAZMORRAS: el numero de misiones y los niveles de las misiones (campo qlvl) salen del
--   Diario de misiones de Forever. Los rangos de jugador (lo-hi) son los de Classic, aproximados.
--   Faltan las mazmorras nuevas de Forever cuyo rango no esta publicado.
-- Los IDs de mapa son los de Classic; si un mapa abre otra zona, corrige el numero.

local _, NS = ...

NS.MAX_LEVEL = 60
NS.Zones = {}
NS.Hubs = {}
NS.Dungeons = {}

local function z(key, en, es, min, max, dungeons, map)
    NS.Zones[key] = { en = en, es = es, min = min, max = max, dungeons = dungeons, map = map }
end

-- faction: "A" (Alianza), "H" (Horda) o nil (ambas)
local function h(zone, name, lo, hi, faction)
    local list = NS.Hubs[zone]
    if not list then list = {}; NS.Hubs[zone] = list end
    list[#list + 1] = { name = name, lo = lo, hi = hi, faction = faction }
end

local function d(en, lo, hi, quests, qlvl, where, zone, faction)
    NS.Dungeons[#NS.Dungeons + 1] = {
        en = en, lo = lo, hi = hi, quests = quests, qlvl = qlvl,
        where = where, zone = zone, faction = faction,
    }
end

------------------------------------------------------------------------
-- Zonas
------------------------------------------------------------------------
-- Zonas de inicio
z("elwynn",     "Elwynn Forest",   "Bosque de Elwynn",   1, 10, "The Stockade", 1429)
z("dunmorogh",  "Dun Morogh",      "Dun Morogh",         1, 10, "Hall of Thanes, Gnomeregan", 1426)
z("teldrassil", "Teldrassil",      "Teldrassil",         1, 10, nil, 1438)
z("durotar",    "Durotar",         "Durotar",            1, 10, "Ragefire Chasm", 1411)
z("mulgore",    "Mulgore",         "Mulgore",            1, 10, nil, 1412)
z("tirisfal",   "Tirisfal Glades", "Claros de Tirisfal", 1, 10, "Ruins of Lordaeron, Scarlet Monastery", 1420)
z("zephras",    "Zephras Isle",    "Zephras Isle",       1, 12)

-- Zonas de leveo
z("westfall",   "Westfall",          "Páramos de Poniente", 10, 20, "The Deadmines", 1436)
z("lochmodan",  "Loch Modan",        "Loch Modan",          10, 20, nil, 1432)
z("darkshore",  "Darkshore",         "Costa Oscura",        10, 20, "Blackfathom Deeps", 1439)
z("silverpine", "Silverpine Forest", "Bosque de Argénteos", 10, 20, "Shadowfang Keep", 1421)
z("barrens",    "The Barrens",       "Los Baldíos",         10, 25, "Wailing Caverns, Razorfen Kraul, Razorfen Downs", 1413)
z("redridge",   "Redridge Mountains","Montañas Crestagrana",15, 25, nil, 1433)
z("stonetalon", "Stonetalon Mountains","Sierra Espolón",    15, 27, nil, 1442)
z("duskwood",   "Duskwood",          "Bosque del Ocaso",    18, 30, nil, 1431)
z("ashenvale",  "Ashenvale",         "Vallefresno",         18, 30, nil, 1440)
z("wetlands",   "Wetlands",          "Los Humedales",       20, 30, "Excavation Site", 1437)
z("hillsbrad",  "Hillsbrad Foothills","Laderas de Trabalomas",20, 30, nil, 1424)
z("thousand",   "Thousand Needles",  "Las Mil Agujas",      25, 35, nil, 1441)
z("arathi",     "Arathi Highlands",  "Tierras Altas de Arathi", 30, 40, nil, 1417)
z("desolace",   "Desolace",          "Desolace",            30, 40, "Maraudon", 1443)
z("stv",        "Stranglethorn Vale","Vega de Tuercespina", 30, 45, "The Drowned City", 1434)
z("riverglades","Riverglades",       "Riverglades",         35, 45, "Krol'Dok Stronghold")
z("dustwallow", "Dustwallow Marsh",  "Marjal Revolcafango", 35, 45, "Alcaz Island Prison", 1445)
z("tanaris",    "Tanaris",           "Tanaris",             40, 50, "Zul'Farrak", 1446)
z("feralas",    "Feralas",           "Feralas",             40, 50, "Dire Maul", 1444)
z("hinterlands","The Hinterlands",   "Tierras del Interior",40, 50, nil, 1425)
z("searing",    "Searing Gorge",     "Garganta de Fuego",   43, 50, "Blackrock Depths", 1427)
z("felwood",    "Felwood",           "Frondavil",           48, 55, nil, 1448)
z("ungoro",     "Un'Goro Crater",    "Cráter de Un'Goro",   48, 55, "Shaper's Terrace", 1449)
z("burning",    "Burning Steppes",   "Estepas Ardientes",   50, 58, "Blackrock Spire", 1428)
z("wpl",        "Western Plaguelands","Tierras de la Peste del Oeste", 51, 58, "Scholomance", 1422)
z("winterspring","Winterspring",     "Cuna del Invierno",   53, 60, nil, 1452)
z("silithus",   "Silithus",          "Silithus",            55, 60, nil, 1451)
z("epl",        "Eastern Plaguelands","Tierras de la Peste del Este", 53, 60, "Stratholme", 1423)
z("hyjal",      "Mount Hyjal",       "Monte Hyjal",         60, 60, "Bandas: Barrow Deeps, Hyjal Summit")

-- Zona de inicio segun raza ("START" en la ruta)
NS.StartZone = {
    Human = "elwynn", Dwarf = "dunmorogh", Gnome = "dunmorogh", NightElf = "teldrassil",
    Orc = "durotar", Troll = "durotar", Tauren = "mulgore", Scourge = "tirisfal",
}

------------------------------------------------------------------------
-- Pueblos donde recoger misiones (nombres en ingles, como se ven en el mapa)
------------------------------------------------------------------------
h("elwynn", "Northshire Abbey", 1, 5, "A");        h("elwynn", "Goldshire", 5, 10, "A")
h("dunmorogh", "Coldridge Valley", 1, 5, "A");     h("dunmorogh", "Kharanos", 5, 10, "A")
h("teldrassil", "Shadowglen", 1, 5, "A");          h("teldrassil", "Dolanaar", 5, 10, "A")
h("durotar", "Valley of Trials", 1, 5, "H");       h("durotar", "Razor Hill", 5, 10, "H")
h("mulgore", "Camp Narache", 1, 5, "H");           h("mulgore", "Bloodhoof Village", 5, 10, "H")
h("tirisfal", "Deathknell", 1, 5, "H");            h("tirisfal", "Brill", 5, 10, "H")

h("westfall", "Sentinel Hill", 10, 15, "A");       h("westfall", "Moonbrook", 15, 20, "A")
h("lochmodan", "Thelsamar", 10, 18, "A")
h("darkshore", "Auberdine", 10, 20, "A")
h("silverpine", "The Sepulcher", 10, 20, "H")
h("barrens", "The Crossroads", 10, 20, "H");       h("barrens", "Camp Taurajo", 20, 25, "H")
h("redridge", "Lakeshire", 15, 25, "A")
h("stonetalon", "Sun Rock Retreat", 15, 27, "H")
h("duskwood", "Darkshire", 20, 30, "A")
h("ashenvale", "Astranaar", 18, 30, "A");          h("ashenvale", "Splintertree Post", 18, 30, "H")
h("wetlands", "Menethil Harbor", 20, 30, "A")
h("hillsbrad", "Southshore", 20, 30, "A");         h("hillsbrad", "Tarren Mill", 20, 30, "H")
h("thousand", "Freewind Post", 25, 35, "H")
h("arathi", "Refuge Pointe", 30, 40, "A");         h("arathi", "Hammerfall", 30, 40, "H")
h("desolace", "Nijel's Point", 30, 40, "A");       h("desolace", "Shadowprey Village", 30, 40, "H")
h("stv", "Nesingwary's Expedition", 30, 40);       h("stv", "Booty Bay", 35, 45)
h("dustwallow", "Theramore Isle", 35, 45, "A");    h("dustwallow", "Brackenwall Village", 35, 45, "H")
h("tanaris", "Gadgetzan", 40, 50)
h("feralas", "Feathermoon Stronghold", 40, 50, "A"); h("feralas", "Camp Mojache", 40, 50, "H")
h("hinterlands", "Aerie Peak", 40, 50, "A");       h("hinterlands", "Revantusk Village", 40, 50, "H")
h("searing", "Thorium Point", 43, 50)
h("felwood", "Talonbranch Glade", 48, 55)
h("ungoro", "Marshal's Refuge", 48, 55)
h("burning", "Morgan's Vigil", 50, 58, "A");       h("burning", "Flame Crest", 50, 58, "H")
h("wpl", "Chillwind Camp", 51, 58, "A");           h("wpl", "The Bulwark", 51, 58, "H")
h("winterspring", "Everlook", 53, 60)
h("silithus", "Cenarion Hold", 55, 60)
h("epl", "Light's Hope Chapel", 53, 60)

------------------------------------------------------------------------
-- Mazmorras: d(nombre, nivel min, nivel max, nº misiones, niveles de misión, dónde, zona, facción)
------------------------------------------------------------------------
d("Ragefire Chasm",       13, 18,  6, "15-16", "Orgrimmar",                nil,        "H")
d("Wailing Caverns",      17, 24, nil, nil,    "The Barrens",              "barrens")
d("The Deadmines",        17, 26, nil, nil,    "Westfall",                 "westfall")
d("Ruins of Lordaeron",   20, 25,  9, "21-22", "Undercity (Tirisfal)",     "tirisfal", "H")
d("Shadowfang Keep",      22, 30,  3, "25-27", "Silverpine Forest",        "silverpine")
d("Blackfathom Deeps",    22, 32,  8, nil,     "costa de Ashenvale",       "ashenvale")
d("The Stockade",         24, 32, nil, nil,    "Stormwind",                nil,        "A")
d("Razorfen Kraul",       26, 34,  5, nil,     "The Barrens",              "barrens")
d("Gnomeregan",           28, 36, nil, nil,    "Dun Morogh",               "dunmorogh")
d("Excavation Site",      29, 35,  5, "31",    "Wetlands",                 "wetlands")
d("City of Dalaran",      30, 38,  4, "33",    "Alterac Mountains",        nil)
d("Scarlet Monastery",    34, 45,  6, nil,     "Tirisfal Glades",          "tirisfal")
d("Razorfen Downs",       35, 44,  5, nil,     "The Barrens",              "barrens")
d("Uldaman",              38, 48, nil, nil,    "Badlands",                 nil)
d("Zul'Farrak",           42, 50, nil, nil,    "Tanaris",                  "tanaris")
d("Maraudon",             42, 52,  8, "42-51", "Desolace",                 "desolace")
d("Temple of Atal'Hakkar",48, 56, nil, nil,    "Swamp of Sorrows",         nil)
d("Blackrock Depths",     50, 58, 27, nil,     "Searing Gorge",            "searing")
d("Blackrock Spire",      55, 60, 27, nil,     "Burning Steppes",          "burning")
d("Dire Maul",            57, 60, 23, nil,     "Feralas",                  "feralas")
d("Scholomance",          58, 60, 11, nil,     "Western Plaguelands",      "wpl")
d("Stratholme",           58, 60, 16, nil,     "Eastern Plaguelands",      "epl")

------------------------------------------------------------------------
-- Ruta sugerida: {nivel desde, nivel hasta, {zonas}}.
-- Se recomienda la primera zona de la lista cuya franja incluya tu nivel; el resto son alternativas.
------------------------------------------------------------------------
local late = {
    { 40, 49, { "dustwallow", "tanaris", "feralas", "hinterlands", "searing" } },
    { 50, 59, { "ungoro", "felwood", "burning", "wpl", "winterspring", "silithus" } },
    { 60, 60, { "hyjal", "epl" } },
}

NS.Route = {
    Alliance = {
        { 1,  9,  { "START" } },
        { 10, 12, { "zephras" } },
        { 13, 19, { "westfall", "lochmodan", "darkshore" } },
        { 20, 29, { "redridge", "duskwood", "wetlands", "ashenvale" } },
        { 30, 39, { "arathi", "stv", "desolace", "riverglades" } },
    },
    Horde = {
        { 1,  9,  { "START" } },
        { 10, 12, { "zephras" } },
        { 13, 19, { "silverpine", "barrens" } },
        { 20, 29, { "stonetalon", "ashenvale", "hillsbrad" } },
        { 30, 39, { "thousand", "arathi", "stv", "desolace", "riverglades" } },
    },
}
for _, route in pairs(NS.Route) do
    for _, b in ipairs(late) do route[#route + 1] = b end
end

-- Devuelve la zona recomendada y las alternativas para un nivel y facción
function NS.Recommend(level, faction)
    local route = NS.Route[faction] or NS.Route.Alliance
    for _, b in ipairs(route) do
        if level >= b[1] and level <= b[2] then
            local primary, alts = nil, {}
            for _, key in ipairs(b[3]) do
                local zone = NS.Zones[key]
                local ok = key == "START" or (level >= zone.min and level <= zone.max)
                if ok then
                    if not primary then primary = key else alts[#alts + 1] = key end
                end
            end
            return primary or b[3][1], alts
        end
    end
    return "hyjal", {}
end

-- Proximo nivel en el que cambia la zona recomendada
function NS.NextChange(level, faction)
    local current = NS.Recommend(level, faction)
    for l = level + 1, NS.MAX_LEVEL do
        local key = NS.Recommend(l, faction)
        if key ~= current then return l, key end
    end
end
