// Enclave Secret Base System
// Hidden base management, detection avoidance

// ============ SECRET BASE MANAGER ============

/datum/enclave_secret_base
	var/base_id = "enclave_main"
	var/name = "Enclave Command Center"
	var/detection_risk = 0
	var/security_level = BASE_SECURITY_GOOD
	var/disguised_as = "Abandoned Warehouse"
	var/list/entrances = list()
	var/list/detection_log = list()
	var/lockdown_active = FALSE

/datum/enclave_secret_base/proc/add_entrance(obj/structure/hidden_entrance/entrance)
	entrances += entrance

/datum/enclave_secret_base/proc/remove_entrance(obj/structure/hidden_entrance/entrance)
	entrances -= entrance

/datum/enclave_secret_base/proc/increase_detection(amount, reason)
	detection_risk = clamp(detection_risk + amount, 0, 100)

	var/datum/detection_event/event = new()
	event.time = world.time
	event.amount = amount
	event.reason = reason
	detection_log += event

	if(detection_log.len > 20)
		detection_log.Cut(1, 2)

	if(detection_risk >= 100)
		trigger_compromise()

/datum/enclave_secret_base/proc/decrease_detection(amount)
	detection_risk = clamp(detection_risk - amount, 0, 100)

/datum/enclave_secret_base/proc/process_detection()
	var/decay_rate = 1
	switch(security_level)
		if(BASE_SECURITY_EXCELLENT)
			decay_rate = 2
		if(BASE_SECURITY_PERFECT)
			decay_rate = 3

	decrease_detection(decay_rate)

/datum/enclave_secret_base/proc/set_security_level(level)
	security_level = clamp(level, BASE_SECURITY_POOR, BASE_SECURITY_PERFECT)

/datum/enclave_secret_base/proc/set_disguise(disguise)
	disguised_as = disguise

/datum/enclave_secret_base/proc/trigger_lockdown()
	lockdown_active = TRUE

	for(var/obj/structure/hidden_entrance/E in entrances)
		E.locked = TRUE

	for(var/mob/M in GLOB.player_list)
		if(M.faction == "enclave")
			to_chat(M, span_userdanger("BASE LOCKDOWN INITIATED!"))

	addtimer(CALLBACK(src, .proc/end_lockdown), 5 MINUTES)

/datum/enclave_secret_base/proc/end_lockdown()
	lockdown_active = FALSE

	for(var/obj/structure/hidden_entrance/E in entrances)
		E.locked = FALSE

	for(var/mob/M in GLOB.player_list)
		if(M.faction == "enclave")
			to_chat(M, span_notice("Base lockdown lifted."))

/datum/enclave_secret_base/proc/trigger_compromise()
	for(var/mob/M in GLOB.player_list)
		if(M.faction == "enclave")
			to_chat(M, span_userdanger("BASE COMPROMISED! EVACUATE IMMEDIATELY!"))
			to_chat(M, span_warning("You have 5 minutes to evacuate before the base is lost."))

	addtimer(CALLBACK(src, .proc/complete_evacuation), 5 MINUTES)

/datum/enclave_secret_base/proc/complete_evacuation()
	detection_risk = 0
	for(var/mob/M in GLOB.player_list)
		if(M.faction == "enclave")
			to_chat(M, span_danger("Base has been compromised and relocated."))

/datum/enclave_secret_base/proc/get_detection_status()
	if(detection_risk >= 75)
		return "CRITICAL"
	else if(detection_risk >= 50)
		return "HIGH"
	else if(detection_risk >= 25)
		return "MODERATE"
	else
		return "LOW"

// ============ DETECTION EVENT DATUM ============

/datum/detection_event
	var/time
	var/amount
	var/reason

// ============ HIDDEN ENTRANCE ============

/obj/structure/hidden_entrance
	name = "Wall"
	desc = "A perfectly normal wall."
	icon = 'icons/obj/structures.dmi'
	icon_state = "wall"
	density = TRUE
	anchored = TRUE

	var/base_id = "enclave_main"
	var/entrance_type = "hidden_door"
	var/discovered = FALSE
	var/locked = FALSE
	var/requires_access = TRUE
	var/discovery_risk = "low"

/obj/structure/hidden_entrance/attack_hand(mob/user)
	if(discovered)
		if(locked)
			to_chat(user, span_warning("The entrance is locked."))
			return
		open(user)
		return

	if(requires_access && user.faction != "enclave")
		to_chat(user, span_notice("It's just a regular wall."))
		return

	open(user)

/obj/structure/hidden_entrance/proc/open(mob/user)
	if(locked)
		to_chat(user, span_warning("The entrance is sealed."))
		return

	density = !density
	icon_state = density ? "wall" : "wall_open"

	if(density)
		to_chat(user, span_notice("You seal the hidden entrance."))
	else
		to_chat(user, span_notice("You open the hidden entrance."))
		GLOB.enclave_secret_base.increase_detection(1, "Entrance used")

/obj/structure/hidden_entrance/proc/discover(mob/user)
	if(discovered)
		return

	discovered = TRUE
	GLOB.enclave_secret_base.increase_detection(20, "Entrance discovered by [user.ckey]")

/obj/structure/hidden_entrance/proc/seal()
	density = TRUE
	icon_state = "wall"
	locked = TRUE

// ============ BASE SECURITY TERMINAL ============

/obj/machinery/computer/enclave_base_security
	name = "Enclave Base Security Terminal"
	desc = "A terminal for managing base security."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/enclave_base_security/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/enclave_base_security/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BaseSecurity")
		ui.open()

/obj/machinery/computer/enclave_base_security/ui_data(mob/user)
	var/list/data = list()

	data["base_name"] = GLOB.enclave_secret_base.name
	data["disguise"] = GLOB.enclave_secret_base.disguised_as
	data["detection_risk"] = GLOB.enclave_secret_base.detection_risk
	data["detection_status"] = GLOB.enclave_secret_base.get_detection_status()
	data["security_level"] = GLOB.enclave_secret_base.security_level
	data["lockdown"] = GLOB.enclave_secret_base.lockdown_active

	var/list/entrances_data = list()
	for(var/obj/structure/hidden_entrance/E in GLOB.enclave_secret_base.entrances)
		entrances_data += list(list(
			"ref" = REF(E),
			"type" = E.entrance_type,
			"discovered" = E.discovered,
			"locked" = E.locked,
			"risk" = E.discovery_risk,
		))
	data["entrances"] = entrances_data

	var/list/log_data = list()
	for(var/datum/detection_event/E in GLOB.enclave_secret_base.detection_log)
		log_data += list(list(
			"time" = E.time,
			"amount" = E.amount,
			"reason" = E.reason,
		))
	data["detection_log"] = log_data

	var/list/security_options = list(
		list("level" = BASE_SECURITY_POOR, "name" = "Poor", "modifier" = "+50%"),
		list("level" = BASE_SECURITY_FAIR, "name" = "Fair", "modifier" = "+25%"),
		list("level" = BASE_SECURITY_GOOD, "name" = "Good", "modifier" = "Normal"),
		list("level" = BASE_SECURITY_EXCELLENT, "name" = "Excellent", "modifier" = "-25%"),
		list("level" = BASE_SECURITY_PERFECT, "name" = "Perfect", "modifier" = "-50%"),
	)
	data["security_options"] = security_options

	return data

/obj/machinery/computer/enclave_base_security/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("set_security")
			var/level = text2num(params["level"])
			GLOB.enclave_secret_base.set_security_level(level)
			to_chat(usr, span_notice("Security level updated."))
			return TRUE

		if("set_disguise")
			var/disguise = params["disguise"]
			GLOB.enclave_secret_base.set_disguise(disguise)
			to_chat(usr, span_notice("Disguise updated."))
			return TRUE

		if("lockdown")
			GLOB.enclave_secret_base.trigger_lockdown()
			to_chat(usr, span_warning("Lockdown initiated!"))
			return TRUE

		if("seal_entrance")
			var/ref = params["ref"]
			var/obj/structure/hidden_entrance/E = locate(ref)
			if(E)
				E.seal()
			return TRUE

		if("evacuate")
			GLOB.enclave_secret_base.trigger_compromise()
			return TRUE

	return FALSE

// ============ BASE DETECTION TRIGGERS ============

/obj/machinery/vertibird_launcher
	name = "Vertibird Launch Pad"
	desc = "A launch platform for vertibirds."
	icon = 'icons/obj/structures.dmi'
	icon_state = "launch_pad"
	density = FALSE
	anchored = TRUE

/obj/machinery/vertibird_launcher/proc/launch()
	GLOB.enclave_secret_base.increase_detection(10, "Vertibird launched")

/obj/machinery/eyebot_deployment
	name = "Eyebot Deployment Station"
	desc = "A station for deploying eyebots."
	icon = 'icons/obj/machines.dmi'
	icon_state = "eyebot_station"
	density = TRUE
	anchored = TRUE

/obj/machinery/eyebot_deployment/proc/deploy()
	GLOB.enclave_secret_base.increase_detection(2, "Eyebot deployed")

// ============ BASE POWER SPIKE ============

/datum/controller/subsystem/machinery/proc/check_power_spike()
	for(var/obj/machinery/M in GLOB.machines)
		if(M.power_usage > 5000 && M.faction == "enclave")
			GLOB.enclave_secret_base.increase_detection(5, "Power usage spike detected")
