// ====================================================
// ROBOT HARDWARE HOOKS
// Runtime state vars and procs added to hardware datums
// so that behavior circuits can read them via get_hardware().
//
// IMPORTANT: This file only declares vars and procs that do
// NOT already exist in robot_hardware.dm. All config vars
// (lethal_mode, fire_range, stun_range, etc.) live in
// robot_hardware.dm. This file adds only the live runtime
// state written during robot operation.
//
// File: code/modules/integrated_electronics/robot_hardware_hooks.dm
// ====================================================


// ====================================================
// WEAPON - runtime fire tracking
// ====================================================

/datum/robot_hardware/weapon
	/// world.time of last shot fired. Written by fire_at().
	/// Read by on_weapon_fired trigger.
	var/last_fire_time = 0
	/// Range bonus tiles added at build time from builder PER.
	var/fire_range_bonus = 0

/// Fire the weapon at a target. Locates or spawns the gun,
/// aims the robot, and sends a projectile toward the target.
/datum/robot_hardware/weapon/proc/fire_at(mob/living/silicon/robot/R, mob/living/target)
	if(!target || !R || !gun_type)
		return
	var/obj/item/gun/G = locate(gun_type) in R
	if(!G)
		G = new gun_type(R)
	if(!G)
		return
	last_fire_time = world.time
	R.setDir(get_dir(R, target))
	var/turf/T = get_turf(target)
	if(!T)
		return
	var/obj/item/projectile/P = new /obj/item/projectile(T)
	P.preparePixelProjectile(T, R, null)
	P.fire()
	R.visible_message(span_danger("[R] fires [G] at [target]!"))


// ====================================================
// MICROPHONE - runtime hear state
// ====================================================

/datum/robot_hardware/microphone
	/// Last speech message detected. Written by on_hear().
	/// Read by on_speech_heard trigger.
	var/last_heard_message = ""
	/// world.time when last_heard_message was written.
	var/last_heard_time = 0

/// Called by hardware_on_hear() when speech is detected nearby.
/// Filters by trigger_phrase if set.
/datum/robot_hardware/microphone/proc/on_hear(mob/speaker, msg)
	if(!msg)
		return
	if(trigger_phrase && !findtext(msg, trigger_phrase))
		return
	last_heard_message = msg
	last_heard_time = world.time


// ====================================================
// SIGNALER - runtime receive state
// ====================================================

/datum/robot_hardware/signaler
	/// world.time of last matching signal received.
	/// Read by on_signal_received trigger.
	var/last_received_time = 0

/// Called by hardware_on_receive_signal() when a matching
/// radio signal arrives.
/datum/robot_hardware/signaler/proc/on_receive_signal(datum/signal/sig)
	if(!sig)
		return
	if(sig.data["code"] && sig.data["code"] != code)
		return
	last_received_time = world.time

/// Transmit a signal on our frequency/code via the robot's
/// signaler_connection (registered in signaler/install).
/datum/robot_hardware/signaler/proc/send_signal(mob/living/silicon/robot/R)
	if(!R || !R.signaler_connection)
		return
	var/datum/radio_frequency/RF = R.signaler_connection
	if(!RF)
		return
	var/datum/signal/sig = new()
	sig.data["frequency"] = frequency
	sig.data["code"]      = code
	sig.data["signal"]    = "ACTIVATE"
	RF.post_signal(R, sig)


// ====================================================
// ID READER - runtime scan state
// ====================================================

/datum/robot_hardware/id_reader
	/// world.time of last successful ID scan.
	/// Written by hardware_on_id_scan(). Read by on_access_granted.
	var/last_scan_time = 0
	/// Weakref to the last scanned ID card.
	var/datum/weakref/last_scanned_ref = null


// ====================================================
// INJECTOR - reagent tank lifecycle
// ====================================================

/datum/robot_hardware/injector
	/// Reference to the borghypo created at install time.
	/// Read by inject_reagent and offer_drink circuits via INJ.reagent_tank.
	var/obj/item/reagent_containers/borghypo/reagent_tank = null


// ====================================================
// REAGENT PUMP - runtime state
// ====================================================

/datum/robot_hardware/reagent_pump
	/// Units transferred per pump activation (alias read by circuits).
	var/pump_amount = 10


// ====================================================
// DISPLAY SCREEN - current text state
// ====================================================

/datum/robot_hardware/display_screen
	/// Currently displayed text. Written by display_screen response.
	var/current_text = "ONLINE"


// ====================================================
// ROBOT MOB HOOKS
// Route live events into installed hardware datums.
// Call these from robot.dm's hear(), attackby(), etc.
// ====================================================

/// Route speech to any installed microphone hardware.
/// Call from /mob/living/silicon/robot/hear() in robot.dm.
/mob/living/silicon/robot/proc/hardware_on_hear(mob/speaker, msg)
	if(!installed_hardware)
		return
	for(var/datum/robot_hardware/microphone/MIC in installed_hardware)
		MIC.on_hear(speaker, msg)

/// Notify id_reader hardware of a successful ID scan.
/// Call from attackby() when an ID card is used on the robot.
/mob/living/silicon/robot/proc/hardware_on_id_scan(obj/item/card/id/ID)
	if(!installed_hardware)
		return
	for(var/datum/robot_hardware/id_reader/IDR in installed_hardware)
		IDR.last_scan_time = world.time
		IDR.last_scanned_ref = WEAKREF(ID)

/// Route incoming radio signals to signaler hardware.
/// Call from the robot's receive_signal() proc.
/mob/living/silicon/robot/proc/hardware_on_receive_signal(datum/signal/sig)
	if(!installed_hardware)
		return
	for(var/datum/robot_hardware/signaler/SIG in installed_hardware)
		SIG.on_receive_signal(sig)
