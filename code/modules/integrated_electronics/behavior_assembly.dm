// ====================================================
// BEHAVIOR ASSEMBLY
// A pre-programmed circuit board that plugs into a
// robot's cert upgrade slot and defines automated
// behaviors via signal-driven circuits.
//
// No SScircuit dependency — all circuits fire via
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

	/// Max circuits this assembly can hold — set at fabricator print time via PER + LCK
	var/max_circuits = 2

	/// Sensor range baked in from builder's PER at print time
	/// Used by circuits that need a detection radius
	var/sensor_range = 5

	/// Ckey of the player who built this assembly — for logging
	var/builder_ckey = ""

	/// Human-readable label, set by fabricator design
	var/assembly_label = "Unnamed Assembly"


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

/obj/item/behavior_assembly/proc/unregister_signals(mob/living/silicon/robot/R)
	for(var/datum/behavior_circuit/C in circuits)
		C.unregister(R)


// ====================================================
// BASE BEHAVIOR CIRCUIT DATUM
// ====================================================

/datum/behavior_circuit
	var/circuit_name = "Unknown Circuit"
	var/circuit_desc = "An unconfigured behavior circuit."

	/// Weakref to the robot this circuit is registered on
	var/datum/weakref/robot_ref = null

	/// Weakref to the parent assembly
	var/datum/weakref/assembly_ref = null


/// Called when the assembly is installed. R = robot holder.
/datum/behavior_circuit/proc/register(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	robot_ref  = WEAKREF(R)
	assembly_ref = WEAKREF(A)

/// Called when the assembly is removed.
/datum/behavior_circuit/proc/unregister(mob/living/silicon/robot/R)
	robot_ref  = null
	assembly_ref = null

/// Convenience — resolves and returns the robot, or null if gone
/datum/behavior_circuit/proc/get_robot()
	return robot_ref?.resolve()

/// Convenience — resolves and returns the assembly, or null if gone
/datum/behavior_circuit/proc/get_assembly()
	return assembly_ref?.resolve()
