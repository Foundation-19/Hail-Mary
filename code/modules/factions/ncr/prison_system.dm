// NCR Prison System
// Arrest, sentencing, and incarceration mechanics

GLOBAL_LIST_EMPTY(ncr_prisoners)
GLOBAL_LIST_EMPTY(ncr_parolees)
GLOBAL_LIST_EMPTY(ncr_escapees)

// ============ PRISON TERMINAL ============

/obj/machinery/prison_terminal/ncr
	name = "NCR Prison Terminal"
	desc = "A terminal for managing the NCR Correctional Facility."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	req_access = list(ACCESS_NCR)
	density = FALSE
	anchored = TRUE

	var/datum/prison_manager/manager

/obj/machinery/prison_terminal/ncr/Initialize()
	. = ..()
	manager = new /datum/prison_manager(src)

/obj/machinery/prison_terminal/ncr/Destroy()
	QDEL_NULL(manager)
	return ..()

/obj/machinery/prison_terminal/ncr/attack_hand(mob/user)
	if(!allowed(user))
		to_chat(user, span_warning("Access denied. NCR personnel only."))
		return
	ui_interact(user)

/obj/machinery/prison_terminal/ncr/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PrisonManagement")
		ui.open()

/obj/machinery/prison_terminal/ncr/ui_data(mob/user)
	return manager ? manager.get_ui_data(user) : list()

/obj/machinery/prison_terminal/ncr/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	if(!manager)
		return FALSE

	. = manager.handle_action(action, params, usr)

// ============ PRISON MANAGER ============

/datum/prison_manager
	var/obj/machinery/prison_terminal/ncr/owner
	var/list/prisoners = list()
	var/list/escape_alerts = list()
	var/list/available_cells = list()

/datum/prison_manager/New(obj/machinery/prison_terminal/ncr/terminal)
	owner = terminal
	GLOB.ncr_prisoners = prisoners
	find_available_cells()

/datum/prison_manager/proc/find_available_cells()
	available_cells = list()
	for(var/obj/structure/prison_cell/cell in world)
		if(!cell.prisoner_ckey)
			available_cells += cell

/datum/prison_manager/proc/get_ui_data(mob/user)
	var/list/data = list()

	data["is_law_enforcement"] = is_law_enforcement(user)
	data["is_judge"] = is_judge(user)
	data["is_ranger"] = is_ranger(user)

	var/datum/prisoner_record/my_record = get_prisoner_record(user.ckey)
	if(my_record)
		data["my_status"] = my_record.get_ui_data()

	var/list/prisoners_data = list()
	for(var/datum/prisoner_record/record as anything in prisoners)
		prisoners_data += list(record.get_ui_data())
	data["prisoners"] = prisoners_data

	data["escape_alerts"] = escape_alerts

	return data

/datum/prison_manager/proc/handle_action(action, list/params, mob/user)
	switch(action)
		if("arrest_player")
			return arrest_player(user, params)
		if("release_prisoner")
			return release_prisoner(user, params)
		if("offer_parole")
			return offer_parole(user, params)
		if("add_time")
			return add_time(user, params)
		if("work_detail")
			return start_work_detail(user)
		if("attempt_escape")
			return attempt_escape(user)
		if("request_parole")
			return request_parole(user)
		if("track_escapee")
			return track_escapee(user, params)

	return FALSE

/datum/prison_manager/proc/is_law_enforcement(mob/user)
	if(!user.mind || !user.mind.assigned_role)
		return FALSE
	return user.mind.assigned_role in list("NCR Trooper", "NCR Sergeant", "NCR Lieutenant", "NCR Captain", "NCR Ranger", "Veteran Ranger", "NCR Military Police")

/datum/prison_manager/proc/is_judge(mob/user)
	if(!user.mind || !user.mind.assigned_role)
		return FALSE
	return user.mind.assigned_role in list("NCR Captain", "NCR Lieutenant")

/datum/prison_manager/proc/is_ranger(mob/user)
	if(!user.mind || !user.mind.assigned_role)
		return FALSE
	return user.mind.assigned_role in list("NCR Ranger", "Veteran Ranger")

/datum/prison_manager/proc/get_prisoner_record(ckey)
	for(var/datum/prisoner_record/record as anything in prisoners)
		if(record.prisoner_ckey == ckey)
			return record
	return null

/datum/prison_manager/proc/arrest_player(mob/user, list/params)
	if(!is_law_enforcement(user))
		return FALSE

	var/target_ckey = ckey(params["target_ckey"])
	var/crime = params["crime"]

	if(!target_ckey || !crime)
		return FALSE

	var/mob/living/carbon/human/target = get_mob_by_ckey(target_ckey)
	if(!target)
		to_chat(user, span_warning("Cannot find player with that name."))
		return FALSE

	if(!istype(target))
		to_chat(user, span_warning("Target must be a human."))
		return FALSE

	if(get_prisoner_record(target_ckey))
		to_chat(user, span_warning("That player is already incarcerated."))
		return FALSE

	find_available_cells()
	if(!available_cells.len)
		to_chat(user, span_warning("No available prison cells!"))
		return FALSE

	var/sentence_minutes = get_sentence_time(crime)
	if(!sentence_minutes)
		to_chat(user, span_warning("Invalid crime type."))
		return FALSE

	var/obj/structure/prison_cell/cell = available_cells[1]
	available_cells -= cell

	var/datum/prisoner_record/record = new()
	record.prisoner_ckey = target_ckey
	record.prisoner_name = target.real_name
	record.crime = crime
	record.sentence_minutes = sentence_minutes
	record.arresting_officer = user.real_name
	record.arrested_at = world.time
	record.status = NCR_PRISONER_STATUS_INCARCERATED

	prisoners += record
	GLOB.ncr_prisoners = prisoners

	cell.insert_prisoner(target, record)

	to_chat(user, span_notice("Arrested [target.real_name] for [crime]. Sentence: [sentence_minutes] minutes."))
	to_chat(user, span_notice("Prisoner placed in cell at [get_area_name(cell)]."))

	adjust_faction_reputation(user.ckey, "ncr", 1)

	return TRUE

/datum/prison_manager/proc/get_sentence_time(crime)
	switch(crime)
		if(NCR_CRIME_TRESPASSING)
			return NCR_SENTENCE_TRESPASSING
		if(NCR_CRIME_THEFT)
			return NCR_SENTENCE_THEFT
		if(NCR_CRIME_ASSAULT)
			return NCR_SENTENCE_ASSAULT
		if(NCR_CRIME_MURDER)
			return NCR_SENTENCE_MURDER
	return 0

/datum/prison_manager/proc/release_prisoner(mob/user, list/params)
	if(!is_law_enforcement(user))
		return FALSE

	var/target_ckey = params["target_ckey"]
	if(!target_ckey)
		return FALSE

	var/datum/prisoner_record/record = get_prisoner_record(target_ckey)
	if(!record)
		return FALSE

	record.status = NCR_PRISONER_STATUS_RELEASED

	var/mob/prisoner = get_mob_by_ckey(target_ckey)
	if(prisoner)
		to_chat(prisoner, span_notice("You have been released from NCR custody."))

	prisoners -= record
	STOP_PROCESSING(SSobj, record)
	qdel(record)

	return TRUE

/datum/prison_manager/proc/offer_parole(mob/user, list/params)
	if(!is_judge(user))
		return FALSE

	var/target_ckey = params["target_ckey"]
	if(!target_ckey)
		return FALSE

	var/datum/prisoner_record/record = get_prisoner_record(target_ckey)
	if(!record)
		return FALSE

	if(record.time_served < record.sentence_minutes / 2)
		to_chat(user, span_warning("Prisoner not eligible for parole yet."))
		return FALSE

	if(record.escape_attempts > 0)
		to_chat(user, span_warning("Prisoner has escape attempts - parole denied."))
		return FALSE

	record.status = NCR_PRISONER_STATUS_PAROLED
	record.parole_officer = user.ckey

	var/mob/prisoner = get_mob_by_ckey(target_ckey)
	if(prisoner)
		to_chat(prisoner, span_notice("You have been granted parole. Do not violate the conditions."))

	prisoners -= record
	GLOB.ncr_parolees += list(record)

	STOP_PROCESSING(SSobj, record)

	return TRUE

/datum/prison_manager/proc/add_time(mob/user, list/params)
	if(!is_law_enforcement(user))
		return FALSE

	var/target_ckey = params["target_ckey"]
	var/additional_time = text2num(params["time"])

	if(!target_ckey || !additional_time)
		return FALSE

	var/datum/prisoner_record/record = get_prisoner_record(target_ckey)
	if(!record)
		return FALSE

	record.sentence_minutes = min(record.sentence_minutes + additional_time, NCR_PRISON_MAX_SENTENCE / (1 MINUTES))

	var/mob/prisoner = get_mob_by_ckey(target_ckey)
	if(prisoner)
		to_chat(prisoner, span_warning("[additional_time] minutes added to your sentence."))

	return TRUE

/datum/prison_manager/proc/start_work_detail(mob/user)
	var/datum/prisoner_record/record = get_prisoner_record(user.ckey)
	if(!record)
		return FALSE

	if(record.working)
		to_chat(user, span_warning("You are already working."))
		return FALSE

	record.working = TRUE
	record.work_start_time = world.time

	to_chat(user, span_notice("You begin working. [NCR_PRISON_WORK_REDUCTION / (1 MINUTES)] minutes will be reduced from your sentence every [NCR_PRISON_WORK_TIME / (1 MINUTES)] minutes."))

	addtimer(CALLBACK(record, PROC_REF(complete_work_session)), NCR_PRISON_WORK_TIME)

	return TRUE

/datum/prison_manager/proc/attempt_escape(mob/user)
	var/datum/prisoner_record/record = get_prisoner_record(user.ckey)
	if(!record)
		return FALSE

	var/success_chance = 40

	if(prob(success_chance))
		record.status = NCR_PRISONER_STATUS_ESCAPED
		record.sentence_minutes += NCR_PRISON_ESCAPE_BONUS / (1 MINUTES)

		prisoners -= record
		GLOB.ncr_escapees += list(record)

		escape_alerts += list(list(
			"ckey" = record.prisoner_ckey,
			"name" = record.prisoner_name,
			"last_seen" = get_area_name(user),
			"time" = world.time,
		))

		to_chat(user, span_userdanger("You escaped! But you are now wanted by the NCR!"))

		var/mob/living/carbon/human/H = user
		if(istype(H))
			var/obj/item/stack/f13Cash/caps/bounty = new(get_turf(H))
			bounty.amount = min(record.sentence_minutes * 5, 300)

		STOP_PROCESSING(SSobj, record)

		notify_escape(record)
	else
		record.escape_attempts++
		record.sentence_minutes += NCR_PRISON_ESCAPE_BONUS / (1 MINUTES)
		to_chat(user, span_warning("Escape attempt failed! [NCR_PRISON_ESCAPE_BONUS / (1 MINUTES)] minutes added to your sentence."))

	return TRUE

/datum/prison_manager/proc/request_parole(mob/user)
	var/datum/prisoner_record/record = get_prisoner_record(user.ckey)
	if(!record)
		return FALSE

	if(record.parole_requested)
		to_chat(user, span warning("You have already requested parole."))
		return FALSE

	if(record.time_served < record.sentence_minutes / 2)
		to_chat(user, span warning("Not eligible for parole yet. Serve at least 50% of your sentence."))
		return FALSE

	if(record.escape_attempts > 0)
		to_chat(user, span warning("Prisoners with escape attempts are not eligible for parole."))
		return FALSE

	record.parole_requested = TRUE
	to_chat(user, span notice("Parole request submitted. Wait for a judge to review."))

	for(var/mob/M in GLOB.player_list)
		if(M.client && M.mind && (M.mind.assigned_role in list("NCR Captain", "NCR Lieutenant")))
			to_chat(M, span notice("Parole request received from [record.prisoner_name]."))

	return TRUE

/datum/prison_manager/proc/track_escapee(mob/user, list/params)
	if(!is_ranger(user))
		return FALSE

	var/target_ckey = params["target_ckey"]
	if(!target_ckey)
		return FALSE

	for(var/datum/prisoner_record/record in GLOB.ncr_escapees)
		if(record.prisoner_ckey == target_ckey)
			var/mob/escapee = get_mob_by_ckey(target_ckey)
			if(escapee)
				var/dir_text = get_dir_text(user, escapee)
				var/dist = get_dist(user, escapee)
				to_chat(user, span notice("Tracking [record.prisoner_name]: [dir_text], approximately [dist] meters away."))
			else
				to_chat(user, span warning("Cannot locate [record.prisoner_name]. They may be logged out."))
			return TRUE

	return FALSE

/datum/prison_manager/proc/notify_escape(datum/prisoner_record/record)
	for(var/mob/M in GLOB.player_list)
		if(M.client && M.mind && is_law_enforcement(M))
			to_chat(M, span_alert("PRISONER ESCAPE: [record.prisoner_name] has escaped from custody!"))

// ============ PRISONER RECORD ============

/datum/prisoner_record
	var/prisoner_ckey
	var/prisoner_name
	var/crime
	var/sentence_minutes = 0
	var/time_served = 0
	var/status = NCR_PRISONER_STATUS_INCARCERATED
	var/arresting_officer
	var/arrested_at
	var/escape_attempts = 0
	var/parole_requested = FALSE
	var/parole_officer

	var/working = FALSE
	var/work_start_time = 0

/datum/prisoner_record/process()
	if(status != NCR_PRISONER_STATUS_INCARCERATED)
		return PROCESSING_KILL

	time_served += 1 / 60

	if(time_served >= sentence_minutes)
		auto_release()
		return PROCESSING_KILL

	if(time_served >= sentence_minutes * 0.67 && escape_attempts == 0)
		apply_good_behavior()

/datum/prisoner_record/proc/auto_release()
	status = NCR_PRISONER_STATUS_RELEASED

	var/mob/prisoner = get_mob_by_ckey(prisoner_ckey)
	if(prisoner)
		to_chat(prisoner, span_notice("You have served your sentence. You are now free."))

	GLOB.ncr_prisoners -= src

/datum/prisoner_record/proc/apply_good_behavior()
	sentence_minutes = sentence_minutes * 0.67

	var/mob/prisoner = get_mob_by_ckey(prisoner_ckey)
	if(prisoner)
		to_chat(prisoner, span_notice("Good behavior reduction applied."))

/datum/prisoner_record/proc/complete_work_session()
	if(!working)
		return

	working = FALSE
	sentence_minutes -= NCR_PRISON_WORK_REDUCTION / (1 MINUTES)

	var/mob/prisoner = get_mob_by_ckey(prisoner_ckey)
	if(prisoner)
		to_chat(prisoner, span notice("Work completed. [NCR_PRISON_WORK_REDUCTION / (1 MINUTES)] minutes reduced from sentence."))

/datum/prisoner_record/proc/get_ui_data()
	return list(
		"prisoner_ckey" = prisoner_ckey,
		"prisoner_name" = prisoner_name,
		"crime" = crime,
		"sentence_minutes" = sentence_minutes,
		"time_served" = round(time_served, 0.1),
		"time_remaining" = max(0, round(sentence_minutes - time_served, 0.1)),
		"status" = status,
		"arresting_officer" = arresting_officer,
		"escape_attempts" = escape_attempts,
		"parole_eligible" = (time_served >= sentence_minutes / 2) && (escape_attempts == 0),
		"parole_requested" = parole_requested,
	)

// ============ HELPER PROCS ============

/proc/get_dir_text(mob/user, mob/target)
	var/dir = get_dir(user, target)
	switch(dir)
		if(NORTH)
			return "north"
		if(SOUTH)
			return "south"
		if(EAST)
			return "east"
		if(WEST)
			return "west"
		if(NORTHEAST)
			return "northeast"
		if(NORTHWEST)
			return "northwest"
		if(SOUTHEAST)
			return "southeast"
		if(SOUTHWEST)
			return "southwest"
	return "unknown direction"
