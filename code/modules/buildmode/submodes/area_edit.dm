/datum/buildmode_mode/area_edit
	key = "areaedit"
	var/area/storedarea
	var/image/areaimage

/datum/buildmode_mode/area_edit/New()
	areaimage = image('icons/turf/areas.dmi', null, "yellow")
	..()

/datum/buildmode_mode/area_edit/enter_mode(datum/buildmode/BM)
	BM.holder.images += areaimage

/datum/buildmode_mode/area_edit/exit_mode(datum/buildmode/BM)
	areaimage.loc = null // de-color the area
	BM.holder.images -= areaimage
	return ..()

/datum/buildmode_mode/area_edit/Destroy()
	QDEL_NULL(areaimage)
	storedarea = null
	return ..()

/datum/buildmode_mode/area_edit/show_help(client/c)
	to_chat(c, span_notice("***********************************************************"))
	to_chat(c, span_notice("Left Mouse Button on obj/turf/mob  = Paint area"))
	to_chat(c, span_notice("Right Mouse Button on obj/turf/mob = Select area to paint"))
	to_chat(c, span_notice("Right Mouse Button on buildmode button = Create new area"))
	to_chat(c, span_notice("New areas should be /area/f13/custom (or a subtype) so the F13 power grid can see them."))
	to_chat(c, span_notice("Tiles inside a live junction-box zone can't be painted - unbolt the box first, then re-bolt it (or press RESCAN ZONES) afterwards."))
	to_chat(c, span_notice("***********************************************************"))

/datum/buildmode_mode/area_edit/change_settings(client/c)
	var/target_path = input(c, "Enter typepath:", "Typepath", "/area/f13/custom")
	var/areatype = text2path(target_path)
	// The F13 junction-box grid only understands /area/f13 and its subtypes
	// (f13_grid_immune, f13_jbox_zone, f13_custom, the power_change() override...).
	if(!ispath(areatype, /area/f13))
		to_chat(c, span_warning("Area must be /area/f13 or a subtype (use /area/f13/custom), otherwise the power grid can't see it."))
		return
	var/areaname = input(c, "Enter area name:", "Area name", "Area")
	if(!areaname || !length(areaname))
		return
	var/area/f13/new_area = new areatype
	new_area.power_equip = 0
	new_area.power_light = 0
	new_area.power_environ = 0
	new_area.always_unpowered = 0
	new_area.name = areaname
	// Runtime-made areas are scoped by datum (not typepath) by junction boxes,
	// and should show up in the global area lists like any other area.
	new_area.f13_custom = TRUE
	new_area.addSorted()
	storedarea = new_area
	areaimage.loc = storedarea // color our area

/datum/buildmode_mode/area_edit/handle_click(client/c, params, object)
	var/list/pa = params2list(params)
	var/left_click = pa.Find("left")
	var/right_click = pa.Find("right")
	var/turf/T = get_turf(object)
	if(!T)
		return

	// Tiles owned by a live junction-box zone are off-limits: moving them would
	// silently orphan them from the box. Unbolt the box, edit, then re-bolt / rescan.
	var/area/f13/current = get_area(T)
	if(istype(current) && current.f13_jbox_zone)
		to_chat(c, span_warning("That tile is part of a powered junction-box zone. Unbolt the box first, edit, then re-bolt it."))
		return

	if(left_click)
		if(!storedarea)
			to_chat(c, span_warning("Configure or select the area you want to paint first!"))
			return
		var/area/f13/stored_f13 = storedarea
		if(istype(stored_f13) && stored_f13.f13_jbox_zone)
			to_chat(c, span_warning("That area is a live junction-box zone and can't be painted with."))
			return
		if(get_area(T) != storedarea)
			log_admin("Build Mode: [key_name(c)] added [AREACOORD(T)] to [storedarea]")
			storedarea.contents.Add(T)
	else if(right_click)
		storedarea = get_area(T)
		areaimage.loc = storedarea // color our area
