# Jefes y botín de las mazmorras de la ruta. El cliente de Forever no tiene diario.
# El resultado queda dentro de LevelGuide: al jugar no se lee ningún otro addon.
import os
import build_guide as bg

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "JournalForever"))
OUT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "Bosses.lua"))

# Nombre en Data.lua -> nombre en el bestiario
ALIAS = {
    "Temple of Atal'Hakkar": "The Temple of Atal'Hakkar",
    "Excavation Site": "Excavation Site: Wetlands",
}


def lua_str(s):
    return '"' + (s or "").replace("\\", "\\\\").replace('"', '\\"') + '"'


def load(path, marker):
    text = open(path, encoding="utf-8", errors="replace").read()
    return bg.Parser(bg.extract_table(text, marker)).parse()


def main():
    themes = load(os.path.join(ROOT, "BestiaryData.lua"), "ns.BestiaryThemes")
    creatures = load(os.path.join(ROOT, "BestiaryData.lua"), "ns.Creatures")
    loot = load(os.path.join(ROOT, "BestiaryData.lua"), "ns.CreatureBossLoot")
    by_name = {}
    for theme in themes:
        if isinstance(theme, list) and theme[0] == "dungeon" and isinstance(theme[4], list):
            by_name[theme[1]] = [int(x) for x in theme[4] if isinstance(x, (int, float))]

    wanted = [
        "Ragefire Chasm", "Wailing Caverns", "The Deadmines", "Ruins of Lordaeron",
        "Shadowfang Keep", "Blackfathom Deeps", "The Stockade", "Razorfen Kraul",
        "Gnomeregan", "Excavation Site", "City of Dalaran", "Scarlet Monastery",
        "Razorfen Downs", "Uldaman", "Zul'Farrak", "Maraudon", "Temple of Atal'Hakkar",
        "Blackrock Depths", "Blackrock Spire", "Dire Maul", "Scholomance", "Stratholme",
        "Hall of Thanes", "The Hall of Thanes",
    ]
    lines = [
        "-- Jefes y objetos. Forever no tiene diario de encuentros; va en el propio addon.",
        "local _, NS = ...",
        "NS.Bosses = {",
    ]
    for name in wanted:
        ids = by_name.get(name) or by_name.get(ALIAS.get(name)) or []
        parsed = []
        for nid in ids:
            c = creatures.get(nid)
            if not isinstance(c, list) or len(c) < 4:
                continue
            items = [int(i) for i in (loot.get(nid) or []) if isinstance(i, (int, float))][:16]
            rank = int(c[3] or 0)
            display = int(c[5] or 0) if len(c) > 5 else 0
            if rank == 3 or items:
                parsed.append((rank != 3, nid, c[0], display, items))
        parsed.sort()
        if not parsed:
            continue
        key = "Hall of Thanes" if name == "The Hall of Thanes" else name
        lines.append(" [%s] = {" % lua_str(key))
        for _rank, nid, cname, display, items in parsed[:16]:
            lines.append("  {%d,%s,%d,{%s}}," % (nid, lua_str(cname), display, ",".join(str(i) for i in items)))
        lines.append(" },")
    lines.append("}")
    text = "\n".join(lines) + "\n"
    open(OUT, "w", encoding="utf-8", newline="\n").write(text)
    print("bytes", len(text.encode("utf-8")))


if __name__ == "__main__":
    main()
