// SMART AI SYSTEM - Improvements for hostile mob AI
// This file adds: Cover System, Target Prioritization, Flanking, Group Coordination, Investigation, Anti-Kite
// Variables are defined in hostile.dm - this file only contains procs

// ============================================
// COVER SYSTEM
// ============================================

// Cover object types that mobs can use for protection
#define COVER_TYPE_LOW 1      // Crates, tables, low walls - 50% protection
#define COVER_TYPE_HIGH 2     // Walls, pillars, full cover - 100% protection
#define COVER_QUALITY_POOR 1  // Partial protection
#define COVER_QUALITY_GOOD 2  // Full protection

// Combat role defines
#define ROLE_ATTACKER 1
#define ROLE_TANK 2
#define ROLE_FLANKER 3
#define ROLE_SUPPORT 4

// Flanking direction defines
#define FLANK_LEFT 1
#define FLANK_RIGHT 2

// ============================================
// COVER SYSTEM PROCS
// ============================================

/// Find the nearest available cover object
/mob/living/simple_animal/hostile/proc/find_nearest_cover()
	if(!uses_cover || !target)
		return null

	var/best_cover = null
	var/best_score = 0
	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)

	if(!my_turf || !target_turf)
		return null

	// Search for cover objects
	for(var/obj/structure/S in range(cover_search_range, src))
		if(!can_use_as_cover(S))
			continue

		var/cover_score = evaluate_cover_quality(S, target_turf)
		if(cover_score > best_score)
			best_score = cover_score
			best_cover = S

	return best_cover

/// Check if an object can be used as cover
/mob/living/simple_animal/hostile/proc/can_use_as_cover(obj/structure/S)
	if(!S || S.density == FALSE)
		return FALSE

	// Check if it's a valid cover type
	if(istype(S, /obj/structure/table) || istype(S, /obj/structure/rack))
		return TRUE
	if(istype(S, /obj/structure/closet/crate))
		return TRUE
	if(istype(S, /obj/structure/barricade))
		return TRUE
	if(istype(S, /obj/structure/falsewall))
		return TRUE

	// Walls adjacent to us
	if(istype(S, /obj/structure/girder) || istype(S, /obj/structure/falsewall))
		return TRUE

	return FALSE

/// Evaluate how good a piece of cover is (higher = better)
/mob/living/simple_animal/hostile/proc/evaluate_cover_quality(obj/structure/cover, turf/target_turf)
	var/score = 0
	var/turf/cover_turf = get_turf(cover)
	var/turf/my_turf = get_turf(src)

	// Must have line of sight to target from cover
	if(!can_see(cover_turf, target_turf, vision_range))
		return 0

	// Distance from us to cover (closer = better)
	var/dist_to_cover = get_dist(my_turf, cover_turf)
	score += max(10 - dist_to_cover, 1)

	// Distance from target (further = safer for ranged mobs)
	var/dist_from_target = get_dist(cover_turf, target_turf)
	if(ranged)
		score += min(dist_from_target, 7) // Ranged mobs want distance
	else
		score += max(7 - dist_from_target, 1) // Melee mobs want to close

	// Check if cover actually blocks LOS to target
	var/turf/behind_cover = get_step(cover_turf, get_dir(cover_turf, target_turf))
	if(behind_cover && !can_see(behind_cover, target_turf, vision_range))
		score += 10 // Good cover - fully blocks LOS

	return score

/// Move to cover position
/mob/living/simple_animal/hostile/proc/move_to_cover()
	if(!uses_cover || in_cover)
		return FALSE

	if(world.time - last_cover_seek < cover_seek_cooldown)
		return FALSE

	var/obj/structure/best_cover = find_nearest_cover()
	if(!best_cover)
		return FALSE

	// Calculate position behind cover (opposite side from target)
	var/turf/cover_turf = get_turf(best_cover)
	var/turf/target_turf = get_turf(target)
	var/cover_dir = get_dir(cover_turf, target_turf)
	var/hide_dir = turn(cover_dir, 180) // Opposite direction
	var/turf/hide_spot = get_step(cover_turf, hide_dir)

	if(!hide_spot)
		hide_spot = cover_turf

	// Check if hide spot is walkable
	if(hide_spot.density)
		// Try adjacent tiles
		for(var/dir in GLOB.cardinals)
			var/turf/adjacent = get_step(cover_turf, dir)
			if(adjacent && !adjacent.density)
				hide_spot = adjacent
				break

	last_cover_seek = world.time
	current_cover = best_cover
	Goto(hide_spot, move_to_delay, 0)
	return TRUE

/// Enter cover state when adjacent to cover object
/mob/living/simple_animal/hostile/proc/enter_cover()
	if(!current_cover || in_cover)
		return

	in_cover = TRUE
	cover_entered_time = world.time

	// Face target from cover
	if(target)
		setDir(get_dir(src, target))

/// Exit cover state
/mob/living/simple_animal/hostile/proc/exit_cover()
	in_cover = FALSE
	peeking_from_cover = FALSE
	current_cover = null

/// Peek from cover to shoot
/mob/living/simple_animal/hostile/proc/peek_from_cover()
	if(!in_cover || !target)
		return FALSE

	peeking_from_cover = TRUE

	// Face target
	setDir(get_dir(src, target))

	// Stay peeking for a moment then return to cover
	addtimer(CALLBACK(src, PROC_REF(return_to_cover)), 20)

	return TRUE

/// Return to full cover after peeking
/mob/living/simple_animal/hostile/proc/return_to_cover()
	peeking_from_cover = FALSE

// ============================================
// TARGET PRIORITIZATION PROCS
// ============================================

/// Calculate threat score for a potential target
/mob/living/simple_animal/hostile/proc/calculate_threat_score(atom/T)
	if(!isliving(T))
		return 0

	var/mob/living/L = T
	var/score = 100 // Base score

	// Distance factor (closer = higher threat)
	var/dist = get_dist(src, L)
	score += max(20 - dist, 0) * 2

	// Health factor (lower health = easier kill = priority)
	if(L.health < L.maxHealth * 0.25)
		score += 30 // Finish off weakened targets
	else if(L.health < L.maxHealth * 0.5)
		score += 15

	// Weapon factor (armed targets are more dangerous)
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		if(H.get_active_held_item())
			var/obj/item/I = H.get_active_held_item()
			if(istype(I, /obj/item/gun))
				score += 40 // Guns are high threat
			else if(I.force > 10)
				score += 20 // Dangerous melee weapon

	// Recent damage factor (who hurt us recently)
	if(L in foes)
		score += 25

	// Faction priority (some factions hate each other more)
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		// Check if they're wearing faction armor
		if(istype(H.wear_suit, /obj/item/clothing/suit/armor))
			score += 15 // Armored targets

	return score

/// Get the highest priority target from a list
/mob/living/simple_animal/hostile/proc/get_priority_target(list/possible_targets)
	if(!possible_targets || !possible_targets.len)
		return null

	var/best_target = null
	var/best_score = 0

	for(var/atom/T in possible_targets)
		if(!isliving(T))
			continue

		var/mob/living/L = T
		if(L.stat == DEAD)
			continue

		var/score = calculate_threat_score(T)

		// Use remembered threat scores if available
		var/memory_key = "\ref[T]"
		if(target_threat_scores[memory_key])
			// Blend current score with memory
			score = (score + target_threat_scores[memory_key]) / 2

		if(score > best_score)
			best_score = score
			best_target = T

	// Update threat memory
	if(best_target)
		var/memory_key = "\ref[best_target]"
		target_threat_scores[memory_key] = best_score

	return best_target

/// Clean up old threat memories
/mob/living/simple_animal/hostile/proc/cleanup_threat_memory()
	if(target_threat_scores.len > 20)
		target_threat_scores.Cut()

// ============================================
// FLANKING PROCS
// ============================================

/// Determine if flanking is viable and start flanking
/mob/living/simple_animal/hostile/proc/attempt_flank()
	if(!target || flanking)
		return FALSE

	if(world.time - last_flank_time < flank_cooldown)
		return FALSE

	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)

	if(!my_turf || !target_turf)
		return FALSE

	// Check if there are allies also attacking this target
	var/allies_attacking = 0
	for(var/mob/living/simple_animal/hostile/M in range(7, target))
		if(M == src)
			continue
		if(!faction_check_mob(M, TRUE))
			continue
		if(M.target == target)
			allies_attacking++

	// Only flank if we have allies attacking (coordination)
	if(allies_attacking < 1)
		return FALSE

	// Choose flank direction
	flank_direction = pick(FLANK_LEFT, FLANK_RIGHT)
	flank_start_pos = my_turf
	flanking = TRUE
	last_flank_time = world.time

	return TRUE

/// Move to flanking position
/mob/living/simple_animal/hostile/proc/move_to_flank_position()
	if(!flanking || !target)
		return

	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return

/// Calculate perpendicular direction
	var/direction_to_target = get_dir(src, target)
	var/flank_dir = turn(direction_to_target, flank_direction == FLANK_LEFT ? -90 : 90)

	// Find a good flanking position
	var/turf/flank_pos = get_ranged_target_turf(target, flank_dir, flank_distance)

	// Check if position is valid
	if(flank_pos && !flank_pos.density)
		Goto(flank_pos, move_to_delay, minimum_distance)
	else
		// Try shorter distance
		flank_pos = get_ranged_target_turf(target, flank_dir, flank_distance / 2)
		if(flank_pos && !flank_pos.density)
			Goto(flank_pos, move_to_delay, minimum_distance)

/// Check if we've completed flanking
/mob/living/simple_animal/hostile/proc/check_flank_complete()
	if(!flanking || !flank_start_pos)
		return TRUE

	var/current_dist = get_dist(src, target)
	var/start_dist = get_dist(flank_start_pos, target)

	// We've moved into a flanking position if:
	// 1. We're closer now
	// 2. We've moved a significant distance
	var/moved_closer = current_dist < start_dist
	var/moved_away_from_start = get_dist(src, flank_start_pos) >= 3

	if(moved_closer && moved_away_from_start)
		flanking = FALSE
		return TRUE

	return FALSE

// ============================================
// GROUP COORDINATION PROCS
// ============================================

/// Broadcast target position to nearby allies
/mob/living/simple_animal/hostile/proc/broadcast_target_position()
	if(!target)
		return

	var/turf/target_loc = get_turf(target)
	if(!target_loc)
		return

	for(var/mob/living/simple_animal/hostile/M in range(aggro_vision_range, src))
		if(M == src || M.stat == DEAD)
			continue
		if(!faction_check_mob(M, TRUE))
			continue

		// Share target information
		M.last_known_location = target_loc
		M.remembered_target = target

/// Assign roles in combat group
/mob/living/simple_animal/hostile/proc/assign_combat_roles()
	var/list/nearby_allies = list()

	for(var/mob/living/simple_animal/hostile/M in range(7, src))
		if(M == src || M.stat == DEAD)
			continue
		if(!faction_check_mob(M, TRUE))
			continue
		if(M.target != target)
			continue
		nearby_allies += M

	if(nearby_allies.len < 1)
		return

	// Simple role assignment based on mob type
	// Tanks: High health, melee
	// Flankers: Fast, medium health
	// Support: Ranged

	for(var/mob/living/simple_animal/hostile/M in nearby_allies)
		if(M.health >= M.maxHealth * 0.75 && !M.ranged)
			M.combat_role = ROLE_TANK
		else if(M.move_to_delay <= 2)
			M.combat_role = ROLE_FLANKER
		else if(M.ranged)
			M.combat_role = ROLE_SUPPORT
		else
			M.combat_role = ROLE_ATTACKER

/// Coordinate attack with allies
/mob/living/simple_animal/hostile/proc/coordinate_attack()
	if(!target)
		return

	if(world.time - last_coordination_time < coordination_interval)
		return

	last_coordination_time = world.time

	// Count allies attacking target
	var/allies_engaged = 0
	var/allies_flanking = 0

	for(var/mob/living/simple_animal/hostile/M in range(7, target))
		if(M == src || M.stat == DEAD)
			continue
		if(!faction_check_mob(M, TRUE))
			continue
		if(M.target == target)
			allies_engaged++
			if(M.flanking)
				allies_flanking++

	// Tactical decisions based on numbers
	if(allies_engaged >= 2 && allies_flanking < 1)
		// We have numbers, try to flank
		attempt_flank()

	if(allies_engaged >= 3)
		// Enough allies, spread out
		spread_from_allies()

/// Spread out from allies to avoid clustering
/mob/living/simple_animal/hostile/proc/spread_from_allies()
	if(!target)
		return

	var/turf/my_turf = get_turf(src)
	if(!my_turf)
		return

	// Find average position of allies
	var/avg_x = 0
	var/avg_y = 0
	var/ally_count = 0

	for(var/mob/living/simple_animal/hostile/M in range(5, src))
		if(M == src || !faction_check_mob(M, TRUE))
			continue
		var/turf/M_turf = get_turf(M)
		if(M_turf)
			avg_x += M_turf.x
			avg_y += M_turf.y
			ally_count++

	if(ally_count < 1)
		return

	avg_x /= ally_count
	avg_y /= ally_count

	// Move away from cluster center
	var/direction = get_dir(my_turf, locate(avg_x, avg_y, my_turf.z))
	var/opposite_dir = turn(direction, 180)
	var/turf/spread_turf = get_step(my_turf, opposite_dir)

	if(spread_turf && !spread_turf.density)
		Move(spread_turf)

// ============================================
// INVESTIGATION PROCS
// ============================================

/// Investigate a suspicious sound or movement
/mob/living/simple_animal/hostile/proc/investigate_suspicious_activity(turf/location, reason = "sound")
	if(!location || investigation_target)
		return

	investigation_target = location
	investigation_reason = reason
	investigation_start_time = world.time

	// Move to investigate
	Goto(location, move_to_delay, 2)

/// Check investigation status
/mob/living/simple_animal/hostile/proc/check_investigation()
	if(!investigation_target)
		return

	// Timeout check
	if(world.time - investigation_start_time > max_investigation_time)
		clear_investigation()
		return

	// Reached investigation target
	var/dist = get_dist(src, investigation_target)
	if(dist <= 2)
		// Look around
		if(prob(50))
			setDir(pick(NORTH, SOUTH, EAST, WEST))

		// Look in containers
		if(prob(30))
			check_nearby_hiding_spots()

		// Clear investigation after a moment
		if(world.time - investigation_start_time > 30)
			clear_investigation()

/// Check nearby containers and hiding spots
/mob/living/simple_animal/hostile/proc/check_nearby_hiding_spots()
	for(var/obj/structure/closet/C in range(2, src))
		if(C.opened)
			continue
		// We're checking this container
		visible_message(span_notice("[src] investigates [C]..."))

/// Clear investigation state
/mob/living/simple_animal/hostile/proc/clear_investigation()
	investigation_target = null
	investigation_reason = ""
	investigation_start_time = 0

// ============================================
// INTEGRATION HOOKS
// ============================================

/// Hook into handle_automated_action for cover behavior
/mob/living/simple_animal/hostile/proc/handle_cover_behavior()
	if(!uses_cover || !target)
		return

	// Check if we should seek cover
	var/should_seek_cover = FALSE

	// Low health - seek cover
	if(health < maxHealth * cover_health_threshold)
		should_seek_cover = TRUE

	// Under fire (recently shot)
	if(world.time - last_combat_sound < 50)
		should_seek_cover = TRUE

	if(should_seek_cover && !in_cover)
		move_to_cover()

	// In cover behavior
	if(in_cover)
		// Time to peek and shoot?
		if(world.time - cover_entered_time > cover_stay_duration)
			if(ranged && COOLDOWN_FINISHED(src, ranged_cooldown))
				peek_from_cover()

/// Hook into PickTarget for prioritization
/mob/living/simple_animal/hostile/proc/smart_pick_target(list/Targets)
	if(!Targets || !Targets.len)
		return null

	// Use prioritization system
	return get_priority_target(Targets)

/// Hook for group coordination
/mob/living/simple_animal/hostile/proc/handle_group_coordination()
	if(!target)
		return

	// Periodic coordination
	if(world.time - last_coordination_time > coordination_interval)
		coordinate_attack()

		// Share target info
		broadcast_target_position()

// ============================================
// ANTI-KITE PROCS
// ============================================

/// Instant reaction when attacked - bypasses the 1-second SSnpcpool tick delay
/// Called from bullet_act and adjustHealth when the mob takes damage
/mob/living/simple_animal/hostile/proc/instant_react_to_attack(atom/attacker)
	if(!attacker || stat != CONSCIOUS || client)
		return

	// Face the attacker immediately
	var/face_dir = get_dir(src, attacker)
	if(face_dir)
		setDir(face_dir)

	// Anti-kite mobs dodge sideways instantly
	if(anti_kite && can_dodge_shots)
		try_dodge_shot()

	// Start moving toward attacker immediately (don't wait for next tick)
	if(target && CHECK_BITFIELD(mobility_flags, MOBILITY_MOVE))
		Goto(target, move_to_delay, minimum_distance)

	// Ranged mobs fire back immediately
	if(ranged && target && COOLDOWN_FINISHED(src, ranged_cooldown))
		OpenFire(target)

/// Main anti-kite handler - called from handle_automated_action
/mob/living/simple_animal/hostile/proc/handle_anti_kite()
	if(!target || !anti_kite)
		return

	if(can_lunge)
		try_lunge()

/// After veering sideways, step back toward target to maintain approach
/mob/living/simple_animal/hostile/proc/step_toward_target()
	if(!target || stat != CONSCIOUS)
		return
	var/dir_to_target = get_dir(src, target)
	if(dir_to_target)
		var/turf/T = get_step(src, dir_to_target)
		if(T)
			Move(T, dir_to_target)

/// Lunge/charge toward target to close distance
/mob/living/simple_animal/hostile/proc/try_lunge()
	if(!target)
		return

	if(world.time - last_lunge < lunge_cooldown)
		return

	var/dist = get_dist(src, target)
	if(dist < lunge_range_min || dist > lunge_range_max)
		return

	if(!prob(lunge_chance))
		return

	var/turf/my_turf = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!my_turf || !target_turf)
		return

	if(!can_see(src, target, lunge_range_max + 1))
		return

	last_lunge = world.time

	if(lunge_is_teleport)
		// Flying lunge - teleport to a tile adjacent to target
		var/list/valid_turfs = list()
		for(var/dir in GLOB.cardinals)
			var/turf/T = get_step(target_turf, dir)
			if(T && !T.density)
				var/blocked = FALSE
				for(var/atom/A in T)
					if(A.density && !ismob(A))
						blocked = TRUE
						break
				if(!blocked)
					valid_turfs += T
		if(valid_turfs.len)
			var/turf/landing = pick(valid_turfs)
			visible_message(span_danger("[src] swoops toward [target]!"))
			forceMove(landing)
			setDir(get_dir(src, target))
	else
		// Ground charge - rapidly step toward target over several tiles
		var/dir_to_target = get_dir(src, target)
		var/steps = min(dist - 1, 4)
		visible_message(span_danger("[src] charges toward [target]!"))
		for(var/i in 1 to steps)
			var/turf/next = get_step(src, dir_to_target)
			if(!next || next.density)
				break
			var/blocked = FALSE
			for(var/atom/A in next)
				if(A.density && !ismob(A))
					blocked = TRUE
					break
			if(blocked)
				break
			Move(next, dir_to_target)
		setDir(get_dir(src, target))

/// Dodge incoming projectile by sidestepping
/mob/living/simple_animal/hostile/proc/try_dodge_shot()
	if(!can_dodge_shots)
		return FALSE

	if(world.time - last_dodge < dodge_cooldown)
		return FALSE

	if(!prob(dodge_chance))
		return FALSE

	if(!target)
		return FALSE

	var/dir_to_target = get_dir(src, target)
	if(!dir_to_target)
		return FALSE

	// Dodge perpendicular to the shooter
	var/dodge_dir = pick(turn(dir_to_target, 90), turn(dir_to_target, -90))
	var/turf/dodge_turf = get_step(src, dodge_dir)

	if(!dodge_turf || dodge_turf.density)
		return FALSE

	last_dodge = world.time
	Move(dodge_turf, dodge_dir)
	return TRUE

// ============================================
// TACTICAL AI PROCS
// ============================================

/// Main tactical handler - called from handle_automated_action
/mob/living/simple_animal/hostile/proc/handle_tactical_ai()
	if(!target)
		retreating = FALSE
		return

	// Retreat when badly hurt
	if(can_retreat)
		handle_retreat()

	// Use stimpak when hurt
	if(can_use_stimpak)
		handle_stimpak()

	// Throw grenades at clustered enemies
	if(can_throw_grenades && !retreating)
		handle_grenade_throw()

	// Suppression fire to pin targets
	if(can_suppress && ranged && !retreating)
		handle_suppression()

// ============================================
// RETREAT & REGROUP
// ============================================

/// Handle retreat behavior - fall back when badly hurt
/mob/living/simple_animal/hostile/proc/handle_retreat()
	if(!can_retreat || !target)
		return

	var/health_ratio = health / maxHealth

	// Start retreating if below threshold
	if(health_ratio <= retreat_health_threshold && !retreating)
		retreating = TRUE
		// Find nearest ally to retreat toward
		var/mob/living/simple_animal/hostile/nearest_ally = null
		var/closest_dist = 999
		for(var/mob/living/simple_animal/hostile/M in range(10, src))
			if(M == src || M.stat == DEAD)
				continue
			if(!faction_check_mob(M, TRUE))
				continue
			var/dist = get_dist(src, M)
			if(dist < closest_dist)
				closest_dist = dist
				nearest_ally = M

		if(nearest_ally)
			Goto(nearest_ally, move_to_delay * 0.7, 2)
		else
			// No allies nearby, just run away
			walk_away(src, target, 7, move_to_delay)
		return

	// Stop retreating if health recovered
	if(health_ratio > retreat_health_threshold * 1.5)
		retreating = FALSE
		walk(src, 0)

// ============================================
// STIMPAK / SELF-HEAL
// ============================================

/// Use a stimpak/healing item on self
/mob/living/simple_animal/hostile/proc/handle_stimpak()
	if(!can_use_stimpak)
		return

	if(world.time - last_stimpak_use < stimpak_cooldown)
		return

	var/health_ratio = health / maxHealth
	if(health_ratio > stimpak_threshold)
		return

	last_stimpak_use = world.time

	// Apply healing directly (simulates using a stimpak)
	var/heal_amount = round(maxHealth * 0.3)
	adjustHealth(-heal_amount)
	visible_message(span_notice("[src] applies a healing patch!"))

// ============================================
// GRENADE THROWING
// ============================================

/// Throw a grenade at clustered enemies
/mob/living/simple_animal/hostile/proc/handle_grenade_throw()
	if(!can_throw_grenades || !target)
		return

	if(world.time - last_grenade_throw < grenade_cooldown)
		return

	// Count how many enemies are clustered near the target
	var/enemies_near_target = 0
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return

	for(var/mob/living/L in range(grenade_cluster_range, target_turf))
		if(L == src || L.stat == DEAD)
			continue
		if(!faction_check_mob(L, TRUE))
			enemies_near_target++

	if(enemies_near_target < grenade_min_targets)
		return

	// Don't throw if allies are too close to the target
	for(var/mob/living/simple_animal/hostile/M in range(3, target_turf))
		if(M == src)
			continue
		if(faction_check_mob(M, TRUE))
			return

	last_grenade_throw = world.time

	// Create and throw the grenade
	var/turf/throw_target = get_step(target_turf, pick(NORTH, SOUTH, EAST, WEST)) // slight scatter
	var/obj/item/grenade/G = new grenade_type(get_turf(src))
	G.preprime(user = src)
	G.throw_at(throw_target, 7, 2, src)
	visible_message(span_danger("[src] throws a grenade!"))

// ============================================
// SUPPRESSION FIRE
// ============================================

/// Fire rapidly at a target to pin them down
/mob/living/simple_animal/hostile/proc/handle_suppression()
	if(!can_suppress || !ranged || !target)
		return

	if(world.time - last_suppress < suppress_cooldown)
		return

	var/dist = get_dist(src, target)
	if(dist > suppress_range)
		return

	// Check if allies are flanking this target (don't suppress if we're the only one fighting)
	var/allies_engaged = 0
	for(var/mob/living/simple_animal/hostile/M in range(7, target))
		if(M == src || M.stat == DEAD)
			continue
		if(!faction_check_mob(M, TRUE))
			continue
		if(M.target == target && !M.ranged)
			allies_engaged++

	// Only suppress if we have melee allies who can take advantage
	if(allies_engaged < 1)
		return

	last_suppress = world.time

	// Fire multiple shots rapidly to suppress
	visible_message(span_danger("[src] lays down suppressing fire!"))
	for(var/i in 1 to 3)
		if(!target || stat != CONSCIOUS)
			break
		if(COOLDOWN_FINISHED(src, ranged_cooldown))
			OpenFire(target)
		sleep(3)

// ============================================
// AMBUSH BEHAVIOR
// ============================================

/// Set up an ambush near a doorway or corner
/mob/living/simple_animal/hostile/proc/handle_ambush()
	if(!can_ambush || target || ambush_waiting)
		return

	// Only ambush when idle
	if(AIStatus != AI_IDLE)
		return

	// Find a good ambush spot - near a door or corner
	var/turf/ambush_spot = null

	if(can_open_doors)
		// Wait near a closed door
		for(var/obj/structure/simple_door/SD in range(3, src))
			if(SD.density)
				ambush_spot = get_step(SD, pick(GLOB.cardinals))
				break
		if(!ambush_spot)
			for(var/obj/machinery/door/D in range(3, src))
				if(D.density)
					ambush_spot = get_step(D, pick(GLOB.cardinals))
					break

	if(!ambush_spot)
		// Wait near a wall corner
		var/turf/my_turf = get_turf(src)
		if(my_turf)
			for(var/dir in GLOB.cardinals)
				var/turf/adjacent = get_step(my_turf, dir)
				if(adjacent && adjacent.density)
					ambush_spot = my_turf
					break

	if(!ambush_spot || ambush_spot.density)
		return

	// Move to ambush spot and wait
	if(get_dist(src, ambush_spot) > 1)
		Goto(ambush_spot, move_to_delay, 0)

	ambush_waiting = TRUE
	ambush_start_time = world.time
	stop_automated_movement = TRUE

/// Check if ambush should end
/mob/living/simple_animal/hostile/proc/check_ambush()
	if(!ambush_waiting)
		return

	// End ambush if we got a target
	if(target)
		end_ambush()
		return

	// End ambush if patience expired
	if(world.time - ambush_start_time > ambush_patience)
		end_ambush()
		return

/// End ambush state
/mob/living/simple_animal/hostile/proc/end_ambush()
	ambush_waiting = FALSE
	stop_automated_movement = FALSE
