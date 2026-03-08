// ====================================================
// BEHAVIOR ASSEMBLY
// A pre-programmed circuit board that plugs into a
// robot's cert upgrade slot and defines automated
// behaviors via signal-driven circuits.
//
// No SScircuit dependency - all circuits fire via
// existing COMSIG signals on the robot holder.
//
// Builder's SPECIAL is snapshotted at fabricator
// print time and baked into the assembly datum.
//
// File: code/modules/integrated_electronics/behavior_assembly.dm
// ====================================================


// ====================================================
// PHYSICAL ITEM
// ====================================================

/obj/item/behavior_assembly
	name = "behavior assembly"
	desc = "A pre-programmed circuit board. Install it into a robot's cert upgrade slot via open panel."
	icon = 'icons/obj/assemblies/electronic_components.dmi'
	icon_state = "template"
	w_class = WEIGHT_CLASS_SMALL

	/// The behavior circuits loaded into this assembly
	var/list/datum/behavior_circuit/circuits = list()

	/// Max circuits this assembly can hold - set at fabricator print time via PER + LCK
	var/max_circuits = 2

	/// Sensor range baked in from builder's PER at print time
	/// Used by circuits that need a detection radius
	var/sensor_range = 5

	/// Ckey of the player who built this assembly - for logging
	var/builder_ckey = ""

	/// Human-readable label, set by fabricator design
	var/assembly_label = "Unnamed Assembly"

	/// One-time slot expansion at reprogram terminal has been used
	var/slot_expansion_used = FALSE

	/// Pending bonus circuit from a LCK roll at print time - "trigger" or "response"
	/// Set when player chose to defer the bonus slot selection until REPROGRAM
	var/pending_bonus_slot = null

	/// If TRUE, behavior circuits will fire even when a player mind is controlling this robot.
	/// Set by robot_workshop at spawn so assemblies always run regardless of control mode.
	var/assembly_override = FALSE


/obj/item/behavior_assembly/Initialize(mapload)
	. = ..()
	name = "behavior assembly - [assembly_label]"

/obj/item/behavior_assembly/Destroy()
	QDEL_LIST(circuits)
	return ..()

/obj/item/behavior_assembly/examine(mob/user)
	. = ..()
	. += span_notice("Label: <b>[assembly_label]</b>")
	. += span_notice("Circuits: [circuits.len]/[max_circuits]")
	. += span_notice("Sensor range: [sensor_range] tiles")
	if(circuits.len)
		for(var/datum/behavior_circuit/C in circuits)
			. += span_notice("  - [C.circuit_name]")
	. += span_notice("Use it on a robot to install. Crowbar open the panel first for player-controlled robots.")


// ====================================================
// DIRECT INSTALLATION
// Use the assembly on a robot to install it.
// Player-controlled robots require open panel.
// NPC robots (no mind) can be installed freely.
// ====================================================

/obj/item/behavior_assembly/attack(atom/target, mob/living/user)
	if(!istype(target, /mob/living/silicon/robot))
		return ..()
	var/mob/living/silicon/robot/R = target
	_try_install(R, user)

/obj/item/behavior_assembly/proc/_is_npc_robot(mob/living/silicon/robot/R)
	// NPC: no player mind and not a shell
	return (!R.mind && !R.shell)

/obj/item/behavior_assembly/proc/_try_install(mob/living/silicon/robot/R, mob/living/user)
	var/is_npc = _is_npc_robot(R)
	// Player robots require open panel
	if(!is_npc && !R.opened)
		to_chat(user, span_warning("You need to open [R]'s panel with a crowbar first."))
		return
	// Build cert_upgrade wrapper
	var/datum/cert_upgrade/robot/behavior_assembly/U = new()
	U.assembly = src
	// Ensure the robot has a cert - NPCs get an auto-assigned standard cert
	if(!R.cpu_cert)
		if(is_npc)
			R.cpu_cert = new /datum/cpu_cert/robot()
			R.cpu_cert.apply_to_holder(R)
			to_chat(user, span_notice("[R] has no certification - auto-applying standard chassis cert."))
		else
			to_chat(user, span_warning("[R] has no base certification installed. Install a base cert first."))
			qdel(U)
			return
	// Cert compatibility check -- warn if assembly requires flags the cert doesn't have.
	// We don't hard-block NPC installs (mappers may intentionally use exotic assemblies),
	// but we log and warn so misconfigurations are visible.
	if(!cert_compatible(R.cpu_cert))
		to_chat(user, span_warning("[assembly_label] requires capabilities this chassis cert does not have. Some circuits may not function."))
		log_game("[key_name(user)] installed behavior assembly '[assembly_label]' onto [R] whose cert lacks required flags.")
	// Check slot availability
	var/datum/cpu_cert/C = R.cpu_cert
	if(!C.can_install_upgrade(U))
		to_chat(user, span_warning("No available upgrade slots on [R]. Remove an existing upgrade first."))
		qdel(U)
		return
	// Install
	if(!user.transferItemToLoc(src, R))
		qdel(U)
		return
	if(C.install_upgrade(U, R))
		to_chat(user, span_notice("You install [assembly_label] into [R]. Behavior circuits activated."))
		var/aname = assembly_label
		log_game("[key_name(user)] installed behavior assembly '[aname]' into [R] at [AREACOORD(R)]")
	else
		to_chat(user, span_warning("Installation failed - upgrade slot rejected."))
		forceMove(drop_location())
		qdel(U)


// ====================================================
// REMOVAL
// Used in cert strip / manual remove from robot panel.
// Called by datum/cert_upgrade/robot/behavior_assembly/on_remove.
// ====================================================

/obj/item/behavior_assembly/proc/eject_from(mob/living/silicon/robot/R, mob/living/user)
	unregister_signals(R)
	forceMove(get_turf(R))
	if(user)
		to_chat(user, span_notice("You remove [assembly_label] from [R]."))


// ====================================================
// CERT UPGRADE SUBTYPE
// Plugs behavior assembly into cert upgrade slot
// ====================================================

/datum/cert_upgrade/robot/behavior_assembly
	upgrade_name = "Behavior Assembly"
	upgrade_desc = "A pre-programmed behavior circuit board."
	energy_mod = 2

	/// The physical assembly item this upgrade wraps
	var/obj/item/behavior_assembly/assembly = null

/datum/cert_upgrade/robot/behavior_assembly/on_apply(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!assembly)
		return
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	assembly.register_signals(R)

/datum/cert_upgrade/robot/behavior_assembly/on_remove(datum/cpu_cert/C, atom/holder)
	. = ..()
	if(!assembly)
		return
	if(!istype(holder, /mob/living/silicon/robot))
		return
	var/mob/living/silicon/robot/R = holder
	assembly.unregister_signals(R)
	// Move the physical item back to the world so it can be picked up or re-used
	assembly.forceMove(get_turf(R))
	assembly = null

/datum/cert_upgrade/robot/behavior_assembly/Destroy()
	if(assembly)
		qdel(assembly)
	assembly = null
	return ..()


// ====================================================
// SIGNAL REGISTRATION
// Called by the cert upgrade when installed/removed
// ====================================================

/obj/item/behavior_assembly/proc/register_signals(mob/living/silicon/robot/R)
	for(var/datum/behavior_circuit/C in circuits)
		C.register(R, src)

// Returns TRUE if this assembly is compatible with the given cert.
// Called by the CPU fabricator before printing to warn the builder.
// Subtypes override to enforce required capability flags.
/obj/item/behavior_assembly/proc/cert_compatible(datum/cpu_cert/C)
	return TRUE

/obj/item/behavior_assembly/proc/unregister_signals(mob/living/silicon/robot/R)
	for(var/datum/behavior_circuit/C in circuits)
		C.unregister(R)


// ====================================================
// BASE BEHAVIOR CIRCUIT DATUM
// ====================================================

/datum/behavior_circuit
	var/circuit_name = "Unknown Circuit"
	var/circuit_desc = "An unconfigured behavior circuit."
	/// Human-readable explanation shown in the fabricator workshop
	var/tutorial_text = "No documentation available."
	/// CPU budget cost. Checked against cert compute at assembly install.
	var/cpu_cost = 1
	/// TRUE if this circuit requires specific hardware ICs in the robot's module
	var/needs_hardware = FALSE

	/// Hardware slot identifier used by robot_workshop UI to show named requirement slots
	/// Matches IC_SLOT_* defines. Only set on circuits with needs_hardware = TRUE.
	var/hardware_slot_name = null
	/// Weakref to the robot this circuit is registered on
	var/datum/weakref/robot_ref = null
	/// Weakref to the parent assembly
	var/datum/weakref/assembly_ref = null



/// Called when the assembly is installed. R = robot holder.
/datum/behavior_circuit/proc/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	robot_ref    = WEAKREF(R)
	assembly_ref = WEAKREF(A)
	RegisterSignal(R, COMSIG_ROBOT_CLOCK_TICK, PROC_REF(_on_clock_tick))

/// Called when the assembly is removed.
/datum/behavior_circuit/proc/unregister(mob/living/silicon/robot/R)
	UnregisterSignal(R, COMSIG_ROBOT_CLOCK_TICK)
	robot_ref    = null
	assembly_ref = null

/// Internal signal handler -- resolves refs and calls execute()
/datum/behavior_circuit/proc/_on_clock_tick(mob/living/silicon/robot/R, datum/robot_hardware/clock/CLK)
	var/obj/item/behavior_assembly/A = assembly_ref?.resolve()
	if(!R || !A)
		return
	execute(R, A)

/// Convenience - resolves and returns the robot, or null if gone
/datum/behavior_circuit/proc/get_robot()
	return robot_ref?.resolve()

/// Convenience - resolves and returns the assembly, or null if gone
/datum/behavior_circuit/proc/get_assembly()
	return assembly_ref?.resolve()


// ====================================================
// MULTITOOL LINKAGE - Follow Target
// Scan a player's ID card with a multitool to capture
// their name/ref, then use the multitool on the robot
// to link them as the follow target for any follow_target
// behavior circuit installed on the robot.
// ====================================================

// Multitool linkage: user scans an ID card with multitool (buffers assignment),
// then uses the multitool on this assembly to link the follow target.
/obj/item/behavior_assembly/multitool_act(mob/living/user)
	var/obj/item/multitool/MT = user.get_active_hand()
	if(!istype(MT, /obj/item/multitool))
		MT = locate(/obj/item/multitool) in user.contents
	if(!istype(MT, /obj/item/multitool))
		return FALSE
	if(!MT.buffer)
		to_chat(user, span_warning("Scan an ID card with a multitool first to set a follow target."))
		return TRUE
	_try_multitool_link(MT, user)
	return TRUE

/obj/item/behavior_assembly/proc/_try_multitool_link(obj/item/multitool/MT, mob/user)
	// Multitool must have a buffered target from scanning an ID card
	if(!MT.buffer)
		to_chat(user, span_warning("Scan an ID card with the multitool first to link a follow target."))
		return
	// Find linked mob by name match - buffer should be a mob name or ID name
	var/target_name = "[MT.buffer]"
	var/mob/living/found = null
	for(var/mob/living/M in GLOB.alive_mob_list)
		if(M.name == target_name || (istype(M, /mob/living/carbon/human) && M.real_name == target_name))
			found = M
			break
	if(!found)
		to_chat(user, span_warning("Could not locate '[target_name]' in the world. Are they still alive?"))
		return
	// Find a follow_target circuit in this assembly and link it
	var/linked = FALSE
	for(var/datum/behavior_circuit/response/follow_target/FT in circuits)
		FT.set_linked_target(found, user)
		linked = TRUE
	if(!linked)
		to_chat(user, span_warning("This assembly has no Follow Linked Target response to configure."))
		return
	visible_message(span_notice("[user] links [found.name] as a follow target on [src]."))
	MT.buffer = null  // Clear buffer after use


// Multitool scanning an ID card buffers the assignee name for follow-target linkage.
// Use: scan ID card with multitool -> use multitool on behavior assembly -> robot follows that person.
/obj/item/card/id/multitool_act(mob/living/user)
	var/obj/item/multitool/MT = user.get_active_hand()
	if(!istype(MT, /obj/item/multitool))
		MT = locate(/obj/item/multitool) in user.contents
	if(!istype(MT, /obj/item/multitool))
		return FALSE
	// Buffer the cardholder's registered name, not their job assignment.
	// registered_name is what matches mob.real_name in the world search.
	MT.buffer = registered_name
	to_chat(user, span_notice("Buffered follow target: [registered_name] ([assignment]). Use the multitool on a behavior assembly to link."))
	return TRUE
