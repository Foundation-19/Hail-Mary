/obj/item/projectile/rock
	name = "rock"
	icon = 'fallout/icons/objects/c13ammo.dmi'
	icon_state = "rock"
	damage = BULLET_DAMAGE_PISTOL_10MM
	stamina = BULLET_STAMINA_PISTOL_10MM
	spread = BULLET_SPREAD_SURPLUS
	recoil = BULLET_RECOIL_PISTOL_10MM

	pixels_per_second = BULLET_SPEED_PISTOL_22
	damage_falloff = BULLET_FALLOFF_DEFAULT_PISTOL_LIGHT

	range = 50
	damage_type = BRUTE
	nodamage = FALSE
	candink = TRUE
	flag = "bullet"
	hitsound_wall = "ricochet"
	impact_effect_type = /obj/effect/temp_visual/impact_effect

/obj/item/projectile/brick
	name = "brick"
	icon = 'fallout/icons/objects/brick.dmi'
	icon_state = "brick"
	damage = BULLET_DAMAGE_PISTOL_44
	stamina = BULLET_STAMINA_PISTOL_44
	spread = BULLET_SPREAD_SURPLUS
	recoil = BULLET_RECOIL_PISTOL_44

	pixels_per_second = BULLET_SPEED_PISTOL_22
	damage_falloff = BULLET_FALLOFF_DEFAULT_PISTOL_LIGHT

	range = 50
	damage_type = BRUTE
	nodamage = FALSE
	candink = TRUE
	flag = "bullet"
	hitsound_wall = "ricochet"
	impact_effect_type = /obj/effect/temp_visual/impact_effect

/obj/item/projectile/flintlock
	name = "musket ball"
	icon_state = "musket"
	damage = BULLET_DAMAGE_FLINTLOCK_MATCH
	stamina = BULLET_STAMINA_FLINTLOCK
	spread = 15
	recoil = BULLET_RECOIL_FLINTLOCK
	wound_bonus = BULLET_WOUND_FLINTLOCK_MATCH

	pixels_per_second = BULLET_SPEED_FLINTLOCK_MATCH
	damage_falloff = BULLET_FALLOFF_DEFAULT_PISTOL_LIGHT

	damage_type = BRUTE
	flag = "bullet"
	hitsound_wall = "ricochet"
	impact_effect_type = /obj/effect/temp_visual/impact_effect
	icon_state = "musket"

/obj/item/projectile/flintlock/minie
	name = "minie ball"
	damage = BULLET_DAMAGE_FLINTLOCK
	stamina = BULLET_STAMINA_FLINTLOCK
	spread = -15 // shockingly accurate
	recoil = BULLET_RECOIL_FLINTLOCK
	wound_bonus = BULLET_WOUND_FLINTLOCK

	pixels_per_second = BULLET_SPEED_FLINTLOCK
	damage_falloff = BULLET_FALLOFF_DEFAULT_PISTOL_LIGHT

	range = 50
	damage_type = BRUTE
	nodamage = FALSE
	candink = TRUE
	flag = "bullet"
	hitsound_wall = "ricochet"
	impact_effect_type = /obj/effect/temp_visual/impact_effect

/obj/item/projectile/flintlock/rubber
	name = "superball"
	icon_state = "musket_rubber"
	damage = RUBBERY_DAMAGE_FLINTLOCK
	stamina = RUBBERY_STAMINA_FLINTLOCK
	spread = BULLET_SPREAD_SURPLUS
	recoil = BULLET_RECOIL_FLINTLOCK
	wound_bonus = RUBBERY_WOUND_FLINTLOCK

	flag = "bullet"
	hitsound_wall = "ricochet"
	impact_effect_type = /obj/effect/temp_visual/impact_effect

/obj/item/projectile/rock/cannonball
	name = "iron cannon ball"
	icon = 'icons/fallout/objects/guns/projectiles.dmi'
	icon_state = "cannon"
	damage = 70
	armour_penetration = -0.2
	sharpness = SHARP_NONE
	var/sturdy = list(
	/turf/closed,
	/obj/mecha,
	/obj/machinery/door,
	/obj/structure
	)

/obj/item/projectile/rock/cannonball/on_hit(atom/target, blocked=0)
	..()
	for(var/i in sturdy)
		if(istype(target, i))
			explosion(target, 0, 1, 1, 2)
			return BULLET_ACT_HIT
	new /obj/item/broken_missile(get_turf(src), 1)
