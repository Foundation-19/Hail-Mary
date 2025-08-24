/turf/open/water
	gender = PLURAL
	name = "water"
	desc = "Shallow water."
	icon = 'icons/turf/floors.dmi'
	icon_state = "riverwater_motion"
	baseturfs = /turf/open/indestructible/ground/inside/mountain
	initial_gas_mix = OPENTURF_DEFAULT_ATMOS
	planetary_atmos = TRUE
	slowdown = 2
	bullet_sizzle = TRUE
	bullet_bounce_sound = null //needs a splashing sound one day.
	var/obj/effect/overlay/water/watereffect

	footstep = FOOTSTEP_WATER
	barefootstep = FOOTSTEP_WATER
	clawfootstep = FOOTSTEP_WATER
	heavyfootstep = FOOTSTEP_WATER

	//fortuna edit
	depth = 1 // Higher numbers indicates deeper water.




// Fortuna edit. Below is Largely ported from citadels HRP branch

/turf/open/water/Initialize()
	. = ..()
	update_icon()

/turf/open/water/update_icon()
	. = ..()

/turf/open/water/Entered(atom/movable/AM, atom/oldloc)
	if(istype(AM, /mob/living))
		var/mob/living/L = AM
		L.update_water()
		if(L.check_submerged() <= 0)
			return
		if(!istype(oldloc, /turf/open/water))
			to_chat(L, span_warning("You get drenched in water!"))
	AM.water_act(5)
	..()

/turf/open/water/Exited(atom/movable/AM, atom/newloc)
	if(istype(AM, /mob/living))
		var/mob/living/L = AM
		L.update_water()
		if(L.check_submerged() <= 0)
			return
		if(!istype(newloc, /turf/open/water))
			to_chat(L, span_warning("You climb out of \the [src]."))
	..()

/mob/living/proc/check_submerged()
	if(buckled)
		return 0
	if(locate(/obj/structure/lattice/catwalk) in loc)
		return 0
	loc = get_turf(src)
	if(istype(loc, /turf/open/indestructible/ground/outside/water) || istype(loc, /turf/open/water))
		var/turf/open/T = loc
		return T.depth
	return 0

// Use this to have things react to having water applied to them.
/atom/movable/proc/water_act(amount)
	return

/mob/living/water_act(amount)
	if(ishuman(src))
		var/mob/living/carbon/human/drownee = src
		if(!drownee || drownee.stat == DEAD)
			return
		if(drownee.resting && !drownee.internal)
			if(drownee.stat != CONSCIOUS)
				drownee.adjustOxyLoss(1)
			else
				drownee.adjustOxyLoss(1)
				if(prob(35))
					to_chat(drownee, span_danger("You're drowning!"))
	adjust_fire_stacks(-amount * 5)
	for(var/atom/movable/AM in contents)
		AM.water_act(amount)

/turf/open/water/deep
	name = "shore"
	desc = "Shallow water."
	icon = 'icons/turf/floors.dmi'
	icon_state = "riverwater"
	sunlight_state = SUNLIGHT_SOURCE
	depth = 2

/turf/open/water/deep/Initialize(mapload)
	. = ..()
	watereffect = new /obj/effect/overlay/water(src)

/turf/open/water/cavern
	name = "cavern"
	desc = "Shallow water."
	icon = 'icons/turf/floors.dmi'
	icon_state = "riverwater"
	sunlight_state = NO_SUNLIGHT
	depth = 0

/turf/open/water/cavern/deep
	name = "cavern"
	depth = 2

/turf/open/water/cavern/deep/Initialize(mapload)
	. = ..()
	watereffect = new /obj/effect/overlay/water(src)

/turf/open/water/cavern/diagonal
	name = "cavern"
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "cavernfloor"
	layer = VISIBLE_FROM_ABOVE_LAYER

/turf/open/water/cavern/diagonal/alt
	name = "cavern"
	dir = WEST

/turf/open/water/cavern/river
	name = "river"
	icon_state = "riverwater_motion"

/turf/open/water/cavern/sewer
	name = "river"
	icon = 'icons/fallout/turfs/ground.dmi'
	icon_state = "riverwateruhh"

/turf/open/water/cavern/sewer/no_slowdown
	name = "river"
	slowdown = FALSE

/turf/open/water/shore
	name = "shore"
	desc = "Shallow water."
	icon = 'icons/turf/pool.dmi'
	icon_state = "watersedge"
	sunlight_state = SUNLIGHT_SOURCE
	depth = 1

/turf/open/water/shore/northwest
	name = "shore"
	icon_state = "blendednorthwest"

/turf/open/water/shore/north
	name = "shore"
	icon_state = "blendednorth"

/turf/open/water/shore/northeast
	name = "shore"
	icon_state = "blendednortheast"

/turf/open/water/shore/east
	name = "shore"
	icon_state = "blendedeast"

/turf/open/water/shore/southeast
	name = "shore"
	icon_state = "blendedsoutheast"

/turf/open/water/shore/southwest
	name = "shore"
	icon_state = "blendedsouthwest"

/turf/open/water/shore/west
	name = "shore"
	icon_state = "blendedwest"

/turf/open/water/channel
	name = "channel"
	desc = "Shallow water."
	icon = 'icons/turf/pool.dmi'
	icon_state = "channel"
	sunlight_state = SUNLIGHT_SOURCE
	depth = 2

/turf/open/water/channeldark
	name = "channel"
	desc = "Shallow water."
	icon = 'icons/turf/pool.dmi'
	icon_state = "channel"
	sunlight_state = NO_SUNLIGHT
	depth = 2

/turf/open/water/watersedge
	name = "shore"
	desc = "Shallow water."
	icon = 'icons/turf/pool.dmi'
	icon_state = "watersedge1"
	sunlight_state = SUNLIGHT_SOURCE
	depth = 1

/turf/open/water/watersedge/north
	dir = NORTH

/turf/open/water/watersedge/east
	dir = EAST

/turf/open/water/watersedge/south
	dir = SOUTH

/turf/open/water/watersedge/west
	dir = WEST

/turf/open/water/watersedge/northwest
	icon_state = "watersedge2"
	dir = NORTHWEST

/turf/open/water/watersedge/northeast
	icon_state = "watersedge2"
	dir = NORTHEAST

/turf/open/water/watersedge/southeast
	icon_state = "watersedge2"
	dir = SOUTHEAST

/turf/open/water/watersedge/southwest
	icon_state = "watersedge2"
	dir = SOUTHWEST

/turf/open/water/vrocean
	icon = 'icons/misc/beach.dmi'
	icon_state = "water"
	plane = ABOVE_WALL_PLANE

/turf/open/water/vrocean/Initialize(mapload)
	. = ..()
	watereffect = new /obj/effect/overlay/water(src)
