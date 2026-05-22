// Simplified trigger system with cooldowns

// Cooldown globals
GLOBAL_LIST_INIT(karma_cooldowns, list())

/proc/get_karma_cooldown(ckey, action_type)
	var/list/cooldowns = GLOB.karma_cooldowns[ckey]
	if(!cooldowns)
		return 0
	return cooldowns[action_type] || 0

/proc/set_karma_cooldown(ckey, action_type, duration)
	LAZYINITLIST(GLOB.karma_cooldowns[ckey])
	GLOB.karma_cooldowns[ckey][action_type] = world.time + duration

/proc/check_karma_cooldown(ckey, action_type, duration)
	var/last_action = get_karma_cooldown(ckey, action_type)
	if(last_action && world.time < last_action)
		return FALSE
	set_karma_cooldown(ckey, action_type, duration)
	return TRUE

// ============ REPUTATION SPECIFIC TRIGGERS ============

// Reputation changes based on actions - called from death hooks
/proc/modify_rep_by_action_trigger(ckey, action_type)
	switch(action_type)
		// NCR Related
		if("kill_ncr_soldier")
			adjust_faction_reputation(ckey, "ncr", -15)
			adjust_faction_reputation(ckey, "legion", 5)
		
		if("kill_legion_soldier")
			adjust_faction_reputation(ckey, "legion", -15)
			adjust_faction_reputation(ckey, "ncr", 5)
		
		if("kill_bos_knight")
			adjust_faction_reputation(ckey, "bos", -20)
		
		if("complete_ncr_mission")
			adjust_faction_reputation(ckey, "ncr", 10)
			adjust_faction_reputation(ckey, "legion", -5)
		
		if("complete_legion_mission")
			adjust_faction_reputation(ckey, "legion", 10)
			adjust_faction_reputation(ckey, "ncr", -5)
		
		if("complete_bos_mission")
			adjust_faction_reputation(ckey, "bos", 15)
		
		if("help_civilian_ncr")
			adjust_faction_reputation(ckey, "ncr", 5)
		
		if("steal_from_ncr")
			adjust_faction_reputation(ckey, "ncr", -20)
			adjust_faction_reputation(ckey, "legion", 10)
		
		if("donate_tech_bos")
			adjust_faction_reputation(ckey, "bos", 15)
		
		if("kill_raider")
			adjust_faction_reputation(ckey, "ncr", 2)
			adjust_faction_reputation(ckey, "legion", 2)
		
		if("kill_enclave")
			adjust_faction_reputation(ckey, "ncr", 10)
			adjust_faction_reputation(ckey, "bos", 5)
		
		if("help_followers")
			adjust_faction_reputation(ckey, "followers", 10)
