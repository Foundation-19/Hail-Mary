// Player Roleplay Stats Verb
// Allows players to view their karma, reputation, background, and bounties

// Forward declarations - get_bounty is in bounty_system.dm
// get_all_faction_info is in reputation_effects.dm
// view_karma_history is in karma_history.dm
// check_bounties is in bounty_system.dm

/client/verb/view_roleplay_stats()
	set name = "View RP Stats"
	set category = "Character"
	set desc = "View your roleplay statistics"
	
	show_character_status_panel(usr, ckey)

/proc/show_character_status_panel(mob/user, target_ckey)
	if(!user || !target_ckey)
		return
	
	var/datum/browser/popup = new(user, "rp_stats", "Character Status", 700, 700)
	
	var/karma_val = get_karma(target_ckey)
	var/karma_title = get_karma_title(karma_val)
	var/karma_desc = get_karma_description(karma_val)
	var/bounty = get_bounty(target_ckey)
	
	// Karma color
	var/karma_cls = "karma-neutral"
	if(karma_val >= KARMA_HERO)
		karma_cls = "karma-good"
	else if(karma_val <= KARMA_VILLAIN)
		karma_cls = "karma-evil"
	
	// Get all faction info
	var/list/faction_info = get_all_faction_info(target_ckey)
	
	var/html = {"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #d4a574; font-family: "Courier New", monospace; padding: 20px; }
			h1 { color: #ffcc66; border-bottom: 1px solid #664422; padding-bottom: 10px; }
			h2 { color: #ffcc66; margin-top: 20px; border-bottom: 1px solid #443322; }
			h3 { color: #d4a574; margin-top: 15px; }
			.stat-row { padding: 10px 0; border-bottom: 1px solid #332211; }
			.karma-good { color: #33ff33; }
			.karma-neutral { color: #ffff33; }
			.karma-evil { color: #ff3333; }
			.karma-legend { color: #ff00ff; font-weight: bold; }
			.karma-infamous { color: #ff0000; font-weight: bold; }
			.faction-name { color: #d4a574; font-weight: bold; }
			.faction-box { 
				border: 1px solid #443322; 
				padding: 12px; 
				margin: 8px 0;
				background: #221100;
			}
			.faction-rep { color: #ffcc00; }
			.faction-rank { color: #996633; font-style: italic; }
			.faction-access { color: #66ccff; font-size: 0.9em; }
			.bounty-box { 
				border: 2px solid #ff0000; 
				padding: 15px; 
				margin: 10px 0;
				background: #330000;
			}
			.bounty-amount { color: #ff0000; font-size: 1.3em; font-weight: bold; }
			.no-bounty { color: #33ff33; }
			.background-box { 
				border: 1px solid #443322; 
				padding: 15px; 
				margin-top: 10px;
				background: #221100;
			}
			.action-buttons { margin-top: 20px; }
			.action-btn { 
				padding: 10px 15px; 
				background: #332211; 
				color: #d4a574;
				border: 1px solid #443322;
				cursor: pointer;
				margin-right: 10px;
				text-decoration: none;
				display: inline-block;
			}
			.action-btn:hover { background: #443322; }
			.access-level { display: inline-block; padding: 2px 8px; background: #443322; margin-left: 10px; }
		</style>
	</head>
	<body>
		<h1>Character Status</h1>
		
		<h2>Karma</h2>
		<div class='stat-row'>
			<div class='[karma_cls]' style='font-size: 2em;'>[karma_val]</div>
			<div style='font-size: 1.3em;'>[karma_title]</div>
			<div style='color: #996633; margin-top: 5px;'>[karma_desc]</div>
		</div>
		
		<h2>Level</h2>
		<div class='stat-row'>
			[generate_level_display(target_ckey)]
		</div>
		
		<h2>Bounty</h2>"}
	
	// Bounty section
	if(bounty > 0)
		html += "<div class='bounty-box'>"
		html += "<div class='bounty-amount'>[bounty] CAPS</div>"
		html += "<div style='color: #ff6666;'>Bounty hunters may be after you!</div>"
		html += "</div>"
	else
		html += "<div class='no-bounty'>No active bounty on your head.</div>"
	
	// Faction reputations
	html += "<h2>Faction Reputations</h2>"
	
	var/has_factions = FALSE
	for(var/faction_id in faction_info)
		var/list/info = faction_info[faction_id]
		if(!info)
			continue
		
		has_factions = TRUE
		var/faction_name = info["name"]
		var/rep = info["reputation"]
		var/rank = info["rank"]
		var/access = info["access_level"]
		var/reaction = info["reaction"]
		var/color = info["color"]
		
		// Reaction color
		var/reaction_color = "#999999"
		if(reaction == "friendly")
			reaction_color = "#33ff33"
		else if(reaction == "hostile" || reaction == "kill_on_sight")
			reaction_color = "#ff3333"
		
		html += "<div class='faction-box'>"
		html += "<div class='faction-name' style='color: [color];'>[faction_name]</div>"
		html += "<div class='faction-rep'>Reputation: [rep] | Rank: [rank]</div>"
		html += "<div class='faction-access' style='color: [reaction_color];'>Status: [reaction]</div>"
		if(access > 0)
			html += "<div class='faction-access'>Vendor Access Level: [access]</div>"
		html += "</div>"
	
	if(!has_factions)
		html += "<p style='color: #996633;'>No faction reputations yet. Your actions in the wasteland will determine how factions view you.</p>"
	
	// Background section
	html += "<h2>Background</h2>"
	
	var/list/bg_data = get_character_background(target_ckey)
	if(bg_data)
		var/datum/background/B = GLOB.character_backgrounds[bg_data["type"]]
		if(B)
			html += "<div class='background-box'>"
			html += "<div style='font-weight: bold; font-size: 1.2em;'>[B.name]</div>"
			html += "<div style='margin-top: 10px;'>[B.description]</div>"
			if(bg_data["backstory"])
				html += "<div style='margin-top: 15px; color: #996633;'><i>Your backstory:</i></div>"
				html += "<div>[bg_data["backstory"]]</div>"
			html += "</div>"
	else
		html += "<p>No background selected.</p>"
	
	// Perks section
	html += "<h2>Perks</h2>"
	html += "<div class='stat-row'>"
	var/perk_points = get_perk_points(target_ckey)
	html += "<div style='color: #ffcc66;'>Perk Points: [perk_points]</div>"
	var/list/active_perks = get_active_perks(target_ckey)
	if(active_perks.len)
		for(var/perk_id in active_perks)
			var/list/info = get_perk_info(perk_id)
			html += "<div style='color: #d4a574;'>[info["name"]]</div>"
	else
		html += "<div style='color: #996633;'>No perks unlocked yet.</div>"
	html += "</div>"
	
	// Action buttons
	html += "<div class='action-buttons'>"
	html += "<a href='?src=[REF(user.client)];karma_history=1' class='action-btn'>View Karma History</a>"
	html += "<a href='?src=[REF(user.client)];bounties=1' class='action-btn'>View All Bounties</a>"
	html += "<a href='?src=[REF(user.client)];background_choice_ui=1' class='action-btn'>Change Background</a>"
	html += "<a href='?src=[REF(user.client)];open_perks=1' class='action-btn'>Open Perk Menu</a>"
	html += "</div>"
	
	html += "</body></html>"
	
	popup.set_content(html)
	popup.open()

// Handle player stats Topic calls - called from client_procs.dm
/proc/handle_player_stats_topic(client/C, href_list)
	if(href_list["karma_history"])
		C.view_karma_history()
		return TRUE
	
	if(href_list["bounties"])
		C.check_bounties()
		return TRUE
	
	if(href_list["background_choice_ui"])
		C.select_background()
		return TRUE
	
	if(href_list["open_perks"])
		show_perk_menu(C.mob, C.ckey)
		return TRUE
	
	if(href_list["allocate_special_ui"])
		open_special_allocation_ui(C.mob)
		return TRUE
	
	return FALSE

/proc/generate_level_display(ckey)
	var/level = get_player_level(ckey)
	var/xp = get_player_xp(ckey)
	var/next_level_xp = get_total_xp_for_level(level + 1)
	var/current_level_xp = get_total_xp_for_level(level)
	
	var/xp_progress = xp - current_level_xp
	var/xp_needed = next_level_xp - current_level_xp
	var/percent = 0
	if(xp_needed > 0)
		percent = round((xp_progress / xp_needed) * 100)
		percent = clamp(percent, 0, 100)
	
	var/title = get_level_title(level)
	var/color = get_level_color(level)
	var/bonus_perks = get_bonus_perk_points_total(ckey)
	var/list/pdata = get_player_level_data(ckey)
	var/available_special = 0
	if(pdata)
		available_special = pdata["available_special"] || 0
	
	var/html = {"
		<div style='font-size: 2em; color: [color];'>Level [level]</div>
		<div style='font-size: 1.3em; color: [color];'>[title]</div>
		<div style='margin-top: 10px;'>
			<div style='color: #996633;'>XP: [xp] / [next_level_xp] ([percent]%)</div>
			<div style='background: #332211; height: 20px; width: 100%; margin-top: 5px; border: 1px solid #443322;'>
				<div style='background: [color]; height: 100%; width: [percent]%;'></div>
			</div>
		</div>
"}
	
	if(bonus_perks > 0)
		html += "<div style='color: #66ff66; margin-top: 10px;'>+[bonus_perks] bonus perk point(s) available</div>"
	
	if(available_special > 0)
		html += "<div style='color: #66ff66; margin-top: 5px;'>+[available_special] SPECIAL point(s) available</div>"
		html += "<a href='?src=[REF(usr.client)];allocate_special_ui=1' class='action-btn' style='margin-top: 10px;'>Allocate SPECIAL</a>"
	
	return html
