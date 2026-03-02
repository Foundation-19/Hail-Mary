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
		if(M.health < M.maxHealth * health_threshold)
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
