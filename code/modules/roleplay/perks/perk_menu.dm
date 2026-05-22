
/client/verb/open_perk_menu()
	set name = "Perk Menu"
	set category = "Character"
	set desc = "View and select perks"
	
	if(!length(GLOB.perk_datums))
		initialize_perks()
	show_perk_menu(usr, ckey, "all")

/proc/show_perk_menu(mob/user, ckey, filter_stat = null)
	if(!user || !ckey)
		return

	if(!length(GLOB.perk_datums))
		initialize_perks()

	var/datum/browser/popup = new(user, "perk_menu", "Perks", 800, 700)
	
	var/points = get_perk_points(ckey)
	var/list/active_perks = get_active_perks(ckey)
	var/client_ref = REF(user.client)
	
	var/special_stats = list("S", "P", "E", "C", "I", "A", "L")
	var/stat_names = list("S" = "Strength", "P" = "Perception", "E" = "Endurance", "C" = "Charisma", "I" = "Intelligence", "A" = "Agility", "L" = "Luck")
	
	var/current_filter = filter_stat || "all"
	
	var/html = {"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #d4a574; font-family: "Courier New", monospace; padding: 15px; }
			h1 { color: #ffcc66; border-bottom: 1px solid #664422; padding-bottom: 10px; margin-top: 0; }
			h2 { color: #ffcc66; margin: 15px 0 10px 0; font-size: 1.2em; }
			.points-box { 
				background: #2a1a0a; 
				border: 2px solid #664422; 
				padding: 15px; 
				margin-bottom: 20px;
				text-align: center;
			}
			.points { color: #ffcc66; font-size: 2em; font-weight: bold; }
			.points-label { color: #996633; }
			.info-box { background: #221100; border: 1px solid #443322; padding: 10px; margin-bottom: 15px; color: #996633; }
			.perk-grid { display: flex; flex-wrap: wrap; gap: 10px; }
			.perk-card { 
				flex: 1 1 220px;
				background: #2a1a0a; 
				border: 1px solid #443322; 
				padding: 12px;
				max-width: 280px;
			}
			.perk-card.owned { border-color: #66cc66; }
			.perk-name { color: #ffcc66; font-weight: bold; font-size: 1.1em; }
			.perk-desc { color: #996633; font-size: 0.9em; margin: 8px 0; }
			.perk-req { color: #ff6666; font-size: 0.8em; }
			.perk-owned { color: #66cc66; font-weight: bold; }
			.perk-unlock-btn { 
				background: #224422; 
				color: #d4a574;
				border: 1px solid #446644;
				padding: 8px 16px;
				cursor: pointer;
				margin-top: 8px;
				width: 100%;
			}
			.perk-unlock-btn:hover { background: #335533; }
			.perk-unlock-btn:disabled { 
				background: #332211; 
				color: #665544;
				cursor: not-allowed;
			}
			.action-btn { 
				background: #332211; 
				color: #d4a574;
				border: 1px solid #443322;
				padding: 8px 16px;
				cursor: pointer;
				margin: 5px;
				display: inline-block;
			}
			.action-btn:hover { background: #443322; }
			.action-btn-active { background: #664422; color: #ffcc66; border-color: #ffcc66; }
		</style>
	</head>
	<body>
		<h1>Perks</h1>
		<div class="points-box">
			<div class="points">[points]</div>
			<div class="points-label">Perk Points Available</div>
		</div>
		
		<div class="info-box">
			<strong>How to earn perks:</strong> Earn 1 perk point for every 2 hours of active playtime. 
			Play the game to unlock perks!
		</div>
		
		<h2>Filter by SPECIAL</h2>
		<div>
"}

	// Add filter links for each SPECIAL stat
	for(var/stat in special_stats)
		var/active_class = (current_filter == stat) ? "action-btn-active" : ""
		html += {"<a href='byond://?src=[client_ref];perk_filter=[stat]' class='action-btn [active_class]'>[stat_names[stat]]</a>"}
	
	var/all_class = (current_filter == "all") ? "action-btn-active" : ""
	html += {"<a href='byond://?src=[client_ref];perk_filter=all' class='action-btn [all_class]'>All</a>"}
	
	var/filter_title = (current_filter == "all") ? "All Perks" : "[stat_names[current_filter]] Perks"
	html += {"
		</div>
		
		<h2>[filter_title]</h2>
		<div class="perk-grid">
"}

	// Generate perk cards
	for(var/id in GLOB.perk_datums)
		var/datum/perk/P = GLOB.perk_datums[id]
		if(!P)
			continue
		
		// Filter by SPECIAL stat
		if(filter_stat && filter_stat != "all" && P.special_stat != filter_stat)
			continue
		
		var/is_active = (id in active_perks)
		
		// Determine if can unlock
		var/can_unlock = FALSE
		if(istype(user, /mob/living/carbon/human) && !is_active)
			can_unlock = can_unlock_perk(user, id)
		
		// Build requirement text
		var/req_text = ""
		if(is_active)
			req_text = "<span class='perk-owned'>Unlocked</span>"
		else
			var/list/reqs = list()
			if(P.special_min > 0)
				var/user_stat = 0
				switch(P.special_stat)
					if("S") user_stat = user.special_s
					if("P") user_stat = user.special_p
					if("E") user_stat = user.special_e
					if("C") user_stat = user.special_c
					if("I") user_stat = user.special_i
					if("A") user_stat = user.special_a
					if("L") user_stat = user.special_l
				
				if(user_stat >= P.special_min)
					reqs += "[P.special_stat] [P.special_min] (You: [user_stat])"
				else
					reqs += "[P.special_stat] [P.special_min] (You: [user_stat] - Need more!)"
			
			if(P.requires_perk)
				var/datum/perk/req = get_perk_info(P.requires_perk)
				if(req)
					if(has_perk(user.ckey, P.requires_perk))
						reqs += "[req.name] (Owned)"
					else
						reqs += "[req.name] (Need first)"
			
			if(reqs.len)
				req_text = jointext(reqs, ", ")
			else
				req_text = "Available"
		
		// Build card HTML
		var/card_class = "perk-card"
		if(is_active)
			card_class += " owned"
		
		html += {"<div class='[card_class]'>"}
		html += {"<div class='perk-name'>[P.name]</div>"}
		html += {"<div class='perk-desc'>[P.desc]</div>"}
		html += {"<div class='perk-req'>[req_text]</div>"}
		
		if(can_unlock)
			html += {"<a href='byond://?src=[client_ref];unlock_perk=[id]' class='perk-unlock-btn'>Unlock</a>"}
		else if(is_active)
			html += {"<button class='perk-unlock-btn' disabled>Owned</button>"}
		else
			html += {"<button class='perk-unlock-btn' disabled>Locked</button>"}
		
		html += "</div>"

	html += {"
		</div>
	</body>
	</html>
"}
	
	popup.set_content(html)
	popup.open()

// Handle perk Topic calls - called from client_procs.dm
/proc/handle_perks_topic(client/C, href_list)
	if(href_list["unlock_perk"])
		var/perk_id = href_list["unlock_perk"]
		var/mob/living/carbon/human/H = C.mob
		if(istype(H))
			if(grant_perk(H, perk_id))
				show_perk_menu(H, C.ckey)
			else
				to_chat(H, span_warning("Cannot unlock this perk."))
		return TRUE
	
	if(href_list["perk_filter"])
		var/filter_stat = href_list["perk_filter"]
		show_perk_menu(C.mob, C.ckey, filter_stat)
		return TRUE
	
	return FALSE
