/// Lightweight reference finder run when an object fails its GC check, so leaks are diagnosable without
/// compiling in REFERENCE_TRACKING. It only looks at likely holders (global vars, mobs, timers) and is
/// throttled to one scan per type every few minutes.
GLOBAL_VAR_INIT(gc_holder_scan_enabled, TRUE)
GLOBAL_VAR_INIT(gc_holder_scan_busy, FALSE)
GLOBAL_LIST_EMPTY(gc_holder_scan_types)

#define GC_HOLDER_SCAN_TYPE_COOLDOWN (5 MINUTES)
#define GC_HOLDER_SCAN_MAX_FOUND 8

/proc/gc_queue_holder_scan(datum/D)
	if(!GLOB.gc_holder_scan_enabled || GLOB.gc_holder_scan_busy || !D)
		return
	if(istype(D, /datum/controller) || istype(D, /datum/timedevent))
		return
	var/last_scan = GLOB.gc_holder_scan_types[D.type]
	if(last_scan && world.time < last_scan + GC_HOLDER_SCAN_TYPE_COOLDOWN)
		return
	GLOB.gc_holder_scan_types[D.type] = world.time
	GLOB.gc_holder_scan_busy = TRUE
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(gc_holder_scan), D)

/proc/gc_holder_scan(datum/D)
	var/ref = "\ref[D]"
	var/type_text = "[D.type]"
	var/list/found = list()
	var/list/seen = list()
	var/start = REALTIMEOFDAY

	for(var/key in global.vars)
		if(key == "vars" || key == "GLOB")
			continue
		gc_scan_value(global.vars[key], "global.[key]", D, found, seen, 3)
	gc_scan_value(GLOB, "GLOB", D, found, seen, 3)
	CHECK_TICK

	for(var/mob/M in GLOB.mob_list)
		if(!D || length(found) >= GC_HOLDER_SCAN_MAX_FOUND)
			break
		gc_scan_value(M, "[M.type] \ref[M]", D, found, seen, 3)
		CHECK_TICK

	var/list/timers = SStimer.timer_id_dict
	for(var/id in timers)
		if(!D || length(found) >= GC_HOLDER_SCAN_MAX_FOUND)
			break
		var/datum/timedevent/T = timers[id]
		if(T)
			gc_scan_value(T.callBack, "timer [T.source || T.name || id]", D, found, seen, 2)
		CHECK_TICK

	var/aborted = !D
	GLOB.gc_holder_scan_busy = FALSE
	if(aborted)
		log_world("## TESTING: GC: holder scan for [type_text] [ref] aborted, object was hard deleted first")
	else if(!length(found))
		log_world("## TESTING: GC: holder scan for [type_text] [ref] found no reference in globals, mobs or timers ([(REALTIMEOFDAY - start) / 10]s)")
	else
		log_world("## TESTING: GC: holder scan for [type_text] [ref] found: [found.Join(" | ")] ([(REALTIMEOFDAY - start) / 10]s)")

/// Recursively looks for `D` inside `value`, recording the path of anything holding it
/proc/gc_scan_value(value, path, datum/D, list/found, list/seen, depth)
	if(!D || length(found) >= GC_HOLDER_SCAN_MAX_FOUND)
		return
	if(value == D)
		found += path
		return
	if(depth <= 0 || isnum(value) || istext(value) || isnull(value) || isfile(value) || isicon(value))
		return

	if(islist(value))
		var/list/L = value
		if(seen[L])
			return
		seen[L] = TRUE
		var/normal = IS_NORMAL_LIST(L)
		var/index = 0
		for(var/element in L)
			index++
			if(element == D)
				found += "[path]\[[index]\]"
				continue
			if(islist(element) || istype(element, /datum))
				gc_scan_value(element, "[path]\[[index]\]", D, found, seen, depth - 1)
			if(normal && !isnum(element) && !istext(element))
				var/assoc_val = L[element]
				if(assoc_val == D)
					found += "[path]\[[element]\]"
				else if(islist(assoc_val) || istype(assoc_val, /datum))
					gc_scan_value(assoc_val, "[path]\[[element]\]", D, found, seen, depth - 1)
		return

	if(istype(value, /datum))
		var/datum/V = value
		if(seen[V])
			return
		seen[V] = TRUE
		var/list/vars_list = V.vars
		for(var/varname in vars_list)
			if(varname == "vars" || varname == "vis_locs" || varname == "contents" || varname == "overlays" || varname == "underlays" || varname == "verbs")
				continue
			var/variable = vars_list[varname]
			if(variable == D)
				found += "[V.type] \ref[V] [varname]"
				continue
			if(islist(variable) || istype(variable, /datum))
				gc_scan_value(variable, "[V.type] \ref[V] [varname]", D, found, seen, depth - 1)

#undef GC_HOLDER_SCAN_TYPE_COOLDOWN
#undef GC_HOLDER_SCAN_MAX_FOUND
