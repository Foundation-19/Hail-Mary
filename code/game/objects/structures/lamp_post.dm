// The lighting system
//
// consists of light fixtures (/obj/machinery/light) and light tube/bulb items (/obj/item/light)

//#define LIGHT_EMERGENCY_POWER_USE 0.2 //How much power emergency lights will consume per tick
// status values shared between lighting fixtures and items
#define LIGHT_OK 0
#define LIGHT_EMPTY 1
#define LIGHT_BROKEN 2
#define LIGHT_BURNED 3

/obj/structure/light_construct/lamp_post
	name = "lamp post frame"
	desc = "A lamp post under construction."
	icon = 'icons/fallout/objects/96x160_street_decore.dmi'
	icon_state = "nvlamp-singles"
	max_integrity = 200
	sheets_refunded = 5
	layer = GASFIRE_LAYER
	plane = MOB_PLANE
	density = TRUE
	pixel_x = -32
	var/lamp_post_variant = "singles"

/obj/structure/light_construct/lamp_post/doubles
	lamp_post_variant = "doubles - straight"
	icon_state = "nvlamp-straight-doubles"

/obj/structure/light_construct/lamp_post/doubles/bent
	lamp_post_variant = "doubles - corner"
	icon_state = "nvlamp-corner-doubles"

/obj/structure/light_construct/lamp_post/triples
	lamp_post_variant = "triples"
	icon_state = "nvlamp-triples"

/obj/structure/light_construct/lamp_post/quadra
	lamp_post_variant = "quadra"
	icon_state = "nvlamp-quadra"

/obj/structure/light_construct/lamp_post/attackby(obj/item/W, mob/user, params)
	add_fingerprint(user)
	if(istype(W, /obj/item/stock_parts/cell))
		if(!cell_connectors)
			to_chat(user, span_warning("This [name] can't support a power cell!"))
			return
		if(HAS_TRAIT(W, TRAIT_NODROP))
			to_chat(user, span_warning("[W] is stuck to your hand!"))
			return
		user.dropItemToGround(W)
		if(cell)
			user.visible_message(span_notice("[user] swaps [W] out for [src]'s cell."), \
			span_notice("You swap [src]'s power cells."))
			cell.forceMove(drop_location())
			user.put_in_hands(cell)
		else
			user.visible_message(span_notice("[user] hooks up [W] to [src]."), \
			span_notice("You add [W] to [src]."))
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		W.forceMove(src)
		cell = W
		add_fingerprint(user)
		return
	switch(stage)
		if(1)
			if(istype(W, /obj/item/wrench))
				to_chat(usr, span_notice("You begin deconstructing [src]..."))
				if (W.use_tool(src, user, 30, volume=50))
					new /obj/item/stack/sheet/metal(drop_location(), sheets_refunded)
					user.visible_message("[user.name] deconstructs [src].", \
						span_notice("You deconstruct [src]."), span_italic("You hear a ratchet."))
					playsound(src.loc, 'sound/items/deconstruct.ogg', 75, 1)
					qdel(src)
				return

			if(istype(W, /obj/item/stack/cable_coil))
				if(W.use_tool(src, user, 0, 1, skill_gain_mult = TRIVIAL_USE_TOOL_MULT))
					icon_state = icon_state
					stage = 2
					user.visible_message("[user.name] adds wires to [src].", \
						span_notice("You add wires to [src]."))
				else
					to_chat(user, span_warning("You need one length of cable to wire [src]!"))
				return
		if(2)
			if(istype(W, /obj/item/wrench))
				to_chat(usr, span_warning("You have to remove the wires first!"))
				return

			if(istype(W, /obj/item/wirecutters))
				stage = 1
				icon_state = icon_state
				new /obj/item/stack/cable_coil(drop_location(), 1, "red")
				user.visible_message("[user.name] removes the wiring from [src].", \
					span_notice("You remove the wiring from [src]."), span_italic("You hear clicking."))
				W.play_tool_sound(src, 100)
				return

			if(istype(W, /obj/item/screwdriver))
				user.visible_message("[user.name] closes [src]'s casing.", \
					span_notice("You close [src]'s casing."), span_italic("You hear screwing."))
				W.play_tool_sound(src, 75)
				switch(lamp_post_variant)
					if("singles")
						newlight = new /obj/machinery/light/lamp_post/built(loc)
					if("doubles - straight")
						newlight = new /obj/machinery/light/lamp_post/doubles/built(loc)
					if("doubles - corner")
						newlight = new /obj/machinery/light/lamp_post/doubles/bent/built(loc)
					if("triples")
						newlight = new /obj/machinery/light/lamp_post/triples/built(loc)
					if("quadra")
						newlight = new /obj/machinery/light/lamp_post/quadra/built(loc)
				newlight.setDir(dir)
				transfer_fingerprints_to(newlight)
				if(cell)
					newlight.cell = cell
					cell.forceMove(newlight)
					cell = null
				qdel(src)
				return
	return ..()

/obj/machinery/light/lamp_post
	name = "lamp post"
	desc = "A relic of the past that continues to illuminate the darkness."
	icon = 'icons/fallout/objects/96x160_street_decore.dmi'
	base_state = "nvlamp-singles"
	icon_state = "nvlamp-singles-on"
	layer = GASFIRE_LAYER
	plane = MOB_PLANE
	max_integrity = 100
	brightness = 15
	bulb_colour = "#fff598"
	flickering = TRUE
	flicker_chance = 100/2
	density = TRUE
	pixel_x = -32
	var/lamp_post_variant = "singles"

/obj/machinery/light/lamp_post/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/obj/structure/light_construct/newlight = null
		var/cur_stage = 2
		if(!disassembled)
			cur_stage = 1
		switch(lamp_post_variant)
			if("singles")
				newlight = new /obj/structure/light_construct/lamp_post(src.loc)
			if("doubles - straight")
				newlight = new /obj/structure/light_construct/lamp_post/doubles(src.loc)
			if("doubles - corner")
				newlight = new /obj/structure/light_construct/lamp_post/doubles/bent(src.loc)
			if("triples")
				newlight = new /obj/structure/light_construct/lamp_post/triples(src.loc)
			if("quadra")
				newlight = new /obj/structure/light_construct/lamp_post/quadra(src.loc)
		newlight.icon_state = base_state
		newlight.setDir(src.dir)
		newlight.stage = cur_stage
		if(!disassembled)
			newlight.obj_integrity = newlight.max_integrity * 0.5
			if(status != LIGHT_BROKEN)
				break_light_tube()
			if(status != LIGHT_EMPTY)
				drop_light_tube()
			new /obj/item/stack/cable_coil(loc, 1, "red")
		transfer_fingerprints_to(newlight)
		if(cell)
			newlight.cell = cell
			cell.forceMove(newlight)
			cell = null
	qdel(src)

/obj/machinery/light/lamp_post/built
	start_with_cell = FALSE
	icon_state = "nvlamp-singles"

/obj/machinery/light/lamp_post/built/Initialize()
	. = ..()
	status = LIGHT_EMPTY
	update(0)

/obj/machinery/light/lamp_post/broken
	status = LIGHT_BROKEN
	icon_state = "nvlamp-singles"

/obj/machinery/light/lamp_post/update_icon_state()
	switch(status)		// set icon_states
		if(LIGHT_OK)
			icon_state = "[base_state]-on"
		if(LIGHT_EMPTY)
			icon_state = "[base_state]"
		if(LIGHT_BURNED)
			icon_state = "[base_state]"
		if(LIGHT_BROKEN)
			icon_state = "[base_state]"

/obj/machinery/light/lamp_post/doubles
	base_state = "nvlamp-straight-doubles"
	icon_state = "nvlamp-straight-doubles-on"
	lamp_post_variant = "doubles - straight"

/obj/machinery/light/lamp_post/doubles/built
	start_with_cell = FALSE
	icon_state = "nvlamp-straight-doubles"

/obj/machinery/light/lamp_post/doubles/built/Initialize()
	. = ..()
	status = LIGHT_EMPTY
	update(0)

/obj/machinery/light/lamp_post/doubles/broken
	status = LIGHT_BROKEN
	icon_state = "nvlamp-straight-doubles"


/obj/machinery/light/lamp_post/doubles/bent
	base_state = "nvlamp-corner-doubles"
	icon_state = "nvlamp-corner-doubles-on"
	lamp_post_variant = "doubles - corner"

/obj/machinery/light/lamp_post/doubles/bent/built
	start_with_cell = FALSE
	icon_state = "nvlamp-corner-doubles"

/obj/machinery/light/lamp_post/doubles/bent/built/Initialize()
	. = ..()
	status = LIGHT_EMPTY
	update(0)

/obj/machinery/light/lamp_post/doubles/bent/broken
	status = LIGHT_BROKEN
	icon_state = "nvlamp-corner-doubles"

/obj/machinery/light/lamp_post/triples
	base_state = "nvlamp-triples"
	icon_state = "nvlamp-triples-on"
	lamp_post_variant = "triples"

/obj/machinery/light/lamp_post/triples/built
	start_with_cell = FALSE
	icon_state = "nvlamp-triples"

/obj/machinery/light/lamp_post/triples/built/Initialize()
	. = ..()
	status = LIGHT_EMPTY
	update(0)

/obj/machinery/light/lamp_post/triples/broken
	status = LIGHT_BROKEN
	icon_state = "nvlamp-triples"

/obj/machinery/light/lamp_post/quadra
	base_state = "nvlamp-quadra"
	icon_state = "nvlamp-quadra-on"
	lamp_post_variant = "quadra"

/obj/machinery/light/lamp_post/quadra/built
	start_with_cell = FALSE
	icon_state = "nvlamp-quadra"

/obj/machinery/light/lamp_post/quadra/built/Initialize()
	. = ..()
	status = LIGHT_EMPTY
	update(0)

/obj/machinery/light/lamp_post/quadra/broken
	status = LIGHT_BROKEN
	icon_state = "nvlamp-quadra"

/obj/effect/lamp_post/traffic_light
	name = "traffic light"
	desc = "A relic of the past, associated with sirens of justice and tickets."
	icon = 'icons/fallout/objects/96x160_street_decore.dmi'

	anchored = TRUE
	opacity = 0
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	layer = GASFIRE_LAYER

	pixel_x = -32

/obj/effect/lamp_post/traffic_light/left
	icon_state = "traffic-light-leftside"

/obj/effect/lamp_post/traffic_light/right
	icon_state = "traffic-light-rightside"

/obj/effect/lamp_post/traffic_light/blinking
	icon_state = "traffic-light-south-blinking"



/*	light_system = MOVABLE_LIGHT
	light_range = 8
	light_color = "#a8a582"
	light_on = FALSE

	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	layer = GASFIRE_LAYER
	anchored = TRUE
	max_integrity = 750
	opacity = 0
	density = TRUE

	pixel_x = -32 */

