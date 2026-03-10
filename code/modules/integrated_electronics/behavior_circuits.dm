// ====================================================
// HARDWARE SLOT DEFINES
// These are defined here so behavior_circuits.dm can use
// them for hardware_slot_name assignments without depending
// on robot_workshop.dm being compiled first.
// robot_workshop.dm also defines these - DM will warn on
// duplicate #defines but the values are identical.
// ====================================================

#define HW_SLOT_WEAPON           "/datum/robot_hardware/weapon"
#define HW_SLOT_AIR_CANNON       "/datum/robot_hardware/air_cannon"
#define HW_SLOT_GRENADE          "/datum/robot_hardware/grenade_launcher"
#define HW_SLOT_THROWER          "/datum/robot_hardware/thrower"
#define HW_SLOT_GRABBER          "/datum/robot_hardware/grabber"
#define HW_SLOT_INJECTOR         "/datum/robot_hardware/injector"
#define HW_SLOT_REAGENT_PUMP     "/datum/robot_hardware/reagent_pump"
#define HW_SLOT_SIGNALER         "/datum/robot_hardware/signaler"
#define HW_SLOT_DISPLAY          "/datum/robot_hardware/display_screen"
#define HW_SLOT_ID_READER        "/datum/robot_hardware/id_reader"
#define HW_SLOT_MICROPHONE       "/datum/robot_hardware/microphone"
#define HW_SLOT_GPS              "/datum/robot_hardware/gps"
#define HW_SLOT_ENV_SCANNER      "/datum/robot_hardware/environment_scanner"
#define HW_SLOT_HEALTH_SCANNER   "/datum/robot_hardware/health_scanner"
#define HW_SLOT_LIGHT            "/datum/robot_hardware/light"
#define HW_SLOT_CHEM_SPRAYER     "/datum/robot_hardware/chem_sprayer"
#define HW_SLOT_HARVESTER        "/datum/robot_hardware/harvester"
#define HW_SLOT_MATERIAL_COLLECTOR "/datum/robot_hardware/material_collector"
#define HW_SLOT_GRINDER          "/datum/robot_hardware/grinder_module"

#define HW_SLOT_BIO_SCANNER      "/datum/robot_hardware/bio_scanner"
#define HW_SLOT_OBJECT_LOCATOR   "/datum/robot_hardware/object_locator"
#define HW_SLOT_POWER_RELAY      "/datum/robot_hardware/power_relay"
#define HW_SLOT_NAV_COMPUTER     "/datum/robot_hardware/nav_computer"
#define HW_SLOT_VOCABULARY       "/datum/robot_hardware/vocabulary_module"

#define ROBOT_COMBAT_MELEE  1   // Always close in
#define ROBOT_COMBAT_RANGED 2   // Stay at retreat_distance, back off if closer
#define ROBOT_COMBAT_MIXED  3   // Prefer range, switch to melee if rushed

#define HW_SLOT_CLOCK            "/datum/robot_hardware/clock"
#define HW_SLOT_MEMORY           "/datum/robot_hardware/memory_core"


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
	tutorial_text = "Stuns the nearest enemy. No hardware required -- the robot delivers the pulse directly from its chassis. Configure 'stun_duration' in deciseconds (default 20 = 2 seconds). Good for security robots that need to incapacitate without killing."
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
	circuit_name = "Response: Extinguish Fire"
	circuit_desc = "Uses the robot's extinguisher on a nearby mob that is on fire."
	tutorial_text = "The robot finds the nearest mob on fire in range and uses its installed extinguisher on them. Pair with Trigger: On Interval or On Enemy Spotted. No special hardware required beyond an extinguisher in the module loadout."
	cpu_cost = 2

/datum/behavior_circuit/response/fire_extinguisher/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	// Find an extinguisher in the robot's module inventory
	var/obj/item/extinguisher/EX = null
	if(R.module)
		for(var/obj/item/extinguisher/E in R.module.modules)
			EX = E
			break
	if(!EX)
		return
	// Find the nearest mob on fire within sensor range
	var/scan_range = A ? A.sensor_range : 5
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
	// Step adjacent if needed
	if(get_dist(R, target) > 1)
		step_towards(R, target)
		return
	EX.attack(target, R)
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
			R.reagents.trans_to(RC, RP.transfer_amount)
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
	tutorial_text = "The robot finds the nearest reagent container in range and transfers its contents into the robot's reagent tank. Pair with Trigger: On Reagent Container Nearby or On Interval. Requires Reagent Tank hardware."
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
		if(R.faction_check_mob(M, FALSE))
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

/obj/item/behavior_assembly/scavenger_bot/cert_compatible(datum/cpu_cert/C)
	return C && (C.capability_flags & CERT_CAN_INTERFACE)

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

/obj/item/behavior_assembly/hunter/Initialize(mapload)
	. = ..()
	// On Enemy Spotted -> Remember Last Enemy + Fire Weapon (one trigger, two responses)
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T1 = new()
	var/datum/behavior_circuit/response/remember_enemy/RE1 = new()
	var/datum/behavior_circuit/response/fire_weapon/RE2 = new()
	T1.responses_list = list(RE1, RE2)
	circuits += T1
	circuits += RE1
	circuits += RE2
	// On Remembered Enemy -> Pathfind (persistent chase after losing sight)
	var/datum/behavior_circuit/trigger/on_remembered_enemy/T3 = new()
	var/datum/behavior_circuit/response/pathfind_to_enemy/RE3 = new()
	T3.response = RE3
	circuits += T3
	circuits += RE3

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
