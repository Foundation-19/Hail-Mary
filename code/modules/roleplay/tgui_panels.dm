// TGUI Backend for Roleplay Panels
// All panels use the fallout terminal theme

// ============ RP STATS PANEL ============

/datum/rp_stats_panel
	var/client/owner

/datum/rp_stats_panel/New(client/C)
	owner = C

/datum/rp_stats_panel/Destroy()
	owner = null
	return ..()

/datum/rp_stats_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/rp_stats_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RPStats")
		ui.open()

/datum/rp_stats_panel/ui_data(mob/user)
	. = list()
	
	// Karma
	var/karma_val = get_karma(owner?.ckey)
	.["karma"] = karma_val
	.["karma_title"] = get_karma_title(karma_val)
	.["karma_desc"] = get_karma_description(karma_val)
	
	// Level
	var/level = get_player_level(owner?.ckey)
	.["level"] = level
	.["level_title"] = get_level_title(level)
	.["xp"] = get_player_xp(owner?.ckey)
	var/next_xp = get_total_xp_for_level(level + 1)
	var/curr_xp = get_total_xp_for_level(level)
	.["xp_needed"] = next_xp
	.["xp_percent"] = next_xp > curr_xp ? round(((.["xp"] - curr_xp) / (next_xp - curr_xp)) * 100) : 0
	
	// Bounty
	.["bounty"] = get_bounty(owner?.ckey)
	
	// Bonus perks
	.["bonus_perks"] = get_bonus_perk_points_total(owner?.ckey)
	
	// Available SPECIAL
	var/list/pdata = get_player_level_data(owner?.ckey)
	.["available_special"] = pdata?["available_special"] || 0
	
	// Factions
	.["factions"] = list()
	var/list/faction_info = get_all_faction_info(owner?.ckey)
	for(var/faction_id in faction_info)
		var/list/info = faction_info[faction_id]
		if(!info) continue
		.["factions"] += list(list(
			"name" = info["name"],
			"reputation" = info["reputation"],
			"rank" = info["rank"],
			"reaction" = info["reaction"],
			"access_level" = info["access_level"] || 0,
			"color" = info["color"] || "#4cff4c",
		))
	
	// Background
	var/list/bg_data = get_character_background(owner?.ckey)
	if(bg_data)
		var/datum/background/B = GLOB.character_backgrounds[bg_data["type"]]
		if(B)
			.["background"] = list(
				"name" = B.name,
				"description" = B.description,
				"backstory" = bg_data["backstory"] || "",
			)
	else
		.["background"] = null

/datum/rp_stats_panel/ui_act(action, params)
	. = ..()
	if(.) return
	
	switch(action)
		if("karma_history")
			owner?.view_karma_history()
			return TRUE
		if("view_bounties")
			owner?.check_bounties()
			return TRUE
		if("open_perks")
			owner?.open_perk_menu()
			return TRUE
		if("allocate_special")
			open_special_allocation_ui(owner?.mob)
			return TRUE
	
	return FALSE

// ============ RELATIONSHIPS PANEL ============

/datum/relationships_panel
	var/client/owner

/datum/relationships_panel/New(client/C)
	owner = C

/datum/relationships_panel/Destroy()
	owner = null
	return ..()

/datum/relationships_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/relationships_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Relationships")
		ui.open()

/datum/relationships_panel/ui_data(mob/user)
	. = list()
	
	.["relationships"] = list()
	var/list/rels = get_relationships(owner?.ckey)
	
	for(var/other_ckey in rels)
		var/list/rel = rels[other_ckey]
		.["relationships"] += list(list(
			"ckey" = other_ckey,
			"type" = rel["type"],
			"description" = rel["description"] || "",
			"secret" = rel["secret"] || FALSE,
		))
	
	.["relationship_types"] = GLOB.relationship_types

/datum/relationships_panel/ui_act(action, params)
	. = ..()
	if(.) return
	
	switch(action)
		if("remove")
			var/ckey = params["ckey"]
			if(ckey)
				remove_relationship(owner?.ckey, ckey)
				return TRUE
		if("propose")
			// Close TGUI and use the original input-based flow
			usr << browse(null, "window=Relationships")
			owner?.propose_relationship()
			return TRUE
	
	return FALSE

// ============ BOUNTIES PANEL ============

/datum/bounties_panel
	var/client/owner

/datum/bounties_panel/New(client/C)
	owner = C

/datum/bounties_panel/Destroy()
	owner = null
	return ..()

/datum/bounties_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/bounties_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Bounties")
		ui.open()

/datum/bounties_panel/ui_data(mob/user)
	. = list()
	
	.["your_bounty"] = get_bounty(owner?.ckey)
	
	.["bounties"] = list()
	var/list/all_bounties = get_all_bounties()
	
	for(var/list/b in all_bounties)
		.["bounties"] += list(list(
			"ckey" = b["ckey"],
			"amount" = b["amount"],
			"reason" = b["reason"] || "No reason given",
			"placed_by" = b["placed_by"] || "system",
			"created_at" = b["created_at"] || "Unknown",
		))

// ============ KARMA HISTORY PANEL ============

/datum/karma_history_panel
	var/client/owner

/datum/karma_history_panel/New(client/C)
	owner = C

/datum/karma_history_panel/Destroy()
	owner = null
	return ..()

/datum/karma_history_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/karma_history_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "KarmaHistory")
		ui.open()

/datum/karma_history_panel/ui_data(mob/user)
	. = list()
	
	.["history"] = list()
	var/list/hist = get_karma_history(owner?.ckey, 50)
	
	for(var/list/entry in hist)
		.["history"] += list(list(
			"action" = entry["action"],
			"amount" = entry["amount"],
			"before" = entry["before"],
			"after" = entry["after"],
			"reason" = entry["reason"],
			"time" = entry["time"],
		))

// ============ NOTEBOOK PANEL ============

/datum/notebook_panel
	var/client/owner
	var/datum/notebook/notebook

/datum/notebook_panel/New(client/C)
	owner = C
	notebook = get_player_notebook(C?.ckey)

/datum/notebook_panel/Destroy()
	owner = null
	notebook = null
	return ..()

/datum/notebook_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/notebook_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Notebook")
		ui.open()

/datum/notebook_panel/ui_data(mob/user)
	. = list()
	
	.["max_entries"] = NOTEBOOK_MAX_ENTRIES
	.["entries"] = list()
	
	if(notebook?.entries)
		for(var/id in notebook.entries)
			var/datum/notebook_entry/entry = notebook.entries[id]
			.["entries"] += list(list(
				"id" = entry.id,
				"text" = entry.text,
				"is_public" = entry.is_public,
				"timestamp" = entry.timestamp,
			))

/datum/notebook_panel/ui_act(action, params)
	. = ..()
	if(.) return
	
	switch(action)
		if("add")
			var/text = params["text"]
			var/is_public = text2num(params["public"]) || 0
			if(text && notebook)
				notebook.add_entry(text, is_public)
				return TRUE
		if("delete")
			var/id = text2num(params["id"])
			if(id && notebook)
				notebook.delete_entry(id)
				return TRUE
		if("view_public")
			var/datum/browser/popup = new(usr, "public_notebook", "Public Notes", 600, 500)
			var/html = ""
			if(SSdbcore.Connect())
				var/datum/db_query/query = SSdbcore.NewQuery(
					"SELECT ckey, entry_text, timestamp FROM [format_table_name("notebook_entries")] WHERE is_public = '1' ORDER BY entry_id DESC LIMIT 50"
				)
				if(query.Execute())
					while(query.NextRow())
						html += "<b>[query.item[1]]</b> - [query.item[3]]<br>[query.item[2]]<br><hr>"
				qdel(query)
			popup.set_content(html || "No public notes.")
			popup.open()
			return TRUE
	
	return FALSE

// ============ PERK MENU PANEL ============

/datum/perk_menu_panel
	var/client/owner
	var/current_filter = "all"

/datum/perk_menu_panel/New(client/C)
	owner = C
	if(!length(GLOB.perk_datums))
		initialize_perks()

/datum/perk_menu_panel/Destroy()
	owner = null
	return ..()

/datum/perk_menu_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/perk_menu_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PerkMenu")
		ui.open()

/datum/perk_menu_panel/ui_data(mob/user)
	. = list()
	
	.["points"] = get_perk_points(owner?.ckey)
	.["current_filter"] = current_filter
	.["special_stats"] = list("S", "P", "E", "C", "I", "A", "L")
	
	var/list/active_perks = get_active_perks(owner?.ckey)
	.["active_perks"] = active_perks
	
	.["perks"] = list()
	
	for(var/id in GLOB.perk_datums)
		var/datum/perk/P = GLOB.perk_datums[id]
		if(!P) continue
		
		var/is_active = (id in active_perks)
		var/can_unlock = FALSE
		var/user_stat = 0
		
		if(ishuman(owner?.mob))
			var/mob/living/carbon/human/H = owner.mob
			can_unlock = can_unlock_perk(H, id)
			
			switch(P.special_stat)
				if("S") user_stat = H.special_s
				if("P") user_stat = H.special_p
				if("E") user_stat = H.special_e
				if("C") user_stat = H.special_c
				if("I") user_stat = H.special_i
				if("A") user_stat = H.special_a
				if("L") user_stat = H.special_l
		
		var/has_prereq = TRUE
		var/requires_perk_name = ""
		if(P.requires_perk)
			has_prereq = has_perk(owner?.ckey, P.requires_perk)
			var/datum/perk/req = get_perk_info(P.requires_perk)
			requires_perk_name = req?.name || P.requires_perk
		
		.["perks"] += list(list(
			"id" = id,
			"name" = P.name,
			"desc" = P.desc,
			"special_stat" = P.special_stat,
			"special_min" = P.special_min,
			"user_stat" = user_stat,
			"requires_perk" = P.requires_perk || "",
			"requires_perk_name" = requires_perk_name,
			"has_prereq" = has_prereq,
			"can_unlock" = can_unlock,
			"is_active" = is_active,
		))

/datum/perk_menu_panel/ui_act(action, params)
	. = ..()
	if(.) return
	
	switch(action)
		if("unlock")
			var/perk_id = params["perk"]
			if(perk_id && ishuman(owner?.mob))
				var/mob/living/carbon/human/H = owner.mob
				if(grant_perk(H, perk_id))
					return TRUE
		if("filter")
			current_filter = params["filter"] || "all"
			return TRUE
	
	return FALSE

// ============ QUEST JOURNAL PANEL ============

/datum/quest_journal_panel
	var/client/owner

/datum/quest_journal_panel/New(client/C)
	owner = C

/datum/quest_journal_panel/Destroy()
	owner = null
	return ..()

/datum/quest_journal_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/quest_journal_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "QuestJournal")
		ui.open()

/datum/quest_journal_panel/ui_data(mob/user)
	. = list()
	
	.["player_faction"] = ""
	if(ishuman(owner?.mob))
		var/mob/living/carbon/human/H = owner.mob
		var/datum/job/job = SSjob.GetJob(H.mind?.assigned_role)
		.["player_faction"] = job?.faction || ""
	
	.["active_quests"] = get_player_quests_by_status(owner?.ckey, "active")
	.["completed_quests"] = get_player_quests_by_status(owner?.ckey, "completed")
	.["available_quests"] = list()
	
	for(var/id in GLOB.quests)
		var/list/Q = GLOB.quests[id]
		.["available_quests"] += list(list(
			"id" = id,
			"name" = Q["name"],
			"description" = Q["desc"],
			"faction" = Q["faction"] || "",
			"caps" = Q["caps"] || 0,
			"karma_type" = Q["karma_type"] || "neutral",
		))

/datum/quest_journal_panel/ui_act(action, params)
	. = ..()
	if(.) return
	
	switch(action)
		if("accept")
			var/quest_id = params["quest"]
			if(quest_id && accept_player_quest(owner?.ckey, quest_id))
				return TRUE
		if("abandon")
			var/quest_id = params["quest"]
			if(quest_id && SSdbcore.Connect())
				var/datum/db_query/q = SSdbcore.NewQuery(
					"DELETE FROM [format_table_name("quest_progress")] WHERE ckey = :ckey AND quest_id = :quest_id",
					list("ckey" = owner.ckey, "quest_id" = quest_id)
				)
				q.Execute()
				qdel(q)
				return TRUE
	
	return FALSE

/proc/get_player_quests_by_status(ckey, status)
	if(!ckey || !SSdbcore.Connect())
		return list()
	
	var/datum/db_query/q = SSdbcore.NewQuery(
		"SELECT quest_id, status FROM [format_table_name("quest_progress")] WHERE ckey = :ckey AND status = :status",
		list("ckey" = ckey, "status" = status)
	)
	
	var/list/quests = list()
	if(q.Execute())
		while(q.NextRow())
			var/quest_id = q.item[1]
			var/list/Q = GLOB.quests[quest_id]
			if(Q)
				quests += list(list(
					"id" = quest_id,
					"name" = Q["name"],
					"description" = Q["desc"],
					"status" = q.item[2],
				))
	
	qdel(q)
	return quests

// ============ HELPER PROCS TO OPEN PANELS ============

/client/verb/view_rp_stats_tgui()
	set name = "View RP Stats"
	set category = "Character"
	set desc = "View your roleplay statistics"
	
	var/datum/rp_stats_panel/panel = new(src)
	panel.ui_interact(mob)

/client/verb/view_relationships_tgui()
	set name = "View Relationships"
	set category = "Character"
	set desc = "View your relationships with other players"
	
	var/datum/relationships_panel/panel = new(src)
	panel.ui_interact(mob)

/client/verb/view_bounties_tgui()
	set name = "View Bounties"
	set category = "Character"
	set desc = "View active bounties in the wasteland"
	
	var/datum/bounties_panel/panel = new(src)
	panel.ui_interact(mob)

/client/verb/view_karma_history_tgui()
	set name = "Karma History"
	set category = "Character"
	set desc = "View your karma history and statistics"
	
	var/datum/karma_history_panel/panel = new(src)
	panel.ui_interact(mob)

/client/verb/open_notebook_tgui()
	set name = "Notebook"
	set category = "Character"
	set desc = "Open your character notebook"
	
	var/datum/notebook_panel/panel = new(src)
	panel.ui_interact(mob)

/client/verb/open_perk_menu_tgui()
	set name = "Perk Menu"
	set category = "Character"
	set desc = "View and select perks"
	
	if(!length(GLOB.perk_datums))
		initialize_perks()
	var/datum/perk_menu_panel/panel = new(src)
	panel.ui_interact(mob)

/client/verb/view_quests_tgui()
	set name = "Quest Journal"
	set category = "Character"
	
	var/datum/quest_journal_panel/panel = new(src)
	panel.ui_interact(mob)
