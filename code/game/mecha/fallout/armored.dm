/obj/mecha/combat/phazon/armored
	name = "\improper uparmored M38"
	desc = "A apparently original M38 jeep, modified with a almost fully armored chassis."
	icon = 'icons/mecha/armoredjeep.dmi'
	icon_state = "armoredjeep"
	max_integrity = 400
	step_energy_drain = 1.5
	step_in = 1.5
	armor = ARMOR_VALUE_VEHICLE_ARMORED
	wreckage = /obj/structure/mecha_wreckage/buggy
	max_utility_equip = 2
	max_weapons_equip = 1
	max_misc_equip = 1

/obj/mecha/combat/phazon/armoredjeep/rangerarmed/go_out()
	..()
	update_icon()

/obj/mecha/combat/phazon/armoredjeep/rangerarmed/moved_inside(mob/living/carbon/human/H)
	..()
	update_icon()

/obj/mecha/combat/phazon/armoredjeep/rangerarmed/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	smoke_action.Grant(user, src)

/obj/mecha/combat/phazon/armoredjeep/rangerarmed/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	smoke_action.Remove(user)

/obj/mecha/combat/phazon/armoredjeep/rangerarmed/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/hobo
	ME.attach(src)
	max_ammo()
