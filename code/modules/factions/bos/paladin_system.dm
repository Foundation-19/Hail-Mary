// BOS Paladin Elite System
// Progression, abilities, and equipment

GLOBAL_LIST_EMPTY(paladin_progressions)

// ============ PALADIN TERMINAL ============

/obj/machinery/paladin_terminal/bos
	name = "Brotherhood Paladin Terminal"
	desc = "A terminal for Paladin progression and combat training."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	req_access = list(ACCESS_BOS)
	density = FALSE
	anchored = TRUE

	var/datum/paladin_manager/manager

/obj/machinery/paladin_terminal/bos/Initialize()
	. = ..()
	manager = new /datum/paladin_manager(src)

/obj/machinery/paladin_terminal/bos/Destroy()
	QDEL_NULL(manager)
	return ..()

/obj/machinery/paladin_terminal/bos/attack_hand(mob/user)
	if(!allowed(user))
		to_chat(user, span_warning("Access denied. Brotherhood personnel only."))
		return
	ui_interact(user)

/obj/machinery/paladin_terminal/bos/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PaladinTerminal")
		ui.open()

/obj/machinery/paladin_terminal/bos/ui_data(mob/user)
	return manager ? manager.get_ui_data(user) : list()

/obj/machinery/paladin_terminal/bos/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	if(!manager)
		return FALSE

	. = manager.handle_action(action, params, usr)

// ============ PALADIN MANAGER ============

/datum/paladin_manager
	var/obj/machinery/paladin_terminal/bos/owner

/datum/paladin_manager/New(obj/machinery/paladin_terminal/bos/terminal)
	owner = terminal

/datum/paladin_manager/proc/get_ui_data(mob/user)
	var/list/data = list()

	var/datum/paladin_progression/progression = get_progression(user.ckey)
	if(!progression)
		progression = new /datum/paladin_progression(user.ckey)
		GLOB.paladin_progressions += progression

	data["progression"] = progression.get_ui_data()
	data["bos_reputation"] = get_bos_reputation(user.ckey)
	data["can_advance"] = can_advance(user, progression)
	data["is_wearing_pa"] = is_wearing_power_armor(user)

	var/list/available_missions = list()
	for(var/datum/paladin_mission/mission as anything in get_available_missions(progression))
		available_missions += list(mission.get_ui_data())
	data["available_missions"] = available_missions

	return data

/datum/paladin_manager/proc/get_progression(ckey)
	for(var/datum/paladin_progression/P as anything in GLOB.paladin_progressions)
		if(P.ckey == ckey)
			return P
	return null

/datum/paladin_manager/proc/get_bos_reputation(ckey)
	return 0

/datum/paladin_manager/proc/is_wearing_power_armor(mob/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	return istype(H.wear_suit, /obj/item/clothing/suit/armor/power_armor)

/datum/paladin_manager/proc/can_advance(mob/user, datum/paladin_progression/progression)
	var/rep = get_bos_reputation(user.ckey)
	var/next_tier = progression.paladin_tier + 1

	switch(next_tier)
		if(PALADIN_TIER_KNIGHT)
			return rep >= PALADIN_REP_KNIGHT
		if(PALADIN_TIER_KNIGHT_SERGEANT)
			return rep >= PALADIN_REP_KNIGHT_SERGEANT && progression.missions_completed >= 3
		if(PALADIN_TIER_PALADIN)
			return rep >= PALADIN_REP_PALADIN && progression.missions_completed >= 5
		if(PALADIN_TIER_SENIOR_PALADIN)
			return rep >= PALADIN_REP_SENIOR_PALADIN && progression.missions_completed >= 10
		if(PALADIN_TIER_PALADIN_COMMANDER)
			return rep >= PALADIN_REP_PALADIN_COMMANDER && progression.missions_completed >= 15
		if(PALADIN_TIER_HEAD_PALADIN)
			return rep >= PALADIN_REP_HEAD_PALADIN && progression.missions_completed >= 25

	return FALSE

/datum/paladin_manager/proc/get_available_missions(datum/paladin_progression/progression)
	var/list/missions = list()

	if(progression.paladin_tier >= PALADIN_TIER_KNIGHT)
		missions += new /datum/paladin_mission/tech_escort()
		missions += new /datum/paladin_mission/perimeter_defense()

	if(progression.paladin_tier >= PALADIN_TIER_KNIGHT_SERGEANT)
		missions += new /datum/paladin_mission/base_assault()
		missions += new /datum/paladin_mission/vip_extraction()

	if(progression.paladin_tier >= PALADIN_TIER_PALADIN)
		missions += new /datum/paladin_mission/high_value_target()

	return missions

/datum/paladin_manager/proc/handle_action(action, list/params, mob/user)
	switch(action)
		if("advance_tier")
			return advance_tier(user)
		if("accept_mission")
			return accept_mission(user, params)
		if("use_combat_stance")
			return use_combat_stance(user)
		if("use_tactical_command")
			return use_tactical_command(user)
		if("use_power_armor_boost")
			return use_power_armor_boost(user)

	return FALSE

/datum/paladin_manager/proc/advance_tier(mob/user)
	var/datum/paladin_progression/progression = get_progression(user.ckey)
	if(!progression)
		return FALSE

	if(!can_advance(user, progression))
		return FALSE

	progression.paladin_tier++

	var/tier_name = get_tier_name(progression.paladin_tier)
	to_chat(user, span_notice("You have been promoted to [tier_name]!"))

	grant_abilities(user, progression)

	return TRUE

/datum/paladin_manager/proc/get_tier_name(tier)
	switch(tier)
		if(PALADIN_TIER_INITIATE)
			return "Initiate"
		if(PALADIN_TIER_KNIGHT)
			return "Knight"
		if(PALADIN_TIER_KNIGHT_SERGEANT)
			return "Knight Sergeant"
		if(PALADIN_TIER_PALADIN)
			return "Paladin"
		if(PALADIN_TIER_SENIOR_PALADIN)
			return "Senior Paladin"
		if(PALADIN_TIER_PALADIN_COMMANDER)
			return "Paladin Commander"
		if(PALADIN_TIER_HEAD_PALADIN)
			return "Head Paladin"
	return "Unknown"

/datum/paladin_manager/proc/grant_abilities(mob/user, datum/paladin_progression/progression)
	if(progression.paladin_tier >= PALADIN_TIER_KNIGHT)
		var/datum/action/paladin_combat_stance/stance = new()
		stance.Grant(user)

	if(progression.paladin_tier >= PALADIN_TIER_KNIGHT_SERGEANT)
		var/datum/action/paladin_tactical_command/command = new()
		command.Grant(user)

	if(progression.paladin_tier >= PALADIN_TIER_PALADIN)
		var/datum/action/paladin_pa_boost/boost = new()
		boost.Grant(user)

/datum/paladin_manager/proc/accept_mission(mob/user, list/params)
	var/mission_id = params["mission_id"]
	if(!mission_id)
		return FALSE

	if(GLOB.bos_player_active_missions[user.ckey])
		to_chat(user, span_warning("You already have an active mission."))
		return FALSE

	var/datum/paladin_progression/progression = get_progression(user.ckey)
	if(!progression)
		return FALSE

	for(var/datum/paladin_mission/mission as anything in get_available_missions(progression))
		if(mission.id == mission_id)
			progression.active_mission = mission
			GLOB.bos_player_active_missions[user.ckey] = mission_id
			to_chat(user, span_notice("Mission accepted: [mission.name]"))
			return TRUE

	return FALSE

/datum/paladin_manager/proc/use_combat_stance(mob/user)
	var/datum/paladin_progression/progression = get_progression(user.ckey)
	if(!progression || progression.paladin_tier < PALADIN_TIER_KNIGHT)
		return FALSE

	if(progression.combat_stance_cooldown > world.time)
		to_chat(user, span_warning("Combat stance on cooldown."))
		return FALSE

	var/duration = 30 SECONDS + (progression.paladin_tier * 5 SECONDS)

	progression.combat_stance_active = TRUE
	to_chat(user, span_notice("You enter a combat stance. +15% damage for [duration/10] seconds."))

	addtimer(CALLBACK(src, PROC_REF(end_combat_stance), user), duration)

	progression.combat_stance_cooldown = world.time + PALADIN_COMBAT_COOLDOWN

	return TRUE

/datum/paladin_manager/proc/end_combat_stance(mob/user)
	var/datum/paladin_progression/progression = get_progression(user.ckey)
	if(progression)
		progression.combat_stance_active = FALSE
		if(user)
			to_chat(user, span_notice("Your combat stance ends."))

/datum/paladin_manager/proc/use_tactical_command(mob/user)
	var/datum/paladin_progression/progression = get_progression(user.ckey)
	if(!progression || progression.paladin_tier < PALADIN_TIER_KNIGHT_SERGEANT)
		return FALSE

	if(progression.tactical_cooldown > world.time)
		to_chat(user, span_warning("Tactical command on cooldown."))
		return FALSE

	var/range = 7 + progression.paladin_tier
	var/bonus = 10 + (progression.paladin_tier * 2)

	for(var/mob/living/carbon/human/H in range(range, user))
		if(H.stat == CONSCIOUS && (H.mind?.assigned_role in list("Knight", "Knight Sergeant", "Paladin", "Senior Paladin", "Paladin Commander", "Head Paladin")))
			to_chat(H, span_notice("Tactical Command active! +[bonus]% combat effectiveness."))
			H.add_filter("paladin_command", 2, list("type" = "outline", "color" = "#ffcc00", "size" = 1))
			addtimer(CALLBACK(src, PROC_REF(end_tactical_command), H), 45 SECONDS)

	to_chat(user, span_notice("You issue tactical commands to nearby Brotherhood members."))

	progression.tactical_cooldown = world.time + PALADIN_TACTICAL_COOLDOWN

	return TRUE

/datum/paladin_manager/proc/end_tactical_command(mob/user)
	if(user)
		user.remove_filter("paladin_command")
		to_chat(user, span_notice("Tactical command effect ends."))

/datum/paladin_manager/proc/use_power_armor_boost(mob/user)
	var/datum/paladin_progression/progression = get_progression(user.ckey)
	if(!progression || progression.paladin_tier < PALADIN_TIER_PALADIN)
		return FALSE

	if(!is_wearing_power_armor(user))
		to_chat(user, span_warning("You must be wearing power armor."))
		return FALSE

	if(progression.pa_boost_cooldown > world.time)
		to_chat(user, span_warning("Power armor boost on cooldown."))
		return FALSE

	var/mob/living/carbon/human/H = user

	H.add_movespeed_modifier(/datum/movespeed_modifier/paladin_boost)
	H.adjustBruteLoss(-10)
	H.adjustFireLoss(-10)

	to_chat(H, span_notice("Power armor systems boosted! Speed and repairs activated."))

	addtimer(CALLBACK(src, PROC_REF(end_pa_boost), H), 60 SECONDS)

	progression.pa_boost_cooldown = world.time + PALADIN_PA_COOLDOWN

	return TRUE

/datum/paladin_manager/proc/end_pa_boost(mob/living/carbon/human/user)
	if(user)
		user.remove_movespeed_modifier(/datum/movespeed_modifier/paladin_boost)
		to_chat(user, span_notice("Power armor boost ends."))

// ============ PALADIN PROGRESSION ============

/datum/paladin_progression
	var/ckey
	var/paladin_tier = PALADIN_TIER_INITIATE
	var/missions_completed = 0
	var/missions_failed = 0
	var/tech_recovered = 0
	var/combat_victories = 0
	var/codex_violations = 0

	var/combat_stance_active = FALSE
	var/combat_stance_cooldown = 0
	var/tactical_cooldown = 0
	var/pa_boost_cooldown = 0

	var/datum/paladin_mission/active_mission

/datum/paladin_progression/New(player_ckey)
	ckey = player_ckey

/datum/paladin_progression/proc/get_ui_data()
	return list(
		"paladin_tier" = paladin_tier,
		"tier_name" = get_tier_name_ui(paladin_tier),
		"missions_completed" = missions_completed,
		"missions_failed" = missions_failed,
		"tech_recovered" = tech_recovered,
		"combat_victories" = combat_victories,
		"codex_violations" = codex_violations,
		"active_mission" = active_mission ? active_mission.get_ui_data() : null,
		"combat_stance_cooldown" = max(0, round((combat_stance_cooldown - world.time) / 10)),
		"tactical_cooldown" = max(0, round((tactical_cooldown - world.time) / 10)),
		"pa_boost_cooldown" = max(0, round((pa_boost_cooldown - world.time) / 10)),
	)

/datum/paladin_progression/proc/get_tier_name_ui(tier)
	switch(tier)
		if(PALADIN_TIER_INITIATE)
			return "Initiate"
		if(PALADIN_TIER_KNIGHT)
			return "Knight"
		if(PALADIN_TIER_KNIGHT_SERGEANT)
			return "Knight Sergeant"
		if(PALADIN_TIER_PALADIN)
			return "Paladin"
		if(PALADIN_TIER_SENIOR_PALADIN)
			return "Senior Paladin"
		if(PALADIN_TIER_PALADIN_COMMANDER)
			return "Paladin Commander"
		if(PALADIN_TIER_HEAD_PALADIN)
			return "Head Paladin"
	return "Unknown"

// ============ PALADIN MISSIONS ============

/datum/paladin_mission
	var/id
	var/name
	var/description
	var/difficulty = 1
	var/research_reward = 50
	var/reputation_reward = 5
	var/required_tier = PALADIN_TIER_KNIGHT

/datum/paladin_mission/proc/get_ui_data()
	return list(
		"id" = id,
		"name" = name,
		"description" = description,
		"difficulty" = difficulty,
		"research_reward" = research_reward,
		"reputation_reward" = reputation_reward,
	)

/datum/paladin_mission/tech_escort
	id = "tech_escort"
	name = "Scribe Escort"
	description = "Protect a Scribe during field operations."
	difficulty = 2
	research_reward = 75
	reputation_reward = 10
	required_tier = PALADIN_TIER_KNIGHT

/datum/paladin_mission/perimeter_defense
	id = "perimeter_defense"
	name = "Perimeter Defense"
	description = "Defend Brotherhood territory from hostile forces."
	difficulty = 2
	research_reward = 50
	reputation_reward = 8
	required_tier = PALADIN_TIER_KNIGHT

/datum/paladin_mission/base_assault
	id = "base_assault"
	name = "Base Assault"
	description = "Lead an assault on a hostile installation."
	difficulty = 4
	research_reward = 150
	reputation_reward = 15
	required_tier = PALADIN_TIER_KNIGHT_SERGEANT

/datum/paladin_mission/vip_extraction
	id = "vip_extraction"
	name = "VIP Extraction"
	description = "Extract a high-value asset from enemy territory."
	difficulty = 3
	research_reward = 125
	reputation_reward = 12
	required_tier = PALADIN_TIER_KNIGHT_SERGEANT

/datum/paladin_mission/high_value_target
	id = "high_value_target"
	name = "Eliminate HVT"
	description = "Neutralize a high-value target (Paladins only)."
	difficulty = 5
	research_reward = 250
	reputation_reward = 25
	required_tier = PALADIN_TIER_PALADIN

// ============ PALADIN ABILITIES ============

/datum/action/paladin_combat_stance
	name = "Paladin Combat Stance"
	desc = "Enter a combat stance for +15% damage."
	button_icon_state = "paladin_combat"
	check_flags = AB_CHECK_CONSCIOUS

	var/last_use = 0
	var/cooldown = PALADIN_COMBAT_COOLDOWN
	var/active = FALSE

/datum/action/paladin_combat_stance/Trigger(trigger_flags)
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

/datum/action/paladin_combat_stance/proc/end_combat()
	active = FALSE
	if(owner)
		to_chat(owner, span_notice("Your combat stance ends."))

/datum/action/paladin_tactical_command
	name = "Tactical Command"
	desc = "Issue commands to nearby Brotherhood members for combat bonuses."
	button_icon_state = "paladin_command"
	check_flags = AB_CHECK_CONSCIOUS

	var/last_use = 0
	var/cooldown = PALADIN_TACTICAL_COOLDOWN

/datum/action/paladin_tactical_command/Trigger(trigger_flags)
	if(!owner)
		return FALSE

	if(world.time < last_use + cooldown)
		to_chat(owner, span_warning("Tactical command on cooldown."))
		return FALSE

	var/range = 7
	var/bonus = 10

	for(var/mob/living/carbon/human/H in range(range, owner))
		if(H.stat == CONSCIOUS && (H.mind?.assigned_role in list("Knight", "Knight Sergeant", "Paladin", "Senior Paladin", "Paladin Commander", "Head Paladin")))
			to_chat(H, span_notice("Tactical Command active! +[bonus]% combat effectiveness."))
			H.add_filter("paladin_command", 2, list("type" = "outline", "color" = "#ffcc00", "size" = 1))
			addtimer(CALLBACK(src, PROC_REF(end_tactical_command), H), 45 SECONDS)

	to_chat(owner, span_notice("You issue tactical commands to nearby Brotherhood members."))

	last_use = world.time

	return TRUE

/datum/action/paladin_tactical_command/proc/end_tactical_command(mob/user)
	if(user)
		user.remove_filter("paladin_command")
		to_chat(user, span_notice("Tactical command effect ends."))

/datum/action/paladin_pa_boost
	name = "Power Armor Boost"
	desc = "Activate power armor systems for speed and repairs."
	button_icon_state = "paladin_boost"
	check_flags = AB_CHECK_CONSCIOUS

	var/last_use = 0
	var/cooldown = PALADIN_PA_COOLDOWN

/datum/action/paladin_pa_boost/Trigger(trigger_flags)
	if(!owner)
		return FALSE

	if(!ishuman(owner))
		return FALSE

	var/mob/living/carbon/human/H = owner

	if(!istype(H.wear_suit, /obj/item/clothing/suit/armor/power_armor))
		to_chat(owner, span_warning("You must be wearing power armor."))
		return FALSE

	if(world.time < last_use + cooldown)
		to_chat(owner, span_warning("Power armor boost on cooldown."))
		return FALSE

	H.add_movespeed_modifier(/datum/movespeed_modifier/paladin_boost)
	H.adjustBruteLoss(-10)
	H.adjustFireLoss(-10)

	to_chat(H, span_notice("Power armor systems boosted! Speed and repairs activated."))

	addtimer(CALLBACK(src, PROC_REF(end_pa_boost), H), 60 SECONDS)

	last_use = world.time

	return TRUE

/datum/action/paladin_pa_boost/proc/end_pa_boost(mob/living/carbon/human/user)
	if(user)
		user.remove_movespeed_modifier(/datum/movespeed_modifier/paladin_boost)
		to_chat(user, span_notice("Power armor boost ends."))

// ============ MOVESPEED MODIFIER ============

/datum/movespeed_modifier/paladin_boost
	movetypes = GROUND
	multiplicative_slowdown = -0.3
