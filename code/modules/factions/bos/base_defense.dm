// BOS Base Defense Network System
// Automated defenses, sensors, and security

GLOBAL_LIST_EMPTY(bos_defense_networks)
GLOBAL_VAR(bos_defense_network_initialized)

// ============ DEFENSE NETWORK CONTROLLER ============

/obj/machinery/defense_network_terminal
	name = "Brotherhood Defense Terminal"
	desc = "A terminal for managing automated base defense systems."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	req_access = list(ACCESS_BOS)
	density = FALSE
	anchored = TRUE

	var/datum/defense_network/network

/obj/machinery/defense_network_terminal/Initialize()
	. = ..()
	network = get_or_create_network()

/obj/machinery/defense_network_terminal/proc/get_or_create_network()
	if(GLOB.bos_defense_networks["main"])
		return GLOB.bos_defense_networks["main"]

	var/datum/defense_network/new_network = new /datum/defense_network("bos_main")
	GLOB.bos_defense_networks["main"] = new_network
	return new_network

/obj/machinery/defense_network_terminal/Destroy()
	if(network)
		network.terminals -= src
	return ..()

/obj/machinery/defense_network_terminal/attack_hand(mob/user)
	if(!allowed(user))
		to_chat(user, span_warning("Access denied. Brotherhood personnel only."))
		return
	ui_interact(user)

/obj/machinery/defense_network_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BOSDefenseNetwork")
		ui.open()

/obj/machinery/defense_network_terminal/ui_data(mob/user)
	return network ? network.get_ui_data() : list()

/obj/machinery/defense_network_terminal/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	if(!network)
		return FALSE

	. = network.handle_action(action, params, usr)

// ============ DEFENSE NETWORK DATUM ============

/datum/defense_network
	var/network_id
	var/list/terminals = list()
	var/list/connected_turrets = list()
	var/list/connected_sensors = list()
	var/list/connected_barriers = list()
	var/power_draw = 0
	var/max_power = 1000
	var/alert_level = 0
	var/list/detection_log = list()
	var/last_scan = 0

/datum/defense_network/New(id)
	network_id = id
	initialize_network()

/datum/defense_network/proc/initialize_network()
	connected_turrets += new /datum/defense_turret_data("alpha", "Entrance", 20, 10)
	connected_turrets += new /datum/defense_turret_data("bravo", "Armory", 15, 8)
	connected_turrets += new /datum/defense_turret_data("charlie", "Bunker Core", 25, 12)

	connected_sensors += new /datum/defense_sensor_data("sensor_1", "Perimeter North")
	connected_sensors += new /datum/defense_sensor_data("sensor_2", "Perimeter South")
	connected_sensors += new /datum/defense_sensor_data("sensor_3", "Bunker Interior")

	connected_barriers += new /datum/defense_barrier_data("barrier_1", "Main Gate")
	connected_barriers += new /datum/defense_barrier_data("barrier_2", "Armory Door")

/datum/defense_network/proc/get_ui_data()
	var/list/data = list()

	data["network_id"] = network_id
	data["alert_level"] = alert_level
	data["alert_name"] = get_alert_name(alert_level)
	data["power_draw"] = calculate_power_draw()
	data["max_power"] = max_power
	data["power_percent"] = round((max_power - calculate_power_draw()) / max_power * 100)

	var/list/turrets = list()
	for(var/datum/defense_turret_data/turret as anything in connected_turrets)
		turrets += list(turret.get_ui_data())
	data["turrets"] = turrets

	var/list/sensors = list()
	for(var/datum/defense_sensor_data/sensor as anything in connected_sensors)
		sensors += list(sensor.get_ui_data())
	data["sensors"] = sensors

	var/list/barriers = list()
	for(var/datum/defense_barrier_data/barrier as anything in connected_barriers)
		barriers += list(barrier.get_ui_data())
	data["barriers"] = barriers

	data["detection_log"] = detection_log

	return data

/datum/defense_network/proc/get_alert_name(level)
	switch(level)
		if(0)
			return "NORMAL"
		if(1)
			return "ELEVATED"
		if(2)
			return "HIGH"
		if(3)
			return "CRITICAL"
	return "UNKNOWN"

/datum/defense_network/proc/calculate_power_draw()
	var/total = 0
	for(var/datum/defense_turret_data/turret as anything in connected_turrets)
		if(turret.status != "standby")
			total += 50
	for(var/datum/defense_sensor_data/sensor as anything in connected_sensors)
		if(sensor.active)
			total += 20
	for(var/datum/defense_barrier_data/barrier as anything in connected_barriers)
		if(barrier.mode != "open")
			total += 100
	return total

/datum/defense_network/proc/handle_action(action, list/params, mob/user)
	switch(action)
		if("set_turret_mode")
			return set_turret_mode(params)
		if("toggle_turret")
			return toggle_turret(params)
		if("set_barrier_mode")
			return set_barrier_mode(params)
		if("set_alert_level")
			return set_alert_level(params)
		if("full_lockdown")
			return full_lockdown(user)
		if("all_turrets_active")
			return all_turrets_active(user)
		if("reset_to_normal")
			return reset_to_normal(user)
		if("scan_area")
			return scan_area(user)

	return FALSE

/datum/defense_network/proc/set_turret_mode(list/params)
	var/turret_id = params["turret_id"]
	var/mode = params["mode"]

	for(var/datum/defense_turret_data/turret as anything in connected_turrets)
		if(turret.id == turret_id)
			turret.mode = mode
			add_detection_log("Turret [turret.name] set to [mode] mode.")
			return TRUE
	return FALSE

/datum/defense_network/proc/toggle_turret(list/params)
	var/turret_id = params["turret_id"]

	for(var/datum/defense_turret_data/turret as anything in connected_turrets)
		if(turret.id == turret_id)
			turret.status = (turret.status == "standby") ? "active" : "standby"
			add_detection_log("Turret [turret.name] [turret.status == "active" ? "activated" : "deactivated"].")
			return TRUE
	return FALSE

/datum/defense_network/proc/set_barrier_mode(list/params)
	var/barrier_id = params["barrier_id"]
	var/mode = params["mode"]

	for(var/datum/defense_barrier_data/barrier as anything in connected_barriers)
		if(barrier.id == barrier_id)
			barrier.mode = mode
			add_detection_log("Barrier [barrier.name] set to [mode] mode.")
			return TRUE
	return FALSE

/datum/defense_network/proc/set_alert_level(list/params)
	var/level = text2num(params["level"])
	if(level < 0 || level > 3)
		return FALSE

	alert_level = level
	add_detection_log("Alert level changed to [get_alert_name(level)].")
	return TRUE

/datum/defense_network/proc/full_lockdown(mob/user)
	alert_level = 3

	for(var/datum/defense_turret_data/turret as anything in connected_turrets)
		turret.status = "active"
		turret.mode = "lethal"

	for(var/datum/defense_barrier_data/barrier as anything in connected_barriers)
		barrier.mode = "emergency"

	add_detection_log("FULL LOCKDOWN INITIATED by [user.ckey].")

	if(user)
		to_chat(user, span_danger("FULL LOCKDOWN INITIATED. All defenses activated."))

	return TRUE

/datum/defense_network/proc/all_turrets_active(mob/user)
	for(var/datum/defense_turret_data/turret as anything in connected_turrets)
		turret.status = "active"

	add_detection_log("All turrets activated by [user?.ckey].")

	if(user)
		to_chat(user, span_notice("All turrets activated."))

	return TRUE

/datum/defense_network/proc/reset_to_normal(mob/user)
	alert_level = 0

	for(var/datum/defense_turret_data/turret as anything in connected_turrets)
		turret.status = "standby"
		turret.mode = "stun"

	for(var/datum/defense_barrier_data/barrier as anything in connected_barriers)
		barrier.mode = "restricted"

	add_detection_log("Systems reset to NORMAL by [user?.ckey].")

	if(user)
		to_chat(user, span_notice("Defense systems reset to normal."))

	return TRUE

/datum/defense_network/proc/scan_area(mob/user)
	if(world.time < last_scan + 30 SECONDS)
		if(user)
			to_chat(user, span_warning("Scan on cooldown."))
		return FALSE

	last_scan = world.time
	add_detection_log("Area scan initiated by [user?.ckey].")

	if(user)
		to_chat(user, span_notice("Scanning area for hostiles..."))

	return TRUE

/datum/defense_network/proc/add_detection_log(message)
	var/entry = "[station_time_timestamp()] - [message]"
	detection_log.Insert(1, entry)
	if(detection_log.len > 20)
		detection_log.Cut(21)

// ============ TURRET DATA ============

/datum/defense_turret_data
	var/id
	var/name
	var/damage
	var/range
	var/status = "standby"
	var/mode = "stun"
	var/targets = 0

/datum/defense_turret_data/New(turret_id, turret_name, turret_damage, turret_range)
	id = turret_id
	name = turret_name
	damage = turret_damage
	range = turret_range

/datum/defense_turret_data/proc/get_ui_data()
	return list(
		"id" = id,
		"name" = name,
		"damage" = damage,
		"range" = range,
		"status" = status,
		"mode" = mode,
		"targets" = targets,
	)

// ============ SENSOR DATA ============

/datum/defense_sensor_data
	var/id
	var/name
	var/active = TRUE
	var/last_detection = null

/datum/defense_sensor_data/New(sensor_id, sensor_name)
	id = sensor_id
	name = sensor_name

/datum/defense_sensor_data/proc/get_ui_data()
	return list(
		"id" = id,
		"name" = name,
		"active" = active,
		"last_detection" = last_detection,
	)

// ============ BARRIER DATA ============

/datum/defense_barrier_data
	var/id
	var/name
	var/mode = "restricted"

/datum/defense_barrier_data/New(barrier_id, barrier_name)
	id = barrier_id
	name = barrier_name

/datum/defense_barrier_data/proc/get_ui_data()
	return list(
		"id" = id,
		"name" = name,
		"mode" = mode,
	)
