// Courier Delivery Mission System
// Non-faction players can deliver packages for caps

GLOBAL_LIST_EMPTY(courier_missions)
GLOBAL_LIST_EMPTY(active_couriers)
GLOBAL_LIST_EMPTY(courier_packages)

#define PACKAGE_FRAGILE 1
#define PACKAGE_VALUABLE 2
#define PACKAGE_DANGEROUS 4
#define PACKAGE_TIME_SENSITIVE 8

// ============ COURIER PACKAGE ============

/obj/item/courier_package
	name = "delivery package"
	desc = "A sealed package for delivery."
	icon = 'icons/obj/storage.dmi'
	icon_state = "deliverypackage"
	w_class = WEIGHT_CLASS_NORMAL
	var/package_id
	var/destination_name = "Unknown"
	var/destination_coords
	var/sender_name = "Anonymous"
	var/reward_caps = 50
	var/time_limit = 0
	var/bonus_for_speed = 0
	var/package_flags = 0
	var/delivery_started = 0
	var/picked_up = FALSE

/obj/item/courier_package/Initialize()
	. = ..()
	package_id = "pkg_[world.time]_[rand(1000, 9999)]"
	GLOB.courier_packages += src

/obj/item/courier_package/Destroy()
	GLOB.courier_packages -= src
	return ..()

/obj/item/courier_package/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Destination: [destination_name]</span>"
	. += "<span class='notice'>Sender: [sender_name]</span>"
	. += "<span class='notice'>Reward: [reward_caps] caps</span>"
	if(time_limit > 0)
		var/time_remaining = max(0, time_limit - (world.time - delivery_started))
		. += "<span class='warning'>Time remaining: [round(time_remaining / 600, 0.1)] minutes</span>"
	if(package_flags & PACKAGE_FRAGILE)
		. += "<span class='warning'>FRAGILE - Handle with care!</span>"
	if(package_flags & PACKAGE_VALUABLE)
		. += "<span class='notice'>VALUABLE - High value contents.</span>"
	if(package_flags & PACKAGE_DANGEROUS)
		. += "<span class='danger'>DANGEROUS - Contents may be hazardous.</span>"

/obj/item/courier_package/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/weapon))
		if(!picked_up)
			to_chat(user, span_warning("This package is sealed and cannot be opened."))
		return
	return ..()

/obj/item/courier_package/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(package_flags & PACKAGE_FRAGILE)
		if(prob(30))
			visible_message(span_danger("[src] breaks open!"))
			handle_package_damage()
			qdel(src)

/obj/item/courier_package/proc/handle_package_damage()
	if(package_flags & PACKAGE_DANGEROUS)
		explosion(src, 0, 1, 2)
	else if(package_flags & PACKAGE_VALUABLE)
		reward_caps = max(0, reward_caps - 25)

// ============ COURIER MISSION ============

/datum/courier_mission
	var/mission_id
	var/name = "Delivery Mission"
	var/description = "Deliver a package to its destination."
	var/pickup_location = "Post Office"
	var/pickup_coords
	var/destination_name = "Unknown"
	var/destination_coords
	var/reward_caps = 50
	var/bonus_caps = 0
	var/time_limit = 0
	var/status = "available"
	var/assigned_to = null
	var/created_time = 0
	var/started_time = 0
	var/completed_time = 0
	var/package_flags = 0
	var/obj/item/courier_package/package

	var/static/next_id = 1

/datum/courier_mission/New()
	mission_id = "courier_[next_id++]"
	created_time = world.time

/datum/courier_mission/proc/get_ui_data()
	return list(
		"mission_id" = mission_id,
		"name" = name,
		"description" = description,
		"pickup_location" = pickup_location,
		"destination_name" = destination_name,
		"reward_caps" = reward_caps,
		"bonus_caps" = bonus_caps,
		"time_limit" = time_limit,
		"status" = status,
		"assigned_to" = assigned_to,
		"package_flags" = package_flags,
		"is_fragile" = (package_flags & PACKAGE_FRAGILE) ? TRUE : FALSE,
		"is_valuable" = (package_flags & PACKAGE_VALUABLE) ? TRUE : FALSE,
		"is_dangerous" = (package_flags & PACKAGE_DANGEROUS) ? TRUE : FALSE,
		"is_time_sensitive" = (package_flags & PACKAGE_TIME_SENSITIVE) ? TRUE : FALSE,
	)

/datum/courier_mission/proc/create_package()
	package = new /obj/item/courier_package()
	package.package_id = mission_id
	package.destination_name = destination_name
	package.destination_coords = destination_coords
	package.sender_name = "Courier Service"
	package.reward_caps = reward_caps
	package.time_limit = time_limit
	package.package_flags = package_flags
	return package

/datum/courier_mission/proc/accept(mob/user)
	if(status != "available")
		return FALSE

	if(GLOB.active_couriers[user.ckey])
		to_chat(user, span_warning("You already have an active delivery."))
		return FALSE

	status = "active"
	assigned_to = user.ckey
	started_time = world.time
	GLOB.active_couriers[user.ckey] = mission_id

	create_package()

	var/turf/pickup_turf = locate(pickup_coords[1], pickup_coords[2], pickup_coords[3])
	if(pickup_turf)
		package.loc = pickup_turf

	to_chat(user, span_notice("Mission accepted: [name]"))
	to_chat(user, span_notice("Pick up the package at: [pickup_location]"))
	return TRUE

/datum/courier_mission/proc/complete(mob/user, obj/item/courier_package/delivered_package)
	if(status != "active")
		return FALSE

	if(assigned_to != user.ckey)
		return FALSE

	status = "completed"
	completed_time = world.time
	GLOB.active_couriers -= user.ckey

	var/total_reward = reward_caps + bonus_caps

	if(time_limit > 0)
		var/time_taken = world.time - started_time
		if(time_taken < time_limit * 0.5)
			bonus_caps += reward_caps * 0.5
			total_reward += bonus_caps
			to_chat(user, span_notice("Speed bonus! Extra [bonus_caps] caps!"))

	var/mob/living/carbon/human/H = user
	if(istype(H))
		var/obj/item/stack/f13Cash/caps = new /obj/item/stack/f13Cash/caps(get_turf(H), total_reward)
		H.put_in_hands(caps)

	qdel(delivered_package)
	to_chat(user, span_notice("Delivery completed! You received [total_reward] caps."))
	return TRUE

/datum/courier_mission/proc/fail()
	status = "failed"
	GLOB.active_couriers -= assigned_to
	if(package)
		qdel(package)

/datum/courier_mission/proc/check_timeout()
	if(time_limit > 0 && status == "active")
		if(world.time > started_time + time_limit)
			fail()
			return TRUE
	return FALSE

// ============ MISSION TYPES ============

/datum/courier_mission/standard
	name = "Standard Delivery"
	description = "Deliver a package safely to its destination."
	reward_caps = 50
	time_limit = 0

/datum/courier_mission/express
	name = "Express Delivery"
	description = "Time-sensitive delivery. Deliver quickly for bonus pay!"
	reward_caps = 75
	time_limit = 15 MINUTES
	bonus_caps = 50
	package_flags = PACKAGE_TIME_SENSITIVE

/datum/courier_mission/fragile
	name = "Fragile Delivery"
	description = "Handle with extreme care. Fragile contents."
	reward_caps = 100
	package_flags = PACKAGE_FRAGILE

/datum/courier_mission/valuable
	name = "Valuable Cargo"
	description = "High-value contents. Protect at all costs."
	reward_caps = 150
	package_flags = PACKAGE_VALUABLE

/datum/courier_mission/dangerous
	name = "Hazardous Materials"
	description = "Contains dangerous materials. Handle with caution."
	reward_caps = 200
	package_flags = PACKAGE_DANGEROUS

/datum/courier_mission/long_distance
	name = "Long Haul"
	description = "Long distance delivery. Good pay for the journey."
	reward_caps = 250
	time_limit = 45 MINUTES

// ============ COURIER TERMINAL ============

/obj/machinery/courier_terminal
	name = "Courier Terminal"
	desc = "A terminal for accepting delivery missions."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/courier_terminal/Initialize()
	. = ..()
	generate_missions()

/obj/machinery/courier_terminal/proc/generate_missions()
	if(GLOB.courier_missions.len > 0)
		return

	var/list/mission_types = list(
		/datum/courier_mission/standard,
		/datum/courier_mission/express,
		/datum/courier_mission/fragile,
		/datum/courier_mission/valuable,
		/datum/courier_mission/dangerous,
		/datum/courier_mission/long_distance,
	)

	for(var/i = 1 to 4)
		var/mission_type = pick(mission_types)
		var/datum/courier_mission/mission = new mission_type()
		mission.pickup_location = pick("Eastwood", "Primm", "Novac", "Freeside", "Goodsprings")
		mission.destination_name = pick("NCR Outpost", "Bunker Hill", "Quarry Junction", "Jacobstown", "Nellis")
		GLOB.courier_missions += mission

/obj/machinery/courier_terminal/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/courier_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CourierTerminal")
		ui.open()

/obj/machinery/courier_terminal/ui_data(mob/user)
	var/list/available_missions = list()
	var/list/active_mission = null

	for(var/datum/courier_mission/mission as anything in GLOB.courier_missions)
		if(mission.status == "available")
			available_missions += list(mission.get_ui_data())
		if(mission.assigned_to == user.ckey && mission.status == "active")
			active_mission = mission.get_ui_data()

	return list(
		"available_missions" = available_missions,
		"active_mission" = active_mission,
		"can_take_mission" = can_take_mission(user),
		"courier_reputation" = get_courier_reputation(user.ckey),
	)

/obj/machinery/courier_terminal/proc/get_courier_reputation(ckey)
	return 0

/obj/machinery/courier_terminal/proc/can_take_mission(mob/user)
	if(GLOB.active_couriers[user.ckey])
		return FALSE
	return TRUE

/obj/machinery/courier_terminal/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("accept_mission")
			var/mission_id = params["mission_id"]
			for(var/datum/courier_mission/mission as anything in GLOB.courier_missions)
				if(mission.mission_id == mission_id)
					return mission.accept(usr)
			return FALSE

		if("abandon_mission")
			var/mission_id = params["mission_id"]
			for(var/datum/courier_mission/mission as anything in GLOB.courier_missions)
				if(mission.mission_id == mission_id && mission.assigned_to == usr.ckey)
					mission.fail()
					to_chat(usr, span_warning("Mission abandoned. Your reputation may suffer."))
					return TRUE
			return FALSE

		if("refresh_missions")
			generate_missions()
			return TRUE

	return FALSE

// ============ DELIVERY POINT ============

/obj/structure/delivery_point
	name = "delivery drop-off"
	desc = "A designated location for package deliveries."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "delivery"
	anchored = TRUE
	density = FALSE
	var/location_name = "Delivery Point"

/obj/structure/delivery_point/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/courier_package))
		var/obj/item/courier_package/package = I
		handle_delivery(user, package)
		return TRUE
	return ..()

/obj/structure/delivery_point/proc/handle_delivery(mob/user, obj/item/courier_package/package)
	for(var/datum/courier_mission/mission as anything in GLOB.courier_missions)
		if(mission.package_id == package.package_id && mission.assigned_to == user.ckey)
			if(mission.destination_name == location_name || mission.destination_name == "Unknown")
				mission.complete(user, package)
				return

	to_chat(user, span_warning("This package doesn't belong here."))

// ============ COURIER JOB HELPERS ============

/proc/get_active_courier_mission(ckey)
	return GLOB.courier_missions[GLOB.active_couriers[ckey]]
