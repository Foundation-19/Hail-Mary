// Hostile mob behavior library (Hostile AI redesign, phase 6c).
// Each detector recognizes one trick a target keeps repeating against the mob. A detection adds evidence to a score
// that fades with time. Above AI_BHV_ON the matching counter switches on, and it stays on until the score drops
// below AI_BHV_OFF, so it does not flicker. While on it nudges the utility of a few intents, never by more than
// AI_BHV_MAX_MOD, and only while the fight is in the place or range where the trick was caught.
// - Door-kiting: the target crosses the same door again and again. Counter: stop chasing through it, hold out of the
//   door line, favor flank routes, call for backup.
// - Corner-peeking: the target keeps leaving sight and coming back at the same spot. Counter: hold at range rather
//   than rush, widen the approach.
// - Ranged kiting: a mob that wants to close in keeps getting hurt while the target stays out of reach. Counter:
//   fall back out of the line, flank.
// - Retreat and heal: the target's health climbs back up in the middle of a fight. Counter: press the attack, don't
//   fall back or stall.
// - Room camping: the target holds still and allies keep dying near it. Counter: wait out of its sight until enough
//   fighters have gathered (or the patience runs out), call for backup, then rush it.
// The kite counter also moves the mob: it closes on the target from cover to cover instead of across open ground, and
// falls back out of the line of fire. The heal counter keeps a search going longer and walks it along the heading the
// target was last seen on. Everything else only biases the intent choice, and none of it can keep itself alive: once
// the mob holds or retreats the evidence stops, and the score fades (more slowly while the counter is still needed).
// Every number is a guess. They live in GLOB.ai_bhv_tuning and can be changed from the AI Doctrine admin verb, and
// any behavior can be switched off there (GLOB.ai_bhv_disabled). Tuning is not saved between rounds.
// The ai_doctrine datum keeps how common each behavior is for a type (it makes detection a little quicker next round)
// and whether its counter has been helping (a counter that does not help is turned down), both saved between rounds.
// Scores belong to one mob and one target, and are cleared when the mob switches targets.

/// What each counter does to intent utility, as intent, change pairs
GLOBAL_LIST_INIT(ai_behavior_counters, list(
	list(AI_INTENT_ATTACK, -0.3, AI_INTENT_HOLD, 0.4, AI_INTENT_FLANK, 0.3, AI_INTENT_BACKUP, 0.3),
	list(AI_INTENT_ATTACK, -0.25, AI_INTENT_HOLD, 0.35, AI_INTENT_FLANK, 0.3),
	list(AI_INTENT_ATTACK, -0.1, AI_INTENT_RETREAT, 0.3, AI_INTENT_FLANK, 0.3),
	list(AI_INTENT_ATTACK, 0.2, AI_INTENT_RETREAT, -0.3, AI_INTENT_HOLD, -0.3),
	list(AI_INTENT_ATTACK, -0.3, AI_INTENT_HOLD, 0.4, AI_INTENT_BACKUP, 0.3)))
GLOBAL_LIST_INIT(ai_behavior_names, list("door", "corner", "kite", "heal", "camp"))

/// Tunable numbers: key, then default, least, most, what it does
/proc/ai_bhv_make_spec()
	return list(
		"on" = list(0.7, 0.3, 0.95, "score above which a counter switches on"),
		"off" = list(0.3, 0.05, 0.9, "score below which a counter switches off (kept under on)"),
		"evidence" = list(0.3, 0.05, 1, "score one catch adds"),
		"halflife" = list(300, 50, 3000, "deciseconds for a score to halve"),
		"event_gap" = list(20, 1, 200, "least deciseconds between two catches of one behavior"),
		"window" = list(150, 20, 1200, "deciseconds in which a repeat counts as a repeat"),
		"max_mod" = list(0.4, 0.05, 1, "most a counter moves one intent"),
		"hold_base" = list(0.35, 0.05, 1, "what hold is worth when a counter asks for it from nothing"),
		"strength" = list(1, 0, 3, "multiplier on every counter change"),
		"sustain_time" = list(1200, 0, 6000, "deciseconds after the last catch a needed counter fades slowly"),
		"sustain_fade" = list(0.25, 0, 1, "fade rate multiplier while a counter is sustained"),
		"camp_deaths" = list(2, 1, 10, "allies lost near a still target before it counts as camping"),
		"camp_still" = list(150, 20, 3000, "deciseconds a target must hold still to be a camper"),
		"camp_window" = list(900, 100, 6000, "deciseconds an ally death stays on the books"),
		"camp_mass" = list(3, 2, 10, "fighters (self and allies near) needed before the camper is rushed"),
		"camp_patience" = list(200, 20, 3000, "longest deciseconds a mob waits for the mass"),
		"lead_hops" = list(3, 0, 10, "search leads followed along the target's heading"),
		"memory_scale" = list(2, 1, 6, "multiplier on target memory against a healer"))

/proc/ai_bhv_default_tuning()
	var/list/spec = ai_bhv_make_spec()
	var/list/tuning = list()
	for(var/key in spec)
		var/list/row = spec[key]
		tuning[key] = row[1]
	return tuning

GLOBAL_LIST_INIT(ai_bhv_spec, ai_bhv_make_spec())
GLOBAL_LIST_INIT(ai_bhv_tuning, ai_bhv_default_tuning())
/// Bit per behavior an admin has switched off
GLOBAL_VAR_INIT(ai_bhv_disabled, 0)
/// Recent deaths of mobs that were in a fight, as list(turf, time, faction): where allies keep dying
GLOBAL_LIST_EMPTY(ai_ally_deaths)

/mob/living/simple_animal/hostile
	/// Decaying evidence per behavior, null until the mob first has a target to watch
	var/list/ai_bhv_score
	/// Last time each behavior got evidence
	var/list/ai_bhv_event_time
	/// Bit per behavior whose counter is on
	var/ai_bhv_on = 0
	/// Bit per behavior whose counter changed the last decision, for scoring whether counters help
	var/ai_bhv_applied = 0
	var/ai_bhv_stamp = 0
	/// Where the door and corner tricks were caught
	var/turf/ai_bhv_door_spot
	var/turf/ai_bhv_corner_spot
	/// Target position on the last look, and the last door tile it crossed
	var/turf/ai_bhv_last_pos
	var/turf/ai_bhv_door_turf
	var/ai_bhv_door_time = 0
	/// When sight of the target was lost, and where it was last seen
	var/ai_bhv_los_lost = 0
	var/turf/ai_bhv_los_pos
	var/ai_bhv_hurt_time = 0
	var/ai_bhv_kite_time = 0
	var/ai_bhv_kite_dist = 0
	/// Lowest health the target has shown lately, as a fraction, and when
	var/ai_bhv_target_low = 1
	var/ai_bhv_low_time = 0
	/// The target the scores were built against
	var/datum/weakref/ai_bhv_target_ref
	/// Room camping: where the target has been holding still since when, the newest death already counted, and the wait
	var/turf/ai_bhv_anchor
	var/ai_bhv_anchor_time = 0
	var/ai_bhv_camp_seen = 0
	var/turf/ai_bhv_camp_spot
	var/ai_bhv_camp_wait_start = 0
	var/ai_bhv_camp_waiting = FALSE
	/// Which way the target was last going, and when
	var/ai_bhv_track_dir = 0
	var/ai_bhv_track_time = 0
	var/ai_bhv_lead_hops = 0
	/// Cover bounding and staging
	var/turf/ai_cover_goal
	var/ai_cover_next = 0
	var/ai_cover_pause_until = 0

/// Whether a behavior's counter is on and allowed to act
/mob/living/simple_animal/hostile/proc/ai_bhv_active(behavior)
	return (ai_bhv_on & AI_BHV_FLAG(behavior)) && GLOB.ai_learning_enabled && !(GLOB.ai_bhv_disabled & AI_BHV_FLAG(behavior))

/// How long a lost target is remembered
/mob/living/simple_animal/hostile/proc/get_memory_duration()
	if(ai_bhv_active(AI_BHV_HEAL))
		return target_memory_duration * AI_BHV_MEMORY_SCALE
	return target_memory_duration

/// Whether this mob's behavior results go into the doctrine
/mob/living/simple_animal/hostile/proc/ai_bhv_counts()
	return ai_learning_active() && !GLOB.ai_learning_frozen && !(flags_1 & ADMIN_SPAWNED_1)

/mob/living/simple_animal/hostile/proc/ai_note_engagement()
	if(ai_bhv_counts())
		get_ai_doctrine().bhv_engagements++

/mob/living/simple_animal/hostile/proc/ai_bhv_reset()
	ai_bhv_score = null
	ai_bhv_event_time = null
	ai_bhv_on = 0
	ai_bhv_applied = 0
	ai_bhv_door_spot = null
	ai_bhv_corner_spot = null
	ai_bhv_last_pos = null
	ai_bhv_door_turf = null
	ai_bhv_door_time = 0
	ai_bhv_los_lost = 0
	ai_bhv_los_pos = null
	ai_bhv_kite_time = 0
	ai_bhv_target_low = 1
	ai_bhv_low_time = 0
	ai_bhv_target_ref = null
	ai_bhv_anchor = null
	ai_bhv_anchor_time = 0
	ai_bhv_camp_seen = 0
	ai_bhv_camp_spot = null
	ai_bhv_camp_wait_start = 0
	ai_bhv_camp_waiting = FALSE
	ai_bhv_track_dir = 0
	ai_bhv_track_time = 0
	ai_bhv_lead_hops = 0
	ai_cover_goal = null
	ai_cover_next = 0
	ai_cover_pause_until = 0

/mob/living/simple_animal/hostile/proc/ai_bhv_open_door_at(turf/T)
	for(var/obj/structure/simple_door/SD in T)
		if(!SD.density)
			return TRUE
	for(var/obj/machinery/door/D in T)
		if(!D.density)
			return TRUE
	return FALSE

/// Adds evidence for a behavior. spot is where it was caught. Returns TRUE if the evidence was recorded.
/mob/living/simple_animal/hostile/proc/ai_bhv_evidence(behavior, amount, turf/spot)
	if(GLOB.ai_bhv_disabled & AI_BHV_FLAG(behavior))
		return FALSE
	if(world.time - ai_bhv_event_time[behavior] < AI_BHV_EVENT_GAP)
		return FALSE
	ai_bhv_event_time[behavior] = world.time
	amount *= get_ai_doctrine().sensitivity(behavior)
	ai_bhv_score[behavior] = min(1, ai_bhv_score[behavior] + amount)
	if(behavior == AI_BHV_DOOR)
		ai_bhv_door_spot = spot
	else if(behavior == AI_BHV_CORNER)
		ai_bhv_corner_spot = spot
	else if(behavior == AI_BHV_CAMP)
		ai_bhv_camp_spot = spot
	ai_debug_log("behavior_evidence [GLOB.ai_behavior_names[behavior]] score=[round(ai_bhv_score[behavior], 0.01)]")
	return TRUE

/// Fades the scores and flips counters on or off with hysteresis. A counter that is still needed here fades slowly
/// for a while after its last evidence, because working counters stop the trick that raised them.
/mob/living/simple_animal/hostile/proc/ai_bhv_refresh(target_distance)
	// Time out of sight or in a search does not burn the score down
	var/dt = min(world.time - ai_bhv_stamp, 100)
	ai_bhv_stamp = world.time
	for(var/b in 1 to AI_BHV_COUNT)
		var/flag = AI_BHV_FLAG(b)
		if(GLOB.ai_bhv_disabled & flag)
			ai_bhv_score[b] = 0
			ai_bhv_on &= ~flag
			continue
		var/rate = dt
		if((ai_bhv_on & flag) && world.time - ai_bhv_event_time[b] <= AI_BHV_SUSTAIN_TIME && ai_bhv_in_context(b, target_distance))
			rate *= AI_BHV_SUSTAIN_FADE
		if(rate > 0)
			ai_bhv_score[b] *= 2 ** (-rate / AI_BHV_HALFLIFE)
		var/score = ai_bhv_score[b]
		if(!(ai_bhv_on & flag) && score >= AI_BHV_ON)
			ai_bhv_on |= flag
			ai_debug_log("behavior_counter_on [GLOB.ai_behavior_names[b]] score=[round(score, 0.01)]")
			if(ai_bhv_counts())
				get_ai_doctrine().bhv_catches[b]++
		else if((ai_bhv_on & flag) && score < AI_BHV_OFF)
			ai_bhv_on &= ~flag
			ai_debug_log("behavior_counter_off [GLOB.ai_behavior_names[b]] score=[round(score, 0.01)]")

/// Called each tick the mob can see its target. Looks for the tricks the library knows.
/mob/living/simple_animal/hostile/proc/ai_behavior_update(target_distance)
	if(ckey || !ai_decision_enabled || !GLOB.ai_learning_enabled || !isliving(target))
		return
	var/mob/living/L = target
	var/turf/here = get_turf(L)
	if(!here)
		return
	// Scores belong to one target. A switch through a lost-target gap does not go through the acquire reset.
	if(ai_bhv_score && RESOLVEWEAKREF(ai_bhv_target_ref) != target)
		ai_bhv_reset()
	if(!ai_bhv_target_ref)
		ai_bhv_target_ref = WEAKREF(target)
	if(!ai_bhv_score)
		ai_bhv_score = list()
		ai_bhv_event_time = list()
		for(var/b in 1 to AI_BHV_COUNT)
			ai_bhv_score += 0
			ai_bhv_event_time += -AI_BHV_EVENT_GAP
		ai_bhv_stamp = world.time

	// Door-kiting: the target crossed the same door again within the window
	if(ai_bhv_last_pos && ai_bhv_last_pos != here && get_dist(ai_bhv_last_pos, here) <= 8)
		for(var/turf/T in getline(ai_bhv_last_pos, here))
			if(T == ai_bhv_last_pos || !ai_bhv_open_door_at(T))
				continue
			if(T == ai_bhv_door_turf && world.time - ai_bhv_door_time <= AI_BHV_WINDOW)
				ai_bhv_evidence(AI_BHV_DOOR, AI_BHV_EVIDENCE, T)
			ai_bhv_door_turf = T
			ai_bhv_door_time = world.time
			break
	if(ai_bhv_last_pos && ai_bhv_last_pos != here && ai_bhv_last_pos.z == here.z)
		ai_bhv_track_dir = get_dir(ai_bhv_last_pos, here)
		ai_bhv_track_time = world.time
	ai_bhv_last_pos = here
	ai_bhv_lead_hops = 0
	// Corner-peeking: sight was lost for a moment and the target came back at about the same spot
	if(ai_bhv_los_lost)
		var/gap = world.time - ai_bhv_los_lost
		ai_bhv_los_lost = 0
		if(gap >= 10 && gap <= AI_BHV_WINDOW / 2 && ai_bhv_los_pos && get_dist(ai_bhv_los_pos, here) <= 2)
			ai_bhv_evidence(AI_BHV_CORNER, AI_BHV_EVIDENCE, here)
	ai_bhv_los_pos = here

	// Ranged kiting: a mob that wants to close keeps getting hurt without gaining ground
	if(!ranged || combat_mode == COMBAT_MODE_MIXED)
		if(world.time - ai_bhv_kite_time >= 30)
			if(ai_bhv_kite_time && ai_intent == AI_INTENT_ATTACK && target_distance >= 5 && target_distance >= ai_bhv_kite_dist && world.time - ai_bhv_hurt_time <= 40)
				ai_bhv_evidence(AI_BHV_KITE, AI_BHV_EVIDENCE, null)
			ai_bhv_kite_time = world.time
			ai_bhv_kite_dist = target_distance

	// Retreat and heal: the target's health comes back up during the fight
	if(L.maxHealth > 0)
		var/hp = CLAMP(L.health / L.maxHealth, 0, 1)
		if(hp <= ai_bhv_target_low || world.time - ai_bhv_low_time > 600)
			ai_bhv_target_low = hp
			ai_bhv_low_time = world.time
		else if(hp - ai_bhv_target_low >= 0.2 && ai_bhv_target_low < 0.75)
			ai_bhv_evidence(AI_BHV_HEAL, AI_BHV_EVIDENCE + 0.1, null)
			ai_bhv_target_low = hp
			ai_bhv_low_time = world.time

	// Room camping: the target has held still while allies kept dying around it
	if(!ranged || combat_mode == COMBAT_MODE_MIXED)
		if(!ai_bhv_anchor || ai_bhv_anchor.z != here.z || get_dist(ai_bhv_anchor, here) > AI_BHV_CAMP_ROAM)
			ai_bhv_anchor = here
			ai_bhv_anchor_time = world.time
		else if(world.time - ai_bhv_anchor_time >= AI_BHV_CAMP_STILL)
			var/deaths = 0
			var/newest = 0
			for(var/list/entry in GLOB.ai_ally_deaths)
				var/turf/where = entry[1]
				var/died_at = entry[2]
				if(world.time - died_at > AI_BHV_CAMP_WINDOW || where.z != here.z || get_dist(where, ai_bhv_anchor) > AI_BHV_CAMP_RANGE || get_dist(where, src) > AI_BHV_CAMP_SIGHT)
					continue
				if(!faction_check(entry[3], faction, TRUE))
					continue
				deaths++
				newest = max(newest, died_at)
			if(deaths >= AI_BHV_CAMP_DEATHS && newest > ai_bhv_camp_seen)
				if(ai_bhv_evidence(AI_BHV_CAMP, AI_BHV_EVIDENCE * (deaths - AI_BHV_CAMP_DEATHS + 1), ai_bhv_anchor))
					ai_bhv_camp_seen = newest

	ai_bhv_refresh(target_distance)

/// Notes that this mob died in a fight, so allies nearby can tell when a spot is killing them
/mob/living/simple_animal/hostile/proc/ai_log_ally_death(turf/where)
	if(ckey || (flags_1 & ADMIN_SPAWNED_1) || !GLOB.ai_learning_enabled)
		return
	if(world.time - ai_bhv_hurt_time > 100 && world.time - last_target_sighting > 100)
		return
	GLOB.ai_ally_deaths += list(list(where, world.time, faction.Copy()))
	if(length(GLOB.ai_ally_deaths) > AI_BHV_DEATH_LOG_MAX)
		GLOB.ai_ally_deaths.Cut(1, length(GLOB.ai_ally_deaths) - AI_BHV_DEATH_LOG_MAX + 1)
/// Whether a counter's trick was caught here, so it only shapes fights like the one it was learned from
/mob/living/simple_animal/hostile/proc/ai_bhv_in_context(behavior, target_distance)
	switch(behavior)
		if(AI_BHV_DOOR)
			return ai_bhv_door_spot && get_dist(target, ai_bhv_door_spot) <= 7
		if(AI_BHV_CORNER)
			return ai_bhv_corner_spot && get_dist(target, ai_bhv_corner_spot) <= 7
		if(AI_BHV_KITE)
			return target_distance >= 4
		if(AI_BHV_CAMP)
			return ai_bhv_camp_spot && get_dist(target, ai_bhv_camp_spot) <= AI_BHV_CAMP_RANGE && (!ranged || combat_mode == COMBAT_MODE_MIXED)
	return TRUE

/// Applies the counters that are on to the intent scores. A counter can lift hold from nothing when it asks for it
/// (door always, corner only for mobs that shoot), but it cannot make an intent the mob has no way to do.
/mob/living/simple_animal/hostile/proc/ai_apply_behavior_counters(list/intents, list/utility, target_distance, datum/ai_doctrine/doctrine, allies_near = 0)
	ai_bhv_applied = 0
	ai_bhv_camp_waiting = FALSE
	if(!ai_bhv_on || !target || !GLOB.ai_learning_enabled)
		ai_bhv_camp_wait_start = 0
		return
	var/list/delta = list()
	var/hold_from_nothing = FALSE
	for(var/b in 1 to AI_BHV_COUNT)
		var/flag = AI_BHV_FLAG(b)
		if(!(ai_bhv_on & flag) || (GLOB.ai_bhv_disabled & flag) || !ai_bhv_in_context(b, target_distance))
			if(b == AI_BHV_CAMP)
				ai_bhv_camp_wait_start = 0
			continue
		if(b == AI_BHV_CAMP)
			// A camper is only waited out while the squad is still too thin to rush it. The wait ends for good once
			// the patience runs out, so the mob does not start waiting again.
			if(target_distance < 4 || allies_near + 1 >= AI_BHV_CAMP_MASS)
				ai_bhv_camp_wait_start = 0
				continue
			if(!ai_bhv_camp_wait_start)
				ai_bhv_camp_wait_start = world.time
				ai_debug_log("behavior_camp_wait allies=[allies_near]")
				call_for_backup(target, "found")
			if(world.time - ai_bhv_camp_wait_start > AI_BHV_CAMP_PATIENCE)
				continue
			ai_bhv_camp_waiting = TRUE
			hold_from_nothing = TRUE
		ai_bhv_applied |= flag
		var/scale = (doctrine ? doctrine.counter_scale(b) : 1) * AI_BHV_STRENGTH
		var/list/mods = GLOB.ai_behavior_counters[b]
		for(var/j in 1 to length(mods) step 2)
			delta["[mods[j]]"] += mods[j + 1] * scale
		if(target_distance >= 3 && (b == AI_BHV_DOOR || (b == AI_BHV_CORNER && ranged)))
			hold_from_nothing = TRUE
	if(!ai_bhv_applied)
		return
	for(var/i in 1 to length(intents))
		var/d = delta["[intents[i]]"]
		if(!d)
			continue
		d = CLAMP(d, -AI_BHV_MAX_MOD, AI_BHV_MAX_MOD)
		if(utility[i] <= 0)
			if(!(intents[i] == AI_INTENT_HOLD && d > 0 && hold_from_nothing))
				continue
			utility[i] = AI_BHV_HOLD_BASE
		utility[i] = max(0, utility[i] + d)
	ai_debug_log("behavior_counters applied=[ai_bhv_applied]")

/// Whether a line from a to b is cut off. With sight_only, low cover that can be seen over does not count, so this
/// is whether someone at one end could see the other. Without it, anything solid counts, which is whether the mob
/// could walk it in a straight line.
/mob/living/simple_animal/hostile/proc/ai_bhv_line_blocked(turf/a, turf/b, sight_only = FALSE)
	for(var/turf/T in getline(a, b))
		if(T == a || T == b)
			continue
		if(T.density || (sight_only && T.opacity))
			return TRUE
		for(var/obj/O in T)
			if(sight_only && O.opacity)
				return TRUE
			if(!O.density)
				continue
			if(sight_only && istype(O, /obj/structure))
				var/obj/structure/S = O
				if(S.is_low_cover())
					continue
			return TRUE
	return FALSE

/// Whether nothing solid stands on the tile
/mob/living/simple_animal/hostile/proc/ai_bhv_tile_free(turf/T)
	if(!T || T.density)
		return FALSE
	for(var/atom/movable/AM in T)
		if(AM.density)
			return FALSE
	return TRUE

/// Picks a tile near the mob that the threat cannot see. closing wants one nearer the threat (to move up between
/// covered positions), otherwise one no nearer than here (to get out of the line of fire).
/mob/living/simple_animal/hostile/proc/ai_find_cover_tile(turf/threat_turf, closing)
	var/turf/here = get_turf(src)
	if(!here || !threat_turf || here.z != threat_turf.z)
		return null
	var/cur = get_dist(here, threat_turf)
	var/turf/best
	var/best_cost = 1e9
	for(var/turf/T in range(AI_BHV_COVER_SCAN, here))
		if(T == here || !ai_bhv_tile_free(T))
			continue
		var/d = get_dist(T, threat_turf)
		if(d <= 2 || (closing ? d > cur - 2 : d < cur - 1))
			continue
		if(!ai_bhv_line_blocked(threat_turf, T, TRUE) || ai_bhv_line_blocked(here, T))
			continue
		var/cost = closing ? d + get_dist(here, T) * 0.5 : get_dist(here, T)
		if(cost < best_cost)
			best_cost = cost
			best = T
	return best

/// Closes on the target from one covered tile to the next, with a short pause under each, and rushes the last few
/// tiles. Returns TRUE if it issued movement.
/mob/living/simple_animal/hostile/proc/ai_cover_advance()
	var/turf/here = get_turf(src)
	var/turf/there = target ? get_turf(target) : null
	if(!here || !there || here.z != there.z || get_dist(here, there) <= AI_BHV_COVER_RUSH)
		ai_cover_goal = null
		return FALSE
	if(world.time < ai_cover_pause_until)
		walk(src, 0)
		return TRUE
	if(ai_cover_goal && here == ai_cover_goal)
		ai_cover_goal = null
		ai_cover_next = 0
		ai_cover_pause_until = world.time + AI_BHV_COVER_PAUSE
		walk(src, 0)
		return TRUE
	if(!ai_cover_goal && world.time < ai_cover_next)
		return FALSE
	if(!ai_cover_goal || world.time >= ai_cover_next)
		ai_cover_goal = ai_find_cover_tile(there, TRUE)
		ai_cover_next = world.time + (ai_cover_goal ? AI_BHV_COVER_REPICK : 10)
		if(!ai_cover_goal)
			return FALSE
		ai_debug_log("behavior_cover_advance to=[ai_cover_goal.x],[ai_cover_goal.y]")
		Goto(ai_cover_goal, move_to_delay, 0)
	return TRUE

/// Gets out of the target's sight, or stands still if already out of it. Returns TRUE if it handled the movement.
/mob/living/simple_animal/hostile/proc/ai_break_line_of_sight()
	var/turf/here = get_turf(src)
	var/turf/there = target ? get_turf(target) : null
	if(!here || !there || here.z != there.z)
		return FALSE
	if(ai_bhv_line_blocked(there, here, TRUE))
		walk(src, 0)
		return TRUE
	var/turf/goal = ai_find_cover_tile(there, FALSE)
	if(!goal)
		// Nowhere to wait, so stop waiting and push
		if(ai_bhv_camp_waiting)
			ai_bhv_camp_wait_start = world.time - AI_BHV_CAMP_PATIENCE - 1
		return FALSE
	ai_debug_log("behavior_break_los to=[goal.x],[goal.y]")
	Goto(goal, move_to_delay, 0)
	return TRUE

/// While searching for a target that heals up in fights, follows the way it was last heading past where it was lost,
/// a few leads at most. Returns TRUE if it set a new destination.
/mob/living/simple_animal/hostile/proc/ai_search_lead()
	if(target || !ai_bhv_active(AI_BHV_HEAL) || !ai_bhv_track_dir || ai_bhv_lead_hops >= AI_BHV_LEAD_HOPS)
		return FALSE
	if(world.time - ai_bhv_track_time > AI_BHV_LEAD_FRESH)
		return FALSE
	var/turf/here = get_turf(src)
	if(!last_known_location || !here || last_known_location.z != here.z || get_dist(here, last_known_location) > 2)
		return FALSE
	var/turf/best
	var/best_steps = 0
	for(var/heading in list(ai_bhv_track_dir, turn(ai_bhv_track_dir, 45), turn(ai_bhv_track_dir, -45)))
		var/turf/T = last_known_location
		var/steps = 0
		while(steps < AI_BHV_LEAD_STEPS)
			var/turf/next = get_step(T, heading)
			if(!next || !ai_bhv_tile_free(next))
				break
			T = next
			steps++
		if(steps > best_steps)
			best_steps = steps
			best = T
	if(best_steps < AI_BHV_LEAD_MIN)
		return FALSE
	ai_bhv_lead_hops++
	if(!update_search_destination(best, "heal_lead", AI_BHV_LEAD_CONF))
		return FALSE
	ai_debug_log("behavior_search_lead hop=[ai_bhv_lead_hops] steps=[best_steps]")
	schedule_search_tick(15)
	return TRUE

/// Admin menu for the behavior numbers, called from the AI Doctrine verb
/proc/ai_bhv_tuning_menu(mob/user)
	var/choice = input(user, "Behavior tuning is not saved between rounds.", "AI behavior tuning") as null|anything in list("View", "Change a value", "Switch a behavior on or off", "Restore defaults")
	switch(choice)
		if("View")
			var/list/lines = list()
			for(var/key in GLOB.ai_bhv_spec)
				var/list/row = GLOB.ai_bhv_spec[key]
				lines += "[key] = [GLOB.ai_bhv_tuning[key]] (default [row[1]], range [row[2]] to [row[3]]): [row[4]]"
			for(var/b in 1 to AI_BHV_COUNT)
				lines += "[GLOB.ai_behavior_names[b]]: [(GLOB.ai_bhv_disabled & AI_BHV_FLAG(b)) ? "OFF" : "on"]"
			to_chat(user, "<div class='examine_block'>[lines.Join("<br>")]</div>")
		if("Change a value")
			var/key = input(user, "Which value?", "AI behavior tuning") as null|anything in GLOB.ai_bhv_spec
			if(!key)
				return
			var/list/row = GLOB.ai_bhv_spec[key]
			var/value = input(user, "[row[4]]\nRange [row[2]] to [row[3]], default [row[1]].", "[key]", GLOB.ai_bhv_tuning[key]) as null|num
			if(isnull(value))
				return
			value = CLAMP(value, row[2], row[3])
			if(key == "on" && value <= GLOB.ai_bhv_tuning["off"])
				to_chat(user, span_warning("'on' has to stay above 'off' ([GLOB.ai_bhv_tuning["off"]])."))
				return
			if(key == "off" && value >= GLOB.ai_bhv_tuning["on"])
				to_chat(user, span_warning("'off' has to stay below 'on' ([GLOB.ai_bhv_tuning["on"]])."))
				return
			GLOB.ai_bhv_tuning[key] = value
			message_admins("[key_name_admin(user)] set AI behavior tuning [key] to [value].")
			log_admin("[key_name(user)] set AI behavior tuning [key] to [value].")
		if("Switch a behavior on or off")
			var/name = input(user, "Which behavior?", "AI behavior tuning") as null|anything in GLOB.ai_behavior_names
			if(!name)
				return
			var/b = GLOB.ai_behavior_names.Find(name)
			GLOB.ai_bhv_disabled ^= AI_BHV_FLAG(b)
			var/off = (GLOB.ai_bhv_disabled & AI_BHV_FLAG(b)) ? "off" : "on"
			message_admins("[key_name_admin(user)] switched AI behavior [name] [off].")
			log_admin("[key_name(user)] switched AI behavior [name] [off].")
		if("Restore defaults")
			GLOB.ai_bhv_tuning = ai_bhv_default_tuning()
			GLOB.ai_bhv_disabled = 0
			message_admins("[key_name_admin(user)] restored the AI behavior tuning defaults.")
			log_admin("[key_name(user)] restored the AI behavior tuning defaults.")
