/obj/mecha/base_vehicle
	name = "\improper real fallout MECHA"
	desc = "A oddly flimsy-looking car, with a sign featuring a crudely-drawn walking robot on the roof. The sign reads: 'MECHA IS REAL!'. You get a feeling this isn't supposed to exist."
	icon = 'icons/mecha/vehicle_base.dmi'
	icon_state = "vehicle_base"
	stepsound = 'sound/f13machines/buggy_loop.ogg'
	turnsound = 'sound/f13machines/buggy_loop.ogg'
	step_in = 2
	dir_in = 2 //Facing South.
	step_energy_drain = 1
	max_integrity = 100
	deflect_chance = 0
	armor = ARMOR_VALUE_VEHICLE_VLIGHT
	max_temperature = 25000
	wreckage = /obj/structure/mecha_wreckage/fallout
	internal_damage_threshold = 25
	force = 5
	can_be_locked = TRUE
	canstrafe = FALSE

	facing_modifiers = list(FRONT_ARMOUR = 0.8, SIDE_ARMOUR = 1, BACK_ARMOUR = 1.15) // experimental: weaker at the front because that's where the engine is..

	max_utility_equip = 3
	max_weapons_equip = 0
	max_misc_equip = 1

/obj/structure/mecha_wreckage/fallout
	name = "\improper vehicle wreckage"
	desc = "A destroyed vehicle."
	icon = 'icons/fallout/vehicles/medium_vehicles.dmi'
	icon_state = "derelict"

/obj/mecha/base_vehicle/GrantActions(mob/living/user, human_occupant = 0)
	..()

/obj/mecha/base_vehicle/RemoveActions(mob/living/user, human_occupant = 0)
	..()
