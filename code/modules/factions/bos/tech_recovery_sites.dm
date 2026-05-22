// Brotherhood of Steel Tech Recovery Mission Sites
// Pre-defined missions with locations and rewards

// ============ EASY MISSIONS (Knight+) ============

/datum/tech_recovery_mission/raider_stash
	id = "raider_stash"
	name = "Raider Tech Cache"
	description = "Intelligence suggests a raider group has been hoarding pre-war technology at a nearby encampment."
	difficulty = BOS_DIFFICULTY_EASY
	required_rank = BOS_RANK_KNIGHT
	research_points = 50
	location_name = "Raider Encampment"
	possible_tech = list(
		/datum/tech_item/common,
		/datum/tech_item/common/holotape,
		/datum/tech_item/common/components
	)

/datum/tech_recovery_mission/crashed_vertibird
	id = "crashed_vertibird"
	name = "Crashed Vertibird Site"
	description = "A pre-war vertibird crash site has been located. Salvage any recoverable technology."
	difficulty = BOS_DIFFICULTY_EASY
	required_rank = BOS_RANK_KNIGHT
	research_points = 100
	location_name = "Crash Site"
	possible_tech = list(
		/datum/tech_item/common,
		/datum/tech_item/uncommon,
		/datum/tech_item/uncommon/power_armor_parts
	)

/datum/tech_recovery_mission/abandoned_shack
	id = "abandoned_shack"
	name = "Scavenger Cache"
	description = "A scavenger's stash has been discovered. Check for any pre-war technology."
	difficulty = BOS_DIFFICULTY_EASY
	required_rank = BOS_RANK_KNIGHT
	research_points = 40
	location_name = "Abandoned Shack"
	possible_tech = list(
		/datum/tech_item/common,
		/datum/tech_item/common/components
	)

// ============ MEDIUM MISSIONS (Knight Sergeant+) ============

/datum/tech_recovery_mission/repconn_hq
	id = "repconn_hq"
	name = "REPCONN Headquarters"
	description = "REPCONN's headquarters may contain valuable rocketry and energy weapon research."
	difficulty = BOS_DIFFICULTY_MEDIUM
	required_rank = BOS_RANK_KNIGHT_SERGEANT
	research_points = 150
	location_name = "REPCONN HQ"
	possible_tech = list(
		/datum/tech_item/uncommon,
		/datum/tech_item/uncommon/power_armor_parts,
		/datum/tech_item/rare
	)

/datum/tech_recovery_mission/satellite_array
	id = "satellite_array"
	name = "Satellite Array"
	description = "A pre-war satellite communications array. The control systems may contain valuable data."
	difficulty = BOS_DIFFICULTY_MEDIUM
	required_rank = BOS_RANK_KNIGHT_SERGEANT
	research_points = 175
	location_name = "Satellite Array"
	possible_tech = list(
		/datum/tech_item/uncommon,
		/datum/tech_item/rare,
		/datum/tech_item/common/holotape
	)

/datum/tech_recovery_mission/bunker_hill
	id = "bunker_hill"
	name = "Hidden Bunker"
	description = "A sealed pre-war bunker has been discovered. Break in and catalog its contents."
	difficulty = BOS_DIFFICULTY_MEDIUM
	required_rank = BOS_RANK_KNIGHT_SERGEANT
	research_points = 200
	location_name = "Hidden Bunker"
	possible_tech = list(
		/datum/tech_item/uncommon,
		/datum/tech_item/uncommon/power_armor_parts,
		/datum/tech_item/rare
	)

// ============ HARD MISSIONS (Paladin+) ============

/datum/tech_recovery_mission/vault_raid
	id = "vault_raid"
	name = "Vault Tech Recovery"
	description = "A sealed vault may contain advanced pre-war technology. Expect automated defenses."
	difficulty = BOS_DIFFICULTY_HARD
	required_rank = BOS_RANK_PALADIN
	research_points = 250
	location_name = "Sealed Vault"
	possible_tech = list(
		/datum/tech_item/rare,
		/datum/tech_item/rare/energy_core,
		/datum/tech_item/legendary
	)

/datum/tech_recovery_mission/military_base
	id = "military_base"
	name = "Military Base Raid"
	description = "A pre-war military installation. Heavily fortified with potential automated turrets."
	difficulty = BOS_DIFFICULTY_HARD
	required_rank = BOS_RANK_PALADIN
	research_points = 300
	location_name = "Military Base"
	possible_tech = list(
		/datum/tech_item/rare,
		/datum/tech_item/uncommon/power_armor_parts,
		/datum/tech_item/legendary/pa_blueprint
	)

/datum/tech_recovery_mission/enclave_outpost
	id = "enclave_outpost"
	name = "Abandoned Enclave Outpost"
	description = "A remnant Enclave facility. Their advanced technology could prove valuable."
	difficulty = BOS_DIFFICULTY_HARD
	required_rank = BOS_RANK_PALADIN
	research_points = 350
	location_name = "Enclave Outpost"
	possible_tech = list(
		/datum/tech_item/rare,
		/datum/tech_item/rare/energy_core,
		/datum/tech_item/legendary
	)

// ============ VERY HARD MISSIONS (Paladin Commander+) ============

/datum/tech_recovery_mission/pozzed_facility
	id = "pozzed_facility"
	name = "Pozzed Research Facility"
	description = "A highly irradiated pre-war research facility. Extreme radiation hazards present."
	difficulty = BOS_DIFFICULTY_VERY_HARD
	required_rank = BOS_RANK_PALADIN_COMMANDER
	research_points = 400
	location_name = "Pozzed Facility"
	possible_tech = list(
		/datum/tech_item/legendary,
		/datum/tech_item/legendary/pa_blueprint,
		/datum/tech_item/rare/energy_core
	)

/datum/tech_recovery_mission/ai_facility
	id = "ai_facility"
	name = "AI Research Center"
	description = "A pre-war artificial intelligence research center. Expect automated security systems."
	difficulty = BOS_DIFFICULTY_VERY_HARD
	required_rank = BOS_RANK_PALADIN_COMMANDER
	research_points = 450
	location_name = "AI Research Center"
	possible_tech = list(
		/datum/tech_item/legendary,
		/datum/tech_item/legendary/pa_blueprint
	)

// ============ EXTREME MISSIONS (Head Paladin+) ============

/datum/tech_recovery_mission/area51
	id = "area51"
	name = "Classified Military Installation"
	description = "A top-secret pre-war military research facility. Highest priority technology recovery."
	difficulty = BOS_DIFFICULTY_EXTREME
	required_rank = BOS_RANK_HEAD_PALADIN
	research_points = 500
	location_name = "Classified Site"
	possible_tech = list(
		/datum/tech_item/legendary,
		/datum/tech_item/legendary/pa_blueprint,
		/datum/tech_item/legendary
	)

/datum/tech_recovery_mission/enclave_bunker
	id = "enclave_bunker"
	name = "Enclave Command Bunker"
	description = "A major Enclave command and control facility. Advanced technology and heavy security expected."
	difficulty = BOS_DIFFICULTY_EXTREME
	required_rank = BOS_RANK_HEAD_PALADIN
	research_points = 500
	location_name = "Enclave Command"
	possible_tech = list(
		/datum/tech_item/legendary,
		/datum/tech_item/legendary/pa_blueprint,
		/datum/tech_item/rare/energy_core
	)
