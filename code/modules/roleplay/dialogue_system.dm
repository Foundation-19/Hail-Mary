// Branching dialogue trees with reputation requirements
// Supports JSON loading from config/dialogues/

GLOBAL_LIST_INIT(dialogue_trees, list())
GLOBAL_LIST_EMPTY(json_dialogue_cache)

// ============ HELPER FOR JSON LOADING ============
// This is called at runtime to ensure loader is loaded first
/proc/ensure_dialogue_loaded()
	// Check if JSON cache already has data
	if(GLOB.json_dialogue_cache && GLOB.json_dialogue_cache.len > 0)
		return TRUE
	// At runtime, call the loader if it exists (it's loaded after this file in the DME)
	// This works because the actual proc will be available when the game runs
	return FALSE

// ============ INITIALIZATION ============

/proc/init_dialogue_system()
	if(GLOB.dialogue_trees.len > 0)
		return GLOB.dialogue_trees
	
	GLOB.dialogue_trees = list()
	
	// Try to load JSON dialogues
	if(ensure_dialogue_loaded() && GLOB.json_dialogue_cache && GLOB.json_dialogue_cache.len > 0)
		log_world("dialogue_system: Using [GLOB.json_dialogue_cache.len] JSON-loaded dialogue trees")
		return GLOB.dialogue_trees
	
	// ============ NCR ============
	GLOB.dialogue_trees["ncr"] = list(
		"start" = list(
			text = "What do you want, civilian? We're busy here.",
			responses = list(
				"I need supplies" = "ncr_supplies",
				"Looking for work" = "ncr_work",
				"Any missions?" = "ncr_missions",
				"Got any jobs?" = "_quest_offer",
				"How's the situation?" = "ncr_situation"
			)
		),
		"start_hero" = list(
			text = "Ah, it's you! The hero of the wastes. How can I assist?",
			requirements = list("min_karma" = 500),
			responses = list(
				"I need supplies" = "ncr_supplies",
				"Looking for work" = "ncr_work",
				"Any special missions?" = "ncr_hero_mission",
				"Got any jobs?" = "_quest_offer"
			)
		),
		"start_villain" = list(
			text = "I've heard about you. The NCR has eyes everywhere. Watch yourself.",
			requirements = list("max_karma" = -500),
			responses = list(
				"Just passing through" = "ncr_situation",
				"Got any jobs?" = "_quest_offer"
			)
		),
		"ncr_hero_mission" = list(
			text = "We have a special task. A legendary figure like you could help with the Legion leadership. Interested?",
			rewards = list("rep" = list("ncr" = 25), "quest" = "ncr_legendary_mission")
		),
		"ncr_supplies" = list(
			text = "Talk to the quartermaster tent. We're short on everything, but he'll find you something.",
			rewards = list("location" = " quartermaster tent")
		),
		"ncr_work" = list(
			text = "Good to hear. We always need help with raider problems.",
			responses = list(
				"I'm ready to help" = "ncr_volunteer",
				"What kind of help?" = "ncr_missions"
			)
		),
		"ncr_volunteer" = list(
			text = "Good to hear. Talk to Captain Wells for assignment.",
			rewards = list("rep" = list("ncr" = 5))
		),
		"ncr_missions" = list(
			text = "We've got raiders to the east giving us trouble. Also, Legion scouts spotted north. It's been quiet... too quiet.",
			responses = list(
				"Raiders? I can help" = "ncr_raiders",
				"Legion? What's happening?" = "ncr_legion_info"
			)
		),
		"ncr_raiders" = list(
			text = "Clear out the raider camp at [pick("Canyon", "Dusty", "Broken")] Hills. Bring back proof and you'll be rewarded.",
			rewards = list("quest" = "raider_camp")
		),
		"ncr_legion_info" = list(
			text = "Scouts only. No main force yet. But we're watching. You see anything, report it immediately."
		),
		"ncr_situation" = list(
			text = "Raiders to the east, Legion to the north. It's been quiet... too quiet. Stay alert, civilian."
		)
	)
	GLOB.dialogue_trees["ncr_sergeant"] = GLOB.dialogue_trees["ncr"]
	
	// ============ LEGION FRUMENTARIUS ============
	GLOB.dialogue_trees["legion"] = list(
		"start" = list(
			text = "Are you here to join the Legion, or do you seek information?",
			responses = list(
				"I seek information" = "legion_info",
				"I wish to join" = "legion_join",
				"Any work available?" = "legion_work",
				"Got any jobs?" = "_quest_offer"
			)
		),
		"start_hero" = list(
			text = "You carry the weight of honor. Caesar respects strength.",
			requirements = list("min_karma" = 500),
			responses = list(
				"I seek information" = "legion_info",
				"Any work available?" = "legion_work",
				"Got any jobs?" = "_quest_offer"
			)
		),
		"start_villain" = list(
			text = "Ah, a pragmatist. The ends justify the means. Good. We have work.",
			requirements = list("max_karma" = -250),
			responses = list(
				"What work?" = "legion_evil_work",
				"Got any jobs?" = "_quest_offer"
			)
		),
		"legion_evil_work" = list(
			text = "We need... eliminated. Quietly. The NCR has informants in their camps. Bring us their dogtags.",
			rewards = list("rep" = list("legion" = 20), "karma" = -15)
		),
		"legion_info" = list(
			text = "The wasteland belongs to Caesar. The NCR rots from within. Their democracy is weakness.",
			responses = list(
				"And what of the Brotherhood?" = "legion_brotherhood",
				"I see..." = "legion_end"
			)
		),
		"legion_brotherhood" = list(
			text = "The Brotherhood hides in their bunkers. They fear the light of Caesar. They will be crushed in time."
		),
		"legion_join" = list(
			text = "The Legion welcomes those with strength. Prove yourself in battle, and you may rise among us.",
			requirements = list("min_rep" = list("legion" = 10))
		),
		"legion_work" = list(
			text = "We need supplies. Bring weapons and medicine. The Legion rewards those who serve."
		),
		"legion_end" = list(
			text = "Walk wisely, wastelanders."
		)
	)
	
	// ============ BROTHERHOOD OF STEEL ============
	GLOB.dialogue_trees["bos"] = list(
		"start" = list(
			text = "State your business, outsider. This is Brotherhood territory.",
			responses = list(
				"I bring technology" = "bos_donate",
				"Seeking knowledge" = "bos_knowledge",
				"Got any jobs?" = "_quest_offer",
				"Just passing through" = "bos_pass"
			)
		),
		"bos_donate" = list(
			text = "Technology belongs to the Brotherhood. What do you have to offer?",
			requirements = list("has_tech" = TRUE)
		),
		"bos_knowledge" = list(
			text = "Knowledge is power. But some knowledge is too dangerous. What do you seek?"
		),
		"bos_pass" = list(
			text = "Then move along quickly. Our patience is limited."
		)
	)
	GLOB.dialogue_trees["brotherhood"] = GLOB.dialogue_trees["bos"]
	
	// ============ GENERIC TRADER ============
	GLOB.dialogue_trees["trader"] = list(
		"start" = list(
			text = "Take a look at my wares. Best prices in the wasteland!",
			responses = list(
				"What do you have?" = "trader_wares",
				"Any rumors?" = "trader_rumors",
				"I'm looking to sell" = "trader_sell",
				"Got any jobs?" = "_quest_offer",
				"Any discounts?" = "trader_discount"
			)
		),
		"start_hero" = list(
			text = "It's the hero! What can I do for you? First round's on me!",
			requirements = list("min_karma" = 500),
			responses = list(
				"What do you have?" = "trader_wares",
				"Any rumors?" = "trader_rumors",
				"Got any jobs?" = "_quest_offer",
				"Best deal?" = "trader_hero_deal"
			)
		),
		"start_villain" = list(
			text = "I've heard of you... Stay back. Don't touch my wares.",
			requirements = list("max_karma" = -500),
			responses = list(
				"Just looking" = "trader_wares",
				"Got any jobs?" = "_quest_offer"
			)
		),
		"trader_wares" = list(
			text = "Stimpaks, Rad-Away, food, ammo - you name it! Prices are negotiable for friends."
		),
		"trader_rumors" = list(
			text = "Word is there's a cache of pre-war tech somewhere to the south. Raiders are guarding it. Could be worth a fortune...",
			cost = 20,
			rewards = list("info" = "tech_cache")
		),
		"trader_sell" = list(
			text = "What do you have? Caps talks, friend."
		),
		"trader_discount" = list(
			text = "Hmm, you've got a reputation. 10% off, consider it a thank you.",
			rewards = list("karma" = 3)
		),
		"trader_hero_deal" = list(
			text = "25% off! Tell your friends about me, hero. You've earned it.",
			rewards = list("karma" = 5)
		)
	)
	
	// ============ FOLLOWERS OF THE APOCRYPHA ============
	GLOB.dialogue_trees["followers"] = list(
		"start" = list(
			text = "Welcome, traveler. The Followers offer aid to all who seek knowledge.",
			responses = list(
				"I need medical help" = "followers_medical",
				"Looking for work" = "followers_work",
				"Got any jobs?" = "_quest_offer",
				"What do you do?" = "followers_mission"
			)
		),
		"followers_medical" = list(
			text = "We can help, but our supplies are stretched thin. Any donations would be appreciated.",
			rewards = list("heal" = TRUE)
		),
		"followers_work" = list(
			text = "The wasteland is full of those in need. Help us help them, and you'll be rewarded.",
			rewards = list("rep" = list("followers" = 10))
		),
		"followers_mission" = list(
			text = "We preserve knowledge, heal the sick, and try to bring light to the darkness. Join us, if you believe in our cause."
		)
	)
	
	// ============ GENERIC WASTELANDER ============
	GLOB.dialogue_trees["generic"] = list(
		"start" = list(
			text = "Hey there, traveler. Watch yourself out in the wastes.",
			responses = list(
				"Any news?" = "generic_news",
				"Got any jobs?" = "_quest_offer",
				"Stay safe" = "generic_end"
			)
		),
		"generic_news" = list(
			text = "Heard there's been trouble with raiders lately. Keep your weapon close."
		),
		"generic_end" = list(
			text = "You too."
		)
	)
	
	// ============ ENCLAVE ============
	GLOB.dialogue_trees["enclave"] = list(
		"start" = list(
			text = "Citizen. State your business.",
			responses = list(
				"Just passing through" = "enclave_pass",
				"Who are you?" = "enclave_info",
				"Got any jobs?" = "_quest_offer"
			)
		),
		"enclave_pass" = list(
			text = "Move along. This area is secured."
		),
		"enclave_info" = list(
			text = "We are the Enclave. The rightful government of these United States. Remember that."
		)
	)
	
	// ============ VAULT ============
	GLOB.dialogue_trees["vault"] = list(
		"start" = list(
			text = "Welcome to our Vault. We don't get many visitors.",
			responses = list(
				"Nice to meet you" = "vault_greet",
				"Any work?" = "vault_work",
				"Got any jobs?" = "_quest_offer"
			)
		),
		"vault_greet" = list(
			text = "Likewise. Just... don't touch anything without asking."
		),
		"vault_work" = list(
			text = "We sometimes need supplies from the surface. Check with the Overseer if you're interested.",
			rewards = list("rep" = list("vault" = 5))
		)
	)
	
	// ============ BIGHORN ============
	GLOB.dialogue_trees["bighorn"] = list(
		"start" = list(
			text = "Welcome to Bighorn. We're a peaceful town, but we can handle ourselves.",
			responses = list(
				"What's there to do?" = "bighorn_activities",
				"Any trouble?" = "bighorn_trouble",
				"Got any jobs?" = "_quest_offer"
			)
		),
		"bighorn_activities" = list(
			text = "We've got a saloon, a general store, and not much else. But it's safe here."
		),
		"bighorn_trouble" = list(
			text = "Raiders sometimes test our defenses. The Sheriff keeps them in line."
		)
	)
	GLOB.dialogue_trees["city"] = GLOB.dialogue_trees["bighorn"]
	
	
	return GLOB.dialogue_trees

// ============ DIALOGUE FUNCTIONS ============

/proc/start_dialogue(mob/player, npc_type)
	if(!GLOB.dialogue_trees.len)
		init_dialogue_system()
	
	// Try JSON first, then fallback to hardcoded
	var/dialogue_tree = GLOB.json_dialogue_cache[npc_type]
	if(!dialogue_tree)
		dialogue_tree = GLOB.dialogue_trees[npc_type]
	
	if(!dialogue_tree)
		to_chat(player, span_warning("This NPC has nothing to say."))
		return
	
	show_dialogue_node(player, npc_type, "start")

/proc/get_faction_for_dialogue(npc_type)
	if(npc_type == "ncr" || npc_type == "ncr_ranger")
		return "ncr"
	if(npc_type == "legion" || npc_type == "legion_centurion")
		return "legion"
	if(npc_type == "brotherhood" || npc_type == "brotherhood_elder")
		return "bos"
	if(npc_type == "bighorn" || npc_type == "bighorn_mayor" || npc_type == "bighorn_sheriff")
		return "city"
	if(npc_type == "hub")
		return "hubologists"
	if(npc_type == "vault")
		return "vault"
	return null

/proc/get_rank_greeting(mob/player, npc_type)
	var/faction = get_faction_for_dialogue(npc_type)
	if(!faction)
		return null
	
	var/reputation = get_faction_reputation(player.ckey, faction)
	var/rank = get_faction_rank(faction, reputation)
	
	#ifdef GLOBAL_LIST_INIT_json_dialogue_cache
	var/dialogue_tree = GLOB.json_dialogue_cache[npc_type]
	#else
	var/dialogue_tree = null
	#endif
	if(!dialogue_tree)
		dialogue_tree = GLOB.dialogue_trees[npc_type]
	
	if(dialogue_tree && dialogue_tree["rank_greetings"])
		var/list/rank_greetings = dialogue_tree["rank_greetings"]
		if(rank_greetings[rank])
			return rank_greetings[rank]
	
	return null

/proc/show_dialogue_node(mob/player, npc_type, node_id)
	// Special handling: quest offer
	if(node_id == "_quest_offer")
		var/mob/living/simple_animal/hostile/quest_npc = null
		for(var/mob/living/simple_animal/hostile/npc in view(7, player))
			if(npc.dialogue_type == npc_type && npc.stat == CONSCIOUS)
				quest_npc = npc
				break
		if(quest_npc && ishuman(player))
			quest_npc.offer_quest(player)
		else
			to_chat(player, span_warning("Nobody here has work for you."))
		return

	// Try JSON first, then fallback to hardcoded
	#ifdef GLOBAL_LIST_INIT_json_dialogue_cache
	var/dialogue_tree = GLOB.json_dialogue_cache[npc_type]
	#else
	var/dialogue_tree = null
	#endif
	if(!dialogue_tree)
		dialogue_tree = GLOB.dialogue_trees[npc_type]
	
	if(!dialogue_tree)
		return
	
	// JSON format uses ["nodes"], DM hardcoded format has nodes at top level
	var/list/nodes = null
	if(dialogue_tree["nodes"])
		nodes = dialogue_tree["nodes"]
	else
		nodes = dialogue_tree  // DM format: nodes are at top level
	
	if(!nodes || !nodes[node_id])
		return
	var/list/node_data = nodes[node_id]
	var/display_text = node_data["text"]
	
	// Check requirements
	if(node_data["requirements"])
		var/list/reqs = node_data["requirements"]
		
		if(reqs["min_rep"])
			var/list/rep_reqs = reqs["min_rep"]
			for(var/faction in rep_reqs)
				var/current_rep = get_faction_reputation(player.ckey, faction)
				if(current_rep < rep_reqs[faction])
					display_text = "You don't have enough standing with [faction] to ask about that."
					node_data["responses"] = null
		
		if(reqs["has_tech"] && !player_has_tech(player))
			display_text = "You don't have any technology to offer."
			node_data["responses"] = null
		
		if(reqs["min_karma"])
			var/min_k = reqs["min_karma"]
			if(get_karma(player.ckey) < min_k)
				display_text = "Your reputation isn't sufficient to ask about that."
				node_data["responses"] = null
		
		if(reqs["max_karma"])
			var/max_k = reqs["max_karma"]
			if(get_karma(player.ckey) > max_k)
				display_text = "We have nothing to discuss."
				node_data["responses"] = null
	
	// Dynamic greeting based on karma and faction rep
	if(node_id == "start")
		// Check for NPC memory-based greeting first (if player is human)
		var/attitude_greeting = null
		if(ishuman(player))
			var/mob/living/carbon/human/H = player
			// Find NPC with this dialogue_type to check memory
			for(var/mob/living/simple_animal/hostile/npc in view(7, H))
				if(npc.dialogue_type == npc_type)
					var/attitude = npc.get_player_attitude(H)
					if(attitude != 0)
						attitude_greeting = get_attitude_greeting(attitude, npc_type)
						// Add attitude indicator
						var/att_color = attitude > 0 ? "#88ff88" : "#ff8888"
						var/att_text = attitude > 0 ? " (Friendly)" : " (Wary)"
						display_text += "<br><span style='color:[att_color]'>[att_text]</span>"
					break
		
		// Try rank-based greeting from JSON
		var/rank_greeting = get_rank_greeting(player, npc_type)
		if(rank_greeting)
			if(attitude_greeting)
				display_text = attitude_greeting
			else
				display_text = rank_greeting
		
		// Add karma indicator
		var/player_karma = get_karma(player.ckey)
		var/karma_suffix = ""
		if(player_karma >= KARMA_LEGEND)
			karma_suffix = " <span style='color:#66ff66'>[get_karma_title(player_karma)]</span>"
		else if(player_karma >= KARMA_HERO)
			karma_suffix = " <span style='color:#88ff88'>Welcome, friend.</span>"
		else if(player_karma <= KARMA_INFAMOUS)
			karma_suffix = " <span style='color:#ff6666'>Don't cause trouble.</span>"
		else if(player_karma <= KARMA_VILLAIN)
			karma_suffix = " <span style='color:#ff8888'>...What do you want?</span>"
		
		display_text += karma_suffix
		
		// Add faction reputation to greeting based on NPC type
		var/faction = get_faction_for_dialogue(npc_type)
		if(faction)
			var/faction_rep = get_faction_reputation(player.ckey, faction)
			var/faction_rank = get_faction_rank(faction, faction_rep)
			var/faction_color = "#997744"
			if(faction == "legion")
				faction_color = "#cc4444"
			else if(faction == "bos")
				faction_color = "#4444cc"
			else if(faction == "city")
				faction_color = "#44aa44"
			display_text += "<br><span style='color:[faction_color]'>[uppertext(faction)] Standing: [faction_rank] ([faction_rep])</span>"
	
	// Check cost (caps required)
	if(node_data["cost"])
		var/cost = node_data["cost"]
		var/player_caps = get_caps_amount(player)
		if(player_caps < cost)
			display_text += " (Requires [cost] caps)"
	
	// Give rewards
	if(node_data["rewards"])
		give_dialogue_rewards(player, node_data["rewards"])
	
	// Execute service if present
	if(node_data["service"])
		// Find NPC with this dialogue type to execute service
		var/mob/living/simple_animal/hostile/service_npc = null
		for(var/mob/living/simple_animal/hostile/npc in view(7, player))
			if(npc.dialogue_type == npc_type)
				service_npc = npc
				break
		
		if(service_npc)
			var/result = handle_service_response(player, service_npc, node_data["service"])
			switch(result)
				if("insufficient_funds")
					display_text += "<br><span style='color:#ff6666'>You can't afford that service.</span>"
				if("cooldown")
					display_text += "<br><span style='color:#ffaa66'>That service isn't available yet.</span>"
				if("error")
					display_text += "<br><span style='color:#ff6666'>Something went wrong.</span>"
	
	// Build UI
	var/datum/browser/popup = new(player, "dialogue_[npc_type]", "Conversation", 600, 450)
	
	var/html = {"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #d4a574; font-family: "Courier New", monospace; padding: 20px; }
			h1 { color: #ffcc66; border-bottom: 1px solid #664422; padding-bottom: 10px; }
			.npc-name { color: #996633; font-size: 0.9em; margin-bottom: 15px; }
			.dialogue-text { font-size: 1.1em; margin: 20px 0; padding: 15px; background: #2a1a0a; border: 1px solid #664422; min-height: 60px; }
			.response-btn { display: block; width: 100%; padding: 12px; margin: 8px 0; background: #332211; color: #d4a574; border: 1px solid #664422; cursor: pointer; text-align: left; }
			.response-btn:hover { background: #443322; }
			.req-note { color: #666; font-size: 0.8em; display: block; }
			.close-btn { padding: 10px 20px; background: #221100; color: #996633; border: 1px solid #664422; margin-top: 20px; cursor: pointer; }
		</style>
	</head>
	<body>
		<h1>Conversation</h1>
		<div class="npc-name">[uppertext(npc_type)]</div>
		<div class="dialogue-text">[display_text]</div>
		<div class="responses">
"}
	
	// Add response buttons - support both JSON array and DM assoc list formats
	if(node_data["responses"])
		var/list/responses = node_data["responses"]
		
		// JSON format: list of dicts with "text" and "next"
		if(responses.len > 0 && islist(responses[1]))
			for(var/list/response in responses)
				if(response["text"] && response["next"])
					html += "<button class='response-btn' onclick='window.location=\"byond://?src=[REF(player)];dialogue_response=[npc_type];node=[response["next"]]\"'>[response["text"]]</button>"
		
		// DM format: assoc list "text" = "node_id"
		else
			for(var/response_text in responses)
				var/next_node = responses[response_text]
				html += "<button class='response-btn' onclick='window.location=\"byond://?src=[REF(player)];dialogue_response=[npc_type];node=[next_node]\"'>[response_text]</button>"
	
	// Add cost note if applicable
	if(node_data["cost"])
		var/cost_val = node_data["cost"]
		html += "<span class='req-note'>Costs [cost_val] caps</span>"
	
	html += {"
		</div>
		<a href="byond://" class='close-btn' style="display:inline-block;text-decoration:none;text-align:center;">End Conversation</a>
	</body>
	</html>
	"}
	
	popup.set_content(html)
	popup.open()

// ============ HELPER FUNCTIONS ============

/proc/player_has_tech(mob/player)
	for(var/obj/item/I in player.get_contents())
		if(istype(I, /obj/item/weapon) || istype(I, /obj/item/stock_parts))
			return TRUE
	return FALSE

/proc/get_caps_amount(mob/living/carbon/human/user)
	if(!user)
		return 0
	var/caps = 0
	for(var/obj/item/stack/f13Cash/caps/C in user.get_contents())
		if(istype(C))
			caps += C.amount
	return caps

/proc/give_dialogue_rewards(mob/player, list/rewards)
	if(!rewards)
		return
	
	if(rewards["rep"])
		var/list/rep_changes = rewards["rep"]
		for(var/faction in rep_changes)
			adjust_faction_reputation(player.ckey, faction, rep_changes[faction])
	
	if(rewards["karma"])
		adjust_karma(player.ckey, rewards["karma"])
		modify_karma_by_action(player.ckey, "complete_neutral_quest", null, "Dialogue reward")
	
	if(rewards["quest"])
		var/quest_id = rewards["quest"]
		var/list/quest_data = get_quest_data(quest_id)
		if(quest_data && quest_data["name"])
			accept_player_quest(player.ckey, quest_id)
			to_chat(player, span_notice("New quest accepted: [quest_data["name"]]"))
		else
			accept_player_quest(player.ckey, quest_id)
			to_chat(player, span_notice("New quest accepted: [quest_id]"))
	
	if(rewards["caps"])
		var/caps_amount = rewards["caps"]
		var/obj/item/stack/f13Cash/caps/c = new(get_turf(player))
		c.amount = caps_amount
		player.put_in_hands(c)
		to_chat(player, span_notice("You received [caps_amount] caps."))
	
	if(rewards["heal"])
		var/mob/living/L = player
		L.reagents.add_reagent(/datum/reagent/medicine/stimpak, 5)
		to_chat(player, span_notice("You feel refreshed."))
	
	if(rewards["info"])
		var/info_text = rewards["info"]
		to_chat(player, span_notice("You learned: [info_text]"))
		// Could trigger a popup here
	
	if(rewards["location"])
		var/location_name = rewards["location"]
		to_chat(player, span_notice("Location noted: [location_name]"))

/proc/get_npc_dialogue_type(mob/living/carbon/human/H)
	// Use fallback detection - the loader will be available at runtime
	// and can override this by directly setting dialogue trees
	var/name_lower = lowertext(H.name)
	
	// Fallback to legacy detection
	if(findtext(name_lower, "ncr") || findtext(name_lower, "ranger") || findtext(name_lower, "sergeant") || findtext(name_lower, "soldier"))
		return "ncr"
	
	if(findtext(name_lower, "legion") || findtext(name_lower, "centurion") || findtext(name_lower, "decanus") || findtext(name_lower, "caesar"))
		return "legion"
	
	if(findtext(name_lower, "brotherhood") || findtext(name_lower, "paladin") || findtext(name_lower, "elder") || findtext(name_lower, "initiate"))
		return "brotherhood"
	
	if(findtext(name_lower, "trader") || findtext(name_lower, "merchant") || findtext(name_lower, "wander"))
		return "trader"
	
	if(findtext(name_lower, "follower") || findtext(name_lower, "scholar"))
		return "followers"
	
	// Default based on job
	if(H.mind && H.mind.assigned_role)
		var/role = H.mind.assigned_role
		if(findtext(role, "NCR"))
			return "ncr"
		if(findtext(role, "Legion"))
			return "legion"
		if(findtext(role, "Brotherhood"))
			return "brotherhood"
	
	return "generic"

// ============ TOPIC HOOKS ============

/mob/living/carbon/human/Topic(href, href_list)
	if(href_list["dialogue_response"])
		var/npc_type = href_list["dialogue_response"]
		var/node_id = href_list["node"]
		
		if(npc_type && node_id)
			show_dialogue_node(src, npc_type, node_id)
			return
	
	. = ..()

// ============ WORLD INIT ============

/world/proc/init_dialogue()
	init_dialogue_system()
