// Enclave Vertibird Control Console
// TGUI interface for vertibird operations

GLOBAL_LIST_EMPTY(active_beacons)
GLOBAL_LIST_EMPTY(enclave_vertibirds)

/obj/machinery/vertibird_control
	name = "Vertibird Control Console"
	desc = "A console for managing Enclave vertibird operations."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

	var/obj/vertibird/enclave/linked_vertibird
	var/mission_cooldown = 0

/obj/machinery/vertibird_control/Initialize()
	. = ..()
	find_vertibird()

/obj/machinery/vertibird_control/proc/find_vertibird()
	for(var/obj/vertibird/enclave/V in GLOB.enclave_vertibirds)
		linked_vertibird = V
		return
	linked_vertibird = new /obj/vertibird/enclave(loc)

/obj/machinery/vertibird_control/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/vertibird_control/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "VertibirdControl")
		ui.open()

/obj/machinery/vertibird_control/ui_data(mob/user)
	var/list/data = list()
	data["faction"] = "enclave"
	data["faction_name"] = "Enclave"

	if(!linked_vertibird)
		data["vertibird_status"] = "No vertibird linked"
		return data

	data["vertibird_status"] = linked_vertibird.status
	data["vertibird_fuel"] = linked_vertibird.fuel
	data["vertibird_max_fuel"] = VERTIBIRD_MAX_FUEL
	data["vertibird_health"] = linked_vertibird.health
	data["vertibird_max_health"] = VERTIBIRD_MAX_HEALTH
	data["minigun_ammo"] = linked_vertibird.ammo_minigun
	data["minigun_max"] = VERTIBIRD_MAX_AMMO_MINIGUN
	data["missiles"] = linked_vertibird.ammo_missiles
	data["missiles_max"] = VERTIBIRD_MAX_AMMO_MISSILES
	data["callsign"] = linked_vertibird.callsign
	data["in_mission"] = linked_vertibird.in_mission
	data["cooldown"] = max(0, round((mission_cooldown - world.time) / 10))

	var/list/destinations = list()
	for(var/obj/effect/landmark/vertibird/L in GLOB.vertibirdLandZone)
		destinations += list(list(
			"name" = L.name,
			"x" = L.x,
			"y" = L.y,
			"z" = L.z,
			"travel_time" = estimate_travel_time(L)
		))
	data["destinations"] = destinations

	var/list/beacons = list()
	for(var/obj/item/extraction_beacon/B in GLOB.active_beacons)
		beacons += list(list(
			"name" = B.name,
			"ckey" = B.activated_by,
			"x" = B.x,
			"y" = B.y,
			"z" = B.z
		))
	data["active_beacons"] = beacons

	return data

/obj/machinery/vertibird_control/proc/estimate_travel_time(obj/effect/landmark/vertibird/L)
	if(!linked_vertibird || !L)
		return 30
	var/dist = get_dist(linked_vertibird, L)
	return clamp(round(dist / 10), 20, 90)

/obj/machinery/vertibird_control/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	if(!linked_vertibird)
		return FALSE

	switch(action)
		if("transport")
			if(mission_cooldown > world.time)
				to_chat(usr, span_warning("Vertibird is on cooldown."))
				return FALSE
			if(linked_vertibird.in_mission)
				to_chat(usr, span_warning("Vertibird is already on a mission."))
				return FALSE
			if(linked_vertibird.fuel < VERTIBIRD_FUEL_TRANSPORT)
				to_chat(usr, span_warning("Insufficient fuel."))
				return FALSE

			var/target_x = text2num(params["x"])
			var/target_y = text2num(params["y"])
			var/target_z = text2num(params["z"])

			if(!target_x || !target_y || !target_z)
				return FALSE

			linked_vertibird.launch_transport(target_x, target_y, target_z)
			mission_cooldown = world.time + VERTIBIRD_MISSION_COOLDOWN
			return TRUE

		if("supply_drop")
			if(mission_cooldown > world.time)
				to_chat(usr, span_warning("Vertibird is on cooldown."))
				return FALSE
			if(linked_vertibird.in_mission)
				to_chat(usr, span_warning("Vertibird is already on a mission."))
				return FALSE
			if(linked_vertibird.fuel < VERTIBIRD_FUEL_SUPPLY_DROP)
				to_chat(usr, span_warning("Insufficient fuel."))
				return FALSE

			var/beacon_ref = params["beacon"]
			var/crate_type = params["crate_type"]

			if(!beacon_ref || !crate_type)
				return FALSE

			for(var/obj/item/extraction_beacon/B in GLOB.active_beacons)
				if("[REF(B)]" == beacon_ref)
					linked_vertibird.drop_supply(B.loc, crate_type)
					mission_cooldown = world.time + VERTIBIRD_MISSION_COOLDOWN
					return TRUE
			return FALSE

		if("extraction")
			if(mission_cooldown > world.time)
				to_chat(usr, span_warning("Vertibird is on cooldown."))
				return FALSE
			if(linked_vertibird.in_mission)
				to_chat(usr, span_warning("Vertibird is already on a mission."))
				return FALSE
			if(linked_vertibird.fuel < VERTIBIRD_FUEL_EXTRACTION)
				to_chat(usr, span_warning("Insufficient fuel."))
				return FALSE

			var/beacon_ref = params["beacon"]

			if(!beacon_ref)
				return FALSE

			for(var/obj/item/extraction_beacon/B in GLOB.active_beacons)
				if("[REF(B)]" == beacon_ref)
					linked_vertibird.launch_extraction(B.loc)
					mission_cooldown = world.time + VERTIBIRD_MISSION_COOLDOWN
					return TRUE
			return FALSE

		if("reload")
			find_vertibird()
			return TRUE

	return FALSE

// ============ ENCLAVE VERTIBIRD ============

/obj/vertibird/enclave
	name = "Enclave Vertibird"
	desc = "A pre-war vertical takeoff aircraft bearing Enclave markings."
	icon = 'icons/fallout/vehicles/vertibird.dmi'
	icon_state = "vb-static"

	var/callsign = "EV-101 \"Liberty\""
	var/status = VERTIBIRD_STATUS_STANDBY
	var/health = VERTIBIRD_MAX_HEALTH
	var/fuel = VERTIBIRD_MAX_FUEL
	var/ammo_minigun = VERTIBIRD_MAX_AMMO_MINIGUN
	var/ammo_missiles = VERTIBIRD_MAX_AMMO_MISSILES
	var/in_mission = FALSE

/obj/vertibird/enclave/Initialize()
	. = ..()
	GLOB.enclave_vertibirds += src

/obj/vertibird/enclave/Destroy()
	GLOB.enclave_vertibirds -= src
	return ..()

/obj/vertibird/enclave/proc/launch_transport(target_x, target_y, target_z)
	if(in_mission)
		return FALSE

	in_mission = TRUE
	status = VERTIBIRD_STATUS_FLYING
	fuel -= VERTIBIRD_FUEL_TRANSPORT

	visible_message(span_notice("[src] takes off!"))
	playsound(src, 'sound/f13machines/vertibird_start.ogg', 100)

	addtimer(CALLBACK(src, PROC_REF(arrive_transport), target_x, target_y, target_z), 30 SECONDS)

	return TRUE

/obj/vertibird/enclave/proc/arrive_transport(target_x, target_y, target_z)
	x = target_x
	y = target_y
	z = target_z

	playsound(src, 'sound/f13machines/vertibird_stop.ogg', 100)
	visible_message(span_notice("[src] lands at the destination."))

	in_mission = FALSE
	status = VERTIBIRD_STATUS_STANDBY

/obj/vertibird/enclave/proc/drop_supply(target_loc, crate_type)
	if(in_mission)
		return FALSE

	in_mission = TRUE
	status = VERTIBIRD_STATUS_FLYING
	fuel -= VERTIBIRD_FUEL_SUPPLY_DROP

	visible_message(span_notice("[src] takes off for supply drop!"))
	playsound(src, 'sound/f13machines/vertibird_start.ogg', 100)

	addtimer(CALLBACK(src, PROC_REF(deliver_supply), target_loc, crate_type), 20 SECONDS)

	return TRUE

/obj/vertibird/enclave/proc/deliver_supply(target_loc, crate_type)
	var/obj/structure/closet/crate/C = new /obj/structure/closet/crate(target_loc)

	switch(crate_type)
		if(SUPPLY_CRATE_AMMO)
			new /obj/item/ammo_box(C)
			new /obj/item/ammo_box(C)
			new /obj/item/ammo_box(C)
		if(SUPPLY_CRATE_MEDICAL)
			new /obj/item/reagent_containers/pill/patch/healpoultice(C)
			new /obj/item/reagent_containers/pill/patch/healpoultice(C)
			new /obj/item/reagent_containers/hypospray/medipen(C)
		if(SUPPLY_CRATE_EQUIPMENT)
			new /obj/item/clothing/suit/armor/medium/vest(C)
			new /obj/item/flashlight(C)
		if(SUPPLY_CRATE_EMERGENCY)
			new /obj/item/storage/box/ration(C)
			new /obj/item/reagent_containers/glass/bottle/water(C)

	playsound(target_loc, 'sound/effects/bang.ogg', 100)
	visible_message(span_notice("A supply crate drops from the sky!"))

	in_mission = FALSE
	status = VERTIBIRD_STATUS_STANDBY

/obj/vertibird/enclave/proc/launch_extraction(target_loc)
	if(in_mission)
		return FALSE

	in_mission = TRUE
	status = VERTIBIRD_STATUS_FLYING
	fuel -= VERTIBIRD_FUEL_EXTRACTION

	visible_message(span_notice("[src] takes off for extraction!"))
	playsound(src, 'sound/f13machines/vertibird_start.ogg', 100)

	addtimer(CALLBACK(src, PROC_REF(perform_extraction), target_loc), 30 SECONDS)

	return TRUE

/obj/vertibird/enclave/proc/perform_extraction(target_loc)
	var/turf/T = get_turf(target_loc)

	for(var/mob/living/carbon/human/H in range(3, T))
		if(H.stat == CONSCIOUS)
			H.forceMove(loc)
			to_chat(H, span_notice("You have been extracted by the vertibird!"))

	playsound(T, 'sound/f13machines/vertibird_stop.ogg', 100)
	visible_message(span_notice("[src] performs extraction and returns to base."))

	in_mission = FALSE
	status = VERTIBIRD_STATUS_STANDBY
