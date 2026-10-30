"""Cuts the generated art (docs/art_prompts) into game assets. Called by prepare_assets.py ("generated").

The generator names files at random, so GENERATED below says which source file is which asset. When new
pictures arrive: add their lines (source path under Godot/assets/images/dice-wars -> target under assets/,
and how to cut it), then run  python tools/prepare_assets.py generated

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
Needs Pillow, numpy and scipy.
"""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

G = "Gemini_Generated_Image_"

# source (relative to Godot/assets/images/dice-wars) -> (target relative to assets/, kind)
GENERATED = {
    # Greek dice tower
    f"dice_towers/greece/{G}711ba711ba711ba7.jpg": ("towers/greek/tower.png", "cutout"),
    f"dice_towers/greece/{G}8apsq68apsq68aps.jpg": ("towers/greek/tray.png", "cutout"),
    f"dice_towers/greece/{G}evbm6wevbm6wevbm.jpg": ("towers/greek/tray_front.png", "cutout"),
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
    alpha = obj.astype(np.float32)
    # The outermost pixels of the object: alpha from how far they are from white (soft edges).
    rim = obj & ~ndimage.binary_erosion(obj, iterations=2)
    lightness = a.min(axis=2).astype(np.float32)
    soft = np.clip((255.0 - lightness) / (255.0 - 200.0), 0.0, 1.0)
    alpha = np.where(rim, np.clip(soft * 1.4, 0.3, 1.0), alpha)
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
    else:
        raise ValueError(kind)


def prepare(source_root: Path, project_assets: Path) -> list[Path]:
    made = []
    for rel, (target, kind) in GENERATED.items():
        src = source_root / rel
        if not src.exists():
            print("missing", src)
            continue
        dst = project_assets / target
        process(src, dst, kind)
        made.append(dst)
    print("generated art:", len(made), "files")
    return made
