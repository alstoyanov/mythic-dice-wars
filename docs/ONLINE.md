# Online wars

Mythic Dice Wars plays online on the **Mytholore Game Server** (`../mytholore-game-server`), the same server and the same
accounts as Chasm of Knights and Tile Shifter. The game itself stays fully playable offline; only online wars need an
account.

## For players

**Main menu → Online Wars.** Not logged in yet: the account screen first (sign in with Google through the browser, or an
email and password). Then the online lobby:

- **Your pantheon and gods for the next war**: every player brings their own; they are sent to the server when the war
  begins, and stay secret until everyone has chosen (the Book of the Gods is one click away).
- **Quick war against random players** (always rated): a **ranked duel**, or a **ranked war of four**. Matchmaking
  looks for players of about your rating; the longer you wait, the wider the search (any rating after 90 s).
- **Open wars**: the wars other players opened, with how many have joined (*3 of 4 players*); join one, or join any
  war by its **code**.
- **Open a war** for **2 to 6 players**:
  - *Rated* (rating and ranking points), *Friendly* (not rated), or *Long-running* (a day per turn, rated);
  - the realm size, squares or hexagons, the turn order (balanced or classic) and when the secondary gods wake;
  - who can join: anyone, your friends, or only the players you give the code to.
  It starts as soon as it is full; until then it waits up to 30 minutes.
- **Wars in progress** (if the game was closed during one, and long-running wars) can be returned to from the lobby.

**In a war** the game screen is the same as against the computer; the other players' attacks show on the map (the
arrow, then the outcome), your own fill the screen with the dice towers. Each action has a time limit: **60 seconds**
(a day in long-running wars); the time left shows under your gods. When it runs out your turn ends (in a long-running
war you leave the war). If your connection drops, the server keeps your seat for 90 seconds. **Leave** asks first: it
resigns you.

Fog of war is for wars against the computer: online, every player sees the whole realm.

## How the rankings work

Every online war ends with a **finishing place** for each player:

- The last pantheon standing wins: **1st**.
- The others are placed in the **reverse order in which they fell**: the last to lose their land is 2nd, the one before
  3rd, and so on.
- **Leaving** a war (resigning, losing the connection for good, missing a deadline in a long-running war) counts as
  falling at that moment: you are placed below everyone still fighting, and your land stays on the map for the others.

### Ranking points

You score **3 points for every player who finished below you**, and the **winner scores 3 more**:

| Players | 1st | 2nd | 3rd | 4th | 5th | 6th |
|---|---:|---:|---:|---:|---:|---:|
| 2 | 6 | 0 | | | | |
| 3 | 9 | 3 | 0 | | | |
| 4 | 12 | 6 | 3 | 0 | | |
| 5 | 15 | 9 | 6 | 3 | 0 | |
| 6 | 18 | 12 | 9 | 6 | 3 | 0 |

- **Example.** A war of five: Ana wins, Ben falls last, then Cleo, Dev and Eli (who fell first). Ana scores 15, Ben 9,
  Cleo 6, Dev 3, Eli 0.
- **More players, more to win:** winning a war of six (18) is worth three won duels (3 × 6); 2nd of six (12) is worth
  two duels. Outlasting more rivals is harder, and takes longer.
- **Points never go down.** The *Ranking points* leaderboard (the game's main one) rewards both skill and playing often.
- **Only rated wars give points:** ranked duels, ranked wars of four, rated rooms and long-running rooms. Friendly
  rooms give none. A war is also not rated (no points, no rating change) if a player resigned or disconnected before
  everyone had made a few moves, or if the same two players have already finished five rated wars against each other
  in the last 24 hours (the farming guard).

### Rating

Your **rating** (Glicko-2, starting at **1500**) measures skill:

- A war counts as a **result against every other player** in it: finishing above someone is a win against them,
  finishing below them a loss. 2nd place in a war of six is five results: four wins (against those below) and one loss
  (against the winner).
- Beating higher-rated players gains more; losing to lower-rated ones costs more.
- While your rating is uncertain (your first wars, or after a long break) it moves faster: a new player's first war can
  move it by 100–250 points; later ones by about 10–30.
- The **Rating** leaderboard lists players with at least 5 rated wars. One rating covers every rated war (duels, wars of
  four, rooms of 2 to 6).

### Other leaderboards and stats

**Wars won** (1st places in any war) and **Territories conquered**. Your account page also shows wars played, lost,
top-three finishes (in wars of 3 or more), miracles cast and your largest army.

The website shows this explanation on the game's page and under every leaderboard of the game.

## Replays

Every finished war can be watched again on the website (**Matches**, or *Replay on the website* at the end of a war):

- the realm in the players' colours, with each player's pantheon die and the dice on every territory, and an arrow for
  each battle;
- **Play / Pause**, the **speed** (¼× to 8×), **one action** back or forward, **one turn** back or forward (⏪ ⏩), the
  start and the end, a slider, and the keyboard (Space, ←, →, Page Up/Down, Home, End);
- **What changed** in the current turn: every battle (the dice and the totals, conquered or repelled, what the gods
  did), miracles, the reinforcements, players falling or leaving, and the turn in all (each player's land and dice
  before and after);
- the list of turns (click one to jump to it), and the players with their gods, land, dice, place, points and rating.

## Storage

A war is stored as small as it can be: the server keeps the **seed** of the match and **one byte per action** (every
die, the deal and the reinforcements are recomputed from the seed when a war is restored after a restart or replayed).
For this game the server does not even keep the time between actions (a replay plays at the speed you choose).

| | Actions | Moves | The match row | The players' rows | With index entries |
|---|---:|---:|---:|---:|---:|
| Duel, small realm | 68 | 70 B | 393 B | 683 B | **≈ 1.4 KB** |
| War of three, small | 94 | 97 B | 417 B | 1,107 B | ≈ 2.0 KB |
| War of four, small | 134 | 138 B | 465 B | 1,465 B | **≈ 2.5 KB** |
| War of six, large (estimate) | ~350 | ~360 B | ~690 B | ~2,200 B | **≈ 4 KB** |

(Measured on a local server with `pg_column_size`; the war of six from simulated wars.) So **one war usually takes
about 1.5 to 4 KB**, of which the replay (the moves) is only **70 to 400 bytes**: the rest is the result itself (the
match, every player's place, rating before and after, and stats), which is kept in any case. A million wars take about
2–3 GB. The replay a viewer loads (about 100–500 KB of JSON, every position of the war) is built on request and never
stored.

**Admin switch — keep only results.** In the admin portal, *Games → Mythic Dice Wars → Stored matches*: *Keep only
results* drops the moves of every match that ends from then on (results, ratings and stats stay; such a war has no
replay). *Keep matches in full* turns replays back on. Matches still being played always keep their moves (they are
needed to resume after a restart). The same card shows what the finished matches of the last 30 days take on average.

## How it works

- **The server is the host.** The Go module `modules/mythicdicewars` is a port of `core/match_state.gd` (its catalog of
  gods is generated from `core/god_catalog.gd`: `go run gen_catalog.go …` in `rules/v1`). It deals the land, rolls every
  die, checks every action and decides the places. The realm is generated on the server with integer arithmetic only, so
  it is the same on every machine; the game draws the realm it is sent.
- **Actions** (WebSocket `MAKE_MOVE`): `gods` (before the war), `attack`, `miracle`, `end`. Every accepted action comes
  back to every player with its result in the game's own format (the battle as `MatchState.attack` returns it) and the
  whole public state after it.
- **The game** (`session/online.gd`, `session/online_war.gd`) mirrors that state into a `MatchState`, so the map, the
  player list, the battle screen and the hints are the same code as offline; `presentation/game_screen.gd` plays the
  announced actions one after another, and sends the player's clicks. Its own rules only decide what may be clicked: the
  server checks again (an end-to-end test checks it never refuses one).
- **Modes**: `ranked-duel`, `ranked-four` (matchmaking), `room` (rated, 2–6), `room-friendly`, `room-async`.
- **Server additions** for this game (useful to others): rooms of a chosen size (2–6), matchmaking for more than two
  players, a per-mode step cap, not storing action times, stats that count only in rated matches, a module's own
  explanation of its rankings on the website, the admin switch *keep only results*, and a bounded replay cache.

## Running and testing

```sh
# the server (../mytholore-game-server)
go test ./modules/mythicdicewars/        # wars of 2–6 to the end, restore from the packed moves, codec, sizes
go test ./internal/app -run DiceWars     # a rated room of three over WebSockets, points, replay, results only; a queue of four
python tools/dicewars-assets/build.py    # the website's dice and god portraits, from this game's art

# the game, against a local server (see the server's README to run one; set the game active in /admin/games)
godot --path . res://tests/online_e2e.tscn -- --server=http://127.0.0.1:8080 --out=<folder> --players=4
godot --headless --path . res://tests/check_scripts.tscn    # every script compiles (with the autoloads)
```

The end-to-end test registers new accounts, opens a war, plays one player through the real game screen and the others
as bots, and checks the places, the points and the replay.
