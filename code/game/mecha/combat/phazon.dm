/obj/mecha/combat/phazon
	name = "\improper Phazon"
	desc = "This is a Phazon exosuit. The pinnacle of scientific research and pride of Nanotrasen, it uses cutting edge bluespace technology and expensive materials."
	icon_state = "phazon"
	step_in = 2
	dir_in = 2 //Facing South.
	step_energy_drain = 3
	max_integrity = 200
	deflect_chance = 30
	armor = ARMOR_VALUE_HEAVY
	max_temperature = 25000
	infra_luminosity = 3
	wreckage = /obj/structure/mecha_wreckage/fallout
	add_req_access = 1
	internal_damage_threshold = 25
	force = 15
	phase_state = "phazon-phase"

	facing_modifiers = list(FRONT_ARMOUR = 0.85, SIDE_ARMOUR = 1, BACK_ARMOUR = 1.15) // experimental: weaker at the front because that's where the engine is..

	max_utility_equip = 3
	max_weapons_equip = 1
	max_misc_equip = 1

/obj/structure/mecha_wreckage/fallout
	name = "\improper vehicle wreckage"
	desc = "A destroyed vehicle."
	icon = 'icons/fallout/vehicles/medium_vehicles.dmi'
	icon_state = "derelict"

/obj/mecha/combat/phazon/GrantActions(mob/living/user, human_occupant = 0)
	..()
	switch_damtype_action.Grant(user, src)
	phasing_action.Grant(user, src)


/obj/mecha/combat/phazon/RemoveActions(mob/living/user, human_occupant = 0)
	..()
	switch_damtype_action.Remove(user)
	phasing_action.Remove(user)
