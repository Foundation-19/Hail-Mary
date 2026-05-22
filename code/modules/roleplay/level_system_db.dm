// player_xp_cache: write-through cache so get_player_xp_db never hits DB twice per event

GLOBAL_LIST_EMPTY(player_xp_cache)

/proc/get_player_level_db(ckey)
	if(!SSdbcore.Connect())
		return 1
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT level FROM [format_table_name("player_levels")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)
	
	if(!query.Execute())
		qdel(query)
		return 1
	
	var/level = 1
	if(query.NextRow())
		level = text2num(query.item[1]) || 1
	
	qdel(query)
	return level

/proc/get_player_xp_db(ckey)
	// Check in-memory cache first
	if(!isnull(GLOB.player_xp_cache[ckey]))
		return GLOB.player_xp_cache[ckey]

	if(!SSdbcore.Connect())
		return 0
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT xp FROM [format_table_name("player_levels")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)
	
	if(!query.Execute())
		qdel(query)
		return 0
	
	var/xp = 0
	if(query.NextRow())
		xp = text2num(query.item[1]) || 0
	
	qdel(query)
	GLOB.player_xp_cache[ckey] = xp
	return xp

/proc/add_xp_db(ckey, amount, source)
	if(!SSdbcore.Connect())
		return FALSE
	
	var/current_xp = get_player_xp_db(ckey)
	var/old_level = calculate_level_from_xp(current_xp) // compute BEFORE the update
	var/new_xp = max(0, current_xp + amount)
	var/new_level = calculate_level_from_xp(new_xp)
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"INSERT INTO [format_table_name("player_levels")] (ckey, xp, level, last_xp_gain) VALUES (:ckey, :xp, :level, NOW()) ON DUPLICATE KEY UPDATE xp = :xp2, level = :level2, last_xp_gain = NOW()",
		list(
			"ckey" = ckey,
			"xp" = new_xp,
			"xp2" = new_xp,
			"level" = new_level,
			"level2" = new_level
		)
	)
	
	var/success = query.Execute()
	qdel(query)
	
	if(success)
		GLOB.player_xp_cache[ckey] = new_xp // keep cache in sync
		if(new_level > old_level)
			handle_level_up(ckey, old_level, new_level)
		
		log_level_system("[ckey] gained [amount] XP from [source || "unknown"] (total: [new_xp], level: [new_level])")
	
	return success

/proc/get_player_level_data_db(ckey)
	if(!SSdbcore.Connect())
		return null
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT xp, level, special_bonuses, bonus_perk_points FROM [format_table_name("player_levels")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)
	
	if(!query.Execute())
		qdel(query)
		return null
	
	var/list/pdata = null
	if(query.NextRow())
		pdata = list(
			"xp" = text2num(query.item[1]) || 0,
			"level" = text2num(query.item[2]) || 1,
			"special_bonuses" = parse_special_bonuses(query.item[3]),
			"bonus_perk_points" = text2num(query.item[4]) || 0
		)
	
	qdel(query)
	return pdata

/proc/parse_special_bonuses(bstring)
	if(!bstring || bstring == "")
		return list("S"=0, "P"=0, "E"=0, "C"=0, "I"=0, "A"=0, "L"=0)
	
	var/list/bonuses = list("S"=0, "P"=0, "E"=0, "C"=0, "I"=0, "A"=0, "L"=0)
	var/list/parts = splittext(bstring, ",")
	for(var/part in parts)
		var/list/kv = splittext(part, ":")
		if(kv.len == 2)
			var/stat = trim(kv[1])
			var/val = text2num(trim(kv[2]))
			bonuses[stat] = val
	
	return bonuses

/proc/special_bonuses_to_string(list/bonuses)
	if(!bonuses)
		return ""
	
	var/result = ""
	for(var/stat in list("S", "P", "E", "C", "I", "A", "L"))
		if(result != "")
			result += ","
		result += "[stat]:[bonuses[stat] || 0]"
	
	return result

/proc/save_special_bonuses_db(ckey, list/bonuses)
	if(!SSdbcore.Connect())
		return FALSE
	
	var/bstring = special_bonuses_to_string(bonuses)
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"UPDATE [format_table_name("player_levels")] SET special_bonuses = :bonuses WHERE ckey = :ckey",
		list("bonuses" = bstring, "ckey" = ckey)
	)
	
	var/success = query.Execute()
	qdel(query)
	return success

/proc/add_bonus_perk_points_db(ckey, amount)
	if(!SSdbcore.Connect())
		return FALSE
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"INSERT INTO [format_table_name("player_levels")] (ckey, bonus_perk_points) VALUES (:ckey, :amount) ON DUPLICATE KEY UPDATE bonus_perk_points = bonus_perk_points + :amount2",
		list("ckey" = ckey, "amount" = amount, "amount2" = amount)
	)
	
	var/success = query.Execute()
	qdel(query)
	return success

/proc/ensure_player_level_entry(ckey)
	if(!SSdbcore.Connect())
		return FALSE
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"INSERT IGNORE INTO [format_table_name("player_levels")] (ckey, level, xp) VALUES (:ckey, 1, 0)",
		list("ckey" = ckey)
	)
	
	var/success = query.Execute()
	qdel(query)
	return success

/proc/create_level_tables()
	if(!SSdbcore.Connect())
		log_level_system("WARNING: Cannot connect to database to create level tables")
		return
	
	var/table_name = format_table_name("player_levels")
	var/create_query = "CREATE TABLE IF NOT EXISTS [table_name] (id INT AUTO_INCREMENT PRIMARY KEY, ckey VARCHAR(32) NOT NULL UNIQUE, xp BIGINT NOT NULL DEFAULT 0, level INT NOT NULL DEFAULT 1, special_bonuses VARCHAR(20) DEFAULT '', bonus_perk_points INT NOT NULL DEFAULT 0, last_xp_gain DATETIME DEFAULT CURRENT_TIMESTAMP, UNIQUE KEY ckey (ckey))"
	var/datum/db_query/query = SSdbcore.NewQuery(create_query)
	query.Execute()
	qdel(query)
	
	log_level_system("Level system database tables created/verified")
