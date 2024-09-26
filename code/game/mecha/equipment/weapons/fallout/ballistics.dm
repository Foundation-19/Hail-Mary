// Shotguns!

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot
	name = "\improper Heavy vehicular shotgun"
	desc = "A shotgun that's modified to be mounted on a vehicle, fires a volley of heavy pellets."
	icon_state = "vehicle_scatter"
	fire_sound = 'sound/weapons/sound_weapons_mech_shotgun.ogg'
	equip_cooldown = 15
	projectile = /obj/item/projectile/bullet/pellet/shotgun_trainshot/tracer
	projectiles = 24
	projectiles_cache = 24
	projectiles_cache_max = 144
	projectiles_per_shot = 6
	variance = 25
	harmful = TRUE
	ammo_type = "scattershot"

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot/improvised
	name = "\improper Improvised vehicular shotgun"
	desc = "A shotgun built from scrap metal, fits to a combat vehicle, fires a volley of pellets."
	icon_state = "vehicle_scatter_makeshift"
	fire_sound = 'sound/f13weapons/auto5.ogg'
	equip_cooldown = 20
	projectile = /obj/item/projectile/bullet/pellet/shotgun_buckshot/tracer
	projectiles = 40
	projectiles_cache = 40
	projectiles_cache_max = 160
	projectiles_per_shot = 7
	variance = 25
	harmful = TRUE
	ammo_type = "scattershot"

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot/rapid
	name = "\improper Rapid-fire vehicular shotgun"
	desc = "A rapid-fire shotgun fitted for mounting on a combat vehicle, fires fewer heavy pellets, but faster."
	icon_state = "vehicle_scatter_rapid"
	fire_sound = 'sound/weapons/sound_weapons_mech_mortar.ogg'
	equip_cooldown = 8
	projectile = /obj/item/projectile/bullet/pellet/shotgun_trainshot/tracer
	projectiles = 40
	projectiles_cache = 40
	projectiles_cache_max = 200
	projectiles_per_shot = 5
	variance = 25
	is_automatic = TRUE
	harmful = TRUE
	ammo_type = "scattershot"

// LMG!

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg
	name = "\improper Vehicular LMG"
	desc = "A machinegun chambered in 9mm to be mounted on combat vehicles. Fires a two-round burst."
	icon_state = "vehicle_lmg"
	fire_sound = 'sound/weapons/sound_weapons_mech_autocannon.ogg'
	equip_cooldown = 8
	projectile = /obj/item/projectile/bullet/c9mm/tracer
	projectiles = 300
	projectiles_cache = 300
	projectiles_cache_max = 1200
	projectiles_per_shot = 2
	is_automatic = TRUE
	variance = 6
	randomspread = 1
	projectile_delay = 2
	harmful = TRUE
	ammo_type = "lmg"

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/rapid
	name = "\improper Rapid-fire vehicular LMG"
	desc = "A machinegun that's a real machinegun. Can be fired in full-auto by holding down the trigger, for combat vehicles."
	icon_state = "vehicle_lmg_rapid"
	fire_sound = 'sound/f13weapons/bozar_fire.ogg'
	equip_cooldown = 1
	projectile_delay = 1
	projectile = /obj/item/projectile/bullet/c9mm/tracer
	projectiles = 50
	projectiles_cache = 50
	projectiles_cache_max = 500
	variance = 6
	projectiles_per_shot = 1
	randomspread = 1.08
	harmful = TRUE
	ammo_type = "lmg"

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg/improvised
	name = "\improper Improvised vehicular LMG"
	desc = "A improvised machinegun chambered in 9mm, fitted for combat vehicles."
	icon_state = "vehicle_lmg_makeshift"
	fire_sound = 'sound/f13weapons/boltfire.ogg'
	equip_cooldown = 10
	projectile = /obj/item/projectile/bullet/c9mm/improvised/tracer
	projectiles = 25
	projectiles_cache = 25
	projectiles_cache_max = 1200
	projectiles_per_shot = 2
	variance = 6
	is_automatic = TRUE
	randomspread = 1.2
	harmful = TRUE
	ammo_type = "lmg"

// Minigun!

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/minigun
	name = "\improper Vehicular minigun"
	desc = "A minigun, capable of firing in full-auto but builds up heat rapidly. fitted for combat vehicles."
	icon_state = "vehicle_lmg_minigun"
	fire_sound = 'sound/f13weapons/antimaterielfire.ogg'
	equip_cooldown = 1
	projectile = /obj/item/projectile/bullet/c9mm/improvised/tracer
	projectiles = 100
	projectiles_cache = 200
	projectiles_cache_max = 600
	projectiles_per_shot = 1
	variance = 6
	is_automatic = TRUE
	randomspread = 112
	harmful = TRUE
	ammo_type = "minigun"
	var/overheat = 0
	var/overheat_max = 160
	var/heat_diffusion = 2.5 //How much heat is lost per tick
	var/damage = 25

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/minigun/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/minigun/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/minigun/process()
	overheat = max(0, overheat - heat_diffusion)

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/minigun/action(atom/target, params)
	if(!action_checks(target))
		return 0
	var/turf/curloc = get_turf(chassis)
	var/turf/targloc = get_turf(target)
	if (!targloc || !istype(targloc) || !curloc)
		return 0
	if (targloc == curloc)
		return 0
	if(overheat < overheat_max)
		overheat += projectiles_per_shot
	else
		chassis.occupant_message("The gun's heat sensor locked the trigger to prevent barrel damage.")
		return
	chassis.occupant.DelayNextAction(3)
	set_ready_state(0)
	for(var/i=1 to get_shot_amount())
		var/obj/item/projectile/A = new projectile(curloc)
		A.firer = chassis.occupant
		A.original = target
		A.damage = damage
		if(!A.suppressed && firing_effect_type)
			new firing_effect_type(get_turf(src), chassis.dir)

		var/spread = 0
		if(variance)
			if(randomspread)
				spread = round((rand() - 0.5) * variance)
			else
				spread = round((i / projectiles_per_shot - 0.5) * variance)
		A.preparePixelProjectile(target, chassis.occupant, params, spread)

		A.fire()
		overheat++
		projectiles--
		playsound(chassis, fire_sound, 50, 1)
		chassis.occupant.DelayNextAction(1)

	if(kickback)
		chassis.newtonian_move(turn(chassis.dir,180))

	return 1
