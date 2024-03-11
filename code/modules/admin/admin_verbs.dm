//admin verb groups - They can overlap if you so wish. Only one of each verb will exist in the verbs list regardless
//the procs are cause you can't put the comments in the GLOB var define
GLOBAL_LIST_INIT(admin_verbs_default, world.AVerbsDefault())
GLOBAL_PROTECT(admin_verbs_default)
TYPE_PROC_REF(/world, AVerbsDefault)()
	return list(
	TYPE_PROC_REF(/client, deadmin),				/*destroys our own admin datum so we can play as a regular player*/
	TYPE_PROC_REF(/client, cmd_admin_say),			/*admin-only ooc chat*/
	TYPE_PROC_REF(/client, dsay),					/*talk in deadchat using our ckey/fakekey*/
	TYPE_PROC_REF(/client, deadchat),
	TYPE_PROC_REF(/client, investigate_show),		/*various admintools for investigation. Such as a singulo grief-log*/
	TYPE_PROC_REF(/client, debug_variables),		/*allows us to -see- the variables of any instance in the game. +VAREDIT needed to modify*/
	TYPE_PROC_REF(/client, toggleprayers),
	TYPE_PROC_REF(/client, toggleadminhelpsound),
	TYPE_PROC_REF(/client, debugstatpanel),
	TYPE_PROC_REF(/client, RemoteLOOC), 			/*Fuck you I'm a PascaleCase enjoyer when it comes to functions. Fuck you nerds for using your shitty ass underscores like you know what the fuck you're reading why add an extra character and waste a couple milimeters of eye movement for me to read your entire proc name like jesus fucking christ bro. Just literally use PascalCase it looks so much neater, it's modern, industry professionals are taught to use it, C# coding standards state this, C++ coding standards, Unreal Engine developers do this, and so do Unity professionals. Like bruh please. Join me in the revolution to do PascalCase. */ // Welcome to byond~ src.grab_antlers_and_grind(deer_boi)
	)
GLOBAL_LIST_INIT(admin_verbs_admin, world.AVerbsAdmin())
GLOBAL_PROTECT(admin_verbs_admin)
TYPE_PROC_REF(/world, AVerbsAdmin)()
	return list(
	TYPE_PROC_REF(/client, toggle_experimental_clickdrag_thing),				/*toggles the harm intent no-clickdrag thing*/
	TYPE_PROC_REF(/client, toggle_radpuddle_disco_vomit_nightmare),				/*makes radpuddles flash and show numbers. please dont use this*/
	TYPE_PROC_REF(/client, show_radpuddle_scores),				/*makes radpuddles flash and show numbers. please dont use this*/
	TYPE_PROC_REF(/client, invisimin),				/*allows our mob to go invisible/visible*/
//	TYPE_PROC_REF(/datum/admins, show_traitor_panel),	/*interface which shows a mob's mind*/ -Removed due to rare practical use. Moved to debug verbs ~Errorage
	TYPE_PROC_REF(/datum/admins, show_player_panel),	/*shows an interface for individual players, with various links (links require additional flags*/
	/datum/verbs/menu/Admin/verb/playerpanel,
	TYPE_PROC_REF(/client, game_panel),			/*game panel, allows to change game-mode etc*/
	TYPE_PROC_REF(/client, getvpt),                /*shows all users who connected from a shady place*/
	TYPE_PROC_REF(/client, check_ai_laws),			/*shows AI and borg laws*/
	TYPE_PROC_REF(/datum/admins, toggleooc),		/*toggles ooc on/off for everyone*/
	TYPE_PROC_REF(/datum/admins, toggleooclocal),	/*toggles looc on/off for everyone*/
	TYPE_PROC_REF(/datum/admins, toggleoocdead),	/*toggles ooc on/off for everyone who is dead*/
	TYPE_PROC_REF(/datum/admins, toggleaooc),		/*toggles antag ooc on/off*/
	TYPE_PROC_REF(/datum/admins, toggleenter),		/*toggles whether people can join the current game*/
	TYPE_PROC_REF(/datum/admins, toggleguests),	/*toggles whether guests can join the current game*/
	TYPE_PROC_REF(/datum/admins, announce),		/*priority announce something to all clients.*/
	TYPE_PROC_REF(/datum/admins, set_admin_notice), /*announcement all clients see when joining the server.*/
	TYPE_PROC_REF(/client, admin_ghost),			/*allows us to ghost/reenter body at will*/
	TYPE_PROC_REF(/client, toggle_view_range),		/*changes how far we can see*/
	TYPE_PROC_REF(/client, getserverlogs),		/*for accessing server logs*/
	TYPE_PROC_REF(/client, cmd_admin_subtle_message),	/*send an message to somebody as a 'voice in their head'*/
	TYPE_PROC_REF(/client, cmd_admin_headset_message),	/*send an message to somebody through their headset as CentCom*/
	TYPE_PROC_REF(/client, cmd_admin_delete),		/*delete an instance/object/mob/etc*/
	TYPE_PROC_REF(/client, cmd_admin_check_contents),	/*displays the contents of an instance*/
	TYPE_PROC_REF(/client, centcom_podlauncher),/*Open a window to launch a Supplypod and configure it or it's contents*/
	TYPE_PROC_REF(/client, check_antagonists),		/*shows all antags*/
	TYPE_PROC_REF(/datum/admins, access_news_network),	/*allows access of newscasters*/
	TYPE_PROC_REF(/client, jumptocoord),			/*we ghost and jump to a coordinate*/
	TYPE_PROC_REF(/client, getcurrentlogs),		/*for accessing server logs for the current round*/
	TYPE_PROC_REF(/client, Getmob),				/*teleports a mob to our location*/
	TYPE_PROC_REF(/client, Getkey),				/*teleports a mob with a certain ckey to our location*/
//	TYPE_PROC_REF(/client, sendmob),				/*sends a mob somewhere*/ -Removed due to it needing two sorting procs to work, which were executed every time an admin right-clicked. ~Errorage
	TYPE_PROC_REF(/client, jumptoarea),
	TYPE_PROC_REF(/client, jumptokey),				/*allows us to jump to the location of a mob with a certain ckey*/
	TYPE_PROC_REF(/client, jumptomob),				/*allows us to jump to a specific mob*/
	TYPE_PROC_REF(/client, jumptoturf),			/*allows us to jump to a specific turf*/
	TYPE_PROC_REF(/client, admin_call_shuttle),	/*allows us to call the emergency shuttle*/
	TYPE_PROC_REF(/client, admin_cancel_shuttle),	/*allows us to cancel the emergency shuttle, sending it back to centcom*/
	TYPE_PROC_REF(/client, cmd_admin_direct_narrate),	/*send text directly to a player with no padding. Useful for narratives and fluff-text*/
	TYPE_PROC_REF(/client, cmd_admin_world_narrate),	/*sends text to all players with no padding*/
	TYPE_PROC_REF(/client, cmd_admin_local_narrate),	/*sends text to all mobs within view of atom*/
	TYPE_PROC_REF(/client, cmd_admin_man_up), //CIT CHANGE - adds man up verb
	TYPE_PROC_REF(/client, cmd_admin_man_up_global), //CIT CHANGE - ditto
	TYPE_PROC_REF(/client, cmd_admin_create_centcom_report),
	TYPE_PROC_REF(/client, cmd_admin_make_priority_announcement), //CIT CHANGE
	TYPE_PROC_REF(/client, cmd_change_command_name),
	TYPE_PROC_REF(/client, cmd_admin_check_player_exp), /* shows players by playtime */
	TYPE_PROC_REF(/client, toggle_combo_hud), // toggle display of the combination pizza antag and taco sci/med/eng hud
	TYPE_PROC_REF(/client, toggle_AI_interact), /*toggle admin ability to interact with machines as an AI*/
	TYPE_PROC_REF(/datum/admins, open_shuttlepanel), /* Opens shuttle manipulator UI */
	TYPE_PROC_REF(/client, respawn_character),
	TYPE_PROC_REF(/client, secrets),
	TYPE_PROC_REF(/client, toggle_hear_radio),		/*allows admins to hide all radio output*/
	TYPE_PROC_REF(/client, toggle_split_admin_tabs),
	TYPE_PROC_REF(/client, reload_admins),
	TYPE_PROC_REF(/client, reestablish_db_connection), /*reattempt a connection to the database*/
	TYPE_PROC_REF(/client, cmd_admin_pm_context),	/*right-click adminPM interface*/
	TYPE_PROC_REF(/client, cmd_admin_pm_panel),		/*admin-pm list*/
	TYPE_PROC_REF(/client, adminChangeMoney),
	TYPE_PROC_REF(/client, adminCheckMoney),
	TYPE_PROC_REF(/client, panicbunker),
	TYPE_PROC_REF(/datum/admins, BC_WhitelistKeyVerb),
	TYPE_PROC_REF(/datum/admins, BC_RemoveKeyVerb),
	TYPE_PROC_REF(/datum/admins, BC_ToggleState),
	TYPE_PROC_REF(/client, stop_sounds),
	TYPE_PROC_REF(/client, mark_datum_mapview),
	TYPE_PROC_REF(/client, hide_verbs),			/*hides all our adminverbs*/
	TYPE_PROC_REF(/client, hide_most_verbs),		/*hides all our hideable adminverbs*/
	TYPE_PROC_REF(/datum/admins, open_borgopanel),
	TYPE_PROC_REF(/datum/admins, toggle_sleep),
	TYPE_PROC_REF(/datum/admins, toggle_sleep_area),
	)
GLOBAL_LIST_INIT(admin_verbs_ban, list(TYPE_PROC_REF(/client, unban_panel), TYPE_PROC_REF(/client, DB_ban_panel), TYPE_PROC_REF(/client, stickybanpanel)))
GLOBAL_PROTECT(admin_verbs_ban)
GLOBAL_LIST_INIT(admin_verbs_sounds, list(TYPE_PROC_REF(/client, play_local_sound), TYPE_PROC_REF(/client, play_sound), TYPE_PROC_REF(/client, manual_play_web_sound), TYPE_PROC_REF(/client, set_round_end_sound)))
GLOBAL_PROTECT(admin_verbs_sounds)
GLOBAL_LIST_INIT(admin_verbs_fun, list(
	TYPE_PROC_REF(/client, cmd_admin_dress),
	TYPE_PROC_REF(/client, cmd_admin_gib_self),
	TYPE_PROC_REF(/client, drop_bomb),
	TYPE_PROC_REF(/client, set_dynex_scale),
	TYPE_PROC_REF(/client, drop_dynex_bomb),
	TYPE_PROC_REF(/client, cinematic),
	TYPE_PROC_REF(/client, one_click_antag),
	TYPE_PROC_REF(/client, cmd_admin_add_freeform_ai_law),
	TYPE_PROC_REF(/client, object_say),
	TYPE_PROC_REF(/client, toggle_random_events),
	TYPE_PROC_REF(/client, set_ooc),
	TYPE_PROC_REF(/client, reset_ooc),
	TYPE_PROC_REF(/client, forceEvent),
	TYPE_PROC_REF(/client, admin_change_sec_level),
	TYPE_PROC_REF(/client, toggle_nuke),
	TYPE_PROC_REF(/client, run_weather),
	TYPE_PROC_REF(/client, mass_zombie_infection),
	TYPE_PROC_REF(/client, mass_zombie_cure),
	TYPE_PROC_REF(/client, polymorph_all),
	TYPE_PROC_REF(/client, show_tip),
	TYPE_PROC_REF(/client, smite),
	TYPE_PROC_REF(/client, admin_away),
	TYPE_PROC_REF(/client, cmd_admin_toggle_fov),
	TYPE_PROC_REF(/client, roll_dices)					//CIT CHANGE - Adds dice verb
	))
GLOBAL_PROTECT(admin_verbs_fun)
GLOBAL_LIST_INIT(admin_verbs_spawn, list(TYPE_PROC_REF(/datum/admins, spawn_atom), TYPE_PROC_REF(/datum/admins, podspawn_atom), TYPE_PROC_REF(/datum/admins, spawn_cargo), TYPE_PROC_REF(/datum/admins, spawn_objasmob), TYPE_PROC_REF(/client, respawn_character)))
GLOBAL_PROTECT(admin_verbs_spawn)
GLOBAL_LIST_INIT(admin_verbs_server, world.AVerbsServer())
TYPE_PROC_REF(/world, AVerbsServer)()
	return list(
	TYPE_PROC_REF(/datum/admins, startnow),
	TYPE_PROC_REF(/datum/admins, restart),
	TYPE_PROC_REF(/datum/admins, end_round),
	TYPE_PROC_REF(/datum/admins, delay),
	TYPE_PROC_REF(/datum/admins, toggleaban),
	TYPE_PROC_REF(/client, everyone_random),
	TYPE_PROC_REF(/datum/admins, toggleAI),
	TYPE_PROC_REF(/datum/admins, toggleMulticam),
	TYPE_PROC_REF(/datum/admins, toggledynamicvote),
	TYPE_PROC_REF(/client, cmd_admin_delete),		/*delete an instance/object/mob/etc*/
	TYPE_PROC_REF(/client, cmd_debug_del_all),
	TYPE_PROC_REF(/client, toggle_random_events),
	TYPE_PROC_REF(/client, forcerandomrotate),
	TYPE_PROC_REF(/client, adminchangemap),
	TYPE_PROC_REF(/client, toggle_hub)
	)
GLOBAL_PROTECT(admin_verbs_server)
GLOBAL_LIST_INIT(admin_verbs_debug, world.AVerbsDebug())
TYPE_PROC_REF(/world, AVerbsDebug)()
	return list(
	TYPE_PROC_REF(/client, restart_controller),
	TYPE_PROC_REF(/client, cmd_admin_list_open_jobs),
	TYPE_PROC_REF(/client, Debug2),
	TYPE_PROC_REF(/client, cmd_debug_make_powernets),
	TYPE_PROC_REF(/client, cmd_debug_mob_lists),
	TYPE_PROC_REF(/client, cmd_admin_delete),
	TYPE_PROC_REF(/client, cmd_debug_del_all),
	TYPE_PROC_REF(/client, restart_controller),
	TYPE_PROC_REF(/client, enable_debug_verbs),
	TYPE_PROC_REF(/client, callproc),
	TYPE_PROC_REF(/client, callproc_datum),
	TYPE_PROC_REF(/client, SDQL2_query),
	TYPE_PROC_REF(/client, test_movable_UI),
	TYPE_PROC_REF(/client, test_snap_UI),
	TYPE_PROC_REF(/client, debugNatureMapGenerator),
	TYPE_PROC_REF(/client, check_bomb_impacts),
	/proc/machine_upgrade,
	TYPE_PROC_REF(/client, populate_world),
	TYPE_PROC_REF(/client, get_dynex_power),		//*debug verbs for dynex explosions.
	TYPE_PROC_REF(/client, get_dynex_range),		//*debug verbs for dynex explosions.
	TYPE_PROC_REF(/client, set_dynex_scale),
	TYPE_PROC_REF(/client, cmd_display_del_log),
	TYPE_PROC_REF(/client, create_outfits),
	TYPE_PROC_REF(/client, modify_goals),
	TYPE_PROC_REF(/client, debug_huds),
	TYPE_PROC_REF(/client, map_template_load),
	TYPE_PROC_REF(/client, map_template_upload),
	TYPE_PROC_REF(/client, map_template_loadtest),
	TYPE_PROC_REF(/client, jump_to_ruin),
	TYPE_PROC_REF(/client, clear_dynamic_transit),
	TYPE_PROC_REF(/client, toggle_medal_disable),
	TYPE_PROC_REF(/client, view_runtimes),
	TYPE_PROC_REF(/client, pump_random_event),
	TYPE_PROC_REF(/client, cmd_display_init_log),
	TYPE_PROC_REF(/client, cmd_display_overlay_log),
	TYPE_PROC_REF(/client, reload_configuration),
	TYPE_PROC_REF(/datum/admins, create_or_modify_area),
	TYPE_PROC_REF(/datum/admins, fixcorruption),
#ifdef REFERENCE_TRACKING
	TYPE_PROC_REF(///datum/admins, view_refs),
	TYPE_PROC_REF(///datum/admins, view_del_failures),
#endif
	TYPE_PROC_REF(/client, generate_wikichem_list), //DO NOT PRESS UNLESS YOU WANT SUPERLAG
	)
GLOBAL_PROTECT(admin_verbs_debug)
//GLOBAL_LIST_INIT(admin_verbs_possess, list(GLOBAL_PROC_REF(possess), GLOBAL_PROC_REF(release)))
//GLOBAL_PROTECT(admin_verbs_possess)
GLOBAL_LIST_INIT(admin_verbs_permissions, list(TYPE_PROC_REF(/client, edit_admin_permissions)))
GLOBAL_PROTECT(admin_verbs_permissions)
GLOBAL_LIST_INIT(admin_verbs_poll, list(TYPE_PROC_REF(/client, create_poll)))

//verbs which can be hidden - needs work
GLOBAL_PROTECT(admin_verbs_poll)
GLOBAL_LIST_INIT(admin_verbs_hideable, list(
	TYPE_PROC_REF(/client, set_ooc),
	TYPE_PROC_REF(/client, reset_ooc),
	TYPE_PROC_REF(/client, deadmin),
	TYPE_PROC_REF(/datum/admins, show_traitor_panel),
	TYPE_PROC_REF(/datum/admins, toggleenter),
	TYPE_PROC_REF(/datum/admins, toggleguests),
	TYPE_PROC_REF(/datum/admins, announce),
	TYPE_PROC_REF(/datum/admins, set_admin_notice),
	TYPE_PROC_REF(/client, admin_ghost),
	TYPE_PROC_REF(/client, toggle_view_range),
	TYPE_PROC_REF(/client, cmd_admin_subtle_message),
	TYPE_PROC_REF(/client, cmd_admin_headset_message),
	TYPE_PROC_REF(/client, cmd_admin_check_contents),
	TYPE_PROC_REF(/datum/admins, access_news_network),
	TYPE_PROC_REF(/client, admin_call_shuttle),
	TYPE_PROC_REF(/client, admin_cancel_shuttle),
	TYPE_PROC_REF(/client, cmd_admin_direct_narrate),
	TYPE_PROC_REF(/client, cmd_admin_world_narrate),
	TYPE_PROC_REF(/client, cmd_admin_local_narrate),
	TYPE_PROC_REF(/client, play_local_sound),
	TYPE_PROC_REF(/client, play_sound),
	TYPE_PROC_REF(/client, set_round_end_sound),
	TYPE_PROC_REF(/client, cmd_admin_dress),
	TYPE_PROC_REF(/client, cmd_admin_gib_self),
	TYPE_PROC_REF(/client, drop_bomb),
	TYPE_PROC_REF(/client, drop_dynex_bomb),
	TYPE_PROC_REF(/client, get_dynex_range),
	TYPE_PROC_REF(/client, get_dynex_power),
	TYPE_PROC_REF(/client, set_dynex_scale),
	TYPE_PROC_REF(/client, cinematic),
	TYPE_PROC_REF(/client, cmd_admin_add_freeform_ai_law),
	TYPE_PROC_REF(/client, cmd_admin_create_centcom_report),
	TYPE_PROC_REF(/client, cmd_change_command_name),
	TYPE_PROC_REF(/client, object_say),
	TYPE_PROC_REF(/client, toggle_random_events),
	TYPE_PROC_REF(/datum/admins, startnow),
	TYPE_PROC_REF(/datum/admins, restart),
	TYPE_PROC_REF(/datum/admins, delay),
	TYPE_PROC_REF(/datum/admins, toggleaban),
	TYPE_PROC_REF(/client, everyone_random),
	TYPE_PROC_REF(/datum/admins, toggleAI),
	TYPE_PROC_REF(/client, restart_controller),
	TYPE_PROC_REF(/client, cmd_admin_list_open_jobs),
	TYPE_PROC_REF(/client, callproc),
	TYPE_PROC_REF(/client, callproc_datum),
	TYPE_PROC_REF(/client, Debug2),
	TYPE_PROC_REF(/client, reload_admins),
	TYPE_PROC_REF(/client, cmd_debug_make_powernets),
	TYPE_PROC_REF(/client, startSinglo),
	TYPE_PROC_REF(/client, cmd_debug_mob_lists),
	TYPE_PROC_REF(/client, cmd_debug_del_all),
	TYPE_PROC_REF(/client, enable_debug_verbs),
//	/proc/possess,
//	/proc/release,
	TYPE_PROC_REF(/client, reload_admins),
	TYPE_PROC_REF(/client, panicbunker),
	TYPE_PROC_REF(/client, admin_change_sec_level),
	TYPE_PROC_REF(/client, toggle_nuke),
	TYPE_PROC_REF(/client, cmd_display_del_log),
	TYPE_PROC_REF(/client, toggle_combo_hud),
	TYPE_PROC_REF(/client, debug_huds),
	TYPE_PROC_REF(/client, cmd_admin_man_up), //CIT CHANGE - adds man up verb
	TYPE_PROC_REF(/client, cmd_admin_man_up_global) //CIT CHANGE - ditto
	))
GLOBAL_PROTECT(admin_verbs_hideable)

TYPE_PROC_REF(/client, add_admin_verbs)()
	if(holder)
		control_freak = CONTROL_FREAK_SKIN | CONTROL_FREAK_MACROS

		var/rights = holder.rank.rights
		add_verb(src, GLOB.admin_verbs_default)
		if(rights & R_BUILDMODE)
			add_verb(src, TYPE_PROC_REF(/client, togglebuildmodeself))
		if(rights & R_ADMIN)
			add_verb(src, GLOB.admin_verbs_admin)
		if(rights & R_BAN)
			add_verb(src, GLOB.admin_verbs_ban)
		if(rights & R_FUN)
			add_verb(src, GLOB.admin_verbs_fun)
		if(rights & R_SERVER)
			add_verb(src, GLOB.admin_verbs_server)
		if(rights & R_DEBUG)
			add_verb(src, GLOB.admin_verbs_debug)
		if(rights & R_POSSESS)
//			add_verb(src, GLOB.admin_verbs_possess)
//		if(rights & R_PERMISSIONS)
			add_verb(src, GLOB.admin_verbs_permissions)
		if(rights & R_STEALTH)
			add_verb(src, TYPE_PROC_REF(/client, stealth))
		if(rights & R_ADMIN)
			add_verb(src, GLOB.admin_verbs_poll)
		if(rights & R_SOUNDS)
			add_verb(src, GLOB.admin_verbs_sounds)
			if(CONFIG_GET(string/invoke_youtubedl))
				add_verb(src, TYPE_PROC_REF(/client, play_web_sound))
		if(rights & R_SPAWN)
			add_verb(src, GLOB.admin_verbs_spawn)
			add_verb(src, GLOB.staff_verbs)

TYPE_PROC_REF(/client, remove_admin_verbs)()
	remove_verb(src, list(
		GLOB.admin_verbs_default,
		TYPE_PROC_REF(/client, togglebuildmodeself),
		GLOB.admin_verbs_admin,
		GLOB.admin_verbs_ban,
		GLOB.admin_verbs_fun,
		GLOB.admin_verbs_server,
		GLOB.admin_verbs_debug,
//		GLOB.admin_verbs_possess,
		GLOB.admin_verbs_permissions,
		TYPE_PROC_REF(/client, stealth),
		GLOB.admin_verbs_poll,
		GLOB.admin_verbs_sounds,
		TYPE_PROC_REF(/client, play_web_sound),
		GLOB.admin_verbs_spawn,
		/*Debug verbs added by "show debug verbs"*/
		GLOB.admin_verbs_debug_mapping,
		TYPE_PROC_REF(/client, disable_debug_verbs),
		TYPE_PROC_REF(/client, readmin)
		))

TYPE_PROC_REF(/client, hide_most_verbs)()//Allows you to keep some functionality while hiding some verbs
	set name = "Adminverbs - Hide Most"
	set category = "Admin"

	remove_verb(src, GLOB.admin_verbs_hideable)
	remove_verb(src, TYPE_PROC_REF(/client, hide_most_verbs))
	add_verb(src, TYPE_PROC_REF(/client, show_verbs))

	to_chat(src, span_interface("Most of your adminverbs have been hidden."))
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Hide Most Adminverbs") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	return

TYPE_PROC_REF(/client, hide_verbs)()
	set name = "Adminverbs - Hide All"
	set category = "Admin"

	remove_admin_verbs()
	add_verb(src, TYPE_PROC_REF(/client, show_verbs))

	to_chat(src, span_interface("Almost all of your adminverbs have been hidden."))
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Hide All Adminverbs") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	return

TYPE_PROC_REF(/client, show_verbs)()
	set name = "Adminverbs - Show"
	set category = "Admin"

	remove_verb(src, TYPE_PROC_REF(/client, show_verbs))
	add_admin_verbs()

	to_chat(src, span_interface("All of your adminverbs are now visible."))
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Show Adminverbs") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!




TYPE_PROC_REF(/client, admin_ghost)()
	set category = "Admin.Game"
	set name = "Aghost"
	if(!holder)
		return FALSE
	if(isobserver(mob))
		//re-enter
		var/mob/dead/observer/ghost = mob
		if(!ghost.mind || !ghost.mind.current) //won't do anything if there is no body
			return FALSE
		if(!ghost.can_reenter_corpse)
			log_admin("[key_name(usr)] re-entered corpse")
			message_admins("[key_name_admin(usr)] re-entered corpse")
		ghost.can_reenter_corpse = 1 //force re-entering even when otherwise not possible
		ghost.reenter_corpse()
		if(isliving(mob))
			var/mob/living/L = mob
			L.living_flags &= ~HIDE_OFFLINE_INDICATOR
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Admin Reenter") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	else if(isnewplayer(mob))
		to_chat(src, "<font color='red'>Error: Aghost: Can't admin-ghost whilst in the lobby. Join or Observe first.</font>")
		return FALSE
	else
		//ghostize
		log_admin("[key_name(usr)] admin ghosted.")
		message_admins("[key_name_admin(usr)] admin ghosted.")
		var/mob/body = mob
		if(isliving(body))
			var/mob/living/livingbody = body
			livingbody.living_flags |= HIDE_OFFLINE_INDICATOR
		body.ghostize(1, voluntary = TRUE)
		if(body && !body.key)
			body.key = "@[key]"	//Haaaaaaaack. But the people have spoken. If it breaks; blame adminbus
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Admin Ghost") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	return TRUE

TYPE_PROC_REF(/client, invisimin)()
	set name = "Invisimin"
	set category = "Admin.Game"
	set desc = "Toggles ghost-like invisibility (Don't abuse this)"
	if(holder && mob)
		if(mob.invisibility == INVISIBILITY_OBSERVER)
			mob.invisibility = initial(mob.invisibility)
			to_chat(mob, span_boldannounce("Invisimin off. Invisibility reset."))
		else
			mob.invisibility = INVISIBILITY_OBSERVER
			to_chat(mob, "<span class='adminnotice'><b>Invisimin on. You are now as invisible as a ghost.</b></span>")

TYPE_PROC_REF(/client, toggle_experimental_clickdrag_thing)()
	set name = "Toggle Clickdrag Changes"
	set category = "Debug"
	set desc = "Toggles harm-intent clickdrag disabling. Its experimental, click this if people complain clickdragging being broken, and tell Superlagg what broke."
	GLOB.use_experimental_clickdrag_thing = !GLOB.use_experimental_clickdrag_thing
	log_admin("[key_name(usr)] toggled the harm intent clickdrag disabling thing.")
	message_admins("[key_name_admin(usr)] toggled the harm intent clickdrag disabling thing.")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Toggled clickdrag thing")
	if(alert("Tell everyone the experimental clickdrag thing was [GLOB.use_experimental_clickdrag_thing ? "enabled" : "disabled"]?",,"Yes","No") != "Yes")
		return
	to_chat(world, "<B>The experimental harm-intent clickdrag disable thing has been [GLOB.use_experimental_clickdrag_thing ? "enabled" : "disabled"].</B>")

/// No longer does what it did, but fuck it im keeping the name
TYPE_PROC_REF(/client, toggle_radpuddle_disco_vomit_nightmare)()
	set name = "Toggle Radturf Screaming"
	set category = "Debug"
	set desc = "Toggles whether mobs will scream and shout a number when irradiated."
	GLOB.rad_puddle_debug = !GLOB.rad_puddle_debug
	log_admin("[key_name(usr)] toggled Radturf screaming.")
	message_admins("[key_name_admin(usr)] toggled Radturf screaming.")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Toggled Radturf screaming")

TYPE_PROC_REF(/client, show_radpuddle_scores)()
	set name = "Show Radpuddle Numbers"
	set category = "Debug"
	set desc = "Makes the redpuddle'd tiles show numbers."
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_RADIATION_SHOW)
	message_admins("[key_name_admin(usr)] <B>pinged radiation.</B>")

TYPE_PROC_REF(/client, check_antagonists)()
	set name = "Check Antagonists"
	set category = "Admin.Game"
	if(holder)
		holder.check_antagonists()
		log_admin("[key_name(usr)] checked antagonists.")	//for tsar~
		if(!isobserver(usr) && SSticker.HasRoundStarted())
			message_admins("[key_name_admin(usr)] checked antagonists.")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Check Antagonists") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

TYPE_PROC_REF(/client, unban_panel)()
	set name = "Unban Panel"
	set category = "Admin"
	if(holder)
		if(CONFIG_GET(flag/ban_legacy_system))
			holder.unbanpanel()
		else
			holder.DB_ban_panel()
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Unban Panel") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

TYPE_PROC_REF(/client, game_panel)()
	set name = "Game Panel"
	set category = "Admin.Game"
	if(holder)
		holder.Game()
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Game Panel") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

TYPE_PROC_REF(/client, secrets)()
	set name = "Secrets"
	set category = "Admin.Game"
	if (holder)
		holder.Secrets()
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Secrets Panel") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!


TYPE_PROC_REF(/client, findStealthKey)(txt)
	if(txt)
		for(var/P in GLOB.stealthminID)
			if(GLOB.stealthminID[P] == txt)
				return P
	txt = GLOB.stealthminID[ckey]
	return txt

TYPE_PROC_REF(/client, createStealthKey)()
	var/num = (rand(0,1000))
	var/i = 0
	while(i == 0)
		i = 1
		for(var/P in GLOB.stealthminID)
			if(num == GLOB.stealthminID[P])
				num++
				i = 0
	GLOB.stealthminID["[ckey]"] = "@[num2text(num)]"

TYPE_PROC_REF(/client, getvpt)()
	set category = "Admin"
	set name = "Check Clients"
	if(holder)
		if(!check_rights(R_ADMIN, 0))
			return
		for (var/ckey in GLOB.warning_ckeys)
			to_chat(usr, "[ckey] connected from a known [GLOB.warning_ckeys[ckey]].")
		if (GLOB.warning_ckeys.len == 0)
			to_chat(usr, "No ckeys have been flagged.")

TYPE_PROC_REF(/client, stealth)()
	set category = "Admin"
	set name = "Stealth Mode"
	if(holder)
		if(!check_rights(R_STEALTH, 0))
			return
		if(holder.fakekey)
			holder.fakekey = null
			if(isobserver(mob))
				mob.invisibility = initial(mob.invisibility)
				mob.alpha = initial(mob.alpha)
				mob.name = initial(mob.name)
				mob.mouse_opacity = initial(mob.mouse_opacity)
		else
			var/new_key = ckeyEx(stripped_input(usr, "Enter your desired display name.", "Fake Key", key, 26))
			if(!new_key)
				return
			holder.fakekey = new_key
			createStealthKey()
			if(isobserver(mob))
				mob.invisibility = INVISIBILITY_MAXIMUM //JUST IN CASE
				mob.alpha = 0 //JUUUUST IN CASE
				mob.name = " "
				mob.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		log_admin("[key_name(usr)] has turned stealth mode [holder.fakekey ? "ON" : "OFF"]")
		message_admins("[key_name_admin(usr)] has turned stealth mode [holder.fakekey ? "ON" : "OFF"]")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Stealth Mode") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

TYPE_PROC_REF(/client, drop_bomb)()
	set category = "Admin.Fun"
	set name = "Drop Bomb"
	set desc = "Cause an explosion of varying strength at your location."

	var/list/choices = list("Small Bomb (1, 2, 3, 3)", "Medium Bomb (2, 3, 4, 4)", "Big Bomb (3, 5, 7, 5)", "Maxcap", "Custom Bomb")
	var/choice = input("What size explosion would you like to produce? NOTE: You can do all this rapidly and in an IC manner (using cruise missiles!) with the Config/Launch Supplypod verb. WARNING: These ignore the maxcap") as null|anything in choices
	var/turf/epicenter = mob.loc

	switch(choice)
		if(null)
			return 0
		if("Small Bomb (1, 2, 3, 3)")
			explosion(epicenter, 1, 2, 3, 3, TRUE, TRUE)
		if("Medium Bomb (2, 3, 4, 4)")
			explosion(epicenter, 2, 3, 4, 4, TRUE, TRUE)
		if("Big Bomb (3, 5, 7, 5)")
			explosion(epicenter, 3, 5, 7, 5, TRUE, TRUE)
		if("Maxcap")
			explosion(epicenter, GLOB.MAX_EX_DEVESTATION_RANGE, GLOB.MAX_EX_HEAVY_RANGE, GLOB.MAX_EX_LIGHT_RANGE, GLOB.MAX_EX_FLASH_RANGE)
		if("Custom Bomb")
			var/devastation_range = input("Devastation range (in tiles):") as null|num
			if(devastation_range == null)
				return
			var/heavy_impact_range = input("Heavy impact range (in tiles):") as null|num
			if(heavy_impact_range == null)
				return
			var/light_impact_range = input("Light impact range (in tiles):") as null|num
			if(light_impact_range == null)
				return
			var/flash_range = input("Flash range (in tiles):") as null|num
			if(flash_range == null)
				return
			if(devastation_range > GLOB.MAX_EX_DEVESTATION_RANGE || heavy_impact_range > GLOB.MAX_EX_HEAVY_RANGE || light_impact_range > GLOB.MAX_EX_LIGHT_RANGE || flash_range > GLOB.MAX_EX_FLASH_RANGE)
				if(alert("Bomb is bigger than the maxcap. Continue?",,"Yes","No") != "Yes")
					return
			epicenter = mob.loc //We need to reupdate as they may have moved again
			explosion(epicenter, devastation_range, heavy_impact_range, light_impact_range, flash_range, TRUE, TRUE)
	message_admins("[ADMIN_LOOKUPFLW(usr)] creating an admin explosion at [epicenter.loc].")
	log_admin("[key_name(usr)] created an admin explosion at [epicenter.loc].")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Drop Bomb") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

TYPE_PROC_REF(/client, drop_dynex_bomb)()
	set category = "Admin.Fun"
	set name = "Drop DynEx Bomb"
	set desc = "Cause an explosion of varying strength at your location."

	var/ex_power = input("Explosive Power:") as null|num
	var/turf/epicenter = mob.loc
	if(ex_power && epicenter)
		dyn_explosion(epicenter, ex_power)
		message_admins("[ADMIN_LOOKUPFLW(usr)] creating an admin explosion at [epicenter.loc].")
		log_admin("[key_name(usr)] created an admin explosion at [epicenter.loc].")
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Drop Dynamic Bomb") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

TYPE_PROC_REF(/client, get_dynex_range)()
	set category = "Debug"
	set name = "Get DynEx Range"
	set desc = "Get the estimated range of a bomb, using explosive power."

	var/ex_power = input("Explosive Power:") as null|num
	if (isnull(ex_power))
		return
	var/range = round((2 * ex_power)**GLOB.DYN_EX_SCALE)
	to_chat(usr, "Estimated Explosive Range: (Devastation: [round(range*0.25)], Heavy: [round(range*0.5)], Light: [round(range)])")

TYPE_PROC_REF(/client, get_dynex_power)()
	set category = "Debug"
	set name = "Get DynEx Power"
	set desc = "Get the estimated required power of a bomb, to reach a specific range."

	var/ex_range = input("Light Explosion Range:") as null|num
	if (isnull(ex_range))
		return
	var/power = (0.5 * ex_range)**(1/GLOB.DYN_EX_SCALE)
	to_chat(usr, "Estimated Explosive Power: [power]")

TYPE_PROC_REF(/client, set_dynex_scale)()
	set category = "Debug"
	set name = "Set DynEx Scale"
	set desc = "Set the scale multiplier of dynex explosions. The default is 0.5."

	var/ex_scale = input("New DynEx Scale:") as null|num
	if(!ex_scale)
		return
	GLOB.DYN_EX_SCALE = ex_scale
	log_admin("[key_name(usr)] has modified Dynamic Explosion Scale: [ex_scale]")
	message_admins("[key_name_admin(usr)] has  modified Dynamic Explosion Scale: [ex_scale]")

TYPE_PROC_REF(/client, give_spell)(mob/T in GLOB.mob_list)
	set category = "Admin.Fun"
	set name = "Give Spell"
	set desc = "Gives a spell to a mob."

	var/list/spell_list = list()
	var/type_length = length_char("/obj/effect/proc_holder/spell") + 2
	for(var/A in GLOB.spells)
		spell_list[copytext_char("[A]", type_length)] = A
	var/obj/effect/proc_holder/spell/S = input("Choose the spell to give to that guy", "ABRAKADABRA") as null|anything in spell_list
	if(!S)
		return

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Give Spell") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	log_admin("[key_name(usr)] gave [key_name(T)] the spell [S].")
	message_admins(span_adminnotice("[key_name_admin(usr)] gave [key_name(T)] the spell [S]."))

	S = spell_list[S]
	if(T.mind)
		T.mind.AddSpell(new S)
	else
		T.AddSpell(new S)
		message_admins(span_danger("Spells given to mindless mobs will not be transferred in mindswap or cloning!"))

TYPE_PROC_REF(/client, remove_spell)(mob/T in GLOB.mob_list)
	set category = "Admin.Fun"
	set name = "Remove Spell"
	set desc = "Remove a spell from the selected mob."

	if(T && T.mind)
		var/obj/effect/proc_holder/spell/S = input("Choose the spell to remove", "NO ABRAKADABRA") as null|anything in T.mind.spell_list
		if(S)
			T.mind.RemoveSpell(S)
			log_admin("[key_name(usr)] removed the spell [S] from [key_name(T)].")
			message_admins(span_adminnotice("[key_name_admin(usr)] removed the spell [S] from [key_name(T)]."))
			SSblackbox.record_feedback("tally", "admin_verb", 1, "Remove Spell") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

TYPE_PROC_REF(/client, give_disease)(mob/living/T in GLOB.mob_living_list)
	set category = "Admin.Fun"
	set name = "Give Disease"
	set desc = "Gives a Disease to a mob."
	if(!istype(T))
		to_chat(src, span_notice("You can only give a disease to a mob of type /mob/living."))
		return
	var/datum/disease/D = input("Choose the disease to give to that guy", "ACHOO") as null|anything in SSdisease.diseases
	if(!D)
		return
	T.ForceContractDisease(new D, FALSE, TRUE)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Give Disease") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
	log_admin("[key_name(usr)] gave [key_name(T)] the disease [D].")
	message_admins(span_adminnotice("[key_name_admin(usr)] gave [key_name(T)] the disease [D]."))

TYPE_PROC_REF(/client, object_say)(obj/O in world)
	set category = "Admin.Events"
	set name = "OSay"
	set desc = "Makes an object say something."
	var/message = input(usr, "What do you want the message to be?", "Make Sound") as text | null
	if(!message)
		return
	O.say(message)
	log_admin("[key_name(usr)] made [O] at [AREACOORD(O)] say \"[message]\"")
	message_admins(span_adminnotice("[key_name_admin(usr)] made [O] at [AREACOORD(O)]. say \"[message]\""))
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Object Say") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
TYPE_PROC_REF(/client, togglebuildmodeself)()
	set name = "Toggle Build Mode Self"
	set category = "Admin.Events"
	if (!(holder.rank.rights & R_BUILDMODE))
		return
	if(src.mob)
		togglebuildmode(src.mob)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Toggle Build Mode") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

TYPE_PROC_REF(/client, check_ai_laws)()
	set name = "Check AI Laws"
	set category = "Admin.Game"
	if(holder)
		src.holder.output_ai_laws()

TYPE_PROC_REF(/client, deadmin)()
	set name = "Deadmin"
	set category = "Admin"
	set desc = "Shed your admin powers."

	if(!holder)
		return

	if(has_antag_hud())
		toggle_combo_hud()

	holder.deactivate()

	to_chat(src, span_interface("You are now a normal player."))
	log_admin("[src] deadmined themself.")
	message_admins("[src] deadmined themself.")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Deadmin")

TYPE_PROC_REF(/client, readmin)()
	set name = "Readmin"
	set category = "Admin"
	set desc = "Regain your admin powers."

	var/datum/admins/A = GLOB.deadmins[ckey]

	if(!A)
		A = GLOB.admin_datums[ckey]
		if (!A)
			var/msg = " is trying to readmin but they have no deadmin entry"
			message_admins("[key_name_admin(src)][msg]")
			log_admin_private("[key_name(src)][msg]")
			return

	A.associate(src)

	if (!holder)
		return //This can happen if an admin attempts to vv themself into somebody elses's deadmin datum by getting ref via brute force

	to_chat(src, span_interface("You are now an admin."))
	message_admins("[src] re-adminned themselves.")
	log_admin("[src] re-adminned themselves.")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Readmin")

TYPE_PROC_REF(/client, populate_world)(amount = 50 as num)
	set name = "Populate World"
	set category = "Debug"
	set desc = "(\"Amount of mobs to create\") Populate the world with test mobs."

	if (amount > 0)
		var/area/area
		var/list/candidates
		var/turf/open/floor/tile
		var/j,k

		for (var/i = 1 to amount)
			j = 100

			do
				area = pick(GLOB.the_station_areas)

				if (area)

					candidates = get_area_turfs(area)

					if (candidates.len)
						k = 100

						do
							tile = pick(candidates)
						while ((!tile || !istype(tile)) && --k > 0)

						if (tile)
							var/mob/living/carbon/human/hooman = new(tile)
							hooman.equipOutfit(pick(subtypesof(/datum/outfit)))
							testing("Spawned test mob at [COORD(tile)]")
			while (!area && --j > 0)

TYPE_PROC_REF(/client, toggle_AI_interact)()
	set name = "Toggle Admin AI Interact"
	set category = "Admin.Game"
	set desc = "Allows you to interact with most machines as an AI would as a ghost"

	AI_Interact = !AI_Interact
	if(mob && IsAdminGhost(mob))
		mob.silicon_privileges = AI_Interact ? ALL : NONE

	log_admin("[key_name(usr)] has [AI_Interact ? "activated" : "deactivated"] Admin AI Interact")
	message_admins("[key_name_admin(usr)] has [AI_Interact ? "activated" : "deactivated"] their AI interaction")

TYPE_PROC_REF(/client, debugstatpanel)()
	set name = "Debug Stat Panel"
	set category = "Debug"

	src << output("", "statbrowser:create_debug")


TYPE_PROC_REF(/datum/admins, toggle_sleep)(mob/living/perp in GLOB.mob_living_list)
	set category = null
	set name = "Toggle Sleeping"

	if(!check_rights(R_ADMIN))
		message_admins("[ADMIN_TPMONTY(usr)] tried to use toggle_sleep() without admin perms.")
		log_admin("INVALID ADMIN PROC ACCESS: [key_name(usr)] tried to use toggle_sleep() without admin perms.")
		return

	if(perp.IsAdminSleeping())
		perp.ToggleAdminSleep()
	else if(tgui_alert(usr, "Are you sure you want to sleep [key_name(perp)]?", "Toggle Sleeping", list("Yes", "No")) != "Yes")
		return
	else if(QDELETED(perp))
		to_chat(usr, span_warning("Target is no longer valid."))
		return
	else
		perp.ToggleAdminSleep()

	log_admin("[key_name(usr)] has [perp.IsAdminSleeping() ? "enabled" : "disabled"] sleeping on [key_name(perp)].")
	message_admins("[ADMIN_TPMONTY(usr)] has [perp.IsAdminSleeping() ? "enabled" : "disabled"] sleeping on [ADMIN_TPMONTY(perp)].")


TYPE_PROC_REF(/datum/admins, toggle_sleep_area)()
	set category = "Admin.Game"
	set name = "Toggle Sleeping Area"

	if(!check_rights(R_ADMIN))
		message_admins("[ADMIN_TPMONTY(usr)] tried to use toggle_sleep_area() without admin perms.")
		log_admin("INVALID ADMIN PROC ACCESS: [key_name(usr)] tried to use toggle_sleep_area() without admin perms.")
		return

	switch(tgui_alert(usr, "Sleep or unsleep everyone?", "Toggle Sleeping Area", list("Sleep", "Unsleep", "Cancel")))
		if("Sleep")
			for(var/mob/living/perp in view())
				perp.SetAdminSleep()
			log_admin("[key_name(usr)] has slept everyone in view.")
			message_admins("[ADMIN_TPMONTY(usr)] has slept everyone in view.")
		if("Unsleep")
			for(var/mob/living/perp in view())
				perp.SetAdminSleep(remove = TRUE)
			log_admin("[key_name(usr)] has unslept everyone in view.")
			message_admins("[ADMIN_TPMONTY(usr)] has unslept everyone in view.")
