// Provides backstory selection at roundstart with mechanical benefits

GLOBAL_LIST_INIT(character_backgrounds, init_character_backgrounds())

/proc/init_character_backgrounds()
	var/list/backgrounds = list()
	backgrounds["vault_dweller"] = new /datum/background/vault_dweller()
	backgrounds["wastelander"] = new /datum/background/wastelander()
	backgrounds["tribal"] = new /datum/background/tribal()
	backgrounds["brotherhood_outcast"] = new /datum/background/brotherhood_outcast()
	backgrounds["ghoul_prewar"] = new /datum/background/ghoul_prewar()
	backgrounds["raider"] = new /datum/background/raider()
	backgrounds["enclave_remnant"] = new /datum/background/enclave_remnant()
	backgrounds["mercenary"] = new /datum/background/mercenary()
	return backgrounds

/datum/background
	var/id = ""
	var/name = ""
	var/description = ""
	var/list/starting_items = list()
	var/list/traits = list()
	var/list/reputation_modifiers = list()

/datum/background/proc/apply_background(mob/living/carbon/human/H)
	if(!H || !H.ckey)
		return FALSE
	
	// Try to equip starting items
	for(var/item_path in starting_items)
		if(ispath(item_path))
			var/obj/item/I = new item_path(H)
			if(!H.equip_to_appropriate_slot(I, TRUE))
				// If can't equip, put in hand or on floor
				H.put_in_hand(I, TRUE)
	
	// Apply reputation modifiers
	for(var/faction in reputation_modifiers)
		var/amount = reputation_modifiers[faction]
		adjust_faction_reputation(H.ckey, faction, amount)
	
	return TRUE

// Background definitions with starting items
/datum/background/vault_dweller
	id = "vault_dweller"
	name = "Vault Dweller"
	description = "You were born and raised inside a Vault, sealed away from the wasteland. You have knowledge of pre-war culture but the outside world is a mystery."
	starting_items = list(/obj/item/clothing/under/f13/vault)
	reputation_modifiers = list("ncr" = 5)

/datum/background/wastelander
	id = "wastelander"
	name = "Wastelander"
	description = "You've spent your entire life in the wasteland. You know how to survive, where to find water, and how to deal with raiders."
	starting_items = list(/obj/item/melee/onehanded/knife/hunting, /obj/item/flashlight)
	reputation_modifiers = list()

/datum/background/tribal
	id = "tribal"
	name = "Tribal"
	description = "You were raised by a tribal group, learning ancient customs and survival skills. You have a deep respect for nature and the old ways."
	starting_items = list(/obj/item/melee/onehanded/knife/bone)
	reputation_modifiers = list("greatkhans" = 10)

/datum/background/brotherhood_outcast
	id = "brotherhood_outcast"
	name = "Brotherhood Outcast"
	description = "You once served the Brotherhood of Steel, but circumstances forced you to leave. You still possess knowledge of technology."
	starting_items = list(/obj/item/book/manual, /obj/item/flashlight)
	reputation_modifiers = list("bos" = 25)

/datum/background/ghoul_prewar
	id = "ghoul_prewar"
	name = "Pre-War Ghoul"
	description = "You were ghoulified before the Great War, making you one of the oldest beings in the wasteland. You've seen civilizations rise and fall."
	starting_items = list(/obj/item/flashlight, /obj/item/storage/wallet/stash/low)
	reputation_modifiers = list("ncr" = -5)

/datum/background/raider
	id = "raider"
	name = "Raider"
	description = "You rose through the ranks of raider gangs, taking what you want through force. You have a violent reputation but know how to survive."
	starting_items = list(/obj/item/melee/onehanded/knife/switchblade)
	reputation_modifiers = list("ncr" = -20, "legion" = 10, "raiders" = 15)

/datum/background/enclave_remnant
	id = "enclave_remnant"
	name = "Enclave Remnant"
	description = "You served the Enclave before their fall. You have access to advanced technology and knowledge of their plans."
	starting_items = list(/obj/item/card/id, /obj/item/flashlight)
	reputation_modifiers = list("ncr" = -30, "enclave" = 20)

/datum/background/mercenary
	id = "mercenary"
	name = "Mercenary"
	description = "You're a hired gun who works for anyone who can pay. You have no loyalty to factions, only to the highest bidder."
	starting_items = list(/obj/item/melee/onehanded/knife/bowie)
	reputation_modifiers = list()

// Database functions
GLOBAL_LIST_EMPTY(background_cache)

/proc/get_character_background(ckey)
	if(!ckey)
		return null
	
	if(SSdbcore.Connect())
		var/datum/db_query/query = SSdbcore.NewQuery(
			"SELECT background_type, backstory FROM [format_table_name("character_background")] WHERE ckey = :ckey",
			list("ckey" = ckey)
		)
		
		if(!query.Execute())
			qdel(query)
			return GLOB.background_cache[ckey] || null
		
		var/list/background_data = null
		if(query.NextRow())
			var/bg_type = query.item[1]
			var/backstory = query.item[2]
			background_data = list("type" = bg_type, "backstory" = backstory)
		
		qdel(query)
		return background_data
	
	return GLOB.background_cache[ckey] || null

/proc/set_character_background(ckey, background_id, backstory = "")
	if(!ckey)
		return FALSE
	
	if(!GLOB.character_backgrounds[background_id])
		return FALSE
	
	if(SSdbcore.Connect())
		var/datum/db_query/query = SSdbcore.NewQuery(
			"INSERT INTO [format_table_name("character_background")] (ckey, background_type, backstory, created_at) VALUES (:ckey, :background_id, :backstory, NOW()) ON DUPLICATE KEY UPDATE background_type = :background_id, backstory = :backstory",
			list("ckey" = ckey, "background_id" = background_id, "backstory" = backstory)
		)
		
		var/success = query.Execute()
		qdel(query)
		return success
	
	GLOB.background_cache[ckey] = list("type" = background_id, "backstory" = backstory)
	return TRUE

/mob/proc/get_background()
	return get_character_background(ckey)

/mob/proc/apply_character_background()
	var/list/bg_data = get_character_background(ckey)
	if(!bg_data)
		return FALSE
	
	var/datum/background/B = GLOB.character_backgrounds[bg_data["type"]]
	if(!B)
		return FALSE
	
	if(ishuman(src))
		B.apply_background(src)
	
	return TRUE

/client/verb/select_background()
	set name = "Select Background"
	set category = "Admin"
	set desc = "Choose your character's backstory"
	
	// Build the list for selection
	var/list/choices = list()
	for(var/bg_id in GLOB.character_backgrounds)
		var/datum/background/B = GLOB.character_backgrounds[bg_id]
		choices[bg_id] = B.name
	
	// Create the interface
	var/datum/browser/popup = new(usr, "background_select", "Select Background", 600, 600)
	
	var/html = {"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #33ff33; font-family: "Courier New", monospace; padding: 20px; }
			h1 { color: #33ff33; border-bottom: 1px solid #33ff33; padding-bottom: 10px; }
			h2 { color: #66ff66; margin-top: 20px; }
			.background-option { 
				border: 1px solid #33ff33; 
				padding: 15px; 
				margin: 10px 0; 
				cursor: pointer;
			}
			.background-option:hover { background: #003300; }
			.background-name { font-weight: bold; font-size: 1.2em; }
			.background-desc { color: #99ff99; margin-top: 5px; }
			.rep-bonus { color: #ffcc00; font-size: 0.9em; }
			.backstory-input { 
				width: 100%; 
				background: #000; 
				color: #33ff33; 
				border: 1px solid #33ff33;
				padding: 10px;
				margin-top: 20px;
			}
			.confirm-btn {
				background: #003300;
				color: #33ff33;
				border: 1px solid #33ff33;
				padding: 10px 30px;
				margin-top: 20px;
				cursor: pointer;
				font-family: "Courier New", monospace;
			}
			.confirm-btn:hover { background: #004400; }
		</style>
	</head>
	<body>
		<h1>Select Your Background</h1>
		<p>This affects your starting items and faction reputation.</p>
	"}
	
	for(var/bg_id in GLOB.character_backgrounds)
		var/datum/background/B = GLOB.character_backgrounds[bg_id]
		var/rep_text = ""
		if(length(B.reputation_modifiers))
			var/list/reps = list()
			for(var/faction in B.reputation_modifiers)
				var/amount = B.reputation_modifiers[faction]
				reps += "[faction]: [amount >= 0 ? "+" : ""][amount]"
			rep_text = "<br><span class='rep-bonus'>Starting rep: [reps.Join(", ")]</span>"
		
		html += "<div class='background-option' onclick='selectBackground(\"[bg_id]\")'>"
		html += "<div class='background-name'>[B.name]</div>"
		html += "<div class='background-desc'>[B.description]</div>[rep_text]"
		html += "</div>"
	
	html += {"
		<div id='selected-info' style='display:none;'>
			<h2 id='selected-name'></h2>
			<p id='selected-desc'></p>
			<textarea id='backstory' class='backstory-input' placeholder='Write your backstory (optional)...' rows='4' maxlength='200'></textarea>
			<br>
			<button class='confirm-btn' onclick='confirmBackground()'>Confirm Selection</button>
		</div>
		<script>
			var selectedBg = null;
			function selectBackground(bgId) {
				selectedBg = bgId;
				document.getElementById('selected-info').style.display = 'block';
			}
			function confirmBackground() {
				if(!selectedBg) return;
				var backstory = document.getElementById('backstory').value;
				window.location = '?src=[REF(src)];background_choice=' + selectedBg + ';backstory=' + encodeURIComponent(backstory);
			}
		</script>
	</body>
	</html>"}
	
	popup.set_content(html)
	popup.open()

// Handle background Topic calls - called from client_procs.dm
/proc/handle_backgrounds_topic(client/C, href_list)
	if(href_list["background_choice"])
		var/choice = href_list["background_choice"]
		var/backstory = href_list["backstory"]
		if(backstory && length(backstory) > 200)
			backstory = copytext(backstory, 1, 200)
		
		if(set_character_background(C.ckey, choice, backstory))
			to_chat(C.mob, span_notice("Background set! It will be applied next spawn."))
			C.mob << browse(null, "window=background_select")
		else
			to_chat(C.mob, span_warning("Failed to set background."))
		return TRUE
	
	return FALSE

