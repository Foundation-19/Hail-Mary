// Tracks and logs all karma changes

GLOBAL_LIST_INIT(karma_history_cache, list())

// Check if history uses DB
/proc/karma_history_use_db()
	return SSdbcore.Connect()

// Log a karma action
/proc/log_karma_action(ckey, action_type, amount, reason = null)
	if(karma_history_use_db())
		return log_karma_action_db(ckey, action_type, amount, reason)
	else
		return log_karma_action_file(ckey, action_type, amount, reason)

// Log to database
/proc/log_karma_action_db(ckey, action_type, amount, reason = null)
	var/current_karma = get_karma(ckey)
	var/new_karma = clamp(current_karma + amount, KARMA_MIN, KARMA_MAX)
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"INSERT INTO [format_table_name("karma_history")] (ckey, action_type, amount, karma_before, karma_after, reason) VALUES (:ckey, :action, :amount, :before, :after, :reason)",
		list(
			"ckey" = ckey,
			"action" = action_type,
			"amount" = amount,
			"before" = current_karma,
			"after" = new_karma,
			"reason" = reason || action_type
		)
	)
	
	var/success = query.Execute()
	qdel(query)
	
	GLOB.karma_history_cache -= ckey
	return success

// Log to SSpersistence
/proc/log_karma_action_file(ckey, action_type, amount, reason = null)
	if(!SSpersistence)
		return FALSE
	
	if(!SSpersistence.karma_history_data[ckey])
		SSpersistence.karma_history_data[ckey] = list()
	
	var/current_karma = get_karma(ckey)
	var/new_karma = clamp(current_karma + amount, KARMA_MIN, KARMA_MAX)
	
	var/list/entry = list(
		"action_type" = action_type,
		"amount" = amount,
		"karma_before" = current_karma,
		"karma_after" = new_karma,
		"reason" = reason || action_type,
		"timestamp" = "[TIME_STAMP("hh:mm:ss", FALSE)]"
	)
	
	SSpersistence.karma_history_data[ckey] += list(entry)
	
	// Keep only last 100 entries per player
	var/list/ckey_history = SSpersistence.karma_history_data[ckey]
	if(ckey_history.len > 100)
		ckey_history.Cut(1, ckey_history.len - 99)
	
	GLOB.karma_history_cache -= ckey
	return TRUE

// Get karma history for a player
/proc/get_karma_history(ckey, limit = 20)
	// Check cache first
	if(GLOB.karma_history_cache[ckey])
		return GLOB.karma_history_cache[ckey]
	
	if(karma_history_use_db())
		return get_karma_history_db(ckey, limit)
	else
		return get_karma_history_file(ckey, limit)

// Get from database
/proc/get_karma_history_db(ckey, limit = 20)
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT action_type, amount, karma_before, karma_after, reason, timestamp FROM [format_table_name("karma_history")] WHERE ckey = :ckey ORDER BY timestamp DESC LIMIT :limit",
		list("ckey" = ckey, "limit" = limit)
	)
	
	var/list/history = list()
	if(query.Execute())
		while(query.NextRow())
			history += list(list(
				"action" = query.item[1],
				"amount" = text2num(query.item[2]),
				"before" = text2num(query.item[3]),
				"after" = text2num(query.item[4]),
				"reason" = query.item[5],
				"time" = query.item[6]
			))
	
	qdel(query)
	GLOB.karma_history_cache[ckey] = history
	return history

// Get from SSpersistence
/proc/get_karma_history_file(ckey, limit = 20)
	var/list/history = list()
	var/list/player_history = SSpersistence?.karma_history_data[ckey]
	
	if(player_history)
		var/count = 0
		for(var/i = player_history.len to 1 step -1)
			if(count >= limit)
				break
			var/list/entry = player_history[i]
			history += list(list(
				"action" = entry["action_type"],
				"amount" = entry["amount"],
				"before" = entry["karma_before"],
				"after" = entry["karma_after"],
				"reason" = entry["reason"],
				"time" = entry["timestamp"]
			))
			count++
	
	GLOB.karma_history_cache[ckey] = history
	return history

// Get karma statistics for a player
/proc/get_karma_stats(ckey)
	if(karma_history_use_db())
		return get_karma_stats_db(ckey)
	else
		return get_karma_stats_file(ckey)

// Get stats from database
/proc/get_karma_stats_db(ckey)
	var/datum/db_query/total_query = SSdbcore.NewQuery(
		"SELECT SUM(amount) as total_change, COUNT(*) as total_actions FROM [format_table_name("karma_history")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)
	
	var/list/stats = list(
		"total_changes" = 0,
		"positive_actions" = 0,
		"negative_actions" = 0,
		"total_positive" = 0,
		"total_negative" = 0,
		"most_common_action" = null,
		"recent_trend" = 0 // Last 10 actions averaged
	)
	
	if(total_query.Execute() && total_query.NextRow())
		stats["total_changes"] = text2num(total_query.item[2])
	
	qdel(total_query)
	
	// Get positive/negative breakdown
	var/datum/db_query/breakdown_query = SSdbcore.NewQuery(
		"SELECT SUM(CASE WHEN amount > 0 THEN 1 ELSE 0 END) as pos_count, SUM(CASE WHEN amount < 0 THEN 1 ELSE 0 END) as neg_count, SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as pos_total, SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END) as neg_total FROM [format_table_name("karma_history")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)
	
	if(breakdown_query.Execute() && breakdown_query.NextRow())
		stats["positive_actions"] = text2num(breakdown_query.item[1]) || 0
		stats["negative_actions"] = text2num(breakdown_query.item[2]) || 0
		stats["total_positive"] = text2num(breakdown_query.item[3]) || 0
		stats["total_negative"] = text2num(breakdown_query.item[4]) || 0
	
	qdel(breakdown_query)
	
	// Get most common action
	var/datum/db_query/common_query = SSdbcore.NewQuery(
		"SELECT action_type, COUNT(*) as cnt FROM [format_table_name("karma_history")] WHERE ckey = :ckey GROUP BY action_type ORDER BY cnt DESC LIMIT 1",
		list("ckey" = ckey)
	)
	
	if(common_query.Execute() && common_query.NextRow())
		stats["most_common_action"] = common_query.item[1]
	
	qdel(common_query)
	
	// Get recent trend (last 10)
	var/datum/db_query/trend_query = SSdbcore.NewQuery(
		"SELECT SUM(amount) FROM (SELECT amount FROM [format_table_name("karma_history")] WHERE ckey = :ckey ORDER BY timestamp DESC LIMIT 10) as recent",
		list("ckey" = ckey)
	)
	
	if(trend_query.Execute() && trend_query.NextRow())
		stats["recent_trend"] = text2num(trend_query.item[1]) || 0
	
	qdel(trend_query)
	
	return stats

// Get stats from file
/proc/get_karma_stats_file(ckey)
	var/list/stats = list(
		"total_changes" = 0,
		"positive_actions" = 0,
		"negative_actions" = 0,
		"total_positive" = 0,
		"total_negative" = 0,
		"most_common_action" = null,
		"recent_trend" = 0
	)
	
	var/list/player_history = SSpersistence?.karma_history_data[ckey]
	if(!player_history)
		return stats
	
	stats["total_changes"] = player_history.len
	
	var/list/action_counts = list()
	var/recent_sum = 0
	var/recent_count = min(10, player_history.len)
	
	for(var/i = 1 to player_history.len)
		var/list/entry = player_history[i]
		var/amount = entry["amount"]
		
		if(amount > 0)
			stats["positive_actions"]++
			stats["total_positive"] += amount
		else if(amount < 0)
			stats["negative_actions"]++
			stats["total_negative"] += amount
		
		action_counts[entry["action_type"]]++
		
		// Recent trend (last 10)
		if(i > player_history.len - 10)
			recent_sum += amount
	
	if(recent_count > 0)
		stats["recent_trend"] = round(recent_sum / recent_count)
	
	// Most common action
	var/max_count = 0
	for(var/action in action_counts)
		if(action_counts[action] > max_count)
			max_count = action_counts[action]
			stats["most_common_action"] = action
	
	return stats

// Player verb to view karma history
/client/verb/view_karma_history()
	set name = "Karma History"
	set category = "Character"
	set desc = "View your karma history and statistics"
	
	var/ckey_to_view = ckey
	
	// If admin, allow viewing others
	if(holder)
		var/mob/target = input(src, "View karma history for:", "Karma History") as null|anything in GLOB.player_list
		if(target && target.ckey)
			ckey_to_view = target.ckey
	
	show_karma_history_ui(usr, ckey_to_view)

/proc/show_karma_history_ui(mob/user, ckey)
	var/datum/browser/popup = new(user, "karma_history", "Karma History", 700, 600)
	
	var/karma = get_karma(ckey)
	var/karma_title = get_karma_title(karma)
	var/karma_desc = get_karma_description(karma)
	var/list/history = get_karma_history(ckey, 25)
	var/list/stats = get_karma_stats(ckey)
	
	var/positive_actions = stats["positive_actions"]
	var/negative_actions = stats["negative_actions"]
	var/total_positive = stats["total_positive"]
	var/total_negative = stats["total_negative"]
	var/recent_trend = stats["recent_trend"]
	
	var/trend_icon = ""
	var/trend_color = "#999999"
	if(recent_trend > 0)
		trend_icon = "▲"
		trend_color = "#33ff33"
	else if(recent_trend < 0)
		trend_icon = "▼"
		trend_color = "#ff3333"
	
	var/html = {"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #d4a574; font-family: "Courier New", monospace; padding: 20px; }
			h1 { color: #ffcc66; border-bottom: 1px solid #664422; padding-bottom: 10px; }
			.karma-display { text-align: center; padding: 20px; background: #2a1a0a; border: 2px solid #664422; margin-bottom: 20px; }
			.karma-value { font-size: 2.5em; font-weight: bold; color: #ffcc66; }
			.karma-title { font-size: 1.5em; color: #66ff66; margin: 10px 0; }
			.karma-desc { color: #996633; font-style: italic; }
			.stats-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-bottom: 20px; }
			.stat-box { padding: 15px; background: #221100; border: 1px solid #443322; }
			.stat-label { color: #996633; font-size: 0.9em; }
			.stat-value { font-size: 1.2em; color: #d4a574; }
			.positive { color: #33ff33; }
			.negative { color: #ff3333; }
			.history-item { padding: 10px; margin: 5px 0; background: #2a1a0a; border-left: 3px solid #664422; }
			.history-item.pos { border-left-color: #33ff33; }
			.history-item.neg { border-left-color: #ff3333; }
			.history-amount { font-weight: bold; }
			.history-amount.pos { color: #33ff33; }
			.history-amount.neg { color: #ff3333; }
			.history-action { color: #d4a574; }
			.history-time { color: #664422; font-size: 0.8em; }
			.trend { font-size: 1.2em; }
		</style>
	</head>
	<body>
		<h1>Karma History</h1>
		
		<div class="karma-display">
			<div class="karma-value">[karma]</div>
			<div class="karma-title">[karma_title]</div>
			<div class="karma-desc">[karma_desc]</div>
		</div>
		
		<div class="stats-grid">
			<div class="stat-box">
				<div class="stat-label">Positive Actions</div>
				<div class="stat-value positive">[positive_actions]</div>
			</div>
			<div class="stat-box">
				<div class="stat-label">Negative Actions</div>
				<div class="stat-value negative">[negative_actions]</div>
			</div>
			<div class="stat-box">
				<div class="stat-label">Total Positive Gain</div>
				<div class="stat-value positive">+[total_positive]</div>
			</div>
			<div class="stat-box">
				<div class="stat-label">Total Negative Loss</div>
				<div class="stat-value negative">[total_negative]</div>
			</div>
			<div class="stat-box" style="grid-column: span 2;">
				<div class="stat-label">Recent Trend (Last 10 Actions)</div>
				<div class="stat-value trend" style="color: [trend_color];">[trend_icon] [recent_trend > 0 ? "+" : ""][recent_trend]</div>
			</div>
		</div>
		
		<h2 style="color: #ffcc66;">Recent Changes</h2>
"}
	
	for(var/i in 1 to min(length(history), 15))
		var/list/entry = history[i]
		var/amount = entry["amount"]
		var/action = entry["action"]
		var/time_str = entry["time"]
		var/reason = entry["reason"]
		
		var/cls = amount >= 0 ? "pos" : "neg"
		var/sign = amount >= 0 ? "+" : ""
		
		html += "<div class='history-item [cls]'>"
		html += "<span class='history-amount [cls]'>[sign][amount]</span>"
		html += " - <span class='history-action'>[action]</span>"
		if(reason && reason != action)
			html += "<br><span class='history-reason' style='color: #996633; font-size: 0.9em;'>[reason]</span>"
		html += " - <span class='history-time'>[time_str]</span>"
		html += "</div>"
	
	if(!history.len)
		html += "<p style='color: #996633;'>No karma changes recorded yet.</p>"
	
	html += "</body></html>"
	
	popup.set_content(html)
	popup.open()

// Clear old history (for maintenance)
/proc/cleanup_karma_history(days_to_keep = 90)
	if(!SSdbcore.Connect())
		return
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"DELETE FROM [format_table_name("karma_history")] WHERE timestamp < DATE_SUB(NOW(), INTERVAL :days DAY)",
		list("days" = days_to_keep)
	)
	
	query.Execute()
	qdel(query)
	
	log_admin("Cleaned up old karma history entries")
	
	return 0
