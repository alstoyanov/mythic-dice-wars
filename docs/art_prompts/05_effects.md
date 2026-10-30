# Effects (sprite sheets)

Short animations for battles and miracles, each as one row of eight frames.

- **One conversation for all of them**, in order.
- Generate at **4096 × 512** (eight square frames side by side).
- Save as `assets/vfx/<file>`.

**Light goes on black, smoke and debris on white.** The first Greek set was all on white, and a glow's
bright core cannot be told apart from a white background, so lightning, motes and the ward came out
faint (the game now draws extra light over them). Glows painted on black can simply be added onto the
map. The flag sheet is gone: a white flag on white cannot be cut out, and the game draws its pennants itself.

### `dust.png` (on white)

```
A sprite sheet of eight animation frames in one horizontal row of equal square cells with white gaps between them and no lines or borders around the cells, on a plain pure white background: a puff of grey-brown dust bursting outward and fading away, from the first frame to the last. Hand-painted game-effect style with a bright core and soft edges, the same size and position in every frame. No text, no letters, no numbers, no signature, no border, no frame.
```

### `lightning.png` (on black)

```
A sprite sheet of eight animation frames in one horizontal row of equal square cells with black gaps between them and no lines or borders around the cells, on a plain pure black background: a bolt of white-blue lightning striking down, flashing bright and fading, from the first frame to the last. Hand-painted game-effect style with a bright core and soft edges, the same size and position in every frame. No text, no letters, no numbers, no signature, no border, no frame. Match the style of the earlier sprite sheets in this conversation.
```

### `motes.png` (on black)

```
A sprite sheet of eight animation frames in one horizontal row of equal square cells with black gaps between them and no lines or borders around the cells, on a plain pure black background: golden motes of light rising in a spiral and fading, from the first frame to the last. Hand-painted game-effect style with a bright core and soft edges, the same size and position in every frame. No text, no letters, no numbers, no signature, no border, no frame. Match the style of the earlier sprite sheets in this conversation.
```

### `ward_dome.png` (on black)

```
A sprite sheet of eight animation frames in one horizontal row of equal square cells with black gaps between them and no lines or borders around the cells, on a plain pure black background: a translucent pale-blue dome of light forming from the ground up with a ripple, from the first frame to the last. Hand-painted game-effect style with a bright core and soft edges, the same size and position in every frame. No text, no letters, no numbers, no signature, no border, no frame. Match the style of the earlier sprite sheets in this conversation.
```

### `crumble.png` (on white)

```
A sprite sheet of eight animation frames in one horizontal row of equal square cells with white gaps between them and no lines or borders around the cells, on a plain pure white background: a carved stone die cracking into pieces that fall away, from the first frame to the last. Hand-painted game-effect style with a bright core and soft edges, the same size and position in every frame. No text, no letters, no numbers, no signature, no border, no frame. Match the style of the earlier sprite sheets in this conversation.
```
