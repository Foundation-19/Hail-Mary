/datum/create_panel
	var/client/owner
	var/mode = "object"
	var/list/paths = list()

/datum/create_panel/New(client/C, panel_mode = "object")
	if(!istype(C))
		qdel(src)
		return
	owner = C
	mode = panel_mode
	switch(mode)
		if("object")
			paths = typesof(/obj)
		if("turf")
			paths = typesof(/turf)
		if("mob")
			paths = typesof(/mob)

/datum/create_panel/Destroy()
	owner = null
	paths = null
	return ..()

/datum/create_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/create_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CreatePanel")
		ui.open()

/datum/create_panel/ui_data(mob/user)
	. = list()
	.["mode"] = mode
	.["paths"] = paths

/datum/create_panel/ui_act(action, params)
	if(..())
		return TRUE

	switch(action)
		if("spawn")
			var/path = text2path(params["path"])
			if(!path)
				return
			var/count = text2num(params["count"]) || 1
			var/offset = params["offset"]
			var/offset_type = params["offset_type"]
			var/direction = text2num(params["dir"])
			var/custom_name = params["name"]
			var/where = params["where"]
			
			var/list/offsets = splittext(offset, ",")
			var/x_off = 0
			var/y_off = 0
			var/z_off = 0
			if(offsets.len >= 3)
				x_off = text2num(offsets[1]) || 0
				y_off = text2num(offsets[2]) || 0
				z_off = text2num(offsets[3]) || 0
			
			var/turf/target_turf
			var/mob/user = usr
			
			if(offset_type == "absolute")
				target_turf = locate(x_off, y_off, z_off)
			else
				var/turf/user_turf = get_turf(user)
				if(user_turf)
					target_turf = locate(user_turf.x + x_off, user_turf.y + y_off, user_turf.z + z_off)
			
			if(!target_turf)
				target_turf = get_turf(user)
			
			if(!target_turf)
				to_chat(user, span_warning("Cannot determine spawn location."))
				return TRUE
			
			for(var/i in 1 to count)
				if(mode == "turf")
					target_turf.ChangeTurf(path)
					log_admin("[key_name(user)] changed turf to [path] at [AREACOORD(target_turf)]")
					continue
				
				var/atom/movable/created
				switch(mode)
					if("object")
						created = new path(target_turf)
					if("mob")
						created = new path(target_turf)
				
				if(created)
					if(direction)
						created.setDir(direction)
					if(custom_name)
						created.name = custom_name
					
					if(where == "inhand" && ismob(user))
						var/mob/M = user
						M.put_in_hands(created)
					else if(where == "frompod")
						var/obj/structure/closet/supplypod/pod = new()
						pod.open()
						created.forceMove(pod)
					
					log_admin("[key_name(user)] created [created] at [AREACOORD(target_turf)]")
			
			to_chat(user, span_notice("Spawned [count] [initial(path)] at [AREACOORD(target_turf)]."))
			return TRUE

	return FALSE

/datum/admins/proc/create_object_tgui(mob/user)
	var/datum/create_panel/panel = new(user.client, "object")
	panel.ui_interact(user)

/datum/admins/proc/create_turf_tgui(mob/user)
	var/datum/create_panel/panel = new(user.client, "turf")
	panel.ui_interact(user)

/datum/admins/proc/create_mob_tgui(mob/user)
	var/datum/create_panel/panel = new(user.client, "mob")
	panel.ui_interact(user)
