/obj/effect/decal/remains
	name = "remains"
	gender = PLURAL
	icon = 'icons/effects/blood.dmi'
	var/list/obj/item/debris_result = list(/obj/item/stack/sheet/bone)
	var/drop_amount = 1

/obj/effect/decal/remains/Initialize()
	if(isemptylist(debris_result))
		return INITIALIZE_HINT_QDEL
	. = ..()

/obj/effect/decal/remains/acid_act()
	visible_message(span_warning("[src] dissolve[gender==PLURAL?"":"s"] into a puddle of sizzling goop!"))
	playsound(src, 'sound/items/welder.ogg', 150, 1)
	new /obj/effect/decal/cleanable/greenglow(drop_location())
	qdel(src)

/obj/effect/decal/remains/attack_hand(mob/user)
	visible_message(span_notice("[user] begins to pick through [src]."))
	if(do_after(user, 40, target = src))
		var/atom/find = make_debris()
		if(find)
			to_chat(user, span_notice("You find \a [find] in [src]!"))
			if(drop_amount == 0)
				qdel(src)
				return
		return
	. = ..()

/obj/effect/decal/remains/proc/make_debris()
	drop_amount--
	var/type_to_spawn = pick(debris_result)
	return new type_to_spawn (get_turf(src))

/obj/effect/decal/remains/examine_more()
	. = list(span_notice("<i>You examine [src] closer, and note the following...</i>"))
	if(LAZYLEN(debris_result))
		var/obj/item/show = pick(debris_result)
		. += span_notice("You think you can see some [initial(show.name)] in it.")
	if(drop_amount && (drop_amount < initial(drop_amount)))
		. += span_notice("It looks like it has already been picked through somewhat.")
	return .

/obj/effect/decal/remains/human
	desc = "They look like human remains. They have a strange aura about them."
	icon_state = "remains"
	drop_amount = 2

/obj/effect/decal/remains/plasma
	icon_state = "remainsplasma"
	drop_amount = 0

/obj/effect/decal/remains/xeno
	desc = "They look like the remains of something... alien. They have a strange aura about them."
	icon_state = "remainsxeno"
	drop_amount = 2

/obj/effect/decal/remains/xeno/larva
	icon_state = "remainslarva"

/obj/effect/decal/remains/robot
	desc = "They look like the remains of something mechanical. They have a strange aura about them."
	icon = 'icons/mob/robots.dmi'
	icon_state = "remainsrobot"
	debris_result = list(/obj/item/stack/sheet/metal, /obj/item/stack/cable_coil, /obj/item/stack/rods)
	drop_amount = 2

/obj/effect/decal/cleanable/robot_debris/old
	name = "dusty robot debris"
	desc = "Looks like nobody has touched this in a while."

/obj/effect/decal/remains/deadeyebot
	desc = "A destroyed or deactivated eyebot. Best not stick around to see if it's still functioning."
	icon = 'icons/fallout/mobs/robots/eyebots.dmi'
	icon_state = "eyebot_d"

/obj/effect/decal/remains/skulls
	name = "decoration"
	desc = "A string of skulls."
	icon = 'icons/fallout/objects/decals.dmi'
	icon_state = "skulls"
	drop_amount = 1
	plane = GAME_PLANE
	layer = OBJ_LAYER

/obj/effect/decal/remains/cloth
	name = "decoration"
	desc = "A simple cloth decoration."
	icon = 'icons/fallout/objects/decals.dmi'
	icon_state = "skin"
	drop_amount = 1
	plane = GAME_PLANE
	layer = OBJ_LAYER
	debris_result = list(/obj/item/stack/sheet/cloth)

/obj/effect/decal/remains/hay
	name = "hay bale"
	desc = "You'd need eight stomachs to eat that."
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "haybale"
	drop_amount = 2
	plane = GAME_PLANE
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER
	debris_result = list(/obj/item/stack/sheet/hay/five)

/obj/effect/decal/remains/bottles
	name = "pile of bottles"
	desc = "Someone's evening fun."
	icon = 'icons/obj/structures.dmi'
	icon_state = "bottles1"
	drop_amount = 2
	plane = GAME_PLANE
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER
	debris_result = list(/obj/item/reagent_containers/food/drinks/beer)

/obj/effect/decal/remains/cans
	name = "pile of cans"
	desc = "Someone's evening fun."
	icon = 'icons/obj/structures.dmi'
	icon_state = "cans1"
	drop_amount = 1
	plane = GAME_PLANE
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER
	debris_result = list(/obj/item/reagent_containers/food/drinks/soda_cans/sodawater)

/obj/effect/decal/remains/nest
	name = "animal nest"
	desc = "There seems to be some eggs inside."
	icon = 'icons/misc/Pit.dmi'
	icon_state = "pit"
	drop_amount = 3
	plane = GAME_PLANE
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER
	debris_result = list(/obj/item/reagent_containers/food/snacks/egg)

/obj/effect/decal/remains/rock
	name = "rock"
	desc = "You see nothing out of the ordinary."
	icon = 'icons/obj/flora/rocks.dmi'
	icon_state = "basalt1"
	drop_amount = 3
	plane = GAME_PLANE
	layer = OBJ_LAYER
	debris_result = list(/obj/item/stack/sheet/mineral/limestone)
