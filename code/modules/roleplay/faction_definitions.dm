// Defines all playable factions and their rank structures

GLOBAL_LIST_INIT(factions, init_factions())

/proc/init_factions()
	var/list/factions = list()
	factions["ncr"] = new /datum/faction/ncr()
	factions["legion"] = new /datum/faction/legion()
	factions["bos"] = new /datum/faction/brotherhood()
	factions["enclave"] = new /datum/faction/enclave()
	factions["greatkhans"] = new /datum/faction/great_khans()
	factions["followers"] = new /datum/faction/followers()
	factions["raiders"] = new /datum/faction/raiders()
	factions["vipers"] = new /datum/faction/vipers()
	factions["jackals"] = new /datum/faction/jackals()
	return factions

// Reputation levels like Fallout: New Vegas
// Threshold: Public perception (what NPCs/players think)
// Private: Faction leadership's actual opinion

// Reputation thresholds defined in code/__DEFINES/roleplay_constants.dm

/datum/faction
	var/id = ""
	var/name = ""
	var/description = ""
	var/list/ranks = list()
	var/list/enemy_factions = list()
	var/list/friendly_factions = list()
	var/default_rank = "Neutral"

/datum/faction/ncr
	id = "ncr"
	name = "New California Republic"
	description = "The democratic republic striving to restore order to the wasteland."
	enemy_factions = list("legion", "raiders", "enclave")
	friendly_factions = list("followers")
	ranks = list(
		"Vilified" = -100,
		"Hated" = -50,
		"Disliked" = -25,
		"Shunned" = 0,
		"Neutral" = 10,
		"Accepted" = 25,
		"Liked" = 50,
		"Admired" = 75,
		"Idolized" = 100
	)
	default_rank = "Neutral"

/datum/faction/legion
	id = "legion"
	name = "Caesar's Legion"
	description = "A totalitarian regime dedicated to conquering the wasteland."
	enemy_factions = list("ncr", "bos", "enclave")
	friendly_factions = list()
	ranks = list(
		"Vilified" = -100,
		"Hated" = -50,
		"Disliked" = -25,
		"Shunned" = 0,
		"Neutral" = 10,
		"Accepted" = 25,
		"Liked" = 50,
		"Admired" = 75,
		"Idolized" = 100
	)
	default_rank = "Neutral"

/datum/faction/brotherhood
	id = "bos"
	name = "Brotherhood of Steel"
	description = "A techno-knightly order dedicated to preserving pre-war technology."
	enemy_factions = list("legion", "enclave", "raiders")
	friendly_factions = list()
	ranks = list(
		"Vilified" = -100,
		"Hated" = -50,
		"Disliked" = -25,
		"Shunned" = 0,
		"Neutral" = 10,
		"Accepted" = 25,
		"Liked" = 50,
		"Admired" = 75,
		"Idolized" = 100
	)
	default_rank = "Neutral"

/datum/faction/enclave
	id = "enclave"
	name = "The Enclave"
	description = "Remnants of the pre-war US government."
	enemy_factions = list("ncr", "legion", "bos")
	friendly_factions = list()
	ranks = list(
		"Vilified" = -100,
		"Hated" = -50,
		"Disliked" = -25,
		"Shunned" = 0,
		"Neutral" = 10,
		"Accepted" = 25,
		"Liked" = 50,
		"Admired" = 75,
		"Idolized" = 100
	)
	default_rank = "Neutral"

/datum/faction/great_khans
	id = "greatkhans"
	name = "Great Khans"
	description = "A raider clan with a code of honor."
	enemy_factions = list("ncr")
	friendly_factions = list("legion", "raiders")
	ranks = list(
		"Vilified" = -100,
		"Hated" = -50,
		"Disliked" = -25,
		"Shunned" = 0,
		"Neutral" = 10,
		"Accepted" = 25,
		"Liked" = 50,
		"Admired" = 75,
		"Idolized" = 100
	)
	default_rank = "Neutral"

/datum/faction/followers
	id = "followers"
	name = "Followers of the Apocrypha"
	description = "Scholars dedicated to preserving knowledge and helping others."
	enemy_factions = list()
	friendly_factions = list("ncr", "bos")
	ranks = list(
		"Vilified" = -100,
		"Hated" = -50,
		"Disliked" = -25,
		"Shunned" = 0,
		"Neutral" = 10,
		"Accepted" = 25,
		"Liked" = 50,
		"Admired" = 75,
		"Idolized" = 100
	)
	default_rank = "Neutral"

/datum/faction/raiders
	id = "raiders"
	name = "Raiders"
	description = "Survivors who take what they want."
	enemy_factions = list("ncr", "legion", "bos", "enclave")
	friendly_factions = list("greatkhans", "vipers", "jackals")
	ranks = list(
		"Vilified" = -100,
		"Hated" = -50,
		"Disliked" = -25,
		"Shunned" = 0,
		"Neutral" = 10,
		"Accepted" = 25,
		"Liked" = 50,
		"Admired" = 75,
		"Idolized" = 100
	)
	default_rank = "Neutral"

/datum/faction/vipers
	id = "vipers"
	name = "Viper Gang"
	description = "A gang of slavers and raiders."
	enemy_factions = list("ncr", "legion")
	friendly_factions = list("raiders", "jackals")
	ranks = list(
		"Vilified" = -100,
		"Hated" = -50,
		"Disliked" = -25,
		"Shunned" = 0,
		"Neutral" = 10,
		"Accepted" = 25,
		"Liked" = 50,
		"Admired" = 75,
		"Idolized" = 100
	)
	default_rank = "Neutral"

/datum/faction/jackals
	id = "jackals"
	name = "Jackals"
	description = "A loosely organized gang of scavengers."
	enemy_factions = list("ncr")
	friendly_factions = list("raiders", "vipers")
	ranks = list(
		"Vilified" = -100,
		"Hated" = -50,
		"Disliked" = -25,
		"Shunned" = 0,
		"Neutral" = 10,
		"Accepted" = 25,
		"Liked" = 50,
		"Admired" = 75,
		"Idolized" = 100
	)
	default_rank = "Neutral"

/proc/get_faction(faction_id)
	return GLOB.factions[faction_id]

/proc/get_faction_name(faction_id)
	var/datum/faction/F = get_faction(faction_id)
	return F ? F.name : faction_id

/proc/get_faction_rank(faction_id, reputation)
	var/datum/faction/F = get_faction(faction_id)
	if(!F)
		return "Unknown"
	
	// Find highest rank whose threshold we meet or exceed
	// Ranks are ordered lowest to highest, so iterate backwards
	var/last_rank = F.default_rank
	for(var/rank in F.ranks)
		if(reputation >= F.ranks[rank])
			last_rank = rank
	
	return last_rank
