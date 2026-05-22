// Brotherhood of Steel Tech Recovery Missions
// BOS Knights and Paladins recover pre-war technology

GLOBAL_LIST_EMPTY(bos_mission_cooldowns)
GLOBAL_LIST_EMPTY(bos_player_active_missions)

/obj/machinery/bos_mission_terminal
	name = "Brotherhood Mission Terminal"
	desc = "A secure terminal for assigning tech recovery operations to field units."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	req_access = list(ACCESS_BOS)
	density = TRUE
	anchored = TRUE

	var/list/available_missions = list()
	var/list/active_missions = list()
	var/list/completed_missions = list()
	var/list/recovered_tech = list()

/obj/machinery/bos_mission_terminal/Initialize()
	. = ..()
	generate_missions()

/obj/machinery/bos_mission_terminal/proc/generate_missions()
	available_missions.Cut()
	for(var/datum/tech_recovery_mission/mission as anything in subtypesof(/datum/tech_recovery_mission))
		var/datum/tech_recovery_mission/M = new mission
		if(M.auto_generate)
			available_missions += M

/obj/machinery/bos_mission_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TechRecovery")
		ui.open()

/obj/machinery/bos_mission_terminal/ui_data(mob/user)
	var/list/data = list()
	data["faction"] = "bos"
	data["faction_name"] = "Brotherhood of Steel"
	data["player_has_active"] = GLOB.bos_player_active_missions[user.ckey] ? TRUE : FALSE

	var/list/available = list()
	for(var/datum/tech_recovery_mission/M in available_missions)
		if(M.status == BOS_MISSION_AVAILABLE)
			var/on_cooldown = GLOB.bos_mission_cooldowns[M.id] && GLOB.bos_mission_cooldowns[M.id] > world.time
			available += list(list(
				"id" = M.id,
				"name" = M.name,
				"description" = M.description,
				"difficulty" = M.difficulty,
				"difficulty_text" = difficulty_to_text(M.difficulty),
				"required_rank" = M.required_rank,
				"research_points" = M.research_points,
				"location" = M.location_name,
				"on_cooldown" = on_cooldown,
				"cooldown_remaining" = on_cooldown ? round((GLOB.bos_mission_cooldowns[M.id] - world.time) / 600) : 0
			))
	data["available_missions"] = available

	var/list/active = list()
	for(var/datum/tech_recovery_mission/M in active_missions)
		active += list(list(
			"id" = M.id,
			"name" = M.name,
			"status" = M.status,
			"assigned_to" = M.assigned_to,
			"time_remaining" = M.time_remaining()
		))
	data["active_missions"] = active

	var/list/completed = list()
	for(var/datum/tech_recovery_mission/M in completed_missions)
		completed += list(list(
			"id" = M.id,
			"name" = M.name,
			"success" = M.status == BOS_MISSION_COMPLETED
		))
	data["completed_missions"] = completed

	var/list/tech = list()
	for(var/datum/tech_item/T in recovered_tech)
		tech += list(list(
			"name" = T.name,
			"rarity" = T.rarity,
			"research_value" = T.research_value,
			"analyzed" = T.analyzed
		))
	data["recovered_tech"] = tech

	return data

/obj/machinery/bos_mission_terminal/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("accept_mission")
			var/mission_id = params["id"]
			for(var/datum/tech_recovery_mission/M in available_missions)
				if(M.id == mission_id && M.status == BOS_MISSION_AVAILABLE)
					if(can_accept_mission(usr, M))
						M.accept_mission(usr)
						available_missions -= M
						active_missions += M
						return TRUE
		if("complete_mission")
			var/mission_id = params["id"]
			for(var/datum/tech_recovery_mission/M in active_missions)
				if(M.id == mission_id && M.assigned_to == usr.ckey)
					var/datum/tech_item/reward = M.complete_mission(usr)
					if(reward)
						recovered_tech += reward
					active_missions -= M
					completed_missions += M
					return TRUE
		if("fail_mission")
			var/mission_id = params["id"]
			for(var/datum/tech_recovery_mission/M in active_missions)
				if(M.id == mission_id && M.assigned_to == usr.ckey)
					M.fail_mission()
					active_missions -= M
					completed_missions += M
					return TRUE
		if("analyze_tech")
			var/tech_name = params["name"]
			for(var/datum/tech_item/T in recovered_tech)
				if(T.name == tech_name && !T.analyzed)
					T.analyze(src)
					return TRUE
		if("analyze_all")
			for(var/datum/tech_item/T in recovered_tech)
				if(!T.analyzed)
					T.analyze(src)
			return TRUE

	return FALSE

/obj/machinery/bos_mission_terminal/proc/can_accept_mission(mob/user, datum/tech_recovery_mission/mission)
	if(!ishuman(user))
		return FALSE

	if(GLOB.bos_player_active_missions[user.ckey])
		return FALSE

	if(GLOB.bos_mission_cooldowns[mission.id] && GLOB.bos_mission_cooldowns[mission.id] > world.time)
		return FALSE

	var/mob/living/carbon/human/H = user
	var/player_rank = get_bos_rank(H)
	if(player_rank < mission.required_rank)
		return FALSE

	for(var/datum/tech_recovery_mission/M in active_missions)
		if(M.assigned_to == user.ckey)
			return FALSE
	return TRUE

/obj/machinery/bos_mission_terminal/proc/get_bos_rank(mob/living/carbon/human/H)
	var/obj/item/card/id/I = H.get_idcard()
	if(!I)
		return BOS_RANK_INITIATE
	if(I.assignment == "Elder")
		return BOS_RANK_ELDER
	if(I.assignment == "Head Paladin")
		return BOS_RANK_HEAD_PALADIN
	if(I.assignment == "Paladin Commander")
		return BOS_RANK_PALADIN_COMMANDER
	if(I.assignment == "Paladin")
		return BOS_RANK_PALADIN
	if(I.assignment == "Knight Sergeant")
		return BOS_RANK_KNIGHT_SERGEANT
	if(I.assignment == "Knight" || I.assignment == "Senior Knight")
		return BOS_RANK_KNIGHT
	return BOS_RANK_INITIATE

/obj/machinery/bos_mission_terminal/proc/difficulty_to_text(difficulty)
	switch(difficulty)
		if(BOS_DIFFICULTY_EASY)
			return "\u2605\u2606\u2606\u2606\u2606"
		if(BOS_DIFFICULTY_MEDIUM)
			return "\u2605\u2605\u2606\u2606\u2606"
		if(BOS_DIFFICULTY_HARD)
			return "\u2605\u2605\u2605\u2606\u2606"
		if(BOS_DIFFICULTY_VERY_HARD)
			return "\u2605\u2605\u2605\u2605\u2606"
		if(BOS_DIFFICULTY_EXTREME)
			return "\u2605\u2605\u2605\u2605\u2605"
		else
			return "\u2605\u2606\u2606\u2606\u2606"

// ============ TECH RECOVERY MISSION DATUM ============

/datum/tech_recovery_mission
	var/id
	var/name = "Tech Recovery Mission"
	var/description = "Recover pre-war technology."
	var/difficulty = BOS_DIFFICULTY_MEDIUM
	var/required_rank = BOS_RANK_KNIGHT
	var/research_points = 100
	var/location_name = "Unknown"
	var/turf/location_turf
	var/time_limit = 0
	var/start_time = 0
	var/status = BOS_MISSION_AVAILABLE
	var/assigned_to = null
	var/auto_generate = TRUE

	var/list/possible_tech = list()
	var/list/spawned_tech = list()

/datum/tech_recovery_mission/proc/accept_mission(mob/user)
	status = BOS_MISSION_IN_PROGRESS
	assigned_to = user.ckey
	start_time = world.time
	GLOB.bos_player_active_missions[user.ckey] = id
	spawn_mission_site()

/datum/tech_recovery_mission/proc/spawn_mission_site()
	return

/datum/tech_recovery_mission/proc/complete_mission(mob/user)
	status = BOS_MISSION_COMPLETED
	GLOB.bos_player_active_missions -= user.ckey
	GLOB.bos_mission_cooldowns[id] = world.time + 30 MINUTES
	var/datum/tech_item/reward = get_random_tech()
	SSresearch.bos_tech.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = research_points))
	log_game("[user.ckey] completed BOS tech recovery mission: [name]")
	return reward

/datum/tech_recovery_mission/proc/fail_mission()
	status = BOS_MISSION_FAILED
	GLOB.bos_player_active_missions -= assigned_to
	GLOB.bos_mission_cooldowns[id] = world.time + 15 MINUTES
	log_game("[assigned_to] failed BOS tech recovery mission: [name]")
	assigned_to = null

/datum/tech_recovery_mission/proc/time_remaining()
	if(!time_limit)
		return -1
	return max(0, time_limit - (world.time - start_time))

/datum/tech_recovery_mission/proc/get_random_tech()
	if(!possible_tech.len)
		return new /datum/tech_item/common
	var/tech_type = pick(possible_tech)
	return new tech_type

// ============ TECH ITEM DATUM ============

/datum/tech_item
	var/name = "Technology Component"
	var/rarity = BOS_TECH_COMMON
	var/research_value = 25
	var/unique_item_path
	var/unlocks_node
	var/analyzed = FALSE

/datum/tech_item/proc/analyze(obj/machinery/bos_mission_terminal/terminal)
	analyzed = TRUE
	terminal.recovered_tech -= src
	SSresearch.bos_tech.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = research_value))
	if(unlocks_node)
		SSresearch.bos_tech.research_node_id(unlocks_node, TRUE)
	if(unique_item_path)
		new unique_item_path(terminal.loc)
	qdel(src)

// Common Tech
/datum/tech_item/common
	name = "Pre-War Circuit Board"
	rarity = BOS_TECH_COMMON
	research_value = 25

/datum/tech_item/common/holotape
	name = "Data Holotape"
	research_value = 30

/datum/tech_item/common/components
	name = "Electronic Components"
	research_value = 20

// Uncommon Tech
/datum/tech_item/uncommon
	name = "Laser Weapon Parts"
	rarity = BOS_TECH_UNCOMMON
	research_value = 75

/datum/tech_item/uncommon/power_armor_parts
	name = "Power Armor Servo"
	research_value = 100

// Rare Tech
/datum/tech_item/rare
	name = "Advanced Weapon Schematic"
	rarity = BOS_TECH_RARE
	research_value = 150

/datum/tech_item/rare/energy_core
	name = "Microfusion Core Prototype"
	research_value = 200

// Legendary Tech
/datum/tech_item/legendary
	name = "Pre-War AI Fragment"
	rarity = BOS_TECH_LEGENDARY
	research_value = 400

/datum/tech_item/legendary/pa_blueprint
	name = "Advanced Power Armor Blueprint"
	research_value = 500
	unlocks_node = "bos_power_armor_advanced"
