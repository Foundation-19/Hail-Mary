/obj/mecha/combat/phazon/armoured_jeep
	name = "\improper uparmored M38"
	desc = "A apparently original M38 jeep, modified with a almost fully armored chassis."
	icon = 'icons/mecha/armoured_jeep.dmi'
	icon_state = "armoured_jeep"
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	pixel_x = -7
	pixel_y = -5
	max_integrity = 500
	step_energy_drain = 1.5
	step_in = 1.5
	armor = ARMOR_VALUE_SALVAGE
	wreckage = /obj/structure/mecha_wreckage/armoured_jeep
	max_utility_equip = 2
	max_weapons_equip = 1
	max_misc_equip = 1

/obj/mecha/combat/phazon/buggy/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/buggy/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/structure/mecha_wreckage/armoured_jeep
	name = "\improper M38 wreckage"
	desc = "Wreckage of a M38 jeep, it's completely destroyed."
	icon_state = "armoured_jeep-broken"

/obj/mecha/combat/phazon/armoured_jeep/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/rapid
	ME.attach(src)
	max_ammo()