// Eastwood Sheriff & Law Enforcement
// Local law enforcement separate from NCR

// ============ SHERIFF DATUM ============

/datum/eastwood_sheriff
	var/sheriff_ckey = null
	var/sheriff_name = null
	var/list/deputies = list()
	var/list/active_warrants = list()
	var/list/arrest_records = list()
	var/list/fines_issued = list()
	var/election_time = 0

/datum/eastwood_sheriff/proc/is_sheriff(ckey)
	return sheriff_ckey == ckey

/datum/eastwood_sheriff/proc/is_deputy(ckey)
	for(var/datum/deputy_record/D in deputies)
		if(D.ckey == ckey)
			return TRUE
	return FALSE

/datum/eastwood_sheriff/proc/is_law_enforcement(ckey)
	return is_sheriff(ckey) || is_deputy(ckey)

/datum/eastwood_sheriff/proc/appoint_deputy(mob/user, target_ckey)
	if(!is_sheriff(user.ckey))
		return FALSE

	if(deputies.len >= MAX_DEPUTIES)
		return FALSE

	for(var/datum/deputy_record/D in deputies)
		if(D.ckey == target_ckey)
			return FALSE

	if(!GLOB.eastwood_council.is_citizen(target_ckey))
		return FALSE

	var/datum/deputy_record/deputy = new()
	deputy.ckey = target_ckey
	deputy.appointed_time = world.time

	var/mob/living/carbon/human/H = get_mob_by_ckey(target_ckey)
	if(H)
		deputy.name = H.name

	deputies += deputy
	return TRUE

/datum/eastwood_sheriff/proc/remove_deputy(target_ckey)
	for(var/datum/deputy_record/D in deputies)
		if(D.ckey == target_ckey)
			deputies -= D
			qdel(D)
			return TRUE
	return FALSE

/datum/eastwood_sheriff/proc/issue_warrant(target_ckey, crime, issuer_ckey)
	if(!is_law_enforcement(issuer_ckey))
		return FALSE

	for(var/datum/arrest_warrant/W in active_warrants)
		if(W.target_ckey == target_ckey)
			return FALSE

	var/datum/arrest_warrant/warrant = new()
	warrant.target_ckey = target_ckey
	warrant.crime = crime
	warrant.issuer_ckey = issuer_ckey
	warrant.issued_time = world.time

	var/mob/living/carbon/human/H = get_mob_by_ckey(target_ckey)
	if(H)
		warrant.target_name = H.name

	active_warrants += warrant
	return TRUE

/datum/eastwood_sheriff/proc/clear_warrant(target_ckey)
	for(var/datum/arrest_warrant/W in active_warrants)
		if(W.target_ckey == target_ckey)
			active_warrants -= W
			qdel(W)
			return TRUE
	return FALSE

/datum/eastwood_sheriff/proc/issue_fine(target_ckey, amount, reason, issuer_ckey)
	if(!is_law_enforcement(issuer_ckey))
		return FALSE

	var/datum/town_fine/fine = new()
	fine.target_ckey = target_ckey
	fine.amount = amount
	fine.reason = reason
	fine.issuer_ckey = issuer_ckey
	fine.issued_time = world.time

	var/mob/living/carbon/human/H = get_mob_by_ckey(target_ckey)
	if(H)
		fine.target_name = H.name

	fines_issued += fine
	return TRUE

/datum/eastwood_sheriff/proc/pay_fine(target_ckey, amount)
	for(var/datum/town_fine/F in fines_issued)
		if(F.target_ckey == target_ckey && F.amount <= amount && !F.paid)
			F.paid = TRUE
			return TRUE
	return FALSE

/datum/eastwood_sheriff/proc/arrest_criminal(mob/target, mob/officer)
	if(!is_law_enforcement(officer.ckey))
		return FALSE

	var/has_warrant = FALSE
	for(var/datum/arrest_warrant/W in active_warrants)
		if(W.target_ckey == target.ckey)
			has_warrant = TRUE
			break

	if(!has_warrant)
		return FALSE

	var/datum/arrest_record/record = new()
	record.target_ckey = target.ckey
	record.target_name = target.name
	record.arresting_officer = officer.ckey
	record.arrest_time = world.time

	arrest_records += record

	return TRUE

/datum/eastwood_sheriff/proc/get_mob_by_ckey(ckey)
	for(var/mob/M in GLOB.player_list)
		if(M.ckey == ckey)
			return M
	return null

// ============ DEPUTY RECORD ============

/datum/deputy_record
	var/ckey
	var/name
	var/appointed_time

// ============ ARREST WARRANT ============

/datum/arrest_warrant
	var/target_ckey
	var/target_name
	var/crime
	var/issuer_ckey
	var/issued_time

// ============ TOWN FINE ============

/datum/town_fine
	var/target_ckey
	var/target_name
	var/amount
	var/reason
	var/issuer_ckey
	var/issued_time
	var/paid = FALSE

// ============ ARREST RECORD ============

/datum/arrest_record
	var/target_ckey
	var/target_name
	var/arresting_officer
	var/arrest_time
	var/release_time

// ============ SHERIFF'S OFFICE CONSOLE ============

/obj/machinery/computer/sheriff_office
	name = "Sheriff's Office Terminal"
	desc = "A terminal for Eastwood law enforcement."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/sheriff_office/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/sheriff_office/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SheriffOffice")
		ui.open()

/obj/machinery/computer/sheriff_office/ui_data(mob/user)
	var/list/data = list()

	data["is_sheriff"] = GLOB.eastwood_sheriff.is_sheriff(user.ckey)
	data["is_deputy"] = GLOB.eastwood_sheriff.is_deputy(user.ckey)
	data["is_law_enforcement"] = GLOB.eastwood_sheriff.is_law_enforcement(user.ckey)
	data["sheriff_name"] = GLOB.eastwood_sheriff.sheriff_name
	data["max_deputies"] = MAX_DEPUTIES

	var/list/deputies_data = list()
	for(var/datum/deputy_record/D in GLOB.eastwood_sheriff.deputies)
		deputies_data += list(list("ckey" = D.ckey, "name" = D.name))
	data["deputies"] = deputies_data

	var/list/warrants_data = list()
	for(var/datum/arrest_warrant/W in GLOB.eastwood_sheriff.active_warrants)
		warrants_data += list(list("target_ckey" = W.target_ckey, "target_name" = W.target_name, "crime" = W.crime, "issuer_ckey" = W.issuer_ckey))
	data["active_warrants"] = warrants_data

	var/list/fines_data = list()
	for(var/datum/town_fine/F in GLOB.eastwood_sheriff.fines_issued)
		if(!F.paid)
			fines_data += list(list("target_ckey" = F.target_ckey, "target_name" = F.target_name, "amount" = F.amount, "reason" = F.reason))
	data["outstanding_fines"] = fines_data

	return data

/obj/machinery/computer/sheriff_office/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("appoint_deputy")
			var/target_ckey = params["target_ckey"]
			if(GLOB.eastwood_sheriff.appoint_deputy(usr, target_ckey))
				to_chat(usr, span_notice("Deputy appointed."))
			else
				to_chat(usr, span_warning("Cannot appoint deputy."))
			return TRUE

		if("remove_deputy")
			var/target_ckey = params["target_ckey"]
			if(GLOB.eastwood_sheriff.remove_deputy(target_ckey))
				to_chat(usr, span_notice("Deputy removed."))
			return TRUE

		if("issue_warrant")
			var/target_ckey = params["target_ckey"]
			var/crime = params["crime"]
			if(GLOB.eastwood_sheriff.issue_warrant(target_ckey, crime, usr.ckey))
				to_chat(usr, span_notice("Arrest warrant issued."))
			else
				to_chat(usr, span_warning("Cannot issue warrant."))
			return TRUE

		if("clear_warrant")
			var/target_ckey = params["target_ckey"]
			if(GLOB.eastwood_sheriff.clear_warrant(target_ckey))
				to_chat(usr, span_notice("Warrant cleared."))
			return TRUE

		if("issue_fine")
			var/target_ckey = params["target_ckey"]
			var/amount = text2num(params["amount"])
			var/reason = params["reason"]
			if(GLOB.eastwood_sheriff.issue_fine(target_ckey, amount, reason, usr.ckey))
				to_chat(usr, span_notice("Fine issued."))
			return TRUE

	return FALSE

// ============ JAIL CELL ============

/obj/structure/jail_cell
	name = "Jail Cell"
	desc = "A small holding cell for prisoners."
	icon = 'icons/obj/structures.dmi'
	icon_state = "jail_cell"
	density = FALSE
	anchored = TRUE

	var/occupant_ckey = null
	var/sentence_end = 0

/obj/structure/jail_cell/proc/incarcerate(mob/living/carbon/human/prisoner, minutes)
	if(occupant_ckey)
		return FALSE

	occupant_ckey = prisoner.ckey
	sentence_end = world.time + (minutes MINUTES)

	prisoner.forceMove(get_turf(src))

	addtimer(CALLBACK(src, .proc/release), minutes MINUTES)
	return TRUE

/obj/structure/jail_cell/proc/release()
	if(!occupant_ckey)
		return

	var/mob/living/carbon/human/H = get_prisoner()
	if(H)
		to_chat(H, span_notice("Your sentence is complete. You are free to go."))

	occupant_ckey = null
	sentence_end = 0

/obj/structure/jail_cell/proc/get_prisoner()
	if(!occupant_ckey)
		return null
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.ckey == occupant_ckey)
			return H
	return null

/obj/structure/jail_cell/proc/time_remaining()
	if(!sentence_end)
		return 0
	return max(0, sentence_end - world.time)
