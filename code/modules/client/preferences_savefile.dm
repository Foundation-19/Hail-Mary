//This is the lowest supported version, anything below this is completely obsolete and the entire savefile will be wiped.
#define SAVEFILE_VERSION_MIN	37

//This is the current version, anything below this will attempt to update (if it's not obsolete)
//	You do not need to raise this if you are adding new values that have sane defaults.
//	Only raise this value when changing the meaning/format/name/layout of an existing value
//	where you would want the updater procs below to run
#define SAVEFILE_VERSION_MAX	52

/*
SAVEFILE UPDATING/VERSIONING - 'Simplified', or rather, more coder-friendly ~Carn
	This proc checks if the current directory of the savefile S needs updating
	It is to be used by the load_character and load_preferences procs.
	(S.cd=="/" is preferences, S.cd=="/character[integer]" is a character slot, etc)

	if the current directory's version is below SAVEFILE_VERSION_MIN it will simply wipe everything in that directory
	(if we're at root "/" then it'll just wipe the entire savefile, for instance.)

	if its version is below SAVEFILE_VERSION_MAX but above the minimum, it will load data but later call the
	respective update_preferences() or update_character() proc.
	Those procs allow coders to specify format changes so users do not lose their setups and have to redo them again.

	Failing all that, the standard sanity checks are performed. They simply check the data is suitable, reverting to
	initial() values if necessary.
*/
/datum/preferences/proc/savefile_needs_update(savefile/S)
	var/savefile_version
	S["version"] >> savefile_version

	if(savefile_version < SAVEFILE_VERSION_MIN)
		S.dir.Cut()
		return -2
	if(savefile_version < SAVEFILE_VERSION_MAX)
		return savefile_version
	return -1

//should these procs get fairly long
//just increase SAVEFILE_VERSION_MIN so it's not as far behind
//SAVEFILE_VERSION_MAX and then delete any obsolete if clauses
//from these procs.
//This only really meant to avoid annoying frequent players
//if your savefile is 3 months out of date, then 'tough shit'.


/datum/preferences/proc/update_preferences(current_version, savefile/S)
	if(current_version < 37)	//If you remove this, remove force_reset_keybindings() too.
		force_reset_keybindings_direct(TRUE)
		addtimer(CALLBACK(src, PROC_REF(force_reset_keybindings)), 30)	//No mob available when this is run, timer allows user choice.


/datum/preferences/proc/update_character(current_version, savefile/S)
	if(current_version < 38)
		UI_style = GLOB.available_ui_styles[1] // Force the Fallout UI once.

	if(current_version < 47) //loadout save gets changed to json
		var/text_to_load
		S["loadout"] >> text_to_load
		var/list/saved_loadout_paths = splittext(text_to_load, "|")
		//MAXIMUM_LOADOUT_SAVES save slots per loadout now
		for(var/i=1, i<= MAXIMUM_LOADOUT_SAVES, i++)
			loadout_data["SAVE_[i]"] = list()
		for(var/some_gear_item in saved_loadout_paths)
			if(!ispath(text2path(some_gear_item)))
				log_game("Failed to copy item [some_gear_item] to new loadout system when migrating from version [current_version] to 40, issue: item is not a path")
				continue
			var/datum/gear/gear_item = text2path(some_gear_item)
			if(!(initial(gear_item.loadout_flags)))	//removed the can color polychrom since it's not ported
				loadout_data["SAVE_1"] += list(list(LOADOUT_ITEM = some_gear_item)) //for the migration we put their old save into the first save slot, which is loaded by default!
			else
				//the same but we setup some new polychromic data (you can't get the initial value for a list so we have to do this horrible thing here)
				var/datum/gear/temporary_gear_item = new gear_item
				loadout_data["SAVE_1"] += list(list(LOADOUT_ITEM = some_gear_item))	//removed loadout color because not porting polychrom
				qdel(temporary_gear_item)
			//it's double packed into a list because += will union the two lists contents

		S["loadout"] = safe_json_encode(loadout_data)

	if(current_version < 43) //extreme changes to how things are coloured (the introduction of the advanced coloring system)
		features["color_scheme"] = OLD_CHARACTER_COLORING //disable advanced coloring system by default
		for(var/feature in features)
			var/feature_value = features[feature]
			if(feature_value)
				var/ref_list = GLOB.mutant_reference_list[feature]
				if(ref_list)
					var/datum/sprite_accessory/accessory = ref_list[feature_value]
					if(accessory)
						if(accessory.color_src == MATRIXED && !accessory.matrixed_sections && feature_value != "None")
							message_admins("Sprite Accessory Failure (migration from [current_version] to 39): Accessory [accessory.type] is a matrixed item without any matrixed sections set!")
							continue

		features["color_scheme"] = OLD_CHARACTER_COLORING //advanced is off by default


	if(current_version < 38) //further eye sprite changes
		if(S["species"] == "plasmaman")
			left_eye_color = "#FFC90E"
			right_eye_color = "#FFC90E"
		else
			if(S["species"] == "skeleton")
				left_eye_color = "#BAB99E"
				right_eye_color = "#BAB99E"

	if(current_version < 51) //humans can have digi legs now, make sure they dont default to them or human players will murder me in my sleep
		if(S["species"] == "human")
			features["legs"] = "Plantigrade"



/datum/preferences/proc/load_path(ckey,filename="preferences.sav")
	if(!ckey)
		return
	path = "data/player_saves/[ckey[1]]/[ckey]/[filename]"
	vr_path = "data/player_saves/[ckey[1]]/[ckey]/vore"
	// TODO: Make bellies save/load to/from a human readable format
	// Shouldnt be too hard to convert the current savefile format to json or txt or something
	// Hopefully everyone's bellies dont get fucked when I do that!

/datum/preferences/proc/load_preferences()
	if(!path)
		return FALSE
	if(world.time < loadprefcooldown)
		if(istype(parent))
			to_chat(parent, span_warning("You're attempting to load your preferences a little too fast. Wait half a second, then try again."))
		return FALSE
	loadprefcooldown = world.time + PREF_SAVELOAD_COOLDOWN
	if(!fexists(path))
		return FALSE

	var/savefile/S = new /savefile(path)
	if(!S)
		return FALSE
	S.cd = "/"

	var/needs_update = savefile_needs_update(S)
	if(needs_update == -2)		//fatal, can't load any data
		var/bacpath = "[path].updatebac" //todo: if the savefile version is higher then the server, check the backup, and give the player a prompt to load the backup
		if (fexists(bacpath))
			fdel(bacpath) //only keep 1 version of backup
		fcopy(S, bacpath) //byond helpfully lets you use a savefile for the first arg.
		return FALSE

	. = TRUE

	//general preferences
	S["ooccolor"]			>> ooccolor
	S["lastchangelog"]		>> lastchangelog
	S["UI_style"]			>> UI_style
	S["hotkeys"]			>> hotkeys
	S["chat_on_map"]		>> chat_on_map
	S["max_chat_length"]	>> max_chat_length
	S["see_chat_non_mob"]	>> see_chat_non_mob
	READ_FILE(S["see_rc_emotes"] , see_rc_emotes)
	S["tgui_fancy"]			>> tgui_fancy
	S["tgui_lock"]			>> tgui_lock
	S["buttons_locked"]		>> buttons_locked
	S["windowflash"]		>> windowflashing
	S["be_special"] 		>> be_special


	S["default_slot"]		>> default_slot
	S["chat_toggles"]		>> chat_toggles
	S["cb_toggles"]			>> cb_toggles
	S["toggles"]			>> toggles
	S["ghost_form"]			>> ghost_form
	S["ghost_orbit"]		>> ghost_orbit
	S["ghost_accs"]			>> ghost_accs
	S["ghost_others"]		>> ghost_others
	S["preferred_map"]		>> preferred_map
	S["ignoring"]			>> ignoring
	S["ghost_hud"]			>> ghost_hud
	S["inquisitive_ghost"]	>> inquisitive_ghost
	S["uses_glasses_colour"]>> uses_glasses_colour
	S["clientfps"]			>> clientfps
	S["parallax"]			>> parallax
	S["ambientocclusion"]	>> ambientocclusion
	S["auto_fit_viewport"]	>> auto_fit_viewport
	S["hud_toggle_flash"]	>> hud_toggle_flash
	S["hud_toggle_color"]	>> hud_toggle_color
	S["menuoptions"]		>> menuoptions
	S["enable_tips"]		>> enable_tips
	S["tip_delay"]			>> tip_delay
	S["pda_style"]			>> pda_style
	S["pda_color"]			>> pda_color
	S["pda_skin"]			>> pda_skin

	// Custom hotkeys
	S["key_bindings"]		>> key_bindings
	S["modless_key_bindings"]		>> modless_key_bindings

	//citadel code
	S["arousable"]			>> arousable
	S["screenshake"]		>> screenshake
	S["damagescreenshake"]	>> damagescreenshake
	S["widescreenpref"]		>> widescreenpref
	S["end_of_round_deathmatch"] >> end_of_round_deathmatch
	READ_FILE(S["matchmaking_prefs"], matchmaking_prefs)
	S["autostand"]			>> autostand
	S["cit_toggles"]		>> cit_toggles
	S["preferred_chaos"]	>> preferred_chaos
	S["auto_ooc"]			>> auto_ooc
	S["no_tetris_storage"]		>> no_tetris_storage

	chat_toggles |= CHAT_LOOC // the LOOC doesn't stop
	//try to fix any outdated data if necessary
	if(needs_update >= 0)
		var/bacpath = "[path].updatebac" //todo: if the savefile version is higher then the server, check the backup, and give the player a prompt to load the backup
		if (fexists(bacpath))
			fdel(bacpath) //only keep 1 version of backup
		fcopy(S, bacpath) //byond helpfully lets you use a savefile for the first arg.
		update_preferences(needs_update, S)		//needs_update = savefile_version if we need an update (positive integer)



	//Sanitize
	ooccolor		= sanitize_ooccolor(sanitize_hexcolor(ooccolor, 6, 1, initial(ooccolor)))
	lastchangelog	= sanitize_text(lastchangelog, initial(lastchangelog))
	UI_style		= sanitize_inlist(UI_style, GLOB.available_ui_styles, GLOB.available_ui_styles[1])
	hotkeys			= sanitize_integer(hotkeys, 0, 1, initial(hotkeys))
	chat_on_map		= sanitize_integer(chat_on_map, 0, 1, initial(chat_on_map))
	max_chat_length = sanitize_integer(max_chat_length, 1, CHAT_MESSAGE_MAX_LENGTH, initial(max_chat_length))
	see_chat_non_mob	= sanitize_integer(see_chat_non_mob, 0, 1, initial(see_chat_non_mob))
	see_rc_emotes = sanitize_integer(see_rc_emotes, FALSE, TRUE, initial(see_rc_emotes))
	tgui_fancy		= sanitize_integer(tgui_fancy, 0, 1, initial(tgui_fancy))
	tgui_lock		= sanitize_integer(tgui_lock, 0, 1, initial(tgui_lock))
	buttons_locked	= sanitize_integer(buttons_locked, 0, 1, initial(buttons_locked))
	windowflashing		= sanitize_integer(windowflashing, 0, 1, initial(windowflashing))
	default_slot	= sanitize_integer(default_slot, 1, max_save_slots, initial(default_slot))
	toggles			= sanitize_integer(toggles, 0, 16777215, initial(toggles))
	cb_toggles			= sanitize_integer(cb_toggles, 0, 16777215, initial(cb_toggles))
	clientfps		= sanitize_integer(clientfps, 0, 1000, 0)
	parallax		= sanitize_integer(parallax, PARALLAX_INSANE, PARALLAX_DISABLE, null)
	ambientocclusion	= sanitize_integer(ambientocclusion, 0, 1, initial(ambientocclusion))
	auto_fit_viewport	= sanitize_integer(auto_fit_viewport, 0, 1, initial(auto_fit_viewport))
	hud_toggle_flash = sanitize_integer(hud_toggle_flash, 0, 1, initial(hud_toggle_flash))
	hud_toggle_color = sanitize_hexcolor(hud_toggle_color, 6, 1, initial(hud_toggle_color))
	ghost_form		= sanitize_inlist(ghost_form, GLOB.ghost_forms, initial(ghost_form))
	ghost_orbit 	= sanitize_inlist(ghost_orbit, GLOB.ghost_orbits, initial(ghost_orbit))
	ghost_accs		= sanitize_inlist(ghost_accs, GLOB.ghost_accs_options, GHOST_ACCS_DEFAULT_OPTION)
	ghost_others	= sanitize_inlist(ghost_others, GLOB.ghost_others_options, GHOST_OTHERS_DEFAULT_OPTION)
	menuoptions		= SANITIZE_LIST(menuoptions)
	be_special		= SANITIZE_LIST(be_special)
	pda_style		= sanitize_inlist(pda_style, GLOB.pda_styles, initial(pda_style))
	pda_color		= sanitize_hexcolor(pda_color, 6, 1, initial(pda_color))
	pda_skin		= sanitize_inlist(pda_skin, GLOB.pda_reskins, PDA_SKIN_CLASSIC)
	screenshake			= sanitize_integer(screenshake, 0, 800, initial(screenshake))
	damagescreenshake	= sanitize_integer(damagescreenshake, 0, 2, initial(damagescreenshake))
	widescreenpref		= sanitize_integer(widescreenpref, 0, 1, initial(widescreenpref))
	end_of_round_deathmatch = sanitize_integer(end_of_round_deathmatch, FALSE, TRUE, initial(end_of_round_deathmatch))
	autostand			= sanitize_integer(autostand, 0, 1, initial(autostand))
	cit_toggles			= sanitize_integer(cit_toggles, 0, 16777215, initial(cit_toggles))
	auto_ooc			= sanitize_integer(auto_ooc, 0, 1, initial(auto_ooc))
	no_tetris_storage		= sanitize_integer(no_tetris_storage, 0, 1, initial(no_tetris_storage))
	key_bindings 			= sanitize_islist(key_bindings, list())
	modless_key_bindings 	= sanitize_islist(modless_key_bindings, list())

	verify_keybindings_valid()		// one of these days this will runtime and you'll be glad that i put it in a different proc so no one gets their saves wiped

	if(needs_update >= 0) //save the updated version
		var/old_default_slot = default_slot
		var/old_max_save_slots = max_save_slots

		for (var/slot in S.dir) //but first, update all current character slots.
			if (copytext(slot, 1, 10) != "character")
				continue
			var/slotnum = text2num(copytext(slot, 10))
			if (!slotnum)
				continue
			max_save_slots = max(max_save_slots, slotnum) //so we can still update byond member slots after they lose memeber status
			default_slot = slotnum
			if (load_character()) // this updtates char slots
				save_character()
		default_slot = old_default_slot
		max_save_slots = old_max_save_slots
		save_preferences()

	return TRUE

/datum/preferences/proc/verify_keybindings_valid()
	// Sanitize the actual keybinds to make sure they exist.
	for(var/key in key_bindings)
		if(!islist(key_bindings[key]))
			key_bindings -= key
		var/list/binds = key_bindings[key]
		for(var/bind in binds)
			if(!GLOB.keybindings_by_name[bind])
				binds -= bind
		if(!length(binds))
			key_bindings -= key
	// End
	// I hate copypaste but let's do it again but for modless ones
	for(var/key in modless_key_bindings)
		var/bindname = modless_key_bindings[key]
		if(!GLOB.keybindings_by_name[bindname])
			modless_key_bindings -= key

/datum/preferences/proc/save_preferences()
	if(!path)
		return 0
	if(world.time < saveprefcooldown)
		if(istype(parent))
			to_chat(parent, span_warning("You're attempting to save your preferences a little too fast. Wait half a second, then try again."))
		return 0
	saveprefcooldown = world.time + PREF_SAVELOAD_COOLDOWN
	var/savefile/S = new /savefile(path)
	if(!S)
		return 0
	S.cd = "/"

	WRITE_FILE(S["version"] , SAVEFILE_VERSION_MAX)		//updates (or failing that the sanity checks) will ensure data is not invalid at load. Assume up-to-date

	//general preferences
	WRITE_FILE(S["ooccolor"], ooccolor)
	WRITE_FILE(S["lastchangelog"], lastchangelog)
	WRITE_FILE(S["UI_style"], UI_style)
	WRITE_FILE(S["hotkeys"], hotkeys)
	WRITE_FILE(S["chat_on_map"], chat_on_map)
	WRITE_FILE(S["max_chat_length"], max_chat_length)
	WRITE_FILE(S["see_chat_non_mob"], see_chat_non_mob)
	WRITE_FILE(S["see_rc_emotes"], see_rc_emotes)
	WRITE_FILE(S["tgui_fancy"], tgui_fancy)
	WRITE_FILE(S["tgui_lock"], tgui_lock)
	WRITE_FILE(S["buttons_locked"], buttons_locked)
	WRITE_FILE(S["windowflash"], windowflashing)
	WRITE_FILE(S["be_special"], be_special)
	WRITE_FILE(S["default_slot"], default_slot)
	WRITE_FILE(S["toggles"], toggles)
	WRITE_FILE(S["cb_toggles"], cb_toggles)
	WRITE_FILE(S["chat_toggles"], chat_toggles)
	WRITE_FILE(S["ghost_form"], ghost_form)
	WRITE_FILE(S["ghost_orbit"], ghost_orbit)
	WRITE_FILE(S["ghost_accs"], ghost_accs)
	WRITE_FILE(S["ghost_others"], ghost_others)
	WRITE_FILE(S["preferred_map"], preferred_map)
	WRITE_FILE(S["ignoring"], ignoring)
	WRITE_FILE(S["ghost_hud"], ghost_hud)
	WRITE_FILE(S["inquisitive_ghost"], inquisitive_ghost)
	WRITE_FILE(S["uses_glasses_colour"], uses_glasses_colour)
	WRITE_FILE(S["clientfps"], clientfps)
	WRITE_FILE(S["parallax"], parallax)
	WRITE_FILE(S["ambientocclusion"], ambientocclusion)
	WRITE_FILE(S["auto_fit_viewport"], auto_fit_viewport)
	WRITE_FILE(S["hud_toggle_flash"], hud_toggle_flash)
	WRITE_FILE(S["hud_toggle_color"], hud_toggle_color)
	WRITE_FILE(S["menuoptions"], menuoptions)
	WRITE_FILE(S["enable_tips"], enable_tips)
	WRITE_FILE(S["tip_delay"], tip_delay)
	WRITE_FILE(S["pda_style"], pda_style)
	WRITE_FILE(S["pda_color"], pda_color)
	WRITE_FILE(S["pda_skin"], pda_skin)
	WRITE_FILE(S["key_bindings"], key_bindings)
	WRITE_FILE(S["modless_key_bindings"], modless_key_bindings)

	//citadel code
	WRITE_FILE(S["screenshake"], screenshake)
	WRITE_FILE(S["damagescreenshake"], damagescreenshake)
	WRITE_FILE(S["arousable"], arousable)
	WRITE_FILE(S["widescreenpref"], widescreenpref)
	WRITE_FILE(S["end_of_round_deathmatch"], end_of_round_deathmatch)
	WRITE_FILE(S["autostand"], autostand)
	WRITE_FILE(S["cit_toggles"], cit_toggles)
	WRITE_FILE(S["preferred_chaos"], preferred_chaos)
	WRITE_FILE(S["auto_ooc"], auto_ooc)
	WRITE_FILE(S["no_tetris_storage"], no_tetris_storage)
	return 1

/datum/preferences/proc/load_character(slot)
	if(!path)
		return FALSE
	if(world.time < loadcharcooldown) //This is before the check to see if the filepath exists to ensure that BYOND can't get hung up on read attempts when the hard drive is a little slow
		if(istype(parent))
			to_chat(parent, span_warning("You're attempting to load your character a little too fast. Wait half a second, then try again."))
		return "SLOW THE FUCK DOWN" //the reason this isn't null is to make sure that people don't have their character slots overridden by random chars if they accidentally double-click a slot
	loadcharcooldown = world.time + PREF_SAVELOAD_COOLDOWN
	if(!fexists(path))
		return FALSE
	var/savefile/S = new /savefile(path)
	if(!S)
		return FALSE
	features = list(
		"mcolor" = "FFFFFF",
		"mcolor2" = "FFFFFF",
		"mcolor3" = "FFFFFF",

		"legs" = "Plantigrade",
		"ipc_screen" = "Sunburst",
		"ipc_antenna" = "None",
		"flavor_text" = "",
		"silicon_flavor_text" = "",

		"ooc_notes" = OOC_NOTE_TEMPLATE,
		"body_model" = MALE,
		"body_size" = RESIZE_DEFAULT_SIZE,
		"color_scheme" = OLD_CHARACTER_COLORING,
		"chat_color" = "whoopsie")

	S.cd = "/"
	if(!slot)
		slot = default_slot
	slot = sanitize_integer(slot, 1, max_save_slots, initial(default_slot))
	if(slot != default_slot)
		default_slot = slot
		WRITE_FILE(S["default_slot"] , slot)

	S.cd = "/character[slot]"
	var/needs_update = savefile_needs_update(S)
	if(needs_update == -2)		//fatal, can't load any data
		return FALSE

	. = TRUE

	//Species
	var/species_id
	S["species"]			>> species_id
	if(species_id) // for ass-backwards compatability
		switch(species_id)
			if("avian", "aquatic")
				species_id = "mammal"
			if("moth")
				species_id = "insect"
			if("synthanthro")
				species_id = "synthliz"

		var/newtype = GLOB.species_list[species_id]
		if(newtype)
			pref_species = new newtype


	scars_index = rand(1,5) // WHY

	//Character
	S["real_name"]				>> real_name
	S["custom_species"]			>> custom_species
	S["name_is_always_random"]	>> be_random_name
	S["body_is_always_random"]	>> be_random_body
	S["gender"]					>> gender
	S["body_model"]				>> features["body_model"]
	S["body_size"]				>> features["body_size"]
	S["age"]					>> age
	S["hair_color"]				>> hair_color
	S["facial_hair_color"]		>> facial_hair_color
	S["eye_type"]				>> eye_type
	S["left_eye_color"]			>> left_eye_color
	S["right_eye_color"]		>> right_eye_color
	S["use_custom_skin_tone"]	>> use_custom_skin_tone
	S["skin_tone"]				>> skin_tone
	S["hair_style_name"]		>> hair_style
	S["facial_style_name"]		>> facial_hair_style
	S["underwear"]				>> underwear
	S["undie_color"]			>> undie_color
	S["undershirt"]				>> undershirt
	S["shirt_color"]			>> shirt_color
	S["socks"]					>> socks
	S["socks_color"]			>> socks_color
	S["backbag"]				>> backbag
	S["jumpsuit_style"]			>> jumpsuit_style
	S["uplink_loc"]				>> uplink_spawn_loc
	S["custom_speech_verb"]		>> custom_speech_verb
	S["custom_tongue"]			>> custom_tongue
	S["feature_mcolor"]					>> features["mcolor"]
	S["feature_chat_color"]				>> features["chat_color"]
	S["persistent_scars"] 				>> persistent_scars
	S["scars1"]							>> scars_list["1"]
	S["scars2"]							>> scars_list["2"]
	S["scars3"]							>> scars_list["3"]
	S["scars4"]							>> scars_list["4"]
	S["scars5"]							>> scars_list["5"]
	var/limbmodstr
	S["modified_limbs"] >> limbmodstr
	if(length(limbmodstr))
		modified_limbs = safe_json_decode(limbmodstr)
	else
		modified_limbs = list()
	S["chosen_limb_id"]					>> chosen_limb_id
	S["hide_ckey"]						>> hide_ckey //saved per-character

	//Custom names
	for(var/custom_name_id in GLOB.preferences_custom_names)
		var/savefile_slot_name = custom_name_id + "_name" //TODO remove this
		S[savefile_slot_name] >> custom_names[custom_name_id]

	S["preferred_ai_core_display"]		>> preferred_ai_core_display
	S["prefered_security_department"]	>> prefered_security_department

	//Jobs
	S["joblessrole"]		>> joblessrole

	//Load prefs
	S["job_preferences"]	>> job_preferences

	//Quirks
	S["all_quirks"]			>> all_quirks

	//Records
	S["security_records"]			>>			security_records
	S["medical_records"]			>>			medical_records

	//Citadel code
	S["feature_mcolor2"]				>> features["mcolor2"]
	S["feature_mcolor3"]				>> features["mcolor3"]
	// note safe json decode will runtime the first time it migrates but this is fine and it solves itself don't worry about it if you see it error
	features["mam_body_markings"] = safe_json_decode(S["feature_mam_body_markings"])

	//flavor text
	//Let's make our players NOT cry desperately as we wipe their savefiles of their special snowflake texts:
	if((S["flavor_text"] != "") && (S["flavor_text"] != null) && S["flavor_text"]) //If old text isn't null and isn't "" but still exists.
		S["flavor_text"]				>> features["flavor_text"] //Load old flavortext as current dna-based flavortext

		WRITE_FILE(S["feature_flavor_text"], features["flavor_text"]) //Save it in our new type of flavor-text
		WRITE_FILE(S["flavor_text"]	, "") //Remove old flavortext, completing the cut-and-paste into the new format.

	else //We have no old flavortext, default to new
		S["feature_flavor_text"]		>> features["flavor_text"]


	S["silicon_feature_flavor_text"]		>> features["silicon_flavor_text"]

	S["feature_ooc_notes"]				>> features["ooc_notes"]
	S["silicon_flavor_text"] >> features["silicon_flavor_text"]

	//gear loadout
	if(S["loadout"])
		loadout_data = safe_json_decode(S["loadout"])
	else
		loadout_data = list()
	//special
	S["special_s"]			>> special_s
	S["special_p"]			>> special_p
	S["special_e"]			>> special_e
	S["special_c"]			>> special_c
	S["special_i"]			>> special_i
	S["special_a"]			>> special_a
	S["special_l"]			>> special_l

	READ_FILE(S["matchmaking_prefs"], matchmaking_prefs)

	// !! COYOTE SAVE FILE STUFF !!
	S["profilePicture"] >> profilePicture // Profile picklies

	S["gradient_color"]		>> features_override["grad_color"] // Hair gradients!
	S["gradient_style"]		>> features_override["grad_style"] // Hair gradients electric boogaloo 2!!

	//try to fix any outdated data if necessary
	//preference updating will handle saving the updated data for us.
	if(needs_update >= 0)
		update_character(needs_update, S)		//needs_update == savefile_version if we need an update (positive integer)

	//Sanitize

	real_name	= reject_bad_name(real_name)
	gender		= sanitize_gender(gender, TRUE, TRUE)
	features["body_model"] = sanitize_gender(features["body_model"], FALSE, FALSE, gender == FEMALE ? FEMALE : MALE)
	if(!real_name)
		real_name	= random_unique_name(gender)
	custom_species	= reject_bad_name(custom_species)
	for(var/custom_name_id in GLOB.preferences_custom_names)
		var/namedata = GLOB.preferences_custom_names[custom_name_id]
		custom_names[custom_name_id] = reject_bad_name(custom_names[custom_name_id],namedata["allow_numbers"])
		if(!custom_names[custom_name_id])
			custom_names[custom_name_id] = get_default_name(custom_name_id)

	be_random_name	= sanitize_integer(be_random_name, 0, 1, initial(be_random_name))
	be_random_body	= sanitize_integer(be_random_body, 0, 1, initial(be_random_body))

	hair_style					= sanitize_inlist(hair_style, GLOB.hair_styles_list)
	facial_hair_style			= sanitize_inlist(facial_hair_style, GLOB.facial_hair_styles_list)
	underwear					= sanitize_inlist(underwear, GLOB.underwear_list)
	undershirt 					= sanitize_inlist(undershirt, GLOB.undershirt_list)
	undie_color						= sanitize_hexcolor(undie_color, 6, FALSE, initial(undie_color))
	shirt_color						= sanitize_hexcolor(shirt_color, 6, FALSE, initial(shirt_color))
	socks							= sanitize_inlist(socks, GLOB.socks_list)
	socks_color						= sanitize_hexcolor(socks_color, 6, FALSE, initial(socks_color))
	age								= sanitize_integer(age, AGE_MIN, AGE_MAX, initial(age))
	special_s		= sanitize_integer(special_s, 1, 10, initial(special_s))
	special_p		= sanitize_integer(special_p, 1, 10, initial(special_p))
	special_e		= sanitize_integer(special_e, 1, 10, initial(special_e))
	special_c		= sanitize_integer(special_c, 1, 10, initial(special_c))
	special_i		= sanitize_integer(special_i, 1, 10, initial(special_i))
	special_a		= sanitize_integer(special_a, 1, 10, initial(special_a))
	special_l		= sanitize_integer(special_l, 1, 10, initial(special_l))

	hair_color						= sanitize_hexcolor(hair_color, 6, FALSE)
	facial_hair_color				= sanitize_hexcolor(facial_hair_color, 6, FALSE)
	eye_type						= sanitize_inlist(eye_type, GLOB.eye_types, DEFAULT_EYES_TYPE)
	left_eye_color					= sanitize_hexcolor(left_eye_color, 6, FALSE)
	right_eye_color					= sanitize_hexcolor(right_eye_color, 6, FALSE)

	var/static/allow_custom_skintones
	if(isnull(allow_custom_skintones))
		allow_custom_skintones = CONFIG_GET(flag/allow_custom_skintones)
	use_custom_skin_tone			= allow_custom_skintones ? sanitize_integer(use_custom_skin_tone, FALSE, TRUE, initial(use_custom_skin_tone)) : FALSE
	if(use_custom_skin_tone)
		skin_tone					= sanitize_hexcolor(skin_tone, 6, TRUE, "#FFFFFF")
	else
		skin_tone					= sanitize_inlist(skin_tone, GLOB.skin_tones - GLOB.nonstandard_skin_tones, initial(skin_tone))

	features["horns_color"]			= sanitize_hexcolor(features["horns_color"], 6, FALSE, "85615a")
	features["wings_color"]			= sanitize_hexcolor(features["wings_color"], 6, FALSE, "FFFFFF")
	backbag							= sanitize_inlist(backbag, GLOB.backbaglist, initial(backbag))
	jumpsuit_style					= sanitize_inlist(jumpsuit_style, GLOB.jumpsuitlist, initial(jumpsuit_style))
	uplink_spawn_loc				= sanitize_inlist(uplink_spawn_loc, GLOB.uplink_spawn_loc_list, initial(uplink_spawn_loc))
	features["mcolor"]				= sanitize_hexcolor(features["mcolor"], 6, FALSE)

	var/static/size_min
	if(!size_min)
		size_min = CONFIG_GET(number/body_size_min)
	var/static/size_max
	if(!size_max)
		size_max = CONFIG_GET(number/body_size_max)
	features["body_size"]			= sanitize_num_clamp(features["body_size"], size_min, size_max, RESIZE_DEFAULT_SIZE, 0.01)

	var/static/list/B_sizes
	if(!B_sizes)
		var/list/L = CONFIG_GET(keyed_list/breasts_cups_prefs)
		B_sizes = L.Copy()
	var/static/min_D
	if(!min_D)
		min_D = CONFIG_GET(number/penis_min_inches_prefs)
	var/static/max_D
	if(!max_D)
		max_D = CONFIG_GET(number/penis_max_inches_prefs)
	var/static/min_B
	if(!min_B)
		min_B = CONFIG_GET(number/butt_min_size_prefs)
	var/static/max_B
	if(!max_B)
		max_B = CONFIG_GET(number/butt_max_size_prefs)
	var/static/min_O
	if(!min_O)
		min_O = CONFIG_GET(number/belly_min_size_prefs)
	var/static/max_O
	if(!max_O)
		max_O = CONFIG_GET(number/belly_max_size_prefs)
	var/static/safe_visibilities
	if(!safe_visibilities)
		var/list/L = CONFIG_GET(keyed_list/safe_visibility_toggles)
		safe_visibilities = L.Copy()


	custom_speech_verb				= sanitize_inlist(custom_speech_verb, GLOB.speech_verbs, "default")
	custom_tongue					= sanitize_inlist(custom_tongue, GLOB.roundstart_tongues, "default")

	security_records				= copytext(security_records, 1, MAX_FLAVOR_LEN)
	medical_records					= copytext(medical_records, 1, MAX_FLAVOR_LEN)

	features["genital_order"]		= sanitize_text(features["genital_order"], DEF_COCKSTRING)
	features["genital_hide"]		= sanitize_integer(features["genital_hide"], 0, 4096, 0)
	features["genital_whitelist"]	= copytext(features["genital_whitelist"], 1, MAX_MESSAGE_LEN)
	features["taste"]				= copytext(features["taste"], 1, MAX_TASTE_LEN)
	features["flavor_text"]			= copytext(features["flavor_text"], 1, MAX_FLAVOR_LEN)
	features["silicon_flavor_text"]	= copytext(features["silicon_flavor_text"], 1, MAX_FLAVOR_LEN)
	features["ooc_notes"]			= copytext(features["ooc_notes"], 1, MAX_FLAVOR_LEN)


	persistent_scars = sanitize_integer(persistent_scars)
	scars_list["1"] = sanitize_text(scars_list["1"])
	scars_list["2"] = sanitize_text(scars_list["2"])
	scars_list["3"] = sanitize_text(scars_list["3"])
	scars_list["4"] = sanitize_text(scars_list["4"])
	scars_list["5"] = sanitize_text(scars_list["5"])

	// !! COYOTE SANITISATION !!
	profilePicture = sanitize_text(profilePicture) // If we still have issues loading save files with this then comment this out, IT SHOULD BE A STRING REEEE

	features_override["grad_color"]		= sanitize_hexcolor(features_override["grad_color"], 6, FALSE, default = COLOR_ALMOST_BLACK)
	features_override["grad_style"]		= sanitize_inlist(features_override["grad_style"], GLOB.hair_gradients, "none")

	joblessrole	= sanitize_integer(joblessrole, 1, 3, initial(joblessrole))
	//Validate job prefs
	for(var/j in job_preferences)
		if(job_preferences["[j]"] != JP_LOW && job_preferences["[j]"] != JP_MEDIUM && job_preferences["[j]"] != JP_HIGH)
			job_preferences -= j

	all_quirks = SANITIZE_LIST(all_quirks)

	if(GetQuirkBalance() < 0)
		reset_quirks()

	matchmaking_prefs = sanitize_matchmaking_prefs(matchmaking_prefs)

	cit_character_pref_load(S)

	return 1

/datum/preferences/proc/save_character()
	if(!path)
		return 0
	if(world.time < savecharcooldown)
		if(istype(parent))
			to_chat(parent, span_warning("You're attempting to save your character a little too fast. Wait half a second, then try again."))
		return 0
	if(GetQuirkBalance() < 0)
		reset_quirks("balance")
	if(GetPositiveQuirkCount() > MAX_QUIRKS)
		reset_quirks("max")
	savecharcooldown = world.time + PREF_SAVELOAD_COOLDOWN
	var/savefile/S = new /savefile(path)
	if(!S)
		return 0
	S.cd = "/character[default_slot]"

	WRITE_FILE(S["version"]			, SAVEFILE_VERSION_MAX)	//load_character will sanitize any bad data, so assume up-to-date.)

	//Character
	WRITE_FILE(S["real_name"]				, real_name)
	WRITE_FILE(S["custom_species"]			, custom_species)
	WRITE_FILE(S["name_is_always_random"]	, be_random_name)
	WRITE_FILE(S["body_is_always_random"]	, be_random_body)
	WRITE_FILE(S["gender"]					, gender)
	WRITE_FILE(S["body_model"]				, features["body_model"])
	WRITE_FILE(S["body_size"]				, features["body_size"])
	WRITE_FILE(S["age"]						, age)
	WRITE_FILE(S["hair_color"]				, hair_color)
	WRITE_FILE(S["facial_hair_color"]		, facial_hair_color)
	WRITE_FILE(S["eye_type"]				, eye_type)
	WRITE_FILE(S["left_eye_color"]			, left_eye_color)
	WRITE_FILE(S["right_eye_color"]			, right_eye_color)
	WRITE_FILE(S["use_custom_skin_tone"]	, use_custom_skin_tone)
	WRITE_FILE(S["skin_tone"]				, skin_tone)
	WRITE_FILE(S["hair_style_name"]			, hair_style)
	WRITE_FILE(S["facial_style_name"]		, facial_hair_style)
	WRITE_FILE(S["underwear"]				, underwear)
	WRITE_FILE(S["undie_color"]				, undie_color)
	WRITE_FILE(S["undershirt"]				, undershirt)
	WRITE_FILE(S["shirt_color"]				, shirt_color)
	WRITE_FILE(S["socks"]					, socks)
	WRITE_FILE(S["socks_color"]				, socks_color)
	WRITE_FILE(S["backbag"]					, backbag)
	WRITE_FILE(S["jumpsuit_style"]			, jumpsuit_style)
	WRITE_FILE(S["uplink_loc"]				, uplink_spawn_loc)
	WRITE_FILE(S["species"]					, pref_species.id)
	WRITE_FILE(S["custom_speech_verb"]		, custom_speech_verb)
	WRITE_FILE(S["custom_tongue"]			, custom_tongue)

	// records
	WRITE_FILE(S["security_records"]		, security_records)
	WRITE_FILE(S["medical_records"]			, medical_records)

	WRITE_FILE(S["feature_ooc_notes"], features["ooc_notes"])

	WRITE_FILE(S["feature_taste"], features["taste"])

	//special
	WRITE_FILE(S["special_s"]		,special_s)
	WRITE_FILE(S["special_p"]		,special_p)
	WRITE_FILE(S["special_e"]		,special_e)
	WRITE_FILE(S["special_c"]		,special_c)
	WRITE_FILE(S["special_i"]		,special_i)
	WRITE_FILE(S["special_a"]		,special_a)
	WRITE_FILE(S["special_l"]		,special_l)
	WRITE_FILE(S["feature_color_scheme"], features["color_scheme"])
	WRITE_FILE(S["feature_chat_color"], features["chat_color"])

	//save every advanced coloring mode thing in one go
	for(var/feature in features)
		var/feature_value = features[feature]
		if(feature_value)
			var/ref_list = GLOB.mutant_reference_list[feature]
			if(ref_list)
				var/datum/sprite_accessory/accessory = ref_list[feature_value]
				if(accessory)
					var/mutant_string = accessory.mutant_part_string
					if(!mutant_string)
						if(istype(accessory, /datum/sprite_accessory/mam_body_markings))
							mutant_string = "mam_body_markings"
					var/primary_string = "[mutant_string]_primary"
					var/secondary_string = "[mutant_string]_secondary"
					var/tertiary_string = "[mutant_string]_tertiary"
					if(accessory.color_src == MATRIXED && !accessory.matrixed_sections && feature_value != "None")
						message_admins("Sprite Accessory Failure (saving data): Accessory [accessory.type] is a matrixed item without any matrixed sections set!")
						continue
					if(features[primary_string])
						WRITE_FILE(S["feature_[primary_string]"], features[primary_string])
					if(features[secondary_string])
						WRITE_FILE(S["feature_[secondary_string]"], features[secondary_string])
					if(features[tertiary_string])
						WRITE_FILE(S["feature_[tertiary_string]"], features[tertiary_string])

	//Custom names
	for(var/custom_name_id in GLOB.preferences_custom_names)
		var/savefile_slot_name = custom_name_id + "_name" //TODO remove this
		WRITE_FILE(S[savefile_slot_name],custom_names[custom_name_id])

	WRITE_FILE(S["preferred_ai_core_display"]		,  preferred_ai_core_display)
	WRITE_FILE(S["prefered_security_department"]	, prefered_security_department)

	//Jobs
	WRITE_FILE(S["joblessrole"]		, joblessrole)
	//Write prefs
	WRITE_FILE(S["job_preferences"] , job_preferences)
	WRITE_FILE(S["hide_ckey"]		, hide_ckey)


	//Quirks
	WRITE_FILE(S["all_quirks"]			, all_quirks)

	WRITE_FILE(S["persistent_scars"]			, persistent_scars)
	WRITE_FILE(S["scars1"]						, scars_list["1"])
	WRITE_FILE(S["scars2"]						, scars_list["2"])
	WRITE_FILE(S["scars3"]						, scars_list["3"])
	WRITE_FILE(S["scars4"]						, scars_list["4"])
	WRITE_FILE(S["scars5"]						, scars_list["5"])
	if(islist(modified_limbs))
		WRITE_FILE(S["modified_limbs"]				, safe_json_encode(modified_limbs))
	WRITE_FILE(S["chosen_limb_id"],   chosen_limb_id)


	//gear loadout
	if(length(loadout_data))
		S["loadout"] << safe_json_encode(loadout_data)
	else
		S["loadout"] << safe_json_encode(list())

	WRITE_FILE(S["matchmaking_prefs"], matchmaking_prefs)

	// !! COYOTE SAVEFILE STUFF !!
	WRITE_FILE(S["profilePicture"],	profilePicture)

	WRITE_FILE(S["gradient_color"]			, features_override["grad_color"])
	WRITE_FILE(S["gradient_style"]			, features_override["grad_style"])

	cit_character_pref_save(S)

	return 1


#undef SAVEFILE_VERSION_MAX
#undef SAVEFILE_VERSION_MIN

#ifdef TESTING
//DEBUG
//Some crude tools for testing savefiles
//path is the savefile path
/client/verb/savefile_export(path as text)
	var/savefile/S = new /savefile(path)
	S.ExportText("/",file("[path].txt"))
//path is the savefile path
/client/verb/savefile_import(path as text)
	var/savefile/S = new /savefile(path)
	S.ImportText("/",file("[path].txt"))

#endif
