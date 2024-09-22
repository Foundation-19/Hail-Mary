/obj/mecha/combat
	force = 30
	internal_damage_threshold = 50
	armor = ARMOR_VALUE_HEAVY
	mouse_pointer = 'icons/mecha/mecha_mouse.dmi'
	deflect_chance = 0
	stepsound = 'sound/mecha/neostep2.ogg'

	max_weapons_equip = 3
	max_utility_equip = 1
	max_misc_equip = 2

/obj/mecha/combat/proc/max_ammo() //Max the ammo stored for Nuke Ops mechs, or anyone else that calls this
	for(var/obj/item/I in equipment)
		if(istype(I, /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/))
			var/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/gun = I
			gun.projectiles_cache = gun.projectiles_cache_max
