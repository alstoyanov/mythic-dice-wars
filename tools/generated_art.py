"""Cuts the generated art (docs/art_prompts) into game assets. Called by prepare_assets.py ("generated").

The generator names files at random: rename them when sorting them into the source folders (for example
dice_towers/norse/tower.jpg), and GENERATED below says which source file becomes which asset. When new
pictures arrive: add their lines (source path under Godot/assets/images/dice-wars -> target under assets/,
and how to cut it), then run  python tools/prepare_assets.py generated
A new pantheon's dice tower needs only its folder in TOWER_FOLDERS (and, if its pieces fit differently,
a line in TOWER_LAYOUT; if its tray is seen straight on, its front can be cut from the tray: FRONT_FROM_TRAY).

Kinds of cutting:
  cutout                   an object on white: the white around it removed (strictly, so white marble
                           stays), only the largest piece kept (stray bits dropped)
  icon                     like cutout, then centred on a square
  fx:<frames to skip>      a row of 8 animation frames on white (smoke, debris): white turned into
                           transparency, frames sliced, the listed frames left out, saved as one strip
                           of square frames
  glow:<frames to skip>    the same for light painted on white (lightning, sparks, a dome of light): the
                           colour is kept and strengthened, as the white core cannot be told from the
                           background (better: generate glows on black, see docs/art_prompts/05_effects.md)
  cut:<frames to skip>     the same for a solid object in each frame (a white flag): cut out frame by frame
  light:<frames to skip>   light painted on BLACK (the way glows should be generated): black turned into
                           transparency, so the light keeps its full brightness
  front:<share>            a tray's front wall cut from the tray itself (cutout, then everything above
                           <share> of its height made transparent, the size kept): it fits the tray exactly
  picture:<longest side>   a whole painting (key art): scaled down and saved as it is (JPEG for .jpg)
  appicon:<x0,y0,x1,y1,r>:<side>
                           the app icon: the generator paints the rounded square on a background, so the
                           square (box x0..x1, y0..y1 in the source, corner radius r) is cut out, its
                           corners made transparent, and saved at side × side pixels
Needs Pillow, numpy and scipy.
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

G = "Gemini_Generated_Image_"

# The dice towers: source folder (Godot/assets/images/dice-wars/dice_towers/<folder>) -> pantheon id.
# Each folder holds tower.jpg, tray.jpg and tray_front.jpg (not needed where FRONT_FROM_TRAY cuts the front).
TOWER_FOLDERS = {"greece": "greek", "norse": "norse", "egypt": "egyptian", "china": "chinese", "maya": "mayan",
                 "mesopotamia": "mesopotamian", "yoruba": "yoruba"}

# How each tower's pieces fit together in the battle screen, written to towers/<pantheon>/layout.json
# (missing keys: the defaults in Looks.tower). front: draw tray_front over the dice (off when it does not
# match the tray's shape, e.g. a ledge the tray lacks); floor: where the dice row sits, as a share
# of the tray's height; reach: how far the row spreads from the middle, as a share of the tray's width;
# tray_width: the tray's size against the standard (taller trays drawn a little smaller).
TOWER_LAYOUT = {
    "norse": {"floor": 0.5, "reach": 0.27},
    "mayan": {"floor": 0.48, "reach": 0.26},
    "chinese": {"tray_width": 0.92, "floor": 0.4, "reach": 0.31},
    "yoruba": {"tray_width": 0.92, "floor": 0.4, "reach": 0.31},
    "egyptian": {"floor": 0.43, "reach": 0.31},
    "mesopotamian": {"front": False, "floor": 0.36, "reach": 0.31},
}

# Trays seen straight on whose front wall is cut from the tray picture instead of a separate tray_front.jpg
# (pantheon -> where the front rim begins, as a share of the cut-out tray's height).
FRONT_FROM_TRAY = {"norse": 0.62, "mayan": 0.59}

# source (relative to Godot/assets/images/dice-wars) -> (target relative to assets/, kind)
GENERATED = {
    # Dice towers, one per pantheon
    **{f"dice_towers/{folder}/{part}.jpg": (f"towers/{pantheon}/{part}.png", "cutout")
       for folder, pantheon in TOWER_FOLDERS.items() for part in ("tower", "tray", "tray_front")
       if not (part == "tray_front" and pantheon in FRONT_FROM_TRAY)},
    **{f"dice_towers/{folder}/tray.jpg#front": (f"towers/{pantheon}/tray_front.png", f"front:{FRONT_FROM_TRAY[pantheon]}")
       for folder, pantheon in TOWER_FOLDERS.items() if pantheon in FRONT_FROM_TRAY},
    # Key art (splash screen, store pages) and the app icon
    "key/key_art.jpg": ("branding/key_art.jpg", "picture:1920"),
    "key/key_art_portrait.jpg": ("branding/key_art_portrait.jpg", "picture:1920"),
    "key/icon.jpg": ("branding/icon.png", "appicon:181,183,1867,1869,360:512"),
    "key/icon.jpg#small": ("../icon.png", "appicon:181,183,1867,1869,360:256"),  # the project / window icon
    # HUD icons (shared)
    f"hud_icons/{G}a2z6uda2z6uda2z6.jpg": ("ui/icons/reinforce.png", "icon"),
    f"hud_icons/{G}d0adu2d0adu2d0ad.jpg": ("ui/icons/defence.png", "icon"),
    f"hud_icons/{G}i5glz3i5glz3i5gl.jpg": ("ui/icons/reserve.png", "icon"),
    f"hud_icons/{G}k5g6jvk5g6jvk5g6.jpg": ("ui/icons/favour.png", "icon"),
    f"hud_icons/{G}os0k6jos0k6jos0k.jpg": ("ui/icons/bless.png", "icon"),
    f"hud_icons/{G}pnqbjxpnqbjxpnqb.jpg": ("ui/icons/crown.png", "icon"),
    f"hud_icons/{G}pqxh00pqxh00pqxh.jpg": ("ui/icons/asleep.png", "icon"),
    f"hud_icons/{G}qjwnnnqjwnnnqjwn.jpg": ("ui/icons/attack.png", "icon"),
    f"hud_icons/{G}r6vjr3r6vjr3r6vj.jpg": ("ui/icons/ward.png", "icon"),
    f"hud_icons/{G}ruafexruafexruaf.jpg": ("ui/icons/end_turn.png", "icon"),
    f"hud_icons/{G}vgqjvgvgqjvgvgqj.jpg": ("ui/icons/smite.png", "icon"),
    f"hud_icons/{G}wbntrfwbntrfwbnt.jpg": ("ui/icons/awaken.png", "icon"),
    # Effects (shared)
    f"effects/{G}4yw2cu4yw2cu4yw2.jpg": ("vfx/ward_dome.png", "glow:"),
    f"effects/{G}5qmyk15qmyk15qmy.jpg": ("vfx/dust.png", "fx:"),
    # effects/...6p3pvf (the white flag) is not used: white on white cannot be cut out; the game draws its pennants
    f"effects/{G}ar6w3var6w3var6w.jpg": ("vfx/lightning.png", "glow:0,1,2"),  # frames 2-3 are broken (grey boxes), frame 1 catches their edge
    f"effects/{G}mn05l6mn05l6mn05.jpg": ("vfx/motes.png", "glow:"),
    f"effects/{G}sx5l2qsx5l2qsx5l.jpg": ("vfx/crumble.png", "fx:"),
}

SIZES = {"cutout": 512, "icon": 128, "fx": 192}


def _rgb(img: Image.Image) -> np.ndarray:
    return np.asarray(img.convert("RGB")).astype(np.int16)


def _shape_mask(a: np.ndarray, white: int = 244) -> np.ndarray:
    return a.min(axis=2) < white


def _cutout(img: Image.Image, white: int = 246) -> Image.Image:
    """Removes the white around an object: only near-white pixels connected to the picture's edge go, so
    white marble inside the object stays. The 2-pixel rim is softened (white turned into transparency),
    and only the largest piece is kept."""
    a = _rgb(img)
    light = a.min(axis=2) >= white
    labels, _n = ndimage.label(light)
    edge = np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))
    bg = np.isin(labels, edge[edge > 0])
    obj = ~bg
    lab, n = ndimage.label(obj)
    if n > 1:
        sizes = ndimage.sum(obj, lab, range(1, n + 1))
        obj = lab == (int(np.argmax(sizes)) + 1)
        obj = ndimage.binary_fill_holes(obj)
    # Holes: the background seen through an opening (a tower's window) is enclosed, so it survived the
    # step above. It is told apart from white marble by being large, flat and almost pure white.
    holes = np.zeros(light.shape, dtype=bool)
    inner, n_inner = ndimage.label(light & obj)
    if n_inner:
        sizes = ndimage.sum(np.ones(light.shape), inner, range(1, n_inner + 1))
        for i in np.nonzero(sizes >= 120)[0] + 1:
            px = a[inner == i]
            if px.mean() >= 248 and px.std(axis=0).max() < 6:
                holes |= inner == i
    obj &= ~holes
    alpha = obj.astype(np.float32)
    # The outermost pixels of the object: alpha from how far they are from white (soft edges). Along the
    # outline a little is always kept (the object's edge must not fray); around a hole the near-white edge
    # fades out completely, or it would draw a light frame round the opening.
    rim = obj & ~ndimage.binary_erosion(obj, iterations=2)
    hole_rim = rim & ndimage.binary_dilation(holes, iterations=3)
    lightness = a.min(axis=2).astype(np.float32)
    soft = np.clip((255.0 - lightness) / (255.0 - 200.0), 0.0, 1.0)
    alpha = np.where(rim, np.clip(soft * 1.4, 0.3, 1.0), alpha)
    alpha = np.where(hole_rim, np.clip(soft * 1.4, 0.0, 1.0), alpha)
    rgba = np.dstack([a.astype(np.uint8), (alpha * 255).astype(np.uint8)])
    out = Image.fromarray(rgba, "RGBA")
    return out.crop(out.getbbox())


def _cutout_bbox(img: Image.Image) -> tuple[int, int, int, int]:
    """Where _cutout's crop lies in the original picture (to keep a frame's object in place)."""
    a = _rgb(img)
    ys, xs = np.nonzero(a.min(axis=2) < 236)
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def _white_to_alpha(img: Image.Image, glow: bool = False) -> Image.Image:
    """Turns white into transparency (smoke painted on white). `glow`: light painted on white; its colour
    is kept, lifted towards white, and made more opaque, so it still shines on a dark map."""
    a = np.asarray(img.convert("RGB")).astype(np.float32) / 255.0
    alpha = (1.0 - a).max(axis=2)
    alpha = np.clip((alpha - 0.08) / 0.92, 0.0, 1.0)  # JPEG noise and the faint frame borders in the white
    safe = np.maximum(alpha, 1e-4)[..., None]
    rgb = np.clip((a - (1.0 - safe)) / safe, 0.0, 1.0)
    if glow:
        rgb = rgb * 0.45 + 0.55
        alpha = np.clip(alpha * 2.6, 0.0, 1.0)
    return Image.fromarray(np.dstack([(rgb * 255).astype(np.uint8), (alpha * 255).astype(np.uint8)]), "RGBA")


def _black_to_alpha(img: Image.Image) -> Image.Image:
    """Turns black into transparency (light painted on black): alpha from the brightest channel."""
    a = np.asarray(img.convert("RGB")).astype(np.float32) / 255.0
    alpha = np.clip((a.max(axis=2) - 0.06) / 0.94, 0.0, 1.0)
    rgb = np.clip(a / np.maximum(a.max(axis=2, keepdims=True), 1e-4), 0.0, 1.0)
    return Image.fromarray(np.dstack([(rgb * 255).astype(np.uint8), (alpha * 255).astype(np.uint8)]), "RGBA")


def _clear_edges(frame: Image.Image, band: float = 0.05) -> Image.Image:
    """Fades out a frame's outer edge, where the generator's faint cell borders lie."""
    a = np.asarray(frame).copy()
    h, w = a.shape[:2]
    ramp_y = np.clip(np.minimum(np.arange(h), h - 1 - np.arange(h)) / (h * band), 0.0, 1.0)
    ramp_x = np.clip(np.minimum(np.arange(w), w - 1 - np.arange(w)) / (w * band), 0.0, 1.0)
    a[..., 3] = (a[..., 3] * np.minimum.outer(ramp_y, ramp_x)).astype(np.uint8)
    return Image.fromarray(a, "RGBA")


def _fit(img: Image.Image, longest: int) -> Image.Image:
    w, h = img.size
    k = longest / max(w, h)
    return img.resize((max(1, round(w * k)), max(1, round(h * k))), Image.LANCZOS)


def process(src: Path, dst: Path, kind: str) -> None:
    img = Image.open(src)
    dst.parent.mkdir(parents=True, exist_ok=True)
    if kind == "cutout":
        small = _fit(img.convert("RGB"), 1024)
        out = _cutout(small)
        _fit(out, SIZES["cutout"]).save(dst, optimize=True)
    elif kind.startswith("front:"):
        out = _cutout(_fit(img.convert("RGB"), 1024))
        a = np.asarray(out).copy()
        cut = float(kind.split(":")[1]) * a.shape[0]
        # Soft over 3 pixels, so the rim's edge is not a hard line across the dice.
        keep = np.clip((np.arange(a.shape[0]) - cut) / 3.0 + 0.5, 0.0, 1.0)
        a[..., 3] = (a[..., 3] * keep[:, None]).astype(np.uint8)
        _fit(Image.fromarray(a, "RGBA"), SIZES["cutout"]).save(dst, optimize=True)
    elif kind == "icon":
        out = _cutout(_fit(img.convert("RGB"), 1024), white=236)
        side = max(out.size)
        square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        square.paste(out, ((side - out.size[0]) // 2, (side - out.size[1]) // 2))
        square.resize((SIZES["icon"], SIZES["icon"]), Image.LANCZOS).save(dst, optimize=True)
    elif kind.split(":")[0] in ("fx", "glow", "cut", "light"):
        mode, rest = kind.split(":")
        skip = {int(x) for x in rest.split(",") if x != ""}
        rgb = img.convert("RGB")
        fw = rgb.size[0] / 8.0
        margin = 16  # the generator draws faint frame borders: stay clear of them
        cells = [rgb.crop((round(i * fw) + margin, margin, round((i + 1) * fw) - margin, rgb.size[1] - margin))
                 for i in range(8) if i not in skip]
        s = SIZES["fx"]
        strip = Image.new("RGBA", (s * len(cells), s), (0, 0, 0, 0))
        for i, cell in enumerate(cells):
            if mode == "cut":
                obj = _cutout(cell, white=236)
                frame = Image.new("RGBA", cell.size, (0, 0, 0, 0))
                bbox = _cutout_bbox(cell)
                frame.paste(obj, bbox[:2])
            elif mode == "light":
                frame = _clear_edges(_black_to_alpha(cell))
            else:
                frame = _white_to_alpha(cell, glow=mode == "glow")
                frame = _clear_edges(frame)
            strip.paste(frame.resize((s, s), Image.LANCZOS), (i * s, 0))
        strip.save(dst, optimize=True)
    elif kind.startswith("picture:"):
        out = _fit(img.convert("RGB"), int(kind.split(":")[1]))
        if dst.suffix == ".jpg":
            out.save(dst, quality=88, optimize=True)
        else:
            out.save(dst, optimize=True)
    elif kind.startswith("appicon:"):
        _, box, side = kind.split(":")
        x0, y0, x1, y1, r = (int(v) for v in box.split(","))
        square = img.convert("RGB").crop((x0, y0, x1, y1))
        # The rounded corners, drawn 4× larger and scaled down for a smooth edge.
        big = Image.new("L", (square.size[0] * 4, square.size[1] * 4), 0)
        ImageDraw.Draw(big).rounded_rectangle((0, 0, big.size[0] - 1, big.size[1] - 1), radius=r * 4, fill=255)
        square.putalpha(big.resize(square.size, Image.LANCZOS))
        square.resize((int(side), int(side)), Image.LANCZOS).save(dst, optimize=True)
    else:
        raise ValueError(kind)


def prepare(source_root: Path, project_assets: Path) -> list[Path]:
    made = []
    for rel, (target, kind) in GENERATED.items():
        src = source_root / rel.split("#")[0]  # "#..." tells apart two assets made from one source
        if not src.exists():
            print("missing", src)
            continue
        dst = project_assets / target
        process(src, dst, kind)
        made.append(dst)
    for pantheon, layout in TOWER_LAYOUT.items():
        dst = project_assets / "towers" / pantheon / "layout.json"
        if dst.parent.exists():
            dst.write_text(json.dumps(layout, indent=1) + "\n", encoding="utf-8")
            made.append(dst)
    print("generated art:", len(made), "files")
    return made
