"""Copies and converts the art the game uses from the shared asset folders into this project.

    python tools/prepare_assets.py            # everything
    python tools/prepare_assets.py dice       # only the dice faces
    python tools/prepare_assets.py --preview  # also writes tools/_dice_preview.png (a contact sheet)

Sources (outside the project):
  * Dice sheets: Godot/assets/images/dice-wars/dice/dice_<skin>.jpg -- six faces on white, 3 x 2,
    read left to right, top to bottom as the values 1..6.
  * God portraits: the 512 px thumbnails of the Tile Shifter legends
    (games/tile-shifter-godot/content/realms/<realm>/legends/<god>/thumb.jpg), which are the
    paintings in Godot/assets/images/tile-shift, cropped and named per god.
  * Realm interface themes (backgrounds, frames, buttons, title fonts): Tile Shifter's
    assets/themes/<realm>.
  * Interface sounds and the menu font: Chasm of Knights.

Output: assets/dice/<skin>/face_<1..6>.png (256 px, white background removed),
assets/gods/<pantheon>/<god>.jpg, assets/themes/<pantheon>/..., assets/fonts, assets/audio/sfx.
Needs Pillow.
"""
import shutil
import sys
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
GODOT = ROOT.parent.parent  # Documents/Godot
DICE_SRC = GODOT / "assets" / "images" / "dice-wars" / "dice"
TILE_SHIFTER = GODOT / "games" / "tile-shifter-godot"
CHASM = GODOT / "games" / "chasm-of-knights"

FACE_SIZE = 256
WHITE = 236  # a pixel whose channels are all above this counts as background

# skin id -> sheet file name (some files are spelled differently from the ids)
DICE_SKINS = {
    "aztec": "dice_atztec.jpg", "celtic": "dice_celtic.jpg", "chinese": "dice_china.jpg",
    "egyptian": "dice_egypt.jpg", "greek": "dice_greek.jpg", "inca": "dice_inca.jpg",
    "inuit": "dice_inuit.jpg", "japanese": "dice_japan.jpg", "mayan": "dice_mayan.jpg",
    "mesopotamian": "dice_messopotamia.jpg", "norse": "dice_norse.jpg", "persian": "dice_persian.jpg",
    "polynesian": "dice_polynesian.jpg", "slavic": "dice_slavic.jpg",
}

# pantheon id -> (Tile Shifter realm folder, Tile Shifter theme folder)
PANTHEONS = {
    "greek": ("greek", "greek"),
    "norse": ("norse", "norse"),
    "egyptian": ("egyptian", "egypt"),
    "chinese": ("chinese", "chinese"),
    "mayan": ("mayan", "mayan"),
    "mesopotamian": ("mesopotamian", "mesopotamian"),
}

SFX = ["click_003", "tick_002", "back_002", "maximize_006", "toggle_002", "win", "lose", "place", "pick",
       "crumble_1", "crumble_2", "special"]


def _is_white(px) -> bool:
    return px[0] > WHITE and px[1] > WHITE and px[2] > WHITE


def _face_box(img: Image.Image, cell: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    """Bounding box of the non-white pixels inside `cell` (sampled every 2 px, then padded)."""
    x0, y0, x1, y1 = cell
    px = img.load()
    min_x, min_y, max_x, max_y = x1, y1, x0, y0
    for y in range(y0, y1, 2):
        for x in range(x0, x1, 2):
            if not _is_white(px[x, y]):
                min_x, min_y = min(min_x, x), min(min_y, y)
                max_x, max_y = max(max_x, x), max(max_y, y)
    return max(x0, min_x - 2), max(y0, min_y - 2), min(x1, max_x + 3), min(y1, max_y + 3)


def _clear_background(face: Image.Image) -> Image.Image:
    """Makes the white around the rounded die transparent (flood fill from the edges), with a soft rim."""
    face = face.convert("RGBA")
    w, h = face.size
    px = face.load()
    seen = bytearray(w * h)
    todo = deque()
    for x in range(w):
        todo.extend([(x, 0), (x, h - 1)])
    for y in range(h):
        todo.extend([(0, y), (w - 1, y)])
    while todo:
        x, y = todo.popleft()
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        r, g, b, _a = px[x, y]
        lightness = min(r, g, b)
        if lightness <= WHITE - 30:
            continue
        # near-white: fade out (pure white -> fully transparent)
        px[x, y] = (r, g, b, 0 if lightness > WHITE else int(255 * (WHITE - lightness) / 30))
        if lightness > WHITE - 8:
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                    todo.append((nx, ny))
    return face


def prepare_dice() -> list[Path]:
    made = []
    for skin, file_name in DICE_SKINS.items():
        src = DICE_SRC / file_name
        if not src.exists():
            print("missing", src)
            continue
        sheet = Image.open(src).convert("RGB")
        w, h = sheet.size
        out_dir = ROOT / "assets" / "dice" / skin
        out_dir.mkdir(parents=True, exist_ok=True)
        for i in range(6):
            col, row = i % 3, i // 3
            cell = (col * w // 3, row * h // 2, (col + 1) * w // 3, (row + 1) * h // 2)
            box = _face_box(sheet, cell)
            face = sheet.crop(box)
            side = max(face.size)  # square, the die centred
            square = Image.new("RGB", (side, side), (255, 255, 255))
            square.paste(face, ((side - face.size[0]) // 2, (side - face.size[1]) // 2))
            square = square.resize((FACE_SIZE, FACE_SIZE), Image.LANCZOS)
            out = out_dir / f"face_{i + 1}.png"
            _clear_background(square).save(out, optimize=True)
            made.append(out)
        print("dice", skin)
    return made


def prepare_gods() -> None:
    for pantheon, (realm, _theme) in PANTHEONS.items():
        legends = TILE_SHIFTER / "content" / "realms" / realm / "legends"
        out_dir = ROOT / "assets" / "gods" / pantheon
        out_dir.mkdir(parents=True, exist_ok=True)
        for god_dir in sorted(p for p in legends.iterdir() if p.is_dir()):
            thumb = god_dir / "thumb.jpg"
            if thumb.exists():
                shutil.copyfile(thumb, out_dir / f"{god_dir.name}.jpg")
        print("gods", pantheon)


def prepare_themes() -> None:
    for pantheon, (_realm, theme) in PANTHEONS.items():
        src = TILE_SHIFTER / "assets" / "themes" / theme
        out_dir = ROOT / "assets" / "themes" / pantheon
        out_dir.mkdir(parents=True, exist_ok=True)
        for f in src.iterdir():
            if f.suffix.lower() in (".jpg", ".png", ".ttf", ".json", ".txt"):
                shutil.copyfile(f, out_dir / f.name)
        print("theme", pantheon)


def prepare_shared() -> None:
    fonts = ROOT / "assets" / "fonts"
    fonts.mkdir(parents=True, exist_ok=True)
    for name in ["PTSerif-Regular.ttf", "PTSerif-Bold.ttf", "OFL-PTSerif.txt"]:
        shutil.copyfile(CHASM / "presentation" / "shared" / "fonts" / name, fonts / name)
    sfx = ROOT / "assets" / "audio" / "sfx"
    sfx.mkdir(parents=True, exist_ok=True)
    src = CHASM / "presentation" / "shared" / "audio" / "sfx"
    for name in SFX:
        if (src / f"{name}.ogg").exists():
            shutil.copyfile(src / f"{name}.ogg", sfx / f"{name}.ogg")
    for name in ["CREDITS.txt", "LICENSE-Kenney-InterfaceSounds.txt"]:
        if (src / name).exists():
            shutil.copyfile(src / name, sfx / name)
    print("fonts and sounds")


def preview(faces: list[Path]) -> None:
    skins = sorted({p.parent.name for p in faces})
    cell = 96
    sheet = Image.new("RGBA", (cell * 6, cell * len(skins)), (40, 40, 48, 255))
    for r, skin in enumerate(skins):
        for c in range(6):
            face = Image.open(ROOT / "assets" / "dice" / skin / f"face_{c + 1}.png").resize((cell, cell))
            sheet.alpha_composite(face, (c * cell, r * cell))
    out = ROOT / "tools" / "_dice_preview.png"
    sheet.save(out)
    print("preview", out)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    what = set(args) or {"dice", "gods", "themes", "shared"}
    faces = prepare_dice() if "dice" in what else []
    if "gods" in what:
        prepare_gods()
    if "themes" in what:
        prepare_themes()
    if "shared" in what:
        prepare_shared()
    if "--preview" in sys.argv and faces:
        preview(faces)
