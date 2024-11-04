//Buggy

/obj/mecha/base_vehicle/buggy
	name = "\improper Buggy"
	desc = "A light vehicle, not very powerfull or solid, running on a powercell."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggygreen"
	pixel_x = -15
	pixel_y = -5
	max_integrity = 200
	step_in = 0.8
	armor = ARMOR_VALUE_VEHICLE_LIGHT
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

	facing_modifiers = list(FRONT_ARMOUR = 1.15, SIDE_ARMOUR = 1, BACK_ARMOUR = 0.85) // Engine's on the back, IG

	max_utility_equip = 2
	max_weapons_equip = 0
	max_misc_equip = 1

/obj/structure/mecha_wreckage/buggy
	name = "\improper Buggy wreckage"
	desc = "Its a buggy ! Won't bug you anymore."
	icon = 'icons/fallout/vehicles/medium_vehicles.dmi'
	icon_state = "buggy-broken"

/obj/mecha/base_vehicle/buggy/go_out()
	..()
	update_icon()

/obj/mecha/base_vehicle/buggy/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/base_vehicle/buggy/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/base_vehicle/buggy/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/base_vehicle/buggy/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggydune

/obj/mecha/base_vehicle/buggy/dune
	name = "\improper Buggy"
	desc = "A light vehicle, not very powerfull or solid, running on a powercell."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggydune"

/obj/mecha/base_vehicle/buggy/dune/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggyred

/obj/mecha/base_vehicle/buggy/red
	name = "\improper Buggy"
	desc = "A light vehicle, not very powerfull or solid, running on a powercell."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggyred"

/obj/mecha/base_vehicle/buggy/red/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggyflame

/obj/mecha/base_vehicle/buggy/flamme
	name = "\improper Buggy"
	desc = "A light vehicle, not very powerfull or solid, running on a powercell."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggyflame"

/obj/mecha/base_vehicle/buggy/flamme/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggy Ranger

/obj/mecha/base_vehicle/buggy/ranger
	name = "\improper Ranger Buggy"
	desc = "A light vehicle, not very powerfull or solid, running on a powercell. This one as been recolored by the Rangers."
	icon = 'icons/mecha/hanlonbuggy.dmi'
	icon_state = "hanlonbuggy"
	armor = ARMOR_VALUE_VEHICLE_MED_LIGHT

/obj/mecha/base_vehicle/buggy/ranger/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//Buggy Ranger AND RICO

/obj/mecha/base_vehicle/buggy/rangerarmed
	name = "\improper Vet Ranger Buggy with gunner"
	desc = "A light vehicle, not very powerfull or solid, running on a powercell. This one as been recolored by the Rangers... And Ranger Rico ''Gunner'' Davberger is gonna shoot with his shotgun."
	icon = 'icons/mecha/buggyrangergun.dmi'
	icon_state = "rangergun"
	armor = ARMOR_VALUE_VEHICLE_MED_LIGHT

	max_weapons_equip = 1

/obj/mecha/base_vehicle/buggy/rangerarmed/go_out()
	..()
	update_icon()

/obj/mecha/base_vehicle/buggy/rangerarmed/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/base_vehicle/buggy/rangerarmed/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	smoke_action.Grant(user, src)

/obj/mecha/base_vehicle/buggy/rangerarmed/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	smoke_action.Remove(user)

/obj/mecha/base_vehicle/buggy/rangerarmed/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot
	ME.attach(src)
	max_ammo()

//Buggyblue

/obj/mecha/base_vehicle/buggy/blue
	name = "\improper Minutemen Buggy"
	desc = "A light vehicle, not very powerful or solid, running on fuel."
	icon = 'icons/mecha/buggy.dmi'
	icon_state = "buggyblue"

/obj/mecha/base_vehicle/buggy/blue/go_out()
	..()
	update_icon()

/obj/mecha/base_vehicle/buggy/blue/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/base_vehicle/buggy/blue/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/base_vehicle/buggy/blue/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/base_vehicle/buggy/blue/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
