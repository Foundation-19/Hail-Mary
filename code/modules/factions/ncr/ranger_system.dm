// NCR Ranger Elite System
// Progression, abilities, and equipment

GLOBAL_LIST_EMPTY(ranger_progressions)

// ============ RANGER TERMINAL ============

/obj/machinery/ranger_terminal/ncr
	name = "NCR Ranger Terminal"
	desc = "A terminal for Ranger progression and assignments."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	req_access = list(ACCESS_NCR)
	density = FALSE
	anchored = TRUE

	var/datum/ranger_manager/manager

/obj/machinery/ranger_terminal/ncr/Initialize()
	. = ..()
	manager = new /datum/ranger_manager(src)

/obj/machinery/ranger_terminal/ncr/Destroy()
	QDEL_NULL(manager)
	return ..()

/obj/machinery/ranger_terminal/ncr/attack_hand(mob/user)
	if(!allowed(user))
		to_chat(user, span_warning("Access denied. NCR personnel only."))
		return
	ui_interact(user)

/obj/machinery/ranger_terminal/ncr/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RangerTerminal")
		ui.open()

/obj/machinery/ranger_terminal/ncr/ui_data(mob/user)
	return manager ? manager.get_ui_data(user) : list()

/obj/machinery/ranger_terminal/ncr/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	if(!manager)
		return FALSE

	. = manager.handle_action(action, params, usr)

// ============ RANGER MANAGER ============

/datum/ranger_manager
	var/obj/machinery/ranger_terminal/ncr/owner

/datum/ranger_manager/New(obj/machinery/ranger_terminal/ncr/terminal)
	owner = terminal

/datum/ranger_manager/proc/get_ui_data(mob/user)
	var/list/data = list()

	var/datum/ranger_progression/progression = get_progression(user.ckey)
	if(!progression)
		progression = new /datum/ranger_progression(user.ckey)
		GLOB.ranger_progressions += progression

	data["progression"] = progression.get_ui_data()
	data["ncr_reputation"] = get_ncr_reputation(user.ckey)
	data["can_advance"] = can_advance(user, progression)

	var/list/available_missions = list()
	for(var/datum/ranger_mission/mission as anything in get_available_missions(progression))
		available_missions += list(mission.get_ui_data())
	data["available_missions"] = available_missions

	return data

/datum/ranger_manager/proc/get_progression(ckey)
	for(var/datum/ranger_progression/P as anything in GLOB.ranger_progressions)
		if(P.ckey == ckey)
			return P
	return null

/datum/ranger_manager/proc/get_ncr_reputation(ckey)
	return 0

/datum/ranger_manager/proc/can_advance(mob/user, datum/ranger_progression/progression)
	var/rep = get_ncr_reputation(user.ckey)
	var/next_tier = progression.ranger_tier + 1

	switch(next_tier)
		if(RANGER_TIER_SCOUT)
			return rep >= RANGER_REP_SCOUT
		if(RANGER_TIER_RANGER)
			return rep >= RANGER_REP_RANGER && progression.total_missions >= 3
		if(RANGER_TIER_VETERAN)
			return rep >= RANGER_REP_VETERAN && progression.successful_missions >= 5
		if(RANGER_TIER_CAPTAIN)
			return rep >= RANGER_REP_CAPTAIN && progression.successful_missions >= 10
		if(RANGER_TIER_CHIEF)
			return rep >= RANGER_REP_CHIEF && progression.successful_missions >= 20

	return FALSE

/datum/ranger_manager/proc/get_available_missions(datum/ranger_progression/progression)
	var/list/missions = list()

	if(progression.ranger_tier >= RANGER_TIER_SCOUT)
		missions += new /datum/ranger_mission/track_fugitive()
		missions += new /datum/ranger_mission/reconnaissance()

	if(progression.ranger_tier >= RANGER_TIER_RANGER)
		missions += new /datum/ranger_mission/infiltrate_legion()
		missions += new /datum/ranger_mission/protect_vip()

	if(progression.ranger_tier >= RANGER_TIER_VETERAN)
		missions += new /datum/ranger_mission/eliminate_target()

	return missions

/datum/ranger_manager/proc/handle_action(action, list/params, mob/user)
	switch(action)
		if("advance_tier")
			return advance_tier(user)
		if("accept_mission")
			return accept_mission(user, params)
		if("use_ability_tracking")
			return use_tracking(user)
		if("use_ability_stealth")
			return use_stealth(user)
		if("use_ability_combat")
			return use_combat(user)

	return FALSE

/datum/ranger_manager/proc/advance_tier(mob/user)
	var/datum/ranger_progression/progression = get_progression(user.ckey)
	if(!progression)
		return FALSE

	if(!can_advance(user, progression))
		return FALSE

	progression.ranger_tier++

	var/tier_name = get_tier_name(progression.ranger_tier)
	to_chat(user, span_notice("You have been promoted to [tier_name]!"))

	grant_abilities(user, progression)

	return TRUE

/datum/ranger_manager/proc/get_tier_name(tier)
	switch(tier)
		if(RANGER_TIER_TROOPER)
			return "Trooper"
		if(RANGER_TIER_SCOUT)
			return "Scout"
		if(RANGER_TIER_RANGER)
			return "Ranger"
		if(RANGER_TIER_VETERAN)
			return "Veteran Ranger"
		if(RANGER_TIER_CAPTAIN)
			return "Ranger Captain"
		if(RANGER_TIER_CHIEF)
			return "Ranger Chief"
	return "Unknown"

/datum/ranger_manager/proc/grant_abilities(mob/user, datum/ranger_progression/progression)
	if(progression.ranger_tier >= RANGER_TIER_SCOUT)
		if(!user.mind?.has_action(/datum/action/ranger_track))
			var/datum/action/ranger_track/track = new()
			track.Grant(user)

	if(progression.ranger_tier >= RANGER_TIER_RANGER)
		if(!user.mind?.has_action(/datum/action/ranger_stealth))
			var/datum/action/ranger_stealth/stealth = new()
			stealth.Grant(user)

	if(progression.ranger_tier >= RANGER_TIER_VETERAN)
		if(!user.mind?.has_action(/datum/action/ranger_combat))
			var/datum/action/ranger_combat/combat = new()
			combat.Grant(user)

/datum/ranger_manager/proc/accept_mission(mob/user, list/params)
	var/mission_id = params["mission_id"]
	if(!mission_id)
		return FALSE

	var/datum/ranger_progression/progression = get_progression(user.ckey)
	if(!progression)
		return FALSE

	for(var/datum/ranger_mission/mission as anything in get_available_missions(progression))
		if(mission.id == mission_id)
			progression.active_mission = mission
			to_chat(user, span_notice("Mission accepted: [mission.name]"))
			return TRUE

	return FALSE

/datum/ranger_manager/proc/use_tracking(mob/user)
	var/datum/ranger_progression/progression = get_progression(user.ckey)
	if(!progression || progression.ranger_tier < RANGER_TIER_SCOUT)
		return FALSE

	if(progression.tracking_cooldown > world.time)
		to_chat(user, span_warning("Tracking ability on cooldown."))
		return FALSE

	var/list/targets = list()

	for(var/datum/prisoner_record/record in GLOB.ncr_escapees)
		targets[record.prisoner_name] = record.prisoner_ckey

	for(var/list/bounty in GLOB.ncr_bounties_global)
		if(bounty["target_name"])
			targets[bounty["target_name"]] = bounty["target_ckey"]

	if(!targets.len)
		to_chat(user, span_warning("No targets to track."))
		return FALSE

	var/choice = input(user, "Select target to track:", "Ranger Tracking") as null|anything in targets
	if(!choice)
		return FALSE

	var/target_ckey = targets[choice]
	var/mob/target = get_mob_by_ckey(target_ckey)

	if(!target)
		to_chat(user, span_warning("Cannot locate target."))
		return FALSE

	var/distance = get_dist(user, target)
	var/direction = get_dir_text(user, target)

	var/accuracy = 50 + (progression.ranger_tier * 10)
	var/noise = rand(-3, 3) * (100 - accuracy) / 100

	var	reported_dist = round(distance + (distance * noise / 10))
	var	reported_dir = direction

	if(prob(100 - accuracy))
		var/list/dirs = list("north", "south", "east", "west", "northeast", "northwest", "southeast", "southwest")
		reported_dir = pick(dirs)

	to_chat(user, span_notice("Tracking [choice]: Approximately [reported_dist] meters to the [reported_dir]."))

	progression.tracking_cooldown = world.time + RANGER_TRACK_COOLDOWN

	return TRUE

/datum/ranger_manager/proc/use_stealth(mob/user)
	var/datum/ranger_progression/progression = get_progression(user.ckey)
	if(!progression || progression.ranger_tier < RANGER_TIER_RANGER)
		return FALSE

	if(progression.stealth_cooldown > world.time)
		to_chat(user, span_warning("Stealth ability on cooldown."))
		return FALSE

	var/duration = 30 SECONDS + (progression.ranger_tier * 10 SECONDS)

	user.alpha = 100
	to_chat(user, span_notice("You fade into the shadows."))

	addtimer(CALLBACK(src, PROC_REF(end_stealth), user), duration)

	progression.stealth_cooldown = world.time + RANGER_STEALTH_COOLDOWN

	return TRUE

/datum/ranger_manager/proc/end_stealth(mob/user)
	if(user)
		user.alpha = 255
		to_chat(user, span_notice("You emerge from the shadows."))

/datum/ranger_manager/proc/use_combat(mob/user)
	var/datum/ranger_progression/progression = get_progression(user.ckey)
	if(!progression || progression.ranger_tier < RANGER_TIER_VETERAN)
		return FALSE

	if(progression.combat_cooldown > world.time)
		to_chat(user, span_warning("Combat stance on cooldown."))
		return FALSE

	var/duration = 30 SECONDS

	progression.combat_stance_active = TRUE
	to_chat(user, span_notice("You enter a combat stance. +15% damage for 30 seconds."))

	addtimer(CALLBACK(src, PROC_REF(end_combat), user), duration)

	progression.combat_cooldown = world.time + RANGER_COMBAT_COOLDOWN

	return TRUE

/datum/ranger_manager/proc/end_combat(mob/user)
	var/datum/ranger_progression/progression = get_progression(user.ckey)
	if(progression)
		progression.combat_stance_active = FALSE
		if(user)
			to_chat(user, span_notice("Your combat stance ends."))

// ============ RANGER PROGRESSION ============

/datum/ranger_progression
	var/ckey
	var/ranger_tier = RANGER_TIER_TROOPER
	var/total_missions = 0
	var/successful_missions = 0
	var/failed_missions = 0
	var/tracking_skill = 0
	var/stealth_skill = 0
	var/combat_skill = 0

	var/tracking_cooldown = 0
	var/stealth_cooldown = 0
	var/combat_cooldown = 0
	var/combat_stance_active = FALSE

	var/datum/ranger_mission/active_mission

/datum/ranger_progression/New(player_ckey)
	ckey = player_ckey

/datum/ranger_progression/proc/get_ui_data()
	return list(
		"ranger_tier" = ranger_tier,
		"tier_name" = get_tier_name_ui(ranger_tier),
		"total_missions" = total_missions,
		"successful_missions" = successful_missions,
		"failed_missions" = failed_missions,
		"tracking_skill" = tracking_skill,
		"stealth_skill" = stealth_skill,
		"combat_skill" = combat_skill,
		"active_mission" = active_mission ? active_mission.get_ui_data() : null,
		"tracking_cooldown" = max(0, round((tracking_cooldown - world.time) / (1 SECOND))),
		"stealth_cooldown" = max(0, round((stealth_cooldown - world.time) / (1 SECOND))),
		"combat_cooldown" = max(0, round((combat_cooldown - world.time) / (1 SECOND))),
	)

/datum/ranger_progression/proc/get_tier_name_ui(tier)
	switch(tier)
		if(RANGER_TIER_TROOPER)
			return "Trooper"
		if(RANGER_TIER_SCOUT)
			return "Scout"
		if(RANGER_TIER_RANGER)
			return "Ranger"
		if(RANGER_TIER_VETERAN)
			return "Veteran Ranger"
		if(RANGER_TIER_CAPTAIN)
			return "Ranger Captain"
		if(RANGER_TIER_CHIEF)
			return "Ranger Chief"
	return "Unknown"

// ============ RANGER MISSIONS ============

/datum/ranger_mission
	var/id
	var/name
	var/description
	var/difficulty = 1
	var/caps_reward = 50
	var/reputation_reward = 5
	var/required_tier = RANGER_TIER_SCOUT

/datum/ranger_mission/proc/get_ui_data()
	return list(
		"id" = id,
		"name" = name,
		"description" = description,
		"difficulty" = difficulty,
		"caps_reward" = caps_reward,
		"reputation_reward" = reputation_reward,
	)

/datum/ranger_mission/track_fugitive
	id = "track_fugitive"
	name = "Track Fugitive"
	description = "Locate and capture an escaped prisoner."
	difficulty = 2
	caps_reward = 50
	reputation_reward = 10
	required_tier = RANGER_TIER_SCOUT

/datum/ranger_mission/reconnaissance
	id = "reconnaissance"
	name = "Reconnaissance"
	description = "Scout hostile territory and report findings."
	difficulty = 1
	caps_reward = 50
	reputation_reward = 5
	required_tier = RANGER_TIER_SCOUT

/datum/ranger_mission/infiltrate_legion
	id = "infiltrate_legion"
	name = "Infiltrate Legion Territory"
	description = "Spy on Legion operations and gather intel."
	difficulty = 4
	caps_reward = 100
	reputation_reward = 15
	required_tier = RANGER_TIER_RANGER

/datum/ranger_mission/protect_vip
	id = "protect_vip"
	name = "Protect VIP"
	description = "Escort an important NPC through dangerous territory."
	difficulty = 3
	caps_reward = 75
	reputation_reward = 10
	required_tier = RANGER_TIER_RANGER

/datum/ranger_mission/eliminate_target
	id = "eliminate_target"
	name = "Eliminate High-Value Target"
	description = "Assassinate a priority target (Rangers only)."
	difficulty = 5
	caps_reward = 200
	reputation_reward = 25
	required_tier = RANGER_TIER_VETERAN

// ============ RANGER ABILITIES ============

/datum/action/ranger_track
	name = "Ranger Tracking"
	desc = "Track escaped prisoners and bounty targets."
	button_icon_state = "ranger_track"
	check_flags = AB_CHECK_CONSCIOUS

	var/last_use = 0
	var/cooldown = RANGER_TRACK_COOLDOWN

/datum/action/ranger_track/Trigger(trigger_flags)
	if(!owner)
		return FALSE

	if(world.time < last_use + cooldown)
		to_chat(owner, span_warning("Tracking ability on cooldown."))
		return FALSE

	var/list/targets = list()

	for(var/datum/prisoner_record/record in GLOB.ncr_escapees)
		targets[record.prisoner_name] = record.prisoner_ckey

	for(var/list/bounty in GLOB.ncr_bounties_global)
		if(bounty["target_name"])
			targets[bounty["target_name"]] = bounty["target_ckey"]

	if(!targets.len)
		to_chat(owner, span_warning("No targets to track."))
		return FALSE

	var/choice = input(owner, "Select target to track:", "Ranger Tracking") as null|anything in targets
	if(!choice)
		return FALSE

	var/target_ckey = targets[choice]
	var/mob/target = get_mob_by_ckey(target_ckey)

	if(!target)
		to_chat(owner, span_warning("Cannot locate target."))
		return FALSE

	var/distance = get_dist(owner, target)
	var/direction = get_dir_text(owner, target)

	to_chat(owner, span_notice("Tracking [choice]: Approximately [distance] meters to the [direction]."))

	last_use = world.time

	return TRUE

/datum/action/ranger_stealth
	name = "Ranger Stealth"
	desc = "Fade into the shadows for 30 seconds."
	button_icon_state = "ranger_stealth"
	check_flags = AB_CHECK_CONSCIOUS

	var/last_use = 0
	var/cooldown = RANGER_STEALTH_COOLDOWN

/datum/action/ranger_stealth/Trigger(trigger_flags)
	if(!owner)
		return FALSE

	if(world.time < last_use + cooldown)
		to_chat(owner, span_warning("Stealth ability on cooldown."))
		return FALSE

	owner.alpha = 100
	to_chat(owner, span_notice("You fade into the shadows."))

	addtimer(CALLBACK(src, PROC_REF(end_stealth)), 30 SECONDS)

	last_use = world.time

	return TRUE

/datum/action/ranger_stealth/proc/end_stealth()
	if(owner)
		owner.alpha = 255
		to_chat(owner, span_notice("You emerge from the shadows."))

/datum/action/ranger_combat
	name = "Ranger Combat Stance"
	desc = "Enter a combat stance for +15% damage."
	button_icon_state = "ranger_combat"
	check_flags = AB_CHECK_CONSCIOUS

	var/last_use = 0
	var/cooldown = RANGER_COMBAT_COOLDOWN
	var/active = FALSE

/datum/action/ranger_combat/Trigger(trigger_flags)
	if(!owner)
		return FALSE

	if(world.time < last_use + cooldown)
		to_chat(owner, span_warning("Combat stance on cooldown."))
		return FALSE

	active = TRUE
	to_chat(owner, span_notice("You enter a combat stance. +15% damage for 30 seconds."))

	addtimer(CALLBACK(src, PROC_REF(end_combat)), 30 SECONDS)

	last_use = world.time

	return TRUE

/datum/action/ranger_combat/proc/end_combat()
	active = FALSE
	if(owner)
		to_chat(owner, span_notice("Your combat stance ends."))
