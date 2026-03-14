// HW_SLOT and ROBOT_COMBAT defines are in _behavior_defines.dm

// ====================================================
// BEHAVIOR CIRCUITS
// Signal-driven automation circuits for behavior assemblies.
//
// Design principles:
//   - No CERT_CAN_* gates on circuit execution. Gates were
//     removed because they created clunky double-requirements.
//     Hardware-dependent responses simply check for the IC
//     in the robot's module at runtime - if the IC is missing
//     the response silently does nothing, which is intuitive.
//   - Every circuit declares tutorial_text so the fabricator
//     workshop can teach players what each circuit does.
//   - cpu_cost is consumed by behavior_assembly and checked
//     against the robot's cert compute budget at install time.
//   - Configurable vars are set by the workshop before printing
//     and written onto the instantiated circuits at print time.
//
// STUB: COMSIG-based triggers are stubbed with SSobj processing.
//       Search "// STUB:" to find swap points.
//
// File: code/modules/integrated_electronics/behavior_circuits.dm
// ====================================================


// ====================================================
// BASE DATUMS
// ====================================================
// /datum/behavior_circuit base (vars + procs) is defined in behavior_assembly.dm.
// We extend it here to add vars needed only by hardware-aware circuits.

/datum/behavior_circuit
	/// The /datum/robot_hardware subtype this circuit needs installed.
	/// Matches HW_SLOT_* defines. Set on hardware-dependent subtypes.
	/// Used by the workshop hardware picker to filter compatible hardware.
	var/required_hardware_type = null


// -- TRIGGER BASE --------------------------------------------

/datum/behavior_circuit/trigger
	/// Single wired response — kept for backwards compat with presets and fabricator rewire.
	/// If responses_list is non-empty it takes priority over this var.
	var/datum/behavior_circuit/response/response = null
	/// Multi-response list. Populated when a trigger is wired to more than one response.
	/// The fabricator's "add response" flow appends here. _trigger() iterates this if set.
	var/list/responses_list = null
	/// Per-trigger Logic Core override. When set, this datum's conditions gate ONLY this
	/// trigger rather than the robot-global Logic Core hardware. Allows mixed-condition builds:
	/// e.g. one assembly fires only when hurt, another fires unconditionally.
	/// Set by the fabricator's advanced wiring UI; null = fall back to installed hardware.
	var/datum/robot_hardware/logic_core/local_logic_core = null

// Triggers have no execute() — base register() wires _on_clock_tick to every circuit,
// which calls execute(). Without this no-op, calling execute() on a trigger datum throws
// a runtime on every clock tick, breaking the signal handler chain and preventing
// on_tick_signal (the real On Clock Tick handler) from ever firing.
/datum/behavior_circuit/trigger/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	return  // triggers are activated by _trigger(), not execute()

/datum/behavior_circuit/trigger/proc/_trigger(mob/living/silicon/robot/R)
	log_game("CIRCUIT TRIGGER: [circuit_name] fired on [R]")
	// Skip autonomous behavior for player-controlled robots UNLESS assembly_override is set.
	// assembly_override is set by robot_workshop so assemblies always run on workshop-built bots.
	if(R.mind && R.client)
		var/assembly_active = FALSE
		for(var/datum/cert_upgrade/robot/behavior_assembly/U in R.cpu_cert?.upgrade_slots)
			if(U.assembly?.assembly_override)
				assembly_active = TRUE
				break
		if(!assembly_active)
			log_game("CIRCUIT TRIGGER: [circuit_name] BLOCKED - player-controlled, no assembly_override")
			return
	// Logic Core gate
	var/datum/robot_hardware/logic_core/LC = local_logic_core
	if(!LC)
		LC = get_hardware(R, /datum/robot_hardware/logic_core)
	if(LC && !LC.evaluate(R))
		log_game("CIRCUIT TRIGGER: [circuit_name] BLOCKED - Logic Core gate failed")
		return
	// Advanced Circuit Board
	var/datum/robot_hardware/circuit_board/CB = get_hardware(R, /datum/robot_hardware/circuit_board)
	if(CB && CB.nodes.len)
		CB.evaluate()
	// Fire responses
	var/obj/item/behavior_assembly/A_exec = get_assembly()
	if(responses_list && responses_list.len)
		for(var/datum/behavior_circuit/response/RE in responses_list)
			log_game("CIRCUIT RESPONSE: [RE.circuit_name] executing on [R]")
			RE.execute(R, A_exec)
	else if(response)
		log_game("CIRCUIT RESPONSE: [response.circuit_name] executing on [R]")
		response.execute(R, A_exec)
	else
		log_game("CIRCUIT TRIGGER: [circuit_name] - no response wired")


// -- RESPONSE BASE -------------------------------------------
// execute() overrides the base stub defined in _behavior_defines.dm

/// Returns the first installed /datum/robot_hardware of hw_type on robot R.
/// Used by hardware-dependent circuits to resolve their datum instead of
/// searching R.module.modules for legacy IC objects.
/datum/behavior_circuit/proc/get_hardware(mob/living/silicon/robot/R, hw_type)
	if(!R || !R.installed_hardware)
		return null
	for(var/datum/robot_hardware/HW in R.installed_hardware)
		if(istype(HW, hw_type))
			return HW
	return null


/// Returns TRUE if target M is friendly to robot R (shared faction or same mob).
/// Used by all circuits to skip friendly mobs when scanning for enemies.
/proc/_is_faction_friend(mob/living/silicon/robot/R, mob/living/M)
	if(!R || !M || M == R)
		return TRUE
	if(!R.faction)
		return FALSE  // robot has no faction - treat all non-self as potential targets
	// faction can be a string (single faction) or a list (multiple factions).
	// Normalise both sides to lists before comparing.
	var/list/r_factions = islist(R.faction) ? R.faction : list(R.faction)
	var/list/m_factions = M.faction ? (islist(M.faction) ? M.faction : list(M.faction)) : null
	if(!r_factions.len || !m_factions || !m_factions.len)
		return FALSE
	// Exclude entries that are NOT meaningful alliance markers:
	// "neutral" = generic no-faction tag shared by all mobs, not an alliance.
	// self-REF entries ([mob_XXXX]) = unique per-mob identity tags added by living Initialize,
	// also shared by nobody else so they can never match across mobs.
	// Matching on either of these produces false positives where all mobs appear friendly.
	var/static/list/ignore_factions = list("neutral", "silicon")
	// Self-REF entries added by living/Initialize look like [mob_1954].
	// ascii2text(91) is "[" — avoids DM string interpolation parser treating "[" as an expression.
	var/static/open_bracket = ascii2text(91)
	for(var/f in r_factions)
		if(f in ignore_factions)
			continue
		if(copytext(f, 1, 2) == open_bracket)  // skip self-REF entries
			continue
		if(f in m_factions)
			return TRUE
	return FALSE


// ====================================================
// TRIGGER CIRCUITS
// ====================================================


// -- ON TAKE DAMAGE ----------------------------------

/datum/behavior_circuit/trigger/on_take_damage
	circuit_name = "Trigger: On Take Damage"
	circuit_desc = "Fires when the robot takes significant damage."
	tutorial_text = "Fires when the robot takes a hit above the damage threshold. Configure 'damage_threshold' (default 10). Has a built-in cooldown so it fires at most once every 2 seconds, not every tick. Good for: distress calls, self-repair triggers, retreat behavior, or retaliation responses."
	cpu_cost = 1
	var/damage_threshold = 10
	var/last_health = -1
	var/last_fire = 0
	var/fire_cooldown = 20  // 2 seconds minimum between fires

/datum/behavior_circuit/trigger/on_take_damage/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	last_health = R.health
	last_fire = world.time
	// SSfastprocess (~0.5s window) keeps per-sample drag brute below threshold.
	// SSobj (2s window) lets accumulated drag brute add up to 10+ and false-trigger.
	START_PROCESSING(SSfastprocess, src)

/datum/behavior_circuit/trigger/on_take_damage/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSfastprocess, src)
	. = ..()

/datum/behavior_circuit/trigger/on_take_damage/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSfastprocess, src)
		return
	// delta = damage taken THIS sample window only (not accumulated).
	// Drag/bump deals ~1-3 brute per 0.5s. Real hits deal 10+.
	var/delta = last_health - R.health
	last_health = R.health
	if(delta >= damage_threshold && world.time >= last_fire + fire_cooldown)
		last_fire = world.time
		_trigger(R)


// -- ON LOW POWER ------------------------------------

/datum/behavior_circuit/trigger/on_low_power
	circuit_name = "Trigger: On Low Power"
	circuit_desc = "Fires once when cell charge drops below a threshold."
	tutorial_text = "Fires once when cell charge drops below the threshold, then resets when power recovers. Configure 'power_threshold' (0.0-1.0, default 0.2 = 20%). Good for: low-battery warnings, retreat to charger, entering low-power mode."
	cpu_cost = 1
	var/charge_threshold = 0.2
	var/already_triggered = FALSE

/datum/behavior_circuit/trigger/on_low_power/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_low_power/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_low_power/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	if(!R.cell)
		return
	var/ratio = R.cell.charge / R.cell.maxcharge
	if(ratio < charge_threshold && !already_triggered)
		already_triggered = TRUE
		_trigger(R)
	else if(ratio >= charge_threshold)
		already_triggered = FALSE


// -- ON DARKNESS -------------------------------------
// Fires once when the robot's turf drops below a
// darkness threshold.  Resets when it becomes lit again.
// Good for: activating a light, sounding an alert,
// retreating to a lit area.

/datum/behavior_circuit/trigger/on_darkness
	circuit_name = "Trigger: On Darkness"
	circuit_desc = "Fires once when the robot's location becomes dark. Resets when lit again."
	tutorial_text = "Fires when the turf the robot stands on drops below the darkness threshold (0.0-1.0, default 0.15). Resets when light returns. Good for: activating a headlamp, alerting to a power outage, or retreating to lit areas. Pair with Toggle Light or Say Text."
	cpu_cost = 1
	var/lum_threshold = 0.15
	var/in_darkness = FALSE

/datum/behavior_circuit/trigger/on_darkness/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_darkness/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_darkness/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/turf/T = get_turf(R)
	if(!T)
		return
	var/lum = T.get_lumcount()
	if(lum <= lum_threshold && !in_darkness)
		in_darkness = TRUE
		_trigger(R)
	else if(lum > lum_threshold)
		in_darkness = FALSE


// -- ON LIT ---------------------------------------
// Fires once when the robot's turf rises above a
// light threshold.  Resets when it becomes dark again.
// Good for: turning a light off, a "back to normal" hook.

/datum/behavior_circuit/trigger/on_lit
	circuit_name = "Trigger: On Lit"
	circuit_desc = "Fires once when the robot's location becomes lit after being dark. Resets when dark again."
	tutorial_text = "Fires when the turf the robot stands on rises above the light threshold (0.0-1.0, default 0.15). Resets when darkness returns. Companion to On Darkness. Good for: deactivating a headlamp when you enter a lit room, or chaining a 'lights-on' response."
	cpu_cost = 1
	var/lum_threshold = 0.15
	var/in_light = TRUE

/datum/behavior_circuit/trigger/on_lit/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_lit/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_lit/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/turf/T = get_turf(R)
	if(!T)
		return
	var/lum = T.get_lumcount()
	if(lum > lum_threshold && !in_light)
		in_light = TRUE
		_trigger(R)
	else if(lum <= lum_threshold)
		in_light = FALSE


// -- ON ENEMY SPOTTED --------------------------------

/datum/behavior_circuit/trigger/on_enemy_spotted
	circuit_name = "Trigger: On Enemy Spotted"
	circuit_desc = "Fires when a hostile mob enters sensor range."
	tutorial_text = "Scans for hostile mobs within sensor range every few seconds. Sensor range is baked in from the builder's Perception at print time. Best paired with: Enter Combat Mode, Pathfind To Enemy, Fire Weapon, Broadcast Alert."
	cpu_cost = 2
	var/last_spotted = 0
	var/spot_cooldown = 50

/datum/behavior_circuit/trigger/on_enemy_spotted/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_enemy_spotted/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_enemy_spotted/process()
	if(world.time < last_spotted + spot_cooldown)
		return
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/obj/item/behavior_assembly/A = get_assembly()
	var/scan_range = A ? A.sensor_range : 5
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(_is_faction_friend(R, M))
			continue
		last_spotted = world.time
		_trigger(R)
		return


// -- ON DEATH ----------------------------------------

/datum/behavior_circuit/trigger/on_death
	circuit_name = "Trigger: On Death"
	circuit_desc = "Fires once when the robot dies."
	tutorial_text = "Fires exactly once when the robot dies. Good for: distress beacons, self-destruct, drop all items, or a last words message."
	cpu_cost = 1
	var/already_fired = FALSE

/datum/behavior_circuit/trigger/on_death/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	already_fired = FALSE  // reset so reinsertion into a live robot doesn't immediately fire
	START_PROCESSING(SSfastprocess, src)  // fast poll so death response fires within ~0.5s

/datum/behavior_circuit/trigger/on_death/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSfastprocess, src)
	. = ..()

/datum/behavior_circuit/trigger/on_death/process()
	if(already_fired)
		STOP_PROCESSING(SSfastprocess, src)
		return
	var/mob/living/silicon/robot/R = get_robot()
	if(!R)
		STOP_PROCESSING(SSfastprocess, src)
		return
	if(R.stat == DEAD)
		already_fired = TRUE
		STOP_PROCESSING(SSfastprocess, src)
		_trigger(R)  // fire after stop so process() can't be re-entered


// -- ON INTERVAL -------------------------------------

/datum/behavior_circuit/trigger/on_interval
	circuit_name = "Trigger: On Interval"
	circuit_desc = "Fires repeatedly on a fixed time interval."
	tutorial_text = "Fires repeatedly on a fixed timer. Configure 'interval_ticks' (10 ticks = 1 second). Good for: ambient announcements, patrol loops, status checks, heartbeat signals."
	cpu_cost = 1
	var/interval_ticks = 100
	var/last_fire = 0

/datum/behavior_circuit/trigger/on_interval/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	last_fire = world.time
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_interval/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_interval/process()
	if(world.time < last_fire + interval_ticks)
		return
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	last_fire = world.time
	_trigger(R)


// -- ON CLOCK TICK ------------------------------------
// Paired with the Interval Clock hardware. Unlike on_interval
// (which runs its own SSobj timer), this trigger fires only when
// the Clock hardware emits COMSIG_ROBOT_CLOCK_TICK. Install both
// and they share one clock source — keeps everything in sync and
// makes the clock hardware actually meaningful.

/datum/behavior_circuit/trigger/on_clock_tick
	circuit_name = "Trigger: On Clock Tick"
	circuit_desc = "Fires each time the robot's Interval Clock hardware ticks."
	tutorial_text = "HARDWARE REQUIRED: Interval Clock. Fires each time the installed Interval Clock hardware pulses. Unlike On Interval (which has its own independent timer), this shares the clock hardware's configured interval. Install both when you want multiple assemblies to stay perfectly in sync."
	needs_hardware = TRUE
	hardware_slot_name = HW_SLOT_CLOCK
	required_hardware_type = /datum/robot_hardware/clock
	cpu_cost = 1

/datum/behavior_circuit/trigger/on_clock_tick/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	RegisterSignal(R, COMSIG_ROBOT_CLOCK_TICK, PROC_REF(on_tick_signal))

/datum/behavior_circuit/trigger/on_clock_tick/unregister(mob/living/silicon/robot/R)
	UnregisterSignal(R, COMSIG_ROBOT_CLOCK_TICK)
	. = ..()

/datum/behavior_circuit/trigger/on_clock_tick/proc/on_tick_signal(mob/living/silicon/robot/R, datum/robot_hardware/clock/CLK)
	SIGNAL_HANDLER
	_trigger(R)


// -- ON POWER RESTORED -------------------------------

/datum/behavior_circuit/trigger/on_power_restored
	circuit_name = "Trigger: On Power Restored"
	circuit_desc = "Fires once when the robot's cell charge rises above threshold after being low."
	tutorial_text = "Fires once when the cell recovers above the power threshold after having been low. Good for: announcing readiness, resuming patrol, or broadcasting a status update after recharging."
	cpu_cost = 1
	var/restore_threshold = 0.5
	var/was_low = FALSE

/datum/behavior_circuit/trigger/on_power_restored/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	// If robot is already low-power when installed, mark was_low so any recharge fires the trigger
	if(R.cell && (R.cell.charge / R.cell.maxcharge) < 0.3)
		was_low = TRUE
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_power_restored/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_power_restored/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	if(!R.cell)
		return
	var/ratio = R.cell.charge / R.cell.maxcharge
	if(ratio < 0.3)
		was_low = TRUE
	else if(ratio >= restore_threshold && was_low)
		was_low = FALSE
		_trigger(R)


// -- ON MOB APPROACHES -------------------------------

/datum/behavior_circuit/trigger/on_mob_approaches
	circuit_name = "Trigger: Mob Approaches"
	circuit_desc = "Fires when any living mob enters close proximity."
	tutorial_text = "Fires when a living mob enters proximity. Configure 'approach_range' (default 3 tiles) and 'check_faction' (FALSE = fire on anyone, TRUE = skip faction allies). Default FALSE fires on any conscious mob including builders. Good for: greeting visitors, offering items, sounding an alarm. For enemy-only detection use On Enemy Spotted instead."
	cpu_cost = 2
	var/last_check = 0
	var/check_cooldown = 30
	var/approach_range = 3
	var/check_faction = FALSE  // FALSE: fire on anyone approaching. Set TRUE to skip faction allies.

/datum/behavior_circuit/trigger/on_mob_approaches/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_mob_approaches/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_mob_approaches/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	for(var/mob/living/M in range(approach_range, R))
		if(M == R)
			continue
		if(M.stat != CONSCIOUS)
			continue
		if(check_faction && _is_faction_friend(R, M))
			log_game("CIRCUIT mob_approaches: skipping [M] - faction friend of [R]")
			continue
		log_game("CIRCUIT mob_approaches: [R] detects [M] at dist=[get_dist(R,M)] check_faction=[check_faction]")
		_trigger(R)
		return


// -- ON MOB THIRSTY ----------------------------------

/datum/behavior_circuit/trigger/on_mob_thirsty
	circuit_name = "Trigger: Mob Thirsty Nearby"
	circuit_desc = "Fires when a thirsty human is in sensor range."
	tutorial_text = "Fires when a thirsty human is in sensor range. Used by drink-bot builds. Pair with the Offer Drink response, which requires an Injector hardware datum loaded with a drink reagent."
	cpu_cost = 2
	var/last_check = 0
	var/check_cooldown = 50

/datum/behavior_circuit/trigger/on_mob_thirsty/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_mob_thirsty/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_mob_thirsty/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/obj/item/behavior_assembly/A = get_assembly()
	var/scan_range = A ? A.sensor_range : 5
	for(var/mob/living/carbon/human/H in range(scan_range, R))
		if(H.stat == DEAD)
			continue
		if(H.thirst <= THIRST_LEVEL_THIRSTY)
			_trigger(R)
			return


// -- ON MOB INJURED ----------------------------------

/datum/behavior_circuit/trigger/on_mob_injured
	circuit_name = "Trigger: Mob Injured Nearby"
	circuit_desc = "Fires when a friendly mob below a health threshold is in range."
	tutorial_text = "Fires when a friendly mob (same faction) is below the health threshold in sensor range. Configure 'health_threshold' as a percentage 0-100 (default 50 = below 50% health). Pair with: Inject Reagent, Self Repair Pulse, or Follow Linked Target."
	cpu_cost = 2
	var/last_check = 0
	var/check_cooldown = 50
	var/health_threshold = 50  // percentage 0-100

/datum/behavior_circuit/trigger/on_mob_injured/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_mob_injured/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_mob_injured/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/obj/item/behavior_assembly/A = get_assembly()
	var/scan_range = A ? A.sensor_range : 5
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(!_is_faction_friend(R, M))  // skip enemies
			continue
		// Compare as percentage so it works correctly across all robot health pools
		var/health_pct = (M.health / max(M.maxHealth, 1)) * 100
		if(health_pct < health_threshold)
			_trigger(R)
			return


// -- ON NIGHT CYCLE ----------------------------------

/datum/behavior_circuit/trigger/on_night_cycle
	circuit_name = "Trigger: On Night Cycle"
	circuit_desc = "Fires when the world time enters the night window."
	tutorial_text = "Fires once per in-game night period. Configure 'night_start' and 'night_end' in ticks. Good for: patrol robots that behave differently after dark, lighting systems, or security bots that activate at night."
	cpu_cost = 1
	var/night_start = 180000
	var/night_end   = 360000
	var/already_triggered = FALSE

/datum/behavior_circuit/trigger/on_night_cycle/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_night_cycle/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_night_cycle/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/t = world.time % 360000
	// AND: both conditions must hold so "night" is a real window, not always-true
	var/in_night = (t >= night_start && t < night_end)
	if(in_night && !already_triggered)
		already_triggered = TRUE
		_trigger(R)
	else if(!in_night)
		already_triggered = FALSE


// -- ON MESS DETECTED --------------------------------

/datum/behavior_circuit/trigger/on_mess_detected
	circuit_name = "Trigger: On Mess Detected"
	circuit_desc = "Fires when blood, reagent spills, or dirt are found nearby."
	tutorial_text = "Fires when blood, spills, or dirt decals are found on nearby turfs. Good for janitor robots. Pair with Emote Action to announce the mess, or any cleaning response. Triggers on blood footprints from wounded humans."
	cpu_cost = 1
	var/last_check = 0
	var/check_cooldown = 50

/datum/behavior_circuit/trigger/on_mess_detected/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_mess_detected/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_mess_detected/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	// Only trigger on actual cleanable decals - NOT ambient reagents (water, air etc)
	for(var/turf/T in range(3, R))
		for(var/obj/effect/decal/cleanable/C in T.contents)
			_trigger(R)
			return


// -- ON ACCESS GRANTED -------------------------------

/datum/behavior_circuit/trigger/on_access_granted
	needs_hardware = TRUE
	circuit_name = "Trigger: On Access Granted"
	hardware_slot_name = HW_SLOT_ID_READER
	required_hardware_type = /datum/robot_hardware/id_reader
	circuit_desc = "Fires when an ID scan by the robot succeeds."
	tutorial_text = "HARDWARE REQUIRED: ID Reader. Fires when the robot scans an ID with valid access. Good for: door-guard robots, greeter builds, or escort bots that unlock on ID confirmation. Pair with Say Text or Follow Linked Target."
	cpu_cost = 1
	var/last_check = 0
	var/check_cooldown = 10
	var/last_scan_time = 0

/datum/behavior_circuit/trigger/on_access_granted/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_access_granted/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_access_granted/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return
	var/datum/robot_hardware/id_reader/IDR = get_hardware(R, /datum/robot_hardware/id_reader)
	if(!IDR)
		return
	if(IDR.last_scan_time && IDR.last_scan_time != last_scan_time)
		last_scan_time = IDR.last_scan_time
		_trigger(R)


// -- ON SPEECH HEARD ---------------------------------

/datum/behavior_circuit/trigger/on_speech_heard
	needs_hardware = TRUE
	circuit_name = "Trigger: On Speech Heard"
	hardware_slot_name = HW_SLOT_MICROPHONE
	required_hardware_type = /datum/robot_hardware/microphone
	circuit_desc = "Fires when the robot's microphone picks up speech."
	tutorial_text = "HARDWARE REQUIRED: Microphone. Fires when the robot picks up new speech nearby. Good for: companion robots that respond when spoken to, voice-activated alarms, or logging conversations."
	cpu_cost = 2
	var/last_heard = 0
	var/hear_cooldown = 10
	var/last_message = ""

/datum/behavior_circuit/trigger/on_speech_heard/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	// Snapshot current mic state so stale messages don't trigger immediately on insertion
	var/datum/robot_hardware/microphone/MIC = get_hardware(R, /datum/robot_hardware/microphone)
	if(MIC)
		last_message = MIC.last_heard_message
	last_heard = world.time
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_speech_heard/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_speech_heard/process()
	if(world.time < last_heard + hear_cooldown)
		return
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return
	var/datum/robot_hardware/microphone/MIC = get_hardware(R, /datum/robot_hardware/microphone)
	if(!MIC)
		return
	// microphone datum stores last heard message in its last_message var
	var/msg = MIC.last_heard_message
	if(msg && msg != last_message && MIC.last_heard_time > last_heard)
		last_message = msg
		last_heard = world.time
		_trigger(R)


// -- ON WEAPON FIRED ---------------------------------

/datum/behavior_circuit/trigger/on_weapon_fired
	needs_hardware = TRUE
	circuit_name = "Trigger: On Robot Fires Weapon"
	hardware_slot_name = HW_SLOT_WEAPON
	required_hardware_type = /datum/robot_hardware/weapon
	circuit_desc = "Fires each time THIS robot fires its own weapon. Not triggered when the robot is shot at."
	tutorial_text = "HARDWARE REQUIRED: Weapon hardware datum. Fires each time the robot's weapon discharges. Good for: sound effects on fire, logging shots, or chaining a secondary action after each attack."
	cpu_cost = 1
	var/last_shot = 0

/datum/behavior_circuit/trigger/on_weapon_fired/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_weapon_fired/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_weapon_fired/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return
	var/datum/robot_hardware/weapon/WH = get_hardware(R, /datum/robot_hardware/weapon)
	if(!WH)
		return
	if(WH.last_fire_time && WH.last_fire_time != last_shot)
		last_shot = WH.last_fire_time
		_trigger(R)


// -- ON HIT -----------------------------------------
// Fires when the robot is struck by a projectile.
// Hooks into the existing bullet_act() tracking.

/datum/behavior_circuit/trigger/on_hit
	circuit_name = "Trigger: On Hit"
	circuit_desc = "Fires when the robot is struck by a projectile or attack."
	tutorial_text = "Fires when this robot takes a projectile hit. Good for: last-resort detonation, retaliation triggers, distress signals on first damage. No hardware required."
	cpu_cost = 1
	var/last_hit_time = 0

/datum/behavior_circuit/trigger/on_hit/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	last_hit_time = R.last_damage_time
	START_PROCESSING(SSfastprocess, src)

/datum/behavior_circuit/trigger/on_hit/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSfastprocess, src)
	. = ..()

/datum/behavior_circuit/trigger/on_hit/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R)
		STOP_PROCESSING(SSfastprocess, src)
		return
	if(R.last_damage_time > last_hit_time)
		last_hit_time = R.last_damage_time
		_trigger(R)


// -- ON SIGNAL RECEIVED ------------------------------

/datum/behavior_circuit/trigger/on_signal_received
	needs_hardware = TRUE
	circuit_name = "Trigger: On Signal Received"
	hardware_slot_name = HW_SLOT_SIGNALER
	required_hardware_type = /datum/robot_hardware/signaler
	circuit_desc = "Fires when a radio signal is received on the configured frequency."
	tutorial_text = "HARDWARE REQUIRED: Signaler. Fires when a matching radio signal is received. Good for: remotely commanded robots. Send a signal on the configured frequency and the robot executes its response. Pair with Say Text, Enter Combat Mode, or any response."
	cpu_cost = 2
	var/last_received = 0
	var/signal_cooldown = 5

/datum/behavior_circuit/trigger/on_signal_received/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_signal_received/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_signal_received/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return
	var/datum/robot_hardware/signaler/SIG = get_hardware(R, /datum/robot_hardware/signaler)
	if(!SIG)
		return
	if(SIG.last_received_time && SIG.last_received_time > last_received)
		if(world.time > last_received + signal_cooldown)
			last_received = world.time
			_trigger(R)


// -- ON GPS ZONE -------------------------------------

/datum/behavior_circuit/trigger/on_gps_zone
	needs_hardware = TRUE
	circuit_name = "Trigger: On GPS Zone"
	hardware_slot_name = HW_SLOT_GPS
	required_hardware_type = /datum/robot_hardware/gps
	circuit_desc = "Fires when the robot is within defined map coordinates."
	tutorial_text = "HARDWARE REQUIRED: GPS. Fires when the robot is inside the defined coordinate zone. Configure 'zone_x1', 'zone_y1', 'zone_x2', 'zone_y2'. Chain multiple assemblies with different GPS zones to build a patrol route."
	cpu_cost = 2
	var/zone_x1 = 0
	var/zone_y1 = 0
	var/zone_x2 = 255
	var/zone_y2 = 255
	var/last_check = 0
	var/check_cooldown = 20
	var/in_zone = FALSE

/datum/behavior_circuit/trigger/on_gps_zone/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_gps_zone/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_gps_zone/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return
	var/datum/robot_hardware/gps/GPS = get_hardware(R, /datum/robot_hardware/gps)
	if(!GPS)
		return
	var/turf/here = get_turf(R)
	if(!here)
		return
	var/gx = here.x
	var/gy = here.y
	var/now_in = (gx >= zone_x1 && gx <= zone_x2 && gy >= zone_y1 && gy <= zone_y2)
	if(now_in && !in_zone)
		in_zone = TRUE
		_trigger(R)
	else if(!now_in)
		in_zone = FALSE


// -- ON ATMOS THRESHOLD ------------------------------

/datum/behavior_circuit/trigger/on_radiation_detected
	needs_hardware = TRUE
	circuit_name = "Trigger: On Radiation Detected"
	hardware_slot_name = HW_SLOT_ENV_SCANNER
	required_hardware_type = /datum/robot_hardware/environment_scanner
	circuit_desc = "Fires when the robot detects significant radiation on itself or nearby survivors."
	tutorial_text = "HARDWARE REQUIRED: Environment Scanner. Fires when the robot's own radiation level exceeds the threshold, or when a nearby mob has radiation above the threshold. Good for: RadAway dispensers, hazmat warnings, evacuation triggers. Pair with Broadcast Alert or Spray Reagent."
	cpu_cost = 2
	var/rad_threshold  = 10
	var/scan_range     = 5
	var/last_check     = 0
	var/check_cooldown = 30

/datum/behavior_circuit/trigger/on_radiation_detected/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_radiation_detected/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_radiation_detected/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return
	// Fire if the robot itself is irradiated
	if(R.radiation >= rad_threshold)
		_trigger(R)
		return
	// Fire if a nearby survivor is irradiated
	for(var/mob/living/carbon/M in range(scan_range, R))
		if(M.radiation >= rad_threshold)
			_trigger(R)
			return


// -- ON HEALTH SCAN CRITICAL -------------------------

/datum/behavior_circuit/trigger/on_health_scan_critical
	needs_hardware = TRUE
	circuit_name = "Trigger: Health Scan Critical"
	hardware_slot_name = HW_SLOT_HEALTH_SCANNER
	required_hardware_type = /datum/robot_hardware/health_scanner
	circuit_desc = "Fires when the robot's health scanner detects a critically injured mob."
	tutorial_text = "HARDWARE REQUIRED: Health Scanner. Fires when the scanner finds a mob with critical injuries in range. More precise than On Mob Injured. Good for medic robots. Pair with Inject Reagent or Say Text."
	cpu_cost = 2
	var/damage_threshold = 80
	var/last_check = 0
	var/check_cooldown = 30

/datum/behavior_circuit/trigger/on_health_scan_critical/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_health_scan_critical/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_health_scan_critical/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return
	var/datum/robot_hardware/health_scanner/HS = get_hardware(R, /datum/robot_hardware/health_scanner)
	if(!HS)
		return
	var/obj/item/behavior_assembly/A = get_assembly()
	var/scan_range = A ? A.sensor_range : 5
	for(var/mob/living/carbon/M in range(scan_range, R))
		if(M.stat == DEAD)
			continue
		if((M.getBruteLoss() + M.getFireLoss() + M.getToxLoss() + M.getOxyLoss()) >= damage_threshold)
			_trigger(R)
			return




// -- ON LOW HEALTH -----------------------------------

/datum/behavior_circuit/trigger/on_low_health
	circuit_name = "Trigger: On Low Health"
	circuit_desc = "Fires once when the robot's health drops below a threshold."
	tutorial_text = "Fires once when the robot crosses below the health threshold, then resets when health recovers above it (with 10% hysteresis). Configure 'health_threshold' (0.0-1.0, default 0.25 = 25% max health). Good for: retreat-when-hurt, distress calls, emergency self-repair. Pairs well with Flee From Threat or Broadcast Distress."
	cpu_cost = 1
	var/health_threshold = 0.25
	var/already_triggered = FALSE

/datum/behavior_circuit/trigger/on_low_health/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	already_triggered = (R.health <= R.maxHealth * health_threshold)
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_low_health/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_low_health/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/ratio = R.health / max(R.maxHealth, 1)
	if(ratio <= health_threshold && !already_triggered)
		already_triggered = TRUE
		_trigger(R)
	else if(ratio > health_threshold + 0.1)
		already_triggered = FALSE


// -- ON ALLY UNDER ATTACK ----------------------------

/datum/behavior_circuit/trigger/on_ally_under_attack
	circuit_name = "Trigger: On Ally Under Attack"
	circuit_desc = "Fires when a nearby friendly mob takes damage."
	tutorial_text = "Scans for faction-matched mobs in range whose health dropped since last check. Configure 'scan_range' (default 9) and 'damage_threshold' (default 5). Fires when an ally loses that much HP in a single scan window. Good for: group defense, sentries that rally when allies are shot, backup calls. Pairs well with Enter Combat Mode, Broadcast Alert, or Pathfind To Enemy."
	cpu_cost = 2
	var/scan_range = 9
	var/damage_threshold = 5
	var/last_check = 0
	var/check_cooldown = 15
	var/last_fire = 0
	var/fire_cooldown = 40
	var/list/ally_health_snapshot = null

/datum/behavior_circuit/trigger/on_ally_under_attack/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	ally_health_snapshot = list()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_ally_under_attack/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	ally_health_snapshot = null
	. = ..()

/datum/behavior_circuit/trigger/on_ally_under_attack/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	if(world.time < last_fire + fire_cooldown)
		return
	var/list/new_snapshot = list()
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(!_is_faction_friend(R, M))
			continue
		var/mref = REF(M)
		new_snapshot[mref] = M.health
		if(ally_health_snapshot && (mref in ally_health_snapshot))
			var/old_hp = ally_health_snapshot[mref]
			if(old_hp - M.health >= damage_threshold)
				ally_health_snapshot = new_snapshot
				last_fire = world.time
				_trigger(R)
				return
	ally_health_snapshot = new_snapshot


// -- ON COMBAT SOUND NEARBY --------------------------

/datum/behavior_circuit/trigger/on_combat_sound_nearby
	needs_hardware = TRUE
	circuit_name = "Trigger: On Combat Sound Nearby"
	hardware_slot_name = HW_SLOT_MICROPHONE
	required_hardware_type = /datum/robot_hardware/microphone
	circuit_desc = "Fires when the robot's microphone picks up nearby gunfire or combat sounds."
	tutorial_text = "HARDWARE REQUIRED: Microphone. Fires when the mic picks up a combat sound — gunshots, projectile impacts — within hearing range. Unlike On Speech Heard which only fires on speech, this fires when bullet_act sets last_combat_time on the mic hardware. Good for: alert sentries that activate when shooting starts, guards that investigate combat sounds."
	cpu_cost = 2
	var/hear_cooldown = 30
	var/last_combat_time = 0

/datum/behavior_circuit/trigger/on_combat_sound_nearby/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	var/datum/robot_hardware/microphone/MIC = get_hardware(R, /datum/robot_hardware/microphone)
	if(MIC)
		last_combat_time = MIC.last_combat_time
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_combat_sound_nearby/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_combat_sound_nearby/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/datum/robot_hardware/microphone/MIC = get_hardware(R, /datum/robot_hardware/microphone)
	if(!MIC)
		return
	if(MIC.last_combat_time > last_combat_time)
		last_combat_time = MIC.last_combat_time
		_trigger(R)

// ====================================================
// RESPONSE CIRCUITS
// ====================================================
// Note: Hardware-dependent responses check for the required
// IC at runtime. If the IC is absent, execution silently
// returns. No CERT_CAN_* flags are checked here - those
// gates were replaced by hardware presence checks, which
// are more intuitive and make the workshop self-documenting.
// ====================================================


// -- BROADCAST ALERT ---------------------------------

/datum/behavior_circuit/response/broadcast_alert
	circuit_name = "Response: Broadcast Alert"
	circuit_desc = "Broadcasts a radio alert message on the robot's channel."
	tutorial_text = "Broadcasts a message on the robot's radio channel. No hardware required. Configure 'alert_message'. Good for: distress calls, zone announcements, status reports."
	cpu_cost = 1
	var/alert_message = "WARNING: Threat detected."

/datum/behavior_circuit/response/broadcast_alert/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	// Use radio prefix so the alert goes out over the robot's radio channel.
	// Silicon say() with ";" routes through the installed radio automatically.
	R.say(";[alert_message]")


// -- BROADCAST DISTRESS ------------------------------

/datum/behavior_circuit/response/broadcast_distress
	circuit_name = "Response: Broadcast Distress Signal"
	circuit_desc = "Broadcasts a distress call including current location."
	tutorial_text = "Broadcasts a distress call that includes the robot's current location. No configuration needed. Good for: damage events, low health, or being attacked."
	cpu_cost = 1

/datum/behavior_circuit/response/broadcast_distress/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/area/here = get_area(R)
	var/loc = here ? here.name : "unknown location"
	var/msg = "[R.name]: DISTRESS — unit down at [loc]! Requesting assistance!"
	// R.say() is gated on consciousness. Use direct chat + radio so it works when dead.
	var/turf/T = get_turf(R)
	if(T)
		playsound(T, 'sound/machines/alarm.ogg', 60, 1)
	for(var/mob/living/M in range(7, R))
		to_chat(M, span_danger(msg))
	if(R.radio)
		R.radio.talk_into(R, msg, null, null, null)


// -- SAY TEXT ----------------------------------------

/datum/behavior_circuit/response/say_text
	circuit_name = "Response: Say Text"
	circuit_desc = "Robot speaks a line of text aloud."
	tutorial_text = "The robot says a message aloud. Configure 'say_string'. Good for: greetings, warnings, personality, or responding to speech triggers. No hardware required."
	cpu_cost = 1
	var/say_string = "Beep."

/datum/behavior_circuit/response/say_text/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	// Check for speaker hardware for enhanced audio output
	var/datum/robot_hardware/speaker/SPK = get_hardware(R, /datum/robot_hardware/speaker)
	if(SPK)
		playsound(R, SPK.sound_file, SPK.volume, 1)
	R.say(say_string)


// -- EMOTE ACTION ------------------------------------

/datum/behavior_circuit/response/emote_action
	circuit_name = "Response: Emote Action"
	circuit_desc = "Robot performs a visible emote or ambient action."
	tutorial_text = "The robot performs a visible emote. Configure 'emote_text' -- it appears in chat as the robot's name followed by the emote text. Good for personality: beeping, gesturing, reacting to stimuli. No hardware required."
	cpu_cost = 1
	var/emote_text = "beeps cheerfully"

/datum/behavior_circuit/response/emote_action/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	R.visible_message(span_notice("[R] [emote_text]."))


// -- ENTER COMBAT MODE -------------------------------

/datum/behavior_circuit/response/enter_combat_mode
	circuit_name = "Response: Enter Combat Mode"
	circuit_desc = "Switches the robot into combat stance."
	tutorial_text = "Switches the robot into combat stance. No hardware required. This is a mode change, not an attack. Pair with Fire Weapon or Pathfind To Enemy to make the robot actually fight."
	cpu_cost = 1

/datum/behavior_circuit/response/enter_combat_mode/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	R.a_intent = INTENT_HARM


// -- SELF REPAIR PULSE -------------------------------

/datum/behavior_circuit/response/self_repair_pulse
	circuit_name = "Response: Self Repair Pulse"
	circuit_desc = "Instantly repairs a small amount of the robot's damage."
	tutorial_text = "The robot heals itself for a small amount. No hardware required. Configure 'repair_amount' (default 15). Costs cell charge proportional to repair amount — larger pulses drain the battery faster. Pair with On Take Damage."
	cpu_cost = 2
	var/repair_amount = 15
	/// Cell charge consumed per repair point. 10 charge per HP = meaningful but not crippling.
	var/energy_cost_per_hp = 10

/datum/behavior_circuit/response/self_repair_pulse/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.cell)
		return
	var/energy_needed = repair_amount * energy_cost_per_hp
	if(R.cell.charge < energy_needed)
		if(R.stat != DEAD)  // only warn if alive; dead robot can't speak
			R.visible_message(span_warning("[R]'s repair pulse sputters — insufficient power."))
		return
	R.cell.charge -= energy_needed
	if(R.stat == DEAD)
		// Must zero out brute BEFORE revive() so can_be_revived() passes (health > HEALTH_THRESHOLD_DEAD).
		// adjustBruteLoss(-getBruteLoss()) clears all brute regardless of repair_amount,
		// guaranteeing health crosses the threshold. The cell drain is the cost limiter.
		R.adjustBruteLoss(-R.getBruteLoss())
		R.adjustFireLoss(-R.getFireLoss())
		R.revive()
		R.visible_message(span_notice("[R] emergency repair pulse fires — unit back online!"))
	else
		R.heal_bodypart_damage(repair_amount, repair_amount)
		R.visible_message(span_notice("[R] emits a brief repair pulse."))


// -- EMERGENCY LOCKDOWN ------------------------------

/datum/behavior_circuit/response/lockdown_self
	circuit_name = "Response: Emergency Lockdown"
	circuit_desc = "Anchors the robot in place and plays an alarm."
	tutorial_text = "Anchors the robot in place and sounds an alarm. Good for: area denial, security checkpoints, or self-preservation. Combine with Broadcast Distress for a full emergency response. No hardware required."
	cpu_cost = 1

/datum/behavior_circuit/response/lockdown_self/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	R.anchored = TRUE
	R.a_intent = INTENT_HARM
	R.visible_message(span_danger("[R] locks down! SECURITY ALERT!"))
	playsound(R, 'sound/machines/alarm.ogg', 50, 1)


// -- PATHFIND TO ENEMY -------------------------------

/datum/behavior_circuit/response/pathfind_to_enemy
	circuit_name = "Response: Pathfind To Enemy"
	circuit_desc = "Moves the robot toward the nearest hostile mob."
	tutorial_text = "Steps toward the nearest enemy each time it fires. For faster pursuit pair with a short On Interval trigger. No hardware required."
	cpu_cost = 2

/datum/behavior_circuit/response/pathfind_to_enemy/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.anchored || R.stat == DEAD)
		return
	var/scan_range = A ? A.sensor_range : 7
	var/mob/living/target = null
	var/closest_dist = INFINITY
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(_is_faction_friend(R, M))
			continue
		var/d = get_dist(R, M)
		if(d < closest_dist)
			closest_dist = d
			target = M
	if(!target)
		return
	if(target in view(get_turf(R)))
		step(R, get_dir(get_turf(R), get_step_towards(get_turf(R), target)))
	else
		step_towards(R, target)


// -- FOLLOW FRIENDLY ---------------------------------

/datum/behavior_circuit/response/follow_target
	circuit_name = "Response: Follow Linked Target"
	circuit_desc = "Follows a specific mob linked by multitool ID scan."
	tutorial_text = "Steps toward a specific linked mob. To link a target: scan their ID card with a multitool, then use the multitool on the robot. The link persists until reprogrammed. If the target is dead or gone, does nothing. Pair with On Interval for continuous escort. No hardware required."
	cpu_cost = 2
	var/datum/weakref/linked_target_ref = null
	var/linked_target_name = ""

/datum/behavior_circuit/response/follow_target/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.anchored || R.stat == DEAD)
		return
	if(!linked_target_ref)
		return  // no target set yet - silent until linked via multitool
	var/mob/living/target = linked_target_ref.resolve()
	if(!target || QDELETED(target))
		// Target qdel'd entirely (left server etc)
		linked_target_ref = null
		R.say("Escort target lost. Awaiting new link.")
		return
	if(target.stat == DEAD)
		return  // target is dead/unconscious - hold position silently
	if(get_dist(R, target) <= 1)
		return  // already adjacent, no need to step
	step_towards(R, target)
	R.setDir(get_dir(R, target))

/// Called by multitool linkage - sets the follow target
/datum/behavior_circuit/response/follow_target/proc/set_linked_target(mob/living/new_target, mob/user)
	linked_target_ref = WEAKREF(new_target)
	linked_target_name = new_target.name
	if(user)
		to_chat(user, span_notice("Follow target linked: [new_target.name]."))


// -- REMEMBER LAST ENEMY -----------------------------
// Writes the nearest hostile's weakref+name into Memory Core.
// Paired with On Remembered Enemy to recall and re-engage
// after losing sight (e.g. enemy ducked around a corner).

/datum/behavior_circuit/response/remember_enemy
	circuit_name = "Response: Remember Last Enemy"
	circuit_desc = "Stores the nearest hostile in Memory Core for later recall."
	tutorial_text = "HARDWARE REQUIRED: Memory Core. Writes the nearest hostile mob into the 'last_enemy' memory slot. Pair with Trigger: On Remembered Enemy to re-engage after losing line of sight. Without a Memory Core this does nothing."
	needs_hardware = TRUE
	hardware_slot_name = HW_SLOT_MEMORY
	required_hardware_type = /datum/robot_hardware/memory_core
	cpu_cost = 1

/datum/behavior_circuit/response/remember_enemy/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/memory_core/MEM = get_hardware(R, /datum/robot_hardware/memory_core)
	if(!MEM)
		return
	var/scan_range = A ? A.sensor_range : 10
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD || QDELETED(M))
			continue
		if(_is_faction_friend(R, M))
			continue  // skip friendlies
		MEM.write("last_enemy", WEAKREF(M))
		MEM.write("last_enemy_name", M.name)
		return


// -- ON REMEMBERED ENEMY ------------------------------
// Fires when Memory Core has a stored enemy that is still
// alive, acting as a "persistent hunt" trigger.

/datum/behavior_circuit/trigger/on_remembered_enemy
	circuit_name = "Trigger: On Remembered Enemy"
	circuit_desc = "Fires when a previously remembered enemy is still alive and trackable."
	tutorial_text = "HARDWARE REQUIRED: Memory Core. Fires periodically while the 'last_enemy' memory slot holds a living mob. Pair with Response: Remember Last Enemy (on On Enemy Spotted) to create persistent hunt behavior: robot chases after an enemy even after losing direct sensor contact."
	needs_hardware = TRUE
	hardware_slot_name = HW_SLOT_MEMORY
	required_hardware_type = /datum/robot_hardware/memory_core
	cpu_cost = 1
	var/check_interval = 20
	var/last_check = 0

/datum/behavior_circuit/trigger/on_remembered_enemy/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	last_check = world.time
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_remembered_enemy/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_remembered_enemy/process()
	if(world.time < last_check + check_interval)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/datum/robot_hardware/memory_core/MEM = get_hardware(R, /datum/robot_hardware/memory_core)
	if(!MEM)
		return
	var/datum/weakref/enemy_ref = MEM.read("last_enemy")
	if(!enemy_ref)
		return
	var/mob/living/enemy = enemy_ref.resolve()
	if(!enemy || enemy.stat == DEAD || QDELETED(enemy))
		// Enemy is gone - clear the memory slot
		MEM.clear("last_enemy")
		MEM.clear("last_enemy_name")
		return
	_trigger(R)


// -- FLEE FROM THREAT --------------------------------

/datum/behavior_circuit/response/flee_from_threat
	circuit_name = "Response: Flee From Threat"
	circuit_desc = "Moves away from the nearest hostile mob."
	tutorial_text = "Steps away from the nearest enemy each time it fires. Combine with On Take Damage for a robot that retreats when hit. No hardware required."
	cpu_cost = 2

/datum/behavior_circuit/response/flee_from_threat/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.anchored || R.stat == DEAD)
		return
	var/scan_range = A ? A.sensor_range : 5
	var/mob/living/threat = null
	var/closest_dist = INFINITY
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(_is_faction_friend(R, M))
			continue
		var/d = get_dist(R, M)
		if(d < closest_dist)
			closest_dist = d
			threat = M
	if(!threat)
		return
	step_away(R, threat)


// -- MOVE DIRECTION ----------------------------------

/datum/behavior_circuit/response/move_direction
	circuit_name = "Response: Move Direction"
	circuit_desc = "Steps the robot one tile in a fixed direction."
	tutorial_text = "Steps one tile in a fixed direction each time it fires. Configure 'move_dir' (NORTH/SOUTH/EAST/WEST). Pair with On Interval for a simple patrol loop. Chain two assemblies moving in opposite directions for a back-and-forth route."
	cpu_cost = 1
	var/move_dir = SOUTH

/datum/behavior_circuit/response/move_direction/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.anchored || R.stat == DEAD)
		return
	step(R, move_dir)


// -- FIRE WEAPON -------------------------------------

/datum/behavior_circuit/response/fire_weapon
	needs_hardware = TRUE
	circuit_name = "Response: Fire Weapon"
	hardware_slot_name = HW_SLOT_WEAPON
	required_hardware_type = /datum/robot_hardware/weapon
	circuit_desc = "Fires the robot's weapon at the nearest enemy. Requires Weapon hardware."
	tutorial_text = "HARDWARE REQUIRED: Weapon hardware datum. Fires the weapon at the nearest hostile in sensor range. Does nothing if no enemy is in range. Pair with On Enemy Spotted for auto-turret, or On Take Damage for retaliation. Set require_los=FALSE for retaliation builds so walls don't block the shot."
	cpu_cost = 3
	/// If TRUE, skips targets with no line of sight. Set FALSE for retaliation builds.
	var/require_los = TRUE

/datum/behavior_circuit/response/fire_weapon/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/weapon/WH = get_hardware(R, /datum/robot_hardware/weapon)
	if(!WH)
		log_game("CIRCUIT fire_weapon: no weapon hardware on [R]")
		return
	var/scan_range = (A ? A.sensor_range : 7) + WH.fire_range
	var/mob/living/target = null

	// Retaliation: if robot was attacked recently (within 5s), shoot back at that attacker directly.
	if(R.last_attacker_ref)
		var/mob/living/attacker = R.last_attacker_ref.resolve()
		var/age = world.time - R.last_attacker_time
		if(age > 50)
			log_game("CIRCUIT fire_weapon: last_attacker_ref expired age=[age] ticks")
		else if(!attacker)
			log_game("CIRCUIT fire_weapon: last_attacker_ref resolve() returned null (GCd?)")
		else if(attacker.stat == DEAD)
			log_game("CIRCUIT fire_weapon: last attacker=[attacker] is dead")
		else if(_is_faction_friend(R, attacker))
			log_game("CIRCUIT fire_weapon: attacker=[attacker] is faction friend of [R], skipping retaliation")
		else
			target = attacker
			log_game("CIRCUIT fire_weapon: retaliation target=[attacker]")
	else
		log_game("CIRCUIT fire_weapon: last_attacker_ref is null - pending_attacker_ref was=[R.pending_attacker_ref]")

	// Fallback: scan for nearest visible hostile in range.
	// view() instead of range() — range() ignores walls, so the robot would fixate on
	// targets through solid walls that it can never actually shoot.
	if(!target)
		var/closest_dist = INFINITY
		for(var/mob/living/M in view(scan_range, R))
			if(M == R || M.stat == DEAD)
				continue
			if(_is_faction_friend(R, M))
				continue
			var/d = get_dist(R, M)
			if(d < closest_dist)
				closest_dist = d
				target = M

	if(!target)
		log_game("CIRCUIT fire_weapon: no visible target in range=[scan_range]")
		return
	WH.fire_at(R, target)


// -- FIRE AIR CANNON ---------------------------------

/datum/behavior_circuit/response/fire_air_cannon
	needs_hardware = TRUE
	circuit_name = "Response: Fire Air Cannon"
	hardware_slot_name = HW_SLOT_AIR_CANNON
	required_hardware_type = /datum/robot_hardware/air_cannon
	circuit_desc = "Fires the pneumatic cannon at the nearest enemy. Requires Air Cannon hardware."
	tutorial_text = "HARDWARE REQUIRED: Air Cannon hardware datum. Non-lethal suppression: knocks nearby hostiles back without dealing damage. Good for crowd control robots."
	cpu_cost = 3

/datum/behavior_circuit/response/fire_air_cannon/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/air_cannon/AC = get_hardware(R, /datum/robot_hardware/air_cannon)
	if(!AC)
		return
	if(AC.gas_volume <= 0)
		R.visible_message(span_warning("[R]'s pneumatic cannon hisses — out of propellant!"))
		return
	var/scan_range = A ? A.sensor_range : 7
	var/mob/living/target = null
	var/closest_dist = INFINITY
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(_is_faction_friend(R, M))
			continue
		var/d = get_dist(R, M)
		if(d < closest_dist)
			closest_dist = d
			target = M
	if(!target)
		return
	if(!(target in view(scan_range, R)))
		return
	// Throw the target with configured knockback, consume propellant
	var/turf/here = get_turf(R)
	var/throw_dir = get_dir(here, get_turf(target))
	target.throw_at(get_step(get_turf(target), throw_dir), AC.knockback_force, 1, R)
	AC.gas_volume = max(0, AC.gas_volume - 1)
	R.visible_message(span_warning("[R] fires a burst of compressed air at [target]! ([AC.gas_volume] shots remaining)"))


// -- DETONATE SELF -----------------------------------

/datum/behavior_circuit/response/detonate_self
	circuit_name = "Response: Detonate Self"
	circuit_desc = "Triggers a self-destruct explosion after a short delay."
	tutorial_text = "The robot announces its detonation then explodes after 3 seconds. Any robot can self-destruct if programmed to. Pair with On Death for a deadman switch or On Enemy Spotted for a suicide build. No hardware required."
	cpu_cost = 2

/datum/behavior_circuit/response/detonate_self/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/turf/T = get_turf(R)
	// Bypass visible_message which may be gated on consciousness
	for(var/mob/living/M in range(5, R))
		to_chat(M, span_danger("[R] begins emitting a high-pitched whine!"))
	if(T)
		playsound(T, 'sound/machines/alarm.ogg', 75, 1)
	addtimer(CALLBACK(src, PROC_REF(_boom), R), 30, TIMER_UNIQUE|TIMER_OVERRIDE)

/datum/behavior_circuit/response/detonate_self/proc/_boom(mob/living/silicon/robot/R)
	if(QDELETED(R))
		return
	explosion(R, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 3, flash_range = 4)
	// Fully destroy the robot chassis - not just kill it
	if(!QDELETED(R))
		R.gib()


// -- PRIME GRENADE -----------------------------------

/datum/behavior_circuit/response/prime_grenade
	needs_hardware = TRUE
	circuit_name = "Response: Prime Grenade"
	hardware_slot_name = HW_SLOT_GRENADE
	required_hardware_type = /datum/robot_hardware/grenade_launcher
	circuit_desc = "Arms and throws the grenade at the nearest enemy. Requires Grenade Launcher hardware."
	tutorial_text = "HARDWARE REQUIRED: Grenade Launcher hardware datum with a grenade loaded. Arms and throws the grenade at the nearest enemy. Does nothing if no grenade is loaded. Configure 'detonation_time' (default 3 seconds)."
	cpu_cost = 2
	var/detonation_time = 3

/datum/behavior_circuit/response/prime_grenade/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/grenade_launcher/GL = get_hardware(R, /datum/robot_hardware/grenade_launcher)
	if(!GL)
		return
	// Find a loaded grenade - either player-inserted or hardware-spawned on install
	var/obj/item/grenade/G = locate(/obj/item/grenade) in R
	if(!G)
		R.visible_message(span_warning("[R]'s grenade launcher is empty!"))
		return
	var/scan_range = A ? A.sensor_range : 5
	var/mob/living/target = null
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(_is_faction_friend(R, M))
			continue
		target = M
		break
	if(!target)
		return
	var/grenade_scan_range = A ? A.sensor_range : 5
	if(!(target in view(grenade_scan_range, R)))
		return
	// Prime the grenade and throw it from the robot's position
	G.prime()
	G.throw_at(target, 7, 1, R)
	R.visible_message(span_danger("[R] launches [G] at [target]!"))


// -- THROW ITEM AT ENEMY -----------------------------

/datum/behavior_circuit/response/throw_item_at_enemy
	needs_hardware = TRUE
	circuit_name = "Response: Throw Item At Enemy"
	hardware_slot_name = HW_SLOT_THROWER
	required_hardware_type = /datum/robot_hardware/thrower
	circuit_desc = "Throws a held item at the nearest hostile. Requires Thrower hardware."
	tutorial_text = "HARDWARE REQUIRED: Thrower hardware datum. Throws a held item at the nearest hostile. The robot must be holding something first -- pair with Grab Nearest Item. Good for improvised weapon robots or distracting enemies."
	cpu_cost = 2

/datum/behavior_circuit/response/throw_item_at_enemy/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/thrower/TH = get_hardware(R, /datum/robot_hardware/thrower)
	if(!TH)
		return
	// Find something to throw from the robot's held items
	var/obj/item/projectile = null
	for(var/obj/item/I in R)
		if(!I.anchored)
			projectile = I
			break
	if(!projectile)
		return
	var/scan_range = A ? A.sensor_range : 7
	var/mob/living/target = null
	var/closest_dist = INFINITY
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(_is_faction_friend(R, M))
			continue
		var/d = get_dist(R, M)
		if(d < closest_dist)
			closest_dist = d
			target = M
	if(!target)
		return
	projectile.forceMove(get_turf(R))
	projectile.throw_at(target, TH.throw_range, TH.throw_force, R)


// -- INJECT REAGENT ----------------------------------

/datum/behavior_circuit/response/inject_reagent
	needs_hardware = TRUE
	circuit_name = "Response: Inject Reagent"
	hardware_slot_name = HW_SLOT_INJECTOR
	required_hardware_type = /datum/robot_hardware/injector
	circuit_desc = "Injects reagents into the nearest valid target. Requires Injector hardware."
	tutorial_text = "HARDWARE REQUIRED: Injector hardware datum. Injects reagents into the nearest mob. Configure 'inject_amount' (default 5u) and 'target_friendly' (TRUE = friendlies only, FALSE = any mob). Used by medic robots."
	cpu_cost = 2
	var/inject_amount = 5
	var/target_friendly = TRUE

/datum/behavior_circuit/response/inject_reagent/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/injector/INJ = get_hardware(R, /datum/robot_hardware/injector)
	if(!INJ || !INJ.reagent_tank || !INJ.reagent_tank.reagents || !INJ.reagent_tank.reagents.total_volume)
		return
	var/scan_range = A ? A.sensor_range : 5
	for(var/mob/living/carbon/M in range(scan_range, R))
		if(M.stat == DEAD)
			continue
		if(target_friendly && !_is_faction_friend(R, M))
			continue
		INJ.reagent_tank.reagents.trans_to(M, inject_amount)
		R.visible_message(span_notice("[R] administers treatment to [M]."))
		return


// -- OFFER DRINK -------------------------------------

/datum/behavior_circuit/response/offer_drink
	needs_hardware = TRUE
	circuit_name = "Response: Offer Drink"
	hardware_slot_name = HW_SLOT_INJECTOR
	required_hardware_type = /datum/robot_hardware/injector
	circuit_desc = "Dispenses a drink to the nearest thirsty mob. Requires Injector hardware."
	tutorial_text = "HARDWARE REQUIRED: Injector hardware datum loaded with a drink reagent. Dispenses 10u to the nearest thirsty human. The injector won't refill automatically. Pair with the On Mob Thirsty Nearby trigger."
	cpu_cost = 1

/datum/behavior_circuit/response/offer_drink/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/injector/INJ = get_hardware(R, /datum/robot_hardware/injector)
	if(!INJ || !INJ.reagent_tank || !INJ.reagent_tank.reagents || !INJ.reagent_tank.reagents.total_volume)
		return
	var/obj/item/behavior_assembly/asm = get_assembly()
	var/scan_range = asm ? asm.sensor_range : 5
	for(var/mob/living/carbon/human/H in range(scan_range, R))
		if(H.stat == DEAD || !H.reagents)
			continue
		if(H.thirst <= THIRST_LEVEL_THIRSTY)
			INJ.reagent_tank.reagents.trans_to(H, 10)
			R.visible_message(span_notice("[R] extends a dispenser nozzle toward [H]."))
			return


// -- GRAB NEAREST ITEM -------------------------------

/datum/behavior_circuit/response/grab_nearest_item
	needs_hardware = TRUE
	circuit_name = "Response: Grab Nearest Item"
	hardware_slot_name = HW_SLOT_GRABBER
	required_hardware_type = /datum/robot_hardware/grabber
	circuit_desc = "Grabs the nearest loose item. Requires Grabber hardware."
	tutorial_text = "HARDWARE REQUIRED: Grabber hardware datum. Picks up the nearest loose item within range. Configure 'grab_range' (default 2 tiles). The robot can then throw it (Throw Item At Enemy) or carry it."
	cpu_cost = 2
	var/grab_range = 2

/datum/behavior_circuit/response/grab_nearest_item/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/grabber/GR = get_hardware(R, /datum/robot_hardware/grabber)
	if(!GR)
		return
	for(var/obj/item/I in range(grab_range, R))
		if(istype(I, /obj/item/electronic_assembly) || istype(I, /obj/item/integrated_circuit))
			continue
		if(I.anchored)
			continue
		I.forceMove(R)
		R.visible_message(span_notice("[R] picks up [I]."))
		return


// -- DROP ALL ITEMS ----------------------------------

/datum/behavior_circuit/response/drop_all_items
	needs_hardware = TRUE
	circuit_name = "Response: Drop All Items"
	hardware_slot_name = HW_SLOT_GRABBER
	required_hardware_type = /datum/robot_hardware/grabber
	circuit_desc = "Drops all held items. Requires Grabber hardware."
	tutorial_text = "HARDWARE REQUIRED: Grabber hardware datum. Drops all held items. Good for: deposit robots that collect and drop items at a location, or robots that drop weapons on death. Pair with On Death trigger."
	cpu_cost = 1

/datum/behavior_circuit/response/drop_all_items/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/grabber/GR = get_hardware(R, /datum/robot_hardware/grabber)
	if(!GR)
		return
	for(var/obj/item/I in R)
		if(istype(I, /obj/item/electronic_assembly) || istype(I, /obj/item/integrated_circuit))
			continue
		I.forceMove(get_turf(R))


// -- STUN TARGET -------------------------------------

/datum/behavior_circuit/response/stun_target
	circuit_name = "Response: Stun Target"
	circuit_desc = "Stuns the nearest hostile mob briefly."
	tutorial_text = "Stuns the nearest hostile. Works without Stun Module hardware using chassis defaults (range: assembly sensor_range, duration: stun_duration var). Install Stun Module hardware for configurable range and duration that scale with builder STR. Good for security robots that incapacitate without killing."
	cpu_cost = 2
	var/stun_duration = 20

/datum/behavior_circuit/response/stun_target/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	// Prefer the hardware's configured stun_range; fall back to assembly sensor_range
	// if no stun_module is installed (allows use as a bare chassis pulse).
	var/datum/robot_hardware/stun_module/SM = get_hardware(R, /datum/robot_hardware/stun_module)
	var/scan_range = SM ? SM.stun_range : (A ? A.sensor_range : 3)
	var/duration   = SM ? SM.stun_duration : stun_duration
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(_is_faction_friend(R, M))
			continue
		M.Stun(duration)
		R.visible_message(span_warning("[R] fires a stun pulse at [M]!"))
		return


// -- DEPLOY SMOKE ------------------------------------

/datum/behavior_circuit/response/deploy_smoke
	circuit_name = "Response: Deploy Smoke"
	circuit_desc = "Releases a smoke cloud around the robot."
	tutorial_text = "Releases a smoke cloud at the robot's position. No hardware required. Configure 'smoke_range' (default 2 tiles) and 'smoke_duration' (default 15 ticks). Good for: escape when damaged, area denial, or covering allied movement."
	cpu_cost = 2
	var/smoke_range = 2
	var/smoke_duration = 15

/datum/behavior_circuit/response/deploy_smoke/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/effect_system/smoke_spread/smoke = new()
	smoke.set_up(smoke_range, get_turf(R))
	smoke.start()


// -- FIRE EXTINGUISHER -------------------------------

/datum/behavior_circuit/response/fire_extinguisher
	needs_hardware = TRUE
	circuit_name = "Response: Extinguish Fire"
	hardware_slot_name = HW_SLOT_EXTINGUISHER
	required_hardware_type = /datum/robot_hardware/extinguisher_module
	circuit_desc = "Douses the nearest mob on fire. Requires Extinguisher Module hardware."
	tutorial_text = "HARDWARE REQUIRED: Extinguisher Module. The robot finds the nearest mob on fire within the hardware's spray_range and douses them. Respects charge count (set -1 for unlimited). Pair with Trigger: On Interval for automatic fire response."
	cpu_cost = 2

/datum/behavior_circuit/response/fire_extinguisher/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/extinguisher_module/EM = get_hardware(R, /datum/robot_hardware/extinguisher_module)
	if(!EM)
		return
	var/obj/item/extinguisher/EX = EM.get_extinguisher()
	if(!EX)
		R.visible_message(span_warning("[R]'s extinguisher module is empty!"))
		return
	// Find nearest mob on fire within hardware spray_range
	var/scan_range = EM.spray_range
	var/mob/living/target = null
	var/closest = INFINITY
	for(var/mob/living/M in view(scan_range, R))
		if(M.fire_stacks > 0 || M.on_fire)
			var/d = get_dist(R, M)
			if(d < closest)
				closest = d
				target = M
	if(!target)
		return
	// Step adjacent if needed; trigger will re-fire next tick to close distance
	if(get_dist(R, target) > 1)
		step_towards(R, target)
		return
	EX.attack(target, R)
	EM.consume_charge()
	R.visible_message(span_notice("[R] extinguishes [target]!"))


// -- TOGGLE LIGHT ------------------------------------

/datum/behavior_circuit/response/toggle_light
	needs_hardware = TRUE
	circuit_name = "Response: Toggle Light"
	hardware_slot_name = HW_SLOT_LIGHT
	required_hardware_type = /datum/robot_hardware/light
	circuit_desc = "Toggles or sets the robot's light. Requires Light hardware."
	tutorial_text = "HARDWARE REQUIRED: Light hardware datum. Toggles the robot's light or forces it on/off. Configure 'force_state': -1 = toggle, 0 = force off, 1 = force on. Good for stealth robots or night-cycle triggers."
	cpu_cost = 1
	var/force_state = -1

/datum/behavior_circuit/response/toggle_light/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/light/LT = get_hardware(R, /datum/robot_hardware/light)
	if(!LT)
		return
	var/new_state = (force_state == -1) ? !LT.start_on : (force_state > 0)
	LT.start_on = new_state
	if(new_state)
		R.set_light_range(LT.light_brightness)
		R.set_light_on(TRUE)
	else
		R.set_light_on(FALSE)
		R.set_light_range(0)


// -- PLAY SOUND --------------------------------------

/datum/behavior_circuit/response/play_sound
	circuit_name = "Response: Play Sound"
	circuit_desc = "Plays a sound effect at the robot's position."
	tutorial_text = "Plays a sound at the robot's location. No hardware required. Configure 'sound_file' (e.g. 'sound/machines/beep.ogg') and 'sound_volume' (0-100). Good for personality, alarm sounds, or feedback beeps."
	cpu_cost = 1
	var/sound_file = 'sound/machines/beep.ogg'
	var/sound_volume = 50

/datum/behavior_circuit/response/play_sound/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	playsound(R, sound_file, sound_volume, 1)


// -- PUMP REAGENTS -----------------------------------

/datum/behavior_circuit/response/pump_reagents
	needs_hardware = TRUE
	circuit_name = "Response: Pump Reagents"
	hardware_slot_name = HW_SLOT_REAGENT_PUMP
	required_hardware_type = /datum/robot_hardware/reagent_pump
	circuit_desc = "Activates the reagent pump to push chemicals. Requires Reagent Pump hardware."
	tutorial_text = "HARDWARE REQUIRED: Reagent Pump hardware datum. Activates the pump to push reagents from the attached container. For chemistry and service robots."
	cpu_cost = 1

/datum/behavior_circuit/response/pump_reagents/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/reagent_pump/RP = get_hardware(R, /datum/robot_hardware/reagent_pump)
	if(!RP || !R.reagents || R.reagents.total_volume <= 0)
		return
	var/scan_range = A ? A.sensor_range : 3
	for(var/obj/item/reagent_containers/RC in range(scan_range, R))
		if(RC.reagents)
			R.reagents.trans_to(RC, RP.transfer_rate)
			R.visible_message(span_notice("[R] pumps reagents."))
			return


// -- SEND RADIO SIGNAL -------------------------------

/datum/behavior_circuit/response/send_radio_signal
	needs_hardware = TRUE
	circuit_name = "Response: Send Radio Signal"
	hardware_slot_name = HW_SLOT_SIGNALER
	required_hardware_type = /datum/robot_hardware/signaler
	circuit_desc = "Transmits a radio signal on the configured frequency. Requires Signaler hardware."
	tutorial_text = "HARDWARE REQUIRED: Signaler hardware datum. Transmits a radio signal on the configured frequency. Good for triggering other robots remotely, activating traps, or chaining behaviors across multiple robots. Set the frequency on the Signaler datum at build time."
	cpu_cost = 1

/datum/behavior_circuit/response/send_radio_signal/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/signaler/SIG = get_hardware(R, /datum/robot_hardware/signaler)
	if(!SIG)
		return
	SIG.send_signal(R)
	R.visible_message(span_notice("[R] transmits a signal on [SIG.frequency]."))


// -- READ BATTERY ------------------------------------

/datum/behavior_circuit/response/read_battery
	circuit_name = "Response: Read Battery"
	circuit_desc = "Says the current cell charge percentage aloud."
	tutorial_text = "The robot says its current battery percentage aloud. No hardware required. Pair with On Interval for periodic status reports, or On Low Power for an automatic low-battery warning."
	cpu_cost = 1

/datum/behavior_circuit/response/read_battery/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.cell)
		R.say("Battery status: no cell installed.")
		return
	var/pct = round((R.cell.charge / R.cell.maxcharge) * 100)
	R.say("Battery status: [pct]%.")


// -- PULL TARGET -------------------------------------

/datum/behavior_circuit/response/pull_target
	circuit_name = "Response: Pull Target"
	circuit_desc = "Grabs and pulls the nearest friendly mob."
	tutorial_text = "Grabs and pulls the nearest friendly mob. No hardware required. Good for: rescue robots that drag the injured to safety, escort builds, or physically hauling allies."
	cpu_cost = 2

/datum/behavior_circuit/response/pull_target/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/scan_range = A ? A.sensor_range : 3
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(!_is_faction_friend(R, M))
			continue
		R.pulling = M
		R.visible_message(span_notice("[R] begins pulling [M]."))
		return


// -- DISPLAY SCREEN ----------------------------------

/datum/behavior_circuit/response/display_screen
	needs_hardware = TRUE
	circuit_name = "Response: Display Screen Message"
	hardware_slot_name = HW_SLOT_DISPLAY
	required_hardware_type = /datum/robot_hardware/display_screen
	circuit_desc = "Shows a message on the robot's display screen. Requires Display Screen hardware."
	tutorial_text = "HARDWARE REQUIRED: Display Screen hardware datum. Updates the robot's screen with 'display_text'. Good for status boards, warning displays, or information robots."
	cpu_cost = 1
	var/display_text = "STATUS: NOMINAL"

/datum/behavior_circuit/response/display_screen/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/display_screen/DS = get_hardware(R, /datum/robot_hardware/display_screen)
	if(!DS)
		return
	DS.current_text = display_text
	// Update robot name overlay if it uses a display
	R.visible_message(span_notice("[R]'s screen reads: [display_text]"))


// ====================================================
// HARVESTER CIRCUIT
// ====================================================

/datum/behavior_circuit/response/harvest_plants
	needs_hardware = TRUE
	circuit_name = "Response: Harvest Nearby Plants"
	hardware_slot_name = HW_SLOT_HARVESTER
	required_hardware_type = /datum/robot_hardware/harvester
	circuit_desc = "Harvests mature plants in range. Requires Harvester Module hardware."
	tutorial_text = "HARDWARE REQUIRED: Harvester Module. The robot searches for mature hydroponic trays in range and harvests them. Set auto_replant on the hardware datum to replant after harvesting. Pair with On Interval for a fully automated farm bot."
	cpu_cost = 2

/datum/behavior_circuit/response/harvest_plants/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/harvester/HV = get_hardware(R, /datum/robot_hardware/harvester)
	if(!HV)
		return
	// Cooldown prevents per-tick spam cycling through all trays in range
	if(world.time < HV.last_harvest + HV.harvest_cooldown)
		return
	// Find a tray that is ready to harvest (tray.harvest = TRUE means ripe)
	// Skip trays with no seed planted and trays that are dead
	var/obj/machinery/hydroponics/target_tray = null
	for(var/obj/machinery/hydroponics/tray in range(HV.harvest_range, R))
		if(tray.harvest && tray.myseed)
			target_tray = tray
			break
	if(!target_tray)
		return
	HV.last_harvest = world.time
	// Step adjacent if not next to it
	if(get_dist(R, target_tray) > 1)
		step_towards(R, target_tray)
		return
	// attack_hand() has issilicon(user) guard that blocks robots. Call update_tray() directly
	// which is the same proc attack_hand() calls internally when harvest == TRUE.
	target_tray.update_tray(R)
	R.visible_message(span_notice("[R] harvests [target_tray]."))


// ====================================================
// MATERIAL COLLECTOR CIRCUIT
// ====================================================

/datum/behavior_circuit/response/collect_items
	needs_hardware = TRUE
	circuit_name = "Response: Collect Nearby Items"
	hardware_slot_name = HW_SLOT_MATERIAL_COLLECTOR
	required_hardware_type = /datum/robot_hardware/material_collector
	circuit_desc = "Picks up nearby raw materials. Requires Material Collector hardware."
	tutorial_text = "HARDWARE REQUIRED: Material Collector. The robot searches for raw materials (metal sheets, glass, etc.) in range and picks them up. Configure target_types on the hardware datum to restrict what it collects. Requires Grabber Arm to store items."
	cpu_cost = 2

/datum/behavior_circuit/response/collect_items/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/material_collector/MC = get_hardware(R, /datum/robot_hardware/material_collector)
	var/datum/robot_hardware/grabber/GR = get_hardware(R, /datum/robot_hardware/grabber)
	if(!MC)
		return
	for(var/obj/item/I in range(MC.collect_range, R))
		if(I.anchored)
			continue
		// Use istype subtype check so sheet/metal subtypes are caught
		var/type_match = FALSE
		for(var/t in MC.target_types)
			if(istype(I, t))
				type_match = TRUE
				break
		if(!type_match)
			continue
		if(GR && GR.held_items.len >= GR.max_items)
			continue
		// Step toward item if not adjacent
		if(get_dist(R, I) > 1)
			step_towards(R, I)
			return
		I.forceMove(R)
		if(GR)
			GR.held_items += I
		R.visible_message(span_notice("[R] collects [I]."))
		return


// ====================================================
// GRINDER CIRCUIT
// ====================================================

/datum/behavior_circuit/response/grind_item
	needs_hardware = TRUE
	circuit_name = "Response: Grind Item"
	hardware_slot_name = HW_SLOT_GRINDER
	required_hardware_type = /datum/robot_hardware/grinder_module
	circuit_desc = "Grinds a held item into reagents. Requires Grinder Module hardware."
	tutorial_text = "HARDWARE REQUIRED: Grinder Module. Grinds the first held item (via Grabber Arm) into its chemical components, storing results in the onboard Reagent Tank. Requires both Grabber Arm and Reagent Tank hardware. Good for automated chemistry or scrap processing bots."
	cpu_cost = 3

/datum/behavior_circuit/response/grind_item/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/grinder_module/GM = get_hardware(R, /datum/robot_hardware/grinder_module)
	var/datum/robot_hardware/grabber/GR = get_hardware(R, /datum/robot_hardware/grabber)
	if(!GM || !GR)
		return
	if(!GR.held_items || !GR.held_items.len)
		return
	var/obj/item/target = GR.held_items[1]
	if(!target)
		return
	var/target_name = target.name
	GR.held_items -= target
	if(target.reagents && R.reagents)
		target.reagents.trans_to(R, target.reagents.total_volume)
	qdel(target)
	R.visible_message(span_notice("[R] grinds [target_name] into reagents."))


// ====================================================
// GAS VENT CIRCUIT
// ====================================================

/datum/behavior_circuit/response/pump_reagent
	needs_hardware = TRUE
	circuit_name = "Response: Pump Reagent"
	hardware_slot_name = HW_SLOT_REAGENT_PUMP
	required_hardware_type = /datum/robot_hardware/reagent_pump
	circuit_desc = "Transfers reagents between the robot's tank and an adjacent container."
	tutorial_text = "HARDWARE REQUIRED: Reagent Pump. Pulls reagents into the robot from an adjacent container, or pushes them out, depending on the hardware's pump_direction setting. Good for: supply bots that restock from dispensers, or robots that dispense reagents into containers."
	cpu_cost = 1

/datum/behavior_circuit/response/pump_reagent/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/reagent_pump/PU = get_hardware(R, /datum/robot_hardware/reagent_pump)
	if(!PU || !R.reagents)
		return
	// Scan adjacent tiles for a reagent container
	var/obj/item/reagent_containers/target = null
	for(var/obj/item/reagent_containers/RC in range(1, R))
		if(RC.reagents)
			target = RC
			break
	if(!target)
		return
	var/amount = PU.transfer_rate
	if(PU.pump_direction == 0)
		// Pull: container -> robot
		target.reagents.trans_to(R, min(amount, target.reagents.total_volume))
		R.visible_message(span_notice("[R] draws reagents from [target]."))
	else
		// Push: robot -> container
		R.reagents.trans_to(target, min(amount, R.reagents.total_volume))
		R.visible_message(span_notice("[R] fills [target] with reagents."))


// ====================================================
// BIO SCANNER CIRCUITS
// ====================================================

/datum/behavior_circuit/trigger/on_mutant_detected
	needs_hardware = TRUE
	circuit_name = "Trigger: On Mutant Detected"
	hardware_slot_name = HW_SLOT_BIO_SCANNER
	required_hardware_type = /datum/robot_hardware/bio_scanner
	circuit_desc = "Fires when an unusual biological signature is detected nearby."
	tutorial_text = "HARDWARE REQUIRED: Bio Scanner. Fires when a mob with unusual biology (non-standard species, mutation flags) is detected in scan range. Configure target_species on the hardware datum to only react to a specific species. Good for field research bots or bounty hunter builds."
	cpu_cost = 2
	var/last_detected = 0

/datum/behavior_circuit/trigger/on_mutant_detected/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	last_detected = world.time
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_mutant_detected/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_mutant_detected/process()
	if(world.time < last_detected + 30)
		return
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/datum/robot_hardware/bio_scanner/BS = get_hardware(R, /datum/robot_hardware/bio_scanner)
	if(!BS)
		return
	for(var/mob/living/carbon/human/M in range(BS.scan_radius, R))
		if(M == R || M.stat == DEAD)
			continue
		if(!M.dna || !M.dna.species)
			continue
		// Filter by species type path if configured on hardware
		if(BS.target_species)
			if(!istype(M.dna.species, BS.target_species))
				continue
		// Trigger on non-baseline species (ghouls, mutants, etc.)
		if(!istype(M.dna.species, /datum/species/human))
			last_detected = world.time
			_trigger(R)
			return

/datum/behavior_circuit/response/broadcast_bio_report
	needs_hardware = TRUE
	circuit_name = "Response: Broadcast Bio Report"
	hardware_slot_name = HW_SLOT_BIO_SCANNER
	required_hardware_type = /datum/robot_hardware/bio_scanner
	circuit_desc = "Reports biological scan results to the radio. Requires Bio Scanner hardware."
	tutorial_text = "HARDWARE REQUIRED: Bio Scanner. Broadcasts a brief biological report about the nearest mob in scan range -- species, apparent health state, and faction. Good for field research robots or scouts."
	cpu_cost = 1

/datum/behavior_circuit/response/broadcast_bio_report/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/bio_scanner/BS = get_hardware(R, /datum/robot_hardware/bio_scanner)
	if(!BS)
		return
	for(var/mob/living/M in range(BS.scan_radius, R))
		if(M == R || M.stat == DEAD)
			continue
		var/health_state = M.health > M.maxHealth * 0.75 ? "healthy" : (M.health > 0 ? "injured" : "critical")
		// ";message" prefix sends over robot's radio channel in SS13
		R.say(";BIO REPORT: [M.name] -- [health_state] -- [M.stat == CONSCIOUS ? "CONSCIOUS" : "INCAPACITATED"]")
		return


// ====================================================
// OBJECT LOCATOR CIRCUIT
// ====================================================

/datum/behavior_circuit/trigger/on_item_spotted
	needs_hardware = TRUE
	circuit_name = "Trigger: On Item Spotted"
	hardware_slot_name = HW_SLOT_OBJECT_LOCATOR
	required_hardware_type = /datum/robot_hardware/object_locator
	circuit_desc = "Fires when a specific item type is found nearby. Requires Object Locator hardware."
	tutorial_text = "HARDWARE REQUIRED: Object Locator. Fires when an item matching target_type is found within search_radius. More precise than the Environment Scanner. The robot will pathfind toward it. Configure target_type on the hardware datum."
	cpu_cost = 1
	var/last_spotted = 0

/datum/behavior_circuit/trigger/on_item_spotted/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	last_spotted = world.time
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_item_spotted/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_item_spotted/process()
	if(world.time < last_spotted + 20)
		return
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/datum/robot_hardware/object_locator/OL = get_hardware(R, /datum/robot_hardware/object_locator)
	if(!OL)
		return
	for(var/obj/item/I in range(OL.search_radius, R))
		if(!istype(I, OL.target_type))
			continue
		last_spotted = world.time
		_trigger(R)
		return


// ====================================================
// POWER RELAY CIRCUIT
// ====================================================

/datum/behavior_circuit/response/relay_power
	needs_hardware = TRUE
	circuit_name = "Response: Relay Power"
	hardware_slot_name = HW_SLOT_POWER_RELAY
	required_hardware_type = /datum/robot_hardware/power_relay
	circuit_desc = "Beams charge to nearby robots or machines. Requires Power Relay hardware."
	tutorial_text = "HARDWARE REQUIRED: Power Relay. Transfers charge from this robot's power cell to the nearest robot or powered machine in relay_range. Configure transfer_rate (units per tick) and relay_range on the hardware datum. Drains the robot's own cell."
	cpu_cost = 2

/datum/behavior_circuit/response/relay_power/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/power_relay/PR = get_hardware(R, /datum/robot_hardware/power_relay)
	if(!PR || !R.cell || R.cell.charge < PR.transfer_rate)
		return
	// Try robots first, then powered machines
	for(var/mob/living/silicon/robot/target in range(PR.relay_range, R))
		if(target == R || !target.cell || target.cell.charge >= target.cell.maxcharge)
			continue
		R.cell.charge -= PR.transfer_rate
		target.cell.charge = min(target.cell.charge + PR.transfer_rate, target.cell.maxcharge)
		R.visible_message(span_notice("[R] relays [PR.transfer_rate]u of power to [target]."))
		return
	for(var/obj/machinery/M in range(PR.relay_range, R))
		var/obj/item/stock_parts/cell/MC = locate(/obj/item/stock_parts/cell) in M
		if(!MC || MC.charge >= MC.maxcharge)
			continue
		R.cell.charge -= PR.transfer_rate
		MC.charge = min(MC.charge + PR.transfer_rate, MC.maxcharge)
		R.visible_message(span_notice("[R] relays power to [M]."))
		return


// ====================================================
// NAV COMPUTER CIRCUIT (Waypoint Patrol)
// ====================================================

/datum/behavior_circuit/response/patrol_waypoints
	needs_hardware = TRUE
	circuit_name = "Response: Patrol Waypoints"
	hardware_slot_name = HW_SLOT_NAV_COMPUTER
	required_hardware_type = /datum/robot_hardware/nav_computer
	circuit_desc = "Moves the robot along its stored waypoints. Requires Navigation Computer hardware."
	tutorial_text = "HARDWARE REQUIRED: Navigation Computer. Steps the robot to the next waypoint in its stored list. Configure waypoints as list(list(x,y,z)) on the hardware datum. Set loop_route = TRUE to patrol in a loop. Use with On Interval trigger for automated patrol."
	cpu_cost = 2

/datum/behavior_circuit/response/patrol_waypoints/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/nav_computer/NC = get_hardware(R, /datum/robot_hardware/nav_computer)
	if(!NC || !NC.waypoints.len)
		return
	if(NC.current_waypoint > NC.waypoints.len)
		if(NC.loop_route)
			NC.current_waypoint = 1
		else
			return
	var/list/wp = NC.waypoints[NC.current_waypoint]
	if(!islist(wp) || wp.len < 2)
		NC.current_waypoint++
		return
	var/turf/target = locate(wp[1], wp[2], (wp.len >= 3 ? wp[3] : R.z))
	if(!target)
		NC.current_waypoint++
		return
	if(get_dist(R, target) <= 1)
		NC.current_waypoint++
		return
	step_towards(R, target)


// ====================================================
// VOCABULARY CIRCUIT
// ====================================================

/datum/behavior_circuit/response/say_vocab_phrase
	needs_hardware = TRUE
	circuit_name = "Response: Say Vocab Phrase"
	hardware_slot_name = HW_SLOT_VOCABULARY
	required_hardware_type = /datum/robot_hardware/vocabulary_module
	circuit_desc = "Says a stored vocabulary phrase by index. Requires Vocabulary Module hardware."
	tutorial_text = "HARDWARE REQUIRED: Vocabulary Module. Says the phrase stored at 'phrase_index' in the vocabulary module's phrases list. Index 1 = first phrase. Good for building robots that cycle through different responses, announcements, or flavor speech without hardcoding strings in each circuit."
	cpu_cost = 1
	var/phrase_index = 1

/datum/behavior_circuit/response/say_vocab_phrase/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/vocabulary_module/VM = get_hardware(R, /datum/robot_hardware/vocabulary_module)
	if(!VM || !VM.phrases.len)
		return
	var/idx = clamp(phrase_index, 1, VM.phrases.len)
	R.say(VM.phrases[idx])


// ====================================================
// PIPE INTERFACE CIRCUITS
// ====================================================

/datum/behavior_circuit/trigger/on_reagent_container_nearby
	circuit_name = "Trigger: On Reagent Container Nearby"
	circuit_desc = "Fires when a reagent container is detected on the ground or in a nearby mob's inventory."
	tutorial_text = "Fires when the robot detects a reagent container (chem bottle, canteen, medkit, etc.) within sensor range. Configure check_range (default 4) and check_inventory (default FALSE). When check_inventory is TRUE, also scans nearby mobs' hands and pockets. Good for: medical dispensers that home in on supplies, scavenger bots collecting chems. No hardware required."
	cpu_cost = 1
	var/last_check = 0
	var/check_range = 4
	/// When TRUE, also scans nearby mobs' inventories for reagent containers.
	var/check_inventory = FALSE

/datum/behavior_circuit/trigger/on_reagent_container_nearby/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_reagent_container_nearby/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_reagent_container_nearby/process()
	if(world.time < last_check + 20)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return
	for(var/obj/item/reagent_containers/RC in range(check_range, R))
		if(RC.reagents && RC.reagents.total_volume > 0)
			_trigger(R)
			return
	if(check_inventory)
		for(var/mob/living/M in range(check_range, R))
			if(M == R || M.stat == DEAD)
				continue
			for(var/obj/item/reagent_containers/RC in M.contents)
				if(RC.reagents && RC.reagents.total_volume > 0)
					_trigger(R)
					return

/datum/behavior_circuit/response/collect_reagents
	circuit_name = "Response: Collect Reagents"
	circuit_desc = "Moves to and collects reagents from the nearest container in range."
	tutorial_text = "The robot moves to and collects reagents from the nearest container in range into the robot's internal reagents. Install Internal Reagent Tank hardware for meaningful storage capacity -- without it the robot has only its default reagent buffer. Pair with Trigger: On Reagent Container Nearby or On Interval."
	cpu_cost = 2

/datum/behavior_circuit/response/collect_reagents/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.reagents)
		return
	var/scan_range = A ? A.sensor_range : 4
	var/obj/item/reagent_containers/target = null
	var/closest = INFINITY
	for(var/obj/item/reagent_containers/RC in range(scan_range, R))
		if(!RC.reagents || RC.reagents.total_volume <= 0)
			continue
		var/d = get_dist(R, RC)
		if(d < closest)
			closest = d
			target = RC
	if(!target)
		return
	if(get_dist(R, target) > 1)
		step_towards(R, target)
		return
	target.reagents.trans_to(R, target.reagents.total_volume)
	R.visible_message(span_notice("[R] collects reagents from [target]."))

// -- SPRAY REAGENT ------------------------------------

/datum/behavior_circuit/response/spray_reagent
	needs_hardware = TRUE
	circuit_name = "Response: Spray Reagent"
	hardware_slot_name = HW_SLOT_CHEM_SPRAYER
	required_hardware_type = /datum/robot_hardware/chem_sprayer
	circuit_desc = "Sprays reagents from the robot's tank onto a nearby mob."
	tutorial_text = "HARDWARE REQUIRED: Chem Sprayer. The robot sprays a configured amount of reagent from its tank onto the nearest mob in range. Combine with On Interval for passive dispensing, or On Take Damage for emergency self-treatment. Requires Reagent Tank hardware for supply."
	cpu_cost = 2

/datum/behavior_circuit/response/spray_reagent/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/chem_sprayer/SP = get_hardware(R, /datum/robot_hardware/chem_sprayer)
	if(!SP || !R.reagents || R.reagents.total_volume <= 0)
		return
	var/mob/living/target = null
	var/closest = INFINITY
	for(var/mob/living/M in range(SP.spray_range, R))
		if(M == R || M.stat == DEAD)
			continue
		var/d = get_dist(R, M)
		if(d < closest)
			closest = d
			target = M
	if(!target)
		return
	if(!target.reagents)
		return
	R.reagents.trans_to(target, min(SP.spray_amount, R.reagents.total_volume))
	R.visible_message(span_notice("[R] sprays [target] with reagents."))



// -- MAINTAIN COMBAT RANGE ---------------------------

/datum/behavior_circuit/response/maintain_combat_range
	needs_hardware = TRUE
	circuit_name = "Response: Maintain Combat Range"
	hardware_slot_name = HW_SLOT_WEAPON
	required_hardware_type = /datum/robot_hardware/weapon
	circuit_desc = "Moves toward or away from the nearest enemy to hold the configured combat range."
	tutorial_text = "HARDWARE REQUIRED: Weapon hardware. Reads combat_mode, retreat_distance, and minimum_distance from the weapon hardware and repositions the robot. RANGED: backs off when enemy closes. MIXED: prefers range but closes if rushed. MELEE: always charges. Pair with Fire Weapon and On Enemy Spotted for a full ranged build."
	cpu_cost = 2

/datum/behavior_circuit/response/maintain_combat_range/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.anchored || R.stat == DEAD)
		return
	var/datum/robot_hardware/weapon/WH = get_hardware(R, /datum/robot_hardware/weapon)
	if(!WH)
		return
	var/scan_range = (A ? A.sensor_range : 7) + WH.fire_range
	var/mob/living/target = null
	var/closest_dist = INFINITY
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(_is_faction_friend(R, M))
			continue
		var/d = get_dist(R, M)
		if(d < closest_dist)
			closest_dist = d
			target = M
	if(!target)
		return
	var/cmode = WH.combat_mode
	var/ret_d  = WH.retreat_distance
	var/min_d  = WH.minimum_distance
	var/tgt_d  = get_dist(R, target)
	switch(cmode)
		if(ROBOT_COMBAT_MELEE)
			step_to(R, target, 1)
		if(ROBOT_COMBAT_RANGED)
			if(tgt_d < ret_d)
				step_away(R, target)
			else if(tgt_d > ret_d + 2)
				step_to(R, target, ret_d)
		if(ROBOT_COMBAT_MIXED)
			if(tgt_d <= min_d)
				step_to(R, target, 1)
			else if(tgt_d < ret_d)
				step_away(R, target)
			else if(tgt_d > ret_d + 2)
				step_to(R, target, ret_d)

// ====================================================
// PRESET ASSEMBLY SUBTYPES
// These are the named assemblies printed by behavior designs.
// Each pre-wires its own circuits with default config.
// ====================================================

/obj/item/behavior_assembly/sentry
	assembly_label = "Sentry Protocol"

/obj/item/behavior_assembly/sentry/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T = new()
	var/datum/behavior_circuit/response/enter_combat_mode/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/guardian
	assembly_label = "Guardian Protocol"

/obj/item/behavior_assembly/guardian/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_take_damage/T = new()
	var/datum/behavior_circuit/response/broadcast_distress/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/medic
	assembly_label = "Medic Protocol"

/obj/item/behavior_assembly/medic/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_take_damage/T = new()
	var/datum/behavior_circuit/response/self_repair_pulse/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/watchdog
	assembly_label = "Watchdog Protocol"

/obj/item/behavior_assembly/watchdog/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_low_power/T = new()
	var/datum/behavior_circuit/response/broadcast_alert/RE = new()
	RE.alert_message = "WARNING: Power cell critical. Requesting recharge."
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/deadman
	assembly_label = "Dead Man Protocol"

/obj/item/behavior_assembly/deadman/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_death/T = new()
	var/datum/behavior_circuit/response/broadcast_distress/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/fortress
	assembly_label = "Fortress Protocol"

/obj/item/behavior_assembly/fortress/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_take_damage/T = new()
	var/datum/behavior_circuit/response/lockdown_self/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/drink_bot
	assembly_label = "Hospitality Protocol"

/obj/item/behavior_assembly/drink_bot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_mob_thirsty/T = new()
	var/datum/behavior_circuit/response/offer_drink/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/medbot
	assembly_label = "Field Medic Protocol"

/obj/item/behavior_assembly/medbot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_mob_injured/T = new()
	var/datum/behavior_circuit/response/inject_reagent/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/night_watch
	assembly_label = "Night Watch Protocol"

/obj/item/behavior_assembly/night_watch/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_night_cycle/T = new()
	var/datum/behavior_circuit/response/broadcast_alert/RE = new()
	RE.alert_message = "Night cycle active. Patrol mode engaged."
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/escort
	assembly_label = "Escort Protocol"

/obj/item/behavior_assembly/escort/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_interval/T = new()
	T.interval_ticks = 20
	var/datum/behavior_circuit/response/follow_target/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/last_resort
	assembly_label = "Last Resort Protocol"

/obj/item/behavior_assembly/last_resort/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_death/T = new()
	var/datum/behavior_circuit/response/detonate_self/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/turret_bot
	assembly_label = "Turret Protocol"

/obj/item/behavior_assembly/turret_bot/cert_compatible(datum/cpu_cert/C)
	return C && (C.capability_flags & CERT_CAN_SHOOT)

/obj/item/behavior_assembly/turret_bot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T = new()
	var/datum/behavior_circuit/response/fire_weapon/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/combat_medic
	assembly_label = "Combat Medic Protocol"

/obj/item/behavior_assembly/combat_medic/cert_compatible(datum/cpu_cert/C)
	return C && (C.capability_flags & CERT_CAN_REPAIR)

/obj/item/behavior_assembly/combat_medic/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_mob_injured/T = new()
	var/datum/behavior_circuit/response/inject_reagent/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/sprint_chaser
	assembly_label = "Sprint Chaser Protocol"

/obj/item/behavior_assembly/sprint_chaser/cert_compatible(datum/cpu_cert/C)
	return C && (C.capability_flags & CERT_CAN_SPRINT)

/obj/item/behavior_assembly/sprint_chaser/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T = new()
	var/datum/behavior_circuit/response/pathfind_to_enemy/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/infiltrator
	assembly_label = "Infiltrator Protocol"

/obj/item/behavior_assembly/infiltrator/cert_compatible(datum/cpu_cert/C)
	return C && (C.capability_flags & CERT_CAN_HACK)

/obj/item/behavior_assembly/infiltrator/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_access_granted/T = new()
	var/datum/behavior_circuit/response/say_text/RE = new()
	RE.say_string = "Access confirmed. Proceeding."
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/field_surgeon
	assembly_label = "Field Surgeon Protocol"

/obj/item/behavior_assembly/field_surgeon/cert_compatible(datum/cpu_cert/C)
	return C && (C.capability_flags & CERT_CAN_REPAIR)

/obj/item/behavior_assembly/field_surgeon/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_health_scan_critical/T = new()
	var/datum/behavior_circuit/response/inject_reagent/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/broadcast_relay
	assembly_label = "Broadcast Relay Protocol"

/obj/item/behavior_assembly/broadcast_relay/cert_compatible(datum/cpu_cert/C)
	return C && (C.capability_flags & CERT_CAN_BROADCAST)

/obj/item/behavior_assembly/broadcast_relay/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_interval/T = new()
	T.interval_ticks = 600
	var/datum/behavior_circuit/response/broadcast_alert/RE = new()
	RE.alert_message = "RELAY ACTIVE. Broadcasting on all channels."
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/scavenger_bot
	assembly_label = "Scavenger Protocol"

/obj/item/behavior_assembly/scavenger_bot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_interval/T = new()
	T.interval_ticks = 80
	var/datum/behavior_circuit/response/grab_nearest_item/RE = new()
	var/datum/behavior_circuit/response/emote_action/EA = new()
	EA.emote_text = "begins cleaning the floor with its utility arm"
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/hunter
	assembly_label = "Hunter Protocol"
	max_circuits = 5

/obj/item/behavior_assembly/hunter/Initialize(mapload)
	. = ..()
	// On Enemy Spotted -> Remember + Fire + maintain range (kites while shooting)
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T1 = new()
	var/datum/behavior_circuit/response/remember_enemy/RE1 = new()
	var/datum/behavior_circuit/response/fire_weapon/RE2 = new()
	var/datum/behavior_circuit/response/maintain_combat_range/RE3 = new()
	T1.responses_list = list(RE1, RE2, RE3)
	circuits += T1
	circuits += RE1
	circuits += RE2
	circuits += RE3
	// On Remembered Enemy -> Pathfind (persistent chase after losing sight)
	var/datum/behavior_circuit/trigger/on_remembered_enemy/T2 = new()
	var/datum/behavior_circuit/response/pathfind_to_enemy/RE4 = new()
	T2.response = RE4
	circuits += T2
	circuits += RE4

/obj/item/behavior_assembly/clock_patrol
	assembly_label = "Clock Patrol Protocol"

/obj/item/behavior_assembly/clock_patrol/Initialize(mapload)
	. = ..()
	// On Clock Tick -> Patrol Waypoints (shared clock, stays in sync with other assemblies)
	var/datum/behavior_circuit/trigger/on_clock_tick/T = new()
	var/datum/behavior_circuit/response/patrol_waypoints/RE = new()
	T.response = RE
	circuits += T
	circuits += RE


// ====================================================
// LAYER 1 — PERSONALITY & SOCIAL CIRCUITS
// ====================================================


// -- ON IDLE TOO LONG --------------------------------
// Fires when the robot has not moved or acted for a
// configurable number of ticks.  Good for ambient
// chatter, fidget emotes, or "wake up" behaviors that
// fire only when the robot is standing still.

/datum/behavior_circuit/trigger/on_idle
	circuit_name = "Trigger: On Idle"
	circuit_desc = "Fires when the robot has not moved or acted for a while."
	tutorial_text = "Fires once after the robot stays in the same position without acting for 'idle_ticks' ticks (default 200 = 20s). Resets whenever the robot moves or a response executes. Great for ambient personality: a robot that hums to itself when left alone, or one that announces it's ready for orders after standing still."
	cpu_cost = 1
	var/idle_ticks = 200
	var/last_move_time = 0
	var/last_turf = null

/datum/behavior_circuit/trigger/on_idle/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	last_turf = get_turf(R)
	last_move_time = world.time
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_idle/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_idle/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/turf/current = get_turf(R)
	if(current != last_turf)
		last_turf = current
		last_move_time = world.time
		return
	if(world.time >= last_move_time + idle_ticks)
		last_move_time = world.time  // reset so it fires once per idle window, not every tick
		_trigger(R)


// -- ON SPOKEN TO DIRECTLY ---------------------------
// Fires when someone says the robot's own name in
// speech picked up by the Microphone hardware.

/datum/behavior_circuit/trigger/on_spoken_to
	needs_hardware = TRUE
	circuit_name = "Trigger: On Spoken To Directly"
	hardware_slot_name = HW_SLOT_MICROPHONE
	required_hardware_type = /datum/robot_hardware/microphone
	circuit_desc = "Fires when someone says the robot's name nearby."
	tutorial_text = "HARDWARE REQUIRED: Microphone. Fires when picked-up speech contains the robot's own name (case-insensitive). Great for companion robots that respond when addressed, or robots with names that trigger a special greeting. Pair with Say Text for a personal touch."
	cpu_cost = 2
	var/last_response_time = 0
	var/response_cooldown = 50  // 5s minimum between responses

/datum/behavior_circuit/trigger/on_spoken_to/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_spoken_to/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_spoken_to/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	if(world.time < last_response_time + response_cooldown)
		return
	var/datum/robot_hardware/microphone/MIC = get_hardware(R, /datum/robot_hardware/microphone)
	if(!MIC || !MIC.last_heard_message)
		return
	if(MIC.last_heard_time <= last_response_time)
		return  // no new speech since last response
	// Check if the robot's name appears in the heard message
	if(findtext(MIC.last_heard_message, lowertext(R.name)))
		last_response_time = world.time
		_trigger(R)


// -- WAVE AT MOB -------------------------------------
// Performs a friendly wave emote toward the nearest
// living mob.  No hardware required.

/datum/behavior_circuit/response/wave_at_mob
	circuit_name = "Response: Wave At Mob"
	circuit_desc = "Performs a friendly wave emote toward the nearest living mob."
	tutorial_text = "The robot waves at the nearest conscious mob. No hardware required. Good for greeter bots, companion robots, or adding personality to a service build. Pair with On Mob Approaches or On Spoken To."
	cpu_cost = 1

/datum/behavior_circuit/response/wave_at_mob/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/scan_range = A ? A.sensor_range : 5
	var/mob/living/target = null
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat != CONSCIOUS)
			continue
		target = M
		break
	if(target)
		R.visible_message(span_notice("[R] turns toward [target] and waves."))
		R.setDir(get_dir(R, target))
	else
		R.visible_message(span_notice("[R] waves at nobody in particular."))


// -- REPORT POSITION ---------------------------------
// Says the robot's current area name over radio.
// No hardware required.

/datum/behavior_circuit/response/report_position
	circuit_name = "Response: Report Position"
	circuit_desc = "Broadcasts current location on the radio channel."
	tutorial_text = "The robot says its current area name aloud on the radio. No hardware required. Configure 'position_prefix' to customize the message preamble (default: 'Position report'). Good for patrol robots that check in, delivery bots announcing arrival, or sentinels confirming their post."
	cpu_cost = 1
	var/position_prefix = "Position report"

/datum/behavior_circuit/response/report_position/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/area/here = get_area(R)
	var/loc_name = here ? here.name : "unknown area"
	R.say(";[position_prefix]: [R.name] at [loc_name].")


// ====================================================
// PRESET: GREETER PROTOCOL
// On Mob Approaches -> Wave At Mob + Say Text
// The quintessential service-robot opener.
// ====================================================

/obj/item/behavior_assembly/greeter
	assembly_label = "Greeter Protocol"

/obj/item/behavior_assembly/greeter/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_mob_approaches/T = new()
	T.approach_range = 4
	T.check_faction = FALSE  // greet everyone
	var/datum/behavior_circuit/response/wave_at_mob/RE1 = new()
	var/datum/behavior_circuit/response/say_text/RE2 = new()
	RE2.say_string = "Greetings, traveler. How may I assist you today?"
	T.responses_list = list(RE1, RE2)
	circuits += T
	circuits += RE1
	circuits += RE2


// ====================================================
// LAYER 2 — TACTICAL RESPONSE CIRCUITS
// ====================================================


// -- ON HEALTH CRITICAL ------------------------------
// Fires when THIS robot's own HP drops below a
// percentage threshold.  Different from On Take Damage
// (which fires on any significant hit) — this is a
// sustained low-health state check.

/datum/behavior_circuit/trigger/on_health_critical
	circuit_name = "Trigger: On Health Critical"
	circuit_desc = "Fires once when the robot's own HP drops below a percentage threshold."
	tutorial_text = "Fires once when the robot's health drops below 'health_pct' percent (default 25%). Resets when health recovers above the threshold. Different from On Take Damage — this is a sustained state, not a per-hit event. Good for: triggering a panic retreat, broadcasting a last-stand message, or activating a self-repair burst."
	cpu_cost = 1
	var/health_pct = 25
	var/already_triggered = FALSE

/datum/behavior_circuit/trigger/on_health_critical/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_health_critical/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_health_critical/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/pct = (R.health / max(R.maxHealth, 1)) * 100
	if(pct < health_pct && !already_triggered)
		already_triggered = TRUE
		_trigger(R)
	else if(pct >= health_pct + 10)  // 10% hysteresis — avoids rapid fire at the boundary
		already_triggered = FALSE


// -- RETREAT TO SPAWN --------------------------------
// Steps the robot back toward the turf it was standing
// on when the assembly was first installed.  No hardware
// required — spawn point is captured at registration.

/datum/behavior_circuit/response/retreat_to_spawn
	circuit_name = "Response: Retreat To Spawn"
	circuit_desc = "Steps the robot back toward its spawn point."
	tutorial_text = "Steps toward the turf where the robot first activated its assembly. No hardware required. The spawn point is captured automatically when the assembly is installed — no configuration needed. Pair with On Health Critical for a robot that flees when badly damaged, or with On Low Power to return to a charging station."
	cpu_cost = 2
	var/turf/spawn_turf = null

/datum/behavior_circuit/response/retreat_to_spawn/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	spawn_turf = get_turf(R)

/datum/behavior_circuit/response/retreat_to_spawn/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.anchored || R.stat == DEAD || !spawn_turf)
		return
	if(get_dist(R, spawn_turf) <= 1)
		return
	step_towards(R, spawn_turf)


// -- CALL FOR REINFORCEMENTS -------------------------
// Broadcasts a distress call that includes a count of
// visible enemies.  More dramatic than Broadcast Alert,
// more tactical than Broadcast Distress.

/datum/behavior_circuit/response/call_reinforcements
	circuit_name = "Response: Call For Reinforcements"
	circuit_desc = "Broadcasts an enemy count and requests backup on the radio."
	tutorial_text = "Scans for hostiles in sensor range and broadcasts a reinforcement request with the enemy count and current location. No hardware required. Configure 'callsign' to personalise the robot's radio identifier (default: the robot's name). Good for: lone sentinels that call backup when overwhelmed, patrol robots that report contact."
	cpu_cost = 1
	var/callsign = ""  // empty = use robot name

/datum/behavior_circuit/response/call_reinforcements/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/scan_range = A ? A.sensor_range : 7
	var/enemy_count = 0
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(!_is_faction_friend(R, M))
			enemy_count++
	var/area/here = get_area(R)
	var/loc_name = here ? here.name : "unknown location"
	var/id = (callsign && callsign != "") ? callsign : R.name
	var/msg = "[id]: CONTACT — [enemy_count] hostile\s at [loc_name]. Requesting immediate reinforcement!"
	R.say(";[msg]")


// -- ACTIVATE SPRINT ---------------------------------
// Triggers the robot's sprint mode for a short burst.
// Requires the Locomotion hardware datum with can_sprint
// enabled.  Degrades gracefully — if no sprint hardware,
// does nothing silently.

/datum/behavior_circuit/response/activate_sprint
	needs_hardware = TRUE
	circuit_name = "Response: Activate Sprint Burst"
	hardware_slot_name = HW_SLOT_LOCOMOTION
	required_hardware_type = /datum/robot_hardware/locomotion
	circuit_desc = "Activates the robot's sprint mode for a burst of speed. Requires Locomotion hardware with sprint enabled."
	tutorial_text = "HARDWARE REQUIRED: Locomotion hardware datum with 'can_sprint' set to TRUE. Calls the robot's sprint toggle, giving a burst of speed that drains the cell. Good for: Assaultrons that sprint when an enemy is spotted, couriers that rush to a target, or panic-mode builds that combine fleeing with a speed burst."
	cpu_cost = 1

/datum/behavior_circuit/response/activate_sprint/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/locomotion/LOC = get_hardware(R, /datum/robot_hardware/locomotion)
	if(!LOC || !LOC.can_sprint)
		return
	if(!R.cansprint || !R.cell || R.cell.charge < 25)
		return
	R.default_toggle_sprint()


// -- HOLD POSITION -----------------------------------
// Anchors the robot in place without the alarm or
// intent change of Emergency Lockdown.  A "stand your
// ground" order with no drama.

/datum/behavior_circuit/response/hold_position
	circuit_name = "Response: Hold Position"
	circuit_desc = "Anchors the robot in place silently."
	tutorial_text = "Anchors the robot in place without sounding an alarm or changing combat intent. The robot will not move until a Release Position response fires. Good for: guard posts that activate on a signal, sentry bots ordered to hold ground, or timed builds where the robot freezes after reaching a waypoint. Pair with Response: Release Position."
	cpu_cost = 1

/datum/behavior_circuit/response/hold_position/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.anchored)
		return
	R.anchored = TRUE
	R.visible_message(span_notice("[R] locks its servos and holds position."))


// -- RELEASE POSITION --------------------------------
// Unanchors the robot.  Companion to Hold Position.

/datum/behavior_circuit/response/release_position
	circuit_name = "Response: Release Position"
	circuit_desc = "Releases an anchored robot to move freely again."
	tutorial_text = "Unanchors the robot if it was held in place by a Hold Position response. No hardware required. Pair with a timed trigger (On Interval, On Clock Tick) to create robots that hold post for a set duration then resume patrol."
	cpu_cost = 1

/datum/behavior_circuit/response/release_position/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.anchored)
		return
	R.anchored = FALSE
	R.visible_message(span_notice("[R] releases its servo locks and resumes movement."))


// ====================================================
// PRESET: PANIC PROTOCOL
// On Health Critical -> Flee From Threat +
//                       Call For Reinforcements +
//                       Activate Sprint Burst
// A robot that fights dirty when cornered.
// ====================================================

/obj/item/behavior_assembly/panic
	assembly_label = "Panic Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/panic/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_health_critical/T = new()
	T.health_pct = 25
	var/datum/behavior_circuit/response/flee_from_threat/RE1 = new()
	var/datum/behavior_circuit/response/call_reinforcements/RE2 = new()
	var/datum/behavior_circuit/response/broadcast_distress/RE3 = new()
	T.responses_list = list(RE1, RE2, RE3)
	circuits += T
	circuits += RE1
	circuits += RE2
	circuits += RE3


// ====================================================
// PRESET: SENTRY HOLD PROTOCOL
// On Enemy Spotted -> Hold Position + Enter Combat Mode
// On Interval (slow) -> Release Position (patrol resumes
//   only when no enemies present — combine with logic core)
// A guard that locks down on contact.
// ====================================================

/obj/item/behavior_assembly/sentry_hold
	assembly_label = "Sentry Hold Protocol"
	max_circuits = 6

/obj/item/behavior_assembly/sentry_hold/Initialize(mapload)
	. = ..()
	// Enemy spotted -> lock down, enter combat, fire and hold range
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T1 = new()
	var/datum/behavior_circuit/response/hold_position/RE1 = new()
	var/datum/behavior_circuit/response/enter_combat_mode/RE2 = new()
	var/datum/behavior_circuit/response/fire_weapon/RE3 = new()
	var/datum/behavior_circuit/response/maintain_combat_range/RE4 = new()
	T1.responses_list = list(RE1, RE2, RE3, RE4)
	circuits += T1
	circuits += RE1
	circuits += RE2
	circuits += RE3
	circuits += RE4
	// Slow interval -> release (only fires when no enemies trip the first trigger)
	var/datum/behavior_circuit/trigger/on_interval/T2 = new()
	T2.interval_ticks = 300  // 30s
	var/datum/behavior_circuit/response/release_position/RE5 = new()
	T2.response = RE5
	circuits += T2
	circuits += RE5


// ====================================================
// LAYER 3 — ENVIRONMENTAL CIRCUITS
// ====================================================


// -- ON FIRE NEARBY ----------------------------------
// Fires when a mob is burning or a fire hotspot exists
// on a nearby turf.  No hardware required.

/datum/behavior_circuit/trigger/on_fire_nearby
	circuit_name = "Trigger: On Fire Nearby"
	circuit_desc = "Fires when a burning mob or fire hazard is detected in range."
	tutorial_text = "Fires when any mob in range has fire stacks (is on fire), or when a fire hotspot object is found on a nearby turf. No hardware required. Configure 'fire_scan_range' (default 4 tiles). Good for: fire-response robots that scramble the extinguisher, alarm bots, or escape triggers. Pair with Response: Extinguish Fire or Response: Sound Alarm."
	cpu_cost = 1
	var/fire_scan_range = 4
	var/last_check = 0
	var/check_cooldown = 30
	var/already_triggered = FALSE

/datum/behavior_circuit/trigger/on_fire_nearby/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	already_triggered = FALSE
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_fire_nearby/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_fire_nearby/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	// Check for mobs on fire
	for(var/mob/living/M in range(fire_scan_range, R))
		if(M.fire_stacks > 0 || M.on_fire)
			if(!already_triggered)
				already_triggered = TRUE
				_trigger(R)
			return
	// Check for fire hotspot objects on nearby turfs
	for(var/turf/T in range(fire_scan_range, R))
		for(var/obj/effect/hotspot/HS in T.contents)
			if(!already_triggered)
				already_triggered = TRUE
				_trigger(R)
			return
	// No fire found — reset so it can trigger again next time fire appears
	already_triggered = FALSE


// -- ON BODY DETECTED --------------------------------
// Fires when the environment scanner finds a dead mob
// on a nearby turf.  Requires Environment Scanner.

/datum/behavior_circuit/trigger/on_body_detected
	needs_hardware = TRUE
	circuit_name = "Trigger: On Body Detected"
	hardware_slot_name = HW_SLOT_ENV_SCANNER
	required_hardware_type = /datum/robot_hardware/environment_scanner
	circuit_desc = "Fires when a dead mob is found nearby. Requires Environment Scanner."
	tutorial_text = "HARDWARE REQUIRED: Environment Scanner with 'detect_bodies' enabled. Fires when a dead mob is found within scan range. Configure 'body_check_range' (default uses hardware scan_radius). Good for: mortuary bots that retrieve bodies, security robots that mark casualty locations, or distress triggers for witnessing a death. Pair with Broadcast Alert or Follow Linked Target."
	cpu_cost = 1
	var/last_check = 0
	var/check_cooldown = 50
	var/already_triggered = FALSE

/datum/behavior_circuit/trigger/on_body_detected/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	already_triggered = FALSE
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_body_detected/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_body_detected/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/datum/robot_hardware/environment_scanner/ES = get_hardware(R, /datum/robot_hardware/environment_scanner)
	if(!ES || !ES.detect_bodies)
		return
	var/scan_range = ES.scan_radius
	for(var/mob/living/M in range(scan_range, R))
		if(M == R)
			continue
		if(M.stat == DEAD)
			if(!already_triggered)
				already_triggered = TRUE
				_trigger(R)
			return
	already_triggered = FALSE


// -- SOUND ALARM -------------------------------------
// Plays an alarm sound and broadcasts a configurable
// alert on the radio.  A louder, more dramatic version
// of Broadcast Alert.  No hardware required.

/datum/behavior_circuit/response/sound_alarm
	circuit_name = "Response: Sound Alarm"
	circuit_desc = "Plays an alarm sound and broadcasts an alert message on radio."
	tutorial_text = "Plays an alarm klaxon and broadcasts a message on the robot's radio channel. No hardware required. Configure 'alarm_message' for the radio text and 'alarm_volume' (0-100, default 75). Good for: fire alerts, intruder detection, hazard warnings. More dramatic than Broadcast Alert because it plays audible sound."
	cpu_cost = 1
	var/alarm_message = "WARNING: Hazard detected. All units respond."
	var/alarm_volume = 75

/datum/behavior_circuit/response/sound_alarm/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	playsound(R, 'sound/machines/alarm.ogg', alarm_volume, TRUE)
	R.say(";[alarm_message]")
	R.visible_message(span_danger("[R]: [alarm_message]"))


// -- SEAL NEARBY DOOR --------------------------------
// Finds the nearest unlocked airlock and bolts it.
// No hardware required — the robot physically locks
// the door using its chassis manipulators.

/datum/behavior_circuit/response/seal_nearby_door
	circuit_name = "Response: Seal Nearby Door"
	circuit_desc = "Finds the nearest unlocked airlock and bolts it shut."
	tutorial_text = "The robot finds the nearest open airlock within 'seal_range' tiles and bolts it shut. No hardware required. Configure 'seal_range' (default 3 tiles) and 'announce_seal' (TRUE = say a message when bolting). Good for: security robots that lock down on intrusion, fire containment builds, or quarantine protocols. Pair with On Enemy Spotted or On Fire Nearby."
	cpu_cost = 1
	var/seal_range = 3
	var/announce_seal = TRUE

/datum/behavior_circuit/response/seal_nearby_door/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/obj/machinery/door/airlock/target = null
	var/closest = INFINITY
	for(var/obj/machinery/door/airlock/D in range(seal_range, R))
		if(D.locked)
			continue  // already bolted
		var/d = get_dist(R, D)
		if(d < closest)
			closest = d
			target = D
	if(!target)
		return
	target.lock()
	if(announce_seal)
		R.visible_message(span_warning("[R] bolts [target] shut."))


// -- HAZMAT WARNING ----------------------------------
// Broadcasts a radiation hazard alert with location.
// Companion response to the existing On Radiation
// Detected trigger.  No hardware required.

/datum/behavior_circuit/response/hazmat_warning
	circuit_name = "Response: Broadcast Hazmat Warning"
	circuit_desc = "Broadcasts a radiation hazard warning with current location on radio."
	tutorial_text = "Broadcasts a hazmat/radiation warning that includes the robot's current area. No hardware required. Configure 'hazmat_prefix' (default 'HAZMAT ALERT'). Designed to pair with Trigger: On Radiation Detected. Good for: dedicated hazmat scouts, field researchers, or any robot equipped with an Environment Scanner."
	cpu_cost = 1
	var/hazmat_prefix = "HAZMAT ALERT"

/datum/behavior_circuit/response/hazmat_warning/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/area/here = get_area(R)
	var/loc_name = here ? here.name : "unknown area"
	playsound(R, 'sound/machines/alarm.ogg', 60, TRUE)
	R.say(";[hazmat_prefix]: Radiation hazard at [loc_name]. Avoid area. Seek cover.")


// ====================================================
// PRESET: FIRE WATCH PROTOCOL
// On Fire Nearby -> Sound Alarm + Extinguish Fire
// A robot that detects and suppresses fire.
// Requires Extinguisher Module hardware.
// ====================================================

/obj/item/behavior_assembly/fire_watch
	assembly_label = "Fire Watch Protocol"
	max_circuits = 3

/obj/item/behavior_assembly/fire_watch/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_fire_nearby/T = new()
	T.fire_scan_range = 5
	var/datum/behavior_circuit/response/sound_alarm/RE1 = new()
	RE1.alarm_message = "FIRE DETECTED. Suppression systems engaged."
	var/datum/behavior_circuit/response/fire_extinguisher/RE2 = new()
	T.responses_list = list(RE1, RE2)
	circuits += T
	circuits += RE1
	circuits += RE2


// ====================================================
// PRESET: LOCKDOWN PROTOCOL
// On Enemy Spotted -> Seal Nearby Door +
//                     Sound Alarm +
//                     Enter Combat Mode
// A security robot that locks the building on contact.
// ====================================================

/obj/item/behavior_assembly/lockdown
	assembly_label = "Lockdown Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/lockdown/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T = new()
	var/datum/behavior_circuit/response/seal_nearby_door/RE1 = new()
	var/datum/behavior_circuit/response/sound_alarm/RE2 = new()
	RE2.alarm_message = "INTRUDER ALERT. Initiating lockdown."
	var/datum/behavior_circuit/response/enter_combat_mode/RE3 = new()
	T.responses_list = list(RE1, RE2, RE3)
	circuits += T
	circuits += RE1
	circuits += RE2
	circuits += RE3


// ====================================================
// LAYER 4 — MEMORY & STATE MACHINE CIRCUITS
// ====================================================
// These circuits use the Memory Core hardware datum
// to store and react to named flags.  This enables
// multi-phase behaviors: one assembly sets a flag,
// another triggers on it.  The foundation for true
// robot state machines.
// ====================================================


// -- ON MEMORY FLAG SET ------------------------------
// Fires whenever a specific named key exists and is
// truthy in the Memory Core.  Polls on a slow interval
// so it acts as a persistent "while flag is set" gate
// rather than a one-shot.

/datum/behavior_circuit/trigger/on_memory_flag
	needs_hardware = TRUE
	circuit_name = "Trigger: On Memory Flag Set"
	hardware_slot_name = HW_SLOT_MEMORY
	required_hardware_type = /datum/robot_hardware/memory_core
	circuit_desc = "Fires periodically while a named memory flag is set in the Memory Core."
	tutorial_text = "HARDWARE REQUIRED: Memory Core. Fires repeatedly (at 'poll_interval' ticks, default 30) while the named 'flag_key' exists and is truthy in memory. This is a sustained trigger — it keeps firing as long as the flag is set. Pair with Response: Set Memory Flag (from another assembly) to create multi-phase robots. Configure 'flag_key' to match the key written by Set Memory Flag."
	cpu_cost = 2
	var/flag_key = "alert"
	var/poll_interval = 30
	var/last_check = 0

/datum/behavior_circuit/trigger/on_memory_flag/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	last_check = world.time
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_memory_flag/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_memory_flag/process()
	if(world.time < last_check + poll_interval)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/datum/robot_hardware/memory_core/MEM = get_hardware(R, /datum/robot_hardware/memory_core)
	if(!MEM)
		return
	var/val = MEM.read(flag_key)
	if(val)
		_trigger(R)


// -- ON MEMORY FLAG CLEAR ----------------------------
// Fires ONCE when a named key transitions from set to
// absent.  Useful for "when the alert ends" hooks.

/datum/behavior_circuit/trigger/on_memory_flag_cleared
	needs_hardware = TRUE
	circuit_name = "Trigger: On Memory Flag Cleared"
	hardware_slot_name = HW_SLOT_MEMORY
	required_hardware_type = /datum/robot_hardware/memory_core
	circuit_desc = "Fires once when a named memory flag transitions from set to cleared."
	tutorial_text = "HARDWARE REQUIRED: Memory Core. Fires exactly once when the named 'flag_key' transitions from a truthy value to absent. Useful for 'end of phase' hooks: e.g. fire once when an alert is cancelled, resume patrol when a threat flag clears. Pair with Trigger: On Memory Flag Set and Response: Clear Memory Flag."
	cpu_cost = 1
	var/flag_key = "alert"
	var/was_set = FALSE
	var/last_check = 0
	var/check_interval = 20

/datum/behavior_circuit/trigger/on_memory_flag_cleared/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	// Snapshot initial state so we don't immediately fire if flag is absent on load
	var/datum/robot_hardware/memory_core/MEM = get_hardware(R, /datum/robot_hardware/memory_core)
	was_set = MEM ? !!MEM.read(flag_key) : FALSE
	last_check = world.time
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_memory_flag_cleared/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_memory_flag_cleared/process()
	if(world.time < last_check + check_interval)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/datum/robot_hardware/memory_core/MEM = get_hardware(R, /datum/robot_hardware/memory_core)
	if(!MEM)
		return
	var/currently_set = !!MEM.read(flag_key)
	if(was_set && !currently_set)
		was_set = FALSE
		_trigger(R)
	else if(currently_set)
		was_set = TRUE


// -- SET MEMORY FLAG ---------------------------------
// Writes a named key/value pair to the Memory Core.
// This is the setter half of the flag system.

/datum/behavior_circuit/response/set_memory_flag
	needs_hardware = TRUE
	circuit_name = "Response: Set Memory Flag"
	hardware_slot_name = HW_SLOT_MEMORY
	required_hardware_type = /datum/robot_hardware/memory_core
	circuit_desc = "Writes a named flag to the Memory Core. Other circuits can read it."
	tutorial_text = "HARDWARE REQUIRED: Memory Core. Writes a key/value pair into memory. Configure 'flag_key' (the name) and 'flag_value' (what to store, default '1'). Other assemblies on the same robot can read this via Trigger: On Memory Flag Set. This is how you build multi-phase robots: trigger A sets a flag, trigger B reacts to it."
	cpu_cost = 1
	var/flag_key = "alert"
	var/flag_value = "1"

/datum/behavior_circuit/response/set_memory_flag/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/memory_core/MEM = get_hardware(R, /datum/robot_hardware/memory_core)
	if(!MEM)
		return
	MEM.write(flag_key, flag_value)


// -- CLEAR MEMORY FLAG -------------------------------
// Deletes a named key from the Memory Core.

/datum/behavior_circuit/response/clear_memory_flag
	needs_hardware = TRUE
	circuit_name = "Response: Clear Memory Flag"
	hardware_slot_name = HW_SLOT_MEMORY
	required_hardware_type = /datum/robot_hardware/memory_core
	circuit_desc = "Removes a named flag from the Memory Core."
	tutorial_text = "HARDWARE REQUIRED: Memory Core. Removes the named 'flag_key' from memory. Pair this with a timed trigger (On Interval) to auto-clear flags after a set duration, or with On Enemy Spotted clearing a 'sleeping' flag to permanently wake a robot. The complement to Set Memory Flag."
	cpu_cost = 1
	var/flag_key = "alert"

/datum/behavior_circuit/response/clear_memory_flag/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/memory_core/MEM = get_hardware(R, /datum/robot_hardware/memory_core)
	if(!MEM)
		return
	MEM.clear(flag_key)


// -- SAY REMEMBERED NAME -----------------------------
// Reads the stored "last_enemy_name" or any named
// string from Memory Core and says it aloud.  Gives
// robots the ability to reference what they remember.

/datum/behavior_circuit/response/say_memory_value
	needs_hardware = TRUE
	circuit_name = "Response: Say Memory Value"
	hardware_slot_name = HW_SLOT_MEMORY
	required_hardware_type = /datum/robot_hardware/memory_core
	circuit_desc = "Reads a named value from Memory Core and says it aloud."
	tutorial_text = "HARDWARE REQUIRED: Memory Core. Reads the string stored at 'read_key' and says it (prefixed by 'say_prefix'). If the key is empty or absent, says 'say_fallback' instead. Use with Remember Last Enemy (which writes 'last_enemy_name') to make robots announce who they're hunting. Or write any string to memory and have the robot recite it on cue."
	cpu_cost = 1
	var/read_key = "last_enemy_name"
	var/say_prefix = "Target identified:"
	var/say_fallback = "No target in memory."

/datum/behavior_circuit/response/say_memory_value/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/memory_core/MEM = get_hardware(R, /datum/robot_hardware/memory_core)
	if(!MEM)
		return
	var/val = MEM.read(read_key)
	if(val && "[val]" != "")
		R.say("[say_prefix] [val].")
	else
		R.say(say_fallback)


// -- INCREMENT MEMORY COUNTER ------------------------
// Reads a numeric key, increments it, and writes it
// back.  Enables robots that count events — shots
// fired, mobs greeted, patrols completed.

/datum/behavior_circuit/response/increment_counter
	needs_hardware = TRUE
	circuit_name = "Response: Increment Memory Counter"
	hardware_slot_name = HW_SLOT_MEMORY
	required_hardware_type = /datum/robot_hardware/memory_core
	circuit_desc = "Increments a named numeric counter in Memory Core."
	tutorial_text = "HARDWARE REQUIRED: Memory Core. Reads the value at 'counter_key', adds 'increment_by' (default 1), and writes it back. If the key doesn't exist yet, starts from 0. Use with Trigger: On Memory Flag Set (checking a threshold via another circuit) for event-counting robots. A robot can count how many enemies it's spotted, how many times it's been hit, or how many patrols it's completed."
	cpu_cost = 1
	var/counter_key = "count"
	var/increment_by = 1

/datum/behavior_circuit/response/increment_counter/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/memory_core/MEM = get_hardware(R, /datum/robot_hardware/memory_core)
	if(!MEM)
		return
	var/current = text2num(MEM.read(counter_key)) || 0
	MEM.write(counter_key, "[current + increment_by]")


// ====================================================
// PRESET: GRUDGE PROTOCOL
// Assembly 1: On Enemy Spotted ->
//   Remember Last Enemy + Set Memory Flag("grudge") +
//   Say Memory Value (announces target name)
// Assembly 2: On Memory Flag("grudge") ->
//   Pathfind To Enemy
// Assembly 3: On Death ->
//   Clear Memory Flag("grudge") + Broadcast Distress
//
// Implemented as a single multi-trigger assembly
// using max_circuits = 6.  The robot sees an enemy,
// names them, chases them persistently, and
// broadcasts on death.
// ====================================================

/obj/item/behavior_assembly/grudge
	assembly_label = "Grudge Protocol"
	max_circuits = 7

/obj/item/behavior_assembly/grudge/Initialize(mapload)
	. = ..()

	// Trigger 1: Enemy spotted -> remember + announce + flag
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T1 = new()
	var/datum/behavior_circuit/response/remember_enemy/RE1 = new()
	var/datum/behavior_circuit/response/say_memory_value/RE2 = new()
	RE2.read_key = "last_enemy_name"
	RE2.say_prefix = "Target acquired:"
	RE2.say_fallback = "Hostile detected."
	var/datum/behavior_circuit/response/set_memory_flag/RE3 = new()
	RE3.flag_key = "grudge"
	RE3.flag_value = "1"
	T1.responses_list = list(RE1, RE2, RE3)
	circuits += T1
	circuits += RE1
	circuits += RE2
	circuits += RE3

	// Trigger 2: While grudge flag is set -> chase
	var/datum/behavior_circuit/trigger/on_memory_flag/T2 = new()
	T2.flag_key = "grudge"
	T2.poll_interval = 15
	var/datum/behavior_circuit/response/pathfind_to_enemy/RE4 = new()
	T2.response = RE4
	circuits += T2
	circuits += RE4

	// Trigger 3: On death -> broadcast distress
	var/datum/behavior_circuit/trigger/on_death/T3 = new()
	var/datum/behavior_circuit/response/broadcast_distress/RE5 = new()
	T3.response = RE5
	circuits += T3
	circuits += RE5


// ====================================================
// PRESET: WATCHFUL PROTOCOL
// On Interval (slow) -> Set Memory Flag("watching")
// On Memory Flag("watching") -> Broadcast Alert
//   with a "I am observing" message
// On Enemy Spotted -> Clear Memory Flag("watching") +
//   Set Memory Flag("combat") + Enter Combat Mode
// A robot that announces its vigilance state and
// switches cleanly into combat when needed.
// ====================================================

/obj/item/behavior_assembly/watchful
	assembly_label = "Watchful Protocol"
	max_circuits = 8

/obj/item/behavior_assembly/watchful/Initialize(mapload)
	. = ..()

	// Periodic check-in: set flag and broadcast
	var/datum/behavior_circuit/trigger/on_interval/T1 = new()
	T1.interval_ticks = 400  // ~40s between check-ins
	var/datum/behavior_circuit/response/set_memory_flag/RE1 = new()
	RE1.flag_key = "watching"
	RE1.flag_value = "1"
	var/datum/behavior_circuit/response/report_position/RE2 = new()
	RE2.position_prefix = "Watchpost check-in"
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2

	// Enemy contact: clear watch flag, enter combat
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T2 = new()
	var/datum/behavior_circuit/response/clear_memory_flag/RE3 = new()
	RE3.flag_key = "watching"
	var/datum/behavior_circuit/response/set_memory_flag/RE4 = new()
	RE4.flag_key = "combat"
	RE4.flag_value = "1"
	var/datum/behavior_circuit/response/enter_combat_mode/RE5 = new()
	var/datum/behavior_circuit/response/sound_alarm/RE6 = new()
	RE6.alarm_message = "Contact! Engaging hostile."
	T2.responses_list = list(RE3, RE4, RE5, RE6)
	circuits += T2
	circuits += RE3
	circuits += RE4
	circuits += RE5
	circuits += RE6


// ====================================================
// LAYER 5 — WILD CARDS
// The weird combos. The SS13-chemistry moments.
// These are the circuits that make players stop and
// say "wait — I can do WHAT?"
// ====================================================


// -- ON ITEM PICKED UP --------------------------------
// Fires when the robot's grabber acquires a new item.
// Snapshots held_items.len at registration and fires
// whenever it increases.

/datum/behavior_circuit/trigger/on_item_picked_up
	needs_hardware = TRUE
	circuit_name = "Trigger: On Item Picked Up"
	hardware_slot_name = HW_SLOT_GRABBER
	required_hardware_type = /datum/robot_hardware/grabber
	circuit_desc = "Fires when the robot picks up a new item with its Grabber Arm."
	tutorial_text = "HARDWARE REQUIRED: Grabber Arm. Fires each time the robot's grabber acquires a new item. Configure 'pickup_cooldown' (default 10 ticks) to prevent rapid re-triggering. Good for: robots that react to what they collect — a courier that announces its cargo, a hoarder bot that emotes when it finds something, or a scavenger that throws whatever it grabs straight at enemies."
	cpu_cost = 1
	var/last_count = 0
	var/last_pickup = 0
	var/pickup_cooldown = 10

/datum/behavior_circuit/trigger/on_item_picked_up/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	var/datum/robot_hardware/grabber/GR = get_hardware(R, /datum/robot_hardware/grabber)
	last_count = GR ? GR.held_items.len : 0
	last_pickup = world.time
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_item_picked_up/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_item_picked_up/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	if(world.time < last_pickup + pickup_cooldown)
		return
	var/datum/robot_hardware/grabber/GR = get_hardware(R, /datum/robot_hardware/grabber)
	if(!GR)
		return
	var/current_count = GR.held_items.len
	if(current_count > last_count)
		last_count = current_count
		last_pickup = world.time
		_trigger(R)
	else
		last_count = current_count


// -- OFFER ITEM TO FRIENDLY --------------------------
// Extends a held item toward the nearest friendly mob.
// The robot physically hands over the item.

/datum/behavior_circuit/response/offer_item
	needs_hardware = TRUE
	circuit_name = "Response: Offer Item To Friendly"
	hardware_slot_name = HW_SLOT_GRABBER
	required_hardware_type = /datum/robot_hardware/grabber
	circuit_desc = "Hands a held item to the nearest friendly mob."
	tutorial_text = "HARDWARE REQUIRED: Grabber Arm. The robot takes the first item from its grabber and hands it to the nearest friendly mob in range. The item moves to the target's contents (their inventory) or the floor if they can't receive it. Configure 'offer_range' (default 3 tiles). Good for: courier robots that deliver items, supply bots that hand out gear, or a scavenger that brings found items back to its owner. Pair with On Item Picked Up for a full delivery loop."
	cpu_cost = 2
	var/offer_range = 3

/datum/behavior_circuit/response/offer_item/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/grabber/GR = get_hardware(R, /datum/robot_hardware/grabber)
	if(!GR || !GR.held_items.len)
		return
	var/mob/living/target = null
	var/closest = INFINITY
	for(var/mob/living/M in range(offer_range, R))
		if(M == R || M.stat != CONSCIOUS)
			continue
		if(!_is_faction_friend(R, M))
			continue
		var/d = get_dist(R, M)
		if(d < closest)
			closest = d
			target = M
	if(!target)
		return
	var/obj/item/gift = GR.held_items[1]
	if(!gift)
		return
	GR.held_items -= gift
	// Try to put in hands (carbon mobs), fall back to floor
	if(istype(target, /mob/living/carbon))
		var/mob/living/carbon/target_carbon = target
		target_carbon.put_in_hands(gift)
	else
		gift.forceMove(get_turf(target))
	R.visible_message(span_notice("[R] extends an arm toward [target] and offers [gift]."))


// -- ON FACTION MEMBER DIES --------------------------
// Fires when a same-faction mob dies within range.
// The "witness a death" trigger.

/datum/behavior_circuit/trigger/on_faction_member_dies
	circuit_name = "Trigger: On Faction Member Dies"
	circuit_desc = "Fires when a friendly mob dies nearby."
	tutorial_text = "Fires when a mob in the same faction dies within 'death_scan_range' tiles (default 8). Has a cooldown so it fires at most once per 3 seconds regardless of how many allies die at once. Good for: vengeance builds, morale broadcasts, emergency medical responses, or robots that go berserk when their owner is killed. No hardware required."
	cpu_cost = 2
	var/death_scan_range = 8
	var/last_fire = 0
	var/fire_cooldown = 30  // 3s — handles simultaneous deaths gracefully
	var/list/ally_alive_snapshot = null
	var/last_check = 0
	var/check_cooldown = 20

/datum/behavior_circuit/trigger/on_faction_member_dies/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	ally_alive_snapshot = list()
	// Snapshot current living allies
	for(var/mob/living/M in range(death_scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(_is_faction_friend(R, M))
			ally_alive_snapshot[REF(M)] = TRUE
	last_check = world.time
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_faction_member_dies/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	ally_alive_snapshot = null
	. = ..()

/datum/behavior_circuit/trigger/on_faction_member_dies/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	if(world.time < last_fire + fire_cooldown)
		return
	var/list/new_snapshot = list()
	for(var/mob/living/M in range(death_scan_range, R))
		if(M == R)
			continue
		if(!_is_faction_friend(R, M))
			continue
		if(M.stat != DEAD)
			new_snapshot[REF(M)] = TRUE
		else if(ally_alive_snapshot && (REF(M) in ally_alive_snapshot))
			// Was alive last tick, now dead
			ally_alive_snapshot = new_snapshot
			last_fire = world.time
			_trigger(R)
			return
	ally_alive_snapshot = new_snapshot


// -- TAUNT ENEMY -------------------------------------
// Says a configurable taunt line at the nearest enemy.
// Pure personality. Pure chaos.

/datum/behavior_circuit/response/taunt_enemy
	circuit_name = "Response: Taunt Enemy"
	circuit_desc = "Says a taunt line at the nearest visible enemy."
	tutorial_text = "The robot says a configurable taunt at the nearest enemy. No hardware required. Configure 'taunt_string'. Good for: personality on combat robots, psychological warfare, flavor text. Combine with On Enemy Spotted or On Take Damage. The Mr. Gutsy ships with opinions pre-installed — now it can voice them."
	cpu_cost = 1
	var/taunt_string = "Is that all you've got?"

/datum/behavior_circuit/response/taunt_enemy/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/scan_range = A ? A.sensor_range : 7
	var/mob/living/target = null
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(_is_faction_friend(R, M))
			continue
		target = M
		break
	if(target)
		R.say("[taunt_string]")
		R.setDir(get_dir(R, target))


// -- MIMIC SPEECH ------------------------------------
// Repeats the last heard speech back at the speaker.
// The "parrot bot" circuit.  Needs Microphone.

/datum/behavior_circuit/response/mimic_speech
	needs_hardware = TRUE
	circuit_name = "Response: Mimic Speech"
	hardware_slot_name = HW_SLOT_MICROPHONE
	required_hardware_type = /datum/robot_hardware/microphone
	circuit_desc = "Repeats the last heard speech back aloud. Requires Microphone hardware."
	tutorial_text = "HARDWARE REQUIRED: Microphone. The robot repeats the last thing it heard, prefixed by 'mimic_prefix' (default empty). Combine with Trigger: On Speech Heard for a robot that echoes everything said near it. Combine with On Spoken To Directly for a robot that only echoes when addressed. Great for companion bots, comedy builds, or robots with unsettling repetition behavior."
	cpu_cost = 1
	var/mimic_prefix = ""

/datum/behavior_circuit/response/mimic_speech/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/microphone/MIC = get_hardware(R, /datum/robot_hardware/microphone)
	if(!MIC || !MIC.last_heard_message)
		return
	var/msg = MIC.last_heard_message
	// Strip excess whitespace and cap length so a long speech can't flood chat
	msg = copytext(msg, 1, 120)
	if(mimic_prefix != "")
		R.say("[mimic_prefix] [msg]")
	else
		R.say(msg)


// ====================================================
// PRESET: VENGEANCE PROTOCOL
// On Faction Member Dies -> Enter Combat Mode +
//   Pathfind To Enemy + Taunt Enemy + Sound Alarm
// A robot that goes berserk when an ally falls.
// ====================================================

/obj/item/behavior_assembly/vengeance
	assembly_label = "Vengeance Protocol"
	max_circuits = 5

/obj/item/behavior_assembly/vengeance/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_faction_member_dies/T = new()
	var/datum/behavior_circuit/response/enter_combat_mode/RE1 = new()
	var/datum/behavior_circuit/response/pathfind_to_enemy/RE2 = new()
	var/datum/behavior_circuit/response/taunt_enemy/RE3 = new()
	RE3.taunt_string = "You'll pay for that!"
	var/datum/behavior_circuit/response/sound_alarm/RE4 = new()
	RE4.alarm_message = "Ally down! Engaging hostile!"
	T.responses_list = list(RE1, RE2, RE3, RE4)
	circuits += T
	circuits += RE1
	circuits += RE2
	circuits += RE3
	circuits += RE4


// ====================================================
// PRESET: COURIER PROTOCOL
// On Item Picked Up -> Report Position (announce cargo) +
//   Follow Linked Target (move toward delivery target)
// On Interval (slow) -> Grab Nearest Item
// A robot that collects items and brings them home.
// Requires Grabber Arm.  Link a delivery target with
// multitool + ID card.
// ====================================================

/obj/item/behavior_assembly/courier
	assembly_label = "Courier Protocol"
	max_circuits = 5

/obj/item/behavior_assembly/courier/Initialize(mapload)
	. = ..()
	// Periodic item collection
	var/datum/behavior_circuit/trigger/on_interval/T1 = new()
	T1.interval_ticks = 60
	var/datum/behavior_circuit/response/grab_nearest_item/RE1 = new()
	T1.response = RE1
	circuits += T1
	circuits += RE1
	// On pickup: announce and move toward delivery target
	var/datum/behavior_circuit/trigger/on_item_picked_up/T2 = new()
	var/datum/behavior_circuit/response/report_position/RE2 = new()
	RE2.position_prefix = "Cargo acquired"
	var/datum/behavior_circuit/response/follow_target/RE3 = new()
	T2.responses_list = list(RE2, RE3)
	circuits += T2
	circuits += RE2
	circuits += RE3


// ====================================================
// PRESET: PARROT PROTOCOL
// On Speech Heard -> Mimic Speech
// The simplest, strangest build possible.
// Needs Microphone.  Requires no INT.
// ====================================================

/obj/item/behavior_assembly/parrot
	assembly_label = "Parrot Protocol"

/obj/item/behavior_assembly/parrot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_speech_heard/T = new()
	var/datum/behavior_circuit/response/mimic_speech/RE = new()
	T.response = RE
	circuits += T
	circuits += RE


// ====================================================
// LAYER 6 — STEALTH & INFILTRATION
// ====================================================


// -- ON ACCESS DENIED --------------------------------
// Fires when a nearby mob fails an ID scan check.
// Complement to On Access Granted.

/datum/behavior_circuit/trigger/on_access_denied
	needs_hardware = TRUE
	circuit_name = "Trigger: On Access Denied"
	hardware_slot_name = HW_SLOT_ID_READER
	required_hardware_type = /datum/robot_hardware/id_reader
	circuit_desc = "Fires when a nearby mob lacks the required access level."
	tutorial_text = "HARDWARE REQUIRED: ID Card Reader. Fires when the robot detects a mob in scan range who does NOT have the required access level. Good for: alarm bots at restricted areas, robots that flag unauthorized personnel, or access-controlled builds that react to intruders differently than to valid credentials. Pairs well with Sound Alarm, Broadcast Alert, or Enter Combat Mode."
	cpu_cost = 1
	var/last_check = 0
	var/check_cooldown = 30
	var/last_deny_time = 0

/datum/behavior_circuit/trigger/on_access_denied/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	last_deny_time = world.time
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_access_denied/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_access_denied/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/datum/robot_hardware/id_reader/IDR = get_hardware(R, /datum/robot_hardware/id_reader)
	if(!IDR)
		return
	for(var/mob/living/carbon/human/H in range(IDR.scan_range, R))
		if(H.stat != CONSCIOUS)
			continue
		// Check if they have a valid ID with required access
		var/obj/item/card/id/ID = H.get_idcard(TRUE)
		if(!ID || !ID.access)
			// No ID or empty access list — denial
			last_deny_time = world.time
			_trigger(R)
			return
		if(IDR.required_access && !(IDR.required_access in ID.access))
			last_deny_time = world.time
			_trigger(R)
			return


// -- OPEN NEARBY DOOR --------------------------------
// Unbolts and opens the nearest door.  Complement
// to Seal Nearby Door.

/datum/behavior_circuit/response/open_nearby_door
	circuit_name = "Response: Open Nearby Door"
	circuit_desc = "Unbolts and opens the nearest bolted airlock."
	tutorial_text = "The robot finds the nearest bolted airlock within 'open_range' tiles and unbolts it. No hardware required. Configure 'open_range' (default 3). Good for: escort robots that clear the path, access robots that open doors for authorized personnel, or infiltration builds that bypass locked areas. Companion to Seal Nearby Door."
	cpu_cost = 1
	var/open_range = 3

/datum/behavior_circuit/response/open_nearby_door/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/obj/machinery/door/airlock/target = null
	var/closest = INFINITY
	for(var/obj/machinery/door/airlock/D in range(open_range, R))
		if(!D.locked)
			continue
		var/d = get_dist(R, D)
		if(d < closest)
			closest = d
			target = D
	if(!target)
		return
	target.unlock()
	target.open()
	R.visible_message(span_notice("[R] unbolts and opens [target]."))


// -- KILL LIGHTS -------------------------------------
// Turns off the robot's own light and all nearby
// toggleable light sources.  The blackout response.

/datum/behavior_circuit/response/kill_lights
	needs_hardware = TRUE
	circuit_name = "Response: Kill Lights"
	hardware_slot_name = HW_SLOT_LIGHT
	required_hardware_type = /datum/robot_hardware/light
	circuit_desc = "Shuts off the robot's own light hardware."
	tutorial_text = "HARDWARE REQUIRED: Light hardware datum. Turns off the robot's own light. Useful for stealth approaches, night-cycle ambushes, or setting mood. The robot goes dark — no headlamp, no glow. Pair with On Enemy Spotted or On Night Cycle. Companion to Toggle Light which can also force the light back on."
	cpu_cost = 1

/datum/behavior_circuit/response/kill_lights/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/light/LT = get_hardware(R, /datum/robot_hardware/light)
	if(!LT)
		return
	LT.start_on = FALSE
	R.set_light_on(FALSE)
	R.set_light_range(0)


// -- SUPPRESS VOCALISATION ---------------------------
// Sets a memory flag that tells Say Text / Emote
// responses to stay silent for a configurable window.
// Stealth mode — the robot goes dark.

/datum/behavior_circuit/response/go_quiet
	needs_hardware = TRUE
	circuit_name = "Response: Go Quiet"
	hardware_slot_name = HW_SLOT_MEMORY
	required_hardware_type = /datum/robot_hardware/memory_core
	circuit_desc = "Sets a silence flag in memory. Say Text and Emote will check this and skip output."
	tutorial_text = "HARDWARE REQUIRED: Memory Core. Writes 'silent' = '1' into memory. Pair with a timed On Interval + Clear Memory Flag to auto-expire silence after a duration. Other assemblies can check this flag with Trigger: On Memory Flag Set to avoid announcing themselves. Good for infiltration robots that go dark when approaching a target."
	cpu_cost = 1
	var/quiet_duration = 100  // ticks before auto-clear if memory persists

/datum/behavior_circuit/response/go_quiet/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/memory_core/MEM = get_hardware(R, /datum/robot_hardware/memory_core)
	if(!MEM)
		return
	MEM.write("silent", "1")
	// Silent message — the robot says nothing when going quiet
	// (that's the whole point)


// ====================================================
// PRESET: SHADOW PROTOCOL
// On Enemy Spotted -> Kill Lights + Go Quiet
// On Access Denied -> Sound Alarm + Enter Combat Mode
// A robot that goes dark on contact but screams
// when someone fails the ID check.
// Requires Light + Memory Core hardware.
// ====================================================

/obj/item/behavior_assembly/shadow
	assembly_label = "Shadow Protocol"
	max_circuits = 5

/obj/item/behavior_assembly/shadow/Initialize(mapload)
	. = ..()
	// Enemy spotted: go dark
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T1 = new()
	var/datum/behavior_circuit/response/kill_lights/RE1 = new()
	var/datum/behavior_circuit/response/go_quiet/RE2 = new()
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2
	// Access denied: alarm and combat
	var/datum/behavior_circuit/trigger/on_access_denied/T2 = new()
	var/datum/behavior_circuit/response/sound_alarm/RE3 = new()
	RE3.alarm_message = "UNAUTHORIZED ACCESS DETECTED."
	var/datum/behavior_circuit/response/enter_combat_mode/RE4 = new()
	T2.responses_list = list(RE3, RE4)
	circuits += T2
	circuits += RE3
	circuits += RE4


// ====================================================
// LAYER 7 — CROWD CONTROL & AREA DENIAL
// ====================================================


// -- ON MOB COUNT THRESHOLD --------------------------
// Fires when the number of enemies in range reaches
// or exceeds a configured count.

/datum/behavior_circuit/trigger/on_mob_count_threshold
	circuit_name = "Trigger: On Mob Count Threshold"
	circuit_desc = "Fires when enough enemies are present in sensor range simultaneously."
	tutorial_text = "Fires when the count of hostile mobs in sensor range reaches 'threshold' (default 3). Has a cooldown so it fires at most once per 5 seconds. Good for: robots that escalate tactics when overwhelmed — deploying smoke, calling backup, or going berserk. No hardware required. Pair with Deploy Smoke, Call Reinforcements, or Sound Alarm."
	cpu_cost = 2
	var/threshold = 3
	var/last_fire = 0
	var/fire_cooldown = 50
	var/last_check = 0
	var/check_cooldown = 20

/datum/behavior_circuit/trigger/on_mob_count_threshold/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_mob_count_threshold/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_mob_count_threshold/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	if(world.time < last_fire + fire_cooldown)
		return
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/obj/item/behavior_assembly/A = get_assembly()
	var/scan_range = A ? A.sensor_range : 7
	var/count = 0
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(_is_faction_friend(R, M))
			continue
		count++
	if(count >= threshold)
		last_fire = world.time
		_trigger(R)


// -- AIR BLAST ALL DIRECTIONS ------------------------
// Fires the air cannon outward in all four cardinal
// directions simultaneously.  Area suppression.

/datum/behavior_circuit/response/air_blast_area
	needs_hardware = TRUE
	circuit_name = "Response: Air Blast Area"
	hardware_slot_name = HW_SLOT_AIR_CANNON
	required_hardware_type = /datum/robot_hardware/air_cannon
	circuit_desc = "Fires the air cannon outward in all four directions, knocking back everything nearby."
	tutorial_text = "HARDWARE REQUIRED: Air Cannon hardware datum. Fires four simultaneous bursts in NORTH/SOUTH/EAST/WEST, knocking back any mob adjacent to or near the robot. Uses 4 propellant charges. More expensive than Fire Air Cannon but hits all directions at once. Good for: a robot that's surrounded, panic-mode builds, or area denial."
	cpu_cost = 3

/datum/behavior_circuit/response/air_blast_area/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/air_cannon/AC = get_hardware(R, /datum/robot_hardware/air_cannon)
	if(!AC || AC.gas_volume < 4)
		if(AC)
			R.visible_message(span_warning("[R]'s cannon is low on propellant!"))
		return
	var/turf/here = get_turf(R)
	// Blast in all 4 cardinal directions
	for(var/dir in list(NORTH, SOUTH, EAST, WEST))
		for(var/mob/living/M in range(2, R))
			if(M == R)
				continue
			var/mob_dir = get_dir(here, get_turf(M))
			if(!(mob_dir & dir))
				continue
			M.throw_at(get_step(get_turf(M), dir), AC.knockback_force, 1, R)
	AC.gas_volume = max(0, AC.gas_volume - 4)
	R.visible_message(span_danger("[R] releases a full-circle pressure burst!"))


// -- STROBE FLASH ------------------------------------
// Rapidly blinks the robot's light to disorient.

/datum/behavior_circuit/response/strobe_flash
	needs_hardware = TRUE
	circuit_name = "Response: Strobe Flash"
	hardware_slot_name = HW_SLOT_LIGHT
	required_hardware_type = /datum/robot_hardware/light
	circuit_desc = "Rapidly blinks the robot's light for a disorienting effect."
	tutorial_text = "HARDWARE REQUIRED: Light hardware datum. Rapidly pulses the robot's light on and off several times. No direct gameplay effect but creates strong visual noise and is good for roleplay panic/alert moments, adding flair to combat transitions, or companion bots that react to danger expressively. No damage dealt."
	cpu_cost = 1
	var/flash_pulses = 4

/datum/behavior_circuit/response/strobe_flash/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/light/LT = get_hardware(R, /datum/robot_hardware/light)
	if(!LT)
		return
	// Rapid toggle — each toggle is async so this returns immediately
	// The visual effect plays out over ~1 second in background
	INVOKE_ASYNC(src, PROC_REF(_do_strobe), R, LT)

/datum/behavior_circuit/response/strobe_flash/proc/_do_strobe(mob/living/silicon/robot/R, datum/robot_hardware/light/LT)
	var/original_state = LT.start_on
	for(var/i in 1 to flash_pulses)
		if(!R || R.stat == DEAD)
			break
		R.set_light_on(TRUE)
		R.set_light_range(LT.light_brightness)
		sleep(2)
		R.set_light_on(FALSE)
		R.set_light_range(0)
		sleep(2)
	// Restore original state
	LT.start_on = original_state
	if(R && R.stat != DEAD)
		if(original_state)
			R.set_light_on(TRUE)
			R.set_light_range(LT.light_brightness)


// ====================================================
// PRESET: CROWD CONTROL PROTOCOL
// On Mob Count Threshold (3+) ->
//   Air Blast Area + Deploy Smoke + Sound Alarm
// A robot that goes area-suppression mode when
// surrounded.  Requires Air Cannon hardware.
// ====================================================

/obj/item/behavior_assembly/crowd_control
	assembly_label = "Crowd Control Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/crowd_control/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_mob_count_threshold/T = new()
	T.threshold = 3
	var/datum/behavior_circuit/response/air_blast_area/RE1 = new()
	var/datum/behavior_circuit/response/deploy_smoke/RE2 = new()
	var/datum/behavior_circuit/response/sound_alarm/RE3 = new()
	RE3.alarm_message = "Multiple hostiles engaged. Suppression systems active."
	T.responses_list = list(RE1, RE2, RE3)
	circuits += T
	circuits += RE1
	circuits += RE2
	circuits += RE3


// ====================================================
// LAYER 8 — LOGISTICS & RESOURCE
// ====================================================


// -- ON GRABBER FULL ---------------------------------

/datum/behavior_circuit/trigger/on_grabber_full
	needs_hardware = TRUE
	circuit_name = "Trigger: On Grabber Full"
	hardware_slot_name = HW_SLOT_GRABBER
	required_hardware_type = /datum/robot_hardware/grabber
	circuit_desc = "Fires when the Grabber Arm reaches maximum item capacity."
	tutorial_text = "HARDWARE REQUIRED: Grabber Arm. Fires when held_items.len reaches max_items. Resets when capacity drops back below max. Good for: courier robots that switch to delivery mode when loaded, scavengers that stop grabbing and head home, or bots that announce they're full and need unloading. Pair with Follow Linked Target or Report Position."
	cpu_cost = 1
	var/last_check = 0
	var/check_cooldown = 20
	var/was_full = FALSE

/datum/behavior_circuit/trigger/on_grabber_full/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	was_full = FALSE
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_grabber_full/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_grabber_full/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/datum/robot_hardware/grabber/GR = get_hardware(R, /datum/robot_hardware/grabber)
	if(!GR)
		return
	var/is_full = (GR.held_items.len >= GR.max_items)
	if(is_full && !was_full)
		was_full = TRUE
		_trigger(R)
	else if(!is_full)
		was_full = FALSE


// -- ON GRABBER EMPTY --------------------------------

/datum/behavior_circuit/trigger/on_grabber_empty
	needs_hardware = TRUE
	circuit_name = "Trigger: On Grabber Empty"
	hardware_slot_name = HW_SLOT_GRABBER
	required_hardware_type = /datum/robot_hardware/grabber
	circuit_desc = "Fires when the Grabber Arm drops to zero held items."
	tutorial_text = "HARDWARE REQUIRED: Grabber Arm. Fires once when held_items drops to zero after having held something. Resets when the grabber acquires items again. Good for: a delivery bot that switches back to collection mode after dropping off cargo, or a scavenger that announces it's ready for more. Pair with Grab Nearest Item or Report Position."
	cpu_cost = 1
	var/last_check = 0
	var/check_cooldown = 20
	var/was_holding = FALSE

/datum/behavior_circuit/trigger/on_grabber_empty/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	var/datum/robot_hardware/grabber/GR = get_hardware(R, /datum/robot_hardware/grabber)
	was_holding = GR ? (GR.held_items.len > 0) : FALSE
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_grabber_empty/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_grabber_empty/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/datum/robot_hardware/grabber/GR = get_hardware(R, /datum/robot_hardware/grabber)
	if(!GR)
		return
	var/now_empty = (GR.held_items.len == 0)
	if(now_empty && was_holding)
		was_holding = FALSE
		_trigger(R)
	else if(!now_empty)
		was_holding = TRUE


// -- DEPOSIT TO CONTAINER ----------------------------
// Moves all held items into the nearest container
// object within range.

/datum/behavior_circuit/response/deposit_to_container
	needs_hardware = TRUE
	circuit_name = "Response: Deposit To Container"
	hardware_slot_name = HW_SLOT_GRABBER
	required_hardware_type = /datum/robot_hardware/grabber
	circuit_desc = "Deposits all held items into the nearest container. Requires Grabber Arm."
	tutorial_text = "HARDWARE REQUIRED: Grabber Arm. Moves all currently held items into the nearest accessible container (crate, locker, bag) within 'deposit_range' tiles. Moves adjacent if needed. Good for: scavenger bots that collect and store, supply bots that stock crates, or any robot that needs a drop-off point. Pair with On Grabber Full for a full collect-deposit loop."
	cpu_cost = 2
	var/deposit_range = 4

/datum/behavior_circuit/response/deposit_to_container/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/grabber/GR = get_hardware(R, /datum/robot_hardware/grabber)
	if(!GR || !GR.held_items.len)
		return
	// Find nearest container
	var/obj/target = null
	var/closest = INFINITY
	for(var/obj/O in range(deposit_range, R))
		if(!istype(O, /obj/structure/closet) && !istype(O, /obj/item/storage/box))
			continue
		var/d = get_dist(R, O)
		if(d < closest)
			closest = d
			target = O
	if(!target)
		return
	if(get_dist(R, target) > 1)
		step_towards(R, target)
		return
	// Deposit all held items
	var/count = 0
	for(var/obj/item/I in GR.held_items.Copy())
		I.forceMove(target)
		GR.held_items -= I
		count++
	if(count > 0)
		R.visible_message(span_notice("[R] deposits [count] item\s into [target]."))


// -- REQUEST RESUPPLY --------------------------------
// Broadcasts a specific resupply request on radio.

/datum/behavior_circuit/response/request_resupply
	circuit_name = "Response: Request Resupply"
	circuit_desc = "Broadcasts a resupply request on the radio channel."
	tutorial_text = "Broadcasts a resupply request over the robot's radio channel with its current location. No hardware required. Configure 'supply_type' (what to ask for, default 'materials') and 'urgency' (default 'standard'). Good for: mining bots that call for pickup, medical robots that need more stimpaks, or any logistics chain."
	cpu_cost = 1
	var/supply_type = "materials"
	var/urgency = "standard"

/datum/behavior_circuit/response/request_resupply/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/area/here = get_area(R)
	var/loc_name = here ? here.name : "unknown location"
	R.say(";RESUPPLY REQUEST ([urgency]): [R.name] requires [supply_type] at [loc_name].")


// ====================================================
// PRESET: DEPOT PROTOCOL
// On Grabber Full -> Deposit To Container + Report Position
// On Grabber Empty -> Grab Nearest Item
// Full collect-deposit loop.  Requires Grabber Arm.
// ====================================================

/obj/item/behavior_assembly/depot
	assembly_label = "Depot Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/depot/Initialize(mapload)
	. = ..()
	// Full -> deposit and report
	var/datum/behavior_circuit/trigger/on_grabber_full/T1 = new()
	var/datum/behavior_circuit/response/deposit_to_container/RE1 = new()
	var/datum/behavior_circuit/response/report_position/RE2 = new()
	RE2.position_prefix = "Depot full — depositing at"
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2
	// Empty -> collect again
	var/datum/behavior_circuit/trigger/on_grabber_empty/T2 = new()
	var/datum/behavior_circuit/response/grab_nearest_item/RE3 = new()
	T2.response = RE3
	circuits += T2
	circuits += RE3


// ====================================================
// LAYER 9 — COMPANION & PROTECTION
// ====================================================


// -- ON OWNER HURT -----------------------------------
// Fires when the linked follow-target takes damage.
// The bodyguard trigger.

/datum/behavior_circuit/trigger/on_owner_hurt
	circuit_name = "Trigger: On Owner Hurt"
	circuit_desc = "Fires when the robot's linked follow-target takes significant damage."
	tutorial_text = "Fires when the mob linked as follow-target takes damage above 'owner_damage_threshold' (default 10 HP). The link is the same one used by Follow Linked Target — set it with multitool + ID card. No hardware required. Good for: bodyguard builds that switch to combat when the owner is attacked, or companions that call for help when their human is hurt."
	cpu_cost = 2
	var/owner_damage_threshold = 10
	var/last_fire = 0
	var/fire_cooldown = 20
	var/owner_health_snapshot = -1

/datum/behavior_circuit/trigger/on_owner_hurt/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	// Snapshot owner health if already linked
	var/datum/behavior_circuit/response/follow_target/FT = null
	for(var/datum/behavior_circuit/C in A?.circuits)
		if(istype(C, /datum/behavior_circuit/response/follow_target))
			FT = C
			break
	if(FT && FT.linked_target_ref)
		var/mob/living/owner = FT.linked_target_ref.resolve()
		if(owner)
			owner_health_snapshot = owner.health
	START_PROCESSING(SSfastprocess, src)

/datum/behavior_circuit/trigger/on_owner_hurt/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSfastprocess, src)
	. = ..()

/datum/behavior_circuit/trigger/on_owner_hurt/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSfastprocess, src)
		return
	if(world.time < last_fire + fire_cooldown)
		return
	// Find the follow_target circuit on this assembly to get the linked mob
	var/obj/item/behavior_assembly/A = get_assembly()
	if(!A)
		return
	var/datum/behavior_circuit/response/follow_target/FT = null
	for(var/datum/behavior_circuit/C in A.circuits)
		if(istype(C, /datum/behavior_circuit/response/follow_target))
			FT = C
			break
	if(!FT || !FT.linked_target_ref)
		return
	var/mob/living/owner = FT.linked_target_ref.resolve()
	if(!owner || owner.stat == DEAD)
		return
	if(owner_health_snapshot < 0)
		owner_health_snapshot = owner.health
		return
	var/delta = owner_health_snapshot - owner.health
	owner_health_snapshot = owner.health
	if(delta >= owner_damage_threshold)
		last_fire = world.time
		_trigger(R)


// -- INTERPOSE SELF ----------------------------------
// Steps the robot between its linked follow-target
// and the nearest threat.

/datum/behavior_circuit/response/interpose_self
	circuit_name = "Response: Interpose Self"
	circuit_desc = "Moves the robot between its linked follow-target and the nearest enemy."
	tutorial_text = "Steps the robot to a position between its linked follow-target and the nearest hostile. Uses the same link as Follow Linked Target (multitool + ID card). No hardware required. Good for: bodyguard robots that physically shield their charge, companions that step in front of danger, or tanks that protect a fragile ally. Pair with On Owner Hurt."
	cpu_cost = 2

/datum/behavior_circuit/response/interpose_self/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.anchored || R.stat == DEAD || !A)
		return
	// Find linked target
	var/datum/behavior_circuit/response/follow_target/FT = null
	for(var/datum/behavior_circuit/C in A.circuits)
		if(istype(C, /datum/behavior_circuit/response/follow_target))
			FT = C
			break
	if(!FT || !FT.linked_target_ref)
		return
	var/mob/living/owner = FT.linked_target_ref.resolve()
	if(!owner || owner.stat == DEAD)
		return
	// Find nearest threat
	var/scan_range = A.sensor_range
	var/mob/living/threat = null
	var/closest = INFINITY
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD || _is_faction_friend(R, M))
			continue
		var/d = get_dist(owner, M)
		if(d < closest)
			closest = d
			threat = M
	if(!threat)
		return
	// Step toward the midpoint between owner and threat
	var/turf/owner_turf = get_turf(owner)
	var/turf/threat_turf = get_turf(threat)
	if(!owner_turf || !threat_turf)
		return
	// Move toward owner if farther, otherwise step toward threat
	if(get_dist(R, owner) > 2)
		step_towards(R, owner)
	else
		step_towards(R, threat)
	R.setDir(get_dir(R, threat))


// -- DRAG INJURED ALLY -------------------------------
// Grabs and pulls the nearest critically-injured
// friendly toward the robot's spawn point.

/datum/behavior_circuit/response/drag_injured_ally
	circuit_name = "Response: Drag Injured Ally"
	circuit_desc = "Grabs and pulls the nearest critically-injured friendly toward safety."
	tutorial_text = "Finds the nearest conscious-but-critically-injured friendly (below 'drag_threshold' HP, default 30), grabs them, and begins pulling toward the robot's spawn point. No hardware required — spawn point is captured at assembly registration. Good for: combat medic robots that extract casualties, rescue bots, or any companion that prioritizes keeping allies alive."
	cpu_cost = 2
	var/drag_threshold = 30
	var/turf/safe_turf = null

/datum/behavior_circuit/response/drag_injured_ally/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	safe_turf = get_turf(R)

/datum/behavior_circuit/response/drag_injured_ally/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.anchored || R.stat == DEAD || !safe_turf)
		return
	var/scan_range = A ? A.sensor_range : 5
	var/mob/living/target = null
	var/lowest_hp = drag_threshold
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(!_is_faction_friend(R, M))
			continue
		if(M.health < lowest_hp)
			lowest_hp = M.health
			target = M
	if(!target)
		return
	R.pulling = target
	step_towards(R, safe_turf)
	R.visible_message(span_notice("[R] grabs [target] and drags them toward safety."))


// ====================================================
// PRESET: BODYGUARD PROTOCOL
// On Owner Hurt -> Interpose Self + Enter Combat Mode
//   + Taunt Enemy ("Back away from them!")
// On Interval -> Follow Linked Target
// Requires linking via multitool + ID card.
// ====================================================

/obj/item/behavior_assembly/bodyguard
	assembly_label = "Bodyguard Protocol"
	max_circuits = 5

/obj/item/behavior_assembly/bodyguard/Initialize(mapload)
	. = ..()
	// Persistent follow
	var/datum/behavior_circuit/trigger/on_interval/T1 = new()
	T1.interval_ticks = 20
	var/datum/behavior_circuit/response/follow_target/RE1 = new()
	T1.response = RE1
	circuits += T1
	circuits += RE1
	// Owner hurt: interpose + combat + taunt
	var/datum/behavior_circuit/trigger/on_owner_hurt/T2 = new()
	var/datum/behavior_circuit/response/interpose_self/RE2 = new()
	var/datum/behavior_circuit/response/enter_combat_mode/RE3 = new()
	var/datum/behavior_circuit/response/taunt_enemy/RE4 = new()
	RE4.taunt_string = "Back away from them!"
	T2.responses_list = list(RE2, RE3, RE4)
	circuits += T2
	circuits += RE2
	circuits += RE3
	circuits += RE4


// ====================================================
// LAYER 10 — TIMING & SEQUENCING
// ====================================================


// -- ON COUNTDOWN COMPLETE ---------------------------
// Decrements a named memory counter each poll and
// fires when it reaches zero.  The "delayed action"
// trigger.

/datum/behavior_circuit/trigger/on_countdown
	needs_hardware = TRUE
	circuit_name = "Trigger: On Countdown Complete"
	hardware_slot_name = HW_SLOT_MEMORY
	required_hardware_type = /datum/robot_hardware/memory_core
	circuit_desc = "Fires when a named countdown counter in memory reaches zero."
	tutorial_text = "HARDWARE REQUIRED: Memory Core. Reads 'counter_key' from memory each poll ('poll_interval' ticks, default 20). If the value is a number > 0, decrements it and writes it back. When it hits 0, fires and clears the key. Use Response: Set Memory Flag (with a numeric value) to start the countdown. Good for: delayed explosions, timed lockdowns that expire, behaviors that fire N ticks after an event."
	cpu_cost = 2
	var/counter_key = "countdown"
	var/poll_interval = 20
	var/last_check = 0

/datum/behavior_circuit/trigger/on_countdown/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	last_check = world.time
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_countdown/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_countdown/process()
	if(world.time < last_check + poll_interval)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/datum/robot_hardware/memory_core/MEM = get_hardware(R, /datum/robot_hardware/memory_core)
	if(!MEM)
		return
	var/val = text2num(MEM.read(counter_key))
	if(val == null || val <= 0)
		return
	var/new_val = val - 1
	if(new_val <= 0)
		MEM.clear(counter_key)
		_trigger(R)
	else
		MEM.write(counter_key, "[new_val]")


// -- ONE-SHOT LOCKOUT --------------------------------
// Sets a permanent "fired" flag so the assembly
// can only fire once ever — even across reboots.

/datum/behavior_circuit/response/one_shot_lockout
	needs_hardware = TRUE
	circuit_name = "Response: One-Shot Lockout"
	hardware_slot_name = HW_SLOT_MEMORY
	required_hardware_type = /datum/robot_hardware/memory_core
	circuit_desc = "Sets a permanent lockout flag so this assembly only fires once ever."
	tutorial_text = "HARDWARE REQUIRED: Memory Core. Writes 'lockout_key' = '1' permanently into memory. Pair this as the LAST response in a sequence — once it fires, the Trigger: On Memory Flag Set with the same key becomes the gate that blocks re-firing. Use for true one-shot behaviors: a single distress call, a one-time self-destruct confirmation, or an introduction sequence that never repeats."
	cpu_cost = 1
	var/lockout_key = "fired"

/datum/behavior_circuit/response/one_shot_lockout/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/memory_core/MEM = get_hardware(R, /datum/robot_hardware/memory_core)
	if(!MEM)
		return
	MEM.write(lockout_key, "1")


// -- BROADCAST MEMORY COUNTER STATUS -----------------
// Reads a counter from memory and says its value on
// radio — gives robots a way to report numeric state.

/datum/behavior_circuit/response/broadcast_counter
	needs_hardware = TRUE
	circuit_name = "Response: Broadcast Counter Status"
	hardware_slot_name = HW_SLOT_MEMORY
	required_hardware_type = /datum/robot_hardware/memory_core
	circuit_desc = "Reads a named counter from memory and broadcasts its value on radio."
	tutorial_text = "HARDWARE REQUIRED: Memory Core. Reads the numeric value stored at 'counter_key' and broadcasts it over radio. Configure 'counter_prefix' to customise the message (default: 'Counter status'). Good for: patrol bots that report their patrol count, sentries that announce their kill count, or any robot that tracks and reports a numeric stat. Pairs naturally with Increment Memory Counter."
	cpu_cost = 1
	var/counter_key = "count"
	var/counter_prefix = "Counter status"

/datum/behavior_circuit/response/broadcast_counter/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/memory_core/MEM = get_hardware(R, /datum/robot_hardware/memory_core)
	if(!MEM)
		return
	var/val = MEM.read(counter_key)
	var/display = (val != null) ? "[val]" : "0"
	R.say(";[counter_prefix]: [display]")


// ====================================================
// PRESET: ESCALATION PROTOCOL
// On Take Damage -> Increment Counter("hits")
// On Countdown("escalate") -> Enter Combat Mode +
//   Call Reinforcements + Say Text ("Threat level escalated.")
// On Interval (very slow) -> Clear Counter (de-escalate)
//
// A robot that stays calm under light fire but
// escalates to full combat after absorbing enough hits.
// Requires Memory Core hardware.  INT 7+.
// ====================================================

/obj/item/behavior_assembly/escalation
	assembly_label = "Escalation Protocol"
	max_circuits = 8

/obj/item/behavior_assembly/escalation/Initialize(mapload)
	. = ..()
	// Each hit increments the counter
	var/datum/behavior_circuit/trigger/on_take_damage/T1 = new()
	T1.damage_threshold = 8
	var/datum/behavior_circuit/response/increment_counter/RE1 = new()
	RE1.counter_key = "hits"
	T1.response = RE1
	circuits += T1
	circuits += RE1
	// Memory flag set when hits >= 3: set countdown to trigger escalation
	var/datum/behavior_circuit/trigger/on_memory_flag/T2 = new()
	T2.flag_key = "hits"
	T2.poll_interval = 20
	var/datum/behavior_circuit/response/set_memory_flag/RE2 = new()
	RE2.flag_key = "escalate"
	RE2.flag_value = "3"  // 3-tick countdown
	T2.response = RE2
	circuits += T2
	circuits += RE2
	// Countdown fires: escalate
	var/datum/behavior_circuit/trigger/on_countdown/T3 = new()
	T3.counter_key = "escalate"
	var/datum/behavior_circuit/response/enter_combat_mode/RE3 = new()
	var/datum/behavior_circuit/response/call_reinforcements/RE4 = new()
	var/datum/behavior_circuit/response/say_text/RE5 = new()
	RE5.say_string = "Threat level escalated. Combat systems engaged."
	T3.responses_list = list(RE3, RE4, RE5)
	circuits += T3
	circuits += RE3
	circuits += RE4
	circuits += RE5
	// Slow de-escalation: clear hit counter after 60 seconds of quiet
	var/datum/behavior_circuit/trigger/on_interval/T4 = new()
	T4.interval_ticks = 600
	var/datum/behavior_circuit/response/clear_memory_flag/RE6 = new()
	RE6.flag_key = "hits"
	T4.response = RE6
	circuits += T4
	circuits += RE6


// ====================================================
// PRESET: DEAD MAN TIMER
// On Death -> Set Memory Flag("countdown") = "5"
// On Countdown("countdown") -> Detonate Self
//
// The robot arms itself on death and detonates
// after a 5-tick delay.  More dramatic than Last Resort
// because it gives enemies a moment to react.
// Requires Memory Core hardware.
// ====================================================

/obj/item/behavior_assembly/dead_man_timer
	assembly_label = "Dead Man Timer"
	max_circuits = 4

/obj/item/behavior_assembly/dead_man_timer/Initialize(mapload)
	. = ..()
	// Death arms the countdown
	var/datum/behavior_circuit/trigger/on_death/T1 = new()
	var/datum/behavior_circuit/response/set_memory_flag/RE1 = new()
	RE1.flag_key = "countdown"
	RE1.flag_value = "5"
	var/datum/behavior_circuit/response/say_text/RE2 = new()
	RE2.say_string = "Dead man switch armed. Detonation in 5 ticks."
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2
	// Countdown fires detonation
	var/datum/behavior_circuit/trigger/on_countdown/T2 = new()
	T2.counter_key = "countdown"
	var/datum/behavior_circuit/response/detonate_self/RE3 = new()
	T2.response = RE3
	circuits += T2
	circuits += RE3


// ====================================================
// FARMING BOT PROTOCOL
// The full autonomous farm loop:
//   On Interval -> Harvest Nearby Plants
//                  + Grab Nearest Item (collect yield)
//   On Grabber Full -> Report Position (loaded) +
//                      Follow Linked Target (return)
//   On Grabber Empty -> Report Position (ready)
//
// Designed for Mr. Handy with:
//   - Harvester Module hardware (auto_replant = TRUE)
//   - Grabber Arm hardware
// Link a drop-off target with multitool + ID card
// so the bot returns when loaded.
// ====================================================

/obj/item/behavior_assembly/farming_bot
	assembly_label = "Farming Protocol"
	max_circuits = 6

/obj/item/behavior_assembly/farming_bot/Initialize(mapload)
	. = ..()
	// Primary loop: harvest then collect yield
	var/datum/behavior_circuit/trigger/on_interval/T1 = new()
	T1.interval_ticks = 50  // ~5s between harvest sweeps
	var/datum/behavior_circuit/response/harvest_plants/RE1 = new()
	var/datum/behavior_circuit/response/grab_nearest_item/RE2 = new()
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2
	// Full load: report and return to linked target
	var/datum/behavior_circuit/trigger/on_grabber_full/T2 = new()
	var/datum/behavior_circuit/response/report_position/RE3 = new()
	RE3.position_prefix = "Harvest loaded"
	var/datum/behavior_circuit/response/follow_target/RE4 = new()
	T2.responses_list = list(RE3, RE4)
	circuits += T2
	circuits += RE3
	circuits += RE4


// ====================================================
// LAYER A — UTILITY & SERVICE PROTOCOLS
// ====================================================


// ====================================================
// PRESET: JANITOR PROTOCOL
// On Mess Detected -> Emote Action ("moves to clean up")
//                  + Say Text ("This is unacceptable.")
// On Interval (slow) -> Emote Action ("scrubs the floor")
// No hardware required.  Mr. Handy natural pairing.
// ====================================================

/obj/item/behavior_assembly/janitor
	assembly_label = "Janitor Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/janitor/Initialize(mapload)
	. = ..()
	// Mess detected: react and complain
	var/datum/behavior_circuit/trigger/on_mess_detected/T1 = new()
	var/datum/behavior_circuit/response/emote_action/RE1 = new()
	RE1.emote_text = "moves purposefully toward the mess"
	var/datum/behavior_circuit/response/say_text/RE2 = new()
	RE2.say_string = "Unsanitary conditions detected. Corrective action initiated."
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2
	// Slow ambient loop: scrubbing emote when nothing is happening
	var/datum/behavior_circuit/trigger/on_idle/T2 = new()
	T2.idle_ticks = 300
	var/datum/behavior_circuit/response/emote_action/RE3 = new()
	RE3.emote_text = "wipes down a nearby surface with a cleaning cloth"
	T2.response = RE3
	circuits += T2
	circuits += RE3


// ====================================================
// PRESET: LAMP BOT PROTOCOL
// On Darkness -> Toggle Light (force on)
// On Lit      -> Toggle Light (force off)
// The robot is a smart lamp.
// Requires Light hardware.
// ====================================================

/obj/item/behavior_assembly/lamp_bot
	assembly_label = "Lamp Bot Protocol"
	max_circuits = 2

/obj/item/behavior_assembly/lamp_bot/Initialize(mapload)
	. = ..()
	// Dark: turn on
	var/datum/behavior_circuit/trigger/on_darkness/T1 = new()
	var/datum/behavior_circuit/response/toggle_light/RE1 = new()
	RE1.force_state = 1
	T1.response = RE1
	circuits += T1
	circuits += RE1
	// Lit: turn off
	var/datum/behavior_circuit/trigger/on_lit/T2 = new()
	var/datum/behavior_circuit/response/toggle_light/RE2 = new()
	RE2.force_state = 0
	T2.response = RE2
	circuits += T2
	circuits += RE2


// ====================================================
// PRESET: BATTERY STEWARD PROTOCOL
// On Low Power  -> Read Battery + Retreat To Spawn
// On Power Restored -> Read Battery + Report Position
// A robot that manages its own power cycle and
// announces when it's back online.
// No hardware required.
// ====================================================

/obj/item/behavior_assembly/battery_steward
	assembly_label = "Battery Steward Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/battery_steward/Initialize(mapload)
	. = ..()
	// Low power: announce and retreat to charging point
	var/datum/behavior_circuit/trigger/on_low_power/T1 = new()
	T1.charge_threshold = 0.2
	var/datum/behavior_circuit/response/read_battery/RE1 = new()
	var/datum/behavior_circuit/response/retreat_to_spawn/RE2 = new()
	var/datum/behavior_circuit/response/say_text/RE3 = new()
	RE3.say_string = "Power cell low. Returning to charge station."
	T1.responses_list = list(RE1, RE2, RE3)
	circuits += T1
	circuits += RE1
	circuits += RE2
	circuits += RE3
	// Power restored: announce readiness
	var/datum/behavior_circuit/trigger/on_power_restored/T2 = new()
	var/datum/behavior_circuit/response/read_battery/RE4 = new()
	var/datum/behavior_circuit/response/report_position/RE5 = new()
	RE5.position_prefix = "Power restored — back online"
	T2.responses_list = list(RE4, RE5)
	circuits += T2
	circuits += RE4
	circuits += RE5


// ====================================================
// PRESET: CHEM RUNNER PROTOCOL
// On Reagent Container Nearby -> Collect Reagents
//                              + Follow Linked Target
// Collects nearby chemistry supplies and brings them
// to a linked chemist or dispenser.
// Link target with multitool + ID card.
// No hardware required.
// ====================================================

/obj/item/behavior_assembly/chem_runner
	assembly_label = "Chem Runner Protocol"
	max_circuits = 3

/obj/item/behavior_assembly/chem_runner/Initialize(mapload)
	. = ..()
	// Reagent spotted: collect and bring to linked target
	var/datum/behavior_circuit/trigger/on_reagent_container_nearby/T1 = new()
	T1.check_range = 5
	var/datum/behavior_circuit/response/collect_reagents/RE1 = new()
	var/datum/behavior_circuit/response/follow_target/RE2 = new()
	var/datum/behavior_circuit/response/report_position/RE3 = new()
	RE3.position_prefix = "Chem pickup"
	T1.responses_list = list(RE1, RE2, RE3)
	circuits += T1
	circuits += RE1
	circuits += RE2
	circuits += RE3


// ====================================================
// LAYER B — COMBAT DEPTH PROTOCOLS
// ====================================================


// ====================================================
// PRESET: REACTIVE MARKSMAN PROTOCOL
// On Hit -> Maintain Combat Range + Fire Weapon +
//           Taunt Enemy
// A robot that backs off when shot and returns fire
// while trash-talking.  Requires Weapon hardware.
// ====================================================

/obj/item/behavior_assembly/reactive_marksman
	assembly_label = "Reactive Marksman Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/reactive_marksman/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_hit/T = new()
	var/datum/behavior_circuit/response/maintain_combat_range/RE1 = new()
	var/datum/behavior_circuit/response/fire_weapon/RE2 = new()
	var/datum/behavior_circuit/response/taunt_enemy/RE3 = new()
	RE3.taunt_string = "You'll have to do better than that."
	T.responses_list = list(RE1, RE2, RE3)
	circuits += T
	circuits += RE1
	circuits += RE2
	circuits += RE3


// ====================================================
// PRESET: GRENADIER PROTOCOL
// On Mob Count Threshold (3+) -> Prime Grenade +
//                                Flee From Threat
// Lobs a grenade into a crowd then retreats.
// Requires Grenade Launcher hardware.
// ====================================================

/obj/item/behavior_assembly/grenadier
	assembly_label = "Grenadier Protocol"
	max_circuits = 3

/obj/item/behavior_assembly/grenadier/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_mob_count_threshold/T = new()
	T.threshold = 3
	var/datum/behavior_circuit/response/prime_grenade/RE1 = new()
	var/datum/behavior_circuit/response/flee_from_threat/RE2 = new()
	T.responses_list = list(RE1, RE2)
	circuits += T
	circuits += RE1
	circuits += RE2


// ====================================================
// PRESET: STUN & SUBDUE PROTOCOL
// On Enemy Spotted -> Stun Target + Enter Combat Mode
// On Ally Under Attack -> Stun Target
// Focuses on incapacitation over lethal force.
// Best on a Protectron.  Stun Module hardware
// recommended but not required.
// ====================================================

/obj/item/behavior_assembly/stun_subdue
	assembly_label = "Stun & Subdue Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/stun_subdue/Initialize(mapload)
	. = ..()
	// Enemy spotted: stun and enter combat
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T1 = new()
	var/datum/behavior_circuit/response/stun_target/RE1 = new()
	var/datum/behavior_circuit/response/enter_combat_mode/RE2 = new()
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2
	// Ally under attack: stun the attacker
	var/datum/behavior_circuit/trigger/on_ally_under_attack/T2 = new()
	var/datum/behavior_circuit/response/stun_target/RE3 = new()
	T2.response = RE3
	circuits += T2
	circuits += RE3


// ====================================================
// PRESET: COMBAT SOUND RESPONSE PROTOCOL
// On Combat Sound Nearby -> Enter Combat Mode +
//   Sound Alarm + Set Memory Flag("alert")
// On Memory Flag("alert") -> Report Position +
//   Pathfind To Enemy
// Wakes on gunfire, reports contact, and hunts the
// source.  Requires Microphone hardware.
// ====================================================

/obj/item/behavior_assembly/combat_response
	assembly_label = "Combat Response Protocol"
	max_circuits = 6

/obj/item/behavior_assembly/combat_response/Initialize(mapload)
	. = ..()
	// Gunfire heard: wake up and flag
	var/datum/behavior_circuit/trigger/on_combat_sound_nearby/T1 = new()
	var/datum/behavior_circuit/response/enter_combat_mode/RE1 = new()
	var/datum/behavior_circuit/response/sound_alarm/RE2 = new()
	RE2.alarm_message = "Gunfire detected. Responding."
	var/datum/behavior_circuit/response/set_memory_flag/RE3 = new()
	RE3.flag_key = "alert"
	RE3.flag_value = "1"
	T1.responses_list = list(RE1, RE2, RE3)
	circuits += T1
	circuits += RE1
	circuits += RE2
	circuits += RE3
	// While alert: report and pursue
	var/datum/behavior_circuit/trigger/on_memory_flag/T2 = new()
	T2.flag_key = "alert"
	T2.poll_interval = 25
	var/datum/behavior_circuit/response/report_position/RE4 = new()
	RE4.position_prefix = "Responding to contact"
	var/datum/behavior_circuit/response/pathfind_to_enemy/RE5 = new()
	T2.responses_list = list(RE4, RE5)
	circuits += T2
	circuits += RE4
	circuits += RE5


// ====================================================
// LAYER C — SPECIALIST PROTOCOLS
// ====================================================


// ====================================================
// PRESET: BIO SCOUT PROTOCOL
// On Mutant Detected -> Broadcast Bio Report +
//   Remember Last Enemy + Set Memory Flag("contact")
// Requires Bio Scanner hardware.  INT 7+.
// Field researcher that scans and logs unusual biology.
// ====================================================

/obj/item/behavior_assembly/bio_scout
	assembly_label = "Bio Scout Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/bio_scout/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_mutant_detected/T = new()
	var/datum/behavior_circuit/response/broadcast_bio_report/RE1 = new()
	var/datum/behavior_circuit/response/remember_enemy/RE2 = new()
	var/datum/behavior_circuit/response/set_memory_flag/RE3 = new()
	RE3.flag_key = "contact"
	RE3.flag_value = "1"
	T.responses_list = list(RE1, RE2, RE3)
	circuits += T
	circuits += RE1
	circuits += RE2
	circuits += RE3


// ====================================================
// PRESET: HAZMAT RESPONDER PROTOCOL
// On Radiation Detected -> Hazmat Warning +
//   Spray Reagent (RadAway) + Seal Nearby Door
// Contamination containment robot.
// Requires Environment Scanner + Chem Sprayer hardware.
// ====================================================

/obj/item/behavior_assembly/hazmat_responder
	assembly_label = "Hazmat Responder Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/hazmat_responder/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_radiation_detected/T = new()
	var/datum/behavior_circuit/response/hazmat_warning/RE1 = new()
	var/datum/behavior_circuit/response/spray_reagent/RE2 = new()
	var/datum/behavior_circuit/response/seal_nearby_door/RE3 = new()
	T.responses_list = list(RE1, RE2, RE3)
	circuits += T
	circuits += RE1
	circuits += RE2
	circuits += RE3


// ====================================================
// PRESET: GPS ZONE GUARD PROTOCOL
// On GPS Zone -> Hold Position + Sound Alarm +
//               Enter Combat Mode
// Only activates when the robot is inside a defined
// map coordinate zone.  Requires GPS hardware.
// ====================================================

/obj/item/behavior_assembly/gps_zone_guard
	assembly_label = "GPS Zone Guard Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/gps_zone_guard/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_gps_zone/T = new()
	var/datum/behavior_circuit/response/hold_position/RE1 = new()
	var/datum/behavior_circuit/response/sound_alarm/RE2 = new()
	RE2.alarm_message = "Zone boundary breach. Lockdown active."
	var/datum/behavior_circuit/response/enter_combat_mode/RE3 = new()
	T.responses_list = list(RE1, RE2, RE3)
	circuits += T
	circuits += RE1
	circuits += RE2
	circuits += RE3


// ====================================================
// PRESET: ANNOUNCE BOT PROTOCOL
// On Interval (very slow) -> Say Vocab Phrase +
//                            Display Screen Message
// A town crier / bulletin board robot.
// Cycles through stored announcements.
// Requires Vocabulary Module + Display Screen hardware.
// ====================================================

/obj/item/behavior_assembly/announce_bot
	assembly_label = "Announce Bot Protocol"
	max_circuits = 2

/obj/item/behavior_assembly/announce_bot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_interval/T = new()
	T.interval_ticks = 800  // ~80s between announcements
	var/datum/behavior_circuit/response/say_vocab_phrase/RE1 = new()
	RE1.phrase_index = 1
	var/datum/behavior_circuit/response/display_screen/RE2 = new()
	RE2.display_text = "ANNOUNCEMENT IN PROGRESS"
	T.responses_list = list(RE1, RE2)
	circuits += T
	circuits += RE1
	circuits += RE2


// ====================================================
// PRESET: RELAY STATION PROTOCOL
// On Signal Received -> Broadcast Alert +
//                       Send Radio Signal
// A signal repeater — receives a signal on one
// frequency and rebroadcasts on its own channel.
// Chains robots across distances.
// Requires Signaler hardware.
// ====================================================

/obj/item/behavior_assembly/relay_station
	assembly_label = "Relay Station Protocol"
	max_circuits = 3

/obj/item/behavior_assembly/relay_station/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_signal_received/T = new()
	var/datum/behavior_circuit/response/broadcast_alert/RE1 = new()
	RE1.alert_message = "Signal relayed. Retransmitting."
	var/datum/behavior_circuit/response/send_radio_signal/RE2 = new()
	T.responses_list = list(RE1, RE2)
	circuits += T
	circuits += RE1
	circuits += RE2


// ====================================================
// PRESET: ALCHEMIST PROTOCOL
// On Reagent Container Nearby -> Collect Reagents
// On Interval -> Grind Item + Pump Reagent
// Automated chemistry processing bot.
// Requires Grabber Arm + Reagent Tank + Grinder Module
// + Reagent Pump hardware.  INT 7+.
// ====================================================

/obj/item/behavior_assembly/alchemist
	assembly_label = "Alchemist Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/alchemist/Initialize(mapload)
	. = ..()
	// Collect nearby reagent containers
	var/datum/behavior_circuit/trigger/on_reagent_container_nearby/T1 = new()
	T1.check_range = 3
	var/datum/behavior_circuit/response/collect_reagents/RE1 = new()
	T1.response = RE1
	circuits += T1
	circuits += RE1
	// Process loop: grind held items, pump result
	var/datum/behavior_circuit/trigger/on_interval/T2 = new()
	T2.interval_ticks = 100
	var/datum/behavior_circuit/response/grind_item/RE2 = new()
	var/datum/behavior_circuit/response/pump_reagent/RE3 = new()
	T2.responses_list = list(RE2, RE3)
	circuits += T2
	circuits += RE2
	circuits += RE3


// ====================================================
// LAYER E — CLEARING REMAINING ORPHANS
// ====================================================


// ====================================================
// PRESET: SPRINT AMBUSH PROTOCOL
// On Enemy Spotted -> Activate Sprint + Fire Weapon
// On Weapon Fired  -> Taunt Enemy
// An aggressive Assaultron that surges into range,
// fires, and trash-talks on each shot.
// Requires Weapon + Locomotion (can_sprint) hardware.
// ====================================================

/obj/item/behavior_assembly/sprint_ambush
	assembly_label = "Sprint Ambush Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/sprint_ambush/Initialize(mapload)
	. = ..()
	// Enemy spotted: burst toward them and open fire
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T1 = new()
	var/datum/behavior_circuit/response/activate_sprint/RE1 = new()
	var/datum/behavior_circuit/response/fire_weapon/RE2 = new()
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2
	// Each shot: taunt
	var/datum/behavior_circuit/trigger/on_weapon_fired/T2 = new()
	var/datum/behavior_circuit/response/taunt_enemy/RE3 = new()
	RE3.taunt_string = "Pow! That's what you get, smoothskin!"
	T2.response = RE3
	circuits += T2
	circuits += RE3


// ====================================================
// PRESET: MEDEVAC PROTOCOL
// On Health Scan Critical -> Drag Injured Ally +
//                            Pull Target
// On Low Health (own)     -> Retreat To Spawn +
//                            Broadcast Distress
// A dedicated evacuation robot.
// Best on Mr. Handy with Health Scanner hardware.
// ====================================================

/obj/item/behavior_assembly/medevac
	assembly_label = "Medevac Protocol"
	max_circuits = 5

/obj/item/behavior_assembly/medevac/Initialize(mapload)
	. = ..()
	// Critical ally nearby: drag them to safety
	var/datum/behavior_circuit/trigger/on_health_scan_critical/T1 = new()
	var/datum/behavior_circuit/response/drag_injured_ally/RE1 = new()
	var/datum/behavior_circuit/response/pull_target/RE2 = new()
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2
	// Own health critical: retreat and call for help
	var/datum/behavior_circuit/trigger/on_low_health/T2 = new()
	T2.health_threshold = 0.3
	var/datum/behavior_circuit/response/retreat_to_spawn/RE3 = new()
	var/datum/behavior_circuit/response/broadcast_distress/RE4 = new()
	T2.responses_list = list(RE3, RE4)
	circuits += T2
	circuits += RE3
	circuits += RE4


// ====================================================
// PRESET: RIOT CONTROL PROTOCOL
// On Mob Count Threshold (3+) -> Air Blast Area +
//                                Strobe Flash +
//                                Sound Alarm
// On Enemy Spotted -> Move Direction (step back) +
//                     Fire Air Cannon
// A Securitron that uses maximum non-lethal suppression.
// Requires Air Cannon hardware.
// ====================================================

/obj/item/behavior_assembly/riot_control
	assembly_label = "Riot Control Protocol"
	max_circuits = 6

/obj/item/behavior_assembly/riot_control/Initialize(mapload)
	. = ..()
	// Surrounded: area blast + strobe + alarm
	var/datum/behavior_circuit/trigger/on_mob_count_threshold/T1 = new()
	T1.threshold = 3
	var/datum/behavior_circuit/response/air_blast_area/RE1 = new()
	var/datum/behavior_circuit/response/strobe_flash/RE2 = new()
	var/datum/behavior_circuit/response/sound_alarm/RE3 = new()
	RE3.alarm_message = "DISPERSE. Use of force authorized."
	T1.responses_list = list(RE1, RE2, RE3)
	circuits += T1
	circuits += RE1
	circuits += RE2
	circuits += RE3
	// Single target: step back and blast them
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T2 = new()
	var/datum/behavior_circuit/response/move_direction/RE4 = new()
	RE4.move_dir = SOUTH  // default step-back; configure at workshop
	var/datum/behavior_circuit/response/fire_air_cannon/RE5 = new()
	T2.responses_list = list(RE4, RE5)
	circuits += T2
	circuits += RE4
	circuits += RE5


// ====================================================
// PRESET: THROWER PROTOCOL
// On Item Picked Up  -> Throw Item At Enemy
// On Grabber Empty   -> Grab Nearest Item
// A scavenger that throws whatever it finds.
// Requires Grabber Arm + Throwing Arm hardware.
// ====================================================

/obj/item/behavior_assembly/thrower_bot
	assembly_label = "Thrower Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/thrower_bot/Initialize(mapload)
	. = ..()
	// Picked something up: immediately throw it at enemy
	var/datum/behavior_circuit/trigger/on_item_picked_up/T1 = new()
	var/datum/behavior_circuit/response/throw_item_at_enemy/RE1 = new()
	T1.response = RE1
	circuits += T1
	circuits += RE1
	// Empty grabber: go collect more ammunition
	var/datum/behavior_circuit/trigger/on_grabber_empty/T2 = new()
	var/datum/behavior_circuit/response/grab_nearest_item/RE2 = new()
	T2.response = RE2
	circuits += T2
	circuits += RE2


// ====================================================
// PRESET: SUPPLY DROP PROTOCOL
// On Mob Approaches -> Offer Item + Say Text
// On Grabber Empty  -> Request Resupply
// A logistics robot that distributes held items
// to approaching friendlies and calls for restocking.
// Requires Grabber Arm hardware.
// ====================================================

/obj/item/behavior_assembly/supply_drop
	assembly_label = "Supply Drop Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/supply_drop/Initialize(mapload)
	. = ..()
	// Someone approaches: offer item
	var/datum/behavior_circuit/trigger/on_mob_approaches/T1 = new()
	T1.approach_range = 3
	T1.check_faction = TRUE  // friendlies only
	var/datum/behavior_circuit/response/offer_item/RE1 = new()
	var/datum/behavior_circuit/response/say_text/RE2 = new()
	RE2.say_string = "Resupply available. Take what you need."
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2
	// Empty grabber: call for resupply
	var/datum/behavior_circuit/trigger/on_grabber_empty/T2 = new()
	var/datum/behavior_circuit/response/request_resupply/RE3 = new()
	RE3.supply_type = "inventory items"
	RE3.urgency = "urgent"
	T2.response = RE3
	circuits += T2
	circuits += RE3


// ====================================================
// PRESET: POWER RELAY PROTOCOL
// On Interval -> Relay Power + Read Battery
// On Low Power -> Request Resupply + Broadcast Distress
// A robot that recharges other robots and reports
// its own power state.
// Requires Power Relay hardware.
// ====================================================

/obj/item/behavior_assembly/power_relay_bot
	assembly_label = "Power Relay Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/power_relay_bot/Initialize(mapload)
	. = ..()
	// Periodic: relay power to nearby robots, report own charge
	var/datum/behavior_circuit/trigger/on_interval/T1 = new()
	T1.interval_ticks = 60
	var/datum/behavior_circuit/response/relay_power/RE1 = new()
	var/datum/behavior_circuit/response/read_battery/RE2 = new()
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2
	// Own power low: call for help
	var/datum/behavior_circuit/trigger/on_low_power/T2 = new()
	var/datum/behavior_circuit/response/request_resupply/RE3 = new()
	RE3.supply_type = "power cell"
	RE3.urgency = "critical"
	var/datum/behavior_circuit/response/broadcast_distress/RE4 = new()
	T2.responses_list = list(RE3, RE4)
	circuits += T2
	circuits += RE3
	circuits += RE4


// ====================================================
// PRESET: COLLECTION SWEEP PROTOCOL
// On Item Spotted    -> Collect Nearby Items +
//                       Play Sound (confirm beep)
// On Grabber Full    -> Drop All Items + Report Position
// A mining/salvage sweep bot.
// Requires Material Collector + Grabber hardware.
// ====================================================

/obj/item/behavior_assembly/collection_sweep
	assembly_label = "Collection Sweep Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/collection_sweep/Initialize(mapload)
	. = ..()
	// Item spotted: collect and confirm
	var/datum/behavior_circuit/trigger/on_item_spotted/T1 = new()
	var/datum/behavior_circuit/response/collect_items/RE1 = new()
	var/datum/behavior_circuit/response/play_sound/RE2 = new()
	RE2.sound_file = 'sound/machines/ping.ogg'
	RE2.sound_volume = 30
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2
	// Full: dump payload and report
	var/datum/behavior_circuit/trigger/on_grabber_full/T2 = new()
	var/datum/behavior_circuit/response/drop_all_items/RE3 = new()
	var/datum/behavior_circuit/response/report_position/RE4 = new()
	RE4.position_prefix = "Payload deposited"
	T2.responses_list = list(RE3, RE4)
	circuits += T2
	circuits += RE3
	circuits += RE4


// ====================================================
// PRESET: WATCHPOST PROTOCOL
// On Spoken To Directly -> Say Text (respond) +
//                          Report Position
// On Body Detected      -> Sound Alarm +
//                          Broadcast Distress +
//                          Play Sound
// On Memory Flag Cleared("alert") -> Say Text +
//                                    Release Position
// A guard bot that responds when addressed, alarms
// on casualties, and stands down when alert clears.
// Requires Microphone + Environment Scanner hardware.
// ====================================================

/obj/item/behavior_assembly/watchpost
	assembly_label = "Watchpost Protocol"
	max_circuits = 7

/obj/item/behavior_assembly/watchpost/Initialize(mapload)
	. = ..()
	// Spoken to: acknowledge and report position
	var/datum/behavior_circuit/trigger/on_spoken_to/T1 = new()
	var/datum/behavior_circuit/response/say_text/RE1 = new()
	RE1.say_string = "Watchpost operational. All clear."
	var/datum/behavior_circuit/response/report_position/RE2 = new()
	RE2.position_prefix = "Watchpost position"
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2
	// Body detected: alert!
	var/datum/behavior_circuit/trigger/on_body_detected/T2 = new()
	var/datum/behavior_circuit/response/sound_alarm/RE3 = new()
	RE3.alarm_message = "CASUALTY DETECTED. All units respond."
	var/datum/behavior_circuit/response/broadcast_distress/RE4 = new()
	var/datum/behavior_circuit/response/play_sound/RE5 = new()
	RE5.sound_file = 'sound/machines/alarm.ogg'
	RE5.sound_volume = 80
	var/datum/behavior_circuit/response/set_memory_flag/RE6 = new()
	RE6.flag_key = "alert"
	RE6.flag_value = "1"
	T2.responses_list = list(RE3, RE4, RE5, RE6)
	circuits += T2
	circuits += RE3
	circuits += RE4
	circuits += RE5
	circuits += RE6
	// Alert cleared: stand down
	var/datum/behavior_circuit/trigger/on_memory_flag_cleared/T3 = new()
	T3.flag_key = "alert"
	var/datum/behavior_circuit/response/say_text/RE7 = new()
	RE7.say_string = "Alert cleared. Resuming normal operations."
	var/datum/behavior_circuit/response/release_position/RE8 = new()
	T3.responses_list = list(RE7, RE8)
	circuits += T3
	circuits += RE7
	circuits += RE8


// ====================================================
// PRESET: ONE-SHOT ANNOUNCEMENT PROTOCOL
// On Mob Approaches (once ever) ->
//   Say Text + Play Sound + One-Shot Lockout
// Fires once and never again — a robot with a single
// thing to say.  The tutorial demonstration for
// one_shot_lockout.  No hardware required.
// ====================================================

/obj/item/behavior_assembly/one_shot_announcement
	assembly_label = "One-Shot Announcement"
	max_circuits = 4

/obj/item/behavior_assembly/one_shot_announcement/Initialize(mapload)
	. = ..()
	// Check lockout first — if "fired" flag set, memory gate blocks this
	// (wire a second assembly with On Memory Flag -> do nothing to fully suppress)
	var/datum/behavior_circuit/trigger/on_mob_approaches/T = new()
	T.approach_range = 5
	T.check_faction = FALSE
	var/datum/behavior_circuit/response/say_text/RE1 = new()
	RE1.say_string = "Welcome. This message will not repeat."
	var/datum/behavior_circuit/response/play_sound/RE2 = new()
	RE2.sound_file = 'sound/machines/chime.ogg'
	RE2.sound_volume = 60
	var/datum/behavior_circuit/response/one_shot_lockout/RE3 = new()
	RE3.lockout_key = "fired"
	T.responses_list = list(RE1, RE2, RE3)
	circuits += T
	circuits += RE1
	circuits += RE2
	circuits += RE3


// ====================================================
// PRESET: PUMP STATION PROTOCOL
// On Interval -> Pump Reagents (push to containers) +
//               Broadcast Counter Status
// Tracks how many pump cycles have run and reports.
// Requires Reagent Pump hardware + Memory Core.
// ====================================================

/obj/item/behavior_assembly/pump_station
	assembly_label = "Pump Station Protocol"
	max_circuits = 4

/obj/item/behavior_assembly/pump_station/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_interval/T = new()
	T.interval_ticks = 120
	var/datum/behavior_circuit/response/pump_reagents/RE1 = new()
	var/datum/behavior_circuit/response/increment_counter/RE2 = new()
	RE2.counter_key = "cycles"
	var/datum/behavior_circuit/response/broadcast_counter/RE3 = new()
	RE3.counter_key = "cycles"
	RE3.counter_prefix = "Pump cycles completed"
	T.responses_list = list(RE1, RE2, RE3)
	circuits += T
	circuits += RE1
	circuits += RE2
	circuits += RE3


// ====================================================
// PRESET: DOOR PATROL PROTOCOL
// On Interval (slow) -> Open Nearby Door +
//                       Move Direction (step through) +
//                       Seal Nearby Door (close behind)
// A robot that patrols by moving through doorways
// and closing them behind itself.
// No hardware required.
// ====================================================

/obj/item/behavior_assembly/door_patrol
	assembly_label = "Door Patrol Protocol"
	max_circuits = 3

/obj/item/behavior_assembly/door_patrol/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_interval/T = new()
	T.interval_ticks = 150
	var/datum/behavior_circuit/response/open_nearby_door/RE1 = new()
	var/datum/behavior_circuit/response/move_direction/RE2 = new()
	RE2.move_dir = NORTH  // configure at workshop to match patrol direction
	var/datum/behavior_circuit/response/seal_nearby_door/RE3 = new()
	T.responses_list = list(RE1, RE2, RE3)
	circuits += T
	circuits += RE1
	circuits += RE2
	circuits += RE3
