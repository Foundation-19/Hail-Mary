// Simple but functional quest tracking with failure/expiration support

/datum/quest
	var/id = ""
	var/name = ""
	var/description = ""
	var/objective = ""
	var/completed = FALSE

GLOBAL_LIST_INIT(quests, list(
	"ncr_raiders" = list("name" = "Clear Raiders", "desc" = "Eliminate raider threat", "faction" = "ncr", "rep" = 15, "caps" = 50, "karma_type" = "good"),
	"ncr_scout" = list("name" = "Scout Mission", "desc" = "Survey territory", "faction" = "ncr", "rep" = 20, "caps" = 75, "karma_type" = "neutral"),
	"ncr_civilian" = list("name" = "Protect Settlement", "desc" = "Defend NCR settlers from attack", "faction" = "ncr", "rep" = 25, "caps" = 100, "karma_type" = "good"),
	"ncr_supplies" = list("name" = "Supply Run", "desc" = "Deliver supplies to NCR outpost", "faction" = "ncr", "rep" = 15, "caps" = 75, "karma_type" = "good"),
	"legion_tribal" = list("name" = "Tribal Integration", "desc" = "Bring tribals to Legion", "faction" = "legion", "rep" = 20, "karma_type" = "evil"),
	"legion_slave" = list("name" = "Capture Slaves", "desc" = "Deliver captives to Legion", "faction" = "legion", "rep" = 30, "caps" = 100, "karma_type" = "evil"),
	"legion_kill_ncr" = list("name" = "Strike at NCR", "desc" = "Attack NCR patrol", "faction" = "legion", "rep" = 25, "caps" = 150, "karma_type" = "evil"),
	"bos_tech" = list("name" = "Recover Tech", "desc" = "Find pre-war technology", "faction" = "bos", "rep" = 25, "karma_type" = "neutral"),
	"bos_scavenge" = list("name" = "Scavenge Bunker", "desc" = "Search abandoned bunker for tech", "faction" = "bos", "rep" = 30, "caps" = 125, "karma_type" = "neutral"),
	"kill_ghouls" = list("name" = "Feral Problem", "desc" = "Clear ferals", "faction" = null, "caps" = 60, "karma" = 5, "karma_type" = "good"),
	"caravan" = list("name" = "Caravan Guard", "desc" = "Protect the caravan", "faction" = null, "caps" = 100, "karma_type" = "good"),
	"help_nomads" = list("name" = "Help Nomads", "desc" = "Share food and water with travelers", "faction" = null, "caps" = 40, "karma_type" = "good"),
	"burial_rite" = list("name" = "Burial Rite", "desc" = "Give proper burial to the dead", "faction" = null, "caps" = 25, "karma_type" = "good"),
	"enclave_data" = list("name" = "Enclave Intel", "desc" = "Steal data for mysterious client", "faction" = null, "caps" = 200, "karma_type" = "evil"),
	"rob_caravan" = list("name" = "Highwayman", "desc" = "Take what you want from travelers", "faction" = null, "caps" = 150, "karma_type" = "evil")
))

/proc/get_quest_data(quest_id)
	return GLOB.quests[quest_id]

/proc/get_faction_quests(faction)
	var/list/result = list()
	for(var/id in GLOB.quests)
		var/list/Q = GLOB.quests[id]
		if(Q["faction"] == faction)
			result[id] = Q
	return result

/proc/accept_player_quest(ckey, quest_id)
	if(!GLOB.quests[quest_id])
		return FALSE
	
	// Add small karma for accepting quest
	modify_karma_by_action(ckey, "accept_quest", null, "Accepted quest: [quest_id]")
	
	if(SSdbcore.Connect())
		var/datum/db_query/q = SSdbcore.NewQuery(
			"INSERT INTO [format_table_name("quest_progress")] (ckey, quest_id, status) VALUES (:ckey, :quest_id, 'active')",
			list("ckey" = ckey, "quest_id" = quest_id)
		)
		q.Execute()
		qdel(q)
	return TRUE

/proc/complete_player_quest(ckey, quest_id)
	var/list/Q = GLOB.quests[quest_id]
	if(!Q)
		return FALSE
	
	// Apply faction reputation
	if(Q["faction"] && Q["rep"])
		var/faction_id = Q["faction"]
		adjust_faction_reputation(ckey, faction_id, Q["rep"])
		
		// Trigger reputation action based on faction
		var/rep_action = "complete_[faction_id]_quest"
		modify_rep_by_action_extended(ckey, rep_action)
	
	// Apply karma based on quest type (good/neutral/evil)
	if(Q["karma_type"])
		var/action_type = "complete_[Q["karma_type"]]_quest"
		modify_karma_by_action(ckey, action_type, null, "Completed quest: [Q["name"]]")
	// Fallback for old-style karma field
	else if(Q["karma"])
		adjust_karma(ckey, Q["karma"])
	
	// Give caps reward
	if(Q["caps"])
		var/mob/p = find_player_by_ckey(ckey)
		if(p && ishuman(p))
			var/obj/item/stack/f13Cash/caps/c = new(get_turf(p))
			c.amount = Q["caps"]
			p.put_in_hands(c)
	
	// Update database
	if(SSdbcore.Connect())
		var/datum/db_query/q = SSdbcore.NewQuery(
			"UPDATE [format_table_name("quest_progress")] SET status = 'completed' WHERE ckey = :ckey AND quest_id = :quest_id",
			list("ckey" = ckey, "quest_id" = quest_id)
		)
		q.Execute()
		qdel(q)
	return TRUE

/client/verb/view_quests()
	set name = "Quest Journal"
	set category = "Character"
	show_quests_ui(usr)

/proc/show_quests_ui(mob/user)
	var/datum/browser/popup = new(user, "quests", "Quest Journal", 600, 500)
	
	var/ckey = user.ckey
	var/list/active = list()
	
	if(SSdbcore.Connect())
		var/datum/db_query/q = SSdbcore.NewQuery(
			"SELECT quest_id FROM [format_table_name("quest_progress")] WHERE ckey = :ckey AND status = 'active'",
			list("ckey" = ckey)
		)
		if(q.Execute())
			while(q.NextRow())
				active += q.item[1]
		qdel(q)
	
	var/faction_titles = list("ncr" = "NCR", "legion" = "Legion", "bos" = "Brotherhood", "neutral" = "Wasteland")
	var/faction_colors = list("ncr" = "#3355FF", "legion" = "#FF3333", "bos" = "#FFD700", "neutral" = "#AAAAAA")
	
	var/html = {"
	<!DOCTYPE html>
	<html><head><style>
		body { background: #1a1a1a; color: #d4a574; font-family: monospace; padding: 20px; }
		h1 { color: #ffcc66; border-bottom: 1px solid #664422; }
		h2 { color: #d4a574; margin-top: 20px; }
		.quest { border: 1px solid #664422; padding: 15px; margin: 10px 0; background: #2a1a0a; }
		.name { font-weight: bold; color: #ffcc66; }
		.desc { color: #996633; }
		.reward { color: #66ff66; font-size: 0.9em; }
	</style></head><body>
		<h1>Quest Journal</h1>
	"}
	
	html += "<h2>Active Quests</h2>"
	if(active.len)
		for(var/qid in active)
			var/list/Q = GLOB.quests[qid]
			if(Q)
				html += "<div class='quest'><div class='name'>[Q["name"]]</div>"
				html += "<div class='desc'>[Q["desc"]]</div></div>"
	else
		html += "<p>No active quests. Accept missions from faction leaders.</p>"
	
	var/factions = list("ncr", "legion", "bos", "neutral")
	for(var/f in factions)
		var/list/fquests = get_faction_quests(f)
		if(fquests.len)
			html += "<h2 style='color: [faction_colors[f]]'>[faction_titles[f]] Missions</h2>"
			for(var/qid in fquests)
				if(qid in active) continue
				var/list/Q = fquests[qid]
				html += "<div class='quest'>"
				html += "<div class='name'>[Q["name"]]</div>"
				html += "<div class='desc'>[Q["desc"]]</div>"
				var/rew = ""
				if(Q["rep"]) rew += "+[Q["rep"]] [f] rep "
				if(Q["caps"]) rew += "[Q["caps"]] caps "
				if(Q["karma"]) rew += "Karma [Q["karma"]] "
				if(Q["karma_type"]) 
					var/karma_amt = 0
					if(Q["karma_type"] == "good") karma_amt = 15
					else if(Q["karma_type"] == "neutral") karma_amt = 5
					else if(Q["karma_type"] == "evil") karma_amt = -15
					rew += "[karma_amt > 0 ? "+" : ""][karma_amt] Karma ([Q["karma_type"]])"
				html += "<div class='reward'>Reward: [rew]</div>"
				html += "</div>"
	
	html += "</body></html>"
	popup.set_content(html)
	popup.open()

/mob/living/carbon/human/Topic(href, href_list)
	if(href_list["acceptq"])
		var/qid = href_list["acceptq"]
		if(accept_player_quest(ckey, qid))
			to_chat(src, span_notice("Quest accepted!"))
		show_quests_ui(src)
	. = ..()

// ============ QUEST FAILURE/EXPIRATION SYSTEM ============

/proc/fail_player_quest(ckey, quest_id, reason = "Quest failed")
	var/list/Q = GLOB.quests[quest_id]
	if(!Q)
		return FALSE
	
	var/mob/player = find_player_by_ckey(ckey)
	if(player)
		to_chat(player, span_warning("[reason]: [Q["name"]]"))
	
	if(Q["karma_type"])
		var/action_type = "fail_[Q["karma_type"]]_quest"
		modify_karma_by_action(ckey, action_type, null, "Failed quest: [Q["name"]]")
	
	if(SSdbcore.Connect())
		var/datum/db_query/q = SSdbcore.NewQuery(
			"UPDATE [format_table_name("quest_progress")] SET status = 'failed', failed_at = NOW() WHERE ckey = :ckey AND quest_id = :quest_id",
			list("ckey" = ckey, "quest_id" = quest_id)
		)
		q.Execute()
		qdel(q)
	return TRUE

/proc/setup_quest_database()
	if(!SSdbcore.Connect())
		return FALSE
	
	var/datum/db_query/query = SSdbcore.NewQuery({"
		CREATE TABLE IF NOT EXISTS [format_table_name("quest_progress")] (
			id INT AUTO_INCREMENT PRIMARY KEY,
			ckey VARCHAR(32) NOT NULL,
			quest_id VARCHAR(64) NOT NULL,
			status ENUM('active', 'completed', 'failed', 'expired') DEFAULT 'active',
			accepted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			completed_at DATETIME,
			failed_at DATETIME,
			expires_at DATETIME,
			UNIQUE KEY unique_quest (ckey, quest_id)
		)"}
	)
	
	var/success = query.Execute()
	qdel(query)
	return success

/proc/accept_player_quest_with_expiry(ckey, quest_id, time_limit = 0)
	if(!GLOB.quests[quest_id])
		return FALSE
	
	if(!time_limit)
		time_limit = QUEST_DEFAULT_TIME_LIMIT
	
	modify_karma_by_action(ckey, "accept_quest", null, "Accepted quest: [quest_id]")
	
	if(SSdbcore.Connect())
		var/expires_sql = time_limit > 0 ? "DATE_ADD(NOW(), INTERVAL :time_limit SECOND)" : "NULL"
		var/datum/db_query/q = SSdbcore.NewQuery(
			"INSERT INTO [format_table_name("quest_progress")] (ckey, quest_id, status, expires_at) VALUES (:ckey, :quest_id, 'active', [expires_sql])",
			list("ckey" = ckey, "quest_id" = quest_id, "time_limit" = time_limit)
		)
		q.Execute()
		qdel(q)
	return TRUE

/proc/check_expired_quests()
	if(!SSdbcore.Connect())
		return
	
	var/datum/db_query/q = SSdbcore.NewQuery(
		"SELECT ckey, quest_id FROM [format_table_name("quest_progress")] WHERE status = 'active' AND expires_at IS NOT NULL AND expires_at < NOW()"
	)
	
	if(q.Execute())
		while(q.NextRow())
			var/ckey = q.item[1]
			var/quest_id = q.item[2]
			expire_player_quest(ckey, quest_id)
	qdel(q)

/proc/expire_player_quest(ckey, quest_id)
	var/list/Q = GLOB.quests[quest_id]
	if(!Q)
		return FALSE
	
	var/mob/player = find_player_by_ckey(ckey)
	if(player)
		to_chat(player, span_warning("Quest expired: [Q["name"]]. Time has run out!"))
	
	if(SSdbcore.Connect())
		var/datum/db_query/q = SSdbcore.NewQuery(
			"UPDATE [format_table_name("quest_progress")] SET status = 'expired', failed_at = NOW() WHERE ckey = :ckey AND quest_id = :quest_id",
			list("ckey" = ckey, "quest_id" = quest_id)
		)
		q.Execute()
		qdel(q)
	return TRUE

/proc/get_player_quest_time_remaining(ckey, quest_id)
	if(!SSdbcore.Connect())
		return -1
	
	var/datum/db_query/q = SSdbcore.NewQuery(
		"SELECT TIMESTAMPDIFF(SECOND, NOW(), expires_at) FROM [format_table_name("quest_progress")] WHERE ckey = :ckey AND quest_id = :quest_id AND status = 'active'",
		list("ckey" = ckey, "quest_id" = quest_id)
	)
	
	var/time_remaining = -1
	if(q.Execute() && q.NextRow())
		time_remaining = text2num(q.item[1])
	qdel(q)
	return time_remaining

/proc/format_time_remaining(seconds)
	if(seconds < 0)
		return "No time limit"
	if(seconds == 0)
		return "Expired"
	
	var/days = floor(seconds / 86400)
	seconds -= days * 86400
	var/hours = floor(seconds / 3600)
	seconds -= hours * 3600
	var/minutes = floor(seconds / 60)
	
	if(days > 0)
		return "[days]d [hours]h remaining"
	if(hours > 0)
		return "[hours]h [minutes]m remaining"
	return "[minutes]m remaining"

/proc/process_quest_expiry()
	check_expired_quests()
	addtimer(CALLBACK(GLOBAL_PROC, /proc/process_quest_expiry), 3000)

/world/proc/init_quest_system()
	setup_quest_database()
	process_quest_expiry()
