/obj/item/mecha_parts/mecha_equipment/weapon/energy/laser // AER9
	equip_cooldown = 7
	name = "\improper mounted laser rifle"
	desc = "A mounted laser rifle, drawing off the vehicle's alternator. Fires basic lasers."
	icon_state = "mecha_laser"
	energy_drain = 50
	projectile = /obj/item/projectile/beam/laser/lasgun/hitscan
	fire_sound = 'sound/weapons/laser.ogg'
	harmful = TRUE

/obj/item/mecha_parts/mecha_equipment/weapon/energy/laser/heavy // AER12
	equip_cooldown = 12
	name = "\improper mounted laser cannon"
	desc = "A mounted laser rifle, drawing off the vehicle's alternator. Fires heavy lasers. "
	icon_state = "mecha_laser_heavy"
	energy_drain = 100
	projectile = /obj/item/projectile/beam/laser/aer12/hitscan
	fire_sound = 'sound/weapons/lasercannonfire.ogg'

/obj/item/mecha_parts/mecha_equipment/weapon/energy/plasma // Plasma Pistol/Cannon
	equip_cooldown = 20
	name = "\improper mounted plasma gun"
	desc = "A mounted plasma weapon, seemingly non-OEM based running off the vehicle's alternator. Fires large globules of burning plasma. "
	icon_state = "mecha_plasma_gun"
	energy_drain = 200
	projectile = /obj/item/projectile/energy/plasmabolt/rifle
	fire_sound = 'sound/weapons/lasercannonfire.ogg'