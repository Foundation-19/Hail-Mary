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
#define HW_SLOT_GAS_PUMP         "/datum/robot_hardware/gas_pump"
#define HW_SLOT_HARVESTER        "/datum/robot_hardware/harvester"
#define HW_SLOT_MATERIAL_COLLECTOR "/datum/robot_hardware/material_collector"
#define HW_SLOT_GRINDER          "/datum/robot_hardware/grinder_module"
#define HW_SLOT_GAS_VENT         "/datum/robot_hardware/gas_vent"
#define HW_SLOT_BIO_SCANNER      "/datum/robot_hardware/bio_scanner"
#define HW_SLOT_OBJECT_LOCATOR   "/datum/robot_hardware/object_locator"
#define HW_SLOT_POWER_RELAY      "/datum/robot_hardware/power_relay"
#define HW_SLOT_NAV_COMPUTER     "/datum/robot_hardware/nav_computer"
#define HW_SLOT_VOCABULARY       "/datum/robot_hardware/vocabulary_module"
#define HW_SLOT_PIPE_INTERFACE   "/datum/robot_hardware/pipe_interface"


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
	var/datum/behavior_circuit/response/response = null

/datum/behavior_circuit/trigger/proc/_trigger(mob/living/silicon/robot/R)
	// Skip autonomous behavior for player-controlled robots UNLESS assembly_override is set.
	// assembly_override is set by robot_workshop so assemblies always run on workshop-built bots.
	if(R.mind && R.client)
		var/assembly_active = FALSE
		for(var/datum/cert_upgrade/robot/behavior_assembly/U in R.cpu_cert?.upgrade_slots)
			if(U.assembly?.assembly_override)
				assembly_active = TRUE
				break
		if(!assembly_active)
			return
	if(response)
		response.execute(R, get_assembly())


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


// ====================================================
// TRIGGER CIRCUITS
// ====================================================


// -- ON TAKE DAMAGE ----------------------------------

/datum/behavior_circuit/trigger/on_take_damage
	circuit_name = "Trigger: On Take Damage"
	circuit_desc = "Fires when the robot takes significant damage."
	tutorial_text = "Fires when the robot takes a hit above the damage threshold. Configure 'damage_threshold' (default 10). Good for: distress calls, self-repair triggers, retreat behavior, or retaliation responses."
	cpu_cost = 1
	var/damage_threshold = 10
	var/last_health = -1

/datum/behavior_circuit/trigger/on_take_damage/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	last_health = R.health
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_take_damage/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_take_damage/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/delta = last_health - R.health
	last_health = R.health
	if(delta >= damage_threshold)
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
		if(R.faction_check_mob(M, FALSE))
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
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_death/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_death/process()
	if(already_fired)
		STOP_PROCESSING(SSobj, src)
		return
	var/mob/living/silicon/robot/R = get_robot()
	if(!R)
		STOP_PROCESSING(SSobj, src)
		return
	if(R.stat == DEAD)
		already_fired = TRUE
		_trigger(R)
		STOP_PROCESSING(SSobj, src)


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
	tutorial_text = "Fires when any living mob (friend or foe) enters proximity. Good for: greeting visitors, offering items, sounding an alarm. For enemy-only detection use On Enemy Spotted instead."
	cpu_cost = 2
	var/last_check = 0
	var/check_cooldown = 30
	var/approach_range = 3

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
		if(M == R || M.stat == DEAD)
			continue
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
		if(H.thirst < THIRST_LEVEL_THIRSTY)
			_trigger(R)
			return


// -- ON MOB INJURED ----------------------------------

/datum/behavior_circuit/trigger/on_mob_injured
	circuit_name = "Trigger: Mob Injured Nearby"
	circuit_desc = "Fires when a friendly mob below a health threshold is in range."
	tutorial_text = "Fires when a friendly mob (same faction) is below the health threshold in sensor range. Configure 'health_threshold' (default 50). Pair with: Inject Reagent, Self Repair Pulse, or Follow Linked Target."
	cpu_cost = 2
	var/last_check = 0
	var/check_cooldown = 50
	var/health_threshold = 50

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
		if(!R.faction_check_mob(M, FALSE))  // skip enemies
			continue
		if(M.health < health_threshold)
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
	var/in_night = (t >= night_start || t < night_end)
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
	for(var/turf/T in range(3, R))
		// Check for blood decals (footprints, splatter, puddles)
		for(var/obj/effect/decal/cleanable/blood/B in T.contents)
			_trigger(R)
			return
		// Check for general cleanable mess
		for(var/obj/effect/decal/cleanable/C in T.contents)
			_trigger(R)
			return
		// Check for reagent spills
		if(T.reagents && T.reagents.total_volume > 0)
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
	circuit_name = "Trigger: On Weapon Fired"
	hardware_slot_name = HW_SLOT_WEAPON
	required_hardware_type = /datum/robot_hardware/weapon
	circuit_desc = "Fires each time the robot's weapon fires."
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

/datum/behavior_circuit/trigger/on_atmos_threshold
	needs_hardware = TRUE
	circuit_name = "Trigger: On Atmos Threshold"
	hardware_slot_name = HW_SLOT_ENV_SCANNER
	required_hardware_type = /datum/robot_hardware/environment_scanner
	circuit_desc = "Fires when atmospheric pressure or O2 drops below safe levels."
	tutorial_text = "HARDWARE REQUIRED: Environment Scanner. Fires when local pressure or O2 drops below safe levels. Good for: emergency response robots, breach detection, warning survivors. Pair with Broadcast Alert or Deploy Smoke."
	cpu_cost = 2
	var/pressure_min = 60
	var/o2_min = 16
	var/last_check = 0
	var/check_cooldown = 30

/datum/behavior_circuit/trigger/on_atmos_threshold/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_atmos_threshold/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_atmos_threshold/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return
	var/datum/robot_hardware/environment_scanner/ENV = get_hardware(R, /datum/robot_hardware/environment_scanner)
	if(!ENV)
		return
	// Sample atmosphere - check if area is unsafe (space, breached)
	// without accessing turf.air which is not directly accessible.
	var/turf/here = get_turf(R)
	if(!here)
		return
	var/area/A = get_area(here)
	if(!A)
		return
	// Treat space tiles and area with fire/breaches as threshold-triggered
	if(istype(here, /turf/open/space))
		_trigger(R)
		return
	for(var/obj/effect/hotspot/HS in range(3, R))
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
	if(R.radio)
		R.radio.talk_into(R, alert_message, R.radio.frequency, null, null)
	else
		R.say(alert_message)


// -- BROADCAST DISTRESS ------------------------------

/datum/behavior_circuit/response/broadcast_distress
	circuit_name = "Response: Broadcast Distress Signal"
	circuit_desc = "Broadcasts a distress call including current location."
	tutorial_text = "Broadcasts a distress call that includes the robot's current location. No configuration needed. Good for: damage events, low health, or being attacked."
	cpu_cost = 1

/datum/behavior_circuit/response/broadcast_distress/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/area/here = get_area(R)
	var/loc = here ? here.name : "unknown location"
	var/msg = "[R.name] is under attack at [loc]! Requesting immediate assistance!"
	if(R.radio)
		R.radio.talk_into(R, msg, R.radio.frequency, null, null)
	else
		R.say(msg)


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
	tutorial_text = "The robot heals itself for a small amount. No hardware required. Configure 'repair_amount' (default 15). Higher values drain the cell faster. Pair with On Take Damage."
	cpu_cost = 2
	var/repair_amount = 15

/datum/behavior_circuit/response/self_repair_pulse/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.stat == DEAD)
		return
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
		if(R.faction_check_mob(M, FALSE))
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
	var/mob/living/target = linked_target_ref?.resolve()
	if(!target || target.stat == DEAD || QDELETED(target))
		// No linked target - announce waiting state once
		return
	step_towards(R, target)
	R.setDir(get_dir(R, target))

/// Called by multitool linkage - sets the follow target
/datum/behavior_circuit/response/follow_target/proc/set_linked_target(mob/living/new_target, mob/user)
	linked_target_ref = WEAKREF(new_target)
	linked_target_name = new_target.name
	if(user)
		to_chat(user, span_notice("Follow target linked: [new_target.name]."))


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
		if(R.faction_check_mob(M, FALSE))
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
	tutorial_text = "HARDWARE REQUIRED: Weapon hardware datum. Fires the weapon at the nearest hostile in sensor range. Does nothing if no enemy is in range. Pair with On Enemy Spotted for a complete auto-turret."
	cpu_cost = 3

/datum/behavior_circuit/response/fire_weapon/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
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
	// Delegate to the hardware datum's fire proc
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
	var/scan_range = A ? A.sensor_range : 7
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
	// Throw the target with configured knockback
	var/turf/here = get_turf(R)
	var/throw_dir = get_dir(here, get_turf(target))
	target.throw_at(get_step(get_turf(target), throw_dir), AC.knockback_force, 1, R)
	R.visible_message(span_warning("[R] fires a burst of compressed air at [target]!"))


// -- DETONATE SELF -----------------------------------

/datum/behavior_circuit/response/detonate_self
	circuit_name = "Response: Detonate Self"
	circuit_desc = "Triggers a self-destruct explosion after a short delay."
	tutorial_text = "The robot announces its detonation then explodes after 3 seconds. Any robot can self-destruct if programmed to. Pair with On Death for a deadman switch or On Enemy Spotted for a suicide build. No hardware required."
	cpu_cost = 2

/datum/behavior_circuit/response/detonate_self/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	R.visible_message(span_danger("[R] begins emitting a high-pitched whine!"))
	playsound(R, 'sound/machines/alarm.ogg', 75, 1)
	addtimer(CALLBACK(src, PROC_REF(_boom), R), 10, TIMER_UNIQUE|TIMER_OVERRIDE)

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
	var/scan_range = A ? A.sensor_range : 5
	var/mob/living/target = null
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(R.faction_check_mob(M, FALSE))
			continue
		target = M
		break
	if(!target)
		return
	// Spawn and throw the grenade
	var/obj/item/grenade/G = new GL.grenade_type(get_turf(R))
	G.throw_at(target, 7, 1, R)
	addtimer(CALLBACK(G, TYPE_PROC_REF(/obj/item/grenade, prime)), 30)
	R.visible_message(span_danger("[R] launches a grenade at [target]!"))


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
		if(R.faction_check_mob(M, FALSE))
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
		if(target_friendly && !R.faction_check_mob(M, FALSE))
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
		if(H.thirst < THIRST_LEVEL_THIRSTY)
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
	var/scan_range = A ? A.sensor_range : 3
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(R.faction_check_mob(M, FALSE))
			continue
		M.Stun(stun_duration)
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
	smoke.set_up(smoke_range, 0, R)
	smoke.start()


// -- FIRE EXTINGUISHER -------------------------------

/datum/behavior_circuit/response/fire_extinguisher
	needs_hardware = TRUE
	circuit_name = "Response: Extinguish Fire"
	hardware_slot_name = HW_SLOT_GAS_PUMP
	required_hardware_type = /datum/robot_hardware/gas_pump
	circuit_desc = "Sprays CO2 at nearby fire tiles. Requires Gas Pump hardware."
	tutorial_text = "HARDWARE REQUIRED: Gas Pump hardware datum (CO2 extinguisher config). Scans nearby turfs for fire and suppresses it. For firefighting robots."
	cpu_cost = 2

/datum/behavior_circuit/response/fire_extinguisher/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/gas_pump/GP = get_hardware(R, /datum/robot_hardware/gas_pump)
	if(!GP)
		return
	var/scan_range = A ? A.sensor_range : 3
	for(var/turf/T in range(scan_range, R))
		if(locate(/obj/effect/hotspot) in T)
			T.hotspot_expose(-100, 100)
			R.visible_message(span_notice("[R] vents gas at the fire!"))
			return


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
		R.set_light(LT.light_brightness, 1, LT.light_color)
	else
		R.set_light(0)


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
		if(!R.faction_check_mob(M, FALSE))
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
	// Use the tray's own attack_hand proc to trigger harvesting logic
	for(var/obj/machinery/hydroponics/tray in range(HV.harvest_range, R))
		tray.attack_hand(R)
		R.visible_message(span_notice("[R] tends a hydroponic tray."))
		return


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
		if(!is_type_in_list(I, MC.target_types))
			continue
		if(GR && GR.held_items.len >= GR.max_items)
			continue
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

/datum/behavior_circuit/response/vent_gas
	needs_hardware = TRUE
	circuit_name = "Response: Vent Gas"
	hardware_slot_name = HW_SLOT_GAS_VENT
	required_hardware_type = /datum/robot_hardware/gas_vent
	circuit_desc = "Releases gas from internal reserves. Requires Gas Vent hardware."
	tutorial_text = "HARDWARE REQUIRED: Gas Vent. Releases a burst of gas from the robot's internal reservoir into the surrounding area. Configure vent_radius and vent_amount on the hardware datum. Can be used for smoke screens, gas deployment, or atmoshperic equalization."
	cpu_cost = 2

/datum/behavior_circuit/response/vent_gas/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/gas_vent/GV = get_hardware(R, /datum/robot_hardware/gas_vent)
	if(!GV)
		return
	// Use the smoke system as a safe visual proxy for gas venting.
	// True atmospheric injection requires knowing the codebase's gas_mixture API,
	// which varies. Replace with adjust_moles() calls if atmos procs are available.
	var/datum/effect_system/smoke_spread/smoke = new()
	smoke.set_up(GV.vent_radius, 0, R)
	smoke.start()
	R.visible_message(span_warning("[R] vents [GV.gas_type] gas!"))


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
	for(var/mob/living/carbon/M in range(BS.scan_radius, R))
		if(M == R || M.stat == DEAD)
			continue
		// Filter by species name if configured
		if(BS.target_species)
			var/species_name = M.dna?.species
			if(species_name && species_name != BS.target_species)
				continue
		// Trigger on non-human carbon mobs
		if(!istype(M, /mob/living/carbon/human))
			last_detected = world.time
			_trigger(R)
			return
		// Or humans with active DNA mutations
		var/mob/living/carbon/human/H = M
		if(H.dna && H.dna.uni_identity)
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
		R.say("BIO REPORT: [M.name] -- [M.real_name ? M.real_name : "unknown"] -- [health_state]")
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

/datum/behavior_circuit/trigger/on_pipe_connected
	needs_hardware = TRUE
	circuit_name = "Trigger: On Pipe Connected"
	hardware_slot_name = HW_SLOT_PIPE_INTERFACE
	required_hardware_type = /datum/robot_hardware/pipe_interface
	circuit_desc = "Fires when the robot is standing on a pipe connector. Requires Pipe Interface hardware."
	tutorial_text = "HARDWARE REQUIRED: Pipe Interface. Fires when the robot is standing on a floor pipe connector. Use this to trigger gas or reagent exchange. Good for maintenance or chemical distribution bots that dock at fixed stations."
	cpu_cost = 1
	var/last_check = 0

/datum/behavior_circuit/trigger/on_pipe_connected/process()
	if(world.time < last_check + 10)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		return
	var/datum/robot_hardware/pipe_interface/PIPE_HW = get_hardware(R, /datum/robot_hardware/pipe_interface)
	if(!PIPE_HW)
		return
	var/turf/T = get_turf(R)
	for(var/obj/machinery/atmospherics/components/unary/portables_connector/connector in T)
		if(connector.connected_device)
			_trigger(R)
			return

/datum/behavior_circuit/response/exchange_with_pipe
	needs_hardware = TRUE
	circuit_name = "Response: Exchange With Pipe"
	hardware_slot_name = HW_SLOT_PIPE_INTERFACE
	required_hardware_type = /datum/robot_hardware/pipe_interface
	circuit_desc = "Exchanges gas or reagents with a floor pipe connector. Requires Pipe Interface hardware."
	tutorial_text = "HARDWARE REQUIRED: Pipe Interface. Exchanges gas or reagents with the pipe connector at the robot's current turf. Set exchange_mode to 'gas' or 'reagent' and configure exchange_rate on the hardware datum."
	cpu_cost = 2

/datum/behavior_circuit/response/exchange_with_pipe/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/datum/robot_hardware/pipe_interface/PIPE_HW = get_hardware(R, /datum/robot_hardware/pipe_interface)
	if(!PIPE_HW)
		return
	var/turf/T = get_turf(R)
	for(var/obj/machinery/atmospherics/components/unary/portables_connector/connector in T)
		if(!connector.connected_device)
			continue
		// Gas exchange: stub - wire up to your codebase's tank/atmos API
		if(PIPE_HW.exchange_mode == "reagent" && R.reagents && connector.connected_device && connector.connected_device.reagents)
			R.reagents.trans_to(connector.connected_device, PIPE_HW.exchange_rate)
			R.visible_message(span_notice("[R] pumps reagents into the pipe connector."))
		else
			R.visible_message(span_notice("[R] docks with the pipe connector."))
		return


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
