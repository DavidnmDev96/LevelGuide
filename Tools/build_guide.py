# Genera Guide.lua: una ruta de pasos fijos (aceptar / hacer / entregar),
# el formato de RestedXP, Zygor y Guidelime. El texto de esas guías no se copia.
# Los hechos (cadenas, nivel, NPC) salen de la base de misiones de Forever.
import math
import os

SRC = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "JournalForever", "JournalData.lua"))
OUT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "Guide.lua"))

ALLIANCE = 77
HORDE = 178

AREA_MAP = {
    1: 1426, 3: 1418, 4: 1419, 8: 1435, 9: 1429, 10: 1431, 11: 1437, 12: 1429,
    14: 1411, 15: 1445, 16: 1447, 17: 1413, 28: 1422, 33: 1434, 36: 1416, 38: 1432,
    40: 1436, 44: 1433, 45: 1417, 46: 1428, 47: 1425, 51: 1427, 85: 1420, 130: 1421,
    132: 1426, 139: 1423, 141: 1438, 148: 1439, 154: 1420, 188: 1438, 215: 1412,
    220: 1412, 267: 1424, 331: 1440, 357: 1444, 361: 1448, 363: 1411, 400: 1441,
    405: 1443, 406: 1442, 440: 1446, 490: 1449, 618: 1452, 1377: 1451,
    1497: 1458, 1519: 1453, 1537: 1455, 1637: 1454, 1638: 1456, 1657: 1457,
}

SKIP_CATS = {
    "Cooking", "Fishing", "First Aid", "Alchemy", "Blacksmithing", "Engineering",
    "Leatherworking", "Tailoring", "Herbalism", "Seasonal", "Lunar Festival",
    "Darkmoon Faire", "Midsummer", "Invasion", "Ahn'Qiraj War", "Legendary",
    "Reputation", "Special",
}
SKIP_DUNGEON = ("Blackwing", "Molten Core", "Naxxramas", "Ahn'Qiraj", "Zul'Gurub", "Onyxia")
BG_AREAS = {2597, 3277, 3358}  # Warsong, Arathi Basin, Alterac Valley


def extract_table(text, marker):
    i = text.find(marker)
    if i < 0:
        raise SystemExit("no está " + marker)
    i = text.find("{", i)
    depth = 0
    for j in range(i, len(text)):
        c = text[j]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return text[i:j + 1]
    raise SystemExit("tabla sin cerrar " + marker)


class Parser:
    def __init__(self, s):
        self.s = s
        self.n = len(s)
        self.i = 0

    def peek(self):
        return self.s[self.i] if self.i < self.n else ""

    def skip(self):
        s, i, n = self.s, self.i, self.n
        while i < n and s[i] in " \t\r\n,;":
            i += 1
        self.i = i

    def parse(self):
        self.skip()
        c = self.peek()
        if c == "{":
            return self.table()
        if c == '"':
            return self.string()
        if c == "-" or c.isdigit():
            return self.number()
        for word, val in (("nil", None), ("true", True), ("false", False)):
            if self.s.startswith(word, self.i):
                self.i += len(word)
                return val
        raise SystemExit("token raro en %d: %r" % (self.i, self.s[self.i:self.i + 40]))

    def string(self):
        i = self.i + 1
        out = []
        s = self.s
        while i < self.n:
            c = s[i]
            if c == "\\":
                nch = s[i + 1]
                out.append({"n": "\n", "t": "\t", "\\": "\\", '"': '"'}.get(nch, nch))
                i += 2
                continue
            if c == '"':
                self.i = i + 1
                return "".join(out)
            out.append(c)
            i += 1
        raise SystemExit("string sin cerrar")

    def number(self):
        i = self.i
        s = self.s
        if s[i] == "-":
            i += 1
        while i < self.n and (s[i].isdigit() or s[i] == "."):
            i += 1
        raw = s[self.i:i]
        self.i = i
        return float(raw) if "." in raw else int(raw)

    def table(self):
        self.i += 1
        arr = []
        dct = {}
        while True:
            self.skip()
            if self.peek() == "}":
                self.i += 1
                return dct if dct else arr
            if self.peek() == "[":
                self.i += 1
                key = self.parse()
                self.skip()
                if self.peek() == "]":
                    self.i += 1
                self.skip()
                if self.peek() == "=":
                    self.i += 1
                dct[key] = self.parse()
            else:
                arr.append(self.parse())


def faction_of(races):
    if not races:
        return "B"
    low = int(races) & 0xFFFFFFFF
    a = bool(low & ALLIANCE)
    h = bool(low & HORDE)
    if a and not h:
        return "A"
    if h and not a:
        return "H"
    return "B"


def load():
    text = open(SRC, encoding="utf-8", errors="replace").read()
    themes = Parser(extract_table(text, "ns.JournalThemes")).parse()
    classes = set(Parser(extract_table(text, "ns.JournalClassQuests")).parse())
    rawq = Parser(extract_table(text, "ns.JournalQuests")).parse()
    rawp = Parser(extract_table(text, "ns.JournalPrereqs")).parse()
    rawn = Parser(extract_table(text, "ns.JournalNpcs")).parse()
    quests = {}
    for qid, row in rawq.items():
        if not isinstance(row, list) or len(row) < 11:
            continue
        starters = row[6] if isinstance(row[6], list) else []
        finishers = row[7] if isinstance(row[7], list) else []
        quests[int(qid)] = {
            "id": int(qid),
            "name": row[0] or ("Misión %d" % qid),
            "level": int(row[1] or 0),
            "req": int(row[2] or 0),
            "fac": faction_of(row[3] or 0),
            "cls": int(row[4] or 0),
            "obj": (row[5] or "").replace("\n", " "),
            "starters": [int(x) for x in starters if isinstance(x, (int, float))],
            "finishers": [int(x) for x in finishers if isinstance(x, (int, float))],
            "xp": int(row[10] or 0),
        }
    pres = {}
    for qid, row in rawp.items():
        if isinstance(row, list):
            pres[int(qid)] = [int(x) for x in row if isinstance(x, (int, float)) and int(x) in quests]
    npcs = {}
    for nid, row in rawn.items():
        if isinstance(row, list) and len(row) >= 5 and isinstance(row[0], str):
            npcs[int(nid)] = {
                "name": row[0],
                "area": int(row[1] or 0),
                "x": float(row[3] or 0),
                "y": float(row[4] or 0),
            }
    zone_of = {}
    banned = set(classes)
    dungeons = []
    for theme in themes:
        if not isinstance(theme, list) or len(theme) < 5:
            continue
        kind, name, ids = theme[0], theme[1], theme[4]
        if not isinstance(ids, list):
            continue
        ids = [int(x) for x in ids if isinstance(x, (int, float)) and int(x) in quests]
        if kind == "zone" and isinstance(theme[2], (int, float)):
            area = int(theme[2])
            for qid in ids:
                zone_of.setdefault(qid, area)
        elif kind == "category" and name in SKIP_CATS:
            banned.update(ids)
        elif kind == "dungeon" and not any(s in (name or "") for s in SKIP_DUNGEON):
            levels = [quests[i]["level"] for i in ids if quests[i]["level"] > 0]
            if not levels:
                continue
            levels.sort()
            dungeons.append((name, levels[len(levels) // 2], ids))
    return quests, pres, npcs, zone_of, banned, dungeons


def lua_str(s):
    s = (s or "").replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ").replace("\r", " ")
    if len(s) > 180:
        s = s[:177].rstrip() + "..."
    return '"%s"' % s


def npc_at(npcs, ids):
    for nid in ids or []:
        n = npcs.get(nid)
        if n:
            return n
    return None


def build(race, chapters, quests, pres, npcs, zone_of, banned, fac):
    def ok(qid):
        q = quests.get(qid)
        if not q or qid in banned or q["cls"]:
            return False
        if fac == "A" and q["fac"] == "H":
            return False
        if fac == "H" and q["fac"] == "A":
            return False
        return True

    def fits(q, lo, hi):
        lvl = q["level"] or q["req"] or 1
        return lo - 1 <= lvl <= hi + 1

    def qarea(qid):
        area = zone_of.get(qid)
        if area:
            return area
        n = npc_at(npcs, quests[qid]["starters"]) or npc_at(npcs, quests[qid]["finishers"])
        return n["area"] if n else None

    pools = []
    claimed = set()
    for title, areas, lo, hi, dungeon in chapters:
        pool = set()
        if dungeon:
            for qid in areas:  # aquí areas es la lista de misiones
                if ok(qid) and qid not in claimed:
                    pool.add(qid)
        else:
            area_set = set(areas)
            for qid in quests:
                if qarea(qid) in area_set and ok(qid) and qid not in claimed and fits(quests[qid], lo, hi):
                    pool.add(qid)
        claimed |= pool
        pools.append([title, pool, dungeon, lo])

    selected = set()
    for _, pool, _, _ in pools:
        selected |= pool

    changed = True
    while changed:
        changed = False
        for _, pool, _, _ in pools:
            for qid in list(pool):
                ql = quests[qid]["level"] or 1
                for p in pres.get(qid, []):
                    if p in selected or not ok(p):
                        continue
                    # No arrastrar una cadena mucho más baja (eso mete la zona de otra raza).
                    if (quests[p]["level"] or 1) < ql - 8:
                        continue
                    pool.add(p)
                    selected.add(p)
                    changed = True

    rev = {}
    for qid in selected:
        for p in pres.get(qid, []):
            if p in selected:
                rev.setdefault(p, []).append(qid)

    def leads(qid, seen):
        if qid in seen:
            return False
        seen.add(qid)
        if quests[qid]["xp"] > 0:
            return True
        return any(leads(d, seen) for d in rev.get(qid, []))

    for pool_row in pools:
        pool_row[1] = {qid for qid in pool_row[1] if leads(qid, set())}
    selected = set()
    for _, pool, _, _ in pools:
        selected |= pool

    def unlocks(qid, turned):
        return sum(1 for d in rev.get(qid, []) if d not in turned)

    steps = []
    turned = set()
    pos = None

    def pos_of(qid, key):
        n = npc_at(npcs, quests[qid][key])
        if not n or (n["x"] == 0 and n["y"] == 0):
            return None
        return (n["area"], n["x"], n["y"])

    def dist(a, b):
        if not a or not b:
            return 800
        if a[0] != b[0]:
            return 400
        return math.hypot(a[1] - b[1], a[2] - b[2])

    for title, pool, dungeon, lo in pools:
        if not pool:
            continue
        maps = []
        if not dungeon:
            for qid in pool:
                area = zone_of.get(qid)
                m = AREA_MAP.get(area or 0)
                if m:
                    maps.append(m)
        map_id = max(set(maps), key=maps.count) if maps else 0
        steps.append(("G", map_id, title, 1 if dungeon else 0))
        guard = 0
        while pool:
            guard += 1
            if guard > 5000:
                break
            ready = []
            for qid in pool:
                need = [p for p in pres.get(qid, []) if p in selected]
                if all(p in turned for p in need):
                    ready.append(qid)
            if not ready:
                qid = min(pool, key=lambda i: (quests[i]["req"], quests[i]["level"], i))
                missing = [p for p in pres.get(qid, []) if p in selected and p not in turned]
                if not missing:
                    ready = [qid]
                else:
                    for m in missing:
                        pool.add(m)
                    continue
            openers = [q for q in ready if unlocks(q, turned) > 0]
            cands = openers or ready

            def rank(qid):
                return (dist(pos, pos_of(qid, "starters")), -unlocks(qid, turned), quests[qid]["level"], qid)

            qid = min(cands, key=rank)
            sid = quests[qid]["starters"][:1]
            batch = [i for i in cands if quests[i]["starters"][:1] == sid]
            if openers:
                batch = [i for i in batch if unlocks(i, turned) > 0] or batch[:1]
            else:
                batch = batch[:4]
            batch.sort(key=lambda i: (quests[i]["level"], i))
            for g in batch:
                steps.append(("A", g))
            for g in batch:
                steps.append(("C", g))
            batch.sort(key=lambda i: (-unlocks(i, turned), quests[i]["level"], i))
            for g in batch:
                steps.append(("T", g))
                turned.add(g)
                pool.discard(g)
            pos = pos_of(batch[-1], "finishers") or pos_of(batch[-1], "starters") or pos
    return steps


def chapters_for(race, quests, zone_of, dungeons):
    # Una sola línea por raza, como hacen las guías de velocidad: no todas las zonas a la vez.
    if race in ("Dwarf", "Gnome"):
        start = ("Dun Morogh", [1, 132], 1, 11, False)
        mid = [
            ("Loch Modan", [38], 10, 18, False),
            ("Los Humedales", [11], 20, 30, False),
        ]
    elif race == "NightElf":
        start = ("Teldrassil", [141, 188], 1, 11, False)
        mid = [
            ("Costa Oscura", [148], 10, 20, False),
            ("Vallefresno", [331], 18, 30, False),
        ]
    elif race == "Human":
        start = ("Bosque de Elwynn", [9, 12], 1, 11, False)
        mid = [
            ("Páramos de Poniente", [40], 10, 20, False),
            ("Montañas Crestagrana", [44], 15, 26, False),
        ]
    elif race == "Scourge":
        start = ("Claros de Tirisfal", [154, 85], 1, 11, False)
        mid = [
            ("Bosque de Argénteos", [130], 10, 20, False),
            ("Laderas de Trabalomas", [267], 20, 32, False),
        ]
    elif race == "Tauren":
        start = ("Mulgore", [220, 215], 1, 11, False)
        mid = [
            ("Los Baldíos", [17], 10, 25, False),
            ("Las Mil Agujas", [400], 25, 35, False),
        ]
    else:
        start = ("Durotar", [363, 14], 1, 11, False)
        mid = [
            ("Los Baldíos", [17], 10, 25, False),
            ("Sierra Espolón", [406], 15, 27, False),
            ("Las Mil Agujas", [400], 25, 35, False),
        ]
    late_a = [
        ("Bosque del Ocaso", [10], 20, 30, False),
        ("Vega de Tuercespina", [33], 30, 45, False),
        ("Marjal Revolcafango", [15], 35, 45, False),
        ("Tanaris", [440], 40, 50, False),
        ("Feralas", [357], 42, 52, False),
        ("Cráter de Un'Goro", [490], 48, 55, False),
        ("Estepas Ardientes", [46], 50, 58, False),
        ("Tierras de la Peste del Oeste", [28], 51, 58, False),
        ("Tierras de la Peste del Este", [139], 53, 60, False),
    ]
    late_h = [
        ("Tierras Altas de Arathi", [45], 30, 40, False),
        ("Vega de Tuercespina", [33], 30, 45, False),
        ("Tanaris", [440], 40, 50, False),
        ("Feralas", [357], 42, 52, False),
        ("Cráter de Un'Goro", [490], 48, 55, False),
        ("Frondavil", [361], 48, 55, False),
        ("Cuna del Invierno", [618], 53, 60, False),
        ("Silithus", [1377], 55, 60, False),
    ]
    horde = race in ("Orc", "Troll", "Tauren", "Scourge")
    chapters = [start] + mid + (late_h if horde else late_a)

    # Zonas propias de Forever: se meten en la línea según el nivel medio de sus misiones.
    known = {a for ch in chapters for a in ch[1]}
    extra = {}
    for qid, area in zone_of.items():
        if area in known or area in AREA_MAP or area in BG_AREAS:
            continue
        q = quests[qid]
        if q["level"] <= 0 or q["cls"]:
            continue
        extra.setdefault(area, []).append(q["level"])
    extras = []
    for area, levels in extra.items():
        if len(levels) < 8:
            continue
        levels.sort()
        med = levels[len(levels) // 2]
        extras.append((med, area, len(levels)))
    extras.sort()
    for med, area, _n in extras:
        names = []
        for qid, a in zone_of.items():
            if a == area:
                names.append((quests[qid]["name"] + " " + quests[qid]["obj"])[:400])
                if len(names) >= 30:
                    break
        blob = " ".join(names)
        title = "Zona de Forever %d" % area
        for word in ("Zephras", "Riverglades", "Hyjal", "Gilneas", "Lordaeron"):
            if word in blob:
                title = word
                break
        chapters.append((title, [area], max(1, med - 2), min(60, med + 2), False))

    fac = "H" if horde else "A"
    dg_chapters = []
    for name, med, ids in dungeons:
        dg_chapters.append((med, ("Mazmorra: " + name, ids, max(1, med - 1), med + 2, True)))
    dg_chapters.sort()
    merged = []
    di = 0
    body = chapters
    # La zona de inicio va primero; el resto y las mazmorras, por nivel.
    head, tail = body[0], body[1:]
    tail = sorted(tail, key=lambda ch: ch[2])
    for ch in [head] + tail:
        while di < len(dg_chapters) and dg_chapters[di][0] <= ch[2]:
            merged.append(dg_chapters[di][1])
            di += 1
        merged.append(ch)
    while di < len(dg_chapters):
        merged.append(dg_chapters[di][1])
        di += 1
    return merged


def main():
    quests, pres, npcs, zone_of, banned, dungeons = load()
    races = {
        "Human": "A", "Dwarf": "A", "Gnome": "A", "NightElf": "A",
        "Orc": "H", "Troll": "H", "Tauren": "H", "Scourge": "H",
    }
    paths = {}
    used = set()
    for race, fac in races.items():
        if race == "Gnome":
            paths[race] = "Dwarf"
            continue
        if race == "Troll":
            paths[race] = "Orc"
            continue
        ch = chapters_for(race, quests, zone_of, dungeons)
        steps = build(race, ch, quests, pres, npcs, zone_of, banned, fac)
        paths[race] = steps
        for st in steps:
            if st[0] != "G":
                used.add(st[1])
        print(race, "pasos", len(steps), "misiones", len({s[1] for s in steps if s[0] != "G"}))

    lines = [
        "-- Generado por Tools/build_guide.py. No editar a mano.",
        "-- Pasos fijos de ruta (aceptar, hacer, entregar), no copiados de guías de pago.",
        "local _, NS = ...",
        "NS.Qinfo = {",
    ]
    for qid in sorted(used):
        q = quests[qid]
        s = npc_at(npcs, q["starters"])
        f = npc_at(npcs, q["finishers"])
        def bit(n):
            if not n:
                return "0,0,0,\"\""
            m = AREA_MAP.get(n["area"], 0)
            return "%d,%.1f,%.1f,%s" % (m, n["x"], n["y"], lua_str(n["name"]))
        obj = q["obj"].replace("$B", " ").replace("$b", " ")
        lines.append(" [%d]={%s,%d,%d,%s,%s,%s}," % (
            qid, lua_str(q["name"]), q["level"], q["req"], lua_str(obj), bit(s), bit(f)))
    lines.append("}")
    lines.append("NS.Qpre = {")
    for qid in sorted(used):
        ps = [p for p in pres.get(qid, []) if p in used]
        if ps:
            lines.append(" [%d]={%s}," % (qid, ",".join(str(p) for p in ps)))
    lines.append("}")
    lines.append("NS.Steps = {}")
    for race, steps in paths.items():
        if isinstance(steps, str):
            lines.append("NS.Steps.%s = NS.Steps.%s" % (race, steps))
            continue
        lines.append("NS.Steps.%s = {" % race)
        for st in steps:
            if st[0] == "G":
                lines.append(" {\"G\",%d,%s,%d}," % (st[1], lua_str(st[2]), st[3]))
            else:
                lines.append(" {\"%s\",%d}," % (st[0], st[1]))
        lines.append("}")
    # Muestra de control: las primeras aceptaciones humanas tienen que ser la cadena de Northshire.
    sample = [s for s in paths["Human"] if s[0] in ("A", "G")][:12]
    print("Muestra Human:")
    for st in sample:
        if st[0] == "G":
            print("  ir a", st[2])
        else:
            print("  aceptar", st[1], quests[st[1]]["name"], "niv", quests[st[1]]["level"])
    text = "\n".join(lines) + "\n"
    open(OUT, "w", encoding="utf-8", newline="\n").write(text)
    print("escrito", OUT, "bytes", len(text.encode("utf-8")))


if __name__ == "__main__":
    main()
