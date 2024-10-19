/obj/mecha/base_vehicle/armoured_jeep
	name = "\improper uparmored M38"
	desc = "A apparently original M38 jeep, modified with a almost fully armored chassis. Much of the interior space is occupied by advanced electronics designed to allow a single occupant to command, gun and drive at the same time."
	icon = 'icons/mecha/armoured_jeep.dmi'
	icon_state = "armoured_jeep"
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	can_be_locked = FALSE
	enter_delay = 30
	pixel_x = -7
	pixel_y = -5
	max_integrity = 500
	step_energy_drain = 1.25
	step_in = 1.5
	armor = ARMOR_VALUE_VEHICLE_ARMORED
	wreckage = /obj/structure/mecha_wreckage/armoured_jeep
	max_utility_equip = 3
	max_weapons_equip = 1
	max_misc_equip = 1
	facing_modifiers = list(FRONT_ARMOUR = 1.25, SIDE_ARMOUR = 1, BACK_ARMOUR = 0.6)

/obj/mecha/base_vehicle/armoured_jeep/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/base_vehicle/armoured_jeep/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)

/obj/structure/mecha_wreckage/armoured_jeep
	name = "\improper M38 wreckage"
	desc = "Wreckage of a M38 jeep, it's completely destroyed."
	icon = 'icons/mecha/armoured_jeep.dmi'
	icon_state = "armoured_jeep-broken"

/obj/mecha/base_vehicle/armoured_jeep/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/rapid
	ME.attach(src)
	max_ammo()

/obj/mecha/base_vehicle/m4sherman_cx
	name = "\improper West-Tek Sherman M4-CX"
	desc = "A authentic Sherman, this one is a Pre-War prototype designed by Wesk-Tek to explore the practicality of a significantly downsized tank platform. The 75mm cannon has been replaced by two light, modular weapons sponsons and the cast steel hull has been replaced by a much thinner composite to save on weight and volume. The program was cancelled due to a lack of funding and failure to meet objectives before the War, but the schematics are occasionally still found in the wasteland."
	icon = 'icons/mecha/sherman.dmi'
	icon_state = "sherman"
	stepsound = 'sound/mecha/tanktracks.mp3'
	turnsound = 'sound/mecha/tanktracks.mp3'
	can_be_locked = FALSE
	enter_delay = 50
	pixel_x = -8
	pixel_y = -4
	max_integrity = 600 // its a tank!
	step_in = 3
	step_energy_drain = 1.5
	armor = ARMOR_VALUE_VEHICLE_ARMORED_HEAVY
	wreckage = /obj/structure/mecha_wreckage/sherman
	max_utility_equip = 2
	max_weapons_equip = 2
	max_misc_equip = 1
	facing_modifiers = list(FRONT_ARMOUR = 1.5, SIDE_ARMOUR = 1, BACK_ARMOUR = 0.6)

/obj/mecha/base_vehicle/m4sherman_cx/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	zoom_action.Grant(user, src)

/obj/mecha/base_vehicle/m4sherman_cx/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	zoom_action.Remove(user, src)

/obj/mecha/base_vehicle/m4sherman_cx/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/seat
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/minigun
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot/rapid
	max_ammo()

/obj/structure/mecha_wreckage/sherman
	name = "\improper sherman wreckage"
	desc = "Wreckage of a sherman tank, it's completely destroyed."
	icon = 'icons/mecha/sherman.dmi'
	icon_state = "sherman-broken"
