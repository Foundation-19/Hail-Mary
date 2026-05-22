/datum/lobby_menu
	var/client/owner

/datum/lobby_menu/New(client/C)
	owner = C

/datum/lobby_menu/Destroy()
	owner = null
	return ..()

/datum/lobby_menu/ui_state(mob/user)
	return GLOB.always_state

/datum/lobby_menu/ui_close(mob/user)
	var/mob/dead/new_player/np = owner?.mob
	if(istype(np))
		addtimer(CALLBACK(np, TYPE_PROC_REF(/mob/dead/new_player, new_player_panel)), 1)

/datum/lobby_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LobbyMenu")
		ui.open()

/datum/lobby_menu/ui_data(mob/user)
	var/list/data = list()
	
	if(owner && owner.prefs)
		var/pname = owner.prefs.be_random_name ? "WANDERER" : uppertext(owner.prefs.real_name)
		data["character_name"] = pname
		data["current_slot"] = owner.prefs.default_slot || 1
	else
		data["character_name"] = "WANDERER"
		data["current_slot"] = 1
	
	if(SSticker.current_state <= GAME_STATE_PREGAME)
		data["game_state"] = "pregame"
		var/mob/dead/new_player/np = owner?.mob
		data["ready"] = istype(np) && np.ready == PLAYER_READY_TO_PLAY
	else
		data["game_state"] = "running"
		data["ready"] = FALSE
	
	data["has_polls"] = FALSE
	
	if(SSdbcore.Connect())
		var/isadmin = FALSE
		if(owner?.holder)
			isadmin = TRUE
		var/datum/db_query/query_get_new_polls = SSdbcore.NewQuery({"
			SELECT id FROM [format_table_name("poll_question")]
			WHERE (adminonly = 0 OR :isadmin = 1)
			AND Now() BETWEEN starttime AND endtime
			AND id NOT IN (
				SELECT pollid FROM [format_table_name("poll_vote")]
				WHERE ckey = :ckey
			)
			AND id NOT IN (
				SELECT pollid FROM [format_table_name("poll_textreply")]
				WHERE ckey = :ckey
			)
		"}, list("isadmin" = isadmin, "ckey" = user.ckey))
		if(query_get_new_polls.Execute())
			if(query_get_new_polls.NextRow())
				data["has_polls"] = TRUE
		qdel(query_get_new_polls)
	
	data["rules_accepted"] = owner?.prefs?.rules_accepted || FALSE
	data["is_interviewee"] = owner?.interviewee || FALSE
	
	return data

/datum/lobby_menu/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	
	var/mob/dead/new_player/np = usr
	if(!istype(np))
		return
	
	switch(action)
		if("show_preferences")
			SStgui.close_uis(src)
			var/datum/tgui_character_setup/panel = new(owner)
			panel.ui_interact(np)
			return TRUE
		
		if("refresh")
			np.new_player_panel()
			return TRUE
		
		if("fix_chat")
			owner?.nuke_chat()
			return TRUE
		
		if("late_join")
			if(!SSticker || !SSticker.IsRoundInProgress())
				to_chat(usr, span_danger("The round is either not ready, or has already finished..."))
				return
			if((length_char(owner?.prefs?.features?["flavor_text"])) < MIN_FLAVOR_LEN)
				alert(usr, "Your flavor text must be at least [MIN_FLAVOR_LEN] characters. Please edit your character in the Character Creator.", "Flavor Text Required")
				return
			SStgui.close_uis(src)
			np.LateChoices()
			return TRUE
		
		if("observe")
			np.make_me_an_observer()
			return TRUE
		
		if("view_wiki")
			owner << link("https://sites.google.com/view/f13mechanisediron/menu?authuser=0")
			return TRUE
		
		if("show_rules")
			np.show_rules_panel(FALSE)
			return TRUE
		
		if("show_polls")
			np.handle_player_polling()
			return TRUE
	
	return FALSE
