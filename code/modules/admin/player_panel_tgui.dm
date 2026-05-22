/datum/player_panel
	var/client/owner
	var/datum/admins/holder

/datum/player_panel/New(client/C)
	if(!istype(C))
		qdel(src)
		CRASH("Player panel attempted to open without a valid client")
	owner = C
	holder = C.holder

/datum/player_panel/Destroy()
	owner = null
	holder = null
	return ..()

/datum/player_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/player_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PlayerPanel")
		ui.open()

/datum/player_panel/ui_data(mob/user)
	. = list()
	.["players"] = list()
	
	var/list/mobs = sortmobs()
	for(var/mob/M in mobs)
		if(!M.ckey)
			continue
		
		var/M_job = ""
		if(isliving(M))
			if(iscarbon(M))
				if(ishuman(M))
					M_job = M.job
				else if(ismonkey(M))
					M_job = "Monkey"
				else if(isalien(M))
					M_job = islarva(M) ? "Alien larva" : ROLE_ALIEN
				else
					M_job = "Carbon-based"
			else if(issilicon(M))
				if(isAI(M))
					M_job = "AI"
				else if(ispAI(M))
					M_job = ROLE_PAI
				else if(iscyborg(M))
					M_job = "Cyborg"
				else
					M_job = "Silicon-based"
			else if(isanimal(M))
				M_job = iscorgi(M) ? "Corgi" : isslime(M) ? "slime" : "Animal"
			else
				M_job = "Living"
		else if(isnewplayer(M))
			M_job = "New player"
		else if(isobserver(M))
			var/mob/dead/observer/O = M
			M_job = O.started_as_observer ? "Observer" : "Ghost"
		
		.["players"] += list(list(
			"ref" = REF(M),
			"name" = M.name,
			"real_name" = M.real_name,
			"key" = M.key,
			"job" = M_job,
			"ip" = M.lastKnownIP,
			"is_antag" = is_special_character(M)
		))

/datum/player_panel/ui_act(action, params)
	if(..())
		return
	
	if(!holder)
		return
	
	var/mob/target = locate(params["ref"])
	var/ref = "[REF(holder)];[HrefToken()]"
	
	switch(action)
		if("check_antagonists")
			usr.client << link("?src=[ref];check_antagonist=1")
		if("player_opts")
			if(target)
				holder.show_player_panel_tgui(target)
		if("view_vars")
			if(target)
				usr.client.debug_variables_tgui(target)
		if("priv_msg")
			var/ckey = params["ckey"]
			if(ckey)
				usr.client.cmd_admin_pm(ckey)
		if("follow")
			if(target)
				usr.client << link("?src=[ref];adminplayerobservefollow=[params["ref"]]")
		if("logs")
			if(target)
				usr.client << link("?src=[ref];individuallog=[params["ref"]]")
		if("traitor")
			if(target)
				usr.client << link("?src=[ref];traitor=[params["ref"]]")
	
	return TRUE

/datum/admins/proc/player_panel_tgui()
	if(!check_rights(R_ADMIN))
		message_admins("[ADMIN_TPMONTY(usr)] tried to use player_panel_tgui() without admin perms.")
		log_admin("INVALID ADMIN PROC ACCESS: [key_name(usr)] tried to use player_panel_tgui() without admin perms.")
		return
	
	log_admin("[key_name(usr)] checked the player panel (TGUI).")
	var/datum/player_panel/panel = new(usr.client)
	panel.ui_interact(usr)
