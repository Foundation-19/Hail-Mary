// ====================================================
// BEHAVIOR ASSEMBLY SHARED DEFINES
// This file must compile before behavior_assembly.dm,
// behavior_circuits.dm, and robot_hardware.dm.
// Place it first in integrated_electronics.dme includes.
//
// File: code/modules/integrated_electronics/_behavior_defines.dm
// ====================================================

/// Sent by /datum/robot_hardware/clock each tick.
/// Arguments: (mob/living/silicon/robot/R, datum/robot_hardware/clock/CLK)
/// Received by behavior circuits via RegisterSignal in their register() proc.
#define COMSIG_ROBOT_CLOCK_TICK "robot_clock_tick"

/// Stub proc declared on the base circuit datum so both trigger and response
/// subtypes can call execute() without dreamchecker errors.
/// Overridden by /datum/behavior_circuit/response/proc/execute in behavior_circuits.dm.
/datum/behavior_circuit/proc/execute(mob/living/silicon/robot/R, obj/item/behavior_assembly/A)
	return
