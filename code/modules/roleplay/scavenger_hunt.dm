// Scavenger Hunt System
// Players search for hidden items across the wasteland for rewards

GLOBAL_LIST_EMPTY(scavenger_hunts)
GLOBAL_LIST_EMPTY(active_scavengers)
GLOBAL_LIST_EMPTY(scavenger_items)

// ============ SCAVENGER HUNT ============

/datum/scavenger_hunt
	var/hunt_id
	var/name = "Scavenger Hunt"
	var/description = "Find hidden items across the wasteland."
	var/reward_caps = 100
	var/reward_item
	var/time_limit = 0
	var/status = "available"
	var/created_time = 0
	var/started_time = 0
	var/completed_time = 0
	var/list/required_items = list()
	var/found_items = 0
	var/difficulty = 1
	var/assigned_to = null
	var/hint = ""

	var/static/next_id = 1

/datum/scavenger_hunt/New()
	hunt_id = "hunt_[next_id++]"
	created_time = world.time

/datum/scavenger_hunt/proc/get_ui_data()
	return list(
		"hunt_id" = hunt_id,
		"name" = name,
		"description" = description,
		"reward_caps" = reward_caps,
		"reward_item" = reward_item,
		"time_limit" = time_limit,
		"status" = status,
		"required_items" = required_items.len,
		"found_items" = found_items,
		"difficulty" = difficulty,
		"hint" = hint,
	)

/datum/scavenger_hunt/proc/generate_items()
	var/list/area/area_list = get_areas(/area/f13)

	if(!area_list.len)
		return

	var/list/item_types = list(
		/obj/item/scavenger_token/common,
		/obj/item/scavenger_token/uncommon,
		/obj/item/scavenger_token/rare,
	)

	var/num_items = min(required_items.len, 5)
	for(var/i = 1 to num_items)
		var/area/spawn_area = pick(area_list)
		var/list/turfs = get_area_turfs(spawn_area.type)
		if(!turfs.len)
			continue

		var/list/valid_turfs = list()
		for(var/turf/T in turfs)
			if(!T.density && !istype(T, /turf/open/space))
				valid_turfs += T
		if(!valid_turfs.len)
			continue

		var/turf/spawn_turf = pick(valid_turfs)
		var/item_type = pick(item_types)
		var/obj/item/scavenger_token/token = new item_type(spawn_turf)
		token.hunt_id = hunt_id
		token.item_index = i
		GLOB.scavenger_items += token

/datum/scavenger_hunt/proc/start(mob/user)
	if(status != "available")
		return FALSE

	if(GLOB.active_scavengers[user.ckey])
		to_chat(user, span_warning("You already have an active scavenger hunt."))
		return FALSE

	status = "active"
	assigned_to = user.ckey
	started_time = world.time
	GLOB.active_scavengers[user.ckey] = hunt_id

	generate_items()

	to_chat(user, span_notice("Scavenger hunt started: [name]"))
	to_chat(user, span_notice("Find [required_items.len] hidden items!"))
	if(hint)
		to_chat(user, span_notice("Hint: [hint]"))
	return TRUE

/datum/scavenger_hunt/proc/found_item(mob/user, obj/item/scavenger_token/token)
	if(status != "active")
		return FALSE

	if(assigned_to != user.ckey)
		return FALSE

	found_items++
	GLOB.scavenger_items -= token

	to_chat(user, span_notice("Item found! [found_items]/[required_items.len]"))

	if(found_items >= required_items.len)
		complete(user)

	return TRUE

/datum/scavenger_hunt/proc/complete(mob/user)
	if(status != "active")
		return FALSE

	status = "completed"
	completed_time = world.time
	GLOB.active_scavengers -= user.ckey

	var/mob/living/carbon/human/H = user
	if(istype(H))
		var/obj/item/stack/f13Cash/caps = new /obj/item/stack/f13Cash/caps(get_turf(H), reward_caps)
		H.put_in_hands(caps)

		if(reward_item)
			var/obj/item/reward = new reward_item(get_turf(H))
			H.put_in_hands(reward)

	to_chat(user, span_notice("Scavenger hunt completed! You received [reward_caps] caps!"))
	return TRUE

/datum/scavenger_hunt/proc/fail()
	status = "failed"
	GLOB.active_scavengers -= assigned_to
	for(var/obj/item/scavenger_token/token as anything in GLOB.scavenger_items)
		if(token.hunt_id == hunt_id)
			qdel(token)

/datum/scavenger_hunt/proc/check_timeout()
	if(time_limit > 0 && status == "active")
		if(world.time > started_time + time_limit)
			fail()
			return TRUE
	return FALSE

// ============ HUNT TYPES ============

/datum/scavenger_hunt/easy
	name = "Wasteland Treasure Hunt"
	description = "Find hidden tokens scattered nearby."
	reward_caps = 75
	difficulty = 1
	required_items = list("token", "token", "token")
	time_limit = 20 MINUTES
	hint = "Check around buildings and ruins."

/datum/scavenger_hunt/medium
	name = "Relic Recovery"
	description = "Locate scattered pre-war artifacts."
	reward_caps = 150
	difficulty = 2
	required_items = list("token", "token", "token", "token", "token")
	time_limit = 30 MINUTES
	hint = "Search abandoned structures carefully."

/datum/scavenger_hunt/hard
	name = "Hidden Cache Hunt"
	description = "Find a well-hidden collection of valuable items."
	reward_caps = 300
	reward_item = /obj/item/gun/energy/laser/pistol
	difficulty = 3
	required_items = list("token", "token", "token", "token")
	time_limit = 45 MINUTES
	hint = "The items are scattered across dangerous territory."

/datum/scavenger_hunt/endless
	name = "Endless Scavenging"
	description = "Keep finding items until you decide to stop."
	reward_caps = 50
	difficulty = 1
	required_items = list("token", "token")
	time_limit = 0
	hint = "Items respawn over time. How many can you find?"

// ============ SCAVENGER TOKEN ============

/obj/item/scavenger_token
	name = "scavenger token"
	desc = "A token marked with a symbol. Someone might be looking for these."
	icon = 'icons/obj/objects.dmi'
	icon_state = "scavenger_token"
	w_class = WEIGHT_CLASS_TINY
	var/hunt_id
	var/item_index = 0
	var/rarity = "common"

/obj/item/scavenger_token/common
	name = "common scavenger token"
	icon_state = "scavenger_token_common"
	rarity = "common"

/obj/item/scavenger_token/uncommon
	name = "uncommon scavenger token"
	icon_state = "scavenger_token_uncommon"
	rarity = "uncommon"

/obj/item/scavenger_token/rare
	name = "rare scavenger token"
	icon_state = "scavenger_token_rare"
	rarity = "rare"

/obj/item/scavenger_token/pickup(mob/user)
	..()
	if(hunt_id)
		for(var/datum/scavenger_hunt/hunt as anything in GLOB.scavenger_hunts)
			if(hunt.hunt_id == hunt_id)
				hunt.found_item(user, src)
				return

/obj/item/scavenger_token/examine(mob/user)
	. = ..()
	if(hunt_id)
		. += "<span class='notice'>This token is part of a scavenger hunt.</span>"
	. += "<span class='notice'>Rarity: [rarity]</span>"

// ============ SCAVENGER TERMINAL ============

/obj/machinery/scavenger_terminal
	name = "Scavenger Terminal"
	desc = "A terminal for accepting scavenger hunts."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/scavenger_terminal/Initialize()
	. = ..()
	generate_hunts()

/obj/machinery/scavenger_terminal/proc/generate_hunts()
	if(GLOB.scavenger_hunts.len > 0)
		return

	var/list/hunt_types = list(
		/datum/scavenger_hunt/easy,
		/datum/scavenger_hunt/medium,
		/datum/scavenger_hunt/hard,
	)

	for(var/i = 1 to 3)
		var/hunt_type = pick(hunt_types)
		var/datum/scavenger_hunt/hunt = new hunt_type()
		GLOB.scavenger_hunts += hunt

/obj/machinery/scavenger_terminal/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/scavenger_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ScavengerTerminal")
		ui.open()

/obj/machinery/scavenger_terminal/ui_data(mob/user)
	var/list/available_hunts = list()
	var/list/active_hunt = null

	for(var/datum/scavenger_hunt/hunt as anything in GLOB.scavenger_hunts)
		if(hunt.status == "available")
			available_hunts += list(hunt.get_ui_data())
		if(hunt.assigned_to == user.ckey && hunt.status == "active")
			active_hunt = hunt.get_ui_data()

	return list(
		"available_hunts" = available_hunts,
		"active_hunt" = active_hunt,
		"can_start_hunt" = can_start_hunt(user),
		"total_found" = get_player_total_found(user.ckey),
	)

/obj/machinery/scavenger_terminal/proc/get_player_total_found(ckey)
	if(!ckey)
		return 0
	var/total = 0
	for(var/datum/scavenger_hunt/hunt as anything in GLOB.scavenger_hunts)
		if(hunt.assigned_to == ckey)
			total += hunt.found_items
	return total

/obj/machinery/scavenger_terminal/proc/can_start_hunt(mob/user)
	if(GLOB.active_scavengers[user.ckey])
		return FALSE
	return TRUE

/obj/machinery/scavenger_terminal/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("start_hunt")
			var/hunt_id = params["hunt_id"]
			for(var/datum/scavenger_hunt/hunt as anything in GLOB.scavenger_hunts)
				if(hunt.hunt_id == hunt_id)
					return hunt.start(usr)
			return FALSE

		if("abandon_hunt")
			var/hunt_id = params["hunt_id"]
			for(var/datum/scavenger_hunt/hunt as anything in GLOB.scavenger_hunts)
				if(hunt.hunt_id == hunt_id && hunt.assigned_to == usr.ckey)
					hunt.fail()
					to_chat(usr, span_warning("Hunt abandoned. Tokens disappear."))
					return TRUE
			return FALSE

		if("refresh_hunts")
			generate_hunts()
			return TRUE

	return FALSE

// ============ WORLD SPAWNER ============

/proc/spawn_random_scavenger_tokens()
	var/list/area/f13_areas = get_areas(/area/f13)
	if(!f13_areas.len)
		return
	var/list/valid_turfs = list()
	for(var/area/A in f13_areas)
		var/list/area_turfs = get_area_turfs(A.type)
		for(var/turf/T in area_turfs)
			if(!T.density && !istype(T, /turf/open/space))
				if(prob(1))
					valid_turfs += T

	for(var/i = 1 to min(valid_turfs.len, 10))
		var/turf/T = pick(valid_turfs)
		var/token_type = pick(
			/obj/item/scavenger_token/common,
			/obj/item/scavenger_token/uncommon,
			/obj/item/scavenger_token/rare,
		)
		new token_type(T)
