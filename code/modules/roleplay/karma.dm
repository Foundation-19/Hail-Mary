// Tracks player moral alignment (Good/Evil)
// Karma constants defined in code/__DEFINES/roleplay_constants.dm

// Forward declarations for procs in other files
// log_karma_action defined in karma_history.dm

// In-memory write-through cache: avoids a DB SELECT on every karma read
GLOBAL_LIST_EMPTY(karma_cache)

// Check if DB is available
/proc/karma_use_db()
	return SSdbcore.Connect()

// Get karma for a player
/proc/get_karma(ckey)
	if(!ckey)
		return 0
	if(karma_use_db())
		return get_karma_db(ckey)
	else if(SSpersistence && SSpersistence.karma_data && SSpersistence.karma_data[ckey])
		return SSpersistence.karma_data[ckey]
	return 0

// Get karma from database
/proc/get_karma_db(ckey)
	// Check in-memory cache first — avoids a DB round trip on every read
	if(!isnull(GLOB.karma_cache[ckey]))
		return GLOB.karma_cache[ckey]

	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT karma_value FROM [format_table_name("player_karma")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)
	
	if(!query.Execute())
		qdel(query)
		return 0
	
	var/karma_value = 0
	if(query.NextRow())
		karma_value = text2num(query.item[1])
	
	qdel(query)
	GLOB.karma_cache[ckey] = karma_value
	return karma_value

// Set karma directly
/proc/set_karma(ckey, value)
	if(!ckey)
		return FALSE
	if(karma_use_db())
		return set_karma_db(ckey, value)
	else if(SSpersistence)
		if(!SSpersistence.karma_data)
			SSpersistence.karma_data = list()
		SSpersistence.karma_data[ckey] = clamp(value, KARMA_MIN, KARMA_MAX)
		return TRUE
	return FALSE

// Set karma in database
/proc/set_karma_db(ckey, value)
	value = clamp(value, KARMA_MIN, KARMA_MAX)
	GLOB.karma_cache[ckey] = value	// keep cache in sync immediately
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"INSERT INTO [format_table_name("player_karma")] (ckey, karma_value, last_updated) VALUES (:ckey, :value, NOW()) ON DUPLICATE KEY UPDATE karma_value = :value, last_updated = NOW()",
		list("ckey" = ckey, "value" = value)
	)
	
	var/success = query.Execute()
	qdel(query)
	return success

// Adjust karma with feedback
/proc/adjust_karma(ckey, amount)
	if(!ckey)
		return 0
	var/current = get_karma(ckey)
	var/new_value = clamp(current + amount, KARMA_MIN, KARMA_MAX)
	set_karma(ckey, new_value)
	
	// Check for bounty triggers
	check_bounty_trigger(ckey)
	
	// Show feedback to player - iterate through player list
	var/mob/M
	for(var/mob/L in GLOB.player_list)
		if(L.ckey == ckey)
			M = L
			break
	
	if(M && abs(amount) >= 5)
		to_chat(M, span_notice("[amount > 0 ? "+" : ""][amount] Karma"))
		
		// Check for threshold crossings
		if(current < KARMA_HERO && new_value >= KARMA_HERO)
			to_chat(M, span_greentext("You are now seen as a HERO in the wasteland!"))
		else if(current > KARMA_VILLAIN && new_value <= KARMA_VILLAIN)
			to_chat(M, span_boldwarning("You are now seen as a VILLAIN in the wasteland!"))
		
		// Check for legendary/infamous
		if(current < KARMA_LEGEND && new_value >= KARMA_LEGEND)
			to_chat(M, span_greentext("You are LEGENDARY! People tell stories of your heroics!"))
		if(current > KARMA_INFAMOUS && new_value <= KARMA_INFAMOUS)
			to_chat(M, span_boldwarning("You are now INFAMOUS! The wasteland fears your name!"))
	
	return new_value

// Mob helper
/mob/proc/get_karma_value()
	return get_karma(ckey)

/mob/proc/adjust_karma_value(amount)
	return adjust_karma(ckey, amount)

// Karma actions - Call these on specific player actions
// Returns the actual karma change applied
/proc/modify_karma_by_action(ckey, action_type, custom_amount = null, reason = null)
	if(!ckey)
		return 0
	
	var/amount = custom_amount
	if(isnull(amount))
		amount = get_action_karma_amount(action_type)
	
	if(amount == 0)
		return 0
	
	var/result = adjust_karma(ckey, amount)
	
	// Log to history
	log_karma_action(ckey, action_type, amount, reason)
	
	// Also award XP for the action
	var/xp_amount = get_xp_for_action(action_type)
	if(xp_amount != 0)
		add_xp(ckey, xp_amount, action_type)
	
	return result

// Get karma amount for an action type
/proc/get_action_karma_amount(action_type)
	switch(action_type)
		// ============ COMBAT ACTIONS ============
		if("save_life")
			return 10
		if("kill_player")
			return -20
		if("kill_civilian")
			return -25
		if("kill_npc_friendly")
			return -15
		if("kill_raider")
			return 5
		if("assist_kill")
			return 3
		if("defend_ally")
			return 8
		if("defend_stranger")
			return 5
		if("surrender")
			return 2
		if("win_duel")
			return 5
		
		// ============ HEALING ACTIONS ============
		if("heal_player")
			return 8
		if("heal_npc")
			return 5
		if("use_stimpak_other")
			return 3
		if("revive_player")
			return 12
		if("revive_npc")
			return 8
		if("give_blood")
			return 6
		
		// ============ SOCIAL ACTIONS ============
		if("help_new_player")
			return 5
		if("help_stranger")
			return 3
		if("share_resources")
			return 5
		if("share_food")
			return 4
		if("trade_honest")
			return 2
		if("greet_respectfully")
			return 1
		if("insult")
			return -2
		if("recruit")
			return 5
		if("teach_skill")
			return 7
		if("intimidate")
			return -3
		if("comfort_grieving")
			return 6
		
		// ============ ITEM ACTIONS ============
		if("donate_charity")
			return 7
		if("donate_caps_poor")
			return 5
		if("donate_supplies")
			return 8
		if("share_item")
			return 3
		if("steal")
			return -10
		if("pickpocket")
			return -12
		if("loot_corpses")
			return -5
		
		// ============ QUEST ACTIONS ============
		if("complete_good_quest")
			return 15
		if("complete_neutral_quest")
			return 5
		if("complete_evil_quest")
			return -15
		if("accept_quest")
			return 2
		if("abandon_quest")
			return -3
		if("fail_quest")
			return -5
		
		// ============ WORLD ACTIONS ============
		if("discover_location")
			return 3
		if("explore_ruin")
			return 2
		if("rescue_hostage")
			return 15
		if("help_prisoner")
			return 10
		if("free_slave")
			return 12
		if("attack_peaceful")
			return -20
		if("destroy_property")
			return -8
		if("damage_environment")
			return -3
		
		// ============ SPEECH ACTIONS ============
		if("tell_truth")
			return 2
		if("lie")
			return -5
		if("deceive")
			return -8
		if("preach")
			return 3
		if("threaten")
			return -4
		if("beg")
			return 2
		
		// ============ SURVIVAL ACTIONS ============
		if("cannibalize")
			return -20
		if("eat_human")
			return -15
		if("drink_blood")
			return -10
		if("share_water")
			return 4
		
		// ============ TRADING ACTIONS ============
		if("price_gouge")
			return -8
		if("fair_trade")
			return 3
		if("scam_merchant")
			return -10
		if("honest_deal")
			return 5
		if("generous_discount")
			return 7
		
		// ============ VEHICLE ACTIONS ============
		if("run_over_npc")
			return -15
		if("rescue_from_vehicle")
			return 10
		if("dangerous_driving")
			return -5
		
		// ============ SPECIAL ACTIONS ============
		if("spare_enemy")
			return 10
		if("show_mercy")
			return 8
		if("torture_prisoner")
			return -30
		if("rape")
			return -50
		if("slave_trade")
			return -40
		if("betray_trust")
			return -15
		if("break_promise")
			return -10
		if("keep_promise")
			return 8
		if("forgive")
			return 5
		if("seek_revenge")
			return -12
		if("show_gratitude")
			return 4
		if("be_grateful")
			return 3
		
	return 0

// Check karma thresholds
/proc/is_karma_good(ckey)
	return get_karma(ckey) >= KARMA_HERO

/proc/is_karma_evil(ckey)
	return get_karma(ckey) <= KARMA_VILLAIN

/proc/is_karma_legend(ckey)
	return get_karma(ckey) >= KARMA_LEGEND

/proc/is_karma_infamous(ckey)
	return get_karma(ckey) <= KARMA_INFAMOUS

// Karma effects on vendors
/proc/get_karma_vendor_discount(ckey)
	var/karma = get_karma(ckey)
	if(karma >= KARMA_LEGEND)
		return 0.25 // 25% discount for legends
	if(karma >= KARMA_HERO)
		return 0.20 // 20% discount for heroes
	if(karma >= KARMA_GOOD)
		return 0.10 // 10% discount for good
	if(karma <= KARMA_INFAMOUS)
		return -0.30 // 30% markup for infamous
	if(karma <= KARMA_VILLAIN)
		return -0.20 // 20% markup for villains
	if(karma <= KARMA_SHADY)
		return -0.10 // 10% markup for shady
	return 0

// Get karma title
/proc/get_karma_title(karma)
	if(karma >= KARMA_LEGEND)
		return "Legendary Hero"
	if(karma >= KARMA_HERO)
		return "Hero"
	if(karma >= KARMA_GOOD)
		return "Good"
	if(karma >= KARMA_NEUTRAL)
		return "Neutral"
	if(karma >= KARMA_SHADY)
		return "Wanderer"
	if(karma >= KARMA_VILLAIN)
		return "Shady"
	if(karma >= KARMA_INFAMOUS)
		return "Villain"
	return "Infamous"

// Get karma description
/proc/get_karma_description(karma)
	if(karma >= KARMA_LEGEND)
		return "Your name is spoken in whispers across the wasteland. People tell stories of your heroics."
	if(karma >= KARMA_HERO)
		return "You are known as a hero. Merchants offer discounts, and people greet you warmly."
	if(karma >= KARMA_GOOD)
		return "You have a good reputation. Most people trust you."
	if(karma >= KARMA_NEUTRAL)
		return "You're just another face in the wasteland."
	if(karma >= KARMA_SHADY)
		return "People are cautious around you. You've done questionable things."
	if(karma >= KARMA_VILLAIN)
		return "You are known as a villain. Bounties may be placed on your head."
	if(karma >= KARMA_INFAMOUS)
		return "The wasteland fears you. Enemies flee at your approach."
	return "Your name is synonymous with terror. No one dares cross you."

// Karma effects on spawns - called when spawning NPCs
/proc/get_karma_spawn_bonus(ckey, spawn_type)
	var/karma = get_karma(ckey)
	
	switch(spawn_type)
		if("ally")
			if(karma >= KARMA_LEGEND)
				return 0.3 // 30% bonus chance for legendary
			if(karma >= KARMA_HERO)
				return 0.2
			if(karma >= KARMA_GOOD)
				return 0.1
			if(karma <= KARMA_VILLAIN)
				return -0.2 // Less likely to get allies
			return 0
			
		if("hostile")
			if(karma <= KARMA_INFAMOUS)
				return 0.3
			if(karma <= KARMA_VILLAIN)
				return 0.2
			if(karma <= KARMA_SHADY)
				return 0.1
			if(karma >= KARMA_HERO)
				return -0.2
			return 0
	
	return 0

// Karma-based dialogue options
/proc/get_karma_dialogue_options(ckey, list/base_options)
	var/karma = get_karma(ckey)
	var/list/options = list()
	
	for(var/item in base_options)
		options += item
	
	if(karma >= KARMA_HERO)
		options += "Offer help"
		options += "Ask about troubles"
	
	if(karma <= KARMA_VILLAIN)
		options += "Demand tribute"
		options += "Threaten"
	
	return options

// Admin verbs
/client/proc/set_karma()
	set category = "Admin"
	set name = "Set Karma"
	set desc = "Set a player's karma value"
	
	var/ckey_input = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!ckey_input)
		return
	
	var/new_value = input(src, "Enter karma value ([KARMA_MIN] to [KARMA_MAX]):", "Karma") as num|null
	if(isnull(new_value))
		return
	
	set_karma(ckey_input, new_value)
	
	log_admin("[key_name(src)] set [ckey_input]'s karma to [new_value]")
	message_admins("[key_name(src)] set [ckey_input]'s karma to [new_value]")

/client/proc/adjust_karma()
	set category = "Admin"
	set name = "Adjust Karma"
	set desc = "Adjust a player's karma value"
	
	var/ckey_input = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!ckey_input)
		return
	
	var/amount = input(src, "Enter adjustment amount:", "Amount") as num|null
	if(isnull(amount))
		return
	
	adjust_karma(ckey_input, amount)
	
	log_admin("[key_name(src)] adjusted [ckey_input]'s karma by [amount]")
	message_admins("[key_name(src)] adjusted [ckey_input]'s karma by [amount]")
