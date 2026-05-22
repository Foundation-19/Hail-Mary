// DYNAMIC QUEST GENERATION - NPCs offer procedurally generated quests
// Quests encourage players to team up and explore together

#define QUEST_DELIVERY "Delivery"
#define QUEST_BOUNTY "Bounty"
#define QUEST_SCAVENGE "Scavenge"
#define QUEST_ESCORT "Escort"
#define QUEST_CLEAR "Clear Out"
#define QUEST_RETRIEVE "Retrieve Item"

GLOBAL_LIST_INIT(player_active_quests, list())

/datum/dynamic_quest
	var/quest_type = ""
	var/title = ""
	var/description = ""
	var/reward = 0
	var/target_name = ""
	var/area_name = ""
	var/area_ref = ""
	var/item_type
	var/time_limit = 0
	var/post_time = 0
	var/completed = FALSE
	var/expired = FALSE
	var/claimed_by = ""
	var/quest_giver_name = ""
	var/visited_target_area = FALSE
	var/minimum_time_at_target = 300
	var/time_at_target = 0

/datum/dynamic_quest/proc/is_active()
	return !completed && !expired && (world.time - post_time) < time_limit

/datum/dynamic_quest/proc/check_expiry()
	if(completed || expired)
		return
	if((world.time - post_time) >= time_limit)
		expired = TRUE

/datum/dynamic_quest/proc/check_progress(mob/living/carbon/human/H)
	if(!H || completed || expired)
		return
	var/area/player_area = get_area(H)
	if(player_area && player_area.name == area_name)
		if(!visited_target_area)
			visited_target_area = TRUE
			to_chat(H, span_notice("<b>QUEST UPDATE:</b> You've arrived at [area_name]! Stay a while to complete your task..."))
		time_at_target += 10
	else if(visited_target_area)
		time_at_target += 5

/datum/dynamic_quest/proc/can_complete(mob/living/carbon/human/H)
	if(!H || completed || expired)
		return FALSE
	switch(quest_type)
		if(QUEST_BOUNTY)
			if(!visited_target_area)
				return FALSE
			var/recent_kill = H.recent_hostile_kill_time && (world.time - H.recent_hostile_kill_time) < 600
			return recent_kill
		if(QUEST_DELIVERY, QUEST_SCAVENGE, QUEST_RETRIEVE)
			return visited_target_area && time_at_target >= minimum_time_at_target
	return TRUE

/datum/dynamic_quest/proc/get_status_text()
	switch(quest_type)
		if(QUEST_BOUNTY)
			if(!visited_target_area)
				return "<span style='color:#ff8844'>Travel to [area_name]</span>"
			return "<span style='color:#88ff88'>At target area - kill your mark!</span>"
		if(QUEST_DELIVERY, QUEST_SCAVENGE, QUEST_RETRIEVE)
			if(!visited_target_area)
				return "<span style='color:#ff8844'>Travel to [area_name]</span>"
			if(time_at_target < minimum_time_at_target)
				return "<span style='color:#ffcc44'>Searching... [round(time_at_target / minimum_time_at_target * 100)]%</span>"
			return "<span style='color:#88ff88'>Ready to turn in!</span>"
	return "<span style='color:#88ff88'>Ready to turn in!</span>"

/proc/generate_dynamic_quest(atom/npc)
	var/datum/dynamic_quest/Q = new()
	var/quest_types = list(QUEST_DELIVERY, QUEST_BOUNTY, QUEST_SCAVENGE, QUEST_RETRIEVE)
	Q.quest_type = pick(quest_types)
	Q.quest_giver_name = npc ? npc.name : "Unknown"
	Q.post_time = world.time
	Q.time_limit = QUEST_DEFAULT_TIME_LIMIT

	var/list/valid_areas = list()
	for(var/area/A in get_areas(/area))
		if(!A || findtext(A.name, "space") || findtext(A.name, "centcomm") || findtext(A.name, "admin") || findtext(A.name, "shuttle"))
			continue
		valid_areas += A
	var/area/target_area = valid_areas.len ? pick(valid_areas) : null
	Q.area_name = target_area ? target_area.name : "the wasteland"
	Q.area_ref = target_area ? REF(target_area) : ""

	switch(Q.quest_type)
		if(QUEST_DELIVERY)
			var/items = list("medical supplies", "ammo crate", "water flask", "spare parts", "a sealed letter", "food rations")
			Q.target_name = pick(items)
			Q.title = "Deliver [Q.target_name]"
			Q.description = "I need someone to deliver [Q.target_name] to [Q.area_name]. Should be safe. Probably."
			Q.reward = rand(20, 60)
			Q.minimum_time_at_target = 300
		if(QUEST_BOUNTY)
			var/targets = list("a feral ghoul", "a raider scout", "an escaped convict", "a thief", "a deserting soldier")
			Q.target_name = pick(targets)
			Q.title = "Bounty: [capitalize(Q.target_name)]"
			Q.description = "There's a bounty on [Q.target_name] last seen near [Q.area_name]. Bring proof of the kill."
			Q.reward = rand(40, 120)
			Q.minimum_time_at_target = 0
		if(QUEST_SCAVENGE)
			var/items = list("copper wire", "circuit boards", "fusion cells", "scrap metal", "weapon parts", "medical supplies")
			Q.target_name = pick(items)
			Q.title = "Scavenge [capitalize(Q.target_name)]"
			Q.description = "I need [Q.target_name] from [Q.area_name]. Bring back what you find."
			Q.reward = rand(25, 75)
			Q.minimum_time_at_target = 200
		if(QUEST_RETRIEVE)
			var/items = list("a lost holotape", "a family heirloom", "a stolen item", "a data chip", "an old key")
			Q.target_name = pick(items)
			Q.title = "Retrieve [Q.target_name]"
			Q.description = "[capitalize(Q.target_name)] was taken to [Q.area_name]. Get it back for me."
			Q.reward = rand(30, 90)
			Q.minimum_time_at_target = 200

	return Q

/proc/get_player_quests(ckey)
	if(!ckey)
		return list()
	var/list/active = list()
	for(var/datum/dynamic_quest/Q in GLOB.player_active_quests[ckey])
		if(Q.is_active())
			active += Q
	return active

/proc/add_player_quest(ckey, datum/dynamic_quest/Q)
	if(!ckey || !Q)
		return
	if(!GLOB.player_active_quests[ckey])
		GLOB.player_active_quests[ckey] = list()
	if(length(GLOB.player_active_quests[ckey]) >= QUEST_MAX_ACTIVE)
		return FALSE
	GLOB.player_active_quests[ckey] += Q
	return TRUE

/proc/complete_dynamic_quest(ckey, datum/dynamic_quest/Q)
	if(!ckey || !Q || Q.completed)
		return FALSE
	Q.completed = TRUE
	if(GLOB.player_active_quests[ckey])
		GLOB.player_active_quests[ckey] -= Q
	log_game("QUEST: [ckey] completed quest '[Q.title]' for [Q.reward] caps")
	return TRUE

/proc/check_quest_progress_all(mob/living/carbon/human/H)
	if(!H || !H.ckey)
		return
	var/list/quests = get_player_quests(H.ckey)
	for(var/datum/dynamic_quest/Q in quests)
		Q.check_progress(H)

// ============================================
// QUEST GIVER NPC - Enhanced dialogue with quest integration
// ============================================

/mob/living/simple_animal/hostile/proc/offer_quest(mob/living/carbon/human/player)
	if(!dialogue_type || !player)
		return

	var/list/current_quests = get_player_quests(player.ckey)
	if(current_quests.len >= QUEST_MAX_ACTIVE)
		to_chat(player, span_warning("You already have [QUEST_MAX_ACTIVE] active quests. Complete some first!"))
		return

	var/datum/dynamic_quest/Q = generate_dynamic_quest(src)
	if(!Q)
		return

	var/choice = alert(player, "[src] says: \"[Q.description] Reward: [Q.reward] caps. Interested?\"", "Quest Offer", "Accept", "Maybe Later", "No")
	if(choice != "Accept")
		to_chat(player, span_notice("[src] nods. \"Come back if you change your mind.\""))
		return

	if(!add_player_quest(player.ckey, Q))
		to_chat(player, span_warning("You can't take on more quests right now."))
		return

	to_chat(player, span_notice("<b>NEW QUEST:</b> [Q.title] - [Q.description] (Reward: [Q.reward] caps)"))
	to_chat(player, span_notice("You have [Q.time_limit / 600] minutes to complete this quest."))

	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(check_quest_expired), player, Q), Q.time_limit, TIMER_DELETE_ME)

/mob/living/simple_animal/hostile/proc/complete_quest(mob/living/carbon/human/player, datum/dynamic_quest/Q)
	if(!Q || Q.completed || Q.expired)
		return
	if(!Q.can_complete(player))
		to_chat(player, span_warning("You haven't completed the objectives for '[Q.title]' yet!"))
		return

	Q.completed = TRUE
	var/obj/item/stack/f13Cash/caps/C = new(get_turf(player), Q.reward)
	player.put_in_hands(C)
	to_chat(player, span_greentext("<b>QUEST COMPLETE!</b> [Q.title] - You earned [Q.reward] caps!"))
	visible_message(span_notice("[src] hands [player] [Q.reward] caps. \"Pleasure doing business.\""))
	complete_dynamic_quest(player.ckey, Q)
	if(player.ckey)
		adjust_karma(player.ckey, 5)
		add_xp(player.ckey, XP_COMPLETE_QUEST_NEUTRAL, "quest:[Q.title]")

/proc/check_quest_expired(mob/living/carbon/human/player, datum/dynamic_quest/Q)
	if(!Q || Q.completed || Q.expired || !player)
		return
	Q.expired = TRUE
	to_chat(player, span_warning("<b>QUEST EXPIRED:</b> [Q.title] - Time ran out!"))
	if(player.ckey && GLOB.player_active_quests[player.ckey])
		GLOB.player_active_quests[player.ckey] -= Q

// ============================================
// QUEST BOARD - Physical board showing available quests
// ============================================

/obj/structure/quest_board
	name = "quest board"
	desc = "A board where job postings and bounties are pinned. Adventure awaits."
	icon = 'icons/obj/structures.dmi'
	icon_state = "noticeboard0"
	density = FALSE
	anchored = TRUE
	var/list/datum/dynamic_quest/quests = list()
	var/max_quests = 10

/obj/structure/quest_board/Initialize()
	. = ..()
	refresh_quests()

/obj/structure/quest_board/proc/refresh_quests()
	quests.Cut()
	for(var/i = 1 to max_quests)
		var/datum/dynamic_quest/Q = generate_dynamic_quest(src)
		if(Q)
			quests += Q

/obj/structure/quest_board/attack_hand(mob/user)
	if(!ishuman(user))
		return
	show_quests(user)

/obj/structure/quest_board/proc/show_quests(mob/user)
	var/html = "<center><h2>Wasteland Quests</h2>"
	html += "<a href='byond://?src=[REF(src)];refresh=1'>Refresh Board</a> | "
	html += "<a href='byond://?src=[REF(src)];my_quests=1'>My Quests</a><hr>"

	var/list/player_quests = get_player_quests(user.ckey)
	if(player_quests.len > 0)
		html += "<b>Your Active Quests ([player_quests.len]/[QUEST_MAX_ACTIVE]):</b><br>"
		for(var/datum/dynamic_quest/PQ in player_quests)
			var/time_left = max(0, PQ.time_limit - (world.time - PQ.post_time))
			html += "<i>[PQ.title]</i> - [PQ.reward] caps - [round(time_left / 600)]m left<br>"
			html += "&nbsp;&nbsp;[PQ.get_status_text()] "
			html += "<a href='byond://?src=[REF(src)];abandon=[REF(PQ)]'>(Abandon)</a><br>"
		html += "<hr>"

	html += "<table width='100%'>"
	html += "<tr><th>Type</th><th>Quest</th><th>Reward</th><th>Time</th><th>Action</th></tr>"
	for(var/i = 1 to quests.len)
		var/datum/dynamic_quest/Q = quests[i]
		Q.check_expiry()
		if(Q.completed || Q.expired)
			continue
		var/time_left = max(0, Q.time_limit - (world.time - Q.post_time))
		html += "<tr>"
		html += "<td>[Q.quest_type]</td>"
		html += "<td>[Q.title]</td>"
		html += "<td>[Q.reward] caps</td>"
		html += "<td>[round(time_left / 600)]m</td>"
		if(Q.claimed_by)
			html += "<td><i>Claimed</i></td>"
		else
			html += "<td><a href='byond://?src=[REF(src)];accept=[i]'>Accept</a></td>"
		html += "</tr>"
	html += "</table></center>"
	var/datum/browser/popup = new(user, "quest_board_[REF(src)]", "Quest Board", 500, 550)
	popup.set_content(html)
	popup.open()

/obj/structure/quest_board/Topic(href, href_list)
	if(!ishuman(usr))
		return
	if(href_list["refresh"])
		refresh_quests()
	else if(href_list["accept"])
		var/index = text2num(href_list["accept"])
		if(index && index <= quests.len)
			var/datum/dynamic_quest/Q = quests[index]
			if(!Q.completed && !Q.expired && !Q.claimed_by)
				var/list/current = get_player_quests(usr.ckey)
				if(current.len >= QUEST_MAX_ACTIVE)
					to_chat(usr, span_warning("You already have [QUEST_MAX_ACTIVE] active quests!"))
				else if(add_player_quest(usr.ckey, Q))
					Q.claimed_by = usr.real_name
					to_chat(usr, span_notice("<b>QUEST ACCEPTED:</b> [Q.title] - [Q.description] (Reward: [Q.reward] caps, Time: [Q.time_limit / 600] min)"))
					if(usr.ckey)
						adjust_karma(usr.ckey, 1)
					addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(check_quest_expired), usr, Q), max(1, Q.time_limit - (world.time - Q.post_time)), TIMER_DELETE_ME)
				else
					to_chat(usr, span_warning("You can't take on more quests right now."))
	else if(href_list["abandon"])
		var/datum/dynamic_quest/Q = locate(href_list["abandon"])
		if(Q && usr.ckey && GLOB.player_active_quests[usr.ckey])
			GLOB.player_active_quests[usr.ckey] -= Q
			to_chat(usr, span_warning("You abandoned the quest: [Q.title]"))
	show_quests(usr)

// ============================================
// QUEST COMPLETION VERB - Turn in completed quests at quest board
// ============================================

/obj/structure/quest_board/verb/turn_in_quest()
	set src in view(2)
	set name = "Turn In Quest"
	set category = "IC"

	if(!ishuman(usr))
		return

	var/mob/living/carbon/human/H = usr
	var/list/player_quests = get_player_quests(H.ckey)

	if(!player_quests.len)
		to_chat(H, span_warning("You have no active quests to turn in."))
		return

	var/datum/dynamic_quest/Q = input(H, "Which quest have you completed?", "Turn In Quest") as null|anything in player_quests
	if(!Q)
		return

	if(!Q.can_complete(H))
		to_chat(H, span_warning("You haven't completed the objectives for '[Q.title]' yet! [Q.get_status_text()]"))
		return

	var/confirm = alert(H, "Mark '[Q.title]' as complete and collect [Q.reward] caps?", "Turn In Quest", "Complete", "Cancel")
	if(confirm != "Complete")
		return

	complete_dynamic_quest(H.ckey, Q)
	var/obj/item/stack/f13Cash/caps/C = new(get_turf(H), Q.reward)
	H.put_in_hands(C)
	to_chat(H, span_greentext("<b>QUEST COMPLETE!</b> [Q.title] - You earned [Q.reward] caps!"))
	visible_message(span_notice("[H] turns in a completed quest at the board."))
	if(H.ckey)
		adjust_karma(H.ckey, 5)
		add_xp(H.ckey, XP_COMPLETE_QUEST_NEUTRAL, "quest:[Q.title]")
