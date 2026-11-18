
/obj/machinery/pipedispenser
	name = "pipe dispenser"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "pipe_d"
	desc = "Dispenses countless types of pipes. Very useful if you need pipes."
	density = TRUE
	circuit = /obj/item/circuitboard/machine/pipedispenser
	interaction_flags_machine = INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_OFFLINE
	var/wait = 0
	var/piping_layer = PIPING_LAYER_DEFAULT

/// Shared page head so every pipe button renders as an icon tile with its label underneath.
#define PIPE_DISPENSER_STYLE "<STYLE>a.pipe{display:inline-block;width:84px;height:68px;margin:2px;padding:2px;border:1px solid #555;text-align:center;vertical-align:top;text-decoration:none;font-size:11px;overflow:hidden}a.pipe:hover{background:#334;border-color:#99f}a.pipe img{display:block;margin:0 auto 2px auto}</STYLE>"

/obj/machinery/pipedispenser/attack_paw(mob/user)
	return attack_hand(user)

/obj/machinery/pipedispenser/ui_interact(mob/user)
	. = ..()
	var/dat = "PIPING LAYER: <A href='?src=[REF(src)];layer_down=1'>--</A><b>[piping_layer]</b><A href='?src=[REF(src)];layer_up=1'>++</A><BR>"

	var/recipes = GLOB.atmos_pipe_recipes

	for(var/category in recipes)
		var/list/cat_recipes = recipes[category]
		dat += "<b>[category]:</b><br>"

		for(var/i in cat_recipes)
			var/datum/pipe_info/I = i
			dat += I.Render(src, user)

		dat += "<br>"

	user << browse("<HEAD><TITLE>[src]</TITLE>[PIPE_DISPENSER_STYLE]</HEAD><TT>[dat]</TT>", "window=pipedispenser;size=480x560")
	onclose(user, "pipedispenser")
	return

/obj/machinery/pipedispenser/Topic(href, href_list)
	if(..())
		return 1
	var/mob/living/L = usr
	if(!anchored || !istype(L) || !CHECK_MOBILITY(L, MOBILITY_USE))
		usr << browse(null, "window=pipedispenser")
		return 1
	usr.set_machine(src)
	add_fingerprint(usr)
	if(href_list["make"])
		if(wait < world.time)
			var/p_type = text2path(href_list["make"])
			if(!ispath(p_type, /obj/machinery/atmospherics))
				return
			var/p_dir = text2num(href_list["dir"])
			var/obj/item/pipe/P = new (loc, p_type, p_dir)
			P.setPipingLayer(piping_layer)
			P.add_fingerprint(usr)
			wait = world.time + 10
	if(href_list["makemeter"])
		if(wait < world.time )
			new /obj/item/pipe_meter(loc)
			wait = world.time + 15
	if(href_list["layer_up"])
		piping_layer = clamp(++piping_layer, PIPING_LAYER_MIN, PIPING_LAYER_MAX)
	if(href_list["layer_down"])
		piping_layer = clamp(--piping_layer, PIPING_LAYER_MIN, PIPING_LAYER_MAX)
	return

/obj/machinery/pipedispenser/attackby(obj/item/W, mob/user, params)
	add_fingerprint(user)
	if (istype(W, /obj/item/pipe) || istype(W, /obj/item/pipe_meter))
		to_chat(usr, span_notice("You put [W] back into [src]."))
		qdel(W)
		return
	else
		return ..()

/obj/machinery/pipedispenser/proc/verify_recipe(recipes, path)
	for(var/category in recipes)
		var/list/cat_recipes = recipes[category]
		for(var/i in cat_recipes)
			var/datum/pipe_info/info = i
			if (path == info.id)
				return TRUE
	return FALSE

/obj/machinery/pipedispenser/wrench_act(mob/living/user, obj/item/I)
	if(default_unfasten_wrench(user, I, 40))
		user << browse(null, "window=pipedispenser")

	return TRUE


/obj/machinery/pipedispenser/disposal
	name = "disposal pipe dispenser"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "pipe_d"
	desc = "Dispenses pipes that will ultimately be used to move trash around."
	density = TRUE
	circuit = /obj/item/circuitboard/machine/disposaldispenser



//Allow you to drag-drop disposal pipes and transit tubes into it
/obj/machinery/pipedispenser/disposal/MouseDrop_T(obj/structure/pipe, mob/living/user)
	if(!istype(user) || !CHECK_MOBILITY(user, MOBILITY_USE))
		return

	if (!istype(pipe, /obj/structure/disposalconstruct) && !istype(pipe, /obj/structure/c_transit_tube) && !istype(pipe, /obj/structure/c_transit_tube_pod))
		return

	if (get_dist(user, src) > 1 || get_dist(src,pipe) > 1 )
		return

	if (pipe.anchored)
		return

	qdel(pipe)

/obj/machinery/pipedispenser/disposal/interact(mob/user)

	var/dat = ""
	var/recipes = GLOB.disposal_pipe_recipes

	for(var/category in recipes)
		var/list/cat_recipes = recipes[category]
		dat += "<b>[category]:</b><br>"

		for(var/i in cat_recipes)
			var/datum/pipe_info/I = i
			dat += I.Render(src, user)

		dat += "<br>"

	user << browse("<HEAD><TITLE>[src]</TITLE>[PIPE_DISPENSER_STYLE]</HEAD><TT>[dat]</TT>", "window=pipedispenser;size=480x420")
	return


/obj/machinery/pipedispenser/disposal/Topic(href, href_list)
	if(..())
		return 1
	usr.set_machine(src)
	add_fingerprint(usr)
	if(href_list["dmake"])
		if(wait < world.time)
			var/p_type = text2path(href_list["dmake"])
			if (!verify_recipe(GLOB.disposal_pipe_recipes, p_type))
				return
			var/obj/structure/disposalconstruct/C = new (loc, p_type)

			if(!C.can_place())
				to_chat(usr, span_warning("There's not enough room to build that here!"))
				qdel(C)
				return
			if(href_list["dir"])
				C.setDir(text2num(href_list["dir"]))
			C.add_fingerprint(usr)
			C.update_icon()
			wait = world.time + 15
	return

//transit tube dispenser
//inherit disposal for the dragging proc
/obj/machinery/pipedispenser/disposal/transit_tube
	name = "transit tube dispenser"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "pipe_d"
	density = TRUE
	desc = "Dispenses pipes that will move beings around."
	circuit = /obj/item/circuitboard/machine/transitdispenser


/obj/machinery/pipedispenser/disposal/transit_tube/interact(mob/user)
	var/static/list/tube_ids = list(
		/obj/structure/c_transit_tube = TRANSIT_TUBE_STRAIGHT,
		/obj/structure/c_transit_tube/crossing = TRANSIT_TUBE_STRAIGHT_CROSSING,
		/obj/structure/c_transit_tube/curved = TRANSIT_TUBE_CURVED,
		/obj/structure/c_transit_tube/diagonal = TRANSIT_TUBE_DIAGONAL,
		/obj/structure/c_transit_tube/diagonal/crossing = TRANSIT_TUBE_DIAGONAL_CROSSING,
		/obj/structure/c_transit_tube/junction = TRANSIT_TUBE_JUNCTION,
		/obj/structure/c_transit_tube/station = TRANSIT_TUBE_STATION,
		/obj/structure/c_transit_tube/station/reverse = TRANSIT_TUBE_TERMINUS,
		/obj/structure/c_transit_tube_pod = TRANSIT_TUBE_POD,
	)

	var/dat = ""
	for(var/category in GLOB.transit_tube_recipes)
		dat += "<b>[category]:</b><br>"
		for(var/datum/pipe_info/I as anything in GLOB.transit_tube_recipes[category])
			var/tube = tube_ids[I.id]
			if(isnull(tube))
				continue
			dat += I.render_button(src, user, "tube=[tube]", I.name, I.dirtype == PIPE_ONEDIR ? SOUTH : NORTH)
		dat += "<br>"

	user << browse("<HEAD><TITLE>[src]</TITLE>[PIPE_DISPENSER_STYLE]</HEAD><TT>[dat]</TT>", "window=pipedispenser;size=480x420")
	return


/obj/machinery/pipedispenser/disposal/transit_tube/Topic(href, href_list)
	if(..())
		return 1
	usr.set_machine(src)
	add_fingerprint(usr)
	if(wait < world.time)
		if(href_list["tube"])
			var/tube_type = text2num(href_list["tube"])
			var/obj/structure/C
			switch(tube_type)
				if(TRANSIT_TUBE_STRAIGHT)
					C = new /obj/structure/c_transit_tube(loc)
				if(TRANSIT_TUBE_STRAIGHT_CROSSING)
					C = new /obj/structure/c_transit_tube/crossing(loc)
				if(TRANSIT_TUBE_CURVED)
					C = new /obj/structure/c_transit_tube/curved(loc)
				if(TRANSIT_TUBE_DIAGONAL)
					C = new /obj/structure/c_transit_tube/diagonal(loc)
				if(TRANSIT_TUBE_DIAGONAL_CROSSING)
					C = new /obj/structure/c_transit_tube/diagonal/crossing(loc)
				if(TRANSIT_TUBE_JUNCTION)
					C = new /obj/structure/c_transit_tube/junction(loc)
				if(TRANSIT_TUBE_STATION)
					C = new /obj/structure/c_transit_tube/station(loc)
				if(TRANSIT_TUBE_TERMINUS)
					C = new /obj/structure/c_transit_tube/station/reverse(loc)
				if(TRANSIT_TUBE_POD)
					C = new /obj/structure/c_transit_tube_pod(loc)
			if(C)
				C.add_fingerprint(usr)
			wait = world.time + 15
	return
