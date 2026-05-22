// Enclave Genetic Screening
// Purity verification and mutant detection

// ============ GENETIC SCREENING MANAGER ============

/datum/enclave_genetic_screening
	var/list/scan_results = list()
	var/list/blacklist = list()
	var/list/citizenship_applications = list()

/datum/enclave_genetic_screening/proc/scan_target(mob/living/carbon/human/target, mob/user)
	if(!target || !istype(target))
		return null

	var/datum/genetic_scan_result/result = new()
	result.ckey = target.ckey
	result.scan_time = world.time
	result.scanned_by = user.ckey

	result.purity_rating = calculate_purity(target)
	result.mutation_type = classify_mutation(target)
	result.status = determine_status(result.purity_rating, result.mutation_type)

	scan_results += result
	GLOB.enclave_genetic_records[target.ckey] = result

	return result

/datum/enclave_genetic_screening/proc/calculate_purity(mob/living/carbon/human/target)
	var/purity = 100

	if(target.get_species() == "Ghoul")
		purity = 45
	else if(target.get_species() == "Super Mutant")
		purity = 15

	if(target.dna?.check_mutation(HULK))
		purity -= 20

	if(target.dna?.check_mutation(LASEREYES))
		purity -= 15

	if(target.radiation > 100)
		purity -= 10
	else if(target.radiation > 50)
		purity -= 5

	if(target.dna?.species?.id == "human")
		if(target.dna?.check_mutation(XRAY))
			purity -= 5

	return clamp(purity, 0, 100)

/datum/enclave_genetic_screening/proc/classify_mutation(mob/living/carbon/human/target)
	var/species = target.get_species()

	if(species == "Super Mutant")
		return "super_mutant"
	else if(species == "Ghoul")
		return "ghoul"
	else if(target.radiation > 100 || target.dna?.check_mutation(HULK))
		return "minor_mutation"
	else
		return "none"

/datum/enclave_genetic_screening/proc/determine_status(purity, mutation_type)
	switch(mutation_type)
		if("super_mutant")
			return SCREENING_TERMINATED
		if("ghoul")
			return SCREENING_QUARANTINED

	if(purity >= GENETIC_PURITY_PURE)
		return SCREENING_APPROVED
	else if(purity >= GENETIC_PURITY_WASTELANDER)
		return SCREENING_MONITORED
	else
		return SCREENING_QUARANTINED

/datum/enclave_genetic_screening/proc/get_result(ckey)
	for(var/datum/genetic_scan_result/R in scan_results)
		if(R.ckey == ckey)
			return R
	return null

/datum/enclave_genetic_screening/proc/add_to_blacklist(ckey, reason)
	blacklist[ckey] = reason

/datum/enclave_genetic_screening/proc/remove_from_blacklist(ckey)
	blacklist -= ckey

/datum/enclave_genetic_screening/proc/is_blacklisted(ckey)
	return blacklist[ckey] ? TRUE : FALSE

/datum/enclave_genetic_screening/proc/apply_citizenship(ckey)
	var/datum/citizenship_application/app = new()
	app.ckey = ckey
	app.application_time = world.time
	app.probation_end = world.time + (7 * 24 * 60 * 10)

	citizenship_applications += app

/datum/enclave_genetic_screening/proc/approve_citizenship(ckey)
	for(var/datum/citizenship_application/A in citizenship_applications)
		if(A.ckey == ckey)
			A.status = "approved"
			return TRUE
	return FALSE

/datum/enclave_genetic_screening/proc/deny_citizenship(ckey)
	for(var/datum/citizenship_application/A in citizenship_applications)
		if(A.ckey == ckey)
			A.status = "denied"
			return TRUE
	return FALSE

// ============ GENETIC SCAN RESULT DATUM ============

/datum/genetic_scan_result
	var/ckey
	var/scan_time
	var/purity_rating = 100
	var/mutation_type = "none"
	var/status = SCREENING_APPROVED
	var/scanned_by
	var/notes = ""

// ============ CITIZENSHIP APPLICATION ============

/datum/citizenship_application
	var/ckey
	var/application_time
	var/probation_end
	var/sponsor_ckey
	var/status = "pending"

// ============ GENETIC SCREENING TERMINAL ============

/obj/machinery/computer/enclave_genetic_screening
	name = "Enclave Genetic Screening Terminal"
	desc = "A terminal for genetic purity verification."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/enclave_genetic_screening/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/enclave_genetic_screening/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GeneticScreening")
		ui.open()

/obj/machinery/computer/enclave_genetic_screening/ui_data(mob/user)
	var/list/data = list()

	var/datum/genetic_scan_result/current_scan = GLOB.enclave_genetic_screening.get_result(user.ckey)
	if(current_scan)
		data["has_scan"] = TRUE
		data["my_purity"] = current_scan.purity_rating
		data["my_status"] = current_scan.status
		data["my_mutation"] = current_scan.mutation_type
	else
		data["has_scan"] = FALSE

	var/list/scan_history = list()
	for(var/datum/genetic_scan_result/R in GLOB.enclave_genetic_screening.scan_results)
		scan_history += list(list(
			"ckey" = R.ckey,
			"purity" = R.purity_rating,
			"status" = R.status,
			"mutation" = R.mutation_type,
			"time" = R.scan_time,
		))
	data["scan_history"] = scan_history

	var/list/blacklist_data = list()
	for(var/ckey in GLOB.enclave_genetic_screening.blacklist)
		blacklist_data += list(list("ckey" = ckey, "reason" = GLOB.enclave_genetic_screening.blacklist[ckey]))
	data["blacklist"] = blacklist_data

	var/list/applications_data = list()
	for(var/datum/citizenship_application/A in GLOB.enclave_genetic_screening.citizenship_applications)
		applications_data += list(list(
			"ckey" = A.ckey,
			"status" = A.status,
			"probation_remaining" = max(0, A.probation_end - world.time),
		))
	data["applications"] = applications_data

	data["scanner_status"] = "Active"

	return data

/obj/machinery/computer/enclave_genetic_screening/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("scan_self")
			var/result = GLOB.enclave_genetic_screening.scan_target(usr, usr)
			if(result)
				to_chat(usr, span_notice("Scan complete. Purity: [result.purity_rating]% - [result.status]"))
			return TRUE

		if("scan_target")
			var/mob/living/carbon/human/target = usr.pulling
			if(target && istype(target))
				var/result = GLOB.enclave_genetic_screening.scan_target(target, usr)
				if(result)
					to_chat(usr, span_notice("Scan complete. [target.name] - Purity: [result.purity_rating]% - [result.status]"))
			else
				to_chat(usr, span_warning("No valid target to scan."))
			return TRUE

		if("approve_citizenship")
			var/ckey = params["ckey"]
			GLOB.enclave_genetic_screening.approve_citizenship(ckey)
			to_chat(usr, span_notice("Citizenship approved."))
			return TRUE

		if("deny_citizenship")
			var/ckey = params["ckey"]
			GLOB.enclave_genetic_screening.deny_citizenship(ckey)
			to_chat(usr, span_notice("Citizenship denied."))
			return TRUE

		if("add_blacklist")
			var/ckey = params["ckey"]
			var/reason = params["reason"]
			GLOB.enclave_genetic_screening.add_to_blacklist(ckey, reason)
			to_chat(usr, span_notice("Added to blacklist."))
			return TRUE

		if("remove_blacklist")
			var/ckey = params["ckey"]
			GLOB.enclave_genetic_screening.remove_from_blacklist(ckey)
			to_chat(usr, span_notice("Removed from blacklist."))
			return TRUE

	return FALSE

// ============ BASE SCANNER ============

/obj/machinery/genetic_scanner_gate
	name = "Genetic Scanner Gate"
	desc = "All visitors must pass through for genetic screening."
	icon = 'icons/obj/machines/scanner.dmi'
	icon_state = "scanner_gate"
	density = FALSE
	anchored = TRUE

	var/last_scan_time = 0
	var/scan_cooldown = 5 SECONDS

/obj/machinery/genetic_scanner_gate/Crossed(atom/movable/AM)
	. = ..()

	if(world.time - last_scan_time < scan_cooldown)
		return

	if(!ishuman(AM))
		return

	var/mob/living/carbon/human/H = AM
	var/result = GLOB.enclave_genetic_screening.scan_target(H, src)

	if(result)
		switch(result.status)
			if(SCREENING_APPROVED)
				visible_message(span_notice("[H] passes genetic screening - APPROVED."))
			if(SCREENING_MONITORED)
				visible_message(span_warning("[H] passes genetic screening - MONITORED."))
			if(SCREENING_QUARANTINED)
				visible_message(span_danger("[H] flagged for QUARANTINE."))
			if(SCREENING_TERMINATED)
				visible_message(span_userdanger("[H] flagged for TERMINATION."))
				alert_security(H)

		last_scan_time = world.time

/obj/machinery/genetic_scanner_gate/proc/alert_security(mob/living/carbon/human/target)
	for(var/mob/M in GLOB.player_list)
		if(M.faction == "enclave")
			to_chat(M, span_userdanger("SECURITY ALERT: [target] flagged for termination at genetic scanner!"))

// ============ HANDHELD SCANNER ============

/obj/item/genetic_scanner_handheld
	name = "Handheld Genetic Scanner"
	desc = "A portable device for field genetic screening."
	icon = 'icons/obj/device.dmi'
	icon_state = "handheld_scanner"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/genetic_scanner_handheld/attack(mob/living/M, mob/living/user)
	if(!ishuman(M))
		return

	var/mob/living/carbon/human/H = M
	var/result = GLOB.enclave_genetic_screening.scan_target(H, user)

	if(result)
		to_chat(user, span_notice("--- GENETIC SCAN ---"))
		to_chat(user, span_notice("Subject: [H.real_name]"))
		to_chat(user, span_notice("Purity: [result.purity_rating]%"))
		to_chat(user, span_notice("Mutation: [result.mutation_type]"))
		to_chat(user, span_notice("Status: [result.status]"))

/obj/item/genetic_scanner_handheld/afterattack(atom/target, mob/user, proximity)
	if(!proximity)
		return

	if(ishuman(target))
		attack(target, user)
