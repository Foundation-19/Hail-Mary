// NCR Bounty Contracts
// Auto-generated bounties for NPC targets

/datum/ncr_contract
	var/id
	var/name
	var/description
	var/reward_min = 50
	var/reward_max = 150
	var/location_hint
	var/difficulty = 1
	var/target_type
	var/auto_generate = TRUE
	var/status = NCR_CONTRACT_STATUS_AVAILABLE
	var/accepted_by

/datum/ncr_contract/proc/get_data()
	return list(
		"id" = id,
		"name" = name,
		"description" = description,
		"reward" = rand(reward_min, reward_max),
		"location_hint" = location_hint,
		"difficulty" = difficulty,
		"target_type" = target_type,
		"status" = status,
		"accepted_by" = accepted_by,
	)

/datum/ncr_contract/raider_leader
	id = "contract_raider_leader"
	name = "Raider Leader"
	description = "Eliminate a notorious raider leader operating in the region."
	reward_min = 75
	reward_max = 150
	location_hint = "Vault 3 area"
	difficulty = 3
	target_type = "raider"

/datum/ncr_contract/legion_scout
	id = "contract_legion_scout"
	name = "Legion Scout"
	description = "Locate and eliminate Legion reconnaissance elements."
	reward_min = 50
	reward_max = 100
	location_hint = "Eastern territories"
	difficulty = 2
	target_type = "legion"

/datum/ncr_contract/fiend_chieftain
	id = "contract_fiend_chieftain"
	name = "Fiend Chieftain"
	description = "Neutralize a Fiend gang leader terrorizing travelers."
	reward_min = 100
	reward_max = 200
	location_hint = "South Vegas ruins"
	difficulty = 4
	target_type = "fiend"

/datum/ncr_contract/powder_ganger
	id = "contract_powder_ganger"
	name = "Powder Ganger Boss"
	description = "Bring to justice a Powder Ganger leader responsible for caravan raids."
	reward_min = 75
	reward_max = 125
	location_hint = "Correctional facility area"
	difficulty = 2
	target_type = "powder_ganger"

/datum/ncr_contract/escaped_convict
	id = "contract_escaped_convict"
	name = "Escaped Convict"
	description = "Track down and return an escaped prisoner from NCR custody."
	reward_min = 100
	reward_max = 300
	location_hint = "Last seen heading north"
	difficulty = 3
	target_type = "escapee"
	auto_generate = FALSE

/datum/ncr_contract/weapon_smuggler
	id = "contract_weapon_smuggler"
	name = "Weapon Smuggler"
	description = "Intercept a weapons smuggler supplying raiders with military hardware."
	reward_min = 100
	reward_max = 175
	location_hint = "Trade routes"
	difficulty = 3
	target_type = "smuggler"

/datum/ncr_contract/slaver_captain
	id = "contract_slaver_captain"
	name = "Slaver Captain"
	description = "Eliminate a slaver captain operating in NCR territory."
	reward_min = 150
	reward_max = 250
	location_hint = "Unknown"
	difficulty = 4
	target_type = "slaver"

/datum/ncr_contract/bounty_hunter_turncoat
	id = "contract_bounty_hunter_turncoat"
	name = "Turncoat Bounty Hunter"
	description = "A bounty hunter has been preying on NCR citizens. Bring them to justice."
	reward_min = 125
	reward_max = 200
	location_hint = "Wasteland"
	difficulty = 3
	target_type = "turncoat"
