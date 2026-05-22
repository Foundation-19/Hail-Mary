// Enclave Covert Operations
// Secret missions: assassination, sabotage, theft, intel

// ============ COVERT OPS MANAGER ============

/datum/enclave_covert_ops
	var/list/available_missions = list()
	var/list/active_missions = list()
	var/list/completed_missions = list()
	var/list/intel_database = list()
	var/intel_points = 0

/datum/enclave_covert_ops/proc/generate_missions()
	available_missions = list()
	
	var/list/mission_types = list(
		COVERT_TYPE_ASSASSINATION,
		COVERT_TYPE_SABOTAGE,
		COVERT_TYPE_THEFT,
		COVERT_TYPE_INTEL,
		COVERT_TYPE_RECON,
	)
	
	for(var/i in 1 to 5)
		var/datum/covert_mission/mission = new()
		mission.mission_id = "mission_[world.time]_[i]"
		mission.mission_type = pick(mission_types)
		mission.difficulty = rand(COVERT_DIFFICULTY_EASY, COVERT_DIFFICULTY_HARD)
		generate_mission_details(mission)
		available_missions += mission

/datum/enclave_covert_ops/proc/generate_mission_details(datum/covert_mission/mission)
	switch(mission.mission_type)
		if(COVERT_TYPE_ASSASSINATION)
			mission.name = "Operation [pick("Silent", "Shadow", "Dark")] [pick("Thunder", "Strike", "Blade")]"
			mission.description = "Eliminate high-value target."
			mission.target_name = pick("NCR Officer", "Legion Centurion", "BOS Knight", "Raider Leader")
			mission.reward_caps = 300 + (mission.difficulty * 100)
			mission.reward_reputation = 15 + (mission.difficulty * 5)
			mission.reward_intel = 50
		if(COVERT_TYPE_SABOTAGE)
			mission.name = "Operation [pick("Broken", "Shattered", "Cracked")] [pick("Gear", "Shield", "System")]"
			mission.description = "Destroy enemy equipment or infrastructure."
			mission.target_name = pick("Power Generator", "Water Purifier", "Comms Array", "Vehicle")
			mission.reward_caps = 150 + (mission.difficulty * 50)
			mission.reward_reputation = 10 + (mission.difficulty * 3)
			mission.reward_intel = 75
		if(COVERT_TYPE_THEFT)
			mission.name = "Operation [pick("Acquisition", "Retrieval", "Borrowed")] [pick("Item", "Asset", "Data")]"
			mission.description = "Steal valuable intel or technology."
			mission.target_name = pick("Holotape", "Blueprint", "Weapon Prototype", "Research Data")
			mission.reward_caps = 100 + (mission.difficulty * 75)
			mission.reward_reputation = 8 + (mission.difficulty * 2)
			mission.reward_intel = 100 + (mission.difficulty * 25)
		if(COVERT_TYPE_INTEL)
			mission.name = "Operation [pick("Eagle", "Watchful", "Silent")] [pick("Eye", "Observer", "Gaze")]"
			mission.description = "Gather intelligence on enemy operations."
			mission.target_name = pick("Enemy Movements", "Base Layout", "Supply Routes")
			mission.reward_caps = 75 + (mission.difficulty * 25)
			mission.reward_reputation = 5 + (mission.difficulty * 2)
			mission.reward_intel = 150 + (mission.difficulty * 50)
		if(COVERT_TYPE_RECON)
			mission.name = "Operation [pick("Scout", "Probe", "Survey")] [pick("Mission", "Run", "Check")]"
			mission.description = "Map enemy positions and defenses."
			mission.target_name = pick("NCR Territory", "Legion Camp", "BOS Bunker", "Settlement")
			mission.reward_caps = 50 + (mission.difficulty * 20)
			mission.reward_reputation = 3 + mission.difficulty
			mission.reward_intel = 75 + (mission.difficulty * 25)

/datum/enclave_covert_ops/proc/accept_mission(mob/user, mission_id)
	var/datum/covert_mission/mission = get_mission_by_id(mission_id)
	if(!mission)
		return FALSE

	if(mission.status != "available")
		return FALSE

	mission.status = "in_progress"
	mission.assigned_to = user.ckey
	mission.start_time = world.time

	active_missions += mission
	available_missions -= mission

	return TRUE

/datum/enclave_covert_ops/proc/complete_mission(mob/user, mission_id, success = TRUE)
	var/datum/covert_mission/mission = get_mission_by_id(mission_id)
	if(!mission)
		return FALSE

	if(success)
		mission.status = "completed"
		intel_points += mission.reward_intel

		var/obj/item/stack/f13Cash/caps/reward = new(get_turf(user))
		reward.amount = mission.reward_caps
		user.put_in_hands(reward)

		adjust_faction_reputation(user.ckey, "enclave", mission.reward_reputation)

		to_chat(user, span_notice("Mission completed! Reward: [mission.reward_caps] caps, [mission.reward_reputation] rep, [mission.reward_intel] intel."))
	else
		mission.status = "failed"
		to_chat(user, span_warning("Mission failed."))

	active_missions -= mission
	completed_missions += mission

	return TRUE

/datum/enclave_covert_ops/proc/get_mission_by_id(mission_id)
	for(var/datum/covert_mission/M in available_missions)
		if(M.mission_id == mission_id)
			return M
	for(var/datum/covert_mission/M in active_missions)
		if(M.mission_id == mission_id)
			return M
	return null

/datum/enclave_covert_ops/proc/spend_intel(amount)
	if(intel_points >= amount)
		intel_points -= amount
		return TRUE
	return FALSE

// ============ COVERT MISSION DATUM ============

/datum/covert_mission
	var/mission_id
	var/name = "Covert Operation"
	var/description = "A secret mission."
	var/mission_type = COVERT_TYPE_RECON
	var/difficulty = COVERT_DIFFICULTY_MEDIUM
	var/target_name
	var/target_location

	var/reward_caps = 100
	var/reward_reputation = 10
	var/reward_intel = 50

	var/status = "available"
	var/assigned_to
	var/start_time
	var/time_limit = 30 MINUTES

	var/detection_level = 0
	var/loadout_type = "stealth"

// ============ COVERT LOADOUT ============

/datum/covert_loadout
	var/name = "Stealth Operative"
	var/loadout_type = "stealth"
	var/list/equipment = list()
	var/detection_modifier = 0

/datum/covert_loadout/assault
	name = "Assault Loadout"
	loadout_type = "assault"
	detection_modifier = 30
	equipment = list(/obj/item/gun/ballistic/automatic/assault_rifle, /obj/item/clothing/suit/armor/vest)

/datum/covert_loadout/stealth
	name = "Stealth Loadout"
	loadout_type = "stealth"
	detection_modifier = -20
	equipment = list(/obj/item/gun/ballistic/automatic/pistol/silenced, /obj/item/clothing/suit/armor/vest/leather)

/datum/covert_loadout/infiltrator
	name = "Infiltrator Loadout"
	loadout_type = "infiltrator"
	detection_modifier = 10
	equipment = list(/obj/item/gun/ballistic/automatic/pistol, /obj/item/clothing/under/f13/ncr)

// ============ COVERT OPS TERMINAL ============

/obj/machinery/computer/enclave_covert_ops
	name = "Enclave Covert Operations Terminal"
	desc = "A terminal for managing secret Enclave operations."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/enclave_covert_ops/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/enclave_covert_ops/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CovertOps")
		ui.open()

/obj/machinery/computer/enclave_covert_ops/ui_data(mob/user)
	var/list/data = list()

	data["intel_points"] = GLOB.enclave_covert_ops.intel_points

	var/list/available_data = list()
	for(var/datum/covert_mission/M in GLOB.enclave_covert_ops.available_missions)
		available_data += list(list(
			"id" = M.mission_id,
			"name" = M.name,
			"type" = M.mission_type,
			"difficulty" = M.difficulty,
			"target" = M.target_name,
			"reward_caps" = M.reward_caps,
			"reward_rep" = M.reward_reputation,
			"reward_intel" = M.reward_intel,
		))
	data["available_missions"] = available_data

	var/list/active_data = list()
	for(var/datum/covert_mission/M in GLOB.enclave_covert_ops.active_missions)
		active_data += list(list(
			"id" = M.mission_id,
			"name" = M.name,
			"type" = M.mission_type,
			"assigned" = M.assigned_to,
			"time_remaining" = max(0, M.time_limit - (world.time - M.start_time)),
			"detection" = M.detection_level,
		))
	data["active_missions"] = active_data

	var/list/loadouts = list(
		list("name" = "Assault", "type" = "assault", "detection_mod" = 30),
		list("name" = "Stealth", "type" = "stealth", "detection_mod" = -20),
		list("name" = "Infiltrator", "type" = "infiltrator", "detection_mod" = 10),
	)
	data["loadouts"] = loadouts

	return data

/obj/machinery/computer/enclave_covert_ops/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("accept_mission")
			var/mission_id = params["mission_id"]
			if(GLOB.enclave_covert_ops.accept_mission(usr, mission_id))
				to_chat(usr, span_notice("Mission accepted. Good luck, operative."))
			return TRUE

		if("complete_mission")
			var/mission_id = params["mission_id"]
			var/success = text2num(params["success"]) || 1
			GLOB.enclave_covert_ops.complete_mission(usr, mission_id, success)
			return TRUE

		if("generate_missions")
			GLOB.enclave_covert_ops.generate_missions()
			to_chat(usr, span_notice("New missions generated."))
			return TRUE

		if("set_loadout")
			var/mission_id = params["mission_id"]
			var/loadout = params["loadout"]
			var/datum/covert_mission/M = GLOB.enclave_covert_ops.get_mission_by_id(mission_id)
			if(M)
				M.loadout_type = loadout
			return TRUE

	return FALSE

// ============ STEALTH MECHANICS ============

/mob/living/carbon/human
	var/detection_level = 0
	var/disguise_faction = null
	var/stealth_bonus = 0

/mob/living/carbon/human/proc/update_detection()
	detection_level = 0

	var/turf/T = get_turf(src)
	var/light_level = T.get_lumcount() * 100

	detection_level += (100 - light_level) * 0.3

	if(m_intent == MOVE_INTENT_RUN)
		detection_level += 30

	if(disguise_faction)
		detection_level -= 20

	detection_level -= stealth_bonus

	detection_level = clamp(detection_level, 0, 100)

/mob/living/carbon/human/proc/check_detection()
	update_detection()

	if(detection_level >= DETECTION_DETECTED)
		return "detected"
	else if(detection_level >= DETECTION_ALERTED)
		return "alerted"
	else if(detection_level >= DETECTION_SUSPICIOUS)
		return "suspicious"
	else
		return "undetected"
