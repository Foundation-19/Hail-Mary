//pickuptruck

/obj/mecha/combat/phazon/pickuptruck
	name = "\improper pickup truck"
	desc = "A old vehicule, runing on powercell."
	icon = 'icons/mecha/pickuptruck.dmi'
	icon_state = "pickuptruck"
	pixel_x = -17
	pixel_y = -3
	max_integrity = 300
	step_in = 1.4
	step_energy_drain = 1.5
	armor = ARMOR_VALUE_VEHICLE_CAR
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/pickuptruck/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/pickuptruck/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/pickuptruck/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/pickuptruck/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/pickuptruck/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//pickuptruck blue

/obj/mecha/combat/phazon/pickuptruck/blue
	name = "\improper pickup truck"
	desc = "A old vehicule, runing on powercell."
	icon = 'icons/mecha/pickuptruck-blue.dmi'
	icon_state = "pickuptruck"
	max_integrity = 300
	armor = ARMOR_VALUE_VEHICLE_CAR
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/pickuptruck/blue/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//pickuptruck bos

/obj/mecha/combat/phazon/pickuptruck/bos
	name = "\improper BoS pickup truck"
	desc = "A old vehicule, runing on powercell."
	icon = 'icons/mecha/pickuptruck-bos.dmi'
	icon_state = "pickuptruck"
	max_integrity = 300
	armor = ARMOR_VALUE_VEHICLE_CAR
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/pickuptruck/bos/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//pickuptruck bos AND Kiana

/obj/mecha/combat/phazon/pickuptruck/bos/armed
	name = "\improper BoS pickup truck with gunner"
	desc = "A old vehicule, runing on powercell. Its a A modified brotherhood truck, with the addition of a laser rifle at the back, maned by Paladin Kiana Davberg."
	icon = 'icons/mecha/pickuptruck-gunbos.dmi'
	icon_state = "pickuptruck"
	max_integrity = 300
	armor = ARMOR_VALUE_VEHICLE_CAR
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/pickuptruck/bos/armed/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)