//Highwayman

/obj/mecha/combat/phazon/highwayman
	name = "\improper highwayman eco"
	desc = "A fast vehicule, runing on powercell. YUP ! ITS THE HIGHWAYMAN ! Kinda. Its not the original, but a budget version."
	icon = 'icons/mecha/highwayman.dmi'
	icon_state = "highwayman"
	pixel_x = -15
	pixel_y = 0
	max_integrity = 250
	armor = ARMOR_VALUE_VEHICLE_CAR
	armor = list("melee" = 30, "bullet" = 25, "laser" = 20, "energy" = 20, "bomb" = 40, "bio" = 0, "rad" = 100, "fire" = 100, "acid" = 100)
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/highwayman/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/highwayman/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/highwayman/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/highwayman/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/combat/phazon/highwayman/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//corvega

/obj/mecha/combat/phazon/corvega
	name = "\improper Corvega"
	desc = "A old vehicule, runing on powercell."
	icon = 'icons/mecha/corvega.dmi'
	icon_state = "corvega"
	max_integrity = 280
	armor = ARMOR_VALUE_VEHICLE_CAR
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/corvega/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//corvega police

/obj/mecha/combat/phazon/corvega/police
	name = "\improper Police Corvega"
	desc = "A old vehicule, runing on powercell. Seems to have been the proprety of the PreWar Yuma PD."
	icon = 'icons/mecha/corvega-police.dmi'
	icon_state = "corvega"
	max_integrity = 280
	armor = ARMOR_VALUE_VEHICLE_ARMORED_LIGHT
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/combat/phazon/corvega/police/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	sirens_action.Grant(user, src)

/obj/mecha/combat/phazon/corvega/police/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	sirens_action.Remove(user)

/obj/mecha/combat/phazon/corvega/police/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)