// ====================================================
// ROBOT ACTIVITY LOG  —  robot_log.dm
//
// A rolling event buffer on each robot. Captures:
//   - Behavior circuit responses executing
//   - Hardware activations (weapon, injector, mic)
//   - Damage taken with attacker identification
//   - Speech and emotes heard by the microphone
//   - Service actions (rename, reboot, faction changes)
//
// The terminal caches a snapshot when the technician hits
// the Sync button on the service record page.
//
// Format: [HH:MM:SS]  CATEGORY — detail
// Timestamps are world.time from round start (deciseconds → H:M:S).
// Buffer: 100 entries, newest first. Persists until cleared.
//
// Usage:
//   robot_log(R, "WEAPON FIRED — target: [name]", RLOG_COMBAT)
// ====================================================

// ── Category defines ─────────────────────────────────────────────────────────
#define RLOG_SYSTEM   "sys"   // boots, reboots, service actions
#define RLOG_CIRCUIT  "cir"   // behavior circuit responses
#define RLOG_HARDWARE "hw"    // hardware activations
#define RLOG_COMBAT   "com"   // damage, weapon fire, threat
#define RLOG_ENVIRON  "env"   // audio/speech/emotes heard

#define ROBOT_LOG_MAX 100

// ── Vars on the robot mob ─────────────────────────────────────────────────────

/mob/living/silicon/robot
	/// Rolling activity log. Each entry is a pre-formatted HTML string.
	/// Index 1 = newest. Capped at ROBOT_LOG_MAX. Persists until cleared.
	var/list/activity_log = null


// ── Core proc ─────────────────────────────────────────────────────────────────

/// Append an event to R's activity log.
/// category: one of the RLOG_* defines (used for color-coding in terminal).
/proc/robot_log(mob/living/silicon/robot/R, message, category)
	if(!R || QDELETED(R) || !message)
		return
	if(!R.activity_log)
		R.activity_log = list()

	// Timestamp: world.time is deciseconds since round start
	var/ds  = world.time
	var/hh  = round(ds / 36000)
	var/mm  = round((ds % 36000) / 600)
	var/ss  = round((ds % 600) / 10)
	var/ts  = "\[[hh < 10 ? "0" : ""][hh]:[mm < 10 ? "0" : ""][mm]:[ss < 10 ? "0" : ""][ss]\]"

	// Color class per category
	var/cls = "dim"
	switch(category)
		if(RLOG_COMBAT)   cls = "bad"
		if(RLOG_HARDWARE) cls = "warn"
		if(RLOG_CIRCUIT)  cls = "good"
		if(RLOG_ENVIRON)  cls = "hi"
		if(RLOG_SYSTEM)   cls = "dim"

	var/entry = "<span class='dim'>[ts]</span>  <span class='[cls]'>[html_encode(message)]</span>"
	R.activity_log.Insert(1, entry)
	if(R.activity_log.len > ROBOT_LOG_MAX)
		R.activity_log.len = ROBOT_LOG_MAX


// ── Terminal snapshot ─────────────────────────────────────────────────────────

/obj/machinery/computer/terminal
	/// Cached copy of the last-viewed robot's log.
	/// Key: REF string of robot. Value: list of log entry strings.
	var/list/robot_log_cache = null

/// Pull a fresh snapshot from R into the terminal's cache.
/// Called from the robot_sync_log Topic handler when the technician hits [sync].
/obj/machinery/computer/terminal/proc/snapshot_robot_log(mob/living/silicon/robot/R)
	if(!robot_log_cache)
		robot_log_cache = list()
	var/rref = REF(R)
	if(R.activity_log && R.activity_log.len)
		// Deep copy so the cache is stable even if the robot keeps logging
		robot_log_cache[rref] = R.activity_log.Copy()
	else
		robot_log_cache[rref] = list()

/// Render the cached log for a robot as HTML.
/// Falls back to live log if no cache exists yet (first view).
/obj/machinery/computer/terminal/proc/render_robot_log(mob/living/silicon/robot/R)
	var/rref = REF(R)
	var/list/entries = null
	var/cached = robot_log_cache && (rref in robot_log_cache)
	if(cached)
		entries = robot_log_cache[rref]

	var/dat = "<b>ACTIVITY LOG</b>"
	if(entries && entries.len)
		dat += "  <span class='dim'>([entries.len] entries —  last synced)</span>"
		dat += "  <a href='byond://?src=[REF(src)];choice=robot_sync_log;rref=[rref]'>\[sync\]</a>"
		dat += "  <a href='byond://?src=[REF(src)];choice=robot_clear_log;rref=[rref]'>\[clear\]</a>"
		dat += "<br>"
		for(var/entry in entries)
			dat += "&gt; [entry]<br>"
	else
		dat += "  <span class='dim'>(not synced)</span>"
		dat += "  <a href='byond://?src=[REF(src)];choice=robot_sync_log;rref=[rref]'>\[sync\]</a>"
		dat += "<br>"
		dat += "<span class='dim'>&gt; Pull a fresh log snapshot from the unit.</span><br>"
	return dat


// ── Lifecycle events ──────────────────────────────────────────────────────────

// Robot coming online — log it.
// Call init_robot_log() from the robot's Initialize() or New().
/mob/living/silicon/robot/proc/init_robot_log()
	if(!activity_log)
		activity_log = list()
	robot_log(src, "UNIT ONLINE — [real_name] ([type])", RLOG_SYSTEM)

// Called from reboot service action.
/mob/living/silicon/robot/proc/log_reboot()
	robot_log(src, "REBOOT — soft reset initiated.", RLOG_SYSTEM)

// Called when logging a service action (rename, faction, control mode).
/mob/living/silicon/robot/proc/log_service(message)
	robot_log(src, message, RLOG_SYSTEM)


// ── Damage hook ───────────────────────────────────────────────────────────────
// Extends adjustBruteLoss defined in robot.dm.
// Only logs hits >= 5 to avoid spam from chip damage.

/mob/living/silicon/robot/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE, required_biotype = NONE, include_roboparts = TRUE)
	if(amount >= 5)
		var/mob/attacker = last_attacker_ref ? last_attacker_ref.resolve() : null
		if(attacker)
			robot_log(src, "DAMAGE — [round(amount)]hp — attacker: [attacker.name]", RLOG_COMBAT)
		else
			robot_log(src, "DAMAGE — [round(amount)]hp — source unknown", RLOG_COMBAT)
	return ..()


// ── Speech / emote hooks ──────────────────────────────────────────────────────
// Extends hardware_on_hear() defined in robot_hardware_hooks.dm.
// Only fires if the robot has a microphone (Hear() already gates on TRAIT_HEARING_HARDWARE,
// and hardware_on_hear() only routes to installed microphone datums).

/mob/living/silicon/robot/hardware_on_hear(mob/speaker, msg)
	..()   // run hooks.dm logic (trigger_phrase check, last_heard_message, etc.)
	if(speaker && msg)
		var/spk = speaker.name ? speaker.name : "unknown"
		// Truncate long messages
		var/display = length(msg) > 80 ? (copytext(msg, 1, 78) + "...") : msg
		robot_log(src, "HEARD — [spk]: \"[display]\"", RLOG_ENVIRON)

// Extends hardware_on_combat_sound() defined in robot_hardware_hooks.dm.
/mob/living/silicon/robot/hardware_on_combat_sound()
	..()
	robot_log(src, "AUDIO — combat sound detected nearby", RLOG_ENVIRON)


// ── Behavior circuit hook ─────────────────────────────────────────────────────
// Base execute() on /datum/behavior_circuit/response.
// Every response subtype calls ..() so this fires once per execution.
// Subtypes that produce more useful messages override log_entry.

/datum/behavior_circuit/response
	/// Human-readable log line for this response type.
	/// Null falls back to circuit_name.
	/// Used by response/execute in robot_log.dm.
	var/log_entry = null
	/// TRUE = this subtype logs its own specific entry in its execute() override.
	/// response/execute will skip the generic log line for these.
	var/suppress_base_log = FALSE
	/// Short visible_message emote shown to nearby players when this circuit fires.
	/// This is the noob feedback hook -- players nearby see the robot react in real-time.
	/// Set to null to suppress visible chatter for this response type.
	/// Dynamic responses (fire_weapon, follow_target etc.) emit their own chatter in execute().
	var/visible_chatter = null
	/// Cooldown (deciseconds) between visible_chatter emits. Prevents spam on fast triggers.
	var/chatter_cooldown = 30
	var/last_chatter = 0

/datum/behavior_circuit/response/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	// Override — proc/execute declared on base datum in _behavior_defines.dm.
	// This is the generic fallback log for responses that don't override execute().
	// Subtypes that need custom log messages (target names, spoken text, etc.)
	// set suppress_base_log = TRUE and call robot_log() themselves.
	// Include order: robot_log.dm must come BEFORE behavior_circuits.dm in the .dme
	// so behavior_circuits.dm subtype ..() calls bubble up into this override correctly.
	if(R && !suppress_base_log)
		robot_log(R, "CIRCUIT — [log_entry ? log_entry : circuit_name]", RLOG_CIRCUIT)
	// Visible chatter — lets nearby players see the robot's brain working.
	// This is the primary noob feedback hook: when your robot does something, you see it.
	if(R && visible_chatter && world.time >= last_chatter + chatter_cooldown)
		last_chatter = world.time
		R.visible_message(span_notice("[R] [visible_chatter]"))
	..()

// ── Per-response overrides ────────────────────────────────────────────────────
// Only for cases where circuit_name is too terse, where target names add useful
// information, or where visible_chatter adds noob-facing flavor.

/datum/behavior_circuit/response/enter_combat_mode
	log_entry = "CIRCUIT — ENTER COMBAT MODE"
	visible_chatter = "snaps to attention, optics flaring red."

/datum/behavior_circuit/response/flee_from_threat
	log_entry = "CIRCUIT — FLEE FROM THREAT"
	visible_chatter = "reverses course, chassis whirring urgently."

/datum/behavior_circuit/response/lockdown_self
	log_entry = "CIRCUIT — LOCKDOWN ENGAGED"
	visible_chatter = "shudders and locks into an emergency brace posture."

/datum/behavior_circuit/response/self_repair_pulse
	log_entry = "CIRCUIT — SELF-REPAIR PULSE"
	visible_chatter = "emits a rapid series of clicks as internal repair systems cycle."

/datum/behavior_circuit/response/broadcast_alert
	log_entry = "CIRCUIT — BROADCAST ALERT"
	visible_chatter = "transmitter array flashes as it broadcasts an alert signal."

/datum/behavior_circuit/response/broadcast_distress
	log_entry = "CIRCUIT — BROADCAST DISTRESS"
	visible_chatter = "distress beacon lights strobe orange."

/datum/behavior_circuit/response/inject_nearby_mob
	log_entry = "HARDWARE — INJECTOR ACTIVATED"
	visible_chatter = "extends its injector arm."

/datum/behavior_circuit/response/spray_reagent
	log_entry = "HARDWARE — CHEM SPRAYER ACTIVATED"
	visible_chatter = "chemical sprayer hisses and pressurizes."

/datum/behavior_circuit/response/collect_reagents
	log_entry = "HARDWARE — REAGENT COLLECTION CYCLE"
	visible_chatter = "collection nozzle retracts with a soft vacuum hiss."


/datum/behavior_circuit/response/say_text
	suppress_base_log = TRUE
	log_entry = null  // dynamic — override execute() to include text

/datum/behavior_circuit/response/say_text/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R)
		var/datum/behavior_circuit/response/say_text/ST = src
		robot_log(R, "CIRCUIT — SAY: \"[ST.say_string]\"", RLOG_CIRCUIT)
	..()

/datum/behavior_circuit/response/fire_weapon
	suppress_base_log = TRUE

/datum/behavior_circuit/response/fire_weapon/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R)
		var/tname = "unknown"
		if(R.last_attacker_ref)
			var/datum/weakref/tref = R.last_attacker_ref
			var/mob/T = tref.resolve()
			if(T) tname = T.name
		robot_log(R, "WEAPON FIRED — target: [tname]", RLOG_COMBAT)
		if(world.time >= last_chatter + chatter_cooldown)
			last_chatter = world.time
			R.visible_message(span_warning("[R] weapon systems lock onto [tname]."))
	..()

/datum/behavior_circuit/response/pathfind_to_enemy
	suppress_base_log = TRUE

/datum/behavior_circuit/response/pathfind_to_enemy/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R && R.last_attacker_ref)
		var/datum/weakref/tref = R.last_attacker_ref
		var/mob/T = tref.resolve()
		var/tname = T ? T.name : "unknown"
		robot_log(R, "CIRCUIT — MOVING TO ENGAGE: [tname]", RLOG_CIRCUIT)
		if(world.time >= last_chatter + chatter_cooldown)
			last_chatter = world.time
			R.visible_message(span_warning("[R] threat drive engages -- pursuit of [tname] initiated."))
	..()

/datum/behavior_circuit/response/follow_target
	suppress_base_log = TRUE

/datum/behavior_circuit/response/follow_target/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R)
		var/tname = "unknown"
		if(linked_target_ref)
			var/datum/weakref/tref2 = linked_target_ref
			var/mob/T = tref2.resolve()
			if(T) tname = T.name
		robot_log(R, "CIRCUIT — FOLLOWING: [tname]", RLOG_CIRCUIT)
		// Follow chatter fires rarely (long cooldown) so it doesn't spam during escort
		if(world.time >= last_chatter + 200)
			last_chatter = world.time
			R.visible_message(span_notice("[R] escort lock on [tname] confirmed."))
	..()

/datum/behavior_circuit/response/remember_enemy
	suppress_base_log = TRUE

/datum/behavior_circuit/response/remember_enemy/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R && R.last_attacker_ref)
		var/datum/weakref/tref = R.last_attacker_ref
		var/mob/T = tref.resolve()
		var/tname = T ? T.name : "unknown"
		robot_log(R, "CIRCUIT — THREAT LOGGED: [tname]", RLOG_CIRCUIT)
		if(world.time >= last_chatter + chatter_cooldown)
			last_chatter = world.time
			R.visible_message(span_warning("[R] threat profile updated: [tname] flagged as hostile."))
	..()





// ── Environment sensor — visual activity hook ────────────────────────────────
// /datum/robot_hardware/environment_sensor is defined in robot_hardware.dm.
// TRAIT_SENSOR_HARDWARE is defined in robot_hardware.dm.
// show_message() is called by BYOND on every mob in view range when visible_message()
// fires. We intercept it to log nearby emotes and visible actions.

/// BYOND calls show_message() on every mob in visual range when a nearby mob
/// calls visible_message() or performs an emote. We intercept it here to log
/// the event if the robot has an environment sensor installed.
/mob/living/silicon/robot/show_message(text, type, alt_text)
	. = ..()
	if(!HAS_TRAIT(src, TRAIT_SENSOR_HARDWARE))
		return
	if(!text || !type)
		return
	// type 2 = visible message (emotes, actions). type 1 = audible only (skip — mic handles those).
	if(type != 2)
		return
	// Strip HTML tags for the log entry (DM replacetext is literal-only, no regex)
	var/raw = text
	var/tag_start = findtext(raw, "<")
	while(tag_start)
		var/tag_end = findtext(raw, ">", tag_start)
		if(!tag_end) break
		raw = copytext(raw, 1, tag_start) + copytext(raw, tag_end + 1)
		tag_start = findtext(raw, "<")
	if(raw && length(raw) > 0)
		var/display = length(raw) > 80 ? (copytext(raw, 1, 78) + "...") : raw
		robot_log(src, "OBSERVED — [display]", RLOG_ENVIRON)


// ── Cleanup ───────────────────────────────────────────────────────────────────

#undef RLOG_SYSTEM
#undef RLOG_CIRCUIT
#undef RLOG_HARDWARE
#undef RLOG_COMBAT
#undef RLOG_ENVIRON
#undef ROBOT_LOG_MAX
