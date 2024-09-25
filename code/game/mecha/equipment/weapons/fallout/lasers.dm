// Small laser!

/obj/item/mecha_parts/mecha_equipment/weapon/energy/laser
	equip_cooldown = 7
	name = "\improper CH-PS \"Immolator\" laser"
	desc = "A weapon for combat exosuits. Shoots basic lasers."
	icon_state = "mecha_laser"
	energy_drain = 50
	projectile = /obj/item/projectile/beam/laser/mech/light
	fire_sound = 'sound/weapons/laser.ogg'
	harmful = TRUE

// Big laser!

/obj/item/mecha_parts/mecha_equipment/weapon/energy/laser/heavy
	equip_cooldown = 14
	name = "\improper CH-LC \"Solaris\" laser cannon"
	desc = "A weapon for combat exosuits. Shoots heavy lasers."
	icon_state = "mecha_laser"
	energy_drain = 75
	projectile = /obj/item/projectile/beam/laser/mech/heavy
	fire_sound = 'sound/weapons/lasercannonfire.ogg'

// Pulse!

/obj/item/mecha_parts/mecha_equipment/weapon/energy/pulse
	equip_cooldown = 40
	name = "\improper MKII heavy pulse cannon"
	desc = "A weapon for combat exosuits. Shoots powerful destructive blasts."
	icon_state = "mecha_pulse"
	energy_drain = 500
	projectile = /obj/item/projectile/beam/laser/mech/pulse
	fire_sound = 'sound/weapons/marauder.ogg'
	harmful = TRUE
