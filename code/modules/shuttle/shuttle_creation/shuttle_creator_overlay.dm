/*
 * Manages the overlays for the shuttle creator drone.
*/

/datum/shuttle_creator_overlay_holder
	var/client/holder
	var/list/images = list()
	var/list/turfs = list()

TYPE_PROC_REF(/datum/shuttle_creator_overlay_holder, add_client)(client/C)
	holder = C
	holder.images += images

TYPE_PROC_REF(/datum/shuttle_creator_overlay_holder, remove_client)()
	if(holder)
		holder.images -= images
		holder = null

TYPE_PROC_REF(/datum/shuttle_creator_overlay_holder, clear_highlights)()
	if(holder)
		holder.images -= images
	images.Cut()
	turfs.Cut()

TYPE_PROC_REF(/datum/shuttle_creator_overlay_holder, create_hightlight)(turf/T)
	if(T in turfs)
		return
	var/image/I = image('icons/turf/overlays.dmi', T, "greenOverlay")
	I.plane = ABOVE_LIGHTING_PLANE
	images += I
	holder.images += I
	turfs += T

TYPE_PROC_REF(/datum/shuttle_creator_overlay_holder, remove_hightlight)(turf/T)
	if(!(T in turfs))
		return
	turfs -= T
	holder.images -= images
	for(var/image/I in images)
		if(get_turf(I) != T)
			continue
		images -= I
	holder.images += images

TYPE_PROC_REF(/datum/shuttle_creator_overlay_holder, highlight_area)(list/turfs)
	for(var/turf/T in turfs)
		highlight_turf(T)

TYPE_PROC_REF(/datum/shuttle_creator_overlay_holder, highlight_turf)(turf/T)
	create_hightlight(T)

TYPE_PROC_REF(/datum/shuttle_creator_overlay_holder, unhighlight_turf)(turf/T)
	remove_hightlight(T)
