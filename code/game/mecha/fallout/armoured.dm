/obj/mecha/combat/phazon/armoured_jeep
	name = "\improper uparmored M38"
	desc = "A apparently original M38 jeep, modified with a almost fully armored chassis. Much of the interior space is occupied by advanced electronics designed to allow a single occupant to command, gun and drive at the same time."
	icon = 'icons/mecha/armoured_jeep.dmi'
	icon_state = "armoured_jeep"
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
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
	facing_modifiers = list(FRONT_ARMOUR = 1.25, SIDE_ARMOUR = 1, BACK_ARMOUR = 0.85)

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
	icon = 'icons/mecha/armoured_jeep.dmi'
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

/obj/mecha/combat/phazon/m4sherman_cemx
	name = "\improper Sherman M4-CEMX"
	desc = "A authentic Sherman, this prototype model is part of the Compact Enhanced Mobility lineage and has been fitted with a quadruped propulsion system, the main 75mm cannon has been replaced with twin light sponsons, and much of the orignal armour has been removed. Much of the interior space is occupied by advanced electronics designed to allow a single occupant to command, gun and drive at the same time. The Sherman CEM(x) program was  discontinued shortly after the creation of only a few prototypes for unknown reasons."
	icon = 'icons/mecha/sherman.dmi'
	icon_state = "sherman"
	pixel_x = -8
	pixel_y = -4
	max_integrity = 700 // its a tank!
	step_in = 3 // its a tank..
	step_energy_drain = 1.5
	armor = ARMOR_VALUE_VEHICLE_ARMORED_HEAVY
	wreckage = /obj/structure/mecha_wreckage/sherman
	max_utility_equip = 2
	max_weapons_equip = 2
	max_misc_equip = 1
	facing_modifiers = list(FRONT_ARMOUR = 1.5, SIDE_ARMOUR = 1, BACK_ARMOUR = 0.7)

/obj/mecha/combat/phazon/m4sherman_cemx/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)
	zoom_action.Grant(user, src)

/obj/mecha/combat/phazon/m4sherman_cemx/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)
	zoom_action.Remove(user, src)

/obj/mecha/combat/phazon/m4sherman_cemx/loaded/Initialize()
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
