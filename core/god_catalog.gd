class_name GodCatalog
extends RefCounted
## The pantheons and their gods, as data. Every god has a boon (and a secondary god also a bane):
## dictionaries of effect keys that MatchState reads (see EFFECT KEYS below). Adding a god means adding
## an entry here and a portrait at assets/gods/<pantheon>/<id>.jpg; no rules code changes unless the
## god needs a new effect key.
##
## EFFECT KEYS (numbers add up across a player's gods; flags are true if any god sets them)
##   attack_bonus        +N to the attack total
##   defense_bonus       +N to the defence total of every territory (negative for a bane)
##   first_attack_bonus  +N to the first attack of each turn
##   underdog_bonus      +N when attacking a territory with more dice than the attacker
##   full_stack_bonus    +N when attacking from a full stack
##   reroll_ones_attack  attacking dice that show 1 are rolled once more
##   reroll_ones_defense defending dice that show 1 are rolled once more
##   min_attack_face     attacking dice never show less than N
##   attack_wins_ties    an attack that ties wins
##   defense_loses_ties  a defence that ties loses
##   conquest_bonus      +N dice on the first territory conquered each turn
##   defend_reward       +N dice on a territory that held against an attack
##   max_dice_bonus      the most dice a territory can hold, 8 + N (a bane can make it smaller)
##   reinforce_bonus     +N reinforcement dice each turn
##   reinforce_mult      reinforcements multiplied (0.5 = halved; applied after the bonus)
##   smart_reinforce     reinforcements go to territories that border an enemy first
##   no_reserve          dice that do not fit are lost instead of kept in the reserve
##   max_attacks         at most N attacks per turn
##   tribute             at the end of each turn the largest stack loses N dice
##   hubris              after a failed attack, another of the attacker's territories loses N dice
##   no_attack_stronger  may not attack a territory with more dice than the attacker
##   favor_bonus         +N favour whenever favour is gained
##   miracle             an active power: {kind: "smite" | "bless" | "ward", amount: N, cost: favour}

const PANTHEONS: Array[Dictionary] = [
	{"id": "greek", "name": "Greek", "realm": "Olympus", "dice": "greek"},
	{"id": "norse", "name": "Norse", "realm": "Asgard", "dice": "norse"},
	{"id": "egyptian", "name": "Egyptian", "realm": "The Two Lands", "dice": "egyptian"},
	{"id": "chinese", "name": "Chinese", "realm": "The Celestial Court", "dice": "chinese"},
	{"id": "mayan", "name": "Mayan", "realm": "Xibalba and the Milpa", "dice": "mayan"},
	{"id": "mesopotamian", "name": "Mesopotamian", "realm": "Land Between the Rivers", "dice": "mesopotamian"},
]

const PRIMARY := "primary"
const SECONDARY := "secondary"

const GODS: Array[Dictionary] = [
	# --- Greek -------------------------------------------------------------------------------
	{"id": "zeus", "pantheon": "greek", "role": PRIMARY, "name": "Zeus", "title": "King of Olympus",
		"boon_name": "Thunderbolt", "boon_text": "Miracle (2 favour): strike an enemy territory, destroying 2 of its dice.",
		"boon": {"miracle": {"kind": "smite", "amount": 2, "cost": 2}}},
	{"id": "athena", "pantheon": "greek", "role": PRIMARY, "name": "Athena", "title": "Strategist of Olympus",
		"boon_name": "Aegis", "boon_text": "+2 to the defence of every territory you hold.",
		"boon": {"defense_bonus": 2}},
	{"id": "demeter", "pantheon": "greek", "role": PRIMARY, "name": "Demeter", "title": "Mother of the Harvest",
		"boon_name": "Bountiful Harvest", "boon_text": "+2 reinforcement dice every turn.",
		"boon": {"reinforce_bonus": 2}},
	{"id": "ares", "pantheon": "greek", "role": SECONDARY, "name": "Ares", "title": "God of War",
		"boon_name": "Bloodlust", "boon_text": "+2 to every attack.",
		"boon": {"attack_bonus": 2},
		"bane_name": "Reckless", "bane_text": "-1 to the defence of every territory you hold.",
		"bane": {"defense_bonus": -1}},
	{"id": "hermes", "pantheon": "greek", "role": SECONDARY, "name": "Hermes", "title": "Messenger of the Gods",
		"boon_name": "Fleet-footed", "boon_text": "Your attacks win ties, and reinforcements rush to your borders.",
		"boon": {"attack_wins_ties": true, "smart_reinforce": true},
		"bane_name": "Travels Light", "bane_text": "Your territories hold at most 6 dice.",
		"bane": {"max_dice_bonus": -2}},
	{"id": "hades", "pantheon": "greek", "role": SECONDARY, "name": "Hades", "title": "Lord of the Underworld",
		"boon_name": "Army of Shades", "boon_text": "+1 to every attack, +1 die on the first territory you conquer each turn, and +1 favour whenever you gain favour.",
		"boon": {"attack_bonus": 1, "conquest_bonus": 1, "favor_bonus": 1},
		"bane_name": "Barren Fields", "bane_text": "-2 reinforcement dice each turn.",
		"bane": {"reinforce_bonus": -2}},
	# --- Norse --------------------------------------------------------------------------------
	{"id": "odin", "pantheon": "norse", "role": PRIMARY, "name": "Odin", "title": "The All-Father",
		"boon_name": "Wisdom of the Runes", "boon_text": "Your dice that show 1 are rolled again, in attack and defence.",
		"boon": {"reroll_ones_attack": true, "reroll_ones_defense": true}},
	{"id": "thor", "pantheon": "norse", "role": PRIMARY, "name": "Thor", "title": "The Thunderer",
		"boon_name": "Opening Thunder", "boon_text": "+5 to the first attack of each turn, +1 to every other.",
		"boon": {"first_attack_bonus": 4, "attack_bonus": 1}},
	{"id": "frigg", "pantheon": "norse", "role": PRIMARY, "name": "Frigg", "title": "Queen of Asgard",
		"boon_name": "Hearth and Home", "boon_text": "A territory that holds against an attack gains 1 die, and +1 to every defence.",
		"boon": {"defend_reward": 1, "defense_bonus": 1}},
	{"id": "tyr", "pantheon": "norse", "role": SECONDARY, "name": "Tyr", "title": "God of the Just War",
		"boon_name": "Just War", "boon_text": "+1 to every attack and +1 to every defence.",
		"boon": {"attack_bonus": 1, "defense_bonus": 1},
		"bane_name": "Bound by Oath", "bane_text": "At most 4 attacks per turn.",
		"bane": {"max_attacks": 4}},
	{"id": "loki", "pantheon": "norse", "role": SECONDARY, "name": "Loki", "title": "The Trickster",
		"boon_name": "Trickery", "boon_text": "+3 when attacking a larger army, and your attacks win ties.",
		"boon": {"underdog_bonus": 3, "attack_wins_ties": true},
		"bane_name": "Betrayal", "bane_text": "Your defences lose ties.",
		"bane": {"defense_loses_ties": true}},
	{"id": "hel", "pantheon": "norse", "role": SECONDARY, "name": "Hel", "title": "Queen of the Dead",
		"boon_name": "Cold Halls", "boon_text": "+1 to every defence, and a territory that holds gains 1 die.",
		"boon": {"defense_bonus": 1, "defend_reward": 1},
		"bane_name": "Cold Patience", "bane_text": "You may not attack a territory with more dice than yours.",
		"bane": {"no_attack_stronger": true}},
	# --- Egyptian -----------------------------------------------------------------------------
	{"id": "ra", "pantheon": "egyptian", "role": PRIMARY, "name": "Ra", "title": "The Sun Who Sails the Sky",
		"boon_name": "Sun's Glare", "boon_text": "Your attacking dice never show a 1.",
		"boon": {"min_attack_face": 2}},
	{"id": "isis", "pantheon": "egyptian", "role": PRIMARY, "name": "Isis", "title": "Mistress of Magic",
		"boon_name": "Breath of Life", "boon_text": "Miracle (4 favour): add 3 dice to one of your territories.",
		"boon": {"miracle": {"kind": "bless", "amount": 3, "cost": 4}}},
	{"id": "ptah", "pantheon": "egyptian", "role": PRIMARY, "name": "Ptah", "title": "The Divine Builder",
		"boon_name": "Master Builder", "boon_text": "Your territories hold up to 9 dice, and +1 reinforcement die.",
		"boon": {"max_dice_bonus": 1, "reinforce_bonus": 1}},
	{"id": "sekhmet", "pantheon": "egyptian", "role": SECONDARY, "name": "Sekhmet", "title": "The Lioness",
		"boon_name": "Rampage", "boon_text": "+2 to every attack.",
		"boon": {"attack_bonus": 2},
		"bane_name": "Unquenchable Wrath", "bane_text": "Every failed attack costs 2 dice from another of your territories.",
		"bane": {"hubris": 2}},
	{"id": "set", "pantheon": "egyptian", "role": SECONDARY, "name": "Set", "title": "Lord of the Red Desert",
		"boon_name": "Desert Storm", "boon_text": "+1 to every attack, and +1 die on the first territory you conquer each turn.",
		"boon": {"attack_bonus": 1, "conquest_bonus": 1},
		"bane_name": "Chaos Tithe", "bane_text": "At the end of each turn your largest stack loses 2 dice.",
		"bane": {"tribute": 2}},
	{"id": "anubis", "pantheon": "egyptian", "role": SECONDARY, "name": "Anubis", "title": "Guardian of the Scales",
		"boon_name": "Weigher of Hearts", "boon_text": "+1 to every defence, and +2 favour whenever you gain favour.",
		"boon": {"defense_bonus": 1, "favor_bonus": 2},
		"bane_name": "Patient Judge", "bane_text": "At most 2 attacks per turn.",
		"bane": {"max_attacks": 2}},
	# --- Chinese ------------------------------------------------------------------------------
	{"id": "jade_emperor", "pantheon": "chinese", "role": PRIMARY, "name": "Jade Emperor", "title": "Ruler of Heaven",
		"boon_name": "Heavenly Mandate", "boon_text": "+2 reinforcement dice, and reinforcements go to your borders first.",
		"boon": {"reinforce_bonus": 2, "smart_reinforce": true}},
	{"id": "guanyin", "pantheon": "chinese", "role": PRIMARY, "name": "Guanyin", "title": "She Who Hears the World",
		"boon_name": "Mercy", "boon_text": "Miracle (1 favour): one of your territories gets +5 defence until your next turn. +1 to every defence, and a territory that holds gains 1 die.",
		"boon": {"miracle": {"kind": "ward", "amount": 5, "cost": 1}, "defend_reward": 1, "defense_bonus": 1}},
	{"id": "guan_yu", "pantheon": "chinese", "role": PRIMARY, "name": "Guan Yu", "title": "The Loyal General",
		"boon_name": "Loyal Blade", "boon_text": "+1 die on the first territory you conquer each turn, and +2 reinforcement dice.",
		"boon": {"conquest_bonus": 1, "reinforce_bonus": 2}},
	{"id": "sun_wukong", "pantheon": "chinese", "role": SECONDARY, "name": "Sun Wukong", "title": "The Monkey King",
		"boon_name": "Seventy-two Transformations", "boon_text": "Attacking 1s are rolled again, +2 against larger armies, and attacks win ties.",
		"boon": {"reroll_ones_attack": true, "underdog_bonus": 2, "attack_wins_ties": true},
		"bane_name": "Restless", "bane_text": "No reserve (extra dice are lost), and -2 reinforcement dice each turn.",
		"bane": {"no_reserve": true, "reinforce_bonus": -2}},
	{"id": "nezha", "pantheon": "chinese", "role": SECONDARY, "name": "Nezha", "title": "The Third Lotus Prince",
		"boon_name": "Wind-Fire Wheels", "boon_text": "+4 to the first attack of each turn, +2 when attacking from a full stack.",
		"boon": {"first_attack_bonus": 4, "full_stack_bonus": 2},
		"bane_name": "Child's Temper", "bane_text": "-1 to the defence of every territory you hold.",
		"bane": {"defense_bonus": -1}},
	{"id": "hou_yi", "pantheon": "chinese", "role": SECONDARY, "name": "Hou Yi", "title": "The Archer Who Shot the Suns",
		"boon_name": "Nine Arrows", "boon_text": "Miracle (2 favour): strike an enemy territory, destroying 3 of its dice.",
		"boon": {"miracle": {"kind": "smite", "amount": 3, "cost": 2}},
		"bane_name": "Exile", "bane_text": "At the end of each turn your largest stack loses 1 die.",
		"bane": {"tribute": 1}},
	# --- Mayan --------------------------------------------------------------------------------
	{"id": "itzamna", "pantheon": "mayan", "role": PRIMARY, "name": "Itzamna", "title": "Lord of the Heavens",
		"boon_name": "Celestial Scribe", "boon_text": "Attacking 1s are rolled again, and +1 favour whenever you gain favour.",
		"boon": {"reroll_ones_attack": true, "favor_bonus": 1}},
	{"id": "chaak", "pantheon": "mayan", "role": PRIMARY, "name": "Chaak", "title": "Bringer of Rain",
		"boon_name": "Life-giving Rain", "boon_text": "Miracle (2 favour): add 2 dice to one of your territories.",
		"boon": {"miracle": {"kind": "bless", "amount": 2, "cost": 2}}},
	{"id": "ix_chel", "pantheon": "mayan", "role": PRIMARY, "name": "Ix Chel", "title": "Lady of the Moon",
		"boon_name": "Moon's Tide", "boon_text": "+1 reinforcement die, and defending 1s are rolled again.",
		"boon": {"reinforce_bonus": 1, "reroll_ones_defense": true}},
	{"id": "kukulkan", "pantheon": "mayan", "role": SECONDARY, "name": "Kukulkan", "title": "The Feathered Serpent",
		"boon_name": "Serpent Wind", "boon_text": "+2 to every attack, and reinforcements go to your borders first.",
		"boon": {"attack_bonus": 2, "smart_reinforce": true},
		"bane_name": "Blood Offering", "bane_text": "At the end of each turn your largest stack loses 1 die.",
		"bane": {"tribute": 1}},
	{"id": "huracan", "pantheon": "mayan", "role": SECONDARY, "name": "Huracan", "title": "Heart of the Sky",
		"boon_name": "Great Flood", "boon_text": "Miracle (2 favour): strike an enemy territory, destroying 2 of its dice. +1 to every attack.",
		"boon": {"miracle": {"kind": "smite", "amount": 2, "cost": 2}, "attack_bonus": 1},
		"bane_name": "Uprooted", "bane_text": "-1 to the defence of every territory you hold.",
		"bane": {"defense_bonus": -1}},
	{"id": "ah_puch", "pantheon": "mayan", "role": SECONDARY, "name": "Ah Puch", "title": "Lord of Xibalba",
		"boon_name": "Harvest of Souls", "boon_text": "+1 to every attack, +1 die on the first territory you conquer each turn, +2 favour whenever you gain favour.",
		"boon": {"attack_bonus": 1, "conquest_bonus": 1, "favor_bonus": 2},
		"bane_name": "Withering", "bane_text": "-2 reinforcement dice each turn.",
		"bane": {"reinforce_bonus": -2}},
	# --- Mesopotamian -------------------------------------------------------------------------
	{"id": "marduk", "pantheon": "mesopotamian", "role": PRIMARY, "name": "Marduk", "title": "Slayer of Tiamat",
		"boon_name": "Champion of the Gods", "boon_text": "+1 to every attack.",
		"boon": {"attack_bonus": 1}},
	{"id": "enki", "pantheon": "mesopotamian", "role": PRIMARY, "name": "Enki", "title": "Lord of the Sweet Waters",
		"boon_name": "Waters of Life", "boon_text": "+1 reinforcement die, and +1 favour whenever you gain favour.",
		"boon": {"reinforce_bonus": 1, "favor_bonus": 1}},
	{"id": "utu", "pantheon": "mesopotamian", "role": PRIMARY, "name": "Utu", "title": "The Sun of Justice",
		"boon_name": "Chariot of the Sun", "boon_text": "+2 when attacking from a full stack, and defending 1s are rolled again.",
		"boon": {"full_stack_bonus": 2, "reroll_ones_defense": true}},
	{"id": "inanna", "pantheon": "mesopotamian", "role": SECONDARY, "name": "Inanna", "title": "Queen of Heaven",
		"boon_name": "Morning Star", "boon_text": "+2 to every attack, and +1 die on the first territory you conquer each turn.",
		"boon": {"attack_bonus": 2, "conquest_bonus": 1},
		"bane_name": "Descent", "bane_text": "-1 to every defence, and no reserve (extra dice are lost).",
		"bane": {"defense_bonus": -1, "no_reserve": true}},
	{"id": "ereshkigal", "pantheon": "mesopotamian", "role": SECONDARY, "name": "Ereshkigal", "title": "Queen of the Great Below",
		"boon_name": "Seven Gates", "boon_text": "+3 to every defence.",
		"boon": {"defense_bonus": 3},
		"bane_name": "Land of No Return", "bane_text": "At most 2 attacks per turn.",
		"bane": {"max_attacks": 2}},
	{"id": "tiamat", "pantheon": "mesopotamian", "role": SECONDARY, "name": "Tiamat", "title": "Mother of Monsters",
		"boon_name": "Primordial Sea", "boon_text": "Your territories hold up to 10 dice, and +2 reinforcement dice.",
		"boon": {"max_dice_bonus": 2, "reinforce_bonus": 2},
		"bane_name": "Brood Hunger", "bane_text": "At the end of each turn your largest stack loses 1 die.",
		"bane": {"tribute": 1}},
]


static func pantheon(id: String) -> Dictionary:
	for p in PANTHEONS:
		if p["id"] == id:
			return p
	return PANTHEONS[0]


static func god(id: String) -> Dictionary:
	for g in GODS:
		if g["id"] == id:
			return g
	return {}


## The gods of `pantheon_id` with `role` (PRIMARY or SECONDARY), in catalog order.
static func gods_of(pantheon_id: String, role: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g in GODS:
		if g["pantheon"] == pantheon_id and g["role"] == role:
			out.append(g)
	return out


static func portrait_path(god_id: String) -> String:
	var g := god(god_id)
	return "res://assets/gods/%s/%s.jpg" % [g.get("pantheon", ""), god_id]


static func dice_face_path(skin: String, value: int) -> String:
	return "res://assets/dice/%s/face_%d.png" % [skin, clampi(value, 1, 6)]
