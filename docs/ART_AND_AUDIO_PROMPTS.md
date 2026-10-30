# Mythic Dice Wars — art and audio prompts

Every picture and sound the game still needs, with prompts ready to paste. For the reasons behind them, see
[GAME_DESIGN.md](GAME_DESIGN.md) §8 (visuals) and §10 (audio).

**What already exists (do not regenerate):**
- **Dice skins** for 14 pantheons: `Godot/assets/images/dice-wars/dice/` (cut into faces by `tools/prepare_assets.py`).
- **God portraits** for Greek, Norse, Egyptian, Chinese, Mayan, Mesopotamian and Yoruba (Tile Shifter).
- **Interface themes** (backgrounds, frames, buttons, title fonts) for the same 7 realms (Tile Shifter).
- **Portrait prompts** for Aztec, Celtic, Inca, Inuit, Japanese, Persian, Polynesian, Slavic, Roman, Finnish,
  Hawaiian, Australian and Indian gods: `tile-shifter-godot/content/realms/_future/<realm>/image_prompts.md`.
  Generate those once, and both games use them.

**How to generate (images).** Use Google Nano Banana / Gemini image, like the other Mytholore art. Use **one
conversation per realm** and start with that realm's terrain tile set, adding *"Match the style, colours and light of
the first picture."* to every later prompt so the set belongs together. Every prompt below is complete: copy it
as it is. Save the files under the paths given (inside this project), then run `python tools/prepare_assets.py`
if the section says so.

**Isometric rules for every map asset**
- **2:1 isometric** (dimetric) view: a square on the ground becomes a diamond **twice as wide as it is tall**.
- Light from the **top left**, soft shadow to the bottom right.
- **Plain pure-white background** (#FFFFFF), the object centred, nothing touching the edges. The tools cut the white
  away, as they already do for the dice.
- **No text, letters, numbers, logos, frames or signatures.**

Contents: [1 Terrain tiles](#1-terrain-tiles) · [2 Props](#2-props) · [3 Dice towers](#3-dice-towers-battle) ·
[4 New dice skins](#4-new-dice-skins) · [5 Realm themes for new pantheons](#5-realm-themes-for-new-pantheons) ·
[6 HUD icons and emblems](#6-hud-icons-and-emblems) · [7 Effects](#7-effects-sprite-sheets) ·
[8 Key art, icon, logo](#8-key-art-app-icon-logo) · [9 Music](#9-music-suno) · [10 Sound effects](#10-sound-effects)

---

## 1. Terrain tiles

Each realm needs **top-face tiles** (the ground of a cell) and **cliff tiles** (the sides of the island). The game tints
the top faces with the owner's colour at about 45%, so they must be **light and low in contrast**, with no strong
colours of their own. Make each as a **single tile**, then the tool cuts it to a 128 × 64 px diamond.

Save as `assets/terrain/<realm>/top_<n>.png` and `assets/terrain/<realm>/cliff_<n>.png`.

### Shared template (fill in the bracket)

```
A single isometric ground tile in 2:1 isometric projection: a flat diamond-shaped piece of ground, exactly twice as wide as it is tall, seen from above at the classic isometric angle, like one tile of a hand-painted strategy game board. The surface is [SURFACE]. Soft painterly hand-painted texture, light and evenly lit from the top left, low contrast, pale and slightly desaturated so it can be tinted with colour later, no strong shadows, no objects standing on it. The diamond is centred on a plain pure white background with generous empty margin, no thickness and no sides visible, nothing else in the picture. No text, no border, no frame.
```

| Realm | top_1 | top_2 | top_3 | top_4 |
|---|---|---|---|---|
| Greek | pale limestone paving with thin cracks and a few tufts of dry grass | sun-bleached olive-grove soil with fallen leaves | short Mediterranean grass with small white flowers | worn white marble slabs with a faint meander pattern |
| Norse | packed snow over dark earth with a few frosted grass blades | grey slate rock with lichen | pale tundra moss and heather | frozen ground with a light dusting of snow and pine needles |
| Egyptian | fine golden desert sand with soft ripples | sandstone paving with eroded edges | dark fertile Nile mud with sparse green shoots | sun-baked cracked clay |
| Chinese | jade-green terrace grass, very short and even | grey stone courtyard tiles in a soft pattern | bamboo-leaf litter on dark earth | pale mossy river stones set in sand |
| Mayan | lush jungle floor of short ferns and moss | weathered limestone plaza blocks with moss in the joints | red-brown jungle earth with roots and leaves | maize-field soil in neat furrows |
| Mesopotamian | sun-dried mud brick paving | pale river-plain soil with reeds | cracked dry clay with a few date-palm fronds | glazed blue-and-ochre brick, very faded |

**Cliff tiles** (2 per realm), the visible side of a raised cell:

```
A single rectangular texture of a cliff face seen straight from the front, [ROCK], hand-painted strategy-game style, top edge a thin lip of [TOP SURFACE] overhanging slightly, the rock darkening gently towards the bottom, lit from the top left, seamless left to right so it can repeat. Wider than tall, 2:1. Plain, no plants sticking out, no objects. On a plain pure white background. No text, no border.
```
Greek: *pale limestone with horizontal strata / olive-grove soil* · Norse: *dark basalt columns with frost / snow* ·
Egyptian: *layered sandstone in ochre and rose / sand* · Chinese: *grey karst stone with moss / jade grass* ·
Mayan: *mossy grey limestone with roots / jungle ferns* · Mesopotamian: *stacked mud brick and clay / sun-dried earth*.

---

## 2. Props

Small objects scattered on territory cells for flavour. They are about one cell wide (64 px at 1×) and up to two cells
tall. Twelve per realm, as **one object per picture**. Save as `assets/props/<realm>/<name>.png`.

### Shared template

```
A single small isometric game prop in 2:1 isometric projection, seen from the classic isometric angle, hand-painted strategy-game style with soft painterly texture: [OBJECT]. It stands on a tiny patch of ground the size of its base. Lit from the top left with a soft shadow falling to the bottom right. Centred on a plain pure white background with generous empty margin, nothing else in the picture. No text, no people, no creatures, no border.
```

| Realm | Objects (one picture each) |
|---|---|
| Greek | a small Doric temple with four columns · a broken column · an olive tree · a cypress tree · an altar with a bronze tripod · an amphora pair · a marble statue on a plinth · a shrine with laurel · a stone well · a vineyard row · a lighthouse tower · a bronze helmet and shield on a stand |
| Norse | a longhouse with turf roof · a runestone · a pine tree · a birch tree with snow · a stone circle · a Viking ship drawn up on rocks · a carved wooden pillar with ravens · a forge with an anvil · a cairn · a burial mound · a watchtower of logs · Yggdrasil sapling with glowing roots |
| Egyptian | a small pyramid · an obelisk · a date palm · a sphinx statue · a temple pylon gate · papyrus reeds · a sun-boat on a stand · a shaduf water lift · a canopic jar pair · a mud-brick granary · a statue of a seated pharaoh · an ankh shrine |
| Chinese | a pagoda · a moon gate · a pine on a rock · a bamboo cluster · a stone lantern · a bronze ding cauldron · a small bridge · a pavilion · a dragon statue · a tea terrace step · a gong on a frame · a lotus pond |
| Mayan | a stepped pyramid · a stela with carvings · a ceiba tree · a ball-court ring wall · a jaguar statue · a maize field patch · a thatched hut · a cenote opening · a feathered-serpent head · an altar stone · a jungle palm · a smoking incense burner |
| Mesopotamian | a small ziggurat · a winged-bull lamassu · a date palm · a reed hut (mudhif) · a city gate of blue glazed brick · a stone stele · an irrigation canal lock · a clay oven · a statue of a worshipper · a sacred tree · a cuneiform tablet stand · a reed boat on mud |

---

## 3. Dice towers (battle)

A dice tower per pantheon. The attacker's stands on the left, the defender's on the right. Dice drop in at the top
and land in the tray. Each tower is drawn **front-on, upright** (not isometric), because it lives in the battle panel.
Make it in **three parts**, each as its own picture on white, so the game can drop dice between them:

- `assets/towers/<pantheon>/tower.png`: the tower body, with an open window at the bottom where dice tumble out
- `assets/towers/<pantheon>/tray.png`: the tray / dish the dice land in (seen slightly from above)
- `assets/towers/<pantheon>/tower_front.png`: only the front lip of the tray, drawn over the dice

### Template

```
A tall ornate dice tower for a board game, seen straight from the front, upright, made of [MATERIAL] in the style of [STYLE], decorated with [MOTIFS]. A square chimney-like tower about three times as tall as wide, with an open slot at the top where dice go in and an arched opening at the bottom where they come out onto a [TRAY]. Hand-painted, highly detailed game-asset illustration, lit from the top left, rich but natural colours. Centred on a plain pure white background with generous margin. No dice, no text, no letters, no people, no border.
```

| Pantheon | MATERIAL | STYLE | MOTIFS | TRAY |
|---|---|---|---|---|
| Greek | white marble with gold inlay | a classical Greek temple | a meander border, lightning bolts, laurel wreaths, an owl on top | shallow marble dish with a gold rim |
| Norse | dark carved wood bound with iron | a Viking stave church | interlaced dragon knotwork, runes as pure ornament, two ravens on the roof | iron-rimmed wooden tray |
| Egyptian | sandstone and lapis lazuli | an Egyptian temple pylon | the eye of Horus, a winged sun disc, papyrus columns | sandstone tray with a lotus rim |
| Chinese | red lacquer and bronze | a three-tier pagoda | dragons, clouds, jade discs | bronze tray with cloud patterns |
| Mayan | grey limestone with jade and red paint | a stepped Maya temple | a feathered serpent coiling around it, glyph-like ornaments without readable text | stone tray with jaguar-head corners |
| Mesopotamian | fired clay and blue glazed brick | a ziggurat of Babylon | lions and dragons of the Ishtar gate, rosettes | clay tray with a blue glazed rim |

---

## 4. New dice skins

**Yoruba** has portraits and a theme but no dice. Other realms may follow. Copy the existing sheets' layout and
**count-coding** exactly, because the game reads the values from it:

> Face 1 = one emblem · 2 = two crossed weapons · 3 = three creatures · 4 = four pillars/columns · 5 = five small
> objects in a circle · 6 = a sun of rays (six-fold).

Save as `Godot/assets/images/dice-wars/dice/dice_<pantheon>.jpg`, add it to `DICE_SKINS` in
`tools/prepare_assets.py` and run it.

```
Six square faces of an ornate game die, shown flat and straight-on, arranged in a grid of three across and two down, with wide white gaps between them, on a plain pure white background. Each face is a rounded square of [MATERIAL] with a raised [BORDER] border, and a raised [METAL] relief in the middle. The faces, left to right, top row then bottom row: 1) a single [EMBLEM]; 2) two crossed [WEAPONS]; 3) three [CREATURES]; 4) four [PILLARS] standing side by side; 5) five [OBJECTS] arranged in a circle; 6) a radiant sun of six-fold rays with [SUN DETAIL]. Photorealistic 3D render of carved material, soft studio light from the top left, crisp detail, all six faces the same size and style. No numbers, no pips, no text, no letters.
```

**Yoruba:** MATERIAL *dark carved iroko wood*, BORDER *beaded (cowrie-shell)*, METAL *bronze*, EMBLEM *double-headed
axe of Shango*, WEAPONS *iron machetes of Ogun*, CREATURES *rams*, PILLARS *carved veranda posts*, OBJECTS
*cowrie shells*, SUN DETAIL *a crown with a beaded veil (Ade) in the centre*.

---

## 5. Realm themes for new pantheons

For a pantheon that gets dice and gods but has no Tile Shifter theme yet (Aztec, Celtic, Inca, Inuit, Japanese, Persian,
Polynesian, Slavic). The files and sizes match the existing themes (`assets/themes/<realm>/`), so the menus pick them up
with no code change. Also add a `look.json` (palette, title font, weather), copying `assets/themes/greek/look.json`.

| File | Size | Prompt |
|---|---|---|
| `background.jpg` | 2560 × 1429 | template A |
| `background_portrait.jpg` | 1080 × 1935 | template A, *"tall 9:16 portrait composition"* |
| `background_game.jpg` / `_portrait_game.jpg` | 1280 × 714 / 540 × 968 | the same picture, blurred (radius ≈ 12 px) and darkened 35%. Make it in an editor, not with a prompt |
| `panel.png` | 224 × 224 | template B |
| `panel_small.png` | 112 × 112 | template B, *"thinner border"* |
| `button.png` | 199 × 56 | template C |
| `round.png` | 112 × 112 | template D |

**A. Background**
```
A wide 16:9 epic landscape painting of [REALM SCENE], seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light, the centre of the picture calmer and darker so a menu can sit over it, detail towards the edges. No people, no creatures, no text, no border.
```
**B. Panel frame (nine-slice)**
```
A square ornamental frame for a game menu panel, seen straight on: a border of [ORNAMENT] around a plain very dark [COLOUR] centre, the border pattern repeating evenly along each side so it can be stretched, identical corners. Flat, hand-crafted, high detail, no perspective, no shadow outside the frame. On a plain pure white background. No text.
```
**C. Button**
```
A wide horizontal game button, about 3.5 times as wide as tall, seen straight on: a [MATERIAL] plaque with a thin [ORNAMENT] border, slightly raised, the centre plain so a word can be written on it. Flat lighting from the top, no perspective. On a plain pure white background. No text.
```
**D. Round medallion**
```
A round game button medallion seen straight on: a disc of [MATERIAL] with a [ORNAMENT] rim, the centre plain and slightly concave so an icon can sit on it. Flat lighting from the top. On a plain pure white background. No text, no icon.
```

| Realm | REALM SCENE | ORNAMENT · COLOUR · MATERIAL |
|---|---|---|
| Aztec | Tenochtitlan on its lake, causeways, the Templo Mayor, volcanoes beyond | stepped-fret greca in turquoise and gold · obsidian black · carved basalt with turquoise mosaic |
| Celtic | misty green hills, a stone circle, a lake with a crannog, an oak forest | knotwork in bronze · deep moss green · bronze with enamel |
| Inca | terraces of Machu Picchu, Andean peaks, clouds below | stepped chakana pattern in gold · warm stone brown · fitted granite and gold |
| Inuit | sea ice under the aurora, an iglu camp, mountains of ice | carved bone with simple line patterns · midnight blue · walrus ivory and driftwood |
| Japanese | a torii in a mountain lake, cherry trees, Mount Fuji | lacquer and gold wave pattern · black lacquer · red lacquer with gold |
| Persian | Persepolis' terraces and columns, gardens with water channels | tile arabesques in turquoise and lapis · deep indigo · glazed tile and gold |
| Polynesian | a volcanic island, lagoon, outrigger canoes, palms | tapa-cloth and carved wood patterns · dark koa brown · carved koa wood and shell |
| Slavic | a birch forest, a wooden fortress on a river, sunset | carved folk patterns, red and gold · dark red · carved wood with painted flowers |

---

## 6. HUD icons and emblems

Small flat icons (256 × 256), drawn in **one shared style** so they belong together. Save them in `assets/ui/icons/`.

```
A single game interface icon: [SUBJECT]. Bold, simple silhouette readable at 32 pixels, hand-painted with a gold-and-ivory palette and a dark outline, a slight bevel, lit from the top left. Centred on a plain pure white background with margin. No text, no letters, no border.
```

| File | SUBJECT |
|---|---|
| `favour.png` | a glowing golden flame in an offering bowl |
| `reserve.png` | three dice in a leather pouch |
| `reinforce.png` | a die with an upward arrow of light |
| `crown.png` | a laurel crown (the leader) |
| `ward.png` | a translucent dome shield |
| `smite.png` | a lightning bolt striking down |
| `bless.png` | an open hand with rising golden sparks |
| `awaken.png` | an opening eye with rays |
| `asleep.png` | a closed eye with a crescent moon |
| `attack.png` | two crossed swords |
| `defence.png` | a round shield |
| `end_turn.png` | an hourglass |

**Player emblems (colour-blind support):** use each pantheon's dice face 1, which the game already has. No new art is needed.

---

## 7. Effects (sprite sheets)

Generate each as a **row of 8 frames** on white (one picture, 8 equal squares left to right), or make them in a
particle tool. Save them in `assets/vfx/`.

```
A sprite sheet of eight animation frames in one horizontal row, equal square cells with white gaps, on a plain pure white background: [EFFECT], from the first frame to the last. Hand-painted game effect style, bright core, soft edges, consistent size and position in every frame. No text, no border.
```

| File | EFFECT |
|---|---|
| `dust.png` | a puff of grey-brown dust bursting outward and fading |
| `lightning.png` | a bolt of white-blue lightning striking down, flashing and fading |
| `motes.png` | golden light motes rising in a spiral and fading |
| `ward_dome.png` | a translucent pale-blue dome forming with a ripple |
| `crumble.png` | a carved die cracking into pieces that fall away |
| `flag_wave.png` | a small pennant on a pole waving in the wind (tint later) |

---

## 8. Key art, app icon, logo

**Key art** (store pages, splash), 3840 × 2160 and a 1080 × 1920 version:
```
Epic key art for a strategy board game: a floating island of patchwork territories seen in isometric view, hovering above a sea of clouds at golden hour, each territory a raised plateau with temples and trees in different colours, tall towers of ornate carved dice standing on them. Above the island, huge and ghostly in the sky, the faces of gods from different mythologies watch: a Greek thunder god, a one-eyed Norse god with ravens, a falcon-headed Egyptian god, a Chinese jade emperor. A single carved die tumbles through the air in the foreground, catching the light. Painterly, richly detailed, premium mythology art book style, warm light, deep atmosphere. Leave calm space at the top centre for a title. No text, no letters, no logo.
```
**App icon**, 1024 × 1024:
```
A game app icon: a single ornate carved die made of white marble and gold, tilted to show three faces, one face showing a golden lightning bolt in relief, glowing softly, on a deep twilight-blue background with a faint golden halo behind it. Bold, centred, simple, readable at small sizes, rounded-square friendly composition, painterly but crisp. No text, no letters, no border.
```
**Logo wordmark:** make the words "Mythic Dice Wars" in a type tool, not an image generator (generators misspell
text). Use Cinzel Decorative Bold (already in Tile Shifter's fonts, OFL) with a gold bevel and a die replacing the "i"
dot of "Dice".

---

## 9. Music (Suno)

The same approach as Chasm of Knights (`content/music/suno_prompts.md`): **Custom** mode, **Instrumental on**,
Weirdness about 25%, Style influence about 75%, 3–4 takes, keep the steadiest, download WAV, loop in an editor.
Save the results as `assets/audio/music/<pantheon>_menu.ogg` and `<pantheon>_war.ogg`, plus `victory.ogg` and `defeat.ogg`.

**Exclude styles (all):**
```
vocals, singing, lyrics, spoken word, rap, EDM, trap beat, electric guitar, dubstep, synth lead, big drop, fade out
```

| Track | Style of Music |
|---|---|
| `greek_menu` | ancient Greek lyre and aulos, soft frame drum, warm and stately, Mediterranean modal, calm cinematic, 80 bpm |
| `greek_war` | ancient Greek war march, aulos and lyre over taiko-like frame drums, bronze percussion, tense but even, 100 bpm, loopable |
| `norse_menu` | Nordic folk, tagelharpa and kraviklyra, low drone, distant wind, calm and mystic, 70 bpm |
| `norse_war` | Nordic war drums, tagelharpa ostinato, deep horns, throat-sung drone without words, driving, 105 bpm, loopable |
| `egyptian_menu` | ancient Egyptian ambience, ney flute, harp, sistrum shimmer, desert calm, 75 bpm |
| `egyptian_war` | Egyptian percussion, darbuka and frame drums, ney and harp ostinato, tense, 100 bpm, loopable |
| `chinese_menu` | guqin and dizi, soft gong, garden calm, pentatonic, 70 bpm |
| `chinese_war` | Chinese war drums, pipa tremolo, suona motifs, steady martial pulse, 110 bpm, loopable |
| `mayan_menu` | Mesoamerican ambience, clay flutes, ocarina, rainforest, slit drum, 75 bpm |
| `mayan_war` | Mesoamerican drums (tunkul, huehuetl), conch, clay whistles, driving, 105 bpm, loopable |
| `mesopotamian_menu` | ancient Mesopotamian lyre and reed pipe, frame drum, dusk, modal, 75 bpm |
| `mesopotamian_war` | Mesopotamian frame drums, lyre ostinato, horn calls, tense, 100 bpm, loopable |
| `victory` | short triumphant fanfare, brass and drums, mythic, 8 seconds, clean ending |
| `defeat` | short sombre phrase, low strings and a distant horn, 7 seconds, clean ending |

---

## 10. Sound effects

Use a sound-effect generator (ElevenLabs Sound Effects or similar) or record them. Keep them short and dry, with
no music. Save them as `assets/audio/sfx/<name>.ogg` and map them in `presentation/sound.gd` (`SOUNDS`).

| Name | Description to generate | Length |
|---|---|---|
| `roll_stone` | a handful of heavy stone dice rattling in a stone cup, then tumbling down a wooden tower | 1.2 s |
| `roll_wood` | wooden dice tumbling down a wooden dice tower and clattering into a tray | 1.2 s |
| `roll_clay` | fired-clay dice rattling and landing in a clay dish | 1.2 s |
| `dice_land` | one die landing on a wooden board with a solid knock | 0.3 s |
| `conquer` | stone crunch followed by a short low war horn | 1.0 s |
| `repelled` | a sword hitting a bronze shield, a clang with a short ring | 0.6 s |
| `reinforce` | soft wooden knocks of dice dropping one after another, three to five knocks | 0.8 s |
| `smite` | a sharp lightning crack with a rolling thunder tail | 1.5 s |
| `bless` | a gentle rising choir-like shimmer with chimes (no words) | 1.2 s |
| `ward` | a deep resonant temple bell with a soft shimmer | 1.5 s |
| `awaken` | a deep gong hit with a rising whoosh | 2.0 s |
| `eliminated` | a crumbling stone wall and a distant horn fading | 2.0 s |
| `turn_start` | a soft single bell tick | 0.4 s |
| `ui_click` / `ui_hover` / `ui_back` | (Kenney's UI sounds are already in; keep them) | — |

**Voice barks [later]:** one wordless shout or chant per god for the awakening, 1–2 s, about 72 lines. Generate them with
a voice tool from a one-line description, e.g. *"a deep, booming male battle cry, ancient Greek war god, reverberant
hall"*.
