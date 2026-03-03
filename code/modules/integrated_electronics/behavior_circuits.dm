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


// -- TRIGGER BASE --------------------------------------------

/datum/behavior_circuit/trigger
	var/datum/behavior_circuit/response/response = null

/datum/behavior_circuit/trigger/proc/_trigger(mob/living/silicon/robot/R)
	// Behavior assemblies do not override player-controlled robots.
	// If the robot has a live player mind in control, skip autonomous responses.
	if(R.mind && R.client)
		return
	if(response)
		response.execute(R, get_assembly())


// -- RESPONSE BASE -------------------------------------------

/datum/behavior_circuit/response/proc/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	return


// ====================================================
// TRIGGER CIRCUITS
// ====================================================


// -- ON TAKE DAMAGE ----------------------------------

/datum/behavior_circuit/trigger/on_take_damage
	circuit_name = "Trigger: On Take Damage"
	circuit_desc = "Fires when the robot takes significant damage."
	tutorial_text = "This trigger watches your robot's health every tick. When damage received in one tick exceeds the threshold, it fires the linked response. Works on both player and NPC robots. Good for: distress calls, self-repair, fleeing, or retaliation."
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
	tutorial_text = "Monitors the robot's power cell ratio. Fires once per low-power event (resets when power is restored). The threshold is 0.0-1.0 where 0.2 = 20% charge. Great for: warning broadcasts, retreating to a charger, entering low-power mode."
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
	tutorial_text = "Scans the area around the robot every 5 seconds. If any mob that is not in the robot's faction is found within sensor range, it fires. Sensor range is set by the builder's Perception stat at print time. Best paired with: Enter Combat Mode, Pathfind To Enemy, Fire Weapon, Broadcast Alert."
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
	tutorial_text = "Polls the robot's stat each tick and fires exactly once when it transitions to DEAD. Perfect for death-triggered behaviors: distress beacons, explosions, drop all items, or a parting message."
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
	tutorial_text = "The simplest trigger: just fires every N ticks (10 ticks = 1 second). Use it for ambient behaviors: periodic announcements, regular status checks, patrol loops, or heartbeat signals. Configure 'interval_ticks' to set how often."
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
	tutorial_text = "Companion to On Low Power. Fires once when the cell recovers above the threshold. Good for: announcing readiness, resuming patrol, or broadcasting a status update after recharging."
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
	tutorial_text = "Broad-spectrum proximity sensor. Fires when ANY living mob (friend or foe) steps within range. Good for service robots: greeting visitors, offering items, sounding an alarm. For enemy-only detection use On Enemy Spotted instead."
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
	tutorial_text = "For service robots only. Scans for humans below THIRST_LEVEL_THIRSTY in range. Used by Drink-Bot builds. Requires a borghypo or dispenser in the robot's module to actually deliver the drink. Pair with: Offer Drink response."
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
	tutorial_text = "Scans for friendly mobs (same faction) below the health threshold. Designed for combat medic and field surgeon builds. Pair with: Inject Reagent, Self Repair Pulse, Follow Friendly. The threshold is a raw health value - default 50 = below half health on most mobs."
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
	tutorial_text = "Fires once per in-game night period. Good for patrol robots that should behave differently after dark, lighting systems, or security bots that activate at night. Uses world.time - configure night_start and night_end in ticks."
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
	tutorial_text = "Janitor trigger. Checks nearby turfs for blood decals (footprints, puddles, splatter) and reagent spills. When contamination is detected it fires. Use with the Emote Action response to make the bot announce it found a mess, or pair it with cleaning module ICs. Triggers on blood footprints left by wounded humans."
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
	circuit_desc = "Fires when an ID scan by the robot succeeds."
	tutorial_text = "For door-guard or escort robots. Polls the robot's ID scanner IC for a successful read. When an ID with valid access is scanned it fires. Pair with: Say Text (greeting), Follow Friendly (escort), or Toggle Light (open a door via the IC chain)."
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
	if(!R || R.stat == DEAD || !R.module)
		return
	for(var/obj/item/integrated_circuit/input/ID in R.module.modules)
		var/t = ID.get_pin_data(IC_OUTPUT, 3)  // output 3 = last scan time
		if(t && t != last_scan_time)
			last_scan_time = t
			_trigger(R)
			return


// -- ON SPEECH HEARD ---------------------------------

/datum/behavior_circuit/trigger/on_speech_heard
	needs_hardware = TRUE
	circuit_name = "Trigger: On Speech Heard"
	circuit_desc = "Fires when the robot's microphone picks up speech."
	tutorial_text = "Requires a microphone IC in the robot's module. Reads the IC's output pins for new messages. Fires when new speech is detected that differs from the last heard message. Good for companion robots that respond to being spoken to, or alarms that trigger on voices."
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
	if(!R || R.stat == DEAD || !R.module)
		return
	for(var/obj/item/integrated_circuit/input/microphone/M in R.module.modules)
		var/msg = M.get_pin_data(IC_OUTPUT, 2)
		if(msg && msg != last_message)
			last_message = msg
			last_heard = world.time
			_trigger(R)
			return


// -- ON WEAPON FIRED ---------------------------------

/datum/behavior_circuit/trigger/on_weapon_fired
	needs_hardware = TRUE
	circuit_name = "Trigger: On Weapon Fired"
	circuit_desc = "Fires each time the robot's weapon IC is activated."
	tutorial_text = "Polls the weapon_firing IC for fire events. Useful for: logging shots, playing sound effects on fire, auto-reloading behavior, or triggering a secondary action after each shot. Requires a weapon_firing IC in the robot's module."
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
	if(!R || R.stat == DEAD || !R.module)
		return
	for(var/obj/item/integrated_circuit/weaponized/weapon_firing/WF in R.module.modules)
		var/t = WF.get_pin_data(IC_OUTPUT, 1)  // last fire timestamp
		if(t && t != last_shot)
			last_shot = t
			_trigger(R)
			return


// -- ON SIGNAL RECEIVED ------------------------------

/datum/behavior_circuit/trigger/on_signal_received
	needs_hardware = TRUE
	circuit_name = "Trigger: On Signal Received"
	circuit_desc = "Fires when a radio signal is received on the robot's signaler IC."
	tutorial_text = "Requires a signaler IC in the robot's module. When the signaler detects a matching radio signal, this trigger fires. Good for remotely commanded robots - you send a signal, the robot executes its response. Works best with Say Text or Enter Combat Mode responses."
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
	if(!R || R.stat == DEAD || !R.module)
		return
	for(var/obj/item/integrated_circuit/input/signaler/S in R.module.modules)
		var/t = S.get_pin_data(IC_OUTPUT, 1)
		if(t && world.time > last_received + signal_cooldown)
			last_received = world.time
			_trigger(R)
			return


// -- ON GPS ZONE -------------------------------------

/datum/behavior_circuit/trigger/on_gps_zone
	needs_hardware = TRUE
	circuit_name = "Trigger: On GPS Zone"
	circuit_desc = "Fires when the robot is within defined map coordinates."
	tutorial_text = "Requires a GPS IC in the robot's module. Define a rectangular zone by coordinates. When the robot is inside that box, it fires. Great for patrol waypoint robots: chain multiple assemblies with GPS zones to create a route. Configure zone_x1/y1/x2/y2."
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
	if(!R || R.stat == DEAD || !R.module)
		return
	for(var/obj/item/integrated_circuit/input/gps/G in R.module.modules)
		var/gx = G.get_pin_data(IC_OUTPUT, 1)
		var/gy = G.get_pin_data(IC_OUTPUT, 2)
		if(!gx || !gy)
			return
		var/now_in = (gx >= zone_x1 && gx <= zone_x2 && gy >= zone_y1 && gy <= zone_y2)
		if(now_in && !in_zone)
			in_zone = TRUE
			_trigger(R)
		else if(!now_in)
			in_zone = FALSE
		return


// -- ON ATMOS THRESHOLD ------------------------------

/datum/behavior_circuit/trigger/on_atmos_threshold
	needs_hardware = TRUE
	circuit_name = "Trigger: On Atmos Threshold"
	circuit_desc = "Fires when atmospheric pressure or O2 drops below safe levels."
	tutorial_text = "Requires an atmospherics IC in the robot's module. Monitors local atmosphere and fires when pressure or O2 falls below the thresholds. Ideal for emergency response robots that seal breaches or warn survivors. Pair with Broadcast Alert or Deploy Smoke."
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
	if(!R || R.stat == DEAD || !R.module)
		return
	for(var/obj/item/integrated_circuit/atmospherics/AT in R.module.modules)
		var/pressure = AT.get_pin_data(IC_OUTPUT, 1)
		var/o2 = AT.get_pin_data(IC_OUTPUT, 2)
		if((pressure && pressure < pressure_min) || (o2 && o2 < o2_min))
			_trigger(R)
		return


// -- ON HEALTH SCAN CRITICAL -------------------------

/datum/behavior_circuit/trigger/on_health_scan_critical
	needs_hardware = TRUE
	circuit_name = "Trigger: Health Scan Critical"
	circuit_desc = "Fires when the robot's health scanner detects a critically injured mob."
	tutorial_text = "Requires a health scanner IC. Scans for mobs whose total damage exceeds the critical threshold. More precise than On Mob Injured because it uses the scanner IC reading rather than raw health. Perfect for medic robots. Pair with Inject Reagent or Say Text."
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
	if(!R || R.stat == DEAD || !R.module)
		return
	var/obj/item/behavior_assembly/A = get_assembly()
	var/scan_range = A ? A.sensor_range : 5
	for(var/obj/item/integrated_circuit/HS in R.module.modules)
		for(var/mob/living/carbon/M in range(scan_range, R))
			if(M.stat == DEAD)
				continue
			if((M.getBruteLoss() + M.getFireLoss() + M.getToxLoss() + M.getOxyLoss()) >= damage_threshold)
				HS.set_pin_data(IC_INPUT, 1, WEAKREF(M))
				HS.do_work()
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
	tutorial_text = "Uses the robot's radio to send a message on its default channel. No special hardware required - all robots have a radio. Configure 'alert_message' to set what it says. Good for: distress calls, zone announcements, status reports."
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
	tutorial_text = "Like Broadcast Alert but automatically includes the robot's current area in the message. Good for: taking damage events, low health situations, or being attacked. No configuration needed."
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
	tutorial_text = "The robot says your configured message out loud via its speech system. If it has a text-to-speech IC it uses that; otherwise falls back to a direct say(). Configure 'say_string' to set the message. Great for: greetings, warnings, personality, or responding to speech triggers."
	cpu_cost = 1
	var/say_string = "Beep."

/datum/behavior_circuit/response/say_text/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.module)
		for(var/obj/item/integrated_circuit/output/text_to_speech/TTS in R.module.modules)
			TTS.set_pin_data(IC_INPUT, 1, say_string)
			TTS.do_work()
			return
	R.say(say_string)


// -- EMOTE ACTION ------------------------------------

/datum/behavior_circuit/response/emote_action
	circuit_name = "Response: Emote Action"
	circuit_desc = "Robot performs a visible emote or ambient action."
	tutorial_text = "Shows a custom emote message visible to nearby players. The robot will '\[robot name\] \[emote_text\].' - configure 'emote_text' to set the action. Great for personality: beeping, gesturing, reacting to stimuli. No hardware required."
	cpu_cost = 1
	var/emote_text = "beeps cheerfully"

/datum/behavior_circuit/response/emote_action/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	R.visible_message(span_notice("[R] [emote_text]."))


// -- ENTER COMBAT MODE -------------------------------

/datum/behavior_circuit/response/enter_combat_mode
	circuit_name = "Response: Enter Combat Mode"
	circuit_desc = "Switches the robot into combat stance."
	tutorial_text = "Sets the robot's combat mode flag, which affects how it interacts with mobs. No hardware required - any robot can enter combat mode. This is a stance change, not an attack. Pair with Fire Weapon or Pathfind To Enemy for actual combat."
	cpu_cost = 1

/datum/behavior_circuit/response/enter_combat_mode/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	R.a_intent = INTENT_HARM


// -- SELF REPAIR PULSE -------------------------------

/datum/behavior_circuit/response/self_repair_pulse
	circuit_name = "Response: Self Repair Pulse"
	circuit_desc = "Instantly repairs a small amount of the robot's damage."
	tutorial_text = "The robot patches its own chassis for a small amount. No hardware required - uses internal self-maintenance routines. Configure 'repair_amount' (default 15) to adjust how much is repaired per pulse. Higher values drain the cell faster. Good paired with On Take Damage."
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
	tutorial_text = "Activates a hard lockdown: the robot anchors itself, enters a defensive stance, and emits an alarm sound. Good for: area denial when critically damaged, security checkpoint bots, or self-preservation responses. Combine with Broadcast Distress for maximum effect."
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
	tutorial_text = "Steps toward the nearest visible enemy each time it fires. Since most triggers fire every few seconds and this steps once, the robot will slowly close the distance. For faster pursuit pair this with a short-interval trigger. No hardware required - uses the robot's built-in locomotion."
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
	tutorial_text = "HARDWARE SETUP: Scan a player's ID card with a multitool, then use the multitool on the robot to link them as the follow target. Once linked the robot will step toward that specific mob whenever this response fires. If the linked target is gone or dead, does nothing. Link is persistent until reprogrammed. Use with On Interval trigger for continuous escort."
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
	tutorial_text = "Cowardly survival response. Steps away from the nearest enemy each time it fires. Combine with On Take Damage for a robot that retreats when shot. No hardware required. Useful for non-combat robots that should not stand their ground."
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
	tutorial_text = "The most basic movement response. Steps exactly one tile in the configured direction each time it fires. Combine with On Interval for a simple patrol loop: set interval to 10 and alternate NORTH/SOUTH assemblies for a back-and-forth patrol. Configure 'move_dir' (NORTH/SOUTH/EAST/WEST)."
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
	circuit_desc = "Fires the robot's weapon IC at the nearest enemy. Requires weapon_firing IC."
	tutorial_text = "HARDWARE REQUIRED: weapon_firing IC in the robot's module. Finds the first weapon_firing IC, scans for the nearest hostile in sensor range, and fires at it. If no weapon IC is found or no enemy is in range, does nothing. Pair with On Enemy Spotted for a complete auto-turret."
	cpu_cost = 3

/datum/behavior_circuit/response/fire_weapon/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	var/obj/item/integrated_circuit/weaponized/weapon_firing/WF = null
	for(var/obj/item/integrated_circuit/weaponized/weapon_firing/W in R.module.modules)
		WF = W
		break
	if(!WF || !WF.installed_gun)
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
	var/turf/T = get_turf(target)
	var/turf/self = get_turf(R)
	WF.set_pin_data(IC_INPUT, 1, T.x - self.x)
	WF.set_pin_data(IC_INPUT, 2, T.y - self.y)
	WF.set_pin_data(IC_INPUT, 3, TRUE)
	WF.do_work()


// -- FIRE AIR CANNON ---------------------------------

/datum/behavior_circuit/response/fire_air_cannon
	needs_hardware = TRUE
	circuit_name = "Response: Fire Air Cannon"
	circuit_desc = "Fires the pneumatic cannon at the nearest enemy. Requires air_cannon and atmospherics ICs."
	tutorial_text = "HARDWARE REQUIRED: air_cannon IC and atmospherics IC in the robot's module. Non-lethal suppression: knocks targets back without dealing direct damage. Good for crowd control robots. If either IC is missing, silently does nothing."
	cpu_cost = 3

/datum/behavior_circuit/response/fire_air_cannon/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	var/obj/item/integrated_circuit/weaponized/air_cannon/AC = null
	var/obj/item/integrated_circuit/atmospherics/AT = null
	for(var/obj/item/integrated_circuit/weaponized/air_cannon/C in R.module.modules)
		AC = C
		break
	for(var/obj/item/IC in R.module.modules)
		if(istype(IC, /obj/item/integrated_circuit/atmospherics))
			AT = IC
			break
	if(!AC || !AT)
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
	var/turf/T = get_turf(target)
	var/turf/self = get_turf(R)
	AT.set_pin_data(IC_INPUT, 1, T.x - self.x)
	AT.set_pin_data(IC_INPUT, 2, T.y - self.y)
	AC.set_pin_data(IC_INPUT, 1, AT.get_pin_data(IC_OUTPUT, 1))
	AC.do_work()


// -- DETONATE SELF -----------------------------------

/datum/behavior_circuit/response/detonate_self
	circuit_name = "Response: Detonate Self"
	circuit_desc = "Triggers a self-destruct explosion after a short delay."
	tutorial_text = "The robot announces its detonation, then explodes after 3 seconds. No cert gate - any robot can self-destruct if programmed to. The player or admin installing this assembly is responsible for the consequences. Pair with On Death or On Enemy Spotted for suicide builds. Very loud, very final."
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
	circuit_desc = "Arms the grenade loaded in the robot's grenade primer IC."
	tutorial_text = "HARDWARE REQUIRED: grenade IC with an attached grenade in the robot's module. Arms and primes the grenade. If no grenade IC or no attached grenade is found, does nothing. Useful for trap-setter robots or walking bombs. Configure 'detonation_time' (default 3 seconds)."
	cpu_cost = 2
	var/detonation_time = 3

/datum/behavior_circuit/response/prime_grenade/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/weaponized/grenade/GR in R.module.modules)
		if(!GR.attached_grenade || GR.attached_grenade.active)
			continue
		GR.set_pin_data(IC_INPUT, 1, detonation_time)
		GR.do_work()
		R.visible_message(span_danger("[R] arms a grenade!"))
		return


// -- THROW ITEM AT ENEMY -----------------------------

/datum/behavior_circuit/response/throw_item_at_enemy
	needs_hardware = TRUE
	circuit_name = "Response: Throw Item At Enemy"
	circuit_desc = "Throws held items at the nearest hostile. Requires grabber and thrower ICs."
	tutorial_text = "HARDWARE REQUIRED: grabber IC and thrower IC in the robot's module. The robot must already be holding something (via Grab Nearest Item) to throw. Great for improvised weapon robots or distracting enemies. No kill-switch required."
	cpu_cost = 2

/datum/behavior_circuit/response/throw_item_at_enemy/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	var/obj/item/integrated_circuit/manipulation/thrower/TH = null
	var/obj/item/integrated_circuit/manipulation/grabber/GR = null
	for(var/obj/item/integrated_circuit/manipulation/thrower/T in R.module.modules)
		TH = T
		break
	for(var/obj/item/integrated_circuit/manipulation/grabber/G in R.module.modules)
		GR = G
		break
	if(!TH || !GR || !GR.contents.len)
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
	TH.set_pin_data(IC_INPUT, 1, WEAKREF(target))
	TH.do_work()


// -- INJECT REAGENT ----------------------------------

/datum/behavior_circuit/response/inject_reagent
	needs_hardware = TRUE
	circuit_name = "Response: Inject Reagent"
	circuit_desc = "Injects reagents into the nearest valid target. Requires borghypo IC."
	tutorial_text = "HARDWARE REQUIRED: borghypo (injector) in the robot's module. Injects 'inject_amount' units into the nearest mob (friendly or hostile, configurable). Used by medic robots. Configure 'inject_amount' (default 5u) and 'target_friendly' (TRUE = inject friendlies only)."
	cpu_cost = 2
	var/inject_amount = 5
	var/target_friendly = TRUE

/datum/behavior_circuit/response/inject_reagent/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	var/obj/item/reagent_containers/borghypo/hypo = null
	for(var/obj/item/reagent_containers/borghypo/H in R.module.modules)
		hypo = H
		break
	if(!hypo || !hypo.reagents || !hypo.reagents.total_volume)
		return
	var/scan_range = A ? A.sensor_range : 5
	for(var/mob/living/carbon/M in range(scan_range, R))
		if(M.stat == DEAD)
			continue
		if(target_friendly && !R.faction_check_mob(M, FALSE))
			continue
		hypo.reagents.trans_to(M, inject_amount)
		R.visible_message(span_notice("[R] administers treatment to [M]."))
		return


// -- OFFER DRINK -------------------------------------

/datum/behavior_circuit/response/offer_drink
	needs_hardware = TRUE
	circuit_name = "Response: Offer Drink"
	circuit_desc = "Dispenses drink to the nearest thirsty mob. Requires borghypo IC."
	tutorial_text = "HARDWARE REQUIRED: borghypo in the robot's module loaded with a drink reagent. Finds the nearest thirsty human and dispenses 10u to them. For Drink-Bot builds. The borghypo must have liquid in it - it won't refill automatically. Pair with On Mob Thirsty trigger."
	cpu_cost = 1

/datum/behavior_circuit/response/offer_drink/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	var/obj/item/reagent_containers/borghypo/dispenser = null
	for(var/obj/item/reagent_containers/borghypo/H in R.module.modules)
		dispenser = H
		break
	if(!dispenser || !dispenser.reagents || !dispenser.reagents.total_volume)
		return
	var/obj/item/behavior_assembly/asm = get_assembly()
	var/scan_range = asm ? asm.sensor_range : 5
	for(var/mob/living/carbon/human/H in range(scan_range, R))
		if(H.stat == DEAD || !H.reagents)
			continue
		if(H.thirst < THIRST_LEVEL_THIRSTY)
			dispenser.reagents.trans_to(H, 10)
			R.visible_message(span_notice("[R] extends a dispenser nozzle toward [H]."))
			return


// -- GRAB NEAREST ITEM -------------------------------

/datum/behavior_circuit/response/grab_nearest_item
	needs_hardware = TRUE
	circuit_name = "Response: Grab Nearest Item"
	circuit_desc = "Grabs the nearest loose item using the grabber IC."
	tutorial_text = "HARDWARE REQUIRED: grabber IC in the robot's module. Finds the nearest loose item within grab_range and picks it up using the IC. The robot can then throw it (Throw Item At Enemy) or carry it. Configure 'grab_range' (default 2 tiles)."
	cpu_cost = 2
	var/grab_range = 2

/datum/behavior_circuit/response/grab_nearest_item/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	var/obj/item/integrated_circuit/manipulation/grabber/GR = null
	for(var/obj/item/integrated_circuit/manipulation/grabber/G in R.module.modules)
		GR = G
		break
	if(!GR)
		return
	for(var/obj/item/I in range(grab_range, R))
		if(istype(I, /obj/item/electronic_assembly) || istype(I, /obj/item/integrated_circuit))
			continue
		if(I.anchored)
			continue
		GR.set_pin_data(IC_INPUT, 1, WEAKREF(I))
		GR.set_pin_data(IC_INPUT, 2, 1)
		GR.do_work()
		return


// -- DROP ALL ITEMS ----------------------------------

/datum/behavior_circuit/response/drop_all_items
	needs_hardware = TRUE
	circuit_name = "Response: Drop All Items"
	circuit_desc = "Ejects all items from the robot's grabber IC."
	tutorial_text = "HARDWARE REQUIRED: grabber IC. Calls the grabber's eject-all mode. Good for: deposit robots that grab items and drop them at a location, or robots that drop weapons on death. Pair with On Death trigger."
	cpu_cost = 1

/datum/behavior_circuit/response/drop_all_items/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/manipulation/grabber/GR in R.module.modules)
		GR.set_pin_data(IC_INPUT, 2, -1)
		GR.do_work()


// -- STUN TARGET -------------------------------------

/datum/behavior_circuit/response/stun_target
	circuit_name = "Response: Stun Target"
	circuit_desc = "Stuns the nearest hostile mob briefly."
	tutorial_text = "Emits a focused EMP-like pulse that stuns the nearest enemy. No weapon IC required - the robot's chassis delivers the pulse directly. Stun duration is configurable (default 2 seconds). Good for security robots that need to incapacitate without lethal force."
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
	tutorial_text = "Creates a small smoke cloud at the robot's position. Useful for: escape when taking damage, area denial, obscuring allied movement. No hardware required. Configure 'smoke_range' (default 2 tiles) and 'smoke_duration' (default 15 ticks)."
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
	circuit_desc = "Sprays CO2 at nearby fire tiles. Requires extinguisher IC."
	tutorial_text = "HARDWARE REQUIRED: extinguisher IC in the module. Scans nearby turfs for fire and activates the IC to extinguish it. For firefighting robots. If no extinguisher IC is present it silently does nothing."
	cpu_cost = 2

/datum/behavior_circuit/response/fire_extinguisher/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	var/scan_range = A ? A.sensor_range : 3
	for(var/turf/T in range(scan_range, R))
		if(locate(/obj/effect/hotspot) in T)
			for(var/obj/item/integrated_circuit/atmospherics/EX in R.module.modules)
				EX.set_pin_data(IC_INPUT, 1, WEAKREF(T))
				EX.do_work()
				return


// -- TOGGLE LIGHT ------------------------------------

/datum/behavior_circuit/response/toggle_light
	needs_hardware = TRUE
	circuit_name = "Response: Toggle Light"
	circuit_desc = "Toggles or sets the robot's light output IC."
	tutorial_text = "HARDWARE REQUIRED: light output IC in the module. Toggles it by default or forces it on/off. Configure 'force_state': -1 = toggle, 0 = force off, 1 = force on. Good for night-cycle triggers or stealth robots that turn off their lights."
	cpu_cost = 1
	var/force_state = -1

/datum/behavior_circuit/response/toggle_light/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/output/light/LT in R.module.modules)
		var/cur = LT.get_pin_data(IC_OUTPUT, 1)
		var/new_state = (force_state == -1) ? !cur : force_state
		LT.set_pin_data(IC_INPUT, 1, new_state)
		LT.do_work()
		return


// -- PLAY SOUND --------------------------------------

/datum/behavior_circuit/response/play_sound
	circuit_name = "Response: Play Sound"
	circuit_desc = "Plays a sound effect at the robot's position."
	tutorial_text = "Plays a sound file from the robot's location. Great for personality and feedback: alarm sounds, beeps, music. Configure 'sound_file' to a valid sound path (e.g. 'sound/machines/beep.ogg'). Volume configurable (0-100)."
	cpu_cost = 1
	var/sound_file = 'sound/machines/beep.ogg'
	var/sound_volume = 50

/datum/behavior_circuit/response/play_sound/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	playsound(R, sound_file, sound_volume, 1)


// -- PUMP REAGENTS -----------------------------------

/datum/behavior_circuit/response/pump_reagents
	needs_hardware = TRUE
	circuit_name = "Response: Pump Reagents"
	circuit_desc = "Activates the reagent pump IC to push chemicals."
	tutorial_text = "HARDWARE REQUIRED: reagent pump IC. Activates the pump to push reagents from a container through the IC. For chemistry/service robots. If no pump IC is present does nothing."
	cpu_cost = 1

/datum/behavior_circuit/response/pump_reagents/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/P in R.module.modules)
		P.do_work()
		return


// -- SEND RADIO SIGNAL -------------------------------

/datum/behavior_circuit/response/send_radio_signal
	needs_hardware = TRUE
	circuit_name = "Response: Send Radio Signal"
	circuit_desc = "Transmits a radio signal via the robot's signaler IC."
	tutorial_text = "HARDWARE REQUIRED: signaler IC in the module. Pulses the signaler to transmit on its configured frequency. Good for triggering other robot assemblies remotely, activating traps, or chaining behaviors across multiple robots. Configure frequency on the IC itself."
	cpu_cost = 1

/datum/behavior_circuit/response/send_radio_signal/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/input/signaler/S in R.module.modules)
		S.do_work()
		return


// -- READ BATTERY ------------------------------------

/datum/behavior_circuit/response/read_battery
	circuit_name = "Response: Read Battery"
	circuit_desc = "Says the current cell charge percentage aloud."
	tutorial_text = "The robot announces its current battery percentage. Simple diagnostic response. Pair with On Interval for a status robot that periodically reports its health, or On Low Power for an automatic low-battery warning. No hardware required."
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
	tutorial_text = "Starts pulling the nearest friendly mob toward the robot. Good for: rescue robots that drag the injured to safety, escort builds, or any situation where you want the robot to physically haul an ally. No hardware required."
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
	circuit_desc = "Shows a message on the robot's screen display IC."
	tutorial_text = "HARDWARE REQUIRED: screen display IC. Updates the display with 'display_text'. Good for status boards, warning displays, or information robots. Configure 'display_text' to set the message shown."
	cpu_cost = 1
	var/display_text = "STATUS: NOMINAL"

/datum/behavior_circuit/response/display_screen/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/output/D in R.module.modules)
		D.set_pin_data(IC_INPUT, 1, display_text)
		D.do_work()
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
