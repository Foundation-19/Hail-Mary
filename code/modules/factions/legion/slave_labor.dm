// Legion Slave Labor Economy System
// Resource generation through slave labor

GLOBAL_LIST_EMPTY(legion_labor_sites)
GLOBAL_LIST_EMPTY(legion_labor_assignments)
GLOBAL_DATUM_INIT(legion_economy_manager, /datum/legion_economy_manager, new())

// ============ LABOR SITE ============

/obj/structure/labor_site
	name = "Labor Site Marker"
	desc = "A marker indicating a location where slaves can be put to work."
	icon = 'icons/obj/structures.dmi'
	icon_state = "labor_site"
	density = FALSE
	anchored = TRUE

	var/site_id
	var/site_name = "Labor Site"
	var/site_type = "mine"
	var/max_slaves = 10
	var/list/assigned_slaves = list()
	var/production_rate = 1.0
	var/list/resource_storage = list()
	var/guard_present = FALSE

/obj/structure/labor_site/Initialize()
	. = ..()
	site_id = "site_[rand(1000, 9999)]"
	GLOB.legion_labor_sites += src

/obj/structure/labor_site/Destroy()
	GLOB.legion_labor_sites -= src
	assigned_slaves.Cut()
	return ..()

/obj/structure/labor_site/proc/assign_slave(datum/slave_registry_entry/slave)
	if(assigned_slaves.len >= max_slaves)
		return FALSE

	if(slave.status != "enslaved")
		return FALSE

	for(var/datum/labor_assignment/assignment as anything in GLOB.legion_labor_assignments)
		if(assignment.slave_ckey == slave.slave_ckey)
			return FALSE

	var/datum/labor_assignment/new_assignment = new()
	new_assignment.slave_ckey = slave.slave_ckey
	new_assignment.slave_name = slave.slave_name
	new_assignment.site_id = site_id
	new_assignment.site_name = site_name
	new_assignment.resource_type = get_resource_type()
	new_assignment.active = TRUE

	GLOB.legion_labor_assignments += new_assignment
	assigned_slaves += new_assignment

	return TRUE

/obj/structure/labor_site/proc/get_resource_type()
	switch(site_type)
		if("mine")
			return pick("iron", "gold", "silver")
		if("farm")
			return pick("food", "healing_powder")
		if("construction")
			return "building_materials"
		if("quarry")
			return pick("stone", "concrete")
		if("workshop")
			return pick("weapons", "armor")
	return "misc"

/obj/structure/labor_site/proc/remove_slave(slave_ckey)
	for(var/datum/labor_assignment/assignment as anything in assigned_slaves)
		if(assignment.slave_ckey == slave_ckey)
			assigned_slaves -= assignment
			GLOB.legion_labor_assignments -= assignment
			qdel(assignment)
			return TRUE
	return FALSE

/obj/structure/labor_site/proc/process_labor()
	var/total_output = 0

	for(var/datum/labor_assignment/assignment as anything in assigned_slaves)
		if(!assignment.active)
			continue

		var/datum/slave_registry_entry/slave
		for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
			if(entry.slave_ckey == assignment.slave_ckey)
				slave = entry
				break

		if(!slave)
			continue

		var/output = LABOR_OUTPUT_BASE

		if(slave.obedience)
			if(slave.obedience.current_obedience > 80)
				output *= 1.5
			else if(slave.obedience.current_obedience < 30)
				output *= 0.5

		if(slave.slave_type == SLAVE_TYPE_SPECIALIST)
			output *= 2

		if(guard_present)
			output *= 1.2

		total_output += output

	var/resource_type = get_resource_type()
	resource_storage[resource_type] = (resource_storage[resource_type] || 0) + total_output

/obj/structure/labor_site/proc/collect_resources(mob/user)
	var/total_collected = 0
	for(var/resource in resource_storage)
		var/amount = resource_storage[resource]
		total_collected += amount
		resource_storage[resource] = 0

	if(total_collected > 0)
		to_chat(user, span_notice("Collected [total_collected] units of resources from [site_name]."))
		return total_collected
	return 0

/obj/structure/labor_site/proc/get_ui_data()
	var/list/slaves_data = list()
	for(var/datum/labor_assignment/assignment as anything in assigned_slaves)
		slaves_data += list(list(
			"slave_ckey" = assignment.slave_ckey,
			"slave_name" = assignment.slave_name,
			"active" = assignment.active,
		))

	return list(
		"site_id" = site_id,
		"site_name" = site_name,
		"site_type" = site_type,
		"max_slaves" = max_slaves,
		"current_slaves" = assigned_slaves.len,
		"production_rate" = production_rate,
		"guard_present" = guard_present,
		"resource_storage" = resource_storage,
		"slaves" = slaves_data,
	)

// ============ LABOR ASSIGNMENT ============

/datum/labor_assignment
	var/slave_ckey
	var/slave_name
	var/site_id
	var/site_name
	var/resource_type = "iron"
	var/generation_rate = 5
	var/difficulty = 1
	var/active = TRUE
	var/work_time = 0
	var/required_for_freedom = 20 MINUTES

/datum/labor_assignment/proc/process_work()
	if(!active)
		return

	work_time += LABOR_TICK

	var/datum/slave_registry_entry/slave
	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == slave_ckey)
			slave = entry
			break

	if(!slave)
		return

	if(work_time >= required_for_freedom)
		grant_freedom(slave)

/datum/labor_assignment/proc/grant_freedom(datum/slave_registry_entry/slave)
	if(!slave)
		return

	slave.status = "freed"
	active = FALSE

	var/mob/living/carbon/human/H = slave.get_slave_mob()
	if(H)
		to_chat(H, span_notice("You have worked for your freedom! The collar deactivates and falls off."))
		var/obj/item/slave_collar/collar = H.get_item_by_slot(ITEM_SLOT_NECK)
		if(collar)
			H.dropItemToGround(collar)
			qdel(collar)

// ============ LABOR SITE TYPES ============

/obj/structure/labor_site/mine
	name = "Mining Operation"
	site_name = "Mining Operation"
	site_type = "mine"
	max_slaves = 10

/obj/structure/labor_site/farm
	name = "Agricultural Field"
	site_name = "Agricultural Field"
	site_type = "farm"
	max_slaves = 15

/obj/structure/labor_site/construction
	name = "Construction Site"
	site_name = "Construction Site"
	site_type = "construction"
	max_slaves = 8

/obj/structure/labor_site/quarry
	name = "Stone Quarry"
	site_name = "Stone Quarry"
	site_type = "quarry"
	max_slaves = 12

/obj/structure/labor_site/workshop
	name = "Craft Workshop"
	site_name = "Craft Workshop"
	site_type = "workshop"
	max_slaves = 5

// ============ LEGION ECONOMY MANAGER ============

/datum/legion_economy_manager
	var/list/resource_totals = list()
	var/last_process = 0

/datum/legion_economy_manager/proc/process()
	if(world.time < last_process + LABOR_TICK)
		return

	last_process = world.time

	for(var/obj/structure/labor_site/site as anything in GLOB.legion_labor_sites)
		site.process_labor()

	for(var/datum/labor_assignment/assignment as anything in GLOB.legion_labor_assignments)
		assignment.process_work()

	update_resource_totals()

/datum/legion_economy_manager/proc/update_resource_totals()
	resource_totals.Cut()

	for(var/obj/structure/labor_site/site as anything in GLOB.legion_labor_sites)
		for(var/resource in site.resource_storage)
			resource_totals[resource] = (resource_totals[resource] || 0) + site.resource_storage[resource]

/datum/legion_economy_manager/proc/get_ui_data()
	var/list/sites_data = list()
	for(var/obj/structure/labor_site/site as anything in GLOB.legion_labor_sites)
		sites_data += list(site.get_ui_data())

	var/list/unassigned_slaves = list()
	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.status != "enslaved" || entry.slave_type != SLAVE_TYPE_LABOR)
			continue

		var/assigned = FALSE
		for(var/datum/labor_assignment/assignment as anything in GLOB.legion_labor_assignments)
			if(assignment.slave_ckey == entry.slave_ckey)
				assigned = TRUE
				break

		if(!assigned)
			unassigned_slaves += list(entry.get_ui_data())

	return list(
		"sites" = sites_data,
		"unassigned_slaves" = unassigned_slaves,
		"resource_totals" = resource_totals,
		"total_slaves_working" = GLOB.legion_labor_assignments.len,
	)

// ============ LABOR MANAGEMENT CONSOLE ============

/obj/machinery/computer/labor_management
	name = "Labor Management Terminal"
	desc = "A terminal for managing slave labor assignments."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/labor_management/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/labor_management/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SlaveEconomy")
		ui.open()

/obj/machinery/computer/labor_management/ui_data(mob/user)
	return GLOB.legion_economy_manager.get_ui_data()

/obj/machinery/computer/labor_management/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("assign_slave")
			return assign_slave(params)
		if("remove_slave")
			return remove_slave(params)
		if("collect_resources")
			return collect_resources(params)

	return FALSE

/obj/machinery/computer/labor_management/proc/assign_slave(list/params)
	var/slave_ckey = params["slave_ckey"]
	var/site_id = params["site_id"]

	var/datum/slave_registry_entry/slave
	for(var/datum/slave_registry_entry/entry in GLOB.legion_slave_registry)
		if(entry.slave_ckey == slave_ckey)
			slave = entry
			break

	if(!slave)
		return FALSE

	for(var/obj/structure/labor_site/site as anything in GLOB.legion_labor_sites)
		if(site.site_id == site_id)
			return site.assign_slave(slave)

	return FALSE

/obj/machinery/computer/labor_management/proc/remove_slave(list/params)
	var/slave_ckey = params["slave_ckey"]
	var/site_id = params["site_id"]

	for(var/obj/structure/labor_site/site as anything in GLOB.legion_labor_sites)
		if(site.site_id == site_id)
			return site.remove_slave(slave_ckey)

	return FALSE

/obj/machinery/computer/labor_management/proc/collect_resources(list/params)
	var/site_id = params["site_id"]

	for(var/obj/structure/labor_site/site as anything in GLOB.legion_labor_sites)
		if(site.site_id == site_id)
			return site.collect_resources(usr)

	return FALSE
