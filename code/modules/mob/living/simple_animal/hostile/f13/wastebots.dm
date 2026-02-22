// In this document: Handy, Gutsy, Protectrons, Robobrains, Assaultrons, Liberator

// Shared robot properties as a define for clarity:
// - mob_biotypes = MOB_ROBOTIC|MOB_INORGANIC
// - damage_coeff: immune to TOX, CLONE, STAMINA, OXY
// - atmos_requirements: no atmosphere needed
// - blood_volume = 0, healable = FALSE
// - del_on_death = TRUE (except playable variants)

///////////////
// MR. HANDY //
///////////////

// BASE HANDY - melee saw bot
/mob/living/simple_animal/hostile/handy
	name = "mr. handy"
	desc = "A crazed pre-war household assistant robot, armed with a cutting saw."
	icon = 'icons/fallout/mobs/robots/wasterobots.dmi'
	icon_state = "handy"
	icon_living = "handy"
	icon_dead = "robot_dead"
	
	mob_biotypes = MOB_ROBOTIC|MOB_INORGANIC
	mob_armor = ARMOR_VALUE_ROBOT_CIVILIAN
	
	maxHealth = 100
	health = 100
	speed = 2
	stamcrit_threshold = SIMPLEMOB_NO_STAMCRIT
	
	melee_damage_lower = 12
	melee_damage_upper = 24
	
	robust_searching = TRUE
	stat_attack = CONSCIOUS
	
	move_resist = MOVE_FORCE_OVERPOWERING
	
	faction = list("wastebot")
	a_intent = INTENT_HARM
	gold_core_spawnable = HOSTILE_SPAWN
	check_friendly_fire = TRUE
	del_on_death = TRUE
	healable = FALSE
	blood_volume = 0
	
	gender = NEUTER
	
	emp_flags = list(
		MOB_EMP_STUN,
		MOB_EMP_BERSERK,
		MOB_EMP_DAMAGE,
		MOB_EMP_SCRAMBLE
	)
	
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	
	speak_emote = list("states")
	attack_verb_simple = "saws"
	attack_sound = 'sound/f13npc/handy/attack.wav'
	
	emote_taunt = list("raises a saw")
	emote_taunt_sound = list(
		'sound/f13npc/handy/taunt1.ogg',
		'sound/f13npc/handy/taunt2.ogg'
	)
	taunt_chance = 30
	aggrosound = list(
		'sound/f13npc/handy/aggro1.ogg',
		'sound/f13npc/handy/aggro2.ogg'
	)
	idlesound = list(
		'sound/f13npc/handy/idle1.wav',
		'sound/f13npc/handy/idle2.ogg',
		'sound/f13npc/handy/idle3.ogg'
	)
	death_sound = 'sound/f13npc/handy/robo_death.ogg'
	deathmessage = "blows apart!"
	
	loot = list(
		/obj/effect/decal/cleanable/robot_debris,
		/obj/item/stack/crafting/electronicparts/three
	)
	
	waddle_amount = 3
	waddle_up_time = 2
	waddle_side_time = 1
	
	can_ghost_into = TRUE
	desc_short = "A snooty robot with a circular saw."
	pop_required_to_jump_into = MED_MOB_MIN_PLAYERS
	
	send_mobs = null
	call_backup = null  // Robots don't call for organic backup
	
	// Z-movement - flies but slow
	can_z_move = TRUE
	can_climb_ladders = FALSE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 50

	can_open_doors = TRUE
	can_open_airlocks = TRUE
	
	// Pure melee - close range saw bot
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/handy/Initialize()
	. = ..()
	add_overlay("eyes-[initial(icon_state)]")

/mob/living/simple_animal/hostile/handy/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// Friendly fire resistance - wastebots are coordinated
/mob/living/simple_animal/hostile/handy/bullet_act(obj/item/projectile/P)
	if(P && P.firer && istype(P.firer, /mob/living/simple_animal/hostile/handy))
		var/original_damage = P.damage
		P.damage *= 0.2
		. = ..()
		P.damage = original_damage
		return
	return ..()

// PLAYABLE HANDY
/mob/living/simple_animal/hostile/handy/playable
	maxHealth = 300
	health = 300
	attack_verb_simple = "shoots a burst of flame at"
	see_in_dark = 8
	wander = FALSE
	force_threshold = 10
	anchored = FALSE
	del_on_death = FALSE
	dextrous = TRUE
	ranged = FALSE
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)

// NSB HANDY - raider bunker variant
/mob/living/simple_animal/hostile/handy/nsb
	name = "mr. handy"
	aggro_vision_range = 15
	faction = list("raider")
	obj_damage = 300
	can_ghost_into = FALSE

///////////////
// MR. GUTSY //
///////////////

// GUTSY - combat variant with plasma + flamer
/mob/living/simple_animal/hostile/handy/gutsy
	name = "mr. gutsy"
	desc = "A pre-war combat robot based off the Mr. Handy design, armed with plasma weaponry and a deadly close-range flamer."
	icon_state = "gutsy"
	icon_living = "gutsy"
	
	mob_armor = ARMOR_VALUE_ROBOT_MILITARY
	
	maxHealth = 100
	health = 100
	stat_attack = UNCONSCIOUS
	
	melee_damage_lower = 18
	melee_damage_upper = 64
	attack_sound = 'sound/items/welder.ogg'
	attack_verb_simple = "shoots a burst of flame at"
	
	can_ghost_into = FALSE
	
	emote_taunt = list("raises a flamer")
	emote_taunt_sound = list(
		'sound/f13npc/gutsy/taunt1.ogg',
		'sound/f13npc/gutsy/taunt2.ogg',
		'sound/f13npc/gutsy/taunt3.ogg',
		'sound/f13npc/gutsy/taunt4.ogg'
	)
	aggrosound = list(
		'sound/f13npc/gutsy/aggro1.ogg',
		'sound/f13npc/gutsy/aggro2.ogg',
		'sound/f13npc/gutsy/aggro3.ogg',
		'sound/f13npc/gutsy/aggro4.ogg',
		'sound/f13npc/gutsy/aggro5.ogg',
		'sound/f13npc/gutsy/aggro6.ogg'
	)
	idlesound = list(
		'sound/f13npc/gutsy/idle1.ogg',
		'sound/f13npc/gutsy/idle2.ogg',
		'sound/f13npc/gutsy/idle3.ogg'
	)
	
	loot = list(
		/obj/effect/decal/cleanable/robot_debris,
		/obj/item/stack/crafting/electronicparts/three,
		/obj/item/stock_parts/cell/ammo/mfc
	)
	
	desc_short = "A gutsy robot with a plasma gun."
	pop_required_to_jump_into = BIG_MOB_MIN_PLAYERS
	
	// Pure ranged - plasma gun
	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 4
	minimum_distance = 1
	
	ranged_cooldown_time = 2 SECONDS
	extra_projectiles = 1
	projectiletype = /obj/item/projectile/f13plasma/scatter
	projectilesound = 'sound/weapons/laser.ogg'
	projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(PLASMA_VOLUME),
		SP_VOLUME_SILENCED(PLASMA_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(PLASMA_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(PLASMA_DISTANT_SOUND),
		SP_DISTANT_RANGE(PLASMA_RANGE_DISTANT)
	)

// PLAYABLE GUTSY
/mob/living/simple_animal/hostile/handy/gutsy/playable
	speed = 1
	attack_verb_simple = "shoots a burst of flame at"
	see_in_dark = 8
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	wander = FALSE
	force_threshold = 10
	anchored = FALSE
	del_on_death = FALSE
	dextrous = TRUE
	ranged = FALSE
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)

// NSB GUTSY
/mob/living/simple_animal/hostile/handy/gutsy/nsb
	name = "mr. gutsy"
	aggro_vision_range = 15
	faction = list("raider")
	obj_damage = 300
	can_ghost_into = FALSE

// MR. BURNSY - flamer variant
/mob/living/simple_animal/hostile/handy/gutsy/flamer
	name = "Mr. Burnsy"
	desc = "A modified mr. gutsy, equipped with a more precise flamer, ditching its plasma weaponry."
	color = "#B85C00"
	can_ghost_into = FALSE
	
	projectiletype = /obj/item/projectile/bullet/incendiary/shotgun
	projectilesound = 'sound/magic/fireball.ogg'
	extra_projectiles = 1

///////////////
// LIBERATOR //
///////////////

// LIBERATOR - small Chinese PLA drone
/mob/living/simple_animal/hostile/handy/liberator
	name = "liberator"
	desc = "A small pre-War drone used by the People's Liberation Army."
	icon = 'icons/fallout/mobs/robots/weirdrobots.dmi'
	icon_state = "liberator"
	icon_living = "leberator"
	icon_dead = "liberator_d"
	icon_gib = "liberator_g"
	
	mob_armor = ARMOR_VALUE_ROBOT_SECURITY
	
	maxHealth = 50
	health = 50
	
	melee_damage_lower = 5
	melee_damage_upper = 10
	attack_verb_simple = "slaps"
	
	can_ghost_into = FALSE
	
	emote_taunt = list("levels its laser")
	emote_taunt_sound = null
	aggrosound = list('sound/f13npc/liberator/chineserobotcarinsurance.ogg')
	idlesound = null
	attack_sound = null
	death_sound = null
	
	loot = list(
		/obj/effect/decal/cleanable/robot_debris,
		/obj/item/stack/crafting/electronicparts/three,
		/obj/item/stock_parts/cell/ammo/mfc
	)
	
	desc_short = "A robot that shoots lasers."
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS
	
	// Pure ranged - laser pistol
	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 4
	minimum_distance = 1
	
	ranged_cooldown_time = 2 SECONDS
	extra_projectiles = 1
	projectiletype = /obj/item/projectile/beam/laser/pistol
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

// YELLOW LIBERATOR
/mob/living/simple_animal/hostile/handy/liberator/yellow
	icon_state = "liberator_y"
	icon_living = "leberator_y"
	icon_dead = "liberator_y_d"

///////////////
// ROBOBRAIN //
///////////////

// ROBOBRAIN - cyborg with laser
/mob/living/simple_animal/hostile/handy/robobrain
	name = "robobrain"
	desc = "A next-gen cyborg developed by General Atomic International."
	icon_state = "robobrain"
	icon_living = "robobrain"
	icon_dead = "robobrain_d"
	
	mob_armor = ARMOR_VALUE_ROBOT_SECURITY
	
	maxHealth = 110
	health = 110
	stat_attack = UNCONSCIOUS
	
	melee_damage_lower = 15
	melee_damage_upper = 37
	attack_verb_simple = "slaps"
	
	can_ghost_into = FALSE
	
	emote_taunt = list("levels its laser")
	emote_taunt_sound = null
	aggrosound = null
	idlesound = null
	attack_sound = null
	death_sound = null
	
	loot = list(
		/obj/effect/decal/cleanable/robot_debris,
		/obj/item/stack/crafting/electronicparts/three,
		/obj/item/stock_parts/cell/ammo/mfc
	)
	
	desc_short = "A brainy robot with lasers."
	
	// Mixed combat - has melee but prefers ranged
	combat_mode = COMBAT_MODE_MIXED
	ranged = TRUE
	retreat_distance = 4
	minimum_distance = 1
	
	ranged_cooldown_time = 2 SECONDS
	extra_projectiles = 1
	projectiletype = /obj/item/projectile/beam/laser
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

// NSB ROBOBRAIN
/mob/living/simple_animal/hostile/handy/robobrain/nsb
	name = "robobrain"
	aggro_vision_range = 15
	faction = list("raider")
	obj_damage = 300
	maxHealth = 300
	health = 300
	can_ghost_into = FALSE

/////////////////
// PROTECTRON  //
/////////////////

// BASE PROTECTRON - slow, laser-armed security bot
/mob/living/simple_animal/hostile/handy/protectron
	name = "protectron"
	desc = "A pre-war security robot armed with deadly lasers."
	icon = 'icons/fallout/mobs/robots/protectrons.dmi'
	icon_state = "protectron"
	icon_living = "protectron"
	icon_dead = "protectron_dead"
	
	mob_armor = ARMOR_VALUE_ROBOT_CIVILIAN
	
	maxHealth = 100
	health = 100
	speed = 4  // Noticeably slow
	move_to_delay = 4
	stat_attack = CONSCIOUS
	
	melee_damage_lower = 5  // Weak melee - it's a ranged bot
	melee_damage_upper = 10
	
	aggro_vision_range = 7
	vision_range = 8
	
	attack_verb_simple = list("baps", "bops", "boops", "smacks", "clamps", "pinches", "thumps", "fistos")
	attack_sound = 'sound/weapons/punch1.ogg'
	
	emote_taunt = list("raises its arm laser", "gets ready to rumble", "assumes the position", "whirls up its servos", "takes aim", "holds its ground")
	emote_taunt_sound = list(
		'sound/f13npc/protectron/taunt1.ogg',
		'sound/f13npc/protectron/taunt2.ogg',
		'sound/f13npc/protectron/taunt3.ogg'
	)
	taunt_chance = 30
	aggrosound = list(
		'sound/f13npc/protectron/aggro1.ogg',
		'sound/f13npc/protectron/aggro2.ogg',
		'sound/f13npc/protectron/aggro3.ogg',
		'sound/f13npc/protectron/aggro4.ogg'
	)
	idlesound = list(
		'sound/f13npc/protectron/idle1.ogg',
		'sound/f13npc/protectron/idle2.ogg',
		'sound/f13npc/protectron/idle3.ogg',
		'sound/f13npc/protectron/idle4.ogg'
	)
	
	attack_phrase = list(
		"Howdy pardner!",
		"Shoot out at the O.K. Corral!",
		"Go back to Oklahoma!",
		"Please assume the position.",
		"Protect and serve.",
		"Antisocial behavior detected.",
		"Criminal behavior will be punished.",
		"Please step into the open and identify yourself, law abiding citizens have nothing to fear."
	)
	
	loot = list(
		/obj/effect/decal/cleanable/robot_debris,
		/obj/item/stack/crafting/electronicparts/five
	)
	
	can_ghost_into = TRUE
	desc_short = "A clunky hunk of junk with a laser."
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS
	
	// Mixed combat - laser + melee when cornered. Slow so retreating is pointless.
	combat_mode = COMBAT_MODE_MIXED
	ranged = TRUE
	retreat_distance = 4
	minimum_distance = 1
	
	ranged_cooldown_time = 2 SECONDS
	extra_projectiles = 0  // One shot at a time on lowpop
	projectiletype = /obj/item/projectile/beam/laser/pistol
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

// PLAYABLE PROTECTRON
/mob/living/simple_animal/hostile/handy/protectron/playable
	melee_damage_lower = 25
	melee_damage_upper = 38
	speed = 2
	attack_verb_simple = "clamps"
	see_in_dark = 8
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	wander = FALSE
	force_threshold = 10
	anchored = FALSE
	del_on_death = FALSE
	ranged = FALSE
	emote_taunt_sound = null
	emote_taunt = null
	aggrosound = null
	idlesound = null
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)

// NSB PROTECTRON
/mob/living/simple_animal/hostile/handy/protectron/nsb
	name = "protectron"
	aggro_vision_range = 15
	faction = list("raider")
	obj_damage = 300
	can_ghost_into = FALSE

// TRADING PROTECTRON - pet/friendly variant
/mob/living/simple_animal/pet/dog/protectron
	name = "Trading Protectron"
	desc = "A standard RobCo RX2 V1.16.4 \"Trade-o-Vend\", loaded with Trade protocols.<br>Looks like it was kept operational for an indefinite period of time. Its body is covered in cracks and dents of various sizes.<br>As it has been repaired countless times, it's amazing the machine is still functioning at all."
	icon = 'icons/fallout/mobs/robots/protectrons.dmi'
	icon_state = "protectron_trade"
	icon_living = "protectron_trade"
	icon_dead = "protectron_trade_dead"
	
	mob_biotypes = MOB_ROBOTIC|MOB_INORGANIC
	
	maxHealth = 200
	health = 200
	speak_chance = 5
	can_ghost_into = FALSE
	blood_volume = 0
	
	faction = list(
		"neutral", "silicon", "dog", "hostile", "pirate", "wastebot", "wolf",
		"plants", "turret", "enclave", "ghoul", "cazador", "supermutant",
		"gecko", "slime", "radscorpion", "skeleton", "carp", "bs", "bighorner"
	)
	
	speak = list(
		"Howdy partner! How about you spend some of them there hard earned caps on some of this fine merchandise.",
		"Welcome back partner! Hoo-wee it's a good day to buy some personal protection!",
		"Stop, this is a robbery! At these prices you are robbing me.",
		"What a fine day partner. A fine day indeed.",
		"Reminds me of what my grandpappy used to say, make a snap decision now and never question it. You look like you could use some product there partner.",
		"Lotta critters out there want to chew you up partner, you could use a little hand with that now couldn't you?"
	)
	
	speak_emote = list()
	emote_hear = list()
	emote_see = list()
	
	response_help_simple = "shakes its manipulator"
	response_disarm_simple = "pushes"
	response_harm_simple = "punches"
	attack_sound = 'sound/voice/liveagain.ogg'
	
	butcher_results = list(/obj/effect/gibspawner/robot = 1)

/////////////////
// ASSAULTRON  //
/////////////////

// BASE ASSAULTRON - fast melee combat robot
/mob/living/simple_animal/hostile/handy/assaultron
	name = "assaultron"
	desc = "A deadly close combat robot developed by RobCo in a vaguely feminine, yet ominous chassis."
	icon_state = "assaultron"
	icon_living = "assaultron"
	icon_dead = "gib7"
	
	mob_biotypes = MOB_ROBOTIC|MOB_INORGANIC
	mob_armor = ARMOR_VALUE_ROBOT_MILITARY
	
	maxHealth = 100
	health = 100
	speed = 1  // Fast for a robot
	stat_attack = UNCONSCIOUS
	gender = FEMALE
	
	melee_damage_lower = 18
	melee_damage_upper = 45
	attack_verb_simple = "grinds their claws on"
	
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	
	can_ghost_into = FALSE
	desc_short = "A deadly robot."
	
	emote_taunt = null
	emote_taunt_sound = null
	aggrosound = null
	idlesound = null
	
	loot = list(
		/obj/effect/decal/cleanable/robot_debris,
		/obj/item/stack/crafting/electronicparts/three,
		/obj/item/stock_parts/cell/ammo/mfc
	)
	
	// Z-movement - can climb
	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 30
	
	// Pure melee - fast close combat
	combat_mode = COMBAT_MODE_MELEE
	retreat_distance = null
	minimum_distance = 1

// NSB ASSAULTRON
/mob/living/simple_animal/hostile/handy/assaultron/nsb
	name = "assaultron"
	aggro_vision_range = 15
	faction = list("raider")
	obj_damage = 300
	can_ghost_into = FALSE

// MARTHA - unique named assaultron
/mob/living/simple_animal/hostile/handy/assaultron/martha
	name = "lil martha"
	desc = "A deadly close combat robot developed by RobCo and covered in thick, dark blue armor plating, the name 'lil martha' scratched onto it."
	
	mob_armor = ARMOR_VALUE_ROBOT_MILITARY_HEAVY
	
	maxHealth = 500
	health = 500
	aggro_vision_range = 15
	obj_damage = 300
	
	faction = list("hostile")
	can_ghost_into = FALSE
	color = "#3444C8"  // Dark blue
	
	emp_flags = list()  // No EMP instakill

// PLAYABLE ASSAULTRON
/mob/living/simple_animal/hostile/handy/assaultron/playable
	see_in_dark = 8
	force_threshold = 15
	wander = FALSE
	anchored = FALSE
	del_on_death = FALSE
	dextrous = TRUE
	can_ghost_into = FALSE
	deathmessage = "abruptly shuts down, falling to the ground!"
	possible_a_intents = list(INTENT_HELP, INTENT_HARM, INTENT_GRAB, INTENT_DISARM)

// SA-S-E - medical assaultron
/mob/living/simple_animal/hostile/handy/assaultron/playable/medical
	name = "SA-S-E"
	desc = "An Assaultron modified for the Medical field, SA-S-E forgoes the weaponry and deadliness of her military counterparts to save lives. Painted white with blue highlights, and a blue cross on the front of her visor, this robot comes equipped with what looks like modified medical gear. Her head has no eye-laser, instead a gently pulsing blue eye that scans people to analyze their health, a defibrillator on her back, and articulated hands to be able to use the myriad medical tools strapped to parts of her body under protective cases all show this model is meant to save lives."
	icon_state = "assaultron_sase"
	icon_dead = "assaultron_sase_dead"

// RED EYE ASSAULTRON - laser eye variant
/mob/living/simple_animal/hostile/handy/assaultron/laser
	name = "red eye assaultron"
	desc = "A modified assaultron. Its eye has been outfitted with a deadly laser."
	color = "#B85C00"
	can_ghost_into = FALSE
	
	// Mixed - laser at range, claws up close
	combat_mode = COMBAT_MODE_MIXED
	ranged = TRUE
	retreat_distance = 4
	minimum_distance = 1
	
	ranged_cooldown_time = 3 SECONDS
	projectiletype = /obj/item/projectile/beam/laser/lasgun
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
