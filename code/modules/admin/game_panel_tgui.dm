/datum/game_panel
	var/client/owner
	var/datum/admins/holder

/datum/game_panel/New(client/C)
	if(!istype(C))
		qdel(src)
		CRASH("Game panel attempted to open without a valid client")
	owner = C
	holder = C.holder

/datum/game_panel/Destroy()
	owner = null
	holder = null
	return ..()

/datum/game_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/game_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GamePanel")
		ui.open()

/datum/game_panel/ui_data(mob/user)
	. = list()
	.["master_mode"] = GLOB.master_mode
	.["round_started"] = SSticker.IsRoundInProgress()
	.["dynamic_options"] = list(
		"forced_rulesets" = list(),
		"forced_storyteller" = null,
		"has_latejoin_rule" = FALSE
	)
	
	if(GLOB.master_mode == "dynamic")
		for(var/datum/dynamic_ruleset/roundstart/rule in GLOB.dynamic_forced_roundstart_ruleset)
			.["dynamic_options"]["forced_rulesets"] += rule.name
		
		if(GLOB.dynamic_forced_storyteller)
			var/datum/dynamic_storyteller/S = GLOB.dynamic_forced_storyteller
			.["dynamic_options"]["forced_storyteller"] = initial(S.name)
		
		if(SSticker?.mode && istype(SSticker.mode, /datum/game_mode/dynamic))
			var/datum/game_mode/dynamic/mode = SSticker.mode
			.["dynamic_options"]["has_latejoin_rule"] = !!mode.forced_latejoin_rule

/datum/game_panel/ui_act(action, params)
	if(..())
		return
	
	if(!holder)
		return
	
	var/ref = "[REF(holder)];[HrefToken()]"
	
	switch(action)
		if("change_mode")
			usr << browse(null, "window=game_panel")
			usr.client << link("?src=[ref];c_mode=1")
		if("force_secret")
			usr << browse(null, "window=game_panel")
			usr.client << link("?src=[ref];f_secret=1")
		if("force_roundstart")
			usr << browse(null, "window=game_panel")
			usr.client << link("?src=[ref];f_dynamic_roundstart=1")
		if("force_storyteller")
			usr << browse(null, "window=game_panel")
			usr.client << link("?src=[ref];f_dynamic_storyteller=1")
		if("force_latejoin")
			usr << browse(null, "window=game_panel")
			usr.client << link("?src=[ref];f_dynamic_latejoin=1")
		if("execute_midround")
			usr << browse(null, "window=game_panel")
			usr.client << link("?src=[ref];f_dynamic_midround=1")
		if("gamemode_panel")
			if(SSticker?.mode && istype(SSticker.mode, /datum/game_mode/dynamic))
				SSticker.mode.ui_interact(usr)
				return TRUE
		if("create_object")
			holder.create_object_tgui(usr)
		if("quick_create_object")
			holder.create_object_tgui(usr)
		if("create_turf")
			holder.create_turf_tgui(usr)
		if("create_mob")
			holder.create_mob_tgui(usr)
	
	return TRUE

/datum/admins/proc/game_panel_tgui()
	if(!check_rights(0))
		return
	
	log_admin("[key_name(usr)] opened the game panel (TGUI).")
	var/datum/game_panel/panel = new(usr.client)
	panel.ui_interact(usr)
