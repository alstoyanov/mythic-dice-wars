# Art and audio prompts

Every picture and sound the game still needs, one file per kind of asset. **Every prompt is complete**: copy the block
and paste it as it is, with nothing to fill in. For the reasons behind them, see [GAME_DESIGN.md](../GAME_DESIGN.md) §8
(visuals) and §10 (audio).

| File | What | Prompts |
|---|---|---|
| [01_terrain_tiles.md](01_terrain_tiles.md) | ground tiles (diamond and hexagon) and cliffs, per realm | 70 |
| [02_props.md](02_props.md) | temples, trees, statues… standing on the map, per realm | 84 |
| [03_dice_towers.md](03_dice_towers.md) | battle dice towers (tower, tray, tray front), per pantheon | 21 |
| [04_dice_skins.md](04_dice_skins.md) | dice sheets: all done; the rules for a new one | 0 |
| [05_realm_themes.md](05_realm_themes.md) | menu backgrounds, frames and buttons for 8 new pantheons | 48 |
| [06_hud_icons.md](06_hud_icons.md) | war-screen icons | 12 |
| [07_effects.md](07_effects.md) | effect sprite sheets | 6 |
| [08_key_art.md](08_key_art.md) | key art, app icon, logo | 3 |
| [09_music.md](09_music.md) | menu and war music per pantheon, stings (Suno) | 14 tracks |
| [10_sound_effects.md](10_sound_effects.md) | sound effects, awakening voices | 21 |

## What already exists (do not regenerate)

- **Dice skins** for 15 pantheons: `Godot/assets/images/dice-wars/dice/` (cut into faces by `tools/prepare_assets.py`).
- **God portraits** for Greek, Norse, Egyptian, Chinese, Mayan, Mesopotamian and Yoruba (Tile Shifter).
- **Interface themes** for the same 7 realms (Tile Shifter).
- **God portrait prompts** for Aztec, Celtic, Inca, Inuit, Japanese, Persian, Polynesian, Slavic, Roman, Finnish,
  Hawaiian, Australian and Indian gods: `tile-shifter-godot/content/realms/_future/<realm>/image_prompts.md`. Generate
  those once, and both games use them.

## How to generate the pictures

- Use Google Nano Banana / Gemini image, like the other Mytholore art.
- Start **one conversation per realm** (or per set, where a file says so) and paste that section's prompts **in order**.
  The later prompts end with *"Match the style, colours and light of the earlier pictures in this conversation"*, so
  the set belongs together.
- Map assets are drawn in **2:1 isometric** view (a square on the ground becomes a diamond twice as wide as it is tall),
  lit from the **top left**, on a **plain white background**, so the white can be cut away the same way
  `tools/prepare_assets.py` already does for the dice.
- Each file says the size to generate and where to save the result.
