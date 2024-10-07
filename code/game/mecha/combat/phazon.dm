/obj/mecha/combat/phazon
	name = "\improper Phazon"
	desc = "This is a Phazon exosuit.The base vehicle type for Fallout, it is composed of cutting edge bullshitium, and you should not be seeing this."
	icon_state = "phazon"
	step_in = 2
	dir_in = 2 //Facing South.
	step_energy_drain = 3
	max_integrity = 200
	deflect_chance = 5
	armor = ARMOR_VALUE_HEAVY
	max_temperature = 25000
	infra_luminosity = 3
	wreckage = /obj/structure/mecha_wreckage/fallout
	add_req_access = 1
	internal_damage_threshold = 25
	force = 15
	can_be_locked = TRUE

	facing_modifiers = list(FRONT_ARMOUR = 0.8, SIDE_ARMOUR = 1, BACK_ARMOUR = 1.15) // experimental: weaker at the front because that's where the engine is..

	max_utility_equip = 3
	max_weapons_equip = 1
	max_misc_equip = 1

/obj/structure/mecha_wreckage/fallout
	name = "\improper vehicle wreckage"
	desc = "A destroyed vehicle."
	icon = 'icons/fallout/vehicles/medium_vehicles.dmi'
	icon_state = "derelict"

/obj/mecha/combat/phazon/GrantActions(mob/living/user, human_occupant = 0)
	cycle_action.Grant(user, src)
	lights_action.Grant(user, src)
	stats_action.Grant(user, src)
	eject_action.Grant(user, src)
	klaxon_action.Grant(user, src)

/obj/mecha/combat/phazon/RemoveActions(mob/living/user, human_occupant = 0)
	cycle_action.Remove(user)
	lights_action.Remove(user)
	stats_action.Remove(user)
	eject_action.Remove(user)
	klaxon_action.Remove(user)