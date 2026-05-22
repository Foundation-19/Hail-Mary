// BOS Codex Enforcement System
// Rules, violations, and trials

GLOBAL_LIST_EMPTY(codex_records)
GLOBAL_LIST_EMPTY(codex_violations)
GLOBAL_LIST_EMPTY(codex_rules)

// ============ CODEX TERMINAL ============

/obj/machinery/codex_terminal
	name = "Brotherhood Codex Terminal"
	desc = "A terminal for accessing the Brotherhood Codex and reporting violations."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	req_access = list(ACCESS_BOS)
	density = FALSE
	anchored = TRUE

	var/datum/codex_manager/manager

/obj/machinery/codex_terminal/Initialize()
	. = ..()
	manager = new /datum/codex_manager(src)
	InitializeCodexRules()

/obj/machinery/codex_terminal/Destroy()
	QDEL_NULL(manager)
	return ..()

/obj/machinery/codex_terminal/attack_hand(mob/user)
	if(!allowed(user))
		to_chat(user, span_warning("Access denied. Brotherhood personnel only."))
		return
	ui_interact(user)

/obj/machinery/codex_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CodexTerminal")
		ui.open()

/obj/machinery/codex_terminal/ui_data(mob/user)
	return manager ? manager.get_ui_data(user) : list()

/obj/machinery/codex_terminal/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	if(!manager)
		return FALSE

	. = manager.handle_action(action, params, usr)

// ============ CODEX MANAGER ============

/datum/codex_manager
	var/obj/machinery/codex_terminal/owner

/datum/codex_manager/New(obj/machinery/codex_terminal/terminal)
	owner = terminal

/datum/codex_manager/proc/get_ui_data(mob/user)
	var/list/data = list()

	var/datum/codex_record/record = get_record(user.ckey)
	if(!record)
		record = new /datum/codex_record(user.ckey)
		GLOB.codex_records += record

	data["user_record"] = record.get_ui_data()
	data["is_elder"] = is_elder(user)
	data["is_command"] = is_command(user)

	var/list/rules = list()
	for(var/datum/codex_rule/rule as anything in GLOB.codex_rules)
		rules += list(rule.get_ui_data())
	data["rules"] = rules

	var/list/pending_cases = list()
	for(var/datum/codex_violation/violation as anything in GLOB.codex_violations)
		if(violation.status == "pending")
			pending_cases += list(violation.get_ui_data())
	data["pending_cases"] = pending_cases

	var/list/recent_violations = list()
	for(var/datum/codex_violation/violation as anything in GLOB.codex_violations)
		if(violation.violator_ckey == user.ckey && violation.status != "dismissed")
			recent_violations += list(violation.get_ui_data())
	data["recent_violations"] = recent_violations

	return data

/datum/codex_manager/proc/get_record(ckey)
	for(var/datum/codex_record/R as anything in GLOB.codex_records)
		if(R.ckey == ckey)
			return R
	return null

/datum/codex_manager/proc/is_elder(mob/user)
	if(!user.mind)
		return FALSE
	return user.mind.assigned_role == "Elder"

/datum/codex_manager/proc/is_command(mob/user)
	if(!user.mind)
		return FALSE
	return user.mind.assigned_role in list("Elder", "Head Paladin", "Paladin Commander", "Head Scribe")

/datum/codex_manager/proc/handle_action(action, list/params, mob/user)
	switch(action)
		if("report_violation")
			return report_violation(user, params)
		if("review_case")
			return review_case(user, params)
		if("punish_case")
			return punish_case(user, params)
		if("dismiss_case")
			return dismiss_case(user, params)
		if("exile_player")
			return exile_player(user, params)

	return FALSE

/datum/codex_manager/proc/report_violation(mob/user, list/params)
	if(!is_command(user))
		to_chat(user, span_warning("Only command staff can report violations."))
		return FALSE

	var/rule_id = params["rule_id"]
	var/accused = params["accused"]
	var/evidence = params["evidence"]

	if(!rule_id || !accused)
		return FALSE

	var/datum/codex_rule/rule
	for(var/datum/codex_rule/R as anything in GLOB.codex_rules)
		if(R.id == rule_id)
			rule = R
			break

	if(!rule)
		return FALSE

	var/datum/codex_violation/violation = new /datum/codex_violation(
		accused,
		rule_id,
		user.ckey,
		evidence
	)
	GLOB.codex_violations += violation

	to_chat(user, span_notice("Violation reported successfully."))

	return TRUE

/datum/codex_manager/proc/review_case(mob/user, list/params)
	if(!is_elder(user))
		to_chat(user, span_warning("Only Elders can review cases."))
		return FALSE

	var/violation_id = params["violation_id"]
	if(!violation_id)
		return FALSE

	for(var/datum/codex_violation/V as anything in GLOB.codex_violations)
		if(V.id == violation_id)
			V.status = "reviewed"
			to_chat(user, span_notice("Case marked as reviewed."))
			return TRUE

	return FALSE

/datum/codex_manager/proc/punish_case(mob/user, list/params)
	if(!is_elder(user))
		to_chat(user, span_warning("Only Elders can punish cases."))
		return FALSE

	var/violation_id = params["violation_id"]
	var/punishment = params["punishment"]

	if(!violation_id)
		return FALSE

	for(var/datum/codex_violation/V as anything in GLOB.codex_violations)
		if(V.id == violation_id)
			V.status = "punished"
			V.punishment_applied = punishment

			var/datum/codex_record/record = get_record(V.violator_ckey)
			if(record)
				record.strikes++
				record.violations += V.id

				if(record.strikes >= 5)
					record.status = "exiled"

			to_chat(user, span_notice("Punishment applied."))

			var/mob/violator = get_mob_by_ckey(V.violator_ckey)
			if(violator)
				to_chat(violator, span_danger("You have been punished for a Codex violation: [punishment]"))

			return TRUE

	return FALSE

/datum/codex_manager/proc/dismiss_case(mob/user, list/params)
	if(!is_elder(user))
		to_chat(user, span_warning("Only Elders can dismiss cases."))
		return FALSE

	var/violation_id = params["violation_id"]
	if(!violation_id)
		return FALSE

	for(var/datum/codex_violation/V as anything in GLOB.codex_violations)
		if(V.id == violation_id)
			V.status = "dismissed"
			to_chat(user, span_notice("Case dismissed."))

			var/mob/violator = get_mob_by_ckey(V.violator_ckey)
			if(violator)
				to_chat(violator, span_notice("The Codex violation against you has been dismissed."))

			return TRUE

	return FALSE

/datum/codex_manager/proc/exile_player(mob/user, list/params)
	if(!is_elder(user))
		to_chat(user, span_warning("Only Elders can exile members."))
		return FALSE

	var/target_ckey = params["target_ckey"]
	if(!target_ckey)
		return FALSE

	var/datum/codex_record/record = get_record(target_ckey)
	if(!record)
		record = new /datum/codex_record(target_ckey)
		GLOB.codex_records += record

	record.status = "exiled"
	record.strikes = 5

	to_chat(user, span_danger("[target_ckey] has been EXILED from the Brotherhood."))

	var/mob/target = get_mob_by_ckey(target_ckey)
	if(target)
		to_chat(target, span_userdanger("You have been EXILED from the Brotherhood of Steel."))

	return TRUE

/datum/codex_manager/proc/get_mob_by_ckey(ckey)
	for(var/mob/M in GLOB.mob_list)
		if(M.ckey == ckey)
			return M
	return null

// ============ CODEX RECORD ============

/datum/codex_record
	var/ckey
	var/list/violations = list()
	var/strikes = 0
	var/status = "good_standing"

/datum/codex_record/New(player_ckey)
	ckey = player_ckey

/datum/codex_record/proc/get_ui_data()
	return list(
		"ckey" = ckey,
		"strikes" = strikes,
		"status" = status,
		"status_name" = get_status_name(),
		"violation_count" = violations.len,
	)

/datum/codex_record/proc/get_status_name()
	switch(status)
		if("good_standing")
			return "Good Standing"
		if("probation")
			return "Probation"
		if("exiled")
			return "EXILED"
	return "Unknown"

// ============ CODEX VIOLATION ============

/datum/codex_violation
	var/id
	var/violator_ckey
	var/rule_id
	var/reported_by_ckey
	var/timestamp
	var/evidence = ""
	var/status = "pending"
	var/punishment_applied = ""

	var/static/next_id = 1

/datum/codex_violation/New(violator, rule, reporter, evidence_text)
	id = "violation_[next_id++]"
	violator_ckey = violator
	rule_id = rule
	reported_by_ckey = reporter
	evidence = evidence_text
	timestamp = station_time_timestamp()

/datum/codex_violation/proc/get_ui_data()
	var/datum/codex_rule/rule
	for(var/datum/codex_rule/R as anything in GLOB.codex_rules)
		if(R.id == rule_id)
			rule = R
			break

	return list(
		"id" = id,
		"violator_ckey" = violator_ckey,
		"rule_id" = rule_id,
		"rule_name" = rule ? rule.name : "Unknown",
		"reported_by" = reported_by_ckey,
		"timestamp" = timestamp,
		"evidence" = evidence,
		"status" = status,
		"punishment" = punishment_applied,
	)

// ============ CODEX RULES ============

/datum/codex_rule
	var/id
	var/name
	var/description
	var/severity = 1
	var/punishment = "Warning"

/datum/codex_rule/proc/get_ui_data()
	return list(
		"id" = id,
		"name" = name,
		"description" = description,
		"severity" = severity,
		"punishment" = punishment,
	)

/datum/codex_rule/preserve_tech
	id = "preserve_tech"
	name = "Preserve Technology"
	description = "All technology must be preserved and protected. Never destroy recoverable tech."
	severity = 2
	punishment = "Demotion, exile for repeat offenders"

/datum/codex_rule/obey_chain
	id = "obey_chain"
	name = "Obey the Chain"
	description = "Follow orders from superiors without question in the field."
	severity = 1
	punishment = "Reprimand to demotion"

/datum/codex_rule/protect_civilians
	id = "protect_civilians"
	name = "Protect Civilians"
	description = "Do not harm innocent civilians. Collateral damage is unacceptable."
	severity = 2
	punishment = "Probation, exile for severe violations"

/datum/codex_rule/no_tech_trading
	id = "no_tech_trading"
	name = "No Tech Trading"
	description = "Never sell or trade Brotherhood technology to outsiders."
	severity = 3
	punishment = "Immediate exile"

/datum/codex_rule/uphold_mission
	id = "uphold_mission"
	name = "Uphold the Mission"
	description = "Prioritize technology recovery above personal interests."
	severity = 1
	punishment = "Reprimand"

/datum/codex_rule/brotherhood_first
	id = "brotherhood_first"
	name = "Brotherhood First"
	description = "Loyalty to the Brotherhood above all other allegiances."
	severity = 2
	punishment = "Exile for severe violation"

/datum/codex_rule/maintain_secrecy
	id = "maintain_secrecy"
	name = "Maintain Secrecy"
	description = "Do not reveal Brotherhood secrets, locations, or operations to outsiders."
	severity = 2
	punishment = "Probation to exile"

/proc/InitializeCodexRules()
	if(GLOB.codex_rules.len)
		return

	GLOB.codex_rules += new /datum/codex_rule/preserve_tech()
	GLOB.codex_rules += new /datum/codex_rule/obey_chain()
	GLOB.codex_rules += new /datum/codex_rule/protect_civilians()
	GLOB.codex_rules += new /datum/codex_rule/no_tech_trading()
	GLOB.codex_rules += new /datum/codex_rule/uphold_mission()
	GLOB.codex_rules += new /datum/codex_rule/brotherhood_first()
	GLOB.codex_rules += new /datum/codex_rule/maintain_secrecy()
