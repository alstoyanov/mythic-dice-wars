# Art and audio prompts

Every picture and sound the game still needs, one file per kind of asset. **Every prompt is complete**: copy the block
and paste it as it is, with nothing to fill in. For the reasons behind them, see [GAME_DESIGN.md](../GAME_DESIGN.md) §8
(visuals) and §10 (audio). The map itself is drawn in code (flat colours), so it needs no tiles or props.

| File | What | Prompts |
|---|---|---|
| [01_dice_towers.md](01_dice_towers.md) | battle dice towers (tower, tray, tray front): all 7 done; the rules for a new one | 21 |
| [02_dice_skins.md](02_dice_skins.md) | dice sheets: all done; the rules for a new one | 0 |
| [03_realm_themes.md](03_realm_themes.md) | menu backgrounds, frames and buttons for 8 new pantheons | 48 |
| [04_hud_icons.md](04_hud_icons.md) | war-screen icons | 12 |
| [05_effects.md](05_effects.md) | effect sprite sheets | 5 |
| [06_key_art.md](06_key_art.md) | key art, app icon, logo: pictures done, the logo still to make | 3 |
| [07_music.md](07_music.md) | menu and war music per pantheon, stings (Suno) | 14 tracks |
| [08_sound_effects.md](08_sound_effects.md) | sound effects, awakening voices | 21 |

## Done and in the game

- **Dice towers** for all 7 pantheons (tower, tray, tray front), in
  `Godot/assets/images/dice-wars/dice_towers/<greece|norse|egypt|china|maya|mesopotamia|yoruba>/` as `tower.jpg`,
  `tray.jpg` and `tray_front.jpg`. The Norse and Mayan trays were redone straight on; their fronts are cut from
  the tray picture itself, so they fit exactly and no `tray_front.jpg` is needed (`FRONT_FROM_TRAY` in
  `tools/generated_art.py`; the replaced pictures are in `dice_towers/_replaced/`). The Mesopotamian front adds a
  ledge the tray does not have, so the game leaves it out (`TOWER_LAYOUT`).
- **Key art and app icon:** `Godot/assets/images/dice-wars/key/` (`key_art.jpg`, `key_art_portrait.jpg`, `icon.jpg`).
  The key art fills the splash screen; the icon (cut out of its background, rounded corners transparent) is the
  window and project icon.
- **Shared:** all 12 HUD icons; the effects (dust, lightning, motes, ward dome, crumble). The lightning sheet has
  two broken frames, so regenerating it on black (see 05) would help.

New pictures are cut into game assets by `python tools/prepare_assets.py generated`. Rename each new file when you
sort it into its folder (the generator's names are random), then add its line to `GENERATED` in
`tools/generated_art.py` (a new pantheon's tower: one line in `TOWER_FOLDERS`).

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
