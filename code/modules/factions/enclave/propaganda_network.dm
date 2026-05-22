// Enclave Propaganda Network
// Broadcast system for influence and information warfare

// ============ PROPAGANDA MANAGER ============

/datum/enclave_propaganda
	var/list/active_broadcasts = list()
	var/list/settlement_influence = list()
	var/list/message_templates = list()
	var/broadcast_power = 100

/datum/enclave_propaganda/proc/initialize_settlements()
	settlement_influence = list()

	var/list/settlements = list("Goodsprings", "Primm", "Novac", "Freeside", "Boulder City")
	for(var/settlement in settlements)
		var/datum/settlement_influence/si = new()
		si.settlement_name = settlement
		si.enclave_influence = 25
		settlement_influence += si

/datum/enclave_propaganda/proc/initialize_messages()
	message_templates = list()

	message_templates += list(list(
		"id" = "recruitment",
		"name" = "Enclave Recruitment",
		"text" = "The Enclave offers safety, order, and purpose. Join us.",
		"type" = "recruitment",
		"karma" = 0,
	))

	message_templates += list(list(
		"id" = "smear_ncr",
		"name" = "NCR Smear Campaign",
		"text" = "The NCR is corrupt, weak, and incapable of protecting you.",
		"type" = "faction_smear",
		"karma" = -5,
	))

	message_templates += list(list(
		"id" = "smear_legion",
		"name" = "Legion Warning",
		"text" = "The Legion will enslave you. Only the Enclave can stop them.",
		"type" = "faction_smear",
		"karma" = -3,
	))

	message_templates += list(list(
		"id" = "mutant_threat",
		"name" = "Mutant Threat Warning",
		"text" = "Mutants threaten your families. Support Enclave purification efforts.",
		"type" = "fear",
		"karma" = -10,
	))

	message_templates += list(list(
		"id" = "order_hope",
		"name" = "Order and Hope",
		"text" = "The Enclave brings order to chaos. A bright future awaits.",
		"type" = "hope",
		"karma" = 0,
	))

/datum/enclave_propaganda/proc/start_broadcast(method, target, message_id, duration)
	var/datum/propaganda_broadcast/broadcast = new()
	broadcast.broadcast_id = "broadcast_[world.time]"
	broadcast.method = method
	broadcast.target_settlement = target
	broadcast.message_id = message_id
	broadcast.duration = duration
	broadcast.start_time = world.time
	broadcast.active = TRUE

	active_broadcasts += broadcast

	apply_influence(broadcast)

	addtimer(CALLBACK(src, .proc/end_broadcast, broadcast.broadcast_id), duration)

	return TRUE

/datum/enclave_propaganda/proc/end_broadcast(broadcast_id)
	for(var/datum/propaganda_broadcast/B in active_broadcasts)
		if(B.broadcast_id == broadcast_id)
			B.active = FALSE
			active_broadcasts -= B
			qdel(B)
			return TRUE
	return FALSE

/datum/enclave_propaganda/proc/apply_influence(datum/propaganda_broadcast/broadcast)
	var/influence_gain = 0

	switch(broadcast.method)
		if(PROPAGANDA_RADIO)
			influence_gain = 3
		if(PROPAGANDA_EYEBOT)
			influence_gain = 5
		if(PROPAGANDA_TV)
			influence_gain = 8
		if(PROPAGANDA_PRINT)
			influence_gain = 2

	for(var/datum/settlement_influence/SI in settlement_influence)
		if(broadcast.target_settlement == "all" || SI.settlement_name == broadcast.target_settlement)
			SI.enclave_influence = clamp(SI.enclave_influence + influence_gain, 0, 100)

/datum/enclave_propaganda/proc/get_settlement_status(influence)
	if(influence >= INFLUENCE_ALLIED)
		return "Allied"
	else if(influence >= INFLUENCE_SYMPATHETIC)
		return "Sympathetic"
	else if(influence >= INFLUENCE_NEUTRAL)
		return "Neutral"
	else if(influence >= INFLUENCE_WARY)
		return "Wary"
	else
		return "Hostile"

/datum/enclave_propaganda/proc/decay_influence()
	for(var/datum/settlement_influence/SI in settlement_influence)
		SI.enclave_influence = max(0, SI.enclave_influence - 1)

// ============ PROPAGANDA BROADCAST DATUM ============

/datum/propaganda_broadcast
	var/broadcast_id
	var/method = PROPAGANDA_RADIO
	var/target_settlement = "all"
	var/message_id
	var/duration = 10 MINUTES
	var/start_time
	var/active = FALSE
	var/influence_strength = 1

// ============ SETTLEMENT INFLUENCE DATUM ============

/datum/settlement_influence
	var/settlement_name
	var/enclave_influence = 25
	var/other_faction_influence = 0
	var/population_opinion = 50

// ============ PROPAGANDA TERMINAL ============

/obj/machinery/computer/enclave_propaganda
	name = "Enclave Propaganda Terminal"
	desc = "A terminal for managing information warfare."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/enclave_propaganda/Initialize()
	. = ..()
	if(GLOB.enclave_propaganda.settlement_influence.len == 0)
		GLOB.enclave_propaganda.initialize_settlements()
	if(GLOB.enclave_propaganda.message_templates.len == 0)
		GLOB.enclave_propaganda.initialize_messages()

/obj/machinery/computer/enclave_propaganda/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/enclave_propaganda/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PropagandaNetwork")
		ui.open()

/obj/machinery/computer/enclave_propaganda/ui_data(mob/user)
	var/list/data = list()

	var/list/broadcasts_data = list()
	for(var/datum/propaganda_broadcast/B in GLOB.enclave_propaganda.active_broadcasts)
		broadcasts_data += list(list(
			"id" = B.broadcast_id,
			"method" = B.method,
			"target" = B.target_settlement,
			"message" = B.message_id,
			"remaining" = max(0, B.duration - (world.time - B.start_time)),
		))
	data["active_broadcasts"] = broadcasts_data

	var/list/settlements_data = list()
	for(var/datum/settlement_influence/SI in GLOB.enclave_propaganda.settlement_influence)
		settlements_data += list(list(
			"name" = SI.settlement_name,
			"influence" = SI.enclave_influence,
			"status" = GLOB.enclave_propaganda.get_settlement_status(SI.enclave_influence),
		))
	data["settlements"] = settlements_data

	data["messages"] = GLOB.enclave_propaganda.message_templates

	var/list/methods = list(
		list("id" = PROPAGANDA_RADIO, "name" = "Radio", "cost" = 0),
		list("id" = PROPAGANDA_EYEBOT, "name" = "Eyebot", "cost" = 1),
		list("id" = PROPAGANDA_TV, "name" = "TV", "cost" = 50),
		list("id" = PROPAGANDA_PRINT, "name" = "Printed", "cost" = 10),
	)
	data["methods"] = methods

	data["broadcast_power"] = GLOB.enclave_propaganda.broadcast_power

	return data

/obj/machinery/computer/enclave_propaganda/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("start_broadcast")
			var/method = params["method"]
			var/target = params["target"]
			var/message = params["message"]
			var/duration = text2num(params["duration"]) * 600

			var/karma_cost = 0
			for(var/list/m in GLOB.enclave_propaganda.message_templates)
				if(m["id"] == message)
					karma_cost = m["karma"]
					break

			adjust_karma(usr.ckey, karma_cost)

			GLOB.enclave_propaganda.start_broadcast(method, target, message, duration)
			to_chat(usr, span_notice("Broadcast started."))
			return TRUE

		if("end_broadcast")
			var/broadcast_id = params["broadcast_id"]
			GLOB.enclave_propaganda.end_broadcast(broadcast_id)
			return TRUE

	return FALSE

// ============ RADIO BROADCASTER ============

/obj/machinery/enclave_radio_tower
	name = "Enclave Radio Tower"
	desc = "A radio transmission tower for Enclave broadcasts."
	icon = 'icons/obj/structures.dmi'
	icon_state = "radio_tower"
	density = TRUE
	anchored = TRUE

	var/active = FALSE
	var/current_message = ""
	var/power_usage = 100

/obj/machinery/enclave_radio_tower/process()
	if(!active)
		return

	if(current_message)
		for(var/mob/M in GLOB.player_list)
			if(istype(M.loc, /area))
				to_chat(M, span_notice("[span_bold("ENCLAVE BROADCAST:")] [current_message]"))

// ============ INFLUENCE EFFECTS ============

/mob/living/carbon/human/proc/check_settlement_influence()
	var/area/A = get_area(src)
	if(!A)
		return

	for(var/datum/settlement_influence/SI in GLOB.enclave_propaganda.settlement_influence)
		if(findtext(A.name, SI.settlement_name))
			if(SI.enclave_influence >= INFLUENCE_SYMPATHETIC)
				adjust_faction_reputation(ckey, "enclave", 1)
			return
