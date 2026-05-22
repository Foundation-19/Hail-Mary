// Tracks individual NPCs' opinions of specific players

GLOBAL_LIST_EMPTY(npc_memory_cache)

/datum/npc_memory
	var/npc_name
	var/npc_type
	var/player_ckey
	var/times_talked = 0
	var/quests_given = 0
	var/quests_completed = 0
	var/gifts_given = 0
	var/times_attacked = 0
	var/last_interaction = 0
	var/attitude = 0 // -100 to 100, 0 is neutral

/datum/npc_memory/New(npc_name_val, npc_type_val, player_ckey_val)
	npc_name = npc_name_val
	npc_type = npc_type_val
	player_ckey = player_ckey_val
	last_interaction = world.time

/datum/npc_memory/proc/adjust_attitude(amount)
	attitude = clamp(attitude + amount, -100, 100)
	last_interaction = world.time
	save_to_cache()

/datum/npc_memory/proc/save_to_cache()
	var/cache_key = "[npc_name]_[player_ckey]"
	GLOB.npc_memory_cache[cache_key] = src

/proc/get_npc_memory(npc_name, npc_type, player_ckey)
	if(!npc_name || !player_ckey)
		return null
	
	var/cache_key = "[npc_name]_[player_ckey]"
	
	if(GLOB.npc_memory_cache[cache_key])
		return GLOB.npc_memory_cache[cache_key]
	
	// Try loading from database
	if(SSdbcore.Connect())
		var/datum/db_query/query = SSdbcore.NewQuery(
			"SELECT times_talked, quests_given, quests_completed, gifts_given, times_attacked, attitude FROM [format_table_name("npc_memory")] WHERE npc_name = :npc_name AND player_ckey = :ckey",
			list("npc_name" = npc_name, "ckey" = player_ckey)
		)
		if(query.Execute())
			if(query.NextRow())
				var/datum/npc_memory/memory = new(npc_name, npc_type, player_ckey)
				memory.times_talked = text2num(query.item[1]) || 0
				memory.quests_given = text2num(query.item[2]) || 0
				memory.quests_completed = text2num(query.item[3]) || 0
				memory.gifts_given = text2num(query.item[4]) || 0
				memory.times_attacked = text2num(query.item[5]) || 0
				memory.attitude = text2num(query.item[6]) || 0
				qdel(query)
				memory.save_to_cache()
				return memory
		qdel(query)
	
	// Create new memory
	var/datum/npc_memory/new_memory = new(npc_name, npc_type, player_ckey)
	new_memory.save_to_cache()
	return new_memory

/proc/save_npc_memory_to_db(datum/npc_memory/memory)
	if(!memory || !SSdbcore.Connect())
		return FALSE
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"INSERT INTO [format_table_name("npc_memory")] (npc_name, npc_type, player_ckey, times_talked, quests_given, quests_completed, gifts_given, times_attacked, attitude, last_interaction) VALUES (:npc_name, :npc_type, :ckey, :talked, :q_given, :q_completed, :gifts, :attacked, :attitude, NOW()) ON DUPLICATE KEY UPDATE times_talked = VALUES(times_talked), quests_given = VALUES(quests_given), quests_completed = VALUES(quests_completed), gifts_given = VALUES(gifts_given), times_attacked = VALUES(times_attacked), attitude = VALUES(attitude), last_interaction = NOW()",
		list("npc_name" = memory.npc_name, "npc_type" = memory.npc_type, "ckey" = memory.player_ckey, "talked" = memory.times_talked, "q_given" = memory.quests_given, "q_completed" = memory.quests_completed, "gifts" = memory.gifts_given, "attacked" = memory.times_attacked, "attitude" = memory.attitude)
	)
	
	var/result = query.Execute()
	qdel(query)
	return result

/proc/get_attitude_tier(attitude)
	if(attitude >= 50)
		return "friendly"
	if(attitude <= -50)
		return "hostile"
	return "neutral"

/proc/get_attitude_greeting(attitude, dialogue_type)
	var/tier = get_attitude_tier(attitude)
	
	// Try to get from JSON dialogue cache
	if(GLOB.json_dialogue_cache[dialogue_type])
		var/dialogue_data = GLOB.json_dialogue_cache[dialogue_type]
		if(tier == "friendly" && dialogue_data["greeting_friendly"])
			return dialogue_data["greeting_friendly"]
		if(tier == "hostile" && dialogue_data["greeting_hostile"])
			return dialogue_data["greeting_hostile"]
		if(dialogue_data["greeting_neutral"])
			return dialogue_data["greeting_neutral"]
	
	// Default fallbacks
	switch(tier)
		if("friendly")
			return "Oh, it's you! Good to see you again."
		if("hostile")
			return "What do you want? You better watch yourself."
		else
			return null

// Implementation of record_npc_interaction (forward declared in hostile.dm)
/proc/record_npc_interaction(mob/living/simple_animal/hostile/npc, mob/living/carbon/human/player, interaction_type, amount = 1)
	if(!npc || !player || !player.ckey || !npc.dialogue_type)
		return
	
	var/datum/npc_memory/memory = get_npc_memory(npc.name, npc.dialogue_type, player.ckey)
	
	switch(interaction_type)
		if("talked")
			memory.times_talked += amount
			memory.adjust_attitude(1)
		if("quest_given")
			memory.quests_given += amount
		if("quest_completed")
			memory.quests_completed += amount
			memory.adjust_attitude(15)
		if("gift")
			memory.gifts_given += amount
			memory.adjust_attitude(10)
		if("attacked")
			memory.times_attacked += amount
			memory.adjust_attitude(-30)
		if("refused_quest")
			memory.adjust_attitude(-5)
		if("healed")
			memory.adjust_attitude(15)
		if("stole")
			memory.adjust_attitude(-20)
		if("killed_friend")
			memory.adjust_attitude(-15)
	
	save_npc_memory_to_db(memory)

/mob/living/simple_animal/hostile/proc/record_player_interaction(mob/living/carbon/human/player, interaction_type, amount = 1)
	if(!player || !player.ckey || !dialogue_type)
		return
	
	var/datum/npc_memory/memory = get_npc_memory(name, dialogue_type, player.ckey)
	
	switch(interaction_type)
		if("talked")
			memory.times_talked += amount
			memory.adjust_attitude(1)
		if("quest_given")
			memory.quests_given += amount
		if("quest_completed")
			memory.quests_completed += amount
			memory.adjust_attitude(15)
		if("gift")
			memory.gifts_given += amount
			memory.adjust_attitude(10)
		if("attacked")
			memory.times_attacked += amount
			memory.adjust_attitude(-30)
		if("refused_quest")
			memory.adjust_attitude(-5)
		if("healed")
			memory.adjust_attitude(15)
		if("stole")
			memory.adjust_attitude(-20)
		if("killed_friend")
			memory.adjust_attitude(-15)
	
	save_npc_memory_to_db(memory)

/mob/living/simple_animal/hostile/proc/get_player_attitude(mob/living/carbon/human/player)
	if(!player || !player.ckey)
		return 0
	
	var/datum/npc_memory/memory = get_npc_memory(name, dialogue_type, player.ckey)
	return memory.attitude

/mob/living/simple_animal/hostile/proc/get_player_memory(mob/living/carbon/human/player)
	if(!player || !player.ckey)
		return null
	
	return get_npc_memory(name, dialogue_type, player.ckey)
