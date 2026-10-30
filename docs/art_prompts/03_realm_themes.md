# Realm themes (menus) for new pantheons

The menu look of each realm: the painted background, frames, buttons and round medallion buttons. The six playable
pantheons already have theirs (from Tile Shifter). These are for the next eight, which already have dice.

- **One conversation per realm**: paste the prompts in order.
- Save in `assets/themes/<realm>/` under the file names below. Then make the two game backgrounds yourself, in any
  image editor: `background_game.jpg` (1280 × 714) and `background_portrait_game.jpg` (540 × 968) are the same two
  pictures scaled down, blurred (radius about 12 px) and darkened by about 35%.
- Add the `look.json` given for each realm, and copy its title font file next to it.

| File | Final size |
|---|---|
| `background.jpg` | 2560 × 1429 |
| `background_portrait.jpg` | 1080 × 1935 |
| `panel.png` | 224 × 224 |
| `panel_small.png` | 112 × 112 |
| `button.png` | 199 × 56 |
| `round.png` | 112 × 112 |

## Aztec

### `background.jpg`

```
A wide 16:9 epic landscape painting of the lake city of Tenochtitlan at sunrise: white causeways across blue water, the twin-temple Templo Mayor, floating chinampa gardens, canoes, and snow-capped volcanoes on the horizon. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The centre of the picture is calmer and darker so a menu panel can sit over it, with the detail towards the edges. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame.
```

### `background_portrait.jpg`

```
A tall 9:16 portrait version of the same scene: the lake city of Tenochtitlan at sunrise: white causeways across blue water, the twin-temple Templo Mayor, floating chinampa gardens, canoes, and snow-capped volcanoes on the horizon. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The middle of the picture is calmer and darker so a menu panel can sit over it, with the detail at the top and bottom. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel.png`

```
A square ornamental frame for a game menu panel, seen straight on: a border of a stepped-fret (xicalcoliuhqui) pattern in turquoise mosaic and gold around a plain, very dark obsidian black centre. The border pattern repeats evenly along each side so it can be stretched, and all four corners are identical. Flat, hand-crafted, high detail, no perspective, no shadow outside the frame. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel_small.png`

```
The same ornamental frame as the previous picture, but with a thinner border: a stepped-fret (xicalcoliuhqui) pattern in turquoise mosaic and gold around a plain, very dark obsidian black centre, the pattern repeating evenly, all four corners identical. Flat, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `button.png`

```
A wide horizontal game button, about 3.5 times as wide as it is tall, seen straight on: a plaque of carved grey basalt inlaid with turquoise mosaic with a thin border of a stepped-fret (xicalcoliuhqui) pattern in turquoise mosaic and gold, slightly raised, the centre plain so a word can be written on it later. Flat lighting from the top, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `round.png`

```
A round game button medallion seen straight on: a disc of carved grey basalt inlaid with turquoise mosaic with a rim of a stepped-fret (xicalcoliuhqui) pattern in turquoise mosaic and gold, the centre plain and slightly concave so an icon can sit on it later. Flat lighting from the top. On a plain pure white background. No icon. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `look.json` (copy `Macondo-Regular.ttf` from Tile Shifter's Mayan theme (assets/themes/mayan) into the same folder)

```json
{
 "id": "aztec",
 "name": "Aztec",
 "palette": {
  "bg_top": "#2a1f1a",
  "bg_bottom": "#0d0806",
  "panel": "#2b211be8",
  "border": "#3fb3a6",
  "text": "#f4ead8",
  "accent": "#e6b84a",
  "button": "#3d2c22",
  "hover": "#55402f",
  "pressed": "#2a1e17",
  "marker": "#46c36b",
  "hint": "#ffd23f"
 },
 "title_font": "Macondo-Regular.ttf",
 "weather": "haze",
 "panel_margin": 28,
 "panel_small_margin": 14,
 "button_margin": 14
}
```

## Celtic

### `background.jpg`

```
A wide 16:9 epic landscape painting of misty green hills at dawn: a ring of standing stones on a rise, a lake with a crannog roundhouse, an ancient oak forest and distant mountains. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The centre of the picture is calmer and darker so a menu panel can sit over it, with the detail towards the edges. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame.
```

### `background_portrait.jpg`

```
A tall 9:16 portrait version of the same scene: misty green hills at dawn: a ring of standing stones on a rise, a lake with a crannog roundhouse, an ancient oak forest and distant mountains. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The middle of the picture is calmer and darker so a menu panel can sit over it, with the detail at the top and bottom. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel.png`

```
A square ornamental frame for a game menu panel, seen straight on: a border of interlaced knotwork in bronze with red enamel studs around a plain, very dark deep moss green centre. The border pattern repeats evenly along each side so it can be stretched, and all four corners are identical. Flat, hand-crafted, high detail, no perspective, no shadow outside the frame. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel_small.png`

```
The same ornamental frame as the previous picture, but with a thinner border: interlaced knotwork in bronze with red enamel studs around a plain, very dark deep moss green centre, the pattern repeating evenly, all four corners identical. Flat, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `button.png`

```
A wide horizontal game button, about 3.5 times as wide as it is tall, seen straight on: a plaque of polished bronze with red and yellow enamel with a thin border of interlaced knotwork in bronze with red enamel studs, slightly raised, the centre plain so a word can be written on it later. Flat lighting from the top, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `round.png`

```
A round game button medallion seen straight on: a disc of polished bronze with red and yellow enamel with a rim of interlaced knotwork in bronze with red enamel studs, the centre plain and slightly concave so an icon can sit on it later. Flat lighting from the top. On a plain pure white background. No icon. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `look.json` (copy `UncialAntiqua-Regular.ttf` from Tile Shifter's assets/fonts into the same folder)

```json
{
 "id": "celtic",
 "name": "Celtic",
 "palette": {
  "bg_top": "#1d2a22",
  "bg_bottom": "#070c09",
  "panel": "#1f2c24e8",
  "border": "#b8935a",
  "text": "#eef0e4",
  "accent": "#d9b765",
  "button": "#2f4134",
  "hover": "#405848",
  "pressed": "#223026",
  "marker": "#46c36b",
  "hint": "#ffd23f"
 },
 "title_font": "UncialAntiqua-Regular.ttf",
 "weather": "rain",
 "panel_margin": 28,
 "panel_small_margin": 14,
 "button_margin": 14
}
```

## Inca

### `background.jpg`

```
A wide 16:9 epic landscape painting of the mountain citadel of Machu Picchu: green terraces stepping down the slopes, fitted stone temples, llamas grazing, sharp Andean peaks and a sea of clouds below. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The centre of the picture is calmer and darker so a menu panel can sit over it, with the detail towards the edges. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame.
```

### `background_portrait.jpg`

```
A tall 9:16 portrait version of the same scene: the mountain citadel of Machu Picchu: green terraces stepping down the slopes, fitted stone temples, llamas grazing, sharp Andean peaks and a sea of clouds below. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The middle of the picture is calmer and darker so a menu panel can sit over it, with the detail at the top and bottom. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel.png`

```
A square ornamental frame for a game menu panel, seen straight on: a border of a stepped Andean cross (chakana) pattern in gold around a plain, very dark warm stone brown centre. The border pattern repeats evenly along each side so it can be stretched, and all four corners are identical. Flat, hand-crafted, high detail, no perspective, no shadow outside the frame. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel_small.png`

```
The same ornamental frame as the previous picture, but with a thinner border: a stepped Andean cross (chakana) pattern in gold around a plain, very dark warm stone brown centre, the pattern repeating evenly, all four corners identical. Flat, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `button.png`

```
A wide horizontal game button, about 3.5 times as wide as it is tall, seen straight on: a plaque of tightly fitted granite blocks edged with gold with a thin border of a stepped Andean cross (chakana) pattern in gold, slightly raised, the centre plain so a word can be written on it later. Flat lighting from the top, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `round.png`

```
A round game button medallion seen straight on: a disc of tightly fitted granite blocks edged with gold with a rim of a stepped Andean cross (chakana) pattern in gold, the centre plain and slightly concave so an icon can sit on it later. Flat lighting from the top. On a plain pure white background. No icon. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `look.json` (copy `Cinzel.ttf` from Tile Shifter's assets/fonts into the same folder)

```json
{
 "id": "inca",
 "name": "Inca",
 "palette": {
  "bg_top": "#2a2219",
  "bg_bottom": "#0d0a07",
  "panel": "#2d241ae8",
  "border": "#d2a13b",
  "text": "#f5ecdc",
  "accent": "#efc35a",
  "button": "#45382a",
  "hover": "#5c4b38",
  "pressed": "#30271d",
  "marker": "#46c36b",
  "hint": "#ffd23f"
 },
 "title_font": "Cinzel.ttf",
 "weather": "haze",
 "panel_margin": 28,
 "panel_small_margin": 14,
 "button_margin": 14
}
```

## Inuit

### `background.jpg`

```
A wide 16:9 epic landscape painting of sea ice under a green and violet aurora: a camp of snow houses, a dog sled, kayaks on the ice edge, icebergs and dark mountains of ice. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The centre of the picture is calmer and darker so a menu panel can sit over it, with the detail towards the edges. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame.
```

### `background_portrait.jpg`

```
A tall 9:16 portrait version of the same scene: sea ice under a green and violet aurora: a camp of snow houses, a dog sled, kayaks on the ice edge, icebergs and dark mountains of ice. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The middle of the picture is calmer and darker so a menu panel can sit over it, with the detail at the top and bottom. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel.png`

```
A square ornamental frame for a game menu panel, seen straight on: a border of carved walrus ivory with simple incised line patterns around a plain, very dark midnight blue centre. The border pattern repeats evenly along each side so it can be stretched, and all four corners are identical. Flat, hand-crafted, high detail, no perspective, no shadow outside the frame. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel_small.png`

```
The same ornamental frame as the previous picture, but with a thinner border: carved walrus ivory with simple incised line patterns around a plain, very dark midnight blue centre, the pattern repeating evenly, all four corners identical. Flat, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `button.png`

```
A wide horizontal game button, about 3.5 times as wide as it is tall, seen straight on: a plaque of walrus ivory set in weathered driftwood with a thin border of carved walrus ivory with simple incised line patterns, slightly raised, the centre plain so a word can be written on it later. Flat lighting from the top, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `round.png`

```
A round game button medallion seen straight on: a disc of walrus ivory set in weathered driftwood with a rim of carved walrus ivory with simple incised line patterns, the centre plain and slightly concave so an icon can sit on it later. Flat lighting from the top. On a plain pure white background. No icon. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `look.json` (copy `Philosopher-Bold.ttf` from Tile Shifter's assets/fonts into the same folder)

```json
{
 "id": "inuit",
 "name": "Inuit",
 "palette": {
  "bg_top": "#152234",
  "bg_bottom": "#050a12",
  "panel": "#18263ae8",
  "border": "#c9c2ae",
  "text": "#eef3f6",
  "accent": "#7fd6c4",
  "button": "#26384f",
  "hover": "#344c68",
  "pressed": "#1a283a",
  "marker": "#46c36b",
  "hint": "#ffd23f"
 },
 "title_font": "Philosopher-Bold.ttf",
 "weather": "snow",
 "panel_margin": 28,
 "panel_small_margin": 14,
 "button_margin": 14
}
```

## Japanese

### `background.jpg`

```
A wide 16:9 epic landscape painting of a vermilion torii gate standing in a still mountain lake, cherry trees in blossom along the shore, a pagoda on a hill and Mount Fuji beyond. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The centre of the picture is calmer and darker so a menu panel can sit over it, with the detail towards the edges. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame.
```

### `background_portrait.jpg`

```
A tall 9:16 portrait version of the same scene: a vermilion torii gate standing in a still mountain lake, cherry trees in blossom along the shore, a pagoda on a hill and Mount Fuji beyond. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The middle of the picture is calmer and darker so a menu panel can sit over it, with the detail at the top and bottom. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel.png`

```
A square ornamental frame for a game menu panel, seen straight on: a border of gold lacquer waves (seigaiha) on black lacquer around a plain, very dark black lacquer centre. The border pattern repeats evenly along each side so it can be stretched, and all four corners are identical. Flat, hand-crafted, high detail, no perspective, no shadow outside the frame. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel_small.png`

```
The same ornamental frame as the previous picture, but with a thinner border: gold lacquer waves (seigaiha) on black lacquer around a plain, very dark black lacquer centre, the pattern repeating evenly, all four corners identical. Flat, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `button.png`

```
A wide horizontal game button, about 3.5 times as wide as it is tall, seen straight on: a plaque of red lacquer with gold maki-e decoration with a thin border of gold lacquer waves (seigaiha) on black lacquer, slightly raised, the centre plain so a word can be written on it later. Flat lighting from the top, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `round.png`

```
A round game button medallion seen straight on: a disc of red lacquer with gold maki-e decoration with a rim of gold lacquer waves (seigaiha) on black lacquer, the centre plain and slightly concave so an icon can sit on it later. Flat lighting from the top. On a plain pure white background. No icon. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `look.json` (copy `ShipporiMincho-Bold.ttf` from Google Fonts (Shippori Mincho, OFL) into the same folder)

```json
{
 "id": "japanese",
 "name": "Japanese",
 "palette": {
  "bg_top": "#2a1c20",
  "bg_bottom": "#0c0709",
  "panel": "#2a1d21e8",
  "border": "#c9a25a",
  "text": "#f6efe8",
  "accent": "#e2574c",
  "button": "#432a2f",
  "hover": "#5c3a40",
  "pressed": "#2e1d21",
  "marker": "#46c36b",
  "hint": "#ffd23f"
 },
 "title_font": "ShipporiMincho-Bold.ttf",
 "weather": "petals",
 "panel_margin": 28,
 "panel_small_margin": 14,
 "button_margin": 14
}
```

## Persian

### `background.jpg`

```
A wide 16:9 epic landscape painting of the terraces of Persepolis at golden hour: rows of tall columns with bull capitals, grand stairways with reliefs, and a walled garden with water channels and cypresses. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The centre of the picture is calmer and darker so a menu panel can sit over it, with the detail towards the edges. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame.
```

### `background_portrait.jpg`

```
A tall 9:16 portrait version of the same scene: the terraces of Persepolis at golden hour: rows of tall columns with bull capitals, grand stairways with reliefs, and a walled garden with water channels and cypresses. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The middle of the picture is calmer and darker so a menu panel can sit over it, with the detail at the top and bottom. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel.png`

```
A square ornamental frame for a game menu panel, seen straight on: a border of arabesque tilework in turquoise and lapis blue with gold around a plain, very dark deep indigo centre. The border pattern repeats evenly along each side so it can be stretched, and all four corners are identical. Flat, hand-crafted, high detail, no perspective, no shadow outside the frame. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel_small.png`

```
The same ornamental frame as the previous picture, but with a thinner border: arabesque tilework in turquoise and lapis blue with gold around a plain, very dark deep indigo centre, the pattern repeating evenly, all four corners identical. Flat, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `button.png`

```
A wide horizontal game button, about 3.5 times as wide as it is tall, seen straight on: a plaque of glazed turquoise tile and gold with a thin border of arabesque tilework in turquoise and lapis blue with gold, slightly raised, the centre plain so a word can be written on it later. Flat lighting from the top, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `round.png`

```
A round game button medallion seen straight on: a disc of glazed turquoise tile and gold with a rim of arabesque tilework in turquoise and lapis blue with gold, the centre plain and slightly concave so an icon can sit on it later. Flat lighting from the top. On a plain pure white background. No icon. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `look.json` (copy `Marcellus-Regular.ttf` from Tile Shifter's assets/fonts into the same folder)

```json
{
 "id": "persian",
 "name": "Persian",
 "palette": {
  "bg_top": "#1b1d33",
  "bg_bottom": "#07070f",
  "panel": "#1e2038e8",
  "border": "#c8a65e",
  "text": "#f2ede0",
  "accent": "#4fc0c8",
  "button": "#2c2f52",
  "hover": "#3b3f6c",
  "pressed": "#1f213a",
  "marker": "#46c36b",
  "hint": "#ffd23f"
 },
 "title_font": "Marcellus-Regular.ttf",
 "weather": "sand",
 "panel_margin": 28,
 "panel_small_margin": 14,
 "button_margin": 14
}
```

## Polynesian

### `background.jpg`

```
A wide 16:9 epic landscape painting of a green volcanic island with a smoking peak, a turquoise lagoon, outrigger canoes on a white beach, palms, and carved wooden figures at a stone marae. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The centre of the picture is calmer and darker so a menu panel can sit over it, with the detail towards the edges. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame.
```

### `background_portrait.jpg`

```
A tall 9:16 portrait version of the same scene: a green volcanic island with a smoking peak, a turquoise lagoon, outrigger canoes on a white beach, palms, and carved wooden figures at a stone marae. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The middle of the picture is calmer and darker so a menu panel can sit over it, with the detail at the top and bottom. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel.png`

```
A square ornamental frame for a game menu panel, seen straight on: a border of carved patterns from tapa cloth and koa wood, with shell inlay around a plain, very dark dark koa brown centre. The border pattern repeats evenly along each side so it can be stretched, and all four corners are identical. Flat, hand-crafted, high detail, no perspective, no shadow outside the frame. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel_small.png`

```
The same ornamental frame as the previous picture, but with a thinner border: carved patterns from tapa cloth and koa wood, with shell inlay around a plain, very dark dark koa brown centre, the pattern repeating evenly, all four corners identical. Flat, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `button.png`

```
A wide horizontal game button, about 3.5 times as wide as it is tall, seen straight on: a plaque of carved koa wood with mother-of-pearl inlay with a thin border of carved patterns from tapa cloth and koa wood, with shell inlay, slightly raised, the centre plain so a word can be written on it later. Flat lighting from the top, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `round.png`

```
A round game button medallion seen straight on: a disc of carved koa wood with mother-of-pearl inlay with a rim of carved patterns from tapa cloth and koa wood, with shell inlay, the centre plain and slightly concave so an icon can sit on it later. Flat lighting from the top. On a plain pure white background. No icon. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `look.json` (copy `Kurale-Regular.ttf` from Tile Shifter's Chinese theme (assets/themes/chinese) into the same folder)

```json
{
 "id": "polynesian",
 "name": "Polynesian",
 "palette": {
  "bg_top": "#20261f",
  "bg_bottom": "#080a07",
  "panel": "#252a20e8",
  "border": "#c49a62",
  "text": "#f6f0e2",
  "accent": "#3cc2b0",
  "button": "#3a3326",
  "hover": "#504633",
  "pressed": "#29241b",
  "marker": "#46c36b",
  "hint": "#ffd23f"
 },
 "title_font": "Kurale-Regular.ttf",
 "weather": "leaves",
 "panel_margin": 28,
 "panel_small_margin": 14,
 "button_margin": 14
}
```

## Slavic

### `background.jpg`

```
A wide 16:9 epic landscape painting of a birch forest at sunset beside a wide river, a wooden hill fort with carved gates, onion-shaped wooden towers and a sacred oak on the riverbank. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The centre of the picture is calmer and darker so a menu panel can sit over it, with the detail towards the edges. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame.
```

### `background_portrait.jpg`

```
A tall 9:16 portrait version of the same scene: a birch forest at sunset beside a wide river, a wooden hill fort with carved gates, onion-shaped wooden towers and a sacred oak on the riverbank. Seen from a high vantage point at golden hour, richly detailed painterly fantasy art in the style of a premium mythology art book, deep atmosphere, soft light. The middle of the picture is calmer and darker so a menu panel can sit over it, with the detail at the top and bottom. No people, no creatures. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel.png`

```
A square ornamental frame for a game menu panel, seen straight on: a border of carved and painted folk patterns of red flowers and gold suns around a plain, very dark dark red centre. The border pattern repeats evenly along each side so it can be stretched, and all four corners are identical. Flat, hand-crafted, high detail, no perspective, no shadow outside the frame. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `panel_small.png`

```
The same ornamental frame as the previous picture, but with a thinner border: carved and painted folk patterns of red flowers and gold suns around a plain, very dark dark red centre, the pattern repeating evenly, all four corners identical. Flat, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `button.png`

```
A wide horizontal game button, about 3.5 times as wide as it is tall, seen straight on: a plaque of carved wood painted with red and gold folk flowers with a thin border of carved and painted folk patterns of red flowers and gold suns, slightly raised, the centre plain so a word can be written on it later. Flat lighting from the top, no perspective. On a plain pure white background. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `round.png`

```
A round game button medallion seen straight on: a disc of carved wood painted with red and gold folk flowers with a rim of carved and painted folk patterns of red flowers and gold suns, the centre plain and slightly concave so an icon can sit on it later. Flat lighting from the top. On a plain pure white background. No icon. No text, no letters, no numbers, no signature, no border, no frame. Match the style, colours and light of the earlier pictures in this conversation.
```

### `look.json` (copy `RuslanDisplay-Regular.ttf` from the Norse theme (assets/themes/norse) into the same folder)

```json
{
 "id": "slavic",
 "name": "Slavic",
 "palette": {
  "bg_top": "#2a1a19",
  "bg_bottom": "#0c0707",
  "panel": "#2d1d1ce8",
  "border": "#c9a258",
  "text": "#f6ece2",
  "accent": "#e3b04f",
  "button": "#4a2a28",
  "hover": "#633936",
  "pressed": "#331d1c",
  "marker": "#46c36b",
  "hint": "#ffd23f"
 },
 "title_font": "RuslanDisplay-Regular.ttf",
 "weather": "leaves",
 "panel_margin": 28,
 "panel_small_margin": 14,
 "button_margin": 14
}
```
