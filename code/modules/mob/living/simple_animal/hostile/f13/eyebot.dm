// In this document: Eyebots, Floating Eyes, Propaganda Eyebot

/////////////
// EYEBOTS //
/////////////

// BASE EYEBOT - hovering laser recon drone
/mob/living/simple_animal/hostile/eyebot
	name = "eyebot"
	desc = "A hovering, propaganda-spewing reconnaissance and surveillance robot with radio antennas pointing out its back and loudspeakers blaring out the front."
	icon = 'icons/fallout/mobs/robots/eyebots.dmi'
	icon_state = "eyebot"
	icon_living = "eyebot"
	icon_dead = "eyebot_d"
	
	mob_biotypes = MOB_ROBOTIC|MOB_INORGANIC
	mob_armor = ARMOR_VALUE_ROBOT_CIVILIAN
	
	maxHealth = 40
	health = 40
	move_to_delay = 2.75
	turns_per_move = 6
	stamcrit_threshold = SIMPLEMOB_NO_STAMCRIT
	
	melee_damage_lower = 2
	melee_damage_upper = 3
	harm_intent_damage = 8
	
	aggro_vision_range = 7
	vision_range = 7
	robust_searching = TRUE
	
	response_help_simple = "touches"
	response_disarm_simple = "shoves"
	response_harm_simple = "hits"
	attack_verb_simple = "punches"
	attack_sound = 'sound/weapons/punch1.ogg'
	
	speak_emote = list("states")
	speak_chance = 0
	aggrosound = list('sound/f13npc/eyebot/aggro.ogg')
	idlesound = list('sound/f13npc/eyebot/idle1.ogg', 'sound/f13npc/eyebot/idle2.ogg')
	death_sound = 'sound/f13npc/eyebot/robo_death.ogg'
	
	emp_flags = list(
		MOB_EMP_STUN,
		MOB_EMP_BERSERK,
		MOB_EMP_DAMAGE,
		MOB_EMP_SCRAMBLE
	)
	
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	
	tastes = list("metal" = 1, "glass" = 1)
	
	faction = list("hostile", "enclave", "wastebot", "ghoul", "cazador", "supermutant", "bighorner")
	a_intent = INTENT_HARM
	check_friendly_fire = TRUE
	healable = FALSE
	blood_volume = 0
	status_flags = CANPUSH
	environment_smash = ENVIRONMENT_SMASH_NONE
	
	can_ghost_into = TRUE
	desc_short = "A flying metal meatball with lasers."
	pop_required_to_jump_into = SMALL_MOB_MIN_PLAYERS
	
	// Z-movement - flies
	can_z_move = TRUE
	can_climb_ladders = TRUE
	can_climb_stairs = TRUE
	can_jump_down = TRUE
	z_move_delay = 50

	can_open_doors = FALSE
	can_open_airlocks = TRUE  // Small enough to slip through
	
	// Pure ranged - kites at extreme distance
	combat_mode = COMBAT_MODE_RANGED
	ranged = TRUE
	retreat_distance = 14
	minimum_distance = 1
	
	ranged_cooldown_time = 2 SECONDS
	projectiletype = /obj/item/projectile/beam/laser/pistol/wattz
	projectilesound = 'sound/weapons/resonator_fire.ogg'
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
	
	var/obj/machinery/camera/portable/builtInCamera

/mob/living/simple_animal/hostile/eyebot/New()
	..()
	name = "ED-[rand(1,99)]"

/mob/living/simple_animal/hostile/eyebot/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat >= UNCONSCIOUS)
			return FALSE
	return ..()

// Friendly fire resistance - eyebots are networked
/mob/living/simple_animal/hostile/eyebot/bullet_act(obj/item/projectile/P)
	if(P && P.firer && istype(P.firer, /mob/living/simple_animal/hostile/eyebot))
		var/original_damage = P.damage
		P.damage *= 0.2
		. = ..()
		P.damage = original_damage
		return
	return ..()

/mob/living/simple_animal/hostile/eyebot/become_the_mob(mob/user)
	send_mobs = /obj/effect/proc_holder/mob_common/direct_mobs/robot
	call_backup = /obj/effect/proc_holder/mob_common/summon_backup/robot
	. = ..()

// PLAYABLE EYEBOT
/mob/living/simple_animal/hostile/eyebot/playable
	maxHealth = 30
	health = 30
	speed = -1
	attack_verb_simple = "zaps"
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

// REINFORCED EYEBOT - tougher raider variant
/mob/living/simple_animal/hostile/eyebot/reinforced
	name = "reinforced eyebot"
	desc = "An eyebot with beefier protection, and extra electronic aggression."
	color = "#B85C00"
	
	mob_armor = ARMOR_VALUE_ROBOT_SECURITY
	
	maxHealth = 100
	health = 100
	
	melee_damage_lower = 5
	melee_damage_upper = 10
	
	faction = list("raider", "wastebot")
	
	// Pure ranged - closer than standard
	retreat_distance = 6
	minimum_distance = 1
	
	extra_projectiles = 1
	auto_fire_delay = GUN_AUTOFIRE_DELAY_SLOWER

/mob/living/simple_animal/hostile/eyebot/reinforced/become_the_mob(mob/user)
	send_mobs = null
	call_backup = null
	. = ..()

///////////////////
// FLOATING EYES //
///////////////////

// FLOATING EYE - taser variant, BOS faction
/mob/living/simple_animal/hostile/eyebot/floatingeye
	name = "floating eyebot"
	desc = "A quick-observation robot commonly found in pre-War military installations.<br>The floating eyebot uses a powerful taser to keep intruders in line."
	icon_state = "floatingeye"
	icon_living = "floatingeye"
	icon_dead = "floatingeye_d"
	
	faction = list("hostile", "bs")
	
	// Pure ranged - closer engagement than standard eyebot
	retreat_distance = 6
	minimum_distance = 1
	
	projectiletype = /obj/item/projectile/energy/electrode
	projectilesound = 'sound/weapons/resonator_blast.ogg'

/mob/living/simple_animal/hostile/eyebot/floatingeye/New()
	..()
	name = "FEB-[rand(1,99)]"

/mob/living/simple_animal/hostile/eyebot/floatingeye/become_the_mob(mob/user)
	send_mobs = null
	call_backup = null
	. = ..()

//////////////////////
// PROPAGANDA EYEBOT //
//////////////////////

// PROPAGANDA EYEBOT - unarmed pet variant
/mob/living/simple_animal/pet/dog/eyebot
	name = "propaganda eyebot"
	desc = "This eyebot's weapons module has been removed and replaced with a loudspeaker. It appears to be shouting Pre-War propaganda."
	icon = 'icons/fallout/mobs/robots/eyebots.dmi'
	icon_state = "eyebot"
	icon_living = "eyebot"
	icon_dead = "eyebot_d"
	icon_gib = "eyebot_d"
	
	mob_biotypes = MOB_ROBOTIC
	
	maxHealth = 60
	health = 60
	speak_chance = 8
	gender = NEUTER
	blood_volume = 0
	
	faction = list("hostile", "enclave", "wastebot", "ghoul", "cazador", "supermutant", "bighorner")
	
	speak = list()
	speak_emote = list("states")
	emote_hear = list()
	emote_see = list("buzzes.", "pings.", "floats in place")
	
	response_help_simple = "shakes the radio of"
	response_disarm_simple = "pushes"
	response_harm_simple = "punches"
	attack_sound = 'sound/voice/liveagain.ogg'
	
	butcher_results = list(/obj/effect/gibspawner/robot = 1)

/mob/living/simple_animal/pet/dog/eyebot/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/wuv, "beeps happily!", EMOTE_AUDIBLE)

/mob/living/simple_animal/pet/dog/eyebot/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	var/emp_damage = round((maxHealth * 0.1) * (severity * 0.1))
	adjustBruteLoss(emp_damage)

// PLAYABLE PROPAGANDA EYEBOT
/mob/living/simple_animal/pet/dog/eyebot/playable
	maxHealth = 200
	health = 200
	speed = 1
	attack_verb_simple = "zaps"
	see_in_dark = 8
	speak_chance = 0
	wander = FALSE
	force_threshold = 10
	anchored = FALSE
	del_on_death = FALSE
	dextrous = TRUE
	aggrosound = null
	idlesound = null
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)

/mob/living/simple_animal/pet/dog/eyebot/playable/become_the_mob(mob/user)
	send_mobs = null
	call_backup = null
	. = ..()
