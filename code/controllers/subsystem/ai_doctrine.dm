// Saves and loads hostile mob doctrines between rounds (Hostile AI redesign, phase 6b).
// What is saved is one slow-moving prior per mob type, context and intent. Priors only ever hold aggregate numbers
// tied to tactics, never anything about players.
// - A round's results are folded into the priors once, at round end, and only for tactics sampled often enough.
// - The step any prior can take in one round is capped, every prior is clamped, and all of them fade toward zero.
// - Rounds that are not representative (few players, short, crashed early) are not merged.
// - A checkpoint every few minutes saves the round so far as a "pending" section. If the server dies, the next start
//   merges it as if the round had ended normally. A clean round end writes no pending section, so nothing counts twice.
// - The file is written to a temp name, read back and checked, then copied over the real one. The last three round-end
//   files are kept as snapshots. A bad or outdated file falls back to the next snapshot, then to defaults.

#define AI_DOCTRINE_DIR "data/ai_doctrine/"
#define AI_DOCTRINE_FILE "data/ai_doctrine/doctrine.json"
#define AI_DOCTRINE_TMP "data/ai_doctrine/doctrine.json.tmp"
#define AI_DOCTRINE_SNAPSHOTS 3
#define AI_DOCTRINE_SCHEMA 1

/// Round samples a tactic needs before the round's result is merged into its prior
#define AI_PERSIST_MIN_SAMPLES 20
/// How far one round's result pulls the prior, and the most a prior can move in one round
#define AI_PERSIST_ALPHA 0.15
#define AI_PERSIST_MAX_STEP 0.1
/// Share each prior keeps per round
#define AI_PERSIST_DECAY 0.02
/// A prior counts like this many samples when blended with the current round
#define AI_PERSIST_PRIOR_WEIGHT 5
/// Rounds with fewer players at their peak, or shorter than this, are not merged
#define AI_PERSIST_MIN_CLIENTS 3
#define AI_PERSIST_MIN_ROUND (15 MINUTES)
#define AI_PERSIST_CHECKPOINT (5 MINUTES)

SUBSYSTEM_DEF(ai_doctrine)
	name = "AI Doctrine"
	init_order = INIT_ORDER_AI_DOCTRINE
	wait = 1 MINUTES
	flags = SS_BACKGROUND
	var/peak_clients = 0
	var/next_checkpoint = 0
	var/rounds_recorded = 0
	/// What the last load, merge or save did, for the admin panel
	var/status = "not loaded"

/datum/controller/subsystem/ai_doctrine/Initialize()
	if(GLOB.ai_learning_enabled)
		load_priors()
	next_checkpoint = world.time + AI_PERSIST_CHECKPOINT
	return ..()

/datum/controller/subsystem/ai_doctrine/fire(resumed = FALSE)
	peak_clients = max(peak_clients, length(GLOB.clients))
	if(world.time >= next_checkpoint)
		next_checkpoint = world.time + AI_PERSIST_CHECKPOINT
		save_file(FALSE, TRUE)

/datum/controller/subsystem/ai_doctrine/Shutdown()
	finish_round()

/datum/controller/subsystem/ai_doctrine/stat_entry(msg)
	msg = "R:[rounds_recorded]|D:[length(GLOB.ai_doctrines)]|U:[GLOB.ai_doctrine_updates]"
	return ..()

/datum/controller/subsystem/ai_doctrine/proc/round_elapsed()
	return SSticker.round_start_time ? world.time - SSticker.round_start_time : 0

/// Why a round should not be merged, or null if it can be
/datum/controller/subsystem/ai_doctrine/proc/junk_reason(peak, elapsed)
	if(peak < AI_PERSIST_MIN_CLIENTS)
		return "only [peak] players at peak"
	if(elapsed < AI_PERSIST_MIN_ROUND)
		return "round lasted [round(elapsed / 600)] minutes"
	return null

/datum/controller/subsystem/ai_doctrine/proc/merge_allowed()
	return GLOB.ai_learning_enabled && !GLOB.ai_learning_frozen

/// Folds the round into the priors and saves with a snapshot. No pending section is written.
/datum/controller/subsystem/ai_doctrine/proc/finish_round()
	if(!merge_allowed())
		status = "round end: learning [GLOB.ai_learning_enabled ? "frozen" : "off"], nothing merged"
	else
		var/junk = junk_reason(max(peak_clients, length(GLOB.clients)), round_elapsed())
		if(junk)
			status = "round end: not merged ([junk])"
		else
			var/merged = merge_round(TRUE)
			rounds_recorded++
			status = "round end: merged [merged] tactics"
	for(var/key in GLOB.ai_doctrines)
		var/datum/ai_doctrine/D = GLOB.ai_doctrines[key]
		D.reset()
	save_file(TRUE, FALSE)

/// Merges every doctrine's current round into its prior. Returns how many tactics were merged.
/datum/controller/subsystem/ai_doctrine/proc/merge_round(decay)
	. = 0
	for(var/key in GLOB.ai_doctrines)
		var/datum/ai_doctrine/D = GLOB.ai_doctrines[key]
		. += D.merge_data(D.value, D.samples, decay)

/// Admin: merge what has been learned so far without the round checks or decay, and save
/datum/controller/subsystem/ai_doctrine/proc/save_now()
	var/merged = merge_round(FALSE)
	for(var/key in GLOB.ai_doctrines)
		var/datum/ai_doctrine/D = GLOB.ai_doctrines[key]
		D.reset()
	status = "manual save: merged [merged] tactics"
	return save_file(FALSE, FALSE)

/// Builds the file contents. include_pending adds the round so far, for crash recovery.
/datum/controller/subsystem/ai_doctrine/proc/build_data(include_pending)
	var/list/doctrines = list()
	var/list/pending_doctrines = list()
	for(var/key in GLOB.ai_doctrines)
		var/datum/ai_doctrine/D = GLOB.ai_doctrines[key]
		if(D.has_prior())
			doctrines[key] = list("prior" = D.prior)
		if(include_pending && D.has_samples())
			pending_doctrines[key] = D.export_pending()
	var/list/data = list("schema_version" = AI_DOCTRINE_SCHEMA, "rounds" = rounds_recorded, "saved_at" = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss"), "doctrines" = doctrines)
	if(include_pending && length(pending_doctrines) && merge_allowed())
		data["pending"] = list("elapsed" = round_elapsed(), "peak" = max(peak_clients, length(GLOB.clients)), "doctrines" = pending_doctrines)
	return data

/// Returns the decoded file if it parses and has the current schema, otherwise null
/datum/controller/subsystem/ai_doctrine/proc/read_file(path)
	if(!fexists(path))
		return null
	var/list/data
	try
		data = json_decode(file2text(path))
	catch
		return null
	if(!islist(data) || data["schema_version"] != AI_DOCTRINE_SCHEMA || !islist(data["doctrines"]))
		return null
	return data

/// Writes to a temp file, checks it reads back, then copies it over the real one. rotate keeps the old file as a snapshot.
/datum/controller/subsystem/ai_doctrine/proc/save_file(rotate, include_pending)
	var/json = json_encode(build_data(include_pending))
	fdel(AI_DOCTRINE_TMP)
	text2file(json, AI_DOCTRINE_TMP)
	if(!read_file(AI_DOCTRINE_TMP))
		fdel(AI_DOCTRINE_TMP)
		status = "save failed: could not write a valid file"
		log_game("AI doctrine save failed: temp file did not validate.")
		return FALSE
	if(rotate && read_file(AI_DOCTRINE_FILE))
		for(var/i in AI_DOCTRINE_SNAPSHOTS to 2 step -1)
			var/older = "[AI_DOCTRINE_FILE].[i - 1]"
			if(fexists(older))
				fdel("[AI_DOCTRINE_FILE].[i]")
				fcopy(older, "[AI_DOCTRINE_FILE].[i]")
		fdel("[AI_DOCTRINE_FILE].1")
		fcopy(AI_DOCTRINE_FILE, "[AI_DOCTRINE_FILE].1")
	fcopy(AI_DOCTRINE_TMP, AI_DOCTRINE_FILE)
	fdel(AI_DOCTRINE_TMP)
	return TRUE

/// Loads priors from the first good file: the real one, then the snapshots. Merges a crashed round's pending section.
/datum/controller/subsystem/ai_doctrine/proc/load_priors()
	var/list/paths = list(AI_DOCTRINE_FILE, AI_DOCTRINE_TMP)
	for(var/i in 1 to AI_DOCTRINE_SNAPSHOTS)
		paths += "[AI_DOCTRINE_FILE].[i]"
	var/any_file = FALSE
	for(var/path in paths)
		if(fexists(path))
			any_file = TRUE
		var/list/data = read_file(path)
		if(!data)
			continue
		apply_data(data, path == paths[1])
		status = "loaded [path]"
		return TRUE
	status = any_file ? "no usable file, using defaults" : "no saved doctrine yet"
	if(any_file)
		log_game("AI doctrine: no usable file found, using defaults.")
	return FALSE

/// Replaces every prior with the file's, then merges its pending section if it holds a representative round
/datum/controller/subsystem/ai_doctrine/proc/apply_data(list/data, check_pending)
	for(var/key in GLOB.ai_doctrines)
		var/datum/ai_doctrine/D = GLOB.ai_doctrines[key]
		D.clear_prior()
	rounds_recorded = isnum(data["rounds"]) ? data["rounds"] : 0
	var/list/doctrines = data["doctrines"]
	for(var/key in doctrines)
		var/datum/ai_doctrine/D = ai_doctrine_for(key)
		if(!D)
			continue
		var/list/entry = doctrines[key]
		if(islist(entry))
			D.import_prior(entry["prior"])
	var/list/pending = data["pending"]
	if(!check_pending || !islist(pending) || !merge_allowed())
		return
	var/junk = junk_reason(isnum(pending["peak"]) ? pending["peak"] : 0, isnum(pending["elapsed"]) ? pending["elapsed"] : 0)
	if(junk)
		status = "recovered a crashed round but did not merge it ([junk])"
		return
	var/list/pending_doctrines = pending["doctrines"]
	if(!islist(pending_doctrines))
		return
	var/merged = 0
	for(var/key in pending_doctrines)
		var/datum/ai_doctrine/D = ai_doctrine_for(key)
		var/list/entry = pending_doctrines[key]
		if(D && islist(entry))
			merged += D.merge_data(entry["value"], entry["samples"], TRUE)
	rounds_recorded++
	status = "recovered a crashed round, merged [merged] tactics"
	save_file(TRUE, FALSE)

/// Admin: puts back the priors from one of the snapshots
/datum/controller/subsystem/ai_doctrine/proc/restore_snapshot(index)
	var/list/data = read_file("[AI_DOCTRINE_FILE].[index]")
	if(!data)
		return FALSE
	apply_data(data, FALSE)
	status = "rolled back to snapshot [index]"
	return save_file(FALSE, FALSE)

/// Admin: erases every prior, here and in the saved file
/datum/controller/subsystem/ai_doctrine/proc/clear_all_priors()
	for(var/key in GLOB.ai_doctrines)
		var/datum/ai_doctrine/D = GLOB.ai_doctrines[key]
		D.clear_prior()
	status = "all priors cleared"
	return save_file(FALSE, FALSE)
