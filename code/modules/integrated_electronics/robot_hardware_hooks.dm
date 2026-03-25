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
	if(!target || !R)
		return
	// Range gate
	var/effective_range = fire_range + fire_range_bonus
	if(get_dist(R, target) > effective_range)
		return
	// Resolve gun: use stored ref first, then scan module inventory, then spawn fallback
	var/obj/item/gun/G = gun_ref ? gun_ref.resolve() : null
	if(!G && R.module)
		for(var/obj/item/gun/candidate in R.module.modules)
			G = candidate
			gun_ref = WEAKREF(G)
			break
	if(!G && gun_type)
		G = new gun_type(R)
		if(G) gun_ref = WEAKREF(G)
	if(!G)
		return
	last_fire_time = world.time
	R.setDir(get_dir(R, target))
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return
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
	/// world.time when a combat sound (gunshot, explosion, weapon impact) was last detected.
	/// Set by on_combat_sound(). Read by On Combat Sound Nearby trigger.
	var/last_combat_time = 0

/// Called by hardware_on_hear() when speech is detected nearby.
/// Filters by trigger_phrase if set.
/datum/robot_hardware/microphone/proc/on_hear(mob/speaker, msg)
	if(!msg)
		return
	if(trigger_phrase && !findtext(msg, trigger_phrase))
		return
	last_heard_message = msg
	last_heard_time = world.time

/// Called by the robot's bullet_act hook when a projectile impacts.
/// Records the time so On Combat Sound Nearby can fire.
/datum/robot_hardware/microphone/proc/on_combat_sound()
	last_combat_time = world.time


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
	/// Internal reagent tank. Created at install time by install() in robot_hardware.dm.
	/// The borghypo is filled with reagent_type/reagent_volume and added to the module.
	var/obj/item/reagent_containers/reagent_tank = null

// NOTE: install() for injector is defined in robot_hardware.dm.
// Do NOT redefine it here — duplicate proc definitions in DM shadow the earlier one
// and would lose the borghypo initialization + module registration logic.


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

/// Notify microphone hardware that a combat sound occurred nearby.
/// Call from /mob/living/silicon/robot/bullet_act() when a projectile hits.
/mob/living/silicon/robot/proc/hardware_on_combat_sound()
	if(!installed_hardware)
		return
	for(var/datum/robot_hardware/microphone/MIC in installed_hardware)
		MIC.on_combat_sound()


// ====================================================
// POINTER DETECTOR - runtime pointer tracking state
// ====================================================

/datum/robot_hardware/pointer_detector
	/// Last observed laser pointer target location (turf).
	/// Updated each process() tick when the owner's pointer target changes.
	/// Read by On Pointer Changed trigger.
	var/turf/last_pointer_loc = null


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

	// Using multitool on a robot:
	// If the buffer holds a terminal, this is a terminal-link operation — hand off
	// to attackby_terminal_link() and don't touch scanned_mob_ref at all.
	if(istype(target, /mob/living/silicon/robot))
		var/mob/living/silicon/robot/TR = target
		if(istype(buffer, /obj/machinery/computer/terminal))
			TR.attackby_terminal_link(src, user)
			return
		// Otherwise: follow-target linking — need a scanned mob ref
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
// PLAYER-CONTROLLED WEAPON FIRE TRACKING
//
// When a player (or ghost) controls the robot and fires
// a gun item, the weapon hardware's last_fire_time never
// gets stamped because fire_at() is only called by the
// autonomous fire_weapon circuit response.
//
// Override /obj/item/gun/afterattack: if the user is a robot,
// stamp last_fire_time on its weapon hardware and call
// hardware_on_combat_sound() so both On Weapon Fired and
// On Combat Sound Nearby triggers fire correctly.
// ====================================================

/obj/item/gun/afterattack(atom/target, mob/user, proximity, params)
	. = ..(target, user, proximity, params)
	if(!istype(user, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = user
	if(!R.installed_hardware)
		return
	for(var/datum/robot_hardware/weapon/WH in R.installed_hardware)
		WH.last_fire_time = world.time
		break
	R.hardware_on_combat_sound()


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
