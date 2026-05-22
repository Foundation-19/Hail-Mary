// NCR Caravan System
// Physical supply caravans that travel across the wasteland

GLOBAL_LIST_EMPTY(ncr_caravans)
GLOBAL_LIST_EMPTY(ncr_routes)

// ============ CARAVAN TERMINAL ============

/obj/machinery/caravan_terminal/ncr
	name = "NCR Caravan Terminal"
	desc = "A terminal for managing NCR supply routes and caravan logistics."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	req_access = list(ACCESS_NCR)
	density = FALSE
	anchored = TRUE

	var/datum/caravan_manager/manager

/obj/machinery/caravan_terminal/ncr/Initialize()
	. = ..()
	manager = new /datum/caravan_manager(src)

/obj/machinery/caravan_terminal/ncr/Destroy()
	QDEL_NULL(manager)
	return ..()

/obj/machinery/caravan_terminal/ncr/attack_hand(mob/user)
	if(!allowed(user))
		to_chat(user, span_warning("Access denied. NCR personnel only."))
		return
	ui_interact(user)

/obj/machinery/caravan_terminal/ncr/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CaravanLogistics")
		ui.open()

/obj/machinery/caravan_terminal/ncr/ui_data(mob/user)
	return manager ? manager.get_ui_data(user) : list()

/obj/machinery/caravan_terminal/ncr/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	if(!manager)
		return FALSE

	. = manager.handle_action(action, params, usr)

// ============ CARAVAN MANAGER ============

/datum/caravan_manager
	var/obj/machinery/caravan_terminal/ncr/owner
	var/list/routes = list()
	var/list/active_caravans = list()
	var/list/stats = list(
		"runs_today" = 0,
		"revenue" = 0,
		"supplies_delivered" = 0,
		"losses" = 0,
	)

/datum/caravan_manager/New(obj/machinery/caravan_terminal/ncr/terminal)
	owner = terminal
	GLOB.ncr_routes = routes
	GLOB.ncr_caravans = active_caravans
	register_routes()

/datum/caravan_manager/proc/register_routes()
	routes = list(
		new /datum/caravan_route/alpha(),
		new /datum/caravan_route/bravo(),
		new /datum/caravan_route/charlie(),
		new /datum/caravan_route/delta(),
	)

/datum/caravan_manager/proc/get_ui_data(mob/user)
	var/list/data = list()

	data["is_quartermaster"] = is_quartermaster(user)
	data["can_deploy"] = can_deploy_caravan(user)

	var/list/routes_data = list()
	for(var/datum/caravan_route/route as anything in routes)
		routes_data += list(route.get_ui_data())
	data["routes"] = routes_data

	var/list/caravans_data = list()
	for(var/obj/vehicle/caravan/caravan as anything in active_caravans)
		caravans_data += list(caravan.get_ui_data())
	data["active_caravans"] = caravans_data

	data["stats"] = stats

	var/list/my_escorts = list()
	for(var/obj/vehicle/caravan/caravan as anything in active_caravans)
		if(caravan.is_guard(user.ckey))
			my_escorts += list(caravan.get_ui_data())
	data["my_escorts"] = my_escorts

	return data

/datum/caravan_manager/proc/handle_action(action, list/params, mob/user)
	switch(action)
		if("deploy_caravan")
			return deploy_caravan(user, params)
		if("sign_up_escort")
			return sign_up_escort(user, params)
		if("cancel_escort")
			return cancel_escort(user, params)
		if("recall_caravan")
			return recall_caravan(user, params)

	return FALSE

/datum/caravan_manager/proc/is_quartermaster(mob/user)
	if(!user.mind || !user.mind.assigned_role)
		return FALSE
	return user.mind.assigned_role in list("NCR Quartermaster", "NCR Captain", "NCR Lieutenant")

/datum/caravan_manager/proc/can_deploy_caravan(mob/user)
	return is_quartermaster(user)

/datum/caravan_manager/proc/deploy_caravan(mob/user, list/params)
	if(!can_deploy_caravan(user))
		return FALSE

	var/route_id = params["route_id"]
	if(!route_id)
		return FALSE

	var/datum/caravan_route/route
	for(var/datum/caravan_route/r in routes)
		if(r.id == route_id)
			route = r
			break

	if(!route)
		return FALSE

	if(route.status != NCR_ROUTE_STATUS_INACTIVE)
		return FALSE

	if(!route.start_turf)
		to_chat(user, span_warning("Route has no valid starting location."))
		return FALSE

	var/obj/vehicle/caravan/caravan = new(route.start_turf, route)
	caravan.manager = src

	active_caravans += caravan
	route.status = NCR_ROUTE_STATUS_ACTIVE
	route.active_caravan = caravan

	notify_caravan_departed(caravan)

	return TRUE

/datum/caravan_manager/proc/sign_up_escort(mob/user, list/params)
	var/route_id = params["route_id"]
	if(!route_id)
		return FALSE

	for(var/datum/caravan_route/route as anything in routes)
		if(route.id == route_id && route.active_caravan)
			var/obj/vehicle/caravan/caravan = route.active_caravan
			if(caravan.is_guard(user.ckey))
				return FALSE
			if(caravan.guards.len >= NCR_CARAVAN_MAX_GUARDS)
				to_chat(user, span_warning("This caravan has maximum guards."))
				return FALSE
			caravan.add_guard(user.ckey)
			to_chat(user, span_notice("You are now escorting caravan on [route.name]. Stay close to protect it!"))
			return TRUE

	return FALSE

/datum/caravan_manager/proc/cancel_escort(mob/user, list/params)
	for(var/obj/vehicle/caravan/caravan as anything in active_caravans)
		if(caravan.is_guard(user.ckey))
			caravan.remove_guard(user.ckey)
			to_chat(user, span_notice("You are no longer escorting that caravan."))
			return TRUE
	return FALSE

/datum/caravan_manager/proc/recall_caravan(mob/user, list/params)
	if(!is_quartermaster(user))
		return FALSE

	var/caravan_id = params["caravan_id"]
	if(!caravan_id)
		return FALSE

	for(var/obj/vehicle/caravan/caravan as anything in active_caravans)
		if(caravan.id == caravan_id)
			caravan.recall()
			return TRUE

	return FALSE

/datum/caravan_manager/proc/caravan_arrived(obj/vehicle/caravan/caravan)
	stats["runs_today"]++
	stats["revenue"] += caravan.caps_earned
	stats["supplies_delivered"] += caravan.supplies_delivered

	var/list/nearby_guards = list()
	for(var/guard_ckey in caravan.guards)
		var/mob/guard = get_mob_by_ckey(guard_ckey)
		if(guard && get_dist(guard, caravan) <= 7)
			nearby_guards += guard
			var/obj/item/stack/f13Cash/caps/caps = new(get_turf(guard))
			caps.amount = min(caravan.guard_reward, 50)
			guard.put_in_hands(caps)
			to_chat(guard, span_notice("Caravan arrived safely! You earned [caravan.guard_reward] caps."))
			adjust_faction_reputation(guard_ckey, "ncr", 2)
		else if(guard)
			to_chat(guard, span_warning("You were too far from the caravan to receive rewards!"))

	caravan.route.status = NCR_ROUTE_STATUS_INACTIVE
	caravan.route.active_caravan = null
	active_caravans -= caravan

	qdel(caravan)

/datum/caravan_manager/proc/caravan_destroyed(obj/vehicle/caravan/caravan)
	stats["losses"]++

	for(var/guard_ckey in caravan.guards)
		var/mob/guard = get_mob_by_ckey(guard_ckey)
		if(guard)
			to_chat(guard, span_warning("The caravan was destroyed!"))

	caravan.route.status = NCR_ROUTE_STATUS_DAMAGED
	caravan.route.active_caravan = null
	active_caravans -= caravan

/obj/vehicle/caravan/Destroy()
	if(manager && (src in manager.active_caravans))
		manager.active_caravans -= src
	return ..()

/datum/caravan_manager/proc/notify_caravan_departed(obj/vehicle/caravan/caravan)
	for(var/mob/M in GLOB.player_list)
		if(M.client && M.mind && M.mind.assigned_role == "NCR Quartermaster")
			to_chat(M, span_notice("Caravan departed on [caravan.route.name]."))

/datum/caravan_manager/proc/notify_caravan_ambush(obj/vehicle/caravan/caravan)
	for(var/mob/M in GLOB.player_list)
		if(M.client && M.mind && (M.mind.assigned_role in list("NCR Quartermaster", "NCR Captain", "NCR Lieutenant")))
			to_chat(M, span_alert("CARAVAN ALERT: [caravan.route.name] is under attack at [get_area_name(caravan)]!"))

// ============ CARAVAN ROUTE ============

/datum/caravan_route
	var/id
	var/name
	var/description
	var/danger_level = 1
	var/min_guards = 0
	var/caps_per_run = 100
	var/supplies_per_run = 50
	var/status = NCR_ROUTE_STATUS_INACTIVE
	var/obj/vehicle/caravan/active_caravan

	var/turf/start_turf
	var/turf/end_turf
	var/list/waypoint_turfs = list()

/datum/caravan_route/proc/get_ui_data()
	return list(
		"id" = id,
		"name" = name,
		"description" = description,
		"danger_level" = danger_level,
		"min_guards" = min_guards,
		"caps_per_run" = caps_per_run,
		"supplies_per_run" = supplies_per_run,
		"status" = status,
		"active_caravan" = active_caravan ? active_caravan.id : null,
	)

/datum/caravan_route/proc/setup_waypoints()
	return FALSE

/datum/caravan_route/alpha
	id = "route_alpha"
	name = "Route Alpha: NCR HQ to Primm"
	description = "Supply route between NCR Headquarters and Primm."
	danger_level = 2
	min_guards = 1
	caps_per_run = 100
	supplies_per_run = 50

/datum/caravan_route/bravo
	id = "route_bravo"
	name = "Route Bravo: NCR HQ to Novac"
	description = "Long supply route through dangerous territory."
	danger_level = 3
	min_guards = 2
	caps_per_run = 150
	supplies_per_run = 75

/datum/caravan_route/charlie
	id = "route_charlie"
	name = "Route Charlie: Primm to Freeside"
	description = "High-risk route through raider territory."
	danger_level = 4
	min_guards = 2
	caps_per_run = 200
	supplies_per_run = 100

/datum/caravan_route/delta
	id = "route_delta"
	name = "Route Delta: NCR HQ to Hoover Dam"
	description = "Critical supply route to the front lines."
	danger_level = 5
	min_guards = 3
	caps_per_run = 300
	supplies_per_run = 150

// ============ CARAVAN WAYPOINTS ============

/obj/effect/caravan_waypoint
	name = "caravan waypoint"
	desc = "A waypoint for NCR caravan routes."
	icon = 'icons/obj/computer.dmi'
	icon_state = "station_marker"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = POINT_LAYER

	var/route_id
	var/is_start = FALSE
	var/is_end = FALSE

/obj/effect/caravan_waypoint/Initialize()
	. = ..()
	register_waypoint()

/obj/effect/caravan_waypoint/Destroy()
	unregister_waypoint()
	return ..()

/obj/effect/caravan_waypoint/proc/register_waypoint()
	if(!GLOB.ncr_routes || !GLOB.ncr_routes.len)
		return
	for(var/datum/caravan_route/route in GLOB.ncr_routes)
		if(route.id == route_id)
			if(is_start)
				route.start_turf = get_turf(src)
			if(is_end)
				route.end_turf = get_turf(src)
			break

/obj/effect/caravan_waypoint/proc/unregister_waypoint()
	for(var/datum/caravan_route/route in GLOB.ncr_routes)
		if(route.id == route_id)
			if(is_start && route.start_turf == get_turf(src))
				route.start_turf = null
			if(is_end && route.end_turf == get_turf(src))
				route.end_turf = null
			break

/obj/effect/caravan_waypoint/alpha_start
	name = "Route Alpha Start"
	route_id = "route_alpha"
	is_start = TRUE

/obj/effect/caravan_waypoint/alpha_end
	name = "Route Alpha End"
	route_id = "route_alpha"
	is_end = TRUE

/obj/effect/caravan_waypoint/bravo_start
	name = "Route Bravo Start"
	route_id = "route_bravo"
	is_start = TRUE

/obj/effect/caravan_waypoint/bravo_end
	name = "Route Bravo End"
	route_id = "route_bravo"
	is_end = TRUE

/obj/effect/caravan_waypoint/charlie_start
	name = "Route Charlie Start"
	route_id = "route_charlie"
	is_start = TRUE

/obj/effect/caravan_waypoint/charlie_end
	name = "Route Charlie End"
	route_id = "route_charlie"
	is_end = TRUE

/obj/effect/caravan_waypoint/delta_start
	name = "Route Delta Start"
	route_id = "route_delta"
	is_start = TRUE

/obj/effect/caravan_waypoint/delta_end
	name = "Route Delta End"
	route_id = "route_delta"
	is_end = TRUE

// ============ PHYSICAL CARAVAN ============

/obj/vehicle/caravan
	name = "NCR Supply Caravan"
	desc = "A pack brahmin carrying NCR supplies. Protect it from raiders!"
	icon = 'icons/obj/computer.dmi'
	icon_state = "oldpack"
	max_integrity = 200
	armor = list("melee" = 20, "bullet" = 20, "laser" = 10, "energy" = 10, "bomb" = 10, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 50)
	density = TRUE
	anchored = FALSE
	movedelay = 4
	pass_flags = PASSTABLE

	var/id
	var/datum/caravan_route/route
	var/datum/caravan_manager/manager

	var/status = NCR_CARAVAN_STATUS_DOCKED
	var/list/guards = list()

	var/caps_earned = 100
	var/supplies_delivered = 50
	var/guard_reward = 50

	var/current_waypoint = 1
	var/movement_timer
	var/ambush_timer
	var/ambush_cooldown = 0
	var/last_ambush_time = 0

	var/ambush_triggered = FALSE

/obj/vehicle/caravan/Initialize(mapload, datum/caravan_route/caravan_route)
	. = ..()
	if(caravan_route)
		route = caravan_route
		route.active_caravan = src
		caps_earned = route.caps_per_run
		supplies_delivered = route.supplies_per_run
		guard_reward = round(route.caps_per_run / 2)

	id = "caravan_[rand(1000, 9999)]"
	name = "NCR Supply Caravan ([route ? route.name : "Unknown"])"

	START_PROCESSING(SSobj, src)

/obj/vehicle/caravan/Destroy()
	STOP_PROCESSING(SSobj, src)
	deltimer(movement_timer)
	deltimer(ambush_timer)
	if(route)
		route.active_caravan = null
	return ..()

/obj/vehicle/caravan/examine(mob/user)
	. = ..()
	. += span_notice("Route: [route ? route.name : "Unknown"]")
	. += span_notice("Guards: [guards.len]/[NCR_CARAVAN_MAX_GUARDS]")
	. += span_notice("Integrity: [obj_integrity]/[max_integrity]")
	if(status == NCR_CARAVAN_STATUS_TRAVELING)
		. += span_notice("Status: Traveling to destination")

/obj/vehicle/caravan/proc/depart()
	status = NCR_CARAVAN_STATUS_TRAVELING
	current_waypoint = 1

	begin_travel()

/obj/vehicle/caravan/proc/begin_travel()
	if(!route || !route.end_turf)
		return

	if(get_dist(src, route.end_turf) <= 3)
		arrive()
		return

	step_to_destination()

/obj/vehicle/caravan/proc/step_to_destination()
	if(status != NCR_CARAVAN_STATUS_TRAVELING)
		return

	if(!route.end_turf)
		return

	if(get_dist(src, route.end_turf) <= 3)
		arrive()
		return

	var/direction = get_dir(src, route.end_turf)
	var/turf/target = get_step(src, direction)

	if(target && !target.density)
		Move(target, direction)

	check_ambush()

	movement_timer = addtimer(CALLBACK(src, PROC_REF(step_to_destination)), 2 SECONDS, TIMER_STOPPABLE)

/obj/vehicle/caravan/proc/check_ambush()
	if(ambush_triggered)
		return

	if(world.time < last_ambush_time + 1 MINUTES)
		return

	var/ambush_chance = route.danger_level * 3

	var/nearby_guards = 0
	for(var/guard_ckey in guards)
		var/mob/guard = get_mob_by_ckey(guard_ckey)
		if(guard && get_dist(guard, src) <= 5)
			nearby_guards++

	ambush_chance -= nearby_guards * 5
	ambush_chance = max(0, ambush_chance)

	if(prob(ambush_chance))
		trigger_ambush()

/obj/vehicle/caravan/proc/trigger_ambush()
	if(ambush_triggered)
		return

	ambush_triggered = TRUE
	last_ambush_time = world.time
	status = NCR_CARAVAN_STATUS_UNDER_ATTACK

	deltimer(movement_timer)

	if(manager)
		manager.notify_caravan_ambush(src)

	for(var/guard_ckey in guards)
		var/mob/guard = get_mob_by_ckey(guard_ckey)
		if(guard)
			to_chat(guard, span_userdanger("THE CARAVAN IS UNDER ATTACK!"))

	var/num_attackers = rand(2, 3 + route.danger_level)
	spawn_ambushers(num_attackers)

	ambush_timer = addtimer(CALLBACK(src, PROC_REF(resume_after_ambush)), 45 SECONDS, TIMER_STOPPABLE)

/obj/vehicle/caravan/proc/spawn_ambushers(count)
	var/list/spawn_turfs = list()
	for(var/turf/T in range(7, src))
		if(!T.density && !is_blocked_turf(T))
			spawn_turfs += T

	if(!spawn_turfs.len)
		return

	for(var/i in 1 to min(count, spawn_turfs.len))
		var/turf/spawn_loc = pick(spawn_turfs)
		spawn_turfs -= spawn_loc

		var/mob/living/carbon/human/ambusher
		if(prob(60))
			ambusher = new /mob/living/carbon/human(spawn_loc)
			randomize_human(ambusher)
			ambusher.equip_to_slot_or_del(new /obj/item/clothing/under/f13/raider_leather, SLOT_W_UNIFORM)
			ambusher.equip_to_slot_or_del(new /obj/item/gun/ballistic/automatic/pistol/n99, SLOT_BELT)
			ambusher.put_in_hands(new /obj/item/ammo_box/magazine/m10mm)
		else
			ambusher = new /mob/living/carbon/human(spawn_loc)
			randomize_human(ambusher)
			ambusher.equip_to_slot_or_del(new /obj/item/clothing/under/f13/legskirt, SLOT_W_UNIFORM)
			ambusher.equip_to_slot_or_del(new /obj/item/clothing/suit/armor/legion/recruit, SLOT_WEAR_SUIT)
			ambusher.equip_to_slot_or_del(new /obj/item/melee/onehanded/machete, SLOT_BELT)

		ambusher.faction = list("raider")

		for(var/guard_ckey in guards)
			var/mob/guard = get_mob_by_ckey(guard_ckey)
			if(guard)
				ambusher.a_intent = INTENT_HARM
				break

/obj/vehicle/caravan/proc/resume_after_ambush()
	ambush_triggered = FALSE
	status = NCR_CARAVAN_STATUS_TRAVELING
	begin_travel()

/obj/vehicle/caravan/proc/arrive()
	deltimer(movement_timer)
	deltimer(ambush_timer)

	if(status == NCR_CARAVAN_STATUS_UNDER_ATTACK)
		addtimer(CALLBACK(src, PROC_REF(arrive)), 5 SECONDS)
		return

	status = NCR_CARAVAN_STATUS_ARRIVED

	if(manager)
		manager.caravan_arrived(src)

/obj/vehicle/caravan/proc/recall()
	deltimer(movement_timer)
	deltimer(ambush_timer)

	status = NCR_CARAVAN_STATUS_DOCKED

	if(manager)
		route.status = NCR_ROUTE_STATUS_INACTIVE
		route.active_caravan = null
		manager.active_caravans -= src

	qdel(src)

/obj/vehicle/caravan/take_damage(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration = 0, atom/attacked_by)
	. = ..()

	if(obj_integrity <= 0)
		destroy_caravan()

/obj/vehicle/caravan/proc/destroy_caravan()
	if(manager)
		manager.caravan_destroyed(src)

	visible_message(span_warning("[src] is destroyed!"))

	for(var/guard_ckey in guards)
		var/mob/guard = get_mob_by_ckey(guard_ckey)
		if(guard)
			to_chat(guard, span_warning("The caravan you were escorting has been destroyed!"))

	qdel(src)

/obj/vehicle/caravan/proc/add_guard(guard_ckey)
	if(guards.len >= NCR_CARAVAN_MAX_GUARDS)
		return FALSE
	guards += guard_ckey
	return TRUE

/obj/vehicle/caravan/proc/remove_guard(guard_ckey)
	guards -= guard_ckey

/obj/vehicle/caravan/proc/is_guard(guard_ckey)
	return guard_ckey in guards

/obj/vehicle/caravan/proc/get_ui_data()
	return list(
		"id" = id,
		"name" = name,
		"route_id" = route ? route.id : "",
		"route_name" = route ? route.name : "Unknown",
		"status" = status,
		"progress" = get_progress_percent(),
		"guards" = guards,
		"caps_earned" = caps_earned,
		"supplies_delivered" = supplies_delivered,
		"integrity" = obj_integrity,
		"max_integrity" = max_integrity,
	)

/obj/vehicle/caravan/proc/get_progress_percent()
	if(!route || !route.start_turf || !route.end_turf)
		return 0

	var/start_dist = get_dist(route.start_turf, route.end_turf)
	var/current_dist = get_dist(src, route.end_turf)

	if(start_dist == 0)
		return 100

	return round(100 - ((current_dist / start_dist) * 100), 1)
