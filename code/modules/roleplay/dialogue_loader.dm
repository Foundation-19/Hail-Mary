// Loads dialogue trees from JSON config files

GLOBAL_LIST_EMPTY(dialogue_json_cache)

#define DIALOGUE_CONFIG_DIR "config/dialogues"

/proc/load_dialogue_files()
	if(GLOB.json_dialogue_cache.len > 0)
		return GLOB.json_dialogue_cache

	GLOB.json_dialogue_cache = list()
	
	var/list/json_files = flist(DIALOGUE_CONFIG_DIR)
	
	for(var/file in json_files)
		if(!findtext(file, ".json"))
			continue
		
		var/path = "[DIALOGUE_CONFIG_DIR]/[file]"
		var/json_text = file2text(path)
		
		if(!json_text)
			log_world("dialogue_loader: Failed to read [path]")
			continue
		
		var/list/dialogue_data = json_decode(json_text)
		
		if(!dialogue_data)
			log_world("dialogue_loader: Failed to parse JSON from [path]")
			continue
		
		for(var/dialogue_id in dialogue_data)
			GLOB.json_dialogue_cache[dialogue_id] = dialogue_data[dialogue_id]
			log_world("dialogue_loader: Loaded dialogue '[dialogue_id]' from [file]")
	
	if(GLOB.json_dialogue_cache.len > 0)
		log_world("dialogue_loader: Loaded [GLOB.json_dialogue_cache.len] dialogue trees")
	
	return GLOB.json_dialogue_cache

/proc/get_dialogue_tree(dialogue_id)
	if(!GLOB.json_dialogue_cache.len)
		load_dialogue_files()
	
	return GLOB.json_dialogue_cache[dialogue_id]

/proc/get_dialogue_for_npc(mob/living/carbon/human/npc)
	// Check for explicit dialogue_type first (allows custom NPC dialogue)
	if(npc.dialogue_type)
		return npc.dialogue_type
	
	. = get_dialogue_by_faction(npc)
	if(.)
		return .
	
	. = get_dialogue_by_name(npc)
	if(.)
		return .
	
	. = get_dialogue_by_job(npc)
	if(.)
		return .
	
	. = get_dialogue_by_area(npc)
	if(.)
		return .
	
	return "generic"

/proc/get_dialogue_by_faction(mob/living/carbon/human/npc)
	if(!npc.faction)
		return null
	
	var/faction_lower = lowertext(npc.faction)
	
	switch(faction_lower)
		if("ncr")
			return "ncr"
		if("legion")
			return "legion"
		if("brotherhood", "bos")
			return "brotherhood"
		if("enclave")
			return "enclave"
		if("vault")
			return "vault"
		if("city")
			return "bighorn"
		if("hubologists")
			return "hub"
	
	return null

/proc/get_dialogue_by_name(mob/living/carbon/human/npc)
	var/name_lower = lowertext(npc.name)
	
	if(findtext(name_lower, "sergeant") || findtext(name_lower, "soldier") || findtext(name_lower, "ranger"))
		return "ncr"
	
	if(findtext(name_lower, "centurion") || findtext(name_lower, "decanus") || findtext(name_lower, "caesar") || findtext(name_lower, "legionary"))
		return "legion"
	
	if(findtext(name_lower, "paladin") || findtext(name_lower, "elder") || findtext(name_lower, "initiate") || findtext(name_lower, "scribe"))
		return "brotherhood"
	
	if(findtext(name_lower, "overseer") || findtext(name_lower, "dweller"))
		return "vault"
	
	if(findtext(name_lower, "colonel") || findtext(name_lower, "commander") || findtext(name_lower, "enclave"))
		return "enclave"
	
	if(findtext(name_lower, "mayor") || findtext(name_lower, "sheriff"))
		return "bighorn"
	
	if(findtext(name_lower, "trader") || findtext(name_lower, "merchant"))
		return "trader"
	
	if(findtext(name_lower, "hubologist"))
		return "hub"
	
	return null

/proc/get_dialogue_by_job(mob/living/carbon/human/npc)
	if(!npc.mind || !npc.mind.assigned_role)
		return null
	
	var/role = lowertext(npc.mind.assigned_role)
	
	if(findtext(role, "ncr"))
		return "ncr"
	
	if(findtext(role, "legion"))
		return "legion"
	
	if(findtext(role, "brotherhood"))
		return "brotherhood"
	
	if(findtext(role, "enclave"))
		return "enclave"
	
	if(findtext(role, "vault"))
		return "vault"
	
	if(findtext(role, "mayor") || findtext(role, "sheriff") || findtext(role, "city"))
		return "bighorn"
	
	return null

/proc/get_dialogue_by_area(mob/living/carbon/human/npc)
	var/area/A = get_area(npc)
	if(!A)
		return null
	
	var/area_name = lowertext(A.name)
	
	if(findtext(area_name, "ncr"))
		return "ncr"
	
	if(findtext(area_name, "legion"))
		return "legion"
	
	if(findtext(area_name, "brotherhood") || findtext(area_name, "bunker"))
		return "brotherhood"
	
	if(findtext(area_name, "hub"))
		return "hub"
	
	if(findtext(area_name, "bighorn"))
		return "bighorn"
	
	if(findtext(area_name, "rockspring") || findtext(area_name, "village"))
		return "rockspring"
	
	if(findtext(area_name, "vault"))
		return "vault"
	
	return null

// Implementation of load_npc_barks (forward declared in hostile.dm)
// This is the canonical bark loading function used by both simple_animal and human NPCs
/proc/load_npc_barks(mob/living/simple_animal/hostile/npc)
	if(!npc || !npc.dialogue_type)
		return FALSE
	
	if(!GLOB.json_dialogue_cache.len)
		load_dialogue_files()
	
	var/dialogue_data = GLOB.json_dialogue_cache[npc.dialogue_type]
	if(!dialogue_data)
		return FALSE
	
	var/loaded = FALSE
	
	if(dialogue_data["barks"])
		var/list/barks = dialogue_data["barks"]
		if(barks["idle"])
			var/list/idle_barks = barks["idle"]
			npc.bark_strings = idle_barks.Copy()
			loaded = TRUE
		if(barks["combat"])
			var/list/combat_barks = barks["combat"]
			npc.bark_combat = combat_barks.Copy()
		if(barks["greeting"])
			var/list/greeting_barks = barks["greeting"]
			npc.bark_greeting = greeting_barks.Copy()
	
	if(dialogue_data["bark_chance"])
		npc.bark_chance = dialogue_data["bark_chance"]
	if(dialogue_data["bark_cooldown"])
		npc.bark_cooldown_time = dialogue_data["bark_cooldown"]
	if(dialogue_data["bark_range"])
		npc.bark_range = dialogue_data["bark_range"]
	
	return loaded

// Alias for backwards compatibility
/proc/load_barks_for_npc(mob/living/simple_animal/hostile/npc)
	return load_npc_barks(npc)
/proc/get_barks_for_dialogue_type(dialogue_type)
	if(!GLOB.json_dialogue_cache.len)
		load_dialogue_files()
	
	var/dialogue_data = GLOB.json_dialogue_cache[dialogue_type]
	if(!dialogue_data || !dialogue_data["barks"])
		return null
	
	return dialogue_data["barks"]
