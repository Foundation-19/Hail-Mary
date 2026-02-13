/obj/structure/handrail/g_central
	name = "handrail"
	desc = "Old, rusted metal handrails. The green paint is chipping off in spots."
	icon = 'icons/obj/obstacles.dmi'
	icon_state = "g_handrail"
	density = FALSE
	anchored = TRUE
	pixel_y = 0
	
	max_integrity = 150
	integrity_failure = 0.5

/obj/structure/handrail/g_central/Initialize()
	. = ..()
	layer = 4.2
	
	switch(dir)
		if(NORTH)
			pixel_y = 23
		if(SOUTH)
			pixel_y = -16
		if(EAST)
			pixel_x = 20
		if(WEST)
			pixel_x = -20

// Block movement in our direction
/obj/structure/handrail/g_central/CanPass(atom/movable/mover, border_dir)
	if(border_dir == dir)
		return FALSE
	return ..()

/obj/structure/handrail/g_end
	name = "handrail end"
	desc = "Heavy-duty metal handrail ends here.<br>You can pass now!"
	icon = 'icons/obj/obstacles.dmi'
	icon_state = "g_handrail_end"
	density = 0
	anchored = 1
	pixel_y = -9

/obj/structure/handrail/g_end/New()
	if (dir>2)
		layer = 4.2
