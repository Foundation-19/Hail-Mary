// Legion Slave Processing and Registry
// Managing slaves and their registration

// ============ SLAVE REGISTRY ENTRY ============

/datum/slave_registry_entry
	var/slave_ckey
	var/slave_name
	var/owner_ckey
	var/owner_name
	var/enslaver_ckey
	var/enslaved_time
	var/collar_type = "standard"
	var/slave_type = SLAVE_TYPE_LABOR
	var/datum/slave_obedience/obedience
	var/escape_attempts = 0
	var/gladiator_wins = 0
	var/status = "enslaved"
	var/freedom_timer_id = null

/datum/slave_registry_entry/New()
	obedience = new /datum/slave_obedience(src)

/datum/slave_registry_entry/Destroy()
	if(freedom_timer_id)
		deltimer(freedom_timer_id)
	QDEL_NULL(obedience)
	return ..()

/datum/slave_registry_entry/proc/get_ui_data()
	return list(
		"slave_ckey" = slave_ckey,
		"slave_name" = slave_name,
		"owner_ckey" = owner_ckey,
		"owner_name" = owner_name,
		"slave_type" = slave_type,
		"obedience" = obedience ? obedience.current_obedience : 50,
		"escape_attempts" = escape_attempts,
		"gladiator_wins" = gladiator_wins,
		"status" = status,
		"time_enslaved" = world.time - enslaved_time,
	)

/datum/slave_registry_entry/proc/free()
	status = "freed"
	if(freedom_timer_id)
		deltimer(freedom_timer_id)
		freedom_timer_id = null

	var/mob/living/carbon/human/H = get_slave_mob()
	if(H)
		var/obj/item/slave_collar/collar = H.get_item_by_slot(ITEM_SLOT_NECK)
		if(collar)
			H.dropItemToGround(collar)

/datum/slave_registry_entry/proc/get_slave_mob()
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.ckey == slave_ckey)
			return H
	return null

// ============ SLAVE OBEDIENCE ============

/datum/slave_obedience
	var/datum/slave_registry_entry/owner_entry
	var/current_obedience = 50
	var/last_fed = 0
	var/last_watered = 0
	var/last_rested = 0
	var/shocks_received = 0
	var/detonate_threats = 0
	var/last_shock = 0

/datum/slave_obedience/New(datum/slave_registry_entry/entry)
	owner_entry = entry

/datum/slave_obedience/proc/process_needs()
	var/mob/living/carbon/human/H = owner_entry.get_slave_mob()
	if(!H)
		return

	if(world.time - last_fed > 15 MINUTES)
		adjust_obedience(-10)
		H.adjustBruteLoss(5)

	if(world.time - last_watered > 15 MINUTES)
		adjust_obedience(-10)
		H.adjustBruteLoss(5)

	if(world.time - last_rested > 30 MINUTES)
		adjust_obedience(-5)

/datum/slave_obedience/proc/on_fed()
	last_fed = world.time
	adjust_obedience(5)

/datum/slave_obedience/proc/on_watered()
	last_watered = world.time
	adjust_obedience(5)

/datum/slave_obedience/proc/on_rested()
	last_rested = world.time
	adjust_obedience(2)

/datum/slave_obedience/proc/on_shock()
	shocks_received++
	last_shock = world.time
	adjust_obedience(-15)

	if(shocks_received >= 3 && world.time - last_shock < 5 MINUTES)
		message_admins("[owner_entry.owner_ckey] is shocking slave [owner_entry.slave_ckey] excessively.")

	check_revolt()

/datum/slave_obedience/proc/on_detonate_threat()
	detonate_threats++
	adjust_obedience(-20)

	if(detonate_threats >= 2)
		message_admins("[owner_entry.owner_ckey] has threatened to detonate [owner_entry.slave_ckey]'s collar multiple times.")

/datum/slave_obedience/proc/on_escape_attempt(failed = TRUE)
	if(failed)
		owner_entry.escape_attempts++
		adjust_obedience(-20)
	else
		adjust_obedience(10)

/datum/slave_obedience/proc/adjust_obedience(amount)
	current_obedience = clamp(current_obedience + amount, 0, 100)

	if(current_obedience < OBEDIENCE_REBELLIOUS)
		apply_rebellious_status()

		if(current_obedience < 10)
			message_admins("Slave obedience critical: [owner_entry.slave_ckey] owned by [owner_entry.owner_ckey]")

/datum/slave_obedience/proc/apply_rebellious_status()
	var/mob/living/carbon/human/H = owner_entry.get_slave_mob()
	if(!H)
		return

	to_chat(H, span_warning("You feel rebellious! Your obedience is critically low."))

/datum/slave_obedience/proc/check_revolt()
	if(current_obedience < 10)
		trigger_slave_revolt()

/datum/slave_obedience/proc/trigger_slave_revolt()
	var/mob/living/carbon/human/H = owner_entry.get_slave_mob()
	if(!H)
		return

	to_chat(H, span_userdanger("You've had enough! Time to revolt!"))
	H.say("ENOUGH! I WON'T TAKE THIS ANYMORE!")

// ============ SLAVE PROCESSING CONSOLE ============

/obj/machinery/computer/slave_management
	name = "Slave Management Terminal"
	desc = "A terminal for managing the Legion slave registry."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/slave_management/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/slave_management/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SlaveManagement")
		ui.open()

/obj/machinery/computer/slave_management/ui_data(mob/user)
	var/list/data = list()
	data["is_legion"] = check_legion(user)
	data["is_slave"] = check_slave(user)

	var/my_entry = get_slave_entry(user.ckey)
	if(my_entry)
		data["my_status"] = my_entry.get_ui_data()

	var/list/all_slaves = list()
	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.owner_ckey == user.ckey || check_legion(user))
			all_slaves += list(entry.get_ui_data())
	data["all_slaves"] = all_slaves

	var/list/market_slaves = list()
	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.status == "enslaved" && entry.slave_type == SLAVE_TYPE_SPECIALIST)
			market_slaves += list(entry.get_ui_data())
	data["market_slaves"] = market_slaves

	return data

/obj/machinery/computer/slave_management/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("process_slave")
			if(!check_legion(usr))
				return FALSE
			var/target_ckey = params["target_ckey"]
			var/slave_type = params["slave_type"]
			process_slave(target_ckey, slave_type, usr)
			return TRUE

		if("free_slave")
			var/target_ckey = params["target_ckey"]
			if(!can_manage_slave(usr, target_ckey))
				return FALSE
			free_slave(target_ckey)
			return TRUE

		if("transfer_slave")
			if(!check_legion(usr))
				return FALSE
			var/target_ckey = params["target_ckey"]
			var/new_owner = params["new_owner"]
			transfer_slave(target_ckey, new_owner)
			return TRUE

		if("shock_slave")
			var/target_ckey = params["target_ckey"]
			if(!can_manage_slave(usr, target_ckey))
				return FALSE
			var/level = text2num(params["level"])
			shock_slave(target_ckey, level)
			return TRUE

		if("change_type")
			if(!check_legion(usr))
				return FALSE
			var/target_ckey = params["target_ckey"]
			var/new_type = params["new_type"]
			change_slave_type(target_ckey, new_type)
			return TRUE

	return FALSE

/obj/machinery/computer/slave_management/proc/check_legion(mob/user)
	if(!user.mind)
		return FALSE
	if(user.mind.assigned_role in list("Legion Soldier", "Legion Veteran", "Legion Centurion", "Legion Legate", "Legion Arena Master", "Legion Slavemaster"))
		return TRUE
	return FALSE

/obj/machinery/computer/slave_management/proc/check_slave(mob/user)
	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == user.ckey && entry.status == "enslaved")
			return TRUE
	return FALSE

/obj/machinery/computer/slave_management/proc/get_slave_entry(ckey)
	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == ckey)
			return entry
	return null

/obj/machinery/computer/slave_management/proc/can_manage_slave(mob/user, target_ckey)
	if(!check_legion(user))
		return FALSE
	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == target_ckey && entry.owner_ckey == user.ckey)
			return TRUE
	return FALSE

/obj/machinery/computer/slave_management/proc/process_slave(target_ckey, slave_type, mob/processor)
	var/mob/living/carbon/human/H
	for(var/mob/living/carbon/human/M in GLOB.human_list)
		if(M.ckey == target_ckey)
			H = M
			break

	if(!H)
		to_chat(processor, span_warning("Cannot find target."))
		return FALSE

	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == target_ckey)
			to_chat(processor, span_warning("Target is already enslaved."))
			return FALSE

	var/obj/item/slave_collar/collar = new(get_turf(H))
	if(!H.equipToSlotIfPossible(collar, ITEM_SLOT_NECK))
		qdel(collar)
		to_chat(processor, span_warning("Cannot equip collar on target."))
		return FALSE

	collar.arm(processor)

	var/datum/slave_registry_entry/new_entry = new()
	new_entry.slave_ckey = target_ckey
	new_entry.slave_name = H.name
	new_entry.owner_ckey = processor.ckey
	new_entry.owner_name = processor.name
	new_entry.enslaver_ckey = processor.ckey
	new_entry.enslaved_time = world.time
	new_entry.slave_type = slave_type

	GLOB.legion_slave_registry += new_entry

	adjust_karma(processor.ckey, KARMA_ENSLAVE)

	to_chat(H, span_userdanger("You have been enslaved by the Legion!"))
	to_chat(processor, span_notice("[H.name] has been processed as a [slave_type] slave."))

	return TRUE

/obj/machinery/computer/slave_management/proc/free_slave(target_ckey)
	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == target_ckey)
			entry.free()
			return TRUE
	return FALSE

/obj/machinery/computer/slave_management/proc/transfer_slave(target_ckey, new_owner_ckey)
	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == target_ckey)
			entry.owner_ckey = new_owner_ckey

			var/mob/living/carbon/human/H
			for(var/mob/living/carbon/human/M in GLOB.human_list)
				if(M.ckey == new_owner_ckey)
					H = M
					entry.owner_name = M.name
					break

			if(entry.obedience)
				entry.obedience.adjust_obedience(-10)

			return TRUE
	return FALSE

/obj/machinery/computer/slave_management/proc/shock_slave(target_ckey, level)
	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == target_ckey)
			var/mob/living/carbon/human/H = entry.get_slave_mob()
			if(!H)
				return FALSE

			var/obj/item/slave_collar/collar = H.get_item_by_slot(ITEM_SLOT_NECK)
			if(collar)
				collar.shock(usr, level)

			return TRUE
	return FALSE

/obj/machinery/computer/slave_management/proc/change_slave_type(target_ckey, new_type)
	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == target_ckey)
			entry.slave_type = new_type
			return TRUE
	return FALSE
