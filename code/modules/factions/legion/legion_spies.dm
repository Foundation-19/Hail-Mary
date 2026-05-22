// Legion Spy Network System
// Frumentarius intelligence gathering and operations

GLOBAL_LIST_EMPTY(legion_spies)
GLOBAL_LIST_EMPTY(legion_intel_database)

// ============ LEGION SPY ============

/datum/legion_spy
	var/ckey
	var/spy_name
	var/cover_identity = ""
	var/infiltrated_faction = null
	var/cover_quality = 100
	var/suspicion_level = 0
	var/list/gathered_intel = list()
	var/last_report_time = 0
	var/active = TRUE
	var/rank = "frumentarius"

/datum/legion_spy/New(player_ckey, name)
	ckey = player_ckey
	spy_name = name
	GLOB.legion_spies += src

/datum/legion_spy/Destroy()
	GLOB.legion_spies -= src
	gathered_intel.Cut()
	return ..()

/datum/legion_spy/proc/assume_cover(faction_id)
	if(!active)
		return FALSE

	infiltrated_faction = faction_id
	cover_identity = generate_cover_identity(faction_id)
	cover_quality = 100
	suspicion_level = 0

	return TRUE

/datum/legion_spy/proc/generate_cover_identity(faction_id)
	switch(faction_id)
		if("ncr")
			return "NCR Trooper - [pick("Patrol", "Guard", "Scout")]"
		if("bos")
			return "BOS Knight - [pick("Security", "Patrol", "Scribe Assistant")]"
		if("enclave")
			return "Wastelander - Seeking refuge"
		if("town")
			return "Traveler - [pick("Merchant", "Scavenger", "Mercenary")]"
	return "Unknown"

/datum/legion_spy/proc/gather_intel(intel_type, target_info)
	if(!active || !infiltrated_faction)
		return FALSE

	var/datum/intel_report/report = new()
	report.intel_type = intel_type
	report.faction_target = infiltrated_faction
	report.value = calculate_intel_value(intel_type)
	report.report_time = world.time
	report.spy_ckey = ckey
	report.raw_info = target_info

	gathered_intel += report
	GLOB.legion_intel_database += report

	return TRUE

/datum/legion_spy/proc/calculate_intel_value(intel_type)
	switch(intel_type)
		if("personnel")
			return rand(10, 50)
		if("military")
			return rand(100, 500)
		if("economic")
			return rand(50, 200)
		if("plans")
			return rand(200, 1000)
		if("secrets")
			return rand(100, 800)
	return 10

/datum/legion_spy/proc/report_to_caesar()
	if(!active)
		return FALSE

	var/total_value = 0
	for(var/datum/intel_report/report as anything in gathered_intel)
		if(!report.submitted)
			report.submitted = TRUE
			total_value += report.value

	last_report_time = world.time

	return total_value

/datum/legion_spy/proc/maintain_cover()
	if(!active || !infiltrated_faction)
		return

	suspicion_level -= 5
	if(suspicion_level < 0)
		suspicion_level = 0

/datum/legion_spy/proc/raise_suspicion(amount)
	suspicion_level += amount

	if(suspicion_level >= 100)
		expose_spy()

/datum/legion_spy/proc/expose_spy()
	active = FALSE
	suspicion_level = 100

	var/mob/living/carbon/human/H = get_mob_by_ckey()
	if(H)
		to_chat(H, span_userdanger("Your cover has been blown! You are exposed as a Legion spy!"))

/datum/legion_spy/proc/extract()
	if(!active)
		return FALSE

	infiltrated_faction = null
	cover_identity = ""
	cover_quality = 100
	suspicion_level = 0

	var/mob/living/carbon/human/H = get_mob_by_ckey()
	if(H)
		to_chat(H, span_notice("You have been extracted and returned to Legion territory."))

	return TRUE

/datum/legion_spy/proc/get_mob_by_ckey()
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.ckey == ckey)
			return H
	return null

/datum/legion_spy/proc/get_ui_data()
	var/list/intel_data = list()
	for(var/datum/intel_report/report as anything in gathered_intel)
		if(!report.submitted)
			intel_data += list(report.get_ui_data())

	return list(
		"ckey" = ckey,
		"spy_name" = spy_name,
		"cover_identity" = cover_identity,
		"infiltrated_faction" = infiltrated_faction,
		"cover_quality" = cover_quality,
		"suspicion_level" = suspicion_level,
		"intel_gathered" = intel_data.len,
		"last_report_time" = last_report_time,
		"active" = active,
		"rank" = rank,
		"intel" = intel_data,
	)

// ============ INTEL REPORT ============

/datum/intel_report
	var/report_id
	var/intel_type
	var/faction_target
	var/value = 0
	var/accuracy = 100
	var/report_time
	var/spy_ckey
	var/raw_info = ""
	var/submitted = FALSE
	var/expired = FALSE

	var/static/next_id = 1

/datum/intel_report/New()
	report_id = "intel_[next_id++]"

/datum/intel_report/proc/get_ui_data()
	return list(
		"report_id" = report_id,
		"intel_type" = intel_type,
		"faction_target" = faction_target,
		"value" = value,
		"accuracy" = accuracy,
		"report_time" = report_time,
		"submitted" = submitted,
		"expired" = expired,
		"age_hours" = (world.time - report_time) / (1 HOUR),
	)

// ============ SPY NETWORK TERMINAL ============

/obj/machinery/computer/spy_network
	name = "Frumentarius Terminal"
	desc = "A terminal for managing Legion spy operations."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/computer/spy_network/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/spy_network/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SpyNetwork")
		ui.open()

/obj/machinery/computer/spy_network/ui_data(mob/user)
	var/list/spies_data = list()
	for(var/datum/legion_spy/spy as anything in GLOB.legion_spies)
		spies_data += list(spy.get_ui_data())

	var/list/intel_data = list()
	for(var/datum/intel_report/report as anything in GLOB.legion_intel_database)
		if(!report.expired)
			intel_data += list(report.get_ui_data())

	return list(
		"spies" = spies_data,
		"intel_database" = intel_data,
		"total_intel_value" = get_total_intel_value(),
	)

/obj/machinery/computer/spy_network/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("assume_cover")
			return handle_assume_cover(params)
		if("gather_intel")
			return handle_gather_intel(params)
		if("report_intel")
			return handle_report_intel(params)
		if("extract_spy")
			return handle_extract_spy(params)
		if("mark_intel_stale")
			return handle_mark_stale(params)

	return FALSE

/obj/machinery/computer/spy_network/proc/handle_assume_cover(list/params)
	var/spy_ckey = params["spy_ckey"]
	var/faction = params["faction"]

	for(var/datum/legion_spy/spy as anything in GLOB.legion_spies)
		if(spy.ckey == spy_ckey)
			return spy.assume_cover(faction)

	return FALSE

/obj/machinery/computer/spy_network/proc/handle_gather_intel(list/params)
	var/spy_ckey = params["spy_ckey"]
	var/intel_type = params["intel_type"]
	var/target_info = params["target_info"]

	for(var/datum/legion_spy/spy as anything in GLOB.legion_spies)
		if(spy.ckey == spy_ckey)
			return spy.gather_intel(intel_type, target_info)

	return FALSE

/obj/machinery/computer/spy_network/proc/handle_report_intel(list/params)
	var/spy_ckey = params["spy_ckey"]

	for(var/datum/legion_spy/spy as anything in GLOB.legion_spies)
		if(spy.ckey == spy_ckey)
			return spy.report_to_caesar()

	return FALSE

/obj/machinery/computer/spy_network/proc/handle_extract_spy(list/params)
	var/spy_ckey = params["spy_ckey"]

	for(var/datum/legion_spy/spy as anything in GLOB.legion_spies)
		if(spy.ckey == spy_ckey)
			return spy.extract()

	return FALSE

/obj/machinery/computer/spy_network/proc/handle_mark_stale(list/params)
	var/report_id = params["report_id"]

	for(var/datum/intel_report/report as anything in GLOB.legion_intel_database)
		if(report.report_id == report_id)
			report.expired = TRUE
			return TRUE

	return FALSE

/obj/machinery/computer/spy_network/proc/get_total_intel_value()
	var/total = 0
	for(var/datum/intel_report/report as anything in GLOB.legion_intel_database)
		if(!report.expired && report.submitted)
			total += report.value
	return total

// ============ SPY ABILITIES ============

/datum/action/spy_assume_cover
	name = "Assume Cover Identity"
	desc = "Create a cover identity to infiltrate another faction."
	button_icon_state = "spy_cover"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/spy_assume_cover/Trigger(trigger_flags)
	if(!owner)
		return FALSE

	var/datum/legion_spy/spy
	for(var/datum/legion_spy/S as anything in GLOB.legion_spies)
		if(S.ckey == owner.ckey)
			spy = S
			break

	if(!spy)
		return FALSE

	var/faction = input(owner, "Select target faction:", "Cover Identity") as null|anything in list("ncr", "bos", "enclave", "town")
	if(!faction)
		return FALSE

	if(spy.assume_cover(faction))
		to_chat(owner, span_notice("You assume a cover identity as: [spy.cover_identity]"))
		return TRUE

	return FALSE

/datum/action/spy_gather_intel
	name = "Gather Intelligence"
	desc = "Collect intelligence on current location and faction."
	button_icon_state = "spy_intel"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/spy_gather_intel/Trigger(trigger_flags)
	if(!owner)
		return FALSE

	var/datum/legion_spy/spy
	for(var/datum/legion_spy/S as anything in GLOB.legion_spies)
		if(S.ckey == owner.ckey)
			spy = S
			break

	if(!spy || !spy.infiltrated_faction)
		to_chat(owner, span_warning("You must be under cover to gather intelligence."))
		return FALSE

	var/intel_type = input(owner, "Select intelligence type:", "Gather Intel") as null|anything in list("personnel", "military", "economic", "plans", "secrets")
	if(!intel_type)
		return FALSE

	if(spy.gather_intel(intel_type, "Intel gathered at [world.time]"))
		to_chat(owner, span_notice("You gather [intel_type] intelligence."))
		spy.raise_suspicion(10)
		return TRUE

	return FALSE

/datum/action/spy_report
	name = "Report to Caesar"
	desc = "Send gathered intelligence back to Legion command."
	button_icon_state = "spy_report"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/spy_report/Trigger(trigger_flags)
	if(!owner)
		return FALSE

	var/datum/legion_spy/spy
	for(var/datum/legion_spy/S as anything in GLOB.legion_spies)
		if(S.ckey == owner.ckey)
			spy = S
			break

	if(!spy)
		return FALSE

	var/value = spy.report_to_caesar()
	if(value > 0)
		to_chat(owner, span_notice("Intelligence report submitted. Value: [value]"))
		return TRUE
	else
		to_chat(owner, span_warning("No new intelligence to report."))
		return FALSE

/datum/action/spy_sabotage
	name = "Sabotage"
	desc = "Damage enemy operations (high risk)."
	button_icon_state = "spy_sabotage"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/spy_sabotage/Trigger(trigger_flags)
	if(!owner)
		return FALSE

	var/datum/legion_spy/spy
	for(var/datum/legion_spy/S as anything in GLOB.legion_spies)
		if(S.ckey == owner.ckey)
			spy = S
			break

	if(!spy || !spy.infiltrated_faction)
		to_chat(owner, span_warning("You must be under cover to perform sabotage."))
		return FALSE

	if(prob(50))
		to_chat(owner, span_notice("Sabotage successful!"))
		spy.raise_suspicion(30)
		return TRUE
	else
		to_chat(owner, span_danger("Sabotage failed! Your cover may be blown!"))
		spy.expose_spy()
		return FALSE
