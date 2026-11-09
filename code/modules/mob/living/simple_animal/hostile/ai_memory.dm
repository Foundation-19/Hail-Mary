// Hostile mob working memory (Hostile AI redesign, phase 2).
// A short-lived fact store: each fact has a timestamp and a confidence that decays with age, so a mob can
// weigh a fresh gunshot against a stale sighting instead of letting whichever event ran last win.

#define AI_FACT_THREAT 1
#define AI_FACT_HIT_FROM 2
#define AI_FACT_BURNED_DOOR 3
#define AI_FACT_ALLY_DEAD 4

// Starting confidence by evidence type (0-1)
#define AI_CONF_SIGHT 1
#define AI_CONF_HIT_FROM 0.9
#define AI_CONF_ALERT 0.8
#define AI_CONF_GUNSHOT 0.7
#define AI_CONF_REAR_SOUND 0.6
#define AI_CONF_COMBAT_SOUND 0.5
#define AI_CONF_IMPACT_SOUND 0.4
#define AI_CONF_LIGHT 0.3

#define AI_MEMORY_MAX_FACTS 10
#define AI_MEMORY_MAX_THREATS 3
/// Facts fade to nothing over this long (deciseconds)
#define AI_FACT_LIFETIME 600
/// The current search destination fades faster than a fact, so fresh noise can outweigh an old sighting
#define AI_DEST_DECAY 100
#define AI_FACT_MIN_STRENGTH 0.05
/// A door we already checked stays "burned" for this long (deciseconds)
#define AI_BURNED_DOOR_MEMORY 300

/datum/ai_fact
	var/fact_type
	var/turf/location
	var/datum/weakref/subject
	var/created = 0
	var/confidence = 0
	var/source

/// Confidence after decay
/datum/ai_fact/proc/strength()
	return confidence * max(0, 1 - (world.time - created) / AI_FACT_LIFETIME)

/mob/living/simple_animal/hostile
	/// Working memory: /datum/ai_fact entries, capped at AI_MEMORY_MAX_FACTS
	var/list/ai_facts
	/// Confidence and time of the evidence behind last_known_location, used to rank competing destinations
	var/search_dest_confidence = 0
	var/search_dest_time = 0

/mob/living/simple_animal/hostile/proc/prune_ai_facts()
	for(var/datum/ai_fact/F in ai_facts)
		if(F.strength() < AI_FACT_MIN_STRENGTH)
			ai_facts -= F
			qdel(F)

/// The weakest fact of a type (or of any type when null), the first to be forgotten when memory is full
/mob/living/simple_animal/hostile/proc/weakest_ai_fact(fact_type)
	var/datum/ai_fact/weakest
	var/weakest_strength = INFINITY
	for(var/datum/ai_fact/F in ai_facts)
		if(fact_type && F.fact_type != fact_type)
			continue
		var/fact_strength = F.strength()
		if(fact_strength < weakest_strength)
			weakest = F
			weakest_strength = fact_strength
	return weakest

/// Stores or refreshes a fact. A fact about the same subject (or the same spot, for anonymous noise) is updated
/// only by evidence at least as strong as what is already remembered.
/mob/living/simple_animal/hostile/proc/remember_fact(fact_type, turf/location, confidence, atom/subject, source)
	if(!location)
		return null
	prune_ai_facts()
	LAZYINITLIST(ai_facts)

	for(var/datum/ai_fact/existing in ai_facts)
		if(existing.fact_type != fact_type)
			continue
		var/same_fact
		if(subject)
			same_fact = (RESOLVEWEAKREF(existing.subject) == subject)
		else
			same_fact = (existing.location.z == location.z && get_dist(existing.location, location) <= 2)
		if(!same_fact)
			continue
		if(confidence >= existing.strength())
			existing.location = location
			existing.created = world.time
			existing.confidence = confidence
			existing.source = source
		return existing

	var/datum/ai_fact/fact = new
	fact.fact_type = fact_type
	fact.location = location
	if(subject)
		fact.subject = WEAKREF(subject)
	fact.created = world.time
	fact.confidence = confidence
	fact.source = source
	ai_facts += fact
	ai_debug_log("fact_add type=[fact_type] source=[source] confidence=[confidence] at=[location.x],[location.y],[location.z]")

	if(fact_type == AI_FACT_THREAT)
		var/threat_count = 0
		for(var/datum/ai_fact/F in ai_facts)
			if(F.fact_type == AI_FACT_THREAT)
				threat_count++
		if(threat_count > AI_MEMORY_MAX_THREATS)
			var/datum/ai_fact/weakest_threat = weakest_ai_fact(AI_FACT_THREAT)
			ai_facts -= weakest_threat
			qdel(weakest_threat)
	while(length(ai_facts) > AI_MEMORY_MAX_FACTS)
		var/datum/ai_fact/weakest = weakest_ai_fact()
		ai_facts -= weakest
		qdel(weakest)
	return fact

/// Strength of the evidence behind the current search destination
/mob/living/simple_animal/hostile/proc/get_destination_strength()
	return search_dest_confidence * max(0, 1 - (world.time - search_dest_time) / AI_DEST_DECAY)

/// Doors this mob checked recently, so a fresh search does not re-open them
/mob/living/simple_animal/hostile/proc/get_burned_doors()
	. = list()
	for(var/datum/ai_fact/F in ai_facts)
		if(F.fact_type != AI_FACT_BURNED_DOOR || (world.time - F.created) > AI_BURNED_DOOR_MEMORY)
			continue
		var/atom/door = RESOLVEWEAKREF(F.subject)
		if(door && !QDELETED(door))
			. += door

/mob/living/simple_animal/hostile/proc/mark_door_searched(atom/door)
	searched_doors += door
	remember_fact(AI_FACT_BURNED_DOOR, get_turf(door), AI_CONF_SIGHT, door, "searched")

/// Called on nearby allies when one of the pack dies: remember where, and go look if idle.
/mob/living/simple_animal/hostile/proc/hear_ally_death(turf/where, mob/living/simple_animal/hostile/dead_ally)
	if(stat == DEAD || ckey || !where)
		return
	remember_fact(AI_FACT_ALLY_DEAD, where, AI_CONF_ALERT, dead_ally, "ally_death")
	if(target)
		return
	if(AIStatus == AI_IDLE || AIStatus == AI_Z_OFF)
		toggle_ai(AI_ON)
	update_search_destination(get_sound_investigation_spot(where, 2), "ally_death", AI_CONF_COMBAT_SOUND)
	if(!searching)
		enter_search_mode()

/mob/living/simple_animal/hostile/proc/broadcast_ally_death()
	var/turf/where = get_turf(src)
	if(!where)
		return
	for(var/mob/living/simple_animal/hostile/M in range(backup_call_range, where))
		if(M == src || M.stat == DEAD || M.ckey)
			continue
		if(faction_check_mob(M, TRUE))
			M.hear_ally_death(where, src)
