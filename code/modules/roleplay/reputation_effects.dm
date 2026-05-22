// Faction-specific benefits and access levels

// ============ VENDOR ACCESS LEVELS ============

// Get vendor access level for a faction
/proc/get_faction_vendor_access(ckey, faction_id)
	var/rep = get_faction_reputation(ckey, faction_id)
	
	switch(faction_id)
		if("ncr")
			if(rep >= 150)
				return 4 // Premium - military grade
			if(rep >= 100)
				return 3 // Advanced - veteran gear
			if(rep >= 50)
				return 2 // Standard - supplies
			if(rep >= 25)
				return 1 // Basic - food/water
			return 0 // No access
		
		if("legion")
			if(rep >= 100)
				return 4 // Legion elite gear
			if(rep >= 50)
				return 3 // Veteran equipment
			if(rep >= 25)
				return 2 // Standard gear
			if(rep >= 0)
				return 1 // Basic supplies
			return 0 // Hostile
		
		if("bos")
			if(rep >= 175)
				return 4 // Elder access - top tech
			if(rep >= 100)
				return 3 // Paladin access - power armor
			if(rep >= 50)
				return 2 // Knight access - energy weapons
			if(rep >= 25)
				return 1 // Initiate access - basic tech
			return 0 // No access
		
		if("enclave")
			if(rep >= 100)
				return 3 // High clearance
			if(rep >= 50)
				return 2 // Standard access
			if(rep >= 0)
				return 1 // Low clearance
			return -1 // Hostile
		
		if("followers")
			if(rep >= 75)
				return 3 // Master Scholar - rare books
			if(rep >= 30)
				return 2 // Advanced - medical supplies
			if(rep >= 10)
				return 1 // Basic - cheap supplies
			return 0 // No discount
		
		if("raiders")
			if(rep >= 75)
				return 3 // Warlord - best raider gear
			if(rep >= 25)
				return 2 // Raider Boss - weapons
			if(rep >= 0)
				return 1 // Raider - basic supplies
			return 0 // Fresh meat
		
		if("greatkhans")
			if(rep >= 100)
				return 3 // Khan - premium weapons
			if(rep >= 50)
				return 2 // Veteran - good gear
			if(rep >= 0)
				return 1 // Warrior - supplies
			return 0
		
	return 0

// Get vendor discount percentage based on faction rep
/proc/get_faction_vendor_discount(ckey, faction_id)
	var/access_level = get_faction_vendor_access(ckey, faction_id)
	
	switch(access_level)
		if(4)
			return 0.25 // 25% discount
		if(3)
			return 0.20 // 20% discount
		if(2)
			return 0.15 // 15% discount
		if(1)
			return 0.10 // 10% discount
	
	return 0 // No discount

// ============ AREA ACCESS ============

// Check if player can access a faction area
/proc/check_faction_area_access(ckey, area_type)
	switch(area_type)
		if("ncr_base")
			var/rep = get_faction_reputation(ckey, "ncr")
			return rep >= 25
		
		if("ncr_command")
			var/rep = get_faction_reputation(ckey, "ncr")
			return rep >= 75
		
		if("bos_bunker")
			var/rep = get_faction_reputation(ckey, "bos")
			return rep >= 50
		
		if("bos_tech")
			var/rep = get_faction_reputation(ckey, "bos")
			return rep >= 100
		
		if("legion_camp")
			var/rep = get_faction_reputation(ckey, "legion")
			return rep >= 0 // Neutral or better
		
		if("legion_fort")
			var/rep = get_faction_reputation(ckey, "legion")
			return rep >= 50
		
		if("raider_camp")
			var/rep = get_faction_reputation(ckey, "raiders")
			return rep >= 0
		
		if("enclave_base")
			var/rep = get_faction_reputation(ckey, "enclave")
			return rep >= 50 // Very restricted
	
	return FALSE

// ============ DIALOGUE ACCESS ============

// Get available dialogue options based on faction reputation
/proc/get_faction_dialogue_options(ckey, faction_id)
	var/rep = get_faction_reputation(ckey, faction_id)
	var/list/options = list()
	
	switch(faction_id)
		if("ncr")
			if(rep >= 100)
				options += "Military Intelligence"
				options += "Special Operations"
			if(rep >= 50)
				options += "Patrol Routes"
				options += "Supply Requests"
			if(rep >= 25)
				options += "Basic Mission"
				options += "Trade Supplies"
			if(rep >= 0)
				options += "Ask about area"
			if(rep < 0)
				options += "Demand supplies (risky)"
		
		if("legion")
			if(rep >= 75)
				options += "Request Centurion Training"
			if(rep >= 25)
				options += "Offer to fight"
			if(rep >= 0)
				options += "Inquire about Legion"
			if(rep < 0)
				options += "Threaten (suicidal)"
		
		if("bos")
			if(rep >= 100)
				options += "Request Tech Exchange"
				options += "Join Brotherhood"
			if(rep >= 50)
				options += "Request Repairs"
			if(rep >= 25)
				options += "Offer Technology"
			if(rep >= 0)
				options += "Ask about tech"
			if(rep < 0)
				options += "Demand tech (dangerous)"
	
	return options

// ============ FACTION REACTION ============

// Get faction's reaction to a player (for AI behavior)
/proc/get_faction_reaction(ckey, faction_id)
	var/rep = get_faction_reputation(ckey, faction_id)
	
	switch(faction_id)
		if("ncr", "legion", "bos", "enclave")
			if(rep >= 100)
				return "friendly" // Will help, offer quests
			if(rep >= 50)
				return "welcoming" // Will trade, give info
			if(rep >= 25)
				return "neutral" // Will trade
			if(rep >= 0)
				return "cautious" // Will trade but watch closely
			if(rep >= -25)
				return "suspicious" // May refuse service
			if(rep >= -50)
				return "hostile" // Will attack on sight
			return "kill_on_sight" // Will attack immediately
		
		if("raiders")
			if(rep >= 50)
				return "friendly" // Will join raids
			if(rep >= 0)
				return "neutral" // Will trade
			if(rep >= -25)
				return "suspicious" // May rob
			return "hostile"
		
		if("followers")
			if(rep >= 30)
				return "friendly" // Will heal, share knowledge
			if(rep >= 0)
				return "neutral" // Will trade
			return "cautious"
	
	return "neutral"

// Check if faction member should attack player
/proc/should_faction_attack(ckey, faction_id)
	var/reaction = get_faction_reaction(ckey, faction_id)
	return (reaction == "hostile" || reaction == "kill_on_sight")

// ============ FACTION-SPECIFIC ABILITIES ============

// Get abilities unlocked by faction reputation
/proc/get_faction_abilities(ckey, faction_id)
	var/rep = get_faction_reputation(ckey, faction_id)
	var/list/abilities = list()
	
	switch(faction_id)
		if("ncr")
			if(rep >= 150)
				abilities += "ncr_military_transport"
				abilities += "ncr_advanced_equipment"
			if(rep >= 100)
				abilities += "ncr_vehicle_access"
				abilities += "ncr_fast_travel"
			if(rep >= 50)
				abilities += "ncr_advanced_gear"
			if(rep >= 25)
				abilities += "ncr_basic_supplies"
		
		if("bos")
			if(rep >= 175)
				abilities += "bos_power_armor_training"
				abilities += "bos_top_secret_tech"
			if(rep >= 100)
				abilities += "bos_power_armor_access"
				abilities += "bos_advanced_tech"
			if(rep >= 50)
				abilities += "bos_energy_weapons"
				abilities += "bos_repair_services"
			if(rep >= 25)
				abilities += "bos_basic_tech"
		
		if("legion")
			if(rep >= 150)
				abilities += "legion_elite_training"
				abilities += "legion_command"
			if(rep >= 75)
				abilities += "legion_veteran_gear"
			if(rep >= 25)
				abilities += "legion_standard_gear"
		
		if("raiders")
			if(rep >= 100)
				abilities += "raider_territory_control"
				abilities += "raider_tribute_collection"
			if(rep >= 50)
				abilities += "raider_best_weapons"
			if(rep >= 25)
				abilities += "raider_equipment"
	
	return abilities

// ============ FACTION COLOR FOR UI ============

// Get color for faction in UI
/proc/get_faction_ui_color(faction_id)
	switch(faction_id)
		if("ncr")
			return "#3355FF" // NCR Blue
		if("legion")
			return "#FF3333" // Legion Red
		if("bos")
			return "#FFD700" // BoS Gold
		if("enclave")
			return "#00FF00" // Enclave Green
		if("raiders")
			return "#FF6600" // Raider Orange
		if("greatkhans")
			return "#9900FF" // Khan Purple
		if("followers")
			return "#00FFFF" // Followers Cyan
		if("vipers")
			return "#33FF33" // Viper Green
		if("jackals")
			return "#FFFF00" // Jackal Yellow
	
	return "#FFFFFF" // Default white

// ============ FACTION INFORMATION ============

// Get detailed faction info for UI
/proc/get_faction_info(ckey, faction_id)
	var/datum/faction/F = get_faction(faction_id)
	if(!F)
		return null
	
	var/rep = get_faction_reputation(ckey, faction_id)
	var/rank = get_faction_rank(faction_id, rep)
	var/access_level = get_faction_vendor_access(ckey, faction_id)
	var/reaction = get_faction_reaction(ckey, faction_id)
	var/abilities = get_faction_abilities(ckey, faction_id)
	
	return list(
		"faction" = F,
		"id" = faction_id,
		"name" = F.name,
		"description" = F.description,
		"reputation" = rep,
		"rank" = rank,
		"access_level" = access_level,
		"reaction" = reaction,
		"abilities" = abilities,
		"color" = get_faction_ui_color(faction_id)
	)

// Get all faction info for a player
/proc/get_all_faction_info(ckey)
	var/list/all_info = list()
	for(var/faction_id in GLOB.factions)
		all_info[faction_id] = get_faction_info(ckey, faction_id)
	return all_info
