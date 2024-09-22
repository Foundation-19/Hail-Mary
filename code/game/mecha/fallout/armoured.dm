/obj/mecha/combat/phazon/armored
	name = "\improper uparmored M38"
	desc = "A apparently original M38 jeep, modified with a almost fully armored chassis."
//	icon = 'icons/mecha/armoredjeep.dmi'
	icon_state = "armoredjeep"
	max_integrity = 400
	step_energy_drain = 1.5
	step_in = 1.5
	armor = ARMOR_VALUE_PA
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

/obj/mecha/combat/phazon/armoredjeep/rangerarmed/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/hobo
	ME.attach(src)
	max_ammo()