/obj/item/ammo_casing/caseless/magspear
	name = "magnetic spear"
	desc = "A reusable spear that is typically loaded into kinetic spearguns."
	projectile_type = /obj/item/projectile/bullet/reusable/magspear
	caliber = CALIBER_SPEAR
	icon_state = "magspear"
	throwforce = 15 //still deadly when thrown
	throw_speed = 3
	sound_properties = CSP_GAUSS

/obj/item/ammo_casing/caseless/laser
	name = "laser casing"
	desc = "You shouldn't be seeing this."
	caliber = CALIBER_LASER
	icon_state = "s-casing-live"
	projectile_type = /obj/item/projectile/beam
	fire_sound = 'sound/weapons/laser.ogg'
	firing_effect_type = /obj/effect/temp_visual/dir_setting/firing_effect/energy
	sound_properties = CSP_MISC

/obj/item/ammo_casing/caseless/laser/gatling
	caliber = CALIBER_LASERGATLING
	projectile_type = /obj/item/projectile/beam/laser/gatling
	variance = 0.5
	click_cooldown_override = 1

/obj/item/ammo_casing/caseless/flamethrower
	name = "napalm"
	desc = "a bunch of napalm fuel for a flamethrower. A bit useless now that it's been spilt on the ground."
	caliber = CALIBER_FUEL
	icon = 'icons/mob/robots.dmi'
	icon_state = "floor1"
	projectile_type = /obj/item/projectile/incendiary/flamethrower
	sound_properties = CSP_MISC
	var/flame_range = 6 //tiles the stream reaches before fizzling out
	var/flame_temperature = 700
	var/flame_volume = 50
	var/direct_burn_damage = 8 //instant burn damage applied per tick you're standing in the stream, on top of the lingering fire - a flamethrower should hurt the second it touches you, not just eventually
	var/ignite_fire_stacks = 5

//tinted copy of the stock beam effect so the flame stream reads as fire instead of a generic sci-fi beam
/obj/effect/ebeam/flamethrower
	name = "jet of flame"
	color = "#ff9933"
	alpha = 130 //a flat opaque bar reads as a solid snake - translucent + additive blending makes it read as glowing heat/fire instead
	blend_mode = BLEND_ADD
	light_color = LIGHT_COLOR_FIRE
	light_range = LIGHT_RANGE_FIRE

//spawns the fire effect on a tile and burns/ignites everyone standing on it - shared by both the traced line and its widening tiles
/obj/item/ammo_casing/caseless/flamethrower/proc/ignite_turf(turf/T)
	new /obj/effect/hotspot(T, flame_volume, flame_temperature) //turf/hotspot_expose() is stubbed out in this codebase, spawn the fire effect directly
	for(var/mob/living/L in T)
		L.adjust_fire_stacks(ignite_fire_stacks)
		L.IgniteMob()
		//run through "fire" armor like any other damage source, instead of a flat adjustFireLoss() bypass - so fire-rated suits (hazmat, power armor) give real counterplay against being hosed
		var/blocked = L.run_armor_check(null, "fire")
		L.apply_damage(direct_burn_damage, BURN, null, blocked)

//guaranteed line-of-fire, no RNG spread - a stream of napalm doesn't miss, it just has a short reach and stops at walls
/obj/item/ammo_casing/caseless/flamethrower/fire_casing(atom/target, mob/living/user, params, distro, quiet, zone_override, spread, damage_multiplier = 1, penetration_multiplier = 1, projectile_speed_multiplier = 1, atom/fired_from)
	var/turf/userloc = get_turf(user)
	var/turf/targloc = get_turf(target)
	//held-mouse autofire's "target" arg goes stale mid-drag (BYOND only updates it on certain click events) - read the live cursor instead, so the stream actually follows where you're pointing right now
	//use the raw screen-loc math (same as click_catcher) instead of mouseObject - mouseObject snaps to whatever atom last got hovered/dragged over and loses diagonal precision near tile edges
	if(istype(user) && user.client?.mouseParams)
		var/list/modifiers = params2list(user.client.mouseParams)
		var/turf/origin = get_turf(user.client.eye || user)
		var/turf/live_targloc = params2turf(modifiers["screen-loc"], origin, user.client)
		if(istype(live_targloc))
			targloc = live_targloc
	if(!istype(userloc) || !istype(targloc))
		return FALSE

	QDEL_NULL(BB)

	//sample the exact same trigonometric centerline /datum/beam/proc/Draw() uses below, instead of a separate getline() Bresenham guess -
	//that way the tiles that actually burn are always the tiles the beam graphic is actually drawn over, angle for angle
	var/Angle = round(Get_Angle(userloc, targloc))
	var/DX = (32 * targloc.x + targloc.pixel_x) - (32 * userloc.x + userloc.pixel_x)
	var/DY = (32 * targloc.y + targloc.pixel_y) - (32 * userloc.y + userloc.pixel_y)
	var/beam_length = round(sqrt(DX ** 2 + DY ** 2))
	var/turf/previous = userloc
	var/turf/last_turf = userloc
	var/tiles_burned = 0
	for(var/N = 0, N < beam_length, N += 32)
		var/Pixel_x = DX ? round(sin(Angle) + 32 * sin(Angle) * (N + 16) / 32) : 0
		var/Pixel_y = DY ? round(cos(Angle) + 32 * cos(Angle) * (N + 16) / 32) : 0
		var/turf/T = locate(userloc.x + round(Pixel_x / 32), userloc.y + round(Pixel_y / 32), userloc.z)
		if(!istype(T) || T == last_turf)
			continue
		last_turf = T
		if(tiles_burned >= flame_range)
			break
		//reachableAdjacentTurfs() is an A* pathing helper that only ever returns CARDINAL neighbours - using it here silently capped the stream to N/E/S/W. Just check the tile itself for a wall/dense blocker instead, which works for diagonals too.
		//exclude_mobs = TRUE - mobs are dense too, but a flamethrower should wash over a person and keep going, not treat them as a wall
		if(is_blocked_turf(T, TRUE))
			break //flame doesn't pass through walls
		ignite_turf(T)
		previous = T
		tiles_burned++

	//the turf-by-turf hotspots handle the actual game logic (ignite/damage), but on their own they look like disconnected blobs, especially off-angle - draw a real free-angle beam over them so the stream visually arcs to exactly where it stopped
	if(previous != userloc)
		user.Beam(previous, icon_state = "b_beam", time = 4, maxdistance = flame_range + 1, beam_type = /obj/effect/ebeam/flamethrower, beam_sleep_time = 1)

	if(istype(user))
		user.DelayNextAction(considered_action = TRUE, immediate = FALSE)
	user.newtonian_move(get_dir(target, user))
	update_icon()
	deduct_powder_and_bullet_mats()

	//casing_ejector is FALSE (no shells fly out of a flamethrower) so nothing else clears the spent round from the chamber - do it ourselves or the gun jams after one shot
	if(istype(fired_from, /obj/item/gun))
		var/obj/item/gun/gonne = fired_from
		if(gonne.chambered == src)
			gonne.chambered = null
			gonne.update_icon()
	qdel(src)
	return TRUE

//throwin' rock, for throwin'. obtained via *rocks
/obj/item/ammo_casing/caseless/rock
	name = "rock"
	desc = "a nice hefty rock, for bashing over someone's head or throwing at someone's head."
	icon = 'icons/obj/c13ammo.dmi'
	icon_state = "rock"
	item_state = "rock"
	force = 15
	throwforce = 20
	throw_speed = 1 // you can see it comin'
	throw_range = 10 //you can chuck a rock pretty far. good luck hitting anything though
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FIRE_PROOF
	total_mass = TOTAL_MASS_SMALL_ITEM
	attack_verb = list("attacked", "bashed", "brained", "thunked", "clobbered")
	attack_speed = CLICK_CD_MELEE
	max_integrity = 200
	armor = ARMOR_VALUE_GENERIC_ITEM
	caliber = CALIBER_ROCK
	projectile_type = /obj/item/projectile/rock
	is_pickable = TRUE
	custom_materials = list(/datum/material/glass = 50) //rocks are made of silicon, same as sand
	fire_power = CASING_POWER_LIGHT_PISTOL * CASING_POWER_MOD_SURPLUS
	sound_properties = CSP_ROCK

/obj/item/ammo_casing/caseless/brick
	name = "brick"
	desc = "a weighty brick for bashing heads."
	icon = 'icons/obj/brick.dmi'
	icon_state = "brick"
	item_state = "brick"
	force = 15
	throwforce = 20
	throw_speed = 1
	throw_range = 10
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FIRE_PROOF
	total_mass = TOTAL_MASS_SMALL_ITEM
	attack_verb = list("attacked", "bashed", "brained", "thunked", "clobbered")
	attack_speed = CLICK_CD_MELEE
	max_integrity = 200
	armor = ARMOR_VALUE_GENERIC_ITEM
	caliber = CALIBER_BRICK
	projectile_type = /obj/item/projectile/brick
	is_pickable = TRUE
	custom_materials = list(/datum/material/glass = 50)
	fire_power = CASING_POWER_LIGHT_PISTOL * CASING_POWER_MOD_SURPLUS
	sound_properties = CSP_ROCK

/obj/item/ammo_casing/caseless/flintlock
	name = "packed blackpowder cartridge"
	desc = "a measure of blackpowder and round musket ball."
	caliber = CALIBER_FLINTLOCK
	icon = 'icons/obj/c13ammo.dmi'
	icon_state = "flintlock_casing"
	projectile_type = /obj/item/projectile/flintlock
	custom_materials = list(
		/datum/material/iron = MATS_FLINTLOCK_LIGHT_BULLET, // what casing? ~ uwu ~
		/datum/material/blackpowder = MATS_FLINTLOCK_LIGHT_POWDER)
	sound_properties = CSP_FLINTLOCK
	custom_materials = list(/datum/material/blackpowder = 500)
	w_class = WEIGHT_CLASS_SMALL
	variance = 5

/obj/item/ammo_casing/caseless/flintlock/minie
	name = "packed blackpowder minie cartridge"
	desc = "A conical bullet designed to give flintlocks a bit more of a modern edge."
	caliber = CALIBER_FLINTLOCK
	icon = 'icons/obj/c13ammo.dmi'
	icon_state = "flintlock_casing_minie"
	projectile_type = /obj/item/projectile/flintlock/minie
	sound_properties = CSP_FLINTLOCK
	custom_materials = list(
		/datum/material/iron = MATS_FLINTLOCK_LIGHT_POWDER, // what casing? ~ uwu ~
		/datum/material/blackpowder = MATS_FLINTLOCK_HEAVY_POWDER)
	w_class = WEIGHT_CLASS_SMALL
	variance = -5

/obj/item/ammo_casing/caseless/flintlock/rubber
	name = "packed blackpowder rubber cartridge"
	desc = "A superball mashed into a blackpowder cartridge. It's not very effective, but it's fun to shoot. Less than lethal?"
	caliber = CALIBER_FLINTLOCK
	icon = 'icons/obj/c13ammo.dmi'
	icon_state = "flintlock_casing_rubber"
	projectile_type = /obj/item/projectile/flintlock/rubber
	sound_properties = CSP_FLINTLOCK
	custom_materials = list(
		/datum/material/iron = MATS_FLINTLOCK_LIGHT_POWDER, // what casing? ~ uwu ~
		/datum/material/blackpowder = MATS_FLINTLOCK_HEAVY_POWDER)
	w_class = WEIGHT_CLASS_SMALL

