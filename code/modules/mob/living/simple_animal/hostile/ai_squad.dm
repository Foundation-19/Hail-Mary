// Hostile mob squad layer (Hostile AI redesign, phase 5).
// Allied hostile mobs that stand near each other share a /datum/ai_squad: a small blackboard holding the latest
// threat any member reported and the role claims for the current fight.
// - Anchor: the default. Fights from the front and gives the others something to flank around.
// - Flanker: claimed from the squad. Granted only while a squadmate is already holding the target and a slot is
//   free, keeps flankers on different sides, and goes to whoever is nearest its flank tile when the squad is full.
// - Suppressor: ranged mobs hold their ground and keep firing while a flank is underway.
// - Blackboard: a member that lost its target reads the squad's latest threat report as a search lead.
// Squads only keep weakrefs to their members, so they never pin a mob in memory.

/// A flank claim lapses after this long (deciseconds) unless its holder keeps renewing it
#define AI_SQUAD_CLAIM_TIME 80
/// Two flankers of the same target stand at least this many tiles apart
#define AI_SQUAD_FLANK_SPACING 3
/// A bidder takes a full squad's flank slot only when it is this many tiles nearer than the worst-placed holder
#define AI_SQUAD_DISPLACE_MARGIN 4
/// Blackboard threats older than this (deciseconds) are no longer acted on
#define AI_SQUAD_THREAT_FRESH 300
/// A blackboard threat further than this many tiles from a mob is not a lead worth walking to
#define AI_SQUAD_BOARD_RANGE 20
/// Morale a squadmate loses when a nearby member breaks and falls back
#define AI_MORALE_SQUAD_FALLBACK 0.05
#define AI_FLANK_DENY 0
#define AI_FLANK_FREE 1
#define AI_FLANK_RENEW 2
#define AI_FLANK_DISPLACE 3
/// A squad nobody has touched for this long (deciseconds) is discarded
#define AI_SQUAD_IDLE_PRUNE 600

GLOBAL_LIST_EMPTY(ai_squads)
GLOBAL_VAR_INIT(ai_squad_next_id, 1)
/// Flank requests granted, refused and carried through to the target, the gate metric for this phase
GLOBAL_VAR_INIT(ai_squad_flanks_granted, 0)
GLOBAL_VAR_INIT(ai_squad_flanks_denied, 0)
GLOBAL_VAR_INIT(ai_squad_flanks_completed, 0)

/datum/ai_flank_claim
	var/datum/weakref/holder
	var/datum/weakref/target_ref
	var/turf/tile
	var/expires = 0

/datum/ai_squad
	var/id
	/// Weakrefs of the member mobs
	var/list/members = list()
	/// Active /datum/ai_flank_claim entries
	var/list/claims = list()
	/// Blackboard: the latest threat a member reported, where, when and how
	var/datum/weakref/threat_ref
	var/turf/threat_turf
	var/threat_time = 0
	var/last_active = 0

/datum/ai_squad/New(mob/living/simple_animal/hostile/founder)
	. = ..()
	id = GLOB.ai_squad_next_id++
	last_active = world.time
	for(var/datum/ai_squad/old in GLOB.ai_squads)
		if(world.time - old.last_active > AI_SQUAD_IDLE_PRUNE)
			GLOB.ai_squads -= old
	GLOB.ai_squads += src
	if(founder)
		add_member(founder)

/datum/ai_squad/Destroy()
	GLOB.ai_squads -= src
	members = null
	claims = null
	threat_turf = null
	return ..()

/datum/ai_squad/proc/add_member(mob/living/simple_animal/hostile/M)
	members |= WEAKREF(M)
	M.ai_squad = src
	last_active = world.time
	M.ai_debug_log("squad_join squad=[id] members=[length(members)]")

/datum/ai_squad/proc/remove_member(mob/living/simple_animal/hostile/M, reason = "left")
	release_flank(M, reason)
	members -= WEAKREF(M)
	if(M.ai_squad == src)
		M.ai_squad = null
	if(!length(members))
		GLOB.ai_squads -= src

/// Members that are still alive. Forgets the ones that are gone.
/datum/ai_squad/proc/live_members()
	. = list()
	var/list/gone = list()
	for(var/datum/weakref/W in members)
		var/mob/living/simple_animal/hostile/M = W.resolve()
		if(!M || QDELETED(M) || M.stat == DEAD || M.ai_squad != src)
			gone += W
			continue
		. += M
	if(length(gone))
		members -= gone

/// Records a threat on the blackboard. The reporter already knows, so it never reads its own post back.
/datum/ai_squad/proc/note_threat(atom/threat, turf/where, mob/living/simple_animal/hostile/reporter)
	if(!threat || !where)
		return
	threat_ref = WEAKREF(threat)
	threat_turf = where
	threat_time = world.time
	last_active = world.time
	if(reporter)
		reporter.ai_squad_board_read = threat_time

/// A member broke and fell back. Squadmates close enough to see it lose a little nerve, so a pack wavers together
/// instead of every member deciding on its own.
/datum/ai_squad/proc/note_fallback(mob/living/simple_animal/hostile/faller)
	last_active = world.time
	for(var/mob/living/simple_animal/hostile/M in live_members())
		if(M != faller && get_dist(M, faller) <= AI_ALLY_RADIUS)
			M.adjust_ai_morale(-AI_MORALE_SQUAD_FALLBACK, "ally_fell_back")

/datum/ai_squad/proc/claim_is_live(datum/ai_flank_claim/C)
	if(C.expires < world.time)
		return FALSE
	var/mob/living/simple_animal/hostile/H = RESOLVEWEAKREF(C.holder)
	if(!H || QDELETED(H) || H.stat == DEAD || H.ai_squad != src)
		return FALSE
	var/mob/living/T = RESOLVEWEAKREF(C.target_ref)
	if(!T || QDELETED(T) || T.stat == DEAD)
		return FALSE
	return TRUE

/datum/ai_squad/proc/prune_claims()
	for(var/datum/ai_flank_claim/C in claims)
		if(!claim_is_live(C))
			claims -= C
			qdel(C)

/datum/ai_squad/proc/get_claim(mob/living/simple_animal/hostile/M)
	var/datum/weakref/W = WEAKREF(M)
	for(var/datum/ai_flank_claim/C in claims)
		if(C.holder == W)
			return C
	return null

/// Whether a tile keeps the required distance from the other flankers of this target, so the squad spreads out
/datum/ai_squad/proc/flank_tile_free(turf/T, atom/target, mob/living/simple_animal/hostile/asker)
	var/datum/weakref/asker_ref = WEAKREF(asker)
	for(var/datum/ai_flank_claim/C in claims)
		if(C.holder == asker_ref || C.expires < world.time)
			continue
		if(RESOLVEWEAKREF(C.target_ref) != target)
			continue
		if(get_dist(C.tile, T) < AI_SQUAD_FLANK_SPACING)
			return FALSE
	return TRUE

/// Flankers allowed against one target, by how many squadmates are fighting it
/datum/ai_squad/proc/flank_slots(engaged)
	if(engaged >= 6)
		return 3
	if(engaged >= 3)
		return 2
	return 1

/// Works out whether M may flank target, without changing anything. Returns list(verdict, claim to take over, reason).
/// A full squad still lets a bidder in when it is clearly nearer its flank tile than the worst-placed holder, so the
/// ally best positioned for the flank ends up with the job.
/datum/ai_squad/proc/evaluate_flank(mob/living/simple_animal/hostile/M, atom/target, turf/tile)
	prune_claims()
	var/datum/ai_flank_claim/mine = get_claim(M)
	if(mine && RESOLVEWEAKREF(mine.target_ref) == target)
		return list(AI_FLANK_RENEW, mine, null)

	var/engaged = 0
	var/anchors = 0
	for(var/mob/living/simple_animal/hostile/A in live_members())
		if(A.target != target)
			continue
		engaged++
		if(A != M && !get_claim(A))
			anchors++
	if(!anchors)
		return list(AI_FLANK_DENY, null, "no_anchor engaged=[engaged]")

	var/held = 0
	var/datum/ai_flank_claim/worst
	var/worst_dist = -1
	for(var/datum/ai_flank_claim/C in claims)
		if(RESOLVEWEAKREF(C.target_ref) != target)
			continue
		held++
		var/atom/holder = RESOLVEWEAKREF(C.holder)
		var/dist = get_dist(holder, C.tile)
		if(dist > worst_dist)
			worst_dist = dist
			worst = C
	if(held < flank_slots(engaged))
		return list(AI_FLANK_FREE, null, null)
	if(worst && get_dist(M, tile) + AI_SQUAD_DISPLACE_MARGIN <= worst_dist)
		return list(AI_FLANK_DISPLACE, worst, null)
	return list(AI_FLANK_DENY, null, "slots_full engaged=[engaged] held=[held]")

/// Read-only check used while scoring intents
/datum/ai_squad/proc/can_flank(mob/living/simple_animal/hostile/M, atom/target, turf/tile)
	var/list/verdict = evaluate_flank(M, target, tile)
	if(verdict[1] != AI_FLANK_DENY)
		return TRUE
	GLOB.ai_squad_flanks_denied++
	M.ai_debug_log("squad_flank_denied squad=[id] reason=[verdict[3]] denied=[GLOB.ai_squad_flanks_denied]")
	return FALSE

/// Takes the claim once the mob has actually chosen to flank. A holder that is displaced loses the claim and falls
/// back to fighting from the front.
/datum/ai_squad/proc/claim_flank(mob/living/simple_animal/hostile/M, atom/target, turf/tile)
	last_active = world.time
	var/list/verdict = evaluate_flank(M, target, tile)
	var/datum/ai_flank_claim/C
	switch(verdict[1])
		if(AI_FLANK_DENY)
			return FALSE
		if(AI_FLANK_RENEW)
			C = verdict[2]
		else
			release_flank(M, "target_changed")
			if(verdict[1] == AI_FLANK_DISPLACE)
				var/datum/ai_flank_claim/old = verdict[2]
				var/mob/living/simple_animal/hostile/loser = RESOLVEWEAKREF(old.holder)
				if(loser)
					release_flank(loser, "displaced_by_nearer ally=[REF(M)]")
			C = new
			C.holder = WEAKREF(M)
			C.target_ref = WEAKREF(target)
			claims += C
			GLOB.ai_squad_flanks_granted++
			M.ai_debug_log("squad_flank_granted squad=[id] tile=[tile.x],[tile.y] displaced=[verdict[1] == AI_FLANK_DISPLACE] granted=[GLOB.ai_squad_flanks_granted] denied=[GLOB.ai_squad_flanks_denied]")
	C.tile = tile
	C.expires = world.time + AI_SQUAD_CLAIM_TIME
	return TRUE

/// Whether a squadmate other than M is currently committed to flanking this target
/datum/ai_squad/proc/flank_active(atom/target, mob/living/simple_animal/hostile/M)
	var/datum/weakref/asker_ref = WEAKREF(M)
	for(var/datum/ai_flank_claim/C in claims)
		if(C.holder == asker_ref || C.expires < world.time)
			continue
		if(RESOLVEWEAKREF(C.target_ref) == target)
			return TRUE
	return FALSE

/datum/ai_squad/proc/release_flank(mob/living/simple_animal/hostile/M, reason = "released")
	var/datum/ai_flank_claim/C = get_claim(M)
	if(!C)
		return
	claims -= C
	qdel(C)
	M.ai_debug_log("squad_flank_released squad=[id] reason=[reason]")

/// The flanker reached its side of the target: the claim is spent and the mob fights from there
/datum/ai_squad/proc/complete_flank(mob/living/simple_animal/hostile/M)
	if(!get_claim(M))
		return
	GLOB.ai_squad_flanks_completed++
	release_flank(M, "arrived completed=[GLOB.ai_squad_flanks_completed]")

/mob/living/simple_animal/hostile
	var/datum/ai_squad/ai_squad
	/// Blackboard threat timestamp this mob has already acted on
	var/ai_squad_board_read = 0

/// A mob that lost its target takes a squadmate's fresher report as a lead, so it follows the squad's picture of
/// where the threat is instead of only what it saw itself. update_search_destination ignores a weaker lead.
/mob/living/simple_animal/hostile/proc/ai_read_squad_board()
	var/datum/ai_squad/S = ai_squad
	if(!S || !S.threat_turf || S.threat_time <= ai_squad_board_read)
		return
	ai_squad_board_read = S.threat_time
	if(world.time - S.threat_time > AI_SQUAD_THREAT_FRESH || S.threat_turf.z != z || get_dist(src, S.threat_turf) > AI_SQUAD_BOARD_RANGE)
		return
	update_search_destination(S.threat_turf, "squad_board", AI_CONF_ALERT)

/// Joins the nearby squad, or founds one. When two squads meet, the smaller one folds into the larger.
/mob/living/simple_animal/hostile/proc/ai_squad_sync(datum/ai_squad/nearby)
	if(ckey || stat == DEAD)
		return
	if(!ai_squad)
		if(nearby)
			nearby.add_member(src)
		else
			new /datum/ai_squad(src)
		return
	if(nearby && nearby != ai_squad && length(nearby.members) >= length(ai_squad.members))
		ai_squad.remove_member(src, "merged")
		nearby.add_member(src)

/mob/living/simple_animal/hostile/proc/ai_get_squad()
	if(!ai_squad)
		ai_squad_sync(null)
	return ai_squad

/mob/living/simple_animal/hostile/proc/ai_squad_leave()
	if(ai_squad)
		ai_squad.remove_member(src, "gone")
	ai_squad = null
