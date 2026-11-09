// Hostile mob action fault memory (Hostile AI redesign, phase 3.5).
// Every action gets an expectation and an observed outcome. A failure is remembered against the geometry of the
// action (for a shot: origin turf -> target turf), not against a target, so the mob learns that one tile cannot
// hit another instead of fixating on one player. Failures expire, and a suppressed action is still probed
// periodically, so a run of faults can never stop a mob attacking altogether.

#define AI_ACTION_SHOT "shot"

/// Failures on one key before the action is suppressed
#define AI_FAULT_THRESHOLD 2
/// A fault is forgotten this long after its latest failure (deciseconds); doors open and targets move
#define AI_FAULT_MEMORY 150
/// While suppressed, one attempt is still allowed per interval to find out whether the fault is gone
#define AI_FAULT_PROBE_INTERVAL 50
#define AI_FAULT_MAX_ENTRIES 12
/// A shot stopped by a dense non-mob this close to the shooter is a geometry mistake; a farther stop is an accuracy result
#define AI_LANE_BLOCK_NEAR_DIST 4

GLOBAL_VAR_INIT(ai_shots_fired, 0)
GLOBAL_VAR_INIT(ai_shots_blocked, 0)

/datum/ai_fault
	var/fails = 0
	var/last_fail = 0
	var/last_probe = 0

/mob/living/simple_animal/hostile
	/// Fault memory: "action|context" -> /datum/ai_fault
	var/list/ai_faults
	var/ai_shots_fired = 0
	var/ai_shots_blocked = 0
	/// Set by OpenFire when it declined a shot because of the lane; MoveToTarget reads it to sidestep
	var/ai_shot_declined = FALSE
	var/ai_last_observed_lane
	var/ai_last_observed_time = 0

/// Context key for a shot: purely geometric
/mob/living/simple_animal/hostile/proc/lane_key(turf/origin, turf/goal)
	return "[origin.x],[origin.y],[origin.z]>[goal.x],[goal.y],[goal.z]"

/mob/living/simple_animal/hostile/proc/prune_ai_faults()
	for(var/key in ai_faults)
		var/datum/ai_fault/F = ai_faults[key]
		if(world.time - F.last_fail > AI_FAULT_MEMORY)
			ai_faults -= key
			qdel(F)
	if(length(ai_faults) < AI_FAULT_MAX_ENTRIES)
		return
	// Still full: forget the oldest
	var/oldest_key
	var/oldest_time = INFINITY
	for(var/key in ai_faults)
		var/datum/ai_fault/F = ai_faults[key]
		if(F.last_fail < oldest_time)
			oldest_time = F.last_fail
			oldest_key = key
	if(oldest_key)
		qdel(ai_faults[oldest_key])
		ai_faults -= oldest_key

/// The single entry point for outcomes: a success clears the fault, a failure records it
/mob/living/simple_animal/hostile/proc/report_outcome(action, context_key, success)
	var/key = "[action]|[context_key]"
	var/datum/ai_fault/F = LAZYACCESS(ai_faults, key)
	if(success)
		if(F)
			ai_debug_log("fault_clear action=[action] key=[context_key]")
			ai_faults -= key
			qdel(F)
		return
	if(!F)
		prune_ai_faults()
		F = new
		LAZYSET(ai_faults, key, F)
	F.fails++
	F.last_fail = world.time
	if(F.fails == AI_FAULT_THRESHOLD)
		F.last_probe = world.time
	ai_debug_log("fault_add action=[action] key=[context_key] fails=[F.fails]")

/// Whether this action should be skipped for now. A suppressed action is let through once per probe interval
/// unless probe is FALSE (planning queries that must not consume the probe).
/mob/living/simple_animal/hostile/proc/action_suppressed(action, context_key, probe = TRUE)
	var/key = "[action]|[context_key]"
	var/datum/ai_fault/F = LAZYACCESS(ai_faults, key)
	if(!F)
		return FALSE
	if(world.time - F.last_fail > AI_FAULT_MEMORY)
		ai_faults -= key
		qdel(F)
		return FALSE
	if(F.fails < AI_FAULT_THRESHOLD)
		return FALSE
	if(world.time - F.last_probe >= AI_FAULT_PROBE_INTERVAL)
		if(probe)
			F.last_probe = world.time
			ai_debug_log("fault_probe action=[action] key=[context_key]")
		return FALSE
	return TRUE

/// Walks the shot line and returns TRUE if a projectile fired from origin can reach target_turf. Rejects dense
/// turfs, dense non-mob objects, and diagonal steps squeezed between two dense orthogonal turfs.
/mob/living/simple_animal/hostile/proc/shot_is_clear(turf/origin, turf/target_turf)
	if(!origin || !target_turf)
		return FALSE
	if(origin.z != target_turf.z)
		return TRUE // Multi-Z shots are gated by OpenFire's openspace rules
	var/turf/previous = origin
	for(var/turf/T in getline(origin, target_turf))
		if(T == origin)
			continue
		if(previous.x != T.x && previous.y != T.y)
			var/turf/side_a = locate(previous.x, T.y, T.z)
			var/turf/side_b = locate(T.x, previous.y, T.z)
			if(side_a && side_b && side_a.density && side_b.density)
				return FALSE
		previous = T
		if(T == target_turf)
			break
		if(T.density)
			return FALSE
		for(var/obj/O in T)
			if(O.density)
				return FALSE
	return TRUE

/// A shot from here to there was expected to arrive; counts it for the blocked/fired metric
/mob/living/simple_animal/hostile/proc/note_shot_fired()
	ai_shots_fired++
	GLOB.ai_shots_fired++

/// Called by the projectile on its first impact. Compares the expectation (it reaches the target) with what
/// happened. Only a stop on something dense and near the shooter counts as a fault; a shot that flew on and
/// missed is an accuracy result.
/mob/living/simple_animal/hostile/proc/observe_shot(obj/item/projectile/P, atom/impacted)
	if(ckey || QDELETED(src) || QDELETED(impacted))
		return
	var/turf/origin = P.starting || get_turf(src)
	var/turf/goal = P.original ? get_turf(P.original) : null
	var/turf/hit_turf = get_turf(impacted)
	if(!origin || !goal || !hit_turf || origin.z != goal.z || hit_turf.z != goal.z)
		return
	// Pellet casings send several projectiles per shot; only the first impact of a lane in a tick counts
	var/lane = lane_key(origin, goal)
	if(lane == ai_last_observed_lane && world.time == ai_last_observed_time)
		return
	ai_last_observed_lane = lane
	ai_last_observed_time = world.time
	if(isliving(impacted))
		var/mob/living/hit_mob = impacted
		if(!faction_check_mob(hit_mob))
			ai_note_hit_landed()
	var/blocked = FALSE
	if(!isliving(impacted) && hit_turf != goal && get_dist(origin, hit_turf) <= AI_LANE_BLOCK_NEAR_DIST)
		if(isturf(impacted) || impacted.density)
			blocked = TRUE
	if(blocked)
		ai_shots_blocked++
		GLOB.ai_shots_blocked++
		ai_debug_log("shot_blocked hit=[impacted] at=[hit_turf.x],[hit_turf.y] blocked/fired=[ai_shots_blocked]/[ai_shots_fired] global=[GLOB.ai_shots_blocked]/[GLOB.ai_shots_fired]")
	report_outcome(AI_ACTION_SHOT, lane, !blocked)
