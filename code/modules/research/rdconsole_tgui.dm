
#define RDSCREEN_TGUI_MENU 0
#define RDSCREEN_TGUI_TECHWEB 1
#define RDSCREEN_TGUI_NODEVIEW 2
#define RDSCREEN_TGUI_DESIGNVIEW 3
#define RDSCREEN_TGUI_PROTOLATHE 4
#define RDSCREEN_TGUI_IMPRINTER 5
#define RDSCREEN_TGUI_DECONSTRUCT 6
#define RDSCREEN_TGUI_TECHDISK 7
#define RDSCREEN_TGUI_DESIGNDISK 8
#define RDSCREEN_TGUI_SETTINGS 9

/obj/machinery/computer/rdconsole/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResearchConsole")
		ui.open()

/obj/machinery/computer/rdconsole/ui_data(mob/user)
	var/list/data = list()
	
	data["locked"] = locked
	data["security_enabled"] = !(obj_flags & EMAGGED)
	data["organization"] = stored_research ? stored_research.organization : "Unknown"
	data["research_control"] = research_control
	
	data["points"] = list()
	for(var/point_type in stored_research.research_points)
		data["points"][point_type] = stored_research.research_points[point_type]
	
	data["income"] = list()
	for(var/point_type in stored_research.last_bitcoins)
		data["income"][point_type] = stored_research.last_bitcoins[point_type]
	
	data["has_lathe"] = !QDELETED(linked_lathe)
	data["has_imprinter"] = !QDELETED(linked_imprinter)
	data["has_destroyer"] = !QDELETED(linked_destroy)
	data["has_tech_disk"] = !QDELETED(t_disk)
	data["has_design_disk"] = !QDELETED(d_disk)
	
	// Map old screen defines to TGUI screen numbers
	var/tgui_screen = 0
	switch(screen)
		if(RDSCREEN_MENU)
			tgui_screen = 0
		if(RDSCREEN_TECHWEB, RDSCREEN_TECHWEB_NODEVIEW, RDSCREEN_TECHWEB_DESIGNVIEW)
			tgui_screen = 1
		if(RDSCREEN_PROTOLATHE, RDSCREEN_PROTOLATHE_MATERIALS, RDSCREEN_PROTOLATHE_CHEMICALS, RDSCREEN_PROTOLATHE_CATEGORY_VIEW, RDSCREEN_PROTOLATHE_SEARCH)
			tgui_screen = 4
		if(RDSCREEN_IMPRINTER, RDSCREEN_IMPRINTER_MATERIALS, RDSCREEN_IMPRINTER_CHEMICALS, RDSCREEN_IMPRINTER_CATEGORY_VIEW, RDSCREEN_IMPRINTER_SEARCH)
			tgui_screen = 5
		if(RDSCREEN_DECONSTRUCT)
			tgui_screen = 6
		if(RDSCREEN_TECHDISK)
			tgui_screen = 7
		if(RDSCREEN_DESIGNDISK, RDSCREEN_DESIGNDISK_UPLOAD)
			tgui_screen = 8
		if(RDSCREEN_SETTINGS, RDSCREEN_DEVICE_LINKING)
			tgui_screen = 9
		else
			tgui_screen = 0
	data["screen"] = tgui_screen
	
	data["nodes"] = list()
	data["researched_count"] = 0
	data["available_count"] = 0
	
	for(var/node_id in stored_research.tiers)
		var/datum/techweb_node/node = SSresearch.techweb_node_by_id(node_id)
		if(stored_research.hidden_nodes[node_id])
			continue
		
		var/status = "locked"
		if(stored_research.researched_nodes[node_id])
			status = "researched"
			data["researched_count"]++
		else if(stored_research.available_nodes[node_id])
			status = "available"
			data["available_count"]++
		
		var/list/cost = node.get_price(stored_research)
		var/cost_display = techweb_point_display_generic(cost)
		var/can_afford = stored_research.can_afford(cost)
		
		var/list/prereqs = list()
		for(var/prereq_id in node.prereq_ids)
			var/datum/techweb_node/prereq = SSresearch.techweb_node_by_id(prereq_id)
			prereqs += list(list(
				"id" = prereq_id,
				"name" = prereq.display_name,
				"researched" = stored_research.researched_nodes[prereq_id] ? TRUE : FALSE,
			))
		
		var/list/unlocks = list()
		for(var/unlock_id in node.unlock_ids)
			var/datum/techweb_node/unlock = SSresearch.techweb_node_by_id(unlock_id)
			unlocks += list(list(
				"id" = unlock_id,
				"name" = unlock.display_name,
				"researched" = stored_research.researched_nodes[unlock_id] ? TRUE : FALSE,
			))
		
		var/list/designs = list()
		for(var/design_id in node.design_ids)
			var/datum/design/design = SSresearch.techweb_design_by_id(design_id)
			designs += list(list(
				"id" = design_id,
				"name" = design.name,
			))
		
		data["nodes"] += list(list(
			"id" = node_id,
			"name" = node.display_name,
			"description" = node.description,
			"category" = node.category,
			"tier" = stored_research.tiers[node_id],
			"status" = status,
			"cost_display" = cost_display,
			"can_afford" = can_afford,
			"prereqs" = prereqs,
			"unlocks" = unlocks,
			"designs" = designs,
		))
	
	if(selected_node_id)
		data["selected_node"] = get_node_data(selected_node_id)
	else
		data["selected_node"] = null
	
	if(selected_design_id)
		data["selected_design"] = get_design_data(selected_design_id)
	else
		data["selected_design"] = null
	
	if(data["has_lathe"])
		data["lathe_materials"] = get_lathe_materials(linked_lathe)
		data["lathe_chemicals"] = get_lathe_chemicals(linked_lathe)
		data["lathe_categories"] = linked_lathe.categories
		data["lathe_busy"] = linked_lathe.busy
		data["lathe_designs"] = get_available_designs(PROTOLATHE)
	
	if(data["has_imprinter"])
		data["imprinter_materials"] = get_lathe_materials(linked_imprinter)
		data["imprinter_chemicals"] = get_lathe_chemicals(linked_imprinter)
		data["imprinter_categories"] = linked_imprinter.categories
		data["imprinter_busy"] = linked_imprinter.busy
		data["imprinter_designs"] = get_available_designs(IMPRINTER)
	
	if(data["has_destroyer"])
		data["destroyer_loaded"] = linked_destroy.loaded_item ? TRUE : FALSE
		if(linked_destroy.loaded_item)
			data["destroyer_item_name"] = linked_destroy.loaded_item.name
		data["destroyer_busy"] = linked_destroy.busy
	
	if(data["has_tech_disk"])
		data["tech_disk_nodes"] = list()
		for(var/node_id in t_disk.stored_research.researched_nodes)
			var/datum/techweb_node/node = SSresearch.techweb_node_by_id(node_id)
			data["tech_disk_nodes"] += list(list(
				"id" = node_id,
				"name" = node.display_name,
			))
	
	if(data["has_design_disk"])
		data["design_disk_slots"] = list()
		for(var/i in 1 to d_disk.max_blueprints)
			if(d_disk.blueprints[i])
				var/datum/design/D = d_disk.blueprints[i]
				data["design_disk_slots"] += list(list(
					"slot" = i,
					"name" = D.name,
					"id" = D.id,
				))
			else
				data["design_disk_slots"] += list(list(
					"slot" = i,
					"name" = null,
					"id" = null,
				))
	
	if(selected_category)
		data["selected_category"] = selected_category
	else
		data["selected_category"] = null
	
	data["search_string"] = searchstring
	
	return data

/obj/machinery/computer/rdconsole/proc/get_node_data(node_id)
	var/datum/techweb_node/node = SSresearch.techweb_node_by_id(node_id)
	if(!node)
		return null
	
	var/list/cost = node.get_price(stored_research)
	
	var/list/prereqs = list()
	for(var/prereq_id in node.prereq_ids)
		var/datum/techweb_node/prereq = SSresearch.techweb_node_by_id(prereq_id)
		prereqs += list(list(
			"id" = prereq_id,
			"name" = prereq.display_name,
			"researched" = stored_research.researched_nodes[prereq_id] ? TRUE : FALSE,
		))
	
	var/list/unlocks = list()
	for(var/unlock_id in node.unlock_ids)
		var/datum/techweb_node/unlock = SSresearch.techweb_node_by_id(unlock_id)
		unlocks += list(list(
			"id" = unlock_id,
			"name" = unlock.display_name,
			"researched" = stored_research.researched_nodes[unlock_id] ? TRUE : FALSE,
		))
	
	var/list/designs = list()
	for(var/design_id in node.design_ids)
		designs += list(get_design_data(design_id))
	
	return list(
		"id" = node_id,
		"name" = node.display_name,
		"description" = node.description,
		"category" = node.category,
		"tier" = stored_research.tiers[node_id],
		"status" = stored_research.researched_nodes[node_id] ? "researched" : stored_research.available_nodes[node_id] ? "available" : "locked",
		"cost" = cost,
		"cost_display" = techweb_point_display_generic(cost),
		"can_afford" = stored_research.can_afford(cost),
		"prereqs" = prereqs,
		"unlocks" = unlocks,
		"designs" = designs,
	)

/obj/machinery/computer/rdconsole/proc/get_design_data(design_id)
	var/datum/design/design = SSresearch.techweb_design_by_id(design_id)
	if(!design)
		return null
	
	var/list/materials = list()
	for(var/mat in design.materials)
		var/mat_name = CallMaterialName(mat)
		materials += list(list(
			"name" = mat_name,
			"amount" = design.materials[mat],
		))
	
	var/list/reagents = list()
	for(var/reag in design.reagents_list)
		var/reag_name = CallMaterialName(reag)
		reagents += list(list(
			"name" = reag_name,
			"amount" = design.reagents_list[reag],
		))
	
	var/list/build_types = list()
	if(design.build_type & PROTOLATHE)
		build_types += "protolathe"
	if(design.build_type & IMPRINTER)
		build_types += "imprinter"
	if(design.build_type & AUTOLATHE)
		build_types += "autolathe"
	if(design.build_type & MECHFAB)
		build_types += "mechfab"
	
	var/list/unlocked_by = list()
	for(var/node_id in design.unlocked_by)
		var/datum/techweb_node/node = SSresearch.techweb_node_by_id(node_id)
		unlocked_by += list(list(
			"id" = node_id,
			"name" = node.display_name,
			"researched" = stored_research.researched_nodes[node_id] ? TRUE : FALSE,
		))
	
	return list(
		"id" = design_id,
		"name" = design.name,
		"build_types" = build_types,
		"materials" = materials,
		"reagents" = reagents,
		"category" = design.category,
		"unlocked_by" = unlocked_by,
	)

/obj/machinery/computer/rdconsole/proc/get_lathe_materials(obj/machinery/rnd/production/lathe)
	var/list/materials = list()
	if(!lathe.materials.mat_container)
		return materials
	
	for(var/mat_id in lathe.materials.mat_container.materials)
		var/datum/material/M = mat_id
		var/amount = lathe.materials.mat_container.materials[mat_id]
		materials += list(list(
			"name" = M.name,
			"amount" = amount,
			"ref" = REF(M),
		))
	
	return materials

/obj/machinery/computer/rdconsole/proc/get_lathe_chemicals(obj/machinery/rnd/production/lathe)
	var/list/chemicals = list()
	for(var/datum/reagent/R in lathe.reagents.reagent_list)
		chemicals += list(list(
			"name" = R.name,
			"volume" = R.volume,
		))
	
	return chemicals

/obj/machinery/computer/rdconsole/proc/get_available_designs(build_type)
	var/list/designs = list()
	
	for(var/design_id in stored_research.researched_designs)
		var/datum/design/design = SSresearch.techweb_design_by_id(design_id)
		if(!(design.build_type & build_type))
			continue
		
		var/list/mat_check = list()
		var/can_build = TRUE
		
		if(build_type == PROTOLATHE && linked_lathe)
			var/coeff = linked_lathe.print_cost_coeff
			if(!linked_lathe.efficient_with(design.build_path))
				coeff = 1
			for(var/mat in design.materials)
				var/available = linked_lathe.check_mat(design, mat)
				mat_check += list(list(
					"name" = CallMaterialName(mat),
					"needed" = design.materials[mat] * coeff,
					"available" = available,
				))
				if(available < 1)
					can_build = FALSE
		else if(build_type == IMPRINTER && linked_imprinter)
			var/coeff = linked_imprinter.print_cost_coeff
			if(!linked_imprinter.efficient_with(design.build_path))
				coeff = 1
			for(var/mat in design.materials)
				var/available = linked_imprinter.check_mat(design, mat)
				mat_check += list(list(
					"name" = CallMaterialName(mat),
					"needed" = design.materials[mat] * coeff,
					"available" = available,
				))
				if(available < 1)
					can_build = FALSE
		
		designs += list(list(
			"id" = design_id,
			"name" = design.name,
			"categories" = design.category,
			"can_build" = can_build,
			"materials" = mat_check,
		))
	
	return designs

/obj/machinery/computer/rdconsole/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	
	add_fingerprint(usr)
	
	switch(action)
		if("lock")
			if(obj_flags & EMAGGED)
				to_chat(usr, span_boldwarning("Security protocol error: Unable to lock."))
				return TRUE
			if(allowed(usr))
				locked = TRUE
				return TRUE
			else
				to_chat(usr, span_boldwarning("Unauthorized Access."))
		
		if("unlock")
			if(allowed(usr))
				locked = FALSE
				return TRUE
			else
				to_chat(usr, span_boldwarning("Unauthorized Access."))
		
		if("set_screen")
			var/new_screen = text2num(params["screen"])
			// Map TGUI screen numbers to original defines
			switch(new_screen)
				if(0)
					screen = RDSCREEN_MENU
				if(1)
					screen = RDSCREEN_TECHWEB
					selected_node_id = null
				if(4)
					screen = RDSCREEN_PROTOLATHE
				if(5)
					screen = RDSCREEN_IMPRINTER
				if(6)
					screen = RDSCREEN_DECONSTRUCT
				if(7)
					screen = RDSCREEN_TECHDISK
				if(8)
					screen = RDSCREEN_DESIGNDISK
				if(9)
					screen = RDSCREEN_SETTINGS
				else
					screen = new_screen
			return TRUE
		
		if("research_node")
			if(!research_control)
				return
			if(locked)
				return
			research_node(params["node_id"], usr)
			return TRUE
		
		if("select_node")
			selected_node_id = params["node_id"]
			screen = RDSCREEN_TECHWEB
			return TRUE
		
		if("select_design")
			selected_design_id = params["design_id"]
			screen = RDSCREEN_TGUI_DESIGNVIEW
			return TRUE
		
		if("build")
			if(QDELETED(linked_lathe))
				return
			if(linked_lathe.busy)
				say("Protolathe busy!")
				return
			linked_lathe.user_try_print_id(params["design_id"], text2num(params["amount"]) || 1)
			return TRUE
		
		if("imprint")
			if(QDELETED(linked_imprinter))
				return
			if(linked_imprinter.busy)
				say("Circuit imprinter busy!")
				return
			linked_imprinter.user_try_print_id(params["design_id"])
			return TRUE
		
		if("select_category")
			selected_category = params["category"]
			return TRUE
		
		if("clear_category")
			selected_category = null
			return TRUE
		
		if("eject_material")
			if(QDELETED(linked_lathe))
				return
			if(!linked_lathe.materials.mat_container)
				return
			var/datum/material/M = locate(params["ref"]) in linked_lathe.materials.mat_container.materials
			if(M)
				linked_lathe.eject_sheets(M, text2num(params["amount"]) || 1)
			return TRUE
		
		if("eject_imprinter_material")
			if(QDELETED(linked_imprinter))
				return
			if(!linked_imprinter.materials.mat_container)
				return
			var/datum/material/M = locate(params["ref"]) in linked_imprinter.materials.mat_container.materials
			if(M)
				linked_imprinter.eject_sheets(M, text2num(params["amount"]) || 1)
			return TRUE
		
		if("dispose_reagent")
			var/target = params["target"]
			if(target == "lathe" && !QDELETED(linked_lathe))
				linked_lathe.reagents.del_reagent(params["reagent"])
			else if(target == "imprinter" && !QDELETED(linked_imprinter))
				linked_imprinter.reagents.del_reagent(params["reagent"])
			return TRUE
		
		if("dispose_all_reagents")
			var/target = params["target"]
			if(target == "lathe" && !QDELETED(linked_lathe))
				linked_lathe.reagents.clear_reagents()
			else if(target == "imprinter" && !QDELETED(linked_imprinter))
				linked_imprinter.reagents.clear_reagents()
			return TRUE
		
		if("eject_tech_disk")
			if(!QDELETED(t_disk))
				eject_disk("tech")
				screen = RDSCREEN_TGUI_MENU
			return TRUE
		
		if("eject_design_disk")
			if(!QDELETED(d_disk))
				eject_disk("design")
				screen = RDSCREEN_TGUI_MENU
			return TRUE
		
		if("upload_tech_disk")
			if(QDELETED(t_disk))
				return
			say("Uploading technology disk.")
			t_disk.stored_research.copy_research_to(stored_research)
			return TRUE
		
		if("download_tech_disk")
			if(QDELETED(t_disk))
				return
			say("Downloading to technology disk.")
			stored_research.copy_research_to(t_disk.stored_research)
			return TRUE
		
		if("clear_tech_disk")
			if(QDELETED(t_disk))
				return
			QDEL_NULL(t_disk.stored_research)
			t_disk.stored_research = new
			say("Wiping technology disk.")
			return TRUE
		
		if("upload_design_disk")
			if(QDELETED(d_disk))
				return
			var/slot = text2num(params["slot"])
			if(slot && d_disk.blueprints[slot])
				stored_research.add_design(d_disk.blueprints[slot], TRUE)
				say("Uploaded design to database.")
			else if(!slot)
				for(var/i in 1 to d_disk.max_blueprints)
					if(d_disk.blueprints[i])
						stored_research.add_design(d_disk.blueprints[i], TRUE)
				say("Uploaded all designs to database.")
			return TRUE
		
		if("copy_to_design_disk")
			if(QDELETED(d_disk))
				return
			var/slot = text2num(params["slot"])
			var/design_id = params["design_id"]
			if(!slot || !design_id)
				return
			var/datum/design/D = SSresearch.techweb_design_by_id(design_id)
			if(!D)
				return
			d_disk.blueprints[slot] = D
			say("Copied design to disk.")
			return TRUE
		
		if("clear_design_disk_slot")
			if(QDELETED(d_disk))
				return
			var/slot = text2num(params["slot"])
			if(slot)
				d_disk.blueprints[slot] = null
				say("Cleared design slot.")
			return TRUE
		
		if("clear_design_disk_all")
			if(QDELETED(d_disk))
				return
			for(var/i in 1 to d_disk.max_blueprints)
				d_disk.blueprints[i] = null
			say("Wiping design disk.")
			return TRUE
		
		if("sync_devices")
			SyncRDevices()
			say("Resynced with nearby devices.")
			return TRUE
		
		if("deconstruct")
			if(QDELETED(linked_destroy))
				return
			if((last_long_action + 1 SECONDS) > world.time)
				return
			last_long_action = world.time
			linked_destroy.user_try_decon_id(params["node_id"], usr)
			return TRUE
		
		if("eject_destroyer_item")
			if(QDELETED(linked_destroy))
				return
			if(linked_destroy.busy)
				return
			if(linked_destroy.loaded_item)
				linked_destroy.unload_item()
			return TRUE
	
	return FALSE
