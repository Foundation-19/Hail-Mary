//Fallout 13 general destructible floor directory

/turf/open/floor/f13
	name = "floor"
	planetary_atmos = 1
	icon_state = "floor"
	icon_regular_floor = "floor"
	icon_plating = "plating"
	icon = 'icons/fallout/turfs/floors.dmi'

/turf/open/floor/f13/ReplaceWithLattice()
	ChangeTurf(baseturfs)

/turf/open/floor/f13/wood
	icon_state = "housewood1"
	icon = 'icons/fallout/turfs/ground.dmi'
	floor_tile = /obj/item/stack/tile/wood
	icon_plating = "housebase"
//	step_sounds = list("human" = "woodfootsteps")
	broken_states = list("housewood1-broken", "housewood2-broken", "housewood3-broken", "housewood4-broken")

/turf/open/floor/f13/wood/New()
	..()
	if(prob(5))
		broken = 1
		icon_state = pick(broken_states)
	else
		icon_state = "housewood[rand(1,4)]"

/turf/open/floor/f13/wood/make_plating()
	return ChangeTurf(/turf/open/floor/plating/wooden)

/turf/open/floor/f13/wood/attackby(obj/item/C, mob/user, params)
	if(..())
		return
	if(istype(C, /obj/item/screwdriver))
		if(broken || burnt)
			new /obj/item/stack/sheet/mineral/wood(src)
		else
			new floor_tile(src)
		to_chat(user, span_danger("You unscrew the planks."))
		make_plating()
		playsound(src, C.usesound, 80, 1)
		return

/turf/open/floor/f13/lit
	sunlight_state = SUNLIGHT_SOURCE

/turf/open/floor/f13/green
	icon_state = "hydrofloor"

/turf/open/floor/f13/green/lit
	name = "floor"
	sunlight_state = SUNLIGHT_SOURCE

/turf/open/floor/f13/blue
	icon_state = "darkdirty"

/turf/open/floor/f13/blue/lit
	name = "floor"
	sunlight_state = SUNLIGHT_SOURCE

/turf/open/floor/f13/red
	icon_state = "reddirtyfull"

/turf/open/floor/f13/red/lit
	name = "floor"
	sunlight_state = SUNLIGHT_SOURCE

/turf/open/floor/f13/yellow
	icon_state = "yellowdirtyfull"

/turf/open/floor/f13/yellow/lit
	name = "floor"
	sunlight_state = SUNLIGHT_SOURCE

/turf/open/floor/f13/dark
	name = "floor"
	icon_state = "darkyellowfull"

/turf/open/floor/f13/dark/lit
	sunlight_state = SUNLIGHT_SOURCE

/turf/open/floor/f13/rusty
	icon_state = "floorrusty"

/turf/open/floor/f13/rusty/lit
	sunlight_state = SUNLIGHT_SOURCE

/turf/open/floor/f13/paintwall
	name = "paint wall"
	icon = 'icons/fallout/turfs/walls/tunnel.dmi'
	icon_state = "tunnel0"
	icon_type_smooth = "tunnel"
	opacity = TRUE
	smooth = SMOOTH_OLD
	sunlight_state = SUNLIGHT_SOURCE
	canSmoothWith = list(/turf/open/floor/f13/paintwall)
	var/blocked_dir = list(NORTH, EAST, NORTHEAST)

/turf/open/floor/f13/paintwall/CanPass(atom/movable/mover, border_dir)
	. = ..()  // capture parent result FIRST
	if(istype(mover) && (mover.pass_flags & PASSTABLE))
		return !density
	if(istype(mover) && (mover.dir in blocked_dir))
		return density
	return TRUE

