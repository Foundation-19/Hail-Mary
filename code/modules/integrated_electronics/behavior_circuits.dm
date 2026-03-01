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
