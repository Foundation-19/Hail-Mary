/// Base for machines that should only work when the wasteland grid is online.
/// This fork doesn't guarantee TG hooks like UPDATE_ICON / update_appearance etc.
/// So we implement our own refresh proc and call it from the grid code.

/obj/machinery/f13_grid_gated
	parent_type = /obj/machinery
	var/requires_wasteland_grid = TRUE

/obj/machinery/f13_grid_gated/proc/wasteland_grid_ok()
	return !!GLOB.wasteland_grid_online

/obj/machinery/f13_grid_gated/powered()
	if(requires_wasteland_grid && !wasteland_grid_ok())
		return FALSE
	return ..()

/obj/machinery/f13_grid_gated/is_operational()
	. = ..()
	if(!.)
		return FALSE
	if(requires_wasteland_grid && !wasteland_grid_ok())
		return FALSE
	return TRUE

/obj/machinery/f13_grid_gated/proc/on_wasteland_grid_change()
	if(hascall(src, "power_change"))
		call(src, "power_change")()

	if(hascall(src, "update_icon"))
		call(src, "update_icon")()
	else if(hascall(src, "UpdateIcon"))
		call(src, "UpdateIcon")()

	if(hascall(src, "update_appearance"))
		call(src, "update_appearance")()
