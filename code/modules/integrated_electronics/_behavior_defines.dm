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

// ====================================================
// HARDWARE SLOT DEFINES
// Single authoritative source. Included before
// behavior_circuits.dm, robot_workshop.dm, and
// robot_hardware.dm so all three can reference these
// without duplicating or forward-declaring them.
// ====================================================

#define HW_SLOT_WEAPON           "/datum/robot_hardware/weapon"
#define HW_SLOT_AIR_CANNON       "/datum/robot_hardware/air_cannon"
#define HW_SLOT_GRENADE          "/datum/robot_hardware/grenade_launcher"
#define HW_SLOT_THROWER          "/datum/robot_hardware/thrower"
#define HW_SLOT_GRABBER          "/datum/robot_hardware/grabber"
#define HW_SLOT_INJECTOR         "/datum/robot_hardware/injector"
#define HW_SLOT_REAGENT_PUMP     "/datum/robot_hardware/reagent_pump"
#define HW_SLOT_SIGNALER         "/datum/robot_hardware/signaler"
#define HW_SLOT_DISPLAY          "/datum/robot_hardware/display_screen"
#define HW_SLOT_ID_READER        "/datum/robot_hardware/id_reader"
#define HW_SLOT_MICROPHONE       "/datum/robot_hardware/microphone"
#define HW_SLOT_GPS              "/datum/robot_hardware/gps"
#define HW_SLOT_ENV_SCANNER      "/datum/robot_hardware/environment_scanner"
#define HW_SLOT_HEALTH_SCANNER   "/datum/robot_hardware/health_scanner"
#define HW_SLOT_LIGHT            "/datum/robot_hardware/light"
#define HW_SLOT_CHEM_SPRAYER     "/datum/robot_hardware/chem_sprayer"
#define HW_SLOT_HARVESTER        "/datum/robot_hardware/harvester"
#define HW_SLOT_MATERIAL_COLLECTOR "/datum/robot_hardware/material_collector"
#define HW_SLOT_GRINDER          "/datum/robot_hardware/grinder_module"
#define HW_SLOT_BIO_SCANNER      "/datum/robot_hardware/bio_scanner"
#define HW_SLOT_OBJECT_LOCATOR   "/datum/robot_hardware/object_locator"
#define HW_SLOT_POWER_RELAY      "/datum/robot_hardware/power_relay"
#define HW_SLOT_NAV_COMPUTER     "/datum/robot_hardware/nav_computer"
#define HW_SLOT_VOCABULARY       "/datum/robot_hardware/vocabulary_module"
#define HW_SLOT_CLOCK            "/datum/robot_hardware/clock"
#define HW_SLOT_MEMORY           "/datum/robot_hardware/memory_core"
#define HW_SLOT_EXTINGUISHER     "/datum/robot_hardware/extinguisher_module"

// ====================================================
// ROBOT COMBAT MODE DEFINES
// Used by weapon hardware and Maintain Combat Range circuit.
// ====================================================

#define ROBOT_COMBAT_MELEE  1   // Always close in
#define ROBOT_COMBAT_RANGED 2   // Stay at retreat_distance, back off if closer
#define ROBOT_COMBAT_MIXED  3   // Prefer range, switch to melee if rushed

