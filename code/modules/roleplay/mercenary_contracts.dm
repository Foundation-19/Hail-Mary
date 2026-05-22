// Mercenary Contract Board System
// Non-faction players can take temporary jobs from any faction
// Objective verification: area visit tracking, kill tracking, time-at-location

GLOBAL_LIST_EMPTY(mercenary_contracts)
GLOBAL_LIST_EMPTY(active_mercenaries)

#define MERC_OBJ_AREA_VISIT "area_visit"
#define MERC_OBJ_KILL_TARGET "kill_target"
#define MERC_OBJ_GUARD_LOCATION "guard_location"
#define MERC_OBJ_RETRIEVE_ITEM "retrieve_item"

/datum/mercenary_objective
	var/objective_type = MERC_OBJ_AREA_VISIT
	var/description = "Go somewhere"
	var/area_name = ""
	var/completed = FALSE
	var/time_at_target = 0
	var/required_time_at_target = 0
	var/kill_required = FALSE

/datum/mercenary_objective/proc/check_progress(mob/living/carbon/human/H)
	if(completed || !H)
		return
	var/area/player_area = get_area(H)
	switch(objective_type)
		if(MERC_OBJ_AREA_VISIT, MERC_OBJ_RETRIEVE_ITEM)
			if(player_area && player_area.name == area_name)
				time_at_target += 10
				if(time_at_target >= required_time_at_target)
					completed = TRUE
		if(MERC_OBJ_KILL_TARGET)
			if(player_area && player_area.name == area_name)
				if(!kill_required)
					kill_required = TRUE
			if(kill_required && H.recent_hostile_kill_time && (world.time - H.recent_hostile_kill_time) < 600)
				completed = TRUE
		if(MERC_OBJ_GUARD_LOCATION)
			if(player_area && player_area.name == area_name)
				time_at_target += 10
				if(time_at_target >= required_time_at_target)
					completed = TRUE
			else if(time_at_target > 0)
				time_at_target = max(0, time_at_target - 5)

/datum/mercenary_objective/proc/get_status_text()
	if(completed)
		return "<span style='color:#88ff88'>Complete!</span>"
	switch(objective_type)
		if(MERC_OBJ_AREA_VISIT, MERC_OBJ_RETRIEVE_ITEM)
			if(time_at_target <= 0)
				return "<span style='color:#ff8844'>Travel to [area_name]</span>"
			return "<span style='color:#ffcc44'>Searching... [round(time_at_target / max(1, required_time_at_target) * 100)]%</span>"
		if(MERC_OBJ_KILL_TARGET)
			if(!kill_required)
				return "<span style='color:#ff8844'>Travel to [area_name] and find your mark</span>"
			return "<span style='color:#ffcc44'>At target area - kill your mark!</span>"
		if(MERC_OBJ_GUARD_LOCATION)
			if(time_at_target <= 0)
				return "<span style='color:#ff8844'>Travel to [area_name] and stand guard</span>"
			return "<span style='color:#ffcc44'>Guarding... [round(time_at_target / max(1, required_time_at_target) * 100)]%</span>"
	return "<span style='color:#ff8844'>In progress</span>"

// ============ MERCENARY CONTRACT ============

/datum/mercenary_contract
	var/contract_id
	var/name = "Contract"
	var/description = "Complete a task for payment."
	var/faction_employer = "neutral"
	var/reward_caps = 100
	var/reward_reputation = 10
	var/difficulty = 1
	var/time_limit = 0
	var/required_reputation = 0
	var/status = "available"
	var/assigned_to = null
	var/created_time = 0
	var/accepted_time = 0
	var/completed_time = 0
	var/location_hint = ""
	var/list/datum/mercenary_objective/objectives = list()
	var/blacklist_factions = list()

	var/static/next_id = 1

/datum/mercenary_contract/New()
	contract_id = "contract_[next_id++]"
	created_time = world.time

/datum/mercenary_contract/proc/get_ui_data()
	var/obj_completed = 0
	var/obj_total = objectives.len
	for(var/datum/mercenary_objective/O as anything in objectives)
		if(O.completed)
			obj_completed++
	return list(
		"contract_id" = contract_id,
		"name" = name,
		"description" = description,
		"faction_employer" = faction_employer,
		"reward_caps" = reward_caps,
		"reward_reputation" = reward_reputation,
		"difficulty" = difficulty,
		"time_limit" = time_limit,
		"required_reputation" = required_reputation,
		"status" = status,
		"assigned_to" = assigned_to,
		"location_hint" = location_hint,
		"objectives_total" = obj_total,
		"objectives_completed" = obj_completed,
	)

/datum/mercenary_contract/proc/check_progress(mob/living/carbon/human/H)
	if(status != "active" || !H)
		return
	for(var/datum/mercenary_objective/O as anything in objectives)
		O.check_progress(H)

/datum/mercenary_contract/proc/can_complete()
	if(status != "active")
		return FALSE
	for(var/datum/mercenary_objective/O as anything in objectives)
		if(!O.completed)
			return FALSE
	return TRUE

/datum/mercenary_contract/proc/get_objectives_text()
	var/list/texts = list()
	for(var/datum/mercenary_objective/O as anything in objectives)
		texts += "[O.description] - [O.get_status_text()]"
	return texts

/datum/mercenary_contract/proc/accept(mob/user)
	if(status != "available")
		return FALSE

	status = "active"
	assigned_to = user.ckey
	accepted_time = world.time
	GLOB.active_mercenaries[user.ckey] = contract_id

	to_chat(user, span_notice("Contract accepted: [name]"))
	for(var/datum/mercenary_objective/O as anything in objectives)
		to_chat(user, span_notice("- [O.description]"))
	return TRUE

/datum/mercenary_contract/proc/complete(mob/user)
	if(status != "active")
		return FALSE

	if(assigned_to != user.ckey)
		return FALSE

	if(!can_complete())
		to_chat(user, span_warning("You haven't completed all objectives yet!"))
		for(var/text in get_objectives_text())
			to_chat(user, span_warning("- [text]"))
		return FALSE

	status = "completed"
	completed_time = world.time
	GLOB.active_mercenaries -= user.ckey

	var/mob/living/carbon/human/H = user
	if(istype(H))
		var/obj/item/stack/f13Cash/caps = new /obj/item/stack/f13Cash/caps(get_turf(H), reward_caps)
		H.put_in_hands(caps)

		if(faction_employer != "neutral")
			adjust_faction_reputation(user.ckey, faction_employer, reward_reputation)

	to_chat(user, span_notice("Contract completed! You received [reward_caps] caps."))
	log_game("MERC_CONTRACT: [user.ckey] completed contract '[name]' for [reward_caps] caps")
	return TRUE

/datum/mercenary_contract/proc/fail()
	status = "failed"
	GLOB.active_mercenaries -= assigned_to

/datum/mercenary_contract/proc/check_timeout()
	if(time_limit > 0 && status == "active")
		if(world.time > accepted_time + time_limit)
			fail()
			return TRUE
	return FALSE

// ============ CONTRACT TYPES ============

/datum/mercenary_contract/proc/generate_objectives()
	return

/datum/mercenary_contract/proc/pick_target_area()
	var/list/valid_areas = list()
	for(var/area/A in get_areas(/area))
		if(!A || findtext(A.name, "space") || findtext(A.name, "centcomm") || findtext(A.name, "admin") || findtext(A.name, "shuttle"))
			continue
		if(istype(A, /area/f13))
			valid_areas += A
	if(!valid_areas.len)
		for(var/area/A in get_areas(/area))
			if(!A || findtext(A.name, "space") || findtext(A.name, "centcomm") || findtext(A.name, "admin") || findtext(A.name, "shuttle"))
				continue
			valid_areas += A
	var/area/target = valid_areas.len ? pick(valid_areas) : null
	return target ? target.name : "the wasteland"

/datum/mercenary_contract/escort
	name = "Escort Mission"
	description = "Escort a VIP safely to their destination."
	difficulty = 2
	reward_caps = 150
	reward_reputation = 15
	time_limit = 30 MINUTES
	location_hint = "VIP waiting at designated location"

/datum/mercenary_contract/escort/generate_objectives()
	var/area_name = pick_target_area()
	var/datum/mercenary_objective/O1 = new()
	O1.objective_type = MERC_OBJ_AREA_VISIT
	O1.area_name = area_name
	O1.required_time_at_target = 200
	O1.description = "Escort the VIP to [area_name]"
	objectives += O1
	location_hint = "VIP needs to reach [area_name]"

/datum/mercenary_contract/retrieval
	name = "Item Retrieval"
	description = "Retrieve a specific item from a dangerous location."
	difficulty = 3
	reward_caps = 200
	reward_reputation = 20
	location_hint = "Item last seen at marked location"

/datum/mercenary_contract/retrieval/generate_objectives()
	var/area_name = pick_target_area()
	var/datum/mercenary_objective/O1 = new()
	O1.objective_type = MERC_OBJ_RETRIEVE_ITEM
	O1.area_name = area_name
	O1.required_time_at_target = 300
	O1.description = "Retrieve the item from [area_name]"
	objectives += O1
	location_hint = "Item last seen at [area_name]"

/datum/mercenary_contract/elimination
	name = "Target Elimination"
	description = "Eliminate a specific hostile target."
	difficulty = 4
	reward_caps = 300
	reward_reputation = 25
	location_hint = "Target operating in designated area"

/datum/mercenary_contract/elimination/generate_objectives()
	var/area_name = pick_target_area()
	var/datum/mercenary_objective/O1 = new()
	O1.objective_type = MERC_OBJ_KILL_TARGET
	O1.area_name = area_name
	O1.description = "Eliminate the target near [area_name]"
	objectives += O1
	location_hint = "Target operating near [area_name]"

/datum/mercenary_contract/recon
	name = "Reconnaissance"
	description = "Scout a location and report findings."
	difficulty = 1
	reward_caps = 75
	reward_reputation = 10
	location_hint = "Investigate marked location"

/datum/mercenary_contract/recon/generate_objectives()
	var/area_name = pick_target_area()
	var/datum/mercenary_objective/O1 = new()
	O1.objective_type = MERC_OBJ_AREA_VISIT
	O1.area_name = area_name
	O1.required_time_at_target = 150
	O1.description = "Scout [area_name] and report findings"
	objectives += O1
	location_hint = "Investigate [area_name]"

/datum/mercenary_contract/guard
	name = "Guard Duty"
	description = "Protect a location for a set period."
	difficulty = 2
	reward_caps = 125
	reward_reputation = 12
	time_limit = 20 MINUTES
	location_hint = "Report to location and stand guard"

/datum/mercenary_contract/guard/generate_objectives()
	var/area_name = pick_target_area()
	var/datum/mercenary_objective/O1 = new()
	O1.objective_type = MERC_OBJ_GUARD_LOCATION
	O1.area_name = area_name
	O1.required_time_at_target = 600
	O1.description = "Guard [area_name] for an extended period"
	objectives += O1
	location_hint = "Report to [area_name] and stand guard"

/datum/mercenary_contract/rescue
	name = "Rescue Operation"
	description = "Rescue a captured individual."
	difficulty = 4
	reward_caps = 350
	reward_reputation = 30
	location_hint = "Hostage held at marked location"

/datum/mercenary_contract/rescue/generate_objectives()
	var/area_name = pick_target_area()
	var/datum/mercenary_objective/O1 = new()
	O1.objective_type = MERC_OBJ_AREA_VISIT
	O1.area_name = area_name
	O1.required_time_at_target = 100
	O1.description = "Reach [area_name] and extract the hostage"
	objectives += O1
	var/datum/mercenary_objective/O2 = new()
	O2.objective_type = MERC_OBJ_AREA_VISIT
	O2.area_name = pick_target_area()
	O2.required_time_at_target = 200
	O2.description = "Escort the hostage to safety"
	objectives += O2
	location_hint = "Hostage held at [area_name]"

/datum/mercenary_contract/sabotage
	name = "Sabotage"
	description = "Destroy or disable enemy equipment."
	difficulty = 3
	reward_caps = 200
	reward_reputation = 20
	location_hint = "Target equipment at designated location"

/datum/mercenary_contract/sabotage/generate_objectives()
	var/area_name = pick_target_area()
	var/datum/mercenary_objective/O1 = new()
	O1.objective_type = MERC_OBJ_RETRIEVE_ITEM
	O1.area_name = area_name
	O1.required_time_at_target = 250
	O1.description = "Sabotage equipment at [area_name]"
	objectives += O1
	location_hint = "Target equipment at [area_name]"

// ============ MERCENARY BOARD ============

/obj/machinery/mercenary_board
	name = "Mercenary Contract Board"
	desc = "A terminal displaying available contracts for hire."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/mercenary_board/Initialize()
	. = ..()
	generate_contracts()

/obj/machinery/mercenary_board/proc/generate_contracts()
	if(GLOB.mercenary_contracts.len > 0)
		return

	var/list/contract_types = list(
		/datum/mercenary_contract/escort,
		/datum/mercenary_contract/retrieval,
		/datum/mercenary_contract/elimination,
		/datum/mercenary_contract/recon,
		/datum/mercenary_contract/guard,
		/datum/mercenary_contract/rescue,
		/datum/mercenary_contract/sabotage,
	)

	for(var/i = 1 to 5)
		var/contract_type = pick(contract_types)
		var/datum/mercenary_contract/contract = new contract_type()
		contract.faction_employer = pick("ncr", "bos", "legion", "enclave", "neutral")
		contract.generate_objectives()
		GLOB.mercenary_contracts += contract

/obj/machinery/mercenary_board/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/mercenary_board/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MercenaryBoard")
		ui.open()

/obj/machinery/mercenary_board/ui_data(mob/user)
	var/list/available_contracts = list()
	var/list/active_contract = null

	for(var/datum/mercenary_contract/contract as anything in GLOB.mercenary_contracts)
		if(contract.status == "available")
			available_contracts += list(contract.get_ui_data())
		if(contract.assigned_to == user.ckey && contract.status == "active")
			active_contract = contract.get_ui_data()

	return list(
		"available_contracts" = available_contracts,
		"active_contract" = active_contract,
		"player_reputation" = get_player_reputation(user.ckey),
		"can_take_contracts" = can_take_contracts(user),
	)

/obj/machinery/mercenary_board/proc/get_player_reputation(ckey)
	return 0

/obj/machinery/mercenary_board/proc/can_take_contracts(mob/user)
	if(GLOB.active_mercenaries[user.ckey])
		return FALSE
	return TRUE

/obj/machinery/mercenary_board/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("accept_contract")
			var/contract_id = params["contract_id"]
			for(var/datum/mercenary_contract/contract as anything in GLOB.mercenary_contracts)
				if(contract.contract_id == contract_id)
					return contract.accept(usr)
			return FALSE

		if("complete_contract")
			var/contract_id = params["contract_id"]
			for(var/datum/mercenary_contract/contract as anything in GLOB.mercenary_contracts)
				if(contract.contract_id == contract_id)
					return contract.complete(usr)
			return FALSE

		if("abandon_contract")
			var/contract_id = params["contract_id"]
			for(var/datum/mercenary_contract/contract as anything in GLOB.mercenary_contracts)
				if(contract.contract_id == contract_id && contract.assigned_to == usr.ckey)
					contract.fail()
					to_chat(usr, span_warning("Contract abandoned. Your reputation may suffer."))
					return TRUE
			return FALSE

	return FALSE

// ============ FACTION-SPECIFIC CONTRACT BOARDS ============

/obj/machinery/mercenary_board/ncr
	name = "NCR Contract Terminal"
	desc = "NCR military contracts available here."

/obj/machinery/mercenary_board/ncr/generate_contracts()
	if(GLOB.mercenary_contracts.len > 0)
		return

	var/list/contract_types = list(
		/datum/mercenary_contract/escort,
		/datum/mercenary_contract/guard,
		/datum/mercenary_contract/recon,
	)

	for(var/i = 1 to 3)
		var/contract_type = pick(contract_types)
		var/datum/mercenary_contract/contract = new contract_type()
		contract.faction_employer = "ncr"
		contract.generate_objectives()
		GLOB.mercenary_contracts += contract

/obj/machinery/mercenary_board/bos
	name = "Brotherhood Contract Terminal"
	desc = "Brotherhood technology recovery contracts."

/obj/machinery/mercenary_board/bos/generate_contracts()
	if(GLOB.mercenary_contracts.len > 0)
		return

	var/list/contract_types = list(
		/datum/mercenary_contract/retrieval,
		/datum/mercenary_contract/recon,
		/datum/mercenary_contract/sabotage,
	)

	for(var/i = 1 to 3)
		var/contract_type = pick(contract_types)
		var/datum/mercenary_contract/contract = new contract_type()
		contract.faction_employer = "bos"
		contract.generate_objectives()
		GLOB.mercenary_contracts += contract

/obj/machinery/mercenary_board/legion
	name = "Legion Contract Terminal"
	desc = "Legion combat contracts."

/obj/machinery/mercenary_board/legion/generate_contracts()
	if(GLOB.mercenary_contracts.len > 0)
		return

	var/list/contract_types = list(
		/datum/mercenary_contract/elimination,
		/datum/mercenary_contract/rescue,
		/datum/mercenary_contract/sabotage,
	)

	for(var/i = 1 to 3)
		var/contract_type = pick(contract_types)
		var/datum/mercenary_contract/contract = new contract_type()
		contract.faction_employer = "legion"
		contract.generate_objectives()
		GLOB.mercenary_contracts += contract
