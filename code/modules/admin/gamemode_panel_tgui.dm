/datum/game_mode/dynamic/ui_state(mob/user)
	return GLOB.admin_state

/datum/game_mode/dynamic/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GameModePanel")
		ui.open()

/datum/game_mode/dynamic/ui_data(mob/user)
	. = list()
	.["mode_name"] = "Dynamic"
	.["threat_level"] = threat_level
	.["current_threat"] = threat
	.["storyteller_name"] = storyteller?.name || "Unknown"
	.["peaceful_percentage"] = peaceful_percentage
	.["forced_extended"] = GLOB.dynamic_forced_extended
	.["classic_secret"] = GLOB.dynamic_classic_secret
	.["no_stacking"] = GLOB.dynamic_no_stacking
	.["stacking_limit"] = GLOB.dynamic_stacking_limit
	.["curve_centre"] = GLOB.dynamic_curve_centre
	.["curve_width"] = GLOB.dynamic_curve_width
	
	.["executed_rules"] = list()
	for(var/datum/dynamic_ruleset/DR in executed_rules)
		.["executed_rules"] += "[DR.ruletype] - [DR.name]"
	
	var/latejoin_time = (latejoin_injection_cooldown - world.time)
	if(latejoin_time > 600)
		.["latejoin_timer"] = "[round(latejoin_time / 600, 0.1)] minutes"
	else
		.["latejoin_timer"] = "[round(latejoin_time / 10)] seconds"
	
	var/midround_time = (midround_injection_cooldown - world.time)
	if(midround_time > 600)
		.["midround_timer"] = "[round(midround_time / 600, 0.1)] minutes"
	else
		.["midround_timer"] = "[round(midround_time / 10)] seconds"

/datum/game_mode/dynamic/ui_act(action, params)
	if(..())
		return TRUE
	
	if(!check_rights(R_ADMIN))
		return TRUE
	
	switch(action)
		if("refresh")
			return TRUE
		
		if("vv_mode")
			usr.client.debug_variables(src)
			return TRUE
		
		if("adjust_threat")
			var/threatadd = input(usr, "Specify how much threat to add (negative to subtract). This can inflate the threat level.", "Adjust Threat", 0) as null|num
			if(!isnum(threatadd))
				return
			create_threat(threatadd)
			log_admin("[key_name(usr)] adjusted dynamic threat by [threatadd].")
			message_admins("[ADMIN_TPMONTY(usr)] adjusted dynamic threat by [threatadd].")
			return TRUE
		
		if("view_log")
			usr << browse(threat_log.Join("<br>"), "window=threat_log")
			return TRUE
		
		if("change_storyteller")
			var/list/storytellers = list()
			for(var/T in subtypesof(/datum/dynamic_storyteller))
				var/datum/dynamic_storyteller/S = T
				storytellers[initial(S.name)] = T
			var/choice = input(usr, "Choose a storyteller", "Storyteller", storyteller.name) as null|anything in storytellers
			if(!choice)
				return
			var/storyteller_type = storytellers[choice]
			if(storyteller_type)
				QDEL_NULL(storyteller)
				storyteller = new storyteller_type()
				log_admin("[key_name(usr)] changed the storyteller to [storyteller.name].")
				message_admins("[ADMIN_TPMONTY(usr)] changed the storyteller to [storyteller.name].")
			return TRUE
		
		if("toggle_forced_extended")
			GLOB.dynamic_forced_extended = !GLOB.dynamic_forced_extended
			log_admin("[key_name(usr)] toggled forced extended [GLOB.dynamic_forced_extended ? "ON" : "OFF"].")
			return TRUE
		
		if("toggle_classic_secret")
			GLOB.dynamic_classic_secret = !GLOB.dynamic_classic_secret
			log_admin("[key_name(usr)] toggled classic secret [GLOB.dynamic_classic_secret ? "ON" : "OFF"].")
			return TRUE
		
		if("toggle_no_stacking")
			GLOB.dynamic_no_stacking = !GLOB.dynamic_no_stacking
			log_admin("[key_name(usr)] toggled no stacking [GLOB.dynamic_no_stacking ? "ON" : "OFF"].")
			return TRUE
		
		if("adjust_stacking_limit")
			var/new_limit = input(usr, "Set stacking limit", "Stacking Limit", GLOB.dynamic_stacking_limit) as null|num
			if(!isnum(new_limit))
				return
			GLOB.dynamic_stacking_limit = new_limit
			log_admin("[key_name(usr)] set stacking limit to [new_limit].")
			return TRUE
		
		if("inject_latejoin")
			latejoin_injection_cooldown = 0
			log_admin("[key_name(usr)] triggered a latejoin injection.")
			message_admins("[ADMIN_TPMONTY(usr)] triggered a latejoin injection.")
			return TRUE
		
		if("inject_midround")
			midround_injection_cooldown = 0
			log_admin("[key_name(usr)] triggered a midround injection.")
			message_admins("[ADMIN_TPMONTY(usr)] triggered a midround injection.")
			return TRUE

	return FALSE
