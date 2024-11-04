//Highwayman

/obj/mecha/base_vehicle/highwayman
	name = "\improper highwayman eco"
	desc = "A fast vehicule, runing on powercell. YUP ! ITS THE HIGHWAYMAN ! Kinda. Its not the original, but a budget version."
	icon = 'icons/mecha/highwayman.dmi'
	icon_state = "highwayman"
	pixel_x = -16
	pixel_y = -5
	max_integrity = 250
	step_energy_drain = 0.5
	step_in = 0.7
	armor = ARMOR_VALUE_VEHICLE_LIGHT
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	wreckage = /obj/structure/mecha_wreckage/fallout

/obj/mecha/base_vehicle/highwayman/go_out()
	..()
	update_icon()

/obj/mecha/base_vehicle/highwayman/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/base_vehicle/highwayman/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/base_vehicle/highwayman/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/mecha/base_vehicle/highwayman/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//corvega

/obj/mecha/base_vehicle/corvega
	name = "\improper Corvega"
	desc = "A old vehicule, runing on powercell."
	icon = 'icons/mecha/corvega.dmi'
	icon_state = "corvega"
	max_integrity = 280
	armor = ARMOR_VALUE_VEHICLE_MED_LIGHT
	wreckage = /obj/structure/mecha_wreckage/buggy

/obj/mecha/base_vehicle/corvega/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)

//corvega police

/obj/mecha/base_vehicle/corvega/police
	name = "\improper Police Corvega"
	desc = "A old vehicule, runing on powercell. Seems to have been the proprety of the PreWar Yuma PD."
	icon = 'icons/mecha/corvega-police.dmi'
	icon_state = "corvega"
	max_integrity = 280
	armor = ARMOR_VALUE_VEHICLE_MEDIUM
	wreckage = /obj/structure/mecha_wreckage/buggy

	max_weapons_equip = 1

/obj/mecha/base_vehicle/corvega/police/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	sirens_action.Grant(user, src)

/obj/mecha/base_vehicle/corvega/police/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	sirens_action.Remove(user)

/obj/mecha/base_vehicle/corvega/police/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
