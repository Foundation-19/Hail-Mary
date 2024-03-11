/datum/buildmode_mode
	var/key = "oops"

	var/datum/buildmode/BM

	// would corner selection work better as a component?
	var/use_corner_selection = FALSE
	var/list/preview
	var/turf/cornerA
	var/turf/cornerB

/datum/buildmode_mode/New(datum/buildmode/BM)
	src.BM = BM
	preview = list()
	return ..()

/datum/buildmode_mode/Destroy()
	cornerA = null
	cornerB = null
	QDEL_LIST(preview)
	preview = null
	return ..()

TYPE_PROC_REF(/datum/buildmode_mode, enter_mode)(datum/buildmode/BM)
	return

TYPE_PROC_REF(/datum/buildmode_mode, exit_mode)(datum/buildmode/BM)
	return

TYPE_PROC_REF(/datum/buildmode_mode, get_button_iconstate)()
	return "buildmode_[key]"

TYPE_PROC_REF(/datum/buildmode_mode, show_help)(client/c)
	CRASH("No help defined, yell at a coder")

TYPE_PROC_REF(/datum/buildmode_mode, change_settings)(client/c)
	to_chat(c, span_warning("There is no configuration available for this mode"))
	return

TYPE_PROC_REF(/datum/buildmode_mode, Reset)()
	deselect_region()

TYPE_PROC_REF(/datum/buildmode_mode, select_tile)(turf/T, corner_to_select)
	var/overlaystate
	BM.holder.images -= preview
	switch(corner_to_select)
		if(AREASELECT_CORNERA)
			overlaystate = "greenOverlay"
		if(AREASELECT_CORNERB)
			overlaystate = "blueOverlay"

	var/image/I = image('icons/turf/overlays.dmi', T, overlaystate)
	I.plane = ABOVE_LIGHTING_PLANE
	preview += I
	BM.holder.images += preview
	return T

TYPE_PROC_REF(/datum/buildmode_mode, highlight_region)(region)
	BM.holder.images -= preview
	for(var/t in region)
		var/image/I = image('icons/turf/overlays.dmi', t, "redOverlay")
		I.plane = ABOVE_LIGHTING_PLANE
		preview += I
	BM.holder.images += preview

TYPE_PROC_REF(/datum/buildmode_mode, deselect_region)()
	BM.holder.images -= preview
	preview.Cut()
	cornerA = null
	cornerB = null

TYPE_PROC_REF(/datum/buildmode_mode, handle_click)(client/c, params, object)
	var/list/pa = params2list(params)
	var/left_click = pa.Find("left")
	if(use_corner_selection)
		if(left_click)
			if(!cornerA)
				cornerA = select_tile(get_turf(object), AREASELECT_CORNERA)
				return
			if(cornerA && !cornerB)
				cornerB = select_tile(get_turf(object), AREASELECT_CORNERB)
				to_chat(c, span_boldwarning("Region selected, if you're happy with your selection left click again, otherwise right click."))
				return
			handle_selected_area(c, params)
			deselect_region()
		else
			to_chat(c, span_notice("Region selection canceled!"))
			deselect_region()
	return

TYPE_PROC_REF(/datum/buildmode_mode, handle_selected_area)(client/c, params)
