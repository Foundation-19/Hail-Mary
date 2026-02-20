// Combat mode defines
#define COMBAT_MODE_MELEE 1   // Pure melee, always rush in
#define COMBAT_MODE_RANGED 2  // Pure ranged, never voluntarily enter melee
#define COMBAT_MODE_MIXED 3   // Ranged but will melee if target gets close (like reaver)

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
	
	// LOW-LIGHT VISION: Some mobs (mutants, animals, nightkin) see better in darkness
	var/has_low_light_vision = FALSE // Set to TRUE for mutants, animals, nightkin, deathclaws, etc.
	var/low_light_bonus = 3 // Extra tiles of vision in darkness when has_low_light_vision is TRUE
	var/debug_vision = FALSE // Set to TRUE to see cone detection messages in chat
	
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
	/// SMART SEARCH: Track visited search locations to avoid repetition
	var/list/searched_turfs = list()
	/// SMART SEARCH: Current search expansion level (increases over time)
	var/search_expansion = 0
	/// SMART SEARCH: Doors we've already tried to open during search
	var/list/searched_doors = list()
	/// SMART SEARCH: Containers (closets/crates/lockers) we've searched
	var/list/searched_containers = list()
	/// SMART SEARCH: Recently opened door (to prioritize exploring beyond it)
	var/atom/recently_opened_door = null
	/// SMART SEARCH: Container we're currently moving toward to investigate
	var/obj/structure/closet/investigating_container = null
	/// SMART SEARCH: Timestamp when search started (for timeout)
	var/search_start_time = 0
	/// SMART SEARCH: Base search timeout for non-aggressive mobs (2.5 minutes)
	var/search_timeout_base = 1500 // 150 seconds = 2.5 minutes
	/// SMART SEARCH: Extended search timeout for aggressive mobs (5 minutes)
	var/search_timeout_aggressive = 3000 // 300 seconds = 5 minutes
	/// SMART SEARCH: Last time we exited search mode
	var/last_search_exit_time = 0
	/// SMART SEARCH: Cooldown before re-entering search (prevents spam loop)
	var/search_entry_cooldown = 10 // 1 second

	/// How far to call for backup when finding a target (tiles)
	var/backup_call_range = 2
	/// Cooldown between backup calls to prevent spam
	COOLDOWN_DECLARE(backup_call_cooldown)
	/// How long between backup calls (deciseconds)
	var/backup_call_delay = 50 // 5 seconds

	/// Are we currently rallying to allies?
	var/rallying = FALSE
	/// When did we start rallying?
	var/rally_start_time = 0
	/// How long to rally before advancing (deciseconds) - 3 seconds
	var/rally_duration = 30
	/// Rally point location
	var/turf/rally_point = null

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

	/// CURIOSITY SYSTEM: Idle mobs occasionally investigate nearby closed doors/rooms
	var/curiosity_enabled = TRUE
	/// When did we last investigate out of curiosity?
	var/last_curiosity_check = 0
	/// How often to consider investigating (deciseconds) - 10-20 seconds
	var/curiosity_check_interval = 100
	/// Chance to actually investigate when checking (0-100)
	var/curiosity_chance = 35

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
	/// Range we can hear impact sounds (tiles) - same as gunfire (impacts ARE from gunfire)
	var/impact_hearing_range = 7  // Increased to 7 tiles to match combat sounds

	// LIGHT DETECTION SYSTEM - Mobs notice player light sources in darkness
	/// Can this mob detect light sources?
	var/can_detect_light = TRUE
	/// How far can we detect light sources? (tiles)
	var/light_detection_range = 9
	/// Minimum light_range value to be detected (flashlights are ~3-4, torches ~3)
	var/light_detection_threshold = 2
	/// Last time we detected a light source
	var/last_light_detected = 0
	/// Cooldown between light detections (deciseconds) - prevents spam
	var/light_detection_cooldown = 50 // 5 seconds
	/// Memory of last detected light location
	var/turf/last_light_location = null
	/// Should we only detect lights in dark areas? (TRUE = ignore lights in well-lit rooms)
	var/only_detect_lights_in_darkness = TRUE
	/// Minimum darkness level required to detect lights (0-1, lower = darker)
	var/darkness_threshold = 0.5

	/// SPATIAL AWARENESS & DOOR MEMORY
	/// List of door locations we know about and can potentially use
	var/list/known_doors = list()
	/// Last position we were at
	var/turf/last_position = null
	/// How long have we been stuck in the same position?
	var/stuck_time = 0
	/// Position where we got stuck
	var/turf/stuck_position = null
	/// How long to wait before considering ourselves stuck (deciseconds) - 10 seconds
	var/stuck_timeout = 100
	/// Faster timeout for corner situations where we can see target (deciseconds) - 3 seconds
	var/corner_stuck_timeout = 30
	/// How long to wait before smashing (deciseconds) - 15 seconds (stuck_timeout + smash_delay)
	var/smash_delay = 150

	/// DOOR KITING PREVENTION: Track TARGET's door passages to detect exploit
	/// Last door the target passed through
	var/atom/target_last_door = null
	/// How many times has target passed through this door recently?
	var/target_door_pass_count = 0
	/// Last time target passed through a door
	var/target_last_door_pass_time = 0
	/// Have we committed to one side due to target kiting?
	var/committed_to_door_side = FALSE
	/// Which side of the door are we committed to?
	var/turf/committed_door_location = null
	/// Last known position of target (for tracking movement)
	var/turf/target_last_position = null
	
	/// CORNER KITING PREVENTION: Track target peeking around corners
	/// How many times has target peeked from same area?
	var/corner_peek_count = 0
	/// Last time target peeked
	var/last_corner_peek_time = 0
	/// Location where target keeps peeking from
	var/turf/corner_peek_location = null
	/// Have we committed to rushing a corner?
	var/committed_to_corner = FALSE
	
	/// LIGHT PATROL SYSTEM: Idle mobs patrol to nearby doors when players are nearby
	/// Are we on light patrol?
	var/light_patrolling = FALSE
	/// Where did we start the patrol from?
	var/turf/patrol_home = null
	/// Which door are we patrolling to?
	var/atom/patrol_target_door = null
	/// How many times have we visited each door?
	var/list/patrol_door_visits = list()
	/// Maximum visits before resting at home
	var/patrol_max_visits = 2
	/// Are we resting after patrol?
	var/patrol_resting = FALSE
	/// When did we start resting?
	var/patrol_rest_start = 0
	/// How long to rest before patrolling again (30 seconds)
	var/patrol_rest_duration = 300
	/// Timer for patrol checks
	var/patrol_check_timer = null
	
	/// THROWN ITEM DETECTION: Track thrown items and investigate spammers
	/// Track recent thrown items and their sources
	var/list/recent_thrown_items = list()
	/// When did we last clear the thrown item list?
	var/last_thrown_clear = 0
	/// How many thrown items before we investigate the source?
	var/thrown_spam_threshold = 3
	/// Cooldown for investigating thrown items (deciseconds)
	var/thrown_investigation_cooldown = 150 // 15 seconds
	
	/// LIGHT DESTRUCTION DETECTION: Track shot-out lights and investigate
	/// Track recent light destructions and their sources
	var/list/recent_light_shots = list()
	/// When did we last clear the light shot list?
	var/last_light_shot_clear = 0
	/// How many lights shot before we investigate the shooter?
	var/light_spam_threshold = 3
	
	/// Last time we smashed something (prevents spam)
	var/last_smash_time = 0
	/// Cooldown between smash attempts (deciseconds) - 5 seconds
	var/smash_cooldown = 50
	/// Are we currently stuck and trying alternate routes?
	var/is_stuck = FALSE
	/// How many alternate path attempts have we made?
	var/path_attempts = 0
	/// Maximum path attempts before smashing
	var/max_path_attempts = 3
	/// Last time we gave up chasing target due to being stuck
	var/last_give_up_time = 0
	/// Cooldown after giving up before we can re-acquire targets (deciseconds) - 15 seconds
	var/give_up_cooldown = 150

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

	/// What's our primary combat style?
	var/combat_mode = COMBAT_MODE_MELEE // COMBAT_MODE_MELEE, COMBAT_MODE_RANGED, or COMBAT_MODE_MIXED

	/// CHAIN REACTION ALERTING - tracks if this mob is the "alpha" that woke up others
	var/is_alpha_alerter = FALSE
	/// Range for chain reaction LOS alerting (tiles)
	var/chain_alert_range = 3
	/// Cooldown for chain alerting to prevent spam
	COOLDOWN_DECLARE(chain_alert_cooldown)
	/// How long between chain alerts (deciseconds)
	var/chain_alert_delay = 30 // 3 seconds

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
	
	// Clear smart search memory
	if(searched_turfs)
		searched_turfs.Cut()
	searched_turfs = null
	
	if(searched_doors)
		searched_doors.Cut()
	searched_doors = null
	
	search_expansion = 0
	
	// Clear stuck state and door memory
	known_doors = null
	last_position = null
	stuck_position = null
	is_stuck = FALSE
	
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
	
	// Safety check: ensure possible_targets is a proper list, not nested
	if(!possible_targets)
		possible_targets = list()
	else if(!islist(possible_targets))
		possible_targets = list(possible_targets)
	else if(islist(possible_targets))
		// Check for nested lists and flatten them
		var/has_nested = FALSE
		for(var/item in possible_targets)
			if(islist(item))
				has_nested = TRUE
				break
		
		if(has_nested)
			var/list/flattened = list()
			var/original_len = possible_targets.len
			for(var/entry in possible_targets)
				if(islist(entry))
					for(var/subitem in entry)
						flattened += subitem
				else
					flattened += entry
			possible_targets = flattened
			
			// Debug logging to track down the source
			log_runtime("HOSTILE MOB: [src] ([type]) had nested list from ListTargets() at [get_turf(src)]. Original list: [original_len] entries, flattened to [flattened.len] entries.")

	// IMMEDIATE TARGET RESPONSE: Fast acquisition for both search mode and initial detection
	// When idle or searching, quickly grab first valid target without waiting for next cycle
	if((searching || AIStatus == AI_IDLE) && possible_targets && possible_targets.len > 0)
		for(var/atom/possible_target in possible_targets)
			// Dead/ghost check
			if(isliving(possible_target))
				var/mob/living/L = possible_target
				if(L.stat == DEAD || L.ckey && !L.client)
					continue
			
			// CORE FIX: Check distance FIRST using effective range
			var/effective_range = get_effective_vision_range(possible_target)
			var/actual_distance = get_dist(src, possible_target)
			
			if(actual_distance > effective_range)
				continue // Too far in darkness
			
			// Now check line of sight
			if(!can_see(src, possible_target, effective_range))
				continue
			
			// Faction check
			if(!CanAttack(possible_target))
				continue
			
			// All checks passed - acquire target
			if(AIStatus == AI_IDLE)
				toggle_ai(AI_ON)
			
			if(searching)
				exit_search_mode(FALSE, found_target = TRUE)
			
			last_target_sighting = world.time
			remembered_target = possible_target
			GiveTarget(possible_target)
			call_for_backup(possible_target, "found")
			break

	// LIGHT DETECTION: Periodically check for light sources in darkness
	// Has its own cooldown to avoid spam
	if(!target || searching)
		detect_light_source()

	// POSITION TRACKING
	var/turf/current_pos = get_turf(src)
	if(target && current_pos)
		if(last_position == current_pos)
			if(!stuck_position)
				stuck_position = current_pos
				stuck_time = world.time
			else
				var/stuck_duration = world.time - stuck_time
				var/target_dist = get_dist(src, target)
				var/can_see_target = can_see(src, target, get_effective_vision_range(target))
				if(can_see_target && target_dist >= 2 && target_dist <= 10)
					if(stuck_duration > corner_stuck_timeout && !is_stuck)
						is_stuck = TRUE
						path_attempts = 0
						visible_message(span_notice("[src] changes approach..."))
				else if(stuck_duration > stuck_timeout)
					if(!is_stuck)
						is_stuck = TRUE
						path_attempts = 0
		else
			if(is_stuck || stuck_position)
				is_stuck = FALSE
				stuck_position = null
				stuck_time = 0
				path_attempts = 0
	else
		is_stuck = FALSE
		stuck_position = null
		stuck_time = 0
		path_attempts = 0

	last_position = current_pos

	if(can_open_doors && prob(10))
		scan_for_doors()

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
				Goto(pick(escape_turfs), move_to_delay, 0)
	else
		time_on_stairs = 0

	if(can_open_doors && target)
		var/turf/T = get_step(src, get_dir(src, target))
		if(T)
			for(var/obj/structure/simple_door/SD in T)
				if(SD.density)
					try_open_door(SD)
			for(var/obj/machinery/door/D in T)
				if(D.density)
					try_open_door(D)

	if(environment_smash)
		EscapeConfinement()

	// CURIOSITY SYSTEM: Idle mobs occasionally investigate nearby doors/rooms
	if(AIStatus == AI_IDLE && curiosity_enabled && can_open_doors && !target && !searching)
		if((world.time - last_curiosity_check) > curiosity_check_interval)
			last_curiosity_check = world.time
			if(prob(curiosity_chance))
				// PERFORMANCE: Use direct object range() instead of turf iteration
				// Limit to range 3 instead of vision_range (9) to reduce lag
				var/list/nearby_doors = list()
				for(var/obj/structure/simple_door/SD in range(3, src))
					if(SD.density)
						nearby_doors += SD
				for(var/obj/machinery/door/D in range(3, src))
					if(D.density)
						nearby_doors += D
				
				if(nearby_doors.len > 0)
					// Prefer doors closer to us
					var/atom/door_to_check = null
					var/closest_dist = 999
					for(var/atom/door in nearby_doors)
						var/dist = get_dist(src, door)
						if(dist < closest_dist && prob(70)) // 70% chance to keep closer one
							closest_dist = dist
							door_to_check = door
					
					if(!door_to_check)
						door_to_check = pick(nearby_doors)
					
					visible_message(span_notice("[src] investigates a nearby door..."))
					Goto(door_to_check, move_to_delay, 0)
					// Try to open it when we get adjacent
					addtimer(CALLBACK(src, PROC_REF(curiosity_check_door), door_to_check), 3 SECONDS, TIMER_DELETE_ME)
	
	// LIGHT PATROL SYSTEM: Check for nearby players and patrol
	if(AIStatus == AI_IDLE && !target && !searching && !light_patrolling)
		// Check every 5 seconds (50 deciseconds)
		if(!patrol_check_timer || (world.time - patrol_check_timer) > 50)
			patrol_check_timer = world.time
			check_light_patrol()

	if(AICanContinue(possible_targets))
		if(!QDELETED(target) && !targets_from.Adjacent(target))
			if(is_stuck && (world.time - stuck_time > smash_delay))
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
		
		// CHAIN REACTION: This mob just woke up, alert nearby allies
		trigger_chain_alert(user)
	return ..()

/mob/living/simple_animal/hostile/bullet_act(obj/item/projectile/P)
	// ALERT NEARBY ALLIES ABOUT COMBAT - alert at multiple locations
	if(P.firer)
		// Alert from shooter location (full range, muffled by walls)
		alert_allies_of_combat(get_turf(P.firer), P.firer)
		
		// Alert from impact location (smaller radius, also muffled)
		// This represents the sound of bullet hitting wall/target/mob
		var/turf/impact_loc = get_turf(src)
		if(impact_loc)
			// Use a smaller range for impact sounds
			alert_allies_of_impact(impact_loc, P.firer, impact_hearing_range)
	
	. = ..()
	if (peaceful == TRUE)
		peaceful = FALSE
	
	// IMPROVED RETARGETING: Switch targets if being shot by someone closer or while searching
	if(stat == CONSCIOUS && AIStatus != AI_OFF && !client && P.firer)
		if(get_dist(src, P.firer) <= aggro_vision_range)
			var/should_retarget = FALSE
			
			if(!target)
				// No target, always acquire the shooter
				should_retarget = TRUE
			else
				var/current_target_dist = get_dist(src, target)
				var/shooter_dist = get_dist(src, P.firer)
				
				// Retarget if: shooter is much closer, OR we're searching (lost current target)
				if(shooter_dist < (current_target_dist - 3) || searching)
					should_retarget = TRUE
			
			if(should_retarget)
				if(searching)
					exit_search_mode(found_target = TRUE) // Found shooter
				FindTarget(list(P.firer), 1)
				COOLDOWN_RESET(src, sight_shoot_delay)
				trigger_chain_alert(P.firer)
				visible_message(span_danger("[src] turns its attention to [P.firer]!"))
				return
				
		if(!target) // Only run to projectile source if we have no target after all checks
			Goto(P.starting, move_to_delay, 3)

// GLOBAL HELPER: Alert all hostile mobs about a projectile impact at a location
// This should be called from turf/obj bullet_act implementations or projectile on_range
/proc/alert_hostile_mobs_of_impact(turf/impact_location, atom/firer, impact_range = 5)
	if(!impact_location || !firer)
		return
	
	for(var/mob/living/simple_animal/hostile/M in range(7, impact_location))
		if(M.stat == DEAD || M.ckey || !M.can_hear_combat)
			continue
		
		// Only alert mobs actively engaged (has target or searching)
		if(!M.target && !M.searching)
			continue
		
		// Check muffled range
		var/effective_range = M.calculate_muffled_sound_range(impact_location, impact_range)
		var/distance = get_dist(M, impact_location)
		var/z_distance = abs(M.z - impact_location.z)
		
		if(distance <= effective_range && z_distance <= 1)
			M.hear_impact_sound(impact_location, firer)

// CHAIN REACTION ALERTING
// When a mob wakes up, it alerts all allies within LOS (vision range)
// Those allies then check for the original target and also wake up
// This creates a cascading alert system
/mob/living/simple_animal/hostile/proc/trigger_chain_alert(atom/threat)
	if(!threat)
		return

	// BUG 2 FIX: Only alpha mobs broadcast chain alerts
	if(!is_alpha_alerter)
		return

	if(!COOLDOWN_FINISHED(src, chain_alert_cooldown))
		return

	COOLDOWN_START(src, chain_alert_cooldown, chain_alert_delay)

	visible_message(span_danger("[src] alerts nearby allies!"))

	var/list/alerted_allies = list()

	for(var/mob/living/simple_animal/hostile/M in range(chain_alert_range, src))
		if(M == src || M.stat == DEAD || M.ckey)
			continue
		if(!faction_check_mob(M, TRUE))
			continue
		if(can_see(src, M, chain_alert_range))
			alerted_allies += M

	var/turf/above_us = get_step_multiz(get_turf(src), UP)
	if(above_us)
		for(var/mob/living/simple_animal/hostile/M in range(chain_alert_range, above_us))
			if(M == src || M.stat == DEAD || M.ckey)
				continue
			if(!faction_check_mob(M, TRUE))
				continue
			if(can_see(src, M, chain_alert_range))
				alerted_allies += M

	var/turf/below_us = get_step_multiz(get_turf(src), DOWN)
	if(below_us)
		for(var/mob/living/simple_animal/hostile/M in range(chain_alert_range, below_us))
			if(M == src || M.stat == DEAD || M.ckey)
				continue
			if(!faction_check_mob(M, TRUE))
				continue
			if(can_see(src, M, chain_alert_range))
				alerted_allies += M

	for(var/mob/living/simple_animal/hostile/ally in alerted_allies)
		ally.receive_chain_alert(threat, src)

// Receive a chain alert from an ally
/mob/living/simple_animal/hostile/proc/receive_chain_alert(atom/threat, mob/living/simple_animal/hostile/alerter)
	if(!threat || QDELETED(threat))
		return

	if(AIStatus == AI_ON || target)
		return

	// Ghost check
	if(isliving(threat))
		var/mob/living/L = threat
		if(L.stat == DEAD || L.ckey && !L.client)
			return

	visible_message(span_danger("[src] perks up from [alerter]'s alert!"))

	if(can_see(src, threat, get_effective_vision_range(threat)) && CanAttack(threat))
		// Direct confirmation - becomes alpha, can propagate
		if(AIStatus != AI_ON)
			toggle_ai(AI_ON)
		FindTarget(list(threat), 1)
		remembered_target = threat
		last_target_sighting = world.time
		last_known_location = get_turf(threat)
		// GiveTarget (called by FindTarget) sets is_alpha_alerter = TRUE
		// so this mob CAN chain-alert further
		trigger_chain_alert(threat)
	else
		// Can't confirm - search quietly, no further propagation
		is_alpha_alerter = FALSE
		if(AIStatus != AI_ON)
			toggle_ai(AI_ON)
		last_known_location = get_turf(threat)
		enter_search_mode() // is_alpha_alerter=FALSE → no broadcast


// SOUND MUFFLING THROUGH WALLS
// Calculates effective hearing range by counting walls between source and listener
// Each wall reduces range by 1 tile
/mob/living/simple_animal/hostile/proc/calculate_muffled_sound_range(turf/sound_source, base_range)
	if(!sound_source)
		return 0
	
	var/turf/our_turf = get_turf(src)
	if(!our_turf)
		return 0
	
	// Get line between source and us
	var/list/line = getline(sound_source, our_turf)
	
	// Count walls
	var/wall_count = 0
	for(var/turf/T in line)
		if(iswallturf(T))
			wall_count++
	
	// Each wall reduces range by 1
	var/effective_range = base_range - wall_count
	
	// Can't go below 0
	return max(effective_range, 0)

// Updated alert_allies_of_combat with sound muffling
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
			// Check muffled range
			var/effective_range = M.calculate_muffled_sound_range(combat_location, combat_hearing_range)
			var/actual_distance = get_dist(M, combat_location)
			
			if(actual_distance <= effective_range)
				allies_in_range += M
	
	// Z above
	var/turf/above = get_step_multiz(combat_location, UP)
	if(above)
		for(var/mob/living/simple_animal/hostile/M in range(combat_hearing_range, above))
			if(M == src || M.stat == DEAD || M.ckey)
				continue
			if(faction_check_mob(M, TRUE))
				// Check muffled range (Z-distance adds 1 wall equivalent)
				var/effective_range = M.calculate_muffled_sound_range(combat_location, combat_hearing_range) - 1
				var/actual_distance = get_dist(M, above)
				
				if(actual_distance <= effective_range)
					allies_in_range += M
	
	// Z below
	var/turf/below = get_step_multiz(combat_location, DOWN)
	if(below)
		for(var/mob/living/simple_animal/hostile/M in range(combat_hearing_range, below))
			if(M == src || M.stat == DEAD || M.ckey)
				continue
			if(faction_check_mob(M, TRUE))
				// Check muffled range (Z-distance adds 1 wall equivalent)
				var/effective_range = M.calculate_muffled_sound_range(combat_location, combat_hearing_range) - 1
				var/actual_distance = get_dist(M, below)
				
				if(actual_distance <= effective_range)
					allies_in_range += M
	
	// Alert all allies
	for(var/mob/living/simple_animal/hostile/ally in allies_in_range)
		ally.hear_combat_sound(combat_location, attacker)

// Alert allies about impact sounds (bullet hitting wall/target)
// Smaller radius than gunfire, but still muffled by walls
/mob/living/simple_animal/hostile/proc/alert_allies_of_impact(turf/impact_location, atom/attacker, impact_range = 5)
	if(!impact_location)
		return
	
	var/notified = 0
	var/max_notifications = 10 // CPU OPTIMIZATION: Limit notifications per impact
	
	// CPU OPTIMIZATION: Reduced range from 20 to 5 tiles, ALL hostile mobs (not just faction)
	// Impacts are universal - everyone hears bullets hitting things nearby
	for(var/mob/living/simple_animal/hostile/M in range(5, impact_location))
		if(M.stat == DEAD || M.ckey || !M.can_hear_combat)
			continue
		
		// Check muffled range
		var/effective_range = M.calculate_muffled_sound_range(impact_location, impact_range)
		var/actual_distance = get_dist(M, impact_location)
		
		if(actual_distance <= effective_range)
			M.hear_impact_sound(impact_location, attacker)
			notified++
			if(notified >= max_notifications) // Early exit optimization
				return

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

/// Determine which vision cone the target is in relative to mob's facing direction
/// Returns CONE_FRONT, CONE_PERIPHERAL, or CONE_REAR
/mob/living/simple_animal/hostile/proc/get_vision_cone(atom/target)
	if(!target)
		return CONE_REAR
	
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!my_turf || !target_turf)
		return CONE_REAR
	
	// Same tile = front cone
	if(my_turf == target_turf)
		return CONE_FRONT
	
	// Calculate relative position
	var/dx = target_turf.x - my_turf.x
	var/dy = target_turf.y - my_turf.y
	
	// If no direction set, face the target
	if(!dir || dir == 0)
		setDir(get_dir(src, target))
		return CONE_FRONT
	
	// ============================================
	// QUADRANT-BASED DETECTION (matches visual sectors exactly)
	// ============================================
	// Uses IDENTICAL quadrant logic as get_sector_turfs() for perfect 1:1 match
	//
	// Sector layout:
	// FRONT (RED): -30° to +30° → CONE_FRONT
	// RIGHT PERIPHERAL (YELLOW): 30° to 90° → CONE_PERIPHERAL
	// RIGHT REAR (CYAN): 90° to 150° → CONE_REAR
	// REAR (GRAY): 150° to 210° → CONE_REAR
	// LEFT REAR (CYAN): 210° to 270° → CONE_REAR
	// LEFT PERIPHERAL (YELLOW): 270° to 330° → CONE_PERIPHERAL
	// ============================================
	
	// Get base direction angle
	var/base_angle = dir_to_angle_detection(dir)
	
	// Calculate angle to target using SAME quadrant logic as visuals
	var/target_angle = calculate_angle_from_offset_detection(dx, dy)
	
	// Calculate relative angle from facing direction
	var/relative_angle = target_angle - base_angle
	
	// Normalize to -180 to +180 range
	while(relative_angle > 180)
		relative_angle -= 360
	while(relative_angle < -180)
		relative_angle += 360
	
	// Classify based on angle (matching visual sectors EXACTLY)
	if(relative_angle >= -30 && relative_angle <= 30)
		// Front center: -30° to +30° (60° total)
		return CONE_FRONT
	else if((relative_angle > 30 && relative_angle <= 90) || (relative_angle >= -90 && relative_angle < -30))
		// Peripheral zones: 30° to 90° and -90° to -30° (270° to 330°)
		return CONE_PERIPHERAL
	else
		// Rear zones: 90° to 270° (includes cyan rear peripheral and gray rear center)
		return CONE_REAR

/// Get directional vision multiplier (DISABLED FOR TESTING)
/// Returns 1.0 to disable directional vision while testing lighting
/mob/living/simple_animal/hostile/proc/get_directional_vision_multiplier(atom/target)
	// DISABLED: Just return full range for lighting-only testing
	return 1.0

/// Check if target is within the mob's field of view (direction-based)
/// Returns TRUE if target is in front half (180-degree cone) of mob's facing direction
/// Legacy compatibility wrapper for the multiplier system
/mob/living/simple_animal/hostile/proc/in_field_of_view(atom/target)
	if(!target)
		return FALSE
	
	var/multiplier = get_directional_vision_multiplier(target)
	return (multiplier >= 0.5) // TRUE if in front or side, FALSE if behind

/// Calculate effective vision range based on lighting AND directional cone
/// Front cone: Better dark vision (5 tiles in darkness vs 3 in peripheral, 0 in rear)
/mob/living/simple_animal/hostile/proc/get_effective_vision_range(atom/target)
	if(!target)
		return vision_range
	
	// Determine which cone target is in
	var/cone_type = get_vision_cone(target)
	
	// No vision behind us ever
	if(cone_type == CONE_REAR)
		return 0
	
	// Check if target has a light source
	var/has_light = FALSE
	if(isliving(target))
		var/mob/living/L = target
		if(L.light_range > 0)
			has_light = TRUE
	
	// If they have a light, they're visible at full range
	if(has_light)
		// Apply cone multiplier
		if(cone_type == CONE_FRONT)
			return vision_range
		else // CONE_PERIPHERAL
			return max(round(vision_range * 0.6), 2)
	
	// Check ambient lighting at target location
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return 2
	
	var/light_amount = target_turf.get_lumcount()
	var/base_range = vision_range
	
	// Lighting-based range calculation (same for all cones)
	if(light_amount >= 0.5)
		base_range = vision_range // Bright: full range
	else if(light_amount >= 0.2)
		base_range = max(round(vision_range * 0.6), 3) // Dim: 60% range
	else
		// Darkness: reduced to 40% range
		base_range = max(round(vision_range * 0.4), 3)
	
	// STEALTH BOY CHECK: Drastically reduce detection range for cloaked targets
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.alpha < 100) // Heavily cloaked by stealth boy
			// Reduce detection range to 20% - they need to be VERY close
			base_range = max(round(base_range * 0.2), 1)
	
	// Apply cone multipliers
	if(cone_type == CONE_FRONT)
		return base_range // Full range in front cone
	else // CONE_PERIPHERAL
		return max(round(base_range * 0.6), 2) // 60% of lighting range in peripheral

/// LOW-LIGHT VISION: Modified version that adds low-light vision bonus for mutants/animals
/mob/living/simple_animal/hostile/proc/get_effective_vision_range_lowlight(atom/target)
	var/base_range = get_effective_vision_range(target)
	
	if(!has_low_light_vision)
		return base_range
	
	// Check if it's actually dark
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return base_range
	
	var/light_amount = target_turf.get_lumcount()
	
	// Only apply low-light bonus in darkness
	if(light_amount < 0.2)
		// Add bonus to dark vision
		return base_range + low_light_bonus
	
	return base_range

/// Determine which sound cone the target is in (for rear detection)
/mob/living/simple_animal/hostile/proc/get_sound_cone(atom/target)
	if(!target)
		return null
	
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!my_turf || !target_turf)
		return null
	
	var/dx = target_turf.x - my_turf.x
	var/dy = target_turf.y - my_turf.y
	
	// ============================================
	// QUADRANT-BASED SOUND DETECTION (matches visual sectors exactly)
	// ============================================
	// Sound detection only works in REAR zones (90° to 270° from facing)
	//
	// REAR CENTER (GRAY): 150° to 210° → SOUND_REAR_CENTER (harder to hear)
	// REAR PERIPHERAL (CYAN): 90° to 150° and 210° to 270° → SOUND_REAR_PERIPHERAL (easier to hear)
	// ============================================
	
	// Get base direction angle
	var/base_angle = dir_to_angle_detection(dir)
	
	// Calculate angle to target using SAME quadrant logic
	var/target_angle = calculate_angle_from_offset_detection(dx, dy)
	
	// Calculate relative angle
	var/relative_angle = target_angle - base_angle
	
	// Normalize to -180 to +180
	while(relative_angle > 180)
		relative_angle -= 360
	while(relative_angle < -180)
		relative_angle += 360
	
	// Check if target is in rear zones
	if(relative_angle >= -90 && relative_angle <= 90)
		return null // Front zones - no sound detection
	
	// Target is behind - determine if center or peripheral
	// Rear center: 150° to 210° (±30° from opposite = relative ±30° from 180°)
	// Which is: relative >= 150 OR relative <= -150
	var/abs_rel = abs(relative_angle)
	if(abs_rel >= 150)
		return SOUND_REAR_CENTER // Directly behind (harder to hear)
	else
		return SOUND_REAR_PERIPHERAL // Rear diagonal (easier to hear)

// Helper functions for detection (identical to visual logic)
/mob/living/simple_animal/hostile/proc/dir_to_angle_detection(byond_dir)
	switch(byond_dir)
		if(NORTH)
			return 0
		if(NORTHEAST)
			return 45
		if(EAST)
			return 90
		if(SOUTHEAST)
			return 135
		if(SOUTH)
			return 180
		if(SOUTHWEST)
			return 225
		if(WEST)
			return 270
		if(NORTHWEST)
			return 315
	return 0

/mob/living/simple_animal/hostile/proc/calculate_angle_from_offset_detection(dx, dy)
	var/angle = 0
	
	// Cardinals (avoids arctan edge cases)
	if(dx == 0)
		if(dy > 0)
			return 0 // NORTH
		else
			return 180 // SOUTH
	else if(dy == 0)
		if(dx > 0)
			return 90 // EAST
		else
			return 270 // WEST
	
	// Diagonals - use arctan on absolute values
	var/acute_angle = arctan(abs(dy), abs(dx))
	
	// Map to correct quadrant
	if(dx > 0 && dy > 0)
		angle = acute_angle // NE
	else if(dx < 0 && dy > 0)
		angle = 360 - acute_angle // NW
	else if(dx > 0 && dy < 0)
		angle = 180 - acute_angle // SE
	else // dx < 0 && dy < 0
		angle = 180 + acute_angle // SW
	
	// Normalize
	while(angle < 0)
		angle += 360
	while(angle >= 360)
		angle -= 360
	
	return angle

/// Detect moving targets behind us via sound
/mob/living/simple_animal/hostile/proc/detect_rear_movement(atom/target)
	if(!target)
		return 0
	
	if(!isliving(target))
		return 0
	
	var/mob/living/L = target
	
	// FIX 1: Check if they're BEHIND us first
	var/sound_cone = get_sound_cone(target)
	if(!sound_cone)
		return 0 // Not behind us - no sound detection
	
	// FIX 2: Check for recent movement
	// Must have moved within last 2 seconds (20 deciseconds)
	// This catches continuous walking/running between actual movement ticks
	if(!L.last_move_time)
		return 0 // Never moved
	
	var/time_since_move = world.time - L.last_move_time
	
	// 2 second window catches ongoing movement
	if(time_since_move > 20)
		return 0 // Stopped moving - no sound
	
	// Get their movement sound level
	var/sound_level = 1.0 // Default for non-humans
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		sound_level = H.get_movement_sound_level()
	
	// Calculate detection range based on zone
	// REAR CENTER: Directly behind - sound travels straight, easier to hear
	// REAR PERIPHERAL: Diagonal/side angles - slightly muffled by head position
	var/detection_range = 0
	
	if(sound_cone == SOUND_REAR_CENTER)
		detection_range = round(sound_level * 3) // Directly behind - sound travels clearly
	else // SOUND_REAR_PERIPHERAL
		detection_range = round(sound_level * 2.5) // Diagonal - slightly muffled
	
	return detection_range

/mob/living/simple_animal/hostile/proc/ListTargets()//Step 1, find out what we can see
	if(!search_objects)
		// CORE FIX: Filter by effective range BEFORE adding to list
		. = list()
		
		// Get all potential targets in max vision range
		var/list/potential_targets = hearers(vision_range, targets_from) - src
		
		for(var/atom/A in potential_targets)
			// Skip non-attackable things early
			if(!isliving(A) && !ismecha(A) && !istype(A, /obj/machinery/porta_turret))
				continue
			
			// VISION-BASED DETECTION
			var/effective_range = get_effective_vision_range(A)
			
			// Apply low-light vision bonus if applicable
			if(has_low_light_vision)
				effective_range = get_effective_vision_range_lowlight(A)
			
			var/actual_distance = get_dist(src, A)
			
			// Check if within visual range
			if(actual_distance <= effective_range)
				. += A
				if(debug_vision && isliving(A))
					var/mob/living/L = A
					var/cone = get_vision_cone(L)
					var/cone_name = "UNKNOWN"
					switch(cone)
						if(CONE_FRONT)
							cone_name = "FRONT (90°)"
						if(CONE_PERIPHERAL)
							cone_name = "PERIPHERAL (45°)"
						if(CONE_REAR)
							cone_name = "REAR (blind)"
					to_chat(L, span_notice("[src] detected you via VISION in [cone_name] cone at [actual_distance] tiles (max: [effective_range])"))
				continue
			
			// SOUND-BASED DETECTION (for targets behind us)
			var/sound_range = detect_rear_movement(A)
			if(sound_range > 0 && actual_distance <= sound_range)
				// Heard movement! Turn to face the sound source
				var/face_dir = get_dir(src, A)
				if(face_dir && face_dir != dir)
					setDir(face_dir)
				
				// Check line-of-sight AND if they're within stealth-adjusted range
				// Note: effective_range is already calculated above with stealth penalty
				var/can_actually_see = can_see(src, A, effective_range) && (actual_distance <= effective_range)
				
				if(!can_actually_see)
					// Heard something, turned to check, but can't see it - enter search mode
					if(!searching && !target)
						last_known_location = get_turf(A)
						remembered_target = A
						last_target_sighting = world.time
					
					// Wake up and enter search mode immediately
					if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
						toggle_ai(AI_ON)
					enter_search_mode()
					
					if(debug_vision && isliving(A))
						var/mob/living/L = A
						to_chat(L, span_warning("[src] heard you but can't see you (stealth: [effective_range] tiles) - searching!"))
						var/sound_cone = get_sound_cone(L)
						var/cone_name = "UNKNOWN"
						switch(sound_cone)
							if(SOUND_REAR_CENTER)
								cone_name = "REAR CENTER (90°)"
							if(SOUND_REAR_PERIPHERAL)
								cone_name = "REAR PERIPHERAL (45°)"
						to_chat(L, span_warning("[src] detected you via SOUND in [cone_name] cone at [actual_distance] tiles (max: [sound_range])"))
					continue
				
				// Successfully detected via sound - add as target
				. += A
				if(debug_vision && isliving(A))
					var/mob/living/L = A
					var/sound_cone = get_sound_cone(L)
					var/cone_name = "UNKNOWN"
					switch(sound_cone)
						if(SOUND_REAR_CENTER)
							cone_name = "REAR CENTER (90°)"
						if(SOUND_REAR_PERIPHERAL)
							cone_name = "REAR PERIPHERAL (45°)"
					to_chat(L, span_notice("[src] detected you via SOUND in [cone_name] cone at [actual_distance] tiles (max: [sound_range])"))
		
		// Check for targets one Z-level ABOVE through openspace
		var/turf/our_turf = get_turf(targets_from)
		var/turf/above_us = get_step_multiz(our_turf, UP)
		if(above_us && istype(above_us, /turf/open/transparent/openspace))
			for(var/mob/living/M in range(vision_range, above_us))
				var/turf/their_turf = get_turf(M)
				if(istype(their_turf, /turf/open/transparent/openspace))
					var/effective_range = get_effective_vision_range(M)
					if(has_low_light_vision)
						effective_range = get_effective_vision_range_lowlight(M)
					var/actual_distance = get_dist(src, M)
					if(actual_distance <= effective_range)
						. += M
		
		// Check for targets one Z-level BELOW through openspace
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
						var/effective_range = get_effective_vision_range(M)
						if(has_low_light_vision)
							effective_range = get_effective_vision_range_lowlight(M)
						var/actual_distance = get_dist(src, M)
						if(actual_distance <= effective_range)
							. += M
		
		// Add hostile machines that are in effective range
		var/static/hostile_machines = typecacheof(list(/obj/machinery/porta_turret, /obj/mecha, /obj/structure/destructible/clockwork/ocular_warden, /obj/item/electronic_assembly))
		
		for(var/HM in typecache_filter_list(range(vision_range, targets_from), hostile_machines))
			CHECK_TICK
			var/effective_range = get_effective_vision_range(HM)
			var/actual_distance = get_dist(src, HM)
			if(actual_distance <= effective_range && can_see(targets_from, HM, effective_range))
				. += HM
	else
		// Object search mode - also respect effective range
		. = list()
		for(var/obj/A in oview(vision_range, targets_from))
			CHECK_TICK
			var/effective_range = get_effective_vision_range(A)
			var/actual_distance = get_dist(src, A)
			if(actual_distance <= effective_range)
				. += A
		for(var/mob/living/A in oview(vision_range, targets_from))
			CHECK_TICK
			var/effective_range = get_effective_vision_range(A)
			var/actual_distance = get_dist(src, A)
			if(actual_distance <= effective_range)
				. += A

/mob/living/simple_animal/hostile/proc/FindTarget(list/possible_targets, HasTargetsList = 0)
	. = list()

	if(peaceful == FALSE)
		if(!HasTargetsList)
			possible_targets = ListTargets()

		// SEARCH MODE: If searching and target reappears in LOS, re-acquire
		if(searching && target && (target in possible_targets) && can_see(src, target, get_effective_vision_range(target)))
			exit_search_mode(found_target = TRUE)
			last_target_sighting = world.time
			remembered_target = target
			GiveTarget(target)
			COOLDOWN_START(src, sight_shoot_delay, sight_shoot_delay_time)
			call_for_backup(target, "found")
			return target

		// Normal target acquisition loop
		for(var/pos_targ in possible_targets)
			var/atom/A = pos_targ
			if(Found(A))
				. = list(A)
				break
			if(CanAttack(A))
				. += A
				continue

		var/Target = PickTarget(.)
		GiveTarget(Target)
		COOLDOWN_START(src, sight_shoot_delay, sight_shoot_delay_time)

		if(Target)
			remembered_target = Target
			last_target_sighting = world.time
			last_known_location = get_turf(Target)

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

/mob/living/simple_animal/hostile/proc/GiveTarget(new_target)
	add_target(new_target)
	LosePatience()
	if(target != null)
		remembered_target = target
		last_target_sighting = world.time
		is_alpha_alerter = TRUE  // We personally have a confirmed target
		GainPatience()
		Aggro()
		return 1
	else
		is_alpha_alerter = FALSE  // Lost target, no longer primary alerter

//What we do after closing in
/mob/living/simple_animal/hostile/proc/MeleeAction(patience = TRUE)
	// Vision check before attempting melee
	if(target)
		var/effective_range = get_effective_vision_range(target)
		if(effective_range == 0)
			// Target is behind us - lose target
			LoseTarget()
			return
		var/dist = get_dist(src, target)
		if(dist > effective_range)
			// Target is beyond our vision range - lose target
			LoseTarget()
			return
	
	if(rapid_melee > 1)
		var/datum/callback/cb = CALLBACK(src, PROC_REF(CheckAndAttack))
		var/delay = SSnpcpool.wait / rapid_melee
		for(var/i in 1 to rapid_melee)
			addtimer(cb, (i - 1)*delay, TIMER_DELETE_ME)
	else
		AttackingTarget()
	if(patience)
		GainPatience()

/mob/living/simple_animal/hostile/proc/CheckAndAttack()
	if(target && targets_from && isturf(targets_from.loc) && target.Adjacent(targets_from) && !incapacitated())
		// Vision check before rapid melee attack
		var/effective_range = get_effective_vision_range(target)
		if(effective_range == 0)
			return // Can't see target (behind us)
		var/dist = get_dist(src, target)
		if(dist > effective_range)
			return // Target beyond vision range
		AttackingTarget()

/mob/living/simple_animal/hostile/proc/MoveToTarget(list/possible_targets)
	stop_automated_movement = 1
	
	// Safety check: flatten nested lists if somehow we received one
	if(possible_targets && islist(possible_targets))
		for(var/item in possible_targets)
			if(islist(item))
				// We have a nested list - flatten it
				var/list/flattened = list()
				for(var/entry in possible_targets)
					if(islist(entry))
						// Add all items from the nested list
						for(var/subitem in entry)
							flattened += subitem
					else
						flattened += entry
				possible_targets = flattened
				log_runtime("HOSTILE MOB MoveToTarget: [src] ([type]) had nested list at [get_turf(src)]. Flattened to [flattened.len] entries.")
				break

	if(peaceful == TRUE)
		LoseTarget()
		return 0
	
	// DOOR KITING CHECK: Track if target is exploiting door kiting
	if(target)
		check_target_door_kiting()
		
		// If target is kiting and we're committed, stay on our side
		if(committed_to_door_side && committed_door_location)
			var/dist_from_commitment = get_dist(src, committed_door_location)
			
			if(dist_from_commitment > 2)
				// Moved too far from commitment point - return to it
				Goto(committed_door_location, move_to_delay, 0)
				return 1
			else
				// Stay here and wait for target to come to us
				walk(src, 0)
				
				// If target gets far enough away, reset commitment
				if(get_dist(src, target) > 7)
					committed_to_door_side = FALSE
					committed_door_location = null
					target_door_pass_count = 0
					target_last_door = null
				
				return 1
		
		// CORNER KITING CHECK: Track if target is exploiting corner peeks
		check_corner_kiting()
		
		// If target is corner peeking, commit to rushing their position
		if(committed_to_corner && corner_peek_location)
			// Rush toward their last known peek location
			Goto(corner_peek_location, move_to_delay, 0)
			
			// Reset if we reach the corner or target gets far away
			if(get_dist(src, corner_peek_location) <= 1 || (target && get_dist(src, target) > 10))
				committed_to_corner = FALSE
				corner_peek_location = null
				corner_peek_count = 0
			
			return 1

	if(searching)
		if(target && (target in possible_targets) && can_see(src, target, get_effective_vision_range(target)))
			exit_search_mode(found_target = TRUE)
			last_target_sighting = world.time
			call_for_backup(target, "found")
		else
			return 1

	if(rallying)
		if(target && (target in possible_targets) && can_see(src, target, get_effective_vision_range(target)))
			rallying = FALSE
			rally_point = null
		else if((world.time - rally_start_time) > rally_duration)
			advance_after_rally()
		else
			return 1

	if(!target)
		if(remembered_target && !QDELETED(remembered_target) && last_known_location)
			if((world.time - last_target_sighting) < target_memory_duration)
				if(!searching)
					enter_search_mode()
				return 1
		LoseTarget()
		return 0

	if(!CanAttack(target))
		if(remembered_target && (world.time - last_target_sighting) < target_memory_duration)
			if(!searching)
				enter_search_mode()
			return 1
		LoseTarget()
		return 0

	var/has_los = (target in possible_targets) && can_see(src, target, get_effective_vision_range(target))

	if(has_los)
		last_target_sighting = world.time
		remembered_target = target
		last_known_location = get_turf(target)
	else
		var/time_since_seen = world.time - last_target_sighting
		if(time_since_seen > 30)
			if(!searching)
				enter_search_mode()
			var/saved_remembered = remembered_target
			var/saved_location = last_known_location
			var/saved_sighting = last_target_sighting
			GiveTarget(null)
			remembered_target = saved_remembered
			last_known_location = saved_location
			last_target_sighting = saved_sighting
			return 1

	// Z-PURSUIT
	if(pursuing_z_target)
		if(target && target.z == z)
			pursuing_z_target = FALSE
			z_pursuit_structure = null
		else if((world.time - z_pursuit_started) > z_pursuit_timeout)
			pursuing_z_target = FALSE
			z_pursuit_structure = null

	if(pursuing_z_target && z_pursuit_structure && target && target.z != z)
		var/dist = get_dist(src, z_pursuit_structure)
		if(dist <= 1 && istype(z_pursuit_structure, /obj/structure/ladder))
			walk(src, 0)
			step(src, get_dir(src, z_pursuit_structure))
		else
			Goto(z_pursuit_structure, move_to_delay, 0)
		return 1

	// DIFFERENT Z LEVEL
	if(target && target.z != z)
		var/on_stairs = FALSE
		for(var/obj/structure/stairs/S in loc)
			on_stairs = TRUE
			break

		if((world.time - last_successful_z_move) < z_move_success_cooldown)
			if(on_stairs)
				Goto(target, move_to_delay, minimum_distance)
			return 1

		if(!on_stairs)
			if(attempt_z_pursuit())
				return 1

		if(on_stairs)
			Goto(target, move_to_delay, minimum_distance)
			return 1

		LoseTarget()
		return 0

	// DOOR OPENING toward target
	if(can_open_doors && target)
		var/turf/T = get_step(src, get_dir(src, target))
		if(T)
			for(var/obj/structure/simple_door/SD in T)
				if(SD.density)
					try_open_door(SD)
			for(var/obj/machinery/door/D in T)
				if(D.density)
					try_open_door(D)

	if(!Process_Spacemove())
		walk(src, 0)
		return 1

	var/target_distance = get_dist(targets_from, target)

	// TARGET IN LOS - normal combat path
	if(has_los)
		// RANGED ATTACK
		// Allow shooting even when adjacent if we can't maintain proper distance (tight spaces)
		var/can_shoot = FALSE
		if(ranged && ranged_cooldown <= world.time)
			if(!target.Adjacent(targets_from))
				can_shoot = TRUE // Normal case: not adjacent
			else if(retreat_distance != null && target_distance < retreat_distance)
				// We want to retreat but target is adjacent - shoot anyway (cornered)
				can_shoot = TRUE
			else if(target_distance <= 1 && minimum_distance > 0)
				// Target is right on us but we want distance - shoot anyway (tight space)
				can_shoot = TRUE
		
		if(can_shoot)
			var/fired = OpenFire(target)
			if(!fired || is_shot_blocked(target))
				if(retreat_distance != null && abs(target_distance - retreat_distance) <= 2)
					var/turf/better_position = find_firing_position(target)
					if(better_position)
						Move(better_position, get_dir(src, better_position))
						return 1

		// MOVEMENT
		if(retreat_distance != null)
			if(is_stuck && target_distance >= 2)
				if(target_distance > 1)
					Goto(target, move_to_delay, 1)
				else
					is_stuck = FALSE
					stuck_position = null
					stuck_time = 0
					path_attempts = 0
			else if(target_distance < retreat_distance && CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
				set_glide_size(DELAY_TO_GLIDE_SIZE(move_to_delay))
				walk_away(src, target, retreat_distance, move_to_delay)
			else if(target_distance > retreat_distance)
				Goto(target, move_to_delay, retreat_distance)
			else
				walk(src, 0)
		else
			if(target_distance > minimum_distance)
				Goto(target, move_to_delay, minimum_distance)
			else
				walk(src, 0)

		// MELEE ATTACK
		if(COOLDOWN_TIMELEFT(src, melee_cooldown))
			return TRUE

		// Safety check: target might have been cleared during movement/shooting
		if(!target)
			return 0

		var/is_adjacent = targets_from && isturf(targets_from.loc) && target.Adjacent(targets_from) && target.z == z

		if(is_adjacent)
			var/effective_combat_mode = combat_mode ? combat_mode : COMBAT_MODE_MELEE
			var/should_melee = (effective_combat_mode == COMBAT_MODE_MELEE || effective_combat_mode == COMBAT_MODE_MIXED)

			if(should_melee)
				COOLDOWN_START(src, melee_cooldown, melee_attack_cooldown)
				MeleeAction()
		else if(rapid_melee > 1 && target_distance <= melee_queue_distance)
			var/effective_combat_mode = combat_mode ? combat_mode : COMBAT_MODE_MELEE
			if(effective_combat_mode != COMBAT_MODE_RANGED)
				COOLDOWN_START(src, melee_cooldown, melee_attack_cooldown)
				MeleeAction(FALSE)
		else
			in_melee = FALSE

		return 1

	// TARGET NOT IN LOS but we know roughly where they are (within grace period)
	// Move toward last known position - this is the "searching while in combat" path
	// ranged_ignores_vision mobs can still shoot
	if(target && (environment_smash || can_open_doors || ranged_ignores_vision))
		if(target.loc != null && get_dist(targets_from, target.loc) <= vision_range)
			if(ranged_ignores_vision && ranged_cooldown <= world.time)
				OpenFire(target)

			var/target_dist = get_dist(targets_from, target)
			if(target_dist <= 3)
				if((environment_smash & ENVIRONMENT_SMASH_WALLS) || (environment_smash & ENVIRONMENT_SMASH_RWALLS))
					Goto(target, move_to_delay, minimum_distance)
					FindHidden()
					return 1
				else
					if(FindHidden())
						return 1
			
			// If we can open doors and target is nearby but not visible, move toward them
			// Don't immediately give up after firing - pursue through the door
			if(can_open_doors && target_dist <= vision_range)
				Goto(target, move_to_delay, minimum_distance)
				return 1

	LoseTarget()
	return 0

/mob/living/simple_animal/hostile/proc/Goto(target, delay, minimum_distance)
	if(target == src.target)
		approaching_target = TRUE
		// FIX: Turn to face target while pursuing
		var/face_dir = get_dir(src, target)
		if(face_dir && face_dir != dir)
			setDir(face_dir)
	else
		approaching_target = FALSE
	if(CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		set_glide_size(DELAY_TO_GLIDE_SIZE(move_to_delay))
		// Try pathfinding with walk_to - it handles basic pathing
		walk_to(src, target, minimum_distance, delay)
	if(variation_list[MOB_MINIMUM_DISTANCE_CHANCE] && LAZYLEN(variation_list[MOB_MINIMUM_DISTANCE]) && prob(variation_list[MOB_MINIMUM_DISTANCE_CHANCE]))
		minimum_distance = vary_from_list(variation_list[MOB_MINIMUM_DISTANCE])
	if(variation_list[MOB_VARIED_SPEED_CHANCE] && LAZYLEN(variation_list[MOB_VARIED_SPEED]) && prob(variation_list[MOB_VARIED_SPEED_CHANCE]))
		move_to_delay = vary_from_list(variation_list[MOB_VARIED_SPEED])

/mob/living/simple_animal/hostile/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(!ckey && !stat && search_objects < 3 && . > 0)
		if(searching)
			exit_search_mode(FALSE, found_target = TRUE)
			visible_message(span_danger("[src] snaps to attention!"))
			var/list/possible_targets = ListTargets()
			var/new_target = null
			// FIXED: Only acquire target we can actually see
			for(var/atom/T in possible_targets)
				if(can_see(src, T, get_effective_vision_range(T)) && CanAttack(T))
					new_target = T
					break
			if(new_target)
				GiveTarget(new_target)
				remembered_target = new_target
				last_target_sighting = world.time
				last_known_location = get_turf(new_target)
			else
				// Was hurt but can't see attacker - keep searching, update memory
				remembered_target = remembered_target // unchanged
				// search_for_target() will keep running

		else if(rallying)
			rallying = FALSE
			rally_point = null
			visible_message(span_danger("[src] cancels retreat and fights back!"))
			var/list/possible_targets = ListTargets()
			var/new_target = null
			// FIXED: LOS check here too
			for(var/atom/T in possible_targets)
				if(can_see(src, T, get_effective_vision_range(T)) && CanAttack(T))
					new_target = T
					break
			if(new_target)
				GiveTarget(new_target)
				remembered_target = new_target
				last_target_sighting = world.time
				last_known_location = get_turf(new_target)
			else
				FindTarget()

		else if(search_objects)
			LoseTarget()
			LoseSearchObjects()

		if(AIStatus != AI_ON && AIStatus != AI_OFF)
			toggle_ai(AI_ON)
			FindTarget()
		else if(target != null && prob(40))
			FindTarget()


/// DOOR KITING PREVENTION: Track if target is passing through same door repeatedly
/mob/living/simple_animal/hostile/proc/check_target_door_kiting()
	if(!target || !isliving(target))
		return FALSE
	
	// Reset if it's been more than 5 seconds
	if((world.time - target_last_door_pass_time) > 50)
		target_door_pass_count = 0
		target_last_door = null
		committed_to_door_side = FALSE
		committed_door_location = null
		return FALSE
	
	// Get target's current position
	var/turf/target_turf = get_turf(target)
	if(!target_turf || !target_last_position)
		target_last_position = target_turf
		return FALSE
	
	// Check if target moved
	if(target_turf == target_last_position)
		return committed_to_door_side
	
	// Check if target passed through a door between last position and current position
	var/atom/door_passed = null
	
	// Check for doors at old position
	for(var/obj/structure/simple_door/SD in target_last_position)
		if(!SD.density) // Door is open
			door_passed = SD
			break
	if(!door_passed)
		for(var/obj/machinery/door/D in target_last_position)
			if(!D.density) // Door is open
				door_passed = D
				break
	
	// Check for doors at new position
	if(!door_passed)
		for(var/obj/structure/simple_door/SD in target_turf)
			if(!SD.density)
				door_passed = SD
				break
	if(!door_passed)
		for(var/obj/machinery/door/D in target_turf)
			if(!D.density)
				door_passed = D
				break
	
	// Track door passage
	if(door_passed)
		if(door_passed == target_last_door)
			// Target passed through same door again
			if((world.time - target_last_door_pass_time) < 50) // Within 5 seconds
				target_door_pass_count++
				if(target_door_pass_count >= 3)
					// Target is kiting! Commit to this side
					if(!committed_to_door_side)
						committed_to_door_side = TRUE
						committed_door_location = get_turf(src)
						visible_message(span_warning("[src] stops chasing through the doorway!"))
			else
				target_door_pass_count = 1 // Reset if too much time passed
		else
			// Different door
			target_last_door = door_passed
			target_door_pass_count = 1
		
		target_last_door_pass_time = world.time
	
	// Update last position
	target_last_position = target_turf
	return committed_to_door_side

/// CORNER KITING PREVENTION: Track if target is peeking around same corner repeatedly
/mob/living/simple_animal/hostile/proc/check_corner_kiting()
	if(!target || !isliving(target))
		return FALSE
	
	// Reset if it's been more than 5 seconds
	if((world.time - last_corner_peek_time) > 50)
		corner_peek_count = 0
		corner_peek_location = null
		committed_to_corner = FALSE
		return FALSE
	
	// Check if we lost sight of target
	var/has_los = can_see(src, target, get_effective_vision_range(target))
	
	if(!has_los)
		// Target disappeared - record as potential peek
		var/turf/target_turf = get_turf(target)
		if(target_turf)
			// Check if this is same area as last peek
			if(corner_peek_location && get_dist(corner_peek_location, target_turf) <= 2)
				// Same corner area!
				if((world.time - last_corner_peek_time) < 50) // Within 5 seconds
					corner_peek_count++
					if(corner_peek_count >= 3)
						// Target is corner peeking! Commit to rushing
						if(!committed_to_corner)
							committed_to_corner = TRUE
							visible_message(span_warning("[src] stops reacting to the corner peeks!"))
				else
					corner_peek_count = 1
			else
				// New corner location
				corner_peek_location = target_turf
				corner_peek_count = 1
			
			last_corner_peek_time = world.time
	
	return committed_to_corner

/// BARRICADE FIX: Check if target is blocked by structure
/mob/living/simple_animal/hostile/proc/is_target_blocked_by_structure(atom/A)
	if(!A)
		return FALSE
	
	var/turf/source = get_turf(src)
	var/turf/target_turf = get_turf(A)
	
	if(!source || !target_turf)
		return FALSE
	
	// Get line to target
	var/list/line_to_target = getline(source, target_turf)
	
	// Check for blocking structures (NOT doors - doors can be opened)
	for(var/turf/T in line_to_target)
		if(T == source || T == target_turf)
			continue
		
		// Check for barricades, tables, windows, etc
		for(var/obj/structure/S in T)
			if(S.density)
				// Skip doors - we handle those separately
				if(istype(S, /obj/structure/simple_door))
					continue
				if(istype(S, /obj/machinery/door))
					continue
				
				// Found a blocking structure!
				return TRUE
	
	return FALSE

/// LIGHT PATROL: Check for nearby players and start patrol
/mob/living/simple_animal/hostile/proc/check_light_patrol()
	// Don't patrol if already have target, searching, or currently patrolling
	if(target || searching || AIStatus != AI_IDLE || light_patrolling || patrol_resting)
		return
	
	// Check if resting cooldown expired
	if(patrol_resting)
		if((world.time - patrol_rest_start) > patrol_rest_duration)
			patrol_resting = FALSE
			patrol_door_visits = list() // Reset visit counts
		else
			return // Still resting
	
	// Look for players within 14 tiles
	var/found_player = FALSE
	for(var/mob/living/carbon/human/H in range(14, src))
		if(H.stat == DEAD || H.ckey && !H.client)
			continue
		
		// Check if we can attack them (faction check)
		if(!CanAttack(H))
			continue
		
		// Found a valid player!
		found_player = TRUE
		break
	
	if(!found_player)
		return
	
	// Start light patrol!
	start_light_patrol()

/// LIGHT PATROL: Start patrolling
/mob/living/simple_animal/hostile/proc/start_light_patrol()
	light_patrolling = TRUE
	patrol_home = get_turf(src)
	
	// Find doors within 14 tiles
	var/list/available_doors = list()
	
	for(var/obj/structure/simple_door/SD in range(14, src))
		// Skip doors we've visited too many times
		var/visits = patrol_door_visits[SD] || 0
		if(visits >= patrol_max_visits)
			continue
		available_doors += SD
	
	for(var/obj/machinery/door/D in range(14, src))
		var/visits = patrol_door_visits[D] || 0
		if(visits >= patrol_max_visits)
			continue
		available_doors += D
	
	// No doors available?
	if(available_doors.len == 0)
		// Move to furthest point within 7 tiles
		patrol_to_furthest_point()
		return
	
	// Pick a random door
	patrol_target_door = pick(available_doors)
	
	// Record this visit
	if(!patrol_door_visits[patrol_target_door])
		patrol_door_visits[patrol_target_door] = 0
	patrol_door_visits[patrol_target_door]++
	
	visible_message(span_notice("[src] perks up and starts patrolling..."))
	
	// Move toward the door (max 7 tiles)
	patrol_to_target()

/// LIGHT PATROL: Move toward patrol target
/mob/living/simple_animal/hostile/proc/patrol_to_target()
	if(!patrol_target_door || !patrol_home)
		end_light_patrol()
		return
	
	// Calculate how far we can move (max 7 tiles from home)
	var/dist_from_home = get_dist(src, patrol_home)
	var/dist_to_door = get_dist(src, patrol_target_door)
	var/tiles_remaining = 7 - dist_from_home
	
	if(tiles_remaining <= 0)
		// Reached max range - return home
		return_to_patrol_home()
		return
	
	if(dist_to_door <= 1)
		// Reached the door!
		return_to_patrol_home()
		return
	
	// Move toward door with SLOW speed (patrol is slower)
	var/patrol_delay = move_to_delay * 1.5 // 50% slower than normal
	Goto(patrol_target_door, patrol_delay, 1)
	
	// Check again in 2 seconds
	addtimer(CALLBACK(src, PROC_REF(patrol_to_target)), 2 SECONDS, TIMER_DELETE_ME)

/// LIGHT PATROL: Return to starting position
/mob/living/simple_animal/hostile/proc/return_to_patrol_home()
	if(!patrol_home)
		end_light_patrol()
		return
	
	// Move back to home position
	var/patrol_delay = move_to_delay * 1.5
	Goto(patrol_home, patrol_delay, 0)
	
	// Check if we're home
	if(get_dist(src, patrol_home) <= 1)
		end_light_patrol()
	else
		// Check again in 2 seconds
		addtimer(CALLBACK(src, PROC_REF(return_to_patrol_home)), 2 SECONDS, TIMER_DELETE_ME)

/// LIGHT PATROL: Move to furthest point when no doors available
/mob/living/simple_animal/hostile/proc/patrol_to_furthest_point()
	if(!patrol_home)
		end_light_patrol()
		return
	
	// Find furthest open turf within 7 tiles
	var/list/candidate_turfs = list()
	for(var/turf/open/T in range(7, patrol_home))
		if(!T.density)
			candidate_turfs += T
	
	if(candidate_turfs.len == 0)
		end_light_patrol()
		return
	
	// Pick furthest turf
	var/turf/furthest = null
	var/furthest_dist = 0
	for(var/turf/T in candidate_turfs)
		var/dist = get_dist(patrol_home, T)
		if(dist > furthest_dist)
			furthest_dist = dist
			furthest = T
	
	if(!furthest)
		end_light_patrol()
		return
	
	visible_message(span_notice("[src] patrols to a distant point..."))
	
	// Move to furthest point
	var/patrol_delay = move_to_delay * 1.5
	Goto(furthest, patrol_delay, 0)
	
	// Return home after reaching it
	addtimer(CALLBACK(src, PROC_REF(return_to_patrol_home)), 5 SECONDS, TIMER_DELETE_ME)

/// LIGHT PATROL: End patrol and possibly rest
/mob/living/simple_animal/hostile/proc/end_light_patrol()
	light_patrolling = FALSE
	patrol_target_door = null
	walk(src, 0) // Stop moving
	
	// Check if we should start resting
	var/all_doors_visited = TRUE
	for(var/obj/structure/simple_door/SD in range(14, patrol_home))
		var/visits = patrol_door_visits[SD] || 0
		if(visits < patrol_max_visits)
			all_doors_visited = FALSE
			break
	
	if(all_doors_visited)
		for(var/obj/machinery/door/D in range(14, patrol_home))
			var/visits = patrol_door_visits[D] || 0
			if(visits < patrol_max_visits)
				all_doors_visited = FALSE
				break
	
	if(all_doors_visited)
		// All doors visited - rest at home
		patrol_resting = TRUE
		patrol_rest_start = world.time
		visible_message(span_notice("[src] returns to its post."))

// ========================================
// THROWN ITEM DETECTION SYSTEM
// ========================================
// Track who's throwing items, investigate source if spammed

/// Called when a thrown item lands near the mob
/mob/living/simple_animal/hostile/proc/detect_thrown_item(obj/item/thrown_item, atom/thrower)
	if(!thrown_item || !thrower)
		return
	
	// Don't react if we already have a target
	if(target)
		return
	
	// Clear old entries (older than 10 seconds)
	if((world.time - last_thrown_clear) > 100)
		recent_thrown_items = list()
		last_thrown_clear = world.time
	
	// Add this throw to our memory
	if(!recent_thrown_items[thrower])
		recent_thrown_items[thrower] = 0
	recent_thrown_items[thrower]++
	
	// Check if this thrower is spamming
	if(recent_thrown_items[thrower] >= thrown_spam_threshold)
		// SPAM DETECTED - investigate the source (thrower)
		if(CanAttack(thrower))
			visible_message(span_warning("[src] notices someone throwing things!"))
			
			// Wake up if idle
			if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
				toggle_ai(AI_ON)
			
			// Enter search mode targeting the thrower
			last_known_location = get_turf(thrower)
			remembered_target = thrower
			last_target_sighting = world.time
			
			if(!searching)
				enter_search_mode()
			
			// Reset spam counter for this thrower
			recent_thrown_items[thrower] = 0
	else
		// First or second throw - investigate the ITEM, not the thrower
		var/turf/item_location = get_turf(thrown_item)
		
		if(item_location && !searching)
			visible_message(span_notice("[src] looks toward [thrown_item]..."))
			
			// End light patrol if active
			if(light_patrolling)
				end_light_patrol()
			
			// Wake up
			if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
				toggle_ai(AI_ON)
			
			// Set investigation state to prevent LoseTarget() from stopping movement
			last_known_location = item_location
			remembered_target = thrower  // Remember who threw it
			last_target_sighting = world.time  // Mark as recent
			
			// Move toward the item to investigate (adjacent)
			Goto(item_location, move_to_delay, 0)

// ========================================
// LIGHT DESTRUCTION DETECTION SYSTEM
// ========================================
// Investigate shot-out lights, or the shooter if spamming

/// Called when a light is destroyed nearby
/mob/living/simple_animal/hostile/proc/detect_light_destruction(turf/destruction_location, atom/shooter, silenced = FALSE)
	if(!destruction_location)
		return
	
	// Don't react if we already have a target
	if(target)
		return
	
	// Clear old entries (older than 10 seconds)
	if((world.time - last_light_shot_clear) > 100)
		recent_light_shots = list()
		last_light_shot_clear = world.time
	
	// Add this destruction to our memory (if we know the shooter)
	if(shooter)
		if(!recent_light_shots[shooter])
			recent_light_shots[shooter] = 0
		recent_light_shots[shooter]++
	
	// Check if shooter is spamming (shot 3+ lights)
	if(shooter && recent_light_shots[shooter] >= light_spam_threshold)
		// SPAM DETECTED - investigate the SHOOTER
		if(CanAttack(shooter))
			visible_message(span_warning("[src] notices someone shooting out lights!"))
			
			// Wake up if idle
			if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
				toggle_ai(AI_ON)
			
			// Enter search mode targeting the shooter
			last_known_location = get_turf(shooter)
			remembered_target = shooter
			last_target_sighting = world.time
			
			if(!searching)
				enter_search_mode()
			
			// Reset spam counter
			recent_light_shots[shooter] = 0
	else
		// First, second shot, OR we don't know who shot it
		
		if(silenced)
			// Silenced weapon - only investigate if very close (3 tiles)
			// Investigate the LIGHT LOCATION since we can't hear the shooter
			if(get_dist(src, destruction_location) > 3)
				return
			
			visible_message(span_notice("[src] notices a light going out..."))
			
			// End light patrol if active
			if(light_patrolling)
				end_light_patrol()
			
			// Wake up if idle
			if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
				toggle_ai(AI_ON)
			
			// Set investigation state to prevent LoseTarget() from stopping movement
			last_known_location = destruction_location
			if(shooter)
				remembered_target = shooter
			last_target_sighting = world.time
			
			// Move to investigate the light location (adjacent)
			if(!searching)
				Goto(destruction_location, move_to_delay, 0)
		else
			// NOT silenced - heard the gunshot!
			// Natural response: investigate the SHOOTER, not the light
			if(shooter && CanAttack(shooter))
				var/turf/shooter_location = get_turf(shooter)
				
				visible_message(span_warning("[src] heard that shot!"))
				
				// End light patrol if active
				if(light_patrolling)
					end_light_patrol()
				
				// Wake up if idle
				if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
					toggle_ai(AI_ON)
				
				// Set investigation state to prevent LoseTarget() from stopping movement
				last_known_location = shooter_location
				remembered_target = shooter
				last_target_sighting = world.time
				
				// Move directly toward the shooter (adjacent)
				if(!searching)
					Goto(shooter_location, move_to_delay, 0)
			else
				// Don't know the shooter - investigate the light location as fallback
				visible_message(span_notice("[src] notices a light going out..."))
				
				// End light patrol if active
				if(light_patrolling)
					end_light_patrol()
				
				// Wake up if idle
				if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
					toggle_ai(AI_ON)
				
				// Set investigation state to prevent LoseTarget() from stopping movement
				last_known_location = destruction_location
				last_target_sighting = world.time
				
				// Move to investigate the light location (adjacent)
				if(!searching)
					Goto(destruction_location, move_to_delay, 0)

/mob/living/simple_animal/hostile/proc/AttackingTarget()
	// VISION CHECK: Don't attack if we can't see the target
	if(target)
		var/effective_range = get_effective_vision_range(target)
		// If effective range is 0, target is completely out of vision (behind us)
		if(effective_range == 0)
			if(isliving(target))
				var/mob/living/L = target
				if(L.client)
					to_chat(L, span_notice("DEBUG: [src] cannot attack - you are behind them (range=0)"))
			return FALSE
		
		// Check if target is within our effective vision range
		var/dist = get_dist(src, target)
		if(dist > effective_range)
			if(isliving(target))
				var/mob/living/L = target
				if(L.client)
					to_chat(L, span_notice("DEBUG: [src] cannot attack - beyond vision range (dist=[dist], range=[effective_range])"))
			return FALSE
	
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
	
	// Face the target when we acquire them
	if(target && !QDELETED(target))
		var/face_dir = get_dir(src, target)
		if(face_dir && face_dir != dir)
			setDir(face_dir)
	
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
	// Check if we should clear memory due to target being crit/dead
	if(remembered_target && !QDELETED(remembered_target) && isliving(remembered_target))
		var/mob/living/L = remembered_target
		if(L.stat == DEAD || L.stat == UNCONSCIOUS)
			// Target went crit/dead - clear memory immediately
			remembered_target = null
			last_target_sighting = 0
			if(searching)
				exit_search_mode(give_up_message = TRUE, found_target = FALSE)

	// Z-pursuit check
	if(target && can_z_move && isliving(target))
		var/mob/living/L = target
		if(L.z != z)
			remembered_target = L
			last_target_sighting = world.time
			last_known_location = get_turf(L)

			if((world.time - last_z_move_attempt) < 50)
				return

			if(attempt_z_pursuit())
				return

	// Memory expired or no memory - truly give up
	if(remembered_target && (world.time - last_target_sighting) > target_memory_duration && !searching)
		remembered_target = null

	// If memory still valid, enter search instead of fully giving up
	if(remembered_target && (world.time - last_target_sighting) < target_memory_duration)
		if(!searching)
			enter_search_mode()
		// Still clear the combat target
		GiveTarget(null)
		approaching_target = FALSE
		in_melee = FALSE
		walk(src, 0)
		LoseAggro()
		return

	// Full give-up
	if(searching)
		exit_search_mode(give_up_message = FALSE, found_target = FALSE)

	if(rallying)
		rallying = FALSE
		rally_point = null

	pursuing_z_target = FALSE
	z_pursuit_structure = null
	remembered_target = null
	last_known_location = null
	is_stuck = FALSE
	stuck_position = null
	stuck_time = 0
	path_attempts = 0

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
				addtimer(CALLBACK(src, PROC_REF(climb_stairs), S), 1, TIMER_DELETE_ME)
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
		return

	// Don't start searching if the remembered target is dead OR CRIT
	if(remembered_target && !QDELETED(remembered_target) && isliving(remembered_target))
		var/mob/living/L = remembered_target
		if(L.stat == DEAD || L.stat == UNCONSCIOUS) // FIX: Include UNCONSCIOUS (crit)
			// Target is dead/crit, no point searching
			remembered_target = null
			last_target_sighting = 0
			return

	if(last_search_exit_time > 0 && (world.time - last_search_exit_time) < search_entry_cooldown)
		if(!remembered_target || (world.time - last_target_sighting) > target_memory_duration)
			return

	searching = TRUE

	if(target)
		last_known_location = get_turf(target)
	else if(remembered_target && !QDELETED(remembered_target))
		last_known_location = get_turf(remembered_target)

	searched_turfs = list()
	searched_doors = list()
	searched_containers = list()
	search_expansion = 0
	search_start_time = world.time
	recently_opened_door = null
	investigating_container = null

	visible_message(span_warning("[src] looks around suspiciously..."))

	if(is_alpha_alerter)
		if(target)
			call_for_backup(target, "lost")
		else if(remembered_target && !QDELETED(remembered_target))
			call_for_backup(remembered_target, "lost")

	// Schedule search asynchronously to avoid blocking call in signal handlers
	addtimer(CALLBACK(src, PROC_REF(search_for_target)), 0.5 SECONDS, TIMER_DELETE_ME)

/mob/living/simple_animal/hostile/proc/exit_search_mode(give_up_message = TRUE, found_target = FALSE)
	if(!searching)
		return

	searching = FALSE
	last_search_exit_time = world.time

	searched_turfs = list()
	searched_doors = list()
	searched_containers = list()
	search_expansion = 0
	recently_opened_door = null
	investigating_container = null
	search_start_time = 0

	if(!found_target)
		// Gave up - no longer tracking this threat
		is_alpha_alerter = FALSE
		remembered_target = null
		last_target_sighting = 0
		if(give_up_message)
			visible_message(span_notice("[src] gives up the search."))
		LoseTarget()
	else
		visible_message(span_danger("[src] resumes the hunt!"))
		// is_alpha_alerter stays as-is - if we found the target we may now broadcast

/mob/living/simple_animal/hostile/proc/search_for_target()
	if(!searching || QDELETED(src))
		return

	// Check if remembered_target is dead/invalid - if so, give up search
	if(remembered_target)
		if(QDELETED(remembered_target))
			// Target deleted entirely
			visible_message(span_notice("[src] gives up the search."))
			exit_search_mode(FALSE)
			return
		
		if(isliving(remembered_target))
			var/mob/living/L = remembered_target
			if(L.stat == DEAD)
				// Target died - no point searching for a corpse
				visible_message(span_notice("[src] gives up the search."))
				exit_search_mode(FALSE)
				return

	// HARD CHECK: Valid, visible, ATTACKABLE target right now?
	var/list/immediate_targets = ListTargets()
	if(immediate_targets && immediate_targets.len > 0)
		for(var/atom/possible_target in immediate_targets)
			// BUG 1 FIX: CanAttack() gates faction member targeting
			// BUG 3 FIX: Explicit living+stat check catches ghosts that slip past CanAttack
			if(isliving(possible_target))
				var/mob/living/L = possible_target
				if(L.stat == DEAD || L.ckey && !L.client) // Dead or ghosted
					continue
			if(!can_see(src, possible_target, get_effective_vision_range(possible_target)))
				continue
			if(!CanAttack(possible_target))
				continue

			visible_message(span_danger("[src] spots [possible_target]!"))
			exit_search_mode(FALSE, found_target = TRUE)
			last_target_sighting = world.time
			remembered_target = possible_target
			GiveTarget(possible_target)
			last_known_location = get_turf(possible_target)
			walk(src, 0)
			call_for_backup(possible_target, "found")
			return

	// TIME-BASED TIMEOUT
	if(search_start_time > 0)
		var/elapsed_time = world.time - search_start_time
		var/timeout_threshold = search_timeout_base

		if(is_low_health || (last_target_sighting > 0 && (world.time - last_target_sighting) < 600))
			timeout_threshold = search_timeout_aggressive

		if(elapsed_time > timeout_threshold)
			visible_message(span_notice("[src] gives up the search."))
			exit_search_mode(FALSE)
			return

	if(!last_known_location || !CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		addtimer(CALLBACK(src, PROC_REF(search_for_target)), 3 SECONDS, TIMER_DELETE_ME)
		return

	var/turf/current_pos = get_turf(src)
	var/dist_to_last_known = get_dist(current_pos, last_known_location)

	// PRIORITY 0: Move to last_known_location if we're far from it
	// This ensures we search where the player was last seen, not random areas
	if(dist_to_last_known > 3)
		// Check for doors blocking the path to last_known_location
		if(can_open_doors)
			var/dir_to_target = get_dir(src, last_known_location)
			var/turf/T = get_step(src, dir_to_target)
			if(T)
				// Check for doors in the next step toward target
				for(var/obj/structure/simple_door/SD in T)
					if(SD.density && !(SD in searched_doors))
						searched_doors += SD
						if(try_open_door(SD))
							visible_message(span_notice("[src] opens [SD] to continue pursuit..."))
							
							// Check if target is now visible after opening door
							sleep(5)
							var/list/check_targets = ListTargets()
							if(check_targets && check_targets.len > 0)
								for(var/atom/possible_target in check_targets)
									if(isliving(possible_target))
										var/mob/living/L = possible_target
										if(L.stat == DEAD || L.ckey && !L.client)
											continue
									if(!can_see(src, possible_target, get_effective_vision_range(possible_target)))
										continue
									if(!CanAttack(possible_target))
										continue
									
									visible_message(span_danger("[src] spots [possible_target]!"))
									exit_search_mode(FALSE, found_target = TRUE)
									last_target_sighting = world.time
									remembered_target = possible_target
									GiveTarget(possible_target)
									last_known_location = get_turf(possible_target)
									walk(src, 0)
									call_for_backup(possible_target, "found")
									return
							
							addtimer(CALLBACK(src, PROC_REF(search_for_target)), 1 SECONDS, TIMER_DELETE_ME)
							return
				for(var/obj/machinery/door/D in T)
					if(D.density && !(D in searched_doors))
						searched_doors += D
						if(try_open_door(D))
							visible_message(span_notice("[src] opens [D] to continue pursuit..."))
							
							// Check if target is now visible after opening door
							sleep(5)
							var/list/check_targets = ListTargets()
							if(check_targets && check_targets.len > 0)
								for(var/atom/possible_target in check_targets)
									if(isliving(possible_target))
										var/mob/living/L = possible_target
										if(L.stat == DEAD || L.ckey && !L.client)
											continue
									if(!can_see(src, possible_target, get_effective_vision_range(possible_target)))
										continue
									if(!CanAttack(possible_target))
										continue
									
									visible_message(span_danger("[src] spots [possible_target]!"))
									exit_search_mode(FALSE, found_target = TRUE)
									last_target_sighting = world.time
									remembered_target = possible_target
									GiveTarget(possible_target)
									last_known_location = get_turf(possible_target)
									walk(src, 0)
									call_for_backup(possible_target, "found")
									return
							
							addtimer(CALLBACK(src, PROC_REF(search_for_target)), 1 SECONDS, TIMER_DELETE_ME)
							return
		
		// We're too far from where we last saw them - move closer first
		if(!(last_known_location in searched_turfs))
			searched_turfs += last_known_location
			visible_message(span_warning("[src] moves to investigate the last known position..."))
			Goto(last_known_location, move_to_delay, 0)
			addtimer(CALLBACK(src, PROC_REF(search_for_target)), 3 SECONDS, TIMER_DELETE_ME)
			return

	// Special case: Very close to last_known_location - do thorough immediate area check
	// This catches targets standing right at/near the door or last known position
	if(dist_to_last_known <= 1)
		var/list/close_range_targets = ListTargets()
		if(close_range_targets && close_range_targets.len > 0)
			for(var/atom/possible_target in close_range_targets)
				if(isliving(possible_target))
					var/mob/living/L = possible_target
					if(L.stat == DEAD || L.ckey && !L.client)
						continue
				
				// More lenient check when very close - check actual distance
				var/dist_to_target = get_dist(src, possible_target)
				if(dist_to_target <= 3) // Within close range
					if(CanAttack(possible_target))
						visible_message(span_danger("[src] spots [possible_target] nearby!"))
						exit_search_mode(FALSE, found_target = TRUE)
						last_target_sighting = world.time
						remembered_target = possible_target
						GiveTarget(possible_target)
						last_known_location = get_turf(possible_target)
						walk(src, 0)
						call_for_backup(possible_target, "found")
						return

	// Now we're close to last_known_location - search systematically around it
	var/current_radius = search_radius + (search_expansion * 2)
	if(current_radius > 15)
		current_radius = 15

	// PRIORITY 1: Check BOTH doors AND containers, investigate closest one
	// This fixes the issue where mobs would check all doors before any containers
	if(can_open_doors && last_known_location)
		// Ensure last_known_location is a proper turf
		if(!isturf(last_known_location))
			last_known_location = get_turf(last_known_location)
		
		if(last_known_location)
			var/list/hiding_spots = list() // Combined list of doors and containers
			
			// Collect unchecked doors
			for(var/obj/structure/simple_door/SD in range(current_radius, last_known_location))
				if(!(SD in searched_doors) && SD.density)
					hiding_spots += SD
			for(var/obj/machinery/door/D in range(current_radius, last_known_location))
				if(!(D in searched_doors) && D.density)
					hiding_spots += D
			
			// Collect unchecked containers 
			for(var/obj/structure/closet/C in range(current_radius, last_known_location))
				if(!(C in searched_containers) && !C.opened && !C.welded && !C.locked)
					hiding_spots += C
			
			// Find CLOSEST hiding spot (door or container)
			if(hiding_spots.len > 0)
				var/atom/closest_spot = null
				var/closest_dist = 999
				for(var/atom/spot in hiding_spots)
					var/dist = get_dist(src, spot)
					if(dist < closest_dist)
						closest_dist = dist
						closest_spot = spot
				
				// Handle the closest hiding spot
				if(closest_spot)
					// Is it a container?
					if(istype(closest_spot, /obj/structure/closet))
						var/obj/structure/closet/C = closest_spot
						
						if(get_dist(src, C) <= 1) // Adjacent - open it NOW
							searched_containers += C
							visible_message(span_warning("[src] searches [C]..."))
							
							// Check container contents BEFORE opening
							for(var/atom/A in C.contents)
								if(isliving(A))
									var/mob/living/L = A
									if(L.stat == DEAD || L.ckey && !L.client)
										continue
									if(CanAttack(L))
										// Found someone hiding!
										C.open(src)
										sleep(5)
										visible_message(span_danger("[src] found [L] hiding in [C]!"))
										exit_search_mode(FALSE, found_target = TRUE)
										last_target_sighting = world.time
										remembered_target = L
										GiveTarget(L)
										last_known_location = get_turf(L)
										walk(src, 0)
										call_for_backup(L, "found")
										return
							
							// No one inside - open and check nearby
							C.open(src)
							sleep(5)
							
							var/list/check_targets = ListTargets()
							if(check_targets && check_targets.len > 0)
								for(var/atom/possible_target in check_targets)
									if(isliving(possible_target))
										var/mob/living/L = possible_target
										if(L.stat == DEAD || L.ckey && !L.client)
											continue
									if(!CanAttack(possible_target))
										continue
									
									if(get_dist(possible_target, C) <= 1)
										visible_message(span_danger("[src] found [possible_target] near [C]!"))
										exit_search_mode(FALSE, found_target = TRUE)
										last_target_sighting = world.time
										remembered_target = possible_target
										GiveTarget(possible_target)
										last_known_location = get_turf(possible_target)
										walk(src, 0)
										call_for_backup(possible_target, "found")
										return
							
							// Container was empty - continue searching
							addtimer(CALLBACK(src, PROC_REF(search_for_target)), 1 SECONDS, TIMER_DELETE_ME)
							return
						else // Not adjacent - move toward it
							Goto(C, move_to_delay, 0)
							addtimer(CALLBACK(src, PROC_REF(search_for_target)), 1.5 SECONDS, TIMER_DELETE_ME)
							return
					
					// Is it a door?
					else
						if(get_dist(src, closest_spot) <= 1) // Adjacent - open it
							searched_doors += closest_spot
							if(try_open_door(closest_spot))
								recently_opened_door = closest_spot
								sleep(5)
								
								var/list/check_targets = ListTargets()
								if(check_targets && check_targets.len > 0)
									for(var/atom/possible_target in check_targets)
										if(isliving(possible_target))
											var/mob/living/L = possible_target
											if(L.stat == DEAD || L.ckey && !L.client)
												continue
										if(!can_see(src, possible_target, get_effective_vision_range(possible_target)))
											continue
										if(!CanAttack(possible_target))
											continue
										
										visible_message(span_danger("[src] spots [possible_target] behind the door!"))
										exit_search_mode(FALSE, found_target = TRUE)
										last_target_sighting = world.time
										remembered_target = possible_target
										GiveTarget(possible_target)
										last_known_location = get_turf(possible_target)
										walk(src, 0)
										call_for_backup(possible_target, "found")
										return
								
								// No visible target - continue searching
								addtimer(CALLBACK(src, PROC_REF(search_for_target)), 1 SECONDS, TIMER_DELETE_ME)
								return
						else // Not adjacent - move toward it
							Goto(closest_spot, move_to_delay, 0)
							addtimer(CALLBACK(src, PROC_REF(search_for_target)), 1.5 SECONDS, TIMER_DELETE_ME)
							return
		
		// All hiding spots checked
	
	// PRIORITY 2: Explore unsearched tiles around last_known_location
	var/list/unexplored_turfs = list()
	
	// Search around last_known_location, not our current position
	for(var/turf/T in range(current_radius, last_known_location))
		if(T in searched_turfs)
			continue
		if(!istype(T, /turf/open))
			continue
		
		// Prioritize tiles near recently opened doors
		if(recently_opened_door)
			var/turf/door_turf = get_turf(recently_opened_door)
			if(get_dist(T, door_turf) <= 2)
				unexplored_turfs.Insert(1, T)
				continue
		
		// PERFORMANCE: Direct door check instead of turf iteration
		var/near_unopened_door = FALSE
		for(var/obj/structure/simple_door/SD in orange(1, T))
			if(SD.density && !(SD in searched_doors))
				near_unopened_door = TRUE
				break
		if(!near_unopened_door)
			for(var/obj/machinery/door/D in orange(1, T))
				if(D.density && !(D in searched_doors))
					near_unopened_door = TRUE
					break
		
		if(near_unopened_door)
			unexplored_turfs.Insert(1, T)
		else
			unexplored_turfs += T
	
	// Move to unexplored area
	if(unexplored_turfs.len)
		var/turf/search_target = null
		
		// Pick from top candidates, preferring ones closer to last_known_location
		var/candidates_count = min(5, unexplored_turfs.len)
		var/list/candidate_turfs = unexplored_turfs.Copy(1, candidates_count + 1)
		
		// Score by distance to last_known_location (closer = better)
		var/best_score = 999
		for(var/turf/T in candidate_turfs)
			var/score = get_dist(T, last_known_location)
			
			// Small randomization to avoid perfectly synchronized movement
			score += rand(-2, 2)
			
			if(score < best_score)
				best_score = score
				search_target = T
		
		if(!search_target)
			search_target = pick(candidate_turfs)
		
		// Clear recently_opened_door if we've moved past it
		if(recently_opened_door)
			var/turf/door_turf = get_turf(recently_opened_door)
			if(door_turf && get_dist(current_pos, door_turf) > 3)
				recently_opened_door = null
		
		// Move to target
		searched_turfs += search_target
		Goto(search_target, move_to_delay, 0)
	else
		// Exhausted current radius - expand search
		search_expansion++
		if(search_expansion <= 8)
			visible_message(span_notice("[src] expands the search..."))

	addtimer(CALLBACK(src, PROC_REF(search_for_target)), 3 SECONDS, TIMER_DELETE_ME)

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

	if(last_give_up_time && (world.time - last_give_up_time) < give_up_cooldown)
		return

	// Ghost/dead check on the alert target itself
	if(isliving(alert_target))
		var/mob/living/L = alert_target
		if(L.stat == DEAD || L.ckey && !L.client)
			return // Don't chase ghosts or corpses

	// Can we see them directly?
	if(can_see(src, alert_target, get_effective_vision_range(alert_target)) && CanAttack(alert_target))
		if(searching)
			exit_search_mode(found_target = TRUE)
		// Direct confirmation → becomes alpha
		GiveTarget(alert_target) // GiveTarget sets is_alpha_alerter = TRUE
		remembered_target = alert_target
		last_target_sighting = world.time
		last_known_location = target_location
		if(AIStatus != AI_ON)
			toggle_ai(AI_ON)
		visible_message(span_danger("[src] responds to the alert!"))
		return

	// Can't see them - search quietly, no cascade
	is_alpha_alerter = FALSE  // Explicitly secondary
	remembered_target = alert_target
	last_target_sighting = world.time
	last_known_location = target_location

	if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
		toggle_ai(AI_ON)

	if(!searching && !target)
		// enter_search_mode() will see is_alpha_alerter=FALSE and NOT broadcast
		enter_search_mode()
		if(target_location && get_dist(src, target_location) > 3)
			visible_message(span_danger("[src] responds to the alert and advances!"))
			Goto(target_location, move_to_delay, 2)
		else
			visible_message(span_danger("[src] responds to the alert!"))
	else if(target && target != alert_target)
		// Already have a target - only update memory if alert target is much closer
		if(get_dist(src, alert_target) < get_dist(src, target) - 3)
			last_known_location = target_location

// RETREAT TO ALLIES - move toward nearby allies while calling for backup
/mob/living/simple_animal/hostile/proc/retreat_to_allies()
	if(!target)
		return
	
	// Find nearby allies
	var/list/nearby_allies = list()
	var/turf/my_turf = get_turf(src)
	
	// Same Z-level
	for(var/mob/living/simple_animal/hostile/M in range(backup_call_range, src))
		if(M == src || M.stat == DEAD || M.ckey)
			continue
		if(faction_check_mob(M, TRUE))
			nearby_allies += M
	
	// Check Z-level above
	var/turf/above_us = get_step_multiz(my_turf, UP)
	if(above_us)
		for(var/mob/living/simple_animal/hostile/M in range(backup_call_range, above_us))
			if(M == src || M.stat == DEAD || M.ckey)
				continue
			if(faction_check_mob(M, TRUE))
				nearby_allies += M
	
	// Check Z-level below
	var/turf/below_us = get_step_multiz(my_turf, DOWN)
	if(below_us)
		for(var/mob/living/simple_animal/hostile/M in range(backup_call_range, below_us))
			if(M == src || M.stat == DEAD || M.ckey)
				continue
			if(faction_check_mob(M, TRUE))
				nearby_allies += M
	
	if(nearby_allies.len)
		// Found allies! Call for backup and enter rally mode
		visible_message(span_danger("[src] retreats toward reinforcements, calling for backup!"))
		call_for_backup(target, "found")
		
		// Enter rally mode
		rallying = TRUE
		rally_start_time = world.time
		rally_point = get_turf(target) // Remember where we saw the target
		
		// Move toward closest ally
		var/mob/living/simple_animal/hostile/closest_ally = null
		var/shortest_dist = INFINITY
		for(var/mob/living/simple_animal/hostile/ally in nearby_allies)
			var/dist = get_dist(src, ally)
			if(dist < shortest_dist)
				shortest_dist = dist
				closest_ally = ally
		
		if(closest_ally && get_dist(src, closest_ally) > 2) // Only move if not already adjacent
			Goto(closest_ally, move_to_delay, 2) // Stop at distance 2 from ally
			
		// Schedule advance back to target after rally duration
		addtimer(CALLBACK(src, PROC_REF(advance_after_rally)), rally_duration, TIMER_DELETE_ME)
	else
		// No allies nearby, just alert them anyway and keep fighting
		call_for_backup(target, "found")

// Advance back to target after rallying with allies
/mob/living/simple_animal/hostile/proc/advance_after_rally()
	if(!rallying || QDELETED(src))
		return
	
	// Exit rally mode
	rallying = FALSE
	
	// If we still have a target, advance toward them
	if(target && !QDELETED(target))
		visible_message(span_danger("[src] advances with reinforcements!"))
		
		// Move toward target if they're far away
		var/dist = get_dist(src, target)
		if(dist > 3)
			Goto(target, move_to_delay, 1)
	
	// Fallback: If no target but we have rally point, move there
	else if(rally_point && !QDELETED(rally_point))
		visible_message(span_danger("[src] advances toward the last sighting!"))
		Goto(rally_point, move_to_delay, 2)
	
	// Clear rally point
	rally_point = null

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

// CURIOSITY - Check door during idle investigation
/mob/living/simple_animal/hostile/proc/curiosity_check_door(atom/door)
	if(!door || QDELETED(door) || stat == DEAD || AIStatus == AI_OFF)
		return
	
	// Only proceed if we're still idle and near the door
	if(AIStatus != AI_IDLE || get_dist(src, door) > 2)
		return
	
	// Try to open the door
	if(get_dist(src, door) <= 1 && try_open_door(door))
		visible_message(span_notice("[src] peeks through [door]..."))
		
		// Wait a moment for door to open
		sleep(5)
		
		// Look for targets on the other side
		var/list/check_targets = ListTargets()
		if(check_targets && check_targets.len > 0)
			for(var/atom/possible_target in check_targets)
				if(isliving(possible_target))
					var/mob/living/L = possible_target
					if(L.stat == DEAD || L.ckey && !L.client)
						continue
				if(!CanAttack(possible_target))
					continue
				
				// Found someone! Wake up and aggro properly
				visible_message(span_danger("[src] spots [possible_target] through the door!"))
				toggle_ai(AI_ON)
				last_target_sighting = world.time
				remembered_target = possible_target
				GiveTarget(possible_target)
				last_known_location = get_turf(possible_target)
				walk(src, 0)
				call_for_backup(possible_target, "found")
				COOLDOWN_RESET(src, sight_shoot_delay)
				LosePatience()
				return
		
		// Didn't see anyone - check nearby containers (within 5 tiles beyond the door)
		var/turf/door_turf = get_turf(door)
		if(door_turf)
			var/list/nearby_containers = list()
			for(var/turf/T in range(5, door_turf))
				for(var/obj/structure/closet/C in T)
					if(!C.opened && !C.welded && !C.locked)
						nearby_containers += C
			
			if(nearby_containers.len > 0)
				// Pick closest container
				var/obj/structure/closet/closest_container = null
				var/closest_dist = 999
				for(var/obj/structure/closet/C in nearby_containers)
					var/dist = get_dist(src, C)
					if(dist < closest_dist)
						closest_dist = dist
						closest_container = C
				
				if(closest_container)
					visible_message(span_notice("[src] investigates [closest_container]..."))
					// Move toward it
					Goto(closest_container, move_to_delay, 0)
					// Check it after getting close
					addtimer(CALLBACK(src, PROC_REF(curiosity_check_container), closest_container), 3 SECONDS, TIMER_DELETE_ME)
					return

// CURIOSITY - Check container during idle investigation
/mob/living/simple_animal/hostile/proc/curiosity_check_container(obj/structure/closet/container)
	if(!container || QDELETED(container) || stat == DEAD || AIStatus == AI_OFF)
		return
	
	// Only proceed if we're still idle and near the container
	if(AIStatus != AI_IDLE || get_dist(src, container) > 1)
		return
	
	// Check if container is still closed
	if(container.opened || container.welded || container.locked)
		return
	
	visible_message(span_warning("[src] searches [container]..."))
	
	// Check container contents BEFORE opening (to catch hiding mobs)
	for(var/atom/A in container.contents)
		if(isliving(A))
			var/mob/living/L = A
			if(L.stat == DEAD || L.ckey && !L.client)
				continue
			if(CanAttack(L))
				// Found someone hiding! Open and aggro!
				container.open(src)
				sleep(5) // Wait for animation
				visible_message(span_danger("[src] found [L] hiding in [container]!"))
				toggle_ai(AI_ON)
				last_target_sighting = world.time
				remembered_target = L
				GiveTarget(L)
				last_known_location = get_turf(L)
				walk(src, 0)
				call_for_backup(L, "found")
				COOLDOWN_RESET(src, sight_shoot_delay)
				LosePatience()
				return
	
	// No one inside - just open it
	container.open(src)
	sleep(5)
	
	// Check if anyone visible nearby now (they might have stepped out)
	var/list/check_targets = ListTargets()
	if(check_targets && check_targets.len > 0)
		for(var/atom/possible_target in check_targets)
			if(isliving(possible_target))
				var/mob/living/L = possible_target
				if(L.stat == DEAD || L.ckey && !L.client)
					continue
			if(!CanAttack(possible_target))
				continue
			
			// Found someone nearby - aggro!
			visible_message(span_danger("[src] spots [possible_target]!"))
			toggle_ai(AI_ON)
			last_target_sighting = world.time
			remembered_target = possible_target
			GiveTarget(possible_target)
			last_known_location = get_turf(possible_target)
			walk(src, 0)
			call_for_backup(possible_target, "found")
			COOLDOWN_RESET(src, sight_shoot_delay)
			LosePatience()
			return

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

// SOUND DETECTION - hear gunfire and move toward it (WITH MUFFLING)
/mob/living/simple_animal/hostile/proc/hear_combat_sound(turf/sound_location, atom/sound_source)
	if(!can_hear_combat)
		return
	
	if(!sound_location || QDELETED(sound_location))
		return
	
	// Calculate muffled range
	var/effective_range = calculate_muffled_sound_range(sound_location, combat_hearing_range)
	
	// Ignore sounds beyond effective range
	var/distance = get_dist(src, sound_location)
	var/z_distance = abs(z - sound_location.z)
	
	if(distance > effective_range)
		return
	
	if(z_distance > 1) // Only hear sounds 1 Z-level away max
		return
	
	last_combat_sound = world.time
	
	// Don't give exact location - pick a random spot near the sound (simulates hearing direction)
	var/list/investigation_turfs = list()
	for(var/turf/T in range(3, sound_location)) // Smaller radius for more accurate investigation
		if(istype(T, /turf/open))
			investigation_turfs += T
	
	var/turf/investigation_spot = sound_location
	if(investigation_turfs.len)
		investigation_spot = pick(investigation_turfs)
	
	// WAKE UP if idle - sounds should always wake mobs
	if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
		toggle_ai(AI_ON)
		visible_message(span_warning("[src] perks up at the sound of combat!"))
	
	// If we're stuck on stairs or in a loop, this breaks us out
	if(pursuing_z_target || (recent_climbs >= 2))
		// Commit to the Z-level the sound came from
		if(sound_location.z != z && can_z_move)
			committed_z_level = 0 // Clear commitment
			recent_climbs = 0
			z_commit_time = 0
			
			if(remembered_target)
				last_known_location = investigation_spot // Use approximate location
			
			if(searching)
				last_known_location = investigation_spot
		else if(sound_location.z == z)
			commit_to_z_level()
			
			if(searching || !target)
				last_known_location = investigation_spot
				if(!searching)
					enter_search_mode()
	
	// ACTIVELY INVESTIGATE - move toward the sound!
	if(!target) // Only investigate if we don't have a target
		last_known_location = investigation_spot
		
		if(!searching)
			enter_search_mode()
			visible_message(span_notice("[src] starts investigating the commotion..."))
		else
			// Already searching, update location
			visible_message(span_notice("[src] adjusts their search toward the gunfire..."))
	else if(searching)
		// We have a remembered target but are searching - update search location
		last_known_location = investigation_spot
		visible_message(span_notice("[src] adjusts their search toward the gunfire..."))

// Hear impact sounds (bullet hitting wall/target) - smaller radius
/mob/living/simple_animal/hostile/proc/hear_impact_sound(turf/impact_location, atom/sound_source)
	if(!can_hear_combat)
		return
	
	if(!impact_location || QDELETED(impact_location))
		return
	
	// Calculate muffled range (now 7 tiles to match combat sounds)
	var/effective_range = calculate_muffled_sound_range(impact_location, impact_hearing_range)
	
	// Ignore sounds beyond effective range
	var/distance = get_dist(src, impact_location)
	var/z_distance = abs(z - impact_location.z)
	
	if(distance > effective_range)
		return
	
	if(z_distance > 1) // Only hear sounds 1 Z-level away max
		return
	
	last_combat_sound = world.time
	
	// Use impact location directly for CPU efficiency (no random picking)
	var/turf/investigation_spot = impact_location
	
	// ALWAYS WAKE UP - impacts should alert idle mobs
	if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
		toggle_ai(AI_ON)
		visible_message(span_warning("[src] hears an impact nearby!"))
	
	// AGGRESSIVE DOOR CHECKING - open doors between us and impact (ONLY ADJACENT)
	if(can_open_doors)
		var/list/path = getline(get_turf(src), impact_location)
		for(var/turf/T in path)
			// REALISM FIX: Only open doors within melee range (adjacent)
			var/door_distance = get_dist(src, T)
			if(door_distance > 1)
				continue // Too far to open
			
			// Check for simple doors
			for(var/obj/structure/simple_door/SD in T)
				if(SD.density && try_open_door(SD))
					visible_message(span_notice("[src] opens [SD] to investigate!"))
					break // Only open one door per check for performance
			
			// Check for machinery doors
			for(var/obj/machinery/door/D in T)
				if(D.density && try_open_door(D))
					visible_message(span_notice("[src] opens [D] to investigate!"))
					break // Only open one door per check for performance
	
	// INVESTIGATE - move toward the impact
	if(!target)
		last_known_location = investigation_spot
		
		if(!searching)
			enter_search_mode()
			visible_message(span_notice("[src] goes to investigate the noise..."))
		else
			last_known_location = investigation_spot
	else if(searching)
		// Update search location to be closer to impact
		last_known_location = investigation_spot

/mob/living/simple_animal/hostile/proc/hear_gunshot(turf/shot_location, atom/shooter)
	if(!can_hear_combat)
		return
	
	if(!shot_location || QDELETED(shot_location))
		return
	
	// Check if shooter is an enemy
	if(shooter && faction_check_mob(shooter))
		return // Don't care about friendly fire
	
	// Calculate muffled range
	var/effective_range = calculate_muffled_sound_range(shot_location, combat_hearing_range)
	
	var/distance = get_dist(src, shot_location)
	var/z_distance = abs(z - shot_location.z)
	
	if(distance > effective_range)
		return
	
	if(z_distance > 1)
		return
	
	// Wake up if idle
	if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
		toggle_ai(AI_ON)
	
	// If we don't have a target, investigate the sound
	if(!target && !searching)
		last_known_location = shot_location
		enter_search_mode()
		visible_message(span_warning("[src] perks up at the sound of gunfire!"))

// LIGHT DETECTION - detect and investigate light sources in darkness
/mob/living/simple_animal/hostile/proc/detect_light_source()
	if(!can_detect_light)
		return
	
	// Check cooldown
	if(world.time < last_light_detected + light_detection_cooldown)
		return
	
	// Check if we're in darkness (if required)
	if(only_detect_lights_in_darkness)
		var/turf/my_turf = get_turf(src)
		if(!my_turf)
			return
		
		// Check the ambient light level at our location
		var/light_level = my_turf.get_lumcount()
		if(light_level > darkness_threshold)
			return // Too bright, don't bother detecting lights
	
	// ONLY check for living mobs with lights - not objects
	var/list/potential_lights = list()
	
	// FIX: Use the INTEGRATED vision system instead of raw view()
	// Check all mobs in range, but filter by effective vision range
	for(var/mob/living/M in view(light_detection_range, src))
		if(M == src)
			continue
		
		// Don't detect friendly faction members
		if(faction_check_mob(M))
			continue
		
		// Check if they're emitting enough light
		if(M.light_range < light_detection_threshold)
			continue
		
		// FIX: Apply the integrated vision system
		// This checks BOTH lighting and direction
		var/effective_range = get_effective_vision_range(M)
		var/actual_distance = get_dist(src, M)
		
		// Only detect if within our effective vision range
		if(actual_distance <= effective_range)
			potential_lights += M
	
	// If we found any lights, investigate the closest one
	if(potential_lights.len > 0)
		var/atom/closest_light = null
		var/closest_distance = INFINITY
		
		for(var/atom/light_source in potential_lights)
			var/distance = get_dist(src, light_source)
			if(distance < closest_distance)
				closest_distance = distance
				closest_light = light_source
		
		if(closest_light)
			var/turf/light_location = get_turf(closest_light)
			
			// Update cooldown
			last_light_detected = world.time
			last_light_location = light_location
			
			// Wake up if idle
			if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
				toggle_ai(AI_ON)
			
			// If it's a mob and we don't have a target, acquire it
			if(ismob(closest_light) && !target)
				GiveTarget(closest_light)
				visible_message(span_warning("[src] spots a light source in the darkness!"))
				return
			
			// Otherwise investigate the location
			if(!target && !searching)
				last_known_location = light_location
				enter_search_mode()
				visible_message(span_warning("[src] notices a light in the darkness..."))
			else if(searching && !target)
				// Update search location if already searching
				last_known_location = light_location

// CORNER NAVIGATION - try alternate paths when stuck at corners
/mob/living/simple_animal/hostile/proc/navigate_around_corner()
	if(!target || !CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		return FALSE
	
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	
	if(!my_turf || !target_turf)
		return FALSE
	
	// Get direction to target
	var/target_dir = get_dir(my_turf, target_turf)
	
	// Try moving perpendicular to the target direction to navigate around corners
	// This helps when stuck at walls/corners
	var/list/sidestep_dirs = list()
	
	// Build list of perpendicular directions based on primary direction
	switch(target_dir)
		if(NORTH)
			sidestep_dirs = list(EAST, WEST)
		if(SOUTH)
			sidestep_dirs = list(EAST, WEST)
		if(EAST)
			sidestep_dirs = list(NORTH, SOUTH)
		if(WEST)
			sidestep_dirs = list(NORTH, SOUTH)
		if(NORTHEAST)
			sidestep_dirs = list(NORTH, EAST, SOUTHEAST, NORTHWEST)
		if(NORTHWEST)
			sidestep_dirs = list(NORTH, WEST, SOUTHWEST, NORTHEAST)
		if(SOUTHEAST)
			sidestep_dirs = list(SOUTH, EAST, NORTHEAST, SOUTHWEST)
		if(SOUTHWEST)
			sidestep_dirs = list(SOUTH, WEST, NORTHWEST, SOUTHEAST)
	
	// Shuffle to avoid predictable patterns
	sidestep_dirs = shuffle(sidestep_dirs)
	
	// Try each sidestep direction
	for(var/step_dir in sidestep_dirs)
		var/turf/test_turf = get_step(my_turf, step_dir)
		
		if(!test_turf)
			continue
		
		// Check if this turf is passable
		if(test_turf.density)
			continue
		
		// Check for blocking objects
		var/blocked = FALSE
		for(var/atom/movable/AM in test_turf)
			if(AM.density && AM != target)
				// Check if we can open it (door)
				if(can_open_doors && (istype(AM, /obj/structure/simple_door) || istype(AM, /obj/machinery/door)))
					// Try opening the door
					try_open_door(AM)
					blocked = FALSE
					break
				else
					blocked = TRUE
					break
		
		if(blocked)
			continue
		
		// Check if this position gets us closer or provides better angle
		var/current_dist = get_dist(my_turf, target_turf)
		var/new_dist = get_dist(test_turf, target_turf)
		
		// Accept if same distance or closer (allows sidestepping around corners)
		if(new_dist <= current_dist + 1)
			// Try to move there
			if(Move(test_turf, step_dir))
				// Success! Clear stuck state
				return TRUE
	
	// Couldn't find alternate path
	return FALSE

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

// Helper function to find a nearby position with clear line of sight to target
/mob/living/simple_animal/hostile/proc/find_firing_position(atom/target)
	if(!target)
		return null
	
	// Get current distance to target
	var/current_dist = get_dist(src, target)
	
	// Try adjacent tiles that maintain roughly the same distance
	var/list/candidate_positions = list()
	var/turf/my_turf = get_turf(src)
	
	for(var/direction in GLOB.cardinals + GLOB.diagonals)
		var/turf/T = get_step(my_turf, direction)
		if(!T || T.density)
			continue
		
		// Check if we can move there
		var/blocked = FALSE
		for(var/atom/A in T)
			if(A.density && A != src)
				blocked = TRUE
				break
		if(blocked)
			continue
		
		// Check if this position has clear shot line (not just vision)
		var/has_clear_shot = TRUE
		var/turf/target_turf = get_turf(target)
		var/list/shot_check = getline(T, target_turf)
		
		for(var/turf/check_turf in shot_check)
			if(check_turf == T || check_turf == target_turf)
				continue
			
			if(check_turf.density)
				has_clear_shot = FALSE
				break
			
			for(var/atom/A in check_turf)
				if(A.density && !ismob(A))
					has_clear_shot = FALSE
					break
			
			if(!has_clear_shot)
				break
		
		if(!has_clear_shot)
			continue
		
		// Check distance - prefer positions at similar distance
		var/new_dist = get_dist(T, target)
		var/dist_diff = abs(new_dist - current_dist)
		
		// Prioritize positions that maintain our distance
		if(dist_diff <= 1)
			candidate_positions[T] = 1 // High priority
		else if(dist_diff <= 2)
			candidate_positions[T] = 2 // Medium priority
		else
			candidate_positions[T] = 3 // Low priority (distance changed too much)
	
	// Return best position, or null if none found
	if(candidate_positions.len > 0)
		// Sort by priority and return best
		var/turf/best_pos = null
		var/best_priority = 999
		for(var/turf/T in candidate_positions)
			if(candidate_positions[T] < best_priority)
				best_priority = candidate_positions[T]
				best_pos = T
		return best_pos
	
	return null

/mob/living/simple_animal/hostile/proc/OpenFire(atom/A)
	// CRITICAL: Check if we actually have line of sight before shooting
	// Exception: Allow close-range shooting (within 2 tiles) even without perfect LOS
	var/dist_to_target = get_dist(src, A)
	if(dist_to_target > 2 && !can_see(src, A, get_effective_vision_range(A)))
		return FALSE // Can't see target and not close enough, don't shoot
	
	if(COOLDOWN_TIMELEFT(src, sight_shoot_delay))
		return FALSE
	
	// BARRICADE FIX: Don't shoot at targets blocked by structures
	// Pathfinding will handle getting around obstacles
	if(dist_to_target > 2 && is_target_blocked_by_structure(A))
		return FALSE // Target behind barricade/table/window - path around instead
	
	// TACTICAL: Check shot line for doors - prefer opening over shooting (ONLY ADJACENT)
	if(can_open_doors && A.z == z) // Only check same Z-level
		var/list/shot_line = getline(src, A)
		for(var/turf/T in shot_line)
			if(T == get_turf(src)) // Skip our own tile
				continue
			
			// REALISM FIX: Only open doors within melee range (adjacent tiles)
			var/door_distance = get_dist(src, T)
			if(door_distance > 1)
				continue // Too far to open, skip this door
			
			// Check for simple doors
			for(var/obj/structure/simple_door/SD in T)
				if(SD.density && try_open_door(SD))
					visible_message(span_notice("[src] opens [SD] to get a clear shot!"))
					return FALSE // Don't shoot this turn, door is opening
			
			// Check for machinery doors
			for(var/obj/machinery/door/D in T)
				if(D.density && try_open_door(D))
					visible_message(span_notice("[src] opens [D] to get a clear shot!"))
					return FALSE // Don't shoot this turn, door is opening
	
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
			addtimer(cb, (i - 1)*rapid_fire_delay, TIMER_DELETE_ME)
	else
		Shoot(A)
		for(var/i in 1 to extra_projectiles)
			addtimer(CALLBACK(src, PROC_REF(Shoot), A), i * auto_fire_delay, TIMER_DELETE_ME)
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

// CHECK SHOT LINE - detect if projectiles will hit walls even  with diagonal vision
/mob/living/simple_animal/hostile/proc/is_shot_blocked(atom/target)
	if(!target)
		return TRUE
	
	// Get the shot line from us to target
	var/turf/source_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	
	if(!source_turf || !target_turf)
		return TRUE
	
	// Use getline to get the actual path a projectile would take
	var/list/shot_line = getline(source_turf, target_turf)
	
	// Check each turf in the shot path
	for(var/turf/T in shot_line)
		if(T == source_turf || T == target_turf)
			continue // Skip source and destination
		
		// Check if turf itself is dense
		if(T.density)
			return TRUE // Wall or dense turf blocks shot
		
		// Check for dense atoms (walls, windows, etc)
		for(var/atom/A in T)
			if(A.density)
				// Ignore mobs - we can shoot over/past them
				if(ismob(A))
					continue
				// Ignore simple animals - can shoot over them
				if(istype(A, /mob/living/simple_animal))
					continue
				// Dense structure/obj blocks shot
				return TRUE
	
	// Shot line is clear
	return FALSE


/mob/living/simple_animal/hostile/Move(atom/newloc, dir, step_x, step_y)
	// FIX: Set facing direction when we move (so mobs turn naturally)
	if(dir && dir != src.dir && !dodging)
		setDir(dir)
	
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

// SPATIAL AWARENESS - scan for doors we can use
/mob/living/simple_animal/hostile/proc/scan_for_doors()
	if(!can_open_doors)
		return
	
	// PERFORMANCE: Reduced scan range from vision_range to fixed 5 to reduce lag
	// Direct object iteration instead of turf iteration
	var/scan_range = 5
	
	for(var/obj/machinery/door/D in range(scan_range, src))
		// Add to known doors if not already there
		var/door_loc = get_turf(D)
		if(door_loc && !(door_loc in known_doors))
			known_doors += door_loc
	
	for(var/obj/structure/simple_door/SD in range(scan_range, src))
		// Add to known doors if not already there
		var/door_loc = get_turf(SD)
		if(door_loc && !(door_loc in known_doors))
			known_doors += door_loc
	
	// Limit memory size to prevent bloat (keep 20 most recent)
	if(known_doors.len > 20)
		known_doors.Cut(1, known_doors.len - 20)

// Try alternate paths using door memory
/mob/living/simple_animal/hostile/proc/try_alternate_path()
	if(!target || !can_open_doors)
		return FALSE
	
	if(path_attempts >= max_path_attempts)
		return FALSE // Tried enough times
	
	path_attempts++
	
	// Look for known doors that might provide alternate routes
	var/list/potential_doors = list()
	
	for(var/turf/door_loc in known_doors)
		if(QDELETED(door_loc))
			known_doors -= door_loc
			continue
		
		// Check if door is in a useful direction
		var/door_dist = get_dist(src, door_loc)
		var/target_dist = get_dist(src, target)
		
		// Door should be closer to us than target, but still reasonably close to target
		if(door_dist < target_dist && door_dist <= 10)
			potential_doors += door_loc
	
	if(!potential_doors.len)
		return FALSE
	
	// Pick a random door to try
	var/turf/chosen_door = pick(potential_doors)
	
	visible_message(span_notice("[src] looks for another way around..."))
	
	// Pathfind to the door
	Goto(chosen_door, move_to_delay, 0)
	
	return TRUE

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
	// This should only be called when we're REALLY stuck (after 15 seconds of trying)
	
	// SPECIAL CASE: If searching, mark current location as unreachable and let search continue
	if(searching)
		// Mark our stuck position as searched so we don't try to go there again
		var/turf/stuck_at = get_turf(src)
		if(stuck_at && !(stuck_at in searched_turfs))
			searched_turfs += stuck_at
		// Also mark nearby turfs as searched to help pathfinding avoid this area
		for(var/turf/T in range(2, stuck_at))
			if(!(T in searched_turfs))
				searched_turfs += T
		// Reset stuck state so we can try a different search location
		is_stuck = FALSE
		stuck_position = null
		stuck_time = 0
		path_attempts = 0
		return
	
	// PRIORITY 1: Try opening doors aggressively first
	if(can_open_doors)
		var/opened_something = FALSE
		
		// Try all adjacent turfs for doors
		for(var/dir in GLOB.cardinals)
			var/turf/T = get_step(src, dir)
			if(!T)
				continue
			
			// Try simple doors
			for(var/obj/structure/simple_door/SD in T)
				if(SD.density && try_open_door(SD))
					opened_something = TRUE
					visible_message(span_notice("[src] forces open [SD]!"))
			
			// Try machinery doors
			for(var/obj/machinery/door/D in T)
				if(D.density && try_open_door(D))
					opened_something = TRUE
					visible_message(span_notice("[src] forces open [D]!"))
		
		if(opened_something)
			// Give the door time to open
			return
	
	// PRIORITY 2: Try alternate paths using door memory
	if(can_open_doors && try_alternate_path())
		visible_message(span_notice("[src] tries to find another route..."))
		return
	
	// GIVE UP: If exhausted all path attempts and been stuck for 30+ seconds, give up entirely
	if(path_attempts >= max_path_attempts && is_stuck && (world.time - stuck_time > 300))
		visible_message(span_notice("[src] gives up the chase."))
		// Set exhaustion cooldown to prevent immediate re-acquisition
		last_give_up_time = world.time
		// Force clear ALL target state
		searching = FALSE
		remembered_target = null
		last_target_sighting = 0
		LoseTarget()
		return
	
	// PRIORITY 3: Only smash if we can't open doors AND we're REALLY stuck
	if(!environment_smash)
		// Can't smash - if we've exhausted options and been stuck 20+ seconds, give up
		if(path_attempts >= max_path_attempts && is_stuck && (world.time - stuck_time > 200))
			visible_message(span_notice("[src] gives up the chase."))
			// Set exhaustion cooldown to prevent immediate re-acquisition
			last_give_up_time = world.time
			// Force clear ALL target state
			searching = FALSE
			remembered_target = null
			last_target_sighting = 0
			LoseTarget()
		return
	
	// Check if we've been stuck long enough to justify smashing
	if(!is_stuck || (world.time - stuck_time < smash_delay))
		return // Not stuck long enough yet
	
	// ANTI-SPAM: Check smash cooldown
	if((world.time - last_smash_time) < smash_cooldown)
		return // Too soon since last smash
	
	// ONE frustration message with cooldown
	visible_message(span_danger("[src] gets frustrated and starts breaking things!"))
	last_smash_time = world.time
	
	// Now we can smash
	EscapeConfinement()
	var/dir_to_target = get_dir(targets_from, target)
	var/dir_list = list()
	if(dir_to_target in GLOB.diagonals)
		for(var/direction in GLOB.cardinals)
			if(direction & dir_to_target)
				dir_list += direction
	else
		dir_list += dir_to_target
	
	// Only smash if target is close (prevents smashing through entire base)
	var/target_dist = get_dist(targets_from, target)
	if(target_dist <= 5) // Only smash if within 5 tiles
		for(var/direction in dir_list)
			SmashInDirection(direction)

// Pure smashing - no door checking (that's handled above now)
/mob/living/simple_animal/hostile/proc/SmashInDirection(direction)
	var/turf/T = get_step(targets_from, direction)
	if(T && T.Adjacent(targets_from))
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
	addtimer(CALLBACK(src, PROC_REF(un_emp_stun)), min(intensity, 3 SECONDS), TIMER_DELETE_ME)

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
	addtimer(CALLBACK(src, PROC_REF(un_emp_berserk), old_faction), intensity SECONDS * 0.5, TIMER_DELETE_ME)

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
