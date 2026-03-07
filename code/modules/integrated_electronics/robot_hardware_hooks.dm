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

/// Fire the weapon at a target. Locates the installed gun and fires it
/// using the gun's standard shoot proc so damage/ammo/sound all apply correctly.
/datum/robot_hardware/weapon/proc/fire_at(mob/living/silicon/robot/R, mob/living/target)
	if(!target || !R || !gun_type)
		return
	// Range gate: don't fire at targets beyond fire_range + any bonus
	var/effective_range = fire_range + fire_range_bonus
	if(get_dist(R, target) > effective_range)
		return
	// Locate the installed gun; create it if not yet spawned
	var/obj/item/gun/G = null
	for(var/obj/item/gun/candidate in R)
		if(istype(candidate, gun_type))
			G = candidate
			break
	if(!G)
		G = new gun_type(R)
	if(!G)
		return
	last_fire_time = world.time
	R.setDir(get_dir(R, target))
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return
	// Use the gun's afterattack so ammo consumption, sound, and projectile type all work
	G.afterattack(target, R, TRUE)
	R.visible_message(span_danger("[R] fires [G.name] at [target]!"))


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
	/// Internal reagent tank. Created at install time.
	var/obj/item/reagent_containers/reagent_tank = null

/datum/robot_hardware/injector/install(mob/living/silicon/robot/R)
	. = ..()
	if(!reagent_tank)
		reagent_tank = new /obj/item/reagent_containers/glass/beaker/large(R)


// ====================================================
// REAGENT PUMP - pump tank lifecycle
// ====================================================

/datum/robot_hardware/reagent_pump
	/// Internal pump tank. Created at install time.
	var/obj/item/reagent_containers/pump_tank = null
	/// Units transferred per pump activation.
	var/pump_amount = 10

/datum/robot_hardware/reagent_pump/install(mob/living/silicon/robot/R)
	. = ..()
	if(!pump_tank)
		pump_tank = new /obj/item/reagent_containers/glass/beaker/large(R)


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


// ====================================================
// MULTITOOL - ID CARD SCAN + FOLLOW TARGET LINKING
//
// Usage:
//   1. Use multitool on an ID card (or holder of one)
//      → stores the card owner as the follow target.
//   2. Use the multitool on a robot that has a
//      Follow Linked Target circuit installed
//      → calls set_linked_target() on that circuit.
// ====================================================

/obj/item/multitool
	/// Weakref to the mob whose ID was last scanned.
	var/datum/weakref/scanned_mob_ref = null
	/// Display name of the last scanned target.
	var/scanned_mob_name = ""

/// Scan an ID card: store the owner so we can link them to a robot later.
/obj/item/multitool/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity)
		return

	// Scanning an ID card directly
	if(istype(target, /obj/item/card/id))
		var/obj/item/card/id/ID = target
		// Try to find the living mob who owns this card
		var/mob/living/owner = null
		// First check if the user is holding it (their own ID)
		if(istype(user, /mob/living))
			owner = user
		// Otherwise search nearby for a mob whose ID matches
		if(!owner)
			for(var/mob/living/M in range(2, target))
				if(M.get_idcard(TRUE) == ID || M.get_idcard(FALSE) == ID)
					owner = M
					break
		if(owner)
			scanned_mob_ref  = WEAKREF(owner)
			scanned_mob_name = owner.real_name ? owner.real_name : owner.name
			to_chat(user, span_notice("Multitool: follow target stored — [scanned_mob_name]."))
		else
			to_chat(user, span_warning("Multitool: could not locate the owner of this ID card."))
		return

	// Using multitool on a robot: link the stored target to its Follow circuit
	if(istype(target, /mob/living/silicon/robot))
		if(!scanned_mob_ref)
			to_chat(user, span_warning("Multitool: no follow target scanned. Use the multitool on an ID card first."))
			return
		var/mob/living/target_mob = scanned_mob_ref.resolve()
		if(!target_mob || QDELETED(target_mob))
			to_chat(user, span_warning("Multitool: stored follow target no longer exists."))
			scanned_mob_ref  = null
			scanned_mob_name = ""
			return
		var/mob/living/silicon/robot/R = target
		var/linked = FALSE
		// Walk all behavior assemblies installed on the cert
		for(var/datum/cert_upgrade/robot/behavior_assembly/U in R.cpu_cert?.upgrade_slots)
			var/obj/item/behavior_assembly/A = U.assembly
			if(!A)
				continue
			for(var/datum/behavior_circuit/response/follow_target/FT in A.circuits)
				FT.set_linked_target(target_mob, user)
				linked = TRUE
		if(!linked)
			to_chat(user, span_warning("Multitool: this robot has no Follow Linked Target circuit installed."))
		return


// ====================================================
// GRENADE LAUNCHER - physical insertion via click
// If a player clicks on a robot while holding a grenade,
// and the robot has Grenade Launcher hardware installed,
// the grenade gets loaded in automatically.
// ====================================================

/mob/living/silicon/robot/attackby(obj/item/W, mob/user, params)
	. = ..(W, user, params)
	if(istype(W, /obj/item/grenade) && installed_hardware)
		for(var/datum/robot_hardware/grenade_launcher/GL in installed_hardware)
			if(GL.accept_grenade(W, user, src))
				return
