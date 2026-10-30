# Power ranking of the gods

*Generated 2026-10-30 by `python tools/run_balance.py` (wars played by `tests/balance_sim.gd`, analysed by `tools/balance_report.py`). Do not edit by hand: run the tool again after changing a god.*

**Data:** 60,003 duels (2 players) and 20,000 four-player wars between computer players (all Strategists), with the default rules: balanced turn order (head start), the secondary god waking after a few conquests, no fog of war, a medium realm (28 territories), square and hex boards alike. Every player's pantheon and gods were drawn at random.

**How to read it.** The ratings come from a model fitted to all the wars at once, so each god is judged apart from the partner it was paired with, the opponents it met and the turn order. A rating is shown as a win chance: a god with an *average partner* against an *average pair*, in a duel (50% is average) and in a four-player war (25% is average). **Overall** is fitted to the duels and the four-player wars together and shown as a duel win chance; the lists are in its order. *Duel* and *4 players* are fitted to each kind of war alone: where they differ, a god suits one kind better. *Raw* is the plain share of wars won (not corrected for partners and opponents). ± is the 95% margin of error. Verdicts (overall): within ±2 points of 50% *fair*, up to ±4 *a little strong / weak*, beyond that **strong / weak**.

The results are what the computer players make of each god. A human may use some powers better (miracles, timing) or worse; treat them as a guide, not the last word.

## Summary

- **Pantheons: not balanced.** Strongest Yoruba (58.7%), weakest Mesopotamian (42.2%), in a duel against an average pantheon.
- **Gods:** 5 of 42 are fair (within ±2 points), 7 a little off, 30 far off; from 24.7% to 66.7%.
- **Strongest:** Odin 67%, Sun Wukong 65%, Kukulkan 64%, Esu 63%, Sekhmet 63%.
- **Weakest:** Anubis 25%, Ptah 32%, Nezha 35%, Guanyin 37%, Tiamat 39%.
- **Better in duels than in four-player wars:** Itzamna (62% duel, 19% of 4), Loki (54% duel, 15% of 4), Sun Wukong (72% duel, 29% of 4), Shango (59% duel, 18% of 4).
- **Better in four-player wars than in duels:** Anubis (13% duel, 25% of 4), Ereshkigal (30% duel, 39% of 4), Tyr (35% duel, 32% of 4), Isis (49% duel, 40% of 4). Defensive powers and attack limits cost less when rivals also fight each other.
- **Pairs that are more (or less) than their gods:** Guanyin + Hou Yi -12, Ptah + Anubis +10, Chaak + Huracan -9, Marduk + Ereshkigal -6, Guan Yu + Hou Yi +6, Guanyin + Nezha +6 points (a pair's margin of error is about ±2.5).
- **Strongest pair:** Odin + Hel (75.7%); **weakest:** Ra + Anubis (18.8%).
- **Counters:** 61 matchups where a god does clearly better against a particular god than its strength explains; the clearest: Ereshkigal against Hermes, Anubis against Hermes, Anubis against Athena.

## Turn order

- **Duels:** #1 55.0%, #2 45.0% (fair 50%).
- **Four-player wars:** #1 25.5%, #2 22.5%, #3 23.7%, #4 28.3% (fair 25%).

## Are the pantheons balanced?

**Not balanced:** the pantheons' duel win chances lie between 42.2% and 58.7%. A pantheon's rating is that of its six gods together, so it also tells how good its choice of gods is on average.

| # | Pantheon | Overall | Duel | 4 players | Raw duel wins | Raw 4-player wins | Verdict |
|---|---|---|---|---|---|---|---|
| 1 | Yoruba | **58.7%** ±0.7 | 61.4% | 28.2% | 61.1% | 28.1% | **strong** |
| 2 | Mayan | **54.0%** ±0.7 | 58.1% | 22.0% | 57.8% | 21.9% | a little strong |
| 3 | Norse | **51.5%** ±0.7 | 49.3% | 29.2% | 49.2% | 29.1% | fair |
| 4 | Chinese | **51.2%** ±0.7 | 51.2% | 25.7% | 51.1% | 25.6% | fair |
| 5 | Greek | **49.1%** ±0.7 | 50.8% | 21.8% | 50.7% | 21.7% | fair |
| 6 | Egyptian | **43.4%** ±0.7 | 40.7% | 24.3% | 41.0% | 24.2% | **weak** |
| 7 | Mesopotamian | **42.2%** ±0.7 | 38.7% | 24.5% | 39.0% | 24.4% | **weak** |

### Pantheon against pantheon (duels)

How often the row's pantheon beat the column's. **Bold**: clearly more or less than the two pantheons' ratings expect (|z| ≥ 2.5): the row's gods suit, or struggle against, the column's in particular.

| | Greek | Norse | Egyptian | Chinese | Mayan | Mesopotamian | Yoruba |
|---|---|---|---|---|---|---|---|
| **Greek** | – | 49% | 59% | 51% | 43% | 62% | 41% |
| **Norse** | 51% | – | 57% | 49% | 42% | 58% | 39% |
| **Egyptian** | 41% | 43% | – | 40% | 34% | 50% | 29% |
| **Chinese** | 49% | 51% | 60% | – | 43% | 63% | 41% |
| **Mayan** | 57% | 58% | 66% | 57% | – | 70% | 47% |
| **Mesopotamian** | 38% | 42% | 50% | 37% | 30% | – | **26%** |
| **Yoruba** | 59% | 61% | 71% | 59% | 53% | **74%** | – |

## Power ranking: primary gods

| # | God | Pantheon | Overall | Duel | 4 players | Raw duel wins | Raw 4-player wins | Verdict | Powers |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **Odin** | Norse | **66.7%** ±1.1 | 69.3% | 37.6% | 66.1% | 38.7% | **strong** | Wisdom of the Runes: Your dice that show 1 are rolled again, in attack and defence. |
| 2 | **Guan Yu** | Chinese | **61.1%** ±1.1 | 59.2% | 38.9% | 57.6% | 37.6% | **strong** | Loyal Blade: +1 die on the first territory you conquer each turn, and +2 reinforcement dice. |
| 3 | **Obatala** | Yoruba | **59.6%** ±1.1 | 61.1% | 32.2% | 64.9% | 32.6% | **strong** | Shaper of the World: +1 to every defence, +1 reinforcement die, and reinforcements go to your borders first. |
| 4 | **Athena** | Greek | **58.0%** ±1.1 | 59.3% | 31.0% | 58.1% | 28.3% | **strong** | Aegis: +2 to the defence of every territory you hold. |
| 5 | **Isis** | Egyptian | **56.7%** ±1.1 | 49.3% | 40.2% | 45.1% | 37.5% | **strong** | Breath of Life: Miracle (4 favour): add 3 dice to one of your territories. |
| 6 | **Ix Chel** | Mayan | **55.7%** ±1.1 | 56.8% | 29.0% | 59.1% | 26.6% | **strong** | Moon's Tide: +1 reinforcement die, and defending 1s are rolled again. |
| 7 | **Itzamna** | Mayan | **54.7%** ±1.1 | 62.4% | 19.0% | 63.9% | 17.4% | **strong** | Celestial Scribe: Attacking 1s are rolled again, and +1 favour whenever you gain favour. |
| 8 | **Jade Emperor** | Chinese | **53.5%** ±1.1 | 56.3% | 25.1% | 55.6% | 24.5% | a little strong | Heavenly Mandate: +2 reinforcement dice, and reinforcements go to your borders first. |
| 9 | **Yemoja** | Yoruba | **53.0%** ±1.1 | 49.8% | 32.1% | 55.3% | 32.7% | a little strong | Ocean's Embrace: +2 reinforcement dice, and a territory that holds against an attack gains 1 die. |
| 10 | **Utu** | Mesopotamian | **52.6%** ±1.1 | 50.9% | 29.1% | 45.2% | 28.3% | a little strong | Chariot of the Sun: +2 when attacking from a full stack, and defending 1s are rolled again. |
| 11 | **Shango** | Yoruba | **52.2%** ±1.1 | 59.3% | 18.5% | 63.2% | 19.3% | a little strong | Thunderstones: +1 to every attack (+3 on the first each turn), and your attacks win ties. |
| 12 | **Ra** | Egyptian | **49.1%** ±1.2 | 53.3% | 20.0% | 48.7% | 18.8% | fair | Sun's Glare: Your attacking dice never show a 1. |
| 13 | **Chaak** | Mayan | **46.8%** ±1.2 | 46.0% | 23.6% | 50.2% | 21.6% | a little weak | Life-giving Rain: Miracle (2 favour): add 2 dice to one of your territories. |
| 14 | **Demeter** | Greek | **45.9%** ±1.2 | 44.4% | 23.9% | 45.3% | 21.7% | **weak** | Bountiful Harvest: +2 reinforcement dice every turn. |
| 15 | **Zeus** | Greek | **45.2%** ±1.2 | 48.8% | 16.6% | 48.6% | 15.2% | **weak** | Thunderbolt: Miracle (2 favour): strike an enemy territory, destroying 2 of its dice. |
| 16 | **Frigg** | Norse | **45.0%** ±1.1 | 40.6% | 26.4% | 41.0% | 27.9% | **weak** | Hearth and Home: A territory that holds against an attack gains 1 die, and +1 to every defence. |
| 17 | **Enki** | Mesopotamian | **42.8%** ±1.2 | 37.4% | 26.1% | 34.4% | 25.3% | **weak** | Waters of Life: +1 reinforcement die, and +1 favour whenever you gain favour. |
| 18 | **Marduk** | Mesopotamian | **42.4%** ±1.2 | 42.0% | 19.7% | 37.4% | 19.4% | **weak** | Champion of the Gods: +1 to every attack. |
| 19 | **Thor** | Norse | **40.5%** ±1.2 | 39.5% | 18.7% | 40.7% | 20.5% | **weak** | Opening Thunder: +5 to the first attack of each turn, +1 to every other. |
| 20 | **Guanyin** | Chinese | **37.0%** ±1.2 | 37.5% | 15.0% | 40.2% | 14.9% | **weak** | Mercy: Miracle (1 favour): one of your territories gets +5 defence until your next turn. +1 to every defence, and a territory that holds gains 1 die. |
| 21 | **Ptah** | Egyptian | **31.8%** ±1.3 | 27.3% | 16.7% | 29.0% | 15.8% | **weak** | Master Builder: Your territories hold up to 9 dice, and +1 reinforcement die. |

## Power ranking: secondary gods

| # | God | Pantheon | Overall | Duel | 4 players | Raw duel wins | Raw 4-player wins | Verdict | Powers |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **Sun Wukong** | Chinese | **65.2%** ±1.1 | 72.1% | 28.6% | 69.6% | 28.4% | **strong** | Seventy-two Transformations: Attacking 1s are rolled again, +2 against larger armies, and attacks win ties. — *Restless: No reserve (extra dice are lost), and -2 reinforcement dice each turn.* |
| 2 | **Kukulkan** | Mayan | **64.4%** ±1.1 | 70.6% | 30.9% | 71.5% | 28.1% | **strong** | Serpent Wind: +2 to every attack, and reinforcements go to your borders first. — *Blood Offering: At the end of each turn your largest stack loses 1 die.* |
| 3 | **Esu** | Yoruba | **63.5%** ±1.1 | 65.8% | 34.8% | 68.9% | 35.3% | **strong** | Crossroads: +3 when attacking a larger army, and attacking 1s are rolled again. — *The Trickster's Price: After a failed attack, another of your territories loses 1 die.* |
| 4 | **Sekhmet** | Egyptian | **62.9%** ±1.1 | 68.7% | 28.9% | 60.0% | 28.0% | **strong** | Rampage: +2 to every attack. — *Unquenchable Wrath: Every failed attack costs 2 dice from another of your territories.* |
| 5 | **Hel** | Norse | **61.6%** ±1.1 | 61.3% | 36.9% | 58.0% | 38.0% | **strong** | Cold Halls: +1 to every defence, and a territory that holds gains 1 die. — *Cold Patience: You may not attack a territory with more dice than yours.* |
| 6 | **Hermes** | Greek | **56.2%** ±1.1 | 55.9% | 31.3% | 54.9% | 28.5% | **strong** | Fleet-footed: Your attacks win ties, and reinforcements rush to your borders. — *Travels Light: Your territories hold at most 6 dice.* |
| 7 | **Ogun** | Yoruba | **54.9%** ±1.1 | 58.8% | 24.1% | 63.1% | 25.1% | **strong** | Iron Path: +2 to every attack, +1 more when attacking from a full stack. — *Restless Blade: -1 to the defence of every territory you hold.* |
| 8 | **Inanna** | Mesopotamian | **54.8%** ±1.1 | 61.2% | 20.6% | 53.9% | 19.7% | **strong** | Morning Star: +2 to every attack, and +1 die on the first territory you conquer each turn. — *Descent: -1 to every defence, and no reserve (extra dice are lost).* |
| 9 | **Ares** | Greek | **51.5%** ±1.1 | 54.7% | 22.4% | 54.3% | 20.3% | fair | Bloodlust: +2 to every attack. — *Reckless: -1 to the defence of every territory you hold.* |
| 10 | **Set** | Egyptian | **51.4%** ±1.1 | 56.7% | 19.7% | 49.3% | 19.9% | fair | Desert Storm: +1 to every attack, and +1 die on the first territory you conquer each turn. — *Chaos Tithe: At the end of each turn your largest stack loses 2 dice.* |
| 11 | **Hou Yi** | Chinese | **51.0%** ±1.1 | 47.3% | 30.5% | 47.9% | 30.0% | fair | Nine Arrows: Miracle (2 favour): strike an enemy territory, destroying 3 of its dice. — *Exile: At the end of each turn your largest stack loses 1 die.* |
| 12 | **Huracan** | Mayan | **48.1%** ±1.1 | 47.7% | 23.6% | 51.8% | 21.6% | fair | Great Flood: Miracle (2 favour): strike an enemy territory, destroying 2 of its dice. +1 to every attack. — *Uprooted: -1 to the defence of every territory you hold.* |
| 13 | **Loki** | Norse | **47.1%** ±1.2 | 53.9% | 15.2% | 52.3% | 16.6% | a little weak | Trickery: +3 when attacking a larger army, and your attacks win ties. — *Betrayal: Your defences lose ties.* |
| 14 | **Oya** | Yoruba | **46.3%** ±1.1 | 45.4% | 23.0% | 51.4% | 24.1% | a little weak | Whirlwind: Miracle (1 favour): strike an enemy territory, destroying 2 of its dice. +1 favour whenever you gain favour. — *The Wind Turns: -1 to the defence of every territory you hold.* |
| 15 | **Ah Puch** | Mayan | **44.3%** ±1.1 | 46.0% | 17.7% | 50.1% | 16.0% | **weak** | Harvest of Souls: +1 to every attack, +1 die on the first territory you conquer each turn, +2 favour whenever you gain favour. — *Withering: -2 reinforcement dice each turn.* |
| 16 | **Tyr** | Norse | **43.9%** ±1.2 | 35.1% | 32.2% | 37.0% | 32.8% | **weak** | Just War: +1 to every attack and +1 to every defence. — *Bound by Oath: At most 4 attacks per turn.* |
| 17 | **Ereshkigal** | Mesopotamian | **43.6%** ±1.2 | 30.2% | 38.8% | 27.6% | 36.8% | **weak** | Seven Gates: +3 to every defence. — *Land of No Return: At most 2 attacks per turn.* |
| 18 | **Hades** | Greek | **41.5%** ±1.2 | 42.1% | 17.6% | 43.0% | 16.2% | **weak** | Army of Shades: +1 to every attack, +1 die on the first territory you conquer each turn, and +1 favour whenever you gain favour. — *Barren Fields: -2 reinforcement dice each turn.* |
| 19 | **Tiamat** | Mesopotamian | **39.4%** ±1.2 | 39.7% | 17.8% | 35.3% | 17.0% | **weak** | Primordial Sea: Your territories hold up to 10 dice, and +2 reinforcement dice. — *Brood Hunger: At the end of each turn your largest stack loses 1 die.* |
| 20 | **Nezha** | Chinese | **35.4%** ±1.2 | 32.7% | 17.7% | 35.5% | 18.1% | **weak** | Wind-Fire Wheels: +4 to the first attack of each turn, +2 when attacking from a full stack. — *Child's Temper: -1 to the defence of every territory you hold.* |
| 21 | **Anubis** | Egyptian | **24.7%** ±1.4 | 12.7% | 25.2% | 12.9% | 24.6% | **weak** | Weigher of Hearts: +1 to every defence, and +2 favour whenever you gain favour. — *Patient Judge: At most 2 attacks per turn.* |

## All gods in one list

Primary and secondary gods side by side (each against the average of its own kind).

| # | God | Role | Pantheon | Overall | Duel | 4 players |
|---|---|---|---|---|---|---|
| 1 | Odin | primary | Norse | **66.7%** | 69.3% | 37.6% |
| 2 | Sun Wukong | secondary | Chinese | **65.2%** | 72.1% | 28.6% |
| 3 | Kukulkan | secondary | Mayan | **64.4%** | 70.6% | 30.9% |
| 4 | Esu | secondary | Yoruba | **63.5%** | 65.8% | 34.8% |
| 5 | Sekhmet | secondary | Egyptian | **62.9%** | 68.7% | 28.9% |
| 6 | Hel | secondary | Norse | **61.6%** | 61.3% | 36.9% |
| 7 | Guan Yu | primary | Chinese | **61.1%** | 59.2% | 38.9% |
| 8 | Obatala | primary | Yoruba | **59.6%** | 61.1% | 32.2% |
| 9 | Athena | primary | Greek | **58.0%** | 59.3% | 31.0% |
| 10 | Isis | primary | Egyptian | **56.7%** | 49.3% | 40.2% |
| 11 | Hermes | secondary | Greek | **56.2%** | 55.9% | 31.3% |
| 12 | Ix Chel | primary | Mayan | **55.7%** | 56.8% | 29.0% |
| 13 | Ogun | secondary | Yoruba | **54.9%** | 58.8% | 24.1% |
| 14 | Inanna | secondary | Mesopotamian | **54.8%** | 61.2% | 20.6% |
| 15 | Itzamna | primary | Mayan | **54.7%** | 62.4% | 19.0% |
| 16 | Jade Emperor | primary | Chinese | **53.5%** | 56.3% | 25.1% |
| 17 | Yemoja | primary | Yoruba | **53.0%** | 49.8% | 32.1% |
| 18 | Utu | primary | Mesopotamian | **52.6%** | 50.9% | 29.1% |
| 19 | Shango | primary | Yoruba | **52.2%** | 59.3% | 18.5% |
| 20 | Ares | secondary | Greek | **51.5%** | 54.7% | 22.4% |
| 21 | Set | secondary | Egyptian | **51.4%** | 56.7% | 19.7% |
| 22 | Hou Yi | secondary | Chinese | **51.0%** | 47.3% | 30.5% |
| 23 | Ra | primary | Egyptian | **49.1%** | 53.3% | 20.0% |
| 24 | Huracan | secondary | Mayan | **48.1%** | 47.7% | 23.6% |
| 25 | Loki | secondary | Norse | **47.1%** | 53.9% | 15.2% |
| 26 | Chaak | primary | Mayan | **46.8%** | 46.0% | 23.6% |
| 27 | Oya | secondary | Yoruba | **46.3%** | 45.4% | 23.0% |
| 28 | Demeter | primary | Greek | **45.9%** | 44.4% | 23.9% |
| 29 | Zeus | primary | Greek | **45.2%** | 48.8% | 16.6% |
| 30 | Frigg | primary | Norse | **45.0%** | 40.6% | 26.4% |
| 31 | Ah Puch | secondary | Mayan | **44.3%** | 46.0% | 17.7% |
| 32 | Tyr | secondary | Norse | **43.9%** | 35.1% | 32.2% |
| 33 | Ereshkigal | secondary | Mesopotamian | **43.6%** | 30.2% | 38.8% |
| 34 | Enki | primary | Mesopotamian | **42.8%** | 37.4% | 26.1% |
| 35 | Marduk | primary | Mesopotamian | **42.4%** | 42.0% | 19.7% |
| 36 | Hades | secondary | Greek | **41.5%** | 42.1% | 17.6% |
| 37 | Thor | primary | Norse | **40.5%** | 39.5% | 18.7% |
| 38 | Tiamat | secondary | Mesopotamian | **39.4%** | 39.7% | 17.8% |
| 39 | Guanyin | primary | Chinese | **37.0%** | 37.5% | 15.0% |
| 40 | Nezha | secondary | Chinese | **35.4%** | 32.7% | 17.7% |
| 41 | Ptah | primary | Egyptian | **31.8%** | 27.3% | 16.7% |
| 42 | Anubis | secondary | Egyptian | **24.7%** | 12.7% | 25.2% |

## Power ranking: pairs of gods

Every primary god with every secondary god of its pantheon (63 pairs), rated as a team. **Synergy**: how much better (or worse) the pair does than its two gods' own ratings add up to, in duel win-chance points; a large synergy means the two powers help (or hinder) each other.

| # | Pair | Pantheon | Overall | Duel | 4 players | Raw duel wins | Synergy |
|---|---|---|---|---|---|---|---|
| 1 | Odin + Hel | Norse | **75.7%** ±1.9 | 77.8% | 49.9% | 74.8% | -0.5 |
| 2 | Guan Yu + Sun Wukong | Chinese | **72.1%** ±1.9 | 76.6% | 41.0% | 73.5% | -2.5 |
| 3 | Isis + Sekhmet | Egyptian | **71.6%** ±1.9 | 70.4% | 48.7% | 67.4% | +2.6 |
| 4 | Obatala + Esu | Yoruba | **70.3%** ±1.9 | 72.8% | 41.7% | 70.3% | -1.7 |
| 5 | Shango + Esu | Yoruba | **68.3%** ±1.9 | 77.3% | 29.6% | 74.1% | +2.8 |
| 6 | Guan Yu + Hou Yi | Chinese | **68.2%** ±1.9 | 62.7% | 51.1% | 60.2% | +6.2 |
| 7 | Ix Chel + Kukulkan | Mayan | **67.6%** ±1.9 | 75.0% | 31.7% | 72.0% | -1.8 |
| 8 | Chaak + Kukulkan | Mayan | **66.4%** ±1.9 | 71.3% | 34.1% | 68.4% | +5.0 |
| 9 | Itzamna + Kukulkan | Mayan | **66.1%** ±1.9 | 77.3% | 23.7% | 73.9% | -2.5 |
| 10 | Jade Emperor + Sun Wukong | Chinese | **66.0%** ±1.9 | 75.0% | 26.7% | 72.1% | -2.2 |
| 11 | Yemoja + Esu | Yoruba | **65.5%** ±1.9 | 64.4% | 42.0% | 62.3% | -0.8 |
| 12 | Obatala + Ogun | Yoruba | **65.3%** ±1.9 | 71.4% | 31.4% | 68.6% | +1.1 |
| 13 | Odin + Loki | Norse | **64.6%** ±1.9 | 74.2% | 26.0% | 71.2% | +0.6 |
| 14 | Ra + Sekhmet | Egyptian | **63.6%** ±1.9 | 72.8% | 24.9% | 70.4% | +1.5 |
| 15 | Athena + Hermes | Greek | **62.6%** ±1.9 | 62.6% | 37.3% | 60.2% | -1.3 |
| 16 | Odin + Tyr | Norse | **61.4%** ±1.9 | 54.0% | 47.2% | 52.6% | +0.4 |
| 17 | Athena + Ares | Greek | **61.0%** ±1.9 | 65.5% | 29.1% | 63.2% | +1.5 |
| 18 | Isis + Set | Egyptian | **60.1%** ±1.9 | 58.2% | 37.5% | 55.9% | +1.9 |
| 19 | Ix Chel + Huracan | Mayan | **58.9%** ±1.9 | 59.4% | 32.3% | 57.7% | +5.1 |
| 20 | Jade Emperor + Hou Yi | Chinese | **58.7%** ±1.9 | 58.7% | 33.6% | 56.9% | +4.3 |
| 21 | Frigg + Hel | Norse | **58.5%** ±1.9 | 53.0% | 41.1% | 51.0% | +1.7 |
| 22 | Guanyin + Sun Wukong | Chinese | **58.3%** ±1.9 | 66.0% | 22.0% | 63.3% | +5.9 |
| 23 | Yemoja + Ogun | Yoruba | **57.9%** ±1.9 | 59.6% | 29.8% | 58.1% | +0.1 |
| 24 | Obatala + Oya | Yoruba | **57.1%** ±1.9 | 57.1% | 31.6% | 56.1% | +1.1 |
| 25 | Shango + Ogun | Yoruba | **56.1%** ±1.9 | 64.6% | 19.2% | 62.4% | -0.9 |
| 26 | Itzamna + Huracan | Mayan | **56.0%** ±1.9 | 63.5% | 20.2% | 61.7% | +3.3 |
| 27 | Utu + Inanna | Mesopotamian | **55.2%** ±1.9 | 58.7% | 24.8% | 56.8% | -2.2 |
| 28 | Ra + Set | Egyptian | **53.4%** ±1.9 | 61.9% | 16.1% | 60.4% | +2.9 |
| 29 | Zeus + Hermes | Greek | **53.2%** ±1.9 | 57.1% | 22.9% | 55.2% | +1.8 |
| 30 | Demeter + Hermes | Greek | **52.0%** ±1.9 | 50.2% | 29.7% | 49.5% | -0.1 |
| 31 | Utu + Ereshkigal | Mesopotamian | **51.9%** ±1.9 | 38.1% | 44.9% | 39.7% | +5.7 |
| 32 | Thor + Hel | Norse | **51.4%** ±1.9 | 50.1% | 28.4% | 48.8% | -0.8 |
| 33 | Marduk + Inanna | Mesopotamian | **50.5%** ±1.9 | 56.7% | 17.4% | 55.5% | +3.2 |
| 34 | Yemoja + Oya | Yoruba | **50.3%** ±1.9 | 45.5% | 32.6% | 45.2% | +1.0 |
| 35 | Athena + Hades | Greek | **49.8%** ±1.9 | 52.2% | 22.7% | 50.7% | +0.2 |
| 36 | Itzamna + Ah Puch | Mayan | **48.7%** ±1.9 | 58.2% | 11.5% | 56.1% | -0.2 |
| 37 | Demeter + Ares | Greek | **48.3%** ±2.0 | 49.9% | 22.2% | 49.2% | +0.9 |
| 38 | Ix Chel + Ah Puch | Mayan | **47.2%** ±1.9 | 49.3% | 20.5% | 48.2% | -2.8 |
| 39 | Enki + Inanna | Mesopotamian | **47.0%** ±1.9 | 48.6% | 20.1% | 49.4% | -0.6 |
| 40 | Shango + Oya | Yoruba | **46.4%** ±1.9 | 54.0% | 13.0% | 52.8% | -2.0 |
| 41 | Chaak + Ah Puch | Mayan | **44.4%** ±2.0 | 46.1% | 19.2% | 46.0% | +3.3 |
| 42 | Zeus + Ares | Greek | **44.3%** ±2.0 | 50.6% | 13.4% | 50.0% | -2.4 |
| 43 | Guan Yu + Nezha | Chinese | **42.3%** ±2.0 | 37.7% | 26.1% | 38.9% | -4.0 |
| 44 | Thor + Loki | Norse | **40.7%** ±2.0 | 45.7% | 11.8% | 45.3% | +3.0 |
| 45 | Frigg + Tyr | Norse | **40.6%** ±2.0 | 29.6% | 33.7% | 30.9% | +1.6 |
| 46 | Ptah + Sekhmet | Egyptian | **39.2%** ±2.0 | 41.3% | 14.8% | 41.5% | -5.0 |
| 47 | Utu + Tiamat | Mesopotamian | **39.1%** ±2.0 | 37.1% | 20.0% | 38.4% | -2.9 |
| 48 | Frigg + Loki | Norse | **38.5%** ±2.0 | 40.2% | 14.7% | 40.9% | -3.6 |
| 49 | Zeus + Hades | Greek | **37.5%** ±2.0 | 40.9% | 11.7% | 41.0% | +0.5 |
| 50 | Demeter + Hades | Greek | **37.0%** ±2.0 | 36.0% | 16.7% | 37.6% | -0.6 |
| 51 | Enki + Ereshkigal | Mesopotamian | **36.9%** ±2.1 | 19.3% | 42.0% | 22.3% | +0.3 |
| 52 | Jade Emperor + Nezha | Chinese | **36.7%** ±2.1 | 35.7% | 17.3% | 37.0% | -1.9 |
| 53 | Chaak + Huracan | Mayan | **35.8%** ±2.1 | 35.4% | 15.6% | 36.0% | -9.1 |
| 54 | Marduk + Tiamat | Mesopotamian | **35.3%** ±2.1 | 34.8% | 15.0% | 36.2% | +2.9 |
| 55 | Enki + Tiamat | Mesopotamian | **33.0%** ±2.1 | 29.1% | 18.9% | 31.3% | +0.3 |
| 56 | Thor + Tyr | Norse | **32.3%** ±2.2 | 24.1% | 24.6% | 27.1% | -2.4 |
| 57 | Guanyin + Nezha | Chinese | **30.3%** ±2.2 | 28.3% | 14.2% | 30.6% | +5.9 |
| 58 | Marduk + Ereshkigal | Mesopotamian | **30.1%** ±2.2 | 18.4% | 29.5% | 21.2% | -6.2 |
| 59 | Ptah + Set | Egyptian | **27.5%** ±2.3 | 28.7% | 8.0% | 31.3% | -5.6 |
| 60 | Guanyin + Hou Yi | Chinese | **25.7%** ±2.3 | 24.2% | 11.1% | 26.9% | -12.3 |
| 61 | Isis + Anubis | Egyptian | **24.3%** ±2.4 | 8.6% | 32.9% | 10.8% | -5.7 |
| 62 | Ptah + Anubis | Egyptian | **23.7%** ±2.4 | 11.3% | 26.6% | 13.9% | +10.5 |
| 63 | Ra + Anubis | Egyptian | **18.8%** ±2.6 | 11.4% | 18.3% | 13.9% | -5.2 |

## Counters: gods that do better against particular gods

For every two gods met on opposite sides of the duels (861 matchups with enough wars), the wins of the first god's side are compared with what the ratings expect (they already include both partners and the turn order). Listed: the matchups where the first god's side won clearly more (z ≥ 3: three standard deviations; by chance alone about one or two of this many matchups would reach it, so a single entry near 3 is a hint, not proof).

| God | does better against | Wars | Won | Expected | z | Powers involved |
|---|---|---|---|---|---|---|
| **Ereshkigal** (Mesopotamian) | Hermes (Greek) | 261 | 51.0% | 21.2% | 11.9 | Seven Gates vs Travels Light |
| **Anubis** (Egyptian) | Hermes (Greek) | 266 | 26.3% | 8.6% | 10.4 | Weigher of Hearts vs Travels Light |
| **Anubis** (Egyptian) | Athena (Greek) | 257 | 21.0% | 7.1% | 8.7 | Weigher of Hearts vs Aegis |
| **Anubis** (Egyptian) | Hel (Norse) | 267 | 21.0% | 7.7% | 8.3 | Weigher of Hearts vs Cold Patience |
| **Ereshkigal** (Mesopotamian) | Athena (Greek) | 267 | 37.8% | 18.8% | 8.1 | Seven Gates vs Aegis |
| **Ereshkigal** (Mesopotamian) | Hel (Norse) | 263 | 36.9% | 19.1% | 7.5 | Seven Gates vs Cold Patience |
| **Ereshkigal** (Mesopotamian) | Frigg (Norse) | 284 | 54.2% | 34.0% | 7.4 | Seven Gates vs Hearth and Home |
| **Tiamat** (Mesopotamian) | Ereshkigal (Mesopotamian) | 272 | 81.6% | 60.0% | 7.4 | Primordial Sea vs Land of No Return |
| **Anubis** (Egyptian) | Ereshkigal (Mesopotamian) | 272 | 41.9% | 25.5% | 6.4 | Weigher of Hearts vs Land of No Return |
| **Ereshkigal** (Mesopotamian) | Demeter (Greek) | 282 | 46.5% | 29.5% | 6.3 | Seven Gates vs Bountiful Harvest |
| **Loki** (Norse) | Shango (Yoruba) | 271 | 56.1% | 38.4% | 6.3 | Trickery vs Thunderstones |
| **Jade Emperor** (Chinese) | Ereshkigal (Mesopotamian) | 287 | 90.9% | 77.2% | 5.8 | Heavenly Mandate vs Land of No Return |
| **Tyr** (Norse) | Hel (Norse) | 275 | 42.9% | 28.9% | 5.5 | Just War vs Cold Patience |
| **Ereshkigal** (Mesopotamian) | Guanyin (Chinese) | 266 | 51.1% | 36.1% | 5.4 | Seven Gates vs Mercy |
| **Tyr** (Norse) | Ereshkigal (Mesopotamian) | 273 | 74.7% | 59.9% | 5.2 | Just War vs Land of No Return |
| **Jade Emperor** (Chinese) | Tyr (Norse) | 264 | 83.3% | 69.6% | 5.2 | Heavenly Mandate vs Bound by Oath |
| **Utu** (Mesopotamian) | Loki (Norse) | 248 | 57.3% | 42.0% | 5.2 | Chariot of the Sun vs Betrayal |
| **Ereshkigal** (Mesopotamian) | Loki (Norse) | 272 | 37.1% | 24.6% | 5.0 | Seven Gates vs Betrayal |
| **Hel** (Norse) | Loki (Norse) | 286 | 70.3% | 57.0% | 4.9 | Cold Halls vs Betrayal |
| **Nezha** (Chinese) | Anubis (Egyptian) | 237 | 92.0% | 79.8% | 4.8 | Wind-Fire Wheels vs Patient Judge |
| **Tyr** (Norse) | Frigg (Norse) | 272 | 56.6% | 43.1% | 4.8 | Just War vs Hearth and Home |
| **Jade Emperor** (Chinese) | Anubis (Egyptian) | 262 | 98.9% | 90.7% | 4.7 | Heavenly Mandate vs Patient Judge |
| **Oya** (Yoruba) | Tyr (Norse) | 251 | 78.5% | 65.5% | 4.5 | Whirlwind vs Bound by Oath |
| **Tyr** (Norse) | Anubis (Egyptian) | 248 | 91.9% | 81.2% | 4.5 | Just War vs Patient Judge |
| **Tyr** (Norse) | Athena (Greek) | 261 | 41.4% | 29.5% | 4.4 | Just War vs Aegis |
| **Loki** (Norse) | Sun Wukong (Chinese) | 269 | 43.1% | 31.4% | 4.4 | Trickery vs Restless |
| **Shango** (Yoruba) | Ereshkigal (Mesopotamian) | 255 | 94.5% | 85.1% | 4.3 | Thunderstones vs Land of No Return |
| **Ix Chel** (Mayan) | Loki (Norse) | 283 | 67.8% | 56.3% | 4.2 | Moon's Tide vs Betrayal |
| **Guan Yu** (Chinese) | Tyr (Norse) | 267 | 82.0% | 71.4% | 4.2 | Loyal Blade vs Bound by Oath |
| **Frigg** (Norse) | Athena (Greek) | 282 | 44.0% | 32.7% | 4.2 | Hearth and Home vs Aegis |
| **Loki** (Norse) | Guan Yu (Chinese) | 287 | 56.1% | 45.0% | 4.2 | Trickery vs Loyal Blade |
| **Ra** (Egyptian) | Ereshkigal (Mesopotamian) | 276 | 80.4% | 70.8% | 4.1 | Sun's Glare vs Land of No Return |
| **Tyr** (Norse) | Guanyin (Chinese) | 291 | 58.4% | 47.4% | 4.1 | Just War vs Mercy |
| **Frigg** (Norse) | Guanyin (Chinese) | 259 | 64.1% | 52.3% | 4.1 | Hearth and Home vs Mercy |
| **Guan Yu** (Chinese) | Anubis (Egyptian) | 242 | 97.9% | 90.7% | 4.0 | Loyal Blade vs Patient Judge |
| **Nezha** (Chinese) | Tyr (Norse) | 268 | 60.1% | 48.7% | 4.0 | Wind-Fire Wheels vs Bound by Oath |
| **Oya** (Yoruba) | Ereshkigal (Mesopotamian) | 240 | 87.5% | 76.9% | 4.0 | Whirlwind vs Land of No Return |
| **Tiamat** (Mesopotamian) | Anubis (Egyptian) | 255 | 90.6% | 81.3% | 3.9 | Primordial Sea vs Patient Judge |
| **Huracan** (Mayan) | Ereshkigal (Mesopotamian) | 276 | 85.9% | 76.8% | 3.6 | Great Flood vs Land of No Return |
| **Utu** (Mesopotamian) | Ereshkigal (Mesopotamian) | 273 | 79.1% | 69.4% | 3.6 | Chariot of the Sun vs Land of No Return |
