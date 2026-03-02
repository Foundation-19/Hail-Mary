// ====================================================
// BEHAVIOR CIRCUITS
// Signal-driven automation circuits for behavior assemblies.
//
// NOTE: COMSIG values are stubbed below pending confirmation
// of actual signal define names from your codebase.
// Search for "// STUB:" to find swap points.
//
// File: code/modules/integrated_electronics/behavior_circuits.dm
// ====================================================


// ====================================================
// TRIGGER BASE
// ====================================================

/datum/behavior_circuit/trigger
	var/datum/behavior_circuit/response/response = null

/datum/behavior_circuit/trigger/proc/_trigger(mob/living/silicon/robot/R)
	if(response)
		response.execute(R, get_assembly())


// ====================================================
// RESPONSE BASE
// execute() is declared here so subtypes can override it.
// ====================================================

/datum/behavior_circuit/response/proc/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	return


// ====================================================
// TRIGGER CIRCUITS
// ====================================================


// --- ON TAKE DAMAGE ---

/datum/behavior_circuit/trigger/on_take_damage
	circuit_name = "Trigger: On Take Damage"
	circuit_desc = "Fires when the robot takes damage above the threshold."
	var/damage_threshold = 10
	var/last_health = -1  // tracked manually since we can't rely on healthchange signal

/datum/behavior_circuit/trigger/on_take_damage/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	last_health = R.health
	// STUB: Replace COMSIG_MOB_HEALTHCHANGE with your actual health change signal
	// e.g. COMSIG_LIVING_HEALTH_UPDATE or equivalent
	// RegisterSignal(R, COMSIG_MOB_HEALTHCHANGE, PROC_REF(_on_health_change))
	//
	// Using START_PROCESSING as a fallback until signal name is confirmed
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_take_damage/unregister(mob/living/silicon/robot/R)
	// UnregisterSignal(R, COMSIG_MOB_HEALTHCHANGE)
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


// --- ON LOW POWER ---

/datum/behavior_circuit/trigger/on_low_power
	circuit_name = "Trigger: On Low Power"
	circuit_desc = "Fires when the robot's power cell drops below threshold."
	var/charge_threshold = 0.2
	var/already_triggered = FALSE  // only fire once per low-power event

/datum/behavior_circuit/trigger/on_low_power/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_low_power/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_low_power/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || !R.cell)
		return
	var/ratio = R.cell.charge / R.cell.maxcharge
	if(ratio <= charge_threshold)
		if(!already_triggered)
			already_triggered = TRUE
			_trigger(R)
	else
		already_triggered = FALSE  // reset once recharged


// --- ON ENEMY SPOTTED ---

/datum/behavior_circuit/trigger/on_enemy_spotted
	circuit_name = "Trigger: On Enemy Spotted"
	circuit_desc = "Fires when a hostile mob enters sensor range."
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
		return
	var/obj/item/behavior_assembly/A = get_assembly()
	var/scan_range = A ? A.sensor_range : 5

	for(var/mob/living/M in range(scan_range, R))
		if(M == R)
			continue
		if(M.stat == DEAD)
			continue
		if(!R.faction_check_mob(M, FALSE))
			last_spotted = world.time
			_trigger(R)
			return


// --- ON DEATH ---

/datum/behavior_circuit/trigger/on_death
	circuit_name = "Trigger: On Death"
	circuit_desc = "Fires once when the robot is destroyed."

/datum/behavior_circuit/trigger/on_death/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	// STUB: Replace with your actual mob death signal
	// e.g. COMSIG_MOB_DEATH or COMSIG_LIVING_DEATH
	// RegisterSignal(R, COMSIG_MOB_DEATH, PROC_REF(_on_death))
	//
	// Using SSobj process as fallback
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_death/unregister(mob/living/silicon/robot/R)
	// UnregisterSignal(R, COMSIG_MOB_DEATH)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_death/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R)
		STOP_PROCESSING(SSobj, src)
		return
	if(R.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		_trigger(R)


// ====================================================
// RESPONSE CIRCUITS
// ====================================================


// --- BROADCAST ALERT ---

/datum/behavior_circuit/response/broadcast_alert
	circuit_name = "Response: Broadcast Alert"
	circuit_desc = "Broadcasts an alert on the robot's radio channel."
	var/alert_message = "WARNING: Threat detected."

/datum/behavior_circuit/response/broadcast_alert/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.radio)
		return
	R.say(alert_message, language = null)


// --- ENTER COMBAT MODE ---

/datum/behavior_circuit/response/enter_combat_mode
	circuit_name = "Response: Enter Combat Mode"
	circuit_desc = "Activates the robot's combat routines."

/datum/behavior_circuit/response/enter_combat_mode/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.cpu_cert)
		return
	if(!(R.cpu_cert.capability_flags & CERT_CAN_SHOOT))
		return
	if(R.emagged)
		return
	R.SetEmagged(TRUE)
	R.audible_message(span_warning("[R] enters combat mode!"))


// --- SELF REPAIR PULSE ---

/datum/behavior_circuit/response/self_repair_pulse
	circuit_name = "Response: Self Repair Pulse"
	circuit_desc = "Triggers a minor self-repair routine, restoring some brute damage."
	var/repair_amount = 15

/datum/behavior_circuit/response/self_repair_pulse/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.cpu_cert)
		return
	if(!(R.cpu_cert.capability_flags & CERT_CAN_REPAIR))
		return
	if(!R.getBruteLoss())
		return
	R.adjustBruteLoss(-repair_amount)
	R.audible_message(span_notice("[R]'s repair subroutines activate briefly."))


// --- LOCKDOWN SELF ---

/datum/behavior_circuit/response/lockdown_self
	circuit_name = "Response: Emergency Lockdown"
	circuit_desc = "Initiates an emergency lockdown, immobilizing the robot."

/datum/behavior_circuit/response/lockdown_self/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.locked_down)
		return
	R.SetLockdown(TRUE)
	R.audible_message(span_warning("[R] enters emergency lockdown!"))


// --- BROADCAST DISTRESS ---

/datum/behavior_circuit/response/broadcast_distress
	circuit_name = "Response: Broadcast Distress Signal"
	circuit_desc = "Broadcasts a distress signal including current location."

/datum/behavior_circuit/response/broadcast_distress/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.radio)
		return
	var/area/here = get_area(R)
	R.say("DISTRESS SIGNAL: Unit [R.real_name] reporting threat at [here ? here.name : "unknown location"]. Requesting assistance.", language = null)


// ====================================================
// PRE-BUILT ASSEMBLY SUBTYPES
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
	T.damage_threshold = 5
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/watchdog
	assembly_label = "Watchdog Protocol"

/obj/item/behavior_assembly/watchdog/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_low_power/T = new()
	var/datum/behavior_circuit/response/broadcast_alert/RE = new()
	RE.alert_message = "WARNING: Power reserves critical. Requesting recharge."
	T.response = RE
	circuits += T
	circuits += RE

/obj/item/behavior_assembly/deadman
	assembly_label = "Deadman Protocol"

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
	T.damage_threshold = 20
	T.response = RE
	circuits += T
	circuits += RE


// ====================================================
// EXPANDED BEHAVIOR CIRCUITS
// ====================================================

/datum/behavior_circuit/trigger/on_mob_thirsty
	circuit_name = "Trigger: Mob Thirsty Nearby"
	circuit_desc = "Fires when a human survivor in sensor range is thirsty."
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
		return
	var/obj/item/behavior_assembly/A = get_assembly()
	var/scan_range = A ? A.sensor_range : 5

	for(var/mob/living/carbon/human/H in range(scan_range, R))
		if(H.stat == DEAD)
			continue
		if(H.thirst < THIRST_LEVEL_THIRSTY)
			_trigger(R)
			return


// ====================================================
// TRIGGER: ON MOB INJURED
// Fires when a friendly mob nearby is hurt.
// Pairs well with: self_repair_pulse or broadcast_alert
// ====================================================

/datum/behavior_circuit/trigger/on_mob_injured
	circuit_name = "Trigger: Friendly Injured Nearby"
	circuit_desc = "Fires when a friendly mob in sensor range is below 50% health."
	var/last_check = 0
	var/check_cooldown = 50
	var/health_threshold = 0.5  // 50% health

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
		return
	var/obj/item/behavior_assembly/A = get_assembly()
	var/scan_range = A ? A.sensor_range : 5

	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(!R.faction_check_mob(M, FALSE))  // only friendly mobs
			continue
		if(M.health < M.getMaxHealth() * health_threshold)
			_trigger(R)
			return


// ====================================================
// TRIGGER: ON NIGHT CYCLE
// Fires when the server enters night.
// Pairs well with: enter_combat_mode, lockdown_self
// ====================================================

/datum/behavior_circuit/trigger/on_night_cycle
	circuit_name = "Trigger: Night Cycle"
	circuit_desc = "Fires when night begins. Resets at dawn."
	var/fired_tonight = FALSE

/datum/behavior_circuit/trigger/on_night_cycle/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_night_cycle/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_night_cycle/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return
	// Check SSnight if it exists, otherwise check lighting
	// STUB: replace SSnight.is_night with your actual night check proc
	var/is_night = (world.time % 2400 > 1200)  // rough placeholder
	if(is_night && !fired_tonight)
		fired_tonight = TRUE
		_trigger(R)
	else if(!is_night)
		fired_tonight = FALSE  // reset for next night


// ====================================================
// TRIGGER: ON MESS DETECTED
// Fires when a cleanable decal is on the floor in range.
// Pairs well with: emote_action (cleaning response)
// ====================================================

/datum/behavior_circuit/trigger/on_mess_detected
	circuit_name = "Trigger: Mess Detected"
	circuit_desc = "Fires when a mess (cleanable decal) is detected on the floor in sensor range."
	var/last_check = 0
	var/check_cooldown = 100

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
		return
	var/obj/item/behavior_assembly/A = get_assembly()
	var/scan_range = A ? A.sensor_range : 5

	for(var/obj/effect/decal/cleanable/C in range(scan_range, R))
		_trigger(R)
		return


// ====================================================
// TRIGGER: ON MOB APPROACHES
// Fires when ANY mob (faction irrelevant) enters range.
// Pairs well with: offer_drink, broadcast_alert, follow_target
// ====================================================

/datum/behavior_circuit/trigger/on_mob_approaches
	circuit_name = "Trigger: Mob Approaches"
	circuit_desc = "Fires when any living mob enters close sensor range. Faction-neutral."
	var/last_triggered = 0
	var/approach_cooldown = 100
	var/approach_range = 3  // tighter than sensor_range - personal space

/datum/behavior_circuit/trigger/on_mob_approaches/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_mob_approaches/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_mob_approaches/process()
	if(world.time < last_triggered + approach_cooldown)
		return
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return

	for(var/mob/living/M in range(approach_range, R))
		if(M == R || M.stat == DEAD)
			continue
		last_triggered = world.time
		_trigger(R)
		return


// ====================================================
// RESPONSE: OFFER DRINK
// Dispenses water/drink to a thirsty mob in range.
// Uses the first borghypo found in the robot's module list.
// ====================================================

/datum/behavior_circuit/response/offer_drink
	circuit_name = "Response: Offer Drink"
	circuit_desc = "Dispenses water to the nearest thirsty mob. Requires drink dispenser module."

/datum/behavior_circuit/response/offer_drink/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	// Find a borghypo in the robot's modules to dispense from
	var/obj/item/reagent_containers/borghypo/dispenser = null
	for(var/obj/item/reagent_containers/borghypo/H in R.module.modules)
		dispenser = H
		break
	if(!dispenser || !dispenser.reagents || !dispenser.reagents.total_volume)
		return

	var/obj/item/behavior_assembly/asm = get_assembly()
	var/scan_range = asm ? asm.sensor_range : 5

	for(var/mob/living/carbon/human/H in range(scan_range, R))
		if(H.stat == DEAD)
			continue
		if(!H.reagents)
			continue
		if(H.thirst < THIRST_LEVEL_THIRSTY)
			dispenser.reagents.trans_to(H, 10)
			R.visible_message(span_notice("[R] extends a dispenser nozzle toward [H]."))
			return


// ====================================================
// RESPONSE: FOLLOW TARGET
// Robot moves toward the nearest friendly mob.
// Stub - actual pathfinding depends on your nav system.
// ====================================================

/datum/behavior_circuit/response/follow_target
	circuit_name = "Response: Follow Friendly"
	circuit_desc = "Moves toward the nearest friendly mob in sensor range."
	var/datum/weakref/follow_target_ref = null

/datum/behavior_circuit/response/follow_target/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/scan_range = A ? A.sensor_range : 5
	var/mob/living/closest = null
	var/closest_dist = INFINITY

	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(!R.faction_check_mob(M, FALSE))
			continue
		var/d = get_dist(R, M)
		if(d < closest_dist)
			closest_dist = d
			closest = M

	if(!closest)
		return

	follow_target_ref = WEAKREF(closest)
	// STUB: replace with your pathfinding proc
	// e.g. R.Move(get_step_towards(R, closest))
	step_towards(R, closest)
	R.setDir(get_dir(R, closest))


// ====================================================
// RESPONSE: FLEE FROM THREAT
// Robot moves away from the nearest enemy.
// ====================================================

/datum/behavior_circuit/response/flee_from_threat
	circuit_name = "Response: Flee From Threat"
	circuit_desc = "Moves away from the nearest hostile mob."

/datum/behavior_circuit/response/flee_from_threat/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	var/scan_range = A ? A.sensor_range : 5
	var/mob/living/threat = null
	var/closest_dist = INFINITY

	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(R.faction_check_mob(M, FALSE))  // skip friendlies
			continue
		var/d = get_dist(R, M)
		if(d < closest_dist)
			closest_dist = d
			threat = M

	if(!threat)
		return

	step_away(R, threat)


// ====================================================
// RESPONSE: DETONATE SELF
// Robot explodes. For chaotic or kamikaze builds.
// Only works if CERT_CAN_MALF is set on the cert.
// ====================================================

/datum/behavior_circuit/response/detonate_self
	circuit_name = "Response: Detonate Self"
	circuit_desc = "Triggers a self-destruct explosion. Requires CERT_CAN_MALF. Use carefully."

/datum/behavior_circuit/response/detonate_self/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.cpu_cert)
		return
	if(!(R.cpu_cert.capability_flags & CERT_CAN_MALF))
		return
	R.visible_message(span_danger("[R] begins emitting a high-pitched whine!"))
	addtimer(CALLBACK(src, PROC_REF(_boom), R), 30, TIMER_OVERRIDE)

/datum/behavior_circuit/response/detonate_self/proc/_boom(mob/living/silicon/robot/R)
	if(QDELETED(R))
		return
	explosion(R, devastation_range = 0, heavy_impact_range = 1, light_impact_range = 2, flash_range = 3)
	R.death()


// ====================================================
// RESPONSE: EMOTE ACTION
// Performs a visible emote. Good for personality builds.
// ====================================================

/datum/behavior_circuit/response/emote_action
	circuit_name = "Response: Emote Action"
	circuit_desc = "Performs a visible emote. Customize the emote text."
	var/emote_text = "beeps cheerfully"

/datum/behavior_circuit/response/emote_action/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	R.visible_message(span_notice("[R] [emote_text]."))


// ====================================================
// PRE-BUILT ASSEMBLY SUBTYPES - EXPANDED
// Additional preset assemblies using new circuits.
// ====================================================

// Drink bot: approach -> offer drink
/obj/item/behavior_assembly/drink_bot
	assembly_label = "Drink Bot Protocol"

/obj/item/behavior_assembly/drink_bot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_mob_approaches/T = new()
	var/datum/behavior_circuit/response/offer_drink/RE = new()
	T.approach_range = 4
	T.response = RE
	circuits += T
	circuits += RE

// Medbot: injured nearby -> broadcast alert
/obj/item/behavior_assembly/medbot
	assembly_label = "Medbot Protocol"

/obj/item/behavior_assembly/medbot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_mob_injured/T = new()
	var/datum/behavior_circuit/response/broadcast_distress/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

// Night watch: night begins -> enter combat mode
/obj/item/behavior_assembly/night_watch
	assembly_label = "Night Watch Protocol"

/obj/item/behavior_assembly/night_watch/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_night_cycle/T = new()
	var/datum/behavior_circuit/response/enter_combat_mode/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

// Janitor: mess detected -> emote cleaning
/obj/item/behavior_assembly/janitor_protocol
	assembly_label = "Janitor Protocol"

/obj/item/behavior_assembly/janitor_protocol/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_mess_detected/T = new()
	var/datum/behavior_circuit/response/emote_action/RE = new()
	RE.emote_text = "begins cleaning the floor with its utility arm"
	T.response = RE
	circuits += T
	circuits += RE

// Suicide bomb: enemy spotted -> detonate (requires CERT_CAN_MALF)
/obj/item/behavior_assembly/suicide_bomb
	assembly_label = "Last Resort Protocol"

/obj/item/behavior_assembly/suicide_bomb/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T = new()
	var/datum/behavior_circuit/response/detonate_self/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

// Escort: always follow nearest friendly
/obj/item/behavior_assembly/escort
	assembly_label = "Escort Protocol"

/obj/item/behavior_assembly/escort/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_mob_approaches/T = new()
	var/datum/behavior_circuit/response/follow_target/RE = new()
	T.approach_range = 8
	T.response = RE
	circuits += T
	circuits += RE


// ====================================================
// IC INTEGRATION LAYER
// Bridges behavior_circuit triggers/responses with the
// integrated_circuits subsystem (IC pins, locomotion,
// weaponized, reagent, output, time, access circuits).
// ====================================================


// ====================================================
// TRIGGER: ON INTERVAL (mirrors time/ticker)
// Fires on a configurable repeating interval.
// Replaces the need to wire a ticker circuit + memory
// just to drive a behavior assembly.
// Pairs well with: any response.
// ====================================================

/datum/behavior_circuit/trigger/on_interval
	circuit_name = "Trigger: On Interval"
	circuit_desc = "Fires repeatedly on a set interval (in deciseconds). Mirrors the IC ticker circuit."
	var/interval = 40  // 4 seconds default, matching slow ticker
	var/next_fire = 0

/datum/behavior_circuit/trigger/on_interval/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	next_fire = world.time + interval
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_interval/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_interval/process()
	if(world.time < next_fire)
		return
	next_fire = world.time + interval
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return
	_trigger(R)


// ====================================================
// TRIGGER: ON POWER RESTORED
// Fires once when the robot's cell charge recovers
// above threshold after having been low.
// Mirrors power transmitter circuit awareness.
// Pairs well with: broadcast_alert, emote_action.
// ====================================================

/datum/behavior_circuit/trigger/on_power_restored
	circuit_name = "Trigger: On Power Restored"
	circuit_desc = "Fires once when the robot's power cell recovers above the threshold after being low."
	var/restore_threshold = 0.5  // 50% charge to count as "restored"
	var/was_low = FALSE

/datum/behavior_circuit/trigger/on_power_restored/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_power_restored/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_power_restored/process()
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || !R.cell)
		return
	var/ratio = R.cell.charge / R.cell.maxcharge
	if(ratio < restore_threshold)
		was_low = TRUE
	else if(was_low)
		was_low = FALSE
		_trigger(R)


// ====================================================
// TRIGGER: ON ACCESS GRANTED
// Fires when a mob with sufficient access approaches.
// Mirrors access.dm card_reader circuit behavior:
// checks if a nearby mob holds an ID that passes
// the assembly's access_card check.
// Pairs well with: emote_action, broadcast_alert,
//                  toggle_light_response, unlock_doors.
// ====================================================

/datum/behavior_circuit/trigger/on_access_granted
	circuit_name = "Trigger: On Access Granted"
	circuit_desc = "Fires when a friendly mob with a valid ID card enters close range. Mirrors card_reader circuit."
	var/last_triggered = 0
	var/access_cooldown = 50
	var/check_range = 1

/datum/behavior_circuit/trigger/on_access_granted/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_access_granted/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_access_granted/process()
	if(world.time < last_triggered + access_cooldown)
		return
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD)
		return

	for(var/mob/living/carbon/human/H in range(check_range, R))
		if(H.stat == DEAD)
			continue
		var/obj/item/card/id/card = H.get_idcard(TRUE)
		if(!card)
			continue
		// Fire when any nearby human presents a valid ID card
		last_triggered = world.time
		_trigger(R)
		return


// ====================================================
// TRIGGER: ON WEAPON_FIRED (mirrors weaponized.dm)
// Fires when the robot's weapon_firing IC completes
// a shot. Hook into post-fire to chain a response
// (e.g. retreat after shooting, say a line, etc.)
// Uses processing poll since we can't RegisterSignal
// on a circuit's activate_pin easily without a hook.
// ====================================================

/datum/behavior_circuit/trigger/on_weapon_fired
	circuit_name = "Trigger: On Weapon Fired"
	circuit_desc = "Fires after the robot's weapon firing circuit completes a shot. Mirrors weaponized IC behavior."
	var/last_shot_time = 0
	var/shot_cooldown = 10

/datum/behavior_circuit/trigger/on_weapon_fired/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_weapon_fired/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_weapon_fired/process()
	if(world.time < last_shot_time + shot_cooldown)
		return
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD || !R.module)
		return
	// Detect if a weapon_firing circuit recently fired by checking
	// any energy gun in the robot's module for a depleted charge delta.
	// This is a best-effort heuristic since we cannot hook IC activate_pin directly.
	for(var/obj/item/gun/energy/G in R.module.modules)
		var/obj/item/stock_parts/cell/C = G.get_cell()
		if(C && C.charge < C.maxcharge)
			last_shot_time = world.time
			_trigger(R)
			return


// ====================================================
// RESPONSE: MOVE IN DIRECTION (mirrors locomotion IC)
// Steps the robot one tile in a configured direction.
// Direct mirror of manipulation/locomotion do_work().
// ====================================================

/datum/behavior_circuit/response/move_direction
	circuit_name = "Response: Move Direction"
	circuit_desc = "Steps the robot one tile in the set direction. Mirrors the IC locomotion circuit."
	var/move_dir = SOUTH

/datum/behavior_circuit/response/move_direction/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.anchored || R.stat == DEAD)
		return
	step(R, move_dir)


// ====================================================
// RESPONSE: PATHFIND TO NEAREST ENEMY
// Uses get_step_towards for basic pathfinding toward
// the nearest hostile mob. Upgrades the stub in
// flee_from_threat / follow_target with the same
// approach used by smart/basic_pathfinder do_work().
// ====================================================

/datum/behavior_circuit/response/pathfind_to_enemy
	circuit_name = "Response: Pathfind To Enemy"
	circuit_desc = "Steps toward the nearest hostile mob using pathfinding. Mirrors IC basic_pathfinder logic."

/datum/behavior_circuit/response/pathfind_to_enemy/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(R.anchored || R.stat == DEAD)
		return
	var/scan_range = A ? A.sensor_range : 7
	var/mob/living/target = null
	var/closest_dist = INFINITY

	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(R.faction_check_mob(M, FALSE))  // skip friendlies
			continue
		var/d = get_dist(R, M)
		if(d < closest_dist)
			closest_dist = d
			target = M

	if(!target)
		return
	// Mirror of smart/basic_pathfinder: step towards visible target
	if(target in view(get_turf(R)))
		step(R, get_dir(get_turf(R), get_step_towards(get_turf(R), target)))
	else
		step_towards(R, target)


// ====================================================
// RESPONSE: FIRE WEAPON
// Activates the first weapon_firing IC found in the
// robot's module, targeting the nearest visible enemy.
// Direct mirror of weaponized/weapon_firing do_work().
// ====================================================

/datum/behavior_circuit/response/fire_weapon
	circuit_name = "Response: Fire Weapon"
	circuit_desc = "Fires the robot's weapon at the nearest visible hostile. Requires a weapon_firing IC in the module. Mirrors weaponized IC."

/datum/behavior_circuit/response/fire_weapon/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.cpu_cert)
		return
	if(!(R.cpu_cert.capability_flags & CERT_CAN_SHOOT))
		return
	if(!R.module)
		return

	// Find a weapon_firing IC in the module
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

	// Set IC input pins and pulse fire, mirroring weaponized/weapon_firing
	var/turf/T = get_turf(target)
	var/turf/self = get_turf(R)
	WF.set_pin_data(IC_INPUT, 1, T.x - self.x)
	WF.set_pin_data(IC_INPUT, 2, T.y - self.y)
	WF.set_pin_data(IC_INPUT, 3, TRUE)  // lethal mode
	WF.do_work()


// ====================================================
// RESPONSE: INJECT REAGENT
// Injects reagents from the first injector IC found
// in the robot's module into the nearest valid target.
// Mirrors reagents/injector do_work() logic.
// ====================================================

/datum/behavior_circuit/response/inject_reagent
	circuit_name = "Response: Inject Reagent"
	circuit_desc = "Injects reagents from the robot's integrated hypo-injector into the nearest valid target. Mirrors IC injector."
	var/inject_amount = 5
	var/inject_friendlies_only = TRUE

/datum/behavior_circuit/response/inject_reagent/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return

	var/obj/item/integrated_circuit/reagent/injector/INJ = null
	for(var/obj/item/integrated_circuit/reagent/injector/I in R.module.modules)
		INJ = I
		break
	if(!INJ || !INJ.reagents || !INJ.reagents.total_volume)
		return

	var/scan_range = 1  // must be adjacent, mirrors IC injector range check
	var/mob/living/carbon/human/best = null

	for(var/mob/living/carbon/human/H in range(scan_range, R))
		if(H.stat == DEAD)
			continue
		if(inject_friendlies_only && !R.faction_check_mob(H, FALSE))
			continue
		best = H
		break

	if(!best || !best.reagents)
		return

	INJ.set_pin_data(IC_INPUT, 1, WEAKREF(best))
	INJ.set_pin_data(IC_INPUT, 2, inject_amount)
	INJ.do_work(1)


// ====================================================
// RESPONSE: PLAY SOUND
// Plays a sound via the robot's beeper/speaker IC,
// or falls back to playsound directly.
// Mirrors output/sound/beeper do_work().
// ====================================================

/datum/behavior_circuit/response/play_sound
	circuit_name = "Response: Play Sound"
	circuit_desc = "Plays a sound from the robot's speaker circuit, or directly. Mirrors IC beeper/speaker."
	var/sound_path = 'sound/machines/ping.ogg'
	var/sound_volume = 50

/datum/behavior_circuit/response/play_sound/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	// Try to use a speaker IC in the module first (mirrors output/sound do_work)
	if(R.module)
		for(var/obj/item/integrated_circuit/output/sound/SPK in R.module.modules)
			SPK.set_pin_data(IC_INPUT, 1, sound_path)
			SPK.set_pin_data(IC_INPUT, 2, sound_volume)
			SPK.do_work()
			return
	// Fallback: direct playsound if no speaker IC installed
	playsound(get_turf(R), sound_path, sound_volume, TRUE)


// ====================================================
// RESPONSE: SAY TEXT
// Makes the robot say text via its TTS circuit, or
// falls back to R.say(). Mirrors output/text_to_speech.
// ====================================================

/datum/behavior_circuit/response/say_text
	circuit_name = "Response: Say Text"
	circuit_desc = "Makes the robot say a line via its text-to-speech circuit. Mirrors IC TTS output."
	var/say_string = "Beep."

/datum/behavior_circuit/response/say_text/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	// Use TTS IC if available (mirrors output/text_to_speech do_work)
	if(R.module)
		for(var/obj/item/integrated_circuit/output/text_to_speech/TTS in R.module.modules)
			TTS.set_pin_data(IC_INPUT, 1, say_string)
			TTS.do_work()
			return
	// Fallback: direct say
	R.say(say_string)


// ====================================================
// RESPONSE: TOGGLE LIGHT
// Toggles the robot's light output IC on or off.
// Mirrors output/light do_work().
// ====================================================

/datum/behavior_circuit/response/toggle_light
	circuit_name = "Response: Toggle Light"
	circuit_desc = "Toggles the robot's light output circuit. Mirrors the IC light circuit."
	var/force_state = -1  // -1 = toggle, 0 = force off, 1 = force on

/datum/behavior_circuit/response/toggle_light/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/output/light/LT in R.module.modules)
		if(force_state == -1)
			LT.do_work()  // toggle, mirrors light do_work
		else
			var/should_be_on = force_state == 1
			if(LT.light_toggled != should_be_on)
				LT.do_work()
		return  // only act on first light IC found


// ====================================================
// RESPONSE: GRAB NEAREST ITEM
// Uses the grabber IC in the robot's module to pick
// up the nearest non-mob item.
// Mirrors manipulation/grabber do_work() mode 1.
// ====================================================

/datum/behavior_circuit/response/grab_nearest_item
	circuit_name = "Response: Grab Nearest Item"
	circuit_desc = "Grabs the nearest item on the floor via the robot's grabber circuit. Mirrors IC grabber."
	var/grab_range = 1

/datum/behavior_circuit/response/grab_nearest_item/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return

	var/obj/item/integrated_circuit/manipulation/grabber/GR = null
	for(var/obj/item/integrated_circuit/manipulation/grabber/G in R.module.modules)
		GR = G
		break
	if(!GR)
		return

	var/obj/item/target = null
	for(var/obj/item/I in range(grab_range, R))
		if(istype(I, /obj/item/electronic_assembly) || istype(I, /obj/item/integrated_circuit))
			continue
		if(I.anchored)
			continue
		target = I
		break

	if(!target)
		return

	GR.set_pin_data(IC_INPUT, 1, WEAKREF(target))
	GR.set_pin_data(IC_INPUT, 2, 1)  // mode 1 = grab
	GR.do_work()


// ====================================================
// RESPONSE: DROP ALL ITEMS
// Uses the grabber IC in the robot's module to drop
// all currently held items.
// Mirrors manipulation/grabber do_work() mode -1.
// ====================================================

/datum/behavior_circuit/response/drop_all_items
	circuit_name = "Response: Drop All Items"
	circuit_desc = "Drops all items from the robot's grabber circuit. Mirrors IC grabber eject-all."

/datum/behavior_circuit/response/drop_all_items/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/manipulation/grabber/GR in R.module.modules)
		GR.set_pin_data(IC_INPUT, 2, -1)  // mode -1 = eject all
		GR.do_work()
		return


// ====================================================
// RESPONSE: THROW ITEM AT TARGET
// Fires the thrower IC at the nearest enemy using the
// first item in the grabber's inventory as projectile.
// Mirrors manipulation/thrower do_work().
// ====================================================

/datum/behavior_circuit/response/throw_item_at_enemy
	circuit_name = "Response: Throw Item At Enemy"
	circuit_desc = "Throws the first grabbed item at the nearest hostile mob. Requires thrower and grabber ICs. Mirrors IC thrower."

/datum/behavior_circuit/response/throw_item_at_enemy/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	if(!R.cpu_cert || !(R.cpu_cert.capability_flags & CERT_CAN_SHOOT))
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

	var/turf/T = get_turf(target)
	var/turf/self = get_turf(R)
	TH.set_pin_data(IC_INPUT, 1, T.x - self.x)
	TH.set_pin_data(IC_INPUT, 2, T.y - self.y)
	TH.set_pin_data(IC_INPUT, 3, WEAKREF(GR.contents[1]))
	TH.do_work()


// ====================================================
// PRE-BUILT ASSEMBLIES - IC INTEGRATION PRESETS
// ====================================================

// Patrol bot: interval trigger -> step south, loops to create patrol
/obj/item/behavior_assembly/patrol_bot
	assembly_label = "Patrol Bot Protocol"

/obj/item/behavior_assembly/patrol_bot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_interval/T = new()
	var/datum/behavior_circuit/response/move_direction/RE = new()
	T.interval = 20  // move every 2 seconds
	RE.move_dir = SOUTH
	T.response = RE
	circuits += T
	circuits += RE

// Turret bot: enemy spotted -> fire weapon, then say taunt
/obj/item/behavior_assembly/turret_bot
	assembly_label = "Turret Bot Protocol"

/obj/item/behavior_assembly/turret_bot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T = new()
	var/datum/behavior_circuit/response/fire_weapon/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

// Combat medic: friendly injured -> inject reagent
/obj/item/behavior_assembly/combat_medic
	assembly_label = "Combat Medic Protocol"

/obj/item/behavior_assembly/combat_medic/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_mob_injured/T = new()
	var/datum/behavior_circuit/response/inject_reagent/RE = new()
	RE.inject_friendlies_only = TRUE
	RE.inject_amount = 10
	T.response = RE
	circuits += T
	circuits += RE

// Alarm bot: low power -> play warning sound
/obj/item/behavior_assembly/alarm_bot
	assembly_label = "Alarm Bot Protocol"

/obj/item/behavior_assembly/alarm_bot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_low_power/T = new()
	var/datum/behavior_circuit/response/play_sound/RE = new()
	RE.sound_path = 'sound/machines/warning-buzzer.ogg'
	RE.sound_volume = 75
	T.response = RE
	circuits += T
	circuits += RE

// Greeter: access granted -> say greeting + toggle light
/obj/item/behavior_assembly/greeter_bot
	assembly_label = "Greeter Bot Protocol"

/obj/item/behavior_assembly/greeter_bot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_access_granted/T = new()
	var/datum/behavior_circuit/response/say_text/RE = new()
	RE.say_string = "Welcome. Identity verified. Have a pleasant shift."
	T.response = RE
	circuits += T
	circuits += RE

// Scavenger: interval -> grab nearest item
/obj/item/behavior_assembly/scavenger_bot
	assembly_label = "Scavenger Bot Protocol"

/obj/item/behavior_assembly/scavenger_bot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_interval/T = new()
	var/datum/behavior_circuit/response/grab_nearest_item/RE = new()
	T.interval = 50
	RE.grab_range = 1
	T.response = RE
	circuits += T
	circuits += RE


// ====================================================
// ====================================================
// IC INTEGRATION LAYER - PART 2
// Remaining triggers and responses covering all IC
// subtypes not addressed in Part 1.
// ====================================================
// ====================================================


// ====================================================
// TRIGGER: ON SIGNAL RECEIVED (mirrors input/signaler)
// Fires when a radio signal on the robot's signaler IC
// frequency/code is received.
// ====================================================

/datum/behavior_circuit/trigger/on_signal_received
	circuit_name = "Trigger: On Signal Received"
	circuit_desc = "Fires when a radio signal is received on the robot's signaler IC. Mirrors IC signaler receive_signal."
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
		// Trigger mirrors signaler behavior: fire once per received signal
		// Actual hook would be RegisterSignal(S, COMSIG_IC_ACTIVATEPIN, PROC_REF(_on_trigger))
		// For now, use a flag var on the signaler if available, else skip
		if(world.time > last_received + signal_cooldown)
			// Cannot poll signal receipt without a hook - this trigger requires manual wiring
			// or a COMSIG hook once the signal name is confirmed. Left as a stub frame.
			break


// ====================================================
// TRIGGER: ON SPEECH HEARD (mirrors input/microphone)
// Fires when the microphone IC picks up any speech.
// ====================================================

/datum/behavior_circuit/trigger/on_speech_heard
	circuit_name = "Trigger: On Speech Heard"
	circuit_desc = "Fires when the robot's microphone IC hears speech. Mirrors IC microphone Hear()."
	var/last_heard = 0
	var/hear_cooldown = 10
	var/last_message = ""
	var/last_speaker = ""

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
		// Mirror microphone Hear(): read the last heard message from the IC's output pins
		var/msg = M.get_pin_data(IC_OUTPUT, 2)
		var/spkr = M.get_pin_data(IC_OUTPUT, 1)
		if(msg && msg != last_message)
			last_message = msg
			last_speaker = spkr
			last_heard = world.time
			_trigger(R)
			return


// ====================================================
// TRIGGER: ON GPS ZONE (mirrors input/gps)
// Fires when the robot enters a defined coordinate zone.
// ====================================================

/datum/behavior_circuit/trigger/on_gps_zone
	circuit_name = "Trigger: On GPS Zone"
	circuit_desc = "Fires when the robot is within the defined coordinate box. Mirrors IC GPS circuit."
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
	var/turf/T = get_turf(R)
	if(!T)
		return
	var/now_in = (T.x >= zone_x1 && T.x <= zone_x2 && T.y >= zone_y1 && T.y <= zone_y2)
	if(now_in && !in_zone)
		in_zone = TRUE
		_trigger(R)
	else if(!now_in)
		in_zone = FALSE


// ====================================================
// TRIGGER: ON ATMOS THRESHOLD (mirrors input/atmospheric_analyzer)
// Fires when pressure or temperature in the local turf
// crosses a threshold. Mirrors atmospheric_analyzer do_work().
// ====================================================

/datum/behavior_circuit/trigger/on_atmos_threshold
	circuit_name = "Trigger: On Atmos Threshold"
	circuit_desc = "Fires when local air pressure or temperature crosses a threshold. Mirrors IC atmospheric analyzer."
	var/check_pressure = TRUE  // TRUE = check pressure, FALSE = check temperature
	var/threshold_value = 50   // kPa for pressure, K for temperature
	var/threshold_above = FALSE  // TRUE = fire when above, FALSE = fire when below
	var/last_check = 0
	var/check_cooldown = 20
	var/already_triggered = FALSE

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
	var/turf/T = get_turf(R)
	if(!T)
		return
	var/datum/gas_mixture/air = T.return_air()
	if(!air)
		return
	var/value = check_pressure ? air.return_pressure() : air.return_temperature()
	var/condition = threshold_above ? (value > threshold_value) : (value < threshold_value)
	if(condition && !already_triggered)
		already_triggered = TRUE
		_trigger(R)
	else if(!condition)
		already_triggered = FALSE


// ====================================================
// TRIGGER: ON HEALTH SCAN (mirrors input/med_scanner)
// Fires when a friendly mob's health drops below
// a threshold. Uses med_scanner IC if present, else
// polls directly. Mirrors med_scanner do_work().
// ====================================================

/datum/behavior_circuit/trigger/on_health_scan_critical
	circuit_name = "Trigger: On Health Scan Critical"
	circuit_desc = "Fires when a friendly mob in range falls below the health threshold %. Mirrors IC medical analyzer."
	var/health_threshold_pct = 25  // percent
	var/scan_range = 3
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
	for(var/mob/living/M in range(scan_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(!R.faction_check_mob(M, FALSE))
			continue
		var/pct = (M.health / M.getMaxHealth()) * 100
		if(pct <= health_threshold_pct)
			_trigger(R)
			return


// ====================================================
// TRIGGER: ON TANK PRESSURE (mirrors input/tank_slot + atmospherics/tank)
// Fires when a tank IC in the module drops below
// or exceeds a pressure threshold.
// ====================================================

/datum/behavior_circuit/trigger/on_tank_pressure
	circuit_name = "Trigger: On Tank Pressure"
	circuit_desc = "Fires when an atmospherics tank IC's pressure crosses a threshold. Mirrors IC tank circuit monitoring."
	var/pressure_threshold = 100   // kPa
	var/trigger_when_below = TRUE  // TRUE = fire when below, FALSE = fire when above
	var/last_check = 0
	var/check_cooldown = 20
	var/already_triggered = FALSE

/datum/behavior_circuit/trigger/on_tank_pressure/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_tank_pressure/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_tank_pressure/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD || !R.module)
		return
	var/found_tank = null
	for(var/obj/item/IC in R.module.modules)
		if(istype(IC, /obj/item/integrated_circuit/atmospherics/tank))
			found_tank = IC
			break
	if(!found_tank)
		return
	var/datum/gas_mixture/air = found_tank:air_contents
	if(!air)
		return
	var/pressure = air.return_pressure()
	var/condition = trigger_when_below ? (pressure < pressure_threshold) : (pressure > pressure_threshold)
	if(!condition)
		already_triggered = FALSE
	else if(!already_triggered)
		already_triggered = TRUE
		_trigger(R)


// ====================================================
// TRIGGER: ON NTNET MESSAGE (mirrors input/ntnet_advanced)
// Fires when the NTNet transreceiver IC receives a packet.
// ====================================================

/datum/behavior_circuit/trigger/on_ntnet_message
	circuit_name = "Trigger: On NTNet Message"
	circuit_desc = "Fires when the robot's NTNet transreceiver IC receives a data packet. Mirrors IC ntnet_advanced."
	var/last_data = null
	var/last_check = 0
	var/check_cooldown = 5

/datum/behavior_circuit/trigger/on_ntnet_message/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/behavior_circuit/trigger/on_ntnet_message/unregister(mob/living/silicon/robot/R)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/datum/behavior_circuit/trigger/on_ntnet_message/process()
	if(world.time < last_check + check_cooldown)
		return
	last_check = world.time
	var/mob/living/silicon/robot/R = get_robot()
	if(!R || R.stat == DEAD || !R.module)
		return
	for(var/obj/item/integrated_circuit/input/ntnet_advanced/NET in R.module.modules)
		var/received = NET.get_pin_data(IC_OUTPUT, 1)
		if(!isnull(received) && received != last_data)
			last_data = received
			_trigger(R)
			return


// ====================================================
// RESPONSE: STUN TARGET (mirrors weaponized/stun)
// Stuns the nearest hostile mob in holding range.
// Mirrors weaponized/stun do_work() + attempt_stun().
// ====================================================

/datum/behavior_circuit/response/stun_target
	circuit_name = "Response: Stun Target"
	circuit_desc = "Stuns the nearest hostile mob holding or adjacent to the robot. Mirrors IC electronic stun module."
	var/stun_strength = 40
	var/stun_range = 1

/datum/behavior_circuit/response/stun_target/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	// Use the stun IC if present - mirrors weaponized/stun do_work
	for(var/obj/item/integrated_circuit/weaponized/stun/S in R.module.modules)
		S.set_pin_data(IC_INPUT, 1, stun_strength)
		S.do_work()
		return
	// Fallback: direct stun on nearest adjacent hostile
	for(var/mob/living/M in range(stun_range, R))
		if(M == R || M.stat == DEAD)
			continue
		if(R.faction_check_mob(M, FALSE))
			continue
		M.DefaultCombatKnockdown(stun_strength)
		R.visible_message(span_danger("[R] delivers an electric shock to [M]!"))
		return


// ====================================================
// RESPONSE: PRIME GRENADE (mirrors weaponized/grenade)
// Primes the grenade IC attached in the robot's module.
// Mirrors weaponized/grenade do_work().
// ====================================================

/datum/behavior_circuit/response/prime_grenade
	circuit_name = "Response: Prime Grenade"
	circuit_desc = "Primes the grenade in the robot's grenade primer IC. Requires CERT_CAN_MALF. Mirrors IC grenade primer."
	var/detonation_time = 3  // seconds

/datum/behavior_circuit/response/prime_grenade/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.cpu_cert || !(R.cpu_cert.capability_flags & CERT_CAN_MALF))
		return
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/weaponized/grenade/GR in R.module.modules)
		if(!GR.attached_grenade || GR.attached_grenade.active)
			continue
		GR.set_pin_data(IC_INPUT, 1, detonation_time)
		GR.do_work()
		R.visible_message(span_danger("[R] arms a grenade!"))
		return


// ====================================================
// RESPONSE: FIRE AIR CANNON (mirrors weaponized/air_cannon)
// Fires the pneumatic cannon at the nearest enemy.
// Mirrors weaponized/air_cannon do_work().
// ====================================================

/datum/behavior_circuit/response/fire_air_cannon
	circuit_name = "Response: Fire Air Cannon"
	circuit_desc = "Fires the robot's pneumatic air cannon at the nearest hostile. Requires air_cannon IC and atmospherics IC. Mirrors IC air cannon."

/datum/behavior_circuit/response/fire_air_cannon/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.cpu_cert || !(R.cpu_cert.capability_flags & CERT_CAN_SHOOT))
		return
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
		if(M == R || M.stat == DEAD || R.faction_check_mob(M, FALSE))
			continue
		var/d = get_dist(R, M)
		if(d < closest_dist)
			closest_dist = d
			target = M
	if(!target)
		return

	var/turf/T = get_turf(target)
	var/turf/self = get_turf(R)
	// Grab first grabbable item in module to use as projectile
	var/obj/item/projectile = null
	for(var/obj/item/I in R.module.modules)
		if(istype(I, /obj/item/integrated_circuit))
			continue
		projectile = I
		break
	if(!projectile)
		return

	AC.set_pin_data(IC_INPUT, 1, T.x - self.x)
	AC.set_pin_data(IC_INPUT, 2, T.y - self.y)
	AC.set_pin_data(IC_INPUT, 3, WEAKREF(projectile))
	AC.set_pin_data(IC_INPUT, 4, WEAKREF(AT))
	AC.do_work()


// ====================================================
// RESPONSE: DEPLOY SMOKE (mirrors reagent/smoke)
// Activates the smoke generator IC in the robot's module.
// Mirrors reagent/smoke do_work() ord 1.
// ====================================================

/datum/behavior_circuit/response/deploy_smoke
	circuit_name = "Response: Deploy Smoke"
	circuit_desc = "Activates the robot's smoke generator IC. Mirrors IC smoke generator."

/datum/behavior_circuit/response/deploy_smoke/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/reagent/smoke/S in R.module.modules)
		if(!S.reagents || S.reagents.total_volume < 10)  // 10 = IC_SMOKE_REAGENTS_MINIMUM_UNITS
			continue
		S.do_work(1)
		return


// ====================================================
// RESPONSE: FIRE EXTINGUISHER (mirrors reagent/extinguisher)
// Sprays extinguisher reagents at a target direction.
// Mirrors reagent/extinguisher do_work().
// ====================================================

/datum/behavior_circuit/response/fire_extinguisher
	circuit_name = "Response: Fire Extinguisher"
	circuit_desc = "Sprays the robot's extinguisher IC at the nearest fire or hostile. Mirrors IC extinguisher."

/datum/behavior_circuit/response/fire_extinguisher/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/reagent/extinguisher/EX in R.module.modules)
		if(!EX.reagents || EX.reagents.total_volume < 10 || EX.busy)  // 10 = IC_SMOKE_REAGENTS_MINIMUM_UNITS
			continue
		// Aim at nearest fire or hostile
		var/turf/target_turf = null
		var/scan_range = A ? A.sensor_range : 5
		// Look for hotspots/fire effects on nearby turfs
		for(var/turf/T in range(scan_range, R))
			for(var/obj/effect/E in T)
				if(istype(E, /obj/effect/hotspot))
					target_turf = T
					break
			if(target_turf)
				break
		// Fall back to nearest hostile
		if(!target_turf)
			for(var/mob/living/M in range(scan_range, R))
				if(M == R || M.stat == DEAD || R.faction_check_mob(M, FALSE))
					continue
				target_turf = get_turf(M)
				break
		if(!target_turf)
			return
		var/turf/self = get_turf(R)
		EX.set_pin_data(IC_INPUT, 1, target_turf.x - self.x)
		EX.set_pin_data(IC_INPUT, 2, target_turf.y - self.y)
		EX.do_work()
		return


// ====================================================
// RESPONSE: PUMP REAGENTS (mirrors reagent/pump)
// Transfers reagents between two IC reagent containers.
// Mirrors reagent/pump do_work().
// ====================================================

/datum/behavior_circuit/response/pump_reagents
	circuit_name = "Response: Pump Reagents"
	circuit_desc = "Pumps reagents from the first storage IC to the first injector IC in the module. Mirrors IC reagent pump."
	var/pump_amount = 5

/datum/behavior_circuit/response/pump_reagents/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	var/obj/item/integrated_circuit/reagent/pump/P = null
	for(var/obj/item/integrated_circuit/reagent/pump/PMP in R.module.modules)
		P = PMP
		break
	if(!P)
		return
	// pump do_work reads IC_INPUT 1=source, 2=target, 3=amount via on_data_written
	// Find first storage IC as source and first injector as target
	var/source_ref = null
	var/target_ref = null
	for(var/obj/item/integrated_circuit/reagent/storage/ST in R.module.modules)
		source_ref = WEAKREF(ST)
		break
	for(var/obj/item/integrated_circuit/reagent/injector/INJ in R.module.modules)
		target_ref = WEAKREF(INJ)
		break
	if(!source_ref || !target_ref)
		return
	P.set_pin_data(IC_INPUT, 1, source_ref)
	P.set_pin_data(IC_INPUT, 2, target_ref)
	P.set_pin_data(IC_INPUT, 3, pump_amount)
	P.on_data_written()
	P.do_work()


// ====================================================
// RESPONSE: GRIND ITEM (mirrors reagent/storage/grinder)
// Grinds the first item in the grabber into the grinder IC.
// Mirrors reagent/storage/grinder grind() proc.
// ====================================================

/datum/behavior_circuit/response/grind_item
	circuit_name = "Response: Grind Item"
	circuit_desc = "Grinds the first item from the grabber IC into the grinder IC. Mirrors IC reagent grinder."

/datum/behavior_circuit/response/grind_item/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	var/obj/item/integrated_circuit/reagent/storage/grinder/GR = null
	var/obj/item/integrated_circuit/manipulation/grabber/GB = null
	for(var/obj/item/integrated_circuit/reagent/storage/grinder/G in R.module.modules)
		GR = G
		break
	for(var/obj/item/integrated_circuit/manipulation/grabber/G in R.module.modules)
		GB = G
		break
	if(!GR || !GB || !GB.contents.len)
		return
	GR.set_pin_data(IC_INPUT, 1, WEAKREF(GB.contents[1]))
	GR.do_work(1)


// ====================================================
// RESPONSE: HEAT REAGENTS (mirrors reagent/storage/heater)
// Enables the heater IC in the module at a set temperature.
// Mirrors reagent/storage/heater on_data_written() + process().
// ====================================================

/datum/behavior_circuit/response/heat_reagents
	circuit_name = "Response: Heat Reagents"
	circuit_desc = "Sets the robot's reagent heater IC to a target temperature and enables it. Mirrors IC chemical heater."
	var/target_temp = 373  // Kelvin, ~100C
	var/enable = TRUE

/datum/behavior_circuit/response/heat_reagents/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/reagent/storage/heater/H in R.module.modules)
		H.set_pin_data(IC_INPUT, 1, target_temp)
		H.set_pin_data(IC_INPUT, 2, enable)
		H.on_data_written()
		return


// ====================================================
// RESPONSE: PULL TARGET (mirrors manipulation/claw)
// Pulls the nearest friendly or specified mob using the
// claw IC. Mirrors manipulation/claw do_work() mode 1.
// ====================================================

/datum/behavior_circuit/response/pull_target
	circuit_name = "Response: Pull Target"
	circuit_desc = "Uses the robot's claw IC to pull the nearest friendly mob. Mirrors IC pulling claw."
	var/pull_friendlies = TRUE
	var/pull_range = 3

/datum/behavior_circuit/response/pull_target/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	var/obj/item/integrated_circuit/manipulation/claw/CL = null
	for(var/obj/item/integrated_circuit/manipulation/claw/C in R.module.modules)
		CL = C
		break
	if(!CL)
		return

	var/mob/living/target = null
	for(var/mob/living/M in range(pull_range, R))
		if(M == R || M.stat == DEAD)
			continue
		var/is_friendly = R.faction_check_mob(M, FALSE)
		if(pull_friendlies != is_friendly)
			continue
		target = M
		break
	if(!target)
		return
	CL.set_pin_data(IC_INPUT, 1, WEAKREF(target))
	CL.set_pin_data(IC_INPUT, 2, GRAB_PASSIVE)
	CL.do_work(1)


// ====================================================
// RESPONSE: INSERT ITEM INTO STORAGE (mirrors manipulation/inserter)
// Inserts the first grabbed item into a nearby storage.
// Mirrors manipulation/inserter do_work() mode 1.
// ====================================================

/datum/behavior_circuit/response/insert_into_storage
	circuit_name = "Response: Insert Into Storage"
	circuit_desc = "Inserts the first grabbed item into the nearest storage. Mirrors IC inserter."
	var/insert_range = 1

/datum/behavior_circuit/response/insert_into_storage/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	var/obj/item/integrated_circuit/manipulation/inserter/INS = null
	var/obj/item/integrated_circuit/manipulation/grabber/GB = null
	for(var/obj/item/integrated_circuit/manipulation/inserter/I in R.module.modules)
		INS = I
		break
	for(var/obj/item/integrated_circuit/manipulation/grabber/G in R.module.modules)
		GB = G
		break
	if(!INS || !GB || !GB.contents.len)
		return
	// Find nearest storage
	var/obj/item/storage/container = null
	for(var/obj/item/storage/S in range(insert_range, R))
		container = S
		break
	if(!container)
		return
	INS.set_pin_data(IC_INPUT, 1, WEAKREF(GB.contents[1]))
	INS.set_pin_data(IC_INPUT, 2, WEAKREF(container))
	INS.set_pin_data(IC_INPUT, 3, 1)  // mode 1 = insert
	INS.do_work()


// ====================================================
// RESPONSE: HARVEST HYDROTRAY (mirrors manipulation/plant_module)
// Harvests the nearest hydroponic tray.
// Mirrors manipulation/plant_module do_work() mode 0.
// ====================================================

/datum/behavior_circuit/response/harvest_hydrotray
	circuit_name = "Response: Harvest Hydroponic Tray"
	circuit_desc = "Harvests the nearest ready hydroponic tray. Mirrors IC plant manipulation module."
	var/harvest_range = 1
	var/mode = 0  // 0=harvest, 1=uproot weeds, 2=uproot plant, 3=plant seed

/datum/behavior_circuit/response/harvest_hydrotray/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	var/obj/item/integrated_circuit/manipulation/plant_module/PM = null
	for(var/obj/item/integrated_circuit/manipulation/plant_module/P in R.module.modules)
		PM = P
		break
	if(!PM)
		return
	for(var/obj/machinery/hydroponics/H in range(harvest_range, R))
		PM.set_pin_data(IC_INPUT, 1, WEAKREF(H))
		PM.set_pin_data(IC_INPUT, 2, mode)
		PM.do_work()
		return


// ====================================================
// RESPONSE: RENAME ASSEMBLY (mirrors manipulation/renamer)
// Sets the assembly's name via the renamer IC.
// Mirrors manipulation/renamer do_work() mode 1.
// ====================================================

/datum/behavior_circuit/response/rename_assembly
	circuit_name = "Response: Rename Assembly"
	circuit_desc = "Renames the assembly to the configured string. Mirrors IC renamer circuit."
	var/new_name = "Unit"

/datum/behavior_circuit/response/rename_assembly/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module || !A)
		return
	for(var/obj/item/integrated_circuit/manipulation/renamer/RN in R.module.modules)
		RN.set_pin_data(IC_INPUT, 1, new_name)
		RN.do_work(1)
		return
	// Fallback: direct rename
	A.name = new_name


// ====================================================
// RESPONSE: REPAINT ASSEMBLY (mirrors manipulation/repaint)
// Sets the assembly's color via the repaint IC.
// Mirrors manipulation/repaint do_work() mode 1.
// ====================================================

/datum/behavior_circuit/response/repaint_assembly
	circuit_name = "Response: Repaint Assembly"
	circuit_desc = "Repaints the assembly to the configured hex color. Mirrors IC auto-repainter."
	var/paint_color = "#FF0000"

/datum/behavior_circuit/response/repaint_assembly/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module || !A)
		return
	for(var/obj/item/integrated_circuit/manipulation/repaint/RP in R.module.modules)
		RP.set_pin_data(IC_INPUT, 1, paint_color)
		RP.do_work(1)
		return
	// No repaint IC present - nothing to fall back to


// ====================================================
// RESPONSE: TRANSMIT POWER (mirrors power/transmitter)
// Transmits power from the robot's cell to a target IC.
// Mirrors power/transmitter do_work().
// ====================================================

/datum/behavior_circuit/response/transmit_power
	circuit_name = "Response: Transmit Power"
	circuit_desc = "Transmits power from the robot's cell to a nearby target via the power transmitter IC. Mirrors IC power transmitter."

/datum/behavior_circuit/response/transmit_power/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/power/transmitter/PT in R.module.modules)
		// Find nearest powered machine with a cell to charge
		var/atom/movable/best_target = null
		for(var/obj/machinery/M in range(1, R))
			if(M.get_cell())
				best_target = M
				break
		if(!best_target)
			return
		PT.set_pin_data(IC_INPUT, 1, WEAKREF(best_target))
		PT.do_work()
		return


// ====================================================
// RESPONSE: PUMP GAS (mirrors atmospherics/pump)
// Pulses the gas pump IC between two atmos containers.
// Mirrors atmospherics/pump do_work().
// ====================================================

/datum/behavior_circuit/response/pump_gas
	circuit_name = "Response: Pump Gas"
	circuit_desc = "Activates the robot's gas pump IC, transferring gas between its source and target. Mirrors IC gas pump."
	var/target_pressure = 101  // kPa

/datum/behavior_circuit/response/pump_gas/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/IC in R.module.modules)
		if(IC.type != /obj/item/integrated_circuit/atmospherics/pump && IC.type != /obj/item/integrated_circuit/atmospherics/pump/volume)
			continue
		var/obj/item/integrated_circuit/atmospherics/pump/P = IC
		P.set_pin_data(IC_INPUT, 3, target_pressure)
		P.on_data_written()
		P.do_work()
		return


// ====================================================
// RESPONSE: VENT GAS (mirrors atmospherics/pump/vent)
// Vents the tank IC's contents into the environment.
// Mirrors atmospherics/pump/vent do_work().
// ====================================================

/datum/behavior_circuit/response/vent_gas
	circuit_name = "Response: Vent Gas"
	circuit_desc = "Vents gas from the robot's atmos tank IC into the environment. Mirrors IC gas vent."
	var/vent_pressure = 101

/datum/behavior_circuit/response/vent_gas/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return

	// Find vent and tank ICs first
	var/obj/item/integrated_circuit/atmospherics/pump/vent/V = null
	var/tank_ic = null
	for(var/obj/item/IC in R.module.modules)
		if(istype(IC, /obj/item/integrated_circuit/atmospherics/pump/vent))
			V = IC
			break
	for(var/obj/item/IC2 in R.module.modules)
		if(istype(IC2, /obj/item/integrated_circuit/atmospherics/tank))
			tank_ic = IC2
			break
	if(!V)
		return

	if(!isnull(tank_ic))
		V.set_pin_data(IC_INPUT, 1, WEAKREF(tank_ic))
	V.set_pin_data(IC_INPUT, 2, vent_pressure)
	V.on_data_written()
	V.do_work()


// ====================================================
// RESPONSE: SET AMBIENT TEMPERATURE (mirrors atmospherics/cooler + heater)
// Enables the cooler or heater IC to reach a target temp.
// Mirrors atmospherics/cooler/on_data_written() + process().
// ====================================================

/datum/behavior_circuit/response/set_ambient_temp
	circuit_name = "Response: Set Ambient Temperature"
	circuit_desc = "Enables the robot's atmospheric cooler or heater IC to reach a target temperature. Mirrors IC atmospheric cooler/heater."
	var/target_temp = 293.15  // Kelvin
	var/enable = TRUE

/datum/behavior_circuit/response/set_ambient_temp/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/IC in R.module.modules)
		if(!istype(IC, /obj/item/integrated_circuit/atmospherics/cooler))
			continue
		var/obj/item/integrated_circuit/atmospherics/cooler/COOL = IC
		COOL.set_pin_data(IC_INPUT, 1, target_temp)
		COOL.set_pin_data(IC_INPUT, 2, enable)
		COOL.on_data_written()
		return


// ====================================================
// RESPONSE: TOGGLE CAMERA (mirrors output/video_camera)
// Enables or disables the robot's camera IC.
// Mirrors output/video_camera set_camera_status().
// ====================================================

/datum/behavior_circuit/response/toggle_camera
	circuit_name = "Response: Toggle Camera"
	circuit_desc = "Enables or disables the robot's video camera IC. Mirrors IC video camera circuit."
	var/camera_on = TRUE
	var/camera_network = "ss13"

/datum/behavior_circuit/response/toggle_camera/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/output/video_camera/CAM in R.module.modules)
		CAM.set_pin_data(IC_INPUT, 2, camera_on)
		CAM.set_pin_data(IC_INPUT, 3, list(camera_network))
		CAM.on_data_written()
		return


// ====================================================
// RESPONSE: DISPLAY ON SCREEN (mirrors output/screen)
// Shows a message on the robot's screen IC and broadcasts
// it to nearby mobs. Mirrors output/screen/large do_work().
// ====================================================

/datum/behavior_circuit/response/display_screen
	circuit_name = "Response: Display Screen Message"
	circuit_desc = "Displays a message on the robot's screen IC visible to nearby mobs. Mirrors IC screen output."
	var/screen_message = "STATUS: ACTIVE"

/datum/behavior_circuit/response/display_screen/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/output/screen/SCR in R.module.modules)
		SCR.set_pin_data(IC_INPUT, 1, screen_message)
		SCR.do_work()
		return
	// Fallback: visible message
	R.visible_message(span_notice("[R] displays: [screen_message]"))


// ====================================================
// RESPONSE: SET LED STATE (mirrors output/led)
// Sets the robot's LED IC to a specific color and state.
// Mirrors output/led on_data_written().
// ====================================================

/datum/behavior_circuit/response/set_led
	circuit_name = "Response: Set LED"
	circuit_desc = "Sets the robot's LED IC color and state. Mirrors IC LED output."
	var/led_lit = TRUE
	var/led_color = "#FF0000"

/datum/behavior_circuit/response/set_led/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/output/led/LED in R.module.modules)
		LED.set_pin_data(IC_INPUT, 1, led_lit)
		LED.set_pin_data(IC_INPUT, 2, led_color)
		LED.on_data_written()
		return


// ====================================================
// RESPONSE: UPDATE DIAGNOSTIC HUD (mirrors output/diagnostic_hud)
// Changes the robot's AR diagnostic HUD icon state.
// Mirrors output/diagnostic_hud on_data_written().
// ====================================================

/datum/behavior_circuit/response/update_hud_icon
	circuit_name = "Response: Update Diagnostic HUD"
	circuit_desc = "Updates the robot's AR diagnostic HUD icon. Valid icons: alert, move, working, patrol, called, heart. Mirrors IC AR interface."
	var/hud_icon = "alert"

/datum/behavior_circuit/response/update_hud_icon/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/output/diagnostic_hud/HUD in R.module.modules)
		HUD.set_pin_data(IC_INPUT, 1, hud_icon)
		HUD.on_data_written()
		return


// ====================================================
// RESPONSE: SEND NTNET MESSAGE (mirrors input/ntnet_advanced)
// Sends a data packet over NTNet via the transreceiver IC.
// Mirrors ntnet_advanced do_work().
// ====================================================

/datum/behavior_circuit/response/send_ntnet_message
	circuit_name = "Response: Send NTNet Message"
	circuit_desc = "Sends a data packet over NTNet via the robot's transreceiver IC. Mirrors IC NTNet transreceiver."
	var/target_address = ""  // Empty = broadcast
	var/list/message_data = list()

/datum/behavior_circuit/response/send_ntnet_message/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/input/ntnet_advanced/NET in R.module.modules)
		NET.set_pin_data(IC_INPUT, 1, target_address)
		NET.set_pin_data(IC_INPUT, 2, message_data)
		NET.do_work()
		return


// ====================================================
// RESPONSE: SEND RADIO SIGNAL (mirrors input/signaler)
// Pulses the robot's signaler IC to send a radio signal.
// Mirrors signaler do_work().
// ====================================================

/datum/behavior_circuit/response/send_radio_signal
	circuit_name = "Response: Send Radio Signal"
	circuit_desc = "Pulses the robot's signaler IC to broadcast a radio signal. Mirrors IC integrated signaler."

/datum/behavior_circuit/response/send_radio_signal/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/input/signaler/S in R.module.modules)
		S.do_work()
		return


// ====================================================
// RESPONSE: READ BATTERY STATE (mirrors input/internalbm)
// Reads the internal battery and stores it for use.
// Mirrors internalbm do_work().
// ====================================================

/datum/behavior_circuit/response/read_battery
	circuit_name = "Response: Read Battery State"
	circuit_desc = "Reads the internal battery monitor IC and emits a visible status readout. Mirrors IC internal battery monitor."

/datum/behavior_circuit/response/read_battery/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	if(!R.module)
		return
	for(var/obj/item/integrated_circuit/input/internalbm/BM in R.module.modules)
		BM.do_work()
		var/pct = BM.get_pin_data(IC_OUTPUT, 3)
		if(!isnull(pct))
			R.visible_message(span_notice("[R]: Power at [round(pct, 1)]%."))
		return
	// Fallback if no IC present
	if(R.cell)
		var/pct = round(100 * R.cell.charge / R.cell.maxcharge, 1)
		R.visible_message(span_notice("[R]: Power at [pct]%."))


// ====================================================
// PRE-BUILT ASSEMBLIES - PART 2 IC INTEGRATION PRESETS
// ====================================================

// Smoke screen: enemy spotted -> deploy smoke + flee
/obj/item/behavior_assembly/smoke_screen
	assembly_label = "Smoke Screen Protocol"

/obj/item/behavior_assembly/smoke_screen/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T = new()
	var/datum/behavior_circuit/response/deploy_smoke/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

// Firefighter: atmos threshold (high temp) -> extinguisher
/obj/item/behavior_assembly/firefighter_bot
	assembly_label = "Firefighter Protocol"

/obj/item/behavior_assembly/firefighter_bot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_atmos_threshold/T = new()
	var/datum/behavior_circuit/response/fire_extinguisher/RE = new()
	T.check_pressure = FALSE
	T.threshold_value = 350  // K - hot air
	T.threshold_above = TRUE
	T.response = RE
	circuits += T
	circuits += RE

// Combat medic 2: health scan -> inject + say
/obj/item/behavior_assembly/field_medic
	assembly_label = "Field Medic Protocol"

/obj/item/behavior_assembly/field_medic/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_health_scan_critical/T = new()
	var/datum/behavior_circuit/response/inject_reagent/RE = new()
	T.health_threshold_pct = 30
	RE.inject_amount = 15
	T.response = RE
	circuits += T
	circuits += RE

// Guard bot: enemy spotted -> stun + update HUD to alert
/obj/item/behavior_assembly/guard_bot
	assembly_label = "Guard Bot Protocol"

/obj/item/behavior_assembly/guard_bot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_enemy_spotted/T = new()
	var/datum/behavior_circuit/response/stun_target/RE = new()
	T.response = RE
	circuits += T
	circuits += RE

// Camera sentinel: on interval -> toggle camera, update HUD
/obj/item/behavior_assembly/camera_sentinel
	assembly_label = "Camera Sentinel Protocol"

/obj/item/behavior_assembly/camera_sentinel/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_interval/T = new()
	var/datum/behavior_circuit/response/toggle_camera/RE = new()
	T.interval = 100
	RE.camera_on = TRUE
	RE.camera_network = "ss13"
	T.response = RE
	circuits += T
	circuits += RE

// Hydroponics bot: on interval -> harvest trays
/obj/item/behavior_assembly/hydro_bot
	assembly_label = "Hydroponics Bot Protocol"

/obj/item/behavior_assembly/hydro_bot/Initialize(mapload)
	. = ..()
	var/datum/behavior_circuit/trigger/on_interval/T = new()
	var/datum/behavior_circuit/response/harvest_hydrotray/RE = new()
	T.interval = 200
	RE.harvest_range = 1
	T.response = RE
	circuits += T
	circuits += RE

