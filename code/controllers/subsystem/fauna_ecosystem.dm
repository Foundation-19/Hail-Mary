// code/controllers/subsystem/fauna_ecosystem.dm
// LIVING ECOSYSTEM - Fauna that feels alive
//
// Gameplay Tuning Pass (TONED DOWN):
// - Less insane spawn/repro pressure (server won’t melt)
// - Packs still exist, but less “always-on”
// - Roaming is REAL: solos commit to 30–45 tile goals (not 3-tile shuffles)
//
// FORMATION / ANTI-STACK FIX:
// - Pack members DO NOT all chase the leader tile anymore.
// - Each member gets a stable “slot” around the leader.
// - Non-leaders only take 1 step per pack tick (prevents yo-yo + clumping).
// - Leader drives patrol/hunt movement.
//
// WARNING: More roaming means mobs travel farther; watch edge cases like map borders/invalid areas.

#define FAUNA_TICK_SECS 6 // toned down from 3

// ---- Population ----
#define FAUNA_HEAT_HARDCAP 70
#define FAUNA_HEAT_DECAY 0.12
#define FAUNA_HEAT_FROM_HUMAN 3
#define FAUNA_HEAT_NIGHT_MULT 2

// ---- Reproduction ----
#define FAUNA_REPRO_EVERY 90
#define FAUNA_REPRO_CHANCE 22
#define FAUNA_REPRO_CHILDREN_MIN 1
#define FAUNA_REPRO_CHILDREN_MAX 3
#define FAUNA_REPRO_COOLDOWN 520
#define FAUNA_REPRO_SPREAD_MIN 3
#define FAUNA_REPRO_SPREAD_MAX 9
#define FAUNA_MATE_SEARCH_RANGE 18
#define FAUNA_MATE_PAIR_RANGE 6
#define FAUNA_GESTATION_MIN 80
#define FAUNA_GESTATION_MAX 150
#define FAUNA_NEST_STAY_RADIUS 8
#define FAUNA_NEST_DECAY 2400
#define FAUNA_REPRO_CHANCE_MIN 8
#define FAUNA_REPRO_CHANCE_MAX 88
#define FAUNA_REPRO_LOWPOP_BOOST_HIGH 24
#define FAUNA_REPRO_LOWPOP_BOOST_MID 12
#define FAUNA_REPRO_LOWPOP_SOLO_THRESH 45
#define FAUNA_REPRO_LOWPOP_SOLO_CHANCE 18
#define FAUNA_REPRO_MAX_OFFSPRING_PASS 32

// ---- Territorial Spread ----
#define FAUNA_CROWD_RADIUS 6
#define FAUNA_CROWD_THRESHOLD 6
#define FAUNA_DISPERSE_DIST 14

// ---- Pack Behavior ----
#define FAUNA_PACK_PROCESS_EVERY 3
#define FAUNA_PACK_MOVE_SPEED 1   // leader movement; followers are capped to 1 step
#define FAUNA_PACK_COHESION_DIST 10
#define FAUNA_PACK_PATROL_RADIUS 35
#define FAUNA_PACK_WAYPOINT_COUNT 4
#define FAUNA_PACK_HUNT_RANGE 14
#define FAUNA_PACK_GIVE_UP_RANGE 22

// ---- Solo Mob Behavior ----
#define FAUNA_SOLO_WANDER_CHANCE 28
#define FAUNA_SOLO_WANDER_DIST 4
#define FAUNA_SOLO_FIND_FRIENDS_RANGE 18
#define FAUNA_SOLO_FLEE_RANGE 10
#define FAUNA_SOLO_FLEE_DIST 14

// ---- Predator/Prey ----
#define FAUNA_PREDATOR_HUNT_RANGE 12
#define FAUNA_PREDATOR_CHASE_SPEED 1
#define FAUNA_PREDATOR_KILL_RANGE 1
#define FAUNA_PREDATOR_REST_AFTER_KILL 70

// ---- Z-Level Activity ----
#define FAUNA_Z_ACTIVE_TTL 4200

// ---- Roaming (NEW) ----
#define FAUNA_ROAM_MIN 30
#define FAUNA_ROAM_MAX 45
#define FAUNA_ROAM_RETRY 25
#define FAUNA_ROAM_STEP_SPEED 1

// ---- Home / Nesting ----
#define FAUNA_HOME_ASSIGN_MIN 3
#define FAUNA_HOME_ASSIGN_MAX 12
#define FAUNA_HOME_PULL_DIST 10
#define FAUNA_HOME_PATROL_RADIUS 20

// ---- Behavior States ----
#define FAUNA_STATE_ROAM "roam"
#define FAUNA_STATE_HUNT "hunt"
#define FAUNA_STATE_FLEE "flee"
#define FAUNA_STATE_RETURN_HOME "return_home"
#define FAUNA_STATE_GUARD_HOME "guard_home"
#define FAUNA_STATE_REST "rest"
#define FAUNA_STATE_INVESTIGATE "investigate"

// ---- Intent / Memory / Signals ----
#define FAUNA_INTENT_MIN 20
#define FAUNA_INTENT_MAX 60
#define FAUNA_INVESTIGATE_TTL 100
#define FAUNA_INVESTIGATE_RANGE 14
#define FAUNA_INVESTIGATE_CHANCE 16
#define FAUNA_SIGNAL_RANGE 12
#define FAUNA_SIGNAL_COOLDOWN 50
#define FAUNA_HOME_DANGER_RELOCATE 8
#define FAUNA_BLOCKED_TTL 120
#define FAUNA_SCENT_TTL 900
#define FAUNA_PAUSE_MIN 8
#define FAUNA_PAUSE_MAX 22
#define FAUNA_TERRITORY_CORE_MIN 7
#define FAUNA_TERRITORY_CORE_MAX 14
#define FAUNA_STALK_CHASE_TTL 140
#define FAUNA_FLANK_MIN_DIST 3
#define FAUNA_FLANK_MAX_DIST 8
#define FAUNA_DEBUG_SUMMARY_EVERY 150
#define FAUNA_DEN_QUALITY_MAX 100
#define FAUNA_DEN_QUALITY_DECAY 0.2

// ---- Role Types ----
#define FAUNA_ROLE_PREY 1
#define FAUNA_ROLE_AMBUSH 2
#define FAUNA_ROLE_HUNTER 3
#define FAUNA_ROLE_APEX 4

SUBSYSTEM_DEF(fauna_ecosystem)
	name = "Fauna Ecosystem"
	wait = FAUNA_TICK_SECS
	priority = 35
	flags = SS_BACKGROUND

	var/list/species_defs = list()
	var/list/packs = list()

	// Timers keyed by ref string
	var/list/repro_cooldowns = list()  // "\ref[mob]" -> time
	var/list/rest_timers = list()      // "\ref[mob]" -> time
	var/list/flee_memory = list()      // "\ref[mob]" -> "\ref[threat]"
	var/list/hunt_memory = list()      // "\ref[mob]" -> "\ref[prey]"
	var/list/gestation_until = list()  // "\ref[mob]" -> time
	var/list/mate_target = list()      // "\ref[mob]" -> "\ref[mate]"
	var/list/nest_site = list()        // "\ref[mob]" -> turf
	var/list/nest_expires = list()     // "\ref[mob]" -> time

	// Roam goals keyed by ref string
	var/list/roam_goal = list()        // "\ref[mob]" -> "\ref[turf]"
	var/list/home_turf = list()        // "\ref[mob]" -> turf
	var/list/mob_state = list()        // "\ref[mob]" -> FAUNA_STATE_*
	var/list/intent_until = list()     // "\ref[mob]" -> world.time
	var/list/investigate_goal = list() // "\ref[mob]" -> turf
	var/list/investigate_until = list()// "\ref[mob]" -> world.time
	var/list/prey_last_turf = list()   // "\ref[mob]" -> turf
	var/list/threat_last_turf = list() // "\ref[mob]" -> turf
	var/list/signal_cd_until = list()  // "\ref[mob]" -> world.time
	var/list/home_danger = list()      // "\ref[mob]" -> scalar
	var/list/blocked_memory = list()   // "\ref[mob]" -> list(turf = world.time expiry)
	var/list/pause_until = list()      // "\ref[mob]" -> world.time
	var/list/territory_core = list()   // "\ref[mob]" -> radius
	var/list/dominance_rank = list()   // "\ref[mob]" -> 1..100
	var/list/chase_until = list()      // "\ref[mob]" -> world.time
	var/list/failed_hunt_until = list()// "\ref[mob]" -> world.time
	var/list/scent_trails = list()     // "x,y,z|species" -> world.time expiry
	var/list/safe_spot = list()        // "\ref[mob]" -> turf
	var/list/home_quality = list()     // "\ref[mob]" -> 0..100
	var/list/home_backup = list()      // "\ref[mob]" -> turf
	var/list/home_season = list()      // "\ref[mob]" -> season index

	var/list/z_last_human = list()
	var/list/z_heat = list()

	var/next_repro_tick = 0
	var/process_cycle = 0

	var/debug_logging = FALSE

// ============== HELPER: Safe ref key ==============
/datum/controller/subsystem/fauna_ecosystem/proc/mob_key(mob/M)
	if(!M) return null
	return "\ref[M]"

/datum/controller/subsystem/fauna_ecosystem/proc/get_mob_from_key(key)
	if(!key) return null
	return locate(key)

/datum/controller/subsystem/fauna_ecosystem/proc/ensure_mob_profile(mob/living/simple_animal/hostile/M)
	if(!M) return
	var/key = mob_key(M)
	if(!key) return
	if(isnull(territory_core[key]))
		territory_core[key] = rand(FAUNA_TERRITORY_CORE_MIN, FAUNA_TERRITORY_CORE_MAX)
	if(isnull(dominance_rank[key]))
		dominance_rank[key] = rand(1, 100)

/datum/controller/subsystem/fauna_ecosystem/proc/scent_key(turf/T, species_id)
	if(!T || !species_id) return null
	return "[T.x],[T.y],[T.z]|[species_id]"

/datum/controller/subsystem/fauna_ecosystem/proc/drop_scent(mob/living/simple_animal/hostile/M)
	if(!M) return
	var/datum/fauna_species/S = get_species_for_mob(M)
	if(!S) return
	var/turf/T = get_turf(M)
	if(!T) return
	var/key = scent_key(T, S.id)
	if(!key) return
	scent_trails[key] = world.time + FAUNA_SCENT_TTL

/datum/controller/subsystem/fauna_ecosystem/proc/get_scent_value(turf/T, species_id)
	var/key = scent_key(T, species_id)
	if(!key) return 0
	var/expires = scent_trails[key]
	if(!expires) return 0
	if(world.time >= expires)
		scent_trails -= key
		return 0
	return max(1, round((expires - world.time) / 80))

/datum/controller/subsystem/fauna_ecosystem/proc/terrain_preference_score(datum/fauna_species/S, turf/T)
	if(!S || !T) return -1000
	if(!is_valid_turf(T)) return -1000

	var/score = 0
	var/path = "[T.type]"
	var/area/A = get_area(T)
	var/apath = A ? "[A.type]" : ""

	if(findtext(path, "water"))
		if(findtext(S.id, "mirelurk"))
			score += 4
		else
			score -= 2

	if(findtext(path, "cave") || findtext(apath, "cave") || findtext(apath, "underground"))
		if(S.role >= FAUNA_ROLE_AMBUSH) score += 2
		else score -= 1

	if(findtext(path, "outside") || findtext(apath, "wasteland"))
		if(S.role == FAUNA_ROLE_PREY || S.role == FAUNA_ROLE_HUNTER) score += 2

	if(findtext(path, "building") || findtext(apath, "building"))
		if(S.role >= FAUNA_ROLE_AMBUSH) score += 1

	// crude altitude/cliff awareness
	if(findtext(path, "cliff") || findtext(path, "chasm") || findtext(path, "drop"))
		if(S.role >= FAUNA_ROLE_AMBUSH) score += 1
		else score -= 4

	if(findtext(path, "roof"))
		if(S.role == FAUNA_ROLE_AMBUSH) score += 1
		else score -= 2

	return score

/datum/controller/subsystem/fauna_ecosystem/proc/is_blocked_recently(mob/living/simple_animal/hostile/M, turf/T)
	if(!M || !T) return FALSE
	var/key = mob_key(M)
	if(!key) return FALSE
	var/list/memory = blocked_memory[key]
	if(!islist(memory)) return FALSE
	var/until = memory[T]
	if(!until) return FALSE
	if(world.time >= until)
		memory -= T
		blocked_memory[key] = memory
		return FALSE
	return TRUE

/datum/controller/subsystem/fauna_ecosystem/proc/remember_blocked_turf(mob/living/simple_animal/hostile/M, turf/T)
	if(!M || !T) return
	var/key = mob_key(M)
	if(!key) return
	var/list/memory = blocked_memory[key]
	if(!islist(memory))
		memory = list()
	memory[T] = world.time + FAUNA_BLOCKED_TTL
	blocked_memory[key] = memory

/datum/controller/subsystem/fauna_ecosystem/proc/get_behavior_state(mob/living/simple_animal/hostile/M)
	var/key = mob_key(M)
	if(!key) return FAUNA_STATE_ROAM
	var/state = mob_state[key]
	if(!istext(state) || !length(state))
		return FAUNA_STATE_ROAM
	return state

/datum/controller/subsystem/fauna_ecosystem/proc/should_pause(mob/living/simple_animal/hostile/M)
	var/key = mob_key(M)
	if(!key) return FALSE
	var/until = pause_until[key]
	if(until && world.time < until)
		return TRUE

	var/state = get_behavior_state(M)
	var/chance = 0
	switch(state)
		if(FAUNA_STATE_ROAM) chance = 8
		if(FAUNA_STATE_INVESTIGATE) chance = 14
		if(FAUNA_STATE_GUARD_HOME) chance = 10
		if(FAUNA_STATE_HUNT) chance = 3
		if(FAUNA_STATE_FLEE) chance = 1
		if(FAUNA_STATE_REST) chance = 20
		else chance = 6

	if(prob(chance))
		pause_until[key] = world.time + rand(FAUNA_PAUSE_MIN, FAUNA_PAUSE_MAX)
		return TRUE
	return FALSE

/datum/controller/subsystem/fauna_ecosystem/proc/maybe_social_tick(mob/living/simple_animal/hostile/M, datum/fauna_species/S)
	if(!M || !S) return
	var/mob/living/simple_animal/hostile/friend = find_nearby_same_species(M, 2)
	if(!friend) return

	var/mkey = mob_key(M)
	if(!mkey) return

	// greeting ritual
	if(prob(6))
		set_intent(M, FAUNA_STATE_GUARD_HOME, rand(10, 24))
		return

	// grooming during rest windows
	if(prob(5) && get_behavior_state(M) == FAUNA_STATE_REST)
		rest_timers[mkey] = world.time + rand(20, 45)
		return

	// simple juvenile play behavior
	if(findtext(S.id, "young") && prob(10))
		wander_randomly(M, 3)

/datum/controller/subsystem/fauna_ecosystem/proc/maybe_handle_territory_conflict(mob/living/simple_animal/hostile/M, datum/fauna_species/S)
	if(!M || !S) return
	var/mkey = mob_key(M)
	var/turf/my_home = get_home_turf(M)
	if(!mkey || !my_home) return

	var/core = territory_core[mkey]
	if(!core) core = 8

	var/mob/living/simple_animal/hostile/rival = find_nearby_same_species(M, 3)
	if(!rival || rival == M) return
	if(is_in_pack(M) && is_in_pack(rival)) return

	var/rkey = mob_key(rival)
	var/turf/rhome = get_home_turf(rival)
	if(!rkey || !rhome) return

	if(get_dist(M, my_home) > core) return
	if(get_dist(rival, my_home) > core) return

	if(prob(9))
		var/my_dom = dominance_rank[mkey]
		var/r_dom = dominance_rank[rkey]
		if(my_dom >= r_dom)
			set_intent(M, FAUNA_STATE_GUARD_HOME, rand(16, 35))
			step_toward_target(rival, rhome, 1)
		else
			set_intent(rival, FAUNA_STATE_GUARD_HOME, rand(16, 35))
			step_toward_target(M, my_home, 1)

/datum/controller/subsystem/fauna_ecosystem/proc/choose_flank_turf(mob/living/simple_animal/hostile/M, atom/target)
	var/turf/TT = get_turf(target)
	if(!TT || !M) return null
	var/turf/MT = get_turf(M)
	if(!MT) return null
	var/d = get_dist(MT, TT)
	if(d < FAUNA_FLANK_MIN_DIST || d > FAUNA_FLANK_MAX_DIST)
		return null

	var/dir = get_dir(MT, TT)
	var/side = pick(turn(dir, 90), turn(dir, -90))
	var/turf/F = get_step(TT, side)
	if(F && is_valid_turf(F))
		return F
	return null

/datum/controller/subsystem/fauna_ecosystem/proc/choose_move_direction(mob/living/simple_animal/hostile/M, atom/target)
	if(!M || !target) return 0
	var/turf/MT = get_turf(M)
	if(!MT) return 0
	var/datum/fauna_species/S = get_species_for_mob(M)
	if(!S) return 0

	var/base_dir = get_dir(M, target)
	var/list/cands = list(
		base_dir,
		turn(base_dir, 45),
		turn(base_dir, -45),
		turn(base_dir, 90),
		turn(base_dir, -90)
	)

	var/best_dir = 0
	var/best_score = -10000
	var/state = get_behavior_state(M)
	for(var/d in cands)
		if(!d) continue
		var/turf/T = get_step(M, d)
		if(!T) continue
		if(is_blocked_recently(M, T)) continue

		var/sc = terrain_preference_score(S, T)
		if(sc <= -999) continue
		sc -= get_dist(T, target)

		// path smoothing
		if(d != base_dir) sc += 0.5

		// return-home can leverage scent trail
		if(state == FAUNA_STATE_RETURN_HOME)
			sc += get_scent_value(T, S.id)

		if(sc > best_score)
			best_score = sc
			best_dir = d

	return best_dir

/datum/controller/subsystem/fauna_ecosystem/proc/smart_step_towards(mob/living/simple_animal/hostile/M, atom/target)
	if(!M || !target) return
	if(should_pause(M)) return

	var/state = get_behavior_state(M)
	var/turf/start = get_turf(M)
	if(!start) return

	var/atom/final_target = target
	var/datum/fauna_species/S = get_species_for_mob(M)

	// stalking / flanking for predators
	if(S && S.role >= FAUNA_ROLE_AMBUSH && state == FAUNA_STATE_HUNT)
		var/turf/flank = choose_flank_turf(M, target)
		if(flank && prob(45))
			final_target = flank

	// slight curvature even in non-hunt movement
	if(prob(18))
		var/dir = get_dir(M, final_target)
		var/curve = pick(turn(dir, 45), turn(dir, -45))
		var/turf/curved = get_step(M, curve)
		if(curved && is_valid_turf(curved))
			final_target = curved

	var/d = choose_move_direction(M, final_target)
	if(!d)
		return

	step(M, d)
	var/turf/end = get_turf(M)
	if(end == start)
		var/turf/blocked = get_step(M, d)
		if(blocked)
			remember_blocked_turf(M, blocked)
		return

	drop_scent(M)

/datum/controller/subsystem/fauna_ecosystem/proc/set_intent(mob/living/simple_animal/hostile/M, state, duration = 0)
	if(!M || !state) return
	var/key = mob_key(M)
	if(!key) return
	var/prev = mob_state[key]
	mob_state[key] = state
	if(duration <= 0)
		duration = rand(FAUNA_INTENT_MIN, FAUNA_INTENT_MAX)
	intent_until[key] = world.time + duration
	if(debug_logging && prev != state && prob(8))
		log_world("FAUNA AI: [M.type] [prev] -> [state] ([duration] ticks)")

/datum/controller/subsystem/fauna_ecosystem/proc/intent_locked(mob/living/simple_animal/hostile/M, expected_state = null)
	var/key = mob_key(M)
	if(!key) return FALSE
	var/until = intent_until[key]
	if(!until || world.time >= until)
		return FALSE
	if(expected_state && mob_state[key] != expected_state)
		return FALSE
	return TRUE

/datum/controller/subsystem/fauna_ecosystem/proc/remember_target_turf(list/bucket, mob/living/simple_animal/hostile/M, atom/target)
	if(!bucket || !M || !target) return
	var/turf/T = get_turf(target)
	if(!T || !is_valid_turf(T)) return
	bucket[mob_key(M)] = T

/datum/controller/subsystem/fauna_ecosystem/proc/maybe_emit_hunt_signal(mob/living/simple_animal/hostile/M, atom/target)
	if(!M || !target) return
	var/mkey = mob_key(M)
	if(!mkey) return
	var/cd = signal_cd_until[mkey]
	if(cd && world.time < cd) return
	signal_cd_until[mkey] = world.time + FAUNA_SIGNAL_COOLDOWN

	var/datum/fauna_species/myS = get_species_for_mob(M)
	if(!myS) return

	for(var/mob/living/simple_animal/hostile/ally in range(FAUNA_SIGNAL_RANGE, M))
		if(ally == M) continue
		if(QDELETED(ally) || ally.stat) continue

		var/datum/fauna_species/allyS = get_species_for_mob(ally)
		if(!allyS || allyS.id != myS.id) continue

		var/akey = mob_key(ally)
		hunt_memory[akey] = mob_key(target)
		remember_target_turf(prey_last_turf, ally, target)
		set_intent(ally, FAUNA_STATE_HUNT, rand(20, 45))

/datum/controller/subsystem/fauna_ecosystem/proc/maybe_emit_flee_signal(mob/living/simple_animal/hostile/M, mob/living/simple_animal/hostile/threat)
	if(!M || !threat) return
	var/mkey = mob_key(M)
	if(!mkey) return
	var/cd = signal_cd_until[mkey]
	if(cd && world.time < cd) return
	signal_cd_until[mkey] = world.time + FAUNA_SIGNAL_COOLDOWN

	var/datum/fauna_species/myS = get_species_for_mob(M)
	if(!myS) return

	for(var/mob/living/simple_animal/hostile/ally in range(FAUNA_SIGNAL_RANGE, M))
		if(ally == M) continue
		if(QDELETED(ally) || ally.stat) continue

		var/datum/fauna_species/allyS = get_species_for_mob(ally)
		if(!allyS || allyS.id != myS.id) continue

		var/akey = mob_key(ally)
		flee_memory[akey] = mob_key(threat)
		remember_target_turf(threat_last_turf, ally, threat)
		set_intent(ally, FAUNA_STATE_FLEE, rand(18, 35))

/datum/controller/subsystem/fauna_ecosystem/proc/try_start_investigation(mob/living/simple_animal/hostile/M, turf/T)
	if(!M || !T || !is_valid_turf(T)) return FALSE
	var/mkey = mob_key(M)
	if(!mkey) return FALSE
	investigate_goal[mkey] = T
	investigate_until[mkey] = world.time + FAUNA_INVESTIGATE_TTL
	set_intent(M, FAUNA_STATE_INVESTIGATE, rand(25, 55))
	return TRUE

/datum/controller/subsystem/fauna_ecosystem/proc/do_investigate_behavior(mob/living/simple_animal/hostile/M)
	var/mkey = mob_key(M)
	if(!mkey) return FALSE
	var/until = investigate_until[mkey]
	var/turf/goal = investigate_goal[mkey]
	if(!until || world.time >= until || !goal || QDELETED(goal))
		investigate_goal -= mkey
		investigate_until -= mkey
		return FALSE

	if(get_dist(M, goal) <= 1)
		investigate_goal -= mkey
		investigate_until -= mkey
		set_intent(M, FAUNA_STATE_GUARD_HOME, rand(12, 28))
		return TRUE

	step_toward_target(M, goal, 1)
	return TRUE

/datum/controller/subsystem/fauna_ecosystem/proc/tick_home_danger(mob/living/simple_animal/hostile/M, datum/fauna_species/S)
	if(!M || !S) return
	var/mkey = mob_key(M)
	if(!mkey) return
	var/turf/home = get_home_turf(M)
	if(!home) return

	var/d = home_danger[mkey]
	if(isnull(d)) d = 0
	d = max(0, d - 0.25)

	var/q = home_quality[mkey]
	if(isnull(q)) q = rand(35, 60)
	q = clamp(q - FAUNA_DEN_QUALITY_DECAY, 0, FAUNA_DEN_QUALITY_MAX)

	var/mob/living/predator = find_nearby_predator(M, 5)
	if(predator)
		d += 1
		q -= 0.8
	var/mob/living/carbon/human/H = find_nearby_human(M, 5)
	if(H && S.role == FAUNA_ROLE_PREY)
		d += 0.5
		q -= 0.4

	if(get_dist(M, home) <= 3 && !predator && !H)
		q += 0.5 // den "improves" while safely occupied

	var/current_season = round((world.time / 30000) % 4)
	var/prev_season = home_season[mkey]
	if(isnull(prev_season))
		prev_season = current_season
	if(prev_season != current_season)
		home_season[mkey] = current_season
		// seasonal relocation: low-quality dens are more likely to be abandoned
		if(q < 45 || prob(18))
			var/turf/backup = home_backup[mkey]
			if(backup && is_valid_turf(backup))
				set_home_turf(M, backup)
			else
				var/turf/seasonal_home = pick_spread_turf(home, FAUNA_HOME_ASSIGN_MAX, FAUNA_HOME_ASSIGN_MAX + 14)
				if(seasonal_home)
					set_home_turf(M, seasonal_home)
			set_intent(M, FAUNA_STATE_RETURN_HOME, rand(25, 50))

	if(d >= FAUNA_HOME_DANGER_RELOCATE)
		var/turf/new_home = home_backup[mkey]
		if(!new_home || !is_valid_turf(new_home))
			new_home = pick_spread_turf(home, FAUNA_HOME_ASSIGN_MAX, FAUNA_HOME_ASSIGN_MAX + 12)
		if(new_home)
			set_home_turf(M, new_home)
			set_intent(M, FAUNA_STATE_RETURN_HOME, rand(25, 50))
		d = 0
		q = max(25, q - 8)

	home_danger[mkey] = d
	home_quality[mkey] = clamp(q, 0, FAUNA_DEN_QUALITY_MAX)

// ============== PACK FORMATION HELPERS ==============

/datum/controller/subsystem/fauna_ecosystem/proc/_ref_hash(atom/A)
	// cheap stable-ish hash from ref string (doesn't need to be cryptographically good)
	if(!A) return 0
	var/t = "\ref[A]"
	var/acc = 0
	var/len = length(t)
	for(var/i in 1 to len)
		acc = (acc * 33 + text2ascii(t, i)) % 2147483647
	return acc

/datum/controller/subsystem/fauna_ecosystem/proc/get_pack_slot_turf(mob/leader, mob/member, dist = 2)
	// Each member gets a stable slot around the leader so the pack doesn’t stack/yo-yo.
	var/turf/L = get_turf(leader)
	if(!L) return null

	var/h = (_ref_hash(leader) + _ref_hash(member)) % 8
	var/dx = 0
	var/dy = 0

	switch(h)
		if(0) { dx =  dist; dy =  0 }
		if(1) { dx = -dist; dy =  0 }
		if(2) { dx =  0; dy =  dist }
		if(3) { dx =  0; dy = -dist }
		if(4) { dx =  dist; dy =  dist }
		if(5) { dx = -dist; dy =  dist }
		if(6) { dx =  dist; dy = -dist }
		if(7) { dx = -dist; dy = -dist }

	var/x = clamp(L.x + dx, 1, world.maxx)
	var/y = clamp(L.y + dy, 1, world.maxy)
	var/turf/T = locate(x, y, L.z)
	if(T && is_valid_turf(T))
		return T

	// fallback: just orbit leader’s turf
	return L

// ============== ROAM HELPERS (NEW) ==============

/datum/controller/subsystem/fauna_ecosystem/proc/pick_long_roam_turf(mob/M, min_dist = FAUNA_ROAM_MIN, max_dist = FAUNA_ROAM_MAX)
	var/turf/origin = get_turf(M)
	if(!origin) return null

	for(var/i in 1 to FAUNA_ROAM_RETRY)
		var/angle = rand(0, 359)
		var/dist = rand(min_dist, max_dist)

		var/x = clamp(origin.x + cos(angle) * dist, 1, world.maxx)
		var/y = clamp(origin.y + sin(angle) * dist, 1, world.maxy)

		var/turf/T = locate(x, y, origin.z)
		if(T && is_valid_turf(T))
			return T

	return null

/datum/controller/subsystem/fauna_ecosystem/proc/roam_tick(mob/living/simple_animal/hostile/M, step_speed = FAUNA_ROAM_STEP_SPEED)
	var/key = mob_key(M)
	if(!key) return

	var/turf/goal = roam_goal[key]
	if(goal)
		// locate("\ref[turf]") works, but if goal got deleted/invalid, this falls through
		if(!istype(goal, /turf) || QDELETED(goal))
			goal = null

	if(!goal || get_dist(M, goal) < 3)
		goal = pick_long_roam_turf(M, FAUNA_ROAM_MIN, FAUNA_ROAM_MAX)
		if(goal)
			roam_goal[key] = goal
		else
			roam_goal -= key

	if(goal)
		step_toward_target(M, goal, step_speed)

// ============== INITIALIZATION ==============

/datum/controller/subsystem/fauna_ecosystem/Initialize(timeofday)
	. = ..()

	if(debug_logging)
		log_world("FAUNA: ===== INITIALIZING LIVING ECOSYSTEM =====")

	z_last_human = list()
	z_heat = list()
	for(var/z in 1 to world.maxz)
		z_last_human += 0
		z_heat += 0

	build_species()

	next_repro_tick = world.time + FAUNA_REPRO_EVERY

	if(debug_logging)
		var/mob_count = 0
		for(var/mob/living/simple_animal/hostile/M in world)
			var/datum/fauna_species/S = get_species_for_mob(M)
			if(S)
				mob_count++
		log_world("FAUNA: Found [mob_count] managed fauna mobs on map")

	return .

/datum/controller/subsystem/fauna_ecosystem/proc/build_species()
	// Prey
	register_species(new /datum/fauna_species/prey/radroach)
	register_species(new /datum/fauna_species/prey/bloatfly)
	register_species(new /datum/fauna_species/prey/molerat)
	register_species(new /datum/fauna_species/prey/giantant)
	register_species(new /datum/fauna_species/prey/fireant)

	// Ambush predators
	register_species(new /datum/fauna_species/ambush/gecko)
	register_species(new /datum/fauna_species/ambush/gecko_big)
	register_species(new /datum/fauna_species/ambush/radscorpion)

	// Pack hunters
	register_species(new /datum/fauna_species/hunter/stalkeryoung)
	register_species(new /datum/fauna_species/hunter/stalker)
	register_species(new /datum/fauna_species/hunter/cazador)

	// Apex
	register_species(new /datum/fauna_species/apex/mirelurk)
	register_species(new /datum/fauna_species/apex/mirelurk_hunter)

/datum/controller/subsystem/fauna_ecosystem/proc/register_species(datum/fauna_species/S)
	if(S?.id)
		species_defs[S.id] = S

/datum/controller/subsystem/fauna_ecosystem/proc/get_species_for_mob(mob/M)
	if(!M) return null
	for(var/id in species_defs)
		var/datum/fauna_species/S = species_defs[id]
		if(S && istype(M, S.mob_type))
			return S
	return null

// ============== MAIN LOOP ==============

/datum/controller/subsystem/fauna_ecosystem/fire(resumed = FALSE)
	process_cycle++

	if(debug_logging && process_cycle % 20 == 0)
		log_world("FAUNA: Tick [process_cycle] - [length(packs)] packs")

	track_humans()
	process_fauna_behaviors()

	if(process_cycle % FAUNA_PACK_PROCESS_EVERY == 0)
		process_packs()

	if(world.time >= next_repro_tick)
		process_reproduction()
		next_repro_tick = world.time + FAUNA_REPRO_EVERY

	if(process_cycle % 100 == 0)
		cleanup_stale_timers()
		cleanup_scent_trails()

	if(debug_logging && process_cycle % FAUNA_DEBUG_SUMMARY_EVERY == 0)
		log_world(fauna_debug_summary())

// ============== HUMAN TRACKING ==============

/datum/controller/subsystem/fauna_ecosystem/proc/track_humans()
	var/night_mult = is_night() ? FAUNA_HEAT_NIGHT_MULT : 1

	for(var/z in 1 to length(z_heat))
		z_heat[z] = max(0, z_heat[z] - FAUNA_HEAT_DECAY)

	for(var/mob/living/carbon/human/H in world)
		if(H.stat) continue
		var/turf/T = get_turf(H)
		if(!T) continue

		if(T.z <= length(z_last_human))
			z_last_human[T.z] = world.time
			z_heat[T.z] = min(FAUNA_HEAT_HARDCAP, z_heat[T.z] + (FAUNA_HEAT_FROM_HUMAN * night_mult))

/datum/controller/subsystem/fauna_ecosystem/proc/is_z_active(z)
	if(z < 1 || z > length(z_last_human))
		return FALSE
	return (world.time - z_last_human[z]) < FAUNA_Z_ACTIVE_TTL

// ============== FAUNA BEHAVIOR PROCESSING ==============

/datum/controller/subsystem/fauna_ecosystem/proc/process_fauna_behaviors()
	for(var/mob/living/simple_animal/hostile/M in world)
		if(QDELETED(M)) continue
		if(M.stat) continue
		if(!is_z_active(M.z)) continue

		var/datum/fauna_species/S = get_species_for_mob(M)
		if(!S) continue

		if(is_in_pack(M)) continue

		var/mkey = mob_key(M)
		ensure_mob_profile(M)
		tick_home_danger(M, S)
		maybe_social_tick(M, S)
		maybe_handle_territory_conflict(M, S)

		var/rest_until = rest_timers[mkey]
		if(rest_until && world.time < rest_until)
			var/turf/rest_here = get_turf(M)
			if(rest_here && is_valid_turf(rest_here))
				safe_spot[mkey] = rest_here
			continue

		// Intent lock keeps behavior from twitching every tick.
		if(intent_locked(M, FAUNA_STATE_INVESTIGATE))
			if(do_investigate_behavior(M))
				if(MC_TICK_CHECK) return
				continue
		if(intent_locked(M, FAUNA_STATE_RETURN_HOME))
			var/turf/home = get_home_turf(M)
			if(home)
				step_toward_target(M, home, 1)
				if(MC_TICK_CHECK) return
				continue
		if(intent_locked(M, FAUNA_STATE_ROAM))
			roam_tick(M, 1)
			if(MC_TICK_CHECK) return
			continue
		if(intent_locked(M, FAUNA_STATE_REST))
			if(prob(15))
				wander_randomly(M, 2)
			if(MC_TICK_CHECK) return
			continue
		if(intent_locked(M, FAUNA_STATE_GUARD_HOME))
			var/turf/home2 = get_home_turf(M)
			if(home2 && get_dist(M, home2) > 3)
				step_toward_target(M, home2, 1)
			else if(prob(20))
				wander_randomly(M, 2)
			if(MC_TICK_CHECK) return
			continue

		switch(S.role)
			if(FAUNA_ROLE_PREY)   do_prey_behavior(M, S)
			if(FAUNA_ROLE_AMBUSH) do_ambush_behavior(M, S)
			if(FAUNA_ROLE_HUNTER) do_hunter_behavior(M, S)
			if(FAUNA_ROLE_APEX)   do_apex_behavior(M, S)

		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/fauna_ecosystem/proc/is_in_pack(mob/M)
	for(var/datum/fauna_pack/P in packs)
		if(M in P.members)
			return TRUE
	return FALSE

/datum/controller/subsystem/fauna_ecosystem/proc/get_pack_for_mob(mob/M)
	if(!M) return null
	for(var/datum/fauna_pack/P in packs)
		if(M in P.members)
			return P
	return null

/// Prey
/datum/controller/subsystem/fauna_ecosystem/proc/do_prey_behavior(mob/living/simple_animal/hostile/M, datum/fauna_species/S)
	var/turf/my_turf = get_turf(M)
	if(!my_turf) return

	var/mkey = mob_key(M)
	ensure_home_turf(M)

	var/mob/living/predator = find_nearby_predator(M, FAUNA_SOLO_FLEE_RANGE)
	if(predator)
		var/pd = get_dist(M, predator)
		var/datum/fauna_species/predS = get_species_for_mob(predator)
		// Freeze at distance so prey doesn't always instantly sprint.
		if(pd >= 6 && prob(predS?.role == FAUNA_ROLE_AMBUSH ? 50 : 35))
			set_intent(M, FAUNA_STATE_REST, rand(8, 16))
			return

		// Mobbing: groups may harass predator briefly before disengaging.
		var/near_allies = count_nearby_same_species(M, 3)
		if(near_allies >= 3 && pd <= 5 && predS?.role < FAUNA_ROLE_APEX && prob(25))
			step_toward_target(M, predator, 1)
			set_intent(M, FAUNA_STATE_GUARD_HOME, rand(8, 18))
			return

		flee_from(M, predator)
		flee_memory[mkey] = mob_key(predator)
		remember_target_turf(threat_last_turf, M, predator)
		maybe_emit_flee_signal(M, predator)
		set_intent(M, FAUNA_STATE_FLEE, rand(18, 35))
		return

	var/threat_key = flee_memory[mkey]
	if(threat_key)
		var/mob/threat = get_mob_from_key(threat_key)
		if(threat && !QDELETED(threat) && threat.stat == 0 && get_dist(M, threat) < FAUNA_SOLO_FLEE_RANGE)
			flee_from(M, threat)
			remember_target_turf(threat_last_turf, M, threat)
			set_intent(M, FAUNA_STATE_FLEE, rand(18, 35))
			return
		else
			flee_memory -= mkey

	if(prob(12))
		var/mob/friend = find_nearby_same_species(M, FAUNA_SOLO_FIND_FRIENDS_RANGE)
		if(friend && get_dist(M, friend) > 2)
			step_toward_target(M, friend, 1)
			set_intent(M, FAUNA_STATE_GUARD_HOME, rand(15, 30))
			return

	// Off-cycle species drift back home and rest.
	if((S.nocturnal && !is_night()) || (!S.nocturnal && is_night()))
		var/turf/home = get_home_turf(M)
		if(home && get_dist(M, home) > 2)
			step_toward_target(M, home, 1)
			set_intent(M, FAUNA_STATE_RETURN_HOME, rand(20, 45))
			return
		if(prob(12))
			rest_timers[mkey] = world.time + rand(30, 90)
			set_intent(M, FAUNA_STATE_REST, rand(20, 40))
			return

	// Long roam, but avoid drifting forever from den.
	var/turf/home2 = get_home_turf(M)
	if(home2 && get_dist(M, home2) > FAUNA_HOME_PULL_DIST)
		step_toward_target(M, home2, 1)
		set_intent(M, FAUNA_STATE_RETURN_HOME, rand(18, 40))
		return
	var/turf/safe = safe_spot[mkey]
	if(safe && is_valid_turf(safe) && get_dist(M, safe) > 4 && prob(18))
		step_toward_target(M, safe, 1)
		set_intent(M, FAUNA_STATE_RETURN_HOME, rand(15, 30))
		return
	if(prob(FAUNA_INVESTIGATE_CHANCE))
		var/mob/living/carbon/human/H = find_nearby_human(M, FAUNA_INVESTIGATE_RANGE)
		if(H)
			if(try_start_investigation(M, get_turf(H)))
				return
	if(prob(FAUNA_SOLO_WANDER_CHANCE))
		roam_tick(M, 1)
		set_intent(M, FAUNA_STATE_ROAM, rand(20, 55))

/// Ambush
/datum/controller/subsystem/fauna_ecosystem/proc/do_ambush_behavior(mob/living/simple_animal/hostile/M, datum/fauna_species/S)
	var/turf/my_turf = get_turf(M)
	if(!my_turf) return

	var/mkey = mob_key(M)
	ensure_home_turf(M)
	var/fail_until = failed_hunt_until[mkey]
	if(fail_until && world.time < fail_until)
		if(prob(22))
			roam_tick(M, 1)
			set_intent(M, FAUNA_STATE_ROAM, rand(20, 45))
		return

	var/hunt_key = hunt_memory[mkey]
	if(hunt_key)
		var/mob/prey = get_mob_from_key(hunt_key)
		if(prey && !QDELETED(prey) && prey.stat == 0)
			var/d = get_dist(M, prey)
			if(d <= FAUNA_PREDATOR_KILL_RANGE)
				attack_prey(M, prey)
				hunt_memory -= mkey
				chase_until -= mkey
				set_intent(M, FAUNA_STATE_HUNT, rand(18, 35))
				return
			else if(d < FAUNA_PREDATOR_HUNT_RANGE)
				if(!chase_until[mkey])
					chase_until[mkey] = world.time + FAUNA_STALK_CHASE_TTL
				if(world.time >= chase_until[mkey])
					hunt_memory -= mkey
					chase_until -= mkey
					failed_hunt_until[mkey] = world.time + rand(70, 140)
					set_intent(M, FAUNA_STATE_INVESTIGATE, rand(20, 35))
					return
				if(prob(35) && d > 3)
					// stalking pause instead of constant beeline.
					set_intent(M, FAUNA_STATE_INVESTIGATE, rand(10, 18))
					return
				step_toward_target(M, prey, FAUNA_PREDATOR_CHASE_SPEED)
				remember_target_turf(prey_last_turf, M, prey)
				maybe_emit_hunt_signal(M, prey)
				set_intent(M, FAUNA_STATE_HUNT, rand(20, 40))
				return
		var/turf/last_prey = prey_last_turf[mkey]
		hunt_memory -= mkey
		if(last_prey)
			try_start_investigation(M, last_prey)
			return

	var/mob/prey = find_nearby_prey(M, FAUNA_PREDATOR_HUNT_RANGE)
	if(prey)
		hunt_memory[mkey] = mob_key(prey)
		chase_until[mkey] = world.time + FAUNA_STALK_CHASE_TTL
		step_toward_target(M, prey, FAUNA_PREDATOR_CHASE_SPEED)
		remember_target_turf(prey_last_turf, M, prey)
		maybe_emit_hunt_signal(M, prey)
		set_intent(M, FAUNA_STATE_HUNT, rand(20, 40))
		return

	var/mob/human = find_nearby_human(M, FAUNA_PREDATOR_HUNT_RANGE + 2)
	if(human)
		step_toward_target(M, human, FAUNA_PREDATOR_CHASE_SPEED)
		remember_target_turf(prey_last_turf, M, human)
		maybe_emit_hunt_signal(M, human)
		set_intent(M, FAUNA_STATE_HUNT, rand(20, 40))
		return

	// roam sometimes; ambushers should still reposition over time
	if(prob(FAUNA_INVESTIGATE_CHANCE))
		var/turf/remembered = prey_last_turf[mkey]
		if(remembered && try_start_investigation(M, remembered))
			return
	if(prob(18))
		roam_tick(M, 1)
		set_intent(M, FAUNA_STATE_ROAM, rand(20, 55))

	// Resting behavior (toned)
	if(S.nocturnal && !is_night())
		if(prob(18))
			rest_timers[mkey] = world.time + rand(40, 120)
			set_intent(M, FAUNA_STATE_REST, rand(25, 50))
	else if(!S.nocturnal && is_night())
		if(prob(16))
			rest_timers[mkey] = world.time + rand(40, 120)
			set_intent(M, FAUNA_STATE_REST, rand(25, 50))

/// Hunter
/datum/controller/subsystem/fauna_ecosystem/proc/do_hunter_behavior(mob/living/simple_animal/hostile/M, datum/fauna_species/S)
	var/mkey = mob_key(M)
	ensure_home_turf(M)
	var/fail_until = failed_hunt_until[mkey]
	if(fail_until && world.time < fail_until)
		if(prob(26))
			roam_tick(M, 1)
			set_intent(M, FAUNA_STATE_ROAM, rand(20, 45))
		return

	if(prob(16)) // toned down from 28
		try_join_or_form_pack(M, S)
		return

	var/hunt_key = hunt_memory[mkey]
	if(hunt_key)
		var/mob/prey = get_mob_from_key(hunt_key)
		if(prey && !QDELETED(prey) && prey.stat == 0)
			var/d = get_dist(M, prey)
			if(d <= FAUNA_PREDATOR_KILL_RANGE)
				attack_prey(M, prey)
				hunt_memory -= mkey
				chase_until -= mkey
				set_intent(M, FAUNA_STATE_HUNT, rand(18, 35))
				return
			else if(d < FAUNA_PACK_GIVE_UP_RANGE)
				if(!chase_until[mkey])
					chase_until[mkey] = world.time + FAUNA_STALK_CHASE_TTL
				if(world.time >= chase_until[mkey])
					hunt_memory -= mkey
					chase_until -= mkey
					failed_hunt_until[mkey] = world.time + rand(80, 160)
					set_intent(M, FAUNA_STATE_INVESTIGATE, rand(20, 35))
					return
				if(prob(28) && d > 4)
					// stalking beat to avoid robotic sprinting.
					set_intent(M, FAUNA_STATE_INVESTIGATE, rand(8, 16))
					return
				step_toward_target(M, prey, FAUNA_PREDATOR_CHASE_SPEED)
				remember_target_turf(prey_last_turf, M, prey)
				maybe_emit_hunt_signal(M, prey)
				set_intent(M, FAUNA_STATE_HUNT, rand(22, 45))
				return
		var/turf/last_prey = prey_last_turf[mkey]
		hunt_memory -= mkey
		if(last_prey)
			try_start_investigation(M, last_prey)
			return

	var/mob/prey = find_nearby_prey(M, FAUNA_PREDATOR_HUNT_RANGE)
	if(prey)
		hunt_memory[mkey] = mob_key(prey)
		chase_until[mkey] = world.time + FAUNA_STALK_CHASE_TTL
		step_toward_target(M, prey, FAUNA_PREDATOR_CHASE_SPEED)
		remember_target_turf(prey_last_turf, M, prey)
		maybe_emit_hunt_signal(M, prey)
		set_intent(M, FAUNA_STATE_HUNT, rand(22, 45))
		return

	var/mob/human = find_nearby_human(M, FAUNA_PACK_HUNT_RANGE)
	if(human)
		step_toward_target(M, human, FAUNA_PREDATOR_CHASE_SPEED)
		remember_target_turf(prey_last_turf, M, human)
		maybe_emit_hunt_signal(M, human)
		set_intent(M, FAUNA_STATE_HUNT, rand(22, 45))
		return

	// Hunters roam a lot when not actively hunting
	var/turf/home = get_home_turf(M)
	if(home && get_dist(M, home) > FAUNA_HOME_PULL_DIST + 4)
		step_toward_target(M, home, 1)
		set_intent(M, FAUNA_STATE_RETURN_HOME, rand(20, 45))
		return
	if(prob(FAUNA_INVESTIGATE_CHANCE))
		var/turf/remembered = prey_last_turf[mkey]
		if(remembered && try_start_investigation(M, remembered))
			return
	if(prob(35))
		roam_tick(M, 1)
		set_intent(M, FAUNA_STATE_ROAM, rand(20, 55))

/// Apex
/datum/controller/subsystem/fauna_ecosystem/proc/do_apex_behavior(mob/living/simple_animal/hostile/M, datum/fauna_species/S)
	var/mkey = mob_key(M)
	ensure_home_turf(M)
	var/fail_until = failed_hunt_until[mkey]
	if(fail_until && world.time < fail_until)
		if(prob(20))
			roam_tick(M, 1)
			set_intent(M, FAUNA_STATE_ROAM, rand(20, 45))
		return

	var/hunt_key = hunt_memory[mkey]
	if(hunt_key)
		var/mob/prey = get_mob_from_key(hunt_key)
		if(prey && !QDELETED(prey) && prey.stat == 0)
			var/d = get_dist(M, prey)
			if(d <= FAUNA_PREDATOR_KILL_RANGE)
				attack_prey(M, prey)
				hunt_memory -= mkey
				chase_until -= mkey
				set_intent(M, FAUNA_STATE_HUNT, rand(20, 40))
				return
			else if(d < FAUNA_PACK_GIVE_UP_RANGE)
				if(!chase_until[mkey])
					chase_until[mkey] = world.time + FAUNA_STALK_CHASE_TTL
				if(world.time >= chase_until[mkey])
					hunt_memory -= mkey
					chase_until -= mkey
					failed_hunt_until[mkey] = world.time + rand(90, 170)
					set_intent(M, FAUNA_STATE_INVESTIGATE, rand(22, 38))
					return
				if(prob(22) && d > 4)
					set_intent(M, FAUNA_STATE_INVESTIGATE, rand(8, 15))
					return
				step_toward_target(M, prey, FAUNA_PREDATOR_CHASE_SPEED)
				remember_target_turf(prey_last_turf, M, prey)
				maybe_emit_hunt_signal(M, prey)
				set_intent(M, FAUNA_STATE_HUNT, rand(24, 50))
				return
		var/turf/last_prey = prey_last_turf[mkey]
		hunt_memory -= mkey
		if(last_prey)
			try_start_investigation(M, last_prey)
			return

	var/mob/target = find_any_nearby_fauna(M, FAUNA_PREDATOR_HUNT_RANGE + 3)
	if(target)
		hunt_memory[mkey] = mob_key(target)
		chase_until[mkey] = world.time + FAUNA_STALK_CHASE_TTL
		step_toward_target(M, target, FAUNA_PREDATOR_CHASE_SPEED)
		remember_target_turf(prey_last_turf, M, target)
		maybe_emit_hunt_signal(M, target)
		set_intent(M, FAUNA_STATE_HUNT, rand(24, 50))
		return

	var/mob/human = find_nearby_human(M, FAUNA_PACK_HUNT_RANGE + 2)
	if(human)
		step_toward_target(M, human, FAUNA_PREDATOR_CHASE_SPEED)
		remember_target_turf(prey_last_turf, M, human)
		maybe_emit_hunt_signal(M, human)
		set_intent(M, FAUNA_STATE_HUNT, rand(24, 50))
		return

	// Apex wander is mostly long roam, but less frequent
	var/turf/home = get_home_turf(M)
	if(home && get_dist(M, home) > FAUNA_HOME_PULL_DIST + 8)
		step_toward_target(M, home, 1)
		set_intent(M, FAUNA_STATE_RETURN_HOME, rand(20, 45))
		return
	if(prob(FAUNA_INVESTIGATE_CHANCE))
		var/turf/remembered = prey_last_turf[mkey]
		if(remembered && try_start_investigation(M, remembered))
			return
	if(prob(20))
		roam_tick(M, 1)
		set_intent(M, FAUNA_STATE_ROAM, rand(20, 55))

// ============== PACK BEHAVIOR ==============

/datum/fauna_pack
	var/id = 0
	var/list/members = list()
	var/z = 1
	var/role = FAUNA_ROLE_HUNTER
	var/species_id = null

	var/list/waypoints = list()
	var/current_waypoint = 1
	var/turf/goal = null
	var/turf/home = null
	var/list/member_roles = list() // "\ref[mob]" -> "scout"|"rear"|"core"

	var/hunt_target_key = null
	var/hunting = FALSE

/datum/controller/subsystem/fauna_ecosystem/proc/try_join_or_form_pack(mob/living/simple_animal/hostile/M, datum/fauna_species/S)
	var/turf/my_turf = get_turf(M)
	if(!my_turf) return

	for(var/datum/fauna_pack/P in packs)
		if(P.species_id != S.id) continue
		if(P.z != M.z) continue
		if(length(P.members) >= 6) continue // toned down from 9

		for(var/mob/member in P.members)
			if(QDELETED(member)) continue
			if(get_dist(M, member) < FAUNA_PACK_COHESION_DIST)
				P.members += M
				if(debug_logging)
					log_world("FAUNA: [M.type] joined pack [P.id]")
				return

	var/list/nearby = list()
	for(var/mob/living/simple_animal/hostile/other in range(FAUNA_PACK_COHESION_DIST, M))
		if(other == M) continue
		if(QDELETED(other)) continue
		if(other.stat) continue
		if(is_in_pack(other)) continue

		var/datum/fauna_species/other_S = get_species_for_mob(other)
		if(other_S?.id == S.id)
			nearby += other

	// need 3 total now (toned)
	if(length(nearby) >= 2)
		var/datum/fauna_pack/P = new
		P.id = rand(1, 999999999)
		P.z = M.z
		P.species_id = S.id
		P.role = S.role
		P.members = list(M) + nearby
		P.home = my_turf
		for(var/mob/living/simple_animal/hostile/member in P.members)
			set_home_turf(member, my_turf)

		setup_pack_patrol(P, my_turf)
		packs += P

		if(debug_logging)
			log_world("FAUNA: New pack [P.id] formed with [length(P.members)] [S.id]")

/datum/controller/subsystem/fauna_ecosystem/proc/setup_pack_patrol(datum/fauna_pack/P, turf/center)
	P.waypoints = list()
	if(!P.home)
		P.home = center

	for(var/i in 1 to FAUNA_PACK_WAYPOINT_COUNT)
		var/angle = (360 / FAUNA_PACK_WAYPOINT_COUNT) * i
		var/dx = cos(angle) * FAUNA_HOME_PATROL_RADIUS
		var/dy = sin(angle) * FAUNA_HOME_PATROL_RADIUS

		var/wx = clamp(center.x + dx, 1, world.maxx)
		var/wy = clamp(center.y + dy, 1, world.maxy)

		var/turf/T = locate(wx, wy, P.z)
		if(T && is_valid_turf(T))
			P.waypoints += T

	if(length(P.waypoints))
		P.goal = P.waypoints[1]
		P.current_waypoint = 1

/datum/controller/subsystem/fauna_ecosystem/proc/update_pack_structure(datum/fauna_pack/P)
	if(!P || !length(P.members)) return

	// leadership challenge: dominant member can take lead
	if(length(P.members) >= 3 && prob(3))
		var/mob/new_leader = P.members[1]
		var/best = dominance_rank[mob_key(new_leader)]
		for(var/mob/living/simple_animal/hostile/M in P.members)
			var/score = dominance_rank[mob_key(M)]
			if(isnull(score)) score = 0
			if(score > best)
				best = score
				new_leader = M
		if(new_leader && new_leader != P.members[1])
			P.members -= new_leader
			P.members.Insert(1, new_leader)
			if(debug_logging)
				log_world("FAUNA: Pack [P.id] leadership challenge won by [new_leader.type]")

	P.member_roles = list()
	var/len = length(P.members)
	if(len <= 1) return

	// assign scout / rear guard / core roles
	var/mob/scout = P.members[2]
	if(scout) P.member_roles[mob_key(scout)] = "scout"
	if(len >= 3)
		var/mob/rear = P.members[len]
		if(rear && rear != scout) P.member_roles[mob_key(rear)] = "rear"

	for(var/i in 2 to len)
		var/mob/member = P.members[i]
		if(!member) continue
		var/key = mob_key(member)
		if(!(key in P.member_roles))
			P.member_roles[key] = "core"

/datum/controller/subsystem/fauna_ecosystem/proc/process_packs()
	var/list/to_remove = list()
	var/list/to_add = list()

	for(var/datum/fauna_pack/P in packs)
		var/list/alive = list()
		for(var/mob/M in P.members)
			if(!QDELETED(M) && M.stat == 0)
				alive += M
		P.members = alive

		if(!length(P.members))
			to_remove += P
			continue

		if(!is_z_active(P.z))
			continue

		update_pack_structure(P)
		process_pack_behavior(P)

		// split oversized packs into two roaming groups
		if(length(P.members) > 6)
			var/datum/fauna_pack/N = new
			N.id = rand(1, 999999999)
			N.z = P.z
			N.species_id = P.species_id
			N.role = P.role
			N.home = P.home

			var/split_at = round(length(P.members) / 2)
			N.members = P.members.Copy(split_at + 1)
			P.members.Cut(split_at + 1)
			setup_pack_patrol(N, N.home ? N.home : get_turf(N.members[1]))
			to_add += N
			if(debug_logging)
				log_world("FAUNA: Pack [P.id] split into [P.id] + [N.id]")

		if(MC_TICK_CHECK)
			break

	packs -= to_remove
	packs += to_add

/datum/controller/subsystem/fauna_ecosystem/proc/process_pack_behavior(datum/fauna_pack/P)
	if(!length(P.members)) return

	var/mob/leader = P.members[1]
	var/turf/leader_turf = get_turf(leader)
	if(!leader_turf) return
	if(!P.home)
		P.home = leader_turf

	for(var/mob/living/simple_animal/hostile/member in P.members)
		ensure_mob_profile(member)
		ensure_home_turf(member)

	// Priority: Hunt players
	var/mob/human = find_nearby_human(leader, FAUNA_PACK_HUNT_RANGE)
	if(human)
		P.hunting = TRUE
		P.hunt_target_key = mob_key(human)
		maybe_emit_hunt_signal(leader, human)

		// leader pushes the hunt
		if(!QDELETED(leader))
			step_toward_target(leader, human, FAUNA_PACK_MOVE_SPEED)

		// followers keep formation; only nudge 1 step
		for(var/mob/living/simple_animal/hostile/M in P.members)
			if(M == leader) continue
			if(QDELETED(M)) continue

			var/role = P.member_roles[mob_key(M)]
			if(role == "scout")
				var/turf/flank_h = choose_flank_turf(M, human)
				if(flank_h)
					step_toward_target(M, flank_h, 1)
					continue
			var/slot_dist = (role == "rear") ? 3 : 2
			var/turf/slot = get_pack_slot_turf(leader, M, slot_dist)
			if(slot && get_dist(M, slot) > 0)
				step_toward_target(M, slot, 1)

		if(debug_logging)
			log_world("FAUNA: Pack [P.id] hunting player")
		return

	// Priority: Hunt prey
	var/mob/prey = find_nearby_prey(leader, FAUNA_PREDATOR_HUNT_RANGE)
	if(prey)
		P.hunt_target_key = mob_key(prey)
		maybe_emit_hunt_signal(leader, prey)

		if(!QDELETED(leader))
			hunt_memory[mob_key(leader)] = mob_key(prey)
			step_toward_target(leader, prey, FAUNA_PACK_MOVE_SPEED)

		for(var/mob/living/simple_animal/hostile/M in P.members)
			if(M == leader) continue
			if(QDELETED(M)) continue
			hunt_memory[mob_key(M)] = mob_key(prey)

			var/role = P.member_roles[mob_key(M)]
			if(role == "scout")
				var/turf/flank_p = choose_flank_turf(M, prey)
				if(flank_p)
					step_toward_target(M, flank_p, 1)
					continue

			var/slot_dist = (role == "rear") ? 3 : 2
			var/turf/slot = get_pack_slot_turf(leader, M, slot_dist)
			if(slot && get_dist(M, slot) > 0)
				step_toward_target(M, slot, 1)

		return

	// Patrol mode
	P.hunting = FALSE
	P.hunt_target_key = null

	// Nocturnal packs prefer returning to den during daytime.
	var/datum/fauna_species/pack_S = get_species_for_mob(leader)
	if(pack_S?.nocturnal && !is_night() && P.home)
		if(get_dist(leader, P.home) > 2)
			step_toward_target(leader, P.home, 1)
		for(var/mob/living/simple_animal/hostile/M in P.members)
			if(M == leader) continue
			if(QDELETED(M)) continue
			var/turf/slot_home = get_pack_slot_turf(leader, M, 2)
			if(slot_home && get_dist(M, slot_home) > 0)
				step_toward_target(M, slot_home, 1)
		return

	if(!P.goal && length(P.waypoints))
		P.goal = P.waypoints[P.current_waypoint]

	if(P.goal)
		if(get_dist(leader, P.goal) < 3)
			P.current_waypoint++
			if(P.current_waypoint > length(P.waypoints))
				P.current_waypoint = 1
			if(length(P.waypoints))
				P.goal = P.waypoints[P.current_waypoint]

		// Leader drives patrol
		if(!QDELETED(leader))
			step_toward_target(leader, P.goal, FAUNA_PACK_MOVE_SPEED)

		// Followers keep formation
		for(var/mob/living/simple_animal/hostile/M in P.members)
			if(M == leader) continue
			if(QDELETED(M)) continue

			var/role = P.member_roles[mob_key(M)]
			var/slot_dist = (role == "rear") ? 3 : 2
			var/turf/slot = get_pack_slot_turf(leader, M, slot_dist)
			if(!slot) continue

			if(get_dist(M, leader) > FAUNA_PACK_COHESION_DIST)
				step_toward_target(M, slot, 2)
			else if(get_dist(M, slot) > 0)
				step_toward_target(M, slot, 1)

// ============== REPRODUCTION ==============

/datum/controller/subsystem/fauna_ecosystem/proc/get_nest_turf(mob/living/simple_animal/hostile/M)
	var/key = mob_key(M)
	if(!key) return null
	var/turf/N = nest_site[key]
	if(!N || QDELETED(N) || !is_valid_turf(N))
		return null
	var/expire = nest_expires[key]
	if(expire && world.time >= expire)
		nest_site -= key
		nest_expires -= key
		return null
	return N

/datum/controller/subsystem/fauna_ecosystem/proc/set_nest_turf(mob/living/simple_animal/hostile/M, turf/N)
	var/key = mob_key(M)
	if(!key || !N || !is_valid_turf(N)) return
	nest_site[key] = N
	nest_expires[key] = world.time + FAUNA_NEST_DECAY

/datum/controller/subsystem/fauna_ecosystem/proc/clear_repro_state(mob/living/simple_animal/hostile/M)
	var/key = mob_key(M)
	if(!key) return
	gestation_until -= key
	mate_target -= key

/datum/controller/subsystem/fauna_ecosystem/proc/find_mate_candidate(mob/living/simple_animal/hostile/parent, datum/fauna_species/S)
	if(!parent || !S) return null
	var/mob/living/simple_animal/hostile/best = null
	var/best_d = 99999

	for(var/mob/living/simple_animal/hostile/M in range(FAUNA_MATE_SEARCH_RANGE, parent))
		if(M == parent) continue
		if(QDELETED(M) || M.stat) continue

		var/datum/fauna_species/MS = get_species_for_mob(M)
		if(!MS || MS.id != S.id) continue

		var/mkey = mob_key(M)
		if(!mkey) continue
		if(gestation_until[mkey]) continue
		if(repro_cooldowns[mkey] && world.time < repro_cooldowns[mkey]) continue
		if(mate_target[mkey]) continue

		var/d = get_dist(parent, M)
		if(d < best_d)
			best_d = d
			best = M

	return best

/datum/controller/subsystem/fauna_ecosystem/proc/choose_nest_site(mob/living/simple_animal/hostile/A, mob/living/simple_animal/hostile/B)
	if(!A || !B) return null
	var/turf/AT = get_turf(A)
	var/turf/BT = get_turf(B)
	if(!AT || !BT) return null

	// Prefer existing den/home between pair first.
	var/turf/AH = get_home_turf(A)
	if(AH && get_dist(B, AH) <= FAUNA_MATE_SEARCH_RANGE && is_valid_turf(AH))
		return AH
	var/turf/BH = get_home_turf(B)
	if(BH && get_dist(A, BH) <= FAUNA_MATE_SEARCH_RANGE && is_valid_turf(BH))
		return BH

	var/mx = round((AT.x + BT.x) / 2)
	var/my = round((AT.y + BT.y) / 2)
	var/turf/mid = locate(clamp(mx, 1, world.maxx), clamp(my, 1, world.maxy), AT.z)
	if(mid && is_valid_turf(mid))
		return mid

	return pick_spread_turf(AT, 1, 4)

/datum/controller/subsystem/fauna_ecosystem/proc/start_pair_gestation(mob/living/simple_animal/hostile/A, mob/living/simple_animal/hostile/B, turf/N)
	if(!A || !B || !N) return FALSE
	var/akey = mob_key(A)
	var/bkey = mob_key(B)
	if(!akey || !bkey) return FALSE

	var/gest = world.time + rand(FAUNA_GESTATION_MIN, FAUNA_GESTATION_MAX)
	gestation_until[akey] = gest
	gestation_until[bkey] = gest
	mate_target[akey] = bkey
	mate_target[bkey] = akey
	set_nest_turf(A, N)
	set_nest_turf(B, N)
	set_home_turf(A, N)
	set_home_turf(B, N)
	set_intent(A, FAUNA_STATE_GUARD_HOME, rand(24, 55))
	set_intent(B, FAUNA_STATE_GUARD_HOME, rand(24, 55))
	return TRUE

/datum/controller/subsystem/fauna_ecosystem/proc/spawn_from_nest(mob/living/simple_animal/hostile/parent, datum/fauna_species/S, turf/N)
	if(!parent || !S || !N) return 0
	var/spawned = 0
	var/children = rand(FAUNA_REPRO_CHILDREN_MIN, FAUNA_REPRO_CHILDREN_MAX)
	var/pkey = mob_key(parent)
	var/den_q = pkey ? home_quality[pkey] : null

	if(S.role == FAUNA_ROLE_PREY)
		children += rand(1, 2)
		if(prob(25))
			children++
	else if(S.role == FAUNA_ROLE_HUNTER)
		if(prob(35))
			children++
	else if(S.role == FAUNA_ROLE_APEX)
		if(prob(55))
			children--

	if(!isnull(den_q) && den_q >= 70 && prob(45))
		children++

	// Roaches/flies were over-scaling population pressure; keep litters small.
	if(S.id == "radroach")
		children = max(1, round(children * 0.45))
	else if(S.id == "bloatfly")
		children = max(1, round(children * 0.55))

	children = clamp(children, 1, 6)

	for(var/i in 1 to children)
		var/turf/T = pick_spread_turf(N, 1, 3)
		if(!T) T = N

		var/mob/living/simple_animal/hostile/child = new S.mob_type(T)
		if(child)
			spawned++
			set_home_turf(child, N)
			set_nest_turf(child, N)
			if(prob(35))
				set_intent(child, FAUNA_STATE_GUARD_HOME, rand(20, 45))
			else if(prob(45))
				roam_tick(child, 1)

	return spawned

/datum/controller/subsystem/fauna_ecosystem/proc/process_reproduction()
	set background = 1

	if(debug_logging)
		log_world("FAUNA: === REPRODUCTION PASS ===")

	var/births = 0
	var/pairs_started = 0
	var/offspring_spawned = 0
	var/list/species_count_cache = list()

	for(var/mob/living/simple_animal/hostile/parent in world)
		if(QDELETED(parent)) continue
		if(parent.stat) continue
		if(!is_z_active(parent.z))
			// Still allow map fauna to breed when players are physically nearby.
			if(!find_nearby_human(parent, FAUNA_MATE_SEARCH_RANGE + 6))
				continue

		var/datum/fauna_species/S = get_species_for_mob(parent)
		if(!S) continue

		var/pkey = mob_key(parent)
		if(!pkey) continue

		ensure_home_turf(parent)
		ensure_mob_profile(parent)
		var/pop_key = "[S.id]@[parent.z]"
		var/current_pop = species_count_cache[pop_key]
		if(isnull(current_pop))
			current_pop = count_species_on_z(S, parent.z)
			species_count_cache[pop_key] = current_pop

		// Gestating pairs stay around nest and then deliver.
		var/gest = gestation_until[pkey]
		if(gest)
			var/turf/N = get_nest_turf(parent)
			if(!N)
				N = get_home_turf(parent)
				if(N)
					set_nest_turf(parent, N)

			var/mate_key = mate_target[pkey]
			var/mob/living/simple_animal/hostile/mate = get_mob_from_key(mate_key)
			if(!mate || QDELETED(mate) || mate.stat)
				clear_repro_state(parent)
				if(N)
					nest_expires[pkey] = world.time + (FAUNA_NEST_DECAY / 2)
				continue

			if(world.time < gest)
				if(N && get_dist(parent, N) > FAUNA_NEST_STAY_RADIUS)
					step_toward_target(parent, N, 1)
					set_intent(parent, FAUNA_STATE_RETURN_HOME, rand(18, 40))
				else if(N && prob(30))
					set_intent(parent, FAUNA_STATE_GUARD_HOME, rand(14, 32))
				continue

			if(current_pop >= S.hardcap)
				clear_repro_state(parent)
				repro_cooldowns[pkey] = world.time + (FAUNA_REPRO_COOLDOWN / 2)
				continue

			var/spawned = spawn_from_nest(parent, S, N)
			if(spawned > 0)
				births++
				offspring_spawned += spawned
				repro_cooldowns[pkey] = world.time + FAUNA_REPRO_COOLDOWN
				var/mkey = mob_key(mate)
				if(mkey)
					repro_cooldowns[mkey] = world.time + FAUNA_REPRO_COOLDOWN
					clear_repro_state(mate)
				home_quality[pkey] = clamp((home_quality[pkey] || 50) + 2, 0, FAUNA_DEN_QUALITY_MAX)
				species_count_cache[pop_key] = current_pop + spawned
				if(debug_logging)
					log_world("FAUNA: [S.id] nest delivery by [parent.type], [spawned] offspring at ([N ? N.x : 0],[N ? N.y : 0],[parent.z])")
			clear_repro_state(parent)
			if(offspring_spawned >= FAUNA_REPRO_MAX_OFFSPRING_PASS)
				if(debug_logging)
					log_world("FAUNA: reproduction pass reached offspring budget ([offspring_spawned]/[FAUNA_REPRO_MAX_OFFSPRING_PASS])")
				break
			continue

		var/cd = repro_cooldowns[pkey]
		if(cd && world.time < cd)
			continue

		if(current_pop >= S.hardcap)
			continue

		var/turf/origin = get_turf(parent)
		if(!origin || !is_valid_turf(origin))
			continue
		var/turf/home = get_home_turf(parent)
		if(home)
			if(get_dist(parent, home) > 6 && prob(70))
				continue
			origin = home

		var/nearby_same = count_nearby_same_species(parent, FAUNA_CROWD_RADIUS)
		if(nearby_same >= FAUNA_CROWD_THRESHOLD && prob(25))
			disperse_mob(parent)

		var/chance = FAUNA_REPRO_CHANCE
		if(is_night() && S.nocturnal)
			chance *= 1.25
		else if(!is_night() && !S.nocturnal)
			chance *= 1.15

		if(current_pop < round(S.hardcap * 0.30))
			chance += FAUNA_REPRO_LOWPOP_BOOST_HIGH
		else if(current_pop < round(S.hardcap * 0.55))
			chance += FAUNA_REPRO_LOWPOP_BOOST_MID
		else if(current_pop > round(S.hardcap * 0.90))
			chance -= 10

		if(S.role == FAUNA_ROLE_PREY)
			chance += 8
		else if(S.role == FAUNA_ROLE_APEX)
			chance -= 6

		// Tune down explosive low-tier insect growth.
		if(S.id == "radroach")
			chance -= 22
		else if(S.id == "bloatfly")
			chance -= 16

		var/den_q = home_quality[pkey]
		if(!isnull(den_q))
			chance += round((den_q - 50) / 20)

		if(nearby_same <= 1 && current_pop < round(S.hardcap * 0.70))
			chance += 6

		chance = clamp(chance, FAUNA_REPRO_CHANCE_MIN, FAUNA_REPRO_CHANCE_MAX)
		if(!prob(chance))
			continue

		if(mate_target[pkey] || gestation_until[pkey])
			continue

		var/mob/living/simple_animal/hostile/mate = find_mate_candidate(parent, S)
		if(!mate)
			var/solo_threshold = (S.role == FAUNA_ROLE_PREY) ? (FAUNA_REPRO_LOWPOP_SOLO_THRESH / 100) : 0.30
			if(current_pop >= round(S.hardcap * solo_threshold))
				continue
			var/solo_chance = FAUNA_REPRO_LOWPOP_SOLO_CHANCE
			if(S.role != FAUNA_ROLE_PREY)
				solo_chance = 8
			if(S.id == "radroach")
				solo_chance = max(4, round(solo_chance * 0.50))
			else if(S.id == "bloatfly")
				solo_chance = max(5, round(solo_chance * 0.65))
			if(!prob(solo_chance))
				continue
			mate = parent
		var/mkey = mob_key(mate)
		if(!mkey) continue

		if(mate != parent && get_dist(parent, mate) > FAUNA_MATE_PAIR_RANGE)
			step_toward_target(parent, mate, 2)
			step_toward_target(mate, parent, 2)
			set_intent(parent, FAUNA_STATE_GUARD_HOME, rand(10, 24))
			set_intent(mate, FAUNA_STATE_GUARD_HOME, rand(10, 24))
			continue

		var/turf/N = choose_nest_site(parent, mate)
		if(!N) continue

		if(start_pair_gestation(parent, mate, N))
			pairs_started++
			if(debug_logging)
				log_world("FAUNA: [S.id] pair started gestation at nest ([N.x],[N.y],[N.z])")

		if(offspring_spawned >= FAUNA_REPRO_MAX_OFFSPRING_PASS)
			break

		if(MC_TICK_CHECK)
			return

	if(debug_logging)
		log_world("FAUNA: Reproduction complete - [pairs_started] pairs, [births] births, [offspring_spawned] offspring")

/datum/controller/subsystem/fauna_ecosystem/proc/disperse_mob(mob/living/simple_animal/hostile/M)
	var/turf/origin = get_turf(M)
	if(!origin) return
	var/turf/goal = pick_spread_turf(origin, FAUNA_DISPERSE_DIST, FAUNA_DISPERSE_DIST + 10)
	if(goal)
		roam_goal[mob_key(M)] = goal



// ============== HELPERS ==============

/datum/controller/subsystem/fauna_ecosystem/proc/is_night()
	return (world.time % 12000) >= 6000

/datum/controller/subsystem/fauna_ecosystem/proc/is_valid_turf(turf/T)
	if(!T) return FALSE
	if(T.density) return FALSE
	if(istype(T, /turf/open/transparent)) return FALSE
	if(istype(T, /turf/open/space)) return FALSE
	if(istype(T, /turf/open/floor/plating/f13/outside/roof)) return FALSE
	if(istype(T, /turf/open/indestructible/binary)) return FALSE
	if(istype(T, /turf/open/floor/holofloor)) return FALSE

	var/area/A = get_area(T)
	return is_valid_area(A)

/datum/controller/subsystem/fauna_ecosystem/proc/is_valid_area(area/A)
	if(!A) return FALSE
	if(istype(A, /area/f13/wasteland)) return TRUE
	if(istype(A, /area/f13/caves)) return TRUE
	if(istype(A, /area/f13/tunnel)) return TRUE
	if(istype(A, /area/f13/underground/cave)) return TRUE
	if(istype(A, /area/f13/building)) return TRUE
	return FALSE

/datum/controller/subsystem/fauna_ecosystem/proc/pick_spread_turf(turf/origin, min_dist, max_dist)
	if(!origin) return null

	for(var/attempt in 1 to 20)
		var/angle = rand(0, 359)
		var/dist = rand(min_dist, max_dist)

		var/nx = clamp(origin.x + cos(angle) * dist, 1, world.maxx)
		var/ny = clamp(origin.y + sin(angle) * dist, 1, world.maxy)

		var/turf/T = locate(nx, ny, origin.z)
		if(T && is_valid_turf(T))
			return T

	return null

/datum/controller/subsystem/fauna_ecosystem/proc/step_toward_target(mob/M, atom/target, steps = 1)
	if(!M || !target) return
	if(!istype(M, /mob/living/simple_animal/hostile))
		step_towards(M, target)
		return
	var/mob/living/simple_animal/hostile/H = M
	// Avoid movement tug-of-war with core hostile AI during active combat/pathing.
	if(H.ckey)
		return
	if(H.target || H.stop_automated_movement)
		return
	var/state = get_behavior_state(H)

	var/gait = "walk"
	switch(state)
		if(FAUNA_STATE_HUNT) gait = "run"
		if(FAUNA_STATE_FLEE) gait = "run"
		if(FAUNA_STATE_INVESTIGATE) gait = "stalk"
		if(FAUNA_STATE_RETURN_HOME) gait = "trot"
		if(FAUNA_STATE_GUARD_HOME) gait = "creep"
		if(FAUNA_STATE_REST) gait = "creep"

	var/move_attempts = 1
	if(gait == "run")
		move_attempts = prob(18) ? 2 : 1
	else if(gait == "trot")
		move_attempts = prob(10) ? 2 : 1
	else if(gait == "stalk")
		if(prob(35))
			return
	else if(gait == "creep")
		if(prob(55))
			return

	// Keep multi-step bursts rare to prevent "teleport/zoom" looking movement.
	if(steps > 1 && gait == "run" && prob(15))
		move_attempts = max(move_attempts, 2)

	for(var/i in 1 to move_attempts)
		smart_step_towards(H, target)

/datum/controller/subsystem/fauna_ecosystem/proc/set_home_turf(mob/living/simple_animal/hostile/M, turf/T)
	var/key = mob_key(M)
	if(!key || !T || !is_valid_turf(T)) return
	var/turf/old_home = home_turf[key]
	if(old_home && old_home != T && is_valid_turf(old_home))
		home_backup[key] = old_home
	home_turf[key] = T
	if(isnull(home_quality[key]))
		home_quality[key] = rand(35, 60)

/datum/controller/subsystem/fauna_ecosystem/proc/get_home_turf(mob/living/simple_animal/hostile/M)
	var/key = mob_key(M)
	if(!key) return null
	var/turf/T = home_turf[key]
	if(T && !QDELETED(T) && is_valid_turf(T))
		return T
	return null

/datum/controller/subsystem/fauna_ecosystem/proc/ensure_home_turf(mob/living/simple_animal/hostile/M)
	if(!M) return
	if(get_home_turf(M)) return

	var/turf/origin = get_turf(M)
	if(!origin) return

	var/turf/pick = pick_spread_turf(origin, FAUNA_HOME_ASSIGN_MIN, FAUNA_HOME_ASSIGN_MAX)
	if(!pick)
		pick = origin
	set_home_turf(M, pick)

/datum/controller/subsystem/fauna_ecosystem/proc/wander_randomly(mob/M, dist)
	if(!M) return
	var/turf/origin = get_turf(M)
	if(!origin) return

	var/turf/goal = pick_spread_turf(origin, 1, dist)
	if(goal)
		step_toward_target(M, goal, 1)

/datum/controller/subsystem/fauna_ecosystem/proc/flee_from(mob/M, mob/threat)
	if(!M || !threat) return

	var/turf/my_turf = get_turf(M)
	var/turf/threat_turf = get_turf(threat)
	if(!my_turf || !threat_turf) return

	var/dx = my_turf.x - threat_turf.x
	var/dy = my_turf.y - threat_turf.y

	var/dist = max(1, sqrt(dx*dx + dy*dy))
	dx = (dx / dist) * FAUNA_SOLO_FLEE_DIST
	dy = (dy / dist) * FAUNA_SOLO_FLEE_DIST

	// zigzag retreat makes escapes look less robotic
	if(prob(55))
		var/pdx = -dy
		var/pdy = dx
		var/sign = pick(-1, 1)
		dx += (pdx / max(1, dist)) * rand(2, 5) * sign
		dy += (pdy / max(1, dist)) * rand(2, 5) * sign

	// occasional fake retreat / double-back attempt for prey confusion tactics
	if(prob(12))
		dx *= -0.35
		dy *= -0.35

	var/nx = clamp(my_turf.x + dx, 1, world.maxx)
	var/ny = clamp(my_turf.y + dy, 1, world.maxy)

	var/turf/flee_goal = locate(nx, ny, my_turf.z)
	if(flee_goal)
		step_toward_target(M, flee_goal, 2)

/datum/controller/subsystem/fauna_ecosystem/proc/attack_prey(mob/living/simple_animal/hostile/predator, mob/living/prey)
	if(!predator || !prey) return
	if(QDELETED(prey)) return
	if(prey.stat) return
	if(get_dist(predator, prey) > FAUNA_PREDATOR_KILL_RANGE) return

	// Never execute packmates or same-species here; keeps deaths from looking random.
	var/datum/fauna_pack/ppack = get_pack_for_mob(predator)
	if(ppack)
		if(prey in ppack.members)
			return
	var/datum/fauna_species/predS = get_species_for_mob(predator)
	var/datum/fauna_species/preyS = get_species_for_mob(prey)
	if(predS?.id && preyS?.id && predS.id == preyS.id)
		return

	if(istype(prey, /mob/living/simple_animal))
		var/mob/living/simple_animal/SA = prey
		// Apply real damage first; only kill when HP is actually depleted.
		if(hascall(SA, "adjustBruteLoss"))
			call(SA, "adjustBruteLoss")(rand(18, 32))

		if(!isnull(SA.health) && SA.health > 0)
			return

		SA.death()

		if(debug_logging)
			log_world("FAUNA: [predator.type] killed [prey.type]")

		rest_timers[mob_key(predator)] = world.time + FAUNA_PREDATOR_REST_AFTER_KILL

/datum/controller/subsystem/fauna_ecosystem/proc/find_nearby_predator(mob/M, range)
	var/datum/fauna_species/my_S = get_species_for_mob(M)
	if(!my_S || my_S.role != FAUNA_ROLE_PREY)
		return null

	for(var/mob/living/simple_animal/hostile/other in range(range, M))
		if(other == M) continue
		if(QDELETED(other)) continue
		if(other.stat) continue

		var/datum/fauna_species/other_S = get_species_for_mob(other)
		if(other_S && other_S.role >= FAUNA_ROLE_AMBUSH)
			return other

	return null

/datum/controller/subsystem/fauna_ecosystem/proc/find_nearby_prey(mob/M, range)
	var/mob/living/simple_animal/hostile/best = null
	var/best_score = -10000

	for(var/mob/living/simple_animal/hostile/other in range(range, M))
		if(other == M) continue
		if(QDELETED(other)) continue
		if(other.stat) continue

		var/datum/fauna_species/other_S = get_species_for_mob(other)
		if(!other_S || other_S.role != FAUNA_ROLE_PREY)
			continue

		var/sc = 0
		sc -= get_dist(M, other)

		// weak or injured prey get focused
		if(!isnull(other:health) && !isnull(other:maxHealth) && other:maxHealth > 0)
			var/hp_ratio = other:health / other:maxHealth
			sc += (1 - hp_ratio) * 8

		// isolated prey are preferred
		sc -= count_nearby_same_species(other, 2)

		if(sc > best_score)
			best_score = sc
			best = other

	return best

/datum/controller/subsystem/fauna_ecosystem/proc/find_any_nearby_fauna(mob/M, range)
	var/datum/fauna_species/myS = get_species_for_mob(M)
	var/datum/fauna_pack/myPack = get_pack_for_mob(M)
	var/mob/living/simple_animal/hostile/preferred = null
	var/mob/living/simple_animal/hostile/fallback = null

	for(var/mob/living/simple_animal/hostile/other in range(range, M))
		if(other == M) continue
		if(QDELETED(other)) continue
		if(other.stat) continue
		if(myPack)
			if(other in myPack.members)
				continue

		var/datum/fauna_species/otherS = get_species_for_mob(other)
		if(!otherS) continue
		if(myS?.id && otherS.id == myS.id) continue

		// Prefer true prey to reduce arbitrary inter-predator wipes.
		if(otherS.role == FAUNA_ROLE_PREY)
			if(!preferred || get_dist(M, other) < get_dist(M, preferred))
				preferred = other
		else
			if(!fallback || get_dist(M, other) < get_dist(M, fallback))
				fallback = other

	if(preferred)
		return preferred
	// Allow occasional predator conflicts, but not as default behavior.
	if(fallback && prob(20))
		return fallback
	return null

/datum/controller/subsystem/fauna_ecosystem/proc/find_nearby_same_species(mob/M, range)
	var/datum/fauna_species/my_S = get_species_for_mob(M)
	if(!my_S) return null

	for(var/mob/living/simple_animal/hostile/other in range(range, M))
		if(other == M) continue
		if(QDELETED(other)) continue
		if(other.stat) continue

		var/datum/fauna_species/other_S = get_species_for_mob(other)
		if(other_S?.id == my_S.id)
			return other

	return null

/datum/controller/subsystem/fauna_ecosystem/proc/find_nearby_human(mob/M, range)
	for(var/mob/living/carbon/human/H in range(range, M))
		if(H.stat) continue
		return H
	return null

/datum/controller/subsystem/fauna_ecosystem/proc/count_nearby_same_species(mob/M, range)
	var/datum/fauna_species/my_S = get_species_for_mob(M)
	if(!my_S) return 0

	var/count = 0
	for(var/mob/living/simple_animal/hostile/other in range(range, M))
		if(other == M) continue
		if(QDELETED(other)) continue
		if(other.stat) continue

		var/datum/fauna_species/other_S = get_species_for_mob(other)
		if(other_S?.id == my_S.id)
			count++

	return count

/datum/controller/subsystem/fauna_ecosystem/proc/count_species_on_z(datum/fauna_species/S, z)
	var/count = 0
	for(var/mob/living/simple_animal/hostile/M in world)
		if(M.z != z) continue
		if(QDELETED(M)) continue
		if(M.stat) continue
		if(istype(M, S.mob_type))
			count++
	return count

/datum/controller/subsystem/fauna_ecosystem/proc/cleanup_scent_trails()
	if(!islist(scent_trails) || !length(scent_trails))
		return
	var/list/stale = list()
	for(var/key in scent_trails)
		var/until = scent_trails[key]
		if(!until || world.time >= until)
			stale += key
	for(var/key in stale)
		scent_trails -= key

/datum/controller/subsystem/fauna_ecosystem/proc/fauna_debug_summary()
	var/list/state_counts = list()
	for(var/key in mob_state)
		var/state = mob_state[key]
		if(!state) state = "none"
		state_counts[state] += 1

	var/text = "FAUNA DEBUG: states="
	for(var/s in state_counts)
		text += "[s]:[state_counts[s]] "
	text += "| packs=[length(packs)] scents=[length(scent_trails)] safe=[length(safe_spot)] dens=[length(home_quality)] nests=[length(nest_site)] gest=[length(gestation_until)]"
	return text

/datum/controller/subsystem/fauna_ecosystem/proc/cleanup_stale_timers()
	var/list/stale = list()

	for(var/key in repro_cooldowns)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		repro_cooldowns -= key

	stale.Cut()
	for(var/key in rest_timers)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		rest_timers -= key

	stale.Cut()
	for(var/key in flee_memory)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		flee_memory -= key

	stale.Cut()
	for(var/key in hunt_memory)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		hunt_memory -= key

	stale.Cut()
	for(var/key in gestation_until)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		gestation_until -= key

	stale.Cut()
	for(var/key in mate_target)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		mate_target -= key

	stale.Cut()
	for(var/key in nest_site)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		nest_site -= key

	stale.Cut()
	for(var/key in nest_expires)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		nest_expires -= key

	// roam goals cleanup
	stale.Cut()
	for(var/key in roam_goal)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		roam_goal -= key

	// home cleanup
	stale.Cut()
	for(var/key in home_turf)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		home_turf -= key

	// state cleanup
	stale.Cut()
	for(var/key in mob_state)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		mob_state -= key

	// intent timer cleanup
	stale.Cut()
	for(var/key in intent_until)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		intent_until -= key

	// investigate cleanup
	stale.Cut()
	for(var/key in investigate_goal)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		investigate_goal -= key

	stale.Cut()
	for(var/key in investigate_until)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		investigate_until -= key

	// memory + signals cleanup
	stale.Cut()
	for(var/key in prey_last_turf)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		prey_last_turf -= key

	stale.Cut()
	for(var/key in threat_last_turf)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		threat_last_turf -= key

	stale.Cut()
	for(var/key in signal_cd_until)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		signal_cd_until -= key

	stale.Cut()
	for(var/key in home_danger)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		home_danger -= key

	stale.Cut()
	for(var/key in blocked_memory)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		blocked_memory -= key

	stale.Cut()
	for(var/key in pause_until)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		pause_until -= key

	stale.Cut()
	for(var/key in territory_core)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		territory_core -= key

	stale.Cut()
	for(var/key in dominance_rank)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		dominance_rank -= key

	stale.Cut()
	for(var/key in chase_until)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		chase_until -= key

	stale.Cut()
	for(var/key in failed_hunt_until)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		failed_hunt_until -= key

	stale.Cut()
	for(var/key in safe_spot)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		safe_spot -= key

	stale.Cut()
	for(var/key in home_quality)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		home_quality -= key

	stale.Cut()
	for(var/key in home_backup)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		home_backup -= key

	stale.Cut()
	for(var/key in home_season)
		var/mob/M = get_mob_from_key(key)
		if(!M || QDELETED(M))
			stale += key
	for(var/key in stale)
		home_season -= key

// ============== SPECIES DEFINITIONS ==============

/datum/fauna_species
	var/id = null
	var/name = "Unknown"
	var/mob_type = /mob/living/simple_animal/hostile
	var/role = FAUNA_ROLE_PREY
	var/hardcap = 220
	var/nocturnal = FALSE

// ---- PREY ----

/datum/fauna_species/prey
	role = FAUNA_ROLE_PREY
	hardcap = 280

/datum/fauna_species/prey/radroach
	id = "radroach"
	name = "Radroach"
	mob_type = /mob/living/simple_animal/hostile/radroach
	hardcap = 160

/datum/fauna_species/prey/bloatfly
	id = "bloatfly"
	name = "Bloatfly"
	mob_type = /mob/living/simple_animal/hostile/bloatfly
	hardcap = 145

/datum/fauna_species/prey/molerat
	id = "molerat"
	name = "Molerat"
	mob_type = /mob/living/simple_animal/hostile/molerat
	hardcap = 260

/datum/fauna_species/prey/giantant
	id = "giantant"
	name = "Giant Ant"
	mob_type = /mob/living/simple_animal/hostile/giantant
	hardcap = 220

/datum/fauna_species/prey/fireant
	id = "fireant"
	name = "Fire Ant"
	mob_type = /mob/living/simple_animal/hostile/fireant
	hardcap = 200

// ---- AMBUSH PREDATORS ----

/datum/fauna_species/ambush
	role = FAUNA_ROLE_AMBUSH
	hardcap = 140

/datum/fauna_species/ambush/gecko
	id = "gecko"
	name = "Gecko"
	mob_type = /mob/living/simple_animal/hostile/gecko
	hardcap = 180
	nocturnal = FALSE

/datum/fauna_species/ambush/gecko_big
	id = "gecko_big"
	name = "Big Gecko"
	mob_type = /mob/living/simple_animal/hostile/gecko/big
	hardcap = 70
	nocturnal = FALSE

/datum/fauna_species/ambush/radscorpion
	id = "radscorpion"
	name = "Radscorpion"
	mob_type = /mob/living/simple_animal/hostile/radscorpion
	hardcap = 90
	nocturnal = TRUE

// ---- PACK HUNTERS ----

/datum/fauna_species/hunter
	role = FAUNA_ROLE_HUNTER
	hardcap = 110

/datum/fauna_species/hunter/stalkeryoung
	id = "stalkeryoung"
	name = "Young Nightstalker"
	mob_type = /mob/living/simple_animal/hostile/stalkeryoung
	hardcap = 130
	nocturnal = TRUE

/datum/fauna_species/hunter/stalker
	id = "stalker"
	name = "Nightstalker"
	mob_type = /mob/living/simple_animal/hostile/stalker
	hardcap = 95
	nocturnal = TRUE

/datum/fauna_species/hunter/cazador
	id = "cazador"
	name = "Cazador"
	mob_type = /mob/living/simple_animal/hostile/cazador
	hardcap = 120
	nocturnal = FALSE

// ---- APEX PREDATORS ----

/datum/fauna_species/apex
	role = FAUNA_ROLE_APEX
	hardcap = 45

/datum/fauna_species/apex/mirelurk
	id = "mirelurk"
	name = "Mirelurk"
	mob_type = /mob/living/simple_animal/hostile/mirelurk
	hardcap = 55
	nocturnal = FALSE

/datum/fauna_species/apex/mirelurk_hunter
	id = "mirelurk_hunter"
	name = "Mirelurk Hunter"
	mob_type = /mob/living/simple_animal/hostile/mirelurk/hunter
	hardcap = 30
	nocturnal = FALSE
