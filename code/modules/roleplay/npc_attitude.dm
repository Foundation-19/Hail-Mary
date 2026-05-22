// Provides attitude-based effects (shop discounts, dialogue options, etc.)

// Attitude thresholds
#define ATTITUDE_FRIENDLY 50
#define ATTITUDE_HOSTILE -50

// Shop price modifiers based on attitude
/proc/get_attitude_price_modifier(mob/living/simple_animal/hostile/npc, mob/living/carbon/human/customer)
	if(!npc || !customer)
		return 1.0
	
	var/attitude = npc.get_player_attitude(customer)
	
	if(attitude >= ATTITUDE_FRIENDLY)
		return 0.8 // 20% discount
	else if(attitude <= ATTITUDE_HOSTILE)
		return 1.5 // 50% markup
	
	return 1.0 // Normal price

// Check if player gets free items from NPC
/proc/can_get_free_gift(mob/living/simple_animal/hostile/npc, mob/living/carbon/human/player)
	if(!npc || !player)
		return FALSE
	
	var/attitude = npc.get_player_attitude(player)
	
	// Only friendly NPCs (attitude >= 50) with high interaction count give free items
	var/datum/npc_memory/memory = npc.get_player_memory(player)
	if(!memory)
		return FALSE
	
	if(attitude >= ATTITUDE_FRIENDLY && memory.times_talked >= 10 && prob(20))
		return TRUE
	
	return FALSE

// Check if dialogue option is available based on attitude
/proc/can_access_attitude_dialogue(mob/living/simple_animal/hostile/npc, mob/living/carbon/human/player, min_attitude = 0)
	if(!npc || !player)
		return FALSE
	
	var/attitude = npc.get_player_attitude(player)
	return attitude >= min_attitude

// Get attitude-based service quality modifier
/proc/get_attitude_service_modifier(mob/living/simple_animal/hostile/npc, mob/living/carbon/human/customer)
	if(!npc || !customer)
		return 1.0
	
	var/attitude = npc.get_player_attitude(customer)
	
	// Friendly NPCs give better service (healing, repairs, etc.)
	if(attitude >= ATTITUDE_FRIENDLY)
		return 1.25 // 25% bonus to service quality
	else if(attitude <= ATTITUDE_HOSTILE)
		return 0.75 // 25% penalty to service quality
	
	return 1.0

// Attitude-based dialogue availability
/datum/attitude_requirement
	var/min_attitude = 0
	var/max_attitude = 100

/proc/check_attitude_requirement(mob/living/simple_animal/hostile/npc, mob/living/carbon/human/player, list/requirements)
	if(!requirements)
		return TRUE
	
	if(!npc || !player)
		return FALSE
	
	var/attitude = npc.get_player_attitude(player)
	
	if(requirements["min_attitude"])
		if(attitude < requirements["min_attitude"])
			return FALSE
	
	if(requirements["max_attitude"])
		if(attitude > requirements["max_attitude"])
			return FALSE
	
	return TRUE

// Modify shop prices based on attitude
/mob/living/simple_animal/hostile/proc/apply_attitude_to_price(base_price, mob/living/carbon/human/customer)
	var/modifier = get_attitude_price_modifier(src, customer)
	return round(base_price * modifier)

// Check if this NPC will call guards on player
/mob/living/simple_animal/hostile/proc/will_call_guards(mob/living/carbon/human/player)
	if(!player)
		return FALSE
	
	var/attitude = get_player_attitude(player)
	
	// Hostile NPCs will call guards
	if(attitude <= ATTITUDE_HOSTILE)
		return TRUE
	
	// Very negative faction reputation also triggers guards
	var/faction_id = get_faction_for_dialogue(dialogue_type)
	if(faction_id)
		var/faction_rep = get_faction_reputation(player.ckey, faction_id)
		if(faction_rep <= -50)
			return TRUE
	
	return FALSE

// Get attitude-based tips and hints
/mob/living/simple_animal/hostile/proc/get_attitude_hint(mob/living/carbon/human/player)
	if(!player)
		return null
	
	var/attitude = get_player_attitude(player)
	
	if(attitude >= ATTITUDE_FRIENDLY)
		return pick(list(
			"By the way, I heard there's a cache of supplies to the north.",
			"You might want to avoid the eastern road - raiders have been active.",
			"The quartermaster has some extra stimpaks if you need them.",
			"If you're looking for work, the boss has been asking about you."
		))
	else if(attitude <= ATTITUDE_HOSTILE)
		return pick(list(
			"You're on thin ice here.",
			"Don't push your luck.",
			"I'm watching you.",
			"One wrong move..."
		))
	
	return null
