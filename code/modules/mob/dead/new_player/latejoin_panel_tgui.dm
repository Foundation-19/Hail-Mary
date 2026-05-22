/datum/latejoin_panel
	var/client/owner

/datum/latejoin_panel/New(client/C)
	owner = C

/datum/latejoin_panel/Destroy()
	owner = null
	return ..()

/datum/latejoin_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/latejoin_panel/ui_close(mob/user)
	var/mob/dead/new_player/np = user
	if(istype(np))
		addtimer(CALLBACK(np, TYPE_PROC_REF(/mob/dead/new_player, new_player_panel)), 1)

/datum/latejoin_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LateJoin")
		ui.open()

/datum/latejoin_panel/ui_data(mob/user)
	var/list/data = list()
	
	data["round_duration"] = DisplayTimeText(world.time - SSticker.round_start_time)
	
	if(SSshuttle.emergency)
		switch(SSshuttle.emergency.mode)
			if(SHUTTLE_ESCAPE)
				data["evacuation_status"] = "The area has been evacuated."
			if(SHUTTLE_CALL)
				if(!SSshuttle.canRecall())
					data["evacuation_status"] = "The area is currently undergoing evacuation procedures."
	
	data["factions"] = list()
	
	var/mob/dead/new_player/np = user
	if(!istype(np))
		return data
	
	for(var/category in GLOB.position_categories)
		var/list/jobs_in_cat = GLOB.position_categories[category]["jobs"]
		var/list/faction_data = list()
		faction_data["name"] = category
		faction_data["jobs"] = list()
		
		for(var/job_title in jobs_in_cat)
			var/datum/job/job_datum = SSjob.name_occupations[job_title]
			if(!job_datum)
				continue
			
			var/list/job_data = list()
			job_data["title"] = job_datum.title
			job_data["current"] = job_datum.current_positions
			job_data["total"] = job_datum.total_positions
			
			var/availability = np.IsJobUnavailable(job_datum.title, TRUE)
			
			if(availability == JOB_AVAILABLE)
				job_data["available"] = TRUE
				job_data["locked"] = FALSE
			else
				job_data["available"] = FALSE
				job_data["locked"] = TRUE
				
				var/lock_reason = ""
				switch(availability)
					if(JOB_UNAVAILABLE_BANNED)
						lock_reason = "You are banned from this job."
					if(JOB_UNAVAILABLE_PLAYTIME)
						var/remaining = job_datum.required_playtime_remaining(owner)
						if(remaining)
							lock_reason = "Need [get_exp_format(remaining)] more playtime."
					if(JOB_UNAVAILABLE_ACCOUNTAGE)
						lock_reason = "Account too young."
					if(JOB_UNAVAILABLE_SLOTFULL)
						job_data["available"] = FALSE
						job_data["locked"] = FALSE
						lock_reason = "Position filled."
					if(JOB_UNAVAILABLE_SPECIESLOCK)
						lock_reason = "Species not allowed."
					if(JOB_UNAVAILABLE_WHITELIST)
						lock_reason = "Whitelist required."
					if(JOB_UNAVAILABLE_SPECIAL)
						lock_reason = "SPECIAL requirements not met."
					else
						lock_reason = "Unavailable."
				
				job_data["lock_reason"] = lock_reason
			
			faction_data["jobs"] += list(job_data)
		
		if(length(faction_data["jobs"]))
			data["factions"] += list(faction_data)
	
	return data

/datum/latejoin_panel/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	
	var/mob/dead/new_player/np = usr
	if(!istype(np))
		return
	
	switch(action)
		if("close")
			SStgui.close_uis(src)
			if(istype(np))
				np.new_player_panel()
			return TRUE
		
		if("join_job")
			var/job = params["job"]
			if(!job)
				return
			
			if(!SSticker || !SSticker.IsRoundInProgress())
				to_chat(usr, span_danger("The round is either not ready, or has already finished..."))
				return
			
			if(!GLOB.enter_allowed)
				to_chat(usr, span_notice("There is an administrative lock on entering the game!"))
				return
			
			if((length_char(owner?.prefs?.features?["flavor_text"])) < MIN_FLAVOR_LEN)
				alert(usr, "Your flavor text must be at least [MIN_FLAVOR_LEN] characters. Please edit your character in the Character Creator.", "Flavor Text Required")
				SStgui.close_uis(src)
				if(istype(np))
					np.new_player_panel()
				return TRUE
			
			SStgui.close_uis(src)
			np.AttemptLateSpawn(job)
			return TRUE
	
	return FALSE
