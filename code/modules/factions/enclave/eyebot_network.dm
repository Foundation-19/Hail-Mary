// Enclave Eyebot Network
// Surveillance, patrol, and propaganda broadcasting

GLOBAL_DATUM_INIT(enclave_eyebot_network, /datum/enclave_eyebot_network, new())

/datum/enclave_eyebot_network
	var/network_id = "enclave_primary"
	var/list/connected_eyebots = list()
	var/list/patrol_routes = list()
	var/list/alert_log = list()
	var/max_eyebots = EYEBOT_MAX_UNITS

/datum/enclave_eyebot_network/proc/register_eyebot(mob/living/simple_animal/hostile/eyebot/enclave/eyebot)
	if(!eyebot)
		return FALSE
	if(connected_eyebots.len >= max_eyebots)
		return FALSE
	connected_eyebots[eyebot.eyebot_id] = eyebot
	eyebot.network = src
	return TRUE

/datum/enclave_eyebot_network/proc/unregister_eyebot(eyebot_id)
	connected_eyebots -= eyebot_id

/datum/enclave_eyebot_network/proc/spawn_eyebot()
	if(connected_eyebots.len >= max_eyebots)
		return null
	var/list/z3_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	if(!z3_levels || !z3_levels.len)
		return null
	var/target_z = pick(z3_levels)
	var/list/candidate_turfs = list()
	for(var/turf/open/floor/F in block(locate(1, 1, target_z), locate(world.maxx, world.maxy, target_z)))
		if(!F.density && !istype(F, /turf/open/space))
			candidate_turfs += F
	if(!candidate_turfs.len)
		return null
	var/turf/spawn_loc = pick(candidate_turfs)
	var/mob/living/simple_animal/hostile/eyebot/enclave/new_eyebot = new(spawn_loc)
	if(register_eyebot(new_eyebot))
		return new_eyebot
	qdel(new_eyebot)
	return null

/datum/enclave_eyebot_network/proc/get_status_report()
	var/list/report = list()
	report["total_units"] = connected_eyebots ? connected_eyebots.len : 0
	report["max_units"] = max_eyebots
	report["active_patrols"] = 0
	report["alerts_24h"] = alert_log ? alert_log.len : 0

	var/list/units = list()
	for(var/eyebot_id in connected_eyebots)
		var/mob/living/simple_animal/hostile/eyebot/enclave/E = connected_eyebots[eyebot_id]
		if(E && !QDELETED(E))
			units += list(E.get_network_data())
			if(E.current_patrol)
				report["active_patrols"]++
	report["units"] = units

	return report

/datum/enclave_eyebot_network/proc/log_alert(mob/living/simple_animal/hostile/eyebot/enclave/source, mob/living/target)
	var/list/alert = list(
		"eyebot_id" = source.eyebot_id,
		"target_name" = target.name,
		"target_ckey" = target.ckey,
		"location" = "[get_area_name(target)]",
		"time" = world.time,
	)
	alert_log += list(alert)

	if(alert_log.len > 100)
		alert_log.Cut(1, 2)

/datum/enclave_eyebot_network/proc/broadcast_alert(mob/living/simple_animal/hostile/eyebot/enclave/source, mob/living/target)
	log_alert(source, target)

	for(var/mob/M in GLOB.player_list)
		if(M.client && M.mind)
			if(M.mind.assigned_role in list("Enclave Soldier", "Enclave Scientist", "Enclave Officer", "Enclave Commander"))
				to_chat(M, span_alert("EYEBOT ALERT: [source.eyebot_id] detected [target.name] at [get_area_name(target)]!"))

// ============ EYEBOT CONTROL CONSOLE ============

/obj/machinery/computer/eyebot_control
	name = "Enclave Eyebot Control Terminal"
	desc = "A terminal for managing the Enclave eyebot surveillance network."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/eyebot_control/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/eyebot_control/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EyebotControl")
		ui.open()

/obj/machinery/computer/eyebot_control/ui_data(mob/user)
	var/list/data = list()
	data["faction"] = "enclave"
	data["faction_name"] = "Enclave"

	var/datum/enclave_eyebot_network/network = GLOB.enclave_eyebot_network
	if(!network)
		return data

	data["status"] = network.get_status_report()

	var/list/routes = list()
	if(network.patrol_routes)
		for(var/datum/eyebot_patrol_route/route in network.patrol_routes)
			if(route)
				routes += list(route.get_ui_data())
	data["patrol_routes"] = routes

	var/list/alerts = list()
	if(network.alert_log && network.alert_log.len > 0)
		for(var/i = max(1, network.alert_log.len - 9) to network.alert_log.len)
			if(network.alert_log[i])
				alerts += list(network.alert_log[i])
	data["recent_alerts"] = alerts

	return data

/obj/machinery/computer/eyebot_control/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	var/datum/enclave_eyebot_network/network = GLOB.enclave_eyebot_network
	if(!network)
		return FALSE

	switch(action)
		if("spawn_eyebot")
			var/mob/living/simple_animal/hostile/eyebot/enclave/new_bot = network.spawn_eyebot()
			if(new_bot)
				to_chat(usr, span_notice("Eyebot [new_bot.eyebot_id] deployed to [get_area_name(new_bot)]."))
				return TRUE
			else
				to_chat(usr, span_warning("Cannot deploy more eyebots. Network at capacity or no valid spawn location."))
			return FALSE

		if("view_feed")
			var/eyebot_id = params["eyebot_id"]
			var/mob/living/simple_animal/hostile/eyebot/enclave/E = network.connected_eyebots[eyebot_id]
			if(E && !QDELETED(E))
				E.view_through(usr)
				return TRUE

		if("direct_control")
			var/eyebot_id = params["eyebot_id"]
			var/mob/living/simple_animal/hostile/eyebot/enclave/E = network.connected_eyebots[eyebot_id]
			if(E && !QDELETED(E))
				E.take_control(usr)
				return TRUE

		if("start_patrol")
			var/eyebot_id = params["eyebot_id"]
			var/route_id = params["route_id"]
			var/mob/living/simple_animal/hostile/eyebot/enclave/E = network.connected_eyebots[eyebot_id]
			if(!E || QDELETED(E))
				return FALSE
			for(var/datum/eyebot_patrol_route/route in network.patrol_routes)
				if(route.id == route_id)
					E.start_patrol(route)
					return TRUE
			return FALSE

		if("stop_patrol")
			var/eyebot_id = params["eyebot_id"]
			var/mob/living/simple_animal/hostile/eyebot/enclave/E = network.connected_eyebots[eyebot_id]
			if(E && !QDELETED(E))
				E.stop_patrol()
				return TRUE

		if("toggle_propaganda")
			var/eyebot_id = params["eyebot_id"]
			var/mob/living/simple_animal/hostile/eyebot/enclave/E = network.connected_eyebots[eyebot_id]
			if(E && !QDELETED(E))
				E.propaganda_enabled = !E.propaganda_enabled
				return TRUE

	return FALSE

// ============ ENCLAVE EYEBOT MOB ============

/mob/living/simple_animal/hostile/eyebot/enclave
	name = "Enclave Eyebot"
	desc = "An eyebot bearing Enclave markings. Its speakers are tuned for propaganda broadcasts."
	faction = list("enclave")

	var/eyebot_id
	var/datum/enclave_eyebot_network/network
	var/datum/eyebot_patrol_route/current_patrol
	var/current_waypoint = 1
	var/patrol_direction = 1
	var/patrol_enabled = FALSE
	var/propaganda_enabled = FALSE
	var/detection_range = EYEBOT_DETECTION_RANGE
	var/last_alert_time = 0
	var/battery_level = 100
	var/mob/living/original_mob
	var/was_ai_enabled = TRUE

/mob/living/simple_animal/hostile/eyebot/enclave/Initialize()
	. = ..()
	eyebot_id = "ED-[rand(10, 99)]"
	name = "Enclave [eyebot_id]"
	verbs += /mob/living/simple_animal/hostile/eyebot/enclave/proc/exit_control

/mob/living/simple_animal/hostile/eyebot/enclave/Destroy()
	if(network)
		network.unregister_eyebot(eyebot_id)
	return ..()

/mob/living/simple_animal/hostile/eyebot/enclave/Life()
	. = ..()
	if(stat == DEAD)
		return

	if(patrol_enabled && current_patrol)
		patrol_tick()

	if(propaganda_enabled)
		broadcast_propaganda()

	detect_enemies()

	battery_level -= EYEBOT_BATTERY_DRAIN
	if(battery_level <= 0)
		death()

/mob/living/simple_animal/hostile/eyebot/enclave/proc/get_network_data()
	return list(
		"eyebot_id" = eyebot_id || "UNKNOWN",
		"name" = name || "Enclave Eyebot",
		"status" = (stat == CONSCIOUS) ? "ONLINE" : "OFFLINE",
		"mode" = patrol_enabled ? "PATROL" : "SURVEILLANCE",
		"battery" = round(battery_level),
		"location" = "[x],[y]",
		"area" = get_area_name(src) || "Unknown",
		"patrol_route" = current_patrol ? current_patrol.name : null,
		"propaganda" = propaganda_enabled ? TRUE : FALSE,
	)

/mob/living/simple_animal/hostile/eyebot/enclave/proc/patrol_tick()
	if(!current_patrol || !current_patrol.waypoints.len)
		return

	if(current_waypoint > current_patrol.waypoints.len || current_waypoint < 1)
		return

	var/turf/target = current_patrol.waypoints[current_waypoint]
	if(!target)
		return

	if(get_dist(src, target) <= 1)
		current_waypoint += patrol_direction

		if(current_waypoint > current_patrol.waypoints.len)
			switch(current_patrol.loop_mode)
				if(PATROL_LOOP)
					current_waypoint = 1
				if(PATROL_PINGPONG)
					current_waypoint = current_patrol.waypoints.len - 1
					patrol_direction = -1
				if(PATROL_ONCE)
					stop_patrol()
					return
		else if(current_waypoint < 1)
			current_waypoint = 2
			patrol_direction = 1
	else
		walk_to(src, target, 1, 2)

/mob/living/simple_animal/hostile/eyebot/enclave/proc/start_patrol(datum/eyebot_patrol_route/route)
	if(!route || !route.waypoints.len)
		return FALSE
	current_patrol = route
	current_waypoint = 1
	patrol_direction = 1
	patrol_enabled = TRUE
	return TRUE

/mob/living/simple_animal/hostile/eyebot/enclave/proc/stop_patrol()
	patrol_enabled = FALSE
	current_patrol = null
	current_waypoint = 1

/mob/living/simple_animal/hostile/eyebot/enclave/proc/broadcast_propaganda()
	if(world.time % EYEBOT_PROPAGANDA_INTERVAL != 0)
		return

	var/message = pick(
		"Citizens! The Enclave offers protection from the lawless wastes!",
		"Trust in the Enclave. We are the last hope for America!",
		"Report mutant activity to your local Enclave representative!",
		"The Enclave: Rebuilding America, one step at a time!",
	)

	for(var/mob/living/carbon/human/H in range(EYEBOT_PROPAGANDA_RANGE, src))
		if(H.stat == CONSCIOUS)
			to_chat(H, span_notice("[name] broadcasts: \"[message]\""))
			adjust_karma(H.ckey, -1)

/mob/living/simple_animal/hostile/eyebot/enclave/proc/detect_enemies()
	if(world.time < last_alert_time + EYEBOT_ALERT_COOLDOWN)
		return

	for(var/mob/living/L in range(detection_range, src))
		if(L.stat != CONSCIOUS)
			continue
		if(L.faction && ("enclave" in L.faction))
			continue
		if(ishuman(L))
			if(network)
				network.broadcast_alert(src, L)
			last_alert_time = world.time
			return

/mob/living/simple_animal/hostile/eyebot/enclave/proc/view_through(mob/user)
	if(!user.client)
		return
	user.client.eye = src
	user.reset_perspective(src)
	to_chat(user, span_notice("Viewing through [name]. Use 'Reset View' to exit."))

/mob/living/simple_animal/hostile/eyebot/enclave/proc/take_control(mob/user)
	if(ckey)
		to_chat(user, span_warning("This eyebot is already under direct control."))
		return
	original_mob = user
	was_ai_enabled = (AIStatus != AI_OFF)
	toggle_ai(AI_OFF)
	ckey = user.ckey
	to_chat(user, span_notice("You are now directly controlling [name]. Use the 'Exit Control' verb to leave."))

/mob/living/simple_animal/hostile/eyebot/enclave/proc/exit_control()
	set name = "Exit Control"
	set category = "Eyebot"
	set desc = "Stop controlling the eyebot"

	if(!original_mob)
		return
	original_mob.ckey = ckey
	original_mob = null
	if(was_ai_enabled)
		toggle_ai(AI_ON)
	to_chat(usr, span_notice("You return to your body."))

/mob/living/simple_animal/hostile/eyebot/enclave/death(gibbed)
	if(network)
		network.unregister_eyebot(eyebot_id)
	if(original_mob && ckey)
		original_mob.ckey = ckey
		original_mob = null
		if(was_ai_enabled)
			toggle_ai(AI_ON)
	..()

// ============ PATROL ROUTE DATUM ============

/datum/eyebot_patrol_route
	var/id
	var/name = "Patrol Route"
	var/list/waypoints = list()
	var/loop_mode = PATROL_LOOP

/datum/eyebot_patrol_route/proc/get_ui_data()
	return list(
		"id" = id || "route_[rand(100,999)]",
		"name" = name || "Patrol Route",
		"waypoints_count" = waypoints ? waypoints.len : 0,
		"loop_mode" = loop_mode || PATROL_LOOP,
	)

/datum/eyebot_patrol_route/proc/add_waypoint(turf/T)
	if(T)
		waypoints += T

/datum/eyebot_patrol_route/proc/remove_waypoint(index)
	if(index > 0 && index <= waypoints.len)
		waypoints.Cut(index, index + 1)

// Pre-defined patrol routes
/datum/eyebot_patrol_route/alpha
	id = "route_alpha"
	name = "Perimeter Alpha"

/datum/eyebot_patrol_route/bravo
	id = "route_bravo"
	name = "Perimeter Bravo"

/datum/eyebot_patrol_route/charlie
	id = "route_charlie"
	name = "Interior Patrol"
