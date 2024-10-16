/turf/closed/wall/r_wall
	name = "reinforced wall"
	desc = "A huge chunk of reinforced metal used to separate rooms."
	icon = 'icons/turf/walls/reinforced_wall.dmi'
	icon_state = "r_wall"
	opacity = 1
	density = TRUE
	canSmoothWith = list(/turf/closed/wall/f13/ruins, /turf/closed/wall, /turf/closed/wall/r_wall, /turf/closed/wall/r_wall/rust)
	var/d_state = INTACT
	hardness = 60
	sheet_type = /obj/item/stack/sheet/plasteel
	sheet_amount = 1
	girder_type = /obj/structure/girder/reinforced
	explosion_block = 0
	rad_insulation = RAD_HEAVY_INSULATION

	max_integrity = 1200
	damage_deflection = 75
	demolition_mod_resist = 0.75

/turf/closed/wall/r_wall/get_armour_list()
	return list("melee" = 75,  "bullet" = 50, "laser" = 50, "energy" = 50, "bomb" = 75, "bio" = 100, "rad" = 100, "fire" = 80, "acid" = 70, "wound" = 0, "damage_threshold" = 0)

/turf/closed/wall/r_wall/deconstruction_hints(mob/user)
	switch(d_state)
		if(INTACT)
			return "<span class='notice'>The outer <b>grille</b> is fully intact.</span>"
		if(SUPPORT_LINES)
			return "<span class='notice'>The outer <i>grille</i> has been cut, and the support lines are <b>screwed</b> securely to the outer cover.</span>"
		if(COVER)
			return "<span class='notice'>The support lines have been <i>unscrewed</i>, and the metal cover is <b>welded</b> firmly in place.</span>"
		if(CUT_COVER)
			return "<span class='notice'>The metal cover has been <i>sliced through</i>, and is <b>connected loosely</b> to the girder.</span>"
		if(ANCHOR_BOLTS)
			return "<span class='notice'>The outer cover has been <i>pried away</i>, and the bolts anchoring the support rods are <b>wrenched</b> in place.</span>"
		if(SUPPORT_RODS)
			return "<span class='notice'>The bolts anchoring the support rods have been <i>loosened</i>, but are still <b>welded</b> firmly to the girder.</span>"
		if(SHEATH)
			return "<span class='notice'>The support rods have been <i>sliced through</i>, and the outer sheath is <b>connected loosely</b> to the girder.</span>"

/turf/closed/wall/r_wall/devastate_wall()
	new sheet_type(src, sheet_amount)
	new /obj/item/stack/sheet/metal(src, 2)

/turf/closed/wall/r_wall/try_destroy(obj/item/I, mob/user, turf/T)
	return FALSE

/turf/closed/wall/r_wall/try_decon(obj/item/W, mob/user, turf/T)
	//DECONSTRUCTION
	switch(d_state)
		if(INTACT)
			if(istype(W, /obj/item/wirecutters))
				W.play_tool_sound(src, 100)
				d_state = SUPPORT_LINES
				update_icon()
				to_chat(user, span_notice("You cut the outer grille."))
				return 1

		if(SUPPORT_LINES)
			if(istype(W, /obj/item/screwdriver))
				to_chat(user, span_notice("You begin unsecuring the support lines..."))
				if(W.use_tool(src, user, 40, volume=100))
					if(!istype(src, /turf/closed/wall/r_wall) || d_state != SUPPORT_LINES)
						return 1
					d_state = COVER
					update_icon()
					to_chat(user, span_notice("You unsecure the support lines."))
				return 1

			else if(istype(W, /obj/item/wirecutters))
				W.play_tool_sound(src, 100)
				d_state = INTACT
				update_icon()
				to_chat(user, span_notice("You repair the outer grille."))
				return 1

		if(COVER)
			if(istype(W, /obj/item/weldingtool) || istype(W, /obj/item/gun/energy/plasmacutter))
				if(!W.tool_start_check(user, amount=0))
					return
				to_chat(user, span_notice("You begin slicing through the metal cover..."))
				if(W.use_tool(src, user, 60, volume=100))
					if(!istype(src, /turf/closed/wall/r_wall) || d_state != COVER)
						return 1
					d_state = CUT_COVER
					update_icon()
					to_chat(user, span_notice("You press firmly on the cover, dislodging it."))
				return 1

			if(istype(W, /obj/item/screwdriver))
				to_chat(user, span_notice("You begin securing the support lines..."))
				if(W.use_tool(src, user, 40, volume=100))
					if(!istype(src, /turf/closed/wall/r_wall) || d_state != COVER)
						return 1
					d_state = SUPPORT_LINES
					update_icon()
					to_chat(user, span_notice("The support lines have been secured."))
				return 1

		if(CUT_COVER)
			if(istype(W, /obj/item/crowbar))
				to_chat(user, span_notice("You struggle to pry off the cover..."))
				if(W.use_tool(src, user, 100, volume=100))
					if(!istype(src, /turf/closed/wall/r_wall) || d_state != CUT_COVER)
						return 1
					d_state = ANCHOR_BOLTS
					update_icon()
					to_chat(user, span_notice("You pry off the cover."))
				return 1

			if(istype(W, /obj/item/weldingtool))
				if(!W.tool_start_check(user, amount=0))
					return
				to_chat(user, span_notice("You begin welding the metal cover back to the frame..."))
				if(W.use_tool(src, user, 60, volume=100))
					if(!istype(src, /turf/closed/wall/r_wall) || d_state != CUT_COVER)
						return TRUE
					d_state = COVER
					update_icon()
					to_chat(user, span_notice("The metal cover has been welded securely to the frame."))
				return 1

		if(ANCHOR_BOLTS)
			if(istype(W, /obj/item/wrench))
				to_chat(user, span_notice("You start loosening the anchoring bolts which secure the support rods to their frame..."))
				if(W.use_tool(src, user, 40, volume=100))
					if(!istype(src, /turf/closed/wall/r_wall) || d_state != ANCHOR_BOLTS)
						return 1
					d_state = SUPPORT_RODS
					update_icon()
					to_chat(user, span_notice("You remove the bolts anchoring the support rods."))
				return 1

			if(istype(W, /obj/item/crowbar))
				to_chat(user, span_notice("You start to pry the cover back into place..."))
				if(W.use_tool(src, user, 20, volume=100))
					if(!istype(src, /turf/closed/wall/r_wall) || d_state != ANCHOR_BOLTS)
						return 1
					d_state = CUT_COVER
					update_icon()
					to_chat(user, span_notice("The metal cover has been pried back into place."))
				return 1

		if(SUPPORT_RODS)
			if(istype(W, /obj/item/weldingtool) || istype(W, /obj/item/gun/energy/plasmacutter))
				if(!W.tool_start_check(user, amount=0))
					return
				to_chat(user, span_notice("You begin slicing through the support rods..."))
				if(W.use_tool(src, user, 100, volume=100))
					if(!istype(src, /turf/closed/wall/r_wall) || d_state != SUPPORT_RODS)
						return 1
					d_state = SHEATH
					update_icon()
					to_chat(user, span_notice("You slice through the support rods."))
				return 1

			if(istype(W, /obj/item/wrench))
				to_chat(user, span_notice("You start tightening the bolts which secure the support rods to their frame..."))
				W.play_tool_sound(src, 100)
				if(W.use_tool(src, user, 40))
					if(!istype(src, /turf/closed/wall/r_wall) || d_state != SUPPORT_RODS)
						return 1
					d_state = ANCHOR_BOLTS
					update_icon()
					to_chat(user, span_notice("You tighten the bolts anchoring the support rods."))
				return 1

		if(SHEATH)
			if(istype(W, /obj/item/crowbar))
				to_chat(user, span_notice("You struggle to pry off the outer sheath..."))
				if(W.use_tool(src, user, 100, volume=100))
					if(!istype(src, /turf/closed/wall/r_wall) || d_state != SHEATH)
						return 1
					to_chat(user, span_notice("You pry off the outer sheath."))
					dismantle_wall()
				return 1

			if(istype(W, /obj/item/weldingtool))
				if(!W.tool_start_check(user, amount=0))
					return
				to_chat(user, span_notice("You begin welding the support rods back together..."))
				if(W.use_tool(src, user, 100, volume=100))
					if(!istype(src, /turf/closed/wall/r_wall) || d_state != SHEATH)
						return TRUE
					d_state = SUPPORT_RODS
					update_icon()
					to_chat(user, span_notice("You weld the support rods back together."))
				return 1
	return 0

/turf/closed/wall/r_wall/update_icon()
	. = ..()
	if(d_state != INTACT)
		smooth = SMOOTH_FALSE
		clear_smooth_overlays()
	else
		smooth = SMOOTH_TRUE
		queue_smooth_neighbors(src)
		queue_smooth(src)

/turf/closed/wall/r_wall/update_icon_state()
	if(d_state != INTACT)
		icon_state = "r_wall-[d_state]"
	else
		icon_state = "r_wall"

/turf/closed/wall/r_wall/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_FIVE)
		if(prob(30))
			dismantle_wall()

/turf/closed/wall/r_wall/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(the_rcd.canRturf)
		return ..()


/turf/closed/wall/r_wall/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	if(the_rcd.canRturf)
		return ..()

/turf/closed/wall/r_wall/rust_heretic_act()
	if(prob(50))
		return
	if(prob(70))
		new /obj/effect/temp_visual/glowing_rune(src)
	ChangeTurf(/turf/closed/wall/r_wall/rust)

/turf/closed/wall/r_wall/syndicate
	name = "hull"
	desc = "The armored hull of an ominous looking ship."
	icon = 'icons/turf/walls/plastitanium_wall.dmi'
	icon_state = "map-shuttle"
	explosion_block = 0
	sheet_type = /obj/item/stack/sheet/mineral/plastitanium
	smooth = SMOOTH_MORE|SMOOTH_DIAGONAL
	canSmoothWith = list(/turf/closed/wall/r_wall/syndicate, /turf/closed/wall/mineral/plastitanium, /obj/machinery/door/airlock/shuttle, /obj/machinery/door/airlock, /obj/structure/window/plastitanium, /obj/structure/shuttle/engine, /obj/structure/falsewall/plastitanium)

/turf/closed/wall/r_wall/syndicate/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	return FALSE

/turf/closed/wall/r_wall/syndicate/nodiagonal
	smooth = SMOOTH_MORE
	icon_state = "map-shuttle_nd"

/turf/closed/wall/r_wall/syndicate/nosmooth
	icon = 'icons/turf/shuttle.dmi'
	icon_state = "wall"
	smooth = SMOOTH_FALSE

/turf/closed/wall/r_wall/syndicate/overspace
	icon_state = "map-overspace"
	fixed_underlay = list("space"=1)

/////////////////////Pirate Ship walls/////////////////////

/turf/closed/wall/r_wall/syndicate/pirate
	desc = "Yarr just try to blow this to smithereens!"
	explosion_block = 2
	canSmoothWith = list(/turf/closed/wall/r_wall/syndicate/pirate, /obj/machinery/door/airlock/shuttle, /obj/machinery/door/airlock, /obj/structure/window/plastitanium/pirate, /obj/structure/shuttle/engine, /obj/structure/falsewall/plastitanium)

/turf/closed/wall/r_wall/syndicate/pirate/nodiagonal
	smooth = SMOOTH_MORE
	icon_state = "map-shuttle_nd"

/turf/closed/wall/r_wall/syndicate/pirate/nosmooth
	icon = 'icons/turf/shuttle.dmi'
	icon_state = "wall"

/turf/closed/wall/r_wall/syndicate/pirate/overspace
	icon_state = "map-overspace"
	fixed_underlay = list("space"=1)
