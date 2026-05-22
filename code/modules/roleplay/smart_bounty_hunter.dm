// SMART BOUNTY HUNTER - AI that actively hunts bountied players
// Uses the existing anti-kite and smart AI systems

/mob/living/simple_animal/hostile/f13/bounty_hunter
	name = "bounty hunter"
	desc = "A weathered wastelander who hunts for caps. They seem to be looking for someone..."
	icon = 'icons/fallout/mobs/humans/raider.dmi'
	icon_state = "junker"
	icon_living = "junker"
	icon_dead = "junker_dead"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	sentience_type = SENTIENCE_BOSS
	maxHealth = 200
	health = 200
	melee_damage_lower = 15
	melee_damage_upper = 25
	move_to_delay = 2.5
	combat_mode = COMBAT_MODE_MIXED
	ranged = TRUE
	retreat_distance = 2
	minimum_distance = 1
	aggro_vision_range = 12
	vision_range = 9
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	can_open_doors = TRUE
	speak_chance = 5
	turns_per_move = 3
	faction = list("bounty_hunter")
	guaranteed_butcher_results = list()

	var/mob/living/carbon/human/target_bounty = null
	var/hunt_duration = 10 MINUTES
	var/hunt_start_time = 0
	var/caps_reward = 0

	// Smart AI
	anti_kite = TRUE
	can_lunge = TRUE
	lunge_range_min = 2
	lunge_range_max = 5
	lunge_cooldown = 60
	lunge_chance = 25
	lunge_is_teleport = FALSE
	veer_chance = 25
	can_dodge_shots = TRUE
	dodge_chance = 25
	dodge_cooldown = 15
	can_retreat = TRUE
	retreat_health_threshold = 0.3
	can_use_stimpak = TRUE
	stimpak_threshold = 0.4
	stimpak_cooldown = 600
	uses_cover = TRUE

/mob/living/simple_animal/hostile/f13/bounty_hunter/Initialize()
	. = ..()
	hunt_start_time = world.time
	addtimer(CALLBACK(src, PROC_REF(give_up_hunt)), hunt_duration, TIMER_DELETE_ME)
	GLOB.active_bounty_hunters += src

/mob/living/simple_animal/hostile/f13/bounty_hunter/Destroy()
	GLOB.active_bounty_hunters -= src
	return ..()

/mob/living/simple_animal/hostile/f13/bounty_hunter/proc/assign_bounty(mob/living/carbon/human/target, reward)
	target_bounty = target
	caps_reward = reward
	if(target)
		GiveTarget(target)
		visible_message(span_danger("[src] spots [target]! \"That's a nice bounty on your head, [target.name]!\""))

/mob/living/simple_animal/hostile/f13/bounty_hunter/proc/give_up_hunt()
	if(stat == DEAD)
		return
	if(target_bounty && target_bounty.stat != DEAD)
		visible_message(span_notice("[src] holsters their weapon. \"You got lucky this time...\""))
	else
		visible_message(span_notice("[src] checks their list and moves on."))
	qdel(src)

/mob/living/simple_animal/hostile/f13/bounty_hunter/death(gibbed)
	if(target_bounty && target_bounty.stat != DEAD)
		visible_message(span_notice("[src] drops, clutching their wound. \"Not... worth it...\""))
		if(target_bounty.ckey)
			adjust_karma(target_bounty.ckey, 10)
	return ..()

/mob/living/simple_animal/hostile/f13/bounty_hunter/PickTarget(list/Targets)
	if(target_bounty && target_bounty.stat != DEAD && (target_bounty in Targets))
		return target_bounty
	return ..()

/mob/living/simple_animal/hostile/f13/bounty_hunter/AttackingTarget()
	. = ..()
	if(. && target_bounty && target == target_bounty && target_bounty.stat == DEAD)
		visible_message(span_danger("[src] stands over [target_bounty]. \"Bounty collected.\""))
		new/obj/item/stack/f13Cash/caps(get_turf(src), caps_reward)
		give_up_hunt()

// ============================================
// BOUNTY HUNTER SPAWNER - Spawns hunters for bountied players
// ============================================

/proc/spawn_smart_bounty_hunters(mob/living/carbon/human/target, reward = 500)
	if(!target || target.stat == DEAD)
		return

	var/spawn_count = min(3, max(1, round(reward / 300)))
	var/list/spawn_turfs = list()

	for(var/turf/T in range(15, target))
		if(T.density)
			continue
		if(!can_see(T, target, 15))
			continue
		spawn_turfs += T
		if(spawn_turfs.len >= 5)
			break

	if(!spawn_turfs.len)
		return

	for(var/i = 1 to spawn_count)
		var/turf/spawn_loc = pick(spawn_turfs)
		var/mob/living/simple_animal/hostile/f13/bounty_hunter/H = new(spawn_loc)
		H.assign_bounty(target, round(reward / spawn_count))
