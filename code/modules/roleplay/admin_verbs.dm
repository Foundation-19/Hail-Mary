// Centralized admin controls for karma, reputation, backgrounds, and relationships

// ============ REPUTATION VERBS ============

/client/proc/view_all_reputations()
	set category = "Admin"
	set name = "View All Reputations"
	set desc = "View all players' faction reputations"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/dat = "<html><head><title>Faction Reputations</title></head><body>"
	dat += "<h1>Faction Reputations</h1>"
	dat += "<table border='1' cellpadding='5'>"
	dat += "<tr><th>Ckey</th><th>Faction</th><th>Reputation</th><th>Rank</th></tr>"
	
	if(!SSdbcore.Connect())
		to_chat(src, span_warning("Database not connected!"))
		return
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT ckey, faction_id, reputation_value, rank_title FROM [format_table_name("faction_reputation")] ORDER BY ckey"
	)
	
	if(query.Execute())
		while(query.NextRow())
			var/ckey = query.item[1]
			var/faction = query.item[2]
			var/rep = query.item[3]
			var/rank = query.item[4]
			
			dat += "<tr><td>[ckey]</td><td>[faction]</td><td>[rep]</td><td>[rank]</td></tr>"
	
	qdel(query)
	
	dat += "</table></body></html>"
	usr << browse(dat, "window=admin_reputations;size=800x600")

/client/proc/view_player_reputation()
	set category = "Admin"
	set name = "View Player Rep"
	set desc = "View a specific player's faction reputations"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/target_ckey = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!target_ckey)
		return
	
	target_ckey = ckey(target_ckey)
	
	if(!SSdbcore.Connect())
		to_chat(src, span_warning("Database not connected!"))
		return
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT faction_id, reputation_value, rank_title, last_updated FROM [format_table_name("faction_reputation")] WHERE ckey = :ckey",
		list("ckey" = target_ckey)
	)
	
	var/dat = "<html><head><title>[target_ckey]'s Reputation</title></head><body>"
	dat += "<h1>Reputation for [target_ckey]</h1>"
	dat += "<table border='1' cellpadding='5'>"
	dat += "<tr><th>Faction</th><th>Reputation</th><th>Rank</th><th>Last Updated</th></tr>"
	
	if(query.Execute())
		while(query.NextRow())
			var/faction = query.item[1]
			var/rep = query.item[2]
			var/rank = query.item[3]
			var/updated = query.item[4]
			
			dat += "<tr><td>[faction]</td><td>[rep]</td><td>[rank]</td><td>[updated]</td></tr>"
	
	qdel(query)
	
	dat += "</table>"
	dat += "<br><a href='?src=[REF(src)];set_rep_target=[target_ckey]'>Adjust This Player's Reputation</a>"
	
	usr << browse(dat, "window=admin_player_rep;size=600x400")

/client/proc/set_faction_rep()
	set category = "Admin"
	set name = "Set Faction Rep"
	set desc = "Set a player's exact reputation with a faction"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/target_ckey = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!target_ckey)
		return
	
	var/faction_choice = input(src, "Choose faction:", "Faction") as null|anything in GLOB.factions
	if(!faction_choice)
		return
	
	var/new_value = input(src, "Enter reputation value (-100 to 250):", "Reputation") as num|null
	if(isnull(new_value))
		return
	
	new_value = clamp(new_value, -100, 250)
	set_faction_reputation(target_ckey, faction_choice, new_value)
	
	log_admin("[key_name(src)] set [target_ckey]'s reputation with [faction_choice] to [new_value]")
	message_admins("[key_name(src)] set [target_ckey]'s reputation with [faction_choice] to [new_value]")
	to_chat(src, span_notice("Set [target_ckey]'s [faction_choice] rep to [new_value]."))

/client/proc/adjust_faction_rep()
	set category = "Admin"
	set name = "Adjust Faction Rep"
	set desc = "Adjust a player's reputation with a faction"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/target_ckey = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!target_ckey)
		return
	
	var/faction_choice = input(src, "Choose faction:", "Faction") as null|anything in GLOB.factions
	if(!faction_choice)
		return
	
	var/amount = input(src, "Enter adjustment amount:", "Amount") as num|null
	if(isnull(amount))
		return
	
	adjust_faction_reputation(target_ckey, faction_choice, amount)
	
	log_admin("[key_name(src)] adjusted [target_ckey]'s reputation with [faction_choice] by [amount]")
	message_admins("[key_name(src)] adjusted [target_ckey]'s reputation with [faction_choice] by [amount]")

// ============ KARMA VERBS ============

/client/proc/view_all_karma()
	set category = "Admin"
	set name = "View All Karma"
	set desc = "View all players' karma"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/dat = "<html><head><title>Player Karma</title></head><body>"
	dat += "<h1>Player Karma</h1>"
	dat += "<table border='1' cellpadding='5'>"
	dat += "<tr><th>Ckey</th><th>Karma</th><th>Title</th></tr>"
	
	if(!SSdbcore.Connect())
		to_chat(src, span_warning("Database not connected!"))
		return
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT ckey, karma_value FROM [format_table_name("player_karma")] ORDER BY karma_value DESC"
	)
	
	if(query.Execute())
		while(query.NextRow())
			var/ckey = query.item[1]
			var/karma = text2num(query.item[2])
			var/title = get_karma_title(karma)
			
			var/karma_color = karma >= KARMA_HERO ? "green" : (karma <= KARMA_VILLAIN ? "red" : "white")
			
			dat += "<tr><td>[ckey]</td><td style='color:[karma_color]'>[karma]</td><td>[title]</td></tr>"
	
	qdel(query)
	
	dat += "</table></body></html>"
	usr << browse(dat, "window=admin_karma;size=600x400")

/client/proc/view_player_karma()
	set category = "Admin"
	set name = "View Player Karma"
	set desc = "View a specific player's karma"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/target_ckey = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!target_ckey)
		return
	
	target_ckey = ckey(target_ckey)
	var/karma = get_karma(target_ckey)
	var/title = get_karma_title(karma)
	
	var/karma_color = karma >= KARMA_HERO ? "green" : (karma <= KARMA_VILLAIN ? "red" : "yellow")
	
	to_chat(src, span_notice("=== [target_ckey]'s Karma ==="))
	to_chat(src, span_notice("Karma: <span style='color:[karma_color]'>[karma]</span> ([title])"))

/client/proc/set_karma_verb()
	set category = "Admin"
	set name = "Set Karma"
	set desc = "Set a player's exact karma value"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/target_ckey = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!target_ckey)
		return
	
	var/new_value = input(src, "Enter karma value ([KARMA_MIN] to [KARMA_MAX]):", "Karma") as num|null
	if(isnull(new_value))
		return
	
	set_karma(target_ckey, new_value)
	
	log_admin("[key_name(src)] set [target_ckey]'s karma to [new_value]")
	message_admins("[key_name(src)] set [target_ckey]'s karma to [new_value]")
	to_chat(src, span_notice("Set [target_ckey]'s karma to [new_value]."))

/client/proc/adjust_karma_verb()
	set category = "Admin"
	set name = "Adjust Karma"
	set desc = "Adjust a player's karma value"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/target_ckey = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!target_ckey)
		return
	
	var/amount = input(src, "Enter adjustment amount:", "Amount") as num|null
	if(isnull(amount))
		return
	
	adjust_karma(target_ckey, amount)
	
	log_admin("[key_name(src)] adjusted [target_ckey]'s karma by [amount]")
	message_admins("[key_name(src)] adjusted [target_ckey]'s karma by [amount]")

// ============ BACKGROUND VERBS ============

/client/proc/view_background()
	set category = "Admin"
	set name = "View Background"
	set desc = "View a player's selected background"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/target_ckey = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!target_ckey)
		return
	
	target_ckey = ckey(target_ckey)
	var/list/bg_data = get_character_background(target_ckey)
	
	if(bg_data)
		to_chat(src, span_notice("=== [target_ckey]'s Background ==="))
		to_chat(src, span_notice("Type: [bg_data["type"]]"))
		to_chat(src, span_notice("Backstory: [bg_data["backstory"] || "None"]"))
	else
		to_chat(src, span_warning("No background found for [target_ckey]"))

/client/proc/set_background_verb()
	set category = "Admin"
	set name = "Set Background"
	set desc = "Set a player's background"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/target_ckey = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!target_ckey)
		return
	
	var/choice = input(src, "Choose background:", "Background") as null|anything in GLOB.character_backgrounds
	if(!choice)
		return
	
	var/backstory = input(src, "Enter backstory (optional):", "Backstory") as text|null
	
	if(set_character_background(target_ckey, choice, backstory))
		to_chat(src, span_notice("Set [target_ckey]'s background to [choice]."))
		log_admin("[key_name(src)] set [target_ckey]'s background to [choice]")
	else
		to_chat(src, span_warning("Failed to set background."))

/client/proc/view_all_backgrounds()
	set category = "Admin"
	set name = "View All Backgrounds"
	set desc = "View all players' backgrounds"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/dat = "<html><head><title>Player Backgrounds</title></head><body>"
	dat += "<h1>Player Backgrounds</h1>"
	dat += "<table border='1' cellpadding='5'>"
	dat += "<tr><th>Ckey</th><th>Background</th><th>Backstory</th></tr>"
	
	if(!SSdbcore.Connect())
		to_chat(src, span_warning("Database not connected!"))
		return
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT ckey, background_type, backstory FROM [format_table_name("character_background")]"
	)
	
	if(query.Execute())
		while(query.NextRow())
			var/ckey = query.item[1]
			var/bg = query.item[2]
			var/bs = query.item[3] || "None"
			
			dat += "<tr><td>[ckey]</td><td>[bg]</td><td>[copytext(bs, 1, 50)]</td></tr>"
	
	qdel(query)
	
	dat += "</table></body></html>"
	usr << browse(dat, "window=admin_backgrounds;size=800x600")

// ============ RELATIONSHIP VERBS ============

/client/proc/view_relationships_verb()
	set category = "Admin"
	set name = "View Relationships"
	set desc = "View a player's relationships"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/target_ckey = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!target_ckey)
		return
	
	target_ckey = ckey(target_ckey)
	var/list/rels = get_relationships(target_ckey)
	
	if(!rels.len)
		to_chat(src, span_notice("[target_ckey] has no relationships."))
		return
	
	to_chat(src, span_notice("=== [target_ckey]'s Relationships ==="))
	
	for(var/other_ckey in rels)
		var/list/rel = rels[other_ckey]
		to_chat(src, span_notice("[other_ckey] - [rel["type"]]: [rel["description"] || "No description"]"))

/client/proc/set_relationship_verb()
	set category = "Admin"
	set name = "Set Relationship"
	set desc = "Create or update a relationship between two players"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/ckey1 = input(src, "Enter first player ckey:", "Player 1") as text|null
	if(!ckey1)
		return
	
	var/ckey2 = input(src, "Enter second player ckey:", "Player 2") as text|null
	if(!ckey2)
		return
	
	var/rel_type = input(src, "Relationship type:", "Type") as null|anything in list("friend", "enemy", "family", "rival", "mentor", "student")
	if(!rel_type)
		return
	
	var/description = input(src, "Description (optional):", "Description") as text|null
	var/secret = alert(src, "Make this relationship secret?", "Secret", "Yes", "No") == "Yes"
	
	if(set_relationship(ckey1, ckey2, rel_type, description, secret))
		to_chat(src, span_notice("Relationship set."))
		log_admin("[key_name(src)] set relationship: [ckey1] - [ckey2] = [rel_type]")
	else
		to_chat(src, span_warning("Failed to set relationship."))

// ============ RESET VERBS ============

/client/proc/reset_roleplay_data()
	set category = "Admin"
	set name = "Reset RP Data"
	set desc = "Reset all roleplay data for a player"
	
	if(!check_rights(R_ADMIN))
		return
	
	var/target_ckey = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!target_ckey)
		return
	
	var/confirm = alert(src, "This will reset ALL karma, reputation, and background for [target_ckey]. Are you sure?", "Confirm Reset", "Yes", "No")
	if(confirm != "Yes")
		return
	
	if(!SSdbcore.Connect())
		to_chat(src, span_warning("Database not connected!"))
		return
	
	// Reset karma
	var/datum/db_query/q1 = SSdbcore.NewQuery("DELETE FROM [format_table_name("player_karma")] WHERE ckey = :ckey", list("ckey" = target_ckey))
	q1.Execute()
	qdel(q1)
	
	// Reset reputation
	var/datum/db_query/q2 = SSdbcore.NewQuery("DELETE FROM [format_table_name("faction_reputation")] WHERE ckey = :ckey", list("ckey" = target_ckey))
	q2.Execute()
	qdel(q2)
	
	// Reset background
	var/datum/db_query/q3 = SSdbcore.NewQuery("DELETE FROM [format_table_name("character_background")] WHERE ckey = :ckey", list("ckey" = target_ckey))
	q3.Execute()
	qdel(q3)
	
	to_chat(src, span_notice("Reset all roleplay data for [target_ckey]."))
	log_admin("[key_name(src)] reset all RP data for [target_ckey]")
	message_admins("[key_name(src)] reset all RP data for [target_ckey]")

// ============ TOGGLE VERBS ============

/client/proc/toggle_karma_system()
	set category = "Admin"
	set name = "Toggle Karma System"
	set desc = "Enable or disable the karma system"
	
	if(!check_rights(R_ADMIN))
		return
	
	// Could add config toggle here
	to_chat(src, span_notice("Karma system is always enabled in this version."))
