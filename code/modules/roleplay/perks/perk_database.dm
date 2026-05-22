// Handles saving/loading perk data from database

#define PERK_PLAYTIME_INTERVAL 7200 // 2 hours in seconds = 1 perk point
#define PERK_ACTIVE_PLAYTHRESHOLD 60 // Player must have moved in last 60 seconds to earn points
#define PERK_MAX_POINTS 30 // Soft cap - after this, only elite perks available

// Initialize perk system on world start
/world/proc/init_perk_system()
	initialize_perks()
	log_perk_system("Perk system initialized with [length(GLOB.perk_datums)] perks")

// Get available perk points for a player
/proc/get_perk_points(ckey)
	if(!SSdbcore.Connect())
		return get_bonus_perk_points_total(ckey)

	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT points_available FROM [format_table_name("perk_points")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)

	if(!query.Execute())
		qdel(query)
		return get_bonus_perk_points_total(ckey)

	var/points = 0
	if(query.NextRow())
		points = text2num(query.item[1])

	qdel(query)
	points += get_bonus_perk_points_total(ckey)
	return points

// Get total points earned (lifetime)
/proc/get_total_perk_points(ckey)
	if(!SSdbcore.Connect())
		return 0

	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT total_points_earned FROM [format_table_name("perk_points")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)

	if(!query.Execute())
		qdel(query)
		return 0

	var/points = 0
	if(query.NextRow())
		points = text2num(query.item[1])

	qdel(query)
	return points

// Add perk point to player
/proc/add_perk_point(ckey, amount = 1)
	if(!SSdbcore.Connect())
		return FALSE

	var/datum/db_query/query = SSdbcore.NewQuery(
		"INSERT INTO [format_table_name("perk_points")] (ckey, points_available, total_points_earned, playtime_seconds, last_updated) VALUES (:ckey, :points, :total, 0, NOW()) ON DUPLICATE KEY UPDATE points_available = points_available + :points, total_points_earned = total_points_earned + :points, last_updated = NOW()",
		list("ckey" = ckey, "points" = amount, "total" = amount)
	)

	var/success = query.Execute()
	qdel(query)
	return success

// Spend a perk point
/proc/spend_perk_point(ckey)
	if(!SSdbcore.Connect())
		return FALSE

	var/current_points = get_perk_points(ckey)
	if(current_points <= 0)
		return FALSE

	var/datum/db_query/query = SSdbcore.NewQuery(
		"UPDATE [format_table_name("perk_points")] SET points_available = points_available - 1 WHERE ckey = :ckey AND points_available > 0",
		list("ckey" = ckey)
	)

	var/success = query.Execute()
	qdel(query)
	return success

// Get all active perks for a player
/proc/get_active_perks(ckey)
	if(!SSdbcore.Connect())
		return list()

	var/list/perks = list()
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT perk_id FROM [format_table_name("player_perks")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)

	if(!query.Execute())
		qdel(query)
		return perks

	while(query.NextRow())
		perks += query.item[1]

	qdel(query)
	return perks

// Check if player has a specific perk
/proc/has_perk(ckey, perk_id)
	if(!SSdbcore.Connect())
		return FALSE

	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT 1 FROM [format_table_name("player_perks")] WHERE ckey = :ckey AND perk_id = :perk_id",
		list("ckey" = ckey, "perk_id" = perk_id)
	)

	if(!query.Execute())
		qdel(query)
		return FALSE

	var/has = query.NextRow()
	qdel(query)
	return has

// Grant a perk to a player
/proc/grant_perk_db(ckey, perk_id)
	if(!SSdbcore.Connect())
		return FALSE

	if(has_perk(ckey, perk_id))
		return FALSE

	var/datum/db_query/query = SSdbcore.NewQuery(
		"INSERT INTO [format_table_name("player_perks")] (ckey, perk_id, date_earned) VALUES (:ckey, :perk_id, NOW())",
		list("ckey" = ckey, "perk_id" = perk_id)
	)

	var/success = query.Execute()
	qdel(query)
	return success

// Remove a perk from a player
/proc/remove_perk_db(ckey, perk_id)
	if(!SSdbcore.Connect())
		return FALSE

	var/datum/db_query/query = SSdbcore.NewQuery(
		"DELETE FROM [format_table_name("player_perks")] WHERE ckey = :ckey AND perk_id = :perk_id",
		list("ckey" = ckey, "perk_id" = perk_id)
	)

	var/success = query.Execute()
	qdel(query)
	return success

// Update player playtime and check for perk awards
// Only awards points for active playtime (player must have moved recently)
/proc/check_perk_playtime(ckey, playtime_seconds, is_active = FALSE)
	if(!SSdbcore.Connect())
		return

	// Check if player has reached max points - if so, don't calculate further
	var/total_points = get_total_perk_points(ckey)
	if(total_points >= PERK_MAX_POINTS)
		return

	// Only award points if player is active (not AFK)
	if(!is_active)
		return

	// Get current playtime tracked in perk system
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT playtime_seconds FROM [format_table_name("perk_points")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)

	if(!query.Execute())
		qdel(query)
		return

	var/tracked_seconds = 0
	if(query.NextRow())
		tracked_seconds = text2num(query.item[1])

	qdel(query)

	// Calculate new points earned based on playtime
	var/new_playtime = playtime_seconds - tracked_seconds
	if(new_playtime <= 0)
		return

	var/new_points = floor(new_playtime / PERK_PLAYTIME_INTERVAL)
	if(new_points > 0)
		add_perk_point(ckey, new_points)

		// Update tracked playtime
		var/datum/db_query/update_query = SSdbcore.NewQuery(
			"UPDATE [format_table_name("perk_points")] SET playtime_seconds = :playtime WHERE ckey = :ckey",
			list("ckey" = ckey, "playtime" = playtime_seconds)
		)
		update_query.Execute()
		qdel(update_query)

		log_perk_system("[ckey] earned [new_points] perk point(s) from playtime")

// Get perk info from global list
/proc/get_perk_info(perk_id)
	return GLOB.perk_datums[perk_id]

// Log perk system events
/proc/log_perk_system(message)
	log_game("[message]")

// Create database tables (call this once during setup)
/proc/create_perk_tables()
	if(!SSdbcore.Connect())
		log_perk_system("WARNING: Cannot connect to database to create perk tables")
		return

	var/datum/db_query/query = SSdbcore.NewQuery("CREATE TABLE IF NOT EXISTS [format_table_name("perk_points")] (id INT AUTO_INCREMENT PRIMARY KEY, ckey VARCHAR(32) NOT NULL UNIQUE, points_available INT DEFAULT 0, total_points_earned INT DEFAULT 0, playtime_seconds INT DEFAULT 0, last_updated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP)")
	query.Execute()
	qdel(query)

	var/datum/db_query/query2 = SSdbcore.NewQuery("CREATE TABLE IF NOT EXISTS [format_table_name("player_perks")] (id INT AUTO_INCREMENT PRIMARY KEY, ckey VARCHAR(32) NOT NULL, perk_id VARCHAR(64) NOT NULL, date_earned DATETIME DEFAULT CURRENT_TIMESTAMP, UNIQUE KEY unique_perk (ckey, perk_id))")
	query2.Execute()
	qdel(query2)

	log_perk_system("Perk database tables created/verified")
