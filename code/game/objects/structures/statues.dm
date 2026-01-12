/obj/structure/statue
	name = "statue"
	desc = "Placeholder. Yell at Firecage if you SOMEHOW see this."
	icon = 'icons/obj/statue.dmi'
	icon_state = ""
	density = TRUE
	anchored = FALSE
	max_integrity = 100
	var/oreAmount = 5
	var/material_drop_type = /obj/item/stack/sheet/metal
	var/impressiveness = 15
	CanAtmosPass = ATMOS_PASS_DENSITY


/obj/structure/statue/Initialize()
	. = ..()
	AddElement(/datum/element/art, impressiveness)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/datum,_AddElement), list(/datum/element/beauty, impressiveness *  75)), 0)
	AddComponent(/datum/component/simple_rotation, ROTATION_ALTCLICK | ROTATION_CLOCKWISE, CALLBACK(src, PROC_REF(can_user_rotate)), CALLBACK(src, PROC_REF(can_be_rotated)), null)

/obj/structure/statue/proc/can_be_rotated(mob/user)
	if(!anchored)
		return TRUE
	to_chat(user, span_warning("It's bolted to the floor, you'll need to unwrench it first."))

/obj/structure/statue/proc/can_user_rotate(mob/user)
	return user.canUseTopic(src, BE_CLOSE, FALSE, !iscyborg(user))

/obj/structure/statue/attackby(obj/item/W, mob/living/user, params)
	add_fingerprint(user)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(default_unfasten_wrench(user, W))
			return
		if(istype(W, /obj/item/weldingtool) || istype(W, /obj/item/gun/energy/plasmacutter))
			if(!W.tool_start_check(user, amount=0))
				return FALSE

			user.visible_message("[user] is slicing apart the [name].", \
								span_notice("You are slicing apart the [name]..."))
			if(W.use_tool(src, user, 40, volume=50))
				user.visible_message("[user] slices apart the [name].", \
									span_notice("You slice apart the [name]!"))
				deconstruct(TRUE)
			return
	return ..()

/obj/structure/statue/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(material_drop_type)
			var/drop_amt = oreAmount
			if(!disassembled)
				drop_amt -= 2
			if(drop_amt > 0)
				new material_drop_type(get_turf(src), drop_amt)
	qdel(src)

//////////////////////////////////////STATUES/////////////////////////////////////////////////////////////
////////////////////////uranium///////////////////////////////////

/obj/structure/statue/uranium
	max_integrity = 300
	light_range = 2
	material_drop_type = /obj/item/stack/sheet/mineral/uranium
	var/last_event = 0
	var/active = null
	impressiveness = 25 // radiation makes an impression

/obj/structure/statue/uranium/nuke
	name = "statue of a nuclear fission explosive"
	desc = "This is a grand statue of a Nuclear Explosive. It has a sickening green colour."
	icon_state = "nuke"

/obj/structure/statue/uranium/eng
	name = "Statue of an engineer"
	desc = "This statue has a sickening green colour."
	icon_state = "eng"

/obj/structure/statue/uranium/attackby(obj/item/W, mob/user, params)
	radiate()
	return ..()

/obj/structure/statue/uranium/Bumped(atom/movable/AM)
	radiate()
	..()

/obj/structure/statue/uranium/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	radiate()
	. = ..()

/obj/structure/statue/uranium/attack_paw(mob/user)
	radiate()
	. = ..()

/obj/structure/statue/uranium/proc/radiate()
	if(!active)
		if(world.time > last_event+15)
			active = 1
			radiation_pulse(src, 30)
			last_event = world.time
			active = null
			return
	return

////////////////////////////plasma///////////////////////////////////////////////////////////////////////

/obj/structure/statue/plasma
	max_integrity = 200
	material_drop_type = /obj/item/stack/sheet/mineral/plasma
	desc = "This statue is suitably made from plasma."
	impressiveness = 20

/obj/structure/statue/plasma/scientist
	name = "statue of a scientist"
	icon_state = "sci"

/obj/structure/statue/plasma/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature > 300)
		PlasmaBurn(exposed_temperature)


/obj/structure/statue/plasma/bullet_act(obj/item/projectile/Proj)
	var/burn = FALSE
	if(!(Proj.nodamage) && Proj.damage_type == BURN && !QDELETED(src))
		burn = TRUE
	if(burn)
		var/turf/T = get_turf(src)
		if(Proj.firer)
			message_admins("Plasma statue ignited by [ADMIN_LOOKUPFLW(Proj.firer)] in [ADMIN_VERBOSEJMP(T)]")
			log_game("Plasma statue ignited by [key_name(Proj.firer)] in [AREACOORD(T)]")
		else
			message_admins("Plasma statue ignited by [Proj]. No known firer, in [ADMIN_VERBOSEJMP(T)]")
			log_game("Plasma statue ignited by [Proj] in [AREACOORD(T)]. No known firer.")
		PlasmaBurn(2500)
	return ..()

/obj/structure/statue/plasma/attackby(obj/item/W, mob/user, params)
	if(W.get_temperature() > 300 && !QDELETED(src))//If the temperature of the object is over 300, then ignite
		var/turf/T = get_turf(src)
		message_admins("Plasma statue ignited by [ADMIN_LOOKUPFLW(user)] in [ADMIN_VERBOSEJMP(T)]")
		log_game("Plasma statue ignited by [key_name(user)] in [AREACOORD(T)]")
		ignite(W.get_temperature())
	else
		return ..()

/obj/structure/statue/plasma/proc/PlasmaBurn(exposed_temperature)
	if(QDELETED(src))
		return
	atmos_spawn_air("plasma=[oreAmount*10];TEMP=[exposed_temperature]")
	deconstruct(FALSE)

/obj/structure/statue/plasma/proc/ignite(exposed_temperature)
	if(exposed_temperature > 300)
		PlasmaBurn(exposed_temperature)

//////////////////////gold///////////////////////////////////////

/obj/structure/statue/gold
	max_integrity = 300
	material_drop_type = /obj/item/stack/sheet/mineral/gold
	desc = "This is a highly valuable statue made from gold."
	impressiveness = 30

/obj/structure/statue/gold/hos
	name = "statue of the head of security"
	icon_state = "hos"

/obj/structure/statue/gold/hop
	name = "statue of the head of personnel"
	icon_state = "hop"

/obj/structure/statue/gold/cmo
	name = "statue of the chief medical officer"
	icon_state = "cmo"

/obj/structure/statue/gold/ce
	name = "statue of the chief engineer"
	icon_state = "ce"

/obj/structure/statue/gold/rd
	name = "statue of the research director"
	icon_state = "rd"

//////////////////////////silver///////////////////////////////////////

/obj/structure/statue/silver
	max_integrity = 300
	material_drop_type = /obj/item/stack/sheet/mineral/silver
	desc = "This is a valuable statue made from silver."
	impressiveness = 25

/obj/structure/statue/silver/md
	name = "statue of a medical officer"
	icon_state = "md"

/obj/structure/statue/silver/janitor
	name = "statue of a janitor"
	icon_state = "jani"

/obj/structure/statue/silver/sec
	name = "statue of a security officer"
	icon_state = "sec"

/obj/structure/statue/silver/secborg
	name = "statue of a security cyborg"
	icon_state = "secborg"

/obj/structure/statue/silver/medborg
	name = "statue of a medical cyborg"
	icon_state = "medborg"

/////////////////////////diamond/////////////////////////////////////////

/obj/structure/statue/diamond
	max_integrity = 1000
	material_drop_type = /obj/item/stack/sheet/mineral/diamond
	desc = "This is a very expensive diamond statue."
	impressiveness = 60

/obj/structure/statue/diamond/captain
	name = "statue of THE captain."
	icon_state = "cap"

/obj/structure/statue/diamond/ai1
	name = "statue of the AI hologram."
	icon_state = "ai1"

/obj/structure/statue/diamond/ai2
	name = "statue of the AI core."
	icon_state = "ai2"

/obj/structure/statue/diamond/verakeyes
	name = "holographic statue"
	desc = "A vision of pre-war elegance, frozen in time."
	color = "#33b5e5"
	icon_state = "verakeyesanimated"
	alpha = 200
	pixel_x = -2
	anchored = TRUE

/obj/structure/statue/diamond/indestructible
	name = "statue of the AI hologram."
	icon_state = "ai1"
	flags_1 = NODECONSTRUCT_1
	resistance_flags = FIRE_PROOF | ACID_PROOF | UNACIDABLE | FREEZE_PROOF | INDESTRUCTIBLE

/obj/structure/statue/diamond/indestructible/artdecofountain
	name = "weathered statue"
	desc = "They align with the four cardinal directions, their bowls have long since dried."
	icon = 'icons/obj/Ritas.dmi'
	icon_state = "artdecofountain"
	anchored = TRUE
	density = FALSE

/obj/structure/statue/diamond/indestructible/artdecofountain/center
	name = "weathered statue"
	icon_state = "artdecofountainoverlay"

/obj/structure/statue/diamond/indestructible/artdecowinged
	name = "weathered statue"
	desc = "Winged guardians watching over the airport."
	icon = 'icons/obj/Ritas.dmi'
	icon_state = "artdecowinged"
	anchored = TRUE
	density = FALSE

/obj/structure/statue/diamond/indestructible/artdecohead
	name = "weathered statue"
	desc = "Winged guardians watching over the airport."
	icon = 'icons/obj/artdeco.dmi'
	icon_state = "head"
	anchored = TRUE
	density = FALSE

/obj/structure/statue/diamond/indestructible/artdecoatlas
	name = "weathered statue"
	desc = "Winged guardians watching over the airport."
	icon = 'icons/obj/artdeco.dmi'
	icon_state = "atlas"
	anchored = TRUE
	density = FALSE

/obj/structure/statue/diamond/indestructible/oldworldstatue
	name = "old world statue"
	desc = "It is watching over you."
	icon = 'icons/obj/Ritas.dmi'
	icon_state = "face"
	anchored = TRUE
	density = FALSE

/obj/structure/statue/diamond/indestructible/redrocket
	name = "Red Rocket"
	desc = "Drive in, Fly out!"
	icon = 'icons/obj/Ritas.dmi'
	icon_state = "rrw"
	anchored = TRUE
	density = FALSE

/obj/structure/statue/diamond/indestructible/redrocket/two
	name = "Red Rocket"
	icon_state = "rrw2"

/obj/structure/statue/diamond/indestructible/redrocket/three
	name = "Red Rocket"
	icon_state = "rrw3"
	density = TRUE

/obj/structure/statue/diamond/indestructible/redrocket/redux
	name = "Red Rocket"
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "redrocketredux"

/obj/structure/statue/diamond/indestructible/redrocket/bits
	name = "Red Rocket"
	icon = 'icons/fallout/objects/redrocketredux.dmi'
	icon_state = "redrocketbits"

/obj/structure/statue/diamond/indestructible/redrocket/text
	name = "Red Rocket"
	icon = 'icons/fallout/objects/wendover.dmi'
	icon_state = "redrockettext"
	layer = FLY_LAYER
	density = TRUE

/obj/structure/statue/diamond/indestructible/carheap
	name = "car pile"
	desc = "A stack of cars built up by the 80s."
	icon = 'icons/fallout/objects/redrocketredux.dmi'
	icon_state = "carpile_lower"
	anchored = TRUE
	layer = VISIBLE_FROM_ABOVE_LAYER
	bound_width = 288

/obj/structure/statue/diamond/indestructible/carheap/upper
	name = "car pile"
	icon_state = "carpile_upper"

/obj/structure/statue/diamond/indestructible/landinggear
	name = "landing gear"
	desc = "The landing gear of a plane."
	icon = 'icons/fallout/trash.dmi'
	icon_state = "auto_shaft"
	anchored = TRUE
	density = FALSE

/obj/structure/statue/diamond/indestructible/teslacoil
	name = "tesla coil"
	desc = "You see something out of the ordinary."
	icon = 'icons/obj/Ritas.dmi'
	icon_state = "techexhibit"
	anchored = TRUE
	pixel_x = -16
	pixel_y = -15

/obj/structure/statue/diamond/indestructible/tanningbed
	name = "tanning bed"
	desc = "You see something out of the ordinary."
	icon = 'icons/obj/atmospherics/pipes/transit_tube.dmi'
	icon_state = "open_station0"
	layer = MOB_LOWER_LAYER
	anchored = TRUE
	density = FALSE
	dir = NORTH
	pixel_y = -4

/obj/structure/statue/diamond/indestructible/seesaw
	name = "seesaw"
	desc = "Alt-click to teeter. Alt-click again to totter."
	icon = 'icons/fallout/objects/playstructure.dmi'
	icon_state = "seesaw"
	layer = VISIBLE_FROM_ABOVE_LAYER
	pixel_x = -32
	bound_width = 96
	anchored = FALSE
	density = FALSE

/obj/structure/statue/diamond/indestructible/swings
	name = "swings"
	desc = "An old pre-war playstructure."
	icon = 'icons/fallout/objects/playstructure.dmi'
	icon_state = "swingbottom"
	layer = VISIBLE_FROM_ABOVE_LAYER
	pixel_x = -64
	bound_width = 160
	anchored = TRUE
	density = FALSE

/obj/structure/statue/diamond/indestructible/swings/two
	name = "swings"
	icon_state = "swingbottom2"

/obj/structure/statue/diamond/indestructible/swings/top
	name = "swings"
	icon_state = "swingtop"
	layer = FLY_LAYER

/obj/structure/statue/diamond/indestructible/rocket
	name = "Rocket"
	desc = "An old pre-war playstructure."
	icon = 'icons/fallout/objects/rocket.dmi'
	icon_state = "mbottom"
	layer = VISIBLE_FROM_ABOVE_LAYER
	pixel_x = -32
	pixel_y = 16
	anchored = TRUE
	density = FALSE
	dir = SOUTHEAST

/obj/structure/statue/diamond/indestructible/rocket/top
	name = "Rocket"
	icon_state = "mtop"
	layer = FLY_LAYER
	density = TRUE

/obj/structure/statue/diamond/indestructible/ufo
	name = "UFO"
	desc = "An out of this world play structure."
	icon = 'icons/fallout/objects/playstructure2.dmi'
	icon_state = "UFObottom"
	layer = VISIBLE_FROM_ABOVE_LAYER
	bound_width = 96
	anchored = TRUE
	density = FALSE

/obj/structure/statue/diamond/indestructible/ufo/top
	name = "UFO"
	icon_state = "UFOtop"
	layer = FLY_LAYER
	density = TRUE

/obj/structure/statue/diamond/fishtank
	name = "derelict fish tank"
	desc = "A display case for prized possessions."
	icon = 'icons/obj/fish/fish_items.dmi'
	icon_state = "tank1"
	anchored = TRUE

/obj/structure/statue/diamond/overlayable

	flags_1 = NODECONSTRUCT_1
	resistance_flags = FIRE_PROOF | ACID_PROOF | UNACIDABLE | FREEZE_PROOF | INDESTRUCTIBLE
	anchored = TRUE
	var/mutable_appearance/signoverlay

/obj/structure/statue/diamond/overlayable/Initialize()
	. = ..()
	signoverlay = mutable_appearance(icon, "[icon_state]overlay", ABOVE_ALL_MOB_LAYER)
	add_overlay(signoverlay)

/obj/structure/statue/diamond/overlayable/WendoverWill
	name = "Wendover Will"
	desc = "Iconic mascot of the Stateline casino. Where the West Begins."
	icon = 'icons/obj/Ritas.dmi'
	icon_state = "wendoverwill"
	density = FALSE

/obj/structure/statue/diamond/overlayable/MontegoBay
	name = "Montego Bay"
	desc = "How you wish you were in Sherbrooke now."
	icon = 'icons/obj/Ritas.dmi'
	icon_state = "MontegoBay"
	pixel_x = -2
	density = FALSE

/obj/structure/statue/diamond/overlayable/MontegoBay/Initialize()
	. = ..()
	signoverlay = mutable_appearance(icon, "[icon_state]overlay", SPACEVINE_LAYER)
	add_overlay(signoverlay)

/obj/structure/statue/diamond/overlayable/palmtree
	name = "palm tree"
	desc = "A tree straight from the tropics."
	icon = 'icons/misc/beach2.dmi'
	icon_state = "palm1"

/obj/structure/statue/diamond/overlayable/motherofcombustionright
	name = "The Mother of Combustion"
	desc = "Ancestor, object of worship or decoration stolen from the Brotherhood, no one can remember. All anyone knows for sure is she is a valuable motif for the compound."
	icon = 'icons/obj/tomb.dmi'
	icon_state = "ladystatue-right"

/obj/structure/statue/diamond/overlayable/motherofcombustionleft
	name = "The Mother of Combustion"
	desc = "Ancestor, object of worship or decoration stolen from the Brotherhood, no one can remember. All anyone knows for sure is she is a valuable motif for the compound."
	icon = 'icons/obj/tomb.dmi'
	icon_state = "ladystatue-left"

/obj/structure/statue/diamond/overlayable/colossalskull
	name = "collosal skull"
	desc = "The gaping maw of a dead, titanic monster. This one is cracked in half."
	icon = 'icons/obj/Ritas.dmi'
	icon_state = "colossalskull"
	layer = CLOSED_BLASTDOOR_LAYER


/////////////////////sandstone/////////////////////////////////////////

/obj/structure/statue/sandstone
	max_integrity = 50
	material_drop_type = /obj/item/stack/sheet/mineral/sandstone

/obj/structure/statue/sandstone/assistant
	name = "statue of an assistant"
	desc = "A cheap statue of sandstone for a greyshirt."
	icon_state = "assist"

/obj/structure/statue/sandstone/gravestone
	name = "gravestone"
	desc = "A stone grave marker, the name of the person buried here has long been lost to time."
	icon = 'icons/obj/graveyard.dmi'
	icon_state = "stone-1"


/obj/structure/statue/sandstone/venus //call me when we add marble i guess
	name = "statue of a pure maiden"
	desc = "An ancient marble statue. The subject is depicted with a floor-length braid and is wielding a toolbox. By Jove, it's easily the most gorgeous depiction of a woman you've ever seen. The artist must truly be a master of his craft. Shame about the broken arm, though."
	icon = 'icons/obj/statuelarge.dmi'
	icon_state = "venus"

/////////////////////snow/////////////////////////////////////////

/obj/structure/statue/snow
	max_integrity = 50
	material_drop_type = /obj/item/stack/sheet/mineral/snow

/obj/structure/statue/snow/snowman
	name = "snowman"
	desc = "Several lumps of snow put together to form a snowman."
	icon_state = "snowman"

/obj/structure/statue/sandstone/mars
	name = "statue of Mars"
	desc = "A statue dedicated to Legion's God of War."
	icon_state = "marsred"

//Wood

/obj/structure/statue/wood
	obj_integrity = 150
	material_drop_type = /obj/item/stack/sheet/mineral/wood

/obj/structure/statue/wood/headstonewood
	name = "gravemarker"
	desc = "A wooden gravemarker, used to mark a burial site."
	icon = 'icons/obj/graveyard.dmi'
	icon_state = "wooden"
	density = 0
	anchored = 1
	oreAmount = 2
	var/obj/item/clothing/head/Helmet = null
	var/obj/item/card/id/dogtag/Dogtags = null

/obj/structure/statue/wood/headstonewood/examine(mob/user)
	. = ..()
	if(Helmet)
		. += span_notice("It has [Helmet] on it.")
	if(Dogtags)
		. += span_notice("It has [Dogtags] on it.")

/obj/structure/statue/wood/headstonewood/Destroy()
	if(Helmet)
		Helmet.forceMove(src.loc)
	if(Dogtags)
		Dogtags.forceMove(src.loc)
	return ..()

/obj/structure/statue/wood/headstonewood/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/clothing/head))
		if(Helmet)
			to_chat(user, span_notice("There's already a hat on the marker."))
			return
		W.forceMove(src)
		Helmet = W
		update_icon()
		user.visible_message("[user] puts the [Helmet] on the grave marker.", "You put the [Helmet] on the grave marker.")
		return
	if(istype(W, /obj/item/card/id/dogtag))
		if(Dogtags)
			to_chat(user, span_notice("There's already some dogtags on the marker."))
			return
		W.forceMove(src)
		Dogtags = W
		update_icon()
		user.visible_message("[user] puts the [Dogtags] on the grave marker.", "You put the [Dogtags] on the grave marker.")
		return
	..()

/obj/structure/statue/wood/headstonewood/attack_hand(mob/user)
	if(Helmet)
		user.put_in_hands(Helmet)
		user.visible_message("[user] removes the [Helmet] from the grave marker.", "You remove the [Helmet] from the grave marker.")
		Helmet = null
		update_icon()
		return
	if(Dogtags)
		user.put_in_hands(Dogtags)
		user.visible_message("[user] removes the [Dogtags] from the grave marker.", "You remove the [Dogtags] from the grave marker.")
		Dogtags = null
		update_icon()
		return
	..()

/obj/structure/statue/wood/headstonewood/update_icon()
	name = initial(name)
	overlays.Cut()
	if(Dogtags)
		var/icon/O = new('icons/mob/mob.dmi', icon_state = "[Dogtags.icon_state]")
		O.Shift(SOUTH, 6)
		overlays += O
		name = "[initial(name)] ([Dogtags.registered_name])"
	if(Helmet)
		var/icon/O = new('icons/mob/clothing/head.dmi', icon_state = "[Helmet.icon_state]")
		O.Shift(SOUTH, 6)
		overlays += O

/obj/structure/statue/wood/whitelegtotem
	name = "war totem"
	desc = "A White Leg war totem, superstitiously linked to the tribe's success in war."
	icon = 'icons/obj/Ritas.dmi'
	icon_state = "wartotem2"
	anchored = TRUE
	pixel_x = -16
	var/mutable_appearance/totemoverlay

/obj/structure/statue/wood/whitelegtotem/Initialize()
	. = ..()
	totemoverlay = mutable_appearance(icon, "[icon_state]overlay", ABOVE_ALL_MOB_LAYER)
	add_overlay(totemoverlay)


//fortuna statues

/obj/structure/statue/bos/ladyleft
	name = "The Lady"
	desc = "The inscription reads 'Scribe with hands outstretched, pray her shelter of the world, reborn anew of olde.'"
	icon = 'icons/obj/tomb.dmi'
	icon_state = "ladystatue-left"
	anchored = TRUE
/obj/structure/statue/bos/ladyright
	name = "The Lady"
	desc = "The inscription reads 'Scribe with hands outstretched, pray her shelter of the world, reborn anew of olde.'"
	icon = 'icons/obj/tomb.dmi'
	icon_state = "ladystatue-right"
	anchored = TRUE
