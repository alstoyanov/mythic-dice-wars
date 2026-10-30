# Mythic Dice Wars

A turn-based territory war of dice and gods on a floating isometric island (Godot 4.7). Proof of concept.

- **Design:** [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) (rules, gods, visuals, UI, tech, roadmap)
- **Art and audio still to make:** [docs/art_prompts/](docs/art_prompts/README.md) (one file per kind of asset, every prompt ready to paste)
- **Original brief:** [docs/basic_game_specification.md](docs/basic_game_specification.md)

## Run

Open the folder in Godot 4.7 and press Play, or:

```sh
godot --path .
```

## Assets

`assets/` is generated from the shared art folders (the dice sheets in `Godot/assets/images/dice-wars/dice`, and the god
portraits and realm themes of Tile Shifter, the fonts and sounds of Chasm of Knights):

```sh
python tools/prepare_assets.py          # needs Pillow
```

## Tests

```sh
# rules + AI + balance: plays whole wars between computer players (headless)
godot --headless --path . -s tests/sim_test.gd -- --matches=200

# opens every screen, plays an attack, saves screenshots (needs a window)
godot --path . res://tests/screenshots.tscn -- --out=<folder> [--size=540x960] [--pantheon=norse]
```

## Layout

| Folder | What |
|---|---|
| `core/` | the rules, pure logic: map generation, match state, gods as data, dice odds |
| `ai/` | computer players |
| `session/` | settings and the choices of the New War screens |
| `presentation/` | screens, the isometric map (`map/`), UI helpers shared with Chasm of Knights |
| `assets/` | dice faces, god portraits, realm themes, fonts, sounds |
| `tests/`, `tools/` | simulation, screenshots; the asset script |
