/obj/structure/lattice
	name = "lattice"
	desc = "A lightweight support lattice. These hold our station together."
	icon = 'icons/obj/smooth_structures/lattice.dmi'
	icon_state = "lattice"
	density = FALSE
	anchored = TRUE
	armor = ARMOR_VALUE_MEDIUM
	max_integrity = 50
	layer = LATTICE_LAYER //under pipes
	plane = FLOOR_PLANE
	var/number_of_rods = 1
	canSmoothWith = list(
		/obj/structure/lattice,
		/turf/open/floor,
		/turf/closed/wall,
		/obj/structure/falsewall)
	smooth = SMOOTH_MORE
	//	flags = CONDUCT_1

/obj/structure/lattice/examine(mob/user)
	. = ..()
	. += deconstruction_hints(user)

/obj/structure/lattice/proc/deconstruction_hints(mob/user)
	return "<span class='notice'>The rods look like they could be <b>cut</b>. There's space for more <i>rods</i> or a <i>tile</i>.</span>"

/obj/structure/lattice/Initialize(mapload)
	. = ..()
	for(var/obj/structure/lattice/LAT in loc)
		if(LAT != src)
			QDEL_IN(LAT, 0)

/obj/structure/lattice/blob_act(obj/structure/blob/B)
	return

/obj/structure/lattice/ratvar_act()
	new /obj/structure/lattice/clockwork(loc)

/obj/structure/lattice/attackby(obj/item/C, mob/user, params)
	if(resistance_flags & INDESTRUCTIBLE)
		return
	if(istype(C, /obj/item/wirecutters))
		to_chat(user, span_notice("Slicing [name] joints ..."))
		deconstruct()
	else
		var/turf/T = get_turf(src)
		return T.attackby(C, user) //hand this off to the turf instead (for building plating, catwalks, etc)

/obj/structure/lattice/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/rods(get_turf(src), number_of_rods)
	qdel(src)

/obj/structure/lattice/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(the_rcd.mode == RCD_FLOORWALL)
		return list("mode" = RCD_FLOORWALL, "delay" = 0, "cost" = 2)

/obj/structure/lattice/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	if(passed_mode == RCD_FLOORWALL)
		to_chat(user, span_notice("You build a floor."))
		var/turf/T = src.loc
		if(isspaceturf(T))
			T.PlaceOnTop(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
			qdel(src)
			return TRUE
	return FALSE

/obj/structure/lattice/singularity_pull(S, current_size)
	if(current_size >= STAGE_FOUR)
		deconstruct()

/obj/structure/lattice/clockwork
	name = "cog lattice"
	desc = "A lightweight support lattice. These hold the Justicar's station together."
	icon = 'icons/obj/smooth_structures/lattice_clockwork.dmi'

/obj/structure/lattice/clockwork/Initialize(mapload)
	canSmoothWith += /turf/open/indestructible/clock_spawn_room //list overrides are a terrible thing
	. = ..()
	ratvar_act()
	if(is_reebe(z))
		resistance_flags |= INDESTRUCTIBLE

/obj/structure/lattice/clockwork/ratvar_act()
	if(ISODD(x+y))
		icon = 'icons/obj/smooth_structures/lattice_clockwork_large.dmi'
		pixel_x = -9
		pixel_y = -9
	else
		icon = 'icons/obj/smooth_structures/lattice_clockwork.dmi'
		pixel_x = 0
		pixel_y = 0
	return TRUE

/obj/structure/lattice/catwalk
	name = "catwalk"
	desc = "A catwalk for easier EVA maneuvering and cable placement."
	icon = 'icons/obj/smooth_structures/catwalk.dmi'
	icon_state = "catwalk"
	number_of_rods = 2
	smooth = SMOOTH_TRUE
	canSmoothWith = null
	obj_flags = CAN_BE_HIT | BLOCK_Z_OUT_DOWN | BLOCK_Z_IN_UP

/obj/structure/lattice/catwalk/deconstruction_hints(mob/user)
	to_chat(user, "<span class='notice'>The supporting rods look like they could be <b>cut</b>.</span>")

/obj/structure/lattice/catwalk/ratvar_act()
	new /obj/structure/lattice/catwalk/clockwork(loc)

/obj/structure/lattice/catwalk/Move()
	var/turf/T = loc
	for(var/obj/structure/cable/C in T)
		C.deconstruct()
	..()

/obj/structure/lattice/catwalk/deconstruct()
	var/turf/T = loc
	for(var/obj/structure/cable/C in T)
		C.deconstruct()
	..()

/obj/structure/lattice/catwalk/clockwork
	name = "clockwork catwalk"
	icon = 'icons/obj/smooth_structures/catwalk_clockwork.dmi'
	canSmoothWith = list(/obj/structure/lattice,
	/turf/open/floor,
	/turf/open/indestructible/clock_spawn_room,
	/turf/closed/wall,
	/obj/structure/falsewall)
	smooth = SMOOTH_MORE

/obj/structure/lattice/catwalk/clockwork/Initialize(mapload)
	. = ..()
	ratvar_act()
	if(!mapload)
		new /obj/effect/temp_visual/ratvar/floor/catwalk(loc)
		new /obj/effect/temp_visual/ratvar/beam/catwalk(loc)
	if(is_reebe(z))
		resistance_flags |= INDESTRUCTIBLE

/obj/structure/lattice/catwalk/clockwork/ratvar_act()
	if(ISODD(x+y))
		icon = 'icons/obj/smooth_structures/catwalk_clockwork_large.dmi'
		pixel_x = -9
		pixel_y = -9
	else
		icon = 'icons/obj/smooth_structures/catwalk_clockwork.dmi'
		pixel_x = 0
		pixel_y = 0
	return TRUE

/obj/structure/lattice/lava
	name = "heatproof support lattice"
	desc = "A specialized support beam for building across lava. Watch your step."
	icon = 'icons/obj/smooth_structures/catwalk.dmi'
	icon_state = "catwalk"
	number_of_rods = 1
	color = "#5286b9ff"
	smooth = SMOOTH_TRUE
	canSmoothWith = null
	obj_flags = CAN_BE_HIT | BLOCK_Z_OUT_DOWN | BLOCK_Z_IN_UP
	resistance_flags = FIRE_PROOF | LAVA_PROOF

/obj/structure/lattice/lava/deconstruction_hints(mob/user)
	return "<span class='notice'>The rods look like they could be <b>cut</b>, but the <i>heat treatment will shatter off</i>. There's space for a <i>tile</i>.</span>"

/obj/structure/lattice/lava/attackby(obj/item/C, mob/user, params)
	. = ..()
	if(istype(C, /obj/item/stack/tile/plasteel))
		var/obj/item/stack/tile/plasteel/P = C
		if(P.use(1))
			to_chat(user, span_notice("You construct a floor plating, as lava settles around the rods."))
			playsound(src, 'sound/weapons/genhit.ogg', 50, TRUE)
			new /turf/open/floor/plating(locate(x, y, z))
		else
			to_chat(user, span_warning("You need one floor tile to build atop [src]."))
		return

/obj/structure/lattice/catwalk/invisible
	invisibility = INVISIBILITY_ABSTRACT
	smooth = SMOOTH_FALSE
	resistance_flags = INDESTRUCTIBLE

/obj/structure/lattice/corrugated
	name = "roof"
	desc = "Fence turned floor."
	icon = 'icons/obj/fence.dmi'
	icon_state = "corrugatedfence"

/obj/structure/lattice/catwalk/wing
	name = "wing"
	desc = "The wing of an airplane"
	icon = 'icons/turf/floors.dmi'
	icon_state = "airplane"
	plane = FLOOR_PLANE
	layer = LATTICE_LAYER
	smooth = SMOOTH_FALSE
	dir = WEST
	resistance_flags = INDESTRUCTIBLE

/obj/structure/lattice/catwalk/wing/flat
	name = "wing"
	icon_state = "airplaneflat"

/obj/structure/lattice/catwalk/wing/one
	name = "wing"
	icon_state = "airplane1"

/obj/structure/lattice/catwalk/wing/two
	name = "wing"
	icon_state = "airplane2"

/obj/structure/lattice/catwalk/wing/three
	name = "wing"
	icon_state = "airplane3"

/obj/structure/lattice/catwalk/wing/four
	name = "wing"
	icon_state = "airplane4"

/obj/structure/lattice/catwalk/wing/seven
	name = "wing"
	icon_state = "airplane7"

/obj/structure/lattice/catwalk/wing/eight
	name = "wing"
	icon_state = "airplane8"

/obj/structure/lattice/catwalk/wing/nine
	name = "wing"
	icon_state = "airplane9"

/obj/structure/lattice/catwalk/wing/ten
	name = "wing"
	icon_state = "airplane10"

/obj/structure/lattice/catwalk/wing/eleven
	name = "wing"
	icon_state = "airplane11"

/obj/structure/lattice/catwalk/wing/twelve
	name = "wing"
	icon_state = "airplane12"

/obj/structure/lattice/catwalk/wing/thirteen
	name = "wing"
	icon_state = "airplane13"

/obj/structure/lattice/catwalk/wing/fourteen
	name = "wing"
	icon_state = "airplane14"

/obj/structure/lattice/catwalk/wing/fifteen
	name = "wing"
	icon_state = "airplane15"
