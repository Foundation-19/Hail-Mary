// In this document: Securitron, Sentry Bot, and variants

/////////////////
// SECURITRON  //
/////////////////

// BASE SECURITRON - TV-head wheeled robot, ranged burst fire
/mob/living/simple_animal/hostile/securitron
	name = "securitron"
	desc = "A pre-War type of securitron.<br>Extremely dangerous machine."
	icon = 'icons/fallout/mobs/robots/wasterobots.dmi'
	icon_state = "securitron"
	icon_living = "securitron"
	icon_dead = "securitron_dead"
	
	mob_biotypes = MOB_ROBOTIC|MOB_INORGANIC
	mob_armor = ARMOR_VALUE_ROBOT_SECURITY
	
	maxHealth = 100
	health = 100
	move_to_delay = 2.75
	turns_per_move = 5
	stamcrit_threshold = SIMPLEMOB_NO_STAMCRIT
	sentience_type = SENTIENCE_BOSS
	
	melee_damage_lower = 5
	melee_damage_upper = 10
	harm_intent_damage = 8
	
	aggro_vision_range = 7
	vision_range = 8
	robust_searching = TRUE
	
	response_help_simple = "pokes"
	response_disarm_simple = "shoves"
	response_harm_simple = "hits"
	attack_verb_simple = "punches"
	attack_sound = 'sound/weapons/punch1.ogg'
	
	speak = list("Stop Right There Criminal.")
	speak_chance = 1
	emote_hear = list("Beeps.")
	emote_taunt = list("readies its arm gun")
	taunt_chance = 30
	
	emp_flags = list(
		MOB_EMP_STUN,
		MOB_EMP_BERSERK,
		MOB_EMP_DAMAGE,
		MOB_EMP_SCRAMBLE
	)
	
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	
	faction = list("wastebot")
	a_intent = INTENT_HARM
	check_friendly_fire = TRUE
	del_on_death = TRUE
	healable = FALSE
	blood_volume = 0
	
	move_resist = MOVE_FORCE_OVERPOWERING
	environment_smash = ENVIRONMENT_SMASH_NONE
	
	loot = list(
		/obj/effect/decal/cleanable/robot_debris,
		/obj/item/stack/crafting/electronicparts/three
	)
	
	can_ghost_into = TRUE
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS
	
	// Z-movement - wheels, no ladders
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 30

	can_open_doors = TRUE
	can_open_airlocks = TRUE
	
	// Pure ranged - burst fire pistol
	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 1
	
	ranged_ignores_vision = TRUE
	auto_fire_delay = GUN_AUTOFIRE_DELAY_SLOW
	extra_projectiles = 2
	projectiletype = /obj/item/projectile/bullet/c9mm/simple
	projectilesound = 'sound/f13weapons/varmint_rifle.ogg'
	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(PISTOL_LIGHT_VOLUME),
		SP_VOLUME_SILENCED(PISTOL_LIGHT_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(PISTOL_LIGHT_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(PISTOL_LIGHT_DISTANT_SOUND),
		SP_DISTANT_RANGE(PISTOL_LIGHT_RANGE_DISTANT)
	)

/mob/living/simple_animal/hostile/securitron/Aggro()
	. = ..()
	if(.)
		return
	summon_backup(10)

/mob/living/simple_animal/hostile/securitron/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// Friendly fire resistance + defensive grenade release
/mob/living/simple_animal/hostile/securitron/bullet_act(obj/item/projectile/Proj)
	if(!Proj)
		CRASH("[src] securitron invoked bullet_act() without a projectile")
	
	if(Proj.firer && istype(Proj.firer, /mob/living/simple_animal/hostile/securitron))
		var/original_damage = Proj.damage
		Proj.damage *= 0.2
		. = ..()
		Proj.damage = original_damage
		return
	
	// Chance to release defensive grenade when shot
	if(prob(5) && health > 1)
		var/flashbang_turf = get_turf(src)
		if(!flashbang_turf)
			return ..()
		var/obj/item/grenade/S
		switch(rand(1, 10))
			if(1)
				S = new /obj/item/grenade/flashbang/sentry(flashbang_turf)
			if(2)
				S = new /obj/item/grenade/stingbang(flashbang_turf)
			if(3 to 10)
				S = new /obj/item/grenade/smokebomb(flashbang_turf)
		visible_message(span_danger("\The [src] releases a defensive [S]!"))
		S.preprime(user = null)
	
	return ..()

// Death sequence - beeps then explodes
/mob/living/simple_animal/hostile/securitron/proc/do_death_beep()
	playsound(src, 'sound/machines/triple_beep.ogg', 75, TRUE)
	visible_message(span_warning("You hear an ominous beep coming from [src]!"), span_warning("You hear an ominous beep!"))

/mob/living/simple_animal/hostile/securitron/proc/self_destruct()
	explosion(src, 1, 2, 4, 4)

/mob/living/simple_animal/hostile/securitron/death()
	do_sparks(3, TRUE, src)
	for(var/i in 1 to 3)
		addtimer(CALLBACK(src, PROC_REF(do_death_beep)), i * 1 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(self_destruct)), 4 SECONDS)
	return ..()

// NSB SECURITRON - raider bunker variant, doesn't retreat
/mob/living/simple_animal/hostile/securitron/nsb
	name = "Securitron"
	faction = list("raider")
	obj_damage = 300
	can_ghost_into = FALSE
	
	retreat_distance = null  // Perish, mortal

/////////////////
// SENTRY BOT  //
/////////////////

// BASE SENTRY BOT - heavy gatling laser platform
/mob/living/simple_animal/hostile/securitron/sentrybot
	name = "sentry bot"
	desc = "A pre-war military robot armed with a deadly gatling laser and covered in thick armor plating."
	icon_state = "sentrybot"
	icon_living = "sentrybot"
	icon_dead = "sentrybot_dead"
	
	mob_armor = ARMOR_VALUE_ROBOT_MILITARY
	
	maxHealth = 150
	health = 150
	stat_attack = UNCONSCIOUS
	del_on_death = FALSE  // Explodes instead
	
	melee_damage_lower = 24
	melee_damage_upper = 55
	attack_verb_simple = "pulverizes"
	attack_sound = 'sound/weapons/punch1.ogg'
	
	emote_taunt = list("spins its barrels")
	emote_taunt_sound = list(
		'sound/f13npc/sentry/taunt1.ogg',
		'sound/f13npc/sentry/taunt2.ogg',
		'sound/f13npc/sentry/taunt3.ogg',
		'sound/f13npc/sentry/taunt4.ogg',
		'sound/f13npc/sentry/taunt5.ogg',
		'sound/f13npc/sentry/taunt6.ogg'
	)
	aggrosound = list(
		'sound/f13npc/sentry/aggro1.ogg',
		'sound/f13npc/sentry/aggro2.ogg',
		'sound/f13npc/sentry/aggro3.ogg',
		'sound/f13npc/sentry/aggro4.ogg',
		'sound/f13npc/sentry/aggro5.ogg'
	)
	idlesound = list(
		'sound/f13npc/sentry/idle1.ogg',
		'sound/f13npc/sentry/idle2.ogg',
		'sound/f13npc/sentry/idle3.ogg',
		'sound/f13npc/sentry/idle4.ogg'
	)
	
	loot = list(
		/obj/effect/decal/cleanable/robot_debris,
		/obj/item/stack/crafting/electronicparts/five,
		/obj/item/stock_parts/cell/ammo/mfc
	)
	
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	
	// Pure ranged - gatling laser
	combat_mode = COMBAT_MODE_RANGED
	retreat_distance = 5
	minimum_distance = 1
	
	ranged_cooldown_time = 40  // Brrrrrrrt
	extra_projectiles = 2  // 3 shots per burst
	projectiletype = /obj/item/projectile/beam/laser/pistol/ultraweak
	projectilesound = 'sound/weapons/laser.ogg'
	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(LASER_VOLUME),
		SP_VOLUME_SILENCED(LASER_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(LASER_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(LASER_DISTANT_SOUND),
		SP_DISTANT_RANGE(LASER_RANGE_DISTANT)
	)
	
	var/warned = FALSE  // For low health warning sound

/mob/living/simple_animal/hostile/securitron/sentrybot/Life()
	. = ..()
	if(!warned && health <= 50)
		warned = TRUE
		playsound(src, 'sound/f13npc/sentry/systemfailure.ogg', 75, FALSE)

// NSB SENTRY BOT - raider faction
/mob/living/simple_animal/hostile/securitron/sentrybot/nsb
	name = "sentry bot"
	obj_damage = 300
	can_ghost_into = FALSE

// NSB RIOT SENTRY - non-lethal breacher
/mob/living/simple_animal/hostile/securitron/sentrybot/nsb/riot
	name = "riot-control sentry bot"
	desc = "A pre-war military robot armed with a modified breacher shotgun and covered in thick armor plating."
	
	retreat_distance = null  // Gets right in your face
	extra_projectiles = 0
	
	projectiletype = /obj/item/projectile/bullet/shotgun_beanbag
	projectilesound = 'sound/f13weapons/riot_shotgun.ogg'
	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(SHOTGUN_VOLUME),
		SP_VOLUME_SILENCED(SHOTGUN_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(SHOTGUN_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(SHOTGUN_DISTANT_SOUND),
		SP_DISTANT_RANGE(SHOTGUN_RANGE_DISTANT)
	)

// PLAYABLE SENTRY BOT
/mob/living/simple_animal/hostile/securitron/sentrybot/playable
	maxHealth = 50
	health = 50
	speed = 1
	attack_verb_simple = "clamps"
	see_in_dark = 8
	environment_smash = ENVIRONMENT_SMASH_RWALLS
	wander = FALSE
	force_threshold = 15
	anchored = FALSE
	del_on_death = FALSE
	ranged = FALSE
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null

// LIL' CHEW-CHEW - unique named boss
/mob/living/simple_animal/hostile/securitron/sentrybot/chew
	name = "lil' chew-chew"
	desc = "An oddly scorched pre-war military robot armed with a deadly gatling laser and covered in thick, oddly blue armor plating, the name Lil' Chew-Chew scratched onto its front armour crudely, highlighted by small bits of white paint. There seems to be an odd pack on the monstrosity's back with a chute at the bottom - there's the most scorch-marks on the robot here, so it's safe to assume this robot is capable of explosions. Better watch out!"
	
	mob_armor = ARMOR_VALUE_ROBOT_MILITARY_HEAVY
	
	maxHealth = 1000
	health = 1000
	obj_damage = 300
	extra_projectiles = 6
	
	retreat_distance = null  // Perish, mortal
	environment_smash = ENVIRONMENT_SMASH_RWALLS
	
	color = "#75FFE2"
	aggro_vision_range = 15
	can_ghost_into = FALSE
	
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1  // Can't self-harm with explosion spam

/mob/living/simple_animal/hostile/securitron/sentrybot/chew/bullet_act(obj/item/projectile/Proj)
	if(!Proj)
		CRASH("[src] sentrybot invoked bullet_act() without a projectile")
	if(prob(10) && health > 1)
		visible_message(span_danger("\The [src] releases a defensive explosive!"))
		explosion(get_turf(src), -1, -1, 2, flame_range = 4)
	return ..()

// BIG CHEW-CHEW - bunker boss variant
/mob/living/simple_animal/hostile/securitron/sentrybot/chew/strong
	name = "big chew-chew"
	desc = "An oddly scorched pre-war military robot armed with a deadly gatling laser firing high-penetration experimental lasers and covered in thick, dark blue armor plating, the name Big Chew-Chew scratched onto its front armour crudely, highlighted by small bits of white paint. There seems to be an odd pack on the monstrosity's back with a chute at the bottom - it's safe to assume this robot is capable of explosions. Better watch out!"
	
	maxHealth = 1500
	health = 1500
	extra_projectiles = 4  // Fires a bit less than lil chew-chew
	armour_penetration = 1
	move_to_delay = 2.75
	rapid_melee = 2
	
	retreat_distance = null  // Is going to punch you
	
	color = "#3444C8"  // Dark blue
	
	emp_flags = list()  // No EMP instakill
	projectiletype = /obj/item/projectile/beam/laser/pistol/ultraweak/chew/strong

// SUICIDE SENTRY - rushes in and explodes
/mob/living/simple_animal/hostile/securitron/sentrybot/suicide
	name = "explosive sentry bot"
	desc = "A pre-war military robot armed with a deadly gatling laser and covered in thick armor plating. Don't get too close to this one, it looks like it's rigged to blow!"
	
	maxHealth = 160
	health = 160
	color = "#B85C00"
	
	// Rushes target
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/securitron/sentrybot/suicide/AttackingTarget()
	. = ..()
	if(ishuman(target))
		addtimer(CALLBACK(src, PROC_REF(do_death_beep)), 1 SECONDS)
		addtimer(CALLBACK(src, PROC_REF(self_destruct)), 2 SECONDS)
