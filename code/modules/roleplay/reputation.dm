// Tracks player standing with different factions
// faction_reputation_cache doubles as write-through cache: populated on first DB read,
// kept in sync on every write, so subsequent reads within a round cost nothing.

GLOBAL_LIST_EMPTY(faction_reputation_cache)

// Global procs for reputation manipulation
/proc/get_faction_reputation(ckey, faction_id)
	if(!ckey || !faction_id)
		return 0

	// Check in-memory cache first
	if(GLOB.faction_reputation_cache[ckey] && !isnull(GLOB.faction_reputation_cache[ckey][faction_id]))
		return GLOB.faction_reputation_cache[ckey][faction_id]

	// Cache miss: try database
	if(SSdbcore.Connect())
		var/datum/db_query/query = SSdbcore.NewQuery(
			"SELECT reputation_value FROM [format_table_name("faction_reputation")] WHERE ckey = :ckey AND faction_id = :faction_id",
			list("ckey" = ckey, "faction_id" = faction_id)
		)
		
		if(!query.Execute())
			qdel(query)
			return 0
		
		var/rep_value = 0
		if(query.NextRow())
			rep_value = text2num(query.item[1]) || 0
		
		qdel(query)
		LAZYINITLIST(GLOB.faction_reputation_cache[ckey])
		GLOB.faction_reputation_cache[ckey][faction_id] = rep_value
		return rep_value

	// No DB: return 0 (cache was already uninitialised, nothing to fall back to)
	return 0

/proc/set_faction_reputation(ckey, faction_id, value)
	if(!ckey || !faction_id)
		return FALSE

	// Always update the in-memory cache
	LAZYINITLIST(GLOB.faction_reputation_cache[ckey])
	GLOB.faction_reputation_cache[ckey][faction_id] = value

	// Try database
	if(SSdbcore.Connect())
		var/datum/db_query/query = SSdbcore.NewQuery(
			"INSERT INTO [format_table_name("faction_reputation")] (ckey, faction_id, reputation_value, rank_title, last_updated) VALUES (:ckey, :faction_id, :value, :rank, NOW()) ON DUPLICATE KEY UPDATE reputation_value = :value, rank_title = :rank, last_updated = NOW()",
			list("ckey" = ckey, "faction_id" = faction_id, "value" = value, "rank" = get_faction_rank(faction_id, value))
		)
		
		var/success = query.Execute()
		qdel(query)
		return success

	return TRUE

/proc/adjust_faction_reputation(ckey, faction_id, amount)
	var/current = get_faction_reputation(ckey, faction_id)
	var/new_value = clamp(current + amount, -100, 250)
	set_faction_reputation(ckey, faction_id, new_value)
	
	// Show feedback to player - iterate through player list
	var/mob/M
	for(var/mob/L in GLOB.player_list)
		if(L.ckey == ckey)
			M = L
			break
	
	if(M && abs(amount) >= 5)
		to_chat(M, span_notice("[amount > 0 ? "+" : ""][amount] Reputation with [get_faction_name(faction_id)]"))
	
	// Check for rank changes
	var/old_rank = get_faction_rank(faction_id, current)
	var/new_rank = get_faction_rank(faction_id, new_value)
	if(old_rank != new_rank && M)
		to_chat(M, span_boldnotice("Your rank with [get_faction_name(faction_id)] is now [new_rank]!"))
	
	return new_value

// Mob helper procs
/mob/proc/get_faction_reputation(faction_id)
	return get_faction_reputation(ckey, faction_id)

/mob/proc/adjust_faction_reputation(faction_id, amount)
	return adjust_faction_reputation(ckey, faction_id, amount)

/mob/proc/get_all_faction_reputations()
	if(!ckey)
		return list()
	
	// Try database first
	if(SSdbcore.Connect())
		var/datum/db_query/query = SSdbcore.NewQuery(
			"SELECT faction_id, reputation_value, rank_title FROM [format_table_name("faction_reputation")] WHERE ckey = :ckey",
			list("ckey" = ckey)
		)
		
		var/list/reputations = list()
		if(query.Execute())
			while(query.NextRow())
				var/faction_id = query.item[1]
				var/rep_value = text2num(query.item[2]) || 0
				var/rank_title = query.item[3]
				reputations[faction_id] = list("value" = rep_value, "rank" = rank_title)
		
		qdel(query)
		return reputations
	
	// Fallback to memory cache
	if(GLOB.faction_reputation_cache[ckey])
		var/list/reputations = list()
		for(var/faction_id in GLOB.faction_reputation_cache[ckey])
			var/rep_value = GLOB.faction_reputation_cache[ckey][faction_id]
			reputations[faction_id] = list("value" = rep_value, "rank" = get_faction_rank(faction_id, rep_value))
		return reputations
	
	return list()

// Check if player meets reputation requirement (used for job selection)
/proc/check_faction_requirement(ckey, faction_id, required_rep)
	var/current_rep = get_faction_reputation(ckey, faction_id)
	return current_rep >= required_rep

// Get vendor access level based on reputation
/proc/get_vendor_access_level(ckey, faction_id)
	var/rep = get_faction_reputation(ckey, faction_id)
	switch(faction_id)
		if("ncr")
			if(rep >= 100)
				return 3 // Premium
			if(rep >= 50)
				return 2 // Advanced
			if(rep >= 25)
				return 1 // Standard
			return 0 // No access
		
		if("legion")
			if(rep >= 75)
				return 3
			if(rep >= 25)
				return 2
			if(rep >= 0)
				return 1
			return 0
		
		if("bos")
			if(rep >= 100)
				return 3
			if(rep >= 50)
				return 2
			if(rep >= 25)
				return 1
			return 0
	
	return 0

// Admin verbs for manipulating reputation
/client/proc/set_faction_reputation()
	set category = "Admin"
	set name = "Set Faction Reputation"
	set desc = "Set a player's reputation with a faction"
	
	var/ckey_input = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!ckey_input)
		return
	
	var/faction_choice = input(src, "Choose faction:", "Faction") as null|anything in GLOB.factions
	if(!faction_choice)
		return
	
	var/new_value = input(src, "Enter new reputation value (-100 to 250):", "Reputation") as num|null
	if(isnull(new_value))
		return
	
	new_value = clamp(new_value, -100, 250)
	set_faction_reputation(ckey_input, faction_choice, new_value)
	
	log_admin("[key_name(src)] set [ckey_input]'s reputation with [faction_choice] to [new_value]")
	message_admins("[key_name(src)] set [ckey_input]'s reputation with [faction_choice] to [new_value]")

/client/proc/adjust_faction_reputation()
	set category = "Admin"
	set name = "Adjust Faction Reputation"
	set desc = "Adjust a player's reputation with a faction"
	
	var/ckey_input = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!ckey_input)
		return
	
	var/faction_choice = input(src, "Choose faction:", "Faction") as null|anything in GLOB.factions
	if(!faction_choice)
		return
	
	var/amount = input(src, "Enter adjustment amount:", "Amount") as num|null
	if(isnull(amount))
		return
	
	adjust_faction_reputation(ckey_input, faction_choice, amount)
	
	log_admin("[key_name(src)] adjusted [ckey_input]'s reputation with [faction_choice] by [amount]")
	message_admins("[key_name(src)] adjusted [ckey_input]'s reputation with [faction_choice] by [amount]")
