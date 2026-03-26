GLOBAL_LIST_EMPTY(exp_to_update)
GLOBAL_PROTECT(exp_to_update)

/// Returns the compound "Faction/Tier" key for the given job title, or null if not found.
/proc/get_tier_key_for_job(title)
	for(var/tier_key in GLOB.exp_tiermap)
		if(title in GLOB.exp_tiermap[tier_key])
			return tier_key
	return null

/// Returns the total minutes still owed to access the given tier_key, per exp_tier_requirements.
/// Checks own-faction hours, Wasteland hours, and best-other-faction hours as the tier demands.
/// Returns 0 if the tier has no requirements or the faction is fully exempt.
/proc/check_tier_prereqs(client/C, tier_key)
	var/sep_pos = findtext(tier_key, EXP_TIER_SEP)
	if(!sep_pos)
		return 0
	var/faction = copytext(tier_key, 1, sep_pos)
	var/tier_name = copytext(tier_key, sep_pos + 1)
	if(faction in C.prefs.exp_type_exempt)
		return 0
	var/list/reqs = GLOB.exp_tier_requirements[tier_name]
	if(!reqs)
		return 0
	var/total_remaining = 0
	// Own-faction hours
	var/faction_req = text2num(reqs["faction"])
	if(faction_req)
		var/player_mins = _get_tier_faction_minutes(C, faction)
		if(player_mins < faction_req)
			total_remaining += faction_req - player_mins
	// Wasteland hours (skipped for Wasteland faction roles themselves — they are the entry point)
	var/wasteland_req = text2num(reqs["wasteland"])
	if(wasteland_req && faction != "Wasteland" && !("Wasteland" in C.prefs.exp_type_exempt))
		var/waster_mins = _get_tier_faction_minutes(C, "Wasteland")
		if(waster_mins < wasteland_req)
			total_remaining += wasteland_req - waster_mins
	// Best single other-faction hours
	var/other_req = text2num(reqs["other_faction"])
	if(other_req)
		var/best_other = _get_best_other_faction_minutes(C, faction)
		if(best_other < other_req)
			total_remaining += other_req - best_other
	return total_remaining

/// Sums all job minutes the client has across every tier of the given faction.
/proc/_get_tier_faction_minutes(client/C, faction)
	var/prefix = faction + EXP_TIER_SEP
	var/plen = length(prefix)
	var/total = 0
	for(var/tk in GLOB.exp_tiermap)
		if(copytext(tk, 1, plen + 1) != prefix)
			continue
		for(var/job_key in GLOB.exp_tiermap[tk])
			if(!isnull(C.prefs.exp[job_key]))
				total += text2num(C.prefs.exp[job_key])
	return total

/// Returns the highest faction-total minutes the client has in any faction except exclude_faction.
/proc/_get_best_other_faction_minutes(client/C, exclude_faction)
	var/list/seen = list()
	var/best = 0
	for(var/tk in GLOB.exp_tiermap)
		var/sep = findtext(tk, EXP_TIER_SEP)
		if(!sep)
			continue
		var/f = copytext(tk, 1, sep)
		if(f == exclude_faction || (f in seen))
			continue
		seen += f
		var/mins = _get_tier_faction_minutes(C, f)
		if(mins > best)
			best = mins
	return best

// Procs
/datum/job/proc/required_playtime_remaining(client/C)
	if(!C)
		return 0
	if(!CONFIG_GET(flag/use_exp_tracking))
		return 0
	if(!SSdbcore.Connect())
		return 0
	var/has_single_req = (exp_requirements && exp_type)
	var/has_multi_req = (multi_exp_requirements && multi_exp_requirements.len)
	if(!has_single_req && !has_multi_req)
		return 0
	if(!job_is_xp_locked(src.title))
		return 0
	if(CONFIG_GET(flag/use_exp_restrictions_admin_bypass) && check_rights_for(C,R_ADMIN))
		return 0
	var/isexempt = C.prefs.db_flags & DB_FLAG_EXEMPT
	if(isexempt)
		return 0
	var/total_remaining = 0
	if(has_single_req)
		var/req_type = get_exp_req_type()
		if(!(req_type in C.prefs.exp_type_exempt))
			var/tier_key = get_tier_key_for_job(src.title)
			if(!tier_key || !(tier_key in C.prefs.exp_type_exempt))
				var/my_exp = C.calc_exp_type(req_type)
				var/job_requirement = get_exp_req_amount()
				if(my_exp < job_requirement)
					total_remaining += job_requirement - my_exp
	if(has_multi_req)
		total_remaining += check_multi_exp_requirements(C)
	// Tier chain prerequisite: higher-tier roles require time in each lower tier first
	var/tier_key_job = get_tier_key_for_job(src.title)
	if(tier_key_job && !(tier_key_job in C.prefs.exp_type_exempt))
		total_remaining += check_tier_prereqs(C, tier_key_job)
	return total_remaining

/// Returns the total remaining minutes across all unmet multi_exp_requirements, or 0 if all are met.
/datum/job/proc/check_multi_exp_requirements(client/C)
	if(!multi_exp_requirements || !multi_exp_requirements.len)
		return 0
	var/total_remaining = 0
	var/tier_key = get_tier_key_for_job(src.title)
	for(var/req_type in multi_exp_requirements)
		if(req_type in C.prefs.exp_type_exempt)
			continue
		if(tier_key && (tier_key in C.prefs.exp_type_exempt))
			continue
		var/required_amount = multi_exp_requirements[req_type]
		var/player_exp = C.calc_exp_type(req_type)
		if(player_exp < required_amount)
			total_remaining += required_amount - player_exp
	return total_remaining

/datum/job/proc/get_exp_req_amount()
	if(title in (GLOB.command_positions | list("AI")))
		var/uerhh = CONFIG_GET(number/use_exp_restrictions_heads_hours)
		if(uerhh)
			return uerhh * 60
	return exp_requirements

/datum/job/proc/get_exp_req_type()
	if(title in (GLOB.command_positions | list("AI")))
		if(CONFIG_GET(flag/use_exp_restrictions_heads_department) && exp_type_department)
			return exp_type_department
	return exp_type

/proc/job_is_xp_locked(jobtitle)
	if(!CONFIG_GET(flag/use_exp_restrictions_heads) && (jobtitle in (GLOB.command_positions | list("AI"))))
		return FALSE
	if(!CONFIG_GET(flag/use_exp_restrictions_other) && !(jobtitle in (GLOB.command_positions | list("AI"))))
		return FALSE
	return TRUE

/client/proc/calc_exp_type(exptype)
	var/list/explist = prefs.exp.Copy()
	var/amount = 0
	var/list/typelist = GLOB.exp_jobsmap[exptype]
	if(!typelist)
		return -1
	for(var/job in typelist["titles"])
		if(job in explist)
			amount += explist[job]
	return amount

/client/proc/get_exp_report()
	if(!CONFIG_GET(flag/use_exp_tracking))
		return "Tracking is disabled in the server configuration file."
	var/list/play_records = prefs.exp
	if(!play_records.len)
		set_exp_from_db()
		play_records = prefs.exp
		if(!play_records.len)
			return "[key] has no records."
	var/return_text = list()
	return_text += "<UL>"
	var/list/exp_data = list()
	for(var/category in SSjob.name_occupations)
		if(play_records[category])
			exp_data[category] = text2num(play_records[category])
		else
			exp_data[category] = 0
	for(var/category in GLOB.exp_specialmap)
		if(category == EXP_TYPE_SPECIAL || category == EXP_TYPE_ANTAG)
			if(GLOB.exp_specialmap[category])
				for(var/innercat in GLOB.exp_specialmap[category])
					if(play_records[innercat])
						exp_data[innercat] = text2num(play_records[innercat])
					else
						exp_data[innercat] = 0
		else
			if(play_records[category])
				exp_data[category] = text2num(play_records[category])
			else
				exp_data[category] = 0
	if(prefs.db_flags & DB_FLAG_EXEMPT)
		return_text += "<LI>Exempt (all jobs auto-unlocked)</LI>"
	if(prefs.exp_type_exempt.len)
		var/list/exempt_names = list()
		for(var/et in prefs.exp_type_exempt)
			exempt_names += et
		return_text += "<LI>Per-type exempt: [exempt_names.Join(", ")]</LI>"

	for(var/dep in exp_data)
		if(exp_data[dep] > 0)
			if(exp_data[EXP_TYPE_LIVING] > 0)
				var/percentage = num2text(round(exp_data[dep]/exp_data[EXP_TYPE_LIVING]*100))
				return_text += "<LI>[dep] [get_exp_format(exp_data[dep])] ([percentage]%)</LI>"
			else
				return_text += "<LI>[dep] [get_exp_format(exp_data[dep])] </LI>"
	if(CONFIG_GET(flag/use_exp_restrictions_admin_bypass) && check_rights_for(src,R_ADMIN))
		return_text += "<LI>Commander (all jobs auto-unlocked)</LI>"
	return_text += "</UL>"
	var/list/jobs_locked = list()
	var/list/jobs_unlocked = list()
	for(var/datum/job/job in SSjob.occupations)
		var/has_single_req = (job.exp_requirements && job.exp_type)
		var/has_multi_req = (job.multi_exp_requirements && job.multi_exp_requirements.len)
		if(!has_single_req && !has_multi_req)
			continue
		if(!job_is_xp_locked(job.title))
			continue
		else if(!job.required_playtime_remaining(mob.client))
			jobs_unlocked += job.title
		else
			var/list/req_parts = list()
			if(has_single_req)
				var/xp_req = job.get_exp_req_amount()
				req_parts += "[get_exp_format(text2num(calc_exp_type(job.get_exp_req_type())))] / [get_exp_format(xp_req)] as [job.get_exp_req_type()]"
			if(has_multi_req)
				for(var/req_type in job.multi_exp_requirements)
					var/req_amount = job.multi_exp_requirements[req_type]
					req_parts += "[get_exp_format(text2num(calc_exp_type(req_type)))] / [get_exp_format(req_amount)] as [req_type]"
			jobs_locked += "[job.title] ([req_parts.Join(", ")])"
	if(jobs_unlocked.len)
		return_text += "<BR><BR>Jobs Unlocked:<UL><LI>"
		return_text += jobs_unlocked.Join("</LI><LI>")
		return_text += "</LI></UL>"
	if(jobs_locked.len)
		return_text += "<BR><BR>Jobs Not Unlocked:<UL><LI>"
		return_text += jobs_locked.Join("</LI><LI>")
		return_text += "</LI></UL>"
	return return_text


/client/proc/get_exp_living(pure_numeric = FALSE)
	if(!prefs.exp || !prefs.exp[EXP_TYPE_LIVING])
		return pure_numeric ? 0 : "No data"
	var/exp_living = text2num(prefs.exp[EXP_TYPE_LIVING])
	return pure_numeric ? exp_living : get_exp_format(exp_living)

/proc/get_exp_format(expnum)
	if(expnum > 60)
		return num2text(round(expnum / 60)) + "h"
	else if(expnum > 0)
		return num2text(expnum) + "m"
	else
		return "0h"

/datum/controller/subsystem/blackbox/proc/update_exp(mins, ann = FALSE)
	if(!SSdbcore.Connect())
		return -1
	for(var/client/L in GLOB.clients)
		if(L.is_afk())
			continue
		L.update_exp_list(mins,ann)

/datum/controller/subsystem/blackbox/proc/update_exp_db()
	set waitfor = FALSE
	var/list/old_minutes = GLOB.exp_to_update
	GLOB.exp_to_update = null
	SSdbcore.MassInsert(format_table_name("role_time"), old_minutes, duplicate_key = "ON DUPLICATE KEY UPDATE minutes = minutes + VALUES(minutes)")

/// Resets all exp entries for a given aggregate exp_type (or a direct special key) to 0 in both memory and the DB.
/// exp_type should be a key from GLOB.exp_jobsmap (e.g. EXP_TYPE_WASTELAND) or a direct DB key (e.g. EXP_TYPE_LIVING).
/// Returns TRUE on success, FALSE on any failure.
/client/proc/reset_exp_for_type(exp_type)
	if(!CONFIG_GET(flag/use_exp_tracking))
		return FALSE
	if(!SSdbcore.Connect())
		return FALSE
	if(!src || !prefs)
		return FALSE

	// Build the list of raw DB job keys to zero
	var/list/keys_to_reset = list()
	var/list/typemap = GLOB.exp_jobsmap[exp_type]
	var/list/titles = typemap ? typemap["titles"] : null
	if(titles && titles.len)
		keys_to_reset = titles.Copy()
	else
		var/list/tier_titles = GLOB.exp_tiermap[exp_type]
		if(tier_titles && tier_titles.len)
			keys_to_reset = tier_titles.Copy()
		else
			// Direct special type stored under its own DB key (Living, Ghost, Admin, etc.)
			keys_to_reset += exp_type

	// Run all DB queries first; only update in-memory after all succeed
	for(var/job_key in keys_to_reset)
		var/datum/db_query/q = SSdbcore.NewQuery(
			"UPDATE [format_table_name("role_time")] SET minutes = 0 WHERE ckey = :ckey AND job = :job",
			list("ckey" = ckey, "job" = job_key)
		)
		var/db_ok = q.Execute()
		if(!db_ok)
			var/errmsg = q.ErrorMsg()
			qdel(q)
			to_chat(usr, span_danger("DB error while resetting [job_key]: [errmsg]"))
			return FALSE
		qdel(q)
	for(var/job_key in keys_to_reset)
		prefs.exp[job_key] = 0
	return TRUE

/// Sets all hours for the given exp type to total_minutes.
/// For aggregate types, puts all minutes on the first job key and zeroes the rest.
/// Returns TRUE on success, FALSE on failure.
/client/proc/set_exp_for_type(exp_type, total_minutes)
	if(!CONFIG_GET(flag/use_exp_tracking))
		return FALSE
	if(!SSdbcore.Connect())
		return FALSE
	if(!src || !prefs)
		return FALSE

	var/list/keys_to_set = list()
	var/list/typemap = GLOB.exp_jobsmap[exp_type]
	var/list/titles = typemap ? typemap["titles"] : null
	if(titles && titles.len)
		keys_to_set = titles.Copy()
	else
		var/list/tier_titles = GLOB.exp_tiermap[exp_type]
		if(tier_titles && tier_titles.len)
			keys_to_set = tier_titles.Copy()
		else
			keys_to_set += exp_type

	// Build the planned new values first
	var/list/new_values = list()
	var/first = TRUE
	for(var/job_key in keys_to_set)
		new_values[job_key] = first ? total_minutes : 0
		first = FALSE
	// Run all DB queries before touching in-memory state
	for(var/job_key in new_values)
		var/datum/db_query/q = SSdbcore.NewQuery(
			"INSERT INTO [format_table_name("role_time")] (ckey, job, minutes) VALUES (:ckey, :job, :minutes) ON DUPLICATE KEY UPDATE minutes = VALUES(minutes)",
			list("ckey" = ckey, "job" = job_key, "minutes" = new_values[job_key])
		)
		var/db_ok = q.Execute()
		if(!db_ok)
			var/errmsg = q.ErrorMsg()
			qdel(q)
			to_chat(usr, span_danger("DB error while setting [job_key]: [errmsg]"))
			return FALSE
		qdel(q)
	for(var/job_key in new_values)
		prefs.exp[job_key] = new_values[job_key]
	return TRUE

/// Loads per-type exp exemptions from the DB into prefs.exp_type_exempt.
/client/proc/load_exp_type_exempts()
	if(!CONFIG_GET(flag/use_exp_tracking))
		return
	if(!SSdbcore.Connect())
		return
	if(!src || !prefs)
		return
	var/datum/db_query/q = SSdbcore.NewQuery(
		"SELECT exp_type FROM [format_table_name("exp_type_exempt")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)
	if(!q.Execute(async = FALSE))
		qdel(q)
		return
	prefs.exp_type_exempt = list()
	while(q.NextRow())
		prefs.exp_type_exempt[q.item[1]] = TRUE
	qdel(q)

/// Sets or clears a per-type exp exemption for this client in both memory and the DB.
/// Returns TRUE on success, FALSE on failure.
/client/proc/set_exp_type_exempt(exp_type, state = TRUE)
	if(!CONFIG_GET(flag/use_exp_tracking))
		return FALSE
	if(!SSdbcore.Connect())
		return FALSE
	if(!src || !prefs)
		return FALSE
	var/datum/db_query/q
	if(state)
		prefs.exp_type_exempt[exp_type] = TRUE
		q = SSdbcore.NewQuery(
			"INSERT IGNORE INTO [format_table_name("exp_type_exempt")] (ckey, exp_type) VALUES (:ckey, :exp_type)",
			list("ckey" = ckey, "exp_type" = exp_type)
		)
	else
		prefs.exp_type_exempt -= exp_type
		q = SSdbcore.NewQuery(
			"DELETE FROM [format_table_name("exp_type_exempt")] WHERE ckey = :ckey AND exp_type = :exp_type",
			list("ckey" = ckey, "exp_type" = exp_type)
		)
	if(!q.Execute())
		qdel(q)
		return FALSE
	qdel(q)
	return TRUE

//resets a client's exp to what was in the db.
/client/proc/set_exp_from_db()
	if(!CONFIG_GET(flag/use_exp_tracking))
		return -1
	if(!SSdbcore.Connect())
		return -1
	if(!src || !prefs)
		return -1
	var/datum/db_query/exp_read = SSdbcore.NewQuery(
		"SELECT job, minutes FROM [format_table_name("role_time")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)
	if(!exp_read || !exp_read.Execute(async = FALSE))
		qdel(exp_read)
		return -1
	var/list/play_records = list()
	while(exp_read.NextRow())
		play_records[exp_read.item[1]] = text2num(exp_read.item[2])
	qdel(exp_read)

	for(var/rtype in SSjob.name_occupations)
		if(!play_records[rtype])
			play_records[rtype] = 0
	for(var/rtype in GLOB.exp_specialmap)
		if(!play_records[rtype])
			play_records[rtype] = 0

	prefs.exp = play_records

//updates player db flags
/client/proc/update_flag_db(newflag, state = FALSE)

	if(!SSdbcore.Connect())
		return -1

	if(!set_db_player_flags())
		return -1

	if((prefs.db_flags & newflag) && !state)
		prefs.db_flags &= ~newflag
	else
		prefs.db_flags |= newflag

	var/datum/db_query/flag_update = SSdbcore.NewQuery(
		"UPDATE [format_table_name("player")] SET flags = :flags WHERE ckey= :ckey",
		list("flags" = prefs.db_flags, "ckey" = ckey)
	)

	if(!flag_update.Execute())
		qdel(flag_update)
		return -1
	qdel(flag_update)


/client/proc/update_exp_list(minutes, announce_changes = FALSE)
	if(!CONFIG_GET(flag/use_exp_tracking))
		return -1
	if(!SSdbcore.Connect())
		return -1
	if (!isnum(minutes))
		return -1
	var/list/play_records = list()

	if(isliving(mob))
		if(mob.stat != DEAD)
			var/rolefound = FALSE
			play_records[EXP_TYPE_LIVING] += minutes
			if(announce_changes)
				to_chat(src,span_notice("You got: [minutes] Living EXP!"))
			if(mob.mind.assigned_role)
				for(var/job in SSjob.name_occupations)
					if(mob.mind.assigned_role == job)
						rolefound = TRUE
						play_records[job] += minutes
						if(announce_changes)
							to_chat(src,span_notice("You got: [minutes] [job] EXP!"))
				if(!rolefound)
					for(var/role in GLOB.exp_specialmap[EXP_TYPE_SPECIAL])
						if(mob.mind.assigned_role == role)
							rolefound = TRUE
							play_records[role] += minutes
							if(announce_changes)
								to_chat(mob,span_notice("You got: [minutes] [role] EXP!"))
				if(mob.mind.special_role && !(mob.mind.datum_flags & DF_VAR_EDITED))
					var/trackedrole = mob.mind.special_role
					play_records[trackedrole] += minutes
					if(announce_changes)
						to_chat(src,span_notice("You got: [minutes] [trackedrole] EXP!"))
			if(!rolefound)
				play_records["Unknown"] += minutes
		else
			if(holder && !holder.deadmined)
				play_records[EXP_TYPE_ADMIN] += minutes
				if(announce_changes)
					to_chat(src,span_notice("You got: [minutes] Admin EXP!"))
			else
				play_records[EXP_TYPE_GHOST] += minutes
				if(announce_changes)
					to_chat(src,span_notice("You got: [minutes] Ghost EXP!"))
	else if(isobserver(mob))
		play_records[EXP_TYPE_GHOST] += minutes
		if(announce_changes)
			to_chat(src,span_notice("You got: [minutes] Ghost EXP!"))
	else if(minutes)	//Let "refresh" checks go through
		return

	for(var/jtype in play_records)
		var/jvalue = play_records[jtype]
		if (!jvalue)
			continue
		if (!isnum(jvalue))
			CRASH("invalid job value [jtype]:[jvalue]")
		LAZYINITLIST(GLOB.exp_to_update)
		GLOB.exp_to_update.Add(list(list(
			"job" = jtype,
			"ckey" = ckey,
			"minutes" = jvalue)))
		prefs.exp[jtype] += jvalue
	addtimer(CALLBACK(SSblackbox, TYPE_PROC_REF(/datum/controller/subsystem/blackbox, update_exp_db)),20,TIMER_OVERRIDE|TIMER_UNIQUE)


//ALWAYS call this at beginning to any proc touching player flags, or your database admin will probably be mad
/client/proc/set_db_player_flags()
	if(!SSdbcore.Connect())
		return FALSE
	if(!src || !prefs)
		return FALSE

	var/datum/db_query/flags_read = SSdbcore.NewQuery(
		"SELECT flags FROM [format_table_name("player")] WHERE ckey=:ckey",
		list("ckey" = ckey)
	)

	if(!flags_read)
		return FALSE

	if(!flags_read.Execute(async = FALSE))
		qdel(flags_read)
		return FALSE

	if(flags_read.NextRow())
		prefs.db_flags = text2num(flags_read.item[1])
	else if(isnull(prefs.db_flags))
		prefs.db_flags = 0	//This PROBABLY won't happen, but better safe than sorry.
	qdel(flags_read)
	return TRUE
