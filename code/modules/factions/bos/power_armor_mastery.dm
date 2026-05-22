// BOS Power Armor Mastery System
// Training, maintenance, and customization

GLOBAL_LIST_EMPTY(pa_mastery_records)
GLOBAL_LIST_EMPTY(pa_mods)

// ============ POWER ARMOR BAY TERMINAL ============

/obj/machinery/power_armor_bay
	name = "Power Armor Bay Terminal"
	desc = "A terminal for power armor training, maintenance, and customization."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	req_access = list(ACCESS_BOS)
	density = FALSE
	anchored = TRUE

	var/datum/pa_bay_manager/manager

/obj/machinery/power_armor_bay/Initialize()
	. = ..()
	manager = new /datum/pa_bay_manager(src)
	InitializePAMods()

/obj/machinery/power_armor_bay/Destroy()
	QDEL_NULL(manager)
	return ..()

/obj/machinery/power_armor_bay/attack_hand(mob/user)
	if(!allowed(user))
		to_chat(user, span_warning("Access denied. Brotherhood personnel only."))
		return
	ui_interact(user)

/obj/machinery/power_armor_bay/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PowerArmorBay")
		ui.open()

/obj/machinery/power_armor_bay/ui_data(mob/user)
	return manager ? manager.get_ui_data(user) : list()

/obj/machinery/power_armor_bay/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	if(!manager)
		return FALSE

	. = manager.handle_action(action, params, usr)

// ============ PA BAY MANAGER ============

/datum/pa_bay_manager
	var/obj/machinery/power_armor_bay/owner

/datum/pa_bay_manager/New(obj/machinery/power_armor_bay/terminal)
	owner = terminal

/datum/pa_bay_manager/proc/get_ui_data(mob/user)
	var/list/data = list()

	var/datum/pa_mastery/mastery = get_mastery(user.ckey)
	if(!mastery)
		mastery = new /datum/pa_mastery(user.ckey)
		GLOB.pa_mastery_records += mastery

	data["mastery"] = mastery.get_ui_data()
	data["bos_reputation"] = get_bos_reputation(user.ckey)
	data["is_wearing_pa"] = is_wearing_power_armor(user)
	data["active_suit"] = get_active_suit_data(user)

	var/list/available_mods = list()
	for(var/datum/pa_mod/mod as anything in GLOB.pa_mods)
		available_mods += list(mod.get_ui_data(mastery.skill_level))
	data["available_mods"] = available_mods

	return data

/datum/pa_bay_manager/proc/get_mastery(ckey)
	for(var/datum/pa_mastery/M as anything in GLOB.pa_mastery_records)
		if(M.ckey == ckey)
			return M
	return null

/datum/pa_bay_manager/proc/get_bos_reputation(ckey)
	return 0

/datum/pa_bay_manager/proc/is_wearing_power_armor(mob/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	return istype(H.wear_suit, /obj/item/clothing/suit/armor/power_armor)

/datum/pa_bay_manager/proc/get_active_suit_data(mob/user)
	var/list/suit_data = list(
		"has_suit" = FALSE,
		"name" = "",
		"condition" = 100,
		"fuel" = 100,
		"mods" = list(),
	)

	if(!ishuman(user))
		return suit_data

	var/mob/living/carbon/human/H = user
	var/obj/item/clothing/suit/armor/power_armor/suit = H.wear_suit

	if(!istype(suit))
		return suit_data

	suit_data["has_suit"] = TRUE
	suit_data["name"] = suit.name
	suit_data["condition"] = get_suit_condition(suit)
	suit_data["fuel"] = suit.cell ? round((suit.cell.charge / suit.cell.maxcharge) * 100) : 0
	suit_data["mods"] = get_installed_mods(suit)

	return suit_data

/datum/pa_bay_manager/proc/get_suit_condition(obj/item/clothing/suit/armor/power_armor/suit)
	if(!suit)
		return 0
	return round((1 - (suit.obj_integrity / suit.max_integrity)) * 100)

/datum/pa_bay_manager/proc/get_installed_mods(obj/item/clothing/suit/armor/power_armor/suit)
	var/list/mods = list()
	return mods

/datum/pa_bay_manager/proc/handle_action(action, list/params, mob/user)
	switch(action)
		if("start_training")
			return start_training(user)
		if("perform_maintenance")
			return perform_maintenance(user)
		if("install_mod")
			return install_mod(user, params)
		if("remove_mod")
			return remove_mod(user, params)

	return FALSE

/datum/pa_bay_manager/proc/start_training(mob/user)
	var/datum/pa_mastery/mastery = get_mastery(user.ckey)
	if(!mastery)
		return FALSE

	if(mastery.training_in_progress)
		to_chat(user, span_warning("You are already training."))
		return FALSE

	var/next_level = mastery.skill_level + 1
	var/hours_required = get_hours_for_level(next_level)

	if(mastery.training_hours >= hours_required)
		mastery.skill_level = next_level
		mastery.training_hours = 0
		to_chat(user, span_notice("Power Armor skill advanced to level [next_level]!"))
		return TRUE

	mastery.training_in_progress = TRUE
	to_chat(user, span_notice("Beginning power armor training simulation..."))

	addtimer(CALLBACK(src, PROC_REF(complete_training), user), 30 SECONDS)

	return TRUE

/datum/pa_bay_manager/proc/complete_training(mob/user)
	var/datum/pa_mastery/mastery = get_mastery(user.ckey)
	if(!mastery)
		return

	mastery.training_in_progress = FALSE
	mastery.training_hours += 0.5
	to_chat(user, span_notice("Training session complete. Total hours: [mastery.training_hours]"))

/datum/pa_bay_manager/proc/get_hours_for_level(level)
	switch(level)
		if(1)
			return 5
		if(2)
			return 15
		if(3)
			return 30
		if(4)
			return 50
		if(5)
			return 100
	return 0

/datum/pa_bay_manager/proc/perform_maintenance(mob/user)
	var/datum/pa_mastery/mastery = get_mastery(user.ckey)
	if(!mastery || mastery.skill_level < 1)
		to_chat(user, span_warning("You need at least Basic PA training to perform maintenance."))
		return FALSE

	if(!ishuman(user))
		return FALSE

	var/mob/living/carbon/human/H = user
	var/obj/item/clothing/suit/armor/power_armor/suit = H.wear_suit

	if(!istype(suit))
		to_chat(user, span_warning("You must be wearing power armor to maintain it."))
		return FALSE

	to_chat(user, span_notice("Performing power armor maintenance..."))

	suit.obj_integrity = min(suit.obj_integrity + 50, suit.max_integrity)

	if(suit.cell)
		suit.cell.charge = min(suit.cell.charge + 500, suit.cell.maxcharge)

	to_chat(user, span_notice("Maintenance complete. Suit repaired and refueled."))
	return TRUE

/datum/pa_bay_manager/proc/install_mod(mob/user, list/params)
	var/mod_id = params["mod_id"]
	if(!mod_id)
		return FALSE

	var/datum/pa_mastery/mastery = get_mastery(user.ckey)
	if(!mastery)
		return FALSE

	var/datum/pa_mod/target_mod
	for(var/datum/pa_mod/mod as anything in GLOB.pa_mods)
		if(mod.id == mod_id)
			target_mod = mod
			break

	if(!target_mod)
		return FALSE

	if(mastery.skill_level < target_mod.skill_required)
		to_chat(user, span_warning("You need skill level [target_mod.skill_required] to install this mod."))
		return FALSE

	if(!ishuman(user))
		return FALSE

	var/mob/living/carbon/human/H = user
	var/obj/item/clothing/suit/armor/power_armor/suit = H.wear_suit

	if(!istype(suit))
		to_chat(user, span_warning("You must be wearing power armor to install mods."))
		return FALSE

	if(!(suit.type in target_mod.compatible_suits))
		to_chat(user, span_warning("This mod is not compatible with your power armor type."))
		return FALSE

	to_chat(user, span_notice("Installing [target_mod.name]... This will take [target_mod.installation_time / 600] minutes."))

	addtimer(CALLBACK(src, PROC_REF(complete_mod_install), user, target_mod, suit), target_mod.installation_time)

	return TRUE

/datum/pa_bay_manager/proc/complete_mod_install(mob/user, datum/pa_mod/mod, obj/item/clothing/suit/armor/power_armor/suit)
	if(!user || !suit)
		return

	to_chat(user, span_notice("[mod.name] successfully installed!"))
	apply_mod_effects(suit, mod)

/datum/pa_bay_manager/proc/apply_mod_effects(obj/item/clothing/suit/armor/power_armor/suit, datum/pa_mod/mod)
	return

/datum/pa_bay_manager/proc/remove_mod(mob/user, list/params)
	var/mod_id = params["mod_id"]
	if(!mod_id)
		return FALSE

	to_chat(user, span_notice("Mod removed."))
	return TRUE

// ============ PA MASTERY RECORD ============

/datum/pa_mastery
	var/ckey
	var/skill_level = 0
	var/training_hours = 0
	var/training_in_progress = FALSE
	var/list/suits_mastered = list()
	var/maintenance_bonus = 0
	var/movement_bonus = 0
	var/fuel_efficiency = 1.0

/datum/pa_mastery/New(player_ckey)
	ckey = player_ckey

/datum/pa_mastery/proc/get_ui_data()
	return list(
		"skill_level" = skill_level,
		"skill_name" = get_skill_name(skill_level),
		"training_hours" = training_hours,
		"training_in_progress" = training_in_progress,
		"suits_mastered" = suits_mastered,
		"movement_bonus" = get_movement_bonus(),
		"fuel_efficiency" = get_fuel_efficiency(),
		"next_level_hours" = get_next_level_hours(),
	)

/datum/pa_mastery/proc/get_skill_name(level)
	switch(level)
		if(0)
			return "Untrained"
		if(1)
			return "Basic"
		if(2)
			return "Proficient"
		if(3)
			return "Advanced"
		if(4)
			return "Expert"
		if(5)
			return "Master"
	return "Unknown"

/datum/pa_mastery/proc/get_movement_bonus()
	return skill_level * 10

/datum/pa_mastery/proc/get_fuel_efficiency()
	return 1.0 + (skill_level * 0.1)

/datum/pa_mastery/proc/get_next_level_hours()
	if(skill_level >= 5)
		return 0
	return get_hours_for_level(skill_level + 1)

/datum/pa_mastery/proc/get_hours_for_level(level)
	switch(level)
		if(1)
			return 5
		if(2)
			return 15
		if(3)
			return 30
		if(4)
			return 50
		if(5)
			return 100
	return 0

// ============ PA MOD DEFINITIONS ============

/datum/pa_mod
	var/id
	var/name
	var/description
	var/list/compatible_suits = list()
	var/installation_time = 5 MINUTES
	var/skill_required = 3
	var/rarity = "uncommon"
	var/list/effects = list()

/datum/pa_mod/proc/get_ui_data(user_skill)
	return list(
		"id" = id,
		"name" = name,
		"description" = description,
		"skill_required" = skill_required,
		"can_install" = user_skill >= skill_required,
		"rarity" = rarity,
		"installation_time" = installation_time / 600,
	)

/datum/pa_mod/jetpack
	id = "jetpack"
	name = "Jetpack"
	description = "Enables flight capability for compatible power armor suits."
	compatible_suits = list(
		/obj/item/clothing/suit/armor/power_armor/t51b,
		/obj/item/clothing/suit/armor/power_armor/advanced,
	)
	installation_time = 10 MINUTES
	skill_required = 4
	rarity = "rare"

/datum/pa_mod/medical_system
	id = "medical_system"
	name = "Medical System"
	description = "Automatically injects stimpaks when the wearer is injured."
	compatible_suits = list(
		/obj/item/clothing/suit/armor/power_armor/t45d,
		/obj/item/clothing/suit/armor/power_armor/t51b,
		/obj/item/clothing/suit/armor/power_armor/advanced,
	)
	installation_time = 5 MINUTES
	skill_required = 3
	rarity = "uncommon"

/datum/pa_mod/targeting_hud
	id = "targeting_hud"
	name = "Targeting HUD"
	description = "Provides night vision and highlights enemy targets."
	compatible_suits = list(
		/obj/item/clothing/suit/armor/power_armor/t45d,
		/obj/item/clothing/suit/armor/power_armor/t51b,
		/obj/item/clothing/suit/armor/power_armor/advanced,
	)
	installation_time = 3 MINUTES
	skill_required = 2
	rarity = "common"

/datum/pa_mod/strength_servos
	id = "strength_servos"
	name = "Strength Servos"
	description = "Increases strength by 2 while the suit is worn."
	compatible_suits = list(
		/obj/item/clothing/suit/armor/power_armor/t45d,
		/obj/item/clothing/suit/armor/power_armor/t51b,
		/obj/item/clothing/suit/armor/power_armor/advanced,
	)
	installation_time = 5 MINUTES
	skill_required = 3
	rarity = "uncommon"

/datum/pa_mod/mobility_frame
	id = "mobility_frame"
	name = "Mobility Frame"
	description = "Increases movement speed by 20%."
	compatible_suits = list(
		/obj/item/clothing/suit/armor/power_armor/t45d,
		/obj/item/clothing/suit/armor/power_armor/t51b,
	)
	installation_time = 4 MINUTES
	skill_required = 2
	rarity = "common"

/datum/pa_mod/armor_plating
	id = "armor_plating"
	name = "Armor Plating"
	description = "Increases damage resistance by 15%."
	compatible_suits = list(
		/obj/item/clothing/suit/armor/power_armor/t45d,
		/obj/item/clothing/suit/armor/power_armor/t51b,
		/obj/item/clothing/suit/armor/power_armor/advanced,
	)
	installation_time = 6 MINUTES
	skill_required = 2
	rarity = "common"

/datum/pa_mod/stealth_field
	id = "stealth_field"
	name = "Stealth Field"
	description = "Provides limited invisibility for short durations."
	compatible_suits = list(
		/obj/item/clothing/suit/armor/power_armor/advanced,
	)
	installation_time = 15 MINUTES
	skill_required = 5
	rarity = "legendary"

/datum/pa_mod/tesla_coils
	id = "tesla_coils"
	name = "Tesla Coils"
	description = "Shocks melee attackers with electrical discharge."
	compatible_suits = list(
		/obj/item/clothing/suit/armor/power_armor/t51b,
		/obj/item/clothing/suit/armor/power_armor/advanced,
	)
	installation_time = 8 MINUTES
	skill_required = 4
	rarity = "rare"

/proc/InitializePAMods()
	if(GLOB.pa_mods.len)
		return

	GLOB.pa_mods += new /datum/pa_mod/jetpack()
	GLOB.pa_mods += new /datum/pa_mod/medical_system()
	GLOB.pa_mods += new /datum/pa_mod/targeting_hud()
	GLOB.pa_mods += new /datum/pa_mod/strength_servos()
	GLOB.pa_mods += new /datum/pa_mod/mobility_frame()
	GLOB.pa_mods += new /datum/pa_mod/armor_plating()
	GLOB.pa_mods += new /datum/pa_mod/stealth_field()
	GLOB.pa_mods += new /datum/pa_mod/tesla_coils()
