/datum/tgui_character_setup
	var/client/owner
	var/datum/preferences/prefs
	var/current_tab = 0
	var/const/map_name = "character_preview_map"

/datum/tgui_character_setup/New(client/C)
	if(!istype(C))
		qdel(src)
		return
	owner = C
	prefs = C?.prefs
	if(!prefs)
		qdel(src)
		return

/datum/tgui_character_setup/Destroy()
	if(owner)
		owner.clear_character_previews()
	owner = null
	prefs = null
	return ..()

/datum/tgui_character_setup/ui_state(mob/user)
	return GLOB.always_state

/datum/tgui_character_setup/ui_close(mob/user)
	var/mob/dead/new_player/np = owner?.mob
	if(istype(np))
		addtimer(CALLBACK(np, TYPE_PROC_REF(/mob/dead/new_player, new_player_panel)), 1)

/datum/tgui_character_setup/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CharacterSetup")
		ui.open()
	update_preview()

/datum/tgui_character_setup/ui_data(mob/user)
	. = list()
	
	.["current_tab"] = current_tab
	.["mapRef"] = map_name
	
	// Identity
	.["real_name"] = prefs?.real_name || ""
	.["gender"] = prefs?.gender == MALE ? "male" : prefs?.gender == FEMALE ? "female" : "other"
	.["age"] = prefs?.age || 30
	.["species"] = prefs?.pref_species?.name || "Human"
	.["be_random_name"] = prefs?.be_random_name || FALSE
	.["be_random_body"] = prefs?.be_random_body || FALSE
	
	// SPECIAL
	.["special_remaining"] = get_special_remaining()
	.["special_strength"] = prefs?.special_s || 5
	.["special_perception"] = prefs?.special_p || 5
	.["special_endurance"] = prefs?.special_e || 5
	.["special_charisma"] = prefs?.special_c || 5
	.["special_intelligence"] = prefs?.special_i || 5
	.["special_agility"] = prefs?.special_a || 5
	.["special_luck"] = prefs?.special_l || 5
	
	// Jobs
	.["jobs"] = get_jobs()
	.["factions"] = get_factions()
	
	// Quirks
	.["quirks"] = prefs?.all_quirks || list()
	.["quirks_available"] = get_quirks_available()
	.["quirk_balance"] = get_quirk_balance()
	
	// Slots
	.["current_slot"] = prefs?.default_slot || 1
	.["slot_names"] = get_slot_names()
	.["max_slots"] = prefs?.max_save_slots || 30
	
	// Appearance
	.["hair_style"] = prefs?.hair_style || "Bald"
	.["hair_color"] = "#" + (prefs?.hair_color || "000000")
	.["facial_hair_style"] = prefs?.facial_hair_style || "Shaved"
	.["facial_hair_color"] = "#" + (prefs?.facial_hair_color || "000000")
	.["eye_color"] = "#" + (prefs?.left_eye_color || "000000")
	.["skin_tone"] = prefs?.skin_tone || "caucasian1"
	.["flavor_text"] = prefs?.features?["flavor_text"] || ""
	.["underwear"] = prefs?.underwear || "Nude"
	.["undershirt"] = prefs?.undershirt || "Nude"
	.["socks"] = prefs?.socks || "Nude"
	.["backpack"] = prefs?.backbag || "Backpack"
	
	// Lists
	.["species_list"] = get_species_list()
	.["hair_styles"] = get_hair_styles_list()
	.["facial_hair_styles"] = get_facial_hair_styles_list()
	.["skin_tones"] = get_skin_tones_list()
	.["underwear_list"] = get_underwear_list()
	.["undershirt_list"] = get_undershirt_list()
	.["socks_list"] = get_socks_list()
	
	// Game prefs
	.["ui_style"] = prefs?.UI_style || "Midnight"
	.["lobby_music"] = prefs?.toggles & SOUND_LOBBY
	.["ambience"] = prefs?.toggles & SOUND_AMBIENCE
	.["chat_on_map"] = prefs?.chat_on_map || FALSE
	.["hotkeys"] = prefs?.hotkeys || FALSE
	.["ghost_form"] = prefs?.ghost_form || "ghost"
	.["ghost_orbit"] = prefs?.ghost_orbit || "circle"
	.["ghost_forms"] = list("ghost", "ghost2", "ghostian")
	.["ghost_orbits"] = list("circle", "triangle", "square")
	
	// Loadout
	.["loadout_points"] = prefs?.gear_points || 12
	.["loadout_used"] = get_loadout_used()
	.["loadout_categories"] = get_loadout_categories()
	.["loadout_subcategories"] = get_loadout_subcategories()
	.["loadout_items"] = get_loadout_items()
	.["loadout_selected"] = get_loadout_selected()
	
	// Keybinds
	.["keybind_categories"] = get_keybind_categories()
	.["keybindings"] = get_keybindings()

/datum/tgui_character_setup/proc/get_list(list/L)
	if(!L)
		return list()
	return L.Copy()

/datum/tgui_character_setup/proc/get_species_list()
	. = list()
	if(GLOB.roundstart_race_names)
		for(var/name in GLOB.roundstart_race_names)
			. += name

/datum/tgui_character_setup/proc/get_hair_styles_list()
	. = list()
	if(GLOB.hair_styles_list)
		for(var/name in GLOB.hair_styles_list)
			. += name

/datum/tgui_character_setup/proc/get_facial_hair_styles_list()
	. = list()
	if(GLOB.facial_hair_styles_list)
		for(var/name in GLOB.facial_hair_styles_list)
			. += name

/datum/tgui_character_setup/proc/get_skin_tones_list()
	. = list()
	if(GLOB.skin_tones)
		for(var/name in GLOB.skin_tones)
			. += name

/datum/tgui_character_setup/proc/get_underwear_list()
	. = list()
	if(GLOB.underwear_list)
		for(var/name in GLOB.underwear_list)
			. += name

/datum/tgui_character_setup/proc/get_undershirt_list()
	. = list()
	if(GLOB.undershirt_list)
		for(var/name in GLOB.undershirt_list)
			. += name

/datum/tgui_character_setup/proc/get_socks_list()
	. = list()
	if(GLOB.socks_list)
		for(var/name in GLOB.socks_list)
			. += name

/datum/tgui_character_setup/proc/get_special_remaining()
	if(!prefs) return 5
	var/total = (prefs.special_s||5)+(prefs.special_p||5)+(prefs.special_e||5)+(prefs.special_c||5)+(prefs.special_i||5)+(prefs.special_a||5)+(prefs.special_l||5)
	return max(0, SPECIAL_MAX_POINT_SUM_CAP - total)

/datum/tgui_character_setup/proc/get_jobs()
	. = list()
	if(!SSjob) return .
	for(var/datum/job/job in SSjob.occupations)
		if(job.total_positions == 0 || job.faction == "None") continue
		var/pref
		switch(prefs?.job_preferences["[job.title]"])
			if(JP_HIGH) pref = "HIGH"
			if(JP_MEDIUM) pref = "MEDIUM"
			if(JP_LOW) pref = "LOW"
		. += list(list(
			"title" = job.title,
			"faction" = job.faction,
			"preference" = pref,
			"banned" = jobban_isbanned(owner?.mob, job.title),
		))

/datum/tgui_character_setup/proc/get_factions()
	. = list("All")
	if(!SSjob) return .
	var/list/seen = list()
	for(var/datum/job/job in SSjob.occupations)
		if(job.faction && job.faction != "None" && !(job.faction in seen))
			seen += job.faction
	return . + sortList(seen)

/datum/tgui_character_setup/proc/get_quirks_available()
	. = list()
	if(!SSquirks?.quirks) return .
	for(var/id in SSquirks.quirks)
		var/datum/quirk/Q = SSquirks.quirks[id]
		if(!Q) continue
		. += list(list(
			"id" = id,
			"name" = initial(Q.name),
			"desc" = initial(Q.desc),
			"value" = initial(Q.value),
		))

/datum/tgui_character_setup/proc/get_quirk_balance()
	if(!prefs || !SSquirks) return 5
	return SSquirks.total_points(prefs.all_quirks)

/datum/tgui_character_setup/proc/get_slot_names()
	. = list()
	if(!prefs?.path) return list("Slot 1", "Slot 2", "Slot 3")
	var/savefile/S = new(prefs.path)
	for(var/i in 1 to prefs.max_save_slots)
		S.cd = "/character[i]"
		var/name
		S["real_name"] >> name
		. += name || "Slot [i]"

/datum/tgui_character_setup/proc/get_loadout_used()
	if(!prefs?.loadout_data) return 0
	var/list/chosen = prefs.loadout_data["SAVE_[prefs.loadout_slot]"]
	if(!chosen) return 0
	var/total = 0
	for(var/item in chosen)
		var/datum/gear/gear = text2path(item[LOADOUT_ITEM])
		if(gear) total += initial(gear.cost)
	return total

/datum/tgui_character_setup/proc/get_loadout_categories()
	. = list()
	if(!GLOB.loadout_categories)
		return .
	for(var/cat in GLOB.loadout_categories)
		. += cat

/datum/tgui_character_setup/proc/get_loadout_subcategories()
	. = list()
	if(!GLOB.loadout_categories)
		return .
	for(var/cat in GLOB.loadout_categories)
		.[cat] = list()
		var/list/subcats = GLOB.loadout_categories[cat]
		if(subcats && subcats != LOADOUT_SUBCATEGORIES_NONE)
			for(var/sub in subcats)
				.[cat] += sub

/datum/tgui_character_setup/proc/get_loadout_items()
	. = list()
	if(!GLOB.loadout_items)
		return .
	for(var/cat in GLOB.loadout_items)
		.[cat] = list()
		for(var/sub in GLOB.loadout_items[cat])
			var/list/items = GLOB.loadout_items[cat][sub]
			if(!items || !items.len)
				continue
			.[cat][sub] = list()
			for(var/name in items)
				var/datum/gear/gear = items[name]
				if(!gear)
					continue
				.[cat][sub] += list(list(
					"name" = name,
					"path" = "[gear.type]",
					"cost" = gear.cost,
					"description" = gear.description || "",
				))

/datum/tgui_character_setup/proc/get_loadout_selected()
	. = list()
	if(!prefs?.loadout_data) return .
	var/list/chosen = prefs.loadout_data["SAVE_[prefs.loadout_slot]"]
	if(!chosen) return .
	for(var/item in chosen)
		. += item[LOADOUT_ITEM]

/datum/tgui_character_setup/proc/get_keybind_categories()
	. = list()
	if(!GLOB.keybindings_by_name) return .
	for(var/name in GLOB.keybindings_by_name)
		var/datum/keybinding/kb = GLOB.keybindings_by_name[name]
		if(kb?.category && !(kb.category in .))
			. += kb.category

/datum/tgui_character_setup/proc/get_keybindings()
	. = list()
	if(!GLOB.keybindings_by_name) return .
	for(var/name in GLOB.keybindings_by_name)
		var/datum/keybinding/kb = GLOB.keybindings_by_name[name]
		if(!kb?.category) continue
		if(!.[kb.category]) .[kb.category] = list()
		.[kb.category] += list(list(
			"name" = kb.name,
			"desc" = kb.description || "",
			"keys" = prefs?.key_bindings?[kb.name] || list(),
		))

/datum/tgui_character_setup/ui_act(action, params)
	if(..()) return TRUE
	
	switch(action)
		if("close")
			SStgui.close_uis(src)
			var/mob/dead/new_player/np = owner?.mob
			if(istype(np))
				np.new_player_panel()
			return TRUE
		
		if("set_tab")
			current_tab = text2num(params["tab"]) || 0
			update_preview()
		
		if("set_name")
			var/name = params["name"]
			if(name && length(name) >= 2 && length(name) <= 52)
				prefs.real_name = name
				update_preview()
		
		if("randomize_name")
			prefs.real_name = prefs.pref_species.random_name(prefs.gender)
			update_preview()
		
		if("set_gender")
			switch(params["gender"])
				if("male") prefs.gender = MALE
				if("female") prefs.gender = FEMALE
				if("other") prefs.gender = PLURAL
			update_preview()
		
		if("adjust_age")
			var/age = prefs.age + text2num(params["delta"])
			if(age >= 17 && age <= 80)
				prefs.age = age
		
		if("toggle_random_name")
			prefs.be_random_name = !prefs.be_random_name
		
		if("toggle_random_body")
			prefs.be_random_body = !prefs.be_random_body
			update_preview()
		
		if("randomize_body")
			prefs.random_character(prefs.gender)
			update_preview()
		
		if("adjust_special")
			var/stat = params["stat"]
			var/delta = text2num(params["delta"])
			var/current_total = (prefs.special_s||5)+(prefs.special_p||5)+(prefs.special_e||5)+(prefs.special_c||5)+(prefs.special_i||5)+(prefs.special_a||5)+(prefs.special_l||5)
			if(delta > 0 && current_total >= SPECIAL_MAX_POINT_SUM_CAP)
				return
			switch(stat)
				if("strength") prefs.special_s = clamp((prefs.special_s||5)+delta, 1, 10)
				if("perception") prefs.special_p = clamp((prefs.special_p||5)+delta, 1, 10)
				if("endurance") prefs.special_e = clamp((prefs.special_e||5)+delta, 1, 10)
				if("charisma") prefs.special_c = clamp((prefs.special_c||5)+delta, 1, 10)
				if("intelligence") prefs.special_i = clamp((prefs.special_i||5)+delta, 1, 10)
				if("agility") prefs.special_a = clamp((prefs.special_a||5)+delta, 1, 10)
				if("luck") prefs.special_l = clamp((prefs.special_l||5)+delta, 1, 10)
			update_preview()
		
		if("reset_special")
			prefs.special_s = prefs.special_p = prefs.special_e = prefs.special_c = prefs.special_i = prefs.special_a = prefs.special_l = 5
			update_preview()
		
		if("set_job_pref")
			var/job = params["job"]
			var/level = params["level"]
			switch(level)
				if("HIGH") prefs.job_preferences[job] = JP_HIGH
				if("MEDIUM") prefs.job_preferences[job] = JP_MEDIUM
				if("LOW") prefs.job_preferences[job] = JP_LOW
				if("NEVER") prefs.job_preferences -= job
			update_preview()
		
		if("toggle_quirk")
			var/quirk = params["quirk"]
			if(quirk in prefs.all_quirks)
				prefs.all_quirks -= quirk
			else
				prefs.all_quirks += quirk
			update_preview()
		
		if("select_slot")
			var/slot = text2num(params["slot"])
			if(slot >= 1 && slot <= prefs.max_save_slots)
				prefs.default_slot = slot
				prefs.load_character()
				update_preview()
		
		if("save_preferences")
			prefs.save_preferences()
			prefs.save_character()
		
		if("load_preferences")
			prefs.load_preferences()
			prefs.load_character()
			update_preview()
		
		if("set_species")
			var/species = params["species"]
			if(species in GLOB.roundstart_race_names)
				var/datum/species/S = GLOB.species_list[GLOB.roundstart_race_names[species]]
				if(S)
					prefs.pref_species = new S()
					update_preview()
		
		if("set_skin_tone")
			if(params["tone"] in GLOB.skin_tones)
				prefs.skin_tone = params["tone"]
				update_preview()
		
		if("set_hair_style")
			if(params["style"] in GLOB.hair_styles_list)
				prefs.hair_style = params["style"]
				update_preview()
		
		if("set_hair_color")
			prefs.hair_color = copytext(params["color"], 2)
			update_preview()
		
		if("set_facial_hair")
			if(params["style"] in GLOB.facial_hair_styles_list)
				prefs.facial_hair_style = params["style"]
				update_preview()
		
		if("set_facial_hair_color")
			prefs.facial_hair_color = copytext(params["color"], 2)
			update_preview()
		
		if("set_eye_color")
			prefs.left_eye_color = prefs.right_eye_color = copytext(params["color"], 2)
			update_preview()
		
		if("set_flavor_text")
			prefs.features["flavor_text"] = copytext(params["text"], 1, 501)
		
		if("set_underwear")
			if(params["style"] in GLOB.underwear_list)
				prefs.underwear = params["style"]
				update_preview()
		
		if("set_undershirt")
			if(params["style"] in GLOB.undershirt_list)
				prefs.undershirt = params["style"]
				update_preview()
		
		if("set_socks")
			if(params["style"] in GLOB.socks_list)
				prefs.socks = params["style"]
				update_preview()
		
		if("set_backpack")
			prefs.backbag = params["style"]
		
		if("set_ui_style")
			prefs.UI_style = params["style"]
		
		if("toggle_lobby_music")
			prefs.toggles ^= SOUND_LOBBY
		
		if("toggle_ambience")
			prefs.toggles ^= SOUND_AMBIENCE
		
		if("toggle_chat_on_map")
			prefs.chat_on_map = !prefs.chat_on_map
		
		if("toggle_hotkeys")
			prefs.hotkeys = !prefs.hotkeys
		
		if("set_ghost_form")
			prefs.ghost_form = params["form"]
		
		if("set_ghost_orbit")
			prefs.ghost_orbit = params["orbit"]
		
		if("toggle_loadout_item")
			var/path = params["path"]
			var/list/chosen = prefs.loadout_data["SAVE_[prefs.loadout_slot]"]
			if(!chosen)
				chosen = list()
				prefs.loadout_data["SAVE_[prefs.loadout_slot]"] = chosen
			var/found = FALSE
			for(var/i = chosen.len to 1 step -1)
				if(chosen[i][LOADOUT_ITEM] == path)
					chosen.Cut(i, i+1)
					found = TRUE
			if(!found)
				chosen += list(list(LOADOUT_ITEM = path))
			update_preview()
		
		if("clear_loadout")
			prefs.loadout_data["SAVE_[prefs.loadout_slot]"] = list()
			update_preview()
		
		if("capture_keybind")
			var/name = params["name"]
			if(name && owner)
				var/datum/keybinding/kb = GLOB.keybindings_by_name[name]
				if(kb)
					prefs.CaptureKeybinding(owner.mob, kb, text2num(params["index"]))
		
		if("reset_keybinds")
			prefs.key_bindings = list()
			for(var/name in GLOB.keybindings_by_name)
				var/datum/keybinding/kb = GLOB.keybindings_by_name[name]
				if(kb?.hotkey_keys)
					prefs.key_bindings[name] = kb.hotkey_keys.Copy()
		
		if("open_flavor_editor")
			var/datum/flavor_text_editor/editor = new(src)
			editor.ui_interact(owner?.mob)
	
	return TRUE

/datum/flavor_text_editor
	var/datum/tgui_character_setup/parent

/datum/flavor_text_editor/New(datum/tgui_character_setup/parent)
	src.parent = parent

/datum/flavor_text_editor/Destroy()
	parent = null
	return ..()

/datum/flavor_text_editor/ui_state(mob/user)
	return GLOB.always_state

/datum/flavor_text_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FlavorTextEditor")
		ui.open()

/datum/flavor_text_editor/ui_data(mob/user)
	var/list/data = list()
	data["flavor_text"] = parent?.prefs?.features?["flavor_text"] || ""
	return data

/datum/flavor_text_editor/ui_act(action, params)
	if(..())
		return TRUE
	switch(action)
		if("set_flavor_text")
			parent?.prefs?.features["flavor_text"] = copytext(params["text"], 1, 2001)
			return TRUE
		if("close")
			SStgui.close_uis(src)
			return TRUE
	return FALSE

/datum/tgui_character_setup/proc/update_preview()
	if(!prefs || !owner)
		return
	
	var/mob/living/carbon/human/dummy/mannequin = generate_or_wait_for_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
	mannequin.cut_overlays()
	
	for(var/obj/item/I in mannequin.get_all_gear())
		mannequin.dropItemToGround(I, TRUE)
		qdel(I)
	mannequin.delete_equipment()
	
	mannequin.add_overlay(mutable_appearance('fallout/icons/ui/backgrounds.dmi', "traitor", layer = SPACE_LAYER))
	
	var/equip_job = TRUE
	switch(current_tab)
		if(APPEARANCE_TAB)
			equip_job = FALSE
	
	prefs.copy_to(mannequin, initial_spawn = TRUE)
	
	var/datum/job/previewJob = prefs.get_highest_job()
	if(previewJob && equip_job)
		if(istype(previewJob, /datum/job/ai))
			owner.show_character_previews(image('icons/mob/ai.dmi', icon_state = resolve_ai_icon(prefs.preferred_ai_core_display), dir = SOUTH))
			unset_busy_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
			return
		if(istype(previewJob, /datum/job/cyborg))
			owner.show_character_previews(image('icons/mob/robots.dmi', icon_state = "robot", dir = SOUTH))
			unset_busy_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
			return
		mannequin.job = previewJob.title
		previewJob.equip(mannequin, TRUE, preference_source = owner)
	
	mannequin.regenerate_icons()
	COMPILE_OVERLAYS(mannequin)
	
	owner.show_character_previews(new /mutable_appearance(mannequin))
	unset_busy_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
