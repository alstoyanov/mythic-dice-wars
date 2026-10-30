"""Copies the gods' stories from Tile Shifter into core/god_lore.gd (for the Book of the Gods).

Tile Shifter (../tile-shifter-godot) keeps, for every god, a legend (content/realms/<pantheon>/legends/<id>/
legend.tres: a short description, the story, a "did you know"), and for every realm an introduction
(realm.tres). This copies those texts for the gods in core/god_catalog.gd, so the game carries them itself.
Run it again after the texts or the catalog change:

    python tools/import_lore.py [path to tile-shifter-godot]
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "tile-shifter-godot"
OUT = ROOT / "core" / "god_lore.gd"

FIELD = re.compile(r'^(\w+) = "((?:[^"\\]|\\.)*)"\s*$', re.MULTILINE)
FLAG = re.compile(r'^(\w+) = (true|false)\s*$', re.MULTILINE)


def fields(text: str) -> dict:
    out = {k: json.loads('"%s"' % v) for k, v in FIELD.findall(text)}
    out.update({k: v == "true" for k, v in FLAG.findall(text)})
    return out


def resource_section(path: Path) -> str:
    """The main [resource] part of a .tres (sub-resources come before it)."""
    text = path.read_text(encoding="utf-8")
    return text[text.index("\n[resource]"):]


def gd(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def main() -> None:
    catalog = (ROOT / "core" / "god_catalog.gd").read_text(encoding="utf-8")
    gods = re.findall(r'\{"id": "(\w+)", "pantheon": "(\w+)"', catalog)
    pantheons = list(dict.fromkeys(p for _, p in gods))
    lines = [
        "class_name GodLore",
        "extends RefCounted",
        "## The stories of the gods and their realms, for the Book of the Gods. Written by tools/import_lore.py",
        "## from Tile Shifter's legends (do not edit here: edit them there and run the tool again).",
        "",
        "## pantheon id -> {name, subtitle, about, living (a living tradition: still practised today)}",
        "const REALMS := {",
    ]
    for p in pantheons:
        f = fields(resource_section(SOURCE / "content" / "realms" / p / "realm.tres"))
        lines.append('\t"%s": {"name": %s, "subtitle": %s, "about": %s, "living": %s},' % (
            p, gd(f["display_name"]), gd(f.get("subtitle", "")), gd(f.get("about", "")),
            "true" if f.get("is_living_tradition") else "false"))
    lines += ["}", "", "## god id -> {featured (a few words), lore (the story), did_you_know}", "const GODS := {"]
    missing = []
    for gid, p in gods:
        path = SOURCE / "content" / "realms" / p / "legends" / gid / "legend.tres"
        if not path.exists():
            missing.append(gid)
            continue
        f = fields(resource_section(path))
        lines.append('\t"%s": {"featured": %s, "lore": %s, "did_you_know": %s},' % (
            gid, gd(f.get("featured", "")), gd(f.get("lore", "")), gd(f.get("did_you_know", ""))))
    lines += ["}", "", "", "static func realm(pantheon_id: String) -> Dictionary:",
              "\treturn REALMS.get(pantheon_id, {})", "", "",
              "static func god(god_id: String) -> Dictionary:", "\treturn GODS.get(god_id, {})", ""]
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print("wrote", OUT, "-", len(gods) - len(missing), "gods", ("missing: " + ", ".join(missing)) if missing else "")


if __name__ == "__main__":
    main()
