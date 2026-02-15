/mob/living/simple_animal/hostile
	faction = list("hostile")
	stop_automated_movement_when_pulled = 0
	obj_damage = 40
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES //Bitflags. Set to ENVIRONMENT_SMASH_STRUCTURES to break closets,tables,racks, etc; ENVIRONMENT_SMASH_WALLS for walls; ENVIRONMENT_SMASH_RWALLS for rwalls
	mob_size = MOB_SIZE_LARGE
	gold_core_spawnable = NO_SPAWN
	var/atom/target
	var/ranged = FALSE
	var/rapid = 0 //How many shots per volley.
	var/rapid_fire_delay = 2 //Time between rapid fire shots

	var/dodging = FALSE
	var/approaching_target = FALSE //We should dodge now
	var/in_melee = FALSE	//We should sidestep now
	var/dodge_prob = 30
	var/sidestep_per_cycle = 1 //How many sidesteps per npcpool cycle when in melee

	var/extra_projectiles = 0 //how many projectiles above 1?
	/// How long to wait between shots?
	var/auto_fire_delay = GUN_AUTOFIRE_DELAY_NORMAL
	var/projectiletype	//set ONLY it and NULLIFY casingtype var, if we have ONLY projectile
	var/projectilesound
	/// Play a sound after they shoot?
	var/sound_after_shooting
	/// How long after shooting should it play?
	var/sound_after_shooting_delay = 1 SECONDS
	var/list/projectile_sound_properties = list(
		SP_VARY(FALSE),
		SP_VOLUME(PLASMA_VOLUME),
		SP_VOLUME_SILENCED(PLASMA_VOLUME * SILENCED_VOLUME_MULTIPLIER),
		SP_NORMAL_RANGE(PLASMA_RANGE),
		SP_NORMAL_RANGE_SILENCED(SILENCED_GUN_RANGE),
		SP_IGNORE_WALLS(TRUE),
		SP_DISTANT_SOUND(null),
		SP_DISTANT_RANGE(null)
	)

	var/casingtype		//set ONLY it and NULLIFY projectiletype, if we have projectile IN CASING
	/// Deciseconds between moves for automated movement. m2d 3 = standard, less is fast, more is slower.
	var/move_to_delay = 3
	var/list/friends = list()
	var/list/foes = list()
	var/list/emote_taunt
	var/emote_taunt_sound = FALSE // Does it have a sound associated with the emote? Defaults to false.
	var/taunt_chance = 0

	/// What happens when this mob is EMP'd?
	var/list/emp_flags = list()
	/// What emp effects are active?
	var/list/active_emp_flags = list()
	/// Smoke!
	var/datum/effect_system/smoke_spread/bad/smoke

	var/rapid_melee = 1			 //Number of melee attacks between each npc pool tick. Spread evenly.
	var/melee_queue_distance = 4 //If target is close enough start preparing to hit them if we have rapid_melee enabled

	var/melee_attack_cooldown = 2 SECONDS
	COOLDOWN_DECLARE(melee_cooldown)

	var/sight_shoot_delay_time = 0.7 SECONDS
	COOLDOWN_DECLARE(sight_shoot_delay)

	var/ranged_message = "fires" //Fluff text for ranged mobs
	var/ranged_cooldown = 0 //What the current cooldown on ranged attacks is, generally world.time + ranged_cooldown_time
	var/ranged_cooldown_time = 3 SECONDS //How long, in deciseconds, the cooldown of ranged attacks is
	var/ranged_ignores_vision = FALSE //if it'll fire ranged attacks even if it lacks vision on its target, only works with environment smash
	var/check_friendly_fire = 0 // Should the ranged mob check for friendlies when shooting
	/// If our mob runs from players when they're too close, set in tile distance. By default, mobs do not retreat.
	var/retreat_distance = null
	/// Minimum approach distance, so ranged mobs chase targets down, but still keep their distance set in tiles to the target, set higher to make mobs keep distance
	var/minimum_distance = 1

	var/decompose = TRUE //Does this mob decompose over time when dead?

//These vars are related to how mobs locate and target
	var/robust_searching = 0 //By default, mobs have a simple searching method, set this to 1 for the more scrutinous searching (stat_attack, stat_exclusive, etc), should be disabled on most mobs
	var/vision_range = 9 //How big of an area to search for targets in, a vision of 9 attempts to find targets as soon as they walk into screen view
	var/aggro_vision_range = 9 //If a mob is aggro, we search in this radius. Defaults to 9 to keep in line with original simple mob aggro radius
	var/search_objects = 0 //If we want to consider objects when searching around, set this to 1. If you want to search for objects while also ignoring mobs until hurt, set it to 2. To completely ignore mobs, even when attacked, set it to 3
	var/search_objects_timer_id //Timer for regaining our old search_objects value after being attacked
	var/search_objects_regain_time = 30 //the delay between being attacked and gaining our old search_objects value back
	var/list/wanted_objects = list() //A typecache of objects types that will be checked against to attack, should we have search_objects enabled
	var/stat_attack = CONSCIOUS //Mobs with stat_attack to UNCONSCIOUS will attempt to attack things that are unconscious, Mobs with stat_attack set to DEAD will attempt to attack the dead.
	var/stat_exclusive = FALSE //Mobs with this set to TRUE will exclusively attack things defined by stat_attack, stat_attack DEAD means they will only attack corpses
	var/attack_same = 0 //Set us to 1 to allow us to attack our own faction
	var/atom/targets_from = null //all range/attack/etc. calculations should be done from this atom, defaults to the mob itself, useful for Vehicles and such
	var/attack_all_objects = FALSE //if true, equivalent to having a wanted_objects list containing ALL objects.

	var/lose_patience_timer_id //id for a timer to call LoseTarget(), used to stop mobs fixating on a target they can't reach
	var/lose_patience_timeout = 300 //30 seconds by default, so there's no major changes to AI behaviour, beyond actually bailing if stuck forever

	var/peaceful = FALSE //Determines if mob is actively looking to attack something, regardless if hostile by default to the target or not

//These vars activate certain things on the mob depending on what it hears
	var/attack_phrase = "" //Makes the mob become hostile (if it wasn't beforehand) upon hearing
	var/peace_phrase = "" //Makes the mob become peaceful (if it wasn't beforehand) upon hearing
	var/reveal_phrase = "" //Uncamouflages the mob (if it were to become invisible via the alpha var) upon hearing
	var/hide_phrase = "" //Camouflages the mob (Sets it to a defined alpha value, regardless if already 'hiddeb') upon hearing

	/// Probability it'll do some other kind of melee attack, like a knockback hit.
	var/alternate_attack_prob = 0
	/// At what percent of their health does the mob change states? Like, get ANGY on low-health or something. set to 0 or FALSE to disable
	/// Is a decimal, 0 through 1. 0.5 means half health, 0.25 is quarter health, etc
	var/low_health_threshold = 0
	/// Has the mob done its Low Health thing?
	var/is_low_health = FALSE
	/// Does this mob un-itself if nobody's on the Z level?
	var/despawns_when_lonely = TRUE
	/// timer for despawning when lonely
	var/lonely_timer_id

	/// Can this mob pursue targets across Z-levels? (Master toggle)
	var/can_z_move = TRUE
	/// Can this mob climb ladders specifically?
	var/can_climb_ladders = TRUE
	/// Can this mob use stairs specifically?
	var/can_climb_stairs = TRUE
	/// Can this mob jump down through openspace?
	var/can_jump_down = TRUE
	/// How long to wait before attempting Z pursuit (deciseconds)
	var/z_move_delay = 30
	/// Last time we attempted Z-level movement
	var/last_z_move_attempt = 0
	/// What Z-level was our target last seen on?
	var/target_last_z = 0

	// Z-PURSUIT STATE TRACKING - prevents AI from getting confused during vertical movement
	/// Are we currently in the middle of Z-level pursuit? Used to lock the mob into climbing mode
	var/pursuing_z_target = FALSE
	/// What structure (ladder/stairs) are we trying to reach for Z pursuit?
	var/atom/z_pursuit_structure = null
	/// When did we start Z-pursuit? Used for timeout
	var/z_pursuit_started = 0
	/// Maximum time to spend in Z-pursuit before giving up (10 seconds)
	var/z_pursuit_timeout = 100

	/// Remembered target during Z-pursuit - won't lose them even if out of sight
	var/atom/remembered_target = null
	/// When did we last see our target? Used to prevent losing them during brief moments out of sight
	var/last_target_sighting = 0
	/// How long to remember target after losing sight (deciseconds) - 15 seconds
	var/target_memory_duration = 150

	/// Are we in active search mode?
	var/searching = FALSE
	/// Timer ID for search mode
	var/search_timer_id = null
	/// How long to search after losing sight (deciseconds) - 30 seconds
	var/search_duration = 300
	/// Last known location of target
	var/turf/last_known_location = null
	/// Search radius around last known location
	var/search_radius = 7

	/// How far to call for backup when finding a target (tiles)
	var/backup_call_range = 15
	/// Cooldown between backup calls to prevent spam
	COOLDOWN_DECLARE(backup_call_cooldown)
	/// How long between backup calls (deciseconds)
	var/backup_call_delay = 50 // 5 seconds

	/// Last time we successfully changed Z-levels
	var/last_successful_z_move = 0
	/// Cooldown after changing Z before we can pursue again (prevents stair loops)
	var/z_move_success_cooldown = 30 // 3 seconds

	/// Can this mob open doors?
	var/can_open_doors = FALSE
	/// Can this mob open airlocks specifically?
	var/can_open_airlocks = FALSE
	/// Cooldown between door opening attempts
	COOLDOWN_DECLARE(door_open_cooldown)
	/// How long between door opening attempts
	var/door_open_delay = 20 // 2 seconds

	/// What Z-level are we committed to searching?
	var/committed_z_level = 0
	/// When did we commit to this Z-level?
	var/z_commit_time = 0
	/// How long to stay on a Z-level before switching (deciseconds) - 10 seconds
	var/z_commit_duration = 100
	/// How many times have we climbed recently? (prevents yo-yoing)
	var/recent_climbs = 0
	/// Last time we reset climb counter
	var/last_climb_reset = 0

	/// Can we hear combat sounds to locate targets?
	var/can_hear_combat = TRUE  // Work on what mobs can hear or not, leave on TRUE for now
	/// Range we can hear combat sounds (tiles)
	var/combat_hearing_range = 7  // Reduced to 7 tiles by default
	/// Last time we heard combat
	var/last_combat_sound = 0

	/// How long have we been on stairs?
	var/time_on_stairs = 0
	/// Last time we checked if on stairs
	var/last_stairs_check = 0
	/// Maximum time allowed on stairs before forced off (deciseconds) - 5 seconds
	var/max_stairs_time = 50

	/// How many consecutive times have we stepped on stairs?
	var/consecutive_stair_steps = 0
	/// Maximum consecutive stair steps before forcing off
	var/max_consecutive_stair_steps = 5

/mob/living/simple_animal/hostile/Initialize()
	. = ..()

	if(!targets_from)
		targets_from = src
	wanted_objects = typecacheof(wanted_objects)
	if(MOB_EMP_DAMAGE in emp_flags)
		smoke = new /datum/effect_system/smoke_spread/bad
		smoke.attach(src)

/mob/living/simple_animal/hostile/Destroy()
	// Clear target reference with signal cleanup
	GiveTarget(null)
	targets_from = null
	
	// Clear Z-pursuit memory references - IMPORTANT FOR GC
	remembered_target = null
	z_pursuit_structure = null
	last_known_location = null
	
	// Clear Z-commitment
	committed_z_level = 0
	
	// Clear search mode
	if(search_timer_id)
		deltimer(search_timer_id)
		search_timer_id = null
	searching = FALSE
	
	// Clear lists
	if(friends)
		friends.Cut()
	friends = null
	
	if(foes)
		foes.Cut()
	foes = null
	
	if(wanted_objects)
		wanted_objects = null
	
	if(emote_taunt)
		emote_taunt = null
	
	// Clear smoke system
	if(smoke)
		QDEL_NULL(smoke)
	
	// Clear active emp flags
	if(active_emp_flags)
		active_emp_flags = null
	if(emp_flags)
		emp_flags = null
	
	// Clear timers
	if(lonely_timer_id)
		deltimer(lonely_timer_id)
		lonely_timer_id = null
	
	if(lose_patience_timer_id)
		deltimer(lose_patience_timer_id)
		lose_patience_timer_id = null
	
	if(search_objects_timer_id)
		deltimer(search_objects_timer_id)
		search_objects_timer_id = null
	
	// Unqueue from idle NPC pool
	SSidlenpcpool.remove_from_culling(src)
	
	return ..()

/mob/living/simple_animal/hostile/BiologicalLife(seconds, times_fired)
	if(!CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		walk(src, 0)

	if(!(. = ..()))
		walk(src, 0) //stops walking
		if(decompose)
			if(prob(1)) // 1% chance every cycle to decompose
				visible_message(span_notice("\The dead body of the [src] decomposes!"))
				gib(FALSE, FALSE, FALSE, TRUE)
		return
	check_health()

/mob/living/simple_animal/hostile/proc/check_health()
	if(low_health_threshold <= 0)
		return FALSE
	if(stat == DEAD)
		return FALSE
	if (QDELETED(src)) // diseases can qdel the mob via transformations
		return FALSE
	
	if(is_low_health && health > (maxHealth * low_health_threshold)) // no longer low health
		make_high_health()
		return TRUE
	if(!is_low_health && health < (maxHealth * low_health_threshold))
		make_low_health()
		return TRUE

/// Override this with what should happen when going from low health to high health
/mob/living/simple_animal/hostile/proc/make_high_health()
	return

/// Override this with what should happen when going from high health to low health
/mob/living/simple_animal/hostile/proc/make_low_health()
	return

/mob/living/simple_animal/hostile/handle_automated_action()
	if(AIStatus == AI_OFF)
		return 0

	var/list/possible_targets = ListTargets()
	
	// HARD ANTI-STUCK CHECK - force mobs off stairs if stuck too long
	var/on_stairs = FALSE
	for(var/obj/structure/stairs/S in loc)
		on_stairs = TRUE
		break
	
	if(on_stairs)
		if(time_on_stairs == 0)
			time_on_stairs = world.time
		else if((world.time - time_on_stairs) > max_stairs_time)
			commit_to_z_level()
			pursuing_z_target = FALSE
			z_pursuit_structure = null
			time_on_stairs = 0
			
			var/list/escape_turfs = list()
			for(var/turf/T in range(3, src))
				var/has_stairs = FALSE
				for(var/obj/structure/stairs/ST in T)
					has_stairs = TRUE
					break
				if(!has_stairs && istype(T, /turf/open))
					escape_turfs += T
			
			if(escape_turfs.len)
				var/turf/escape = pick(escape_turfs)
				Goto(escape, move_to_delay, 0)
				visible_message(span_notice("[src] steps away from the stairs."))
	else
		time_on_stairs = 0
	
	// Try opening doors if we're stuck and can open them
	if(can_open_doors && target)
		var/turf/T = get_step(src, get_dir(src, target))
		if(T)
			// Check for simple doors
			for(var/obj/structure/simple_door/SD in T)
				if(SD.density)
					try_open_door(SD)
			// Check for machinery doors
			for(var/obj/machinery/door/D in T)
				if(D.density)
					try_open_door(D)

	if(environment_smash)
		EscapeConfinement()

	if(AICanContinue(possible_targets))
		if(!QDELETED(target) && !targets_from.Adjacent(target))
			DestroyPathToTarget()
		if(!MoveToTarget(possible_targets))
			if(AIShouldSleep(possible_targets))
				toggle_ai(AI_IDLE)
	consider_despawning()
	return 1

/mob/living/simple_animal/hostile/handle_automated_movement()
	. = ..()
	if(!CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		return
	if(dodging && target && in_melee && isturf(loc) && isturf(target.loc))
		var/datum/cb = CALLBACK(src,PROC_REF(sidestep))
		if(sidestep_per_cycle > 1) //For more than one just spread them equally - this could changed to some sensible distribution later
			var/sidestep_delay = SSnpcpool.wait / sidestep_per_cycle
			for(var/i in 1 to sidestep_per_cycle)
				addtimer(cb, (i - 1)*sidestep_delay)
		else //Otherwise randomize it to make the players guessing.
			addtimer(cb,rand(1,SSnpcpool.wait))

/mob/living/simple_animal/hostile/toggle_ai(togglestatus)
	. = ..()
	if(QDELETED(src))
		return
	if(consider_despawning())
		if(!lonely_timer_id && !QDELETED(src))
			lonely_timer_id = addtimer(CALLBACK(src, PROC_REF(queue_unbirth)), 30 SECONDS, TIMER_STOPPABLE)
	else
		if(lonely_timer_id)
			deltimer(lonely_timer_id)
			lonely_timer_id = null	
		unqueue_unbirth()

/mob/living/simple_animal/hostile/proc/consider_despawning()
	if(!despawns_when_lonely)
		return FALSE
	if(ckey)
		return FALSE
	if(lazarused)
		return FALSE
	if(stat == DEAD)
		return FALSE
	if(CHECK_BITFIELD(datum_flags, DF_VAR_EDITED))
		return FALSE
	if(CHECK_BITFIELD(flags_1, ADMIN_SPAWNED_1))
		return FALSE
	if(health <= 0)
		return FALSE
	if(AIStatus == AI_ON || AIStatus == AI_OFF)
		return FALSE
	if(target) // Don't despawn if we have a target
		return FALSE
	return TRUE

/mob/living/simple_animal/hostile/become_the_mob(mob/user)
	if(lonely_timer_id)
		deltimer(lonely_timer_id)
		lonely_timer_id = null	
	unqueue_unbirth()
	. = ..()


/mob/living/simple_animal/hostile/proc/sidestep()
	if(!target || !isturf(target.loc) || !isturf(loc) || stat == DEAD)
		return
	var/target_dir = get_dir(src,target)

	var/static/list/cardinal_sidestep_directions = list(-90,-45,0,45,90)
	var/static/list/diagonal_sidestep_directions = list(-45,0,45)
	var/chosen_dir = 0
	if (target_dir & (target_dir - 1))
		chosen_dir = pick(diagonal_sidestep_directions)
	else
		chosen_dir = pick(cardinal_sidestep_directions)
	if(chosen_dir)
		chosen_dir = turn(target_dir,chosen_dir)
		Move(get_step(src,chosen_dir))
		face_atom(target) //Looks better if they keep looking at you when dodging

/mob/living/simple_animal/hostile/attacked_by(obj/item/I, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1, damage_addition)
	if (peaceful == TRUE)
		peaceful = FALSE
	if(stat == CONSCIOUS && !target && AIStatus != AI_OFF && !client && user)
		FindTarget(list(user), 1)
		COOLDOWN_RESET(src, sight_shoot_delay) // Let them shoot back immediately when attacked
	return ..()

/mob/living/simple_animal/hostile/bullet_act(obj/item/projectile/P)
	. = ..()
	if (peaceful == TRUE)
		peaceful = FALSE
	if(stat == CONSCIOUS && !target && AIStatus != AI_OFF && !client)
		if(P.firer && get_dist(src, P.firer) <= aggro_vision_range)
			FindTarget(list(P.firer), 1)
			COOLDOWN_RESET(src, sight_shoot_delay)
		Goto(P.starting, move_to_delay, 3)
	
	// ALERT NEARBY ALLIES ABOUT COMBAT - they'll hear the gunfire
	alert_allies_of_combat(get_turf(src), P.firer)

/mob/living/simple_animal/hostile/proc/alert_allies_of_combat(turf/combat_location, atom/attacker)
	if(!combat_location)
		return
	
	// Find allies in hearing range across Z-levels
	var/list/allies_in_range = list()
	
	// Same Z
	for(var/mob/living/simple_animal/hostile/M in range(combat_hearing_range, combat_location))
		if(M == src || M.stat == DEAD || M.ckey)
			continue
		if(faction_check_mob(M, TRUE))
			allies_in_range += M
	
	// Z above
	var/turf/above = get_step_multiz(combat_location, UP)
	if(above)
		for(var/mob/living/simple_animal/hostile/M in range(combat_hearing_range, above))
			if(M == src || M.stat == DEAD || M.ckey)
				continue
			if(faction_check_mob(M, TRUE))
				allies_in_range += M
	
	// Z below
	var/turf/below = get_step_multiz(combat_location, DOWN)
	if(below)
		for(var/mob/living/simple_animal/hostile/M in range(combat_hearing_range, below))
			if(M == src || M.stat == DEAD || M.ckey)
				continue
			if(faction_check_mob(M, TRUE))
				allies_in_range += M
	
	// Alert all allies
	for(var/mob/living/simple_animal/hostile/ally in allies_in_range)
		ally.hear_combat_sound(combat_location, attacker)

/mob/living/simple_animal/hostile/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	. = ..()
	if (raw_message == attack_phrase)
		alpha = 255
		peaceful = FALSE
	if (raw_message == peace_phrase)
		peaceful = TRUE
	if (raw_message == reveal_phrase)
		alpha = 255
	if (raw_message == hide_phrase)
		alpha = 90
	return ..()

//////////////HOSTILE MOB TARGETTING AND AGGRESSION////////////

/mob/living/simple_animal/hostile/proc/ListTargets()//Step 1, find out what we can see
	if(!search_objects)
		. = hearers(vision_range, targets_from) - src
		
		// Check for targets one Z-level ABOVE through openspace above us
		var/turf/our_turf = get_turf(targets_from)
		var/turf/above_us = get_step_multiz(our_turf, UP)
		if(above_us && istype(above_us, /turf/open/transparent/openspace))
			// We're under openspace, we can see up
			for(var/mob/living/M in range(vision_range, above_us))
				// Make sure they're actually on the openspace (visible to us)
				var/turf/their_turf = get_turf(M)
				if(istype(their_turf, /turf/open/transparent/openspace))
					. += M
		
		// Check for targets one Z-level BELOW through openspace we're standing on/near
		var/list/openspace_tiles = list()
		if(istype(our_turf, /turf/open/transparent/openspace))
			openspace_tiles += our_turf
		
		for(var/turf/open/transparent/openspace/OS in range(1, targets_from))
			openspace_tiles += OS
		
		if(openspace_tiles.len)
			var/turf/below_check = get_step_multiz(our_turf, DOWN)
			if(below_check)
				for(var/mob/living/M in range(vision_range, below_check))
					var/turf/their_turf = get_turf(M)
					var/turf/above_them = get_step_multiz(their_turf, UP)
					if(above_them && istype(above_them, /turf/open/transparent/openspace))
						. += M
		
		var/static/hostile_machines = typecacheof(list(/obj/machinery/porta_turret, /obj/mecha, /obj/structure/destructible/clockwork/ocular_warden,/obj/item/electronic_assembly))

		for(var/HM in typecache_filter_list(range(vision_range, targets_from), hostile_machines))
			CHECK_TICK
			if(can_see(targets_from, HM, vision_range))
				. += HM
	else
		. = list()
		for (var/obj/A in oview(vision_range, targets_from))
			CHECK_TICK
			. += A
		for (var/mob/living/A in oview(vision_range, targets_from))
			CHECK_TICK
			. += A

/mob/living/simple_animal/hostile/proc/FindTarget(list/possible_targets, HasTargetsList = 0)
	. = list()
	if (peaceful == FALSE)
		if(!HasTargetsList)
			possible_targets = ListTargets()
		
		// SEARCH MODE: If we're searching and find target, re-acquire them
		if(searching && (target in possible_targets))
			exit_search_mode()
			last_target_sighting = world.time
			remembered_target = target
			GiveTarget(target)
			COOLDOWN_START(src, sight_shoot_delay, sight_shoot_delay_time)
			
			// CALL FOR BACKUP - alert nearby allies we found the target!
			call_for_backup(target, "found")
			
			return target
		
		// MEMORY SYSTEM: If we have a remembered target and haven't seen them recently, keep them as target
		if(remembered_target && !QDELETED(remembered_target))
			if((world.time - last_target_sighting) < target_memory_duration)
				// We recently saw this target, keep pursuing even if not in possible_targets
				if(target != remembered_target)
					GiveTarget(remembered_target)
					COOLDOWN_START(src, sight_shoot_delay, sight_shoot_delay_time)
				return remembered_target
			else if(!searching)
				// Memory expired but not searching yet - enter search mode
				enter_search_mode()
				return remembered_target
		
		for(var/pos_targ in possible_targets)
			var/atom/A = pos_targ
			if(Found(A))//Just in case people want to override targetting
				. = list(A)
				break
			if(CanAttack(A))//Can we attack it?
				. += A
				continue
		var/Target = PickTarget(.)
		GiveTarget(Target)
		COOLDOWN_START(src, sight_shoot_delay, sight_shoot_delay_time)
		
		// Remember this target
		if(Target)
			remembered_target = Target
			last_target_sighting = world.time
			last_known_location = get_turf(Target)
			
			// NEW TARGET FOUND - call for backup if we just acquired a new target
			if(!target || target != Target)
				call_for_backup(Target, "found")
		
		return Target

/mob/living/simple_animal/hostile/proc/PossibleThreats()
	. = list()
	for(var/pos_targ in ListTargets())
		var/atom/A = pos_targ
		if(Found(A))
			. = list(A)
			break
		if(CanAttack(A))
			. += A
			continue



/mob/living/simple_animal/hostile/proc/Found(atom/A)//This is here as a potential override to pick a specific target if available
	return

/mob/living/simple_animal/hostile/proc/PickTarget(list/Targets)//Step 3, pick amongst the possible, attackable targets
	if(target != null)//If we already have a target, but are told to pick again, calculate the lowest distance between all possible, and pick from the lowest distance targets
		for(var/pos_targ in Targets)
			var/atom/A = pos_targ
			var/target_dist = get_dist(targets_from, target)
			var/possible_target_distance = get_dist(targets_from, A)
			if(target_dist < possible_target_distance)
				Targets -= A
	if(!Targets.len)//We didnt find nothin!
		return
	var/chosen_target = pick(Targets)//Pick the remaining targets (if any) at random
	return chosen_target

// Please do not add one-off mob AIs here, but override this function for your mob
/mob/living/simple_animal/hostile/CanAttack(atom/the_target)
	if(!the_target || the_target.type == /atom/movable/lighting_object || isturf(the_target))
		return FALSE
	if(!loc)
		return FALSE

	if(ismob(the_target))
		var/mob/M = the_target
		if(M.status_flags & GODMODE)
			return FALSE

	if(see_invisible < the_target.invisibility)
		return FALSE
	
	// Allow attacking through Z-levels if there's openspace
	if(the_target.z != z)
		// Target is above us
		if(the_target.z == z + 1)
			var/turf/above_us = get_step_multiz(get_turf(src), UP)
			if(!istype(above_us, /turf/open/transparent/openspace))
				return FALSE
			var/turf/target_turf = get_turf(the_target)
			if(!istype(target_turf, /turf/open/transparent/openspace))
				return FALSE
		// Target is below us
		else if(the_target.z == z - 1)
			var/turf/our_turf = get_turf(src)
			if(!istype(our_turf, /turf/open/transparent/openspace))
				// Check if we're near openspace
				var/found_openspace = FALSE
				for(var/turf/open/transparent/openspace/OS in range(1, src))
					found_openspace = TRUE
					break
				if(!found_openspace)
					return FALSE
			var/turf/target_turf = get_turf(the_target)
			var/turf/above_target = get_step_multiz(target_turf, UP)
			if(!istype(above_target, /turf/open/transparent/openspace))
				return FALSE
		else
			return FALSE // Too far in Z
	
	if(search_objects < 2)
		if(isliving(the_target))
			var/mob/living/L = the_target
			var/faction_check = !foes[L] && faction_check_mob(L)
			if(robust_searching)
				if(faction_check && !attack_same)
					return FALSE
				if(L.stat > stat_attack)
					return FALSE
				if(stat_attack == CONSCIOUS && IS_STAMCRIT(L))
					return FALSE
				if(L.stat == UNCONSCIOUS && stat_attack == UNCONSCIOUS && HAS_TRAIT(L, TRAIT_DEATHCOMA))
					return FALSE
				if(friends[L] > 0 && foes[L] < 1)
					return FALSE
			else
				if((faction_check && !attack_same) || L.stat)
					return FALSE
			return TRUE

		if(ismecha(the_target))
			var/obj/mecha/M = the_target
			if(M.occupant)
				if(CanAttack(M.occupant))
					return TRUE

		if(istype(the_target, /obj/machinery/porta_turret))
			var/obj/machinery/porta_turret/P = the_target
			if(P.in_faction(src))
				return FALSE
			if(P.has_cover &&!P.raised)
				return FALSE
			if(P.stat & BROKEN)
				return FALSE
			return TRUE

		if(istype(the_target, /obj/item/electronic_assembly))
			var/obj/item/electronic_assembly/O = the_target
			if(O.combat_circuits)
				return TRUE

		if(istype(the_target, /obj/structure/destructible/clockwork/ocular_warden))
			var/obj/structure/destructible/clockwork/ocular_warden/OW = the_target
			if(OW.target != src)
				return FALSE
			return TRUE
	if(isobj(the_target))
		if(attack_all_objects || is_type_in_typecache(the_target, wanted_objects))
			return TRUE

	return FALSE

/mob/living/simple_animal/hostile/proc/GiveTarget(new_target)//Step 4, give us our selected target
	add_target(new_target)
	LosePatience()
	if(target != null)
		// Update memory when we get a new target
		remembered_target = target
		last_target_sighting = world.time
		GainPatience()
		Aggro()
		return 1
	else
		// Only clear memory if we're not in Z-pursuit
		if(!pursuing_z_target)
			remembered_target = null

//What we do after closing in
/mob/living/simple_animal/hostile/proc/MeleeAction(patience = TRUE)
	if(rapid_melee > 1)
		var/datum/callback/cb = CALLBACK(src, PROC_REF(CheckAndAttack))
		var/delay = SSnpcpool.wait / rapid_melee
		for(var/i in 1 to rapid_melee)
			addtimer(cb, (i - 1)*delay)
	else
		AttackingTarget()
	if(patience)
		GainPatience()

/mob/living/simple_animal/hostile/proc/CheckAndAttack()
	if(target && targets_from && isturf(targets_from.loc) && target.Adjacent(targets_from) && !incapacitated())
		AttackingTarget()

/mob/living/simple_animal/hostile/proc/MoveToTarget(list/possible_targets)//Step 5, handle movement between us and our target
	stop_automated_movement = 1
	if (peaceful == TRUE)
		LoseTarget()
		return 0
	
	// If we're in search mode, keep searching
	if(searching)
		// Check if target is back in sight
		if(target && (target in possible_targets))
			exit_search_mode()
			last_target_sighting = world.time
			
			// FOUND THEM AGAIN - call for backup!
			call_for_backup(target, "found")
		return 1 // Keep searching
	
	// If we have no target but have a remembered target, restore it
	if(!target && remembered_target && !QDELETED(remembered_target))
		if((world.time - last_target_sighting) < target_memory_duration)
			GiveTarget(remembered_target)
		else
			// Memory expired, enter search mode
			enter_search_mode()
			return 1
	
	if(!target || !CanAttack(target))
		// Check if we should keep pursuing via memory
		if(remembered_target && (world.time - last_target_sighting) < target_memory_duration)
			if(remembered_target.z != z)
				// Target is on different Z, keep pursuing
				if(attempt_z_pursuit())
					return 1
			else
				// Same Z but can't see them - enter search mode
				if(!searching)
					enter_search_mode()
				return 1
		LoseTarget()
		return 0
	
	// Update last sighting if we can see target
	if(target in possible_targets)
		last_target_sighting = world.time
		remembered_target = target
		last_known_location = get_turf(target)
	else if((world.time - last_target_sighting) > 50) // Haven't seen them for 5 seconds
		// Lost line of sight - enter search mode
		if(!searching)
			enter_search_mode()
		return 1
	
	// Z-PURSUIT STATE MANAGEMENT
	// Clear Z-pursuit state if target is back on same Z-level OR we've been pursuing too long (timeout)
	if(pursuing_z_target)
		if(target && target.z == z)
			// Target is back on our level - resume normal combat
			pursuing_z_target = FALSE
			z_pursuit_structure = null
		else if((world.time - z_pursuit_started) > z_pursuit_timeout)
			// Been pursuing for too long (10+ seconds) - give up
			pursuing_z_target = FALSE
			z_pursuit_structure = null
			visible_message(span_notice("[src] gives up the pursuit."))
	
	// PRIORITY: If we're in Z-pursuit mode, keep moving toward the structure (ladder/stairs)
	// This overrides normal combat AI to ensure we actually reach and climb the structure
	if(pursuing_z_target && z_pursuit_structure && target && target.z != z)
		var/dist = get_dist(src, z_pursuit_structure)
		
		// If we're right next to a ladder, step onto it
		if(dist <= 1 && istype(z_pursuit_structure, /obj/structure/ladder))
			walk(src, 0) // Stop pathfinding
			step(src, get_dir(src, z_pursuit_structure)) // Step onto ladder
		else
			// Still far away, keep pathfinding toward it
			Goto(z_pursuit_structure, move_to_delay, 0)
		
		return 1 // Keep pursuing, don't do normal AI stuff
	
	if(target in possible_targets)
		if(target.z != z)
			// Check if we're ON stairs right now - if so, don't re-trigger pursuit
			var/on_stairs = FALSE
			for(var/obj/structure/stairs/S in loc)
				on_stairs = TRUE
				break
			
			// Check if we just climbed - give time to reach target before climbing again
			if((world.time - last_successful_z_move) < z_move_success_cooldown)
				// Just climbed, wait for cooldown
				if(on_stairs)
					// On stairs and just climbed - continue walking off stairs
					Goto(target, move_to_delay, minimum_distance)
				return 1
			
			// Only attempt Z-pursuit if cooldown is over AND not on stairs
			if(!on_stairs && (world.time - last_successful_z_move) >= z_move_success_cooldown)
				if(attempt_z_pursuit())
					return 1
			
			// If on stairs but can't pursue yet, just walk
			if(on_stairs)
				Goto(target, move_to_delay, minimum_distance)
				return 1
			
			LoseTarget()
			return 0
		
		var/target_distance = get_dist(targets_from, target)
		
		// Check if we THINK we're adjacent but target is on different Z
		if(targets_from && isturf(targets_from.loc) && target.Adjacent(targets_from))
			// Verify they're actually on the same Z-level
			if(target.z != z)
				// Target is on different Z but appears adjacent (openspace issue)
				// Don't try to melee, just pursue
				if(attempt_z_pursuit())
					return 1
				LoseTarget()
				return 0
		
		if(ranged)
			if(!target.Adjacent(targets_from) && ranged_cooldown <= world.time)
				OpenFire(target)
		
		if(!Process_Spacemove())
			walk(src,0)
			return 1
		
		// Try opening doors if we're stuck and can open them
		if(can_open_doors && target)
			var/turf/T = get_step(src, get_dir(src, target))
			if(T)
				for(var/obj/machinery/door/D in T)
					if(D.density)
						try_open_door(D)
			
		if(retreat_distance != null)
			if(target_distance <= retreat_distance && CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
				set_glide_size(DELAY_TO_GLIDE_SIZE(move_to_delay))
				walk_away(src,target,retreat_distance,move_to_delay)
			else
				Goto(target,move_to_delay,minimum_distance)
		else
			Goto(target,move_to_delay,minimum_distance)
		
		if(variation_list[MOB_RETREAT_DISTANCE_CHANCE] && LAZYLEN(variation_list[MOB_RETREAT_DISTANCE]) && prob(variation_list[MOB_RETREAT_DISTANCE_CHANCE]))
			retreat_distance = vary_from_list(variation_list[MOB_RETREAT_DISTANCE])
		
		if(target)
			if(COOLDOWN_TIMELEFT(src, melee_cooldown))
				return TRUE
			COOLDOWN_START(src, melee_cooldown, melee_attack_cooldown)
			
			// Only try melee if we're ACTUALLY adjacent (same Z-level)
			if(targets_from && isturf(targets_from.loc) && target.Adjacent(targets_from) && target.z == z)
				MeleeAction()
			else
				if(rapid_melee > 1 && target_distance <= melee_queue_distance)
					MeleeAction(FALSE)
				in_melee = FALSE
			return 1
		return 0
		
	if(environment_smash || can_open_doors)
		if(target.loc != null && get_dist(targets_from, target.loc) <= vision_range)
			if(ranged_ignores_vision && ranged_cooldown <= world.time)
				OpenFire(target)
			
			// Only smash if we're REALLY close and can't path normally
			var/target_dist = get_dist(targets_from, target)
			if(target_dist <= 3) // Reduced from default range
				if((environment_smash & ENVIRONMENT_SMASH_WALLS) || (environment_smash & ENVIRONMENT_SMASH_RWALLS))
					Goto(target,move_to_delay,minimum_distance)
					FindHidden()
					return 1
				else
					if(FindHidden())
						return 1
	LoseTarget()
	return 0

/mob/living/simple_animal/hostile/proc/Goto(target, delay, minimum_distance)
	if(target == src.target)
		approaching_target = TRUE
	else
		approaching_target = FALSE
	if(CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		set_glide_size(DELAY_TO_GLIDE_SIZE(move_to_delay))
		walk_to(src, target, minimum_distance, delay)
	if(variation_list[MOB_MINIMUM_DISTANCE_CHANCE] && LAZYLEN(variation_list[MOB_MINIMUM_DISTANCE]) && prob(variation_list[MOB_MINIMUM_DISTANCE_CHANCE]))
		minimum_distance = vary_from_list(variation_list[MOB_MINIMUM_DISTANCE])
	if(variation_list[MOB_VARIED_SPEED_CHANCE] && LAZYLEN(variation_list[MOB_VARIED_SPEED]) && prob(variation_list[MOB_VARIED_SPEED_CHANCE]))
		move_to_delay = vary_from_list(variation_list[MOB_VARIED_SPEED])

/mob/living/simple_animal/hostile/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(!ckey && !stat && search_objects < 3 && . > 0)//Not unconscious, and we don't ignore mobs
		if(search_objects)//Turn off item searching and ignore whatever item we were looking at, we're more concerned with fight or flight
			LoseTarget()
			LoseSearchObjects()
		if(AIStatus != AI_ON && AIStatus != AI_OFF)
			toggle_ai(AI_ON)
			FindTarget()
		else if(target != null && prob(40))//No more pulling a mob forever and having a second player attack it, it can switch targets now if it finds a more suitable one
			FindTarget()


/mob/living/simple_animal/hostile/proc/AttackingTarget()
	SEND_SIGNAL(src, COMSIG_HOSTILE_ATTACKINGTARGET, target)
	in_melee = TRUE
	if(prob(alternate_attack_prob) && AlternateAttackingTarget(target))
		return FALSE
	return target.attack_animal(src)

/// Does an extra *thing* when attacking. Return TRUE to not do the standard attack
/mob/living/simple_animal/hostile/proc/AlternateAttackingTarget(atom/the_target)
	return

/mob/living/simple_animal/hostile/proc/Aggro()
	if(ckey)
		return TRUE
	vision_range = aggro_vision_range
	if(target && LAZYLEN(emote_taunt) && prob(taunt_chance))
		INVOKE_ASYNC(src, PROC_REF(emote), "me", EMOTE_VISIBLE, "[pick(emote_taunt)] at [target].")
		taunt_chance = max(taunt_chance-7,2)
	if(LAZYLEN(emote_taunt_sound))
		var/taunt_choice = pick(emote_taunt_sound)
		playsound(loc, taunt_choice, 50, 0, vary = FALSE, frequency = SOUND_FREQ_NORMALIZED(sound_pitch, vary_pitches[1], vary_pitches[2]))


/mob/living/simple_animal/hostile/proc/LoseAggro()
	stop_automated_movement = 0
	vision_range = initial(vision_range)
	taunt_chance = initial(taunt_chance)

/mob/living/simple_animal/hostile/proc/LoseTarget()
	// Check if target just changed Z-levels before giving up
	if(target && can_z_move && isliving(target))
		var/mob/living/L = target
		if(L.z != z) // Target is on different Z!
			// MEMORY LOCK: Remember them for extended period during Z-pursuit
			remembered_target = L
			last_target_sighting = world.time
			last_known_location = get_turf(L)
			
			// Give ourselves a brief grace period to re-acquire via Z pursuit
			if((world.time - last_z_move_attempt) < 50) // Within 5 seconds of last Z move
				return // Keep the target locked!
			
			if(attempt_z_pursuit())
				return // Don't lose target, we're pursuing
	
	// Only clear memory if enough time has passed AND not in search mode
	if(remembered_target && (world.time - last_target_sighting) > target_memory_duration && !searching)
		remembered_target = null
	
	// Don't clear target/pursuit state if we have a remembered target or are searching
	if((remembered_target && (world.time - last_target_sighting) < target_memory_duration) || searching)
		return // Keep pursuit active
	
	// Clear search mode
	if(searching)
		exit_search_mode()
	
	// Clear Z-pursuit state when actually losing target
	pursuing_z_target = FALSE
	z_pursuit_structure = null
	remembered_target = null
	last_known_location = null
	
	GiveTarget(null)
	approaching_target = FALSE
	in_melee = FALSE
	walk(src, 0)
	LoseAggro()

// Z-LEVEL PURSUIT SYSTEM
// This proc handles mobs chasing targets up/down stairs and ladders
// Called when target is on a different Z-level than the mob
/mob/living/simple_animal/hostile/proc/attempt_z_pursuit()
	if(!target || !can_z_move) // Master toggle
		pursuing_z_target = FALSE
		z_pursuit_structure = null
		return FALSE
	
	// Check Z-level commitment - don't pursue if committed to current Z
	if(!should_change_z_level())
		pursuing_z_target = FALSE
		z_pursuit_structure = null
		return FALSE
	
	// Prevent stair loop - don't pursue if we just changed Z-levels
	if((world.time - last_successful_z_move) < z_move_success_cooldown)
		pursuing_z_target = FALSE
		z_pursuit_structure = null
		return FALSE
	
	var/mob/living/L = target
	if(!istype(L))
		pursuing_z_target = FALSE
		z_pursuit_structure = null
		return FALSE
	
	var/went_up = (L.z > z)
	var/went_down = (L.z < z)
	
	// Don't pursue if target is on same Z (prevents loop when they just climbed)
	if(L.z == z)
		pursuing_z_target = FALSE
		z_pursuit_structure = null
		return FALSE
	
	// STEP 1: Check if we're standing ON a ladder right now
	// If yes, climb immediately without pathfinding (if we can climb ladders)
	if(can_climb_ladders)
		var/obj/structure/ladder/unbreakable/current_ladder = locate() in loc
		if(current_ladder)
			if(went_up && current_ladder.up)
				visible_message(span_warning("[src] climbs up the ladder after [target]!"))
				zMove(target = get_turf(current_ladder.up), z_move_flags = ZMOVE_CHECK_PULLEDBY|ZMOVE_ALLOW_BUCKLED|ZMOVE_INCLUDE_PULLED)
				last_z_move_attempt = world.time
				last_successful_z_move = world.time
				pursuing_z_target = FALSE  // We climbed! Clear pursuit state
				z_pursuit_structure = null
				record_z_level_change()
				return TRUE
			else if(went_down && current_ladder.down)
				visible_message(span_warning("[src] climbs down the ladder after [target]!"))
				zMove(target = get_turf(current_ladder.down), z_move_flags = ZMOVE_CHECK_PULLEDBY|ZMOVE_ALLOW_BUCKLED|ZMOVE_INCLUDE_PULLED)
				last_z_move_attempt = world.time
				last_successful_z_move = world.time
				pursuing_z_target = FALSE  // We climbed! Clear pursuit state
				z_pursuit_structure = null
				record_z_level_change()
				return TRUE
	
	// STEP 2: Check if we're near stairs (reduces cooldown)
	var/near_stairs = FALSE
	if(can_climb_stairs && went_up)
		for(var/obj/structure/stairs/S in view(vision_range, src))
			if(S.isTerminator())
				var/dist = get_dist(src, S)
				if(dist <= 2) // Within 2 tiles of stairs
					near_stairs = TRUE
					break
	
	// STEP 3: Cooldown check (can be bypassed if near stairs)
	if(world.time < last_z_move_attempt + z_move_delay)
		if(near_stairs)
			// Very short cooldown when near stairs
			if(world.time < last_z_move_attempt + 2)
				return pursuing_z_target  // Return current state
		else
			return pursuing_z_target  // Return current state
	
	last_z_move_attempt = world.time
	target_last_z = L.z
	
	if(!went_up && !went_down)
		pursuing_z_target = FALSE
		z_pursuit_structure = null
		return FALSE
	
	// STEP 4: Find Z-level transition structures (stairs, ladders, openspace)
	// Only include structures we're actually allowed to use
	var/list/z_structures = list()
	
	if(went_up)
		// Target went UP - look for stairs and ladders going up
		if(can_climb_stairs)
			for(var/obj/structure/stairs/S in view(vision_range, src))
				if(S.isTerminator())
					z_structures += S
		
		if(can_climb_ladders)
			for(var/obj/structure/ladder/LD in view(vision_range, src))
				if(LD.up)
					z_structures += LD
	
	else if(went_down)
		// Target went DOWN - look for openspace and ladders going down
		if(can_jump_down)
			var/turf/our_turf = get_turf(src)
			
			if(istype(our_turf, /turf/open/transparent/openspace))
				z_structures += our_turf
			
			for(var/turf/open/transparent/openspace/OS in view(vision_range, src))
				z_structures += OS
		
		if(can_climb_ladders)
			for(var/obj/structure/ladder/LD in view(vision_range, src))
				if(LD.down)
					z_structures += LD
	
	if(!z_structures.len)
		pursuing_z_target = FALSE
		z_pursuit_structure = null
		return FALSE
	
	// STEP 5: Pick nearest structure and enter Z-pursuit state
	var/atom/nearest = get_closest_atom(/atom, z_structures, src)
	
	// Enter Z-pursuit state - this locks the mob into climbing mode
	pursuing_z_target = TRUE
	z_pursuit_structure = nearest
	z_pursuit_started = world.time
	
	visible_message(span_danger("[src] pursues [target] [went_up ? "upward" : "downward"]!"))
	
	// CALL FOR BACKUP - alert allies about Z-level pursuit
	call_for_backup(target, "found")
	
	LosePatience()
	GainPatience()
	COOLDOWN_RESET(src, sight_shoot_delay)
	
	// STEP 6: Handle different structure types
	
	// STAIRS - special handling for multi-tile climb (only if we can climb stairs)
	if(went_up && can_climb_stairs && istype(nearest, /obj/structure/stairs))
		var/obj/structure/stairs/S = nearest
		var/turf/our_turf = get_turf(src)
		var/turf/stairs_turf = get_turf(S)
		var/dist = get_dist(src, S)
		
		if(our_turf == stairs_turf)
			// Already on stairs - climb
			var/step_result = step(src, S.dir)
			if(!step_result)
				// Climb blocked, set micro-cooldown
				last_z_move_attempt = world.time - (z_move_delay - 2)
		else if(dist <= 1)
			// Adjacent - try to step on
			walk(src, 0)
			var/dir_to_stairs = get_dir(src, S)
			var/step_result = step(src, dir_to_stairs)
			
			if(step_result && get_turf(src) == stairs_turf)
				addtimer(CALLBACK(src, PROC_REF(climb_stairs), S), 1)
			else if(!step_result)
				last_z_move_attempt = world.time - (z_move_delay - 2)
				return TRUE
		else
			// Use Goto for pathfinding
			Goto(S, move_to_delay, 0)
	
	// LADDERS - aggressive stepping to ensure mob gets ON the ladder tile (only if we can climb ladders)
	else if(can_climb_ladders && istype(nearest, /obj/structure/ladder))
		var/obj/structure/ladder/L_target = nearest
		var/dist = get_dist(src, L_target)
		
		// Check if already on ladder tile
		var/obj/structure/ladder/on_ladder = locate() in loc
		if(on_ladder)
			// Already on ladder, next tick will detect and climb
			return TRUE
		
		if(dist == 0)
			// Somehow on ladder tile without locate() finding it - next tick will climb
			return TRUE
		else if(dist == 1)
			// Adjacent to ladder - AGGRESSIVELY step onto it
			walk(src, 0) // Stop any pathfinding
			step(src, get_dir(src, L_target)) // Force step onto ladder
			// Next AI tick will detect we're on ladder and climb
		else
			// Still far away - pathfind toward ladder
			Goto(L_target, move_to_delay, 0)
	
	// OPENSPACE/OTHER - generic pathfinding (only if we can jump down)
	else if(can_jump_down)
		Goto(nearest, move_to_delay, 0)
	else
		// We can't use this structure type, give up
		pursuing_z_target = FALSE
		z_pursuit_structure = null
		return FALSE
	
	return TRUE

// Helper proc for delayed stair climbing
/mob/living/simple_animal/hostile/proc/climb_stairs(obj/structure/stairs/S)
	if(!S || QDELETED(S) || QDELETED(src))
		return
	
	var/turf/our_turf = get_turf(src)
	var/turf/stairs_turf = get_turf(S)
	
	if(our_turf != stairs_turf)
		return
	
	step(src, S.dir)
	
	// Mark this as a successful Z-move to prevent immediate loop
	record_z_level_change() // Changed from last_successful_z_move = world.time
	pursuing_z_target = FALSE
	z_pursuit_structure = null

// SEARCH MODE - actively patrol and look for lost target
/mob/living/simple_animal/hostile/proc/enter_search_mode()
	if(searching)
		return // Already searching
	
	searching = TRUE
	last_known_location = get_turf(target) // Remember where we last saw them
	
	visible_message(span_warning("[src] looks around suspiciously..."))
	
	// Call for backup - let allies know we lost the target
	if(target)
		call_for_backup(target, "lost")
	
	// Start search timer
	search_timer_id = addtimer(CALLBACK(src, PROC_REF(exit_search_mode)), search_duration, TIMER_STOPPABLE)
	
	// Start searching behavior
	search_for_target()

/mob/living/simple_animal/hostile/proc/exit_search_mode()
	searching = FALSE
	last_known_location = null
	search_timer_id = null
	
	// Give up and return to idle
	if(!target)
		LoseTarget()

/mob/living/simple_animal/hostile/proc/search_for_target()
	if(!searching || QDELETED(src))
		return
	
	// If we found the target, exit search mode
	if(target && (target in ListTargets()))
		exit_search_mode()
		last_target_sighting = world.time
		return
	
	// Move to a random location near last known position
	if(last_known_location && CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		var/list/search_turfs = list()
		for(var/turf/T in range(search_radius, last_known_location))
			if(istype(T, /turf/open))
				search_turfs += T
		
		if(search_turfs.len)
			var/turf/search_target = pick(search_turfs)
			Goto(search_target, move_to_delay, 0)
	
	// Keep searching every few seconds
	addtimer(CALLBACK(src, PROC_REF(search_for_target)), 3 SECONDS)

// BACKUP SYSTEM - alert nearby allies about target location
/mob/living/simple_animal/hostile/proc/call_for_backup(atom/found_target, alert_type = "found")
	if(!found_target)
		return
	
	// Cooldown check to prevent spam
	if(!COOLDOWN_FINISHED(src, backup_call_cooldown))
		return
	
	COOLDOWN_START(src, backup_call_cooldown, backup_call_delay)
	
	// Alert message
	switch(alert_type)
		if("found")
			visible_message(span_danger("[src] alerts nearby allies!"))
		if("lost")
			visible_message(span_warning("[src] signals they've lost sight of the target!"))
	
	// Find allies in range, INCLUDING ACROSS Z-LEVELS
	var/list/allies_to_alert = list()
	
	// Same Z-level
	for(var/mob/living/simple_animal/hostile/M in range(backup_call_range, src))
		if(M == src || M.stat == DEAD || M.ckey)
			continue
		if(faction_check_mob(M, TRUE))
			allies_to_alert += M
	
	// Check Z-level above
	var/turf/above_us = get_step_multiz(get_turf(src), UP)
	if(above_us)
		for(var/mob/living/simple_animal/hostile/M in range(backup_call_range, above_us))
			if(M == src || M.stat == DEAD || M.ckey)
				continue
			if(faction_check_mob(M, TRUE))
				allies_to_alert += M
	
	// Check Z-level below
	var/turf/below_us = get_step_multiz(get_turf(src), DOWN)
	if(below_us)
		for(var/mob/living/simple_animal/hostile/M in range(backup_call_range, below_us))
			if(M == src || M.stat == DEAD || M.ckey)
				continue
			if(faction_check_mob(M, TRUE))
				allies_to_alert += M
	
	// Alert each ally
	for(var/mob/living/simple_animal/hostile/ally in allies_to_alert)
		switch(alert_type)
			if("found")
				ally.receive_backup_alert(found_target, get_turf(found_target))
			if("lost")
				ally.receive_lost_alert(found_target, get_turf(found_target))

// Receive backup alert from ally
/mob/living/simple_animal/hostile/proc/receive_backup_alert(atom/alert_target, turf/target_location)
	if(!alert_target || QDELETED(alert_target))
		return
	
	// If we're idle or searching, immediately respond
	if(AIStatus == AI_IDLE || searching)
		// Exit search mode if in it
		if(searching)
			exit_search_mode()
		
		// Set this as our target
		GiveTarget(alert_target)
		remembered_target = alert_target
		last_target_sighting = world.time
		last_known_location = target_location
		
		// Wake up AI
		if(AIStatus != AI_ON)
			toggle_ai(AI_ON)
		
		visible_message(span_danger("[src] responds to the alert!"))
	
	// If we have a different target, consider switching if the alerted target is closer
	else if(target && target != alert_target)
		var/current_target_dist = get_dist(src, target)
		var/alert_target_dist = get_dist(src, alert_target)
		
		// Switch to closer target
		if(alert_target_dist < current_target_dist)
			GiveTarget(alert_target)
			remembered_target = alert_target
			last_target_sighting = world.time
			last_known_location = target_location

// Receive lost target alert from ally
/mob/living/simple_animal/hostile/proc/receive_lost_alert(atom/lost_target, turf/last_location)
	// If we're searching for the same target, update our search location
	if(searching && remembered_target == lost_target)
		last_known_location = last_location
		visible_message(span_notice("[src] updates their search pattern..."))

// DOOR OPENING - smart mobs can open doors instead of destroying them
/mob/living/simple_animal/hostile/proc/try_open_door(atom/D)
	if(!can_open_doors)
		return FALSE
	
	if(!D || QDELETED(D))
		return FALSE
	
	// Check cooldown
	if(!COOLDOWN_FINISHED(src, door_open_cooldown))
		return FALSE
	
	COOLDOWN_START(src, door_open_cooldown, door_open_delay)
	
	// Handle simple doors (wooden, metal, etc)
	if(istype(D, /obj/structure/simple_door))
		var/obj/structure/simple_door/SD = D
		
		// Check if door has a padlock
		if(SD.padlock && SD.padlock.locked)
			return FALSE // Can't open locked doors
		
		// Check if door is already open
		if(!SD.density)
			return FALSE
		
		// Check if door is moving
		if(SD.moving)
			return FALSE
		
		// Open the door using the proper method
		visible_message(span_notice("[src] opens [SD]."))
		SD.SwitchState(TRUE) // Use SwitchState with animate = TRUE
		return TRUE
	
	// Handle airlocks
	if(istype(D, /obj/machinery/door/airlock))
		if(!can_open_airlocks)
			return FALSE
		
		var/obj/machinery/door/airlock/A = D
		if(A.locked || A.welded)
			return FALSE // Can't open locked/welded doors
		
		// Try to open it
		if(A.density) // Door is closed
			visible_message(span_notice("[src] opens [A]."))
			INVOKE_ASYNC(A, TYPE_PROC_REF(/obj/machinery/door, open))
			return TRUE
		
		return FALSE
	
	// Handle other machinery doors
	if(istype(D, /obj/machinery/door))
		var/obj/machinery/door/MD = D
		
		// Try to open it
		if(MD.density) // Door is closed
			visible_message(span_notice("[src] opens [MD]."))
			INVOKE_ASYNC(MD, TYPE_PROC_REF(/obj/machinery/door, open))
			return TRUE
	
	return FALSE

// Z-LEVEL COMMITMENT - prevents constant up/down movement
/mob/living/simple_animal/hostile/proc/commit_to_z_level()
	committed_z_level = z
	z_commit_time = world.time
	recent_climbs = 0

/mob/living/simple_animal/hostile/proc/should_change_z_level()
	// Reset climb counter every 30 seconds
	if((world.time - last_climb_reset) > 300)
		recent_climbs = 0
		last_climb_reset = world.time
	
	// If we've climbed 3+ times recently, commit to current Z
	if(recent_climbs >= 3)
		commit_to_z_level()
		visible_message(span_notice("[src] decides to stay on this level for now."))
		return FALSE
	
	// If we just committed to a Z-level, don't change
	if(committed_z_level == z && (world.time - z_commit_time) < z_commit_duration)
		return FALSE
	
	return TRUE

/mob/living/simple_animal/hostile/proc/record_z_level_change()
	recent_climbs++
	last_climb_reset = world.time
	last_successful_z_move = world.time

// SOUND DETECTION - hear gunfire and move toward it
/mob/living/simple_animal/hostile/proc/hear_combat_sound(turf/sound_location, atom/sound_source)
	if(!can_hear_combat)
		return
	
	if(!sound_location || QDELETED(sound_location))
		return
	
	// Ignore sounds too far away (including Z-distance)
	var/distance = get_dist(src, sound_location)
	var/z_distance = abs(z - sound_location.z)
	
	if(distance > combat_hearing_range)
		return
	
	if(z_distance > 1) // Only hear sounds 1 Z-level away max
		return
	
	last_combat_sound = world.time
	
	// Don't give exact location - pick a random spot near the sound (simulates hearing direction)
	var/list/investigation_turfs = list()
	for(var/turf/T in range(7, sound_location)) // 7 tile radius around actual sound
		if(istype(T, /turf/open))
			investigation_turfs += T
	
	var/turf/investigation_spot = sound_location
	if(investigation_turfs.len)
		investigation_spot = pick(investigation_turfs)
	
	// If we're stuck on stairs or in a loop, this breaks us out
	if(pursuing_z_target || (recent_climbs >= 2))
		// Commit to the Z-level the sound came from
		if(sound_location.z != z && can_z_move)
			committed_z_level = 0 // Clear commitment
			recent_climbs = 0
			z_commit_time = 0
			
			visible_message(span_danger("[src] perks up at the sound of combat!"))
			
			if(remembered_target)
				last_known_location = investigation_spot // Use approximate location
			
			if(searching)
				last_known_location = investigation_spot
		else if(sound_location.z == z)
			commit_to_z_level()
			visible_message(span_danger("[src] hears combat nearby!"))
			
			if(searching || !target)
				last_known_location = investigation_spot
				if(!searching)
					enter_search_mode()
	
	// If we're idle or searching, investigate the sound
	if(AIStatus == AI_IDLE || searching)
		last_known_location = investigation_spot // Approximate location
		
		if(!searching)
			enter_search_mode()
		else
			visible_message(span_notice("[src] adjusts their search toward the gunfire..."))

//////////////END HOSTILE MOB TARGETTING AND AGGRESSION////////////

/mob/living/simple_animal/hostile/death(gibbed)
	LoseTarget()
	..(gibbed)

/mob/living/simple_animal/hostile/proc/summon_backup(distance, exact_faction_match)
	if(COOLDOWN_FINISHED(src, ding_spam_cooldown))
		return TRUE
	COOLDOWN_START(src, ding_spam_cooldown, SIMPLE_MOB_DING_COOLDOWN)
	do_alert_animation(src)
	playsound(loc, 'sound/machines/chime.ogg', 50, 1, -1)
	for(var/mob/living/simple_animal/hostile/M in oview(distance, targets_from))
		if(faction_check_mob(M, TRUE))
			if(M.AIStatus == AI_OFF || M.stat == DEAD || M.ckey)
				return
			M.Goto(src,M.move_to_delay,M.minimum_distance)

/mob/living/simple_animal/hostile/proc/CheckFriendlyFire(atom/A)
	if(check_friendly_fire && !ckey)
		for(var/turf/T in getline(src,A)) // Not 100% reliable but this is faster than simulating actual trajectory
			for(var/mob/living/L in T)
				if(L == src || L == A)
					continue
				if(faction_check_mob(L) && !attack_same)
					return TRUE

/mob/living/simple_animal/hostile/proc/CanShootThrough(atom/A)
	// Same Z-level is fine
	if(A.z == z)
		return TRUE
	
	// Check if we can shoot down through openspace
	if(A.z == z - 1) // Target is below us
		var/turf/our_turf = get_turf(src)
		if(istype(our_turf, /turf/open/transparent/openspace))
			return TRUE
		// Check if we're standing near openspace with clear shot
		for(var/turf/open/transparent/openspace/OS in range(1, src))
			if(get_dir(src, A) == get_dir(src, OS))
				return TRUE
	
	// Check if we can shoot up through openspace
	if(A.z == z + 1) // Target is above us
		var/turf/their_turf = get_turf(A)
		if(istype(their_turf, /turf/open/transparent/openspace))
			return TRUE
	
	return FALSE

/mob/living/simple_animal/hostile/proc/OpenFire(atom/A)
	if(COOLDOWN_TIMELEFT(src, sight_shoot_delay))
		return FALSE
	
	// Allow shooting through openspace
	if(A.z != z)
		var/can_shoot = FALSE
		
		// Shooting down through openspace
		if(A.z == z - 1)
			var/turf/A_turf = get_turf(A)
			var/turf/above_target = get_step_multiz(A_turf, UP)
			if(above_target && istype(above_target, /turf/open/transparent/openspace))
				// Make sure we're near the openspace
				if(get_dist(src, above_target) <= vision_range)
					can_shoot = TRUE
		
		// Shooting up through openspace
		else if(A.z == z + 1)
			var/turf/our_turf = get_turf(src)
			var/turf/above_us = get_step_multiz(our_turf, UP)
			if(above_us && istype(above_us, /turf/open/transparent/openspace))
				can_shoot = TRUE
		
		if(!can_shoot)
			return FALSE
	
	if(CheckFriendlyFire(A))
		return
	
	visible_message("<span class='danger'><b>[src]</b> [islist(ranged_message) ? pick(ranged_message) : ranged_message] at [A]!</span>")
	if(rapid > 1)
		var/datum/callback/cb = CALLBACK(src, PROC_REF(Shoot), A)
		for(var/i in 1 to rapid)
			addtimer(cb, (i - 1)*rapid_fire_delay)
	else
		Shoot(A)
		for(var/i in 1 to extra_projectiles)
			addtimer(CALLBACK(src, PROC_REF(Shoot), A), i * auto_fire_delay)
	ranged_cooldown = world.time + ranged_cooldown_time
	if(sound_after_shooting)
		addtimer(CALLBACK(GLOBAL_PROC,GLOBAL_PROC_REF(playsound), src, sound_after_shooting, 100, 0, 0), sound_after_shooting_delay, TIMER_STOPPABLE)
	if(projectiletype)
		if(LAZYLEN(variation_list[MOB_PROJECTILE]) >= 2)
			projectiletype = vary_from_list(variation_list[MOB_PROJECTILE], TRUE)
	if(casingtype)
		if(LAZYLEN(variation_list[MOB_CASING]) >= 2)
			casingtype = vary_from_list(variation_list[MOB_CASING], TRUE)

/mob/living/simple_animal/hostile/proc/Shoot(atom/targeted_atom)
	if( QDELETED(targeted_atom) || targeted_atom == targets_from.loc || targeted_atom == targets_from )
		return
	var/turf/startloc = get_turf(targets_from)
	if(casingtype)
		var/obj/item/ammo_casing/casing = new casingtype(startloc)
		playsound(
			src,
			projectilesound,
			projectile_sound_properties[SOUND_PROPERTY_VOLUME],
			projectile_sound_properties[SOUND_PROPERTY_VARY],
			projectile_sound_properties[SOUND_PROPERTY_NORMAL_RANGE],
			ignore_walls = projectile_sound_properties[SOUND_PROPERTY_IGNORE_WALLS],
			distant_sound = projectile_sound_properties[SOUND_PROPERTY_DISTANT_SOUND],
			distant_range = projectile_sound_properties[SOUND_PROPERTY_DISTANT_SOUND_RANGE], 
			vary = FALSE, 
			frequency = SOUND_FREQ_NORMALIZED(sound_pitch, vary_pitches[1], vary_pitches[2])
			)
		casing.fire_casing(targeted_atom, src, null, null, null, ran_zone(), 0, null, null, null, src)
		qdel(casing)
	else if(projectiletype)
		var/obj/item/projectile/P = new projectiletype(startloc)
		playsound(
			src,
			projectilesound,
			projectile_sound_properties[SOUND_PROPERTY_VOLUME],
			projectile_sound_properties[SOUND_PROPERTY_VARY],
			projectile_sound_properties[SOUND_PROPERTY_NORMAL_RANGE],
			ignore_walls = projectile_sound_properties[SOUND_PROPERTY_IGNORE_WALLS],
			distant_sound = projectile_sound_properties[SOUND_PROPERTY_DISTANT_SOUND],
			distant_range = projectile_sound_properties[SOUND_PROPERTY_DISTANT_SOUND_RANGE], 
			vary = FALSE, 
			frequency = SOUND_FREQ_NORMALIZED(sound_pitch, vary_pitches[1], vary_pitches[2])
			)
		P.starting = startloc
		P.firer = src
		P.fired_from = src
		P.yo = targeted_atom.y - startloc.y
		P.xo = targeted_atom.x - startloc.x
		if(AIStatus != AI_ON)//Don't want mindless mobs to have their movement screwed up firing in space
			newtonian_move(get_dir(targeted_atom, targets_from))
		P.original = targeted_atom
		P.preparePixelProjectile(targeted_atom, src)
		P.fire()
		return P

/mob/living/simple_animal/hostile/proc/CanSmashTurfs(turf/T)
	return iswallturf(T) || ismineralturf(T)


/mob/living/simple_animal/hostile/Move(atom/newloc, dir, step_x, step_y)
	if(dodging && approaching_target && prob(dodge_prob) && moving_diagonally == 0 && isturf(loc) && isturf(newloc))
		return dodge(newloc,dir)
	
	// Check if we're stepping onto/off stairs
	var/was_on_stairs = FALSE
	for(var/obj/structure/stairs/S in loc)
		was_on_stairs = TRUE
		break
	
	var/moving_to_stairs = FALSE
	for(var/obj/structure/stairs/S in newloc)
		moving_to_stairs = TRUE
		break
	
	// ANTI-LOOP: Count consecutive stair steps
	if(was_on_stairs || moving_to_stairs)
		consecutive_stair_steps++
		
		if(consecutive_stair_steps >= max_consecutive_stair_steps)
			// Too many stair steps! Force commit and stop pursuing
			commit_to_z_level()
			pursuing_z_target = FALSE
			z_pursuit_structure = null
			consecutive_stair_steps = 0
			
			visible_message(span_notice("[src] stops at the stairs."))
			return FALSE // Don't move onto stairs
	else
		consecutive_stair_steps = 0
	
	. = ..() // Do the move
	
	if(!.) // Move failed
		return FALSE
	
	// IMMEDIATE LADDER CLIMBING
	if(can_climb_ladders && pursuing_z_target && target && target.z != z && !client)
		if((world.time - last_successful_z_move) < z_move_success_cooldown)
			return .
		
		var/obj/structure/ladder/unbreakable/L = locate() in loc
		if(L)
			var/went_up = (target.z > z)
			var/went_down = (target.z < z)
			
			if(went_up && L.up)
				visible_message(span_warning("[src] immediately climbs up the ladder!"))
				zMove(target = get_turf(L.up), z_move_flags = ZMOVE_CHECK_PULLEDBY|ZMOVE_ALLOW_BUCKLED|ZMOVE_INCLUDE_PULLED)
				pursuing_z_target = FALSE
				z_pursuit_structure = null
				last_z_move_attempt = world.time
				last_successful_z_move = world.time
				record_z_level_change()
				consecutive_stair_steps = 0
				return TRUE
			else if(went_down && L.down)
				visible_message(span_warning("[src] immediately climbs down the ladder!"))
				zMove(target = get_turf(L.down), z_move_flags = ZMOVE_CHECK_PULLEDBY|ZMOVE_ALLOW_BUCKLED|ZMOVE_INCLUDE_PULLED)
				pursuing_z_target = FALSE
				z_pursuit_structure = null
				last_z_move_attempt = world.time
				last_successful_z_move = world.time
				record_z_level_change()
				consecutive_stair_steps = 0
				return TRUE

/mob/living/simple_animal/hostile/proc/dodge(moving_to,move_direction)
	//Assuming we move towards the target we want to swerve toward them to get closer
	var/cdir = turn(move_direction,45)
	var/ccdir = turn(move_direction,-45)
	dodging = FALSE
	. = Move(get_step(loc,pick(cdir,ccdir)))
	if(!.)//Can't dodge there so we just carry on
		. =  Move(moving_to,move_direction)
	dodging = TRUE

/mob/living/simple_animal/hostile/proc/DestroyObjectsInDirection(direction)
	var/turf/T = get_step(targets_from, direction)
	if(T && T.Adjacent(targets_from))
		if(CanSmashTurfs(T))
			T.attack_animal(src)
		for(var/obj/O in T)
			if(O.density && environment_smash >= ENVIRONMENT_SMASH_STRUCTURES && !O.IsObscured())
				O.attack_animal(src)
				return


/mob/living/simple_animal/hostile/proc/DestroyPathToTarget()
	// STEP 1: Try opening doors first (if capable)
	if(can_open_doors)
		var/dir_to_target = get_dir(targets_from, target)
		var/turf/T = get_step(targets_from, dir_to_target)
		if(T)
			for(var/obj/machinery/door/D in T)
				if(D.density && try_open_door(D))
					return // Successfully opened door, no need to smash
	
	// STEP 2: Only smash if we can't open doors OR door opening failed
	if(environment_smash)
		EscapeConfinement()
		var/dir_to_target = get_dir(targets_from, target)
		var/dir_list = list()
		if(dir_to_target in GLOB.diagonals)
			for(var/direction in GLOB.cardinals)
				if(direction & dir_to_target)
					dir_list += direction
		else
			dir_list += dir_to_target
		
		// Only smash if target is relatively close (prevents smashing through entire base)
		var/target_dist = get_dist(targets_from, target)
		if(target_dist <= 5) // Only smash if within 5 tiles
			for(var/direction in dir_list)
				DestroyOrOpenInDirection(direction)

/mob/living/simple_animal/hostile/proc/DestroyOrOpenInDirection(direction)
	var/turf/T = get_step(targets_from, direction)
	if(T && T.Adjacent(targets_from))
		// Check for doors first
		if(can_open_doors)
			// Try simple doors
			for(var/obj/structure/simple_door/SD in T)
				if(SD.density) // Door is closed
					if(try_open_door(SD))
						return // Successfully opened door, don't destroy
			
			// Try machinery doors
			for(var/obj/machinery/door/D in T)
				if(D.density) // Door is closed
					if(try_open_door(D))
						return // Successfully opened door, don't destroy
		
		// If we didn't open a door, proceed with normal destruction
		if(environment_smash)
			if(CanSmashTurfs(T))
				T.attack_animal(src)
			for(var/obj/O in T)
				if(O.density && environment_smash >= ENVIRONMENT_SMASH_STRUCTURES && !O.IsObscured())
					O.attack_animal(src)
					return

mob/living/simple_animal/hostile/proc/DestroySurroundings() // for use with megafauna destroying everything around them
	if(environment_smash)
		EscapeConfinement()
		for(var/dir in GLOB.cardinals)
			DestroyObjectsInDirection(dir)


/mob/living/simple_animal/hostile/proc/EscapeConfinement()
	if(buckled)
		buckled.attack_animal(src)
	if(!isturf(targets_from.loc) && targets_from.loc != null)//Did someone put us in something?
		var/atom/A = targets_from.loc
		A.attack_animal(src)//Bang on it till we get out


/mob/living/simple_animal/hostile/proc/FindHidden()
	if(istype(target.loc, /obj/structure/closet) || istype(target.loc, /obj/machinery/disposal) || istype(target.loc, /obj/machinery/sleeper))
		var/atom/A = target.loc
		Goto(A,move_to_delay,minimum_distance)
		if(A.Adjacent(targets_from))
			A.attack_animal(src)
		return 1

/mob/living/simple_animal/hostile/RangedAttack(atom/A, params) //Player firing
	if(ranged && ranged_cooldown <= world.time)
		GiveTarget(A)
		OpenFire(A)
		DelayNextAction()
	. = ..()
	return TRUE

////// AI Status ///////
/mob/living/simple_animal/hostile/proc/AICanContinue(list/possible_targets)
	switch(AIStatus)
		if(AI_ON)
			. = 1
		if(AI_IDLE)
			if(FindTarget(possible_targets, 1))
				. = 1
				toggle_ai(AI_ON) //Wake up for more than one Life() cycle.
			else
				. = 0

/mob/living/simple_animal/hostile/proc/AIShouldSleep(list/possible_targets)
	return !FindTarget(possible_targets, 1)


//These two procs handle losing our target if we've failed to attack them for
//more than lose_patience_timeout deciseconds, which probably means we're stuck
/mob/living/simple_animal/hostile/proc/GainPatience()
	if(QDELETED(src))
		return
	
	if(lose_patience_timeout)
		LosePatience()
		lose_patience_timer_id = addtimer(CALLBACK(src, PROC_REF(LoseTarget)), lose_patience_timeout, TIMER_STOPPABLE)


/mob/living/simple_animal/hostile/proc/LosePatience()
	deltimer(lose_patience_timer_id)


//These two procs handle losing and regaining search_objects when attacked by a mob
/mob/living/simple_animal/hostile/proc/LoseSearchObjects()
	if(QDELETED(src))
		return
	
	search_objects = 0
	deltimer(search_objects_timer_id)
	search_objects_timer_id = addtimer(CALLBACK(src, PROC_REF(RegainSearchObjects)), search_objects_regain_time, TIMER_STOPPABLE)


/mob/living/simple_animal/hostile/proc/RegainSearchObjects(value)
	if(!value)
		value = initial(search_objects)
	search_objects = value

/mob/living/simple_animal/hostile/consider_wakeup()
	..()
	var/list/tlist
	var/turf/T = get_turf(src)

	if (!T)
		return

	if (!length(SSmobs.clients_by_zlevel[T.z])) // It's fine to use .len here but doesn't compile on 511
		toggle_ai(AI_Z_OFF)
		return
	
	tlist = ListTargetsLazy(T.z)

	if(AIStatus == AI_IDLE && tlist.len)
		toggle_ai(AI_ON)

/mob/living/simple_animal/hostile/proc/ListTargetsLazy(_Z)//Step 1, find out what we can see
	var/static/hostile_machines = typecacheof(list(/obj/machinery/porta_turret, /obj/mecha, /obj/structure/destructible/clockwork/ocular_warden))
	. = list()
	for (var/I in SSmobs.clients_by_zlevel[_Z])
		var/mob/M = I
		if (get_dist(M, src) < vision_range)
			if (isturf(M.loc))
				. += M
			else if (M.loc.type in hostile_machines)
				. += M.loc

// Fix the handle_target_del to ensure it clears properly
/mob/living/simple_animal/hostile/proc/handle_target_del(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(target, COMSIG_PARENT_QDELETING)
	target = null
	LoseTarget()

// Ensure add_target properly cleans up old references
/mob/living/simple_animal/hostile/proc/add_target(new_target)
	if(target)
		UnregisterSignal(target, COMSIG_PARENT_QDELETING)
	target = new_target
	if(target)
		RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(handle_target_del))

/mob/living/simple_animal/hostile/proc/queue_unbirth()
	SSidlenpcpool.add_to_culling(src)

/mob/living/simple_animal/hostile/proc/unqueue_unbirth()
	SSidlenpcpool.remove_from_culling(src)

/// return to monke-- stuffs a mob into their own special nest
/mob/living/simple_animal/hostile/proc/unbirth_self(forced)
	if(!forced && !consider_despawning()) // check again plz
		return
	var/obj/structure/nest/my_home
	if(isweakref(nest))
		my_home = RESOLVEWEAKREF(nest)
	if(!my_home)
		my_home = new/obj/structure/nest/special(get_turf(src))
	SEND_SIGNAL(my_home, COMSIG_SPAWNER_ABSORB_MOB, src)

/mob/living/simple_animal/hostile/setup_variations()
	if(!..())
		return
	if(LAZYLEN(variation_list[MOB_VARIED_VIEW_RANGE]))
		vision_range = vary_from_list(variation_list[MOB_VARIED_VIEW_RANGE])
	if(LAZYLEN(variation_list[MOB_VARIED_AGGRO_RANGE]))
		aggro_vision_range = vary_from_list(variation_list[MOB_VARIED_AGGRO_RANGE])
	if(LAZYLEN(variation_list[MOB_VARIED_SPEED]))
		move_to_delay = vary_from_list(variation_list[MOB_VARIED_SPEED])
	if(LAZYLEN(variation_list[MOB_RETREAT_DISTANCE]))
		retreat_distance = vary_from_list(variation_list[MOB_RETREAT_DISTANCE])
	if(LAZYLEN(variation_list[MOB_MINIMUM_DISTANCE]))
		minimum_distance = vary_from_list(variation_list[MOB_MINIMUM_DISTANCE])

/mob/living/simple_animal/hostile/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	emp_effect(severity)

/// EMP intensity tends to be 20-40
/mob/living/simple_animal/hostile/proc/emp_effect(intensity)
	if(!LAZYLEN(emp_flags))
		return FALSE
	if(!islist(emp_flags))
		return FALSE

	switch(pick(emp_flags))
		if(MOB_EMP_STUN)
			do_emp_stun(intensity)
		if(MOB_EMP_BERSERK)
			do_emp_berserk(intensity)
		if(MOB_EMP_DAMAGE)
			do_emp_damage(intensity)
		if(MOB_EMP_SCRAMBLE)
			do_emp_scramble(intensity)
	do_sparks(3, FALSE, src)
	return TRUE

/mob/living/simple_animal/hostile/proc/do_emp_stun(intensity)
	if(!intensity)
		return FALSE
	if(MOB_EMP_STUN in active_emp_flags)
		return FALSE
	active_emp_flags |= MOB_EMP_STUN
	visible_message(span_green("[src] shudders as the EMP overloads its servos!"))
	LoseTarget()
	toggle_ai(AI_OFF)
	addtimer(CALLBACK(src, PROC_REF(un_emp_stun)), min(intensity, 3 SECONDS))

/mob/living/simple_animal/hostile/proc/un_emp_stun()
	active_emp_flags -= MOB_EMP_STUN
	LoseTarget()
	toggle_ai(AI_ON)

/mob/living/simple_animal/hostile/proc/do_emp_berserk(intensity)
	if(!intensity)
		return FALSE
	if(MOB_EMP_BERSERK in active_emp_flags)
		return FALSE
	active_emp_flags |= MOB_EMP_BERSERK
	LoseTarget()
	visible_message(span_green("[src] lets out a burst of static and whips its gun around wildly!"))
	var/list/old_faction = faction
	faction = null
	addtimer(CALLBACK(src, PROC_REF(un_emp_berserk), old_faction), intensity SECONDS * 0.5)

/mob/living/simple_animal/hostile/proc/un_emp_berserk(list/unberserk)
	active_emp_flags -= MOB_EMP_BERSERK
	faction = unberserk
	LoseTarget()

/mob/living/simple_animal/hostile/proc/do_emp_damage(intensity)
	if(!intensity)
		return FALSE
	smoke.set_up(round(clamp(intensity*0.5, 1, 3), 1), src)
	smoke.start()
	visible_message(span_green("[src] shoots out a plume of acrid smoke!"))
	adjustBruteLoss(maxHealth * 0.01 * intensity)
	playsound(src.loc, 'sound/effects/smoke.ogg', 50, 1, -3)

/mob/living/simple_animal/hostile/proc/do_emp_scramble(intensity)
	if(!intensity)
		return FALSE
	move_to_delay = rand(move_to_delay * 0.5, move_to_delay * 2)
	auto_fire_delay = rand(auto_fire_delay * 0.8, auto_fire_delay * 1.5)
	extra_projectiles = rand(extra_projectiles - 1, extra_projectiles + 1)
	ranged_cooldown_time = rand(ranged_cooldown_time * 0.5, ranged_cooldown_time * 2)
	retreat_distance = rand(0, 10)
	minimum_distance = rand(0, 10)
	LoseTarget()
	visible_message(span_notice("[src] jerks around wildly and starts acting strange!"))
