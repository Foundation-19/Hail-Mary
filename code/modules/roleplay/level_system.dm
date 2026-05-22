// XP-based leveling with SPECIAL bonuses and perk point bonuses
// XP defines are in code/__DEFINES/roleplay_constants.dm

/proc/level_use_db()
	return SSdbcore.Connect()

/proc/get_player_level(ckey)
	if(!ckey)
		return 1
	if(level_use_db())
		return get_player_level_db(ckey)
	else if(SSpersistence && SSpersistence.player_level_data && SSpersistence.player_level_data[ckey])
		return SSpersistence.player_level_data[ckey]["level"] || 1
	return 1

/proc/get_player_xp(ckey)
	if(!ckey)
		return 0
	if(level_use_db())
		return get_player_xp_db(ckey)
	else if(SSpersistence && SSpersistence.player_level_data && SSpersistence.player_level_data[ckey])
		return SSpersistence.player_level_data[ckey]["xp"] || 0
	return 0

/proc/get_xp_required_for_level(level)
	if(!level || level < 1)
		return 0
	return level * XP_LEVEL_SCALING

/proc/get_total_xp_for_level(level)
	if(!level || level < 1)
		return 0
	var/total = 0
	for(var/i = 1 to level)
		total += get_xp_required_for_level(i)
	return total

/proc/add_xp(ckey, amount, source = null)
	if(!ckey)
		return FALSE
	
	var/current_xp = get_player_xp(ckey)
	var/new_xp = current_xp + amount
	
	if(new_xp < 0)
		new_xp = 0
	
	if(level_use_db())
		return add_xp_db(ckey, amount, source)
	else if(SSpersistence)
		return add_xp_file(ckey, amount, source)
	return FALSE

/proc/add_xp_file(ckey, amount, source)
	if(!SSpersistence)
		return FALSE
	
	if(!SSpersistence.player_level_data[ckey])
		SSpersistence.player_level_data[ckey] = list(
			"xp" = 0,
			"level" = 1,
			"special_bonuses" = list("S"=0, "P"=0, "E"=0, "C"=0, "I"=0, "A"=0, "L"=0),
			"bonus_perk_points" = 0,
			"available_special" = 0
		)
	
	var/list/pdata = SSpersistence.player_level_data[ckey]
	var/old_level = pdata["level"]
	
	pdata["xp"] = max(0, pdata["xp"] + amount)
	
	var/new_level = calculate_level_from_xp(pdata["xp"])
	pdata["level"] = new_level
	
	if(new_level > old_level)
		handle_level_up(ckey, old_level, new_level)
	
	log_level_system("[ckey] gained [amount] XP from [source || "unknown"] (total: [pdata["xp"]], level: [new_level])")
	return TRUE

/proc/calculate_level_from_xp(xp)
	var/level = 1
	var/total_xp_needed = 0
	
	while(TRUE)
		total_xp_needed += get_xp_required_for_level(level)
		if(xp < total_xp_needed)
			break
		level++
		if(level >= 100)
			break
	
	return level

/proc/handle_level_up(ckey, old_level, new_level)
	var/mob/p = find_player_by_ckey(ckey)
	
	if(p)
		to_chat(p, span_greentext(" ★ LEVEL UP! You are now level [new_level]! ★ "))
	
	var/bonus_perks = get_bonus_perk_points(new_level) - get_bonus_perk_points(old_level)
	if(bonus_perks > 0)
		add_bonus_perk_points(ckey, bonus_perks)
		if(p)
			to_chat(p, span_notice("+[bonus_perks] bonus perk point(s) available!"))
	
	if(new_level % 5 == 0)
		var/list/pdata = get_player_level_data(ckey)
		if(pdata)
			pdata["available_special"] = pdata["available_special"] + 1
			if(p)
				to_chat(p, span_notice("+1 SPECIAL stat point available! Choose wisely."))
				open_special_allocation_ui(p)

	if(p)
		announce_level_up(p, new_level)

/proc/announce_level_up(mob/p, new_level)
	var/title = get_level_title(new_level)
	if(title)
		to_chat(p, span_greentext("You are now known as [title] [p.real_name]!"))

/proc/get_bonus_perk_points(level)
	if(level >= 20)
		return 15
	if(level >= 15)
		return 10
	if(level >= 10)
		return 5
	if(level >= 5)
		return 2
	return 0

/proc/get_level_title(level)
	if(level >= 30)
		return "Legend"
	if(level >= 20)
		return "Hero"
	if(level >= 15)
		return "Elite"
	if(level >= 10)
		return "Veteran"
	if(level >= 5)
		return "Survivor"
	return "Wastelander"

/proc/get_level_color(level)
	if(level >= 30)
		return "#ff00ff"
	if(level >= 20)
		return "#00ff00"
	if(level >= 15)
		return "#00ccff"
	if(level >= 10)
		return "#ffcc00"
	if(level >= 5)
		return "#cccccc"
	return "#888888"

/proc/get_player_level_data(ckey)
	if(level_use_db())
		return get_player_level_data_db(ckey)
	else if(SSpersistence)
		return SSpersistence.player_level_data[ckey]
	return null

/proc/add_bonus_perk_points(ckey, amount)
	if(level_use_db())
		add_bonus_perk_points_db(ckey, amount)
	else if(SSpersistence)
		if(!SSpersistence.player_level_data[ckey])
			SSpersistence.player_level_data[ckey] = list("xp"=0, "level"=1, "bonus_perk_points"=0)
		SSpersistence.player_level_data[ckey]["bonus_perk_points"] += amount

/proc/get_bonus_perk_points_total(ckey)
	var/list/pdata = get_player_level_data(ckey)
	if(pdata)
		return pdata["bonus_perk_points"] || 0
	return 0

/proc/allocate_special_bonus(ckey, stat, mob/p)
	var/list/pdata = get_player_level_data(ckey)
	if(!pdata)
		return FALSE
	
	var/available = pdata["available_special"] || 0
	if(available <= 0)
		if(p)
			to_chat(p, span_warning("No SPECIAL points available!"))
		return FALSE
	
	var/list/bonuses = pdata["special_bonuses"]
	if(!bonuses)
		bonuses = list("S"=0, "P"=0, "E"=0, "C"=0, "I"=0, "A"=0, "L"=0)
	
	if(bonuses[stat] >= 2)
		if(p)
			to_chat(p, span_warning("You can only increase a stat by +2 from leveling!"))
		return FALSE
	
	bonuses[stat]++
	pdata["special_bonuses"] = bonuses
	pdata["available_special"]--
	
	if(level_use_db())
		save_special_bonuses_db(ckey, bonuses)
	
	if(p)
		to_chat(p, span_notice("+1 [stat]! Your [get_special_name(stat)] is now [get_special_display(p, stat) + bonuses[stat]]"))
	
	return TRUE

/proc/get_special_name(stat)
	switch(stat)
		if("S")
			return "Strength"
		if("P")
			return "Perception"
		if("E")
			return "Endurance"
		if("C")
			return "Charisma"
		if("I")
			return "Intelligence"
		if("A")
			return "Agility"
		if("L")
			return "Luck"
	return stat

/proc/get_special_display(mob/living/carbon/human/p, stat)
	if(!p)
		return 0
	switch(stat)
		if("S")
			return p.special_s
		if("P")
			return p.special_p
		if("E")
			return p.special_e
		if("C")
			return p.special_c
		if("I")
			return p.special_i
		if("A")
			return p.special_a
		if("L")
			return p.special_l
	return 0

/proc/open_special_allocation_ui(mob/p)
	var/ckey = p.ckey
	var/list/pdata = get_player_level_data(ckey)
	if(!pdata)
		return
	
	var/available = pdata["available_special"] || 0
	var/list/bonuses = pdata["special_bonuses"]
	if(!bonuses)
		bonuses = list("S"=0, "P"=0, "E"=0, "C"=0, "I"=0, "A"=0, "L"=0)
	
	var/datum/browser/popup = new(p, "special_alloc", "Allocate SPECIAL", 400, 300)
	
	var/html = {"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #d4a574; font-family: monospace; padding: 20px; }
			h1 { color: #ffcc66; }
			.stat-row { display: flex; justify-content: space-between; padding: 10px; border-bottom: 1px solid #332211; }
			.stat-name { color: #d4a574; }
			.stat-bonus { color: #66ff66; }
			.btn { padding: 8px 16px; background: #332211; color: #d4a574; border: 1px solid #443322; cursor: pointer; }
			.btn:hover { background: #443322; }
			.btn:disabled { opacity: 0.5; cursor: not-allowed; }
			.available { color: #ffcc66; font-size: 1.2em; margin-bottom: 15px; }
		</style>
	</head>
	<body>
		<h1>Allocate SPECIAL</h1>
		<div class='available'>Points Available: [available]</div>
"}
	
	var/list/stats = list("S", "P", "E", "C", "I", "A", "L")
	for(var/stat in stats)
		var/current_val = get_special_display(p, stat)
		var/bonus = bonuses[stat] || 0
		var/disabled = (bonus >= 2 || available <= 0) ? "disabled" : ""
		html += "<div class='stat-row'>"
		html += "<span class='stat-name'>[get_special_name(stat)]: [current_val]</span>"
		html += "<span class='stat-bonus'>[bonus >= 0 ? "+" : ""][bonus]</span>"
		html += "<button class='btn' [disabled] onclick='window.location=\"byond://?src=[REF(p.client)];allocate_special=[stat]\"'>+1</button>"
		html += "</div>"
	
	html += "</body></html>"
	popup.set_content(html)
	popup.open()

/proc/log_level_system(message)
	log_game("[message]")

/proc/get_xp_for_action(action_type)
	switch(action_type)
		if("kill_raider")
			return XP_KILL_RAIDER
		if("kill_feral")
			return XP_KILL_FERAL
		if("kill_veteran")
			return XP_KILL_VETERAN
		if("kill_boss")
			return XP_KILL_BOSS
		if("kill_player")
			return XP_KILL_PLAYER
		if("complete_good_quest")
			return XP_COMPLETE_QUEST_GOOD
		if("complete_evil_quest")
			return XP_COMPLETE_QUEST_EVIL
		if("complete_neutral_quest")
			return XP_COMPLETE_QUEST_NEUTRAL
		if("explore_new")
			return XP_EXPLORE_NEW
		if("craft_item")
			return XP_CRAFT_ITEM
		if("trade")
			return XP_TRADE
		if("help_player")
			return XP_HELP_PLAYER
		if("help_npc")
			return XP_HELP_NPC
		if("discover_location")
			return XP_DISCOVER_LOCATION
		if("survive_day")
			return XP_SURVIVE_DAY
	return 0

/proc/get_xp_for_mob_kill(mob/living/simple_animal/hostile/M)
	if(!M)
		return 0
	if(istype(M, /mob/living/simple_animal/hostile/megafauna))
		return XP_KILL_BOSS
	if(M.maxHealth >= 300)
		return XP_KILL_VETERAN
	if(M.maxHealth >= 100)
		return XP_KILL_FERAL
	return XP_KILL_RAIDER

/mob/living/carbon/human/Topic(href, href_list)
	if(href_list["allocate_special"])
		var/stat = href_list["allocate_special"]
		if(allocate_special_bonus(ckey, stat, src))
			open_special_allocation_ui(src)
			return
	
	. = ..()
