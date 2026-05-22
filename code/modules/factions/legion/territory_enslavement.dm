// Legion Territory Enslavement System
// Managing enslaved populations in conquered territories

GLOBAL_LIST_EMPTY(enslaved_territories)

// ============ ENSLAVED TERRITORY ============

/datum/enslaved_territory
	var/territory_id
	var/territory_name = "Unknown Territory"
	var/owner_faction = "legion"
	var/population = 100
	var/enslaved_percent = 10
	var/resistance_level = 0
	var/generation_rate = 10
	var/last_tick = 0
	var/legion_presence = 1
	var/rebellion_cooldown = 0

/datum/enslaved_territory/New(id, name, pop)
	territory_id = id
	territory_name = name
	if(pop)
		population = pop
	GLOB.enslaved_territories += src

/datum/enslaved_territory/Destroy()
	GLOB.enslaved_territories -= src
	return ..()

/datum/enslaved_territory/proc/process()
	if(world.time < last_tick + 5 MINUTES)
		return

	last_tick = world.time

	process_revenue()
	check_rebellion()
	process_resistance_decay()

/datum/enslaved_territory/proc/process_revenue()
	var/base_revenue = population * (enslaved_percent / 100) * generation_rate

	if(owner_faction != "legion")
		return

	GLOB.legion_economy_manager.resource_totals["caps"] = 
		(GLOB.legion_economy_manager.resource_totals["caps"] || 0) + base_revenue

/datum/enslaved_territory/proc/enslave_more(percent)
	if(owner_faction != "legion")
		return FALSE

	var/new_percent = enslaved_percent + percent
	if(new_percent > 50)
		new_percent = 50

	enslaved_percent = new_percent
	resistance_level += percent * 2

	return TRUE

/datum/enslaved_territory/proc/free_slaves(percent)
	var/new_percent = enslaved_percent - percent
	if(new_percent < 0)
		new_percent = 0

	enslaved_percent = new_percent
	resistance_level -= percent

/datum/enslaved_territory/proc/check_rebellion()
	if(rebellion_cooldown > world.time)
		return

	var/rebellion_chance = resistance_level * (100 - legion_presence * 10) / 100

	if(prob(rebellion_chance))
		trigger_rebellion()

/datum/enslaved_territory/proc/trigger_rebellion()
	rebellion_cooldown = world.time + 30 MINUTES

	var/event_type = pick("sabotage", "escape", "uprising")

	switch(event_type)
		if("sabotage")
			sabotage_event()
		if("escape")
			escape_event()
		if("uprising")
			uprising_event()

/datum/enslaved_territory/proc/sabotage_event()
	generation_rate *= 0.5
	addtimer(VARSET_CALLBACK(src, generation_rate, generation_rate * 2), 10 MINUTES)

	message_admins("Sabotage in enslaved territory [territory_name]!")

/datum/enslaved_territory/proc/escape_event()
	var/escaped = round(population * enslaved_percent * 0.05)
	enslaved_percent -= 5

	message_admins("[escaped] slaves escaped from [territory_name]!")

/datum/enslaved_territory/proc/uprising_event()
	resistance_level = 100
	enslaved_percent = max(enslaved_percent - 20, 0)

	message_admins("Uprising in [territory_name]! Military response required!")

/datum/enslaved_territory/proc/crack_down()
	resistance_level -= 30
	legion_presence += 1

	if(resistance_level < 0)
		resistance_level = 0

/datum/enslaved_territory/proc/process_resistance_decay()
	if(owner_faction != "legion")
		return

	resistance_level -= legion_presence

	if(resistance_level < 0)
		resistance_level = 0

/datum/enslaved_territory/proc/get_ui_data()
	return list(
		"territory_id" = territory_id,
		"territory_name" = territory_name,
		"owner_faction" = owner_faction,
		"population" = population,
		"enslaved_percent" = enslaved_percent,
		"enslaved_count" = round(population * enslaved_percent / 100),
		"resistance_level" = resistance_level,
		"generation_rate" = generation_rate,
		"legion_presence" = legion_presence,
	)

// ============ TERRITORY MANAGEMENT CONSOLE ============

/obj/machinery/computer/territory_enslavement
	name = "Territory Management Terminal"
	desc = "A terminal for managing enslaved populations in Legion territories."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/territory_enslavement/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/territory_enslavement/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TerritoryEnslavement")
		ui.open()

/obj/machinery/computer/territory_enslavement/ui_data(mob/user)
	var/list/territories_data = list()
	for(var/datum/enslaved_territory/territory as anything in GLOB.enslaved_territories)
		territories_data += list(territory.get_ui_data())

	return list(
		"territories" = territories_data,
		"total_enslaved" = get_total_enslaved(),
		"total_revenue" = get_total_revenue(),
	)

/obj/machinery/computer/territory_enslavement/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("enslave_more")
			return enslave_more(params)
		if("free_slaves")
			return free_slaves(params)
		if("crack_down")
			return crack_down(params)

	return FALSE

/obj/machinery/computer/territory_enslavement/proc/enslave_more(list/params)
	var/territory_id = params["territory_id"]
	var/percent = text2num(params["percent"]) || 5

	for(var/datum/enslaved_territory/territory as anything in GLOB.enslaved_territories)
		if(territory.territory_id == territory_id)
			return territory.enslave_more(percent)

	return FALSE

/obj/machinery/computer/territory_enslavement/proc/free_slaves(list/params)
	var/territory_id = params["territory_id"]
	var/percent = text2num(params["percent"]) || 10

	for(var/datum/enslaved_territory/territory as anything in GLOB.enslaved_territories)
		if(territory.territory_id == territory_id)
			territory.free_slaves(percent)
			return TRUE

	return FALSE

/obj/machinery/computer/territory_enslavement/proc/crack_down(list/params)
	var/territory_id = params["territory_id"]

	for(var/datum/enslaved_territory/territory as anything in GLOB.enslaved_territories)
		if(territory.territory_id == territory_id)
			territory.crack_down()
			return TRUE

	return FALSE

/obj/machinery/computer/territory_enslavement/proc/get_total_enslaved()
	var/total = 0
	for(var/datum/enslaved_territory/territory as anything in GLOB.enslaved_territories)
		total += round(territory.population * territory.enslaved_percent / 100)
	return total

/obj/machinery/computer/territory_enslavement/proc/get_total_revenue()
	var/total = 0
	for(var/datum/enslaved_territory/territory as anything in GLOB.enslaved_territories)
		if(territory.owner_faction == "legion")
			total += territory.population * (territory.enslaved_percent / 100) * territory.generation_rate
	return total

// ============ INITIALIZATION ============

/proc/initialize_enslaved_territories()
	if(GLOB.enslaved_territories.len)
		return

	new /datum/enslaved_territory("goodsprings", "Goodsprings", 150)
	new /datum/enslaved_territory("primm", "Primm", 200)
	new /datum/enslaved_territory("novac", "Novac", 180)
	new /datum/enslaved_territory("nelpson", "Nelson", 100)
	new /datum/enslaved_territory("cotton_cove", "Cottonwood Cove", 120)
