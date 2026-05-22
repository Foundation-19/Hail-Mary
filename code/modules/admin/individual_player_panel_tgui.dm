/datum/individual_player_panel
	var/client/owner
	var/datum/admins/holder
	var/mob/target

/datum/individual_player_panel/New(client/C, mob/M)
	if(!istype(C))
		qdel(src)
		CRASH("Individual player panel attempted to open without a valid client")
	owner = C
	holder = C.holder
	target = M

/datum/individual_player_panel/Destroy()
	owner = null
	holder = null
	target = null
	return ..()

/datum/individual_player_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/individual_player_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IndividualPlayerPanel")
		ui.open()

/datum/individual_player_panel/ui_data(mob/user)
	. = list()
	.["player"] = list(
		"name" = target.name,
		"real_name" = target.real_name,
		"key" = target.key,
		"ckey" = target.ckey,
		"ref" = REF(target),
		"job" = target.job,
		"mob_type" = "[target.type]",
		"has_client" = !!target.client,
		"rank" = target.client?.holder?.rank || "Player",
		"playtime" = target.client?.get_exp_living() || "Unknown",
		"first_seen" = target.client?.player_join_date || "Unknown",
		"account_date" = target.client?.account_join_date || "Unknown",
		"byond_version" = target.client?.byond_version ? "[target.client.byond_version].[target.client.byond_build || "xxx"]" : "Unknown",
		"antag_rep" = SSpersistence.antag_rep[target.ckey] || 0,
		"is_new_player" = isnewplayer(target),
		"is_human" = ishuman(target),
		"is_monkey" = ismonkey(target),
		"is_corgi" = iscorgi(target),
		"is_ai" = isAI(target),
		"is_cyborg" = iscyborg(target),
		"is_animal" = isanimal(target),
		"has_mind" = !!target.mind,
		"muted_ic" = target.client?.prefs?.muted & MUTE_IC,
		"muted_ooc" = target.client?.prefs?.muted & MUTE_OOC,
		"muted_pray" = target.client?.prefs?.muted & MUTE_PRAY,
		"muted_adminhelp" = target.client?.prefs?.muted & MUTE_ADMINHELP,
		"muted_deadchat" = target.client?.prefs?.muted & MUTE_DEADCHAT,
		"muted_all" = target.client?.prefs?.muted & MUTE_ALL,
		"jobban_ooc" = jobban_isbanned(target, "OOC"),
		"jobban_looc" = jobban_isbanned(target, "LOOC"),
		"jobban_emote" = jobban_isbanned(target, "emote"),
	)

/datum/individual_player_panel/ui_act(action, params)
	if(..())
		return
	
	if(!holder || !target)
		return
	
	var/ref = "[REF(holder)];[HrefToken()]"
	var/ref_mob = REF(target)
	
	switch(action)
		if("view_vars")
			owner.debug_variables_tgui(target)
		if("traitor_panel")
			usr.client << link("?src=[ref];traitor=[ref_mob]")
		if("private_message")
			owner.cmd_admin_pm(params["ckey"])
		if("subtle_message")
			usr.client << link("?src=[ref];subtlemessage=[ref_mob]")
		if("follow")
			usr.client << link("?src=[ref];adminplayerobservefollow=[ref_mob]")
		if("logs")
			var/source = target.client ? LOGSRC_CLIENT : LOGSRC_MOB
			usr.client << link("?src=[ref];individuallog=[ref_mob];log_src=[source]")
		if("add_rep")
			usr.client << link("?src=[ref];modantagrep=add;mob=[ref_mob]")
		if("sub_rep")
			usr.client << link("?src=[ref];modantagrep=subtract;mob=[ref_mob]")
		if("set_rep")
			usr.client << link("?src=[ref];modantagrep=set;mob=[ref_mob]")
		if("zero_rep")
			usr.client << link("?src=[ref];modantagrep=zero;mob=[ref_mob]")
		if("kick")
			usr.client << link("?src=[ref];boot2=[ref_mob]")
		if("ban")
			usr.client << link("?src=[ref];newban=[ref_mob]")
		if("jobban")
			usr.client << link("?src=[ref];jobban2=[ref_mob]")
		if("identity_ban")
			usr.client << link("?src=[ref];appearanceban=[ref_mob]")
		if("mute")
			var/mute_type
			switch(params["type"])
				if("ic") mute_type = MUTE_IC
				if("ooc") mute_type = MUTE_OOC
				if("pray") mute_type = MUTE_PRAY
				if("adminhelp") mute_type = MUTE_ADMINHELP
				if("deadchat") mute_type = MUTE_DEADCHAT
				if("all") mute_type = MUTE_ALL
			usr.client << link("?src=[ref];mute=[target.ckey];mute_type=[mute_type]")
		if("notes")
			usr.client << link("?src=[ref];showmessageckey=[target.ckey]")
		if("prison")
			usr.client << link("?src=[ref];sendtoprison=[ref_mob]")
		if("lobby")
			usr.client << link("?src=[ref];sendbacktolobby=[ref_mob]")
		if("jump_to")
			usr.client << link("?src=[ref];jumpto=[ref_mob]")
		if("get")
			usr.client << link("?src=[ref];getmob=[ref_mob]")
		if("send_to")
			usr.client << link("?src=[ref];sendmob=[ref_mob]")
		if("heal")
			usr.client << link("?src=[ref];revive=[ref_mob]")
		if("sleep")
			usr.client << link("?src=[ref];sleep=[ref_mob]")
		if("transform")
			var/t_type = params["type"]
			switch(t_type)
				if("human") usr.client << link("?src=[ref];humanone=[ref_mob]")
				if("monkey") usr.client << link("?src=[ref];monkeyone=[ref_mob]")
				if("corgi") usr.client << link("?src=[ref];corgione=[ref_mob]")
				if("ai") usr.client << link("?src=[ref];makeai=[ref_mob]")
				if("cyborg") usr.client << link("?src=[ref];makerobot=[ref_mob]")
		if("simple_make")
			var/s_type = params["type"]
			usr.client << link("?src=[ref];simplemake=[s_type];mob=[ref_mob]")
		if("force_speech")
			usr.client << link("?src=[ref];forcespeech=[ref_mob]")
		if("narrate")
			usr.client << link("?src=[ref];narrateto=[ref_mob]")
		if("tdome")
			var/which = params["which"]
			if(which == "1") usr.client << link("?src=[ref];tdome1=[ref_mob]")
			else if(which == "2") usr.client << link("?src=[ref];tdome2=[ref_mob]")
	
	return TRUE

/datum/admins/proc/show_player_panel_tgui(mob/M)
	if(!check_rights(R_ADMIN))
		return
	
	if(QDELETED(M))
		to_chat(usr, span_warning("Target no longer exists."), confidential = TRUE)
		return
	
	log_admin("[key_name(usr)] opened individual player panel (TGUI) for [key_name(M)].")
	var/datum/individual_player_panel/panel = new(usr.client, M)
	panel.ui_interact(usr)
