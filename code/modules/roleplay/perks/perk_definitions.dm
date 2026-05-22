// 42 perks across 7 SPECIAL categories

GLOBAL_LIST_EMPTY(perk_datums)

/datum/perk
	var/id = ""
	var/name = ""
	var/desc = ""
	var/special_stat = ""
	var/special_min = 0
	var/trait_given = ""
	var/requires_perk = ""
	var/tier = 1

/datum/perk/New()
	. = ..()
	if(id)
		GLOB.perk_datums[id] = src

// ==========================================
// STRENGTH PERKS (Melee/Defense)
// ==========================================

/datum/perk/iron_fist
	id = "iron_fist"
	name = "Iron Fist"
	desc = "Deal +20% melee damage with unarmed attacks. Your fists are deadly weapons."
	special_stat = "S"
	special_min = 4
	trait_given = TRAIT_PERK_IRON_FIST

/datum/perk/big_leagues
	id = "big_leagues"
	name = "Big Leagues"
	desc = "Deal +1 tier of melee damage. Your attacks hit harder."
	special_stat = "S"
	special_min = 6
	trait_given = TRAIT_PERK_BIG_LEAGUES
	requires_perk = "iron_fist"
	tier = 2

/datum/perk/steelfist
	id = "steelfist"
	name = "Steel Fist"
	desc = "Unarmed attacks ignore 10 points of armor. Hit through defenses."
	special_stat = "S"
	special_min = 5
	trait_given = TRAIT_PERK_STEELFIST

/datum/perk/tank
	id = "tank"
	name = "Tank"
	desc = "Reduce all incoming damage by 10%. You can take a hit."
	special_stat = "S"
	special_min = 7
	trait_given = TRAIT_PERK_TANK
	requires_perk = "iron_fist"
	tier = 2

/datum/perk/piercing_strike
	id = "piercing_strike"
	name = "Piercing Strike"
	desc = "Melee attacks ignore 20% of target armor. Penetrating blows."
	special_stat = "S"
	special_min = 8
	trait_given = TRAIT_PERK_PIERCING_STRIKE
	requires_perk = "big_leagues"
	tier = 2

/datum/perk/martial_arts
	id = "martial_arts"
	name = "Martial Arts"
	desc = "+15% dodge chance when fighting unarmed. Swift and elusive."
	special_stat = "S"
	special_min = 5
	trait_given = TRAIT_PERK_MARTIAL_ARTS

// ==========================================
// PERCEPTION PERKS (Accuracy/Vision)
// ==========================================

/datum/perk/awareness
	id = "awareness"
	name = "Awareness"
	desc = "See enemy health bars when examining. Know your target."
	special_stat = "P"
	special_min = 4
	trait_given = TRAIT_PERK_AWARENESS

/datum/perk/sniper
	id = "sniper"
	name = "Sniper"
	desc = "+15% projectile accuracy. Bullets find their mark."
	special_stat = "P"
	special_min = 6
	trait_given = TRAIT_PERK_SNIPER

/datum/perk/night_sight
	id = "night_sight"
	name = "Night Sight"
	desc = "Permanent low-light vision. The dark holds no secrets."
	special_stat = "P"
	special_min = 5
	trait_given = TRAIT_PERK_NIGHT_SIGHT

/datum/perk/targeted
	id = "targeted"
	name = "Targeted"
	desc = "+10% critical hit chance with ranged weapons. Precision kills."
	special_stat = "P"
	special_min = 7
	trait_given = TRAIT_PERK_TARGETED
	requires_perk = "sniper"
	tier = 2

/datum/perk/detective
	id = "detective"
	name = "Detective"
	desc = "Reveal hidden items and traps in tiles. Nothing stays hidden."
	special_stat = "P"
	special_min = 6
	trait_given = TRAIT_PERK_DETECTIVE

/datum/perk/explorer
	id = "explorer"
	name = "Explorer"
	desc = "Reveal more map areas on your radar. Know the territory."
	special_stat = "P"
	special_min = 4
	trait_given = TRAIT_PERK_EXPLORER

// ==========================================
// ENDURANCE PERKS (Survival)
// ==========================================

/datum/perk/rad_resist
	id = "rad_resist"
	name = "Rad Resistance"
	desc = "+50% radiation resistance. The glow doesn't bother you."
	special_stat = "E"
	special_min = 4
	trait_given = TRAIT_PERK_RAD_RESIST

/datum/perk/toxicity
	id = "toxicity"
	name = "Toxicity"
	desc = "+50% poison and disease resistance. Tougher insides."
	special_stat = "E"
	special_min = 5
	trait_given = TRAIT_PERK_TOXICITY

/datum/perk/toughness
	id = "toughness"
	name = "Toughness"
	desc = "-10% all incoming damage. Built like a vault."
	special_stat = "E"
	special_min = 6
	trait_given = TRAIT_PERK_TOUGHNESS

/datum/perk/fast_healer
	id = "fast_healer"
	name = "Fast Healer"
	desc = "+25% healing from stimpaks and medicine. Recovery speed."
	special_stat = "E"
	special_min = 5
	trait_given = TRAIT_PERK_FAST_HEALER

/datum/perk/water_breathing
	id = "water_breathing"
	name = "Water Breather"
	desc = "Can breathe in contaminated water. Swim where others sink."
	special_stat = "E"
	special_min = 6
	trait_given = TRAIT_PERK_WATER_BREATHING
	requires_perk = "toxicity"
	tier = 2

/datum/perk/living_legend
	id = "living_legend"
	name = "Living Legend"
	desc = "-25% damage when below 30% health. Fight harder when hurt."
	special_stat = "E"
	special_min = 8
	trait_given = TRAIT_PERK_LIVING_LEGEND
	requires_perk = "toughness"
	tier = 3

// ==========================================
// CHARISMA PERKS (Social)
// ==========================================

/datum/perk/speaker
	id = "speaker"
	name = "Speaker"
	desc = "+20% speech check success. Words are weapons."
	special_stat = "C"
	special_min = 4
	trait_given = TRAIT_PERK_SPEAKER

/datum/perk/animal_friend
	id = "animal_friend"
	name = "Animal Friend"
	desc = "Animals are non-hostile to you. Even wild things trust you."
	special_stat = "C"
	special_min = 5
	trait_given = TRAIT_PERK_ANIMAL_FRIEND

/datum/perk/merchant
	id = "merchant"
	name = "Merchant"
	desc = "+10% better vendor prices. Better deals for friendly faces."
	special_stat = "C"
	special_min = 6
	trait_given = TRAIT_PERK_MERCHANT
	requires_perk = "speaker"
	tier = 2

/datum/perk/leader
	id = "leader"
	name = "Leader"
	desc = "Your companions deal +20% damage. Lead from the front."
	special_stat = "C"
	special_min = 7
	trait_given = TRAIT_PERK_LEADER
	requires_perk = "animal_friend"
	tier = 2

/datum/perk/intimidator
	id = "intimidator"
	name = "Intimidator"
	desc = "+15% success rate on fear actions. Don't make me angry."
	special_stat = "C"
	special_min = 6
	trait_given = TRAIT_PERK_INTIMIDATOR

/datum/perk/voice_of_charisma
	id = "voice_of_charisma"
	name = "Voice of Charisma"
	desc = "+10% to all social interactions. The gift of gab."
	special_stat = "C"
	special_min = 8
	trait_given = TRAIT_PERK_VOICE_OF_CHARISMA
	requires_perk = "speaker"
	tier = 3

// ==========================================
// INTELLIGENCE PERKS (Crafting/Knowledge)
// ==========================================

/datum/perk/scavenger
	id = "scavenger"
	name = "Scavenger"
	desc = "See item stats and values on pickup. Know what it's worth."
	special_stat = "I"
	special_min = 4
	trait_given = TRAIT_PERK_SCAVENGER

/datum/perk/medic
	id = "medic"
	name = "Medic"
	desc = "+25% healing item efficiency. Make the most of supplies."
	special_stat = "I"
	special_min = 5
	trait_given = TRAIT_PERK_MEDIC

/datum/perk/chemist_perk
	id = "chemist"
	name = "Chemist"
	desc = "+30% chem potency. Your mixtures work better."
	special_stat = "I"
	special_min = 6
	trait_given = TRAIT_PERK_CHEMIST
	requires_perk = "medic"
	tier = 2

/datum/perk/hacker
	id = "hacker"
	name = "Hacker"
	desc = "Access more terminal functions. The code yields to you."
	special_stat = "I"
	special_min = 6
	trait_given = TRAIT_PERK_HACKER

/datum/perk/weaponsmith
	id = "weaponsmith"
	name = "Weapon Smith"
	desc = "Unlock advanced weapon crafting recipes. Build better guns."
	special_stat = "I"
	special_min = 7
	trait_given = TRAIT_PERK_WEAPONSMITH
	requires_perk = "scavenger"
	tier = 2

/datum/perk/greedy_gift
	id = "greedy_gift"
	name = "Greedy Gift"
	desc = "+10% loot from containers. More loot, more luck."
	special_stat = "I"
	special_min = 5
	trait_given = TRAIT_PERK_GREEDY_GIFT
	requires_perk = "scavenger"
	tier = 2

// ==========================================
// AGILITY PERKS (Speed/Evasion)
// ==========================================

/datum/perk/action_girl
	id = "action_girl"
	name = "Action Boy/Girl"
	desc = "+25% sprint buffer regeneration. Keep running longer."
	special_stat = "A"
	special_min = 4
	trait_given = TRAIT_PERK_ACTION_GIRL

/datum/perk/moving_target
	id = "moving_target"
	name = "Moving Target"
	desc = "-15% damage taken while moving. Harder to hit on the run."
	special_stat = "A"
	special_min = 5
	trait_given = TRAIT_PERK_MOVING_TARGET

/datum/perk/dodger
	id = "dodger"
	name = "Dodger"
	desc = "+10% dodge chance. Slippery target."
	special_stat = "A"
	special_min = 6
	trait_given = TRAIT_PERK_DODGER

/datum/perk/speed_demon
	id = "speed_demon"
	name = "Speed Demon"
	desc = "+15% movement speed. You're faster than fast."
	special_stat = "A"
	special_min = 7
	trait_given = TRAIT_PERK_SPEED_DEMON
	requires_perk = "action_girl"
	tier = 2

/datum/perk/silent_running
	id = "silent_running"
	name = "Silent Running"
	desc = "Your footsteps are silent. Move like a ghost."
	special_stat = "A"
	special_min = 6
	trait_given = TRAIT_PERK_SILENT_RUNNING

/datum/perk/light_step
	id = "light_step"
	name = "Light Step"
	desc = "Floor traps don't trigger for you. Tread carefully."
	special_stat = "A"
	special_min = 5
	trait_given = TRAIT_PERK_LIGHT_STEP

// ==========================================
// LUCK PERKS (Random/Items)
// ==========================================

/datum/perk/fortune_finder
	id = "fortune_finder"
	name = "Fortune Finder"
	desc = "+25% caps from loot and containers. Riches find you."
	special_stat = "L"
	special_min = 4
	trait_given = TRAIT_PERK_FORTUNE_FINDER

/datum/perk/mysterious_stranger
	id = "mysterious_stranger"
	name = "Mysterious Stranger"
	desc = "5% chance for instant-kill on attacks. The stranger aids you."
	special_stat = "L"
	special_min = 6
	trait_given = TRAIT_PERK_MYSTERIOUS_STRANGER

/datum/perk/looter
	id = "looter"
	name = "Looter"
	desc = "+15% item drop rates from enemies and containers."
	special_stat = "L"
	special_min = 5
	trait_given = TRAIT_PERK_LOOTER
	requires_perk = "fortune_finder"
	tier = 2

/datum/perk/critical_eye
	id = "critical_eye"
	name = "Critical Eye"
	desc = "+10% critical hit chance. Lucky hits."
	special_stat = "L"
	special_min = 7
	trait_given = TRAIT_PERK_CRITICAL_EYE

/datum/perk/safe_for_work
	id = "safe_for_work"
	name = "Safe for Work"
	desc = "No critical fail chance. Always aim true."
	special_stat = "L"
	special_min = 8
	trait_given = TRAIT_PERK_SAFE_FOR_WORK
	requires_perk = "critical_eye"
	tier = 3

/datum/perk/casino
	id = "casino"
	name = "Casino"
	desc = "+20% win rate at slot machines. Lady luck smiles."
	special_stat = "L"
	special_min = 6
	trait_given = TRAIT_PERK_CASINO

// Initialize all perks on game start
/proc/initialize_perks()
	for(var/type in subtypesof(/datum/perk))
		if(type == /datum/perk)
			continue
		new type()
	log_game("Initialized [length(GLOB.perk_datums)] perks")
