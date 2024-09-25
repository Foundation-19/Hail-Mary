// Mutable appearances are an inbuilt byond datastructure. Read the documentation on them by hitting F1 in DM.
// Basically use them instead of images for overlays/underlays and when changing an object's appearance if you're doing so with any regularity.
// Unless you need the overlay/underlay to have a different direction than the base object. Then you have to use an image due to a bug.

// Mutable appearances are children of images, just so you know.

#if DM_BUILD > 1642
/mutable_appearance/proc/New(mutable_appearance/to_copy)
	if(!to_copy)
		plane = FLOAT_PLANE
#else
/mutable_appearance/New(mutable_appearance/to_copy)
	..()
	if(!to_copy)
		plane = FLOAT_PLANE
#endif	// Fix for broken proc on latest version of BYOND.

// Helper similar to image()
/proc/mutable_appearance(icon, icon_state = "", layer = FLOAT_LAYER, plane = FLOAT_PLANE, color = "#FFFFFF")
	var/mutable_appearance/MA = new()
	MA.icon = icon
	MA.icon_state = icon_state
	MA.layer = layer
	MA.plane = plane
	MA.color = color
	return MA
