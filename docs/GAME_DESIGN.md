# Mythic Dice Wars — Game Design Document

> **Status:** Draft v1, written alongside the first proof of concept (POC).
> **Engine:** Godot 4.7, statically typed GDScript, Compatibility renderer (desktop, web, mobile).
> **Source brief:** [basic_game_specification.md](basic_game_specification.md).
> **Companion:** [art_prompts/](art_prompts/README.md) lists every picture and sound still to be made, one file per kind of asset, every prompt ready to paste.
>
> Markers: **[POC]** = built and playable now · **[MVP]** = needed for the first release · **[LATER]** = after release.
> Numbers in this document are the values in the code at the time of writing. The code is the source of truth (`core/match_state.gd`, `core/god_catalog.gd`).

---

## Contents

1. [Vision](#1-vision)
2. [Audience, platforms, sessions](#2-audience-platforms-sessions)
3. [The core loop](#3-the-core-loop)
4. [Rules](#4-rules)
5. [The gods](#5-the-gods)
6. [Pantheons and realms](#6-pantheons-and-realms)
7. [Computer opponents](#7-computer-opponents)
8. [Visual design: 2D isometric](#8-visual-design-2d-isometric)
9. [UI and navigation](#9-ui-and-navigation)
10. [Audio](#10-audio)
11. [Game modes and progression](#11-game-modes-and-progression)
12. [Balance](#12-balance)
13. [Technical design](#13-technical-design)
14. [The proof of concept](#14-the-proof-of-concept)
15. [Roadmap](#15-roadmap)
16. [Open questions](#16-open-questions)
17. [Glossary](#17-glossary)

---

## 1. Vision

**Mythic Dice Wars** is a quick, turn-based territory war on a floating island. Each player leads a pantheon, and armies are stacks of dice. You attack a neighbouring territory, both sides roll all their dice, and the higher total wins the land. At the end of your turn your largest connected realm sends reinforcements. Two gods tilt the odds. One is a steady patron. The other is mighty but flawed and wakes up mid-war.

**One-line pitch:** *Roll for the favour of the gods: a five-minute war of dice, territory and divine patrons, drawn as a hand-painted isometric diorama.*

### 1.1 Pillars

| Pillar | What it means | How we test it |
|---|---|---|
| **Learn in one battle** | The base rules fit on one screen: attack, compare totals, reinforce by your largest region. Gods add to these rules and never replace them. | A new player wins or loses a first war without opening Help. |
| **Every roll is a prayer** | Dice are the drama. Rolls are shown with the pantheon's own dice art and land with weight. The odds are always visible before you commit. | A battle reads at a glance: who rolled what, which bonuses applied, who won. |
| **A pantheon is a play style** | Primary god = identity, no price. Secondary god = a gamble with a real flaw. Two players with the same map play differently. | Each god changes at least one decision per turn: where to attack, when to stop, what to protect. |
| **A diorama you want to touch** | A 2D isometric look: raised land, cliffs, dice towers. It reads well on a phone held upright and on a 4K monitor. | Screenshots are recognisable as this game at thumbnail size. |
| **Short and complete** | A war takes 5–15 minutes. No meta-currency is needed to enjoy one. | The median POC war vs. 3 rivals ends in under 12 minutes. |

### 1.2 What makes it different

The core mechanic belongs to a well-loved genre: territory dice battles, with risk-style adjacency and sums of d6. We keep it because it is elegant. This game's identity comes from:

1. **The dual-god system** (§5): a boon without a price plus a boon *with* a price that wakes at a milestone. This changes the shape of a war halfway through.
2. **Favour and miracles** (§5.4): a second, slower resource that rewards fighting and losing alike, spent on active powers.
3. **Pantheon-themed dice and realms** (§6): 14 hand-made dice skins already exist, and each pantheon brings its own land, colours, frames and fonts.
4. **An isometric diorama presentation** (§8) with physical dice towers, instead of flat coloured blobs.

---

## 2. Audience, platforms, sessions

- **Audience:** strategy players who like short sessions (*Risk*, *Small World*, *Polytopia*, dice-battle games), and mythology fans. Age 10+, no gore.
- **Platforms:** Windows / macOS / Linux, the web (itch.io, own site), and Android / iOS (native export). One codebase and one UI that adapts to the screen (§9.4).
- **Session:** 5–15 minutes per war. Wars can be paused at any moment and are auto-saved **[MVP]**.
- **Monetisation (assumption):** premium, or free with cosmetic pantheon packs. No pay-to-win: a god bought later must be balanced against the free roster.

---

## 3. The core loop

```
          ┌──────────────────────────── your turn ────────────────────────────┐
          │                                                                    │
 start ──►│  (optional) cast a miracle ──► choose a territory with ≥ 2 dice    │
          │                                   │                                │
          │                                   ▼                                │
          │                     attack a neighbouring enemy ◄──┐               │
          │                                   │                │ again?        │
          │                  roll: both sides roll all dice    │               │
          │                  + gods' bonuses → higher wins ────┘               │
          │                                   │ no                             │
          │                                   ▼                                │
          │                 End turn: tribute (some gods) → reinforcements     │
          │                 = size of largest connected region (+ reserve)     │
          └────────────────────────────────────┬───────────────────────────────┘
                                               ▼
                         rivals take their turns (the same loop)
                                               │
                     last pantheon standing ◄──┘ (or the whole map)
```

**Mid-war beat:** after your 4th conquest your secondary god **awakens** (banner and sound). Its boon and its bane switch on together. This is the moment a war changes gear.

**Meta loop [LATER]:** wars → campaign chapters → unlock gods and realms → mastery challenges (§11).

---

## 4. Rules

### 4.1 The realm [POC]
- A realm is one island made of **cells**, grouped into **territories** of about 22 cells each. A war option chooses the cells:
  - **Isometric squares** (default): square cells drawn as 2:1 diamonds; 4 neighbours per cell.
  - **Hexagons**: flat-topped hex cells in offset columns ("odd-q"), drawn from the same slanted camera (squashed to 62% height) with the same cliffs and elevation; 6 neighbours per cell. Borders are smoother and territories touch more neighbours, so wars are a little more open.
- Two territories are **neighbours** when any of their cells share an edge. Water separates nothing: there is only one island, and every territory can be reached.
- Sizes: **Small 18**, **Medium 28**, **Large 40** territories.
- The island's outline follows the screen. A wide screen gets a wide island (aspect about 1.7) and a phone held upright gets a tall one (about 0.85). The map then fills the screen without scrolling.
- Generation: a noisy ellipse of land (only its largest connected part is kept), seeds spread by farthest-point sampling, then territories grow from the seeds one cell at a time. Usually the smallest territory grows next, so sizes stay even. Every territory also gets a random **elevation** of 0–2 steps (looks only). Same seed → same map.

### 4.2 Setup [POC]
- 2–8 players. **Turn order is shuffled.**
- Territories are dealt evenly at random. Every territory starts with 1 die.
- Each player then gets the same dice budget: ⌈territories ÷ players⌉ × 3 in total, scattered at random over their own land (at most 8 per territory).
- **Head start** (war option *Turn order: Balanced*, the default). Moving first is a large edge, so every later player gets extra dice before the first turn:

  head start of the player moving k-th of n = round(0.66 × (k − 1) ÷ (n − 1) × their reinforcement)

  "Their reinforcement" is what they would get for ending a turn right then (their largest region plus god bonuses, §4.4). The dice are placed exactly like reinforcements (border-first for the gods that do that), and what does not fit goes to the reserve. The first player gets none; the last gets about two thirds of one turn's dice. With 4 players the shares are 0, 22%, 44% and 66%. *Classic* turns it off. Why and how it was tuned: §12.4.

### 4.3 Attacking [POC]
1. Choose one of your territories with **at least 2 dice**, then a **neighbouring enemy** territory.
2. The attacker rolls **all** the attacking territory's dice. The defender rolls all of theirs.
3. **Attack total** = sum + attack bonuses. **Defence total** = sum + defence bonuses (§5).
4. **Higher total wins. Ties go to the defender**, unless a god says otherwise.
5. **Attacker wins:** the territory changes owner. All dice but one move in, and one die stays behind.
   **Defender wins:** the attacking territory is left with 1 die.
6. You may attack as often as you like. Some banes limit this.
7. A player with no territories left is **eliminated**.

**Odds.** The chance to win is shown when hovering a target. Plain dice, no bonuses:

| attacker ↓ / defender → | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| **2** | 84% | 44% | 15% | 4% | 1% | <1% | <1% | <1% |
| **3** | 97% | 78% | 45% | 19% | 6% | 1% | <1% | <1% |
| **4** | >99% | 94% | 74% | 46% | 22% | 8% | 3% | 1% |
| **5** | >99% | 99% | 91% | 72% | 46% | 24% | 10% | 4% |
| **6** | >99% | >99% | 98% | 88% | 70% | 47% | 26% | 12% |
| **7** | >99% | >99% | 99% | 96% | 86% | 69% | 47% | 27% |
| **8** | >99% | >99% | >99% | 99% | 95% | 84% | 67% | 47% |

*(Ties to the defender, so equal stacks are slightly below 50%. Exact values come from `DiceOdds`.)*

### 4.4 Ending a turn: reinforcements [POC]
1. **Tribute** (only some banes): the largest stack loses N dice (never below 1).
2. **Reinforcements** = the number of territories in your **largest connected region**, + reinforcement bonuses, × multipliers (rounded down, at least 0).
3. Add your **reserve** (dice that did not fit last time).
4. Place dice one at a time on random territories that are not full. A god may send them to **border** territories first.
5. What does not fit goes to the **reserve** (max 30). Some banes remove the reserve, and then the extra dice are lost.

### 4.5 Victory [POC]
- **Domination:** the last player with territories wins. In a single-player war, the war ends as soon as the human is eliminated.
- **[MVP] Concede and fast-forward:** when only computer players are left, offer "watch the end" at maximum speed or "skip to result".
- **[LATER] Alternative goals** (war options): *Hold the Omphalos* (own the central territory for 3 of your turns), *Majority* (own 60% of the map at the end of round 20).

### 4.6 Constants

| Constant | Value | Where |
|---|---|---|
| Most dice per territory | 8 (+/- gods) | `MatchState.BASE_MAX_DICE` |
| Reserve cap | 30 | `MatchState.RESERVE_CAP` |
| Favour cap | 12 | `MatchState.FAVOR_CAP` |
| Conquests to wake the secondary god | 4 | `MatchState.AWAKEN_CONQUESTS` |
| Average starting dice per territory | 3 | `MatchState.START_DICE_PER_TERRITORY` |
| Head start of the last player (share of one reinforcement) | 0.66 | `MatchState.HEAD_START_SHARE` |
| Cells per territory | 22 | `MapGenerator.CELLS_PER_TERRITORY` |

### 4.7 War options

| Option | Values | Status |
|---|---|---|
| Players | 2–8 | [POC] |
| Realm size | Small / Medium / Large | [POC] |
| Board | Isometric squares / Hexagons | [POC] |
| Rivals' skill | Novice / Warlord / Strategist | [POC] |
| Secondary god | Wakes after 4 conquests / Awake from the start | [POC] |
| Turn order | Balanced (head start for later players, §4.2) / Classic | [POC] |
| Seat setup | each seat: Human (hotseat) / Computer / Closed | [MVP] |
| Teams | free-for-all / 2v2 / 2v2v2 / 4v4 | [LATER] |
| Fog of war | Off / On (see only your land and its neighbours, §4.8) | [POC] |
| Turn timer | off / 30 s / 60 s | [LATER] (online) |
| Seed | random / typed (shareable map codes) | [MVP] |

### 4.8 Fog of war [POC]
A war option, **off by default**. It makes wars less predictable: you plan from what your borders tell you, not from a full view of the board.

- **What a player sees** (`MatchState.can_see(p, t)`): their own territories and every territory next to one of them, with owner and dice. Everything else is hidden. The map outline, territory borders and elevation stay visible, so you know the shape of the realm but not who holds it. A fallen player sees everything.
- **The fog moves with the front:** conquering a territory reveals its neighbours; losing one may hide its surroundings again.
- **What stays public:** how many lands each player holds (the player list and the leader's crown), every player's gods and favour, and awakening and elimination banners.
- **What is hidden:** for other players, their dice total, reinforcements, reserve and head start in the player list. On the map, hidden territories have no colour, dice, pennant or effects.
- **Battles:** shown only if the player sees the attacking or the defending territory. Battles fought entirely in the fog are not shown at all (no arrow, no sound).
- **Miracles** can only target a territory the caster can see.
- **The computer players are bound by the same rule.** Attacks always go to neighbours (visible by definition). Smite considers only enemy territories touching its land. Bless and ward only consider its own. The one place an AI looks further is the Strategist's exposure check (enemy stacks next to a territory it is about to conquer). There, unseen territories are assumed to hold the average enemy stack it can see (`AiPlayer._seen_dice`). Territory counts (for "attack the leader") are public, as for the human.
- **Test:** `sim_test.gd` plays a quarter of its wars under fog. A blindness check scrambles the dice on every territory the current AI cannot see and requires its next attack and miracle to stay exactly the same (about 2,000 decisions per run).
- **Drawing:** hidden territories are drawn in a mist grey mixed into the realm's ground colour, slowly brightening and darkening in drifting bands.

**Later:** remember the last seen state of a territory ("last seen: 4 dice, round 6") instead of hiding it completely; scouting gods (for example Heimdall or Horus) who see further.

---

## 5. The gods

### 5.1 Two gods per player
Each player picks a **pantheon** and then two of its gods:

| | Primary god | Secondary god |
|---|---|---|
| **Role** | The patron: defines your play style | The gamble: great power, real flaw |
| **Price** | None (a pure boon) | A **bane** that is active whenever the boon is |
| **When** | From the first turn | **Wakes after your 4th conquest** (default), or from the start (war option) |
| **Budget** | ~1 "power point" (§12.2) | ~2 power points of boon, ~1 point of bane |

**Why the awakening milestone:** it rewards aggression early, makes the mid-war change of pace visible ("Ares awakens!"), and gives a struggling player a reason to push for that 4th conquest. A player that turtles never wakes their secondary god. For a defensive secondary (Hel, Ereshkigal), that is a meaningful choice.

**Rules for gods**
- A boon or bane only changes numbers and permissions that already exist (bonuses, caps, limits, where dice go). It never adds a new kind of turn, so the rules stay learnable.
- Effects stack: numbers add up, flags combine with "or", multipliers multiply, limits take the lowest value.
- Each pantheon has **3 primary + 3 secondary** gods in the POC. Twelve per pantheon is the goal for release (the portraits already exist for 7 pantheons, see §6).
- **[LATER] Crossover wars:** pick a primary and a secondary from *different* pantheons (Zeus + Loki). This is a war option, off by default, because pantheon identity matters for the look.

### 5.2 Effect vocabulary [POC]
Every god is **data** (`core/god_catalog.gd`). A boon or bane is a dictionary of these keys. A new god needs no code unless it needs a new key.

| Key | Meaning | Typical use |
|---|---|---|
| `attack_bonus` | +N to every attack total | war gods |
| `defense_bonus` | +N (or −N) to every defence total | protectors / reckless banes |
| `first_attack_bonus` | +N to the first attack of each turn | opening strikes |
| `underdog_bonus` | +N when attacking a larger stack | tricksters |
| `full_stack_bonus` | +N when attacking from a full stack | heavy hitters |
| `reroll_ones_attack` / `_defense` | dice showing 1 are rolled once more | wisdom, luck |
| `min_attack_face` | attacking dice never show below N | sun gods |
| `attack_wins_ties` / `defense_loses_ties` | tie rules | tricksters / their banes |
| `conquest_bonus` | +N dice on the **first** territory conquered each turn | conquerors |
| `defend_reward` | +N dice on a territory that held | hearth gods |
| `max_dice_bonus` | stack cap 8 ± N | builders / "travels light" |
| `reinforce_bonus` / `reinforce_mult` | more / fewer reinforcements | harvest gods / famine banes |
| `smart_reinforce` | reinforcements go to borders first | rulers |
| `no_reserve` | dice that do not fit are lost | restless banes |
| `max_attacks` | at most N attacks per turn (counted from the moment the god wakes, so waking never ends a turn at once) | oath banes |
| `tribute` | the largest stack loses N dice each turn | sacrifice banes |
| `hubris` | after a failed attack, another of your stacks loses N | wrath banes |
| `no_attack_stronger` | may not attack a larger stack | patience banes |
| `favor_bonus` | +N whenever favour is gained | priestly gods |
| `miracle` | an active power `{kind, amount, cost}` | see §5.4 |

**Planned keys [MVP/LATER]:** `steal_on_conquest` (take 1 die from a neighbour), `fortify` (move dice between two of your neighbouring territories once per turn), `sea_raid` (attack across one water gap), `curse` (an enemy territory cannot reinforce next turn), `swap` (exchange two stacks), `reveal` (fog of war), `rebirth` (a territory lost returns its dice to the reserve).

### 5.3 Roster (POC)

These tables are generated from `core/god_catalog.gd` (after the second balance pass, §12).

#### Greek

| God | Role | Boon | Bane |
|---|---|---|---|
| **Zeus**, King of Olympus | Primary | **Thunderbolt** — Miracle (2 favour): strike an enemy territory, destroying 2 of its dice. | — |
| **Athena**, Strategist of Olympus | Primary | **Aegis** — +2 to the defence of every territory you hold. | — |
| **Demeter**, Mother of the Harvest | Primary | **Bountiful Harvest** — +2 reinforcement dice every turn. | — |
| **Ares**, God of War | Secondary | **Bloodlust** — +2 to every attack. | **Reckless** — -1 to the defence of every territory you hold. |
| **Hermes**, Messenger of the Gods | Secondary | **Fleet-footed** — Your attacks win ties, and reinforcements rush to your borders. | **Travels Light** — Your territories hold at most 6 dice. |
| **Hades**, Lord of the Underworld | Secondary | **Army of Shades** — +1 to every attack, +1 die on the first territory you conquer each turn, and +1 favour whenever you gain favour. | **Barren Fields** — -2 reinforcement dice each turn. |

#### Norse

| God | Role | Boon | Bane |
|---|---|---|---|
| **Odin**, The All-Father | Primary | **Wisdom of the Runes** — Your dice that show 1 are rolled again, in attack and defence. | — |
| **Thor**, The Thunderer | Primary | **Opening Thunder** — +5 to the first attack of each turn, +1 to every other. | — |
| **Frigg**, Queen of Asgard | Primary | **Hearth and Home** — A territory that holds against an attack gains 1 die, and +1 to every defence. | — |
| **Tyr**, God of the Just War | Secondary | **Just War** — +1 to every attack and +1 to every defence. | **Bound by Oath** — At most 4 attacks per turn. |
| **Loki**, The Trickster | Secondary | **Trickery** — +3 when attacking a larger army, and your attacks win ties. | **Betrayal** — Your defences lose ties. |
| **Hel**, Queen of the Dead | Secondary | **Cold Halls** — +1 to every defence, and a territory that holds gains 1 die. | **Cold Patience** — You may not attack a territory with more dice than yours. |

#### Egyptian

| God | Role | Boon | Bane |
|---|---|---|---|
| **Ra**, The Sun Who Sails the Sky | Primary | **Sun's Glare** — Your attacking dice never show a 1. | — |
| **Isis**, Mistress of Magic | Primary | **Breath of Life** — Miracle (4 favour): add 3 dice to one of your territories. | — |
| **Ptah**, The Divine Builder | Primary | **Master Builder** — Your territories hold up to 9 dice, and +1 reinforcement die. | — |
| **Sekhmet**, The Lioness | Secondary | **Rampage** — +2 to every attack. | **Unquenchable Wrath** — Every failed attack costs 2 dice from another of your territories. |
| **Set**, Lord of the Red Desert | Secondary | **Desert Storm** — +1 to every attack, and +1 die on the first territory you conquer each turn. | **Chaos Tithe** — At the end of each turn your largest stack loses 2 dice. |
| **Anubis**, Guardian of the Scales | Secondary | **Weigher of Hearts** — +1 to every defence, and +2 favour whenever you gain favour. | **Patient Judge** — At most 2 attacks per turn. |

#### Chinese

| God | Role | Boon | Bane |
|---|---|---|---|
| **Jade Emperor**, Ruler of Heaven | Primary | **Heavenly Mandate** — +2 reinforcement dice, and reinforcements go to your borders first. | — |
| **Guanyin**, She Who Hears the World | Primary | **Mercy** — Miracle (1 favour): one of your territories gets +5 defence until your next turn. +1 to every defence, and a territory that holds gains 1 die. | — |
| **Guan Yu**, The Loyal General | Primary | **Loyal Blade** — +1 die on the first territory you conquer each turn, and +2 reinforcement dice. | — |
| **Sun Wukong**, The Monkey King | Secondary | **Seventy-two Transformations** — Attacking 1s are rolled again, +2 against larger armies, and attacks win ties. | **Restless** — No reserve (extra dice are lost), and -2 reinforcement dice each turn. |
| **Nezha**, The Third Lotus Prince | Secondary | **Wind-Fire Wheels** — +4 to the first attack of each turn, +2 when attacking from a full stack. | **Child's Temper** — -1 to the defence of every territory you hold. |
| **Hou Yi**, The Archer Who Shot the Suns | Secondary | **Nine Arrows** — Miracle (2 favour): strike an enemy territory, destroying 3 of its dice. | **Exile** — At the end of each turn your largest stack loses 1 die. |

#### Mayan

| God | Role | Boon | Bane |
|---|---|---|---|
| **Itzamna**, Lord of the Heavens | Primary | **Celestial Scribe** — Attacking 1s are rolled again, and +1 favour whenever you gain favour. | — |
| **Chaak**, Bringer of Rain | Primary | **Life-giving Rain** — Miracle (2 favour): add 2 dice to one of your territories. | — |
| **Ix Chel**, Lady of the Moon | Primary | **Moon's Tide** — +1 reinforcement die, and defending 1s are rolled again. | — |
| **Kukulkan**, The Feathered Serpent | Secondary | **Serpent Wind** — +2 to every attack, and reinforcements go to your borders first. | **Blood Offering** — At the end of each turn your largest stack loses 1 die. |
| **Huracan**, Heart of the Sky | Secondary | **Great Flood** — Miracle (2 favour): strike an enemy territory, destroying 2 of its dice. +1 to every attack. | **Uprooted** — -1 to the defence of every territory you hold. |
| **Ah Puch**, Lord of Xibalba | Secondary | **Harvest of Souls** — +1 to every attack, +1 die on the first territory you conquer each turn, +2 favour whenever you gain favour. | **Withering** — -2 reinforcement dice each turn. |

#### Mesopotamian

| God | Role | Boon | Bane |
|---|---|---|---|
| **Marduk**, Slayer of Tiamat | Primary | **Champion of the Gods** — +1 to every attack. | — |
| **Enki**, Lord of the Sweet Waters | Primary | **Waters of Life** — +1 reinforcement die, and +1 favour whenever you gain favour. | — |
| **Utu**, The Sun of Justice | Primary | **Chariot of the Sun** — +2 when attacking from a full stack, and defending 1s are rolled again. | — |
| **Inanna**, Queen of Heaven | Secondary | **Morning Star** — +2 to every attack, and +1 die on the first territory you conquer each turn. | **Descent** — -1 to every defence, and no reserve (extra dice are lost). |
| **Ereshkigal**, Queen of the Great Below | Secondary | **Seven Gates** — +3 to every defence. | **Land of No Return** — At most 2 attacks per turn. |
| **Tiamat**, Mother of Monsters | Secondary | **Primordial Sea** — Your territories hold up to 10 dice, and +2 reinforcement dice. | **Brood Hunger** — At the end of each turn your largest stack loses 1 die. |

#### Yoruba

| God | Role | Boon | Bane |
|---|---|---|---|
| **Shango**, King of Thunder | Primary | **Thunderstones** — +1 to every attack (+3 on the first each turn), and your attacks win ties. | — |
| **Yemoja**, Mother of the Waters | Primary | **Ocean's Embrace** — +2 reinforcement dice, and a territory that holds against an attack gains 1 die. | — |
| **Obatala**, Father of the White Cloth | Primary | **Shaper of the World** — +1 to every defence, +1 reinforcement die, and reinforcements go to your borders first. | — |
| **Ogun**, Lord of Iron | Secondary | **Iron Path** — +2 to every attack, +1 more when attacking from a full stack. | **Restless Blade** — -1 to the defence of every territory you hold. |
| **Oya**, Queen of the Storm | Secondary | **Whirlwind** — Miracle (1 favour): strike an enemy territory, destroying 2 of its dice. +1 favour whenever you gain favour. | **The Wind Turns** — -1 to the defence of every territory you hold. |
| **Esu**, Keeper of the Crossroads | Secondary | **Crossroads** — +3 when attacking a larger army, and attacking 1s are rolled again. | **The Trickster's Price** — After a failed attack, another of your territories loses 1 die. |

### 5.4 Favour and miracles [POC]
- **Favour** is gained by **fighting**: +1 for every attack you make (win or lose) and +1 whenever you **lose** a territory ("faith grows in defeat"). Gods can add to every gain. Cap 12.
- **Miracles** are active powers granted by some gods. They cost favour and can be used **once per turn per god**, at any point in your turn.

| Kind | Effect | Gods (POC) |
|---|---|---|
| `smite` | an enemy territory loses N dice (never below 1) | Zeus (2 for 2), Hou Yi (3 for 2), Huracan (2 for 2), Oya (2 for 1) |
| `bless` | one of your territories gains N dice (up to the cap) | Isis (3 for 4), Chaak (2 for 2) |
| `ward` | one of your territories gets +N defence until your next turn | Guanyin (+5 for 1) |

**[MVP] Divine Miracles as consumables** (from the brief's roadmap): favour can also buy one-off **relics** between wars or from shrines on the map (special territories). Examples: *Golden Fleece* (reroll one battle), *Pandora's Jar* (every enemy stack touching yours loses 1 die), *Mead of Poetry* (see the next 3 AI moves). Shrine territories should give +1 favour per turn to their owner, which creates objectives on the map.

### 5.5 How the gods appear to the player
- **Choosing:** god cards show the portrait, name, epithet, the boon in green and the bane in red. Selection is framed in the realm's accent colour and the other cards are dimmed.
- **In war:** both portraits sit beside the player's name. An asleep secondary god is darkened, with a tooltip saying how many conquests remain. Hover a portrait to read its powers.
- **Awakening:** a banner ("Ares awakens for You!"), a sound, and the portrait lights up **[POC]**. Later: a full-screen portrait flash and a voice line **[LATER]**.
- **Battle breakdown:** the battle panel lists every bonus that applied ("Divine might +2, Ward +5") **[POC]**.

---

## 6. Pantheons and realms

### 6.1 Assets on hand

| Pantheon | Dice skin | God portraits (Tile Shifter) | UI theme (Tile Shifter) | In POC |
|---|---|---|---|---|
| Greek | ✔ marble and gold | 12 | ✔ | ✔ |
| Norse | ✔ slate and iron | 12 | ✔ | ✔ |
| Egyptian | ✔ sandstone and lapis | 12 | ✔ | ✔ |
| Chinese | ✔ jade and bronze | 12 | ✔ | ✔ |
| Mayan | ✔ jungle stone | 12 | ✔ | ✔ |
| Mesopotamian | ✔ fired clay | 12 | ✔ | ✔ |
| Yoruba | ✔ carved iroko and bronze | 12 | ✔ | ✔ |
| Aztec, Celtic, Inca, Inuit, Japanese, Persian, Polynesian, Slavic | ✔ | ✘ (to make) | ✘ (to make) | — |

Yoruba became playable as soon as its dice arrived (the portraits and theme already existed). Every dice skin is a 3 × 2 sheet of faces read as **values 1–6**. The faces are **count-coded**: 1 emblem, 2 crossed weapons, 3 creatures, 4 pillars, 5 objects, 6 rays. The value can be read without numbers. `tools/prepare_assets.py` cuts them out.

### 6.2 What a pantheon brings
1. **Gods:** 3 + 3 in the POC, 12 at release (6 primary, 6 secondary).
2. **Dice skin:** used for that player's dice on the map and in battles.
3. **Realm look:** used when it is the human's pantheon. It sets the menu theme (background, frames, buttons, title font, weather particles) and the **terrain palette** of the island (top, cliff and sea colours, `Looks.TERRAIN`).
4. **Music theme [MVP]** and **voice barks [LATER]**.

### 6.3 Planned gods for the next pantheons (names only, design later)
- **Aztec:** Huitzilopochtli, Quetzalcoatl, Tlaloc / Tezcatlipoca, Mictlantecuhtli, Xipe Totec.
- **Celtic:** the Dagda, Brigid, Lugh / the Morrígan, Cernunnos, Manannán.
- **Japanese:** Amaterasu, Susanoo, Hachiman / Raijin, Inari, Izanami.
- **Slavic:** Perun, Mokosh, Svarog / Veles, Morana, Stribog.
- **Inca, Inuit, Persian, Polynesian:** Inti, Pachamama, Viracocha / Sedna, Sila, Tulugaak / Ahura Mazda, Mithra, Anahita / Māui, Pele, Tangaroa.

---

## 7. Computer opponents

### 7.1 Levels [POC]

| Level | Behaviour |
|---|---|
| **Novice** | Attacks when its chance is ≥ 50%, with noise. Sometimes stops early. Ignores structure. |
| **Warlord** | Needs ≥ 57%. Prefers attacks that **join its regions** (bigger reinforcements), hits the leader, picks off 1-die stacks. |
| **Strategist** | Needs ≥ 60%. Also weighs **exposure** (how many strong enemy stacks would border the conquered land and the emptied source), and keeps big stacks on the borders of its main region. |

All levels read the real odds with every god's effect included (`DiceOdds.attack_chance`). Under fog of war they use only what they can see (§4.8). They use full stacks before they would waste reinforcements, and cast miracles with simple targeting: smite the strongest enemy stack touching their land, bless or ward their most threatened border.

**Anti-stall:** if a computer player finds no good attack, but its stacks are 85% full or the war has passed round 60, it takes its best fight above 30%. After round 80 it takes any fight. Without this, about 4% of AI-only wars between defensive gods never ended.

### 7.2 Planned [MVP/LATER]
- **Personalities from gods:** Ares-led AIs are aggressive, Athena-led AIs turtle and counter. Done by adjusting the score weights per god.
- **Look-ahead:** a one-ply estimate of next turn's reinforcement and counter-attacks for Strategist. A Monte-Carlo option for a "Titan" difficulty.
- **Kingmaker guard:** AIs gang up a little on a runaway leader. This is already a small bonus for hitting the leader.
- **Tells:** a short bubble over an AI's capital ("Thor eyes your border") to give it personality.

---

## 8. Visual design: 2D isometric

### 8.1 Art direction
A **hand-painted diorama**: a floating island of raised land, seen from a fixed isometric camera, against the realm's painted backdrop. Colours belong to the realm. Ownership is shown by a strong tint on the land, so the board still reads at a glance. Dice are physical, carved objects (the existing skins), not flat icons.

- Projection: **2:1 dimetric** (classic "isometric" pixel ratio). A cell's diamond is 32 × 16 world units, an elevation step is 5 units, and the island is 14 units thick.
- Light from the **top left**. The top faces are lit, the left faces at 80% and the right faces at 62%.
- Everything is 2D: Polygon2D-style drawing now, sprites later. No 3D nodes, so it runs on low-end phones and in the browser.

### 8.2 The map [POC → MVP]
**Now (POC, all drawn in code):**
- Each cell is a raised block: a top diamond in the owner's colour (60% player colour over the realm's ground colour, with ±4.5% brightness noise per cell) and two cliff faces in the realm's cliff colour, darkening downwards.
- Territory borders are dark lines on the top faces, the coast is a light rim, and the selection is outlined in gold. Elevation gives every territory its own plateau.
- Draw order: cells sorted back to front by their screen position (y, then x). Dice stacks are drawn after the terrain, also back to front.
- Both boards share one drawing routine: a cell is its top outline (a diamond, or a hexagon flattened to 62%), the edges facing the camera become cliffs (2 for a diamond, 3 for a hexagon, each shaded by direction), and every edge knows which neighbour lies across it, for borders and the coast.
- A soft shadow of the island falls on the backdrop.

**Flat colours by design.** Painted ground tiles, cliffs and props were tried with the Greek art and removed: they added little to a board that is read for colour and numbers, and every new realm would have needed some 30 more pictures. The map stays code-drawn, so a new pantheon needs only its dice, portraits and menu theme.

**Markers on the map [POC]:** each player's capital (the strongest territory of their largest region, where reinforcements come from) flies a waving pennant in their colour, drawn in code.

**Later:** an animated sea or cloud ring around the island (a shader on a large polygon).

### 8.3 Dice and battles
**On the map [POC].** Every die is a small isometric cube built from the skin's face pictures: three parallelograms (top, left, right) each textured with a face, plus a dark body behind to fill the rounded corners. Dice stack in columns of up to 4, and up to 3 columns for stacks of 9–10. A few faces per stack are chosen at random but fixed per stack, so the stacks look varied and stay stable.

**Clutter control [POC]**, as asked in the brief:
- A **count badge** in the owner's colour beside every stack (can be turned off in Settings; always shown for stacks over 4).
- When zoomed out so far that a die would be under 12 px, stacks **collapse to a single die and the badge**. Hovering or selecting a territory shows its **full tower** again.
- Zoom (wheel, pinch, trackpad) and pan (drag) make a detailed view available on every screen.

**Battles [POC].**
- **Over the whole screen.** The map dims, the attacker slides in from the left and the defender from the right (on a tall screen from the top and the bottom), each with their pantheon's **dice tower** (all 7 pantheons have their own; a new pantheon borrows another's until its art exists), and "VS" pops in between. Tower and tray are scaled to the room. The pieces of each tower fit together by a small layout (`assets/towers/<pantheon>/layout.json`, written by the asset tool): where the dice row sits on the tray floor, how wide it spreads, the tray's size, and whether the tray front is drawn over the dice (left out where it does not match the tray's shape; for a tray painted straight on, the front can be cut from the tray picture itself, so it fits exactly); the dice are as big as the tray allows: about 100 px for up to three dice on a laptop screen, one row up to five, two staggered rows for more. The dice tumble out of the tower's arch into the tray (0.8 s at normal speed; battle speed 1×, 2× or 6×, computer turns at least 2×) and settle. **Both rolls stay in view**: the losing side's dice are not hidden or destroyed. Then everything fades back to the map, where the outcome plays (dust, a flash, "+N" / "−N"). An arc arrow on the map links attacker and defender.
- **How the gods changed the roll.** Under each tray the total is taken apart: the sum of the dice, then every bonus or penalty with the god and power behind it ("+2 Ares · Bloodlust", "−1 Ares · Reckless", "+5 Guanyin · Mercy (ward)", "+4 Thor · Opening Thunder (first attack)"), then what the gods did to the dice themselves ("Ra · Sun's Glare: no 1s", "Odin · Wisdom of the Runes: 1s rolled again"). A die whose 1 was rolled again has a gold frame and a small "1→". Below the verdict: how a tie was decided and what the gods did after the battle ("Guan Yu · Loyal Blade: +1 die on the conquered land", "Frigg · Hearth and Home: +1 die for holding", "Sekhmet · Unquenchable Wrath: another territory loses 2"). The same bonuses are listed in the status bar when hovering a target, before attacking.
- **How long the result stays (Settings, "Battle result shown"):** Brief 0.8 s, Normal 1.8 s, Long 3.5 s, or **Until I press Continue** (also a click on the map, Enter or Space). The battle screen opens for the player's own attacks. **The computer's attacks**, on the player as well as between rivals, are shown only on the map: the arc arrow for 1 s (whatever the battle speed), then the outcome; the rolls are not shown. "Show the computer's battles" (Settings, off by default) puts them on the battle screen too (attacks on the player hold like the player's own; battles between rivals stay brief).
- On the map after a battle: a conquered territory flashes gold and the new owner's colour washes across it from the attacker's side. Dust puffs on the stack that was reduced to 1.

### 8.4 VFX list

| Event | Effect | Status |
|---|---|---|
| Conquest | gold flash, colour wash, dust burst | flash [POC] |
| Repelled | dark flash on attacker, defender stack bounces | flash [POC] |
| Reinforcement | "+N" floats, dice drop onto stacks one by one | floats [POC] |
| Tribute / hubris | "−N" floats in red, a die cracks and fades | floats [POC] |
| Smite | lightning / arrows / flood per god from the sky | flash [POC] |
| Bless | rising golden motes, die appears | flash [POC] |
| Ward | translucent dome on the territory until it ends | ring on badge [POC] |
| Awakening | full-screen portrait flash, the god's colour floods the HUD frame | banner [POC] |
| Elimination | the fallen player's land greys, a banner | banner [POC] |
| Victory / defeat | confetti or ash, banner (from Chasm of Knights) | [POC] |

### 8.5 Colour and accessibility
- Player colours: crimson, azure, emerald, gold, violet, teal, amber, rose (`Looks.PLAYER_COLORS`).
- **[MVP] Colour-blind support:** a per-player **emblem** (from the pantheon's dice face 1) drawn on the count badge, plus an optional *pattern overlay* (stripes, dots, chevrons) on the land.
- Text never relies on colour alone: the battle panel also says "Conquered!" / "Repelled!".

---

## 9. UI and navigation

The menus follow **Chasm of Knights**: everything is built in code with the shared helpers (`Ui`, `UiTheme`, `MenuBackdrop`, `IconButton`, `GameLayout`, `EndOverlay`), in one framed column centred on a painted, weather-animated realm backdrop. Primary actions use round medallion buttons (◀ Back, ▶ Start), and screens fade in. The theme (frames, buttons, title font, weather) comes from the **realm of the pantheon you chose**, and changes live when you pick another pantheon.

### 9.1 Screen flow

```
Boot → Splash (key art + title, tap to skip)
  → Main Menu
       ├─ New War ─► Pantheon & options ─► Choose your gods ─► War ─► Result ─► (New war | Main menu)
       ├─ Quick War ─────────────────────────────────────────► War   (last choices)
       ├─ Campaign [LATER] ─► Era map ─► Chapter briefing ─► War ─► Chapter result
       ├─ Settings (sound, volume, battle speed, how long battle results stay, dice counts, full screen)
       ├─ How to play (rules + every god)
       ├─ Credits
       └─ Quit (desktop only)
```

### 9.2 Screens

| Screen | Content | Status |
|---|---|---|
| **Splash** | The key art over the whole screen (the wide picture, or the tall one on a screen held upright), standing still; the title and subtitle fade in over the sky at the top, on a soft shadow. 3 s, or click to skip. Without the key art: the realm painting. | [POC] |
| **Main menu** | Title, current pantheon and gods, New War, Quick War, Book of the Gods, icon row (Settings, Help, Credits, Quit). | [POC] |
| **New War** | 7 pantheon tiles (die face + name, framed when chosen; picking one re-themes the screen; the tiles grow with the text), Players, Realm size, Board, Rivals, Secondary god timing, Turn order, Fog of war. On a wide screen the tiles stand beside the options (4, 3 or 2 to a row, whatever fits), so the panel fits a laptop window; on a narrow one above them (the panel scrolls). ◀ / ▶. | [POC] |
| **Choose your gods** | Two rows of god cards (portrait, epithet, boon, bane), the awakening note. ◀ / ▶ Start. | [POC] |
| **Book of the Gods** | To help choose a pantheon (from the main menu, or the book button in New War). A tab per pantheon; the realm's name and a few words about it; its 3 primary and 3 secondary gods as portraits. The chosen god: a large portrait, name in the realm's title font, epithet and role, boon and bane as in a war, then their story and a "did you know?" (scrolls where the screen is short). Browsing a pantheon shows its realm's look; leaving puts the player's own pantheon back. **Play with <god>** takes that pantheon and god into New War. The stories come from Tile Shifter's legends: `python tools/import_lore.py` copies them into `core/god_lore.gd`. | [POC] |
| **War** | §9.3 | [POC] |
| **Result** | Banner + confetti/ash over the map; New war / Main menu. [MVP] adds stats: rounds, conquests, biggest roll, luck meter (rolled vs expected), a "war chronicle" timeline. | [POC] basic |
| **Pause [MVP]** | Resume, Rules, Settings, Concede, Save & quit. | — |

### 9.3 The war screen
**Landscape (desktop, tablet, phone held sideways):**
```
┌────────────────────────────── status bar ───────────────────────────────┐
│  "Attack a highlighted neighbour…"     Your gods: Zeus — Thunderbolt · … │
├──────────────────────────────────────────────────┬──────────────────────┤
│                                                  │ ▣ Utu   [P][S]       │
│                                                  │   Lands 9 · Dice 21  │
│                isometric realm map               │ ▣ You   [P][S]       │
│          (zoom / pan, dice towers, badges)       │ ▣ Isis  [P][S]       │
│                                                  │ ▣ Jade Emperor …     │
│            ┌──── battle panel ────┐              │                      │
│            │ You 20   vs   Enki 4 │              │                      │
│            └──────────────────────┘              │                      │
├──────────────────────────────────────────────────┴──────────────────────┤
│        [Thunderbolt (2 / 3 favour)]  [Re-centre]  [Leave]  [End turn +5] │
└──────────────────────────────────────────────────────────────────────────┘
```
**Portrait (phone held upright):** the status bar at the top, the map in the middle (a taller island is generated), and the buttons at the bottom within thumb reach. The player list is hidden below 700 px width in the POC. **[MVP]** shows it as a horizontal strip of pills (colour, dice count, crown on the leader) under the status bar, which opens a sheet on tap.

**Interaction**
| Action | Mouse | Touch |
|---|---|---|
| Choose attacker | click own territory (≥ 2 dice) | tap |
| Attack | click a highlighted neighbour | tap |
| Odds preview | hover target | long-press target [MVP] |
| Cancel | right-click, click empty sky, click the attacker again | tap the attacker again / sky |
| Zoom | wheel / trackpad pinch | pinch |
| Pan | drag (when zoomed) | drag |
| Miracle | button → click a target (targets glow blue) | same |
| End turn | button (shows "+N" = reinforcements you will get), [MVP] Space | button |

Feedback: the attackable neighbours pulse orange, the selection is lifted and outlined in gold, and the hover target shows "5 dice against 3 — 91% chance to win" in the status bar.

### 9.4 Responsive rules (from Chasm of Knights)
- Window minimum on desktop: 480 × 640. Phones get a content scale from their DPI (`AppWindow`).
- Below 720 px wide, menus stack. Below 600 px tall with a wide aspect, game screens put the board beside the controls (`GameLayout`).
- Safe areas (notches, gesture bars) are respected. The Android back button returns to the menu.

### 9.5 Localisation [MVP]
All strings go through `tr()` (as in Chasm of Knights). Planned first languages: English, Bulgarian, German, Spanish, French, Portuguese, Chinese (subset fonts as in Chasm). God names stay in their usual English forms, with a native-script subtitle as flavour [LATER].

---

## 10. Audio

- **Music [MVP]:** one calm menu theme per pantheon (60–90 s loop), one tense war loop per pantheon that layers in a percussion stem when any player is down to 3 territories, and short victory and defeat stings.
- **SFX:** dice rattle (wood/stone/clay per skin), dice landing in the tray, conquest (stone crunch + horn), repelled (shield clang), reinforcement (soft drops), miracle per kind (thunder, choir swell, temple bell), awakening (deep gong + the god's leitmotif), UI ticks. The POC reuses Chasm of Knights' Kenney UI sounds and placeholder hits.
- **Voice [LATER]:** one awakening line per god ("The war god wakes!"), short and language-neutral (a shout or chant).
- Prompts for all of these are in [art_prompts/07_music.md](art_prompts/07_music.md) and [art_prompts/08_sound_effects.md](art_prompts/08_sound_effects.md).

---

## 11. Game modes and progression

| Mode | Description | Status |
|---|---|---|
| **Skirmish (New War)** | Free choice of pantheon, gods and options vs. 1–7 computer rivals. | [POC] |
| **Quick War** | One tap: last choices, new map. | [POC] |
| **Hotseat** | 2–8 humans (and computers) on one device. A "pass the device" screen hides nothing (no fog), but it marks whose turn it is. | [MVP] |
| **Daily Omen** | A seeded map + fixed gods per day, with a score (rounds to victory, territories lost). Shareable result line. | [MVP] |
| **Campaign: Eras of Myth** | Per pantheon, 6–8 chapters following its myths (*Titanomachy*, *Ragnarök*, *the Contendings of Horus and Set*, *the Hero Twins in Xibalba*…). Scripted maps, special rules, boss gods with unique powers. Winning unlocks gods, dice skins and realm themes. | [LATER] |
| **Online** | Via the **Mytholore Game Server** (as Chasm of Knights): ranked 1v1 and casual 4-player FFA, friends, open games, cloud saves. The server runs the rules (MatchState is pure and deterministic, so it ports to the server). | [LATER] |

**Progression [LATER]:** a *Pantheon Codex* (each god's lore page unlocks on first win with them), mastery badges per god (win with it, win without losing a territory, win in ≤ 10 rounds), and cosmetic dice skins usable with any pantheon. No power progression: gods are unlocked, never upgraded.

---

## 12. Balance

### 12.1 Method
`tests/sim_test.gd` plays whole wars between computer players with random pantheons, gods and levels (2–8 players, all sizes, both awakening options). It checks rule invariants (dice always 1..cap, maps connected, every war finishes) and prints each god's **win rate relative to a fair share** (1.00 = average).

```sh
godot --headless --path . -s tests/sim_test.gd -- --matches=600
```

**Target:** every god between **0.8 and 1.25** over 2,000+ wars, at the Strategist level. Then a human playtest pass, because AIs under-use some powers (miracles, defensive play).

**Power ranking** ([power_ranking.md](power_ranking.md)): `python tools/run_balance.py` plays 60,000 duels and 20,000 four-player wars between Strategists in parallel (`tests/balance_sim.gd`, about 12 minutes on 16 threads) and `tools/balance_report.py` fits a rating to every god, pair and pantheon (each god judged apart from its partner, its opponents and the turn order). The report has the pantheon balance, pantheon-vs-pantheon results, rankings of gods and pairs (with synergy), and the counters: gods that do better against particular gods than their ratings explain. Run it again after changing a god; `--report-only` rewrites the report from the last data.

### 12.2 Power budget (guideline)
| Effect | ≈ points |
|---|---|
| +1 attack | 1 |
| +1 defence | 0.6 |
| +2 reinforcements per turn | 1 |
| reroll 1s (one side) | 0.5 |
| attacks win ties | 0.5 |
| +1 die on first conquest per turn | 0.7 |
| defend reward +1 | 0.8 |
| miracle (per 1 favour of cost, per die moved) | 0.4 |
| tribute 1 per turn (bane) | −0.8 |
| max 2 attacks per turn (bane) | −1.2 |

Primary ≈ 1 point. Secondary boon ≈ 2 points, bane ≈ −1 point. Banes must **hurt a specific play style**, not just subtract numbers. For example, Hel's "may not attack a larger army" punishes the bold.

### 12.3 First passes (AI vs AI, 600 wars each)
1. **Initial values:** "+1 die on *every* conquest" was far too strong (Inanna 3.29, Guan Yu 2.87, Ah Puch 2.62, Set 2.40). Pure defence and "first attack" gods were weak (Guanyin 0.09, Ares 0.25, Thor 0.28). 4% of wars stalled.
2. **Pass 1:** conquest bonus limited to the first conquest per turn, weak gods buffed, AI anti-stall added. The conquest gods were fixed, but halved reinforcements became too harsh (Hades 0.03, Hou Yi 0.06) and the "defend reward" gods ran hot.
3. **Pass 2 (current):** all 600 wars finished, the range is **0.52–1.67**, and pantheons won 80–115 wars each (fair share 100). Hot: Isis, Ereshkigal, Hel, Guan Yu, Hou Yi. Cold: Guanyin, Ptah, Ah Puch, Hades, Itzamna, Nezha, Zeus. Next step: a 2,000-war run per change, the Strategist level only, and human playtests of the miracle gods (the AI uses miracles crudely).

### 12.4 Turn order and the head start
With the classic setup (equal dice for everyone) the **first player wins far too often**. The first attacks hit a board where nobody has reinforced yet. They break up the rivals' regions, so the rivals get fewer reinforcements, and that lead keeps growing. AI vs AI, Warlords, medium realm, 150–300 wars per row (win % by place in the turn order):

| Rule tried | 2 players | 4 players |
|---|---|---|
| Classic (no compensation) | **82** / 18 | **36** / 29 / 19 / 16 |
| Fixed extra dice: +2 per place | 78 / 22 | 19 / 19 / 27 / 35 |
| Fixed extra dice: +4 per place | 66 / 34 | 9 / 12 / 20 / **59** |
| First round: 1 attack each, or k attacks for the k-th player | 81–85 / 15–19 | 35–37 / … / 16–21 |
| The first player only reinforces on turn 1 | 61 / 39 | 28 / 26 / 22 / 24 |
| Everyone reinforces together at the end of each round | 18 / **82** (the last player wins instead) | 1 / 2 / 8 / **88** |
| … with the starting player rotating each round | 40 / 60 | 24 / 10 / 11 / 55 |
| … with a random order each round | 50 / 50, but whoever is last in round 1 wins 72% | 19 / 24 / 27 / 30, last in round 1 wins 62% |
| Head start, a full reinforcement for the last player | 36 / 64 | 23 / 23 / 25 / 29 |
| **Head start, 0.66 of a reinforcement (current)** | **55 / 45** (500 wars) | **23 / 28 / 23 / 26** (500 wars) |

Fixed dice cannot work for every player count: two players need many, eight need few. A share of **one reinforcement** scales with the map and the number of players by itself. Reinforcing at the end of the round moves the edge to the last player: the territories that player attacked from are refilled at once, while everyone else's stay weak for the rest of the round. `tests/sim_test.gd` checks the turn order on every run (§13.5).

**Later:** a share per player count if human playtests show the first player is still ahead; a placement draft (players place their starting dice themselves, last player first) as an advanced option.

---

## 13. Technical design

### 13.1 Layers (same split as Chasm of Knights)
```
core/          pure rules, no nodes, deterministic with a seed
  realm_map.gd       RealmMap: cells, territories, neighbours, centres
  map_generator.gd   MapGenerator: island + territories from a seed
  match_state.gd     MatchState: owners, dice, players, gods' effects, attack / miracle / end_turn
  god_catalog.gd     GodCatalog: pantheons and gods as data
  dice_odds.gd       DiceOdds: exact win chances (sum distributions, rerolls, min faces)
ai/
  ai_player.gd       AiPlayer: attack and miracle choice per level
session/
  game_settings.gd   GameSettings: preferences + last war choices (user://settings.cfg)
presentation/
  ui.gd, ui_theme.gd, icon_button.gd, menu_backdrop.gd, game_layout.gd, end_overlay.gd, app_window.gd
                     shared with Chasm of Knights (lightly adapted)
  looks.gd           Looks: realm themes (look.json) + terrain palettes + player colours
  sound.gd           Sound autoload
  map/realm_view.gd  RealmView: the isometric map (draw, pick, zoom, pan, effects)
  map/dice_art.gd    DiceArt: isometric dice cubes from face pictures
  battle_panel.gd, player_panel.gd, game_screen.gd and the menu screens (*.gd + *.tscn)
assets/          generated by tools/prepare_assets.py from the shared asset folders
tests/           sim_test.gd (headless rules + balance), screenshots.tscn (every screen)
tools/           prepare_assets.py
```

**Rules for the code**
- `core/` never touches nodes, rendering or `GameSettings`. Every random number comes from the `RandomNumberGenerator` passed in. So a war is **replayable from its seed and action list**, which is what is needed for saves, replays, the server and Daily Omen.
- Actions return **result dictionaries** (what happened). The presentation animates them. The map shows a **copy** of the state (`RealmView.refresh()`), so outcomes appear when the animation says so.
- Gods are data. Effects are interpreted by `MatchState` in a small number of places (`attack_modifiers`, `attack`, `end_turn`, `cast_miracle`).

### 13.2 Saves and replays [MVP]
Save = `{seed, options, player defs, actions: [["attack", from, to], ["miracle", god, target], ["end"]]}`. Load replays the actions on a fresh `MatchState` with the same seed. Replays come for free from this.

### 13.3 Rendering budget
- The POC redraws the map every frame (`_process` → `queue_redraw`) for the pulses and floaters. This is about 1,000 cells × 3 polygons plus about 150 textured cube faces, which is fine on desktop. **[MVP]** Bake the static terrain into a `SubViewport` texture (or a `MultiMesh`/`Polygon2D` set built once), redraw only the overlay, and stop redrawing when idle (mobile battery).
- Textures: dice faces are 256² with mipmaps. God portraits are 512² (thumbs from Tile Shifter).
- Target: 60 fps on a mid-range Android phone (Snapdragon 7-class), 30 fps floor on low-end phones, a web build under 40 MB.

### 13.4 Builds [POC]
`export_presets.cfg` has **Windows Desktop** (`export/windows/Mythic Dice Wars.exe`, the .pck inside the .exe, ~190 MB) and **Android** (`export/android/Mythic Dice Wars.apk`, arm64, package `com.mytholore.mythicdicewars`, ~115 MB), set up like Mythos Academy's. Both take every resource plus `*.json` (the realms' `look.json` and the towers' `layout.json` are plain files, not resources) and leave out `tests/`, `tools/` and `docs/`. The Compatibility renderer everywhere.

```sh
godot --headless --path . --export-release "Windows Desktop" "export/windows/Mythic Dice Wars.exe"
godot --headless --path . --export-debug "Android" "export/android/Mythic Dice Wars.apk"
```

A release APK for a store needs a release keystore (Project > Export > Android > Keystore). The icons come from the key art's `icon.jpg` (`tools/generated_art.py`): the project icon, the Windows `.ico` (16–256 px), Android's legacy 192 px icon and its adaptive icon (the picture as the background layer, set within the middle two thirds that launchers show; an empty foreground). [MVP]: a Web build, and Chasm of Knights' `export_guard` plugin.

### 13.5 Testing
- `tests/sim_test.gd`: invariants and balance (headless, CI-friendly; ~80 s for 600 wars). A quarter of the wars are played under fog of war, and the **fog blindness check** (§4.8) runs first. It ends with the **turn-order check**: 100 wars each of 2 and 4 Warlords with the head start, wins printed by place in the turn order, and a failure if the first of two players wins outside 35–65% (`--seats=N` changes the count, `--seats=0` skips it).
- `tests/screenshots.tscn`: opens every screen, plays a human attack, and saves PNGs at any size (`--size=540x960`, `--pantheon=norse`, `--grid=hex`, `--fog=on`). It is a smoke test for script errors, and it gives screenshots for the store page.
- [MVP] unit tests for `DiceOdds` (against brute force) and `MapGenerator` (connectivity, sizes, determinism).

---

## 14. The proof of concept

### 14.1 What is in it
- A complete war against 1–7 computer rivals, on a generated isometric island of 18/28/40 territories that fits the screen's shape.
- 7 pantheons × 6 gods (42), all effect keys, favour and 3 kinds of miracle, secondary-god awakening.
- Three AI levels with exact odds, anti-stall, miracle use.
- Isometric map with elevation, cliffs, borders, selection, target pulses, zoom/pan/pinch, dice towers built from the real dice skins, count badges, collapse when zoomed out.
- Battle panel with the real dice faces, bonuses and the outcome. Reinforcement and penalty floaters, banners for awakening and elimination, victory and defeat overlays.
- Chasm-style menus: splash, main menu, New War (pantheon tiles re-theme the screen live), god selection cards, settings, how to play (every god listed), credits.
- Responsive: landscape and portrait (checked at 1280 × 800 and 540 × 960).

### 14.2 What is not (yet)
Hotseat, saves, a pause menu, music, localisation, colour-blind emblems, campaign, online, exports. The player list is hidden on a phone held upright.

### 14.3 Running it
```sh
python tools/prepare_assets.py      # once (already done): copies and cuts the art
godot --path .                      # play
godot --headless --path . -s tests/sim_test.gd -- --matches=200
godot --path . res://tests/screenshots.tscn -- --out=<folder> [--size=540x960] [--pantheon=egyptian]
```

---

## 15. Roadmap

| Milestone | Content | Estimate |
|---|---|---|
| **M0 — POC** ✔ | This build. | done |
| **M1 — Vertical slice** | Music and SFX for 2 realms, a logo, pause / save / resume, hotseat, seat setup, mobile player strip, colour-blind emblems. | 4–6 weeks |
| **M2 — Content complete (launch set)** | 7 pantheons × 12 gods, balance at 2,000-war sims + playtests, Daily Omen, localisation (EN + 3), exports (Win, Web, Android). | 8–10 weeks |
| **M3 — Launch** | Store pages, trailer (from the screenshot test), analytics (opt-in), crash reporting. | 2 weeks |
| **M4 — Campaign** | Eras of Myth for Greek and Norse, boss gods, unlocks. | 6–8 weeks |
| **M5 — Online** | Mytholore server integration: ranked 1v1, casual FFA, friends, cloud saves. | 6 weeks |
| **M6+** | New pantheons from the existing dice skins (Aztec, Celtic, Japanese, Slavic…), crossover wars, relics and shrines. | ongoing |

---

## 16. Open questions

1. **Secondary god timing.** Is "wakes after 4 conquests" right, or should it scale with map size (e.g. 15% of the territories)? Alternatively, should it wake at the **start of round 4** so turtles also get it?
2. **Primary actives vs. passives.** Should every primary god have both a small passive and a miracle? The brief allows "passive/active". The POC mixes them.
3. **Favour from losses.** Earning favour by losing land is thematic, but could feed snowballs for the miracle gods of the player in second place. Watch it in playtests.
4. **Same-pantheon wars.** Allow two players with the same pantheon (different gods)? The POC lets rivals repeat a pantheon only when there are more than 6 players.
5. **Map shapes.** Add archipelagos with bridges (sea raids) as a later map type?
6. **Name.** "Mythic Dice Wars" is a working title. Check trademarks and search uniqueness before publishing.

---

## 17. Glossary
| Term | Meaning |
|---|---|
| Realm | the map of one war (an island of territories) and the visual theme of a pantheon |
| Territory | a group of cells that one player owns, holding 1–8 dice |
| Stack / tower | the dice on a territory |
| Region | a group of connected territories of one player. The largest one decides reinforcements |
| Reserve | dice that did not fit, kept for the next turn (max 30) |
| Head start | extra dice for the players who move later, given before the first turn (§4.2) |
| Fog of war | the option where a player sees only their own territories and their neighbours (§4.8) |
| Boon / bane | a god's advantage / drawback, as effect keys (§5.2) |
| Awakening | the moment a secondary god becomes active |
| Favour | the currency of miracles, gained by fighting and by losing land |
| Miracle | an active god power: smite, bless, ward |
