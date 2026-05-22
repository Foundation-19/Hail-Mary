// Safe House Claiming System
// Non-faction players can claim and customize personal safe houses

GLOBAL_LIST_EMPTY(safe_houses)
GLOBAL_LIST_EMPTY(player_houses)

#define HOUSE_TIER_1 1
#define HOUSE_TIER_2 2
#define HOUSE_TIER_3 3

#define HOUSE_LOCK_BASIC 1
#define HOUSE_LOCK_ADVANCED 2
#define HOUSE_LOCK_BIOMETRIC 3

// ============ SAFE HOUSE DATUM ============

/datum/safe_house
	var/house_id
	var/name = "Safe House"
	var/description = "A secure location to call home."
	var/tier = HOUSE_TIER_1
	var/owner_ckey = null
	var/owner_name = null
	var/list/authorized_users = list()
	var/rent_cost = 100
	var/rent_paid_until = 0
	var/claimed_time = 0
	var/list/furniture = list()
	var/list/storage = list()
	var/security_level = HOUSE_LOCK_BASIC
	var/list/amenities = list()
	var/location_name = "Unknown"
	var/area/house_area = null
	var/locked = TRUE
	var/alarm_active = FALSE
	var/list/upgrade_costs = list(
		"security" = 500,
		"storage" = 300,
		"furniture" = 200,
		"amenities" = 400,
	)

	var/static/next_id = 1

/datum/safe_house/New()
	house_id = "house_[next_id++]"

/datum/safe_house/proc/get_ui_data()
	return list(
		"house_id" = house_id,
		"name" = name,
		"description" = description,
		"tier" = tier,
		"owner_ckey" = owner_ckey,
		"owner_name" = owner_name,
		"authorized_users" = authorized_users,
		"rent_cost" = rent_cost,
		"rent_paid_until" = rent_paid_until,
		"claimed_time" = claimed_time,
		"security_level" = security_level,
		"amenities" = amenities,
		"location_name" = location_name,
		"locked" = locked,
		"alarm_active" = alarm_active,
		"upgrade_costs" = upgrade_costs,
		"is_owner" = TRUE,
	)

/datum/safe_house/proc/can_claim(mob/user)
	if(owner_ckey)
		return FALSE
	return TRUE

/datum/safe_house/proc/claim(mob/user)
	if(!can_claim(user))
		return FALSE

	owner_ckey = user.ckey
	owner_name = user.real_name
	claimed_time = world.time
	GLOB.player_houses[user.ckey] = house_id

	to_chat(user, span_notice("You have claimed [name]!"))
	to_chat(user, span_notice("Rent: [rent_cost] caps per week."))
	return TRUE

/datum/safe_house/proc/unclaim()
	owner_ckey = null
	owner_name = null
	authorized_users = list()
	rent_paid_until = 0
	claimed_time = 0
	locked = TRUE
	GLOB.player_houses -= owner_ckey

/datum/safe_house/proc/pay_rent(mob/user, weeks)
	if(owner_ckey != user.ckey)
		return FALSE

	var/mob/living/carbon/human/H = user
	if(!istype(H))
		return FALSE

	var/cost = rent_cost * weeks
	var/obj/item/stack/f13Cash/caps = H.get_item_by_slot(SLOT_L_STORE)
	if(!caps || caps.amount < cost)
		caps = H.get_item_by_slot(SLOT_R_STORE)
	if(!caps || caps.amount < cost)
		to_chat(user, span_warning("You need [cost] caps to pay rent."))
		return FALSE

	caps.use(cost)
	rent_paid_until = max(rent_paid_until, world.time) + (weeks * 7 DAYS)

	to_chat(user, span_notice("Rent paid for [weeks] week(s)."))
	return TRUE

/datum/safe_house/proc/add_authorized(user_ckey)
	if(!authorized_users[user_ckey])
		authorized_users += user_ckey
		return TRUE
	return FALSE

/datum/safe_house/proc/remove_authorized(user_ckey)
	authorized_users -= user_ckey
	return TRUE

/datum/safe_house/proc/upgrade_security(mob/user)
	if(security_level >= HOUSE_LOCK_BIOMETRIC)
		return FALSE

	var/mob/living/carbon/human/H = user
	if(!istype(H))
		return FALSE

	var/cost = upgrade_costs["security"]
	var/obj/item/stack/f13Cash/caps = H.get_item_by_slot(SLOT_L_STORE)
	if(!caps || caps.amount < cost)
		caps = H.get_item_by_slot(SLOT_R_STORE)
	if(!caps || caps.amount < cost)
		to_chat(user, span_warning("You need [cost] caps for this upgrade."))
		return FALSE

	caps.use(cost)
	security_level++

	to_chat(user, span_notice("Security upgraded to level [security_level]!"))
	return TRUE

/datum/safe_house/proc/toggle_lock(mob/user)
	if(owner_ckey != user.ckey && !(user.ckey in authorized_users))
		return FALSE

	locked = !locked
	to_chat(user, span_notice("Door [locked ? "locked" : "unlocked"]."))
	return TRUE

/datum/safe_house/proc/add_amenity(amenity_type, mob/user)
	var/mob/living/carbon/human/H = user
	if(!istype(H))
		return FALSE

	var/cost = upgrade_costs["amenities"]
	var/obj/item/stack/f13Cash/caps = H.get_item_by_slot(SLOT_L_STORE)
	if(!caps || caps.amount < cost)
		caps = H.get_item_by_slot(SLOT_R_STORE)
	if(!caps || caps.amount < cost)
		to_chat(user, span_warning("You need [cost] caps for this amenity."))
		return FALSE

	caps.use(cost)
	amenities += amenity_type

	to_chat(user, span_notice("Amenity added!"))
	return TRUE

/datum/safe_house/proc/check_rent()
	if(rent_paid_until > 0 && world.time > rent_paid_until)
		unclaim()
		return FALSE
	return TRUE

/datum/safe_house/proc/transfer_ownership(new_owner_ckey, mob/user)
	if(owner_ckey != user.ckey)
		return FALSE

	owner_ckey = new_owner_ckey
	GLOB.player_houses[new_owner_ckey] = house_id
	GLOB.player_houses -= user.ckey

	to_chat(user, span_notice("Ownership transferred."))
	return TRUE

// ============ SAFE HOUSE TYPES ============

/datum/safe_house/shack
	name = "Wasteland Shack"
	description = "A small, basic shelter."
	tier = HOUSE_TIER_1
	rent_cost = 50
	location_name = "Wasteland"

/datum/safe_house/apartment
	name = "Settlement Apartment"
	description = "A decent apartment in a settlement."
	tier = HOUSE_TIER_2
	rent_cost = 100
	location_name = "Eastwood"

/datum/safe_house/bunker
	name = "Pre-War Bunker"
	description = "A fortified underground bunker."
	tier = HOUSE_TIER_3
	rent_cost = 200
	security_level = HOUSE_LOCK_ADVANCED
	location_name = "Hidden"

/datum/safe_house/broadcast
	name = "Broadcast Tower"
	description = "An abandoned broadcast station."
	tier = HOUSE_TIER_2
	rent_cost = 150
	location_name = "Broadcast Tower"

/datum/safe_house/warehouse
	name = "Warehouse Loft"
	description = "A converted warehouse space."
	tier = HOUSE_TIER_2
	rent_cost = 125
	location_name = "Industrial District"

// ============ SAFE HOUSE DOOR ============

/obj/machinery/door/airlock/safe_house_door
	name = "reinforced door"
	desc = "A heavy door protecting a safe house."
	icon = 'icons/obj/doors/airlocks/station/station.dmi'
	icon_state = "closed"
	locked = TRUE
	var/datum/safe_house/house = null

/obj/machinery/door/airlock/safe_house_door/attack_hand(mob/user)
	if(house)
		if(house.locked)
			if(house.owner_ckey == user.ckey || (user.ckey in house.authorized_users))
				house.toggle_lock(user)
			else
				to_chat(user, span_warning("This door is locked."))
				return
	. = ..()

/obj/machinery/door/airlock/safe_house_door/attackby(obj/item/I, mob/user, params)
	if(house && istype(I, /obj/item/card/id))
		if(house.owner_ckey == user.ckey)
			house.toggle_lock(user)
			return
	. = ..()

// ============ SAFE HOUSE TERMINAL ============

/obj/machinery/safe_house_terminal
	name = "Safe House Terminal"
	desc = "Manage your safe house settings."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE
	var/datum/safe_house/linked_house = null

/obj/machinery/safe_house_terminal/Initialize()
	. = ..()
	if(!linked_house)
		linked_house = new /datum/safe_house/shack()
		GLOB.safe_houses += linked_house

/obj/machinery/safe_house_terminal/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/safe_house_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SafeHouseTerminal")
		ui.open()

/obj/machinery/safe_house_terminal/ui_data(mob/user)
	if(!linked_house)
		return list("error" = "No house linked")

	var/list/data = linked_house.get_ui_data()
	data["is_owner"] = (linked_house.owner_ckey == user.ckey)
	data["is_authorized"] = (user.ckey in linked_house.authorized_users) || data["is_owner"]
	data["can_claim"] = linked_house.can_claim(user)
	data["rent_days_remaining"] = max(0, round((linked_house.rent_paid_until - world.time) / (1 DAY)))

	return data

/obj/machinery/safe_house_terminal/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	if(!linked_house)
		return FALSE

	switch(action)
		if("claim_house")
			return linked_house.claim(usr)

		if("pay_rent")
			var/weeks = text2num(params["weeks"]) || 1
			return linked_house.pay_rent(usr, weeks)

		if("unclaim_house")
			if(linked_house.owner_ckey == usr.ckey)
				linked_house.unclaim()
				to_chat(usr, span_notice("You have released ownership of the house."))
				return TRUE
			return FALSE

		if("toggle_lock")
			return linked_house.toggle_lock(usr)

		if("upgrade_security")
			return linked_house.upgrade_security(usr)

		if("add_amenity")
			var/amenity = params["amenity"]
			return linked_house.add_amenity(amenity, usr)

		if("add_authorized")
			var/target_ckey = params["ckey"]
			if(target_ckey)
				return linked_house.add_authorized(target_ckey)
			return FALSE

		if("remove_authorized")
			var/target_ckey = params["ckey"]
			if(target_ckey)
				return linked_house.remove_authorized(target_ckey)
			return FALSE

	return FALSE

// ============ REAL ESTATE TERMINAL ============

/obj/machinery/real_estate_terminal
	name = "Real Estate Terminal"
	desc = "Browse and claim available properties."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/real_estate_terminal/Initialize()
	. = ..()
	generate_listings()

/obj/machinery/real_estate_terminal/proc/generate_listings()
	if(GLOB.safe_houses.len > 0)
		return

	var/list/house_types = list(
		/datum/safe_house/shack,
		/datum/safe_house/apartment,
		/datum/safe_house/bunker,
		/datum/safe_house/broadcast,
		/datum/safe_house/warehouse,
	)

	for(var/i = 1 to 5)
		var/house_type = pick(house_types)
		var/datum/safe_house/house = new house_type()
		GLOB.safe_houses += house

/obj/machinery/real_estate_terminal/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/real_estate_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RealEstateTerminal")
		ui.open()

/obj/machinery/real_estate_terminal/ui_data(mob/user)
	var/list/available_houses = list()

	for(var/datum/safe_house/house as anything in GLOB.safe_houses)
		var/list/house_data = list(
			"house_id" = house.house_id,
			"name" = house.name,
			"description" = house.description,
			"tier" = house.tier,
			"rent_cost" = house.rent_cost,
			"location_name" = house.location_name,
			"security_level" = house.security_level,
			"is_available" = !house.owner_ckey,
		)
		available_houses += list(house_data)

	return list(
		"available_houses" = available_houses,
		"player_house" = GLOB.player_houses[user.ckey],
	)

/obj/machinery/real_estate_terminal/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("claim_property")
			var/house_id = params["house_id"]
			for(var/datum/safe_house/house as anything in GLOB.safe_houses)
				if(house.house_id == house_id)
					return house.claim(usr)
			return FALSE

		if("refresh_listings")
			generate_listings()
			return TRUE

	return FALSE

// ============ HOUSE AMENITIES ============

/datum/house_amenity
	var/name = "Basic Amenity"
	var/description = "An amenity for your safe house."
	var/cost = 200
	var/unique = FALSE

/datum/house_amenity/workbench
	name = "Crafting Workbench"
	description = "A workbench for crafting items."
	cost = 300

/datum/house_amenity/bed
	name = "Quality Bed"
	description = "A comfortable bed for better rest."
	cost = 200

/datum/house_amenity/storage
	name = "Secure Storage"
	description = "A secure container for valuables."
	cost = 400

/datum/house_amenity/med_station
	name = "Medical Station"
	description = "Basic medical supplies and healing."
	cost = 500

/datum/house_amenity/generator
	name = "Power Generator"
	description = "Provides power to the house."
	cost = 350
