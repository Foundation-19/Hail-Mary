// Comprehensive action triggers and death integration

// Handle death for reputation/karma changes - called from on_player_death
/proc/handle_death_reputation(mob/living/victim, gibbed)
	if(!victim)
		return
	
	// Get attacker ckey directly from victim
	var/attacker_ckey = victim.lastattackerckey
	
	if(!attacker_ckey || ckey(attacker_ckey) == ckey(victim.ckey))
		return
	
	// Determine victim faction
	var/victim_faction = get_mob_faction(victim)
	
	// Skip if self-kill
	if(ckey(attacker_ckey) == ckey(victim.ckey))
		return
	
	// Apply karma changes
	if(victim_faction)
		var/karma_action = get_karma_action_for_faction(victim_faction)
		var/reason = "Killed [victim.real_name] ([victim_faction])"
		if(karma_action)
			modify_karma_by_action(attacker_ckey, karma_action, null, reason)
		// Apply reputation changes
		apply_kill_reputation(attacker_ckey, victim_faction, victim)
	else
		// No faction - apply generic player kill penalty
		var/reason = "Killed [victim.real_name] (Unknown faction)"
		modify_karma_by_action(attacker_ckey, "kill_player", null, reason)

// Get faction from mob - checks faction list, name, and player job
/proc/get_mob_faction(mob/living/L)
	if(!L)
		return null
	
	// Check explicit faction assignments - handle lists and strings
	if(L.faction)
		var/faction_check = L.faction
		// Handle list factions
		if(islist(faction_check))
			for(var/f in faction_check)
				if(f && istext(f))
					// Try as-is
					if(f in GLOB.factions)
						return f
					// Try uppercase
					var/f_upper = uppertext(f)
					if(f_upper == "NCR")
						return "ncr"
					if(f_upper == "LEGION")
						return "legion"
					if(f_upper == "BROTHERHOOD")
						return "bos"
		else if(istext(faction_check))
			if(faction_check in GLOB.factions)
				return faction_check
			var/f_upper = uppertext(faction_check)
			if(f_upper == "NCR")
				return "ncr"
			if(f_upper == "LEGION")
				return "legion"
	
	// Check if it's a human player - get faction from job
	if(istype(L, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = L
		if(H.mind?.assigned_role)
			var/datum/job/J = H.mind.assigned_role
			if(J.faction)
				return lowertext(J.faction)
	
	// Check name for faction indicators
	var/name_lower = lowertext(L.name)
	if(findtext(name_lower, "ncr") || findtext(name_lower, "ranger"))
		return "ncr"
	if(findtext(name_lower, "legion") || findtext(name_lower, "centurion") || findtext(name_lower, "decanus"))
		return "legion"
	if(findtext(name_lower, "brotherhood") || findtext(name_lower, "paladin") || findtext(name_lower, "vertibird"))
		return "bos"
	if(findtext(name_lower, "enclave"))
		return "enclave"
	if(findtext(name_lower, "raider"))
		return "raiders"
	if(findtext(name_lower, "khan"))
		return "greatkhans"
	if(findtext(name_lower, "ghoul"))
		return "ghoul"
	
	return null

// Get karma action for killing a faction member
/proc/get_karma_action_for_faction(faction_id)
	switch(faction_id)
		if("ncr", "legion", "bos", "enclave")
			return "kill_npc_friendly"
		if("raiders", "vipers", "jackals")
			return "kill_raider"
		if("greatkhans")
			return "kill_player" // Kharma penalty for killing Khans
		if("followers")
			return "kill_npc_friendly" // Negative karma
	
	return "kill_npc_friendly"

// Apply reputation changes for a kill
/proc/apply_kill_reputation(ckey, victim_faction, mob/living/victim)
	if(!ckey || !victim_faction)
		return
	
	// Get kill value based on victim type
	var/kill_value = get_kill_reputation_value(victim)
	
	// Apply direct reputation change
	adjust_faction_reputation(ckey, victim_faction, -kill_value)
	
	// Apply rivalry effects
	apply_rivalry_effects(ckey, victim_faction, kill_value)


// Get reputation value for killing a specific mob
/proc/get_kill_reputation_value(mob/living/victim)
	// Check for rank/level indicators
	var/value = 10 // Base value
	
	// Check name for rank indicators
	var/victim_name = lowertext(victim.name)
	
	if(findtext(victim_name, "recruit") || findtext(victim_name, "initiate") || findtext(victim_name, "scavenger"))
		value = 5
	else if(findtext(victim_name, "soldier") || findtext(victim_name, "warrior") || findtext(victim_name, "raider"))
		value = 10
	else if(findtext(victim_name, "veteran") || findtext(victim_name, "knight") || findtext(victim_name, "decanus"))
		value = 15
	else if(findtext(victim_name, "sergeant") || findtext(victim_name, "centurion") || findtext(victim_name, "paladin"))
		value = 25
	else if(findtext(victim_name, "lieutenant") || findtext(victim_name, "legate") || findtext(victim_name, "elder"))
		value = 50
	else if(findtext(victim_name, "captain") || findtext(victim_name, "general"))
		value = 75
	else if(findtext(victim_name, "commander") || findtext(victim_name, "president"))
		value = 100
	
	// Check if it's a player
	if(victim.client)
		value *= 2 // Killing players is more significant
	
	return value

// Apply rivalry effects - helping one faction may hurt another
/proc/apply_rivalry_effects(ckey, faction_killed, kill_value)
	var/datum/faction/F = get_faction(faction_killed)
	if(!F)
		return
	
	// Apply enemy faction reactions
	for(var/enemy_faction in F.enemy_factions)
		// Enemy of my enemy is my friend (slight boost)
		var/bonus = round(kill_value * 0.3)
		adjust_faction_reputation(ckey, enemy_faction, bonus)
	
	// Apply friendly faction reactions
	for(var/friend_faction in F.friendly_factions)
		// Friend of my enemy is my enemy (slight penalty)
		var/penalty = -round(kill_value * 0.2)
		adjust_faction_reputation(ckey, friend_faction, penalty)

// ============ COMPREHENSIVE ACTION TRIGGERS ============

// Call this to modify reputation by action type
/proc/modify_rep_by_action_extended(ckey, action_type, custom_amount = null)
	if(!ckey)
		return
	
	var/amount = custom_amount
	if(isnull(amount))
		amount = get_action_reputation_amount(action_type)
	
	if(amount == 0)
		return
	
	adjust_faction_reputation(ckey, action_type, amount)

// Get reputation amount for an action type
/proc/get_action_reputation_amount(action_type)
	switch(action_type)
		// ============ NCR ACTIONS ============
		if("ncr")
			return 0 // Placeholder, handled in switch below
		
		// NCR Killing
		if("kill_ncr_recruit")
			return -5
		if("kill_ncr_soldier")
			return -10
		if("kill_ncr_veteran")
			return -15
		if("kill_ncr_sergeant")
			return -20
		if("kill_ncr_officer")
			return -25
		if("kill_ncr_general")
			return -50
		
		// NCR Helping
		if("heal_ncr_soldier")
			return 3
		if("rescue_ncr_captive")
			return 15
		if("defend_ncr_camp")
			return 10
		if("complete_ncr_quest")
			return 15
		if("donate_to_ncr")
			return 5
		if("steal_from_ncr")
			return -15
		if("attack_ncr_civilian")
			return -20
		
		// ============ LEGION ACTIONS ============
		if("kill_legion_recruit")
			return -5
		if("kill_legion_decanus")
			return -10
		if("kill_legion_centurion")
			return -20
		if("kill_legion_legate")
			return -50
		
		// Legion Helping
		if("heal_legion_soldier")
			return 3
		if("complete_legion_quest")
			return 15
		if("donate_slaves_legion")
			return 10
		if("steal_from_legion")
			return -10
		
		// ============ BOS ACTIONS ============
		if("kill_bos_initiate")
			return -10
		if("kill_bos_knight")
			return -15
		if("kill_bos_paladin")
			return -25
		if("kill_bos_elder")
			return -75
		
		// BoS Helping
		if("heal_bos_member")
			return 5
		if("donate_tech_bos")
			return 15
		if("complete_bos_quest")
			return 20
		if("steal_from_bos")
			return -25
		
		// ============ ENCLAVE ACTIONS ============
		if("kill_enclave_soldier")
			return -10
		if("kill_enclave_officer")
			return -25
		if("kill_enclave_commander")
			return -50
		
		// Enclave Helping
		if("complete_enclave_quest")
			return -10 // Working with Enclave hurts other factions
		
		// ============ FOLLOWERS ACTIONS ============
		if("help_followers")
			return 10
		if("donate_meds_followers")
			return 5
		if("complete_followers_quest")
			return 10
		if("attack_followers")
			return -15
		
		// ============ RAIDER ACTIONS ============
		if("kill_raider")
			return 2
		if("kill_raider_boss")
			return 10
		if("join_raiders")
			return 15
		if("leave_raiders")
			return -10
		if("raid_ncr")
			return 10
		if("raid_legion")
			return 10
		
		// ============ GREAT KHANS ACTIONS ============
		if("kill_khan")
			return -10
		if("help_khans")
			return 10
		if("join_khans")
			return 15
		
		// ============ GENERAL ACTIONS ============
		if("rescue_civilian")
			return 5
		if("defend_civilians")
			return 8
		if("heal_civilian")
			return 3
		if("attack_civilian")
			return -15
		if("murder_civilian")
			return -25
		if("steal")
			return -5
		if("break_peace")
			return -10
		if("keep_peace")
			return 5
		
		// ============ QUEST ACTIONS ============
		if("betray_faction")
			return -50
		if("remain_loyal")
			return 20
		if("complete_daily_quest")
			return 5
		if("complete_weekly_quest")
			return 15
		
	return 0

// Get specific NCR reputation change
/proc/get_ncr_reputation_change(action_type)
	switch(action_type)
		if("kill_ncr")
			return -10
		if("heal_ncr")
			return 3
		if("complete_ncr_mission")
			return 15
		if("steal_ncr")
			return -20
		if("help_ncr")
			return 5
		if("attack_ncr")
			return -15
	
	return 0

// Legacy function for compatibility
/proc/modify_rep_by_action(ckey, action_type)
	// Map old action types to new system
	var/faction = null
	var/modifier = 0
	
	switch(action_type)
		if("kill_ncr_soldier")
			faction = "ncr"
			modifier = -15
		if("kill_legion_soldier")
			faction = "legion"
			modifier = -15
		if("kill_bos_knight")
			faction = "bos"
			modifier = -20
		if("complete_ncr_mission")
			faction = "ncr"
			modifier = 10
		if("complete_legion_mission")
			faction = "legion"
			modifier = 10
		if("complete_bos_mission")
			faction = "bos"
			modifier = 15
		if("help_civilian_ncr")
			faction = "ncr"
			modifier = 5
		if("steal_from_ncr")
			faction = "ncr"
			modifier = -20
		if("donate_tech_bos")
			faction = "bos"
			modifier = 15
		if("kill_raider")
			modifier = 2 // Applies to NCR and Legion
		if("kill_enclave")
			modifier = 10 // To NCR, 5 to BoS
		if("help_followers")
			faction = "followers"
			modifier = 10
	
	// Apply primary faction change
	if(faction)
		adjust_faction_reputation(ckey, faction, modifier)
	
	// Apply secondary effects for special actions
	switch(action_type)
		if("kill_ncr_soldier")
			adjust_faction_reputation(ckey, "legion", 5)
		if("kill_legion_soldier")
			adjust_faction_reputation(ckey, "ncr", 5)
		if("steal_from_ncr")
			adjust_faction_reputation(ckey, "legion", 10)
		if("kill_raider")
			adjust_faction_reputation(ckey, "ncr", 2)
			adjust_faction_reputation(ckey, "legion", 2)
		if("kill_enclave")
			adjust_faction_reputation(ckey, "ncr", 10)
			adjust_faction_reputation(ckey, "bos", 5)

	return TRUE
